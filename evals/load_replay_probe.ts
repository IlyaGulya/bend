#!/usr/bin/env bun
import {replayKernel,checkFrozen,frozen} from './load_replay_kernel.ts';
import {guardHeavyGate,parseHeavyGateOptions} from './heavy_gate.ts';
import {dlopen,FFIType,ptr} from 'bun:ffi';
import {createHash,randomUUID} from 'node:crypto';
import {resolve,join} from 'node:path';
import {tmpdir} from 'node:os';
import {writeFileSync,appendFileSync,rmSync} from 'node:fs';
await guardHeavyGate(import.meta.path,{label:'gated direct parser load/validation'});
const phase=parseHeavyGateOptions(process.argv.slice(2)).args[0];
if(!['pattern','load','validation'].includes(phase))throw Error('Expected pattern, load or validation');
const equivalence=await Bun.file('checkpoints/load-replay-equivalence.json').json();if(equivalence.status!=='PASS')throw Error('Small equivalence prerequisite not met');
if(phase!=='pattern'){const pattern=await Bun.file('checkpoints/load-replay-pattern.json').json();if(pattern.status!=='PASS'||!pattern.patternScanAssigned)throw Error('pattern_scan assignment prerequisite not met');}
if(phase==='validation'){const load=await Bun.file('checkpoints/load-replay-load.json').json();if(load.status!=='PASS')throw Error('Full load prerequisite not met');}
await checkFrozen();
const memorySource=resolve('evals/book_phase_memory.c'),hash=createHash('sha256').update(await Bun.file(memorySource).text()).digest('hex').slice(0,16),library=join(tmpdir(),`bend-book-phase-${hash}.dylib`);
if(!await Bun.file(library).exists()){const cc=Bun.spawnSync(['cc','-O2','-dynamiclib',memorySource,'-o',library]);if(cc.exitCode)throw Error(new TextDecoder().decode(cc.stderr));}
const sampler=dlopen(library,{book_phase_memory:{args:[FFIType.ptr],returns:FFIType.i32}}),buffer=new BigUint64Array(3);
function memory(){if(sampler.symbols.book_phase_memory(ptr(buffer))!==0)throw Error('Process memory sample failed');return{footprintBytes:Number(buffer[0]),rssBytes:Number(buffer[1]),lifetimeMaxFootprintBytes:Number(buffer[2])};}
const journal=`checkpoints/load-replay-${phase}.jsonl`,progress=`checkpoints/load-replay-${phase}.progress.json`,result=`checkpoints/load-replay-${phase}.json`;
writeFileSync(journal,'');const start=performance.now();let declarations=0,checkingIndex=-1,checkedDefs=0,activeName:string|null=null;
function event(data:object){const row={elapsedMs:performance.now()-start,...memory(),...data};appendFileSync(journal,JSON.stringify(row)+'\n');writeFileSync(progress,JSON.stringify({status:'ACTIVE',phase,declarations,checkingIndex,checkedDefs,activeName,last:row})+'\n');}
let input=resolve('bend2/selfhost/parser_full_generated_fuel.bend'),temporary:string|undefined;
if(phase==='pattern'){
 const text=await Bun.file(input).text(),headers=[...text.matchAll(/^(?:def|law|type) ([^\s(]+)/gm)],position=headers.findIndex(h=>h[1]==='pattern_scan');if(position<0)throw Error('Exact pattern_scan source missing');
 const end=headers[position+1]?.index??text.length;temporary=resolve('bend2/selfhost',`.load_replay_pattern_${randomUUID()}.bend`);writeFileSync(temporary,text.slice(0,end));input=temporary;
}
const handle=await replayKernel('direct',(name,stage)=>{activeName=name;event({phase:'load',name,stage});}),K=handle.kernel,book=K.book_nil();
event({phase:'load',stage:'start',temporaryKernel:handle.path,input});
const push=book.order.push.bind(book.order);book.order.push=(...names:string[])=>{const length=push(...names);declarations=length;for(const name of names)event({phase:'load',stage:'declaration-complete',index:length-1,name});return length;};
try{
 const loadStart=performance.now();await K.book_load(book,input,'',new Map());const loadElapsedMs=performance.now()-loadStart;
 const scan=book.tlds.pattern_scan,patternScanAssigned=scan?.$==='Def'&&scan.v!==null;
 event({phase:'load',stage:'complete',declarations,loadElapsedMs,patternScanAssigned});
 let validationElapsedMs:number|undefined;
 if(phase==='validation'){
  let passes=0,previous:string|null=null;
  book.order=new Proxy(book.order,{get(array,key,receiver){if(typeof key==='string'&&/^\d+$/.test(key)){const index=Number(key);if(index===0)passes++;if(passes===2){if(previous){const prior=book.tlds[previous];if(prior?.$==='Def'&&prior.e!=null)checkedDefs++;}checkingIndex=index;activeName=array[index];event({phase:'validation',stage:'declaration-begin',index,name:activeName,previous,checkedDefs});previous=activeName;}}return Reflect.get(array,key,receiver);}});
  const validStart=performance.now();K.book_valid(book);validationElapsedMs=performance.now()-validStart;checkingIndex=book.order.length;
  event({phase:'validation',stage:'complete',declarationsChecked:book.order.length,validationElapsedMs});
  if(book.hols||book.open)throw Error(`Unfilled validation result: holes=${book.hols}, open=${book.open}`);
 }
 await checkFrozen();const data={status:'PASS',phase,declarations,patternScanAssigned,loadElapsedMs,validationElapsedMs,declarationsChecked:phase==='validation'?book.order.length:0,checkedDefs:Object.values(book.tlds).filter(d=>d.$==='Def'&&d.e!=null).length,elapsedMs:performance.now()-start,finalMemory:memory(),frozen,journal};writeFileSync(result,JSON.stringify(data,null,2)+'\n');writeFileSync(progress,JSON.stringify(data)+'\n');console.log(JSON.stringify(data));
}catch(error){const detail=error&&typeof error==='object'&&'$'in error&&error.$==='Err'?K.err_show(error as Parameters<typeof K.err_show>[0]):String(error);event({stage:'error',activeName,checkingIndex,error:detail});writeFileSync(result,JSON.stringify({status:'FAIL',phase,activeName,checkingIndex,declarations,error:detail,frozen},null,2)+'\n');throw error;}
finally{handle.close();if(temporary)rmSync(temporary,{force:true});}
