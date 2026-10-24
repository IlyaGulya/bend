#!/usr/bin/env bun
// Build and run the bounded diagnostic native chunk-profile component.
//
// This compiles only evals/native_stage_profile_driver.bend (the generated
// Template/Checker Run machines plus the profile-only view), not the full
// compiler root, and runs a finite seeded Run under a tool deadline. It is
// diagnostic only: the output is operational chunk attribution, not acceptance,
// benchmark or source-substage evidence.
//
// usage: node --experimental-strip-types --max-old-space-size=4096 \
//   evals/native_stage_profile_build.ts [--artifact-dir=DIR] [--timeout-ms=N]
import {createHash} from 'node:crypto';
import {execFileSync, spawnSync} from 'node:child_process';
import {existsSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync} from 'node:fs';
import {dirname, join, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {tmpdir} from 'node:os';
import {nativeTraceObservations} from './compiler_stage_profile.mjs';
import type * as Bend from '../bend2/bend.ts';
import type * as Compiler from '../bend2/comp.ts';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const sha = bytes => createHash('sha256').update(bytes).digest('hex');

function options() {
  const values = new Map();
  for (const argument of process.argv.slice(2)) {
    const at = argument.indexOf('=');
    const name = at < 0 ? argument : argument.slice(0, at), value = at < 0 ? undefined : argument.slice(at + 1);
    if (!['--artifact-dir', '--timeout-ms'].includes(name) || value === undefined || values.has(name))
      throw Error('expected unique --artifact-dir=DIR or --timeout-ms=N, observed ' + argument);
    values.set(name, value);
  }
  const timeoutMs = Number(values.get('--timeout-ms') ?? '180000');
  if (!Number.isSafeInteger(timeoutMs) || timeoutMs < 1) throw Error('--timeout-ms must be a positive integer');
  return {artifactDir: values.has('--artifact-dir') ? resolve(values.get('--artifact-dir')) : undefined, timeoutMs};
}

const o = options();
const directory = o.artifactDir ?? mkdtempSync(join(tmpdir(), 'bend-native-stage-profile-'));
mkdirSync(directory, {recursive: true});
const kernelPath = join(root, 'bend2/bend.ts'), compilerPath = join(root, 'bend2/comp.ts');
const driverPath = join(root, 'evals/native_stage_profile_driver.bend');
const hostPath = join(root, 'evals/native_stage_profile_host.c');
const K = await import(kernelPath) as typeof Bend;
const C = await import(compilerPath) as typeof Compiler;
const started = performance.now();
const book = K.book_nil();
await K.book_load(book, driverPath, '', new Map());
K.book_valid(book);
const validationMs = performance.now() - started;
const codegenStart = performance.now();
const c = C.compile_book(book);
const codegenMs = performance.now() - codegenStart;
const cPath = join(directory, 'native-stage-profile.c');
const artifact = join(directory, 'native-stage-profile');
if (existsSync(cPath) || existsSync(artifact)) throw Error('artifact directory already holds a previous component: ' + directory);
writeFileSync(cPath, c, {flag: 'wx'});
const cc = process.env.CC ?? 'clang';
const flags = ['-std=c11', '-O0', '-pthread', cPath, '-lpthread', '-lm', '-o', artifact];
execFileSync(cc, flags, {stdio: 'inherit', timeout: o.timeoutMs});
const run = spawnSync(artifact, [], {encoding: 'utf8', timeout: o.timeoutMs});
if (run.error) throw run.error;
if (run.status !== 0) throw Error('native stage profile exited ' + String(run.status) + ': ' + (run.stderr ?? ''));
const stderr = run.stderr ?? '';
const observations = nativeTraceObservations(stderr);
const phases = observations.filter(row => row.kind === 'native-chunk-profile');
if (phases.length === 0) throw Error('native stage profile emitted no NATIVE_CHUNK_PROFILE rows: ' + stderr);
if (phases.some(row => row.values.chunkAdvances === 0))
  throw Error('native stage profile observed no chunk transitions; the fixture is not exercising the Run machine');
console.log(JSON.stringify({
  diagnosticOnly: true, acceptanceEvidence: false,
  directory, driverPath, driverSha256: sha(readFileSync(driverPath)), hostPath, hostSha256: sha(readFileSync(hostPath)),
  kernelSha256: sha(readFileSync(kernelPath)), compilerSha256: sha(readFileSync(compilerPath)),
  cPath, cSha256: sha(c), artifact, artifactSha256: sha(readFileSync(artifact)),
  buildCommand: [cc, ...flags], validationMs, codegenMs, totalMs: performance.now() - started,
  runtime: {node: process.versions.node, v8: process.versions.v8, platform: process.platform, arch: process.arch},
  phases: phases.map(row => ({name: row.name, values: row.values, details: row.details})),
  note: 'profile-only native driver over the real generated Template/Checker Run machine with a finite seeded stack; not a compiler workload and not a source-substage CPU claim',
}));
