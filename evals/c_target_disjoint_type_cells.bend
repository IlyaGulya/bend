# C target fixture: two sibling array halves hold heap closures that capture
# their own k. Consuming the left half's Type cell must not copy the right
# half's Type cell, and each captured closure is applied exactly once.
import Base

def mk(n: U32) -> (U32 -> U32):
  x => (U32.add(x, n) : U32)

law sumf:
  for a: Array<(U32 -> U32)>
  U32

def sumf(a):
  match a:
    case ALeaf{f}:
      f(1)
    case ANode{xs, ys}:
      (sumf(xs) + sumf(ys) : U32)

def main() -> IO(Unit):
  IO.print(U32.show(sumf(ANode{ALeaf{mk(1)}, ALeaf{mk(2)}})))

#|5
