#!/usr/bin/env bun
/** One aligned real-candidate diagnostic; never a full-check/backend claim. */
import {createHash, randomUUID} from 'node:crypto';
import {appendFileSync, readFileSync, rmSync, writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {checkFrozen, frozen} from './load_replay_kernel.ts';
import {guardHeavyGate, runHeavyGate} from './heavy_gate.ts';
import {alignedPatternScanSource} from './pattern_scan_aligned_source.ts';

const configPath = resolve('evals/pattern_scan_aligned_evidence.json');
const config = JSON.parse(readFileSync(configPath, 'utf8'));
const stem = resolve('evals/pattern_scan_aligned_result');
const resultPath = stem + '.json', progress = stem + '.progress.json', journal = stem + '.jsonl';
const guardianPath = stem + '.guardian.json', auditPath = stem + '.source-audit.json';
const sourcePath = resolve('bend2/selfhost/.pattern_scan_aligned_source.bend');
const outputBase = resolve('bend2/selfhost/.pattern_scan_aligned_generated.bend');
const candidatePath = outputBase.replace('.bend', '_fuel.bend');
const sha = (text: string) => createHash('sha256').update(text).digest('hex');
const mode = process.argv[2];

if (mode === undefined) {
  for (const path of [resultPath, guardianPath, progress]) if (await Bun.file(path).exists()) throw Error('Diagnostic already attempted; consume existing evidence, do not repeat: ' + path);
  const gate = await runHeavyGate([process.execPath, import.meta.path, '--worker'], {
    label: 'One aligned real pattern_scan fresh native target check (retain checked e)',
    memoryMiB: config.budget.physicalMiB, rssMiB: config.budget.rssMiB,
    pollMs: config.budget.pollMs, termGraceMs: 0,
  });
  writeFileSync(guardianPath, JSON.stringify(gate, null, 2) + '\n');
  const worker = await Bun.file(resultPath).exists() ? await Bun.file(resultPath).json() : null;
  const last = await Bun.file(progress).exists() ? await Bun.file(progress).json() : null;
  const final = {status: gate.status === 'PASS' && worker?.status === 'TARGET_PASS' ? 'TARGET_PASS' : gate.status === 'PASS' ? 'FAIL' : gate.status,
    diagnosticOnly: true, fullValidation: 'NOT_RUN', backendCompilation: 'NOT_RUN', checkedERetention: 'retain', configPath, worker, last,
    guardian: gate, peakFootprintBytes: gate.peakFootprintBytes, peakRssBytes: gate.peakRssBytes, journal, auditPath};
  writeFileSync(resultPath, JSON.stringify(final, null, 2) + '\n');
  console.log(JSON.stringify(final));
  process.exit(gate.exitCode || (final.status === 'TARGET_PASS' ? 0 : 2));
}
if (!['--worker', '--prepare'].includes(mode)) throw Error('Usage: bun evals/pattern_scan_aligned_probe.ts');
await guardHeavyGate(import.meta.path, {label: 'Aligned pattern_scan diagnostic worker'});
await checkFrozen();
const compilerHash = sha(await Bun.file('bend2/comp.ts').text());
const started = performance.now();
let phase = 'prepare';
const temporaryGenerator = resolve('evals', '.pattern_scan_aligned_generate_' + randomUUID() + '.ts');
const temporaryGraph = resolve('evals', '.pattern_scan_aligned_graph_' + randomUUID() + '.json');
try {
  if (mode === '--worker') {
    writeFileSync(journal, '');
    // The supervisor's periodic sampling covers synchronous child work. This
    // lightweight orchestrator provides an independent wall watchdog.
    const deadline = setTimeout(() => {
      const data = {status: 'WALL_LIMIT', phase, wallMs: config.budget.wallMs};
      writeFileSync(resultPath, JSON.stringify(data, null, 2) + '\n');
      process.exit(124); // Gate tears down the entire child process group.
    }, config.budget.wallMs);
    try {
      const prepare = Bun.spawn([process.execPath, import.meta.path, '--prepare'], {stdout: 'inherit', stderr: 'inherit'});
      const prepareExit = await prepare.exited;
      if (prepareExit !== 0) { process.exitCode = prepareExit; }
      else {
        phase = 'target';
        // Preparation has exited: no source AST/lowering graphs remain alive.
        const target = Bun.spawn([process.execPath, resolve('evals/pattern_scan_aligned_target.ts')], {stdout: 'inherit', stderr: 'inherit'});
        process.exitCode = await target.exited;
      }
    } finally { clearTimeout(deadline); }
  } else {
    const prepared = await alignedPatternScanSource(await Bun.file('bend2/selfhost/parser.bend').text());
    const sourceHash = prepared.audit.transformedSha256;
    writeFileSync(sourcePath, prepared.source);
    writeFileSync(auditPath, JSON.stringify(prepared.audit, null, 2) + '\n');
    appendFileSync(journal, JSON.stringify({phase, stage: 'source-audit-after', elapsedMs: performance.now() - started, sourcePath, sourceHash, auditPath}) + '\n');
    const currentGraph = await Bun.file('bend2/selfhost/parser_full_current_graph.json').json();
    // Fresh raw-AST facts for this diagnostic input. No feedback-cut changes.
    const metadataBytes = JSON.stringify({...currentGraph, sourceCheckpoint: sourceHash.slice(0, 8), sourceSha256: sourceHash,
      definitions: prepared.graph.definitions, edges: prepared.graph.edges, unresolvedReferences: prepared.graph.unresolvedReferences}, null, 2) + '\n';
    writeFileSync(temporaryGraph, metadataBytes);
    const originalGenerator = await Bun.file('evals/parser_full_generate.ts').text();
    const substitutions = [
      ['const input = resolve(import.meta.dir, "../bend2/selfhost/parser.bend");', `const input = ${JSON.stringify(sourcePath)};`],
      ['const output = resolve(import.meta.dir, "../bend2/selfhost/parser_full_generated.bend");', `const output = ${JSON.stringify(outputBase)};`],
      [`const expected = "${frozen['bend2/selfhost/parser.bend']}";`, `const expected = "${sourceHash}";`],
      ['const currentGraphPath = resolve(import.meta.dir, "../bend2/selfhost/parser_full_current_graph.json");', `const currentGraphPath = ${JSON.stringify(temporaryGraph)};`],
    ];
    let redirected = originalGenerator;
    for (const [before, after] of substitutions) {
      if (redirected.split(before!).length !== 2) throw Error('Generator constant substitution anchor drift');
      redirected = redirected.replace(before!, after!);
    }
    let recovered = redirected;
    for (const [before, after] of [...substitutions].reverse()) recovered = recovered.replace(after!, before!);
    if (recovered !== originalGenerator) throw Error('Generator redirect is not exactly invertible');
    writeFileSync(temporaryGenerator, redirected);
    phase = 'generation';
    const generationStart = performance.now();
    appendFileSync(journal, JSON.stringify({phase, stage: 'generation-before', substitutions, generatorInverseByteExact: true}) + '\n');
    const generation = Bun.spawn([process.execPath, temporaryGenerator, '--fuel-parametric'], {stdout: 'inherit', stderr: 'inherit'});
    const generationExitCode = await generation.exited;
    if (generationExitCode !== 0) throw Error('Frozen redirected generator exited ' + generationExitCode);
    const generatedHash = sha(await Bun.file(candidatePath).text());
    const scorecard = await Bun.file(candidatePath + '.scorecard.json').json();
    if (scorecard.sourceSha256 !== sourceHash || scorecard.generatedSha256 !== generatedHash) throw Error('Generated output/source scorecard mismatch');
    const generationEvidence = {phase, stage: 'generation-after', generationElapsedMs: performance.now() - generationStart, candidatePath, generatedHash, sourceHash,
      compilerHash, frozen, metadataInputSha256: sha(metadataBytes), redirectedGeneratorSha256: sha(redirected),
      generatorRedirects: substitutions.map(([before, after]) => ({before, after})), generatorInverseByteExact: true};
    appendFileSync(journal, JSON.stringify(generationEvidence) + '\n');
    writeFileSync(stem + '.generation.json', JSON.stringify(generationEvidence, null, 2) + '\n');
  }
} catch (error) {
  const data = {status: 'FAIL', phase, error: String(error), frozen, compilerHash};
  appendFileSync(journal, JSON.stringify(data) + '\n');
  writeFileSync(resultPath, JSON.stringify(data, null, 2) + '\n');
  process.exitCode = 2;
} finally {
  rmSync(temporaryGenerator, {force: true}); rmSync(temporaryGraph, {force: true});
  await checkFrozen();
  if (sha(await Bun.file('bend2/comp.ts').text()) !== compilerHash) throw Error('Frozen compiler changed during diagnostic');
}
