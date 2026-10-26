# A compact scalar literal and its constructor spelling must agree across
# UTF-16 boundaries: NUL, BMP, the first supplementary code, an astral glyph,
# and the last Unicode scalar. Length counts Chars, not UTF-16 code units.
import Base

def literal() -> String:
  "\u{0}\u{e9}\u{10000}\u{1f600}\u{10ffff}"

def codes(s: String) -> List<U32>:
  match s:
    case SNil{}: Nil{}
    case SCon{head, tail}: Char.to_u32(head) <> codes(tail)

def main() -> Nat & List<U32>:
  (String.length(literal()), codes(literal()))

#|(5n, [0, 233, 65536, 128512, 1114111])
