import {sourceOracle} from './bootstrap_source_oracle.ts';
import {canonicalCore,normalizeCoreBook,normalizeImports} from './parser_full_semantic_normalize.ts';
import type {Value} from './parser_full_semantic_normalize.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {createHash} from 'node:crypto';
import {writeFileSync,mkdtempSync,rmSync} from 'node:fs';
import {resolve,dirname,join} from 'node:path';
import {tmpdir} from 'node:os';
import {Readable} from 'node:stream';
import {createInterface} from 'node:readline';
await guardHeavyGate(import.meta.path,{label:'Rebuilt compiled parser complete module AST parity'});
const artifact=process.argv.find(a=>a.startsWith('--artifact='))?.slice(11);
if(!artifact)throw Error('Explicit rebuilt artifact required');
const report=process.argv.find(a=>a.startsWith('--report='))?.slice(9)??'checkpoints/bootstrap-rebuilt-parser-parity.json';
const selected=process.argv.find(a=>a.startsWith('--suite='))?.slice(8);
const producer=Bun.spawn(['node','evals/bootstrap_parser_artifact_worker.mjs',resolve(artifact)],{stdin:'pipe',stdout:'pipe',stderr:'inherit'});
const lines=createInterface({input:Readable.fromWeb(producer.stdout as any)});
let id=0;const requests=new Map<number,{resolve:(r:any)=>void,reject:(e:Error)=>void}>();
lines.on('line',line=>{const r=JSON.parse(line,(_,v)=>v?.$==='$NativeNat'?BigInt(v.value):v),p=requests.get(r.id);if(!p)throw Error('Unexpected worker response');requests.delete(r.id);r.error?p.reject(Error(r.error)):p.resolve(r.result);});
producer.exited.then(code=>{for(const p of requests.values())p.reject(Error('Parser worker exited '+code));requests.clear();});
async function parse(file:string,source:string){const request=id++,reply=new Promise<any>((resolve,reject)=>requests.set(request,{resolve,reject}));producer.stdin.write(JSON.stringify({id:request,file,source})+'\n');await producer.stdin.flush();return reply;}
function decode(x:any):Value{if(typeof x==='bigint'){const n=Number(x);if(!Number.isSafeInteger(n))throw Error('Unsafe AST Nat');return n;}if(typeof x!=='object'||x===null)return x;if(x.$==='Nil'||x.$==='Con'){const out:Value[]=[];while(x.$==='Con'){out.push(decode(x.head));x=x.tail;}if(x.$!=='Nil')throw Error('Invalid native list');return out;}return {tag:x.$.split('.').at(-1),fields:Object.entries(x).filter(([k])=>k!=='$').map(([,v])=>decode(v))};}
const hash=(x:unknown)=>createHash('sha256').update(JSON.stringify(x)).digest('hex');
const text=await Bun.file('evals/parser_full_fuel_smoke.ts').text(),begin=text.indexOf('const originalCorpus = ['),end=text.indexOf('const literalCorpus = [',begin);
const regression=new Function(text.slice(begin,end)+'return originalCorpus.concat(expandedCorpus);')() as {name:string,source:string}[];
if(regression.length!==29)throw Error('Whole29 drift');
const manifest=await Bun.file('checkpoints/bootstrap-real-source-corpus.json').json();
const dir=mkdtempSync(join(tmpdir(),'bend-rebuilt-parity-')),file=join(dir,'source.bend');
writeFileSync(file,'');writeFileSync(join(dir,'dependency.bend'),'def value() -> Nat:\n  7n\n');
const suite=[...regression.slice(0,6).map(r=>({...r,file,suite:'tiny6'})),...regression.map(r=>({...r,file,suite:'whole29'})),...await Promise.all(manifest.modules.map(async(m:any)=>({name:m.file.split('/').at(-1),file:m.file,source:await Bun.file(m.snapshot).text(),suite:'real'})))];
const rows:any[]=[];
function save(){writeFileSync(report,JSON.stringify({artifact:resolve(artifact!),artifactSha256,normalization:'Complete module semantics; existing spans/alpha ledger only',counts:Object.fromEntries(['tiny6','whole29','real'].map(s=>[s,{total:rows.filter(r=>r.suite===s).length,accepted:rows.filter(r=>r.suite===s&&r.compiledAccepted).length,acceptanceParity:rows.filter(r=>r.suite===s&&r.acceptanceParity).length,semanticParity:rows.filter(r=>r.suite===s&&r.semanticParity).length}])),rows},null,2)+'\n');}
const artifactSha256=createHash('sha256').update(new Uint8Array(await Bun.file(artifact).arrayBuffer())).digest('hex');
try{for(const item of suite.filter(item=>!selected||item.suite===selected)){
 console.log(JSON.stringify({stage:'compiled-parse',name:item.name,suite:item.suite,bytes:Buffer.byteLength(item.source)}));
 const oracle=await sourceOracle(item.file,item.source,{preloadBase:item.suite!=='real'}),row:any={name:item.name,file:item.file,suite:item.suite,stage0Accepted:oracle.accepted};
 try{
  const result=await parse(item.file,item.source);row.compiledAccepted=result.$==='ParseSuccess';row.acceptanceParity=row.compiledAccepted===oracle.accepted;
  if(!row.compiledAccepted){row.failure=decode(result);if(!oracle.accepted)row.semanticParity=true;}
  if(row.compiledAccepted&&oracle.accepted){
   const module=decode(result.module) as any,imports=module.fields[1],adjusted={...module,fields:[module.fields[0],imports.map((v:any)=>{const actual=oracle.imports.find(i=>i.alias===v.fields[1]);return {...v,fields:[actual?.namespace||v.fields[0],...v.fields.slice(1)]};}),module.fields[2]]};
   const environment=oracle.normalizationBook(),expected=normalizeCoreBook(environment,oracle.declarations.map(d=>d.key),oracle.imports.map(i=>({path:i.path,alias:i.alias})),item.file,dirname(item.file)+'/').semantic;
   const actual=canonicalCore(adjusted,environment,item.source).semantic;actual.imports=normalizeImports(imports.map((v:any)=>({path:v.fields[0],alias:v.fields[1]})));
   row.stage0ASTHash=hash(expected);row.compiledASTHash=hash(actual);row.semanticParity=row.stage0ASTHash===row.compiledASTHash;
   if(!row.semanticParity)writeFileSync(report+'.'+item.name+'.mismatch.json',JSON.stringify({expected,actual},null,2)+'\n');
  }
 }catch(error){row.error=String(error);row.acceptanceParity??=false;row.semanticParity=false;}
 rows.push(row);save();console.log(JSON.stringify(row));Bun.gc(true);
}}finally{lines.close();producer.stdin.end();await producer.exited;rmSync(dir,{recursive:true,force:true});}
if(rows.some(r=>!r.acceptanceParity||!r.semanticParity))process.exitCode=2;
