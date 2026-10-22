#!/usr/bin/env bun
/** Phased canonical parser regeneration with once-only native code generation.
 * --prepare-source emits corrected factored source and its fresh dependency graph.
 * --prepare --source-gate PATH applies the cut after the complete 71-case preparation proof.
 * --build-native authenticates prepared inputs and emits a provisional native artifact.
 * --build --candidate-gate PATH accepts that existing artifact after all 75 compiled cases.
 * Each public phase acquires the exclusive 8192 MiB footprint/RSS, 10 ms guardian.
 * Optional --run-id NAME selects a fresh namespace; historical artifacts stay intact.
 * Temporary generator changes are source/config redirects only, never output patches.
 * Fresh sequence (run all commands from the repository root, with one run-id):
 *   --prepare-source --run-id NAME
 *   bootstrap_parser_public_gate.ts --parser=SOURCE --entry=parse_module_tokens --report=PUBLIC
 *   bootstrap_parser_fast.ts --parser=SOURCE --entry=parse_module_tokens --public-report=PUBLIC --report=SOURCE_GATE
 *   --prepare --run-id NAME --source-gate SOURCE_GATE
 *   --build-native --run-id NAME
 *   bootstrap_parser_public_gate.ts --parser=CANDIDATE --entry=parse_with_fuel --report=PUBLIC_CANDIDATE
 *   bootstrap_parser_fast.ts --parser=CANDIDATE --entry=parse_with_fuel --component=ARTIFACT --component-build=NATIVE_RESULT --public-report=PUBLIC_CANDIDATE --report=CANDIDATE_GATE
 *   --build --run-id NAME --candidate-gate CANDIDATE_GATE
 * Gate scripts must run through heavy_gate.ts with --memory-mib 8192
 * --rss-mib 8192 --poll-ms 10. Every report path must be fresh.
 * The canonical NAME.native-build.result.json remains a provisional schema-4
 * receipt; only NAME.result.json publishes final parser acceptance. Root consumers
 * authenticate both the unchanged native receipt and this complete semantic barrier.
 */
import {createHash, randomUUID} from 'node:crypto';
import {appendFileSync, writeFileSync, rmSync} from 'node:fs';
import {dirname, relative, resolve} from 'node:path';
import {execFileSync} from 'node:child_process';
import {runHeavyGate, guardHeavyGate} from './heavy_gate.ts';
import * as Bend from '../bend2/bend.ts';
import {readParserGraph} from './parser_full_graph.ts';
import {termChildren} from './parser_full_type_env.ts';
import * as atom from './parse_atom_shape_source.ts';
import * as cases from './parse_case_shape_source.ts';
import * as doToken from './parse_do_token_shape_source.ts';
import * as operator from './operator_key_shape_source.ts';
import * as external from './external_import_shape_source.ts';
import * as symbols from './symbol_pair_shape_source.ts';
import {normalizeEvaluationContexts} from './parser_full_eval_context.ts';
import {authenticateNativeParserReceipt, authenticateParserSemanticGate} from './selfhost_driver_source.ts';

const root = resolve(import.meta.dir, '..');
if (resolve(process.cwd()) !== root) throw Error('Run from the repository root');
const canonicalPath = 'bend2/selfhost/parser.bend';
const release = '4ff8545f19b09b7d2b8ca2303668100eac8efd66';
const sha = (bytes: string | Uint8Array) => createHash('sha256').update(bytes).digest('hex');
const releaseKernelSha256 = sha(execFileSync('git', ['show', release + ':bend2/bend.ts'], {cwd: root}));
async function hash(path: string) { return sha(new Uint8Array(await Bun.file(path).arrayBuffer())); }
const helperPaths = [
  'evals/pattern_scan_partition_source.ts', 'evals/parse_atom_shape_source.ts',
  'evals/parse_body_shape_source.ts', 'evals/parse_case_shape_source.ts',
  'evals/parse_do_token_shape_source.ts', 'evals/operator_key_shape_source.ts',
  'evals/external_import_shape_source.ts', 'evals/symbol_pair_shape_source.ts',
];
const historicalCutPath = 'bend2/selfhost/parser_full_cut.json';
const baselineCandidatePath = 'bend2/selfhost/.parser_definition_body_shape_generated_fuel.bend';
const baselineScorecardPath = baselineCandidatePath + '.scorecard.json';
const gateSettings = {memoryMiB: 8192, rssMiB: 8192, pollMs: 10};
const args = process.argv.slice(2);
const mode = args.shift();
if (!['--prepare-source', '--prepare', '--build-native', '--build', '--worker-prepare-source', '--worker-prepare', '--worker-build-native', '--worker-build'].includes(mode ?? ''))
  throw Error('Usage: bun --smol evals/bootstrap_parser_rebuild.ts --prepare-source|--prepare --source-gate PATH|--build-native|--build --candidate-gate PATH [--run-id NAME]');
let runId: string | undefined, expectedCanonical: string | undefined;
let sourceGatePath: string | undefined, candidateGatePath: string | undefined;
while (args.length) {
  const key = args.shift(), value = args.shift();
  if (!value) throw Error('Missing option value');
  if (key === '--run-id' && runId === undefined) runId = value;
  else if (key === '--source-gate' && sourceGatePath === undefined) sourceGatePath = resolve(root, value);
  else if (key === '--candidate-gate' && candidateGatePath === undefined) candidateGatePath = resolve(root, value);
  else if (key === '--canonical-sha256' && expectedCanonical === undefined && mode!.startsWith('--worker-')) expectedCanonical = value;
  else throw Error('Unknown or duplicate option ' + key);
}
const publicPhase = mode!.replace('--worker-', '').replace('--', '');
if ((publicPhase === 'prepare') !== !!sourceGatePath || (publicPhase === 'build') !== !!candidateGatePath)
  throw Error('Only --prepare requires --source-gate; only --build requires --candidate-gate');
