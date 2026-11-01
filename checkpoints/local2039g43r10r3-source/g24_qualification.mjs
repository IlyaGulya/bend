#!/usr/bin/env bun
/**
 * Complete G24 qualification runner.
 *
 * One committed orchestration of the existing, accepted gates. Nothing here
 * replaces a gate: the parser rebuild, native build, real stage0->stage1->stage2
 * fixedpoint, emitted-image fixture suites, C/JS matrices, native/library,
 * admission and host-consumer suites are all driven through their existing
 * entry points and authenticated receipts.
 *
 * Correctness only:
 *   bun --smol evals/g24_qualification.mjs --run-id=NAME --node=NODE \
 *     --phase=correctness [--bun=BUN] [--clang=CLANG] \
 *     [--llvm-bin=/opt/homebrew/opt/llvm@21/bin] [--out=checkpoints/NAME]
 *
 * Full phase (default: correctness + paired frozen-corpus throughput):
 *   bun --smol evals/g24_qualification.mjs --run-id=NAME --node=NODE \
 *     --bindings=PATH --frozen-repository=PATH \
 *     --control-native=PATH --control-image=PATH [--bun=BUN] [--clang=CLANG] \
 *     [--llvm-bin=...] [--out=checkpoints/NAME]
 *   The full phase measures throughput immediately after the authenticated
 *   fixedpoint, before expensive consumer matrices. Final PASS still requires
 *   every consumer gate; early measurements never imply compiler acceptance.
 *
 * Run this runner directly, never inside another heavy_gate: it applies the
 * accepted guard to each heavy step itself, and the matrix runner starts one
 * exclusive gate per fixture stage.
 *
 * Throughput-only phase against a prior correctness receipt:
 *   bun --smol evals/g24_qualification.mjs --run-id=NAME --node=NODE \
 *     --phase=throughput --from-receipt=checkpoints/NAME/receipt.json \
 *     --bindings=PATH --frozen-repository=PATH --control-native=PATH \
 *     --control-image=PATH [--out=checkpoints/NAME-throughput]
 *
 * Opt-in strict performance rejection (default off; historical and default runs
 * keep their exact previous behavior):
 *   add --fail-fast-performance=true to a throughput-measuring invocation
 *   (full phase or --phase=throughput). After the 12 authenticated measurements
 *   are published, each runtime (native, js) must satisfy:
 *     candidate pipeline arithmetic mean AND median strictly less than control;
 *     candidate median peak RSS AND median peak footprint less than or equal
 *     to control.
 *   Exactly three control and three candidate rows per runtime, finite
 *   nonnegative metrics and every original row are required; rows are never
 *   excluded. The bounded performanceDecision is published in the receipt
 *   before a rejection throws through the existing catch path. A rejection
 *   keeps completed full-root/fixedpoint/measurement evidence, leaves
 *   correctnessPassed false, and never produces a *_PASS status. This is
 *   rejection evidence only, never compiler or performance acceptance.
 *
 * Explicit distributed transport (default remains serial):
 *   add --distributed-plan=PLAN.json. See g24_distributed.mjs for the pinned
 *   SSH/local-single-host plan, complete snapshot and cancellation protocol.
 *   The native->stage1->stage2 chain and emitted-image gate stay serial;
 *   all C/JS matrices and native/admission/host consumers remain mandatory.
 *   Performance lanes keep six rows on one pinned dedicated physical host,
 *   native before JS, and do not claim global same-host serial execution.
 * Native build experiment: --cc-partitions=4|8 (default 4), forbidden for
 * throughput-only runs; backend children remain bounded by the native helper.
 *
 * Every heavy child inherits the original 8192 MiB RSS / 8192 MiB footprint /
 * 10 ms / 600000 ms gate. Every child process runs with an explicit cwd. The
 * receipt is published atomically and bounded; child logs stay beside it.
 *
 * This runner never claims compiler or performance acceptance. It publishes
 * execution evidence for the parent-owned integration decision.
 */
