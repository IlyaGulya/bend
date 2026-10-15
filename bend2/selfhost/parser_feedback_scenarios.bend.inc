
# PF1 canonical values encode strings as arrays of Unicode scalar numbers.
def parity_codes_tail(s: String) -> String:
  match s:
    case SNil{}: ""
    case SCon{head, tail}:
      String.concat([",", U32.show(Char.to_u32(head)), parity_codes_tail(tail)])
def parity_codes(s: String) -> String:
  match s:
    case SNil{}: ""
    case SCon{head, tail}:
      String.concat([U32.show(Char.to_u32(head)), parity_codes_tail(tail)])
def parity_string(s: String) -> String:
  String.concat(["[", parity_codes(s), "]"])
def parity_span(span: Ast.SourceSpan) -> String:
  match span:
    case Ast.SpanOf{file, beg, end}:
      String.concat(["[", parity_string(file), ",", Nat.show(beg), ",", Nat.show(end), "]"])
def parity_quantity(q: Ast.Quantity) -> String:
  match q:
    case Ast.QZero{}: "0"
    case Ast.QOne{}: "1"
    case Ast.QMany{}: "2"
def parity_optional_quantity(q: Maybe<&2, Ast.Quantity>) -> String:
  match q:
    case None{}: "null"
    case Some{value}: parity_quantity(value)
def parity_ast(term: Ast.SyntaxTerm) -> String:
  match term:
    case Ast.TermVar{key, index, _}:
      String.concat(["[\"Var\",", parity_string(key), ",", Nat.show(index), "]"])
    case Ast.TermRef{key, _}: String.concat(["[\"Ref\",", parity_string(key), "]"])
    case Ast.TermApp{fn, arg, _}:
      String.concat(["[\"App\",", parity_ast(fn), ",", parity_ast(arg), "]"])
    case Ast.TermLam{q, key, index, body, _}:
      String.concat(["[\"Lam\",", parity_optional_quantity(q), ",", parity_string(key), ",", Nat.show(index), ",", parity_ast(body), "]"])
    case Ast.TermAnn{term, ty, _}:
      String.concat(["[\"Ann\",", parity_ast(term), ",", parity_ast(ty), "]"])
    case Ast.TermType{kind, _}: String.concat(["[\"Typ\",", parity_ast(kind), "]"])
    case Ast.TermQuantity{q, _}: String.concat(["[\"Qua\",", parity_quantity(q), "]"])
    case Ast.TermQuant{}: "[\"Qnt\"]"
    case Ast.TermHole{key, _}: String.concat(["[\"Hol\",", parity_string(key), "]"])
    case _: "[\"UNSUPPORTED_AST\"]"
def parity_spans(term: Ast.SyntaxTerm) -> List<&2, String>:
  match term:
    case Ast.TermVar{_, _, span}: [parity_span(span)]
    case Ast.TermRef{_, span}: [parity_span(span)]
    case Ast.TermApp{fn, arg, span}:
      parity_span(span) <> List.append(&2, String, parity_spans(fn), parity_spans(arg))
    case Ast.TermLam{_, _, _, body, span}: parity_span(span) <> parity_spans(body)
    case Ast.TermAnn{term, ty, span}:
      parity_span(span) <> List.append(&2, String, parity_spans(term), parity_spans(ty))
    case Ast.TermType{kind, span}: parity_span(span) <> parity_spans(kind)
    case Ast.TermQuantity{_, span}: [parity_span(span)]
    case Ast.TermHole{_, span}: [parity_span(span)]
    case _: Nil{}
def parity_kind(kind: Lexer.TokenKind) -> String:
  match kind:
    case Lexer.NameToken{}: "NameToken"
    case Lexer.NumberToken{}: "NumberToken"
    case Lexer.StringToken{}: "StringToken"
    case Lexer.CharToken{}: "CharToken"
    case Lexer.SymbolToken{}: "SymbolToken"
    case Lexer.NewlineToken{}: "NewlineToken"
    case Lexer.EndToken{}: "EndToken"
    case Lexer.ErrorToken{}: "ErrorToken"
def parity_token(token: Lexer.Token) -> String:
  match token:
    case Lexer.TokenInfo{kind, text, beg, end, line, col}:
      String.concat(["[\"", parity_kind(kind), "\",", parity_string(text), ",", Nat.show(beg), ",", Nat.show(end), ",", Nat.show(line), ",", Nat.show(col), "]"])
def parity_tokens(tokens: List<&2, Lexer.Token>) -> List<&2, String>:
  match tokens:
    case Nil{}: Nil{}
    case head <> tail: parity_token(head) <> parity_tokens(tail)
