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
# The bounded do/name/AST-building utilities retain production bodies.
# Outbound adapters use independent grammar-specific scanners; there are no
# calls back into the selected entries and no imports of the parser closure.
# Token scanning recurses only on literal token tails. Nesting uses data frames;
# do evaluation recurses only on literal operation-segment tails. Computed
# results are matched by typed parameter helpers, never computed scrutinees.
#
# Grammar covered: return, action sequencing, untyped type <- value binding,
# named typed binding/assignment, operation chains, scope resolution,
# argument lists and nested calls/parentheses. Untyped bind introduces '_',
# not a named scope entry, exactly as production does. AST construction and
# remainder/span rules use production helpers. `do M:` remains a production
# error: the selected entry requires `<` plus the parameter closing delimiter.
#
# Adapters: parse_term_args/parse_term_tail use the expression scanner;
# parse_do_typed_bind uses the segment scanner/fold; parse_parenthesized accepts
# term tuples; parse_name_term/parse_template_term call the independent scanner.
# Explicit unsupported holes (False, unconsumed remainder) delimit the harness:
# list/rewrite/forall/amp/many-lambda/absurd/brace/string/character/number syntax,
# operators, typed-parenthesis/body fallback, nested do/Kind and non-comma args.
# No unchecked recursion, fuel, or production-wrapper callbacks are used.

type HarnessExprFrame is Data:
  HarnessCallFrame{head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, end: Nat}
  HarnessGroupFrame{args: List<&2, Ast.SyntaxTerm>, beg: Nat, end: Nat}

type HarnessExprResult is Data:
  HarnessExprResult{left: Ast.OptionalTerm, args: List<&2, Ast.SyntaxTerm>, after: List<&2, Lexer.Token>, ok: Bool}

type HarnessDoSegment is Data:
  HarnessDoSegment{tokens: List<&2, Lexer.Token>}

type HarnessDoOperation is Data:
  HarnessDoReturn{value: Ast.SyntaxTerm, after: List<&2, Lexer.Token>}
  HarnessDoStep{kind: Nat, key: String, key_beg: Nat, ty: Ast.SyntaxTerm, value: Ast.SyntaxTerm, after: List<&2, Lexer.Token>}
  HarnessDoFailure{term: Ast.SyntaxTerm, after: List<&2, Lexer.Token>}

# Lexer.tokens emits individual symbol characters. The restricted entry merges
# only an adjacent '<' '-' pair, preserving production pair spans. '<' '>' is
# deliberately not merged because the selected do entry requires its opener.
type HarnessPendingToken is Data:
  HarnessNoToken{}
  HarnessSomeToken{token: Lexer.Token}

type HarnessTokenStep is Data:
  HarnessTokenStep{pending: HarnessPendingToken, emitted: List<&2, Lexer.Token>}

def harness_bind_pair_adjacent(adjacent: Bool, left: Lexer.Token, right: Lexer.Token, beg: Nat, end: Nat, line: Nat, col: Nat) -> HarnessTokenStep:
  match adjacent:
    case True{}:
      HarnessTokenStep{HarnessNoToken{}, [Lexer.TokenInfo{Lexer.SymbolToken{}, "<-", beg, end, line, col}]}
    case False{}:
      HarnessTokenStep{HarnessSomeToken{right}, [left]}

def harness_bind_pair(left: Lexer.Token, right: Lexer.Token) -> HarnessTokenStep:
  match left right:
    case Lexer.TokenInfo{Lexer.SymbolToken{}, "<", +beg, +left_end, +line, +col} Lexer.TokenInfo{Lexer.SymbolToken{}, "-", +right_beg, +end, +right_line, +right_col}:
      harness_bind_pair_adjacent(Nat.is_eq(left_end, right_beg), Lexer.TokenInfo{Lexer.SymbolToken{}, "<", beg, left_end, line, col}, Lexer.TokenInfo{Lexer.SymbolToken{}, "-", right_beg, end, right_line, right_col}, beg, end, line, col)
    case Lexer.TokenInfo{lk, lt, lb, le, ll, lc} Lexer.TokenInfo{rk, rt, rb, re, rl, rc}:
      HarnessTokenStep{HarnessSomeToken{Lexer.TokenInfo{rk, rt, rb, re, rl, rc}}, [Lexer.TokenInfo{lk, lt, lb, le, ll, lc}]}

