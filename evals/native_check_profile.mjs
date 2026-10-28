#!/usr/bin/env node
/**
 * Bounded external sampler for the native compiler's CHECK phase.
 *
 * Usage:
 *   node evals/native_check_profile.mjs --out-dir=FRESH_DIR [options] -- \
 *     BINARY +RTS --threads 1 --gpu off --RTS ROOT BASE runtime.tsv exports.txt PHASE OUTPUT
 *
 * The helper spawns the unchanged accepted native executable with exactly the
 * argv after `--`. It forwards the child's stdout/stderr byte for byte while
 * capturing them, and it starts /usr/bin/sample only after the host's own
 * stderr protocol announces `NATIVE_PHASE_START {"phase":"check"}`, stopping it
 * when `NATIVE_PHASE {"phase":"check",...}` arrives. The child's argv, cwd,
 * environment, output path and exit status are not modified.
 *
 * Options:
 *   --out-dir=DIR                 fresh output directory (required)
 *   --timeout-ms=N                child wall ceiling, default 600000
 *   --sample-interval-ms=N        sample interval, default 1
 *   --sample-ceiling-s=N          sample duration ceiling, default timeout+120s
 *   --source-map=FILE             C source to map sampled symbols to definitions;
 *                                 repeatable, heuristic (no DWARF is fabricated)
 *   --top-frames=N                symbols listed per table, default 40
 *   --tolerate-sample-failure     keep the child's exit code even when the
 *                                 check phase could not be sampled
 *
 * Exit status: the child's exit status (or the same terminating signal). If the
 * child succeeded but the requested check-phase sample is unusable, the helper
 * exits 70 unless --tolerate-sample-failure is given. A child timeout exits 124.
 *
 * Outputs in DIR: summary.json, child.stdout, child.stderr, check.sample.txt,
 * check.sample.stderr.txt, check.sample.stdout.txt. The helper prints one
 * `NATIVE_CHECK_PROFILE {...}` line to stderr after the child finishes.
 *
 * Attribution limits are written into summary.json: this is an external,
 * symbol-level sample of sampled thread stacks (including blocked/sleeping
 * threads) during one phase. It is not CPU time, not allocation, and not
 * source-line attribution. Per-thread subtrees are retained so the main compute
 * thread can be reported separately from runtime threads. The accepted image has
 * no DWARF line tables, so sampled frames resolve to C symbols only. Sampling
 * suspends the target per sample; its wall/CPU perturbation is not measured by
 * A/B here.
 */
import {createHash} from 'node:crypto';
import {constants as osConstants} from 'node:os';
import {createWriteStream, existsSync, mkdirSync, readFileSync, realpathSync, writeFileSync} from 'node:fs';
import {basename, join, resolve} from 'node:path';
import {spawn} from 'node:child_process';
import {performance} from 'node:perf_hooks';

const SAMPLE_TOOL = '/usr/bin/sample';
// Conservative Darwin wait/blocking primitives. A sampled stack ending at one
// of these is reported as waiting, not as compiler work; everything else stays
// explicitly "sampled, not CPU".
const WAIT_SYMBOLS = new Set(['__psynch_cvwait', '__psynch_cvsignal', '__psynch_mutexwait', '__psynch_mutexdrop',
  '__psynch_rw_rdlock', '__psynch_rw_wrlock', '__psynch_rw_unlock', '__semwait_signal', 'semaphore_wait_trap',
  'mach_msg2_trap', 'mach_msg_trap', 'kevent', 'kevent_id', '__ulock_wait', '__ulock_wait2', 'swtch_pri', 'swtch',
  'thread_switch', '__workq_kernreturn', '__select', 'select', 'poll', '__poll'].map(symbol => symbol.replace(/^_+/, '')));
const PHASE_START_PREFIX = 'NATIVE_PHASE_START ';
const PHASE_PREFIX = 'NATIVE_PHASE ';
const BEGIN_PREFIX = 'NATIVE_BEGIN ';
const FUEL_PREFIX = 'NATIVE_FUEL ';

const argv = process.argv.slice(2);
const separator = argv.indexOf('--');

const options = {outDir: undefined, timeoutMs: 600000, sampleIntervalMs: 1, sampleCeilingS: undefined,
  tolerateSampleFailure: false, sourceMaps: [], topFrames: 40, identifyOnly: false, symbolMap: false,
  generatedC: undefined, manifest: undefined, out: undefined, module: undefined};
for (const argument of (separator < 0 ? argv : argv.slice(0, separator))) {
  const match = /^--([a-z-]+)(?:=(.*))?$/.exec(argument);
  if (!match) usage('Unsupported argument: ' + argument);
  const [, key, raw] = match;
  if (key === 'out-dir') options.outDir = raw;
  else if (key === 'timeout-ms') options.timeoutMs = positiveInteger(raw, key);
  else if (key === 'sample-interval-ms') options.sampleIntervalMs = positiveInteger(raw, key);
  else if (key === 'sample-ceiling-s') options.sampleCeilingS = positiveInteger(raw, key);
  else if (key === 'source-map') {
    if (!raw) usage('--source-map requires a path');
    options.sourceMaps.push(resolve(raw));
  } else if (key === 'top-frames') options.topFrames = positiveInteger(raw, key);
  else if (key === 'tolerate-sample-failure') {
    if (raw !== undefined) usage('--tolerate-sample-failure takes no value');
    options.tolerateSampleFailure = true;
  } else if (key === 'identify-only') {
    if (raw !== undefined) usage('--identify-only takes no value');
    options.identifyOnly = true;
  } else if (key === 'symbol-map') {
    if (raw !== undefined) usage('--symbol-map takes no value');
    options.symbolMap = true;
  } else if (key === 'generated-c' || key === 'manifest' || key === 'out' || key === 'module') {
    if (!raw) usage('--' + key + ' requires a path');
    options[{ 'generated-c': 'generatedC', manifest: 'manifest', out: 'out', module: 'module' }[key]] = raw;
  } else usage('Unsupported option: --' + key);
}
if (options.timeoutMs > 3600000) usage('--timeout-ms must be at most 3600000');
if (options.sampleIntervalMs > 100) usage('--sample-interval-ms must be at most 100');
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
if (options.symbolMap) {
  if (!options.generatedC || !options.manifest || !options.out) usage('--symbol-map requires --generated-c, --manifest and --out');
  runSymbolMap(options);
  process.exit(0);
}
if (!options.identifyOnly && !existsSync(SAMPLE_TOOL)) {
  console.error('native_check_profile: missing OS prerequisite ' + SAMPLE_TOOL + ' (Darwin sampler); refusing to fall back');
  process.exit(69);
}
for (const path of options.sourceMaps) if (!existsSync(path)) usage('--source-map file is missing: ' + path);
if (separator < 0 || separator === argv.length - 1) usage('Expected -- followed by the native compiler argv');

