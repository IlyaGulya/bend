# Private record results keep owned children live across another call, then
# transfer them to a separate consumer. A stored second result must not replace
# the first one's components; F32 negative zero must retain its bits.
import Base

type Packet is Type:
  Packet{items: Array<U32>, text: String, bits: F32}

def from_word(value: U32) -> F32:
  match value:
    case U32{word}: F32{word}

def make(value: U32) -> Packet:
  Packet{Array.new(U32, 3n, value), "hold", from_word(2147483648)}

def make_alt(value: U32) -> Packet:
  Packet{Array.new(U32, 3n, value), "hold", from_word(0)}

def delay(n: Nat, value: U32) -> U32:
  match n:
    case 0n: value
    case 1n+rest: delay(rest, U32.add(value, 1))

def consume_item(result: Array<U32> & U32, text: String, bits: F32, later: U32) -> U32:
  match result:
    case Tuple{items, value}:
      U32.add(U32.add(value, later), U32.add(U32.from_nat(String.length(text)), F32.bits(bits)))

def consume(packet: Packet, seed: U32) -> U32:
  match packet:
    case Packet{items, text, bits}:
      later = delay(130n, seed)
      consume_item(Array.get(U32, items, 2), text, bits, later)

def overlapping(+a: U32, +b: U32) -> U32:
  first = make(a)
  second = make(b)
  U32.add(consume(first, 3), consume(second, 5))

def escaped(value: U32) -> Packet:
  make(value)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(consume(make(40), 3)))
    Unit <- IO.print(U32.show(overlapping(40, 7)))
    Unit <- IO.print(U32.show(consume(escaped(9), 1)))
    IO.print(U32.show(consume(make_alt(50), 1)))

#|2147483825
#|323
#|2147483792
#|185
