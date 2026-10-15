import * as B from '../bend2/bend.ts';
import {createHash} from 'node:crypto';
import {mkdtemp, writeFile, rm} from 'node:fs/promises';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {readParserGraph} from './parser_full_graph.ts';
import {suffixFixtures, type Fixture} from './stage0_trailing_suffix_fixtures.ts';
import {trailingSuffixEligibility, type SuffixEligibility} from './stage0_trailing_suffix_eligibility.ts';

export type NativeSuffixFixtureObservation = {
  fixture: string;
  sourceSha256: string;
  selectedConstructor: string;
  eligibility: SuffixEligibility;
  nativeLoad: 'passed';
  bookValid: 'passed';
  results: {args: readonly string[]; expected: number; actual: number}[];
};

async function load(source: string): Promise<B.Book> {
  const directory = await mkdtemp(join(tmpdir(), 'bend-stage0-trailing-suffix-'));
  try {
    const path = join(directory, 'main.bend');
    await writeFile(path, source);
    const book = B.book_nil();
    await B.book_load(book, path, '', new Map());
    return book;
  } finally {
    await rm(directory, {recursive: true, force: true});
  }
}

function run(book: B.Book, args: readonly string[]): number {
  const parser: B.Parse = {
    book, dir: tmpdir() + '/', str: `matrix(${args.join(', ')})`, pos: 0,
    sc: {stk: [], frs: 0}, ns: '', al: {}, os: [], inst: null, ts: [], lv: 0,
  };
  let value = B.term_wnf(book, B.term_higher(B.parse_term(parser)));
  let result = 0;
  while (value.$ === 'Ctr' && value.k === 'Succ') {
    result++;
    value = B.term_wnf(book, value.x[0]);
  }
  if (value.$ !== 'Ctr' || value.k !== 'Zero') throw Error('Expected a native Nat result');
  return result;
}

/** Baseline observations only: no source rewrite, optimized compiler or witness adapter. */
export async function runNativeSuffixFixtures(): Promise<NativeSuffixFixtureObservation[]> {
  const observations: NativeSuffixFixtureObservation[] = [];
  for (const fixture of suffixFixtures) {
    const graph = await readParserGraph(fixture.source);
    const body = graph.bodies.get('matrix');
    if (!body || body.$ !== 'Match') throw Error(`${fixture.name}: expected a raw matrix Match Body`);
    let selectedConstructor: string | undefined;
    for (const row of body.r) {
      const pattern = row.p[0];
      if (pattern?.$ === 'PCtr') {
        selectedConstructor = pattern.k;
        break;
      }
    }
    if (!selectedConstructor) throw Error(`${fixture.name}: missing first-column constructor`);
    const eligibility = trailingSuffixEligibility(body.r, selectedConstructor);
    const classification = eligibility.eligible ? 'eligible' : 'legacy';
    if (classification !== fixture.expectedEligibility) {
      throw Error(`${fixture.name}: expected ${fixture.expectedEligibility}, observed ${JSON.stringify(eligibility)}`);
    }
    const book = await load(fixture.source);
    B.book_valid(book);
    const results: NativeSuffixFixtureObservation['results'] = [];
    for (const input of fixture.inputs) {
      const actual = run(book, input.args);
      if (actual !== input.expected) {
        throw Error(`${fixture.name}: matrix(${input.args.join(', ')}) expected ${input.expected}, observed ${actual}`);
      }
      results.push({args: input.args, expected: input.expected, actual});
    }
    observations.push({
      fixture: fixture.name,
      sourceSha256: createHash('sha256').update(fixture.source).digest('hex'),
      selectedConstructor, eligibility, nativeLoad: 'passed', bookValid: 'passed', results,
    });
    Bun.gc(true);
  }
  return observations;
}

export async function runNativeSuffixWitness(
  fixture: Fixture,
  witness: B.HTerm,
): Promise<{validated: boolean; cases: number; outputs: NativeSuffixFixtureObservation['results']}> {
  const book = await load(fixture.source);
  const matrix = book.tlds.matrix;
  if (!matrix || matrix.$ !== 'Def') throw Error(`${fixture.name}: expected a native matrix definition`);
  matrix.v = witness;
  B.book_valid(book);
  const outputs: NativeSuffixFixtureObservation['results'] = [];
  for (const input of fixture.inputs) {
    const actual = run(book, input.args);
    if (actual !== input.expected) {
      throw Error(`${fixture.name} witness: matrix(${input.args.join(', ')}) expected ${input.expected}, observed ${actual}`);
    }
    outputs.push({args: input.args, expected: input.expected, actual});
  }
  return {validated: true, cases: outputs.length, outputs};
}
