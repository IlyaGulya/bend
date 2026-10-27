# Word-backed scalar conversions consume their temporary Word once, including
# repeated calls and a Word still needed by another conversion.
import Base

def from_word(x: U32) -> F32:
  match x:
    case U32{word}: F32{word}

def roundtrip(x: U32) -> U32:
  F32.bits(from_word(x))

def shared(x: U32) -> U32:
  match x:
    case U32{+word}:
      U32.add(F32.bits(F32{word}), U32{word})

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(roundtrip(1065353216)))
    IO.print(U32.show(roundtrip(2147483648)))
    IO.print(U32.show(roundtrip(1)))
    IO.print(U32.show(roundtrip(2139095040)))
    IO.print(U32.show(roundtrip(1065353217)))
    IO.print(U32.show(shared(1065353216)))

#|1065353216
#|2147483648
#|1
#|2139095040
#|1065353217
#|2130706432
