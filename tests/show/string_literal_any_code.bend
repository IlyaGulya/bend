# show (show_string_literal_any_code): a String literal is Bend String data,
# not text at an FFI boundary. Every logical Char keeps its exact u32 code
# inside Bend — NUL, ASCII, a control, the last scalar, a separated surrogate
# pair and a code past U+10FFFF (#1080) — so the literal's length counts
# logical Chars and the value prints back as the same escapes. Before, the C
# target wrote a literal through its UTF-8 decoder, which cannot carry a
# surrogate's code nor one past U+10FFFF and returned U+FFFD instead.
import Base

def lit() -> String:
  "\u{41}\u{0}\u{e9}\u{7f}\u{10ffff}\u{d800}\u{dc00}\u{110000}\u{ffffffff}"

def shown() -> String:
  "\u{41}\u{0}\u{e9}\u{7f}\u{d800}\u{dc00}\u{110000}\u{ffffffff}"

def codes(s: String) -> List<U32>:
  match s:
    case SNil{}: Nil{}
    case SCon{head, tail}: Char.to_u32(head) <> codes(tail)

def from_codes(cs: List<U32>) -> String:
  match cs:
    case Nil{}: SNil{}
    case +code <> rest: SCon{Char.from_u32(code), from_codes(rest)}

# The literal and a string built one Char at a time are the same value, and
# the two shapes a literal can also take — empty and plain ASCII — agree too.
def same() -> Bool:
  String.eq(lit(), from_codes([65, 0, 233, 127, 1114111, 55296, 56320, 1114112, 4294967295]))

def edges() -> Bool:
  Bool.and(String.is_empty(""), String.eq("bend", from_codes([98, 101, 110, 100])))

law main:
  Pair(Nat, Pair(List<U32>, Pair(Bool, Pair(Bool, String))))

def main():
  (String.length(lit()), (codes(lit()), (same(), (edges(), shown()))))

#|(9n, [65, 0, 233, 127, 1114111, 55296, 56320, 1114112, 4294967295], True{}, True{}, "A\0é\u{7f}\u{d800}\u{dc00}\u{110000}\u{ffffffff}")
