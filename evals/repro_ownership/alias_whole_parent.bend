# Whole-parent / projected-field reuse witness, value-observable only.
# A Many caller value is supplied to two affine consumers: one projects one
# Many String field, the other consumes the whole parent. Any sharing copy a
# correct emitter makes is legitimate, so this fixture has no heap frontier
# check; the only contract is the printed value (4 + 5 = 9) and no double
# free. It is deliberately NOT part of the two memory witnesses.
import Base

type PairS is Data:
  PairS{+a: String, +b: String}

def first_field(p: PairS) -> Nat:
  match p:
    case PairS{a, b}:
      String.length(a)

def whole_length(p: PairS) -> Nat:
  match p:
    case PairS{a, b}:
      Nat.add(String.length(a), String.length(b))

def both(+p: PairS) -> Nat:
  Nat.add(first_field(p), whole_length(p))

def main() -> IO(Unit):
  IO.print(Nat.show(both(PairS{"abcd", "z"})))
