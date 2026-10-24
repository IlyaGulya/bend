#!/usr/bin/env bun
// Turn a preserved native compiler stderr trace into a compiler-profile report.
//
// This reads rows the native compiler already emitted
// (`NATIVE_BEGIN`, `NATIVE_FUEL`, `NATIVE_PHASE`, `NATIVE_RESULT`) and records
// them as child-process observations. It does not run a binary, does not time
// the collector's own process, and does not turn a coarse native phase into a
// substage CPU measurement. Fine native typed-substage spans are unavailable
// until the typed-step driver exposes progress at a host-visible boundary.
//
// usage: bun evals/compiler_stage_report.mjs --native-log=PATH --stage-profile=DIR
//   [--expect-sha256=HEX]
import {createHash} from 'node:crypto';
import {readFileSync,realpathSync} from 'node:fs';
import {resolve} from 'node:path';
import {createStageProfile,nativeTraceObservations} from './compiler_stage_profile.mjs';

function fail(message) {
  console.error('stage-report: ' + message);
  process.exit(1);
}

function parseArguments() {
  const values = new Map();
  for (const argument of process.argv.slice(2)) {
    const at = argument.indexOf('=');
    const name = at < 0 ? argument : argument.slice(0, at);
    const value = at < 0 ? undefined : argument.slice(at + 1);
    if (!['--native-log', '--stage-profile', '--expect-sha256'].includes(name) || value === undefined || values.has(name))
      fail('expected --native-log=PATH --stage-profile=DIR [--expect-sha256=HEX], observed ' + argument);
    values.set(name, value);
  }
  if (!values.has('--native-log') || !values.has('--stage-profile')) fail('--native-log and --stage-profile are required');
  return {log: resolve(values.get('--native-log')), directory: resolve(values.get('--stage-profile')),
    expect: values.get('--expect-sha256')};
}

const options = parseArguments();
const logPath = realpathSync(options.log);
const bytes = readFileSync(logPath);
const digest = createHash('sha256').update(bytes).digest('hex');
if (options.expect !== undefined && options.expect !== digest) fail('native trace digest differs from --expect-sha256');
const observations = nativeTraceObservations(bytes.toString('utf8'));
const phaseRows = observations.filter(row => row.kind === 'native-phase-coarse-span');
if (phaseRows.length === 0) fail('native trace has no NATIVE_PHASE rows: ' + logPath);
const begin = observations.find(row => row.kind === 'native-begin');

const profile = await createStageProfile({
  directory: options.directory,
  rawDetail: false,
  execution: {
    stage: 'native-compiler-trace',
    mode: 'preserved-native-stderr',
    target: 'native',
    logPath,
    logSha256: digest,
    logBytes: bytes.length,
    nativePhase: begin?.details?.phase ?? null,
    computeThreads: begin?.values?.computeThreads ?? null,
    parserFuel: begin?.values?.parserFuel ?? null,
    scope: 'child-process getrusage/wall rows; no collector span timing and no fine native substage attribution',
  },
});
for (const observation of observations) profile.record(observation);
profile.record({
  kind: 'trace-coverage', scope: 'preserved native stderr', name: 'row-counts',
  values: {phaseRows: phaseRows.length,
    fuelRows: observations.filter(row => row.kind === 'native-fuel-exact').length,
    resultRows: observations.filter(row => row.kind === 'native-result').length},
  source: 'native compiler stderr',
  details: {
    coarsePhases: phaseRows.map(row => row.name),
    fineNativeSubstages: null,
    fineNativeSubstagesReason: 'the typed driver exposes no host-visible progress boundary; native fine spans require a coordinated private typed view and are not claimed by this report',
  },
});
profile.finish('completed');
const reportPath = profile.reportPath;
console.log(JSON.stringify({reportPath, logPath, logSha256: digest, phaseRows: phaseRows.length,
  phases: phaseRows.map(row => row.name), observationRows: observations.length}));