const canonicalSha256 = await hash(canonicalPath);
if (expectedCanonical && expectedCanonical !== canonicalSha256) throw Error('Canonical source changed before worker start');
runId ??= canonicalSha256.slice(0, 16);
if (!/^[A-Za-z0-9][A-Za-z0-9_-]{0,79}$/.test(runId)) throw Error('Unsafe run identifier');
const stem = resolve(root, 'checkpoints/bootstrap-parser-rebuild-' + runId);
const sourcePath = resolve(root, 'checkpoints/.bootstrap_parser_rebuild_' + runId + '_source.bend');
const outputBase = resolve(root, 'checkpoints/.bootstrap_parser_rebuild_' + runId + '_generated.bend');
const candidatePath = outputBase.replace('.bend', '_fuel.bend');
const graphPath = stem + '.graph.json';
const artifactPath = stem + '.js';
const manifestPath = stem + '.prepare.json';
const sourceManifestPath = stem + '.source-v1.json';
const overlayPath = stem + '.current-cut-v1.json';
const architecturePath = stem + '.architecture-delta-v1.json';
// Evidence records the complete native source context, not Parse's cyclic Book.
const json = (value: unknown) => JSON.stringify(value, (key, field) =>
  key === 'file' && field && typeof field === 'object' &&
  typeof field.str === 'string' && typeof field.ns === 'string' && field.al
    ? {str: field.str, ns: field.ns, al: field.al} : field, 2) + '\n';
function create(path: string, value: string | Uint8Array) { writeFileSync(path, value, {flag: 'wx'}); }

