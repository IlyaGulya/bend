/** Small generic programs; each extraction is an ordinary source match row. */
export type BodyCaptureFixture = Readonly<{
  name: string;
  source: string;
  row: readonly number[];
  inputs: readonly (readonly [expression: string, expected: number])[];
}>;
const resource = `type Resource is Type:
  Resource{value: Nat}
def consume(resource: Resource) -> Nat:
  match resource:
    case Resource{value}:
      value
`;
export const bodyCaptureFixtures: readonly BodyCaptureFixture[] = [
  {
    name: 'ordinary captured value',
    source: `import Base
def example(seed: Nat, flag: Bool) -> Nat:
  match flag:
    case True{}:
      seed
    case False{}:
      0n
`,
    row: [0],
    inputs: [['example(7n, True{})', 7], ['example(19n, True{})', 19], ['example(7n, False{})', 0]],
  },
  {
    name: 'affine resource remains affine',
    source: `import Base
${resource}def example(resource: Resource, flag: Bool) -> Nat:
  match flag:
    case True{}:
      consume(resource)
    case False{}:
      consume(resource)
`,
    row: [0],
    inputs: [['example(Resource{13n}, True{})', 13], ['example(Resource{21n}, False{})', 21]],
  },
  {
    name: 'Many captured value supports contraction',
    source: `import Base
def example(+seed: Nat, flag: Bool) -> Nat:
  match flag:
    case True{}:
      Nat.add(seed, seed)
    case False{}:
      seed
`,
    row: [0],
    inputs: [['example(8n, True{})', 16], ['example(3n, True{})', 6], ['example(8n, False{})', 8]],
  },
  {
    name: 'two captured values retain distinct identities',
    source: `import Base
def example(first: Nat, second: Nat, flag: Bool) -> Nat:
  match flag:
    case True{}:
      Nat.sub(second, first)
    case False{}:
      second
`,
    row: [0],
    inputs: [['example(4n, 9n, True{})', 5], ['example(2n, 15n, True{})', 13], ['example(4n, 9n, False{})', 9]],
  },
  {
    name: 'same-name pattern binder shadows a different typed formal',
    source: `import Base
type Box is Data:
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
      value
    case Empty{}:
      flag_number(value)
`,
    row: [0],
    inputs: [['example(True{}, Packed{17n})', 17], ['example(False{}, Packed{6n})', 6], ['example(True{}, Empty{})', 2], ['example(False{}, Empty{})', 3]],
  },
  {
    name: 'capture type closes over an earlier erased type binder',
    source: `import Base
${resource}def example(-A: Type, value: A, flag: Bool) -> A:
  match flag:
    case True{}:
      value
    case False{}:
      value
`,
    row: [0],
    inputs: [['example(Nat, 23n, True{})', 23], ['example(Nat, 5n, False{})', 5], ['consume(example(Resource, Resource{14n}, True{}))', 14]],
  },
  {
    name: 'remainder tail is captured without the consumed head',
    source: `import Base
def example(tokens: List<&2, Nat>) -> Nat:
  match tokens:
    case _ <> +rest:
      List.length(&2, Nat, rest)
    case Nil{}:
      0n
`,
    row: [0],
    inputs: [['example([9n])', 0], ['example([9n, 8n, 7n, 6n])', 3], ['example([])', 0]],
  },
  {
    name: 'body-local aliases and lambda-shadow binders are not captures',
    source: `import Base
def example(+value: Nat, flag: Bool, other: Nat) -> Nat:
  match flag:
    case True{}:
      saved = value
      Nat.add(saved, (value => value)(other))
    case False{}:
      value
`,
    row: [0],
    inputs: [['example(12n, True{}, 12n)', 24], ['example(5n, True{}, 5n)', 10], ['example(12n, True{}, 3n)', 15], ['example(5n, True{}, 9n)', 14], ['example(12n, False{}, 3n)', 12]],
  },
  {
    name: 'initial matched field precedes a lower-ID captured tail',
    source: `import Base
type Selection is Data:
  Selection{selector: Bool}
def example(selection: Selection, rest: List<&2, Nat>) -> Nat:
  match selection:
    case Selection{selector}:
      match selector:
        case True{}:
          match rest:
            case Nil{}:
              11n
            case _ <> tail:
              List.length(&2, Nat, tail)
        case False{}:
          99n
`,
    row: [0],
    inputs: [
      ['example(Selection{True{}}, [])', 11],
      ['example(Selection{True{}}, [7n])', 0],
      ['example(Selection{True{}}, [7n, 8n, 9n, 10n])', 3],
      ['example(Selection{False{}}, [])', 99],
      ['example(Selection{False{}}, [7n, 8n, 9n, 10n])', 99],
    ],
  },
];

/** An affine payload must still fail native validation after row extraction. */
export const invalidAffineBodyCapture = `import Base
${resource}def example(resource: Resource, flag: Bool) -> Nat:
  match flag:
    case True{}:
      Nat.add(consume(resource), consume(resource))
    case False{}:
      consume(resource)
`;