def harness_bind_step(pending: HarnessPendingToken, token: Lexer.Token) -> HarnessTokenStep:
  match pending:
    case HarnessNoToken{}: HarnessTokenStep{HarnessSomeToken{token}, Nil{}}
    case HarnessSomeToken{previous}: harness_bind_pair(previous, token)

def harness_with_token_step(step: HarnessTokenStep, use: HarnessPendingToken -> List<&2, Lexer.Token> -> List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:
  match step:
    case HarnessTokenStep{pending, emitted}: use(pending, emitted)

def harness_token_acc(emitted: List<&2, Lexer.Token>, acc: List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:
  match emitted:
    case +token <> rest: harness_token_acc(rest, token <> acc)
    case Nil{}: acc

def harness_token_finish(pending: HarnessPendingToken, acc: List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:
  match pending:
    case HarnessNoToken{}: List.reverse(&2, Lexer.Token, acc)
    case HarnessSomeToken{token}: List.reverse(&2, Lexer.Token, token <> acc)

def harness_bind_scan(tokens: List<&2, Lexer.Token>, pending: HarnessPendingToken, acc: List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:
  match tokens:
    case +token <> rest:
      harness_with_token_step(harness_bind_step(pending, token), next => emitted => harness_bind_scan(rest, next, harness_token_acc(emitted, acc)))
    case Nil{}:
      harness_token_finish(pending, acc)

def harness_tokens(source: String) -> List<&2, Lexer.Token>:
  harness_bind_scan(Lexer.tokens(source), HarnessNoToken{}, Nil{})

# Each recorded segment retains its original source remainder. Splitting uses
# only literal token tails; expression parsing never controls recursive descent.

def with_term_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, use: Ast.SyntaxTerm -> List<&2, Lexer.Token> -> Bool -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((term, after), ok):
      use(term, after, ok)

def with_args_result(result: (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool, use: List<&2, Ast.SyntaxTerm> -> List<&2, Lexer.Token> -> Bool -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((args, after), ok):
      use(args, after, ok)

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

def harness_expr_term(result: HarnessExprResult) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case HarnessExprResult{Ast.SomeTerm{term}, _, after, ok}: ((term, after), ok)
    case HarnessExprResult{Ast.NoTerm{}, _, after, _}: ((Ast.TermHole{"harness-unsupported: empty expression", span("", 0n, 0n)}, after), False{})

def harness_expr_finish(left: Ast.OptionalTerm, acc: List<&2, Ast.SyntaxTerm>, after: List<&2, Lexer.Token>, ok: Bool) -> HarnessExprResult:
  HarnessExprResult{left, List.reverse(&2, Ast.SyntaxTerm, acc), after, ok}

def harness_expr_error(file: String, +token: Lexer.Token, tokens: List<&2, Lexer.Token>, acc: List<&2, Ast.SyntaxTerm>) -> HarnessExprResult:
  harness_expr_finish(Ast.SomeTerm{Ast.TermHole{"parse-error: expected a term", span(file, token_beg(token), token_end(token))}}, acc, tokens, False{})

def harness_with_expr_atom(result: Ast.SyntaxTerm & Bool, yes: Ast.SyntaxTerm -> HarnessExprResult, no: Ast.SyntaxTerm -> HarnessExprResult) -> HarnessExprResult:
  match result:
    case (term, True{}): yes(term)
    case (term, False{}): no(term)

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

def harness_group_terms(terms: List<&2, Ast.SyntaxTerm>, file: String, beg: Nat, end: Nat) -> Ast.SyntaxTerm & Bool:
  match terms:
    case +first <> rest: make_tuple(rest, first, file, beg, end)
    case Nil{}: (Ast.TermCtr{"Tuple", Nil{}, span(file, beg, end)}, True{})

def harness_frame_close(frame: HarnessExprFrame, left: Ast.OptionalTerm, after: List<&2, Lexer.Token>, file: String) -> Ast.SyntaxTerm & Bool:
  match frame left:
    case HarnessCallFrame{+head, args, _} Ast.SomeTerm{term}:
      apply_terms(List.reverse(&2, Ast.SyntaxTerm, term <> args), file, head, token_beg_first(head))
    case HarnessCallFrame{+head, args, _} Ast.NoTerm{}:
      apply_terms(List.reverse(&2, Ast.SyntaxTerm, args), file, head, token_beg_first(head))
    case HarnessGroupFrame{args, beg, end} Ast.SomeTerm{term}:
      harness_group_terms(List.reverse(&2, Ast.SyntaxTerm, term <> args), file, beg, token_end_of(after, end))
    case HarnessGroupFrame{_, beg, end} Ast.NoTerm{}:
      (Ast.TermCtr{"Tuple", Nil{}, span(file, beg, token_end_of(after, end))}, True{})

# This scanner's only recursion is on the literal tail of its token input.
# Parenthesized expressions use data frames rather than recursive parser calls.

def harness_frame_add(frame: HarnessExprFrame, term: Ast.SyntaxTerm) -> HarnessExprFrame:
  match frame:
    case HarnessCallFrame{head, args, end}: HarnessCallFrame{head, term <> args, end}
    case HarnessGroupFrame{args, beg, end}: HarnessGroupFrame{term <> args, beg, end}

def harness_choose_expr(condition: Bool, yes: Nat -> HarnessExprResult, no: Nat -> HarnessExprResult) -> HarnessExprResult:
  match condition:
    case True{}: yes(0n)
    case False{}: no(0n)

def harness_expr_tail_allowed(condition: Bool, term: Ast.SyntaxTerm, +token: Lexer.Token, tokens: List<&2, Lexer.Token>, file: String, acc: List<&2, Ast.SyntaxTerm>) -> HarnessExprResult:
  match condition:
    case True{}: harness_expr_finish(Ast.SomeTerm{term}, acc, tokens, True{})
    case False{}: harness_expr_finish(Ast.SomeTerm{Ast.TermHole{"harness-unsupported: term operator or tail", span(file, token_beg(token), token_end(token))}}, acc, tokens, False{})

def harness_term_delimiter(text: String) -> Bool:
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

def harness_atom_lookup(found: Maybe<&2, Nat>, file: String, key: String, beg: Nat, end: Nat) -> Ast.SyntaxTerm & Bool:
  match found:
    case Some{index}: (Ast.TermVar{key, index, span(file, beg, end)}, True{})
    case None{}: (Ast.TermRef{key, span(file, beg, end)}, True{})

def harness_atom_number(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool) -> Ast.SyntaxTerm & Bool:
  match result:
    case ((term, _), ok): (term, ok)

def harness_unsupported(file: String, branch: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  ((Ast.TermHole{String.append("harness-unsupported: ", branch), span(file, beg, end)}, rest), False{})

def parse_number(file: String, text: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_unsupported(file, "numeric literal", beg, end, rest)

def harness_expr_atom(+file: String, token: Lexer.Token, scope: List<&2, Scope>, depth: Nat) -> Ast.SyntaxTerm & Bool:
  match token:
    case Lexer.TokenInfo{Lexer.NameToken{}, "Type", +beg, +end, _, _}:
      (Ast.TermType{Ast.TermQuantity{Ast.QOne{}, span(file, beg, end)}, span(file, beg, end)}, True{})
    case Lexer.TokenInfo{Lexer.NameToken{}, "Data", +beg, +end, _, _}:
      (Ast.TermType{Ast.TermQuantity{Ast.QMany{}, span(file, beg, end)}, span(file, beg, end)}, True{})
    case Lexer.TokenInfo{Lexer.NameToken{}, "Quant", _, _, _, _}:
      (Ast.TermQuant{}, True{})
    case Lexer.TokenInfo{Lexer.NameToken{}, "do", beg, end, _, _}:
      (Ast.TermHole{"harness-unsupported: nested do", span(file, beg, end)}, False{})
    case Lexer.TokenInfo{Lexer.NameToken{}, "Kind", beg, end, _, _}:
      (Ast.TermHole{"harness-unsupported: nested Kind", span(file, beg, end)}, False{})
    case Lexer.TokenInfo{Lexer.NameToken{}, +key, beg, end, _, _}:
      harness_atom_lookup(lookup(key, scope, depth), file, key, beg, end)
    case Lexer.TokenInfo{Lexer.NumberToken{}, text, beg, end, _, _}:
      harness_atom_number(parse_number(file, text, beg, end, Nil{}, scope, depth))
    case Lexer.TokenInfo{_, _, beg, end, _, _}:
      (Ast.TermHole{"parse-error: expected a term", span(file, beg, end)}, False{})

def harness_args_separator(is_comma: Bool, is_close: Bool, comma: Nat -> HarnessExprResult, closed: Nat -> HarnessExprResult, failed: Nat -> HarnessExprResult) -> HarnessExprResult:
  match is_comma is_close:
    case True{} _: comma(0n)
    case False{} True{}: closed(0n)
    case False{} False{}: failed(0n)

def harness_frame_dispatch(text: String, left: Ast.OptionalTerm, closed: Ast.OptionalTerm -> HarnessExprResult, comma: Ast.SyntaxTerm -> HarnessExprResult, failed: Nat -> HarnessExprResult) -> HarnessExprResult:
  match text left:
    case ")" Ast.SomeTerm{term}: closed(Ast.SomeTerm{term})
    case ")" Ast.NoTerm{}: closed(Ast.NoTerm{})
    case "," Ast.SomeTerm{term}: comma(term)
    case _ _: failed(0n)

def harness_root_dispatch(args_goal: Bool, left: Ast.OptionalTerm, args_term: Ast.SyntaxTerm -> HarnessExprResult, args_empty: Nat -> HarnessExprResult, term: Ast.SyntaxTerm -> HarnessExprResult, missing: Nat -> HarnessExprResult) -> HarnessExprResult:
  match args_goal left:
    case True{} Ast.SomeTerm{value}: args_term(value)
    case True{} Ast.NoTerm{}: args_empty(0n)
    case False{} Ast.SomeTerm{value}: term(value)
    case False{} Ast.NoTerm{}: missing(0n)

def harness_root_args_term(+term: Ast.SyntaxTerm, +text: String, +close: String, +acc: List<&2, Ast.SyntaxTerm>, +rest: List<&2, Lexer.Token>, file: String, token: Lexer.Token, tokens: List<&2, Lexer.Token>, more: List<&2, Ast.SyntaxTerm> -> HarnessExprResult) -> HarnessExprResult:
  harness_args_separator(String.eq(text, ","), Bool.or(String.eq(text, close), Bool.and(String.eq(close, ">"), String.eq(text, "<>"))), unused => more(term <> acc), unused => harness_expr_finish(Ast.SomeTerm{term}, term <> acc, rest, True{}), unused => harness_expr_error(file, token, tokens, acc))

def harness_root_term(+term: Ast.SyntaxTerm, +text: String, +token: Lexer.Token, tokens: List<&2, Lexer.Token>, file: String, acc: List<&2, Ast.SyntaxTerm>) -> HarnessExprResult:
  harness_expr_tail_allowed(Bool.or(harness_term_delimiter(text), Bool.and(String.eq(text, ">"), Bool.not(Nat.is_lt(token_end_first(term), token_beg(token))))), term, token, tokens, file, acc)

def harness_expr_scan(+file: String, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +left: Ast.OptionalTerm, +frames: List<&2, HarnessExprFrame>, +args_goal: Bool, +close: String, +acc: List<&2, Ast.SyntaxTerm>) -> HarnessExprResult:
  match tokens:
    case +token <> +rest:
      match token:
        case Lexer.TokenInfo{Lexer.NewlineToken{}, _, _, _, _, _}:
          match left frames args_goal:
            case Ast.NoTerm{} Nil{} True{}:
              harness_expr_scan(file, rest, scope, depth, Ast.NoTerm{}, Nil{}, True{}, close, acc)
            case Ast.NoTerm{} Nil{} False{}:
              harness_expr_scan(file, rest, scope, depth, Ast.NoTerm{}, Nil{}, False{}, close, acc)
            case Ast.SomeTerm{term} Nil{} False{}:
              harness_expr_finish(Ast.SomeTerm{term}, acc, rest, True{})
            case _ _ _:
              harness_expr_error(file, token, tokens, acc)
        case Lexer.TokenInfo{Lexer.SymbolToken{}, "(", beg, end, _, _}:
          match left:
            case Ast.SomeTerm{head}:
              harness_expr_scan(file, rest, scope, depth, Ast.NoTerm{}, HarnessCallFrame{head, Nil{}, end} <> frames, args_goal, close, acc)
            case Ast.NoTerm{}:
              harness_expr_scan(file, rest, scope, depth, Ast.NoTerm{}, HarnessGroupFrame{Nil{}, beg, end} <> frames, args_goal, close, acc)
        case Lexer.TokenInfo{Lexer.SymbolToken{}, +text, _, _, _, _}:
          match frames:
            case +frame <> +outer:
              harness_frame_dispatch(text, left, remaining => harness_with_expr_atom(harness_frame_close(frame, remaining, rest, file), closed => harness_expr_scan(file, rest, scope, depth, Ast.SomeTerm{closed}, outer, args_goal, close, acc), closed => harness_expr_finish(Ast.SomeTerm{closed}, acc, rest, False{})), term => harness_expr_scan(file, rest, scope, depth, Ast.NoTerm{}, harness_frame_add(frame, term) <> outer, args_goal, close, acc), unused => harness_expr_error(file, token, tokens, acc))
            case Nil{}:
              harness_root_dispatch(args_goal, left, term => harness_root_args_term(term, text, close, acc, rest, file, token, tokens, items => harness_expr_scan(file, rest, scope, depth, Ast.NoTerm{}, Nil{}, True{}, close, items)), unused => harness_choose_expr(Bool.or(String.eq(text, close), Bool.and(String.eq(close, ">"), String.eq(text, "<>"))), ignored => harness_expr_finish(Ast.NoTerm{}, acc, rest, True{}), ignored => harness_expr_error(file, token, tokens, acc)), term => harness_root_term(term, text, token, tokens, file, acc), unused => harness_expr_error(file, token, tokens, acc))
        case Lexer.TokenInfo{Lexer.EndToken{}, _, _, _, _, _}:
          match left frames args_goal:
            case Ast.SomeTerm{term} Nil{} False{}: harness_expr_finish(Ast.SomeTerm{term}, acc, tokens, True{})
            case _ _ _: harness_expr_error(file, token, tokens, acc)
        case Lexer.TokenInfo{+kind, +text, +beg, +end, +line, +col}:
          match left:
            case Ast.NoTerm{}:
              harness_with_expr_atom(harness_expr_atom(file, Lexer.TokenInfo{kind, text, beg, end, line, col}, scope, depth), term => harness_expr_scan(file, rest, scope, depth, Ast.SomeTerm{term}, frames, args_goal, close, acc), term => harness_expr_finish(Ast.SomeTerm{term}, acc, tokens, False{}))
            case Ast.SomeTerm{term}:
              match frames args_goal:
                case Nil{} False{}: harness_expr_finish(Ast.SomeTerm{term}, acc, tokens, True{})
                case _ _: harness_expr_error(file, Lexer.TokenInfo{kind, text, beg, end, line, col}, tokens, acc)
    case Nil{}:
      match left frames args_goal:
        case Ast.SomeTerm{term} Nil{} False{}: harness_expr_finish(Ast.SomeTerm{term}, acc, Nil{}, True{})
        case _ _ _: harness_expr_finish(Ast.SomeTerm{Ast.TermHole{"parse-error: expected a term", span(file, 0n, 0n)}}, acc, Nil{}, False{})

def harness_parse_term(file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_expr_term(harness_expr_scan(file, tokens, scope, depth, Ast.NoTerm{}, Nil{}, False{}, "", Nil{}))

def harness_scan_args(result: HarnessExprResult) -> (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool:
  match result:
    case HarnessExprResult{_, args, after, ok}: ((args, after), ok)

def parse_term_args(file: String, tokens: List<&2, Lexer.Token>, close: String, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.SyntaxTerm>) -> (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool:
  harness_scan_args(harness_expr_scan(file, tokens, scope, depth, Ast.NoTerm{}, Nil{}, True{}, close, acc))

def harness_name_term(+file: String, +key: String, +beg: Nat, +end: Nat, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +next <> rest:
      match next:
        case Lexer.TokenInfo{ _, "=>",  _,  _,  _,  _}:
          next_scope = extend_scope(key, depth, scope)
          with_term_result(harness_parse_term(file, rest, next_scope, depth + 1n, 0n), body => after => ok => parse_name_lambda_result(ok, body, after, file, key, beg, end, depth))
        case Lexer.TokenInfo{ _, "{",  _,  _,  _,  _}:
          with_args_result(parse_term_args(file, rest, "}", scope, depth, Nil{}), args => after_args => ok_args => parse_name_constructor_result(ok_args, args, after_args, file, key, beg, end))
        case _:
          parse_name_term_lookup(lookup(key, scope, depth), file, key, beg, end, tokens)
    case Nil{}:
      parse_name_term_lookup(lookup(key, scope, depth), file, key, beg, end, Nil{})

def parse_name_term(file: String, key: String, beg: Nat, end: Nat, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_name_term(file, key, beg, end, tokens, scope, depth)

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

def parse_term_tail(file: String, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_expr_term(harness_expr_scan(file, tokens, scope, depth, Ast.SomeTerm{left}, Nil{}, False{}, "", Nil{}))

def parse_term_atom_result(ok: Bool, left: Ast.SyntaxTerm, rest: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, level: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok:
    case True{}:
      parse_term_tail(file, left, rest, scope, depth, level)
    case False{}:
      ((left, rest), False{})

def parse_template_term_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((+term, after), True{}):
      ((Ast.TermTemplate{term, span(file, beg, token_end_first(term))}, after), True{})
    case ((term, after), False{}):
      ((term, after), False{})

def harness_template_term(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_template_term_result(harness_parse_term(file, tokens, scope, depth, 12n), file, beg)

def parse_template_term(file: String, tokens: List<&2, Lexer.Token>, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_template_term(file, tokens, beg, scope, depth)

def harness_do_segments(tokens: List<&2, Lexer.Token>, start: List<&2, Lexer.Token>, nesting: Nat, started: Bool, acc: List<&2, HarnessDoSegment>) -> List<&2, HarnessDoSegment>:
  match tokens:
    case +token <> +rest:
      match token:
        case Lexer.TokenInfo{Lexer.SymbolToken{}, "(", _, _, _, _}:
          harness_do_segments(rest, start, nesting + 1n, True{}, acc)
        case Lexer.TokenInfo{Lexer.SymbolToken{}, ")", _, _, _, _}:
          match nesting:
            case 0n: List.reverse(&2, HarnessDoSegment, HarnessDoSegment{start} <> acc)
            case 1n+outer: harness_do_segments(rest, start, outer, True{}, acc)
        case Lexer.TokenInfo{Lexer.SymbolToken{}, ";", _, _, _, _}:
          match nesting:
            case 0n: harness_do_segments(rest, rest, 0n, False{}, HarnessDoSegment{start} <> acc)
            case _: harness_do_segments(rest, start, nesting, True{}, acc)
        case Lexer.TokenInfo{Lexer.NewlineToken{}, _, _, _, _, _}:
          match nesting started:
            case 0n True{}: harness_do_segments(rest, rest, 0n, False{}, HarnessDoSegment{start} <> acc)
            case 0n False{}: harness_do_segments(rest, rest, 0n, False{}, acc)
            case _ _: harness_do_segments(rest, start, nesting, started, acc)
        case Lexer.TokenInfo{Lexer.EndToken{}, _, _, _, _, _}:
          List.reverse(&2, HarnessDoSegment, HarnessDoSegment{start} <> acc)
        case _:
          harness_do_segments(rest, start, nesting, True{}, acc)
    case Nil{}:
      List.reverse(&2, HarnessDoSegment, HarnessDoSegment{start} <> acc)

def harness_do_value(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, kind: Nat, key: String, key_beg: Nat, ty: Ast.SyntaxTerm) -> HarnessDoOperation:
  match result:
    case ((value, after), True{}): HarnessDoStep{kind, key, key_beg, ty, value, after}
    case ((term, after), False{}): HarnessDoFailure{term, after}

def harness_do_typed_token(token: Lexer.Token, rest: List<&2, Lexer.Token>, ty: Ast.SyntaxTerm, file: String, key: String, key_beg: Nat, scope: List<&2, Scope>, depth: Nat) -> HarnessDoOperation:
  match token:
    case Lexer.TokenInfo{_, "<-", _, _, _, _}:
      harness_do_value(harness_parse_term(file, rest, scope, depth, 0n), 1n, key, key_beg, ty)
    case Lexer.TokenInfo{_, "=", _, _, _, _}:
      harness_do_value(harness_parse_term(file, rest, scope, depth, 0n), 2n, key, key_beg, ty)
    case Lexer.TokenInfo{kind, text, +beg, +end, line, col}:
      HarnessDoFailure{Ast.TermHole{"parse-error: expected <- in do binding", span(file, beg, end)}, Lexer.TokenInfo{kind, text, beg, end, line, col} <> rest}

def harness_do_typed(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, key: String, key_beg: Nat, scope: List<&2, Scope>, depth: Nat) -> HarnessDoOperation:
  match result:
    case ((ty, +token <> rest), True{}):
      harness_do_typed_token(token, rest, ty, file, key, key_beg, scope, depth)
    case ((term, after), _): HarnessDoFailure{term, after}

def harness_do_action_after(scanned: List<&2, Lexer.Token>, action: Ast.SyntaxTerm, after: List<&2, Lexer.Token>, file: String, +beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> HarnessDoOperation:
  match scanned:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{_, "<-", _, _, _, _}:
          harness_do_value(harness_parse_term(file, rest, scope, depth, 0n), 0n, "_", beg, action)
        case _:
          HarnessDoStep{3n, "_", beg, Ast.TermRef{"Unit", span(file, beg, end)}, action, after}
    case Nil{}:
      HarnessDoStep{3n, "_", beg, Ast.TermRef{"Unit", span(file, beg, end)}, action, after}

def harness_do_action_value(action: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, file: String, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> HarnessDoOperation:
  harness_do_action_after(skip_rewrite_semicolon(after), action, after, file, beg, end, scope, depth)

def harness_do_action(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> HarnessDoOperation:
  match result:
    case ((action, after), True{}):
      harness_do_action_value(action, after, file, beg, end, scope, depth)
    case ((term, after), False{}): HarnessDoFailure{term, after}

def harness_do_return_operation(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool) -> HarnessDoOperation:
  match result:
    case ((value, after), True{}): HarnessDoReturn{value, after}
    case ((term, after), False{}): HarnessDoFailure{term, after}

def harness_do_name_token(next: Lexer.Token, after: List<&2, Lexer.Token>, tokens: List<&2, Lexer.Token>, +file: String, key: String, key_beg: Nat, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> HarnessDoOperation:
  match next:
    case Lexer.TokenInfo{_, ":", _, _, _, _}:
      harness_do_typed(harness_parse_term(file, after, scope, depth, 1n), file, key, key_beg, scope, depth)
    case _:
      harness_do_action(harness_parse_term(file, tokens, scope, depth, 0n), file, beg, end, scope, depth)

def harness_do_name_rest(rest: List<&2, Lexer.Token>, tokens: List<&2, Lexer.Token>, +file: String, key: String, key_beg: Nat, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> HarnessDoOperation:
  match rest:
    case +next <> after:
      harness_do_name_token(next, after, tokens, file, key, key_beg, beg, end, scope, depth)
    case Nil{}:
      harness_do_action(harness_parse_term(file, tokens, scope, depth, 0n), file, beg, end, scope, depth)

def harness_do_operation(+tokens: List<&2, Lexer.Token>, +file: String, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> HarnessDoOperation:
  match tokens:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{Lexer.NameToken{}, "return", _, _, _, _}:
          harness_do_return_operation(harness_parse_term(file, rest, scope, depth, 0n))
        case Lexer.TokenInfo{Lexer.NameToken{}, key, key_beg, _, _, _}:
          harness_do_name_rest(rest, tokens, file, key, key_beg, beg, end, scope, depth)
        case _:
          harness_do_action(harness_parse_term(file, tokens, scope, depth, 0n), file, beg, end, scope, depth)
    case Nil{}:
      HarnessDoFailure{Ast.TermHole{"parse-error: expected return in do block", span(file, beg, end)}, Nil{}}

def harness_do_build(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, kind: Nat, key: String, key_beg: Nat, ty: Ast.SyntaxTerm, value: Ast.SyntaxTerm, file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, beg: Nat, end: Nat, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((body, after), ok):
      match kind:
        case 1n: parse_do_typed_bind_body_result(ok, body, after, file, monad, args, key, key_beg, ty, value, beg, end, depth)
        case 2n: parse_do_assignment_body_result(ok, body, after, file, key, key_beg, depth, ty, value)
        case _: parse_do_bind_body_result(ok, body, after, file, monad, args, ty, value, beg, end, depth)

# Scope moves forward on the literal segment tail; AST builders run on unwind.

def harness_do_dispatch(operation: HarnessDoOperation, on_return: Ast.SyntaxTerm -> List<&2, Lexer.Token> -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, on_failure: Ast.SyntaxTerm -> List<&2, Lexer.Token> -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, on_step: Nat -> String -> Nat -> Ast.SyntaxTerm -> Ast.SyntaxTerm -> List<&2, Lexer.Token> -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match operation:
    case HarnessDoReturn{value, after}: on_return(value, after)
    case HarnessDoFailure{term, after}: on_failure(term, after)
    case HarnessDoStep{kind, key, key_beg, ty, value, after}: on_step(kind, key, key_beg, ty, value, after)

def harness_do_step_more(stop: Bool, kind: Nat, +key: String, key_beg: Nat, ty: Ast.SyntaxTerm, value: Ast.SyntaxTerm, after: List<&2, Lexer.Token>, file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, beg: Nat, end: Nat, scope: List<&2, Scope>, +depth: Nat, more: List<&2, Scope> -> Nat -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match stop:
    case True{}: ((value, after), True{})
    case False{}: harness_do_build(more(extend_scope(key, depth, scope), depth + 1n), kind, key, key_beg, ty, value, file, monad, args, beg, end, depth)

def harness_do_step_checked(+kind: Nat, key: String, key_beg: Nat, ty: Ast.SyntaxTerm, value: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat, more: List<&2, Scope> -> Nat -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_do_step_more(Bool.and(Nat.is_eq(kind, 3n), Bool.not(do_has_more(after, col))), kind, key, key_beg, ty, value, after, file, monad, args, beg, end, scope, depth, more)

def harness_do_eval(segments: List<&2, HarnessDoSegment>, +file: String, +monad: String, +args: List<&2, Ast.SyntaxTerm>, +beg: Nat, +end: Nat, +scope: List<&2, Scope>, +depth: Nat, +col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match segments:
    case +segment <> rest:
      match segment:
        case HarnessDoSegment{tokens}:
          harness_do_dispatch(harness_do_operation(tokens, file, beg, end, scope, depth), value => after => parse_do_return_value_result(((value, after), True{}), file, monad, args, beg, end), term => after => ((term, after), False{}), kind => key => key_beg => ty => value => after => harness_do_step_checked(kind, key, key_beg, ty, value, after, file, monad, args, beg, end, scope, depth, col, next_scope => next_depth => harness_do_eval(rest, file, monad, args, beg, end, next_scope, next_depth, col)))
    case Nil{}:
      ((Ast.TermHole{"parse-error: expected return in do block", span(file, beg, end)}, Nil{}), False{})

def harness_do_start(file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, +tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_do_eval(harness_do_segments(tokens, tokens, 0n, False{}, Nil{}), file, monad, args, beg, end, scope, depth, col)

def parse_do_typed_bind(file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_do_start(file, monad, args, tokens, beg, end, scope, depth, col)

def harness_parenthesized_result(result: (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool, file: String, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((terms, after), True{}): parse_parenthesized_terms(terms, after, file, beg, end)
    case (_, False{}): harness_unsupported(file, "parenthesized body or typed operator", beg, end, tokens)

def harness_parenthesized(+file: String, +tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, col: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_parenthesized_result(parse_term_args(file, tokens, ")", scope, depth, Nil{}), file, tokens, beg, end)

def parse_parenthesized(file: String, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, col: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_parenthesized(file, tokens, beg, end, col, scope, depth)

def parse_list(file: String, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_unsupported(file, "parse_list", beg, end, tokens)

def parse_rewrite(file: String, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_unsupported(file, "parse_rewrite", beg, end, tokens)

def harness_unsupported_point(file: String, branch: String, +beg: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_unsupported(file, branch, beg, beg, rest)

def parse_all(file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, beg: Nat, quantity: Ast.Quantity) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_unsupported_point(file, "parse_all", beg, tokens)

def parse_amp(file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, beg: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_unsupported(file, "parse_amp", beg, end, tokens)

def parse_many_lambda(file: String, tokens: List<&2, Lexer.Token>, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_unsupported_point(file, "parse_many_lambda", beg, tokens)

def parse_absurd(file: String, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_unsupported(file, "parse_absurd", beg, end, tokens)

def parse_brace(file: String, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_unsupported(file, "parse_brace", beg, end, tokens)

def parse_string(file: String, text: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_unsupported(file, "parse_string", beg, end, rest)

def parse_char_literal(file: String, text: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  harness_unsupported(file, "parse_char_literal", beg, end, rest)
