# Minimal witness: constructing data fields that hold Bool values from both
# arms. Each Bool operand is unboxed into the laid-out field word; the word
# must be the arm's own tag (False = 0, True = 1), not one constant tag.
#
# Both orders are built so a writer that always emits tag 1 turns the first
# field of each pair into True and cannot match either expectation. Two Bool
# fields already make the record two laid-out words (unpacked), so the reads
# take the unpacked-field path.
#
# Expected: False/True for {False, True}, then True/False for {True, False}.
import Base

type Tagged is Data:
  Tagged{l: Bool, r: Bool}

def tags(p: Tagged) -> IO(Unit):
  match p:
    case Tagged{l, r}:
      do IO<Unit>:
        Unit <- IO.print(Bool.show(l))
        IO.print(Bool.show(r))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- tags(Tagged{False{}, True{}})
    tags(Tagged{True{}, False{}})

#|False
#|True
#|True
#|False
