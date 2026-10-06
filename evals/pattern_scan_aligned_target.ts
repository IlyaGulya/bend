#!/usr/bin/env bun
/** Fresh process after generation; full direct load, native bounded book_valid.
 * Prefix is trusted, NOT checked. Keep normal checked e assignment unchanged.
 */
import {createHash} from 'node:crypto';
import {appendFileSync, writeFileSync} from 'node:fs';
import {resolve, join} from 'node:path';
import {tmpdir} from 'node:os';
import {dlopen, FFIType, ptr} from 'bun:ffi';
import type {Err} from '../bend2/bend.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {checkFrozen, frozen, replayKernel} from './load_replay_kernel.ts';

await guardHeavyGate(import.meta.path, {label: 'Aligned fresh native pattern_scan target (retain e)'});
await checkFrozen();
const stem = resolve('evals/pattern_scan_aligned_result');
const journal = stem + '.jsonl', result = stem + '.json', progress = stem + '.progress.json';
const evidence = await Bun.file(stem + '.generation.json').json();
const audit = await Bun.file(stem + '.source-audit.json').json();
const candidatePath = resolve('bend2/selfhost/.pattern_scan_aligned_generated_fuel.bend');
const sha = (text: string) => createHash('sha256').update(text).digest('hex');
if (audit.status !== 'SOURCE_AUDIT_PASS' || audit.transformedSha256 !== evidence.sourceHash ||
    sha(await Bun.file('bend2/selfhost/.pattern_scan_aligned_source.bend').text()) !== evidence.sourceHash ||
    sha(await Bun.file(candidatePath).text()) !== evidence.generatedHash) throw Error('Aligned candidate provenance mismatch');
const compilerHash = sha(await Bun.file('bend2/comp.ts').text());
if (compilerHash !== evidence.compilerHash) throw Error('Compiler drift since preparation');
const samplerSource = resolve('evals/book_phase_memory.c');
const libraryPath = join(tmpdir(), `bend-book-phase-${sha(await Bun.file(samplerSource).text()).slice(0, 16)}.dylib`);
if (!await Bun.file(libraryPath).exists()) {
  const cc = Bun.spawnSync(['cc', '-O2', '-dynamiclib', samplerSource, '-o', libraryPath]);
  if (cc.exitCode) throw Error(new TextDecoder().decode(cc.stderr));
}
const sampler = dlopen(libraryPath, {book_phase_memory: {args: [FFIType.ptr], returns: FFIType.i32}});
const buffer = new BigUint64Array(3), started = performance.now();
let phase = 'load', checkedBodies = 0, activeName: string | null = null, bodyStarted = 0;
let declarationsLoaded = 0, targetIndex: number | null = null;
function event(data: object) {
  if (sampler.symbols.book_phase_memory(ptr(buffer)) !== 0) throw Error('Memory sample failed');
  const heap = process.memoryUsage();
  const row = {elapsedMs: performance.now() - started, phase, checkedBodies, activeName,
    footprintBytes: Number(buffer[0]), rssBytes: Number(buffer[1]), lifetimeMaxFootprintBytes: Number(buffer[2]),
    heapUsed: heap.heapUsed, heapTotal: heap.heapTotal, ...data};
  appendFileSync(journal, JSON.stringify(row) + '\n');
  writeFileSync(progress, JSON.stringify({status: 'ACTIVE', last: row}) + '\n');
  return row;
}
const handle = await replayKernel('direct', undefined, {retention: 'retain', observeCheck: (name, stage) => {
  activeName = name;
  if (name !== 'pattern_scan') throw Error('Unexpected checked body: ' + name);
  if (stage === 'before') { bodyStarted = performance.now(); event({stage: 'body-before'}); }
  else { checkedBodies++; event({stage: 'body-after', targetElapsedMs: performance.now() - bodyStarted}); }
}});
const K = handle.kernel, book = K.book_nil();
try {
  const beforeLoad = event({stage: 'load-before', temporaryKernel: handle.path, candidatePath,
    sourceHash: evidence.sourceHash, generatedHash: evidence.generatedHash, compilerHash});
  const loadStarted = performance.now();
  await K.book_load(book, candidatePath, '', new Map());
  const loadElapsedMs = performance.now() - loadStarted;
  declarationsLoaded = book.order.length;
  targetIndex = book.order.indexOf('pattern_scan');
  if (declarationsLoaded !== 1280 || targetIndex < 0 || book.order.filter(name => name === 'pattern_scan').length !== 1) throw Error('Full candidate order/target drift');
  const afterLoad = event({stage: 'load-after', declarationsLoaded, targetIndex, loadElapsedMs});
  const originalOrder = [...book.order];
  book.order = originalOrder.slice(0, targetIndex + 1);
  phase = 'validation';
  const beforeValidation = event({stage: 'validation-before', nativeDone: targetIndex, boundedOrder: book.order.length, checkedERetention: 'retain'});
  const validationStarted = performance.now();
  K.book_valid(book, targetIndex);
  const validationElapsedMs = performance.now() - validationStarted;
  if (checkedBodies !== 1) throw Error('Target-only execution did not check exactly one body');
  const target = book.tlds.pattern_scan;
  if (target?.$ !== 'Def' || target.e === null || target.e === undefined) throw Error('Checked target e was not retained');
  const retainedE = Object.values(book.tlds).filter(def => def.$ === 'Def' && def.e != null).length;
  book.order = originalOrder;
  await checkFrozen();
  if (sha(await Bun.file('bend2/comp.ts').text()) !== compilerHash) throw Error('Frozen compiler changed during diagnostic');
  const afterValidation = event({stage: 'validation-after', validationElapsedMs, retainedE, targetCheckedERetained: true});
  const data = {status: 'TARGET_PASS', diagnosticOnly: true, mode: 'fresh-direct-load/native-trusted-prefix-target', checkedERetention: 'retain',
    prefixBodiesChecked: 0, checkedBodies, declarationsLoaded, targetIndex, nativeDone: targetIndex, originalOrderRestored: true,
    fullValidation: 'NOT_RUN', backendCompilation: 'NOT_RUN', sourceHash: evidence.sourceHash, generatedHash: evidence.generatedHash,
    candidatePath, loadElapsedMs, validationElapsedMs, retainedE, beforeLoad, afterLoad, beforeValidation, afterValidation,
    peakFootprintBytes: afterValidation.lifetimeMaxFootprintBytes, frozen, compilerHash, journal};
  writeFileSync(result, JSON.stringify(data, null, 2) + '\n');
  writeFileSync(progress, JSON.stringify(data) + '\n');
  console.log(JSON.stringify(data));
} catch (error) {
  const detail = error && typeof error === 'object' && '$' in error && error.$ === 'Err' ? K.err_show(error as Err) : String(error);
  event({stage: 'error', error: detail});
  const data = {status: 'FAIL', phase, activeName, checkedBodies, declarationsLoaded, targetIndex, error: detail, sourceHash: evidence.sourceHash,
    generatedHash: evidence.generatedHash, checkedERetention: 'retain', frozen, compilerHash, journal};
  writeFileSync(result, JSON.stringify(data, null, 2) + '\n');
  process.exitCode = 2;
} finally {
  handle.close(); sampler.close();
  await checkFrozen();
  if (sha(await Bun.file('bend2/comp.ts').text()) !== compilerHash) throw Error('Frozen compiler changed during diagnostic');
}
