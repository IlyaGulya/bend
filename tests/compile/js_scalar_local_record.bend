# Records cross internal calls before their fields are consumed. Covers
# constructor-field order, nested fields, a call between construction and use,
# a returned record, and a copied name whose field is read twice.
import Base

type ScalarPair is Data:
  ScalarPair{fst: U32, snd: U32}

type Cell is Data:
  Cell{value: U32}

type Holder is Data:
  Holder{head: U32, cell: Cell}

def sum_pair(value: ScalarPair) -> U32:
  match value:
    case ScalarPair{a, b}: U32.add(a, b)

def sum_holder(value: Holder) -> U32:
  match value:
    case Holder{a, Cell{v}}: U32.add(a, v)

def sum_reused_pair(value: ScalarPair) -> U32:
  match value:
    case ScalarPair{a, +b}: U32.add(U32.add(a, b), b)

def local_pair(+x: U32) -> U32:
  sum_pair(ScalarPair{x, U32.add(x, 1)})

def nested(+x: U32) -> U32:
  sum_holder(Holder{x, Cell{U32.add(x, 2)}})

def escaped(+x: U32) -> ScalarPair:
  ScalarPair{x, U32.mul(x, 3)}

def twice(l: U32, r: U32) -> U32:
  U32.add(U32.mul(l, 2), r)

def after_call(+x: U32) -> U32:
  p = {Holder{x, Cell{U32.add(x, 2)}} : Holder}
  y = twice(x, U32.add(x, 1))
  U32.add(sum_holder(p), y)

def via_call(x: U32) -> U32:
  sum_pair(escaped(x))

def aliased(+x: U32) -> U32:
  p = {ScalarPair{x, U32.mul(x, 4)} : ScalarPair}
  q = p
  sum_reused_pair(q)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(local_pair(3)))
    IO.print(U32.show(nested(3)))
    IO.print(U32.show(via_call(4)))
    IO.print(U32.show(aliased(3)))
    IO.print(U32.show(after_call(3)))

#|7
#|8
#|16
#|27
#|18
