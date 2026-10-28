# C target fixture: nested cell type (Maybe of a wide record) in an array.
# The cell descriptor is the full applied family, not a suffix guess.
# Expected 12 from Some value 12 at index 0.
import Base

type Cell is Data:
  Cell{a: U32, b: U32}

def element(pair: Array<Maybe<&2, Cell>> & Maybe<&2, Cell>) -> Maybe<&2, Cell>:
  (a, v) = pair
  v

def value(v: Maybe<&2, Cell>) -> U32:
  match v:
    case Some{Cell{a, b}}:
      U32.add(a, b)
    case None{}:
      0

def main() -> IO(Unit):
  a = Array.new(Maybe<&2, Cell>, 1n, None{})
  b = Array.set(Maybe<&2, Cell>, a, 0, Some{Cell{5, 7}})
  IO.print(U32.show(value(element(Array.get(Maybe<&2, Cell>, b, 0)))))

#|12
