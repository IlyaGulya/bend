#!/usr/bin/env bun
/** Diagnostic profiling-overhead harness for the typed-step compiler host.
 *
 * This is evidence plumbing, not acceptance and not a benchmark. It compares
 * the ordinary candidate_host.ts path (off) with the same host plus the
 * existing `--stage-profile` createStageProfile option (on), on one immutable
 * compiler image and one immutable full source closure. Legs run in fresh
 * directories in alternating order across at least two pairs; every leg is one
 * heavyweight heavy_gate.ts command with explicit identical limits. Nothing is
 * retried, patched, overloaded or substituted.
 *
 * Exact exposed argv (values may use `--name=value` or `--name value`):
 *
 *   --source=PATH            root .bend of the compiler workload (required)
 *   --candidate=PATH         compiled typed-step JS image (required)
 *   --parser=PATH            accepted compiled parser JS (default: candidate)
 *   --base=PATH              base library (default: <repo>/bend2/base.bend)
 *   --candidate-build=PATH   candidate host build receipt; its artifact/source
 *                            identity is checked against --candidate/--source
 *   --target=js|c            emitted source target (default: js)
 *   --runtime-c=PATH         C runtime source (default for c:
 *                            <repo>/bend2/selfhost/c_runtime.c)
 *   --exports=NAME,...       library export names (default: the 13-entry ABI
 *                            from native_seed_runtime.mjs)
 *   --whole-module           emit the whole-module entry instead of a library;
 *                            mutually exclusive with an explicit --exports
 *   --pairs=N                off/on pairs, N >= 2 (default: 2); the first pair
 *                            runs off then on, the next on then off, alternating
 *   --report=PATH            fresh compact JSON report (required; must not exist)
 *   --work-directory=PATH    fresh directory for logs/outputs/profiles; must not
 *                            exist (default: mkdtemp under the OS temp dir)
 *   --node=PATH              Node.js executable (default: node from PATH)
 *   --bun=PATH               Bun executable for heavy_gate.ts (default: the
 *                            running Bun, else bun from PATH)
 *   --worker=PATH            caller copy of the Node 256MiB-stack/
 *                            3072MiB-old-generation worker adapter; it must
 *                            declare both limits. Default: a generated copy of
 *                            that established adapter under the work directory.
 *   --memory-mib=N           heavy-gate physical-footprint limit (default 8192)
 *   --rss-mib=N              heavy-gate RSS limit (default 8192)
 *   --poll-ms=N              heavy-gate sampling interval (default 100)
 *   --timeout-ms=N           heavy-gate deadline (default 600000; larger values
 *                            are diagnostic-only, never acceptance evidence)
 *   --label=TEXT             report label
 *   --expect-failure         negative-control mode: every leg must fail with the
 *                            same exit code and identical host diagnostics
 *   --help                   print this usage
 *
 * Pinned before and after every leg: the candidate image, accepted parser,
 * source root, base, C runtime when used, candidate-build receipt and
 * provenance, the complete workloadRows source/foreign closure, the 13-entry
 * exported ABI module, the harness/runtime helper modules and the worker
 * adapter. Any drift, missing/ambiguous guardian receipt, lock busy, resource
 * limit, incomplete collector profile, unequal output bytes or unequal
 * failure diagnostics aborts the run and is recorded.
 *
 * Wall/user/system CPU and child maximum RSS come only from a Darwin
 * `/usr/bin/time -lp` wait4 receipt around the Node child. Guardian peak RSS and
 * physical footprint come separately from the heavy-gate supervisor. The
 * harness parent's process.cpuUsage is never used as the child's CPU. The
 * time -lp clock is reported to 0.01 s; alternating samples on one machine are
 * operational evidence, not isolated instrumentation cost or exclusive CPU.
 *
 * Bulk logs, emitted sources and collector profiles stay in the ignored work
 * directory. Only the compact report is written to --report.
 */
import {createHash} from 'node:crypto';
import {
 closeSync, existsSync, mkdirSync, mkdtempSync, openSync, readFileSync, readdirSync,
 realpathSync, statSync, writeFileSync,
} from 'node:fs';
import {tmpdir} from 'node:os';
import {dirname, isAbsolute, join, resolve} from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {ABI, workloadRows} from './native_seed_runtime.mjs';

const REPO_ROOT = realpathSync(resolve(dirname(fileURLToPath(import.meta.url)), '..'));
const MiB = 1024 * 1024;
const ACCEPTANCE_LIMITS = Object.freeze({memoryMiB: 8192, rssMiB: 8192, timeoutMs: 600000});
const TERM_GRACE_MS = 1000;
const TIME = Object.freeze({path: '/usr/bin/time', args: Object.freeze(['-lp'])});
const ADAPTER_STACK_MIB = 256;
const ADAPTER_OLD_GENERATION_MIB = 3072;
// The exact established adapter contract at /tmp/bend2039-candidate-worker.mjs:
// a Node worker with a 256 MiB stack and a 3072 MiB old generation.
const ADAPTER_SOURCE = `import {Worker} from 'node:worker_threads';
import {pathToFileURL} from 'node:url';
const [script,...argv]=process.argv.slice(2);
if(!script)throw Error('Expected candidate runner and arguments');
const worker=new Worker(pathToFileURL(script),{argv,resourceLimits:{stackSizeMb:${ADAPTER_STACK_MIB},maxOldGenerationSizeMb:${ADAPTER_OLD_GENERATION_MIB}}});
worker.once('error',error=>{console.error(error);process.exitCode=1;});
worker.once('exit',code=>{process.exitCode=code;});
`;

const sha256 = value => createHash('sha256').update(value).digest('hex');
const hashFile = path => sha256(readFileSync(path));

function pinFile(path) {
  const real = realpathSync(path);
  const bytes = readFileSync(real);
  return {path: real, bytes: bytes.length, sha256: sha256(bytes)};
}

function expect(condition, message) {
  if (!condition) throw Error(message);
}

function errorText(error) {
  return error instanceof Error ? error.message : String(error);
}

function usage() {
  return [
    'usage: bun evals/compiler_profile_overhead.ts --source=PATH --candidate=PATH --report=PATH',
    '  [--parser=PATH] [--base=PATH] [--candidate-build=PATH] [--target=js|c]',
    '  [--runtime-c=PATH] [--exports=NAME,...] [--whole-module] [--pairs=N]',
    '  [--work-directory=PATH] [--node=PATH] [--bun=PATH] [--worker=PATH]',
    '  [--memory-mib=8192] [--rss-mib=8192] [--poll-ms=100] [--timeout-ms=600000]',
    '  [--label=TEXT] [--expect-failure] [--help]',
    '',
    'See the file header for the exact contract and evidence limits.',
  ].join('\n');
}

function integer(value, name, min, max) {
  const number = Number(value);
  if (!Number.isSafeInteger(number) || number < min || number > max)
    throw Error(name + ' must be an integer between ' + min + ' and ' + max);
  return number;
}

