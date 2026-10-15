export type Fixture = {
  name: string;
  source: string;
  expectedEligibility: 'eligible' | 'legacy';
  inputs: readonly {args: readonly string[]; expected: number}[];
  covers: readonly string[];
};

export const suffixFixtures: readonly Fixture[] = [
  {
    name: 'eligible-closed',
    source: `import Base
type Tag is Data:
  C{}
  D{}
def matrix(tag: Tag, flag: Bool, later: Bool) -> Nat:
  match tag flag later:
    case C{} True{} True{}:
      1n
    case C{} True{} False{}:
      2n
    case _ False{} True{}:
      30n
    case _ _ _:
      40n
`,
    expectedEligibility: 'eligible',
    inputs: [
      {args: ['C{}', 'True{}', 'True{}'], expected: 1},
      {args: ['C{}', 'True{}', 'False{}'], expected: 2},
      {args: ['C{}', 'False{}', 'True{}'], expected: 30},
      {args: ['C{}', 'False{}', 'False{}'], expected: 40},
      {args: ['D{}', 'True{}', 'True{}'], expected: 40},
      {args: ['D{}', 'True{}', 'False{}'], expected: 40},
      {args: ['D{}', 'False{}', 'True{}'], expected: 30},
      {args: ['D{}', 'False{}', 'False{}'], expected: 40},
    ],
    covers: ['closed-trailing-suffix', 'C-prefix-failure', 'non-C-default', 'later-column-fallthrough'],
  },
  {
    name: 'eligible-other-constructor-in-suffix',
    source: `import Base
type Tag is Data:
  C{}
  D{}
def matrix(tag: Tag, flag: Bool) -> Nat:
  match tag flag:
    case C{} True{}:
      1n
    case D{} True{}:
      20n
    case _ False{}:
      30n
    case _ _:
      40n
`,
    expectedEligibility: 'eligible',
    inputs: [
      {args: ['C{}', 'True{}'], expected: 1},
      {args: ['C{}', 'False{}'], expected: 30},
      {args: ['D{}', 'True{}'], expected: 20},
      {args: ['D{}', 'False{}'], expected: 30},
    ],
    covers: ['other-constructor-after-last-C', 'C-prefix-failure', 'non-C-constructor-suffix'],
  },
  {
    name: 'legacy-before-wildcard',
    source: `import Base
type Tag is Data:
  C{}
  D{}
def matrix(tag: Tag, flag: Bool) -> Nat:
  match tag flag:
    case _ True{}:
      10n
    case C{} _:
      20n
    case _ _:
      30n
`,
    expectedEligibility: 'legacy',
    inputs: [
      {args: ['C{}', 'True{}'], expected: 10},
      {args: ['C{}', 'False{}'], expected: 20},
      {args: ['D{}', 'True{}'], expected: 10},
      {args: ['D{}', 'False{}'], expected: 30},
    ],
    covers: ['wildcard-before-C', 'later-C-deliberately-shadowed', 'raw-row-order'],
  },
  {
    name: 'legacy-between-wildcard',
    source: `import Base
type Tag is Data:
  C{}
  D{}
def matrix(tag: Tag, flag: Bool, later: Bool) -> Nat:
  match tag flag later:
    case C{} True{} True{}:
      1n
    case _ False{} _:
      30n
    case C{} _ False{}:
      2n
    case _ _ _:
      40n
`,
    expectedEligibility: 'legacy',
    inputs: [
      {args: ['C{}', 'True{}', 'True{}'], expected: 1},
      {args: ['C{}', 'True{}', 'False{}'], expected: 2},
      {args: ['C{}', 'False{}', 'True{}'], expected: 30},
      {args: ['C{}', 'False{}', 'False{}'], expected: 30},
      {args: ['D{}', 'True{}', 'True{}'], expected: 40},
      {args: ['D{}', 'True{}', 'False{}'], expected: 40},
      {args: ['D{}', 'False{}', 'True{}'], expected: 30},
      {args: ['D{}', 'False{}', 'False{}'], expected: 30},
    ],
    covers: ['wildcard-between-same-C-rows', 'later-C-deliberately-shadowed', 'raw-row-order'],
  },
  {
    name: 'eligible-later-column-fallthrough',
    source: `import Base
type Tag is Data:
  C{}
  D{}
def matrix(tag: Tag, flag: Bool, later: Bool) -> Nat:
  match tag flag later:
    case C{} True{} True{}:
      1n
    case _ False{} True{}:
      30n
    case _ False{} False{}:
      31n
    case _ _ _:
      40n
`,
    expectedEligibility: 'eligible',
    inputs: [
      {args: ['C{}', 'True{}', 'True{}'], expected: 1},
      {args: ['C{}', 'True{}', 'False{}'], expected: 40},
      {args: ['C{}', 'False{}', 'True{}'], expected: 30},
      {args: ['C{}', 'False{}', 'False{}'], expected: 31},
      {args: ['D{}', 'True{}', 'True{}'], expected: 40},
      {args: ['D{}', 'True{}', 'False{}'], expected: 40},
      {args: ['D{}', 'False{}', 'True{}'], expected: 30},
      {args: ['D{}', 'False{}', 'False{}'], expected: 31},
    ],
    covers: ['multi-column-suffix', 'later-column-failure-selects-next-suffix-row', 'C-prefix-failure', 'non-C-default'],
  },
  {
    name: 'eligible-nested-fields',
    source: `import Base
type Payload is Data:
  Packed{flag: Bool, value: Nat}
  Vacant{}
type Tag is Data:
  C{payload: Payload}
  D{payload: Payload}
def matrix(tag: Tag, flag: Bool) -> Nat:
  match tag flag:
    case C{Packed{True{}, value}} True{}:
      value
    case C{Packed{False{}, value}} True{}:
      Nat.add(value, 1n)
    case _ False{}:
      30n
    case _ _:
      40n
`,
    expectedEligibility: 'eligible',
    inputs: [
      {args: ['C{Packed{True{}, 7n}}', 'True{}'], expected: 7},
      {args: ['C{Packed{False{}, 7n}}', 'True{}'], expected: 8},
      {args: ['C{Packed{True{}, 7n}}', 'False{}'], expected: 30},
      {args: ['C{Packed{False{}, 7n}}', 'False{}'], expected: 30},
      {args: ['C{Vacant{}}', 'True{}'], expected: 40},
      {args: ['C{Vacant{}}', 'False{}'], expected: 30},
      {args: ['D{Packed{True{}, 9n}}', 'True{}'], expected: 40},
      {args: ['D{Packed{False{}, 9n}}', 'False{}'], expected: 30},
      {args: ['D{Vacant{}}', 'True{}'], expected: 40},
      {args: ['D{Vacant{}}', 'False{}'], expected: 30},
    ],
    covers: ['nested-constructor-fields', 'nested-C-prefix-failure', 'C-later-column-failure', 'non-C-default'],
  },
  {
    name: 'eligible-affine-whole-alias',
    source: `import Base
type Resource is Type:
  Resource{value: Nat}
type Packet is Type:
  C{resource: Resource}
  D{resource: Resource}
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
def matrix(packet: Packet, flag: Bool) -> Nat:
  match packet flag:
    case C{resource} True{}:
      consume_resource(resource)
    case whole _:
      consume(whole)
`,
    expectedEligibility: 'eligible',
    inputs: [
      {args: ['C{Resource{7n}}', 'True{}'], expected: 7},
      {args: ['C{Resource{7n}}', 'False{}'], expected: 17},
      {args: ['D{Resource{9n}}', 'True{}'], expected: 29},
      {args: ['D{Resource{9n}}', 'False{}'], expected: 29},
    ],
    covers: ['affine-Type-field-in-outer-Type-packet', 'One-whole-alias-consumed-once-by-native-helper', 'native-book-valid-ownership', 'C-prefix-failure', 'non-C-default'],
  },
  {
    name: 'eligible-copied-data-capture',
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
    expectedEligibility: 'eligible',
    inputs: [
      {args: ['C{7n}', 'True{}'], expected: 14},
      {args: ['C{7n}', 'False{}'], expected: 28},
      {args: ['D{9n}', 'True{}'], expected: 36},
      {args: ['D{9n}', 'False{}'], expected: 36},
    ],
    covers: ['copied-Data-field', 'Many-whole-capture-used-twice', 'explicit-quantities-preserved', 'C-prefix-failure', 'non-C-default'],
  },
];
