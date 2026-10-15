#!/usr/bin/env bun
/** Measurement only. Loads the frozen candidate; never changes checker bodies. */
import * as B from '../bend2/bend.ts';
import {guardHeavyGate,parseHeavyGateOptions} from './heavy_gate.ts';
import {dlopen,FFIType,ptr} from 'bun:ffi';
import {createHash,randomUUID} from 'node:crypto';
import {resolve,join} from 'node:path';
import {tmpdir} from 'node:os';
import {mkdirSync,appendFileSync,writeFileSync,rmSync} from 'node:fs';
await guardHeavyGate(import.meta.path,{label:'frozen whole-book phase attribution'});
const args=parseHeavyGateOptions(process.argv.slice(2)).args;
const phase=args[0]??'load';
if(!['load','validation','load-profile'].includes(phase))throw Error('Expected load, validation or load-profile');
const before=args.find(a=>a.startsWith('--before='))?.slice(9),through=args.find(a=>a.startsWith('--through='))?.slice(10);
const label=args.find(a=>a.startsWith('--label='))?.slice(8)??phase;
if(!/^[\w-]+$/.test(label))throw Error('Invalid result label');
const retained=args.includes('--retained');
if(before&&through)throw Error('Choose one prefix boundary');
if(retained&&(phase!=='load-profile'||!before))throw Error('Exact retained-v counting requires load-profile and a safe --before prefix');
declare global {
 var __bookPhaseProbe: ((name:string,stage:string,value:unknown)=>void)|undefined;
 var __bookPhaseBacking: ((node:object,body:unknown,env:unknown)=>void)|undefined;
}
const frozen:Record<string,string>={
 'bend2/bend.ts':'47e1b06e2fa4466bad702f86d8cbce03f40e833a8ba8eaa1e04297fa46dc94a9',
 'bend2/selfhost/parser.bend':'f425995af41087dfa51f79e7b04259ea5d1acfa9906061c7ed57199bad4e18df',
 'bend2/selfhost/parser_full_generated_fuel.bend':'b66ca5fe16b41d65feb51afd95b3954550396b60e542c21a93fe042b7fa9d51e',
 'evals/parser_full_generate.ts':'0aedb4c1703cffe1055794b29829a357edcd956fdc0a8dec77bfa3c0cf7a6da6'};
