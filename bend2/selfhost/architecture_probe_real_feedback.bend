import Base
import ./ast.bend as Ast
import ./lexer.bend as Lexer

# A small protocol check, not a replacement parser. Every recursive call takes
# a directly matched token tail; the AST and tokens are production types.
type Request is Data:
  TermRequest{file: String}
  TermsRequest{file: String, acc: List<&2, Ast.SyntaxTerm>}
  LocalValuesRequest{file: String, line: Nat}

type Kont is Data:
  DoneTerm{}
  DoneTerms{}
  DoneLocalValues{}
  AfterApply{file: String, head: Ast.SyntaxTerm, beg: Nat}
  AfterListItem{file: String, acc: List<&2, Ast.SyntaxTerm>}
  AfterApplyThenList{file: String, head: Ast.SyntaxTerm, beg: Nat}

type Outcome is Data:
  TermValue{term: Ast.SyntaxTerm, rest: List<&2, Lexer.Token>, ok: Bool}
  TermsValue{terms: List<&2, Ast.SyntaxTerm>, rest: List<&2, Lexer.Token>, ok: Bool}
  LocalValuesValue{values: List<&2, Ast.SyntaxTerm>, rest: List<&2, Lexer.Token>, line: Nat, ok: Bool}

def ref(file: String, key: String, beg: Nat, end: Nat) -> Ast.SyntaxTerm:
  Ast.TermRef{key, Ast.SpanOf{file, beg, end}}

def apply(file: String, head: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, beg: Nat, end: Nat) -> Ast.SyntaxTerm:
  Ast.TermApp{head, arg, Ast.SpanOf{file, beg, end}}

# This ordinary, nonrecursive helper builds a request; it is not a machine state.
def prepare_terms(file: String, acc: List<&2, Ast.SyntaxTerm>) -> Request:
  TermsRequest{file, acc}

def drive(+tokens: List<&2, Lexer.Token>, request: Request, kont: Kont) -> Outcome:
  match tokens request kont:
    case Lexer.TokenInfo{Lexer.NameToken{}, key, +beg, end, _, _} <> (Lexer.TokenInfo{Lexer.SymbolToken{}, "(", _, _, _, _} <> +rest) TermRequest{+file} DoneTerm{}:
      drive(rest, TermRequest{file}, AfterApply{file, ref(file, key, beg, end), beg})
    case Lexer.TokenInfo{Lexer.NameToken{}, key, +beg, end, _, _} <> (Lexer.TokenInfo{Lexer.SymbolToken{}, "(", _, _, _, _} <> +rest) TermRequest{+file} DoneTerms{}:
      drive(rest, TermRequest{file}, AfterApplyThenList{file, ref(file, key, beg, end), beg})
    case Lexer.TokenInfo{Lexer.NameToken{}, key, beg, end, _, _} <> rest TermRequest{file} DoneTerm{}:
      TermValue{ref(file, key, beg, end), rest, True{}}
    case Lexer.TokenInfo{Lexer.NameToken{}, key, beg, end, _, _} <> (Lexer.TokenInfo{Lexer.SymbolToken{}, ")", _, close_end, _, _} <> rest) TermRequest{_} AfterApply{+file, head, start}:
      TermValue{apply(file, head, ref(file, key, beg, end), start, close_end), rest, True{}}
    case Lexer.TokenInfo{Lexer.NameToken{}, key, beg, end, _, _} <> (Lexer.TokenInfo{Lexer.SymbolToken{}, ")", _, close_end, _, _} <> +rest) TermRequest{_} AfterApplyThenList{+file, head, start}:
      drive(rest, prepare_terms(file, [apply(file, head, ref(file, key, beg, end), start, close_end)]), DoneTerms{})
    case Lexer.TokenInfo{Lexer.NameToken{}, key, beg, end, _, _} <> (Lexer.TokenInfo{Lexer.SymbolToken{}, ",", _, _, _, _} <> +rest) TermsRequest{+file, acc} DoneTerms{}:
      drive(rest, TermRequest{file}, AfterListItem{file, ref(file, key, beg, end) <> acc})
    case Lexer.TokenInfo{Lexer.NameToken{}, key, beg, end, _, _} <> (Lexer.TokenInfo{Lexer.SymbolToken{}, ";", _, _, _, _} <> rest) TermsRequest{file, acc} DoneTerms{}:
      TermsValue{List.reverse(&2, Ast.SyntaxTerm, ref(file, key, beg, end) <> acc), rest, True{}}
    case Lexer.TokenInfo{Lexer.NameToken{}, key, beg, end, _, _} <> (Lexer.TokenInfo{Lexer.SymbolToken{}, ";", _, _, _, _} <> rest) TermRequest{file} AfterListItem{_, acc}:
      TermsValue{List.reverse(&2, Ast.SyntaxTerm, ref(file, key, beg, end) <> acc), rest, True{}}
    case Lexer.TokenInfo{Lexer.NameToken{}, key, beg, end, _, _} <> (Lexer.TokenInfo{Lexer.SymbolToken{}, ";", _, _, _, _} <> rest) LocalValuesRequest{file, line} DoneLocalValues{}:
      LocalValuesValue{ref(file, key, beg, end) <> Nil{}, rest, line, True{}}
    case _ TermRequest{file} _:
      TermValue{Ast.TermHole{"failure", Ast.SpanOf{file, 0n, 0n}}, tokens, False{}}
    case _ TermsRequest{_, _} _:
      TermsValue{Nil{}, tokens, False{}}
    case _ LocalValuesRequest{_, line} _:
      LocalValuesValue{Nil{}, tokens, line, False{}}

