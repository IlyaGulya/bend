// Opt-in diagnostic scoped profiler for the official compiler producers.
//
// This collector is evidence plumbing, not an acceptance signal and not a
// benchmark. It records three distinct kinds of evidence and never converts
// one into another:
//
//   * coarse explicit spans: monotonic wall, process-wide CPU boundary delta,
//     current-thread CPU boundary delta, and process.memoryUsage plus
//     process.resourceUsage/RSS and runtime heap-statistics boundary snapshots;
//   * sampled attribution: optional V8 inspector CPU (1 ms) and statistical
//     allocation (4 MiB) profiles for explicitly sampled spans;
//   * exact counters/observations supplied by the producer (definition,
//     segment, cache and chunk counts, or child-process RUSAGE rows).
//
// A boundary heapUsed delta is not allocation or retained bytes. RSS and peak
// RSS are process-wide. process.cpuUsage covers every thread in this process,
// not child processes; child CPU requires its own rusage receipt.
// process.threadCpuUsage covers only the collector's own thread, so the
// process-minus-thread difference is arithmetic, not attribution. Nested or
// overlapping spans have overlapping CPU deltas and no exclusive CPU is
// invented. Footprint, live/retained bytes, allocation-request counts and
// child rusage that the host cannot observe stay unavailable with an explicit
// reason in every snapshot.
//
// Import is side-effect free. Inspector is loaded lazily and only when a span
// explicitly requests sampling, so Bun/Node runners that never profile pay no
// startup cost. The no-profile producer path never imports this module.

import {randomUUID} from 'node:crypto';
import {closeSync, mkdirSync, mkdtempSync, openSync, renameSync, writeFileSync, writeSync} from 'node:fs';
import {join, resolve} from 'node:path';
import {isMainThread, threadId} from 'node:worker_threads';

export const COMPILER_PROFILE_SCHEMA_VERSION = 1;
const profilerVersion = 'compiler-profile/2';
const statuses = new Set(['completed', 'failed', 'aborted']);

