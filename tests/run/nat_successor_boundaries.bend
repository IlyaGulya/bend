# Literal successor folding must agree with dynamic successors across the
# parser's short-chain and U32 boundaries; neither path wraps a Nat to U32.
import Base

def successor(n: Nat) -> Nat:
  Succ{n}

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Nat.show(Succ{0n}))
    IO.print(Nat.show(Succ{32n}))
    IO.print(Nat.show(Succ{255n}))
    IO.print(Nat.show(Succ{256n}))
    IO.print(Nat.show(Succ{4294967295n}))
    IO.print(Nat.show(successor(Nat.add(4294967295n, 1n))))

#|1
#|33
#|256
#|257
#|4294967296
#|4294967297