function parseOptions(argv) {
  const values = new Map();
  const flags = new Set();
  const withValue = {
    '--source': true, '--candidate': true, '--parser': true, '--base': true,
    '--candidate-build': true, '--target': true, '--runtime-c': true,
    '--exports': true, '--pairs': true, '--report': true,
    '--work-directory': true, '--node': true, '--bun': true, '--worker': true,
    '--memory-mib': true, '--rss-mib': true, '--poll-ms': true,
    '--timeout-ms': true, '--label': true,
  };
  const withoutValue = {'--whole-module': true, '--expect-failure': true, '--help': true};
  for (let i = 0; i < argv.length; i += 1) {
    const argument = argv[i];
    if (typeof argument !== 'string' || !argument.startsWith('--'))
      throw Error('unexpected positional argument: ' + String(argument));
    const equals = argument.indexOf('=');
    const name = equals < 0 ? argument : argument.slice(0, equals);
    if (withoutValue[name] === true) {
      if (equals >= 0) throw Error(name + ' takes no value');
      if (flags.has(name)) throw Error('duplicate option ' + name);
      flags.add(name);
      continue;
    }
    if (withValue[name] !== true) throw Error('unknown option ' + name);
    const value = equals < 0 ? argv[++i] : argument.slice(equals + 1);
    if (value === undefined || value === '')
      throw Error('missing value for ' + name);
    if (values.has(name)) throw Error('duplicate option ' + name);
    values.set(name, value);
  }
  const options = {
    help: flags.has('--help'),
    expectFailure: flags.has('--expect-failure'),
    wholeModule: flags.has('--whole-module'),
    source: values.get('--source') ?? null,
    candidate: values.get('--candidate') ?? null,
    parser: values.get('--parser') ?? null,
    base: values.get('--base') ?? null,
    candidateBuild: values.get('--candidate-build') ?? null,
    target: values.get('--target') ?? 'js',
    runtimeC: values.get('--runtime-c') ?? null,
    report: values.get('--report') ?? null,
    workDirectory: values.get('--work-directory') ?? null,
    node: values.get('--node') ?? 'node',
    bun: values.get('--bun') ?? ((process.versions && process.versions.bun) ? process.execPath : 'bun'),
    worker: values.get('--worker') ?? null,
    label: values.get('--label') ?? 'compiler-profile-overhead',
    memoryMiB: integer(values.get('--memory-mib') ?? 8192, '--memory-mib', 1, 1048576),
    rssMiB: integer(values.get('--rss-mib') ?? 8192, '--rss-mib', 1, 1048576),
    pollMs: integer(values.get('--poll-ms') ?? 100, '--poll-ms', 10, 1000),
    timeoutMs: integer(values.get('--timeout-ms') ?? 600000, '--timeout-ms', 1, 2147483647),
    pairs: integer(values.get('--pairs') ?? 2, '--pairs', 2, 64),
    exports: null,
  };
  if (options.help) return options;
  if (options.target !== 'js' && options.target !== 'c')
    throw Error('--target must be js or c');
  for (const key of ['source', 'candidate', 'report'])
    if (options[key] === null) throw Error('required --' + key + '=PATH');
  if (options.wholeModule && values.has('--exports'))
    throw Error('--whole-module and --exports are mutually exclusive');
  if (!options.wholeModule) {
    const names = values.has('--exports')
      ? values.get('--exports').split(',')
      : ABI.slice();
    if (names.length === 0 || names.some(name => !/^[A-Za-z_][A-Za-z0-9_]*$/.test(name)))
      throw Error('--exports needs comma-separated Bend identifiers');
    if (new Set(names).size !== names.length)
      throw Error('--exports contains a duplicate name');
    options.exports = names;
  }
  if (options.target !== 'c' && values.has('--runtime-c'))
    throw Error('--runtime-c is only valid with --target=c');
  if (options.label.includes('\n') || options.label.includes('\r'))
    throw Error('--label must be one line');
  return options;
}

function resolveExecutable(command, label, initialCwd) {
  let candidate = command;
  if (!command.includes('/')) {
    const which = spawnSync('/usr/bin/which', [command], {encoding: 'utf8', timeout: 60000});
    const found = which.status === 0 ? String(which.stdout).trim().split('\n')[0] : '';
    if (!found) throw Error(label + ' executable not found on PATH: ' + command);
    candidate = found;
  } else if (!isAbsolute(command)) {
    candidate = resolve(initialCwd, command);
  }
  const path = realpathSync(candidate);
  const version = spawnSync(path, ['--version'], {encoding: 'utf8', timeout: 60000, maxBuffer: 1 << 20});
  if (version.error) throw Error(label + ' --version failed: ' + errorText(version.error));
  const text = String(version.stdout || '') + String(version.stderr || '');
  return {
    command,
    path,
    version: version.status === 0 ? text.trim().split('\n')[0] || null : null,
    versionStatus: version.status,
  };
}

function resolveConfig(options, initialCwd, reportPath) {
  const resolveFile = (value, label) => {
    const absolute = isAbsolute(value) ? value : resolve(initialCwd, value);
    let real;
    try {
      real = realpathSync(absolute);
    } catch (error) {
      throw Error(label + ' is not readable: ' + absolute + ': ' + errorText(error));
    }
    if (!statSync(real).isFile()) throw Error(label + ' is not a regular file: ' + real);
    return real;
  };
  const sourcePath = resolveFile(options.source, '--source');
  const candidatePath = resolveFile(options.candidate, '--candidate');
  const parserPath = options.parser === null ? candidatePath : resolveFile(options.parser, '--parser');
  const parserSeparate = options.parser !== null && parserPath !== candidatePath;
  const basePath = resolveFile(options.base ?? join(REPO_ROOT, 'bend2/base.bend'), '--base');
  const candidateBuildPath = options.candidateBuild === null
    ? null
    : resolveFile(options.candidateBuild, '--candidate-build');
  const runtimeCPath = options.target === 'c'
    ? resolveFile(options.runtimeC ?? join(REPO_ROOT, 'bend2/selfhost/c_runtime.c'), '--runtime-c')
    : null;
  const workerOverride = options.worker === null ? null : resolveFile(options.worker, '--worker');
  const workDirectory = options.workDirectory === null
    ? null
    : resolve(initialCwd, options.workDirectory);
  const sourcePin = pinFile(sourcePath);
  const candidatePin = pinFile(candidatePath);
  const parserPin = pinFile(parserPath);
  const basePin = pinFile(basePath);
  return {
    sourcePath,
    candidatePath,
    parserPath,
    parserSeparate,
    basePath,
    candidateBuildPath,
    runtimeCPath,
    workerOverride,
    workDirectory,
    reportPath,
    sourcePin,
    candidatePin,
    parserPin,
    basePin,
    target: options.target,
    library: !options.wholeModule,
    exports: options.exports,
    exportArg: options.exports === null ? null : options.exports.join(','),
    pairs: options.pairs,
    limits: {
      memoryMiB: options.memoryMiB,
      rssMiB: options.rssMiB,
      pollMs: options.pollMs,
      termGraceMs: TERM_GRACE_MS,
      timeoutMs: options.timeoutMs,
    },
  };
}

