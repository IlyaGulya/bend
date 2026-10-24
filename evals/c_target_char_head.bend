# C target fixture: a Char read from a string stored in a record field and in
# an Array<Char> element, both read back through Char.to_u32.
#
# The literal is non-ASCII (U+03BB, 955) so a raw/unpacked head word cannot
# pass by accident. Both stores and both reads must agree with the packed Chr
# representation. Expected: 955 twice.
import Base

type Holder is Data:
  Holder{c: Char}

def first(s: String) -> Char:
  match s:
    case SCon{h, t}: h
    case SNil{}: 'a'

def main() -> IO(Unit):
  c = first("λx")
  h = Holder{c}
  a = Array.new(Char, 0n, c)
  (b, got) = Array.get(Char, a, 0)
  match h:
    case Holder{field}:
      do IO<Unit>:
        Unit <- IO.print(U32.show(Char.to_u32(field)))
        Unit <- IO.print(U32.show(Char.to_u32(got)))
        Unit

#|955
#|955
