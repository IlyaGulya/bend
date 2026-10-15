import {replayKernel,checkFrozen} from './load_replay_kernel.ts';
import * as Comp from '../bend2/.comp_js_stream_probe.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {writeFileSync,appendFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {dlopen,FFIType,ptr} from 'bun:ffi';
await guardHeavyGate(import.meta.path,{label:'Compiled selfhost Checker/JSEmit reusable driver'});
const root='/Users/ilyagulya/Projects/My/bend',stem=root+'/checkpoints/compiled-frontend-build',artifact=root+'/checkpoints/selfhost-frontend-driver.js';
const lib=dlopen('/tmp/bend-artifact-phase-memory.dylib',{artifact_memory:{args:[FFIType.ptr],returns:FFIType.i32}});
function memory(){const m=new BigUint64Array(2);if(lib.symbols.artifact_memory(ptr(m)))throw Error('Memory sample failed');return {footprintBytes:Number(m[0]),rssBytes:Number(m[1])};}
const start=performance.now();let phase='load';function event(data:object){const row={phase,elapsedMs:performance.now()-start,...memory(),...data};appendFileSync(stem+'.jsonl',JSON.stringify(row)+'\n');writeFileSync(stem+'.progress.json',JSON.stringify(row)+'\n');}
await checkFrozen();const kernel=await replayKernel('direct',undefined,{retention:'retain'});
try{
 const K=kernel.kernel,book=K.book_nil(),file=root+'/bend2/selfhost/hybrid_driver.bend';event({stage:'load-start',file,temporaryKernel:kernel.path});await K.book_load(book,file,'',new Map());event({stage:'load-pass',events:book.order.length});
 const roots=['parsed_module','check_modules','emit_modules'];for(const key of roots)if(!book.tlds[key])throw Error('Missing root '+key);
 if(Object.keys(book.tlds).some(k=>k.startsWith('parser.')||k==='loader.load'))throw Error('Unexpected parser/Loader implementation in driver book');
 phase='validation';const order=book.order;let passes=0;book.order=new Proxy(order,{get(a,key,r){if(typeof key==='string'&&/^\d+$/.test(key)){const index=Number(key);if(index===0)passes++;if(passes===2){Bun.gc(true);event({stage:'declaration-begin',index,name:a[index]});}}return Reflect.get(a,key,r);}});event({stage:'validation-start',checksExcluded:0,retainedE:true});K.book_valid(book);book.order=order;if(book.hols||book.open)throw Error('Incomplete native driver');event({stage:'full-validation-pass',events:order.length});Bun.gc(true);
 phase='codegen';Comp.js_storage_release_e(true);Comp.js_storage_set_probe((stage,name,state)=>{event({stage,name,...state,memos:Comp.js_storage_memos()});if(stage==='release-after')Bun.gc(true);});event({stage:'codegen-start',roots});const code=Comp.js_lib(book,roots,roots);writeFileSync(artifact,code);const sha=createHash('sha256').update(code).digest('hex');event({stage:'codegen-pass',artifact,sha256:sha,bytes:Buffer.byteLength(code)});writeFileSync(stem+'.result.json',JSON.stringify({status:'ARTIFACT_PRODUCED',artifact,sha256:sha,bytes:Buffer.byteLength(code),nativeEvents:order.length,roots,toolchain:'Stage0 direct-load diagnostic, full unchanged native validation; accepted exact JS prepare/emit/release temporary variant with diagnostic GC',selfhostGreen:false},null,2)+'\n');
}catch(error){const detail=error&&typeof error==='object'&&'$'in error&&error.$==='Err'?kernel.kernel.err_show(error as Parameters<typeof kernel.kernel.err_show>[0]):String(error);event({stage:'error',diagnostic:detail});console.error(detail);process.exitCode=2;}finally{kernel.close();await checkFrozen();}
