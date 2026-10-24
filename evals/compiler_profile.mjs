// Opt-in diagnostic scoped profiler for the official compiler producers.
//
// This collector is evidence plumbing, not an acceptance signal and not a
// benchmark. It records three distinct kinds of evidence and never converts
// one into another:
//
//   * coarse explicit spans: monotonic wall, process-wide CPU boundary delta,
//     and process.memoryUsage boundary snapshots;
//   * sampled attribution: optional V8 inspector CPU (1 ms) and statistical
//     allocation (4 MiB) profiles for explicitly sampled spans;
//   * exact counters/observations supplied by the producer (definition,
//     segment, cache and chunk counts, or child-process RUSAGE rows).
//
// A boundary heapUsed delta is not allocation or retained bytes. RSS is
// process-wide. process.cpuUsage covers every thread in this process, not
// child processes; child CPU requires its own rusage receipt. Nested or
// overlapping spans have overlapping CPU deltas and no exclusive CPU is
// invented. Retained/live bytes and child rusage that the host cannot observe
// stay null with an explicit reason.
//
// Import is side-effect free. Inspector is loaded lazily and only when a span
// explicitly requests sampling, so Bun/Node runners that never profile pay no
// startup cost. The no-profile producer path never imports this module.

import {randomUUID} from 'node:crypto';
import {closeSync, mkdirSync, mkdtempSync, openSync, renameSync, writeFileSync, writeSync} from 'node:fs';
import {join, resolve} from 'node:path';
import {isMainThread, threadId} from 'node:worker_threads';

export const COMPILER_PROFILE_SCHEMA_VERSION = 1;
const profilerVersion = 'compiler-profile/1';
const statuses = new Set(['completed', 'failed', 'aborted']);

export const compilerProfileLimits = Object.freeze([
  'diagnostic only: profile files do not certify acceptance, bootstrap green, fixedpoint or benchmark results',
  'span CPU is a process.cpuUsage boundary delta over all threads in this process; child processes are excluded and require their own rusage receipt; nested or overlapping spans overlap and no exclusive CPU is derived',
  'boundary heapUsed deltas are not allocation, live or retained bytes; RSS is process-wide',
  'sampled CPU/allocation profiles are statistical, include collected objects for allocation, and have no Bend source map',
  'child-process CPU/RSS exists only where the producer records a child receipt (e.g. NATIVE_PHASE or llvm time -lp); it is never inferred',
  'rawDetail streams every event to events.jsonl; fine spans/observations are aggregated in memory, but JSON serialization and I/O overhead remains and is not measured',
  'fullroot overhead/control and complete stage coverage are not established by a tiny smoke run',
]);

function fail(message) {
  throw new Error('compiler profile: ' + message);
}

function normalizeStatus(status, fallback) {
  if (status === undefined) return fallback;
  if (status === 'complete') status = 'completed';
  if (!statuses.has(status)) fail('invalid status ' + JSON.stringify(status));
  return status;
}

function errorText(error) {
  if (error === undefined || error === null) return null;
  return error instanceof Error ? error.message + (error.stack ? '\n' + error.stack : '') : String(error);
}

function timeSnapshot() {
  return {monotonicMs: performance.now(), unixMs: Date.now()};
}

function cpuSnapshot() {
  const usage = process.cpuUsage();
  return {userMs: usage.user / 1000, systemMs: usage.system / 1000};
}

function cpuDelta(before, after) {
  return {
    kind: 'process-boundary-delta',
    scope: 'process.cpuUsage: every thread in this process, including worker threads; child processes have separate rusage and are excluded; not exclusive to this span and overlapping for nested spans',
    userMs: after.userMs - before.userMs,
    systemMs: after.systemMs - before.systemMs,
  };
}

function memorySnapshot() {
  const usage = process.memoryUsage();
  return {
    scope: 'process.memoryUsage at a span boundary: RSS is process-wide; heapUsed is a boundary sample, not allocation, live or retained bytes',
    rssBytes: usage.rss,
    heapTotalBytes: usage.heapTotal,
    heapUsedBytes: usage.heapUsed,
    externalBytes: usage.external,
    arrayBuffersBytes: usage.arrayBuffers,
  };
}

