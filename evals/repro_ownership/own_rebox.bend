# Minimal whole-parent rebuild witness (#970 reduced): rebox matches a Cons,
# projects its Many head and affine tail, and rebuilds value <> tail. The
# element type is &2 (Many), so the rebuilt node seals its head; the sum's
# Scalar is a packed one-word node and Pair is a two-word heap node. No
# caller residual use, no closure. The only observation is the same foreign
# frontier invariant as own_cons, unchanged.
import Base

type Value is Data:
  Scalar{number: U32}
  Pair{left: Nat, right: Nat}

def wrap(n: Nat) -> Value:
  match n:
    case 0n:
      Scalar{7}
    case 1n+p:
      Pair{p, 4n}

def rebox(values: List<&2, Value>) -> List<&2, Value>:
  match values:
    case Nil{}:
      Nil{}
    case value <> tail:
      value <> tail

def head_u32(values: List<&2, Value>) -> U32:
  match values:
    case Nil{}:
      0
    case value <> tail:
      match value:
        case Scalar{+n}:
          n
        case Pair{left, right}:
          0

def cycle(n: Nat, +seed: Nat, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+more:
      cycle(more, seed, U32.add(acc, head_u32(rebox(wrap(seed) <> Nil{}))))

def heap.check(value: U32, expected: U32, before: U32) -> IO(U32):
  import "./own_rebox.c"
  import "./own_rebox.js"

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(head_u32(rebox(wrap(0n) <> Nil{}))))
    +before : U32 <- heap.check(cycle(1000n, 0n, 0), 7000, 0)
    Unit <- IO.print(U32.show(before))
    after : U32 <- heap.check(cycle(20000n, 0n, 0), 140000, before)
    Unit <- IO.print(U32.show(after))
    IO.print("bounded")
