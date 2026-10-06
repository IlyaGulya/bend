import Base
import ./ast.bend as Ast
import ./lexer.bend as Lexer
import ./core.bend as Core

type ParseResult is Data:
  ParseSuccess{module: Ast.Module}
  ParseFailure{message: String, expected: String, observed: String, span: Ast.SourceSpan}

type TopOwner is Data:
  TopOwnerNone{}
  TopOwnerLaw{}
  TopOwnerClosed{}


type Scope is Data:
  Scope{key: String, index: Nat}
type MatchChainState is Data:
  MatchChainStart{file: String, key: String, head: Ast.SyntaxTerm, original: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, beg: Nat, scope: List<&2, Scope>, depth: Nat}
  MatchChainAfterName{file: String, key: String, head: Ast.SyntaxTerm, original: List<&2, Lexer.Token>, next_key: String, scanned: List<&2, Lexer.Token>, beg: Nat, scope: List<&2, Scope>, depth: Nat}
  MatchChainAfterHead{file: String, key: String, head: Ast.SyntaxTerm, original: List<&2, Lexer.Token>, next_key: String, next_head: Ast.SyntaxTerm, after_head: List<&2, Lexer.Token>, ok_head: Bool, scanned: List<&2, Lexer.Token>, beg: Nat, scope: List<&2, Scope>, depth: Nat}
  MatchChainAfterMatch{file: String, key: String, head: Ast.SyntaxTerm, matched: Ast.SyntaxTerm, after_matched: List<&2, Lexer.Token>, ok_matched: Bool, beg: Nat}

type PatternScanMode is Data:
  PatternExpect{quantity: Ast.Quantity, beg: Nat}
  PatternCompleted{pattern: Ast.SyntaxPattern}
  PatternNoNat{number: Lexer.Token, quantity: Ast.Quantity, beg: Nat, end: Nat}
  PatternBadNat{beg: Nat, end: Nat}

type PatternFrame is Data:
  PatternFrameOf{key: String, beg: Nat, end: Nat, fields: List<&2, Ast.SyntaxPattern>, root_scope: List<&2, Scope>, root_depth: Nat}
type PatternScanGoal is Data:
  PatternSingleGoal{}
  PatternCaseGoal{acc: List<&2, Ast.SyntaxPattern>, before_scope: List<&2, Scope>, before_depth: Nat}

type PatternScanOutcome is Data:
  PatternSingleOutcome{pattern: Ast.SyntaxPattern, after: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, ok: Bool}
  PatternCaseOutcome{patterns: List<&2, Ast.SyntaxPattern>, after: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, ok: Bool}


type FloatParts is Data:
  FloatParts{mantissa: Nat, scale_negative: Bool, scale: Nat, valid: Bool}

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

