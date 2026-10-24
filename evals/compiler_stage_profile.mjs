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
//     reported as a distinct evidence kind, never as an exact span.
//
// Semantic substage grouping uses the exact canonical request constructors and
// canonical source-module composition recorded by the typed-step generator's
// manifest. A request absent from that manifest stays unclassified; this module
// does not guess a phase from a name suffix or re-infer one from source text.
import {createHash} from 'node:crypto';
import {readFileSync, realpathSync} from 'node:fs';

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
  {name: 'emit-render-c', measurement: 'typed-progress-sample', provider: 'canonical modules c_emit/c_emit_core/c_backend/c_backend_physical'},
  {name: 'emit-link-planning', measurement: 'typed-progress-sample', provider: 'canonical module c_backend_link; source-level link planning, not the external linker'},
  {name: 'emit-emitter-entry', measurement: 'typed-progress-sample', provider: 'canonical module emitter'},
  {name: 'link', measurement: 'unreachable-in-candidate-host',
    prerequisite: 'the typed-step candidate emits source only; native_compiler_experiment performs the external clang/link step'},
]);

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
  ['bend2/selfhost/c_emit.bend', 'emit-render-c'],
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
    const sourceOf = new Map();
    const sources = new Set();
    for (const declaration of document.canonicalComposition?.declarations ?? []) {
      if (declaration?.kind !== 'def' || typeof declaration.source !== 'string') continue;
      // Requests use the composed declaration name; the canonical name is kept
      // as an additional exact key for manifests that are not composed.
      if (typeof declaration.name === 'string') sourceOf.set(declaration.name, declaration.source);
      if (typeof declaration.canonicalName === 'string') sourceOf.set(declaration.canonicalName, declaration.source);
      sources.add(declaration.source);
    }
    const basenameOwners = new Map();
    for (const source of sources) {
      const basename = source.split('/').at(-1);
      const owners = basenameOwners.get(basename) ?? [];
      if (!owners.includes(source)) owners.push(source);
      basenameOwners.set(basename, owners);
    }
    const inputs = document.canonicalComposition?.inputs ?? {};
    const sourceVerification = [];
    const sourceStatus = new Map();
    for (const source of [...sources].sort()) {
      const expected = typeof inputs[source] === 'string' ? inputs[source] : null;
      let status = expected === null ? 'unpinned' : 'unavailable';
      let actual = null;
      if (expected !== null) {
        try {
          actual = sha256(readFileSync(source));
          status = actual === expected ? 'verified' : 'mismatch';
        } catch (error) {
          status = 'missing';
        }
      }
      sourceStatus.set(source, status);
      sourceVerification.push({source, expectedSha256: expected, actualSha256: actual, status,
        basis: 'manifest canonicalComposition.inputs declared relative path'});
    }
    const groupOfSource = source => {
      if (source === null) return {group: coarseGroup(protocol), basis: 'protocol-coarse'};
      if (sourceStatus.get(source) === 'mismatch') return {group: 'unverified-source', basis: 'source-hash-mismatch'};
      const exact = moduleGroup.get(source);
      if (exact !== undefined) return {group: exact,
        basis: sourceStatus.get(source) === 'verified' ? 'verified-canonical-source' : 'declared-canonical-source'};
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
      const source = sourceOf.get(name) ?? null;
      const classified = groupOfSource(source);
      const group = artifactBinding.status === 'verified' ? classified.group : 'declared:' + classified.group;
      const basis = artifactBinding.status === 'verified' ? classified.basis : classified.basis + '+artifact-binding-' + artifactBinding.status;
      const previous = requestToGroup.get(tag);
      if (previous !== undefined && previous.group !== group) {
        conflicts.push({tag, previous: previous.group, next: group, manifest: path});
        requestToGroup.set(tag, {group: 'unclassified-conflict', basis: 'manifest-conflict', source: null, protocol, namespace, artifactBinding: artifactBinding.status});
      } else requestToGroup.set(tag, {group, basis, source, protocol, namespace, artifactBinding: artifactBinding.status});
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
    provenance.push({
      path: realpathSync(path), sha256: sha256(bytes), protocol, namespace,
      requestConstructors: definitions.length,
      definitionsWithCanonicalSource: definitions.filter(name => sourceOf.has(name)).length,
      canonicalSources: [...sources].sort(),
      sourceVerification,
      artifactBinding,
      basenameCollisions: [...basenameOwners.entries()].filter(([, owners]) => owners.length > 1)
        .map(([basename, owners]) => ({basename, sources: owners.sort()})),
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

/**
 * Accumulate exact host-step counts and sampled typed-progress observations for
 * one phase. `onStep` is called from the trusted step runtime only when stage
 * profiling is enabled; `record` emits one observation per phase so a full-root
 * report stays compact.
 */
export function createStepAttribution(phase, protocol, table) {
  let hostSteps = 0, attributed = 0, unclassified = 0, observedNamespace = null;
  const requests = new Map(), groups = new Map(), groupBases = new Map(), shapes = new Map();
  const unclassifiedRequests = new Map(), unclassifiedReasons = new Map();
  return {
    onStep(_steps, run) {
      hostSteps += 1;
      const sample = typedProgressSample(run);
      if (sample === undefined) return;
      if (observedNamespace === null && sample.runNamespace !== null) observedNamespace = sample.runNamespace;
      shapes.set(sample.progress, (shapes.get(sample.progress) ?? 0) + 1);
      if (typeof sample.request !== 'string') return;
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
        else if (mapped.group === 'unclassified-conflict') reason = 'manifest-conflict';
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
    },
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
 */
export async function createStageProfile({directory, execution, rawDetail = false, manifestPaths = [], artifact, receiptPaths = []}) {
  const {createCompilerProfile} = await import('./compiler_profile.mjs');
  const receipts = receiptPaths.map(readReceipt);
  const receipt = receipts.find(candidate => artifact !== undefined && candidate.artifactSha256 === artifact.sha256) ?? receipts[0];
  const table = loadStageManifests(manifestPaths, {artifactSha256: artifact?.sha256 ?? null, receipt});
  const profile = await createCompilerProfile({directory, execution, rawDetail});
  const open = [];
  let finished = false;
  const api = {
    profile,
    runDirectory: profile.runDirectory,
    reportPath: profile.reportPath,
    manifestTable: table,
    get finished() {return finished;},
    span(name, details = {}, options = {}) {
      const token = profile.begin(name, details, options);
      open.push({token, name});
      return token;
    },
    end(token, status = 'completed', details = {}) {
      const top = open.at(-1);
      if (top === undefined || top.token !== token) throw Error('Stage span stack violation: ' + (top?.name ?? 'empty'));
      open.pop();
      profile.end(token, status, details);
    },
    record(observation) {profile.record(observation);},
    fail(error) {
      if (finished) return;
      const message = error instanceof Error ? error.message : String(error);
      while (open.length > 0) {
        const top = open.pop();
        profile.end(top.token, 'failed', {closeReason: 'candidate host terminated', error: message});
      }
      profile.finish('failed', error);
      finished = true;
    },
    finish(status = 'completed', error) {
      if (finished) return profile.reportPath;
      while (open.length > 0) {
        const top = open.pop();
        profile.end(top.token, status === 'completed' ? 'aborted' : 'failed',
          {closeReason: 'stage profile finished with span still open'});
      }
      profile.finish(status, error);
      finished = true;
      return profile.reportPath;
    },
  };
  profile.record({
    kind: 'stage-group-metadata', scope: 'diagnostic stage report', name: 'compiler-stage-groups',
    values: Object.fromEntries(stageGroupMetadata.map(group => [group.name, group.measurement])),
    source: 'evals/compiler_stage_profile.mjs',
    details: {schemaVersion: STAGE_PROFILE_SCHEMA_VERSION, groups: stageGroupMetadata,
      attractionNote: 'explicit spans, exact counters and sampled chunk-boundary attribution are separate evidence types and are never added together'},
  });
  if (table.provenance.length > 0) profile.record({
    kind: 'stage-attribution-table', scope: 'canonical generator manifest', name: 'typed-request-groups',
    values: {requestConstructors: table.requestToGroup.size, conflicts: table.conflicts.length},
    source: 'typed-step generator manifest',
    details: {manifests: table.provenance, conflicts: table.conflicts,
      artifact: artifact ?? null, receipt: receipt === undefined ? null : {path: receipt.path, sha256: receipt.sha256,
        artifactSha256: receipt.artifactSha256, provenancePath: receipt.provenancePath}},
  });
  return api;
}
