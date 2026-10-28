import Base

type TokenKind is Data:
  NameToken{}
  NumberToken{}
  StringToken{}
  CharToken{}
  SymbolToken{}
  NewlineToken{}
  EndToken{}
  ErrorToken{}

type Token is Data:
  TokenInfo{kind: TokenKind, text: String, beg: Nat, end: Nat, line: Nat, col: Nat}

type Mark is Data:
  Pos{offset: Nat, line: Nat, col: Nat}

type QuoteClass is Data:
  QuoteClose{}
  QuoteEscape{}
  QuoteNewline{}
  QuoteOther{}
type ScanMode is Data:
  ScanNormal{}
  ScanComment{}
  ScanName{beg: Mark, rev: List<&2, Char>}
  ScanNumber{beg: Mark, rev: List<&2, Char>, fraction: Bool, exponent: Bool}
  ScanAfterDot{beg: Mark, rev: List<&2, Char>, dot: Char, dot_beg: Mark}
  ScanAfterExponent{beg: Mark, rev: List<&2, Char>, marker: Char}
  ScanAfterExponentSign{beg: Mark, rev: List<&2, Char>, marker: Char, sign: Char}
  ScanQuoted{quote: Char, beg: Mark, rev: List<&2, Char>, escaped: Bool, current: QuoteClass}



def char_is(c: Char, code: U32) -> Bool:
  Char.is_eq(c, Char.from_u32(code))

def name_head(+c: Char) -> Bool:
  Bool.or(Char.is_alpha(c), char_is(c, 95))

def name_part(+c: Char) -> Bool:
  Bool.or(name_head(c), Bool.or(Char.is_digit(c), char_is(c, 46)))

def utf16_width(c: Char) -> Nat:
  Bool.pick(Nat, U32.is_gt(Char.to_u32(c), 65535), 2n, 1n)

def advance_newline(mark: Mark, +c: Char, newline: Bool) -> Mark:
  match mark:
    case Pos{offset, line, col}:
      +width = utf16_width(c)
      match newline:
        case True{}:
          Pos{(offset + width : Nat), (line + 1n : Nat), 1n}
        case False{}:
          Pos{(offset + width : Nat), line, (col + width : Nat)}

def advance(mark: Mark, +c: Char) -> Mark:
  advance_newline(mark, c, char_is(c, 10))


def token(kind: TokenKind, text: String, beg: Mark, fin: Mark) -> Token:
  match beg fin:
    case Pos{offset, line, col} Pos{end, _, _}:
      TokenInfo{kind, text, offset, end, line, col}


def quote_class_flags(is_quote: Bool, is_escape: Bool, newline: Bool) -> QuoteClass:
  match is_quote:
    case True{}: QuoteClose{}
    case False{}:
      match is_escape:
        case True{}: QuoteEscape{}
        case False{}:
          match newline:
            case True{}: QuoteNewline{}
            case False{}: QuoteOther{}

def quote_class(cs: List<&2, Char>, quote: Char) -> QuoteClass:
  match cs:
    case Nil{}: QuoteOther{}
    case +c <> _: quote_class_flags(Char.is_eq(c, quote), char_is(c, 92), char_is(c, 10))
def end_tokens(mark: Mark, acc: List<&2, Token>) -> List<&2, Token>:
  match mark:
    case Pos{+offset, line, col}:
      List.reverse(&2, Token, TokenInfo{EndToken{}, SNil{}, offset, offset, line, col} <> acc)

def normal_significant(+c: Char) -> Bool:
  Bool.or(char_is(c, 35), Bool.or(Char.is_space(c), Bool.or(name_head(c), Bool.or(Char.is_digit(c), Bool.or(char_is(c, 34), char_is(c, 39))))))

# The machine is strict, so a Bool.pick argument is built even when the other
# branch is taken. Select first and build exactly one token for this character.
def normal_acc(+c: Char, +mark: Mark, +after: Mark, +acc: List<&2, Token>) -> List<&2, Token>:
  match char_is(c, 10):
    case True{}:
      token(NewlineToken{}, SCon{c, SNil{}}, mark, after) <> acc
    case False{}:
      normal_acc_plain(c, mark, after, acc, normal_significant(c))

def normal_acc_plain(+c: Char, +mark: Mark, +after: Mark, +acc: List<&2, Token>, +significant: Bool) -> List<&2, Token>:
  match significant:
    case True{}: acc
    case False{}: token(SymbolToken{}, SCon{c, SNil{}}, mark, after) <> acc

def normal_mode(+c: Char, +mark: Mark, rest: List<&2, Char>) -> ScanMode:
  match char_is(c, 10):
    case True{}: ScanNormal{}
    case False{}:
      match char_is(c, 35):
        case True{}: ScanComment{}
        case False{}:
          match Char.is_space(c):
            case True{}: ScanNormal{}
            case False{}:
              match name_head(c):
                case True{}: ScanName{mark, [c]}
                case False{}:
                  match Char.is_digit(c):
                    case True{}: ScanNumber{mark, [c], False{}, False{}}
                    case False{}:
                      match Bool.or(char_is(c, 34), char_is(c, 39)):
                        case True{}: ScanQuoted{c, mark, [c], False{}, quote_class(rest, c)}
                        case False{}: ScanNormal{}