export const compilerProfileLimits = Object.freeze([
  'diagnostic only: profile files do not certify acceptance, bootstrap green, fixedpoint or benchmark results',
  'span CPU is a process.cpuUsage boundary delta over all threads in this process; child processes are excluded and require their own rusage receipt; nested or overlapping spans overlap and no exclusive CPU is derived',
  'span thread CPU is a process.threadCpuUsage boundary delta over the collector thread only; worker threads and runtime helper threads are excluded there and included in the process delta, so their arithmetic difference is a measurement gap, not an attribution',
  'boundary heapUsed deltas are not allocation, live or retained bytes; RSS is process-wide',
  'peak RSS is process.resourceUsage().maxRSS (a runtime-documented high-water resident size); it is not memory footprint and no snapshot substitutes one for the other',
  'footprint, live/retained heap and allocation-request counts are unavailable at these boundaries and stay explicit: the collector never forces GC, and inspector heap sampling is statistical over allocated and collected objects',
  'sampled CPU/allocation profiles are statistical, include collected objects for allocation, and have no Bend source map',
  'child-process CPU/RSS exists only where the producer records a child receipt (e.g. NATIVE_PHASE or llvm time -lp); it is never inferred, and worker and child process trees are not enumerable from the collector',
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

function threadCpuSnapshot() {
  if (typeof process.threadCpuUsage !== 'function')
    return {status: 'unavailable', reason: 'process.threadCpuUsage is not available in this runtime'};
  const usage = process.threadCpuUsage();
  return {
    status: 'available',
    source: 'process.threadCpuUsage (microseconds, runtime contract; converted to milliseconds)',
    userMs: usage.user / 1000,
    systemMs: usage.system / 1000,
  };
}

function cpuSnapshot() {
  const usage = process.cpuUsage();
  return {userMs: usage.user / 1000, systemMs: usage.system / 1000, thread: threadCpuSnapshot()};
}

function cpuDelta(before, after) {
  const thread = before.thread.status === 'available' && after.thread.status === 'available'
    ? {
      status: 'available',
      scope: 'process.threadCpuUsage: the collector thread only; excludes worker threads and runtime helper threads',
      userMs: after.thread.userMs - before.thread.userMs,
      systemMs: after.thread.systemMs - before.thread.systemMs,
    }
    : {status: 'unavailable', reason: after.thread.reason ?? before.thread.reason};
  const otherThreads = thread.status === 'available'
    ? {
      status: 'available',
      scope: 'arithmetic difference of the process-wide delta and this-thread delta; covers worker threads and runtime helper threads; a measurement gap, never an attribution to them',
      userMs: (after.userMs - before.userMs) - thread.userMs,
      systemMs: (after.systemMs - before.systemMs) - thread.systemMs,
    }
    : {status: 'unavailable', reason: 'this-thread CPU was not captured at both boundaries, so other-thread CPU cannot be separated'};
  return {
    kind: 'process-boundary-delta',
    scope: 'process.cpuUsage: every thread in this process, including worker threads; child processes have separate rusage and are excluded; not exclusive to this span and overlapping for nested spans',
    userMs: after.userMs - before.userMs,
    systemMs: after.systemMs - before.systemMs,
    thread,
    otherThreads,
  };
}

// Footprint, live heap and allocation-request counts are separate classes with
// no runtime readout at a boundary. They are declared once here, copied into
// every snapshot, and never substituted by RSS, heapUsed or sampled bytes.
const memoryUnavailable = Object.freeze({
  footprintBytes: {
    status: 'unavailable',
    reason: 'no runtime API exposes the OS memory footprint (for example macOS phys_footprint); RSS and peak RSS are different resident-size measurements',
  },
  liveHeapBytes: {
    status: 'unavailable',
    reason: 'a live/retained number requires a forced full GC plus a heap readback; the collector never forces GC, and a boundary heapUsed is not live or retained bytes',
  },
  allocationRequests: {
    status: 'unavailable',
    reason: 'no allocation-site hook is installed; inspector heap sampling is a statistical sample of allocated and collected objects, not an allocation-request count',
  },
});

function resourceUsageSnapshot() {
  if (typeof process.resourceUsage !== 'function')
    return {status: 'unavailable', reason: 'process.resourceUsage is not available in this runtime'};
  const usage = process.resourceUsage();
  if (!Number.isFinite(usage.maxRSS))
    return {status: 'unavailable', reason: 'process.resourceUsage returned no finite maxRSS'};
  return {
    status: 'available',
    source: 'process.resourceUsage().maxRSS',
    maxRss: usage.maxRSS,
    maxRssUnit: 'kilobytes as documented by the process.resourceUsage runtime contract',
    peakRssBytes: usage.maxRSS * 1024,
    scope: 'process high-water resident set size for the whole process; not memory footprint, not live heap and not allocation',
  };
}

const heapStatisticsFields = Object.freeze([
  ['totalHeapSizeBytes', 'total_heap_size'],
  ['totalHeapSizeExecutableBytes', 'total_heap_size_executable'],
  ['totalPhysicalSizeBytes', 'total_physical_size'],
  ['totalAvailableSizeBytes', 'total_available_size'],
  ['usedHeapSizeBytes', 'used_heap_size'],
  ['heapSizeLimitBytes', 'heap_size_limit'],
  ['mallocedBytes', 'malloced_memory'],
  ['peakMallocedBytes', 'peak_malloced_memory'],
  ['externalMemoryBytes', 'external_memory'],
  ['totalGlobalHandlesBytes', 'total_global_handles_size'],
  ['usedGlobalHandlesBytes', 'used_global_handles_size'],
]);

function heapStatisticsSnapshot(probe, omittedReason) {
  if (probe === null)
    return {status: 'unavailable', reason: omittedReason ?? 'node:v8 getHeapStatistics is not available in this runtime'};
  // Bun 1.4.2's v8.ts fabricates several compatibility fields: for example
  // total_allocated_bytes is JSC heapCapacity, not cumulative allocations.
  if (process.versions.bun)
    return {status: 'unavailable', reason: 'V8 heap-statistics field semantics are not verified for this Bun runtime; use the separately labelled process boundary samples'};
  try {
    const statistics = probe();
    const bytes = {};
    for (const [name, key] of heapStatisticsFields)
      if (Number.isFinite(statistics[key])) bytes[name] = statistics[key];
    const counts = {};
    for (const [name, key] of [['nativeContexts', 'number_of_native_contexts'], ['detachedContexts', 'number_of_detached_contexts']])
      if (Number.isFinite(statistics[key])) counts[name] = statistics[key];
    return {
      status: 'available',
      source: 'node:v8 getHeapStatistics',
      bytes, counts,
      scope: 'V8 isolate heap statistics at the boundary; usedHeapSizeBytes is a boundary size and peakMallocedBytes a runtime malloc peak, not cumulative allocation, live/retained bytes, resident size or OS footprint',
    };
  } catch (error) {
    return {status: 'error', reason: errorText(error)};
  }
}

function memorySnapshot(heapProbe, heapOmittedReason) {
  const usage = process.memoryUsage();
  return {
    scope: 'process.memoryUsage at a boundary: RSS is process-wide; heapUsed/heapTotal are boundary samples, not allocation, live or retained bytes; allocation requests are not observed',
    rssBytes: usage.rss,
    heapTotalBytes: usage.heapTotal,
    heapUsedBytes: usage.heapUsed,
    externalBytes: usage.external,
    arrayBuffersBytes: usage.arrayBuffers,
    resourceUsage: resourceUsageSnapshot(),
    heapStatistics: heapStatisticsSnapshot(heapProbe, heapOmittedReason),
    unavailable: memoryUnavailable,
  };
}

function memoryDelta(before, after) {
  return {
    kind: 'boundary-snapshot-delta',
    scope: before.scope,
    heapUsedDeltaBytes: after.heapUsedBytes - before.heapUsedBytes,
    rssDeltaBytes: after.rssBytes - before.rssBytes,
    allocationVolume: {status: 'unavailable',
      reason: 'no verified cumulative allocation counter is exposed by this collector; Bun total_allocated_bytes is heap capacity, not allocation volume'},
    caveat: 'a boundary delta is not allocation or retained bytes; it can miss peaks and includes uncollected garbage; allocationVolume never replaces allocation samples or a retained-byte measurement',
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
  const cpuStart = cpuSnapshot();
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

  // Runtime heap statistics are optional evidence: a runtime without
  // node:v8 still gets an explicit unavailable reason instead of a guessed
  // number. Loading is lazy so no-profile consumers pay nothing.
  let heapProbe = null;
  try {
    const v8 = await import('node:v8');
    if (typeof v8.getHeapStatistics === 'function') heapProbe = () => v8.getHeapStatistics();
  } catch {}
  const fineHeapOmittedReason = 'fine raw span (details.summary:false): runtime heap statistics are captured only for retained evidence to bound diagnostic overhead';

  const identity = {pid: process.pid, parentPid: process.ppid, threadId, isMainThread,
    threadKind: isMainThread ? 'main-thread' : 'worker-thread'};
  // Which process/thread the evidence belongs to, and which parts of the tree
  // this collector cannot enumerate. Child and worker accounting is never
  // merged into span CPU; it requires a producer-supplied receipt.
  const provenance = {
    process: {pid: process.pid, parentPid: process.ppid, execPath: process.execPath, platform: process.platform, arch: process.arch},
    thread: {threadId, isMainThread, threadKind: isMainThread ? 'main-thread' : 'worker-thread',
      source: 'node:worker_threads in the collector process'},
    workerThreads: {enumerable: false,
      reason: 'a producer-created worker thread registers no identity with this collector; a profile created inside that worker carries its own pid/threadId, and process.cpuUsage includes both threads while threadCpuUsage covers only the creating thread'},
    childProcesses: {enumerable: false,
      reason: 'no portable child-process enumeration is available; child CPU/RSS is recorded only from an explicit producer receipt (wait4/rusage/NATIVE_PHASE) and is never merged into span CPU or this process\'s CPU'},
    samplingScope: 'local inspector Session for the isolate that created this collector',
    cpuScope: {process: 'every thread in this process', thread: 'the collector thread only',
      child: 'excluded; explicit producer receipt required',
      otherThreads: 'process delta minus thread delta; arithmetic gap, not attribution'},
  };
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
    provenance,
    measurement: {
      wall: {kind: 'monotonic performance.now', scope: 'collector process'},
      cpu: {
        kind: 'process.cpuUsage boundary delta, plus process.threadCpuUsage boundary delta',
        scope: 'process: every thread in this process; thread: the collector thread only; child processes excluded from both; not exclusive across overlapping spans',
        classes: {
          processBoundaryDelta: {observed: 'process.cpuUsage', semantics: 'all threads in this process, including worker threads'},
          threadBoundaryDelta: {observed: 'process.threadCpuUsage', semantics: 'the collector thread only; excludes worker threads and helper threads'},
          otherThreadGap: {observed: 'process delta minus thread delta', semantics: 'arithmetic gap covering helper/worker threads; not an attribution'},
          childProcess: {observed: null, reason: 'child CPU requires a producer wait4/rusage receipt; the collector never infers it'},
        },
      },
      memory: {
        kind: 'process.memoryUsage + process.resourceUsage + runtime heap-statistics boundary snapshot',
        scope: 'RSS and peak RSS are process-wide; heap sizes are isolate boundary samples; none is allocation requests, live bytes or retained bytes',
        classes: {
          rss: {observed: 'process.memoryUsage().rss', unit: 'bytes', semantics: 'process-wide resident size at the boundary'},
          peakRss: {observed: 'process.resourceUsage().maxRSS', unit: 'bytes (runtime kB × 1024)', semantics: 'process-wide high-water resident size; not footprint'},
          footprint: memoryUnavailable.footprintBytes,
          heapBoundary: {observed: 'process.memoryUsage().heapUsed/heapTotal', unit: 'bytes', semantics: 'isolate boundary sizes, not live or retained bytes'},
          heapStatistics: {observed: 'node:v8 getHeapStatistics when available', unit: 'bytes/counts',
            semantics: 'V8 boundary sizes and runtime malloc peaks, not cumulative allocations or live bytes; Bun compatibility-shim fields stay unavailable'},
          liveHeap: memoryUnavailable.liveHeapBytes,
          allocationRequests: memoryUnavailable.allocationRequests,
          allocationSamples: samplingConfig
            ? {observed: 'inspector HeapProfiler sampling', unit: 'bytes interval, statistical samples', semantics: 'statistical allocation samples including collected objects; not exact sizes or request counts'}
            : {observed: null, reason: 'inspector allocation sampling was not enabled for this profile'},
        },
      },
      sampling: samplingConfig
        ? {kind: 'V8 inspector', cpu: {unit: 'us', intervalUs: cpuIntervalUs, kind: 'statistical CPU stacks'},
            allocation: {unit: 'bytes', intervalBytes: allocationIntervalBytes, kind: 'statistical allocation samples, including collected objects',
              semantics: 'sampled bytes and sites are statistical estimates including objects collected by minor/major GC; never retained bytes and never allocation-request counts'}}
        : null,
    },
    sampling: {config: samplingConfig ? {cpuIntervalUs, allocationIntervalBytes} : null, status: sampler.status, reason: sampler.reason, spans: []},
    limits: [...compilerProfileLimits],
  };
  writeFileSync(join(runDirectory, 'run.json'), JSON.stringify(run, null, 2) + '\n', {flag: 'wx'});

  // Coarse, atomic crash evidence. Fine raw events are streamed to events.jsonl
  // and are deliberately not checkpointed, so this file stays bounded.
  function writeCheckpoint(finalStatus, finalError) {
    const cpu = cpuSnapshot();
    const checkpoint = {
      schemaVersion: COMPILER_PROFILE_SCHEMA_VERSION,
      kind: 'compiler-profile-checkpoint',
      profilerVersion,
      profileId,
      execution,
      identity,
      provenance,
      runDirectory,
      checkpointPath: run.checkpointPath,
      rawDetail,
      status: finalStatus ?? 'running',
      error: finalError ?? null,
      updatedAt: new Date().toISOString(),
      elapsedMs: performance.now() - startMonotonicMs,
      process: {
        cpu: {kind: 'process-boundary-delta',
          scope: 'process.cpuUsage delta since collector creation; every thread in this process; child processes excluded',
          userMs: cpu.userMs - cpuStart.userMs, systemMs: cpu.systemMs - cpuStart.systemMs,
          thread: cpu.thread.status === 'available' && cpuStart.thread.status === 'available'
            ? {status: 'available', scope: 'collector thread only, since collector creation',
                userMs: cpu.thread.userMs - cpuStart.thread.userMs,
                systemMs: cpu.thread.systemMs - cpuStart.thread.systemMs}
            : {status: 'unavailable', reason: cpu.thread.reason ?? cpuStart.thread.reason}},
        memory: memorySnapshot(heapProbe),
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
    const spanDetails = serializable(details);
    // Fine raw spans are streamed but not retained; capturing runtime heap
    // statistics for each of them would pay a heap readback per event without
    // any retained evidence. The omission is explicit in the snapshot.
    const excluded = rawDetail && spanDetails.summary === false;
    const span = {
      id: ++spanSequence,
      parentId: parent?.id ?? null,
      depth: stack.length,
      name,
      details: spanDetails,
      status: 'running',
      startedAt: new Date(times.unixMs).toISOString(),
      startedMonotonicMs: times.monotonicMs,
      cpuStart: cpuSnapshot(),
      memoryStart: memorySnapshot(excluded ? null : heapProbe, excluded ? fineHeapOmittedReason : undefined),
      sample: null,
      excluded,
    };
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
    const memoryEnd = memorySnapshot(span.excluded ? null : heapProbe,
      span.excluded ? fineHeapOmittedReason : undefined);
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
    const keep = options.keep;
    if (keep !== undefined) {
      if (!keep || typeof keep.id !== 'number') fail('abortOpen keep must be a token returned by begin');
      if (keep.profileId !== profileId) fail('abortOpen keep token belongs to a different compiler profile');
      if (!stack.some(span => span.id === keep.id)) fail('abortOpen keep token is not an open span');
    }
    const keepIndex = keep === undefined ? -1 : stack.findIndex(span => span.id === keep.id);
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
      provenance,
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
  let seamCoverageRecorded = false;
  function recordSeamCoverage() {
    if (!profile || seamCoverageRecorded) return;
    seamCoverageRecorded = true;
    profile.record({
      kind: 'producer-seam-coverage', scope: 'canonical producer observe(stage,name,state) seam',
      name: 'compile-book-stages',
      values: {envelopeSpanFamilies: 3, rawOnlySpanFamilies: 3, stateOnlyEventFamilies: 2, modulePhaseFamilies: 0},
      unitsByField: {envelopeSpanFamilies: 'stage families', rawOnlySpanFamilies: 'stage families',
        stateOnlyEventFamilies: 'stage families', modulePhaseFamilies: 'stage families'},
      source: 'bend2/comp.ts FL.options.observe calls',
      details: {
        envelopeSpans: ['c-reachability-before/after', 'c-pass-N-before/after', 'c-pass-N-close-before/after'],
        rawOnlySpans: ['prepare-before/after', 'c-spin-before/after', 'c-definition-before/after'],
        stateOnlyEvents: ['release-before (never begins a span)',
          'release-after (counted; one streamed observation per definition in rawDetail only)'],
        fineGrainAvailable: rawDetail
          ? 'per-definition prepare/spin/definition spans are streamed to events.jsonl but excluded from the bounded summary; their wall/CPU overlap enclosing pass spans and are never exclusive'
          : 'prepare, c-spin and c-definition spans are not begun at all; only the c-reachability and per-pass envelopes carry wall/CPU',
        modulePhaseAttribution: null,
        modulePhaseAttributionReason: 'the producer seam reports per-definition prepare/spin and per-pass envelopes but no catalog/lowering/descriptor-NF/layout/sharing/JS-C-rendering boundary and no authenticated declaration-to-source manifest; deriving a stage owner from a definition key name would be a guess, so no such attribution is produced',
        cpuScope: 'span CPU is process.cpuUsage over every thread plus process.threadCpuUsage over the codegen thread; nested pass/definition spans overlap and no exclusive CPU is derived',
        memoryScope: 'boundary process.memoryUsage/process.resourceUsage/heap-statistics snapshots only; no per-definition allocation, live or retained bytes',
        childScope: 'child processes (clang/link) are excluded from span CPU; only an explicit producer receipt may describe them',
      },
    });
  }
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
      // Coverage metadata is recorded once, at the first span this observer
      // actually opens, so a non-collector recorder stub sees no unexpected row
      // before it has observed any stage.
      recordSeamCoverage();
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
