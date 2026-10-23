import {expect, test} from 'bun:test';
import {resolve} from 'node:path';
import * as B from '../bend2/bend.ts';
import {js_lib} from '../bend2/comp.ts';
test('checked-body release preserves mutually recursive native entrypoints', async () => {
  for (const releaseChecked of [false, true]) {
    const book = B.book_nil();
    await B.book_load(book, resolve(import.meta.dir, '../tests/run/unsafe_mutual.bend'), '', new Map());
    B.book_valid(book);
    const source = js_lib(book, true, {roots: ['main'], exports: ['main'], releaseChecked});
    const module = await import('data:text/javascript;base64,' + Buffer.from(source).toString('base64'));
    expect(module.default.main()).toBe('y');
  }
});


test('checked-body release preserves later word-match folding of earlier entrypoints', async () => {
  for (const releaseChecked of [false, true]) {
    const book = B.book_nil();
    await B.book_load(book, resolve(import.meta.dir, '../tests/run/js_late_fold.bend'), '', new Map());
    B.book_valid(book);
    const source = js_lib(book, true, {roots: ['early', 'lookup'], exports: ['early', 'lookup'], releaseChecked});
    const module = await import('data:text/javascript;base64,' + Buffer.from(source).toString('base64'));
    expect([module.default.lookup(0), module.default.lookup(99)]).toEqual([1, 4]);
  }
});
