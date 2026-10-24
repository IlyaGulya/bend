# C target fixture: wide array cells, so nothing may assume a one-word cell.
#
# Each cell is a four-field record built from the cell index; the array is
# cloned (its wide elements must be retained), one element is read back and
# projected, and both lengths are reported. Expected: 14 (fields 4+2+2+6 for index 1)
# plus two singleton sizes = 16.
import Base

type Cell is Data:
  Cell{a: U32, b: U32, c: U32, d: U32}

def make(i: U32) -> Cell:
  Cell{U32.add(i, 3), U32.add(i, 1), U32.mul(i, 2), U32.add(i, 5)}

def weigh(c: Cell) -> U32:
  match c:
    case Cell{a, b, c2, d}: U32.add(a, U32.add(b, U32.add(c2, d)))

def main() -> IO(Unit):
  a = Array.new(Cell, 0n, make(0))
  b = Array.set(Cell, a, 0, make(1))
  (c, e) = Array.get(Cell, b, 0)
  (d, copy) = Array.clone(Cell, c)
  (f, n) = Array.size(Cell, d)
  (g, m) = Array.size(Cell, copy)
  IO.print(U32.show(U32.add(weigh(e), U32.add(n, m))))

#|16
