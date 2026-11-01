// Diagnostic-only, read-only census of the authenticated emitter trace seam.
// Never advance a Run, invoke a source closure, or retain a native runtime value.
// Exact trace brackets and host-boundary samples are deliberately separate.
import {createHash} from 'node:crypto';
import {readFileSync} from 'node:fs';
import {performance} from 'node:perf_hooks';
import {loadStageManifests, traceTableFor, typedTraceEvents, typedProgressSample,
  TRACE_PROTOCOL_VERSION, TRACE_QUANTUM} from './compiler_stage_profile.mjs';

export const WORK_CENSUS_SCHEMA_VERSION = 1;
export const WORK_CENSUS_STOP_CODE = 'ERR_COMPILER_WORK_CENSUS_STOP';
export class WorkCensusStop extends Error {
  constructor(reason, snapshot) {
    super('Intentional bounded work census stop: ' + reason);
    this.name = 'WorkCensusStop';
    this.code = WORK_CENSUS_STOP_CODE;
    this.reason = reason;
    this.snapshot = snapshot;
  }
}
export const isWorkCensusStop = error => error?.code === WORK_CENSUS_STOP_CODE
  && error?.name === 'WorkCensusStop';

const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const tagOf = value => typeof value?.$ === 'string' ? value.$ : null;
const boundedText = value => typeof value === 'string' ? value.slice(0, 512) : null;
const integer = (options, key, fallback, max) => {
  const value = options[key] ?? fallback;
  if (!Number.isSafeInteger(value) || value < 1 || value > max)
    throw Error('Work census ' + key + ' must be an integer in [1, ' + max + ']');
  return value;
};
const identityOf = root => ({site: root.site, stage: root.stage, source: root.source,
  canonicalName: root.canonicalName, name: root.name, request: root.request,
  canonicalDeclarationSha256: root.canonicalDeclarationSha256,
  composedDeclarationSha256: root.composedDeclarationSha256});

/**
 * options.table is the authenticated result of loadStageManifests, or supply
 * manifestPaths and binding={receipt,artifactSha256} to that existing loader.
 * The table may use a native receipt binding authenticated by the parent; this
 * collector neither reads nor fabricates a compiled-JS receipt. Exactly one
 * verified emitter trace table is required. The caller must bind the receipt
 * to the actual image being observed, not a previous generated JS.
 *
 * sampleEvery controls stack samples only: all trace events, Progress forms and
 * pending tags at EVERY host boundary are counted. maxSteps/maxWallMs stop at a
 * host boundary (before its step call); they cannot interrupt one native step.
 * Limits are pinned in report.config/configSha256. No polling or scheduler,
 * fuel, quantum, source result, or export changes are made by this observer.
 */
