# Generated from repaired parser source by evals/parser_feedback_generate.ts
import Base
import ./ast.bend as Ast
import ./lexer.bend as Lexer
import ./core.bend as Core

type Scope is Data:
  Scope{key: String, index: Nat}

type FeedbackKont is Data:
  Kont_120515{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Nat, capture_5: Nat}
  Kont_166750{file: String, scope: List<&2, Scope>, depth: Nat, level: Nat}
  Kont_117083{capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Lexer.Token>}

type FeedbackRequest is Data:
  Request_parse_do_return_scan{file: String, key: String, args: List<&2, Ast.SyntaxTerm>, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat}
  Request_parse_term{file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat}
  Request_parse_atom{file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat}
  Request_parse_atom_scan{file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat}
  Request_parse_do_atom{file: String, tokens: List<&2, Lexer.Token>, beg: Nat, scope: List<&2, Scope>, depth: Nat}
  Request_parse_do_atom_args_result{result: (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool, file: String, key: String, beg: Nat, end: Nat, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat}
  Request_parse_do_atom_colon{colon: Lexer.Token, after_colon: List<&2, Lexer.Token>, args: List<&2, Ast.SyntaxTerm>, file: String, key: String, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat}
  Request_parse_do_return{file: String, key: String, args: List<&2, Ast.SyntaxTerm>, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat}

type FeedbackStep is Data:
  FeedbackRequest{request: FeedbackRequest, kont: List<&2, FeedbackKont>}
  FeedbackTerm{term: Ast.SyntaxTerm, rest: List<&2, Lexer.Token>, ok: Bool}

type FeedbackRun is Data:
  FeedbackComplete{term: Ast.SyntaxTerm, rest: List<&2, Lexer.Token>, ok: Bool}
  FeedbackInvariantFailure{}


def feedback_pack(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool) -> FeedbackStep:
  match result:
    case ((term, rest), ok): FeedbackTerm{term, rest, ok}

# Restricted outbound grammar harness for the eight-definition feedback POC.
# Canonical parser.bend is the branch-semantics reference; it is not imported.
# Selected -> unselected dependencies (all 24; exact signatures below):
# parse_do_atom_colon: do_first_col, span, token_beg, token_end.
# parse_do_atom_args_result: span.
# parse_do_atom: parse_term_args, span, token_beg, token_end.
# parse_atom_scan: parse_kind_result, parse_name_term, parse_number, parse_list,
#   parse_parenthesized, parse_rewrite, parse_all, parse_amp, parse_many_lambda,
#   parse_absurd, parse_template_term, parse_brace, parse_string,
#   parse_char_literal, span, token_beg, token_end.
# parse_atom: skip_lines.
# parse_do_return_scan: parse_do_return_value_result, parse_do_typed_bind, span.
# parse_do_return: skip_lines.
# parse_term: with_term_result, parse_term_atom_result.
#
# The bounded do/name/args/application helpers below retain production bodies.
# Their only selected-entry callbacks are parse_term and parse_do_return, whose
# tuple-result wrappers are supplied by the generator (forward references).
# Grammar covered: return, action sequencing, untyped type <- value binding,
# named typed binding/assignment, arbitrary operation chains, scoped names,
# lambdas, constructors, argument lists, nested calls/parentheses, Kind, and
# integer literals. The untyped bind introduces '_' rather than a named scope
# entry, exactly as production does. Newline/semicolon and do indentation rules
# are production rules. No correction is made for `do M:`, which must fail;
# the production entry requires `<` and a closing parameter delimiter.
#
# Grammar adapters: parse_term_tail supports calls and production delimiters,
# parse_parenthesized supports term tuples, parse_nat_literal supports literals
# without additive tails, and parse_number_missing_nat rejects non-integers.
# Unsupported syntax is a False result containing an explicit harness hole
# and the unconsumed remainder: list, rewrite, forall/amp, many-lambda, absurd,
# brace, string/character, operators, typed-parenthesis/body fallback, and float.
# These are declared limitations, not production parser error emulations.

def with_term_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, use: Ast.SyntaxTerm -> List<&2, Lexer.Token> -> Bool -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((term, after), ok):
      use(term, after, ok)

def with_args_result(result: (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool, use: List<&2, Ast.SyntaxTerm> -> List<&2, Lexer.Token> -> Bool -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((args, after), ok):
      use(args, after, ok)

def with_term_to_args(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, use: Ast.SyntaxTerm -> List<&2, Lexer.Token> -> Bool -> (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool) -> (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((term, after), ok):
      use(term, after, ok)

def with_term_bool(result: Ast.SyntaxTerm & Bool, use: Ast.SyntaxTerm -> Bool -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case (term, ok):
      use(term, ok)

def span(file: String, beg: Nat, end: Nat) -> Ast.SourceSpan:
  Ast.SpanOf{file, beg, end}

def token_text(token: Lexer.Token) -> String:
  match token:
    case Lexer.TokenInfo{ _, text,  _,  _,  _,  _}:
      text

def token_beg(token: Lexer.Token) -> Nat:
  match token:
    case Lexer.TokenInfo{ _,  _, beg,  _,  _,  _}:
      beg

def token_end(token: Lexer.Token) -> Nat:
  match token:
    case Lexer.TokenInfo{ _,  _,  _, end,  _,  _}:
      end

def skip_lines(tokens: List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:
  match tokens:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{ Lexer.NewlineToken{},  _,  _,  _,  _,  _}:
          skip_lines(rest)
        case _:
          tokens
    case Nil{}:
      Nil{}

def lookup_result(+key: String, rest: List<&2, Scope>, +depth: Nat) -> Maybe<&2, Nat>:
  match rest:
    case +entry <> after:
      match entry:
        case Scope{ found, index}:
          Bool.pick(Maybe<&2, Nat>, String.eq(key, found), Some{depth - index - 1n}, lookup_result(key, after, depth))
    case Nil{}:
      None{}

def lookup(+key: String, scope: List<&2, Scope>, +depth: Nat) -> Maybe<&2, Nat>:
  match scope:
    case +entry <> rest:
      match entry:
        case Scope{ found, index}:
          Bool.pick(Maybe<&2, Nat>, String.eq(key, found), Some{depth - index - 1n}, lookup_result(key, rest, depth))
    case Nil{}:
      None{}

def extend_scope_result(is_underscore: Bool, key: String, index: Nat, scope: List<&2, Scope>) -> List<&2, Scope>:
  match is_underscore:
    case True{}:
      scope
    case False{}:
      Scope{key, index} <> scope

def extend_scope(+key: String, index: Nat, scope: List<&2, Scope>) -> List<&2, Scope>:
  extend_scope_result(String.eq(key, "_"), key, index, scope)

def parse_kind_close(close: Lexer.Token, tail: List<&2, Lexer.Token>, term: Ast.SyntaxTerm, file: String, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match close:
    case Lexer.TokenInfo{_, ")", _, close_end, _, _}:
      ((Ast.TermType{term, span(file, beg, close_end)}, tail), True{})
    case Lexer.TokenInfo{_, _, close_beg, close_end, _, _}:
      ((Ast.TermHole{"parse-error: expected )", span(file, close_beg, close_end)}, tail), False{})

def parse_kind_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((term, +close <> tail), True{}):
      parse_kind_close(close, tail, term, file, beg)
    case (_, False{}):
      ((Ast.TermHole{"parse-error: expected a term", span(file, beg, end)}, rest), False{})
    case _:
      ((Ast.TermHole{"parse-error: expected a term", span(file, beg, end)}, rest), False{})

def parse_do_typed_bind_call_result(result: Ast.SyntaxTerm & Bool, after_body: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case (call, ok_call):
      ((call, after_body), ok_call)

def parse_do_bind_call_result(result: Ast.SyntaxTerm & Bool, after_body: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case (call, ok_call):
      ((call, after_body), ok_call)

def do_first_col(tokens: List<&2, Lexer.Token>) -> Nat:
  match tokens:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{ Lexer.NewlineToken{},  _,  _,  _,  _,  _}:
          do_first_col(rest)
        case Lexer.TokenInfo{ _,  _,  _,  _,  _, col}:
          col
    case Nil{}:
      0n

def do_has_more(tokens: List<&2, Lexer.Token>, col: Nat) -> Bool:
  match tokens:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{ Lexer.NewlineToken{},  _,  _,  _,  _,  _}:
          do_has_more(rest, col)
        case Lexer.TokenInfo{ _, ";",  _,  _,  _,  _}:
          True{}
        case Lexer.TokenInfo{ _, ")",  _,  _,  _,  _}:
          False{}
        case Lexer.TokenInfo{ _, "]",  _,  _,  _,  _}:
          False{}
        case Lexer.TokenInfo{ _, "}",  _,  _,  _,  _}:
          False{}
        case Lexer.TokenInfo{ Lexer.EndToken{},  _,  _,  _,  _,  _}:
          False{}
        case Lexer.TokenInfo{ _,  _,  _,  _,  _, next_col}:
          Nat.is_eq(col, next_col)
    case Nil{}:
      False{}

def skip_rewrite_semicolon(tokens: List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:
  match tokens:
    case +semicolon <> rest:
      match semicolon:
        case Lexer.TokenInfo{ _, ";",  _,  _,  _,  _}: rest
        case _: tokens
    case Nil{}:
      Nil{}

def parse_do_return_call_result(result: Ast.SyntaxTerm & Bool, after_value: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case (call, True{}):
      ((call, skip_rewrite_semicolon(after_value)), True{})
    case (call, False{}):
      ((call, after_value), False{})

def parse_name_term_lookup(found: Maybe<&2, Nat>, file: String, key: String, beg: Nat, end: Nat, tokens: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match found:
    case Some{index}:
      ((Ast.TermVar{key, index,  span(file, beg, end)}, tokens), True{})
    case None{}:
      ((Ast.TermRef{key,  span(file, beg, end)}, tokens), True{})

def token_end_of(tokens: List<&2, Lexer.Token>, fallback: Nat) -> Nat:
  match tokens:
    case +token <> _:
      token_beg(token)
    case Nil{}:
      fallback

def token_beg_first(term: Ast.SyntaxTerm) -> Nat:
  match term:
    case Ast.TermVar{ _,  _,  Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.TermRef{ _,  Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.TermBang{ _,  Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.TermAll{ _,  _,  _,  _,  _,  Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.TermMin{ _,  _,  Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.TermApp{ _,  _,  Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.TermLam{ _,  _,  _,  _,  Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.TermType{ _,  Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.TermQuantity{ _,  Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.TermCtr{ _,  _,  Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.TermAdt{ _,  _,  _,  Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.TermMat{ _,  _,  _,  Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.TermAbsurd{ Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.TermEqual{ _,  _,  _,  Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.TermRefl{ Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.TermRewrite{ _,  _,  _,  Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.TermLet{ _,  _,  _,  _,  _,  Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.TermAnn{ _,  _,  Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.TermTemplate{ _,  Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.TermFill{ _,  _,  Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.TermPlus{ _,  _,  Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.TermHole{ _,  Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.BodyMatch{ _,  _,  Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.BodyCase{ _,  _,  Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.BodyLocal{ _,  _,  _,  _,  Ast.SpanOf{ _, beg,  _}}: beg
    case Ast.BodyReply{ _,  Ast.SpanOf{ _, beg,  _}}: beg
    case _:
      0n

def token_end_first(term: Ast.SyntaxTerm) -> Nat:
  match term:
    case Ast.TermVar{ _,  _,  Ast.SpanOf{ _,  _, end}}: end
    case Ast.TermRef{ _,  Ast.SpanOf{ _,  _, end}}: end
    case Ast.TermBang{ _,  Ast.SpanOf{ _,  _, end}}: end
    case Ast.TermAll{ _,  _,  _,  _,  _,  Ast.SpanOf{ _,  _, end}}: end
    case Ast.TermMin{ _,  _,  Ast.SpanOf{ _,  _, end}}: end
    case Ast.TermApp{ _,  _,  Ast.SpanOf{ _,  _, end}}: end
    case Ast.TermLam{ _,  _,  _,  _,  Ast.SpanOf{ _,  _, end}}: end
    case Ast.TermType{ _,  Ast.SpanOf{ _,  _, end}}: end
    case Ast.TermQuantity{ _,  Ast.SpanOf{ _,  _, end}}: end
    case Ast.TermCtr{ _,  _,  Ast.SpanOf{ _,  _, end}}: end
    case Ast.TermAdt{ _,  _,  _,  Ast.SpanOf{ _,  _, end}}: end
    case Ast.TermMat{ _,  _,  _,  Ast.SpanOf{ _,  _, end}}: end
    case Ast.TermAbsurd{ Ast.SpanOf{ _,  _, end}}: end
    case Ast.TermEqual{ _,  _,  _,  Ast.SpanOf{ _,  _, end}}: end
    case Ast.TermRefl{ Ast.SpanOf{ _,  _, end}}: end
    case Ast.TermRewrite{ _,  _,  _,  Ast.SpanOf{ _,  _, end}}: end
    case Ast.TermLet{ _,  _,  _,  _,  _,  Ast.SpanOf{ _,  _, end}}: end
    case Ast.TermAnn{ _,  _,  Ast.SpanOf{ _,  _, end}}: end
    case Ast.TermTemplate{ _,  Ast.SpanOf{ _,  _, end}}: end
    case Ast.TermFill{ _,  _,  Ast.SpanOf{ _,  _, end}}: end
    case Ast.TermPlus{ _,  _,  Ast.SpanOf{ _,  _, end}}: end
    case Ast.TermHole{ _,  Ast.SpanOf{ _,  _, end}}: end
    case Ast.BodyMatch{ _,  _,  Ast.SpanOf{ _,  _, end}}: end
    case Ast.BodyCase{ _,  _,  Ast.SpanOf{ _,  _, end}}: end
    case Ast.BodyLocal{ _,  _,  _,  _,  Ast.SpanOf{ _,  _, end}}: end
    case Ast.BodyReply{ _,  Ast.SpanOf{ _,  _, end}}: end
    case _:
      0n

def append_terms(left: List<&2, Ast.SyntaxTerm>, right: List<&2, Ast.SyntaxTerm>) -> List<&2, Ast.SyntaxTerm>:
  match left:
    case Nil{}:
      right
    case +item <> rest:
      item <> append_terms(rest, right)

def do_call_return_type(return_type: Ast.OptionalTerm, prefix: List<&2, Ast.SyntaxTerm>, after_return: List<&2, Ast.SyntaxTerm>) -> List<&2, Ast.SyntaxTerm>:
  match return_type:
    case Ast.NoTerm{}:
      append_terms(prefix, after_return)
    case Ast.SomeTerm{term}:
      append_terms(append_terms(prefix, [term]), after_return)

def apply_terms(args: List<&2, Ast.SyntaxTerm>, +file: String, +head: Ast.SyntaxTerm, +beg: Nat) -> Ast.SyntaxTerm & Bool:
  match args:
    case Nil{}:
      (head, True{})
    case +arg <> rest:
      apply_terms(rest, file, Ast.TermApp{head, arg, span(file, beg, token_end_first(arg))}, beg)

def do_call_from_split(split: List<&2, Ast.SyntaxTerm> & Ast.OptionalTerm, +file: String, monad: String, operation: String, before_return: List<&2, Ast.SyntaxTerm>, after_return: List<&2, Ast.SyntaxTerm>, +beg: Nat, end: Nat) -> Ast.SyntaxTerm & Bool:
  match split:
    case (leading, return_type):
      prefix = append_terms(leading, before_return)
      all = do_call_return_type(return_type, prefix, after_return)
      apply_terms(all, file, Ast.TermRef{String.append(String.append(monad, "."), operation), span(file, beg, end)}, beg)

def split_last_do_args(args: List<&2, Ast.SyntaxTerm>, acc: List<&2, Ast.SyntaxTerm>) -> List<&2, Ast.SyntaxTerm> & Ast.OptionalTerm:
  match args:
    case Nil{}:
      (List.reverse(&2, Ast.SyntaxTerm, acc), Ast.NoTerm{})
    case +item <> rest:
      match rest:
        case Nil{}:
          (List.reverse(&2, Ast.SyntaxTerm, acc), Ast.SomeTerm{item})
        case _:
          split_last_do_args(rest, item <> acc)

def do_call(file: String, monad: String, operation: String, args: List<&2, Ast.SyntaxTerm>, before_return: List<&2, Ast.SyntaxTerm>, after_return: List<&2, Ast.SyntaxTerm>, beg: Nat, end: Nat) -> Ast.SyntaxTerm & Bool:
  do_call_from_split(split_last_do_args(args, Nil{}), file, monad, operation, before_return, after_return, beg, end)

def parse_do_return_value_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, key: String, args: List<&2, Ast.SyntaxTerm>, beg: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((value, after_value), True{}):
      parse_do_return_call_result(do_call(file, key, "pure", args, Nil{}, [value], beg, end), after_value)
    case ((value, after_value), False{}):
      ((value, after_value), False{})

def parse_do_typed_bind_body_result(ok_body: Bool, body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, +file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, key: String, key_beg: Nat, ty: Ast.SyntaxTerm, +value: Ast.SyntaxTerm, beg: Nat, end: Nat, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      local_span = span(file, key_beg, token_end_of(after_body, token_end_first(value)))
      parse_do_typed_bind_call_result(do_call(file, monad, "bind", args, [ty], [value, Ast.TermLam{None{}, key, depth, body, local_span}], beg, end), after_body)
    case False{}:
      ((body, after_body), False{})

def parse_do_bind_body_result(ok_body: Bool, body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, +file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, ty: Ast.SyntaxTerm, +value: Ast.SyntaxTerm, +beg: Nat, end: Nat, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      parse_do_bind_call_result(do_call(file, monad, "bind", args, [ty], [value, Ast.TermLam{None{}, "_", depth, body, span(file, beg, token_end_of(after_body, token_end_first(value)))}], beg, end), after_body)
    case False{}:
      ((body, after_body), False{})

def make_do_assignment_term(+file: String, key: String, +key_beg: Nat, depth: Nat, ty: Ast.SyntaxTerm, +value: Ast.SyntaxTerm, body: Ast.SyntaxTerm, after_body: List<&2, Lexer.Token>) -> Ast.SyntaxTerm:
  +value_end = token_end_first(value)
  value_span = span(file, key_beg, value_end)
  Ast.TermLet{[key], [depth], [Ast.QOne{}], [Ast.TermAnn{value, ty, value_span}], body, span(file, key_beg, token_end_of(after_body, value_end))}

def make_do_assignment_result(term: Ast.SyntaxTerm, after_body: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  ((term, after_body), True{})

def parse_do_assignment_body_result(ok_body: Bool, body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, +file: String, key: String, +key_beg: Nat, depth: Nat, ty: Ast.SyntaxTerm, +value: Ast.SyntaxTerm) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      make_do_assignment_result(make_do_assignment_term(file, key, key_beg, depth, ty, value, body, after_body), after_body)
    case False{}:
      ((body, after_body), False{})

def parse_do_typed_bind_type_token(bind_token: Lexer.Token, after_bind: List<&2, Lexer.Token>, ty: Ast.SyntaxTerm, file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, key: String, key_beg: Nat, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match bind_token:
    case Lexer.TokenInfo{_, "<-", _, _, _, _}:
      parse_do_typed_bind_value_result(parse_term(file, after_bind, scope, depth, 0n), file, monad, args, key, key_beg, ty, beg, end, scope, depth, col)
    case Lexer.TokenInfo{_, "=", _, _, _, _}:
      parse_do_assignment(file, monad, args, key, key_beg, ty, after_bind, beg, end, scope, depth, col)
    case _:
      ((Ast.TermHole{"parse-error: expected <- in do binding", span(file, token_beg(bind_token), token_end(bind_token))}, +bind_token <> after_bind), False{})

def parse_do_typed_bind_type_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, key: String, key_beg: Nat, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((ty, +bind_token <> after_bind), True{}):
      parse_do_typed_bind_type_token(bind_token, after_bind, ty, file, monad, args, key, key_beg, beg, end, scope, depth, col)
    case ((ty, after_ty), False{}):
      ((ty, after_ty), False{})
    case ((ty, after_ty), True{}):
      ((ty, after_ty), False{})

def parse_do_typed_bind_value_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, key: String, key_beg: Nat, ty: Ast.SyntaxTerm, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((value, after_value), True{}):
      next_scope = extend_scope(key, depth, scope)
      with_term_result(parse_do_return(file, monad, args, skip_rewrite_semicolon(after_value), beg, end, next_scope, depth + 1n, col), body => after_body => ok_body => parse_do_typed_bind_body_result(ok_body, body, after_body, file, monad, args, key, key_beg, ty, value, beg, end, depth))
    case ((value, after_value), False{}):
      ((value, after_value), False{})

def parse_do_typed_bind(file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +name <> after_name:
      match name:
        case Lexer.TokenInfo{Lexer.NameToken{}, key, key_beg, _, _, _}:
          match after_name:
            case +colon <> after_colon:
              match colon:
                case Lexer.TokenInfo{_, ":", _, _, _, _}:
                  parse_do_typed_bind_type_result(parse_term(file, after_colon, scope, depth, 1n), file, monad, args, key, key_beg, beg, end, scope, depth, col)
                case _:
                  parse_do_untyped(file, monad, args, tokens, beg, end, scope, depth, col)
            case _:
              parse_do_untyped(file, monad, args, tokens, beg, end, scope, depth, col)
        case _:
          parse_do_untyped(file, monad, args, tokens, beg, end, scope, depth, col)
    case Nil{}:
      ((Ast.TermHole{"parse-error: expected return or a do binding", span(file, beg, end)}, Nil{}), False{})

def parse_do_assignment_value_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, key: String, key_beg: Nat, ty: Ast.SyntaxTerm, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((value, after_value), True{}):
      next_scope = extend_scope(key, depth, scope)
      with_term_result(parse_do_return(file, monad, args, skip_rewrite_semicolon(after_value), beg, end, next_scope, depth + 1n, col), body => after_body => ok_body => parse_do_assignment_body_result(ok_body, body, after_body, file, key, key_beg, depth, ty, value))
    case ((value, after_value), False{}):
      ((value, after_value), False{})

def parse_do_assignment(file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, key: String, key_beg: Nat, ty: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_do_assignment_value_result(parse_term(file, tokens, scope, depth, 0n), file, monad, args, key, key_beg, ty, beg, end, scope, depth, col)

def parse_do_untyped_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((action, after_action), True{}):
      parse_do_untyped_after_action(file, monad, args, action, after_action, skip_rewrite_semicolon(after_action), beg, end, scope, depth, col)
    case ((action, after_action), False{}):
      ((action, after_action), False{})

def parse_do_untyped_value_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, action: Ast.SyntaxTerm, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((value, after_value), True{}):
      parse_do_bind(file, monad, args, action, value, after_value, beg, end, scope, depth, col)
    case ((value, after_value), False{}):
      ((value, after_value), False{})

def parse_do_untyped_after_action(file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, action: Ast.SyntaxTerm, after_action: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match scanned:
    case +bind_token <> after_bind:
      match bind_token:
        case Lexer.TokenInfo{_, "<-", _, _, _, _}:
          parse_do_untyped_value_result(parse_term(file, after_bind, scope, depth, 0n), file, monad, args, action, beg, end, scope, depth, col)
        case _:
          parse_do_untyped_step(file, monad, args, action, after_action, beg, end, scope, depth, col)
    case Nil{}:
      ((action, after_action), True{})

def parse_do_untyped(file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_do_untyped_result(parse_term(file, tokens, scope, depth, 0n), file, monad, args, beg, end, scope, depth, col)

def parse_do_untyped_step(file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, action: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_do_untyped_step_after_check(do_has_more(tokens, col), file, monad, args, action, tokens, beg, end, scope, depth, col)

def parse_do_untyped_step_after_check(has_more: Bool, file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, action: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match has_more:
    case True{}:
      parse_do_bind(file, monad, args, Ast.TermRef{ "Unit",  span(file, beg, end)}, action, tokens, beg, end, scope, depth, col)
    case False{}:
      ((action, tokens), True{})

def parse_do_bind(file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, ty: Ast.SyntaxTerm, value: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  next_scope = extend_scope("_", depth, scope)
  with_term_result(parse_do_return(file, monad, args, skip_rewrite_semicolon(tokens), beg, end, next_scope, depth + 1n, col), body => after_body => ok_body => parse_do_bind_body_result(ok_body, body, after_body, file, monad, args, ty, value, beg, end, depth))

def parse_name_lambda_result(ok: Bool, body: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, file: String, key: String, beg: Nat, end: Nat, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok:
    case True{}:
      ((Ast.TermLam{None{}, key, depth, body, span(file, beg, token_end_of(after, end))}, after), True{})
    case False{}:
      ((body, after), False{})

def parse_name_constructor_result(ok: Bool, args: List<&2, Ast.SyntaxTerm>, +after_args: List<&2, Lexer.Token>, file: String, key: String, beg: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok:
    case True{}:
      ((Ast.TermCtr{key, args, span(file, beg, token_end_of(after_args, end))}, after_args), True{})
    case False{}:
      ((Ast.TermHole{"parse-error: expected constructor fields", span(file, beg, end)}, after_args), False{})

def parse_name_term(file: String, key: String, beg: Nat, end: Nat, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +next <> rest:
      match next:
        case Lexer.TokenInfo{ _, "=>",  _,  _,  _,  _}:
          next_scope = extend_scope(key, depth, scope)
          with_term_result(parse_term(file, rest, next_scope, depth + 1n, 0n), body => after => ok => parse_name_lambda_result(ok, body, after, file, key, beg, end, depth))
        case Lexer.TokenInfo{ _, "{",  _,  _,  _,  _}:
          with_args_result(parse_term_args(file, rest, "}", scope, depth, Nil{}), args => after_args => ok_args => parse_name_constructor_result(ok_args, args, after_args, file, key, beg, end))
        case _:
          parse_name_term_lookup(lookup(key, scope, depth), file, key, beg, end, tokens)
    case Nil{}:
      parse_name_term_lookup(lookup(key, scope, depth), file, key, beg, end, Nil{})

def parse_term_args(file: String, tokens: List<&2, Lexer.Token>, close: String, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.SyntaxTerm>) -> (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +token <> rest:
      parse_term_args_first(Bool.or(String.eq(token_text(token), close), Bool.and(String.eq(close, ">"), String.eq(token_text(token), "<>"))), file, token, rest, tokens, close, scope, depth, acc)
    case Nil{}:
      ((List.reverse(&2, Ast.SyntaxTerm, acc), Nil{}), False{})

def parse_term_args_first_result(ok: Bool, term: Ast.SyntaxTerm, after: List<&2, Lexer.Token>, file: String, tokens: List<&2, Lexer.Token>, close: String, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.SyntaxTerm>) -> (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool:
  match ok after:
    case True{} +separator <> tail:
      match separator:
        case Lexer.TokenInfo{ _, ",",  _,  _,  _,  _}:
          parse_term_args(file, tail, close, scope, depth, term <> acc)
        case _:
          parse_term_args_after_separator(String.eq(token_text(separator), close), file, term, after, tail, close, scope, depth, acc)
    case _ _:
      ((List.reverse(&2, Ast.SyntaxTerm, acc), tokens), False{})

def parse_term_args_first(is_close: Bool, file: String, token: Lexer.Token, rest: List<&2, Lexer.Token>, tokens: List<&2, Lexer.Token>, close: String, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.SyntaxTerm>) -> (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool:
  match is_close:
    case True{}:
      ((List.reverse(&2, Ast.SyntaxTerm, acc), rest), True{})
    case False{}:
      with_term_to_args(parse_term(file, tokens, scope, depth, 0n), term => after => ok => parse_term_args_first_result(ok, term, after, file, tokens, close, scope, depth, acc))

def parse_term_args_after_separator(is_close: Bool, file: String, term: Ast.SyntaxTerm, after: List<&2, Lexer.Token>, tail: List<&2, Lexer.Token>, close: String, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.SyntaxTerm>) -> (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool:
  match is_close:
    case True{}:
      ((List.reverse(&2, Ast.SyntaxTerm, term <> acc), tail), True{})
    case False{}:
      parse_term_args(file, after, close, scope, depth, term <> acc)

def make_tuple_cons(first: Ast.SyntaxTerm, result: Ast.SyntaxTerm & Bool, file: String, beg: Nat, end: Nat) -> Ast.SyntaxTerm & Bool:
  match result:
    case (tail, ok):
      (Ast.TermCtr{"Tuple", [first, tail], span(file, beg, end)}, ok)

def make_tuple(rest: List<&2, Ast.SyntaxTerm>, first: Ast.SyntaxTerm, +file: String, +beg: Nat, +end: Nat) -> Ast.SyntaxTerm & Bool:
  match rest:
    case Nil{}:
      (first, True{})
    case +second <> more:
      make_tuple_cons(first, make_tuple(more, second, file, beg, end), file, beg, end)

def parse_parenthesized_tuple_result(result: Ast.SyntaxTerm & Bool, after: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case (tuple, good):
      ((tuple, after), good)

def parse_parenthesized_terms(terms: List<&2, Ast.SyntaxTerm>, +after: List<&2, Lexer.Token>, file: String, beg: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match terms:
    case Nil{}:
      ((Ast.TermCtr{"Tuple", Nil{}, span(file, beg, token_end_of(after, end))}, after), True{})
    case +first <> rest:
      parse_parenthesized_tuple_result(make_tuple(rest, first, file, beg, token_end_of(after, end)), after)

def parse_application_applied_result(ok_apply: Bool, applied: Ast.SyntaxTerm, after_args: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, level: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_apply:
    case True{}:
      parse_term_tail(file, applied, after_args, scope, depth, level)
    case False{}:
      ((applied, after_args), False{})

def parse_application_args_result(ok_args: Bool, args: List<&2, Ast.SyntaxTerm>, after_args: List<&2, Lexer.Token>, file: String, head: Ast.SyntaxTerm, failure: Ast.SyntaxTerm, scope: List<&2, Scope>, depth: Nat, level: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_args:
    case True{}:
      with_term_bool(apply_terms(args, file, head, token_beg_first(head)), applied => ok_apply => parse_application_applied_result(ok_apply, applied, after_args, file, scope, depth, level))
    case False{}:
      ((failure, after_args), False{})

def parse_term_atom_result(ok: Bool, left: Ast.SyntaxTerm, rest: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, level: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok:
    case True{}:
      parse_term_tail(file, left, rest, scope, depth, level)
    case False{}:
      ((left, rest), False{})

def has_nat_suffix_reversed(reversed: List<&2, Char>) -> Bool:
  match reversed:
    case +last <> _:
      Char.is_eq(last, Char.from_u32(110))
    case Nil{}:
      False{}

def drop_nat_suffix_reversed(reversed: List<&2, Char>, text: String) -> String:
  match reversed:
    case +_ <> remaining:
      String.from_list(List.reverse(&2, Char, remaining))
    case Nil{}:
      text

def has_nat_suffix(text: String) -> Bool:
  has_nat_suffix_reversed(List.reverse(&2, Char, String.to_list(text)))

def drop_nat_suffix(+text: String) -> String:
  drop_nat_suffix_reversed(List.reverse(&2, Char, String.to_list(text)), text)

def u32_bit(file: String, bit_value: Nat, beg: Nat, end: Nat) -> Ast.SyntaxTerm:
  match bit_value:
    case 0n: Ast.TermCtr{ "False",  Nil{},  span(file, beg, end)}
    case _: Ast.TermCtr{ "True",  Nil{},  span(file, beg, end)}

def u32_bits(+file: String, +value: Nat, remaining: Nat, +beg: Nat, +end: Nat) -> Ast.SyntaxTerm:
  match remaining:
    case 0n:
      Ast.TermCtr{ "WNil",  Nil{},  span(file, beg, end)}
    case 1n+rest:
      +bit_index = rest
      bit = u32_bit(file, Nat.mod(Nat.div(value, Nat.pow(2n, bit_index)), 2n), beg, end)
      Ast.TermCtr{ "WCon",  [bit, u32_bits(file, value, bit_index, beg, end)],  span(file, beg, end)}

def u32_literal(+file: String, value: Nat, +beg: Nat, +end: Nat) -> Ast.SyntaxTerm:
  word = u32_bits(file, value, 32n, beg, end)
  Ast.TermCtr{ "U32",  [word],  span(file, beg, end)}

def nat_succ_chain(+file: String, value: Nat, +beg: Nat, +end: Nat) -> Ast.SyntaxTerm:
  match value:
    case 0n:
      Ast.TermCtr{ "Zero",  Nil{},  span(file, beg, end)}
    case 1n+rest:
      Ast.TermCtr{ "Succ",  [nat_succ_chain(file, rest, beg, end)],  span(file, beg, end)}

def nat_literal_large(is_large: Bool, +file: String, value: Nat, +beg: Nat, +end: Nat) -> Ast.SyntaxTerm:
  match is_large:
    case True{}:
      Ast.TermApp{ Ast.TermRef{ "U32.to_nat",  span(file, beg, end)},  u32_literal(file, value, beg, end),  span(file, beg, end)}
    case False{}:
      nat_succ_chain(file, value, beg, end)

def nat_literal(file: String, +value: Nat, beg: Nat, end: Nat) -> Ast.SyntaxTerm:
  nat_literal_large(Nat.is_lt(256n, value), file, value, beg, end)

def parse_number(file: String, text: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_number_suffix(has_nat_suffix(text), file, text, beg, end, rest, scope, depth)

def parse_number_suffix(has_suffix: Bool, file: String, text: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match has_suffix:
    case True{}:
      parse_number_nat_result(Nat.read(drop_nat_suffix(text)), True{}, file, text, beg, end, rest, scope, depth)
    case False{}:
      parse_number_nat_result(Nat.read(text), False{}, file, text, beg, end, rest, scope, depth)

def parse_number_nat_result(result: Maybe<&2, Nat>, has_suffix: Bool, file: String, text: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case Some{value}:
      parse_number_nat_range(Nat.is_le(value, 4294967295n), has_suffix, value, file, beg, end, rest, scope, depth)
    case None{}:
      parse_number_missing_nat(has_suffix, file, text, beg, end, rest)

def parse_number_nat_range(in_range: Bool, has_suffix: Bool, value: Nat, file: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match in_range:
    case True{}:
      parse_number_nat_value(has_suffix, value, file, beg, end, rest, scope, depth)
    case False{}:
      match has_suffix:
        case True{}:
          ((Ast.TermHole{ "parse-error: natural literal exceeds 4294967295",  span(file, beg, end)}, rest), False{})
        case False{}:
          ((Ast.TermHole{ "parse-error: unsigned integer literal exceeds 4294967295",  span(file, beg, end)}, rest), False{})

def parse_number_nat_value(has_suffix: Bool, value: Nat, file: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match has_suffix:
    case True{}:
      parse_nat_literal(file, value, beg, end, rest, scope, depth)
    case False{}:
      ((u32_literal(file, value, beg, end), rest), True{})

def parse_template_term(file: String, tokens: List<&2, Lexer.Token>, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_template_term_result(parse_term(file, tokens, scope, depth, 12n), file, beg)

def parse_template_term_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((+term, after), True{}):
      ((Ast.TermTemplate{term, span(file, beg, token_end_first(term))}, after), True{})
    case ((term, after), False{}):
      ((term, after), False{})

def harness_unsupported(file: String, branch: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  ((Ast.TermHole{String.append("harness-unsupported: ", branch), span(file, beg, end)}, rest), False{})

def parse_parenthesized(file: String, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, col: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match parse_term_args(file, tokens, ")", scope, depth, Nil{}):
    case ((terms, after), True{}):
      parse_parenthesized_terms(terms, after, file, beg, end)
    case (_, False{}):
      harness_unsupported(file, "parenthesized body or typed operator", beg, end, tokens)

def parse_nat_literal(file: String, value: Nat, beg: Nat, end: Nat, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{_, "+", _, _, _, _}:
          harness_unsupported(file, "natural additive tail", beg, end, tokens)
        case _:
          ((nat_literal(file, value, beg, end), tokens), True{})
    case Nil{}:
      ((nat_literal(file, value, beg, end), Nil{}), True{})

def parse_number_missing_nat(has_suffix: Bool, file: String, text: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_unsupported(file, "non-integer number", beg, end, rest)

def harness_term_symbol_supported(text: String) -> Bool:
  match text:
    case ")": True{}
    case "]": True{}
    case "}": True{}
    case ",": True{}
    case ":": True{}
    case ";": True{}
    case "<-": True{}
    case "=": True{}
    case "=>": True{}
    case _: False{}

def harness_term_symbol(is_delimiter: Bool, file: String, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_delimiter:
    case True{}:
      ((left, tokens), True{})
    case False{}:
      harness_unsupported(file, "term operator or tail", beg, end, tokens)

def parse_term_tail(file: String, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +next <> rest:
      match next:
        case Lexer.TokenInfo{Lexer.NewlineToken{}, _, _, _, _, _}:
          ((left, rest), True{})
        case Lexer.TokenInfo{Lexer.SymbolToken{}, "(", _, end, _, _}:
          with_args_result(parse_term_args(file, rest, ")", scope, depth, Nil{}), args => after_args => ok_args => parse_application_args_result(ok_args, args, after_args, file, left, Ast.TermHole{"parse-error: expected application arguments", span(file, end, end)}, scope, depth, level))
        case Lexer.TokenInfo{Lexer.SymbolToken{}, ">", beg, end, _, _}:
          harness_term_symbol(Bool.not(Nat.is_lt(token_end_first(left), beg)), file, left, tokens, beg, end)
        case Lexer.TokenInfo{Lexer.SymbolToken{}, text, beg, end, _, _}:
          harness_term_symbol(harness_term_symbol_supported(text), file, left, tokens, beg, end)
        case _:
          ((left, tokens), True{})
    case Nil{}:
      ((left, tokens), True{})

def parse_list(file: String, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_unsupported(file, "parse_list", beg, end, tokens)

def parse_rewrite(file: String, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_unsupported(file, "parse_rewrite", beg, end, tokens)

def parse_all(file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, beg: Nat, quantity: Ast.Quantity) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_unsupported(file, "parse_all", beg, beg, tokens)

def parse_amp(file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, beg: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_unsupported(file, "parse_amp", beg, end, tokens)

def parse_many_lambda(file: String, tokens: List<&2, Lexer.Token>, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_unsupported(file, "parse_many_lambda", beg, beg, tokens)

def parse_absurd(file: String, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_unsupported(file, "parse_absurd", beg, end, tokens)

def parse_brace(file: String, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_unsupported(file, "parse_brace", beg, end, tokens)

def parse_string(file: String, text: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_unsupported(file, "parse_string", beg, end, rest)

def parse_char_literal(file: String, text: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_unsupported(file, "parse_char_literal", beg, end, rest)

def step_parse_do_return(file: String, key: String, args: List<&2, Ast.SyntaxTerm>, +tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> FeedbackStep:
  FeedbackRequest{Request_parse_do_return_scan{file, key, args, tokens, skip_lines(tokens), beg, end, scope, depth, col}, Nil{}}
def step_parse_do_return_scan(+file: String, +key: String, +args: List<&2, Ast.SyntaxTerm>, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +beg: Nat, +end: Nat, +scope: List<&2, Scope>, +depth: Nat, col: Nat) -> FeedbackStep:
  match scanned:
    case +return_token <> rest:
      +feedback_scrutinee_3 = return_token
      match return_token:
        case Lexer.TokenInfo{Lexer.NameToken{}, "return", _, _, _, _}:
          FeedbackRequest{Request_parse_term{file, rest, scope, depth, 0n}, [Kont_120515{file, key, args, beg, end}]}
        case _:
          feedback_pack(parse_do_typed_bind(file, key, args, feedback_scrutinee_3 <> rest, beg, end, scope, depth, col))
    case Nil{}:
      FeedbackTerm{Ast.TermHole{"parse-error: expected return in do block", span(file, beg, end)}, Nil{}, False{}}
def step_parse_term(+file: String, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, level: Nat) -> FeedbackStep:
  FeedbackRequest{Request_parse_atom{file, tokens, scope, depth}, [Kont_166750{file, scope, depth, level}]}
def step_parse_atom(file: String, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackStep:
  FeedbackRequest{Request_parse_atom_scan{file, tokens, skip_lines(tokens), scope, depth}, Nil{}}
def step_parse_atom_scan(+file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackStep:
  match scanned:
    case +token <> rest:
      +feedback_scrutinee_3 = token
      match token:
        case Lexer.TokenInfo{ Lexer.NameToken{}, text, beg, end,  _,  _}:
          +feedback_scrutinee_5 = text
          match text:
            case "do":
              FeedbackRequest{Request_parse_do_atom{file, rest, beg, scope, depth}, Nil{}}
            case "Type":
              FeedbackTerm{Ast.TermType{ Ast.TermQuantity{ Ast.QOne{},  span(file, beg, end)},  span(file, beg, end)}, rest, True{}}
            case "Data":
              FeedbackTerm{Ast.TermType{ Ast.TermQuantity{ Ast.QMany{},  span(file, beg, end)},  span(file, beg, end)}, rest, True{}}
            case "Quant":
              FeedbackTerm{Ast.TermQuant{}, rest, True{}}
            case "Kind":
              +feedback_scrutinee_15 = rest
              match rest:
                case +open <> more:
                  match open:
                    case Lexer.TokenInfo{ _, "(",  _,  _,  _,  _}:
                      FeedbackRequest{Request_parse_term{file, more, scope, depth, 0n}, [Kont_117083{file, beg, end, feedback_scrutinee_15}]}
                    case _:
                      FeedbackTerm{Ast.TermHole{ "parse-error: expected (",  span(file, beg, end)}, feedback_scrutinee_15, False{}}
                case Nil{}:
                  FeedbackTerm{Ast.TermHole{ "parse-error: expected (",  span(file, beg, end)}, feedback_scrutinee_15, False{}}
            case _:
              feedback_pack(parse_name_term(file, feedback_scrutinee_5, beg, end, rest, scope, depth))
        case Lexer.TokenInfo{ Lexer.NumberToken{}, text, beg, end,  _,  _}:
          feedback_pack(parse_number(file, text, beg, end, rest, scope, depth))
        case Lexer.TokenInfo{ Lexer.SymbolToken{}, text, beg, end,  _, col}:
          match text:
            case "?":
              +feedback_scrutinee_31 = rest
              match rest:
                case +name <> tail:
                  +feedback_scrutinee_33 = name
                  match name:
                    case Lexer.TokenInfo{ Lexer.NameToken{},  key,  _,  fin,  _,  _}:
                      FeedbackTerm{Ast.TermHole{key,  span(file, beg, fin)}, tail, True{}}
                    case _:
                      FeedbackTerm{Ast.TermHole{ "parse-error: expected a hole feedback_scrutinee_33",  span(file, beg, end)}, feedback_scrutinee_31, False{}}
                case Nil{}:
                  FeedbackTerm{Ast.TermHole{ "parse-error: expected a hole name",  span(file, beg, end)}, feedback_scrutinee_31, False{}}
            case "[":
              feedback_pack(parse_list(file, rest, beg, end, scope, depth))
            case "(":
              feedback_pack(parse_parenthesized(file, rest, beg, end, col, scope, depth))
            case "%":
              feedback_pack(parse_rewrite(file, rest, beg, end, scope, depth))
            case "@":
              feedback_pack(parse_all(file, rest, scope, depth, beg, Ast.QMany{}))
            case "&":
              feedback_pack(parse_amp(file, rest, scope, depth, beg, end))
            case "+":
              feedback_pack(parse_many_lambda(file, rest, beg, scope, depth))
            case "\\":
              feedback_pack(parse_absurd(file, rest, beg, end, scope, depth))
            case "~":
              feedback_pack(parse_template_term(file, rest, beg, scope, depth))
            case "{":
              feedback_pack(parse_brace(file, rest, beg, end, scope, depth))
        case Lexer.TokenInfo{ Lexer.StringToken{}, text, beg, end,  _,  _}:
          feedback_pack(parse_string(file, text, beg, end, rest))
        case Lexer.TokenInfo{ Lexer.CharToken{}, text, beg, end,  _,  _}:
          feedback_pack(parse_char_literal(file, text, beg, end, rest))
        case _:
          FeedbackTerm{Ast.TermHole{ "parse-error: expected a term",  span(file, token_beg(feedback_scrutinee_3), token_end(feedback_scrutinee_3))}, tokens, False{}}
    case Nil{}:
      FeedbackTerm{Ast.TermHole{ "parse-error: expected a term",  span(file, 0n, 0n)}, Nil{}, False{}}
def step_parse_do_atom(+file: String, +tokens: List<&2, Lexer.Token>, +beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackStep:
  +feedback_scrutinee_1 = tokens
  match tokens:
    case +monad <> rest:
      +feedback_scrutinee_3 = monad
      match monad:
        case Lexer.TokenInfo{Lexer.NameToken{}, key, _, end, _, _}:
          +feedback_scrutinee_5 = rest
          match rest:
            case +open <> after_open:
              +feedback_scrutinee_7 = open
              match open:
                case Lexer.TokenInfo{_, "<", _, _, _, _}:
                  FeedbackRequest{Request_parse_do_atom_args_result{parse_term_args(file, after_open, ">", scope, depth, Nil{}), file, key, beg, end, feedback_scrutinee_1, scope, depth}, Nil{}}
                case _:
                  FeedbackTerm{Ast.TermHole{"parse-error: expected < after do feedback_scrutinee_3", span(file, token_beg(feedback_scrutinee_7), token_end(feedback_scrutinee_7))}, feedback_scrutinee_5, False{}}
            case Nil{}:
              FeedbackTerm{Ast.TermHole{"parse-error: expected do feedback_scrutinee_3 parameters", span(file, end, end)}, feedback_scrutinee_5, False{}}
        case _:
          FeedbackTerm{Ast.TermHole{"parse-error: expected do feedback_scrutinee_3", span(file, token_beg(feedback_scrutinee_3), token_end(feedback_scrutinee_3))}, feedback_scrutinee_1, False{}}
    case Nil{}:
      FeedbackTerm{Ast.TermHole{"parse-error: expected do monad", span(file, beg, beg)}, Nil{}, False{}}
def step_parse_do_atom_args_result(result: (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool, +file: String, key: String, beg: Nat, +end: Nat, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackStep:
  match result:
    case ((args, +colon <> after_colon), True{}):
      FeedbackRequest{Request_parse_do_atom_colon{colon, after_colon, args, file, key, beg, end, scope, depth}, Nil{}}
    case ((_, after_args), False{}):
      FeedbackTerm{Ast.TermHole{"parse-error: expected do parameters", span(file, end, end)}, after_args, False{}}
    case _:
      FeedbackTerm{Ast.TermHole{"parse-error: expected do parameters", span(file, end, end)}, tokens, False{}}
def step_parse_do_atom_colon(+colon: Lexer.Token, +after_colon: List<&2, Lexer.Token>, args: List<&2, Ast.SyntaxTerm>, +file: String, key: String, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackStep:
  +feedback_scrutinee_1 = colon
  match colon:
    case Lexer.TokenInfo{_, ":", _, _, _, _}:
      FeedbackRequest{Request_parse_do_return{file, key, args, after_colon, beg, end, scope, depth, do_first_col(after_colon)}, Nil{}}
    case _:
      FeedbackTerm{Ast.TermHole{"parse-error: expected : after do parameters", span(file, token_beg(feedback_scrutinee_1), token_end(feedback_scrutinee_1))}, +feedback_scrutinee_1 <> after_colon, False{}}

def feedback_resume(frame: FeedbackKont, result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool) -> FeedbackStep:
  match frame:
    case Kont_120515{+capture_1, +capture_2, +capture_3, +capture_4, +capture_5}:
      feedback_pack(parse_do_return_value_result(result, capture_1, capture_2, capture_3, capture_4, capture_5))
    case Kont_166750{+file, +scope, +depth, +level}:
      feedback_pack(with_term_result(result, left => rest => ok => parse_term_atom_result(ok, left, rest, file, scope, depth, level)))
    case Kont_117083{+capture_1, +capture_2, +capture_3, +capture_4}:
      feedback_pack(parse_kind_result(result, capture_1, capture_2, capture_3, capture_4))

def feedback_dispatch(request: FeedbackRequest) -> FeedbackStep:
  match request:
    case Request_parse_do_return_scan{file, key, args, tokens, scanned, beg, end, scope, depth, col}:
      step_parse_do_return_scan(file, key, args, tokens, scanned, beg, end, scope, depth, col)
    case Request_parse_term{file, tokens, scope, depth, level}:
      step_parse_term(file, tokens, scope, depth, level)
    case Request_parse_atom{file, tokens, scope, depth}:
      step_parse_atom(file, tokens, scope, depth)
    case Request_parse_atom_scan{file, tokens, scanned, scope, depth}:
      step_parse_atom_scan(file, tokens, scanned, scope, depth)
    case Request_parse_do_atom{file, tokens, beg, scope, depth}:
      step_parse_do_atom(file, tokens, beg, scope, depth)
    case Request_parse_do_atom_args_result{result, file, key, beg, end, tokens, scope, depth}:
      step_parse_do_atom_args_result(result, file, key, beg, end, tokens, scope, depth)
    case Request_parse_do_atom_colon{colon, after_colon, args, file, key, beg, end, scope, depth}:
      step_parse_do_atom_colon(colon, after_colon, args, file, key, beg, end, scope, depth)
    case Request_parse_do_return{file, key, args, tokens, beg, end, scope, depth, col}:
      step_parse_do_return(file, key, args, tokens, beg, end, scope, depth, col)

def feedback_drive(ticks: Nat, step: FeedbackStep, stack: List<&2, FeedbackKont>) -> FeedbackRun:
  match ticks:
    case 0n: FeedbackInvariantFailure{}
    case 1n+remaining:
      match step:
        case FeedbackRequest{request, pending}:
          feedback_drive(remaining, feedback_dispatch(request), List.append(&2, FeedbackKont, pending, stack))
        case FeedbackTerm{term, rest, ok}:
          match stack:
            case Nil{}: FeedbackComplete{term, rest, ok}
            case frame <> tail:
              feedback_drive(remaining, feedback_resume(frame, ((term, rest), ok)), tail)

def feedback_entry_parse_do_return_scan(+file: String, +key: String, +args: List<&2, Ast.SyntaxTerm>, +tokens: List<&2, Lexer.Token>, +scanned: List<&2, Lexer.Token>, +beg: Nat, +end: Nat, +scope: List<&2, Scope>, +depth: Nat, +col: Nat) -> FeedbackRun:
  feedback_drive(Nat.mul(8n, Nat.add(Nat.add(1n, List.length(&2, Lexer.Token, tokens)), List.length(&2, Lexer.Token, scanned))), FeedbackRequest{Request_parse_do_return_scan{file, key, args, tokens, scanned, beg, end, scope, depth, col}, Nil{}}, Nil{})

def feedback_entry_parse_term(+file: String, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +level: Nat) -> FeedbackRun:
  feedback_drive(Nat.mul(8n, Nat.add(1n, List.length(&2, Lexer.Token, tokens))), FeedbackRequest{Request_parse_term{file, tokens, scope, depth, level}, Nil{}}, Nil{})

def feedback_entry_parse_atom(+file: String, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackRun:
  feedback_drive(Nat.mul(8n, Nat.add(1n, List.length(&2, Lexer.Token, tokens))), FeedbackRequest{Request_parse_atom{file, tokens, scope, depth}, Nil{}}, Nil{})

def feedback_entry_parse_atom_scan(+file: String, +tokens: List<&2, Lexer.Token>, +scanned: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackRun:
  feedback_drive(Nat.mul(8n, Nat.add(Nat.add(1n, List.length(&2, Lexer.Token, tokens)), List.length(&2, Lexer.Token, scanned))), FeedbackRequest{Request_parse_atom_scan{file, tokens, scanned, scope, depth}, Nil{}}, Nil{})

def feedback_entry_parse_do_atom(+file: String, +tokens: List<&2, Lexer.Token>, +beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackRun:
  feedback_drive(Nat.mul(8n, Nat.add(1n, List.length(&2, Lexer.Token, tokens))), FeedbackRequest{Request_parse_do_atom{file, tokens, beg, scope, depth}, Nil{}}, Nil{})

def feedback_entry_parse_do_atom_args_result(+result: (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool, +file: String, +key: String, +beg: Nat, +end: Nat, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackRun:
  feedback_drive(Nat.mul(8n, Nat.add(1n, List.length(&2, Lexer.Token, tokens))), FeedbackRequest{Request_parse_do_atom_args_result{result, file, key, beg, end, tokens, scope, depth}, Nil{}}, Nil{})

def feedback_entry_parse_do_atom_colon(+colon: Lexer.Token, +after_colon: List<&2, Lexer.Token>, +args: List<&2, Ast.SyntaxTerm>, +file: String, +key: String, +beg: Nat, +end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackRun:
  feedback_drive(Nat.mul(8n, Nat.add(1n, List.length(&2, Lexer.Token, after_colon))), FeedbackRequest{Request_parse_do_atom_colon{colon, after_colon, args, file, key, beg, end, scope, depth}, Nil{}}, Nil{})

def feedback_entry_parse_do_return(+file: String, +key: String, +args: List<&2, Ast.SyntaxTerm>, +tokens: List<&2, Lexer.Token>, +beg: Nat, +end: Nat, +scope: List<&2, Scope>, +depth: Nat, +col: Nat) -> FeedbackRun:
  feedback_drive(Nat.mul(8n, Nat.add(1n, List.length(&2, Lexer.Token, tokens))), FeedbackRequest{Request_parse_do_return{file, key, args, tokens, beg, end, scope, depth, col}, Nil{}}, Nil{})


# PF1 canonical values encode strings as arrays of Unicode scalar numbers.
def parity_codes(s: String) -> String:
  match s:
    case SNil{}: ""
    case SCon{head, tail}:
      String.concat([U32.show(Char.to_u32(head)), parity_codes_tail(tail)])
def parity_codes_tail(s: String) -> String:
  match s:
    case SNil{}: ""
    case SCon{head, tail}:
      String.concat([",", U32.show(Char.to_u32(head)), parity_codes_tail(tail)])
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
  IO.bind(Unit, Unit, parity_row("simple_return_header", feedback_entry_parse_term("simple_return_header.bend", Lexer.tokens("do M: return x"), [Scope{"x", 0n}, Scope{"T", 1n}, Scope{"op", 2n}, Scope{"action", 3n}, Scope{"action2", 4n}, Scope{"f", 5n}, Scope{"g", 6n}, Scope{"Unit", 7n}], 8n, 0n)), _ => IO.bind(Unit, Unit, parity_row("action_then_return", feedback_entry_parse_term("action_then_return.bend", Lexer.tokens("do M<>: action; return x"), [Scope{"x", 0n}, Scope{"T", 1n}, Scope{"op", 2n}, Scope{"action", 3n}, Scope{"action2", 4n}, Scope{"f", 5n}, Scope{"g", 6n}, Scope{"Unit", 7n}], 8n, 0n)), _ => IO.bind(Unit, Unit, parity_row("untyped_bind_then_return", feedback_entry_parse_term("untyped_bind_then_return.bend", Lexer.tokens("do M<>: T <- op; return x"), [Scope{"x", 0n}, Scope{"T", 1n}, Scope{"op", 2n}, Scope{"action", 3n}, Scope{"action2", 4n}, Scope{"f", 5n}, Scope{"g", 6n}, Scope{"Unit", 7n}], 8n, 0n)), _ => IO.bind(Unit, Unit, parity_row("typed_bind", feedback_entry_parse_term("typed_bind.bend", Lexer.tokens("do M<>: x: T <- op; return x"), [Scope{"x", 0n}, Scope{"T", 1n}, Scope{"op", 2n}, Scope{"action", 3n}, Scope{"action2", 4n}, Scope{"f", 5n}, Scope{"g", 6n}, Scope{"Unit", 7n}], 8n, 0n)), _ => IO.bind(Unit, Unit, parity_row("two_operations", feedback_entry_parse_term("two_operations.bend", Lexer.tokens("do M<>: action; action2; return x"), [Scope{"x", 0n}, Scope{"T", 1n}, Scope{"op", 2n}, Scope{"action", 3n}, Scope{"action2", 4n}, Scope{"f", 5n}, Scope{"g", 6n}, Scope{"Unit", 7n}], 8n, 0n)), _ => IO.bind(Unit, Unit, parity_row("nested_expression", feedback_entry_parse_term("nested_expression.bend", Lexer.tokens("do M<>: return f(g(x))"), [Scope{"x", 0n}, Scope{"T", 1n}, Scope{"op", 2n}, Scope{"action", 3n}, Scope{"action2", 4n}, Scope{"f", 5n}, Scope{"g", 6n}, Scope{"Unit", 7n}], 8n, 0n)), _ => IO.bind(Unit, Unit, parity_row("malformed_body", feedback_entry_parse_term("malformed_body.bend", Lexer.tokens("do M<>: return"), [Scope{"x", 0n}, Scope{"T", 1n}, Scope{"op", 2n}, Scope{"action", 3n}, Scope{"action2", 4n}, Scope{"f", 5n}, Scope{"g", 6n}, Scope{"Unit", 7n}], 8n, 0n)), _ => IO.bind(Unit, Unit, parity_row("success_remainder", feedback_entry_parse_term("success_remainder.bend", Lexer.tokens("do M<>: return x ) tail"), [Scope{"x", 0n}, Scope{"T", 1n}, Scope{"op", 2n}, Scope{"action", 3n}, Scope{"action2", 4n}, Scope{"f", 5n}, Scope{"g", 6n}, Scope{"Unit", 7n}], 8n, 0n)), _ => IO.bind(Unit, Unit, parity_row("failure_remainder", feedback_entry_parse_term("failure_remainder.bend", Lexer.tokens("do M<>: x: T <- ) tail"), [Scope{"x", 0n}, Scope{"T", 1n}, Scope{"op", 2n}, Scope{"action", 3n}, Scope{"action2", 4n}, Scope{"f", 5n}, Scope{"g", 6n}, Scope{"Unit", 7n}], 8n, 0n)), _ => IO.pure(Unit, Unit{}))))))))))
