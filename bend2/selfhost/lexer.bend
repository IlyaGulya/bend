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

def advance_newline(mark: Mark, +width: Nat, newline: Bool) -> Mark:
  match mark:
    case Pos{offset, line, col}:
      match newline:
        case True{}:
          Pos{(offset + width : Nat), (line + 1n : Nat), 1n}
        case False{}:
          Pos{(offset + width : Nat), line, (col + width : Nat)}

def advance(mark: Mark, +c: Char) -> Mark:
  advance_newline(mark, utf16_width(c), char_is(c, 10))


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
def normal_acc_plain(+c: Char, +mark: Mark, +after: Mark, +acc: List<&2, Token>, significant: Bool) -> List<&2, Token>:
  match significant:
    case True{}: acc
    case False{}: token(SymbolToken{}, SCon{c, SNil{}}, mark, after) <> acc

def normal_acc_newline(+c: Char, +mark: Mark, +after: Mark, +acc: List<&2, Token>, newline: Bool) -> List<&2, Token>:
  match newline:
    case True{}:
      token(NewlineToken{}, SCon{c, SNil{}}, mark, after) <> acc
    case False{}:
      normal_acc_plain(c, mark, after, acc, normal_significant(c))

def normal_acc(+c: Char, +mark: Mark, +after: Mark, +acc: List<&2, Token>) -> List<&2, Token>:
  normal_acc_newline(c, mark, after, acc, char_is(c, 10))

def normal_mode_quote(+c: Char, mark: Mark, rest: List<&2, Char>, quoted: Bool) -> ScanMode:
  match quoted:
    case True{}: ScanQuoted{c, mark, [c], False{}, quote_class(rest, c)}
    case False{}: ScanNormal{}

def normal_mode_digit(+c: Char, mark: Mark, rest: List<&2, Char>, digit: Bool) -> ScanMode:
  match digit:
    case True{}: ScanNumber{mark, [c], False{}, False{}}
    case False{}: normal_mode_quote(c, mark, rest, Bool.or(char_is(c, 34), char_is(c, 39)))

def normal_mode_name(+c: Char, mark: Mark, rest: List<&2, Char>, name: Bool) -> ScanMode:
  match name:
    case True{}: ScanName{mark, [c]}
    case False{}: normal_mode_digit(c, mark, rest, Char.is_digit(c))

def normal_mode_space(+c: Char, mark: Mark, rest: List<&2, Char>, space: Bool) -> ScanMode:
  match space:
    case True{}: ScanNormal{}
    case False{}: normal_mode_name(c, mark, rest, name_head(c))

def normal_mode_comment(+c: Char, mark: Mark, rest: List<&2, Char>, comment: Bool) -> ScanMode:
  match comment:
    case True{}: ScanComment{}
    case False{}: normal_mode_space(c, mark, rest, Char.is_space(c))

def normal_mode_newline(+c: Char, mark: Mark, rest: List<&2, Char>, newline: Bool) -> ScanMode:
  match newline:
    case True{}: ScanNormal{}
    case False{}: normal_mode_comment(c, mark, rest, char_is(c, 35))

def normal_mode(+c: Char, mark: Mark, rest: List<&2, Char>) -> ScanMode:
  normal_mode_newline(c, mark, rest, char_is(c, 10))

# A stop branch decides the next accumulator and mode without recursing, so the
# single `scan` self-call remains the only recursion (no new mutual cycle).
type ScanNext is Data:
  ScanNext{acc: List<&2, Token>, mode: ScanMode}

def scan_number_plain(+c: Char, +rest: List<&2, Char>, +beg: Mark, +rev: List<&2, Char>, +mark: Mark, +after: Mark, +acc: List<&2, Token>) -> ScanNext:
  +number_token = token(NumberToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, mark)
  ScanNext{normal_acc(c, mark, after, number_token <> acc), normal_mode(c, mark, rest)}

