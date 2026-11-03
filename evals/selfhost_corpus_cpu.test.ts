import {expect, test} from 'bun:test';
import {mkdtempSync, rmSync, writeFileSync} from 'node:fs';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {pathToFileURL} from 'node:url';
import {summarizeProfile, type ImageMap} from './selfhost_corpus_cpu.ts';

const emptyMap = (): ImageMap => ({declarations: new Map(), aliases: new Map(), byLine: new Map(), exportLines: new Map(), incoming: new Map(), omissions: []});
const frame = (functionName: string, scriptId: string, url = '', lineNumber = -1) => ({functionName, scriptId, url, lineNumber, columnNumber: 0});
const profile = (nodes: any[], samples: number[], timeDeltas: number[]) => ({startTime: 0, endTime: timeDeltas.reduce((a, b) => a + b, 0), nodes, samples, timeDeltas});

test('physical coverage weights timeDeltas and merges identities across script IDs', () => {
  const data = profile([
    {id: 1, callFrame: frame('(garbage collector)', 'first')},
    {id: 2, callFrame: frame('(garbage collector)', 'second')},
    {id: 3, callFrame: frame('unmapped', 'third')},
  ], [1, 2, 3], [1_000, 8_000, 1_000]);
  const result = summarizeProfile(data, '/unused/image', emptyMap());
  expect(result.functions.filter(row => row.functionName === '(garbage collector)')).toHaveLength(1);
  const gc = result.families.find(row => row.family === 'gc')!;
  expect(gc.selfSamples).toBe(2);
  expect(gc.selfSampledMs).toBe(9);
  expect(gc.selfShare).toBe(0.9);
  expect(result.families.reduce((sum, row) => sum + row.selfSamples, 0)).toBe(3);
  expect(result.families.reduce((sum, row) => sum + row.selfMicroseconds, 0)).toBe(10_000);
});

test('ambiguous, chained and unsupported continuations remain unclassified', () => {
  const directory = mkdtempSync(join(tmpdir(), 'bend-cpu-owner-'));
  try {
    const image = join(directory, 'image.mjs'); writeFileSync(image, '');
    const map = emptyMap();
    for (const [name, lineNumber] of [['$b1', 1], ['$b2', 2], ['$k3', 3], ['$k4', 4], ['$k5', 5]] as const)
      map.declarations.set(name, {name, lineNumber, columnNumber: 0, lineSha256: '', code: name === '$b2' ? null : '{}'});
    map.aliases.set('$b1', [{name: 'checker_core_steps_v1.checker_body_infer', body: '$b1', lineNumber: 10, lineSha256: ''}]);
    map.incoming.set('$k3', new Set(['$b1', '$b2']));
    map.incoming.set('$k4', new Set(['$k3']));
    map.incoming.set('$k5', new Set(['$b2']));
    const data = profile([3, 4, 5].map(id => ({id, callFrame: frame('$k' + id, 'local', pathToFileURL(image).href, id)})), [3, 4, 5], [1_000, 2_000, 3_000]);
    const result = summarizeProfile(data, image, map);
    expect(result.families.find(row => row.family === 'unclassified')!.selfShare).toBe(1);
  } finally { rmSync(directory, {recursive: true, force: true}); }
});

test('physical profiles reject cyclic ancestry and invalid sample weights', () => {
  const a = {id: 1, callFrame: frame('(garbage collector)', 'a'), children: [2]};
  const b = {id: 2, callFrame: frame('(garbage collector)', 'b'), children: [1]};
  expect(() => summarizeProfile(profile([a, b], [1], [1_000]), '/unused/image', emptyMap())).toThrow();
  const invalidWeight = profile([{id: 1, callFrame: frame('(garbage collector)', 'a')}], [1], [-1]);
  invalidWeight.endTime = 1_000;
  expect(() => summarizeProfile(invalidWeight, '/unused/image', emptyMap())).toThrow();
  expect(() => summarizeProfile(profile([{id: 1, callFrame: frame('(garbage collector)', 'a')}], [2], [1]), '/unused/image', emptyMap())).toThrow();
});
