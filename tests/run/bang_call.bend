import Base

law main:
  Nat

def increment(x: Nat) -> Nat:
  Nat.add(x, 1n)

def main():
  Nat.add(increment!(41n), 1n)

#|43n
