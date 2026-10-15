import Base

def app(~f: Nat -> Nat, x: Nat) -> Nat:
  f(x)

def increment(x: Nat) -> Nat:
  Nat.add(x, 1n)

law main:
  Nat

def main() -> Nat:
  app(~increment, 41n)

#| 42
