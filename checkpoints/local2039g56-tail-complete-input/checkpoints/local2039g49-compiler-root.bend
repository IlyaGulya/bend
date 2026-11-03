# EXPERIMENTAL / FUEL-PARAMETRIC / NOT SELFHOST GREEN

import Base
import ../bend2/selfhost/ast.bend as Ast
import ../bend2/selfhost/lexer.bend as Lexer
import ../bend2/selfhost/core.bend as Core

import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/backend_ir.bend as BIR
import ../bend2/selfhost/checked_frontend.bend as Checked
import ./template_steps_v1.bend as Template

import ./emitter_steps_v1.bend as Emit

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
  FloatParts{mantissa: List<&2, Nat>, scale_negative: Bool, scale: Nat, valid: Bool}

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
  FloatScanContinue{mantissa: List<&2, Nat>, fractional: Nat, dot_seen: Bool, in_exponent: Bool, exponent: Nat, exponent_negative: Bool, exponent_sign: Bool, mantissa_digit: Bool, exponent_digit: Bool, valid: Bool}
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

type MatchTailScanAction is Data:
  MatchTailScanRow0{}
  MatchTailScanRow1{}
  MatchTailScanRow2{}

type PatternScanContext is Data:
  PatternScanContext{file: String, tokens: List<&2, Lexer.Token>, frames: List<&2, PatternFrame>, scope: List<&2, Scope>, depth: Nat, goal: PatternScanGoal}

type PatternExpectAction is Data:
  PatternExpectActionRow0{}
  PatternExpectActionRow1{}
  PatternExpectActionRow2{}
  PatternExpectActionRow3{}
  PatternExpectActionRow4{}
  PatternExpectActionRow5{}
  PatternExpectActionRow6{}
  PatternExpectActionRow7{}
  PatternExpectActionRow8{}
  PatternExpectActionRow9{quantity: Ast.Quantity}
  PatternExpectActionRow10{}
  PatternExpectActionRow12{quantity: Ast.Quantity}
  PatternExpectActionRow13{quantity: Ast.Quantity}
  PatternExpectActionRow14{quantity: Ast.Quantity}
  PatternExpectActionRow25{quantity: Ast.Quantity}

type PatternCompletedText is Data:
  PatternCompletedTextRow15{}
  PatternCompletedTextRow16{}
  PatternCompletedTextRow17{}
  PatternCompletedTextRow18{}
  PatternCompletedTextRow19{}
  PatternCompletedTextRow23{}
  PatternCompletedTextOther{}

type DoTokenAction is Data:
  DoTokenActionRow0{}
  DoTokenActionRow1{}
  DoTokenActionRow2{}

type ArrayShapeAction is Data:
  ArrayShapeActionRow0{}
  ArrayShapeActionRow1{}
  ArrayShapeActionRow2{}

type BraceEqualsAction is Data:
  BraceEqualsActionRow0{}
  BraceEqualsActionRow1{}
  BraceEqualsActionRow2{}
  BraceEqualsActionRow3{}

type BodyScanAction is Data:
  BodyScanActionRow0{}
  BodyScanActionRow1{}
  BodyScanActionRow2{}
  BodyScanActionRow3{}
  BodyScanActionRow4{}
  BodyScanActionRow5{}
  BodyScanActionRow6{}

type DefinitionHeaderAction is Data:
  DefinitionHeaderRow0{}
  DefinitionHeaderRow1{}
  DefinitionHeaderRow2{}

type FeedbackValue is Data:
  Value_0{result_0_0_0_0: List<&2, Ast.Clause>, result_0_0_0_1: List<&2, Lexer.Token>, result_0_0_1: List<&2, Scope>, result_0_1: Nat, result_1: Bool}
  Value_1{result_0_0_0_0: List<&2, Ast.TelescopeItem>, result_0_0_0_1: List<&2, Lexer.Token>, result_0_0_1: List<&2, Scope>, result_0_1: Nat, result_1: Bool}
  Value_2{result_0_0_0: List<&2, Ast.SyntaxTerm>, result_0_0_1: List<&2, Lexer.Token>, result_0_1: Nat, result_1: Bool}
  Value_3{result_0_0: Ast.DefBody, result_0_1: List<&2, Lexer.Token>, result_1: Bool}
  Value_4{result_0_0: Ast.SyntaxPattern, result_0_1: List<&2, Lexer.Token>, result_1_0_0: List<&2, Scope>, result_1_0_1: Nat, result_1_1: Bool}
  Value_5{result_0_0: Ast.SyntaxTerm, result_0_1: List<&2, Lexer.Token>, result_1: Bool}
  Value_6{result_0_0: Ast.TopLevel, result_0_1: List<&2, Lexer.Token>, result_1: Bool}
  Value_7{result_0_0: List<&2, Ast.ConstructorDecl>, result_0_1: List<&2, Lexer.Token>, result_1: Bool}
  Value_8{result_0_0: List<&2, Ast.ModuleImport>, result_0_1: List<&2, Lexer.Token>, result_1: Bool}
  Value_9{result_0_0: List<&2, Ast.SyntaxTerm>, result_0_1: List<&2, Lexer.Token>, result_1: Bool}
  Value_10{result_0_0: List<&2, Ast.TopLevel>, result_0_1: Bool, result_1: List<&2, Lexer.Token>}
  Value_11{result: Ast.SyntaxTerm}
  Value_12{result: List<&2, Ast.SyntaxTerm>}
  Value_13{result: Maybe<&2, Ast.SyntaxPattern>}
  Value_14{result: Maybe<&2, List<&2, Ast.SyntaxPattern>>}
  Value_15{result: Maybe<&2, Nat>}
  Value_16{result: Nat}
  Value_17{result: ParseResult}
  Value_18{result: PatternScanOutcome}

type Progress is Data:
  NoProgress{}
  Consumed{}

type FeedbackCursorWitness is Data:
  WitnessNone{}
  WitnessTail{progress: Progress}
  WitnessFields{fields: List<&2, FeedbackCursorWitness>}

type FeedbackFrame is Data:
  KontProgress{}
  Kont_80664{capture_1: Nat}
  Kont_82236{capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Lexer.Token>, capture_6: Ast.SyntaxTerm}
  Kont_85539{capture_0: List<&2, Ast.SyntaxTerm>, capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: String, capture_4: Nat}
  Kont_88585{capture_0: Ast.SourceSpan, capture_1: Ast.SyntaxTerm, capture_2: Ast.SyntaxTerm}
  Kont_88855{capture_0: Ast.SourceSpan, capture_1: Ast.SyntaxTerm, capture_2: Ast.SyntaxTerm}
  Kont_91075{capture_0: List<&2, Ast.SyntaxPattern>, capture_1: Ast.Quantity, capture_2: Ast.SourceSpan, capture_3: List<&2, Ast.SyntaxTerm>}
  Kont_91520{capture_0: Ast.SourceSpan, capture_1: List<&2, Ast.SyntaxTerm>}
  Kont_91796{capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: Ast.SourceSpan, capture_3: Ast.SyntaxTerm}
  Kont_92071{capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: Ast.SourceSpan, capture_3: Ast.SyntaxTerm}
  Kont_92333{capture_0: String, capture_1: Ast.SourceSpan, capture_2: Ast.SyntaxTerm}
  Kont_92756{capture_0: Ast.SourceSpan, capture_1: Ast.SyntaxTerm}
  Kont_93007{capture_0: Ast.SourceSpan, capture_1: Ast.SyntaxTerm}
  Kont_93452{capture_0: Ast.SourceSpan, capture_1: Ast.SyntaxTerm}
  Kont_93964{capture_0: Ast.Quantity, capture_1: String, capture_2: Nat, capture_3: Ast.SourceSpan, capture_4: Ast.SyntaxTerm}
  Kont_94200{capture_0: Ast.SourceSpan, capture_1: Ast.SyntaxTerm}
  Kont_94720{capture_0: Ast.SourceSpan, capture_1: Ast.SyntaxTerm}
  Kont_95059{capture_0: List<&2, String>, capture_1: List<&2, Nat>, capture_2: List<&2, Ast.Quantity>, capture_3: Ast.SourceSpan, capture_4: List<&2, Ast.SyntaxTerm>}
  Kont_95312{capture_0: Nat, capture_1: Ast.SourceSpan, capture_2: Ast.SyntaxTerm}
  Kont_99155{capture_0: Ast.SourceSpan}
  Kont_99029{capture_0: String, capture_1: List<&2, Ast.SyntaxPattern>, capture_2: Ast.Quantity, capture_3: Ast.SyntaxTerm, capture_4: Ast.SourceSpan}
  Kont_98857{capture_0: List<&2, Ast.SyntaxPattern>, capture_1: Ast.SourceSpan}
  Kont_98718{capture_0: String, capture_1: List<&2, Ast.SyntaxTerm>, capture_2: Ast.SourceSpan}
  Kont_98504{capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: Ast.SyntaxTerm, capture_3: Ast.SourceSpan}
  Kont_98288{capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: Ast.SyntaxTerm, capture_3: Ast.SourceSpan}
  Kont_98070{capture_0: String, capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Ast.SourceSpan}
  Kont_97825{capture_0: String, capture_1: Ast.SourceSpan}
  Kont_97688{capture_0: String, capture_1: List<&2, Ast.SyntaxTerm>, capture_2: Ast.SourceSpan}
  Kont_97545{capture_0: String, capture_1: List<&2, Ast.SyntaxTerm>, capture_2: Ast.SourceSpan}
  Kont_97401{capture_0: String, capture_1: List<&2, String>, capture_2: Ast.SourceSpan}
  Kont_97251{capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: Ast.SourceSpan}
  Kont_97113{capture_0: Maybe<&2, Ast.Quantity>, capture_1: String, capture_2: Nat, capture_3: Ast.SourceSpan}
  Kont_96958{capture_0: String, capture_1: Ast.Quantity, capture_2: String, capture_3: Nat, capture_4: Ast.SyntaxTerm, capture_5: Ast.SourceSpan}
  Kont_96786{capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: Ast.SourceSpan}
  Kont_96528{capture_0: Ast.SourceSpan}
  Kont_96408{capture_0: Ast.SourceSpan}
  Kont_96284{capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: Ast.SourceSpan}
  Kont_96147{capture_0: String, capture_1: List<&2, String>, capture_2: List<&2, Nat>, capture_3: List<&2, Ast.Quantity>, capture_4: Ast.SyntaxTerm, capture_5: Ast.SourceSpan}
  Kont_95975{capture_0: String, capture_1: Nat, capture_2: Ast.SyntaxTerm, capture_3: Ast.SourceSpan}
  Kont_95827{capture_0: Ast.SourceSpan}
  Kont_99536{capture_0: Ast.SyntaxTerm}
  Kont_99780{capture_0: String, capture_1: List<&2, Ast.SyntaxTerm>}
  Kont_104727{capture_0: List<&2, Lexer.Token>}
  Kont_130860{capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: Nat, capture_5: List<&2, PatternFrame>, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: PatternScanGoal}
  Kont_136149{capture_1: Ast.SyntaxPattern}
  Kont_136385{capture_1: List<&2, Ast.SyntaxTerm>}
  Kont_136894{capture_1: String, capture_2: Ast.SourceSpan}
  Kont_138041{capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: Nat, capture_4: Nat, capture_5: List<&2, PatternFrame>, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: PatternScanGoal}
  Kont_139772{capture_1: String, capture_2: Nat, capture_3: Ast.SyntaxPattern}
  Kont_140603{capture_1: String, capture_2: Nat}
  Kont_143942{capture_1: String, capture_2: List<&2, PatternFrame>, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: PatternScanGoal}
  Kont_149840{capture_1: String, capture_2: Ast.SyntaxPattern, capture_3: List<&2, PatternFrame>, capture_4: List<&2, Scope>, capture_5: Nat, capture_6: PatternScanGoal}
  Kont_171398{capture_1: String, capture_2: Nat}
  Kont_180552{capture_1: String, capture_2: String, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Lexer.Token>, capture_6: List<&2, Scope>, capture_7: Nat}
  Kont_182168{capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Lexer.Token>}
  Kont_188249{capture_1: String, capture_2: Nat}
  Kont_188761{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Nat, capture_5: Nat}
  Kont_190088{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: Nat, capture_8: Nat, capture_9: List<&2, Scope>, capture_10: Nat, capture_11: Nat, capture_12: Maybe<&2, Ast.Quantity>}
  Kont_193205{lexical_capture_4: String, lexical_capture_6: String, lexical_capture_8: List<&2, Ast.SyntaxTerm>, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_13: Ast.SyntaxTerm, lexical_capture_31: Ast.SyntaxTerm, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_22: Nat, lexical_capture_26: Maybe<&2, Ast.Quantity>}
  Kont_194307{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Nat, capture_7: Nat, capture_8: List<&2, Scope>, capture_9: Nat, capture_10: Nat}
  Kont_195319{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: List<&2, Ast.SyntaxTerm>, lexical_capture_27: String, lexical_capture_28: Nat, lexical_capture_9: Nat, lexical_capture_11: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, lexical_capture_18: Nat}
  Kont_196508{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: Nat, capture_8: Nat, capture_9: List<&2, Scope>, capture_10: Nat, capture_11: Nat, capture_12: Maybe<&2, Ast.Quantity>}
  Kont_196192{lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: String, lexical_capture_8: String, lexical_capture_10: List<&2, Ast.SyntaxTerm>, lexical_capture_12: String, lexical_capture_14: Nat, lexical_capture_16: Nat, lexical_capture_18: Nat, lexical_capture_21: List<&2, Scope>, lexical_capture_23: Nat, lexical_capture_25: Nat}
  Kont_197434{lexical_capture_7: String, lexical_capture_13: String, lexical_capture_15: Nat, lexical_capture_24: Nat, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_3: Ast.SyntaxTerm}
  Kont_199099{lexical_capture_4: String, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_22: Nat, lexical_capture_13: Ast.SyntaxTerm, lexical_capture_29: Ast.SyntaxTerm}
  Kont_199750{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: Nat, capture_8: Nat, capture_9: List<&2, Scope>, capture_10: Nat, capture_11: Nat}
  Kont_201815{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Ast.SyntaxTerm, capture_5: Nat, capture_6: Nat, capture_7: List<&2, Scope>, capture_8: Nat, capture_9: Nat}
  Kont_202383{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Nat, capture_5: Nat, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: Nat}
  Kont_203745{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: List<&2, Ast.SyntaxTerm>, lexical_capture_6: Ast.SyntaxTerm, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_18: Nat}
  Kont_206710{capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Lexer.Token>}
  Kont_207865{capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Scope>, capture_5: Nat}
  Kont_209050{lexical_capture_4: String, lexical_capture_5: Ast.SyntaxTerm, lexical_capture_7: Nat}
  Kont_209742{capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Scope>, capture_6: Nat}
  Kont_210467{capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Ast.SyntaxTerm, capture_4: Nat, capture_5: Nat}
  Kont_210804{capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Ast.SyntaxTerm, capture_4: Nat, capture_5: Nat}
  Kont_213361{capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Lexer.Token>, capture_5: Nat, capture_6: List<&2, Scope>, capture_7: Nat}
  Kont_214597{capture_1: String, capture_2: List<&2, Lexer.Token>, capture_3: Nat, capture_4: List<&2, Scope>, capture_5: Nat}
  Kont_215020{capture_1: String, capture_2: Ast.SyntaxTerm}
  Kont_215921{capture_1: String, capture_2: List<&2, Scope>, capture_3: Nat}
  Kont_218787{capture_1: String, capture_2: String, capture_3: Nat, capture_4: List<&2, Scope>, capture_5: Nat}
  Kont_222414{lexical_capture_98: String, lexical_capture_99: String, lexical_capture_100: Ast.SyntaxTerm, lexical_capture_107: Nat}
  Kont_222088{lexical_capture_98: String, lexical_capture_99: String, lexical_capture_100: Ast.SyntaxTerm, lexical_capture_107: Nat}
  Kont_221748{lexical_capture_98: String, lexical_capture_99: String, lexical_capture_100: Ast.SyntaxTerm, lexical_capture_107: Nat}
  Kont_220917{lexical_capture_49: String, lexical_capture_50: String, lexical_capture_51: Ast.SyntaxTerm, lexical_capture_52: List<&2, Lexer.Token>, lexical_capture_53: String, lexical_capture_55: Nat, lexical_capture_56: List<&2, Scope>, lexical_capture_57: Nat}
  Kont_223608{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_8: Nat}
  Kont_223961{lexical_capture_1: String}
  Kont_224348{lexical_capture_2: String, lexical_capture_3: Ast.SyntaxTerm, lexical_capture_0: Ast.SyntaxTerm, lexical_capture_5: Nat}
  Kont_226950{lexical_capture_4: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: Nat, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat}
  Kont_227357{lexical_capture_4: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: Nat}
  Kont_230149{lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_10: List<&2, Scope>, lexical_capture_12: Nat}
  Kont_230673{lexical_capture_2: String, lexical_capture_3: Ast.SyntaxTerm, lexical_capture_0: Ast.SyntaxTerm, lexical_capture_5: Nat, lexical_capture_10: Nat}
  Kont_232475{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: Nat, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat}
  Kont_233411{lexical_capture_6: String, lexical_capture_21: String, lexical_capture_8: Nat, lexical_capture_10: Nat, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat}
  Kont_235014{lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_10: List<&2, Scope>, lexical_capture_12: Nat}
  Kont_235810{lexical_capture_7: Ast.SyntaxTerm, lexical_capture_28: Ast.SyntaxTerm, lexical_capture_6: String, lexical_capture_11: Nat}
  Kont_236486{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_4: String, lexical_capture_6: Nat, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat}
  Kont_239509{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_20: List<&2, Lexer.Token>}
  Kont_239269{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_14: Nat}
  Kont_242904{lexical_capture_3: String, lexical_capture_8: List<&2, Lexer.Token>, lexical_capture_10: String, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: List<&2, Ast.SyntaxTerm>}
  Kont_244597{lexical_capture_2: String, lexical_capture_4: String, lexical_capture_6: Nat, lexical_capture_8: Nat, lexical_capture_9: Ast.Quantity, lexical_capture_0: Ast.SyntaxTerm, lexical_capture_22: Nat}
  Kont_246785{lexical_capture_1: String, lexical_capture_23: String, lexical_capture_25: Nat, lexical_capture_10: Nat, lexical_capture_11: Ast.Quantity, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat}
  Kont_248037{lexical_capture_1: String, lexical_capture_22: String, lexical_capture_5: Nat, lexical_capture_24: Nat, lexical_capture_10: Nat}
  Kont_249845{lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat}
  Kont_251155{lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_6: Nat, lexical_capture_7: Lexer.Token}
  Kont_251648{capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: List<&2, Lexer.Token>, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: Nat}
  Kont_251939{lexical_capture_1: String, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat, lexical_capture_10: Nat, lexical_capture_3: List<&2, Lexer.Token>}
  Kont_254771{capture_0: List<&2, Ast.SyntaxTerm>, capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: Ast.SyntaxTerm, capture_4: List<&2, Scope>, capture_5: Nat, capture_6: Nat}
  Kont_255415{lexical_capture_3: String, lexical_capture_30: Ast.SyntaxTerm, lexical_capture_5: Lexer.Token, lexical_capture_15: List<&2, Scope>, lexical_capture_17: Nat, lexical_capture_19: Nat, lexical_capture_7: List<&2, Lexer.Token>}
  Kont_261611{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_18: Lexer.Token, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: Nat, lexical_capture_19: List<&2, Lexer.Token>}
  Kont_258147{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: Nat, lexical_capture_39: Nat}
  Kont_264079{lexical_capture_6: String, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_9: Lexer.Token, lexical_capture_20: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, lexical_capture_18: Nat, lexical_capture_11: List<&2, Lexer.Token>}
  Kont_265540{capture_0: List<&2, Ast.SyntaxTerm>, capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: Ast.SyntaxTerm, capture_4: List<&2, Scope>, capture_5: Nat, capture_6: Nat}
  Kont_266451{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_4: List<&2, Lexer.Token>, lexical_capture_6: List<&2, Lexer.Token>, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat}
  Kont_270490{lexical_capture_3: String, lexical_capture_5: String, lexical_capture_8: Ast.SyntaxTerm, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_19: Nat}
  Kont_271785{lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat}
  Kont_272903{capture_0: Bool, capture_1: Ast.SyntaxTerm, capture_2: List<&2, Lexer.Token>, capture_3: Bool, capture_4: String, capture_5: Ast.SyntaxTerm, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: Nat}
  Kont_274182{lexical_capture_17: Bool, lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat, lexical_capture_6: List<&2, Lexer.Token>}
  Kont_276726{lexical_capture_6: String, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_8: Ast.SyntaxTerm, lexical_capture_10: Nat, lexical_capture_12: Nat, lexical_capture_15: List<&2, Scope>, lexical_capture_17: Nat, lexical_capture_19: Nat}
  Kont_277885{capture_0: List<&2, Lexer.Token>, capture_1: String, capture_2: Ast.SyntaxTerm, capture_4: Nat, capture_5: Nat, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: Nat}
  Kont_279668{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat}
  Kont_282173{lexical_capture_3: String, lexical_capture_5: String, lexical_capture_8: Ast.SyntaxTerm, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_19: Nat}
  Kont_292785{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, lexical_capture_17: Ast.Quantity}
  Kont_293503{lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: String, lexical_capture_8: String, lexical_capture_10: Nat, lexical_capture_12: Nat, lexical_capture_14: Nat, lexical_capture_17: List<&2, Scope>, lexical_capture_19: Nat, lexical_capture_20: Ast.Quantity}
  Kont_296071{lexical_capture_1: String}
  Kont_297632{capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: List<&2, Ast.SyntaxPattern>, capture_6: Nat, capture_7: List<&2, Ast.SyntaxTerm>}
  Kont_299524{lexical_capture_3: List<&2, Ast.SyntaxPattern>, lexical_capture_8: List<&2, Scope>, lexical_capture_10: Nat, lexical_capture_12: String, lexical_capture_14: Nat, lexical_capture_16: Nat, lexical_capture_22: Ast.Quantity}
  Kont_300984{lexical_capture_3: List<&2, Ast.SyntaxTerm>, lexical_capture_7: List<&2, Ast.SyntaxPattern>, lexical_capture_13: Ast.Quantity, lexical_capture_15: String, lexical_capture_17: Nat}
  Kont_301643{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, lexical_capture_17: Ast.Quantity}
  Kont_303223{lexical_capture_3: String, lexical_capture_5: String, lexical_capture_7: Nat, lexical_capture_10: Ast.SyntaxPattern, lexical_capture_19: Ast.Quantity, lexical_capture_11: Ast.SyntaxTerm}
  Kont_303846{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat}
  Kont_306294{lexical_capture_3: String, lexical_capture_5: List<&2, Lexer.Token>, lexical_capture_7: Nat, lexical_capture_9: Nat, lexical_capture_12: List<&2, Scope>, lexical_capture_14: Nat}
  Kont_307113{lexical_capture_4: Ast.SyntaxPattern, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: String, lexical_capture_13: List<&2, Lexer.Token>, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_20: List<&2, Scope>, lexical_capture_22: Nat}
  Kont_308366{lexical_capture_2: Ast.SyntaxTerm, lexical_capture_5: Ast.SyntaxPattern, lexical_capture_12: String, lexical_capture_14: Nat}
  Kont_308948{lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_10: List<&2, Scope>, lexical_capture_12: Nat}
  Kont_309436{lexical_capture_1: List<&2, Ast.SyntaxTerm>, lexical_capture_13: Lexer.Token, lexical_capture_3: String, lexical_capture_5: Nat}
  Kont_312599{lexical_capture_1: String, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat, lexical_capture_10: List<&2, Ast.SyntaxTerm>}
  Kont_313186{lexical_capture_3: String, lexical_capture_5: List<&2, Lexer.Token>, lexical_capture_9: Nat, lexical_capture_12: List<&2, Scope>, lexical_capture_14: Nat, lexical_capture_16: Nat, lexical_capture_18: List<&2, Ast.SyntaxTerm>}
  Kont_316227{capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: Nat}
  Kont_317252{lexical_capture_5: List<&2, Ast.SyntaxPattern>, lexical_capture_3: String, lexical_capture_15: Nat}
  Kont_322498{capture_0: String, capture_1: List<&2, Ast.TelescopeItem>, capture_2: List<&2, Scope>, capture_3: Nat, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: List<&2, Lexer.Token>, capture_8: Nat}
  Kont_323146{capture_1: String, capture_2: List<&2, Ast.TelescopeItem>, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: String, capture_6: Nat, capture_7: List<&2, Lexer.Token>}
  Kont_325947{capture_0: String, capture_1: String, capture_2: Ast.Quantity, capture_3: Nat, capture_4: List<&2, Ast.TelescopeItem>, capture_5: List<&2, Scope>, capture_6: Nat, capture_7: Ast.SyntaxTerm, capture_8: List<&2, Lexer.Token>, capture_9: Nat}
  Kont_326599{capture_1: String, capture_2: String, capture_3: Ast.Quantity, capture_4: Nat, capture_5: List<&2, Ast.TelescopeItem>, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: List<&2, Lexer.Token>}
  Kont_328193{}
  Kont_329864{lexical_capture_0: Lexer.Token, lexical_capture_2: List<&2, Lexer.Token>, lexical_capture_8: String, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_14: List<&2, Ast.TelescopeItem>, lexical_capture_5: Ast.SyntaxTerm}
  Kont_331293{capture_1: Lexer.Token, capture_2: String, capture_3: String, capture_4: Nat, capture_5: List<&2, Ast.TelescopeItem>, capture_6: List<&2, Scope>, capture_7: Nat}
  Kont_331662{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: List<&2, Ast.TelescopeItem>, lexical_capture_13: Lexer.Token, lexical_capture_15: List<&2, Lexer.Token>}
  Kont_334657{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat}
  Kont_339962{}
  Kont_339827{}
  Kont_342579{lexical_capture_3: String, lexical_capture_26: Lexer.Token, lexical_capture_27: List<&2, Lexer.Token>, lexical_capture_9: Nat, lexical_capture_12: List<&2, Scope>, lexical_capture_14: Nat, lexical_capture_16: List<&2, Ast.ConstructorDecl>, lexical_capture_18: String, lexical_capture_20: Nat}
  Kont_344635{lexical_capture_6: String, lexical_capture_8: String, lexical_capture_10: Nat, lexical_capture_14: List<&2, Ast.TelescopeItem>, lexical_capture_2: Ast.SyntaxTerm}
  Kont_345467{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: List<&2, Ast.TelescopeItem>, lexical_capture_11: List<&2, Lexer.Token>, lexical_capture_16: List<&2, Scope>, lexical_capture_18: Nat}
  Kont_347534{lexical_capture_26: Lexer.Token, lexical_capture_1: String, lexical_capture_19: String, lexical_capture_5: Nat, lexical_capture_7: Nat}
  Kont_347068{lexical_capture_26: Lexer.Token, lexical_capture_1: String, lexical_capture_19: String, lexical_capture_5: Nat, lexical_capture_7: Nat}
  Kont_349565{lexical_capture_12: String, lexical_capture_14: String, lexical_capture_3: List<&2, Ast.Clause>, lexical_capture_16: Nat, lexical_capture_17: Lexer.Token, lexical_capture_5: List<&2, Lexer.Token>}
  Kont_353513{lexical_capture_1: String, lexical_capture_31: String, lexical_capture_32: Nat, lexical_capture_33: Nat, lexical_capture_5: Nat, lexical_capture_7: Bool, lexical_capture_8: Ast.Quantity, lexical_capture_11: List<&2, Scope>, lexical_capture_13: Nat, lexical_capture_15: List<&2, Ast.Clause>}
  Kont_355479{lexical_capture_1: String, lexical_capture_7: Nat, lexical_capture_9: Bool, lexical_capture_10: Ast.Quantity, lexical_capture_12: String, lexical_capture_14: Nat, lexical_capture_17: Ast.SyntaxTerm, lexical_capture_20: List<&2, Scope>, lexical_capture_22: Nat, lexical_capture_24: List<&2, Ast.Clause>}
  Kont_357785{lexical_capture_1: String, lexical_capture_17: String, lexical_capture_5: Nat, lexical_capture_24: Lexer.Token, lexical_capture_25: List<&2, Lexer.Token>}
  Kont_363271{lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>}
  Kont_362980{lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>}
  Kont_362687{lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>}
  Kont_362397{lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>}
  Kont_365172{lexical_capture_7: String, lexical_capture_3: List<&2, Ast.ModuleImport>}
  Kont_365625{lexical_capture_3: String}

type FeedbackKont is Data:
  FeedbackKont{frame: FeedbackFrame, progress: Progress}

type FeedbackRequest is Data:
  Request_consumed_token_end_before{tokens: List<&2, Lexer.Token>, stop: Nat, fallback: Nat}
  Request_literal_pattern_fields{terms: List<&2, Ast.SyntaxTerm>}
  Request_map_operator_term{v_0: Ast.SyntaxTerm, v_2: String}
  Request_map_operator_terms{v_1: List<&2, Ast.SyntaxTerm>, v_3: String}
  Request_nat_literal_tokens_next{done: Bool, token: Lexer.Token, more: List<&2, Lexer.Token>, value: Nat, end: Nat, stop: Nat}
  Request_parse_atom_scan{file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat}
  Request_parse_body_scan{file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, parent_col: Nat}
  Request_parse_case_row_indented{is_indented: Bool, file: String, tokens: List<&2, Lexer.Token>, rest: List<&2, Lexer.Token>, parent_col: Nat, scope: List<&2, Scope>, depth: Nat, arity: Nat, acc: List<&2, Ast.SyntaxTerm>, beg: Nat, col: Nat}
  Request_parse_def_binders_scan{file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.TelescopeItem>}
  Request_parse_do_typed_bind{file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat}
  Request_parse_imports_result{ok: Bool, item: Ast.ModuleImport, after: List<&2, Lexer.Token>, file: String, acc: List<&2, Ast.ModuleImport>}
  Request_parse_law_clause_condition_scan{file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, beg: Nat, universal: Bool, quantity: Ast.Quantity, key: String, key_beg: Nat, key_end: Nat, ty: Ast.SyntaxTerm, next_scope: List<&2, Scope>, next_depth: Nat, acc: List<&2, Ast.Clause>}
  Request_parse_local_values_next{remaining: List<&2, Ast.SyntaxPattern>, file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, line: Nat, acc: List<&2, Ast.SyntaxTerm>}
  Request_parse_match_chain_state{state: MatchChainState}
  Request_parse_pattern_tuple{file: String, beg: Nat, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat}
  Request_parse_term_args_first_result{ok: Bool, term: Ast.SyntaxTerm, after: List<&2, Lexer.Token>, file: String, tokens: List<&2, Lexer.Token>, close: String, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.SyntaxTerm>}
  Request_parse_term_tail{file: String, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat}
  Request_parse_term_tail_at{file: String, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat, last_end: Nat}
  Request_parse_terms_until_colon_result{ok: Bool, term: Ast.SyntaxTerm, after: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.SyntaxTerm>}
  Request_parse_top_result{validation_0: Map<&2, TopOwner>, validation_1: Bool, top: Ast.TopLevel, after: List<&2, Lexer.Token>, tokens: List<&2, Lexer.Token>, file: String, path: String, acc: List<&2, Ast.TopLevel>}
  Request_parse_type_constructor_fields_result{ok_fields: Bool, fields: List<&2, Ast.TelescopeItem>, after_fields: List<&2, Lexer.Token>, file: String, open: Lexer.Token, after_open: List<&2, Lexer.Token>, col: Nat, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.ConstructorDecl>, key: String, beg: Nat}
  Request_pattern_scan{tokens: List<&2, Lexer.Token>, file: String, mode: PatternScanMode, frames: List<&2, PatternFrame>, scope: List<&2, Scope>, depth: Nat, goal: PatternScanGoal}

type FeedbackAction is Data:
  FeedbackCall{request: FeedbackRequest}
  FeedbackDone{value: FeedbackValue}
  FeedbackInvariant{}

type FeedbackControl is Data:
  FeedbackControl{action: FeedbackAction, pending: List<&2, FeedbackKont>, progress: Progress, own_progress: Progress}

type FeedbackResume is Data:
  FeedbackResume{control: FeedbackControl, progress: Progress, own_progress: Progress}

type FeedbackFuel is Data:
  FeedbackFuelEnd{}
  FeedbackFuelCell{tail: FeedbackFuel}

type FeedbackRun is Data:
  FeedbackComplete{value: FeedbackValue, progress: Progress}
  FeedbackInvariantFailure{progress: Progress}

def feedback_pack_16(result: Nat) -> FeedbackControl:
  FeedbackControl{FeedbackDone{Value_16{result}}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_make_consumed_token_end_before(tokens: List<&2, Lexer.Token>, stop: Nat, fallback: Nat) -> FeedbackRequest:
  Request_consumed_token_end_before{tokens, stop, fallback}

def token_end(token: Lexer.Token) -> Nat:
  match token:
    case Lexer.TokenInfo{ _,  _,  _, end,  _,  _}:
      end

def token_beg(token: Lexer.Token) -> Nat:
  match token:
    case Lexer.TokenInfo{ _,  _, beg,  _,  _,  _}:
      beg

def feedback_compose_progress(left: Progress, right: Progress) -> Progress:
  match left:
    case NoProgress{}: right
    case Consumed{}: Consumed{}

def feedback_attach_with_progress(+before: Progress, step: FeedbackControl, frame: FeedbackFrame) -> FeedbackControl:
  match step:
    case FeedbackControl{action, pending, progress, own_progress}:
      FeedbackControl{action, List.append(&2, FeedbackKont, pending, FeedbackKont{frame, before} <> Nil{}), progress, feedback_compose_progress(before, own_progress)}

def feedback_attach(step: FeedbackControl, frame: FeedbackFrame) -> FeedbackControl:
  feedback_attach_with_progress(NoProgress{}, step, frame)

def feedback_pack_14(result: Maybe<&2, List<&2, Ast.SyntaxPattern>>) -> FeedbackControl:
  FeedbackControl{FeedbackDone{Value_14{result}}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_make_literal_pattern_fields(terms: List<&2, Ast.SyntaxTerm>) -> FeedbackRequest:
  Request_literal_pattern_fields{terms}

def feedback_pack_13(result: Maybe<&2, Ast.SyntaxPattern>) -> FeedbackControl:
  FeedbackControl{FeedbackDone{Value_13{result}}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_make_map_operator_term(v_0: Ast.SyntaxTerm, v_2: String) -> FeedbackRequest:
  Request_map_operator_term{v_0, v_2}

def feedback_make_map_operator_terms(v_1: List<&2, Ast.SyntaxTerm>, v_3: String) -> FeedbackRequest:
  Request_map_operator_terms{v_1, v_3}

def feedback_pack_11(result: Ast.SyntaxTerm) -> FeedbackControl:
  FeedbackControl{FeedbackDone{Value_11{result}}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_pack_12(result: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  FeedbackControl{FeedbackDone{Value_12{result}}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_pack_15(result: Maybe<&2, Nat>) -> FeedbackControl:
  FeedbackControl{FeedbackDone{Value_15{result}}, Nil{}, NoProgress{}, NoProgress{}}

def has_nat_suffix_reversed(reversed: List<&2, Char>) -> Bool:
  match reversed:
    case +last <> _:
      Char.is_eq(last, Char.from_u32(110))
    case Nil{}:
      False{}

def has_nat_suffix(text: String) -> Bool:
  has_nat_suffix_reversed(List.reverse(&2, Char, String.to_list(text)))

def drop_nat_suffix_reversed(reversed: List<&2, Char>, text: String) -> String:
  match reversed:
    case +_ <> remaining:
      String.from_list(List.reverse(&2, Char, remaining))
    case Nil{}:
      text

# Exponent budgets are explicit decreasing first binders, not mutual recursion.

def drop_nat_suffix(+text: String) -> String:
  drop_nat_suffix_reversed(List.reverse(&2, Char, String.to_list(text)), text)

def feedback_make_nat_literal_tokens_next(done: Bool, token: Lexer.Token, more: List<&2, Lexer.Token>, value: Nat, end: Nat, stop: Nat) -> FeedbackRequest:
  Request_nat_literal_tokens_next{done, token, more, value, end, stop}

def step_nat_literal_tokens_value(found: Maybe<&2, Nat>, +end: Nat, rest: List<&2, Lexer.Token>, +stop: Nat) -> FeedbackControl:
  match found:
    case Some{+value}:
      match rest:
        case Nil{}:
          feedback_pack_15(Some{value})
        case +token <> more:
          FeedbackControl{FeedbackCall{feedback_make_nat_literal_tokens_next(Nat.is_le(stop, token_beg(token)), token, more, value, end, stop)}, Nil{}, NoProgress{}, NoProgress{}}
    case None{}:
      feedback_pack_15(None{})

def step_nat_literal_tokens_suffix(valid: Bool, text: String, end: Nat, rest: List<&2, Lexer.Token>, stop: Nat) -> FeedbackControl:
  match valid:
    case True{}:
      step_nat_literal_tokens_value(Nat.read(drop_nat_suffix(text)), end, rest, stop)
    case False{}:
      feedback_pack_15(None{})

def step_nat_literal_tokens(tokens: List<&2, Lexer.Token>, +stop: Nat) -> FeedbackControl:
  match tokens:
    case Lexer.TokenInfo{Lexer.NewlineToken{}, _, _, _, _, _} <> rest:
      step_nat_literal_tokens(rest, stop)
    case Lexer.TokenInfo{Lexer.SymbolToken{}, "(", _, _, _, _} <> rest:
      step_nat_literal_tokens(rest, stop)
    case Lexer.TokenInfo{Lexer.NumberToken{}, +text, _, +end, _, _} <> +rest:
      step_nat_literal_tokens_suffix(has_nat_suffix(text), text, end, rest, stop)
    case _:
      feedback_pack_15(None{})

def feedback_pack_5(result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  match result:
    case ((result_0_0, result_0_1), result_1):
      FeedbackControl{FeedbackDone{Value_5{result_0_0, result_0_1, result_1}}, Nil{}, NoProgress{}, NoProgress{}}

def span(file: String, beg: Nat, end: Nat) -> Ast.SourceSpan:
  Ast.SpanOf{file, beg, end}

def u32_bit(file: String, bit_value: Nat, beg: Nat, end: Nat) -> Ast.SyntaxTerm:
  match bit_value:
    case 0n:
      Ast.TermCtr{ "False",  Nil{},  span(file, beg, end)}
    case _:
      Ast.TermCtr{ "True",  Nil{},  span(file, beg, end)}

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

def parse_unicode_digit_code(chars: List<&2, Char>) -> Nat:
  match chars:
    case +char <> rest:
      U32.to_nat(Char.to_u32(char))
    case Nil{}:
      0n

def unicode_hex_digit_above_zero(is_above: Bool, code: Nat) -> Maybe<&2, Nat>:
  match is_above:
    case True{}:
      Some{(code - 48n : Nat)}
    case False{}:
      None{}

def unicode_hex_digit_above_a(is_above: Bool, code: Nat) -> Maybe<&2, Nat>:
  match is_above:
    case True{}:
      Some{(code - 87n : Nat)}
    case False{}:
      None{}

def unicode_hex_digit_above_A(is_above: Bool, code: Nat) -> Maybe<&2, Nat>:
  match is_above:
    case True{}:
      Some{(code - 55n : Nat)}
    case False{}:
      None{}

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
              parse_unicode_digits(rest, ((acc * 16n : Nat) + digit : Nat), parse_unicode_digit_code(rest), parse_unicode_digit_result(rest))
            case None{}:
              ((0n, chars), False{})
    case Nil{}:
      ((0n, Nil{}), False{})

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

def feedback_make_Kont_188761(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Nat, capture_5: Nat) -> FeedbackFrame:
  Kont_188761{capture_1, capture_2, capture_3, capture_4, capture_5}

def feedback_make_parse_do_typed_bind(file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> FeedbackRequest:
  Request_parse_do_typed_bind{file, monad, args, tokens, beg, end, scope, depth, col}

def feedback_make_Kont_251939(lexical_capture_1: String, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat, lexical_capture_10: Nat, lexical_capture_3: List<&2, Lexer.Token>) -> FeedbackFrame:
  Kont_251939{lexical_capture_1, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_3}

def feedback_make_parse_atom_scan(file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackRequest:
  Request_parse_atom_scan{file, tokens, scanned, scope, depth}

def step_parse_atom(file: String, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  FeedbackControl{FeedbackCall{feedback_make_parse_atom_scan(file, tokens, skip_lines(tokens), scope, depth)}, Nil{}, NoProgress{}, NoProgress{}}

def step_parse_term(+file: String, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, level: Nat) -> FeedbackControl:
  feedback_attach(step_parse_atom(file, tokens, scope, depth), feedback_make_Kont_251939(file, scope, depth, level, tokens))

def step_parse_do_return_scan(+file: String, +key: String, +args: List<&2, Ast.SyntaxTerm>, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +beg: Nat, +end: Nat, +scope: List<&2, Scope>, +depth: Nat, col: Nat) -> FeedbackControl:
  match scanned:
    case +return_token <> +rest:
      match return_token:
        case Lexer.TokenInfo{Lexer.NameToken{}, "return", _, _, _, _}:
          feedback_attach(step_parse_term(file, rest, scope, depth, 0n), feedback_make_Kont_188761(file, key, args, beg, end))
        case Lexer.TokenInfo{feedback_field_6_0, feedback_field_6_1, feedback_field_6_2, feedback_field_6_3, feedback_field_6_4, feedback_field_6_5}:
          FeedbackControl{FeedbackCall{feedback_make_parse_do_typed_bind(file, key, args, (Lexer.TokenInfo{feedback_field_6_0, feedback_field_6_1, feedback_field_6_2, feedback_field_6_3, feedback_field_6_4, feedback_field_6_5} : Lexer.Token) <> rest, beg, end, scope, depth, col)}, Nil{}, NoProgress{}, NoProgress{}}
    case Nil{}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected return in do block", span(file, beg, end)}, Nil{}), False{}))

def step_parse_do_return(file: String, key: String, args: List<&2, Ast.SyntaxTerm>, +tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> FeedbackControl:
  step_parse_do_return_scan(file, key, args, tokens, skip_lines(tokens), beg, end, scope, depth, col)

def step_parse_do_atom_colon(+colon: Lexer.Token, +after_colon: List<&2, Lexer.Token>, args: List<&2, Ast.SyntaxTerm>, +file: String, key: String, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match colon:
    case Lexer.TokenInfo{_, ":", +_, +_, +_, +_}:
      step_parse_do_return(file, key, args, after_colon, beg, end, scope, depth, do_first_col(after_colon))
    case Lexer.TokenInfo{+feedback_field_4_0, +feedback_field_4_1, +feedback_field_4_2, +feedback_field_4_3, +feedback_field_4_4, +feedback_field_4_5}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected : after do parameters", span(file, token_beg((Lexer.TokenInfo{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4, feedback_field_4_5} : Lexer.Token)), token_end((Lexer.TokenInfo{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4, feedback_field_4_5} : Lexer.Token)))}, (Lexer.TokenInfo{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4, feedback_field_4_5} : Lexer.Token) <> after_colon), False{}))

def step_parse_do_atom_args_result(result: (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool, +file: String, key: String, beg: Nat, +end: Nat, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match result:
    case ((args, +colon <> after_colon), True{}):
      step_parse_do_atom_colon(colon, after_colon, args, file, key, beg, end, scope, depth)
    case ((_, after_args), False{}):
      feedback_pack_5(((Ast.TermHole{"parse-error: expected do parameters", span(file, end, end)}, after_args), False{}))
    case _:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected do parameters", span(file, end, end)}, tokens), False{}))

def split_angle_close(+tokens: List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:
  match tokens:
    case Lexer.TokenInfo{Lexer.SymbolToken{}, ">>", +beg, +end, +line, +col} <> rest:
      Lexer.TokenInfo{Lexer.SymbolToken{}, ">", beg, (beg + 1n : Nat), line, col} <> Lexer.TokenInfo{Lexer.SymbolToken{}, ">", (beg + 1n : Nat), end, line, (col + 1n : Nat)} <> rest
    case _:
      tokens

def angle_close_tokens(is_angle: Bool, tokens: List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:
  match is_angle:
    case True{}:
      split_angle_close(tokens)
    case False{}:
      tokens

def feedback_pack_9(result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  match result:
    case ((result_0_0, result_0_1), result_1):
      FeedbackControl{FeedbackDone{Value_9{result_0_0, result_0_1, result_1}}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_make_Kont_242904(lexical_capture_3: String, lexical_capture_8: List<&2, Lexer.Token>, lexical_capture_10: String, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: List<&2, Ast.SyntaxTerm>) -> FeedbackFrame:
  Kont_242904{lexical_capture_3, lexical_capture_8, lexical_capture_10, lexical_capture_13, lexical_capture_15, lexical_capture_17}

def step_parse_term_args_first(is_close: Bool, +file: String, token: Lexer.Token, rest: List<&2, Lexer.Token>, +tokens: List<&2, Lexer.Token>, close: String, +scope: List<&2, Scope>, +depth: Nat, +acc: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match is_close:
    case True{}:
      feedback_pack_9(((List.reverse(&2, Ast.SyntaxTerm, acc), rest), True{}))
    case False{}:
      feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_242904(file, tokens, close, scope, depth, acc))

def token_text(token: Lexer.Token) -> String:
  match token:
    case Lexer.TokenInfo{ _, text,  _,  _,  _,  _}:
      text

def step_parse_term_args_tokens(file: String, +tokens: List<&2, Lexer.Token>, +close: String, scope: List<&2, Scope>, depth: Nat, +acc: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match tokens:
    case +token <> +rest:
      step_parse_term_args_first(Bool.or(String.eq(token_text(token), close), Bool.and(String.eq(close, ">"), String.eq(token_text(token), "<>"))), file, token, rest, tokens, close, scope, depth, acc)
    case Nil{}:
      feedback_pack_9(((List.reverse(&2, Ast.SyntaxTerm, acc), Nil{}), False{}))

def step_parse_term_args(file: String, tokens: List<&2, Lexer.Token>, +close: String, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  step_parse_term_args_tokens(file, angle_close_tokens(String.eq(close, ">"), tokens), close, scope, depth, acc)

def extend_scope_result(is_underscore: Bool, key: String, index: Nat, scope: List<&2, Scope>) -> List<&2, Scope>:
  match is_underscore:
    case True{}:
      scope
    case False{}:
      Scope{key, index} <> scope

def extend_scope(+key: String, index: Nat, scope: List<&2, Scope>) -> List<&2, Scope>:
  extend_scope_result(String.eq(key, "_"), key, index, scope)

def feedback_make_parse_body_scan(file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, parent_col: Nat) -> FeedbackRequest:
  Request_parse_body_scan{file, tokens, scanned, scope, depth, parent_col}

def step_parse_body(file: String, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, parent_col: Nat) -> FeedbackControl:
  FeedbackControl{FeedbackCall{feedback_make_parse_body_scan(file, tokens, skip_lines(tokens), scope, depth, parent_col)}, Nil{}, NoProgress{}, NoProgress{}}

def float_exponent_bits(negative_exponent: Bool, exponent: Nat) -> Nat:
  match negative_exponent:
    case True{}:
      (127n - exponent : Nat)
    case False{}:
      (127n + exponent : Nat)

def encode_float_normal_bits_exact(significand: Nat, negative_exponent: Bool, exponent: Nat) -> Nat & Bool:
  exponent_bits = float_exponent_bits(negative_exponent, exponent)
  bits = (((exponent_bits * 8388608n : Nat) + significand : Nat) - 8388608n : Nat)
  (bits, True{})

def encode_float_normal_rounding_limit(is_below_limit: Bool, significand: Nat, negative_exponent: Bool, exponent: Nat) -> Nat & Bool:
  match is_below_limit:
    case True{}:
      encode_float_normal_bits_exact(significand, negative_exponent, exponent)
    case False{}:
      match negative_exponent:
        case True{}:
          exponent_bits = (128n - exponent : Nat)
          ((exponent_bits * 8388608n : Nat), True{})
        case False{}:
          match exponent:
            case 127n:
              (0n, False{})
            case _:
              ((((exponent + 128n : Nat)) * 8388608n : Nat), True{})

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

def feedback_make_pattern_scan(tokens: List<&2, Lexer.Token>, file: String, mode: PatternScanMode, frames: List<&2, PatternFrame>, scope: List<&2, Scope>, depth: Nat, goal: PatternScanGoal) -> FeedbackRequest:
  Request_pattern_scan{tokens, file, mode, frames, scope, depth, goal}

def feedback_make_Kont_296071(lexical_capture_1: String) -> FeedbackFrame:
  Kont_296071{lexical_capture_1}

def step_parse_reply(+file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_296071(file))

def feedback_make_parse_local_values_next(remaining: List<&2, Ast.SyntaxPattern>, file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, line: Nat, acc: List<&2, Ast.SyntaxTerm>) -> FeedbackRequest:
  Request_parse_local_values_next{remaining, file, tokens, scope, depth, line, acc}

def token_end_of(tokens: List<&2, Lexer.Token>, fallback: Nat) -> Nat:
  match tokens:
    case +token <> _:
      token_beg(token)
    case Nil{}:
      fallback

def parse_case_rows_stop(acc: List<&2, Ast.SyntaxTerm>, tokens: List<&2, Lexer.Token>) -> (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool:
  match acc:
    case Nil{}:
      ((Nil{}, tokens), True{})
    case _:
      ((List.reverse(&2, Ast.SyntaxTerm, acc), tokens), True{})

def feedback_make_parse_def_binders_scan(file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.TelescopeItem>) -> FeedbackRequest:
  Request_parse_def_binders_scan{file, tokens, scanned, scope, depth, acc}

def feedback_pack_1(result: ((((List<&2, Ast.TelescopeItem> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool)) -> FeedbackControl:
  match result:
    case ((((result_0_0_0_0, result_0_0_0_1), result_0_0_1), result_0_1), result_1):
      FeedbackControl{FeedbackDone{Value_1{result_0_0_0_0, result_0_0_0_1, result_0_0_1, result_0_1, result_1}}, Nil{}, NoProgress{}, NoProgress{}}

def step_parse_def_binders(file: String, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.TelescopeItem>) -> FeedbackControl:
  FeedbackControl{FeedbackCall{feedback_make_parse_def_binders_scan(file, tokens, skip_lines(tokens), scope, depth, acc)}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_pack_0(result: ((((List<&2, Ast.Clause> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool)) -> FeedbackControl:
  match result:
    case ((((result_0_0_0_0, result_0_0_0_1), result_0_0_1), result_0_1), result_1):
      FeedbackControl{FeedbackDone{Value_0{result_0_0_0_0, result_0_0_0_1, result_0_0_1, result_0_1, result_1}}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_make_Kont_353513(lexical_capture_1: String, lexical_capture_31: String, lexical_capture_32: Nat, lexical_capture_33: Nat, lexical_capture_5: Nat, lexical_capture_7: Bool, lexical_capture_8: Ast.Quantity, lexical_capture_11: List<&2, Scope>, lexical_capture_13: Nat, lexical_capture_15: List<&2, Ast.Clause>) -> FeedbackFrame:
  Kont_353513{lexical_capture_1, lexical_capture_31, lexical_capture_32, lexical_capture_33, lexical_capture_5, lexical_capture_7, lexical_capture_8, lexical_capture_11, lexical_capture_13, lexical_capture_15}

def step_parse_law_clause_name(+file: String, +tokens: List<&2, Lexer.Token>, beg: Nat, universal: Bool, quantity: Ast.Quantity, +scope: List<&2, Scope>, +depth: Nat, +acc: List<&2, Ast.Clause>) -> FeedbackControl:
  match tokens:
    case +name <> +after_name:
      match name:
        case Lexer.TokenInfo{ Lexer.NameToken{},  key,  key_beg,  key_end,  _,  _}:
          match after_name:
            case +colon <> after_colon:
              match colon:
                case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
                  feedback_attach(step_parse_term(file, after_colon, scope, depth, 0n), feedback_make_Kont_353513(file, key, key_beg, key_end, beg, universal, quantity, scope, depth, acc))
                case _:
                  feedback_pack_0(((((List.reverse(&2, Ast.Clause, acc), after_name), scope), depth), False{}))
            case Nil{}:
              feedback_pack_0(((((List.reverse(&2, Ast.Clause, acc), after_name), scope), depth), False{}))
        case _:
          feedback_pack_0(((((List.reverse(&2, Ast.Clause, acc), tokens), scope), depth), False{}))
    case Nil{}:
      feedback_pack_0(((((List.reverse(&2, Ast.Clause, acc), []), scope), depth), False{}))

def step_parse_law_universal_clause(+file: String, +tokens: List<&2, Lexer.Token>, +beg: Nat, +scope: List<&2, Scope>, +depth: Nat, +acc: List<&2, Ast.Clause>) -> FeedbackControl:
  match tokens:
    case +prefix <> +after_prefix:
      match prefix:
        case Lexer.TokenInfo{ _, "+",  _,  _,  _,  _}:
          step_parse_law_clause_name(file, after_prefix, beg, True{}, Ast.QMany{}, scope, depth, acc)
        case Lexer.TokenInfo{ _, "-",  _,  _,  _,  _}:
          step_parse_law_clause_name(file, after_prefix, beg, True{}, Ast.QZero{}, scope, depth, acc)
        case _:
          step_parse_law_clause_name(file, tokens, beg, True{}, Ast.QOne{}, scope, depth, acc)
    case Nil{}:
      feedback_pack_0(((((List.reverse(&2, Ast.Clause, acc), []), scope), depth), False{}))

def step_parse_law_clause(+file: String, +tokens: List<&2, Lexer.Token>, +beg: Nat, universal: Bool, +scope: List<&2, Scope>, +depth: Nat, +acc: List<&2, Ast.Clause>) -> FeedbackControl:
  match universal:
    case True{}:
      step_parse_law_universal_clause(file, tokens, beg, scope, depth, acc)
    case False{}:
      step_parse_law_clause_name(file, tokens, beg, False{}, Ast.QOne{}, scope, depth, acc)

def step_parse_law_clauses_scan(+file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +acc: List<&2, Ast.Clause>) -> FeedbackControl:
  match scanned:
    case +token <> +after_token:
      match token:
        case Lexer.TokenInfo{ _, "for",  _,  _,  _,  _}:
          step_parse_law_clause(file, after_token, token_beg(token), True{}, scope, depth, acc)
        case Lexer.TokenInfo{ _, "exs",  _,  _,  _,  _}:
          step_parse_law_clause(file, after_token, token_beg(token), False{}, scope, depth, acc)
        case _:
          feedback_pack_0(((((List.reverse(&2, Ast.Clause, acc), tokens), scope), depth), True{}))
    case Nil{}:
      feedback_pack_0(((((List.reverse(&2, Ast.Clause, acc), []), scope), depth), True{}))

def step_parse_law_clauses(file: String, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.Clause>) -> FeedbackControl:
  step_parse_law_clauses_scan(file, tokens, skip_lines(tokens), scope, depth, acc)

def token_end_first(term: Ast.SyntaxTerm) -> Nat:
  match term:
    case Ast.TermVar{ _,  _,  Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.TermRef{ _,  Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.TermBang{ _,  Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.TermAll{ _,  _,  _,  _,  _,  Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.TermMin{ _,  _,  Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.TermApp{ _,  _,  Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.TermLam{ _,  _,  _,  _,  Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.TermType{ _,  Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.TermQuantity{ _,  Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.TermCtr{ _,  _,  Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.TermString{_, _, Ast.SpanOf{_, _, end}}:
      end
    case Ast.TermAdt{ _,  _,  _,  Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.TermMat{ _,  _,  _,  Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.TermAbsurd{ Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.TermEqual{ _,  _,  _,  Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.TermRefl{ Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.TermRewrite{ _,  _,  _,  Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.TermLet{ _,  _,  _,  _,  _,  Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.TermAnn{ _,  _,  Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.TermTemplate{ _,  Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.TermFill{ _,  _,  Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.TermPlus{ _,  _,  Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.TermHole{ _,  Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.BodyMatch{ _,  _,  Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.BodyCase{ _,  _,  Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.BodyLocal{ _,  _,  _,  _,  Ast.SpanOf{ _,  _, end}}:
      end
    case Ast.BodyReply{ _,  Ast.SpanOf{ _,  _, end}}:
      end
    case _:
      0n

def feedback_pack_2(result: (((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Nat) & Bool)) -> FeedbackControl:
  match result:
    case (((result_0_0_0, result_0_0_1), result_0_1), result_1):
      FeedbackControl{FeedbackDone{Value_2{result_0_0_0, result_0_0_1, result_0_1, result_1}}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_make_parse_match_chain_state(state: MatchChainState) -> FeedbackRequest:
  Request_parse_match_chain_state{state}

def feedback_make_parse_term_tail_at(file: String, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat, last_end: Nat) -> FeedbackRequest:
  Request_parse_term_tail_at{file, left, tokens, scope, depth, level, last_end}

def token_beg_first(term: Ast.SyntaxTerm) -> Nat:
  match term:
    case Ast.TermVar{ _,  _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.TermRef{ _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.TermBang{ _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.TermAll{ _,  _,  _,  _,  _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.TermMin{ _,  _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.TermApp{ _,  _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.TermLam{ _,  _,  _,  _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.TermType{ _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.TermQuantity{ _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.TermCtr{ _,  _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.TermString{_, _, Ast.SpanOf{_, beg, _}}:
      beg
    case Ast.TermAdt{ _,  _,  _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.TermMat{ _,  _,  _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.TermAbsurd{ Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.TermEqual{ _,  _,  _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.TermRefl{ Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.TermRewrite{ _,  _,  _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.TermLet{ _,  _,  _,  _,  _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.TermAnn{ _,  _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.TermTemplate{ _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.TermFill{ _,  _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.TermPlus{ _,  _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.TermHole{ _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.BodyMatch{ _,  _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.BodyCase{ _,  _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.BodyLocal{ _,  _,  _,  _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case Ast.BodyReply{ _,  Ast.SpanOf{ _, beg,  _}}:
      beg
    case _:
      0n

def feedback_pack_10(result: ((List<&2, Ast.TopLevel> & Bool) & List<&2, Lexer.Token>)) -> FeedbackControl:
  match result:
    case ((result_0_0, result_0_1), result_1):
      FeedbackControl{FeedbackDone{Value_10{result_0_0, result_0_1, result_1}}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_make_Kont_362397(lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>) -> FeedbackFrame:
  Kont_362397{lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9}

def feedback_make_Kont_362687(lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>) -> FeedbackFrame:
  Kont_362687{lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9}

def feedback_make_Kont_362980(lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>) -> FeedbackFrame:
  Kont_362980{lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9}

def feedback_make_Kont_363271(lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>) -> FeedbackFrame:
  Kont_363271{lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9}

def feedback_pack_6(result: ((Ast.TopLevel & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  match result:
    case ((result_0_0, result_0_1), result_1):
      FeedbackControl{FeedbackDone{Value_6{result_0_0, result_0_1, result_1}}, Nil{}, NoProgress{}, NoProgress{}}

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

def feedback_make_Kont_334657(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat) -> FeedbackFrame:
  Kont_334657{lexical_capture_1, lexical_capture_3, lexical_capture_5}

def step_parse_definition_with_binders(+file: String, key: String, beg: Nat, tokens: List<&2, Lexer.Token>, path: String) -> FeedbackControl:
  feedback_attach(step_parse_def_binders(file, tokens, Nil{}, 0n, Nil{}), feedback_make_Kont_334657(file, key, beg))

def step_parse_definition_name_tail(+key: String, +after_name: List<&2, Lexer.Token>, +file: String, +def_token: Lexer.Token, path: String) -> FeedbackControl:
  match after_name:
    case +open <> after_open:
      match open:
        case Lexer.TokenInfo{_, "(", _, _, _, _}:
          step_parse_definition_with_binders(file, key, token_beg(def_token), after_open, path)
        case Lexer.TokenInfo{+feedback_field_6_0, +feedback_field_6_1, +feedback_field_6_2, +feedback_field_6_3, +feedback_field_6_4, +feedback_field_6_5}:
          feedback_pack_6(((Ast.DefTop{Ast.Definition{key, Nil{}, Ast.NoTerm{}, Ast.DefTerm{Ast.TermHole{"parse-error: expected (", span(file, token_beg((Lexer.TokenInfo{feedback_field_6_0, feedback_field_6_1, feedback_field_6_2, feedback_field_6_3, feedback_field_6_4, feedback_field_6_5} : Lexer.Token)), token_end((Lexer.TokenInfo{feedback_field_6_0, feedback_field_6_1, feedback_field_6_2, feedback_field_6_3, feedback_field_6_4, feedback_field_6_5} : Lexer.Token)))}}, False{}, span(file, token_beg(def_token), token_end((Lexer.TokenInfo{feedback_field_6_0, feedback_field_6_1, feedback_field_6_2, feedback_field_6_3, feedback_field_6_4, feedback_field_6_5} : Lexer.Token)))}}, after_name), False{}))
    case Nil{}:
      feedback_pack_6(((Ast.DefTop{Ast.Definition{key, Nil{}, Ast.NoTerm{}, Ast.DefTerm{Ast.TermHole{"parse-error: expected (", span(file, token_beg(def_token), token_end(def_token))}}, False{}, span(file, token_beg(def_token), token_end(def_token))}}, after_name), False{}))

def step_parse_definition_name_result(name_parsed: (String & List<&2, Lexer.Token>) & Bool, +file: String, +def_token: Lexer.Token, after_def: List<&2, Lexer.Token>, path: String) -> FeedbackControl:
  match name_parsed:
    case ((key, after_name), True{}):
      step_parse_definition_name_tail(key, after_name, file, def_token, path)
    case _:
      feedback_pack_6(((Ast.DefTop{Ast.Definition{"", Nil{}, Ast.NoTerm{}, Ast.DefTerm{Ast.TermHole{"parse-error: expected a definition name", span(file, token_beg(def_token), token_end(def_token))}}, False{}, span(file, token_beg(def_token), token_end(def_token))}}, after_def), False{}))

def step_parse_definition(+file: String, tokens: List<&2, Lexer.Token>, path: String) -> FeedbackControl:
  match tokens:
    case +def_token <> +after_def:
      step_parse_definition_name_result(parse_name(after_def), file, def_token, after_def, path)
    case Nil{}:
      feedback_pack_6(((Ast.DefTop{ Ast.Definition{ "",  Nil{},  Ast.NoTerm{},  Ast.DefTerm{Ast.TermHole{ "parse-error: expected def",  span(file, 0n, 0n)}},  False{},  span(file, 0n, 0n)}}, Nil{}), False{}))

def feedback_make_Kont_357785(lexical_capture_1: String, lexical_capture_17: String, lexical_capture_5: Nat, lexical_capture_24: Lexer.Token, lexical_capture_25: List<&2, Lexer.Token>) -> FeedbackFrame:
  Kont_357785{lexical_capture_1, lexical_capture_17, lexical_capture_5, lexical_capture_24, lexical_capture_25}

def law_failure(+file: String, key: String, beg: Nat, +end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  body = { Ast.TermHole{ "parse-error: malformed or unsupported law",  span(file, end, end)} : Ast.SyntaxTerm }
  declaration = { Ast.LawDecl{key,  Nil{}, body,  span(file, beg, end)} : Ast.LawDecl }
  ((Ast.LawTop{declaration}, rest), False{})

def step_parse_law_decl(+file: String, +tokens: List<&2, Lexer.Token>, +beg: Nat) -> FeedbackControl:
  match tokens:
    case +name <> +after_name:
      match name:
        case Lexer.TokenInfo{ Lexer.NameToken{},  +key,  _,  _,  _,  _}:
          match after_name:
            case +colon <> +after_colon:
              match colon:
                case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
                  feedback_attach(step_parse_law_clauses(file, after_colon, Nil{}, 0n, Nil{}), feedback_make_Kont_357785(file, key, beg, colon, after_colon))
                case Lexer.TokenInfo{feedback_field_10_0, feedback_field_10_1, feedback_field_10_2, feedback_field_10_3, feedback_field_10_4, feedback_field_10_5}:
                  feedback_pack_6(law_failure(file, key, beg, token_beg((Lexer.TokenInfo{feedback_field_10_0, feedback_field_10_1, feedback_field_10_2, feedback_field_10_3, feedback_field_10_4, feedback_field_10_5} : Lexer.Token)), after_name))
            case Nil{}:
              feedback_pack_6(law_failure(file, key, beg, beg, after_name))
        case Lexer.TokenInfo{feedback_field_14_0, feedback_field_14_1, feedback_field_14_2, feedback_field_14_3, feedback_field_14_4, feedback_field_14_5}:
          feedback_pack_6(law_failure(file, "", beg, token_end((Lexer.TokenInfo{feedback_field_14_0, feedback_field_14_1, feedback_field_14_2, feedback_field_14_3, feedback_field_14_4, feedback_field_14_5} : Lexer.Token)), tokens))
    case Nil{}:
      feedback_pack_6(law_failure(file, "", beg, beg, Nil{}))

def feedback_make_Kont_347068(lexical_capture_26: Lexer.Token, lexical_capture_1: String, lexical_capture_19: String, lexical_capture_5: Nat, lexical_capture_7: Nat) -> FeedbackFrame:
  Kont_347068{lexical_capture_26, lexical_capture_1, lexical_capture_19, lexical_capture_5, lexical_capture_7}

def feedback_make_Kont_347534(lexical_capture_26: Lexer.Token, lexical_capture_1: String, lexical_capture_19: String, lexical_capture_5: Nat, lexical_capture_7: Nat) -> FeedbackFrame:
  Kont_347534{lexical_capture_26, lexical_capture_1, lexical_capture_19, lexical_capture_5, lexical_capture_7}

def feedback_make_Kont_345467(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: List<&2, Ast.TelescopeItem>, lexical_capture_11: List<&2, Lexer.Token>, lexical_capture_16: List<&2, Scope>, lexical_capture_18: Nat) -> FeedbackFrame:
  Kont_345467{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_16, lexical_capture_18}

def type_failure(+file: String, key: String, beg: Nat, +end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  error = { Ast.TermHole{ "parse-error: malformed or unsupported type declaration",  span(file, end, end)} : Ast.SyntaxTerm }
  declaration = { Ast.TypeDecl{key,  Nil{},  error,  Nil{},  span(file, beg, end)} : Ast.TypeDecl }
  ((Ast.TypeTop{declaration}, rest), False{})

def step_parse_type_header_scan(+file: String, +key: String, +beg: Nat, col: Nat, params: List<&2, Ast.TelescopeItem>, +tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match scanned:
    case +is_token <> after_is:
      match is_token:
        case Lexer.TokenInfo{ _, "is",  _,  _,  _,  _}:
          feedback_attach(step_parse_term(file, after_is, scope, depth, 0n), feedback_make_Kont_345467(file, key, beg, col, params, tokens, scope, depth))
        case Lexer.TokenInfo{feedback_field_6_0, feedback_field_6_1, feedback_field_6_2, feedback_field_6_3, feedback_field_6_4, feedback_field_6_5}:
          feedback_pack_6(type_failure(file, key, beg, token_beg((Lexer.TokenInfo{feedback_field_6_0, feedback_field_6_1, feedback_field_6_2, feedback_field_6_3, feedback_field_6_4, feedback_field_6_5} : Lexer.Token)), tokens))
    case Nil{}:
      feedback_pack_6(type_failure(file, key, beg, beg, Nil{}))

def step_parse_type_header(file: String, key: String, beg: Nat, col: Nat, params: List<&2, Ast.TelescopeItem>, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  step_parse_type_header_scan(file, key, beg, col, params, tokens, skip_lines(tokens), scope, depth)

def step_parse_type_decl(+file: String, +tokens: List<&2, Lexer.Token>, +beg: Nat, +col: Nat) -> FeedbackControl:
  match tokens:
    case +name <> +after_name:
      match name:
        case Lexer.TokenInfo{ Lexer.NameToken{},  +key,  _,  _,  _,  _}:
          match after_name:
            case +open <> +after_open:
              match open:
                case Lexer.TokenInfo{ _, "<",  _,  _,  _,  _}:
                  feedback_attach(step_parse_def_binders(file, after_open, Nil{}, 0n, Nil{}), feedback_make_Kont_347068(open, file, key, beg, col))
                case Lexer.TokenInfo{_, "<-", start, end, line, column}:
                  erased = { Lexer.TokenInfo{Lexer.SymbolToken{}, "-", (start + 1n : Nat), end, line, (column + 1n : Nat)} : Lexer.Token }
                  feedback_attach(step_parse_def_binders(file, erased <> after_open, Nil{}, 0n, Nil{}), feedback_make_Kont_347534(open, file, key, beg, col))
                case Lexer.TokenInfo{_, "<>", _, _, _, _}:
                  step_parse_type_header(file, key, beg, col, Nil{}, after_open, Nil{}, 0n)
                case _:
                  step_parse_type_header(file, key, beg, col, Nil{}, after_name, Nil{}, 0n)
            case Nil{}:
              step_parse_type_header(file, key, beg, col, Nil{}, after_name, Nil{}, 0n)
        case Lexer.TokenInfo{feedback_field_19_0, feedback_field_19_1, feedback_field_19_2, feedback_field_19_3, feedback_field_19_4, feedback_field_19_5}:
          feedback_pack_6(type_failure(file, "", beg, token_end((Lexer.TokenInfo{feedback_field_19_0, feedback_field_19_1, feedback_field_19_2, feedback_field_19_3, feedback_field_19_4, feedback_field_19_5} : Lexer.Token)), tokens))
    case Nil{}:
      feedback_pack_6(type_failure(file, "", beg, beg, Nil{}))

def feedback_make_Kont_339827() -> FeedbackFrame:
  Kont_339827{}

def feedback_make_Kont_339962() -> FeedbackFrame:
  Kont_339962{}

def step_parse_unsafe_definition(+tokens: List<&2, Lexer.Token>, +file: String, +path: String) -> FeedbackControl:
  match tokens:
    case Lexer.TokenInfo{_, "def", _, _, _, _} <> _:
      feedback_attach(step_parse_definition(file, tokens, path), feedback_make_Kont_339827())
    case Nil{}:
      feedback_attach(step_parse_definition(file, (Nil{} : List<&2, Lexer.Token>), path), feedback_make_Kont_339962())
    case Con{feedback_field_4_0, feedback_field_4_1}:
      feedback_attach(step_parse_definition(file, (Con{feedback_field_4_0, feedback_field_4_1} : List<&2, Lexer.Token>), path), feedback_make_Kont_339962())

def step_parse_unsafe(+file: String, +tokens: List<&2, Lexer.Token>, +path: String) -> FeedbackControl:
  match tokens:
    case Lexer.TokenInfo{_, "unsafe", _, _, _, _} <> rest:
      step_parse_unsafe_definition(skip_lines(rest), file, path)
    case Nil{}:
      step_parse_definition(file, (Nil{} : List<&2, Lexer.Token>), path)
    case Con{feedback_field_4_0, feedback_field_4_1}:
      step_parse_definition(file, (Con{feedback_field_4_0, feedback_field_4_1} : List<&2, Lexer.Token>), path)

def step_parse_top_scan(+file: String, +tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +path: String, +acc: List<&2, Ast.TopLevel>, +owners: Map<&2, TopOwner>) -> FeedbackControl:
  match scanned:
    case +token <> +rest:
      match token:
        case Lexer.TokenInfo{ Lexer.EndToken{},  _,  _,  _,  _,  _}:
          feedback_pack_10(((List.reverse(&2, Ast.TopLevel, acc), True{}), rest))
        case Lexer.TokenInfo{ Lexer.ErrorToken{},  _,  _,  _,  _,  _}:
          feedback_pack_10(((List.reverse(&2, Ast.TopLevel, acc), False{}), tokens))
        case Lexer.TokenInfo{ Lexer.NameToken{},  "law", beg,  _,  _,  _}:
          feedback_attach(step_parse_law_decl(file, rest, beg), feedback_make_Kont_362397(owners, rest, tokens, file, path, acc))
        case Lexer.TokenInfo{ Lexer.NameToken{},  "type", beg,  _,  _, col}:
          feedback_attach(step_parse_type_decl(file, rest, beg, col), feedback_make_Kont_362687(owners, rest, tokens, file, path, acc))
        case Lexer.TokenInfo{ Lexer.SymbolToken{},  "@",  _,  _,  _,  _}:
          feedback_attach(step_parse_unsafe(file, rest, path), feedback_make_Kont_362980(owners, rest, tokens, file, path, acc))
        case Lexer.TokenInfo{ Lexer.NameToken{},  "def", beg, end, line, col}:
          feedback_attach(step_parse_definition(file, Lexer.TokenInfo{Lexer.NameToken{}, "def", beg, end, line, col} <> rest, path), feedback_make_Kont_363271(owners, rest, tokens, file, path, acc))
        case _:
          feedback_pack_10(((List.reverse(&2, Ast.TopLevel, acc), False{}), tokens))
    case Nil{}:
      feedback_pack_10(((List.reverse(&2, Ast.TopLevel, acc), False{}), Nil{}))

def top_owner_set(top: Ast.TopLevel, owners: Map<&2, TopOwner>) -> Map<&2, TopOwner>:
  match top:
    case Ast.DefTop{Ast.Definition{key, _, _, _, _, _}}:
      Map.set(&2, TopOwner, owners, key, TopOwnerClosed{})
    case Ast.TypeTop{Ast.TypeDecl{key, _, _, _, _}}:
      Map.set(&2, TopOwner, owners, key, TopOwnerClosed{})
    case Ast.LawTop{Ast.LawDecl{key, _, _, _}}:
      Map.set(&2, TopOwner, owners, key, TopOwnerLaw{})

def feedback_pack_7(result: ((List<&2, Ast.ConstructorDecl> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  match result:
    case ((result_0_0, result_0_1), result_1):
      FeedbackControl{FeedbackDone{Value_7{result_0_0, result_0_1, result_1}}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_make_Kont_342579(lexical_capture_3: String, lexical_capture_26: Lexer.Token, lexical_capture_27: List<&2, Lexer.Token>, lexical_capture_9: Nat, lexical_capture_12: List<&2, Scope>, lexical_capture_14: Nat, lexical_capture_16: List<&2, Ast.ConstructorDecl>, lexical_capture_18: String, lexical_capture_20: Nat) -> FeedbackFrame:
  Kont_342579{lexical_capture_3, lexical_capture_26, lexical_capture_27, lexical_capture_9, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_18, lexical_capture_20}

def step_parse_type_constructor_indent(is_indented: Bool, +file: String, +tokens: List<&2, Lexer.Token>, rest: List<&2, Lexer.Token>, col: Nat, +scope: List<&2, Scope>, +depth: Nat, +acc: List<&2, Ast.ConstructorDecl>, key: String, beg: Nat) -> FeedbackControl:
  match is_indented:
    case True{}:
      match rest:
        case +open <> +after_open:
          match open:
            case Lexer.TokenInfo{ _, "{",  _,  _,  _,  _}:
              feedback_attach(step_parse_def_binders(file, after_open, scope, depth, Nil{}), feedback_make_Kont_342579(file, open, after_open, col, scope, depth, acc, key, beg))
            case _:
              feedback_pack_7(((List.reverse(&2, Ast.ConstructorDecl, acc), tokens), False{}))
        case Nil{}:
          feedback_pack_7(((List.reverse(&2, Ast.ConstructorDecl, acc), tokens), False{}))
    case False{}:
      feedback_pack_7(((List.reverse(&2, Ast.ConstructorDecl, acc), tokens), True{}))

def step_parse_type_constructors_scan(file: String, +tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +col: Nat, scope: List<&2, Scope>, depth: Nat, +acc: List<&2, Ast.ConstructorDecl>) -> FeedbackControl:
  match scanned:
    case +constructor <> rest:
      match constructor:
        case Lexer.TokenInfo{ Lexer.NameToken{},  key, beg,  _,  _,  constructor_col}:
          step_parse_type_constructor_indent(Nat.is_lt(col, constructor_col), file, tokens, rest, col, scope, depth, acc, key, beg)
        case _:
          feedback_pack_7(((List.reverse(&2, Ast.ConstructorDecl, acc), tokens), True{}))
    case Nil{}:
      feedback_pack_7(((List.reverse(&2, Ast.ConstructorDecl, acc), []), True{}))

def feedback_pack_18(result: PatternScanOutcome) -> FeedbackControl:
  FeedbackControl{FeedbackDone{Value_18{result}}, Nil{}, NoProgress{}, NoProgress{}}

def pattern_file(pattern: Ast.SyntaxPattern) -> String:
  match pattern:
    case Ast.PatternVar{_, _, _, Ast.SpanOf{file, _, _}}:
      file
    case Ast.PatternCtr{_, _, Ast.SpanOf{file, _, _}}:
      file

def step_pattern_finish(goal: PatternScanGoal, +pattern: Ast.SyntaxPattern, +after: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, ok: Bool) -> FeedbackControl:
  match goal ok:
    case PatternSingleGoal{} status:
      feedback_pack_18(PatternSingleOutcome{pattern, after, scope, depth, status})
    case PatternCaseGoal{acc, before_scope, before_depth} True{}:
      FeedbackControl{FeedbackCall{feedback_make_pattern_scan(after, pattern_file(pattern), PatternExpect{Ast.QOne{}, 0n}, Nil{}, scope, depth, PatternCaseGoal{pattern <> acc, before_scope, before_depth})}, Nil{}, NoProgress{}, NoProgress{}}
    case PatternCaseGoal{acc, before_scope, before_depth} False{}:
      feedback_pack_18(PatternCaseOutcome{List.reverse(&2, Ast.SyntaxPattern, acc), after, before_scope, before_depth, False{}})

def feedback_make_parse_pattern_tuple(file: String, beg: Nat, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackRequest:
  Request_parse_pattern_tuple{file, beg, tokens, scope, depth}

def evaluation_context_parse_typed_operator_namespace_96091(v_11: List<&2, Lexer.Token>, v_303: Ast.SyntaxTerm) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((v_303, v_11), True{})

def feedback_resume_Kont_104727(capture_0: List<&2, Lexer.Token>, result: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_pack_5(evaluation_context_parse_typed_operator_namespace_96091(capture_0, result))

def nat_pattern_tail(+file: String, value: Nat, tail: Ast.SyntaxPattern, +beg: Nat, +end: Nat) -> Ast.SyntaxPattern:
  match value:
    case 0n:
      tail
    case 1n+rest:
      Ast.PatternCtr{"Succ", [nat_pattern_tail(file, rest, tail, beg, end)], span(file, beg, end)}

def pattern_end(pattern: Ast.SyntaxPattern) -> Nat:
  match pattern:
    case Ast.PatternVar{_, _, _, Ast.SpanOf{_, _, end}}:
      end
    case Ast.PatternCtr{_, _, Ast.SpanOf{_, _, end}}:
      end

def step_pattern_nat_tail_result(result: (Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool), +file: String, value: Nat, +beg: Nat, end: Nat, frames: List<&2, PatternFrame>, scope: List<&2, Scope>, +depth: Nat, +goal: PatternScanGoal) -> FeedbackControl:
  match result:
    case ((+tail, after), ((next_scope, next_depth), True{})):
      FeedbackControl{FeedbackCall{feedback_make_pattern_scan(after, file, PatternCompleted{nat_pattern_tail(file, value, tail, beg, pattern_end(tail))}, frames, next_scope, next_depth, goal)}, Nil{}, NoProgress{}, NoProgress{}}
    case ((_, after), ((_, _), False{})):
      step_pattern_finish(goal, Ast.PatternVar{"", depth, Ast.QOne{}, span(file, beg, end)}, after, scope, depth, False{})

def feedback_resume_Kont_130860(capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: Nat, capture_5: List<&2, PatternFrame>, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: PatternScanGoal, result: ((Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool))) -> FeedbackControl:
  step_pattern_nat_tail_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8)

def literal_pattern_fields_cons(result: Maybe<&2, List<&2, Ast.SyntaxPattern>>, head: Ast.SyntaxPattern) -> Maybe<&2, List<&2, Ast.SyntaxPattern>>:
  match result:
    case Some{tail}:
      Some{head <> tail}
    case None{}:
      None{}

def feedback_resume_Kont_136149(capture_1: Ast.SyntaxPattern, result: Maybe<&2, List<&2, Ast.SyntaxPattern>>) -> FeedbackControl:
  feedback_pack_14(literal_pattern_fields_cons(result, capture_1))

def feedback_make_Kont_136149(capture_1: Ast.SyntaxPattern) -> FeedbackFrame:
  Kont_136149{capture_1}

def step_literal_pattern_field(result: Maybe<&2, Ast.SyntaxPattern>, rest: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match result:
    case Some{head}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_literal_pattern_fields(rest)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_136149(head))
    case None{}:
      feedback_pack_14(None{})

def feedback_resume_Kont_136385(capture_1: List<&2, Ast.SyntaxTerm>, result: Maybe<&2, Ast.SyntaxPattern>) -> FeedbackControl:
  step_literal_pattern_field(result, capture_1)

def literal_pattern_constructor(result: Maybe<&2, List<&2, Ast.SyntaxPattern>>, key: String, position: Ast.SourceSpan) -> Maybe<&2, Ast.SyntaxPattern>:
  match result:
    case Some{fields}:
      Some{Ast.PatternCtr{key, fields, position}}
    case None{}:
      None{}

def feedback_resume_Kont_136894(capture_1: String, capture_2: Ast.SourceSpan, result: Maybe<&2, List<&2, Ast.SyntaxPattern>>) -> FeedbackControl:
  feedback_pack_13(literal_pattern_constructor(result, capture_1, capture_2))

def step_pattern_literal_finish(result: Maybe<&2, Ast.SyntaxPattern>, +after: List<&2, Lexer.Token>, +file: String, beg: Nat, end: Nat, frames: List<&2, PatternFrame>, +scope: List<&2, Scope>, +depth: Nat, +goal: PatternScanGoal) -> FeedbackControl:
  match result:
    case Some{pattern}:
      FeedbackControl{FeedbackCall{feedback_make_pattern_scan(after, file, PatternCompleted{pattern}, frames, scope, depth, goal)}, Nil{}, NoProgress{}, NoProgress{}}
    case None{}:
      step_pattern_finish(goal, Ast.PatternVar{"", depth, Ast.QOne{}, span(file, beg, end)}, after, scope, depth, False{})

def feedback_resume_Kont_138041(capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: Nat, capture_4: Nat, capture_5: List<&2, PatternFrame>, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: PatternScanGoal, result: Maybe<&2, Ast.SyntaxPattern>) -> FeedbackControl:
  step_pattern_literal_finish(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8)

def feedback_pack_4(result: ((Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool))) -> FeedbackControl:
  match result:
    case ((result_0_0, result_0_1), ((result_1_0_0, result_1_0_1), result_1_1)):
      FeedbackControl{FeedbackDone{Value_4{result_0_0, result_0_1, result_1_0_0, result_1_0_1, result_1_1}}, Nil{}, NoProgress{}, NoProgress{}}

def pattern_tuple_tail_result(result: (Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool), file: String, beg: Nat, left: Ast.SyntaxPattern) -> (Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool):
  match result:
    case ((+right, after), ((scope, depth), True{})):
      ((Ast.PatternCtr{"Tuple", [left, right], span(file, beg, pattern_end(right))}, after), ((scope, depth), True{}))
    case ((_, after), ((scope, depth), False{})):
      ((left, after), ((scope, depth), False{}))

def feedback_resume_Kont_139772(capture_1: String, capture_2: Nat, capture_3: Ast.SyntaxPattern, result: ((Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool))) -> FeedbackControl:
  feedback_pack_4(pattern_tuple_tail_result(result, capture_1, capture_2, capture_3))

def feedback_make_Kont_139772(capture_1: String, capture_2: Nat, capture_3: Ast.SyntaxPattern) -> FeedbackFrame:
  Kont_139772{capture_1, capture_2, capture_3}

def step_pattern_tuple_delimiter(+tokens: List<&2, Lexer.Token>, +file: String, +beg: Nat, +left: Ast.SyntaxPattern, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match tokens:
    case Lexer.TokenInfo{_, ")", _, _, _, _} <> rest:
      feedback_pack_4(((left, rest), ((scope, depth), True{})))
    case Lexer.TokenInfo{_, ",", _, _, _, _} <> rest:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_parse_pattern_tuple(file, beg, rest, scope, depth)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_139772(file, beg, left))
    case Nil{}:
      feedback_pack_4(((left, (Nil{} : List<&2, Lexer.Token>)), ((scope, depth), False{})))
    case Con{feedback_field_6_0, feedback_field_6_1}:
      feedback_pack_4(((left, (Con{feedback_field_6_0, feedback_field_6_1} : List<&2, Lexer.Token>)), ((scope, depth), False{})))

def step_pattern_tuple_head_result(result: ((Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool)), +file: String, +beg: Nat) -> FeedbackControl:
  match result:
    case ((left, after), ((scope, depth), True{})):
      step_pattern_tuple_delimiter(after, file, beg, left, scope, depth)
    case ((pattern, after), ((scope, depth), False{})):
      feedback_pack_4(((pattern, after), ((scope, depth), False{})))

def feedback_resume_Kont_140603(capture_1: String, capture_2: Nat, result: ((Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool))) -> FeedbackControl:
  step_pattern_tuple_head_result(result, capture_1, capture_2)

def step_pattern_group_result(result: (Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool), file: String, frames: List<&2, PatternFrame>, scope: List<&2, Scope>, depth: Nat, +goal: PatternScanGoal) -> FeedbackControl:
  match result:
    case ((pattern, after), ((next_scope, next_depth), True{})):
      FeedbackControl{FeedbackCall{feedback_make_pattern_scan(after, file, PatternCompleted{pattern}, frames, next_scope, next_depth, goal)}, Nil{}, NoProgress{}, NoProgress{}}
    case ((pattern, after), ((_, _), False{})):
      step_pattern_finish(goal, pattern, after, scope, depth, False{})

def feedback_resume_Kont_143942(capture_1: String, capture_2: List<&2, PatternFrame>, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: PatternScanGoal, result: ((Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool))) -> FeedbackControl:
  step_pattern_group_result(result, capture_1, capture_2, capture_3, capture_4, capture_5)

def pattern_beg(pattern: Ast.SyntaxPattern) -> Nat:
  match pattern:
    case Ast.PatternVar{_, _, _, Ast.SpanOf{_, beg, _}}:
      beg
    case Ast.PatternCtr{_, _, Ast.SpanOf{_, beg, _}}:
      beg

def step_pattern_cons_result(result: (Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool), +file: String, +left: Ast.SyntaxPattern, frames: List<&2, PatternFrame>, scope: List<&2, Scope>, depth: Nat, +goal: PatternScanGoal) -> FeedbackControl:
  match result:
    case ((+right, after), ((next_scope, next_depth), True{})):
      combined = { Ast.PatternCtr{"Con", [left, right], span(file, pattern_beg(left), pattern_end(right))} : Ast.SyntaxPattern }
      FeedbackControl{FeedbackCall{feedback_make_pattern_scan(after, file, PatternCompleted{combined}, frames, next_scope, next_depth, goal)}, Nil{}, NoProgress{}, NoProgress{}}
    case ((_, after), ((_, _), False{})):
      step_pattern_finish(goal, left, after, scope, depth, False{})

def feedback_resume_Kont_149840(capture_1: String, capture_2: Ast.SyntaxPattern, capture_3: List<&2, PatternFrame>, capture_4: List<&2, Scope>, capture_5: Nat, capture_6: PatternScanGoal, result: ((Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool))) -> FeedbackControl:
  step_pattern_cons_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6)

def pattern_single_result(result: PatternScanOutcome, file: String, depth: Nat) -> (Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool):
  match result:
    case PatternSingleOutcome{pattern, after, scope, next_depth, ok}:
      ((pattern, after), ((scope, next_depth), ok))
    case PatternCaseOutcome{patterns, after, scope, next_depth, ok}:
      ((Ast.PatternVar{"", depth, Ast.QOne{}, span(file, 0n, 0n)}, after), ((scope, next_depth), False{}))

def feedback_resume_Kont_171398(capture_1: String, capture_2: Nat, result: PatternScanOutcome) -> FeedbackControl:
  feedback_pack_4(pattern_single_result(result, capture_1, capture_2))

def feedback_resume_Kont_180552(capture_1: String, capture_2: String, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Lexer.Token>, capture_6: List<&2, Scope>, capture_7: Nat, result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_do_atom_args_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7)

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

def feedback_resume_Kont_182168(capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Lexer.Token>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(parse_kind_result(result, capture_1, capture_2, capture_3, capture_4))

def parse_template_term_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((+term, after), True{}):
      ((Ast.TermTemplate{term, span(file, beg, token_end_first(term))}, after), True{})
    case ((term, after), False{}):
      ((term, after), False{})

def feedback_resume_Kont_188249(capture_1: String, capture_2: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(parse_template_term_result(result, capture_1, capture_2))

def append_terms(left: List<&2, Ast.SyntaxTerm>, right: List<&2, Ast.SyntaxTerm>) -> List<&2, Ast.SyntaxTerm>:
  match left:
    case Nil{}:
      right
    case +item <> rest:
      item <> append_terms(rest, right)

def apply_terms(args: List<&2, Ast.SyntaxTerm>, +file: String, +head: Ast.SyntaxTerm, +beg: Nat) -> Ast.SyntaxTerm & Bool:
  match args:
    case Nil{}:
      (head, True{})
    case +arg <> rest:
      apply_terms(rest, file, Ast.TermApp{head, arg, span(file, beg, token_end_first(arg))}, beg)

def do_call_return_type(return_type: Ast.OptionalTerm, prefix: List<&2, Ast.SyntaxTerm>, after_return: List<&2, Ast.SyntaxTerm>) -> List<&2, Ast.SyntaxTerm>:
  match return_type:
    case Ast.NoTerm{}:
      append_terms(prefix, after_return)
    case Ast.SomeTerm{term}:
      append_terms(append_terms(prefix, [term]), after_return)

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

def skip_rewrite_semicolon(tokens: List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:
  match tokens:
    case +semicolon <> rest:
      match semicolon:
        case Lexer.TokenInfo{ _, ";",  _,  _,  _,  _}:
          rest
        case _:
          tokens
    case Nil{}:
      Nil{}

def parse_do_return_call_result(result: Ast.SyntaxTerm & Bool, after_value: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case (call, True{}):
      ((call, skip_rewrite_semicolon(after_value)), True{})
    case (call, False{}):
      ((call, after_value), False{})

def parse_do_return_value_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, key: String, args: List<&2, Ast.SyntaxTerm>, beg: Nat, end: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((value, after_value), True{}):
      parse_do_return_call_result(do_call(file, key, "pure", args, Nil{}, [value], beg, end), after_value)
    case ((value, after_value), False{}):
      ((value, after_value), False{})

def feedback_resume_Kont_188761(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Nat, capture_5: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(parse_do_return_value_result(result, capture_1, capture_2, capture_3, capture_4, capture_5))

def feedback_make_Kont_193205(lexical_capture_4: String, lexical_capture_6: String, lexical_capture_8: List<&2, Ast.SyntaxTerm>, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_13: Ast.SyntaxTerm, lexical_capture_31: Ast.SyntaxTerm, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_22: Nat, lexical_capture_26: Maybe<&2, Ast.Quantity>) -> FeedbackFrame:
  Kont_193205{lexical_capture_4, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_13, lexical_capture_31, lexical_capture_15, lexical_capture_17, lexical_capture_22, lexical_capture_26}

def step_parse_do_typed_bind_value_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, +file: String, +monad: String, +args: List<&2, Ast.SyntaxTerm>, +key: String, key_beg: Nat, ty: Ast.SyntaxTerm, +beg: Nat, +end: Nat, scope: List<&2, Scope>, +depth: Nat, col: Nat, quantity: Maybe<&2, Ast.Quantity>) -> FeedbackControl:
  match result:
    case ((value, after_value), True{}):
      next_scope = extend_scope(key, depth, scope)
      feedback_attach(step_parse_do_return(file, monad, args, skip_rewrite_semicolon(after_value), beg, end, next_scope, (depth + 1n : Nat), col), feedback_make_Kont_193205(file, monad, args, key, key_beg, ty, value, beg, end, depth, quantity))
    case ((value, after_value), False{}):
      feedback_pack_5(((value, after_value), False{}))

def feedback_resume_Kont_190088(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: Nat, capture_8: Nat, capture_9: List<&2, Scope>, capture_10: Nat, capture_11: Nat, capture_12: Maybe<&2, Ast.Quantity>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_do_typed_bind_value_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10, capture_11, capture_12)

def parse_do_typed_bind_call_result(result: Ast.SyntaxTerm & Bool, after_body: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case (call, ok_call):
      ((call, after_body), ok_call)

def parse_do_typed_bind_body_result(ok_body: Bool, body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, +file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, key: String, key_beg: Nat, ty: Ast.SyntaxTerm, +value: Ast.SyntaxTerm, beg: Nat, end: Nat, depth: Nat, quantity: Maybe<&2, Ast.Quantity>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      local_span = span(file, key_beg, token_end_of(after_body, token_end_first(value)))
      parse_do_typed_bind_call_result(do_call(file, monad, "bind", args, [ty], [value, Ast.TermLam{quantity, key, depth, body, local_span}], beg, end), after_body)
    case False{}:
      ((body, after_body), False{})

def with_term_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, use: Ast.SyntaxTerm -> List<&2, Lexer.Token> -> Bool -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((term, after), ok):
      use(term, after, ok)

def feedback_resume_Kont_193205(lexical_capture_4: String, lexical_capture_6: String, lexical_capture_8: List<&2, Ast.SyntaxTerm>, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_13: Ast.SyntaxTerm, lexical_capture_31: Ast.SyntaxTerm, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_22: Nat, lexical_capture_26: Maybe<&2, Ast.Quantity>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, body => after_body => ok_body => parse_do_typed_bind_body_result(ok_body, body, after_body, lexical_capture_4, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_13, lexical_capture_31, lexical_capture_15, lexical_capture_17, lexical_capture_22, lexical_capture_26)))

def do_token_action(bind_token: Lexer.Token) -> DoTokenAction:
  match bind_token:
    case Lexer.TokenInfo{_, "<-", +_, +_, +_, +_}:
      DoTokenActionRow0{}
    case Lexer.TokenInfo{_, "=", _, _, _, _}:
      DoTokenActionRow1{}
    case _:
      DoTokenActionRow2{}

def do_token_branch_2(+bind_token: Lexer.Token, after_bind: List<&2, Lexer.Token>, +file: String) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{"parse-error: expected <- in do binding", span(file, token_beg(bind_token), token_end(bind_token))}, bind_token <> after_bind), False{})

def feedback_make_Kont_190088(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: Nat, capture_8: Nat, capture_9: List<&2, Scope>, capture_10: Nat, capture_11: Nat, capture_12: Maybe<&2, Ast.Quantity>) -> FeedbackFrame:
  Kont_190088{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10, capture_11, capture_12}

def step_do_token_branch_0(after_bind: List<&2, Lexer.Token>, ty: Ast.SyntaxTerm, +file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, key: String, key_beg: Nat, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat, col: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, after_bind, scope, depth, 0n), feedback_make_Kont_190088(file, monad, args, key, key_beg, ty, beg, end, scope, depth, col, None{}))

def feedback_make_Kont_199750(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: Nat, capture_8: Nat, capture_9: List<&2, Scope>, capture_10: Nat, capture_11: Nat) -> FeedbackFrame:
  Kont_199750{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10, capture_11}

def step_parse_do_assignment(+file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, key: String, key_beg: Nat, ty: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat, col: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_199750(file, monad, args, key, key_beg, ty, beg, end, scope, depth, col))

def step_do_token_branch_1(after_bind: List<&2, Lexer.Token>, ty: Ast.SyntaxTerm, +file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, key: String, key_beg: Nat, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat, col: Nat) -> FeedbackControl:
  step_parse_do_assignment(file, monad, args, key, key_beg, ty, after_bind, beg, end, scope, depth, col)

def step_do_token_run(action: DoTokenAction, +bind_token: Lexer.Token, +after_bind: List<&2, Lexer.Token>, +ty: Ast.SyntaxTerm, +file: String, +monad: String, +args: List<&2, Ast.SyntaxTerm>, +key: String, +key_beg: Nat, +beg: Nat, +end: Nat, +scope: List<&2, Scope>, +depth: Nat, +col: Nat) -> FeedbackControl:
  match action:
    case DoTokenActionRow0{}:
      step_do_token_branch_0(after_bind, ty, file, monad, args, key, key_beg, beg, end, scope, depth, col)
    case DoTokenActionRow1{}:
      step_do_token_branch_1(after_bind, ty, file, monad, args, key, key_beg, beg, end, scope, depth, col)
    case DoTokenActionRow2{}:
      feedback_pack_5(do_token_branch_2(bind_token, after_bind, file))

def step_parse_do_typed_bind_type_token(+bind_token: Lexer.Token, after_bind: List<&2, Lexer.Token>, ty: Ast.SyntaxTerm, +file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, key: String, key_beg: Nat, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat, col: Nat) -> FeedbackControl:
  step_do_token_run(do_token_action(bind_token), bind_token, after_bind, ty, file, monad, args, key, key_beg, beg, end, scope, depth, col)

def step_parse_do_typed_bind_type_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, key: String, key_beg: Nat, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> FeedbackControl:
  match result:
    case ((ty, +bind_token <> after_bind), True{}):
      step_parse_do_typed_bind_type_token(bind_token, after_bind, ty, file, monad, args, key, key_beg, beg, end, scope, depth, col)
    case ((ty, after_ty), False{}):
      feedback_pack_5(((ty, after_ty), False{}))
    case ((ty, after_ty), True{}):
      feedback_pack_5(((ty, after_ty), False{}))

def feedback_resume_Kont_194307(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Nat, capture_7: Nat, capture_8: List<&2, Scope>, capture_9: Nat, capture_10: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_do_typed_bind_type_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10)

def feedback_make_Kont_196192(lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: String, lexical_capture_8: String, lexical_capture_10: List<&2, Ast.SyntaxTerm>, lexical_capture_12: String, lexical_capture_14: Nat, lexical_capture_16: Nat, lexical_capture_18: Nat, lexical_capture_21: List<&2, Scope>, lexical_capture_23: Nat, lexical_capture_25: Nat) -> FeedbackFrame:
  Kont_196192{lexical_capture_2, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_18, lexical_capture_21, lexical_capture_23, lexical_capture_25}

def feedback_make_Kont_196508(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: Nat, capture_8: Nat, capture_9: List<&2, Scope>, capture_10: Nat, capture_11: Nat, capture_12: Maybe<&2, Ast.Quantity>) -> FeedbackFrame:
  Kont_196508{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10, capture_11, capture_12}

def step_parse_do_plus_bind_ty(ok_ty: Bool, +ty: Ast.SyntaxTerm, +after_ty: List<&2, Lexer.Token>, +file: String, +monad: String, +args: List<&2, Ast.SyntaxTerm>, +key: String, +key_beg: Nat, +beg: Nat, +end: Nat, +scope: List<&2, Scope>, +depth: Nat, +col: Nat) -> FeedbackControl:
  match ok_ty:
    case True{}:
      match after_ty:
        case Lexer.TokenInfo{_, "=", _, _, _, _} <> after_equals:
          feedback_attach(step_parse_term(file, after_equals, scope, depth, 0n), feedback_make_Kont_196192(ty, file, monad, args, key, key_beg, beg, end, scope, depth, col))
        case Lexer.TokenInfo{_, "<-", _, _, _, _} <> after_bind:
          feedback_attach(step_parse_term(file, after_bind, scope, depth, 0n), feedback_make_Kont_196508(file, monad, args, key, key_beg, ty, beg, end, scope, depth, col, Some{Ast.QMany{}}))
        case +bind_token <> after_bind:
          feedback_pack_5(((Ast.TermHole{"parse-error: expected <- or = in + binding", span(file, beg, end)}, bind_token <> after_bind), False{}))
        case Nil{}:
          feedback_pack_5(((Ast.TermHole{"parse-error: expected = in + binding", span(file, beg, end)}, Nil{}), False{}))
    case False{}:
      feedback_pack_5(((ty, after_ty), False{}))

def feedback_consumer_195302(v_280: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_3: String, v_5: List<&2, Ast.SyntaxTerm>, v_27: String, v_28: Nat, v_9: Nat, v_11: Nat, v_14: List<&2, Scope>, v_16: Nat, v_18: Nat) -> FeedbackControl:
  match v_280:
    case ((v_281, v_282), v_283):
      step_parse_do_plus_bind_ty(v_283, v_281, v_282, v_1, v_3, v_5, v_27, v_28, v_9, v_11, v_14, v_16, v_18)

def feedback_resume_Kont_195319(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: List<&2, Ast.SyntaxTerm>, lexical_capture_27: String, lexical_capture_28: Nat, lexical_capture_9: Nat, lexical_capture_11: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, lexical_capture_18: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_195302(result, lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_27, lexical_capture_28, lexical_capture_9, lexical_capture_11, lexical_capture_14, lexical_capture_16, lexical_capture_18)

def feedback_make_Kont_197434(lexical_capture_7: String, lexical_capture_13: String, lexical_capture_15: Nat, lexical_capture_24: Nat, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_3: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_197434{lexical_capture_7, lexical_capture_13, lexical_capture_15, lexical_capture_24, lexical_capture_2, lexical_capture_3}

def step_parse_do_plus_bind_value(ok_value: Bool, ty: Ast.SyntaxTerm, +value: Ast.SyntaxTerm, +after_value: List<&2, Lexer.Token>, +file: String, +monad: String, +args: List<&2, Ast.SyntaxTerm>, +key: String, +key_beg: Nat, +beg: Nat, +end: Nat, scope: List<&2, Scope>, +depth: Nat, col: Nat) -> FeedbackControl:
  match ok_value:
    case True{}:
      next_scope = extend_scope(key, depth, scope)
      feedback_attach(step_parse_do_return(file, monad, args, skip_rewrite_semicolon(after_value), beg, end, next_scope, (depth + 1n : Nat), col), feedback_make_Kont_197434(file, key, key_beg, depth, ty, value))
    case False{}:
      feedback_pack_5(((value, after_value), False{}))

def feedback_consumer_196175(v_281: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_2: Ast.SyntaxTerm, v_6: String, v_8: String, v_10: List<&2, Ast.SyntaxTerm>, v_12: String, v_14: Nat, v_16: Nat, v_18: Nat, v_21: List<&2, Scope>, v_23: Nat, v_25: Nat) -> FeedbackControl:
  match v_281:
    case ((v_282, v_283), v_284):
      step_parse_do_plus_bind_value(v_284, v_2, v_282, v_283, v_6, v_8, v_10, v_12, v_14, v_16, v_18, v_21, v_23, v_25)

def feedback_resume_Kont_196192(lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: String, lexical_capture_8: String, lexical_capture_10: List<&2, Ast.SyntaxTerm>, lexical_capture_12: String, lexical_capture_14: Nat, lexical_capture_16: Nat, lexical_capture_18: Nat, lexical_capture_21: List<&2, Scope>, lexical_capture_23: Nat, lexical_capture_25: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_196175(result, lexical_capture_2, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_18, lexical_capture_21, lexical_capture_23, lexical_capture_25)

def feedback_resume_Kont_196508(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: Nat, capture_8: Nat, capture_9: List<&2, Scope>, capture_10: Nat, capture_11: Nat, capture_12: Maybe<&2, Ast.Quantity>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_do_typed_bind_value_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10, capture_11, capture_12)

def make_do_assignment_result(term: Ast.SyntaxTerm, after_body: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  ((term, after_body), True{})

def make_do_plus_assignment_term(+file: String, key: String, +key_beg: Nat, depth: Nat, ty: Ast.SyntaxTerm, +value: Ast.SyntaxTerm, body: Ast.SyntaxTerm, after_body: List<&2, Lexer.Token>) -> Ast.SyntaxTerm:
  +value_end = token_end_first(value)
  value_span = span(file, key_beg, value_end)
  Ast.TermLet{[key], [depth], [Ast.QMany{}], [Ast.TermAnn{value, ty, value_span}], body, span(file, key_beg, token_end_of(after_body, value_end))}

def parse_do_plus_bind_body(ok_body: Bool, body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, +file: String, key: String, key_beg: Nat, depth: Nat, ty: Ast.SyntaxTerm, +value: Ast.SyntaxTerm) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      make_do_assignment_result(make_do_plus_assignment_term(file, key, key_beg, depth, ty, value, body, after_body), after_body)
    case False{}:
      ((body, after_body), False{})

def feedback_resume_Kont_197434(lexical_capture_7: String, lexical_capture_13: String, lexical_capture_15: Nat, lexical_capture_24: Nat, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_3: Ast.SyntaxTerm, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, body => after_body => ok_body => parse_do_plus_bind_body(ok_body, body, after_body, lexical_capture_7, lexical_capture_13, lexical_capture_15, lexical_capture_24, lexical_capture_2, lexical_capture_3)))

def make_do_assignment_term(+file: String, key: String, +key_beg: Nat, depth: Nat, ty: Ast.SyntaxTerm, +value: Ast.SyntaxTerm, body: Ast.SyntaxTerm, after_body: List<&2, Lexer.Token>) -> Ast.SyntaxTerm:
  +value_end = token_end_first(value)
  value_span = span(file, key_beg, value_end)
  Ast.TermLet{[key], [depth], [Ast.QOne{}], [Ast.TermAnn{value, ty, value_span}], body, span(file, key_beg, token_end_of(after_body, value_end))}

def parse_do_assignment_body_result(ok_body: Bool, body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, +file: String, key: String, +key_beg: Nat, depth: Nat, ty: Ast.SyntaxTerm, +value: Ast.SyntaxTerm) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      make_do_assignment_result(make_do_assignment_term(file, key, key_beg, depth, ty, value, body, after_body), after_body)
    case False{}:
      ((body, after_body), False{})

def feedback_resume_Kont_199099(lexical_capture_4: String, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_22: Nat, lexical_capture_13: Ast.SyntaxTerm, lexical_capture_29: Ast.SyntaxTerm, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, body => after_body => ok_body => parse_do_assignment_body_result(ok_body, body, after_body, lexical_capture_4, lexical_capture_10, lexical_capture_12, lexical_capture_22, lexical_capture_13, lexical_capture_29)))

def feedback_make_Kont_199099(lexical_capture_4: String, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_22: Nat, lexical_capture_13: Ast.SyntaxTerm, lexical_capture_29: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_199099{lexical_capture_4, lexical_capture_10, lexical_capture_12, lexical_capture_22, lexical_capture_13, lexical_capture_29}

def step_parse_do_assignment_value_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, +file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, +key: String, key_beg: Nat, ty: Ast.SyntaxTerm, beg: Nat, end: Nat, scope: List<&2, Scope>, +depth: Nat, col: Nat) -> FeedbackControl:
  match result:
    case ((value, after_value), True{}):
      next_scope = extend_scope(key, depth, scope)
      feedback_attach(step_parse_do_return(file, monad, args, skip_rewrite_semicolon(after_value), beg, end, next_scope, (depth + 1n : Nat), col), feedback_make_Kont_199099(file, key, key_beg, depth, ty, value))
    case ((value, after_value), False{}):
      feedback_pack_5(((value, after_value), False{}))

def feedback_resume_Kont_199750(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: Nat, capture_8: Nat, capture_9: List<&2, Scope>, capture_10: Nat, capture_11: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_do_assignment_value_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10, capture_11)

def feedback_make_Kont_203745(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: List<&2, Ast.SyntaxTerm>, lexical_capture_6: Ast.SyntaxTerm, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_18: Nat) -> FeedbackFrame:
  Kont_203745{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_6, lexical_capture_7, lexical_capture_11, lexical_capture_13, lexical_capture_18}

def step_parse_do_bind(+file: String, +monad: String, +args: List<&2, Ast.SyntaxTerm>, ty: Ast.SyntaxTerm, value: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, +beg: Nat, +end: Nat, scope: List<&2, Scope>, +depth: Nat, col: Nat) -> FeedbackControl:
  next_scope = extend_scope("_", depth, scope)
  feedback_attach(step_parse_do_return(file, monad, args, skip_rewrite_semicolon(tokens), beg, end, next_scope, (depth + 1n : Nat), col), feedback_make_Kont_203745(file, monad, args, ty, value, beg, end, depth))

def step_parse_do_untyped_value_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, action: Ast.SyntaxTerm, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> FeedbackControl:
  match result:
    case ((value, after_value), True{}):
      step_parse_do_bind(file, monad, args, action, value, after_value, beg, end, scope, depth, col)
    case ((value, after_value), False{}):
      feedback_pack_5(((value, after_value), False{}))

def feedback_resume_Kont_201815(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Ast.SyntaxTerm, capture_5: Nat, capture_6: Nat, capture_7: List<&2, Scope>, capture_8: Nat, capture_9: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_do_untyped_value_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9)

def feedback_make_Kont_201815(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Ast.SyntaxTerm, capture_5: Nat, capture_6: Nat, capture_7: List<&2, Scope>, capture_8: Nat, capture_9: Nat) -> FeedbackFrame:
  Kont_201815{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9}

def do_final_type(args: List<&2, Ast.SyntaxTerm>, +head: Ast.SyntaxTerm, +source_span: Ast.SourceSpan) -> Ast.SyntaxTerm:
  match args:
    case Nil{}:
      head
    case +arg <> rest:
      do_final_type(rest, Ast.TermApp{head, arg, source_span}, source_span)

def parse_do_final_action(+file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, +action: Ast.SyntaxTerm, after_action: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  +source_span = span(file, token_beg_first(action), token_end_first(action))
  ty = do_final_type(args, Ast.TermRef{monad, source_span}, source_span)
  ((Ast.TermAnn{action, ty, source_span}, after_action), True{})

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

def step_parse_do_untyped_step_after_check(has_more: Bool, +file: String, +monad: String, +args: List<&2, Ast.SyntaxTerm>, +action: Ast.SyntaxTerm, +tokens: List<&2, Lexer.Token>, +beg: Nat, +end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> FeedbackControl:
  match has_more:
    case True{}:
      step_parse_do_bind(file, monad, args, Ast.TermRef{ "Unit",  span(file, beg, end)}, action, tokens, beg, end, scope, depth, col)
    case False{}:
      feedback_pack_5(parse_do_final_action(file, monad, args, action, tokens))

def step_parse_do_untyped_step(file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, action: Ast.SyntaxTerm, +tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, +col: Nat) -> FeedbackControl:
  step_parse_do_untyped_step_after_check(do_has_more(tokens, col), file, monad, args, action, tokens, beg, end, scope, depth, col)

def step_parse_do_untyped_after_action(+file: String, +monad: String, +args: List<&2, Ast.SyntaxTerm>, +action: Ast.SyntaxTerm, +after_action: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +beg: Nat, +end: Nat, +scope: List<&2, Scope>, +depth: Nat, +col: Nat) -> FeedbackControl:
  match scanned:
    case +bind_token <> after_bind:
      match bind_token:
        case Lexer.TokenInfo{_, "<-", _, _, _, _}:
          feedback_attach(step_parse_term(file, after_bind, scope, depth, 0n), feedback_make_Kont_201815(file, monad, args, action, beg, end, scope, depth, col))
        case _:
          step_parse_do_untyped_step(file, monad, args, action, after_action, beg, end, scope, depth, col)
    case Nil{}:
      feedback_pack_5(parse_do_final_action(file, monad, args, action, after_action))

def step_parse_do_untyped_action_result(ok: Bool, +action: Ast.SyntaxTerm, +after_action: List<&2, Lexer.Token>, file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> FeedbackControl:
  match ok:
    case True{}:
      step_parse_do_untyped_after_action(file, monad, args, action, after_action, skip_rewrite_semicolon(after_action), beg, end, scope, depth, col)
    case False{}:
      feedback_pack_5(((action, after_action), False{}))

def feedback_consumer_200127(v_282: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_4: String, v_6: String, v_8: List<&2, Ast.SyntaxTerm>, v_10: Nat, v_12: Nat, v_15: List<&2, Scope>, v_17: Nat, v_19: Nat) -> FeedbackControl:
  match v_282:
    case ((v_283, v_284), v_285):
      step_parse_do_untyped_action_result(v_285, v_283, v_284, v_4, v_6, v_8, v_10, v_12, v_15, v_17, v_19)

def step_parse_do_untyped_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> FeedbackControl:
  feedback_consumer_200127(result, file, monad, args, beg, end, scope, depth, col)

def feedback_resume_Kont_202383(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Nat, capture_5: Nat, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_do_untyped_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8)

def parse_do_bind_call_result(result: Ast.SyntaxTerm & Bool, after_body: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case (call, ok_call):
      ((call, after_body), ok_call)

def parse_do_bind_body_result(ok_body: Bool, body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, +file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, ty: Ast.SyntaxTerm, +value: Ast.SyntaxTerm, +beg: Nat, end: Nat, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      parse_do_bind_call_result(do_call(file, monad, "bind", args, [ty], [value, Ast.TermLam{None{}, "_", depth, body, span(file, beg, token_end_of(after_body, token_end_first(value)))}], beg, end), after_body)
    case False{}:
      ((body, after_body), False{})

def feedback_resume_Kont_203745(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: List<&2, Ast.SyntaxTerm>, lexical_capture_6: Ast.SyntaxTerm, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_18: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, body => after_body => ok_body => parse_do_bind_body_result(ok_body, body, after_body, lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_6, lexical_capture_7, lexical_capture_11, lexical_capture_13, lexical_capture_18)))

def feedback_make_Kont_82236(capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Lexer.Token>, capture_6: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_82236{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6}

def step_parse_nat_literal_tail_quantity_0(v_12: List<&2, Lexer.Token>, +v_17: List<&2, Lexer.Token>, +v_16: Ast.SyntaxTerm, v_4: String, +v_6: Nat, v_8: Nat, v_10: Nat) -> FeedbackControl:
  feedback_attach(step_nat_literal_tokens(v_12, token_end_of(v_17, token_end_first(v_16))), feedback_make_Kont_82236(v_4, v_6, v_8, v_10, v_17, v_16))

def step_parse_nat_literal_tail(v_2: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_4: String, +v_6: Nat, v_8: Nat, v_10: Nat, v_12: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_2:
    case ((+v_16, v_17), True{}):
      step_parse_nat_literal_tail_quantity_0(v_12, v_17, v_16, v_4, v_6, v_8, v_10)
    case ((v_25, v_26), False{}):
      feedback_pack_5(((v_25, v_26), False{}))

def feedback_resume_Kont_206710(capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Lexer.Token>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_nat_literal_tail(result, capture_1, capture_2, capture_3, capture_4, capture_5)

def expr_finish_list(result: Ast.SyntaxTerm & Bool, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case (list, good):
      ((list, rest), good)

def feedback_make_Kont_209050(lexical_capture_4: String, lexical_capture_5: Ast.SyntaxTerm, lexical_capture_7: Nat) -> FeedbackFrame:
  Kont_209050{lexical_capture_4, lexical_capture_5, lexical_capture_7}

def make_list_cons(item: Ast.SyntaxTerm, result: Ast.SyntaxTerm & Bool, file: String, beg: Nat, end: Nat) -> Ast.SyntaxTerm & Bool:
  match result:
    case (tail, ok):
      (Ast.TermCtr{"Con", [item, tail], span(file, beg, end)}, ok)

def make_list(+file: String, items: List<&2, Ast.SyntaxTerm>, +beg: Nat, +end: Nat) -> Ast.SyntaxTerm & Bool:
  match items:
    case Nil{}:
      (Ast.TermCtr{"Nil", Nil{}, span(file, beg, end)}, True{})
    case +item <> rest:
      make_list_cons(item, make_list(file, rest, beg, end), file, beg, end)

def feedback_make_Kont_209742(capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Scope>, capture_6: Nat) -> FeedbackFrame:
  Kont_209742{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6}

def step_parse_array_literal(+file: String, value: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, tokens, scope, depth, 12n), feedback_make_Kont_209742(file, value, beg, end, scope, depth))

def step_expr_match_list_separator(+separator: Lexer.Token, +after_separator: List<&2, Lexer.Token>, +file: String, +first: Ast.SyntaxTerm, +beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match separator:
    case Lexer.TokenInfo{_, ":", +_, +_, +_, +_}:
      step_parse_array_literal(file, first, after_separator, beg, end, scope, depth)
    case Lexer.TokenInfo{_, ",", _, _, _, _}:
      feedback_attach(step_parse_term_args(file, after_separator, "]", scope, depth, Nil{}), feedback_make_Kont_209050(file, first, beg))
    case Lexer.TokenInfo{_, "]", _, _, _, _}:
      feedback_pack_5(expr_finish_list(make_list(file, [first], beg, token_end(separator)), after_separator))
    case Lexer.TokenInfo{+feedback_field_8_0, +feedback_field_8_1, +feedback_field_8_2, +feedback_field_8_3, +feedback_field_8_4, +feedback_field_8_5}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected , : or ]", span(file, token_beg((Lexer.TokenInfo{feedback_field_8_0, feedback_field_8_1, feedback_field_8_2, feedback_field_8_3, feedback_field_8_4, feedback_field_8_5} : Lexer.Token)), token_end((Lexer.TokenInfo{feedback_field_8_0, feedback_field_8_1, feedback_field_8_2, feedback_field_8_3, feedback_field_8_4, feedback_field_8_5} : Lexer.Token)))}, after_separator), False{}))

def step_expr_match_ok_after(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match result:
    case ((first, +separator <> after_separator), True{}):
      step_expr_match_list_separator(separator, after_separator, file, first, beg, end, scope, depth)
    case ((first, after_first), False{}):
      feedback_pack_5(((first, after_first), False{}))
    case ((first, after_first), True{}):
      feedback_pack_5(((first, after_first), False{}))

def feedback_resume_Kont_207865(capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Scope>, capture_5: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_expr_match_ok_after(result, capture_1, capture_2, capture_3, capture_4, capture_5)

def expr_finish_list_items(ok_items: Bool, items: List<&2, Ast.SyntaxTerm>, +after_items: List<&2, Lexer.Token>, file: String, +first: Ast.SyntaxTerm, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_items:
    case True{}:
      expr_finish_list(make_list(file, first <> items, beg, token_end_of(after_items, token_end_first(first))), after_items)
    case False{}:
      ((Ast.TermHole{"parse-error: expected ]", span(file, token_end_first(first), token_end_first(first))}, after_items), False{})

def with_args_result(result: (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool, use: List<&2, Ast.SyntaxTerm> -> List<&2, Lexer.Token> -> Bool -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((args, after), ok):
      use(args, after, ok)

def feedback_resume_Kont_209050(lexical_capture_4: String, lexical_capture_5: Ast.SyntaxTerm, lexical_capture_7: Nat, result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_args_result(result, items => after_items => ok_items => expr_finish_list_items(ok_items, items, after_items, lexical_capture_4, lexical_capture_5, lexical_capture_7)))

def array_shape_action(shape: Lexer.Token) -> ArrayShapeAction:
  match shape:
    case Lexer.TokenInfo{_, "*", +_, +_, +_, +_}:
      ArrayShapeActionRow0{}
    case Lexer.TokenInfo{_, "^", _, _, _, _}:
      ArrayShapeActionRow1{}
    case _:
      ArrayShapeActionRow2{}

def array_shape_branch_2(+shape: Lexer.Token, after_shape: List<&2, Lexer.Token>, +file: String) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{"parse-error: expected * or ^ in array literal", span(file, token_beg(shape), token_end(shape))}, shape <> after_shape), False{})

def feedback_make_Kont_210467(capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Ast.SyntaxTerm, capture_4: Nat, capture_5: Nat) -> FeedbackFrame:
  Kont_210467{capture_1, capture_2, capture_3, capture_4, capture_5}

def step_array_shape_branch_0(after_shape: List<&2, Lexer.Token>, +file: String, value: Ast.SyntaxTerm, ty: Ast.SyntaxTerm, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, after_shape, scope, depth, 0n), feedback_make_Kont_210467(file, value, ty, beg, end))

def feedback_make_Kont_210804(capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Ast.SyntaxTerm, capture_4: Nat, capture_5: Nat) -> FeedbackFrame:
  Kont_210804{capture_1, capture_2, capture_3, capture_4, capture_5}

def step_array_shape_branch_1(after_shape: List<&2, Lexer.Token>, +file: String, value: Ast.SyntaxTerm, ty: Ast.SyntaxTerm, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, after_shape, scope, depth, 0n), feedback_make_Kont_210804(file, value, ty, beg, end))

def step_array_shape_run(action: ArrayShapeAction, +shape: Lexer.Token, +after_shape: List<&2, Lexer.Token>, +file: String, +value: Ast.SyntaxTerm, +ty: Ast.SyntaxTerm, +beg: Nat, +end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match action:
    case ArrayShapeActionRow0{}:
      step_array_shape_branch_0(after_shape, file, value, ty, beg, end, scope, depth)
    case ArrayShapeActionRow1{}:
      step_array_shape_branch_1(after_shape, file, value, ty, beg, end, scope, depth)
    case ArrayShapeActionRow2{}:
      feedback_pack_5(array_shape_branch_2(shape, after_shape, file))

def step_expr_match_array_shape(+shape: Lexer.Token, after_shape: List<&2, Lexer.Token>, +file: String, value: Ast.SyntaxTerm, ty: Ast.SyntaxTerm, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  step_array_shape_run(array_shape_action(shape), shape, after_shape, file, value, ty, beg, end, scope, depth)

def step_expr_match_array_type(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, value: Ast.SyntaxTerm, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match result:
    case ((ty, +shape <> after_shape), True{}):
      step_expr_match_array_shape(shape, after_shape, file, value, ty, beg, end, scope, depth)
    case ((ty, after_ty), False{}):
      feedback_pack_5(((ty, after_ty), False{}))
    case ((ty, after_ty), True{}):
      feedback_pack_5(((ty, after_ty), False{}))

def feedback_resume_Kont_209742(capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Scope>, capture_6: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_expr_match_array_type(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6)

def array_call_result(result: Ast.SyntaxTerm & Bool, after: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case (term, ok):
      ((term, after), ok)

def array_call(+file: String, ty: Ast.SyntaxTerm, depth: Ast.SyntaxTerm, value: Ast.SyntaxTerm, +beg: Nat, end: Nat, after: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  array_call_result(apply_terms([ty, depth, value], file, Ast.TermRef{"Array.new", span(file, beg, end)}, beg), after)

def expr_match_array_power(array_power: Maybe<&2, Nat>, +file: String, value: Ast.SyntaxTerm, ty: Ast.SyntaxTerm, +count: Ast.SyntaxTerm, close: Lexer.Token, after_close: List<&2, Lexer.Token>, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match array_power:
    case Some{array_depth}:
      array_call(file, ty, nat_literal(file, array_depth, token_beg_first(count), token_end_first(count)), value, beg, token_end(close), after_close)
    case None{}:
      ((Ast.TermHole{ "parse-error: array count must be a power of two",  span(file, token_beg_first(count), token_end_first(count))}, after_close), False{})

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
          power_depth_go(rest, (depth + 1n : Nat), power_depth_step(half))
        case PowerDepthInvalid{}:
          None{}

def power_depth(+count: Nat, depth: Nat) -> Maybe<&2, Nat>:
  power_depth_go(count, depth, power_depth_step(count))
# Only literal token chains and grouping produce compact native Nat literals.
# Explicit constructors, annotations and open tails retain their original AST.

def expr_match_array_nat(nat_count: Maybe<&2, Nat>, file: String, value: Ast.SyntaxTerm, ty: Ast.SyntaxTerm, +count: Ast.SyntaxTerm, close: Lexer.Token, after_close: List<&2, Lexer.Token>, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match nat_count:
    case Some{count_value}:
      expr_match_array_power(power_depth(count_value, 0n), file, value, ty, count, close, after_close, beg)
    case None{}:
      ((Ast.TermHole{ "parse-error: array count must be a natural",  span(file, token_beg_first(count), token_end_first(count))}, after_close), False{})

def nat_from_syntax_successor(result: Maybe<&2, Nat>) -> Maybe<&2, Nat>:
  match result:
    case Some{value}:
      Some{(value + 1n : Nat)}
    case None{}:
      None{}

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
          Maybe.map(&2, Nat, Nat, tail => (tail * 2n : Nat), syntax_word_value_go(rest, value, syntax_word_step(rest)))
        case SyntaxWordOneBit{}:
          Maybe.map(&2, Nat, Nat, tail => ((tail * 2n : Nat) + 1n : Nat), syntax_word_value_go(rest, value, syntax_word_step(rest)))
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

def feedback_resume_Kont_210467(capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Ast.SyntaxTerm, capture_4: Nat, capture_5: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(expr_match_array_count(result, capture_1, capture_2, capture_3, capture_4, capture_5))

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

def feedback_resume_Kont_210804(capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Ast.SyntaxTerm, capture_4: Nat, capture_5: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(expr_match_array_depth(result, capture_1, capture_2, capture_3, capture_4, capture_5))

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

def feedback_make_Kont_214597(capture_1: String, capture_2: List<&2, Lexer.Token>, capture_3: Nat, capture_4: List<&2, Scope>, capture_5: Nat) -> FeedbackFrame:
  Kont_214597{capture_1, capture_2, capture_3, capture_4, capture_5}

def step_parse_parenthesized_body(+file: String, +tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_body(file, tokens, scope, depth, col), feedback_make_Kont_214597(file, tokens, beg, scope, depth))

def step_parse_parenthesized_result(result: (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool, +file: String, +beg: Nat, +end: Nat, tokens: List<&2, Lexer.Token>, col: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match result:
    case ((terms, after), True{}):
      feedback_pack_5(parse_parenthesized_terms(terms, after, file, beg, end))
    case (_, False{}):
      step_parse_parenthesized_body(file, tokens, beg, end, col, scope, depth)

def feedback_resume_Kont_213361(capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Lexer.Token>, capture_5: Nat, capture_6: List<&2, Scope>, capture_7: Nat, result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_parenthesized_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7)

def parse_parenthesized_body_result(body: Ast.SyntaxTerm, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match body:
    case Ast.BodyReply{term,  _}:
      ((term, rest), True{})
    case _:
      ((body, rest), True{})

def feedback_make_Kont_215921(capture_1: String, capture_2: List<&2, Scope>, capture_3: Nat) -> FeedbackFrame:
  Kont_215921{capture_1, capture_2, capture_3}

def step_parse_typed_operator(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_215921(file, scope, depth))

def step_parse_parenthesized_body_close(close: Lexer.Token, rest: List<&2, Lexer.Token>, body: Ast.SyntaxTerm, file: String, tokens: List<&2, Lexer.Token>, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match close:
    case Lexer.TokenInfo{_, ")", _, _, _, _}:
      feedback_pack_5(parse_parenthesized_body_result(body, rest))
    case _:
      step_parse_typed_operator(file, tokens, beg, scope, depth)

def step_parse_parenthesized_body_result_checked(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, +file: String, +tokens: List<&2, Lexer.Token>, +beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match result:
    case ((body, +close <> rest), True{}):
      step_parse_parenthesized_body_close(close, rest, body, file, tokens, beg, scope, depth)
    case _:
      step_parse_typed_operator(file, tokens, beg, scope, depth)

def feedback_resume_Kont_214597(capture_1: String, capture_2: List<&2, Lexer.Token>, capture_3: Nat, capture_4: List<&2, Scope>, capture_5: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_parenthesized_body_result_checked(result, capture_1, capture_2, capture_3, capture_4, capture_5)

def feedback_make_Kont_104727(capture_0: List<&2, Lexer.Token>) -> FeedbackFrame:
  Kont_104727{capture_0}

def step_parse_typed_operator_namespace(v_1: Bool, v_3: String, v_4: Ast.SyntaxTerm, v_6: String, +v_7: Ast.SyntaxTerm, v_9: List<&2, Lexer.Token>, v_11: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_1:
    case True{}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a type name after :", span(v_3, token_beg_first(v_7), token_end_first(v_7))}, v_9), False{}))
    case False{}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_4, v_6)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_104727(v_11))

def term_head_name(term: Ast.SyntaxTerm) -> String:
  match term:
    case Ast.TermVar{key,  _,  _}:
      key
    case Ast.TermRef{key,  _}:
      key
    case Ast.TermAdt{key,  _,  _,  _}:
      key
    case Ast.TermFill{head,  _,  _}:
      term_head_name(head)
    case Ast.TermPlus{head,  _,  _}:
      term_head_name(head)
    case _:
      ""

def step_parse_typed_operator_close(close: Lexer.Token, +tail: List<&2, Lexer.Token>, +ty: Ast.SyntaxTerm, +file: String, term: Ast.SyntaxTerm) -> FeedbackControl:
  match close:
    case Lexer.TokenInfo{kind, ")", beg, +end, line, col}:
      +namespace = term_head_name(ty)
      step_parse_typed_operator_namespace(String.eq(namespace, ""), file, term, namespace, ty, Lexer.TokenInfo{kind, ")", beg, end, line, col} <> tail, tail)
    case Lexer.TokenInfo{kind, text, +beg, +end, line, col}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected )", span(file, beg, end)}, Lexer.TokenInfo{kind, text, beg, end, line, col} <> tail), False{}))

def step_parse_typed_operator_type(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, term: Ast.SyntaxTerm) -> FeedbackControl:
  match result:
    case ((ty, close <> tail), True{}):
      step_parse_typed_operator_close(close, tail, ty, file, term)
    case ((ty, after_ty), False{}):
      feedback_pack_5(((ty, after_ty), False{}))
    case ((ty, after_ty), True{}):
      feedback_pack_5(((ty, after_ty), False{}))

def feedback_resume_Kont_215020(capture_1: String, capture_2: Ast.SyntaxTerm, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_typed_operator_type(result, capture_1, capture_2)

def feedback_make_Kont_215020(capture_1: String, capture_2: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_215020{capture_1, capture_2}

def step_parse_typed_operator_colon(+colon: Lexer.Token, after_colon: List<&2, Lexer.Token>, after_term: List<&2, Lexer.Token>, term: Ast.SyntaxTerm, +file: String, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match colon:
    case Lexer.TokenInfo{_, ":", +_, +_, +_, +_}:
      feedback_attach(step_parse_term(file, after_colon, scope, depth, 0n), feedback_make_Kont_215020(file, term))
    case Lexer.TokenInfo{+feedback_field_4_0, +feedback_field_4_1, +feedback_field_4_2, +feedback_field_4_3, +feedback_field_4_4, +feedback_field_4_5}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected :", span(file, token_beg((Lexer.TokenInfo{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4, feedback_field_4_5} : Lexer.Token)), token_end((Lexer.TokenInfo{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4, feedback_field_4_5} : Lexer.Token)))}, after_term), False{}))

def step_parse_typed_operator_term(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match result:
    case ((term, +colon <> +after_colon), True{}):
      step_parse_typed_operator_colon(colon, after_colon, colon <> after_colon, term, file, scope, depth)
    case ((term, after_term), False{}):
      feedback_pack_5(((term, after_term), False{}))
    case ((term, after_term), True{}):
      feedback_pack_5(((term, after_term), False{}))

def feedback_resume_Kont_215921(capture_1: String, capture_2: List<&2, Scope>, capture_3: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_typed_operator_term(result, capture_1, capture_2, capture_3)

def step_parse_match_chain(file: String, key: String, head: Ast.SyntaxTerm, +tokens: List<&2, Lexer.Token>, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  FeedbackControl{FeedbackCall{feedback_make_parse_match_chain_state(MatchChainStart{file, key, head, tokens, skip_lines(tokens), beg, scope, depth})}, Nil{}, NoProgress{}, NoProgress{}}

def step_parse_match_expr_after_head(+file: String, +key: String, +head: Ast.SyntaxTerm, +after_head: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match scanned:
    case +semicolon <> after_semicolon:
      match semicolon:
        case Lexer.TokenInfo{ _, ";",  _,  _,  _,  _}:
          step_parse_match_chain(file, key, head, after_semicolon, beg, scope, depth)
        case _:
          step_parse_match_chain(file, key, head, after_head, beg, scope, depth)
    case Nil{}:
      step_parse_match_chain(file, key, head, after_head, beg, scope, depth)

def step_parse_match_expr_parsed_head(ok: Bool, +head: Ast.SyntaxTerm, +after_head: List<&2, Lexer.Token>, file: String, key: String, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match ok:
    case True{}:
      step_parse_match_expr_after_head(file, key, head, after_head, skip_lines(after_head), beg, scope, depth)
    case False{}:
      feedback_pack_5(((head, after_head), False{}))

def feedback_consumer_217852(v_283: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_4: String, v_6: String, v_8: Nat, v_11: List<&2, Scope>, v_13: Nat) -> FeedbackControl:
  match v_283:
    case ((v_284, v_285), v_286):
      step_parse_match_expr_parsed_head(v_286, v_284, v_285, v_4, v_6, v_8, v_11, v_13)

def step_parse_match_expr_head_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, key: String, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  feedback_consumer_217852(result, file, key, beg, scope, depth)

def feedback_resume_Kont_218787(capture_1: String, capture_2: String, capture_3: Nat, capture_4: List<&2, Scope>, capture_5: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_match_expr_head_result(result, capture_1, capture_2, capture_3, capture_4, capture_5)

def feedback_consumer_220900_quantity_0(v_6: String, v_8: String, v_9: Ast.SyntaxTerm, v_11: List<&2, Lexer.Token>, v_13: String, v_25: Ast.SyntaxTerm, +v_26: List<&2, Lexer.Token>, v_27: Bool, v_15: Nat, v_18: List<&2, Scope>, v_20: Nat) -> FeedbackControl:
  FeedbackControl{FeedbackCall{feedback_make_parse_match_chain_state(MatchChainAfterHead{v_6, v_8, v_9, v_11, v_13, v_25, v_26, v_27, skip_lines(v_26), v_15, v_18, v_20})}, [], NoProgress{}, NoProgress{}}

def feedback_consumer_220900(v_4: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_6: String, v_8: String, v_9: Ast.SyntaxTerm, v_11: List<&2, Lexer.Token>, v_13: String, v_15: Nat, v_18: List<&2, Scope>, v_20: Nat) -> FeedbackControl:
  match v_4:
    case ((v_25, v_26), v_27):
      feedback_consumer_220900_quantity_0(v_6, v_8, v_9, v_11, v_13, v_25, v_26, v_27, v_15, v_18, v_20)

def feedback_resume_Kont_220917(lexical_capture_49: String, lexical_capture_50: String, lexical_capture_51: Ast.SyntaxTerm, lexical_capture_52: List<&2, Lexer.Token>, lexical_capture_53: String, lexical_capture_55: Nat, lexical_capture_56: List<&2, Scope>, lexical_capture_57: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_220900(result, lexical_capture_49, lexical_capture_50, lexical_capture_51, lexical_capture_52, lexical_capture_53, lexical_capture_55, lexical_capture_56, lexical_capture_57)

def feedback_consumer_221731(v_286: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_98: String, v_99: String, v_100: Ast.SyntaxTerm, v_107: Nat) -> FeedbackControl:
  match v_286:
    case ((v_287, v_288), v_289):
      FeedbackControl{FeedbackCall{feedback_make_parse_match_chain_state(MatchChainAfterMatch{v_98, v_99, v_100, v_287, v_288, v_289, v_107})}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_resume_Kont_221748(lexical_capture_98: String, lexical_capture_99: String, lexical_capture_100: Ast.SyntaxTerm, lexical_capture_107: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_221731(result, lexical_capture_98, lexical_capture_99, lexical_capture_100, lexical_capture_107)

def feedback_consumer_222071(v_285: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_98: String, v_99: String, v_100: Ast.SyntaxTerm, v_107: Nat) -> FeedbackControl:
  match v_285:
    case ((v_286, v_287), v_288):
      FeedbackControl{FeedbackCall{feedback_make_parse_match_chain_state(MatchChainAfterMatch{v_98, v_99, v_100, v_286, v_287, v_288, v_107})}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_resume_Kont_222088(lexical_capture_98: String, lexical_capture_99: String, lexical_capture_100: Ast.SyntaxTerm, lexical_capture_107: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_222071(result, lexical_capture_98, lexical_capture_99, lexical_capture_100, lexical_capture_107)

def feedback_consumer_222397(v_284: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_98: String, v_99: String, v_100: Ast.SyntaxTerm, v_107: Nat) -> FeedbackControl:
  match v_284:
    case ((v_285, v_286), v_287):
      FeedbackControl{FeedbackCall{feedback_make_parse_match_chain_state(MatchChainAfterMatch{v_98, v_99, v_100, v_285, v_286, v_287, v_107})}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_resume_Kont_222414(lexical_capture_98: String, lexical_capture_99: String, lexical_capture_100: Ast.SyntaxTerm, lexical_capture_107: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_222397(result, lexical_capture_98, lexical_capture_99, lexical_capture_100, lexical_capture_107)

def parse_match_tail_with_head_result(ok_tail: Bool, +tail: Ast.SyntaxTerm, +after_tail: List<&2, Lexer.Token>, file: String, key: String, head: Ast.SyntaxTerm, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_tail:
    case True{}:
      ((Ast.TermMat{key, head, tail, span(file, beg, token_end_of(after_tail, token_end_first(tail)))}, after_tail), True{})
    case False{}:
      ((tail, after_tail), False{})

def feedback_resume_Kont_223608(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_8: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, tail => after_tail => ok_tail => parse_match_tail_with_head_result(ok_tail, tail, after_tail, lexical_capture_1, lexical_capture_3, lexical_capture_4, lexical_capture_8)))

def match_tail_scan_is_colon(close: Lexer.Token) -> MatchTailScanAction:
  match close:
    case Lexer.TokenInfo{ _, ";",  _,  _,  _,  _}:
      MatchTailScanRow0{}
    case Lexer.TokenInfo{ _, "}",  _,  _,  _,  _}:
      MatchTailScanRow1{}
    case _:
      MatchTailScanRow2{}

def match_tail_is_colon(end: Lexer.Token) -> Bool:
  match end:
    case Lexer.TokenInfo{ _, "}",  _,  _,  _,  _}:
      True{}
    case _:
      False{}

def match_tail_branch_0(tail: Ast.SyntaxTerm, after_end: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((tail, after_end), True{})

def match_tail_branch_1(file: String, rest: List<&2, Lexer.Token>, +end: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected } after match tail",  span(file, token_beg(end), token_end(end))}, rest), False{})

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

def match_tail_scan_branch_0(file: String, +tail: Ast.SyntaxTerm, +close: Lexer.Token, +rest: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  parse_match_tail_after_semicolon(file, tail, close, rest, skip_lines(rest))

def match_tail_scan_branch_1(+tail: Ast.SyntaxTerm, +rest: List<&2, Lexer.Token>) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((tail, rest), True{})

def match_tail_scan_branch_2(file: String, after_tail: List<&2, Lexer.Token>, +close: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected } after match tail",  span(file, token_beg(close), token_end(close))}, after_tail), False{})

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

def feedback_resume_Kont_223961(lexical_capture_1: String, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, tail => after_tail => ok_tail => parse_match_tail_result(ok_tail, lexical_capture_1, tail, after_tail)))

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

def feedback_resume_Kont_224348(lexical_capture_2: String, lexical_capture_3: Ast.SyntaxTerm, lexical_capture_0: Ast.SyntaxTerm, lexical_capture_5: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, ty => after_ty => ok_ty => parse_brace_equal_type_result(ok_ty, after_ty, ty, lexical_capture_2, lexical_capture_3, lexical_capture_0, lexical_capture_5)))

def brace_equal_right_is_colon(colon: Lexer.Token) -> Bool:
  match colon:
    case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
      True{}
    case _:
      False{}

def brace_equal_right_branch_1(after_right: List<&2, Lexer.Token>, +file: String, +colon: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected :",  span(file, token_beg(colon), token_end(colon))}, after_right), False{})

def feedback_make_Kont_224348(lexical_capture_2: String, lexical_capture_3: Ast.SyntaxTerm, lexical_capture_0: Ast.SyntaxTerm, lexical_capture_5: Nat) -> FeedbackFrame:
  Kont_224348{lexical_capture_2, lexical_capture_3, lexical_capture_0, lexical_capture_5}

def step_brace_equal_right_branch_0(right: Ast.SyntaxTerm, +file: String, left: Ast.SyntaxTerm, beg: Nat, scope: List<&2, Scope>, depth: Nat, after_colon: List<&2, Lexer.Token>) -> FeedbackControl:
  feedback_attach(step_parse_term(file, after_colon, scope, depth, 0n), feedback_make_Kont_224348(file, left, right, beg))

def step_brace_equal_right_run(is_colon: Bool, after_right: List<&2, Lexer.Token>, right: Ast.SyntaxTerm, +file: String, left: Ast.SyntaxTerm, beg: Nat, scope: List<&2, Scope>, depth: Nat, +colon: Lexer.Token, after_colon: List<&2, Lexer.Token>) -> FeedbackControl:
  match is_colon:
    case True{}:
      step_brace_equal_right_branch_0(right, file, left, beg, scope, depth, after_colon)
    case False{}:
      feedback_pack_5(brace_equal_right_branch_1(after_right, file, colon))

def step_parse_brace_equal_right_result(ok_right: Bool, +after_right: List<&2, Lexer.Token>, +right: Ast.SyntaxTerm, +file: String, left: Ast.SyntaxTerm, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match ok_right after_right:
    case True{} +colon <> after_colon:
      step_brace_equal_right_run(brace_equal_right_is_colon(colon), after_right, right, file, left, beg, scope, depth, colon, after_colon)
    case _ _:
      feedback_pack_5(((right, after_right), False{}))

def feedback_consumer_226933(v_288: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_4: String, v_2: Ast.SyntaxTerm, v_6: Nat, v_9: List<&2, Scope>, v_11: Nat) -> FeedbackControl:
  match v_288:
    case ((v_289, v_290), v_291):
      step_parse_brace_equal_right_result(v_291, v_290, v_289, v_4, v_2, v_6, v_9, v_11)

def feedback_resume_Kont_226950(lexical_capture_4: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: Nat, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_226933(result, lexical_capture_4, lexical_capture_2, lexical_capture_6, lexical_capture_9, lexical_capture_11)

def brace_annot_is_colon(close: Lexer.Token) -> Bool:
  match close:
    case Lexer.TokenInfo{ _, "}",  _,  _,  _,  _}:
      True{}
    case _:
      False{}

def brace_annot_branch_0(after_ty: List<&2, Lexer.Token>, ty: Ast.SyntaxTerm, file: String, left: Ast.SyntaxTerm, beg: Nat, +close: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermAnn{ left, ty,  span(file, beg, token_end(close))}, List.tail(&2, Lexer.Token, after_ty)), True{})

def brace_annot_branch_1(after_ty: List<&2, Lexer.Token>, file: String, +close: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected }",  span(file, token_beg(close), token_end(close))}, after_ty), False{})

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

def feedback_resume_Kont_227357(lexical_capture_4: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, ty => after_ty => ok_ty => parse_brace_annot_type_result(ok_ty, after_ty, ty, lexical_capture_4, lexical_capture_2, lexical_capture_6)))

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

def brace_equals_branch_3(+equals: Lexer.Token, after_left: List<&2, Lexer.Token>, +file: String) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected ==",  span(file, token_beg(equals), token_end(equals))}, after_left), False{})

def feedback_make_Kont_232475(lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: Nat, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat) -> FeedbackFrame:
  Kont_232475{lexical_capture_1, lexical_capture_2, lexical_capture_6, lexical_capture_9, lexical_capture_11}

def step_parse_inequality(+file: String, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_232475(file, left, beg, scope, depth))

def step_brace_equals_branch_0(after_equals: List<&2, Lexer.Token>, left: Ast.SyntaxTerm, +file: String, beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  step_parse_inequality(file, left, after_equals, beg, scope, depth)

def feedback_make_Kont_226950(lexical_capture_4: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: Nat, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat) -> FeedbackFrame:
  Kont_226950{lexical_capture_4, lexical_capture_2, lexical_capture_6, lexical_capture_9, lexical_capture_11}

def step_brace_equals_branch_1(after_equals: List<&2, Lexer.Token>, left: Ast.SyntaxTerm, +file: String, beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, after_equals, scope, depth, 0n), feedback_make_Kont_226950(file, left, beg, scope, depth))

def feedback_make_Kont_227357(lexical_capture_4: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: Nat) -> FeedbackFrame:
  Kont_227357{lexical_capture_4, lexical_capture_2, lexical_capture_6}

def step_brace_equals_branch_2(after_equals: List<&2, Lexer.Token>, left: Ast.SyntaxTerm, +file: String, beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, after_equals, scope, depth, 0n), feedback_make_Kont_227357(file, left, beg))

def step_brace_equals_run(action: BraceEqualsAction, +equals: Lexer.Token, +after_equals: List<&2, Lexer.Token>, after_left: List<&2, Lexer.Token>, +left: Ast.SyntaxTerm, +file: String, +beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match action:
    case BraceEqualsActionRow0{}:
      step_brace_equals_branch_0(after_equals, left, file, beg, scope, depth)
    case BraceEqualsActionRow1{}:
      step_brace_equals_branch_1(after_equals, left, file, beg, scope, depth)
    case BraceEqualsActionRow2{}:
      step_brace_equals_branch_2(after_equals, left, file, beg, scope, depth)
    case BraceEqualsActionRow3{}:
      feedback_pack_5(brace_equals_branch_3(equals, after_left, file))

def step_parse_brace_equals(+equals: Lexer.Token, after_equals: List<&2, Lexer.Token>, after_left: List<&2, Lexer.Token>, left: Ast.SyntaxTerm, +file: String, beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  step_brace_equals_run(brace_equals_action(equals), equals, after_equals, after_left, left, file, beg, scope, depth)

def step_parse_brace_left_result(ok_left: Bool, +after_left: List<&2, Lexer.Token>, +left: Ast.SyntaxTerm, file: String, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match ok_left after_left:
    case True{} +equals <> +after_equals:
      step_parse_brace_equals(equals, after_equals, after_left, left, file, beg, scope, depth)
    case _ _:
      feedback_pack_5(((left, after_left), False{}))

def feedback_consumer_230132(v_289: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_5: Nat, v_10: List<&2, Scope>, v_12: Nat) -> FeedbackControl:
  match v_289:
    case ((v_290, v_291), v_292):
      step_parse_brace_left_result(v_292, v_291, v_290, v_1, v_5, v_10, v_12)

def feedback_resume_Kont_230149(lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_10: List<&2, Scope>, lexical_capture_12: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_230132(result, lexical_capture_1, lexical_capture_5, lexical_capture_10, lexical_capture_12)

def inequality_is_colon(close: Lexer.Token) -> Bool:
  match close:
    case Lexer.TokenInfo{ _, "}", _, _, _, _}:
      True{}
    case _:
      False{}

def inequality_branch_0(ty: Ast.SyntaxTerm, after_ty: List<&2, Lexer.Token>, file: String, left: Ast.SyntaxTerm, right: Ast.SyntaxTerm, beg: Nat, depth: Nat, +close: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  +span_value = span(file, beg, token_end(close))
  ((Ast.TermAll{Ast.QOne{}, "_", depth, Ast.TermEqual{left, right, ty, span_value}, Ast.TermRef{"Empty", span_value}, span_value}, List.tail(&2, Lexer.Token, after_ty)), True{})

def inequality_branch_1(after_ty: List<&2, Lexer.Token>, file: String, +close: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{"parse-error: expected }", span(file, token_beg(close), token_end(close))}, after_ty), False{})

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

def feedback_resume_Kont_230673(lexical_capture_2: String, lexical_capture_3: Ast.SyntaxTerm, lexical_capture_0: Ast.SyntaxTerm, lexical_capture_5: Nat, lexical_capture_10: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, ty => after_ty => ok_ty => parse_inequality_type_result(ok_ty, ty, after_ty, lexical_capture_2, lexical_capture_3, lexical_capture_0, lexical_capture_5, lexical_capture_10)))

def inequality_right_is_colon(colon: Lexer.Token) -> Bool:
  match colon:
    case Lexer.TokenInfo{ _, ":", _, _, _, _}:
      True{}
    case _:
      False{}

def inequality_right_branch_1(after_right: List<&2, Lexer.Token>, +file: String, +colon: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{"parse-error: expected :", span(file, token_beg(colon), token_end(colon))}, after_right), False{})

def feedback_make_Kont_230673(lexical_capture_2: String, lexical_capture_3: Ast.SyntaxTerm, lexical_capture_0: Ast.SyntaxTerm, lexical_capture_5: Nat, lexical_capture_10: Nat) -> FeedbackFrame:
  Kont_230673{lexical_capture_2, lexical_capture_3, lexical_capture_0, lexical_capture_5, lexical_capture_10}

def step_inequality_right_branch_0(right: Ast.SyntaxTerm, +file: String, left: Ast.SyntaxTerm, beg: Nat, scope: List<&2, Scope>, +depth: Nat, after_colon: List<&2, Lexer.Token>) -> FeedbackControl:
  feedback_attach(step_parse_term(file, after_colon, scope, depth, 0n), feedback_make_Kont_230673(file, left, right, beg, depth))

def step_inequality_right_run(is_colon: Bool, right: Ast.SyntaxTerm, after_right: List<&2, Lexer.Token>, +file: String, left: Ast.SyntaxTerm, beg: Nat, scope: List<&2, Scope>, +depth: Nat, +colon: Lexer.Token, after_colon: List<&2, Lexer.Token>) -> FeedbackControl:
  match is_colon:
    case True{}:
      step_inequality_right_branch_0(right, file, left, beg, scope, depth, after_colon)
    case False{}:
      feedback_pack_5(inequality_right_branch_1(after_right, file, colon))

def step_parse_inequality_right_result(ok_right: Bool, +right: Ast.SyntaxTerm, +after_right: List<&2, Lexer.Token>, +file: String, left: Ast.SyntaxTerm, beg: Nat, scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match ok_right after_right:
    case True{} +colon <> after_colon:
      step_inequality_right_run(inequality_right_is_colon(colon), right, after_right, file, left, beg, scope, depth, colon, after_colon)
    case _ _:
      feedback_pack_5(((right, after_right), False{}))

def feedback_consumer_232458(v_290: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_2: Ast.SyntaxTerm, v_6: Nat, v_9: List<&2, Scope>, v_11: Nat) -> FeedbackControl:
  match v_290:
    case ((v_291, v_292), v_293):
      step_parse_inequality_right_result(v_293, v_291, v_292, v_1, v_2, v_6, v_9, v_11)

def feedback_resume_Kont_232475(lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: Nat, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_232458(result, lexical_capture_1, lexical_capture_2, lexical_capture_6, lexical_capture_9, lexical_capture_11)

def rewrite_motive_is_colon(colon: Lexer.Token) -> Bool:
  match colon:
    case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
      True{}
    case _:
      False{}

def rewrite_motive_branch_1(+file: String, tokens: List<&2, Lexer.Token>, +colon: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected :",  span(file, token_beg(colon), token_end(colon))}, tokens), False{})

def feedback_make_Kont_236486(lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_4: String, lexical_capture_6: Nat, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat) -> FeedbackFrame:
  Kont_236486{lexical_capture_1, lexical_capture_2, lexical_capture_4, lexical_capture_6, lexical_capture_9, lexical_capture_11}

def step_rewrite_motive_branch_0(+file: String, equation: Ast.SyntaxTerm, +key: String, beg: Nat, +scope: List<&2, Scope>, +depth: Nat, after_colon: List<&2, Lexer.Token>) -> FeedbackControl:
  # Rewrite exposes its implicit value binder; ordinary "_" binders do not.
  base_scope = { Scope{"_", depth} <> scope : List<&2, Scope> }
  motive_scope = extend_scope(key, (depth + 1n : Nat), base_scope)
  feedback_attach(step_parse_term(file, after_colon, motive_scope, (depth + 2n : Nat), 0n), feedback_make_Kont_236486(file, equation, key, beg, scope, depth))

def step_rewrite_motive_run(is_colon: Bool, +file: String, equation: Ast.SyntaxTerm, +key: String, tokens: List<&2, Lexer.Token>, beg: Nat, +scope: List<&2, Scope>, +depth: Nat, +colon: Lexer.Token, after_colon: List<&2, Lexer.Token>) -> FeedbackControl:
  match is_colon:
    case True{}:
      step_rewrite_motive_branch_0(file, equation, key, beg, scope, depth, after_colon)
    case False{}:
      feedback_pack_5(rewrite_motive_branch_1(file, tokens, colon))

def step_parse_rewrite_motive(+file: String, equation: Ast.SyntaxTerm, +key: String, +tokens: List<&2, Lexer.Token>, beg: Nat, +end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match tokens:
    case +colon <> after_colon:
      step_rewrite_motive_run(rewrite_motive_is_colon(colon), file, equation, key, tokens, beg, scope, depth, colon, after_colon)
    case Nil{}:
      feedback_pack_5(((Ast.TermHole{ "parse-error: expected :",  span(file, end, end)}, Nil{}), False{}))

# A lambda body is a block, as in the canonical parser's parse_block.
# Keep the existing local/match grammar and its outer-before-inner scope rules.

def step_parse_rewrite_equation_result(ok_equation: Bool, +equation: Ast.SyntaxTerm, +after_equation: List<&2, Lexer.Token>, file: String, key: String, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match ok_equation:
    case True{}:
      step_parse_rewrite_motive(file, equation, key, after_equation, beg, end, scope, depth)
    case False{}:
      feedback_pack_5(((equation, after_equation), False{}))

def feedback_consumer_233394(v_291: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_6: String, v_21: String, v_8: Nat, v_10: Nat, v_13: List<&2, Scope>, v_15: Nat) -> FeedbackControl:
  match v_291:
    case ((v_292, v_293), v_294):
      step_parse_rewrite_equation_result(v_294, v_292, v_293, v_6, v_21, v_8, v_10, v_13, v_15)

def feedback_resume_Kont_233411(lexical_capture_6: String, lexical_capture_21: String, lexical_capture_8: Nat, lexical_capture_10: Nat, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_233394(result, lexical_capture_6, lexical_capture_21, lexical_capture_8, lexical_capture_10, lexical_capture_13, lexical_capture_15)

def feedback_make_Kont_233411(lexical_capture_6: String, lexical_capture_21: String, lexical_capture_8: Nat, lexical_capture_10: Nat, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat) -> FeedbackFrame:
  Kont_233411{lexical_capture_6, lexical_capture_21, lexical_capture_8, lexical_capture_10, lexical_capture_13, lexical_capture_15}

def step_parse_rewrite_first_at_name(+first: Ast.SyntaxTerm, after_at: List<&2, Lexer.Token>, +after_first: List<&2, Lexer.Token>, +file: String, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match first:
    case Ast.TermVar{key, _, _}:
      feedback_attach(step_parse_term(file, after_at, scope, depth, 0n), feedback_make_Kont_233411(file, key, beg, end, scope, depth))
    case Ast.TermVar{+feedback_field_4_0, +feedback_field_4_1, +feedback_field_4_2}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermVar{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm)), token_end_first((Ast.TermVar{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermRef{+feedback_field_4_0, +feedback_field_4_1}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermRef{feedback_field_4_0, feedback_field_4_1} : Ast.SyntaxTerm)), token_end_first((Ast.TermRef{feedback_field_4_0, feedback_field_4_1} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermBang{+feedback_field_4_0, +feedback_field_4_1}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermBang{feedback_field_4_0, feedback_field_4_1} : Ast.SyntaxTerm)), token_end_first((Ast.TermBang{feedback_field_4_0, feedback_field_4_1} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermSub{+feedback_field_4_0, +feedback_field_4_1, +feedback_field_4_2, +feedback_field_4_3}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermSub{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3} : Ast.SyntaxTerm)), token_end_first((Ast.TermSub{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermLet{+feedback_field_4_0, +feedback_field_4_1, +feedback_field_4_2, +feedback_field_4_3, +feedback_field_4_4, +feedback_field_4_5}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermLet{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4, feedback_field_4_5} : Ast.SyntaxTerm)), token_end_first((Ast.TermLet{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4, feedback_field_4_5} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermAnn{+feedback_field_4_0, +feedback_field_4_1, +feedback_field_4_2}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermAnn{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm)), token_end_first((Ast.TermAnn{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermTemplate{+feedback_field_4_0, +feedback_field_4_1}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermTemplate{feedback_field_4_0, feedback_field_4_1} : Ast.SyntaxTerm)), token_end_first((Ast.TermTemplate{feedback_field_4_0, feedback_field_4_1} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermType{+feedback_field_4_0, +feedback_field_4_1}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermType{feedback_field_4_0, feedback_field_4_1} : Ast.SyntaxTerm)), token_end_first((Ast.TermType{feedback_field_4_0, feedback_field_4_1} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermQuant{}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermQuant{} : Ast.SyntaxTerm)), token_end_first((Ast.TermQuant{} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermQuantity{+feedback_field_4_0, +feedback_field_4_1}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermQuantity{feedback_field_4_0, feedback_field_4_1} : Ast.SyntaxTerm)), token_end_first((Ast.TermQuantity{feedback_field_4_0, feedback_field_4_1} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermMin{+feedback_field_4_0, +feedback_field_4_1, +feedback_field_4_2}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermMin{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm)), token_end_first((Ast.TermMin{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermAll{+feedback_field_4_0, +feedback_field_4_1, +feedback_field_4_2, +feedback_field_4_3, +feedback_field_4_4, +feedback_field_4_5}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermAll{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4, feedback_field_4_5} : Ast.SyntaxTerm)), token_end_first((Ast.TermAll{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4, feedback_field_4_5} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermLam{+feedback_field_4_0, +feedback_field_4_1, +feedback_field_4_2, +feedback_field_4_3, +feedback_field_4_4}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermLam{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4} : Ast.SyntaxTerm)), token_end_first((Ast.TermLam{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermApp{+feedback_field_4_0, +feedback_field_4_1, +feedback_field_4_2}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermApp{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm)), token_end_first((Ast.TermApp{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermAdt{+feedback_field_4_0, +feedback_field_4_1, +feedback_field_4_2, +feedback_field_4_3}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermAdt{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3} : Ast.SyntaxTerm)), token_end_first((Ast.TermAdt{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermFill{+feedback_field_4_0, +feedback_field_4_1, +feedback_field_4_2}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermFill{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm)), token_end_first((Ast.TermFill{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermPlus{+feedback_field_4_0, +feedback_field_4_1, +feedback_field_4_2}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermPlus{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm)), token_end_first((Ast.TermPlus{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermCtr{+feedback_field_4_0, +feedback_field_4_1, +feedback_field_4_2}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermCtr{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm)), token_end_first((Ast.TermCtr{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermString{+feedback_field_4_0, +feedback_field_4_1, +feedback_field_4_2}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermString{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm)), token_end_first((Ast.TermString{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermMat{+feedback_field_4_0, +feedback_field_4_1, +feedback_field_4_2, +feedback_field_4_3}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermMat{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3} : Ast.SyntaxTerm)), token_end_first((Ast.TermMat{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermAbsurd{+feedback_field_4_0}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermAbsurd{feedback_field_4_0} : Ast.SyntaxTerm)), token_end_first((Ast.TermAbsurd{feedback_field_4_0} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermEqual{+feedback_field_4_0, +feedback_field_4_1, +feedback_field_4_2, +feedback_field_4_3}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermEqual{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3} : Ast.SyntaxTerm)), token_end_first((Ast.TermEqual{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermRefl{+feedback_field_4_0}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermRefl{feedback_field_4_0} : Ast.SyntaxTerm)), token_end_first((Ast.TermRefl{feedback_field_4_0} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermRewrite{+feedback_field_4_0, +feedback_field_4_1, +feedback_field_4_2, +feedback_field_4_3}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermRewrite{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3} : Ast.SyntaxTerm)), token_end_first((Ast.TermRewrite{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.TermHole{+feedback_field_4_0, +feedback_field_4_1}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.TermHole{feedback_field_4_0, feedback_field_4_1} : Ast.SyntaxTerm)), token_end_first((Ast.TermHole{feedback_field_4_0, feedback_field_4_1} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.BodyMatch{+feedback_field_4_0, +feedback_field_4_1, +feedback_field_4_2}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.BodyMatch{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm)), token_end_first((Ast.BodyMatch{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.BodyCase{+feedback_field_4_0, +feedback_field_4_1, +feedback_field_4_2}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.BodyCase{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm)), token_end_first((Ast.BodyCase{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.BodyLocal{+feedback_field_4_0, +feedback_field_4_1, +feedback_field_4_2, +feedback_field_4_3, +feedback_field_4_4}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.BodyLocal{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4} : Ast.SyntaxTerm)), token_end_first((Ast.BodyLocal{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4} : Ast.SyntaxTerm)))}, after_first), False{}))
    case Ast.BodyReply{+feedback_field_4_0, +feedback_field_4_1}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected a name before @", span(file, token_beg_first((Ast.BodyReply{feedback_field_4_0, feedback_field_4_1} : Ast.SyntaxTerm)), token_end_first((Ast.BodyReply{feedback_field_4_0, feedback_field_4_1} : Ast.SyntaxTerm)))}, after_first), False{}))

def step_parse_rewrite_first_at(at: Lexer.Token, after_at: List<&2, Lexer.Token>, +first: Ast.SyntaxTerm, +after_first: List<&2, Lexer.Token>, +file: String, +beg: Nat, +end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match at:
    case Lexer.TokenInfo{_, "@", _, _, _, _}:
      step_parse_rewrite_first_at_name(first, after_at, after_first, file, beg, end, scope, depth)
    case _:
      step_parse_rewrite_motive(file, first, "", after_first, beg, end, scope, depth)

def step_parse_rewrite_first_result(ok_first: Bool, +first: Ast.SyntaxTerm, +after_first: List<&2, Lexer.Token>, file: String, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match ok_first after_first:
    case True{} _:
      match after_first:
        case +at <> +after_at:
          step_parse_rewrite_first_at(at, after_at, first, after_first, file, beg, end, scope, depth)
        case Nil{}:
          feedback_pack_5(((first, after_first), False{}))
    case False{} _:
      feedback_pack_5(((first, after_first), False{}))

def feedback_consumer_234997(v_292: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_5: Nat, v_7: Nat, v_10: List<&2, Scope>, v_12: Nat) -> FeedbackControl:
  match v_292:
    case ((v_293, v_294), v_295):
      step_parse_rewrite_first_result(v_295, v_293, v_294, v_1, v_5, v_7, v_10, v_12)

def feedback_resume_Kont_235014(lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_10: List<&2, Scope>, lexical_capture_12: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_234997(result, lexical_capture_1, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_12)

def parse_rewrite_body_result(ok_body: Bool, +body: Ast.SyntaxTerm, after_body: List<&2, Lexer.Token>, equation: Ast.SyntaxTerm, proof: Ast.SyntaxTerm, file: String, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      ((Ast.TermRewrite{equation, proof, body, span(file, beg, token_end_first(body))}, after_body), True{})
    case False{}:
      ((body, after_body), False{})

def feedback_resume_Kont_235810(lexical_capture_7: Ast.SyntaxTerm, lexical_capture_28: Ast.SyntaxTerm, lexical_capture_6: String, lexical_capture_11: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, body => after_body => ok_body => parse_rewrite_body_result(ok_body, body, after_body, lexical_capture_7, lexical_capture_28, lexical_capture_6, lexical_capture_11)))

def feedback_make_Kont_235810(lexical_capture_7: Ast.SyntaxTerm, lexical_capture_28: Ast.SyntaxTerm, lexical_capture_6: String, lexical_capture_11: Nat) -> FeedbackFrame:
  Kont_235810{lexical_capture_7, lexical_capture_28, lexical_capture_6, lexical_capture_11}

def step_parse_rewrite_motive_result(ok_motive: Bool, +motive: Ast.SyntaxTerm, +after_motive: List<&2, Lexer.Token>, +file: String, equation: Ast.SyntaxTerm, key: String, +beg: Nat, scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match ok_motive:
    case True{}:
      inner = { Ast.TermLam{None{}, key, (depth + 1n : Nat), motive, span(file, beg, token_end_first(motive))} : Ast.SyntaxTerm }
      proof = { Ast.TermLam{None{}, "_", depth, inner, span(file, beg, token_end_first(motive))} : Ast.SyntaxTerm }
      body_tokens = skip_rewrite_semicolon(after_motive)
      feedback_attach(step_parse_term(file, body_tokens, scope, depth, 0n), feedback_make_Kont_235810(equation, proof, file, beg))
    case False{}:
      feedback_pack_5(((motive, after_motive), False{}))

def feedback_consumer_236469(v_293: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_2: Ast.SyntaxTerm, v_4: String, v_6: Nat, v_9: List<&2, Scope>, v_11: Nat) -> FeedbackControl:
  match v_293:
    case ((v_294, v_295), v_296):
      step_parse_rewrite_motive_result(v_296, v_294, v_295, v_1, v_2, v_4, v_6, v_9, v_11)

def feedback_resume_Kont_236486(lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_4: String, lexical_capture_6: Nat, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_236469(result, lexical_capture_1, lexical_capture_2, lexical_capture_4, lexical_capture_6, lexical_capture_9, lexical_capture_11)

def parse_name_lambda_result(ok: Bool, body: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, file: String, key: String, beg: Nat, end: Nat, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok:
    case True{}:
      ((Ast.TermLam{None{}, key, depth, body, span(file, beg, token_end_of(after, end))}, after), True{})
    case False{}:
      ((body, after), False{})

def feedback_resume_Kont_239269(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_14: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, body => after => ok => parse_name_lambda_result(ok, body, after, lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_14)))

def feedback_make_Kont_85539(capture_0: List<&2, Ast.SyntaxTerm>, capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: String, capture_4: Nat) -> FeedbackFrame:
  Kont_85539{capture_0, capture_1, capture_2, capture_3, capture_4}

def consumed_token_end_all(tokens: List<&2, Lexer.Token>, fallback: Nat) -> Nat:
  match tokens:
    case next <> rest:
      consumed_token_end_all(rest, token_end(next))
    case Nil{}:
      fallback

def step_consumed_token_end(+tokens: List<&2, Lexer.Token>, remaining: List<&2, Lexer.Token>, +fallback: Nat) -> FeedbackControl:
  match remaining:
    case next <> _:
      FeedbackControl{FeedbackCall{feedback_make_consumed_token_end_before(tokens, token_beg(next), fallback)}, Nil{}, NoProgress{}, NoProgress{}}
    case Nil{}:
      feedback_pack_16(consumed_token_end_all(tokens, fallback))

def step_parse_name_constructor_result(v_1: Bool, v_3: List<&2, Ast.SyntaxTerm>, +v_5: List<&2, Lexer.Token>, +v_7: String, v_9: String, +v_11: Nat, +v_13: Nat, v_15: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_1:
    case True{}:
      feedback_attach(step_consumed_token_end(v_15, v_5, v_13), feedback_make_Kont_85539(v_3, v_5, v_7, v_9, v_11))
    case False{}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected constructor fields", span(v_7, v_11, v_13)}, v_5), False{}))

def feedback_consumer_239492(v_294: Pair(Pair(List<&2, Ast.SyntaxTerm>, List<&2, Lexer.Token>), Bool), v_1: String, v_3: String, v_5: Nat, v_7: Nat, v_20: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_294:
    case ((v_295, v_296), v_297):
      step_parse_name_constructor_result(v_297, v_295, v_296, v_1, v_3, v_5, v_7, v_20)

def feedback_resume_Kont_239509(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_20: List<&2, Lexer.Token>, result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_239492(result, lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_20)

def feedback_make_parse_term_args_first_result(ok: Bool, term: Ast.SyntaxTerm, after: List<&2, Lexer.Token>, file: String, tokens: List<&2, Lexer.Token>, close: String, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.SyntaxTerm>) -> FeedbackRequest:
  Request_parse_term_args_first_result{ok, term, after, file, tokens, close, scope, depth, acc}

def feedback_consumer_242886(v_295: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_3: String, v_8: List<&2, Lexer.Token>, v_10: String, v_13: List<&2, Scope>, v_15: Nat, v_17: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match v_295:
    case ((v_296, v_297), v_298):
      FeedbackControl{FeedbackCall{feedback_make_parse_term_args_first_result(v_298, v_296, v_297, v_3, v_8, v_10, v_13, v_15, v_17)}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_resume_Kont_242904(lexical_capture_3: String, lexical_capture_8: List<&2, Lexer.Token>, lexical_capture_10: String, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: List<&2, Ast.SyntaxTerm>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_242886(result, lexical_capture_3, lexical_capture_8, lexical_capture_10, lexical_capture_13, lexical_capture_15, lexical_capture_17)

def parse_all_named_body_result(ok_body: Bool, body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, file: String, key: String, key_end: Nat, beg: Nat, quantity: Ast.Quantity, ty: Ast.SyntaxTerm, idx: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      ((Ast.TermAll{quantity, key, idx, ty, body, span(file, beg, token_end_of(after_body, key_end))}, after_body), True{})
    case False{}:
      ((body, after_body), False{})

def feedback_resume_Kont_244597(lexical_capture_2: String, lexical_capture_4: String, lexical_capture_6: Nat, lexical_capture_8: Nat, lexical_capture_9: Ast.Quantity, lexical_capture_0: Ast.SyntaxTerm, lexical_capture_22: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, body => after_body => ok_body => parse_all_named_body_result(ok_body, body, after_body, lexical_capture_2, lexical_capture_4, lexical_capture_6, lexical_capture_8, lexical_capture_9, lexical_capture_0, lexical_capture_22)))

def all_named_type_is_colon(arrow: Lexer.Token) -> Bool:
  match arrow:
    case Lexer.TokenInfo{ _, "->", _, _, _, _}:
      True{}
    case _:
      False{}

def all_named_type_branch_1(after_ty: List<&2, Lexer.Token>, +file: String, +arrow: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected ->", span(file, token_beg(arrow), token_end(arrow))}, after_ty), False{})

def feedback_make_Kont_244597(lexical_capture_2: String, lexical_capture_4: String, lexical_capture_6: Nat, lexical_capture_8: Nat, lexical_capture_9: Ast.Quantity, lexical_capture_0: Ast.SyntaxTerm, lexical_capture_22: Nat) -> FeedbackFrame:
  Kont_244597{lexical_capture_2, lexical_capture_4, lexical_capture_6, lexical_capture_8, lexical_capture_9, lexical_capture_0, lexical_capture_22}

def step_all_named_type_branch_0(ty: Ast.SyntaxTerm, +file: String, +key: String, key_end: Nat, beg: Nat, quantity: Ast.Quantity, scope: List<&2, Scope>, +depth: Nat, after_arrow: List<&2, Lexer.Token>) -> FeedbackControl:
  idx = depth
  next_scope = extend_scope(key, depth, scope)
  feedback_attach(step_parse_term(file, after_arrow, next_scope, (depth + 1n : Nat), 0n), feedback_make_Kont_244597(file, key, key_end, beg, quantity, ty, idx))

def step_all_named_type_run(is_colon: Bool, ty: Ast.SyntaxTerm, after_ty: List<&2, Lexer.Token>, +file: String, +key: String, key_end: Nat, beg: Nat, quantity: Ast.Quantity, scope: List<&2, Scope>, +depth: Nat, +arrow: Lexer.Token, after_arrow: List<&2, Lexer.Token>) -> FeedbackControl:
  match is_colon:
    case True{}:
      step_all_named_type_branch_0(ty, file, key, key_end, beg, quantity, scope, depth, after_arrow)
    case False{}:
      feedback_pack_5(all_named_type_branch_1(after_ty, file, arrow))

def step_parse_all_named_type_result(ok_ty: Bool, +ty: Ast.SyntaxTerm, +after_ty: List<&2, Lexer.Token>, +file: String, +key: String, key_end: Nat, beg: Nat, quantity: Ast.Quantity, scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match ok_ty after_ty:
    case True{} +arrow <> after_arrow:
      step_all_named_type_run(all_named_type_is_colon(arrow), ty, after_ty, file, key, key_end, beg, quantity, scope, depth, arrow, after_arrow)
    case _ _:
      feedback_pack_5(((ty, after_ty), False{}))

def feedback_consumer_246768(v_296: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_23: String, v_25: Nat, v_10: Nat, v_11: Ast.Quantity, v_6: List<&2, Scope>, v_8: Nat) -> FeedbackControl:
  match v_296:
    case ((v_297, v_298), v_299):
      step_parse_all_named_type_result(v_299, v_297, v_298, v_1, v_23, v_25, v_10, v_11, v_6, v_8)

def feedback_resume_Kont_246785(lexical_capture_1: String, lexical_capture_23: String, lexical_capture_25: Nat, lexical_capture_10: Nat, lexical_capture_11: Ast.Quantity, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_246768(result, lexical_capture_1, lexical_capture_23, lexical_capture_25, lexical_capture_10, lexical_capture_11, lexical_capture_6, lexical_capture_8)

def parse_many_lambda_body_result(ok_body: Bool, body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, file: String, key: String, beg: Nat, end: Nat, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      ((Ast.TermLam{Some{Ast.QMany{}}, key, depth, body, span(file, beg, token_end_of(after_body, end))}, after_body), True{})
    case False{}:
      ((body, after_body), False{})

def feedback_resume_Kont_248037(lexical_capture_1: String, lexical_capture_22: String, lexical_capture_5: Nat, lexical_capture_24: Nat, lexical_capture_10: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, body => after_body => ok_body => parse_many_lambda_body_result(ok_body, body, after_body, lexical_capture_1, lexical_capture_22, lexical_capture_5, lexical_capture_24, lexical_capture_10)))

def feedback_make_Kont_251155(lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_6: Nat, lexical_capture_7: Lexer.Token) -> FeedbackFrame:
  Kont_251155{lexical_capture_3, lexical_capture_4, lexical_capture_6, lexical_capture_7}

def step_parse_plus_args_spaced(is_spaced: Bool, +file: String, +head: Ast.SyntaxTerm, +beg: Nat, open: Lexer.Token, rest: List<&2, Lexer.Token>, after_head: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match is_spaced:
    case True{}:
      feedback_pack_5(((Ast.TermPlus{head,  Nil{},  span(file, beg, token_end_first(head))}, after_head), True{}))
    case False{}:
      feedback_attach(step_parse_term_args(file, rest, ">", scope, depth, Nil{}), feedback_make_Kont_251155(file, head, beg, open))

def step_parse_plus_sugar_args(+file: String, +head: Ast.SyntaxTerm, +beg: Nat, +after_head: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match after_head:
    case +open <> +rest:
      match open:
        case Lexer.TokenInfo{ _, "<",  _,  _,  _,  _}:
          step_parse_plus_args_spaced(Nat.is_lt(token_end_first(head), token_beg(open)), file, head, beg, open, rest, after_head, scope, depth)
        case _:
          feedback_pack_5(((Ast.TermPlus{head,  Nil{},  span(file, beg, token_end_first(head))}, after_head), True{}))
    case Nil{}:
      feedback_pack_5(((Ast.TermPlus{head,  Nil{},  span(file, beg, token_end_first(head))}, after_head), True{}))

def step_parse_plus_sugar_named(found: Maybe<&2, String>, +file: String, +head: Ast.SyntaxTerm, beg: Nat, +after_head: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match found:
    case Some{ _}:
      step_parse_plus_sugar_args(file, head, beg, after_head, scope, depth)
    case None{}:
      feedback_pack_5(((Ast.TermHole{ "parse-error: expected a simple datatype name after +",  span(file, token_beg_first(head), token_end_first(head))}, after_head), False{}))

def term_name(term: Ast.SyntaxTerm) -> Maybe<&2, String>:
  match term:
    case Ast.TermVar{key,  _,  _}:
      Some{key}
    case Ast.TermRef{key,  _}:
      Some{key}
    case _:
      None{}

def step_parse_plus_sugar_head_result(ok_head: Bool, +head: Ast.SyntaxTerm, +after_head: List<&2, Lexer.Token>, file: String, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match ok_head:
    case True{}:
      step_parse_plus_sugar_named(term_name(head), file, head, beg, after_head, scope, depth)
    case False{}:
      feedback_pack_5(((head, after_head), False{}))

def feedback_consumer_249828(v_297: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_5: Nat, v_14: List<&2, Scope>, v_16: Nat) -> FeedbackControl:
  match v_297:
    case ((v_298, v_299), v_300):
      step_parse_plus_sugar_head_result(v_300, v_298, v_299, v_1, v_5, v_14, v_16)

def feedback_resume_Kont_249845(lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_249828(result, lexical_capture_1, lexical_capture_5, lexical_capture_14, lexical_capture_16)

def parse_plus_args_result(ok_args: Bool, args: List<&2, Ast.SyntaxTerm>, +after_args: List<&2, Lexer.Token>, file: String, +head: Ast.SyntaxTerm, beg: Nat, +open: Lexer.Token) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_args:
    case True{}:
      ((Ast.TermPlus{head, args, span(file, beg, token_end_of(after_args, token_end_first(head)))}, after_args), True{})
    case False{}:
      ((Ast.TermHole{"parse-error: expected plus datatype arguments", span(file, token_beg(open), token_end(open))}, after_args), False{})

def feedback_resume_Kont_251155(lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_6: Nat, lexical_capture_7: Lexer.Token, result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_args_result(result, args => after_args => ok_args => parse_plus_args_result(ok_args, args, after_args, lexical_capture_3, lexical_capture_4, lexical_capture_6, lexical_capture_7)))

def feedback_resume_Kont_251648(capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: List<&2, Lexer.Token>, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: Nat, result: Nat) -> FeedbackControl:
  FeedbackControl{FeedbackCall{feedback_make_parse_term_tail_at(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, result)}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_make_Kont_251648(capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: List<&2, Lexer.Token>, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: Nat) -> FeedbackFrame:
  Kont_251648{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5}

def step_parse_term_atom_result(ok: Bool, +left: Ast.SyntaxTerm, +rest: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, level: Nat, original: List<&2, Lexer.Token>) -> FeedbackControl:
  match ok:
    case True{}:
      feedback_attach(step_consumed_token_end(original, rest, token_end_first(left)), feedback_make_Kont_251648(file, left, rest, scope, depth, level))
    case False{}:
      feedback_pack_5(((left, rest), False{}))

def feedback_consumer_251922(v_298: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_6: List<&2, Scope>, v_8: Nat, v_10: Nat, v_3: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_298:
    case ((v_299, v_300), v_301):
      step_parse_term_atom_result(v_301, v_299, v_300, v_1, v_6, v_8, v_10, v_3)

def feedback_resume_Kont_251939(lexical_capture_1: String, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat, lexical_capture_10: Nat, lexical_capture_3: List<&2, Lexer.Token>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_251922(result, lexical_capture_1, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_3)

def step_parse_application_applied_result(ok_apply: Bool, +applied: Ast.SyntaxTerm, +after_args: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, level: Nat, consumed_end: Nat) -> FeedbackControl:
  match ok_apply:
    case True{}:
      FeedbackControl{FeedbackCall{feedback_make_parse_term_tail_at(file, applied, after_args, scope, depth, level, consumed_end)}, Nil{}, NoProgress{}, NoProgress{}}
    case False{}:
      feedback_pack_5(((applied, after_args), False{}))

def feedback_consumer_254183(v_299: Pair(Ast.SyntaxTerm, Bool), v_3: List<&2, Lexer.Token>, v_5: String, v_9: List<&2, Scope>, v_11: Nat, v_13: Nat, v_21: Nat) -> FeedbackControl:
  match v_299:
    case (v_300, v_301):
      step_parse_application_applied_result(v_301, v_300, v_3, v_5, v_9, v_11, v_13, v_21)

def step_evaluation_context_parse_application_args_result_245655(v_3: List<&2, Ast.SyntaxTerm>, +v_5: List<&2, Lexer.Token>, +v_7: String, +v_8: Ast.SyntaxTerm, v_12: List<&2, Scope>, v_14: Nat, v_16: Nat, v_304: Nat) -> FeedbackControl:
  v_24 = v_304
  feedback_consumer_254183(apply_terms(v_3, v_7, v_8, token_beg_first(v_8)), v_5, v_7, v_12, v_14, v_16, v_24)

def feedback_resume_Kont_254771(capture_0: List<&2, Ast.SyntaxTerm>, capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: Ast.SyntaxTerm, capture_4: List<&2, Scope>, capture_5: Nat, capture_6: Nat, result: Nat) -> FeedbackControl:
  step_evaluation_context_parse_application_args_result_245655(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, result)

def feedback_make_Kont_254771(capture_0: List<&2, Ast.SyntaxTerm>, capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: Ast.SyntaxTerm, capture_4: List<&2, Scope>, capture_5: Nat, capture_6: Nat) -> FeedbackFrame:
  Kont_254771{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6}

def step_parse_application_args_result(v_1: Bool, v_3: List<&2, Ast.SyntaxTerm>, +v_5: List<&2, Lexer.Token>, +v_7: String, +v_8: Ast.SyntaxTerm, v_9: Ast.SyntaxTerm, v_12: List<&2, Scope>, v_14: Nat, v_16: Nat, v_18: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_1:
    case True{}:
      feedback_attach(step_consumed_token_end(v_18, v_5, token_end_first(v_8)), feedback_make_Kont_254771(v_3, v_5, v_7, v_8, v_12, v_14, v_16))
    case False{}:
      feedback_pack_5(((v_9, v_5), False{}))

def feedback_consumer_255398(v_300: Pair(Pair(List<&2, Ast.SyntaxTerm>, List<&2, Lexer.Token>), Bool), +v_3: String, v_30: Ast.SyntaxTerm, +v_5: Lexer.Token, v_15: List<&2, Scope>, v_17: Nat, v_19: Nat, v_7: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_300:
    case ((v_301, v_302), v_303):
      step_parse_application_args_result(v_303, v_301, v_302, v_3, v_30, Ast.TermHole{"parse-error: expected bang-call arguments", span(v_3, token_beg(v_5), token_end(v_5))}, v_15, v_17, v_19, v_7)

def feedback_resume_Kont_255415(+lexical_capture_3: String, lexical_capture_30: Ast.SyntaxTerm, +lexical_capture_5: Lexer.Token, lexical_capture_15: List<&2, Scope>, lexical_capture_17: Nat, lexical_capture_19: Nat, lexical_capture_7: List<&2, Lexer.Token>, result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_255398(result, lexical_capture_3, lexical_capture_30, lexical_capture_5, lexical_capture_15, lexical_capture_17, lexical_capture_19, lexical_capture_7)

def feedback_make_parse_term_tail(file: String, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat) -> FeedbackRequest:
  Request_parse_term_tail{file, left, tokens, scope, depth, level}

def step_parse_term_arrow_result(ok: Bool, +right: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, +file: String, +left: Ast.SyntaxTerm, scope: List<&2, Scope>, +depth: Nat, level: Nat, end: Nat) -> FeedbackControl:
  match ok:
    case True{}:
      FeedbackControl{FeedbackCall{feedback_make_parse_term_tail(file, Ast.TermAll{Ast.QOne{}, "_", depth, left, right, span(file, token_beg_first(left), token_end_of(after, end))}, after, scope, (depth + 1n : Nat), level)}, Nil{}, NoProgress{}, NoProgress{}}
    case False{}:
      feedback_pack_5(((right, after), False{}))

def feedback_consumer_258130(v_302: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_2: Ast.SyntaxTerm, v_7: List<&2, Scope>, v_9: Nat, v_11: Nat, v_39: Nat) -> FeedbackControl:
  match v_302:
    case ((v_303, v_304), v_305):
      step_parse_term_arrow_result(v_305, v_303, v_304, v_1, v_2, v_7, v_9, v_11, v_39)

def feedback_resume_Kont_258147(lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: Nat, lexical_capture_39: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_258130(result, lexical_capture_1, lexical_capture_2, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_39)

def feedback_consumer_261594(v_301: Pair(Pair(List<&2, Ast.SyntaxTerm>, List<&2, Lexer.Token>), Bool), +v_1: String, v_2: Ast.SyntaxTerm, +v_18: Lexer.Token, v_7: List<&2, Scope>, v_9: Nat, v_11: Nat, v_19: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_301:
    case ((v_302, v_303), v_304):
      step_parse_application_args_result(v_304, v_302, v_303, v_1, v_2, Ast.TermHole{"parse-error: expected application arguments", span(v_1, token_end(v_18), token_end(v_18))}, v_7, v_9, v_11, v_19)

def feedback_resume_Kont_261611(+lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, +lexical_capture_18: Lexer.Token, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: Nat, lexical_capture_19: List<&2, Lexer.Token>, result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_261594(result, lexical_capture_1, lexical_capture_2, lexical_capture_18, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_19)

def feedback_make_Kont_265540(capture_0: List<&2, Ast.SyntaxTerm>, capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: Ast.SyntaxTerm, capture_4: List<&2, Scope>, capture_5: Nat, capture_6: Nat) -> FeedbackFrame:
  Kont_265540{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6}

def step_parse_less_many_result(v_1: Bool, v_3: List<&2, Ast.SyntaxTerm>, +v_5: List<&2, Lexer.Token>, +v_7: String, +v_8: Ast.SyntaxTerm, +v_9: Lexer.Token, v_11: Nat, v_14: List<&2, Scope>, v_16: Nat, v_18: Nat, v_20: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_1:
    case True{}:
      feedback_attach(step_consumed_token_end(v_20, v_5, v_11), feedback_make_Kont_265540(v_3, v_5, v_7, v_8, v_14, v_16, v_18))
    case False{}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected datatype arguments", span(v_7, token_beg(v_9), token_end(v_9))}, v_5), False{}))

def feedback_consumer_264062(v_303: Pair(Pair(List<&2, Ast.SyntaxTerm>, List<&2, Lexer.Token>), Bool), v_6: String, v_7: Ast.SyntaxTerm, v_9: Lexer.Token, v_20: Nat, v_14: List<&2, Scope>, v_16: Nat, v_18: Nat, v_11: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_303:
    case ((v_304, v_305), v_306):
      step_parse_less_many_result(v_306, v_304, v_305, v_6, v_7, v_9, v_20, v_14, v_16, v_18, v_11)

def feedback_resume_Kont_264079(lexical_capture_6: String, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_9: Lexer.Token, lexical_capture_20: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, lexical_capture_18: Nat, lexical_capture_11: List<&2, Lexer.Token>, result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_264062(result, lexical_capture_6, lexical_capture_7, lexical_capture_9, lexical_capture_20, lexical_capture_14, lexical_capture_16, lexical_capture_18, lexical_capture_11)

def step_evaluation_context_parse_less_many_result_256259(v_3: List<&2, Ast.SyntaxTerm>, +v_5: List<&2, Lexer.Token>, +v_7: String, +v_8: Ast.SyntaxTerm, v_14: List<&2, Scope>, v_16: Nat, v_18: Nat, v_305: Nat) -> FeedbackControl:
  v_27 = {Ast.TermFill{v_8, v_3, span(v_7, token_beg_first(v_8), v_305)} : Ast.SyntaxTerm}
  FeedbackControl{FeedbackCall{feedback_make_parse_term_tail(v_7, v_27, v_5, v_14, v_16, v_18)}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_resume_Kont_265540(capture_0: List<&2, Ast.SyntaxTerm>, capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: Ast.SyntaxTerm, capture_4: List<&2, Scope>, capture_5: Nat, capture_6: Nat, result: Nat) -> FeedbackControl:
  step_evaluation_context_parse_less_many_result_256259(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, result)

def feedback_make_Kont_264079(lexical_capture_6: String, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_9: Lexer.Token, lexical_capture_20: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, lexical_capture_18: Nat, lexical_capture_11: List<&2, Lexer.Token>) -> FeedbackFrame:
  Kont_264079{lexical_capture_6, lexical_capture_7, lexical_capture_9, lexical_capture_20, lexical_capture_14, lexical_capture_16, lexical_capture_18, lexical_capture_11}

def step_parse_less_named(found: Maybe<&2, String>, wants_many: Bool, +file: String, +left: Ast.SyntaxTerm, +right: Ast.SyntaxTerm, +separator: Lexer.Token, +after_separator: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +level: Nat, end: Nat) -> FeedbackControl:
  match found:
    case Some{ _}:
      match wants_many:
        case True{}:
          feedback_attach(step_parse_term_args(file, after_separator, ">", scope, depth, [right]), feedback_make_Kont_264079(file, left, separator, end, scope, depth, level, after_separator))
        case False{}:
          fill = { Ast.TermFill{ left,  [right],  span(file, token_beg_first(left), token_end(separator))} : Ast.SyntaxTerm }
          FeedbackControl{FeedbackCall{feedback_make_parse_term_tail(file, fill, after_separator, scope, depth, level)}, Nil{}, NoProgress{}, NoProgress{}}
    case None{}:
      feedback_pack_5(((Ast.TermHole{ "parse-error: expected a family name before type arguments",  span(file, token_beg_first(left), token_end(separator))}, after_separator), False{}))

def step_operator_call(+file: String, key: String, +left: Ast.SyntaxTerm, right: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> FeedbackControl:
  +operator_span = span(file, token_beg_first(left), token_end_of(after, end))
  operator = { Ast.TermRef{key,  operator_span} : Ast.SyntaxTerm }
  first = { Ast.TermApp{ operator,  left,  operator_span} : Ast.SyntaxTerm }
  combined = { Ast.TermApp{ first,  right,  operator_span} : Ast.SyntaxTerm }
  FeedbackControl{FeedbackCall{feedback_make_parse_term_tail(file, combined, after, scope, depth, level)}, Nil{}, NoProgress{}, NoProgress{}}

def step_parse_less_operator_or_nested(is_nested: Bool, file: String, +left: Ast.SyntaxTerm, right: Ast.SyntaxTerm, after_right: List<&2, Lexer.Token>, all_tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> FeedbackControl:
  match is_nested:
    case True{}:
      feedback_pack_5(((left, all_tokens), True{}))
    case False{}:
      step_operator_call(file, ".is_lt", left, right, after_right, scope, depth, level, end)

def step_parse_less_right_tokens(ok_right: Bool, +after_right: List<&2, Lexer.Token>, +right: Ast.SyntaxTerm, +file: String, +left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, all_tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +level: Nat, +end: Nat) -> FeedbackControl:
  match ok_right after_right:
    case True{} +separator <> +after_separator:
      match separator:
        case Lexer.TokenInfo{ _, ">",  _,  _,  _,  _}:
          step_parse_less_named(term_name(left), False{}, file, left, right, separator, after_separator, scope, depth, level, end)
        case Lexer.TokenInfo{ _, ",",  _,  _,  _,  _}:
          step_parse_less_named(term_name(left), True{}, file, left, right, separator, after_separator, scope, depth, level, end)
        case _:
          step_parse_less_operator_or_nested(Nat.is_lt(4n, level), file, left, right, after_right, all_tokens, scope, depth, level, end)
    case _ _:
      feedback_pack_5(((right, after_right), False{}))

def step_parse_less_right(ok_right: Bool, after_right: List<&2, Lexer.Token>, right: Ast.SyntaxTerm, file: String, +left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, all_tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, +level: Nat, end: Nat) -> FeedbackControl:
  step_parse_less_right_tokens(ok_right, split_angle_close(after_right), right, file, left, tokens, all_tokens, scope, depth, level, end)

def feedback_consumer_266434(v_304: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_2: Ast.SyntaxTerm, v_4: List<&2, Lexer.Token>, v_6: List<&2, Lexer.Token>, v_9: List<&2, Scope>, v_11: Nat, v_13: Nat, v_15: Nat) -> FeedbackControl:
  match v_304:
    case ((v_305, v_306), v_307):
      step_parse_less_right(v_307, v_306, v_305, v_1, v_2, v_4, v_6, v_9, v_11, v_13, v_15)

def feedback_resume_Kont_266451(lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_4: List<&2, Lexer.Token>, lexical_capture_6: List<&2, Lexer.Token>, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_266434(result, lexical_capture_1, lexical_capture_2, lexical_capture_4, lexical_capture_6, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15)

def step_parse_operator_right_named(key: String, +right: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, +file: String, +left: Ast.SyntaxTerm, +scope: List<&2, Scope>, +depth: Nat, +level: Nat, +end: Nat) -> FeedbackControl:
  match key:
    case "Con":
      constructor = { Ast.TermCtr{ "Con", [left, right], span(file, token_beg_first(left), token_end_of(after, end))} : Ast.SyntaxTerm }
      FeedbackControl{FeedbackCall{feedback_make_parse_term_tail(file, constructor, after, scope, depth, level)}, Nil{}, NoProgress{}, NoProgress{}}
    case SNil{}:
      step_operator_call(file, (SNil{} : String), left, right, after, scope, depth, level, end)
    case SCon{feedback_field_5_0, feedback_field_5_1}:
      step_operator_call(file, (SCon{feedback_field_5_0, feedback_field_5_1} : String), left, right, after, scope, depth, level, end)

def step_parse_operator_right_result(ok: Bool, +right: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, file: String, key: String, left: Ast.SyntaxTerm, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> FeedbackControl:
  match ok:
    case True{}:
      step_parse_operator_right_named(key, right, after, file, left, scope, depth, level, end)
    case False{}:
      feedback_pack_5(((right, after), False{}))

def feedback_consumer_270473(v_305: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_3: String, v_5: String, v_8: Ast.SyntaxTerm, v_13: List<&2, Scope>, v_15: Nat, v_17: Nat, v_19: Nat) -> FeedbackControl:
  match v_305:
    case ((v_306, v_307), v_308):
      step_parse_operator_right_result(v_308, v_306, v_307, v_3, v_5, v_8, v_13, v_15, v_17, v_19)

def feedback_resume_Kont_270490(lexical_capture_3: String, lexical_capture_5: String, lexical_capture_8: Ast.SyntaxTerm, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_19: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_270473(result, lexical_capture_3, lexical_capture_5, lexical_capture_8, lexical_capture_13, lexical_capture_15, lexical_capture_17, lexical_capture_19)

def step_parse_min_precedence_result(ok: Bool, +right: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, +file: String, +left: Ast.SyntaxTerm, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> FeedbackControl:
  match ok:
    case True{}:
      term = { Ast.TermMin{left, right, span(file, token_beg_first(left), token_end_of(after, end))} : Ast.SyntaxTerm }
      FeedbackControl{FeedbackCall{feedback_make_parse_term_tail(file, term, after, scope, depth, level)}, Nil{}, NoProgress{}, NoProgress{}}
    case False{}:
      feedback_pack_5(((right, after), False{}))

def feedback_consumer_271768(v_306: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_3: String, v_4: Ast.SyntaxTerm, v_9: List<&2, Scope>, v_11: Nat, v_13: Nat, v_15: Nat) -> FeedbackControl:
  match v_306:
    case ((v_307, v_308), v_309):
      step_parse_min_precedence_result(v_309, v_307, v_308, v_3, v_4, v_9, v_11, v_13, v_15)

def feedback_resume_Kont_271785(lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_271768(result, lexical_capture_3, lexical_capture_4, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15)

def is_quantity_term(term: Ast.SyntaxTerm) -> Bool:
  match term:
    case Ast.TermQuantity{ _,  _}:
      True{}
    case Ast.TermMin{ _,  _,  _}:
      True{}
    case _:
      False{}

def step_pair_application_result(ok: Bool, +term: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> FeedbackControl:
  match ok:
    case True{}:
      FeedbackControl{FeedbackCall{feedback_make_parse_term_tail_at(file, term, after, scope, depth, level, end)}, Nil{}, NoProgress{}, NoProgress{}}
    case False{}:
      feedback_pack_5(((term, after), False{}))

def feedback_consumer_275073(v_308: Pair(Ast.SyntaxTerm, Bool), v_7: List<&2, Lexer.Token>, v_1: String, v_10: List<&2, Scope>, v_12: Nat, v_14: Nat, v_16: Nat) -> FeedbackControl:
  match v_308:
    case (v_309, v_310):
      step_pair_application_result(v_310, v_309, v_7, v_1, v_10, v_12, v_14, v_16)

def step_pair_application(+file: String, key: String, +left: Ast.SyntaxTerm, right: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat, +end: Nat) -> FeedbackControl:
  span_value = span(file, token_beg_first(left), token_end_of(after, end))
  feedback_consumer_275073(apply_terms([left, right], file, Ast.TermRef{key, span_value}, token_beg_first(left)), after, file, scope, depth, level, end)

def step_parse_pair_quantity(left_is_quantity: Bool, right_is_quantity: Bool, +file: String, +left: Ast.SyntaxTerm, +right: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +level: Nat, +end: Nat) -> FeedbackControl:
  match left_is_quantity right_is_quantity:
    case True{} True{}:
      FeedbackControl{FeedbackCall{feedback_make_parse_term_tail_at(file, Ast.TermMin{left, right, span(file, token_beg_first(left), token_end_of(after, end))}, after, scope, depth, level, end)}, Nil{}, NoProgress{}, NoProgress{}}
    case _ _:
      step_pair_application(file, "Pair", left, right, after, scope, depth, level, end)

def step_parse_pair_operator_consumed(ok: Bool, +right: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, amp: Bool, +file: String, +left: Ast.SyntaxTerm, +scope: List<&2, Scope>, +depth: Nat, +level: Nat, +end: Nat) -> FeedbackControl:
  match ok:
    case True{}:
      match amp:
        case True{}:
          step_parse_pair_quantity(is_quantity_term(left), is_quantity_term(right), file, left, right, after, scope, depth, level, end)
        case False{}:
          step_pair_application(file, "Or", left, right, after, scope, depth, level, end)
    case False{}:
      feedback_pack_5(((right, after), False{}))

def feedback_resume_Kont_272903(capture_0: Bool, capture_1: Ast.SyntaxTerm, capture_2: List<&2, Lexer.Token>, capture_3: Bool, capture_4: String, capture_5: Ast.SyntaxTerm, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: Nat, result: Nat) -> FeedbackControl:
  step_parse_pair_operator_consumed(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, result)

def feedback_make_Kont_272903(capture_0: Bool, capture_1: Ast.SyntaxTerm, capture_2: List<&2, Lexer.Token>, capture_3: Bool, capture_4: String, capture_5: Ast.SyntaxTerm, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: Nat) -> FeedbackFrame:
  Kont_272903{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8}

def step_parse_pair_operator_result(ok: Bool, +right: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, amp: Bool, file: String, +left: Ast.SyntaxTerm, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat, tokens: List<&2, Lexer.Token>) -> FeedbackControl:
  feedback_attach(step_consumed_token_end(tokens, after, end), feedback_make_Kont_272903(ok, right, after, amp, file, left, scope, depth, level))

def feedback_consumer_274165(v_307: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_17: Bool, v_3: String, v_4: Ast.SyntaxTerm, v_9: List<&2, Scope>, v_11: Nat, v_13: Nat, v_15: Nat, v_6: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_307:
    case ((v_308, v_309), v_310):
      step_parse_pair_operator_result(v_310, v_308, v_309, v_17, v_3, v_4, v_9, v_11, v_13, v_15, v_6)

def feedback_resume_Kont_274182(lexical_capture_17: Bool, lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat, lexical_capture_6: List<&2, Lexer.Token>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_274165(result, lexical_capture_17, lexical_capture_3, lexical_capture_4, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15, lexical_capture_6)

def step_parse_array_set_call_result(call_ok: Bool, +call: Ast.SyntaxTerm, +after_value: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, level: Nat) -> FeedbackControl:
  match call_ok:
    case True{}:
      FeedbackControl{FeedbackCall{feedback_make_parse_term_tail(file, call, after_value, scope, depth, level)}, Nil{}, NoProgress{}, NoProgress{}}
    case False{}:
      feedback_pack_5(((call, after_value), False{}))

def feedback_consumer_275983(v_309: Pair(Ast.SyntaxTerm, Bool), v_4: List<&2, Lexer.Token>, v_6: String, v_15: List<&2, Scope>, v_17: Nat, v_19: Nat) -> FeedbackControl:
  match v_309:
    case (v_310, v_311):
      step_parse_array_set_call_result(v_311, v_310, v_4, v_6, v_15, v_17, v_19)

def step_parse_array_set_value_result(ok_value: Bool, +value: Ast.SyntaxTerm, +after_value: List<&2, Lexer.Token>, +file: String, left: Ast.SyntaxTerm, typed_index: Ast.SyntaxTerm, +beg: Nat, open_end: Nat, scope: List<&2, Scope>, depth: Nat, level: Nat) -> FeedbackControl:
  match ok_value:
    case True{}:
      feedback_consumer_275983(apply_terms([Ast.TermRef{"U32", span(file, beg, open_end)}, left, typed_index, value], file, Ast.TermRef{"Array.set", span(file, beg, token_end_first(value))}, beg), after_value, file, scope, depth, level)
    case False{}:
      feedback_pack_5(((value, after_value), False{}))

def feedback_consumer_276709(v_310: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_6: String, v_7: Ast.SyntaxTerm, v_8: Ast.SyntaxTerm, v_10: Nat, v_12: Nat, v_15: List<&2, Scope>, v_17: Nat, v_19: Nat) -> FeedbackControl:
  match v_310:
    case ((v_311, v_312), v_313):
      step_parse_array_set_value_result(v_313, v_311, v_312, v_6, v_7, v_8, v_10, v_12, v_15, v_17, v_19)

def feedback_resume_Kont_276726(lexical_capture_6: String, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_8: Ast.SyntaxTerm, lexical_capture_10: Nat, lexical_capture_12: Nat, lexical_capture_15: List<&2, Scope>, lexical_capture_17: Nat, lexical_capture_19: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_276709(result, lexical_capture_6, lexical_capture_7, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_15, lexical_capture_17, lexical_capture_19)

def step_parse_array_get_result(ok: Bool, +call: Ast.SyntaxTerm, +tokens: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, level: Nat) -> FeedbackControl:
  match ok:
    case True{}:
      FeedbackControl{FeedbackCall{feedback_make_parse_term_tail(file, call, tokens, scope, depth, level)}, Nil{}, NoProgress{}, NoProgress{}}
    case False{}:
      feedback_pack_5(((call, tokens), False{}))

def feedback_consumer_280429(v_312: Pair(Ast.SyntaxTerm, Bool), v_5: List<&2, Lexer.Token>, v_1: String, v_8: List<&2, Scope>, v_10: Nat, v_12: Nat) -> FeedbackControl:
  match v_312:
    case (v_313, v_314):
      step_parse_array_get_result(v_314, v_313, v_5, v_1, v_8, v_10, v_12)

def step_parse_array_get(+file: String, left: Ast.SyntaxTerm, index: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat, +beg: Nat, +end: Nat) -> FeedbackControl:
  feedback_consumer_280429(apply_terms([Ast.TermRef{"U32", span(file, beg, end)}, left, index], file, Ast.TermRef{"Array.get", span(file, beg, end)}, beg), tokens, file, scope, depth, level)

def feedback_make_Kont_276726(lexical_capture_6: String, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_8: Ast.SyntaxTerm, lexical_capture_10: Nat, lexical_capture_12: Nat, lexical_capture_15: List<&2, Scope>, lexical_capture_17: Nat, lexical_capture_19: Nat) -> FeedbackFrame:
  Kont_276726{lexical_capture_6, lexical_capture_7, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_15, lexical_capture_17, lexical_capture_19}

def step_parse_index_set_token(set_token: Lexer.Token, after_set: List<&2, Lexer.Token>, after_close: List<&2, Lexer.Token>, +file: String, +left: Ast.SyntaxTerm, +typed_index: Ast.SyntaxTerm, +beg: Nat, +open_end: Nat, +scope: List<&2, Scope>, +depth: Nat, +level: Nat) -> FeedbackControl:
  match set_token:
    case Lexer.TokenInfo{_, "<-", _, _, _, _}:
      feedback_attach(step_parse_term(file, after_set, scope, depth, 0n), feedback_make_Kont_276726(file, left, typed_index, beg, open_end, scope, depth, level))
    case _:
      step_parse_array_get(file, left, typed_index, after_close, scope, depth, level, beg, open_end)

def step_parse_index_after_close(+after_close: List<&2, Lexer.Token>, +file: String, +left: Ast.SyntaxTerm, +typed_index: Ast.SyntaxTerm, +beg: Nat, +open_end: Nat, +scope: List<&2, Scope>, +depth: Nat, +level: Nat) -> FeedbackControl:
  match after_close:
    case +set_token <> +after_set:
      step_parse_index_set_token(set_token, after_set, after_close, file, left, typed_index, beg, open_end, scope, depth, level)
    case Nil{}:
      step_parse_array_get(file, left, typed_index, Nil{}, scope, depth, level, beg, open_end)

def feedback_resume_Kont_277885(capture_0: List<&2, Lexer.Token>, capture_1: String, capture_2: Ast.SyntaxTerm, capture_4: Nat, capture_5: Nat, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: Nat, result: Ast.SyntaxTerm) -> FeedbackControl:
  step_parse_index_after_close(capture_0, capture_1, capture_2, result, capture_4, capture_5, capture_6, capture_7, capture_8)

def index_result_is_colon(close: Lexer.Token) -> Bool:
  match close:
    case Lexer.TokenInfo{_, "]", _, _, _, _}:
      True{}
    case _:
      False{}

def index_result_branch_1(after_index: List<&2, Lexer.Token>, file: String, +close: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{"parse-error: expected ]", span(file, token_beg(close), token_end(close))}, after_index), False{})

def feedback_make_Kont_277885(capture_0: List<&2, Lexer.Token>, capture_1: String, capture_2: Ast.SyntaxTerm, capture_4: Nat, capture_5: Nat, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: Nat) -> FeedbackFrame:
  Kont_277885{capture_0, capture_1, capture_2, capture_4, capture_5, capture_6, capture_7, capture_8}

def step_index_result_branch_0(index: Ast.SyntaxTerm, file: String, left: Ast.SyntaxTerm, scope: List<&2, Scope>, depth: Nat, level: Nat, beg: Nat, open_end: Nat, after_close: List<&2, Lexer.Token>) -> FeedbackControl:
  feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(index, "U32")}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_277885(after_close, file, left, beg, open_end, scope, depth, level))

def step_index_result_run(is_colon: Bool, after_index: List<&2, Lexer.Token>, index: Ast.SyntaxTerm, +file: String, left: Ast.SyntaxTerm, scope: List<&2, Scope>, depth: Nat, level: Nat, beg: Nat, open_end: Nat, +close: Lexer.Token, after_close: List<&2, Lexer.Token>) -> FeedbackControl:
  match is_colon:
    case True{}:
      step_index_result_branch_0(index, file, left, scope, depth, level, beg, open_end, after_close)
    case False{}:
      feedback_pack_5(index_result_branch_1(after_index, file, close))

def step_parse_index_result(ok_index: Bool, +after_index: List<&2, Lexer.Token>, +index: Ast.SyntaxTerm, file: String, left: Ast.SyntaxTerm, scope: List<&2, Scope>, depth: Nat, level: Nat, beg: Nat, open_end: Nat) -> FeedbackControl:
  match ok_index after_index:
    case True{} +close <> after_close:
      step_index_result_run(index_result_is_colon(close), after_index, index, file, left, scope, depth, level, beg, open_end, close, after_close)
    case _ _:
      feedback_pack_5(((index, after_index), False{}))

def feedback_consumer_279651(v_311: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_2: Ast.SyntaxTerm, v_7: List<&2, Scope>, v_9: Nat, v_11: Nat, v_13: Nat, v_15: Nat) -> FeedbackControl:
  match v_311:
    case ((v_312, v_313), v_314):
      step_parse_index_result(v_314, v_313, v_312, v_1, v_2, v_7, v_9, v_11, v_13, v_15)

def feedback_resume_Kont_279668(lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_279651(result, lexical_capture_1, lexical_capture_2, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15)

def step_parse_operator_precedence_result(ok: Bool, +right: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, +file: String, name: String, +left: Ast.SyntaxTerm, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> FeedbackControl:
  match ok:
    case True{}:
      +operator_span = span(file, token_beg_first(left), token_end_of(after, end))
      operator = { Ast.TermRef{name, operator_span} : Ast.SyntaxTerm }
      first = { Ast.TermApp{operator, left, operator_span} : Ast.SyntaxTerm }
      combined = { Ast.TermApp{first, right, operator_span} : Ast.SyntaxTerm }
      FeedbackControl{FeedbackCall{feedback_make_parse_term_tail(file, combined, after, scope, depth, level)}, Nil{}, NoProgress{}, NoProgress{}}
    case False{}:
      feedback_pack_5(((right, after), False{}))

def feedback_consumer_282156(v_313: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_3: String, v_5: String, v_8: Ast.SyntaxTerm, v_13: List<&2, Scope>, v_15: Nat, v_17: Nat, v_19: Nat) -> FeedbackControl:
  match v_313:
    case ((v_314, v_315), v_316):
      step_parse_operator_precedence_result(v_316, v_314, v_315, v_3, v_5, v_8, v_13, v_15, v_17, v_19)

def feedback_resume_Kont_282173(lexical_capture_3: String, lexical_capture_5: String, lexical_capture_8: Ast.SyntaxTerm, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_19: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_282156(result, lexical_capture_3, lexical_capture_5, lexical_capture_8, lexical_capture_13, lexical_capture_15, lexical_capture_17, lexical_capture_19)

def feedback_make_Kont_293503(lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: String, lexical_capture_8: String, lexical_capture_10: Nat, lexical_capture_12: Nat, lexical_capture_14: Nat, lexical_capture_17: List<&2, Scope>, lexical_capture_19: Nat, lexical_capture_20: Ast.Quantity) -> FeedbackFrame:
  Kont_293503{lexical_capture_2, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_17, lexical_capture_19, lexical_capture_20}

def step_parse_typed_local_ty(ok_ty: Bool, +ty: Ast.SyntaxTerm, +after_ty: List<&2, Lexer.Token>, +file: String, +key: String, +beg: Nat, +key_end: Nat, +col: Nat, +scope: List<&2, Scope>, +depth: Nat, quantity: Ast.Quantity) -> FeedbackControl:
  match ok_ty:
    case True{}:
      match after_ty:
        case Lexer.TokenInfo{ _, "=",  _,  _,  _,  _} <> after_equals:
          feedback_attach(step_parse_term(file, after_equals, scope, depth, 0n), feedback_make_Kont_293503(ty, file, key, beg, key_end, col, scope, depth, quantity))
        case Nil{}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected = after local type",  span(file, key_end, key_end)}, (Nil{} : List<&2, Lexer.Token>)), False{}))
        case Con{feedback_field_6_0, feedback_field_6_1}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected = after local type",  span(file, key_end, key_end)}, (Con{feedback_field_6_0, feedback_field_6_1} : List<&2, Lexer.Token>)), False{}))
    case False{}:
      feedback_pack_5(((ty, after_ty), False{}))

def feedback_consumer_292768(v_314: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_3: String, v_5: Nat, v_7: Nat, v_9: Nat, v_14: List<&2, Scope>, v_16: Nat, v_17: Ast.Quantity) -> FeedbackControl:
  match v_314:
    case ((v_315, v_316), v_317):
      step_parse_typed_local_ty(v_317, v_315, v_316, v_1, v_3, v_5, v_7, v_9, v_14, v_16, v_17)

def feedback_resume_Kont_292785(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, lexical_capture_17: Ast.Quantity, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_292768(result, lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_14, lexical_capture_16, lexical_capture_17)

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

def local_body_ready(tokens: List<&2, Lexer.Token>, parent_col: Nat) -> Bool:
  match tokens:
    case +token <> _:
      match token:
        case Lexer.TokenInfo{ _, ";",  _,  _,  _,  _}:
          True{}
        case _:
          body_indented(tokens, parent_col)
    case Nil{}:
      False{}

def feedback_make_Kont_303223(lexical_capture_3: String, lexical_capture_5: String, lexical_capture_7: Nat, lexical_capture_10: Ast.SyntaxPattern, lexical_capture_19: Ast.Quantity, lexical_capture_11: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_303223{lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_19, lexical_capture_11}

def step_parse_local_body_ready(is_ready: Bool, +file: String, key: String, beg: Nat, col: Nat, pattern: Ast.SyntaxPattern, +value: Ast.SyntaxTerm, +after_value: List<&2, Lexer.Token>, next_scope: List<&2, Scope>, depth: Nat, quantity: Ast.Quantity) -> FeedbackControl:
  match is_ready:
    case True{}:
      feedback_attach(step_parse_body(file, skip_rewrite_semicolon(after_value), next_scope, (depth + 1n : Nat), col), feedback_make_Kont_303223(file, key, beg, pattern, quantity, value))
    case False{}:
      feedback_pack_5(((Ast.TermHole{ "parse-error: expected an indented local body",  span(file, token_end_first(value), token_end_first(value))}, after_value), False{}))

def step_parse_typed_local_value(ok_value: Bool, ty: Ast.SyntaxTerm, +value: Ast.SyntaxTerm, +after_value: List<&2, Lexer.Token>, +file: String, +key: String, +beg: Nat, +key_end: Nat, +col: Nat, scope: List<&2, Scope>, +depth: Nat, +quantity: Ast.Quantity) -> FeedbackControl:
  match ok_value:
    case True{}:
      annotated = { Ast.TermAnn{value, ty, span(file, beg, token_end_first(value))} : Ast.SyntaxTerm }
      pattern = { Ast.PatternVar{key, depth, quantity, span(file, beg, key_end)} : Ast.SyntaxPattern }
      next_scope = extend_scope(key, depth, scope)
      step_parse_local_body_ready(local_body_ready(after_value, col), file, key, beg, col, pattern, annotated, after_value, next_scope, depth, quantity)
    case False{}:
      feedback_pack_5(((value, after_value), False{}))

def feedback_consumer_293486(v_315: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_2: Ast.SyntaxTerm, v_6: String, v_8: String, v_10: Nat, v_12: Nat, v_14: Nat, v_17: List<&2, Scope>, v_19: Nat, v_20: Ast.Quantity) -> FeedbackControl:
  match v_315:
    case ((v_316, v_317), v_318):
      step_parse_typed_local_value(v_318, v_2, v_316, v_317, v_6, v_8, v_10, v_12, v_14, v_17, v_19, v_20)

def feedback_resume_Kont_293503(lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: String, lexical_capture_8: String, lexical_capture_10: Nat, lexical_capture_12: Nat, lexical_capture_14: Nat, lexical_capture_17: List<&2, Scope>, lexical_capture_19: Nat, lexical_capture_20: Ast.Quantity, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_293486(result, lexical_capture_2, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_17, lexical_capture_19, lexical_capture_20)

def parse_reply_result(ok: Bool, +term: Ast.SyntaxTerm, after: List<&2, Lexer.Token>, file: String) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok:
    case True{}:
      ((Ast.BodyReply{term, span(file, token_beg_first(term), token_end_first(term))}, after), True{})
    case False{}:
      ((term, after), False{})

def feedback_resume_Kont_296071(lexical_capture_1: String, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, term => after => ok => parse_reply_result(ok, term, after, lexical_capture_1)))

def step_parse_local_values_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, tokens: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, remaining: List<&2, Ast.SyntaxPattern>, +line: Nat, +acc: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match result:
    case ((value, after), True{}):
      FeedbackControl{FeedbackCall{feedback_make_parse_local_values_next(remaining, file, after, scope, depth, line, value <> acc)}, Nil{}, NoProgress{}, NoProgress{}}
    case (_, False{}):
      feedback_pack_2((((List.reverse(&2, Ast.SyntaxTerm, acc), tokens), line), False{}))

def feedback_resume_Kont_297632(capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: List<&2, Ast.SyntaxPattern>, capture_6: Nat, capture_7: List<&2, Ast.SyntaxTerm>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_local_values_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7)

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

def feedback_make_Kont_300984(lexical_capture_3: List<&2, Ast.SyntaxTerm>, lexical_capture_7: List<&2, Ast.SyntaxPattern>, lexical_capture_13: Ast.Quantity, lexical_capture_15: String, lexical_capture_17: Nat) -> FeedbackFrame:
  Kont_300984{lexical_capture_3, lexical_capture_7, lexical_capture_13, lexical_capture_15, lexical_capture_17}

def step_parse_parallel_body_ready(is_ready: Bool, values: List<&2, Ast.SyntaxTerm>, +after_values: List<&2, Lexer.Token>, patterns: List<&2, Ast.SyntaxPattern>, next_scope: List<&2, Scope>, next_depth: Nat, quantity: Ast.Quantity, +file: String, +beg: Nat, col: Nat) -> FeedbackControl:
  match is_ready:
    case True{}:
      feedback_attach(step_parse_body(file, skip_rewrite_semicolon(after_values), next_scope, next_depth, col), feedback_make_Kont_300984(values, patterns, quantity, file, beg))
    case False{}:
      feedback_pack_5(((Ast.TermHole{ "parse-error: expected an indented parallel-let body",  span(file, token_end_of(after_values, beg), token_end_of(after_values, beg))}, after_values), False{}))

def step_parse_parallel_values_result(ok_values: Bool, values: List<&2, Ast.SyntaxTerm>, +after_values: List<&2, Lexer.Token>, rhs_line: Nat, patterns: List<&2, Ast.SyntaxPattern>, next_scope: List<&2, Scope>, next_depth: Nat, +file: String, +beg: Nat, +col: Nat, quantity: Ast.Quantity) -> FeedbackControl:
  match ok_values:
    case True{}:
      step_parse_parallel_body_ready(local_group_body_ready(after_values, col, rhs_line), values, after_values, patterns, next_scope, next_depth, quantity, file, beg, col)
    case False{}:
      feedback_pack_5(((Ast.TermHole{ "parse-error: expected parallel-let values",  span(file, beg, beg)}, after_values), False{}))

def feedback_consumer_299499(v_317: Pair(Pair(Pair(List<&2, Ast.SyntaxTerm>, List<&2, Lexer.Token>), Nat), Bool), v_3: List<&2, Ast.SyntaxPattern>, v_8: List<&2, Scope>, v_10: Nat, v_12: String, v_14: Nat, v_16: Nat, v_22: Ast.Quantity) -> FeedbackControl:
  match v_317:
    case (((v_318, v_319), v_320), v_321):
      step_parse_parallel_values_result(v_321, v_318, v_319, v_320, v_3, v_8, v_10, v_12, v_14, v_16, v_22)

def feedback_resume_Kont_299524(lexical_capture_3: List<&2, Ast.SyntaxPattern>, lexical_capture_8: List<&2, Scope>, lexical_capture_10: Nat, lexical_capture_12: String, lexical_capture_14: Nat, lexical_capture_16: Nat, lexical_capture_22: Ast.Quantity, result: (((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Nat) & Bool)) -> FeedbackControl:
  feedback_consumer_299499(result, lexical_capture_3, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_22)

def token_end_first_list(terms: List<&2, Ast.SyntaxTerm>) -> Nat:
  match terms:
    case +term <> _:
      token_end_first(term)
    case Nil{}:
      0n

def parse_parallel_parsed_body(ok_body: Bool, body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, +values: List<&2, Ast.SyntaxTerm>, patterns: List<&2, Ast.SyntaxPattern>, quantity: Ast.Quantity, file: String, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      span_end = token_end_of(after_body, token_end_first_list(values))
      ((Ast.BodyLocal{patterns, quantity, values, body, span(file, beg, span_end)}, after_body), True{})
    case False{}:
      ((body, after_body), False{})

def feedback_resume_Kont_300984(lexical_capture_3: List<&2, Ast.SyntaxTerm>, lexical_capture_7: List<&2, Ast.SyntaxPattern>, lexical_capture_13: Ast.Quantity, lexical_capture_15: String, lexical_capture_17: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, body => after_body => ok_body => parse_parallel_parsed_body(ok_body, body, after_body, lexical_capture_3, lexical_capture_7, lexical_capture_13, lexical_capture_15, lexical_capture_17)))

def step_parse_local_body_value(+file: String, +key: String, +beg: Nat, key_end: Nat, +col: Nat, value: Ast.SyntaxTerm, +after_value: List<&2, Lexer.Token>, scope: List<&2, Scope>, +depth: Nat, +quantity: Ast.Quantity) -> FeedbackControl:
  pattern = { Ast.PatternVar{key,  depth, quantity,  span(file, beg, key_end)} : Ast.SyntaxPattern }
  next_scope = extend_scope(key, depth, scope)
  step_parse_local_body_ready(local_body_ready(after_value, col), file, key, beg, col, pattern, value, after_value, next_scope, depth, quantity)

def step_parse_local_body_term_result(ok_value: Bool, file: String, key: String, beg: Nat, key_end: Nat, col: Nat, +value: Ast.SyntaxTerm, +after_value: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, quantity: Ast.Quantity) -> FeedbackControl:
  match ok_value:
    case True{}:
      step_parse_local_body_value(file, key, beg, key_end, col, value, after_value, scope, depth, quantity)
    case False{}:
      feedback_pack_5(((value, after_value), False{}))

def feedback_consumer_301626(v_318: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_3: String, v_5: Nat, v_7: Nat, v_9: Nat, v_14: List<&2, Scope>, v_16: Nat, v_17: Ast.Quantity) -> FeedbackControl:
  match v_318:
    case ((v_319, v_320), v_321):
      step_parse_local_body_term_result(v_321, v_1, v_3, v_5, v_7, v_9, v_319, v_320, v_14, v_16, v_17)

def feedback_resume_Kont_301643(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, lexical_capture_17: Ast.Quantity, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_301626(result, lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_14, lexical_capture_16, lexical_capture_17)

def parse_local_body_parsed(ok_body: Bool, body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, file: String, key: String, beg: Nat, pattern: Ast.SyntaxPattern, quantity: Ast.Quantity, +value: Ast.SyntaxTerm) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      ((Ast.BodyLocal{ [pattern], quantity, [value], body, span(file, beg, token_end_of(after_body, token_end_first(value)))}, after_body), True{})
    case False{}:
      ((body, after_body), False{})

def feedback_resume_Kont_303223(lexical_capture_3: String, lexical_capture_5: String, lexical_capture_7: Nat, lexical_capture_10: Ast.SyntaxPattern, lexical_capture_19: Ast.Quantity, lexical_capture_11: Ast.SyntaxTerm, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, body => after_body => ok_body => parse_local_body_parsed(ok_body, body, after_body, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_19, lexical_capture_11)))

def feedback_consumer_303829(v_319: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_3: String, v_5: Nat, v_7: Nat, v_9: Nat, v_14: List<&2, Scope>, v_16: Nat) -> FeedbackControl:
  match v_319:
    case ((v_320, v_321), v_322):
      step_parse_local_body_term_result(v_322, v_1, v_3, v_5, v_7, v_9, v_320, v_321, v_14, v_16, Ast.QOne{})

def feedback_resume_Kont_303846(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_303829(result, lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_14, lexical_capture_16)

def feedback_make_Kont_307113(lexical_capture_4: Ast.SyntaxPattern, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: String, lexical_capture_13: List<&2, Lexer.Token>, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_20: List<&2, Scope>, lexical_capture_22: Nat) -> FeedbackFrame:
  Kont_307113{lexical_capture_4, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15, lexical_capture_17, lexical_capture_20, lexical_capture_22}

def step_parse_destructuring_pattern_result(ok_pattern: Bool, after_pattern: List<&2, Lexer.Token>, pattern: Ast.SyntaxPattern, next_scope: List<&2, Scope>, next_depth: Nat, +file: String, +tokens: List<&2, Lexer.Token>, beg: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match ok_pattern after_pattern:
    case True{} +equals <> after_equals:
      match equals:
        case Lexer.TokenInfo{ _, "=",  _,  _,  _,  _}:
          feedback_attach(step_parse_term(file, after_equals, scope, depth, 0n), feedback_make_Kont_307113(pattern, next_scope, next_depth, file, tokens, beg, col, scope, depth))
        case _:
          step_parse_reply(file, tokens, scope, depth)
    case _ _:
      step_parse_reply(file, tokens, scope, depth)

def feedback_consumer_306274(v_320: Pair(Pair(Ast.SyntaxPattern, List<&2, Lexer.Token>), Pair(Pair(List<&2, Scope>, Nat), Bool)), v_3: String, v_5: List<&2, Lexer.Token>, v_7: Nat, v_9: Nat, v_12: List<&2, Scope>, v_14: Nat) -> FeedbackControl:
  match v_320:
    case ((v_321, v_322), (v_323, v_324), v_325):
      step_parse_destructuring_pattern_result(v_325, v_322, v_321, v_323, v_324, v_3, v_5, v_7, v_9, v_12, v_14)

def feedback_resume_Kont_306294(lexical_capture_3: String, lexical_capture_5: List<&2, Lexer.Token>, lexical_capture_7: Nat, lexical_capture_9: Nat, lexical_capture_12: List<&2, Scope>, lexical_capture_14: Nat, result: ((Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool))) -> FeedbackControl:
  feedback_consumer_306274(result, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_12, lexical_capture_14)

def feedback_make_Kont_308366(lexical_capture_2: Ast.SyntaxTerm, lexical_capture_5: Ast.SyntaxPattern, lexical_capture_12: String, lexical_capture_14: Nat) -> FeedbackFrame:
  Kont_308366{lexical_capture_2, lexical_capture_5, lexical_capture_12, lexical_capture_14}

def step_parse_destructuring_body_ready(is_ready: Bool, +value: Ast.SyntaxTerm, +after_value: List<&2, Lexer.Token>, pattern: Ast.SyntaxPattern, next_scope: List<&2, Scope>, next_depth: Nat, +file: String, beg: Nat, col: Nat) -> FeedbackControl:
  match is_ready:
    case True{}:
      feedback_attach(step_parse_body(file, skip_rewrite_semicolon(after_value), next_scope, next_depth, col), feedback_make_Kont_308366(value, pattern, file, beg))
    case False{}:
      feedback_pack_5(((Ast.TermHole{ "parse-error: expected an indented destructuring body",  span(file, token_end_first(value), token_end_first(value))}, after_value), False{}))

def step_parse_destructuring_value_result(ok_value: Bool, +value: Ast.SyntaxTerm, +after_value: List<&2, Lexer.Token>, pattern: Ast.SyntaxPattern, next_scope: List<&2, Scope>, next_depth: Nat, file: String, tokens: List<&2, Lexer.Token>, beg: Nat, +col: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match ok_value:
    case True{}:
      step_parse_destructuring_body_ready(local_body_ready(after_value, col), value, after_value, pattern, next_scope, next_depth, file, beg, col)
    case False{}:
      feedback_pack_5(((value, after_value), False{}))

def feedback_consumer_307096(v_321: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_4: Ast.SyntaxPattern, v_7: List<&2, Scope>, v_9: Nat, v_11: String, v_13: List<&2, Lexer.Token>, v_15: Nat, v_17: Nat, v_20: List<&2, Scope>, v_22: Nat) -> FeedbackControl:
  match v_321:
    case ((v_322, v_323), v_324):
      step_parse_destructuring_value_result(v_324, v_322, v_323, v_4, v_7, v_9, v_11, v_13, v_15, v_17, v_20, v_22)

def feedback_resume_Kont_307113(lexical_capture_4: Ast.SyntaxPattern, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: String, lexical_capture_13: List<&2, Lexer.Token>, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_20: List<&2, Scope>, lexical_capture_22: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_307096(result, lexical_capture_4, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15, lexical_capture_17, lexical_capture_20, lexical_capture_22)

def parse_destructuring_parsed_body(ok_body: Bool, body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, +value: Ast.SyntaxTerm, pattern: Ast.SyntaxPattern, file: String, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      ((Ast.BodyLocal{ [pattern], Ast.QOne{}, [value], body, span(file, beg, token_end_of(after_body, token_end_first(value)))}, after_body), True{})
    case False{}:
      ((body, after_body), False{})

def feedback_resume_Kont_308366(lexical_capture_2: Ast.SyntaxTerm, lexical_capture_5: Ast.SyntaxPattern, lexical_capture_12: String, lexical_capture_14: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, body => after_body => ok_body => parse_destructuring_parsed_body(ok_body, body, after_body, lexical_capture_2, lexical_capture_5, lexical_capture_12, lexical_capture_14)))

def match_scrutinees_is_colon(colon: Lexer.Token) -> Bool:
  match colon:
    case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
      True{}
    case _:
      False{}

def match_scrutinees_branch_1(after_scrutinees: List<&2, Lexer.Token>, +file: String, +colon: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected :",  span(file, token_beg(colon), token_end(colon))}, after_scrutinees), False{})

def feedback_make_Kont_309436(lexical_capture_1: List<&2, Ast.SyntaxTerm>, lexical_capture_13: Lexer.Token, lexical_capture_3: String, lexical_capture_5: Nat) -> FeedbackFrame:
  Kont_309436{lexical_capture_1, lexical_capture_13, lexical_capture_3, lexical_capture_5}

def feedback_make_parse_case_row_indented(is_indented: Bool, file: String, tokens: List<&2, Lexer.Token>, rest: List<&2, Lexer.Token>, parent_col: Nat, scope: List<&2, Scope>, depth: Nat, arity: Nat, acc: List<&2, Ast.SyntaxTerm>, beg: Nat, col: Nat) -> FeedbackRequest:
  Request_parse_case_row_indented{is_indented, file, tokens, rest, parent_col, scope, depth, arity, acc, beg, col}

def step_parse_case_rows_scan(file: String, +tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +parent_col: Nat, scope: List<&2, Scope>, depth: Nat, arity: Nat, +acc: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match scanned:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{ Lexer.NameToken{},  "case", beg,  _,  _, +col}:
          FeedbackControl{FeedbackCall{feedback_make_parse_case_row_indented(Nat.is_lt(parent_col, col), file, tokens, rest, parent_col, scope, depth, arity, acc, beg, col)}, Nil{}, NoProgress{}, NoProgress{}}
        case _:
          feedback_pack_9(parse_case_rows_stop(acc, tokens))
    case Nil{}:
      feedback_pack_9(parse_case_rows_stop(acc, Nil{}))

def step_parse_case_rows(file: String, +tokens: List<&2, Lexer.Token>, parent_col: Nat, scope: List<&2, Scope>, depth: Nat, arity: Nat, acc: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  step_parse_case_rows_scan(file, tokens, skip_lines(tokens), parent_col, scope, depth, arity, acc)

def step_match_scrutinees_branch_0(+scrutinees: List<&2, Ast.SyntaxTerm>, +file: String, +beg: Nat, col: Nat, scope: List<&2, Scope>, depth: Nat, +colon: Lexer.Token, after_colon: List<&2, Lexer.Token>) -> FeedbackControl:
  feedback_attach(step_parse_case_rows(file, after_colon, Nat.sub(col, 1n), scope, depth, List.length(&2, Ast.SyntaxTerm, scrutinees), Nil{}), feedback_make_Kont_309436(scrutinees, colon, file, beg))

def step_match_scrutinees_run(is_colon: Bool, after_scrutinees: List<&2, Lexer.Token>, +scrutinees: List<&2, Ast.SyntaxTerm>, +file: String, +beg: Nat, col: Nat, scope: List<&2, Scope>, depth: Nat, +colon: Lexer.Token, after_colon: List<&2, Lexer.Token>) -> FeedbackControl:
  match is_colon:
    case True{}:
      step_match_scrutinees_branch_0(scrutinees, file, beg, col, scope, depth, colon, after_colon)
    case False{}:
      feedback_pack_5(match_scrutinees_branch_1(after_scrutinees, file, colon))

def step_parse_match_scrutinees(ok_scrutinees: Bool, +after_scrutinees: List<&2, Lexer.Token>, +scrutinees: List<&2, Ast.SyntaxTerm>, +file: String, +beg: Nat, col: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match ok_scrutinees after_scrutinees:
    case True{} +colon <> after_colon:
      step_match_scrutinees_run(match_scrutinees_is_colon(colon), after_scrutinees, scrutinees, file, beg, col, scope, depth, colon, after_colon)
    case _ _:
      feedback_pack_5(((Ast.TermHole{ "parse-error: expected match scrutinee",  span(file, beg, beg)}, after_scrutinees), False{}))

def feedback_consumer_308931(v_322: Pair(Pair(List<&2, Ast.SyntaxTerm>, List<&2, Lexer.Token>), Bool), v_1: String, v_5: Nat, v_7: Nat, v_10: List<&2, Scope>, v_12: Nat) -> FeedbackControl:
  match v_322:
    case ((v_323, v_324), v_325):
      step_parse_match_scrutinees(v_325, v_324, v_323, v_1, v_5, v_7, v_10, v_12)

def feedback_resume_Kont_308948(lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_10: List<&2, Scope>, lexical_capture_12: Nat, result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_308931(result, lexical_capture_1, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_12)

def parse_match_cases_result(ok_cases: Bool, cases: List<&2, Ast.SyntaxTerm>, +after_cases: List<&2, Lexer.Token>, +scrutinees: List<&2, Ast.SyntaxTerm>, +colon: Lexer.Token, file: String, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_cases:
    case True{}:
      ((Ast.BodyMatch{scrutinees, cases, span(file, beg, token_end_of(after_cases, token_end_first_list(scrutinees)))}, after_cases), True{})
    case False{}:
      ((Ast.TermHole{ "parse-error: expected an indented case", span(file, token_beg(colon), token_end(colon))}, after_cases), False{})

def feedback_resume_Kont_309436(lexical_capture_1: List<&2, Ast.SyntaxTerm>, lexical_capture_13: Lexer.Token, lexical_capture_3: String, lexical_capture_5: Nat, result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_args_result(result, cases => after_cases => ok_cases => parse_match_cases_result(ok_cases, cases, after_cases, lexical_capture_1, lexical_capture_13, lexical_capture_3, lexical_capture_5)))

def feedback_make_parse_terms_until_colon_result(ok: Bool, term: Ast.SyntaxTerm, after: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.SyntaxTerm>) -> FeedbackRequest:
  Request_parse_terms_until_colon_result{ok, term, after, file, scope, depth, acc}

def feedback_consumer_312581(v_323: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_6: List<&2, Scope>, v_8: Nat, v_10: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match v_323:
    case ((v_324, v_325), v_326):
      FeedbackControl{FeedbackCall{feedback_make_parse_terms_until_colon_result(v_326, v_324, v_325, v_1, v_6, v_8, v_10)}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_resume_Kont_312599(lexical_capture_1: String, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat, lexical_capture_10: List<&2, Ast.SyntaxTerm>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_312581(result, lexical_capture_1, lexical_capture_6, lexical_capture_8, lexical_capture_10)

def step_parse_case_row_result(ok_row: Bool, +row: Ast.SyntaxTerm, +after_row: List<&2, Lexer.Token>, file: String, tokens: List<&2, Lexer.Token>, parent_col: Nat, scope: List<&2, Scope>, depth: Nat, arity: Nat, +acc: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match ok_row:
    case True{}:
      step_parse_case_rows_scan(file, after_row, skip_lines(after_row), parent_col, scope, depth, arity, row <> acc)
    case False{}:
      feedback_pack_9(((List.reverse(&2, Ast.SyntaxTerm, row <> acc), after_row), False{}))

def feedback_consumer_313168(v_324: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_3: String, v_5: List<&2, Lexer.Token>, v_9: Nat, v_12: List<&2, Scope>, v_14: Nat, v_16: Nat, v_18: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match v_324:
    case ((v_325, v_326), v_327):
      step_parse_case_row_result(v_327, v_325, v_326, v_3, v_5, v_9, v_12, v_14, v_16, v_18)

def feedback_resume_Kont_313186(lexical_capture_3: String, lexical_capture_5: List<&2, Lexer.Token>, lexical_capture_9: Nat, lexical_capture_12: List<&2, Scope>, lexical_capture_14: Nat, lexical_capture_16: Nat, lexical_capture_18: List<&2, Ast.SyntaxTerm>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_313168(result, lexical_capture_3, lexical_capture_5, lexical_capture_9, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_18)

def pattern_count_matches(patterns: List<&2, Ast.SyntaxPattern>, count: Nat) -> Bool:
  match patterns:
    case Nil{}:
      match count:
        case 0n:
          True{}
        case _:
          False{}
    case +_ <> rest:
      match count:
        case 0n:
          False{}
        case 1n+more:
          pattern_count_matches(rest, more)

def case_row_is_colon(colon: Lexer.Token) -> Bool:
  match colon:
    case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
      True{}
    case _:
      False{}

def case_row_branch_1(file: String, tokens: List<&2, Lexer.Token>, +colon: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected :",  span(file, token_beg(colon), token_end(colon))}, tokens), False{})

def feedback_make_Kont_317252(lexical_capture_5: List<&2, Ast.SyntaxPattern>, lexical_capture_3: String, lexical_capture_15: Nat) -> FeedbackFrame:
  Kont_317252{lexical_capture_5, lexical_capture_3, lexical_capture_15}

def step_parse_case_body_indented(is_indented: Bool, +file: String, patterns: List<&2, Ast.SyntaxPattern>, +after_colon: List<&2, Lexer.Token>, +colon: Lexer.Token, scope: List<&2, Scope>, depth: Nat, beg: Nat, col: Nat) -> FeedbackControl:
  match is_indented:
    case True{}:
      feedback_attach(step_parse_body(file, after_colon, scope, depth, col), feedback_make_Kont_317252(patterns, file, beg))
    case False{}:
      feedback_pack_5(((Ast.TermHole{ "parse-error: expected an indented case body",  span(file, token_end(colon), token_end(colon))}, after_colon), False{}))

def step_case_row_branch_0(file: String, patterns: List<&2, Ast.SyntaxPattern>, scope: List<&2, Scope>, depth: Nat, +beg: Nat, +col: Nat, +colon: Lexer.Token, +after_colon: List<&2, Lexer.Token>) -> FeedbackControl:
  step_parse_case_body_indented(body_indented(after_colon, col), file, patterns, after_colon, colon, scope, depth, beg, col)

def step_case_row_run(is_colon: Bool, +file: String, patterns: List<&2, Ast.SyntaxPattern>, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, +beg: Nat, +col: Nat, +colon: Lexer.Token, +after_colon: List<&2, Lexer.Token>) -> FeedbackControl:
  match is_colon:
    case True{}:
      step_case_row_branch_0(file, patterns, scope, depth, beg, col, colon, after_colon)
    case False{}:
      feedback_pack_5(case_row_branch_1(file, tokens, colon))

def step_parse_case_row_body(+file: String, patterns: List<&2, Ast.SyntaxPattern>, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, +beg: Nat, +col: Nat) -> FeedbackControl:
  match tokens:
    case +colon <> +after_colon:
      step_case_row_run(case_row_is_colon(colon), file, patterns, tokens, scope, depth, beg, col, colon, after_colon)
    case Nil{}:
      feedback_pack_5(((Ast.TermHole{ "parse-error: expected :",  span(file, beg, beg)}, Nil{}), False{}))

def step_parse_case_row_count(is_valid: Bool, patterns: List<&2, Ast.SyntaxPattern>, +after_patterns: List<&2, Lexer.Token>, next_scope: List<&2, Scope>, next_depth: Nat, +file: String, +beg: Nat, col: Nat) -> FeedbackControl:
  match is_valid:
    case True{}:
      step_parse_case_row_body(file, patterns, after_patterns, next_scope, next_depth, beg, col)
    case False{}:
      feedback_pack_5(((Ast.TermHole{ "parse-error: case needs one pattern per scrutinee",  span(file, beg, token_end_of(after_patterns, beg))}, after_patterns), False{}))

def step_parse_case_row_patterns(ok_patterns: Bool, +patterns: List<&2, Ast.SyntaxPattern>, +after_patterns: List<&2, Lexer.Token>, next_scope: List<&2, Scope>, next_depth: Nat, +file: String, +beg: Nat, col: Nat, arity: Nat) -> FeedbackControl:
  match ok_patterns:
    case True{}:
      step_parse_case_row_count(pattern_count_matches(patterns, arity), patterns, after_patterns, next_scope, next_depth, file, beg, col)
    case False{}:
      feedback_pack_5(((Ast.TermHole{ "parse-error: expected a case pattern",  span(file, beg, beg)}, after_patterns), False{}))

def step_parse_case_row_scan_result(result: PatternScanOutcome, +file: String, +beg: Nat, col: Nat, arity: Nat) -> FeedbackControl:
  match result:
    case PatternCaseOutcome{patterns, after, scope, depth, ok}:
      step_parse_case_row_patterns(ok, patterns, after, scope, depth, file, beg, col, arity)
    case PatternSingleOutcome{pattern, after, scope, depth, ok}:
      feedback_pack_5(((Ast.TermHole{"parse-error: unexpected single-pattern outcome", span(file, beg, beg)}, after), False{}))

def feedback_resume_Kont_316227(capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: Nat, result: PatternScanOutcome) -> FeedbackControl:
  step_parse_case_row_scan_result(result, capture_1, capture_2, capture_3, capture_4)

def parse_case_body_result(ok_body: Bool, +body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, patterns: List<&2, Ast.SyntaxPattern>, file: String, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      ((Ast.BodyCase{patterns, body, span(file, beg, token_end_of(after_body, token_end_first(body)))}, after_body), True{})
    case False{}:
      ((body, after_body), False{})

def feedback_resume_Kont_317252(lexical_capture_5: List<&2, Ast.SyntaxPattern>, lexical_capture_3: String, lexical_capture_15: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, body => after_body => ok_body => parse_case_body_result(ok_body, body, after_body, lexical_capture_5, lexical_capture_3, lexical_capture_15)))

def step_evaluation_context_parse_template_binder_type_result_312732(+v_4: String, v_6: List<&2, Ast.TelescopeItem>, v_9: List<&2, Scope>, +v_11: Nat, +v_13: String, v_15: Nat, +v_26: Ast.SyntaxTerm, +v_27: List<&2, Lexer.Token>, +v_29: Nat, v_306: Nat) -> FeedbackControl:
  v_34 = {Ast.TemplateBinder{v_13, v_29, v_26, span(v_4, v_15, v_306)} : Ast.TelescopeItem}
  v_37 = extend_scope(v_13, v_29, v_9)
  step_parse_def_binders(v_4, v_27, v_37, Nat.add(v_11, 1n), v_34 <> v_6)

def feedback_resume_Kont_322498(capture_0: String, capture_1: List<&2, Ast.TelescopeItem>, capture_2: List<&2, Scope>, capture_3: Nat, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: List<&2, Lexer.Token>, capture_8: Nat, result: Nat) -> FeedbackControl:
  step_evaluation_context_parse_template_binder_type_result_312732(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, result)

def feedback_make_Kont_322498(capture_0: String, capture_1: List<&2, Ast.TelescopeItem>, capture_2: List<&2, Scope>, capture_3: Nat, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: List<&2, Lexer.Token>, capture_8: Nat) -> FeedbackFrame:
  Kont_322498{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8}

def step_parse_template_binder_type_result_quantity_0(v_17: List<&2, Lexer.Token>, +v_22: List<&2, Lexer.Token>, +v_21: Ast.SyntaxTerm, +v_4: String, +v_6: List<&2, Ast.TelescopeItem>, +v_9: List<&2, Scope>, +v_11: Nat, +v_13: String, v_15: Nat) -> FeedbackControl:
  +v_24 = v_11
  feedback_attach(step_consumed_token_end(v_17, v_22, token_end_first(v_21)), feedback_make_Kont_322498(v_4, v_6, v_9, v_11, v_13, v_15, v_21, v_22, v_24))

def step_parse_template_binder_type_result(v_2: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), +v_4: String, +v_6: List<&2, Ast.TelescopeItem>, +v_9: List<&2, Scope>, +v_11: Nat, +v_13: String, v_15: Nat, v_17: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_2:
    case ((+v_21, v_22), True{}):
      step_parse_template_binder_type_result_quantity_0(v_17, v_22, v_21, v_4, v_6, v_9, v_11, v_13, v_15)
    case ((v_31, v_32), False{}):
      feedback_pack_1(((((List.reverse(&2, Ast.TelescopeItem, v_6), v_32), v_9), v_11), False{}))

def feedback_resume_Kont_323146(capture_1: String, capture_2: List<&2, Ast.TelescopeItem>, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: String, capture_6: Nat, capture_7: List<&2, Lexer.Token>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_template_binder_type_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7)

def step_evaluation_context_parse_def_binder_type_result_315744(+v_4: String, +v_6: String, v_7: Ast.Quantity, v_9: Nat, v_11: List<&2, Ast.TelescopeItem>, v_14: List<&2, Scope>, +v_16: Nat, +v_27: Ast.SyntaxTerm, +v_28: List<&2, Lexer.Token>, +v_30: Nat, v_307: Nat) -> FeedbackControl:
  v_35 = {Ast.Binder{v_7, v_6, v_30, v_27, span(v_4, v_9, v_307)} : Ast.TelescopeItem}
  v_38 = extend_scope(v_6, v_30, v_14)
  step_parse_def_binders(v_4, v_28, v_38, Nat.add(v_16, 1n), v_35 <> v_11)

def feedback_resume_Kont_325947(capture_0: String, capture_1: String, capture_2: Ast.Quantity, capture_3: Nat, capture_4: List<&2, Ast.TelescopeItem>, capture_5: List<&2, Scope>, capture_6: Nat, capture_7: Ast.SyntaxTerm, capture_8: List<&2, Lexer.Token>, capture_9: Nat, result: Nat) -> FeedbackControl:
  step_evaluation_context_parse_def_binder_type_result_315744(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, result)

def feedback_make_Kont_325947(capture_0: String, capture_1: String, capture_2: Ast.Quantity, capture_3: Nat, capture_4: List<&2, Ast.TelescopeItem>, capture_5: List<&2, Scope>, capture_6: Nat, capture_7: Ast.SyntaxTerm, capture_8: List<&2, Lexer.Token>, capture_9: Nat) -> FeedbackFrame:
  Kont_325947{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9}

def step_parse_def_binder_type_result_quantity_0(v_18: List<&2, Lexer.Token>, +v_23: List<&2, Lexer.Token>, +v_22: Ast.SyntaxTerm, +v_4: String, +v_6: String, v_7: Ast.Quantity, v_9: Nat, +v_11: List<&2, Ast.TelescopeItem>, +v_14: List<&2, Scope>, +v_16: Nat) -> FeedbackControl:
  +v_25 = v_16
  feedback_attach(step_consumed_token_end(v_18, v_23, token_end_first(v_22)), feedback_make_Kont_325947(v_4, v_6, v_7, v_9, v_11, v_14, v_16, v_22, v_23, v_25))

def step_parse_def_binder_type_result(v_2: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), +v_4: String, +v_6: String, v_7: Ast.Quantity, v_9: Nat, +v_11: List<&2, Ast.TelescopeItem>, +v_14: List<&2, Scope>, +v_16: Nat, v_18: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_2:
    case ((+v_22, v_23), True{}):
      step_parse_def_binder_type_result_quantity_0(v_18, v_23, v_22, v_4, v_6, v_7, v_9, v_11, v_14, v_16)
    case ((v_32, v_33), False{}):
      feedback_pack_1(((((List.reverse(&2, Ast.TelescopeItem, v_11), v_33), v_14), v_16), False{}))

def feedback_resume_Kont_326599(capture_1: String, capture_2: String, capture_3: Ast.Quantity, capture_4: Nat, capture_5: List<&2, Ast.TelescopeItem>, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: List<&2, Lexer.Token>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_def_binder_type_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8)

def feedback_pack_3(result: ((Ast.DefBody & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  match result:
    case ((result_0_0, result_0_1), result_1):
      FeedbackControl{FeedbackDone{Value_3{result_0_0, result_0_1, result_1}}, Nil{}, NoProgress{}, NoProgress{}}

def parse_definition_term_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool) -> (Ast.DefBody & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((term, after), ok):
      ((Ast.DefTerm{term}, after), ok)

def feedback_resume_Kont_328193(result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_3(parse_definition_term_result(result))

def definition_failure(+file: String, key: String, binders: List<&2, Ast.TelescopeItem>, beg: Nat, +end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  ((Ast.DefTop{Ast.Definition{key, binders, Ast.NoTerm{}, Ast.DefTerm{Ast.TermHole{"parse-error: malformed definition", span(file, end, end)}}, False{}, span(file, beg, end)}}, rest), False{})

def parse_definition_typed_body_result(ok_body: Bool, body: Ast.DefBody, +after_body: List<&2, Lexer.Token>, colon: Lexer.Token, after_colon: List<&2, Lexer.Token>, file: String, key: String, beg: Nat, binders: List<&2, Ast.TelescopeItem>, +result: Ast.SyntaxTerm) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      ((Ast.DefTop{Ast.Definition{key, binders, Ast.SomeTerm{result}, body, False{}, span(file, beg, token_end_of(after_body, token_end_first(result)))}}, after_body), True{})
    case False{}:
      definition_failure(file, key, binders, beg, token_end(colon), after_colon)

def with_def_body_result(result: (Ast.DefBody & List<&2, Lexer.Token>) & Bool, use: Ast.DefBody -> List<&2, Lexer.Token> -> Bool -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((body, after), ok):
      use(body, after, ok)

def feedback_resume_Kont_329864(lexical_capture_0: Lexer.Token, lexical_capture_2: List<&2, Lexer.Token>, lexical_capture_8: String, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_14: List<&2, Ast.TelescopeItem>, lexical_capture_5: Ast.SyntaxTerm, result: ((Ast.DefBody & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_6(with_def_body_result(result, body => after_body => ok_body => parse_definition_typed_body_result(ok_body, body, after_body, lexical_capture_0, lexical_capture_2, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_5)))

def feedback_make_Kont_329864(lexical_capture_0: Lexer.Token, lexical_capture_2: List<&2, Lexer.Token>, lexical_capture_8: String, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_14: List<&2, Ast.TelescopeItem>, lexical_capture_5: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_329864{lexical_capture_0, lexical_capture_2, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_5}

def definition_body_is_colon(token: Lexer.Token) -> Bool:
  match token:
    case Lexer.TokenInfo{ Lexer.NameToken{},  "import",  _,  _,  _,  _}:
      True{}
    case _:
      False{}

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

def definition_body_branch_0(tokens: List<&2, Lexer.Token>) -> Pair(Pair(Ast.DefBody, List<&2, Lexer.Token>), Bool):
  parse_definition_imports_result(parse_external_imports(tokens, Nil{}))

def feedback_make_Kont_328193() -> FeedbackFrame:
  Kont_328193{}

def step_definition_body_branch_1(file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_body(file, tokens, scope, depth, 0n), feedback_make_Kont_328193())

def step_definition_body_run(is_colon: Bool, file: String, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match is_colon:
    case True{}:
      feedback_pack_3(definition_body_branch_0(tokens))
    case False{}:
      step_definition_body_branch_1(file, tokens, scope, depth)

def step_parse_definition_body_scan(+file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match scanned:
    case +token <> _:
      step_definition_body_run(definition_body_is_colon(token), file, tokens, scope, depth)
    case Nil{}:
      feedback_pack_3(((Ast.DefTerm{Ast.TermHole{ "parse-error: expected a definition body",  span(file, 0n, 0n)}}, Nil{}), False{}))

def step_parse_definition_body(file: String, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  step_parse_definition_body_scan(file, tokens, skip_lines(tokens), scope, depth)

def step_parse_definition_typed_colon(+colon: Lexer.Token, +after_colon: List<&2, Lexer.Token>, after_result: List<&2, Lexer.Token>, result: Ast.SyntaxTerm, header: Lexer.Token, +file: String, +key: String, +beg: Nat, +binders: List<&2, Ast.TelescopeItem>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match colon:
    case Lexer.TokenInfo{_, ":", _, _, _, _}:
      feedback_attach(step_parse_definition_body(file, after_colon, scope, depth), feedback_make_Kont_329864(colon, after_colon, file, key, beg, binders, result))
    case Lexer.TokenInfo{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4, feedback_field_4_5}:
      feedback_pack_6(definition_failure(file, key, binders, beg, token_beg((Lexer.TokenInfo{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4, feedback_field_4_5} : Lexer.Token)), after_result))

def step_parse_definition_typed_result(result_pair: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, +header: Lexer.Token, +file: String, +key: String, +beg: Nat, +binders: List<&2, Ast.TelescopeItem>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match result_pair:
    case ((result, +colon <> +after_colon), True{}):
      step_parse_definition_typed_colon(colon, after_colon, colon <> after_colon, result, header, file, key, beg, binders, scope, depth)
    case ((_, after_result), False{}):
      feedback_pack_6(definition_failure(file, key, binders, beg, token_end(header), after_result))
    case ((_, after_result), True{}):
      feedback_pack_6(definition_failure(file, key, binders, beg, token_end(header), after_result))

def feedback_resume_Kont_331293(capture_1: Lexer.Token, capture_2: String, capture_3: String, capture_4: Nat, capture_5: List<&2, Ast.TelescopeItem>, capture_6: List<&2, Scope>, capture_7: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_definition_typed_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7)

def parse_definition_untyped_body_result(ok_body: Bool, body: Ast.DefBody, +after_body: List<&2, Lexer.Token>, file: String, key: String, beg: Nat, binders: List<&2, Ast.TelescopeItem>, header: Lexer.Token, rest: List<&2, Lexer.Token>) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      ((Ast.DefTop{Ast.Definition{key, binders, Ast.NoTerm{}, body, False{}, span(file, beg, token_end_of(after_body, token_end(header)))}}, after_body), True{})
    case False{}:
      definition_failure(file, key, binders, beg, token_end(header), rest)

def feedback_resume_Kont_331662(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: List<&2, Ast.TelescopeItem>, lexical_capture_13: Lexer.Token, lexical_capture_15: List<&2, Lexer.Token>, result: ((Ast.DefBody & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_6(with_def_body_result(result, body => after_body => ok_body => parse_definition_untyped_body_result(ok_body, body, after_body, lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_13, lexical_capture_15)))

def definition_header_is_colon(header: Lexer.Token) -> DefinitionHeaderAction:
  match header:
    case Lexer.TokenInfo{ _, "->",  _,  _,  _,  _}:
      DefinitionHeaderRow0{}
    case Lexer.TokenInfo{_, ":", _, _, _, _}:
      DefinitionHeaderRow1{}
    case _:
      DefinitionHeaderRow2{}

def definition_header_branch_2(+file: String, key: String, +beg: Nat, binders: List<&2, Ast.TelescopeItem>, tokens: List<&2, Lexer.Token>, +header: Lexer.Token) -> Pair(Pair(Ast.TopLevel, List<&2, Lexer.Token>), Bool):
  definition_failure(file, key, binders, beg, token_beg(header), tokens)

def feedback_make_Kont_331293(capture_1: Lexer.Token, capture_2: String, capture_3: String, capture_4: Nat, capture_5: List<&2, Ast.TelescopeItem>, capture_6: List<&2, Scope>, capture_7: Nat) -> FeedbackFrame:
  Kont_331293{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7}

def step_definition_header_branch_0(+file: String, key: String, +beg: Nat, binders: List<&2, Ast.TelescopeItem>, +scope: List<&2, Scope>, +depth: Nat, +header: Lexer.Token, +rest: List<&2, Lexer.Token>) -> FeedbackControl:
  feedback_attach(step_parse_term(file, rest, scope, depth, 0n), feedback_make_Kont_331293(header, file, key, beg, binders, scope, depth))

def feedback_make_Kont_331662(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: List<&2, Ast.TelescopeItem>, lexical_capture_13: Lexer.Token, lexical_capture_15: List<&2, Lexer.Token>) -> FeedbackFrame:
  Kont_331662{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_13, lexical_capture_15}

def step_definition_header_branch_1(+file: String, key: String, +beg: Nat, binders: List<&2, Ast.TelescopeItem>, +scope: List<&2, Scope>, +depth: Nat, +header: Lexer.Token, +rest: List<&2, Lexer.Token>) -> FeedbackControl:
  feedback_attach(step_parse_definition_body(file, rest, scope, depth), feedback_make_Kont_331662(file, key, beg, binders, header, rest))

def step_definition_header_run(is_colon: DefinitionHeaderAction, +file: String, +key: String, +beg: Nat, +binders: List<&2, Ast.TelescopeItem>, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +header: Lexer.Token, +rest: List<&2, Lexer.Token>) -> FeedbackControl:
  match is_colon:
    case DefinitionHeaderRow0{}:
      step_definition_header_branch_0(file, key, beg, binders, scope, depth, header, rest)
    case DefinitionHeaderRow1{}:
      step_definition_header_branch_1(file, key, beg, binders, scope, depth, header, rest)
    case DefinitionHeaderRow2{}:
      feedback_pack_6(definition_header_branch_2(file, key, beg, binders, tokens, header))

def step_parse_definition_after_binders_scan(+file: String, +key: String, +beg: Nat, +binders: List<&2, Ast.TelescopeItem>, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match scanned:
    case +header <> +rest:
      step_definition_header_run(definition_header_is_colon(header), file, key, beg, binders, tokens, scope, depth, header, rest)
    case Nil{}:
      feedback_pack_6(definition_failure(file, key, binders, beg, beg, Nil{}))

def step_parse_definition_after_binders(file: String, key: String, beg: Nat, binders: List<&2, Ast.TelescopeItem>, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  step_parse_definition_after_binders_scan(file, key, beg, binders, tokens, skip_lines(tokens), scope, depth)

def step_parse_definition_binders_result(ok_binders: Bool, binders: List<&2, Ast.TelescopeItem>, +after_binders: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, +file: String, +key: String, +beg: Nat) -> FeedbackControl:
  match ok_binders:
    case True{}:
      step_parse_definition_after_binders(file, key, beg, binders, after_binders, scope, depth)
    case False{}:
      feedback_pack_6(definition_failure(file, key, Nil{}, beg, token_end_of(after_binders, beg), after_binders))

def feedback_consumer_334633(v_325: Pair(Pair(Pair(Pair(List<&2, Ast.TelescopeItem>, List<&2, Lexer.Token>), List<&2, Scope>), Nat), Bool), v_1: String, v_3: String, v_5: Nat) -> FeedbackControl:
  match v_325:
    case ((((v_326, v_327), v_328), v_329), v_330):
      step_parse_definition_binders_result(v_330, v_326, v_327, v_328, v_329, v_1, v_3, v_5)

def feedback_resume_Kont_334657(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, result: ((((List<&2, Ast.TelescopeItem> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool)) -> FeedbackControl:
  feedback_consumer_334633(result, lexical_capture_1, lexical_capture_3, lexical_capture_5)

def mark_unsafe(top: Ast.TopLevel, unsafe: Bool) -> Ast.TopLevel:
  match top:
    case Ast.DefTop{definition}:
      match definition:
        case Ast.Definition{key, binders, result, body, _, source_span}:
          Ast.DefTop{Ast.Definition{key, binders, result, body, unsafe, source_span}}
    case _:
      top

def with_top_result(result: (Ast.TopLevel & List<&2, Lexer.Token>) & Bool, use: Ast.TopLevel -> List<&2, Lexer.Token> -> Bool -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((top, after), ok):
      use(top, after, ok)

def feedback_resume_Kont_339827(result: ((Ast.TopLevel & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_6(with_top_result(result, top => after => ok => ((mark_unsafe(top, True{}), after), ok)))

def feedback_resume_Kont_339962(result: ((Ast.TopLevel & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_6(with_top_result(result, top => after => _ => ((top, after), False{})))

def feedback_make_parse_type_constructor_fields_result(ok_fields: Bool, fields: List<&2, Ast.TelescopeItem>, after_fields: List<&2, Lexer.Token>, file: String, open: Lexer.Token, after_open: List<&2, Lexer.Token>, col: Nat, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.ConstructorDecl>, key: String, beg: Nat) -> FeedbackRequest:
  Request_parse_type_constructor_fields_result{ok_fields, fields, after_fields, file, open, after_open, col, scope, depth, acc, key, beg}

def feedback_consumer_342542(v_327: Pair(Pair(Pair(Pair(List<&2, Ast.TelescopeItem>, List<&2, Lexer.Token>), List<&2, Scope>), Nat), Bool), v_3: String, v_26: Lexer.Token, v_27: List<&2, Lexer.Token>, v_9: Nat, v_12: List<&2, Scope>, v_14: Nat, v_16: List<&2, Ast.ConstructorDecl>, v_18: String, v_20: Nat) -> FeedbackControl:
  match v_327:
    case ((((v_328, v_329), v_330), v_331), v_332):
      FeedbackControl{FeedbackCall{feedback_make_parse_type_constructor_fields_result(v_332, v_328, v_329, v_3, v_26, v_27, v_9, v_12, v_14, v_16, v_18, v_20)}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_resume_Kont_342579(lexical_capture_3: String, lexical_capture_26: Lexer.Token, lexical_capture_27: List<&2, Lexer.Token>, lexical_capture_9: Nat, lexical_capture_12: List<&2, Scope>, lexical_capture_14: Nat, lexical_capture_16: List<&2, Ast.ConstructorDecl>, lexical_capture_18: String, lexical_capture_20: Nat, result: ((((List<&2, Ast.TelescopeItem> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool)) -> FeedbackControl:
  feedback_consumer_342542(result, lexical_capture_3, lexical_capture_26, lexical_capture_27, lexical_capture_9, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_18, lexical_capture_20)

def parse_type_header_constructors_result(ok_constructors: Bool, constructors: List<&2, Ast.ConstructorDecl>, +after_constructors: List<&2, Lexer.Token>, file: String, key: String, beg: Nat, params: List<&2, Ast.TelescopeItem>, +kind: Ast.SyntaxTerm) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  declaration = { Ast.TypeDecl{key, params, kind, constructors, span(file, beg, token_end_of(after_constructors, token_end_first(kind)))} : Ast.TypeDecl }
  ((Ast.TypeTop{declaration}, after_constructors), ok_constructors)

def with_constructor_decls_result(result: (List<&2, Ast.ConstructorDecl> & List<&2, Lexer.Token>) & Bool, use: List<&2, Ast.ConstructorDecl> -> List<&2, Lexer.Token> -> Bool -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((constructors, after), ok):
      use(constructors, after, ok)

def feedback_resume_Kont_344635(lexical_capture_6: String, lexical_capture_8: String, lexical_capture_10: Nat, lexical_capture_14: List<&2, Ast.TelescopeItem>, lexical_capture_2: Ast.SyntaxTerm, result: ((List<&2, Ast.ConstructorDecl> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_6(with_constructor_decls_result(result, constructors => after_constructors => ok_constructors => parse_type_header_constructors_result(ok_constructors, constructors, after_constructors, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_14, lexical_capture_2)))

def feedback_make_Kont_344635(lexical_capture_6: String, lexical_capture_8: String, lexical_capture_10: Nat, lexical_capture_14: List<&2, Ast.TelescopeItem>, lexical_capture_2: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_344635{lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_14, lexical_capture_2}

def step_parse_type_constructors(file: String, +tokens: List<&2, Lexer.Token>, col: Nat, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.ConstructorDecl>) -> FeedbackControl:
  step_parse_type_constructors_scan(file, tokens, skip_lines(tokens), col, scope, depth, acc)

def step_parse_type_header_kind_result(ok_kind: Bool, +kind: Ast.SyntaxTerm, +after_kind: List<&2, Lexer.Token>, +file: String, +key: String, +beg: Nat, col: Nat, params: List<&2, Ast.TelescopeItem>, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match ok_kind after_kind:
    case True{} +colon <> after_colon:
      match colon:
        case Lexer.TokenInfo{ _, ":", _, _, _, _}:
          feedback_attach(step_parse_type_constructors(file, after_colon, col, scope, depth, Nil{}), feedback_make_Kont_344635(file, key, beg, params, kind))
        case Lexer.TokenInfo{feedback_field_6_0, feedback_field_6_1, feedback_field_6_2, feedback_field_6_3, feedback_field_6_4, feedback_field_6_5}:
          feedback_pack_6(type_failure(file, key, beg, token_beg((Lexer.TokenInfo{feedback_field_6_0, feedback_field_6_1, feedback_field_6_2, feedback_field_6_3, feedback_field_6_4, feedback_field_6_5} : Lexer.Token)), after_kind))
    case _ _:
      feedback_pack_6(type_failure(file, key, beg, token_end_first(kind), after_kind))

def feedback_consumer_345453(v_328: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_3: String, v_5: Nat, v_7: Nat, v_9: List<&2, Ast.TelescopeItem>, v_11: List<&2, Lexer.Token>, v_16: List<&2, Scope>, v_18: Nat) -> FeedbackControl:
  match v_328:
    case ((v_329, v_330), v_331):
      step_parse_type_header_kind_result(v_331, v_329, v_330, v_1, v_3, v_5, v_7, v_9, v_11, v_16, v_18)

def feedback_resume_Kont_345467(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: List<&2, Ast.TelescopeItem>, lexical_capture_11: List<&2, Lexer.Token>, lexical_capture_16: List<&2, Scope>, lexical_capture_18: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_345453(result, lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_16, lexical_capture_18)

def step_parse_type_params_result(ok_params: Bool, params: List<&2, Ast.TelescopeItem>, +after_params: List<&2, Lexer.Token>, open: Lexer.Token, +file: String, +key: String, +beg: Nat, col: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match ok_params:
    case True{}:
      step_parse_type_header(file, key, beg, col, params, after_params, scope, depth)
    case False{}:
      feedback_pack_6(type_failure(file, key, beg, token_end(open), after_params))

def feedback_consumer_347044(v_330: Pair(Pair(Pair(Pair(List<&2, Ast.TelescopeItem>, List<&2, Lexer.Token>), List<&2, Scope>), Nat), Bool), v_26: Lexer.Token, v_1: String, v_19: String, v_5: Nat, v_7: Nat) -> FeedbackControl:
  match v_330:
    case ((((v_331, v_332), v_333), v_334), v_335):
      step_parse_type_params_result(v_335, v_331, v_332, v_26, v_1, v_19, v_5, v_7, v_333, v_334)

def feedback_resume_Kont_347068(lexical_capture_26: Lexer.Token, lexical_capture_1: String, lexical_capture_19: String, lexical_capture_5: Nat, lexical_capture_7: Nat, result: ((((List<&2, Ast.TelescopeItem> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool)) -> FeedbackControl:
  feedback_consumer_347044(result, lexical_capture_26, lexical_capture_1, lexical_capture_19, lexical_capture_5, lexical_capture_7)

def feedback_consumer_347510(v_329: Pair(Pair(Pair(Pair(List<&2, Ast.TelescopeItem>, List<&2, Lexer.Token>), List<&2, Scope>), Nat), Bool), v_26: Lexer.Token, v_1: String, v_19: String, v_5: Nat, v_7: Nat) -> FeedbackControl:
  match v_329:
    case ((((v_330, v_331), v_332), v_333), v_334):
      step_parse_type_params_result(v_334, v_330, v_331, v_26, v_1, v_19, v_5, v_7, v_332, v_333)

def feedback_resume_Kont_347534(lexical_capture_26: Lexer.Token, lexical_capture_1: String, lexical_capture_19: String, lexical_capture_5: Nat, lexical_capture_7: Nat, result: ((((List<&2, Ast.TelescopeItem> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool)) -> FeedbackControl:
  feedback_consumer_347510(result, lexical_capture_26, lexical_capture_1, lexical_capture_19, lexical_capture_5, lexical_capture_7)

def parse_law_body_result(ok_body: Bool, +body: Ast.SyntaxTerm, after_body: List<&2, Lexer.Token>, file: String, key: String, clauses: List<&2, Ast.Clause>, beg: Nat, colon: Lexer.Token, after_clauses: List<&2, Lexer.Token>) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      declaration = { Ast.LawDecl{key, clauses, body, span(file, beg, token_end_first(body))} : Ast.LawDecl }
      ((Ast.LawTop{declaration}, after_body), True{})
    case False{}:
      law_failure(file, key, beg, token_end(colon), after_clauses)

def with_term_top(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, use: Ast.SyntaxTerm -> List<&2, Lexer.Token> -> Bool -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((term, after), ok):
      use(term, after, ok)

def feedback_resume_Kont_349565(lexical_capture_12: String, lexical_capture_14: String, lexical_capture_3: List<&2, Ast.Clause>, lexical_capture_16: Nat, lexical_capture_17: Lexer.Token, lexical_capture_5: List<&2, Lexer.Token>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_6(with_term_top(result, body => after_body => ok_body => parse_law_body_result(ok_body, body, after_body, lexical_capture_12, lexical_capture_14, lexical_capture_3, lexical_capture_16, lexical_capture_17, lexical_capture_5)))

def feedback_make_parse_law_clause_condition_scan(file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, beg: Nat, universal: Bool, quantity: Ast.Quantity, key: String, key_beg: Nat, key_end: Nat, ty: Ast.SyntaxTerm, next_scope: List<&2, Scope>, next_depth: Nat, acc: List<&2, Ast.Clause>) -> FeedbackRequest:
  Request_parse_law_clause_condition_scan{file, tokens, scanned, beg, universal, quantity, key, key_beg, key_end, ty, next_scope, next_depth, acc}

def step_parse_law_clause_condition(file: String, +tokens: List<&2, Lexer.Token>, beg: Nat, universal: Bool, quantity: Ast.Quantity, key: String, key_beg: Nat, key_end: Nat, ty: Ast.SyntaxTerm, next_scope: List<&2, Scope>, next_depth: Nat, acc: List<&2, Ast.Clause>) -> FeedbackControl:
  FeedbackControl{FeedbackCall{feedback_make_parse_law_clause_condition_scan(file, tokens, skip_lines(tokens), beg, universal, quantity, key, key_beg, key_end, ty, next_scope, next_depth, acc)}, Nil{}, NoProgress{}, NoProgress{}}

def step_parse_law_clause_type_result(ok_ty: Bool, ty: Ast.SyntaxTerm, +after_ty: List<&2, Lexer.Token>, file: String, +key: String, key_beg: Nat, key_end: Nat, beg: Nat, universal: Bool, quantity: Ast.Quantity, +scope: List<&2, Scope>, +depth: Nat, +acc: List<&2, Ast.Clause>) -> FeedbackControl:
  match ok_ty:
    case True{}:
      index = depth
      next_scope = extend_scope(key, index, scope)
      step_parse_law_clause_condition(file, after_ty, beg, universal, quantity, key, key_beg, key_end, ty, next_scope, (depth + 1n : Nat), acc)
    case False{}:
      feedback_pack_0(((((List.reverse(&2, Ast.Clause, acc), after_ty), scope), depth), False{}))

def feedback_consumer_353491(v_331: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_31: String, v_32: Nat, v_33: Nat, v_5: Nat, v_7: Bool, v_8: Ast.Quantity, v_11: List<&2, Scope>, v_13: Nat, v_15: List<&2, Ast.Clause>) -> FeedbackControl:
  match v_331:
    case ((v_332, v_333), v_334):
      step_parse_law_clause_type_result(v_334, v_332, v_333, v_1, v_31, v_32, v_33, v_5, v_7, v_8, v_11, v_13, v_15)

def feedback_resume_Kont_353513(lexical_capture_1: String, lexical_capture_31: String, lexical_capture_32: Nat, lexical_capture_33: Nat, lexical_capture_5: Nat, lexical_capture_7: Bool, lexical_capture_8: Ast.Quantity, lexical_capture_11: List<&2, Scope>, lexical_capture_13: Nat, lexical_capture_15: List<&2, Ast.Clause>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_353491(result, lexical_capture_1, lexical_capture_31, lexical_capture_32, lexical_capture_33, lexical_capture_5, lexical_capture_7, lexical_capture_8, lexical_capture_11, lexical_capture_13, lexical_capture_15)

def step_parse_law_clause_condition_result(ok_condition: Bool, +condition: Ast.SyntaxTerm, +after_condition: List<&2, Lexer.Token>, +file: String, beg: Nat, universal: Bool, quantity: Ast.Quantity, key: String, key_beg: Nat, ty: Ast.SyntaxTerm, +next_scope: List<&2, Scope>, +next_depth: Nat, +acc: List<&2, Ast.Clause>) -> FeedbackControl:
  match ok_condition:
    case True{}:
      clause = { Ast.ClauseFor{universal, quantity, key, ty, Some{condition}, span(file, key_beg, token_end_first(condition))} : Ast.Clause }
      step_parse_law_clauses(file, after_condition, next_scope, next_depth, clause <> acc)
    case False{}:
      feedback_pack_0(((((List.reverse(&2, Ast.Clause, acc), after_condition), next_scope), next_depth), False{}))

def feedback_consumer_355457(v_332: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_7: Nat, v_9: Bool, v_10: Ast.Quantity, v_12: String, v_14: Nat, v_17: Ast.SyntaxTerm, v_20: List<&2, Scope>, v_22: Nat, v_24: List<&2, Ast.Clause>) -> FeedbackControl:
  match v_332:
    case ((v_333, v_334), v_335):
      step_parse_law_clause_condition_result(v_335, v_333, v_334, v_1, v_7, v_9, v_10, v_12, v_14, v_17, v_20, v_22, v_24)

def feedback_resume_Kont_355479(lexical_capture_1: String, lexical_capture_7: Nat, lexical_capture_9: Bool, lexical_capture_10: Ast.Quantity, lexical_capture_12: String, lexical_capture_14: Nat, lexical_capture_17: Ast.SyntaxTerm, lexical_capture_20: List<&2, Scope>, lexical_capture_22: Nat, lexical_capture_24: List<&2, Ast.Clause>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_355457(result, lexical_capture_1, lexical_capture_7, lexical_capture_9, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_17, lexical_capture_20, lexical_capture_22, lexical_capture_24)

def feedback_make_Kont_349565(lexical_capture_12: String, lexical_capture_14: String, lexical_capture_3: List<&2, Ast.Clause>, lexical_capture_16: Nat, lexical_capture_17: Lexer.Token, lexical_capture_5: List<&2, Lexer.Token>) -> FeedbackFrame:
  Kont_349565{lexical_capture_12, lexical_capture_14, lexical_capture_3, lexical_capture_16, lexical_capture_17, lexical_capture_5}

def step_parse_law_clauses_result(ok_clauses: Bool, clauses: List<&2, Ast.Clause>, +after_clauses: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, +file: String, +key: String, +beg: Nat, +colon: Lexer.Token, after_colon: List<&2, Lexer.Token>) -> FeedbackControl:
  match ok_clauses:
    case True{}:
      feedback_attach(step_parse_body(file, after_clauses, scope, depth, 0n), feedback_make_Kont_349565(file, key, clauses, beg, colon, after_clauses))
    case False{}:
      feedback_pack_6(law_failure(file, key, beg, token_end(colon), after_colon))

def feedback_consumer_357761(v_333: Pair(Pair(Pair(Pair(List<&2, Ast.Clause>, List<&2, Lexer.Token>), List<&2, Scope>), Nat), Bool), v_1: String, v_17: String, v_5: Nat, v_24: Lexer.Token, v_25: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_333:
    case ((((v_334, v_335), v_336), v_337), v_338):
      step_parse_law_clauses_result(v_338, v_334, v_335, v_336, v_337, v_1, v_17, v_5, v_24, v_25)

def feedback_resume_Kont_357785(lexical_capture_1: String, lexical_capture_17: String, lexical_capture_5: Nat, lexical_capture_24: Lexer.Token, lexical_capture_25: List<&2, Lexer.Token>, result: ((((List<&2, Ast.Clause> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool)) -> FeedbackControl:
  feedback_consumer_357761(result, lexical_capture_1, lexical_capture_17, lexical_capture_5, lexical_capture_24, lexical_capture_25)

def feedback_make_parse_top_result(validation: Map<&2, TopOwner> & Bool, top: Ast.TopLevel, after: List<&2, Lexer.Token>, tokens: List<&2, Lexer.Token>, file: String, path: String, acc: List<&2, Ast.TopLevel>) -> FeedbackRequest:
  match validation:
    case (validation_0, validation_1):
      Request_parse_top_result{validation_0, validation_1, top, after, tokens, file, path, acc}

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
        case TopOwnerLaw{}:
          law_header_bare(header)
        case _:
          False{}
    case Ast.DefTop{Ast.Definition{_, _, Ast.SomeTerm{_}, _, _, _}}:
      match owner:
        case TopOwnerNone{}:
          True{}
        case _:
          False{}
    case Ast.TypeTop{_}:
      match owner:
        case TopOwnerNone{}:
          True{}
        case _:
          False{}
    case Ast.LawTop{_}:
      match owner:
        case TopOwnerNone{}:
          True{}
        case _:
          False{}

def top_owner_checked_result(query: Map<&2, TopOwner> & TopOwner, top: Ast.TopLevel, ok: Bool, header: List<&2, Lexer.Token>) -> Map<&2, TopOwner> & Bool:
  match query:
    case (owners, owner):
      (owners, Bool.and(ok, top_owner_valid(top, owner, header)))

def top_owner_query(top: Ast.TopLevel, owners: Map<&2, TopOwner>) -> Map<&2, TopOwner> & TopOwner:
  match top:
    case Ast.DefTop{Ast.Definition{key, _, _, _, _, _}}:
      Map.get(TopOwner, TopOwnerNone{}, owners, key)
    case Ast.TypeTop{Ast.TypeDecl{key, _, _, _, _}}:
      Map.get(TopOwner, TopOwnerNone{}, owners, key)
    case Ast.LawTop{Ast.LawDecl{key, _, _, _}}:
      Map.get(TopOwner, TopOwnerNone{}, owners, key)

def feedback_consumer_362376(v_337: Pair(Pair(Ast.TopLevel, List<&2, Lexer.Token>), Bool), v_12: Map<&2, TopOwner>, v_19: List<&2, Lexer.Token>, v_3: List<&2, Lexer.Token>, v_1: String, v_7: String, v_9: List<&2, Ast.TopLevel>) -> FeedbackControl:
  match v_337:
    case ((+v_338, v_339), v_340):
      FeedbackControl{FeedbackCall{feedback_make_parse_top_result(top_owner_checked_result(top_owner_query(v_338, v_12), v_338, v_340, v_19), v_338, v_339, v_3, v_1, v_7, v_9)}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_resume_Kont_362397(lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>, result: ((Ast.TopLevel & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_362376(result, lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9)

def feedback_consumer_362666(v_336: Pair(Pair(Ast.TopLevel, List<&2, Lexer.Token>), Bool), v_12: Map<&2, TopOwner>, v_19: List<&2, Lexer.Token>, v_3: List<&2, Lexer.Token>, v_1: String, v_7: String, v_9: List<&2, Ast.TopLevel>) -> FeedbackControl:
  match v_336:
    case ((+v_337, v_338), v_339):
      FeedbackControl{FeedbackCall{feedback_make_parse_top_result(top_owner_checked_result(top_owner_query(v_337, v_12), v_337, v_339, v_19), v_337, v_338, v_3, v_1, v_7, v_9)}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_resume_Kont_362687(lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>, result: ((Ast.TopLevel & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_362666(result, lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9)

def feedback_consumer_362959(v_335: Pair(Pair(Ast.TopLevel, List<&2, Lexer.Token>), Bool), v_12: Map<&2, TopOwner>, v_19: List<&2, Lexer.Token>, v_3: List<&2, Lexer.Token>, v_1: String, v_7: String, v_9: List<&2, Ast.TopLevel>) -> FeedbackControl:
  match v_335:
    case ((+v_336, v_337), v_338):
      FeedbackControl{FeedbackCall{feedback_make_parse_top_result(top_owner_checked_result(top_owner_query(v_336, v_12), v_336, v_338, v_19), v_336, v_337, v_3, v_1, v_7, v_9)}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_resume_Kont_362980(lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>, result: ((Ast.TopLevel & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_362959(result, lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9)

def feedback_consumer_363250(v_334: Pair(Pair(Ast.TopLevel, List<&2, Lexer.Token>), Bool), v_12: Map<&2, TopOwner>, v_19: List<&2, Lexer.Token>, v_3: List<&2, Lexer.Token>, v_1: String, v_7: String, v_9: List<&2, Ast.TopLevel>) -> FeedbackControl:
  match v_334:
    case ((+v_335, v_336), v_337):
      FeedbackControl{FeedbackCall{feedback_make_parse_top_result(top_owner_checked_result(top_owner_query(v_335, v_12), v_335, v_337, v_19), v_335, v_336, v_3, v_1, v_7, v_9)}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_resume_Kont_363271(lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>, result: ((Ast.TopLevel & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_363250(result, lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9)

def feedback_pack_17(result: ParseResult) -> FeedbackControl:
  FeedbackControl{FeedbackDone{Value_17{result}}, Nil{}, NoProgress{}, NoProgress{}}

def error_span(file: String, tokens: List<&2, Lexer.Token>) -> Ast.SourceSpan:
  match tokens:
    case +token <> _:
      span(file, token_beg(token), token_end(token))
    case Nil{}:
      span(file, 0n, 0n)

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

def parse_module_declarations_result(ok: Bool, declarations: List<&2, Ast.TopLevel>, +rest: List<&2, Lexer.Token>, file: String, imports: List<&2, Ast.ModuleImport>) -> ParseResult:
  match ok:
    case True{}:
      ParseSuccess{ Ast.Module{ file, imports, declarations}}
    case False{}:
      ParseFailure{ "invalid or unsupported top-level syntax", "a supported declaration", observed(rest), error_span(file, rest)}

def with_top_declarations_result(result: (List<&2, Ast.TopLevel> & Bool) & List<&2, Lexer.Token>, use: List<&2, Ast.TopLevel> -> Bool -> List<&2, Lexer.Token> -> ParseResult) -> ParseResult:
  match result:
    case ((declarations, ok), rest):
      use(declarations, ok, rest)

def feedback_resume_Kont_365172(lexical_capture_7: String, lexical_capture_3: List<&2, Ast.ModuleImport>, result: ((List<&2, Ast.TopLevel> & Bool) & List<&2, Lexer.Token>)) -> FeedbackControl:
  feedback_pack_17(with_top_declarations_result(result, declarations => ok => rest => parse_module_declarations_result(ok, declarations, rest, lexical_capture_7, lexical_capture_3)))

def feedback_make_Kont_365172(lexical_capture_7: String, lexical_capture_3: List<&2, Ast.ModuleImport>) -> FeedbackFrame:
  Kont_365172{lexical_capture_7, lexical_capture_3}

def top_owners_seed(acc: List<&2, Ast.TopLevel>, owners: Map<&2, TopOwner>) -> Map<&2, TopOwner>:
  match acc:
    case top <> rest:
      top_owner_set(top, top_owners_seed(rest, owners))
    case Nil{}:
      owners

def step_parse_top(file: String, +tokens: List<&2, Lexer.Token>, path: String, +acc: List<&2, Ast.TopLevel>) -> FeedbackControl:
  step_parse_top_scan(file, tokens, skip_lines(tokens), path, acc, top_owners_seed(acc, Map.new(&2, TopOwner)))

def step_parse_module_imports_result(imports_ok: Bool, imports: List<&2, Ast.ModuleImport>, +after_imports: List<&2, Lexer.Token>, +file: String) -> FeedbackControl:
  match imports_ok:
    case True{}:
      feedback_attach(step_parse_top(file, after_imports, file, Nil{}), feedback_make_Kont_365172(file, imports))
    case False{}:
      feedback_pack_17(ParseFailure{ "invalid module import", "import path with optional as-name", observed(after_imports), error_span(file, after_imports)})

def feedback_consumer_365605(v_338: Pair(Pair(List<&2, Ast.ModuleImport>, List<&2, Lexer.Token>), Bool), v_3: String) -> FeedbackControl:
  match v_338:
    case ((v_339, v_340), v_341):
      step_parse_module_imports_result(v_341, v_339, v_340, v_3)

def feedback_resume_Kont_365625(lexical_capture_3: String, result: ((List<&2, Ast.ModuleImport> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_365605(result, lexical_capture_3)

def nat_literal_tokens_sum_range(valid: Bool, sum: Nat) -> Maybe<&2, Nat>:
  match valid:
    case True{}:
      Some{sum}
    case False{}:
      None{}

def nat_literal_tokens_sum(found: Maybe<&2, Nat>, value: Nat) -> Maybe<&2, Nat>:
  match found:
    case Some{tail}:
      +sum = Nat.add(value, tail)
      nat_literal_tokens_sum_range(Nat.is_le(sum, 4294967295n), sum)
    case None{}:
      None{}

def feedback_resume_Kont_80664(capture_1: Nat, result: Maybe<&2, Nat>) -> FeedbackControl:
  feedback_pack_15(nat_literal_tokens_sum(result, capture_1))

def nat_succ_prefix(+file: String, count: Nat, term: Ast.SyntaxTerm, +beg: Nat, +end: Nat) -> Ast.SyntaxTerm:
  match count:
    case 0n:
      term
    case 1n+rest:
      Ast.TermCtr{ "Succ",  [nat_succ_prefix(file, rest, term, beg, end)],  span(file, beg, end)}

def parse_nat_literal_prefix(is_large: Bool, +file: String, value: Nat, +beg: Nat, end: Nat, +after_tail: List<&2, Lexer.Token>, +tail: Ast.SyntaxTerm) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match is_large:
    case True{}:
      +whole_end = token_end_of(after_tail, token_end_first(tail))
      base = nat_literal(file, value, beg, whole_end)
      +operator_span = span(file, beg, whole_end)
      ((Ast.TermApp{Ast.TermApp{Ast.TermRef{"Nat.add", operator_span}, base, operator_span}, tail, operator_span}, after_tail), True{})
    case False{}:
      ((nat_succ_prefix(file, value, tail, beg, token_end_of(after_tail, token_end_first(tail))), after_tail), True{})

def parse_nat_literal_fold_sum(found: Maybe<&2, Nat>, +file: String, +value: Nat, +beg: Nat, +end: Nat, +after_tail: List<&2, Lexer.Token>, +tail: Ast.SyntaxTerm) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match found:
    case Some{sum}:
      ((nat_literal(file, sum, beg, token_end_of(after_tail, token_end_first(tail))), after_tail), True{})
    case None{}:
      parse_nat_literal_prefix(Nat.is_lt(256n, value), file, value, beg, end, after_tail, tail)

def parse_nat_literal_fold(found: Maybe<&2, Nat>, +file: String, +value: Nat, +beg: Nat, +end: Nat, +after_tail: List<&2, Lexer.Token>, +tail: Ast.SyntaxTerm) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_nat_literal_fold_sum(nat_literal_tokens_sum(found, value), file, value, beg, end, after_tail, tail)

def feedback_resume_Kont_82236(capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Lexer.Token>, capture_6: Ast.SyntaxTerm, result: Maybe<&2, Nat>) -> FeedbackControl:
  feedback_pack_5(parse_nat_literal_fold(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6))

def evaluation_context_parse_name_constructor_result_85165(v_3: List<&2, Ast.SyntaxTerm>, +v_5: List<&2, Lexer.Token>, v_7: String, v_9: String, v_11: Nat, v_280: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermCtr{v_9, v_3, span(v_7, v_11, v_280)}, v_5), True{})

def feedback_resume_Kont_85539(capture_0: List<&2, Ast.SyntaxTerm>, capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: String, capture_4: Nat, result: Nat) -> FeedbackControl:
  feedback_pack_5(evaluation_context_parse_name_constructor_result_85165(capture_0, capture_1, capture_2, capture_3, capture_4, result))

def evaluation_context_map_operator_term_90422(v_173: Ast.SourceSpan, v_297: Ast.SyntaxTerm, v_318: Ast.SyntaxTerm, v_323: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  Ast.TermRewrite{v_297, v_318, v_323, v_173}

def feedback_resume_Kont_88585(capture_0: Ast.SourceSpan, capture_1: Ast.SyntaxTerm, capture_2: Ast.SyntaxTerm, result: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_pack_11(evaluation_context_map_operator_term_90422(capture_0, capture_1, capture_2, result))

def evaluation_context_map_operator_term_90146(v_160: Ast.SourceSpan, v_296: Ast.SyntaxTerm, v_317: Ast.SyntaxTerm, v_322: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  Ast.TermEqual{v_296, v_317, v_322, v_160}

def feedback_resume_Kont_88855(capture_0: Ast.SourceSpan, capture_1: Ast.SyntaxTerm, capture_2: Ast.SyntaxTerm, result: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_pack_11(evaluation_context_map_operator_term_90146(capture_0, capture_1, capture_2, result))

def evaluation_context_map_operator_term_90999(v_201: List<&2, Ast.SyntaxPattern>, v_202: Ast.Quantity, v_205: Ast.SourceSpan, v_300: List<&2, Ast.SyntaxTerm>, v_320: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  Ast.BodyLocal{v_201, v_202, v_300, v_320, v_205}

def feedback_resume_Kont_91075(capture_0: List<&2, Ast.SyntaxPattern>, capture_1: Ast.Quantity, capture_2: Ast.SourceSpan, capture_3: List<&2, Ast.SyntaxTerm>, result: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_pack_11(evaluation_context_map_operator_term_90999(capture_0, capture_1, capture_2, capture_3, result))

def evaluation_context_map_operator_term_90668(v_186: Ast.SourceSpan, v_298: List<&2, Ast.SyntaxTerm>, v_319: List<&2, Ast.SyntaxTerm>) -> Ast.SyntaxTerm:
  Ast.BodyMatch{v_298, v_319, v_186}

def feedback_resume_Kont_91520(capture_0: Ast.SourceSpan, capture_1: List<&2, Ast.SyntaxTerm>, result: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  feedback_pack_11(evaluation_context_map_operator_term_90668(capture_0, capture_1, result))

def feedback_make_Kont_88585(capture_0: Ast.SourceSpan, capture_1: Ast.SyntaxTerm, capture_2: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_88585{capture_0, capture_1, capture_2}

def step_evaluation_context_map_operator_term_90385(+v_2: String, v_172: Ast.SyntaxTerm, v_173: Ast.SourceSpan, v_297: Ast.SyntaxTerm, v_318: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_172, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_88585(v_173, v_297, v_318))

def feedback_resume_Kont_91796(capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: Ast.SourceSpan, capture_3: Ast.SyntaxTerm, result: Ast.SyntaxTerm) -> FeedbackControl:
  step_evaluation_context_map_operator_term_90385(capture_0, capture_1, capture_2, capture_3, result)

def feedback_make_Kont_88855(capture_0: Ast.SourceSpan, capture_1: Ast.SyntaxTerm, capture_2: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_88855{capture_0, capture_1, capture_2}

def step_evaluation_context_map_operator_term_90109(+v_2: String, v_159: Ast.SyntaxTerm, v_160: Ast.SourceSpan, v_296: Ast.SyntaxTerm, v_317: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_159, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_88855(v_160, v_296, v_317))

def feedback_resume_Kont_92071(capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: Ast.SourceSpan, capture_3: Ast.SyntaxTerm, result: Ast.SyntaxTerm) -> FeedbackControl:
  step_evaluation_context_map_operator_term_90109(capture_0, capture_1, capture_2, capture_3, result)

def evaluation_context_map_operator_term_89875(v_145: String, v_148: Ast.SourceSpan, v_295: Ast.SyntaxTerm, v_316: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  Ast.TermMat{v_145, v_295, v_316, v_148}

def feedback_resume_Kont_92333(capture_0: String, capture_1: Ast.SourceSpan, capture_2: Ast.SyntaxTerm, result: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_pack_11(evaluation_context_map_operator_term_89875(capture_0, capture_1, capture_2, result))

def evaluation_context_map_operator_term_89492(v_125: Ast.SourceSpan, v_293: Ast.SyntaxTerm, v_315: List<&2, Ast.SyntaxTerm>) -> Ast.SyntaxTerm:
  Ast.TermPlus{v_293, v_315, v_125}

def feedback_resume_Kont_92756(capture_0: Ast.SourceSpan, capture_1: Ast.SyntaxTerm, result: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  feedback_pack_11(evaluation_context_map_operator_term_89492(capture_0, capture_1, result))

def evaluation_context_map_operator_term_89339(v_117: Ast.SourceSpan, v_292: Ast.SyntaxTerm, v_314: List<&2, Ast.SyntaxTerm>) -> Ast.SyntaxTerm:
  Ast.TermFill{v_292, v_314, v_117}

def feedback_resume_Kont_93007(capture_0: Ast.SourceSpan, capture_1: Ast.SyntaxTerm, result: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  feedback_pack_11(evaluation_context_map_operator_term_89339(capture_0, capture_1, result))

def evaluation_context_map_operator_term_89057(v_100: Ast.SourceSpan, v_290: Ast.SyntaxTerm, v_313: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  Ast.TermApp{v_290, v_313, v_100}

def feedback_resume_Kont_93452(capture_0: Ast.SourceSpan, capture_1: Ast.SyntaxTerm, result: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_pack_11(evaluation_context_map_operator_term_89057(capture_0, capture_1, result))

def evaluation_context_map_operator_term_88760(v_76: Ast.Quantity, v_77: String, v_78: Nat, v_81: Ast.SourceSpan, v_288: Ast.SyntaxTerm, v_312: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  Ast.TermAll{v_76, v_77, v_78, v_288, v_312, v_81}

def feedback_resume_Kont_93964(capture_0: Ast.Quantity, capture_1: String, capture_2: Nat, capture_3: Ast.SourceSpan, capture_4: Ast.SyntaxTerm, result: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_pack_11(evaluation_context_map_operator_term_88760(capture_0, capture_1, capture_2, capture_3, capture_4, result))

def evaluation_context_map_operator_term_88569(v_67: Ast.SourceSpan, v_287: Ast.SyntaxTerm, v_311: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  Ast.TermMin{v_287, v_311, v_67}

def feedback_resume_Kont_94200(capture_0: Ast.SourceSpan, capture_1: Ast.SyntaxTerm, result: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_pack_11(evaluation_context_map_operator_term_88569(capture_0, capture_1, result))

def evaluation_context_map_operator_term_88048(v_46: Ast.SourceSpan, v_284: Ast.SyntaxTerm, v_310: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  Ast.TermAnn{v_284, v_310, v_46}

def feedback_resume_Kont_94720(capture_0: Ast.SourceSpan, capture_1: Ast.SyntaxTerm, result: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_pack_11(evaluation_context_map_operator_term_88048(capture_0, capture_1, result))

def evaluation_context_map_operator_term_87900(v_34: List<&2, String>, v_35: List<&2, Nat>, v_36: List<&2, Ast.Quantity>, v_39: Ast.SourceSpan, v_283: List<&2, Ast.SyntaxTerm>, v_309: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  Ast.TermLet{v_34, v_35, v_36, v_283, v_309, v_39}

def feedback_resume_Kont_95059(capture_0: List<&2, String>, capture_1: List<&2, Nat>, capture_2: List<&2, Ast.Quantity>, capture_3: Ast.SourceSpan, capture_4: List<&2, Ast.SyntaxTerm>, result: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_pack_11(evaluation_context_map_operator_term_87900(capture_0, capture_1, capture_2, capture_3, capture_4, result))

def evaluation_context_map_operator_term_87691(v_22: Nat, v_25: Ast.SourceSpan, v_282: Ast.SyntaxTerm, v_308: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  Ast.TermSub{v_22, v_282, v_308, v_25}

def feedback_resume_Kont_95312(capture_0: Nat, capture_1: Ast.SourceSpan, capture_2: Ast.SyntaxTerm, result: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_pack_11(evaluation_context_map_operator_term_87691(capture_0, capture_1, capture_2, result))

def evaluation_context_map_operator_term_87525(v_16: Ast.SourceSpan, v_281: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  Ast.TermBang{v_281, v_16}

def feedback_resume_Kont_95827(capture_0: Ast.SourceSpan, result: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_pack_11(evaluation_context_map_operator_term_87525(capture_0, result))

def feedback_make_Kont_95312(capture_0: Nat, capture_1: Ast.SourceSpan, capture_2: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_95312{capture_0, capture_1, capture_2}

def step_evaluation_context_map_operator_term_87654(+v_2: String, v_22: Nat, v_24: Ast.SyntaxTerm, v_25: Ast.SourceSpan, v_282: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_24, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_95312(v_22, v_25, v_282))

def feedback_resume_Kont_95975(capture_0: String, capture_1: Nat, capture_2: Ast.SyntaxTerm, capture_3: Ast.SourceSpan, result: Ast.SyntaxTerm) -> FeedbackControl:
  step_evaluation_context_map_operator_term_87654(capture_0, capture_1, capture_2, capture_3, result)

def feedback_make_Kont_95059(capture_0: List<&2, String>, capture_1: List<&2, Nat>, capture_2: List<&2, Ast.Quantity>, capture_3: Ast.SourceSpan, capture_4: List<&2, Ast.SyntaxTerm>) -> FeedbackFrame:
  Kont_95059{capture_0, capture_1, capture_2, capture_3, capture_4}

def step_evaluation_context_map_operator_term_87861(+v_2: String, v_34: List<&2, String>, v_35: List<&2, Nat>, v_36: List<&2, Ast.Quantity>, v_38: Ast.SyntaxTerm, v_39: Ast.SourceSpan, v_283: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_38, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_95059(v_34, v_35, v_36, v_39, v_283))

def feedback_resume_Kont_96147(capture_0: String, capture_1: List<&2, String>, capture_2: List<&2, Nat>, capture_3: List<&2, Ast.Quantity>, capture_4: Ast.SyntaxTerm, capture_5: Ast.SourceSpan, result: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  step_evaluation_context_map_operator_term_87861(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, result)

def feedback_make_Kont_94720(capture_0: Ast.SourceSpan, capture_1: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_94720{capture_0, capture_1}

def step_evaluation_context_map_operator_term_88012(+v_2: String, v_45: Ast.SyntaxTerm, v_46: Ast.SourceSpan, v_284: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_45, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_94720(v_46, v_284))

def feedback_resume_Kont_96284(capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: Ast.SourceSpan, result: Ast.SyntaxTerm) -> FeedbackControl:
  step_evaluation_context_map_operator_term_88012(capture_0, capture_1, capture_2, result)

def evaluation_context_map_operator_term_88164(v_51: Ast.SourceSpan, v_285: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  Ast.TermTemplate{v_285, v_51}

def feedback_resume_Kont_96408(capture_0: Ast.SourceSpan, result: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_pack_11(evaluation_context_map_operator_term_88164(capture_0, result))

def evaluation_context_map_operator_term_88274(v_56: Ast.SourceSpan, v_286: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  Ast.TermType{v_286, v_56}

def feedback_resume_Kont_96528(capture_0: Ast.SourceSpan, result: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_pack_11(evaluation_context_map_operator_term_88274(capture_0, result))

def feedback_make_Kont_94200(capture_0: Ast.SourceSpan, capture_1: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_94200{capture_0, capture_1}

def step_evaluation_context_map_operator_term_88533(+v_2: String, v_66: Ast.SyntaxTerm, v_67: Ast.SourceSpan, v_287: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_66, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_94200(v_67, v_287))

def feedback_resume_Kont_96786(capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: Ast.SourceSpan, result: Ast.SyntaxTerm) -> FeedbackControl:
  step_evaluation_context_map_operator_term_88533(capture_0, capture_1, capture_2, result)

def feedback_make_Kont_93964(capture_0: Ast.Quantity, capture_1: String, capture_2: Nat, capture_3: Ast.SourceSpan, capture_4: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_93964{capture_0, capture_1, capture_2, capture_3, capture_4}

def step_evaluation_context_map_operator_term_88726(+v_2: String, v_76: Ast.Quantity, v_77: String, v_78: Nat, v_80: Ast.SyntaxTerm, v_81: Ast.SourceSpan, v_288: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_80, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_93964(v_76, v_77, v_78, v_81, v_288))

def feedback_resume_Kont_96958(capture_0: String, capture_1: Ast.Quantity, capture_2: String, capture_3: Nat, capture_4: Ast.SyntaxTerm, capture_5: Ast.SourceSpan, result: Ast.SyntaxTerm) -> FeedbackControl:
  step_evaluation_context_map_operator_term_88726(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, result)

def evaluation_context_map_operator_term_88912(v_89: Maybe<&2, Ast.Quantity>, v_90: String, v_91: Nat, v_93: Ast.SourceSpan, v_289: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  Ast.TermLam{v_89, v_90, v_91, v_289, v_93}

def feedback_resume_Kont_97113(capture_0: Maybe<&2, Ast.Quantity>, capture_1: String, capture_2: Nat, capture_3: Ast.SourceSpan, result: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_pack_11(evaluation_context_map_operator_term_88912(capture_0, capture_1, capture_2, capture_3, result))

def feedback_make_Kont_93452(capture_0: Ast.SourceSpan, capture_1: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_93452{capture_0, capture_1}

def step_evaluation_context_map_operator_term_89023(+v_2: String, v_99: Ast.SyntaxTerm, v_100: Ast.SourceSpan, v_290: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_99, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_93452(v_100, v_290))

def feedback_resume_Kont_97251(capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: Ast.SourceSpan, result: Ast.SyntaxTerm) -> FeedbackControl:
  step_evaluation_context_map_operator_term_89023(capture_0, capture_1, capture_2, result)

def evaluation_context_map_operator_term_89180(v_107: String, v_109: List<&2, String>, v_110: Ast.SourceSpan, v_291: List<&2, Ast.SyntaxTerm>) -> Ast.SyntaxTerm:
  Ast.TermAdt{v_107, v_291, v_109, v_110}

def feedback_resume_Kont_97401(capture_0: String, capture_1: List<&2, String>, capture_2: Ast.SourceSpan, result: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  feedback_pack_11(evaluation_context_map_operator_term_89180(capture_0, capture_1, capture_2, result))

def feedback_make_Kont_93007(capture_0: Ast.SourceSpan, capture_1: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_93007{capture_0, capture_1}

def step_evaluation_context_map_operator_term_89303(+v_2: String, v_116: List<&2, Ast.SyntaxTerm>, v_117: Ast.SourceSpan, v_292: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_terms(v_116, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_93007(v_117, v_292))

def feedback_resume_Kont_97545(capture_0: String, capture_1: List<&2, Ast.SyntaxTerm>, capture_2: Ast.SourceSpan, result: Ast.SyntaxTerm) -> FeedbackControl:
  step_evaluation_context_map_operator_term_89303(capture_0, capture_1, capture_2, result)

def feedback_make_Kont_92756(capture_0: Ast.SourceSpan, capture_1: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_92756{capture_0, capture_1}

def step_evaluation_context_map_operator_term_89456(+v_2: String, v_124: List<&2, Ast.SyntaxTerm>, v_125: Ast.SourceSpan, v_293: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_terms(v_124, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_92756(v_125, v_293))

def feedback_resume_Kont_97688(capture_0: String, capture_1: List<&2, Ast.SyntaxTerm>, capture_2: Ast.SourceSpan, result: Ast.SyntaxTerm) -> FeedbackControl:
  step_evaluation_context_map_operator_term_89456(capture_0, capture_1, capture_2, result)

def evaluation_context_map_operator_term_89611(v_131: String, v_133: Ast.SourceSpan, v_294: List<&2, Ast.SyntaxTerm>) -> Ast.SyntaxTerm:
  Ast.TermCtr{v_131, v_294, v_133}

def feedback_resume_Kont_97825(capture_0: String, capture_1: Ast.SourceSpan, result: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  feedback_pack_11(evaluation_context_map_operator_term_89611(capture_0, capture_1, result))

def feedback_make_Kont_92333(capture_0: String, capture_1: Ast.SourceSpan, capture_2: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_92333{capture_0, capture_1, capture_2}

def step_evaluation_context_map_operator_term_89839(+v_2: String, v_145: String, v_147: Ast.SyntaxTerm, v_148: Ast.SourceSpan, v_295: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_147, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_92333(v_145, v_148, v_295))

def feedback_resume_Kont_98070(capture_0: String, capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Ast.SourceSpan, result: Ast.SyntaxTerm) -> FeedbackControl:
  step_evaluation_context_map_operator_term_89839(capture_0, capture_1, capture_2, capture_3, result)

def feedback_make_Kont_92071(capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: Ast.SourceSpan, capture_3: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_92071{capture_0, capture_1, capture_2, capture_3}

def step_evaluation_context_map_operator_term_90073(+v_2: String, v_158: Ast.SyntaxTerm, v_159: Ast.SyntaxTerm, v_160: Ast.SourceSpan, v_296: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_158, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_92071(v_2, v_159, v_160, v_296))

def feedback_resume_Kont_98288(capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: Ast.SyntaxTerm, capture_3: Ast.SourceSpan, result: Ast.SyntaxTerm) -> FeedbackControl:
  step_evaluation_context_map_operator_term_90073(capture_0, capture_1, capture_2, capture_3, result)

def feedback_make_Kont_91796(capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: Ast.SourceSpan, capture_3: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_91796{capture_0, capture_1, capture_2, capture_3}

def step_evaluation_context_map_operator_term_90345(+v_2: String, v_171: Ast.SyntaxTerm, v_172: Ast.SyntaxTerm, v_173: Ast.SourceSpan, v_297: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_171, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_91796(v_2, v_172, v_173, v_297))

def feedback_resume_Kont_98504(capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: Ast.SyntaxTerm, capture_3: Ast.SourceSpan, result: Ast.SyntaxTerm) -> FeedbackControl:
  step_evaluation_context_map_operator_term_90345(capture_0, capture_1, capture_2, capture_3, result)

def feedback_make_Kont_91520(capture_0: Ast.SourceSpan, capture_1: List<&2, Ast.SyntaxTerm>) -> FeedbackFrame:
  Kont_91520{capture_0, capture_1}

def step_evaluation_context_map_operator_term_90625(+v_2: String, v_185: List<&2, Ast.SyntaxTerm>, v_186: Ast.SourceSpan, v_298: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_terms(v_185, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_91520(v_186, v_298))

def feedback_resume_Kont_98718(capture_0: String, capture_1: List<&2, Ast.SyntaxTerm>, capture_2: Ast.SourceSpan, result: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  step_evaluation_context_map_operator_term_90625(capture_0, capture_1, capture_2, result)

def evaluation_context_map_operator_term_90800(v_192: List<&2, Ast.SyntaxPattern>, v_194: Ast.SourceSpan, v_299: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  Ast.BodyCase{v_192, v_299, v_194}

def feedback_resume_Kont_98857(capture_0: List<&2, Ast.SyntaxPattern>, capture_1: Ast.SourceSpan, result: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_pack_11(evaluation_context_map_operator_term_90800(capture_0, capture_1, result))

def feedback_make_Kont_91075(capture_0: List<&2, Ast.SyntaxPattern>, capture_1: Ast.Quantity, capture_2: Ast.SourceSpan, capture_3: List<&2, Ast.SyntaxTerm>) -> FeedbackFrame:
  Kont_91075{capture_0, capture_1, capture_2, capture_3}

def step_evaluation_context_map_operator_term_90960(+v_2: String, v_201: List<&2, Ast.SyntaxPattern>, v_202: Ast.Quantity, v_204: Ast.SyntaxTerm, v_205: Ast.SourceSpan, v_300: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_204, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_91075(v_201, v_202, v_205, v_300))

def feedback_resume_Kont_99029(capture_0: String, capture_1: List<&2, Ast.SyntaxPattern>, capture_2: Ast.Quantity, capture_3: Ast.SyntaxTerm, capture_4: Ast.SourceSpan, result: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  step_evaluation_context_map_operator_term_90960(capture_0, capture_1, capture_2, capture_3, capture_4, result)

def evaluation_context_map_operator_term_91111(v_210: Ast.SourceSpan, v_301: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  Ast.BodyReply{v_301, v_210}

def feedback_resume_Kont_99155(capture_0: Ast.SourceSpan, result: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_pack_11(evaluation_context_map_operator_term_91111(capture_0, result))

def evaluation_context_map_operator_terms_91376(v_302: Ast.SyntaxTerm, v_321: List<&2, Ast.SyntaxTerm>) -> List<&2, Ast.SyntaxTerm>:
  v_302 <> v_321

def feedback_resume_Kont_99536(capture_0: Ast.SyntaxTerm, result: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  feedback_pack_12(evaluation_context_map_operator_terms_91376(capture_0, result))

def feedback_make_Kont_99536(capture_0: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_99536{capture_0}

def step_evaluation_context_map_operator_terms_91338(+v_3: String, v_8: List<&2, Ast.SyntaxTerm>, v_302: Ast.SyntaxTerm) -> FeedbackControl:
  feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_terms(v_8, v_3)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_99536(v_302))

def feedback_resume_Kont_99780(capture_0: String, capture_1: List<&2, Ast.SyntaxTerm>, result: Ast.SyntaxTerm) -> FeedbackControl:
  step_evaluation_context_map_operator_terms_91338(capture_0, capture_1, result)

def feedback_resume_frame(frame: FeedbackFrame, value: FeedbackValue) -> FeedbackControl:
  match frame:
    case KontProgress{}: FeedbackControl{FeedbackDone{value}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_80664{capture_1}:
      match value:
        case Value_15{result}:
          feedback_resume_Kont_80664(capture_1, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_82236{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6}:
      match value:
        case Value_15{result}:
          feedback_resume_Kont_82236(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_85539{capture_0, capture_1, capture_2, capture_3, capture_4}:
      match value:
        case Value_16{result}:
          feedback_resume_Kont_85539(capture_0, capture_1, capture_2, capture_3, capture_4, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_88585{capture_0, capture_1, capture_2}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_88585(capture_0, capture_1, capture_2, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_88855{capture_0, capture_1, capture_2}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_88855(capture_0, capture_1, capture_2, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_91075{capture_0, capture_1, capture_2, capture_3}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_91075(capture_0, capture_1, capture_2, capture_3, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_91520{capture_0, capture_1}:
      match value:
        case Value_12{result}:
          feedback_resume_Kont_91520(capture_0, capture_1, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_91796{capture_0, capture_1, capture_2, capture_3}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_91796(capture_0, capture_1, capture_2, capture_3, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_92071{capture_0, capture_1, capture_2, capture_3}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_92071(capture_0, capture_1, capture_2, capture_3, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_92333{capture_0, capture_1, capture_2}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_92333(capture_0, capture_1, capture_2, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_92756{capture_0, capture_1}:
      match value:
        case Value_12{result}:
          feedback_resume_Kont_92756(capture_0, capture_1, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_93007{capture_0, capture_1}:
      match value:
        case Value_12{result}:
          feedback_resume_Kont_93007(capture_0, capture_1, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_93452{capture_0, capture_1}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_93452(capture_0, capture_1, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_93964{capture_0, capture_1, capture_2, capture_3, capture_4}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_93964(capture_0, capture_1, capture_2, capture_3, capture_4, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_94200{capture_0, capture_1}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_94200(capture_0, capture_1, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_94720{capture_0, capture_1}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_94720(capture_0, capture_1, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_95059{capture_0, capture_1, capture_2, capture_3, capture_4}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_95059(capture_0, capture_1, capture_2, capture_3, capture_4, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_95312{capture_0, capture_1, capture_2}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_95312(capture_0, capture_1, capture_2, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_99155{capture_0}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_99155(capture_0, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_99029{capture_0, capture_1, capture_2, capture_3, capture_4}:
      match value:
        case Value_12{result}:
          feedback_resume_Kont_99029(capture_0, capture_1, capture_2, capture_3, capture_4, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_98857{capture_0, capture_1}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_98857(capture_0, capture_1, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_98718{capture_0, capture_1, capture_2}:
      match value:
        case Value_12{result}:
          feedback_resume_Kont_98718(capture_0, capture_1, capture_2, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_98504{capture_0, capture_1, capture_2, capture_3}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_98504(capture_0, capture_1, capture_2, capture_3, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_98288{capture_0, capture_1, capture_2, capture_3}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_98288(capture_0, capture_1, capture_2, capture_3, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_98070{capture_0, capture_1, capture_2, capture_3}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_98070(capture_0, capture_1, capture_2, capture_3, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_97825{capture_0, capture_1}:
      match value:
        case Value_12{result}:
          feedback_resume_Kont_97825(capture_0, capture_1, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_97688{capture_0, capture_1, capture_2}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_97688(capture_0, capture_1, capture_2, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_97545{capture_0, capture_1, capture_2}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_97545(capture_0, capture_1, capture_2, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_97401{capture_0, capture_1, capture_2}:
      match value:
        case Value_12{result}:
          feedback_resume_Kont_97401(capture_0, capture_1, capture_2, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_97251{capture_0, capture_1, capture_2}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_97251(capture_0, capture_1, capture_2, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_97113{capture_0, capture_1, capture_2, capture_3}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_97113(capture_0, capture_1, capture_2, capture_3, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_96958{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_96958(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_96786{capture_0, capture_1, capture_2}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_96786(capture_0, capture_1, capture_2, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_96528{capture_0}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_96528(capture_0, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_96408{capture_0}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_96408(capture_0, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_96284{capture_0, capture_1, capture_2}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_96284(capture_0, capture_1, capture_2, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_96147{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5}:
      match value:
        case Value_12{result}:
          feedback_resume_Kont_96147(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_95975{capture_0, capture_1, capture_2, capture_3}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_95975(capture_0, capture_1, capture_2, capture_3, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_95827{capture_0}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_95827(capture_0, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_99536{capture_0}:
      match value:
        case Value_12{result}:
          feedback_resume_Kont_99536(capture_0, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_99780{capture_0, capture_1}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_99780(capture_0, capture_1, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_104727{capture_0}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_104727(capture_0, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_130860{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8}:
      match value:
        case Value_4{result_0_0, result_0_1, result_1_0_0, result_1_0_1, result_1_1}:
          feedback_resume_Kont_130860(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, ((result_0_0, result_0_1), ((result_1_0_0, result_1_0_1), result_1_1)))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_136149{capture_1}:
      match value:
        case Value_14{result}:
          feedback_resume_Kont_136149(capture_1, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_136385{capture_1}:
      match value:
        case Value_13{result}:
          feedback_resume_Kont_136385(capture_1, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_136894{capture_1, capture_2}:
      match value:
        case Value_14{result}:
          feedback_resume_Kont_136894(capture_1, capture_2, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_138041{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8}:
      match value:
        case Value_13{result}:
          feedback_resume_Kont_138041(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_139772{capture_1, capture_2, capture_3}:
      match value:
        case Value_4{result_0_0, result_0_1, result_1_0_0, result_1_0_1, result_1_1}:
          feedback_resume_Kont_139772(capture_1, capture_2, capture_3, ((result_0_0, result_0_1), ((result_1_0_0, result_1_0_1), result_1_1)))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_140603{capture_1, capture_2}:
      match value:
        case Value_4{result_0_0, result_0_1, result_1_0_0, result_1_0_1, result_1_1}:
          feedback_resume_Kont_140603(capture_1, capture_2, ((result_0_0, result_0_1), ((result_1_0_0, result_1_0_1), result_1_1)))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_143942{capture_1, capture_2, capture_3, capture_4, capture_5}:
      match value:
        case Value_4{result_0_0, result_0_1, result_1_0_0, result_1_0_1, result_1_1}:
          feedback_resume_Kont_143942(capture_1, capture_2, capture_3, capture_4, capture_5, ((result_0_0, result_0_1), ((result_1_0_0, result_1_0_1), result_1_1)))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_149840{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6}:
      match value:
        case Value_4{result_0_0, result_0_1, result_1_0_0, result_1_0_1, result_1_1}:
          feedback_resume_Kont_149840(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, ((result_0_0, result_0_1), ((result_1_0_0, result_1_0_1), result_1_1)))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_171398{capture_1, capture_2}:
      match value:
        case Value_18{result}:
          feedback_resume_Kont_171398(capture_1, capture_2, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_180552{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7}:
      match value:
        case Value_9{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_180552(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_182168{capture_1, capture_2, capture_3, capture_4}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_182168(capture_1, capture_2, capture_3, capture_4, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_188249{capture_1, capture_2}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_188249(capture_1, capture_2, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_188761{capture_1, capture_2, capture_3, capture_4, capture_5}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_188761(capture_1, capture_2, capture_3, capture_4, capture_5, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_190088{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10, capture_11, capture_12}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_190088(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10, capture_11, capture_12, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_193205{lexical_capture_4, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_13, lexical_capture_31, lexical_capture_15, lexical_capture_17, lexical_capture_22, lexical_capture_26}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_193205(lexical_capture_4, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_13, lexical_capture_31, lexical_capture_15, lexical_capture_17, lexical_capture_22, lexical_capture_26, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_194307{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_194307(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_195319{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_27, lexical_capture_28, lexical_capture_9, lexical_capture_11, lexical_capture_14, lexical_capture_16, lexical_capture_18}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_195319(lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_27, lexical_capture_28, lexical_capture_9, lexical_capture_11, lexical_capture_14, lexical_capture_16, lexical_capture_18, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_196508{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10, capture_11, capture_12}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_196508(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10, capture_11, capture_12, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_196192{lexical_capture_2, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_18, lexical_capture_21, lexical_capture_23, lexical_capture_25}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_196192(lexical_capture_2, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_18, lexical_capture_21, lexical_capture_23, lexical_capture_25, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_197434{lexical_capture_7, lexical_capture_13, lexical_capture_15, lexical_capture_24, lexical_capture_2, lexical_capture_3}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_197434(lexical_capture_7, lexical_capture_13, lexical_capture_15, lexical_capture_24, lexical_capture_2, lexical_capture_3, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_199099{lexical_capture_4, lexical_capture_10, lexical_capture_12, lexical_capture_22, lexical_capture_13, lexical_capture_29}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_199099(lexical_capture_4, lexical_capture_10, lexical_capture_12, lexical_capture_22, lexical_capture_13, lexical_capture_29, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_199750{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10, capture_11}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_199750(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10, capture_11, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_201815{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_201815(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_202383{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_202383(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_203745{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_6, lexical_capture_7, lexical_capture_11, lexical_capture_13, lexical_capture_18}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_203745(lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_6, lexical_capture_7, lexical_capture_11, lexical_capture_13, lexical_capture_18, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_206710{capture_1, capture_2, capture_3, capture_4, capture_5}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_206710(capture_1, capture_2, capture_3, capture_4, capture_5, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_207865{capture_1, capture_2, capture_3, capture_4, capture_5}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_207865(capture_1, capture_2, capture_3, capture_4, capture_5, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_209050{lexical_capture_4, lexical_capture_5, lexical_capture_7}:
      match value:
        case Value_9{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_209050(lexical_capture_4, lexical_capture_5, lexical_capture_7, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_209742{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_209742(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_210467{capture_1, capture_2, capture_3, capture_4, capture_5}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_210467(capture_1, capture_2, capture_3, capture_4, capture_5, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_210804{capture_1, capture_2, capture_3, capture_4, capture_5}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_210804(capture_1, capture_2, capture_3, capture_4, capture_5, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_213361{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7}:
      match value:
        case Value_9{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_213361(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_214597{capture_1, capture_2, capture_3, capture_4, capture_5}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_214597(capture_1, capture_2, capture_3, capture_4, capture_5, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_215020{capture_1, capture_2}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_215020(capture_1, capture_2, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_215921{capture_1, capture_2, capture_3}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_215921(capture_1, capture_2, capture_3, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_218787{capture_1, capture_2, capture_3, capture_4, capture_5}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_218787(capture_1, capture_2, capture_3, capture_4, capture_5, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_222414{lexical_capture_98, lexical_capture_99, lexical_capture_100, lexical_capture_107}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_222414(lexical_capture_98, lexical_capture_99, lexical_capture_100, lexical_capture_107, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_222088{lexical_capture_98, lexical_capture_99, lexical_capture_100, lexical_capture_107}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_222088(lexical_capture_98, lexical_capture_99, lexical_capture_100, lexical_capture_107, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_221748{lexical_capture_98, lexical_capture_99, lexical_capture_100, lexical_capture_107}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_221748(lexical_capture_98, lexical_capture_99, lexical_capture_100, lexical_capture_107, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_220917{lexical_capture_49, lexical_capture_50, lexical_capture_51, lexical_capture_52, lexical_capture_53, lexical_capture_55, lexical_capture_56, lexical_capture_57}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_220917(lexical_capture_49, lexical_capture_50, lexical_capture_51, lexical_capture_52, lexical_capture_53, lexical_capture_55, lexical_capture_56, lexical_capture_57, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_223608{lexical_capture_1, lexical_capture_3, lexical_capture_4, lexical_capture_8}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_223608(lexical_capture_1, lexical_capture_3, lexical_capture_4, lexical_capture_8, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_223961{lexical_capture_1}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_223961(lexical_capture_1, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_224348{lexical_capture_2, lexical_capture_3, lexical_capture_0, lexical_capture_5}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_224348(lexical_capture_2, lexical_capture_3, lexical_capture_0, lexical_capture_5, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_226950{lexical_capture_4, lexical_capture_2, lexical_capture_6, lexical_capture_9, lexical_capture_11}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_226950(lexical_capture_4, lexical_capture_2, lexical_capture_6, lexical_capture_9, lexical_capture_11, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_227357{lexical_capture_4, lexical_capture_2, lexical_capture_6}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_227357(lexical_capture_4, lexical_capture_2, lexical_capture_6, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_230149{lexical_capture_1, lexical_capture_5, lexical_capture_10, lexical_capture_12}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_230149(lexical_capture_1, lexical_capture_5, lexical_capture_10, lexical_capture_12, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_230673{lexical_capture_2, lexical_capture_3, lexical_capture_0, lexical_capture_5, lexical_capture_10}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_230673(lexical_capture_2, lexical_capture_3, lexical_capture_0, lexical_capture_5, lexical_capture_10, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_232475{lexical_capture_1, lexical_capture_2, lexical_capture_6, lexical_capture_9, lexical_capture_11}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_232475(lexical_capture_1, lexical_capture_2, lexical_capture_6, lexical_capture_9, lexical_capture_11, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_233411{lexical_capture_6, lexical_capture_21, lexical_capture_8, lexical_capture_10, lexical_capture_13, lexical_capture_15}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_233411(lexical_capture_6, lexical_capture_21, lexical_capture_8, lexical_capture_10, lexical_capture_13, lexical_capture_15, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_235014{lexical_capture_1, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_12}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_235014(lexical_capture_1, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_12, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_235810{lexical_capture_7, lexical_capture_28, lexical_capture_6, lexical_capture_11}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_235810(lexical_capture_7, lexical_capture_28, lexical_capture_6, lexical_capture_11, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_236486{lexical_capture_1, lexical_capture_2, lexical_capture_4, lexical_capture_6, lexical_capture_9, lexical_capture_11}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_236486(lexical_capture_1, lexical_capture_2, lexical_capture_4, lexical_capture_6, lexical_capture_9, lexical_capture_11, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_239509{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_20}:
      match value:
        case Value_9{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_239509(lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_20, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_239269{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_14}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_239269(lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_14, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_242904{lexical_capture_3, lexical_capture_8, lexical_capture_10, lexical_capture_13, lexical_capture_15, lexical_capture_17}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_242904(lexical_capture_3, lexical_capture_8, lexical_capture_10, lexical_capture_13, lexical_capture_15, lexical_capture_17, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_244597{lexical_capture_2, lexical_capture_4, lexical_capture_6, lexical_capture_8, lexical_capture_9, lexical_capture_0, lexical_capture_22}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_244597(lexical_capture_2, lexical_capture_4, lexical_capture_6, lexical_capture_8, lexical_capture_9, lexical_capture_0, lexical_capture_22, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_246785{lexical_capture_1, lexical_capture_23, lexical_capture_25, lexical_capture_10, lexical_capture_11, lexical_capture_6, lexical_capture_8}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_246785(lexical_capture_1, lexical_capture_23, lexical_capture_25, lexical_capture_10, lexical_capture_11, lexical_capture_6, lexical_capture_8, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_248037{lexical_capture_1, lexical_capture_22, lexical_capture_5, lexical_capture_24, lexical_capture_10}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_248037(lexical_capture_1, lexical_capture_22, lexical_capture_5, lexical_capture_24, lexical_capture_10, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_249845{lexical_capture_1, lexical_capture_5, lexical_capture_14, lexical_capture_16}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_249845(lexical_capture_1, lexical_capture_5, lexical_capture_14, lexical_capture_16, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_251155{lexical_capture_3, lexical_capture_4, lexical_capture_6, lexical_capture_7}:
      match value:
        case Value_9{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_251155(lexical_capture_3, lexical_capture_4, lexical_capture_6, lexical_capture_7, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_251648{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5}:
      match value:
        case Value_16{result}:
          feedback_resume_Kont_251648(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_251939{lexical_capture_1, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_3}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_251939(lexical_capture_1, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_3, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_254771{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6}:
      match value:
        case Value_16{result}:
          feedback_resume_Kont_254771(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_255415{+lexical_capture_3, lexical_capture_30, +lexical_capture_5, lexical_capture_15, lexical_capture_17, lexical_capture_19, lexical_capture_7}:
      match value:
        case Value_9{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_255415(lexical_capture_3, lexical_capture_30, lexical_capture_5, lexical_capture_15, lexical_capture_17, lexical_capture_19, lexical_capture_7, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_261611{+lexical_capture_1, lexical_capture_2, +lexical_capture_18, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_19}:
      match value:
        case Value_9{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_261611(lexical_capture_1, lexical_capture_2, lexical_capture_18, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_19, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_258147{lexical_capture_1, lexical_capture_2, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_39}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_258147(lexical_capture_1, lexical_capture_2, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_39, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_264079{lexical_capture_6, lexical_capture_7, lexical_capture_9, lexical_capture_20, lexical_capture_14, lexical_capture_16, lexical_capture_18, lexical_capture_11}:
      match value:
        case Value_9{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_264079(lexical_capture_6, lexical_capture_7, lexical_capture_9, lexical_capture_20, lexical_capture_14, lexical_capture_16, lexical_capture_18, lexical_capture_11, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_265540{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6}:
      match value:
        case Value_16{result}:
          feedback_resume_Kont_265540(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_266451{lexical_capture_1, lexical_capture_2, lexical_capture_4, lexical_capture_6, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_266451(lexical_capture_1, lexical_capture_2, lexical_capture_4, lexical_capture_6, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_270490{lexical_capture_3, lexical_capture_5, lexical_capture_8, lexical_capture_13, lexical_capture_15, lexical_capture_17, lexical_capture_19}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_270490(lexical_capture_3, lexical_capture_5, lexical_capture_8, lexical_capture_13, lexical_capture_15, lexical_capture_17, lexical_capture_19, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_271785{lexical_capture_3, lexical_capture_4, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_271785(lexical_capture_3, lexical_capture_4, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_272903{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8}:
      match value:
        case Value_16{result}:
          feedback_resume_Kont_272903(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_274182{lexical_capture_17, lexical_capture_3, lexical_capture_4, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15, lexical_capture_6}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_274182(lexical_capture_17, lexical_capture_3, lexical_capture_4, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15, lexical_capture_6, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_276726{lexical_capture_6, lexical_capture_7, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_15, lexical_capture_17, lexical_capture_19}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_276726(lexical_capture_6, lexical_capture_7, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_15, lexical_capture_17, lexical_capture_19, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_277885{capture_0, capture_1, capture_2, capture_4, capture_5, capture_6, capture_7, capture_8}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_277885(capture_0, capture_1, capture_2, capture_4, capture_5, capture_6, capture_7, capture_8, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_279668{lexical_capture_1, lexical_capture_2, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_279668(lexical_capture_1, lexical_capture_2, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_282173{lexical_capture_3, lexical_capture_5, lexical_capture_8, lexical_capture_13, lexical_capture_15, lexical_capture_17, lexical_capture_19}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_282173(lexical_capture_3, lexical_capture_5, lexical_capture_8, lexical_capture_13, lexical_capture_15, lexical_capture_17, lexical_capture_19, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_292785{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_14, lexical_capture_16, lexical_capture_17}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_292785(lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_14, lexical_capture_16, lexical_capture_17, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_293503{lexical_capture_2, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_17, lexical_capture_19, lexical_capture_20}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_293503(lexical_capture_2, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_17, lexical_capture_19, lexical_capture_20, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_296071{lexical_capture_1}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_296071(lexical_capture_1, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_297632{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_297632(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_299524{lexical_capture_3, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_22}:
      match value:
        case Value_2{result_0_0_0, result_0_0_1, result_0_1, result_1}:
          feedback_resume_Kont_299524(lexical_capture_3, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_22, (((result_0_0_0, result_0_0_1), result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_300984{lexical_capture_3, lexical_capture_7, lexical_capture_13, lexical_capture_15, lexical_capture_17}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_300984(lexical_capture_3, lexical_capture_7, lexical_capture_13, lexical_capture_15, lexical_capture_17, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_301643{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_14, lexical_capture_16, lexical_capture_17}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_301643(lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_14, lexical_capture_16, lexical_capture_17, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_303223{lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_19, lexical_capture_11}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_303223(lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_19, lexical_capture_11, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_303846{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_14, lexical_capture_16}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_303846(lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_14, lexical_capture_16, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_306294{lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_12, lexical_capture_14}:
      match value:
        case Value_4{result_0_0, result_0_1, result_1_0_0, result_1_0_1, result_1_1}:
          feedback_resume_Kont_306294(lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_12, lexical_capture_14, ((result_0_0, result_0_1), ((result_1_0_0, result_1_0_1), result_1_1)))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_307113{lexical_capture_4, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15, lexical_capture_17, lexical_capture_20, lexical_capture_22}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_307113(lexical_capture_4, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15, lexical_capture_17, lexical_capture_20, lexical_capture_22, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_308366{lexical_capture_2, lexical_capture_5, lexical_capture_12, lexical_capture_14}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_308366(lexical_capture_2, lexical_capture_5, lexical_capture_12, lexical_capture_14, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_308948{lexical_capture_1, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_12}:
      match value:
        case Value_9{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_308948(lexical_capture_1, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_12, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_309436{lexical_capture_1, lexical_capture_13, lexical_capture_3, lexical_capture_5}:
      match value:
        case Value_9{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_309436(lexical_capture_1, lexical_capture_13, lexical_capture_3, lexical_capture_5, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_312599{lexical_capture_1, lexical_capture_6, lexical_capture_8, lexical_capture_10}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_312599(lexical_capture_1, lexical_capture_6, lexical_capture_8, lexical_capture_10, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_313186{lexical_capture_3, lexical_capture_5, lexical_capture_9, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_18}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_313186(lexical_capture_3, lexical_capture_5, lexical_capture_9, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_18, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_316227{capture_1, capture_2, capture_3, capture_4}:
      match value:
        case Value_18{result}:
          feedback_resume_Kont_316227(capture_1, capture_2, capture_3, capture_4, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_317252{lexical_capture_5, lexical_capture_3, lexical_capture_15}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_317252(lexical_capture_5, lexical_capture_3, lexical_capture_15, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_322498{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8}:
      match value:
        case Value_16{result}:
          feedback_resume_Kont_322498(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_323146{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_323146(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_325947{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9}:
      match value:
        case Value_16{result}:
          feedback_resume_Kont_325947(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_326599{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_326599(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_328193{}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_328193(((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_329864{lexical_capture_0, lexical_capture_2, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_5}:
      match value:
        case Value_3{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_329864(lexical_capture_0, lexical_capture_2, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_5, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_331293{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_331293(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_331662{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_13, lexical_capture_15}:
      match value:
        case Value_3{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_331662(lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_13, lexical_capture_15, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_334657{lexical_capture_1, lexical_capture_3, lexical_capture_5}:
      match value:
        case Value_1{result_0_0_0_0, result_0_0_0_1, result_0_0_1, result_0_1, result_1}:
          feedback_resume_Kont_334657(lexical_capture_1, lexical_capture_3, lexical_capture_5, ((((result_0_0_0_0, result_0_0_0_1), result_0_0_1), result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_339962{}:
      match value:
        case Value_6{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_339962(((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_339827{}:
      match value:
        case Value_6{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_339827(((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_342579{lexical_capture_3, lexical_capture_26, lexical_capture_27, lexical_capture_9, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_18, lexical_capture_20}:
      match value:
        case Value_1{result_0_0_0_0, result_0_0_0_1, result_0_0_1, result_0_1, result_1}:
          feedback_resume_Kont_342579(lexical_capture_3, lexical_capture_26, lexical_capture_27, lexical_capture_9, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_18, lexical_capture_20, ((((result_0_0_0_0, result_0_0_0_1), result_0_0_1), result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_344635{lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_14, lexical_capture_2}:
      match value:
        case Value_7{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_344635(lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_14, lexical_capture_2, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_345467{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_16, lexical_capture_18}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_345467(lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_16, lexical_capture_18, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_347534{lexical_capture_26, lexical_capture_1, lexical_capture_19, lexical_capture_5, lexical_capture_7}:
      match value:
        case Value_1{result_0_0_0_0, result_0_0_0_1, result_0_0_1, result_0_1, result_1}:
          feedback_resume_Kont_347534(lexical_capture_26, lexical_capture_1, lexical_capture_19, lexical_capture_5, lexical_capture_7, ((((result_0_0_0_0, result_0_0_0_1), result_0_0_1), result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_347068{lexical_capture_26, lexical_capture_1, lexical_capture_19, lexical_capture_5, lexical_capture_7}:
      match value:
        case Value_1{result_0_0_0_0, result_0_0_0_1, result_0_0_1, result_0_1, result_1}:
          feedback_resume_Kont_347068(lexical_capture_26, lexical_capture_1, lexical_capture_19, lexical_capture_5, lexical_capture_7, ((((result_0_0_0_0, result_0_0_0_1), result_0_0_1), result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_349565{lexical_capture_12, lexical_capture_14, lexical_capture_3, lexical_capture_16, lexical_capture_17, lexical_capture_5}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_349565(lexical_capture_12, lexical_capture_14, lexical_capture_3, lexical_capture_16, lexical_capture_17, lexical_capture_5, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_353513{lexical_capture_1, lexical_capture_31, lexical_capture_32, lexical_capture_33, lexical_capture_5, lexical_capture_7, lexical_capture_8, lexical_capture_11, lexical_capture_13, lexical_capture_15}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_353513(lexical_capture_1, lexical_capture_31, lexical_capture_32, lexical_capture_33, lexical_capture_5, lexical_capture_7, lexical_capture_8, lexical_capture_11, lexical_capture_13, lexical_capture_15, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_355479{lexical_capture_1, lexical_capture_7, lexical_capture_9, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_17, lexical_capture_20, lexical_capture_22, lexical_capture_24}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_355479(lexical_capture_1, lexical_capture_7, lexical_capture_9, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_17, lexical_capture_20, lexical_capture_22, lexical_capture_24, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_357785{lexical_capture_1, lexical_capture_17, lexical_capture_5, lexical_capture_24, lexical_capture_25}:
      match value:
        case Value_0{result_0_0_0_0, result_0_0_0_1, result_0_0_1, result_0_1, result_1}:
          feedback_resume_Kont_357785(lexical_capture_1, lexical_capture_17, lexical_capture_5, lexical_capture_24, lexical_capture_25, ((((result_0_0_0_0, result_0_0_0_1), result_0_0_1), result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_363271{lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9}:
      match value:
        case Value_6{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_363271(lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_362980{lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9}:
      match value:
        case Value_6{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_362980(lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_362687{lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9}:
      match value:
        case Value_6{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_362687(lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_362397{lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9}:
      match value:
        case Value_6{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_362397(lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_365172{lexical_capture_7, lexical_capture_3}:
      match value:
        case Value_10{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_365172(lexical_capture_7, lexical_capture_3, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_365625{lexical_capture_3}:
      match value:
        case Value_8{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_365625(lexical_capture_3, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}

