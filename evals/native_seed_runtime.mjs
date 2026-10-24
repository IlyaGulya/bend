import {createHash} from 'node:crypto';
import {existsSync, readFileSync, realpathSync, writeFileSync} from 'node:fs';
import {posix, resolve} from 'node:path';
import {spawnSync} from 'node:child_process';

export const ABI = ['parsed_module', 'parse_with_fuel', 'expand_modules_start', 'template_step',
  'check_expanded_start', 'inspect_checked_start', 'checker_step', 'emit_modules_start',
  'emit_library_start', 'emitter_step',
  'emit_c_modules_start', 'emit_c_library_start', 'c_emitter_step'];

export const sha = bytes => createHash('sha256').update(bytes).digest('hex');
export const hashPath = path => sha(readFileSync(path));

const importPattern = /^import\s+(\S+)(?:\s+as\s+[A-Za-z_]\w*)?\s*(?:#.*)?$/;
const foreignPattern = /^\s*import\s+"([^"]+\.js)"\s*$/;

/** Trusted host import resolution with the native host's own lexical rule. */
export function workloadRows(entryPath) {
  const root = realpathSync(entryPath);
  const directory = realpathSync('.');
  const sources = new Map(), externals = new Map();
  const scopeOf = (scope, imported) => {
    if (imported === 'Base') return '';
    const target = imported.replace(/\.bend$/, '');
    if (posix.isAbsolute(target)) return posix.normalize(target);
    const parent = posix.dirname(scope);
    return posix.normalize(parent ? parent + '/' + target : target);
  };
  const visit = (file, scope, active) => {
    const real = realpathSync(file);
    if (active.has(real)) throw Error('Native workload import cycle: ' + real);
    const known = sources.get(real);
    if (known) {
      if (known.namespace !== scope) throw Error('One native workload file imported into conflicting namespaces: ' + real);
      return;
    }
    if (!real.startsWith(directory + '/')) throw Error('Native workload input escaped the repository: ' + real);
    const text = readFileSync(real, 'utf8');
    sources.set(real, {file: real, path: real.slice(directory.length + 1), namespace: scope, sha256: sha(text)});
    active.add(real);
    for (const line of text.split('\n')) {
      const imported = importPattern.exec(line);
      if (!imported) continue;
      const target = imported[1];
      if (target.endsWith('.js')) continue;
      const child = target === 'Base' ? resolve('bend2/base.bend') : resolve(posix.dirname(real), target);
      visit(child, scopeOf(scope, target), active);
    }
    for (const match of text.matchAll(new RegExp(foreignPattern.source, 'gm'))) {
      const ext = realpathSync(resolve(posix.dirname(real), match[1]));
      if (!ext.startsWith(directory + '/')) throw Error('Declared foreign source escaped the repository: ' + ext);
      const digest = hashPath(ext);
      const prior = externals.get(ext);
      if (prior && prior.sha256 !== digest) throw Error('Declared source path resolves to different bytes: ' + ext);
      externals.set(ext, {file: ext, path: ext.slice(directory.length + 1), sha256: digest});
    }
    active.delete(real);
  };
  visit(root, '', new Set());
  return {root, directory, sources: [...sources.values()].sort((a, b) => a.path.localeCompare(b.path)), externals: [...externals.values()].sort((a, b) => a.path.localeCompare(b.path))};
}

/** The exact authenticated native workload manifest pinned by the build. */
export function corpusFor(rows) {
  return {
    schemaVersion: 1,
    directory: rows.directory,
    root: rows.root.slice(rows.directory.length + 1),
    exports: ABI,
    files: [
      ...rows.sources.map(({path, sha256, namespace}) => ({path, sha256, namespace})),
      ...rows.externals.map(({path, sha256}) => ({path, sha256, external: true})),
    ],
  };
}

export function corpusFile(rows, out) {
  if (existsSync(out)) throw Error('Use a fresh native corpus path: ' + out);
  const corpus = corpusFor(rows);
  writeFileSync(out, JSON.stringify(corpus, null, 2) + '\n', {flag: 'wx'});
  return corpus;
}

