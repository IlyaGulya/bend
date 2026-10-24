import Base

type Choice is Data:
  Empty{}
  Value{n: Nat}

def increment(n: Nat) -> Nat:
  Nat.add(n, 1n)

def apply(f: Nat -> Nat, n: Nat) -> Nat:
  f(n)

def choose(choice: Choice) -> Nat:
  match choice:
    case Empty{}:
      0n
    case Value{n}:
      apply(increment, n)

law main:
  Nat

def main():
  choose(Value{41n})

#|42n