# A stop branch decides the next accumulator and mode without recursing, so the
# single `scan` self-call remains the only recursion (no new mutual cycle).
type ScanNext is Data:
  ScanNext{acc: List<&2, Token>, mode: ScanMode}

def scan_number_plain(+c: Char, +rest: List<&2, Char>, +beg: Mark, +rev: List<&2, Char>, +mark: Mark, +after: Mark, +acc: List<&2, Token>) -> ScanNext:
  +number_token = token(NumberToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, mark)
  ScanNext{normal_acc(c, mark, after, number_token <> acc), normal_mode(c, mark, rest)}

def scan_number_stop(+c: Char, +rest: List<&2, Char>, +beg: Mark, +rev: List<&2, Char>, +fraction: Bool, +exponent: Bool, +mark: Mark, +after: Mark, +acc: List<&2, Token>) -> ScanNext:
  +suffix = Bool.and(Bool.not(fraction), Bool.and(Bool.not(exponent), char_is(c, 110)))
  +decimal = Bool.and(Bool.not(fraction), Bool.and(Bool.not(exponent), char_is(c, 46)))
  +exponent_mark = Bool.and(fraction, Bool.and(Bool.not(exponent), Bool.or(char_is(c, 101), char_is(c, 69))))
  match suffix:
    case True{}:
      ScanNext{token(NumberToken{}, String.from_list(List.reverse(&2, Char, c <> rev)), beg, after) <> acc, ScanNormal{}}
    case False{}:
      match decimal:
        case True{}:
          ScanNext{acc, ScanAfterDot{beg, rev, c, mark}}
        case False{}:
          match exponent_mark:
            case True{}:
              ScanNext{acc, ScanAfterExponent{beg, rev, c}}
            case False{}:
              scan_number_plain(c, rest, beg, rev, mark, after, acc)

def scan_after_dot_plain(+d: Char, +rest: List<&2, Char>, +beg: Mark, +rev: List<&2, Char>, +dot: Char, +dot_beg: Mark, +mark: Mark, +after: Mark, +acc: List<&2, Token>) -> ScanNext:
  +dot_token = token(SymbolToken{}, SCon{dot, SNil{}}, dot_beg, mark)
  +number_token = token(NumberToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, dot_beg)
  ScanNext{normal_acc(d, mark, after, dot_token <> number_token <> acc), normal_mode(d, mark, rest)}

def scan_exponent_plain(+d: Char, +rest: List<&2, Char>, +beg: Mark, +rev: List<&2, Char>, +marker: Char, +mark: Mark, +after: Mark, +acc: List<&2, Token>) -> ScanNext:
  +exponent_token = token(NumberToken{}, String.from_list(List.reverse(&2, Char, marker <> rev)), beg, mark)
  ScanNext{normal_acc(d, mark, after, exponent_token <> acc), normal_mode(d, mark, rest)}

def scan_exponent_sign_plain(+d: Char, +rest: List<&2, Char>, +beg: Mark, +rev: List<&2, Char>, +marker: Char, +sign: Char, +mark: Mark, +after: Mark, +acc: List<&2, Token>) -> ScanNext:
  +exponent_token = token(NumberToken{}, String.from_list(List.reverse(&2, Char, sign <> (marker <> rev))), beg, mark)
  ScanNext{normal_acc(d, mark, after, exponent_token <> acc), normal_mode(d, mark, rest)}