function inspectCandidateBuild(config) {
  if (config.candidateBuildPath === null) return null;
  const pin = pinFile(config.candidateBuildPath);
  let build;
  try {
    build = JSON.parse(readFileSync(pin.path, 'utf8'));
  } catch (error) {
    throw Error('candidate build receipt is not JSON: ' + errorText(error));
  }
  expect(build !== null && typeof build === 'object' && !Array.isArray(build),
    'candidate build receipt is not an object');
  expect(build.status === 'JS_GENERATED_NOT_YET_EXECUTED', 'candidate build status is not JS_GENERATED_NOT_YET_EXECUTED');
  expect(build.checksExcluded === 0 && build.outputPatches === 0,
    'candidate build excluded checks or patched output');
  expect(build.checkedOutputRetention === 'native e', 'candidate build does not retain native e');
  expect(build.guardian !== null && typeof build.guardian === 'object' && build.guardian.status === 'PASS',
    'candidate build guardian did not pass');
  expect(typeof build.artifactPath === 'string' && typeof build.artifactSha256 === 'string',
    'candidate build has no artifact identity');
  expect(realpathSync(build.artifactPath) === config.candidatePath,
    'candidate build artifact path differs from --candidate');
  expect(build.artifactSha256 === config.candidatePin.sha256,
    'candidate build artifact hash differs from --candidate');
  expect(typeof build.sourcePath === 'string' && typeof build.sourceSha256 === 'string',
    'candidate build has no source identity');
  expect(realpathSync(build.sourcePath) === config.sourcePath,
    'candidate build source path differs from --source');
  expect(build.sourceSha256 === config.sourcePin.sha256,
    'candidate build source hash differs from --source');
  let provenance = null;
  if (typeof build.provenancePath === 'string' && build.provenancePath !== '') {
    const real = realpathSync(build.provenancePath);
    provenance = {
      path: real,
      sha256: hashFile(real),
      declaredProvenanceSha256: typeof build.provenanceSha256 === 'string' ? build.provenanceSha256 : null,
    };
  }
  return {
    path: pin.path,
    bytes: pin.bytes,
    sha256: pin.sha256,
    status: build.status,
    checkedOutputRetention: build.checkedOutputRetention,
    guardianStatus: build.guardian.status,
    artifact: {path: config.candidatePath, sha256: config.candidatePin.sha256},
    source: {path: config.sourcePath, sha256: config.sourcePin.sha256},
    provenance,
  };
}

const HARNESS_MODULE_LABELS = [
  ['native_seed_runtime', 'evals/native_seed_runtime.mjs'],
  ['candidate_host', 'evals/candidate_host.ts'],
  ['heavy_gate', 'evals/heavy_gate.ts'],
  ['stage_helper', 'evals/compiler_stage_profile.mjs'],
  ['collector', 'evals/compiler_profile.mjs'],
  ['overhead_harness', 'evals/compiler_profile_overhead.ts'],
];

function harnessModules() {
  const rows = HARNESS_MODULE_LABELS.map(([label, relative]) => {
    const path = realpathSync(join(REPO_ROOT, relative));
    return {label, path, sha256: hashFile(path)};
  });
  const names = new Set(rows.map(row => row.path));
  expect(names.size === rows.length, 'harness module pin paths are not unique');
  return rows;
}

function sourceClosure(config) {
  return workloadRows(config.sourcePath, config.target);
}

function closureDigest(closure) {
  return sha256(JSON.stringify({
    sources: closure.sources.map(row => [row.path, row.sha256, row.namespace]),
    externals: closure.externals.map(row => [row.path, row.sha256]),
  }));
}

function pinSnapshot(config, closure, modules) {
  const map = new Map();
  const add = path => {
    const real = realpathSync(path);
    if (!statSync(real).isFile()) throw Error('pinned input is not a regular file: ' + real);
    map.set(real, hashFile(real));
  };
  for (const row of closure.sources) map.set(row.file, row.sha256);
  for (const row of closure.externals) map.set(row.file, row.sha256);
  add(config.sourcePath);
  add(config.candidatePath);
  add(config.parserPath);
  add(config.basePath);
  if (config.runtimeCPath !== null) add(config.runtimeCPath);
  if (config.candidateBuildPath !== null) add(config.candidateBuildPath);
  if (config.candidateBuild !== null && config.candidateBuild.provenance !== null)
    add(config.candidateBuild.provenance.path);
  for (const row of modules) add(row.path);
  add(config.workerPath);
  return map;
}

function pinDigest(map) {
  const entries = [...map.entries()]
    .map(([path, digest]) => [path, digest])
    .sort((left, right) => left[0].localeCompare(right[0]));
  return sha256(JSON.stringify(entries));
}

function pinDifference(expected, actual) {
  const problems = [];
  for (const [path, digest] of expected)
    if (!actual.has(path)) problems.push('missing ' + path);
    else if (actual.get(path) !== digest) problems.push('changed ' + path);
  for (const path of actual.keys())
    if (!expected.has(path)) problems.push('added ' + path);
  return problems;
}

function expectSamePins(expected, actual, context) {
  const problems = pinDifference(expected, actual);
  if (problems.length > 0)
    throw Error('input drift ' + context + ' (' + problems.length + '): ' +
      problems.slice(0, 8).join('; ') + (problems.length > 8 ? '; ...' : ''));
}

function parseGuardian(stderr, planned) {
  const lines = stderr.split('\n').filter(line => line.startsWith('HEAVY_GATE '));
  expect(lines.length === 1, 'expected exactly one HEAVY_GATE receipt, observed ' + lines.length);
  let record;
  try {
    record = JSON.parse(lines[0].slice('HEAVY_GATE '.length));
  } catch (error) {
    throw Error('HEAVY_GATE receipt is not JSON: ' + errorText(error));
  }
  expect(record !== null && typeof record === 'object' && !Array.isArray(record),
    'HEAVY_GATE receipt is not an object');
  expect(JSON.stringify(record.command) === JSON.stringify(planned.command),
    'guardian command receipt differs from the executed argv');
  expect(record.reportPhase === 'complete', 'guardian receipt is incomplete (reportPhase=' + record.reportPhase + ')');
  expect(record.ownedTreeStopped === true, 'guardian did not confirm the owned tree stopped');
  expect(record.memoryLimitBytes === planned.limits.memoryMiB * MiB,
    'guardian footprint limit differs from the explicit request');
  expect(record.rssLimitBytes === planned.limits.rssMiB * MiB,
    'guardian RSS limit differs from the explicit request');
  expect(record.timeoutMs === planned.limits.timeoutMs,
    'guardian deadline differs from the explicit request');
  expect(record.status !== 'LOCK_BUSY', 'heavy-gate exclusive lock is busy');
  expect(record.status !== 'RESOURCE_LIMIT',
    'heavy gate enforced a resource limit: ' + String(record.reason));
  expect(record.reason === 'command_exit',
    'guardian reason is not a clean command exit: ' + String(record.reason));
  return record;
}

function parseTimeReceipt(text) {
  const lines = text.split('\n');
  const last = pattern => {
    let value = null;
    for (const line of lines) {
      const match = pattern.exec(line);
      if (match !== null) value = match;
    }
    return value;
  };
  const real = last(/^real\s+([0-9]+(?:\.[0-9]+)?)\s*$/);
  const user = last(/^user\s+([0-9]+(?:\.[0-9]+)?)\s*$/);
  const system = last(/^sys\s+([0-9]+(?:\.[0-9]+)?)\s*$/);
  const maxRss = last(/^\s*([0-9]+)\s+maximum resident set size\s*$/);
  const footprint = last(/^\s*([0-9]+)\s+peak memory footprint\s*$/);
  expect(real !== null && user !== null && system !== null && maxRss !== null,
    'missing a complete /usr/bin/time -lp wait4 receipt');
  return {
    source: '/usr/bin/time -lp (Darwin wait4 rusage of the Node child)',
    realMs: Number(real[1]) * 1000,
    userMs: Number(user[1]) * 1000,
    systemMs: Number(system[1]) * 1000,
    maxRssBytes: Number(maxRss[1]),
    peakFootprintBytes: footprint === null ? null : Number(footprint[1]),
    resolutionMs: 10,
  };
}

