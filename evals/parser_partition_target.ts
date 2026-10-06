#!/usr/bin/env bun
import {replayKernel,checkFrozen} from './load_replay_kernel.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {resolve} from 'node:path';
import {appendFileSync,writeFileSync} from 'node:fs';
await guardHeavyGate(import.meta.path,{label:'Packet scanner context, all row helpers and original-ABI loop native target validation'});
const start=performance.now(),stem='checkpoints/parser-packet-target';let active:string|null=null;
const handle=await replayKernel('direct',undefined,{retention:'retain',observeCheck:(name,stage)=>{active=name;appendFileSync(stem+'.jsonl',JSON.stringify({name,stage,elapsedMs:performance.now()-start})+'\n');writeFileSync(stem+'.progress.json',JSON.stringify({status:'ACTIVE',name,stage})+'\n');}}),K=handle.kernel,book=K.book_nil();
try{writeFileSync(stem+'.jsonl','');await K.book_load(book,resolve('bend2/selfhost/.pattern_scan_packet_generated_fuel.bend'),'',new Map());const names=['PatternScanContext',...book.order.filter(n=>/^pattern_scan_row_\d+$/.test(n)),'pattern_scan_expect_step','pattern_scan_completed_step','pattern_scan_token_step','pattern_scan_empty_step','pattern_scan'],indices=names.map(n=>book.order.indexOf(n));if(indices.some(i=>i<0))throw Error('Missing scanner helper');const done=Math.min(...indices),end=Math.max(...indices)+1,eventsLoaded=book.order.length;book.order=book.order.slice(0,end);K.book_valid(book,done);const data={status:'PASS',scope:'Trusted prefix diagnostic only; not full candidate validation',eventsLoaded,done,end,names,indices,elapsedMs:performance.now()-start,checkedOutputRetention:'native e'};writeFileSync(stem+'.json',JSON.stringify(data,null,2)+'\n');console.log(JSON.stringify(data));}
catch(error){const text=error&&typeof error==='object'&&'$'in error&&error.$==='Err'?K.err_show(error as Parameters<typeof K.err_show>[0]):String(error);const data={status:'FAIL',active,error:text,elapsedMs:performance.now()-start};writeFileSync(stem+'.json',JSON.stringify(data,null,2)+'\n');console.error(JSON.stringify(data));process.exitCode=2;}
finally{await checkFrozen();handle.close();}
