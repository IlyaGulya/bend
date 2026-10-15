/** Small native scanner programs with the original seven-argument call order. */
export type ScannerCursorFixture = Readonly<{
  name: string;
  source: string;
  row: readonly number[];
  inputs: readonly (readonly [expression: string, expected: number])[];
}>;

const prelude = `import Base
def pattern_scan(tokens: List<&2, Nat>, file: Nat, mode: Nat, frames: Nat, scope: Nat, depth: Nat, goal: Nat) -> Nat:
  Nat.add(List.length(&2, Nat, tokens), Nat.add(file, Nat.add(mode, Nat.add(frames, Nat.add(scope, Nat.add(depth, goal))))))
`;
const resource = `type Resource is Type:
  Resource{value: Nat}
def consume(resource: Resource) -> Nat:
  match resource:
    case Resource{value}:
      value
`;

export const scannerCursorFixtures: readonly ScannerCursorFixture[] = [
  {
    name: 'rest-only cursor',
    source: `${prelude}def example(tokens: List<&2, Nat>, +file: Nat) -> Nat:
  match tokens:
    case _ <> rest:
      pattern_scan(rest, file, 2n, 3n, 4n, 5n, 6n)
    case Nil{}:
      0n
`,
    row: [0],
    inputs: [['example([9n, 8n, 7n], 1n)', 23], ['example([9n, 8n], 10n)', 31]],
  },
  {
    name: 'open-only cursor',
    source: `${prelude}def example(tokens: List<&2, Nat>, +file: Nat) -> Nat:
  match tokens:
    case _ <> rest:
      match rest:
        case _ <> after_open:
          pattern_scan(after_open, file, 6n, 5n, 4n, 3n, 2n)
        case Nil{}:
          0n
    case Nil{}:
      0n
`,
    row: [0, 0],
    inputs: [['example([9n, 8n, 7n, 6n], 1n)', 23], ['example([9n, 8n], 10n)', 30]],
  },
  {
    name: 'exclusive branches use different cursors',
    source: `${prelude}def example(tokens: List<&2, Nat>, +file: Nat, flag: Bool) -> Nat:
  match tokens:
    case _ <> +rest:
      match rest:
        case _ <> after_open:
          match flag:
            case True{}:
              pattern_scan(rest, file, 1n, 2n, 3n, 4n, 5n)
            case False{}:
              pattern_scan(after_open, file, 5n, 4n, 3n, 2n, 1n)
        case Nil{}:
          0n
    case Nil{}:
      0n
`,
    row: [0, 0],
    inputs: [
      ['example([9n, 8n, 7n, 6n], 10n, True{})', 28],
      ['example([9n, 8n, 7n, 6n], 10n, False{})', 27],
      ['example([9n, 8n], 1n, True{})', 17],
      ['example([9n, 8n], 1n, False{})', 16],
    ],
  },
  {
    name: 'Nil cursor retains all call-time arguments',
    source: `${prelude}def example(tokens: List<&2, Nat>, +file: Nat, mode: Nat, frames: Nat, scope: Nat, depth: Nat, goal: Nat) -> Nat:
  match tokens:
    case _ <> rest:
      pattern_scan(rest, file, mode, frames, scope, depth, goal)
    case Nil{}:
      0n
`,
    row: [0],
    inputs: [['example([9n], 1n, 2n, 3n, 4n, 5n, 6n)', 21], ['example([8n], 10n, 1n, 2n, 4n, 8n, 16n)', 41]],
  },
  {
    name: 'nested rest and after_open ownership',
    source: `${prelude}def example(tokens: List<&2, Nat>, +file: Nat, flag: Bool) -> Nat:
  match tokens:
    case _ <> +rest:
      match rest:
        case _ <> after_open:
          match flag:
            case True{}:
              pattern_scan(rest, file, 2n, 3n, 4n, 5n, 6n)
            case False{}:
              pattern_scan(after_open, file, 7n, 8n, 9n, 10n, 11n)
        case Nil{}:
          match flag:
            case True{}:
              pattern_scan(rest, file, 2n, 3n, 4n, 5n, 6n)
            case False{}:
              99n
    case Nil{}:
      0n
`,
    row: [0],
    inputs: [
      ['example([9n, 8n, 7n, 6n], 1n, True{})', 24],
      ['example([9n, 8n, 7n, 6n], 1n, False{})', 48],
      ['example([9n], 1n, False{})', 99],
    ],
  },
  {
    name: 'affine surrounding capture is single-use',
    source: `${prelude}${resource}def example(tokens: List<&2, Nat>, +file: Nat, resource: Resource) -> Nat:
  match tokens:
    case _ <> rest:
      Nat.add(pattern_scan(rest, file, 2n, 3n, 4n, 5n, 6n), consume(resource))
    case Nil{}:
      consume(resource)
`,
    row: [0],
    inputs: [['example([9n, 8n, 7n], 1n, Resource{13n})', 36], ['example([9n], 1n, Resource{21n})', 42]],
  },
  {
    name: 'Many surrounding capture is reused',
    source: `${prelude}def example(tokens: List<&2, Nat>, +file: Nat, +seed: Nat) -> Nat:
  match tokens:
    case _ <> rest:
      Nat.add(pattern_scan(rest, file, 2n, 3n, 4n, 5n, 6n), Nat.add(seed, seed))
    case Nil{}:
      Nat.add(seed, seed)
`,
    row: [0],
    inputs: [['example([9n, 8n, 7n], 1n, 8n)', 39], ['example([9n], 1n, 3n)', 27]],
  },
];

/** Factoring must not turn affine contraction into valid native ownership. */
export const invalidAffineScannerCursor: ScannerCursorFixture = {
  name: 'invalid affine surrounding contraction',
  source: `${prelude}${resource}def example(tokens: List<&2, Nat>, +file: Nat, resource: Resource) -> Nat:
  match tokens:
    case _ <> rest:
      Nat.add(pattern_scan(rest, file, 2n, 3n, 4n, 5n, 6n), Nat.add(consume(resource), consume(resource)))
    case Nil{}:
      consume(resource)
`,
  row: [0],
  inputs: [],
};
