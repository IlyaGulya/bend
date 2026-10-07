import * as B from '../bend2/bend.ts';
import {canonicalCore,normalizeCoreBook,normalizeImports} from './parser_full_semantic_normalize.ts';
import type {Value,Node} from './parser_full_semantic_normalize.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {mkdtemp,writeFile,rm} from 'node:fs/promises';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {createHash} from 'node:crypto';
await guardHeavyGate(import.meta.path,{label:'Compiled explicit-fuel parser whole29 execution'});
const artifact='/Users/ilyagulya/Projects/My/bend/checkpoints/parser-explicit-fuel-822e8460.js',report='/Users/ilyagulya/Projects/My/bend/checkpoints/parser-compiled-whole29.json';
const original=await Bun.file('evals/parser_full_fuel_smoke.ts').text(),begin=original.indexOf('const originalCorpus = ['),end=original.indexOf('const literalCorpus = [',begin);
if(begin<0||end<0)throw Error('Existing corpus anchors missing');
const cases=new Function(original.slice(begin,end)+'return originalCorpus.concat(expandedCorpus);')() as {name:string,source:string}[];
if(cases.length!==29)throw Error('Existing29 corpus changed');
function ctor(x:unknown):{[key:string]:unknown}&{$:string}{if(!x||typeof x!=='object'||!('$'in x)||typeof x.$!=='string')throw Error('Expected compiled constructor');return x as {[key:string]:unknown}&{$:string};}
function tag(x:unknown){return ctor(x).$.split('.').at(-1)!;}
function decode(x:unknown):Value{
 if(typeof x==='bigint'){const n=Number(x);if(!Number.isSafeInteger(n))throw Error('Unsafe AST Nat');return n;}
 if(typeof x==='string'||typeof x==='boolean'||typeof x==='number')return x;
 if(Array.isArray(x))return x.map(decode);
 const c=ctor(x),t=tag(c);
 if(t==='Nil'||t==='Con'){const out:Value[]=[];let p=c;while(tag(p)==='Con'){out.push(decode(p.head));p=ctor(p.tail);}if(tag(p)!=='Nil')throw Error('Invalid compiled list');return out;}
 return {tag:t,fields:Object.entries(c).filter(([k])=>k!=='$').map(([,v])=>decode(v))};
}
const dir=await mkdtemp(join(tmpdir(),'bend-parser-compiled-')),rows: {name:string,acceptanceParity:boolean,semanticParity:boolean}[]=[];
async function parse(source:string,fuel:number,file='smoke'){
 const worker=join(dir,'parse-worker.mjs');
 await writeFile(worker,`import parser from ${JSON.stringify(artifact)};const source=await Bun.stdin.text();let fuel={$:'FeedbackFuelEnd'};for(let i=0;i<${fuel};i++)fuel={$:'FeedbackFuelCell',tail:fuel};console.log(JSON.stringify(parser.parse_with_fuel(fuel,${JSON.stringify(file)},source),(_,v)=>typeof v==='bigint'?{$:'$NativeNat',value:String(v)}:v));`);
 const child=Bun.spawn([process.execPath,worker],{stdin:new Blob([source]),stdout:'pipe',stderr:'pipe'});
 const text=await new Response(child.stdout).text(),stderr=await new Response(child.stderr).text();if(await child.exited)throw Error('Compiled parser runtime error: '+stderr);
 const raw=JSON.parse(text,(_,v)=>v&&typeof v==='object'&&v.$==='$NativeNat'?BigInt(v.value):v);
 if(tag(raw)!=='FeedbackComplete')throw Error('Explicit-fuel run '+tag(raw));
 const wrapper=ctor(ctor(raw).value),payload=Object.entries(wrapper).find(([k])=>k!=='$')?.[1],value=decode(payload) as Node;
 if(value.tag!=='ParseSuccess'&&value.tag!=='ParseFailure')throw Error('Unexpected compiled payload '+JSON.stringify(value));return {accepted:value.tag==='ParseSuccess',value,module:value.fields[0]};
}
try{
 await writeFile(join(dir,'dependency.bend'),'def value() -> Nat:\n  7n\n');
 for(const item of cases){
  const actual=await parse(item.source,1000),native=B.book_nil(),seen=new Map<string,string>();
  await B.book_load(native,B.BASE_BEND,'',seen);await B.book_load(native,join(dir,'dependency.bend'),'dependency',seen);
  const environment={...B.book_nil(),tlds:{...native.tlds},ctrs:{...native.ctrs}};
  await writeFile(join(dir,'source.bend'),item.source);
  const imports=normalizeImports([...item.source.matchAll(/^import\s+(\S+)(?:\s+as\s+(\w+))?\s*$/gm)].map(m=>({path:m[1],alias:m[2]??'Base'})));
  let accepted=true,expected:unknown;
  try{const start=await B.book_load(native,join(dir,'source.bend'),'',seen);expected=normalizeCoreBook(native,native.order.slice(start),imports,'smoke',dir+'/').semantic;}
  catch(e){if(!e||typeof e!=='object'||!('$'in e)||e.$!=='Err')throw e;accepted=false;}
  const semantic=actual.accepted?canonicalCore(actual.module,environment,item.source).semantic:null;
  const row={name:item.name,acceptanceParity:actual.accepted===accepted,semanticParity:actual.accepted===accepted&&(!accepted||JSON.stringify(semantic)===JSON.stringify(expected))};rows.push(row);console.log(JSON.stringify(row));
  await writeFile(report,JSON.stringify({status:'IN_PROGRESS',rows},null,2)+'\n');
  if(!row.acceptanceParity||!row.semanticParity){await writeFile('/Users/ilyagulya/Projects/My/bend/checkpoints/parser-compiled-first-mismatch.json',JSON.stringify({row,actual,semantic,expected},null,2));throw Error('Compiled parity mismatch '+item.name);}
  Bun.gc(true);
 }
 const realPath='bend2/selfhost/ast.bend',source=await Bun.file(realPath).text(),real=await parse(source,200000,realPath);if(!real.accepted)throw Error('Compiled parser rejected compiler AST module');
 await writeFile(report,JSON.stringify({checkpoint:'COMPILED EXPLICIT-FUEL SELFHOST PARSER',status:'PASS',artifact,artifactSha256:createHash('sha256').update(await Bun.file(artifact).text()).digest('hex'),tinySmoke:rows.slice(0,6),acceptanceParity:rows.filter(r=>r.acceptanceParity).length,normalizedSemanticParity:rows.filter(r=>r.semanticParity).length,rows,realModule:{path:realPath,accepted:true,fuel:200000,sourceSha256:createHash('sha256').update(source).digest('hex')},selfhostGreen:false},null,2)+'\n');
}finally{await rm(dir,{recursive:true,force:true});}