const command = argv.slice(separator + 1);
if (options.identifyOnly) {
  let identity;
  try {
    identity = machOIdentity(command[0]);
  } catch (error) {
    console.error('native_check_profile: cannot read target binary ' + command[0] + ': ' + error.message);
    process.exit(69);
  }
  if (!identity.machO || !identity.uuid) {
    console.error('native_check_profile: target is not a Mach-O 64-bit image with LC_UUID: ' + command[0]);
    process.exit(69);
  }
  console.log(JSON.stringify({kind: 'native-check-profile-identity', ...identity,
    dwarfSegments: identity.segments.filter(name => name.startsWith('__DWARF'))}, null, 2));
  process.exit(0);
}
if (!options.outDir) usage('--out-dir is required');
const outDir = resolve(options.outDir);
const sampleCeilingS = options.sampleCeilingS ?? Math.ceil(options.timeoutMs / 1000) + 120;
const sampleFile = join(outDir, 'check.sample.txt');
const sampleStderrPath = join(outDir, 'check.sample.stderr.txt');
const sampleStdoutPath = join(outDir, 'check.sample.stdout.txt');
const stdoutPath = join(outDir, 'child.stdout');
const stderrPath = join(outDir, 'child.stderr');
const summaryPath = join(outDir, 'summary.json');
for (const path of [sampleFile, sampleStderrPath, sampleStdoutPath, stdoutPath, stderrPath, summaryPath]) {
  if (existsSync(path)) usage('Refusing to overwrite existing output: ' + path);
}
mkdirSync(outDir, {recursive: true});

const startedAt = new Date().toISOString();
const helperStartMs = performance.now();
const helperCpuStart = process.cpuUsage();

let binaryIdentity;
try {
  binaryIdentity = machOIdentity(command[0]);
} catch (error) {
  console.error('native_check_profile: cannot read target binary ' + command[0] + ': ' + error.message);
  process.exit(69);
}
if (!binaryIdentity.machO) {
  console.error('native_check_profile: target is not a Mach-O 64-bit image: ' + command[0]);
  process.exit(69);
}
if (!binaryIdentity.uuid) {
  console.error('native_check_profile: target Mach-O has no LC_UUID; image identity cannot be pinned');
  process.exit(69);
}

const stdoutFile = createWriteStream(stdoutPath, {flags: 'wx'});
const stderrFile = createWriteStream(stderrPath, {flags: 'wx'});
for (const stream of [process.stdout, process.stderr]) stream.on('error', () => {});
for (const stream of [stdoutFile, stderrFile]) stream.on('error', error => {
  console.error('native_check_profile: capture stream failed: ' + error.message);
  process.exitCode = 74;
});
const stdoutHash = createHash('sha256'), stderrHash = createHash('sha256');
let stdoutBytes = 0, stderrBytes = 0;

const child = spawn(command[0], command.slice(1), {cwd: process.cwd(), env: process.env, stdio: ['ignore', 'pipe', 'pipe']});
const childPid = child.pid ?? null;
const childSpawnMs = performance.now();

let checkStart = null, checkEnd = null, begin = null;
const fuel = [], protocolErrors = [];
let sample = null, sampleStopPromise = null;
let timedOut = false, timeoutTimer = null;

child.stdout.on('data', chunk => {
  stdoutBytes += chunk.length;
  stdoutHash.update(chunk);
  stdoutFile.write(chunk);
  process.stdout.write(chunk);
});
child.stderr.on('data', chunk => {
  stderrBytes += chunk.length;
  stderrHash.update(chunk);
  stderrFile.write(chunk);
  process.stderr.write(chunk);
  consumeStderr(chunk);
});

let carry = '';
function consumeStderr(chunk) {
  carry += chunk.toString('utf8');
  for (let newline; (newline = carry.indexOf('\n')) >= 0;) {
    const line = carry.slice(0, newline);
    carry = carry.slice(newline + 1);
    handleProtocolLine(line);
  }
}

function handleProtocolLine(line) {
  if (line.startsWith(PHASE_START_PREFIX)) {
    const row = parseProtocol(line, PHASE_START_PREFIX);
    if (row.phase === 'check' && !checkStart) {
      checkStart = {row, helperMs: performance.now() - helperStartMs, at: new Date().toISOString()};
      startSample('phase-check-start');
    }
    return;
  }
  if (line.startsWith(PHASE_PREFIX)) {
    const row = parseProtocol(line, PHASE_PREFIX);
    if (row.phase === 'check' && !checkEnd) {
      checkEnd = {row, helperMs: performance.now() - helperStartMs, at: new Date().toISOString()};
      sampleStopPromise = stopSample('phase-check-end');
    }
    return;
  }
  if (line.startsWith(BEGIN_PREFIX)) {
    if (!begin) begin = parseProtocol(line, BEGIN_PREFIX);
    return;
  }
  if (line.startsWith(FUEL_PREFIX)) {
    fuel.push(parseProtocol(line, FUEL_PREFIX));
  }
}

function parseProtocol(line, prefix) {
  try {
    const row = JSON.parse(line.slice(prefix.length));
    if (row && typeof row === 'object') return row;
    throw Error('not an object');
  } catch (error) {
    protocolErrors.push({line: line.slice(0, 240), error: String(error.message ?? error)});
    return {};
  }
}

function startSample(reason) {
  if (sample || !childPid) return;
  const sampleStderr = createWriteStream(sampleStderrPath, {flags: 'wx'});
  const sampleStdout = createWriteStream(sampleStdoutPath, {flags: 'wx'});
  const startedMs = performance.now();
  const proc = spawn(SAMPLE_TOOL, [String(childPid), String(sampleCeilingS), String(options.sampleIntervalMs),
    '-mayDie', '-fullPaths', '-file', sampleFile], {stdio: ['ignore', 'pipe', 'pipe']});
  const record = {reason, tool: SAMPLE_TOOL, pid: proc.pid ?? null, command: [SAMPLE_TOOL, String(childPid),
    String(sampleCeilingS), String(options.sampleIntervalMs), '-mayDie', '-fullPaths', '-file', sampleFile],
  file: sampleFile, startedAt: new Date().toISOString(), startMs: startedMs, attachMs: null,
  attachLineAt: null, stderrText: '', stop: null, exited: null, forcedKill: false};
  sample = record;
  proc.stdout.on('data', chunk => {
    sampleStdout.write(chunk);
    process.stderr.write(chunk);
  });
  proc.stderr.on('data', chunk => {
    sampleStderr.write(chunk);
    process.stderr.write(chunk);
    record.stderrText += chunk.toString('utf8');
    if (record.attachMs === null && /Sampling process/.test(record.stderrText)) {
      record.attachMs = performance.now() - startedMs;
      record.attachLineAt = new Date().toISOString();
    }
  });
  proc.on('error', error => {
    record.spawnError = String(error.message ?? error);
  });
  proc.on('exit', (code, signal) => {
    record.exited = {code, signal, at: new Date().toISOString(), helperMs: performance.now() - helperStartMs};
  });
  record.proc = proc;
  record.sampleStderr = sampleStderr;
  record.sampleStdout = sampleStdout;
}

