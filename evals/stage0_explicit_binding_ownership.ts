import * as B from '../bend2/bend.ts';
import {createHash} from 'node:crypto';
import {mkdtemp, writeFile, rm} from 'node:fs/promises';
import {join} from 'node:path';
import {tmpdir} from 'node:os';

export type ExplicitBindingOwnershipObservation = {
  name: string;
  expected: 'PASS' | 'FAIL';
  actual: 'PASS' | 'FAIL';
  bookValid: boolean;
  error: string | null;
  role: 'case' | 'control';
  quantity: 'Lone' | 'Many';
  callShape: 'exclusive-branches' | 'sequential';
  failureKind: 'affine-usage' | 'function-kind' | 'other-checker' | 'output-mismatch' | null;
  expectationMatched: boolean;
  source: string;
  sourceSha256: string;
  outputs: {args: readonly string[]; expected: number; actual: number}[];
};

type Fixture = {
  name: string;
  expected: 'PASS' | 'FAIL';
  role: 'case' | 'control';
  quantity: 'Lone' | 'Many';
  callShape: 'exclusive-branches' | 'sequential';
  source: string;
  inputs: readonly {args: readonly string[]; expected: number}[];
};

const fixtures: readonly Fixture[] = [
  {
    name: 'closed-reusable-continuation',
    expected: 'PASS',
    role: 'case', quantity: 'Lone', callShape: 'exclusive-branches',
    source: `import Base
def matrix(flag: Bool) -> Nat:
  residual = {x => x : Nat -> Nat}
  {\\{True: residual(1n); False: residual(2n)} : Bool -> Nat}(flag)
`,
    inputs: [
      {args: ['True{}'], expected: 1},
      {args: ['False{}'], expected: 2},
    ],
  },
  {
    name: 'unrestricted-value-capture',
    expected: 'PASS',
    role: 'case', quantity: 'Lone', callShape: 'exclusive-branches',
    source: `import Base
def matrix(flag: Bool, +value: Nat) -> Nat:
  residual = {x => Nat.add(value, x) : Nat -> Nat}
  {\\{True: residual(1n); False: residual(2n)} : Bool -> Nat}(flag)
`,
    inputs: [
      {args: ['True{}', '10n'], expected: 11},
      {args: ['False{}', '10n'], expected: 12},
    ],
  },
  {
    name: 'affine-resource-capture',
    expected: 'PASS',
    role: 'case', quantity: 'Lone', callShape: 'exclusive-branches',
    source: `import Base
type Resource is Type:
  Resource{value: Nat}
def consume(resource: Resource, extra: Nat) -> Nat:
  match resource:
    case Resource{value}:
      Nat.add(value, extra)
def matrix(flag: Bool, resource: Resource) -> Nat:
  residual = {extra => consume(resource, extra) : Nat -> Nat}
  {\\{True: residual(1n); False: residual(2n)} : Bool -> Nat}(flag)
`,
    inputs: [
      {args: ['True{}', 'Resource{10n}'], expected: 11},
      {args: ['False{}', 'Resource{10n}'], expected: 12},
    ],
  },
  {
    name: 'explicit-affine-resource-parameter',
    expected: 'PASS',
    role: 'case', quantity: 'Lone', callShape: 'exclusive-branches',
    source: `import Base
type Resource is Type:
  Resource{value: Nat}
def consume(resource: Resource, extra: Nat) -> Nat:
  match resource:
    case Resource{value}:
      Nat.add(value, extra)
def matrix(flag: Bool, resource: Resource) -> Nat:
  residual = {owned => extra => consume(owned, extra) : Resource -> Nat -> Nat}
  {\\{True: residual(resource, 1n); False: residual(resource, 2n)} : Bool -> Nat}(flag)
`,
    inputs: [
      {args: ['True{}', 'Resource{10n}'], expected: 11},
      {args: ['False{}', 'Resource{10n}'], expected: 12},
    ],
  },
  {
    name: 'many-bound-closed-function-control',
    expected: 'FAIL',
    role: 'control', quantity: 'Many', callShape: 'exclusive-branches',
    source: `import Base
def matrix(flag: Bool) -> Nat:
  +residual = {x => x : Nat -> Nat}
  {\\{True: residual(1n); False: residual(2n)} : Bool -> Nat}(flag)
`,
    inputs: [
      {args: ['True{}'], expected: 1},
      {args: ['False{}'], expected: 2},
    ],
  },
  {
    name: 'sequential-affine-capture-control',
    expected: 'FAIL',
    role: 'control', quantity: 'Lone', callShape: 'sequential',
    source: `import Base
type Resource is Type:
  Resource{value: Nat}
def consume(resource: Resource, extra: Nat) -> Nat:
  match resource:
    case Resource{value}:
      Nat.add(value, extra)
def matrix(resource: Resource) -> Nat:
  residual = {extra => consume(resource, extra) : Nat -> Nat}
  Nat.add(residual(1n), residual(2n))
`,
    inputs: [{args: ['Resource{10n}'], expected: 23}],
  },
];

