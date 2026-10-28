import Base
import ../../bend2/selfhost/lexer.bend as Lexer

def kind_name(kind: Lexer.TokenKind) -> String:
  match kind:
    case Lexer.NameToken{}:
      "name"
    case Lexer.NumberToken{}:
      "number"
    case Lexer.StringToken{}:
      "string"
    case Lexer.CharToken{}:
      "char"
    case Lexer.SymbolToken{}:
      "symbol"
    case Lexer.NewlineToken{}:
      "newline"
    case Lexer.EndToken{}:
      "end"
    case Lexer.ErrorToken{}:
      "error"

def token_text(kind: Lexer.TokenKind, text: String) -> String:
  match kind:
    case Lexer.NameToken{}:
      text
    case Lexer.NumberToken{}:
      text
    case Lexer.StringToken{}:
      text
    case Lexer.CharToken{}:
      text
    case Lexer.SymbolToken{}:
      text
    case Lexer.NewlineToken{}:
      "<NL>"
    case Lexer.EndToken{}:
      text
    case Lexer.ErrorToken{}:
      text

def show_token(token: Lexer.Token) -> String:
  match token:
    case Lexer.TokenInfo{+kind, text, beg, end, line, col}:
      String.concat([
        kind_name(kind), ":", token_text(kind, text),
        "@", Nat.show(beg), "-", Nat.show(end), ":",
        Nat.show(line), ":", Nat.show(col)
      ])

def show_tokens(tokens: List<&2, Lexer.Token>) -> List<&2, String>:
  match tokens:
    case Nil{}:
      Nil{}
    case token <> rest:
      show_token(token) <> show_tokens(rest)

def token_source(tokens: List<&2, Lexer.Token>, acc: String) -> String:
  match tokens:
    case Nil{}:
      acc
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{_, text, _, _, _, _}:
          token_source(rest, acc ++ text)

def token_tags(tokens: List<&2, Lexer.Token>, acc: List<&2, String>) -> List<&2, String>:
  match tokens:
    case Nil{}:
      List.reverse(&2, String, acc)
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{+kind, text, _, _, _, _}:
          token_tags(rest, (kind_name(kind) ++ ":" ++ token_text(kind, text)) <> acc)

def only_end_token(tokens: List<&2, Lexer.Token>) -> Bool:
  match tokens:
    case [Lexer.TokenInfo{Lexer.EndToken{}, _, _, _, _, _}]:
      True{}
    case _:
      False{}

def line_two_column_one(tokens: List<&2, Lexer.Token>, seen_newline: Bool) -> Bool:
  match tokens:
    case Nil{}:
      False{}
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{Lexer.NameToken{}, "b", _, _, line, col}:
          Bool.and(seen_newline, Bool.and(Nat.is_eq(line, 2n), Nat.is_eq(col, 1n)))
        case Lexer.TokenInfo{Lexer.NewlineToken{}, _, _, _, _, _}:
          line_two_column_one(rest, True{})
        case _:
          line_two_column_one(rest, seen_newline)

def report(ok: Bool, name: String) -> IO(Unit):
  match ok:
    case True{}:
      IO.print(name ++ "-ok")
    case False{}:
      IO.print(name ++ "-failed")

law main:
  IO(Unit)

def main():
  source = {"alpha.beta 123n + == # comment\n\"a\\\"é😀\" '\\\\'" : String}
  tokens = Lexer.tokens(source)
  malformed = Lexer.tokens({"\"open" : String})
  tight = {"a.b_9-+<>&~t~0n~1.5e+6~'q'" : String}
  tight_tokens = Lexer.tokens(tight)
  do IO<Unit>:
    IO.print(String.join(show_tokens(tokens), " | "))
    IO.print(String.join(show_tokens(malformed), " | "))
    report(
      Bool.and(
        String.eq(token_source(tight_tokens, ""), tight),
        String.eq(String.join(token_tags(tight_tokens, Nil{}), "|"), "name:a.b_9|symbol:-|symbol:+|symbol:<|symbol:>|symbol:&|symbol:~|name:t|symbol:~|number:0n|symbol:~|number:1.5e+6|symbol:~|char:'q'|end:")
      ),
      "lexer-token-boundaries"
    )
    report(String.eq(token_source(Lexer.tokens({"tail9" : String}), ""), "tail9"), "lexer-name-eof")
    report(only_end_token(Lexer.tokens({"#comment" : String})), "lexer-comment-eof")
    report(line_two_column_one(Lexer.tokens({"a\nb" : String}), False{}), "lexer-newline-position")

#| name:alpha.beta@0-10:1:1 | number:123n@11-15:1:12 | symbol:+@16-17:1:17 | symbol:=@18-19:1:19 | symbol:=@19-20:1:20 | newline:<NL>@29-30:1:30 | string:"a\"é😀"@30-38:2:1 | char:'\\'@39-43:2:10 | end:@43-43:2:14
#| error:"open@0-5:1:1 | end:@5-5:1:6

#| lexer-token-boundaries-ok

#| lexer-name-eof-ok

#| lexer-comment-eof-ok

#| lexer-newline-position-ok