async function stopSample(reason) {
  const record = sample;
  if (!record || record.stop) return record;
  record.stop = {reason, at: new Date().toISOString(), helperMs: performance.now() - helperStartMs};
  if (!record.exited && !record.spawnError) {
    try {
      record.proc.kill('SIGINT');
    } catch (error) {
      record.stop.signalError = String(error.message ?? error);
    }
  }
  const exit = await waitForExit(record.proc, 120000);
  if (!exit.exited) {
    record.forcedKill = true;
    try {
      record.proc.kill('SIGKILL');
    } catch {}
    await waitForExit(record.proc, 10000);
  }
  record.exit = record.exited ?? {code: null, signal: null, note: 'no exit event observed'};
  record.elapsedMs = performance.now() - record.startMs;
  record.sampleStderr.end();
  record.sampleStdout.end();
  await Promise.all([finished(record.sampleStderr), finished(record.sampleStdout)]);
  return record;
}

function waitForExit(proc, timeoutMs) {
  if (proc.exitCode !== null || proc.signalCode !== null) return Promise.resolve({exited: true});
  return new Promise(resolvePromise => {
    let settled = false;
    const done = value => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      resolvePromise(value);
    };
    const timer = setTimeout(() => done({exited: false}), timeoutMs);
    proc.once('exit', () => done({exited: true}));
  });
}

function finished(stream) {
  if (stream.writableFinished) return Promise.resolve();
  return new Promise(resolvePromise => stream.once('finish', resolvePromise));
}

timeoutTimer = setTimeout(() => {
  timedOut = true;
  try {
    child.kill('SIGKILL');
  } catch {}
}, options.timeoutMs);

const childResult = await new Promise(resolvePromise => {
  let settled = false;
  const done = value => {
    if (settled) return;
    settled = true;
    resolvePromise(value);
  };
  child.once('error', error => done({error: String(error.message ?? error), code: null, signal: null}));
  child.once('close', (code, signal) => done({code, signal}));
});
clearTimeout(timeoutTimer);
const childEndMs = performance.now();
if (carry) {
  handleProtocolLine(carry);
  carry = '';
}
if (sample && !sample.stop) sampleStopPromise = stopSample('child-exit');
if (sampleStopPromise) await sampleStopPromise;
if (sample && sample.stop && sample.exit && sample.exited === null) await stopSample('finalize');

stdoutFile.end();
stderrFile.end();
await Promise.all([finished(stdoutFile), finished(stderrFile)]);

const childStdout = readFileSync(stdoutPath);
const childStderr = readFileSync(stderrPath);
const sampleExists = existsSync(sampleFile);
const sampleText = sampleExists ? readFileSync(sampleFile, 'utf8') : null;
const parsed = sampleText ? parseSampleText(sampleText, {
  binaryPath: binaryIdentity.realPath,
  binaryName: basename(binaryIdentity.realPath),
  binaryUuid: binaryIdentity.uuid,
  intervalMs: options.sampleIntervalMs,
  topFrames: options.topFrames,
}) : null;

const targetFrames = parsed?.frames.filter(row => row.image === parsed.targetImage?.name) ?? [];
const mapped = options.sourceMaps.length
  ? mapSymbolsToSources(options.sourceMaps, targetFrames.slice(0, options.topFrames).map(row => row.symbol))
  : null;

const helperCpu = process.cpuUsage(helperCpuStart);
const helperEndMs = performance.now();
const checkObserved = Boolean(checkStart && checkEnd);
const targetUuidMatches = Boolean(parsed?.targetImage
  && parsed.targetImage.uuid.replaceAll('-', '') === binaryIdentity.uuid.replaceAll('-', ''));
const selfConsistent = Boolean(parsed && parsed.selfCountSum === parsed.totalSamples);
const protocolClean = protocolErrors.length === 0;
const samplerExitedCleanly = Boolean(sample && sample.exit && !sample.forcedKill
  && sample.exit.code === 0 && !sample.exit.signal);
const sampleCoveredCheckEnd = Boolean(checkEnd && sample?.exited?.helperMs !== undefined
  && sample.exited.helperMs >= checkEnd.helperMs);
const sampleUsable = Boolean(parsed && parsed.totalSamples > 0 && checkObserved && targetUuidMatches
  && selfConsistent && protocolClean && samplerExitedCleanly && sampleCoveredCheckEnd);
const sampleFailureReasons = [];
if (!checkObserved) sampleFailureReasons.push(checkStart ? 'check phase started but no NATIVE_PHASE check row was observed' : 'no NATIVE_PHASE_START check row was observed');
if (!sample) sampleFailureReasons.push('sampler was never started');
else {
  if (sample.spawnError) sampleFailureReasons.push('sampler failed to start: ' + sample.spawnError);
  if (!sample.exit) sampleFailureReasons.push('sampler exit status was not observed');
  else if (sample.exit.signal) sampleFailureReasons.push('sampler terminated by signal ' + sample.exit.signal);
  else if (sample.exit.code !== 0) sampleFailureReasons.push('sampler exited ' + sample.exit.code);
  if (sample.forcedKill) sampleFailureReasons.push('sampler did not stop on SIGINT and was killed');
  if (checkEnd && sample.exited?.helperMs !== undefined && sample.exited.helperMs < checkEnd.helperMs)
    sampleFailureReasons.push('sampler exited before the check phase ended; sample window does not cover the whole check');
  if (!sampleExists) sampleFailureReasons.push('sampler produced no report file');
  else if (!parsed) sampleFailureReasons.push('sampler report could not be parsed');
  else {
    if (parsed.totalSamples === 0) sampleFailureReasons.push('sampler report contains no samples');
    if (!parsed.targetImage) sampleFailureReasons.push('sampled binary images do not contain the pinned target image');
    else if (!targetUuidMatches) sampleFailureReasons.push('sampled target UUID ' + parsed.targetImage.uuid + ' differs from pinned LC_UUID ' + binaryIdentity.uuid);
    if (!selfConsistent) sampleFailureReasons.push('sampled self counts ' + parsed.selfCountSum + ' differ from thread-root total ' + parsed.totalSamples);
  }
}
if (!protocolClean) sampleFailureReasons.push('native phase protocol contained ' + protocolErrors.length + ' malformed record(s)');
const status = childResult.error ? 'child_spawn_error'
  : timedOut ? 'timeout'
  : childResult.code !== 0 ? 'child_failed'
  : sampleFailureReasons.length ? 'profile_incomplete'
  : 'complete';

