import {createCpuProfiler} from './selfhost_cpu_profile.mjs';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {isMainThread, workerData} from 'node:worker_threads';

// Diagnostic preload only; no compiler/kernel callbacks, inputs, values or code
// are replaced. The existing component builder still owns its guarded worker.
if (!isMainThread && workerData?.worker === true) {
  const directory = process.env.SELFHOST_NATIVE_CPU_PROFILE_DIR;
  if (!directory) throw Error('Missing native diagnostic CPU profile directory');
  const sourcePath = new URL(import.meta.url);
  const sourceSha256 = createHash('sha256').update(readFileSync(sourcePath)).digest('hex');
  const profiler = createCpuProfiler(directory, {
    kind: 'seed-native-component-build',
    diagnosticOnly: true,
    acceptanceEvidence: false,
    sourcePath: sourcePath.pathname,
    sourceSha256,
    argv: process.argv,
    phaseScope: 'authenticated native component worker, preload through exit; no per-definition phase inference',
  });
  profiler.mark('seed-native-load-check-emit');
  process.on('exit', code => profiler.finish(code === 0 ? undefined : Error('Native worker exit ' + code)));
}
