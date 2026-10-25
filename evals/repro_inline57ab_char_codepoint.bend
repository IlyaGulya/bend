# Minimal witness: one Char read as a projected unpacked field and as an
# Array<Char> cell. The codepoint is computed at run time (953 + 2 = U+03BB,
# 955) so no raw/unpacked head word can pass by accident.
#
# `pad: U32` is never read; it makes ChrBox two laid-out words so the Char
# field projection takes the unpacked-field path instead of the packed
# one-word path. Bindings stay at the function-body level (a `do` block only
# accepts `x <- action`, `x : T <- action`, `+x : T = value` or a bare action).
#
# Expected: 955 twice.
import Base

type ChrBox is Data:
  ChrBox{c: Char, pad: U32}

def field_code(r: ChrBox) -> U32:
  match r:
    case ChrBox{c, _}:
      Char.to_u32(c)

def show(r: ChrBox, pair: Array<Char> & Char) -> IO(Unit):
  (arr, v) = pair
  do IO<Unit>:
    Unit <- IO.print(U32.show(field_code(r)))
    IO.print(U32.show(Char.to_u32(v)))

def main() -> IO(Unit):
  +c = Char.from_u32(U32.add(953, 2))
  a = Array.new(Char, 0n, c)
  show(ChrBox{c, 0}, Array.get(Char, a, 0))

#|955
#|955
