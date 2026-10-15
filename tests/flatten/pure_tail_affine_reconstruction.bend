# A genuine Type resource is consumed once: prefix success consumes its field,
# later Bool failure reconstructs the whole Packet for the residual.
import Base

type Resource is Type:
  Resource{value: Nat}
type Packet is Type:
  C{resource: Resource}
  D{resource: Resource}
  E{resource: Resource}

def consume_resource(resource: Resource) -> Nat:
  match resource:
    case Resource{value}:
      value

def consume(packet: Packet) -> Nat:
  match packet:
    case C{resource}:
      Nat.add(consume_resource(resource), 10n)
    case D{resource}:
      Nat.add(consume_resource(resource), 20n)
    case E{resource}:
      Nat.add(consume_resource(resource), 30n)

def matrix(packet: Packet, flag: Bool) -> Nat:
  match packet flag:
    case C{resource} True{}:
      consume_resource(resource)
    case whole _:
      consume(whole)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(Nat.show(matrix(C{Resource{7n}}, True{})))
    Unit <- IO.print(Nat.show(matrix(C{Resource{7n}}, False{})))
    Unit <- IO.print(Nat.show(matrix(D{Resource{9n}}, True{})))
    Unit <- IO.print(Nat.show(matrix(D{Resource{9n}}, False{})))
    Unit <- IO.print(Nat.show(matrix(E{Resource{11n}}, True{})))
    IO.print(Nat.show(matrix(E{Resource{11n}}, False{})))

#|7
#|17
#|29
#|29
#|41
#|41
