import type {ReplayFixture} from './load_replay_fixture_types.ts';

export const fixtures: ReplayFixture[] = [
  {
    name: 'basic-plain-constant',
    features: ['plain-constant', 'Nat-literal'],
    source: `import Base
def main() -> Nat:
  17n
`,
    expected: '17n',
  },
  {
    name: 'basic-local-lambda',
    features: ['lambda', 'local-Let', 'annotated-function-value', 'application'],
    source: `import Base
def main() -> Nat:
  f = {x => Nat.add(x, 3n) : Nat -> Nat}
  f(14n)
`,
    expected: '17n',
  },
  {
    name: 'basic-nested-same-name-lambda',
    features: ['lambda', 'nested-lambda', 'same-name-shadowing', 'distinct-lexical-binder-IDs', 'curried-application'],
    // The two lexical x binders must remain distinct: 5n is discarded,
    // while the inner x is 17n. A name-based capture would return 5n.
    source: `import Base
def main() -> Nat:
  f = {x => x => x : Nat -> Nat -> Nat}
  f(5n, 17n)
`,
    expected: '17n',
  },
  {
    name: 'basic-higher-order-application',
    features: ['application', 'higher-order-argument', 'lambda', 'nested-application', 'earlier-definition-reference'],
    source: `import Base
def apply(f: Nat -> Nat, n: Nat) -> Nat:
  f(n)
def main() -> Nat:
  apply(x => Nat.add(x, 4n), Nat.add(6n, 7n))
`,
    expected: '17n',
  },
  {
    name: 'basic-local-let-chain',
    features: ['local-Let', 'dependent-local-bindings', 'application'],
    source: `import Base
def main() -> Nat:
  first = Nat.add(2n, 3n)
  second = Nat.mul(first, 3n)
  Nat.add(second, 2n)
`,
    expected: '17n',
  },
  {
    name: 'basic-terminating-recursion',
    features: ['recursive-definition', 'terminating-Nat-descent', 'Nat-pattern-match', 'self-reference'],
    source: `import Base
def count(n: Nat) -> Nat:
  match n:
    case 0n:
      2n
    case 1n+p:
      Nat.add(3n, count(p))
def main() -> Nat:
  count(5n)
`,
    expected: '17n',
  },
  {
    name: 'basic-earlier-definition-chain',
    features: ['earlier-definition-reference', 'multiple-definitions', 'reference-chain'],
    source: `import Base
def seed() -> Nat:
  5n
def offset(n: Nat) -> Nat:
  Nat.add(seed(), n)
def result() -> Nat:
  offset(12n)
def main() -> Nat:
  result()
`,
    expected: '17n',
  },
];
