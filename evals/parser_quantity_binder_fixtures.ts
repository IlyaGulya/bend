export type QuantityBinderFixture = {
  name: string;
  source: string;
  // Language contract only: the construct and its checked quantity.
  // Observed parser behavior is recorded separately by the differential driver.
  expected: {
    construct: 'body-local-plus' | 'body-local-typed' | 'do-plus-bind' | 'do-typed-bind' | 'control-untyped';
    quantity: 'QMany' | 'QOne' | 'None';
  };
};

// Minimal real sources for the quantity-binder parser difference. Every source
// is one unchanged declaration; no import, corpus module or textual assertion
// is involved. Stage0 and canonical 7389188a accept the annotated local and do
// forms below. The unquantified control uses the same two body shapes without
// an annotation so a general body/do parse failure is distinguishable from the
// annotated (and "+") forms.
export const quantityBinderFixtures: QuantityBinderFixture[] = [
  {
    name: 'plus-body-local',
    source: 'def f(x: Nat) -> Nat:\n  +l : Nat = x\n  l\n',
    expected: {construct: 'body-local-plus', quantity: 'QMany'},
  },
  {
    name: 'typed-body-local',
    source: 'def f(x: Nat) -> Nat:\n  l : Nat = x\n  l\n',
    expected: {construct: 'body-local-typed', quantity: 'QOne'},
  },
  {
    name: 'plus-do-bind',
    source: 'def f(x: Nat) -> Nat:\n  do M<>: +y : Nat <- x; return y\n',
    expected: {construct: 'do-plus-bind', quantity: 'QMany'},
  },
  {
    name: 'typed-do-bind',
    source: 'def f(x: Nat) -> Nat:\n  do M<>: y : Nat <- x; return y\n',
    expected: {construct: 'do-typed-bind', quantity: 'None'},
  },
  {
    name: 'untyped-control',
    source: 'def f(x: Nat) -> Nat:\n  l = x\n  do M<>: y <- x; return y\n',
    expected: {construct: 'control-untyped', quantity: 'QOne'},
  },
];
