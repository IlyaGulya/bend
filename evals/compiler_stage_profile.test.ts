import {expect, test} from 'bun:test';
import {mkdtemp, rm, writeFile} from 'node:fs/promises';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {createStepAttribution, loadStageManifests, stageGroupMetadata, typedProgressSample} from './compiler_stage_profile.mjs';

type ManifestInput = {runType?: string; output?: string; groups?: string[][]; declarations?: Record<string, unknown>[]; inputs?: Record<string, string>};
type Attribution = {onStep: (steps: number, run: unknown) => void;
  record: (profile: {record: (value: Record<string, unknown>) => void}) => void};

async function manifest(value: ManifestInput): Promise<string> {
  const directory = await mkdtemp(join(tmpdir(), 'bend-stage-profile-'));
  const path = join(directory, 'manifest.json');
  await writeFile(path, JSON.stringify({
    generationConfig: {output: value.output ?? 'checkpoints/emitter_steps_v1.bend'},
    nativeChunk: {runType: value.runType ?? 'EmitterRun'},
    requestGroups: (value.groups ?? []).map((definitions, index) => ({constructor: 'EmitterRequestGroup_' + index, definitions})),
    canonicalComposition: {declarations: value.declarations ?? [], inputs: value.inputs ?? {}},
  }));
  return path;
}

async function withManifest<T>(value: ManifestInput, body: (path: string) => Promise<T> | T): Promise<T> {
  const path = await manifest(value);
  try {return await body(path);} finally {await rm(join(path, '..'), {recursive: true, force: true});}
}

const run = (namespace: string, request?: string) => ({
  $: namespace + '.EmitterRunState',
  progress: request === undefined
    ? {$: namespace + '.EmitterDirect', arguments: 1, invoke: () => undefined, resume: () => undefined}
    : {$: namespace + '.EmitterPending', request: {$: namespace + '.EmitterRequestGroup_0', request: {$: namespace + '.EmitterRequest_' + request}}, resume: () => undefined},
  stack: {$: namespace + '.EmitterStackDone'},
});

function observe(attribution: Attribution, runValue: unknown) {
  attribution.onStep(0, runValue);
  const observations: Record<string, unknown>[] = [];
  attribution.record({record: (value: Record<string, unknown>) => observations.push(value)});
  return observations.find(value => value.kind === 'typed-progress-samples') as Record<string, unknown>;
}

test('stage profile binds a registered namespace and retains fully qualified request tags', async () => {
  const path = await manifest({
    groups: [['emit']],
    declarations: [{kind: 'def', name: 'emit', canonicalName: 'emit', source: 'bend2/selfhost/emitter.bend'}],
  });
  try {
    const table = loadStageManifests([path]);
    expect(table.namespaces).toEqual(['emitter_steps_v1']);
    const observation = observe(createStepAttribution('emit', 'Emitter', table), run('emitter_steps_v1', 'emit'));
    expect(observation.values['emit-emitter-entry']).toBe(1);
    expect(observation.details.requestSamples['emitter_steps_v1.EmitterRequest_emit']).toBe(1);
    expect(observation.details.observedRunNamespace).toBe('emitter_steps_v1');
    expect(observation.details.groupBases['emit-emitter-entry']).toEqual(['declared-canonical-source']);
  } finally {await rm(join(path, '..'), {recursive: true, force: true});}
});

test('stage profile rejects a foreign namespace instead of matching the simple tag', async () => {
  const path = await manifest({groups: [['emit']]});
  try {
    const table = loadStageManifests([path]);
    const observation = observe(createStepAttribution('emit', 'Emitter', table), run('foreign_steps_v9', 'emit'));
    expect(observation.values.unclassified).toBe(1);
    expect(observation.details.unclassifiedReasons).toEqual({'unregistered-namespace': 1});
    expect(observation.details.requestSamples['foreign_steps_v9.EmitterRequest_emit']).toBe(1);
  } finally {await rm(join(path, '..'), {recursive: true, force: true});}
});

test('stage profile retains tags but does not group without a manifest', () => {
  const observation = observe(createStepAttribution('emit', 'Emitter', undefined), run('emitter_steps_v1', 'emit'));
  expect(observation.values.unclassified).toBe(1);
  expect(observation.details.unclassifiedReasons).toEqual({'no-manifest': 1});
  expect(observation.details.requestSamples['emitter_steps_v1.EmitterRequest_emit']).toBe(1);
});

test('stage profile refuses a basename fallback when sources collide', async () => {
  const path = await manifest({
    groups: [['x', 'y']],
    declarations: [
      {kind: 'def', name: 'x', canonicalName: 'x', source: 'a/descriptor_nf.bend'},
      {kind: 'def', name: 'y', canonicalName: 'y', source: 'b/descriptor_nf.bend'},
    ],
  });
  try {
    const table = loadStageManifests([path]);
    const observation = observe(createStepAttribution('emit', 'Emitter', table), run('emitter_steps_v1', 'x'));
    expect(observation.values['module:a/descriptor_nf.bend']).toBe(1);
    expect(observation.values['emit-descriptor-nf']).toBeUndefined();
    expect(table.provenance[0].basenameCollisions).toEqual([{basename: 'descriptor_nf.bend', sources: ['a/descriptor_nf.bend', 'b/descriptor_nf.bend']}]);
  } finally {await rm(join(path, '..'), {recursive: true, force: true});}
});

test('stage profile reports a pinned source hash mismatch instead of a group', async () => {
  const path = await manifest({
    groups: [['emit']],
    declarations: [{kind: 'def', name: 'emit', canonicalName: 'emit', source: 'bend2/selfhost/emitter.bend'}],
    inputs: {'bend2/selfhost/emitter.bend': '0'.repeat(64)},
  });
  try {
    const table = loadStageManifests([path]);
    expect(table.provenance[0].sourceVerification[0].status).toBe('mismatch');
    const observation = observe(createStepAttribution('emit', 'Emitter', table), run('emitter_steps_v1', 'emit'));
    expect(observation.values['unverified-source']).toBe(1);
  } finally {await rm(join(path, '..'), {recursive: true, force: true});}
});

test('stage profile counts an erased Direct request as a shape, not a request sample', async () => {
  const observation = observe(createStepAttribution('emit', 'Emitter', undefined), run('emitter_steps_v1'));
  expect(observation.details.progressShapes).toEqual({Direct: 1});
  expect(observation.values.requestBoundarySamples).toBe(0);
});

test('check publication is documented as part of the check Run, not unreachable', () => {
  const publication = stageGroupMetadata.find(group => group.name === 'check-publication');
  expect(publication?.measurement).toBe('included-in-check-signature-body');
  expect(JSON.stringify(publication)).not.toContain('unreachable');
});

test('typed progress retains the full constructor identity', () => {
  const sample = typedProgressSample(run('emitter_steps_v1', 'emit'));
  expect(sample?.runNamespace).toBe('emitter_steps_v1');
  expect(sample?.request).toBe('emitter_steps_v1.EmitterRequest_emit');
});