function candidateDiagnostics(stderr) {
  return stderr.split('\n')
    .filter(line => line.startsWith('candidate: '))
    .map(line => line.length > 4096 ? line.slice(0, 4096) + '[truncated]' : line);
}

function planLeg(config, legDirectory, kind) {
  const outputPath = join(legDirectory, config.target === 'c' ? 'out.c' : 'out.js');
  const profileDirectory = kind === 'on' ? join(legDirectory, 'profile') : null;
  const hostArgv = ['--candidate=' + config.candidatePath];
  if (config.candidateBuildPath !== null)
    hostArgv.push('--candidate-build=' + config.candidateBuildPath);
  if (config.parserSeparate) hostArgv.push('--parser=' + config.parserPath);
  hostArgv.push('--base=' + config.basePath);
  if (config.library) {
    hostArgv.push('--library');
    hostArgv.push('--exports=' + config.exportArg);
  }
  if (config.target === 'c') hostArgv.push('--runtime-c=' + config.runtimeCPath);
  if (profileDirectory !== null) hostArgv.push('--stage-profile=' + profileDirectory);
  hostArgv.push(config.sourcePath, '-o', outputPath);
  const command = [config.node.path, '--experimental-strip-types', config.workerPath,
    config.candidateHostPath, ...hostArgv];
  const timedCommand = [TIME.path, ...TIME.args, ...command];
  const gateArgv = [config.bun.path, config.heavyGatePath,
    '--memory-mib', String(config.limits.memoryMiB),
    '--rss-mib', String(config.limits.rssMiB),
    '--poll-ms', String(config.limits.pollMs),
    '--term-grace-ms', String(config.limits.termGraceMs),
    '--timeout-ms', String(config.limits.timeoutMs),
    '--', ...timedCommand];
  return {
    legDirectory,
    outputPath,
    profileDirectory,
    hostArgv,
    command,
    timedCommand,
    gateArgv,
    stdoutPath: join(legDirectory, 'child.stdout.log'),
    stderrPath: join(legDirectory, 'child.stderr.log'),
  };
}

function validateProfile(config, plan, expectFailure) {
  const directory = plan.profileDirectory;
  expect(existsSync(directory), 'on leg produced no collector profile directory: ' + directory);
  const entries = readdirSync(directory, {withFileTypes: true})
    .filter(entry => entry.isDirectory() && entry.name.startsWith('profile-'));
  expect(entries.length === 1,
    'expected exactly one collector run under the leg profile directory, observed ' + entries.length);
  const runDirectory = join(directory, entries[0].name);
  const summaryPath = join(runDirectory, 'summary.json');
  expect(existsSync(summaryPath), 'collector run has no summary.json');
  const summaryPin = pinFile(summaryPath);
  const summary = JSON.parse(readFileSync(summaryPin.path, 'utf8'));
  expect(summary !== null && typeof summary === 'object' && !Array.isArray(summary),
    'collector summary is not an object');
  expect(summary.kind === 'compiler-profile', 'collector summary kind differs');
  expect(summary.schemaVersion === 1, 'collector summary schemaVersion differs');
  expect(summary.diagnosticOnly === true && summary.acceptanceEvidence === false,
    'collector summary is not marked diagnostic-only');
  expect(summary.measurementStatus === 'complete',
    'collector profile is incomplete (measurementStatus=' + summary.measurementStatus + ')');
  expect(summary.incompleteEvidence === false, 'collector profile carries incomplete evidence');
  expect(summary.summary != null && summary.summary.unclosedSpans != null &&
    summary.summary.unclosedSpans.count === 0, 'collector profile has unclosed spans');
  expect(summary.run != null && summary.run.rawDetail === false,
    'collector profile unexpectedly retains raw detail');
  expect(summary.sampling != null && summary.sampling.config === null &&
    summary.sampling.status === 'disabled', 'collector profile enabled sampling');
  if (expectFailure) {
    expect(summary.status === 'failed' && summary.workloadStatus === 'failed',
      'negative-control profile status is not failed');
    expect(typeof summary.error === 'string' && summary.error.length > 0,
      'negative-control profile carries no error');
  } else {
    expect(summary.status === 'completed' && summary.workloadStatus === 'completed',
      'profile status is not completed');
    expect(summary.error === null, 'completed profile carries an error');
  }
  const execution = summary.execution;
  expect(execution != null && typeof execution === 'object' && !Array.isArray(execution),
    'profile has no execution identity');
  expect(execution.stage === 'selfhost-candidate' && execution.mode === 'typed-step',
    'profile execution identity differs');
  expect(execution.target === config.target, 'profile target differs');
  expect(execution.sourcePath === config.sourcePath &&
    execution.sourceSha256 === config.sourcePin.sha256,
    'profile source identity differs from the pin');
  expect(execution.candidatePath === config.candidatePath &&
    execution.candidateSha256 === config.candidatePin.sha256,
    'profile candidate identity differs from the pin');
  expect(execution.parserPath === config.parserPath &&
    execution.parserSha256 === config.parserPin.sha256,
    'profile parser identity differs from the pin');
  expect(execution.basePath === config.basePath &&
    execution.baseSha256 === config.basePin.sha256,
    'profile base identity differs from the pin');
  expect(execution.outputPath === plan.outputPath, 'profile output path differs');
  expect(execution.library === config.library, 'profile library flag differs');
  expect(JSON.stringify(execution.exports ?? null) ===
    JSON.stringify(config.library ? config.exports : null), 'profile export set differs');
  const commandNamesProfile = Array.isArray(execution.command) &&
    execution.command.includes('--stage-profile=' + plan.profileDirectory);
  const sources = execution.profileSources;
  expect(sources != null && typeof sources === 'object' && !Array.isArray(sources),
    'profile has no source provenance');
  for (const [key, path] of [
    ['executingScript', config.candidateHostPath],
    ['stageHelper', config.stageHelperPath],
    ['collector', config.collectorPath],
  ]) {
    const row = sources[key];
    expect(row != null && typeof row.path === 'string',
      'profile provenance is missing or malformed for ' + key);
    expect(realpathSync(row.path) === path, 'profile provenance ' + key + ' path differs');
    expect(row.sha256 === hashFile(path), 'profile provenance ' + key + ' hash differs');
  }
  expect(Array.isArray(summary.observations), 'profile observations are not an array');
  const identity = summary.observations.find(row => row.name === 'stage-profile-identity');
  expect(identity !== undefined, 'profile lacks stage-profile-identity');
  expect(identity.details != null && identity.details.parentProfile != null &&
    identity.details.parentProfile.status === 'absent',
    'profile unexpectedly declares or discovers an enclosing profile');
  const collectorId = summary.observations.find(row => row.name === 'collector-profile-id');
  expect(collectorId !== undefined && collectorId.values != null &&
    collectorId.values.profileId === summary.profileId,
    'collector profileId link is absent or differs');
  expect(typeof summary.profileId === 'string' && summary.profileId.length > 0,
    'profile has no profileId');
  const realRun = realpathSync(runDirectory);
  const realParent = realpathSync(directory);
  expect(realRun.startsWith(realParent + '/'), 'profile run directory escaped its leg directory');
  return {
    diagnosticOnly: true,
    acceptanceEvidence: false,
    runDirectory,
    summaryPath: summaryPin.path,
    summaryBytes: summaryPin.bytes,
    summarySha256: summaryPin.sha256,
    profileId: summary.profileId,
    status: summary.status,
    workloadStatus: summary.workloadStatus,
    measurementStatus: summary.measurementStatus,
    incompleteEvidence: summary.incompleteEvidence,
    runWallMs: summary.run.wallMs,
    spanCount: summary.summary.spanCount,
    observationCount: summary.summary.observationCount,
    sampling: {config: summary.sampling.config, status: summary.sampling.status},
    identity: summary.identity,
    execution: {
      sourceSha256: execution.sourceSha256,
      candidateSha256: execution.candidateSha256,
      parserSha256: execution.parserSha256,
      baseSha256: execution.baseSha256,
      outputPath: execution.outputPath,
      library: execution.library,
      exports: execution.exports ?? null,
      target: execution.target,
      command: execution.command,
      commandNamesProfile,
    },
    profileSources: sources,
    parentProfileStatus: identity.details.parentProfile.status,
  };
}

