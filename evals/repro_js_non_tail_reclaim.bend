import Base

# Witness for the JavaScript machine's continuation capture slots.
#
# One iteration here is the shape the compiler itself runs while it parses: an
# outer non-tail call, whose continuation makes a second non-tail call, whose
# continuation tail-calls the loop again (`feedback_drive`). Every split stores
# its continuation's captures on the shared capture stack, and the machine
# resumes a call continuation by rebinding exactly those slots. A machine that
# instead resumes at the end of the popped frame's slots keeps them allocated
# forever, so each iteration leaks both splits' captures (frozen parameters and
# the halves of the old frame), and a long run exhausts the engine's dense
# array ceiling: it dies with "Invalid array length" at the capture store
# instead of printing the checksum. The loop is linear and bounded, so a
# correct machine runs it in constant capture-stack space.
#
# Deep non-tail recursion still holds O(depth) slots by design: every pending
# frame must keep its own captures. This witness is about release, not depth.
def bump_one(x: Nat) -> Nat:
  Nat.add(x, 1n)

def bump_two(x: Nat) -> Nat:
  Nat.add(x, 2n)

def spin(+n: Nat, a: Nat, b: Nat, c: Nat, d: Nat, e: Nat, f: Nat, g: Nat, h: Nat, i: Nat, j: Nat, k: Nat, l: Nat) -> Nat:
  match n:
    case 0n:
      Nat.add(a, l)
    case 1n+rest:
      +x = bump_one(n)
      y = bump_two(x)
      spin(rest, Nat.add(a, Nat.min(1n, x)), b, c, d, e, f, g, h, i, j, k, Nat.add(l, Nat.min(1n, y)))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(Nat.show(spin(12000000n, 0n, 1n, 2n, 3n, 4n, 5n, 6n, 7n, 8n, 9n, 10n, 11n)))
    IO.pure(Unit, Unit{})

#|24000011
