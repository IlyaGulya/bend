import {expect, test} from 'bun:test';
import * as B from '../bend2/bend.ts';
import {dirname, resolve} from 'node:path';

type Fixture = {
  name: string;
  file: string;
  inputs: readonly (readonly [readonly string[], number])[];
};

// Literal oracles are independent of both the prototype compiler and #| output
// annotations. Every source is loaded directly through the production loader.
const fixtures: readonly Fixture[] = [
  {
    name: 'field prefix and simple pure tail',
    file: 'pure_tail_field_prefix.bend',
    inputs: [
      [['C{7n}', 'X{}'], 7],
      [['C{7n}', 'Y{}'], 8],
      [['C{7n}', 'P{}'], 30],
      [['C{7n}', 'Q{}'], 40],
      [['D{9n}', 'X{}'], 50],
      [['D{9n}', 'Y{}'], 50],
      [['D{9n}', 'P{}'], 30],
      [['E{11n}', 'Q{}'], 40],
    ],
  },
  {
    name: 'C/D/E boundary and residual later fallthrough',
    file: 'pure_tail_later_fallthrough.bend',
    inputs: [
      [['C{7n}', 'X{}', 'True{}'], 7],
      [['D{9n}', 'Y{}', 'True{}'], 19],
      [['E{11n}', 'X{}', 'True{}'], 31],
      [['C{7n}', 'X{}', 'False{}'], 40],
      [['D{9n}', 'Y{}', 'False{}'], 40],
      [['E{11n}', 'X{}', 'False{}'], 40],
      [['C{7n}', 'P{}', 'True{}'], 30],
      [['C{7n}', 'P{}', 'False{}'], 31],
      [['D{9n}', 'P{}', 'False{}'], 31],
      [['E{11n}', 'P{}', 'False{}'], 31],
      [['E{11n}', 'Q{}', 'True{}'], 40],
    ],
  },
  {
    name: 'affine Type constructor reconstruction and whole scrutinee',
    file: 'pure_tail_affine_reconstruction.bend',
    inputs: [
      [['C{Resource{7n}}', 'True{}'], 7],
      [['C{Resource{7n}}', 'False{}'], 17],
      [['D{Resource{9n}}', 'True{}'], 29],
      [['D{Resource{9n}}', 'False{}'], 29],
      [['E{Resource{11n}}', 'True{}'], 41],
      [['E{Resource{11n}}', 'False{}'], 41],
    ],
  },
  {
    name: 'copied Data parameter, field and whole quantities',
    file: 'pure_tail_copied_data.bend',
    inputs: [
      [['C{7n}', 'True{}'], 14],
      [['C{7n}', 'False{}'], 28],
      [['D{9n}', 'True{}'], 36],
      [['D{9n}', 'False{}'], 36],
    ],
  },
  {
    name: 'ineligible wildcard before constructor',
    file: 'pure_tail_ineligible_before.bend',
    inputs: [[['C{}'], 10], [['D{}'], 10]],
  },
  {
    name: 'ineligible wildcard between constructors',
    file: 'pure_tail_ineligible_between.bend',
    inputs: [[['C{}'], 10], [['D{}'], 20], [['E{}'], 20]],
  },
  {
    name: 'explicit free affine parameter',
    file: 'pure_tail_explicit_free_affine.bend',
    inputs: [
      [['Resource{7n}', 'C{}', 'True{}'], 7],
      [['Resource{7n}', 'C{}', 'False{}'], 17],
      [['Resource{9n}', 'D{}', 'True{}'], 19],
      [['Resource{9n}', 'D{}', 'False{}'], 19],
    ],
  },
  {
    name: 'stable Many capture and decreasing self-call',
    file: 'pure_tail_stable_many_selfcall.bend',
    inputs: [
      [['10n', 'C{}', 'Nil{}'], 10],
      [['10n', 'D{}', 'Nil{}'], 10],
      [['10n', 'C{}', 'Con{2n, Con{3n, Nil{}}}'], 15],
      [['10n', 'D{}', 'Con{2n, Con{3n, Nil{}}}'], 15],
    ],
  },
];

const sourcePath = (file: string): string =>
  resolve(import.meta.dir, '../tests/flatten', file);

async function load(file: string): Promise<B.Book> {
  const book = B.book_nil();
  await B.book_load(book, sourcePath(file), '', new Map());
  B.book_valid(book);
  return book;
}

function parse(book: B.Book, file: string, source: string): B.HTerm {
  const parser: B.Parse = {
    book, dir: dirname(sourcePath(file)) + '/', str: source, pos: 0,
    sc: {stk: [], frs: 0}, ns: '', al: {}, os: [], inst: null, ts: [], lv: 0,
  };
  return B.term_higher(B.parse_term(parser));
}

function nat(book: B.Book, term: B.HTerm): number {
  let value = B.term_wnf(book, term);
  let result = 0;
  while (value.$ === 'Ctr' && value.k === 'Succ') {
    result++;
    value = B.term_wnf(book, value.x[0]);
  }
  if (value.$ !== 'Ctr' || value.k !== 'Zero') {
    throw Error('Expected a native Nat result');
  }
  return result;
}

for (const fixture of fixtures) {
  test(`production pure tail: ${fixture.name}`, async () => {
    const book = await load(fixture.file);
    for (const [args, expected] of fixture.inputs) {
      expect(nat(book, parse(book, fixture.file, `matrix(${args.join(', ')})`)))
        .toBe(expected);
    }
  }, 30000);
}
