# C target fixture: a closure captures a projected Many field and reads the
# captured path twice. The capture and its continuation carry the same root
# path; repeated reads are shared, not copied into two owners.
import Base

type Holder is Data:
  Holder{+n: U32}

def make(h: Holder) -> (U32 -> U32):
  match h:
    case Holder{n}:
      x => (U32.add(x, U32.add(n, n)) : U32)

def main() -> IO(Unit):
  f = make(Holder{3})
  IO.print(U32.show(f(4)))

#|10
