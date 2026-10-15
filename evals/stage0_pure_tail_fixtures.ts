import * as B from '../bend2/bend.ts';
import {createHash} from 'node:crypto';
import {mkdtemp, writeFile, rm} from 'node:fs/promises';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {readParserGraph} from './parser_full_graph.ts';
import {compilePureTail, type PureTailStats} from './stage0_pure_tail_compiler.ts';

export type PureTailFixture = {
  name: string;
  source: string;
  expectedRootEligible: boolean;
  inputs: readonly {args: readonly string[]; expected: number}[];
  covers: readonly string[];
};

const dataPrelude = `import Base
type Tag is Data:
  C{value: Nat}
  D{value: Nat}
  E{value: Nat}
type Choice is Data:
  X{}
  Y{}
  P{}
  Q{}
`;

export const pureTailFixtures: readonly PureTailFixture[] = [
  {
    name: 'field-prefix-pure-tail',
    source: dataPrelude + `def matrix(tag: Tag, choice: Choice) -> Nat:
  match tag choice:
    case C{value} X{}:
      value
    case C{value} Y{}:
      Nat.add(value, 1n)
    case _ P{}:
      30n
    case _ Q{}:
      40n
    case _ _:
      50n
`,
    expectedRootEligible: true,
    inputs: [
      {args: ['C{7n}', 'X{}'], expected: 7},
      {args: ['C{7n}', 'Y{}'], expected: 8},
      {args: ['C{7n}', 'P{}'], expected: 30},
      {args: ['C{7n}', 'Q{}'], expected: 40},
      {args: ['D{9n}', 'X{}'], expected: 50},
      {args: ['D{9n}', 'Y{}'], expected: 50},
      {args: ['D{9n}', 'P{}'], expected: 30},
      {args: ['E{11n}', 'Q{}'], expected: 40},
    ],
    covers: ['constructor-field-binding', 'X-Y-prefix', 'P-Q-pure-tail', 'prefix-later-column-failure', 'absent-constructor-default'],
  },
  {
    name: 'several-constructors-later-fallthrough',
    source: dataPrelude + `def matrix(tag: Tag, choice: Choice, later: Bool) -> Nat:
  match tag choice later:
    case C{value} X{} True{}:
      value
    case D{value} Y{} True{}:
      Nat.add(value, 10n)
    case E{value} X{} True{}:
      Nat.add(value, 20n)
    case _ P{} True{}:
      30n
    case _ P{} False{}:
      31n
    case _ _ _:
      40n
`,
    expectedRootEligible: true,
    inputs: [
      {args: ['C{7n}', 'X{}', 'True{}'], expected: 7},
      {args: ['D{9n}', 'Y{}', 'True{}'], expected: 19},
      {args: ['E{11n}', 'X{}', 'True{}'], expected: 31},
      {args: ['C{7n}', 'X{}', 'False{}'], expected: 40},
      {args: ['D{9n}', 'Y{}', 'False{}'], expected: 40},
      {args: ['E{11n}', 'X{}', 'False{}'], expected: 40},
      {args: ['C{7n}', 'P{}', 'True{}'], expected: 30},
      {args: ['C{7n}', 'P{}', 'False{}'], expected: 31},
      {args: ['D{9n}', 'P{}', 'False{}'], expected: 31},
      {args: ['E{11n}', 'P{}', 'False{}'], expected: 31},
      {args: ['E{11n}', 'Q{}', 'True{}'], expected: 40},
    ],
    covers: ['C-D-E-before-tail', 'last-constructor-of-any-kind-boundary', 'first-suffix-row-later-failure-then-next-row'],
  },
  {
    name: 'affine-reconstruction',
    source: `import Base
type Resource is Type:
  Resource{value: Nat}
type Packet is Type:
  C{resource: Resource}
  D{resource: Resource}
  E{resource: Resource}
def consume_resource(resource: Resource) -> Nat:
  match resource:
    case Resource{value}:
      value
def consume(packet: Packet) -> Nat:
  match packet:
    case C{resource}:
      Nat.add(consume_resource(resource), 10n)
    case D{resource}:
      Nat.add(consume_resource(resource), 20n)
    case E{resource}:
      Nat.add(consume_resource(resource), 30n)
def matrix(packet: Packet, flag: Bool) -> Nat:
  match packet flag:
    case C{resource} True{}:
      consume_resource(resource)
    case whole _:
      consume(whole)
`,
    expectedRootEligible: true,
    inputs: [
      {args: ['C{Resource{7n}}', 'True{}'], expected: 7},
      {args: ['C{Resource{7n}}', 'False{}'], expected: 17},
      {args: ['D{Resource{9n}}', 'True{}'], expected: 29},
      {args: ['D{Resource{9n}}', 'False{}'], expected: 29},
      {args: ['E{Resource{11n}}', 'True{}'], expected: 41},
      {args: ['E{Resource{11n}}', 'False{}'], expected: 41},
    ],
    covers: ['Type-Resource-field-in-Type-Packet', 'One-field-consumed-on-success', 'whole-original-reconstructed-after-later-Bool-failure', 'whole-original-consumed-once-in-suffix', 'exclusive-affine-capture'],
  },
  {
    name: 'copied-data-marks',
    source: `import Base
type Tag is Data:
  C{value: Nat}
  D{value: Nat}
def copied_value(+tag: Tag) -> Nat:
  match tag:
    case C{+value}:
      Nat.add(value, value)
    case D{+value}:
      Nat.add(value, value)
def matrix(+tag: Tag, flag: Bool) -> Nat:
  match tag flag:
    case C{+value} True{}:
      Nat.add(value, value)
    case +whole _:
      Nat.add(copied_value(whole), copied_value(whole))
`,
    expectedRootEligible: true,
    inputs: [
      {args: ['C{7n}', 'True{}'], expected: 14},
      {args: ['C{7n}', 'False{}'], expected: 28},
      {args: ['D{9n}', 'True{}'], expected: 36},
      {args: ['D{9n}', 'False{}'], expected: 36},
    ],
    covers: ['Data-Many-parameter-preserved', 'copied-field-mark-preserved', 'copied-whole-mark-preserved'],
  },
  {
    name: 'ineligible-before',
    source: `import Base
type Tag is Data:
  C{}
  D{}
def matrix(tag: Tag) -> Nat:
  match tag:
    case _:
      10n
    case C{}:
      20n
    case _:
      30n
`,
    expectedRootEligible: false,
    inputs: [{args: ['C{}'], expected: 10}, {args: ['D{}'], expected: 10}],
    covers: ['wildcard-before-constructor-rejected', 'shadowed-constructor-order-preserved', 'no-inner-split'],
  },
  {
    name: 'ineligible-between',
    source: `import Base
type Tag is Data:
  C{}
  D{}
  E{}
def matrix(tag: Tag) -> Nat:
  match tag:
    case C{}:
      10n
    case _:
      20n
    case D{}:
      30n
    case _:
      40n
`,
    expectedRootEligible: false,
    inputs: [
      {args: ['C{}'], expected: 10},
      {args: ['D{}'], expected: 20},
      {args: ['E{}'], expected: 20},
    ],
    covers: ['wildcard-between-constructors-rejected', 'shadowed-D-order-preserved', 'no-inner-split'],
  },
  {
    name: 'explicit-free-affine-parameter',
    source: `import Base
type Resource is Type:
  Resource{value: Nat}
type Tag is Data:
  C{}
  D{}
def consume(resource: Resource) -> Nat:
  match resource:
    case Resource{value}: value
def matrix(resource: Resource, tag: Tag, flag: Bool) -> Nat:
  match tag flag:
    case C{} True{}: consume(resource)
    case _ _: Nat.add(consume(resource), 10n)
`,
    expectedRootEligible: true,
    inputs: [
      {args: ['Resource{7n}', 'C{}', 'True{}'], expected: 7},
      {args: ['Resource{7n}', 'C{}', 'False{}'], expected: 17},
      {args: ['Resource{9n}', 'D{}', 'True{}'], expected: 19},
      {args: ['Resource{9n}', 'D{}', 'False{}'], expected: 19},
    ],
    covers: ['free-One-Type-value-explicitly-parameterized', 'prefix-and-residual-exclusive-transfer', 'no-affine-capture-at-binding'],
  },
  {
    name: 'decreasing-self-call-with-free-many-value',
    source: `import Base
type Tag is Data:
  C{}
  D{}
def matrix(+offset: Nat, tag: Tag, items: List<&2, Nat>) -> Nat:
  match tag items:
    case C{} Nil{}: offset
    case whole Con{head, tail}: Nat.add(head, matrix(offset, whole, tail))
    case _ Nil{}: offset
`,
    expectedRootEligible: true,
    inputs: [
      {args: ['10n', 'C{}', 'Nil{}'], expected: 10},
      {args: ['10n', 'D{}', 'Nil{}'], expected: 10},
      {args: ['10n', 'C{}', 'Con{2n, Con{3n, Nil{}}}'], expected: 15},
      {args: ['10n', 'D{}', 'Con{2n, Con{3n, Nil{}}}'], expected: 15},
    ],
    covers: ['decreasing-self-call-inside-normal-suffix', 'free-Many-parameter', 'unchanged-native-descent-check'],
  },
];

