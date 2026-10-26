# A Char holds any u32 code and a String holds those Chars, so a code that is no
# Unicode scalar survives construction, append, length, order and Char.to_u32;
# only text crossing a host seam turns it into U+FFFD. The four codes here are a
# low surrogate, a high surrogate, one past U+10FFFF and the largest u32. Text
# crosses both ways: a Char leaves as text and a Char answer is read back as
# text, so a lone surrogate a host hands in is U+FFFD (65533), not a code, and a
# String answer with one is three Chars, the middle one 65533 (the "a?b" line).
import Base

law echo:
  for c: Char
  IO(Char)

def echo(c):
  import "./js_char_full_u32.js"

def lone_char() -> IO(Char):
  import "./js_char_full_u32.js"

def lone_text() -> IO(String):
  import "./js_char_full_u32.js"

def codes() -> String:
  SCon{Char.from_u32(55296), SCon{Char.from_u32(56320),
    SCon{Char.from_u32(1114112), SCon{Char.from_u32(4294967295), SNil{}}}}}

def main() -> IO(U32):
  do IO<U32>:
    lo : Char <- echo(Char.from_u32(55295))
    hi : Char <- echo(Char.from_u32(57344))
    top : Char <- echo(Char.from_u32(1114111))
    sur : Char <- echo(Char.from_u32(55296))
    lc : Char <- lone_char()
    +lt : String <- lone_text()
    Unit <- IO.print(Nat.show(String.length(codes())))
    Unit <- IO.print(U32.show(Char.to_u32(Char.from_u32(4294967295))))
    Unit <- IO.print(U32.show(Char.to_u32(Char.from_u32(57343))))
    Unit <- IO.print(U32.show(Char.to_u32(lo)))
    Unit <- IO.print(U32.show(Char.to_u32(hi)))
    Unit <- IO.print(U32.show(Char.to_u32(top)))
    Unit <- IO.print(U32.show(Char.to_u32(sur)))
    Unit <- IO.print(U32.show(Char.to_u32(Char.from_u32(55296))))
    Unit <- IO.print(U32.show(Char.to_u32(lc)))
    Unit <- IO.print(Nat.show(String.length(lt)))
    Unit <- IO.print(lt)
    Unit <- IO.print(codes())
    return 0

#|4
#|4294967295
#|57343
#|55295
#|57344
#|1114111
#|65533
#|55296
#|65533
#|3
#|a�b
#|����
