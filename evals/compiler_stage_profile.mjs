// Opt-in stage profiling for the selfhost typed-step candidate.
//
// This module is diagnostic only. It never changes compiler behavior, never
// interprets a typed request, and never runs on the ordinary path: callers
// install it only when a stage-profile flag is present. It imports the single
// collector owned by evals/compiler_profile.mjs and adds:
//
//   - explicit wall/CPU/memory spans at real host boundaries (import, fuel
//     build, per-file parse, expand, check, emit, publication of output);
//   - exact host-step counters (the number of bounded Run advances requested);
//   - sampled typed-progress attribution at host-visible chunk boundaries,
//     reported as a distinct evidence kind, never as an exact span;
//   - measured bounded-step intervals: wall and current-thread CPU between two
//     consecutive host boundaries, attributed to the typed request pending when
//     the interval began. A chunk may cross request boundaries, so these are
//     measured envelope intervals, never isolated provider CPU;
//   - provenance pins for the producing script the caller declares, this helper
//     and the collector it imports (real path + sha256), the collector's own
//     profileId once its first span token exists, and a link to an enclosing
//     profile when one was declared, checked against that run's own run.json.
//     With no declaration the report records that none was declared or is
//     discoverable instead of inventing one.
//
// Semantic substage grouping uses the exact canonical request constructors and
// canonical source-module composition recorded by the typed-step generator's
// manifest. A request absent from that manifest stays unclassified; this module
// does not guess a phase from a name suffix or re-infer one from source text.
import {createHash} from 'node:crypto';
import {readFileSync, realpathSync} from 'node:fs';
import {isMainThread, threadId} from 'node:worker_threads';

export const STAGE_PROFILE_SCHEMA_VERSION = 1;

// The named groups the stage report can speak about, and the honest reason for
// each granularity. `measured` groups have a real host boundary; `sampled`
// groups are only attributed at typed chunk boundaries; `unreachable` groups
// are not executed by this host at all.
export const stageGroupMetadata = Object.freeze([
  {name: 'startup-import', measurement: 'explicit-span', provider: 'candidate host module import'},
  {name: 'parse-import-fuel', measurement: 'explicit-span+exact-counter', provider: 'compiled parser, host IO, eager fuel construction'},
  {name: 'template-expand', measurement: 'explicit-span+exact-step-counter', provider: 'typed template Run'},
  {name: 'check-signature-body', measurement: 'explicit-span+exact-step-counter',
    granularity: 'one native check_modules Run; the checker does not expose a host-visible signature/body split'},
  {name: 'check-publication', measurement: 'included-in-check-signature-body',
    granularity: 'FIR publication runs inside the ordinary Checker.check Run before its transient rewind; there is no separate host boundary, and its canonical helpers appear only in sampled request attribution when reached'},
  {name: 'emit-catalog', measurement: 'typed-progress-sample', provider: 'canonical module lower_catalog'},
  {name: 'emit-backend-lowering', measurement: 'typed-progress-sample', provider: 'canonical module backend_lower'},
  {name: 'emit-descriptor-nf', measurement: 'typed-progress-sample', provider: 'canonical module descriptor_nf'},
  {name: 'emit-layouts', measurement: 'typed-progress-sample', provider: 'canonical module c_backend_layout'},
  {name: 'emit-sharing', measurement: 'typed-progress-sample', provider: 'canonical module c_backend_sharing'},
  {name: 'emit-render-js', measurement: 'typed-progress-sample', provider: 'canonical modules js_emit/js_backend'},
  {name: 'emit-render-c', measurement: 'typed-progress-sample', provider: 'canonical modules c_emit_core/c_backend/c_backend_physical'},
  {name: 'emit-link-planning', measurement: 'typed-progress-sample', provider: 'canonical module c_backend_link; source-level link planning, not the external linker'},
  {name: 'emit-emitter-entry', measurement: 'typed-progress-sample', provider: 'canonical module emitter'},
  {name: 'link', measurement: 'unreachable-in-candidate-host',
    prerequisite: 'the typed-step candidate emits source only; native_compiler_experiment performs the external clang/link step'},
]);

// The evidence classes this report keeps separate. They are never added
// together: a measured interval is not an exact provider CPU share, a sample is
// not a duration, and a process-boundary memory number is not allocation.
export const stageEvidenceClasses = Object.freeze({
  explicitSpan: {
    observed: 'monotonic wall, process.cpuUsage delta, process.threadCpuUsage delta, process.memoryUsage/process.resourceUsage/heap-statistics boundary snapshot',
    scope: 'real host boundary; CPU is process-wide for the process delta, this-thread for the thread delta, and child processes are excluded',
  },
  exactCounter: {
    observed: 'host-step calls, module/parse/fuel/byte counters, producer state counters',
    scope: 'exact counts in declared units; never converted into time or CPU',
  },
  typedProgressSample: {
    observed: 'the fully qualified typed request constructor visible at a bounded-step boundary',
    scope: 'operational sample counts, one per boundary; not a duration, call count or CPU share',
  },
  stepInterval: {
    observed: 'wall clock and process.threadCpuUsage across consecutive host-visible typed boundaries',
    scope: 'measured but attributed: the interval is one bounded host step call, attributed to the typed request pending when it began; a chunk may advance up to the native quantum and cross request boundaries, so a group total is envelope time under that request and not isolated provider CPU',
  },
  nativeChildRow: {
    observed: 'NATIVE_BEGIN/NATIVE_FUEL/NATIVE_PHASE/NATIVE_CHUNK_PROFILE/NATIVE_RESULT rows already emitted by the native compiler host',
    scope: 'child-process RUSAGE_SELF wall/user/system and high-water RSS; process-wide across that child only, never per-request',
  },
  unknown: {
    isolatedProviderCpu: 'not observable at this seam: the host advances an opaque native Run by bounded chunks whose internal request transitions are not instrumented, so no exact per-provider CPU or per-request exclusive time exists',
    perGroupMemory: 'not observable: memory snapshots exist only at host-phase boundaries and are process-wide; no per-group or per-request heap/retained/allocation number is derived',
    perGroupAllocation: 'not observable: inspector heap sampling is statistical over allocated and collected objects and is not started by this collector',
    linkExecution: 'unreachable in the typed-step host, which emits source text only',
    workerAndChildTrees: 'not enumerable from the collector; a worker profile reports its own pid/threadId and native child rows carry their own receipt',
  },
});

// Declared canonical relative source path -> stage group. These are the exact
// paths recorded by the generator composition, not basename heuristics. A
// basename fallback is used only when the manifest has one unambiguous source
// for that basename, and the report records that weaker basis.
const moduleGroup = new Map([
  ['bend2/selfhost/backend_lower.bend', 'emit-backend-lowering'],
  ['bend2/selfhost/lower_catalog.bend', 'emit-catalog'],
  ['bend2/selfhost/descriptor_nf.bend', 'emit-descriptor-nf'],
  ['bend2/selfhost/c_backend_layout.bend', 'emit-layouts'],
  ['bend2/selfhost/c_backend_sharing.bend', 'emit-sharing'],
  ['bend2/selfhost/js_emit.bend', 'emit-render-js'],
  ['bend2/selfhost/js_backend.bend', 'emit-render-js'],
  ['bend2/selfhost/c_emit_core.bend', 'emit-render-c'],
  ['bend2/selfhost/c_backend.bend', 'emit-render-c'],
  ['bend2/selfhost/c_backend_physical.bend', 'emit-render-c'],
  ['bend2/selfhost/c_backend_link.bend', 'emit-link-planning'],
  ['bend2/selfhost/emitter.bend', 'emit-emitter-entry'],
  ['bend2/selfhost/checker.bend', 'check-signature-body'],
  ['bend2/selfhost/checker_arena.bend', 'check-signature-body'],
  ['bend2/selfhost/checker_ir.bend', 'check-signature-body'],
  ['bend2/selfhost/template.bend', 'template-expand'],
]);

const coarseGroup = protocol =>
  protocol === 'Checker' ? 'check-signature-body'
    : protocol === 'Template' ? 'template-expand'
      : protocol === 'Emitter' ? 'emit-emitter-entry' : 'unclassified';

