# Many parameter, field and whole-pattern quantities permit real contraction.
import Base

type Tag is Data:
  C{value: Nat}
  D{value: Nat}

def copied_value(+tag: Tag) -> Nat:
  match tag:
    case C{+value}:
      Nat.add(value, value)
    case D{+value}:
      Nat.add(value, value)

def matrix(+tag: Tag, flag: Bool) -> Nat:
  match tag flag:
    case C{+value} True{}:
      Nat.add(value, value)
    case +whole _:
      Nat.add(copied_value(whole), copied_value(whole))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(Nat.show(matrix(C{7n}, True{})))
    Unit <- IO.print(Nat.show(matrix(C{7n}, False{})))
    Unit <- IO.print(Nat.show(matrix(D{9n}, True{})))
    IO.print(Nat.show(matrix(D{9n}, False{})))

#|14
#|28
#|36
#|36