/** Rows `B|E \t namespace \t realpath` exactly as the native host reads them. */
export function runtimeManifest(corpus) {
  return corpus.files.map(row => {
    const real = realpathSync(resolve(corpus.directory, row.path));
    if (hashPath(real) !== row.sha256) throw Error('Native workload row drift: ' + real);
    return [row.external === true ? 'E' : 'B', row.external === true ? '' : row.namespace, real].join('\t');
  }).join('\n') + '\n';
}

/** Complete authentication of a native stage0 build and its workload corpus. */
export function authenticateNativeSeedBuild(reportPath, options) {
  const reportFile = realpathSync(reportPath), report = JSON.parse(readFileSync(reportFile, 'utf8'));
  const limits = options.limits;
  if (report.status !== 'NATIVE_EXECUTABLE_BUILT_NOT_YET_RUN') throw Error('Native stage0 build did not complete');
  if (report.checksExcluded !== 0 || report.outputPatches !== 0) throw Error('Native stage0 excluded checks or patched output');
  const guardian = report.guardian ?? {};
  if (guardian.status !== 'PASS' || guardian.memoryLimitBytes !== limits.memoryMiB * 1024 * 1024
    || guardian.rssLimitBytes !== limits.rssMiB * 1024 * 1024 || guardian.timeoutMs !== (limits.timeoutMs ?? 600000))
    throw Error('Native stage0 guardian contract changed');
  for (const key of ['artifact', 'artifactSha256', 'cPath', 'cSha256', 'kernelSha256', 'compilerSha256', 'source', 'sourceSha256'])
    if (typeof report[key] !== 'string' || !report[key]) throw Error('Missing native stage0 build field: ' + key);
  const binary = realpathSync(report.artifact);
  if (hashPath(binary) !== report.artifactSha256) throw Error('Native stage0 artifact identity drift');
  if (realpathSync(report.cPath) !== resolve(report.cPath) || hashPath(report.cPath) !== report.cSha256)
    throw Error('Native stage0 generated C drift');
  if (report.kernelSha256 !== hashPath(resolve('bend2/bend.ts')) || report.compilerSha256 !== hashPath(resolve('bend2/comp.ts')))
    throw Error('Native stage0 kernel/compiler identity drift');
  if (realpathSync(report.source) !== options.root || report.sourceSha256 !== hashPath(options.root))
    throw Error('Native stage0 did not validate this exact compiler root');
  for (const key of ['checkedDefinitions', 'expectedSourceDefinitions', 'eventsFullyValidated'])
    if (!Number.isSafeInteger(report[key]) || report[key] <= 0) throw Error('Missing native stage0 body/event coverage: ' + key);
  if (report.checkedDefinitions !== report.expectedSourceDefinitions) throw Error('Native stage0 body coverage is partial');
  const pins = report.protectedPins ?? {}, loaded = report.loadedInputs ?? {};
  for (const pinset of [pins, loaded]) {
    if (!Object.keys(pinset).length) throw Error('Missing native stage0 source closure');
    for (const [path, digest] of Object.entries(pinset)) {
      if (typeof digest !== 'string' || resolve(path) !== path || realpathSync(path) !== path || hashPath(path) !== digest)
        throw Error('Native stage0 input drift: ' + path);
    }
  }
  for (const path of ['bend2/bend.ts', 'bend2/comp.ts', 'bend2/base.bend', 'evals/native_compiler_driver.bend', 'evals/native_compiler_host.c'])
    if (pins[realpathSync(resolve(path))] !== hashPath(resolve(path))) throw Error('Native stage0 requires the current ' + path);
  const corpusPath = realpathSync(options.corpusPath);
  if (pins[corpusPath] !== hashPath(corpusPath)) throw Error('Native stage0 corpus is not a protected build input');
  const corpus = JSON.parse(readFileSync(corpusPath, 'utf8'));
  if (corpus.schemaVersion !== 1 || realpathSync(corpus.directory) !== realpathSync('.')
    || resolve(corpus.directory, corpus.root) !== options.root
    || JSON.stringify(corpus.exports) !== JSON.stringify(ABI) || !Array.isArray(corpus.files) || !corpus.files.length)
    throw Error('Native stage0 corpus contract changed');
  const sources = new Map(), externals = new Map();
  for (const row of corpus.files) {
    const real = realpathSync(resolve(corpus.directory, row.path));
    if (hashPath(real) !== row.sha256) throw Error('Native stage0 corpus row drift: ' + real);
    if (row.external === true) externals.set(real, row);
    else {
      if (typeof row.namespace !== 'string' || loaded[real] !== row.sha256) throw Error('Native stage0 corpus/source closure mismatch: ' + real);
      sources.set(real, row);
    }
  }
  const closed = workloadRows(options.root);
  if (sources.size !== closed.sources.length || externals.size !== closed.externals.length)
    throw Error('Native stage0 corpus is not the complete current root closure');
  for (const row of closed.sources) if (sources.get(row.file)?.sha256 !== row.sha256 || sources.get(row.file)?.namespace !== row.namespace)
    throw Error('Native stage0 source closure differs from the current root: ' + row.file);
  for (const row of closed.externals) if (externals.get(row.file)?.sha256 !== row.sha256)
    throw Error('Native stage0 foreign closure differs from the current root: ' + row.file);
  return {reportFile, report, binary, binarySha256: report.artifactSha256, corpus, corpusPath, corpusSha256: hashPath(corpusPath),
    protectedPins: pins, loadedInputs: loaded};
}

