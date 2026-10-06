#!/usr/bin/env bun
/** Fresh real target, not full validation acceptance. */
import {replayKernel,checkFrozen} from './load_replay_kernel.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {writeFileSync,appendFileSync} from 'node:fs';
import {resolve} from 'node:path';
await guardHeavyGate(import.meta.path,{label:'Fresh native real atom row9 target; trusted-prefix diagnostic only'});
const stem='checkpoints/atom-row9-target',start=performance.now();let active:string|null=null;
const handle=await replayKernel('direct',undefined,{retention:'retain',observeCheck:(name,stage)=>{active=name;appendFileSync(stem+'.jsonl',JSON.stringify({name,stage,elapsedMs:performance.now()-start})+'\n');}});
try{
 writeFileSync(stem+'.jsonl','');const K=handle.kernel,book=K.book_nil();
 await K.book_load(book,resolve('bend2/selfhost/.parser_atom_rows_shape_generated_fuel.bend'),'',new Map());
 const name='step_parse_atom_symbol_row_9',index=book.order.indexOf(name),eventsLoaded=book.order.length;if(index<0)throw Error('Missing real atom row9');
 writeFileSync(stem+'.plan.json',JSON.stringify({question:'Does the exact atomic row9 still hit 3GiB with a fresh native target and no preceding checked-e payloads?',onPass:'Whole-check resource failure is not intrinsic to this row; investigate separately authorized checked-output handoff, no semantic workaround',onFailure:'Retain exact intrinsic target error/resource evidence; do not claim whole-check readiness',name,index,eventsLoaded,toolchain:'Temporary direct loader, full native target retaining e; trusted prefix only'},null,2)+'\n');
 book.order=book.order.slice(0,index+1);K.book_valid(book,index);
 const data={status:'PASS',name,index,eventsLoaded,elapsedMs:performance.now()-start,scope:'Trusted-prefix single target only, no full-check acceptance',nativeCheckedOutputRetained:true};writeFileSync(stem+'.json',JSON.stringify(data,null,2)+'\n');console.log(JSON.stringify(data));
}catch(error){const K=handle.kernel,detail=error&&typeof error==='object'&&'$'in error&&error.$==='Err'?K.err_show(error as Parameters<typeof K.err_show>[0]):String(error);writeFileSync(stem+'.json',JSON.stringify({status:'FAIL',active,error:detail},null,2)+'\n');console.error(detail);process.exitCode=2;}
finally{handle.close();await checkFrozen();}
