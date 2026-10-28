# js backend: a record built and taken apart inside one body is a binding, not a
# value. Every projection reads a field the frame already holds, so the
# allocation is gone and the field values, their order and their reads are the
# ones the constructor evaluated. A record copied under a second name is an
# alias, so it stays one value; a record a def returns crosses a call and its
# caller takes it apart boxed. A record nested in another record's field pins
# the projection of a field of a field.
import Base

type Pair is Data:
  Pair{fst: U32, snd: U32}

type Cell is Data:
  Cell{value: U32}

type Holder is Data:
  Holder{head: U32, cell: Cell}

def local_pair(x: U32) -> U32:
  p = Pair{x, U32.add(x, 1)}
  Pair{a, b} = p
  U32.add(a, b)

def nested(x: U32) -> U32:
  p = Holder{x, Cell{U32.add(x, 2)}}
  Holder{a, c} = p
  Cell{v} = c
  U32.add(a, v)

def escaped(x: U32) -> Pair:
  Pair{x, U32.mul(x, 3)}

def twice(l: U32, r: U32) -> U32:
  U32.add(U32.mul(l, 2), r)

def after_call(x: U32) -> U32:
  p = Holder{x, Cell{U32.add(x, 2)}}
  y = twice(x, U32.add(x, 1))
  Holder{a, c} = p
  Cell{v} = c
  U32.add(U32.add(a, v), y)

def via_call(x: U32) -> U32:
  Pair{a, b} = escaped(x)
  U32.add(a, b)

def aliased(x: U32) -> U32:
  p = Pair{x, U32.mul(x, 4)}
  q = p
  Pair{a, b} = q
  U32.add(U32.add(a, b), b)

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