def parity_row(id: String, result: FeedbackRun) -> IO(Unit):
  match result:
    case FeedbackComplete{+term, rest, +ok}:
      IO.print(String.concat(["PF1\t", id, "\t", Bool.pick(String, ok, "1", "0"), "\t", Bool.pick(String, ok, parity_ast(term), "null"), "\t[", String.join(parity_spans(term), ","), "]\t[", String.join(parity_tokens(rest), ","), "]"]))
    case FeedbackInvariantFailure{}:
      IO.print(String.append("PFINVARIANT\t", id))

def main() -> IO(Unit):
  IO.bind(Unit, Unit, parity_row("simple_return_header", feedback_entry_parse_term("simple_return_header.bend", harness_tokens("do M: return x"), [Scope{"x", 0n}, Scope{"T", 1n}, Scope{"op", 2n}, Scope{"action", 3n}, Scope{"action2", 4n}, Scope{"f", 5n}, Scope{"g", 6n}, Scope{"Unit", 7n}], 8n, 0n)), _ => IO.bind(Unit, Unit, parity_row("action_then_return", feedback_entry_parse_term("action_then_return.bend", harness_tokens("do M<>: action; return x"), [Scope{"x", 0n}, Scope{"T", 1n}, Scope{"op", 2n}, Scope{"action", 3n}, Scope{"action2", 4n}, Scope{"f", 5n}, Scope{"g", 6n}, Scope{"Unit", 7n}], 8n, 0n)), _ => IO.bind(Unit, Unit, parity_row("untyped_bind_then_return", feedback_entry_parse_term("untyped_bind_then_return.bend", harness_tokens("do M<>: T <- op; return x"), [Scope{"x", 0n}, Scope{"T", 1n}, Scope{"op", 2n}, Scope{"action", 3n}, Scope{"action2", 4n}, Scope{"f", 5n}, Scope{"g", 6n}, Scope{"Unit", 7n}], 8n, 0n)), _ => IO.bind(Unit, Unit, parity_row("typed_bind", feedback_entry_parse_term("typed_bind.bend", harness_tokens("do M<>: x: T <- op; return x"), [Scope{"x", 0n}, Scope{"T", 1n}, Scope{"op", 2n}, Scope{"action", 3n}, Scope{"action2", 4n}, Scope{"f", 5n}, Scope{"g", 6n}, Scope{"Unit", 7n}], 8n, 0n)), _ => IO.bind(Unit, Unit, parity_row("two_operations", feedback_entry_parse_term("two_operations.bend", harness_tokens("do M<>: action; action2; return x"), [Scope{"x", 0n}, Scope{"T", 1n}, Scope{"op", 2n}, Scope{"action", 3n}, Scope{"action2", 4n}, Scope{"f", 5n}, Scope{"g", 6n}, Scope{"Unit", 7n}], 8n, 0n)), _ => IO.bind(Unit, Unit, parity_row("nested_expression", feedback_entry_parse_term("nested_expression.bend", harness_tokens("do M<>: return f(g(x))"), [Scope{"x", 0n}, Scope{"T", 1n}, Scope{"op", 2n}, Scope{"action", 3n}, Scope{"action2", 4n}, Scope{"f", 5n}, Scope{"g", 6n}, Scope{"Unit", 7n}], 8n, 0n)), _ => IO.bind(Unit, Unit, parity_row("malformed_body", feedback_entry_parse_term("malformed_body.bend", harness_tokens("do M<>: return"), [Scope{"x", 0n}, Scope{"T", 1n}, Scope{"op", 2n}, Scope{"action", 3n}, Scope{"action2", 4n}, Scope{"f", 5n}, Scope{"g", 6n}, Scope{"Unit", 7n}], 8n, 0n)), _ => IO.bind(Unit, Unit, parity_row("success_remainder", feedback_entry_parse_term("success_remainder.bend", harness_tokens("do M<>: return x ) tail"), [Scope{"x", 0n}, Scope{"T", 1n}, Scope{"op", 2n}, Scope{"action", 3n}, Scope{"action2", 4n}, Scope{"f", 5n}, Scope{"g", 6n}, Scope{"Unit", 7n}], 8n, 0n)), _ => IO.bind(Unit, Unit, parity_row("failure_remainder", feedback_entry_parse_term("failure_remainder.bend", harness_tokens("do M<>: x: T <- ) tail"), [Scope{"x", 0n}, Scope{"T", 1n}, Scope{"op", 2n}, Scope{"action", 3n}, Scope{"action2", 4n}, Scope{"f", 5n}, Scope{"g", 6n}, Scope{"Unit", 7n}], 8n, 0n)), _ => IO.pure(Unit, Unit{}))))))))))