def with_term_top(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, use: Ast.SyntaxTerm -> List<&2, Lexer.Token> -> Bool -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((term, after), ok):
      use(term, after, ok)

def with_term_law_clauses(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, use: Ast.SyntaxTerm -> List<&2, Lexer.Token> -> Bool -> (((List<&2, Ast.Clause> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool) -> (((List<&2, Ast.Clause> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool:
  match result:
    case ((term, after), ok):
      use(term, after, ok)

def with_term_bool(result: Ast.SyntaxTerm & Bool, use: Ast.SyntaxTerm -> Bool -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case (term, ok):
      use(term, ok)

def with_def_binders_result(result: (((List<&2, Ast.TelescopeItem> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool, use: List<&2, Ast.TelescopeItem> -> List<&2, Lexer.Token> -> List<&2, Scope> -> Nat -> Bool -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((((binders, after), scope), depth), ok):
      use(binders, after, scope, depth, ok)

def with_def_body_result(result: (Ast.DefBody & List<&2, Lexer.Token>) & Bool, use: Ast.DefBody -> List<&2, Lexer.Token> -> Bool -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((body, after), ok):
      use(body, after, ok)

def with_local_binders_result(result: (((List<&2, Ast.SyntaxPattern> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool, use: List<&2, Ast.SyntaxPattern> -> List<&2, Lexer.Token> -> List<&2, Scope> -> Nat -> Bool -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((((patterns, after), scope), depth), ok):
      use(patterns, after, scope, depth, ok)

def with_local_values_result(result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Nat) & Bool, use: List<&2, Ast.SyntaxTerm> -> List<&2, Lexer.Token> -> Nat -> Bool -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case (((values, after), line), ok):
      use(values, after, line, ok)

def with_pattern_result(result: (Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool), use: Ast.SyntaxPattern -> List<&2, Lexer.Token> -> List<&2, Scope> -> Nat -> Bool -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((pattern, after), ((scope, depth), ok)):
      use(pattern, after, scope, depth, ok)

def span(file: String, beg: Nat, end: Nat) -> Ast.SourceSpan:
  Ast.SpanOf{file, beg, end}


def with_import_result(result: (Ast.ModuleImport & List<&2, Lexer.Token>) & Bool, use: Ast.ModuleImport -> List<&2, Lexer.Token> -> Bool -> ((List<&2, Ast.ModuleImport> & List<&2, Lexer.Token>) & Bool)) -> ((List<&2, Ast.ModuleImport> & List<&2, Lexer.Token>) & Bool):
  match result:
    case ((item, after), ok):
      use(item, after, ok)

def with_top_result(result: (Ast.TopLevel & List<&2, Lexer.Token>) & Bool, use: Ast.TopLevel -> List<&2, Lexer.Token> -> Bool -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((top, after), ok):
      use(top, after, ok)

def with_constructor_decls_result(result: (List<&2, Ast.ConstructorDecl> & List<&2, Lexer.Token>) & Bool, use: List<&2, Ast.ConstructorDecl> -> List<&2, Lexer.Token> -> Bool -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((constructors, after), ok):
      use(constructors, after, ok)

def with_def_binders_constructors_result(result: (((List<&2, Ast.TelescopeItem> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool, use: List<&2, Ast.TelescopeItem> -> List<&2, Lexer.Token> -> List<&2, Scope> -> Nat -> Bool -> (List<&2, Ast.ConstructorDecl> & List<&2, Lexer.Token>) & Bool) -> (List<&2, Ast.ConstructorDecl> & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((((binders, after), scope), depth), ok):
      use(binders, after, scope, depth, ok)

def with_law_clauses_result(result: (((List<&2, Ast.Clause> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool, use: List<&2, Ast.Clause> -> List<&2, Lexer.Token> -> List<&2, Scope> -> Nat -> Bool -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((((clauses, after), scope), depth), ok):
      use(clauses, after, scope, depth, ok)

def with_imports_result(result: (List<&2, Ast.ModuleImport> & List<&2, Lexer.Token>) & Bool, use: List<&2, Ast.ModuleImport> -> List<&2, Lexer.Token> -> Bool -> ParseResult) -> ParseResult:
  match result:
    case ((imports, after), ok):
      use(imports, after, ok)

def with_top_item_result(result: (Ast.TopLevel & List<&2, Lexer.Token>) & Bool, use: Ast.TopLevel -> List<&2, Lexer.Token> -> Bool -> (List<&2, Ast.TopLevel> & Bool) & List<&2, Lexer.Token>) -> (List<&2, Ast.TopLevel> & Bool) & List<&2, Lexer.Token>:
  match result:
    case ((top, after), ok):
      use(top, after, ok)

def with_top_declarations_result(result: (List<&2, Ast.TopLevel> & Bool) & List<&2, Lexer.Token>, use: List<&2, Ast.TopLevel> -> Bool -> List<&2, Lexer.Token> -> ParseResult) -> ParseResult:
  match result:
    case ((declarations, ok), rest):
      use(declarations, ok, rest)

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


type SymbolCombineMode is Data:
  SymbolCombineScan{}
  SymbolCombineMerged{merged: Lexer.Token, consumed: Nat}
  SymbolCombineUnmerged{token: Lexer.Token}
  SymbolCombineSkip{merged: Lexer.Token}

type SymbolPairClass is Data:
  SymbolPairMerged{pair: String}
  SymbolPairUnmerged{left: String}

type SymbolTripleClass is Data:
  SymbolTripleMerged{three: String}
  SymbolTripleUnmerged{left: String, right: String}

def symbol_triple_fallback(text: String) -> SymbolTripleClass:
  match text:
    case SCon{first, SCon{second, _}}:
      SymbolTripleUnmerged{String.from_list([first]), String.from_list([second])}
    case SCon{first, SNil{}}:
      SymbolTripleUnmerged{String.from_list([first]), SNil{}}
    case SNil{}:
      SymbolTripleUnmerged{SNil{}, SNil{}}

def symbol_triple_choice_3(matched: Bool, text: String) -> SymbolTripleClass:
  match matched:
    case True{}:
      SymbolTripleMerged{".&."}
    case False{}:
      symbol_triple_fallback(text)

def symbol_triple_test_3(+text: String) -> SymbolTripleClass:
  symbol_triple_choice_3(String.eq(text, ".&."), text)

def symbol_triple_choice_2(matched: Bool, text: String) -> SymbolTripleClass:
  match matched:
    case True{}:
      SymbolTripleMerged{".^."}
    case False{}:
      symbol_triple_test_3(text)

def symbol_triple_test_2(+text: String) -> SymbolTripleClass:
  symbol_triple_choice_2(String.eq(text, ".^."), text)

def symbol_triple_choice_1(matched: Bool, text: String) -> SymbolTripleClass:
  match matched:
    case True{}:
      SymbolTripleMerged{".|."}
    case False{}:
      symbol_triple_test_2(text)

def symbol_triple_test_1(+text: String) -> SymbolTripleClass:
  symbol_triple_choice_1(String.eq(text, ".|."), text)

def symbol_triple_choice_0(matched: Bool, text: String) -> SymbolTripleClass:
  match matched:
    case True{}:
      SymbolTripleMerged{"<&>"}
    case False{}:
      symbol_triple_test_1(text)

def symbol_triple_test_0(+text: String) -> SymbolTripleClass:
  symbol_triple_choice_0(String.eq(text, "<&>"), text)

def multi_symbol_3(text: String) -> SymbolTripleClass:
  symbol_triple_test_0(text)

def symbol_pair_fallback(text: String) -> SymbolPairClass:
  match text:
    case SCon{first, _}:
      SymbolPairUnmerged{String.from_list([first])}
    case SNil{}:
      SymbolPairUnmerged{SNil{}}

def symbol_pair_choice_12(matched: Bool, text: String) -> SymbolPairClass:
  match matched:
    case True{}:
      SymbolPairMerged{"&&"}
    case False{}:
      symbol_pair_fallback(text)

def symbol_pair_test_12(+text: String) -> SymbolPairClass:
  symbol_pair_choice_12(String.eq(text, "&&"), text)

def symbol_pair_choice_11(matched: Bool, text: String) -> SymbolPairClass:
  match matched:
    case True{}:
      SymbolPairMerged{"||"}
    case False{}:
      symbol_pair_test_12(text)

def symbol_pair_test_11(+text: String) -> SymbolPairClass:
  symbol_pair_choice_11(String.eq(text, "||"), text)

def symbol_pair_choice_10(matched: Bool, text: String) -> SymbolPairClass:
  match matched:
    case True{}:
      SymbolPairMerged{">>"}
    case False{}:
      symbol_pair_test_11(text)

def symbol_pair_test_10(+text: String) -> SymbolPairClass:
  symbol_pair_choice_10(String.eq(text, ">>"), text)

def symbol_pair_choice_9(matched: Bool, text: String) -> SymbolPairClass:
  match matched:
    case True{}:
      SymbolPairMerged{"<<"}
    case False{}:
      symbol_pair_test_10(text)

def symbol_pair_test_9(+text: String) -> SymbolPairClass:
  symbol_pair_choice_9(String.eq(text, "<<"), text)

def symbol_pair_choice_8(matched: Bool, text: String) -> SymbolPairClass:
  match matched:
    case True{}:
      SymbolPairMerged{"++"}
    case False{}:
      symbol_pair_test_9(text)

def symbol_pair_test_8(+text: String) -> SymbolPairClass:
  symbol_pair_choice_8(String.eq(text, "++"), text)

def symbol_pair_choice_7(matched: Bool, text: String) -> SymbolPairClass:
  match matched:
    case True{}:
      SymbolPairMerged{"<>"}
    case False{}:
      symbol_pair_test_8(text)

def symbol_pair_test_7(+text: String) -> SymbolPairClass:
  symbol_pair_choice_7(String.eq(text, "<>"), text)

def symbol_pair_choice_6(matched: Bool, text: String) -> SymbolPairClass:
  match matched:
    case True{}:
      SymbolPairMerged{">="}
    case False{}:
      symbol_pair_test_7(text)

def symbol_pair_test_6(+text: String) -> SymbolPairClass:
  symbol_pair_choice_6(String.eq(text, ">="), text)

def symbol_pair_choice_5(matched: Bool, text: String) -> SymbolPairClass:
  match matched:
    case True{}:
      SymbolPairMerged{"<="}
    case False{}:
      symbol_pair_test_6(text)

def symbol_pair_test_5(+text: String) -> SymbolPairClass:
  symbol_pair_choice_5(String.eq(text, "<="), text)

def symbol_pair_choice_4(matched: Bool, text: String) -> SymbolPairClass:
  match matched:
    case True{}:
      SymbolPairMerged{"!="}
    case False{}:
      symbol_pair_test_5(text)

def symbol_pair_test_4(+text: String) -> SymbolPairClass:
  symbol_pair_choice_4(String.eq(text, "!="), text)

def symbol_pair_choice_3(matched: Bool, text: String) -> SymbolPairClass:
  match matched:
    case True{}:
      SymbolPairMerged{"=="}
    case False{}:
      symbol_pair_test_4(text)

def symbol_pair_test_3(+text: String) -> SymbolPairClass:
  symbol_pair_choice_3(String.eq(text, "=="), text)

def symbol_pair_choice_2(matched: Bool, text: String) -> SymbolPairClass:
  match matched:
    case True{}:
      SymbolPairMerged{"<-"}
    case False{}:
      symbol_pair_test_3(text)

def symbol_pair_test_2(+text: String) -> SymbolPairClass:
  symbol_pair_choice_2(String.eq(text, "<-"), text)

def symbol_pair_choice_1(matched: Bool, text: String) -> SymbolPairClass:
  match matched:
    case True{}:
      SymbolPairMerged{"->"}
    case False{}:
      symbol_pair_test_2(text)

def symbol_pair_test_1(+text: String) -> SymbolPairClass:
  symbol_pair_choice_1(String.eq(text, "->"), text)

def symbol_pair_choice_0(matched: Bool, text: String) -> SymbolPairClass:
  match matched:
    case True{}:
      SymbolPairMerged{"=>"}
    case False{}:
      symbol_pair_test_1(text)

def symbol_pair_test_0(+text: String) -> SymbolPairClass:
  symbol_pair_choice_0(String.eq(text, "=>"), text)

def multi_symbol_2(text: String) -> SymbolPairClass:
  symbol_pair_test_0(text)

def merge_symbol_pair_result(result: SymbolPairClass, beg: Nat, end: Nat, line: Nat, col: Nat, middle_end: Nat) -> SymbolCombineMode:
  match result:
    case SymbolPairMerged{pair}:
      SymbolCombineMerged{Lexer.TokenInfo{Lexer.SymbolToken{}, pair, beg, middle_end, line, col}, 1n}
    case SymbolPairUnmerged{left}:
      SymbolCombineUnmerged{Lexer.TokenInfo{Lexer.SymbolToken{}, left, beg, end, line, col}}

def merge_symbol_pair(is_adjacent: Bool, left: String, right: String, beg: Nat, end: Nat, line: Nat, col: Nat, middle_end: Nat) -> SymbolCombineMode:
  match is_adjacent:
    case True{}:
      merge_symbol_pair_result(multi_symbol_2(String.append(left, right)), beg, end, line, col, middle_end)
    case False{}:
      SymbolCombineUnmerged{Lexer.TokenInfo{Lexer.SymbolToken{}, left, beg, end, line, col}}

def merge_symbol_2(left: String, right: String, beg: Nat, +end: Nat, line: Nat, col: Nat, tokens: List<&2, Lexer.Token>) -> SymbolCombineMode:
  match tokens:
    case +middle <> rest:
      match middle:
        case Lexer.TokenInfo{ Lexer.SymbolToken{}, _, middle_beg, middle_end, _, _}:
          merge_symbol_pair(Nat.is_eq(end, middle_beg), left, right, beg, end, line, col, middle_end)
        case _:
          SymbolCombineUnmerged{Lexer.TokenInfo{Lexer.SymbolToken{}, left, beg, end, line, col}}
    case Nil{}:
      SymbolCombineUnmerged{Lexer.TokenInfo{Lexer.SymbolToken{}, left, beg, end, line, col}}

def merge_symbol_three_result(result: SymbolTripleClass, beg: Nat, end: Nat, line: Nat, col: Nat, last_end: Nat, middle: Lexer.Token, rest: List<&2, Lexer.Token>) -> SymbolCombineMode:
  match result:
    case SymbolTripleMerged{three}:
      SymbolCombineMerged{Lexer.TokenInfo{Lexer.SymbolToken{}, three, beg, last_end, line, col}, 2n}
    case SymbolTripleUnmerged{left, right}:
      merge_symbol_2(left, right, beg, end, line, col, middle <> rest)

def merge_symbol_three(is_adjacent: Bool, text: String, middle: Lexer.Token, rest: List<&2, Lexer.Token>, middle_text: String, last_text: String, last_end: Nat, beg: Nat, end: Nat, line: Nat, col: Nat) -> SymbolCombineMode:
  match is_adjacent:
    case True{}:
      merge_symbol_three_result(multi_symbol_3(String.append(String.append(text, middle_text), last_text)), beg, end, line, col, last_end, middle, rest)
    case False{}:
      merge_symbol_2(text, middle_text, beg, end, line, col, middle <> rest)

def merge_symbol_middle(is_adjacent: Bool, text: String, middle: Lexer.Token, rest: List<&2, Lexer.Token>, middle_text: String, middle_beg: Nat, middle_end: Nat, beg: Nat, end: Nat, line: Nat, col: Nat) -> SymbolCombineMode:
  match is_adjacent rest:
    case True{} +last <> _:
      match last:
        case Lexer.TokenInfo{ Lexer.SymbolToken{}, last_text, last_beg, last_end, _, _}:
          merge_symbol_three(Nat.is_eq(middle_end, last_beg), text, middle, rest, middle_text, last_text, last_end, beg, end, line, col)
        case _:
          merge_symbol_2(text, middle_text, beg, end, line, col, middle <> rest)
    case True{} Nil{}:
      merge_symbol_2(text, middle_text, beg, end, line, col, [middle])
    case False{} _:
      SymbolCombineUnmerged{Lexer.TokenInfo{Lexer.SymbolToken{}, text, beg, end, line, col}}

def merge_symbol(text: String, beg: Nat, +end: Nat, line: Nat, col: Nat, tokens: List<&2, Lexer.Token>) -> SymbolCombineMode:
  match tokens:
    case +middle <> rest:
      match middle:
        case Lexer.TokenInfo{ Lexer.SymbolToken{}, middle_text, middle_beg, middle_end, _, _}:
          merge_symbol_middle(Nat.is_eq(end, middle_beg), text, middle, rest, middle_text, middle_beg, middle_end, beg, end, line, col)
        case _:
          SymbolCombineUnmerged{Lexer.TokenInfo{Lexer.SymbolToken{}, text, beg, end, line, col}}
    case Nil{}:
      SymbolCombineUnmerged{Lexer.TokenInfo{Lexer.SymbolToken{}, text, beg, end, line, col}}

def scan_symbol_mode(token: Lexer.Token, rest: List<&2, Lexer.Token>) -> SymbolCombineMode:
  match token:
    case Lexer.TokenInfo{Lexer.SymbolToken{}, text, beg, end, line, col}:
      merge_symbol(text, beg, end, line, col, rest)
    case _:
      SymbolCombineUnmerged{token}

def combine_symbols(tokens: List<&2, Lexer.Token>, mode: SymbolCombineMode) -> List<&2, Lexer.Token>:
  match tokens mode:
    case +token <> +rest SymbolCombineScan{}:
      combine_symbols(rest, scan_symbol_mode(token, rest))
    case Nil{} SymbolCombineScan{}:
      Nil{}
    case +_ <> rest SymbolCombineMerged{merged, 1n}:
      merged <> combine_symbols(rest, SymbolCombineScan{})
    case +_ <> rest SymbolCombineMerged{merged, 2n}:
      combine_symbols(rest, SymbolCombineSkip{merged})
    case +_ <> rest SymbolCombineMerged{merged, _}:
      merged <> combine_symbols(rest, SymbolCombineScan{})
    case Nil{} SymbolCombineMerged{merged, _}:
      merged <> Nil{}
    case +next <> +rest SymbolCombineUnmerged{token}:
      token <> combine_symbols(rest, scan_symbol_mode(next, rest))
    case Nil{} SymbolCombineUnmerged{token}:
      token <> Nil{}
    case +_ <> rest SymbolCombineSkip{merged}:
      merged <> combine_symbols(rest, SymbolCombineScan{})
    case Nil{} SymbolCombineSkip{merged}:
      merged <> Nil{}


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

def operator_glued_name(end: Nat, tokens: List<&2, Lexer.Token>) -> Bool:
  match tokens:
    case +next <> _:
      match next:
        case Lexer.TokenInfo{ Lexer.NameToken{},  _, beg,  _,  _,  _}:
          Nat.is_eq(end, beg)
        case _:
          False{}
    case Nil{}:
      False{}

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

def parse_string_result(result: Ast.SyntaxTerm & Bool, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case (term, ok):
      ((term, rest), ok)

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

def string_chars_cons_result(result: Ast.SyntaxTerm & Bool, chr: Ast.SyntaxTerm, file: String, beg: Nat, end: Nat) -> Ast.SyntaxTerm & Bool:
  match result:
    case (next, ok):
      (Ast.TermCtr{"SCon", [chr, next], span(file, beg, end)}, ok)

def parse_char_literal_plain_tail(tail: List<&2, Char>, term: Ast.SyntaxTerm, file: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match tail:
    case Nil{}:
      ((term, rest), True{})
    case _:
      ((Ast.TermHole{ "parse-error: invalid character literal",  span(file, beg, end)}, rest), False{})


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

def escape_code_value(code: Nat) -> Maybe<&2, Nat>:
  match code:
    case 110n: Some{10n}
    case 116n: Some{9n}
    case 114n: Some{13n}
    case 48n: Some{0n}
    case 92n: Some{92n}
    case 39n: Some{39n}
    case 34n: Some{34n}
    case _: None{}

def escape_code(char: Char) -> Maybe<&2, Nat>:
  escape_code_value(U32.to_nat(Char.to_u32(char)))

def unicode_hex_digit_above_zero(is_above: Bool, code: Nat) -> Maybe<&2, Nat>:
  match is_above:
    case True{}: Some{code - 48n}
    case False{}: None{}

def unicode_hex_digit_above_a(is_above: Bool, code: Nat) -> Maybe<&2, Nat>:
  match is_above:
    case True{}: Some{code - 87n}
    case False{}: None{}

def unicode_hex_digit_above_A(is_above: Bool, code: Nat) -> Maybe<&2, Nat>:
  match is_above:
    case True{}: Some{code - 55n}
    case False{}: None{}

def unicode_hex_digit_below_A(is_below: Bool, +code: Nat) -> Maybe<&2, Nat>:
  match is_below:
    case True{}:
      unicode_hex_digit_above_A(Nat.is_lt(64n, code), code)
    case False{}:
      None{}

def unicode_hex_digit_below_a(is_below: Bool, +code: Nat) -> Maybe<&2, Nat>:
  match is_below:
    case True{}:
      unicode_hex_digit_above_a(Nat.is_lt(96n, code), code)
    case False{}:
      unicode_hex_digit_below_A(Nat.is_lt(code, 71n), code)

def unicode_hex_digit_below_10(is_below: Bool, +code: Nat) -> Maybe<&2, Nat>:
  match is_below:
    case True{}:
      unicode_hex_digit_above_zero(Nat.is_lt(47n, code), code)
    case False{}:
      unicode_hex_digit_below_a(Nat.is_lt(code, 103n), code)

def unicode_hex_digit_code(+code: Nat) -> Maybe<&2, Nat>:
  unicode_hex_digit_below_10(Nat.is_lt(code, 58n), code)

def unicode_hex_digit(char: Char) -> Maybe<&2, Nat>:
  unicode_hex_digit_code(U32.to_nat(Char.to_u32(char)))

def float_decimal_above_zero(is_above: Bool, code: Nat) -> Maybe<&2, Nat>:
  match is_above:
    case True{}: Some{code - 48n}
    case False{}: None{}

def float_decimal_below_ten(is_below: Bool, +code: Nat) -> Maybe<&2, Nat>:
  match is_below:
    case True{}:
      float_decimal_above_zero(Nat.is_lt(47n, code), code)
    case False{}:
      None{}

def float_decimal_digit(+code: Nat) -> Maybe<&2, Nat>:
  float_decimal_below_ten(Nat.is_lt(code, 58n), code)

def float_scale_positive(exponent_smaller: Bool, mantissa: Nat, fractional: Nat, exponent: Nat) -> FloatParts:
  match exponent_smaller:
    case True{}:
      FloatParts{mantissa,  True{},  fractional - exponent,  True{}}
    case False{}:
      FloatParts{mantissa,  False{},  exponent - fractional,  True{}}

def float_scale(mantissa: Nat, +fractional: Nat, +exponent: Nat, exponent_negative: Bool) -> FloatParts:
  match exponent_negative:
    case True{}:
      FloatParts{mantissa,  True{},  exponent + fractional,  True{}}
    case False{}:
      float_scale_positive(Nat.is_lt(exponent, fractional), mantissa, fractional, exponent)

def parse_unicode_digit_code(chars: List<&2, Char>) -> Nat:
  match chars:
    case +char <> rest:
      U32.to_nat(Char.to_u32(char))
    case Nil{}:
      0n

def parse_unicode_digit_result(chars: List<&2, Char>) -> Maybe<&2, Nat>:
  match chars:
    case +char <> rest:
      unicode_hex_digit(char)
    case Nil{}:
      None{}

def parse_unicode_digits(+chars: List<&2, Char>, acc: Nat, code: Nat, result: Maybe<&2, Nat>) -> (Nat & List<&2, Char>) & Bool:
  match chars:
    case +char <> +rest:
      match code:
        case 125n:
          ((acc, rest), True{})
        case _:
          match result:
            case Some{digit}:
              parse_unicode_digits(rest, acc * 16n + digit, parse_unicode_digit_code(rest), parse_unicode_digit_result(rest))
            case None{}:
              ((0n, chars), False{})
    case Nil{}:
      ((0n, Nil{}), False{})

def parse_unicode_open(code: Nat, chars: List<&2, Char>, +rest: List<&2, Char>, acc: Nat) -> (Nat & List<&2, Char>) & Bool:
  match code:
    case 123n:
      parse_unicode_digits(rest, acc, parse_unicode_digit_code(rest), parse_unicode_digit_result(rest))
    case _:
      ((0n, chars), False{})

def parse_unicode_escape(chars: List<&2, Char>, acc: Nat) -> (Nat & List<&2, Char>) & Bool:
  match chars:
    case +open <> +rest:
      parse_unicode_open(U32.to_nat(Char.to_u32(open)), chars, rest, acc)
    case Nil{}:
      ((0n, Nil{}), False{})

def scan_float_end(mantissa: Nat, fractional: Nat, exponent: Nat, exponent_negative: Bool, valid: Bool, mantissa_digit: Bool, dot_seen: Bool, in_exponent: Bool, exponent_digit: Bool) -> FloatParts:
  match valid mantissa_digit dot_seen in_exponent exponent_digit:
    case True{} True{} True{} False{} _:
      float_scale(mantissa, fractional, exponent, exponent_negative)
    case True{} True{} True{} True{} True{}:
      float_scale(mantissa, fractional, exponent, exponent_negative)
    case _ _ _ _ _:
      FloatParts{mantissa, False{}, 0n, False{}}
def encode_float_subnormal_limit(is_below_limit: Bool, rounded: Nat) -> Nat & Bool:
  match is_below_limit:
    case True{}:
      (rounded, True{})
    case False{}:
      (8388608n, True{})

def round_float_ratio_parity(remainder: Nat, quotient: Nat) -> Nat:
  match remainder:
    case 0n: quotient
    case _: quotient + 1n

def round_float_ratio_above(is_above: Bool, +quotient: Nat, twice: Nat, denominator: Nat) -> Nat:
  match is_above:
    case True{}:
      quotient + 1n
    case False{}:
      round_float_ratio_parity(Nat.mod(quotient, 2n), quotient)

def round_float_ratio_below(is_below: Bool, quotient: Nat, +twice: Nat, +denominator: Nat) -> Nat:
  match is_below:
    case True{}:
      quotient
    case False{}:
      round_float_ratio_above(Nat.is_lt(denominator, twice), quotient, twice, denominator)

def round_float_ratio_parts(parts: Nat & Nat, +denominator: Nat) -> Nat:
  match parts:
    case (quotient, remainder):
      +twice = remainder * 2n
      round_float_ratio_below(Nat.is_lt(twice, denominator), quotient, twice, denominator)

def round_float_ratio(numerator: Nat, +denominator: Nat) -> Nat:
  round_float_ratio_parts(Nat.divmod(numerator, denominator), denominator)
def round_float_scaled(numerator: Nat, denominator: Nat, shift: Nat) -> Nat:
  scaled = numerator * Nat.pow(2n, shift)
  round_float_ratio(scaled, denominator)

def encode_float_subnormal(numerator: Nat, denominator: Nat) -> Nat & Bool:
  +rounded = round_float_scaled(numerator, denominator, 149n)
  encode_float_subnormal_limit(Nat.is_lt(rounded, 8388608n), rounded)

def nat_succ_prefix(+file: String, count: Nat, term: Ast.SyntaxTerm, +beg: Nat, +end: Nat) -> Ast.SyntaxTerm:
  match count:
    case 0n:
      term
    case 1n+rest:
      Ast.TermCtr{ "Succ",  [nat_succ_prefix(file, rest, term, beg, end)],  span(file, beg, end)}

def float_exponent_bits(negative_exponent: Bool, exponent: Nat) -> Nat:
  match negative_exponent:
    case True{}:
      127n - exponent
    case False{}:
      127n + exponent

def encode_float_normal_bits_exact(significand: Nat, negative_exponent: Bool, exponent: Nat) -> Nat & Bool:
  exponent_bits = float_exponent_bits(negative_exponent, exponent)
  bits = exponent_bits * 8388608n + significand - 8388608n
  (bits, True{})

def encode_float_normal_rounding_limit(is_below_limit: Bool, significand: Nat, negative_exponent: Bool, exponent: Nat) -> Nat & Bool:
  match is_below_limit:
    case True{}:
      encode_float_normal_bits_exact(significand, negative_exponent, exponent)
    case False{}:
      match negative_exponent:
        case True{}:
          exponent_bits = 128n - exponent
          (exponent_bits * 8388608n, True{})
        case False{}:
          match exponent:
            case 127n: (0n, False{})
            case _: ((exponent + 128n) * 8388608n, True{})

type FloatScanStep is Data:
  FloatScanContinue{mantissa: Nat, fractional: Nat, dot_seen: Bool, in_exponent: Bool, exponent: Nat, exponent_negative: Bool, exponent_sign: Bool, mantissa_digit: Bool, exponent_digit: Bool, valid: Bool}
  FloatScanDone{parts: FloatParts}

def scan_float_dot(in_exponent: Bool, dot_seen: Bool, mantissa: Nat, fractional: Nat, exponent: Nat, exponent_negative: Bool, exponent_sign: Bool, mantissa_digit: Bool, exponent_digit: Bool, valid: Bool) -> FloatScanStep:
  match in_exponent dot_seen:
    case False{} False{}:
      FloatScanContinue{mantissa, fractional, True{}, False{}, exponent, exponent_negative, exponent_sign, mantissa_digit, exponent_digit, valid}
    case _ _:
      FloatScanDone{FloatParts{mantissa, False{}, 0n, False{}}}

def scan_float_sign(is_negative: Bool, in_exponent: Bool, exponent_digit: Bool, exponent_sign: Bool, mantissa: Nat, fractional: Nat, dot_seen: Bool, exponent: Nat, mantissa_digit: Bool, valid: Bool) -> FloatScanStep:
  match in_exponent exponent_digit exponent_sign:
    case True{} False{} False{}:
      FloatScanContinue{mantissa, fractional, dot_seen, True{}, exponent, is_negative, True{}, mantissa_digit, exponent_digit, valid}
    case _ _ _:
      FloatScanDone{FloatParts{mantissa, False{}, 0n, False{}}}

def scan_float_mantissa_digit(digit: Nat, dot_seen: Bool, mantissa: Nat, fractional: Nat, exponent: Nat, exponent_negative: Bool, exponent_sign: Bool, exponent_digit: Bool, valid: Bool) -> FloatScanStep:
  match dot_seen:
    case True{}:
      FloatScanContinue{mantissa * 10n + digit, fractional + 1n, dot_seen, False{}, exponent, exponent_negative, exponent_sign, True{}, exponent_digit, valid}
    case False{}:
      FloatScanContinue{mantissa * 10n + digit, fractional, dot_seen, False{}, exponent, exponent_negative, exponent_sign, True{}, exponent_digit, valid}

def scan_float_valid_digit(in_exponent: Bool, digit: Nat, dot_seen: Bool, mantissa: Nat, fractional: Nat, exponent: Nat, exponent_negative: Bool, exponent_sign: Bool, mantissa_digit: Bool, exponent_digit: Bool, valid: Bool) -> FloatScanStep:
  match in_exponent:
    case True{}:
      FloatScanContinue{mantissa, fractional, dot_seen, True{}, exponent * 10n + digit, exponent_negative, exponent_sign, mantissa_digit, True{}, valid}
    case False{}:
      scan_float_mantissa_digit(digit, dot_seen, mantissa, fractional, exponent, exponent_negative, exponent_sign, exponent_digit, valid)

def scan_float_digit(result: Maybe<&2, Nat>, in_exponent: Bool, dot_seen: Bool, mantissa: Nat, fractional: Nat, exponent: Nat, exponent_negative: Bool, exponent_sign: Bool, mantissa_digit: Bool, exponent_digit: Bool, valid: Bool) -> FloatScanStep:
  match result:
    case Some{digit}:
      scan_float_valid_digit(in_exponent, digit, dot_seen, mantissa, fractional, exponent, exponent_negative, exponent_sign, mantissa_digit, exponent_digit, valid)
    case None{}:
      FloatScanDone{FloatParts{mantissa, False{}, 0n, False{}}}

def scan_float_exponent_mantissa(mantissa_digit: Bool, mantissa: Nat, fractional: Nat, dot_seen: Bool, exponent: Nat, exponent_negative: Bool, exponent_sign: Bool, valid: Bool) -> FloatScanStep:
  match mantissa_digit:
    case True{}:
      FloatScanContinue{mantissa, fractional, dot_seen, True{}, exponent, exponent_negative, False{}, True{}, False{}, valid}
    case False{}:
      FloatScanDone{FloatParts{mantissa, False{}, 0n, False{}}}

def scan_float_exponent_dot(dot_seen: Bool, mantissa_digit: Bool, mantissa: Nat, fractional: Nat, exponent: Nat, exponent_negative: Bool, exponent_sign: Bool, valid: Bool) -> FloatScanStep:
  match dot_seen:
    case True{}:
      scan_float_exponent_mantissa(mantissa_digit, mantissa, fractional, dot_seen, exponent, exponent_negative, exponent_sign, valid)
    case False{}:
      FloatScanDone{FloatParts{mantissa, False{}, 0n, False{}}}

def scan_float_exponent(in_exponent: Bool, dot_seen: Bool, mantissa_digit: Bool, mantissa: Nat, fractional: Nat, exponent: Nat, exponent_negative: Bool, exponent_sign: Bool, valid: Bool) -> FloatScanStep:
  match in_exponent:
    case False{}:
      scan_float_exponent_dot(dot_seen, mantissa_digit, mantissa, fractional, exponent, exponent_negative, exponent_sign, valid)
    case True{}:
      FloatScanDone{FloatParts{mantissa, False{}, 0n, False{}}}

def scan_float_code(+code: Nat, mantissa: Nat, fractional: Nat, dot_seen: Bool, in_exponent: Bool, exponent: Nat, exponent_negative: Bool, exponent_sign: Bool, mantissa_digit: Bool, exponent_digit: Bool, valid: Bool) -> FloatScanStep:
  match code:
    case 46n:
      scan_float_dot(in_exponent, dot_seen, mantissa, fractional, exponent, exponent_negative, exponent_sign, mantissa_digit, exponent_digit, valid)
    case 101n:
      scan_float_exponent(in_exponent, dot_seen, mantissa_digit, mantissa, fractional, exponent, exponent_negative, exponent_sign, valid)
    case 69n:
      scan_float_exponent(in_exponent, dot_seen, mantissa_digit, mantissa, fractional, exponent, exponent_negative, exponent_sign, valid)
    case 43n:
      scan_float_sign(False{}, in_exponent, exponent_digit, exponent_sign, mantissa, fractional, dot_seen, exponent, mantissa_digit, valid)
    case 45n:
      scan_float_sign(True{}, in_exponent, exponent_digit, exponent_sign, mantissa, fractional, dot_seen, exponent, mantissa_digit, valid)
    case _:
      scan_float_digit(float_decimal_digit(code), in_exponent, dot_seen, mantissa, fractional, exponent, exponent_negative, exponent_sign, mantissa_digit, exponent_digit, valid)

def scan_float_step(chars: List<&2, Char>, mantissa: Nat, fractional: Nat, dot_seen: Bool, in_exponent: Bool, exponent: Nat, exponent_negative: Bool, exponent_sign: Bool, mantissa_digit: Bool, exponent_digit: Bool, valid: Bool) -> FloatScanStep:
  match chars:
    case Nil{}:
      FloatScanDone{scan_float_end(mantissa, fractional, exponent, exponent_negative, valid, mantissa_digit, dot_seen, in_exponent, exponent_digit)}
    case +char <> rest:
      scan_float_code(U32.to_nat(Char.to_u32(char)), mantissa, fractional, dot_seen, in_exponent, exponent, exponent_negative, exponent_sign, mantissa_digit, exponent_digit, valid)

def scan_float_go(chars: List<&2, Char>, step: FloatScanStep) -> FloatParts:
  match chars:
    case Nil{}:
      match step:
        case FloatScanDone{parts}:
          parts
        case FloatScanContinue{+mantissa, +fractional, +dot_seen, +in_exponent, +exponent, +exponent_negative, +exponent_sign, +mantissa_digit, +exponent_digit, +valid}:
          scan_float_end(mantissa, fractional, exponent, exponent_negative, valid, mantissa_digit, dot_seen, in_exponent, exponent_digit)
    case +_ <> +rest:
      match step:
        case FloatScanDone{parts}:
          parts
        case FloatScanContinue{+mantissa, +fractional, +dot_seen, +in_exponent, +exponent, +exponent_negative, +exponent_sign, +mantissa_digit, +exponent_digit, +valid}:
          scan_float_go(rest, scan_float_step(rest, mantissa, fractional, dot_seen, in_exponent, exponent, exponent_negative, exponent_sign, mantissa_digit, exponent_digit, valid))

def scan_float(+chars: List<&2, Char>, mantissa: Nat, fractional: Nat, dot_seen: Bool, in_exponent: Bool, exponent: Nat, exponent_negative: Bool, exponent_sign: Bool, mantissa_digit: Bool, exponent_digit: Bool, valid: Bool) -> FloatParts:
  scan_float_go(chars, scan_float_step(chars, mantissa, fractional, dot_seen, in_exponent, exponent, exponent_negative, exponent_sign, mantissa_digit, exponent_digit, valid))
def encode_float_normal_bits(+significand: Nat, negative_exponent: Bool, exponent: Nat) -> Nat & Bool:
  encode_float_normal_rounding_limit(Nat.is_lt(significand, 16777216n), significand, negative_exponent, exponent)

def encode_float_normal_negative(is_too_large: Bool, numerator: Nat, denominator: Nat, +exponent: Nat) -> Nat & Bool:
  match is_too_large:
    case True{}:
      encode_float_subnormal(numerator, denominator)
    case False{}:
      shift = 23n + exponent
      rounded = round_float_scaled(numerator, denominator, shift)
      encode_float_normal_bits(rounded, True{}, exponent)

def encode_float_normal_positive_small(is_small: Bool, numerator: Nat, denominator: Nat, +exponent: Nat) -> Nat & Bool:
  match is_small:
    case True{}:
      shift = 23n - exponent
      rounded = round_float_scaled(numerator, denominator, shift)
      encode_float_normal_bits(rounded, False{}, exponent)
    case False{}:
      shift = exponent - 23n
      scaled_denominator = denominator * Nat.pow(2n, shift)
      rounded = round_float_scaled(numerator, scaled_denominator, 0n)
      encode_float_normal_bits(rounded, False{}, exponent)

def encode_float_normal_positive(is_too_large: Bool, numerator: Nat, denominator: Nat, +exponent: Nat) -> Nat & Bool:
  match is_too_large:
    case True{}:
      (0n, False{})
    case False{}:
      encode_float_normal_positive_small(Nat.is_lt(exponent, 23n), numerator, denominator, exponent)

def encode_float_normal(numerator: Nat, denominator: Nat, negative_exponent: Bool, +exponent: Nat) -> Nat & Bool:
  match negative_exponent:
    case True{}:
      encode_float_normal_negative(Nat.is_lt(126n, exponent), numerator, denominator, exponent)
    case False{}:
      encode_float_normal_positive(Nat.is_lt(127n, exponent), numerator, denominator, exponent)

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

def encode_float_positive_go(remaining: Nat, is_below: Bool, original_numerator: Nat, original_denominator: Nat, +test_numerator: Nat, +test_denominator: Nat, exponent: Nat) -> Nat & Bool:
  match remaining:
    case 0n:
      (0n, False{})
    case 1n+rest:
      match is_below:
        case True{}:
          encode_float_normal(original_numerator, original_denominator, False{}, exponent)
        case False{}:
          encode_float_positive_go(rest, Nat.is_lt(test_numerator, test_denominator * 4n), original_numerator, original_denominator, test_numerator, test_denominator * 2n, exponent + 1n)

def encode_float_positive(original_numerator: Nat, original_denominator: Nat, +test_numerator: Nat, +test_denominator: Nat, +exponent: Nat) -> Nat & Bool:
  encode_float_positive_go(Nat.sub(128n, exponent), Nat.is_lt(test_numerator, test_denominator * 2n), original_numerator, original_denominator, test_numerator, test_denominator, exponent)

def encode_float_negative_go(remaining: Nat, +is_below: Bool, original_numerator: Nat, original_denominator: Nat, test_numerator: Nat, +test_denominator: Nat, exponent: Nat) -> Nat & Bool:
  match remaining:
    case 0n:
      match is_below:
        case False{}:
          encode_float_normal(original_numerator, original_denominator, True{}, exponent)
        case True{}:
          encode_float_subnormal(original_numerator, original_denominator)
    case 1n+rest:
      match is_below:
        case False{}:
          encode_float_normal(original_numerator, original_denominator, True{}, exponent)
        case True{}:
          +next_numerator = test_numerator * 2n
          next_below = Nat.is_lt(next_numerator, test_denominator)
          encode_float_negative_go(rest, next_below, original_numerator, original_denominator, next_numerator, test_denominator, exponent + 1n)

def encode_float_negative(original_numerator: Nat, original_denominator: Nat, +test_numerator: Nat, +test_denominator: Nat, +exponent: Nat) -> Nat & Bool:
  encode_float_negative_go(Nat.sub(127n, exponent), Nat.is_lt(test_numerator, test_denominator), original_numerator, original_denominator, test_numerator, test_denominator, exponent)

def encode_float32_lt_one(less_than_one: Bool, +numerator: Nat, +denominator: Nat) -> Nat & Bool:
  match less_than_one:
    case True{}:
      encode_float_negative(numerator, denominator, numerator, denominator, 0n)
    case False{}:
      encode_float_positive(numerator, denominator, numerator, denominator, 0n)

def encode_float32(+numerator: Nat, +denominator: Nat) -> Nat & Bool:
  encode_float32_lt_one(Nat.is_lt(numerator, denominator), numerator, denominator)

def float32_parts(parts: FloatParts) -> Nat & Bool:
  match parts:
    case FloatParts{ 0n,  _,  _,  True{}}:
      (0n, True{})
    case FloatParts{mantissa, True{}, scale, True{}}:
      denominator = Nat.pow(10n, scale)
      encode_float32(mantissa, denominator)
    case FloatParts{mantissa, False{}, scale, True{}}:
      numerator = mantissa * Nat.pow(10n, scale)
      encode_float32(numerator, 1n)
    case _:
      (0n, False{})

def float32_bits(text: String) -> Nat & Bool:
  float32_parts(scan_float(String.to_list(text), 0n, 0n, False{}, False{}, 0n, False{}, False{}, False{}, False{}, True{}))

def has_nat_suffix(text: String) -> Bool:
  has_nat_suffix_reversed(List.reverse(&2, Char, String.to_list(text)))

def drop_nat_suffix(+text: String) -> String:
  drop_nat_suffix_reversed(List.reverse(&2, Char, String.to_list(text)), text)

def u32_bit(file: String, bit_value: Nat, beg: Nat, end: Nat) -> Ast.SyntaxTerm:
  match bit_value:
    case 0n: Ast.TermCtr{ "False",  Nil{},  span(file, beg, end)}
    case _: Ast.TermCtr{ "True",  Nil{},  span(file, beg, end)}
def expr_finish_list(result: Ast.SyntaxTerm & Bool, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case (list, good):
      ((list, rest), good)

def array_call_result(result: Ast.SyntaxTerm & Bool, after: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case (term, ok):
      ((term, after), ok)

def nat_from_syntax_successor(result: Maybe<&2, Nat>) -> Maybe<&2, Nat>:
  match result:
    case Some{value}: Some{value + 1n}
    case None{}: None{}

 

def make_list_cons(item: Ast.SyntaxTerm, result: Ast.SyntaxTerm & Bool, file: String, beg: Nat, end: Nat) -> Ast.SyntaxTerm & Bool:
  match result:
    case (tail, ok):
      (Ast.TermCtr{"Con", [item, tail], span(file, beg, end)}, ok)

def u32_bits(+file: String, remaining: Nat, +value: Nat, +beg: Nat, +end: Nat) -> Ast.SyntaxTerm:
  match remaining:
    case 0n:
      Ast.TermCtr{ "WNil",  Nil{},  span(file, beg, end)}
    case 1n+rest:
      bit = u32_bit(file, Nat.mod(value, 2n), beg, end)
      Ast.TermCtr{ "WCon",  [bit, u32_bits(file, rest, Nat.div(value, 2n), beg, end)],  span(file, beg, end)}


def u32_literal(+file: String, value: Nat, +beg: Nat, +end: Nat) -> Ast.SyntaxTerm:
  word = u32_bits(file, 32n, value, beg, end)
  Ast.TermCtr{ "U32",  [word],  span(file, beg, end)}

def character_term(+file: String, value: Nat, +beg: Nat, +end: Nat) -> Ast.SyntaxTerm:
  Ast.TermCtr{ "Chr",  [u32_literal(file, value, beg, end)],  span(file, beg, end)}

type StringCharsInput is Data:
  StringCharsText{char: Char}
  StringCharsBackslash{}
  StringCharsValue{value: Nat}
  StringCharsUnicodeStart{}
  StringCharsUnicodeDigits{acc: Nat}
  StringCharsInvalidEscape{}
  StringCharsInvalidUnicode{}

def string_chars_after_char(is_escape: Bool, char: Char) -> StringCharsInput:
  match is_escape:
    case True{}:
      StringCharsBackslash{}
    case False{}:
      StringCharsText{char}

def string_chars_escape_codepoint(code: Nat) -> StringCharsInput:
  match code:
    case 117n:
      StringCharsUnicodeStart{}
    case _:
      StringCharsInvalidEscape{}

def string_chars_escape_result(result: Maybe<&2, Nat>, code: Nat) -> StringCharsInput:
  match result:
    case Some{value}:
      StringCharsValue{value}
    case None{}:
      string_chars_escape_codepoint(code)

def string_chars_unicode_open(code: Nat) -> StringCharsInput:
  match code:
    case 123n:
      StringCharsUnicodeDigits{0n}
    case _:
      StringCharsInvalidUnicode{}

def string_chars_unicode_digit_result(result: Maybe<&2, Nat>, acc: Nat) -> StringCharsInput:
  match result:
    case Some{digit}:
      StringCharsUnicodeDigits{acc * 16n + digit}
    case None{}:
      StringCharsInvalidUnicode{}

def string_chars_unicode_result(code: Nat, result: Maybe<&2, Nat>, acc: Nat) -> StringCharsInput:
  match code:
    case 125n:
      StringCharsValue{acc}
    case _:
      string_chars_unicode_digit_result(result, acc)

def string_chars_go(+file: String, remaining: List<&2, Char>, +input: StringCharsInput, +beg: Nat, +end: Nat) -> Ast.SyntaxTerm & Bool:
  match remaining:
    case Nil{}:
      match input:
        case StringCharsText{+char}:
          string_chars_cons_result((Ast.TermCtr{"SNil", Nil{}, span(file, beg, end)}, True{}), character_term(file, U32.to_nat(Char.to_u32(char)), beg, end), file, beg, end)
        case StringCharsBackslash{}:
          (Ast.TermHole{"parse-error: incomplete string escape", span(file, beg, end)}, False{})
        case StringCharsValue{+value}:
          string_chars_cons_result((Ast.TermCtr{"SNil", Nil{}, span(file, beg, end)}, True{}), character_term(file, value, beg, end), file, beg, end)
        case StringCharsUnicodeStart{}:
          (Ast.TermHole{"parse-error: invalid unicode escape", span(file, beg, end)}, False{})
        case StringCharsUnicodeDigits{_}:
          (Ast.TermHole{"parse-error: invalid unicode escape", span(file, beg, end)}, False{})
        case StringCharsInvalidEscape{}:
          (Ast.TermHole{"parse-error: invalid string escape", span(file, beg, end)}, False{})
        case StringCharsInvalidUnicode{}:
          (Ast.TermHole{"parse-error: invalid unicode escape", span(file, beg, end)}, False{})
    case +next <> +tail:
      match input:
        case StringCharsText{+char}:
          string_chars_cons_result(string_chars_go(file, tail, string_chars_after_char(Char.is_eq(next, Char.from_u32(92)), next), beg, end), character_term(file, U32.to_nat(Char.to_u32(char)), beg, end), file, beg, end)
        case StringCharsBackslash{}:
          string_chars_go(file, tail, string_chars_escape_result(escape_code(next), U32.to_nat(Char.to_u32(next))), beg, end)
        case StringCharsValue{+value}:
          string_chars_cons_result(string_chars_go(file, tail, string_chars_after_char(Char.is_eq(next, Char.from_u32(92)), next), beg, end), character_term(file, value, beg, end), file, beg, end)
        case StringCharsUnicodeStart{}:
          string_chars_go(file, tail, string_chars_unicode_open(U32.to_nat(Char.to_u32(next))), beg, end)
        case StringCharsUnicodeDigits{+acc}:
          string_chars_go(file, tail, string_chars_unicode_result(U32.to_nat(Char.to_u32(next)), unicode_hex_digit(next), acc), beg, end)
        case StringCharsInvalidEscape{}:
          (Ast.TermHole{"parse-error: invalid string escape", span(file, beg, end)}, False{})
        case StringCharsInvalidUnicode{}:
          (Ast.TermHole{"parse-error: invalid unicode escape", span(file, beg, end)}, False{})

def string_chars(+file: String, chars: List<&2, Char>, beg: Nat, end: Nat) -> Ast.SyntaxTerm & Bool:
  match chars:
    case Nil{}:
      (Ast.TermCtr{"SNil", Nil{}, span(file, beg, end)}, True{})
    case +char <> rest:
      string_chars_go(file, rest, string_chars_after_char(Char.is_eq(char, Char.from_u32(92)), char), beg, end)

def parse_char_literal_unicode_result(result: (Nat & List<&2, Char>) & Bool, file: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((value, Nil{}), True{}):
      ((character_term(file, value, beg, end), rest), True{})
    case _:
      ((Ast.TermHole{"parse-error: invalid unicode character escape", span(file, beg, end)}, rest), False{})

def parse_char_literal_escape_codepoint(code: Nat, after_escape: List<&2, Char>, file: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match code:
    case 117n:
      parse_char_literal_unicode_result(parse_unicode_escape(after_escape, 0n), file, beg, end, rest)
    case _:
      ((Ast.TermHole{"parse-error: invalid character escape", span(file, beg, end)}, rest), False{})

def parse_char_literal_escape_result(result: Maybe<&2, Nat>, escaped: Char, after_escape: List<&2, Char>, +file: String, +beg: Nat, +end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case Some{value}:
      parse_char_literal_plain_tail(after_escape, character_term(file, value, beg, end), file, beg, end, rest)
    case None{}:
      parse_char_literal_escape_codepoint(U32.to_nat(Char.to_u32(escaped)), after_escape, file, beg, end, rest)

def parse_char_literal_after_char(is_escape: Bool, char: Char, tail: List<&2, Char>, +file: String, +beg: Nat, +end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_escape:
    case True{}:
      match tail:
        case +escaped <> after_escape:
          parse_char_literal_escape_result(escape_code(escaped), escaped, after_escape, file, beg, end, rest)
        case Nil{}:
          ((Ast.TermHole{ "parse-error: invalid character literal",  span(file, beg, end)}, rest), False{})
    case False{}:
      parse_char_literal_plain_tail(tail, character_term(file, U32.to_nat(Char.to_u32(char)), beg, end), file, beg, end, rest)

def parse_char_literal_chars(chars: List<&2, Char>, file: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match chars:
    case +char <> tail:
      parse_char_literal_after_char(Char.is_eq(char, Char.from_u32(92)), char, tail, file, beg, end, rest)
    case Nil{}:
      ((Ast.TermHole{ "parse-error: empty character literal",  span(file, beg, end)}, rest), False{})

def parse_number_float_result(result: Nat & Bool, +file: String, +beg: Nat, +end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case (bits, True{}):
      ((Ast.TermCtr{"F32", [u32_literal(file, bits, beg, end)], span(file, beg, end)}, rest), True{})
    case (_, False{}):
      ((Ast.TermHole{"parse-error: unsupported or non-finite numeric literal", span(file, beg, end)}, rest), False{})

def parse_number_missing_nat(has_suffix: Bool, file: String, text: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match has_suffix:
    case True{}:
      ((Ast.TermHole{ "parse-error: invalid natural literal",  span(file, beg, end)}, rest), False{})
    case False{}:
      parse_number_float_result(float32_bits(text), file, beg, end, rest)

def make_tuple_cons(first: Ast.SyntaxTerm, result: Ast.SyntaxTerm & Bool, file: String, beg: Nat, end: Nat) -> Ast.SyntaxTerm & Bool:
  match result:
    case (tail, ok):
      (Ast.TermCtr{"Tuple", [first, tail], span(file, beg, end)}, ok)

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

def parse_parenthesized_tuple_result(result: Ast.SyntaxTerm & Bool, after: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case (tuple, good):
      ((tuple, after), good)

def parse_parenthesized_body_result(body: Ast.SyntaxTerm, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match body:
    case Ast.BodyReply{term,  _}:
      ((term, rest), True{})
    case _:
      ((body, rest), True{})

def operator_key_choice_13(mapped: Bool, key: String, namespace: String) -> String:
  match mapped:
    case True{}:
      String.append(namespace, key)
    case False{}:
      key

def operator_key_test_13(+key: String, namespace: String) -> String:
  operator_key_choice_13(String.eq(key, ".mod"), key, namespace)

def operator_key_choice_12(mapped: Bool, key: String, namespace: String) -> String:
  match mapped:
    case True{}:
      String.append(namespace, key)
    case False{}:
      operator_key_test_13(key, namespace)

def operator_key_test_12(+key: String, namespace: String) -> String:
  operator_key_choice_12(String.eq(key, ".div"), key, namespace)

def operator_key_choice_11(mapped: Bool, key: String, namespace: String) -> String:
  match mapped:
    case True{}:
      String.append(namespace, key)
    case False{}:
      operator_key_test_12(key, namespace)

def operator_key_test_11(+key: String, namespace: String) -> String:
  operator_key_choice_11(String.eq(key, ".mul"), key, namespace)

def operator_key_choice_10(mapped: Bool, key: String, namespace: String) -> String:
  match mapped:
    case True{}:
      String.append(namespace, key)
    case False{}:
      operator_key_test_11(key, namespace)

def operator_key_test_10(+key: String, namespace: String) -> String:
  operator_key_choice_10(String.eq(key, ".sub"), key, namespace)

def operator_key_choice_9(mapped: Bool, key: String, namespace: String) -> String:
  match mapped:
    case True{}:
      String.append(namespace, key)
    case False{}:
      operator_key_test_10(key, namespace)

def operator_key_test_9(+key: String, namespace: String) -> String:
  operator_key_choice_9(String.eq(key, ".add"), key, namespace)

def operator_key_choice_8(mapped: Bool, key: String, namespace: String) -> String:
  match mapped:
    case True{}:
      String.append(namespace, key)
    case False{}:
      operator_key_test_9(key, namespace)

def operator_key_test_8(+key: String, namespace: String) -> String:
  operator_key_choice_8(String.eq(key, ".shrn"), key, namespace)

def operator_key_choice_7(mapped: Bool, key: String, namespace: String) -> String:
  match mapped:
    case True{}:
      String.append(namespace, key)
    case False{}:
      operator_key_test_8(key, namespace)

def operator_key_test_7(+key: String, namespace: String) -> String:
  operator_key_choice_7(String.eq(key, ".shln"), key, namespace)

def operator_key_choice_6(mapped: Bool, key: String, namespace: String) -> String:
  match mapped:
    case True{}:
      String.append(namespace, key)
    case False{}:
      operator_key_test_7(key, namespace)

def operator_key_test_6(+key: String, namespace: String) -> String:
  operator_key_choice_6(String.eq(key, ".is_gt"), key, namespace)

def operator_key_choice_5(mapped: Bool, key: String, namespace: String) -> String:
  match mapped:
    case True{}:
      String.append(namespace, key)
    case False{}:
      operator_key_test_6(key, namespace)

def operator_key_test_5(+key: String, namespace: String) -> String:
  operator_key_choice_5(String.eq(key, ".is_ge"), key, namespace)

def operator_key_choice_4(mapped: Bool, key: String, namespace: String) -> String:
  match mapped:
    case True{}:
      String.append(namespace, key)
    case False{}:
      operator_key_test_5(key, namespace)

def operator_key_test_4(+key: String, namespace: String) -> String:
  operator_key_choice_4(String.eq(key, ".is_le"), key, namespace)

def operator_key_choice_3(mapped: Bool, key: String, namespace: String) -> String:
  match mapped:
    case True{}:
      String.append(namespace, key)
    case False{}:
      operator_key_test_4(key, namespace)

def operator_key_test_3(+key: String, namespace: String) -> String:
  operator_key_choice_3(String.eq(key, ".is_lt"), key, namespace)

def operator_key_choice_2(mapped: Bool, key: String, namespace: String) -> String:
  match mapped:
    case True{}:
      String.append(namespace, key)
    case False{}:
      operator_key_test_3(key, namespace)

def operator_key_test_2(+key: String, namespace: String) -> String:
  operator_key_choice_2(String.eq(key, ".and"), key, namespace)

def operator_key_choice_1(mapped: Bool, key: String, namespace: String) -> String:
  match mapped:
    case True{}:
      String.append(namespace, key)
    case False{}:
      operator_key_test_2(key, namespace)

def operator_key_test_1(+key: String, namespace: String) -> String:
  operator_key_choice_1(String.eq(key, ".xor"), key, namespace)

def operator_key_choice_0(mapped: Bool, key: String, namespace: String) -> String:
  match mapped:
    case True{}:
      String.append(namespace, key)
    case False{}:
      operator_key_test_1(key, namespace)

def operator_key_test_0(+key: String, namespace: String) -> String:
  operator_key_choice_0(String.eq(key, ".or"), key, namespace)

def map_operator_key(namespace: String, key: String) -> String:
  operator_key_test_0(key, namespace)

def match_tail_branch_0(tail: Ast.SyntaxTerm, after_end: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((tail, after_end), True{})

def match_tail_branch_1(file: String, rest: List<&2, Lexer.Token>, +end: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected } after match tail",  span(file, token_beg(end), token_end(end))}, rest), False{})

def match_tail_is_colon(end: Lexer.Token) -> Bool:
  match end:
    case Lexer.TokenInfo{ _, "}",  _,  _,  _,  _}:
      True{}
    case _:
      False{}

def match_tail_run(is_colon: Bool, file: String, tail: Ast.SyntaxTerm, rest: List<&2, Lexer.Token>, +end: Lexer.Token, after_end: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  match is_colon:
    case True{}:
      match_tail_branch_0(tail, after_end)
    case False{}:
      match_tail_branch_1(file, rest, end)

def parse_match_tail_after_semicolon(file: String, tail: Ast.SyntaxTerm, close: Lexer.Token, rest: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match scanned:
    case +end <> after_end:
      match_tail_run(match_tail_is_colon(end), file, tail, rest, end, after_end)
    case Nil{}:
      +at = token_end(close)
      ((Ast.TermHole{ "parse-error: expected } after match tail",  span(file, at, at)}, rest), False{})

def parse_brace_equal_type_result(ok_ty: Bool, after_ty: List<&2, Lexer.Token>, ty: Ast.SyntaxTerm, file: String, left: Ast.SyntaxTerm, right: Ast.SyntaxTerm, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_ty after_ty:
    case True{} +close <> tail:
      match close:
        case Lexer.TokenInfo{ _, "}",  _,  _,  _,  _}:
          ((Ast.TermEqual{left, right, ty,  span(file, beg, token_end(close))}, tail), True{})
        case _:
          ((Ast.TermHole{ "parse-error: expected }",  span(file, token_beg(close), token_end(close))}, after_ty), False{})
    case _ _:
      ((ty, after_ty), False{})

def brace_annot_branch_0(after_ty: List<&2, Lexer.Token>, ty: Ast.SyntaxTerm, file: String, left: Ast.SyntaxTerm, beg: Nat, +close: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermAnn{ left, ty,  span(file, beg, token_end(close))}, List.tail(&2, Lexer.Token, after_ty)), True{})

def brace_annot_branch_1(after_ty: List<&2, Lexer.Token>, file: String, +close: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected }",  span(file, token_beg(close), token_end(close))}, after_ty), False{})

def brace_annot_is_colon(close: Lexer.Token) -> Bool:
  match close:
    case Lexer.TokenInfo{ _, "}",  _,  _,  _,  _}:
      True{}
    case _:
      False{}

def brace_annot_run(is_colon: Bool, after_ty: List<&2, Lexer.Token>, ty: Ast.SyntaxTerm, file: String, left: Ast.SyntaxTerm, beg: Nat, +close: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  match is_colon:
    case True{}:
      brace_annot_branch_0(after_ty, ty, file, left, beg, close)
    case False{}:
      brace_annot_branch_1(after_ty, file, close)

def parse_brace_annot_type_result(ok_ty: Bool, after_ty: List<&2, Lexer.Token>, ty: Ast.SyntaxTerm, file: String, left: Ast.SyntaxTerm, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_ty after_ty:
    case True{} +close <> tail:
      brace_annot_run(brace_annot_is_colon(close), after_ty, ty, file, left, beg, close)
    case _ _:
      ((ty, after_ty), False{})

def inequality_branch_0(ty: Ast.SyntaxTerm, after_ty: List<&2, Lexer.Token>, file: String, left: Ast.SyntaxTerm, right: Ast.SyntaxTerm, beg: Nat, depth: Nat, +close: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  +span_value = span(file, beg, token_end(close))
  ((Ast.TermAll{Ast.QOne{}, "_", depth, Ast.TermEqual{left, right, ty, span_value}, Ast.TermRef{"Empty", span_value}, span_value}, List.tail(&2, Lexer.Token, after_ty)), True{})

def inequality_branch_1(after_ty: List<&2, Lexer.Token>, file: String, +close: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{"parse-error: expected }", span(file, token_beg(close), token_end(close))}, after_ty), False{})

def inequality_is_colon(close: Lexer.Token) -> Bool:
  match close:
    case Lexer.TokenInfo{ _, "}", _, _, _, _}:
      True{}
    case _:
      False{}

def inequality_run(is_colon: Bool, ty: Ast.SyntaxTerm, after_ty: List<&2, Lexer.Token>, file: String, left: Ast.SyntaxTerm, right: Ast.SyntaxTerm, beg: Nat, depth: Nat, +close: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  match is_colon:
    case True{}:
      inequality_branch_0(ty, after_ty, file, left, right, beg, depth, close)
    case False{}:
      inequality_branch_1(after_ty, file, close)

def parse_inequality_type_result(ok_ty: Bool, ty: Ast.SyntaxTerm, after_ty: List<&2, Lexer.Token>, file: String, left: Ast.SyntaxTerm, right: Ast.SyntaxTerm, beg: Nat, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_ty after_ty:
    case True{} +close <> tail:
      inequality_run(inequality_is_colon(close), ty, after_ty, file, left, right, beg, depth, close)
    case _ _:
      ((ty, after_ty), False{})

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

def parse_nat_literal_prefix(is_large: Bool, +file: String, value: Nat, +beg: Nat, +end: Nat, +after_tail: List<&2, Lexer.Token>, tail: Ast.SyntaxTerm) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_large:
    case True{}:
      base = nat_literal(file, value, beg, end)
      +operator_span = span(file, beg, token_end_of(after_tail, end))
      ((Ast.TermApp{Ast.TermApp{Ast.TermRef{"Nat.add", operator_span}, base, operator_span}, tail, operator_span}, after_tail), True{})
    case False{}:
      ((nat_succ_prefix(file, value, tail, beg, token_end_of(after_tail, end)), after_tail), True{})

type SyntaxWordStep is Data:
  SyntaxWordZeroBit{}
  SyntaxWordOneBit{}
  SyntaxWordInvalidBit{}
  SyntaxWordOther{}

def syntax_word_bit(bit: Ast.SyntaxTerm) -> SyntaxWordStep:
  match bit:
    case Ast.TermCtr{"False", Nil{}, _}:
      SyntaxWordZeroBit{}
    case Ast.TermCtr{"True", Nil{}, _}:
      SyntaxWordOneBit{}
    case _:
      SyntaxWordInvalidBit{}

def syntax_word_step(term: Ast.SyntaxTerm) -> SyntaxWordStep:
  match term:
    case Ast.TermCtr{"WCon", [bit, _], _}:
      syntax_word_bit(bit)
    case _:
      SyntaxWordOther{}

def syntax_word_value_go(term: Ast.SyntaxTerm, value: Nat, step: SyntaxWordStep) -> Maybe<&2, Nat>:
  match term:
    case Ast.TermCtr{"WNil", Nil{}, _}:
      Some{value}
    case Ast.TermCtr{"WCon", [_, +rest], _}:
      match step:
        case SyntaxWordZeroBit{}:
          Maybe.map(&2, Nat, Nat, tail => tail * 2n, syntax_word_value_go(rest, value, syntax_word_step(rest)))
        case SyntaxWordOneBit{}:
          Maybe.map(&2, Nat, Nat, tail => tail * 2n + 1n, syntax_word_value_go(rest, value, syntax_word_step(rest)))
        case _:
          None{}
    case _:
      None{}

def syntax_word_value(+term: Ast.SyntaxTerm, value: Nat) -> Maybe<&2, Nat>:
  syntax_word_value_go(term, value, syntax_word_step(term))

def nat_from_syntax(term: Ast.SyntaxTerm) -> Maybe<&2, Nat>:
  match term:
    case Ast.TermCtr{ "Zero",  Nil{},  _}:
      Some{0n}
    case Ast.TermCtr{ "Succ",  [next],  _}:
      nat_from_syntax_successor(nat_from_syntax(next))
    case Ast.TermApp{ Ast.TermRef{ "U32.to_nat",  _},  Ast.TermCtr{ "U32",  [word],  _},  _}:
      syntax_word_value(word, 0n)
    case _:
      None{}
type PowerDepthStep is Data:
  PowerDepthZero{}
  PowerDepthDone{}
  PowerDepthContinue{half: Nat}
  PowerDepthInvalid{}

def power_depth_remainder(remainder: Nat, half: Nat) -> PowerDepthStep:
  match remainder:
    case 0n:
      PowerDepthContinue{half}
    case _:
      PowerDepthInvalid{}

def power_depth_step(+count: Nat) -> PowerDepthStep:
  match count:
    case 0n:
      PowerDepthZero{}
    case 1n:
      PowerDepthDone{}
    case _:
      power_depth_remainder(Nat.mod(count, 2n), Nat.div(count, 2n))

def power_depth_go(remaining: Nat, depth: Nat, step: PowerDepthStep) -> Maybe<&2, Nat>:
  match remaining:
    case 0n:
      None{}
    case 1n+rest:
      match step:
        case PowerDepthZero{}:
          None{}
        case PowerDepthDone{}:
          Some{depth}
        case PowerDepthContinue{half}:
          power_depth_go(rest, depth + 1n, power_depth_step(half))
        case PowerDepthInvalid{}:
          None{}

def power_depth(+count: Nat, depth: Nat) -> Maybe<&2, Nat>:
  power_depth_go(count, depth, power_depth_step(count))
def parse_nat_literal_tail(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, +value: Nat, beg: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((tail, after_tail), True{}):
      parse_nat_literal_prefix(Nat.is_lt(256n, value), file, value, beg, end, after_tail, tail)
    case ((tail, after_tail), False{}):
      ((tail, after_tail), False{})

def make_list(+file: String, items: List<&2, Ast.SyntaxTerm>, +beg: Nat, +end: Nat) -> Ast.SyntaxTerm & Bool:
  match items:
    case Nil{}:
      (Ast.TermCtr{"Nil", Nil{}, span(file, beg, end)}, True{})
    case +item <> rest:
      make_list_cons(item, make_list(file, rest, beg, end), file, beg, end)
def make_tuple(rest: List<&2, Ast.SyntaxTerm>, first: Ast.SyntaxTerm, +file: String, +beg: Nat, +end: Nat) -> Ast.SyntaxTerm & Bool:
  match rest:
    case Nil{}:
      (first, True{})
    case +second <> more:
      make_tuple_cons(first, make_tuple(more, second, file, beg, end), file, beg, end)

def parse_parenthesized_terms(terms: List<&2, Ast.SyntaxTerm>, +after: List<&2, Lexer.Token>, file: String, beg: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match terms:
    case Nil{}:
      ((Ast.TermCtr{"Tuple", Nil{}, span(file, beg, token_end_of(after, end))}, after), True{})
    case +first <> rest:
      parse_parenthesized_tuple_result(make_tuple(rest, first, file, beg, token_end_of(after, end)), after)

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

def parse_all_named_body_result(ok_body: Bool, body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, file: String, key: String, key_end: Nat, beg: Nat, quantity: Ast.Quantity, ty: Ast.SyntaxTerm, idx: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      ((Ast.TermAll{quantity, key, idx, ty, body, span(file, beg, token_end_of(after_body, key_end))}, after_body), True{})
    case False{}:
      ((body, after_body), False{})

def parse_many_lambda_body_result(ok_body: Bool, body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, file: String, key: String, beg: Nat, end: Nat, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      ((Ast.TermLam{Some{Ast.QMany{}}, key, depth, body, span(file, beg, token_end_of(after_body, end))}, after_body), True{})
    case False{}:
      ((body, after_body), False{})

def has_space_after_result(is_spaced: Bool) -> Bool:
  match is_spaced:
    case True{}: True{}
    case False{}: False{}
def has_space_after(end: Nat, tokens: List<&2, Lexer.Token>) -> Bool:
  match tokens:
    case +token <> _:
      has_space_after_result(Nat.is_lt(end, token_beg(token)))
    case Nil{}:
      False{}

def term_head_name(term: Ast.SyntaxTerm) -> String:
  match term:
    case Ast.TermVar{key,  _,  _}: key
    case Ast.TermRef{key,  _}: key
    case Ast.TermAdt{key,  _,  _,  _}: key
    case Ast.TermFill{head,  _,  _}: term_head_name(head)
    case Ast.TermPlus{head,  _,  _}: term_head_name(head)
    case _: ""
def term_name(term: Ast.SyntaxTerm) -> Maybe<&2, String>:
  match term:
    case Ast.TermVar{key,  _,  _}: Some{key}
    case Ast.TermRef{key,  _}: Some{key}
    case _: None{}



@unsafe
def map_operator_term(term: Ast.SyntaxTerm, +namespace: String) -> Ast.SyntaxTerm:
  match term:
    case Ast.TermVar{key, index, source_span}: Ast.TermVar{key, index, source_span}
    case Ast.TermRef{key, source_span}: Ast.TermRef{map_operator_key(namespace, key), source_span}
    case Ast.TermBang{term, source_span}: Ast.TermBang{map_operator_term(term, namespace), source_span}
    case Ast.TermSub{index, value, body, source_span}: Ast.TermSub{index, map_operator_term(value, namespace), map_operator_term(body, namespace), source_span}
    case Ast.TermLet{keys, indexes, quantities, values, body, source_span}: Ast.TermLet{keys, indexes, quantities, Core.map_syntax_terms(child => map_operator_term(child, namespace), values), map_operator_term(body, namespace), source_span}
    case Ast.TermAnn{term, ty, source_span}: Ast.TermAnn{map_operator_term(term, namespace), map_operator_term(ty, namespace), source_span}
    case Ast.TermTemplate{term, source_span}: Ast.TermTemplate{map_operator_term(term, namespace), source_span}
    case Ast.TermType{kind, source_span}: Ast.TermType{map_operator_term(kind, namespace), source_span}
    case Ast.TermQuant{}: Ast.TermQuant{}
    case Ast.TermQuantity{quantity, source_span}: Ast.TermQuantity{quantity, source_span}
    case Ast.TermMin{left, right, source_span}: Ast.TermMin{map_operator_term(left, namespace), map_operator_term(right, namespace), source_span}
    case Ast.TermAll{quantity, key, index, ty, body, source_span}: Ast.TermAll{quantity, key, index, map_operator_term(ty, namespace), map_operator_term(body, namespace), source_span}
    case Ast.TermLam{quantity, key, index, body, source_span}: Ast.TermLam{quantity, key, index, map_operator_term(body, namespace), source_span}
    case Ast.TermApp{fn, arg, source_span}: Ast.TermApp{map_operator_term(fn, namespace), map_operator_term(arg, namespace), source_span}
    case Ast.TermAdt{key, args, refs, source_span}: Ast.TermAdt{key, Core.map_syntax_terms(child => map_operator_term(child, namespace), args), refs, source_span}
    case Ast.TermFill{head, args, source_span}: Ast.TermFill{map_operator_term(head, namespace), Core.map_syntax_terms(child => map_operator_term(child, namespace), args), source_span}
    case Ast.TermPlus{head, args, source_span}: Ast.TermPlus{map_operator_term(head, namespace), Core.map_syntax_terms(child => map_operator_term(child, namespace), args), source_span}
    case Ast.TermCtr{key, args, source_span}: Ast.TermCtr{key, Core.map_syntax_terms(child => map_operator_term(child, namespace), args), source_span}
    case Ast.TermMat{key, head, matched, source_span}: Ast.TermMat{key, map_operator_term(head, namespace), map_operator_term(matched, namespace), source_span}
    case Ast.TermAbsurd{source_span}: Ast.TermAbsurd{source_span}
    case Ast.TermEqual{left, right, ty, source_span}: Ast.TermEqual{map_operator_term(left, namespace), map_operator_term(right, namespace), map_operator_term(ty, namespace), source_span}
    case Ast.TermRefl{source_span}: Ast.TermRefl{source_span}
    case Ast.TermRewrite{equation, proof, body, source_span}: Ast.TermRewrite{map_operator_term(equation, namespace), map_operator_term(proof, namespace), map_operator_term(body, namespace), source_span}
    case Ast.TermHole{key, source_span}: Ast.TermHole{key, source_span}
    case Ast.BodyMatch{scrutinees, cases, source_span}: Ast.BodyMatch{Core.map_syntax_terms(child => map_operator_term(child, namespace), scrutinees), Core.map_syntax_terms(child => map_operator_term(child, namespace), cases), source_span}
    case Ast.BodyCase{patterns, body, source_span}: Ast.BodyCase{patterns, map_operator_term(body, namespace), source_span}
    case Ast.BodyLocal{patterns, quantity, values, body, source_span}: Ast.BodyLocal{patterns, quantity, Core.map_syntax_terms(child => map_operator_term(child, namespace), values), map_operator_term(body, namespace), source_span}
    case Ast.BodyReply{term, source_span}: Ast.BodyReply{map_operator_term(term, namespace), source_span}
def operator_rhs_level(right_assoc: Bool, priority: Nat) -> Nat:
  match right_assoc:
    case True{}:
      priority
    case False{}:
      priority + 1n

def is_quantity_term(term: Ast.SyntaxTerm) -> Bool:
  match term:
    case Ast.TermQuantity{ _,  _}: True{}
    case Ast.TermMin{ _,  _,  _}: True{}
    case _: False{}

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


def parse_template_term_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((+term, after), True{}):
      ((Ast.TermTemplate{term, span(file, beg, token_end_first(term))}, after), True{})
    case ((term, after), False{}):
      ((term, after), False{})

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

def expr_finish_list_items(ok_items: Bool, items: List<&2, Ast.SyntaxTerm>, +after_items: List<&2, Lexer.Token>, file: String, +first: Ast.SyntaxTerm, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_items:
    case True{}:
      expr_finish_list(make_list(file, first <> items, beg, token_end_of(after_items, token_end_first(first))), after_items)
    case False{}:
      ((Ast.TermHole{"parse-error: expected ]", span(file, token_end_first(first), token_end_first(first))}, after_items), False{})
def parse_typed_operator_namespace(is_empty: Bool, file: String, term: Ast.SyntaxTerm, namespace: String, +ty: Ast.SyntaxTerm, after_ty: List<&2, Lexer.Token>, tail: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_empty:
    case True{}:
      ((Ast.TermHole{ "parse-error: expected a type name after :",  span(file, token_beg_first(ty), token_end_first(ty))}, after_ty), False{})
    case False{}:
      ((map_operator_term(term, namespace), tail), True{})


def parse_typed_operator_close(close: Lexer.Token, +tail: List<&2, Lexer.Token>, +ty: Ast.SyntaxTerm, file: String, term: Ast.SyntaxTerm) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match close:
    case Lexer.TokenInfo{kind, ")", beg, +end, line, col}:
      +namespace = term_head_name(ty)
      parse_typed_operator_namespace(String.eq(namespace, ""), file, term, namespace, ty, Lexer.TokenInfo{kind, ")", beg, end, line, col} <> tail, tail)
    case Lexer.TokenInfo{kind, text, +beg, +end, line, col}:
      ((Ast.TermHole{"parse-error: expected )", span(file, beg, end)}, Lexer.TokenInfo{kind, text, beg, end, line, col} <> tail), False{})
def parse_typed_operator_type(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, term: Ast.SyntaxTerm) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((ty, close <> tail), True{}):
      parse_typed_operator_close(close, tail, ty, file, term)
    case ((ty, after_ty), False{}):
      ((ty, after_ty), False{})
    case ((ty, after_ty), True{}):
      ((ty, after_ty), False{})

def parse_match_tail_with_head_result(ok_tail: Bool, +tail: Ast.SyntaxTerm, +after_tail: List<&2, Lexer.Token>, file: String, key: String, head: Ast.SyntaxTerm, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_tail:
    case True{}:
      ((Ast.TermMat{key, head, tail, span(file, beg, token_end_of(after_tail, token_end_first(tail)))}, after_tail), True{})
    case False{}:
      ((tail, after_tail), False{})

type MatchTailScanAction is Data:
  MatchTailScanRow0{}
  MatchTailScanRow1{}
  MatchTailScanRow2{}

def match_tail_scan_branch_0(file: String, +tail: Ast.SyntaxTerm, +close: Lexer.Token, +rest: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  parse_match_tail_after_semicolon(file, tail, close, rest, skip_lines(rest))

def match_tail_scan_branch_1(+tail: Ast.SyntaxTerm, +rest: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((tail, rest), True{})

def match_tail_scan_branch_2(file: String, after_tail: List<&2, Lexer.Token>, +close: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected } after match tail",  span(file, token_beg(close), token_end(close))}, after_tail), False{})

def match_tail_scan_is_colon(close: Lexer.Token) -> MatchTailScanAction:
  match close:
    case Lexer.TokenInfo{ _, ";",  _,  _,  _,  _}:
      MatchTailScanRow0{}
    case Lexer.TokenInfo{ _, "}",  _,  _,  _,  _}:
      MatchTailScanRow1{}
    case _:
      MatchTailScanRow2{}

def match_tail_scan_run(is_colon: MatchTailScanAction, file: String, +tail: Ast.SyntaxTerm, after_tail: List<&2, Lexer.Token>, +close: Lexer.Token, +rest: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  match is_colon:
    case MatchTailScanRow0{}:
      match_tail_scan_branch_0(file, tail, close, rest)
    case MatchTailScanRow1{}:
      match_tail_scan_branch_1(tail, rest)
    case MatchTailScanRow2{}:
      match_tail_scan_branch_2(file, after_tail, close)

def parse_match_tail_scan(file: String, +tail: Ast.SyntaxTerm, after_tail: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match scanned:
    case +close <> +rest:
      match_tail_scan_run(match_tail_scan_is_colon(close), file, tail, after_tail, close, rest)
    case Nil{}:
      ((Ast.TermHole{ "parse-error: expected } after match tail",  span(file, token_end_first(tail), token_end_first(tail))}, after_tail), False{})

def parse_match_tail_result(ok_tail: Bool, file: String, tail: Ast.SyntaxTerm, +after_tail: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_tail:
    case True{}:
      parse_match_tail_scan(file, tail, after_tail, skip_lines(after_tail))
    case False{}:
      ((tail, after_tail), False{})

def empty_generic_follow(tokens: List<&2, Lexer.Token>) -> Bool:
  match tokens:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{ Lexer.NewlineToken{},  _,  _,  _,  _,  _}:
          empty_generic_follow(rest)
        case Lexer.TokenInfo{ Lexer.EndToken{},  _,  _,  _,  _,  _}:
          True{}
        case Lexer.TokenInfo{ Lexer.SymbolToken{}, ")",  _,  _,  _,  _}: True{}
        case Lexer.TokenInfo{ Lexer.SymbolToken{}, "]",  _,  _,  _,  _}: True{}
        case Lexer.TokenInfo{ Lexer.SymbolToken{}, "}",  _,  _,  _,  _}: True{}
        case Lexer.TokenInfo{ Lexer.SymbolToken{}, ",",  _,  _,  _,  _}: True{}
        case Lexer.TokenInfo{ Lexer.SymbolToken{}, ":",  _,  _,  _,  _}: True{}
        case Lexer.TokenInfo{ Lexer.SymbolToken{}, ";",  _,  _,  _,  _}: True{}
        case Lexer.TokenInfo{ Lexer.SymbolToken{}, "(",  _,  _,  _,  _}: True{}
        case Lexer.TokenInfo{ Lexer.SymbolToken{}, "[",  _,  _,  _,  _}: True{}
        case _: False{}
    case Nil{}:
      True{}

def parse_rewrite_body_result(ok_body: Bool, +body: Ast.SyntaxTerm, after_body: List<&2, Lexer.Token>, equation: Ast.SyntaxTerm, proof: Ast.SyntaxTerm, file: String, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      ((Ast.TermRewrite{equation, proof, body, span(file, beg, token_end_first(body))}, after_body), True{})
    case False{}:
      ((body, after_body), False{})

def parse_plus_args_result(ok_args: Bool, args: List<&2, Ast.SyntaxTerm>, +after_args: List<&2, Lexer.Token>, file: String, +head: Ast.SyntaxTerm, beg: Nat, +open: Lexer.Token) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_args:
    case True{}:
      ((Ast.TermPlus{head, args, span(file, beg, token_end_of(after_args, token_end_first(head)))}, after_args), True{})
    case False{}:
      ((Ast.TermHole{"parse-error: expected plus datatype arguments", span(file, token_beg(open), token_end(open))}, after_args), False{})

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

def array_call(+file: String, ty: Ast.SyntaxTerm, depth: Ast.SyntaxTerm, value: Ast.SyntaxTerm, +beg: Nat, end: Nat, after: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  array_call_result(apply_terms([ty, depth, value], file, Ast.TermRef{"Array.new", span(file, beg, end)}, beg), after)

def expr_match_array_depth_close(close: Lexer.Token, after_close: List<&2, Lexer.Token>, file: String, value: Ast.SyntaxTerm, ty: Ast.SyntaxTerm, array_depth: Ast.SyntaxTerm, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match close:
    case Lexer.TokenInfo{_, "]", _, end, _, _}:
      array_call(file, ty, array_depth, value, beg, end, after_close)
    case Lexer.TokenInfo{kind, text, +beg, +end, line, col}:
      ((Ast.TermHole{"parse-error: expected ]", span(file, beg, end)}, Lexer.TokenInfo{kind, text, beg, end, line, col} <> after_close), False{})

def expr_match_array_depth(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, value: Ast.SyntaxTerm, ty: Ast.SyntaxTerm, beg: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((array_depth, +close <> after_close), True{}):
      expr_match_array_depth_close(close, after_close, file, value, ty, array_depth, beg)
    case ((array_depth, after_depth), False{}):
      ((array_depth, after_depth), False{})
    case ((array_depth, after_depth), True{}):
      ((array_depth, after_depth), False{})

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

def expr_match_array_power(array_power: Maybe<&2, Nat>, +file: String, value: Ast.SyntaxTerm, ty: Ast.SyntaxTerm, +count: Ast.SyntaxTerm, close: Lexer.Token, after_close: List<&2, Lexer.Token>, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match array_power:
    case Some{array_depth}:
      array_call(file, ty, nat_literal(file, array_depth, token_beg_first(count), token_end_first(count)), value, beg, token_end(close), after_close)
    case None{}:
      ((Ast.TermHole{ "parse-error: array count must be a power of two",  span(file, token_beg_first(count), token_end_first(count))}, after_close), False{})

def expr_match_array_nat(nat_count: Maybe<&2, Nat>, file: String, value: Ast.SyntaxTerm, ty: Ast.SyntaxTerm, +count: Ast.SyntaxTerm, close: Lexer.Token, after_close: List<&2, Lexer.Token>, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match nat_count:
    case Some{count_value}:
      expr_match_array_power(power_depth(count_value, 0n), file, value, ty, count, close, after_close, beg)
    case None{}:
      ((Ast.TermHole{ "parse-error: array count must be a natural",  span(file, token_beg_first(count), token_end_first(count))}, after_close), False{})

def expr_match_array_count_close(close: Lexer.Token, after_close: List<&2, Lexer.Token>, file: String, value: Ast.SyntaxTerm, ty: Ast.SyntaxTerm, +count: Ast.SyntaxTerm, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match close:
    case Lexer.TokenInfo{kind, "]", close_beg, close_end, line, col}:
      expr_match_array_nat(nat_from_syntax(count), file, value, ty, count, Lexer.TokenInfo{kind, "]", close_beg, close_end, line, col}, after_close, beg)
    case Lexer.TokenInfo{kind, text, close_beg, close_end, line, col}:
      ((count, Lexer.TokenInfo{kind, text, close_beg, close_end, line, col} <> after_close), False{})

def expr_match_array_count(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, value: Ast.SyntaxTerm, ty: Ast.SyntaxTerm, beg: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((count, +close <> after_close), True{}):
      expr_match_array_count_close(close, after_close, file, value, ty, count, beg)
    case ((count, after_count), False{}):
      ((count, after_count), False{})
    case ((count, after_count), True{}):
      ((count, after_count), False{})

def token_end_first_list(terms: List<&2, Ast.SyntaxTerm>) -> Nat:
  match terms:
    case +term <> _:
      token_end_first(term)
    case Nil{}:
      0n
def parse_name_scan(original: List<&2, Lexer.Token>, tokens: List<&2, Lexer.Token>) -> (String & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{ Lexer.NameToken{}, text,  _,  _,  _,  _}:
          ((text, rest), True{})
        case _:
          ((SNil{}, original), False{})
    case Nil{}:
      ((SNil{}, Nil{}), False{})

def parse_name(+tokens: List<&2, Lexer.Token>) -> (String & List<&2, Lexer.Token>) & Bool:
  parse_name_scan(tokens, skip_lines(tokens))


def definition_failure(+file: String, key: String, binders: List<&2, Ast.TelescopeItem>, beg: Nat, +end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  ((Ast.DefTop{Ast.Definition{key, binders, Ast.NoTerm{}, Ast.DefTerm{Ast.TermHole{"parse-error: malformed definition", span(file, end, end)}}, False{}, span(file, beg, end)}}, rest), False{})

def parse_definition_typed_body_result(ok_body: Bool, body: Ast.DefBody, +after_body: List<&2, Lexer.Token>, colon: Lexer.Token, after_colon: List<&2, Lexer.Token>, file: String, key: String, beg: Nat, binders: List<&2, Ast.TelescopeItem>, +result: Ast.SyntaxTerm) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      ((Ast.DefTop{Ast.Definition{key, binders, Ast.SomeTerm{result}, body, False{}, span(file, beg, token_end_of(after_body, token_end_first(result)))}}, after_body), True{})
    case False{}:
      definition_failure(file, key, binders, beg, token_end(colon), after_colon)
def parse_definition_untyped_body_result(ok_body: Bool, body: Ast.DefBody, +after_body: List<&2, Lexer.Token>, file: String, key: String, beg: Nat, binders: List<&2, Ast.TelescopeItem>, header: Lexer.Token, rest: List<&2, Lexer.Token>) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      ((Ast.DefTop{Ast.Definition{key, binders, Ast.NoTerm{}, body, False{}, span(file, beg, token_end_of(after_body, token_end(header)))}}, after_body), True{})
    case False{}:
      definition_failure(file, key, binders, beg, token_end(header), rest)

def parse_definition_term_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool) -> (Ast.DefBody & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((term, after), ok):
      ((Ast.DefTerm{term}, after), ok)
def parse_reply_result(ok: Bool, +term: Ast.SyntaxTerm, after: List<&2, Lexer.Token>, file: String) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok:
    case True{}:
      ((Ast.BodyReply{term, span(file, token_beg_first(term), token_end_first(term))}, after), True{})
    case False{}:
      ((term, after), False{})

def token_line(token: Lexer.Token) -> Nat:
  match token:
    case Lexer.TokenInfo{ _,  _,  _,  _, line,  _}:
      line

def external_paths_valid(paths: List<&2, String>) -> Bool:
  match paths:
    case Nil{}:
      True{}
    case +path <> rest:
      Bool.and(Bool.or(String.ends_with(path, ".c"), String.ends_with(path, ".js")), external_paths_valid(rest))

def parse_definition_imports_result(result: (List<&2, String> & List<&2, Lexer.Token>) & Bool) -> (Ast.DefBody & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((+paths, after), ok):
      ((Ast.DefImports{paths}, after), Bool.and(ok, external_paths_valid(paths)))

def local_group_has_equal(tokens: List<&2, Lexer.Token>) -> Bool:
  match tokens:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{Lexer.NewlineToken{}, _, _, _, _, _}:
          False{}
        case Lexer.TokenInfo{Lexer.EndToken{}, _, _, _, _, _}:
          False{}
        case Lexer.TokenInfo{_, "=", _, _, _, _}:
          True{}
        case Lexer.TokenInfo{_, _, _, _, _, _}:
          local_group_has_equal(rest)
    case Nil{}:
      False{}

def local_binder_pattern(key: String, depth: Nat, quantity: Ast.Quantity, file: String, beg: Nat, end: Nat) -> Ast.SyntaxPattern:
  Ast.PatternVar{key, depth, quantity, span(file, beg, end)}

def parse_local_binders(+file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, +depth: Nat, +quantity: Ast.Quantity, acc: List<&2, Ast.SyntaxPattern>) -> (((List<&2, Ast.SyntaxPattern> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool:
  match tokens:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{_, "=", _, _, _, _}:
          ((((List.reverse(&2, Ast.SyntaxPattern, acc), rest), scope), depth), True{})
        case Lexer.TokenInfo{Lexer.NameToken{}, +key, beg, end, _, _}:
          parse_local_binders(file, rest, extend_scope(key, depth, scope), depth + 1n, quantity, local_binder_pattern(key, depth, quantity, file, beg, end) <> acc)
        case _:
          ((((List.reverse(&2, Ast.SyntaxPattern, acc), tokens), scope), depth), False{})
    case Nil{}:
      ((((List.reverse(&2, Ast.SyntaxPattern, acc), Nil{}), scope), depth), False{})

def parse_parallel_parsed_body(ok_body: Bool, body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, +values: List<&2, Ast.SyntaxTerm>, patterns: List<&2, Ast.SyntaxPattern>, quantity: Ast.Quantity, file: String, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      span_end = token_end_of(after_body, token_end_first_list(values))
      ((Ast.BodyLocal{patterns, quantity, values, body, span(file, beg, span_end)}, after_body), True{})
    case False{}:
      ((body, after_body), False{})


def first_line(tokens: List<&2, Lexer.Token>) -> Nat:
  match tokens:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{ Lexer.NewlineToken{},  _,  _,  _,  _,  _}:
          first_line(rest)
        case _:
          token_line(token)
    case Nil{}:
      0n
def local_counts_match(patterns: List<&2, Ast.SyntaxPattern>, values: List<&2, Ast.SyntaxTerm>) -> Bool:
  match patterns values:
    case Nil{} Nil{}:
      True{}
    case +_ <> more_patterns +_ <> more_values:
      local_counts_match(more_patterns, more_values)
    case _ _:
      False{}

def parse_local_body_parsed(ok_body: Bool, body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, file: String, key: String, beg: Nat, pattern: Ast.SyntaxPattern, quantity: Ast.Quantity, +value: Ast.SyntaxTerm) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      ((Ast.BodyLocal{ [pattern], quantity, [value], body, span(file, beg, token_end_of(after_body, token_end_first(value)))}, after_body), True{})
    case False{}:
      ((body, after_body), False{})

def parse_destructuring_parsed_body(ok_body: Bool, body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, +value: Ast.SyntaxTerm, pattern: Ast.SyntaxPattern, file: String, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      ((Ast.BodyLocal{ [pattern], Ast.QOne{}, [value], body, span(file, beg, token_end_of(after_body, token_end_first(value)))}, after_body), True{})
    case False{}:
      ((body, after_body), False{})

def local_array_write(tokens: List<&2, Lexer.Token>) -> Bool:
  match tokens:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{Lexer.NewlineToken{}, _, _, _, _, _}:
          False{}
        case Lexer.TokenInfo{Lexer.EndToken{}, _, _, _, _, _}:
          False{}
        case Lexer.TokenInfo{_, "<-", _, _, _, _}:
          True{}
        case Lexer.TokenInfo{_, _, _, _, _, _}:
          local_array_write(rest)
    case Nil{}:
      False{}

def parse_match_cases_result(ok_cases: Bool, cases: List<&2, Ast.SyntaxTerm>, +after_cases: List<&2, Lexer.Token>, +scrutinees: List<&2, Ast.SyntaxTerm>, +colon: Lexer.Token, file: String, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_cases:
    case True{}:
      ((Ast.BodyMatch{scrutinees, cases, span(file, beg, token_end_of(after_cases, token_end_first_list(scrutinees)))}, after_cases), True{})
    case False{}:
      ((Ast.TermHole{ "parse-error: expected an indented case", span(file, token_beg(colon), token_end(colon))}, after_cases), False{})

def parse_case_rows_stop(acc: List<&2, Ast.SyntaxTerm>, tokens: List<&2, Lexer.Token>) -> (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool:
  match acc:
    case Nil{}:
      ((Nil{}, tokens), False{})
    case _:
      ((List.reverse(&2, Ast.SyntaxTerm, acc), tokens), True{})

def parse_case_body_result(ok_body: Bool, +body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, patterns: List<&2, Ast.SyntaxPattern>, file: String, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      ((Ast.BodyCase{patterns, body, span(file, beg, token_end_of(after_body, token_end_first(body)))}, after_body), True{})
    case False{}:
      ((body, after_body), False{})

def body_indented(tokens: List<&2, Lexer.Token>, parent_col: Nat) -> Bool:
  match tokens:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{ Lexer.NewlineToken{},  _,  _,  _,  _,  _}:
          body_indented(rest, parent_col)
        case Lexer.TokenInfo{ _,  _,  _,  _,  _, col}:
          Nat.is_lt(parent_col, col)
    case Nil{}:
      False{}
def local_group_body_ready_after_line(is_after: Bool, tokens: List<&2, Lexer.Token>, parent_col: Nat) -> Bool:
  match is_after:
    case True{}:
      body_indented(tokens, parent_col)
    case False{}:
      False{}

def local_group_body_ready(tokens: List<&2, Lexer.Token>, parent_col: Nat, rhs_line: Nat) -> Bool:
  match tokens:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{ Lexer.NewlineToken{},  _,  _,  _,  _,  _}:
          local_group_body_ready(rest, parent_col, rhs_line)
        case Lexer.TokenInfo{ _, ";",  _,  _,  _,  _}:
          True{}
        case Lexer.TokenInfo{ _,  _,  _,  _, line,  _}:
          local_group_body_ready_after_line(Nat.is_lt(rhs_line, line), tokens, parent_col)
    case Nil{}:
      False{}

def local_body_ready(tokens: List<&2, Lexer.Token>, parent_col: Nat) -> Bool:
  match tokens:
    case +token <> _:
      match token:
        case Lexer.TokenInfo{ _, ";",  _,  _,  _,  _}: True{}
        case _: body_indented(tokens, parent_col)
    case Nil{}:
      False{}

def pattern_count_matches(patterns: List<&2, Ast.SyntaxPattern>, count: Nat) -> Bool:
  match patterns:
    case Nil{}:
      match count:
        case 0n: True{}
        case _: False{}
    case +_ <> rest:
      match count:
        case 0n: False{}
        case 1n+more:
          pattern_count_matches(rest, more)


def module_import_without_alias(is_base: Bool, file: String, +canonical: String, beg: Nat, path_token: Lexer.Token, rest: List<&2, Lexer.Token>) -> (Ast.ModuleImport & List<&2, Lexer.Token>) & Bool:
  match is_base:
    case True{}:
      ((Ast.ModuleImport{ canonical,  "Base",  span(file, beg, token_end(path_token))}, rest), True{})
    case False{}:
      ((Ast.ModuleImport{ canonical,  canonical,  span(file, beg, token_end(path_token))}, rest), False{})

def nat_pattern(+file: String, value: Nat, +beg: Nat, +end: Nat) -> Ast.SyntaxPattern:
  match value:
    case 0n:
      Ast.PatternCtr{ "Zero",  Nil{},  span(file, beg, end)}
    case 1n+rest:
      Ast.PatternCtr{ "Succ",  [nat_pattern(file, rest, beg, end)],  span(file, beg, end)}

def parse_pattern_nat_read(result: Maybe<&2, Nat>, file: String, tokens: List<&2, Lexer.Token>, rest: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool):
  match result:
    case Some{value}:
      ((nat_pattern(file, value, beg, end), rest), ((scope, depth), True{}))
    case None{}:
      ((Ast.PatternVar{ "", depth, Ast.QOne{}, span(file, beg, end)}, rest), ((scope, depth), False{}))

def parse_pattern_nat_suffix(is_nat: Bool, file: String, text: String, tokens: List<&2, Lexer.Token>, rest: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool):
  match is_nat:
    case True{}:
      parse_pattern_nat_read(Nat.read(drop_nat_suffix(text)), file, tokens, rest, beg, end, scope, depth)
    case False{}:
      ((Ast.PatternVar{ "", depth, Ast.QOne{}, span(file, beg, end)}, tokens), ((scope, depth), False{}))

def pattern_number_read(result: Maybe<&2, Nat>, file: String, beg: Nat, end: Nat) -> PatternScanMode:
  match result:
    case Some{value}:
      PatternCompleted{nat_pattern(file, value, beg, end)}
    case None{}:
      PatternBadNat{beg, end}

def pattern_number_mode(is_nat: Bool, file: String, text: String, +beg: Nat, +end: Nat, line: Nat, col: Nat, quantity: Ast.Quantity) -> PatternScanMode:
  match is_nat:
    case True{}:
      pattern_number_read(Nat.read(drop_nat_suffix(text)), file, beg, end)
    case False{}:
      PatternNoNat{Lexer.TokenInfo{Lexer.NumberToken{}, text, beg, end, line, col}, quantity, beg, end}

def pattern_finish(goal: PatternScanGoal, pattern: Ast.SyntaxPattern, after: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, ok: Bool) -> PatternScanOutcome:
  match goal ok:
    case PatternSingleGoal{} status:
      PatternSingleOutcome{pattern, after, scope, depth, status}
    case PatternCaseGoal{acc, before_scope, before_depth} True{}:
      PatternCaseOutcome{List.reverse(&2, Ast.SyntaxPattern, pattern <> acc), after, scope, depth, False{}}
    case PatternCaseGoal{acc, before_scope, before_depth} False{}:
      PatternCaseOutcome{List.reverse(&2, Ast.SyntaxPattern, acc), after, before_scope, before_depth, False{}}

type PatternScanContext is Data:
  PatternScanContext{file: String, tokens: List<&2, Lexer.Token>, frames: List<&2, PatternFrame>, scope: List<&2, Scope>, depth: Nat, goal: PatternScanGoal}

type PatternExpectAction is Data:
  PatternExpectActionRow0{}
  PatternExpectActionRow1{}
  PatternExpectActionRow2{}
  PatternExpectActionRow3{}
  PatternExpectActionRow4{}
  PatternExpectActionRow5{quantity: Ast.Quantity}
  PatternExpectActionRow6{quantity: Ast.Quantity}
  PatternExpectActionRow9{quantity: Ast.Quantity}
  PatternExpectActionRow10{quantity: Ast.Quantity}
  PatternExpectActionRow19{quantity: Ast.Quantity}

type PatternCompletedText is Data:
  PatternCompletedTextRow11{}
  PatternCompletedTextRow12{}
  PatternCompletedTextRow13{}
  PatternCompletedTextRow17{}
  PatternCompletedTextOther{}

def pattern_completed_text(text: String) -> PatternCompletedText:
  match text:
    case ",":
      PatternCompletedTextRow11{}
    case ":":
      PatternCompletedTextRow12{}
    case "}":
      PatternCompletedTextRow13{}
    case "+":
      PatternCompletedTextRow17{}
    case _:
      PatternCompletedTextOther{}

def pattern_scan_row_0(ctx: PatternScanContext, beg: Nat, continue_rest: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome) -> PatternScanOutcome:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      continue_rest(PatternExpect{Ast.QMany{}, beg}, frames, scope, depth, goal)

def pattern_scan_row_1(ctx: PatternScanContext, beg: Nat, end: Nat) -> PatternScanOutcome:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      pattern_finish(goal, Ast.PatternVar{"", depth, Ast.QOne{}, span(file, beg, end)}, tokens, scope, depth, False{})

def pattern_scan_row_2(ctx: PatternScanContext, key: String, beg: Nat, end: Nat, continue_open: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome) -> PatternScanOutcome:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      continue_open(PatternExpect{Ast.QOne{}, 0n}, PatternFrameOf{key, beg, end, Nil{}, scope, depth} <> frames, scope, depth, goal)

def pattern_scan_row_3(ctx: PatternScanContext, key: String, end: Nat, initial_beg: Nat, continue_open: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome) -> PatternScanOutcome:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      continue_open(PatternExpect{Ast.QOne{}, 0n}, PatternFrameOf{key, initial_beg, end, Nil{}, scope, depth} <> frames, scope, depth, goal)

def pattern_scan_row_4(ctx: PatternScanContext, +key: String, beg: Nat, end: Nat, continue_rest: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome) -> PatternScanOutcome:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      continue_rest(PatternCompleted{Ast.PatternVar{key, depth, Ast.QOne{}, span(file, beg, end)}}, frames, extend_scope(key, depth, scope), depth + 1n, goal)

def pattern_scan_row_5(ctx: PatternScanContext, +key: String, end: Nat, quantity: Ast.Quantity, initial_beg: Nat, continue_rest: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome) -> PatternScanOutcome:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      continue_rest(PatternCompleted{Ast.PatternVar{key, depth, quantity, span(file, initial_beg, end)}}, frames, extend_scope(key, depth, scope), depth + 1n, goal)

def pattern_scan_row_6(ctx: PatternScanContext, +text: String, +beg: Nat, +end: Nat, line: Nat, col: Nat, quantity: Ast.Quantity, continue_rest: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome) -> PatternScanOutcome:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      continue_rest(pattern_number_mode(has_nat_suffix(text), file, text, beg, end, line, col, quantity), frames, scope, depth, goal)

def pattern_scan_row_9(ctx: PatternScanContext, quantity: Ast.Quantity, initial_beg: Nat, continue_rest: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome) -> PatternScanOutcome:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      continue_rest(PatternExpect{quantity, initial_beg}, frames, scope, depth, goal)

def pattern_scan_row_10(ctx: PatternScanContext, close_end: Nat, quantity: Ast.Quantity, +initial_beg: Nat, continue_rest: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome) -> PatternScanOutcome:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      match frames:
        case PatternFrameOf{key, start, end, fields, root_scope, root_depth} <> parents:
          continue_rest(PatternCompleted{Ast.PatternCtr{key, List.reverse(&2, Ast.SyntaxPattern, fields), span(file, start, close_end)}}, parents, scope, depth, goal)
        case Nil{}:
          pattern_finish(goal, Ast.PatternVar{"", depth, quantity, span(file, initial_beg, initial_beg)}, tokens, scope, depth, False{})

def pattern_scan_row_11(ctx: PatternScanContext, pattern: Ast.SyntaxPattern, continue_rest: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome) -> PatternScanOutcome:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      match frames:
        case PatternFrameOf{key, beg, end, fields, root_scope, root_depth} <> parents:
          continue_rest(PatternExpect{Ast.QOne{}, 0n}, PatternFrameOf{key, beg, end, pattern <> fields, root_scope, root_depth} <> parents, scope, depth, goal)
        case Nil{}:
          match goal:
            case PatternSingleGoal{}:
              PatternSingleOutcome{pattern, tokens, scope, depth, True{}}
            case PatternCaseGoal{acc, before_scope, before_depth}:
              continue_rest(PatternExpect{Ast.QOne{}, 0n}, Nil{}, scope, depth, PatternCaseGoal{pattern <> acc, scope, depth})

def pattern_scan_row_12(ctx: PatternScanContext, pattern: Ast.SyntaxPattern) -> PatternScanOutcome:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      match frames:
        case PatternFrameOf{key, beg, end, fields, root_scope, root_depth} <> parents:
          pattern_finish(goal, Ast.PatternCtr{key, List.reverse(&2, Ast.SyntaxPattern, pattern <> fields), span(file, beg, end)}, tokens, root_scope, root_depth, False{})
        case Nil{}:
          match goal:
            case PatternSingleGoal{}:
              PatternSingleOutcome{pattern, tokens, scope, depth, True{}}
            case PatternCaseGoal{acc, before_scope, before_depth}:
              PatternCaseOutcome{List.reverse(&2, Ast.SyntaxPattern, pattern <> acc), tokens, scope, depth, True{}}

def pattern_scan_row_13(ctx: PatternScanContext, close_end: Nat, pattern: Ast.SyntaxPattern, continue_rest: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome) -> PatternScanOutcome:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      match frames:
        case PatternFrameOf{key, beg, end, fields, root_scope, root_depth} <> parents:
          continue_rest(PatternCompleted{Ast.PatternCtr{key, List.reverse(&2, Ast.SyntaxPattern, pattern <> fields), span(file, beg, close_end)}}, parents, scope, depth, goal)
        case Nil{}:
          pattern_finish(goal, pattern, tokens, scope, depth, True{})

def pattern_scan_row_14(ctx: PatternScanContext, pattern: Ast.SyntaxPattern, continue_rest: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome) -> PatternScanOutcome:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      match frames:
        case +_ <> _:
          continue_rest(PatternCompleted{pattern}, frames, scope, depth, goal)
        case Nil{}:
          match goal:
            case PatternSingleGoal{}:
              PatternSingleOutcome{pattern, tokens, scope, depth, True{}}
            case PatternCaseGoal{acc, before_scope, before_depth}:
              continue_rest(PatternCompleted{pattern}, Nil{}, scope, depth, PatternCaseGoal{acc, before_scope, before_depth})

def pattern_scan_row_15(ctx: PatternScanContext, key: String, beg: Nat, end: Nat, pattern: Ast.SyntaxPattern, continue_open: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome) -> PatternScanOutcome:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      match frames:
        case PatternFrameOf{parent, start, parent_end, fields, root_scope, root_depth} <> parents:
          continue_open(PatternExpect{Ast.QOne{}, 0n}, PatternFrameOf{key, beg, end, Nil{}, scope, depth} <> (PatternFrameOf{parent, start, parent_end, pattern <> fields, root_scope, root_depth} <> parents), scope, depth, goal)
        case Nil{}:
          pattern_finish(goal, pattern, tokens, scope, depth, True{})

def pattern_scan_row_16(ctx: PatternScanContext, +key: String, beg: Nat, end: Nat, pattern: Ast.SyntaxPattern, continue_rest: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome) -> PatternScanOutcome:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      match frames:
        case PatternFrameOf{parent, start, parent_end, fields, root_scope, root_depth} <> parents:
          continue_rest(PatternCompleted{Ast.PatternVar{key, depth, Ast.QOne{}, span(file, beg, end)}}, PatternFrameOf{parent, start, parent_end, pattern <> fields, root_scope, root_depth} <> parents, extend_scope(key, depth, scope), depth + 1n, goal)
        case Nil{}:
          pattern_finish(goal, pattern, tokens, scope, depth, True{})

def pattern_scan_row_17(ctx: PatternScanContext, beg: Nat, pattern: Ast.SyntaxPattern, continue_rest: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome) -> PatternScanOutcome:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      match frames:
        case PatternFrameOf{parent, start, parent_end, fields, root_scope, root_depth} <> parents:
          continue_rest(PatternExpect{Ast.QMany{}, beg}, PatternFrameOf{parent, start, parent_end, pattern <> fields, root_scope, root_depth} <> parents, scope, depth, goal)
        case Nil{}:
          pattern_finish(goal, pattern, tokens, scope, depth, True{})

def pattern_scan_row_18(ctx: PatternScanContext, pattern: Ast.SyntaxPattern) -> PatternScanOutcome:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      match frames:
        case PatternFrameOf{key, beg, end, fields, root_scope, root_depth} <> parents:
          pattern_finish(goal, Ast.PatternCtr{key, List.reverse(&2, Ast.SyntaxPattern, pattern <> fields), span(file, beg, end)}, tokens, root_scope, root_depth, False{})
        case Nil{}:
          pattern_finish(goal, pattern, tokens, scope, depth, True{})

def pattern_scan_row_19(ctx: PatternScanContext, quantity: Ast.Quantity, +initial_beg: Nat) -> PatternScanOutcome:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      match frames:
        case PatternFrameOf{key, start, end, fields, root_scope, root_depth} <> parents:
          pattern_finish(goal, Ast.PatternCtr{key, List.reverse(&2, Ast.SyntaxPattern, fields), span(file, start, end)}, tokens, root_scope, root_depth, False{})
        case Nil{}:
          pattern_finish(goal, Ast.PatternVar{"", depth, quantity, span(file, initial_beg, initial_beg)}, tokens, scope, depth, False{})

def pattern_expect_action(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>) -> PatternExpectAction:
  match token quantity lookahead:
    case Lexer.TokenInfo{Lexer.SymbolToken{}, "+", beg, ignored_end, ignored_line, ignored_col} Ast.QOne{} _:
      PatternExpectActionRow0{}
    case Lexer.TokenInfo{_, "-", beg, end, _, _} Ast.QOne{} _:
      PatternExpectActionRow1{}
    case Lexer.TokenInfo{Lexer.NameToken{}, key, beg, end, _, _} Ast.QOne{} Some{Lexer.TokenInfo{_, "{", _, _, _, _}}:
      PatternExpectActionRow2{}
    case Lexer.TokenInfo{Lexer.NameToken{}, key, _, end, _, _} quantity Some{Lexer.TokenInfo{_, "{", _, _, _, _}}:
      PatternExpectActionRow3{}
    case Lexer.TokenInfo{Lexer.NameToken{}, +key, beg, end, _, _} Ast.QOne{} _:
      PatternExpectActionRow4{}
    case Lexer.TokenInfo{Lexer.NameToken{}, +key, _, end, _, _} quantity _:
      PatternExpectActionRow5{quantity}
    case Lexer.TokenInfo{Lexer.NumberToken{}, +text, +beg, +end, line, col} quantity _:
      PatternExpectActionRow6{quantity}
    case Lexer.TokenInfo{Lexer.NewlineToken{}, _, _, _, _, _} quantity _:
      PatternExpectActionRow9{quantity}
    case Lexer.TokenInfo{_, "}", _, close_end, _, _} quantity _:
      PatternExpectActionRow10{quantity}
    case _ quantity _:
      PatternExpectActionRow19{quantity}

def pattern_scan_expect_run(+token: Lexer.Token, action: PatternExpectAction, +initial_beg: Nat, ctx: PatternScanContext, continue_rest: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome, continue_open: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome) -> PatternScanOutcome:
  match token:
    case Lexer.TokenInfo{kind, +text, +token_beg, +token_end, +token_line, +token_col}:
      match action:
        case PatternExpectActionRow0{}:
          pattern_scan_row_0(ctx, token_beg, continue_rest)
        case PatternExpectActionRow1{}:
          pattern_scan_row_1(ctx, token_beg, token_end)
        case PatternExpectActionRow2{}:
          pattern_scan_row_2(ctx, text, token_beg, token_end, continue_open)
        case PatternExpectActionRow3{}:
          pattern_scan_row_3(ctx, text, token_end, initial_beg, continue_open)
        case PatternExpectActionRow4{}:
          pattern_scan_row_4(ctx, text, token_beg, token_end, continue_rest)
        case PatternExpectActionRow5{quantity}:
          pattern_scan_row_5(ctx, text, token_end, quantity, initial_beg, continue_rest)
        case PatternExpectActionRow6{quantity}:
          pattern_scan_row_6(ctx, text, token_beg, token_end, token_line, token_col, quantity, continue_rest)
        case PatternExpectActionRow9{quantity}:
          pattern_scan_row_9(ctx, quantity, initial_beg, continue_rest)
        case PatternExpectActionRow10{quantity}:
          pattern_scan_row_10(ctx, token_end, quantity, initial_beg, continue_rest)
        case PatternExpectActionRow19{quantity}:
          pattern_scan_row_19(ctx, quantity, initial_beg)

def pattern_scan_expect_step(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>, +initial_beg: Nat, ctx: PatternScanContext, continue_rest: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome, continue_open: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome) -> PatternScanOutcome:
  pattern_scan_expect_run(token, pattern_expect_action(token, quantity, lookahead), initial_beg, ctx, continue_rest, continue_open)

def pattern_scan_completed_fields(choice: PatternCompletedText, kind: Lexer.TokenKind, lookahead: Maybe<&2, Lexer.Token>, +text: String, +token_beg: Nat, +token_end: Nat, pattern: Ast.SyntaxPattern, ctx: PatternScanContext, continue_rest: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome, continue_open: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome) -> PatternScanOutcome:
  match choice kind lookahead:
    case PatternCompletedTextRow11{} _ _:
      pattern_scan_row_11(ctx, pattern, continue_rest)
    case PatternCompletedTextRow12{} _ _:
      pattern_scan_row_12(ctx, pattern)
    case PatternCompletedTextRow13{} _ _:
      pattern_scan_row_13(ctx, token_end, pattern, continue_rest)
    case _ Lexer.NewlineToken{} _:
      pattern_scan_row_14(ctx, pattern, continue_rest)
    case _ Lexer.NameToken{} Some{Lexer.TokenInfo{_, "{", _, _, _, _}}:
      pattern_scan_row_15(ctx, text, token_beg, token_end, pattern, continue_open)
    case _ Lexer.NameToken{} _:
      pattern_scan_row_16(ctx, text, token_beg, token_end, pattern, continue_rest)
    case PatternCompletedTextRow17{} _ _:
      pattern_scan_row_17(ctx, token_beg, pattern, continue_rest)
    case _ _ _:
      pattern_scan_row_18(ctx, pattern)

def pattern_scan_completed_step(+token: Lexer.Token, lookahead: Maybe<&2, Lexer.Token>, pattern: Ast.SyntaxPattern, ctx: PatternScanContext, continue_rest: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome, continue_open: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome) -> PatternScanOutcome:
  match token:
    case Lexer.TokenInfo{kind, +text, +beg, +end, line, col}:
      pattern_scan_completed_fields(pattern_completed_text(text), kind, lookahead, text, beg, end, pattern, ctx, continue_rest, continue_open)

def pattern_scan_token_step(mode: PatternScanMode, +token: Lexer.Token, lookahead: Maybe<&2, Lexer.Token>, +file: String, +tokens: List<&2, Lexer.Token>, frames: List<&2, PatternFrame>, +scope: List<&2, Scope>, +depth: Nat, goal: PatternScanGoal, continue_rest: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome, continue_open: PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome) -> PatternScanOutcome:
  match mode:
    case PatternExpect{quantity, +initial_beg}:
      pattern_scan_expect_step(token, quantity, lookahead, initial_beg, PatternScanContext{file, tokens, frames, scope, depth, goal}, continue_rest, continue_open)
    case PatternCompleted{pattern}:
      pattern_scan_completed_step(token, lookahead, pattern, PatternScanContext{file, tokens, frames, scope, depth, goal}, continue_rest, continue_open)
    case PatternNoNat{number, quantity, beg, end}:
      pattern_finish(goal, Ast.PatternVar{"", depth, quantity, span(file, beg, end)}, number <> tokens, scope, depth, False{})
    case PatternBadNat{beg, end}:
      pattern_finish(goal, Ast.PatternVar{"", depth, Ast.QOne{}, span(file, beg, end)}, tokens, scope, depth, False{})

def pattern_scan_empty_step(mode: PatternScanMode, +file: String, +tokens: List<&2, Lexer.Token>, frames: List<&2, PatternFrame>, +scope: List<&2, Scope>, +depth: Nat, goal: PatternScanGoal) -> PatternScanOutcome:
  match mode:
    case PatternNoNat{number, quantity, beg, end}:
      pattern_finish(goal, Ast.PatternVar{"", depth, quantity, span(file, beg, end)}, number <> tokens, scope, depth, False{})
    case PatternBadNat{beg, end}:
      pattern_finish(goal, Ast.PatternVar{"", depth, Ast.QOne{}, span(file, beg, end)}, tokens, scope, depth, False{})
    case PatternCompleted{pattern}:
      match frames:
        case PatternFrameOf{key, beg, end, fields, root_scope, root_depth} <> parents:
          pattern_finish(goal, Ast.PatternCtr{key, List.reverse(&2, Ast.SyntaxPattern, pattern <> fields), span(file, beg, end)}, tokens, root_scope, root_depth, False{})
        case Nil{}:
          pattern_finish(goal, pattern, tokens, scope, depth, True{})
    case PatternExpect{quantity, +beg}:
      match frames:
        case PatternFrameOf{key, start, end, fields, root_scope, root_depth} <> parents:
          pattern_finish(goal, Ast.PatternCtr{key, List.reverse(&2, Ast.SyntaxPattern, fields), span(file, start, end)}, tokens, root_scope, root_depth, False{})
        case Nil{}:
          pattern_finish(goal, Ast.PatternVar{"", depth, quantity, span(file, beg, beg)}, tokens, scope, depth, False{})

def pattern_scan(+tokens: List<&2, Lexer.Token>, +file: String, mode: PatternScanMode, frames: List<&2, PatternFrame>, +scope: List<&2, Scope>, +depth: Nat, goal: PatternScanGoal) -> PatternScanOutcome:
  match tokens:
    case +token <> +rest:
      match rest:
        case +next <> +after_open:
          pattern_scan_token_step(mode, token, Some{next}, file, tokens, frames, scope, depth, goal, next_mode => next_frames => next_scope => next_depth => next_goal => pattern_scan(rest, file, next_mode, next_frames, next_scope, next_depth, next_goal), next_mode => next_frames => next_scope => next_depth => next_goal => pattern_scan(after_open, file, next_mode, next_frames, next_scope, next_depth, next_goal))
        case Nil{}:
          pattern_scan_token_step(mode, token, None{}, file, tokens, frames, scope, depth, goal, next_mode => next_frames => next_scope => next_depth => next_goal => pattern_scan(rest, file, next_mode, next_frames, next_scope, next_depth, next_goal), next_mode => next_frames => next_scope => next_depth => next_goal => pattern_scan(rest, file, next_mode, next_frames, next_scope, next_depth, next_goal))
    case Nil{}:
      pattern_scan_empty_step(mode, file, tokens, frames, scope, depth, goal)

def pattern_single_result(result: PatternScanOutcome, file: String, depth: Nat) -> (Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool):
  match result:
    case PatternSingleOutcome{pattern, after, scope, next_depth, ok}:
      ((pattern, after), ((scope, next_depth), ok))
    case PatternCaseOutcome{patterns, after, scope, next_depth, ok}:
      ((Ast.PatternVar{"", depth, Ast.QOne{}, span(file, 0n, 0n)}, after), ((scope, next_depth), False{}))

def parse_pattern_atom(+file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool):
  pattern_single_result(pattern_scan(tokens, file, PatternExpect{Ast.QOne{}, 0n}, Nil{}, scope, depth, PatternSingleGoal{}), file, depth)
def parse_module_import_alias_token(file: String, +canonical: String, beg: Nat, path_token: Lexer.Token, as_token: Lexer.Token, alias_token: Lexer.Token, rest: List<&2, Lexer.Token>) -> (Ast.ModuleImport & List<&2, Lexer.Token>) & Bool:
  match alias_token:
    case Lexer.TokenInfo{ Lexer.NameToken{}, alias, _, fin, _, _}:
      ((Ast.ModuleImport{ canonical, alias, span(file, beg, fin)}, rest), True{})
    case Lexer.TokenInfo{kind, text, field_beg, field_end, line, col}:
      ((Ast.ModuleImport{ canonical, canonical, span(file, beg, token_end(path_token))}, as_token <> (Lexer.TokenInfo{kind, text, field_beg, field_end, line, col} <> rest)), False{})

def parse_module_import_alias_target(file: String, +canonical: String, beg: Nat, path_token: Lexer.Token, as_token: Lexer.Token, after_as: List<&2, Lexer.Token>) -> (Ast.ModuleImport & List<&2, Lexer.Token>) & Bool:
  match after_as:
    case +alias_token <> rest:
      parse_module_import_alias_token(file, canonical, beg, path_token, as_token, alias_token, rest)
    case Nil{}:
      ((Ast.ModuleImport{ canonical, canonical, span(file, beg, token_end(path_token))}, as_token <> Nil{}), False{})

def is_base_path(token: Lexer.Token) -> Bool:
  match token:
    case Lexer.TokenInfo{ Lexer.NameToken{},  "Base",  _,  _,  _,  _}:
      True{}
    case _:
      False{}

def parse_module_import_modifier(file: String, fragments: List<&2, String>, beg: Nat, path_token: Lexer.Token, modifier: Lexer.Token, after_modifier: List<&2, Lexer.Token>) -> (Ast.ModuleImport & List<&2, Lexer.Token>) & Bool:
  match path_token modifier:
    case Lexer.TokenInfo{path_kind, _, path_beg, path_end, path_line, path_col} Lexer.TokenInfo{kind, "as", field_beg, field_end, line, col}:
      +canonical = String.concat(List.reverse(&2, String, fragments))
      parse_module_import_alias_target(file, canonical, beg, Lexer.TokenInfo{path_kind, canonical, path_beg, path_end, path_line, path_col}, Lexer.TokenInfo{kind, "as", field_beg, field_end, line, col}, after_modifier)
    case Lexer.TokenInfo{path_kind, _, path_beg, path_end, path_line, path_col} Lexer.TokenInfo{kind, text, field_beg, field_end, line, col}:
      +canonical = String.concat(List.reverse(&2, String, fragments))
      +complete_path = {Lexer.TokenInfo{path_kind, canonical, path_beg, path_end, path_line, path_col} : Lexer.Token}
      module_import_without_alias(is_base_path(complete_path), file, canonical, beg, complete_path, Lexer.TokenInfo{kind, text, field_beg, field_end, line, col} <> after_modifier)

def parse_module_import_path_rest(tokens: List<&2, Lexer.Token>, is_spaced: Bool, +path_token: Lexer.Token, file: String, fragments: List<&2, String>, beg: Nat) -> (Ast.ModuleImport & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +modifier <> +after_modifier:
      match modifier:
        case Lexer.TokenInfo{Lexer.NewlineToken{}, _, _, _, _, _}:
          parse_module_import_modifier(file, fragments, beg, path_token, modifier, after_modifier)
        case Lexer.TokenInfo{Lexer.EndToken{}, _, _, _, _, _}:
          parse_module_import_modifier(file, fragments, beg, path_token, modifier, after_modifier)
        case Lexer.TokenInfo{Lexer.ErrorToken{}, _, _, _, _, _}:
          parse_module_import_modifier(file, fragments, beg, path_token, modifier, after_modifier)
        case Lexer.TokenInfo{kind, text, start, +fin, line, col}:
          match is_spaced:
            case False{}:
              match path_token:
                case Lexer.TokenInfo{path_kind, path_text, path_beg, _, path_line, path_col}:
                  parse_module_import_path_rest(after_modifier, has_space_after(fin, after_modifier), Lexer.TokenInfo{path_kind, path_text, path_beg, fin, path_line, path_col}, file, text <> fragments, beg)
            case True{}:
              parse_module_import_modifier(file, fragments, beg, path_token, Lexer.TokenInfo{kind, text, start, fin, line, col}, after_modifier)
    case Nil{}:
      match path_token:
        case Lexer.TokenInfo{path_kind, _, path_beg, path_end, path_line, path_col}:
          +canonical = String.concat(List.reverse(&2, String, fragments))
          +complete_path = {Lexer.TokenInfo{path_kind, canonical, path_beg, path_end, path_line, path_col} : Lexer.Token}
          module_import_without_alias(is_base_path(complete_path), file, canonical, beg, complete_path, Nil{})

def strip_quotes_reversed(reversed: List<&2, Char>) -> String:
  match reversed:
    case +_ <> chars:
      String.from_list(List.reverse(&2, Char, chars))
    case Nil{}:
      SNil{}
def strip_quotes_chars(chars: List<&2, Char>, text: String) -> String:
  match chars:
    case +_ <> rest:
      strip_quotes_reversed(List.reverse(&2, Char, rest))
    case Nil{}:
      text

def strip_quotes(+text: String) -> String:
  strip_quotes_chars(String.to_list(text), text)

def external_import_token_action(token: Lexer.Token) -> Nat:
  match token:
    case Lexer.TokenInfo{ Lexer.NewlineToken{},  _,  _,  _,  _,  _}:
      0n
    case Lexer.TokenInfo{ Lexer.NameToken{},  "import",  _,  _,  _,  _}:
      1n
    case _:
      2n

def external_import_action(current: List<&2, Lexer.Token>) -> Nat:
  match current:
    case +token <> _:
      external_import_token_action(token)
    case Nil{}:
      2n

def external_import_worker(+current: List<&2, Lexer.Token>, original: List<&2, Lexer.Token>, acc: List<&2, String>, action: Nat) -> (List<&2, String> & List<&2, Lexer.Token>) & Bool:
  match current action:
    case +token <> +rest 0n:
      external_import_worker(rest, original, acc, external_import_action(rest))
    case +token <> Lexer.TokenInfo{ Lexer.StringToken{}, text,  _,  _,  _,  _} <> +after_path 1n:
      external_import_worker(after_path, after_path, strip_quotes(text) <> acc, external_import_action(after_path))
    case +token <> +path_token <> after_path 1n:
      ((List.reverse(&2, String, acc), path_token <> after_path), False{})
    case +token <> Nil{} 1n:
      ((List.reverse(&2, String, acc), Nil{}), False{})
    case _ <> _ _:
      ((List.reverse(&2, String, acc), original), True{})
    case Nil{} _:
      ((List.reverse(&2, String, acc), Nil{}), True{})

def external_import_start(+current: List<&2, Lexer.Token>, original: List<&2, Lexer.Token>, acc: List<&2, String>) -> (List<&2, String> & List<&2, Lexer.Token>) & Bool:
  external_import_worker(current, original, acc, external_import_action(current))

def parse_external_imports_scan(current: List<&2, Lexer.Token>, original: List<&2, Lexer.Token>, acc: List<&2, String>) -> (List<&2, String> & List<&2, Lexer.Token>) & Bool:
  external_import_start(current, original, acc)

def parse_external_imports(+tokens: List<&2, Lexer.Token>, acc: List<&2, String>) -> (List<&2, String> & List<&2, Lexer.Token>) & Bool:
  parse_external_imports_scan(tokens, tokens, acc)

def parse_string(file: String, text: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_string_result(string_chars(file, String.to_list(strip_quotes(text)), beg, end), rest)

def parse_char_literal(file: String, text: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_char_literal_chars(String.to_list(strip_quotes(text)), file, beg, end, rest)

def parse_do_atom_colon(+colon: Lexer.Token, +after_colon: List<&2, Lexer.Token>, args: List<&2, Ast.SyntaxTerm>, file: String, key: String, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match colon:
    case Lexer.TokenInfo{_, ":", +_, +_, +_, +_}:
      parse_do_return(file, key, args, after_colon, beg, end, scope, depth, do_first_col(after_colon))
    case _:
      ((Ast.TermHole{"parse-error: expected : after do parameters", span(file, token_beg(colon), token_end(colon))}, colon <> after_colon), False{})
def parse_do_atom_args_result(result: (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool, file: String, key: String, beg: Nat, +end: Nat, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((args, +colon <> after_colon), True{}):
      parse_do_atom_colon(colon, after_colon, args, file, key, beg, end, scope, depth)
    case ((_, after_args), False{}):
      ((Ast.TermHole{"parse-error: expected do parameters", span(file, end, end)}, after_args), False{})
    case _:
      ((Ast.TermHole{"parse-error: expected do parameters", span(file, end, end)}, tokens), False{})
def parse_do_atom(+file: String, tokens: List<&2, Lexer.Token>, +beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +monad <> rest:
      match monad:
        case Lexer.TokenInfo{Lexer.NameToken{}, key, _, end, _, _}:
          match rest:
            case +open <> +after_open:
              match open:
                case Lexer.TokenInfo{_, "<", _, _, _, _}:
                  parse_do_atom_args_result(parse_term_args(file, after_open, ">", scope, depth, Nil{}), file, key, beg, end, tokens, scope, depth)
                case Lexer.TokenInfo{_, "<>", _, _, _, _}:
                  parse_do_atom_args_result(((Nil{}, after_open), True{}), file, key, beg, end, tokens, scope, depth)
                case _:
                  ((Ast.TermHole{"parse-error: expected < after do monad", span(file, token_beg(open), token_end(open))}, rest), False{})
            case Nil{}:
              ((Ast.TermHole{"parse-error: expected do monad parameters", span(file, end, end)}, rest), False{})
        case _:
          ((Ast.TermHole{"parse-error: expected do monad", span(file, token_beg(monad), token_end(monad))}, tokens), False{})
    case Nil{}:
      ((Ast.TermHole{"parse-error: expected do monad", span(file, beg, beg)}, Nil{}), False{})
def parse_atom_name_dispatch(text: String, +file: String, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat, end: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  match text:
    case "do":
      parse_do_atom(file, rest, beg, scope, depth)
    case "Type":
      ((Ast.TermType{ Ast.TermQuantity{ Ast.QOne{},  span(file, beg, end)},  span(file, beg, end)}, rest), True{})
    case "Data":
      ((Ast.TermType{ Ast.TermQuantity{ Ast.QMany{},  span(file, beg, end)},  span(file, beg, end)}, rest), True{})
    case "Quant":
      ((Ast.TermQuant{}, rest), True{})
    case "Kind":
      match rest:
        case +open <> +more:
          match open:
            case Lexer.TokenInfo{ _, "(",  _,  _,  _,  _}:
              parse_kind_result(parse_term(file, more, scope, depth, 0n), file, beg, end, rest)
            case _:
              ((Ast.TermHole{ "parse-error: expected (",  span(file, beg, end)}, rest), False{})
        case Nil{}:
          ((Ast.TermHole{ "parse-error: expected (",  span(file, beg, end)}, rest), False{})
    case _:
      parse_name_term(file, text, beg, end, rest, scope, depth)

def parse_atom_symbol_row_0(+file: String, rest: List<&2, Lexer.Token>, beg: Nat, end: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  match rest:
    case +name <> tail:
      match name:
        case Lexer.TokenInfo{ Lexer.NameToken{},  key,  _,  fin,  _,  _}:
          ((Ast.TermHole{key,  span(file, beg, fin)}, tail), True{})
        case _:
          ((Ast.TermHole{ "parse-error: expected a hole name",  span(file, beg, end)}, rest), False{})
    case Nil{}:
      ((Ast.TermHole{ "parse-error: expected a hole name",  span(file, beg, end)}, rest), False{})

def parse_atom_symbol_row_1(+file: String, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat, end: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  parse_list(file, rest, beg, end, scope, depth)

def parse_atom_symbol_row_2(+file: String, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat, end: Nat, col: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  parse_parenthesized(file, rest, beg, end, col, scope, depth)

def parse_atom_symbol_row_3(+file: String, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat, end: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  parse_rewrite(file, rest, beg, end, scope, depth)

def parse_atom_symbol_row_4(+file: String, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  parse_all(file, rest, scope, depth, beg, Ast.QMany{})

def parse_atom_symbol_row_5(+file: String, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat, end: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  parse_amp(file, rest, scope, depth, beg, end)

def parse_atom_symbol_row_6(+file: String, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  parse_many_lambda(file, rest, beg, scope, depth)

def parse_atom_symbol_row_7(+file: String, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat, end: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  parse_absurd(file, rest, beg, end, scope, depth)

def parse_atom_symbol_row_8(+file: String, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  parse_template_term(file, rest, beg, scope, depth)

def parse_atom_symbol_row_9(+file: String, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat, end: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  parse_brace(file, rest, beg, end, scope, depth)

def parse_atom_symbol_row_10(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected a term",  span(file, beg, end)}, tokens), False{})

def parse_atom_symbol_dispatch(text: String, +file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat, end: Nat, col: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  match text:
    case "?":
      parse_atom_symbol_row_0(file, rest, beg, end)
    case "[":
      parse_atom_symbol_row_1(file, scope, depth, rest, beg, end)
    case "(":
      parse_atom_symbol_row_2(file, scope, depth, rest, beg, end, col)
    case "%":
      parse_atom_symbol_row_3(file, scope, depth, rest, beg, end)
    case "@":
      parse_atom_symbol_row_4(file, scope, depth, rest, beg)
    case "&":
      parse_atom_symbol_row_5(file, scope, depth, rest, beg, end)
    case "+":
      parse_atom_symbol_row_6(file, scope, depth, rest, beg)
    case "\\":
      parse_atom_symbol_row_7(file, scope, depth, rest, beg, end)
    case "~":
      parse_atom_symbol_row_8(file, scope, depth, rest, beg)
    case "{":
      parse_atom_symbol_row_9(file, scope, depth, rest, beg, end)
    case _:
      parse_atom_symbol_row_10(file, tokens, beg, end)

def parse_atom_scan(+file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match scanned:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{ Lexer.NameToken{}, text, beg, end,  _,  _}:
          parse_atom_name_dispatch(text, file, scope, depth, rest, beg, end)
        case Lexer.TokenInfo{ Lexer.NumberToken{}, text, beg, end,  _,  _}:
          parse_number(file, text, beg, end, rest, scope, depth)
        case Lexer.TokenInfo{ Lexer.SymbolToken{}, text, beg, end,  _, col}:
          parse_atom_symbol_dispatch(text, file, tokens, scope, depth, rest, beg, end, col)
        case Lexer.TokenInfo{ Lexer.StringToken{}, text, beg, end,  _,  _}:
          parse_string(file, text, beg, end, rest)
        case Lexer.TokenInfo{ Lexer.CharToken{}, text, beg, end,  _,  _}:
          parse_char_literal(file, text, beg, end, rest)
        case _:
          ((Ast.TermHole{ "parse-error: expected a term",  span(file, token_beg(token), token_end(token))}, tokens), False{})
    case Nil{}:
      ((Ast.TermHole{ "parse-error: expected a term",  span(file, 0n, 0n)}, Nil{}), False{})
def parse_atom(file: String, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_atom_scan(file, tokens, skip_lines(tokens), scope, depth)

def parse_template_term(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_template_term_result(parse_term(file, tokens, scope, depth, 12n), file, beg)





def parse_do_return_scan(+file: String, key: String, args: List<&2, Ast.SyntaxTerm>, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match scanned:
    case +return_token <> rest:
      match return_token:
        case Lexer.TokenInfo{Lexer.NameToken{}, "return", _, _, _, _}:
          parse_do_return_value_result(parse_term(file, rest, scope, depth, 0n), file, key, args, beg, end)
        case _:
          parse_do_typed_bind(file, key, args, return_token <> rest, beg, end, scope, depth, col)
    case Nil{}:
      ((Ast.TermHole{"parse-error: expected return in do block", span(file, beg, end)}, Nil{}), False{})

def parse_do_return(file: String, key: String, args: List<&2, Ast.SyntaxTerm>, +tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_do_return_scan(file, key, args, tokens, skip_lines(tokens), beg, end, scope, depth, col)

type DoTokenAction is Data:
  DoTokenActionRow0{}
  DoTokenActionRow1{}
  DoTokenActionRow2{}

def do_token_action(bind_token: Lexer.Token) -> DoTokenAction:
  match bind_token:
    case Lexer.TokenInfo{_, "<-", +_, +_, +_, +_}:
      DoTokenActionRow0{}
    case Lexer.TokenInfo{_, "=", _, _, _, _}:
      DoTokenActionRow1{}
    case _:
      DoTokenActionRow2{}

def do_token_branch_0(after_bind: List<&2, Lexer.Token>, ty: Ast.SyntaxTerm, +file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, key: String, key_beg: Nat, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat, col: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  parse_do_typed_bind_value_result(parse_term(file, after_bind, scope, depth, 0n), file, monad, args, key, key_beg, ty, beg, end, scope, depth, col)

def do_token_branch_1(after_bind: List<&2, Lexer.Token>, ty: Ast.SyntaxTerm, +file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, key: String, key_beg: Nat, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat, col: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  parse_do_assignment(file, monad, args, key, key_beg, ty, after_bind, beg, end, scope, depth, col)

def do_token_branch_2(+bind_token: Lexer.Token, after_bind: List<&2, Lexer.Token>, +file: String) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{"parse-error: expected <- in do binding", span(file, token_beg(bind_token), token_end(bind_token))}, bind_token <> after_bind), False{})

def do_token_run(action: DoTokenAction, +bind_token: Lexer.Token, after_bind: List<&2, Lexer.Token>, ty: Ast.SyntaxTerm, +file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, key: String, key_beg: Nat, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat, col: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  match action:
    case DoTokenActionRow0{}:
      do_token_branch_0(after_bind, ty, file, monad, args, key, key_beg, beg, end, scope, depth, col)
    case DoTokenActionRow1{}:
      do_token_branch_1(after_bind, ty, file, monad, args, key, key_beg, beg, end, scope, depth, col)
    case DoTokenActionRow2{}:
      do_token_branch_2(bind_token, after_bind, file)

def parse_do_typed_bind_type_token(+bind_token: Lexer.Token, after_bind: List<&2, Lexer.Token>, ty: Ast.SyntaxTerm, +file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, key: String, key_beg: Nat, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  do_token_run(do_token_action(bind_token), bind_token, after_bind, ty, file, monad, args, key, key_beg, beg, end, scope, depth, col)

def parse_do_typed_bind_type_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, key: String, key_beg: Nat, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((ty, +bind_token <> after_bind), True{}):
      parse_do_typed_bind_type_token(bind_token, after_bind, ty, file, monad, args, key, key_beg, beg, end, scope, depth, col)
    case ((ty, after_ty), False{}):
      ((ty, after_ty), False{})
    case ((ty, after_ty), True{}):
      ((ty, after_ty), False{})

def parse_do_typed_bind_value_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, +file: String, +monad: String, +args: List<&2, Ast.SyntaxTerm>, +key: String, key_beg: Nat, ty: Ast.SyntaxTerm, +beg: Nat, +end: Nat, scope: List<&2, Scope>, +depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((value, after_value), True{}):
      next_scope = extend_scope(key, depth, scope)
      with_term_result(parse_do_return(file, monad, args, skip_rewrite_semicolon(after_value), beg, end, next_scope, depth + 1n, col), body => after_body => ok_body => parse_do_typed_bind_body_result(ok_body, body, after_body, file, monad, args, key, key_beg, ty, value, beg, end, depth))
    case ((value, after_value), False{}):
      ((value, after_value), False{})

def parse_do_typed_bind(+file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
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

def parse_do_assignment_value_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, +file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, +key: String, key_beg: Nat, ty: Ast.SyntaxTerm, beg: Nat, end: Nat, scope: List<&2, Scope>, +depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((value, after_value), True{}):
      next_scope = extend_scope(key, depth, scope)
      with_term_result(parse_do_return(file, monad, args, skip_rewrite_semicolon(after_value), beg, end, next_scope, depth + 1n, col), body => after_body => ok_body => parse_do_assignment_body_result(ok_body, body, after_body, file, key, key_beg, depth, ty, value))
    case ((value, after_value), False{}):
      ((value, after_value), False{})

def parse_do_assignment(+file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, key: String, key_beg: Nat, ty: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_do_assignment_value_result(parse_term(file, tokens, scope, depth, 0n), file, monad, args, key, key_beg, ty, beg, end, scope, depth, col)

def parse_do_untyped_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  with_term_result(result, action => +after_action => ok => parse_do_untyped_action_result(ok, action, after_action, file, monad, args, beg, end, scope, depth, col))

def parse_do_untyped_action_result(ok: Bool, action: Ast.SyntaxTerm, +after_action: List<&2, Lexer.Token>, file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok:
    case True{}:
      parse_do_untyped_after_action(file, monad, args, action, after_action, skip_rewrite_semicolon(after_action), beg, end, scope, depth, col)
    case False{}:
      ((action, after_action), False{})

def parse_do_untyped_value_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, action: Ast.SyntaxTerm, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((value, after_value), True{}):
      parse_do_bind(file, monad, args, action, value, after_value, beg, end, scope, depth, col)
    case ((value, after_value), False{}):
      ((value, after_value), False{})

def parse_do_untyped_after_action(+file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, action: Ast.SyntaxTerm, after_action: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match scanned:
    case +bind_token <> after_bind:
      match bind_token:
        case Lexer.TokenInfo{_, "<-", _, _, _, _}:
          parse_do_untyped_value_result(parse_term(file, after_bind, scope, depth, 0n), file, monad, args, action, beg, end, scope, depth, col)
        case _:
          parse_do_untyped_step(file, monad, args, action, after_action, beg, end, scope, depth, col)
    case Nil{}:
      ((action, after_action), True{})

def parse_do_untyped(+file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_do_untyped_result(parse_term(file, tokens, scope, depth, 0n), file, monad, args, beg, end, scope, depth, col)

def parse_do_untyped_step(file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, action: Ast.SyntaxTerm, +tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, +col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_do_untyped_step_after_check(do_has_more(tokens, col), file, monad, args, action, tokens, beg, end, scope, depth, col)

def parse_do_untyped_step_after_check(has_more: Bool, +file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, action: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, +beg: Nat, +end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match has_more:
    case True{}:
      parse_do_bind(file, monad, args, Ast.TermRef{ "Unit",  span(file, beg, end)}, action, tokens, beg, end, scope, depth, col)
    case False{}:
      ((action, tokens), True{})

def parse_do_bind(+file: String, +monad: String, +args: List<&2, Ast.SyntaxTerm>, ty: Ast.SyntaxTerm, value: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, +beg: Nat, +end: Nat, scope: List<&2, Scope>, +depth: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  next_scope = extend_scope("_", depth, scope)
  with_term_result(parse_do_return(file, monad, args, skip_rewrite_semicolon(tokens), beg, end, next_scope, depth + 1n, col), body => after_body => ok_body => parse_do_bind_body_result(ok_body, body, after_body, file, monad, args, ty, value, beg, end, depth))
def parse_amp(file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, beg: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +quantity <> rest:
      match quantity:
        case Lexer.TokenInfo{ _, "0",  _,  _,  _,  _}:
          ((Ast.TermQuantity{ Ast.QZero{},  span(file, beg, token_end(quantity))}, rest), True{})
        case Lexer.TokenInfo{ _, "1",  _,  _,  _,  _}:
          ((Ast.TermQuantity{ Ast.QOne{},  span(file, beg, token_end(quantity))}, rest), True{})
        case Lexer.TokenInfo{ _, "2",  _,  _,  _,  _}:
          ((Ast.TermQuantity{ Ast.QMany{},  span(file, beg, token_end(quantity))}, rest), True{})
        case _:
          parse_all(file, tokens, scope, depth, beg, Ast.QOne{})
    case Nil{}:
      parse_all(file, Nil{}, scope, depth, beg, Ast.QOne{})

def parse_number(file: String, +text: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_number_suffix(has_nat_suffix(text), file, text, beg, end, rest, scope, depth)

def parse_number_suffix(has_suffix: Bool, file: String, +text: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match has_suffix:
    case True{}:
      parse_number_nat_result(Nat.read(drop_nat_suffix(text)), True{}, file, text, beg, end, rest, scope, depth)
    case False{}:
      parse_number_nat_result(Nat.read(text), False{}, file, text, beg, end, rest, scope, depth)

def parse_number_nat_result(result: Maybe<&2, Nat>, has_suffix: Bool, file: String, text: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case Some{+value}:
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

def parse_nat_literal(+file: String, value: Nat, beg: Nat, end: Nat, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +plus <> rest:
      match plus:
        case Lexer.TokenInfo{_, "+", _, _, _, _}:
          parse_nat_literal_tail(parse_term(file, rest, scope, depth, 0n), file, value, beg, end)
        case _:
          ((nat_literal(file, value, beg, end), tokens), True{})
    case Nil{}:
      ((nat_literal(file, value, beg, end), Nil{}), True{})

def parse_list(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, +end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +close <> after_close:
      match close:
        case Lexer.TokenInfo{_, "]", _, _, _, _}:
          ((Ast.TermCtr{"Nil", Nil{}, span(file, beg, token_end(close))}, after_close), True{})
        case _:
          expr_match_ok_after(parse_term(file, tokens, scope, depth, 0n), file, beg, token_end(close), scope, depth)
    case Nil{}:
      ((Ast.TermHole{"parse-error: expected ]", span(file, end, end)}, Nil{}), False{})

def expr_match_ok_after(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((first, +separator <> after_separator), True{}):
      expr_match_list_separator(separator, after_separator, file, first, beg, end, scope, depth)
    case ((first, after_first), False{}):
      ((first, after_first), False{})
    case ((first, after_first), True{}):
      ((first, after_first), False{})
def expr_match_list_separator(+separator: Lexer.Token, after_separator: List<&2, Lexer.Token>, +file: String, first: Ast.SyntaxTerm, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match separator:
    case Lexer.TokenInfo{_, ":", +_, +_, +_, +_}:
      parse_array_literal(file, first, after_separator, beg, end, scope, depth)
    case Lexer.TokenInfo{_, ",", _, _, _, _}:
      with_args_result(parse_term_args(file, after_separator, "]", scope, depth, Nil{}), items => after_items => ok_items => expr_finish_list_items(ok_items, items, after_items, file, first, beg))
    case Lexer.TokenInfo{_, "]", _, _, _, _}:
      expr_finish_list(make_list(file, [first], beg, token_end(separator)), after_separator)
    case _:
      ((Ast.TermHole{"parse-error: expected , : or ]", span(file, token_beg(separator), token_end(separator))}, after_separator), False{})

def parse_array_literal(+file: String, value: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  expr_match_array_type(parse_term(file, tokens, scope, depth, 12n), file, value, beg, end, scope, depth)

type ArrayShapeAction is Data:
  ArrayShapeActionRow0{}
  ArrayShapeActionRow1{}
  ArrayShapeActionRow2{}

def array_shape_action(shape: Lexer.Token) -> ArrayShapeAction:
  match shape:
    case Lexer.TokenInfo{_, "*", +_, +_, +_, +_}:
      ArrayShapeActionRow0{}
    case Lexer.TokenInfo{_, "^", _, _, _, _}:
      ArrayShapeActionRow1{}
    case _:
      ArrayShapeActionRow2{}

def array_shape_branch_0(after_shape: List<&2, Lexer.Token>, +file: String, value: Ast.SyntaxTerm, ty: Ast.SyntaxTerm, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  expr_match_array_count(parse_term(file, after_shape, scope, depth, 0n), file, value, ty, beg, end)

def array_shape_branch_1(after_shape: List<&2, Lexer.Token>, +file: String, value: Ast.SyntaxTerm, ty: Ast.SyntaxTerm, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  expr_match_array_depth(parse_term(file, after_shape, scope, depth, 0n), file, value, ty, beg, end)

def array_shape_branch_2(+shape: Lexer.Token, after_shape: List<&2, Lexer.Token>, +file: String) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{"parse-error: expected * or ^ in array literal", span(file, token_beg(shape), token_end(shape))}, shape <> after_shape), False{})

def array_shape_run(action: ArrayShapeAction, +shape: Lexer.Token, after_shape: List<&2, Lexer.Token>, +file: String, value: Ast.SyntaxTerm, ty: Ast.SyntaxTerm, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  match action:
    case ArrayShapeActionRow0{}:
      array_shape_branch_0(after_shape, file, value, ty, beg, end, scope, depth)
    case ArrayShapeActionRow1{}:
      array_shape_branch_1(after_shape, file, value, ty, beg, end, scope, depth)
    case ArrayShapeActionRow2{}:
      array_shape_branch_2(shape, after_shape, file)

def expr_match_array_shape(+shape: Lexer.Token, after_shape: List<&2, Lexer.Token>, +file: String, value: Ast.SyntaxTerm, ty: Ast.SyntaxTerm, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  array_shape_run(array_shape_action(shape), shape, after_shape, file, value, ty, beg, end, scope, depth)

def expr_match_array_type(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, value: Ast.SyntaxTerm, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((ty, +shape <> after_shape), True{}):
      expr_match_array_shape(shape, after_shape, file, value, ty, beg, end, scope, depth)
    case ((ty, after_ty), False{}):
      ((ty, after_ty), False{})
    case ((ty, after_ty), True{}):
      ((ty, after_ty), False{})

def parse_parenthesized_result(result: (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool, file: String, beg: Nat, end: Nat, tokens: List<&2, Lexer.Token>, col: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((terms, after), True{}):
      parse_parenthesized_terms(terms, after, file, beg, end)
    case (_, False{}):
      parse_parenthesized_body(file, tokens, beg, end, col, scope, depth)

def parse_parenthesized(+file: String, +tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_parenthesized_result(parse_term_args(file, tokens, ")", scope, depth, Nil{}), file, beg, end, tokens, col, scope, depth)
def parse_parenthesized_body_close(close: Lexer.Token, rest: List<&2, Lexer.Token>, body: Ast.SyntaxTerm, file: String, tokens: List<&2, Lexer.Token>, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match close:
    case Lexer.TokenInfo{_, ")", _, _, _, _}:
      parse_parenthesized_body_result(body, rest)
    case _:
      parse_typed_operator(file, tokens, beg, scope, depth)

def parse_parenthesized_body_result_checked(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, tokens: List<&2, Lexer.Token>, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((body, +close <> rest), True{}):
      parse_parenthesized_body_close(close, rest, body, file, tokens, beg, scope, depth)
    case _:
      parse_typed_operator(file, tokens, beg, scope, depth)

def parse_parenthesized_body(+file: String, +tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_parenthesized_body_result_checked(parse_body(file, tokens, scope, depth, col), file, tokens, beg, scope, depth)
def parse_typed_operator_colon(+colon: Lexer.Token, after_colon: List<&2, Lexer.Token>, after_term: List<&2, Lexer.Token>, term: Ast.SyntaxTerm, +file: String, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match colon:
    case Lexer.TokenInfo{_, ":", +_, +_, +_, +_}:
      parse_typed_operator_type(parse_term(file, after_colon, scope, depth, 0n), file, term)
    case _:
      ((Ast.TermHole{"parse-error: expected :", span(file, token_beg(colon), token_end(colon))}, after_term), False{})

def parse_typed_operator_term(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((term, +colon <> +after_colon), True{}):
      parse_typed_operator_colon(colon, after_colon, colon <> after_colon, term, file, scope, depth)
    case ((term, after_term), False{}):
      ((term, after_term), False{})
    case ((term, after_term), True{}):
      ((term, after_term), False{})

def parse_typed_operator(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_typed_operator_term(parse_term(file, tokens, scope, depth, 0n), file, scope, depth)

def parse_absurd(file: String, tokens: List<&2, Lexer.Token>, beg: Nat, +end: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +open <> rest:
      match open:
        case Lexer.TokenInfo{ _, "{",  _,  _,  _,  _}:
          match rest:
            case +close <> tail:
              match close:
                case Lexer.TokenInfo{ _, "}",  _,  _,  _,  _}:
                  ((Ast.TermAbsurd{ span(file, beg, token_end(close))}, tail), True{})
                case _:
                  parse_match_expr(file, rest, beg, end, scope, depth)
            case Nil{}:
              ((Ast.TermHole{ "parse-error: expected }",  span(file, end, end)}, rest), False{})
        case _:
          ((Ast.TermHole{ "parse-error: expected { after backslash",  span(file, token_beg(open), token_end(open))}, tokens), False{})
    case Nil{}:
      ((Ast.TermHole{ "parse-error: expected { after backslash",  span(file, end, end)}, Nil{}), False{})

def parse_match_expr_after_head(file: String, key: String, head: Ast.SyntaxTerm, after_head: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match scanned:
    case +semicolon <> after_semicolon:
      match semicolon:
        case Lexer.TokenInfo{ _, ";",  _,  _,  _,  _}:
          parse_match_chain(file, key, head, after_semicolon, beg, scope, depth)
        case _:
          parse_match_chain(file, key, head, after_head, beg, scope, depth)
    case Nil{}:
      parse_match_chain(file, key, head, after_head, beg, scope, depth)

def parse_match_expr_head_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, key: String, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  with_term_result(result, head => +after_head => ok => parse_match_expr_parsed_head(ok, head, after_head, file, key, beg, scope, depth))

def parse_match_expr_parsed_head(ok: Bool, head: Ast.SyntaxTerm, +after_head: List<&2, Lexer.Token>, file: String, key: String, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok:
    case True{}:
      parse_match_expr_after_head(file, key, head, after_head, skip_lines(after_head), beg, scope, depth)
    case False{}:
      ((head, after_head), False{})

def parse_match_expr_after_name(+file: String, original: List<&2, Lexer.Token>, key: String, scanned: List<&2, Lexer.Token>, beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match scanned:
    case +colon <> after_colon:
      match colon:
        case Lexer.TokenInfo{_, ":", _, _, _, _}:
          parse_match_expr_head_result(parse_term(file, after_colon, scope, depth, 0n), file, key, beg, scope, depth)
        case _:
          parse_match_tail(file, original, beg, scope, depth)
    case Nil{}:
      parse_match_tail(file, original, beg, scope, depth)

def parse_match_expr_scan(file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, beg: Nat, +end: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match scanned:
    case +name <> after_name:
      match name:
        case Lexer.TokenInfo{ Lexer.NameToken{},  key,  _,  _,  _,  _}:
          parse_match_expr_after_name(file, tokens, key, skip_lines(after_name), beg, scope, depth)
        case _:
          parse_match_tail(file, tokens, beg, scope, depth)
    case Nil{}:
      ((Ast.TermHole{ "parse-error: expected a match tail",  span(file, end, end)}, Nil{}), False{})

def parse_match_expr(file: String, +tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_match_expr_scan(file, tokens, skip_lines(tokens), beg, end, scope, depth)
def parse_match_chain_state(state: MatchChainState) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match state:
    case MatchChainStart{file, key, head, original, scanned, +beg, scope, depth}:
      match scanned:
        case +name <> after_name:
          match name:
            case Lexer.TokenInfo{ Lexer.NameToken{},  next_key,  _,  _,  _,  _}:
              parse_match_chain_state(MatchChainAfterName{file, key, head, original, next_key, skip_lines(after_name), beg, scope, depth})
            case _:
              parse_match_tail_with_head(file, key, head, original, beg, scope, depth)
        case Nil{}:
          ((Ast.TermHole{ "parse-error: expected a match tail",  span(file, beg, beg)}, Nil{}), False{})
    case MatchChainAfterName{+file, key, head, original, next_key, scanned, beg, +scope, +depth}:
      match scanned:
        case +colon <> after_colon:
          match colon:
            case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
              with_term_result(parse_term(file, after_colon, scope, depth, 0n), next_head => +after_head => ok_head => parse_match_chain_state(MatchChainAfterHead{file, key, head, original, next_key, next_head, after_head, ok_head, skip_lines(after_head), beg, scope, depth}))
            case _:
              parse_match_tail_with_head(file, key, head, original, beg, scope, depth)
        case Nil{}:
          parse_match_tail_with_head(file, key, head, original, beg, scope, depth)
    case MatchChainAfterHead{+file, key, head, original, next_key, next_head, +after_head, ok_head, scanned, +beg, scope, depth}:
      match ok_head:
        case True{}:
          match scanned:
            case +semicolon <> +after_semicolon:
              match semicolon:
                case Lexer.TokenInfo{ _, ";",  _,  _,  _,  _}:
                  with_term_result(parse_match_chain_state(MatchChainStart{file, next_key, next_head, after_semicolon, skip_lines(after_semicolon), beg, scope, depth}), matched => after_matched => ok_matched => parse_match_chain_state(MatchChainAfterMatch{file, key, head, matched, after_matched, ok_matched, beg}))
                case _:
                  with_term_result(parse_match_chain_state(MatchChainStart{file, next_key, next_head, after_head, skip_lines(after_head), beg, scope, depth}), matched => after_matched => ok_matched => parse_match_chain_state(MatchChainAfterMatch{file, key, head, matched, after_matched, ok_matched, beg}))
            case Nil{}:
              with_term_result(parse_match_chain_state(MatchChainStart{file, next_key, next_head, after_head, skip_lines(after_head), beg, scope, depth}), matched => after_matched => ok_matched => parse_match_chain_state(MatchChainAfterMatch{file, key, head, matched, after_matched, ok_matched, beg}))
        case False{}:
          ((next_head, after_head), False{})
    case MatchChainAfterMatch{file, key, head, +matched, after_matched, ok_matched, beg}:
      match ok_matched:
        case True{}:
          ((Ast.TermMat{key, head, matched,  span(file, beg, token_end_first(matched))}, after_matched), True{})
        case False{}:
          ((matched, after_matched), False{})

def parse_match_chain(file: String, key: String, head: Ast.SyntaxTerm, +tokens: List<&2, Lexer.Token>, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_match_chain_state(MatchChainStart{file, key, head, tokens, skip_lines(tokens), beg, scope, depth})

def parse_match_tail_with_head(+file: String, key: String, head: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, +beg: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  with_term_result(parse_match_tail(file, tokens, beg, scope, depth), tail => after_tail => ok_tail => parse_match_tail_with_head_result(ok_tail, tail, after_tail, file, key, head, beg))

def parse_match_tail(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  with_term_result(parse_term(file, tokens, scope, depth, 0n), tail => after_tail => ok_tail => parse_match_tail_result(ok_tail, file, tail, after_tail))
def brace_equal_right_branch_0(right: Ast.SyntaxTerm, +file: String, left: Ast.SyntaxTerm, beg: Nat, scope: List<&2, Scope>, depth: Nat, after_colon: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  with_term_result(parse_term(file, after_colon, scope, depth, 0n), ty => after_ty => ok_ty => parse_brace_equal_type_result(ok_ty, after_ty, ty, file, left, right, beg))

def brace_equal_right_branch_1(after_right: List<&2, Lexer.Token>, +file: String, +colon: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected :",  span(file, token_beg(colon), token_end(colon))}, after_right), False{})

def brace_equal_right_is_colon(colon: Lexer.Token) -> Bool:
  match colon:
    case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
      True{}
    case _:
      False{}

def brace_equal_right_run(is_colon: Bool, after_right: List<&2, Lexer.Token>, right: Ast.SyntaxTerm, +file: String, left: Ast.SyntaxTerm, beg: Nat, scope: List<&2, Scope>, depth: Nat, +colon: Lexer.Token, after_colon: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  match is_colon:
    case True{}:
      brace_equal_right_branch_0(right, file, left, beg, scope, depth, after_colon)
    case False{}:
      brace_equal_right_branch_1(after_right, file, colon)

def parse_brace_equal_right_result(ok_right: Bool, after_right: List<&2, Lexer.Token>, right: Ast.SyntaxTerm, +file: String, left: Ast.SyntaxTerm, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_right after_right:
    case True{} +colon <> after_colon:
      brace_equal_right_run(brace_equal_right_is_colon(colon), after_right, right, file, left, beg, scope, depth, colon, after_colon)
    case _ _:
      ((right, after_right), False{})

type BraceEqualsAction is Data:
  BraceEqualsActionRow0{}
  BraceEqualsActionRow1{}
  BraceEqualsActionRow2{}
  BraceEqualsActionRow3{}

def brace_equals_action(equals: Lexer.Token) -> BraceEqualsAction:
  match equals:
    case Lexer.TokenInfo{ _, "!=",  +_,  +_,  +_,  +_}:
      BraceEqualsActionRow0{}
    case Lexer.TokenInfo{_, "==", _, _, _, _}:
      BraceEqualsActionRow1{}
    case Lexer.TokenInfo{_, ":", _, _, _, _}:
      BraceEqualsActionRow2{}
    case _:
      BraceEqualsActionRow3{}

def brace_equals_branch_0(after_equals: List<&2, Lexer.Token>, left: Ast.SyntaxTerm, +file: String, beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  parse_inequality(file, left, after_equals, beg, scope, depth)

def brace_equals_branch_1(after_equals: List<&2, Lexer.Token>, left: Ast.SyntaxTerm, +file: String, beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  with_term_result(parse_term(file, after_equals, scope, depth, 0n), right => after_right => ok_right => parse_brace_equal_right_result(ok_right, after_right, right, file, left, beg, scope, depth))

def brace_equals_branch_2(after_equals: List<&2, Lexer.Token>, left: Ast.SyntaxTerm, +file: String, beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  with_term_result(parse_term(file, after_equals, scope, depth, 0n), ty => after_ty => ok_ty => parse_brace_annot_type_result(ok_ty, after_ty, ty, file, left, beg))

def brace_equals_branch_3(+equals: Lexer.Token, after_left: List<&2, Lexer.Token>, +file: String) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected ==",  span(file, token_beg(equals), token_end(equals))}, after_left), False{})

def brace_equals_run(action: BraceEqualsAction, +equals: Lexer.Token, after_equals: List<&2, Lexer.Token>, after_left: List<&2, Lexer.Token>, left: Ast.SyntaxTerm, +file: String, beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  match action:
    case BraceEqualsActionRow0{}:
      brace_equals_branch_0(after_equals, left, file, beg, scope, depth)
    case BraceEqualsActionRow1{}:
      brace_equals_branch_1(after_equals, left, file, beg, scope, depth)
    case BraceEqualsActionRow2{}:
      brace_equals_branch_2(after_equals, left, file, beg, scope, depth)
    case BraceEqualsActionRow3{}:
      brace_equals_branch_3(equals, after_left, file)

def parse_brace_equals(+equals: Lexer.Token, after_equals: List<&2, Lexer.Token>, after_left: List<&2, Lexer.Token>, left: Ast.SyntaxTerm, +file: String, beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  brace_equals_run(brace_equals_action(equals), equals, after_equals, after_left, left, file, beg, scope, depth)

def parse_brace_left_result(ok_left: Bool, after_left: List<&2, Lexer.Token>, left: Ast.SyntaxTerm, file: String, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_left after_left:
    case True{} +equals <> +after_equals:
      parse_brace_equals(equals, after_equals, after_left, left, file, beg, scope, depth)
    case _ _:
      ((left, after_left), False{})

def parse_brace(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, +end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +first <> after_first:
      match first:
        case Lexer.TokenInfo{ _, "==",  _,  _,  _,  _}:
          match after_first:
            case +close <> tail:
              match close:
                case Lexer.TokenInfo{ _, "}",  _,  _,  _,  _}:
                  ((Ast.TermRefl{ span(file, beg, token_end(close))}, tail), True{})
                case _:
                  ((Ast.TermHole{ "parse-error: expected }",  span(file, token_beg(close), token_end(close))}, after_first), False{})
            case Nil{}:
              ((Ast.TermHole{ "parse-error: expected }",  span(file, end, end)}, after_first), False{})
        case _:
          with_term_result(parse_term(file, tokens, scope, depth, 0n), left => after_left => ok_left => parse_brace_left_result(ok_left, after_left, left, file, beg, scope, depth))
    case Nil{}:
      ((Ast.TermHole{ "parse-error: expected a term or ==}",  span(file, end, end)}, Nil{}), False{})
def inequality_right_branch_0(right: Ast.SyntaxTerm, +file: String, left: Ast.SyntaxTerm, beg: Nat, scope: List<&2, Scope>, +depth: Nat, after_colon: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  with_term_result(parse_term(file, after_colon, scope, depth, 0n), ty => after_ty => ok_ty => parse_inequality_type_result(ok_ty, ty, after_ty, file, left, right, beg, depth))

def inequality_right_branch_1(after_right: List<&2, Lexer.Token>, +file: String, +colon: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{"parse-error: expected :", span(file, token_beg(colon), token_end(colon))}, after_right), False{})

def inequality_right_is_colon(colon: Lexer.Token) -> Bool:
  match colon:
    case Lexer.TokenInfo{ _, ":", _, _, _, _}:
      True{}
    case _:
      False{}

def inequality_right_run(is_colon: Bool, right: Ast.SyntaxTerm, after_right: List<&2, Lexer.Token>, +file: String, left: Ast.SyntaxTerm, beg: Nat, scope: List<&2, Scope>, +depth: Nat, +colon: Lexer.Token, after_colon: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  match is_colon:
    case True{}:
      inequality_right_branch_0(right, file, left, beg, scope, depth, after_colon)
    case False{}:
      inequality_right_branch_1(after_right, file, colon)

def parse_inequality_right_result(ok_right: Bool, right: Ast.SyntaxTerm, after_right: List<&2, Lexer.Token>, +file: String, left: Ast.SyntaxTerm, beg: Nat, scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_right after_right:
    case True{} +colon <> after_colon:
      inequality_right_run(inequality_right_is_colon(colon), right, after_right, file, left, beg, scope, depth, colon, after_colon)
    case _ _:
      ((right, after_right), False{})

def parse_inequality(+file: String, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  with_term_result(parse_term(file, tokens, scope, depth, 0n), right => after_right => ok_right => parse_inequality_right_result(ok_right, right, after_right, file, left, beg, scope, depth))

def parse_rewrite_equation_result(ok_equation: Bool, equation: Ast.SyntaxTerm, after_equation: List<&2, Lexer.Token>, file: String, key: String, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_equation:
    case True{}:
      parse_rewrite_motive(file, equation, key, after_equation, beg, end, scope, depth)
    case False{}:
      ((equation, after_equation), False{})

def parse_rewrite_first_at_name(+first: Ast.SyntaxTerm, after_at: List<&2, Lexer.Token>, after_first: List<&2, Lexer.Token>, +file: String, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match first:
    case Ast.TermVar{key, _, _}:
      with_term_result(parse_term(file, after_at, scope, depth, 0n), equation => after_equation => ok_equation => parse_rewrite_equation_result(ok_equation, equation, after_equation, file, key, beg, end, scope, depth))
    case _:
      ((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first(first), token_end_first(first))}, after_first), False{})

def parse_rewrite_first_at(at: Lexer.Token, after_at: List<&2, Lexer.Token>, first: Ast.SyntaxTerm, after_first: List<&2, Lexer.Token>, file: String, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match at:
    case Lexer.TokenInfo{_, "@", _, _, _, _}:
      parse_rewrite_first_at_name(first, after_at, after_first, file, beg, end, scope, depth)
    case _:
      parse_rewrite_motive(file, first, "", after_first, beg, end, scope, depth)

def parse_rewrite_first_result(ok_first: Bool, first: Ast.SyntaxTerm, after_first: List<&2, Lexer.Token>, file: String, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_first after_first:
    case True{} _:
      match after_first:
        case +at <> +after_at:
          parse_rewrite_first_at(at, after_at, first, after_first, file, beg, end, scope, depth)
        case Nil{}:
          ((first, after_first), False{})
    case False{} _:
      ((first, after_first), False{})

def parse_rewrite(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  with_term_result(parse_term(file, tokens, scope, depth, 0n), first => after_first => ok_first => parse_rewrite_first_result(ok_first, first, after_first, file, beg, end, scope, depth))

def parse_rewrite_motive_result(ok_motive: Bool, +motive: Ast.SyntaxTerm, after_motive: List<&2, Lexer.Token>, +file: String, equation: Ast.SyntaxTerm, key: String, +beg: Nat, scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_motive:
    case True{}:
      inner = { Ast.TermLam{None{}, key, depth + 1n, motive, span(file, beg, token_end_first(motive))} : Ast.SyntaxTerm }
      proof = { Ast.TermLam{None{}, "_", depth, inner, span(file, beg, token_end_first(motive))} : Ast.SyntaxTerm }
      body_tokens = skip_rewrite_semicolon(after_motive)
      with_term_result(parse_term(file, body_tokens, scope, depth, 0n), body => after_body => ok_body => parse_rewrite_body_result(ok_body, body, after_body, equation, proof, file, beg))
    case False{}:
      ((motive, after_motive), False{})

def rewrite_motive_branch_0(+file: String, equation: Ast.SyntaxTerm, +key: String, beg: Nat, +scope: List<&2, Scope>, +depth: Nat, after_colon: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  base_scope = extend_scope("_", depth, scope)
  motive_scope = extend_scope(key, depth + 1n, base_scope)
  with_term_result(parse_term(file, after_colon, motive_scope, depth + 2n, 0n), motive => after_motive => ok_motive => parse_rewrite_motive_result(ok_motive, motive, after_motive, file, equation, key, beg, scope, depth))

def rewrite_motive_branch_1(+file: String, tokens: List<&2, Lexer.Token>, +colon: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected :",  span(file, token_beg(colon), token_end(colon))}, tokens), False{})

def rewrite_motive_is_colon(colon: Lexer.Token) -> Bool:
  match colon:
    case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
      True{}
    case _:
      False{}

def rewrite_motive_run(is_colon: Bool, +file: String, equation: Ast.SyntaxTerm, +key: String, tokens: List<&2, Lexer.Token>, beg: Nat, +scope: List<&2, Scope>, +depth: Nat, +colon: Lexer.Token, after_colon: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  match is_colon:
    case True{}:
      rewrite_motive_branch_0(file, equation, key, beg, scope, depth, after_colon)
    case False{}:
      rewrite_motive_branch_1(file, tokens, colon)

def parse_rewrite_motive(+file: String, equation: Ast.SyntaxTerm, +key: String, tokens: List<&2, Lexer.Token>, beg: Nat, +end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +colon <> after_colon:
      rewrite_motive_run(rewrite_motive_is_colon(colon), file, equation, key, tokens, beg, scope, depth, colon, after_colon)
    case Nil{}:
      ((Ast.TermHole{ "parse-error: expected :",  span(file, end, end)}, Nil{}), False{})

def parse_name_term(+file: String, +key: String, beg: Nat, end: Nat, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
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

def parse_term_args(file: String, tokens: List<&2, Lexer.Token>, +close: String, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.SyntaxTerm>) -> (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +token <> +rest:
      parse_term_args_first(Bool.or(String.eq(token_text(token), close), Bool.and(String.eq(close, ">"), String.eq(token_text(token), "<>"))), file, token, rest, tokens, close, scope, depth, acc)
    case Nil{}:
      ((List.reverse(&2, Ast.SyntaxTerm, acc), Nil{}), False{})

def parse_term_args_first_result(ok: Bool, term: Ast.SyntaxTerm, after: List<&2, Lexer.Token>, file: String, tokens: List<&2, Lexer.Token>, +close: String, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.SyntaxTerm>) -> (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool:
  match ok after:
    case True{} +separator <> +tail:
      match separator:
        case Lexer.TokenInfo{ _, ",",  _,  _,  _,  _}:
          parse_term_args(file, tail, close, scope, depth, term <> acc)
        case _:
          parse_term_args_after_separator(String.eq(token_text(separator), close), file, term, after, tail, close, scope, depth, acc)
    case _ _:
      ((List.reverse(&2, Ast.SyntaxTerm, acc), tokens), False{})

def parse_term_args_first(is_close: Bool, +file: String, token: Lexer.Token, rest: List<&2, Lexer.Token>, +tokens: List<&2, Lexer.Token>, close: String, +scope: List<&2, Scope>, +depth: Nat, acc: List<&2, Ast.SyntaxTerm>) -> (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool:
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
def parse_all(file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, beg: Nat, quantity: Ast.Quantity) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +prefix <> rest:
      match prefix:
        case Lexer.TokenInfo{ _, "+",  _,  _,  _,  _}:
          parse_all_named(file, rest, scope, depth, beg, Ast.QMany{})
        case Lexer.TokenInfo{ _, "-",  _,  _,  _,  _}:
          parse_all_named(file, rest, scope, depth, beg, Ast.QZero{})
        case _:
          parse_all_named(file, tokens, scope, depth, beg, quantity)
    case Nil{}:
      parse_all_named(file, Nil{}, scope, depth, beg, quantity)

def all_named_type_branch_0(ty: Ast.SyntaxTerm, +file: String, +key: String, key_end: Nat, beg: Nat, quantity: Ast.Quantity, scope: List<&2, Scope>, +depth: Nat, after_arrow: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  idx = depth
  next_scope = extend_scope(key, depth, scope)
  with_term_result(parse_term(file, after_arrow, next_scope, depth + 1n, 0n), body => after_body => ok_body => parse_all_named_body_result(ok_body, body, after_body, file, key, key_end, beg, quantity, ty, idx))

def all_named_type_branch_1(after_ty: List<&2, Lexer.Token>, +file: String, +arrow: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected ->", span(file, token_beg(arrow), token_end(arrow))}, after_ty), False{})

def all_named_type_is_colon(arrow: Lexer.Token) -> Bool:
  match arrow:
    case Lexer.TokenInfo{ _, "->", _, _, _, _}:
      True{}
    case _:
      False{}

def all_named_type_run(is_colon: Bool, ty: Ast.SyntaxTerm, after_ty: List<&2, Lexer.Token>, +file: String, +key: String, key_end: Nat, beg: Nat, quantity: Ast.Quantity, scope: List<&2, Scope>, +depth: Nat, +arrow: Lexer.Token, after_arrow: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  match is_colon:
    case True{}:
      all_named_type_branch_0(ty, file, key, key_end, beg, quantity, scope, depth, after_arrow)
    case False{}:
      all_named_type_branch_1(after_ty, file, arrow)

def parse_all_named_type_result(ok_ty: Bool, ty: Ast.SyntaxTerm, after_ty: List<&2, Lexer.Token>, +file: String, +key: String, key_end: Nat, beg: Nat, quantity: Ast.Quantity, scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_ty after_ty:
    case True{} +arrow <> after_arrow:
      all_named_type_run(all_named_type_is_colon(arrow), ty, after_ty, file, key, key_end, beg, quantity, scope, depth, arrow, after_arrow)
    case _ _:
      ((ty, after_ty), False{})

def parse_all_named(+file: String, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +beg: Nat, quantity: Ast.Quantity) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +name <> rest:
      match name:
        case Lexer.TokenInfo{ Lexer.NameToken{},  key,  _,  key_end,  _,  _}:
          match rest:
            case +colon <> after_colon:
              match colon:
                case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
                  with_term_result(parse_term(file, after_colon, scope, depth, 1n), ty => after_ty => ok_ty => parse_all_named_type_result(ok_ty, ty, after_ty, file, key, key_end, beg, quantity, scope, depth))
                case _:
                  ((Ast.TermHole{ "parse-error: expected :",  span(file, token_beg(colon), token_end(colon))}, rest), False{})
            case Nil{}:
              ((Ast.TermHole{ "parse-error: expected :",  span(file, beg, key_end)}, rest), False{})
        case _:
          ((Ast.TermHole{ "parse-error: expected a binder",  span(file, beg, token_end(name))}, tokens), False{})
    case Nil{}:
      ((Ast.TermHole{ "parse-error: expected a binder",  span(file, beg, beg)}, Nil{}), False{})

def parse_many_lambda(+file: String, tokens: List<&2, Lexer.Token>, +beg: Nat, scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +name <> rest:
      match name:
        case Lexer.TokenInfo{ Lexer.NameToken{},  key,  name_beg, end,  _,  _}:
          match rest:
            case +arrow <> after_arrow:
              match arrow:
                case Lexer.TokenInfo{ _, "=>",  _,  _,  _,  _}:
                  next_scope = extend_scope(key, depth, scope)
                  with_term_result(parse_term(file, after_arrow, next_scope, depth + 1n, 0n), body => after_body => ok_body => parse_many_lambda_body_result(ok_body, body, after_body, file, key, beg, end, depth))
                case _:
                  parse_plus_sugar(file, key, beg, name_beg, end, rest, scope, depth)
            case Nil{}:
              parse_plus_sugar(file, key, beg, name_beg, end, rest, scope, depth)
        case _:
          ((Ast.TermHole{ "parse-error: expected a binder after +",  span(file, token_beg(name), token_end(name))}, tokens), False{})
    case Nil{}:
      ((Ast.TermHole{ "parse-error: expected a binder after +",  span(file, beg, beg)}, Nil{}), False{})
def parse_plus_sugar_named(found: Maybe<&2, String>, file: String, +head: Ast.SyntaxTerm, beg: Nat, after_head: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match found:
    case Some{ _}:
      parse_plus_sugar_args(file, head, beg, after_head, scope, depth)
    case None{}:
      ((Ast.TermHole{ "parse-error: expected a simple datatype name after +",  span(file, token_beg_first(head), token_end_first(head))}, after_head), False{})

def parse_plus_sugar_head_result(ok_head: Bool, +head: Ast.SyntaxTerm, after_head: List<&2, Lexer.Token>, file: String, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_head:
    case True{}:
      parse_plus_sugar_named(term_name(head), file, head, beg, after_head, scope, depth)
    case False{}:
      ((head, after_head), False{})

def parse_plus_sugar(+file: String, key: String, beg: Nat, name_beg: Nat, name_end: Nat, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  with_term_result(parse_name_term(file, key, name_beg, name_end, tokens, scope, depth), head => after_head => ok_head => parse_plus_sugar_head_result(ok_head, head, after_head, file, beg, scope, depth))

def parse_plus_sugar_args(file: String, +head: Ast.SyntaxTerm, beg: Nat, after_head: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match after_head:
    case +open <> +rest:
      match open:
        case Lexer.TokenInfo{ _, "<",  _,  _,  _,  _}:
          parse_plus_args_spaced(Nat.is_lt(token_end_first(head), token_beg(open)), file, head, beg, open, rest, after_head, scope, depth)
        case _:
          ((Ast.TermPlus{head,  Nil{},  span(file, beg, token_end_first(head))}, after_head), True{})
    case Nil{}:
      ((Ast.TermPlus{head,  Nil{},  span(file, beg, token_end_first(head))}, after_head), True{})

def parse_plus_args_spaced(is_spaced: Bool, +file: String, +head: Ast.SyntaxTerm, beg: Nat, open: Lexer.Token, rest: List<&2, Lexer.Token>, after_head: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_spaced:
    case True{}:
      ((Ast.TermPlus{head,  Nil{},  span(file, beg, token_end_first(head))}, after_head), True{})
    case False{}:
      with_args_result(parse_term_args(file, rest, ">", scope, depth, Nil{}), args => after_args => ok_args => parse_plus_args_result(ok_args, args, after_args, file, head, beg, open))

def parse_term_atom_result(ok: Bool, left: Ast.SyntaxTerm, rest: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, level: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok:
    case True{}:
      parse_term_tail(file, left, rest, scope, depth, level)
    case False{}:
      ((left, rest), False{})

def parse_term(+file: String, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, level: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  with_term_result(parse_atom(file, tokens, scope, depth), left => rest => ok => parse_term_atom_result(ok, left, rest, file, scope, depth, level))

def parse_empty_generic_follow(is_empty: Bool, file: String, +left: Ast.SyntaxTerm, rest: List<&2, Lexer.Token>, all_tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_empty:
    case True{}:
      parse_empty_generic_name(term_name(left), file, left, rest, all_tokens, scope, depth, level, end)
    case False{}:
      parse_operator_right(file, "Con", 5n, left, rest, scope, depth, level, end, True{})

def parse_empty_generic_name(found: Maybe<&2, String>, +file: String, +left: Ast.SyntaxTerm, rest: List<&2, Lexer.Token>, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match found:
    case Some{ _}:
      fill = { Ast.TermFill{ left,  Nil{},  span(file, token_beg_first(left), end)} : Ast.SyntaxTerm }
      parse_term_tail(file, fill, rest, scope, depth, level)
    case None{}:
      parse_operator_right(file, "Con", 5n, left, rest, scope, depth, level, end, True{})

def parse_glued_operator(is_glued: Bool, file: String, key: String, priority: Nat, left: Ast.SyntaxTerm, remaining: List<&2, Lexer.Token>, all_tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_glued:
    case True{}:
      ((left, all_tokens), True{})
    case False{}:
      parse_operator(file, key, priority, left, remaining, scope, depth, level, end)

def parse_spaced_operator(is_spaced: Bool, file: String, left: Ast.SyntaxTerm, remaining: List<&2, Lexer.Token>, all_tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_spaced:
    case True{}:
      parse_operator(file, ".mod", 11n, left, remaining, scope, depth, level, end)
    case False{}:
      ((left, all_tokens), True{})
def parse_comparison_operator(is_spaced: Bool, file: String, key: String, priority: Nat, left: Ast.SyntaxTerm, remaining: List<&2, Lexer.Token>, all_tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_spaced:
    case True{}:
      parse_operator(file, key, priority, left, remaining, scope, depth, level, end)
    case False{}:
      ((left, all_tokens), True{})


def parse_application_applied_result(ok_apply: Bool, applied: Ast.SyntaxTerm, after_args: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, level: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_apply:
    case True{}:
      parse_term_tail(file, applied, after_args, scope, depth, level)
    case False{}:
      ((applied, after_args), False{})

def parse_application_args_result(ok_args: Bool, args: List<&2, Ast.SyntaxTerm>, after_args: List<&2, Lexer.Token>, +file: String, +head: Ast.SyntaxTerm, failure: Ast.SyntaxTerm, scope: List<&2, Scope>, depth: Nat, level: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_args:
    case True{}:
      with_term_bool(apply_terms(args, file, head, token_beg_first(head)), applied => ok_apply => parse_application_applied_result(ok_apply, applied, after_args, file, scope, depth, level))
    case False{}:
      ((failure, after_args), False{})

def parse_bang_call(is_adjacent: Bool, +file: String, left: Ast.SyntaxTerm, +open: Lexer.Token, after_open: List<&2, Lexer.Token>, rest: List<&2, Lexer.Token>, original: List<&2, Lexer.Token>, next: Lexer.Token, +scope: List<&2, Scope>, +depth: Nat, level: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_adjacent:
    case True{}:
      match left:
        case Ast.TermRef{ +_,  +_}:
          bang = { Ast.TermBang{ left,  span(file, token_beg_first(left), token_end(next))} : Ast.SyntaxTerm }
          with_args_result(parse_term_args(file, after_open, ")", scope, depth, Nil{}), args => after_args => ok_args => parse_application_args_result(ok_args, args, after_args, file, bang, Ast.TermHole{"parse-error: expected bang-call arguments", span(file, token_beg(open), token_end(open))}, scope, depth, level))
        case _:
          ((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first(left), token_end(next))}, rest), False{})
    case False{}:
      ((left, original), True{})

def parse_term_arrow_result(ok: Bool, right: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, +file: String, +left: Ast.SyntaxTerm, scope: List<&2, Scope>, +depth: Nat, level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok:
    case True{}:
      parse_term_tail(file, Ast.TermAll{Ast.QOne{}, "_", depth, left, right, span(file, token_beg_first(left), token_end_of(after, end))}, after, scope, depth + 1n, level)
    case False{}:
      ((right, after), False{})

def parse_term_tail(+file: String, +left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, level: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +next <> +rest:
      match next:
        case Lexer.TokenInfo{ Lexer.NewlineToken{},  _,  _,  _,  _,  _}:
          ((left, rest), True{})
        case Lexer.TokenInfo{ Lexer.SymbolToken{}, text, beg, end,  _,  _}:
          match text:
            case "->":
              match level:
                case 0n:
                  with_term_result(parse_term(file, rest, scope, depth, 0n), right => after => ok => parse_term_arrow_result(ok, right, after, file, left, scope, depth, level, end))
                case _:
                  ((left, tokens), True{})
            case "<":
              parse_less_or_adt(file, left, rest, tokens, beg, scope, depth, level, end)
            case "<&>":
              parse_min_operator(file, left, rest, scope, depth, level, end)
            case "<>":
              parse_empty_generic_follow(empty_generic_follow(rest), file, left, rest, tokens, scope, depth, level, end)
            case "++":
              parse_operator_right(file, "String.append", 5n, left, rest, scope, depth, level, end, True{})
            case "||":
              parse_operator(file, "Bool.or", 2n, left, rest, scope, depth, level, end)
            case "&&":
              parse_operator(file, "Bool.and", 3n, left, rest, scope, depth, level, end)
            case "<=":
              parse_comparison_operator(Nat.is_lt(token_end_first(left), beg), file, ".is_le", 4n, left, rest, tokens, scope, depth, level, end)
            case ">=":
              parse_comparison_operator(Nat.is_lt(token_end_first(left), beg), file, ".is_ge", 4n, left, rest, tokens, scope, depth, level, end)
            case ">":
              parse_comparison_operator(Nat.is_lt(token_end_first(left), beg), file, ".is_gt", 4n, left, rest, tokens, scope, depth, level, end)
            case ".|.":
              parse_operator(file, ".or", 6n, left, rest, scope, depth, level, end)
            case ".^.":
              parse_operator(file, ".xor", 7n, left, rest, scope, depth, level, end)
            case ".&.":
              parse_operator(file, ".and", 8n, left, rest, scope, depth, level, end)
            case "<<":
              parse_operator(file, ".shln", 9n, left, rest, scope, depth, level, end)
            case ">>":
              parse_comparison_operator(Nat.is_lt(token_end_first(left), beg), file, ".shrn", 9n, left, rest, tokens, scope, depth, level, end)
            case "+":
              parse_glued_operator(operator_glued_name(end, rest), file, ".add", 10n, left, rest, tokens, scope, depth, level, end)
            case "&":
              parse_pair_operator(file, left, rest, scope, depth, level, end, True{})
            case "|":
              parse_pair_operator(file, left, rest, scope, depth, level, end, False{})
            case "-":
              parse_glued_operator(operator_glued_name(end, rest), file, ".sub", 10n, left, rest, tokens, scope, depth, level, end)
            case "*":
              parse_operator(file, ".mul", 11n, left, rest, scope, depth, level, end)
            case "/":
              parse_operator(file, ".div", 11n, left, rest, scope, depth, level, end)
            case "%":
              parse_spaced_operator(has_space_after(end, rest), file, left, rest, tokens, scope, depth, level, end)
            case "!":
              match rest:
                case +open <> after_open:
                  match open:
                    case Lexer.TokenInfo{ _, "(",  _,  _,  _,  _}:
                      parse_bang_call(Nat.is_eq(end, token_beg(open)), file, left, open, after_open, rest, tokens, next, scope, depth, level)
                    case _:
                      ((left, tokens), True{})
                case Nil{}:
                  ((left, tokens), True{})
            case "(":
              with_args_result(parse_term_args(file, rest, ")", scope, depth, Nil{}), args => after_args => ok_args => parse_application_args_result(ok_args, args, after_args, file, left, Ast.TermHole{"parse-error: expected application arguments", span(file, token_end(next), token_end(next))}, scope, depth, level))
            case "[":
              parse_index_tail(file, left, rest, scope, depth, level, token_beg_first(left), end)
            case _:
              ((left, tokens), True{})
        case Lexer.TokenInfo{ Lexer.NameToken{},  _,  _,  _,  _,  _}:
          ((left, tokens), True{})
        case _:
          ((left, tokens), True{})
    case Nil{}:
      ((left, tokens), True{})
def parse_less_or_adt(file: String, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, all_tokens: List<&2, Lexer.Token>, open_beg: Nat, scope: List<&2, Scope>, depth: Nat, +level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_less_or_adt_precedence(Nat.is_lt(4n, level), file, left, tokens, all_tokens, open_beg, scope, depth, level, end)

def parse_less_or_adt_precedence(is_nested: Bool, file: String, +left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, all_tokens: List<&2, Lexer.Token>, +open_beg: Nat, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_nested:
    case True{}:
      parse_less_or_adt_nested(Nat.is_lt(token_end_first(left), open_beg), file, left, tokens, all_tokens, open_beg, scope, depth, level, end)
    case False{}:
      parse_less_or_adt_args(file, left, tokens, all_tokens, scope, depth, level, end)

def parse_less_or_adt_nested(is_spaced: Bool, file: String, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, all_tokens: List<&2, Lexer.Token>, open_beg: Nat, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_spaced:
    case True{}:
      ((left, all_tokens), True{})
    case False{}:
      parse_less_or_adt_args(file, left, tokens, all_tokens, scope, depth, level, end)

def parse_less_named(found: Maybe<&2, String>, wants_many: Bool, +file: String, +left: Ast.SyntaxTerm, right: Ast.SyntaxTerm, separator: Lexer.Token, after_separator: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match found:
    case Some{ _}:
      match wants_many:
        case True{}:
          with_args_result(parse_term_args(file, after_separator, ">", scope, depth, [right]), args => after_args => ok_args => parse_less_many_result(ok_args, args, after_args, file, left, separator, end, scope, depth, level))
        case False{}:
          fill = { Ast.TermFill{ left,  [right],  span(file, token_beg_first(left), token_end(separator))} : Ast.SyntaxTerm }
          parse_term_tail(file, fill, after_separator, scope, depth, level)
    case None{}:
      ((Ast.TermHole{ "parse-error: expected a family name before type arguments",  span(file, token_beg_first(left), token_end(separator))}, after_separator), False{})

def parse_less_many_result(ok_args: Bool, args: List<&2, Ast.SyntaxTerm>, +after_args: List<&2, Lexer.Token>, +file: String, +left: Ast.SyntaxTerm, +separator: Lexer.Token, end: Nat, scope: List<&2, Scope>, depth: Nat, level: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_args:
    case True{}:
      fill = { Ast.TermFill{ left, args,  span(file, token_beg_first(left), token_end_of(after_args, end))} : Ast.SyntaxTerm }
      parse_term_tail(file, fill, after_args, scope, depth, level)
    case False{}:
      ((Ast.TermHole{ "parse-error: expected datatype arguments",  span(file, token_beg(separator), token_end(separator))}, after_args), False{})

def parse_less_operator_or_nested(is_nested: Bool, file: String, left: Ast.SyntaxTerm, right: Ast.SyntaxTerm, after_right: List<&2, Lexer.Token>, all_tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_nested:
    case True{}:
      ((left, all_tokens), True{})
    case False{}:
      operator_call(file, ".is_lt", left, right, after_right, scope, depth, level, end)

def parse_less_or_adt_args(+file: String, left: Ast.SyntaxTerm, +tokens: List<&2, Lexer.Token>, all_tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  with_term_result(parse_term(file, tokens, scope, depth, 5n), right => after_right => ok_right => parse_less_right(ok_right, after_right, right, file, left, tokens, all_tokens, scope, depth, level, end))

def parse_less_right(ok_right: Bool, after_right: List<&2, Lexer.Token>, right: Ast.SyntaxTerm, file: String, +left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, all_tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, +level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_right after_right:
    case True{} +separator <> after_separator:
      match separator:
        case Lexer.TokenInfo{ _, ">",  _,  _,  _,  _}:
          parse_less_named(term_name(left), False{}, file, left, right, separator, after_separator, scope, depth, level, end)
        case Lexer.TokenInfo{ _, ",",  _,  _,  _,  _}:
          parse_less_named(term_name(left), True{}, file, left, right, separator, after_separator, scope, depth, level, end)
        case _:
          parse_less_operator_or_nested(Nat.is_lt(4n, level), file, left, right, after_right, all_tokens, scope, depth, level, end)
    case _ _:
      ((right, after_right), False{})

def operator_call(+file: String, key: String, +left: Ast.SyntaxTerm, right: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  +operator_span = span(file, token_beg_first(left), token_end_of(after, end))
  operator = { Ast.TermRef{key,  operator_span} : Ast.SyntaxTerm }
  first = { Ast.TermApp{ operator,  left,  operator_span} : Ast.SyntaxTerm }
  combined = { Ast.TermApp{ first,  right,  operator_span} : Ast.SyntaxTerm }
  parse_term_tail(file, combined, after, scope, depth, level)

def parse_operator_right(file: String, key: String, +priority: Nat, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, +level: Nat, end: Nat, right_assoc: Bool) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_operator_right_precedence(Nat.is_lt(priority, level), file, key, priority, left, tokens, scope, depth, level, end, right_assoc)

def parse_operator_right_named(key: String, right: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, +file: String, +left: Ast.SyntaxTerm, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match key:
    case "Con":
      constructor = { Ast.TermCtr{ "Con", [left, right], span(file, token_beg_first(left), token_end_of(after, end))} : Ast.SyntaxTerm }
      parse_term_tail(file, constructor, after, scope, depth, level)
    case _:
      operator_call(file, key, left, right, after, scope, depth, level, end)

def parse_operator_right_result(ok: Bool, right: Ast.SyntaxTerm, after: List<&2, Lexer.Token>, file: String, key: String, left: Ast.SyntaxTerm, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok:
    case True{}:
      parse_operator_right_named(key, right, after, file, left, scope, depth, level, end)
    case False{}:
      ((right, after), False{})

def parse_operator_right_precedence(is_nested: Bool, +file: String, key: String, priority: Nat, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, level: Nat, end: Nat, right_assoc: Bool) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_nested:
    case True{}:
      ((left, tokens), True{})
    case False{}:
      rhs_level = operator_rhs_level(right_assoc, priority)
      with_term_result(parse_term(file, tokens, scope, depth, rhs_level), right => after => ok => parse_operator_right_result(ok, right, after, file, key, left, scope, depth, level, end))

def parse_min_operator(file: String, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, +level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_min_precedence(Nat.is_lt(5n, level), file, left, tokens, scope, depth, level, end)

def parse_min_precedence_result(ok: Bool, right: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, +file: String, +left: Ast.SyntaxTerm, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok:
    case True{}:
      term = { Ast.TermMin{left, right, span(file, token_beg_first(left), token_end_of(after, end))} : Ast.SyntaxTerm }
      parse_term_tail(file, term, after, scope, depth, level)
    case False{}:
      ((right, after), False{})

def parse_min_precedence(is_nested: Bool, +file: String, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_nested:
    case True{}:
      ((left, tokens), True{})
    case False{}:
      with_term_result(parse_term(file, tokens, scope, depth, 5n), right => after => ok => parse_min_precedence_result(ok, right, after, file, left, scope, depth, level, end))

def parse_pair_quantity(left_is_quantity: Bool, right_is_quantity: Bool, +file: String, +left: Ast.SyntaxTerm, right: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match left_is_quantity right_is_quantity:
    case True{} True{}:
      parse_term_tail(file, Ast.TermMin{left, right,  span(file, token_beg_first(left), token_end_of(after, end))}, after, scope, depth, level)
    case _ _:
      pair_application(file, "Pair", left, right, after, scope, depth, level, end)
def parse_pair_operator_result(ok: Bool, +right: Ast.SyntaxTerm, after: List<&2, Lexer.Token>, amp: Bool, file: String, +left: Ast.SyntaxTerm, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat, tokens: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok:
    case True{}:
      match amp:
        case True{}:
          parse_pair_quantity(is_quantity_term(left), is_quantity_term(right), file, left, right, after, scope, depth, level, end)
        case False{}:
          pair_application(file, "Or", left, right, after, scope, depth, level, end)
    case False{}:
      ((right, after), False{})

def parse_pair_operator(+file: String, left: Ast.SyntaxTerm, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, level: Nat, end: Nat, amp: Bool) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match level:
    case 0n:
      with_term_result(parse_term(file, tokens, scope, depth, 1n), right => after => ok => parse_pair_operator_result(ok, right, after, amp, file, left, scope, depth, level, end, tokens))
    case _:
      ((left, tokens), True{})

def pair_application_result(ok: Bool, term: Ast.SyntaxTerm, after: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, level: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok:
    case True{}:
      parse_term_tail(file, term, after, scope, depth, level)
    case False{}:
      ((term, after), False{})

def pair_application(+file: String, key: String, +left: Ast.SyntaxTerm, right: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  span_value = span(file, token_beg_first(left), token_end_of(after, end))
  with_term_bool(apply_terms([left, right], file, Ast.TermRef{key, span_value}, token_beg_first(left)), term => ok => pair_application_result(ok, term, after, file, scope, depth, level))

def parse_array_set_call_result(call_ok: Bool, call: Ast.SyntaxTerm, after_value: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, level: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match call_ok:
    case True{}:
      parse_term_tail(file, call, after_value, scope, depth, level)
    case False{}:
      ((call, after_value), False{})

def parse_array_set_value_result(ok_value: Bool, +value: Ast.SyntaxTerm, after_value: List<&2, Lexer.Token>, +file: String, left: Ast.SyntaxTerm, typed_index: Ast.SyntaxTerm, +beg: Nat, open_end: Nat, scope: List<&2, Scope>, depth: Nat, level: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_value:
    case True{}:
      with_term_bool(apply_terms([Ast.TermRef{"U32", span(file, beg, open_end)}, left, typed_index, value], file, Ast.TermRef{"Array.set", span(file, beg, token_end_first(value))}, beg), call => call_ok => parse_array_set_call_result(call_ok, call, after_value, file, scope, depth, level))
    case False{}:
      ((value, after_value), False{})

def parse_index_set_token(set_token: Lexer.Token, after_set: List<&2, Lexer.Token>, after_close: List<&2, Lexer.Token>, +file: String, left: Ast.SyntaxTerm, typed_index: Ast.SyntaxTerm, beg: Nat, open_end: Nat, +scope: List<&2, Scope>, +depth: Nat, level: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match set_token:
    case Lexer.TokenInfo{_, "<-", _, _, _, _}:
      with_term_result(parse_term(file, after_set, scope, depth, 0n), value => after_value => ok_value => parse_array_set_value_result(ok_value, value, after_value, file, left, typed_index, beg, open_end, scope, depth, level))
    case _:
      parse_array_get(file, left, typed_index, after_close, scope, depth, level, beg, open_end)

def parse_index_after_close(after_close: List<&2, Lexer.Token>, file: String, left: Ast.SyntaxTerm, typed_index: Ast.SyntaxTerm, beg: Nat, open_end: Nat, scope: List<&2, Scope>, depth: Nat, level: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match after_close:
    case +set_token <> +after_set:
      parse_index_set_token(set_token, after_set, after_close, file, left, typed_index, beg, open_end, scope, depth, level)
    case Nil{}:
      parse_array_get(file, left, typed_index, Nil{}, scope, depth, level, beg, open_end)

def index_result_branch_0(index: Ast.SyntaxTerm, file: String, left: Ast.SyntaxTerm, scope: List<&2, Scope>, depth: Nat, level: Nat, beg: Nat, open_end: Nat, after_close: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  parse_index_after_close(after_close, file, left, map_operator_term(index, "U32"), beg, open_end, scope, depth, level)

def index_result_branch_1(after_index: List<&2, Lexer.Token>, file: String, +close: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{"parse-error: expected ]", span(file, token_beg(close), token_end(close))}, after_index), False{})

def index_result_is_colon(close: Lexer.Token) -> Bool:
  match close:
    case Lexer.TokenInfo{_, "]", _, _, _, _}:
      True{}
    case _:
      False{}

def index_result_run(is_colon: Bool, after_index: List<&2, Lexer.Token>, index: Ast.SyntaxTerm, file: String, left: Ast.SyntaxTerm, scope: List<&2, Scope>, depth: Nat, level: Nat, beg: Nat, open_end: Nat, +close: Lexer.Token, after_close: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  match is_colon:
    case True{}:
      index_result_branch_0(index, file, left, scope, depth, level, beg, open_end, after_close)
    case False{}:
      index_result_branch_1(after_index, file, close)

def parse_index_result(ok_index: Bool, after_index: List<&2, Lexer.Token>, index: Ast.SyntaxTerm, file: String, left: Ast.SyntaxTerm, scope: List<&2, Scope>, depth: Nat, level: Nat, beg: Nat, open_end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_index after_index:
    case True{} +close <> after_close:
      index_result_run(index_result_is_colon(close), after_index, index, file, left, scope, depth, level, beg, open_end, close, after_close)
    case _ _:
      ((index, after_index), False{})

def parse_index_tail(+file: String, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, level: Nat, beg: Nat, open_end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  with_term_result(parse_term(file, tokens, scope, depth, 0n), index => after_index => ok_index => parse_index_result(ok_index, after_index, index, file, left, scope, depth, level, beg, open_end))

def parse_array_get_result(ok: Bool, call: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, level: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok:
    case True{}:
      parse_term_tail(file, call, tokens, scope, depth, level)
    case False{}:
      ((call, tokens), False{})

def parse_array_get(+file: String, left: Ast.SyntaxTerm, index: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat, +beg: Nat, +end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  with_term_bool(apply_terms([Ast.TermRef{"U32", span(file, beg, end)}, left, index], file, Ast.TermRef{"Array.get", span(file, beg, end)}, beg), call => ok => parse_array_get_result(ok, call, tokens, file, scope, depth, level))

def parse_operator(file: String, name: String, +priority: Nat, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, +level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_operator_precedence(Nat.is_lt(priority, level), file, name, priority, left, tokens, scope, depth, level, end)

def parse_operator_precedence_result(ok: Bool, right: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, +file: String, name: String, +left: Ast.SyntaxTerm, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok:
    case True{}:
      +operator_span = span(file, token_beg_first(left), token_end_of(after, end))
      operator = { Ast.TermRef{name, operator_span} : Ast.SyntaxTerm }
      first = { Ast.TermApp{operator, left, operator_span} : Ast.SyntaxTerm }
      combined = { Ast.TermApp{first, right, operator_span} : Ast.SyntaxTerm }
      parse_term_tail(file, combined, after, scope, depth, level)
    case False{}:
      ((right, after), False{})

def parse_operator_precedence(is_nested: Bool, +file: String, name: String, priority: Nat, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, level: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_nested:
    case True{}:
      ((left, tokens), True{})
    case False{}:
      with_term_result(parse_term(file, tokens, scope, depth, priority + 1n), right => after => ok => parse_operator_precedence_result(ok, right, after, file, name, left, scope, depth, level, end))
def parse_body_next_row_0(file: String, scope: List<&2, Scope>, depth: Nat, parent_col: Nat, key: String, beg: Nat, end: Nat, after_next: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  parse_local_body(file, key, beg, end, parent_col, after_next, scope, depth, Ast.QOne{})

def parse_body_next_row_1(file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, parent_col: Nat, beg: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  parse_destructuring_local(file, tokens, beg, parent_col, scope, depth)

def parse_body_next_row_2(file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, parent_col: Nat, +token: Lexer.Token, +rest: List<&2, Lexer.Token>, key: String, beg: Nat, end: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  decl_local_name_group(local_array_write(rest), True{}, file, tokens, token, rest, key, beg, end, parent_col, scope, depth)

def parse_body_next_row_3(file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, parent_col: Nat, +token: Lexer.Token, +rest: List<&2, Lexer.Token>, key: String, beg: Nat, end: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  decl_local_name_group(local_group_has_equal(rest), False{}, file, tokens, token, rest, key, beg, end, parent_col, scope, depth)

def parse_body_next_dispatch(+next: Lexer.Token, file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, parent_col: Nat, +token: Lexer.Token, +rest: List<&2, Lexer.Token>, key: String, beg: Nat, end: Nat, after_next: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  match next:
    case Lexer.TokenInfo{ _, "=",  _,  _,  _,  _}:
      parse_body_next_row_0(file, scope, depth, parent_col, key, beg, end, after_next)
    case Lexer.TokenInfo{ _, "{",  _,  _,  _,  _}:
      parse_body_next_row_1(file, tokens, scope, depth, parent_col, beg)
    case Lexer.TokenInfo{ _, "[",  _,  _,  _,  _}:
      parse_body_next_row_2(file, tokens, scope, depth, parent_col, token, rest, key, beg, end)
    case _:
      parse_body_next_row_3(file, tokens, scope, depth, parent_col, token, rest, key, beg, end)

def parse_body_token_row_0(file: String, scope: List<&2, Scope>, depth: Nat, +rest: List<&2, Lexer.Token>, beg: Nat, col: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  parse_match_body(file, rest, beg, col, scope, depth)

def parse_body_token_row_1(+rest: List<&2, Lexer.Token>, file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, parent_col: Nat, +token: Lexer.Token, key: String, beg: Nat, end: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  match rest:
    case +next <> after_next:
      parse_body_next_dispatch(next, file, tokens, scope, depth, parent_col, token, rest, key, beg, end, after_next)
    case _:
      parse_reply(file, tokens, scope, depth)

def parse_body_token_row_2(file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, parent_col: Nat, +rest: List<&2, Lexer.Token>, beg: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  decl_parallel_or_reply(local_group_has_equal(rest), file, tokens, rest, beg, parent_col, scope, depth, Ast.QMany{})

def parse_body_token_row_3(file: String, scope: List<&2, Scope>, depth: Nat, parent_col: Nat, +rest: List<&2, Lexer.Token>, beg: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  parse_erased_local(file, rest, beg, parent_col, scope, depth)

def parse_body_token_row_4(file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  parse_reply(file, tokens, scope, depth)

type BodyScanAction is Data:
  BodyScanActionRow0{}
  BodyScanActionRow1{}
  BodyScanActionRow2{}
  BodyScanActionRow3{}
  BodyScanActionRow4{}

def body_scan_action(token: Lexer.Token) -> BodyScanAction:
  match token:
    case Lexer.TokenInfo{ Lexer.NameToken{},  "match", beg,  _,  _, col}:
      BodyScanActionRow0{}
    case Lexer.TokenInfo{ Lexer.NameToken{},  key, beg, end,  _, col}:
      BodyScanActionRow1{}
    case Lexer.TokenInfo{ Lexer.SymbolToken{},  "+", beg,  _,  _, col}:
      BodyScanActionRow2{}
    case Lexer.TokenInfo{ Lexer.SymbolToken{},  "-", beg,  _,  _, col}:
      BodyScanActionRow3{}
    case _:
      BodyScanActionRow4{}

def body_scan_run(+token: Lexer.Token, action: BodyScanAction, file: String, tokens: List<&2, Lexer.Token>, +rest: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, parent_col: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  match token:
    case Lexer.TokenInfo{_, key, beg, end, _, col}:
      match action:
        case BodyScanActionRow0{}:
          parse_body_token_row_0(file, scope, depth, rest, beg, col)
        case BodyScanActionRow1{}:
          parse_body_token_row_1(rest, file, tokens, scope, depth, parent_col, token, key, beg, end)
        case BodyScanActionRow2{}:
          parse_body_token_row_2(file, tokens, scope, depth, parent_col, rest, beg)
        case BodyScanActionRow3{}:
          parse_body_token_row_3(file, scope, depth, parent_col, rest, beg)
        case BodyScanActionRow4{}:
          parse_body_token_row_4(file, tokens, scope, depth)

def parse_body_scan(file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, parent_col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match scanned:
    case +token <> +rest:
      body_scan_run(token, body_scan_action(token), file, tokens, rest, scope, depth, parent_col)
    case Nil{}:
      ((Ast.TermHole{ "parse-error: expected a body",  span(file, 0n, 0n)}, Nil{}), False{})

def decl_local_name_group(is_array_write: Bool, is_array: Bool, file: String, tokens: List<&2, Lexer.Token>, token: Lexer.Token, rest: List<&2, Lexer.Token>, key: String, beg: Nat, end: Nat, col: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_array_write:
    case True{}:
      parse_array_write_local(file, key, beg, end, col, token <> rest, scope, depth)
    case False{}:
      decl_parallel_or_reply(is_array, file, tokens, token <> rest, beg, col, scope, depth, Ast.QOne{})

def decl_parallel_or_reply(is_parallel: Bool, file: String, tokens: List<&2, Lexer.Token>, group: List<&2, Lexer.Token>, beg: Nat, col: Nat, scope: List<&2, Scope>, depth: Nat, quantity: Ast.Quantity) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_parallel:
    case True{}:
      parse_parallel_local(file, group, beg, col, scope, depth, quantity)
    case False{}:
      parse_reply(file, tokens, scope, depth)

def parse_body(file: String, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, parent_col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_body_scan(file, tokens, skip_lines(tokens), scope, depth, parent_col)

def parse_reply(+file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  with_term_result(parse_term(file, tokens, scope, depth, 0n), term => after => ok => parse_reply_result(ok, term, after, file))

def parse_erased_local(file: String, tokens: List<&2, Lexer.Token>, beg: Nat, col: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +name <> +rest:
      match name:
        case Lexer.TokenInfo{ Lexer.NameToken{},  key,  key_beg, end,  _,  _}:
          match rest:
            case +equals <> +after_equals:
              match equals:
                case Lexer.TokenInfo{ _, "=",  _,  _,  _,  _}:
                  parse_local_body(file, key, beg, end, col, after_equals, scope, depth, Ast.QZero{})
                case _:
                  decl_parallel_or_reply(local_group_has_equal(name <> rest), file, tokens, name <> rest, beg, col, scope, depth, Ast.QZero{})
            case _:
              decl_parallel_or_reply(local_group_has_equal(name <> rest), file, tokens, name <> rest, beg, col, scope, depth, Ast.QZero{})
        case _:
          parse_reply(file, tokens, scope, depth)
    case Nil{}:
      parse_reply(file, Nil{}, scope, depth)
def parse_local_values_same_line(is_same_line: Bool, file: String, value: Ast.SyntaxTerm, after_value: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, line: Nat, acc: List<&2, Ast.SyntaxTerm>) -> ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Nat) & Bool:
  match is_same_line:
    case True{}:
      parse_local_values(file, after_value, scope, depth, line, value <> acc)
    case False{}:
      (((List.reverse(&2, Ast.SyntaxTerm, value <> acc), after_value), line), True{})

def parse_local_values_next(+next: Lexer.Token, after_next: List<&2, Lexer.Token>, value: Ast.SyntaxTerm, file: String, scope: List<&2, Scope>, depth: Nat, +line: Nat, acc: List<&2, Ast.SyntaxTerm>) -> ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Nat) & Bool:
  match next:
    case Lexer.TokenInfo{_, ";", +_, +_, +_, +_}:
      (((List.reverse(&2, Ast.SyntaxTerm, value <> acc), next <> after_next), line), True{})
    case _:
      parse_local_values_same_line(Nat.is_eq(token_line(next), line), file, value, next <> after_next, scope, depth, line, acc)

def parse_local_values_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, tokens: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, line: Nat, acc: List<&2, Ast.SyntaxTerm>) -> ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Nat) & Bool:
  match result:
    case ((value, +next <> after_next), True{}):
      parse_local_values_next(next, after_next, value, file, scope, depth, line, acc)
    case ((value, Nil{}), True{}):
      (((List.reverse(&2, Ast.SyntaxTerm, value <> acc), []), line), True{})
    case (_, False{}):
      (((List.reverse(&2, Ast.SyntaxTerm, acc), tokens), line), False{})

def parse_local_values(+file: String, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, line: Nat, acc: List<&2, Ast.SyntaxTerm>) -> ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Nat) & Bool:
  parse_local_values_result(parse_term(file, tokens, scope, depth, 0n), tokens, file, scope, depth, line, acc)

def parse_parallel_local(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat, +quantity: Ast.Quantity) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  with_local_binders_result(parse_local_binders(file, tokens, scope, depth, quantity, Nil{}), patterns => after_equals => next_scope => next_depth => ok_patterns => parse_parallel_binders_result(ok_patterns, patterns, after_equals, next_scope, next_depth, file, beg, col, scope, depth, quantity))

def parse_parallel_binders_result(ok_patterns: Bool, patterns: List<&2, Ast.SyntaxPattern>, +after_equals: List<&2, Lexer.Token>, next_scope: List<&2, Scope>, next_depth: Nat, +file: String, +beg: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat, quantity: Ast.Quantity) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_patterns:
    case True{}:
      with_local_values_result(parse_local_values(file, after_equals, scope, depth, first_line(after_equals), Nil{}), values => after_values => rhs_line => ok_values => parse_parallel_values_result(ok_values, values, after_values, rhs_line, patterns, after_equals, next_scope, next_depth, file, beg, col, scope, depth, quantity))
    case False{}:
      ((Ast.TermHole{ "parse-error: expected parallel binders",  span(file, beg, token_end_of(after_equals, beg))}, after_equals), False{})

def parse_parallel_values_result(ok_values: Bool, +values: List<&2, Ast.SyntaxTerm>, after_values: List<&2, Lexer.Token>, rhs_line: Nat, +patterns: List<&2, Ast.SyntaxPattern>, after_equals: List<&2, Lexer.Token>, next_scope: List<&2, Scope>, next_depth: Nat, file: String, +beg: Nat, col: Nat, scope: List<&2, Scope>, depth: Nat, quantity: Ast.Quantity) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_values:
    case True{}:
      parse_parallel_counts_result(local_counts_match(patterns, values), values, after_values, rhs_line, patterns, after_equals, next_scope, next_depth, file, beg, col, scope, depth, quantity)
    case False{}:
      ((Ast.TermHole{ "parse-error: expected parallel-let values",  span(file, beg, beg)}, after_values), False{})

def parse_parallel_counts_result(counts_match: Bool, values: List<&2, Ast.SyntaxTerm>, +after_values: List<&2, Lexer.Token>, rhs_line: Nat, patterns: List<&2, Ast.SyntaxPattern>, after_equals: List<&2, Lexer.Token>, next_scope: List<&2, Scope>, next_depth: Nat, file: String, +beg: Nat, +col: Nat, scope: List<&2, Scope>, depth: Nat, quantity: Ast.Quantity) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match counts_match:
    case True{}:
      parse_parallel_body_ready(local_group_body_ready(after_values, col, rhs_line), values, after_values, patterns, next_scope, next_depth, quantity, file, beg, col)
    case False{}:
      ((Ast.TermHole{ "parse-error: parallel let needs one value per binder",  span(file, beg, token_end_of(after_equals, beg))}, after_values), False{})

def parse_parallel_body_ready(is_ready: Bool, values: List<&2, Ast.SyntaxTerm>, +after_values: List<&2, Lexer.Token>, patterns: List<&2, Ast.SyntaxPattern>, next_scope: List<&2, Scope>, next_depth: Nat, quantity: Ast.Quantity, +file: String, +beg: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_ready:
    case True{}:
      with_term_result(parse_body(file, skip_rewrite_semicolon(after_values), next_scope, next_depth, col), body => after_body => ok_body => parse_parallel_parsed_body(ok_body, body, after_body, values, patterns, quantity, file, beg))
    case False{}:
      ((Ast.TermHole{ "parse-error: expected an indented parallel-let body",  span(file, token_end_of(after_values, beg), token_end_of(after_values, beg))}, after_values), False{})

def parse_local_body(+file: String, key: String, beg: Nat, key_end: Nat, col: Nat, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, quantity: Ast.Quantity) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  with_term_result(parse_term(file, tokens, scope, depth, 0n), value => after_value => ok_value => parse_local_body_term_result(ok_value, file, key, beg, key_end, col, value, after_value, scope, depth, quantity))

def parse_local_body_term_result(ok_value: Bool, file: String, key: String, beg: Nat, key_end: Nat, col: Nat, value: Ast.SyntaxTerm, after_value: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, quantity: Ast.Quantity) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_value:
    case True{}:
      parse_local_body_value(file, key, beg, key_end, col, value, after_value, scope, depth, quantity)
    case False{}:
      ((value, after_value), False{})

def parse_local_body_value(+file: String, +key: String, +beg: Nat, key_end: Nat, +col: Nat, value: Ast.SyntaxTerm, +after_value: List<&2, Lexer.Token>, scope: List<&2, Scope>, +depth: Nat, +quantity: Ast.Quantity) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  pattern = { Ast.PatternVar{key,  depth, quantity,  span(file, beg, key_end)} : Ast.SyntaxPattern }
  next_scope = extend_scope(key, depth, scope)
  parse_local_body_ready(local_body_ready(after_value, col), file, key, beg, col, pattern, value, after_value, next_scope, depth, quantity)

def parse_local_body_ready(is_ready: Bool, +file: String, key: String, beg: Nat, col: Nat, pattern: Ast.SyntaxPattern, +value: Ast.SyntaxTerm, after_value: List<&2, Lexer.Token>, next_scope: List<&2, Scope>, depth: Nat, quantity: Ast.Quantity) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_ready:
    case True{}:
      with_term_result(parse_body(file, skip_rewrite_semicolon(after_value), next_scope, depth + 1n, col), body => after_body => ok_body => parse_local_body_parsed(ok_body, body, after_body, file, key, beg, pattern, quantity, value))
    case False{}:
      ((Ast.TermHole{ "parse-error: expected an indented local body",  span(file, token_end_first(value), token_end_first(value))}, after_value), False{})

def parse_array_write_local(+file: String, key: String, beg: Nat, key_end: Nat, col: Nat, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  with_term_result(parse_term(file, tokens, scope, depth, 0n), value => after_value => ok_value => parse_local_body_term_result(ok_value, file, key, beg, key_end, col, value, after_value, scope, depth, Ast.QOne{}))

def parse_destructuring_local(+file: String, +tokens: List<&2, Lexer.Token>, beg: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  with_pattern_result(parse_pattern_atom(file, tokens, scope, depth), pattern => after_pattern => next_scope => next_depth => ok_pattern => parse_destructuring_pattern_result(ok_pattern, after_pattern, pattern, next_scope, next_depth, file, tokens, beg, col, scope, depth))

def parse_destructuring_pattern_result(ok_pattern: Bool, after_pattern: List<&2, Lexer.Token>, pattern: Ast.SyntaxPattern, next_scope: List<&2, Scope>, next_depth: Nat, +file: String, tokens: List<&2, Lexer.Token>, beg: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_pattern after_pattern:
    case True{} +equals <> after_equals:
      match equals:
        case Lexer.TokenInfo{ _, "=",  _,  _,  _,  _}:
          with_term_result(parse_term(file, after_equals, scope, depth, 0n), value => after_value => ok_value => parse_destructuring_value_result(ok_value, value, after_value, pattern, next_scope, next_depth, file, tokens, beg, col, scope, depth))
        case _:
          parse_reply(file, tokens, scope, depth)
    case _ _:
      parse_reply(file, tokens, scope, depth)

def parse_destructuring_value_result(ok_value: Bool, value: Ast.SyntaxTerm, +after_value: List<&2, Lexer.Token>, pattern: Ast.SyntaxPattern, next_scope: List<&2, Scope>, next_depth: Nat, file: String, tokens: List<&2, Lexer.Token>, beg: Nat, +col: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_value:
    case True{}:
      parse_destructuring_body_ready(local_body_ready(after_value, col), value, after_value, pattern, next_scope, next_depth, file, beg, col)
    case False{}:
      ((value, after_value), False{})

def parse_destructuring_body_ready(is_ready: Bool, +value: Ast.SyntaxTerm, after_value: List<&2, Lexer.Token>, pattern: Ast.SyntaxPattern, next_scope: List<&2, Scope>, next_depth: Nat, +file: String, beg: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_ready:
    case True{}:
      with_term_result(parse_body(file, skip_rewrite_semicolon(after_value), next_scope, next_depth, col), body => after_body => ok_body => parse_destructuring_parsed_body(ok_body, body, after_body, value, pattern, file, beg))
    case False{}:
      ((Ast.TermHole{ "parse-error: expected an indented destructuring body",  span(file, token_end_first(value), token_end_first(value))}, after_value), False{})

def parse_match_body(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  with_args_result(parse_terms_until_colon(file, tokens, scope, depth, Nil{}), scrutinees => after_scrutinees => ok_scrutinees => parse_match_scrutinees(ok_scrutinees, after_scrutinees, scrutinees, file, beg, col, scope, depth))

def match_scrutinees_branch_0(+scrutinees: List<&2, Ast.SyntaxTerm>, +file: String, +beg: Nat, col: Nat, scope: List<&2, Scope>, depth: Nat, +colon: Lexer.Token, after_colon: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  with_args_result(parse_case_rows(file, after_colon, Nat.sub(col, 1n), scope, depth, List.length(&2, Ast.SyntaxTerm, scrutinees), Nil{}), cases => after_cases => ok_cases => parse_match_cases_result(ok_cases, cases, after_cases, scrutinees, colon, file, beg))

def match_scrutinees_branch_1(after_scrutinees: List<&2, Lexer.Token>, +file: String, +colon: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected :",  span(file, token_beg(colon), token_end(colon))}, after_scrutinees), False{})

def match_scrutinees_is_colon(colon: Lexer.Token) -> Bool:
  match colon:
    case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
      True{}
    case _:
      False{}

def match_scrutinees_run(is_colon: Bool, after_scrutinees: List<&2, Lexer.Token>, +scrutinees: List<&2, Ast.SyntaxTerm>, +file: String, +beg: Nat, col: Nat, scope: List<&2, Scope>, depth: Nat, +colon: Lexer.Token, after_colon: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  match is_colon:
    case True{}:
      match_scrutinees_branch_0(scrutinees, file, beg, col, scope, depth, colon, after_colon)
    case False{}:
      match_scrutinees_branch_1(after_scrutinees, file, colon)

def parse_match_scrutinees(ok_scrutinees: Bool, after_scrutinees: List<&2, Lexer.Token>, +scrutinees: List<&2, Ast.SyntaxTerm>, +file: String, +beg: Nat, col: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_scrutinees after_scrutinees:
    case True{} +colon <> after_colon:
      match_scrutinees_run(match_scrutinees_is_colon(colon), after_scrutinees, scrutinees, file, beg, col, scope, depth, colon, after_colon)
    case _ _:
      ((Ast.TermHole{ "parse-error: expected match scrutinee",  span(file, beg, beg)}, after_scrutinees), False{})

def parse_terms_until_colon_result(ok: Bool, term: Ast.SyntaxTerm, after: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.SyntaxTerm>) -> (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool:
  match ok after:
    case True{} _:
      match after:
        case +separator <> tail:
          match separator:
            case Lexer.TokenInfo{ _, ",",  _,  _,  _,  _}:
              parse_terms_until_colon(file, tail, scope, depth, term <> acc)
            case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
              ((List.reverse(&2, Ast.SyntaxTerm, term <> acc), after), True{})
            case _:
              ((List.reverse(&2, Ast.SyntaxTerm, term <> acc), after), False{})
        case Nil{}:
          ((List.reverse(&2, Ast.SyntaxTerm, term <> acc), after), False{})
    case False{} _:
      ((List.reverse(&2, Ast.SyntaxTerm, acc), after), False{})

def parse_terms_until_colon(+file: String, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, acc: List<&2, Ast.SyntaxTerm>) -> (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
          ((List.reverse(&2, Ast.SyntaxTerm, acc), tokens), True{})
        case _:
          with_term_to_args(parse_term(file, tokens, scope, depth, 0n), term => after => ok => parse_terms_until_colon_result(ok, term, after, file, scope, depth, acc))
    case Nil{}:
      ((List.reverse(&2, Ast.SyntaxTerm, acc), Nil{}), False{})

def parse_case_row_indented(is_indented: Bool, +file: String, tokens: List<&2, Lexer.Token>, rest: List<&2, Lexer.Token>, parent_col: Nat, +scope: List<&2, Scope>, +depth: Nat, +arity: Nat, acc: List<&2, Ast.SyntaxTerm>, beg: Nat, col: Nat) -> (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool:
  match is_indented:
    case True{}:
      with_term_to_args(parse_case_row(file, rest, beg, col, scope, depth, arity), row => after_row => ok_row => parse_case_row_result(ok_row, row, after_row, file, tokens, parent_col, scope, depth, arity, acc))
    case False{}:
      parse_case_rows_stop(acc, tokens)

def parse_case_row_result(ok_row: Bool, row: Ast.SyntaxTerm, +after_row: List<&2, Lexer.Token>, file: String, tokens: List<&2, Lexer.Token>, parent_col: Nat, scope: List<&2, Scope>, depth: Nat, arity: Nat, acc: List<&2, Ast.SyntaxTerm>) -> (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool:
  match ok_row:
    case True{}:
      parse_case_rows_scan(file, after_row, skip_lines(after_row), parent_col, scope, depth, arity, row <> acc)
    case False{}:
      ((List.reverse(&2, Ast.SyntaxTerm, row <> acc), after_row), False{})

def parse_case_rows_scan(file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +parent_col: Nat, scope: List<&2, Scope>, depth: Nat, arity: Nat, acc: List<&2, Ast.SyntaxTerm>) -> (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool:
  match scanned:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{ Lexer.NameToken{},  "case", beg,  _,  _, col}:
          parse_case_row_indented(Nat.is_lt(parent_col, col), file, tokens, rest, parent_col, scope, depth, arity, acc, beg, col)
        case _:
          match acc:
            case Nil{}:
              (([], tokens), False{})
            case _:
              ((List.reverse(&2, Ast.SyntaxTerm, acc), tokens), True{})
    case Nil{}:
      match acc:
        case Nil{}:
          (([], []), False{})
        case _:
          ((List.reverse(&2, Ast.SyntaxTerm, acc), []), True{})

def parse_case_rows(file: String, +tokens: List<&2, Lexer.Token>, parent_col: Nat, scope: List<&2, Scope>, depth: Nat, arity: Nat, acc: List<&2, Ast.SyntaxTerm>) -> (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool:
  parse_case_rows_scan(file, tokens, skip_lines(tokens), parent_col, scope, depth, arity, acc)

def parse_case_row_patterns(ok_patterns: Bool, +patterns: List<&2, Ast.SyntaxPattern>, after_patterns: List<&2, Lexer.Token>, next_scope: List<&2, Scope>, next_depth: Nat, file: String, +beg: Nat, col: Nat, arity: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_patterns:
    case True{}:
      parse_case_row_count(pattern_count_matches(patterns, arity), patterns, after_patterns, next_scope, next_depth, file, beg, col)
    case False{}:
      ((Ast.TermHole{ "parse-error: expected a case pattern",  span(file, beg, beg)}, after_patterns), False{})
def parse_case_row_scan_result(result: PatternScanOutcome, file: String, +beg: Nat, col: Nat, arity: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case PatternCaseOutcome{patterns, after, scope, depth, ok}:
      parse_case_row_patterns(ok, patterns, after, scope, depth, file, beg, col, arity)
    case PatternSingleOutcome{pattern, after, scope, depth, ok}:
      ((Ast.TermHole{"parse-error: unexpected single-pattern outcome", span(file, beg, beg)}, after), False{})

def parse_case_row(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat, arity: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_case_row_scan_result(pattern_scan(tokens, file, PatternExpect{Ast.QOne{}, 0n}, Nil{}, scope, depth, PatternCaseGoal{Nil{}, scope, depth}), file, beg, col, arity)


def parse_case_row_count(is_valid: Bool, patterns: List<&2, Ast.SyntaxPattern>, +after_patterns: List<&2, Lexer.Token>, next_scope: List<&2, Scope>, next_depth: Nat, file: String, +beg: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_valid:
    case True{}:
      parse_case_row_body(file, patterns, after_patterns, next_scope, next_depth, beg, col)
    case False{}:
      ((Ast.TermHole{ "parse-error: case needs one pattern per scrutinee",  span(file, beg, token_end_of(after_patterns, beg))}, after_patterns), False{})

def parse_case_body_indented(is_indented: Bool, +file: String, patterns: List<&2, Ast.SyntaxPattern>, after_colon: List<&2, Lexer.Token>, +colon: Lexer.Token, scope: List<&2, Scope>, depth: Nat, beg: Nat, col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_indented:
    case True{}:
      with_term_result(parse_body(file, after_colon, scope, depth, col), body => after_body => ok_body => parse_case_body_result(ok_body, body, after_body, patterns, file, beg))
    case False{}:
      ((Ast.TermHole{ "parse-error: expected an indented case body",  span(file, token_end(colon), token_end(colon))}, after_colon), False{})

def case_row_branch_0(file: String, patterns: List<&2, Ast.SyntaxPattern>, scope: List<&2, Scope>, depth: Nat, +beg: Nat, +col: Nat, +colon: Lexer.Token, +after_colon: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  parse_case_body_indented(body_indented(after_colon, col), file, patterns, after_colon, colon, scope, depth, beg, col)

def case_row_branch_1(file: String, tokens: List<&2, Lexer.Token>, +colon: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected :",  span(file, token_beg(colon), token_end(colon))}, tokens), False{})

def case_row_is_colon(colon: Lexer.Token) -> Bool:
  match colon:
    case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
      True{}
    case _:
      False{}

def case_row_run(is_colon: Bool, file: String, patterns: List<&2, Ast.SyntaxPattern>, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, +beg: Nat, +col: Nat, +colon: Lexer.Token, +after_colon: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  match is_colon:
    case True{}:
      case_row_branch_0(file, patterns, scope, depth, beg, col, colon, after_colon)
    case False{}:
      case_row_branch_1(file, tokens, colon)

def parse_case_row_body(file: String, patterns: List<&2, Ast.SyntaxPattern>, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, +beg: Nat, +col: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +colon <> +after_colon:
      case_row_run(case_row_is_colon(colon), file, patterns, tokens, scope, depth, beg, col, colon, after_colon)
    case Nil{}:
      ((Ast.TermHole{ "parse-error: expected :",  span(file, beg, beg)}, Nil{}), False{})

def parse_def_binders_scan(file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.TelescopeItem>) -> (((List<&2, Ast.TelescopeItem> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool:
  match scanned:
    case +token <> +rest:
      match token:
        case Lexer.TokenInfo{ _, ")",  _,  _,  _,  _}:
          ((((List.reverse(&2, Ast.TelescopeItem, acc), rest), scope), depth), True{})
        case Lexer.TokenInfo{ _, ">",  _,  _,  _,  _}:
          ((((List.reverse(&2, Ast.TelescopeItem, acc), rest), scope), depth), True{})
        case Lexer.TokenInfo{ _, "<>",  _,  _,  _,  _}:
          ((((List.reverse(&2, Ast.TelescopeItem, acc), rest), scope), depth), True{})
        case Lexer.TokenInfo{ _, "}",  _,  _,  _,  _}:
          ((((List.reverse(&2, Ast.TelescopeItem, acc), rest), scope), depth), True{})
        case Lexer.TokenInfo{ _, ",",  _,  _,  _,  _}:
          parse_def_binders_scan(file, rest, skip_lines(rest), scope, depth, acc)
        case Lexer.TokenInfo{ _, "+",  _,  _,  _,  _}:
          parse_def_binder_prefix(file, rest, scope, depth, acc, Ast.QMany{})
        case Lexer.TokenInfo{ _, "-",  _,  _,  _,  _}:
          parse_def_binder_prefix(file, rest, scope, depth, acc, Ast.QZero{})
        case Lexer.TokenInfo{ _, "~", beg,  _,  _,  _}:
          parse_template_def_binder(file, rest, beg, scope, depth, acc)
        case Lexer.TokenInfo{Lexer.NameToken{}, key, beg, _, _, _}:
          parse_def_binder(file, key, Ast.QOne{}, beg, rest, scope, depth, acc)
        case _:
          ((((List.reverse(&2, Ast.TelescopeItem, acc), tokens), scope), depth), False{})
    case Nil{}:
      ((((List.reverse(&2, Ast.TelescopeItem, acc), []), scope), depth), False{})
def parse_def_binders(file: String, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.TelescopeItem>) -> (((List<&2, Ast.TelescopeItem> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool:
  parse_def_binders_scan(file, tokens, skip_lines(tokens), scope, depth, acc)

def parse_template_binder_type_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, +file: String, acc: List<&2, Ast.TelescopeItem>, scope: List<&2, Scope>, +depth: Nat, +key: String, beg: Nat) -> (((List<&2, Ast.TelescopeItem> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool:
  match result:
    case ((+ty, after_ty), True{}):
      +index = depth
      item = { Ast.TemplateBinder{key, index, ty, span(file, beg, token_end_first(ty))} : Ast.TelescopeItem }
      next_scope = extend_scope(key, index, scope)
      parse_def_binders(file, after_ty, next_scope, depth + 1n, item <> acc)
    case ((ty, after_ty), False{}):
      ((((List.reverse(&2, Ast.TelescopeItem, acc), after_ty), scope), depth), False{})

def parse_template_def_binder_after_name(+file: String, key: String, beg: Nat, original: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, acc: List<&2, Ast.TelescopeItem>) -> (((List<&2, Ast.TelescopeItem> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool:
  match scanned:
    case +colon <> after_colon:
      match colon:
        case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
          parse_template_binder_type_result(parse_term(file, after_colon, scope, depth, 0n), file, acc, scope, depth, key, beg)
        case _:
          ((((List.reverse(&2, Ast.TelescopeItem, acc), original), scope), depth), False{})
    case Nil{}:
      ((((List.reverse(&2, Ast.TelescopeItem, acc), original), scope), depth), False{})

def parse_template_def_binder(file: String, tokens: List<&2, Lexer.Token>, beg: Nat, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.TelescopeItem>) -> (((List<&2, Ast.TelescopeItem> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool:
  match tokens:
    case +name <> +after_name:
      match name:
        case Lexer.TokenInfo{ Lexer.NameToken{},  key,  _,  _,  _,  _}:
          parse_template_def_binder_after_name(file, key, beg, after_name, skip_lines(after_name), scope, depth, acc)
        case _:
          ((((List.reverse(&2, Ast.TelescopeItem, acc), tokens), scope), depth), False{})
    case Nil{}:
      ((((List.reverse(&2, Ast.TelescopeItem, acc), []), scope), depth), False{})

def parse_def_binder_prefix(file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.TelescopeItem>, quantity: Ast.Quantity) -> (((List<&2, Ast.TelescopeItem> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool:
  match tokens:
    case +name <> rest:
      match name:
        case Lexer.TokenInfo{ Lexer.NameToken{},  key, beg,  _,  _,  _}:
          parse_def_binder(file, key, quantity, beg, rest, scope, depth, acc)
        case _:
          ((((List.reverse(&2, Ast.TelescopeItem, acc), tokens), scope), depth), False{})
    case Nil{}:
      ((((List.reverse(&2, Ast.TelescopeItem, acc), []), scope), depth), False{})

def parse_def_binder_type_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, +file: String, +key: String, quantity: Ast.Quantity, beg: Nat, acc: List<&2, Ast.TelescopeItem>, scope: List<&2, Scope>, +depth: Nat) -> (((List<&2, Ast.TelescopeItem> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool:
  match result:
    case ((+ty, after_ty), True{}):
      +index = depth
      item = { Ast.Binder{quantity, key, index, ty, span(file, beg, token_end_first(ty))} : Ast.TelescopeItem }
      next_scope = extend_scope(key, index, scope)
      parse_def_binders(file, after_ty, next_scope, depth + 1n, item <> acc)
    case ((ty, after_ty), False{}):
      ((((List.reverse(&2, Ast.TelescopeItem, acc), after_ty), scope), depth), False{})

def parse_def_binder_scan(+file: String, key: String, quantity: Ast.Quantity, beg: Nat, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, acc: List<&2, Ast.TelescopeItem>) -> (((List<&2, Ast.TelescopeItem> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool:
  match scanned:
    case +colon <> after_colon:
      match colon:
        case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
          parse_def_binder_type_result(parse_term(file, after_colon, scope, depth, 0n), file, key, quantity, beg, acc, scope, depth)
        case _:
          parse_untyped_def_binder(file, key, beg, tokens, scope, depth, acc)
    case _:
      parse_untyped_def_binder(file, key, beg, tokens, scope, depth, acc)

def parse_def_binder(file: String, key: String, quantity: Ast.Quantity, beg: Nat, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.TelescopeItem>) -> (((List<&2, Ast.TelescopeItem> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool:
  parse_def_binder_scan(file, key, quantity, beg, tokens, skip_lines(tokens), scope, depth, acc)

def parse_untyped_def_binder(+file: String, +key: String, +beg: Nat, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, +depth: Nat, acc: List<&2, Ast.TelescopeItem>) -> (((List<&2, Ast.TelescopeItem> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool:
  +index = depth
  item = { Ast.Binder{ Ast.QZero{}, key, index,  Ast.TermQuant{},  span(file, beg, token_end_of(tokens, beg))} : Ast.TelescopeItem }
  next_scope = extend_scope(key, index, scope)
  parse_def_binders(file, tokens, next_scope, depth + 1n, item <> acc)

def parse_definition_body_scan(file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.DefBody & List<&2, Lexer.Token>) & Bool:
  match scanned:
    case +token <> _:
      match token:
        case Lexer.TokenInfo{ Lexer.NameToken{},  "import",  _,  _,  _,  _}:
          parse_definition_imports_result(parse_external_imports(tokens, Nil{}))
        case _:
          parse_definition_term_result(parse_body(file, tokens, scope, depth, 0n))
    case Nil{}:
      ((Ast.DefTerm{Ast.TermHole{ "parse-error: expected a definition body",  span(file, 0n, 0n)}}, Nil{}), False{})

def parse_definition_body(file: String, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.DefBody & List<&2, Lexer.Token>) & Bool:
  parse_definition_body_scan(file, tokens, skip_lines(tokens), scope, depth)

def parse_definition_typed_colon(colon: Lexer.Token, +after_colon: List<&2, Lexer.Token>, after_result: List<&2, Lexer.Token>, result: Ast.SyntaxTerm, header: Lexer.Token, +file: String, key: String, beg: Nat, binders: List<&2, Ast.TelescopeItem>, scope: List<&2, Scope>, depth: Nat) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match colon:
    case Lexer.TokenInfo{_, ":", _, _, _, _}:
      with_def_body_result(parse_definition_body(file, after_colon, scope, depth), body => after_body => ok_body => parse_definition_typed_body_result(ok_body, body, after_body, colon, after_colon, file, key, beg, binders, result))
    case _:
      definition_failure(file, key, binders, beg, token_beg(colon), after_result)

def parse_definition_typed_result(result_pair: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, header: Lexer.Token, file: String, key: String, beg: Nat, binders: List<&2, Ast.TelescopeItem>, scope: List<&2, Scope>, depth: Nat) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match result_pair:
    case ((result, +colon <> +after_colon), True{}):
      parse_definition_typed_colon(colon, after_colon, colon <> after_colon, result, header, file, key, beg, binders, scope, depth)
    case ((_, after_result), False{}):
      definition_failure(file, key, binders, beg, token_end(header), after_result)
    case ((_, after_result), True{}):
      definition_failure(file, key, binders, beg, token_end(header), after_result)

type DefinitionHeaderAction is Data:
  DefinitionHeaderRow0{}
  DefinitionHeaderRow1{}
  DefinitionHeaderRow2{}

def definition_header_branch_0(+file: String, key: String, +beg: Nat, binders: List<&2, Ast.TelescopeItem>, +scope: List<&2, Scope>, +depth: Nat, +header: Lexer.Token, +rest: List<&2, Lexer.Token>) -> Pair(Pair(Ast.TopLevel, List<&2, Lexer.Token>), Bool):
  parse_definition_typed_result(parse_term(file, rest, scope, depth, 0n), header, file, key, beg, binders, scope, depth)

def definition_header_branch_1(+file: String, key: String, +beg: Nat, binders: List<&2, Ast.TelescopeItem>, +scope: List<&2, Scope>, +depth: Nat, +header: Lexer.Token, +rest: List<&2, Lexer.Token>) -> Pair(Pair(Ast.TopLevel, List<&2, Lexer.Token>), Bool):
  with_def_body_result(parse_definition_body(file, rest, scope, depth), body => after_body => ok_body => parse_definition_untyped_body_result(ok_body, body, after_body, file, key, beg, binders, header, rest))

def definition_header_branch_2(+file: String, key: String, +beg: Nat, binders: List<&2, Ast.TelescopeItem>, tokens: List<&2, Lexer.Token>, +header: Lexer.Token) -> Pair(Pair(Ast.TopLevel, List<&2, Lexer.Token>), Bool):
  definition_failure(file, key, binders, beg, token_beg(header), tokens)

def definition_header_is_colon(header: Lexer.Token) -> DefinitionHeaderAction:
  match header:
    case Lexer.TokenInfo{ _, "->",  _,  _,  _,  _}:
      DefinitionHeaderRow0{}
    case Lexer.TokenInfo{_, ":", _, _, _, _}:
      DefinitionHeaderRow1{}
    case _:
      DefinitionHeaderRow2{}

def definition_header_run(is_colon: DefinitionHeaderAction, +file: String, key: String, +beg: Nat, binders: List<&2, Ast.TelescopeItem>, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +header: Lexer.Token, +rest: List<&2, Lexer.Token>) -> Pair(Pair(Ast.TopLevel, List<&2, Lexer.Token>), Bool):
  match is_colon:
    case DefinitionHeaderRow0{}:
      definition_header_branch_0(file, key, beg, binders, scope, depth, header, rest)
    case DefinitionHeaderRow1{}:
      definition_header_branch_1(file, key, beg, binders, scope, depth, header, rest)
    case DefinitionHeaderRow2{}:
      definition_header_branch_2(file, key, beg, binders, tokens, header)

def parse_definition_after_binders_scan(+file: String, key: String, +beg: Nat, binders: List<&2, Ast.TelescopeItem>, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match scanned:
    case +header <> +rest:
      definition_header_run(definition_header_is_colon(header), file, key, beg, binders, tokens, scope, depth, header, rest)
    case Nil{}:
      definition_failure(file, key, binders, beg, beg, Nil{})

def parse_definition_after_binders(file: String, key: String, beg: Nat, binders: List<&2, Ast.TelescopeItem>, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  parse_definition_after_binders_scan(file, key, beg, binders, tokens, skip_lines(tokens), scope, depth)

def parse_definition_binders_result(ok_binders: Bool, binders: List<&2, Ast.TelescopeItem>, +after_binders: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, file: String, key: String, +beg: Nat) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match ok_binders:
    case True{}:
      parse_definition_after_binders(file, key, beg, binders, after_binders, scope, depth)
    case False{}:
      definition_failure(file, key, Nil{}, beg, token_end_of(after_binders, beg), after_binders)

def parse_definition_with_binders(+file: String, key: String, beg: Nat, tokens: List<&2, Lexer.Token>, path: String) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  with_def_binders_result(parse_def_binders(file, tokens, Nil{}, 0n, Nil{}), binders => after_binders => scope => depth => ok_binders => parse_definition_binders_result(ok_binders, binders, after_binders, scope, depth, file, key, beg))

def parse_definition_name_tail(key: String, after_name: List<&2, Lexer.Token>, +file: String, +def_token: Lexer.Token, path: String) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match after_name:
    case +open <> after_open:
      match open:
        case Lexer.TokenInfo{_, "(", _, _, _, _}:
          parse_definition_with_binders(file, key, token_beg(def_token), after_open, path)
        case _:
          ((Ast.DefTop{Ast.Definition{key, Nil{}, Ast.NoTerm{}, Ast.DefTerm{Ast.TermHole{"parse-error: expected (", span(file, token_beg(open), token_end(open))}}, False{}, span(file, token_beg(def_token), token_end(open))}}, after_name), False{})
    case Nil{}:
      ((Ast.DefTop{Ast.Definition{key, Nil{}, Ast.NoTerm{}, Ast.DefTerm{Ast.TermHole{"parse-error: expected (", span(file, token_beg(def_token), token_end(def_token))}}, False{}, span(file, token_beg(def_token), token_end(def_token))}}, after_name), False{})

def parse_definition_name_result(name_parsed: (String & List<&2, Lexer.Token>) & Bool, +file: String, +def_token: Lexer.Token, after_def: List<&2, Lexer.Token>, path: String) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match name_parsed:
    case ((key, after_name), True{}):
      parse_definition_name_tail(key, after_name, file, def_token, path)
    case _:
      ((Ast.DefTop{Ast.Definition{"", Nil{}, Ast.NoTerm{}, Ast.DefTerm{Ast.TermHole{"parse-error: expected a definition name", span(file, token_beg(def_token), token_end(def_token))}}, False{}, span(file, token_beg(def_token), token_end(def_token))}}, after_def), False{})

def parse_definition(+file: String, tokens: List<&2, Lexer.Token>, path: String) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +def_token <> +after_def:
      parse_definition_name_result(parse_name(after_def), file, def_token, after_def, path)
    case Nil{}:
      ((Ast.DefTop{ Ast.Definition{ "",  Nil{},  Ast.NoTerm{},  Ast.DefTerm{Ast.TermHole{ "parse-error: expected def",  span(file, 0n, 0n)}},  False{},  span(file, 0n, 0n)}}, Nil{}), False{})
def canonical_import_path(token: Lexer.Token) -> String:
  match token:
    case Lexer.TokenInfo{ Lexer.StringToken{}, text,  _,  _,  _,  _}:
      strip_quotes(text)
    case Lexer.TokenInfo{ Lexer.NameToken{}, text,  _,  _,  _,  _}:
      text
    case _:
      token_text(token)

def parse_module_import_path(file: String, import_token: Lexer.Token, +path_token: Lexer.Token, +after_path: List<&2, Lexer.Token>) -> (Ast.ModuleImport & List<&2, Lexer.Token>) & Bool:
  canonical = canonical_import_path(path_token)
  beg = token_beg(import_token)
  parse_module_import_path_rest(after_path, has_space_after(token_end(path_token), after_path), path_token, file, [canonical], beg)

def parse_module_import(file: String, +import_token: Lexer.Token, tokens: List<&2, Lexer.Token>) -> (Ast.ModuleImport & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +path_token <> after_path:
      parse_module_import_path(file, import_token, path_token, after_path)
    case Nil{}:
      ((Ast.ModuleImport{ "", "", span(file, token_beg(import_token), token_end(import_token))}, Nil{}), False{})

def parse_imports_result(ok: Bool, item: Ast.ModuleImport, +after: List<&2, Lexer.Token>, file: String, acc: List<&2, Ast.ModuleImport>) -> ((List<&2, Ast.ModuleImport> & List<&2, Lexer.Token>) & Bool):
  match ok:
    case True{}:
      parse_imports_scan(file, after, skip_lines(after), item <> acc)
    case False{}:
      ((List.reverse(&2, Ast.ModuleImport, item <> acc), after), False{})

def parse_imports_scan(+file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, acc: List<&2, Ast.ModuleImport>) -> ((List<&2, Ast.ModuleImport> & List<&2, Lexer.Token>) & Bool):
  match scanned:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{ Lexer.NameToken{},  "import",  _,  _,  _,  _}:
          with_import_result(parse_module_import(file, token, rest), item => after => ok => parse_imports_result(ok, item, after, file, acc))
        case _:
          ((List.reverse(&2, Ast.ModuleImport, acc), tokens), True{})
    case Nil{}:
      ((List.reverse(&2, Ast.ModuleImport, acc), []), True{})

def parse_imports(file: String, +tokens: List<&2, Lexer.Token>, acc: List<&2, Ast.ModuleImport>) -> ((List<&2, Ast.ModuleImport> & List<&2, Lexer.Token>) & Bool):
  parse_imports_scan(file, tokens, skip_lines(tokens), acc)

def mark_unsafe(top: Ast.TopLevel, unsafe: Bool) -> Ast.TopLevel:
  match top:
    case Ast.DefTop{definition}:
      match definition:
        case Ast.Definition{key, binders, result, body, _, source_span}:
          Ast.DefTop{Ast.Definition{key, binders, result, body, unsafe, source_span}}
    case _:
      top

def parse_unsafe(file: String, tokens: List<&2, Lexer.Token>, path: String) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +unsafe_token <> rest:
      match unsafe_token:
        case Lexer.TokenInfo{ _, "unsafe",  _,  _,  _,  _}:
          match rest:
            case +def_token <> after_def:
              match def_token:
                case Lexer.TokenInfo{ _, "def",  _,  _,  _,  _}:
                  with_top_result(parse_definition(file, after_def, path), top => after => ok => ((mark_unsafe(top, True{}), after), ok))
                case _:
                  parse_definition(file, rest, path)
            case Nil{}:
              parse_definition(file, rest, path)
        case _:
          parse_definition(file, tokens, path)
    case Nil{}:
      parse_definition(file, Nil{}, path)

def parse_type_header_constructors_result(ok_constructors: Bool, constructors: List<&2, Ast.ConstructorDecl>, +after_constructors: List<&2, Lexer.Token>, file: String, key: String, beg: Nat, params: List<&2, Ast.TelescopeItem>, +kind: Ast.SyntaxTerm) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  declaration = { Ast.TypeDecl{key, params, kind, constructors, span(file, beg, token_end_of(after_constructors, token_end_first(kind)))} : Ast.TypeDecl }
  ((Ast.TypeTop{declaration}, after_constructors), ok_constructors)

def type_failure(+file: String, key: String, beg: Nat, +end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  error = { Ast.TermHole{ "parse-error: malformed or unsupported type declaration",  span(file, end, end)} : Ast.SyntaxTerm }
  declaration = { Ast.TypeDecl{key,  Nil{},  error,  Nil{},  span(file, beg, end)} : Ast.TypeDecl }
  ((Ast.TypeTop{declaration}, rest), False{})

def parse_type_constructor_fields_result(ok_fields: Bool, fields: List<&2, Ast.TelescopeItem>, +after_fields: List<&2, Lexer.Token>, +file: String, open: Lexer.Token, after_open: List<&2, Lexer.Token>, col: Nat, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.ConstructorDecl>, key: String, beg: Nat) -> (List<&2, Ast.ConstructorDecl> & List<&2, Lexer.Token>) & Bool:
  match ok_fields:
    case True{}:
      item = { Ast.Constructor{key, fields, span(file, beg, token_end_of(after_fields, token_end(open)))} : Ast.ConstructorDecl }
      parse_type_constructors_scan(file, after_fields, skip_lines(after_fields), col, scope, depth, item <> acc)
    case False{}:
      ((List.reverse(&2, Ast.ConstructorDecl, acc), after_open), False{})

def parse_type_constructor_indent(is_indented: Bool, +file: String, tokens: List<&2, Lexer.Token>, rest: List<&2, Lexer.Token>, col: Nat, +scope: List<&2, Scope>, +depth: Nat, acc: List<&2, Ast.ConstructorDecl>, key: String, beg: Nat) -> (List<&2, Ast.ConstructorDecl> & List<&2, Lexer.Token>) & Bool:
  match is_indented:
    case True{}:
      match rest:
        case +open <> +after_open:
          match open:
            case Lexer.TokenInfo{ _, "{",  _,  _,  _,  _}:
              with_def_binders_constructors_result(parse_def_binders(file, after_open, scope, depth, Nil{}), fields => after_fields => _fields_scope => _fields_depth => ok_fields => parse_type_constructor_fields_result(ok_fields, fields, after_fields, file, open, after_open, col, scope, depth, acc, key, beg))
            case _:
              ((List.reverse(&2, Ast.ConstructorDecl, acc), tokens), False{})
        case Nil{}:
          ((List.reverse(&2, Ast.ConstructorDecl, acc), tokens), False{})
    case False{}:
      ((List.reverse(&2, Ast.ConstructorDecl, acc), tokens), True{})

def parse_type_constructors_scan(file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +col: Nat, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.ConstructorDecl>) -> (List<&2, Ast.ConstructorDecl> & List<&2, Lexer.Token>) & Bool:
  match scanned:
    case +constructor <> rest:
      match constructor:
        case Lexer.TokenInfo{ Lexer.NameToken{},  key, beg,  _,  _,  constructor_col}:
          parse_type_constructor_indent(Nat.is_lt(col, constructor_col), file, tokens, rest, col, scope, depth, acc, key, beg)
        case _:
          ((List.reverse(&2, Ast.ConstructorDecl, acc), tokens), True{})
    case Nil{}:
      ((List.reverse(&2, Ast.ConstructorDecl, acc), []), True{})

def parse_type_constructors(file: String, +tokens: List<&2, Lexer.Token>, col: Nat, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.ConstructorDecl>) -> (List<&2, Ast.ConstructorDecl> & List<&2, Lexer.Token>) & Bool:
  parse_type_constructors_scan(file, tokens, skip_lines(tokens), col, scope, depth, acc)

def parse_type_header_kind_result(ok_kind: Bool, kind: Ast.SyntaxTerm, after_kind: List<&2, Lexer.Token>, +file: String, key: String, beg: Nat, col: Nat, params: List<&2, Ast.TelescopeItem>, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match ok_kind after_kind:
    case True{} +colon <> after_colon:
      match colon:
        case Lexer.TokenInfo{ _, ":", _, _, _, _}:
          with_constructor_decls_result(parse_type_constructors(file, after_colon, col, scope, depth, Nil{}), constructors => after_constructors => ok_constructors => parse_type_header_constructors_result(ok_constructors, constructors, after_constructors, file, key, beg, params, kind))
        case _:
          type_failure(file, key, beg, token_beg(colon), after_kind)
    case _ _:
      type_failure(file, key, beg, token_end_first(kind), after_kind)

def parse_type_header_scan(+file: String, key: String, +beg: Nat, col: Nat, params: List<&2, Ast.TelescopeItem>, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match scanned:
    case +is_token <> after_is:
      match is_token:
        case Lexer.TokenInfo{ _, "is",  _,  _,  _,  _}:
          with_term_top(parse_term(file, after_is, scope, depth, 0n), kind => after_kind => ok_kind => parse_type_header_kind_result(ok_kind, kind, after_kind, file, key, beg, col, params, tokens, scope, depth))
        case _:
          type_failure(file, key, beg, token_beg(is_token), tokens)
    case Nil{}:
      type_failure(file, key, beg, beg, Nil{})

def parse_type_header(file: String, key: String, beg: Nat, col: Nat, params: List<&2, Ast.TelescopeItem>, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  parse_type_header_scan(file, key, beg, col, params, tokens, skip_lines(tokens), scope, depth)

def parse_type_params_result(ok_params: Bool, params: List<&2, Ast.TelescopeItem>, after_params: List<&2, Lexer.Token>, open: Lexer.Token, file: String, key: String, beg: Nat, col: Nat, scope: List<&2, Scope>, depth: Nat) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match ok_params:
    case True{}:
      parse_type_header(file, key, beg, col, params, after_params, scope, depth)
    case False{}:
      type_failure(file, key, beg, token_end(open), after_params)

def parse_type_decl(+file: String, tokens: List<&2, Lexer.Token>, +beg: Nat, col: Nat) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +name <> after_name:
      match name:
        case Lexer.TokenInfo{ Lexer.NameToken{},  key,  _,  _,  _,  _}:
          match after_name:
            case +open <> after_open:
              match open:
                case Lexer.TokenInfo{ _, "<",  _,  _,  _,  _}:
                  with_def_binders_result(parse_def_binders(file, after_open, Nil{}, 0n, Nil{}), params => after_params => scope => depth => ok_params => parse_type_params_result(ok_params, params, after_params, open, file, key, beg, col, scope, depth))
                case Lexer.TokenInfo{_, "<>", _, _, _, _}:
                  parse_type_header(file, key, beg, col, Nil{}, after_open, Nil{}, 0n)
                case _:
                  parse_type_header(file, key, beg, col, Nil{}, after_name, Nil{}, 0n)
            case Nil{}:
              parse_type_header(file, key, beg, col, Nil{}, after_name, Nil{}, 0n)
        case _:
          type_failure(file, "", beg, token_end(name), tokens)
    case Nil{}:
      type_failure(file, "", beg, beg, Nil{})

def law_failure(+file: String, key: String, beg: Nat, +end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  body = { Ast.TermHole{ "parse-error: malformed or unsupported law",  span(file, end, end)} : Ast.SyntaxTerm }
  declaration = { Ast.LawDecl{key,  Nil{}, body,  span(file, beg, end)} : Ast.LawDecl }
  ((Ast.LawTop{declaration}, rest), False{})

def parse_law_body_result(ok_body: Bool, +body: Ast.SyntaxTerm, after_body: List<&2, Lexer.Token>, file: String, key: String, clauses: List<&2, Ast.Clause>, beg: Nat, colon: Lexer.Token, after_clauses: List<&2, Lexer.Token>) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      declaration = { Ast.LawDecl{key, clauses, body, span(file, beg, token_end_first(body))} : Ast.LawDecl }
      ((Ast.LawTop{declaration}, after_body), True{})
    case False{}:
      law_failure(file, key, beg, token_end(colon), after_clauses)

def parse_law_clauses_result(ok_clauses: Bool, clauses: List<&2, Ast.Clause>, +after_clauses: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, +file: String, key: String, beg: Nat, colon: Lexer.Token, after_colon: List<&2, Lexer.Token>) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match ok_clauses:
    case True{}:
      with_term_top(parse_body(file, after_clauses, scope, depth, 0n), body => after_body => ok_body => parse_law_body_result(ok_body, body, after_body, file, key, clauses, beg, colon, after_clauses))
    case False{}:
      law_failure(file, key, beg, token_end(colon), after_colon)

def parse_law_clauses_scan(file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.Clause>) -> (((List<&2, Ast.Clause> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool:
  match scanned:
    case +token <> after_token:
      match token:
        case Lexer.TokenInfo{ _, "for",  _,  _,  _,  _}:
          parse_law_clause(file, after_token, token_beg(token), True{}, scope, depth, acc)
        case Lexer.TokenInfo{ _, "exs",  _,  _,  _,  _}:
          parse_law_clause(file, after_token, token_beg(token), False{}, scope, depth, acc)
        case _:
          ((((List.reverse(&2, Ast.Clause, acc), tokens), scope), depth), True{})
    case Nil{}:
      ((((List.reverse(&2, Ast.Clause, acc), []), scope), depth), True{})

def parse_law_clauses(file: String, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.Clause>) -> (((List<&2, Ast.Clause> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool:
  parse_law_clauses_scan(file, tokens, skip_lines(tokens), scope, depth, acc)

def parse_law_clause(file: String, tokens: List<&2, Lexer.Token>, beg: Nat, universal: Bool, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.Clause>) -> (((List<&2, Ast.Clause> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool:
  match universal:
    case True{}:
      parse_law_universal_clause(file, tokens, beg, scope, depth, acc)
    case False{}:
      parse_law_clause_name(file, tokens, beg, False{}, Ast.QOne{}, scope, depth, acc)

def parse_law_universal_clause(file: String, tokens: List<&2, Lexer.Token>, beg: Nat, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.Clause>) -> (((List<&2, Ast.Clause> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool:
  match tokens:
    case +prefix <> after_prefix:
      match prefix:
        case Lexer.TokenInfo{ _, "+",  _,  _,  _,  _}:
          parse_law_clause_name(file, after_prefix, beg, True{}, Ast.QMany{}, scope, depth, acc)
        case Lexer.TokenInfo{ _, "-",  _,  _,  _,  _}:
          parse_law_clause_name(file, after_prefix, beg, True{}, Ast.QZero{}, scope, depth, acc)
        case _:
          parse_law_clause_name(file, tokens, beg, True{}, Ast.QOne{}, scope, depth, acc)
    case Nil{}:
      ((((List.reverse(&2, Ast.Clause, acc), []), scope), depth), False{})

def parse_law_clause_type_result(ok_ty: Bool, ty: Ast.SyntaxTerm, after_ty: List<&2, Lexer.Token>, file: String, +key: String, key_beg: Nat, key_end: Nat, beg: Nat, universal: Bool, quantity: Ast.Quantity, scope: List<&2, Scope>, +depth: Nat, acc: List<&2, Ast.Clause>) -> (((List<&2, Ast.Clause> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool:
  match ok_ty:
    case True{}:
      index = depth
      next_scope = extend_scope(key, index, scope)
      parse_law_clause_condition(file, after_ty, beg, universal, quantity, key, key_beg, key_end, ty, next_scope, depth + 1n, acc)
    case False{}:
      ((((List.reverse(&2, Ast.Clause, acc), after_ty), scope), depth), False{})

def parse_law_clause_name(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, universal: Bool, quantity: Ast.Quantity, +scope: List<&2, Scope>, +depth: Nat, acc: List<&2, Ast.Clause>) -> (((List<&2, Ast.Clause> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool:
  match tokens:
    case +name <> after_name:
      match name:
        case Lexer.TokenInfo{ Lexer.NameToken{},  key,  key_beg,  key_end,  _,  _}:
          match after_name:
            case +colon <> after_colon:
              match colon:
                case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
                  with_term_law_clauses(parse_term(file, after_colon, scope, depth, 0n), ty => after_ty => ok_ty => parse_law_clause_type_result(ok_ty, ty, after_ty, file, key, key_beg, key_end, beg, universal, quantity, scope, depth, acc))
                case _:
                  ((((List.reverse(&2, Ast.Clause, acc), after_name), scope), depth), False{})
            case Nil{}:
              ((((List.reverse(&2, Ast.Clause, acc), after_name), scope), depth), False{})
        case _:
          ((((List.reverse(&2, Ast.Clause, acc), tokens), scope), depth), False{})
    case Nil{}:
      ((((List.reverse(&2, Ast.Clause, acc), []), scope), depth), False{})

def parse_law_clause_condition_result(ok_condition: Bool, +condition: Ast.SyntaxTerm, after_condition: List<&2, Lexer.Token>, +file: String, beg: Nat, universal: Bool, quantity: Ast.Quantity, key: String, key_beg: Nat, ty: Ast.SyntaxTerm, next_scope: List<&2, Scope>, next_depth: Nat, acc: List<&2, Ast.Clause>) -> (((List<&2, Ast.Clause> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool:
  match ok_condition:
    case True{}:
      clause = { Ast.ClauseFor{universal, quantity, key, ty, Some{condition}, span(file, key_beg, token_end_first(condition))} : Ast.Clause }
      parse_law_clauses(file, after_condition, next_scope, next_depth, clause <> acc)
    case False{}:
      ((((List.reverse(&2, Ast.Clause, acc), after_condition), next_scope), next_depth), False{})

def parse_law_clause_condition_scan(+file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, beg: Nat, universal: Bool, quantity: Ast.Quantity, key: String, key_beg: Nat, key_end: Nat, ty: Ast.SyntaxTerm, +next_scope: List<&2, Scope>, +next_depth: Nat, acc: List<&2, Ast.Clause>) -> (((List<&2, Ast.Clause> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool:
  match scanned:
    case +where_token <> after_where:
      match where_token:
        case Lexer.TokenInfo{ _, "where",  _,  _,  _,  _}:
          with_term_law_clauses(parse_term(file, after_where, next_scope, next_depth, 0n), condition => after_condition => ok_condition => parse_law_clause_condition_result(ok_condition, condition, after_condition, file, beg, universal, quantity, key, key_beg, ty, next_scope, next_depth, acc))
        case _:
          finish_law_clause(file, tokens, beg, universal, quantity, key, key_beg, key_end, ty, next_scope, next_depth, acc)
    case Nil{}:
      finish_law_clause(file, Nil{}, beg, universal, quantity, key, key_beg, key_end, ty, next_scope, next_depth, acc)

def parse_law_clause_condition(file: String, +tokens: List<&2, Lexer.Token>, beg: Nat, universal: Bool, quantity: Ast.Quantity, key: String, key_beg: Nat, key_end: Nat, ty: Ast.SyntaxTerm, next_scope: List<&2, Scope>, next_depth: Nat, acc: List<&2, Ast.Clause>) -> (((List<&2, Ast.Clause> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool:
  parse_law_clause_condition_scan(file, tokens, skip_lines(tokens), beg, universal, quantity, key, key_beg, key_end, ty, next_scope, next_depth, acc)

def finish_law_clause(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, universal: Bool, quantity: Ast.Quantity, key: String, key_beg: Nat, key_end: Nat, +ty: Ast.SyntaxTerm, next_scope: List<&2, Scope>, next_depth: Nat, acc: List<&2, Ast.Clause>) -> (((List<&2, Ast.Clause> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool:
  match universal:
    case True{}:
      clause = { Ast.ClauseFor{ True{}, quantity, key, ty,  None{},  span(file, key_beg, token_end_first(ty))} : Ast.Clause }
      parse_law_clauses(file, tokens, next_scope, next_depth, clause <> acc)
    case False{}:
      clause = { Ast.ClauseFor{ False{},  Ast.QOne{}, key, ty,  None{},  span(file, key_beg, token_end_first(ty))} : Ast.Clause }
      parse_law_clauses(file, tokens, next_scope, next_depth, clause <> acc)

def parse_law_decl(+file: String, tokens: List<&2, Lexer.Token>, +beg: Nat) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match tokens:
    case +name <> after_name:
      match name:
        case Lexer.TokenInfo{ Lexer.NameToken{},  key,  _,  _,  _,  _}:
          match after_name:
            case +colon <> +after_colon:
              match colon:
                case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
                  with_law_clauses_result(parse_law_clauses(file, after_colon, Nil{}, 0n, Nil{}), clauses => after_clauses => scope => depth => ok_clauses => parse_law_clauses_result(ok_clauses, clauses, after_clauses, scope, depth, file, key, beg, colon, after_colon))
                case _:
                  law_failure(file, key, beg, token_beg(colon), after_name)
            case Nil{}:
              law_failure(file, key, beg, beg, after_name)
        case _:
          law_failure(file, "", beg, token_end(name), tokens)
    case Nil{}:
      law_failure(file, "", beg, beg, Nil{})

def top_owner_set(top: Ast.TopLevel, owners: Map<&2, TopOwner>) -> Map<&2, TopOwner>:
  match top:
    case Ast.DefTop{Ast.Definition{key, _, _, _, _, _}}:
      Map.set(&2, TopOwner, owners, key, TopOwnerClosed{})
    case Ast.TypeTop{Ast.TypeDecl{key, _, _, _, _}}:
      Map.set(&2, TopOwner, owners, key, TopOwnerClosed{})
    case Ast.LawTop{Ast.LawDecl{key, _, _, _}}:
      Map.set(&2, TopOwner, owners, key, TopOwnerLaw{})

def top_owners_seed(acc: List<&2, Ast.TopLevel>, owners: Map<&2, TopOwner>) -> Map<&2, TopOwner>:
  match acc:
    case top <> rest:
      top_owner_set(top, top_owners_seed(rest, owners))
    case Nil{}:
      owners

def top_owner_query(top: Ast.TopLevel, owners: Map<&2, TopOwner>) -> Map<&2, TopOwner> & TopOwner:
  match top:
    case Ast.DefTop{Ast.Definition{key, _, _, _, _, _}}:
      Map.get(TopOwner, TopOwnerNone{}, owners, key)
    case Ast.TypeTop{Ast.TypeDecl{key, _, _, _, _}}:
      Map.get(TopOwner, TopOwnerNone{}, owners, key)
    case Ast.LawTop{Ast.LawDecl{key, _, _, _}}:
      Map.get(TopOwner, TopOwnerNone{}, owners, key)

def law_header_end(tokens: List<&2, Lexer.Token>) -> Bool:
  match tokens:
    case Lexer.TokenInfo{Lexer.NewlineToken{}, _, _, _, _, _} <> rest:
      law_header_end(rest)
    case Lexer.TokenInfo{_, ":", _, _, _, _} <> _:
      True{}
    case _:
      False{}

def law_header_bare(tokens: List<&2, Lexer.Token>) -> Bool:
  match tokens:
    case Lexer.TokenInfo{Lexer.NameToken{}, _, _, _, _, _} <> rest:
      law_header_bare(rest)
    case Lexer.TokenInfo{Lexer.NewlineToken{}, _, _, _, _, _} <> rest:
      law_header_bare(rest)
    case Lexer.TokenInfo{_, "(", _, _, _, _} <> rest:
      law_header_bare(rest)
    case Lexer.TokenInfo{_, ")", _, _, _, _} <> rest:
      law_header_end(rest)
    case Lexer.TokenInfo{_, ",", _, _, _, _} <> rest:
      law_header_bare(rest)
    case _:
      False{}

def top_owner_valid(top: Ast.TopLevel, owner: TopOwner, header: List<&2, Lexer.Token>) -> Bool:
  match top:
    case Ast.DefTop{Ast.Definition{_, _, Ast.NoTerm{}, _, _, _}}:
      match owner:
        case TopOwnerLaw{}: law_header_bare(header)
        case _: False{}
    case Ast.DefTop{Ast.Definition{_, _, Ast.SomeTerm{_}, _, _, _}}:
      match owner:
        case TopOwnerNone{}: True{}
        case _: False{}
    case Ast.TypeTop{_}:
      match owner:
        case TopOwnerNone{}: True{}
        case _: False{}
    case Ast.LawTop{_}:
      match owner:
        case TopOwnerNone{}: True{}
        case _: False{}

def top_owner_checked_result(query: Map<&2, TopOwner> & TopOwner, top: Ast.TopLevel, ok: Bool, header: List<&2, Lexer.Token>) -> Map<&2, TopOwner> & Bool:
  match query:
    case (owners, owner):
      (owners, Bool.and(ok, top_owner_valid(top, owner, header)))

def parse_top_result(validation: Map<&2, TopOwner> & Bool, +top: Ast.TopLevel, +after: List<&2, Lexer.Token>, tokens: List<&2, Lexer.Token>, file: String, path: String, acc: List<&2, Ast.TopLevel>) -> (List<&2, Ast.TopLevel> & Bool) & List<&2, Lexer.Token>:
  match validation:
    case (owners, ok):
      match ok:
        case True{}:
          parse_top_scan(file, after, skip_lines(after), path, top <> acc, top_owner_set(top, owners))
        case False{}:
          ((List.reverse(&2, Ast.TopLevel, top <> acc), False{}), after)

def parse_top_scan(+file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +path: String, acc: List<&2, Ast.TopLevel>, owners: Map<&2, TopOwner>) -> (List<&2, Ast.TopLevel> & Bool) & List<&2, Lexer.Token>:
  match scanned:
    case +token <> +rest:
      match token:
        case Lexer.TokenInfo{ Lexer.EndToken{},  _,  _,  _,  _,  _}:
          ((List.reverse(&2, Ast.TopLevel, acc), True{}), rest)
        case Lexer.TokenInfo{ Lexer.ErrorToken{},  _,  _,  _,  _,  _}:
          ((List.reverse(&2, Ast.TopLevel, acc), False{}), tokens)
        case Lexer.TokenInfo{ Lexer.NameToken{},  "law", beg,  _,  _,  _}:
          with_top_item_result(parse_law_decl(file, rest, beg), +top => after => ok => parse_top_result(top_owner_checked_result(top_owner_query(top, owners), top, ok, rest), top, after, tokens, file, path, acc))
        case Lexer.TokenInfo{ Lexer.NameToken{},  "type", beg,  _,  _, col}:
          with_top_item_result(parse_type_decl(file, rest, beg, col), +top => after => ok => parse_top_result(top_owner_checked_result(top_owner_query(top, owners), top, ok, rest), top, after, tokens, file, path, acc))
        case Lexer.TokenInfo{ Lexer.SymbolToken{},  "@",  _,  _,  _,  _}:
          with_top_item_result(parse_unsafe(file, rest, path), +top => after => ok => parse_top_result(top_owner_checked_result(top_owner_query(top, owners), top, ok, rest), top, after, tokens, file, path, acc))
        case Lexer.TokenInfo{ Lexer.NameToken{},  "def", beg, end, line, col}:
          with_top_item_result(parse_definition(file, Lexer.TokenInfo{Lexer.NameToken{}, "def", beg, end, line, col} <> rest, path), +top => after => ok => parse_top_result(top_owner_checked_result(top_owner_query(top, owners), top, ok, rest), top, after, tokens, file, path, acc))
        case _:
          ((List.reverse(&2, Ast.TopLevel, acc), False{}), tokens)
    case Nil{}:
      ((List.reverse(&2, Ast.TopLevel, acc), False{}), Nil{})

def parse_top(file: String, +tokens: List<&2, Lexer.Token>, path: String, +acc: List<&2, Ast.TopLevel>) -> (List<&2, Ast.TopLevel> & Bool) & List<&2, Lexer.Token>:
  parse_top_scan(file, tokens, skip_lines(tokens), path, acc, top_owners_seed(acc, Map.new(&2, TopOwner)))

def observed(tokens: List<&2, Lexer.Token>) -> String:
  match tokens:
    case +token <> _:
      match token:
        case Lexer.TokenInfo{ Lexer.EndToken{},  _,  _,  _,  _,  _}:
          "end of input"
        case _:
          token_text(token)
    case Nil{}:
      "end of input"

law parse:
  for file: String
  for source: String
  ParseResult

def error_span(file: String, tokens: List<&2, Lexer.Token>) -> Ast.SourceSpan:
  match tokens:
    case +token <> _:
      span(file, token_beg(token), token_end(token))
    case Nil{}:
      span(file, 0n, 0n)
def parse_module_declarations_result(ok: Bool, declarations: List<&2, Ast.TopLevel>, +rest: List<&2, Lexer.Token>, file: String, imports: List<&2, Ast.ModuleImport>) -> ParseResult:
  match ok:
    case True{}:
      ParseSuccess{ Ast.Module{ file, imports, declarations}}
    case False{}:
      ParseFailure{ "invalid or unsupported top-level syntax", "a supported declaration", observed(rest), error_span(file, rest)}

def parse_module_imports_result(imports_ok: Bool, imports: List<&2, Ast.ModuleImport>, +after_imports: List<&2, Lexer.Token>, +file: String) -> ParseResult:
  match imports_ok:
    case True{}:
      with_top_declarations_result(parse_top(file, after_imports, file, Nil{}), declarations => ok => rest => parse_module_declarations_result(ok, declarations, rest, file, imports))
    case False{}:
      ParseFailure{ "invalid module import", "import path with optional as-name", observed(after_imports), error_span(file, after_imports)}

def parse_module_tokens(tokens: List<&2, Lexer.Token>, +file: String) -> ParseResult:
  match tokens:
    case +_ <> _:
      with_imports_result(parse_imports(file, tokens, Nil{}), imports => after_imports => imports_ok => parse_module_imports_result(imports_ok, imports, after_imports, file))
    case Nil{}:
      ParseFailure{ "empty lexer output", "a source token", "end of input", span(file, 0n, 0n)}

def parse(file, source):
  parse_module_tokens(combine_symbols(Lexer.tokens(source), SymbolCombineScan{}), file)

