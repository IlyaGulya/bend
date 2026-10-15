import Base

def descend(n: Nat, value: U32) -> U32:
  match n:
    case 0n: value
    case 1n+rest: descend(rest, U32.add(value, 1))

def invoke(f: U32 -> U32, value: U32) -> U32:
  f(value)

def main() -> U32:
  invoke(value => descend(200000n, value), 7)

#|200007
