// Closed G24 transport inventory. No repository walks, Git file lists or ambient
// output trees. Build receipts remain original authority; producer-only records
// are retained as digest commitments, not misrepresented as worker inputs.
import {createHash} from 'node:crypto';
import {closeSync, constants, fstatSync, lstatSync, openSync, readFileSync, readSync, realpathSync, statSync, writeSync} from 'node:fs';
import {dirname, isAbsolute, relative, resolve} from 'node:path';
import {isBuiltin} from 'node:module';
import {workloadRows} from './native_seed_runtime.mjs';

function identity(st) { return [st.dev, st.ino, st.mode, st.size, st.mtimeMs, st.ctimeMs]; }
function ancestors(path) {
  const rows = [];
  for (let parent = dirname(resolve(path)); ; parent = dirname(parent)) {
    const st = lstatSync(parent);
    rows.push([parent, st.dev, st.ino, st.mode]);
    if (parent === dirname(parent)) return rows;
  }
}
function transfer(path, output, expected, boundary = expected?.boundary) {
  const parents = ancestors(path), before = lstatSync(path);
  if (boundary) {
    need(within(boundary, path) && within(boundary, realpathSync(path)), 'input escaped source boundary: ' + path);
    for (const [parent, , , mode] of parents) if (within(boundary, parent))
      need((mode & constants.S_IFMT) !== constants.S_IFLNK, 'input ancestor is a symlink: ' + parent);
  }
  need(before.isFile() && !before.isSymbolicLink(), 'input replaced by non-regular file: ' + path);
  const fd = openSync(path, constants.O_RDONLY | constants.O_NOFOLLOW);
  const hash = createHash('sha256'), buffer = Buffer.allocUnsafe(1024 * 1024);
  try {
    const opened = identity(fstatSync(fd));
    need(JSON.stringify(opened) === JSON.stringify(identity(before)), 'input changed while opening: ' + path);
    if (expected) need(JSON.stringify(opened) === JSON.stringify(expected.identity)
      && JSON.stringify(parents) === JSON.stringify(expected.ancestors), 'input identity changed: ' + path);
    let bytes;
    while ((bytes = readSync(fd, buffer, 0, buffer.length, null)) !== 0) {
      hash.update(buffer.subarray(0, bytes));
      if (output !== undefined) for (let offset = 0; offset < bytes;)
        offset += writeSync(output, buffer, offset, bytes - offset);
    }
    need(JSON.stringify(identity(fstatSync(fd))) === JSON.stringify(opened)
      && JSON.stringify(identity(lstatSync(path))) === JSON.stringify(opened)
      && JSON.stringify(ancestors(path)) === JSON.stringify(parents), 'input mutated while reading: ' + path);
    const sha256 = hash.digest('hex');
    if (expected) need(sha256 === expected.sha256, 'input content changed: ' + path);
    return {sha256, identity: opened, ancestors: parents, ...(boundary ? {boundary} : {})};
  } finally { closeSync(fd); }
}
export function pinFile(path, boundary) { return transfer(path, undefined, undefined, boundary); }
export function hashFile(path) { return pinFile(path).sha256; }
export function copyPinnedInput(entry, destination) {
  const output = openSync(destination, constants.O_WRONLY | constants.O_CREAT | constants.O_EXCL | constants.O_NOFOLLOW, 0o600);
  try { transfer(entry.original, output, entry); } finally { closeSync(output); }
}
function need(ok, message) { if (!ok) throw Error(message); }
function within(root, path) { const rel = relative(root, path); return rel !== '..' && !rel.startsWith('../') && !isAbsolute(rel); }
function safeSource(path) {
  need(!/(?:^|\/)(?:\.git|\.env(?:\.[^/]*)?|\.ssh|\.aws|\.gnupg|credentials|id_rsa|id_ed25519)(?:\/|$)/i.test(path),
    'refusing sensitive snapshot input: ' + path);
  need(!lstatSync(path).isSymbolicLink() && statSync(path).isFile(), 'snapshot input is not a regular non-symlink file: ' + path);
}
export function collectWorkloadInputs(repository, roots) {
  const previous = process.cwd(), pins = new Map();
  try {
    process.chdir(repository);
    for (const root of roots) for (const target of ['c', 'js']) {
      const work = workloadRows(resolve(repository, root), target);
      for (const row of [...work.sources, ...work.externals]) {
        need(!pins.has(row.file) || pins.get(row.file) === row.sha256, 'inconsistent workload pin');
        pins.set(row.file, row.sha256);
      }
    }
  } finally { process.chdir(previous); }
  return pins;
}
function matrixRoots(repository) {
  const source = readFileSync(resolve(repository, 'evals/c_target_fixtures_run.ts'), 'utf8');
  const declaration = source.match(/\bconst fixtures = (\[[\s\S]*?\]);/);
  need(declaration, 'matrix fixture declaration is unavailable');
  // This is a deliberately closed grammar, not evaluation of the gate. The
  // accepted gate uses literal paths plus a JS-only literal-array spread. A new
  // inventory expression must be supported explicitly, never guessed or omitted.
  const paths = [];
  const grammar = declaration[1].replace(/'([^']*)'/g, (_, value) => {
    if (value === 'js') return 'JS';
    need(/^(?:evals|tests)\/[A-Za-z0-9_/-]+$/.test(value), 'unknown matrix fixture literal: ' + value);
    paths.push(value + '.bend'); return 'FILE';
  }).replace(/\s+/g, '');
  need(/^\[(?:FILE,)*FILE(?:,\.\.\.\(target===JS\?\[(?:FILE,)*FILE\]:\[\]\))?\]$/.test(grammar),
    'unsupported matrix fixture grammar; refusing partial snapshot');
  need(paths.length > 0, 'empty matrix source inventory');
  return paths;
}

