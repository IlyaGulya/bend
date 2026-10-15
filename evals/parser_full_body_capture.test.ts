/** Run serially in the guarded lane:
 * bun evals/heavy_gate.ts --memory-mib 8192 --rss-mib 8192 --poll-ms 10 -- bun test evals/parser_full_body_capture.test.ts
 * Native validation is the full unchanged stage-0 book_valid, not a typed-prefix
 * approximation. Both original and consumer-visible transformed programs run.
 */
import { expect, test } from 'bun:test';
import * as B from '../bend2/bend.ts';
import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { bodyCaptureFixtures, invalidAffineBodyCapture } from './parser_full_body_capture_fixtures.ts';
import { extractFixtureRow } from './parser_full_body_capture_source.ts';

async function loadNative(source: string): Promise<B.Book> {
  const directory = await mkdtemp(join(tmpdir(), 'bend-body-capture-'));
  try {
    const path = join(directory, 'main.bend');
    await writeFile(path, source);
    const book = B.book_nil();
    await B.book_load(book, path, '', new Map());
    return book;
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}

function evaluateNat(book: B.Book, expression: string): number {
  const parser: B.Parse = {
    book, dir: tmpdir() + '/', str: expression, pos: 0,
    stk: [], frs: 0, ns: '', al: {},
  };
  let value = B.term_wnf(book, B.term_higher(B.parse_term(parser)));
  let prefix = 0;
  // Observe compact native literals without expanding their constructor trees.
  while (value.$ === 'Ctr' && value.k === 'Succ' && value.x.length === 1) {
    prefix++;
    value = B.term_wnf(book, value.x[0]);
  }
  if (value.$ === 'Lit' && value.k === 'Nat') return prefix + value.v;
  if (value.$ === 'Ctr' && value.k === 'Zero' && value.x.length === 0) return prefix;
  throw Error('Expected a concrete native Nat result');
}

for (const fixture of bodyCaptureFixtures) {
  test(`source row extraction preserves ${fixture.name}`, async () => {
    try {
      const extracted = await extractFixtureRow(fixture.source, fixture.row);
      expect(extracted.original.unresolvedReferences).toEqual([]);
      expect(extracted.graph.unresolvedReferences).toEqual([]);
      const expected = fixture.inputs.map(([, value]) => value);
      const results: number[][] = [];
      for (const source of [fixture.source, extracted.source]) {
        const book = await loadNative(source);
        B.book_valid(book);
        const values = fixture.inputs.map(([expression]) => evaluateNat(book, expression));
        expect(values).toEqual(expected);
        results.push(values);
      }
      expect(results[1]).toEqual(results[0]);
    } catch(error) {
      if(error&&typeof error==='object'&&'$'in error&&error.$==='Err')throw Error(B.err_show(error as B.Err));
      throw error;
    }
  }, 30000);
}

test('source row extraction cannot legalize affine contraction', async () => {
  const extracted = await extractFixtureRow(invalidAffineBodyCapture, [0]);
  expect(extracted.original.unresolvedReferences).toEqual([]);
  expect(extracted.graph.unresolvedReferences).toEqual([]);
  for (const source of [invalidAffineBodyCapture, extracted.source]) {
    const book = await loadNative(source);
    let rejected = false;
    try {
      B.book_valid(book);
    } catch (error) {
      if (!error || typeof error !== 'object' || !('$' in error) || error.$ !== 'Err') throw error;
      rejected = true;
    }
    expect(rejected).toBe(true);
  }
}, 30000);
