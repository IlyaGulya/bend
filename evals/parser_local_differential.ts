import * as B from '../bend2/bend.ts';
import {canonicalSourceBook,canonicalCore,normalizeCoreBook,normalizeImports,type Value,type Node} from './parser_full_semantic_normalize.ts';
import {installCompiledLexerABI,feedbackParserResult} from './bootstrap_parser_eval_abi.ts';
import {sourceOracle} from './bootstrap_source_oracle.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {localFixtures,templateObservationFixtures} from './parser_local_fixtures.ts';
import {createHash} from 'node:crypto';
import {readFileSync,writeFileSync,mkdtempSync,rmSync,mkdirSync} from 'node:fs';
import {resolve,dirname,join} from 'node:path';
import {tmpdir} from 'node:os';
import {Readable} from 'node:stream';
import {createInterface} from 'node:readline';
import type {ReadableStream as NodeReadableStream} from 'node:stream/web';

// Each invocation compares one exact layer against stage0's complete normalized
// module AST. Run layers sequentially; --fixture=two-binders-two-rhs is the red probe.
const option=(name:string)=>process.argv.find(a=>a.startsWith('--'+name+'='))?.slice(name.length+3);
process.argv.push('--memory-mib','8192','--rss-mib','8192','--poll-ms','10');
await guardHeavyGate(import.meta.path,{label:'Four-layer local declaration AST differential'});
const layer=option('layer')??'canonical';
if(!['canonical','factored','generated','compiled'].includes(layer))throw Error('Unsupported layer '+layer);
const parserPath=option('parser')??(layer==='canonical'?'bend2/selfhost/parser.bend':undefined);
const artifact=option('artifact');
if(!parserPath||(layer==='compiled'&&!artifact))throw Error('Explicit current parser/source and compiled artifact required');
const report=option('report')??'checkpoints/local-'+layer+'.json';
const fixtureName=option('fixture');
const suite=option('suite')??'locals';
if(!['locals','templates'].includes(suite))throw Error('Unknown local suite '+suite);
const corpus=suite==='templates'?templateObservationFixtures:localFixtures;
const fixtures=fixtureName?corpus.filter(f=>f.name===fixtureName):corpus;
if(!fixtures.length)throw Error('Unknown fixture '+fixtureName);
const inputPath=layer==='compiled'?artifact:parserPath;
const inputSha256=createHash('sha256').update(readFileSync(inputPath)).digest('hex');
const rows:any[]=[];
mkdirSync(dirname(resolve(report)),{recursive:true});
function publish(){writeFileSync(report,JSON.stringify({layer,parserPath:parserPath??null,artifact:layer==='compiled'?artifact:null,inputSha256,
 seam:'Complete public module AST normalized by parser_full_semantic_normalize; stage0 sourceOracle reference',
 evidenceSources:['bend2/base.bend:2266-2272','checkpoints/f32-bounded-v1-base.json.modules/3.result.json','checkpoints/f32-bounded-v1-base.json.modules/3.ast.json'],
 rows,passed:rows.length===fixtures.length&&rows.every(r=>r.stage0Accepted&&r.semanticParity)},null,2)+'\n');}
