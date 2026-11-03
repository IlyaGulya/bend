#!/usr/bin/env bun
/** Fresh real-source checker screen, never full compiler acceptance.
 * bun evals/selfhost_corpus_run.ts MANIFEST IMAGE NATIVE-RECEIPT NODE FRESH-DIR
 * bun evals/selfhost_corpus_run.ts --native-executable MANIFEST BUILD BUILD-CORPUS FRESH-DIR
 * bun evals/selfhost_corpus_run.ts --canonical-oracle MANIFEST IMAGE ORACLE-RECEIPT NODE FRESH-DIR
 * JS uses the unchanged guarded throughput driver; C uses the existing native
 * compiler CLI's check phase. Both retain their raw, backend-specific reports.
 */
import {spawn} from 'node:child_process';
import {existsSync, mkdirSync, readFileSync, realpathSync, writeFileSync} from 'node:fs';
import {dirname, resolve} from 'node:path';
import {ABI, authenticateNativeSeedBuild, corpusFor, hashPath, workloadRows} from './native_seed_runtime.mjs';
import {authenticateSourceOracle} from './selfhost_oracle.mjs';

const args = process.argv.slice(2);
const canonical = args[0] === '--canonical-oracle';
if (canonical && args[1] === '--native-executable')
  throw Error('Compiler producer modes are mutually exclusive');
if (canonical) args.shift();
if (!process.versions.bun)
  throw Error('Run the corpus screen with Bun');
if (args[0] === '--native-executable') process.exit(await runNative(args.slice(1)));
if (args.length !== 5)
  throw Error('Usage: bun evals/selfhost_corpus_run.ts MANIFEST IMAGE NATIVE-RECEIPT NODE FRESH-DIR');
const [manifestPath, imagePath, receiptPath, nodePath, outputPath] = args as [string,string,string,string,string];
const manifestFile = realpathSync(manifestPath), image = realpathSync(imagePath);
const receiptFile = realpathSync(receiptPath), node = realpathSync(nodePath), out = resolve(outputPath);
if (existsSync(out)) throw Error('Use a fresh output directory: ' + out);
const {manifest, repository, root} = checkedCorpus(manifestFile);
const receipt = canonical ? authenticateSourceOracle(receiptFile, image) : JSON.parse(readFileSync(receiptFile, 'utf8'));
const imageSha256 = canonical ? receipt.outputSha256 : hashPath(image);
if (canonical && JSON.stringify(receipt.exports) !== JSON.stringify(ABI))
  throw Error('Canonical corpus oracle must export the complete compiler ABI');
if (!canonical && (receipt.status !== 'NATIVE_FULL_COMPILE_PASS' || receipt.result?.result !== 'EmitSuccess'
  || realpathSync(receipt.output) !== image || receipt.outputSha256 !== imageSha256
  || JSON.stringify(receipt.exports) !== JSON.stringify(ABI)
  || !Array.isArray(receipt.command) || receipt.command.at(-2) !== 'compile' || realpathSync(receipt.command.at(-1)) !== image
  || JSON.stringify(receipt.phases?.map((phase: any) => phase.phase)) !== JSON.stringify(['parse', 'expand', 'check', 'emit'])
  || receipt.guardian?.status !== 'PASS' || receipt.guardian?.ownedTreeStopped !== true
  || receipt.guardian?.reportPhase !== 'complete' || receipt.guardian?.exitCode !== 0
  || receipt.guardian?.supervisorExitCode !== 0 || receipt.guardian?.commandExitCode !== 0 || receipt.guardian?.commandSignal !== 0
  || receipt.boundary?.cachedAst !== false || receipt.boundary?.hostParsing !== false
  || receipt.boundary?.hostChecking !== false || receipt.boundary?.checksExcluded !== 0 || receipt.boundary?.outputPatches !== 0))
  throw Error('Image lacks its matching successful unpatched native producer receipt');
const driver = realpathSync(resolve(import.meta.dir, 'selfhost_throughput.mjs'));
const files = ['selfhost_throughput.mjs', 'checker_core_step_runtime.mjs', 'selfhost_cpu_profile.mjs', 'native_seed_runtime.mjs', 'heavy_gate.ts']
  .map(name => realpathSync(resolve(import.meta.dir, name)));
if (canonical) files.push(realpathSync(resolve(import.meta.dir, 'selfhost_oracle.mjs')));
const pins = Object.fromEntries([...files, image, receiptFile, manifestFile, node].map(file => [file, hashPath(file)]));
if (canonical) Object.assign(pins, receipt.loadedInputs);
const inputs = Object.fromEntries(manifest.files.map((row: any) => [realpathSync(resolve(repository, row.path)), row.sha256]));
const request: Record<string, unknown> = {
  schemaVersion: 1, repository, root, image, node, exports: ABI, pins, inputs,
  limits: {memoryMiB: 8192, rssMiB: 8192, pollMs: 10, timeoutMs: 600000},
  stopAfter: 'check',
  scope: canonical
    ? 'DEVELOPMENT canonical TS-produced compiler; fresh own-image parse/expand/check on the frozen source workload. Not native production, emitted-byte fixedpoint, performance-transfer qualification or product acceptance.'
    : 'Frozen real-source corpus; fresh native-produced own-image parse/expand/check. Checker screen only, not emission, fixedpoint or product acceptance.',
};
if (canonical) request.producer = {
  kind: receipt.kind, receipt: receiptFile, source: receipt.source,
  nativeCompiler: false, acceptanceEvidence: false, byteFixedpointClaim: false,
};
mkdirSync(out, {recursive: true});
const requestFile = resolve(out, 'request.json'), reportFile = resolve(out, 'report.json');
writeFileSync(requestFile, JSON.stringify(request, null, 2) + '\n', {flag: 'wx'});
const child = spawn(process.execPath, ['--smol', driver, 'js', requestFile, reportFile], {
  cwd: repository, stdio: 'inherit',
});
const code = await new Promise<number>((done, fail) => {
  child.once('error', fail);
  child.once('close', (status, signal) => signal ? fail(Error('Corpus screen stopped: ' + signal)) : done(status ?? 1));
});
process.exitCode = code;