const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');

const errorText = error => String(error?.message ?? error);

// Provenance pins are read only inside createStageProfile, so an unprofiled run
// never opens, hashes or even resolves a path. A pin never guesses: an
// undeclared or unreadable input stays null with its reason attached.
function pinFile(path, undeclaredReason) {
  if (typeof path !== 'string' || !path) return {path: null, bytes: null, sha256: null, reason: undeclaredReason};
  try {
    const resolved = realpathSync(path);
    const bytes = readFileSync(resolved);
    return {path: resolved, bytes: bytes.length, sha256: sha256(bytes)};
  } catch (error) {
    return {path, bytes: null, sha256: null, reason: 'unreadable declared path: ' + errorText(error)};
  }
}

/**
 * Parse an explicit enclosing-profile declaration (`SELFHOST_STAGE_PARENT`).
 * The declaration is caller-supplied data; a malformed one is a diagnostic
 * failure, never a silently absent link.
 */
export function stageParentDeclaration(text) {
  if (text === undefined || text === null || text === '') return null;
  let value;
  try {
    value = JSON.parse(text);
  } catch (error) {
    throw Error('SELFHOST_STAGE_PARENT is not JSON: ' + errorText(error));
  }
  if (value === null || typeof value !== 'object' || Array.isArray(value))
    throw Error('SELFHOST_STAGE_PARENT must be a JSON object');
  return value;
}

// A parent link is a claim about an existing collector run, so it is checked
// against that run's own run.json: kind, schema, run directory, identity and,
// when declared, the report path. Declared and observed facts stay separate and
// the record never asserts that this profile is the parent's child.
function describeParentProfile(declared, paths) {
  const absent = reason => ({status: 'absent', declared: null, observed: null, relation: null,
    sameProcess: null, reason, linkKey: null});
  if (declared === undefined || declared === null) return absent(isMainThread
    ? 'no enclosing stage profile was declared, and a parent-process profile cannot be discovered from this process'
    : 'no enclosing stage profile was declared, and a worker thread cannot enumerate stage profiles created by another thread');
  if (typeof declared !== 'object' || Array.isArray(declared))
    throw Error('parentProfile must be an object');
  const declaredRow = {
    runDirectory: typeof declared.runDirectory === 'string' ? declared.runDirectory : null,
    reportPath: typeof declared.reportPath === 'string' ? declared.reportPath : null,
    pid: Number.isSafeInteger(declared.pid) ? declared.pid : null,
    threadId: Number.isSafeInteger(declared.threadId) ? declared.threadId : null,
    isMainThread: typeof declared.isMainThread === 'boolean' ? declared.isMainThread : null,
    role: typeof declared.role === 'string' ? declared.role : null,
  };
  const unverified = (reason, observed = null, relation = null) =>
    ({status: 'unverified', declared: declaredRow, observed, relation, sameProcess: null, reason, linkKey: null});
  if (declaredRow.runDirectory === null) return unverified('declared parent profile carries no runDirectory');
  let runDirectory;
  try {
    runDirectory = realpathSync(declaredRow.runDirectory);
  } catch (error) {
    return unverified('declared parent runDirectory is not readable: ' + errorText(error));
  }
  const runJsonPath = paths.join(runDirectory, 'run.json');
  let runBytes, run;
  try {
    runBytes = readFileSync(runJsonPath);
    run = JSON.parse(runBytes.toString('utf8'));
  } catch (error) {
    return unverified('declared parent runDirectory has no readable captured run.json: ' + errorText(error));
  }
  if (run === null || typeof run !== 'object' || Array.isArray(run))
    return unverified('parent run.json is not an object');
  if (run.kind !== 'compiler-profile')
    return unverified('parent run.json kind ' + JSON.stringify(run.kind) + ' is not a compiler-profile');
  if (run.schemaVersion !== paths.schemaVersion)
    return unverified('parent run.json schemaVersion ' + JSON.stringify(run.schemaVersion) +
      ' is not the collector schema ' + paths.schemaVersion);
  const identity = run.identity;
  if (identity === null || typeof identity !== 'object' || Array.isArray(identity) ||
      !Number.isSafeInteger(identity.pid) || !Number.isSafeInteger(identity.threadId) ||
      typeof identity.isMainThread !== 'boolean')
    return unverified('parent run.json has no valid identity {pid, threadId, isMainThread}');
  let recordedDirectory;
  try {
    recordedDirectory = realpathSync(String(run.runDirectory));
  } catch (error) {
    return unverified('parent run.json runDirectory is not readable: ' + errorText(error));
  }
  if (recordedDirectory !== runDirectory)
    return unverified('parent run.json runDirectory differs from the declared runDirectory');
  const observed = {
    kind: run.kind,
    schemaVersion: run.schemaVersion,
    runDirectory,
    identity: {pid: identity.pid,
      parentPid: Number.isSafeInteger(identity.parentPid) ? identity.parentPid : null,
      threadId: identity.threadId, isMainThread: identity.isMainThread},
    reportPath: paths.join(runDirectory, 'summary.json'),
    runJsonPath,
    runJsonSha256: sha256(runBytes),
  };
  // Comparison only: an undeclared field is never filled in from the file.
  const compare = (declaredValue, observedValue) =>
    declaredValue === null ? 'undeclared' : declaredValue === observedValue ? 'match' : 'mismatch';
  const relation = {
    runDirectory: 'match',
    pid: compare(declaredRow.pid, observed.identity.pid),
    threadId: compare(declaredRow.threadId, observed.identity.threadId),
    isMainThread: compare(declaredRow.isMainThread, observed.identity.isMainThread),
    reportPath: 'undeclared',
  };
  if (declaredRow.reportPath !== null) {
    let declaredReport = null;
    try {
      declaredReport = paths.join(realpathSync(paths.dirname(declaredRow.reportPath)), paths.basename(declaredRow.reportPath));
    } catch {}
    relation.reportPath = declaredReport === observed.reportPath ? 'match' : 'mismatch';
  }
  const mismatched = Object.entries(relation).filter(([, value]) => value === 'mismatch').map(([field]) => field);
  const sameProcess = observed.identity.pid === process.pid;
  if (mismatched.length > 0) return {
    status: 'unverified', declared: declaredRow, observed, relation, sameProcess,
    reason: 'declared parent identity contradicts that run\'s own run.json: ' + mismatched.join(', '), linkKey: null,
  };
  return {
    status: 'verified', declared: declaredRow, observed, relation, sameProcess,
    reason: null,
    linkKey: 'parent collector runDirectory and run.json sha256; the parent profileId is in that profile\'s own summary.json',
    causality: 'not asserted: a matching run.json proves that collector run exists with that identity, not that this profile is its child',
    ...(!isMainThread && !sameProcess ? {topologyNote:
      'this profile runs on a worker thread, whose creating thread is in this process; the matched profile therefore belongs to a parent process, not to this thread\'s creator'} : {}),
  };
}

function describeParentThread(declared) {
  if (declared !== undefined && declared !== null) {
    if (typeof declared !== 'object' || Array.isArray(declared)) throw Error('parentThread must be an object');
    return {
      threadId: Number.isSafeInteger(declared.threadId) ? declared.threadId : null,
      isMainThread: typeof declared.isMainThread === 'boolean' ? declared.isMainThread : null,
      sameProcess: true,
      source: typeof declared.source === 'string' ? declared.source : 'declared by the stage profile caller',
    };
  }
  return isMainThread
    ? {threadId: null, isMainThread: null, sameProcess: null,
      source: 'this profile runs on the process main thread; its parent is another process (process.ppid), not a thread of this process'}
    : {threadId: null, isMainThread: null, sameProcess: true,
      source: 'this profile runs on a worker thread; node:worker_threads exposes no creating-thread id, so the creating thread is identified only as that of the same process'};
}

function constructorTag(value) {
  if (value === null || typeof value !== 'object' || Array.isArray(value) || typeof value.$ !== 'string') return undefined;
  return value.$;
}