let book:B.Book|undefined,fuel:B.HTerm=B.Ctr('FeedbackFuelEnd',[]);
if(layer!=='compiled'){
 book=await canonicalSourceBook(readFileSync(parserPath,'utf8'), resolve(parserPath));
 await installCompiledLexerABI(book);
 if(layer==='generated')for(let i=0;i<2000000;i++)fuel=B.Ctr('FeedbackFuelCell',[fuel]);
}
function closed(text:string):B.HTerm{return B.Lit('String',text);}
function ctor(term:B.HTerm){const v=B.term_wnf(book!,term),head=v.$==='Lit'?B.lit_step(v):v;if(head.$!=='Ctr')throw Error('Expected constructor '+head.$);return {...head,k:B.name_key(head.k)};}
function nat(term:B.HTerm):number{let n=0;for(;;){const raw=B.term_wnf(book!,term);if(raw.$==='Lit'&&raw.k==='Nat')return n+raw.v;const v=ctor(raw);if(v.k==='Zero')return n;if(v.k!=='Succ')throw Error('Malformed Nat');n++;term=v.x[0];}}
function text(term:B.HTerm):string{
 let out='';for(;;){const v=ctor(term);if(v.k==='SNil')return out;if(v.k!=='SCon')throw Error('Malformed String');
 let word=ctor(ctor(v.x[0]).x[0]).x[0],code=0,bit=1;
 for(;;){const w=ctor(word);if(w.k==='WNil')break;if(w.k!=='WCon')throw Error('Malformed Word');if(ctor(w.x[0]).k==='True')code+=bit;bit*=2;word=w.x[1];}
 out+=String.fromCodePoint(code);term=v.x[1];}
}
function decode(term:B.HTerm):Value{
 const v=ctor(term),tag=v.k.split('.').at(-1)!;
 if(tag==='Zero'||tag==='Succ')return nat(term);
 if(tag==='True'||tag==='False')return tag==='True';
 if(tag==='SNil'||tag==='SCon')return text(term);
 if(tag==='Nil'||tag==='Con'){const list:Value[]=[];for(;;){const c=ctor(term);if(c.k==='Nil')return list;if(c.k!=='Con')throw Error('Malformed List');list.push(decode(c.x[0]));term=c.x[1];}}
 return {tag,fields:v.x.map(decode)};
}
function record(value:unknown):Record<string,unknown>{if(!value||typeof value!=='object'||Array.isArray(value))throw Error('Malformed compiled object');return value as Record<string,unknown>;}
function native(value:unknown):Value{
 if(typeof value==='string'||typeof value==='boolean'||typeof value==='number')return value;
 const v=record(value);
 if(v.$==='$NativeNat'){const n=Number(v.value);if(!Number.isSafeInteger(n)||n<0)throw Error('Inexact compiled Nat');return n;}
 if(v.$==='Nil'||v.$==='Con'){const list:Value[]=[];let c=v;while(c.$==='Con'){list.push(native(c.head));c=record(c.tail);}if(c.$!=='Nil')throw Error('Malformed compiled List');return list;}
 if(typeof v.$!=='string')throw Error('Malformed compiled constructor');
 return {tag:v.$.split('.').at(-1)!,fields:Object.entries(v).filter(([k])=>k!=='$').map(([,x])=>native(x))};
}
const trace:any[]=[];
if(book&&process.argv.includes('--trace')){
 // Observations only: no grammar or output changes. Generated helpers expose
 // exact input cursors; canonical/factored additionally expose returned cursors.
 for(const [base,tokenIndex] of [['parse_body_scan',1],['decl_local_name_group',3],['parse_parallel_local',1],['parse_array_write_local',5],['parse_local_values',1],['parse_local_body',5]] as const){
  const name=(layer==='generated'?'step_':'')+base,def=book.tlds[name];
  if(def?.$!=='Def')throw Error('Missing local trace helper '+name);
  const original=def.v!,arity=def.n;
  function wrap(term:B.HTerm,args:B.HTerm[]):B.HTerm{
   if(args.length<arity)return B.Lam('local-observation',100000+args.length,arg=>wrap(B.App(term,arg),args.concat(arg)));
   const event:any={helper:name,inputTokens:decode(args[tokenIndex])};
   if(base==='decl_local_name_group'){event.isArrayWrite=decode(args[0]);event.isArray=decode(args[1]);}
   trace.push(event);
   const result=B.term_wnf(book!,term);
   if(layer!=='generated')event.returned=decode(result);
   return result;
  }
  def.v=wrap(original,[]);
 }
}
const worker=layer==='compiled'?Bun.spawn(['node','evals/bootstrap_parser_artifact_worker.mjs',resolve(artifact)],{stdin:'pipe',stdout:'pipe',stderr:'inherit'}):undefined;
const stream=worker?.stdout as unknown as NodeReadableStream<Uint8Array>|undefined;
const lines=stream?createInterface({input:Readable.fromWeb(stream)}):undefined,iterator=lines?.[Symbol.asyncIterator]();
const fixtureDir=mkdtempSync(join(tmpdir(),'bend-local-differential-')),file=join(fixtureDir,'source.bend');
try{
 for(const [id,fixture] of fixtures.entries()){
  trace.length=0;
  const row:any={...fixture,stage0Accepted:false,accepted:false,semanticParity:false};rows.push(row);
  try{
   writeFileSync(file,fixture.source);
   const oracle=await sourceOracle(file,fixture.source,{preloadBase:true});
   row.stage0Accepted=oracle.accepted;row.stage0Observation=oracle.observation;
   if(!oracle.accepted){row.stage0Failure=oracle.failure;throw Error('Stage0 rejected fixture at '+oracle.failure?.pos+' ('+oracle.failure?.category+')');}
   row.stage0Declarations=oracle.declarations.map(d=>({key:d.key,kind:d.kind,template:d.template??false}));
   const environment=oracle.normalizationBook();
   let value:Value;
   if(worker){
    worker.stdin.write(JSON.stringify({id,file,source:fixture.source})+'\n');await worker.stdin.flush();
    const line=await iterator!.next();if(line.done)throw Error('Compiled worker ended');
    const response=record(JSON.parse(line.value));if(response.id!==id)throw Error('Compiled response id mismatch');if(response.error)throw Error(String(response.error));value=native(response.result);
   }else{
    const term=layer==='generated'?feedbackParserResult(book!,B.App(B.App(B.App(B.Ref('parse_with_fuel'),fuel),closed(file)),closed(fixture.source))):B.App(B.App(B.Ref('parse'),closed(file)),closed(fixture.source));
    value=decode(term);
   }
   if(!value||typeof value!=='object'||Array.isArray(value)||!['ParseSuccess','ParseFailure'].includes(value.tag))throw Error('Invalid public parser result');
   const result=value as Node;row.accepted=result.tag==='ParseSuccess';
   row.publicAst=result;
   row.expected=normalizeCoreBook(environment,oracle.declarations.map(d=>d.key),oracle.imports.map(i=>({path:i.path,alias:i.alias})),file,dirname(file)+'/').semantic;
   if(row.accepted){
    row.actual=canonicalCore(result.fields[0],environment,fixture.source).semantic;
    row.actual.imports=normalizeImports(oracle.imports.map(i=>({path:i.path,alias:i.alias})));
    row.semanticParity=JSON.stringify(row.expected)===JSON.stringify(row.actual);
   }else{
    row.failure=result;
    const span=result.fields.find(f=>f&&typeof f==='object'&&!Array.isArray(f)&&f.tag==='SpanOf') as Node|undefined;
    if(span){const [,beg,end]=span.fields;if(typeof beg==='number'&&typeof end==='number')row.publicCursor={beg,end,tokenText:fixture.source.slice(beg,end),sourceRemainder:fixture.source.slice(beg)};}
   }
  }catch(error){row.error=String(error);}
  if(process.argv.includes('--trace'))row.trace=trace.slice();
  publish();console.log(JSON.stringify({layer,name:row.name,stage0Accepted:row.stage0Accepted,accepted:row.accepted,semanticParity:row.semanticParity,error:row.error}));
 }
}finally{if(worker){lines!.close();worker.stdin.end();await worker.exited;}rmSync(fixtureDir,{recursive:true,force:true});}
if(rows.some(r=>!r.stage0Accepted||!r.semanticParity))process.exitCode=1;
