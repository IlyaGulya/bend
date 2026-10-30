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
      match newline:
        case True{}:
          Pos{(offset + utf16_width(c) : Nat), (line + 1n : Nat), 1n}
        case False{}:
          Pos{(offset + utf16_width(c) : Nat), line, (col + utf16_width(c) : Nat)}

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

def normal_acc(+c: Char, +mark: Mark, +acc: List<&2, Token>) -> List<&2, Token>:
  Bool.pick(List<&2, Token>, char_is(c, 10),
    token(NewlineToken{}, SCon{c, SNil{}}, mark, advance(mark, c)) <> acc,
    Bool.pick(List<&2, Token>, Bool.or(char_is(c, 35), Bool.or(Char.is_space(c), Bool.or(name_head(c), Bool.or(Char.is_digit(c), Bool.or(char_is(c, 34), char_is(c, 39)))))),
      acc,
      token(SymbolToken{}, SCon{c, SNil{}}, mark, advance(mark, c)) <> acc))

def normal_mode(+c: Char, +mark: Mark, rest: List<&2, Char>) -> ScanMode:
  Bool.pick(ScanMode, char_is(c, 10),
    ScanNormal{},
    Bool.pick(ScanMode, char_is(c, 35),
      ScanComment{},
      Bool.pick(ScanMode, Char.is_space(c),
        ScanNormal{},
        Bool.pick(ScanMode, name_head(c),
          ScanName{mark, [c]},
          Bool.pick(ScanMode, Char.is_digit(c),
            ScanNumber{mark, [c], False{}, False{}},
            Bool.pick(ScanMode, Bool.or(char_is(c, 34), char_is(c, 39)),
              ScanQuoted{c, mark, [c], False{}, quote_class(rest, c)},
              ScanNormal{}))))))