const simpleConstructor = tag => tag === undefined ? undefined : tag.slice(tag.lastIndexOf('.') + 1);
const constructorNamespace = tag => {
  const at = tag.lastIndexOf('.');
  return at < 0 ? null : tag.slice(0, at);
};

function protocolOf(manifest) {
  const runType = manifest?.nativeChunk?.runType;
  if (typeof runType !== 'string') return undefined;
  for (const protocol of ['Checker', 'Template', 'Emitter']) if (runType.startsWith(protocol)) return protocol;
  return undefined;
}

/**
 * Read the typed-step generator manifests supplied by the caller. A manifest
 * contributes exact request constructors (`<Protocol>Request_<definition>`) and,
 * when it carries `canonicalComposition`, the canonical source module for each
 * definition. Returns an empty table when no manifest was supplied so callers
 * still get exact request tags with an explicit unclassified marker.
 */
function readReceipt(path) {
  const document = JSON.parse(readFileSync(path, 'utf8'));
  let provenance = document;
  if (typeof document.provenancePath === 'string') provenance = JSON.parse(readFileSync(document.provenancePath, 'utf8'));
  const artifactSha256 = typeof document.artifactSha256 === 'string' ? document.artifactSha256 : null;
  return {
    path: realpathSync(path), sha256: sha256(readFileSync(path)), artifactSha256,
    provenancePath: provenance === document ? null : realpathSync(document.provenancePath),
    loadedInputs: provenance.loadedInputs ?? document.loadedInputs ?? {},
    protectedPins: provenance.protectedPins ?? document.protectedPins ?? {},
  };
}

function bindManifestToReceipt(manifest, receipt, artifactSha256) {
  if (receipt === undefined) return {status: 'unverified', reason: 'no component build receipt supplied', checks: []};
  if (receipt.artifactSha256 === null) return {status: 'unverified', reason: 'receipt has no artifactSha256', checks: []};
  if (artifactSha256 === null) return {status: 'unverified', reason: 'no profiled artifact hash supplied', checks: []};
  if (receipt.artifactSha256 !== artifactSha256)
    return {status: 'mismatch', reason: 'receipt artifact hash differs from the profiled component', checks: []};
  const outputs = manifest.outputs ?? {};
  const entries = Object.entries(outputs);
  if (entries.length === 0) return {status: 'unverified', reason: 'manifest has no generated output pins', checks: []};
  const checks = entries.map(([output, expected]) => {
    const match = Object.entries(receipt.loadedInputs).find(([path]) => path === output || path.endsWith('/' + output));
    return {output, expectedSha256: expected, actualSha256: match?.[1] ?? null,
      status: match === undefined ? 'missing' : match[1] === expected ? 'verified' : 'mismatch'};
  });
  if (checks.some(check => check.status === 'mismatch')) return {status: 'mismatch', reason: 'generated output pin differs from receipt', checks};
  const requiredOutput = manifest.generationConfig?.output;
  const required = checks.find(check => check.output === requiredOutput);
  if (required === undefined || required.status !== 'verified')
    return {status: 'unverified', reason: 'receipt does not load the required generated engine output', checks};
  return {status: 'verified', reason: null, checks,
    note: 'all outputs shared between manifest and receipt must match; unloaded sibling outputs are recorded but not required'};
}

