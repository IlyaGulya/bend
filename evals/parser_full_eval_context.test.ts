/** Run serially in the guarded lane:
 * bun evals/heavy_gate.ts --memory-mib 8192 --rss-mib 8192 --poll-ms 10 -- bun test evals/parser_full_eval_context.test.ts
 * Full unchanged stage-0 book_valid and native evaluation are the fixture seam.
 */
import { expect, test } from 'bun:test';
import * as B from '../bend2/bend.ts';
import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { EvaluationContextLimitation, normalizeEvaluationContexts } from './parser_full_eval_context.ts';
import {
  evaluationContextFixtures,
  invalidAffineEvaluationContext,
  multipleSiblingEffects,
  type EvaluationContextFixture,
} from './parser_full_eval_context_fixtures.ts';

async function loadNative(source: string): Promise<B.Book> {
  const directory = await mkdtemp(join(tmpdir(), 'bend-eval-context-'));
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
  // Native evaluation keeps Nat literals compact, including constructor tails.
  while (value.$ === 'Ctr' && value.k === 'Succ' && value.x.length === 1) {
    prefix++;
    value = B.term_wnf(book, value.x[0]);
  }
  if (value.$ === 'Lit' && value.k === 'Nat') return prefix + value.v;
  if (value.$ === 'Ctr' && value.k === 'Zero' && value.x.length === 0) return prefix;
  throw Error('Expected a concrete native Nat result');
}

async function validateAndEvaluate(source: string, fixture: EvaluationContextFixture): Promise<number[]> {
  const book = await loadNative(source);
  B.book_valid(book);
  return fixture.inputs.map(([expression]) => evaluateNat(book, expression));
}

function rethrowNativeError(error: unknown): never {
  if (error && typeof error === 'object' && '$' in error && error.$ === 'Err') {
    throw Error(B.err_show(error as B.Err));
  }
  throw error;
}

for (const fixture of evaluationContextFixtures) {
  test(`evaluation context factoring preserves ${fixture.name}`, async () => {
    try {
      const normalized = await normalizeEvaluationContexts(fixture.source, fixture.seeds);
      const expected = fixture.inputs.map(([, value]) => value);
      const originalResults = await validateAndEvaluate(fixture.source, fixture);
      expect(originalResults).toEqual(expected);
      const normalizedResults = await validateAndEvaluate(normalized.source, fixture);
      expect(normalizedResults).toEqual(expected);
      expect(normalizedResults).toEqual(originalResults);
    } catch (error) {
      rethrowNativeError(error);
    }
  }, 30000);
}

test('evaluation context factoring explicitly rejects multiple suspended sibling effects', async () => {
  try {
    const fixture = multipleSiblingEffects;
    expect(await validateAndEvaluate(fixture.source, fixture)).toEqual(fixture.inputs.map(([, value]) => value));
    try {
      await normalizeEvaluationContexts(fixture.source, fixture.seeds);
      throw Error('Expected multiple suspended sibling effects to be rejected');
    } catch (error) {
      if (!(error instanceof EvaluationContextLimitation)) throw error;
      expect(error.code).toBe('MultipleSuspendedEffects');
      expect(error.message).toContain('multiple-effect evaluation context requires sequencing');
      expect(error.evidence).toMatchObject({ owner: 'example', producers: ['produce', 'produce'] });
    }
  } catch (error) {
    rethrowNativeError(error);
  }
}, 30000);

test('evaluation context factoring cannot legalize affine contraction', async () => {
  try {
    const normalized = await normalizeEvaluationContexts(invalidAffineEvaluationContext, ['produce']);
    for (const source of [invalidAffineEvaluationContext, normalized.source]) {
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
  } catch (error) {
    rethrowNativeError(error);
  }
}, 30000);