const summary = {
  schemaVersion: 1,
  kind: 'native-check-phase-external-sample',
  status,
  profileUsable: sampleUsable,
  usabilityRequirements: 'check start+end observed; sampler exited 0 without forced kill; report parsed with samples; pinned target image and UUID match; protocol clean; per-thread self counts reconcile to thread-root totals',
  scope: 'external Darwin sample of the unchanged accepted native executable, restricted to the host-announced check phase',
  startedAt,
  endedAt: new Date().toISOString(),
  outDir,
  command,
  child: {
    binary: binaryIdentity.realPath,
    binaryArgument: command[0],
    binarySha256: binaryIdentity.sha256,
    binaryUuid: binaryIdentity.uuid,
    machO: {fileType: binaryIdentity.fileType, segments: binaryIdentity.segments, symbolCount: binaryIdentity.symbolCount,
      dwarfSegments: binaryIdentity.segments.filter(name => name.startsWith('__DWARF'))},
    pid: childPid,
    cwd: process.cwd(),
    spawnMs: childSpawnMs - helperStartMs,
    exitCode: childResult.code,
    signal: childResult.signal,
    error: childResult.error,
    timedOut,
    elapsedMs: childEndMs - childSpawnMs,
    stdout: {path: stdoutPath, bytes: stdoutBytes, sha256: stdoutHash.digest('hex')},
    stderr: {path: stderrPath, bytes: stderrBytes, sha256: stderrHash.digest('hex')},
    protocol: {begin, fuelRows: fuel.length, checkStart: checkStart?.row ?? null, checkEnd: checkEnd?.row ?? null,
      errors: protocolErrors},
  },
  checkPhase: {
    name: 'check',
    identification: 'native_compiler_host.c stderr protocol: NATIVE_PHASE_START {"phase":"check"} ... NATIVE_PHASE {"phase":"check",...}',
    startHelperMs: checkStart ? round(checkStart.helperMs) : null,
    endHelperMs: checkEnd ? round(checkEnd.helperMs) : null,
    helperObservedWallMs: checkStart && checkEnd ? round(checkEnd.helperMs - checkStart.helperMs) : null,
    hostElapsedMs: checkEnd?.row?.elapsedMs ?? null,
    hostUserCpuMs: checkEnd?.row?.userCpuMs ?? null,
    hostSystemCpuMs: checkEnd?.row?.systemCpuMs ?? null,
    hostChunkAdvances: checkEnd?.row?.chunkAdvances ?? null,
    hostChunkQuantum: checkEnd?.row?.chunkQuantum ?? null,
    attribution: 'hostElapsedMs/userCpuMs/systemCpuMs are the native host getrusage(RUSAGE_SELF)+monotonic receipt for the check span; the external sampler perturbs that span by an unmeasured amount',
  },
  sampling: sample ? {
    tool: SAMPLE_TOOL,
    command: sample.command,
    intervalMs: options.sampleIntervalMs,
    ceilingSeconds: sampleCeilingS,
    startReason: sample.reason,
    startHelperMs: round(sample.startMs - helperStartMs),
    attachObservedMs: sample.attachMs === null ? null : round(sample.attachMs),
    attachLineAt: sample.attachLineAt,
    stop: sample.stop,
    stopHelperMs: sample.stop ? round(sample.stop.helperMs) : null,
    windowMs: sample.stop ? round(sample.stop.helperMs - (sample.startMs - helperStartMs)) : null,
    exit: sample.exit,
    forcedKill: sample.forcedKill,
    coveredCheckEnd: sampleCoveredCheckEnd,
    processElapsedMs: sample.elapsedMs === undefined ? null : round(sample.elapsedMs),
    report: sampleExists ? {path: sampleFile, bytes: readFileSync(sampleFile).length, sha256: sha256(readFileSync(sampleFile))} : null,
    stderrPath: sampleStderrPath,
    stdoutPath: sampleStdoutPath,
    stderrText: sample.stderrText.slice(0, 4000),
    attachLatencyNote: 'sample attach latency is observed only from its own "Sampling process" line; the first sampled stack can lag the check start by that interval',
  } : null,
  sample: parsed ? {
    totalSamples: parsed.totalSamples,
    threadCount: parsed.threadCount,
    nominalSampledMs: round(parsed.totalSamples * options.sampleIntervalMs),
    countSemantics: 'sampled thread stacks, including blocked/sleeping threads; not CPU time and never rescaled to hostElapsedMs',
    selfCountSum: parsed.selfCountSum,
    selfCountMismatch: parsed.selfCountSum !== parsed.totalSamples,
    waitingSamples: parsed.waitingSamples,
    nonWaitingSamples: parsed.nonWaitingSamples,
    mainThreadIndex: parsed.mainThreadIndex,
    mainThreadInferred: parsed.mainThreadInferred,
    mainThread: parsed.mainThread,
    threads: parsed.threads,
    targetImage: parsed.targetImage,
    imageCount: parsed.images.length,
    selfByImage: parsed.byImage.slice(0, 20),
    topSelf: parsed.frames.slice(0, options.topFrames),
    topInclusive: parsed.inclusive.slice(0, options.topFrames),
    unknownFrames: parsed.unknown.slice(0, 20),
    unknownTotalSamples: parsed.unknownTotalSamples,
    parseWarnings: parsed.warnings,
  } : null,
  sourceMap: mapped ? {
    method: 'single pass over each C file; a symbol maps to the first column-0 line containing `symbol(`; this may be a prototype or declaration rather than the definition, so it is only a heuristic ownership locator, not DWARF or proof of the sampled code path',
    files: options.sourceMaps,
    symbols: mapped,
  } : null,
  helper: {
    elapsedMs: round(helperEndMs - helperStartMs),
    cpuMs: round((helperCpu.user + helperCpu.system) / 1000),
    cpuScope: 'RUSAGE_SELF for this Node wrapper only; the native child and the sampler process are excluded',
    rssBytes: process.memoryUsage().rss,
  },
  limitations: [
    'Attribution is symbol-level only: the accepted image has no __DWARF segments (see child.machO.dwarfSegments), so sample cannot report source lines, inlined frames or variables.',
    'Sample counts are sampled thread stacks (including blocked/sleeping threads) at a nominal ' + options.sampleIntervalMs + '-ms run-time interval; they are not CPU time and must not be rescaled to hostElapsedMs or treated as CPU shares.',
    'Per-thread totals are separate sample populations. Only the main-thread subtree is the compiler compute thread for --threads 1; other threads are runtime threads and may be blocked. waitingSamples counts only conservative wait primitives; nonWaitingSamples is not CPU.',
    'No allocation attribution: this helper observes stacks only. Per-object allocation or byte attribution would require a separately instrumented diagnostic rebuild and is explicitly not claimed here.',
    'External sampling suspends the target per sample; the resulting slowdown of the check span is not measured by an A/B run, so hostElapsedMs and host CPU are perturbed by an unknown amount.',
    'Only the check window is sampled. Parse, expand, emit and fixedpoint comparison are outside the sample window.',
    'sample reports physical footprint at its own attach/report time; that is not an allocation measure and not a phase peak.',
    'The sampler attaches by pid to the child this helper spawned; if attach failed, status is profile_incomplete rather than a silent fallback.',
  ],
};

