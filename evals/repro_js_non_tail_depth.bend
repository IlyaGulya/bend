import Base

# Diagnostic resource-boundary witness, not a full compiler acceptance fixture.
# The recursive result is consumed by addition, so the call is not a tail call.
def depth(n: Nat) -> Nat:
  match n:
    case 0n: 0n
    case 1n+rest: Nat.add(depth(rest), 1n)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(Nat.show(depth(12000n)))
    IO.pure(Unit, Unit{})

#|12000