import {createHash} from 'node:crypto';
import {
  chmodSync, closeSync, existsSync, mkdirSync, openSync, readFileSync, readSync,
  readdirSync, realpathSync, renameSync, statSync, writeFileSync,
} from 'node:fs';
import {basename, dirname, isAbsolute, relative, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
import os from 'node:os';

import {
  ABI, authenticateNativeSeedBuild, corpusFile, corpusFor, requireNativeRun,
  runNativeStage0, runtimeManifest, workloadRows,
} from './native_seed_runtime.mjs';
import {runHeavyGate} from './heavy_gate.ts';
import {SELFHOST_SOURCE_FILE_TAG, sourceFileTagFromRoot, verifySourceFileCarrier} from './checker_core_step_runtime.mjs';
import {loadPlan, distributedConsumers, distributedMeasurements} from './g24_distributed.mjs';
import {hashFile} from './g24_snapshot.mjs';

const SCRIPT = fileURLToPath(import.meta.url);
const LIMITS = Object.freeze({memoryMiB: 8192, rssMiB: 8192, pollMs: 10, timeoutMs: 600000});
const EXPECTED_ABI = Object.freeze(['parsed_module', 'parse_with_fuel', 'expand_modules_start', 'template_step',
  'check_expanded_start', 'inspect_checked_start', 'checker_step', 'emit_modules_start',
  'emit_library_start', 'emitter_step',
  'emit_c_modules_start', 'emit_c_library_start', 'c_emitter_step']);
// The matrix gate is the authority on which cases exist. The runner never
// asserts a literal count: it requires the gate's all-cases mode and checks
// that every announced case has complete per-case evidence, so adding a case
// is picked up without editing the orchestrator.
const MATRIX_TIMEOUT_MS = LIMITS.timeoutMs * 512;
const MAX_RECEIPT_BYTES = 262144;
const MAX_TEXT = 4096;

// The accepted G23 native/library consumer suite. Each file is executed on
// both targets; expectations are the fixture's own `#|` lines.
const NATIVE_SUITE_FILES = Object.freeze([
  'tests/run/c_backend_link.bend', 'tests/run/family_field_hot.bend',
  'tests/run/list_rebox_sum.bend', 'tests/run/array_fork.bend',
  'tests/run/array_atomic_fadd.bend', 'tests/run/array_atomic_edges.bend',
  'tests/run/f32_read_round_once.bend', 'tests/run/f32_read_whitespace.bend',
  'tests/run/f32_pow_unit_base.bend', 'tests/run/word_float_roundtrip.bend',
  'tests/base/map_prefix_keys.bend', 'tests/base/text_ops.bend',
  'tests/run/native_string_borrow.bend', 'tests/reg/checker_arena_names.bend',
  'tests/reg/phys_storage_paths.bend',
]);
const HOST_CONSUMER_FILES = Object.freeze([
  'tests/io/nat_host_export.bend', 'tests/io/nat_alias_export.bend',
  'tests/io/shadowed_nat_export.bend', 'tests/io/generic_export_identity.bend',
  'tests/io/text_host_export.bend',
]);
function distributedConsumerFiles() {
  return [...NATIVE_SUITE_FILES, ...HOST_CONSUMER_FILES, 'evals/c_step_library_fixture.bend'];
}
const ADMISSION_INPUTS = Object.freeze({
  template: 'import Base\n\ntype Box<~a: Type> is Data:\n\ndef main() -> U32:\n  1\n',
  mainless: 'import Base\n\ndef twice(+x: U32) -> U32:\n  U32.add(x, x)\n',
  unit: 'import Base\n\ndef main() -> Unit:\n  Unit{}\n',
  untypedNoLaw: 'import Base\n\ndef main():\n  Unit{}\n',
  lawOwned: 'import Base\n\nlaw main: Unit\ndef main():\n  Unit{}\n',
});

function fail(message) {
  throw Error(String(message));
}
function cap(value, limit = MAX_TEXT) {
  const text = String(value ?? '');
  return text.length <= limit ? text : text.slice(0, limit) + '\n[truncated ' + (text.length - limit) + ' chars]';
}
function hash(bytes) {
  return createHash('sha256').update(bytes).digest('hex');
}
function fileSha(path) {
  return hashFile(realpathSync(path));
}
function readJson(path) {
  return JSON.parse(readFileSync(path, 'utf8'));
}
function writeJsonFresh(path, value) {
  if (existsSync(path)) fail('refusing to overwrite ' + path);
  writeFileSync(path, JSON.stringify(value, null, 2) + '\n', {flag: 'wx'});
}
function tail(path, limit = MAX_TEXT) {
  if (!existsSync(path)) return '';
  const size = statSync(path).size, length = Math.min(size, limit), buffer = Buffer.alloc(length);
  if (length === 0) return '';
  const fd = openSync(path, 'r');
  try {
    readSync(fd, buffer, 0, length, size - length);
  } finally {
    closeSync(fd);
  }
  return buffer.toString('utf8');
}
function shellQuote(value) {
  return "'" + String(value).replaceAll("'", "'\\''") + "'";
}
function median(values) {
  const sorted = [...values].sort((a, b) => a - b), middle = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2;
}
function stats(values) {
  const sorted = [...values].sort((a, b) => a - b), mid = median(sorted);
  return {n: sorted.length, min: sorted[0], median: mid, max: sorted[sorted.length - 1],
    relativeRange: sorted[0] ? (sorted[sorted.length - 1] - sorted[0]) / sorted[0] : 0};
}
function withCwd(directory, action) {
  const previous = process.cwd();
  try {
    process.chdir(directory);
    return action();
  } finally {
    process.chdir(previous);
  }
}

function parseOptions(argv, allowedValues, allowedFlags = []) {
  const values = new Map(), flags = new Set();
  for (const argument of argv) {
    if (!argument.startsWith('--')) fail('unexpected positional argument: ' + argument);
    const at = argument.indexOf('=');
    const name = at < 0 ? argument : argument.slice(0, at), value = at < 0 ? undefined : argument.slice(at + 1);
    if (allowedFlags.includes(name) && value === undefined) {
      if (flags.has(name)) fail('duplicate flag ' + name);
      flags.add(name);
      continue;
    }
    if (!allowedValues.includes(name)) fail('unknown option ' + name);
    if (value === undefined || value === '') fail('option ' + name + ' needs a value');
    if (values.has(name)) fail('duplicate option ' + name);
    values.set(name, value);
  }
  return {values, flags};
}
function required(values, name) {
  const value = values.get(name);
  if (value === undefined) fail('missing required ' + name);
  return value;
}
function booleanOption(values, name) {
  const value = values.get(name);
  if (value === undefined) return false;
  if (value === 'true') return true;
  if (value === 'false') return false;
  fail(name + ' accepts only true or false, got ' + JSON.stringify(value));
}
function assertAbi() {
  if (JSON.stringify(ABI) !== JSON.stringify(EXPECTED_ABI) || ABI.length !== 13)
    fail('public runtime ABI changed: ' + JSON.stringify(ABI));
}
function assertGuardian(guardian, label) {
  if (guardian?.status !== 'PASS' || guardian.reportPhase !== 'complete' || guardian.ownedTreeStopped !== true)
    fail(label + ' guardian did not stop an owned complete tree: ' + JSON.stringify(guardian?.status ?? null));
  if (guardian.memoryLimitBytes !== LIMITS.memoryMiB * 1024 * 1024
    || guardian.rssLimitBytes !== LIMITS.rssMiB * 1024 * 1024 || guardian.timeoutMs !== LIMITS.timeoutMs)
    fail(label + ' guardian limits changed: ' + JSON.stringify(guardian));
  if (guardian.commandExitCode !== 0) fail(label + ' guardian command exited ' + guardian.commandExitCode);
}
function assertNativeChunkEvidence(run, sources) {
  const parse = run.phases.find(row => row.phase === 'parse');
  if (!parse || parse.eagerFuelCells !== sources * 8000000)
    fail('native eager parse fuel is not 8000000 per source: ' + JSON.stringify(parse));
  for (const row of run.phases) {
    if (row.phase === 'parse') continue;
    if (row.chunkQuantum !== 64) fail('native chunk quantum changed: ' + JSON.stringify(row));
  }
  if (!run.begins.length || run.begins[0].parserFuel !== 8000000)
    fail('native parser fuel record changed: ' + JSON.stringify(run.begins));
}

// ---------------------------------------------------------------------------
// Orchestrator
// ---------------------------------------------------------------------------

function hostInfo() {
  const cpus = os.cpus();
  return {
    model: cpus[0]?.model ?? 'unknown', cpu: cpus[0]?.model ?? 'unknown',
    memoryBytes: os.totalmem(), logicalCPUs: cpus.length,
    os: os.platform() + ' ' + os.release() + ' ' + (os.version?.() ?? ''),
  };
}

function checkpointsFor(repository) {
  const directory = resolve(repository, 'checkpoints');
  if (!existsSync(directory)) fail('missing checkpoints directory: ' + directory);
  return directory;
}

function assertFreshNamespace(checkpoints, runId, out) {
  const outName = basename(out);
  for (const entry of readdirSync(checkpoints)) {
    if (!entry.includes(runId)) continue;
    const name = entry;
    if (name === outName) continue;
    fail('run id ' + runId + ' already has artifact ' + resolve(checkpoints, name) + '; choose a fresh --run-id');
  }
  if (existsSync(out)) fail('output directory already exists: ' + out);
}

function preflightTools({repository, bun, node, clang, llvmBin}) {
  for (const [name, path] of [['bun', bun], ['node', node]]) {
    if (!existsSync(path)) fail('unreachable prerequisite: ' + name + ' not found at ' + path);
  }
  const bunVersion = spawnSync(bun, ['--version'], {cwd: repository, encoding: 'utf8', timeout: 60000});
  if (bunVersion.status !== 0 || !/^\d+\.\d+\.\d+/.test(bunVersion.stdout.trim()))
    fail('unreachable prerequisite: bun is not runnable at ' + bun + ': ' + cap(bunVersion.stderr));
  const nodeVersion = spawnSync(node, ['--version'], {cwd: repository, encoding: 'utf8', timeout: 60000});
  if (nodeVersion.status !== 0 || nodeVersion.stdout.trim() !== 'v23.11.0')
    fail('unreachable prerequisite: node must be the accepted v23.11.0 V8 runtime, got ' + cap(nodeVersion.stdout + nodeVersion.stderr));
  const clangVersion = spawnSync(clang, ['--version'], {cwd: repository, encoding: 'utf8', timeout: 60000});
  if (clangVersion.status !== 0 || !/^Apple clang version 21\./m.test(clangVersion.stdout))
    fail('unreachable prerequisite: native LLVM split requires Apple clang 21 at ' + clang + ': ' + cap(clangVersion.stdout + clangVersion.stderr));
  for (const tool of ['opt', 'llvm-split']) {
    const path = resolve(llvmBin, tool);
    if (!existsSync(path)) fail('unreachable prerequisite: missing ' + path);
    const probe = spawnSync(path, ['--version'], {cwd: repository, encoding: 'utf8', timeout: 60000});
    if (probe.status !== 0 && tool === 'opt')
      fail('unreachable prerequisite: ' + path + ' is not executable: ' + cap(probe.stderr));
  }
  return {
    bun: {path: bun, sha256: fileSha(bun), version: bunVersion.stdout.trim()},
    node: {path: node, sha256: fileSha(node), version: nodeVersion.stdout.trim()},
    clang: {command: clang, resolved: spawnSync('/usr/bin/env', ['which', clang], {encoding: 'utf8'}).stdout.trim()},
    llvmBin,
  };
}

function validateBindings(bindingsPath, {repository, frozenRepository, controlNative, controlImage}) {
  if (!existsSync(bindingsPath)) fail('unreachable prerequisite: throughput bindings not found: ' + bindingsPath);
  const bindings = readJson(bindingsPath);
  if (bindings.schemaVersion !== 1) fail('unsupported throughput bindings schema');
  for (const key of ['native', 'image', 'frozenRoot', 'frozenInputs', 'originalLimits', 'expectedBaselineOutput'])
    if (bindings[key] === undefined) fail('throughput bindings lack ' + key);
  for (const [name, row] of [['native', bindings.native], ['image', bindings.image], ['frozenRoot', bindings.frozenRoot]])
    if (typeof row?.path !== 'string' || !/^[0-9a-f]{64}$/.test(row.sha256 ?? '') || !Number.isSafeInteger(row.bytes))
      fail('throughput bindings ' + name + ' record is malformed');
  if (JSON.stringify(bindings.originalLimits) !== JSON.stringify({memoryMiB: 8192, rssMiB: 8192, timeoutMs: 600000}))
    fail('throughput bindings limits differ from the original guard');
  if (!/^[0-9a-f]{64}$/.test(bindings.expectedBaselineOutput ?? ''))
    fail('throughput bindings lack the accepted baseline output hash');
  if (!existsSync(frozenRepository)) fail('unreachable prerequisite: frozen repository not found: ' + frozenRepository);
  const frozen = realpathSync(frozenRepository);
  if (!existsSync(controlNative)) fail('unreachable prerequisite: control native binary not found: ' + controlNative);
  if (!existsSync(controlImage)) fail('unreachable prerequisite: control stage-one image not found: ' + controlImage);
  if (fileSha(controlNative) !== bindings.native.sha256 || statSync(controlNative).size !== bindings.native.bytes)
    fail('control native binary does not match the bindings');
  if (fileSha(controlImage) !== bindings.image.sha256 || statSync(controlImage).size !== bindings.image.bytes)
    fail('control stage-one image does not match the bindings');

  const recordedRoot = bindings.frozenRoot.path;
  // The frozen root lives directly in <frozen repository>/checkpoints, so the
  // repository root is its grandparent on the recording host.
  const recordedFrozen = dirname(dirname(recordedRoot));
  const mapFrozen = recorded => {
    if (!isAbsolute(recorded)) fail('bindings frozen path is not absolute: ' + recorded);
    const rel = relative(recordedFrozen, recorded);
    if (rel.startsWith('..') || isAbsolute(rel)) fail('bindings path escapes the frozen repository: ' + recorded);
    const actual = resolve(frozen, rel);
    if (relative(frozen, actual).startsWith('..')) fail('bindings path escapes the frozen repository: ' + recorded);
    return actual;
  };
  const actualRoot = mapFrozen(recordedRoot);
  if (!existsSync(actualRoot)) fail('unreachable prerequisite: frozen root not found: ' + actualRoot);
  if (fileSha(actualRoot) !== bindings.frozenRoot.sha256 || statSync(actualRoot).size !== bindings.frozenRoot.bytes)
    fail('frozen compiler root does not match the bindings');
  const expectedInputs = new Map();
  for (const [recorded, digest] of Object.entries(bindings.frozenInputs ?? {})) {
    const actual = mapFrozen(recorded);
    if (!existsSync(actual)) fail('unreachable prerequisite: frozen input missing: ' + actual);
    if (fileSha(actual) !== digest) fail('frozen input changed: ' + actual);
    expectedInputs.set(realpathSync(actual), digest);
  }
  if (expectedInputs.size === 0) fail('bindings authenticate no frozen inputs');
  const closure = withCwd(frozen, () => workloadRows(actualRoot, 'js'));
  const actualInputs = new Map([...closure.sources, ...closure.externals].map(row => [row.file, row.sha256]));
  if (actualInputs.size !== expectedInputs.size || [...expectedInputs].some(([path, digest]) => actualInputs.get(path) !== digest))
    fail('frozen workload closure differs from the bindings');
  return {
    path: realpathSync(bindingsPath), sha256: fileSha(bindingsPath), bindings,
    frozenRepository: frozen, frozenRoot: realpathSync(actualRoot),
    inputs: Object.fromEntries([...actualInputs].sort()),
    controlNative: realpathSync(controlNative), controlNativeSha256: bindings.native.sha256,
    controlImage: realpathSync(controlImage), controlImageSha256: bindings.image.sha256,
    expectedBaselineOutput: bindings.expectedBaselineOutput,
  };
}

function childEnv({repository, node, bun, clang, llvmBin}) {
  const path = [dirname(node), dirname(bun), llvmBin, '/opt/homebrew/bin', '/usr/bin', '/bin', '/usr/sbin', '/sbin',
    process.env.PATH ?? ''].filter(Boolean).join(':');
  // Self-guarded scripts call guardHeavyGate without options and would
  // otherwise inherit heavy_gate's 3072/2048/100 defaults. These values are
  // authoritative for every child, independent of the caller's environment.
  return {...process.env, PATH: path, CC: clang, BEND_NO_TELEMETRY: '1',
    HEAVY_GATE_MEMORY_MIB: String(LIMITS.memoryMiB),
    HEAVY_GATE_RSS_MIB: String(LIMITS.rssMiB),
    HEAVY_GATE_POLL_MS: String(LIMITS.pollMs),
    HEAVY_GATE_TIMEOUT_MS: String(LIMITS.timeoutMs)};
}

function createRun({repository, runId, node, bun, clang, llvmBin, out, phase}) {
  const receipt = {
    schemaVersion: 1,
    status: 'IN_PROGRESS',
    runId,
    phase,
    scope: 'Complete G24 candidate correctness and paired frozen-corpus throughput orchestration. Execution evidence only; compiler and performance acceptance remain parent-owned.',
    repository: realpathSync(repository),
    out,
    launchCwd: process.cwd(),
    limits: {...LIMITS},
    abi: [...ABI],
    quantum: 64,
    parserFuel: 8000000,
    tools: {node, bun, clang, llvmBin},
    host: hostInfo(),
    started: Date.now(),
    steps: [],
    correctness: null,
    throughput: null,
    failure: null,
    correctnessPassed: false,
    throughputMeasured: false,
    failFastPerformance: false,
    performanceDecision: null,
    compilerAccepted: false,
    acceptanceOwner: 'parent',
    boundedReceiptBytes: MAX_RECEIPT_BYTES,
  };
  const env = childEnv({repository, node, bun, clang, llvmBin});
  let published = false;

  function publish() {
    receipt.updated = Date.now();
    let text;
    try {
      text = JSON.stringify(receipt, null, 2) + '\n';
    } catch (error) {
      text = JSON.stringify({schemaVersion: 1, status: receipt.status, runId, error: 'receipt serialization failed: ' + String(error)}, null, 2) + '\n';
    }
    if (Buffer.byteLength(text) > MAX_RECEIPT_BYTES) {
      const minimal = {
        schemaVersion: 1, status: receipt.status, runId, phase: receipt.phase,
        repository: receipt.repository, out, failure: receipt.failure,
        failFastPerformance: receipt.failFastPerformance,
        performanceDecision: receipt.performanceDecision,
        note: 'Bounded receipt exceeded ' + MAX_RECEIPT_BYTES + ' bytes; child logs and step statuses remain in this directory.',
        stepCount: receipt.steps.length,
        steps: receipt.steps.map(row => ({label: row.label, status: row.status, exitCode: row.exitCode, elapsedMs: row.elapsedMs})),
        updated: receipt.updated,
      };
      text = JSON.stringify(minimal, null, 2) + '\n';
    }
    const target = resolve(out, 'receipt.json'), temporary = target + '.tmp';
    writeFileSync(temporary, text);
    renameSync(temporary, target);
    published = true;
  }

  function logPaths(label) {
    const directory = resolve(out, 'logs');
    mkdirSync(directory, {recursive: true});
    const safe = label.replace(/[^A-Za-z0-9_.-]/g, '_');
    return [resolve(directory, safe + '.stdout'), resolve(directory, safe + '.stderr')];
  }

  function record(row) {
    if (!receipt.steps.includes(row)) receipt.steps.push(row);
    publish();
    console.log(JSON.stringify({step: row.label, status: row.status, exitCode: row.exitCode, elapsedMs: row.elapsedMs}));
    return row;
  }

  function runPlain(label, command, {cwd = repository, timeoutMs = LIMITS.timeoutMs * 4} = {}) {
    const [stdoutPath, stderrPath] = logPaths(label);
    if (existsSync(stdoutPath) || existsSync(stderrPath)) fail('duplicate log namespace: ' + label);
    const outFd = openSync(stdoutPath, 'wx'), errFd = openSync(stderrPath, 'wx');
    const row = {label, kind: 'command', cwd, command, stdout: stdoutPath, stderr: stderrPath,
      started: Date.now(), status: 'RUNNING'};
    record(row);
    let result;
    try {
      result = spawnSync(command[0], command.slice(1), {
        cwd, env, stdio: ['ignore', outFd, errFd], timeout: timeoutMs, killSignal: 'SIGKILL', maxBuffer: 1 << 20,
      });
    } finally {
      closeSync(outFd);
      closeSync(errFd);
    }
    Object.assign(row, {
      status: result.status === 0 ? 'PASS' : 'FAIL', exitCode: result.status, signal: result.signal,
      elapsedMs: Date.now() - row.started, error: result.error ? cap(String(result.error)) : undefined,
      stdoutBytes: statSync(stdoutPath).size, stderrBytes: statSync(stderrPath).size,
      stdoutSha256: fileSha(stdoutPath), stderrSha256: fileSha(stderrPath),
    });
    if (row.status !== 'PASS') {
      row.stderrTail = tail(stderrPath);
      record(row);
      fail(label + ' exited ' + (result.signal ?? result.status) + ': ' + row.stderrTail);
    }
    record(row);
    return row;
  }

  async function runGuarded(label, command, {cwd = repository} = {}) {
    const [stdoutPath, stderrPath] = logPaths(label);
    if (existsSync(stdoutPath) || existsSync(stderrPath)) fail('duplicate log namespace: ' + label);
    const wrapped = ['/bin/sh', '-c', 'out=$1; err=$2; shift 2; exec "$@" >"$out" 2>"$err"',
      'sh', stdoutPath, stderrPath, ...command];
    const row = {label, kind: 'guarded', cwd, command, stdout: stdoutPath, stderr: stderrPath,
      started: Date.now(), status: 'RUNNING'};
    record(row);
    const guardian = await runHeavyGate(wrapped, {
      label, memoryMiB: LIMITS.memoryMiB, rssMiB: LIMITS.rssMiB, pollMs: LIMITS.pollMs, timeoutMs: LIMITS.timeoutMs,
    });
    Object.assign(row, {
      status: guardian.status === 'PASS' && guardian.exitCode === 0 ? 'PASS' : 'FAIL',
      exitCode: guardian.exitCode, elapsedMs: Date.now() - row.started,
      stdoutBytes: existsSync(stdoutPath) ? statSync(stdoutPath).size : 0,
      stderrBytes: existsSync(stderrPath) ? statSync(stderrPath).size : 0,
      stdoutSha256: existsSync(stdoutPath) ? fileSha(stdoutPath) : undefined,
      stderrSha256: existsSync(stderrPath) ? fileSha(stderrPath) : undefined,
      guardian: {status: guardian.status, reason: guardian.reason, peakRssBytes: guardian.peakRssBytes,
        peakFootprintBytes: guardian.peakFootprintBytes, elapsedMs: guardian.elapsedMs,
        reportPhase: guardian.reportPhase, ownedTreeStopped: guardian.ownedTreeStopped,
        commandExitCode: guardian.commandExitCode, timeoutMs: guardian.timeoutMs,
        memoryLimitBytes: guardian.memoryLimitBytes, rssLimitBytes: guardian.rssLimitBytes},
    });
    if (row.status !== 'PASS') {
      row.stderrTail = tail(stderrPath);
      record(row);
      fail(label + ' failed under the original guard: ' + row.stderrTail);
    }
    assertGuardian(guardian, label);
    record(row);
    return row;
  }

  return {receipt, publish, runPlain, runGuarded, env, get published() { return published; }};
}

function validateNativeBuildAuthenticated(auth, {root, corpusPath}) {
  if (auth.binarySha256 !== fileSha(auth.binary)) fail('native build artifact hash drift');
  if (typeof auth.report?.checkedDefinitions !== 'number' || auth.report.checkedDefinitions !== auth.report.expectedSourceDefinitions)
    fail('native build body coverage is partial');
  if (auth.report.checksExcluded !== 0 || auth.report.outputPatches !== 0)
    fail('native build excluded checks or patched output');
  if (realpathSync(root) !== auth.report.source || fileSha(root) !== auth.report.sourceSha256)
    fail('native build did not validate the fresh compiler root');
  if (realpathSync(corpusPath) !== auth.corpusPath) fail('native build corpus path drift');
  return {binary: auth.binary, binarySha256: auth.binarySha256, cPath: auth.report.cPath,
    cSha256: auth.report.cSha256, checkedDefinitions: auth.report.checkedDefinitions,
    eventsFullyValidated: auth.report.eventsFullyValidated, corpusPath: auth.corpusPath,
    corpusSha256: auth.corpusSha256};
}

function validateJavascriptBuild(buildPath, {artifact, source}) {
  if (!existsSync(buildPath)) fail('missing JS component build result: ' + buildPath);
  const build = readJson(buildPath);
  if (build.status !== 'JS_GENERATED_NOT_YET_EXECUTED')
    fail('JS component build status changed: ' + build.status);
  if (build.checksExcluded !== 0 || build.outputPatches !== 0)
    fail('JS component build excluded checks or patched output');
  if (build.checkedOutputRetention !== 'native e')
    fail('JS component build checked-output retention changed');
  if (realpathSync(build.artifactPath) !== realpathSync(artifact) || build.artifactSha256 !== fileSha(artifact))
    fail('JS component build artifact identity drift');
  if (realpathSync(build.sourcePath) !== realpathSync(source) || build.sourceSha256 !== fileSha(source))
    fail('JS component build did not consume the fresh compiler root');
  assertGuardian(build.guardian, 'js-build');
  if (typeof build.provenancePath !== 'string' || !existsSync(build.provenancePath))
    fail('JS component build provenance is missing');
  const {provenanceSha256, ...provenance} = readJson(build.provenancePath);
  if (provenanceSha256 !== build.provenanceSha256 || hash(JSON.stringify(provenance)) !== provenanceSha256)
    fail('JS component build provenance content changed');
  for (const field of ['protectedPins', 'loadedInputs']) {
    const pins = provenance[field];
    if (!pins || typeof pins !== 'object' || Object.keys(pins).length === 0)
      fail('JS component build provenance lacks ' + field);
    for (const [path, digest] of Object.entries(pins)) {
      if (!existsSync(path)) fail('JS component build input is missing: ' + path);
      if (fileSha(path) !== digest) fail('JS component build input changed: ' + path);
    }
  }
  return {path: realpathSync(buildPath), sha256: fileSha(buildPath), artifact: realpathSync(artifact),
    artifactSha256: build.artifactSha256};
}

function validateFixedpoint(reportPath, {binarySha256}) {
  const proof = readJson(reportPath);
  if (proof.status !== 'NATIVE_SEED_BOOTSTRAP_FIXEDPOINT' || proof.passed !== true || proof.compilerBootstrapGreen !== true)
    fail('full native-seed fixedpoint report is not green: ' + proof.status);
  if (proof.seedMode !== 'native') fail('fixedpoint report is not native-seed mode');
  if (proof.fixedpoint?.equal !== true || proof.fixedpoint.stageOneSha256 !== proof.fixedpoint.stageTwoSha256)
    fail('real stage-one/stage-two byte fixedpoint is not proven');
  if (proof.boundary?.checksExcluded !== 0 || proof.boundary?.outputPatches !== 0)
    fail('fixedpoint boundary excluded checks or patched output');
  if (proof.boundary?.hostChecking !== false || proof.boundary?.hostParsing !== false
    || proof.boundary?.embeddedSource !== false || proof.boundary?.cachedAst !== false)
    fail('fixedpoint boundary changed');
  assertGuardian(proof.guardian, 'bootstrap');
  const one = proof.artifacts?.stageOne, two = proof.artifacts?.stageTwo;
  for (const [artifact, name] of [[one, 'stage-one'], [two, 'stage-two']]) {
    if (!artifact || typeof artifact.path !== 'string' || !existsSync(artifact.path))
      fail('missing ' + name + ' artifact');
    if (fileSha(artifact.path) !== artifact.sha256 || statSync(artifact.path).size !== artifact.bytes)
      fail(name + ' artifact identity drift');
  }
  if (!readFileSync(one.path).equals(readFileSync(two.path))) fail('stage-one and stage-two bytes differ');
  const nativeRun = proof.nativeRun;
  if (!nativeRun || nativeRun.binarySha256 !== binarySha256)
    fail('fixedpoint native run does not use the fresh native build');
  if (nativeRun.buildSha256 !== fileSha(nativeRun.build))
    fail('fixedpoint native run build report drift');
  const phases = nativeRun.phases ?? [];
  if (!phases.length) fail('fixedpoint report lacks native phase evidence');
  const chunks = phases.filter(row => row.chunkQuantum !== undefined);
  if (chunks.length < 3 || chunks.some(row => row.chunkQuantum !== 64))
    fail('fixedpoint native chunk quantum is not 64');
  const parse = phases.find(row => row.phase === 'parse');
  if (!parse || parse.eagerFuelCells % 8000000 !== 0) fail('fixedpoint native parse fuel accounting changed');
  const seedRows = (proof.fixtureRows ?? []).filter(row => row.stage === 'seed');
  if (seedRows.length !== 95 || new Set(seedRows.map(row => row.name)).size !== 95)
    fail('fixedpoint did not execute all 95 original seed fixtures');
  return {proof, stageOne: {path: realpathSync(one.path), sha256: one.sha256, bytes: one.bytes},
    stageTwo: {path: realpathSync(two.path), sha256: two.sha256, bytes: two.bytes}};
}

function validateEmittedSuites(reportPath, stageOne) {
  const report = readJson(reportPath);
  if (report.status !== 'EMITTED_SUITES_BEHAVIOR_PASS' || report.passed !== true)
    fail('emitted-image behavior suites did not pass: ' + report.status);
  // selfhost_emitted_suites.ts publishes evidenceCounts and per-stage
  // fixtureRows (objects), not tuple rows under stage.fixtures.
  const counts = report.evidenceCounts ?? {};
  if (counts.existingSeed !== 95 || counts.freshStageOne !== 95 || counts.freshStageTwo !== 95
    || counts.freshEmitted !== 190 || counts.total !== 285)
    fail('emitted-image suite evidence counts changed: ' + JSON.stringify(counts));
  if (!Array.isArray(report.stages) || report.stages.length !== 2
    || new Set(report.stages.map(stage => stage.stage)).size !== 2)
    fail('emitted suite did not publish both unchanged images');
  for (const stage of report.stages) {
    if (!['stage-one', 'stage-two'].includes(stage.stage) || stage.imageSha256 !== stageOne.sha256
      || stage.passed !== true || stage.exitCode !== 0
      || stage.workerResult?.fixtureExecutions !== 95
      || !Array.isArray(stage.fixtureRows) || stage.fixtureRows.length !== 95
      || stage.fixtureRows.some(row => row.passed !== true || typeof row.name !== 'string')
      || new Set(stage.fixtureRows.map(row => row.name)).size !== 95)
      fail('emitted suite stage evidence changed: ' + stage.stage);
  }
  assertGuardian(report.guardian, 'emitted-suites');
  return {path: realpathSync(reportPath), sha256: fileSha(reportPath), status: report.status, counts};
}

// Resuming throughput from a prior correctness receipt must not launder old
// artifacts under a changed source tree. Re-authenticate the recorded root,
// native build/corpus/source closure, fixedpoint and emitted-image evidence
// against the current repository before accepting the carried binary/image.
function authenticatePriorCorrectness(priorPath, repository) {
  if (!existsSync(priorPath)) fail('unreachable prerequisite: prior correctness receipt not found: ' + priorPath);
  const prior = realpathSync(priorPath), receiptSha256 = fileSha(prior), previous = readJson(prior);
  if (!['G24_CORRECTNESS_PASS', 'G24_QUALIFICATION_PASS'].includes(previous.status)
    || previous.correctnessPassed !== true || previous.correctness?.fixedpoint?.equal !== true)
    fail('prior receipt is not a passing G24 correctness run: ' + previous.status);
  if (typeof previous.repository !== 'string' || !existsSync(previous.repository)
    || realpathSync(previous.repository) !== repository)
    fail('prior receipt belongs to a different repository: ' + String(previous.repository));
  if (JSON.stringify(previous.limits) !== JSON.stringify({...LIMITS}))
    fail('prior receipt used different limits');
  if (JSON.stringify(previous.abi) !== JSON.stringify([...ABI])
    || previous.quantum !== 64 || previous.parserFuel !== 8000000)
    fail('prior receipt has a different ABI/quantum/fuel contract');
  const correctness = previous.correctness;
  const root = correctness.root, native = correctness.native, fixed = correctness.fixedpoint,
    emitted = correctness.emitted;
  for (const [label, path, digest] of [
    ['compiler root', root.path, root.sha256],
    ['root manifest', root.manifest, root.manifestSha256],
    ['native build', native.build?.path, native.build?.sha256],
    ['native binary', native.binary, native.binarySha256],
    ['native C', native.cPath, native.cSha256],
    ['native corpus', native.corpusPath, native.corpusSha256],
    ['fixedpoint report', fixed.report?.path, fixed.report?.sha256],
    ['stage-one image', fixed.stageOne?.path, fixed.stageOne?.sha256],
    ['stage-two image', fixed.stageTwo?.path, fixed.stageTwo?.sha256],
    ['emitted report', emitted?.path, emitted?.sha256],
  ]) {
    if (typeof path !== 'string' || !existsSync(path)) fail('prior receipt ' + label + ' is missing');
    if (fileSha(path) !== digest) fail('prior receipt ' + label + ' changed');
  }
  const auth = authenticateNativeSeedBuild(native.build.path, {
    root: root.path, corpusPath: native.corpusPath, limits: LIMITS,
  });
  const authState = validateNativeBuildAuthenticated(auth, {root: root.path, corpusPath: native.corpusPath});
  for (const field of ['binary', 'binarySha256', 'cPath', 'cSha256', 'corpusPath', 'corpusSha256',
    'checkedDefinitions', 'eventsFullyValidated'])
    if (authState[field] !== native[field]) fail('prior native build differs at ' + field);
  const fixedpoint = validateFixedpoint(fixed.report.path, {binarySha256: native.binarySha256});
  if (fixedpoint.stageOne.sha256 !== fixed.stageOne.sha256 || fixedpoint.stageOne.bytes !== fixed.stageOne.bytes
    || fixedpoint.stageTwo.sha256 !== fixed.stageTwo.sha256 || fixedpoint.stageTwo.bytes !== fixed.stageTwo.bytes)
    fail('prior fixedpoint evidence differs from its receipt');
  const emittedReport = validateEmittedSuites(emitted.path, fixedpoint.stageOne);
  if (emittedReport.sha256 !== emitted.sha256) fail('prior emitted suite evidence changed');
  return {
    repository,
    binary: {path: auth.binary, sha256: auth.binarySha256},
    stageOne: fixedpoint.stageOne,
    source: {root: root.path, rootSha256: root.sha256, manifest: root.manifest,
      manifestSha256: root.manifestSha256, corpusPath: native.corpusPath,
      corpusSha256: native.corpusSha256, nativeBuild: native.build.path,
      nativeBuildSha256: native.build.sha256, fixedpointReport: fixed.report.path,
      emittedReport: emitted.path},
    receipt: {path: prior, sha256: receiptSha256},
  };
}

function buildStageDriver({repository, node, stageOne, out}) {
  const driver = resolve(out, 'stage-one-consumer-driver');
  const worker = resolve(repository, 'evals/candidate_consumer_worker.mjs');
  const host = resolve(repository, 'evals/candidate_host.ts');
  for (const path of [worker, host]) if (!existsSync(path)) fail('missing durable consumer component: ' + path);
  const text = '#!/bin/sh\n'
    + 'exec ' + shellQuote(node) + ' --experimental-strip-types ' + shellQuote(worker) + ' '
    + shellQuote(host) + ' --candidate=' + shellQuote(stageOne) + ' --parser=' + shellQuote(stageOne)
    + ' "$@"\n';
  writeFileSync(driver, text, {flag: 'wx'});
  chmodSync(driver, 0o755);
  return {path: driver, sha256: fileSha(driver), node, worker: {path: worker, sha256: fileSha(worker)},
    host: {path: host, sha256: fileSha(host)}, candidate: stageOne, parser: stageOne,
    candidateSha256: fileSha(stageOne), parserSha256: fileSha(stageOne),
    sourceTag: SELFHOST_SOURCE_FILE_TAG};
}

function validateMatrix(target, logs, driver) {
  const pinsPath = resolve(logs, 'matrix.pins.json');
  if (!existsSync(pinsPath)) fail('matrix did not publish pins: ' + target);
  const pins = readJson(pinsPath);
  if (pins.mode !== 'acceptance-matrix') fail('matrix ran in diagnostic mode: ' + target);
  if (pins.target !== target) fail('matrix target changed: ' + target);
  if (!Number.isSafeInteger(pins.fixtures) || pins.fixtures <= 0)
    fail('matrix announced an invalid fixture count on ' + target);
  if (pins.smokeCase !== null && pins.smokeCase !== undefined) fail('matrix used a smoke-case filter');
  if (pins.driver !== driver.path || fileSha(pins.driver) !== driver.sha256)
    fail('matrix driver identity drift');
  if (pins.gate?.memoryMiB !== 8192 || pins.gate?.rssMiB !== 8192 || pins.gate?.pollMs !== 10
    || pins.gate?.timeoutMs !== 600000) fail('matrix guard contract changed');
  if (pins.node !== driver.node) fail('matrix runtime identity changed');
  if (pins.baseSha256 !== fileSha(resolve(pins.cwd, 'bend2/base.bend')))
    fail('matrix base source changed');
  // One per-case pins record is written for every selected fixture. Counting
  // them ties the announced selection to actual per-case evidence without
  // freezing today's inventory.
  const cases = readdirSync(logs).filter(name => name.endsWith('.pins.json') && name !== 'matrix.pins.json');
  if (cases.length !== pins.fixtures)
    fail('matrix announced ' + pins.fixtures + ' cases but wrote ' + cases.length + ' case records on ' + target);
  const names = [];
  for (const name of cases) {
    const row = readJson(resolve(logs, name));
    if (row.target !== target || typeof row.fixture !== 'string' || typeof row.expected !== 'string')
      fail('matrix case evidence is malformed: ' + name);
    names.push(row.fixture);
  }
  return {target, fixtures: pins.fixtures, cases: names.sort(), logs, pinsPath, pinsSha256: fileSha(pinsPath),
    driver: pins.driver, driverSha256: driver.sha256, node: pins.node};
}

// ---------------------------------------------------------------------------
// Consumer suites (child mode; the outer runner owns the guardian)
// ---------------------------------------------------------------------------

function suiteOptions(argv) {
  const {values} = parseOptions(argv, ['--suite', '--repository', '--node', '--bun', '--clang', '--out',
    '--binary', '--driver', '--execution-cwd']);
  return {
    suite: required(values, '--suite'),
    repository: realpathSync(required(values, '--repository')),
    node: realpathSync(required(values, '--node')),
    bun: realpathSync(values.get('--bun') ?? process.execPath),
    clang: values.get('--clang') ?? 'clang',
    out: resolve(required(values, '--out')),
    binary: values.get('--binary') ? realpathSync(values.get('--binary')) : undefined,
    driver: values.get('--driver') ? realpathSync(values.get('--driver')) : undefined,
    executionCwd: values.get('--execution-cwd') ? realpathSync(values.get('--execution-cwd')) : undefined,
  };
}

function suiteBase(options) {
  if (existsSync(options.out)) fail('suite output directory already exists: ' + options.out);
  mkdirSync(options.out, {recursive: true});
  const receipt = {
    schemaVersion: 1, status: 'IN_PROGRESS', passed: false, suite: options.suite,
    repository: options.repository, limits: {...LIMITS}, abi: [...ABI], rows: [],
  };
  function publish() {
    receipt.updated = Date.now();
    const target = resolve(options.out, 'receipt.json'), temporary = target + '.tmp';
    writeFileSync(temporary, JSON.stringify(receipt, null, 2) + '\n');
    renameSync(temporary, target);
  }
  publish();
  return {receipt, publish};
}

function executeSuite(options, command, extra = {}) {
  const started = Date.now();
  const result = spawnSync(command[0], command.slice(1), {
    cwd: extra.cwd ?? options.repository, encoding: 'utf8', timeout: LIMITS.timeoutMs, killSignal: 'SIGKILL',
    maxBuffer: 1 << 24,
    env: {...process.env, BEND_NO_TELEMETRY: '1', ...(extra.env ?? {})},
  });
  return {
    command, status: result.status, signal: result.signal, elapsedMs: Date.now() - started,
    stdout: cap(result.stdout ?? ''), stdoutSha256: hash(result.stdout ?? ''),
    stderr: cap(result.stderr ?? ''), stderrSha256: hash(result.stderr ?? ''),
    error: result.error ? cap(String(result.error)) : undefined,
  };
}

function expectedLines(repository, file) {
  const source = readFileSync(resolve(repository, file), 'utf8');
  return source.split('\n').filter(line => line.startsWith('#|')).map(line => line.slice(2)).join('\n');
}

function emitFixture(options, {file, target, library, names, stem}) {
  if (!existsSync(resolve(options.repository, file))) fail('missing fixture: ' + file);
  const workload = workloadRows(resolve(options.repository, file), target);
  const corpus = corpusFor(workload);
  const manifest = stem + '.tsv', exportsPath = stem + '.exports';
  writeFileSync(manifest, runtimeManifest(corpus), {flag: 'wx'});
  writeFileSync(exportsPath, names.join('\n') + '\n', {flag: 'wx'});
  const output = stem + (target === 'c' ? '.c' : '.js');
  const run = runNativeStage0(options.binary, {
    root: resolve(options.repository, file), base: resolve(options.repository, 'bend2/base.bend'),
    manifest, exports: exportsPath,
    phase: target === 'c' ? (library ? 'compile-c' : 'compile-c-module') : (library ? 'compile' : 'compile-module'),
    output, ...(target === 'c' ? {runtime: resolve(options.repository, 'bend2/selfhost/c_runtime.c')} : {}),
  }, {timeoutMs: LIMITS.timeoutMs});
  requireNativeRun(run, {sources: workload.sources.length,
    phases: ['parse', 'expand', 'check', target === 'c' ? 'emit-c' : 'emit'], output});
  assertNativeChunkEvidence(run, workload.sources.length);
  return {file, target, library, output, manifest, exports: exportsPath, sources: workload.sources.length,
    run: {command: run.command, status: run.status, signal: run.signal, elapsedMs: run.elapsedMs,
      begins: run.begins, phases: run.phases, results: run.results},
    outputSha256: fileSha(output), outputBytes: statSync(output).size};
}

function nativeSuite(options) {
  if (!options.binary) fail('native suite needs --binary');
  const {receipt, publish} = suiteBase(options);
  const rows = receipt.rows;
  try {
    for (const file of NATIVE_SUITE_FILES) {
      const expected = expectedLines(options.repository, file);
      if (!expected.length) fail(file + ' has no #| expectation');
      for (const target of ['c', 'js']) {
        const stem = resolve(options.out, basename(file, '.bend') + '-' + target);
        const row = {label: basename(file) + ':' + target, file, target,
          sourceSha256: fileSha(resolve(options.repository, file)), expected};
        rows.push(row); publish();
        const emitted = emitFixture(options, {file, target, library: false, names: ['main'], stem});
        Object.assign(row, emitted);
        let command;
        if (target === 'c') {
          const exe = stem;
          row.clang = executeSuite(options, [options.clang, '-std=c11', '-O0', '-pthread', emitted.output, '-lm', '-o', exe]);
          if (row.clang.status !== 0) fail(file + ' C compile failed: ' + row.clang.stderr);
          command = [exe];
        } else {
          command = [options.node, '--max-old-space-size=3072', emitted.output];
        }
        row.execute = executeSuite(options, command);
        row.passed = row.execute.status === 0 && row.execute.signal === null && row.execute.stdout.trimEnd() === expected;
        publish();
        if (!row.passed) fail(file + ' ' + target + ' output differs: ' + JSON.stringify(row.execute.stdout));
      }
    }
    const library = emitFixture(options, {
      file: 'evals/c_step_library_fixture.bend', target: 'c', library: true,
      names: ['add', 'symbol_add', 'partial', 'zero', 'factory', 'mk'],
      stem: resolve(options.out, 'library-six-exports'),
    });
    const caller = resolve(options.repository, 'evals/c_backend_library_caller.c');
    const row = {label: 'library:six-exports', file: library.file, target: 'c', library: true,
      sourceSha256: fileSha(resolve(options.repository, library.file)),
      caller: {path: caller, sha256: fileSha(caller)}, ...library};
    rows.push(row); publish();
    row.clang = executeSuite(options, [options.clang, '-std=c11', '-O0', '-pthread', library.output, caller, '-lm', '-o', resolve(options.out, 'library-six-exports')]);
    if (row.clang.status !== 0) fail('six-export library compile failed: ' + row.clang.stderr);
    row.execute = executeSuite(options, [resolve(options.out, 'library-six-exports')]);
    row.expected = 'export ok';
    row.passed = row.execute.status === 0 && row.execute.stdout.trim() === 'export ok';
    publish();
    if (!row.passed) fail('six-export library output differs: ' + row.execute.stdout);

    const nativeCaller = resolve(options.repository, 'evals/c_backend_native_export_caller.c');
    for (const target of ['c', 'js']) {
      const stem = resolve(options.out, 'native-export-u32-mul-' + target);
      const emitted = emitFixture(options, {file: 'evals/c_step_library_fixture.bend', target,
        library: true, names: ['U32.mul'], stem});
      const exportRow = {label: 'native-export:U32.mul:' + target, file: emitted.file, target,
        library: true, sourceSha256: fileSha(resolve(options.repository, emitted.file)),
        caller: {path: nativeCaller, sha256: fileSha(nativeCaller)}, ...emitted};
      rows.push(exportRow); publish();
      let command;
      if (target === 'c') {
        const exe = stem + '.exe';
        exportRow.clang = executeSuite(options, [options.clang, '-std=c11', '-O0', '-pthread', emitted.output, nativeCaller, '-lm', '-o', exe]);
        if (exportRow.clang.status !== 0) fail('native export C compile failed: ' + exportRow.clang.stderr);
        command = [exe];
      } else {
        command = [options.node, '--input-type=module', '-e',
          'const lib=(await import(' + JSON.stringify('file://' + emitted.output) + ')).default;'
          + 'const value=lib["U32.mul"](2,3);if(value!==6)throw Error("Native product differs");console.log(value);'];
      }
      exportRow.execute = executeSuite(options, command);
      exportRow.expected = '6';
      exportRow.passed = exportRow.execute.status === 0 && exportRow.execute.stdout.trim() === '6';
      publish();
      if (!exportRow.passed) fail('native export differs: ' + target + ': ' + exportRow.execute.stdout);
    }
    if (rows.length !== NATIVE_SUITE_FILES.length * 2 + 1 + 2)
      fail('native/library suite must publish every declared row, got ' + rows.length);
    receipt.status = 'NATIVE_FOREIGN_AND_LIBRARY_SMOKE_PASS';
    receipt.passed = true;
    receipt.counts = {fixtures: 30, library: 1, nativeExports: 2, total: rows.length};
    publish();
  } catch (error) {
    receipt.status = 'FAIL';
    receipt.error = cap(error?.stack ?? error);
    publish();
    process.exitCode = 1;
  }
}

function admissionSuite(options) {
  if (!options.binary) fail('admission suite needs --binary');
  const {receipt, publish} = suiteBase(options);
  const rows = receipt.rows;
  try {
    for (const [name, source] of Object.entries(ADMISSION_INPUTS)) {
      const file = resolve(options.out, name + '.bend');
      writeFileSync(file, source, {flag: 'wx'});
      for (const target of ['js', 'c']) {
        for (const library of name === 'mainless' ? [false, true] : [false]) {
          const stem = resolve(options.out, name + '-' + target + (library ? '-library' : ''));
          const workload = workloadRows(file, target), corpus = corpusFor(workload);
          const manifest = stem + '.tsv', exportsPath = stem + '.exports';
          writeFileSync(manifest, runtimeManifest(corpus), {flag: 'wx'});
          writeFileSync(exportsPath, (library ? 'twice' : 'main') + '\n', {flag: 'wx'});
          const output = stem + (target === 'c' ? '.c' : '.js');
          const run = runNativeStage0(options.binary, {
            root: file, base: resolve(options.repository, 'bend2/base.bend'),
            manifest, exports: exportsPath,
            phase: target === 'c' ? (library ? 'compile-c' : 'compile-c-module') : (library ? 'compile' : 'compile-module'),
            output, ...(target === 'c' ? {runtime: resolve(options.repository, 'bend2/selfhost/c_runtime.c')} : {}),
          }, {timeoutMs: LIMITS.timeoutMs});
          const rejected = name === 'template' || name === 'untypedNoLaw' || (name === 'mainless' && !library);
          const row = {name, target, library, sourceSha256: fileSha(file), expectedRejection: rejected,
            run: {command: run.command, status: run.status, signal: run.signal, elapsedMs: run.elapsedMs,
              begins: run.begins, phases: run.phases, phaseStarts: run.phaseStarts, results: run.results},
            outputExists: existsSync(output)};
          rows.push(row); publish();
          let failure;
          try {
            requireNativeRun(run, {phases: ['parse', 'expand', 'check', target === 'c' ? 'emit-c' : 'emit'],
              sources: workload.sources.length, output});
          } catch (error) {
            failure = error;
          }
          if (rejected) {
            const expectedPhase = name === 'template' ? 'check'
              : name === 'untypedNoLaw' ? 'parse' : target === 'c' ? 'emit-c' : 'emit';
            row.observedFailure = failure?.failurePhase;
            row.passed = row.observedFailure === expectedPhase && run.signal === null && run.status === 1
              && !row.outputExists;
            if (!row.passed) fail('admission boundary differs: ' + name + ' ' + target + ' library=' + library
              + ' expected ' + expectedPhase + ' got ' + JSON.stringify({failure: failure && String(failure), status: run.status, signal: run.signal, output: row.outputExists}));
          } else {
            if (failure) throw failure;
            assertNativeChunkEvidence(run, workload.sources.length);
            row.outputSha256 = fileSha(output);
            let command;
            if (target === 'c') {
              const caller = resolve(options.out, name + '-' + target + (library ? '-library' : '') + '-caller.c');
              writeFileSync(caller, library
                ? '#include <stdint.h>\n#include <assert.h>\n#include <stdio.h>\nextern void bend_library_init(void);\nextern uint32_t bend_export_count(void);\nextern uint64_t bend_export_call(uint32_t,uint64_t*,uint32_t);\nint main(void){bend_library_init();assert(bend_export_count()==1);uint64_t a[]={21};uint64_t r=bend_export_call(0,a,1);assert(r==42);puts("42");return 0;}\n'
                : '', {flag: 'wx'});
              const exe = stem;
              row.clang = executeSuite(options, [options.clang, '-std=c11', '-O0', '-pthread', output,
                ...(library ? [caller] : []), '-lm', '-o', exe]);
              if (row.clang.status !== 0) fail('admission C compile failed: ' + name + ' ' + target);
              command = [exe];
            } else if (library) {
              command = [options.node, '--input-type=module', '-e',
                'const lib=(await import(' + JSON.stringify('file://' + output) + ')).default;console.log(lib.twice(21));'];
            } else {
              command = [options.node, output];
            }
            row.execute = executeSuite(options, command);
            row.expected = library ? '42' : 'Unit{}';
            row.passed = row.execute.status === 0 && row.execute.stdout.trim() === row.expected;
            if (!row.passed) fail('admission output differs: ' + name + ' ' + target + ': ' + row.execute.stdout);
          }
          publish();
        }
      }
    }
    const expected = Object.keys(ADMISSION_INPUTS).reduce(
      (total, name) => total + 2 + (name === 'mainless' ? 2 : 0), 0);
    if (rows.length !== expected)
      fail('admission suite must publish every declared row, got ' + rows.length);
    receipt.status = 'NATIVE_DATATYPE_AND_EXECUTABLE_ADMISSION_PASS';
    receipt.passed = true;
    receipt.counts = {inputs: 5, rows: rows.length};
    publish();
  } catch (error) {
    receipt.status = 'FAIL';
    receipt.error = cap(error?.stack ?? error);
    publish();
    process.exitCode = 1;
  }
}

function hostSuite(options) {
  if (!options.driver) fail('host suite needs --driver');
  const {receipt, publish} = suiteBase(options);
  const rows = receipt.rows;
  const env = {BEND_INNER_LIBRARY_COMPILER: JSON.stringify([options.driver])};
  try {
    for (const file of HOST_CONSUMER_FILES) {
      const name = basename(file, '.bend');
      const expected = expectedLines(options.repository, file);
      if (!expected.trim()) fail(file + ' has no #| expectation');
      const output = resolve(options.out, name + '.js');
      const row = {file, sourceSha256: fileSha(resolve(options.repository, file)), expected,
        driver: {path: options.driver, sha256: fileSha(options.driver)}};
      rows.push(row); publish();
      row.compile = executeSuite(options, [options.driver, resolve(options.repository, file), '-o', output], {env});
      if (row.compile.status !== 0) fail(file + ' host-consumer compile failed: ' + row.compile.stderr);
      row.outputSha256 = fileSha(output);
      row.execute = executeSuite(options, [options.node, output], {env, cwd: options.executionCwd});
      row.passed = row.execute.status === 0 && row.execute.signal === null && row.execute.stdout.trimEnd() === expected;
      publish();
      if (!row.passed) fail(file + ' host consumer output differs: ' + JSON.stringify(row.execute.stdout));
    }
    if (rows.length !== HOST_CONSUMER_FILES.length)
      fail('host-consumer suite must publish every declared row, got ' + rows.length);
    receipt.status = 'ACTUAL_ALIAS_AND_HOST_EXPORT_CONSUMERS_PASS';
    receipt.passed = true;
    receipt.counts = {consumers: rows.length};
    publish();
  } catch (error) {
    receipt.status = 'FAIL';
    receipt.error = cap(error?.stack ?? error);
    publish();
    process.exitCode = 1;
  }
}

// ---------------------------------------------------------------------------
// Throughput
// ---------------------------------------------------------------------------

function buildThroughputRequest({repository, frozen, node, bun, binary, image, expected, producer}) {
  const closure = withCwd(frozen.frozenRepository, () => workloadRows(frozen.frozenRoot, 'js'));
  const inputs = Object.fromEntries([...closure.sources, ...closure.externals]
    .map(row => [row.file, row.sha256]).sort());
  if (JSON.stringify(inputs) !== JSON.stringify(frozen.inputs))
    fail('throughput workload closure differs from the authenticated frozen inputs');
  const pins = {...inputs};
  for (const path of [resolve(repository, 'evals/selfhost_throughput.mjs'),
    resolve(repository, 'evals/heavy_gate.ts'), resolve(repository, 'evals/heavy_gate_native.c'),
    resolve(repository, 'evals/native_seed_runtime.mjs'),
    resolve(repository, 'evals/checker_core_step_runtime.mjs'),
    node, bun, binary, image]) {
    if (!existsSync(path)) fail('unreachable throughput pin: ' + path);
    const real = realpathSync(path);
    pins[real] = fileSha(real);
  }
  return {
    schemaVersion: 1,
    repository: frozen.frozenRepository,
    root: frozen.frozenRoot,
    exports: [...ABI],
    node: realpathSync(node),
    binary: realpathSync(binary),
    image: realpathSync(image),
    ...(expected === undefined ? {} : {expectedSelfhostOutput: expected}),
    limits: {...LIMITS},
    host: hostInfo(),
    inputs,
    pins,
    producer,
  };
}

function throughputRun(run, label, {repository, bun, script, frozenRepo, mode, requestPath, reportPath}) {
  const row = run.runPlain(label, [bun, script, mode, requestPath, reportPath], {
    cwd: frozenRepo, timeoutMs: LIMITS.timeoutMs + 120000,
  });
  const report = readJson(reportPath);
  if (report.status !== 'PASS') fail(label + ' report status ' + report.status + ': ' + (report.error ?? ''));
  if (report.mode !== mode) fail(label + ' mode drift');
  if (report.requestSha256 !== fileSha(requestPath)) fail(label + ' request identity drift');
  if (report.checksExcluded !== 0 || report.outputPatches !== 0)
    fail(label + ' excluded checks or patched output');
  if (JSON.stringify(report.workerPolicy) !== JSON.stringify({stackMiB: 256, oldGenerationMiB: 6144, youngGenerationMiB: 128}))
    fail(label + ' worker policy changed');
  if (report.profiled || report.compilerProfile || report.allocationProfile)
    fail(label + ' returned a profiled timing');
  if (report.limits?.memoryMiB !== 8192 || report.limits?.rssMiB !== 8192 || report.limits?.timeoutMs !== 600000)
    fail(label + ' limits changed');
  if (mode === 'native') {
    const parse = report.phases.find(phase => phase.phase === 'parse');
    if (!parse || parse.eagerFuelCells !== report.moduleCount * 8000000)
      fail(label + ' native eager fuel is not 8000000 per source');
    for (const phase of report.phases)
      if (phase.phase !== 'parse' && phase.chunkQuantum !== 64)
        fail(label + ' native chunk quantum changed');
  }
  assertGuardian(report.guardian, label);
  if (!report.output || typeof report.output.sha256 !== 'string' || !Number.isSafeInteger(report.output.bytes))
    fail(label + ' lacks an authenticated output');
  if (fileSha(report.output.path) !== report.output.sha256) fail(label + ' output bytes changed');
  row.report = {path: realpathSync(reportPath), sha256: fileSha(reportPath)};
  row.mode = mode;
  row.pipelineElapsedMs = report.pipelineElapsedMs;
  row.phases = report.phases.map(phase => ({phase: phase.phase, elapsedMs: phase.elapsedMs}));
  row.output = {path: report.output.path, sha256: report.output.sha256, bytes: report.output.bytes};
  row.peakRssBytes = report.guardian.peakRssBytes;
  row.peakFootprintBytes = report.guardian.peakFootprintBytes;
  row.guardian = {status: report.guardian.status, reason: report.guardian.reason,
    peakRssBytes: report.guardian.peakRssBytes, peakFootprintBytes: report.guardian.peakFootprintBytes,
    elapsedMs: report.guardian.elapsedMs, timeoutMs: report.guardian.timeoutMs,
    memoryLimitBytes: report.guardian.memoryLimitBytes, rssLimitBytes: report.guardian.rssLimitBytes,
    commandExitCode: report.guardian.commandExitCode, ownedTreeStopped: report.guardian.ownedTreeStopped,
    reportPhase: report.guardian.reportPhase};
  run.publish();
  return {report, row};
}

function throughputSummaries(runs) {
  const grouped = {control: [], candidate: []};
  for (const run of runs) grouped[run.role].push(run.row);
  const summary = {};
  for (const role of ['control', 'candidate']) {
    const rows = grouped[role];
    if (rows.length !== 3) fail('throughput needs three ' + role + ' runs, got ' + rows.length);
    const result = {runs: rows.length,
      pipelineMs: stats(rows.map(row => row.pipelineElapsedMs)),
      peakRssBytes: stats(rows.map(row => row.peakRssBytes)),
      peakFootprintBytes: stats(rows.map(row => row.peakFootprintBytes)),
      phases: {}};
    const names = [...new Set(rows.flatMap(row => row.phases.map(phase => phase.phase)))];
    for (const name of names)
      result.phases[name] = stats(rows.map(row => row.phases.find(phase => phase.phase === name)?.elapsedMs)
        .filter(value => typeof value === 'number'));
    summary[role] = result;
  }
  summary.ratio = {
    pipelineMs: summary.candidate.pipelineMs.median / summary.control.pipelineMs.median,
    peakRssBytes: summary.candidate.peakRssBytes.median / summary.control.peakRssBytes.median,
    peakFootprintBytes: summary.candidate.peakFootprintBytes.median / summary.control.peakFootprintBytes.median,
  };
  return summary;
}

const PERFORMANCE_POLICY = Object.freeze({
  id: 'g29-paired-full-root-strict-v1',
  repetitions: Object.freeze({control: 3, candidate: 3}),
  modes: Object.freeze(['native', 'js']),
  rules: Object.freeze({
    pipelineMs: 'candidate arithmetic mean AND median strictly less than control',
    peakRssBytes: 'candidate median less than or equal to control',
    peakFootprintBytes: 'candidate median less than or equal to control',
  }),
  rows: 'all 12 authenticated measurements are required; original rows are never excluded',
  scope: 'rejection evidence only; never compiler or performance acceptance',
});

function mean(values) {
  return values.reduce((total, value) => total + value, 0) / values.length;
}
function validMetric(value) {
  return Number.isFinite(value) && value >= 0;
}

/**
 * Pure decision over an authenticated throughput receipt. Never mutates input
 * and never throws for absent or malformed measurements; it reports failures
 * so the caller can publish the decision before rejecting.
 */
export function performanceDecision(throughput, policy = PERFORMANCE_POLICY) {
  const rows = Array.isArray(throughput?.runs) ? throughput.runs : [];
  const failures = [];
  const expectedRows = policy.modes.length * (policy.repetitions.control + policy.repetitions.candidate);
  if (!Array.isArray(throughput?.runs))
    failures.push('throughput runs are missing');
  else if (rows.length !== expectedRows)
    failures.push('expected ' + expectedRows + ' authenticated rows, got ' + rows.length);
  const metrics = ['pipelineElapsedMs', 'peakRssBytes', 'peakFootprintBytes'];
  for (const [index, row] of rows.entries()) {
    if (!['control', 'candidate'].includes(row?.role))
      failures.push('row ' + index + ' has an unknown role');
    if (!policy.modes.includes(row?.mode))
      failures.push('row ' + index + ' has an unknown mode');
    if (!Number.isSafeInteger(row?.repetition) || row.repetition < 1
      || row.repetition > policy.repetitions[row.role])
      failures.push('row ' + index + ' has an invalid repetition');
    for (const metric of metrics)
      if (!validMetric(row?.[metric]))
        failures.push('row ' + index + ' ' + metric + ' is not finite and nonnegative');
  }

  const modes = {};
  for (const mode of policy.modes) {
    const control = rows.filter(row => row?.mode === mode && row?.role === 'control');
    const candidate = rows.filter(row => row?.mode === mode && row?.role === 'candidate');
    const counts = {control: control.length, candidate: candidate.length};
    let countsOk = control.length === policy.repetitions.control
      && candidate.length === policy.repetitions.candidate;
    for (const [role, group] of [['control', control], ['candidate', candidate]]) {
      const repetitions = group.map(row => row?.repetition);
      if (new Set(repetitions).size !== repetitions.length) {
        countsOk = false;
        failures.push(mode + ' ' + role + ' repetitions are not unique');
      }
    }
    if (!countsOk)
      failures.push(mode + ' requires exactly ' + policy.repetitions.control + ' control and '
        + policy.repetitions.candidate + ' candidate rows, got ' + counts.control + ' and ' + counts.candidate);

    const rowsValid = [...control, ...candidate].every(row => metrics.every(metric => validMetric(row?.[metric])));
    let measurements = null, checks = null;
    if (countsOk && rowsValid) {
      const aggregate = group => Object.fromEntries(metrics.map(metric => {
        const values = group.map(row => row[metric]);
        return [metric, {n: values.length, mean: mean(values), median: median(values)}];
      }));
      const left = aggregate(control), right = aggregate(candidate);
      measurements = {
        pipelineMs: {control: left.pipelineElapsedMs, candidate: right.pipelineElapsedMs,
          delta: {mean: left.pipelineElapsedMs.mean - right.pipelineElapsedMs.mean,
            median: left.pipelineElapsedMs.median - right.pipelineElapsedMs.median}},
        peakRssBytes: {control: left.peakRssBytes, candidate: right.peakRssBytes,
          delta: {median: left.peakRssBytes.median - right.peakRssBytes.median}},
        peakFootprintBytes: {control: left.peakFootprintBytes, candidate: right.peakFootprintBytes,
          delta: {median: left.peakFootprintBytes.median - right.peakFootprintBytes.median}},
      };
      checks = {
        pipelineMeanStrictlyImproved: right.pipelineElapsedMs.mean < left.pipelineElapsedMs.mean,
        pipelineMedianStrictlyImproved: right.pipelineElapsedMs.median < left.pipelineElapsedMs.median,
        peakRssMedianNotIncreased: right.peakRssBytes.median <= left.peakRssBytes.median,
        peakFootprintMedianNotIncreased: right.peakFootprintBytes.median <= left.peakFootprintBytes.median,
      };
      for (const [check, passed] of Object.entries(checks))
        if (!passed) failures.push(mode + ': ' + check + ' is false');
    }
    modes[mode] = {
      counts,
      evaluated: measurements !== null,
      measurements,
      checks,
      passed: measurements !== null && Object.values(checks).every(Boolean),
    };
  }

  const passed = failures.length === 0 && policy.modes.every(mode => modes[mode].passed);
  return {
    policy,
    evaluated: true,
    rows: rows.length,
    expectedRows,
    counts: Object.fromEntries(policy.modes.map(mode => [mode, modes[mode].counts])),
    passed,
    rejected: !passed,
    failures,
    modes,
    note: 'Rejection evidence only. A pass here does not establish compiler or performance acceptance; the parent owns that decision.',
  };
}

function applyPerformanceGate(run) {
  if (run.receipt.failFastPerformance !== true) return null;
  const decision = performanceDecision(run.receipt.throughput);
  run.receipt.performanceDecision = decision;
  // Publish the bounded decision before the rejection propagates so the
  // existing catch path retains it with the already completed evidence.
  run.publish();
  if (!decision.passed)
    fail('fail-fast performance policy rejected the candidate: ' + (decision.failures.join('; ') || 'unknown reason'));
  return decision;
}

// ---------------------------------------------------------------------------
// Correctness phase
// ---------------------------------------------------------------------------

async function runCorrectness(run, context) {
  const {repository, runId, node, bun, clang, llvmBin, out} = context;
  const checkpoints = checkpointsFor(repository);
  const stem = resolve(checkpoints, 'bootstrap-parser-rebuild-' + runId);
  const parserSource = resolve(checkpoints, '.bootstrap_parser_rebuild_' + runId + '_source.bend');
  const parserCandidate = resolve(checkpoints, '.bootstrap_parser_rebuild_' + runId + '_generated_fuel.bend');
  const parserJs = stem + '.js';
  const parserBuild = stem + '.native-build.result.json';
  const sourcePublic = resolve(out, 'parser-public-source.json');
  const sourceGate = resolve(out, 'parser-source-gate.json');
  const nativePublic = resolve(out, 'parser-public-native.json');
  const candidateGate = resolve(out, 'parser-candidate-gate.json');
  const compilerRoot = resolve(checkpoints, '.bootstrap_compiler_root_' + runId + '.bend');
  const rootManifest = resolve(checkpoints, 'selfhost-root-' + runId + '.json');
  const jsImage = resolve(out, 'root.js');
  const jsBuild = resolve(out, 'root-build');
  const nativeCorpus = resolve(out, 'root.native.corpus.json');
  const nativeBuild = resolve(out, 'root-native-build.json');
  const nativeBinary = resolve(out, 'native');
  const bootstrapReport = resolve(out, 'bootstrap.json');
  const emittedReport = resolve(out, 'emitted-suites.json');

  const state = {
    parser: {source: parserSource, candidate: parserCandidate, component: parserJs, build: parserBuild},
    root: {path: compilerRoot, manifest: rootManifest},
    javascript: {artifact: jsImage, build: jsBuild + '.result.json'},
    native: null, fixedpoint: null, matrix: {}, consumers: {}, emitted: null,
    driver: null,
  };

  for (const script of ['evals/checker_core_owned_source.ts', 'evals/template_step_lower.ts',
    'evals/checker_core_step_lower.ts', 'evals/emitter_step_lower.ts'])
    await run.runGuarded(basename(script), [bun, script]);

  run.runPlain('parser-source', [bun, '--smol', 'evals/bootstrap_parser_rebuild.ts', '--prepare-source', '--run-id', runId]);
  run.runPlain('parser-public-source', [bun, '--smol', 'evals/bootstrap_parser_public_gate.ts',
    '--parser=' + parserSource, '--entry=parse_module_tokens', '--report=' + sourcePublic]);
  run.runPlain('parser-source-gate', [bun, '--smol', 'evals/bootstrap_parser_fast.ts',
    '--parser=' + parserSource, '--entry=parse_module_tokens', '--public-report=' + sourcePublic,
    '--report=' + sourceGate]);
  run.runPlain('parser-prepare', [bun, '--smol', 'evals/bootstrap_parser_rebuild.ts',
    '--prepare', '--run-id', runId, '--source-gate', sourceGate]);
  run.runPlain('parser-build', [bun, '--smol', 'evals/bootstrap_parser_rebuild.ts', '--build-native', '--run-id', runId]);
  if (!existsSync(parserJs) || !existsSync(parserBuild)) fail('parser rebuild did not publish its native component');
  run.runPlain('parser-public-native', [bun, '--smol', 'evals/bootstrap_parser_public_gate.ts',
    '--parser=' + parserCandidate, '--entry=parse_with_fuel', '--report=' + nativePublic]);
  run.runPlain('parser-native-gate', [bun, '--smol', 'evals/bootstrap_parser_fast.ts',
    '--parser=' + parserCandidate, '--entry=parse_with_fuel', '--component=' + parserJs,
    '--component-build=' + parserBuild, '--public-report=' + nativePublic, '--report=' + candidateGate]);
  run.runPlain('parser-accept', [bun, '--smol', 'evals/bootstrap_parser_rebuild.ts',
    '--build', '--run-id', runId, '--candidate-gate', candidateGate]);
  state.parser.sourceSha256 = fileSha(parserSource);
  state.parser.candidateSha256 = fileSha(parserCandidate);
  state.parser.componentSha256 = fileSha(parserJs);
  state.parser.buildSha256 = fileSha(parserBuild);
  run.publish();

  await run.runGuarded('compose', [bun, 'evals/selfhost_driver_source.ts',
    '--parser-build=' + parserBuild, '--root=' + compilerRoot, '--manifest=' + rootManifest]);
  state.root.sha256 = fileSha(compilerRoot);
  state.root.manifestSha256 = fileSha(rootManifest);
  run.publish();

  run.runPlain('js-build', [bun, '--smol', 'evals/checker_core_component_build.ts',
    '--file=' + compilerRoot, '--exports=' + ABI.join(','), '--artifact=' + jsImage, '--report=' + jsBuild]);
  state.javascript = validateJavascriptBuild(jsBuild + '.result.json', {artifact: jsImage, source: compilerRoot});

  const workload = withCwd(repository, () => workloadRows(compilerRoot, 'js'));
  const corpus = corpusFile(workload, nativeCorpus);
  state.native = {corpus: {path: nativeCorpus, sha256: fileSha(nativeCorpus), entries: corpus.files.length,
    sources: workload.sources.length, externals: workload.externals.length}};
  run.publish();

  run.runPlain('native-build', [bun, '--smol', 'evals/native_compiler_experiment.ts', '--mode=build',
    '--corpus=' + nativeCorpus, '--artifact=' + nativeBinary, '--report=' + nativeBuild,
    '--cc-pipeline=llvm-split', '--llvm-bin=' + llvmBin, '--cc-partitions=' + context.ccPartitions]);
  const authenticated = authenticateNativeSeedBuild(nativeBuild, {root: compilerRoot, corpusPath: nativeCorpus, limits: LIMITS});
  Object.assign(state.native, validateNativeBuildAuthenticated(authenticated, {root: compilerRoot, corpusPath: nativeCorpus}));
  state.native.build = {path: nativeBuild, sha256: fileSha(nativeBuild)};
  run.publish();

  run.runPlain('bootstrap', [bun, '--smol', 'evals/selfhost_bootstrap_gate.ts',
    '--native-build=' + nativeBuild, '--native-corpus=' + nativeCorpus,
    '--root=' + compilerRoot, '--root-manifest=' + rootManifest,
    '--parser=' + parserJs, '--parser-build=' + parserBuild, '--report=' + bootstrapReport]);
  const fixedpoint = validateFixedpoint(bootstrapReport, {binarySha256: state.native.binarySha256});
  state.fixedpoint = {report: {path: bootstrapReport, sha256: fileSha(bootstrapReport)},
    status: fixedpoint.proof.status, equal: fixedpoint.proof.fixedpoint.equal,
    stageOne: fixedpoint.stageOne, stageTwo: fixedpoint.stageTwo,
    seedMode: fixedpoint.proof.seedMode, compilerBootstrapGreen: fixedpoint.proof.compilerBootstrapGreen,
    nativePhases: fixedpoint.proof.nativeRun.phases, boundary: fixedpoint.proof.boundary,
    nativeRun: {binarySha256: fixedpoint.proof.nativeRun.binarySha256,
      build: fixedpoint.proof.nativeRun.build, buildSha256: fixedpoint.proof.nativeRun.buildSha256,
      corpusSha256: fixedpoint.proof.nativeRun.corpusSha256, sources: fixedpoint.proof.nativeRun.sources}};
  run.publish();
  context.evidence = state;
  if (context.phase === 'all') {
    context.candidate = {repository,
      binary: {path: state.native.binary, sha256: state.native.binarySha256},
      stageOne: fixedpoint.stageOne};
    run.receipt.correctness = state;
    run.receipt.throughput = await runThroughput(run, context);
    run.receipt.throughputMeasured = true;
    run.publish();
    applyPerformanceGate(run);
  }


  run.runPlain('emitted-suites', [bun, '--smol', 'evals/selfhost_emitted_suites.ts',
    '--fixedpoint-report=' + bootstrapReport, '--stage-sha256=' + fixedpoint.stageOne.sha256,
    '--stage-bytes=' + fixedpoint.stageOne.bytes, '--report=' + emittedReport],
    {timeoutMs: LIMITS.timeoutMs * 2});
  state.emitted = validateEmittedSuites(emittedReport, fixedpoint.stageOne);
  run.publish();

  const carrier = sourceFileTagFromRoot(readFileSync(compilerRoot, 'utf8'), 'selfhost');
  if (carrier !== SELFHOST_SOURCE_FILE_TAG) fail('compiler root carrier changed: ' + carrier);
  if (verifySourceFileCarrier(readFileSync(fixedpoint.stageOne.path, 'utf8'), carrier) !== carrier)
    fail('stage-one image does not register the canonical carrier');
  state.driver = buildStageDriver({repository, node, stageOne: fixedpoint.stageOne.path, out});
  run.publish();

  const expectedNativeRows = NATIVE_SUITE_FILES.length * 2 + 1 + 2;
  const expectedAdmissionRows = Object.keys(ADMISSION_INPUTS).reduce(
    (total, name) => total + 2 + (name === 'mainless' ? 2 : 0), 0);
  const expectedHostRows = HOST_CONSUMER_FILES.length;
  if (context.distributed) {
    await distributedConsumers(run, context, state, distributedConsumerFiles());
  } else {

  for (const target of ['c', 'js']) {
    const logs = resolve(out, 'matrix-' + target);
    run.runPlain('matrix-' + target, [bun, 'evals/c_target_fixtures_run.ts', '--driver=' + state.driver.path,
      '--node=' + node, '--target=' + target, '--logs=' + logs, '--keep'],
      {timeoutMs: MATRIX_TIMEOUT_MS});
    state.matrix[target] = validateMatrix(target, logs, state.driver);
    run.publish();
  }

  await run.runGuarded('native-consumers', [bun, SCRIPT, '--suite=native', '--repository=' + repository,
    '--node=' + node, '--bun=' + bun, '--clang=' + clang, '--out=' + resolve(out, 'native-consumers'),
    '--binary=' + state.native.binary]);
  await run.runGuarded('native-admission-boundaries', [bun, SCRIPT, '--suite=admission', '--repository=' + repository,
    '--node=' + node, '--bun=' + bun, '--clang=' + clang, '--out=' + resolve(out, 'native-admission'),
    '--binary=' + state.native.binary]);
  await run.runGuarded('nested-host-consumers', [bun, SCRIPT, '--suite=host', '--repository=' + repository,
    '--node=' + node, '--bun=' + bun, '--clang=' + clang, '--out=' + resolve(out, 'host-consumers'),
    '--driver=' + state.driver.path]);
  for (const [key, directory, status, count] of [
    ['native', 'native-consumers', 'NATIVE_FOREIGN_AND_LIBRARY_SMOKE_PASS', expectedNativeRows],
    ['admission', 'native-admission', 'NATIVE_DATATYPE_AND_EXECUTABLE_ADMISSION_PASS', expectedAdmissionRows],
    ['host', 'host-consumers', 'ACTUAL_ALIAS_AND_HOST_EXPORT_CONSUMERS_PASS', expectedHostRows],
  ]) {
    const path = resolve(out, directory, 'receipt.json');
    const report = readJson(path);
    if (report.status !== status || report.passed !== true || report.rows.length !== count)
      fail(directory + ' suite did not publish ' + count + ' passing rows: ' + report.status);
    state.consumers[key] = {receipt: {path, sha256: fileSha(path)}, status, rows: count,
      counts: report.counts};
  }
  }
  state.consumers.total = expectedNativeRows + expectedAdmissionRows + expectedHostRows;
  state.consumers.rows = {nativeLibrary: expectedNativeRows, admission: expectedAdmissionRows, host: expectedHostRows};
  state.consumers.note = 'matrices ran every accepted case (' + state.matrix.c.fixtures + ' C, '
    + state.matrix.js.fixtures + ' JS); original 95 fixtures executed on both unchanged images by the fixedpoint and emitted-image gates';
  run.publish();

  if (!state.fixedpoint.equal || state.fixedpoint.stageOne.sha256 !== state.fixedpoint.stageTwo.sha256)
    fail('fixedpoint was lost before consumer evidence');
  if (fileSha(compilerRoot) !== state.root.sha256) fail('compiler root changed during qualification');
  if (fileSha(fixedpoint.stageOne.path) !== state.fixedpoint.stageOne.sha256)
    fail('stage-one artifact changed during qualification');

  state.authentication = {
    g23ByteEquality: 'not required: the G24 JS emitter may intentionally change emitted bytes',
    candidateNativeAndJsBytes: 'authenticated in the throughput phase by cross-lane equality against the native lane',
    freshFixedpoint: 'exact stage-one/stage-two byte equality',
    matrixExpectations: 'each fixture #| output on C and JS',
    originalFixtures: '95 seed fixtures, 95 stage-one and 95 stage-two executions in the emitted-image gate',
    stageImageConsumers: 'the stage-one image is both candidate and parser for the C/JS matrices and host consumers; the canonical selfhost carrier is verified and the seed parser is never used on a stage image',
    excludedCases: 0,
    checksExcluded: 0,
    outputPatches: 0,
  };
  return state;
}

// ---------------------------------------------------------------------------
// Throughput phase
// ---------------------------------------------------------------------------

async function runThroughput(run, context) {
  const {repository, node, bun, out, bindings, candidate} = context;
  if (!bindings) fail('throughput phase requires --bindings');
  if (!candidate) fail('throughput phase requires a prior correctness receipt via --from-receipt');
  const measurementMode = context.measurementMode;
  const stageOne = candidate.stageOne;
  if (!existsSync(stageOne.path)) fail('unreachable candidate stage-one image: ' + stageOne.path);
  if (fileSha(stageOne.path) !== stageOne.sha256 || statSync(stageOne.path).size !== stageOne.bytes)
    fail('candidate stage-one image does not match the fixedpoint evidence');
  if (!existsSync(candidate.binary.path)) fail('unreachable candidate native binary: ' + candidate.binary.path);
  if (fileSha(candidate.binary.path) !== candidate.binary.sha256)
    fail('candidate native binary does not match the build evidence');

  const directory = resolve(out, 'throughput');
  mkdirSync(directory, {recursive: true});
  const script = resolve(repository, 'evals/selfhost_throughput.mjs');
  const producer = {
    runId: context.runId, repository: candidate.repository,
    binary: candidate.binary.path, binarySha256: candidate.binary.sha256,
    image: stageOne.path, imageSha256: stageOne.sha256, imageBytes: stageOne.bytes,
    bindings: bindings.path, bindingsSha256: bindings.sha256,
    controlNative: bindings.controlNative, controlNativeSha256: bindings.controlNativeSha256,
    controlImage: bindings.controlImage, controlImageSha256: bindings.controlImageSha256,
    baselineAcceptance: bindings.bindings.baselineAcceptance, waveBase: bindings.bindings.waveBase,
    profiledTimingsExcluded: true,
  };
  const controlNativeRequest = resolve(directory, 'control-native.request.json');
  const controlJsRequest = resolve(directory, 'control-js.request.json');
  const candidateNativeRequest = resolve(directory, 'candidate-native.request.json');
  const candidateJsRequest = resolve(directory, 'candidate-js.request.json');
  writeJsonFresh(controlNativeRequest, buildThroughputRequest({
    repository, frozen: bindings, node, bun, binary: bindings.controlNative,
    image: bindings.controlImage, expected: bindings.expectedBaselineOutput,
    producer: {...producer, lane: 'control-native'}}));
  writeJsonFresh(controlJsRequest, buildThroughputRequest({
    repository, frozen: bindings, node, bun, binary: bindings.controlNative,
    image: bindings.controlImage, expected: bindings.expectedBaselineOutput,
    producer: {...producer, lane: 'control-js'}}));
  writeJsonFresh(candidateNativeRequest, buildThroughputRequest({
    repository, frozen: bindings, node, bun, binary: candidate.binary.path,
    image: stageOne.path, expected: undefined,
    producer: {...producer, lane: 'candidate-native'}}));

  const order = [['control', 1], ['candidate', 1], ['candidate', 2], ['control', 2], ['control', 3], ['candidate', 3]];
  const distributed = context.distributed ? await distributedMeasurements(context) : null;
  const runs = distributed?.runs ?? [];
  let candidateExpected = distributed?.candidateExpected ?? context.candidateExpected;
  for (const mode of distributed ? [] : (measurementMode ? [measurementMode] : ['native', 'js'])) {
    if (mode === 'js') {
      if (candidateExpected === undefined) fail('candidate native lane produced no authenticated output');
      writeJsonFresh(candidateJsRequest, buildThroughputRequest({
        repository, frozen: bindings, node, bun, binary: candidate.binary.path,
        image: stageOne.path, expected: candidateExpected,
        producer: {...producer, lane: 'candidate-js'}}));
    }
    for (const [role, repetition] of order) {
      const requestPath = role === 'control'
        ? (mode === 'native' ? controlNativeRequest : controlJsRequest)
        : (mode === 'native' ? candidateNativeRequest : candidateJsRequest);
      const reportPath = resolve(directory, mode + '-' + role + '-' + repetition + '.json');
      const {report, row} = throughputRun(run, 'throughput-' + mode + '-' + role + '-' + repetition, {
        repository, bun, script, frozenRepo: bindings.frozenRepository, mode, requestPath, reportPath,
      });
      row.role = role;
      row.repetition = repetition;
      if (role === 'control') {
        if (report.output.sha256 !== bindings.expectedBaselineOutput)
          fail('control output differs from the accepted baseline');
      } else if (mode === 'native') {
        candidateExpected ??= report.output.sha256;
        if (report.output.sha256 !== candidateExpected) fail('candidate native repetitions emit different bytes');
      } else if (report.output.sha256 !== candidateExpected) {
        fail('candidate JS output differs from the candidate native output');
      }
      runs.push({role, repetition, mode, report, row});
      run.publish();
    }
  }
  if (measurementMode) return {runs, candidateExpected};
  const summary = {native: throughputSummaries(runs.filter(entry => entry.mode === 'native')),
    js: throughputSummaries(runs.filter(entry => entry.mode === 'js'))};
  const candidateReport = runs.find(entry => entry.role === 'candidate' && entry.mode === 'native' && entry.repetition === 1).report;
  const controlReport = runs.find(entry => entry.role === 'control' && entry.mode === 'native' && entry.repetition === 1).report;
  if (fileSha(stageOne.path) !== stageOne.sha256 || fileSha(candidate.binary.path) !== candidate.binary.sha256)
    fail('throughput candidate inputs changed during measurement');
  if (fileSha(bindings.frozenRoot) !== bindings.bindings.frozenRoot.sha256)
    fail('frozen root changed during measurement');
  for (const [path, digest] of Object.entries(bindings.inputs))
    if (fileSha(path) !== digest) fail('frozen input changed during measurement: ' + path);
  return {
    status: 'PAIRED_FULL_ROOT_THROUGHPUT_PASS',
    measured: true,
    diagnosticOnly: true,
    acceptanceEvidence: false,
    profiledTimingsExcluded: true,
    candidateCompilerAccepted: false,
    frozen: {root: bindings.frozenRoot, rootSha256: bindings.bindings.frozenRoot.sha256,
      repository: bindings.frozenRepository, inputs: Object.keys(bindings.inputs).length},
    bindings: {path: bindings.path, sha256: bindings.sha256,
      baselineAcceptance: bindings.bindings.baselineAcceptance, waveBase: bindings.bindings.waveBase},
    fixedpoint: {stageOneSha256: stageOne.sha256, stageOneBytes: stageOne.bytes,
      criterion: 'exact stage-one/stage-two byte equality was required before measurement'},
    outputAuthentication: {candidateNativeEqualsCandidateJs: true, candidateSha256: candidateExpected,
      controlMatchesAcceptedBaseline: true, controlSha256: controlReport.output.sha256,
      rule: 'candidate native and JS lanes are compared to each other; the control is compared to its authenticated accepted baseline'},
    control: {native: bindings.controlNative, nativeSha256: bindings.controlNativeSha256,
      image: bindings.controlImage, imageSha256: bindings.controlImageSha256,
      outputSha256: controlReport.output.sha256},
    candidate: {native: candidate.binary.path, nativeSha256: candidate.binary.sha256,
      image: stageOne.path, imageSha256: stageOne.sha256, outputSha256: candidateExpected,
      outputBytes: candidateReport.output.bytes},
    order,
    runs: runs.map(entry => ({role: entry.role, mode: entry.mode, repetition: entry.repetition,
      pipelineElapsedMs: entry.report.pipelineElapsedMs, phases: entry.row.phases,
      outputSha256: entry.report.output.sha256, peakRssBytes: entry.report.guardian.peakRssBytes,
      peakFootprintBytes: entry.report.guardian.peakFootprintBytes,
      ...(distributed ? {physical: entry.physical} : {}),
      guardian: entry.row.guardian, report: entry.row.report})),
    summary,
    ...(distributed ? {placement: distributed.placement} : {}),
    note: distributed
      ? 'Explicit distributed transport: each six-row lane is sequential on its dedicated pinned physical host; native output is authenticated before JS. No global same-host claim. Diagnostic evidence only.'
      : 'Unprofiled, same-host, sequentially interleaved clean full-root pairs on the frozen G22 corpus; profiled cost-attribution runs are excluded. Measurements are diagnostic evidence, not a performance acceptance.',
  };
}

// ---------------------------------------------------------------------------
// Entry points
// ---------------------------------------------------------------------------

async function main() {
  const {values} = parseOptions(process.argv.slice(2),
    ['--run-id', '--phase', '--repository', '--bun', '--node', '--clang', '--llvm-bin', '--out',
      '--bindings', '--frozen-repository', '--control-native', '--control-image', '--from-receipt',
      '--fail-fast-performance', '--distributed-plan', '--cc-partitions']);
  const runId = required(values, '--run-id');
  if (!/^[A-Za-z0-9][A-Za-z0-9_-]{0,79}$/.test(runId)) fail('unsafe --run-id');
  const repository = realpathSync(resolve(values.get('--repository') ?? resolve(dirname(SCRIPT), '..')));
  const bun = realpathSync(values.get('--bun') ?? process.execPath);
  const node = realpathSync(required(values, '--node'));
  const clang = values.get('--clang') ?? '/usr/bin/clang';
  const llvmBin = resolve(values.get('--llvm-bin') ?? '/opt/homebrew/opt/llvm@21/bin');
  const phase = values.get('--phase') ?? 'all';
  if (!['all', 'correctness', 'throughput'].includes(phase)) fail('--phase must be all, correctness or throughput');
  const ccPartitionsValue = values.get('--cc-partitions') ?? '4';
  if (!['4', '8'].includes(ccPartitionsValue)) fail('--cc-partitions must be exactly 4 or 8');
  if (phase === 'throughput' && values.has('--cc-partitions'))
    fail('--cc-partitions is not valid for throughput-only runs');
  const ccPartitions = Number(ccPartitionsValue);
  const distributed = values.has('--distributed-plan') ? loadPlan(resolve(values.get('--distributed-plan'))) : undefined;
  const failFastPerformance = booleanOption(values, '--fail-fast-performance');
  if (failFastPerformance && phase === 'correctness')
    fail('--fail-fast-performance requires a phase that measures throughput (all or throughput)');
  let out = resolve(values.get('--out') ?? resolve(repository, 'checkpoints', runId));
  if (existsSync(out)) fail('output directory already exists: ' + out);
  const checkpoints = checkpointsFor(repository);
  assertFreshNamespace(checkpoints, runId, out);
  assertAbi();

  const launchCwd = process.cwd();
  process.chdir(repository);
  mkdirSync(out, {recursive: true});
  // Every downstream proof and relative input uses the same real output root.
  out = realpathSync(out);
  const context = {repository, runId, bun, node, clang, llvmBin, out, phase, launchCwd,
    bindings: undefined, candidate: undefined, ccPartitions, distributed};

  const run = createRun({repository, runId, node, bun, clang, llvmBin, out, phase});
  run.receipt.launchCwd = launchCwd;
  run.receipt.failFastPerformance = failFastPerformance;
  if (phase !== 'throughput') run.receipt.requestedCcPartitions = ccPartitions;
  if (distributed) {
    run.receipt.distributed = {protocol: 1, mode: context.distributed.mode,
      planSha256: context.distributed.planSha256, placement: context.distributed.placement,
      hosts: context.distributed.hosts};
  }
  run.publish();

  try {
    // The accepted per-step gates are exclusive. The matrix runner starts one
    // gate per fixture stage, so wrapping this whole runner in another gate
    // would be LOCK_BUSY, never stricter. Fail before any heavy work.
    if (/^[a-f0-9]{64}$/.test(process.env.HEAVY_GATE_LEASE_TOKEN ?? ''))
      fail('do not wrap g24_qualification inside another heavy_gate: it applies the accepted 8192MiB/600s guard to each heavy step itself');
    run.receipt.preflight = preflightTools({repository, bun, node, clang, llvmBin});
    process.env.PATH = childEnv({repository, node, bun, clang, llvmBin}).PATH;
    Object.assign(process.env, {
      HEAVY_GATE_MEMORY_MIB: String(LIMITS.memoryMiB),
      HEAVY_GATE_RSS_MIB: String(LIMITS.rssMiB),
      HEAVY_GATE_POLL_MS: String(LIMITS.pollMs),
      HEAVY_GATE_TIMEOUT_MS: String(LIMITS.timeoutMs),
    });
    if (run.receipt.preflight.clang.resolved) {
      context.clang = run.receipt.preflight.clang.resolved;
      run.receipt.preflight.clang.command = context.clang;
    }
    run.publish();
    if (phase !== 'correctness') {
      const bindingsPath = resolve(required(values, '--bindings'));
      const frozenRepository = realpathSync(required(values, '--frozen-repository'));
      const controlNative = resolve(required(values, '--control-native'));
      const controlImage = resolve(required(values, '--control-image'));
      context.bindings = validateBindings(bindingsPath, {repository, frozenRepository, controlNative, controlImage});
    }
    if (phase === 'throughput') {
      const prior = resolve(required(values, '--from-receipt'));
      context.evidence = readJson(prior).correctness;
      context.candidate = authenticatePriorCorrectness(prior, repository);
      context.bindings.candidateCarriedFrom = context.candidate.receipt;
    }
    if (phase !== 'throughput') {
      const correctness = await runCorrectness(run, context);
      run.receipt.correctness = correctness;
      run.receipt.correctnessPassed = true;
      run.receipt.status = run.receipt.throughputMeasured
        ? 'G24_QUALIFICATION_PASS' : 'G24_CORRECTNESS_PASS';
      run.publish();
      context.candidate = {
        repository,
        binary: {path: correctness.native.binary, sha256: correctness.native.binarySha256},
        stageOne: correctness.fixedpoint.stageOne,
      };
    }
    if (phase !== 'correctness' && !run.receipt.throughputMeasured) {
      run.receipt.throughput = await runThroughput(run, context);
      run.receipt.throughputMeasured = true;
      run.publish();
      applyPerformanceGate(run);
      run.receipt.status = phase === 'throughput' ? 'G24_THROUGHPUT_PASS' : 'G24_QUALIFICATION_PASS';
      run.publish();
    }
    run.receipt.failure = null;
    run.receipt.finished = Date.now();
    run.publish();
    console.log(JSON.stringify({status: run.receipt.status, receipt: resolve(out, 'receipt.json')}));
  } catch (error) {
    run.receipt.status = 'FAIL';
    run.receipt.failure = {message: cap(error?.stack ?? error), step: run.receipt.steps.at(-1)?.label ?? null};
    run.receipt.finished = Date.now();
    run.publish();
    console.error(JSON.stringify({status: 'FAIL', receipt: resolve(out, 'receipt.json'), error: run.receipt.failure.message}));
    process.exitCode = 1;
  }
}

// Worker entry points are called only by the explicit authenticated transport.
// Original validators run on the execution host; absolute upstream provenance
// stays untouched in the snapshot and coordinator receipt.
export async function runDistributedWorker(job, snapshot, out, executionRepository) {
  const repository = realpathSync(executionRepository), tools = job.pin.tools;
  const {node, bun, clang, llvmBin} = tools;
  process.chdir(repository);
  Object.assign(process.env, childEnv({repository, ...tools}));
  assertAbi();
  preflightTools({repository, ...tools});
  const run = createRun({repository, ...tools, out, runId: job.context.runId, phase: job.job});
  const binary = resolve(snapshot, 'artifacts/binary'), image = resolve(snapshot, 'artifacts/image');
  const candidate = job.context.candidate;
  if (fileSha(binary) !== candidate.binary.sha256 || fileSha(image) !== candidate.stageOne.sha256
    || statSync(image).size !== candidate.stageOne.bytes) fail('transport candidate artifact drift');
  try {
    let value;
    if (job.job.startsWith('performance-')) {
      const original = job.context.bindings;
      const bindings = validateBindings(resolve(snapshot, 'artifacts/bindings'), {
        repository, frozenRepository: resolve(snapshot, 'frozen'),
        controlNative: resolve(snapshot, 'artifacts/controlNative'), controlImage: resolve(snapshot, 'artifacts/controlImage'),
      });
      if (bindings.sha256 !== original.sha256) fail('transport baseline bindings changed');
      const mode = job.job.slice('performance-'.length);
      if (!['native', 'js'].includes(mode)) fail('unknown performance lane');
      if (mode === 'js' && (!job.extra.nativeTransport || !/^[a-f0-9]{64}$/.test(job.extra.candidateExpected ?? '')))
        fail('JS lane requires authenticated native predecessor');
      value = await runThroughput(run, {repository, ...tools, out, runId: job.context.runId,
        bindings, candidate: {...candidate, binary: {...candidate.binary, path: binary},
          stageOne: {...candidate.stageOne, path: image}},
        measurementMode: mode, candidateExpected: job.extra.candidateExpected});
      for (const row of value.runs) row.physical = job.pin.physical;
    } else {
      const driver = buildStageDriver({repository, node, stageOne: image, out});
      if (job.job.startsWith('matrix-')) {
        const target = job.job.slice(7);
        if (!['c', 'js'].includes(target)) fail('unknown matrix target');
        const logs = resolve(out, 'matrix-' + target);
        run.runPlain('matrix-' + target, [bun, 'evals/c_target_fixtures_run.ts', '--driver=' + driver.path,
          '--node=' + node, '--target=' + target, '--logs=' + logs, '--keep'], {timeoutMs: MATRIX_TIMEOUT_MS});
        value = {matrix: validateMatrix(target, logs, driver)};
      } else {
        const specifications = {
          native: ['NATIVE_FOREIGN_AND_LIBRARY_SMOKE_PASS', NATIVE_SUITE_FILES.length * 2 + 1 + 2],
          admission: ['NATIVE_DATATYPE_AND_EXECUTABLE_ADMISSION_PASS',
            Object.keys(ADMISSION_INPUTS).reduce((n, key) => n + 2 + (key === 'mainless' ? 2 : 0), 0)],
          host: ['ACTUAL_ALIAS_AND_HOST_EXPORT_CONSUMERS_PASS', HOST_CONSUMER_FILES.length],
        };
        const spec = specifications[job.job];
        if (!spec) fail('unknown distributed consumer');
        const directory = resolve(out, job.job);
        await run.runGuarded(job.job, [bun, resolve(repository, 'evals/g24_qualification.mjs'),
          '--suite=' + job.job, '--repository=' + repository, '--node=' + node, '--bun=' + bun,
          '--clang=' + clang, '--out=' + directory,
          ...(job.job === 'host' ? ['--driver=' + driver.path, '--execution-cwd=' + out] : ['--binary=' + binary])]);
        const path = resolve(directory, 'receipt.json'), report = readJson(path), [status, count] = spec;
        if (report.status !== status || report.passed !== true || report.rows.length !== count)
          fail(job.job + ' did not publish all passing rows');
        value = {consumer: {receipt: {path, sha256: fileSha(path)}, status, rows: count, counts: report.counts}};
      }
    }
    run.receipt.status = 'DISTRIBUTED_BRANCH_PASS';
    run.publish();
    return value;
  } catch (error) {
    run.receipt.status = 'FAIL'; run.receipt.failure = {message: String(error?.stack ?? error)}; run.publish();
    throw error;
  }
}

export async function runDistributedConsumersFromReceipt(distributed, priorPath, output) {
  const prior = resolve(priorPath), previous = readJson(prior), repository = realpathSync(previous.repository);
  const candidate = withCwd(repository, () => authenticatePriorCorrectness(prior, repository));
  const out = resolve(output);
  if (existsSync(out)) fail('output directory already exists');
  mkdirSync(out, {recursive: true});
  const tools = distributed.hosts[0].pin.tools;
  const context = {repository, out, runId: previous.runId + '-consumers', ...tools, distributed, candidate};
  const run = createRun({...context, phase: 'distributed-consumers'});
  const state = {...previous.correctness, matrix: {}, consumers: {}};
  try {
    await distributedConsumers(run, context, state, distributedConsumerFiles());
    run.receipt.correctness = state;
    run.receipt.status = 'DISTRIBUTED_CONSUMERS_PASS';
    run.receipt.sourceReceipt = {path: resolve(priorPath), sha256: fileSha(priorPath)};
    run.publish();
  } catch (error) {
    run.receipt.status = 'FAIL'; run.receipt.failure = {message: String(error?.stack ?? error)}; run.publish();
    throw error;
  }
}

async function suiteEntry() {
  const options = suiteOptions(process.argv.slice(2));
  process.chdir(options.repository);
  if (options.suite === 'native') nativeSuite(options);
  else if (options.suite === 'admission') admissionSuite(options);
  else if (options.suite === 'host') hostSuite(options);
  else fail('unknown --suite: ' + options.suite);
}

if (import.meta.main ?? (process.argv[1] !== undefined && realpathSync(process.argv[1]) === realpathSync(SCRIPT))) {
  if (process.argv.slice(2).some(argument => argument.startsWith('--suite=')))
    await suiteEntry();
  else
    await main();
}
