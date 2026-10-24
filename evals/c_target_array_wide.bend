# C target fixture: wide array cells, so nothing may assume a one-word cell.
# Each cell is a four-field record; the array is cloned (its wide elements must
# be retained), one element is read back and projected, and both lengths are
# reported. Expected 14 (fields 4+2+2+6 for index 0) plus two singleton sizes.
import Base

type Cell is Data:
  Cell{a: U32, b: U32, c: U32, d: U32}

def weigh(c: Cell) -> U32:
  match c:
    case Cell{a, b, c2, d}: U32.add(a, U32.add(b, U32.add(c2, d)))

def cell_of(pair: Array<Cell> & Cell) -> Cell:
  (arr, v) = pair
  v

def length_of(pair: Array<Cell> & U32) -> U32:
  (arr, n) = pair
  n

def both_sizes(pair: Array<Cell> & Array<Cell>) -> U32:
  (a, b) = pair
  U32.add(length_of(Array.size(Cell, a)), length_of(Array.size(Cell, b)))

def after_get(pair: Array<Cell> & Cell) -> U32:
  (arr, cell) = pair
  U32.add(weigh(cell), both_sizes(Array.clone(Cell, arr)))

def main() -> IO(Unit):
  a = Array.new(Cell, 0n, Cell{3, 1, 0, 5})
  b = Array.set(Cell, a, 0, Cell{4, 2, 2, 6})
  IO.print(U32.show(after_get(Array.get(Cell, b, 0))))

#|16