export function createWorkCensus(options = {}) {
  if (options === null || typeof options !== 'object' || Array.isArray(options))
    throw Error('Work census options must be an object');
  const config = Object.freeze({
    protocolVersion: TRACE_PROTOCOL_VERSION, quantum: TRACE_QUANTUM,
    sampleEvery: integer(options, 'sampleEvery', 64, 1000000000),
    maxSamples: integer(options, 'maxSamples', 256, 4096),
    maxStackDepth: integer(options, 'maxStackDepth', 4096, 65536),
    maxPendingRequests: integer(options, 'maxPendingRequests', 256, 4096),
    maxOpenTraces: integer(options, 'maxOpenTraces', 4096, 65536),
    maxSteps: integer(options, 'maxSteps', 1000000, 1000000000),
    maxWallMs: integer(options, 'maxWallMs', 60000, 3600000),
    progressWrapperLimit: 64,
  });
  const manifest = options.table ?? loadStageManifests(options.manifestPaths, options.binding);
  const candidates = (manifest?.traceTables ?? []).filter(table => table.status !== 'absent');
  if (candidates.length !== 1) throw Error('Work census requires exactly one emitter trace manifest');
  const trace = traceTableFor(manifest, candidates[0].namespace);
  if (trace.status !== 'verified')
    throw Error('Work census trace authentication failed: ' + trace.reasons.join('; '));
  if (trace.roots.length > 128) throw Error('Work census supports at most 128 marked roots');
  const configSha256 = hash(JSON.stringify(config));
  const collectorSha256 = hash(readFileSync(new URL(import.meta.url)));
  const protocolHelperSha256 = hash(readFileSync(new URL('./compiler_stage_profile.mjs', import.meta.url)));
  const nominal = name => trace.namespace === null ? name : trace.namespace + '.' + name;
  const roots = new Map(trace.roots.map(root => [root.site, {
    ...identityOf(root), begins: 0, ends: 0, open: 0, maxOpen: 0, closedInclusiveWallMs: 0,
  }]));
  const rootRequests = new Map(trace.roots.map(root => [root.request, root]));
  const open = [], samples = [], pending = new Map();
  const forms = {Finished: 0, Pending: 0, Direct: 0, unknown: 0, 'depth-limit': 0};
  const outerForms = {Finished: 0, Pending: 0, Direct: 0, Bound: 0, unknown: 0};
  const stackStats = {samples: 0, exact: 0, truncated: 0, unavailable: 0,
    maxObservedDepth: 0, sumExactDepth: 0};
  let state = 'observing', reason = null, startedMs = null, lastMs = null;
  let boundaries = 0, runStates = 0, spanBoundaries = 0, emptySpanBoundaries = 0;
  let begins = 0, ends = 0, maxOpen = 0, lastStep = null, finishSteps = null;
  let unknownRequests = 0, pendingOverflowSamples = 0, sampleCandidates = 0, omittedSamples = 0;
  let lastSnapshot = null, errorMessage = null;

  function fail(message) {
    state = 'invalid';
    reason = message;
    const error = Error('Invalid work census trace: ' + message);
    error.code = 'ERR_COMPILER_WORK_CENSUS_TRACE';
    throw error;
  }
  function stackSample(run) {
    if (tagOf(run) !== nominal('EmitterRunState'))
      return {depth: null, exact: false, reason: 'RunSpan hides its stack in an uninspected next closure'};
    let stack = run.stack, depth = 0;
    for (;;) {
      const tag = tagOf(stack);
      if (tag === nominal('EmitterStackDone')) return {depth, exact: true, reason: null};
      if (tag !== nominal('EmitterStackMore') && tag !== nominal('EmitterStackTraced'))
        return {depth, exact: false, reason: 'unknown or missing native stack constructor'};
      if (depth === config.maxStackDepth)
        return {depth, exact: false, reason: 'stack traversal limit; depth is a lower bound'};
      depth += 1;
      stack = stack.rest;
    }
  }
  function retainSample(snapshot, run) {
    sampleCandidates += 1;
    const stack = stackSample(run);
    stackStats.samples += 1;
    if (stack.depth === null) stackStats.unavailable += 1;
    else {
      stackStats.maxObservedDepth = Math.max(stackStats.maxObservedDepth, stack.depth);
      if (stack.exact) {stackStats.exact += 1; stackStats.sumExactDepth += stack.depth;}
      else stackStats.truncated += 1;
    }
    const sample = {...snapshot, stack};
    if (samples.length < config.maxSamples) samples.push(sample);
    else omittedSamples += 1;
    return sample;
  }
  function countPending(sample) {
    if (sample?.progress !== 'Pending' && sample?.progress !== 'Direct') return;
    const tag = sample.request;
    if (typeof tag !== 'string' || tag.length > 512) {unknownRequests += 1; return;}
    // Strip no guessed prefix. The receipt-authenticated encoding alone permits
    // converting a compiled bare request into its manifest's source namespace.
    const key = trace.tagEncoding === 'canonical-compiled-js'
      ? trace.sourceNamespace + '.' + tag : tag;
    const root = rootRequests.get(key);
    const owner = manifest.requestToGroup.get(key);
    if (!root && (!owner || owner.artifactBinding !== 'verified'
        || owner.basis !== 'verified-canonical-source')) {
      unknownRequests += 1;
      return;
    }
    let row = pending.get(tag);
    if (!row) {
      if (pending.size === config.maxPendingRequests) {pendingOverflowSamples += 1; return;}
      row = {requestTag: tag, manifestRequest: key, samples: 0, pending: 0, direct: 0,
        identity: root ? identityOf(root) : {source: owner.source, canonicalName: null,
          declarationIdentity: 'not exposed by shared request table; request tag and source only'},
        evidence: 'host-boundary-sample-not-call-count'};
      pending.set(tag, row);
    }
    row.samples += 1;
    row[sample.progress === 'Pending' ? 'pending' : 'direct'] += 1;
  }
  function onStep(step, run) {
    if (state !== 'observing') throw Error('Work census received a boundary after ' + state);
    if (!Number.isSafeInteger(step) || step !== boundaries)
      fail('expected contiguous host-step ordinal ' + boundaries + ', observed ' + String(step));
    const now = performance.now();
    if (startedMs === null) startedMs = now;
    lastMs = now;
    lastStep = step;
    boundaries += 1;
    const tag = tagOf(run);
    // Even a rejected event leaves a bounded snapshot of the failing boundary,
    // rather than silently reporting the previous valid boundary as the last.
    lastSnapshot = {step, elapsedMs: now - startedMs, runTag: boundedText(tag),
      progress: null, openTraceDepth: open.length, openSite: open.at(-1)?.site ?? null};
    if (tag !== nominal('EmitterRunState') && tag !== trace.constructors.run)
      fail('unexpected Run constructor or nominal namespace');
    let sample = null;
    if (tag === trace.constructors.run) {
      spanBoundaries += 1;
      const events = typedTraceEvents(run, trace);
      if (events.status !== 'ok') fail(events.reason ?? 'unreadable trace events');
      if (events.events.length === 0) emptySpanBoundaries += 1;
      for (const event of events.events) {
        const root = roots.get(event.site);
        if (!root) fail('event site is absent from authenticated manifest: ' + event.site);
        if (event.kind === 'begin') {
          if (open.length === config.maxOpenTraces) {
            // This valid Begin is counted, but cannot be retained for pairing.
            // Stop before executing its deferred callee; report the censored site.
            root.begins += 1; root.open += 1; begins += 1;
            root.maxOpen = Math.max(root.maxOpen, root.open);
            state = 'stopped'; reason = 'maxOpenTraces';
            lastSnapshot = {step, elapsedMs: now - startedMs, runTag: tag,
              progress: null, openTraceDepth: open.length + 1, unretainedBeginSite: event.site};
            maxOpen = Math.max(maxOpen, open.length + 1);
            throw new WorkCensusStop(reason, {...lastSnapshot});
          }
          open.push({site: event.site, beginStep: step, beginMs: now - startedMs});
          root.begins += 1; root.open += 1; begins += 1;
          root.maxOpen = Math.max(root.maxOpen, root.open);
          maxOpen = Math.max(maxOpen, open.length);
        } else {
          const top = open.at(-1);
          if (!top || top.site !== event.site)
            fail('End site ' + event.site + ' does not match open site ' + (top?.site ?? 'none'));
          open.pop();
          root.ends += 1; root.open -= 1; ends += 1;
          root.closedInclusiveWallMs += now - startedMs - top.beginMs;
        }
      }
    } else {
      runStates += 1;
      sample = typedProgressSample(run);
      const form = sample?.progress;
      if (Object.hasOwn(forms, form)) forms[form] += 1;
      else forms.unknown += 1;
      const outer = tagOf(run.progress);
      const knownOuter = ['Finished', 'Pending', 'Direct', 'Bound'].find(kind => outer === nominal('Emitter' + kind));
      outerForms[knownOuter ?? 'unknown'] += 1;
      countPending(sample);
    }
    lastSnapshot = {step, elapsedMs: now - startedMs, runTag: tag,
      progress: boundedText(sample?.progress), progressTag: boundedText(sample?.progressTag),
      requestTag: boundedText(sample?.request), openTraceDepth: open.length,
      openSite: open.at(-1)?.site ?? null};
    const stopReason = boundaries >= config.maxSteps ? 'maxSteps'
      : now - startedMs >= config.maxWallMs ? 'maxWallMs' : null;
    if (step % config.sampleEvery === 0 || stopReason !== null)
      lastSnapshot = retainSample(lastSnapshot, run);
    if (stopReason !== null) {
      state = 'stopped'; reason = stopReason;
      throw new WorkCensusStop(reason, {...lastSnapshot,
        ...(lastSnapshot.stack ? {stack: {...lastSnapshot.stack}} : {})});
    }
  }
  function onFinish(_value, steps) {
    if (state !== 'observing') fail('finish received after ' + state);
    if (steps !== boundaries) fail('finish step count differs from observed contiguous boundaries');
    if (open.length !== 0) fail('Run finished with ' + open.length + ' unmatched Begin events');
    finishSteps = steps;
    lastMs = performance.now();
    state = 'finished';
  }
  function onError(error, steps) {
    finishSteps = Number.isSafeInteger(steps) ? steps : null;
    if (state === 'stopped' && isWorkCensusStop(error)) return;
    if (state !== 'invalid') {state = 'errored'; reason = 'runtime-or-observer-error';}
    // Retain no error object: it could itself hold an arbitrary native value.
    errorMessage = boundedText(typeof error?.message === 'string' ? error.message : 'non-Error thrown');
    lastMs = performance.now();
  }
  function report() {
    return {
      kind: 'compiler-work-census', schemaVersion: WORK_CENSUS_SCHEMA_VERSION,
      diagnosticOnly: true, acceptanceEvidence: false, config: {...config}, configSha256,
      provenance: {collectorSha256, protocolHelperSha256,
        generationManifestSha256: trace.generationManifestSha256,
        namespace: trace.namespace, sourceNamespace: trace.sourceNamespace, tagEncoding: trace.tagEncoding,
        selfAuthentication: trace.selfAuthentication, artifactBinding: trace.artifactBinding,
        manifests: manifest.provenance},
      outcome: {state, reason, errorMessage, incomplete: state !== 'finished',
        censored: state !== 'finished', validPairingSoFar: state !== 'invalid'},
      window: {startHostStep: startedMs === null ? null : 0, lastObservedHostStep: lastStep,
        elapsedMs: startedMs === null ? null : lastMs - startedMs, runtimeReportedSteps: finishSteps,
        stopBoundaryAdvanced: state === 'stopped' ? false : null,
        scope: 'first observed emitter boundary through last observation; not entire compiler lifetime',
        limitEnforcement: 'host boundaries only; cannot interrupt one native step'},
      exactTrace: {begins, ends, openCalls: begins - ends, maxOpenCalls: maxOpen,
        spanBoundaries, emptySpanBoundaries,
        coverage: state === 'finished' ? 'complete marked-call census for this observed Run'
          : 'prefix only; open calls have no fabricated End',
        roots: [...roots.values()].map(root => ({...root})),
        openNesting: open.map(frame => ({...frame})),
        unretainedOpenCalls: begins - ends - open.length,
        durationScope: 'closed inclusive host-wall spans including nested calls and observer overhead; not exclusive CPU'},
      hostBoundaries: {observed: boundaries, runStates, spanBoundaries,
        progressForms: {...forms}, outerProgressForms: {...outerForms},
        evidence: 'all observed host boundaries only; not all internal64 transitions'},
      pendingRequests: {rows: [...pending.values()].map(row => ({...row, identity: {...row.identity}})),
        unknownSamples: unknownRequests, overflowSamples: pendingOverflowSamples,
        censored: pendingOverflowSamples > 0, evidence: 'bounded host-boundary histogram, not invocation counts'},
      stackDepth: {...stackStats, evidence: 'bounded linked-stack samples; no closures inspected',
        truncatedDepthsAreLowerBounds: true},
      samples: samples.map(sample => ({...sample, stack: {...sample.stack}})),
      sampleRetention: {candidates: sampleCandidates, retained: samples.length, omitted: omittedSamples,
        policy: 'first maxSamples at fixed sampleEvery plus stop boundary; aggregates continue after cap'},
      lastSnapshot: lastSnapshot === null ? null : {...lastSnapshot,
        ...(lastSnapshot.stack ? {stack: {...lastSnapshot.stack}} : {})},
      unknown: {
        internalTransitions: 'native quantum64 transitions between host boundaries are not counted',
        allocations: 'no object allocation or retained-heap census is observable here',
        unmarkedCalls: 'only manifest-marked Begin/End calls have invocation counts',
        directRequests: 'Direct erases its request; no thunk is invoked to reconstruct identity',
        hiddenState: 'RunSpan next, source continuations, source arenas and closure captures are opaque',
        semanticVsAdministrativeCpu: 'forms and marked brackets do not establish exclusive semantic/CPS CPU cost',
        birProgram: 'this collector does not capture BIR; Pending visibility is not guaranteed by a Begin span',
      },
    };
  }
  return {onStep, onFinish, onError, report};
}
