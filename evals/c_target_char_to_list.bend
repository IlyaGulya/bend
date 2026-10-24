# C target fixture: String.to_list characters are packed Char values, and
# Char.to_u32 reads the first two codepoints of a non-ASCII literal.
# U+03BB is 955, 'x' is 120. Expected: 955 then 120.
import Base

def main() -> IO(Unit):
  match String.to_list("λx"):
    case h <> t:
      match t:
        case h2 <> rest:
          do IO<Unit>:
            Unit <- IO.print(U32.show(Char.to_u32(h)))
            Unit <- IO.print(U32.show(Char.to_u32(h2)))
            Unit
        case Nil{}: IO.print("unexpected")
    case Nil{}: IO.print("unexpected")

#|955
#|120