async function load(source: string): Promise<B.Book> {
  const directory = await mkdtemp(join(tmpdir(), 'bend-stage0-explicit-ownership-'));
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


/**
 * Call await runExplicitBindingOwnership() from the existing gated orchestrator.
 * No parser/kernel changes or reconstruction adapter are involved.
 * Four cases retain the requested expectations even if the native checker
 * contradicts them. Two identified controls distinguish actual function
 * contraction (Many) from exclusive branch reuse (Lone). A function-kind
 * rejection is never classified as an affine capture/usage rejection.
 */
export async function runExplicitBindingOwnership(): Promise<ExplicitBindingOwnershipObservation[]> {
  const observations: ExplicitBindingOwnershipObservation[] = [];
  for (const fixture of fixtures) {
    // Loading/parsing errors are never treated as expected ownership rejection.
    const book = await load(fixture.source);
    const observation: ExplicitBindingOwnershipObservation = {
      name: fixture.name, expected: fixture.expected, actual: 'FAIL', bookValid: false,
      error: null, source: fixture.source,
      role: fixture.role, quantity: fixture.quantity, callShape: fixture.callShape,
      failureKind: null, expectationMatched: false,
      sourceSha256: createHash('sha256').update(fixture.source).digest('hex'), outputs: [],
    };
    try {
      B.book_valid(book);
      observation.bookValid = true;
      observation.actual = 'PASS';
    } catch (error) {
      // Use the native tagged Err and printer, following the existing error API.
      const err = error as B.Err;
      if (err?.$ !== 'Err') throw error;
      observation.error = B.err_show(err);
      const affineUsageRejection = err.def === 'matrix'
        && (err.exp === 'resource' || err.exp === 'residual')
        && err.obs === `${err.exp} (consumed more than once)`;
      const functionKindRejection = typeof err.exp !== 'string'
        && err.exp.$ === 'Typ' && err.exp.g.$ === 'Qua' && err.exp.g.q.$ === 'Many'
        && err.obs !== undefined && typeof err.obs !== 'string'
        && err.obs.$ === 'Typ' && err.obs.g.$ === 'Qua' && err.obs.g.q.$ === 'Lone';
      observation.failureKind = affineUsageRejection ? 'affine-usage'
        : functionKindRejection ? 'function-kind' : 'other-checker';
    }
    if (observation.bookValid) {
      for (const input of fixture.inputs) {
        const actual = run(book, input.args);
        observation.outputs.push({args: input.args, expected: input.expected, actual});
        if (actual !== input.expected) {
          observation.actual = 'FAIL';
          observation.failureKind = 'output-mismatch';
          observation.error = `${fixture.name}: matrix(${input.args.join(', ')}) expected ${input.expected}, observed ${actual}`;
        }
      }
    }
    const expectedRejection = fixture.name === 'many-bound-closed-function-control'
      ? 'function-kind' : 'affine-usage';
    observation.expectationMatched = observation.actual === fixture.expected
      && (fixture.expected === 'PASS' || observation.failureKind === expectedRejection);
    observations.push(observation);
  }
  return observations;
}
