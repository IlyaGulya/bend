import {replayKernel,checkFrozen} from './load_replay_kernel.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {writeFileSync,appendFileSync} from 'node:fs';
await guardHeavyGate(import.meta.path,{label:'Exact CheckerCore component full unchanged native validation'});
const root='/Users/ilyagulya/Projects/My/bend',stem=root+'/checkpoints/checker-core-build';
await checkFrozen();
const kernel=await replayKernel('direct',undefined,{retention:'retain'});
let phase='load';const start=performance.now();
function event(data:object){const row={phase,elapsedMs:performance.now()-start,...data};appendFileSync(stem+'.jsonl',JSON.stringify(row)+'\n');writeFileSync(stem+'.progress.json',JSON.stringify(row)+'\n');}
try {
 const K=kernel.kernel,book=K.book_nil(),file=root+'/checkpoints/checker_core_component.bend';
 event({stage:'load-start',file});await K.book_load(book,file,'',new Map());
 event({stage:'load-pass',events:book.order.length});
 if(Object.keys(book.tlds).some(k=>k.startsWith('Template.')||k.startsWith('template.')||k==='check'||k==='check_template_result'))throw Error('Excluded Template boundary leaked into CheckerCore');
 if(!book.tlds['CheckerCore.check_modules']&&!book.tlds['checker_core_slice.check_modules'])throw Error('Missing CheckerCore root');
 phase='validation';const order=book.order;let passes=0;
 book.order=new Proxy(order,{get(a,key,r){if(typeof key==='string'&&/^\d+$/.test(key)){const index=Number(key);if(index===0)passes++;if(passes===2){Bun.gc(true);event({stage:'declaration-begin',index,name:a[index]});}}return Reflect.get(a,key,r);}});
 event({stage:'validation-start',checksExcluded:0,retainedE:true});K.book_valid(book);book.order=order;
 if(book.hols||book.open)throw Error('Incomplete CheckerCore native validation');
 event({stage:'full-validation-pass',events:order.length,checksExcluded:0});
 writeFileSync(stem+'.result.json',JSON.stringify({status:'CHECKERCORE_NATIVE_VALIDATION_PASS',root:'check_modules',checksExcluded:0,events:order.length,selfhostGreen:false},null,2)+'\n');
} catch(error) {
 const diagnostic=error&&typeof error==='object'&&'$'in error&&error.$==='Err'?kernel.kernel.err_show(error as Parameters<typeof kernel.kernel.err_show>[0]):String(error);
 event({stage:'error',diagnostic});console.error(diagnostic);process.exitCode=2;
} finally {kernel.close();await checkFrozen();}