export function snapshotInventory(context) {
  const repository = realpathSync(context.repository), evidence = context.evidence;
  need(evidence?.root?.path && evidence?.native?.build?.path && evidence?.native?.corpusPath
    && evidence?.fixedpoint?.report?.path, 'snapshot requires authenticated producer evidence');
  const files = new Map(), authority = new Map(), documents = new Set();
  const mappings = {repository: {original: repository, snapshot: 'repository'}};
  function add(path, target, expected, role, boundary) {
    safeSource(path);
    const captured = pinFile(path, boundary), digest = captured.sha256;
    if (path.endsWith('.bend')) need(!/^\s*import\s+["']?\//m.test(readFileSync(path, 'utf8')),
      'absolute Bend imports cannot be relocated without changing semantics: ' + path);
    need(expected === undefined || digest === expected, 'snapshot input pin drift: ' + path);
    need(!files.has(target) || files.get(target).sha256 === digest, 'snapshot destination collision: ' + target);
    files.set(target, {path: target, original: path, ...captured, role});
  }
  function source(path, expected, role = 'source') {
    path = resolve(repository, path);
    const canonical = realpathSync(path);
    if (canonical !== path) {
      need(expected !== undefined, 'unreviewed source path alias: ' + path);
      path = canonical;
    }
    for (let parent = dirname(path); within(repository, parent); parent = dirname(parent)) {
      need(!lstatSync(parent).isSymbolicLink(), 'source ancestor is a symlink: ' + parent);
      if (parent === repository) break;
    }
    need(within(repository, realpathSync(path)), 'source input outside repository: ' + path);
    add(path, 'repository/' + relative(repository, path), expected, role, repository);
  }
  function producerPin(path, expected) {
    need(isAbsolute(path) && /^[a-f0-9]{64}$/.test(expected), 'malformed producer input pin');
    safeSource(path);
    need(hashFile(path) === expected, 'producer input drift: ' + path);
    const prior = authority.get(path);
    need(!prior || prior.sha256 === expected, 'conflicting producer authority: ' + path);
    authority.set(path, {original: path, sha256: expected, bytes: statSync(path).size,
      scope: 'coordinator-authenticated producer input; not a claim of remote reauthentication'});
    // Transport every explicitly pinned source, including untracked generated
    // Bend and foreign sources. Opaque producer transports/logs are not executed
    // by consumers; their commitments stay in authority and original receipts.
    if (/\.(?:bend|ts|mjs|js|c|h)$/.test(path)) {
      if (within(repository, realpathSync(path))) source(path, expected, 'producer-source');
      else add(path, 'producer-sources/' + expected + '/' + path.split('/').at(-1), expected, 'producer-source');
    }
  }
  function pinsIn(value) {
    if (!value || typeof value !== 'object') return;
    if (!Array.isArray(value)) {
      const entries = Object.entries(value);
      if (entries.length && entries.every(([path, digest]) => isAbsolute(path) && typeof digest === 'string' && /^[a-f0-9]{64}$/.test(digest))) {
        for (const [path, digest] of entries) producerPin(path, digest);
        return;
      }
    }
    for (const child of Object.values(value)) if (child && typeof child === 'object') pinsIn(child);
  }
  function document(path, expected, provenanceExpected) {
    if (!path) return;
    safeSource(path); path = realpathSync(path);
    if (documents.has(path)) return;
    documents.add(path);
    // Only explicitly selected receipts/manifest/corpus and their provenance
    // documents are parsed. Never infer dependencies by crawling arbitrary JSON.
    need(statSync(path).size <= 16 * 1024 * 1024, 'producer receipt exceeds bounded JSON limit: ' + path);
    const digest = hashFile(path);
    add(path, 'evidence/' + digest + '.json', expected, 'original-producer-evidence');
    const value = JSON.parse(readFileSync(path, 'utf8'));
    if (provenanceExpected !== undefined) {
      const {provenanceSha256, ...payload} = value;
      need(provenanceSha256 === provenanceExpected
        && createHash('sha256').update(JSON.stringify(payload)).digest('hex') === provenanceExpected,
      'producer provenance content drift: ' + path);
    }
    pinsIn(value);
    for (const key of ['provenancePath', 'parserProvenancePath']) if (typeof value[key] === 'string') {
      const provenanceDigest = value[key.replace('Path', 'Sha256')];
      need(/^[a-f0-9]{64}$/.test(provenanceDigest ?? ''), 'missing producer provenance digest');
      document(value[key], undefined, provenanceDigest);
    }
    return value;
  }

  // The running worker has a closed operational module graph. Bun scans imports
  // without evaluating code; relative literal imports are followed, package and
  // unresolved imports are errors. Computed runtime entrypoints/data are the
  // explicit image, host worker, workload, runtime C and frozen-input roles below.
  const scanned = new Set();
  function module(path) {
    path = resolve(repository, path);
    if (scanned.has(path)) return;
    scanned.add(path); source(path, undefined, 'worker-code');
    const code = readFileSync(path, 'utf8');
    const scanner = new Bun.Transpiler({loader: path.endsWith('.ts') ? 'ts' : 'js'});
    for (const imported of [...scanner.scan(code).imports, ...scanner.scanImports(code)]) {
      if (isBuiltin(imported.path) || imported.path === 'bun') continue;
      need(imported.path.startsWith('.'), 'unlisted runtime package/absolute import: ' + imported.path);
      const dependency = resolve(dirname(path), imported.path);
      need(within(repository, dependency), 'runtime import escapes snapshot: ' + dependency);
      module(dependency);
    }
  }
  for (const file of ['evals/g24_distributed.mjs', 'evals/g24_qualification.mjs', 'evals/candidate_host.ts',
    'evals/candidate_consumer_worker.mjs', 'evals/c_target_fixtures_run.ts', 'evals/selfhost_throughput.mjs',
    'bend2/bend.ts', 'bend2/comp.ts']) module(file);
  for (const file of ['evals/heavy_gate_native.c', 'bend2/selfhost/c_runtime.c', 'bend2/base.bend']) source(file);

  if (context.snapshotFixtures) {
    for (const [path, digest] of collectWorkloadInputs(repository, [...context.snapshotFixtures, ...matrixRoots(repository)])) {
      source(path, digest, 'consumer-workload');
      if (/\.(?:js|mjs|ts)$/.test(path)) module(path);
    }
    for (const file of ['evals/c_backend_library_caller.c', 'evals/c_backend_native_export_caller.c']) source(file);
  }
  source(evidence.root.path, evidence.root.sha256, 'compiler-root');
  document(evidence.root.manifest, evidence.root.manifestSha256);
  document(evidence.native.build.path, evidence.native.build.sha256);
  const corpus = document(evidence.native.corpusPath, evidence.native.corpusSha256);
  need(Array.isArray(corpus.files) && corpus.files.length > 0 && isAbsolute(corpus.directory), 'missing producer corpus inventory');
  for (const row of corpus.files) producerPin(resolve(corpus.directory, row.path), row.sha256);
  document(evidence.fixedpoint.report.path, evidence.fixedpoint.report.sha256);
  if (evidence.emitted?.path) document(evidence.emitted.path, evidence.emitted.sha256);
  if (evidence.javascript?.path) document(evidence.javascript.path, evidence.javascript.sha256);
  if (evidence.parser?.build) document(evidence.parser.build, evidence.parser.buildSha256);
  for (const [name, artifact] of [['binary', context.candidate.binary], ['image', context.candidate.stageOne]])
    add(artifact.path, 'artifacts/' + name, artifact.sha256, 'executed-candidate');
  add(evidence.fixedpoint.stageTwo.path, 'artifacts/stage-two', evidence.fixedpoint.stageTwo.sha256, 'fixedpoint-equality-evidence');

  if (context.bindings) {
    const b = context.bindings, frozen = realpathSync(b.frozenRepository);
    mappings.frozen = {original: frozen, snapshot: 'frozen'};
    for (const [path, digest] of Object.entries(b.inputs)) {
      need(within(frozen, realpathSync(path)), 'frozen input escapes authenticated repository');
      add(path, 'frozen/' + relative(frozen, realpathSync(path)), digest, 'frozen-workload', frozen);
    }
    add(b.frozenRoot, 'frozen/' + relative(frozen, b.frozenRoot), b.bindings.frozenRoot.sha256, 'frozen-root');
    for (const [name, path, digest] of [['bindings', b.path, b.sha256],
      ['controlNative', b.controlNative, b.controlNativeSha256], ['controlImage', b.controlImage, b.controlImageSha256]])
      add(path, 'artifacts/' + name, digest, 'baseline-artifact');
  }
  const headers = new Set();
  for (const entry of files.values()) {
    if (!entry.path.startsWith('repository/') || !/\.(?:c|h)$/.test(entry.original) || headers.has(entry.original)) continue;
    headers.add(entry.original);
    const code = readFileSync(entry.original, 'utf8');
    for (const match of code.matchAll(/^\s*#\s*include\s+([^\r\n]+)/gm)) {
      const include = match[1].match(/^"([^"]+)"/);
      if (include) source(resolve(dirname(entry.original), include[1]), undefined, 'local-c-include');
      else need(/^<[^>]+>/.test(match[1]), 'unresolved computed C include: ' + entry.original);
    }
  }
  return {files: [...files.values()].sort((a,b) => a.path.localeCompare(b.path)),
    authority: [...authority.values()].sort((a,b) => a.original.localeCompare(b.original)), mappings};
}
