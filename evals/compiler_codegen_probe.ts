#!/usr/bin/env bun
// Diagnostic only: validate the complete root, observe bounded C passes, publish
// no compiler image. Ordinary compiler/build/acceptance paths are unchanged.
import {createHash} from 'node:crypto';
import {closeSync, openSync, readFileSync, realpathSync, renameSync, writeFileSync} from 'node:fs';
import {dirname, resolve} from 'node:path';
import {cpus, loadavg} from 'node:os';
import {guardHeavyGate} from './heavy_gate.ts';
import {createCompileBookObserver} from './compiler_profile.mjs';

await guardHeavyGate(import.meta.path, {label: 'Bounded full-root C codegen probe'});
const args = new Map<string, string>();
for (const argument of process.argv.slice(2)) {
  const at = argument.indexOf('=');
  const key = argument.slice(0, at), value = argument.slice(at + 1);
  if (at < 0 || !['--root', '--bridge', '--report', '--passes', '--max-codegen-ms'].includes(key)
    || !value || args.has(key)) throw Error('Expected unique --root=PATH --report=PATH [--bridge=PATH] [--passes=2] [--max-codegen-ms=120000]');
  args.set(key, value);
}
function integer(key: string, fallback: number): number {
  const value = Number(args.get(key) ?? fallback);
  if (!Number.isSafeInteger(value) || value < 1) throw Error(key + ' must be a positive integer');
  return value;
}
if (!args.has('--root') || !args.has('--report')) throw Error('Required --root and --report');
const source = realpathSync(args.get('--root')!), reportPath = resolve(args.get('--report')!);
const passes = integer('--passes', 2), maxCodegenMs = integer('--max-codegen-ms', 120000);
const bridge = args.has('--bridge') ? realpathSync(args.get('--bridge')!) : null;
const hash = (path: string) => createHash('sha256').update(readFileSync(path)).digest('hex');
const inputs: Record<string, string> = {};
const pin = (path: string) => { const real = realpathSync(path); inputs[real] = hash(real); };
for (const path of [source, ...(bridge ? [bridge] : []), import.meta.path,
  resolve(import.meta.dir, '../bend2/bend.ts'), resolve(import.meta.dir, '../bend2/comp.ts'),
  resolve(import.meta.dir, 'compiler_profile.mjs')]) pin(path);
closeSync(openSync(reportPath, 'wx'));
const report: any = {schemaVersion: 1, status: 'IN_PROGRESS', terminal: false,
  diagnosticOnly: true, acceptanceEvidence: false, compilerAccepted: false,
  codegenSettled: false, outputPublished: false, source, bridge, inputs,
  limits: {passes, maxCodegenMs},
  hostBefore: {logicalCpus: cpus().length, loadAverage: loadavg()},
  runtime: {execPath: process.execPath, execArgv: process.execArgv, versions: process.versions,
    automaticGcRamHint: process.env.BUN_JSC_forceRAMSize ?? null, manualGC: false},
  passRows: []};