function executeLeg(config, leg, plan) {
  const closureBefore = sourceClosure(config);
  const closureDigestBefore = closureDigest(closureBefore);
  const pinsBefore = pinSnapshot(config, closureBefore, config.modules);
  expectSamePins(config.initialPins, pinsBefore, 'before ' + leg.label);
  leg.pins.beforeDigest = pinDigest(pinsBefore);
  leg.pins.beforeEntries = pinsBefore.size;
  leg.pins.closureDigestBefore = closureDigestBefore;

  const outFd = openSync(plan.stdoutPath, 'wx', 0o644);
  let errFd;
  try {
    errFd = openSync(plan.stderrPath, 'wx', 0o644);
  } catch (error) {
    closeSync(outFd);
    throw error;
  }
  const started = Date.now();
  let run;
  try {
    run = spawnSync(plan.gateArgv[0], plan.gateArgv.slice(1), {
      cwd: REPO_ROOT,
      env: config.childEnv,
      stdio: ['ignore', outFd, errFd],
      timeout: config.launcherTimeoutMs,
      killSignal: 'SIGKILL',
    });
  } finally {
    closeSync(outFd);
    closeSync(errFd);
  }
  leg.launcherMs = Date.now() - started;
  if (run.error) throw Error('heavy-gate launcher failed: ' + errorText(run.error));

  const stdoutText = readFileSync(plan.stdoutPath, 'utf8');
  const stderrText = readFileSync(plan.stderrPath, 'utf8');
  leg.logs = {
    stdout: pinFile(plan.stdoutPath),
    stderr: pinFile(plan.stderrPath),
  };
  leg.diagnostics.candidateLines = candidateDiagnostics(stderrText);

  const guardian = parseGuardian(stderrText, {
    command: plan.timedCommand,
    limits: config.limits,
  });
  expect(run.status === guardian.exitCode,
    'launcher exit ' + String(run.status) + ' differs from guardian exitCode ' + String(guardian.exitCode));
  expect(guardian.supervisorExitCode === run.status,
    'guardian supervisorExitCode differs from the launcher exit');
  if (config.expectFailure) {
    expect(guardian.status === 'FAIL', 'negative-control leg did not fail');
    expect(guardian.commandExitCode !== 0, 'negative-control leg exited zero');
    expect(guardian.commandSignal === 0, 'negative-control leg was terminated by a signal');
  } else {
    expect(guardian.status === 'PASS', 'guardian status is ' + guardian.status + ': ' + guardian.reason);
    expect(guardian.commandExitCode === 0, 'successful leg command exited nonzero');
    expect(guardian.commandSignal === 0, 'successful leg was terminated by a signal');
  }
  leg.guardian = {
    status: guardian.status,
    reason: guardian.reason,
    reportPhase: guardian.reportPhase,
    ownedTreeStopped: guardian.ownedTreeStopped,
    supervisorExitCode: guardian.supervisorExitCode,
    exitCode: guardian.exitCode,
    commandExitCode: guardian.commandExitCode,
    commandSignal: guardian.commandSignal,
    elapsedMs: guardian.elapsedMs,
    peakRssBytes: guardian.peakRssBytes,
    peakFootprintBytes: guardian.peakFootprintBytes,
    memoryLimitBytes: guardian.memoryLimitBytes,
    rssLimitBytes: guardian.rssLimitBytes,
    timeoutMs: guardian.timeoutMs,
    reportPath: guardian.reportPath,
  };
  leg.diagnostics.exitCode = guardian.commandExitCode;
  leg.diagnostics.signal = guardian.commandSignal;

  const timeReceipt = parseTimeReceipt(stderrText);
  leg.timeReceipt = timeReceipt;

  if (!config.expectFailure) {
    const stdoutLines = stdoutText.split('\n').map(line => line.trim()).filter(Boolean);
    expect(stdoutLines.length > 0, 'candidate printed no result on a successful leg');
    const tail = stdoutLines[stdoutLines.length - 1];
    let result;
    try {
      result = JSON.parse(tail);
    } catch (error) {
      throw Error('candidate stdout tail is not a JSON result: ' + errorText(error));
    }
    expect(result !== null && typeof result === 'object' && !Array.isArray(result),
      'candidate result is not an object');
    expect(result.output === plan.outputPath, 'candidate result output path differs from -o');
    expect(existsSync(plan.outputPath), 'candidate reported success but wrote no output');
    const outputPin = pinFile(plan.outputPath);
    expect(result.sha256 === outputPin.sha256, 'candidate result sha256 differs from the output bytes');
    expect(result.bytes === outputPin.bytes, 'candidate result bytes differ from the output size');
    expect(result.target === config.target, 'candidate result target differs');
    expect(result.library === config.library, 'candidate result library flag differs');
    if (config.library)
      expect(JSON.stringify(result.exports) === JSON.stringify(config.exports),
        'candidate result export set differs from --exports');
    else
      expect(result.exports === undefined, 'whole-module candidate result reports exports');
    expect(Number.isSafeInteger(result.modules) && result.modules > 0,
      'candidate result module count is missing');
    leg.candidate = {
      output: result.output,
      sha256: result.sha256,
      bytes: result.bytes,
      target: result.target,
      library: result.library,
      exports: result.exports ?? null,
      modules: result.modules,
      foreignFiles: result.foreignFiles,
      runtime: result.runtime ?? null,
      stageProfile: result.stageProfile ?? null,
    };
    leg.output = {path: plan.outputPath, exists: true, bytes: outputPin.bytes, sha256: outputPin.sha256};
    if (plan.profileDirectory === null) {
      expect(result.stageProfile === undefined, 'off leg unexpectedly reported a stage profile');
    } else {
      expect(typeof result.stageProfile === 'string', 'on leg result carries no stageProfile');
      const profile = validateProfile(config, plan, false);
      expect(realpathSync(result.stageProfile) === profile.summaryPath,
        'candidate result stageProfile differs from the collector summary');
      leg.profile = profile;
    }
  } else {
    expect(leg.diagnostics.candidateLines.length > 0,
      'failing leg produced no candidate diagnostic line');
    if (existsSync(plan.outputPath)) {
      const outputPin = pinFile(plan.outputPath);
      leg.output = {path: plan.outputPath, exists: true, bytes: outputPin.bytes, sha256: outputPin.sha256};
    } else {
      leg.output = {path: plan.outputPath, exists: false, bytes: null, sha256: null};
    }
    if (plan.profileDirectory !== null)
      leg.profile = validateProfile(config, plan, true);
    else
      expect(!existsSync(join(plan.legDirectory, 'profile')),
        'off leg produced a profile directory');
  }

  const closureAfter = sourceClosure(config);
  const closureDigestAfter = closureDigest(closureAfter);
  const pinsAfter = pinSnapshot(config, closureAfter, config.modules);
  expectSamePins(pinsBefore, pinsAfter, 'after ' + leg.label);
  expectSamePins(config.initialPins, pinsAfter, 'between legs at ' + leg.label);
  expect(closureDigestAfter === closureDigestBefore, 'source closure digest changed during ' + leg.label);
  leg.pins.afterDigest = pinDigest(pinsAfter);
  leg.pins.afterEntries = pinsAfter.size;
  leg.pins.closureDigestAfter = closureDigestAfter;
  leg.pins.abiDigest = config.abiDigest;
  leg.abi = {exports: ABI.slice(), digest: config.abiDigest};
}

