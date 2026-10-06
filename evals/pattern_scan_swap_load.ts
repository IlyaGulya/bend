#!/usr/bin/env bun
/** Load-only because exact source-only fixture validity gate failed. */
import {replayKernel,checkFrozen,frozen} from './load_replay_kernel.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {createHash} from 'node:crypto';
import {resolve} from 'node:path';
import {writeFileSync} from 'node:fs';
await guardHeavyGate(import.meta.path,{label:'Native load of exact source-only swapped pattern_scan candidate'});
const path=resolve('bend2/selfhost/parser_full_generated_fuel_column_swap.bend');
const audit=await Bun.file('checkpoints/pattern-scan-source-swap-audit.json').json();
if(createHash('sha256').update(await Bun.file(path).text()).digest('hex')!==audit.transformedSha256)throw Error('Candidate audit/hash mismatch');
const handle=await replayKernel('direct',undefined,{retention:'discard-e'}),K=handle.kernel,book=K.book_nil(),start=performance.now();
try{await K.book_load(book,path,'',new Map());const data={status:'LOAD_PASS',declarations:book.order.length,elapsedMs:performance.now()-start,targetCheck:'NOT_RUN_FAILED_FIXTURE_GATE',frozen};writeFileSync('checkpoints/pattern-scan-swap-load.json',JSON.stringify(data,null,2)+'\n');console.log(JSON.stringify(data));}
catch(error){const detail=error&&typeof error==='object'&&'$'in error&&error.$==='Err'?K.err_show(error as Parameters<typeof K.err_show>[0]):String(error);const data={status:'LOAD_ERROR',error:detail,elapsedMs:performance.now()-start,eventsRegistered:book.order.length,targetIndex:book.order.indexOf('pattern_scan'),targetCheck:'NOT_REACHED',candidateSha256:audit.transformedSha256,frozen};writeFileSync('checkpoints/pattern-scan-swap-load.json',JSON.stringify(data,null,2)+'\n');console.error(JSON.stringify(data));process.exitCode=2;}
finally{await checkFrozen();handle.close();}
