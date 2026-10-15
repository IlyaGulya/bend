export type LocalFixture = {name: string; source: string};

// Full-module public parser regressions; no constructor-name special cases.
export const localFixtures: LocalFixture[] = [
  {name:'one-binder-one-rhs',source:'def f(x: Nat) -> Nat:\n  l = x\n  l\n'},
  {name:'two-binders-two-rhs',source:'def f(x: Nat, y: Nat) -> Nat & Nat:\n  l r = x y\n  (l, r)\n'},
  {name:'two-binders-applications',source:'def f(g: Nat -> Nat, x: Nat, y: Nat) -> Nat & Nat:\n  l r = g(x) g(y)\n  (l, r)\n'},
  {name:'nested-implicit-applications',source:'def f(g: Nat -> Nat, a: Array<Nat>, b: Array<Nat>) -> Array<Nat> & Array<Nat>:\n  l r = Array.map(~Nat, ~Nat, ~g, Array.map(~Nat, ~Nat, ~g, a)) Array.map(~Nat, ~Nat, ~g, Array.map(~Nat, ~Nat, ~g, b))\n  (l, r)\n'},
  {name:'following-constructor-match-case',source:'def f(a: Array<Nat>) -> Array<Nat>:\n  match a:\n    case ANode{xs, ys}:\n      l r = xs ys\n      ANode{l, r}\n    case ALeaf{x}:\n      ALeaf{x}\n'},
  {name:'base-array-map',source:'def f(g: Nat -> Nat, a: Array<Nat>) -> Array<Nat>:\n  match a:\n    case ALeaf{x}:\n      ALeaf{g(x)}\n    case ANode{xs, ys}:\n      l r = Array.map(~Nat, ~Nat, ~g, xs) Array.map(~Nat, ~Nat, ~g, ys)\n      ANode{l, r}\n'},
  {name:'multiline-right-hand-sides',source:'def f(+g: Nat -> Nat, +x: Nat) -> Nat & Nat & Nat & Nat:\n  a b c d = g(x) g(x) g(x)\n    g(x)\n  (a, b, c, d)\n'},
];

// Newly reachable read-only declaration observation: templates and Base binders.
// The unchanged native parser owns specialization; no template is expanded here.
export const templateObservationFixtures: LocalFixture[] = [
  {name:'template-static-instance-and-erased-parameter',source:'def identity(~T: Type, -n: Nat, x: T) -> T:\n  x\ndef f() -> Nat:\n  identity(~Nat, 0n, 7n)\n'},
  {name:'template-captured-argument',source:'def identity(~T: Type, x: T) -> T:\n  x\ndef f(-T: Type, x: T) -> T:\n  identity(~T, x)\n'},
  {name:'template-two-static-arguments',source:'def apply(~T: Type, ~g: T -> T, x: T) -> T:\n  g(x)\ndef f() -> Nat:\n  apply(~Nat, ~Nat.double, 7n)\n'},
  {name:'dependent-law-clause-types',source:'law f:\n  for -A: Type\n  for x: A\n  A\n'},
  {name:'dependent-arrow-default-quantity',source:'def dependent(-A: Type) -> Type:\n  @-R: Type ->\n  @k: (A -> R) ->\n  R\n'},
  {name:'dependent-arrow-explicit-quantities',source:'def quantities(-A: Type) -> Type:\n  @x: A ->\n  @+y: A ->\n  @-z: A ->\n  A\n'},
  {name:'rewrite-captured-underscore',source:'def rewrite(-A: Type, -a: A, -b: A, e: {a == b : A}) -> {b == a : A}:\n  %e : {_ == a : A}\n  {==}\n'},
  {name:'rewrite-equation-binder-shadow-and-restore',source:'law Rewrite.scope:\n  for -A: Type\n  for -a: A\n  for -b: A\n  for e: {a == b : A}\n  {e == e : {a == b : A}}\ndef Rewrite.scope(A,a,b,e):\n  %e@e : {e == e : {a == _ : A}}\n  {==}\n'},
];
