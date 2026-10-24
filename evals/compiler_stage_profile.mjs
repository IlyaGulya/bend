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
  {name: 'check-publication', measurement: 'unreachable-in-candidate-host',
    prerequisite: 'no inspection entry is invoked by the candidate host or bootstrap worker; runCheckedInspectionSteps accepts a span at that boundary if a caller invokes it'},
  {name: 'emit-catalog-lowering', measurement: 'typed-progress-sample', provider: 'canonical modules backend_lower/lower_catalog'},
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

// Exact module -> stage group table. This is declared metadata keyed by the
// canonical module recorded in the generator manifest, not a name heuristic.
const moduleGroup = new Map([
  ['backend_lower.bend', 'emit-catalog-lowering'],
  ['lower_catalog.bend', 'emit-catalog-lowering'],
  ['descriptor_nf.bend', 'emit-descriptor-nf'],
  ['c_backend_layout.bend', 'emit-layouts'],
  ['c_backend_sharing.bend', 'emit-sharing'],
  ['js_emit.bend', 'emit-render-js'],
  ['js_backend.bend', 'emit-render-js'],
  ['c_emit.bend', 'emit-render-c'],
  ['c_emit_core.bend', 'emit-render-c'],
  ['c_backend.bend', 'emit-render-c'],
  ['c_backend_physical.bend', 'emit-render-c'],
  ['c_backend_link.bend', 'emit-link-planning'],
  ['emitter.bend', 'emit-emitter-entry'],
  ['checker.bend', 'check-signature-body'],
  ['checker_arena.bend', 'check-signature-body'],
  ['checker_ir.bend', 'check-signature-body'],
  ['template.bend', 'template-expand'],
]);

const coarseGroup = protocol =>
  protocol === 'Checker' ? 'check-signature-body'
    : protocol === 'Template' ? 'template-expand'
      : protocol === 'Emitter' ? 'emit-emitter-entry' : 'unclassified';

const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');

