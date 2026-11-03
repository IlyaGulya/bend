#!/usr/bin/env bun
/** Fresh native-produced-image checker screen, never full compiler acceptance.
 * bun evals/selfhost_corpus_run.ts MANIFEST IMAGE NATIVE-RECEIPT NODE FRESH-DIR
 * Uses the existing guarded throughput driver without altering its report.
 */
import {spawn} from 'node:child_process';
import {existsSync, mkdirSync, readFileSync, realpathSync, writeFileSync} from 'node:fs';
import {dirname, resolve} from 'node:path';
import {ABI, corpusFor, hashPath, workloadRows} from './native_seed_runtime.mjs';

const args = process.argv.slice(2);
if (!process.versions.bun || args.length !== 5)
  throw Error('Usage: bun evals/selfhost_corpus_run.ts MANIFEST IMAGE NATIVE-RECEIPT NODE FRESH-DIR');
const [manifestPath, imagePath, receiptPath, nodePath, outputPath] = args as [string,string,string,string,string];
const manifestFile = realpathSync(manifestPath), image = realpathSync(imagePath);
const receiptFile = realpathSync(receiptPath), node = realpathSync(nodePath), out = resolve(outputPath);
if (existsSync(out)) throw Error('Use a fresh output directory: ' + out);
const manifest = JSON.parse(readFileSync(manifestFile, 'utf8'));
if (manifest.schemaVersion !== 1 || JSON.stringify(manifest.exports) !== JSON.stringify(ABI) || !Array.isArray(manifest.files))
  throw Error('Expected ordinary native source corpus manifest');
const repository = realpathSync(resolve(dirname(manifestFile), manifest.directory));
const root = realpathSync(resolve(repository, manifest.root));
const previous = process.cwd();
let actual;
try { process.chdir(repository); actual = corpusFor(workloadRows(root, 'js')); }
finally { process.chdir(previous); }
const identity = (rows: any[]) => rows.map(row => {
  const file = realpathSync(resolve(repository, row.path));
  return [file, row.sha256, row.external === true ? null : row.namespace, row.external === true];
}).sort((a, b) => String(a[0]).localeCompare(String(b[0])));
if (JSON.stringify(identity(manifest.files)) !== JSON.stringify(identity(actual.files)))
  throw Error('Manifest differs from complete source closure, namespaces or foreign alternatives');
const receipt = JSON.parse(readFileSync(receiptFile, 'utf8')), imageSha256 = hashPath(image);
if (receipt.status !== 'NATIVE_FULL_COMPILE_PASS' || receipt.result?.result !== 'EmitSuccess'
  || realpathSync(receipt.output) !== image || receipt.outputSha256 !== imageSha256
  || JSON.stringify(receipt.exports) !== JSON.stringify(ABI)
  || !Array.isArray(receipt.command) || receipt.command.at(-2) !== 'compile' || realpathSync(receipt.command.at(-1)) !== image
  || JSON.stringify(receipt.phases?.map((phase: any) => phase.phase)) !== JSON.stringify(['parse', 'expand', 'check', 'emit'])
  || receipt.guardian?.status !== 'PASS' || receipt.guardian?.ownedTreeStopped !== true
  || receipt.guardian?.reportPhase !== 'complete' || receipt.guardian?.exitCode !== 0
  || receipt.guardian?.supervisorExitCode !== 0 || receipt.guardian?.commandExitCode !== 0 || receipt.guardian?.commandSignal !== 0
  || receipt.boundary?.cachedAst !== false || receipt.boundary?.hostParsing !== false
  || receipt.boundary?.hostChecking !== false || receipt.boundary?.checksExcluded !== 0 || receipt.boundary?.outputPatches !== 0)
  throw Error('Image lacks its matching successful unpatched native producer receipt');
const driver = realpathSync(resolve(import.meta.dir, 'selfhost_throughput.mjs'));
const files = ['selfhost_throughput.mjs', 'checker_core_step_runtime.mjs', 'selfhost_cpu_profile.mjs', 'native_seed_runtime.mjs', 'heavy_gate.ts']
  .map(name => realpathSync(resolve(import.meta.dir, name)));
const pins = Object.fromEntries([...files, image, receiptFile, manifestFile, node].map(file => [file, hashPath(file)]));
const inputs = Object.fromEntries(manifest.files.map((row: any) => [realpathSync(resolve(repository, row.path)), row.sha256]));
const request = {
  schemaVersion: 1, repository, root, image, node, exports: ABI, pins, inputs,
  limits: {memoryMiB: 8192, rssMiB: 8192, pollMs: 10, timeoutMs: 600000},
  stopAfter: 'check',
  scope: 'Frozen real-source corpus; fresh native-produced own-image parse/expand/check. Checker screen only, not emission, fixedpoint or product acceptance.',
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