function memoryDelta(before, after) {
  return {
    kind: 'boundary-snapshot-delta',
    scope: before.scope,
    heapUsedDeltaBytes: after.heapUsedBytes - before.heapUsedBytes,
    rssDeltaBytes: after.rssBytes - before.rssBytes,
    caveat: 'a boundary delta is not allocation or retained bytes; it can miss peaks and includes uncollected garbage',
  };
}

function label(value) {
  return String(value).replace(/[^A-Za-z0-9_.-]/g, '_').slice(0, 96) || 'span';
}

function serializable(value, seen = new Set()) {
  if (typeof value === 'bigint') return value.toString() + 'n';
  if (typeof value === 'function') fail('observation contains a function');
  if (value !== null && typeof value === 'object') {
    if (seen.has(value)) fail('observation contains a cycle');
    seen.add(value);
    try {
      if (Array.isArray(value)) return value.map(item => serializable(item, seen));
      const result = {};
      for (const [key, item] of Object.entries(value)) result[key] = serializable(item, seen);
      return result;
    } finally {
      seen.delete(value);
    }
  }
  if (typeof value === 'number' && !Number.isFinite(value)) return String(value);
  return value;
}

/**
 * Create the collector. The factory is async only because inspector sampling
 * is loaded lazily; span operations afterwards are synchronous.
 */
