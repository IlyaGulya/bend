# C target fixture: Bool is an inline one-constructor form per arm, not a raw
# C word and not a heap node. Bool.or reads two projected Bool fields through
# their packed tag view; the result is a canonical Bool term printed by the
# runtime. Expected: True, then False from Bool.xor.
import Base

type Flags is Data:
  Flags{a: Bool, b: Bool}

def either(fs: Flags) -> Bool:
  match fs:
    case Flags{a, b}:
      Bool.or(a, b)

def different(fs: Flags) -> Bool:
  match fs:
    case Flags{a, b}:
      Bool.xor(a, b)

def truth(fs: Flags) -> U32:
  match fs:
    case Flags{a, b}:
      U32.add(Bool.to_u32(a), Bool.to_u32(b))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Bool.show(either(Flags{False{}, True{}})))
    IO.print(Bool.show(different(Flags{True{}, True{}})))
    IO.print(U32.show(truth(Flags{False{}, True{}})))

#|True
#|False
#|1