def scan(cs: List<&2, Char>, +mark: Mark, +acc: List<&2, Token>, mode: ScanMode) -> List<&2, Token>:
  match cs mode:
    case Nil{} ScanNormal{}:
      end_tokens(mark, acc)
    case +c <> +rest ScanNormal{}:
      scan(rest, advance(mark, c), normal_acc(c, mark, acc), normal_mode(c, mark, rest))
    case Nil{} ScanComment{}:
      end_tokens(mark, acc)
    case +c <> +rest ScanComment{}:
      +after_char = advance(mark, c)
      +next_mode = Bool.pick(ScanMode, char_is(c, 10), ScanNormal{}, ScanComment{})
      +next_acc = Bool.pick(List<&2, Token>, char_is(c, 10), token(NewlineToken{}, SCon{c, SNil{}}, mark, after_char) <> acc, acc)
      scan(rest, after_char, next_acc, next_mode)
    case Nil{} ScanName{+beg, +rev}:
      end_tokens(mark, token(NameToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, mark) <> acc)
    case +c <> +rest ScanName{+beg, +rev}:
      +name_token = token(NameToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, mark)
      +after_char = advance(mark, c)
      +continuing = name_part(c)
      +next_mode = Bool.pick(ScanMode, continuing, ScanName{beg, c <> rev}, normal_mode(c, mark, rest))
      +next_acc = Bool.pick(List<&2, Token>, continuing, acc, normal_acc(c, mark, name_token <> acc))
      scan(rest, after_char, next_acc, next_mode)
    case Nil{} ScanNumber{beg, rev, _, _}:
      end_tokens(mark, token(NumberToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, mark) <> acc)
    case +c <> +rest ScanNumber{+beg, +rev, +fraction, +exponent}:
      +number_token = token(NumberToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, mark)
      +after_char = advance(mark, c)
      +digit = Char.is_digit(c)
      +suffix = Bool.and(Bool.not(fraction), Bool.and(Bool.not(exponent), char_is(c, 110)))
      +decimal = Bool.and(Bool.not(fraction), Bool.and(Bool.not(exponent), char_is(c, 46)))
      +exponent_mark = Bool.and(fraction, Bool.and(Bool.not(exponent), Bool.or(char_is(c, 101), char_is(c, 69))))
      +next_mode = Bool.pick(ScanMode, digit,
        ScanNumber{beg, c <> rev, fraction, exponent},
        Bool.pick(ScanMode, suffix, ScanNormal{},
          Bool.pick(ScanMode, decimal, ScanAfterDot{beg, rev, c, mark},
            Bool.pick(ScanMode, exponent_mark, ScanAfterExponent{beg, rev, c}, normal_mode(c, mark, rest)))))
      +next_acc = Bool.pick(List<&2, Token>, digit, acc,
        Bool.pick(List<&2, Token>, suffix,
          token(NumberToken{}, String.from_list(List.reverse(&2, Char, c <> rev)), beg, after_char) <> acc,
          Bool.pick(List<&2, Token>, decimal, acc,
            Bool.pick(List<&2, Token>, exponent_mark, acc, normal_acc(c, mark, number_token <> acc)))))
      scan(rest, after_char, next_acc, next_mode)
    case Nil{} ScanAfterDot{+beg, +rev, +dot, +dot_beg}:
      dot_token = token(SymbolToken{}, SCon{dot, SNil{}}, dot_beg, mark)
      number_token = token(NumberToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, dot_beg)
      end_tokens(mark, dot_token <> number_token <> acc)
    case +d <> +rest ScanAfterDot{+beg, +rev, +dot, +dot_beg}:
      +after_digit = advance(mark, d)
      +number_token = token(NumberToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, dot_beg)
      +dot_token = token(SymbolToken{}, SCon{dot, SNil{}}, dot_beg, mark)
      +digit = Char.is_digit(d)
      +next_mode = Bool.pick(ScanMode, digit, ScanNumber{beg, d <> (dot <> rev), True{}, False{}}, normal_mode(d, mark, rest))
      +next_acc = Bool.pick(List<&2, Token>, digit, acc, normal_acc(d, mark, dot_token <> number_token <> acc))
      scan(rest, after_digit, next_acc, next_mode)
    case Nil{} ScanAfterExponent{beg, rev, _}:
      end_tokens(mark, token(NumberToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, mark) <> acc)
    case +d <> +rest ScanAfterExponent{+beg, +rev, +marker}:
      +after_digit = advance(mark, d)
      +exponent_token = token(NumberToken{}, String.from_list(List.reverse(&2, Char, marker <> rev)), beg, mark)
      +sign = Bool.or(char_is(d, 43), char_is(d, 45))
      +digit = Char.is_digit(d)
      +next_mode = Bool.pick(ScanMode, sign, ScanAfterExponentSign{beg, rev, marker, d},
        Bool.pick(ScanMode, digit, ScanNumber{beg, d <> (marker <> rev), True{}, True{}}, normal_mode(d, mark, rest)))
      +next_acc = Bool.pick(List<&2, Token>, sign, acc,
        Bool.pick(List<&2, Token>, digit, acc, normal_acc(d, mark, exponent_token <> acc)))
      scan(rest, after_digit, next_acc, next_mode)
    case Nil{} ScanAfterExponentSign{beg, rev, marker, sign}:
      end_tokens(mark, token(NumberToken{}, String.from_list(List.reverse(&2, Char, sign <> (marker <> rev))), beg, mark) <> acc)
    case +d <> +rest ScanAfterExponentSign{+beg, +rev, +marker, +sign}:
      +after_digit = advance(mark, d)
      +exponent_token = token(NumberToken{}, String.from_list(List.reverse(&2, Char, sign <> (marker <> rev))), beg, mark)
      +digit = Char.is_digit(d)
      +next_mode = Bool.pick(ScanMode, digit, ScanNumber{beg, d <> (sign <> (marker <> rev)), True{}, True{}}, normal_mode(d, mark, rest))
      +next_acc = Bool.pick(List<&2, Token>, digit, acc, normal_acc(d, mark, exponent_token <> acc))
      scan(rest, after_digit, next_acc, next_mode)
    case Nil{} ScanQuoted{_, beg, rev, _, _}:
      end_tokens(mark, token(ErrorToken{}, String.from_list(List.reverse(&2, Char, rev)), beg, mark) <> acc)
    case +c <> +rest ScanQuoted{+quote, +beg, +rev, True{}, _}:
      scan(rest, advance(mark, c), acc, ScanQuoted{quote, beg, c <> rev, False{}, quote_class(rest, quote)})
    case +c <> +rest ScanQuoted{+quote, +beg, +rev, False{}, QuoteClose{}}:
      kind = Bool.pick(TokenKind, char_is(quote, 34), StringToken{}, CharToken{})
      scan(rest, advance(mark, c), token(kind, String.from_list(List.reverse(&2, Char, c <> rev)), beg, advance(mark, c)) <> acc, ScanNormal{})
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

