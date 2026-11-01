// Run with: bun test evals/g24_distributed.test.mjs
// Safety properties only: filesystem snapshots/leases, plan selectors and receipt shape.
import {test} from 'bun:test';
import assert from 'node:assert/strict';
import {chmodSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, realpathSync, renameSync, rmSync, statSync, symlinkSync, writeFileSync} from 'node:fs';
import {relative, resolve} from 'node:path';
import os from 'node:os';
import {createHash} from 'node:crypto';
import {claimHost, freezeSnapshot, loadPlan, readEnvelope, validateLane, verifySnapshot} from './g24_distributed.mjs';
import {collectWorkloadInputs, pinFile} from './g24_snapshot.mjs';

function writableTree(path) {
  if (statSync(path).isDirectory()) {
    chmodSync(path, 0o700);
    for (const name of readdirSync(path)) writableTree(resolve(path, name));
  } else chmodSync(path, 0o600);
}
function fixture(action) {
  const temp = realpathSync(mkdtempSync(resolve(os.tmpdir(), 'g24-distributed-test-')));
  try {
    const repository = resolve(temp, 'repository'), out = resolve(repository, 'checkpoints/run');
    mkdirSync(resolve(repository, 'nested/imports'), {recursive: true}); mkdirSync(out, {recursive: true});
    writeFileSync(resolve(repository, 'nested/imports/value.bend'), 'nested dependency\n');
    writeFileSync(resolve(repository, 'root.bend'), 'import nested/imports/value.bend\n');
    writeFileSync(resolve(repository, '.env'), 'NEVER_TRANSPORT_THIS_SECRET');
    writeFileSync(resolve(out, 'unrelated.ast.json'), 'UNRELATED_HISTORICAL_TRANSPORT');
    const binary = resolve(out, 'binary'), image = resolve(out, 'stage1.js');
    writeFileSync(binary, 'candidate artifact'); writeFileSync(image, 'stage-one artifact');
    const files = [...collectWorkloadInputs(repository, ['root.bend'])].map(([path, sha256]) =>
      ({path: 'repository/' + relative(repository, path), original: path, ...pinFile(path, repository), sha256, role: 'source'}));
    for (const [name, path] of [['binary', binary], ['image', image]])
      files.push({path: 'artifacts/' + name, original: path, ...pinFile(path), role: 'artifact'});
    const snapshot = freezeSnapshot({files, mappings: {repository: {original: repository, snapshot: 'repository'}}, authority: []}, resolve(out, 'snapshot'));
    action({temp, repository, out, snapshot});
  } finally { writableTree(temp); rmSync(temp, {recursive: true}); }
}

test('snapshot includes nested dependencies and original artifacts without rewriting provenance', () => fixture(({snapshot, out}) => {
  verifySnapshot(snapshot.path, snapshot.sha256);
  const entry = snapshot.manifest.entries.find(e => e.path === 'repository/nested/imports/value.bend');
  assert.ok(entry);
  assert.equal(readFileSync(resolve(snapshot.path, entry.path), 'utf8'), 'nested dependency\n');
  assert.ok(snapshot.manifest.entries.some(e => e.original === realpathSync(resolve(out, 'binary')) && e.path === 'artifacts/binary'));
  assert.ok(snapshot.manifest.entries.every(e => !e.path.includes('.env') && !e.path.includes('unrelated.ast')));
}));

test('mutation of a transitive source fails before worker execution', () => fixture(({snapshot}) => {
  const file = resolve(snapshot.path, 'repository/nested/imports/value.bend');
  chmodSync(file, 0o600); writeFileSync(file, 'mutated dependency\n'); chmodSync(file, 0o444);
  assert.throws(() => verifySnapshot(snapshot.path, snapshot.sha256), /snapshot mutation/);
}));

test('missing or extra snapshot files cannot become partial successful snapshots', () => fixture(({snapshot}) => {
  const directory = resolve(snapshot.path, 'repository/nested/imports'); chmodSync(directory, 0o700);
  const file = resolve(directory, 'value.bend'); rmSync(file);
  assert.throws(() => verifySnapshot(snapshot.path, snapshot.sha256), /incomplete/);
  writeFileSync(file, 'nested dependency\n'); chmodSync(file, 0o444);
  writeFileSync(resolve(directory, 'unexpected.bend'), 'extra');
  assert.throws(() => verifySnapshot(snapshot.path, snapshot.sha256), /extra/);
}));

test('host lease refuses overlap and refuses release after ownership substitution', () => {
  const temp = mkdtempSync(resolve(os.tmpdir(), 'g24-lease-test-')), lock = resolve(temp, 'lock');
  try {
    const owner = {nonce: 'first'}, release = claimHost(lock, owner);
    assert.throws(() => claimHost(lock, {nonce: 'second'}), /EEXIST/);
    writeFileSync(resolve(lock, 'owner.json'), JSON.stringify({nonce: 'substituted'}));
    assert.throws(release, /ownership changed/);
    writeFileSync(resolve(lock, 'owner.json'), JSON.stringify(owner)); release();
    claimHost(lock, {nonce: 'second'})();
  } finally { rmSync(temp, {recursive: true}); }
});