export function loadStageManifests(paths, binding = {}) {
  const requestToGroup = new Map();
  const provenance = [];
  const conflicts = [];
  const namespaces = new Set();
  for (const path of paths ?? []) {
    const bytes = readFileSync(path);
    const document = JSON.parse(bytes.toString('utf8'));
    const protocol = protocolOf(document);
    if (protocol === undefined) throw Error('Stage manifest has no typed Run protocol: ' + path);
    const output = document.generationConfig?.output;
    const namespace = typeof output === 'string' && output ? output.split('/').at(-1).replace(/\.bend$/, '') : undefined;
    if (namespace === undefined || !namespace) throw Error('Stage manifest has no output module namespace for request tags: ' + path);
    namespaces.add(namespace);
    const artifactBinding = bindManifestToReceipt(document, binding.receipt, binding.artifactSha256 ?? null);
    // Ownership comes from the authenticated manifest's canonical declaration
    // metadata only: each `kind:'def'` row declares its composed name, its
    // canonical name and the source file that declares it. Requests use the
    // composed name; the canonical name is only a fallback for manifests that
    // are not composed. The two key spaces stay separate because composed
    // definitions from different provider modules legitimately share a canonical
    // name, and a naive merge silently keeps whichever declaration was read
    // last. A key claimed by two different sources is ambiguous and stays
    // unowned; no name suffix, ordinal or last-wins choice is ever used.
    const composedOwners = new Map(), canonicalOwners = new Map();
    const sources = new Set();
    const declarationIdentities = {count: 0, withoutComposedSha256: 0};
    const addOwner = (map, key, source) => {
      if (typeof key !== 'string' || !key) return;
      const owners = map.get(key) ?? new Set();
      owners.add(source);
      map.set(key, owners);
    };
    for (const declaration of document.canonicalComposition?.declarations ?? []) {
      if (declaration?.kind !== 'def' || typeof declaration.source !== 'string') continue;
      if (typeof declaration.composedDeclarationSha256 === 'string') declarationIdentities.count += 1;
      else declarationIdentities.withoutComposedSha256 += 1;
      addOwner(composedOwners, declaration.name, declaration.source);
      addOwner(canonicalOwners, declaration.canonicalName, declaration.source);
      sources.add(declaration.source);
    }
    const ownerOf = key => {
      const composed = composedOwners.get(key);
      if (composed !== undefined)
        return composed.size === 1
          ? {source: [...composed][0], basis: 'composed-declaration-name'}
          : {conflictSources: [...composed].sort(), basis: 'composed-declaration-name-conflict'};
      const canonical = canonicalOwners.get(key);
      if (canonical !== undefined)
        return canonical.size === 1
          ? {source: [...canonical][0], basis: 'canonical-declaration-name'}
          : {conflictSources: [...canonical].sort(), basis: 'canonical-declaration-name-conflict'};
      return {source: null, basis: 'no-declared-owner'};
    };
    const basenameOwners = new Map();
    for (const source of sources) {
      const basename = source.split('/').at(-1);
      const owners = basenameOwners.get(basename) ?? [];
      if (!owners.includes(source)) owners.push(source);
      basenameOwners.set(basename, owners);
    }
    const inputs = document.canonicalComposition?.inputs ?? {};
    // Independent canonical pins from the composition's source rows. When both
    // the inputs map and a source row pin the same file they must agree; a
    // disagreement is reported instead of choosing one.
    const canonicalSourcePins = new Map();
    for (const row of document.canonicalComposition?.sources ?? [])
      if (typeof row?.canonical === 'string' && typeof row.canonicalSha256 === 'string')
        canonicalSourcePins.set(row.canonical, row.canonicalSha256);
    const sourceVerification = [];
    const sourceStatus = new Map();
    for (const source of [...sources].sort()) {
      const expectedFromInputs = typeof inputs[source] === 'string' ? inputs[source] : null;
      const expectedFromSources = canonicalSourcePins.get(source) ?? null;
      const conflict = expectedFromInputs !== null && expectedFromSources !== null && expectedFromInputs !== expectedFromSources;
      const expected = expectedFromInputs ?? expectedFromSources;
      let status = conflict ? 'conflict' : expected === null ? 'unpinned' : 'unavailable';
      let actual = null;
      if (!conflict && expected !== null) {
        try {
          actual = sha256(readFileSync(source));
          status = actual === expected ? 'verified' : 'mismatch';
        } catch (error) {
          status = 'missing';
        }
      }
      sourceStatus.set(source, status);
      sourceVerification.push({source,
        expectedSha256: expected,
        expectedFromInputsSha256: expectedFromInputs,
        expectedFromCanonicalSourcesSha256: expectedFromSources,
        actualSha256: actual, status,
        basis: expectedFromInputs !== null && expectedFromSources !== null
          ? 'manifest canonicalComposition.inputs and sources[].canonicalSha256 must agree'
          : expectedFromInputs !== null
            ? 'manifest canonicalComposition.inputs declared relative path'
            : expectedFromSources !== null
              ? 'manifest canonicalComposition.sources[].canonicalSha256'
              : 'no canonical pin for this declared source'});
    }
    const groupOfSource = source => {
      if (source === null) return {group: coarseGroup(protocol), basis: 'protocol-coarse'};
      const state = sourceStatus.get(source);
      if (state === 'mismatch') return {group: 'unverified-source', basis: 'source-hash-mismatch'};
      if (state === 'conflict') return {group: 'unverified-source', basis: 'source-pin-conflict'};
      const exact = moduleGroup.get(source);
      if (exact !== undefined) return {group: exact,
        basis: state === 'verified' ? 'verified-canonical-source' : 'declared-canonical-source'};
      const owners = basenameOwners.get(source.split('/').at(-1)) ?? [];
      if (owners.length === 1) {
        const byBasename = moduleGroup.get('bend2/selfhost/' + source.split('/').at(-1));
        if (byBasename !== undefined) return {group: byBasename, basis: 'declared-basename'};
      }
      return {group: 'module:' + source, basis: 'declared-unmapped-source'};
    };
    const definitions = [];
    const addRequest = name => {
      const tag = namespace + '.' + protocol + 'Request_' + name;
      const owner = ownerOf(name);
      // An ambiguous declared owner is never resolved by preference.
      if (owner.conflictSources !== undefined) {
        requestToGroup.set(tag, {group: 'unclassified-conflict', basis: 'declaration-source-conflict',
          source: null, ownerBasis: owner.basis, conflictSources: owner.conflictSources, protocol, namespace,
          artifactBinding: artifactBinding.status});
        return;
      }
      const source = owner.source;
      const classified = groupOfSource(source);
      const group = artifactBinding.status === 'verified' ? classified.group : 'declared:' + classified.group;
      const basis = artifactBinding.status === 'verified' ? classified.basis : classified.basis + '+artifact-binding-' + artifactBinding.status;
      const previous = requestToGroup.get(tag);
      if (previous !== undefined && previous.group !== group) {
        conflicts.push({tag, previous: previous.group, next: group, manifest: path});
        requestToGroup.set(tag, {group: 'unclassified-conflict', basis: 'manifest-conflict', source: null, protocol, namespace, artifactBinding: artifactBinding.status});
      } else requestToGroup.set(tag, {group, basis, source, ownerBasis: owner.basis, protocol, namespace, artifactBinding: artifactBinding.status});
    };
    for (const group of document.requestGroups ?? []) {
      for (const name of group.definitions ?? []) {
        if (typeof name !== 'string') throw Error('Stage manifest request group is malformed: ' + path);
        definitions.push(name);
        addRequest(name);
      }
    }
    // Composition declarations cover canonical definitions that this particular
    // generated closure did not reach into a request group. They still carry
    // exact declared source provenance, so the same request tag stays classifiable.
    for (const declaration of document.canonicalComposition?.declarations ?? []) {
      if (declaration?.kind !== 'def') continue;
      if (typeof declaration.name === 'string' && !definitions.includes(declaration.name)) addRequest(declaration.name);
      if (typeof declaration.canonicalName === 'string' && !definitions.includes(declaration.canonicalName)) addRequest(declaration.canonicalName);
    }
    const uniqueDefinitions = [...new Set(definitions)];
    const ownerBasisCounts = {};
    for (const name of uniqueDefinitions) {
      const basis = ownerOf(name).basis ?? 'unknown';
      ownerBasisCounts[basis] = (ownerBasisCounts[basis] ?? 0) + 1;
    }
    const claimConflicts = (map, key) => [...map.entries()].filter(([, owners]) => owners.size > 1)
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([name, owners]) => ({name, key, sources: [...owners].sort()}));
    provenance.push({
      path: realpathSync(path), sha256: sha256(bytes), protocol, namespace,
      requestConstructors: definitions.length,
      definitionsWithCanonicalSource: uniqueDefinitions.filter(name => typeof ownerOf(name).source === 'string').length,
      definitionOwnerBasis: ownerBasisCounts,
      declarationIdentities,
      canonicalSources: [...sources].sort(),
      canonicalSourcePins: Object.fromEntries([...canonicalSourcePins.entries()].sort(([a], [b]) => a.localeCompare(b))),
      sourceVerification,
      artifactBinding,
      basenameCollisions: [...basenameOwners.entries()].filter(([, owners]) => owners.length > 1)
        .map(([basename, owners]) => ({basename, sources: owners.sort()})),
      declarationOwnerConflicts: [...claimConflicts(composedOwners, 'name'), ...claimConflicts(canonicalOwners, 'canonicalName')],
      canonicalSourceSha256: document.canonicalComposition?.inputs,
      generator: document.generationConfig?.generator,
      loweringSourceSha256: document.loweringSourceSha256,
    });
  }
  return {requestToGroup, provenance, conflicts, namespaces: [...namespaces].sort()};
}

/**
 * Read-only typed progress observation. It follows at most 64 erased `Bound`
 * wrappers and reports constructor tags; request payloads are never inspected.
 * This is an operational sample of where the typed Run stands after a bounded
 * chunk, not a duration, a call count, or a semantic interpretation.
 */
export function typedProgressSample(run) {
  const runTag = constructorTag(run);
  const runNamespace = runTag === undefined ? null : constructorNamespace(runTag);
  let progress = run?.progress;
  for (let depth = 0; depth < 64; depth += 1) {
    const tag = constructorTag(progress);
    if (tag === undefined) return undefined;
    const simple = simpleConstructor(tag);
    // Generated progress constructors carry their protocol prefix
    // (CheckerPending, EmitterDirect, ...); the suffix is the ABI name.
    const kind = simple.replace(/^(?:Checker|Template|Emitter)/, '');
    if (kind === 'Finished') return {progress: kind, progressTag: tag, runNamespace};
    if (kind === 'Pending' || kind === 'Direct') {
      // A Direct progress erases its scheduling request when the source invoke
      // runs, so only the progress shape is visible at that boundary.
      const envelope = progress.request;
      const request = envelope?.request;
      return {
        progress: kind,
        progressTag: tag,
        groupConstructor: constructorTag(envelope) ?? null,
        request: constructorTag(request) ?? null,
        runNamespace,
      };
    }
    if (kind === 'Bound') {progress = progress.inner; continue;}
    if (kind === 'RunState') {progress = progress.progress; continue;}
    return {progress: kind, progressTag: tag, unparsed: true, runNamespace};
  }
  return {progress: 'depth-limit', runNamespace};
}

// Measured interval aggregation is bounded: a full-root phase can observe
// hundreds of thousands of boundaries, but only a bounded set of group, source
// and request keys exists. Overflow is counted, never merged into another key.
const MAX_REQUEST_INTERVAL_BUCKETS = 512;
const MAX_SOURCE_INTERVAL_BUCKETS = 256;

const milliseconds = value => Math.round(value * 1000) / 1000;

function threadCpuBoundary() {
  if (typeof process.threadCpuUsage !== 'function') return null;
  const usage = process.threadCpuUsage();
  return {userMs: usage.user / 1000, systemMs: usage.system / 1000};
}

function newIntervalBucket() {
  return {intervals: 0, wallMs: 0, maxIntervalMs: 0, threadIntervals: 0,
    threadUserMs: 0, threadSystemMs: 0, crossings: 0, crossingUnknown: 0, terminalIntervals: 0};
}

function addInterval(bucket, wallMs, threadDelta, crossing, terminal) {
  bucket.intervals += 1;
  bucket.wallMs += wallMs;
  if (wallMs > bucket.maxIntervalMs) bucket.maxIntervalMs = wallMs;
  if (threadDelta !== null) {
    bucket.threadIntervals += 1;
    bucket.threadUserMs += threadDelta.userMs;
    bucket.threadSystemMs += threadDelta.systemMs;
  }
  if (crossing === true) bucket.crossings += 1;
  else if (crossing === null) bucket.crossingUnknown += 1;
  if (terminal) bucket.terminalIntervals += 1;
}