writeFileSync(summaryPath, JSON.stringify(summary, null, 2) + '\n', {flag: 'wx'});
console.error('NATIVE_CHECK_PROFILE ' + JSON.stringify({status, summary: summaryPath, sample: sampleFile,
  checkObserved, samples: parsed?.totalSamples ?? null, checkWallMs: summary.checkPhase.helperObservedWallMs,
  sampleWindowMs: summary.sampling?.windowMs ?? null, binarySha256: binaryIdentity.sha256, binaryUuid: binaryIdentity.uuid,
  failureReasons: sampleFailureReasons}));

const exitCode = childResult.error ? 127
  : timedOut ? 124
  : childResult.code !== null ? childResult.code
  : childResult.signal ? 128 + (osConstants.signals[childResult.signal] ?? 0)
  : 1;
if (!options.tolerateSampleFailure && status === 'profile_incomplete') {
  process.exitCode = 70;
} else {
  process.exitCode = exitCode;
}
if (childResult.signal && !timedOut) {
  // Preserve the child's terminating signal for the caller instead of mapping it
  // to a synthetic numeric status. summary.json is already durable.
  try {
    process.kill(process.pid, childResult.signal);
  } catch {}
}

/**
 * Build the exact generated-C symbol -> canonical owner map. Provenance comes
 * only from the emitter's `/* FID_<macro>: "<module>:<owner>[$cNN|$kNN]" *\/`
 * comments and the checker manifest's privateHelpers/coverage rows; symbol
 * names are never decoded by guessing. Categories are mutually exclusive and
 * every entry records the rule that assigned it.
 */