function median(values) {
  const sorted = values.slice().sort((left, right) => left - right);
  const middle = sorted.length >> 1;
  return sorted.length % 2 === 1
    ? sorted[middle]
    : (sorted[middle - 1] + sorted[middle]) / 2;
}

function metricStats(legs, read) {
  const values = legs.map(read);
  const defined = values.filter(value => typeof value === 'number' && Number.isFinite(value));
  if (defined.length === 0) return {count: 0, values, median: null, min: null, max: null, range: null, missing: values.length};
  const sorted = defined.slice().sort((left, right) => left - right);
  return {
    count: defined.length,
    values,
    median: median(defined),
    min: sorted[0],
    max: sorted[sorted.length - 1],
    range: sorted[sorted.length - 1] - sorted[0],
    missing: values.length - defined.length,
  };
}

function buildSummary(legs) {
  const metrics = [
    ['wallMs', leg => leg.timeReceipt.realMs],
    ['userMs', leg => leg.timeReceipt.userMs],
    ['systemMs', leg => leg.timeReceipt.systemMs],
    ['cpuMs', leg => leg.timeReceipt.userMs + leg.timeReceipt.systemMs],
    ['childMaxRssBytes', leg => leg.timeReceipt.maxRssBytes],
    ['childPeakFootprintBytes', leg => leg.timeReceipt.peakFootprintBytes],
    ['guardianElapsedMs', leg => leg.guardian.elapsedMs],
    ['guardianPeakRssBytes', leg => leg.guardian.peakRssBytes],
    ['guardianPeakFootprintBytes', leg => leg.guardian.peakFootprintBytes],
  ];
  const off = legs.filter(leg => leg.kind === 'off');
  const on = legs.filter(leg => leg.kind === 'on');
  const perKind = {off: {}, on: {}};
  const comparison = {};
  for (const [name, read] of metrics) {
    perKind.off[name] = metricStats(off, read);
    perKind.on[name] = metricStats(on, read);
    const offMedian = perKind.off[name].median;
    const onMedian = perKind.on[name].median;
    const defined = typeof offMedian === 'number' && typeof onMedian === 'number';
    comparison[name] = {
      offMedian,
      onMedian,
      delta: defined ? onMedian - offMedian : null,
      ratio: defined && offMedian !== 0 ? onMedian / offMedian : null,
      percentDelta: defined && offMedian !== 0 ? (onMedian / offMedian - 1) * 100 : null,
    };
  }
  return {
    diagnosticOnly: true,
    acceptanceEvidence: false,
    samples: {pairs: legs.length / 2, legs: legs.length, off: off.length, on: on.length},
    perKind,
    comparison,
    resolution: 'wall/user/system from 0.01 s Darwin time -lp receipts; medians over the executed alternating legs',
  };
}