def term_payload(term: Ast.SyntaxTerm, rest: List<&2, Lexer.Token>, ok: Bool) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  ((term, rest), ok)

def terms_payload(terms: List<&2, Ast.SyntaxTerm>, rest: List<&2, Lexer.Token>, ok: Bool) -> (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool:
  ((terms, rest), ok)

def local_payload(values: List<&2, Ast.SyntaxTerm>, rest: List<&2, Lexer.Token>, line: Nat, ok: Bool) -> ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Nat) & Bool:
  (((values, rest), line), ok)

def check_application_payload(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool) -> Bool:
  match result:
    case ((Ast.TermApp{Ast.TermRef{"f", Ast.SpanOf{"source", 1n, 2n}}, Ast.TermRef{"x", Ast.SpanOf{"source", 4n, 5n}}, Ast.SpanOf{"source", 1n, 6n}}, Lexer.TokenInfo{Lexer.EndToken{}, _, 9n, 9n, _, _} <> Nil{}), True{}): True{}
    case _: False{}

def check_application(result: Outcome) -> Bool:
  match result:
    case TermValue{term, rest, ok}:
      check_application_payload(term_payload(term, rest, ok))
    case _: False{}

def check_terms_payload(result: (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool) -> Bool:
  match result:
    case (([Ast.TermApp{Ast.TermRef{"f", Ast.SpanOf{"source", 1n, 2n}}, Ast.TermRef{"x", Ast.SpanOf{"source", 4n, 5n}}, Ast.SpanOf{"source", 1n, 6n}}, Ast.TermRef{"y", Ast.SpanOf{"source", 8n, 9n}}], Lexer.TokenInfo{Lexer.EndToken{}, _, 12n, 12n, _, _} <> Nil{}), True{}): True{}
    case _: False{}

def check_terms(result: Outcome) -> Bool:
  match result:
    case TermsValue{terms, rest, ok}:
      check_terms_payload(terms_payload(terms, rest, ok))
    case _: False{}

def check_list_payload(result: (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool) -> Bool:
  match result:
    case (([Ast.TermRef{"a", Ast.SpanOf{"source", 1n, 2n}}, Ast.TermRef{"b", Ast.SpanOf{"source", 4n, 5n}}], Lexer.TokenInfo{Lexer.EndToken{}, _, 8n, 8n, _, _} <> Nil{}), True{}): True{}
    case _: False{}

def check_list(result: Outcome) -> Bool:
  match result:
    case TermsValue{terms, rest, ok}:
      check_list_payload(terms_payload(terms, rest, ok))
    case _: False{}

def check_local_payload(result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Nat) & Bool) -> Bool:
  match result:
    case ((([Ast.TermRef{"v", Ast.SpanOf{"source", 1n, 2n}}], Lexer.TokenInfo{Lexer.EndToken{}, _, 4n, 4n, _, _} <> Nil{}), 7n), True{}): True{}
    case _: False{}

def check_local(result: Outcome) -> Bool:
  match result:
    case LocalValuesValue{values, rest, line, ok}:
      check_local_payload(local_payload(values, rest, line, ok))
    case _: False{}

def text(ok: Bool) -> String:
  match ok:
    case True{}: "true"
    case False{}: "false"

law main:
  IO(Unit)

def main():
  IO.print(String.concat(["application=", text(check_application(drive([Lexer.TokenInfo{Lexer.NameToken{}, "f", 1n, 2n, 1n, 1n}, Lexer.TokenInfo{Lexer.SymbolToken{}, "(", 3n, 4n, 1n, 3n}, Lexer.TokenInfo{Lexer.NameToken{}, "x", 4n, 5n, 1n, 4n}, Lexer.TokenInfo{Lexer.SymbolToken{}, ")", 5n, 6n, 1n, 5n}, Lexer.TokenInfo{Lexer.EndToken{}, "", 9n, 9n, 1n, 9n}], TermRequest{"source"}, DoneTerm{}))), ";nested=", text(check_terms(drive([Lexer.TokenInfo{Lexer.NameToken{}, "f", 1n, 2n, 1n, 1n}, Lexer.TokenInfo{Lexer.SymbolToken{}, "(", 3n, 4n, 1n, 3n}, Lexer.TokenInfo{Lexer.NameToken{}, "x", 4n, 5n, 1n, 4n}, Lexer.TokenInfo{Lexer.SymbolToken{}, ")", 5n, 6n, 1n, 5n}, Lexer.TokenInfo{Lexer.NameToken{}, "y", 8n, 9n, 1n, 8n}, Lexer.TokenInfo{Lexer.SymbolToken{}, ";", 9n, 10n, 1n, 9n}, Lexer.TokenInfo{Lexer.EndToken{}, "", 12n, 12n, 1n, 12n}], TermRequest{"source"}, DoneTerms{}))), ";list=", text(check_list(drive([Lexer.TokenInfo{Lexer.NameToken{}, "a", 1n, 2n, 1n, 1n}, Lexer.TokenInfo{Lexer.SymbolToken{}, ",", 2n, 3n, 1n, 2n}, Lexer.TokenInfo{Lexer.NameToken{}, "b", 4n, 5n, 1n, 4n}, Lexer.TokenInfo{Lexer.SymbolToken{}, ";", 5n, 6n, 1n, 5n}, Lexer.TokenInfo{Lexer.EndToken{}, "", 8n, 8n, 1n, 8n}], prepare_terms("source", Nil{}), DoneTerms{}))), ";local=", text(check_local(drive([Lexer.TokenInfo{Lexer.NameToken{}, "v", 1n, 2n, 1n, 1n}, Lexer.TokenInfo{Lexer.SymbolToken{}, ";", 2n, 3n, 1n, 2n}, Lexer.TokenInfo{Lexer.EndToken{}, "", 4n, 4n, 1n, 4n}], LocalValuesRequest{"source", 7n}, DoneLocalValues{})))]))

#| application=true;nested=true;list=true;local=true
