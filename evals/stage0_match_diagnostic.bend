# Frozen stage0 compiler diagnostic; eight-row subset, not a replacement parser.
# Read via readParserGraph with canonical datatype/import resolution.
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


type FloatScanStep is Data:
  FloatScanContinue{mantissa: Nat, fractional: Nat, dot_seen: Bool, in_exponent: Bool, exponent: Nat, exponent_negative: Bool, exponent_sign: Bool, mantissa_digit: Bool, exponent_digit: Bool, valid: Bool}
  FloatScanDone{parts: FloatParts}


type StringCharsInput is Data:
  StringCharsText{char: Char}
  StringCharsBackslash{}
  StringCharsValue{value: Nat}
  StringCharsUnicodeStart{}
  StringCharsUnicodeDigits{acc: Nat}
  StringCharsInvalidEscape{}
  StringCharsInvalidUnicode{}


type SyntaxWordStep is Data:
  SyntaxWordZeroBit{}
  SyntaxWordOneBit{}
  SyntaxWordInvalidBit{}
  SyntaxWordOther{}


type PowerDepthStep is Data:
  PowerDepthZero{}
  PowerDepthDone{}
  PowerDepthContinue{half: Nat}
  PowerDepthInvalid{}


law parse:
  for file: String
  for source: String
  ParseResult


def pattern_scan(+tokens: List<&2, Lexer.Token>, +file: String, mode: PatternScanMode, frames: List<&2, PatternFrame>, +scope: List<&2, Scope>, +depth: Nat, goal: PatternScanGoal) -> PatternScanOutcome:
  match tokens mode:
    case Lexer.TokenInfo{Lexer.SymbolToken{}, "+", beg, ignored_end, ignored_line, ignored_col} <> +rest PatternExpect{Ast.QOne{}, +ignored_beg}:
      pattern_scan(rest, file, PatternExpect{Ast.QMany{}, beg}, frames, scope, depth, goal)
    case Lexer.TokenInfo{_, "-", beg, end, _, _} <> +rest PatternExpect{Ast.QOne{}, _}:
      pattern_finish(goal, Ast.PatternVar{"", depth, Ast.QOne{}, span(file, beg, end)}, tokens, scope, depth, False{})
    case Lexer.TokenInfo{Lexer.NameToken{}, key, beg, end, _, _} <> (Lexer.TokenInfo{_, "{", _, _, _, _} <> +after_open) PatternExpect{Ast.QOne{}, _}:
      pattern_scan(after_open, file, PatternExpect{Ast.QOne{}, 0n}, PatternFrameOf{key, beg, end, Nil{}, scope, depth} <> frames, scope, depth, goal)
    case Lexer.TokenInfo{Lexer.NameToken{}, key, _, end, _, _} <> (Lexer.TokenInfo{_, "{", _, _, _, _} <> +after_open) PatternExpect{quantity, beg}:
      pattern_scan(after_open, file, PatternExpect{Ast.QOne{}, 0n}, PatternFrameOf{key, beg, end, Nil{}, scope, depth} <> frames, scope, depth, goal)
    case Lexer.TokenInfo{Lexer.NameToken{}, +key, beg, end, _, _} <> +rest PatternExpect{Ast.QOne{}, _}:
      pattern_scan(rest, file, PatternCompleted{Ast.PatternVar{key, depth, Ast.QOne{}, span(file, beg, end)}}, frames, extend_scope(key, depth, scope), depth + 1n, goal)
    case Lexer.TokenInfo{Lexer.NameToken{}, +key, _, end, _, _} <> +rest PatternExpect{quantity, beg}:
      pattern_scan(rest, file, PatternCompleted{Ast.PatternVar{key, depth, quantity, span(file, beg, end)}}, frames, extend_scope(key, depth, scope), depth + 1n, goal)
    case Lexer.TokenInfo{Lexer.NumberToken{}, +text, +beg, +end, line, col} <> +rest PatternExpect{quantity, _}:
      pattern_scan(rest, file, pattern_number_mode(has_nat_suffix(text), file, text, beg, end, line, col, quantity), frames, scope, depth, goal)
    case _ PatternNoNat{number, quantity, beg, end}:
      pattern_finish(goal, Ast.PatternVar{"", depth, quantity, span(file, beg, end)}, number <> tokens, scope, depth, False{})
