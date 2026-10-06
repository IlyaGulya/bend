import type {ReplayFixture} from './load_replay_fixture_types.ts';
import type {LTerm} from '../bend2/bend.ts';

export const fixtures: ReplayFixture[] = [
  {
    name: 'binding-constructor-match',
    features: ['constructor-match', 'constructor-field-binding', 'exhaustive-arms'],
    source: `import Base
type Choice is Data:
  Present{value: Nat}
  Absent{}
def score(choice: Choice) -> Nat:
  match choice:
    case Present{value}:
      value
    case Absent{}:
      5n
def main() -> Nat:
  Nat.add(score(Present{12n}), score(Absent{}))
`,
    expected: '17n',
  },
  {
    name: 'binding-multicolumn-wildcard-priority',
    features: ['multicolumn-match', 'wildcard-priority', 'later-column-fallthrough', 'constructor-field-binding'],
    source: `import Base
type Tag is Data:
  C{value: Nat}
  D{value: Nat}
def score(tag: Tag, flag: Bool) -> Nat:
  match tag flag:
    case C{value} True{}:
      value
    case _ True{}:
      2n
    case C{value} _:
      Nat.add(value, 3n)
    case _ _:
      4n
def main() -> Nat:
  Nat.add(Nat.add(score(C{7n}, True{}), score(D{9n}, True{})), Nat.add(score(C{7n}, False{}), score(D{9n}, False{})))
`,
    expected: '23n',
  },
  {
    name: 'binding-affine-type-resource',
    features: ['affine-Lone-binder', 'Type-resource-consumption', 'single-use-field'],
    source: `import Base
type Resource is Type:
  Resource{value: Nat}
def consume(resource: Resource) -> Nat:
  match resource:
    case Resource{value}:
      value
def main() -> Nat:
  consume(Resource{17n})
`,
    expected: '17n',
  },
  {
    name: 'binding-affine-match-reconstruction',
    features: ['affine-Lone-binder', 'Type-resource-consumption', 'whole-scrutinee-reconstruction', 'exclusive-branch-consumption'],
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
def consume_packet(packet: Packet) -> Nat:
  match packet:
    case C{resource}:
      Nat.add(consume_resource(resource), 10n)
    case D{resource}:
      Nat.add(consume_resource(resource), 20n)
def score(packet: Packet, flag: Bool) -> Nat:
  match packet flag:
    case C{resource} True{}:
      consume_resource(resource)
    case whole _:
      consume_packet(whole)
def main() -> Nat:
  Nat.add(score(C{Resource{7n}}, True{}), Nat.add(score(C{Resource{7n}}, False{}), score(D{Resource{9n}}, True{})))
`,
    expected: '53n',
  },
  {
    name: 'binding-many-actually-duplicated',
    features: ['Many-binder', 'Data-duplication-license', 'two-live-uses'],
    source: `import Base
def twice(+value: Nat) -> Nat:
  Nat.add(value, value)
def main() -> Nat:
  twice(9n)
`,
    expected: '18n',
  },
  {
    name: 'binding-dependent-function-concrete-nat',
    features: ['dependent-type-binder', 'dependent-function-binder', 'erased-Type-parameter', 'concrete-Nat-instantiation', 'partial-application'],
    source: `import Base
def identity(-T: Type, value: T) -> T:
  value
def apply(-T: Type, function: @value: T -> T, value: T) -> T:
  function(value)
def main() -> Nat:
  apply(Nat, identity(Nat), 19n)
`,
    expected: '19n',
  },
  {
    name: 'binding-explicit-sub-shadow-capture',
    features: ['explicit-Sub', 'binder-ID-shadowing', 'same-name-binders', 'capture-sensitive-substitution', 'affine-Lone-binder'],
    source: `import Base
def capture(outer: Nat, inner: Nat) -> Nat:
  Nat.add(outer, inner)
def main() -> Nat:
  capture(5n, 12n)
`,
    expected: '17n',
    rawOverrides: {
      capture: kernel => {
        const variable = (id: number): LTerm => kernel.Var<[LTerm]>('same', id);
        const add = (left: LTerm, right: LTerm): LTerm =>
          kernel.App<[LTerm]>(kernel.App<[LTerm]>(kernel.Ref<[LTerm]>('Nat.add'), left), right);
        // The outer value is captured before the inner lambda reuses ID 11.
        // Sub 37 captures that inner value; both arguments remain single-use.
        // Exactly two lambdas match capture's declared two-argument telescope.
        return kernel.Lam<LTerm>('same', 11,
          kernel.Sub<[LTerm]>(23, variable(11),
            kernel.Lam<LTerm>('same', 11,
              kernel.Sub<[LTerm]>(37, variable(11), add(variable(23), variable(37))),
              undefined, kernel.Lone())),
          undefined, kernel.Lone());
      },
    },
  },
];