function lane() {
  return {runs: [['control', 1], ['candidate', 1], ['candidate', 2], ['control', 2], ['control', 3], ['candidate', 3]]
    .map(([role, repetition]) => ({role, repetition, mode: 'native', physical: 'physical-A',
      report: {status: 'PASS', guardian: {ownedTreeStopped: true}}}))};
}
test('all six lane rows and exact interleaving are mandatory', () => {
  validateLane(lane(), 'native', 'physical-A');
  for (const mutate of [
    r => r.runs.pop(), r => r.runs.push(r.runs[0]), r => { r.runs[2] = r.runs[1]; },
    r => { [r.runs[0], r.runs[1]] = [r.runs[1], r.runs[0]]; },
  ]) {
    const result = lane(); mutate(result);
    assert.throws(() => validateLane(result, 'native', 'physical-A'), /six|lost\/duplicate\/reordered/);
  }
});
test('a successful row from a different physical host cannot enter a lane', () => {
  const result = lane(); result.runs[3].physical = 'physical-B';
  assert.throws(() => validateLane(result, 'native', 'physical-A'), /host substitution/);
});
function selectorPlan(action) {
  const temp = mkdtempSync(resolve(os.tmpdir(), 'g24-selector-test-')), path = resolve(temp, 'plan.json');
  try {
    action((selector, mode = 'ssh') => {
      writeFileSync(path, JSON.stringify({schemaVersion: 1, mode,
        hosts: [{id: 'remote', pin: {physical: 'a'.repeat(64)}, ...selector}],
        placement: Object.fromEntries(['matrix-c', 'matrix-js', 'native', 'admission', 'host',
          'performance-native', 'performance-js'].map(job => [job, 'remote']))}));
      return loadPlan(path);
    });
  } finally { rmSync(temp, {recursive: true}); }
}

test('SSH selectors reject options, control characters and malformed destinations', () => selectorPlan(load => {
  for (const ssh of [
    null, false, 2, [], {}, '', '-misakaindrive', '--', '-oProxyCommand=id',
    ' misakaindrive', 'misakaindrive ', 'misakaindrive\n', 'misakaindrive\r',
    'misaka\tindrive', 'misaka\0indrive', 'misaka\x1bindrive', 'misaka\x7findrive',
    'misaka\u0085indrive', 'user@misakaindrive', 'ssh://misakaindrive', 'misakaindrive:22',
    '/misakaindrive', 'misaka\\indrive', 'misaka;id', '$(id)', '`id`', '"misakaindrive"',
  ]) assert.throws(() => load({ssh}), /invalid SSH selector/, JSON.stringify(ssh));
}));

test('SSH plans reject missing or ambiguous transport selectors instead of choosing a fallback', () => selectorPlan(load => {
  for (const selector of [{}, {node: 2, ssh: 'misakaindrive'},
    {node: null, ssh: 'misakaindrive'}, {node: 2, ssh: null}])
    assert.throws(() => load(selector), /exactly one of node or ssh/);
}));

test('local plans reject any supplied SSH selector instead of silently executing locally', () => selectorPlan(load => {
  for (const ssh of ['misakaindrive', '', null])
    assert.throws(() => load({ssh}, 'local-single-host'), /local mode/);
}));

test('aliases cannot schedule independent jobs on one unrecognized physical host', () => {
  const temp = mkdtempSync(resolve(os.tmpdir(), 'g24-plan-test-')), path = resolve(temp, 'plan.json');
  try {
    for (const [first, alias] of [
      [{node: 2}, {node: 3}],
      [{ssh: 'misakaindrive'}, {ssh: 'misakaindrive-alias'}],
      [{node: 2}, {ssh: 'misakaindrive'}],
      [{ssh: 'misakaindrive'}, {node: 2}],
    ]) {
      writeFileSync(path, JSON.stringify({schemaVersion: 1, mode: 'ssh', hosts: [
        {id: 'first', ...first, pin: {physical: 'a'.repeat(64)}},
        {id: 'alias', ...alias, pin: {physical: 'a'.repeat(64)}},
      ], placement: Object.fromEntries(['matrix-c', 'matrix-js', 'native', 'admission', 'host',
        'performance-native', 'performance-js'].map(job => [job, 'first']))}));
      assert.throws(() => loadPlan(path), /duplicate physical host/);
    }
  } finally { rmSync(temp, {recursive: true}); }
});

test('host substitution in an otherwise valid job envelope is rejected before execution', () => {
  const temp = mkdtempSync(resolve(os.tmpdir(), 'g24-envelope-test-')), path = resolve(temp, 'job.json');
  try {
    const original = JSON.stringify({nonce: 'nonce', pin: {physical: 'host-A'}});
    writeFileSync(path, original);
    const digest = createHash('sha256').update(original).digest('hex');
    assert.equal(readEnvelope(path, digest).pin.physical, 'host-A');
    writeFileSync(path, JSON.stringify({nonce: 'nonce', pin: {physical: 'host-B'}}));
    assert.throws(() => readEnvelope(path, digest), /envelope mutation/);
  } finally { rmSync(temp, {recursive: true}); }
});

test('a pinned source cannot be replaced through a file or ancestor symlink', () => {
  const temp = realpathSync(mkdtempSync(resolve(os.tmpdir(), 'g24-source-race-test-')));
  const root = resolve(temp, 'source'), outside = resolve(temp, 'outside');
  mkdirSync(root); mkdirSync(outside);
  const file = resolve(root, 'value.bend');
  writeFileSync(file, 'expected'); writeFileSync(resolve(outside, 'value.bend'), 'secret');
  const entry = {path: 'repository/value.bend', original: file, ...pinFile(file, root)};
  try {
    renameSync(root, root + '-original'); symlinkSync(outside, root);
    assert.throws(() => freezeSnapshot({files: [entry], mappings: {}, authority: []}, resolve(temp, 'snapshot')), /boundary|symlink|identity/);
    assert.throws(() => pinFile(file, root), /boundary|symlink/);
  } finally {
    rmSync(root); renameSync(root + '-original', root);
    writableTree(temp); rmSync(temp, {recursive: true});
  }
});