export type PureTailFixtureObservation = {
  fixture: string;
  sourceSha256: string;
  rootEligible: boolean;
  baseline: {bookValid: 'passed'; outputs: FixtureOutput[]};
  prototype: {bookValid: 'passed'; outputs: FixtureOutput[]};
  stats: PureTailStats;
  residualNames: string[];
  capture: {parameters: {name: string; quantity: B.Quant}[]; covers: readonly string[]};
};
type FixtureOutput = {args: readonly string[]; expected: number; actual: number};

async function load(source: string): Promise<B.Book> {
  const directory = await mkdtemp(join(tmpdir(), 'bend-stage0-pure-tail-'));
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

function evaluate(book: B.Book, fixture: PureTailFixture, mode: string): FixtureOutput[] {
  return fixture.inputs.map(input => {
    const parser: B.Parse = {
      book, dir: tmpdir() + '/', str: `matrix(${input.args.join(', ')})`, pos: 0,
      sc: {stk: [], frs: 0}, ns: '', al: {}, os: [], inst: null, ts: [], lv: 0,
    };
    let value = B.term_wnf(book, B.term_higher(B.parse_term(parser)));
    let actual = 0;
    while (value.$ === 'Ctr' && value.k === 'Succ') {
      actual++;
      value = B.term_wnf(book, value.x[0]);
    }
    if (value.$ !== 'Ctr' || value.k !== 'Zero') {
      throw Error(`${fixture.name} ${mode}: expected native Nat result`);
    }
    if (actual !== input.expected) {
      throw Error(`${fixture.name} ${mode}: matrix(${input.args.join(', ')}) expected ${input.expected}, observed ${actual}`);
    }
    return {args: input.args, expected: input.expected, actual};
  });
}

/** Native ownership and literal evaluation on independently loaded baseline/prototype books.
 * Exported source fixtures allow the parent to recompile affine-reconstruction for
 * representation measurements without retaining the large native books here. */
export async function runPureTailFixtures(): Promise<PureTailFixtureObservation[]> {
  const observations: PureTailFixtureObservation[] = [];
  for (const fixture of pureTailFixtures) {
    const graph = await readParserGraph(fixture.source);
    const body = graph.bodies.get('matrix');
    const signature = graph.signatures.get('matrix');
    if (!body || body.$ !== 'Match' || !signature) {
      throw Error(`${fixture.name}: missing raw matrix Match/signature`);
    }
    const compilation = compilePureTail(body, signature.parameters, signature.result, graph.parserBook);
    if (compilation.stats.rootEligible !== fixture.expectedRootEligible) {
      throw Error(`${fixture.name}: root eligibility expected ${fixture.expectedRootEligible}, observed ${compilation.stats.rootEligible}`);
    }
    if (!fixture.expectedRootEligible && compilation.stats.eligibleSplits !== 0) {
      throw Error(`${fixture.name}: ineligible control optimized ${compilation.stats.eligibleSplits} splits`);
    }
    if (fixture.expectedRootEligible && (compilation.stats.eligibleSplits === 0 || compilation.residualNames.length === 0)) {
      throw Error(`${fixture.name}: eligible fixture did not bind a residual continuation`);
    }
    const baselineBook = await load(fixture.source);
    try { B.book_valid(baselineBook); } catch(error) { console.error('Native baseline fixture:',fixture.name); throw error; }
    const baseline = {bookValid: 'passed' as const, outputs: evaluate(baselineBook, fixture, 'baseline')};
    const prototypeBook = await load(fixture.source);
    const matrix = prototypeBook.tlds.matrix;
    if (!matrix || matrix.$ !== 'Def') throw Error(`${fixture.name}: missing native matrix definition`);
    matrix.v = B.term_higher(compilation.term);
    try { B.book_valid(prototypeBook); } catch(error) { console.error('Native prototype fixture:',fixture.name); throw error; }
    const prototype = {bookValid: 'passed' as const, outputs: evaluate(prototypeBook, fixture, 'prototype')};
    observations.push({
      fixture: fixture.name,
      sourceSha256: createHash('sha256').update(fixture.source).digest('hex'),
      rootEligible: compilation.stats.rootEligible,
      baseline, prototype, stats: compilation.stats, residualNames: compilation.residualNames,
      capture: {
        parameters: signature.parameters.map(([quantity, name]) => ({name, quantity})),
        covers: fixture.covers,
      },
    });
    Bun.gc(true);
  }
  return observations;
}
