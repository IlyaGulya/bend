/** Run serially in the guarded lane:
 * bun evals/heavy_gate.ts --memory-mib 8192 --rss-mib 8192 --poll-ms 10 -- bun test evals/pattern_scan_cursor.test.ts
 * Full unchanged native book_valid and evaluation compare original, callback
 * reference, and first-order cursor programs, including ownership rejection.
 */
import { expect, test } from 'bun:test';
import * as B from '../bend2/bend.ts';
import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { scannerCursorFixtures, invalidAffineScannerCursor } from './pattern_scan_cursor_fixtures.ts';
import { factorScannerCursorFixture } from './pattern_scan_cursor_source.ts';

async function loadNative(source: string): Promise<B.Book> {
  const directory = await mkdtemp(join(tmpdir(), 'bend-scanner-cursor-'));
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
    sc: { stk: [], frs: 0 }, ns: '', al: {}, os: [], inst: null, ts: [], lv: 0,
  };
  let value = B.term_wnf(book, B.term_higher(B.parse_term(parser)));
  let result = 0;
  while (value.$ === 'Ctr' && value.k === 'Succ') {
    result++;
    value = B.term_wnf(book, value.x[0]!);
  }
  if (value.$ !== 'Ctr' || value.k !== 'Zero') throw Error('Expected a concrete native Nat result');
  return result;
}

function rethrowNativeError(error: unknown): never {
  if (error && typeof error === 'object' && '$' in error && error.$ === 'Err') throw Error(B.err_show(error as B.Err));
  throw error;
}


for (const fixture of scannerCursorFixtures) {
  test(`first-order scanner cursor preserves ${fixture.name}`, async () => {
    try {
      const factored = await factorScannerCursorFixture(fixture.source, fixture.row);
      const results: number[][] = [];
      for (const source of [fixture.source, factored.callbackSource, factored.cursorSource]) {
        const book = await loadNative(source);
        B.book_valid(book);
        const actual = fixture.inputs.map(([expression]) => evaluateNat(book, expression));
        expect(actual).toEqual(fixture.inputs.map(([, expected]) => expected));
        results.push(actual);
      }
      expect(results[1]).toEqual(results[0]);
      expect(results[2]).toEqual(results[1]);
    } catch (error) {
      rethrowNativeError(error);
    } finally {
      Bun.gc(true);
    }
  }, 30000);
}

test('first-order scanner cursor cannot legalize invalid affine contraction', async () => {
  try {
    const fixture = invalidAffineScannerCursor;
    const factored = await factorScannerCursorFixture(fixture.source, fixture.row);
    const validation: boolean[] = [];
    for (const source of [fixture.source, factored.callbackSource, factored.cursorSource]) {
      const book = await loadNative(source);
      let valid = true;
      try {
        B.book_valid(book);
      } catch (error) {
        if (!error || typeof error !== 'object' || !('$' in error) || error.$ !== 'Err') throw error;
        valid = false;
      }
      validation.push(valid);
    }
    expect(validation).toEqual([false, false, false]);
  } catch (error) {
    rethrowNativeError(error);
  } finally {
    Bun.gc(true);
  }
}, 30000);