def scan_number_flags(+c: Char, rest: List<&2, Char>, beg: Mark, rev: List<&2, Char>, mark: Mark, after: Mark, acc: List<&2, Token>, suffix: Bool, decimal: Bool, exponent_mark: Bool) -> ScanNext:
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
def scan_number_stop(+c: Char, rest: List<&2, Char>, beg: Mark, rev: List<&2, Char>, +fraction: Bool, +exponent: Bool, mark: Mark, after: Mark, acc: List<&2, Token>) -> ScanNext:
  scan_number_flags(c, rest, beg, rev, mark, after, acc,
    Bool.and(Bool.not(fraction), Bool.and(Bool.not(exponent), char_is(c, 110))),
    Bool.and(Bool.not(fraction), Bool.and(Bool.not(exponent), char_is(c, 46))),
    Bool.and(fraction, Bool.and(Bool.not(exponent), Bool.or(char_is(c, 101), char_is(c, 69)))))


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

# Each state transition is acyclic. Only scan recurses, on the source tail;
# computed predicates/results cross parameter or projection boundaries.
def scan_comment(+c: Char, mark: Mark, after: Mark, acc: List<&2, Token>, newline: Bool) -> ScanNext:
  match newline:
    case True{}: ScanNext{token(NewlineToken{}, SCon{c, SNil{}}, mark, after) <> acc, ScanNormal{}}
    case False{}: ScanNext{acc, ScanComment{}}

def scan_name(+c: Char, rest: List<&2, Char>, +beg: Mark, rev: List<&2, Char>, +mark: Mark, +after: Mark, acc: List<&2, Token>, continuing: Bool) -> ScanNext:
  match continuing:
    case True{}: ScanNext{acc, ScanName{beg, c <> rev}}
    case False{}:
      name_token = token(NameToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, mark)
      ScanNext{normal_acc(c, mark, after, name_token <> acc), normal_mode(c, mark, rest)}

def scan_number(+c: Char, rest: List<&2, Char>, beg: Mark, rev: List<&2, Char>, fraction: Bool, exponent: Bool, mark: Mark, after: Mark, acc: List<&2, Token>, digit: Bool) -> ScanNext:
  match digit:
    case True{}: ScanNext{acc, ScanNumber{beg, c <> rev, fraction, exponent}}
    case False{}: scan_number_stop(c, rest, beg, rev, fraction, exponent, mark, after, acc)

def scan_after_dot(+c: Char, rest: List<&2, Char>, beg: Mark, rev: List<&2, Char>, dot: Char, dot_beg: Mark, mark: Mark, after: Mark, acc: List<&2, Token>, digit: Bool) -> ScanNext:
  match digit:
    case True{}: ScanNext{acc, ScanNumber{beg, c <> (dot <> rev), True{}, False{}}}
    case False{}: scan_after_dot_plain(c, rest, beg, rev, dot, dot_beg, mark, after, acc)

def scan_after_exponent(+c: Char, rest: List<&2, Char>, beg: Mark, rev: List<&2, Char>, marker: Char, mark: Mark, after: Mark, acc: List<&2, Token>, sign: Bool, digit: Bool) -> ScanNext:
  match sign:
    case True{}: ScanNext{acc, ScanAfterExponentSign{beg, rev, marker, c}}
    case False{}:
      match digit:
        case True{}: ScanNext{acc, ScanNumber{beg, c <> (marker <> rev), True{}, True{}}}
        case False{}: scan_exponent_plain(c, rest, beg, rev, marker, mark, after, acc)

def scan_after_exponent_sign(+c: Char, rest: List<&2, Char>, beg: Mark, rev: List<&2, Char>, marker: Char, sign: Char, mark: Mark, after: Mark, acc: List<&2, Token>, digit: Bool) -> ScanNext:
  match digit:
    case True{}: ScanNext{acc, ScanNumber{beg, c <> (sign <> (marker <> rev)), True{}, True{}}}
    case False{}: scan_exponent_sign_plain(c, rest, beg, rev, marker, sign, mark, after, acc)