function constructorTag(value) {
  if (value === null || typeof value !== 'object' || Array.isArray(value) || typeof value.$ !== 'string') return undefined;
  const at = value.$.lastIndexOf('.');
  return value.$.slice(at + 1);
}

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
export function loadStageManifests(paths) {
  const requestToGroup = new Map();
  const provenance = [];
  const conflicts = [];
  for (const path of paths ?? []) {
    const bytes = readFileSync(path);
    const document = JSON.parse(bytes.toString('utf8'));
    const protocol = protocolOf(document);
    if (protocol === undefined) throw Error('Stage manifest has no typed Run protocol: ' + path);
    const sourceOf = new Map();
    for (const declaration of document.canonicalComposition?.declarations ?? []) {
      if (declaration?.kind !== 'def' || typeof declaration.source !== 'string') continue;
      // Requests use the composed declaration name; the canonical name is kept
      // as an additional exact key for manifests that are not composed.
      if (typeof declaration.name === 'string') sourceOf.set(declaration.name, declaration.source);
      if (typeof declaration.canonicalName === 'string') sourceOf.set(declaration.canonicalName, declaration.source);
    }
    const definitions = [];
    const addRequest = name => {
      const tag = protocol + 'Request_' + name;
      const source = sourceOf.get(name) ?? null;
      const groupName = source === null ? coarseGroup(protocol) : moduleGroup.get(source.split('/').at(-1)) ?? 'module:' + source.split('/').at(-1);
      const previous = requestToGroup.get(tag);
      if (previous !== undefined && previous.group !== groupName) {
        conflicts.push({tag, previous: previous.group, next: groupName, manifest: path});
        requestToGroup.set(tag, {group: 'unclassified-conflict', source: null, protocol});
      } else requestToGroup.set(tag, {group: groupName, source, protocol});
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
    // exact source-module provenance, so the same request tag stays classifiable.
    for (const declaration of document.canonicalComposition?.declarations ?? []) {
      if (declaration?.kind !== 'def') continue;
      if (typeof declaration.name === 'string' && !definitions.includes(declaration.name)) addRequest(declaration.name);
      if (typeof declaration.canonicalName === 'string' && !definitions.includes(declaration.canonicalName)) addRequest(declaration.canonicalName);
    }
    provenance.push({
      path: realpathSync(path), sha256: sha256(bytes), protocol,
      requestConstructors: definitions.length,
      definitionsWithCanonicalSource: definitions.filter(name => sourceOf.has(name)).length,
      canonicalSources: [...new Set(sourceOf.values())].sort(),
      canonicalSourceSha256: document.canonicalComposition?.inputs,
      generator: document.generationConfig?.generator,
      loweringSourceSha256: document.loweringSourceSha256,
    });
  }
  return {requestToGroup, provenance, conflicts};
}

/**
 * Read-only typed progress observation. It follows at most 64 erased `Bound`
 * wrappers and reports constructor tags; request payloads are never inspected.
 * This is an operational sample of where the typed Run stands after a bounded
 * chunk, not a duration, a call count, or a semantic interpretation.
 */
export function typedProgressSample(run) {
  let progress = run?.progress;
  for (let depth = 0; depth < 64; depth += 1) {
    const tag = constructorTag(progress);
    if (tag === undefined) return undefined;
    // Generated progress constructors carry their protocol prefix
    // (CheckerPending, EmitterDirect, ...); the suffix is the ABI name.
    const kind = tag.replace(/^(?:Checker|Template|Emitter)/, '');
    if (kind === 'Finished') return {progress: kind};
    if (kind === 'Pending' || kind === 'Direct') {
      // A Direct progress erases its scheduling request when the source invoke
      // runs, so only the progress shape is visible at that boundary.
      const envelope = progress.request;
      const request = envelope?.request;
      return {
        progress: kind,
        groupConstructor: constructorTag(envelope) ?? null,
        request: constructorTag(request) ?? null,
      };
    }
    if (kind === 'Bound') {progress = progress.inner; continue;}
    if (kind === 'RunState') {progress = progress.progress; continue;}
    return {progress: kind, unparsed: true};
  }
  return {progress: 'depth-limit'};
}

/**
 * Accumulate exact host-step counts and sampled typed-progress observations for
 * one phase. `onStep` is called from the trusted step runtime only when stage
 * profiling is enabled; `record` emits one observation per phase so a full-root
 * report stays compact.
 */
export function createStepAttribution(phase, protocol, table, exact) {
  let hostSteps = 0, attributed = 0, unclassified = 0;
  const requests = new Map(), groups = new Map(), shapes = new Map(), unclassifiedRequests = new Map();
  return {
    onStep(_steps, run) {
      hostSteps += 1;
      const sample = typedProgressSample(run);
      if (sample === undefined) return;
      shapes.set(sample.progress, (shapes.get(sample.progress) ?? 0) + 1);
      if (typeof sample.request !== 'string') return;
      attributed += 1;
      requests.set(sample.request, (requests.get(sample.request) ?? 0) + 1);
      const mapped = table?.requestToGroup?.get(protocol + 'Request_' + sample.request.replace(/^[A-Za-z]+Request_/, ''));
      const group = mapped?.group ?? 'unclassified';
      if (group === 'unclassified') {
        unclassified += 1;
        unclassifiedRequests.set(sample.request, (unclassifiedRequests.get(sample.request) ?? 0) + 1);
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
      if (exact !== undefined) profile.record({
        kind: 'phase-exact-counters', scope: 'candidate host', name: phase, values: exact,
        source: 'candidate_host.ts', details: {phase},
      });
      if (shapes.size > 0) profile.record({
        kind: 'typed-progress-samples', scope: 'host-visible typed chunk boundary',
        name: phase + '-typed-progress', units: 'attributed-boundary-samples',
        values: {attributedBoundarySamples: attributed,
          ...Object.fromEntries([...groups.entries()].sort(([a], [b]) => a.localeCompare(b)))},
        source: 'generated typed Run progress + canonical request constructors',
        details: {
          phase,
          granularity: 'sample of the typed progress after each bounded host step; up to 64 native advances may have run since the previous sample, and only the request pending at the boundary is observed',
          evidenceType: 'operational attribution, not a duration or exact call count',
          progressShapes: Object.fromEntries([...shapes.entries()].sort(([a], [b]) => a.localeCompare(b))),
          requestSamples: Object.fromEntries([...requests.entries()].sort(([a], [b]) => a.localeCompare(b))),
          unclassifiedSamples: unclassified,
          unclassifiedRequests: Object.fromEntries([...unclassifiedRequests.entries()].sort(([a], [b]) => a.localeCompare(b))),
          mapping: table === undefined || table.provenance.length === 0 ? 'no generator manifest supplied; request tags are exact but ungrouped' : 'exact generator manifest request constructors + canonical composition modules',
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
        source: 'native_compiler_host.c NATIVE_BEGIN',
        details: {phase: row.phase, phaseTraceVersion: row.phaseTraceVersion},
      });
      continue;
    }
    if (trimmed.startsWith('NATIVE_FUEL ')) {
      const row = JSON.parse(trimmed.slice('NATIVE_FUEL '.length));
      observations.push({
        kind: 'native-fuel-exact', scope: 'native child process', name: 'parser-fuel-' + row.sourceOrdinal,
        units: 'milliseconds',
        values: {elapsedMs: row.elapsedMs, cells: row.cells, processPeakRssBeforeBytes: row.processPeakRssBeforeBytes,
          processPeakRssAfterBytes: row.processPeakRssAfterBytes},
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
        units: 'milliseconds',
        values: {
          elapsedMs: row.elapsedMs, userCpuMs: row.userCpuMs, systemCpuMs: row.systemCpuMs,
          ...(row.chunkAdvances === undefined ? {} : {chunkAdvances: row.chunkAdvances, chunkQuantum: row.chunkQuantum}),
        },
        source: 'native_compiler_host.c NATIVE_PHASE (getrusage RUSAGE_SELF + monotonic wall)',
        details: {
          granularity: 'coarse phase boundary; CPU is process-wide including compute threads and is not exclusive across overlapping phases',
          ...(row.modules === undefined ? {} : {modules: row.modules, sourceBytes: row.sourceBytes,
            foreignBytes: row.foreignBytes, eagerFuelCells: row.eagerFuelCells, fuelBuildMs: row.fuelBuildMs}),
        },
      });
      continue;
    }
    if (trimmed.startsWith('NATIVE_RESULT ')) {
      const row = JSON.parse(trimmed.slice('NATIVE_RESULT '.length));
      observations.push({
        kind: 'native-result', scope: 'native child process', name: 'result',
        values: {bytes: row.bytes, modules: row.modules},
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
export async function createStageProfile({directory, execution, rawDetail = false, manifestPaths = []}) {
  const {createCompilerProfile} = await import('./compiler_profile.mjs');
  const table = loadStageManifests(manifestPaths);
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
    details: {manifests: table.provenance, conflicts: table.conflicts},
  });
  return api;
}