def scan(cs: List<&2, Char>, +mark: Mark, +acc: List<&2, Token>, mode: ScanMode) -> List<&2, Token>:
  match cs mode:
    case Nil{} ScanNormal{}:
      end_tokens(mark, acc)
    case +c <> +rest ScanNormal{}:
      +after_char = advance(mark, c)
      scan(rest, after_char, normal_acc(c, mark, after_char, acc), normal_mode(c, mark, rest))
    case Nil{} ScanComment{}:
      end_tokens(mark, acc)
    case +c <> +rest ScanComment{}:
      +after_char = advance(mark, c)
      match char_is(c, 10):
        case True{}:
          scan(rest, after_char, token(NewlineToken{}, SCon{c, SNil{}}, mark, after_char) <> acc, ScanNormal{})
        case False{}:
          scan(rest, after_char, acc, ScanComment{})
    case Nil{} ScanName{+beg, +rev}:
      end_tokens(mark, token(NameToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, mark) <> acc)
    case +c <> +rest ScanName{+beg, +rev}:
      +after_char = advance(mark, c)
      match name_part(c):
        case True{}:
          scan(rest, after_char, acc, ScanName{beg, c <> rev})
        case False{}:
          +name_token = token(NameToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, mark)
          scan(rest, after_char, normal_acc(c, mark, after_char, name_token <> acc), normal_mode(c, mark, rest))
    case Nil{} ScanNumber{beg, rev, _, _}:
      end_tokens(mark, token(NumberToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, mark) <> acc)
    case +c <> +rest ScanNumber{+beg, +rev, +fraction, +exponent}:
      +after_char = advance(mark, c)
      match Char.is_digit(c):
        case True{}:
          scan(rest, after_char, acc, ScanNumber{beg, c <> rev, fraction, exponent})
        case False{}:
          match scan_number_stop(c, rest, beg, rev, fraction, exponent, mark, after_char, acc):
            case ScanNext{next_acc, next_mode}:
              scan(rest, after_char, next_acc, next_mode)
    case Nil{} ScanAfterDot{+beg, +rev, +dot, +dot_beg}:
      dot_token = token(SymbolToken{}, SCon{dot, SNil{}}, dot_beg, mark)
      number_token = token(NumberToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, dot_beg)
      end_tokens(mark, dot_token <> number_token <> acc)
    case +d <> +rest ScanAfterDot{+beg, +rev, +dot, +dot_beg}:
      +after_digit = advance(mark, d)
      match Char.is_digit(d):
        case True{}:
          scan(rest, after_digit, acc, ScanNumber{beg, d <> (dot <> rev), True{}, False{}})
        case False{}:
          match scan_after_dot_plain(d, rest, beg, rev, dot, dot_beg, mark, after_digit, acc):
            case ScanNext{next_acc, next_mode}:
              scan(rest, after_digit, next_acc, next_mode)
    case Nil{} ScanAfterExponent{beg, rev, _}:
      end_tokens(mark, token(NumberToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, mark) <> acc)
    case +d <> +rest ScanAfterExponent{+beg, +rev, +marker}:
      +after_digit = advance(mark, d)
      +sign = Bool.or(char_is(d, 43), char_is(d, 45))
      match sign:
        case True{}:
          scan(rest, after_digit, acc, ScanAfterExponentSign{beg, rev, marker, d})
        case False{}:
          match Char.is_digit(d):
            case True{}:
              scan(rest, after_digit, acc, ScanNumber{beg, d <> (marker <> rev), True{}, True{}})
            case False{}:
              match scan_exponent_plain(d, rest, beg, rev, marker, mark, after_digit, acc):
                case ScanNext{next_acc, next_mode}:
                  scan(rest, after_digit, next_acc, next_mode)
    case Nil{} ScanAfterExponentSign{beg, rev, marker, sign}:
      end_tokens(mark, token(NumberToken{}, String.from_list(List.reverse(&2, Char, sign <> (marker <> rev))), beg, mark) <> acc)
    case +d <> +rest ScanAfterExponentSign{+beg, +rev, +marker, +sign}:
      +after_digit = advance(mark, d)
      match Char.is_digit(d):
        case True{}:
          scan(rest, after_digit, acc, ScanNumber{beg, d <> (sign <> (marker <> rev)), True{}, True{}})
        case False{}:
          match scan_exponent_sign_plain(d, rest, beg, rev, marker, sign, mark, after_digit, acc):
            case ScanNext{next_acc, next_mode}:
              scan(rest, after_digit, next_acc, next_mode)
    case Nil{} ScanQuoted{_, beg, rev, _, _}:
      end_tokens(mark, token(ErrorToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, mark) <> acc)
    case +c <> +rest ScanQuoted{+quote, +beg, +rev, True{}, _}:
      scan(rest, advance(mark, c), acc, ScanQuoted{quote, beg, c <> rev, False{}, quote_class(rest, quote)})
    case +c <> +rest ScanQuoted{+quote, +beg, +rev, False{}, QuoteClose{}}:
      +fin = advance(mark, c)
      kind = Bool.pick(TokenKind, char_is(quote, 34), StringToken{}, CharToken{})
      scan(rest, fin, token(kind, String.from_list(List.reverse(&2, Char, c <> rev)), beg, fin) <> acc, ScanNormal{})
    case +c <> +rest ScanQuoted{+quote, +beg, +rev, False{}, QuoteEscape{}}:
      scan(rest, advance(mark, c), acc, ScanQuoted{quote, beg, c <> rev, True{}, quote_class(rest, quote)})
    case +c <> +rest ScanQuoted{+quote, +beg, +rev, False{}, QuoteNewline{}}:
      +fin = advance(mark, c)
      scan(rest, fin, token(NewlineToken{}, SCon{c, SNil{}}, mark, fin) <> token(ErrorToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, mark) <> acc, ScanNormal{})
    case +c <> +rest ScanQuoted{+quote, +beg, +rev, False{}, QuoteOther{}}:
      scan(rest, advance(mark, c), acc, ScanQuoted{quote, beg, c <> rev, False{}, quote_class(rest, quote)})
law tokens:
  for source: String
  List<&2, Token>

def tokens(source):
  scan(String.to_list(source), Pos{0n, 1n, 1n}, Nil{}, ScanNormal{})