function bucketAt(store, key) {
  const existing = store.buckets.get(key);
  if (existing !== undefined) return existing;
  if (store.buckets.size >= store.cap) {
    store.overflow += 1;
    return null;
  }
  const bucket = newIntervalBucket();
  store.buckets.set(key, bucket);
  return bucket;
}

function serializedBuckets(store) {
  return Object.fromEntries([...store.buckets.entries()].sort(([a], [b]) => a.localeCompare(b))
    .map(([key, bucket]) => [key, {
      intervals: bucket.intervals,
      wallMs: milliseconds(bucket.wallMs),
      maxIntervalMs: milliseconds(bucket.maxIntervalMs),
      threadUserMs: bucket.threadIntervals > 0 ? milliseconds(bucket.threadUserMs) : null,
      threadSystemMs: bucket.threadIntervals > 0 ? milliseconds(bucket.threadSystemMs) : null,
      crossings: bucket.crossings,
      crossingUnknown: bucket.crossingUnknown,
      terminalIntervals: bucket.terminalIntervals,
    }]));
}

/**
 * Accumulate exact host-step counts, sampled typed progress and measured
 * bounded-step intervals for one phase. `onStep` runs only when profiling is
 * enabled. Optional progress checkpoints preserve the last observed boundary
 * before an abrupt worker stop.
 *
 * Interval evidence is measured, not sampled: each interval spans two
 * consecutive host-visible boundaries and is attributed to the typed request
 * pending when it began (the request the bounded chunk started under). A chunk
 * may advance up to the native quantum and cross request boundaries inside it,
 * so per-group totals are envelope time, not isolated provider CPU. When a
 * caller passes `options.intervals === false` the interval evidence is skipped
 * and the report says so; sampling/counters are unchanged.
 */
