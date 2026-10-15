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

law main:
  IO(Unit)

def main():
  source = {"alpha.beta 123n + == # comment\n\"a\\\"é😀\" '\\\\'" : String}
  tokens = Lexer.tokens(source)
  malformed = Lexer.tokens({"\"open" : String})
  do IO<Unit>:
    IO.print(String.join(show_tokens(tokens), " | "))
    IO.print(String.join(show_tokens(malformed), " | "))

#| name:alpha.beta@0-10:1:1 | number:123n@11-15:1:12 | symbol:+@16-17:1:17 | symbol:=@18-19:1:19 | symbol:=@19-20:1:20 | newline:<NL>@29-30:1:30 | string:"a\"é😀"@30-38:2:1 | char:'\\'@39-43:2:10 | end:@43-43:2:14
#| error:"open@0-5:1:1 | end:@5-5:1:6
