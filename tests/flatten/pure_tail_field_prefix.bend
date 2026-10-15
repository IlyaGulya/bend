# Constructor fields survive prefix successes and later-column failure.
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

def matrix(tag: Tag, choice: Choice) -> Nat:
  match tag choice:
    case C{value} X{}:
      value
    case C{value} Y{}:
      Nat.add(value, 1n)
    case _ P{}:
      30n
    case _ Q{}:
      40n
    case _ _:
      50n

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(Nat.show(matrix(C{7n}, X{})))
    Unit <- IO.print(Nat.show(matrix(C{7n}, Y{})))
    Unit <- IO.print(Nat.show(matrix(C{7n}, P{})))
    Unit <- IO.print(Nat.show(matrix(C{7n}, Q{})))
    Unit <- IO.print(Nat.show(matrix(D{9n}, X{})))
    Unit <- IO.print(Nat.show(matrix(D{9n}, Y{})))
    Unit <- IO.print(Nat.show(matrix(D{9n}, P{})))
    IO.print(Nat.show(matrix(E{11n}, Q{})))

#|7
#|8
#|30
#|40
#|50
#|50
#|30
#|40