export function createStepAttribution(phase, protocol, table, profile, options = {}) {
  if (options === null || typeof options !== 'object' || Array.isArray(options))
    throw Error('Step attribution options must be an object');
  const measureIntervals = options.intervals !== false;
  const measureThreadCpu = measureIntervals && options.intervalCpu !== false && typeof process.threadCpuUsage === 'function';
  const threadCpuReason = !measureIntervals ? 'interval measurement is disabled'
    : options.intervalCpu === false ? 'options.intervalCpu === false'
      : typeof process.threadCpuUsage !== 'function' ? 'process.threadCpuUsage is not available in this runtime'
        : null;
  let hostSteps = 0, attributed = 0, unclassified = 0, observedNamespace = null;
  const requests = new Map(), groups = new Map(), groupBases = new Map(), shapes = new Map();
  const unclassifiedRequests = new Map(), unclassifiedReasons = new Map();
  const intervalTotal = newIntervalBucket();
  const groupIntervals = {cap: Infinity, overflow: 0, buckets: new Map()};
  const sourceIntervals = {cap: MAX_SOURCE_INTERVAL_BUCKETS, overflow: 0, buckets: new Map()};
  const requestIntervals = {cap: MAX_REQUEST_INTERVAL_BUCKETS, overflow: 0, unattributed: 0, buckets: new Map()};
  let previousBoundary = null, terminal = null;
  let checkpointAt = -Infinity;
  function checkpoint(sample) {
    if (profile === undefined) return;
    const now = performance.now();
    if (now - checkpointAt < 1000) return;
    checkpointAt = now;
    profile.record({
      kind: 'typed-step-progress', scope: 'latest observed host-visible bounded-step boundary',
      name: phase, units: 'host-step-calls', value: hostSteps,
      source: 'checker_core_step_runtime.mjs',
      details: {
        protocol, nativeChunkQuantum: 64,
        progressShape: sample?.progress ?? null,
        request: sample?.request ?? null,
        runNamespace: sample?.runNamespace ?? null,
        granularity: 'first boundary then at most once per second; not a substage duration, live-process claim, or continuous sample',
      },
    });
  }
  // Classify one boundary exactly once. Sample counters keep their existing
  // semantics (one count per observed boundary); interval attribution reuses
  // the same group/source/request owner, never a name suffix or an ordinal.
  function classify(sample) {
    if (sample === undefined)
      return {visibility: 'no-progress-sample', group: 'unclassified', basis: null, source: null, request: null};
    if (observedNamespace === null && sample.runNamespace !== null) observedNamespace = sample.runNamespace;
    shapes.set(sample.progress, (shapes.get(sample.progress) ?? 0) + 1);
    if (typeof sample.request !== 'string')
      return {visibility: sample.progress === 'Direct' ? 'erased-direct'
          : sample.progress === 'depth-limit' ? 'depth-limit'
            : sample.unparsed === true ? 'unparsed' : 'no-request-visible',
        group: 'unclassified', basis: null, source: null, request: null};
    attributed += 1;
    requests.set(sample.request, (requests.get(sample.request) ?? 0) + 1);
    const requestNamespace = constructorNamespace(sample.request);
    let reason = null, mapped;
    if (observedNamespace !== null && requestNamespace !== observedNamespace) reason = 'namespace-mismatch';
    else if (table === undefined || table.requestToGroup.size === 0) reason = 'no-manifest';
    else if (observedNamespace !== null && !table.namespaces.includes(observedNamespace)) reason = 'unregistered-namespace';
    else {
      mapped = table.requestToGroup.get(sample.request);
      if (mapped === undefined) reason = 'unmapped-request';
      else if (mapped.group === 'unclassified-conflict')
        reason = mapped.basis === 'declaration-source-conflict' ? 'declaration-source-conflict' : 'manifest-conflict';
    }
    const group = reason === null ? mapped.group : 'unclassified';
    if (reason === null) {
      const basis = mapped.basis ?? 'unknown';
      const bases = groupBases.get(group) ?? new Set();
      bases.add(basis);
      groupBases.set(group, bases);
    } else {
      unclassified += 1;
      unclassifiedRequests.set(sample.request, (unclassifiedRequests.get(sample.request) ?? 0) + 1);
      unclassifiedReasons.set(reason, (unclassifiedReasons.get(reason) ?? 0) + 1);
    }
    groups.set(group, (groups.get(group) ?? 0) + 1);
    return {visibility: 'request', group,
      basis: reason === null ? mapped.basis ?? 'unknown' : null,
      source: reason === null ? mapped.source ?? null : null,
      request: sample.request, reason};
  }
  function accumulateInterval(from, to, terminalHook) {
    const wallMs = Math.max(0, to.at - from.at);
    const threadDelta = from.thread !== null && to.thread !== null
      ? {userMs: to.thread.userMs - from.thread.userMs, systemMs: to.thread.systemMs - from.thread.systemMs}
      : null;
    const terminalInterval = terminalHook !== null;
    // Equal request tags do not prove the chunk stayed inside one request; a
    // chunk that crossed and returned is undetectable at these boundaries.
    const crossing = terminalInterval ? false
      : from.visibility === 'request' && to.visibility === 'request' ? from.request !== to.request : null;
    addInterval(intervalTotal, wallMs, threadDelta, crossing, terminalInterval);
    const groupBucket = bucketAt(groupIntervals,
      from.visibility === 'request' ? from.group : 'unclassified:' + from.visibility);
    if (groupBucket !== null) addInterval(groupBucket, wallMs, threadDelta, crossing, terminalInterval);
    const sourceBucket = bucketAt(sourceIntervals, from.source ?? '(no declared canonical source)');
    if (sourceBucket !== null) addInterval(sourceBucket, wallMs, threadDelta, crossing, terminalInterval);
    if (from.visibility === 'request') {
      const requestBucket = bucketAt(requestIntervals, from.request);
      if (requestBucket !== null) addInterval(requestBucket, wallMs, threadDelta, crossing, terminalInterval);
    } else requestIntervals.unattributed += 1;
  }
  function closeTerminal(hook) {
    if (!measureIntervals) {
      if (terminal === null) terminal = {hook, measured: false, reason: 'interval measurement is disabled'};
      return;
    }
    if (terminal !== null) return;
    if (previousBoundary === null) {
      terminal = {hook, measured: false, reason: 'no host-visible typed boundary was observed before the terminal hook'};
      return;
    }
    const at = performance.now();
    const thread = measureThreadCpu ? threadCpuBoundary() : null;
    const wallMs = Math.max(0, at - previousBoundary.at);
    accumulateInterval(previousBoundary, {at, thread}, hook);
    terminal = {hook, measured: true, wallMs: milliseconds(wallMs),
      includes: 'the final bounded step call and any result validation between the last boundary and this hook'};
    previousBoundary = null;
  }
  return {
    onStep(_steps, run) {
      hostSteps += 1;
      // Clocks bracket the read-only progress observation so the collector's
      // own classification/checkpoint work never lands inside an interval.
      const endAt = measureIntervals ? performance.now() : 0;
      const endThread = measureThreadCpu ? threadCpuBoundary() : null;
      const sample = typedProgressSample(run);
      checkpoint(sample);
      const endpoint = classify(sample);
      if (!measureIntervals) return;
      if (previousBoundary !== null) accumulateInterval(previousBoundary, {...endpoint, at: endAt, thread: endThread}, null);
      previousBoundary = {...endpoint, at: performance.now(),
        thread: measureThreadCpu ? threadCpuBoundary() : null};
    },
    onFinish(_value, _steps) {closeTerminal('finish');},
    onError(_error, _steps) {closeTerminal('error');},
    record(profile) {
      profile.record({
        kind: 'typed-step-exact-counters', scope: 'host orchestration', name: phase + '-steps',
        units: 'host-step-calls', value: hostSteps, source: 'checker_core_step_runtime.mjs',
        details: {phase, hostStepCall: 'one bounded public step export call; initial start call excluded',
          nativeChunkQuantum: 64, note: 'exact host calls, not semantic operations or CPU'},
      });
      if (shapes.size > 0) profile.record({
        kind: 'typed-progress-samples', scope: 'host-visible typed chunk boundary',
        name: phase + '-typed-progress', units: 'request-boundary-samples',
        values: {requestBoundarySamples: attributed,
          ...Object.fromEntries([...groups.entries()].sort(([a], [b]) => a.localeCompare(b)))},
        source: 'generated typed Run progress + registered generator manifest',
        details: {
          phase,
          granularity: 'sample of the typed progress after each bounded host step; up to 64 native advances may have run since the previous sample, and only the request pending at the boundary is observed',
          evidenceType: 'operational attribution, not a duration or exact call count',
          progressShapes: Object.fromEntries([...shapes.entries()].sort(([a], [b]) => a.localeCompare(b))),
          requestSamples: Object.fromEntries([...requests.entries()].sort(([a], [b]) => a.localeCompare(b))),
          observedRunNamespace: observedNamespace,
          artifactBinding: table?.provenance?.find(row => row.namespace === observedNamespace)?.artifactBinding
            ?? {status: 'unverified', reason: 'no manifest registered for the observed Run namespace', checks: []},
          registeredManifestNamespaces: table?.namespaces ?? [],
          groupBases: Object.fromEntries([...groupBases.entries()].map(([group, bases]) => [group, [...bases].sort()])),
          unclassifiedSamples: unclassified,
          unclassifiedReasons: Object.fromEntries([...unclassifiedReasons.entries()].sort(([a], [b]) => a.localeCompare(b))),
          unclassifiedRequests: Object.fromEntries([...unclassifiedRequests.entries()].sort(([a], [b]) => a.localeCompare(b))),
          mapping: table === undefined || table.provenance.length === 0
            ? 'no generator manifest supplied; fully qualified request tags are retained but ungrouped'
            : 'request namespace bound to the observed Run; groups require an exact registered manifest request tag and declared canonical source path (basename fallback only when unambiguous)',
          intervalMeasurement: 'see the same phase \'-intervals\' observation: measured bounded-step intervals are a separate evidence type and are never added to these sample counts',
        },
      });
      if (!measureIntervals) return;
      profile.record({
        kind: 'step-interval-measurements', scope: 'host-visible bounded-step intervals in one typed phase',
        name: phase + '-intervals',
        values: {
          intervals: intervalTotal.intervals,
          wallMs: milliseconds(intervalTotal.wallMs),
          maxIntervalMs: milliseconds(intervalTotal.maxIntervalMs),
          crossings: intervalTotal.crossings,
          crossingUnknown: intervalTotal.crossingUnknown,
          terminalIntervals: intervalTotal.terminalIntervals,
          groupBuckets: groupIntervals.buckets.size,
          sourceBuckets: sourceIntervals.buckets.size,
          sourceOverflow: sourceIntervals.overflow,
          requestBuckets: requestIntervals.buckets.size,
          requestOverflow: requestIntervals.overflow,
          unattributedIntervals: requestIntervals.unattributed,
          ...(intervalTotal.threadIntervals > 0 ? {
            threadIntervals: intervalTotal.threadIntervals,
            threadUserMs: milliseconds(intervalTotal.threadUserMs),
            threadSystemMs: milliseconds(intervalTotal.threadSystemMs)} : {}),
        },
        unitsByField: {
          intervals: 'bounded-step-intervals', wallMs: 'milliseconds', maxIntervalMs: 'milliseconds',
          threadIntervals: 'intervals', threadUserMs: 'milliseconds', threadSystemMs: 'milliseconds',
          crossings: 'intervals', crossingUnknown: 'intervals', terminalIntervals: 'intervals',
          groupBuckets: 'distinct intervals group keys', sourceBuckets: 'distinct declared source keys',
          sourceOverflow: 'intervals', requestBuckets: 'distinct request keys',
          requestOverflow: 'intervals', unattributedIntervals: 'intervals',
        },
        source: 'checker_core_step_runtime.mjs observe.onStep/onFinish/onError boundaries',
        details: {
          phase, protocol,
          evidenceType: 'measured interval time attributed to the typed request pending when the interval began; never isolated provider CPU',
          attribution: 'each interval starts after one read-only boundary observation and ends at the next boundary; it is the wall and current-thread CPU of the bounded host step call that ran under the start request',
          crossing: 'crossings counts intervals whose request tag differs at the two boundaries; one bounded chunk may advance up to the native quantum and cross request boundaries internally, and a chunk that crosses and returns to the same request is undetectable, so per-group totals are envelope time under the start request, not exclusive provider time',
          projections: 'perGroup, perDeclaredSource and perRequest are three projections of the same disjoint intervals; add one projection only, never across projections',
          keySemantics: {
            group: 'declared stage group, or unclassified:<visibility> when the boundary exposes no attributable request',
            source: 'the authenticated manifest declaration source of the request pending at the interval start; "(no declared canonical source)" when the request has no single declared owner',
            request: 'the fully qualified typed request constructor pending at the interval start',
          },
          coverage: {
            hostSteps,
            measuredIntervals: intervalTotal.intervals,
            terminal,
            window: 'from the first observed boundary to the onFinish/onError hook',
            outsideIntervals: 'the native start export call before the first boundary and host work after the terminal hook; they are outside every interval and the collector never subtracts them from the phase span',
            observationOverhead: 'each boundary reads its clocks before and after the read-only progress sample, so collector sampling work is excluded from the measured intervals',
          },
          threadCpu: {
            status: intervalTotal.threadIntervals > 0 ? 'available' : 'unavailable',
            source: 'process.threadCpuUsage deltas over the same intervals',
            scope: 'the orchestrating thread only; worker threads and runtime helper threads are excluded and no other-thread split is derived',
            reason: intervalTotal.threadIntervals > 0 ? null : threadCpuReason,
          },
          perGroup: serializedBuckets(groupIntervals),
          perDeclaredSource: serializedBuckets(sourceIntervals),
          perRequest: serializedBuckets(requestIntervals),
          unknown: [
            'isolated provider CPU: not observable at this seam; one opaque native chunk may contain up to the native quantum of request transitions and runtime work',
            'process-wide CPU per interval: not collected; the phase span carries one process.cpuUsage delta, and process CPU also covers helper/worker threads that no typed interval boundary can attribute',
            'per-interval or per-group memory, allocation bytes and retained bytes: not observable; only phase-boundary process snapshots exist and this collector starts no inspector sampling',
            'link execution: unreachable in this host, which emits source text only',
            'worker and child process CPU: excluded from both deltas; a worker or native child reports its own identity/receipt and is never merged here',
          ],
        },
      });
    },
  };
}