let phase = 'load', codegenStart = 0, currentPass = 0, lastWrite = 0;
const started = performance.now();
function save(): void {
  report.elapsedMs = performance.now() - started;
  writeFileSync(reportPath + '.tmp', JSON.stringify(report, null, 2) + '\n');
  renameSync(reportPath + '.tmp', reportPath);
}
function progress(event: string, details: Record<string, unknown> = {}): void {
  report.event = event;
  report.processCpuUs = process.cpuUsage();
  save();
  console.log('CODEGEN_PROBE ' + JSON.stringify({event, phase, elapsedMs: report.elapsedMs, ...details}));
}
function authenticate(): void {
  for (const [path, digest] of Object.entries(inputs))
    if (hash(path) !== digest) throw Error('Probe input changed: ' + path);
}
class ProbeStop extends Error {}
let kernel: typeof import('../bend2/bend.ts') | undefined;
try {
  progress('start');
  const K = await import('../bend2/bend.ts'), C = await import('../bend2/comp.ts');
  kernel = K;
  const book = K.book_nil();
  class Inputs extends Map<string, string | null> {
    override set(path: string, namespace: string | null) {
      if (namespace === null) pin(path);
      return super.set(path, namespace);
    }
  }
  const seen = new Inputs();
  await K.book_load(book, source, '', seen);
  if (bridge) await K.book_load(book, bridge, '', seen, undefined, dirname(source) + '/');
  for (const definition of Object.values(book.tlds))
    if (definition.$ === 'Def') for (const path of definition.i ?? []) pin(path);
  phase = 'validate'; progress('loaded', {events: book.order.length, modules: seen.size});
  const expected = Object.values(book.tlds).filter(def => def.$ === 'Def' && def.v !== null).length;
  K.book_valid(book);
  if (book.hols) throw Error('Canonical validation left holes');
  let checked = 0;
  for (const definition of Object.values(book.tlds)) {
    if (definition.$ !== 'Def' || definition.v === null) continue;
    if (definition.e === undefined) throw Error('Missing checked body');
    checked += 1;
  }
  if (checked !== expected) throw Error('Incomplete native body coverage');
  Object.assign(report, {checkedDefinitions: checked, eventsFullyValidated: book.order.length,
    checksExcluded: 0, outputPatches: 0});
  phase = 'codegen'; progress('validated', {checkedDefinitions: checked});
  codegenStart = performance.now();
  const observer = createCompileBookObserver(undefined, {onEvent(stage: string, name: string, state: any) {
    const now = performance.now(), elapsedMs = now - codegenStart;
    const boundary = stage.startsWith('c-pass-') ? /^c-pass-(\d+)-(before|after)$/.exec(stage) : null;
    if (boundary) currentPass = Number(boundary[1]);
    if (boundary || elapsedMs >= maxCodegenMs || now - lastWrite >= 1000) {
      lastWrite = now;
      report.last = {stage, name, pass: currentPass, codegenElapsedMs: elapsedMs,
        ownFacts: state.ownFacts, hotFacts: state.hotFacts, staticFacts: state.staticFacts};
      if (boundary?.[2] === 'after') report.passRows.push(report.last);
      progress(boundary?.[2] === 'after' ? 'pass-complete' : boundary ? 'pass-start' : 'progress', report.last);
    }
    if (boundary?.[2] === 'after' && currentPass >= passes) throw new ProbeStop('pass-budget');
    if (elapsedMs >= maxCodegenMs) throw new ProbeStop('codegen-time-budget');
  }});
  const c = C.compile_book(book, {observe: observer.observe});
  Object.assign(report, {status: 'CODEGEN_SETTLED', codegenSettled: true,
    codegenMs: performance.now() - codegenStart, cBytes: Buffer.byteLength(c),
    cSha256: createHash('sha256').update(c).digest('hex')});
  authenticate();
} catch (error) {
  const stopped = error instanceof ProbeStop;
  const diagnostic = kernel && error && typeof error === 'object' && '$' in error && error.$ === 'Err'
    ? kernel.err_show(error as import('../bend2/bend.ts').Err)
    : String(error instanceof Error ? error.message : error);
  Object.assign(report, {status: stopped ? 'PROBE_STOPPED' : 'FAIL', phase,
    reason: diagnostic,
    codegenMs: codegenStart ? performance.now() - codegenStart : null});
  try { authenticate(); } catch (drift) { report.status = 'FAIL'; report.reason = String(drift); }
  if (report.status === 'FAIL') process.exitCode = 2;
} finally {
  report.terminal = true;
  report.hostAfter = {logicalCpus: cpus().length, loadAverage: loadavg()};
  report.performanceComparisonWarning = report.hostBefore.loadAverage[0] > report.hostBefore.logicalCpus
    || report.hostAfter.loadAverage[0] > report.hostAfter.logicalCpus
    ? 'Host load exceeds logical CPU count; elapsed samples do not isolate candidate performance.' : null;
  save();
  console.log('CODEGEN_PROBE_RESULT ' + JSON.stringify({status: report.status, reason: report.reason,
    report: reportPath, codegenSettled: report.codegenSettled, outputPublished: false,
    passesCompleted: report.passRows.length, elapsedMs: report.elapsedMs}));
}