function main() {
  const initialCwd = process.cwd();
  let options;
  try {
    options = parseOptions(process.argv.slice(2));
  } catch (error) {
    console.error('compiler_profile_overhead: ' + errorText(error) + '\n\n' + usage());
    process.exitCode = 2;
    return;
  }
  if (options.help) {
    console.log(usage());
    return;
  }
  const reportPath = isAbsolute(options.report) ? options.report : resolve(initialCwd, options.report);
  if (existsSync(reportPath)) {
    console.error('compiler_profile_overhead: report path already exists: ' + reportPath);
    process.exitCode = 2;
    return;
  }
  let reportParent;
  try {
    reportParent = statSync(dirname(reportPath));
  } catch (error) {
    console.error('compiler_profile_overhead: report parent is not readable: ' + errorText(error));
    process.exitCode = 2;
    return;
  }
  if (!reportParent.isDirectory()) {
    console.error('compiler_profile_overhead: report parent is not a directory: ' + dirname(reportPath));
    process.exitCode = 2;
    return;
  }
  const reportFd = openSync(reportPath, 'wx', 0o644);
  const report = {
    schemaVersion: 1,
    kind: 'compiler-profile-overhead-diagnostic',
    status: 'FAIL',
    diagnosticOnly: true,
    acceptanceEvidence: false,
    label: options.label,
    createdAt: new Date().toISOString(),
    finishedAt: null,
    scope: [
      'Operational alternating comparison of the candidate_host.ts typed-step path without profiling (off) and with only the existing --stage-profile createStageProfile option (on), on one pinned image and one pinned full source closure.',
      'Every leg is one exclusive heavy_gate.ts invocation with explicit identical limits. Off legs import no collector; on legs never replace collection with the harness CPU sampler.',
      'Child wall/user/system CPU and maximum RSS are the Darwin /usr/bin/time -lp wait4 receipt of the Node child. Guardian peak RSS and physical footprint are separate heavy-gate samples of the owned process tree.',
      'time -lp reports seconds to 0.01 s. Alternating samples on one machine are operational intervals, not isolated instrumentation cost, exclusive CPU share or per-span attribution.',
      'No reruns, retries or fallback limits. Failures abort the run; emitted sources are never patched and never executed by this harness.',
    ],
    nonClaims: [
      'Not acceptance, bootstrap, byte-fixedpoint or benchmark evidence; every record is diagnosticOnly with acceptanceEvidence false.',
      'No per-group memory/allocation and no isolated per-request or per-provider CPU is claimed.',
      'Collector profiles are validated and hashed only; their span contents are not summarized as overhead here.',
      'A larger explicit timeout or different memory limit is a diagnostic setting, never acceptance.',
    ],
    runtime: {
      harness: {
        execPath: process.execPath,
        versions: process.versions,
        argv: process.argv.slice(),
        initialCwd,
        repoRoot: REPO_ROOT,
        platform: process.platform,
        arch: process.arch,
      },
      node: null,
      bun: null,
      time: {path: TIME.path, args: TIME.args.slice(), receipt: 'Darwin wait4 rusage and peak RSS via /usr/bin/time -lp'},
    },
    paths: {
      report: reportPath,
      initialCwd,
      repoRoot: REPO_ROOT,
      workRoot: null,
      source: null,
      candidate: null,
      parser: null,
      parserSeparate: null,
      base: null,
      runtimeC: null,
      candidateBuild: null,
      candidateBuildProvenance: null,
      worker: null,
      node: null,
      bun: null,
      heavyGate: null,
      candidateHost: null,
      stageHelper: null,
      collector: null,
    },
    limits: {
      requested: null,
      acceptance: {...ACCEPTANCE_LIMITS},
      acceptanceTimeoutMs: ACCEPTANCE_LIMITS.timeoutMs,
      extendedTimeout: options.timeoutMs > ACCEPTANCE_LIMITS.timeoutMs,
      termGraceMs: TERM_GRACE_MS,
      matchesAcceptance: options.memoryMiB === ACCEPTANCE_LIMITS.memoryMiB &&
        options.rssMiB === ACCEPTANCE_LIMITS.rssMiB &&
        options.timeoutMs === ACCEPTANCE_LIMITS.timeoutMs,
    },
    abi: null,
    pins: {
      closure: null,
      harness: null,
      candidateBuild: null,
      worker: null,
      initialDigest: null,
      initialEntries: null,
    },
    environment: null,
    order: [],
    pairs: options.pairs,
    legs: [],
    checks: {
      platformDarwin: false,
      abi13: false,
      reportFresh: true,
      initialPins: false,
      pinsStable: false,
      guardianContract: false,
      legArgumentsEquivalent: false,
      legOrderAlternates: false,
      modeConsistent: false,
      outputsByteIdentical: false,
      diagnosticsEqual: false,
      profilesComplete: false,
    },
    summary: null,
    error: null,
    failedAt: null,
  };
  let failure = null;
  let phase = 'prepare';
  try {
    phase = 'prepare';
    expect(process.platform === 'darwin', 'this harness requires Darwin /usr/bin/time -lp wait4 receipts');
    report.checks.platformDarwin = true;
    expect(typeof TIME.path === 'string' && existsSync(TIME.path),
      '/usr/bin/time is unavailable');
    expect(Array.isArray(ABI) && ABI.length === 13 && new Set(ABI).size === 13,
      'the accepted exported ABI is not the 13-entry contract');
    report.checks.abi13 = true;
    process.chdir(REPO_ROOT);

    const config = resolveConfig(options, initialCwd, reportPath);
    config.childEnv = {...process.env};
    delete config.childEnv.SELFHOST_STAGE_PARENT;
    delete config.childEnv.SELFHOST_STAGE_PROFILE_DIR;
    delete config.childEnv.SELFHOST_STAGE_PROGRESS;
    config.launcherTimeoutMs = Math.min(2147483647, config.limits.timeoutMs + 300000);
    report.environment = {
      strippedVariables: ['SELFHOST_STAGE_PARENT', 'SELFHOST_STAGE_PROFILE_DIR', 'SELFHOST_STAGE_PROGRESS'],
      heavyGateVariables: Object.keys(config.childEnv).filter(key => key.startsWith('HEAVY_GATE_')).sort(),
      kind: 'environment passed to every heavy-gate invocation',
    };
    report.paths = {
      ...report.paths,
      source: config.sourcePath,
      candidate: config.candidatePath,
      parser: config.parserPath,
      parserSeparate: config.parserSeparate,
      base: config.basePath,
      runtimeC: config.runtimeCPath,
      candidateBuild: config.candidateBuildPath,
    };
    report.limits.requested = {
      memoryMiB: config.limits.memoryMiB,
      rssMiB: config.limits.rssMiB,
      pollMs: config.limits.pollMs,
      termGraceMs: config.limits.termGraceMs,
      timeoutMs: config.limits.timeoutMs,
      footprintLimitBytes: config.limits.memoryMiB * MiB,
      rssLimitBytes: config.limits.rssMiB * MiB,
    };

    const node = resolveExecutable(options.node, '--node', initialCwd);
    const bun = resolveExecutable(options.bun, '--bun', initialCwd);
    config.node = node;
    config.bun = bun;
    report.runtime.node = node;
    report.runtime.bun = bun;

    const heavyGatePath = realpathSync(join(REPO_ROOT, 'evals/heavy_gate.ts'));
    const candidateHostPath = realpathSync(join(REPO_ROOT, 'evals/candidate_host.ts'));
    const stageHelperPath = realpathSync(join(REPO_ROOT, 'evals/compiler_stage_profile.mjs'));
    const collectorPath = realpathSync(join(REPO_ROOT, 'evals/compiler_profile.mjs'));
    config.heavyGatePath = heavyGatePath;
    config.candidateHostPath = candidateHostPath;
    config.stageHelperPath = stageHelperPath;
    config.collectorPath = collectorPath;
    report.paths = {...report.paths, heavyGate: heavyGatePath, candidateHost: candidateHostPath,
      stageHelper: stageHelperPath, collector: collectorPath, node: node.path, bun: bun.path};

    let workRoot;
    if (config.workDirectory === null) {
      workRoot = mkdtempSync(join(tmpdir(), 'bend2039g7-profile-overhead-'));
    } else {
      if (existsSync(config.workDirectory))
        throw Error('--work-directory must not exist: ' + config.workDirectory);
      mkdirSync(config.workDirectory);
      workRoot = config.workDirectory;
    }
    config.workRoot = workRoot;
    report.paths.workRoot = workRoot;

    let workerPath;
    let workerOrigin;
    if (config.workerOverride !== null) {
      workerPath = config.workerOverride;
      workerOrigin = 'caller-supplied';
      const text = readFileSync(workerPath, 'utf8');
      expect(new RegExp('stackSizeMb\\s*:\\s*' + ADAPTER_STACK_MIB).test(text),
        'caller worker does not declare a ' + ADAPTER_STACK_MIB + ' MiB worker stack');
      expect(new RegExp('maxOldGenerationSizeMb\\s*:\\s*' + ADAPTER_OLD_GENERATION_MIB).test(text),
        'caller worker does not declare a ' + ADAPTER_OLD_GENERATION_MIB + ' MiB old generation');
    } else {
      workerPath = join(workRoot, 'candidate-worker.mjs');
      writeFileSync(workerPath, ADAPTER_SOURCE, {flag: 'wx', mode: 0o644});
      workerOrigin = 'generated from the established adapter contract';
    }
    const workerPin = pinFile(workerPath);
    config.workerPath = workerPin.path;
    report.paths.worker = workerPin.path;
    report.pins.worker = {
      path: workerPin.path,
      bytes: workerPin.bytes,
      sha256: workerPin.sha256,
      origin: workerOrigin,
      contract: {stackSizeMb: ADAPTER_STACK_MIB, maxOldGenerationSizeMb: ADAPTER_OLD_GENERATION_MIB},
      reference: 'evals/compiler_profile_overhead.ts embedded contract; matches /tmp/bend2039-candidate-worker.mjs',
    };

    config.candidateBuild = inspectCandidateBuild(config);
    report.pins.candidateBuild = config.candidateBuild;
    report.paths.candidateBuildProvenance = config.candidateBuild === null || config.candidateBuild.provenance === null
      ? null
      : config.candidateBuild.provenance.path;

    const modules = harnessModules();
    config.modules = modules;
    report.pins.harness = {modules};
    const abiModule = modules.find(row => row.label === 'native_seed_runtime');
    config.abiDigest = sha256(JSON.stringify(ABI));
    report.abi = {
      exports: ABI.slice(),
      count: ABI.length,
      digest: config.abiDigest,
      module: {path: abiModule.path, sha256: abiModule.sha256},
      note: 'passed as the default emitted-library export set; custom --exports is recorded per run',
    };

    phase = 'initial-pins';
    const closure = sourceClosure(config);
    config.initialPins = pinSnapshot(config, closure, modules);
    report.pins.closure = {
      root: config.sourcePath,
      directory: closure.directory,
      target: config.target,
      sources: closure.sources.map(row => ({path: row.path, sha256: row.sha256, namespace: row.namespace})),
      externals: closure.externals.map(row => ({path: row.path, sha256: row.sha256})),
      digest: closureDigest(closure),
    };
    report.pins.initialDigest = pinDigest(config.initialPins);
    report.pins.initialEntries = config.initialPins.size;
    report.checks.initialPins = true;

    for (let pair = 1; pair <= config.pairs; pair += 1) {
      const kinds = pair % 2 === 1 ? ['off', 'on'] : ['on', 'off'];
      for (const kind of kinds) {
        const sequence = report.legs.length + 1;
        const label = 'pair-' + pair + '-' + kind;
        phase = label;
        const legDirectory = join(workRoot, label);
        mkdirSync(legDirectory);
        const plan = planLeg(config, legDirectory, kind);
        const leg = {
          pair,
          kind,
          sequence,
          label,
          status: 'RUNNING',
          diagnosticOnly: true,
          acceptanceEvidence: false,
          directory: legDirectory,
          cwd: REPO_ROOT,
          argv: {
            gate: plan.gateArgv,
            command: plan.timedCommand,
            host: plan.hostArgv,
            node: plan.command,
          },
          output: {path: plan.outputPath, exists: false, bytes: null, sha256: null},
          candidate: null,
          guardian: null,
          timeReceipt: null,
          profile: null,
          abi: null,
          pins: {
            beforeDigest: null,
            afterDigest: null,
            beforeEntries: null,
            afterEntries: null,
            closureDigestBefore: null,
            closureDigestAfter: null,
            abiDigest: null,
          },
          diagnostics: {candidateLines: [], exitCode: null, signal: null},
          logs: null,
          launcherMs: null,
          startedAt: new Date().toISOString(),
          error: null,
        };
        report.legs.push(leg);
        report.order.push({pair, kind, sequence, label});
        try {
          executeLeg(config, leg, plan);
          leg.status = config.expectFailure ? 'EXPECTED_FAILURE' : 'PASS';
        } catch (error) {
          leg.status = 'FAIL';
          leg.error = errorText(error);
          throw error;
        }
      }
    }

    report.checks.pinsStable = true;
    report.checks.guardianContract = true;
    phase = 'cross-leg-checks';
    const legs = report.legs;
    expect(legs.length === config.pairs * 2, 'executed leg count differs from --pairs');
    const expectedOrder = [];
    for (let pair = 1; pair <= config.pairs; pair += 1)
      expectedOrder.push(...(pair % 2 === 1 ? ['off', 'on'] : ['on', 'off']));
    expect(JSON.stringify(legs.map(leg => leg.kind)) === JSON.stringify(expectedOrder),
      'leg order does not alternate off/on across pairs');
    report.checks.legOrderAlternates = true;

    const normalizedHosts = legs.map(leg =>
      leg.argv.host
        .map(argument => argument === leg.output.path ? '<output>' : argument)
        .filter(argument => !argument.startsWith('--stage-profile=')));
    expect(new Set(normalizedHosts.map(argv => JSON.stringify(argv))).size === 1,
      'leg host arguments differ beyond --stage-profile and the output path');
    expect(legs.every(leg =>
      leg.argv.host.filter(argument => argument.startsWith('--stage-profile=')).length ===
      (leg.kind === 'on' ? 1 : 0)),
    'a leg carries the wrong number of --stage-profile arguments');
    report.checks.legArgumentsEquivalent = true;

    const succeeded = legs.filter(leg => leg.guardian.commandExitCode === 0);
    if (config.expectFailure) {
      expect(succeeded.length === 0, 'negative-control run contains a successful leg');
      expect(new Set(legs.map(leg => leg.diagnostics.exitCode)).size === 1,
        'negative-control legs exited with different codes');
      const diagnostics = legs.map(leg => JSON.stringify(leg.diagnostics.candidateLines));
      expect(new Set(diagnostics).size === 1, 'negative-control host diagnostics differ across legs');
      const reasons = legs.map(leg => leg.guardian.reason);
      expect(new Set(reasons).size === 1, 'negative-control guardian reasons differ across legs');
    } else {
      expect(succeeded.length === legs.length, 'successful run contains a failed leg');
      expect(legs.every(leg => leg.diagnostics.candidateLines.length === 0),
        'a successful leg produced candidate diagnostic lines');
      const identities = legs.map(leg => JSON.stringify({
        sha256: leg.output.sha256,
        bytes: leg.output.bytes,
        target: leg.candidate.target,
        library: leg.candidate.library,
        exports: leg.candidate.exports,
        modules: leg.candidate.modules,
        foreignFiles: leg.candidate.foreignFiles,
        runtime: leg.candidate.runtime,
      }));
      expect(new Set(identities).size === 1, 'candidate execution identity differs across legs');
      expect(new Set(legs.map(leg => leg.output.sha256)).size === 1,
        'emitted source bytes are not byte-identical across legs');
      expect(new Set(legs.map(leg => leg.output.bytes)).size === 1,
        'emitted source sizes differ across legs');
    }
    report.checks.modeConsistent = true;

    const outputPresence = new Set(legs.map(leg => leg.output.exists));
    expect(outputPresence.size === 1, 'only some legs emitted output');
    if (legs[0].output.exists) {
      expect(new Set(legs.map(leg => leg.output.sha256)).size === 1,
        'emitted source bytes are not byte-identical across legs');
      expect(new Set(legs.map(leg => leg.output.bytes)).size === 1,
        'emitted source sizes differ across legs');
      const reference = readFileSync(legs[0].output.path);
      for (const leg of legs)
        expect(readFileSync(leg.output.path).equals(reference),
          'emitted output bytes differ in ' + leg.label);
    } else if (!config.expectFailure) {
      throw Error('successful legs emitted no output');
    }
    report.checks.outputsByteIdentical = true;
    report.checks.diagnosticsEqual = true;

    if (legs.some(leg => leg.kind === 'on'))
      report.checks.profilesComplete = legs
        .filter(leg => leg.kind === 'on')
        .every(leg => leg.profile !== null && leg.profile.measurementStatus === 'complete' &&
          leg.profile.incompleteEvidence === false);

    report.summary = buildSummary(legs);
    report.status = 'PASS';
  } catch (error) {
    failure = error;
    report.error = errorText(error);
    report.failedAt = phase;
    report.status = 'FAIL';
  }
  report.finishedAt = new Date().toISOString();
  try {
    writeFileSync(reportFd, JSON.stringify(report, null, 2) + '\n');
  } finally {
    closeSync(reportFd);
  }
  console.log(JSON.stringify({
    status: report.status,
    report: reportPath,
    diagnosticOnly: true,
    acceptanceEvidence: false,
    legs: report.legs.length,
    failedAt: report.failedAt,
    error: report.error ?? undefined,
  }));
  if (failure !== null) process.exitCode = 1;
}

main();