async function prerequisites() {
  if (process.platform !== 'darwin') throw Error('Accepted physical-footprint guardian requires macOS');
  const node = Bun.which('node');
  if (!node) throw Error('Canonical native builder requires Node/V8');
  if (await hash('bend2/bend.ts') !== releaseKernelSha256)
    throw Error('Kernel differs from exact official release Git blob ' + release);
  const inputs: Record<string, string> = {};
  const visit = async (input: string): Promise<void> => {
    const path = relative(root, resolve(root, input));
    if (Object.hasOwn(inputs, path)) return;
    if (path.startsWith('..') || path.startsWith('/')) throw Error('Input import escaped repository: ' + path);
    inputs[path] = await hash(path);
    if (path.endsWith('.ts')) {
      const text = await Bun.file(path).text();
      for (const match of text.matchAll(/\b(?:from\s*|import\s*)["'](\.[^"']+)["']/g))
        if (match[1]!.endsWith('.ts')) await visit(resolve(dirname(resolve(root, path)), match[1]!));
    }
    if (path.endsWith('.bend')) {
      const text = await Bun.file(path).text();
      for (const match of text.matchAll(/^import\s+(\S+)/gm)) {
        const imported = match[1]!;
        if (imported === 'Base') await visit('bend2/base.bend');
        else if (imported.startsWith('.')) await visit(resolve(dirname(resolve(root, path)), imported));
        else throw Error('Unresolved source manifest import: ' + imported + ' in ' + path);
      }
    }
  };
  for (const path of [...helperPaths, 'evals/parser_full_generate.ts', 'evals/bootstrap_parser_current_cut.ts',
    'evals/bootstrap_parser_rebuild.ts', 'evals/checker_core_component_build.ts',
    'evals/heavy_gate_native.c',
    'evals/bootstrap_parser_fast.ts', 'evals/bootstrap_parser_public_gate.ts', 'evals/bootstrap_token_worker.mjs',
    'evals/bootstrap_parser_native_semantic_worker.mjs', 'evals/bootstrap_ast_transport.ts',
    'bend2/comp.ts', 'bend2/base.bend', canonicalPath, historicalCutPath, baselineCandidatePath, baselineScorecardPath])
    await visit(path);
  return {node, release, releaseKernelSha256,
    acceptedInputs: Object.fromEntries(Object.entries(inputs).sort(([a], [b]) => a.localeCompare(b))),
    baselineScorecardSha256: await hash(baselineScorecardPath),
    runnerSha256: await hash(import.meta.path), canonicalSha256, guard: gateSettings};
}
const proof = await prerequisites();
if (!mode!.startsWith('--worker-')) {
  // The public entrypoint always supplies the exact cap, independently of env.
  create(stem + '.' + publicPhase + '.request.json', json(proof));
  const gateArgs = sourceGatePath ? ['--source-gate', sourceGatePath] : candidateGatePath ? ['--candidate-gate', candidateGatePath] : [];
  const result = await runHeavyGate([process.execPath, '--smol', import.meta.path,
    '--worker-' + publicPhase, '--run-id', runId, '--canonical-sha256', canonicalSha256, ...gateArgs],
    {...gateSettings, label: 'Final canonical bootstrap parser ' + mode});
  create(stem + '.' + publicPhase + '.guardian.json', json({...result, pollMs: 10}));
  if (publicPhase === 'build-native' && result.status === 'PASS') {
    const authorizationPath = stem + '.native-build-authorized.json';
    const authorization = await Bun.file(authorizationPath).json();
    await stableInputs();
    for (const [path, digest] of Object.entries(authorization.authenticatedInputs) as [string, string][])
      if (await hash(path) !== digest) throw Error('Prepared native-build input drift: ' + path);
    const child = Bun.spawn(authorization.command, {stdout: 'inherit', stderr: 'inherit', stdin: 'ignore'});
    if (await child.exited !== 0) throw Error('Canonical native parser build failed');
    const native = authenticateNativeParserReceipt(authorization.parserBuildPath), receipt = native.accepted;
    if (receipt.sourcePath !== candidatePath || receipt.sourceSha256 !== authorization.candidateSha256 ||
      receipt.artifactPath !== artifactPath || !sameNames(receipt.exports, ['parse_with_fuel']))
      throw Error('Canonical parser build receipt mismatch');
    await stableInputs();
    for (const [path, digest] of Object.entries(authorization.authenticatedInputs) as [string, string][])
      if (await hash(path) !== digest) throw Error('Prepared input changed during native code generation: ' + path);
    create(stem + '.native-auth.json', json({schemaVersion: 1, status: 'PROVISIONAL_NATIVE_ARTIFACT',
      runId, ...proof, ...authorization, admitted: false, preparationAdmitted: false,
      authorizationPath, authorizationSha256: await hash(authorizationPath),
      artifactSha256: receipt.artifactSha256, parserBuildSha256: await hash(authorization.parserBuildPath),
      provenancePath: receipt.provenancePath, provenanceSha256: receipt.provenanceSha256,
      nativeAuthenticatedInputs: native.authenticatedInputs, guardianPath: stem + '.build-native.guardian.json',
      guardianSha256: await hash(stem + '.build-native.guardian.json'),
      requestPath: stem + '.build-native.request.json', requestSha256: await hash(stem + '.build-native.request.json'),
      workerLogPath: stem + '.build-native.jsonl', workerLogSha256: await hash(stem + '.build-native.jsonl'),
      checksExcluded: 0, outputPatches: 0, compiledExecution: 'NOT_RUN', selfhostGreen: false}));
  } else if (publicPhase === 'build' && result.status === 'PASS') {
    const authorizationPath = stem + '.acceptance-authorized.json';
    const authorization = await Bun.file(authorizationPath).json();
    await stableInputs();
    for (const [path, digest] of Object.entries(authorization.authenticatedInputs) as [string, string][])
      if (await hash(path) !== digest) throw Error('Final acceptance input drift: ' + path);
    create(stem + '.result.json', json({schemaVersion: 1, status: 'PARSER_ACCEPTED_NATIVE_SEMANTICS',
      runId, ...proof, ...authorization, admitted: true, preparationAdmitted: false,
      evaluationMode: 'native-artifact', authorizationPath, authorizationSha256: await hash(authorizationPath),
      guardianPath: stem + '.build.guardian.json', guardianSha256: await hash(stem + '.build.guardian.json'),
      requestPath: stem + '.build.request.json', requestSha256: await hash(stem + '.build.request.json'),
      workerLogPath: stem + '.build.jsonl', workerLogSha256: await hash(stem + '.build.jsonl'),
      checksExcluded: 0, outputPatches: 0, compiledExecution: 'FULL_75_SEMANTIC_GATE', selfhostGreen: false}));
  }
  console.log(json({runId, canonicalSha256, sourceManifestPath, sourcePath, graphPath, manifestPath, candidatePath, artifactPath, ...result}));
  process.exit(result.status === 'PASS' ? 0 : result.exitCode || 2);
}
// A direct internal-mode invocation must not fall back to the guardian's
// smaller/default environmental cap. Public modes always acquire this lane.
process.argv.push('--memory-mib', '8192', '--rss-mib', '8192', '--poll-ms', '10');
await guardHeavyGate(import.meta.path, {label: 'Final canonical bootstrap parser worker'});
const start = performance.now();
let phase = publicPhase === 'build' || publicPhase === 'build-native' ? 'load' : publicPhase === 'prepare-source' ? 'source' : 'cut';
const logPath = stem + '.' + publicPhase + '.jsonl';
create(logPath, '');
function event(data: object) {
  const row = {phase, elapsedMs: performance.now() - start, bunVersion: Bun.version,
    runtimeArgs: process.execArgv, ...data};
  appendFileSync(logPath, JSON.stringify(row) + '\n');
  writeFileSync(stem + '.progress.json', json(row));
}
type Redirect = readonly [string, string];
function redirect(original: string, changes: readonly Redirect[]) {
  let changed = original;
  for (const [before, after] of changes) {
    if (changed.split(before).length !== 2) throw Error('Configuration redirect anchor drift: ' + before);
    changed = changed.replace(before, after);
  }
  let recovered = changed;
  for (const [before, after] of [...changes].reverse()) {
    if (recovered.split(after).length !== 2) throw Error('Configuration redirect inverse anchor drift');
    recovered = recovered.replace(after, before);
  }
  if (recovered !== original) throw Error('Non-invertible configuration redirect');
  return {source: changed, originalSha256: sha(original), configuredSha256: sha(changed), changes, exactInverse: true};
}
async function stableInputs() {
  if (await hash(canonicalPath) !== canonicalSha256) throw Error('Canonical source changed during run');
  const after = await prerequisites();
  if (JSON.stringify(after) !== JSON.stringify(proof)) throw Error('Prerequisite drift during run');
}
function sameNames(left: readonly string[], right: readonly string[]) {
  return JSON.stringify([...left].sort()) === JSON.stringify([...right].sort());
}
function mutualSCCs(edges: Record<string, string[]>, removed: ReadonlySet<string> = new Set()): string[][] {
  let clock = 0;
  const index = new Map<string, number>(), low = new Map<string, number>();
  const stack: string[] = [], active = new Set<string>(), components: string[][] = [];
  function visit(name: string) {
    index.set(name, clock); low.set(name, clock++); stack.push(name); active.add(name);
    for (const target of edges[name] ?? []) {
      if (removed.has(target) || !Object.hasOwn(edges, target)) continue;
      if (!index.has(target)) { visit(target); low.set(name, Math.min(low.get(name)!, low.get(target)!)); }
      else if (active.has(target)) low.set(name, Math.min(low.get(name)!, index.get(target)!));
    }
    if (low.get(name) !== index.get(name)) return;
    const component: string[] = [];
    let target: string;
    do { target = stack.pop()!; active.delete(target); component.push(target); } while (target !== name);
    if (component.length > 1) components.push(component.sort());
  }
  for (const name of Object.keys(edges).sort()) if (!removed.has(name) && !index.has(name)) visit(name);
  return components.sort((a, b) => a.join('\0') < b.join('\0') ? -1 : 1);
}
async function guardianProof(name: string) {
  const gate = await Bun.file(stem + '.' + name + '.guardian.json').json();
  if (gate.status !== 'PASS' || gate.memoryLimitBytes !== 8192 * 1024 * 1024 ||
    gate.rssLimitBytes !== 8192 * 1024 * 1024 || gate.pollMs !== 10)
    throw Error(name + ' lacks accepted guardian proof');
}
function inputProof(manifest: Record<string, unknown>) {
  if (manifest.canonicalSha256 !== canonicalSha256 || manifest.runId !== runId ||
    JSON.stringify(manifest.acceptedInputs) !== JSON.stringify(proof.acceptedInputs) ||
    manifest.runnerSha256 !== proof.runnerSha256)
    throw Error('Phase manifest input/config mismatch');
}
async function sourceProof() {
  const manifest = await Bun.file(sourceManifestPath).json();
  await guardianProof('prepare-source'); inputProof(manifest);
  if (manifest.schemaVersion !== 1 || manifest.status !== 'FACTORED_AWAITING_SEMANTIC_GATE' ||
    manifest.sourcePath !== sourcePath || manifest.graphPath !== graphPath ||
    await hash(sourcePath) !== manifest.transformedSha256 || await hash(graphPath) !== manifest.graphSha256)
    throw Error('Factored source manifest drift');
  const graph = await Bun.file(graphPath).json();
  if (graph.path !== sourcePath || graph.sourceSha256 !== manifest.transformedSha256 ||
    graph.sourceCheckpoint !== manifest.transformedSha256.slice(0, 8) ||
    !Array.isArray(graph.unresolvedReferences) || graph.unresolvedReferences.length)
    throw Error('Factored source graph is not closed');
  return {manifest, graph};
}
async function semanticProof(path: string, parserPath: string, entryPoint: string, phase: 'source' | 'candidate') {
  const result = authenticateParserSemanticGate(path, {phase, parserPath, canonicalSha256,
    kernelSha256: releaseKernelSha256,
    ...(phase === 'candidate' ? {component: {artifactPath, nativeBuildPath: stem + '.native-build.result.json'}} : {})});
  if (result.entryPoint !== entryPoint) throw Error('Semantic entrypoint phase mismatch');
  await stableInputs();
  return result;
}
async function overlayProof(graph: {edges: Record<string, string[]>}, transformedSha256: string) {
  const cut = await Bun.file(overlayPath).json(), historical = await Bun.file(historicalCutPath).json();
  const seeds = [...(historical.completeSelected ?? historical.selected)].sort() as string[];
  const delta = cut.newlySelected as string[], complete = cut.completeSelected as string[];
  // Recompute rather than pin the pre-normalization four-vertex choice.
  const sourceVertices = new Set([...(await Bun.file(canonicalPath).text()).matchAll(/^def ([A-Za-z_]\w*)\(/gm)]
    .map(match => match[1]!));
  if (cut.schemaVersion !== 1 || resolve(root, cut.graphPath) !== graphPath || resolve(root, cut.factoredPath) !== sourcePath ||
    cut.sourceSha256 !== transformedSha256 || cut.factoredSha256 !== transformedSha256 ||
    cut.sourceCheckpoint !== transformedSha256.slice(0, 8) || cut.canonicalSha256 !== canonicalSha256 ||
    cut.currentGraphSha256 !== await hash(graphPath) || cut.graphSourceSha256 !== transformedSha256 ||
    cut.historicalCutSha256 !== await hash(historicalCutPath) || resolve(root, cut.historicalPath) !== resolve(root, historicalCutPath) ||
    seeds.length !== 14 || new Set(seeds).size !== 14 ||
    !sameNames(cut.historicalSelected, seeds) || cut.historicalSourceSha256 !== historical.sourceSha256 ||
    cut.historicalSourceCheckpoint !== historical.sourceCheckpoint || !sameNames(cut.selected, historical.selected))
    throw Error('Current-cut proof input/history mismatch');
  if (!Number.isInteger(cut.minimumCardinality) || cut.minimumCardinality < 0 || cut.minimumCardinality > sourceVertices.size ||
    delta.length !== cut.minimumCardinality || new Set(delta).size !== delta.length || complete.length !== 14 + delta.length ||
    new Set(complete).size !== complete.length || complete.some(name => !Object.hasOwn(graph.edges, name)) ||
    !sameNames(complete, [...seeds, ...delta]) ||
    !Array.isArray(cut.minimumSolutions) || !cut.minimumSolutions.length ||
    !sameNames(cut.minimumSolutions[0], delta) ||
    cut.minimumSolutions.some((solution: string[]) => solution.length !== cut.minimumCardinality || new Set(solution).size !== solution.length ||
      solution.some(name => !sourceVertices.has(name) || seeds.includes(name)) ||
      mutualSCCs(graph.edges, new Set([...seeds, ...solution])).length))
    throw Error('Fresh exact minimum cut proof is inconsistent');
  const vectors = cut.minimumSolutions.map((solution: string[]) => [...solution].sort().join('\0'));
  if (vectors[0] !== [...vectors].sort()[0] || new Set(vectors).size !== vectors.length ||
    !Array.isArray(cut.remainingMutualSCCs) || cut.remainingMutualSCCs.length ||
    mutualSCCs(graph.edges, new Set(complete)).length)
    throw Error('Current cut leaves mutual recursion or violates lexicographic proof');
  return cut;
}
async function structuralProof() {
  const source = await Bun.file(candidatePath).text(), graph = await readParserGraph(source, candidatePath);
  const cut=await Bun.file(overlayPath).json();
  const selectedNames=new Set<string>(cut.completeSelected);
  const selectedCallsUnderLambda:{owner:string;callee:string;offset:number}[]=[];
  function inspectTerm(owner:string,term:Bend.LTerm,underLambda=false){
    const delayed=underLambda||term.$==='Lam';
    if(delayed&&term.$==='Ref'&&selectedNames.has(term.k))
      selectedCallsUnderLambda.push({owner,callee:term.k,offset:term.s?.beg??-1});
    for(const child of termChildren(term))inspectTerm(owner,child,delayed);
  }
  function inspectBody(owner:string,body:Bend.Body){
    if(body.$==='Local'){body.v.forEach(term=>inspectTerm(owner,term));inspectBody(owner,body.f);}
    else if(body.$==='Match'){body.e.forEach(term=>inspectTerm(owner,term));body.r.forEach(row=>inspectBody(owner,row.f));}
    else inspectTerm(owner,body);
  }
  for(const [owner,body]of graph.bodies)inspectBody(owner,body);
  const remainingMutualSCCs=mutualSCCs(graph.edges);
  if(graph.unresolvedReferences.length||remainingMutualSCCs.length||selectedCallsUnderLambda.length||
    !graph.definitions.includes('parse_with_fuel')){
    create(stem+'.generated-structural-failure.json',json({unresolvedReferences:graph.unresolvedReferences,
      remainingMutualSCCs,selectedCallsUnderLambda}));
    throw Error('Generated candidate lacks closed acyclic first-order structural proof');
  }
  const feedbackBoundaries:Record<string,{factoryCalls:number;stepCallers:string[]}>={};
  for(const selected of cut.completeSelected as string[]){
    const factory='feedback_make_'+selected,step='step_'+selected;
    if(graph.definitions.includes(selected)||!graph.definitions.includes(factory)||!graph.definitions.includes(step))
      throw Error('Selected source function did not become a Request boundary: '+selected);
    const maker=graph.bodies.get(factory);
    function constructsRequest(body:Bend.Body):boolean{
      if(body.$!=='Match'&&body.$!=='Local')return body.$==='Ctr'&&body.k==='Request_'+selected;
      // The unchanged maker flattens product arguments by matching their fields.
      return body.$==='Match'&&body.r.length>0&&body.r.every(row=>constructsRequest(row.f));
    }
    if(!maker||!constructsRequest(maker))
      throw Error('Feedback factory does not construct its generic Request variant: '+selected);
    const stepCallers=[...new Set(graph.astReferences.filter(ref=>ref.callee===step).map(ref=>ref.caller))].sort();
    if(stepCallers.length!==1||stepCallers[0]!=='feedback_dispatch')
      throw Error('Selected step has a caller outside generic Request dispatch: '+selected);
    let factoryCalls=0;
    function expression(term:Bend.LTerm,insideCall:boolean){
      const enclosed=insideCall||(term.$==='Ctr'&&term.k==='FeedbackCall');
      const [head,args]=Bend.term_unapply(term);
      if(term.$==='App'&&head.$==='Ref'&&head.k===factory){
        if(!enclosed)throw Error('Selected call escaped FeedbackCall construction: '+selected);
        factoryCalls++;
        args.forEach(argument=>expression(argument,enclosed));return;
      }
      for(const child of termChildren(term))expression(child,enclosed);
    }
    function body(node:Bend.Body){
      if(node.$==='Local'){node.v.forEach(value=>expression(value,false));body(node.f);}
      else if(node.$==='Match'){node.e.forEach(value=>expression(value,false));node.r.forEach(row=>body(row.f));}
      else expression(node,false);
    }
    for(const node of graph.bodies.values())body(node);
    if(factoryCalls===0)throw Error('Selected Request factory has no lowered source calls: '+selected);
    feedbackBoundaries[selected]={factoryCalls,stepCallers};
  }
  return {candidateSha256: sha(source), unresolvedReferences: 0, remainingMutualSCCs: [],selectedCallsUnderLambda:0,feedbackBoundaries,
    definitions: graph.definitions.length, lines: source.split('\n').length - 1, bytes: Buffer.byteLength(source)};
}
const temporaryPaths: string[] = [];
try {
  event({stage: 'prerequisites-pass', ...proof});
  if (mode === '--worker-prepare-source') {
    if (await Bun.file(sourceManifestPath).exists() || await Bun.file(candidatePath).exists() || await Bun.file(sourcePath).exists())
      throw Error('Preparation namespace already used');
    const canonicalGraph = await readParserGraph(await Bun.file(canonicalPath).text());
    const scanner = canonicalGraph.bodies.get('pattern_scan');
    if (scanner?.$ !== 'Match') throw Error('Canonical scanner is not a match');
    const rowCount = scanner.r.length;
    // Grammar additions change only row/literal-count configuration. The current
    // authorized helper bytes implement generic binder-ID lexical captures.
    const patternConfig = redirect(await Bun.file('evals/pattern_scan_partition_source.ts').text(), [
      ['m.r.length!==20', 'm.r.length!==' + rowCount],
      ['i<20', 'i<' + rowCount],
      ['i+1<20', 'i+1<' + rowCount],
    ]);
    const patternPath = resolve(root, 'evals/.bootstrap_parser_pattern_' + randomUUID() + '.ts');
    temporaryPaths.push(patternPath); create(patternPath, patternConfig.source);
    create(stem + '.pattern-config.json', json({...patternConfig, source: undefined, sourceConfigOnly: true, rowCount, completedLiteralCount: 5}));
    const pattern = await import(patternPath) as typeof import('./pattern_scan_partition_source.ts');
    const bodyPath = resolve(root, 'evals/parse_body_shape_source.ts');
    const body = await import(bodyPath) as typeof import('./parse_body_shape_source.ts');
    create(stem + '.body-config.json', json({sourceConfigOnly: false, genericNativeRows: true,
      helperPath: bodyPath, helperSha256: await hash(bodyPath)}));
    const stages = [
      ['patternScanner', pattern.partitionPatternScanSource], ['atomScanner', atom.extractAtomShape], ['bodyScanner', body.extractBodyShape],
      ['caseScanner', cases.extractCaseShape], ['doTokenScanner', doToken.extractDoTokenShape], ['arrayScanner', doToken.extractArrayShape],
      ['operatorKey', operator.extractOperatorKeyShape], ['matchTail', cases.extractMatchTailShape], ['tailScan', cases.extractMatchTailScanShape],
      ['braceRight', cases.extractBraceRightShape], ['braceAnnot', cases.extractBraceAnnotShape], ['braceEquals', doToken.extractBraceEqualsShape],
      ['inequality', cases.extractInequalityShape], ['inequalityRight', cases.extractInequalityRightShape], ['allNamedType', cases.extractAllNamedTypeShape],
      ['indexResult', cases.extractIndexResultShape], ['rewriteMotive', cases.extractRewriteMotiveShape], ['matchScrutinees', cases.extractMatchScrutineesShape],
      ['definitionHeader', cases.extractDefinitionHeaderShape], ['externalImport', external.extractExternalImportShape], ['symbolPair', symbols.extractSymbolPairShape],
      ['symbolTriple', symbols.extractSymbolTripleShape], ['definitionBody', cases.extractDefinitionBodyShape],
      ['caseBodyLayout', cases.normalizeInlineCaseBodies],
      ['evaluationContexts', async (source: string) => {
        const historical = await Bun.file(historicalCutPath).json();
        const seeds = historical.completeSelected ?? historical.selected;
        const normalized = await normalizeEvaluationContexts(source, seeds);
        if (normalized.graph.unresolvedReferences.length || normalized.sourceSpecificTransformerExceptions !== 0)
          throw Error('Evaluation-context factoring is not generically closed');
        create(stem + '.evaluation-contexts.json', json(normalized.contexts));
        return {...normalized, audit: {originalSha256: sha(source), transformedSha256: sha(normalized.source),
          contexts: normalized.contexts, sourceSpecificTransformerExceptions: 0}};
      }],
    ] as const;
    let currentSource = await Bun.file(canonicalPath).text();
    let latest: {source: string; graph: {definitions: string[]; edges: Record<string, string[]>; unresolvedReferences: unknown[]}; audit: {originalSha256: string; transformedSha256: string}} | undefined;
    const audits: Record<string, unknown> = {};
    for (const [name, transform] of stages) {
      const before = sha(currentSource);
      latest = await transform(currentSource);
      if (!latest || latest.audit.originalSha256 !== before || latest.audit.transformedSha256 !== sha(latest.source))
        throw Error('Source factoring audit mismatch: ' + name);
      currentSource = latest.source; audits[name] = latest.audit;
      event({stage: 'factoring-stage-pass', name, sourceSha256: sha(currentSource)});
    }
    if (!latest) throw Error('No source factoring result');
    if (latest.graph.unresolvedReferences.length) {
      create(stem + '.failed-factored-source.bend', currentSource);
      create(stem + '.failed-factored-references.json', json(latest.graph.unresolvedReferences));
      event({stage:'factoring-unresolved', references:latest.graph.unresolvedReferences});
      throw Error('Corrected factoring has unresolved source references');
    }
    // Parser and compiler roots share one physical directory and import
    // namespace. Relocate only imports; every canonical declaration is intact.
    const beforeRelocation = sha(currentSource);
    currentSource = currentSource.replace(/^import (\S+) as ([A-Za-z_]\w*)$/gm, (_, path: string, alias: string) => {
      const target = resolve(dirname(resolve(canonicalPath)), path);
      let spelling = relative(dirname(sourcePath), target).replaceAll('\\', '/');
      if (!spelling.startsWith('.')) spelling = './' + spelling;
      return 'import ' + spelling + ' as ' + alias;
    });
    audits.importRelocation = {originalSha256: beforeRelocation, transformedSha256: sha(currentSource),
      canonicalDirectory: dirname(resolve(canonicalPath)), generatedDirectory: dirname(sourcePath)};
    create(sourcePath, currentSource);
    const transformedSha256 = sha(currentSource);
    create(stem + '.audit.json', json({canonicalSha256, transformedSha256, stages: audits,
      currentInputs: proof.acceptedInputs, generatorLogicUnchanged: true}));
    create(graphPath, json({schemaVersion: 1, kind: 'capture-fixed-factored', path: sourcePath,
      canonicalSha256, sourceCheckpoint: transformedSha256.slice(0, 8), sourceSha256: transformedSha256,
      definitions: latest.graph.definitions, edges: latest.graph.edges, unresolvedReferences: latest.graph.unresolvedReferences}));
    await stableInputs();
    create(sourceManifestPath, json({schemaVersion: 1, status: 'FACTORED_AWAITING_SEMANTIC_GATE', runId, ...proof,
      sourcePath, transformedSha256, graphPath, graphSha256: await hash(graphPath), unresolvedReferences: 0}));
    event({stage: 'factored-source-pass', sourcePath, transformedSha256, graphPath, sourceManifestPath});
  } else if (mode === '--worker-prepare') {
    if (await Bun.file(manifestPath).exists() || await Bun.file(candidatePath).exists() || await Bun.file(overlayPath).exists())
      throw Error('Generation namespace already used');
    const {manifest: sourceManifest, graph} = await sourceProof();
    const transformedSha256 = sourceManifest.transformedSha256;
    const sourceSemanticGate = await semanticProof(sourceGatePath!, sourcePath, 'parse_module_tokens', 'source');
    // The exact solver runs only on this freshly prepared graph, after cheap
    // semantic proof. It chooses the lexicographic minimum; authorization below
    // validates that choice, never selects vertices independently.
    const solver = Bun.spawn([process.execPath, '--smol', 'evals/bootstrap_parser_current_cut.ts',
      '--graph=' + graphPath, '--factored=' + sourcePath, '--output=' + overlayPath],
      {stdout: 'inherit', stderr: 'inherit', stdin: 'ignore'});
    if (await solver.exited !== 0) throw Error('Fresh exact current-cut proof failed');
    const overlay = await overlayProof(graph, transformedSha256);
    const generator = await Bun.file('evals/parser_full_generate.ts').text();
    const configured = redirect(generator, [
      ['const input = resolve(import.meta.dir, "../bend2/selfhost/parser.bend");', 'const input = ' + JSON.stringify(sourcePath) + ';'],
      ['const output = resolve(import.meta.dir, "../bend2/selfhost/parser_full_generated.bend");', 'const output = ' + JSON.stringify(outputBase) + ';'],
      [generator.match(/const expected = "[0-9a-f]{64}";/)?.[0] ?? '', 'const expected = "' + transformedSha256 + '";'],
      ['const currentGraphPath = resolve(import.meta.dir, "../bend2/selfhost/parser_full_current_graph.json");', 'const currentGraphPath = ' + JSON.stringify(graphPath) + ';'],
      ['const cutPath = resolve(import.meta.dir, "../bend2/selfhost/parser_full_cut.json");', 'const cutPath = ' + JSON.stringify(overlayPath) + ';'],
      ['cut.sourceSha256 !== "0009070688f8fffffbb8664e72bd4662bf1324675ba097297076d77939153df5"',
        'cut.sourceSha256 !== "' + transformedSha256 + '"'],
      ['cut.sourceCheckpoint !== "0d0e204f"', 'cut.sourceCheckpoint !== "' + transformedSha256.slice(0, 8) + '"'],
    ]);
    const generatorPath = resolve(root, 'evals/.bootstrap_parser_generator_' + randomUUID() + '.ts');
    temporaryPaths.push(generatorPath); create(generatorPath, configured.source);
    create(stem + '.generator-config.json', json({...configured, source: undefined, sourceConfigOnly: true, outputPatches: 0}));
    phase = 'generation'; event({stage: 'generation-start', generatorPath, logicUnchanged: true});
    const child = Bun.spawn([process.execPath, '--smol', generatorPath, '--fuel-parametric'], {stdout: 'inherit', stderr: 'inherit', stdin: 'ignore'});
    if (await child.exited !== 0) throw Error('Unchanged fuel-parametric generator failed');
    const candidateSha256 = await hash(candidatePath);
    const scorecardPath = candidatePath + '.scorecard.json';
    const scorecard = await Bun.file(scorecardPath).json();
    if (scorecard.generatedSha256 !== candidateSha256 || scorecard.sourceSha256 !== transformedSha256 ||
      scorecard.currentGraphSha256 !== await hash(graphPath) || !scorecard.candidateEmitted ||
      !sameNames(scorecard.completeSelected, overlay.completeSelected) ||
      !sameNames(scorecard.requestVariants, overlay.completeSelected) ||
      scorecard.sourceSpecificTransformerExceptions !== 0 ||
      scorecard.declarationMetadata?.missing?.length !== 0 || scorecard.declarationMetadata?.spurious?.length !== 0)
      throw Error('Generated candidate scorecard/cut mismatch');
    const structuralGate = await structuralProof();
    if (scorecard.generatedBytes !== structuralGate.bytes || scorecard.generatedLines !== structuralGate.lines ||
      scorecard.emittedDefinitions !== structuralGate.definitions)
      throw Error('Generated candidate structural scorecard mismatch');
    const oldScorecard = await Bun.file(baselineScorecardPath).json();
    const oldSource = await Bun.file(baselineCandidatePath).text();
    if (oldScorecard.generatedSha256 !== sha(oldSource) || oldScorecard.requestVariants.length !== 14)
      throw Error('Historical generated architecture baseline mismatch');
    const oldDefinitions = [...oldSource.matchAll(/^def ([A-Za-z_]\w*)\(/gm)].map(match => match[1]!);
    const architecture = (card: typeof scorecard, definitions: number, lines: number, bytes: number) => ({
      requests: card.requestVariants, konts: card.kontVariants.map((frame: {name: string}) => frame.name),
      liftedFunctions: [...card.completeSelected, ...card.mechanicallyLiftedFunctions].sort(), definitions, lines, bytes,
    });
    const before = architecture(oldScorecard, oldDefinitions.length, oldSource.split('\n').length - 1, Buffer.byteLength(oldSource));
    const after = architecture(scorecard, structuralGate.definitions, structuralGate.lines, structuralGate.bytes);
    const addedRemoved = (left: string[], right: string[]) => ({
      added: right.filter(name => !left.includes(name)).sort(), removed: left.filter(name => !right.includes(name)).sort(),
    });
    create(architecturePath, json({schemaVersion: 1, baselineCandidatePath, baselineCandidateSha256: sha(oldSource),
      baselineScorecardPath, baselineScorecardSha256: proof.baselineScorecardSha256, candidatePath, candidateSha256,
      historicalCutSha256: await hash(historicalCutPath), overlayPath, overlaySha256: await hash(overlayPath),
      cut: {before: 14, after: overlay.completeSelected.length, delta: overlay.newlySelected}, before, after,
      delta: {requests: addedRemoved(before.requests, after.requests), konts: addedRemoved(before.konts, after.konts),
        liftedFunctions: addedRemoved(before.liftedFunctions, after.liftedFunctions),
        definitions: after.definitions - before.definitions, lines: after.lines - before.lines, bytes: after.bytes - before.bytes}}));
    await stableInputs();
    create(manifestPath, json({schemaVersion: 1, status: 'PREPARED_NOT_BUILT', runId, ...proof, sourcePath, transformedSha256,
      sourceManifestPath, sourceManifestSha256: await hash(sourceManifestPath), sourceSemanticGate, structuralGate,
      graphPath, graphSha256: await hash(graphPath), overlayPath, overlaySha256: await hash(overlayPath),
      architecturePath, architectureSha256: await hash(architecturePath), outputBase, candidatePath, candidateSha256,
      scorecardPath, scorecardSha256: await hash(scorecardPath), artifactPath,
      sourceConfigOnly: true, outputPatches: 0, selfhostGreen: false}));
    event({stage: 'generation-pass', candidatePath, candidateSha256, manifestPath});
  } else {
    const manifest = await Bun.file(manifestPath).json();
    await guardianProof('prepare'); inputProof(manifest);
    const {graph} = await sourceProof();
    if (manifest.schemaVersion !== 1 || manifest.status !== 'PREPARED_NOT_BUILT' ||
      manifest.sourcePath !== sourcePath || manifest.candidatePath !== candidatePath || manifest.artifactPath !== artifactPath ||
      manifest.overlayPath !== overlayPath || manifest.architecturePath !== architecturePath)
      throw Error('Prepared manifest input/config mismatch');
    for (const [path, pin] of [[sourcePath, manifest.transformedSha256], [candidatePath, manifest.candidateSha256],
      [graphPath, manifest.graphSha256], [candidatePath + '.scorecard.json', manifest.scorecardSha256],
      [sourceManifestPath, manifest.sourceManifestSha256], [overlayPath, manifest.overlaySha256],
      [architecturePath, manifest.architectureSha256]])
      if (await hash(path) !== pin) throw Error('Prepared input drift: ' + path);
    const sourceSemanticGate = await semanticProof(manifest.sourceSemanticGate.path, sourcePath, 'parse_module_tokens', 'source');
    if (JSON.stringify(sourceSemanticGate) !== JSON.stringify(manifest.sourceSemanticGate))
      throw Error('Factored semantic gate changed after generation');
    await overlayProof(graph, manifest.transformedSha256);
    const structuralGate = await structuralProof();
    if (JSON.stringify(structuralGate) !== JSON.stringify(manifest.structuralGate))
      throw Error('Generated structural gate drift');
    if (mode === '--worker-build-native') {
      create(stem + '.native-build.started.json', json({canonicalSha256, candidateSha256: manifest.candidateSha256, onceOnly: true}));
      if (await Bun.file(artifactPath).exists() || await Bun.file(stem + '.native-build.result.json').exists() ||
        await Bun.file(stem + '.native-auth.json').exists() || await Bun.file(stem + '.result.json').exists())
        throw Error('Native artifact namespace already used');
      // Authorize the canonical producer once, without pretending source evaluation
      // admitted this parser. The public entrypoint runs it only after lane release.
      phase = 'native-build';
      const buildReport = stem + '.native-build';
      const command = [process.execPath, '--smol', resolve(root, 'evals/checker_core_component_build.ts'),
        '--file=' + candidatePath, '--exports=parse_with_fuel',
        '--artifact=' + artifactPath, '--report=' + buildReport];
      const authenticatedInputs: Record<string, string> = {...sourceSemanticGate.authenticatedInputs};
      for (const path of [manifestPath, sourceManifestPath, graphPath, overlayPath, architecturePath,
        candidatePath, candidatePath + '.scorecard.json', stem + '.native-build.started.json',
        ...['prepare-source', 'prepare'].flatMap(name => ['guardian.json', 'request.json', 'jsonl']
          .map(suffix => stem + '.' + name + '.' + suffix))])
        authenticatedInputs[path] = await hash(path);
      create(stem + '.native-build-authorized.json', json({command, parserBuildPath: buildReport + '.result.json',
        manifestPath, manifestSha256: await hash(manifestPath), sourceCandidate: candidatePath,
        candidateSha256: manifest.candidateSha256, artifactPath, sourceSemanticGate, structuralGate, authenticatedInputs}));
      event({stage: 'provisional-canonical-build-authorized', command});
    } else {
      if (await Bun.file(stem + '.result.json').exists()) throw Error('Final acceptance namespace already used');
      await guardianProof('build-native');
      const nativeProofPath = stem + '.native-auth.json', nativeProof = await Bun.file(nativeProofPath).json();
      inputProof(nativeProof);
      const native = authenticateNativeParserReceipt(stem + '.native-build.result.json'), receipt = native.accepted;
      if (nativeProof.schemaVersion !== 1 || nativeProof.status !== 'PROVISIONAL_NATIVE_ARTIFACT' ||
        nativeProof.admitted !== false || nativeProof.manifestPath !== manifestPath ||
        nativeProof.manifestSha256 !== await hash(manifestPath) || nativeProof.parserBuildPath !== native.parserBuild ||
        nativeProof.parserBuildSha256 !== await hash(native.parserBuild) ||
        nativeProof.artifactPath !== artifactPath || nativeProof.artifactSha256 !== receipt.artifactSha256 ||
        nativeProof.provenancePath !== receipt.provenancePath || nativeProof.provenanceSha256 !== receipt.provenanceSha256 ||
        receipt.sourcePath !== candidatePath || receipt.sourceSha256 !== manifest.candidateSha256 ||
        receipt.artifactPath !== artifactPath || !sameNames(receipt.exports, ['parse_with_fuel']) ||
        JSON.stringify(nativeProof.sourceSemanticGate) !== JSON.stringify(sourceSemanticGate) ||
        JSON.stringify(nativeProof.structuralGate) !== JSON.stringify(structuralGate) ||
        JSON.stringify(nativeProof.nativeAuthenticatedInputs) !== JSON.stringify(native.authenticatedInputs))
        throw Error('Provisional native artifact/receipt/preparation proof drift');
      for (const [field, suffix] of [['authorization', '.native-build-authorized.json'],
        ['guardian', '.build-native.guardian.json'], ['request', '.build-native.request.json'],
        ['workerLog', '.build-native.jsonl']] as const)
        if (nativeProof[field + 'Path'] !== stem + suffix ||
          nativeProof[field + 'Sha256'] !== await hash(stem + suffix))
          throw Error('Provisional native producer evidence drift: ' + field);
      for (const [path, digest] of Object.entries(nativeProof.authenticatedInputs) as [string, string][])
        if (await hash(path) !== digest) throw Error('Prepared proof drift after native generation: ' + path);
      const candidateSemanticGate = await semanticProof(candidateGatePath!, candidatePath, 'parse_with_fuel', 'candidate');
      create(stem + '.candidate-gates-v1.json', json({sourceSemanticGate, structuralGate, candidateSemanticGate}));
      const authenticatedInputs: Record<string, string> = {...nativeProof.authenticatedInputs,
        ...sourceSemanticGate.authenticatedInputs, ...candidateSemanticGate.authenticatedInputs, ...native.authenticatedInputs};
      for (const path of [manifestPath, sourceManifestPath, graphPath, overlayPath, architecturePath,
        candidatePath + '.scorecard.json', nativeProofPath, nativeProof.authorizationPath,
        nativeProof.guardianPath, nativeProof.requestPath, nativeProof.workerLogPath,
        stem + '.candidate-gates-v1.json', stem + '.native-build.started.json',
        ...['prepare-source', 'prepare'].flatMap(name => ['guardian.json', 'request.json', 'jsonl']
          .map(suffix => stem + '.' + name + '.' + suffix))])
        authenticatedInputs[path] = await hash(path);
      create(stem + '.acceptance-authorized.json', json({manifestPath, manifestSha256: await hash(manifestPath),
        sourceManifestPath, sourceManifestSha256: await hash(sourceManifestPath),
        nativeProofPath, nativeProofSha256: await hash(nativeProofPath),
        parserBuildPath: native.parserBuild, parserBuildSha256: await hash(native.parserBuild),
        artifactPath, artifactSha256: receipt.artifactSha256, provenancePath: receipt.provenancePath,
        provenanceSha256: receipt.provenanceSha256, sourceCandidate: candidatePath,
        candidateSha256: manifest.candidateSha256, sourceSemanticGate, structuralGate, candidateSemanticGate,
        authenticatedInputs}));
      event({stage: 'complete-native-parser-acceptance-authorized', rows: 75, parserBuildPath: native.parserBuild});
    }
  }
} catch (error) {
  const detail = error && typeof error === 'object' && '$' in error && error.$ === 'Err'
    ? Bend.err_show(error as Err) : String(error);
  const evidence = error && typeof error === 'object' && 'toJSON' in error &&
    typeof error.toJSON === 'function' ? error.toJSON() : undefined;
  event({stage: 'error', error: detail, evidence});
  if (evidence) console.error(JSON.stringify(evidence));
  console.error(detail); process.exitCode = 2;
} finally {
  for (const path of temporaryPaths) rmSync(path, {force: true});
  await stableInputs();
}