def scan_char(+c: Char, +rest: List<&2, Char>, +mark: Mark, +after: Mark, acc: List<&2, Token>, mode: ScanMode) -> ScanNext:
  match mode:
    case ScanNormal{}:
      ScanNext{normal_acc(c, mark, after, acc), normal_mode(c, mark, rest)}
    case ScanComment{}:
      scan_comment(c, mark, after, acc, char_is(c, 10))
    case ScanName{+beg, rev}:
      scan_name(c, rest, beg, rev, mark, after, acc, name_part(c))
    case ScanNumber{beg, rev, fraction, exponent}:
      scan_number(c, rest, beg, rev, fraction, exponent, mark, after, acc, Char.is_digit(c))
    case ScanAfterDot{beg, rev, dot, dot_beg}:
      scan_after_dot(c, rest, beg, rev, dot, dot_beg, mark, after, acc, Char.is_digit(c))
    case ScanAfterExponent{beg, rev, marker}:
      scan_after_exponent(c, rest, beg, rev, marker, mark, after, acc, Bool.or(char_is(c, 43), char_is(c, 45)), Char.is_digit(c))
    case ScanAfterExponentSign{beg, rev, marker, sign}:
      scan_after_exponent_sign(c, rest, beg, rev, marker, sign, mark, after, acc, Char.is_digit(c))
    case ScanQuoted{+quote, beg, rev, True{}, _}:
      ScanNext{acc, ScanQuoted{quote, beg, c <> rev, False{}, quote_class(rest, quote)}}
    case ScanQuoted{+quote, beg, rev, False{}, QuoteClose{}}:
      kind = Bool.pick(TokenKind, char_is(quote, 34), StringToken{}, CharToken{})
      ScanNext{token(kind, String.from_list(List.reverse(&2, Char, c <> rev)), beg, after) <> acc, ScanNormal{}}
    case ScanQuoted{+quote, beg, rev, False{}, QuoteEscape{}}:
      ScanNext{acc, ScanQuoted{quote, beg, c <> rev, True{}, quote_class(rest, quote)}}
    case ScanQuoted{_, beg, rev, False{}, QuoteNewline{}}:
      ScanNext{token(NewlineToken{}, SCon{c, SNil{}}, mark, after) <> token(ErrorToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, mark) <> acc, ScanNormal{}}
    case ScanQuoted{+quote, beg, rev, False{}, QuoteOther{}}:
      ScanNext{acc, ScanQuoted{quote, beg, c <> rev, False{}, quote_class(rest, quote)}}

def scan_end(+mark: Mark, acc: List<&2, Token>, mode: ScanMode) -> List<&2, Token>:
  match mode:
    case ScanNormal{}: end_tokens(mark, acc)
    case ScanComment{}: end_tokens(mark, acc)
    case ScanName{beg, rev}:
      end_tokens(mark, token(NameToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, mark) <> acc)
    case ScanNumber{beg, rev, _, _}:
      end_tokens(mark, token(NumberToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, mark) <> acc)
    case ScanAfterDot{beg, rev, dot, +dot_beg}:
      dot_token = token(SymbolToken{}, SCon{dot, SNil{}}, dot_beg, mark)
      number_token = token(NumberToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, dot_beg)
      end_tokens(mark, dot_token <> number_token <> acc)
    case ScanAfterExponent{beg, rev, _}:
      end_tokens(mark, token(NumberToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, mark) <> acc)
    case ScanAfterExponentSign{beg, rev, marker, sign}:
      end_tokens(mark, token(NumberToken{}, String.from_list(List.reverse(&2, Char, sign <> (marker <> rev))), beg, mark) <> acc)
    case ScanQuoted{_, beg, rev, _, _}:
      end_tokens(mark, token(ErrorToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, mark) <> acc)

def scan_next_acc(next: ScanNext) -> List<&2, Token>:
  match next:
    case ScanNext{acc, _}: acc

def scan_next_mode(next: ScanNext) -> ScanMode:
  match next:
    case ScanNext{_, mode}: mode

def scan(cs: List<&2, Char>, +mark: Mark, acc: List<&2, Token>, mode: ScanMode) -> List<&2, Token>:
  match cs:
    case Nil{}: scan_end(mark, acc, mode)
    case +c <> +rest:
      +after = advance(mark, c)
      +next = scan_char(c, rest, mark, after, acc, mode)
      scan(rest, after, scan_next_acc(next), scan_next_mode(next))
law tokens:
  for source: String
  List<&2, Token>

def tokens(source):
  scan(String.to_list(source), Pos{0n, 1n, 1n}, Nil{}, ScanNormal{})

