/** Pure native producers are marked as effects only at the normalization seam. */
export type EvaluationContextFixture = Readonly<{
  name: string;
  source: string;
  seeds: readonly string[];
  inputs: readonly (readonly [expression: string, expected: number])[];
}>;

const prelude = `import Base
def produce(value: Nat) -> Nat:
  value
`;

const resource = `type Resource is Type:
  Resource{value: Nat}
def consume(resource: Resource) -> Nat:
  match resource:
    case Resource{value}:
      value
`;

export const evaluationContextFixtures: readonly EvaluationContextFixture[] = [
  {
    name: 'constructor field preserves the owner result type',
    source: `${prelude}type Box is Data:
  Box{value: Nat}
def example(seed: Nat) -> Box:
  Box{produce(seed)}
def unbox(box: Box) -> Nat:
  match box:
    case Box{value}:
      value
`,
    seeds: ['produce'],
    inputs: [['unbox(example(7n))', 7], ['unbox(example(0n))', 0]],
  },
  {
    name: 'two nested pure applications retain both computations',
    source: `${prelude}def bump(value: Nat) -> Nat:
  Nat.add(value, 1n)
def example(seed: Nat) -> Nat:
  bump(bump(produce(seed)))
`,
    seeds: ['produce'],
    inputs: [['example(5n)', 7], ['example(0n)', 2]],
  },
  {
    name: 'Local initializer retains its bound-local remainder',
    source: `${prelude}def example(seed: Nat) -> Nat:
  value = Nat.add(produce(seed), 2n)
  Nat.add(value, 3n)
`,
    seeds: ['produce'],
    inputs: [['example(5n)', 10], ['example(0n)', 5]],
  },
  {
    name: 'earlier bound local is captured in a later context',
    source: `${prelude}def example(seed: Nat) -> Nat:
  saved = Nat.add(seed, 2n)
  Nat.add(Nat.add(produce(3n), 0n), saved)
`,
    seeds: ['produce'],
    inputs: [['example(8n)', 13], ['example(1n)', 6]],
  },
  {
    name: 'ordinary capture retains argument order',
    source: `${prelude}def example(first: Nat, second: Nat) -> Nat:
  Nat.sub(second, Nat.add(produce(first), 0n))
`,
    seeds: ['produce'],
    inputs: [['example(4n, 9n)', 5], ['example(2n, 15n)', 13]],
  },
  {
    name: 'affine capture permits exactly one resource use',
    source: `${prelude}${resource}def example(seed: Nat, resource: Resource) -> Nat:
  Nat.add(Nat.add(produce(seed), 0n), consume(resource))
`,
    seeds: ['produce'],
    inputs: [['example(2n, Resource{13n})', 15], ['example(5n, Resource{21n})', 26]],
  },
  {
    name: 'Many capture preserves valid contraction',
    source: `${prelude}def example(+seed: Nat) -> Nat:
  Nat.add(Nat.add(produce(1n), 0n), Nat.add(seed, seed))
`,
    seeds: ['produce'],
    inputs: [['example(8n)', 17], ['example(3n)', 7]],
  },
  {
    name: 'Match pattern-local capture keeps its scope',
    source: `${prelude}type Box is Data:
  Packed{value: Nat}
  Empty{}
def example(box: Box) -> Nat:
  match box:
    case Packed{value}:
      Nat.add(Nat.add(produce(2n), 0n), value)
    case Empty{}:
      1n
`,
    seeds: ['produce'],
    inputs: [['example(Packed{17n})', 19], ['example(Packed{6n})', 8], ['example(Empty{})', 1]],
  },
  {
    name: 'simultaneous captures remain distinct',
    source: `${prelude}def example(seed: Nat, first: Nat, second: Nat) -> Nat:
  Nat.add(Nat.add(produce(seed), 0n), Nat.sub(second, first))
`,
    seeds: ['produce'],
    inputs: [['example(3n, 4n, 9n)', 8], ['example(7n, 2n, 15n)', 20]],
  },
  {
    name: 'same-name binders retain their distinct typed identities',
    source: `${prelude}type Box is Data:
  Packed{value: Nat}
  Empty{}
def flag_number(flag: Bool) -> Nat:
  match flag:
    case True{}:
      2n
    case False{}:
      3n
def example(+value: Bool, box: Box) -> Nat:
  match box:
    case Packed{value}:
      Nat.add(Nat.add(produce(2n), 0n), value)
    case Empty{}:
      flag_number(value)
`,
    seeds: ['produce'],
    inputs: [
      ['example(True{}, Packed{17n})', 19],
      ['example(False{}, Packed{6n})', 8],
      ['example(True{}, Empty{})', 2],
      ['example(False{}, Empty{})', 3],
    ],
  },
  {
    name: 'sequential effects normalize through subsequent Local continuations',
    source: `${prelude}def example(seed: Nat) -> Nat:
  first = Nat.add(produce(seed), 1n)
  second = Nat.add(produce(first), 2n)
  Nat.add(second, 3n)
`,
    seeds: ['produce'],
    inputs: [['example(4n)', 10], ['example(0n)', 6]],
  },
  {
    name: 'effectful reverse reachability includes an indirect producer',
    source: `${prelude}def relay(value: Nat) -> Nat:
  produce(value)
def example(seed: Nat) -> Nat:
  Nat.add(relay(seed), 2n)
`,
    seeds: ['produce'],
    inputs: [['example(11n)', 13], ['example(0n)', 2]],
  },
  {
    name: 'already-supported terminal named consumer remains valid',
    source: `${prelude}def bump(value: Nat) -> Nat:
  Nat.add(value, 1n)
def example(seed: Nat) -> Nat:
  bump(produce(seed))
`,
    seeds: ['produce'],
    inputs: [['example(4n)', 5], ['example(0n)', 1]],
  },
];

export const multipleSiblingEffects: EvaluationContextFixture = {
  name: 'multiple suspended sibling effects',
  source: `${prelude}def example(first: Nat, second: Nat) -> Nat:
  Nat.sub(produce(first), produce(second))
`,
  seeds: ['produce'],
  inputs: [['example(9n, 4n)', 5], ['example(15n, 2n)', 13], ['example(2n, 15n)', 0]],
};

/** Factoring must not turn invalid affine contraction into a valid program. */
export const invalidAffineEvaluationContext = `${prelude}${resource}def example(seed: Nat, resource: Resource) -> Nat:
  Nat.add(Nat.add(produce(seed), 0n), Nat.add(consume(resource), consume(resource)))
`;
