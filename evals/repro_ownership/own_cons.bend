# Minimal retained-ownership witness (#970 reduced): one heap constructor,
# built fresh, consumed exactly once by a match that returns one field, in a
# tail-recursive loop. No sum, no Many field, no closure, no caller residual
# use: the shape is valid affine input. If the match releases the consumed
# node, the arena frontier stays bounded; if it only projects, one class-1
# cell (2 words) becomes unreachable per iteration.
#
# heap.check is the same foreign invariant as tests/run/list_rebox_sum.c: it
# compares the runtime H_BUMP frontier, in 1 KiB pages, against
# before + (QUANTUM >> PAGE_BITS). The threshold and frees are unchanged.
import Base

type Box is Data:
  Box{one: U32, two: U32}

def mk(+n: U32) -> Box:
  Box{n, n}

def take(b: Box) -> U32:
  match b:
    case Box{one, two}:
      one

def cycle(n: Nat, +seed: U32, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+more:
      cycle(more, seed, U32.add(acc, take(mk(seed))))

def heap.check(value: U32, expected: U32, before: U32) -> IO(U32):
  import "./own_cons.c"
  import "./own_cons.js"

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(take(mk(3))))
    +before : U32 <- heap.check(cycle(1000n, 3, 0), 3000, 0)
    Unit <- IO.print(U32.show(before))
    after : U32 <- heap.check(cycle(20000n, 3, 0), 60000, before)
    Unit <- IO.print(U32.show(after))
    IO.print("bounded")