for(const[path,expected]of Object.entries(frozen))if(createHash('sha256').update(new Uint8Array(await Bun.file(path).arrayBuffer())).digest('hex')!==expected)throw Error('Frozen input drift: '+path);
const source=resolve('evals/book_phase_memory.c'),hash=createHash('sha256').update(await Bun.file(source).text()).digest('hex').slice(0,16);
const library=join(tmpdir(),`bend-book-phase-${hash}.dylib`);
if(!await Bun.file(library).exists()){const cc=Bun.spawnSync(['cc','-O2','-dynamiclib',source,'-o',library]);if(cc.exitCode)throw Error(new TextDecoder().decode(cc.stderr));}
const sampler=dlopen(library,{book_phase_memory:{args:[FFIType.ptr],returns:FFIType.i32}});
const memoryBuffer=new BigUint64Array(3);
function memory(){if(sampler.symbols.book_phase_memory(ptr(memoryBuffer))!==0)throw Error('Memory sampling unavailable');return{footprintBytes:Number(memoryBuffer[0]),rssBytes:Number(memoryBuffer[1]),lifetimeMaxFootprintBytes:Number(memoryBuffer[2])};}
const journal=resolve(`checkpoints/book-phase-${label}.jsonl`),resultPath=resolve(`checkpoints/book-phase-${label}.json`);
mkdirSync(resolve('checkpoints'),{recursive:true});writeFileSync(journal,'');
const start=performance.now();let completed=0,active:string|null=null;
function event(data:object){const row={elapsedMs:performance.now()-start,...memory(),...data};appendFileSync(journal,JSON.stringify(row)+'\n');}
const candidate=resolve('bend2/selfhost/parser_full_generated_fuel.bend'),temporaries:string[]=[],bodyCounts:object[]=[];
let input=candidate,kernel:BendKernel=B;
type BendKernel=typeof B;
const termKinds=new Set('Var Ref Sub Let Typ Qnt Qua Min All Lam App ADT Ctr Mat Efq Eql Rfl Rwt Hol Ann'.split(' '));
const backingBodies=new WeakMap<object,unknown>(),backingEnvs=new WeakMap<object,unknown>();
if(retained)globalThis.__bookPhaseBacking=(node,body,env)=>{backingBodies.set(node,body);backingEnvs.set(node,env);};
function countSyntax(root:unknown,includeBacking=false){
 const seen=new Set<object>(),stack:unknown[]=[root];let termNodes=0,arrays=0;
 while(stack.length){const value=stack.pop();if(!value||typeof value!=='object'||seen.has(value))continue;seen.add(value);if(Array.isArray(value))arrays++;
 if('$'in value&&typeof value.$==='string'&&termKinds.has(value.$))termNodes++;
 if(includeBacking){stack.push(backingBodies.get(value),backingEnvs.get(value));}
 for(const[key,child]of Object.entries(value))if(key!=='s')stack.push(child);}
 return{termNodes,objects:seen.size-arrays,arrays};
}
if(before||through){
 const text=await Bun.file(candidate).text(),headers=[...text.matchAll(/^(?:def|law|type) ([^\s(]+)/gm)];
 const selected=headers.findIndex(h=>h[1]===(before??through));if(selected<0)throw Error('Prefix boundary not found');
 let end=before?headers[selected].index!:headers[selected+1]?.index??text.length;
 if(text.slice(0,end).endsWith('@unsafe\n'))end-=8;
 input=resolve('bend2/selfhost',`.book_phase_prefix_${randomUUID()}.bend`);temporaries.push(input);writeFileSync(input,text.slice(0,end));
 event({phase:'load',boundary:'prefix',before,through,sourceCharacters:end});
}
if(phase==='load-profile'){
 const original=await Bun.file('bend2/bend.ts').text();
 const anchor='  def.v = term_higher(term_lower(term_higher(body_flatten(b, vars, () => p.sc.frs++))));';
 if(original.split(anchor).length!==2)throw Error('Unique conversion observation anchor missing');
 const replacement='  def.v = term_higher(__bookPhaseObserve(k, "normalized", term_lower(__bookPhaseObserve(k, "higher", term_higher(__bookPhaseObserve(k, "flattened", body_flatten(b, vars, () => p.sc.frs++)))))));';
 const prelude='declare global { var __bookPhaseProbe: ((name:string,stage:string,value:unknown)=>void)|undefined; var __bookPhaseBacking: ((node:object,body:unknown,env:unknown)=>void)|undefined; }\nfunction __bookPhaseObserve<T>(name:string,stage:string,value:T):T { globalThis.__bookPhaseProbe?.(name,stage,value); return value; }\nfunction __bookPhaseCapture<T extends object>(node:T,body:unknown,env:unknown):T { globalThis.__bookPhaseBacking?.(node,body,env); return node; }\n';
 const changes:[string,string][]=[[anchor,replacement]];
 if(retained){
  changes.push(['      return Let(b.k, b.i, v, (xs: HTerm[]) => {','      return __bookPhaseCapture(Let(b.k, b.i, v, (xs: HTerm[]) => {']);
  changes.push(['      }, b.s, b.q);\n    }\n    case "All":','      }, b.s, b.q), b, env);\n    }\n    case "All":']);
  changes.push(['      return All(b.q, b.k, b.i, A, (x: HTerm) => {','      return __bookPhaseCapture(All(b.q, b.k, b.i, A, (x: HTerm) => {']);
  changes.push(['      }, b.s);\n    }\n    case "Lam":','      }, b.s), b, env);\n    }\n    case "Lam":']);
  changes.push(['      return Lam(b.k, b.i, (x: HTerm) => {','      return __bookPhaseCapture(Lam(b.k, b.i, (x: HTerm) => {']);
  changes.push(['      }, b.s, b.q);\n    }\n    case "Typ":','      }, b.s, b.q), b, env);\n    }\n    case "Typ":']);
 }
 let instrumented=original;
 for(const[from,to]of changes){if(instrumented.split(from).length!==2)throw Error('Unique observer capture anchor missing');instrumented=instrumented.replace(from,to);}
 let recovered=instrumented;for(const[from,to]of changes.slice().reverse())recovered=recovered.replace(to,from);
 if(recovered!==original)throw Error('Observer source differs beyond identity hooks');
 const observed=resolve('bend2',`.book_phase_observer_${randomUUID()}.ts`);temporaries.push(observed);
 writeFileSync(observed,prelude+instrumented);
 event({phase:'load',boundary:'observer',observed,productionUnchanged:true,changes:retained?'Identity-only stage hooks and observations of already-captured Lam/All/Let source/environment':'Three return-identity observations in parse_def_body expression only'});
 globalThis.__bookPhaseProbe=(name,stage,value)=>{
  event({phase:'load',boundary:'conversion',name,stage});
  // Full-body counts only on the safely bounded pre-pattern prefix. Never walk the giant failing body.
  if(before&&!retained&&stage==='normalized'){const counts=countSyntax(value),root=value&&typeof value==='object'&&'$'in value?value.$:null;
   const row={name,...counts,root,retention:root==='Lam'?'Entire normalized syntax retained by term_higher Lam closure':'Normalized syntax proxy; non-Lam conversion may retain less'};bodyCounts.push(row);event({phase:'load',boundary:'body-count',...row});}
 };
 kernel=await import(observed);
}
const book=B.book_nil(),originalPush=book.order.push.bind(book.order);
book.order.push=(...names:string[])=>{const n=originalPush(...names);completed=n;for(const name of names){event({phase:'load',boundary:'loaded',index:n-1,name,declarations:n});if(retained){const def=book.tlds[name];if(def?.$==='Def'&&def.v!==null){const row={name,...countSyntax(def.v,true),root:def.v.$,retention:'Unique nodes in def.v plus its actual Lam/All/Let captured syntax and environment; spans excluded'};bodyCounts.push(row);event({phase:'load',boundary:'retained-v-count',...row});}}}return n;};
const originalTlds=book.tlds;
book.tlds=new Proxy(originalTlds,{set(target,key,value,receiver){if(typeof key==='string'){active=key;event({phase:'load',boundary:'begin',index:book.order.length,name:key});}return Reflect.set(target,key,value,receiver);}});
event({phase:'load',boundary:'start'});
try{
 const loadStart=performance.now();await kernel.book_load(book,input,'',new Map());
 const loadElapsedMs=performance.now()-loadStart;event({phase:'load',boundary:'complete',declarations:book.order.length,loadElapsedMs});
 if(phase==='validation'){
  let passes=0,checkedDefs=0,previous:string|null=null;
  book.order=new Proxy(book.order,{get(target,key,receiver){if(typeof key==='string'&&/^\d+$/.test(key)){const index=Number(key);if(index===0)passes++;if(passes===2){if(previous!==null){const prior=book.tlds[previous];if(prior?.$==='Def'&&prior.e!=null)checkedDefs++;}active=target[index];event({phase:'validation',boundary:'begin',index,name:active,previous,checkedDefs});previous=active;}}return Reflect.get(target,key,receiver);}});
  const validStart=performance.now();B.book_valid(book);event({phase:'validation',boundary:'complete',validationElapsedMs:performance.now()-validStart,checkedDefs:Object.values(book.tlds).filter(d=>d.$==='Def'&&d.e!=null).length});
 }
 const result={status:'PASS',phase,declarations:book.order.length,defsWithE:Object.values(book.tlds).filter(d=>d.$==='Def'&&d.e!=null).length,loadElapsedMs,elapsedMs:performance.now()-start,finalMemory:memory(),frozen,journal,bodyCounts};writeFileSync(resultPath,JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify({...result,bodyCounts:bodyCounts.length}));
 if(before){Bun.gc(true);event({phase:'load',boundary:'post-gc',declarations:book.order.length,defsWithE:0});}
}catch(error){event({phase,boundary:'error',active,completed,error:error instanceof Error?error.message:String(error)});throw error;}
finally{globalThis.__bookPhaseProbe=undefined;globalThis.__bookPhaseBacking=undefined;for(const path of temporaries)rmSync(path,{force:true});}