export async function createCompilerProfile(config = {}) {
  if (typeof config.directory !== 'string' || !config.directory) fail('createCompilerProfile requires a directory');
  const parent = resolve(config.directory);
  mkdirSync(parent, {recursive: true});
  const runDirectory = mkdtempSync(join(parent, `profile-${process.pid}-thread-${threadId}-`));
  const rawDetail = config.rawDetail === true;
  const startedAt = new Date().toISOString();
  const startMonotonicMs = performance.now();
  const samplingConfig = config.sampling === true ? {}
    : config.sampling && typeof config.sampling === 'object' ? config.sampling : null;
  const cpuIntervalUs = samplingConfig?.cpuIntervalUs ?? 1000;
  const allocationIntervalBytes = samplingConfig?.allocationIntervalBytes ?? 4194304;
  if (!Number.isSafeInteger(cpuIntervalUs) || cpuIntervalUs < 1) fail('sampling.cpuIntervalUs must be a positive integer');
  if (!Number.isSafeInteger(allocationIntervalBytes) || allocationIntervalBytes < 1) fail('sampling.allocationIntervalBytes must be a positive integer');
  const execution = config.execution === undefined ? null : serializable(config.execution);
  if (rawDetail) mkdirSync(join(runDirectory, 'sampling'), {recursive: true});

  let rawFD = rawDetail ? openSync(join(runDirectory, 'events.jsonl'), 'wx') : undefined;
  let rawEventsWritten = 0;
  const raw = row => {
    if (rawFD === undefined) return;
    writeSync(rawFD, JSON.stringify(serializable(row)) + '\n');
    rawEventsWritten += 1;
  };

  const spans = [];
  const observations = [];
  const stack = [];
  const sampleRecords = [];
  const lastCompletedSpans = [];
  const recentObservations = [];
  const spanStatusCounts = {completed: 0, failed: 0, aborted: 0};
  const fineSpans = {count: 0, completed: 0, failed: 0, aborted: 0, summedWallMsNotExclusive: 0,
    byName: {}, otherNames: 0, failedSamples: [], failedSamplesOmitted: 0};
  const fineObservations = {count: 0, kinds: {}, otherKinds: 0};
  let topLevelSpanCount = 0;
  let spanSequence = 0;
  let observationSequence = 0;
  let activeSample = null;
  let finished = false;
  let summary;
  let sampler = {status: samplingConfig ? 'unavailable' : 'disabled', reason: null, session: null, post: null};

  if (samplingConfig) {
    try {
      // Reuse the existing inspector implementation and its sampling constants.
      const helper = await import('./selfhost_cpu_profile.mjs');
      const {Session} = await import('node:inspector');
      const session = new Session();
      session.connect();
      helper.inspectorPost(session, 'Profiler.enable');
      helper.inspectorPost(session, 'Profiler.setSamplingInterval', {interval: cpuIntervalUs});
      helper.inspectorPost(session, 'HeapProfiler.enable');
      sampler = {status: 'ready', reason: null, session, post: helper.inspectorPost};
      mkdirSync(join(runDirectory, 'sampling'), {recursive: true});
    } catch (error) {
      sampler = {status: 'unavailable', reason: errorText(error), session: null, post: null};
    }
  }

  const identity = {pid: process.pid, parentPid: process.ppid, threadId, isMainThread};
  const profileId = randomUUID();
  const run = {
    schemaVersion: COMPILER_PROFILE_SCHEMA_VERSION,
    kind: 'compiler-profile',
    profilerVersion,
    diagnosticOnly: true,
    acceptanceEvidence: false,
    status: 'running',
    execution,
    identity,
    runtime: {
      name: typeof Bun !== 'undefined' ? 'bun' : 'node',
      versions: {...process.versions},
      platform: process.platform,
      arch: process.arch,
      execPath: process.execPath,
      execArgv: [...process.execArgv],
    },
    runDirectory,
    startedAt,
    startMonotonicMs,
    rawDetail,
    checkpointPath: join(runDirectory, 'checkpoint.json'),
    measurement: {
      wall: {kind: 'monotonic performance.now', scope: 'collector process'},
      cpu: {kind: 'process.cpuUsage boundary delta', scope: 'every thread in this process; child processes excluded; not exclusive across overlapping spans'},
      memory: {kind: 'process.memoryUsage boundary snapshot', scope: 'RSS process-wide; heapUsed boundary sample, not allocation or retained bytes'},
      sampling: samplingConfig
        ? {kind: 'V8 inspector', cpu: {unit: 'us', intervalUs: cpuIntervalUs, kind: 'statistical CPU stacks'},
            allocation: {unit: 'bytes', intervalBytes: allocationIntervalBytes, kind: 'statistical allocation samples, including collected objects'}}
        : null,
    },
    sampling: {config: samplingConfig ? {cpuIntervalUs, allocationIntervalBytes} : null, status: sampler.status, reason: sampler.reason, spans: []},
    limits: [...compilerProfileLimits],
  };
  writeFileSync(join(runDirectory, 'run.json'), JSON.stringify(run, null, 2) + '\n', {flag: 'wx'});

  // Coarse, atomic crash evidence. Fine raw events are streamed to events.jsonl
  // and are deliberately not checkpointed, so this file stays bounded.
  function writeCheckpoint(finalStatus, finalError) {
    const cpu = process.cpuUsage(), memory = process.memoryUsage();
    const checkpoint = {
      schemaVersion: COMPILER_PROFILE_SCHEMA_VERSION,
      kind: 'compiler-profile-checkpoint',
      profilerVersion,
      profileId,
      execution,
      identity,
      runDirectory,
      checkpointPath: run.checkpointPath,
      rawDetail,
      status: finalStatus ?? 'running',
      error: finalError ?? null,
      updatedAt: new Date().toISOString(),
      elapsedMs: performance.now() - startMonotonicMs,
      process: {
        cpu: {kind: 'process-boundary-delta', scope: 'every thread in this process; child processes excluded',
          userMs: cpu.user / 1000, systemMs: cpu.system / 1000},
        memory: memorySnapshot(),
      },
      activeSpans: stack.filter(span => !span.excluded).map(span => ({
        id: span.id, parentId: span.parentId, name: span.name, details: span.details,
        startedAt: span.startedAt, startedMonotonicMs: span.startedMonotonicMs,
        ...(span.sample ? {sample: {...span.sample}} : {})})),
      activeSpanCount: stack.length,
      counts: {
        spans: spanSequence, coarseSpans: spans.length, fineSpans: fineSpans.count,
        observations: observationSequence, retainedObservations: observations.length,
        fineObservations: fineObservations.count,
      },
      lastCompletedSpans,
      recentObservations,
    };
    try {
      writeFileSync(run.checkpointPath + '.tmp', JSON.stringify(checkpoint) + '\n');
      renameSync(run.checkpointPath + '.tmp', run.checkpointPath);
    } catch (error) {
      // A successful summary remains the primary record; checkpoint failure
      // must not mask a compiler result or throw from a span boundary.
    }
  }

  function assertOpen(operation) {
    if (finished) fail(operation + ' after finish');
  }

  function startSample(span) {
    if (sampler.status !== 'ready') {
      span.sample = {status: sampler.status === 'disabled' ? 'unavailable' : sampler.status,
        reason: sampler.reason ?? 'sampling was not enabled in createCompilerProfile'};
      return;
    }
    const stem = join(runDirectory, 'sampling', String(span.id).padStart(6, '0') + '-' + label(span.name));
    const sample = {
      status: 'running',
      spanId: span.id,
      name: span.name,
      cpuIntervalUs,
      allocationIntervalBytes,
      cpuProfilePath: stem + '.cpuprofile',
      allocationProfilePath: stem + '.heapprofile',
      startedAt: new Date().toISOString(),
    };
    sampleRecords.push(sample);
    try {
      sampler.post(sampler.session, 'Profiler.start');
      sampler.post(sampler.session, 'HeapProfiler.startSampling', {
        samplingInterval: allocationIntervalBytes,
        includeObjectsCollectedByMajorGC: true,
        includeObjectsCollectedByMinorGC: true,
      });
      span.sample = sample;
      activeSample = span;
    } catch (error) {
      try { sampler.post(sampler.session, 'Profiler.stop'); } catch {}
      try { sampler.post(sampler.session, 'HeapProfiler.stopSampling'); } catch {}
      sample.status = 'error';
      sample.reason = errorText(error);
      span.sample = sample;
    }
  }

  function stopSample(span) {
    if (activeSample !== span) return;
    activeSample = null;
    const sample = span.sample;
    sample.endedAt = new Date().toISOString();
    try {
      const cpu = sampler.post(sampler.session, 'Profiler.stop')?.profile;
      const allocation = sampler.post(sampler.session, 'HeapProfiler.stopSampling')?.profile;
      writeFileSync(sample.cpuProfilePath, JSON.stringify(cpu) + '\n', {flag: 'wx'});
      writeFileSync(sample.allocationProfilePath, JSON.stringify(allocation) + '\n', {flag: 'wx'});
      sample.status = 'completed';
    } catch (error) {
      sample.status = 'error';
      sample.reason = errorText(error);
    }
  }

  function begin(name, details = {}, options = {}) {
    assertOpen('begin');
    if (typeof name !== 'string' || !name) fail('begin requires a nonempty span name');
    if (details !== null && typeof details !== 'object') fail('begin details must be an object');
    const sample = options.sample === true;
    if (sample && activeSample) fail('cannot sample ' + JSON.stringify(name) + ' while sampled span ' + JSON.stringify(activeSample.name) + ' is active');
    const parent = stack.at(-1);
    const times = timeSnapshot();
    const span = {
      id: ++spanSequence,
      parentId: parent?.id ?? null,
      depth: stack.length,
      name,
      details: serializable(details),
      status: 'running',
      startedAt: new Date(times.unixMs).toISOString(),
      startedMonotonicMs: times.monotonicMs,
      cpuStart: cpuSnapshot(),
      memoryStart: memorySnapshot(),
      sample: null,
    };
    span.excluded = rawDetail && span.details.summary === false;
    if (parent === undefined) topLevelSpanCount += 1;
    if (sample) startSample(span);
    stack.push(span);
    if (!span.excluded) spans.push(span);
    raw({type: 'begin', id: span.id, parentId: span.parentId, depth: span.depth, name,
      details: span.details, sample: span.sample, at: span.startedAt});
    if (!span.excluded) writeCheckpoint();
    return Object.freeze({id: span.id, name: span.name, profileId});
  }

  function closeSpan(span, status, details, closeReason) {
    const times = timeSnapshot();
    const memoryEnd = memorySnapshot();
    const cpuEnd = cpuSnapshot();
    if (span.sample?.status === 'running') stopSample(span);
    span.endedAt = new Date(times.unixMs).toISOString();
    span.endedMonotonicMs = times.monotonicMs;
    span.wallMs = times.monotonicMs - span.startedMonotonicMs;
    span.cpu = cpuDelta(span.cpuStart, cpuEnd);
    span.boundaryMemory = {start: span.memoryStart, end: memoryEnd, delta: memoryDelta(span.memoryStart, memoryEnd)};
    if (details !== null && typeof details !== 'object') fail('end details must be an object');
    span.details = {...span.details, ...serializable(details ?? {})};
    if (closeReason) span.details.closeReason = closeReason;
    span.status = normalizeStatus(status, 'completed');
    delete span.cpuStart;
    delete span.memoryStart;
    spanStatusCounts[span.status] += 1;
    if (span.excluded) {
      // Raw mode streams this span to events.jsonl above; retain only bounded
      // aggregates here so a fullroot trace cannot keep one object per event.
      fineSpans.count += 1;
      fineSpans[span.status] += 1;
      fineSpans.summedWallMsNotExclusive += span.wallMs;
      const name = String(span.name);
      if (Object.hasOwn(fineSpans.byName, name) || Object.keys(fineSpans.byName).length < 64) {
        const entry = fineSpans.byName[name] ??= {count: 0, completed: 0, failed: 0, aborted: 0, summedWallMsNotExclusive: 0};
        entry.count += 1;
        entry[span.status] += 1;
        entry.summedWallMsNotExclusive += span.wallMs;
      } else fineSpans.otherNames += 1;
      if (span.status === 'failed') {
        if (fineSpans.failedSamples.length < 16)
          fineSpans.failedSamples.push({name, startedAt: span.startedAt, endedAt: span.endedAt,
            wallMs: span.wallMs, error: span.details.error ?? null});
        else fineSpans.failedSamplesOmitted += 1;
      }
    }
    raw({type: 'end', id: span.id, parentId: span.parentId, name: span.name, status: span.status,
      wallMs: span.wallMs, cpu: span.cpu, boundaryMemory: span.boundaryMemory,
      details: span.details, at: span.endedAt});
    if (!span.excluded) {
      lastCompletedSpans.push({id: span.id, parentId: span.parentId, name: span.name, status: span.status,
        startedAt: span.startedAt, endedAt: span.endedAt, wallMs: span.wallMs, cpu: span.cpu,
        boundaryMemory: span.boundaryMemory, details: span.details,
        ...(span.sample ? {sample: {...span.sample}} : {})});
      if (lastCompletedSpans.length > 8) lastCompletedSpans.shift();
      writeCheckpoint();
    }
    return span;
  }

  function end(token, status = 'completed', details = {}) {
    assertOpen('end');
    const top = stack.at(-1);
    if (!token || typeof token.id !== 'number') fail('end requires the token returned by begin');
    if (token.profileId !== profileId) fail('end token belongs to a different compiler profile');
    if (!top) fail('end called with no open span (' + token.name + ')');
    if (top.id !== token.id) fail('span close out of order: expected ' + JSON.stringify(top.name) + ', got ' + JSON.stringify(token.name));
    stack.pop();
    const span = closeSpan(top, status, details);
    return Object.freeze({id: span.id, name: span.name, status: span.status, wallMs: span.wallMs, parentId: span.parentId});
  }

  function record(observation = {}) {
    assertOpen('record');
    if (!observation || typeof observation !== 'object') fail('record requires an observation object');
    const {kind, scope, units, unitsByField, name, value, values, source, details} = observation;
    const aggregateOnly = rawDetail && observation.summary === false;
    if (typeof kind !== 'string' || !kind) fail('observation kind is required');
    if (typeof scope !== 'string' || !scope) fail('observation scope is required');
    if (units !== undefined && (typeof units !== 'string' || !units)) fail('observation units must be a nonempty string');
    if (units !== undefined && unitsByField !== undefined) fail('observation accepts units or unitsByField, not both');
    if (unitsByField !== undefined && (unitsByField === null || typeof unitsByField !== 'object' ||
        Array.isArray(unitsByField) || !Object.keys(unitsByField).length)) fail('observation unitsByField must be a nonempty object map');
    if (unitsByField !== undefined)
      for (const [field, unit] of Object.entries(unitsByField))
        if (!field || typeof unit !== 'string' || !unit) fail('observation unitsByField entries must map names to nonempty units');
    if (value !== undefined && values !== undefined) fail('observation accepts value or values, not both');
    if (value === undefined && values === undefined && details === undefined) fail('observation requires value, values or details');
    if (value !== undefined && (typeof value !== 'number' || !Number.isFinite(value))) fail('observation value must be a finite number');
    if (values !== undefined && (values === null || typeof values !== 'object' || Array.isArray(values)))
      fail('observation values must be an object map');
    const times = timeSnapshot();
    const row = {
      id: ++observationSequence,
      spanId: stack.at(-1)?.id ?? null,
      at: new Date(times.unixMs).toISOString(),
      elapsedMs: times.monotonicMs - startMonotonicMs,
      kind,
      name: name ?? null,
      scope,
      units: units ?? null,
      unitsByField: unitsByField === undefined ? null : serializable(unitsByField),
      value: value ?? null,
      values: values === undefined ? null : serializable(values),
      source: source ?? null,
      details: details === undefined ? null : serializable(details),
    };
    observationSequence += 1;
    if (aggregateOnly) {
      fineObservations.count += 1;
      if (Object.hasOwn(fineObservations.kinds, kind) || Object.keys(fineObservations.kinds).length < 64)
        fineObservations.kinds[kind] = (fineObservations.kinds[kind] ?? 0) + 1;
      else fineObservations.otherKinds += 1;
    } else {
      observations.push(row);
      recentObservations.push(row);
      if (recentObservations.length > 16) recentObservations.shift();
      writeCheckpoint();
    }
    raw({type: 'observation', ...row});
    return Object.freeze({id: row.id});
  }

  function abortOpen(status = 'aborted', details = {}, options = {}) {
    assertOpen('abortOpen');
    const finalStatus = normalizeStatus(status, 'aborted');
    if (!['failed', 'aborted'].includes(finalStatus)) fail('abortOpen status must be failed or aborted');
    if (details !== null && typeof details !== 'object') fail('abortOpen details must be an object');
    const keepId = options.keep?.id;
    const keepIndex = keepId === undefined ? -1 : stack.findIndex(span => span.id === keepId);
    let closed = 0;
    while (stack.length > keepIndex + 1) {
      const span = stack.pop();
      closeSpan(span, finalStatus, details, 'producer failure unwind');
      closed += 1;
    }
    return closed;
  }

  function publicSpan(span) {
    const record = {...span};
    if (record.sample) record.sample = {...record.sample};
    return record;
  }

  function finish(status = 'completed', error) {
    if (finished) return summary;
    const finalStatus = normalizeStatus(status, 'completed');
    const unclosedSpans = stack.length;
    const unclosedNames = stack.slice(0, 16).map(span => span.name);
    while (stack.length) {
      const span = stack.pop();
      closeSpan(span, 'aborted', {error: errorText(error)}, 'collector finished with an open span');
    }
    if (activeSample) stopSample(activeSample);
    activeSample = null;
    if (sampler.session) {
      try { sampler.session.disconnect(); } catch (sessionError) {
        sampler.status = 'error';
        sampler.reason = errorText(sessionError);
      }
    }
    const endedAt = new Date().toISOString();
    const endMonotonicMs = performance.now();
    finished = true;
    const summarizedSpans = spans.filter(span => span.details.summary !== false);
    const retainedKinds = {};
    for (const row of observations) retainedKinds[row.kind] = (retainedKinds[row.kind] ?? 0) + 1;
    const observationKinds = {...retainedKinds};
    for (const [kind, count] of Object.entries(fineObservations.kinds))
      observationKinds[kind] = (observationKinds[kind] ?? 0) + count;
    if (fineObservations.otherKinds)
      observationKinds.other = (observationKinds.other ?? 0) + fineObservations.otherKinds;
    const measurementStatus = unclosedSpans > 0 ? 'incomplete' : 'complete';
    const result = {
      schemaVersion: COMPILER_PROFILE_SCHEMA_VERSION,
      kind: 'compiler-profile',
      profilerVersion,
      diagnosticOnly: true,
      acceptanceEvidence: false,
      status: finalStatus,
      workloadStatus: finalStatus,
      measurementStatus,
      incompleteEvidence: unclosedSpans > 0,
      error: errorText(error),
      execution,
      identity,
      profileId,
      runtime: run.runtime,
      run: {
        runDirectory,
        startedAt,
        endedAt,
        wallMs: endMonotonicMs - startMonotonicMs,
        startMonotonicMs,
        endMonotonicMs,
        rawDetail,
        eventsPath: rawDetail ? join(runDirectory, 'events.jsonl') : null,
      },
      measurement: run.measurement,
      sampling: {
        config: run.sampling.config,
        status: sampler.status,
        reason: sampler.reason,
        spans: sampleRecords.map(sample => ({spanId: sample.spanId, name: sample.name, status: sample.status,
          cpuProfilePath: sample.cpuProfilePath, allocationProfilePath: sample.allocationProfilePath,
          cpuIntervalUs: sample.cpuIntervalUs, allocationIntervalBytes: sample.allocationIntervalBytes,
          ...(sample.reason ? {reason: sample.reason} : {})})),
      },
      spans: summarizedSpans.map(publicSpan),
      observations,
      fineGrain: {spans: fineSpans, observations: fineObservations},
      summary: {
        spanCount: spanSequence,
        summarizedSpanCount: summarizedSpans.length,
        excludedFineGrainSpans: fineSpans.count,
        topLevelSpanCount,
        failedSpans: summarizedSpans.filter(span => span.status === 'failed').map(span => span.name),
        abortedSpans: summarizedSpans.filter(span => span.status === 'aborted').map(span => span.name),
        failedSpanCount: spanStatusCounts.failed,
        abortedSpanCount: spanStatusCounts.aborted,
        sampledSpans: sampleRecords.filter(sample => sample.status !== 'unavailable').length,
        observations: observations.length,
        observationCount: observationSequence,
        aggregatedFineObservations: fineObservations.count,
        observationKinds,
        retainedObservationKinds: retainedKinds,
        rawEventsWritten: null,
        measurementStatus,
        incompleteEvidence: unclosedSpans > 0,
        unclosedSpans: {count: unclosedSpans, names: unclosedNames, closeStatus: 'aborted'},
      },
      limits: [...compilerProfileLimits],
    };
    raw({type: 'finish', status: finalStatus, measurementStatus, incompleteEvidence: unclosedSpans > 0,
      error: result.error, summary: {spanCount: result.summary.spanCount,
        observations: result.summary.observationCount, retainedObservations: result.summary.observations,
        sampledSpans: result.summary.sampledSpans, unclosedSpans: result.summary.unclosedSpans}, at: endedAt});
    result.summary.rawEventsWritten = rawEventsWritten;
    writeFileSync(join(runDirectory, 'summary.json'), JSON.stringify(result, null, 2) + '\n', {flag: 'wx'});
    writeCheckpoint(finalStatus, result.error);
    if (rawFD !== undefined) {
      const fd = rawFD;
      rawFD = undefined;
      closeSync(fd);
    }
    summary = result;
    return summary;
  }

  return {
    runDirectory,
    reportPath: join(runDirectory, 'summary.json'),
    rawDetail,
    begin,
    end,
    abortOpen,
    record,
    finish,
  };
}