function runSymbolMap(options) {
  const cPath = realpathSync(options.generatedC);
  const manifestPath = realpathSync(options.manifest);
  const cBytes = readFileSync(cPath);
  const manifestBytes = readFileSync(manifestPath);
  const manifest = JSON.parse(manifestBytes.toString('utf8'));
  const helpers = new Map((manifest.privateHelpers ?? []).map(row => [row.name, row]));
  const bodies = new Map((manifest.coverage ?? []).map(row => [row.stepBody, row]));
  const coverageNames = new Map((manifest.coverage ?? []).map(row => [row.name, row]));
  const classify = (module, owner, helper, coverage) => {
    if (owner === 'checker_step_one' || owner === 'checker_advance' || owner === 'checker_chunk'
      || /_(step_one|advance|chunk)$/.test(owner))
      return ['scheduler', 'generated step/chunk dispatch'];
    if (helper && (helper.kind === 'ordered-match' || helper.kind === 'pure-ordered-match' || helper.kind === 'continuation'))
      return ['generated-match-continuation', 'CPS match/continuation helper: source semantics and administrative reconstruction are blended'];
    if (coverage || helper?.kind === 'pure-source-body' || /^(checker|emitter|template)_body_/.test(owner))
      return ['source-body', 'coverage stepBody or pure source body'];
    if (module === 'checker_core_steps_v1' || module === 'emitter_steps_v1' || module === 'template_steps_v1'
      || module.startsWith('../bend2/selfhost/') || module === 'append_terms')
      return ['source-body', 'shared canonical source helper'];
    if (module === 'native_experiment' || module === 'main')
      return ['scheduler', 'host entry/driver'];
    return ['unclassified', 'no exact owner rule'];
  };
  const transportEvidenceOf = (owner, coverage) => {
    if (/^readback_/.test(owner))
      return {label: 'arena-read-reconstruction', owner, evidence: 'canonical owner readback_* prefix; result ' + (coverage?.result ?? 'n/a')};
    if (/^arena_decode_/.test(owner))
      return {label: 'arena-read-reconstruction', owner, evidence: 'canonical owner arena_decode_* prefix; result ' + (coverage?.result ?? 'n/a')};
    if (/^arena_get_/.test(owner))
      return {label: 'arena-read', owner, evidence: 'canonical owner arena_get_* prefix; result ' + (coverage?.result ?? 'n/a')};
    if (/^arena_publish_|^arena_pack_/.test(owner))
      return {label: 'arena-result-publication', owner, evidence: 'canonical owner arena_publish_*/arena_pack_* prefix; result ' + (coverage?.result ?? 'n/a')};
    return null;
  };

  const symbols = new Map();
  const categories = {'source-body': 0, 'generated-match-continuation': 0, scheduler: 0,
    'allocation-release': 0, unclassified: 0};
  const transportProjection = {'arena-read-reconstruction': 0, 'arena-read': 0, 'arena-result-publication': 0};
  const modules = {};
  const lines = cBytes.toString('utf8').split('\n');
  let malformed = 0;
  for (const line of lines) {
    const match = /^\/\* (FID_[A-Za-z0-9_]+): "(.*)" \*\/$/.exec(line);
    if (!match) {
      if (line.startsWith('/* FID_')) malformed += 1;
      continue;
    }
    const [, macro, provenance] = match;
    const colon = provenance.indexOf(':');
    const module = colon < 0 ? 'host' : provenance.slice(0, colon);
    const ownerRaw = colon < 0 ? provenance : provenance.slice(colon + 1);
    const owner = ownerRaw.split('$')[0];
    const variant = ownerRaw.includes('$') ? ownerRaw.slice(ownerRaw.indexOf('$') + 1) : null;
    const helper = helpers.get(owner);
    const coverage = bodies.get(owner) ?? coverageNames.get(owner);
    const [category, rule] = classify(module, owner, helper, coverage);
    const canonicalOwner = helper?.owner ?? coverage?.name
      ?? (module === 'checker_core_steps_v1' || module === 'emitter_steps_v1' || module === 'template_steps_v1'
        || module.startsWith('../bend2/selfhost/') || module === 'append_terms' ? owner : null);
    const canonicalOwnerSource = helper ? 'privateHelpers.owner' : coverage ? 'coverage.name'
      : canonicalOwner ? 'fid-provenance-owner' : null;
    const transportEvidence = canonicalOwner ? transportEvidenceOf(canonicalOwner, coverage) : null;
    if (transportEvidence) transportProjection[transportEvidence.label] += 1;
    symbols.set('WL_' + macro, {
      macro,
      provenance,
      module,
      owner,
      variant,
      canonicalOwner,
      canonicalOwnerSource,
      helperKind: helper?.kind ?? null,
      coverage: coverage ? {name: coverage.name, stepBody: coverage.stepBody, result: coverage.result,
        request: coverage.request ?? null, requestEnvelope: coverage.requestEnvelope ?? null} : null,
      transportEvidence,
      category,
      rule,
    });
    categories[category] += 1;
    modules[module] = (modules[module] ?? 0) + 1;
  }
  for (const macro of ['FID_ENTER', 'FID_EXIT']) {
    symbols.set('WL_' + macro, {macro, provenance: null, module: 'host', owner: macro.slice(4),
      variant: null, canonicalOwner: null, canonicalOwnerSource: null, helperKind: null, coverage: null,
      transportEvidence: null, category: 'scheduler', rule: 'host sentinel macro'});
    categories.scheduler += 1;
  }
  const runtimeSets = {
    'allocation-release': ['heap_alloc', 'heap_alloc_miss', 'heap_free', 'heap_hand', 'cls_fit', 'spare_free',
      'blk_new', 'blk_read', 'blk_write', 'blk_at', 'blk_cls', 'blk_ptr', 'blk_span', 'blk_keep', 'blk_wcls',
      'bank_push', 'bank_pop', 'term_drop', 'term_keep', 'row_grow'],
    scheduler: ['native_drive', 'native_experiment_run', 'native_experiment_use', 'native_apply', 'native_accepted',
      'native_closed', 'work_loop', 'pool_step', 'pool_work', 'pool_rows', 'pool_turn', 'pool_open', 'pool_try',
      'pool_mmap', 'pool_stack', 'io_step', 'io_loop', 'monk_step', 'root_take', 'root_done', 'cube_run',
      'ring_rewind', 'ring_flip', 'ring_lap', 'ring_push', 'checker_step_one', 'checker_advance', 'checker_chunk'],
    unclassified: ['term_aux', 'term_blk', 'term_loc', 'term_peek', 'term_rfc', 'term_sink', 'term_tag',
      'term_triv', 'rfc_wrap', 'rfc_seal', 'rfc_bump', 'io_box', 'io_node', 'io_str', 'io_tup', 'io_cbuf', 'io_bit',
      'io_eff', 'io_push', 'io_pop', 'io_park_add', 'io_park_cut', 'io_spawn', 'io_wait_on', 'io_take', 'io_sync',
      'io_out', 'io_errs', 'io_lost', 'io_mem', 'io_utf8', 'io_tick'],
  };
  const runtimeNameSet = new Set(Object.values(runtimeSets).flat());
  const runtimeDefinitions = new Map();
  const definitionPattern = /^(?:static\s+)?(?:(INLINE|FAR|OUTLINE)\s+)?[A-Za-z_][^;{}=]*?\b([A-Za-z_]\w*)\s*\(/;
  for (const line of lines) {
    if (!line || line.charCodeAt(0) === 32 || line.charCodeAt(0) === 9 || line.endsWith(';')) continue;
    const match = definitionPattern.exec(line);
    if (!match || !runtimeNameSet.has(match[2]) || runtimeDefinitions.has(match[2])) continue;
    runtimeDefinitions.set(match[2], {attribute: match[1] ?? 'none', signature: line.trim().slice(0, 200)});
  }
  const missingRuntimeSymbols = [];
  for (const [category, names] of Object.entries(runtimeSets)) {
    for (const name of names) {
      if (symbols.has(name)) continue;
      const definition = runtimeDefinitions.get(name);
      if (!definition) {
        missingRuntimeSymbols.push(name);
        continue;
      }
      symbols.set(name, {macro: null, provenance: null, module: 'runtime', owner: name, variant: null,
        canonicalOwner: null, canonicalOwnerSource: null, helperKind: null, coverage: null,
        transportEvidence: null, attribute: definition.attribute, signature: definition.signature,
        category, rule: 'exact runtime name set'});
      categories[category] += 1;
      modules.runtime = (modules.runtime ?? 0) + 1;
    }
  }
  const inlineAllocationSymbols = [...symbols.values()].filter(row => row.module === 'runtime'
    && row.attribute === 'INLINE' && row.category === 'allocation-release').map(row => row.owner);
  const inlineTransportSymbols = [...symbols.values()].filter(row => row.module === 'runtime'
    && row.attribute === 'INLINE' && /^(term_|rfc_)/.test(row.owner)).map(row => row.owner);
  const inlineRisk = [...new Set([...inlineAllocationSymbols, ...inlineTransportSymbols])];
  const filtered = options.module
    ? Object.fromEntries([...symbols].filter(([, row]) => row.module === options.module))
    : Object.fromEntries(symbols);
  const outPath = resolve(options.out);
  if (existsSync(outPath)) usage('Refusing to overwrite existing symbol map: ' + outPath);
  const result = {
    schemaVersion: 1,
    kind: 'native-check-symbol-map',
    generatedC: {path: cPath, bytes: cBytes.length, sha256: sha256(cBytes)},
    manifest: {path: manifestPath, bytes: manifestBytes.length, sha256: sha256(manifestBytes),
      definitionCount: manifest.definitionCount ?? null, privateHelpers: (manifest.privateHelpers ?? []).length,
      coverage: (manifest.coverage ?? []).length},
    provenanceSource: 'generated C `/* FID_<macro>: "<module>:<owner>[$cNN|$kNN]" */` comments joined to checker manifest privateHelpers/coverage; no symbol-name guessing',
    canonicalOwnerPolicy: 'canonicalOwner comes from privateHelpers.owner for generated helpers, coverage.name for source bodies, or the FID provenance owner for shared source helpers; it is a grouping label, not eliminable overhead',
    categoryRules: {
      'source-body': 'coverage stepBody, pure-source-body helper, *_body_* owner, or shared canonical source helper',
      'generated-match-continuation': 'ordered-match/pure-ordered-match/continuation helper; source semantics and administrative reconstruction are blended, so this is NOT called arena/result transport',
      scheduler: 'generated step/chunk dispatch, host entry/driver, host sentinel, or exact runtime scheduler set',
      'allocation-release': 'exact runtime allocator/release names verified as column-0 generated-C definitions; INLINE members are caller-blended and cannot be separated from caller self samples',
      unclassified: 'no exact owner rule, or a runtime helper with no canonical source owner; must remain explicit in any share',
    },
    transportEvidencePolicy: 'arena/result transport is a secondary, evidenced projection only: readback_* and arena_decode_* (arena-read-reconstruction), arena_get_* (arena-read), arena_publish_*/arena_pack_* (arena-result-publication). It is not a primary category, and allocations inside these owners remain blended.',
    transportProjection,
    inlineRisk: {
      policy: 'INLINE bodies can be inlined into callers, so a sampled caller self frame cannot be split between caller and inlined callee; category shares are sampled-stack shares, not exclusive work',
      inlineAllocationSymbols,
      inlineTransportSymbols,
    },
    missingRuntimeSymbols,
    counts: {fidEntries: [...symbols.values()].filter(row => row.macro !== null).length,
      runtimeEntries: [...symbols.values()].filter(row => row.module === 'runtime').length,
      filtered: Object.keys(filtered).length, malformed, categories, transportProjection, modules},
    symbols: filtered,
  };
  writeFileSync(outPath, JSON.stringify(result) + '\n', {flag: 'wx'});
  console.log(JSON.stringify({kind: result.kind, out: outPath, generatedC: result.generatedC,
    manifest: result.manifest, counts: result.counts}, null, 2));
}

function usage(message) {
  console.error('native_check_profile: ' + message);
  console.error('Usage: node evals/native_check_profile.mjs --out-dir=FRESH_DIR [--timeout-ms=N] [--sample-interval-ms=N] [--sample-ceiling-s=N] [--source-map=FILE] [--top-frames=N] [--tolerate-sample-failure] -- BINARY ARGS...');
  console.error('       node evals/native_check_profile.mjs --identify-only -- BINARY');
  console.error('       node evals/native_check_profile.mjs --symbol-map --generated-c=FILE --manifest=FILE --out=FRESH_JSON [--module=NAME]');
  process.exit(64);
}

function positiveInteger(raw, key) {
  if (!/^[1-9][0-9]*$/.test(raw ?? '')) usage('--' + key + ' requires a positive integer');
  return Number(raw);
}

function round(value) {
  return Math.round(value * 1000) / 1000;
}

/** Minimal Mach-O 64 reader: identity, segments, LC_UUID and symbol count. */
function machOIdentity(path) {
  const realPath = realpathSync(path);
  const bytes = readFileSync(realPath);
  if (bytes.length < 32 || bytes.readUInt32LE(0) !== 0xfeedfacf) return {machO: false, realPath, sha256: sha256(bytes)};
  const fileType = bytes.readUInt32LE(12), ncmds = bytes.readUInt32LE(16), sizeofcmds = bytes.readUInt32LE(20);
  let offset = 32, uuid = null, symbolCount = null;
  const segments = [];
  const end = Math.min(bytes.length, 32 + sizeofcmds);
  for (let index = 0; index < ncmds && offset + 8 <= end; index++) {
    const cmd = bytes.readUInt32LE(offset), size = bytes.readUInt32LE(offset + 4);
    if (size < 8 || offset + size > bytes.length) break;
    if (cmd === 0x1b && size >= 24) {
      const raw = bytes.subarray(offset + 8, offset + 24);
      const hex = raw.toString('hex').toUpperCase();
      uuid = hex.slice(0, 8) + '-' + hex.slice(8, 12) + '-' + hex.slice(12, 16) + '-' + hex.slice(16, 20) + '-' + hex.slice(20);
    } else if (cmd === 0x19 && size >= 72) {
      segments.push(bytes.toString('utf8', offset + 8, offset + 24).replace(/\0.*$/s, ''));
    } else if (cmd === 0x2 && size >= 24) {
      symbolCount = bytes.readUInt32LE(offset + 12);
    }
    offset += size;
  }
  return {machO: true, realPath, sha256: sha256(bytes), uuid, fileType, segments, symbolCount};
}

/** Parse `sample` text output. Counts are samples, never milliseconds of CPU. */
function parseSampleText(text, target) {
  const lines = text.split('\n');
  const warnings = [];
  const header = {};
  let callGraphStart = -1, callGraphEnd = lines.length, imagesStart = -1;
  for (let index = 0; index < lines.length; index++) {
    const line = lines[index], trimmed = line.trim();
    if (trimmed === 'Call graph:') callGraphStart = index;
    else if (callGraphStart >= 0 && imagesStart < 0 && (trimmed === 'Binary Images:' || trimmed.startsWith('Total number in stack') || trimmed.startsWith('Sort by top of stack'))) {
      if (callGraphEnd === lines.length) callGraphEnd = index;
      if (trimmed === 'Binary Images:') imagesStart = index;
    }
    if (callGraphStart < 0) {
      const match = /^([A-Za-z][A-Za-z ]*?):\s+(.*)$/.exec(line);
      if (match) header[match[1].trim()] = match[2].trim();
    }
  }
  if (callGraphStart < 0) warnings.push('sample report has no Call graph section');
  if (imagesStart < 0) warnings.push('sample report has no Binary Images section');

  const parsedLines = [];
  for (let index = callGraphStart + 1; callGraphStart >= 0 && index < callGraphEnd; index++) {
    const line = lines[index];
    if (!line.trim()) continue;
    // sample's call tree encodes depth in the 2-character prefix before the
    // count (spaces plus '+', '|' branch glyphs); leading whitespace alone is
    // not the depth, because a '+' replaces indentation at the same level.
    const match = /^([ +|!:]*?)(\d+)\s+(.+)$/.exec(line);
    if (!match) {
      warnings.push('unparsed call-graph line ' + (index + 1) + ': ' + line.trim().slice(0, 120));
      continue;
    }
    parsedLines.push({prefixLength: match[1].length, count: Number(match[2]), text: match[3], line: index + 1});
  }
  const minPrefix = parsedLines.reduce((min, row) => Math.min(min, row.prefixLength), Infinity);
  const roots = [], stack = [];
  const nodes = [];
  for (const row of parsedLines) {
    const depth = Math.max(0, Math.round((row.prefixLength - minPrefix) / 2));
    const frame = splitFrame(row.text);
    const node = {frame, count: row.count, depth, children: [], parent: null, self: row.count};
    while (stack.length && depth <= stack[stack.length - 1].depth) stack.pop();
    if (stack.length) {
      node.parent = stack[stack.length - 1];
      node.parent.children.push(node);
    } else roots.push(node);
    stack.push(node);
    nodes.push(node);
  }
  for (const node of nodes) for (const child of node.children) node.self -= child.count;
  for (const node of nodes) if (node.self < 0) {
    warnings.push('negative self count for ' + node.frame.symbol + ' (' + node.self + '); clamped to 0');
    node.self = 0;
  }

  const totalSamples = roots.reduce((sum, node) => sum + node.count, 0);
  const selfCountSum = nodes.reduce((sum, node) => sum + node.self, 0);
  if (selfCountSum !== totalSamples) warnings.push('self counts ' + selfCountSum + ' differ from thread-root total ' + totalSamples);

  const aggregate = nodeSet => {
    const byKey = new Map(), inclusive = new Map(), byImage = new Map();
    let unknownTotalSamples = 0, waitingSamples = 0;
    for (const node of nodeSet) {
      const symbol = node.frame.symbol;
      const key = (node.frame.image ?? '') + '\u0000' + symbol
        + (symbol === '???' ? '\u0000' + (node.frame.detail ?? '') : '');
      const row = byKey.get(key) ?? {symbol, image: node.frame.image, detail: node.frame.detail,
        selfSamples: 0, inclusiveSamples: 0, nodes: 0};
      row.selfSamples += node.self;
      row.inclusiveSamples += node.count;
      row.nodes += 1;
      byKey.set(key, row);
      const inclusiveRow = inclusive.get(key) ?? {symbol, image: node.frame.image, detail: node.frame.detail,
        inclusiveSamples: 0, nodes: 0};
      inclusiveRow.inclusiveSamples += node.count;
      inclusiveRow.nodes += 1;
      inclusive.set(key, inclusiveRow);
      const image = node.frame.image ?? '(unknown image)';
      const imageRow = byImage.get(image) ?? {image, selfSamples: 0, inclusiveSamples: 0};
      imageRow.selfSamples += node.self;
      imageRow.inclusiveSamples += node.count;
      byImage.set(image, imageRow);
      if (symbol === '???' || symbol === '') unknownTotalSamples += node.self;
      if (WAIT_SYMBOLS.has(symbol.replace(/^_+/, ''))) waitingSamples += node.self;
    }
    return {byKey, inclusive, byImage, unknownTotalSamples, waitingSamples};
  };
  const global = aggregate(nodes);
  const {byKey, inclusive, byImage} = global;
  const unknownTotalSamples = global.unknownTotalSamples;

  const threads = roots.map((root, index) => {
    const subtree = [];
    const pending = [root];
    while (pending.length) {
      const node = pending.pop();
      subtree.push(node);
      for (const child of node.children) pending.push(child);
    }
    const own = aggregate(subtree);
    const name = root.frame.symbol;
    const threadId = /^Thread_(\d+)/.exec(name)?.[1] ?? null;
    const frames = [...own.byKey.values()].sort((a, b) => b.selfSamples - a.selfSamples
      || b.inclusiveSamples - a.inclusiveSamples || a.symbol.localeCompare(b.symbol));
    const inclusiveRows = [...own.inclusive.values()].sort((a, b) => b.inclusiveSamples - a.inclusiveSamples
      || b.selfSamples - a.selfSamples || a.symbol.localeCompare(b.symbol));
    return {
      index,
      name,
      threadId,
      totalSamples: root.count,
      selfCountSum: subtree.reduce((sum, node) => sum + node.self, 0),
      waitingSamples: own.waitingSamples,
      nonWaitingSamples: root.count - own.waitingSamples,
      waitingShare: root.count ? own.waitingSamples / root.count : 0,
      imageSelf: Object.fromEntries([...own.byImage].map(([image, row]) => [image, row.selfSamples])),
      topSelf: frames.slice(0, target.topFrames),
      topInclusive: inclusiveRows.slice(0, target.topFrames),
    };
  });
  let mainThreadIndex = threads.findIndex(thread => /main-thread/.test(thread.name));
  let mainThreadInferred = false;
  if (mainThreadIndex < 0 && threads.length === 1) {
    mainThreadIndex = 0;
    mainThreadInferred = true;
  }
  if (mainThreadIndex < 0) {
    let best = 0;
    threads.forEach((thread, index) => {
      const targetSamples = thread.imageSelf[target.binaryName] ?? 0;
      if (targetSamples > best) {
        best = targetSamples;
        mainThreadIndex = index;
      }
    });
    if (mainThreadIndex >= 0 && best > 0) mainThreadInferred = true;
    else mainThreadIndex = -1;
  }

  const images = [];
  for (let index = imagesStart + 1; imagesStart >= 0 && index < lines.length; index++) {
    const line = lines[index];
    if (!line.trim()) continue;
    const match = /^\s*(0x[0-9a-fA-F]+)\s*-\s*(0x[0-9a-fA-F]+)\s+([+-]?)(\S+)\s+\(([^)]*)\)\s+<([0-9A-Fa-f-]+)>\s*(.*)$/.exec(line);
    if (!match) {
      warnings.push('unparsed binary-image line ' + (index + 1) + ': ' + line.trim().slice(0, 120));
      continue;
    }
    images.push({start: match[1], end: match[2], name: match[4], version: match[5], uuid: match[6].toUpperCase(), path: match[7].trim()});
  }
  let targetImage = null;
  for (const image of images) {
    let imagePath = null;
    try {
      imagePath = image.path ? realpathSync(image.path) : null;
    } catch {}
    if (imagePath === target.binaryPath || image.uuid.replaceAll('-', '') === target.binaryUuid.replaceAll('-', '')) {
      targetImage = {...image, realPath: imagePath};
      break;
    }
  }
  if (!targetImage) warnings.push('sampled binary images do not contain the target image ' + target.binaryPath + ' <' + target.binaryUuid + '>');
  else if (targetImage.uuid.replaceAll('-', '') !== target.binaryUuid.replaceAll('-', '')) warnings.push('sampled target UUID differs from the executable LC_UUID');
  for (const thread of threads) {
    thread.targetImageSamples = targetImage ? (thread.imageSelf[targetImage.name] ?? 0) : 0;
    thread.targetImageShare = thread.totalSamples ? thread.targetImageSamples / thread.totalSamples : 0;
  }

  const frames = [...byKey.values()].sort((a, b) => b.selfSamples - a.selfSamples || b.inclusiveSamples - a.inclusiveSamples || a.symbol.localeCompare(b.symbol));
  const inclusiveRows = [...inclusive.values()].sort((a, b) => b.inclusiveSamples - a.inclusiveSamples || b.selfSamples - a.selfSamples || a.symbol.localeCompare(b.symbol));
  const unknown = frames.filter(row => row.symbol === '???' || row.symbol === '');
  return {
    totalSamples,
    threadCount: roots.length,
    selfCountSum,
    waitingSamples: global.waitingSamples,
    nonWaitingSamples: totalSamples - global.waitingSamples,
    threads,
    mainThreadIndex,
    mainThreadInferred,
    mainThread: mainThreadIndex >= 0 ? threads[mainThreadIndex] : null,
    frames,
    inclusive: inclusiveRows,
    byImage: [...byImage.values()].sort((a, b) => b.selfSamples - a.selfSamples),
    unknown,
    unknownTotalSamples,
    images,
    targetImage,
    header,
    warnings,
  };
}

