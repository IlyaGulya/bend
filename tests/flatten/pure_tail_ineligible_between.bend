# A wildcard between C and D must continue to shadow the D row.
import Base

type Tag is Data:
  C{}
  D{}
  E{}

def matrix(tag: Tag) -> Nat:
  match tag:
    case C{}:
      10n
    case _:
      20n
    case D{}:
      30n
    case _:
      40n

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(Nat.show(matrix(C{})))
    Unit <- IO.print(Nat.show(matrix(D{})))
    IO.print(Nat.show(matrix(E{})))

#|10
#|20
#|20