// Shared adapter for the canonical compiler's existing observe(stage,name,state)
// seam. It creates coarse pass/reachability spans, and fine definition/spin/
// prepare spans only in rawDetail mode. The producer may pass onEvent to keep
// its own trace/progress writer; the adapter never invents state.
export function compilerObserverState(state = {}) {
  const keys = ['eExists', 'hExists', 'retainedHigher', 'segments', 'spins', 'ownFacts', 'hotFacts',
    'staticFacts', 'outputLines', 'outputUTF16Units', 'memos'];
  return Object.fromEntries(keys.filter(key => state[key] !== undefined).map(key => [key, state[key]]));
}

export function createCompileBookObserver(profile, options = {}) {
  const rawDetail = options.rawDetail ?? profile?.rawDetail ?? false;
  const onEvent = options.onEvent;
  const stacks = new Map();
  const entryKeys = ['retainedHigher', 'segments', 'spins', 'ownFacts', 'hotFacts', 'staticFacts'];
  let passes = 0, releases = 0;
  const fine = base => base === 'c-definition' || base === 'c-spin' || base === 'prepare';
  function recordState(kind, name, state, aggregate = false) {
    if (!profile) return;
    const mark = aggregate ? {summary: false} : {};
    const entries = Object.fromEntries(entryKeys.filter(key => typeof state[key] === 'number')
      .map(key => [key, state[key]]));
    if (Object.keys(entries).length)
      profile.record({kind, name, scope: 'in-process compile_book cache/fact/segment entry counts',
        units: 'entries', values: entries, ...mark});
    if (typeof state.outputLines === 'number')
      profile.record({kind: 'compiler-output-state', name: 'output-lines',
        scope: 'in-process emitted output line count', units: 'lines', value: state.outputLines,
        details: {compilerName: name}, ...mark});
    if (typeof state.outputUTF16Units === 'number')
      profile.record({kind: 'compiler-output-state', name: 'output-utf16-units',
        scope: 'in-process emitted output length', units: 'UTF-16 code units',
        value: state.outputUTF16Units, details: {compilerName: name}, ...mark});
    if (state.eExists !== undefined || state.hExists !== undefined)
      profile.record({kind: 'compiler-retention', name: 'definition-state',
        scope: 'in-process checked-body/higher presence flags', units: 'boolean',
        values: {eExists: state.eExists ?? null, hExists: state.hExists ?? null},
        details: {compilerName: name}, ...mark});
    if (state.memos !== null && typeof state.memos === 'object' && Object.keys(state.memos).length)
      profile.record({kind: 'compiler-memo-sizes', name: 'memos',
        scope: 'in-process memo cache entry counts', units: 'entries', values: state.memos,
        details: {compilerName: name}, ...mark});
  }
  function observe(stage, name, state = {}) {
    onEvent?.(stage, name, state);
    if (!profile) return;
    // release-after is a single event per definition, never a before/after
    // span. Raw mode keeps one observation; ordinary profiling counts it and
    // leaves the per-definition rows out, so a large build does not grow the
    // summary without rawDetail.
    if (stage === 'release-before') return;
    if (stage === 'release-after') {
      releases += 1;
      if (rawDetail) recordState('compiler-release', name, state, true);
      return;
    }
    const boundary = /^(.+)-(before|after)$/.exec(stage);
    if (!boundary) return;
    const [, base, side] = boundary;
    if (fine(base) && !rawDetail) return;
    const stack = stacks.get(base) ?? [];
    if (side === 'before') {
      if (base.startsWith('c-pass-')) passes += 1;
      stack.push(profile.begin(base, {name, ...(fine(base) ? {summary: false} : {})}));
      stacks.set(base, stack);
    } else {
      const token = stack.pop();
      if (!token) return;
      const values = compilerObserverState(state);
      recordState('compiler-state', name, state, fine(base) && rawDetail);
      profile.end(token, 'completed', {name, ...values});
      stacks.set(base, stack);
    }
  }
  return {observe, get passes() { return passes; }, get releases() { return releases; }};
}
