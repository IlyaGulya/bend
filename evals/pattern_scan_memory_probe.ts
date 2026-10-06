#!/usr/bin/env bun
/** Fresh target only: native done seeds prefix; no earlier body checks or GC. */
import {replayKernel,checkFrozen,frozen} from './load_replay_kernel.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {dlopen,FFIType,ptr} from 'bun:ffi';
import {createHash} from 'node:crypto';
import {resolve,join} from 'node:path';
import {tmpdir} from 'node:os';
import {writeFileSync,appendFileSync} from 'node:fs';
await guardHeavyGate(import.meta.path,{label:'Fresh pattern_scan native done=705 target check'});
await checkFrozen();
const src=resolve('evals/book_phase_memory.c'),hash=createHash('sha256').update(await Bun.file(src).text()).digest('hex').slice(0,16),lib=join(tmpdir(),`bend-book-phase-${hash}.dylib`);
if(!await Bun.file(lib).exists()){const cc=Bun.spawnSync(['cc','-O2','-dynamiclib',src,'-o',lib]);if(cc.exitCode)throw Error(new TextDecoder().decode(cc.stderr));}
const sampler=dlopen(lib,{book_phase_memory:{args:[FFIType.ptr],returns:FFIType.i32}}),buffer=new BigUint64Array(3);
function memory(){if(sampler.symbols.book_phase_memory(ptr(buffer))!==0)throw Error('Memory sample failed');const heap=process.memoryUsage();return{footprintBytes:Number(buffer[0]),rssBytes:Number(buffer[1]),lifetimeMaxFootprintBytes:Number(buffer[2]),heapUsed:heap.heapUsed,heapTotal:heap.heapTotal};}
const stem='checkpoints/pattern-scan-target',journal=stem+'.jsonl',result=stem+'.json',progress=stem+'.progress.json';
writeFileSync(journal,'');const start=performance.now();let checkedBodies=0,activeName:string|null=null,bodyStart=0,phase='load';
function event(data:object){const row={elapsedMs:performance.now()-start,phase,checkedBodies,activeName,...memory(),...data};appendFileSync(journal,JSON.stringify(row)+'\n');writeFileSync(progress,JSON.stringify({status:'ACTIVE',last:row})+'\n');return row;}
const handle=await replayKernel('direct',undefined,{retention:'discard-e',observeCheck:(name,stage)=>{
 activeName=name;
 if(stage==='before'){bodyStart=performance.now();event({stage:'body-before'});return;}
 checkedBodies++;event({stage:'body-after',targetElapsedMs:performance.now()-bodyStart});
}}),K=handle.kernel,book=K.book_nil();
try{
 event({stage:'load-start',temporaryKernel:handle.path});const t=performance.now();await K.book_load(book,resolve('bend2/selfhost/parser_full_generated_fuel.bend'),'',new Map());const loadElapsedMs=performance.now()-t;
 if(book.order.length!==1280||book.order[705]!=='pattern_scan')throw Error('Frozen order/target drift');event({stage:'load-complete',declarations:1280,loadElapsedMs});
 book.order=book.order.slice(0,706);
 phase='validation';event({stage:'validation-start',done:705,boundedOrder:book.order.length});const validStart=performance.now();K.book_valid(book,705);const validationElapsedMs=performance.now()-validStart;
 if(checkedBodies!==1)throw Error('Target-only execution did not check exactly one body');
 const retainedE=Object.values(book.tlds).filter(d=>d.$==='Def'&&d.e!=null).length;if(retainedE!==0)throw Error('Unexpected retained e');await checkFrozen();
 const final=event({stage:'validation-return',validationElapsedMs,retainedE});const data={status:'PASS',mode:'target-only',declarationsLoaded:1280,declarationEventsValidated:1,checkedBodies,loadElapsedMs,validationElapsedMs,final,frozen,journal};writeFileSync(result,JSON.stringify(data,null,2)+'\n');writeFileSync(progress,JSON.stringify(data)+'\n');console.log(JSON.stringify(data));
}catch(error){const detail=error&&typeof error==='object'&&'$'in error&&error.$==='Err'?K.err_show(error as Parameters<typeof K.err_show>[0]):String(error);event({stage:'error',error:detail});writeFileSync(result,JSON.stringify({status:'FAIL',activeName,checkedBodies,error:detail,frozen},null,2)+'\n');throw error;}
finally{handle.close();}