function splitFrame(text) {
  const match = /^(.*?)\s+\(in ([^)]+)\)(.*)$/.exec(text);
  if (!match) return {symbol: text.trim(), image: null, detail: null};
  return {symbol: match[1].trim(), image: match[2].trim(), detail: match[3].trim()};
}

/** Heuristic symbol-to-C-definition map; never presented as DWARF attribution. */
function mapSymbolsToSources(files, symbols) {
  const wanted = new Map();
  for (const symbol of symbols) {
    if (!symbol || symbol === '???') continue;
    wanted.set(symbol.replace(/^_/, ''), symbol);
  }
  const found = new Map();
  for (const file of files) {
    const text = readFileSync(file, 'utf8');
    let offset = 0, lineNumber = 1;
    while (offset <= text.length) {
      const newline = text.indexOf('\n', offset);
      const end = newline < 0 ? text.length : newline;
      if (end > offset && text.charCodeAt(offset) !== 32 && text.charCodeAt(offset) !== 9 && text.indexOf('(', offset) >= 0 && text.indexOf('(', offset) < end) {
        const line = text.slice(offset, end);
        for (const match of line.matchAll(/([A-Za-z_]\w*)\s*\(/g)) {
          const id = match[1];
          if (wanted.has(id) && !found.has(id)) found.set(id, {file, line: lineNumber, text: line.trim().slice(0, 240)});
        }
      }
      if (newline < 0) break;
      offset = newline + 1;
      lineNumber += 1;
    }
  }
  return [...wanted].map(([id, symbol]) => ({symbol, definition: found.get(id) ?? null}));
}
