import {readFileSync, mkdirSync, writeFileSync, realpathSync} from 'node:fs';
import {resolve} from 'node:path';
import {fileURLToPath, pathToFileURL} from 'node:url';
const [repository, prior, output] = process.argv.slice(2);
const root = realpathSync(repository);
const {guardHeavyGate} = await import(pathToFileURL(resolve(root, 'evals/heavy_gate.ts')).href);
await guardHeavyGate(fileURLToPath(import.meta.url), {label: 'G43R2 actual-producer snapshot-only diagnostic'});
const {authenticateNativeSeedBuild} = await import(pathToFileURL(resolve(root, 'evals/native_seed_runtime.mjs')).href);
const {makeSnapshot, verifySnapshot} = await import(pathToFileURL(resolve(root, 'evals/g24_distributed.mjs')).href);
const {hashFile} = await import(pathToFileURL(resolve(root, 'evals/g24_snapshot.mjs')).href);
const json = path => JSON.parse(readFileSync(path, 'utf8'));
const pin = path => ({path, sha256: hashFile(path)});
const nativePath = resolve(prior, 'root-native-build.json');
const corpusPath = resolve(prior, 'root.native.corpus.json');
const bootstrapPath = resolve(prior, 'bootstrap.json'), bootstrap = json(bootstrapPath);
const rootPath = bootstrap.root;
const auth = authenticateNativeSeedBuild(nativePath, {root: rootPath, corpusPath,
  limits: {memoryMiB: 8192, rssMiB: 8192, pollMs: 10, timeoutMs: 600000}});
if (bootstrap.passed !== true || bootstrap.fixedpoint.equal !== true
  || hashFile(bootstrap.artifacts.stageOne.path) !== bootstrap.fixedpoint.stageOneSha256
  || hashFile(bootstrap.artifacts.stageTwo.path) !== bootstrap.fixedpoint.stageTwoSha256)
  throw Error('individually passed producer evidence changed');
const manifest = resolve(root, 'checkpoints/selfhost-root-local2039g43dist.json');
const context = {repository: root, candidate: {binary: {path: auth.binary, sha256: auth.binarySha256},
  stageOne: bootstrap.artifacts.stageOne}, evidence: {
    root: {...pin(rootPath), manifest, manifestSha256: hashFile(manifest)},
    native: {build: pin(nativePath), corpusPath, corpusSha256: hashFile(corpusPath)},
    fixedpoint: {report: pin(bootstrapPath), stageTwo: bootstrap.artifacts.stageTwo},
    emitted: pin(resolve(prior, 'emitted-suites.json'))}};
mkdirSync(output);
const snapshot = makeSnapshot(context, resolve(output, 'snapshot'));
verifySnapshot(snapshot.path, snapshot.sha256);
const report = {schemaVersion: 1, status: 'PASS', diagnosticOnly: true,
  fullCorrectnessClaim: false, priorCorrectnessManufactured: false,
  scope: 'Actual operational/producer snapshot inventory, freeze and verify only; no consumers, acceptance or new producer run',
  sourceProducer: prior, nativeBuildAuthenticated: true, snapshot: {path: snapshot.path,
    sha256: snapshot.sha256, entries: snapshot.manifest.entries.length},
  actualEntryBytes: snapshot.manifest.entries.reduce((n, e) => n + (e.bytes ?? 0), 0)};
writeFileSync(resolve(output, 'report.json'), JSON.stringify(report, null, 2) + '\n', {flag: 'wx'});
console.log(JSON.stringify(report));