function protocolLines(text, prefix) {
  const rows = [];
  for (const line of text.split('\n')) if (line.startsWith(prefix)) rows.push(JSON.parse(line.slice(prefix.length)));
  return rows;
}

/** Execute the authenticated native compiler over one workload root. */
export function runNativeStage0(binary, work, options) {
  if (!existsSync(binary)) throw Error('Native stage0 binary is missing');
  if (existsSync(work.output)) throw Error('Native stage0 output must be fresh: ' + work.output);
  const command = [binary, '--threads', '1', '--gpu', 'off', '--',
    work.root, work.base, work.manifest, work.exports, work.phase, work.output];
  const started = Date.now();
  const run = spawnSync(command[0], command.slice(1), {encoding: 'utf8', timeout: options.timeoutMs, killSignal: 'SIGKILL', maxBuffer: 1 << 28});
  const stderr = run.stderr ?? '', stdout = run.stdout ?? '';
  const phases = protocolLines(stderr, 'NATIVE_PHASE '), phaseStarts = protocolLines(stderr, 'NATIVE_PHASE_START '),
    fuel = protocolLines(stderr, 'NATIVE_FUEL '), begins = protocolLines(stderr, 'NATIVE_BEGIN '),
    results = protocolLines(stdout + '\n' + stderr, 'NATIVE_RESULT ');
  return {command, status: run.status, signal: run.signal, error: run.error ? String(run.error) : undefined,
    elapsedMs: Date.now() - started, stdout, stderr, phases, phaseStarts, fuel, begins, results};
}

export function requireNativeRun(run, expected) {
  const failPhase = run.phaseStarts.length ? run.phaseStarts[run.phaseStarts.length - 1].phase : 'parse';
  if (run.error) throw Error('Native stage0 execution failed: ' + run.error);
  if (run.signal || run.status !== 0) {
    const error = Error('Native stage0 rejected the input during ' + failPhase);
    error.failurePhase = failPhase;
    error.diagnostic = run.stderr;
    throw error;
  }
  if (run.begins.length !== 1 || run.begins[0].computeThreads !== 1 || run.begins[0].phaseTraceVersion !== 3)
    throw Error('Missing native stage0 runtime record');
  if (JSON.stringify(run.phaseStarts.map(row => row.phase)) !== JSON.stringify(expected.phases)
    || JSON.stringify(run.phases.map(row => row.phase)) !== JSON.stringify(expected.phases))
    throw Error('Missing ordered native stage0 phase evidence');
  if (run.fuel.length !== expected.sources) throw Error('Missing native whole-workload eager-fuel accounting');
  if (run.fuel.some(row => row.cells !== 8000000)) throw Error('Native parser fuel representation changed');
  const result = run.results[0];
  if (run.results.length !== 1 || result.result !== 'EmitSuccess' || result.modules !== expected.sources
    || !Number.isSafeInteger(result.bytes) || result.bytes <= 0) throw Error('Missing complete native emit result');
  const bytes = readFileSync(expected.output);
  if (bytes.length !== result.bytes) throw Error('Native emit result byte count mismatch');
  return {emit: result, bytes};
}
