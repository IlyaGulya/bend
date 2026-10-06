#!/usr/bin/env bun
/** D1 only: direct load, unchanged full checker calls, do not retain checked tm. */
import {replayKernel,checkFrozen,frozen} from './load_replay_kernel.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {dlopen,FFIType,ptr} from 'bun:ffi';
import {createHash} from 'node:crypto';
import {resolve,join} from 'node:path';
import {tmpdir} from 'node:os';
import {writeFileSync,appendFileSync} from 'node:fs';
await guardHeavyGate(import.meta.path,{label:'D1 complete direct-load discard-E validation'});
await checkFrozen();
const accepted=await Bun.file('checkpoints/load-replay-load.json').json();if(accepted.status!=='PASS'||accepted.declarations!==1280)throw Error('Accepted direct-load prerequisite missing');
const memorySource=resolve('evals/book_phase_memory.c'),hash=createHash('sha256').update(await Bun.file(memorySource).text()).digest('hex').slice(0,16),library=join(tmpdir(),`bend-book-phase-${hash}.dylib`);
if(!await Bun.file(library).exists()){const cc=Bun.spawnSync(['cc','-O2','-dynamiclib',memorySource,'-o',library]);if(cc.exitCode)throw Error(new TextDecoder().decode(cc.stderr));}
const sampler=dlopen(library,{book_phase_memory:{args:[FFIType.ptr],returns:FFIType.i32}}),buffer=new BigUint64Array(3);
function memory(){if(sampler.symbols.book_phase_memory(ptr(buffer))!==0)throw Error('Process memory sample failed');return{footprintBytes:Number(buffer[0]),rssBytes:Number(buffer[1]),lifetimeMaxFootprintBytes:Number(buffer[2])};}
const journal='checkpoints/discard-e-validation.jsonl',progress='checkpoints/discard-e-validation.progress.json',result='checkpoints/discard-e-validation.json';
writeFileSync(journal,'');const start=performance.now();let phase='load',checkingIndex=-1,checkedDefs=0,activeName:string|null=null;
function event(data:object){const row={elapsedMs:performance.now()-start,...memory(),phase,...data};appendFileSync(journal,JSON.stringify(row)+'\n');writeFileSync(progress,JSON.stringify({status:'ACTIVE',phase,checkingIndex,checkedDefs,activeName,last:row})+'\n');}
const handle=await replayKernel('direct',undefined,{retention:'discard-e'}),K=handle.kernel,book=K.book_nil();
event({stage:'start',temporaryKernel:handle.path,retention:'discard-e',validatorChange:'Remove only def.e assignment; full term_check(...).tm expression retained'});
try{
 const loadStart=performance.now();await K.book_load(book,resolve('bend2/selfhost/parser_full_generated_fuel.bend'),'',new Map());const loadElapsedMs=performance.now()-loadStart;
 if(book.order.length!==1280)throw Error('Candidate declaration order drift');event({stage:'complete',declarations:book.order.length,loadElapsedMs});
 const originalOrder=book.order,last=new Map<string,number>();originalOrder.forEach((name,index)=>last.set(name,index));
 let passes=0,previousIndex=-1;
 book.order=new Proxy(book.order,{get(array,key,receiver){if(typeof key==='string'&&/^\d+$/.test(key)){const index=Number(key);if(index===0)passes++;
  if(passes===2){if(previousIndex>=0){const name=array[previousIndex],def=book.tlds[name];if(last.get(name)===previousIndex&&def?.$==='Def'&&def.v!==null)checkedDefs++;}
   checkingIndex=index;activeName=array[index];
   const sample=checkedDefs===0||checkedDefs%50===0;
   const retainedE=sample?Object.values(book.tlds).filter(d=>d.$==='Def'&&d.e!=null).length:undefined;
   if(retainedE!==undefined&&retainedE!==0)throw Error('Discard-E unexpectedly retained checked bodies');
   event({stage:'declaration-begin',index,name:activeName,checkedDefs,retainedE,memorySample:sample});previousIndex=index;
  }}return Reflect.get(array,key,receiver);}});
 phase='validation';event({stage:'start',declarations:book.order.length,retainedE:0});
 const validStart=performance.now();K.book_valid(book);const validationElapsedMs=performance.now()-validStart;
 if(previousIndex>=0){const name=originalOrder[previousIndex],def=book.tlds[name];if(last.get(name)===previousIndex&&def?.$==='Def'&&def.v!==null)checkedDefs++;}
 const retainedE=Object.values(book.tlds).filter(d=>d.$==='Def'&&d.e!=null).length;
 if(retainedE!==0)throw Error('Discard-E retained output');if(book.hols||book.open)throw Error(`Unfilled validation result: holes=${book.hols}, open=${book.open}`);
 await checkFrozen();const data={status:'PASS',phase,declarationsLoaded:1280,declarationsChecked:1280,checkedDefs,retainedE,loadElapsedMs,validationElapsedMs,elapsedMs:performance.now()-start,finalMemory:memory(),frozen,journal};writeFileSync(result,JSON.stringify(data,null,2)+'\n');writeFileSync(progress,JSON.stringify(data)+'\n');console.log(JSON.stringify(data));
}catch(error){const detail=error&&typeof error==='object'&&'$'in error&&error.$==='Err'?K.err_show(error as Parameters<typeof K.err_show>[0]):String(error);event({stage:'error',error:detail});const data={status:'FAIL',phase,checkingIndex,activeName,checkedDefs,error:detail,frozen};writeFileSync(result,JSON.stringify(data,null,2)+'\n');console.error(JSON.stringify(data));throw error;}
finally{handle.close();}
