# regression witness: a generic constructor's field domains are its telescope
# applied at the node's own type arguments, kept in source order, and a value two
# fields share is owned once after the last field reads it. The C producer
# interns literal nodes, then closes its borrow and reachability graphs over the
# pass facts; none of that may change what the native or the JS lane prints.
import Base

type Pr<-A: Data> is Data:
  Pr{head: A, tail: A}

type Row is Data:
  Row{name: String, values: List<&2, U32>, pair: Pr<U32>}

def total(values: List<&2, U32>) -> U32:
  match values:
    case Nil{}:
      0
    case h <> t:
      U32.add(h, total(t))

def shared(row: Row, +seen: U32) -> U32:
  match row:
    case Row{name, values, pair}:
      match pair:
        case Pr{head, tail}:
          U32.add(seen, U32.add(total(values), U32.add(head, tail)))

def rows() -> List<&2, Row>:
  [Row{"a", [1, 2, 3], Pr{4, 5}},
   Row{"b", [6], Pr{7, 8}}]

def run(list: List<&2, Row>) -> IO(Unit):
  match list:
    case Nil{}:
      IO.print("none")
    case h <> t:
      match t:
        case Nil{}:
          IO.print(U32.show(shared(h, 0)))
        case g <> u:
          do IO<Unit>:
            Unit <- IO.print(U32.show(shared(h, 0)))
            IO.print(U32.show(shared(g, 0)))

def main() -> IO(Unit):
  run(rows())

#|15
#|21