/**
 * Parse preserved native compiler stderr rows into explicit observations. These
 * are the coarse native spans already emitted by native_compiler_host.c: wall
 * clock and process getrusage scopes, never per-substage or per-allocation
 * claims. The trace is a preserved artifact, not a fresh run.
 */
export function nativeTraceObservations(text) {
  const observations = [];
  for (const line of String(text).split('\n')) {
    const trimmed = line.trim();
    if (trimmed.startsWith('NATIVE_BEGIN ')) {
      const row = JSON.parse(trimmed.slice('NATIVE_BEGIN '.length));
      observations.push({
        kind: 'native-begin', scope: 'native child process', name: 'begin',
        values: {computeThreads: row.computeThreads, parserFuel: row.parserFuel},
        unitsByField: {computeThreads: 'threads', parserFuel: 'fuel-cells'},
        source: 'native_compiler_host.c NATIVE_BEGIN',
        details: {phase: row.phase, phaseTraceVersion: row.phaseTraceVersion},
      });
      continue;
    }
    if (trimmed.startsWith('NATIVE_FUEL ')) {
      const row = JSON.parse(trimmed.slice('NATIVE_FUEL '.length));
      observations.push({
        kind: 'native-fuel-exact', scope: 'native child process', name: 'parser-fuel-' + row.sourceOrdinal,
        values: {elapsedMs: row.elapsedMs, cells: row.cells, processPeakRssBeforeBytes: row.processPeakRssBeforeBytes,
          processPeakRssAfterBytes: row.processPeakRssAfterBytes},
        unitsByField: {elapsedMs: 'milliseconds', cells: 'fuel-cells',
          processPeakRssBeforeBytes: 'bytes', processPeakRssAfterBytes: 'bytes'},
        source: 'native_compiler_host.c NATIVE_FUEL',
        details: {sourceOrdinal: row.sourceOrdinal,
          note: 'eager parser fuel cells constructed for one source; peak RSS before/after includes the whole process'},
      });
      continue;
    }
    if (trimmed.startsWith('NATIVE_PHASE ')) {
      const row = JSON.parse(trimmed.slice('NATIVE_PHASE '.length));
      if (typeof row.phase !== 'string') continue;
      observations.push({
        kind: 'native-phase-coarse-span', scope: 'native child process', name: row.phase,
        values: {
          elapsedMs: row.elapsedMs, userCpuMs: row.userCpuMs, systemCpuMs: row.systemCpuMs,
          ...(row.chunkAdvances === undefined ? {} : {chunkAdvances: row.chunkAdvances, chunkQuantum: row.chunkQuantum}),
        },
        unitsByField: {elapsedMs: 'milliseconds', userCpuMs: 'milliseconds', systemCpuMs: 'milliseconds',
          ...(row.chunkAdvances === undefined ? {} : {chunkAdvances: 'host-step-calls', chunkQuantum: 'steps-per-call'})},
        source: 'native_compiler_host.c NATIVE_PHASE (getrusage RUSAGE_SELF + monotonic wall)',
        details: {
          granularity: 'coarse phase boundary; CPU is process-wide including compute threads and is not exclusive across overlapping phases',
          cpuScope: 'child process RUSAGE_SELF across all of that child\'s threads; never this producer process and never an individual provider',
          cpuIsolation: false,
          providerCpu: null,
          providerCpuReason: 'the phase boundary aggregates every thread in the native child; the typed Run exposes no per-provider boundary inside it',
          provenance: 'native child process receipt; its pid is not carried by this row and is never inferred from the producer pid',
          ...(row.modules === undefined ? {} : {modules: row.modules, sourceBytes: row.sourceBytes,
            foreignBytes: row.foreignBytes, eagerFuelCells: row.eagerFuelCells, fuelBuildMs: row.fuelBuildMs}),
        },
      });
      continue;
    }
    if (trimmed.startsWith('NATIVE_CHUNK_PROFILE ')) {
      const row = JSON.parse(trimmed.slice('NATIVE_CHUNK_PROFILE '.length));
      if (typeof row.phase !== 'string') continue;
      observations.push({
        kind: 'native-chunk-profile', scope: 'diagnostic native chunk view', name: row.phase,
        values: {
          elapsedMs: row.elapsedMs, userCpuMs: row.userCpuMs, systemCpuMs: row.systemCpuMs,
          chunkAdvances: row.chunkAdvances, chunkQuantum: row.chunkQuantum,
          shapeFinished: row.shapeFinished, shapePending: row.shapePending,
          shapeDirect: row.shapeDirect, shapeBound: row.shapeBound,
        },
        unitsByField: {elapsedMs: 'milliseconds', userCpuMs: 'milliseconds', systemCpuMs: 'milliseconds',
          chunkAdvances: 'host-step-calls', chunkQuantum: 'steps-per-call',
          shapeFinished: 'chunk-boundary-samples', shapePending: 'chunk-boundary-samples',
          shapeDirect: 'chunk-boundary-samples', shapeBound: 'chunk-boundary-samples'},
        source: 'evals/native_stage_profile_host.c NATIVE_CHUNK_PROFILE',
        details: {
          evidenceType: 'operational chunk attribution, not a source substage span or CPU share',
          granularity: 'one sample after each bounded chunk view; shape counts the typed progress constructor only (Finished/Pending/Direct/Bound); request payloads are never read',
          requestGroups: row.requestGroups ?? {},
          requestGroupsUnits: 'chunk-boundary-samples by outer Emitter request-group variant (100+N code N in the C counter); payload untouched',
          scopeNote: 'CPU is process-wide RUSAGE_SELF and is not exclusive across overlapping work',
          cpuIsolation: false,
          providerCpu: null,
          providerCpuReason: 'userCpuMs/systemCpuMs belong to the whole chunked phase across every thread; requestGroups are boundary sample counts and must never be divided into or multiplied by that CPU to invent a per-group or per-provider share',
          chunkAttribution: 'a chunk can advance up to chunkQuantum native steps and cross request groups, so even the boundary-observed group is an envelope under which the chunk began, not the chunk\'s exclusive owner',
        },
      });
      continue;
    }
    if (trimmed.startsWith('NATIVE_RESULT ')) {
      const row = JSON.parse(trimmed.slice('NATIVE_RESULT '.length));
      observations.push({
        kind: 'native-result', scope: 'native child process', name: 'result',
        values: {bytes: row.bytes, modules: row.modules},
        unitsByField: {bytes: 'bytes', modules: 'modules'},
        source: 'native_compiler_host.c NATIVE_RESULT', details: {result: row.result},
      });
    }
  }
  return observations;
}

/**
 * Create the opt-in collector plus a strict span stack. The collector owns the
 * run identity and report; this wrapper only guarantees nested closures and
 * honest failure statuses for spans a caller left open.
 *
 * Provenance is pinned here, once, for every producer that profiles through
 * this helper: the executing script the caller declares, this stage helper and
 * the collector it imports, all by real path and sha256. The ordinary
 * (no-profile) path never calls this function, so it hashes and reads nothing.
 * `parentProfile`/`parentThread` describe an enclosing profile and the creating
 * thread; a declared parent is checked against that run's own run.json, and a
 * missing declaration is recorded as undeclared rather than as an absence of
 * any parent profile in the system.
 */