function checkedCorpus(file: string) {
  const manifest = JSON.parse(readFileSync(file, 'utf8'));
  if (manifest.schemaVersion !== 1 || JSON.stringify(manifest.exports) !== JSON.stringify(ABI) || !Array.isArray(manifest.files))
    throw Error('Expected ordinary native source corpus manifest');
  const repository = realpathSync(resolve(dirname(file), manifest.directory));
  const root = realpathSync(resolve(repository, manifest.root)), previous = process.cwd();
  let actual;
  try { process.chdir(repository); actual = corpusFor(workloadRows(root, 'js')); }
  finally { process.chdir(previous); }
  const identity = (rows: any[]) => rows.map(row => {
    const path = realpathSync(resolve(repository, row.path));
    return [path, row.sha256, row.external === true ? null : row.namespace, row.external === true];
  }).sort((a, b) => String(a[0]).localeCompare(String(b[0])));
  if (JSON.stringify(identity(manifest.files)) !== JSON.stringify(identity(actual.files)))
    throw Error('Manifest differs from complete source closure, namespaces or foreign alternatives');
  return {manifest, repository, root, actual};
}

async function runNative(values: string[]): Promise<number> {
  if (values.length !== 4)
    throw Error('Usage: bun evals/selfhost_corpus_run.ts --native-executable MANIFEST BUILD BUILD-CORPUS FRESH-DIR');
  const [manifestPath, buildPath, buildCorpusPath, outputPath] = values as [string,string,string,string];
  const manifestFile = realpathSync(manifestPath), buildFile = realpathSync(buildPath);
  const buildCorpusFile = realpathSync(buildCorpusPath), out = resolve(outputPath);
  if (existsSync(out)) throw Error('Use a fresh output directory: ' + out);
  const {manifest, repository, root, actual} = checkedCorpus(manifestFile);
  const buildCorpus = JSON.parse(readFileSync(buildCorpusFile, 'utf8'));
  const buildRepository = realpathSync(resolve(dirname(buildCorpusFile), buildCorpus.directory));
  const compilerRoot = realpathSync(resolve(buildRepository, buildCorpus.root)), previous = process.cwd();
  let seed;
  try {
    process.chdir(buildRepository);
    seed = authenticateNativeSeedBuild(buildFile, {
      root: compilerRoot, corpusPath: buildCorpusFile,
      limits: {memoryMiB: 8192, rssMiB: 8192, timeoutMs: 600000},
    });
  } finally { process.chdir(previous); }
  const driver = realpathSync(resolve(import.meta.dir, 'native_compiler_experiment.ts'));
  const reportFile = resolve(out, 'report.json'), workloadFile = resolve(out, 'workload.json');
  mkdirSync(out, {recursive: true});
  writeFileSync(workloadFile, JSON.stringify(actual, null, 2) + '\n', {flag: 'wx'});
  const command = [process.execPath, '--smol', driver, '--mode=run',
    '--corpus=' + workloadFile, '--build=' + buildFile, '--report=' + reportFile,
    '--phase=check', '--threads=1'];
  const files = [manifestFile, workloadFile, buildFile, buildCorpusFile, seed.binary, driver,
    realpathSync(resolve(import.meta.dir, 'native_seed_runtime.mjs'))];
  const request = {
    schemaVersion: 1, mode: 'native-executable', repository, root, exports: ABI,
    binary: seed.binary, build: buildFile, buildCorpus: buildCorpusFile, workload: workloadFile,
    pins: Object.fromEntries(files.map(file => [file, hashPath(file)])),
    inputs: Object.fromEntries(manifest.files.map((row: any) => [realpathSync(resolve(repository, row.path)), row.sha256])),
    limits: {memoryMiB: 8192, rssMiB: 8192, pollMs: 10, timeoutMs: 300000},
    stopAfter: 'check', command,
    scope: 'Fresh C-native parse/expand/check using the authenticated existing executable. The existing native CLI owns validation and its guardian; report.json is its unmodified native report. C has no V8 heap-policy claim. Not JS performance, emission, fixedpoint or product acceptance.',
  };
  writeFileSync(resolve(out, 'request.json'), JSON.stringify(request, null, 2) + '\n', {flag: 'wx'});
  const child = spawn(command[0], command.slice(1), {cwd: repository, stdio: 'inherit'});
  return await new Promise<number>((done, fail) => {
    child.once('error', fail);
    child.once('close', (status, signal) => signal ? fail(Error('Native corpus screen stopped: ' + signal)) : done(status ?? 1));
  });
}
