import {readFileSync, writeFileSync, existsSync} from 'node:fs';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';

// Reads parent evidence only; no subprocess, parser, emitter, or synthetic FIR.
const [suitePath, receiptPath, output] = process.argv.slice(2);
if (!suitePath || !receiptPath || !output || existsSync(output)) throw Error('usage: oracle.mjs SUITE RECEIPT FRESH_JSON');
const sha = bytes => createHash('sha256').update(bytes).digest('hex');
const hash = path => sha(readFileSync(path));
const report = {schemaVersion: 1, status: 'STARTING', compilerAccepted: false, rows: [], failures: []};
const save = () => writeFileSync(output, JSON.stringify(report, null, 2) + '\n');
save();
try {
  const suite = JSON.parse(readFileSync(suitePath, 'utf8')), receipt = JSON.parse(readFileSync(receiptPath, 'utf8'));
  report.suite = {path: suitePath, sha256: hash(suitePath)};
  report.receipt = {path: receiptPath, sha256: hash(receiptPath)};
  assert.equal(receipt.suite.sha256, report.suite.sha256);
  assert.equal(receipt.status, 'PASS');
  assert.equal(receipt.authority.class, 'GENUINE_R12_NATIVE_SEED_STAGE1');
  assert.equal(receipt.authority.image.sha256, '85aff9e534c18b4a1d6acac5f3237571dabc58f2c1a75a7ea2040f1c477ab60e');
  for (const test of suite.rows) for (const target of test.targets ?? ['c', 'js']) {
    const row = receipt.rows.find(r => r.name === test.name + '-' + target);
    assert.ok(row, 'missing actual execution row'); assert.equal(row.status, 'PASS');
    assert.equal(row.source.path, test.source); assert.equal(hash(row.source.path), row.source.sha256);
    assert.equal(hash(row.compilation.path), row.compilation.sha256);
    const compilation = JSON.parse(readFileSync(row.compilation.path, 'utf8'));
    assert.equal(compilation.status, 'PASS');
    assert.equal(compilation.authority.image.sha256, receipt.authority.image.sha256);
    for (const [path, digest] of Object.entries(compilation.inputs)) assert.equal(hash(path), digest, 'input drift ' + path);
    assert.equal(hash(compilation.output.path), compilation.output.sha256);
    if (target === 'c') assert.equal(hash(row.binary.path), row.binary.sha256);
    const execution = row.execution;
    assert.equal(execution.guardian.status, 'PASS'); assert.equal(execution.guardian.commandExitCode, 0);
    assert.equal(hash(execution.stdout), execution.stdoutSha256); assert.equal(hash(execution.stderr), execution.stderrSha256);
    const actual = readFileSync(execution.stdout, 'utf8');
    assert.equal(actual, test.expected); assert.equal(actual, row.actual); assert.equal(readFileSync(execution.stderr, 'utf8'), '');
    const result = {name: row.name, target, actual, semanticTrace: 'AUTHENTICATED_EXPECTED_EXECUTION', n07: null};
    if (test.plugins?.length) {
      const snapshot = compilation.snapshots.find(s => s.path.endsWith('/occurrences.mjs'))?.snapshot;
      assert.ok(snapshot, 'missing occurrence snapshot');
      const plugin = compilation.plugins.find(p => p.path.endsWith('/occurrences.mjs'));
      assert.equal(hash(plugin.path), plugin.sha256);
      assert.equal(plugin.inputSha256, plugin.outputSha256, 'passive scanner altered compiler');
      // This scanner does not install a lowering hook. A later parent probe must
      // authenticate its own hook's declaration/callsite mapping separately.
      const mutation = snapshot.diagnosticMutation;
      result.n07 = {sharedContextualTerms: snapshot.sharedTermDifferentFacts.length, controlFailures: mutation.controlFailures.length, collapseFailures: mutation.collapseFailures.length, verdict: mutation.verdict};
      result.n07.coverage = mutation.verdict === 'DISTINGUISHING_INVARIANT_OBSERVED_REQUIRES_EXECUTED_TARGET_TRACES'
        ? 'INVARIANT_AND_EXECUTED_TRACE_REQUIRE_HOOK_PROVENANCE_REVIEW'
        : 'STOP_CONTEXTUAL_PRESERVATION_NOT_ESTABLISHED';
    }
    report.rows.push(result); save();
  }
  report.status = report.rows.some(r => r.n07) ? 'TARGET_TRACES_AUTHENTICATED_N07_NOT_AUTOMATIC_GO' : 'N03_NORMAL_TARGET_TRACES_AUTHENTICATED';
  report.limitations = ['N03 C recoverable throw remains outside the common ABI', 'N07 never passes on serialized fields or ordinary output alone', 'Hook provenance and correspondence to actual published occurrence paths require parent review'];
} catch (error) { report.status = 'STOP'; report.failures.push({message: String(error), stack: error?.stack}); process.exitCode = 1; }
save();
