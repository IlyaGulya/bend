# A stable Many offset remains in lexical scope while recursion decreases on
# the suffix List tail; sharing must not shift the native self-call LHS.
import Base

type Tag is Data:
  C{}
  D{}

def matrix(+offset: Nat, tag: Tag, items: List<&2, Nat>) -> Nat:
  match tag items:
    case C{} Nil{}: offset
    case whole Con{head, tail}: Nat.add(head, matrix(offset, whole, tail))
    case _ Nil{}: offset

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(Nat.show(matrix(10n, C{}, Nil{})))
    Unit <- IO.print(Nat.show(matrix(10n, D{}, Nil{})))
    Unit <- IO.print(Nat.show(matrix(10n, C{}, Con{2n, Con{3n, Nil{}}})))
    IO.print(Nat.show(matrix(10n, D{}, Con{2n, Con{3n, Nil{}}})))

#|10
#|10
#|15
#|15
