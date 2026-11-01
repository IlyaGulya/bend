import {readFileSync, writeFileSync, mkdirSync, realpathSync, existsSync} from 'node:fs';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
const config = JSON.parse(readFileSync(process.argv[2], 'utf8'));
const repository = realpathSync(config.repository), prior = realpathSync(config.producer);
const {authenticateNativeSeedBuild} = await import(pathToFileURL(resolve(repository, 'evals/native_seed_runtime.mjs')).href);
const {dispatch, makeSnapshot, loadPlan} = await import(pathToFileURL(resolve(repository, 'evals/g24_distributed.mjs')).href);
const {hashFile} = await import(pathToFileURL(resolve(repository, 'evals/g24_snapshot.mjs')).href);
const pin = path => ({path, sha256: hashFile(path)});
const json = path => JSON.parse(readFileSync(path, 'utf8'));
for (const [name, expected] of Object.entries(config.producerPins))
  if (hashFile(resolve(prior, name)) !== expected) throw Error('actual producer receipt drift: ' + name);
const bootstrapPath = resolve(prior, 'bootstrap.json'), bootstrap = json(bootstrapPath);
const emittedPath = resolve(prior, 'emitted-suites.json'), emitted = json(emittedPath);
const nativePath = resolve(prior, 'root-native-build.json'), corpusPath = resolve(prior, 'root.native.corpus.json');
const limits = {memoryMiB: 8192, rssMiB: 8192, pollMs: 10, timeoutMs: 600000};
const auth = authenticateNativeSeedBuild(nativePath, {root: bootstrap.root, corpusPath, limits});
if (bootstrap.passed !== true || bootstrap.fixedpoint.equal !== true || emitted.passed !== true
  || hashFile(bootstrap.artifacts.stageOne.path) !== bootstrap.fixedpoint.stageOneSha256
  || hashFile(bootstrap.artifacts.stageTwo.path) !== bootstrap.fixedpoint.stageTwoSha256)
  throw Error('passed individual producer artifacts changed');
if (existsSync(config.out)) throw Error('fresh diagnostic output required');
mkdirSync(config.out);
const state = {root: {...pin(bootstrap.root), manifest: config.manifest, manifestSha256: hashFile(config.manifest)},
  native: {build: pin(nativePath), binary: auth.binary, binarySha256: auth.binarySha256,
    corpusPath, corpusSha256: hashFile(corpusPath)},
  fixedpoint: {report: pin(bootstrapPath), stageOne: bootstrap.artifacts.stageOne,
    stageTwo: bootstrap.artifacts.stageTwo}, emitted: pin(emittedPath), matrix: {}, consumers: {}};
const context = {repository, out: config.out, runId: 'remote2039g43r7-consumers',
  distributed: loadPlan(config.plan)};
let status = 'IN_PROGRESS', failure;
function publish() {
  writeFileSync(resolve(config.out, 'diagnostic.json'), JSON.stringify({schemaVersion: 1, status,
    diagnosticOnly: true, fullCorrectnessClaim: false, priorCorrectnessManufactured: false,
    compilerAccepted: false, performanceAccepted: false, sourceProducer: prior,
    producerPins: config.producerPins, limits, state, failure}, null, 2) + '\n');
}
publish();
try {
  context.candidate = {repository, binary: {path: state.native.binary, sha256: state.native.binarySha256}, stageOne: state.fixedpoint.stageOne};
  context.evidence = state; context.snapshotFixtures = config.fixtures;
  const snapshot = makeSnapshot(context, resolve(config.out, 'consumer-snapshot'));
  state.distributed = {jobs: []};
  for (const job of config.jobs) {
    if (!['admission', 'host'].includes(job)) throw Error('unexpected diagnostic branch');
    const value = await dispatch(context, snapshot, job);
    state.consumers[job] = value.consumer;
    state.distributed.jobs.push(value.transport);
    publish();
  }
  status = 'PASS';
}
catch (e) { status = 'FAIL'; failure = String(e?.stack ?? e); process.exitCode = 1; }
publish();
console.log(JSON.stringify({status, diagnosticOnly: true, jobs: state.distributed?.jobs?.length ?? 0,
  report: resolve(config.out, 'diagnostic.json'), failure}));
