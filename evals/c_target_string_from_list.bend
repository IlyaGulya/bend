# C target fixture: String.from_list builds SCon nodes, which lowering turns
# into the overloaded PrimStringAppend (Chr payload packed, tail quantity with
# one keep). The printer then reads the raw codepoint storage, the head is
# projected into a declared Char, and to_list goes back to Char cells.
#
# The literal is non-ASCII (λ, U+03BB). Expected stdout four lines:
# λx / 955 / 955 / 120.
import Base

def first(s: String) -> Char:
  match s:
    case SCon{h, t}: h
    case SNil{}: 'a'

def codes(s: String) -> IO(Unit):
  match String.to_list(s):
    case a <> rest:
      match rest:
        case b <> tail:
          do IO<Unit>:
            Unit <- IO.print(U32.show(Char.to_u32(a)))
            Unit <- IO.print(U32.show(Char.to_u32(b)))
            Unit
        case Nil{}: IO.print("unexpected")
    case Nil{}: IO.print("unexpected")

def main() -> IO(Unit):
  shown = String.from_list(['λ', 'x'])
  headed = String.from_list(['λ', 'x'])
  listed = String.from_list(['λ', 'x'])
  do IO<Unit>:
    Unit <- IO.print(shown)
    Unit <- IO.print(U32.show(Char.to_u32(first(headed))))
    codes(listed)

#|λx
#|955
#|955
#|120
