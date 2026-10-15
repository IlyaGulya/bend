# A wildcard before a constructor keeps first-row-wins legacy behavior.
import Base

type Tag is Data:
  C{}
  D{}

def matrix(tag: Tag) -> Nat:
  match tag:
    case _:
      10n
    case C{}:
      20n
    case _:
      30n

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(Nat.show(matrix(C{})))
    IO.print(Nat.show(matrix(D{})))

#|10
#|10
