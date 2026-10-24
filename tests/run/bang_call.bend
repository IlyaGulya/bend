import Base

def increment(x: Nat) -> Nat:
  Nat.add(x, 1n)

def main() -> Nat:
  Nat.add(increment!(41n), 1n)

#|43n
