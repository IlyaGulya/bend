# The residual begins after C, D and E; a failed suffix row tries the next.
import Base

type Tag is Data:
  C{value: Nat}
  D{value: Nat}
  E{value: Nat}
type Choice is Data:
  X{}
  Y{}
  P{}
  Q{}

def matrix(tag: Tag, choice: Choice, later: Bool) -> Nat:
  match tag choice later:
    case C{value} X{} True{}:
      value
    case D{value} Y{} True{}:
      Nat.add(value, 10n)
    case E{value} X{} True{}:
      Nat.add(value, 20n)
    case _ P{} True{}:
      30n
    case _ P{} False{}:
      31n
    case _ _ _:
      40n

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(Nat.show(matrix(C{7n}, X{}, True{})))
    Unit <- IO.print(Nat.show(matrix(D{9n}, Y{}, True{})))
    Unit <- IO.print(Nat.show(matrix(E{11n}, X{}, True{})))
    Unit <- IO.print(Nat.show(matrix(C{7n}, X{}, False{})))
    Unit <- IO.print(Nat.show(matrix(D{9n}, Y{}, False{})))
    Unit <- IO.print(Nat.show(matrix(E{11n}, X{}, False{})))
    Unit <- IO.print(Nat.show(matrix(C{7n}, P{}, True{})))
    Unit <- IO.print(Nat.show(matrix(C{7n}, P{}, False{})))
    Unit <- IO.print(Nat.show(matrix(D{9n}, P{}, False{})))
    Unit <- IO.print(Nat.show(matrix(E{11n}, P{}, False{})))
    IO.print(Nat.show(matrix(E{11n}, Q{}, True{})))

#|7
#|19
#|31
#|40
#|40
#|40
#|30
#|31
#|31
#|31
#|40