export async function createStageProfile({directory, execution, rawDetail = false, manifestPaths = [], artifact, receiptPaths = [], executingScript, parentProfile, parentThread}) {
  const {createCompilerProfile, COMPILER_PROFILE_SCHEMA_VERSION} = await import('./compiler_profile.mjs');
  // Imported here, not at module scope: an unprofiled run must not even resolve
  // these modules, and this helper is only called by an opt-in profiling run.
  const {fileURLToPath} = await import('node:url');
  const {join, dirname, basename} = await import('node:path');
  const receipts = receiptPaths.map(readReceipt);
  const receipt = receipts.find(candidate => artifact !== undefined && candidate.artifactSha256 === artifact.sha256) ?? receipts[0];
  const table = loadStageManifests(manifestPaths, {artifactSha256: artifact?.sha256 ?? null, receipt});
  const profileSources = {
    executingScript: pinFile(executingScript,
      'the caller declared no executing script path; the stage helper cannot infer which program imported it'),
    stageHelper: pinFile(fileURLToPath(import.meta.url), 'the stage helper path is unavailable'),
    collector: pinFile(fileURLToPath(new URL('./compiler_profile.mjs', import.meta.url)), 'the collector path is unavailable'),
  };
  const parent = describeParentProfile(parentProfile, {join, dirname, basename, schemaVersion: COMPILER_PROFILE_SCHEMA_VERSION});
  const parentThreadRow = describeParentThread(parentThread);
  const declaredExecution = execution === null || execution === undefined ? {} : execution;
  if (typeof declaredExecution !== 'object' || Array.isArray(declaredExecution))
    throw Error('stage profile execution must be an object');
  const profile = await createCompilerProfile({directory,
    execution: {...declaredExecution, profileSources}, rawDetail});
  const open = [];
  let finished = false, result, collectorProfileId;
  const api = {
    profile,
    runDirectory: profile.runDirectory,
    reportPath: profile.reportPath,
    manifestTable: table,
    profileSources,
    parentProfile: parent,
    parentThread: parentThreadRow,
    get profileId() {return collectorProfileId ?? null;},
    get finished() {return finished;},
    span(name, details = {}, options = {}) {
      const token = profile.begin(name, details, options);
      // The collector exposes its own run UUID only through span tokens; take
      // the first real one so the stage report can be joined to its collector
      // summary. This observes an existing token and creates no span.
      if (collectorProfileId === undefined && typeof token.profileId === 'string') {
        collectorProfileId = token.profileId;
        profile.record({
          kind: 'stage-provenance', scope: 'stage collector identity', name: 'collector-profile-id',
          values: {profileId: collectorProfileId},
          source: 'evals/compiler_stage_profile.mjs',
          details: {origin: 'profileId of the first stage span token; the same UUID is this profile\'s summary.json profileId',
            runDirectory: profile.runDirectory, reportPath: profile.reportPath},
        });
      }
      open.push({token, name});
      return token;
    },
    end(token, status = 'completed', details = {}) {
      const top = open.at(-1);
      if (top === undefined || top.token !== token) throw Error('Stage span stack violation: ' + (top?.name ?? 'empty'));
      const closed = profile.end(token, status, details);
      open.pop();
      return closed;
    },
    record(observation) {profile.record(observation);},
    fail(error) {
      if (finished) return result ?? profile.reportPath;
      const message = error instanceof Error ? error.message : String(error);
      // A known failure is a real boundary: close each open stage explicitly as
      // failed before the collector finalizes.
      while (open.length > 0) {
        const top = open.at(-1);
        profile.end(top.token, 'failed', {closeReason: 'candidate host terminated', error: message});
        open.pop();
      }
      result = profile.finish('failed', error);
      finished = true;
      return result ?? profile.reportPath;
    },
    finish(status = 'completed', error) {
      if (finished) return result ?? profile.reportPath;
      if (status === 'failed') {
        while (open.length > 0) {
          const top = open.at(-1);
          profile.end(top.token, 'failed', {closeReason: 'stage profile failed with span still open', error: error instanceof Error ? error.message : String(error ?? '')});
          open.pop();
        }
      }
      // A completed/aborted finish leaves the open stack to the collector so
      // its fail-closed contract marks measurementStatus incomplete. The wrapper
      // clears its stack only after the collector has observed and closed it.
      result = profile.finish(status, error);
      open.length = 0;
      finished = true;
      return result ?? profile.reportPath;
    },
  };
  profile.record({
    kind: 'stage-provenance', scope: 'stage collector process and thread', name: 'stage-profile-identity',
    values: {pid: process.pid, parentPid: process.ppid, threadId, isMainThread: isMainThread ? 1 : 0},
    source: 'evals/compiler_stage_profile.mjs',
    details: {
      process: {pid: process.pid, parentPid: process.ppid, execPath: process.execPath,
        platform: process.platform, arch: process.arch},
      thread: {threadId, isMainThread, threadKind: isMainThread ? 'main-thread' : 'worker-thread',
        source: 'node:worker_threads in the stage collector process'},
      parentThread: parentThreadRow,
      parentProfile: parent,
      profileSources,
      collectorProfile: {runDirectory: profile.runDirectory, reportPath: profile.reportPath,
        profileId: null,
        profileIdReason: 'the collector exposes profileId only through span tokens; it is recorded by the separate stage-provenance observation collector-profile-id after the first span begins, and this creation-time record is not rewritten',
        linkKey: 'collector runDirectory plus reportPath, both real and unique per profile'},
      cpuScope: {
        phaseSpan: 'process.cpuUsage (every thread in this process) plus process.threadCpuUsage (this thread only) deltas from the collector; child processes are excluded from both',
        stepInterval: 'process.threadCpuUsage deltas over consecutive typed boundaries on the orchestrating thread; worker and helper threads are excluded',
        nativeChildRow: 'child-process RUSAGE_SELF rows parsed from a preserved trace; never merged with this process\'s CPU',
      },
      workerThreads: {enumerable: false,
        reason: 'a producer-created worker thread registers no identity with the stage collector; a worker-created stage report carries its own pid/threadId and the process deltas include all threads'},
      childProcesses: {enumerable: false,
        reason: 'the collector cannot enumerate child processes; a native child\'s CPU/RSS exists only as its own preserved NATIVE_* receipt and is never attributed here'},
      memoryScope: 'phase-boundary process.memoryUsage/process.resourceUsage/heap-statistics snapshots only; no per-group, per-request, live or retained byte measurement',
      samplingScope: 'the stage collector starts no inspector sampling; sampled CPU/allocation profiles belong to the separate compiler-profile sampling option',
    },
  });
  profile.record({
    kind: 'stage-group-metadata', scope: 'diagnostic stage report', name: 'compiler-stage-groups',
    values: Object.fromEntries(stageGroupMetadata.map(group => [group.name, group.measurement])),
    source: 'evals/compiler_stage_profile.mjs',
    details: {schemaVersion: STAGE_PROFILE_SCHEMA_VERSION, groups: stageGroupMetadata,
      evidenceClasses: stageEvidenceClasses,
      attractionNote: 'explicit spans, exact host-step counters, measured step intervals and sampled chunk-boundary attribution are separate evidence types and are never added together',
      unknownNote: 'isolated per-provider CPU, per-group memory/allocation and external link execution stay explicitly unknown; no sampled or envelope number replaces them'},
  });
  if (table.provenance.length > 0) profile.record({
    kind: 'stage-attribution-table', scope: 'canonical generator manifest', name: 'typed-request-groups',
    values: {requestConstructors: table.requestToGroup.size, conflicts: table.conflicts.length,
      declarationOwnerConflicts: table.provenance.reduce((count, row) => count + (row.declarationOwnerConflicts?.length ?? 0), 0)},
    unitsByField: {requestConstructors: 'request constructors', conflicts: 'conflicting request tags',
      declarationOwnerConflicts: 'ambiguous declaration keys'},
    source: 'typed-step generator manifest',
    details: {manifests: table.provenance, conflicts: table.conflicts,
      ownership: 'a request owner is the single declared source of the composed declaration name; the canonical name is used only when no composed name exists, and an ambiguous key stays unowned (unclassified-conflict)',
      artifact: artifact ?? null, receipt: receipt === undefined ? null : {path: receipt.path, sha256: receipt.sha256,
        artifactSha256: receipt.artifactSha256, provenancePath: receipt.provenancePath}},
  });
  return api;
}
