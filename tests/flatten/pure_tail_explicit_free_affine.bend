# An affine free Type value transfers exclusively to prefix or residual.
import Base

type Resource is Type:
  Resource{value: Nat}
type Tag is Data:
  C{}
  D{}

def consume(resource: Resource) -> Nat:
  match resource:
    case Resource{value}: value

def matrix(resource: Resource, tag: Tag, flag: Bool) -> Nat:
  match tag flag:
    case C{} True{}: consume(resource)
    case _ _: Nat.add(consume(resource), 10n)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(Nat.show(matrix(Resource{7n}, C{}, True{})))
    Unit <- IO.print(Nat.show(matrix(Resource{7n}, C{}, False{})))
    Unit <- IO.print(Nat.show(matrix(Resource{9n}, D{}, True{})))
    IO.print(Nat.show(matrix(Resource{9n}, D{}, False{})))

#|7
#|17
#|19
#|19
