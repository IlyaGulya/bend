# EXPERIMENTAL / FUEL-PARAMETRIC / NOT SELFHOST GREEN

import Base
import ../bend2/selfhost/ast.bend as Ast
import ../bend2/selfhost/lexer.bend as Lexer
import ../bend2/selfhost/core.bend as Core

import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/backend_ir.bend as BIR
import ../bend2/selfhost/checked_frontend.bend as Checked
import ./template_steps_v1.bend as Template
import ./checker_core_steps_v1.bend as CheckerCore
import ./js_emit_steps_v1.bend as JSEmit
import ./c_emit_steps_v1.bend as CEmit

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
  Kont_130823{capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: Nat, capture_5: List<&2, PatternFrame>, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: PatternScanGoal}
  Kont_136112{capture_1: Ast.SyntaxPattern}
  Kont_136348{capture_1: List<&2, Ast.SyntaxTerm>}
  Kont_136857{capture_1: String, capture_2: Ast.SourceSpan}
  Kont_138004{capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: Nat, capture_4: Nat, capture_5: List<&2, PatternFrame>, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: PatternScanGoal}
  Kont_139735{capture_1: String, capture_2: Nat, capture_3: Ast.SyntaxPattern}
  Kont_140566{capture_1: String, capture_2: Nat}
  Kont_143905{capture_1: String, capture_2: List<&2, PatternFrame>, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: PatternScanGoal}
  Kont_149803{capture_1: String, capture_2: Ast.SyntaxPattern, capture_3: List<&2, PatternFrame>, capture_4: List<&2, Scope>, capture_5: Nat, capture_6: PatternScanGoal}
  Kont_171361{capture_1: String, capture_2: Nat}
  Kont_180515{capture_1: String, capture_2: String, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Lexer.Token>, capture_6: List<&2, Scope>, capture_7: Nat}
  Kont_182131{capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Lexer.Token>}
  Kont_188212{capture_1: String, capture_2: Nat}
  Kont_188724{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Nat, capture_5: Nat}
  Kont_190051{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: Nat, capture_8: Nat, capture_9: List<&2, Scope>, capture_10: Nat, capture_11: Nat}
  Kont_193125{lexical_capture_4: String, lexical_capture_6: String, lexical_capture_8: List<&2, Ast.SyntaxTerm>, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_13: Ast.SyntaxTerm, lexical_capture_29: Ast.SyntaxTerm, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_22: Nat}
  Kont_194056{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Nat, capture_7: Nat, capture_8: List<&2, Scope>, capture_9: Nat, capture_10: Nat}
  Kont_195068{lexical_capture_4: String, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_22: Nat, lexical_capture_13: Ast.SyntaxTerm, lexical_capture_29: Ast.SyntaxTerm}
  Kont_195719{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: Nat, capture_8: Nat, capture_9: List<&2, Scope>, capture_10: Nat, capture_11: Nat}
  Kont_197784{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Ast.SyntaxTerm, capture_5: Nat, capture_6: Nat, capture_7: List<&2, Scope>, capture_8: Nat, capture_9: Nat}
  Kont_198352{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Nat, capture_5: Nat, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: Nat}
  Kont_199714{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: List<&2, Ast.SyntaxTerm>, lexical_capture_6: Ast.SyntaxTerm, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_18: Nat}
  Kont_202679{capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Lexer.Token>}
  Kont_203834{capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Scope>, capture_5: Nat}
  Kont_205019{lexical_capture_4: String, lexical_capture_5: Ast.SyntaxTerm, lexical_capture_7: Nat}
  Kont_205711{capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Scope>, capture_6: Nat}
  Kont_206436{capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Ast.SyntaxTerm, capture_4: Nat, capture_5: Nat}
  Kont_206773{capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Ast.SyntaxTerm, capture_4: Nat, capture_5: Nat}
  Kont_209330{capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Lexer.Token>, capture_5: Nat, capture_6: List<&2, Scope>, capture_7: Nat}
  Kont_210566{capture_1: String, capture_2: List<&2, Lexer.Token>, capture_3: Nat, capture_4: List<&2, Scope>, capture_5: Nat}
  Kont_210989{capture_1: String, capture_2: Ast.SyntaxTerm}
  Kont_211890{capture_1: String, capture_2: List<&2, Scope>, capture_3: Nat}
  Kont_214756{capture_1: String, capture_2: String, capture_3: Nat, capture_4: List<&2, Scope>, capture_5: Nat}
  Kont_218383{lexical_capture_98: String, lexical_capture_99: String, lexical_capture_100: Ast.SyntaxTerm, lexical_capture_107: Nat}
  Kont_218057{lexical_capture_98: String, lexical_capture_99: String, lexical_capture_100: Ast.SyntaxTerm, lexical_capture_107: Nat}
  Kont_217717{lexical_capture_98: String, lexical_capture_99: String, lexical_capture_100: Ast.SyntaxTerm, lexical_capture_107: Nat}
  Kont_216886{lexical_capture_49: String, lexical_capture_50: String, lexical_capture_51: Ast.SyntaxTerm, lexical_capture_52: List<&2, Lexer.Token>, lexical_capture_53: String, lexical_capture_55: Nat, lexical_capture_56: List<&2, Scope>, lexical_capture_57: Nat}
  Kont_219577{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_8: Nat}
  Kont_219930{lexical_capture_1: String}
  Kont_220317{lexical_capture_2: String, lexical_capture_3: Ast.SyntaxTerm, lexical_capture_0: Ast.SyntaxTerm, lexical_capture_5: Nat}
  Kont_222919{lexical_capture_4: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: Nat, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat}
  Kont_223326{lexical_capture_4: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: Nat}
  Kont_226118{lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_10: List<&2, Scope>, lexical_capture_12: Nat}
  Kont_226642{lexical_capture_2: String, lexical_capture_3: Ast.SyntaxTerm, lexical_capture_0: Ast.SyntaxTerm, lexical_capture_5: Nat, lexical_capture_10: Nat}
  Kont_228444{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: Nat, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat}
  Kont_229380{lexical_capture_6: String, lexical_capture_21: String, lexical_capture_8: Nat, lexical_capture_10: Nat, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat}
  Kont_230983{lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_10: List<&2, Scope>, lexical_capture_12: Nat}
  Kont_231779{lexical_capture_7: Ast.SyntaxTerm, lexical_capture_28: Ast.SyntaxTerm, lexical_capture_6: String, lexical_capture_11: Nat}
  Kont_232455{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_4: String, lexical_capture_6: Nat, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat}
  Kont_235478{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_20: List<&2, Lexer.Token>}
  Kont_235238{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_14: Nat}
  Kont_238873{lexical_capture_3: String, lexical_capture_8: List<&2, Lexer.Token>, lexical_capture_10: String, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: List<&2, Ast.SyntaxTerm>}
  Kont_240566{lexical_capture_2: String, lexical_capture_4: String, lexical_capture_6: Nat, lexical_capture_8: Nat, lexical_capture_9: Ast.Quantity, lexical_capture_0: Ast.SyntaxTerm, lexical_capture_22: Nat}
  Kont_242754{lexical_capture_1: String, lexical_capture_23: String, lexical_capture_25: Nat, lexical_capture_10: Nat, lexical_capture_11: Ast.Quantity, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat}
  Kont_244006{lexical_capture_1: String, lexical_capture_22: String, lexical_capture_5: Nat, lexical_capture_24: Nat, lexical_capture_10: Nat}
  Kont_245814{lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat}
  Kont_247124{lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_6: Nat, lexical_capture_7: Lexer.Token}
  Kont_247617{capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: List<&2, Lexer.Token>, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: Nat}
  Kont_247908{lexical_capture_1: String, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat, lexical_capture_10: Nat, lexical_capture_3: List<&2, Lexer.Token>}
  Kont_250740{capture_0: List<&2, Ast.SyntaxTerm>, capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: Ast.SyntaxTerm, capture_4: List<&2, Scope>, capture_5: Nat, capture_6: Nat}
  Kont_251384{lexical_capture_3: String, lexical_capture_30: Ast.SyntaxTerm, lexical_capture_5: Lexer.Token, lexical_capture_15: List<&2, Scope>, lexical_capture_17: Nat, lexical_capture_19: Nat, lexical_capture_7: List<&2, Lexer.Token>}
  Kont_257580{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_18: Lexer.Token, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: Nat, lexical_capture_19: List<&2, Lexer.Token>}
  Kont_254116{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: Nat, lexical_capture_39: Nat}
  Kont_260048{lexical_capture_6: String, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_9: Lexer.Token, lexical_capture_20: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, lexical_capture_18: Nat, lexical_capture_11: List<&2, Lexer.Token>}
  Kont_261509{capture_0: List<&2, Ast.SyntaxTerm>, capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: Ast.SyntaxTerm, capture_4: List<&2, Scope>, capture_5: Nat, capture_6: Nat}
  Kont_262420{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_4: List<&2, Lexer.Token>, lexical_capture_6: List<&2, Lexer.Token>, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat}
  Kont_266459{lexical_capture_3: String, lexical_capture_5: String, lexical_capture_8: Ast.SyntaxTerm, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_19: Nat}
  Kont_267754{lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat}
  Kont_268872{capture_0: Bool, capture_1: Ast.SyntaxTerm, capture_2: List<&2, Lexer.Token>, capture_3: Bool, capture_4: String, capture_5: Ast.SyntaxTerm, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: Nat}
  Kont_270151{lexical_capture_17: Bool, lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat, lexical_capture_6: List<&2, Lexer.Token>}
  Kont_272695{lexical_capture_6: String, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_8: Ast.SyntaxTerm, lexical_capture_10: Nat, lexical_capture_12: Nat, lexical_capture_15: List<&2, Scope>, lexical_capture_17: Nat, lexical_capture_19: Nat}
  Kont_273854{capture_0: List<&2, Lexer.Token>, capture_1: String, capture_2: Ast.SyntaxTerm, capture_4: Nat, capture_5: Nat, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: Nat}
  Kont_275637{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat}
  Kont_278142{lexical_capture_3: String, lexical_capture_5: String, lexical_capture_8: Ast.SyntaxTerm, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_19: Nat}
  Kont_286456{lexical_capture_1: String}
  Kont_288017{capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: List<&2, Ast.SyntaxPattern>, capture_6: Nat, capture_7: List<&2, Ast.SyntaxTerm>}
  Kont_289909{lexical_capture_3: List<&2, Ast.SyntaxPattern>, lexical_capture_8: List<&2, Scope>, lexical_capture_10: Nat, lexical_capture_12: String, lexical_capture_14: Nat, lexical_capture_16: Nat, lexical_capture_22: Ast.Quantity}
  Kont_291369{lexical_capture_3: List<&2, Ast.SyntaxTerm>, lexical_capture_7: List<&2, Ast.SyntaxPattern>, lexical_capture_13: Ast.Quantity, lexical_capture_15: String, lexical_capture_17: Nat}
  Kont_292028{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, lexical_capture_17: Ast.Quantity}
  Kont_293608{lexical_capture_3: String, lexical_capture_5: String, lexical_capture_7: Nat, lexical_capture_10: Ast.SyntaxPattern, lexical_capture_19: Ast.Quantity, lexical_capture_11: Ast.SyntaxTerm}
  Kont_294231{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat}
  Kont_296679{lexical_capture_3: String, lexical_capture_5: List<&2, Lexer.Token>, lexical_capture_7: Nat, lexical_capture_9: Nat, lexical_capture_12: List<&2, Scope>, lexical_capture_14: Nat}
  Kont_297498{lexical_capture_4: Ast.SyntaxPattern, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: String, lexical_capture_13: List<&2, Lexer.Token>, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_20: List<&2, Scope>, lexical_capture_22: Nat}
  Kont_298751{lexical_capture_2: Ast.SyntaxTerm, lexical_capture_5: Ast.SyntaxPattern, lexical_capture_12: String, lexical_capture_14: Nat}
  Kont_299333{lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_10: List<&2, Scope>, lexical_capture_12: Nat}
  Kont_299821{lexical_capture_1: List<&2, Ast.SyntaxTerm>, lexical_capture_13: Lexer.Token, lexical_capture_3: String, lexical_capture_5: Nat}
  Kont_302984{lexical_capture_1: String, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat, lexical_capture_10: List<&2, Ast.SyntaxTerm>}
  Kont_303571{lexical_capture_3: String, lexical_capture_5: List<&2, Lexer.Token>, lexical_capture_9: Nat, lexical_capture_12: List<&2, Scope>, lexical_capture_14: Nat, lexical_capture_16: Nat, lexical_capture_18: List<&2, Ast.SyntaxTerm>}
  Kont_306612{capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: Nat}
  Kont_307637{lexical_capture_5: List<&2, Ast.SyntaxPattern>, lexical_capture_3: String, lexical_capture_15: Nat}
  Kont_312883{capture_0: String, capture_1: List<&2, Ast.TelescopeItem>, capture_2: List<&2, Scope>, capture_3: Nat, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: List<&2, Lexer.Token>, capture_8: Nat}
  Kont_313531{capture_1: String, capture_2: List<&2, Ast.TelescopeItem>, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: String, capture_6: Nat, capture_7: List<&2, Lexer.Token>}
  Kont_316332{capture_0: String, capture_1: String, capture_2: Ast.Quantity, capture_3: Nat, capture_4: List<&2, Ast.TelescopeItem>, capture_5: List<&2, Scope>, capture_6: Nat, capture_7: Ast.SyntaxTerm, capture_8: List<&2, Lexer.Token>, capture_9: Nat}
  Kont_316984{capture_1: String, capture_2: String, capture_3: Ast.Quantity, capture_4: Nat, capture_5: List<&2, Ast.TelescopeItem>, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: List<&2, Lexer.Token>}
  Kont_318578{}
  Kont_320249{lexical_capture_0: Lexer.Token, lexical_capture_2: List<&2, Lexer.Token>, lexical_capture_8: String, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_14: List<&2, Ast.TelescopeItem>, lexical_capture_5: Ast.SyntaxTerm}
  Kont_321678{capture_1: Lexer.Token, capture_2: String, capture_3: String, capture_4: Nat, capture_5: List<&2, Ast.TelescopeItem>, capture_6: List<&2, Scope>, capture_7: Nat}
  Kont_322047{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: List<&2, Ast.TelescopeItem>, lexical_capture_13: Lexer.Token, lexical_capture_15: List<&2, Lexer.Token>}
  Kont_325042{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat}
  Kont_330347{}
  Kont_330212{}
  Kont_332964{lexical_capture_3: String, lexical_capture_26: Lexer.Token, lexical_capture_27: List<&2, Lexer.Token>, lexical_capture_9: Nat, lexical_capture_12: List<&2, Scope>, lexical_capture_14: Nat, lexical_capture_16: List<&2, Ast.ConstructorDecl>, lexical_capture_18: String, lexical_capture_20: Nat}
  Kont_335020{lexical_capture_6: String, lexical_capture_8: String, lexical_capture_10: Nat, lexical_capture_14: List<&2, Ast.TelescopeItem>, lexical_capture_2: Ast.SyntaxTerm}
  Kont_335852{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: List<&2, Ast.TelescopeItem>, lexical_capture_11: List<&2, Lexer.Token>, lexical_capture_16: List<&2, Scope>, lexical_capture_18: Nat}
  Kont_337919{lexical_capture_26: Lexer.Token, lexical_capture_1: String, lexical_capture_19: String, lexical_capture_5: Nat, lexical_capture_7: Nat}
  Kont_337453{lexical_capture_26: Lexer.Token, lexical_capture_1: String, lexical_capture_19: String, lexical_capture_5: Nat, lexical_capture_7: Nat}
  Kont_339950{lexical_capture_12: String, lexical_capture_14: String, lexical_capture_3: List<&2, Ast.Clause>, lexical_capture_16: Nat, lexical_capture_17: Lexer.Token, lexical_capture_5: List<&2, Lexer.Token>}
  Kont_343898{lexical_capture_1: String, lexical_capture_31: String, lexical_capture_32: Nat, lexical_capture_33: Nat, lexical_capture_5: Nat, lexical_capture_7: Bool, lexical_capture_8: Ast.Quantity, lexical_capture_11: List<&2, Scope>, lexical_capture_13: Nat, lexical_capture_15: List<&2, Ast.Clause>}
  Kont_345864{lexical_capture_1: String, lexical_capture_7: Nat, lexical_capture_9: Bool, lexical_capture_10: Ast.Quantity, lexical_capture_12: String, lexical_capture_14: Nat, lexical_capture_17: Ast.SyntaxTerm, lexical_capture_20: List<&2, Scope>, lexical_capture_22: Nat, lexical_capture_24: List<&2, Ast.Clause>}
  Kont_348170{lexical_capture_1: String, lexical_capture_17: String, lexical_capture_5: Nat, lexical_capture_24: Lexer.Token, lexical_capture_25: List<&2, Lexer.Token>}
  Kont_353656{lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>}
  Kont_353365{lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>}
  Kont_353072{lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>}
  Kont_352782{lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>}
  Kont_355557{lexical_capture_7: String, lexical_capture_3: List<&2, Ast.ModuleImport>}
  Kont_356010{lexical_capture_3: String}

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

def step_consumed_token_end_step(is_consumed: Bool, next: Lexer.Token, rest: List<&2, Lexer.Token>, +stop: Nat, fallback: Nat) -> FeedbackControl:
  match is_consumed:
    case True{}:
      FeedbackControl{FeedbackCall{feedback_make_consumed_token_end_before(rest, stop, Nat.min(token_end(next), stop))}, Nil{}, NoProgress{}, NoProgress{}}
    case False{}:
      feedback_pack_16(fallback)

def token_beg(token: Lexer.Token) -> Nat:
  match token:
    case Lexer.TokenInfo{ _,  _, beg,  _,  _,  _}:
      beg

def step_consumed_token_end_before(tokens: List<&2, Lexer.Token>, +stop: Nat, +fallback: Nat) -> FeedbackControl:
  match tokens:
    case +next <> rest:
      step_consumed_token_end_step(Nat.is_lt(token_beg(next), stop), next, rest, stop, fallback)
    case Nil{}:
      feedback_pack_16(fallback)

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

def feedback_make_Kont_136348(capture_1: List<&2, Ast.SyntaxTerm>) -> FeedbackFrame:
  Kont_136348{capture_1}

def feedback_pack_14(result: Maybe<&2, List<&2, Ast.SyntaxPattern>>) -> FeedbackControl:
  FeedbackControl{FeedbackDone{Value_14{result}}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_make_Kont_136857(capture_1: String, capture_2: Ast.SourceSpan) -> FeedbackFrame:
  Kont_136857{capture_1, capture_2}

def feedback_make_literal_pattern_fields(terms: List<&2, Ast.SyntaxTerm>) -> FeedbackRequest:
  Request_literal_pattern_fields{terms}

def feedback_pack_13(result: Maybe<&2, Ast.SyntaxPattern>) -> FeedbackControl:
  FeedbackControl{FeedbackDone{Value_13{result}}, Nil{}, NoProgress{}, NoProgress{}}

def step_literal_pattern_tree(term: Ast.SyntaxTerm) -> FeedbackControl:
  match term:
    case Ast.TermCtr{key, fields, position}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_literal_pattern_fields(fields)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_136857(key, position))
    case _:
      feedback_pack_13(None{})

def step_literal_pattern(term: Ast.SyntaxTerm) -> FeedbackControl:
  match term:
    case Ast.TermString{chars, names, position}:
      step_literal_pattern_tree(Ast.string_desugar(chars, names, position))
    case Ast.TermVar{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2}:
      step_literal_pattern_tree((Ast.TermVar{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm))
    case Ast.TermRef{feedback_field_4_0, feedback_field_4_1}:
      step_literal_pattern_tree((Ast.TermRef{feedback_field_4_0, feedback_field_4_1} : Ast.SyntaxTerm))
    case Ast.TermBang{feedback_field_4_0, feedback_field_4_1}:
      step_literal_pattern_tree((Ast.TermBang{feedback_field_4_0, feedback_field_4_1} : Ast.SyntaxTerm))
    case Ast.TermSub{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3}:
      step_literal_pattern_tree((Ast.TermSub{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3} : Ast.SyntaxTerm))
    case Ast.TermLet{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4, feedback_field_4_5}:
      step_literal_pattern_tree((Ast.TermLet{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4, feedback_field_4_5} : Ast.SyntaxTerm))
    case Ast.TermAnn{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2}:
      step_literal_pattern_tree((Ast.TermAnn{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm))
    case Ast.TermTemplate{feedback_field_4_0, feedback_field_4_1}:
      step_literal_pattern_tree((Ast.TermTemplate{feedback_field_4_0, feedback_field_4_1} : Ast.SyntaxTerm))
    case Ast.TermType{feedback_field_4_0, feedback_field_4_1}:
      step_literal_pattern_tree((Ast.TermType{feedback_field_4_0, feedback_field_4_1} : Ast.SyntaxTerm))
    case Ast.TermQuant{}:
      step_literal_pattern_tree((Ast.TermQuant{} : Ast.SyntaxTerm))
    case Ast.TermQuantity{feedback_field_4_0, feedback_field_4_1}:
      step_literal_pattern_tree((Ast.TermQuantity{feedback_field_4_0, feedback_field_4_1} : Ast.SyntaxTerm))
    case Ast.TermMin{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2}:
      step_literal_pattern_tree((Ast.TermMin{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm))
    case Ast.TermAll{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4, feedback_field_4_5}:
      step_literal_pattern_tree((Ast.TermAll{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4, feedback_field_4_5} : Ast.SyntaxTerm))
    case Ast.TermLam{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4}:
      step_literal_pattern_tree((Ast.TermLam{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4} : Ast.SyntaxTerm))
    case Ast.TermApp{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2}:
      step_literal_pattern_tree((Ast.TermApp{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm))
    case Ast.TermAdt{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3}:
      step_literal_pattern_tree((Ast.TermAdt{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3} : Ast.SyntaxTerm))
    case Ast.TermFill{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2}:
      step_literal_pattern_tree((Ast.TermFill{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm))
    case Ast.TermPlus{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2}:
      step_literal_pattern_tree((Ast.TermPlus{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm))
    case Ast.TermCtr{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2}:
      step_literal_pattern_tree((Ast.TermCtr{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm))
    case Ast.TermString{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2}:
      step_literal_pattern_tree((Ast.TermString{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm))
    case Ast.TermMat{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3}:
      step_literal_pattern_tree((Ast.TermMat{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3} : Ast.SyntaxTerm))
    case Ast.TermAbsurd{feedback_field_4_0}:
      step_literal_pattern_tree((Ast.TermAbsurd{feedback_field_4_0} : Ast.SyntaxTerm))
    case Ast.TermEqual{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3}:
      step_literal_pattern_tree((Ast.TermEqual{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3} : Ast.SyntaxTerm))
    case Ast.TermRefl{feedback_field_4_0}:
      step_literal_pattern_tree((Ast.TermRefl{feedback_field_4_0} : Ast.SyntaxTerm))
    case Ast.TermRewrite{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3}:
      step_literal_pattern_tree((Ast.TermRewrite{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3} : Ast.SyntaxTerm))
    case Ast.TermHole{feedback_field_4_0, feedback_field_4_1}:
      step_literal_pattern_tree((Ast.TermHole{feedback_field_4_0, feedback_field_4_1} : Ast.SyntaxTerm))
    case Ast.BodyMatch{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2}:
      step_literal_pattern_tree((Ast.BodyMatch{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm))
    case Ast.BodyCase{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2}:
      step_literal_pattern_tree((Ast.BodyCase{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2} : Ast.SyntaxTerm))
    case Ast.BodyLocal{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4}:
      step_literal_pattern_tree((Ast.BodyLocal{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4} : Ast.SyntaxTerm))
    case Ast.BodyReply{feedback_field_4_0, feedback_field_4_1}:
      step_literal_pattern_tree((Ast.BodyReply{feedback_field_4_0, feedback_field_4_1} : Ast.SyntaxTerm))

def step_literal_pattern_fields(terms: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match terms:
    case term <> rest:
      feedback_attach(step_literal_pattern(term), feedback_make_Kont_136348(rest))
    case Nil{}:
      feedback_pack_14(Some{Nil{}})

def feedback_make_Kont_95827(capture_0: Ast.SourceSpan) -> FeedbackFrame:
  Kont_95827{capture_0}

def feedback_make_Kont_95975(capture_0: String, capture_1: Nat, capture_2: Ast.SyntaxTerm, capture_3: Ast.SourceSpan) -> FeedbackFrame:
  Kont_95975{capture_0, capture_1, capture_2, capture_3}

def feedback_make_Kont_96147(capture_0: String, capture_1: List<&2, String>, capture_2: List<&2, Nat>, capture_3: List<&2, Ast.Quantity>, capture_4: Ast.SyntaxTerm, capture_5: Ast.SourceSpan) -> FeedbackFrame:
  Kont_96147{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5}

def feedback_make_Kont_96284(capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: Ast.SourceSpan) -> FeedbackFrame:
  Kont_96284{capture_0, capture_1, capture_2}

def feedback_make_Kont_96408(capture_0: Ast.SourceSpan) -> FeedbackFrame:
  Kont_96408{capture_0}

def feedback_make_Kont_96528(capture_0: Ast.SourceSpan) -> FeedbackFrame:
  Kont_96528{capture_0}

def feedback_make_Kont_96786(capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: Ast.SourceSpan) -> FeedbackFrame:
  Kont_96786{capture_0, capture_1, capture_2}

def feedback_make_Kont_96958(capture_0: String, capture_1: Ast.Quantity, capture_2: String, capture_3: Nat, capture_4: Ast.SyntaxTerm, capture_5: Ast.SourceSpan) -> FeedbackFrame:
  Kont_96958{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5}

def feedback_make_Kont_97113(capture_0: Maybe<&2, Ast.Quantity>, capture_1: String, capture_2: Nat, capture_3: Ast.SourceSpan) -> FeedbackFrame:
  Kont_97113{capture_0, capture_1, capture_2, capture_3}

def feedback_make_Kont_97251(capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: Ast.SourceSpan) -> FeedbackFrame:
  Kont_97251{capture_0, capture_1, capture_2}

def feedback_make_Kont_97401(capture_0: String, capture_1: List<&2, String>, capture_2: Ast.SourceSpan) -> FeedbackFrame:
  Kont_97401{capture_0, capture_1, capture_2}

def feedback_make_Kont_97545(capture_0: String, capture_1: List<&2, Ast.SyntaxTerm>, capture_2: Ast.SourceSpan) -> FeedbackFrame:
  Kont_97545{capture_0, capture_1, capture_2}

def feedback_make_Kont_97688(capture_0: String, capture_1: List<&2, Ast.SyntaxTerm>, capture_2: Ast.SourceSpan) -> FeedbackFrame:
  Kont_97688{capture_0, capture_1, capture_2}

def feedback_make_Kont_97825(capture_0: String, capture_1: Ast.SourceSpan) -> FeedbackFrame:
  Kont_97825{capture_0, capture_1}

def feedback_make_Kont_98070(capture_0: String, capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Ast.SourceSpan) -> FeedbackFrame:
  Kont_98070{capture_0, capture_1, capture_2, capture_3}

def feedback_make_Kont_98288(capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: Ast.SyntaxTerm, capture_3: Ast.SourceSpan) -> FeedbackFrame:
  Kont_98288{capture_0, capture_1, capture_2, capture_3}

def feedback_make_Kont_98504(capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: Ast.SyntaxTerm, capture_3: Ast.SourceSpan) -> FeedbackFrame:
  Kont_98504{capture_0, capture_1, capture_2, capture_3}

def feedback_make_Kont_98718(capture_0: String, capture_1: List<&2, Ast.SyntaxTerm>, capture_2: Ast.SourceSpan) -> FeedbackFrame:
  Kont_98718{capture_0, capture_1, capture_2}

def feedback_make_Kont_98857(capture_0: List<&2, Ast.SyntaxPattern>, capture_1: Ast.SourceSpan) -> FeedbackFrame:
  Kont_98857{capture_0, capture_1}

def feedback_make_Kont_99029(capture_0: String, capture_1: List<&2, Ast.SyntaxPattern>, capture_2: Ast.Quantity, capture_3: Ast.SyntaxTerm, capture_4: Ast.SourceSpan) -> FeedbackFrame:
  Kont_99029{capture_0, capture_1, capture_2, capture_3, capture_4}

def feedback_make_Kont_99155(capture_0: Ast.SourceSpan) -> FeedbackFrame:
  Kont_99155{capture_0}

def feedback_make_map_operator_term(v_0: Ast.SyntaxTerm, v_2: String) -> FeedbackRequest:
  Request_map_operator_term{v_0, v_2}

def feedback_make_map_operator_terms(v_1: List<&2, Ast.SyntaxTerm>, v_3: String) -> FeedbackRequest:
  Request_map_operator_terms{v_1, v_3}

def feedback_pack_11(result: Ast.SyntaxTerm) -> FeedbackControl:
  FeedbackControl{FeedbackDone{Value_11{result}}, Nil{}, NoProgress{}, NoProgress{}}

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

@unsafe
def step_map_operator_term(v_0: Ast.SyntaxTerm, +v_2: String) -> FeedbackControl:
  match v_0:
    case Ast.TermVar{v_6, v_7, v_8}:
      feedback_pack_11(Ast.TermVar{v_6, v_7, v_8})
    case Ast.TermRef{v_11, v_12}:
      feedback_pack_11(Ast.TermRef{map_operator_key(v_2, v_11), v_12})
    case Ast.TermBang{v_15, v_16}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_15, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_95827(v_16))
    case Ast.TermSub{v_22, v_23, v_24, v_25}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_23, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_95975(v_2, v_22, v_24, v_25))
    case Ast.TermLet{v_34, v_35, v_36, v_37, v_38, v_39}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_terms(v_37, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_96147(v_2, v_34, v_35, v_36, v_38, v_39))
    case Ast.TermAnn{v_44, v_45, v_46}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_44, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_96284(v_2, v_45, v_46))
    case Ast.TermTemplate{v_50, v_51}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_50, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_96408(v_51))
    case Ast.TermType{v_55, v_56}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_55, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_96528(v_56))
    case Ast.TermQuant{}:
      feedback_pack_11(Ast.TermQuant{})
    case Ast.TermQuantity{v_60, v_61}:
      feedback_pack_11(Ast.TermQuantity{v_60, v_61})
    case Ast.TermMin{v_65, v_66, v_67}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_65, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_96786(v_2, v_66, v_67))
    case Ast.TermAll{v_76, v_77, v_78, v_79, v_80, v_81}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_79, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_96958(v_2, v_76, v_77, v_78, v_80, v_81))
    case Ast.TermLam{v_89, v_90, v_91, v_92, v_93}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_92, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_97113(v_89, v_90, v_91, v_93))
    case Ast.TermApp{v_98, v_99, v_100}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_98, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_97251(v_2, v_99, v_100))
    case Ast.TermAdt{v_107, v_108, v_109, v_110}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_terms(v_108, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_97401(v_107, v_109, v_110))
    case Ast.TermFill{v_115, v_116, v_117}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_115, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_97545(v_2, v_116, v_117))
    case Ast.TermPlus{v_123, v_124, v_125}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_123, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_97688(v_2, v_124, v_125))
    case Ast.TermCtr{v_131, v_132, v_133}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_terms(v_132, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_97825(v_131, v_133))
    case Ast.TermString{v_138, v_139, v_140}:
      feedback_pack_11(Ast.TermString{v_138, v_139, v_140})
    case Ast.TermMat{v_145, v_146, v_147, v_148}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_146, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_98070(v_2, v_145, v_147, v_148))
    case Ast.TermAbsurd{v_152}:
      feedback_pack_11(Ast.TermAbsurd{v_152})
    case Ast.TermEqual{v_157, v_158, v_159, v_160}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_157, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_98288(v_2, v_158, v_159, v_160))
    case Ast.TermRefl{v_165}:
      feedback_pack_11(Ast.TermRefl{v_165})
    case Ast.TermRewrite{v_170, v_171, v_172, v_173}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_170, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_98504(v_2, v_171, v_172, v_173))
    case Ast.TermHole{v_179, v_180}:
      feedback_pack_11(Ast.TermHole{v_179, v_180})
    case Ast.BodyMatch{v_184, v_185, v_186}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_terms(v_184, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_98718(v_2, v_185, v_186))
    case Ast.BodyCase{v_192, v_193, v_194}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_193, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_98857(v_192, v_194))
    case Ast.BodyLocal{v_201, v_202, v_203, v_204, v_205}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_terms(v_203, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_99029(v_2, v_201, v_202, v_204, v_205))
    case Ast.BodyReply{v_209, v_210}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_209, v_2)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_99155(v_210))

def feedback_make_Kont_99780(capture_0: String, capture_1: List<&2, Ast.SyntaxTerm>) -> FeedbackFrame:
  Kont_99780{capture_0, capture_1}

def feedback_pack_12(result: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  FeedbackControl{FeedbackDone{Value_12{result}}, Nil{}, NoProgress{}, NoProgress{}}

def step_map_operator_terms(v_1: List<&2, Ast.SyntaxTerm>, +v_3: String) -> FeedbackControl:
  match v_1:
    case []:
      feedback_pack_12([])
    case v_7 <> v_8:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(v_7, v_3)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_99780(v_3, v_8))

def feedback_pack_15(result: Maybe<&2, Nat>) -> FeedbackControl:
  FeedbackControl{FeedbackDone{Value_15{result}}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_make_Kont_80664(capture_1: Nat) -> FeedbackFrame:
  Kont_80664{capture_1}

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

def step_nat_literal_tokens_plus(adjacent: Bool, tokens: List<&2, Lexer.Token>, value: Nat, stop: Nat) -> FeedbackControl:
  match adjacent:
    case True{}:
      feedback_attach(step_nat_literal_tokens(tokens, stop), feedback_make_Kont_80664(value))
    case False{}:
      feedback_pack_15(None{})

def step_nat_literal_tokens_next(done: Bool, token: Lexer.Token, +more: List<&2, Lexer.Token>, +value: Nat, +end: Nat, +stop: Nat) -> FeedbackControl:
  match done:
    case True{}:
      feedback_pack_15(Some{value})
    case False{}:
      match token:
        case Lexer.TokenInfo{Lexer.NewlineToken{}, _, _, _, _, _}:
          step_nat_literal_tokens_value(Some{value}, end, more, stop)
        case Lexer.TokenInfo{Lexer.SymbolToken{}, ")", _, _, _, _}:
          step_nat_literal_tokens_value(Some{value}, end, more, stop)
        case Lexer.TokenInfo{Lexer.SymbolToken{}, "+", +beg, _, _, _}:
          step_nat_literal_tokens_plus(Nat.is_eq(beg, end), more, value, stop)
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

def character_term(+file: String, value: Nat, +beg: Nat, +end: Nat) -> Ast.SyntaxTerm:
  Ast.TermCtr{ "Chr",  [u32_literal(file, value, beg, end)],  span(file, beg, end)}

def escape_code_value(code: Nat) -> Maybe<&2, Nat>:
  match code:
    case 110n:
      Some{10n}
    case 116n:
      Some{9n}
    case 114n:
      Some{13n}
    case 48n:
      Some{0n}
    case 92n:
      Some{92n}
    case 39n:
      Some{39n}
    case 34n:
      Some{34n}
    case _:
      None{}

def escape_code(char: Char) -> Maybe<&2, Nat>:
  escape_code_value(U32.to_nat(Char.to_u32(char)))

def parse_char_literal_unicode_result(result: (Nat & List<&2, Char>) & Bool, file: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((value, Nil{}), True{}):
      ((character_term(file, value, beg, end), rest), True{})
    case _:
      ((Ast.TermHole{"parse-error: invalid unicode character escape", span(file, beg, end)}, rest), False{})

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

def parse_char_literal_escape_codepoint(code: Nat, after_escape: List<&2, Char>, file: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match code:
    case 117n:
      parse_char_literal_unicode_result(parse_unicode_escape(after_escape, 0n), file, beg, end, rest)
    case _:
      ((Ast.TermHole{"parse-error: invalid character escape", span(file, beg, end)}, rest), False{})

def parse_char_literal_plain_tail(tail: List<&2, Char>, term: Ast.SyntaxTerm, file: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match tail:
    case Nil{}:
      ((term, rest), True{})
    case _:
      ((Ast.TermHole{ "parse-error: invalid character literal",  span(file, beg, end)}, rest), False{})

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

def parse_char_literal(file: String, text: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_char_literal_chars(String.to_list(strip_quotes(text)), file, beg, end, rest)

def parse_string_result(result: Ast.SyntaxTerm & Bool, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case (term, ok):
      ((term, rest), ok)

def string_chars_after_char(is_escape: Bool, char: Char) -> StringCharsInput:
  match is_escape:
    case True{}:
      StringCharsBackslash{}
    case False{}:
      StringCharsText{char}

def string_chars_cons_result(result: Ast.SyntaxTerm & Bool, chr: U32, +file: String, +beg: Nat, +end: Nat) -> Ast.SyntaxTerm & Bool:
  match result:
    case (Ast.TermString{chars, names, literal_span}, ok):
      (Ast.TermString{chr <> chars, names, literal_span}, ok)
    case (next, ok):
      (Ast.TermCtr{"SCon", [Ast.string_character(chr, Ast.string_literal_names(), span(file, beg, end)), next], span(file, beg, end)}, ok)

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
      StringCharsUnicodeDigits{((acc * 16n : Nat) + digit : Nat)}
    case None{}:
      StringCharsInvalidUnicode{}

def string_chars_unicode_result(code: Nat, result: Maybe<&2, Nat>, acc: Nat) -> StringCharsInput:
  match code:
    case 125n:
      StringCharsValue{acc}
    case _:
      string_chars_unicode_digit_result(result, acc)

def string_codepoint_bit(bit: Nat, value: U32) -> U32:
  match bit:
    case 0n:
      value
    case _:
      U32.inc(value)

def string_codepoint(remaining: Nat, +value: Nat) -> U32:
  match remaining:
    case 0n:
      0
    case 1n+rest:
      +upper = string_codepoint(rest, Nat.div(value, 2n))
      string_codepoint_bit(Nat.mod(value, 2n), U32.add(upper, upper))

def string_chars_go(+file: String, remaining: List<&2, Char>, +input: StringCharsInput, +beg: Nat, +end: Nat) -> Ast.SyntaxTerm & Bool:
  match remaining:
    case Nil{}:
      match input:
        case StringCharsText{+char}:
          string_chars_cons_result((Ast.TermString{Nil{}, Ast.string_literal_names(), span(file, beg, end)}, True{}), Char.to_u32(char), file, beg, end)
        case StringCharsBackslash{}:
          (Ast.TermHole{"parse-error: incomplete string escape", span(file, beg, end)}, False{})
        case StringCharsValue{+value}:
          string_chars_cons_result((Ast.TermString{Nil{}, Ast.string_literal_names(), span(file, beg, end)}, True{}), string_codepoint(32n, value), file, beg, end)
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
          string_chars_cons_result(string_chars_go(file, tail, string_chars_after_char(Char.is_eq(next, Char.from_u32(92)), next), beg, end), Char.to_u32(char), file, beg, end)
        case StringCharsBackslash{}:
          string_chars_go(file, tail, string_chars_escape_result(escape_code(next), U32.to_nat(Char.to_u32(next))), beg, end)
        case StringCharsValue{+value}:
          string_chars_cons_result(string_chars_go(file, tail, string_chars_after_char(Char.is_eq(next, Char.from_u32(92)), next), beg, end), string_codepoint(32n, value), file, beg, end)
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
      (Ast.TermString{Nil{}, Ast.string_literal_names(), span(file, beg, end)}, True{})
    case +char <> rest:
      string_chars_go(file, rest, string_chars_after_char(Char.is_eq(char, Char.from_u32(92)), char), beg, end)

def parse_string(file: String, text: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_string_result(string_chars(file, String.to_list(strip_quotes(text)), beg, end), rest)

def feedback_make_Kont_182131(capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Lexer.Token>) -> FeedbackFrame:
  Kont_182131{capture_1, capture_2, capture_3, capture_4}

def feedback_make_Kont_180515(capture_1: String, capture_2: String, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Lexer.Token>, capture_6: List<&2, Scope>, capture_7: Nat) -> FeedbackFrame:
  Kont_180515{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7}

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

def feedback_make_Kont_188724(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Nat, capture_5: Nat) -> FeedbackFrame:
  Kont_188724{capture_1, capture_2, capture_3, capture_4, capture_5}

def feedback_make_parse_do_typed_bind(file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> FeedbackRequest:
  Request_parse_do_typed_bind{file, monad, args, tokens, beg, end, scope, depth, col}

def feedback_make_Kont_247908(lexical_capture_1: String, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat, lexical_capture_10: Nat, lexical_capture_3: List<&2, Lexer.Token>) -> FeedbackFrame:
  Kont_247908{lexical_capture_1, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_3}

def feedback_make_parse_atom_scan(file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackRequest:
  Request_parse_atom_scan{file, tokens, scanned, scope, depth}

def step_parse_atom(file: String, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  FeedbackControl{FeedbackCall{feedback_make_parse_atom_scan(file, tokens, skip_lines(tokens), scope, depth)}, Nil{}, NoProgress{}, NoProgress{}}

def step_parse_term(+file: String, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, level: Nat) -> FeedbackControl:
  feedback_attach(step_parse_atom(file, tokens, scope, depth), feedback_make_Kont_247908(file, scope, depth, level, tokens))

def step_parse_do_return_scan(+file: String, +key: String, +args: List<&2, Ast.SyntaxTerm>, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +beg: Nat, +end: Nat, +scope: List<&2, Scope>, +depth: Nat, col: Nat) -> FeedbackControl:
  match scanned:
    case +return_token <> +rest:
      match return_token:
        case Lexer.TokenInfo{Lexer.NameToken{}, "return", _, _, _, _}:
          feedback_attach(step_parse_term(file, rest, scope, depth, 0n), feedback_make_Kont_188724(file, key, args, beg, end))
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

def feedback_make_Kont_238873(lexical_capture_3: String, lexical_capture_8: List<&2, Lexer.Token>, lexical_capture_10: String, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: List<&2, Ast.SyntaxTerm>) -> FeedbackFrame:
  Kont_238873{lexical_capture_3, lexical_capture_8, lexical_capture_10, lexical_capture_13, lexical_capture_15, lexical_capture_17}

def step_parse_term_args_first(is_close: Bool, +file: String, token: Lexer.Token, rest: List<&2, Lexer.Token>, +tokens: List<&2, Lexer.Token>, close: String, +scope: List<&2, Scope>, +depth: Nat, +acc: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match is_close:
    case True{}:
      feedback_pack_9(((List.reverse(&2, Ast.SyntaxTerm, acc), rest), True{}))
    case False{}:
      feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_238873(file, tokens, close, scope, depth, acc))

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

def step_parse_do_atom(+file: String, +tokens: List<&2, Lexer.Token>, +beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match tokens:
    case +monad <> +rest:
      match monad:
        case Lexer.TokenInfo{Lexer.NameToken{}, +key, _, +end, _, _}:
          match rest:
            case +open <> +after_open:
              match open:
                case Lexer.TokenInfo{_, "<", _, _, _, _}:
                  feedback_attach(step_parse_term_args(file, after_open, ">", scope, depth, Nil{}), feedback_make_Kont_180515(file, key, beg, end, tokens, scope, depth))
                case Lexer.TokenInfo{_, "<>", _, _, _, _}:
                  step_parse_do_atom_args_result(((Nil{}, after_open), True{}), file, key, beg, end, tokens, scope, depth)
                case Lexer.TokenInfo{+feedback_field_12_0, +feedback_field_12_1, +feedback_field_12_2, +feedback_field_12_3, +feedback_field_12_4, +feedback_field_12_5}:
                  feedback_pack_5(((Ast.TermHole{"parse-error: expected < after do monad", span(file, token_beg((Lexer.TokenInfo{feedback_field_12_0, feedback_field_12_1, feedback_field_12_2, feedback_field_12_3, feedback_field_12_4, feedback_field_12_5} : Lexer.Token)), token_end((Lexer.TokenInfo{feedback_field_12_0, feedback_field_12_1, feedback_field_12_2, feedback_field_12_3, feedback_field_12_4, feedback_field_12_5} : Lexer.Token)))}, rest), False{}))
            case Nil{}:
              feedback_pack_5(((Ast.TermHole{"parse-error: expected do monad parameters", span(file, end, end)}, rest), False{}))
        case Lexer.TokenInfo{+feedback_field_16_0, +feedback_field_16_1, +feedback_field_16_2, +feedback_field_16_3, +feedback_field_16_4, +feedback_field_16_5}:
          feedback_pack_5(((Ast.TermHole{"parse-error: expected do monad", span(file, token_beg((Lexer.TokenInfo{feedback_field_16_0, feedback_field_16_1, feedback_field_16_2, feedback_field_16_3, feedback_field_16_4, feedback_field_16_5} : Lexer.Token)), token_end((Lexer.TokenInfo{feedback_field_16_0, feedback_field_16_1, feedback_field_16_2, feedback_field_16_3, feedback_field_16_4, feedback_field_16_5} : Lexer.Token)))}, tokens), False{}))
    case Nil{}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected do monad", span(file, beg, beg)}, Nil{}), False{}))

def extend_scope_result(is_underscore: Bool, key: String, index: Nat, scope: List<&2, Scope>) -> List<&2, Scope>:
  match is_underscore:
    case True{}:
      scope
    case False{}:
      Scope{key, index} <> scope

def extend_scope(+key: String, index: Nat, scope: List<&2, Scope>) -> List<&2, Scope>:
  extend_scope_result(String.eq(key, "_"), key, index, scope)

def feedback_make_Kont_235238(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_14: Nat) -> FeedbackFrame:
  Kont_235238{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_14}

def feedback_make_Kont_235478(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_20: List<&2, Lexer.Token>) -> FeedbackFrame:
  Kont_235478{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_20}

def lookup_result(+key: String, rest: List<&2, Scope>, +depth: Nat) -> Maybe<&2, Nat>:
  match rest:
    case +entry <> after:
      match entry:
        case Scope{ found, index}:
          Bool.pick(Maybe<&2, Nat>, String.eq(key, found), Some{((depth - index : Nat) - 1n : Nat)}, lookup_result(key, after, depth))
    case Nil{}:
      None{}

def lookup(+key: String, scope: List<&2, Scope>, +depth: Nat) -> Maybe<&2, Nat>:
  match scope:
    case +entry <> rest:
      match entry:
        case Scope{ found, index}:
          Bool.pick(Maybe<&2, Nat>, String.eq(key, found), Some{((depth - index : Nat) - 1n : Nat)}, lookup_result(key, rest, depth))
    case Nil{}:
      None{}

def parse_name_term_lookup(found: Maybe<&2, Nat>, file: String, key: String, beg: Nat, end: Nat, tokens: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match found:
    case Some{index}:
      ((Ast.TermVar{key, index,  span(file, beg, end)}, tokens), True{})
    case None{}:
      ((Ast.TermRef{key,  span(file, beg, end)}, tokens), True{})

def feedback_make_parse_body_scan(file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, parent_col: Nat) -> FeedbackRequest:
  Request_parse_body_scan{file, tokens, scanned, scope, depth, parent_col}

def step_parse_body(file: String, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, parent_col: Nat) -> FeedbackControl:
  FeedbackControl{FeedbackCall{feedback_make_parse_body_scan(file, tokens, skip_lines(tokens), scope, depth, parent_col)}, Nil{}, NoProgress{}, NoProgress{}}

def step_parse_lambda_block_scan(+file: String, +tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match scanned:
    case Lexer.TokenInfo{_, _, _, _, _, col} <> _:
      step_parse_body(file, tokens, scope, depth, Nat.sub(col, 1n))
    case Nil{}:
      step_parse_term(file, tokens, scope, depth, 0n)

def step_parse_lambda_block(+file: String, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  step_parse_lambda_block_scan(file, tokens, skip_lines(tokens), scope, depth)

def step_parse_name_term(+file: String, +key: String, +beg: Nat, +end: Nat, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match tokens:
    case +next <> +rest:
      match next:
        case Lexer.TokenInfo{ _, "=>",  _,  _,  _,  _}:
          next_scope = extend_scope(key, depth, scope)
          feedback_attach(step_parse_lambda_block(file, rest, next_scope, (depth + 1n : Nat)), feedback_make_Kont_235238(file, key, beg, end, depth))
        case Lexer.TokenInfo{ _, "{",  _,  _,  _,  _}:
          feedback_attach(step_parse_term_args(file, rest, "}", scope, depth, Nil{}), feedback_make_Kont_235478(file, key, beg, end, rest))
        case _:
          feedback_pack_5(parse_name_term_lookup(lookup(key, scope, depth), file, key, beg, end, tokens))
    case Nil{}:
      feedback_pack_5(parse_name_term_lookup(lookup(key, scope, depth), file, key, beg, end, Nil{}))

def step_parse_atom_name_dispatch(text: String, +file: String, +scope: List<&2, Scope>, +depth: Nat, +rest: List<&2, Lexer.Token>, +beg: Nat, +end: Nat) -> FeedbackControl:
  match text:
    case "do":
      step_parse_do_atom(file, rest, beg, scope, depth)
    case "Type":
      feedback_pack_5(((Ast.TermType{ Ast.TermQuantity{ Ast.QOne{},  span(file, beg, end)},  span(file, beg, end)}, rest), True{}))
    case "Data":
      feedback_pack_5(((Ast.TermType{ Ast.TermQuantity{ Ast.QMany{},  span(file, beg, end)},  span(file, beg, end)}, rest), True{}))
    case "Quant":
      feedback_pack_5(((Ast.TermQuant{}, rest), True{}))
    case "Kind":
      match rest:
        case +open <> +more:
          match open:
            case Lexer.TokenInfo{ _, "(",  _,  _,  _,  _}:
              feedback_attach(step_parse_term(file, more, scope, depth, 0n), feedback_make_Kont_182131(file, beg, end, rest))
            case _:
              feedback_pack_5(((Ast.TermHole{ "parse-error: expected (",  span(file, beg, end)}, rest), False{}))
        case Nil{}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected (",  span(file, beg, end)}, rest), False{}))
    case SNil{}:
      step_parse_name_term(file, (SNil{} : String), beg, end, rest, scope, depth)
    case SCon{feedback_field_20_0, feedback_field_20_1}:
      step_parse_name_term(file, (SCon{feedback_field_20_0, feedback_field_20_1} : String), beg, end, rest, scope, depth)

def parse_atom_symbol_row_0(rest: List<&2, Lexer.Token>, +file: String, beg: Nat, end: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  match rest:
    case +name <> tail:
      match name:
        case Lexer.TokenInfo{ Lexer.NameToken{},  key,  _,  fin,  _,  _}:
          ((Ast.TermHole{key,  span(file, beg, fin)}, tail), True{})
        case _:
          ((Ast.TermHole{ "parse-error: expected a hole name",  span(file, beg, end)}, rest), False{})
    case Nil{}:
      ((Ast.TermHole{ "parse-error: expected a hole name",  span(file, beg, end)}, rest), False{})

def parse_atom_symbol_row_10(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected a term",  span(file, beg, end)}, tokens), False{})

def feedback_make_Kont_203834(capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Scope>, capture_5: Nat) -> FeedbackFrame:
  Kont_203834{capture_1, capture_2, capture_3, capture_4, capture_5}

def step_parse_list(+file: String, +tokens: List<&2, Lexer.Token>, +beg: Nat, +end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match tokens:
    case +close <> after_close:
      match close:
        case Lexer.TokenInfo{_, "]", _, _, _, _}:
          feedback_pack_5(((Ast.TermCtr{"Nil", Nil{}, span(file, beg, token_end(close))}, after_close), True{}))
        case Lexer.TokenInfo{feedback_field_6_0, feedback_field_6_1, feedback_field_6_2, feedback_field_6_3, feedback_field_6_4, feedback_field_6_5}:
          feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_203834(file, beg, token_end((Lexer.TokenInfo{feedback_field_6_0, feedback_field_6_1, feedback_field_6_2, feedback_field_6_3, feedback_field_6_4, feedback_field_6_5} : Lexer.Token)), scope, depth))
    case Nil{}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected ]", span(file, end, end)}, Nil{}), False{}))

def step_parse_atom_symbol_row_1(+file: String, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat, end: Nat) -> FeedbackControl:
  step_parse_list(file, rest, beg, end, scope, depth)

def feedback_make_Kont_209330(capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Lexer.Token>, capture_5: Nat, capture_6: List<&2, Scope>, capture_7: Nat) -> FeedbackFrame:
  Kont_209330{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7}

def step_parse_parenthesized(+file: String, +tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term_args(file, tokens, ")", scope, depth, Nil{}), feedback_make_Kont_209330(file, beg, end, tokens, col, scope, depth))

def step_parse_atom_symbol_row_2(+file: String, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat, end: Nat, col: Nat) -> FeedbackControl:
  step_parse_parenthesized(file, rest, beg, end, col, scope, depth)

def feedback_make_Kont_230983(lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_10: List<&2, Scope>, lexical_capture_12: Nat) -> FeedbackFrame:
  Kont_230983{lexical_capture_1, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_12}

def step_parse_rewrite(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_230983(file, beg, end, scope, depth))

def step_parse_atom_symbol_row_3(+file: String, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat, end: Nat) -> FeedbackControl:
  step_parse_rewrite(file, rest, beg, end, scope, depth)

def feedback_make_Kont_242754(lexical_capture_1: String, lexical_capture_23: String, lexical_capture_25: Nat, lexical_capture_10: Nat, lexical_capture_11: Ast.Quantity, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat) -> FeedbackFrame:
  Kont_242754{lexical_capture_1, lexical_capture_23, lexical_capture_25, lexical_capture_10, lexical_capture_11, lexical_capture_6, lexical_capture_8}

def step_parse_all_named(+file: String, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +beg: Nat, quantity: Ast.Quantity) -> FeedbackControl:
  match tokens:
    case +name <> +rest:
      match name:
        case Lexer.TokenInfo{ Lexer.NameToken{},  key,  _,  +key_end,  _,  _}:
          match rest:
            case +colon <> after_colon:
              match colon:
                case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
                  feedback_attach(step_parse_term(file, after_colon, scope, depth, 1n), feedback_make_Kont_242754(file, key, key_end, beg, quantity, scope, depth))
                case Lexer.TokenInfo{+feedback_field_10_0, +feedback_field_10_1, +feedback_field_10_2, +feedback_field_10_3, +feedback_field_10_4, +feedback_field_10_5}:
                  feedback_pack_5(((Ast.TermHole{ "parse-error: expected :",  span(file, token_beg((Lexer.TokenInfo{feedback_field_10_0, feedback_field_10_1, feedback_field_10_2, feedback_field_10_3, feedback_field_10_4, feedback_field_10_5} : Lexer.Token)), token_end((Lexer.TokenInfo{feedback_field_10_0, feedback_field_10_1, feedback_field_10_2, feedback_field_10_3, feedback_field_10_4, feedback_field_10_5} : Lexer.Token)))}, rest), False{}))
            case Nil{}:
              feedback_pack_5(((Ast.TermHole{ "parse-error: expected :",  span(file, beg, key_end)}, rest), False{}))
        case Lexer.TokenInfo{feedback_field_14_0, feedback_field_14_1, feedback_field_14_2, feedback_field_14_3, feedback_field_14_4, feedback_field_14_5}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a binder",  span(file, beg, token_end((Lexer.TokenInfo{feedback_field_14_0, feedback_field_14_1, feedback_field_14_2, feedback_field_14_3, feedback_field_14_4, feedback_field_14_5} : Lexer.Token)))}, tokens), False{}))
    case Nil{}:
      feedback_pack_5(((Ast.TermHole{ "parse-error: expected a binder",  span(file, beg, beg)}, Nil{}), False{}))

def step_parse_all(+file: String, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +beg: Nat) -> FeedbackControl:
  # An unmarked dependent binder is linear; only its own + or - overrides it.
  match tokens:
    case +prefix <> +rest:
      match prefix:
        case Lexer.TokenInfo{ _, "+",  _,  _,  _,  _}:
          step_parse_all_named(file, rest, scope, depth, beg, Ast.QMany{})
        case Lexer.TokenInfo{ _, "-",  _,  _,  _,  _}:
          step_parse_all_named(file, rest, scope, depth, beg, Ast.QZero{})
        case _:
          step_parse_all_named(file, tokens, scope, depth, beg, Ast.QOne{})
    case Nil{}:
      step_parse_all_named(file, Nil{}, scope, depth, beg, Ast.QOne{})

def step_parse_atom_symbol_row_4(+file: String, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat) -> FeedbackControl:
  step_parse_all(file, rest, scope, depth, beg)

def step_parse_amp(+file: String, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +beg: Nat, end: Nat) -> FeedbackControl:
  match tokens:
    case +quantity <> +rest:
      match quantity:
        case Lexer.TokenInfo{ _, "0",  _,  _,  _,  _}:
          feedback_pack_5(((Ast.TermQuantity{ Ast.QZero{},  span(file, beg, token_end(quantity))}, rest), True{}))
        case Lexer.TokenInfo{ _, "1",  _,  _,  _,  _}:
          feedback_pack_5(((Ast.TermQuantity{ Ast.QOne{},  span(file, beg, token_end(quantity))}, rest), True{}))
        case Lexer.TokenInfo{ _, "2",  _,  _,  _,  _}:
          feedback_pack_5(((Ast.TermQuantity{ Ast.QMany{},  span(file, beg, token_end(quantity))}, rest), True{}))
        case _:
          step_parse_all(file, tokens, scope, depth, beg)
    case Nil{}:
      step_parse_all(file, Nil{}, scope, depth, beg)

def step_parse_atom_symbol_row_5(+file: String, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat, end: Nat) -> FeedbackControl:
  step_parse_amp(file, rest, scope, depth, beg, end)

def feedback_make_Kont_244006(lexical_capture_1: String, lexical_capture_22: String, lexical_capture_5: Nat, lexical_capture_24: Nat, lexical_capture_10: Nat) -> FeedbackFrame:
  Kont_244006{lexical_capture_1, lexical_capture_22, lexical_capture_5, lexical_capture_24, lexical_capture_10}

def feedback_make_Kont_245814(lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat) -> FeedbackFrame:
  Kont_245814{lexical_capture_1, lexical_capture_5, lexical_capture_14, lexical_capture_16}

def step_parse_plus_sugar(+file: String, key: String, beg: Nat, name_beg: Nat, name_end: Nat, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_name_term(file, key, name_beg, name_end, tokens, scope, depth), feedback_make_Kont_245814(file, beg, scope, depth))

def step_parse_many_lambda(+file: String, +tokens: List<&2, Lexer.Token>, +beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match tokens:
    case +name <> +rest:
      match name:
        case Lexer.TokenInfo{ Lexer.NameToken{},  +key,  +name_beg, +end,  _,  _}:
          match rest:
            case +arrow <> after_arrow:
              match arrow:
                case Lexer.TokenInfo{ _, "=>",  _,  _,  _,  _}:
                  next_scope = extend_scope(key, depth, scope)
                  feedback_attach(step_parse_lambda_block(file, after_arrow, next_scope, (depth + 1n : Nat)), feedback_make_Kont_244006(file, key, beg, end, depth))
                case _:
                  step_parse_plus_sugar(file, key, beg, name_beg, end, rest, scope, depth)
            case Nil{}:
              step_parse_plus_sugar(file, key, beg, name_beg, end, rest, scope, depth)
        case Lexer.TokenInfo{+feedback_field_15_0, +feedback_field_15_1, +feedback_field_15_2, +feedback_field_15_3, +feedback_field_15_4, +feedback_field_15_5}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a binder after +",  span(file, token_beg((Lexer.TokenInfo{feedback_field_15_0, feedback_field_15_1, feedback_field_15_2, feedback_field_15_3, feedback_field_15_4, feedback_field_15_5} : Lexer.Token)), token_end((Lexer.TokenInfo{feedback_field_15_0, feedback_field_15_1, feedback_field_15_2, feedback_field_15_3, feedback_field_15_4, feedback_field_15_5} : Lexer.Token)))}, tokens), False{}))
    case Nil{}:
      feedback_pack_5(((Ast.TermHole{ "parse-error: expected a binder after +",  span(file, beg, beg)}, Nil{}), False{}))

def step_parse_atom_symbol_row_6(+file: String, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat) -> FeedbackControl:
  step_parse_many_lambda(file, rest, beg, scope, depth)

def feedback_make_Kont_214756(capture_1: String, capture_2: String, capture_3: Nat, capture_4: List<&2, Scope>, capture_5: Nat) -> FeedbackFrame:
  Kont_214756{capture_1, capture_2, capture_3, capture_4, capture_5}

def feedback_make_Kont_219930(lexical_capture_1: String) -> FeedbackFrame:
  Kont_219930{lexical_capture_1}

def step_parse_match_tail(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_219930(file))

def step_parse_match_expr_after_name(+file: String, +original: List<&2, Lexer.Token>, key: String, scanned: List<&2, Lexer.Token>, +beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match scanned:
    case +colon <> after_colon:
      match colon:
        case Lexer.TokenInfo{_, ":", _, _, _, _}:
          feedback_attach(step_parse_term(file, after_colon, scope, depth, 0n), feedback_make_Kont_214756(file, key, beg, scope, depth))
        case _:
          step_parse_match_tail(file, original, beg, scope, depth)
    case Nil{}:
      step_parse_match_tail(file, original, beg, scope, depth)

def step_parse_match_expr_scan(+file: String, +tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +beg: Nat, +end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match scanned:
    case +name <> after_name:
      match name:
        case Lexer.TokenInfo{ Lexer.NameToken{},  key,  _,  _,  _,  _}:
          step_parse_match_expr_after_name(file, tokens, key, skip_lines(after_name), beg, scope, depth)
        case _:
          step_parse_match_tail(file, tokens, beg, scope, depth)
    case Nil{}:
      feedback_pack_5(((Ast.TermHole{ "parse-error: expected a match tail",  span(file, end, end)}, Nil{}), False{}))

def step_parse_match_expr(file: String, +tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  step_parse_match_expr_scan(file, tokens, skip_lines(tokens), beg, end, scope, depth)

def step_parse_absurd(+file: String, +tokens: List<&2, Lexer.Token>, +beg: Nat, +end: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match tokens:
    case +open <> +rest:
      match open:
        case Lexer.TokenInfo{ _, "{",  _,  _,  _,  _}:
          match rest:
            case +close <> tail:
              match close:
                case Lexer.TokenInfo{ _, "}",  _,  _,  _,  _}:
                  feedback_pack_5(((Ast.TermAbsurd{ span(file, beg, token_end(close))}, tail), True{}))
                case _:
                  step_parse_match_expr(file, rest, beg, end, scope, depth)
            case Nil{}:
              feedback_pack_5(((Ast.TermHole{ "parse-error: expected }",  span(file, end, end)}, rest), False{}))
        case Lexer.TokenInfo{+feedback_field_14_0, +feedback_field_14_1, +feedback_field_14_2, +feedback_field_14_3, +feedback_field_14_4, +feedback_field_14_5}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected { after backslash",  span(file, token_beg((Lexer.TokenInfo{feedback_field_14_0, feedback_field_14_1, feedback_field_14_2, feedback_field_14_3, feedback_field_14_4, feedback_field_14_5} : Lexer.Token)), token_end((Lexer.TokenInfo{feedback_field_14_0, feedback_field_14_1, feedback_field_14_2, feedback_field_14_3, feedback_field_14_4, feedback_field_14_5} : Lexer.Token)))}, tokens), False{}))
    case Nil{}:
      feedback_pack_5(((Ast.TermHole{ "parse-error: expected { after backslash",  span(file, end, end)}, Nil{}), False{}))

def step_parse_atom_symbol_row_7(+file: String, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat, end: Nat) -> FeedbackControl:
  step_parse_absurd(file, rest, beg, end, scope, depth)

def feedback_make_Kont_188212(capture_1: String, capture_2: Nat) -> FeedbackFrame:
  Kont_188212{capture_1, capture_2}

def step_parse_template_term(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, tokens, scope, depth, 12n), feedback_make_Kont_188212(file, beg))

def step_parse_atom_symbol_row_8(+file: String, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat) -> FeedbackControl:
  step_parse_template_term(file, rest, beg, scope, depth)

def feedback_make_Kont_226118(lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_10: List<&2, Scope>, lexical_capture_12: Nat) -> FeedbackFrame:
  Kont_226118{lexical_capture_1, lexical_capture_5, lexical_capture_10, lexical_capture_12}

def step_parse_brace(+file: String, +tokens: List<&2, Lexer.Token>, +beg: Nat, +end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match tokens:
    case +first <> +after_first:
      match first:
        case Lexer.TokenInfo{ _, "==",  _,  _,  _,  _}:
          match after_first:
            case +close <> tail:
              match close:
                case Lexer.TokenInfo{ _, "}",  _,  _,  _,  _}:
                  feedback_pack_5(((Ast.TermRefl{ span(file, beg, token_end(close))}, tail), True{}))
                case Lexer.TokenInfo{+feedback_field_10_0, +feedback_field_10_1, +feedback_field_10_2, +feedback_field_10_3, +feedback_field_10_4, +feedback_field_10_5}:
                  feedback_pack_5(((Ast.TermHole{ "parse-error: expected }",  span(file, token_beg((Lexer.TokenInfo{feedback_field_10_0, feedback_field_10_1, feedback_field_10_2, feedback_field_10_3, feedback_field_10_4, feedback_field_10_5} : Lexer.Token)), token_end((Lexer.TokenInfo{feedback_field_10_0, feedback_field_10_1, feedback_field_10_2, feedback_field_10_3, feedback_field_10_4, feedback_field_10_5} : Lexer.Token)))}, after_first), False{}))
            case Nil{}:
              feedback_pack_5(((Ast.TermHole{ "parse-error: expected }",  span(file, end, end)}, after_first), False{}))
        case _:
          feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_226118(file, beg, scope, depth))
    case Nil{}:
      feedback_pack_5(((Ast.TermHole{ "parse-error: expected a term or ==}",  span(file, end, end)}, Nil{}), False{}))

def step_parse_atom_symbol_row_9(+file: String, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat, end: Nat) -> FeedbackControl:
  step_parse_brace(file, rest, beg, end, scope, depth)

def step_parse_atom_symbol_dispatch(text: String, +file: String, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +rest: List<&2, Lexer.Token>, +beg: Nat, +end: Nat, col: Nat) -> FeedbackControl:
  match text:
    case "?":
      feedback_pack_5(parse_atom_symbol_row_0(rest, file, beg, end))
    case "[":
      step_parse_atom_symbol_row_1(file, scope, depth, rest, beg, end)
    case "(":
      step_parse_atom_symbol_row_2(file, scope, depth, rest, beg, end, col)
    case "%":
      step_parse_atom_symbol_row_3(file, scope, depth, rest, beg, end)
    case "@":
      step_parse_atom_symbol_row_4(file, scope, depth, rest, beg)
    case "&":
      step_parse_atom_symbol_row_5(file, scope, depth, rest, beg, end)
    case "+":
      step_parse_atom_symbol_row_6(file, scope, depth, rest, beg)
    case "\\":
      step_parse_atom_symbol_row_7(file, scope, depth, rest, beg, end)
    case "~":
      step_parse_atom_symbol_row_8(file, scope, depth, rest, beg)
    case "{":
      step_parse_atom_symbol_row_9(file, scope, depth, rest, beg, end)
    case _:
      feedback_pack_5(parse_atom_symbol_row_10(file, tokens, beg, end))

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

def encode_float_normal_bits(+significand: Nat, negative_exponent: Bool, exponent: Nat) -> Nat & Bool:
  encode_float_normal_rounding_limit(Nat.is_lt(significand, 16777216n), significand, negative_exponent, exponent)

def float_nat_cons(rest: List<&2, Nat>, limb: Nat) -> List<&2, Nat>:
  match rest:
    case Nil{}:
      match limb:
        case 0n:
          Nil{}
        case _:
          [limb]
    case _:
      limb <> rest

def float_nat_sub_limb(underflows: Bool, limb: Nat, remove: Nat) -> Nat:
  match underflows:
    case True{}:
      ((limb + 16777216n : Nat) - remove : Nat)
    case False{}:
      (limb - remove : Nat)

# Subtraction callers establish a >= b before passing a borrow.

def float_nat_sub_go(a: List<&2, Nat>, b: List<&2, Nat>, +borrow: Nat) -> List<&2, Nat>:
  match a b:
    case Nil{} Nil{}:
      Nil{}
    case Nil{} _ <> _:
      Nil{}
    case +limb <> a_rest Nil{}:
      +underflows = Nat.is_lt(limb, borrow)
      next = float_nat_sub_limb(underflows, limb, borrow)
      next_borrow = U32.to_nat(Bool.to_u32(underflows))
      float_nat_cons(float_nat_sub_go(a_rest, Nil{}, next_borrow), next)
    case +limb <> a_rest b_limb <> b_rest:
      +remove = (b_limb + borrow : Nat)
      +underflows = Nat.is_lt(limb, remove)
      next = float_nat_sub_limb(underflows, limb, remove)
      next_borrow = U32.to_nat(Bool.to_u32(underflows))
      float_nat_cons(float_nat_sub_go(a_rest, b_rest, next_borrow), next)

def float_nat_sub(a: List<&2, Nat>, b: List<&2, Nat>) -> List<&2, Nat>:
  float_nat_sub_go(a, b, 0n)

def float_nat_cmp_limb(order: Cmp, a: Nat, b: Nat) -> Cmp:
  match order:
    case EQ{}:
      Nat.cmp(a, b)
    case LT{}:
      LT{}
    case GT{}:
      GT{}

def float_nat_cmp(a: List<&2, Nat>, b: List<&2, Nat>) -> Cmp:
  match a b:
    case Nil{} Nil{}:
      EQ{}
    case Nil{} _ <> _:
      LT{}
    case _ <> _ Nil{}:
      GT{}
    case a_limb <> a_rest b_limb <> b_rest:
      float_nat_cmp_limb(float_nat_cmp(a_rest, b_rest), a_limb, b_limb)

def float_nat_mul_small(value: List<&2, Nat>, +factor: Nat, carry: Nat) -> List<&2, Nat>:
  match value:
    case Nil{}:
      match carry:
        case 0n:
          Nil{}
        case _:
          [carry]
    case limb <> rest:
      +scaled = ((limb * factor : Nat) + carry : Nat)
      Nat.mod(scaled, 16777216n) <> float_nat_mul_small(rest, factor, Nat.div(scaled, 16777216n))

def round_float_ratio_parity(remainder: Nat, quotient: Nat) -> Nat:
  match remainder:
    case 0n:
      quotient
    case _:
      (quotient + 1n : Nat)

def round_float_ratio_cmp(order: Cmp, +quotient: Nat) -> Nat:
  match order:
    case LT{}:
      quotient
    case EQ{}:
      round_float_ratio_parity(Nat.mod(quotient, 2n), quotient)
    case GT{}:
      (quotient + 1n : Nat)

def round_float_ratio(quotient: Nat, +remainder: List<&2, Nat>, denominator: List<&2, Nat>) -> Nat:
  round_float_ratio_cmp(float_nat_cmp(remainder, float_nat_sub(denominator, remainder)), quotient)

# Shift is the first binder and strictly decreases before any accumulator changes.
# Its exact remainder stays in limbs until round-to-nearest, ties-to-even.

def round_float_scaled_loop(shift: Nat, is_below: Bool, +quotient: Nat, remainder: List<&2, Nat>, +denominator: List<&2, Nat>, doubled: List<&2, Nat>) -> Nat:
  match shift:
    case 0n:
      round_float_ratio(quotient, remainder, denominator)
    case 1n+rest:
      match is_below:
        case True{}:
          +next = doubled
          +next_doubled = float_nat_mul_small(next, 2n, 0n)
          round_float_scaled_loop(rest, Cmp.is_lt(float_nat_cmp(next_doubled, denominator)), (quotient * 2n : Nat), next, denominator, next_doubled)
        case False{}:
          +next = float_nat_sub(doubled, denominator)
          +next_doubled = float_nat_mul_small(next, 2n, 0n)
          round_float_scaled_loop(rest, Cmp.is_lt(float_nat_cmp(next_doubled, denominator)), ((quotient * 2n : Nat) + 1n : Nat), next, denominator, next_doubled)

def round_float_scaled_go(shift: Nat, quotient: Nat, +remainder: List<&2, Nat>, +denominator: List<&2, Nat>) -> Nat:
  +doubled = float_nat_mul_small(remainder, 2n, 0n)
  round_float_scaled_loop(shift, Cmp.is_lt(float_nat_cmp(doubled, denominator)), quotient, remainder, denominator, doubled)

# The negative exponent search has already multiplied the ratio by 2^126.

def encode_float_normal(numerator: List<&2, Nat>, +denominator: List<&2, Nat>, negative_exponent: Bool, exponent: Nat) -> Nat & Bool:
  rounded = round_float_scaled_go(23n, 1n, float_nat_sub(numerator, denominator), denominator)
  encode_float_normal_bits(rounded, negative_exponent, exponent)

def encode_float_subnormal(numerator: List<&2, Nat>, denominator: List<&2, Nat>) -> Nat & Bool:
  (round_float_scaled_go(23n, 0n, numerator, denominator), True{})

def encode_float_negative_go(remaining: Nat, is_below: Bool, numerator: List<&2, Nat>, +denominator: List<&2, Nat>, +exponent: Nat) -> Nat & Bool:
  match remaining is_below:
    case _ False{}:
      encode_float_normal(numerator, denominator, True{}, exponent)
    case 0n True{}:
      encode_float_subnormal(numerator, denominator)
    case 1n+rest True{}:
      +next = float_nat_mul_small(numerator, 2n, 0n)
      encode_float_negative_go(rest, Cmp.is_lt(float_nat_cmp(next, denominator)), next, denominator, (exponent + 1n : Nat))

def encode_float_negative(+numerator: List<&2, Nat>, +denominator: List<&2, Nat>, +exponent: Nat) -> Nat & Bool:
  encode_float_negative_go((126n - exponent : Nat), Cmp.is_lt(float_nat_cmp(numerator, denominator)), numerator, denominator, exponent)

def encode_float_positive_go(remaining: Nat, is_below: Bool, +numerator: List<&2, Nat>, denominator: List<&2, Nat>, +twice_denominator: List<&2, Nat>, +exponent: Nat) -> Nat & Bool:
  match remaining is_below:
    case _ True{}:
      encode_float_normal(numerator, denominator, False{}, exponent)
    case 0n False{}:
      (0n, False{})
    case 1n+rest False{}:
      +next_twice = float_nat_mul_small(twice_denominator, 2n, 0n)
      encode_float_positive_go(rest, Cmp.is_lt(float_nat_cmp(numerator, next_twice)), numerator, twice_denominator, next_twice, (exponent + 1n : Nat))

def encode_float_positive(+numerator: List<&2, Nat>, +denominator: List<&2, Nat>, +exponent: Nat) -> Nat & Bool:
  +twice_denominator = float_nat_mul_small(denominator, 2n, 0n)
  encode_float_positive_go((127n - exponent : Nat), Cmp.is_lt(float_nat_cmp(numerator, twice_denominator)), numerator, denominator, twice_denominator, exponent)

def encode_float32_lt_one(less_than_one: Bool, numerator: List<&2, Nat>, denominator: List<&2, Nat>) -> Nat & Bool:
  match less_than_one:
    case True{}:
      encode_float_negative(numerator, denominator, 0n)
    case False{}:
      encode_float_positive(numerator, denominator, 0n)

def encode_float32(+numerator: List<&2, Nat>, +denominator: List<&2, Nat>) -> Nat & Bool:
  encode_float32_lt_one(Cmp.is_lt(float_nat_cmp(numerator, denominator)), numerator, denominator)

def float_nat_scale(scale: Nat, value: List<&2, Nat>) -> List<&2, Nat>:
  match scale:
    case 0n:
      value
    case 1n+rest:
      float_nat_scale(rest, float_nat_mul_small(value, 10n, 0n))

def float32_parts(parts: FloatParts) -> Nat & Bool:
  match parts:
    case FloatParts{Nil{}, _, _, True{}}:
      (0n, True{})
    case FloatParts{mantissa, True{}, scale, True{}}:
      denominator = float_nat_scale(scale, [1n])
      encode_float32(mantissa, denominator)
    case FloatParts{mantissa, False{}, scale, True{}}:
      numerator = float_nat_scale(scale, mantissa)
      encode_float32(numerator, [1n])
    case _:
      (0n, False{})

def float_scale_positive(exponent_smaller: Bool, mantissa: List<&2, Nat>, fractional: Nat, exponent: Nat) -> FloatParts:
  match exponent_smaller:
    case True{}:
      FloatParts{mantissa,  True{},  (fractional - exponent : Nat),  True{}}
    case False{}:
      FloatParts{mantissa,  False{},  (exponent - fractional : Nat),  True{}}

def float_scale(mantissa: List<&2, Nat>, +fractional: Nat, +exponent: Nat, exponent_negative: Bool) -> FloatParts:
  match exponent_negative:
    case True{}:
      FloatParts{mantissa,  True{},  (exponent + fractional : Nat),  True{}}
    case False{}:
      float_scale_positive(Nat.is_lt(exponent, fractional), mantissa, fractional, exponent)

def scan_float_end(mantissa: List<&2, Nat>, fractional: Nat, exponent: Nat, exponent_negative: Bool, valid: Bool, mantissa_digit: Bool, dot_seen: Bool, in_exponent: Bool, exponent_digit: Bool) -> FloatParts:
  match valid mantissa_digit dot_seen in_exponent exponent_digit:
    case True{} True{} True{} False{} _:
      float_scale(mantissa, fractional, exponent, exponent_negative)
    case True{} True{} True{} True{} True{}:
      float_scale(mantissa, fractional, exponent, exponent_negative)
    case _ _ _ _ _:
      FloatParts{mantissa, False{}, 0n, False{}}

def float_decimal_above_zero(is_above: Bool, code: Nat) -> Maybe<&2, Nat>:
  match is_above:
    case True{}:
      Some{(code - 48n : Nat)}
    case False{}:
      None{}

def float_decimal_below_ten(is_below: Bool, +code: Nat) -> Maybe<&2, Nat>:
  match is_below:
    case True{}:
      float_decimal_above_zero(Nat.is_lt(47n, code), code)
    case False{}:
      None{}

def float_decimal_digit(+code: Nat) -> Maybe<&2, Nat>:
  float_decimal_below_ten(Nat.is_lt(code, 58n), code)

# Float integers are canonical little-endian base-2^24 limbs; zero is Nil.
# Decimal multiply-add stays below 10 * 2^24, independent of literal size.
# Neither a long mantissa nor its decimal scale needs a Nat above 2^48-1.

def scan_float_mantissa_digit(digit: Nat, dot_seen: Bool, mantissa: List<&2, Nat>, fractional: Nat, exponent: Nat, exponent_negative: Bool, exponent_sign: Bool, exponent_digit: Bool, valid: Bool) -> FloatScanStep:
  match dot_seen:
    case True{}:
      FloatScanContinue{float_nat_mul_small(mantissa, 10n, digit), (fractional + 1n : Nat), dot_seen, False{}, exponent, exponent_negative, exponent_sign, True{}, exponent_digit, valid}
    case False{}:
      FloatScanContinue{float_nat_mul_small(mantissa, 10n, digit), fractional, dot_seen, False{}, exponent, exponent_negative, exponent_sign, True{}, exponent_digit, valid}

def scan_float_valid_digit(in_exponent: Bool, digit: Nat, dot_seen: Bool, mantissa: List<&2, Nat>, fractional: Nat, exponent: Nat, exponent_negative: Bool, exponent_sign: Bool, mantissa_digit: Bool, exponent_digit: Bool, valid: Bool) -> FloatScanStep:
  match in_exponent:
    case True{}:
      FloatScanContinue{mantissa, fractional, dot_seen, True{}, ((exponent * 10n : Nat) + digit : Nat), exponent_negative, exponent_sign, mantissa_digit, True{}, valid}
    case False{}:
      scan_float_mantissa_digit(digit, dot_seen, mantissa, fractional, exponent, exponent_negative, exponent_sign, exponent_digit, valid)

def scan_float_digit(result: Maybe<&2, Nat>, in_exponent: Bool, dot_seen: Bool, mantissa: List<&2, Nat>, fractional: Nat, exponent: Nat, exponent_negative: Bool, exponent_sign: Bool, mantissa_digit: Bool, exponent_digit: Bool, valid: Bool) -> FloatScanStep:
  match result:
    case Some{digit}:
      scan_float_valid_digit(in_exponent, digit, dot_seen, mantissa, fractional, exponent, exponent_negative, exponent_sign, mantissa_digit, exponent_digit, valid)
    case None{}:
      FloatScanDone{FloatParts{mantissa, False{}, 0n, False{}}}

def scan_float_dot(in_exponent: Bool, dot_seen: Bool, mantissa: List<&2, Nat>, fractional: Nat, exponent: Nat, exponent_negative: Bool, exponent_sign: Bool, mantissa_digit: Bool, exponent_digit: Bool, valid: Bool) -> FloatScanStep:
  match in_exponent dot_seen:
    case False{} False{}:
      FloatScanContinue{mantissa, fractional, True{}, False{}, exponent, exponent_negative, exponent_sign, mantissa_digit, exponent_digit, valid}
    case _ _:
      FloatScanDone{FloatParts{mantissa, False{}, 0n, False{}}}

def scan_float_exponent_mantissa(mantissa_digit: Bool, mantissa: List<&2, Nat>, fractional: Nat, dot_seen: Bool, exponent: Nat, exponent_negative: Bool, exponent_sign: Bool, valid: Bool) -> FloatScanStep:
  match mantissa_digit:
    case True{}:
      FloatScanContinue{mantissa, fractional, dot_seen, True{}, exponent, exponent_negative, False{}, True{}, False{}, valid}
    case False{}:
      FloatScanDone{FloatParts{mantissa, False{}, 0n, False{}}}

def scan_float_exponent_dot(dot_seen: Bool, mantissa_digit: Bool, mantissa: List<&2, Nat>, fractional: Nat, exponent: Nat, exponent_negative: Bool, exponent_sign: Bool, valid: Bool) -> FloatScanStep:
  match dot_seen:
    case True{}:
      scan_float_exponent_mantissa(mantissa_digit, mantissa, fractional, dot_seen, exponent, exponent_negative, exponent_sign, valid)
    case False{}:
      FloatScanDone{FloatParts{mantissa, False{}, 0n, False{}}}

def scan_float_exponent(in_exponent: Bool, dot_seen: Bool, mantissa_digit: Bool, mantissa: List<&2, Nat>, fractional: Nat, exponent: Nat, exponent_negative: Bool, exponent_sign: Bool, valid: Bool) -> FloatScanStep:
  match in_exponent:
    case False{}:
      scan_float_exponent_dot(dot_seen, mantissa_digit, mantissa, fractional, exponent, exponent_negative, exponent_sign, valid)
    case True{}:
      FloatScanDone{FloatParts{mantissa, False{}, 0n, False{}}}

def scan_float_sign(is_negative: Bool, in_exponent: Bool, exponent_digit: Bool, exponent_sign: Bool, mantissa: List<&2, Nat>, fractional: Nat, dot_seen: Bool, exponent: Nat, mantissa_digit: Bool, valid: Bool) -> FloatScanStep:
  match in_exponent exponent_digit exponent_sign:
    case True{} False{} False{}:
      FloatScanContinue{mantissa, fractional, dot_seen, True{}, exponent, is_negative, True{}, mantissa_digit, exponent_digit, valid}
    case _ _ _:
      FloatScanDone{FloatParts{mantissa, False{}, 0n, False{}}}

def scan_float_code(+code: Nat, mantissa: List<&2, Nat>, fractional: Nat, dot_seen: Bool, in_exponent: Bool, exponent: Nat, exponent_negative: Bool, exponent_sign: Bool, mantissa_digit: Bool, exponent_digit: Bool, valid: Bool) -> FloatScanStep:
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

def scan_float_step(chars: List<&2, Char>, mantissa: List<&2, Nat>, fractional: Nat, dot_seen: Bool, in_exponent: Bool, exponent: Nat, exponent_negative: Bool, exponent_sign: Bool, mantissa_digit: Bool, exponent_digit: Bool, valid: Bool) -> FloatScanStep:
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

def scan_float(+chars: List<&2, Char>, mantissa: List<&2, Nat>, fractional: Nat, dot_seen: Bool, in_exponent: Bool, exponent: Nat, exponent_negative: Bool, exponent_sign: Bool, mantissa_digit: Bool, exponent_digit: Bool, valid: Bool) -> FloatParts:
  scan_float_go(chars, scan_float_step(chars, mantissa, fractional, dot_seen, in_exponent, exponent, exponent_negative, exponent_sign, mantissa_digit, exponent_digit, valid))

def float32_bits(text: String) -> Nat & Bool:
  float32_parts(scan_float(String.to_list(text), Nil{}, 0n, False{}, False{}, 0n, False{}, False{}, False{}, False{}, True{}))

def parse_number_float_result(result: Nat & Bool, +file: String, +beg: Nat, +end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case (bits, True{}):
      ((Ast.TermCtr{"F32", [u32_bits(file, 32n, bits, beg, end)], span(file, beg, end)}, rest), True{})
    case (_, False{}):
      ((Ast.TermHole{"parse-error: unsupported or non-finite numeric literal", span(file, beg, end)}, rest), False{})

def parse_scalar_number_range(in_range: Bool, file: String, value: Nat, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match in_range:
    case True{}:
      ((u32_literal(file, value, beg, end), rest), True{})
    case False{}:
      ((Ast.TermHole{"parse-error: unsigned integer literal exceeds 4294967295", span(file, beg, end)}, rest), False{})

def parse_scalar_number_read(result: Maybe<&2, Nat>, file: String, text: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case Some{+value}:
      parse_scalar_number_range(Nat.is_le(value, 4294967295n), file, value, beg, end, rest)
    case None{}:
      parse_number_float_result(float32_bits(text), file, beg, end, rest)

def parse_scalar_number(file: String, +text: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_scalar_number_read(Nat.read(text), file, text, beg, end, rest)

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

def feedback_make_Kont_202679(capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Lexer.Token>) -> FeedbackFrame:
  Kont_202679{capture_1, capture_2, capture_3, capture_4, capture_5}

def step_parse_nat_literal_plus(adjacent: Bool, +file: String, +value: Nat, +beg: Nat, +end: Nat, tokens: List<&2, Lexer.Token>, +rest: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match adjacent:
    case True{}:
      feedback_attach(step_parse_term(file, rest, scope, depth, 0n), feedback_make_Kont_202679(file, value, beg, end, rest))
    case False{}:
      feedback_pack_5(((nat_literal(file, value, beg, end), tokens), True{}))

def step_parse_nat_literal(+file: String, +value: Nat, +beg: Nat, +end: Nat, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match tokens:
    case +plus <> rest:
      match plus:
        case Lexer.TokenInfo{_, "+", plus_beg, _, _, _}:
          step_parse_nat_literal_plus(Nat.is_eq(end, plus_beg), file, value, beg, end, tokens, rest, scope, depth)
        case _:
          feedback_pack_5(((nat_literal(file, value, beg, end), tokens), True{}))
    case Nil{}:
      feedback_pack_5(((nat_literal(file, value, beg, end), Nil{}), True{}))

def step_parse_number_nat_range(in_range: Bool, value: Nat, +file: String, +beg: Nat, +end: Nat, +rest: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match in_range:
    case True{}:
      step_parse_nat_literal(file, value, beg, end, rest, scope, depth)
    case False{}:
      feedback_pack_5(((Ast.TermHole{"parse-error: natural literal exceeds 4294967295", span(file, beg, end)}, rest), False{}))

def step_parse_number_nat_result(result: Maybe<&2, Nat>, +file: String, +beg: Nat, +end: Nat, +rest: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match result:
    case Some{+value}:
      step_parse_number_nat_range(Nat.is_le(value, 4294967295n), value, file, beg, end, rest, scope, depth)
    case None{}:
      feedback_pack_5(((Ast.TermHole{"parse-error: invalid natural literal", span(file, beg, end)}, rest), False{}))

def step_parse_number_suffix(has_suffix: Bool, +file: String, +text: String, +beg: Nat, +end: Nat, +rest: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match has_suffix:
    case True{}:
      step_parse_number_nat_result(Nat.read(drop_nat_suffix(text)), file, beg, end, rest, scope, depth)
    case False{}:
      feedback_pack_5(parse_scalar_number(file, text, beg, end, rest))

def step_parse_number(file: String, +text: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  step_parse_number_suffix(has_nat_suffix(text), file, text, beg, end, rest, scope, depth)

def step_parse_atom_scan(+file: String, +tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match scanned:
    case +token <> +rest:
      match token:
        case Lexer.TokenInfo{ Lexer.NameToken{}, text, beg, end,  _,  _}:
          step_parse_atom_name_dispatch(text, file, scope, depth, rest, beg, end)
        case Lexer.TokenInfo{ Lexer.NumberToken{}, text, beg, end,  _,  _}:
          step_parse_number(file, text, beg, end, rest, scope, depth)
        case Lexer.TokenInfo{ Lexer.SymbolToken{}, text, beg, end,  _, col}:
          step_parse_atom_symbol_dispatch(text, file, tokens, scope, depth, rest, beg, end, col)
        case Lexer.TokenInfo{ Lexer.StringToken{}, text, beg, end,  _,  _}:
          feedback_pack_5(parse_string(file, text, beg, end, rest))
        case Lexer.TokenInfo{ Lexer.CharToken{}, text, beg, end,  _,  _}:
          feedback_pack_5(parse_char_literal(file, text, beg, end, rest))
        case Lexer.TokenInfo{+feedback_field_14_0, +feedback_field_14_1, +feedback_field_14_2, +feedback_field_14_3, +feedback_field_14_4, +feedback_field_14_5}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a term",  span(file, token_beg((Lexer.TokenInfo{feedback_field_14_0, feedback_field_14_1, feedback_field_14_2, feedback_field_14_3, feedback_field_14_4, feedback_field_14_5} : Lexer.Token)), token_end((Lexer.TokenInfo{feedback_field_14_0, feedback_field_14_1, feedback_field_14_2, feedback_field_14_3, feedback_field_14_4, feedback_field_14_5} : Lexer.Token)))}, tokens), False{}))
    case Nil{}:
      feedback_pack_5(((Ast.TermHole{ "parse-error: expected a term",  span(file, 0n, 0n)}, Nil{}), False{}))

def body_scan_action(token: Lexer.Token) -> BodyScanAction:
  match token:
    case Lexer.TokenInfo{ Lexer.NameToken{},  "match", beg,  _,  _, col}:
      BodyScanActionRow0{}
    case Lexer.TokenInfo{Lexer.SymbolToken{}, "(", beg, _, _, _}:
      BodyScanActionRow1{}
    case Lexer.TokenInfo{Lexer.NumberToken{}, _, beg, _, _, _}:
      BodyScanActionRow2{}
    case Lexer.TokenInfo{ Lexer.NameToken{},  key, beg, end,  _, col}:
      BodyScanActionRow3{}
    case Lexer.TokenInfo{ Lexer.SymbolToken{},  "+", beg,  _,  _, col}:
      BodyScanActionRow4{}
    case Lexer.TokenInfo{ Lexer.SymbolToken{},  "-", beg,  _,  _, col}:
      BodyScanActionRow5{}
    case _:
      BodyScanActionRow6{}

def feedback_make_Kont_299333(lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_10: List<&2, Scope>, lexical_capture_12: Nat) -> FeedbackFrame:
  Kont_299333{lexical_capture_1, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_12}

def feedback_make_Kont_302984(lexical_capture_1: String, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat, lexical_capture_10: List<&2, Ast.SyntaxTerm>) -> FeedbackFrame:
  Kont_302984{lexical_capture_1, lexical_capture_6, lexical_capture_8, lexical_capture_10}

def step_parse_terms_until_colon(+file: String, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +acc: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match tokens:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
          feedback_pack_9(((List.reverse(&2, Ast.SyntaxTerm, acc), tokens), True{}))
        case _:
          feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_302984(file, scope, depth, acc))
    case Nil{}:
      feedback_pack_9(((List.reverse(&2, Ast.SyntaxTerm, acc), Nil{}), False{}))

def step_parse_match_body(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_terms_until_colon(file, tokens, scope, depth, Nil{}), feedback_make_Kont_299333(file, beg, col, scope, depth))

def step_parse_body_token_row_0(file: String, scope: List<&2, Scope>, depth: Nat, +rest: List<&2, Lexer.Token>, beg: Nat, col: Nat) -> FeedbackControl:
  step_parse_match_body(file, rest, beg, col, scope, depth)

def destructuring_has_equal(tokens: List<&2, Lexer.Token>, nesting: Nat) -> Bool:
  match tokens nesting:
    case Nil{} _:
      False{}
    case Lexer.TokenInfo{Lexer.EndToken{}, _, _, _, _, _} <> _ _:
      False{}
    case Lexer.TokenInfo{Lexer.NewlineToken{}, _, _, _, _, _} <> _ 0n:
      False{}
    case Lexer.TokenInfo{_, "=", _, _, _, _} <> _ 0n:
      True{}
    case Lexer.TokenInfo{_, "(", _, _, _, _} <> rest depth:
      destructuring_has_equal(rest, (depth + 1n : Nat))
    case Lexer.TokenInfo{_, "{", _, _, _, _} <> rest depth:
      destructuring_has_equal(rest, (depth + 1n : Nat))
    case Lexer.TokenInfo{_, "[", _, _, _, _} <> rest depth:
      destructuring_has_equal(rest, (depth + 1n : Nat))
    case Lexer.TokenInfo{_, ")", _, _, _, _} <> rest 1n+depth:
      destructuring_has_equal(rest, depth)
    case Lexer.TokenInfo{_, "}", _, _, _, _} <> rest 1n+depth:
      destructuring_has_equal(rest, depth)
    case Lexer.TokenInfo{_, "]", _, _, _, _} <> rest 1n+depth:
      destructuring_has_equal(rest, depth)
    case Lexer.TokenInfo{_, ")", _, _, _, _} <> _ 0n:
      False{}
    case Lexer.TokenInfo{_, "}", _, _, _, _} <> _ 0n:
      False{}
    case Lexer.TokenInfo{_, "]", _, _, _, _} <> _ 0n:
      False{}
    case Lexer.TokenInfo{_, ",", _, _, _, _} <> _ 0n:
      False{}
    case Lexer.TokenInfo{_, ":", _, _, _, _} <> _ 0n:
      False{}
    case Lexer.TokenInfo{_, ";", _, _, _, _} <> _ 0n:
      False{}
    case _ <> rest depth:
      destructuring_has_equal(rest, depth)

def feedback_make_Kont_296679(lexical_capture_3: String, lexical_capture_5: List<&2, Lexer.Token>, lexical_capture_7: Nat, lexical_capture_9: Nat, lexical_capture_12: List<&2, Scope>, lexical_capture_14: Nat) -> FeedbackFrame:
  Kont_296679{lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_12, lexical_capture_14}

def feedback_make_Kont_171361(capture_1: String, capture_2: Nat) -> FeedbackFrame:
  Kont_171361{capture_1, capture_2}

def feedback_make_pattern_scan(tokens: List<&2, Lexer.Token>, file: String, mode: PatternScanMode, frames: List<&2, PatternFrame>, scope: List<&2, Scope>, depth: Nat, goal: PatternScanGoal) -> FeedbackRequest:
  Request_pattern_scan{tokens, file, mode, frames, scope, depth, goal}

def step_parse_pattern_atom(+file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  feedback_attach(FeedbackControl{FeedbackCall{feedback_make_pattern_scan(tokens, file, PatternExpect{Ast.QOne{}, 0n}, Nil{}, scope, depth, PatternSingleGoal{})}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_171361(file, depth))

def feedback_make_Kont_286456(lexical_capture_1: String) -> FeedbackFrame:
  Kont_286456{lexical_capture_1}

def step_parse_reply(+file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_286456(file))

def step_parse_destructuring_recognized(is_local: Bool, +file: String, +tokens: List<&2, Lexer.Token>, beg: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match is_local:
    case True{}:
      feedback_attach(step_parse_pattern_atom(file, tokens, scope, depth), feedback_make_Kont_296679(file, tokens, beg, col, scope, depth))
    case False{}:
      step_parse_reply(file, tokens, scope, depth)

def step_parse_destructuring_local(+file: String, +tokens: List<&2, Lexer.Token>, beg: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  step_parse_destructuring_recognized(destructuring_has_equal(skip_lines(tokens), 0n), file, tokens, beg, col, scope, depth)

def step_parse_body_token_row_1(file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, parent_col: Nat, beg: Nat) -> FeedbackControl:
  step_parse_destructuring_local(file, tokens, beg, parent_col, scope, depth)

def step_parse_body_token_row_2(file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, parent_col: Nat, beg: Nat) -> FeedbackControl:
  step_parse_destructuring_local(file, tokens, beg, parent_col, scope, depth)

def feedback_make_Kont_292028(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, lexical_capture_17: Ast.Quantity) -> FeedbackFrame:
  Kont_292028{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_14, lexical_capture_16, lexical_capture_17}

def step_parse_local_body(+file: String, key: String, beg: Nat, key_end: Nat, col: Nat, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, quantity: Ast.Quantity) -> FeedbackControl:
  feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_292028(file, key, beg, key_end, col, scope, depth, quantity))

def step_parse_body_next_row_0(file: String, scope: List<&2, Scope>, depth: Nat, parent_col: Nat, key: String, beg: Nat, end: Nat, after_next: List<&2, Lexer.Token>) -> FeedbackControl:
  step_parse_local_body(file, key, beg, end, parent_col, after_next, scope, depth, Ast.QOne{})

def step_parse_body_next_row_1(file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, parent_col: Nat, beg: Nat) -> FeedbackControl:
  step_parse_destructuring_local(file, tokens, beg, parent_col, scope, depth)

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

def feedback_make_Kont_289909(lexical_capture_3: List<&2, Ast.SyntaxPattern>, lexical_capture_8: List<&2, Scope>, lexical_capture_10: Nat, lexical_capture_12: String, lexical_capture_14: Nat, lexical_capture_16: Nat, lexical_capture_22: Ast.Quantity) -> FeedbackFrame:
  Kont_289909{lexical_capture_3, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_22}

def feedback_make_parse_local_values_next(remaining: List<&2, Ast.SyntaxPattern>, file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, line: Nat, acc: List<&2, Ast.SyntaxTerm>) -> FeedbackRequest:
  Request_parse_local_values_next{remaining, file, tokens, scope, depth, line, acc}

def step_parse_local_values(file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, remaining: List<&2, Ast.SyntaxPattern>, acc: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  FeedbackControl{FeedbackCall{feedback_make_parse_local_values_next(remaining, file, tokens, scope, depth, 0n, acc)}, Nil{}, NoProgress{}, NoProgress{}}

def token_end_of(tokens: List<&2, Lexer.Token>, fallback: Nat) -> Nat:
  match tokens:
    case +token <> _:
      token_beg(token)
    case Nil{}:
      fallback

def step_parse_parallel_binders_result(ok_patterns: Bool, +patterns: List<&2, Ast.SyntaxPattern>, +after_equals: List<&2, Lexer.Token>, next_scope: List<&2, Scope>, next_depth: Nat, +file: String, +beg: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat, quantity: Ast.Quantity) -> FeedbackControl:
  match ok_patterns:
    case True{}:
      feedback_attach(step_parse_local_values(file, after_equals, scope, depth, patterns, Nil{}), feedback_make_Kont_289909(patterns, next_scope, next_depth, file, beg, col, quantity))
    case False{}:
      feedback_pack_5(((Ast.TermHole{ "parse-error: expected parallel binders",  span(file, beg, token_end_of(after_equals, beg))}, after_equals), False{}))

def feedback_consumer_289217(v_312: Pair(Pair(Pair(Pair(List<&2, Ast.SyntaxPattern>, List<&2, Lexer.Token>), List<&2, Scope>), Nat), Bool), v_1: String, v_5: Nat, v_7: Nat, v_10: List<&2, Scope>, v_12: Nat, v_13: Ast.Quantity) -> FeedbackControl:
  match v_312:
    case ((((v_313, v_314), v_315), v_316), v_317):
      step_parse_parallel_binders_result(v_317, v_313, v_314, v_315, v_316, v_1, v_5, v_7, v_10, v_12, v_13)

def local_binder_pattern(key: String, depth: Nat, quantity: Ast.Quantity, file: String, beg: Nat, end: Nat) -> Ast.SyntaxPattern:
  Ast.PatternVar{key, depth, quantity, span(file, beg, end)}

def parse_local_binders(+file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, +depth: Nat, +quantity: Ast.Quantity, acc: List<&2, Ast.SyntaxPattern>) -> (((List<&2, Ast.SyntaxPattern> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool:
  match tokens:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{_, "=", _, _, _, _}:
          ((((List.reverse(&2, Ast.SyntaxPattern, acc), rest), scope), depth), True{})
        case Lexer.TokenInfo{Lexer.NameToken{}, +key, beg, end, _, _}:
          parse_local_binders(file, rest, extend_scope(key, depth, scope), (depth + 1n : Nat), quantity, local_binder_pattern(key, depth, quantity, file, beg, end) <> acc)
        case _:
          ((((List.reverse(&2, Ast.SyntaxPattern, acc), tokens), scope), depth), False{})
    case Nil{}:
      ((((List.reverse(&2, Ast.SyntaxPattern, acc), Nil{}), scope), depth), False{})

def step_parse_parallel_local(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat, +quantity: Ast.Quantity) -> FeedbackControl:
  feedback_consumer_289217(parse_local_binders(file, tokens, scope, depth, quantity, Nil{}), file, beg, col, scope, depth, quantity)

def step_decl_parallel_or_reply(is_parallel: Bool, +file: String, tokens: List<&2, Lexer.Token>, group: List<&2, Lexer.Token>, beg: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat, quantity: Ast.Quantity) -> FeedbackControl:
  match is_parallel:
    case True{}:
      step_parse_parallel_local(file, group, beg, col, scope, depth, quantity)
    case False{}:
      step_parse_reply(file, tokens, scope, depth)

def feedback_make_Kont_294231(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat) -> FeedbackFrame:
  Kont_294231{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_14, lexical_capture_16}

def step_parse_array_write_local(+file: String, key: String, beg: Nat, key_end: Nat, col: Nat, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_294231(file, key, beg, key_end, col, scope, depth))

# Recognize the local-assignment marker before constructing speculative patterns.
# Nested markers and delimiters belonging to an enclosing term are not locals.

def step_decl_local_name_group(is_array_write: Bool, is_array: Bool, +file: String, tokens: List<&2, Lexer.Token>, +token: Lexer.Token, +rest: List<&2, Lexer.Token>, key: String, +beg: Nat, end: Nat, +col: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match is_array_write:
    case True{}:
      step_parse_array_write_local(file, key, beg, end, col, token <> rest, scope, depth)
    case False{}:
      step_decl_parallel_or_reply(is_array, file, tokens, token <> rest, beg, col, scope, depth, Ast.QOne{})

def step_parse_body_next_row_2(file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, parent_col: Nat, +token: Lexer.Token, +rest: List<&2, Lexer.Token>, key: String, beg: Nat, end: Nat) -> FeedbackControl:
  step_decl_local_name_group(local_array_write(rest), True{}, file, tokens, token, rest, key, beg, end, parent_col, scope, depth)

def local_group_has_equal(tokens: List<&2, Lexer.Token>) -> Bool:
  match tokens:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{_, "=", _, _, _, _}:
          True{}
        case Lexer.TokenInfo{Lexer.NameToken{}, _, _, _, _, _}:
          local_group_has_equal(rest)
        case _:
          False{}
    case Nil{}:
      False{}

def step_parse_body_next_row_3(file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, parent_col: Nat, +token: Lexer.Token, +rest: List<&2, Lexer.Token>, beg: Nat) -> FeedbackControl:
  step_decl_parallel_or_reply(local_group_has_equal(rest), file, tokens, token <> rest, beg, parent_col, scope, depth, Ast.QOne{})

def step_parse_body_next_dispatch(+next: Lexer.Token, +file: String, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +parent_col: Nat, +token: Lexer.Token, +rest: List<&2, Lexer.Token>, +key: String, +beg: Nat, +end: Nat, after_next: List<&2, Lexer.Token>) -> FeedbackControl:
  match next:
    case Lexer.TokenInfo{ _, "=",  _,  _,  _,  _}:
      step_parse_body_next_row_0(file, scope, depth, parent_col, key, beg, end, after_next)
    case Lexer.TokenInfo{ _, "{",  _,  _,  _,  _}:
      step_parse_body_next_row_1(file, tokens, scope, depth, parent_col, beg)
    case Lexer.TokenInfo{ _, "[",  _,  _,  _,  _}:
      step_parse_body_next_row_2(file, tokens, scope, depth, parent_col, token, rest, key, beg, end)
    case _:
      step_parse_body_next_row_3(file, tokens, scope, depth, parent_col, token, rest, beg)

def step_parse_body_token_row_3(+rest: List<&2, Lexer.Token>, +file: String, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, parent_col: Nat, +token: Lexer.Token, key: String, beg: Nat, end: Nat) -> FeedbackControl:
  match rest:
    case +next <> after_next:
      step_parse_body_next_dispatch(next, file, tokens, scope, depth, parent_col, token, rest, key, beg, end, after_next)
    case _:
      step_parse_reply(file, tokens, scope, depth)

def step_parse_body_token_row_4(file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, parent_col: Nat, +rest: List<&2, Lexer.Token>, beg: Nat) -> FeedbackControl:
  step_decl_parallel_or_reply(local_group_has_equal(rest), file, tokens, rest, beg, parent_col, scope, depth, Ast.QMany{})

def step_parse_erased_local(+file: String, +tokens: List<&2, Lexer.Token>, +beg: Nat, +col: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match tokens:
    case +name <> +rest:
      match name:
        case Lexer.TokenInfo{ Lexer.NameToken{},  key,  key_beg, end,  _,  _}:
          match rest:
            case +equals <> +after_equals:
              match equals:
                case Lexer.TokenInfo{ _, "=",  _,  _,  _,  _}:
                  step_parse_local_body(file, key, beg, end, col, after_equals, scope, depth, Ast.QZero{})
                case _:
                  step_decl_parallel_or_reply(local_group_has_equal(name <> rest), file, tokens, name <> rest, beg, col, scope, depth, Ast.QZero{})
            case Nil{}:
              step_decl_parallel_or_reply(local_group_has_equal(name <> (Nil{} : List<&2, Lexer.Token>)), file, tokens, name <> (Nil{} : List<&2, Lexer.Token>), beg, col, scope, depth, Ast.QZero{})
            case Con{+feedback_field_12_0, +feedback_field_12_1}:
              step_decl_parallel_or_reply(local_group_has_equal(name <> (Con{feedback_field_12_0, feedback_field_12_1} : List<&2, Lexer.Token>)), file, tokens, name <> (Con{feedback_field_12_0, feedback_field_12_1} : List<&2, Lexer.Token>), beg, col, scope, depth, Ast.QZero{})
        case _:
          step_parse_reply(file, tokens, scope, depth)
    case Nil{}:
      step_parse_reply(file, Nil{}, scope, depth)

def step_parse_body_token_row_5(file: String, scope: List<&2, Scope>, depth: Nat, parent_col: Nat, +rest: List<&2, Lexer.Token>, beg: Nat) -> FeedbackControl:
  step_parse_erased_local(file, rest, beg, parent_col, scope, depth)

def step_parse_body_token_row_6(file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  step_parse_reply(file, tokens, scope, depth)

def step_body_scan_run(+token: Lexer.Token, action: BodyScanAction, +file: String, +tokens: List<&2, Lexer.Token>, +rest: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +parent_col: Nat) -> FeedbackControl:
  match token:
    case Lexer.TokenInfo{_, key, +beg, end, _, col}:
      match action:
        case BodyScanActionRow0{}:
          step_parse_body_token_row_0(file, scope, depth, rest, beg, col)
        case BodyScanActionRow1{}:
          step_parse_body_token_row_1(file, tokens, scope, depth, parent_col, beg)
        case BodyScanActionRow2{}:
          step_parse_body_token_row_2(file, tokens, scope, depth, parent_col, beg)
        case BodyScanActionRow3{}:
          step_parse_body_token_row_3(rest, file, tokens, scope, depth, parent_col, token, key, beg, end)
        case BodyScanActionRow4{}:
          step_parse_body_token_row_4(file, tokens, scope, depth, parent_col, rest, beg)
        case BodyScanActionRow5{}:
          step_parse_body_token_row_5(file, scope, depth, parent_col, rest, beg)
        case BodyScanActionRow6{}:
          step_parse_body_token_row_6(file, tokens, scope, depth)

def step_parse_body_scan(+file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, parent_col: Nat) -> FeedbackControl:
  match scanned:
    case +token <> +rest:
      step_body_scan_run(token, body_scan_action(token), file, tokens, rest, scope, depth, parent_col)
    case Nil{}:
      feedback_pack_5(((Ast.TermHole{ "parse-error: expected a body",  span(file, 0n, 0n)}, Nil{}), False{}))

def feedback_make_Kont_303571(lexical_capture_3: String, lexical_capture_5: List<&2, Lexer.Token>, lexical_capture_9: Nat, lexical_capture_12: List<&2, Scope>, lexical_capture_14: Nat, lexical_capture_16: Nat, lexical_capture_18: List<&2, Ast.SyntaxTerm>) -> FeedbackFrame:
  Kont_303571{lexical_capture_3, lexical_capture_5, lexical_capture_9, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_18}

def parse_case_rows_stop(acc: List<&2, Ast.SyntaxTerm>, tokens: List<&2, Lexer.Token>) -> (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool:
  match acc:
    case Nil{}:
      ((Nil{}, tokens), True{})
    case _:
      ((List.reverse(&2, Ast.SyntaxTerm, acc), tokens), True{})

def feedback_make_Kont_306612(capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: Nat) -> FeedbackFrame:
  Kont_306612{capture_1, capture_2, capture_3, capture_4}

def step_parse_case_row(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat, arity: Nat) -> FeedbackControl:
  feedback_attach(FeedbackControl{FeedbackCall{feedback_make_pattern_scan(tokens, file, PatternExpect{Ast.QOne{}, 0n}, Nil{}, scope, depth, PatternCaseGoal{Nil{}, scope, depth})}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_306612(file, beg, col, arity))

def step_parse_case_row_indented(is_indented: Bool, +file: String, +tokens: List<&2, Lexer.Token>, rest: List<&2, Lexer.Token>, parent_col: Nat, +scope: List<&2, Scope>, +depth: Nat, +arity: Nat, +acc: List<&2, Ast.SyntaxTerm>, beg: Nat, col: Nat) -> FeedbackControl:
  match is_indented:
    case True{}:
      feedback_attach(step_parse_case_row(file, rest, beg, col, scope, depth, arity), feedback_make_Kont_303571(file, tokens, parent_col, scope, depth, arity, acc))
    case False{}:
      feedback_pack_9(parse_case_rows_stop(acc, tokens))

def feedback_make_parse_def_binders_scan(file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.TelescopeItem>) -> FeedbackRequest:
  Request_parse_def_binders_scan{file, tokens, scanned, scope, depth, acc}

def feedback_pack_1(result: ((((List<&2, Ast.TelescopeItem> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool)) -> FeedbackControl:
  match result:
    case ((((result_0_0_0_0, result_0_0_0_1), result_0_0_1), result_0_1), result_1):
      FeedbackControl{FeedbackDone{Value_1{result_0_0_0_0, result_0_0_0_1, result_0_0_1, result_0_1, result_1}}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_make_Kont_316984(capture_1: String, capture_2: String, capture_3: Ast.Quantity, capture_4: Nat, capture_5: List<&2, Ast.TelescopeItem>, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: List<&2, Lexer.Token>) -> FeedbackFrame:
  Kont_316984{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8}

def step_parse_def_binders(file: String, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.TelescopeItem>) -> FeedbackControl:
  FeedbackControl{FeedbackCall{feedback_make_parse_def_binders_scan(file, tokens, skip_lines(tokens), scope, depth, acc)}, Nil{}, NoProgress{}, NoProgress{}}

def step_parse_untyped_def_binder(+file: String, +key: String, +beg: Nat, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, +depth: Nat, acc: List<&2, Ast.TelescopeItem>) -> FeedbackControl:
  +index = depth
  item = { Ast.Binder{ Ast.QZero{}, key, index,  Ast.TermQuant{},  span(file, beg, token_end_of(tokens, beg))} : Ast.TelescopeItem }
  next_scope = extend_scope(key, index, scope)
  step_parse_def_binders(file, tokens, next_scope, (depth + 1n : Nat), item <> acc)

def step_parse_def_binder_scan(+file: String, +key: String, quantity: Ast.Quantity, +beg: Nat, +tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +acc: List<&2, Ast.TelescopeItem>) -> FeedbackControl:
  match scanned:
    case +colon <> +after_colon:
      match colon:
        case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
          feedback_attach(step_parse_term(file, after_colon, scope, depth, 0n), feedback_make_Kont_316984(file, key, quantity, beg, acc, scope, depth, after_colon))
        case _:
          step_parse_untyped_def_binder(file, key, beg, tokens, scope, depth, acc)
    case _:
      step_parse_untyped_def_binder(file, key, beg, tokens, scope, depth, acc)

def step_parse_def_binder(file: String, key: String, quantity: Ast.Quantity, beg: Nat, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.TelescopeItem>) -> FeedbackControl:
  step_parse_def_binder_scan(file, key, quantity, beg, tokens, skip_lines(tokens), scope, depth, acc)

def step_parse_def_binder_prefix(file: String, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +acc: List<&2, Ast.TelescopeItem>, quantity: Ast.Quantity) -> FeedbackControl:
  match tokens:
    case +name <> rest:
      match name:
        case Lexer.TokenInfo{ Lexer.NameToken{},  key, beg,  _,  _,  _}:
          step_parse_def_binder(file, key, quantity, beg, rest, scope, depth, acc)
        case _:
          feedback_pack_1(((((List.reverse(&2, Ast.TelescopeItem, acc), tokens), scope), depth), False{}))
    case Nil{}:
      feedback_pack_1(((((List.reverse(&2, Ast.TelescopeItem, acc), []), scope), depth), False{}))

def feedback_make_Kont_313531(capture_1: String, capture_2: List<&2, Ast.TelescopeItem>, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: String, capture_6: Nat, capture_7: List<&2, Lexer.Token>) -> FeedbackFrame:
  Kont_313531{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7}

def step_parse_template_def_binder_after_name(+file: String, key: String, beg: Nat, +original: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +acc: List<&2, Ast.TelescopeItem>) -> FeedbackControl:
  match scanned:
    case +colon <> +after_colon:
      match colon:
        case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
          feedback_attach(step_parse_term(file, after_colon, scope, depth, 0n), feedback_make_Kont_313531(file, acc, scope, depth, key, beg, after_colon))
        case _:
          feedback_pack_1(((((List.reverse(&2, Ast.TelescopeItem, acc), original), scope), depth), False{}))
    case Nil{}:
      feedback_pack_1(((((List.reverse(&2, Ast.TelescopeItem, acc), original), scope), depth), False{}))

def step_parse_template_def_binder(file: String, +tokens: List<&2, Lexer.Token>, beg: Nat, +scope: List<&2, Scope>, +depth: Nat, +acc: List<&2, Ast.TelescopeItem>) -> FeedbackControl:
  match tokens:
    case +name <> +after_name:
      match name:
        case Lexer.TokenInfo{ Lexer.NameToken{},  key,  _,  _,  _,  _}:
          step_parse_template_def_binder_after_name(file, key, beg, after_name, skip_lines(after_name), scope, depth, acc)
        case _:
          feedback_pack_1(((((List.reverse(&2, Ast.TelescopeItem, acc), tokens), scope), depth), False{}))
    case Nil{}:
      feedback_pack_1(((((List.reverse(&2, Ast.TelescopeItem, acc), []), scope), depth), False{}))

def step_parse_def_binders_scan(+file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +acc: List<&2, Ast.TelescopeItem>) -> FeedbackControl:
  match scanned:
    case +token <> +rest:
      match token:
        case Lexer.TokenInfo{ _, ")",  _,  _,  _,  _}:
          feedback_pack_1(((((List.reverse(&2, Ast.TelescopeItem, acc), rest), scope), depth), True{}))
        case Lexer.TokenInfo{ _, ">",  _,  _,  _,  _}:
          feedback_pack_1(((((List.reverse(&2, Ast.TelescopeItem, acc), rest), scope), depth), True{}))
        case Lexer.TokenInfo{ _, "<>",  _,  _,  _,  _}:
          feedback_pack_1(((((List.reverse(&2, Ast.TelescopeItem, acc), rest), scope), depth), True{}))
        case Lexer.TokenInfo{ _, "}",  _,  _,  _,  _}:
          feedback_pack_1(((((List.reverse(&2, Ast.TelescopeItem, acc), rest), scope), depth), True{}))
        case Lexer.TokenInfo{ _, ",",  _,  _,  _,  _}:
          FeedbackControl{FeedbackCall{feedback_make_parse_def_binders_scan(file, rest, skip_lines(rest), scope, depth, acc)}, Nil{}, NoProgress{}, NoProgress{}}
        case Lexer.TokenInfo{ _, "+",  _,  _,  _,  _}:
          step_parse_def_binder_prefix(file, rest, scope, depth, acc, Ast.QMany{})
        case Lexer.TokenInfo{ _, "-",  _,  _,  _,  _}:
          step_parse_def_binder_prefix(file, rest, scope, depth, acc, Ast.QZero{})
        case Lexer.TokenInfo{ _, "~", beg,  _,  _,  _}:
          step_parse_template_def_binder(file, rest, beg, scope, depth, acc)
        case Lexer.TokenInfo{Lexer.NameToken{}, key, beg, _, _, _}:
          step_parse_def_binder(file, key, Ast.QOne{}, beg, rest, scope, depth, acc)
        case _:
          feedback_pack_1(((((List.reverse(&2, Ast.TelescopeItem, acc), tokens), scope), depth), False{}))
    case Nil{}:
      feedback_pack_1(((((List.reverse(&2, Ast.TelescopeItem, acc), []), scope), depth), False{}))

def feedback_make_Kont_194056(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Nat, capture_7: Nat, capture_8: List<&2, Scope>, capture_9: Nat, capture_10: Nat) -> FeedbackFrame:
  Kont_194056{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10}

def feedback_make_Kont_198352(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Nat, capture_5: Nat, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: Nat) -> FeedbackFrame:
  Kont_198352{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8}

def step_parse_do_untyped(+file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat, col: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_198352(file, monad, args, beg, end, scope, depth, col))

def step_parse_do_typed_bind(+file: String, +monad: String, +args: List<&2, Ast.SyntaxTerm>, +tokens: List<&2, Lexer.Token>, +beg: Nat, +end: Nat, +scope: List<&2, Scope>, +depth: Nat, +col: Nat) -> FeedbackControl:
  match tokens:
    case +name <> after_name:
      match name:
        case Lexer.TokenInfo{Lexer.NameToken{}, key, key_beg, _, _, _}:
          match after_name:
            case +colon <> after_colon:
              match colon:
                case Lexer.TokenInfo{_, ":", _, _, _, _}:
                  feedback_attach(step_parse_term(file, after_colon, scope, depth, 1n), feedback_make_Kont_194056(file, monad, args, key, key_beg, beg, end, scope, depth, col))
                case _:
                  step_parse_do_untyped(file, monad, args, tokens, beg, end, scope, depth, col)
            case _:
              step_parse_do_untyped(file, monad, args, tokens, beg, end, scope, depth, col)
        case _:
          step_parse_do_untyped(file, monad, args, tokens, beg, end, scope, depth, col)
    case Nil{}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected return or a do binding", span(file, beg, end)}, Nil{}), False{}))

def feedback_pack_8(result: ((List<&2, Ast.ModuleImport> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  match result:
    case ((result_0_0, result_0_1), result_1):
      FeedbackControl{FeedbackDone{Value_8{result_0_0, result_0_1, result_1}}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_make_parse_imports_result(ok: Bool, item: Ast.ModuleImport, after: List<&2, Lexer.Token>, file: String, acc: List<&2, Ast.ModuleImport>) -> FeedbackRequest:
  Request_parse_imports_result{ok, item, after, file, acc}

def feedback_consumer_329144(v_322: Pair(Pair(Ast.ModuleImport, List<&2, Lexer.Token>), Bool), v_1: String, v_7: List<&2, Ast.ModuleImport>) -> FeedbackControl:
  match v_322:
    case ((v_323, v_324), v_325):
      FeedbackControl{FeedbackCall{feedback_make_parse_imports_result(v_325, v_323, v_324, v_1, v_7)}, Nil{}, NoProgress{}, NoProgress{}}

def canonical_import_path(token: Lexer.Token) -> String:
  match token:
    case Lexer.TokenInfo{ Lexer.StringToken{}, text,  _,  _,  _,  _}:
      strip_quotes(text)
    case Lexer.TokenInfo{ Lexer.NameToken{}, text,  _,  _,  _,  _}:
      text
    case _:
      token_text(token)

def has_space_after_result(is_spaced: Bool) -> Bool:
  match is_spaced:
    case True{}:
      True{}
    case False{}:
      False{}

def has_space_after(end: Nat, tokens: List<&2, Lexer.Token>) -> Bool:
  match tokens:
    case +token <> _:
      has_space_after_result(Nat.is_lt(end, token_beg(token)))
    case Nil{}:
      False{}

def is_base_path(token: Lexer.Token) -> Bool:
  match token:
    case Lexer.TokenInfo{ Lexer.NameToken{},  "Base",  _,  _,  _,  _}:
      True{}
    case _:
      False{}

def module_import_without_alias(is_base: Bool, file: String, +canonical: String, beg: Nat, path_token: Lexer.Token, rest: List<&2, Lexer.Token>) -> (Ast.ModuleImport & List<&2, Lexer.Token>) & Bool:
  match is_base:
    case True{}:
      ((Ast.ModuleImport{ canonical,  "Base",  span(file, beg, token_end(path_token))}, rest), True{})
    case False{}:
      ((Ast.ModuleImport{ canonical,  canonical,  span(file, beg, token_end(path_token))}, rest), False{})

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

def step_parse_imports_scan(+file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +acc: List<&2, Ast.ModuleImport>) -> FeedbackControl:
  match scanned:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{ Lexer.NameToken{},  "import",  _,  _,  _,  _}:
          feedback_consumer_329144(parse_module_import(file, token, rest), file, acc)
        case _:
          feedback_pack_8(((List.reverse(&2, Ast.ModuleImport, acc), tokens), True{}))
    case Nil{}:
      feedback_pack_8(((List.reverse(&2, Ast.ModuleImport, acc), []), True{}))

def step_parse_imports_result(ok: Bool, +item: Ast.ModuleImport, +after: List<&2, Lexer.Token>, file: String, +acc: List<&2, Ast.ModuleImport>) -> FeedbackControl:
  match ok:
    case True{}:
      step_parse_imports_scan(file, after, skip_lines(after), item <> acc)
    case False{}:
      feedback_pack_8(((List.reverse(&2, Ast.ModuleImport, item <> acc), after), False{}))

def feedback_make_Kont_345864(lexical_capture_1: String, lexical_capture_7: Nat, lexical_capture_9: Bool, lexical_capture_10: Ast.Quantity, lexical_capture_12: String, lexical_capture_14: Nat, lexical_capture_17: Ast.SyntaxTerm, lexical_capture_20: List<&2, Scope>, lexical_capture_22: Nat, lexical_capture_24: List<&2, Ast.Clause>) -> FeedbackFrame:
  Kont_345864{lexical_capture_1, lexical_capture_7, lexical_capture_9, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_17, lexical_capture_20, lexical_capture_22, lexical_capture_24}

def feedback_pack_0(result: ((((List<&2, Ast.Clause> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool)) -> FeedbackControl:
  match result:
    case ((((result_0_0_0_0, result_0_0_0_1), result_0_0_1), result_0_1), result_1):
      FeedbackControl{FeedbackDone{Value_0{result_0_0_0_0, result_0_0_0_1, result_0_0_1, result_0_1, result_1}}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_make_Kont_343898(lexical_capture_1: String, lexical_capture_31: String, lexical_capture_32: Nat, lexical_capture_33: Nat, lexical_capture_5: Nat, lexical_capture_7: Bool, lexical_capture_8: Ast.Quantity, lexical_capture_11: List<&2, Scope>, lexical_capture_13: Nat, lexical_capture_15: List<&2, Ast.Clause>) -> FeedbackFrame:
  Kont_343898{lexical_capture_1, lexical_capture_31, lexical_capture_32, lexical_capture_33, lexical_capture_5, lexical_capture_7, lexical_capture_8, lexical_capture_11, lexical_capture_13, lexical_capture_15}

def step_parse_law_clause_name(+file: String, +tokens: List<&2, Lexer.Token>, beg: Nat, universal: Bool, quantity: Ast.Quantity, +scope: List<&2, Scope>, +depth: Nat, +acc: List<&2, Ast.Clause>) -> FeedbackControl:
  match tokens:
    case +name <> +after_name:
      match name:
        case Lexer.TokenInfo{ Lexer.NameToken{},  key,  key_beg,  key_end,  _,  _}:
          match after_name:
            case +colon <> after_colon:
              match colon:
                case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
                  feedback_attach(step_parse_term(file, after_colon, scope, depth, 0n), feedback_make_Kont_343898(file, key, key_beg, key_end, beg, universal, quantity, scope, depth, acc))
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

def step_finish_law_clause(+file: String, +tokens: List<&2, Lexer.Token>, beg: Nat, universal: Bool, quantity: Ast.Quantity, +key: String, +key_beg: Nat, key_end: Nat, +ty: Ast.SyntaxTerm, +next_scope: List<&2, Scope>, +next_depth: Nat, +acc: List<&2, Ast.Clause>) -> FeedbackControl:
  match universal:
    case True{}:
      clause = { Ast.ClauseFor{ True{}, quantity, key, ty,  None{},  span(file, key_beg, token_end_first(ty))} : Ast.Clause }
      step_parse_law_clauses(file, tokens, next_scope, next_depth, clause <> acc)
    case False{}:
      clause = { Ast.ClauseFor{ False{},  Ast.QOne{}, key, ty,  None{},  span(file, key_beg, token_end_first(ty))} : Ast.Clause }
      step_parse_law_clauses(file, tokens, next_scope, next_depth, clause <> acc)

def step_parse_law_clause_condition_scan(+file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +beg: Nat, +universal: Bool, +quantity: Ast.Quantity, +key: String, +key_beg: Nat, +key_end: Nat, +ty: Ast.SyntaxTerm, +next_scope: List<&2, Scope>, +next_depth: Nat, +acc: List<&2, Ast.Clause>) -> FeedbackControl:
  match scanned:
    case +where_token <> after_where:
      match where_token:
        case Lexer.TokenInfo{ _, "where",  _,  _,  _,  _}:
          feedback_attach(step_parse_term(file, after_where, next_scope, next_depth, 0n), feedback_make_Kont_345864(file, beg, universal, quantity, key, key_beg, ty, next_scope, next_depth, acc))
        case _:
          step_finish_law_clause(file, tokens, beg, universal, quantity, key, key_beg, key_end, ty, next_scope, next_depth, acc)
    case Nil{}:
      step_finish_law_clause(file, Nil{}, beg, universal, quantity, key, key_beg, key_end, ty, next_scope, next_depth, acc)

def feedback_make_Kont_288017(capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: List<&2, Ast.SyntaxPattern>, capture_6: Nat, capture_7: List<&2, Ast.SyntaxTerm>) -> FeedbackFrame:
  Kont_288017{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7}

def feedback_pack_2(result: (((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Nat) & Bool)) -> FeedbackControl:
  match result:
    case (((result_0_0_0, result_0_0_1), result_0_1), result_1):
      FeedbackControl{FeedbackDone{Value_2{result_0_0_0, result_0_0_1, result_0_1, result_1}}, Nil{}, NoProgress{}, NoProgress{}}

def token_line(token: Lexer.Token) -> Nat:
  match token:
    case Lexer.TokenInfo{ _,  _,  _,  _, line,  _}:
      line

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

def step_parse_local_values_next(remaining: List<&2, Ast.SyntaxPattern>, +file: String, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, line: Nat, +acc: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match remaining:
    case Nil{}:
      feedback_pack_2((((List.reverse(&2, Ast.SyntaxTerm, acc), tokens), line), True{}))
    case _ <> more:
      feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_288017(tokens, file, scope, depth, more, first_line(skip_lines(tokens)), acc))

def feedback_make_Kont_216886(lexical_capture_49: String, lexical_capture_50: String, lexical_capture_51: Ast.SyntaxTerm, lexical_capture_52: List<&2, Lexer.Token>, lexical_capture_53: String, lexical_capture_55: Nat, lexical_capture_56: List<&2, Scope>, lexical_capture_57: Nat) -> FeedbackFrame:
  Kont_216886{lexical_capture_49, lexical_capture_50, lexical_capture_51, lexical_capture_52, lexical_capture_53, lexical_capture_55, lexical_capture_56, lexical_capture_57}

def feedback_make_Kont_217717(lexical_capture_98: String, lexical_capture_99: String, lexical_capture_100: Ast.SyntaxTerm, lexical_capture_107: Nat) -> FeedbackFrame:
  Kont_217717{lexical_capture_98, lexical_capture_99, lexical_capture_100, lexical_capture_107}

def feedback_make_Kont_218057(lexical_capture_98: String, lexical_capture_99: String, lexical_capture_100: Ast.SyntaxTerm, lexical_capture_107: Nat) -> FeedbackFrame:
  Kont_218057{lexical_capture_98, lexical_capture_99, lexical_capture_100, lexical_capture_107}

def feedback_make_Kont_218383(lexical_capture_98: String, lexical_capture_99: String, lexical_capture_100: Ast.SyntaxTerm, lexical_capture_107: Nat) -> FeedbackFrame:
  Kont_218383{lexical_capture_98, lexical_capture_99, lexical_capture_100, lexical_capture_107}

def feedback_make_parse_match_chain_state(state: MatchChainState) -> FeedbackRequest:
  Request_parse_match_chain_state{state}

def feedback_make_Kont_219577(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_8: Nat) -> FeedbackFrame:
  Kont_219577{lexical_capture_1, lexical_capture_3, lexical_capture_4, lexical_capture_8}

def step_parse_match_tail_with_head(+file: String, key: String, head: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, +beg: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_match_tail(file, tokens, beg, scope, depth), feedback_make_Kont_219577(file, key, head, beg))

def step_parse_match_chain_state(state: MatchChainState) -> FeedbackControl:
  match state:
    case MatchChainStart{+file, +key, +head, +original, scanned, +beg, +scope, +depth}:
      match scanned:
        case +name <> after_name:
          match name:
            case Lexer.TokenInfo{ Lexer.NameToken{},  next_key,  _,  _,  _,  _}:
              FeedbackControl{FeedbackCall{feedback_make_parse_match_chain_state(MatchChainAfterName{file, key, head, original, next_key, skip_lines(after_name), beg, scope, depth})}, Nil{}, NoProgress{}, NoProgress{}}
            case _:
              step_parse_match_tail_with_head(file, key, head, original, beg, scope, depth)
        case Nil{}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a match tail",  span(file, beg, beg)}, Nil{}), False{}))
    case MatchChainAfterName{+file, +key, +head, +original, next_key, scanned, +beg, +scope, +depth}:
      match scanned:
        case +colon <> after_colon:
          match colon:
            case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
              feedback_attach(step_parse_term(file, after_colon, scope, depth, 0n), feedback_make_Kont_216886(file, key, head, original, next_key, beg, scope, depth))
            case _:
              step_parse_match_tail_with_head(file, key, head, original, beg, scope, depth)
        case Nil{}:
          step_parse_match_tail_with_head(file, key, head, original, beg, scope, depth)
    case MatchChainAfterHead{+file, +key, +head, original, +next_key, +next_head, +after_head, ok_head, scanned, +beg, +scope, +depth}:
      match ok_head:
        case True{}:
          match scanned:
            case +semicolon <> +after_semicolon:
              match semicolon:
                case Lexer.TokenInfo{ _, ";",  _,  _,  _,  _}:
                  feedback_attach(FeedbackControl{FeedbackCall{feedback_make_parse_match_chain_state(MatchChainStart{file, next_key, next_head, after_semicolon, skip_lines(after_semicolon), beg, scope, depth})}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_217717(file, key, head, beg))
                case _:
                  feedback_attach(FeedbackControl{FeedbackCall{feedback_make_parse_match_chain_state(MatchChainStart{file, next_key, next_head, after_head, skip_lines(after_head), beg, scope, depth})}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_218057(file, key, head, beg))
            case Nil{}:
              feedback_attach(FeedbackControl{FeedbackCall{feedback_make_parse_match_chain_state(MatchChainStart{file, next_key, next_head, after_head, skip_lines(after_head), beg, scope, depth})}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_218383(file, key, head, beg))
        case False{}:
          feedback_pack_5(((next_head, after_head), False{}))
    case MatchChainAfterMatch{file, key, head, +matched, +after_matched, ok_matched, beg}:
      match ok_matched:
        case True{}:
          feedback_pack_5(((Ast.TermMat{key, head, matched,  span(file, beg, token_end_first(matched))}, after_matched), True{}))
        case False{}:
          feedback_pack_5(((matched, after_matched), False{}))

def feedback_make_Kont_140566(capture_1: String, capture_2: Nat) -> FeedbackFrame:
  Kont_140566{capture_1, capture_2}

def step_parse_pattern_tuple(+file: String, beg: Nat, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_pattern_atom(file, tokens, scope, depth), feedback_make_Kont_140566(file, beg))

def step_parse_term_args_after_separator(is_close: Bool, file: String, +term: Ast.SyntaxTerm, after: List<&2, Lexer.Token>, tail: List<&2, Lexer.Token>, close: String, scope: List<&2, Scope>, depth: Nat, +acc: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match is_close:
    case True{}:
      feedback_pack_9(((List.reverse(&2, Ast.SyntaxTerm, term <> acc), tail), True{}))
    case False{}:
      step_parse_term_args(file, after, close, scope, depth, term <> acc)

def step_parse_term_args_first_result_tokens(ok: Bool, +term: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, +file: String, tokens: List<&2, Lexer.Token>, +close: String, +scope: List<&2, Scope>, +depth: Nat, +acc: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match ok after:
    case True{} +separator <> +tail:
      match separator:
        case Lexer.TokenInfo{ _, ",",  _,  _,  _,  _}:
          step_parse_term_args(file, tail, close, scope, depth, term <> acc)
        case Lexer.TokenInfo{feedback_field_6_0, feedback_field_6_1, feedback_field_6_2, feedback_field_6_3, feedback_field_6_4, feedback_field_6_5}:
          step_parse_term_args_after_separator(String.eq(token_text((Lexer.TokenInfo{feedback_field_6_0, feedback_field_6_1, feedback_field_6_2, feedback_field_6_3, feedback_field_6_4, feedback_field_6_5} : Lexer.Token)), close), file, term, after, tail, close, scope, depth, acc)
    case _ _:
      feedback_pack_9(((List.reverse(&2, Ast.SyntaxTerm, acc), tokens), False{}))

def step_parse_term_args_first_result(ok: Bool, term: Ast.SyntaxTerm, after: List<&2, Lexer.Token>, file: String, tokens: List<&2, Lexer.Token>, +close: String, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  step_parse_term_args_first_result_tokens(ok, term, angle_close_tokens(String.eq(close, ">"), after), file, tokens, close, scope, depth, acc)

def feedback_make_parse_term_tail_at(file: String, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat, last_end: Nat) -> FeedbackRequest:
  Request_parse_term_tail_at{file, left, tokens, scope, depth, level, last_end}

def step_parse_term_tail(+file: String, +left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, level: Nat) -> FeedbackControl:
  FeedbackControl{FeedbackCall{feedback_make_parse_term_tail_at(file, left, tokens, scope, depth, level, token_end_first(left))}, Nil{}, NoProgress{}, NoProgress{}}

# Syntactic consumption and AST spans differ for a grouped single term.
# Operator adjacency follows the consumed closing token, not the inner span.

def feedback_make_Kont_254116(lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: Nat, lexical_capture_39: Nat) -> FeedbackFrame:
  Kont_254116{lexical_capture_1, lexical_capture_2, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_39}

def feedback_make_Kont_257580(lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_18: Lexer.Token, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: Nat, lexical_capture_19: List<&2, Lexer.Token>) -> FeedbackFrame:
  Kont_257580{lexical_capture_1, lexical_capture_2, lexical_capture_18, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_19}

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

def feedback_make_Kont_251384(lexical_capture_3: String, lexical_capture_30: Ast.SyntaxTerm, lexical_capture_5: Lexer.Token, lexical_capture_15: List<&2, Scope>, lexical_capture_17: Nat, lexical_capture_19: Nat, lexical_capture_7: List<&2, Lexer.Token>) -> FeedbackFrame:
  Kont_251384{lexical_capture_3, lexical_capture_30, lexical_capture_5, lexical_capture_15, lexical_capture_17, lexical_capture_19, lexical_capture_7}

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

def step_parse_bang_call(is_adjacent: Bool, +file: String, +left: Ast.SyntaxTerm, +open: Lexer.Token, +after_open: List<&2, Lexer.Token>, +rest: List<&2, Lexer.Token>, original: List<&2, Lexer.Token>, +next: Lexer.Token, +scope: List<&2, Scope>, +depth: Nat, level: Nat) -> FeedbackControl:
  match is_adjacent:
    case True{}:
      match left:
        case Ast.TermRef{ +_,  +_}:
          bang = { Ast.TermBang{ left,  span(file, token_beg_first(left), token_end(next))} : Ast.SyntaxTerm }
          feedback_attach(step_parse_term_args(file, after_open, ")", scope, depth, Nil{}), feedback_make_Kont_251384(file, bang, open, scope, depth, level, after_open))
        case Ast.TermVar{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermVar{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermRef{feedback_field_7_0, feedback_field_7_1}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermRef{feedback_field_7_0, feedback_field_7_1} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermBang{feedback_field_7_0, feedback_field_7_1}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermBang{feedback_field_7_0, feedback_field_7_1} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermSub{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2, feedback_field_7_3}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermSub{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2, feedback_field_7_3} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermLet{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2, feedback_field_7_3, feedback_field_7_4, feedback_field_7_5}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermLet{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2, feedback_field_7_3, feedback_field_7_4, feedback_field_7_5} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermAnn{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermAnn{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermTemplate{feedback_field_7_0, feedback_field_7_1}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermTemplate{feedback_field_7_0, feedback_field_7_1} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermType{feedback_field_7_0, feedback_field_7_1}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermType{feedback_field_7_0, feedback_field_7_1} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermQuant{}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermQuant{} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermQuantity{feedback_field_7_0, feedback_field_7_1}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermQuantity{feedback_field_7_0, feedback_field_7_1} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermMin{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermMin{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermAll{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2, feedback_field_7_3, feedback_field_7_4, feedback_field_7_5}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermAll{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2, feedback_field_7_3, feedback_field_7_4, feedback_field_7_5} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermLam{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2, feedback_field_7_3, feedback_field_7_4}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermLam{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2, feedback_field_7_3, feedback_field_7_4} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermApp{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermApp{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermAdt{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2, feedback_field_7_3}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermAdt{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2, feedback_field_7_3} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermFill{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermFill{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermPlus{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermPlus{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermCtr{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermCtr{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermString{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermString{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermMat{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2, feedback_field_7_3}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermMat{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2, feedback_field_7_3} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermAbsurd{feedback_field_7_0}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermAbsurd{feedback_field_7_0} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermEqual{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2, feedback_field_7_3}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermEqual{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2, feedback_field_7_3} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermRefl{feedback_field_7_0}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermRefl{feedback_field_7_0} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermRewrite{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2, feedback_field_7_3}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermRewrite{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2, feedback_field_7_3} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.TermHole{feedback_field_7_0, feedback_field_7_1}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.TermHole{feedback_field_7_0, feedback_field_7_1} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.BodyMatch{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.BodyMatch{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.BodyCase{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.BodyCase{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.BodyLocal{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2, feedback_field_7_3, feedback_field_7_4}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.BodyLocal{feedback_field_7_0, feedback_field_7_1, feedback_field_7_2, feedback_field_7_3, feedback_field_7_4} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
        case Ast.BodyReply{feedback_field_7_0, feedback_field_7_1}:
          feedback_pack_5(((Ast.TermHole{ "parse-error: expected a named reference before !",  span(file, token_beg_first((Ast.BodyReply{feedback_field_7_0, feedback_field_7_1} : Ast.SyntaxTerm)), token_end(next))}, rest), False{}))
    case False{}:
      feedback_pack_5(((left, original), True{}))

def feedback_make_Kont_278142(lexical_capture_3: String, lexical_capture_5: String, lexical_capture_8: Ast.SyntaxTerm, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_19: Nat) -> FeedbackFrame:
  Kont_278142{lexical_capture_3, lexical_capture_5, lexical_capture_8, lexical_capture_13, lexical_capture_15, lexical_capture_17, lexical_capture_19}

def step_parse_operator_precedence(is_nested: Bool, +file: String, name: String, priority: Nat, +left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, level: Nat, end: Nat, all_tokens: List<&2, Lexer.Token>) -> FeedbackControl:
  match is_nested:
    case True{}:
      feedback_pack_5(((left, all_tokens), True{}))
    case False{}:
      feedback_attach(step_parse_term(file, tokens, scope, depth, (priority + 1n : Nat)), feedback_make_Kont_278142(file, name, left, scope, depth, level, end))

def step_parse_operator(file: String, name: String, +priority: Nat, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, +level: Nat, end: Nat, all_tokens: List<&2, Lexer.Token>) -> FeedbackControl:
  step_parse_operator_precedence(Nat.is_lt(priority, level), file, name, priority, left, tokens, scope, depth, level, end, all_tokens)

def step_parse_comparison_operator(is_spaced: Bool, file: String, key: String, priority: Nat, +left: Ast.SyntaxTerm, remaining: List<&2, Lexer.Token>, +all_tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> FeedbackControl:
  match is_spaced:
    case True{}:
      step_parse_operator(file, key, priority, left, remaining, scope, depth, level, end, all_tokens)
    case False{}:
      feedback_pack_5(((left, all_tokens), True{}))

def step_parse_glued_operator(is_glued: Bool, file: String, key: String, priority: Nat, +left: Ast.SyntaxTerm, remaining: List<&2, Lexer.Token>, +all_tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> FeedbackControl:
  match is_glued:
    case True{}:
      feedback_pack_5(((left, all_tokens), True{}))
    case False{}:
      step_parse_operator(file, key, priority, left, remaining, scope, depth, level, end, all_tokens)

def feedback_make_Kont_275637(lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat) -> FeedbackFrame:
  Kont_275637{lexical_capture_1, lexical_capture_2, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15}

def step_parse_index_tail(+file: String, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, level: Nat, beg: Nat, open_end: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_275637(file, left, scope, depth, level, beg, open_end))

def feedback_make_Kont_262420(lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_4: List<&2, Lexer.Token>, lexical_capture_6: List<&2, Lexer.Token>, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat) -> FeedbackFrame:
  Kont_262420{lexical_capture_1, lexical_capture_2, lexical_capture_4, lexical_capture_6, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15}

def step_parse_less_or_adt_args(+file: String, left: Ast.SyntaxTerm, +tokens: List<&2, Lexer.Token>, all_tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, level: Nat, end: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, tokens, scope, depth, 5n), feedback_make_Kont_262420(file, left, tokens, all_tokens, scope, depth, level, end))

def step_parse_less_or_adt_nested(is_spaced: Bool, file: String, +left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, +all_tokens: List<&2, Lexer.Token>, open_beg: Nat, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> FeedbackControl:
  match is_spaced:
    case True{}:
      feedback_pack_5(((left, all_tokens), True{}))
    case False{}:
      step_parse_less_or_adt_args(file, left, tokens, all_tokens, scope, depth, level, end)

def step_parse_less_or_adt_precedence(is_nested: Bool, +file: String, +left: Ast.SyntaxTerm, +tokens: List<&2, Lexer.Token>, +all_tokens: List<&2, Lexer.Token>, +open_beg: Nat, +scope: List<&2, Scope>, +depth: Nat, +level: Nat, +end: Nat) -> FeedbackControl:
  match is_nested:
    case True{}:
      step_parse_less_or_adt_nested(Nat.is_lt(token_end_first(left), open_beg), file, left, tokens, all_tokens, open_beg, scope, depth, level, end)
    case False{}:
      step_parse_less_or_adt_args(file, left, tokens, all_tokens, scope, depth, level, end)

def step_parse_less_or_adt(file: String, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, all_tokens: List<&2, Lexer.Token>, open_beg: Nat, scope: List<&2, Scope>, depth: Nat, +level: Nat, end: Nat) -> FeedbackControl:
  step_parse_less_or_adt_precedence(Nat.is_lt(4n, level), file, left, tokens, all_tokens, open_beg, scope, depth, level, end)

def feedback_make_Kont_267754(lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat) -> FeedbackFrame:
  Kont_267754{lexical_capture_3, lexical_capture_4, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15}

def step_parse_min_precedence(is_nested: Bool, +file: String, +left: Ast.SyntaxTerm, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, level: Nat, end: Nat) -> FeedbackControl:
  match is_nested:
    case True{}:
      feedback_pack_5(((left, tokens), True{}))
    case False{}:
      feedback_attach(step_parse_term(file, tokens, scope, depth, 5n), feedback_make_Kont_267754(file, left, scope, depth, level, end))

def step_parse_min_operator(file: String, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, +level: Nat, end: Nat) -> FeedbackControl:
  step_parse_min_precedence(Nat.is_lt(5n, level), file, left, tokens, scope, depth, level, end)

def feedback_make_Kont_266459(lexical_capture_3: String, lexical_capture_5: String, lexical_capture_8: Ast.SyntaxTerm, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_19: Nat) -> FeedbackFrame:
  Kont_266459{lexical_capture_3, lexical_capture_5, lexical_capture_8, lexical_capture_13, lexical_capture_15, lexical_capture_17, lexical_capture_19}

def operator_rhs_level(right_assoc: Bool, priority: Nat) -> Nat:
  match right_assoc:
    case True{}:
      priority
    case False{}:
      (priority + 1n : Nat)

def step_parse_operator_right_precedence(is_nested: Bool, +file: String, key: String, priority: Nat, +left: Ast.SyntaxTerm, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, level: Nat, end: Nat, right_assoc: Bool) -> FeedbackControl:
  match is_nested:
    case True{}:
      feedback_pack_5(((left, tokens), True{}))
    case False{}:
      rhs_level = operator_rhs_level(right_assoc, priority)
      feedback_attach(step_parse_term(file, tokens, scope, depth, rhs_level), feedback_make_Kont_266459(file, key, left, scope, depth, level, end))

def step_parse_operator_right(file: String, key: String, +priority: Nat, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, +level: Nat, end: Nat, right_assoc: Bool) -> FeedbackControl:
  step_parse_operator_right_precedence(Nat.is_lt(priority, level), file, key, priority, left, tokens, scope, depth, level, end, right_assoc)

def feedback_make_Kont_270151(lexical_capture_17: Bool, lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat, lexical_capture_6: List<&2, Lexer.Token>) -> FeedbackFrame:
  Kont_270151{lexical_capture_17, lexical_capture_3, lexical_capture_4, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15, lexical_capture_6}

def step_parse_pair_operator_precedence(is_nested: Bool, +file: String, +left: Ast.SyntaxTerm, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, level: Nat, end: Nat, amp: Bool) -> FeedbackControl:
  match is_nested:
    case False{}:
      feedback_attach(step_parse_term(file, tokens, scope, depth, 1n), feedback_make_Kont_270151(amp, file, left, scope, depth, level, end, tokens))
    case True{}:
      feedback_pack_5(((left, tokens), True{}))

def step_parse_pair_operator(+file: String, left: Ast.SyntaxTerm, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +level: Nat, end: Nat, amp: Bool) -> FeedbackControl:
  step_parse_pair_operator_precedence(Nat.is_lt(1n, level), file, left, tokens, scope, depth, level, end, amp)

def step_parse_spaced_operator(is_spaced: Bool, file: String, +left: Ast.SyntaxTerm, remaining: List<&2, Lexer.Token>, +all_tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> FeedbackControl:
  match is_spaced:
    case True{}:
      step_parse_operator(file, ".mod", 11n, left, remaining, scope, depth, level, end, all_tokens)
    case False{}:
      feedback_pack_5(((left, all_tokens), True{}))

def step_parse_term_tail_after_line(file: String, +left: Ast.SyntaxTerm, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat, +all_tokens: List<&2, Lexer.Token>, last_end: Nat) -> FeedbackControl:
  match tokens:
    case +next <> +rest:
      match next:
        case Lexer.TokenInfo{ _, "(", _, _, _, _}:
          feedback_pack_5(((left, all_tokens), True{}))
        case Lexer.TokenInfo{ _, "[", _, _, _, _}:
          feedback_pack_5(((left, all_tokens), True{}))
        case _:
          FeedbackControl{FeedbackCall{feedback_make_parse_term_tail_at(file, left, tokens, scope, depth, level, last_end)}, Nil{}, NoProgress{}, NoProgress{}}
    case Nil{}:
      feedback_pack_5(((left, tokens), True{}))

def step_parse_term_tail_at(+file: String, +left: Ast.SyntaxTerm, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +level: Nat, +last_end: Nat) -> FeedbackControl:
  match tokens:
    case +next <> +rest:
      match next:
        case Lexer.TokenInfo{ Lexer.NewlineToken{},  _,  _,  _,  _,  _}:
          step_parse_term_tail_after_line(file, left, skip_lines(rest), scope, depth, level, tokens, last_end)
        case Lexer.TokenInfo{ Lexer.SymbolToken{}, text, +beg, +end,  _,  _}:
          match text:
            case "->":
              match level:
                case 0n:
                  feedback_attach(step_parse_term(file, rest, extend_scope("_", depth, scope), (depth + 1n : Nat), 0n), feedback_make_Kont_254116(file, left, scope, depth, level, end))
                case _:
                  feedback_pack_5(((left, tokens), True{}))
            case "<":
              step_parse_less_or_adt(file, left, rest, tokens, beg, scope, depth, level, end)
            case "<&>":
              step_parse_min_operator(file, left, rest, scope, depth, level, end)
            case "<>":
              step_parse_operator_right(file, "Con", 5n, left, rest, scope, depth, level, end, True{})
            case "++":
              step_parse_operator_right(file, "String.append", 5n, left, rest, scope, depth, level, end, True{})
            case "||":
              step_parse_operator(file, "Bool.or", 2n, left, rest, scope, depth, level, end, tokens)
            case "&&":
              step_parse_operator(file, "Bool.and", 3n, left, rest, scope, depth, level, end, tokens)
            case "<=":
              step_parse_comparison_operator(Nat.is_lt(last_end, beg), file, ".is_le", 4n, left, rest, tokens, scope, depth, level, end)
            case ">=":
              step_parse_comparison_operator(Nat.is_lt(last_end, beg), file, ".is_ge", 4n, left, rest, tokens, scope, depth, level, end)
            case ">":
              step_parse_comparison_operator(Nat.is_lt(last_end, beg), file, ".is_gt", 4n, left, rest, tokens, scope, depth, level, end)
            case ".|.":
              step_parse_operator(file, ".or", 6n, left, rest, scope, depth, level, end, tokens)
            case ".^.":
              step_parse_operator(file, ".xor", 7n, left, rest, scope, depth, level, end, tokens)
            case ".&.":
              step_parse_operator(file, ".and", 8n, left, rest, scope, depth, level, end, tokens)
            case "<<":
              step_parse_operator(file, ".shln", 9n, left, rest, scope, depth, level, end, tokens)
            case ">>":
              step_parse_comparison_operator(Nat.is_lt(last_end, beg), file, ".shrn", 9n, left, rest, tokens, scope, depth, level, end)
            case "+":
              step_parse_glued_operator(operator_glued_name(end, rest), file, ".add", 10n, left, rest, tokens, scope, depth, level, end)
            case "&":
              step_parse_pair_operator(file, left, rest, scope, depth, level, end, True{})
            case "|":
              step_parse_pair_operator(file, left, rest, scope, depth, level, end, False{})
            case "-":
              step_parse_glued_operator(operator_glued_name(end, rest), file, ".sub", 10n, left, rest, tokens, scope, depth, level, end)
            case "*":
              step_parse_operator(file, ".mul", 11n, left, rest, scope, depth, level, end, tokens)
            case "/":
              step_parse_operator(file, ".div", 11n, left, rest, scope, depth, level, end, tokens)
            case "%":
              step_parse_spaced_operator(has_space_after(end, rest), file, left, rest, tokens, scope, depth, level, end)
            case "!":
              match rest:
                case +open <> after_open:
                  match open:
                    case Lexer.TokenInfo{ _, "(",  _,  _,  _,  _}:
                      step_parse_bang_call(Nat.is_eq(end, token_beg(open)), file, left, open, after_open, rest, tokens, next, scope, depth, level)
                    case _:
                      feedback_pack_5(((left, tokens), True{}))
                case Nil{}:
                  feedback_pack_5(((left, tokens), True{}))
            case "(":
              feedback_attach(step_parse_term_args(file, rest, ")", scope, depth, Nil{}), feedback_make_Kont_257580(file, left, next, scope, depth, level, rest))
            case "[":
              step_parse_index_tail(file, left, rest, scope, depth, level, token_beg_first(left), end)
            case _:
              feedback_pack_5(((left, tokens), True{}))
        case Lexer.TokenInfo{ Lexer.NameToken{},  _,  _,  _,  _,  _}:
          feedback_pack_5(((left, tokens), True{}))
        case _:
          feedback_pack_5(((left, tokens), True{}))
    case Nil{}:
      feedback_pack_5(((left, tokens), True{}))

def step_parse_terms_until_colon_result(ok: Bool, +term: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, +file: String, +scope: List<&2, Scope>, +depth: Nat, +acc: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match ok after:
    case True{} _:
      match after:
        case +separator <> tail:
          match separator:
            case Lexer.TokenInfo{ _, ",",  _,  _,  _,  _}:
              step_parse_terms_until_colon(file, tail, scope, depth, term <> acc)
            case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
              feedback_pack_9(((List.reverse(&2, Ast.SyntaxTerm, term <> acc), after), True{}))
            case _:
              step_parse_terms_until_colon(file, after, scope, depth, term <> acc)
        case Nil{}:
          feedback_pack_9(((List.reverse(&2, Ast.SyntaxTerm, term <> acc), after), False{}))
    case False{} _:
      feedback_pack_9(((List.reverse(&2, Ast.SyntaxTerm, acc), after), False{}))

def feedback_pack_10(result: ((List<&2, Ast.TopLevel> & Bool) & List<&2, Lexer.Token>)) -> FeedbackControl:
  match result:
    case ((result_0_0, result_0_1), result_1):
      FeedbackControl{FeedbackDone{Value_10{result_0_0, result_0_1, result_1}}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_make_Kont_352782(lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>) -> FeedbackFrame:
  Kont_352782{lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9}

def feedback_make_Kont_353072(lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>) -> FeedbackFrame:
  Kont_353072{lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9}

def feedback_make_Kont_353365(lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>) -> FeedbackFrame:
  Kont_353365{lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9}

def feedback_make_Kont_353656(lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>) -> FeedbackFrame:
  Kont_353656{lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9}

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

def feedback_make_Kont_325042(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat) -> FeedbackFrame:
  Kont_325042{lexical_capture_1, lexical_capture_3, lexical_capture_5}

def step_parse_definition_with_binders(+file: String, key: String, beg: Nat, tokens: List<&2, Lexer.Token>, path: String) -> FeedbackControl:
  feedback_attach(step_parse_def_binders(file, tokens, Nil{}, 0n, Nil{}), feedback_make_Kont_325042(file, key, beg))

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

def feedback_make_Kont_348170(lexical_capture_1: String, lexical_capture_17: String, lexical_capture_5: Nat, lexical_capture_24: Lexer.Token, lexical_capture_25: List<&2, Lexer.Token>) -> FeedbackFrame:
  Kont_348170{lexical_capture_1, lexical_capture_17, lexical_capture_5, lexical_capture_24, lexical_capture_25}

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
                  feedback_attach(step_parse_law_clauses(file, after_colon, Nil{}, 0n, Nil{}), feedback_make_Kont_348170(file, key, beg, colon, after_colon))
                case Lexer.TokenInfo{feedback_field_10_0, feedback_field_10_1, feedback_field_10_2, feedback_field_10_3, feedback_field_10_4, feedback_field_10_5}:
                  feedback_pack_6(law_failure(file, key, beg, token_beg((Lexer.TokenInfo{feedback_field_10_0, feedback_field_10_1, feedback_field_10_2, feedback_field_10_3, feedback_field_10_4, feedback_field_10_5} : Lexer.Token)), after_name))
            case Nil{}:
              feedback_pack_6(law_failure(file, key, beg, beg, after_name))
        case Lexer.TokenInfo{feedback_field_14_0, feedback_field_14_1, feedback_field_14_2, feedback_field_14_3, feedback_field_14_4, feedback_field_14_5}:
          feedback_pack_6(law_failure(file, "", beg, token_end((Lexer.TokenInfo{feedback_field_14_0, feedback_field_14_1, feedback_field_14_2, feedback_field_14_3, feedback_field_14_4, feedback_field_14_5} : Lexer.Token)), tokens))
    case Nil{}:
      feedback_pack_6(law_failure(file, "", beg, beg, Nil{}))

def feedback_make_Kont_337453(lexical_capture_26: Lexer.Token, lexical_capture_1: String, lexical_capture_19: String, lexical_capture_5: Nat, lexical_capture_7: Nat) -> FeedbackFrame:
  Kont_337453{lexical_capture_26, lexical_capture_1, lexical_capture_19, lexical_capture_5, lexical_capture_7}

def feedback_make_Kont_337919(lexical_capture_26: Lexer.Token, lexical_capture_1: String, lexical_capture_19: String, lexical_capture_5: Nat, lexical_capture_7: Nat) -> FeedbackFrame:
  Kont_337919{lexical_capture_26, lexical_capture_1, lexical_capture_19, lexical_capture_5, lexical_capture_7}

def feedback_make_Kont_335852(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: List<&2, Ast.TelescopeItem>, lexical_capture_11: List<&2, Lexer.Token>, lexical_capture_16: List<&2, Scope>, lexical_capture_18: Nat) -> FeedbackFrame:
  Kont_335852{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_16, lexical_capture_18}

def type_failure(+file: String, key: String, beg: Nat, +end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  error = { Ast.TermHole{ "parse-error: malformed or unsupported type declaration",  span(file, end, end)} : Ast.SyntaxTerm }
  declaration = { Ast.TypeDecl{key,  Nil{},  error,  Nil{},  span(file, beg, end)} : Ast.TypeDecl }
  ((Ast.TypeTop{declaration}, rest), False{})

def step_parse_type_header_scan(+file: String, +key: String, +beg: Nat, col: Nat, params: List<&2, Ast.TelescopeItem>, +tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match scanned:
    case +is_token <> after_is:
      match is_token:
        case Lexer.TokenInfo{ _, "is",  _,  _,  _,  _}:
          feedback_attach(step_parse_term(file, after_is, scope, depth, 0n), feedback_make_Kont_335852(file, key, beg, col, params, tokens, scope, depth))
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
                  feedback_attach(step_parse_def_binders(file, after_open, Nil{}, 0n, Nil{}), feedback_make_Kont_337453(open, file, key, beg, col))
                case Lexer.TokenInfo{_, "<-", start, end, line, column}:
                  erased = { Lexer.TokenInfo{Lexer.SymbolToken{}, "-", (start + 1n : Nat), end, line, (column + 1n : Nat)} : Lexer.Token }
                  feedback_attach(step_parse_def_binders(file, erased <> after_open, Nil{}, 0n, Nil{}), feedback_make_Kont_337919(open, file, key, beg, col))
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

def feedback_make_Kont_330212() -> FeedbackFrame:
  Kont_330212{}

def feedback_make_Kont_330347() -> FeedbackFrame:
  Kont_330347{}

def step_parse_unsafe_definition(+tokens: List<&2, Lexer.Token>, +file: String, +path: String) -> FeedbackControl:
  match tokens:
    case Lexer.TokenInfo{_, "def", _, _, _, _} <> _:
      feedback_attach(step_parse_definition(file, tokens, path), feedback_make_Kont_330212())
    case Nil{}:
      feedback_attach(step_parse_definition(file, (Nil{} : List<&2, Lexer.Token>), path), feedback_make_Kont_330347())
    case Con{feedback_field_4_0, feedback_field_4_1}:
      feedback_attach(step_parse_definition(file, (Con{feedback_field_4_0, feedback_field_4_1} : List<&2, Lexer.Token>), path), feedback_make_Kont_330347())

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
          feedback_attach(step_parse_law_decl(file, rest, beg), feedback_make_Kont_352782(owners, rest, tokens, file, path, acc))
        case Lexer.TokenInfo{ Lexer.NameToken{},  "type", beg,  _,  _, col}:
          feedback_attach(step_parse_type_decl(file, rest, beg, col), feedback_make_Kont_353072(owners, rest, tokens, file, path, acc))
        case Lexer.TokenInfo{ Lexer.SymbolToken{},  "@",  _,  _,  _,  _}:
          feedback_attach(step_parse_unsafe(file, rest, path), feedback_make_Kont_353365(owners, rest, tokens, file, path, acc))
        case Lexer.TokenInfo{ Lexer.NameToken{},  "def", beg, end, line, col}:
          feedback_attach(step_parse_definition(file, Lexer.TokenInfo{Lexer.NameToken{}, "def", beg, end, line, col} <> rest, path), feedback_make_Kont_353656(owners, rest, tokens, file, path, acc))
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

def step_parse_top_result(validation: Map<&2, TopOwner> & Bool, +top: Ast.TopLevel, +after: List<&2, Lexer.Token>, tokens: List<&2, Lexer.Token>, file: String, path: String, +acc: List<&2, Ast.TopLevel>) -> FeedbackControl:
  match validation:
    case (owners, ok):
      match ok:
        case True{}:
          step_parse_top_scan(file, after, skip_lines(after), path, top <> acc, top_owner_set(top, owners))
        case False{}:
          feedback_pack_10(((List.reverse(&2, Ast.TopLevel, top <> acc), False{}), after))

def feedback_pack_7(result: ((List<&2, Ast.ConstructorDecl> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  match result:
    case ((result_0_0, result_0_1), result_1):
      FeedbackControl{FeedbackDone{Value_7{result_0_0, result_0_1, result_1}}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_make_Kont_332964(lexical_capture_3: String, lexical_capture_26: Lexer.Token, lexical_capture_27: List<&2, Lexer.Token>, lexical_capture_9: Nat, lexical_capture_12: List<&2, Scope>, lexical_capture_14: Nat, lexical_capture_16: List<&2, Ast.ConstructorDecl>, lexical_capture_18: String, lexical_capture_20: Nat) -> FeedbackFrame:
  Kont_332964{lexical_capture_3, lexical_capture_26, lexical_capture_27, lexical_capture_9, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_18, lexical_capture_20}

def step_parse_type_constructor_indent(is_indented: Bool, +file: String, +tokens: List<&2, Lexer.Token>, rest: List<&2, Lexer.Token>, col: Nat, +scope: List<&2, Scope>, +depth: Nat, +acc: List<&2, Ast.ConstructorDecl>, key: String, beg: Nat) -> FeedbackControl:
  match is_indented:
    case True{}:
      match rest:
        case +open <> +after_open:
          match open:
            case Lexer.TokenInfo{ _, "{",  _,  _,  _,  _}:
              feedback_attach(step_parse_def_binders(file, after_open, scope, depth, Nil{}), feedback_make_Kont_332964(file, open, after_open, col, scope, depth, acc, key, beg))
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

def step_parse_type_constructor_fields_result(ok_fields: Bool, fields: List<&2, Ast.TelescopeItem>, +after_fields: List<&2, Lexer.Token>, +file: String, open: Lexer.Token, after_open: List<&2, Lexer.Token>, col: Nat, scope: List<&2, Scope>, depth: Nat, +acc: List<&2, Ast.ConstructorDecl>, key: String, beg: Nat) -> FeedbackControl:
  match ok_fields:
    case True{}:
      item = { Ast.Constructor{key, fields, span(file, beg, token_end_of(after_fields, token_end(open)))} : Ast.ConstructorDecl }
      step_parse_type_constructors_scan(file, after_fields, skip_lines(after_fields), col, scope, depth, item <> acc)
    case False{}:
      feedback_pack_7(((List.reverse(&2, Ast.ConstructorDecl, acc), after_open), False{}))

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

def step_pattern_scan_empty_step(mode: PatternScanMode, +file: String, +tokens: List<&2, Lexer.Token>, +frames: List<&2, PatternFrame>, +scope: List<&2, Scope>, +depth: Nat, +goal: PatternScanGoal) -> FeedbackControl:
  match mode:
    case PatternBadNat{beg, end}:
      step_pattern_finish(goal, Ast.PatternVar{"", depth, Ast.QOne{}, span(file, beg, end)}, tokens, scope, depth, False{})
    case PatternCompleted{+pattern}:
      match frames:
        case PatternFrameOf{key, beg, end, fields, root_scope, root_depth} <> parents:
          step_pattern_finish(goal, Ast.PatternCtr{key, List.reverse(&2, Ast.SyntaxPattern, pattern <> fields), span(file, beg, end)}, tokens, root_scope, root_depth, False{})
        case Nil{}:
          step_pattern_finish(goal, pattern, tokens, scope, depth, True{})
    case PatternExpect{quantity, +beg}:
      match frames:
        case PatternFrameOf{key, start, end, fields, root_scope, root_depth} <> parents:
          step_pattern_finish(goal, Ast.PatternCtr{key, List.reverse(&2, Ast.SyntaxPattern, fields), span(file, start, end)}, tokens, root_scope, root_depth, False{})
        case Nil{}:
          step_pattern_finish(goal, Ast.PatternVar{"", depth, quantity, span(file, beg, beg)}, tokens, scope, depth, False{})

def pattern_completed_text_test_5(same: Bool, +text: String) -> PatternCompletedText:
  match same:
    case True{}:
      PatternCompletedTextRow23{}
    case False{}:
      PatternCompletedTextOther{}

def pattern_completed_text_test_4(same: Bool, +text: String) -> PatternCompletedText:
  match same:
    case True{}:
      PatternCompletedTextRow19{}
    case False{}:
      pattern_completed_text_test_5(String.eq(text, "+"), text)

def pattern_completed_text_test_3(same: Bool, +text: String) -> PatternCompletedText:
  match same:
    case True{}:
      PatternCompletedTextRow18{}
    case False{}:
      pattern_completed_text_test_4(String.eq(text, "}"), text)

def pattern_completed_text_test_2(same: Bool, +text: String) -> PatternCompletedText:
  match same:
    case True{}:
      PatternCompletedTextRow17{}
    case False{}:
      pattern_completed_text_test_3(String.eq(text, "]"), text)

def pattern_completed_text_test_1(same: Bool, +text: String) -> PatternCompletedText:
  match same:
    case True{}:
      PatternCompletedTextRow16{}
    case False{}:
      pattern_completed_text_test_2(String.eq(text, ":"), text)

def pattern_completed_text_test_0(same: Bool, +text: String) -> PatternCompletedText:
  match same:
    case True{}:
      PatternCompletedTextRow15{}
    case False{}:
      pattern_completed_text_test_1(String.eq(text, ","), text)

def pattern_completed_text(+text: String) -> PatternCompletedText:
  pattern_completed_text_test_0(String.eq(text, "<>"), text)

def feedback_make_Kont_149803(capture_1: String, capture_2: Ast.SyntaxPattern, capture_3: List<&2, PatternFrame>, capture_4: List<&2, Scope>, capture_5: Nat, capture_6: PatternScanGoal) -> FeedbackFrame:
  Kont_149803{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6}

def step_pattern_scan_row_15(ctx: PatternScanContext, rest: List<&2, Lexer.Token>, left: Ast.SyntaxPattern) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      feedback_attach(step_parse_pattern_atom(file, rest, scope, depth), feedback_make_Kont_149803(file, left, frames, scope, depth, goal))

def step_pattern_scan_row_16(ctx: PatternScanContext, +pattern: Ast.SyntaxPattern, +cursor_tail_1: List<&2, Lexer.Token>) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, +goal}:
      match frames:
        case PatternFrameOf{key, beg, end, fields, root_scope, root_depth} <> parents:
          FeedbackControl{FeedbackCall{feedback_make_pattern_scan(cursor_tail_1, file, PatternExpect{Ast.QOne{}, 0n}, PatternFrameOf{key, beg, end, pattern <> fields, root_scope, root_depth} <> parents, scope, depth, goal)}, Nil{}, NoProgress{}, NoProgress{}}
        case Nil{}:
          match goal:
            case PatternSingleGoal{}:
              feedback_pack_18(PatternSingleOutcome{pattern, tokens, scope, depth, True{}})
            case PatternCaseGoal{acc, before_scope, before_depth}:
              FeedbackControl{FeedbackCall{feedback_make_pattern_scan(cursor_tail_1, file, PatternExpect{Ast.QOne{}, 0n}, Nil{}, scope, depth, PatternCaseGoal{pattern <> acc, scope, depth})}, Nil{}, NoProgress{}, NoProgress{}}

def step_pattern_scan_row_17(ctx: PatternScanContext, +pattern: Ast.SyntaxPattern) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, +goal}:
      match frames:
        case PatternFrameOf{key, beg, end, fields, root_scope, root_depth} <> parents:
          step_pattern_finish(goal, Ast.PatternCtr{key, List.reverse(&2, Ast.SyntaxPattern, pattern <> fields), span(file, beg, end)}, tokens, root_scope, root_depth, False{})
        case Nil{}:
          match goal:
            case PatternSingleGoal{}:
              feedback_pack_18(PatternSingleOutcome{pattern, tokens, scope, depth, True{}})
            case PatternCaseGoal{acc, before_scope, before_depth}:
              feedback_pack_18(PatternCaseOutcome{List.reverse(&2, Ast.SyntaxPattern, pattern <> acc), tokens, scope, depth, True{}})

def pattern_list_fields(fields: List<&2, Ast.SyntaxPattern>, result: Ast.SyntaxPattern, +file: String, +beg: Nat, +end: Nat) -> Ast.SyntaxPattern:
  match fields:
    case Nil{}:
      result
    case field <> rest:
      pattern_list_fields(rest, Ast.PatternCtr{"Con", [field, result], span(file, beg, end)}, file, beg, end)

def make_pattern_list(fields: List<&2, Ast.SyntaxPattern>, +file: String, +beg: Nat, +end: Nat) -> Ast.SyntaxPattern:
  pattern_list_fields(fields, Ast.PatternCtr{"Nil", Nil{}, span(file, beg, end)}, file, beg, end)

def step_pattern_scan_row_18(ctx: PatternScanContext, close_end: Nat, +pattern: Ast.SyntaxPattern, cursor_tail_1: List<&2, Lexer.Token>) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, +goal}:
      match frames:
        case PatternFrameOf{"[]", beg, _, fields, _, _} <> parents:
          FeedbackControl{FeedbackCall{feedback_make_pattern_scan(cursor_tail_1, file, PatternCompleted{make_pattern_list(pattern <> fields, file, beg, close_end)}, parents, scope, depth, goal)}, Nil{}, NoProgress{}, NoProgress{}}
        case _:
          step_pattern_finish(goal, pattern, tokens, scope, depth, False{})

def step_pattern_scan_row_19(ctx: PatternScanContext, +close_end: Nat, +pattern: Ast.SyntaxPattern, +cursor_tail_1: List<&2, Lexer.Token>) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, +goal}:
      match frames:
        case PatternFrameOf{"[]", beg, _, fields, root_scope, root_depth} <> _:
          step_pattern_finish(goal, make_pattern_list(pattern <> fields, file, beg, close_end), tokens, root_scope, root_depth, False{})
        case PatternFrameOf{key, beg, end, fields, root_scope, root_depth} <> parents:
          FeedbackControl{FeedbackCall{feedback_make_pattern_scan(cursor_tail_1, file, PatternCompleted{Ast.PatternCtr{key, List.reverse(&2, Ast.SyntaxPattern, pattern <> fields), span(file, beg, close_end)}}, parents, scope, depth, goal)}, Nil{}, NoProgress{}, NoProgress{}}
        case Nil{}:
          step_pattern_finish(goal, pattern, tokens, scope, depth, True{})

def step_pattern_scan_row_20(ctx: PatternScanContext, +pattern: Ast.SyntaxPattern, +cursor_tail_1: List<&2, Lexer.Token>) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, +frames, +scope, +depth, +goal}:
      match frames:
        case +_ <> _:
          FeedbackControl{FeedbackCall{feedback_make_pattern_scan(cursor_tail_1, file, PatternCompleted{pattern}, frames, scope, depth, goal)}, Nil{}, NoProgress{}, NoProgress{}}
        case Nil{}:
          match goal:
            case PatternSingleGoal{}:
              feedback_pack_18(PatternSingleOutcome{pattern, tokens, scope, depth, True{}})
            case PatternCaseGoal{acc, before_scope, before_depth}:
              FeedbackControl{FeedbackCall{feedback_make_pattern_scan(cursor_tail_1, file, PatternCompleted{pattern}, Nil{}, scope, depth, PatternCaseGoal{acc, before_scope, before_depth})}, Nil{}, NoProgress{}, NoProgress{}}

def step_pattern_scan_row_21(ctx: PatternScanContext, key: String, beg: Nat, end: Nat, +pattern: Ast.SyntaxPattern, +cursor_tail_2: List<&2, Lexer.Token>) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, +goal}:
      match frames:
        case PatternFrameOf{parent, start, parent_end, fields, root_scope, root_depth} <> parents:
          FeedbackControl{FeedbackCall{feedback_make_pattern_scan(cursor_tail_2, file, PatternExpect{Ast.QOne{}, 0n}, PatternFrameOf{key, beg, end, Nil{}, scope, depth} <> (PatternFrameOf{parent, start, parent_end, pattern <> fields, root_scope, root_depth} <> parents), scope, depth, goal)}, Nil{}, NoProgress{}, NoProgress{}}
        case Nil{}:
          step_pattern_finish(goal, pattern, tokens, scope, depth, True{})

def step_pattern_scan_row_22(ctx: PatternScanContext, +key: String, beg: Nat, end: Nat, +pattern: Ast.SyntaxPattern, +cursor_tail_1: List<&2, Lexer.Token>) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, +goal}:
      match frames:
        case PatternFrameOf{parent, start, parent_end, fields, root_scope, root_depth} <> parents:
          FeedbackControl{FeedbackCall{feedback_make_pattern_scan(cursor_tail_1, file, PatternCompleted{Ast.PatternVar{key, depth, Ast.QOne{}, span(file, beg, end)}}, PatternFrameOf{parent, start, parent_end, pattern <> fields, root_scope, root_depth} <> parents, extend_scope(key, depth, scope), (depth + 1n : Nat), goal)}, Nil{}, NoProgress{}, NoProgress{}}
        case Nil{}:
          step_pattern_finish(goal, pattern, tokens, scope, depth, True{})

def step_pattern_scan_row_23(ctx: PatternScanContext, beg: Nat, +pattern: Ast.SyntaxPattern, +cursor_tail_1: List<&2, Lexer.Token>) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, +goal}:
      match frames:
        case PatternFrameOf{parent, start, parent_end, fields, root_scope, root_depth} <> parents:
          FeedbackControl{FeedbackCall{feedback_make_pattern_scan(cursor_tail_1, file, PatternExpect{Ast.QMany{}, beg}, PatternFrameOf{parent, start, parent_end, pattern <> fields, root_scope, root_depth} <> parents, scope, depth, goal)}, Nil{}, NoProgress{}, NoProgress{}}
        case Nil{}:
          step_pattern_finish(goal, pattern, tokens, scope, depth, True{})

def step_pattern_scan_row_24(ctx: PatternScanContext, +pattern: Ast.SyntaxPattern) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, +goal}:
      match frames:
        case PatternFrameOf{key, beg, end, fields, root_scope, root_depth} <> parents:
          step_pattern_finish(goal, Ast.PatternCtr{key, List.reverse(&2, Ast.SyntaxPattern, pattern <> fields), span(file, beg, end)}, tokens, root_scope, root_depth, False{})
        case Nil{}:
          step_pattern_finish(goal, pattern, tokens, scope, depth, True{})

def step_pattern_scan_completed_fields(choice: PatternCompletedText, kind: Lexer.TokenKind, lookahead: Maybe<&2, Lexer.Token>, +text: String, +token_beg: Nat, +token_end: Nat, +pattern: Ast.SyntaxPattern, +ctx: PatternScanContext, +cursor_tail_1: List<&2, Lexer.Token>, +cursor_tail_1: List<&2, Lexer.Token>, +cursor_tail_2: List<&2, Lexer.Token>) -> FeedbackControl:
  match choice kind lookahead:
    case PatternCompletedTextRow15{} _ _:
      step_pattern_scan_row_15(ctx, cursor_tail_1, pattern)
    case PatternCompletedTextRow16{} _ _:
      step_pattern_scan_row_16(ctx, pattern, cursor_tail_1)
    case PatternCompletedTextRow17{} _ _:
      step_pattern_scan_row_17(ctx, pattern)
    case PatternCompletedTextRow18{} _ _:
      step_pattern_scan_row_18(ctx, token_end, pattern, cursor_tail_1)
    case PatternCompletedTextRow19{} _ _:
      step_pattern_scan_row_19(ctx, token_end, pattern, cursor_tail_1)
    case _ Lexer.NewlineToken{} _:
      step_pattern_scan_row_20(ctx, pattern, cursor_tail_1)
    case _ Lexer.NameToken{} Some{Lexer.TokenInfo{_, "{", _, _, _, _}}:
      step_pattern_scan_row_21(ctx, text, token_beg, token_end, pattern, cursor_tail_2)
    case _ Lexer.NameToken{} _:
      step_pattern_scan_row_22(ctx, text, token_beg, token_end, pattern, cursor_tail_1)
    case PatternCompletedTextRow23{} _ _:
      step_pattern_scan_row_23(ctx, token_beg, pattern, cursor_tail_1)
    case _ _ _:
      step_pattern_scan_row_24(ctx, pattern)

def step_pattern_scan_completed_step(+token: Lexer.Token, lookahead: Maybe<&2, Lexer.Token>, pattern: Ast.SyntaxPattern, ctx: PatternScanContext, +cursor_tail_1: List<&2, Lexer.Token>, +cursor_tail_1: List<&2, Lexer.Token>, +cursor_tail_2: List<&2, Lexer.Token>) -> FeedbackControl:
  match token:
    case Lexer.TokenInfo{kind, +text, +beg, +end, line, col}:
      step_pattern_scan_completed_fields(pattern_completed_text(text), kind, lookahead, text, beg, end, pattern, ctx, cursor_tail_1, cursor_tail_1, cursor_tail_2)

def pattern_expect_action_test_14(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>) -> PatternExpectAction:
  match token quantity lookahead:
    case _ quantity _:
      PatternExpectActionRow25{quantity}

def pattern_expect_action_test_13(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>) -> PatternExpectAction:
  match token quantity lookahead:
    case Lexer.TokenInfo{_, "}", _, close_end, _, _} quantity _:
      PatternExpectActionRow14{quantity}
    case +next_token next_quantity next_lookahead:
      pattern_expect_action_test_14(next_token, next_quantity, next_lookahead)

def pattern_expect_action_test_12(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>) -> PatternExpectAction:
  match token quantity lookahead:
    case Lexer.TokenInfo{_, "]", _, close_end, _, _} quantity _:
      PatternExpectActionRow13{quantity}
    case +next_token next_quantity next_lookahead:
      pattern_expect_action_test_13(next_token, next_quantity, next_lookahead)

def pattern_expect_action_test_11(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>) -> PatternExpectAction:
  match token quantity lookahead:
    case Lexer.TokenInfo{Lexer.NewlineToken{}, _, _, _, _, _} quantity _:
      PatternExpectActionRow12{quantity}
    case +next_token next_quantity next_lookahead:
      pattern_expect_action_test_12(next_token, next_quantity, next_lookahead)

def pattern_expect_action_test_10(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>) -> PatternExpectAction:
  match token quantity lookahead:
    case Lexer.TokenInfo{Lexer.NumberToken{}, +text, +beg, +end, _, _} _ _:
      PatternExpectActionRow10{}
    case +next_token next_quantity next_lookahead:
      pattern_expect_action_test_11(next_token, next_quantity, next_lookahead)

def pattern_expect_action_test_9(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>) -> PatternExpectAction:
  match token quantity lookahead:
    case Lexer.TokenInfo{Lexer.NameToken{}, +key, _, end, _, _} quantity _:
      PatternExpectActionRow9{quantity}
    case +next_token next_quantity next_lookahead:
      pattern_expect_action_test_10(next_token, next_quantity, next_lookahead)

def pattern_expect_action_test_8(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>) -> PatternExpectAction:
  match token quantity lookahead:
    case Lexer.TokenInfo{Lexer.NameToken{}, +key, beg, end, _, _} Ast.QOne{} _:
      PatternExpectActionRow8{}
    case +next_token next_quantity next_lookahead:
      pattern_expect_action_test_9(next_token, next_quantity, next_lookahead)

def pattern_expect_action_test_7(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>) -> PatternExpectAction:
  match token quantity lookahead:
    case Lexer.TokenInfo{Lexer.NameToken{}, key, _, end, _, _} quantity Some{Lexer.TokenInfo{_, "{", _, _, _, _}}:
      PatternExpectActionRow7{}
    case +next_token next_quantity next_lookahead:
      pattern_expect_action_test_8(next_token, next_quantity, next_lookahead)

def pattern_expect_action_test_6(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>) -> PatternExpectAction:
  match token quantity lookahead:
    case Lexer.TokenInfo{Lexer.NameToken{}, key, beg, end, _, _} Ast.QOne{} Some{Lexer.TokenInfo{_, "{", _, _, _, _}}:
      PatternExpectActionRow6{}
    case +next_token next_quantity next_lookahead:
      pattern_expect_action_test_7(next_token, next_quantity, next_lookahead)

def pattern_expect_action_test_5(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>) -> PatternExpectAction:
  match token quantity lookahead:
    case Lexer.TokenInfo{_, "-", beg, end, _, _} Ast.QOne{} _:
      PatternExpectActionRow5{}
    case +next_token next_quantity next_lookahead:
      pattern_expect_action_test_6(next_token, next_quantity, next_lookahead)

def pattern_expect_action_test_4(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>) -> PatternExpectAction:
  match token quantity lookahead:
    case Lexer.TokenInfo{Lexer.SymbolToken{}, "+", beg, ignored_end, ignored_line, ignored_col} Ast.QOne{} _:
      PatternExpectActionRow4{}
    case +next_token next_quantity next_lookahead:
      pattern_expect_action_test_5(next_token, next_quantity, next_lookahead)

def pattern_expect_action_test_3(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>) -> PatternExpectAction:
  match token quantity lookahead:
    case Lexer.TokenInfo{Lexer.StringToken{}, text, +beg, +end, _, _} Ast.QOne{} _:
      PatternExpectActionRow3{}
    case +next_token next_quantity next_lookahead:
      pattern_expect_action_test_4(next_token, next_quantity, next_lookahead)

def pattern_expect_action_test_2(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>) -> PatternExpectAction:
  match token quantity lookahead:
    case Lexer.TokenInfo{Lexer.CharToken{}, text, +beg, +end, _, _} Ast.QOne{} _:
      PatternExpectActionRow2{}
    case +next_token next_quantity next_lookahead:
      pattern_expect_action_test_3(next_token, next_quantity, next_lookahead)

def pattern_expect_action_test_1(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>) -> PatternExpectAction:
  match token quantity lookahead:
    case Lexer.TokenInfo{_, "[", beg, end, _, _} Ast.QOne{} _:
      PatternExpectActionRow1{}
    case +next_token next_quantity next_lookahead:
      pattern_expect_action_test_2(next_token, next_quantity, next_lookahead)

def pattern_expect_action_test_0(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>) -> PatternExpectAction:
  match token quantity lookahead:
    case Lexer.TokenInfo{_, "(", beg, _, _, _} Ast.QOne{} _:
      PatternExpectActionRow0{}
    case +next_token next_quantity next_lookahead:
      pattern_expect_action_test_1(next_token, next_quantity, next_lookahead)

def pattern_expect_action(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>) -> PatternExpectAction:
  pattern_expect_action_test_0(token, quantity, lookahead)

def feedback_make_Kont_143905(capture_1: String, capture_2: List<&2, PatternFrame>, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: PatternScanGoal) -> FeedbackFrame:
  Kont_143905{capture_1, capture_2, capture_3, capture_4, capture_5}

def feedback_make_parse_pattern_tuple(file: String, beg: Nat, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackRequest:
  Request_parse_pattern_tuple{file, beg, tokens, scope, depth}

def step_pattern_scan_row_0(ctx: PatternScanContext, beg: Nat, rest: List<&2, Lexer.Token>) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_parse_pattern_tuple(file, beg, rest, scope, depth)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_143905(file, frames, scope, depth, goal))

def step_pattern_scan_row_1(ctx: PatternScanContext, beg: Nat, end: Nat, cursor_tail_1: List<&2, Lexer.Token>) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      FeedbackControl{FeedbackCall{feedback_make_pattern_scan(cursor_tail_1, file, PatternExpect{Ast.QOne{}, 0n}, PatternFrameOf{"[]", beg, end, Nil{}, scope, depth} <> frames, scope, depth, goal)}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_make_Kont_138004(capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: Nat, capture_4: Nat, capture_5: List<&2, PatternFrame>, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: PatternScanGoal) -> FeedbackFrame:
  Kont_138004{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8}

def step_pattern_literal_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, +file: String, +beg: Nat, +end: Nat, frames: List<&2, PatternFrame>, +scope: List<&2, Scope>, +depth: Nat, +goal: PatternScanGoal) -> FeedbackControl:
  match result:
    case ((term, after), True{}):
      feedback_attach(step_literal_pattern(term), feedback_make_Kont_138004(after, file, beg, end, frames, scope, depth, goal))
    case ((_, after), False{}):
      step_pattern_finish(goal, Ast.PatternVar{"", depth, Ast.QOne{}, span(file, beg, end)}, after, scope, depth, False{})

def nat_pattern(+file: String, value: Nat, +beg: Nat, +end: Nat) -> Ast.SyntaxPattern:
  match value:
    case 0n:
      Ast.PatternCtr{ "Zero",  Nil{},  span(file, beg, end)}
    case 1n+rest:
      Ast.PatternCtr{ "Succ",  [nat_pattern(file, rest, beg, end)],  span(file, beg, end)}

def feedback_make_Kont_130823(capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: Nat, capture_5: List<&2, PatternFrame>, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: PatternScanGoal) -> FeedbackFrame:
  Kont_130823{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8}

def step_pattern_nat_tail_allowed(allowed: Bool, +file: String, value: Nat, +beg: Nat, +end: Nat, +tokens: List<&2, Lexer.Token>, frames: List<&2, PatternFrame>, +scope: List<&2, Scope>, +depth: Nat, +goal: PatternScanGoal) -> FeedbackControl:
  match allowed:
    case True{}:
      feedback_attach(step_parse_pattern_atom(file, tokens, scope, depth), feedback_make_Kont_130823(file, value, beg, end, frames, scope, depth, goal))
    case False{}:
      step_pattern_finish(goal, Ast.PatternVar{"", depth, Ast.QOne{}, span(file, beg, end)}, tokens, scope, depth, False{})

def step_pattern_nat_adjacent(adjacent: Bool, +file: String, +value: Nat, +beg: Nat, +end: Nat, tail: List<&2, Lexer.Token>, tokens: List<&2, Lexer.Token>, +frames: List<&2, PatternFrame>, +scope: List<&2, Scope>, +depth: Nat, +goal: PatternScanGoal) -> FeedbackControl:
  match adjacent:
    case True{}:
      step_pattern_nat_tail_allowed(Nat.is_le(value, 256n), file, value, beg, end, tail, frames, scope, depth, goal)
    case False{}:
      FeedbackControl{FeedbackCall{feedback_make_pattern_scan(tokens, file, PatternCompleted{nat_pattern(file, value, beg, end)}, frames, scope, depth, goal)}, Nil{}, NoProgress{}, NoProgress{}}

def step_pattern_nat_after(+tokens: List<&2, Lexer.Token>, +file: String, +value: Nat, +beg: Nat, +end: Nat, +frames: List<&2, PatternFrame>, +scope: List<&2, Scope>, +depth: Nat, +goal: PatternScanGoal) -> FeedbackControl:
  match tokens:
    case Lexer.TokenInfo{_, "+", plus_beg, _, _, _} <> tail:
      step_pattern_nat_adjacent(Nat.is_eq(end, plus_beg), file, value, beg, end, tail, tokens, frames, scope, depth, goal)
    # A natural prefix consumes one +; the remaining + is the tail's quantity.
    # Split only here, after the number, so expression ++ remains concatenation.
    case Lexer.TokenInfo{Lexer.SymbolToken{}, "++", +plus_beg, plus_end, line, col} <> tail:
      remaining = { Lexer.TokenInfo{Lexer.SymbolToken{}, "+", (plus_beg + 1n : Nat), plus_end, line, (col + 1n : Nat)} <> tail : List<&2, Lexer.Token> }
      step_pattern_nat_adjacent(Nat.is_eq(end, plus_beg), file, value, beg, end, remaining, tokens, frames, scope, depth, goal)
    case Nil{}:
      FeedbackControl{FeedbackCall{feedback_make_pattern_scan((Nil{} : List<&2, Lexer.Token>), file, PatternCompleted{nat_pattern(file, value, beg, end)}, frames, scope, depth, goal)}, Nil{}, NoProgress{}, NoProgress{}}
    case Con{feedback_field_9_0, feedback_field_9_1}:
      FeedbackControl{FeedbackCall{feedback_make_pattern_scan((Con{feedback_field_9_0, feedback_field_9_1} : List<&2, Lexer.Token>), file, PatternCompleted{nat_pattern(file, value, beg, end)}, frames, scope, depth, goal)}, Nil{}, NoProgress{}, NoProgress{}}

def step_pattern_nat_read(result: Maybe<&2, Nat>, +file: String, +tokens: List<&2, Lexer.Token>, +beg: Nat, +end: Nat, frames: List<&2, PatternFrame>, +scope: List<&2, Scope>, +depth: Nat, +goal: PatternScanGoal) -> FeedbackControl:
  match result:
    case Some{value}:
      step_pattern_nat_after(tokens, file, value, beg, end, frames, scope, depth, goal)
    case None{}:
      step_pattern_finish(goal, Ast.PatternVar{"", depth, Ast.QOne{}, span(file, beg, end)}, tokens, scope, depth, False{})

def step_pattern_number_start(is_nat: Bool, +file: String, +text: String, +beg: Nat, +end: Nat, +tokens: List<&2, Lexer.Token>, +frames: List<&2, PatternFrame>, +scope: List<&2, Scope>, +depth: Nat, +goal: PatternScanGoal) -> FeedbackControl:
  match is_nat:
    case True{}:
      step_pattern_nat_read(Nat.read(drop_nat_suffix(text)), file, tokens, beg, end, frames, scope, depth, goal)
    case False{}:
      step_pattern_literal_result(parse_scalar_number(file, text, beg, end, tokens), file, beg, end, frames, scope, depth, goal)

def step_pattern_scan_row_10(ctx: PatternScanContext, +text: String, +beg: Nat, +end: Nat, +rest: List<&2, Lexer.Token>) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      step_pattern_number_start(has_nat_suffix(text), file, text, beg, end, rest, frames, scope, depth, goal)

def step_pattern_scan_row_12(ctx: PatternScanContext, quantity: Ast.Quantity, initial_beg: Nat, +cursor_tail_1: List<&2, Lexer.Token>) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      FeedbackControl{FeedbackCall{feedback_make_pattern_scan(cursor_tail_1, file, PatternExpect{quantity, initial_beg}, frames, scope, depth, goal)}, Nil{}, NoProgress{}, NoProgress{}}

def step_pattern_scan_row_13(ctx: PatternScanContext, close_end: Nat, quantity: Ast.Quantity, +initial_beg: Nat, cursor_tail_1: List<&2, Lexer.Token>) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, +goal}:
      match frames:
        case PatternFrameOf{"[]", start, _, fields, _, _} <> parents:
          FeedbackControl{FeedbackCall{feedback_make_pattern_scan(cursor_tail_1, file, PatternCompleted{make_pattern_list(fields, file, start, close_end)}, parents, scope, depth, goal)}, Nil{}, NoProgress{}, NoProgress{}}
        case _:
          step_pattern_finish(goal, Ast.PatternVar{"", depth, quantity, span(file, initial_beg, initial_beg)}, tokens, scope, depth, False{})

def step_pattern_scan_row_14(ctx: PatternScanContext, +close_end: Nat, quantity: Ast.Quantity, +initial_beg: Nat, +cursor_tail_1: List<&2, Lexer.Token>) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, +goal}:
      match frames:
        case PatternFrameOf{"[]", start, _, fields, root_scope, root_depth} <> _:
          step_pattern_finish(goal, make_pattern_list(fields, file, start, close_end), tokens, root_scope, root_depth, False{})
        case PatternFrameOf{key, start, end, fields, root_scope, root_depth} <> parents:
          FeedbackControl{FeedbackCall{feedback_make_pattern_scan(cursor_tail_1, file, PatternCompleted{Ast.PatternCtr{key, List.reverse(&2, Ast.SyntaxPattern, fields), span(file, start, close_end)}}, parents, scope, depth, goal)}, Nil{}, NoProgress{}, NoProgress{}}
        case Nil{}:
          step_pattern_finish(goal, Ast.PatternVar{"", depth, quantity, span(file, initial_beg, initial_beg)}, tokens, scope, depth, False{})

def step_pattern_scan_row_2(ctx: PatternScanContext, text: String, +beg: Nat, +end: Nat, rest: List<&2, Lexer.Token>) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      step_pattern_literal_result(parse_char_literal(file, text, beg, end, rest), file, beg, end, frames, scope, depth, goal)

def step_pattern_scan_row_25(ctx: PatternScanContext, quantity: Ast.Quantity, +initial_beg: Nat) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, +goal}:
      match frames:
        case PatternFrameOf{key, start, end, fields, root_scope, root_depth} <> parents:
          step_pattern_finish(goal, Ast.PatternCtr{key, List.reverse(&2, Ast.SyntaxPattern, fields), span(file, start, end)}, tokens, root_scope, root_depth, False{})
        case Nil{}:
          step_pattern_finish(goal, Ast.PatternVar{"", depth, quantity, span(file, initial_beg, initial_beg)}, tokens, scope, depth, False{})

def step_pattern_scan_row_3(ctx: PatternScanContext, text: String, +beg: Nat, +end: Nat, rest: List<&2, Lexer.Token>) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      step_pattern_literal_result(parse_string(file, text, beg, end, rest), file, beg, end, frames, scope, depth, goal)

def step_pattern_scan_row_4(ctx: PatternScanContext, beg: Nat, +cursor_tail_1: List<&2, Lexer.Token>) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      FeedbackControl{FeedbackCall{feedback_make_pattern_scan(cursor_tail_1, file, PatternExpect{Ast.QMany{}, beg}, frames, scope, depth, goal)}, Nil{}, NoProgress{}, NoProgress{}}

def step_pattern_scan_row_5(ctx: PatternScanContext, beg: Nat, end: Nat) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      step_pattern_finish(goal, Ast.PatternVar{"", depth, Ast.QOne{}, span(file, beg, end)}, tokens, scope, depth, False{})

def step_pattern_scan_row_6(ctx: PatternScanContext, key: String, beg: Nat, end: Nat, +cursor_tail_2: List<&2, Lexer.Token>) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      FeedbackControl{FeedbackCall{feedback_make_pattern_scan(cursor_tail_2, file, PatternExpect{Ast.QOne{}, 0n}, PatternFrameOf{key, beg, end, Nil{}, scope, depth} <> frames, scope, depth, goal)}, Nil{}, NoProgress{}, NoProgress{}}

def step_pattern_scan_row_7(ctx: PatternScanContext, key: String, end: Nat, initial_beg: Nat, +cursor_tail_2: List<&2, Lexer.Token>) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      FeedbackControl{FeedbackCall{feedback_make_pattern_scan(cursor_tail_2, file, PatternExpect{Ast.QOne{}, 0n}, PatternFrameOf{key, initial_beg, end, Nil{}, scope, depth} <> frames, scope, depth, goal)}, Nil{}, NoProgress{}, NoProgress{}}

def step_pattern_scan_row_8(ctx: PatternScanContext, +key: String, beg: Nat, end: Nat, +cursor_tail_1: List<&2, Lexer.Token>) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      FeedbackControl{FeedbackCall{feedback_make_pattern_scan(cursor_tail_1, file, PatternCompleted{Ast.PatternVar{key, depth, Ast.QOne{}, span(file, beg, end)}}, frames, extend_scope(key, depth, scope), (depth + 1n : Nat), goal)}, Nil{}, NoProgress{}, NoProgress{}}

def step_pattern_scan_row_9(ctx: PatternScanContext, +key: String, end: Nat, quantity: Ast.Quantity, initial_beg: Nat, +cursor_tail_1: List<&2, Lexer.Token>) -> FeedbackControl:
  match ctx:
    case PatternScanContext{+file, +tokens, frames, +scope, +depth, goal}:
      FeedbackControl{FeedbackCall{feedback_make_pattern_scan(cursor_tail_1, file, PatternCompleted{Ast.PatternVar{key, depth, quantity, span(file, initial_beg, end)}}, frames, extend_scope(key, depth, scope), (depth + 1n : Nat), goal)}, Nil{}, NoProgress{}, NoProgress{}}

def step_pattern_scan_expect_run(+token: Lexer.Token, action: PatternExpectAction, +initial_beg: Nat, +ctx: PatternScanContext, +cursor_tail_1: List<&2, Lexer.Token>, +cursor_tail_1: List<&2, Lexer.Token>, +cursor_tail_2: List<&2, Lexer.Token>) -> FeedbackControl:
  match token:
    case Lexer.TokenInfo{kind, +text, +token_beg, +token_end, +token_line, +token_col}:
      match action:
        case PatternExpectActionRow0{}:
          step_pattern_scan_row_0(ctx, token_beg, cursor_tail_1)
        case PatternExpectActionRow1{}:
          step_pattern_scan_row_1(ctx, token_beg, token_end, cursor_tail_1)
        case PatternExpectActionRow2{}:
          step_pattern_scan_row_2(ctx, text, token_beg, token_end, cursor_tail_1)
        case PatternExpectActionRow3{}:
          step_pattern_scan_row_3(ctx, text, token_beg, token_end, cursor_tail_1)
        case PatternExpectActionRow4{}:
          step_pattern_scan_row_4(ctx, token_beg, cursor_tail_1)
        case PatternExpectActionRow5{}:
          step_pattern_scan_row_5(ctx, token_beg, token_end)
        case PatternExpectActionRow6{}:
          step_pattern_scan_row_6(ctx, text, token_beg, token_end, cursor_tail_2)
        case PatternExpectActionRow7{}:
          step_pattern_scan_row_7(ctx, text, token_end, initial_beg, cursor_tail_2)
        case PatternExpectActionRow8{}:
          step_pattern_scan_row_8(ctx, text, token_beg, token_end, cursor_tail_1)
        case PatternExpectActionRow9{quantity}:
          step_pattern_scan_row_9(ctx, text, token_end, quantity, initial_beg, cursor_tail_1)
        case PatternExpectActionRow10{}:
          step_pattern_scan_row_10(ctx, text, token_beg, token_end, cursor_tail_1)
        case PatternExpectActionRow12{quantity}:
          step_pattern_scan_row_12(ctx, quantity, initial_beg, cursor_tail_1)
        case PatternExpectActionRow13{quantity}:
          step_pattern_scan_row_13(ctx, token_end, quantity, initial_beg, cursor_tail_1)
        case PatternExpectActionRow14{quantity}:
          step_pattern_scan_row_14(ctx, token_end, quantity, initial_beg, cursor_tail_1)
        case PatternExpectActionRow25{quantity}:
          step_pattern_scan_row_25(ctx, quantity, initial_beg)

def step_pattern_scan_expect_step(+token: Lexer.Token, quantity: Ast.Quantity, lookahead: Maybe<&2, Lexer.Token>, +initial_beg: Nat, ctx: PatternScanContext, +cursor_tail_1: List<&2, Lexer.Token>, +cursor_tail_1: List<&2, Lexer.Token>, +cursor_tail_2: List<&2, Lexer.Token>) -> FeedbackControl:
  step_pattern_scan_expect_run(token, pattern_expect_action(token, quantity, lookahead), initial_beg, ctx, cursor_tail_1, cursor_tail_1, cursor_tail_2)

def step_pattern_scan_token_step(mode: PatternScanMode, +token: Lexer.Token, +lookahead: Maybe<&2, Lexer.Token>, +file: String, +tokens: List<&2, Lexer.Token>, +frames: List<&2, PatternFrame>, +scope: List<&2, Scope>, +depth: Nat, +goal: PatternScanGoal, +cursor_tail_1: List<&2, Lexer.Token>, +cursor_tail_1: List<&2, Lexer.Token>, +cursor_tail_2: List<&2, Lexer.Token>) -> FeedbackControl:
  match mode:
    case PatternExpect{quantity, +initial_beg}:
      step_pattern_scan_expect_step(token, quantity, lookahead, initial_beg, PatternScanContext{file, tokens, frames, scope, depth, goal}, cursor_tail_1, cursor_tail_1, cursor_tail_2)
    case PatternCompleted{pattern}:
      step_pattern_scan_completed_step(token, lookahead, pattern, PatternScanContext{file, tokens, frames, scope, depth, goal}, cursor_tail_1, cursor_tail_1, cursor_tail_2)
    case PatternBadNat{beg, end}:
      step_pattern_finish(goal, Ast.PatternVar{"", depth, Ast.QOne{}, span(file, beg, end)}, tokens, scope, depth, False{})

def step_pattern_scan(+tokens: List<&2, Lexer.Token>, +file: String, +mode: PatternScanMode, +frames: List<&2, PatternFrame>, +scope: List<&2, Scope>, +depth: Nat, +goal: PatternScanGoal) -> FeedbackControl:
  match tokens:
    case +token <> +rest:
      match rest:
        case +next <> +after_open:
          step_pattern_scan_token_step(mode, token, Some{next}, file, tokens, frames, scope, depth, goal, rest, rest, after_open)
        case Nil{}:
          step_pattern_scan_token_step(mode, token, None{}, file, tokens, frames, scope, depth, goal, rest, rest, rest)
    case Nil{}:
      step_pattern_scan_empty_step(mode, file, tokens, frames, scope, depth, goal)

def feedback_dispatch(request: FeedbackRequest) -> FeedbackControl:
  match request:
    case Request_consumed_token_end_before{tokens, stop, fallback}:
      step_consumed_token_end_before(tokens, stop, fallback)
    case Request_literal_pattern_fields{terms}:
      step_literal_pattern_fields(terms)
    case Request_map_operator_term{v_0, v_2}:
      step_map_operator_term(v_0, v_2)
    case Request_map_operator_terms{v_1, v_3}:
      step_map_operator_terms(v_1, v_3)
    case Request_nat_literal_tokens_next{done, token, more, value, end, stop}:
      step_nat_literal_tokens_next(done, token, more, value, end, stop)
    case Request_parse_atom_scan{file, tokens, scanned, scope, depth}:
      step_parse_atom_scan(file, tokens, scanned, scope, depth)
    case Request_parse_body_scan{file, tokens, scanned, scope, depth, parent_col}:
      step_parse_body_scan(file, tokens, scanned, scope, depth, parent_col)
    case Request_parse_case_row_indented{is_indented, file, tokens, rest, parent_col, scope, depth, arity, acc, beg, col}:
      step_parse_case_row_indented(is_indented, file, tokens, rest, parent_col, scope, depth, arity, acc, beg, col)
    case Request_parse_def_binders_scan{file, tokens, scanned, scope, depth, acc}:
      step_parse_def_binders_scan(file, tokens, scanned, scope, depth, acc)
    case Request_parse_do_typed_bind{file, monad, args, tokens, beg, end, scope, depth, col}:
      step_parse_do_typed_bind(file, monad, args, tokens, beg, end, scope, depth, col)
    case Request_parse_imports_result{ok, item, after, file, acc}:
      step_parse_imports_result(ok, item, after, file, acc)
    case Request_parse_law_clause_condition_scan{file, tokens, scanned, beg, universal, quantity, key, key_beg, key_end, ty, next_scope, next_depth, acc}:
      step_parse_law_clause_condition_scan(file, tokens, scanned, beg, universal, quantity, key, key_beg, key_end, ty, next_scope, next_depth, acc)
    case Request_parse_local_values_next{remaining, file, tokens, scope, depth, line, acc}:
      step_parse_local_values_next(remaining, file, tokens, scope, depth, line, acc)
    case Request_parse_match_chain_state{state}:
      step_parse_match_chain_state(state)
    case Request_parse_pattern_tuple{file, beg, tokens, scope, depth}:
      step_parse_pattern_tuple(file, beg, tokens, scope, depth)
    case Request_parse_term_args_first_result{ok, term, after, file, tokens, close, scope, depth, acc}:
      step_parse_term_args_first_result(ok, term, after, file, tokens, close, scope, depth, acc)
    case Request_parse_term_tail{file, left, tokens, scope, depth, level}:
      step_parse_term_tail(file, left, tokens, scope, depth, level)
    case Request_parse_term_tail_at{file, left, tokens, scope, depth, level, last_end}:
      step_parse_term_tail_at(file, left, tokens, scope, depth, level, last_end)
    case Request_parse_terms_until_colon_result{ok, term, after, file, scope, depth, acc}:
      step_parse_terms_until_colon_result(ok, term, after, file, scope, depth, acc)
    case Request_parse_top_result{validation_0, validation_1, top, after, tokens, file, path, acc}:
      step_parse_top_result((validation_0, validation_1), top, after, tokens, file, path, acc)
    case Request_parse_type_constructor_fields_result{ok_fields, fields, after_fields, file, open, after_open, col, scope, depth, acc, key, beg}:
      step_parse_type_constructor_fields_result(ok_fields, fields, after_fields, file, open, after_open, col, scope, depth, acc, key, beg)
    case Request_pattern_scan{tokens, file, mode, frames, scope, depth, goal}:
      step_pattern_scan(tokens, file, mode, frames, scope, depth, goal)

def feedback_stack_progress(stack: List<&2, FeedbackKont>) -> Progress:
  match stack:
    case Nil{}: NoProgress{}
    case FeedbackKont{_, progress} <> tail:
      feedback_compose_progress(progress, feedback_stack_progress(tail))

def feedback_failure(progress: Progress, pending: List<&2, FeedbackKont>, stack: List<&2, FeedbackKont>) -> FeedbackRun:
  FeedbackInvariantFailure{feedback_compose_progress(progress, feedback_compose_progress(feedback_stack_progress(pending), feedback_stack_progress(stack)))}

def feedback_finish(step: FeedbackControl, stack: List<&2, FeedbackKont>) -> FeedbackRun:
  match step:
    case FeedbackControl{action, pending, progress, _}:
      match action:
        case FeedbackDone{value}:
          match pending:
            case Nil{}:
              match stack:
                case Nil{}: FeedbackComplete{value, progress}
                case frame <> tail: feedback_failure(progress, Nil{}, frame <> tail)
            case frame <> tail: feedback_failure(progress, frame <> tail, stack)
        case _: feedback_failure(progress, pending, stack)

def feedback_save_progress(progress: Progress, pending: List<&2, FeedbackKont>) -> List<&2, FeedbackKont>:
  match progress:
    case NoProgress{}: pending
    case Consumed{}:
      List.append(&2, FeedbackKont, pending, FeedbackKont{KontProgress{}, Consumed{}} <> Nil{})

def feedback_prefix_consumed(fresh: Progress, control: FeedbackControl) -> FeedbackControl:
  match control:
    case FeedbackControl{action, pending, progress, own_progress}:
      match action:
        case FeedbackDone{value}:
          match pending:
            case Nil{}:
              FeedbackControl{FeedbackDone{value}, Nil{}, feedback_compose_progress(Consumed{}, progress), feedback_compose_progress(fresh, own_progress)}
            case frame <> tail:
              FeedbackControl{FeedbackDone{value}, feedback_save_progress(Consumed{}, frame <> tail), progress, feedback_compose_progress(fresh, own_progress)}
        case FeedbackCall{request}:
          FeedbackControl{FeedbackCall{request}, feedback_save_progress(Consumed{}, pending), progress, feedback_compose_progress(fresh, own_progress)}
        case FeedbackInvariant{}:
          FeedbackControl{FeedbackInvariant{}, pending, feedback_compose_progress(Consumed{}, progress), feedback_compose_progress(fresh, own_progress)}

def feedback_prefix_inherited(before: Progress, control: FeedbackControl) -> FeedbackControl:
  match before:
    case NoProgress{}: control
    case Consumed{}: feedback_prefix_consumed(NoProgress{}, control)

def feedback_pack_resume(+segment_progress: Progress, +control: FeedbackControl) -> FeedbackResume:
  match control:
    case FeedbackControl{_, _, _, own_progress}:
      FeedbackResume{feedback_prefix_inherited(segment_progress, control), segment_progress, own_progress}

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

def feedback_resume_Kont_130823(capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: Nat, capture_5: List<&2, PatternFrame>, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: PatternScanGoal, result: ((Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool))) -> FeedbackControl:
  step_pattern_nat_tail_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8)

def literal_pattern_fields_cons(result: Maybe<&2, List<&2, Ast.SyntaxPattern>>, head: Ast.SyntaxPattern) -> Maybe<&2, List<&2, Ast.SyntaxPattern>>:
  match result:
    case Some{tail}:
      Some{head <> tail}
    case None{}:
      None{}

def feedback_resume_Kont_136112(capture_1: Ast.SyntaxPattern, result: Maybe<&2, List<&2, Ast.SyntaxPattern>>) -> FeedbackControl:
  feedback_pack_14(literal_pattern_fields_cons(result, capture_1))

def feedback_make_Kont_136112(capture_1: Ast.SyntaxPattern) -> FeedbackFrame:
  Kont_136112{capture_1}

def step_literal_pattern_field(result: Maybe<&2, Ast.SyntaxPattern>, rest: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match result:
    case Some{head}:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_literal_pattern_fields(rest)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_136112(head))
    case None{}:
      feedback_pack_14(None{})

def feedback_resume_Kont_136348(capture_1: List<&2, Ast.SyntaxTerm>, result: Maybe<&2, Ast.SyntaxPattern>) -> FeedbackControl:
  step_literal_pattern_field(result, capture_1)

def literal_pattern_constructor(result: Maybe<&2, List<&2, Ast.SyntaxPattern>>, key: String, position: Ast.SourceSpan) -> Maybe<&2, Ast.SyntaxPattern>:
  match result:
    case Some{fields}:
      Some{Ast.PatternCtr{key, fields, position}}
    case None{}:
      None{}

def feedback_resume_Kont_136857(capture_1: String, capture_2: Ast.SourceSpan, result: Maybe<&2, List<&2, Ast.SyntaxPattern>>) -> FeedbackControl:
  feedback_pack_13(literal_pattern_constructor(result, capture_1, capture_2))

def step_pattern_literal_finish(result: Maybe<&2, Ast.SyntaxPattern>, +after: List<&2, Lexer.Token>, +file: String, beg: Nat, end: Nat, frames: List<&2, PatternFrame>, +scope: List<&2, Scope>, +depth: Nat, +goal: PatternScanGoal) -> FeedbackControl:
  match result:
    case Some{pattern}:
      FeedbackControl{FeedbackCall{feedback_make_pattern_scan(after, file, PatternCompleted{pattern}, frames, scope, depth, goal)}, Nil{}, NoProgress{}, NoProgress{}}
    case None{}:
      step_pattern_finish(goal, Ast.PatternVar{"", depth, Ast.QOne{}, span(file, beg, end)}, after, scope, depth, False{})

def feedback_resume_Kont_138004(capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: Nat, capture_4: Nat, capture_5: List<&2, PatternFrame>, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: PatternScanGoal, result: Maybe<&2, Ast.SyntaxPattern>) -> FeedbackControl:
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

def feedback_resume_Kont_139735(capture_1: String, capture_2: Nat, capture_3: Ast.SyntaxPattern, result: ((Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool))) -> FeedbackControl:
  feedback_pack_4(pattern_tuple_tail_result(result, capture_1, capture_2, capture_3))

def feedback_make_Kont_139735(capture_1: String, capture_2: Nat, capture_3: Ast.SyntaxPattern) -> FeedbackFrame:
  Kont_139735{capture_1, capture_2, capture_3}

def step_pattern_tuple_delimiter(+tokens: List<&2, Lexer.Token>, +file: String, +beg: Nat, +left: Ast.SyntaxPattern, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match tokens:
    case Lexer.TokenInfo{_, ")", _, _, _, _} <> rest:
      feedback_pack_4(((left, rest), ((scope, depth), True{})))
    case Lexer.TokenInfo{_, ",", _, _, _, _} <> rest:
      feedback_attach(FeedbackControl{FeedbackCall{feedback_make_parse_pattern_tuple(file, beg, rest, scope, depth)}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_139735(file, beg, left))
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

def feedback_resume_Kont_140566(capture_1: String, capture_2: Nat, result: ((Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool))) -> FeedbackControl:
  step_pattern_tuple_head_result(result, capture_1, capture_2)

def step_pattern_group_result(result: (Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool), file: String, frames: List<&2, PatternFrame>, scope: List<&2, Scope>, depth: Nat, +goal: PatternScanGoal) -> FeedbackControl:
  match result:
    case ((pattern, after), ((next_scope, next_depth), True{})):
      FeedbackControl{FeedbackCall{feedback_make_pattern_scan(after, file, PatternCompleted{pattern}, frames, next_scope, next_depth, goal)}, Nil{}, NoProgress{}, NoProgress{}}
    case ((pattern, after), ((_, _), False{})):
      step_pattern_finish(goal, pattern, after, scope, depth, False{})

def feedback_resume_Kont_143905(capture_1: String, capture_2: List<&2, PatternFrame>, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: PatternScanGoal, result: ((Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool))) -> FeedbackControl:
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

def feedback_resume_Kont_149803(capture_1: String, capture_2: Ast.SyntaxPattern, capture_3: List<&2, PatternFrame>, capture_4: List<&2, Scope>, capture_5: Nat, capture_6: PatternScanGoal, result: ((Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool))) -> FeedbackControl:
  step_pattern_cons_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6)

def pattern_single_result(result: PatternScanOutcome, file: String, depth: Nat) -> (Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool):
  match result:
    case PatternSingleOutcome{pattern, after, scope, next_depth, ok}:
      ((pattern, after), ((scope, next_depth), ok))
    case PatternCaseOutcome{patterns, after, scope, next_depth, ok}:
      ((Ast.PatternVar{"", depth, Ast.QOne{}, span(file, 0n, 0n)}, after), ((scope, next_depth), False{}))

def feedback_resume_Kont_171361(capture_1: String, capture_2: Nat, result: PatternScanOutcome) -> FeedbackControl:
  feedback_pack_4(pattern_single_result(result, capture_1, capture_2))

def feedback_resume_Kont_180515(capture_1: String, capture_2: String, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Lexer.Token>, capture_6: List<&2, Scope>, capture_7: Nat, result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
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

def feedback_resume_Kont_182131(capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Lexer.Token>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(parse_kind_result(result, capture_1, capture_2, capture_3, capture_4))

def parse_template_term_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((+term, after), True{}):
      ((Ast.TermTemplate{term, span(file, beg, token_end_first(term))}, after), True{})
    case ((term, after), False{}):
      ((term, after), False{})

def feedback_resume_Kont_188212(capture_1: String, capture_2: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
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

def feedback_resume_Kont_188724(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Nat, capture_5: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(parse_do_return_value_result(result, capture_1, capture_2, capture_3, capture_4, capture_5))

def feedback_make_Kont_193125(lexical_capture_4: String, lexical_capture_6: String, lexical_capture_8: List<&2, Ast.SyntaxTerm>, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_13: Ast.SyntaxTerm, lexical_capture_29: Ast.SyntaxTerm, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_22: Nat) -> FeedbackFrame:
  Kont_193125{lexical_capture_4, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_13, lexical_capture_29, lexical_capture_15, lexical_capture_17, lexical_capture_22}

def step_parse_do_typed_bind_value_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, +file: String, +monad: String, +args: List<&2, Ast.SyntaxTerm>, +key: String, key_beg: Nat, ty: Ast.SyntaxTerm, +beg: Nat, +end: Nat, scope: List<&2, Scope>, +depth: Nat, col: Nat) -> FeedbackControl:
  match result:
    case ((value, after_value), True{}):
      next_scope = extend_scope(key, depth, scope)
      feedback_attach(step_parse_do_return(file, monad, args, skip_rewrite_semicolon(after_value), beg, end, next_scope, (depth + 1n : Nat), col), feedback_make_Kont_193125(file, monad, args, key, key_beg, ty, value, beg, end, depth))
    case ((value, after_value), False{}):
      feedback_pack_5(((value, after_value), False{}))

def feedback_resume_Kont_190051(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: Nat, capture_8: Nat, capture_9: List<&2, Scope>, capture_10: Nat, capture_11: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_do_typed_bind_value_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10, capture_11)

def parse_do_typed_bind_call_result(result: Ast.SyntaxTerm & Bool, after_body: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case (call, ok_call):
      ((call, after_body), ok_call)

def parse_do_typed_bind_body_result(ok_body: Bool, body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, +file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, key: String, key_beg: Nat, ty: Ast.SyntaxTerm, +value: Ast.SyntaxTerm, beg: Nat, end: Nat, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      local_span = span(file, key_beg, token_end_of(after_body, token_end_first(value)))
      parse_do_typed_bind_call_result(do_call(file, monad, "bind", args, [ty], [value, Ast.TermLam{None{}, key, depth, body, local_span}], beg, end), after_body)
    case False{}:
      ((body, after_body), False{})

def with_term_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, use: Ast.SyntaxTerm -> List<&2, Lexer.Token> -> Bool -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((term, after), ok):
      use(term, after, ok)

def feedback_resume_Kont_193125(lexical_capture_4: String, lexical_capture_6: String, lexical_capture_8: List<&2, Ast.SyntaxTerm>, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_13: Ast.SyntaxTerm, lexical_capture_29: Ast.SyntaxTerm, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_22: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, body => after_body => ok_body => parse_do_typed_bind_body_result(ok_body, body, after_body, lexical_capture_4, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_13, lexical_capture_29, lexical_capture_15, lexical_capture_17, lexical_capture_22)))

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

def feedback_make_Kont_190051(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: Nat, capture_8: Nat, capture_9: List<&2, Scope>, capture_10: Nat, capture_11: Nat) -> FeedbackFrame:
  Kont_190051{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10, capture_11}

def step_do_token_branch_0(after_bind: List<&2, Lexer.Token>, ty: Ast.SyntaxTerm, +file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, key: String, key_beg: Nat, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat, col: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, after_bind, scope, depth, 0n), feedback_make_Kont_190051(file, monad, args, key, key_beg, ty, beg, end, scope, depth, col))

def feedback_make_Kont_195719(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: Nat, capture_8: Nat, capture_9: List<&2, Scope>, capture_10: Nat, capture_11: Nat) -> FeedbackFrame:
  Kont_195719{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10, capture_11}

def step_parse_do_assignment(+file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, key: String, key_beg: Nat, ty: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat, col: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_195719(file, monad, args, key, key_beg, ty, beg, end, scope, depth, col))

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

def feedback_resume_Kont_194056(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Nat, capture_7: Nat, capture_8: List<&2, Scope>, capture_9: Nat, capture_10: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_do_typed_bind_type_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10)

def make_do_assignment_result(term: Ast.SyntaxTerm, after_body: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  ((term, after_body), True{})

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

def feedback_resume_Kont_195068(lexical_capture_4: String, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_22: Nat, lexical_capture_13: Ast.SyntaxTerm, lexical_capture_29: Ast.SyntaxTerm, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, body => after_body => ok_body => parse_do_assignment_body_result(ok_body, body, after_body, lexical_capture_4, lexical_capture_10, lexical_capture_12, lexical_capture_22, lexical_capture_13, lexical_capture_29)))

def feedback_make_Kont_195068(lexical_capture_4: String, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_22: Nat, lexical_capture_13: Ast.SyntaxTerm, lexical_capture_29: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_195068{lexical_capture_4, lexical_capture_10, lexical_capture_12, lexical_capture_22, lexical_capture_13, lexical_capture_29}

def step_parse_do_assignment_value_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, +file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, +key: String, key_beg: Nat, ty: Ast.SyntaxTerm, beg: Nat, end: Nat, scope: List<&2, Scope>, +depth: Nat, col: Nat) -> FeedbackControl:
  match result:
    case ((value, after_value), True{}):
      next_scope = extend_scope(key, depth, scope)
      feedback_attach(step_parse_do_return(file, monad, args, skip_rewrite_semicolon(after_value), beg, end, next_scope, (depth + 1n : Nat), col), feedback_make_Kont_195068(file, key, key_beg, depth, ty, value))
    case ((value, after_value), False{}):
      feedback_pack_5(((value, after_value), False{}))

def feedback_resume_Kont_195719(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: Nat, capture_8: Nat, capture_9: List<&2, Scope>, capture_10: Nat, capture_11: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_do_assignment_value_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10, capture_11)

def feedback_make_Kont_199714(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: List<&2, Ast.SyntaxTerm>, lexical_capture_6: Ast.SyntaxTerm, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_18: Nat) -> FeedbackFrame:
  Kont_199714{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_6, lexical_capture_7, lexical_capture_11, lexical_capture_13, lexical_capture_18}

def step_parse_do_bind(+file: String, +monad: String, +args: List<&2, Ast.SyntaxTerm>, ty: Ast.SyntaxTerm, value: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, +beg: Nat, +end: Nat, scope: List<&2, Scope>, +depth: Nat, col: Nat) -> FeedbackControl:
  next_scope = extend_scope("_", depth, scope)
  feedback_attach(step_parse_do_return(file, monad, args, skip_rewrite_semicolon(tokens), beg, end, next_scope, (depth + 1n : Nat), col), feedback_make_Kont_199714(file, monad, args, ty, value, beg, end, depth))

def step_parse_do_untyped_value_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, action: Ast.SyntaxTerm, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> FeedbackControl:
  match result:
    case ((value, after_value), True{}):
      step_parse_do_bind(file, monad, args, action, value, after_value, beg, end, scope, depth, col)
    case ((value, after_value), False{}):
      feedback_pack_5(((value, after_value), False{}))

def feedback_resume_Kont_197784(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Ast.SyntaxTerm, capture_5: Nat, capture_6: Nat, capture_7: List<&2, Scope>, capture_8: Nat, capture_9: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_do_untyped_value_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9)

def feedback_make_Kont_197784(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Ast.SyntaxTerm, capture_5: Nat, capture_6: Nat, capture_7: List<&2, Scope>, capture_8: Nat, capture_9: Nat) -> FeedbackFrame:
  Kont_197784{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9}

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
          feedback_attach(step_parse_term(file, after_bind, scope, depth, 0n), feedback_make_Kont_197784(file, monad, args, action, beg, end, scope, depth, col))
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

def feedback_consumer_196096(v_280: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_4: String, v_6: String, v_8: List<&2, Ast.SyntaxTerm>, v_10: Nat, v_12: Nat, v_15: List<&2, Scope>, v_17: Nat, v_19: Nat) -> FeedbackControl:
  match v_280:
    case ((v_281, v_282), v_283):
      step_parse_do_untyped_action_result(v_283, v_281, v_282, v_4, v_6, v_8, v_10, v_12, v_15, v_17, v_19)

def step_parse_do_untyped_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> FeedbackControl:
  feedback_consumer_196096(result, file, monad, args, beg, end, scope, depth, col)

def feedback_resume_Kont_198352(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Nat, capture_5: Nat, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
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

def feedback_resume_Kont_199714(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: List<&2, Ast.SyntaxTerm>, lexical_capture_6: Ast.SyntaxTerm, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_18: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
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

def feedback_resume_Kont_202679(capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Lexer.Token>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_nat_literal_tail(result, capture_1, capture_2, capture_3, capture_4, capture_5)

def expr_finish_list(result: Ast.SyntaxTerm & Bool, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match result:
    case (list, good):
      ((list, rest), good)

def feedback_make_Kont_205019(lexical_capture_4: String, lexical_capture_5: Ast.SyntaxTerm, lexical_capture_7: Nat) -> FeedbackFrame:
  Kont_205019{lexical_capture_4, lexical_capture_5, lexical_capture_7}

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

def feedback_make_Kont_205711(capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Scope>, capture_6: Nat) -> FeedbackFrame:
  Kont_205711{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6}

def step_parse_array_literal(+file: String, value: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, tokens, scope, depth, 12n), feedback_make_Kont_205711(file, value, beg, end, scope, depth))

def step_expr_match_list_separator(+separator: Lexer.Token, +after_separator: List<&2, Lexer.Token>, +file: String, +first: Ast.SyntaxTerm, +beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match separator:
    case Lexer.TokenInfo{_, ":", +_, +_, +_, +_}:
      step_parse_array_literal(file, first, after_separator, beg, end, scope, depth)
    case Lexer.TokenInfo{_, ",", _, _, _, _}:
      feedback_attach(step_parse_term_args(file, after_separator, "]", scope, depth, Nil{}), feedback_make_Kont_205019(file, first, beg))
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

def feedback_resume_Kont_203834(capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Scope>, capture_5: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
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

def feedback_resume_Kont_205019(lexical_capture_4: String, lexical_capture_5: Ast.SyntaxTerm, lexical_capture_7: Nat, result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
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

def feedback_make_Kont_206436(capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Ast.SyntaxTerm, capture_4: Nat, capture_5: Nat) -> FeedbackFrame:
  Kont_206436{capture_1, capture_2, capture_3, capture_4, capture_5}

def step_array_shape_branch_0(after_shape: List<&2, Lexer.Token>, +file: String, value: Ast.SyntaxTerm, ty: Ast.SyntaxTerm, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, after_shape, scope, depth, 0n), feedback_make_Kont_206436(file, value, ty, beg, end))

def feedback_make_Kont_206773(capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Ast.SyntaxTerm, capture_4: Nat, capture_5: Nat) -> FeedbackFrame:
  Kont_206773{capture_1, capture_2, capture_3, capture_4, capture_5}

def step_array_shape_branch_1(after_shape: List<&2, Lexer.Token>, +file: String, value: Ast.SyntaxTerm, ty: Ast.SyntaxTerm, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, after_shape, scope, depth, 0n), feedback_make_Kont_206773(file, value, ty, beg, end))

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

def feedback_resume_Kont_205711(capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Scope>, capture_6: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
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

def feedback_resume_Kont_206436(capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Ast.SyntaxTerm, capture_4: Nat, capture_5: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
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

def feedback_resume_Kont_206773(capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Ast.SyntaxTerm, capture_4: Nat, capture_5: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
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

def feedback_make_Kont_210566(capture_1: String, capture_2: List<&2, Lexer.Token>, capture_3: Nat, capture_4: List<&2, Scope>, capture_5: Nat) -> FeedbackFrame:
  Kont_210566{capture_1, capture_2, capture_3, capture_4, capture_5}

def step_parse_parenthesized_body(+file: String, +tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_body(file, tokens, scope, depth, col), feedback_make_Kont_210566(file, tokens, beg, scope, depth))

def step_parse_parenthesized_result(result: (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool, +file: String, +beg: Nat, +end: Nat, tokens: List<&2, Lexer.Token>, col: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match result:
    case ((terms, after), True{}):
      feedback_pack_5(parse_parenthesized_terms(terms, after, file, beg, end))
    case (_, False{}):
      step_parse_parenthesized_body(file, tokens, beg, end, col, scope, depth)

def feedback_resume_Kont_209330(capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Lexer.Token>, capture_5: Nat, capture_6: List<&2, Scope>, capture_7: Nat, result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_parenthesized_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7)

def parse_parenthesized_body_result(body: Ast.SyntaxTerm, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match body:
    case Ast.BodyReply{term,  _}:
      ((term, rest), True{})
    case _:
      ((body, rest), True{})

def feedback_make_Kont_211890(capture_1: String, capture_2: List<&2, Scope>, capture_3: Nat) -> FeedbackFrame:
  Kont_211890{capture_1, capture_2, capture_3}

def step_parse_typed_operator(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_211890(file, scope, depth))

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

def feedback_resume_Kont_210566(capture_1: String, capture_2: List<&2, Lexer.Token>, capture_3: Nat, capture_4: List<&2, Scope>, capture_5: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
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

def feedback_resume_Kont_210989(capture_1: String, capture_2: Ast.SyntaxTerm, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_typed_operator_type(result, capture_1, capture_2)

def feedback_make_Kont_210989(capture_1: String, capture_2: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_210989{capture_1, capture_2}

def step_parse_typed_operator_colon(+colon: Lexer.Token, after_colon: List<&2, Lexer.Token>, after_term: List<&2, Lexer.Token>, term: Ast.SyntaxTerm, +file: String, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match colon:
    case Lexer.TokenInfo{_, ":", +_, +_, +_, +_}:
      feedback_attach(step_parse_term(file, after_colon, scope, depth, 0n), feedback_make_Kont_210989(file, term))
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

def feedback_resume_Kont_211890(capture_1: String, capture_2: List<&2, Scope>, capture_3: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
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

def feedback_consumer_213821(v_281: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_4: String, v_6: String, v_8: Nat, v_11: List<&2, Scope>, v_13: Nat) -> FeedbackControl:
  match v_281:
    case ((v_282, v_283), v_284):
      step_parse_match_expr_parsed_head(v_284, v_282, v_283, v_4, v_6, v_8, v_11, v_13)

def step_parse_match_expr_head_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, file: String, key: String, beg: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  feedback_consumer_213821(result, file, key, beg, scope, depth)

def feedback_resume_Kont_214756(capture_1: String, capture_2: String, capture_3: Nat, capture_4: List<&2, Scope>, capture_5: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_match_expr_head_result(result, capture_1, capture_2, capture_3, capture_4, capture_5)

def feedback_consumer_216869_quantity_0(v_6: String, v_8: String, v_9: Ast.SyntaxTerm, v_11: List<&2, Lexer.Token>, v_13: String, v_25: Ast.SyntaxTerm, +v_26: List<&2, Lexer.Token>, v_27: Bool, v_15: Nat, v_18: List<&2, Scope>, v_20: Nat) -> FeedbackControl:
  FeedbackControl{FeedbackCall{feedback_make_parse_match_chain_state(MatchChainAfterHead{v_6, v_8, v_9, v_11, v_13, v_25, v_26, v_27, skip_lines(v_26), v_15, v_18, v_20})}, [], NoProgress{}, NoProgress{}}

def feedback_consumer_216869(v_4: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_6: String, v_8: String, v_9: Ast.SyntaxTerm, v_11: List<&2, Lexer.Token>, v_13: String, v_15: Nat, v_18: List<&2, Scope>, v_20: Nat) -> FeedbackControl:
  match v_4:
    case ((v_25, v_26), v_27):
      feedback_consumer_216869_quantity_0(v_6, v_8, v_9, v_11, v_13, v_25, v_26, v_27, v_15, v_18, v_20)

def feedback_resume_Kont_216886(lexical_capture_49: String, lexical_capture_50: String, lexical_capture_51: Ast.SyntaxTerm, lexical_capture_52: List<&2, Lexer.Token>, lexical_capture_53: String, lexical_capture_55: Nat, lexical_capture_56: List<&2, Scope>, lexical_capture_57: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_216869(result, lexical_capture_49, lexical_capture_50, lexical_capture_51, lexical_capture_52, lexical_capture_53, lexical_capture_55, lexical_capture_56, lexical_capture_57)

def feedback_consumer_217700(v_284: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_98: String, v_99: String, v_100: Ast.SyntaxTerm, v_107: Nat) -> FeedbackControl:
  match v_284:
    case ((v_285, v_286), v_287):
      FeedbackControl{FeedbackCall{feedback_make_parse_match_chain_state(MatchChainAfterMatch{v_98, v_99, v_100, v_285, v_286, v_287, v_107})}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_resume_Kont_217717(lexical_capture_98: String, lexical_capture_99: String, lexical_capture_100: Ast.SyntaxTerm, lexical_capture_107: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_217700(result, lexical_capture_98, lexical_capture_99, lexical_capture_100, lexical_capture_107)

def feedback_consumer_218040(v_283: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_98: String, v_99: String, v_100: Ast.SyntaxTerm, v_107: Nat) -> FeedbackControl:
  match v_283:
    case ((v_284, v_285), v_286):
      FeedbackControl{FeedbackCall{feedback_make_parse_match_chain_state(MatchChainAfterMatch{v_98, v_99, v_100, v_284, v_285, v_286, v_107})}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_resume_Kont_218057(lexical_capture_98: String, lexical_capture_99: String, lexical_capture_100: Ast.SyntaxTerm, lexical_capture_107: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_218040(result, lexical_capture_98, lexical_capture_99, lexical_capture_100, lexical_capture_107)

def feedback_consumer_218366(v_282: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_98: String, v_99: String, v_100: Ast.SyntaxTerm, v_107: Nat) -> FeedbackControl:
  match v_282:
    case ((v_283, v_284), v_285):
      FeedbackControl{FeedbackCall{feedback_make_parse_match_chain_state(MatchChainAfterMatch{v_98, v_99, v_100, v_283, v_284, v_285, v_107})}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_resume_Kont_218383(lexical_capture_98: String, lexical_capture_99: String, lexical_capture_100: Ast.SyntaxTerm, lexical_capture_107: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_218366(result, lexical_capture_98, lexical_capture_99, lexical_capture_100, lexical_capture_107)

def parse_match_tail_with_head_result(ok_tail: Bool, +tail: Ast.SyntaxTerm, +after_tail: List<&2, Lexer.Token>, file: String, key: String, head: Ast.SyntaxTerm, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_tail:
    case True{}:
      ((Ast.TermMat{key, head, tail, span(file, beg, token_end_of(after_tail, token_end_first(tail)))}, after_tail), True{})
    case False{}:
      ((tail, after_tail), False{})

def feedback_resume_Kont_219577(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_8: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
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

def feedback_resume_Kont_219930(lexical_capture_1: String, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
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

def feedback_resume_Kont_220317(lexical_capture_2: String, lexical_capture_3: Ast.SyntaxTerm, lexical_capture_0: Ast.SyntaxTerm, lexical_capture_5: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, ty => after_ty => ok_ty => parse_brace_equal_type_result(ok_ty, after_ty, ty, lexical_capture_2, lexical_capture_3, lexical_capture_0, lexical_capture_5)))

def brace_equal_right_is_colon(colon: Lexer.Token) -> Bool:
  match colon:
    case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
      True{}
    case _:
      False{}

def brace_equal_right_branch_1(after_right: List<&2, Lexer.Token>, +file: String, +colon: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected :",  span(file, token_beg(colon), token_end(colon))}, after_right), False{})

def feedback_make_Kont_220317(lexical_capture_2: String, lexical_capture_3: Ast.SyntaxTerm, lexical_capture_0: Ast.SyntaxTerm, lexical_capture_5: Nat) -> FeedbackFrame:
  Kont_220317{lexical_capture_2, lexical_capture_3, lexical_capture_0, lexical_capture_5}

def step_brace_equal_right_branch_0(right: Ast.SyntaxTerm, +file: String, left: Ast.SyntaxTerm, beg: Nat, scope: List<&2, Scope>, depth: Nat, after_colon: List<&2, Lexer.Token>) -> FeedbackControl:
  feedback_attach(step_parse_term(file, after_colon, scope, depth, 0n), feedback_make_Kont_220317(file, left, right, beg))

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

def feedback_consumer_222902(v_286: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_4: String, v_2: Ast.SyntaxTerm, v_6: Nat, v_9: List<&2, Scope>, v_11: Nat) -> FeedbackControl:
  match v_286:
    case ((v_287, v_288), v_289):
      step_parse_brace_equal_right_result(v_289, v_288, v_287, v_4, v_2, v_6, v_9, v_11)

def feedback_resume_Kont_222919(lexical_capture_4: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: Nat, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_222902(result, lexical_capture_4, lexical_capture_2, lexical_capture_6, lexical_capture_9, lexical_capture_11)

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

def feedback_resume_Kont_223326(lexical_capture_4: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
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

def feedback_make_Kont_228444(lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: Nat, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat) -> FeedbackFrame:
  Kont_228444{lexical_capture_1, lexical_capture_2, lexical_capture_6, lexical_capture_9, lexical_capture_11}

def step_parse_inequality(+file: String, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_228444(file, left, beg, scope, depth))

def step_brace_equals_branch_0(after_equals: List<&2, Lexer.Token>, left: Ast.SyntaxTerm, +file: String, beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  step_parse_inequality(file, left, after_equals, beg, scope, depth)

def feedback_make_Kont_222919(lexical_capture_4: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: Nat, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat) -> FeedbackFrame:
  Kont_222919{lexical_capture_4, lexical_capture_2, lexical_capture_6, lexical_capture_9, lexical_capture_11}

def step_brace_equals_branch_1(after_equals: List<&2, Lexer.Token>, left: Ast.SyntaxTerm, +file: String, beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, after_equals, scope, depth, 0n), feedback_make_Kont_222919(file, left, beg, scope, depth))

def feedback_make_Kont_223326(lexical_capture_4: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: Nat) -> FeedbackFrame:
  Kont_223326{lexical_capture_4, lexical_capture_2, lexical_capture_6}

def step_brace_equals_branch_2(after_equals: List<&2, Lexer.Token>, left: Ast.SyntaxTerm, +file: String, beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, after_equals, scope, depth, 0n), feedback_make_Kont_223326(file, left, beg))

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

def feedback_consumer_226101(v_287: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_5: Nat, v_10: List<&2, Scope>, v_12: Nat) -> FeedbackControl:
  match v_287:
    case ((v_288, v_289), v_290):
      step_parse_brace_left_result(v_290, v_289, v_288, v_1, v_5, v_10, v_12)

def feedback_resume_Kont_226118(lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_10: List<&2, Scope>, lexical_capture_12: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_226101(result, lexical_capture_1, lexical_capture_5, lexical_capture_10, lexical_capture_12)

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

def feedback_resume_Kont_226642(lexical_capture_2: String, lexical_capture_3: Ast.SyntaxTerm, lexical_capture_0: Ast.SyntaxTerm, lexical_capture_5: Nat, lexical_capture_10: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, ty => after_ty => ok_ty => parse_inequality_type_result(ok_ty, ty, after_ty, lexical_capture_2, lexical_capture_3, lexical_capture_0, lexical_capture_5, lexical_capture_10)))

def inequality_right_is_colon(colon: Lexer.Token) -> Bool:
  match colon:
    case Lexer.TokenInfo{ _, ":", _, _, _, _}:
      True{}
    case _:
      False{}

def inequality_right_branch_1(after_right: List<&2, Lexer.Token>, +file: String, +colon: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{"parse-error: expected :", span(file, token_beg(colon), token_end(colon))}, after_right), False{})

def feedback_make_Kont_226642(lexical_capture_2: String, lexical_capture_3: Ast.SyntaxTerm, lexical_capture_0: Ast.SyntaxTerm, lexical_capture_5: Nat, lexical_capture_10: Nat) -> FeedbackFrame:
  Kont_226642{lexical_capture_2, lexical_capture_3, lexical_capture_0, lexical_capture_5, lexical_capture_10}

def step_inequality_right_branch_0(right: Ast.SyntaxTerm, +file: String, left: Ast.SyntaxTerm, beg: Nat, scope: List<&2, Scope>, +depth: Nat, after_colon: List<&2, Lexer.Token>) -> FeedbackControl:
  feedback_attach(step_parse_term(file, after_colon, scope, depth, 0n), feedback_make_Kont_226642(file, left, right, beg, depth))

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

def feedback_consumer_228427(v_288: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_2: Ast.SyntaxTerm, v_6: Nat, v_9: List<&2, Scope>, v_11: Nat) -> FeedbackControl:
  match v_288:
    case ((v_289, v_290), v_291):
      step_parse_inequality_right_result(v_291, v_289, v_290, v_1, v_2, v_6, v_9, v_11)

def feedback_resume_Kont_228444(lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: Nat, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_228427(result, lexical_capture_1, lexical_capture_2, lexical_capture_6, lexical_capture_9, lexical_capture_11)

def rewrite_motive_is_colon(colon: Lexer.Token) -> Bool:
  match colon:
    case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
      True{}
    case _:
      False{}

def rewrite_motive_branch_1(+file: String, tokens: List<&2, Lexer.Token>, +colon: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected :",  span(file, token_beg(colon), token_end(colon))}, tokens), False{})

def feedback_make_Kont_232455(lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_4: String, lexical_capture_6: Nat, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat) -> FeedbackFrame:
  Kont_232455{lexical_capture_1, lexical_capture_2, lexical_capture_4, lexical_capture_6, lexical_capture_9, lexical_capture_11}

def step_rewrite_motive_branch_0(+file: String, equation: Ast.SyntaxTerm, +key: String, beg: Nat, +scope: List<&2, Scope>, +depth: Nat, after_colon: List<&2, Lexer.Token>) -> FeedbackControl:
  # Rewrite exposes its implicit value binder; ordinary "_" binders do not.
  base_scope = { Scope{"_", depth} <> scope : List<&2, Scope> }
  motive_scope = extend_scope(key, (depth + 1n : Nat), base_scope)
  feedback_attach(step_parse_term(file, after_colon, motive_scope, (depth + 2n : Nat), 0n), feedback_make_Kont_232455(file, equation, key, beg, scope, depth))

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

def feedback_consumer_229363(v_289: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_6: String, v_21: String, v_8: Nat, v_10: Nat, v_13: List<&2, Scope>, v_15: Nat) -> FeedbackControl:
  match v_289:
    case ((v_290, v_291), v_292):
      step_parse_rewrite_equation_result(v_292, v_290, v_291, v_6, v_21, v_8, v_10, v_13, v_15)

def feedback_resume_Kont_229380(lexical_capture_6: String, lexical_capture_21: String, lexical_capture_8: Nat, lexical_capture_10: Nat, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_229363(result, lexical_capture_6, lexical_capture_21, lexical_capture_8, lexical_capture_10, lexical_capture_13, lexical_capture_15)

def feedback_make_Kont_229380(lexical_capture_6: String, lexical_capture_21: String, lexical_capture_8: Nat, lexical_capture_10: Nat, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat) -> FeedbackFrame:
  Kont_229380{lexical_capture_6, lexical_capture_21, lexical_capture_8, lexical_capture_10, lexical_capture_13, lexical_capture_15}

def step_parse_rewrite_first_at_name(+first: Ast.SyntaxTerm, after_at: List<&2, Lexer.Token>, +after_first: List<&2, Lexer.Token>, +file: String, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match first:
    case Ast.TermVar{key, _, _}:
      feedback_attach(step_parse_term(file, after_at, scope, depth, 0n), feedback_make_Kont_229380(file, key, beg, end, scope, depth))
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

def feedback_consumer_230966(v_290: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_5: Nat, v_7: Nat, v_10: List<&2, Scope>, v_12: Nat) -> FeedbackControl:
  match v_290:
    case ((v_291, v_292), v_293):
      step_parse_rewrite_first_result(v_293, v_291, v_292, v_1, v_5, v_7, v_10, v_12)

def feedback_resume_Kont_230983(lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_10: List<&2, Scope>, lexical_capture_12: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_230966(result, lexical_capture_1, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_12)

def parse_rewrite_body_result(ok_body: Bool, +body: Ast.SyntaxTerm, after_body: List<&2, Lexer.Token>, equation: Ast.SyntaxTerm, proof: Ast.SyntaxTerm, file: String, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      ((Ast.TermRewrite{equation, proof, body, span(file, beg, token_end_first(body))}, after_body), True{})
    case False{}:
      ((body, after_body), False{})

def feedback_resume_Kont_231779(lexical_capture_7: Ast.SyntaxTerm, lexical_capture_28: Ast.SyntaxTerm, lexical_capture_6: String, lexical_capture_11: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, body => after_body => ok_body => parse_rewrite_body_result(ok_body, body, after_body, lexical_capture_7, lexical_capture_28, lexical_capture_6, lexical_capture_11)))

def feedback_make_Kont_231779(lexical_capture_7: Ast.SyntaxTerm, lexical_capture_28: Ast.SyntaxTerm, lexical_capture_6: String, lexical_capture_11: Nat) -> FeedbackFrame:
  Kont_231779{lexical_capture_7, lexical_capture_28, lexical_capture_6, lexical_capture_11}

def step_parse_rewrite_motive_result(ok_motive: Bool, +motive: Ast.SyntaxTerm, +after_motive: List<&2, Lexer.Token>, +file: String, equation: Ast.SyntaxTerm, key: String, +beg: Nat, scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match ok_motive:
    case True{}:
      inner = { Ast.TermLam{None{}, key, (depth + 1n : Nat), motive, span(file, beg, token_end_first(motive))} : Ast.SyntaxTerm }
      proof = { Ast.TermLam{None{}, "_", depth, inner, span(file, beg, token_end_first(motive))} : Ast.SyntaxTerm }
      body_tokens = skip_rewrite_semicolon(after_motive)
      feedback_attach(step_parse_term(file, body_tokens, scope, depth, 0n), feedback_make_Kont_231779(equation, proof, file, beg))
    case False{}:
      feedback_pack_5(((motive, after_motive), False{}))

def feedback_consumer_232438(v_291: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_2: Ast.SyntaxTerm, v_4: String, v_6: Nat, v_9: List<&2, Scope>, v_11: Nat) -> FeedbackControl:
  match v_291:
    case ((v_292, v_293), v_294):
      step_parse_rewrite_motive_result(v_294, v_292, v_293, v_1, v_2, v_4, v_6, v_9, v_11)

def feedback_resume_Kont_232455(lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_4: String, lexical_capture_6: Nat, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_232438(result, lexical_capture_1, lexical_capture_2, lexical_capture_4, lexical_capture_6, lexical_capture_9, lexical_capture_11)

def parse_name_lambda_result(ok: Bool, body: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, file: String, key: String, beg: Nat, end: Nat, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok:
    case True{}:
      ((Ast.TermLam{None{}, key, depth, body, span(file, beg, token_end_of(after, end))}, after), True{})
    case False{}:
      ((body, after), False{})

def feedback_resume_Kont_235238(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_14: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
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

def feedback_consumer_235461(v_292: Pair(Pair(List<&2, Ast.SyntaxTerm>, List<&2, Lexer.Token>), Bool), v_1: String, v_3: String, v_5: Nat, v_7: Nat, v_20: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_292:
    case ((v_293, v_294), v_295):
      step_parse_name_constructor_result(v_295, v_293, v_294, v_1, v_3, v_5, v_7, v_20)

def feedback_resume_Kont_235478(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_20: List<&2, Lexer.Token>, result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_235461(result, lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_20)

def feedback_make_parse_term_args_first_result(ok: Bool, term: Ast.SyntaxTerm, after: List<&2, Lexer.Token>, file: String, tokens: List<&2, Lexer.Token>, close: String, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.SyntaxTerm>) -> FeedbackRequest:
  Request_parse_term_args_first_result{ok, term, after, file, tokens, close, scope, depth, acc}

def feedback_consumer_238855(v_293: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_3: String, v_8: List<&2, Lexer.Token>, v_10: String, v_13: List<&2, Scope>, v_15: Nat, v_17: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match v_293:
    case ((v_294, v_295), v_296):
      FeedbackControl{FeedbackCall{feedback_make_parse_term_args_first_result(v_296, v_294, v_295, v_3, v_8, v_10, v_13, v_15, v_17)}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_resume_Kont_238873(lexical_capture_3: String, lexical_capture_8: List<&2, Lexer.Token>, lexical_capture_10: String, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: List<&2, Ast.SyntaxTerm>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_238855(result, lexical_capture_3, lexical_capture_8, lexical_capture_10, lexical_capture_13, lexical_capture_15, lexical_capture_17)

def parse_all_named_body_result(ok_body: Bool, body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, file: String, key: String, key_end: Nat, beg: Nat, quantity: Ast.Quantity, ty: Ast.SyntaxTerm, idx: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      ((Ast.TermAll{quantity, key, idx, ty, body, span(file, beg, token_end_of(after_body, key_end))}, after_body), True{})
    case False{}:
      ((body, after_body), False{})

def feedback_resume_Kont_240566(lexical_capture_2: String, lexical_capture_4: String, lexical_capture_6: Nat, lexical_capture_8: Nat, lexical_capture_9: Ast.Quantity, lexical_capture_0: Ast.SyntaxTerm, lexical_capture_22: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, body => after_body => ok_body => parse_all_named_body_result(ok_body, body, after_body, lexical_capture_2, lexical_capture_4, lexical_capture_6, lexical_capture_8, lexical_capture_9, lexical_capture_0, lexical_capture_22)))

def all_named_type_is_colon(arrow: Lexer.Token) -> Bool:
  match arrow:
    case Lexer.TokenInfo{ _, "->", _, _, _, _}:
      True{}
    case _:
      False{}

def all_named_type_branch_1(after_ty: List<&2, Lexer.Token>, +file: String, +arrow: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected ->", span(file, token_beg(arrow), token_end(arrow))}, after_ty), False{})

def feedback_make_Kont_240566(lexical_capture_2: String, lexical_capture_4: String, lexical_capture_6: Nat, lexical_capture_8: Nat, lexical_capture_9: Ast.Quantity, lexical_capture_0: Ast.SyntaxTerm, lexical_capture_22: Nat) -> FeedbackFrame:
  Kont_240566{lexical_capture_2, lexical_capture_4, lexical_capture_6, lexical_capture_8, lexical_capture_9, lexical_capture_0, lexical_capture_22}

def step_all_named_type_branch_0(ty: Ast.SyntaxTerm, +file: String, +key: String, key_end: Nat, beg: Nat, quantity: Ast.Quantity, scope: List<&2, Scope>, +depth: Nat, after_arrow: List<&2, Lexer.Token>) -> FeedbackControl:
  idx = depth
  next_scope = extend_scope(key, depth, scope)
  feedback_attach(step_parse_term(file, after_arrow, next_scope, (depth + 1n : Nat), 0n), feedback_make_Kont_240566(file, key, key_end, beg, quantity, ty, idx))

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

def feedback_consumer_242737(v_294: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_23: String, v_25: Nat, v_10: Nat, v_11: Ast.Quantity, v_6: List<&2, Scope>, v_8: Nat) -> FeedbackControl:
  match v_294:
    case ((v_295, v_296), v_297):
      step_parse_all_named_type_result(v_297, v_295, v_296, v_1, v_23, v_25, v_10, v_11, v_6, v_8)

def feedback_resume_Kont_242754(lexical_capture_1: String, lexical_capture_23: String, lexical_capture_25: Nat, lexical_capture_10: Nat, lexical_capture_11: Ast.Quantity, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_242737(result, lexical_capture_1, lexical_capture_23, lexical_capture_25, lexical_capture_10, lexical_capture_11, lexical_capture_6, lexical_capture_8)

def parse_many_lambda_body_result(ok_body: Bool, body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, file: String, key: String, beg: Nat, end: Nat, depth: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      ((Ast.TermLam{Some{Ast.QMany{}}, key, depth, body, span(file, beg, token_end_of(after_body, end))}, after_body), True{})
    case False{}:
      ((body, after_body), False{})

def feedback_resume_Kont_244006(lexical_capture_1: String, lexical_capture_22: String, lexical_capture_5: Nat, lexical_capture_24: Nat, lexical_capture_10: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, body => after_body => ok_body => parse_many_lambda_body_result(ok_body, body, after_body, lexical_capture_1, lexical_capture_22, lexical_capture_5, lexical_capture_24, lexical_capture_10)))

def feedback_make_Kont_247124(lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_6: Nat, lexical_capture_7: Lexer.Token) -> FeedbackFrame:
  Kont_247124{lexical_capture_3, lexical_capture_4, lexical_capture_6, lexical_capture_7}

def step_parse_plus_args_spaced(is_spaced: Bool, +file: String, +head: Ast.SyntaxTerm, +beg: Nat, open: Lexer.Token, rest: List<&2, Lexer.Token>, after_head: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match is_spaced:
    case True{}:
      feedback_pack_5(((Ast.TermPlus{head,  Nil{},  span(file, beg, token_end_first(head))}, after_head), True{}))
    case False{}:
      feedback_attach(step_parse_term_args(file, rest, ">", scope, depth, Nil{}), feedback_make_Kont_247124(file, head, beg, open))

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

def feedback_consumer_245797(v_295: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_5: Nat, v_14: List<&2, Scope>, v_16: Nat) -> FeedbackControl:
  match v_295:
    case ((v_296, v_297), v_298):
      step_parse_plus_sugar_head_result(v_298, v_296, v_297, v_1, v_5, v_14, v_16)

def feedback_resume_Kont_245814(lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_245797(result, lexical_capture_1, lexical_capture_5, lexical_capture_14, lexical_capture_16)

def parse_plus_args_result(ok_args: Bool, args: List<&2, Ast.SyntaxTerm>, +after_args: List<&2, Lexer.Token>, file: String, +head: Ast.SyntaxTerm, beg: Nat, +open: Lexer.Token) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_args:
    case True{}:
      ((Ast.TermPlus{head, args, span(file, beg, token_end_of(after_args, token_end_first(head)))}, after_args), True{})
    case False{}:
      ((Ast.TermHole{"parse-error: expected plus datatype arguments", span(file, token_beg(open), token_end(open))}, after_args), False{})

def feedback_resume_Kont_247124(lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_6: Nat, lexical_capture_7: Lexer.Token, result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_args_result(result, args => after_args => ok_args => parse_plus_args_result(ok_args, args, after_args, lexical_capture_3, lexical_capture_4, lexical_capture_6, lexical_capture_7)))

def feedback_resume_Kont_247617(capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: List<&2, Lexer.Token>, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: Nat, result: Nat) -> FeedbackControl:
  FeedbackControl{FeedbackCall{feedback_make_parse_term_tail_at(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, result)}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_make_Kont_247617(capture_0: String, capture_1: Ast.SyntaxTerm, capture_2: List<&2, Lexer.Token>, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: Nat) -> FeedbackFrame:
  Kont_247617{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5}

def step_parse_term_atom_result(ok: Bool, +left: Ast.SyntaxTerm, +rest: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, level: Nat, original: List<&2, Lexer.Token>) -> FeedbackControl:
  match ok:
    case True{}:
      feedback_attach(step_consumed_token_end(original, rest, token_end_first(left)), feedback_make_Kont_247617(file, left, rest, scope, depth, level))
    case False{}:
      feedback_pack_5(((left, rest), False{}))

def feedback_consumer_247891(v_296: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_6: List<&2, Scope>, v_8: Nat, v_10: Nat, v_3: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_296:
    case ((v_297, v_298), v_299):
      step_parse_term_atom_result(v_299, v_297, v_298, v_1, v_6, v_8, v_10, v_3)

def feedback_resume_Kont_247908(lexical_capture_1: String, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat, lexical_capture_10: Nat, lexical_capture_3: List<&2, Lexer.Token>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_247891(result, lexical_capture_1, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_3)

def step_parse_application_applied_result(ok_apply: Bool, +applied: Ast.SyntaxTerm, +after_args: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, level: Nat, consumed_end: Nat) -> FeedbackControl:
  match ok_apply:
    case True{}:
      FeedbackControl{FeedbackCall{feedback_make_parse_term_tail_at(file, applied, after_args, scope, depth, level, consumed_end)}, Nil{}, NoProgress{}, NoProgress{}}
    case False{}:
      feedback_pack_5(((applied, after_args), False{}))

def feedback_consumer_250152(v_297: Pair(Ast.SyntaxTerm, Bool), v_3: List<&2, Lexer.Token>, v_5: String, v_9: List<&2, Scope>, v_11: Nat, v_13: Nat, v_21: Nat) -> FeedbackControl:
  match v_297:
    case (v_298, v_299):
      step_parse_application_applied_result(v_299, v_298, v_3, v_5, v_9, v_11, v_13, v_21)

def step_evaluation_context_parse_application_args_result_241624(v_3: List<&2, Ast.SyntaxTerm>, +v_5: List<&2, Lexer.Token>, +v_7: String, +v_8: Ast.SyntaxTerm, v_12: List<&2, Scope>, v_14: Nat, v_16: Nat, v_304: Nat) -> FeedbackControl:
  v_24 = v_304
  feedback_consumer_250152(apply_terms(v_3, v_7, v_8, token_beg_first(v_8)), v_5, v_7, v_12, v_14, v_16, v_24)

def feedback_resume_Kont_250740(capture_0: List<&2, Ast.SyntaxTerm>, capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: Ast.SyntaxTerm, capture_4: List<&2, Scope>, capture_5: Nat, capture_6: Nat, result: Nat) -> FeedbackControl:
  step_evaluation_context_parse_application_args_result_241624(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, result)

def feedback_make_Kont_250740(capture_0: List<&2, Ast.SyntaxTerm>, capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: Ast.SyntaxTerm, capture_4: List<&2, Scope>, capture_5: Nat, capture_6: Nat) -> FeedbackFrame:
  Kont_250740{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6}

def step_parse_application_args_result(v_1: Bool, v_3: List<&2, Ast.SyntaxTerm>, +v_5: List<&2, Lexer.Token>, +v_7: String, +v_8: Ast.SyntaxTerm, v_9: Ast.SyntaxTerm, v_12: List<&2, Scope>, v_14: Nat, v_16: Nat, v_18: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_1:
    case True{}:
      feedback_attach(step_consumed_token_end(v_18, v_5, token_end_first(v_8)), feedback_make_Kont_250740(v_3, v_5, v_7, v_8, v_12, v_14, v_16))
    case False{}:
      feedback_pack_5(((v_9, v_5), False{}))

def feedback_consumer_251367(v_298: Pair(Pair(List<&2, Ast.SyntaxTerm>, List<&2, Lexer.Token>), Bool), +v_3: String, v_30: Ast.SyntaxTerm, +v_5: Lexer.Token, v_15: List<&2, Scope>, v_17: Nat, v_19: Nat, v_7: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_298:
    case ((v_299, v_300), v_301):
      step_parse_application_args_result(v_301, v_299, v_300, v_3, v_30, Ast.TermHole{"parse-error: expected bang-call arguments", span(v_3, token_beg(v_5), token_end(v_5))}, v_15, v_17, v_19, v_7)

def feedback_resume_Kont_251384(+lexical_capture_3: String, lexical_capture_30: Ast.SyntaxTerm, +lexical_capture_5: Lexer.Token, lexical_capture_15: List<&2, Scope>, lexical_capture_17: Nat, lexical_capture_19: Nat, lexical_capture_7: List<&2, Lexer.Token>, result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_251367(result, lexical_capture_3, lexical_capture_30, lexical_capture_5, lexical_capture_15, lexical_capture_17, lexical_capture_19, lexical_capture_7)

def feedback_make_parse_term_tail(file: String, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat) -> FeedbackRequest:
  Request_parse_term_tail{file, left, tokens, scope, depth, level}

def step_parse_term_arrow_result(ok: Bool, +right: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, +file: String, +left: Ast.SyntaxTerm, scope: List<&2, Scope>, +depth: Nat, level: Nat, end: Nat) -> FeedbackControl:
  match ok:
    case True{}:
      FeedbackControl{FeedbackCall{feedback_make_parse_term_tail(file, Ast.TermAll{Ast.QOne{}, "_", depth, left, right, span(file, token_beg_first(left), token_end_of(after, end))}, after, scope, (depth + 1n : Nat), level)}, Nil{}, NoProgress{}, NoProgress{}}
    case False{}:
      feedback_pack_5(((right, after), False{}))

def feedback_consumer_254099(v_300: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_2: Ast.SyntaxTerm, v_7: List<&2, Scope>, v_9: Nat, v_11: Nat, v_39: Nat) -> FeedbackControl:
  match v_300:
    case ((v_301, v_302), v_303):
      step_parse_term_arrow_result(v_303, v_301, v_302, v_1, v_2, v_7, v_9, v_11, v_39)

def feedback_resume_Kont_254116(lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: Nat, lexical_capture_39: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_254099(result, lexical_capture_1, lexical_capture_2, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_39)

def feedback_consumer_257563(v_299: Pair(Pair(List<&2, Ast.SyntaxTerm>, List<&2, Lexer.Token>), Bool), +v_1: String, v_2: Ast.SyntaxTerm, +v_18: Lexer.Token, v_7: List<&2, Scope>, v_9: Nat, v_11: Nat, v_19: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_299:
    case ((v_300, v_301), v_302):
      step_parse_application_args_result(v_302, v_300, v_301, v_1, v_2, Ast.TermHole{"parse-error: expected application arguments", span(v_1, token_end(v_18), token_end(v_18))}, v_7, v_9, v_11, v_19)

def feedback_resume_Kont_257580(+lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, +lexical_capture_18: Lexer.Token, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: Nat, lexical_capture_19: List<&2, Lexer.Token>, result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_257563(result, lexical_capture_1, lexical_capture_2, lexical_capture_18, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_19)

def feedback_make_Kont_261509(capture_0: List<&2, Ast.SyntaxTerm>, capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: Ast.SyntaxTerm, capture_4: List<&2, Scope>, capture_5: Nat, capture_6: Nat) -> FeedbackFrame:
  Kont_261509{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6}

def step_parse_less_many_result(v_1: Bool, v_3: List<&2, Ast.SyntaxTerm>, +v_5: List<&2, Lexer.Token>, +v_7: String, +v_8: Ast.SyntaxTerm, +v_9: Lexer.Token, v_11: Nat, v_14: List<&2, Scope>, v_16: Nat, v_18: Nat, v_20: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_1:
    case True{}:
      feedback_attach(step_consumed_token_end(v_20, v_5, v_11), feedback_make_Kont_261509(v_3, v_5, v_7, v_8, v_14, v_16, v_18))
    case False{}:
      feedback_pack_5(((Ast.TermHole{"parse-error: expected datatype arguments", span(v_7, token_beg(v_9), token_end(v_9))}, v_5), False{}))

def feedback_consumer_260031(v_301: Pair(Pair(List<&2, Ast.SyntaxTerm>, List<&2, Lexer.Token>), Bool), v_6: String, v_7: Ast.SyntaxTerm, v_9: Lexer.Token, v_20: Nat, v_14: List<&2, Scope>, v_16: Nat, v_18: Nat, v_11: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_301:
    case ((v_302, v_303), v_304):
      step_parse_less_many_result(v_304, v_302, v_303, v_6, v_7, v_9, v_20, v_14, v_16, v_18, v_11)

def feedback_resume_Kont_260048(lexical_capture_6: String, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_9: Lexer.Token, lexical_capture_20: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, lexical_capture_18: Nat, lexical_capture_11: List<&2, Lexer.Token>, result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_260031(result, lexical_capture_6, lexical_capture_7, lexical_capture_9, lexical_capture_20, lexical_capture_14, lexical_capture_16, lexical_capture_18, lexical_capture_11)

def step_evaluation_context_parse_less_many_result_252228(v_3: List<&2, Ast.SyntaxTerm>, +v_5: List<&2, Lexer.Token>, +v_7: String, +v_8: Ast.SyntaxTerm, v_14: List<&2, Scope>, v_16: Nat, v_18: Nat, v_305: Nat) -> FeedbackControl:
  v_27 = {Ast.TermFill{v_8, v_3, span(v_7, token_beg_first(v_8), v_305)} : Ast.SyntaxTerm}
  FeedbackControl{FeedbackCall{feedback_make_parse_term_tail(v_7, v_27, v_5, v_14, v_16, v_18)}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_resume_Kont_261509(capture_0: List<&2, Ast.SyntaxTerm>, capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: Ast.SyntaxTerm, capture_4: List<&2, Scope>, capture_5: Nat, capture_6: Nat, result: Nat) -> FeedbackControl:
  step_evaluation_context_parse_less_many_result_252228(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, result)

def feedback_make_Kont_260048(lexical_capture_6: String, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_9: Lexer.Token, lexical_capture_20: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, lexical_capture_18: Nat, lexical_capture_11: List<&2, Lexer.Token>) -> FeedbackFrame:
  Kont_260048{lexical_capture_6, lexical_capture_7, lexical_capture_9, lexical_capture_20, lexical_capture_14, lexical_capture_16, lexical_capture_18, lexical_capture_11}

def step_parse_less_named(found: Maybe<&2, String>, wants_many: Bool, +file: String, +left: Ast.SyntaxTerm, +right: Ast.SyntaxTerm, +separator: Lexer.Token, +after_separator: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +level: Nat, end: Nat) -> FeedbackControl:
  match found:
    case Some{ _}:
      match wants_many:
        case True{}:
          feedback_attach(step_parse_term_args(file, after_separator, ">", scope, depth, [right]), feedback_make_Kont_260048(file, left, separator, end, scope, depth, level, after_separator))
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

def feedback_consumer_262403(v_302: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_2: Ast.SyntaxTerm, v_4: List<&2, Lexer.Token>, v_6: List<&2, Lexer.Token>, v_9: List<&2, Scope>, v_11: Nat, v_13: Nat, v_15: Nat) -> FeedbackControl:
  match v_302:
    case ((v_303, v_304), v_305):
      step_parse_less_right(v_305, v_304, v_303, v_1, v_2, v_4, v_6, v_9, v_11, v_13, v_15)

def feedback_resume_Kont_262420(lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_4: List<&2, Lexer.Token>, lexical_capture_6: List<&2, Lexer.Token>, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_262403(result, lexical_capture_1, lexical_capture_2, lexical_capture_4, lexical_capture_6, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15)

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

def feedback_consumer_266442(v_303: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_3: String, v_5: String, v_8: Ast.SyntaxTerm, v_13: List<&2, Scope>, v_15: Nat, v_17: Nat, v_19: Nat) -> FeedbackControl:
  match v_303:
    case ((v_304, v_305), v_306):
      step_parse_operator_right_result(v_306, v_304, v_305, v_3, v_5, v_8, v_13, v_15, v_17, v_19)

def feedback_resume_Kont_266459(lexical_capture_3: String, lexical_capture_5: String, lexical_capture_8: Ast.SyntaxTerm, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_19: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_266442(result, lexical_capture_3, lexical_capture_5, lexical_capture_8, lexical_capture_13, lexical_capture_15, lexical_capture_17, lexical_capture_19)

def step_parse_min_precedence_result(ok: Bool, +right: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, +file: String, +left: Ast.SyntaxTerm, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat) -> FeedbackControl:
  match ok:
    case True{}:
      term = { Ast.TermMin{left, right, span(file, token_beg_first(left), token_end_of(after, end))} : Ast.SyntaxTerm }
      FeedbackControl{FeedbackCall{feedback_make_parse_term_tail(file, term, after, scope, depth, level)}, Nil{}, NoProgress{}, NoProgress{}}
    case False{}:
      feedback_pack_5(((right, after), False{}))

def feedback_consumer_267737(v_304: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_3: String, v_4: Ast.SyntaxTerm, v_9: List<&2, Scope>, v_11: Nat, v_13: Nat, v_15: Nat) -> FeedbackControl:
  match v_304:
    case ((v_305, v_306), v_307):
      step_parse_min_precedence_result(v_307, v_305, v_306, v_3, v_4, v_9, v_11, v_13, v_15)

def feedback_resume_Kont_267754(lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_267737(result, lexical_capture_3, lexical_capture_4, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15)

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

def feedback_consumer_271042(v_306: Pair(Ast.SyntaxTerm, Bool), v_7: List<&2, Lexer.Token>, v_1: String, v_10: List<&2, Scope>, v_12: Nat, v_14: Nat, v_16: Nat) -> FeedbackControl:
  match v_306:
    case (v_307, v_308):
      step_pair_application_result(v_308, v_307, v_7, v_1, v_10, v_12, v_14, v_16)

def step_pair_application(+file: String, key: String, +left: Ast.SyntaxTerm, right: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat, +end: Nat) -> FeedbackControl:
  span_value = span(file, token_beg_first(left), token_end_of(after, end))
  feedback_consumer_271042(apply_terms([left, right], file, Ast.TermRef{key, span_value}, token_beg_first(left)), after, file, scope, depth, level, end)

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

def feedback_resume_Kont_268872(capture_0: Bool, capture_1: Ast.SyntaxTerm, capture_2: List<&2, Lexer.Token>, capture_3: Bool, capture_4: String, capture_5: Ast.SyntaxTerm, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: Nat, result: Nat) -> FeedbackControl:
  step_parse_pair_operator_consumed(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, result)

def feedback_make_Kont_268872(capture_0: Bool, capture_1: Ast.SyntaxTerm, capture_2: List<&2, Lexer.Token>, capture_3: Bool, capture_4: String, capture_5: Ast.SyntaxTerm, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: Nat) -> FeedbackFrame:
  Kont_268872{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8}

def step_parse_pair_operator_result(ok: Bool, +right: Ast.SyntaxTerm, +after: List<&2, Lexer.Token>, amp: Bool, file: String, +left: Ast.SyntaxTerm, scope: List<&2, Scope>, depth: Nat, level: Nat, end: Nat, tokens: List<&2, Lexer.Token>) -> FeedbackControl:
  feedback_attach(step_consumed_token_end(tokens, after, end), feedback_make_Kont_268872(ok, right, after, amp, file, left, scope, depth, level))

def feedback_consumer_270134(v_305: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_17: Bool, v_3: String, v_4: Ast.SyntaxTerm, v_9: List<&2, Scope>, v_11: Nat, v_13: Nat, v_15: Nat, v_6: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_305:
    case ((v_306, v_307), v_308):
      step_parse_pair_operator_result(v_308, v_306, v_307, v_17, v_3, v_4, v_9, v_11, v_13, v_15, v_6)

def feedback_resume_Kont_270151(lexical_capture_17: Bool, lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat, lexical_capture_6: List<&2, Lexer.Token>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_270134(result, lexical_capture_17, lexical_capture_3, lexical_capture_4, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15, lexical_capture_6)

def step_parse_array_set_call_result(call_ok: Bool, +call: Ast.SyntaxTerm, +after_value: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, level: Nat) -> FeedbackControl:
  match call_ok:
    case True{}:
      FeedbackControl{FeedbackCall{feedback_make_parse_term_tail(file, call, after_value, scope, depth, level)}, Nil{}, NoProgress{}, NoProgress{}}
    case False{}:
      feedback_pack_5(((call, after_value), False{}))

def feedback_consumer_271952(v_307: Pair(Ast.SyntaxTerm, Bool), v_4: List<&2, Lexer.Token>, v_6: String, v_15: List<&2, Scope>, v_17: Nat, v_19: Nat) -> FeedbackControl:
  match v_307:
    case (v_308, v_309):
      step_parse_array_set_call_result(v_309, v_308, v_4, v_6, v_15, v_17, v_19)

def step_parse_array_set_value_result(ok_value: Bool, +value: Ast.SyntaxTerm, +after_value: List<&2, Lexer.Token>, +file: String, left: Ast.SyntaxTerm, typed_index: Ast.SyntaxTerm, +beg: Nat, open_end: Nat, scope: List<&2, Scope>, depth: Nat, level: Nat) -> FeedbackControl:
  match ok_value:
    case True{}:
      feedback_consumer_271952(apply_terms([Ast.TermRef{"U32", span(file, beg, open_end)}, left, typed_index, value], file, Ast.TermRef{"Array.set", span(file, beg, token_end_first(value))}, beg), after_value, file, scope, depth, level)
    case False{}:
      feedback_pack_5(((value, after_value), False{}))

def feedback_consumer_272678(v_308: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_6: String, v_7: Ast.SyntaxTerm, v_8: Ast.SyntaxTerm, v_10: Nat, v_12: Nat, v_15: List<&2, Scope>, v_17: Nat, v_19: Nat) -> FeedbackControl:
  match v_308:
    case ((v_309, v_310), v_311):
      step_parse_array_set_value_result(v_311, v_309, v_310, v_6, v_7, v_8, v_10, v_12, v_15, v_17, v_19)

def feedback_resume_Kont_272695(lexical_capture_6: String, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_8: Ast.SyntaxTerm, lexical_capture_10: Nat, lexical_capture_12: Nat, lexical_capture_15: List<&2, Scope>, lexical_capture_17: Nat, lexical_capture_19: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_272678(result, lexical_capture_6, lexical_capture_7, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_15, lexical_capture_17, lexical_capture_19)

def step_parse_array_get_result(ok: Bool, +call: Ast.SyntaxTerm, +tokens: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, level: Nat) -> FeedbackControl:
  match ok:
    case True{}:
      FeedbackControl{FeedbackCall{feedback_make_parse_term_tail(file, call, tokens, scope, depth, level)}, Nil{}, NoProgress{}, NoProgress{}}
    case False{}:
      feedback_pack_5(((call, tokens), False{}))

def feedback_consumer_276398(v_310: Pair(Ast.SyntaxTerm, Bool), v_5: List<&2, Lexer.Token>, v_1: String, v_8: List<&2, Scope>, v_10: Nat, v_12: Nat) -> FeedbackControl:
  match v_310:
    case (v_311, v_312):
      step_parse_array_get_result(v_312, v_311, v_5, v_1, v_8, v_10, v_12)

def step_parse_array_get(+file: String, left: Ast.SyntaxTerm, index: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat, +beg: Nat, +end: Nat) -> FeedbackControl:
  feedback_consumer_276398(apply_terms([Ast.TermRef{"U32", span(file, beg, end)}, left, index], file, Ast.TermRef{"Array.get", span(file, beg, end)}, beg), tokens, file, scope, depth, level)

def feedback_make_Kont_272695(lexical_capture_6: String, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_8: Ast.SyntaxTerm, lexical_capture_10: Nat, lexical_capture_12: Nat, lexical_capture_15: List<&2, Scope>, lexical_capture_17: Nat, lexical_capture_19: Nat) -> FeedbackFrame:
  Kont_272695{lexical_capture_6, lexical_capture_7, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_15, lexical_capture_17, lexical_capture_19}

def step_parse_index_set_token(set_token: Lexer.Token, after_set: List<&2, Lexer.Token>, after_close: List<&2, Lexer.Token>, +file: String, +left: Ast.SyntaxTerm, +typed_index: Ast.SyntaxTerm, +beg: Nat, +open_end: Nat, +scope: List<&2, Scope>, +depth: Nat, +level: Nat) -> FeedbackControl:
  match set_token:
    case Lexer.TokenInfo{_, "<-", _, _, _, _}:
      feedback_attach(step_parse_term(file, after_set, scope, depth, 0n), feedback_make_Kont_272695(file, left, typed_index, beg, open_end, scope, depth, level))
    case _:
      step_parse_array_get(file, left, typed_index, after_close, scope, depth, level, beg, open_end)

def step_parse_index_after_close(+after_close: List<&2, Lexer.Token>, +file: String, +left: Ast.SyntaxTerm, +typed_index: Ast.SyntaxTerm, +beg: Nat, +open_end: Nat, +scope: List<&2, Scope>, +depth: Nat, +level: Nat) -> FeedbackControl:
  match after_close:
    case +set_token <> +after_set:
      step_parse_index_set_token(set_token, after_set, after_close, file, left, typed_index, beg, open_end, scope, depth, level)
    case Nil{}:
      step_parse_array_get(file, left, typed_index, Nil{}, scope, depth, level, beg, open_end)

def feedback_resume_Kont_273854(capture_0: List<&2, Lexer.Token>, capture_1: String, capture_2: Ast.SyntaxTerm, capture_4: Nat, capture_5: Nat, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: Nat, result: Ast.SyntaxTerm) -> FeedbackControl:
  step_parse_index_after_close(capture_0, capture_1, capture_2, result, capture_4, capture_5, capture_6, capture_7, capture_8)

def index_result_is_colon(close: Lexer.Token) -> Bool:
  match close:
    case Lexer.TokenInfo{_, "]", _, _, _, _}:
      True{}
    case _:
      False{}

def index_result_branch_1(after_index: List<&2, Lexer.Token>, file: String, +close: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{"parse-error: expected ]", span(file, token_beg(close), token_end(close))}, after_index), False{})

def feedback_make_Kont_273854(capture_0: List<&2, Lexer.Token>, capture_1: String, capture_2: Ast.SyntaxTerm, capture_4: Nat, capture_5: Nat, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: Nat) -> FeedbackFrame:
  Kont_273854{capture_0, capture_1, capture_2, capture_4, capture_5, capture_6, capture_7, capture_8}

def step_index_result_branch_0(index: Ast.SyntaxTerm, file: String, left: Ast.SyntaxTerm, scope: List<&2, Scope>, depth: Nat, level: Nat, beg: Nat, open_end: Nat, after_close: List<&2, Lexer.Token>) -> FeedbackControl:
  feedback_attach(FeedbackControl{FeedbackCall{feedback_make_map_operator_term(index, "U32")}, Nil{}, NoProgress{}, NoProgress{}}, feedback_make_Kont_273854(after_close, file, left, beg, open_end, scope, depth, level))

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

def feedback_consumer_275620(v_309: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_2: Ast.SyntaxTerm, v_7: List<&2, Scope>, v_9: Nat, v_11: Nat, v_13: Nat, v_15: Nat) -> FeedbackControl:
  match v_309:
    case ((v_310, v_311), v_312):
      step_parse_index_result(v_312, v_311, v_310, v_1, v_2, v_7, v_9, v_11, v_13, v_15)

def feedback_resume_Kont_275637(lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_275620(result, lexical_capture_1, lexical_capture_2, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15)

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

def feedback_consumer_278125(v_311: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_3: String, v_5: String, v_8: Ast.SyntaxTerm, v_13: List<&2, Scope>, v_15: Nat, v_17: Nat, v_19: Nat) -> FeedbackControl:
  match v_311:
    case ((v_312, v_313), v_314):
      step_parse_operator_precedence_result(v_314, v_312, v_313, v_3, v_5, v_8, v_13, v_15, v_17, v_19)

def feedback_resume_Kont_278142(lexical_capture_3: String, lexical_capture_5: String, lexical_capture_8: Ast.SyntaxTerm, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_19: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_278125(result, lexical_capture_3, lexical_capture_5, lexical_capture_8, lexical_capture_13, lexical_capture_15, lexical_capture_17, lexical_capture_19)

def parse_reply_result(ok: Bool, +term: Ast.SyntaxTerm, after: List<&2, Lexer.Token>, file: String) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok:
    case True{}:
      ((Ast.BodyReply{term, span(file, token_beg_first(term), token_end_first(term))}, after), True{})
    case False{}:
      ((term, after), False{})

def feedback_resume_Kont_286456(lexical_capture_1: String, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, term => after => ok => parse_reply_result(ok, term, after, lexical_capture_1)))

def step_parse_local_values_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool, tokens: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, remaining: List<&2, Ast.SyntaxPattern>, +line: Nat, +acc: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match result:
    case ((value, after), True{}):
      FeedbackControl{FeedbackCall{feedback_make_parse_local_values_next(remaining, file, after, scope, depth, line, value <> acc)}, Nil{}, NoProgress{}, NoProgress{}}
    case (_, False{}):
      feedback_pack_2((((List.reverse(&2, Ast.SyntaxTerm, acc), tokens), line), False{}))

def feedback_resume_Kont_288017(capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: List<&2, Ast.SyntaxPattern>, capture_6: Nat, capture_7: List<&2, Ast.SyntaxTerm>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_local_values_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7)

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

def feedback_make_Kont_291369(lexical_capture_3: List<&2, Ast.SyntaxTerm>, lexical_capture_7: List<&2, Ast.SyntaxPattern>, lexical_capture_13: Ast.Quantity, lexical_capture_15: String, lexical_capture_17: Nat) -> FeedbackFrame:
  Kont_291369{lexical_capture_3, lexical_capture_7, lexical_capture_13, lexical_capture_15, lexical_capture_17}

def step_parse_parallel_body_ready(is_ready: Bool, values: List<&2, Ast.SyntaxTerm>, +after_values: List<&2, Lexer.Token>, patterns: List<&2, Ast.SyntaxPattern>, next_scope: List<&2, Scope>, next_depth: Nat, quantity: Ast.Quantity, +file: String, +beg: Nat, col: Nat) -> FeedbackControl:
  match is_ready:
    case True{}:
      feedback_attach(step_parse_body(file, skip_rewrite_semicolon(after_values), next_scope, next_depth, col), feedback_make_Kont_291369(values, patterns, quantity, file, beg))
    case False{}:
      feedback_pack_5(((Ast.TermHole{ "parse-error: expected an indented parallel-let body",  span(file, token_end_of(after_values, beg), token_end_of(after_values, beg))}, after_values), False{}))

def step_parse_parallel_values_result(ok_values: Bool, values: List<&2, Ast.SyntaxTerm>, +after_values: List<&2, Lexer.Token>, rhs_line: Nat, patterns: List<&2, Ast.SyntaxPattern>, next_scope: List<&2, Scope>, next_depth: Nat, +file: String, +beg: Nat, +col: Nat, quantity: Ast.Quantity) -> FeedbackControl:
  match ok_values:
    case True{}:
      step_parse_parallel_body_ready(local_group_body_ready(after_values, col, rhs_line), values, after_values, patterns, next_scope, next_depth, quantity, file, beg, col)
    case False{}:
      feedback_pack_5(((Ast.TermHole{ "parse-error: expected parallel-let values",  span(file, beg, beg)}, after_values), False{}))

def feedback_consumer_289884(v_313: Pair(Pair(Pair(List<&2, Ast.SyntaxTerm>, List<&2, Lexer.Token>), Nat), Bool), v_3: List<&2, Ast.SyntaxPattern>, v_8: List<&2, Scope>, v_10: Nat, v_12: String, v_14: Nat, v_16: Nat, v_22: Ast.Quantity) -> FeedbackControl:
  match v_313:
    case (((v_314, v_315), v_316), v_317):
      step_parse_parallel_values_result(v_317, v_314, v_315, v_316, v_3, v_8, v_10, v_12, v_14, v_16, v_22)

def feedback_resume_Kont_289909(lexical_capture_3: List<&2, Ast.SyntaxPattern>, lexical_capture_8: List<&2, Scope>, lexical_capture_10: Nat, lexical_capture_12: String, lexical_capture_14: Nat, lexical_capture_16: Nat, lexical_capture_22: Ast.Quantity, result: (((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Nat) & Bool)) -> FeedbackControl:
  feedback_consumer_289884(result, lexical_capture_3, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_22)

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

def feedback_resume_Kont_291369(lexical_capture_3: List<&2, Ast.SyntaxTerm>, lexical_capture_7: List<&2, Ast.SyntaxPattern>, lexical_capture_13: Ast.Quantity, lexical_capture_15: String, lexical_capture_17: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, body => after_body => ok_body => parse_parallel_parsed_body(ok_body, body, after_body, lexical_capture_3, lexical_capture_7, lexical_capture_13, lexical_capture_15, lexical_capture_17)))

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

def feedback_make_Kont_293608(lexical_capture_3: String, lexical_capture_5: String, lexical_capture_7: Nat, lexical_capture_10: Ast.SyntaxPattern, lexical_capture_19: Ast.Quantity, lexical_capture_11: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_293608{lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_19, lexical_capture_11}

def step_parse_local_body_ready(is_ready: Bool, +file: String, key: String, beg: Nat, col: Nat, pattern: Ast.SyntaxPattern, +value: Ast.SyntaxTerm, +after_value: List<&2, Lexer.Token>, next_scope: List<&2, Scope>, depth: Nat, quantity: Ast.Quantity) -> FeedbackControl:
  match is_ready:
    case True{}:
      feedback_attach(step_parse_body(file, skip_rewrite_semicolon(after_value), next_scope, (depth + 1n : Nat), col), feedback_make_Kont_293608(file, key, beg, pattern, quantity, value))
    case False{}:
      feedback_pack_5(((Ast.TermHole{ "parse-error: expected an indented local body",  span(file, token_end_first(value), token_end_first(value))}, after_value), False{}))

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

def feedback_consumer_292011(v_314: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_3: String, v_5: Nat, v_7: Nat, v_9: Nat, v_14: List<&2, Scope>, v_16: Nat, v_17: Ast.Quantity) -> FeedbackControl:
  match v_314:
    case ((v_315, v_316), v_317):
      step_parse_local_body_term_result(v_317, v_1, v_3, v_5, v_7, v_9, v_315, v_316, v_14, v_16, v_17)

def feedback_resume_Kont_292028(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, lexical_capture_17: Ast.Quantity, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_292011(result, lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_14, lexical_capture_16, lexical_capture_17)

def parse_local_body_parsed(ok_body: Bool, body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, file: String, key: String, beg: Nat, pattern: Ast.SyntaxPattern, quantity: Ast.Quantity, +value: Ast.SyntaxTerm) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      ((Ast.BodyLocal{ [pattern], quantity, [value], body, span(file, beg, token_end_of(after_body, token_end_first(value)))}, after_body), True{})
    case False{}:
      ((body, after_body), False{})

def feedback_resume_Kont_293608(lexical_capture_3: String, lexical_capture_5: String, lexical_capture_7: Nat, lexical_capture_10: Ast.SyntaxPattern, lexical_capture_19: Ast.Quantity, lexical_capture_11: Ast.SyntaxTerm, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, body => after_body => ok_body => parse_local_body_parsed(ok_body, body, after_body, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_19, lexical_capture_11)))

def feedback_consumer_294214(v_315: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_3: String, v_5: Nat, v_7: Nat, v_9: Nat, v_14: List<&2, Scope>, v_16: Nat) -> FeedbackControl:
  match v_315:
    case ((v_316, v_317), v_318):
      step_parse_local_body_term_result(v_318, v_1, v_3, v_5, v_7, v_9, v_316, v_317, v_14, v_16, Ast.QOne{})

def feedback_resume_Kont_294231(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_294214(result, lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_14, lexical_capture_16)

def feedback_make_Kont_297498(lexical_capture_4: Ast.SyntaxPattern, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: String, lexical_capture_13: List<&2, Lexer.Token>, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_20: List<&2, Scope>, lexical_capture_22: Nat) -> FeedbackFrame:
  Kont_297498{lexical_capture_4, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15, lexical_capture_17, lexical_capture_20, lexical_capture_22}

def step_parse_destructuring_pattern_result(ok_pattern: Bool, after_pattern: List<&2, Lexer.Token>, pattern: Ast.SyntaxPattern, next_scope: List<&2, Scope>, next_depth: Nat, +file: String, +tokens: List<&2, Lexer.Token>, beg: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match ok_pattern after_pattern:
    case True{} +equals <> after_equals:
      match equals:
        case Lexer.TokenInfo{ _, "=",  _,  _,  _,  _}:
          feedback_attach(step_parse_term(file, after_equals, scope, depth, 0n), feedback_make_Kont_297498(pattern, next_scope, next_depth, file, tokens, beg, col, scope, depth))
        case _:
          step_parse_reply(file, tokens, scope, depth)
    case _ _:
      step_parse_reply(file, tokens, scope, depth)

def feedback_consumer_296659(v_316: Pair(Pair(Ast.SyntaxPattern, List<&2, Lexer.Token>), Pair(Pair(List<&2, Scope>, Nat), Bool)), v_3: String, v_5: List<&2, Lexer.Token>, v_7: Nat, v_9: Nat, v_12: List<&2, Scope>, v_14: Nat) -> FeedbackControl:
  match v_316:
    case ((v_317, v_318), (v_319, v_320), v_321):
      step_parse_destructuring_pattern_result(v_321, v_318, v_317, v_319, v_320, v_3, v_5, v_7, v_9, v_12, v_14)

def feedback_resume_Kont_296679(lexical_capture_3: String, lexical_capture_5: List<&2, Lexer.Token>, lexical_capture_7: Nat, lexical_capture_9: Nat, lexical_capture_12: List<&2, Scope>, lexical_capture_14: Nat, result: ((Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool))) -> FeedbackControl:
  feedback_consumer_296659(result, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_12, lexical_capture_14)

def feedback_make_Kont_298751(lexical_capture_2: Ast.SyntaxTerm, lexical_capture_5: Ast.SyntaxPattern, lexical_capture_12: String, lexical_capture_14: Nat) -> FeedbackFrame:
  Kont_298751{lexical_capture_2, lexical_capture_5, lexical_capture_12, lexical_capture_14}

def step_parse_destructuring_body_ready(is_ready: Bool, +value: Ast.SyntaxTerm, +after_value: List<&2, Lexer.Token>, pattern: Ast.SyntaxPattern, next_scope: List<&2, Scope>, next_depth: Nat, +file: String, beg: Nat, col: Nat) -> FeedbackControl:
  match is_ready:
    case True{}:
      feedback_attach(step_parse_body(file, skip_rewrite_semicolon(after_value), next_scope, next_depth, col), feedback_make_Kont_298751(value, pattern, file, beg))
    case False{}:
      feedback_pack_5(((Ast.TermHole{ "parse-error: expected an indented destructuring body",  span(file, token_end_first(value), token_end_first(value))}, after_value), False{}))

def step_parse_destructuring_value_result(ok_value: Bool, +value: Ast.SyntaxTerm, +after_value: List<&2, Lexer.Token>, pattern: Ast.SyntaxPattern, next_scope: List<&2, Scope>, next_depth: Nat, file: String, tokens: List<&2, Lexer.Token>, beg: Nat, +col: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match ok_value:
    case True{}:
      step_parse_destructuring_body_ready(local_body_ready(after_value, col), value, after_value, pattern, next_scope, next_depth, file, beg, col)
    case False{}:
      feedback_pack_5(((value, after_value), False{}))

def feedback_consumer_297481(v_317: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_4: Ast.SyntaxPattern, v_7: List<&2, Scope>, v_9: Nat, v_11: String, v_13: List<&2, Lexer.Token>, v_15: Nat, v_17: Nat, v_20: List<&2, Scope>, v_22: Nat) -> FeedbackControl:
  match v_317:
    case ((v_318, v_319), v_320):
      step_parse_destructuring_value_result(v_320, v_318, v_319, v_4, v_7, v_9, v_11, v_13, v_15, v_17, v_20, v_22)

def feedback_resume_Kont_297498(lexical_capture_4: Ast.SyntaxPattern, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: String, lexical_capture_13: List<&2, Lexer.Token>, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_20: List<&2, Scope>, lexical_capture_22: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_297481(result, lexical_capture_4, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15, lexical_capture_17, lexical_capture_20, lexical_capture_22)

def parse_destructuring_parsed_body(ok_body: Bool, body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, +value: Ast.SyntaxTerm, pattern: Ast.SyntaxPattern, file: String, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      ((Ast.BodyLocal{ [pattern], Ast.QOne{}, [value], body, span(file, beg, token_end_of(after_body, token_end_first(value)))}, after_body), True{})
    case False{}:
      ((body, after_body), False{})

def feedback_resume_Kont_298751(lexical_capture_2: Ast.SyntaxTerm, lexical_capture_5: Ast.SyntaxPattern, lexical_capture_12: String, lexical_capture_14: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, body => after_body => ok_body => parse_destructuring_parsed_body(ok_body, body, after_body, lexical_capture_2, lexical_capture_5, lexical_capture_12, lexical_capture_14)))

def match_scrutinees_is_colon(colon: Lexer.Token) -> Bool:
  match colon:
    case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
      True{}
    case _:
      False{}

def match_scrutinees_branch_1(after_scrutinees: List<&2, Lexer.Token>, +file: String, +colon: Lexer.Token) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected :",  span(file, token_beg(colon), token_end(colon))}, after_scrutinees), False{})

def feedback_make_Kont_299821(lexical_capture_1: List<&2, Ast.SyntaxTerm>, lexical_capture_13: Lexer.Token, lexical_capture_3: String, lexical_capture_5: Nat) -> FeedbackFrame:
  Kont_299821{lexical_capture_1, lexical_capture_13, lexical_capture_3, lexical_capture_5}

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
  feedback_attach(step_parse_case_rows(file, after_colon, Nat.sub(col, 1n), scope, depth, List.length(&2, Ast.SyntaxTerm, scrutinees), Nil{}), feedback_make_Kont_299821(scrutinees, colon, file, beg))

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

def feedback_consumer_299316(v_318: Pair(Pair(List<&2, Ast.SyntaxTerm>, List<&2, Lexer.Token>), Bool), v_1: String, v_5: Nat, v_7: Nat, v_10: List<&2, Scope>, v_12: Nat) -> FeedbackControl:
  match v_318:
    case ((v_319, v_320), v_321):
      step_parse_match_scrutinees(v_321, v_320, v_319, v_1, v_5, v_7, v_10, v_12)

def feedback_resume_Kont_299333(lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_10: List<&2, Scope>, lexical_capture_12: Nat, result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_299316(result, lexical_capture_1, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_12)

def parse_match_cases_result(ok_cases: Bool, cases: List<&2, Ast.SyntaxTerm>, +after_cases: List<&2, Lexer.Token>, +scrutinees: List<&2, Ast.SyntaxTerm>, +colon: Lexer.Token, file: String, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_cases:
    case True{}:
      ((Ast.BodyMatch{scrutinees, cases, span(file, beg, token_end_of(after_cases, token_end_first_list(scrutinees)))}, after_cases), True{})
    case False{}:
      ((Ast.TermHole{ "parse-error: expected an indented case", span(file, token_beg(colon), token_end(colon))}, after_cases), False{})

def feedback_resume_Kont_299821(lexical_capture_1: List<&2, Ast.SyntaxTerm>, lexical_capture_13: Lexer.Token, lexical_capture_3: String, lexical_capture_5: Nat, result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_args_result(result, cases => after_cases => ok_cases => parse_match_cases_result(ok_cases, cases, after_cases, lexical_capture_1, lexical_capture_13, lexical_capture_3, lexical_capture_5)))

def feedback_make_parse_terms_until_colon_result(ok: Bool, term: Ast.SyntaxTerm, after: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.SyntaxTerm>) -> FeedbackRequest:
  Request_parse_terms_until_colon_result{ok, term, after, file, scope, depth, acc}

def feedback_consumer_302966(v_319: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_6: List<&2, Scope>, v_8: Nat, v_10: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match v_319:
    case ((v_320, v_321), v_322):
      FeedbackControl{FeedbackCall{feedback_make_parse_terms_until_colon_result(v_322, v_320, v_321, v_1, v_6, v_8, v_10)}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_resume_Kont_302984(lexical_capture_1: String, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat, lexical_capture_10: List<&2, Ast.SyntaxTerm>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_302966(result, lexical_capture_1, lexical_capture_6, lexical_capture_8, lexical_capture_10)

def step_parse_case_row_result(ok_row: Bool, +row: Ast.SyntaxTerm, +after_row: List<&2, Lexer.Token>, file: String, tokens: List<&2, Lexer.Token>, parent_col: Nat, scope: List<&2, Scope>, depth: Nat, arity: Nat, +acc: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match ok_row:
    case True{}:
      step_parse_case_rows_scan(file, after_row, skip_lines(after_row), parent_col, scope, depth, arity, row <> acc)
    case False{}:
      feedback_pack_9(((List.reverse(&2, Ast.SyntaxTerm, row <> acc), after_row), False{}))

def feedback_consumer_303553(v_320: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_3: String, v_5: List<&2, Lexer.Token>, v_9: Nat, v_12: List<&2, Scope>, v_14: Nat, v_16: Nat, v_18: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match v_320:
    case ((v_321, v_322), v_323):
      step_parse_case_row_result(v_323, v_321, v_322, v_3, v_5, v_9, v_12, v_14, v_16, v_18)

def feedback_resume_Kont_303571(lexical_capture_3: String, lexical_capture_5: List<&2, Lexer.Token>, lexical_capture_9: Nat, lexical_capture_12: List<&2, Scope>, lexical_capture_14: Nat, lexical_capture_16: Nat, lexical_capture_18: List<&2, Ast.SyntaxTerm>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_303553(result, lexical_capture_3, lexical_capture_5, lexical_capture_9, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_18)

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

def feedback_make_Kont_307637(lexical_capture_5: List<&2, Ast.SyntaxPattern>, lexical_capture_3: String, lexical_capture_15: Nat) -> FeedbackFrame:
  Kont_307637{lexical_capture_5, lexical_capture_3, lexical_capture_15}

def step_parse_case_body_indented(is_indented: Bool, +file: String, patterns: List<&2, Ast.SyntaxPattern>, +after_colon: List<&2, Lexer.Token>, +colon: Lexer.Token, scope: List<&2, Scope>, depth: Nat, beg: Nat, col: Nat) -> FeedbackControl:
  match is_indented:
    case True{}:
      feedback_attach(step_parse_body(file, after_colon, scope, depth, col), feedback_make_Kont_307637(patterns, file, beg))
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

def feedback_resume_Kont_306612(capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: Nat, result: PatternScanOutcome) -> FeedbackControl:
  step_parse_case_row_scan_result(result, capture_1, capture_2, capture_3, capture_4)

def parse_case_body_result(ok_body: Bool, +body: Ast.SyntaxTerm, +after_body: List<&2, Lexer.Token>, patterns: List<&2, Ast.SyntaxPattern>, file: String, beg: Nat) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      ((Ast.BodyCase{patterns, body, span(file, beg, token_end_of(after_body, token_end_first(body)))}, after_body), True{})
    case False{}:
      ((body, after_body), False{})

def feedback_resume_Kont_307637(lexical_capture_5: List<&2, Ast.SyntaxPattern>, lexical_capture_3: String, lexical_capture_15: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_5(with_term_result(result, body => after_body => ok_body => parse_case_body_result(ok_body, body, after_body, lexical_capture_5, lexical_capture_3, lexical_capture_15)))

def step_evaluation_context_parse_template_binder_type_result_303117(+v_4: String, v_6: List<&2, Ast.TelescopeItem>, v_9: List<&2, Scope>, +v_11: Nat, +v_13: String, v_15: Nat, +v_26: Ast.SyntaxTerm, +v_27: List<&2, Lexer.Token>, +v_29: Nat, v_306: Nat) -> FeedbackControl:
  v_34 = {Ast.TemplateBinder{v_13, v_29, v_26, span(v_4, v_15, v_306)} : Ast.TelescopeItem}
  v_37 = extend_scope(v_13, v_29, v_9)
  step_parse_def_binders(v_4, v_27, v_37, Nat.add(v_11, 1n), v_34 <> v_6)

def feedback_resume_Kont_312883(capture_0: String, capture_1: List<&2, Ast.TelescopeItem>, capture_2: List<&2, Scope>, capture_3: Nat, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: List<&2, Lexer.Token>, capture_8: Nat, result: Nat) -> FeedbackControl:
  step_evaluation_context_parse_template_binder_type_result_303117(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, result)

def feedback_make_Kont_312883(capture_0: String, capture_1: List<&2, Ast.TelescopeItem>, capture_2: List<&2, Scope>, capture_3: Nat, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: List<&2, Lexer.Token>, capture_8: Nat) -> FeedbackFrame:
  Kont_312883{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8}

def step_parse_template_binder_type_result_quantity_0(v_17: List<&2, Lexer.Token>, +v_22: List<&2, Lexer.Token>, +v_21: Ast.SyntaxTerm, +v_4: String, +v_6: List<&2, Ast.TelescopeItem>, +v_9: List<&2, Scope>, +v_11: Nat, +v_13: String, v_15: Nat) -> FeedbackControl:
  +v_24 = v_11
  feedback_attach(step_consumed_token_end(v_17, v_22, token_end_first(v_21)), feedback_make_Kont_312883(v_4, v_6, v_9, v_11, v_13, v_15, v_21, v_22, v_24))

def step_parse_template_binder_type_result(v_2: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), +v_4: String, +v_6: List<&2, Ast.TelescopeItem>, +v_9: List<&2, Scope>, +v_11: Nat, +v_13: String, v_15: Nat, v_17: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_2:
    case ((+v_21, v_22), True{}):
      step_parse_template_binder_type_result_quantity_0(v_17, v_22, v_21, v_4, v_6, v_9, v_11, v_13, v_15)
    case ((v_31, v_32), False{}):
      feedback_pack_1(((((List.reverse(&2, Ast.TelescopeItem, v_6), v_32), v_9), v_11), False{}))

def feedback_resume_Kont_313531(capture_1: String, capture_2: List<&2, Ast.TelescopeItem>, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: String, capture_6: Nat, capture_7: List<&2, Lexer.Token>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_template_binder_type_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7)

def step_evaluation_context_parse_def_binder_type_result_306129(+v_4: String, +v_6: String, v_7: Ast.Quantity, v_9: Nat, v_11: List<&2, Ast.TelescopeItem>, v_14: List<&2, Scope>, +v_16: Nat, +v_27: Ast.SyntaxTerm, +v_28: List<&2, Lexer.Token>, +v_30: Nat, v_307: Nat) -> FeedbackControl:
  v_35 = {Ast.Binder{v_7, v_6, v_30, v_27, span(v_4, v_9, v_307)} : Ast.TelescopeItem}
  v_38 = extend_scope(v_6, v_30, v_14)
  step_parse_def_binders(v_4, v_28, v_38, Nat.add(v_16, 1n), v_35 <> v_11)

def feedback_resume_Kont_316332(capture_0: String, capture_1: String, capture_2: Ast.Quantity, capture_3: Nat, capture_4: List<&2, Ast.TelescopeItem>, capture_5: List<&2, Scope>, capture_6: Nat, capture_7: Ast.SyntaxTerm, capture_8: List<&2, Lexer.Token>, capture_9: Nat, result: Nat) -> FeedbackControl:
  step_evaluation_context_parse_def_binder_type_result_306129(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, result)

def feedback_make_Kont_316332(capture_0: String, capture_1: String, capture_2: Ast.Quantity, capture_3: Nat, capture_4: List<&2, Ast.TelescopeItem>, capture_5: List<&2, Scope>, capture_6: Nat, capture_7: Ast.SyntaxTerm, capture_8: List<&2, Lexer.Token>, capture_9: Nat) -> FeedbackFrame:
  Kont_316332{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9}

def step_parse_def_binder_type_result_quantity_0(v_18: List<&2, Lexer.Token>, +v_23: List<&2, Lexer.Token>, +v_22: Ast.SyntaxTerm, +v_4: String, +v_6: String, v_7: Ast.Quantity, v_9: Nat, +v_11: List<&2, Ast.TelescopeItem>, +v_14: List<&2, Scope>, +v_16: Nat) -> FeedbackControl:
  +v_25 = v_16
  feedback_attach(step_consumed_token_end(v_18, v_23, token_end_first(v_22)), feedback_make_Kont_316332(v_4, v_6, v_7, v_9, v_11, v_14, v_16, v_22, v_23, v_25))

def step_parse_def_binder_type_result(v_2: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), +v_4: String, +v_6: String, v_7: Ast.Quantity, v_9: Nat, +v_11: List<&2, Ast.TelescopeItem>, +v_14: List<&2, Scope>, +v_16: Nat, v_18: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_2:
    case ((+v_22, v_23), True{}):
      step_parse_def_binder_type_result_quantity_0(v_18, v_23, v_22, v_4, v_6, v_7, v_9, v_11, v_14, v_16)
    case ((v_32, v_33), False{}):
      feedback_pack_1(((((List.reverse(&2, Ast.TelescopeItem, v_11), v_33), v_14), v_16), False{}))

def feedback_resume_Kont_316984(capture_1: String, capture_2: String, capture_3: Ast.Quantity, capture_4: Nat, capture_5: List<&2, Ast.TelescopeItem>, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: List<&2, Lexer.Token>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_def_binder_type_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8)

def feedback_pack_3(result: ((Ast.DefBody & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  match result:
    case ((result_0_0, result_0_1), result_1):
      FeedbackControl{FeedbackDone{Value_3{result_0_0, result_0_1, result_1}}, Nil{}, NoProgress{}, NoProgress{}}

def parse_definition_term_result(result: (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool) -> (Ast.DefBody & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((term, after), ok):
      ((Ast.DefTerm{term}, after), ok)

def feedback_resume_Kont_318578(result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
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

def feedback_resume_Kont_320249(lexical_capture_0: Lexer.Token, lexical_capture_2: List<&2, Lexer.Token>, lexical_capture_8: String, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_14: List<&2, Ast.TelescopeItem>, lexical_capture_5: Ast.SyntaxTerm, result: ((Ast.DefBody & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_6(with_def_body_result(result, body => after_body => ok_body => parse_definition_typed_body_result(ok_body, body, after_body, lexical_capture_0, lexical_capture_2, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_5)))

def feedback_make_Kont_320249(lexical_capture_0: Lexer.Token, lexical_capture_2: List<&2, Lexer.Token>, lexical_capture_8: String, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_14: List<&2, Ast.TelescopeItem>, lexical_capture_5: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_320249{lexical_capture_0, lexical_capture_2, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_5}

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

def feedback_make_Kont_318578() -> FeedbackFrame:
  Kont_318578{}

def step_definition_body_branch_1(file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_body(file, tokens, scope, depth, 0n), feedback_make_Kont_318578())

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
      feedback_attach(step_parse_definition_body(file, after_colon, scope, depth), feedback_make_Kont_320249(colon, after_colon, file, key, beg, binders, result))
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

def feedback_resume_Kont_321678(capture_1: Lexer.Token, capture_2: String, capture_3: String, capture_4: Nat, capture_5: List<&2, Ast.TelescopeItem>, capture_6: List<&2, Scope>, capture_7: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  step_parse_definition_typed_result(result, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7)

def parse_definition_untyped_body_result(ok_body: Bool, body: Ast.DefBody, +after_body: List<&2, Lexer.Token>, file: String, key: String, beg: Nat, binders: List<&2, Ast.TelescopeItem>, header: Lexer.Token, rest: List<&2, Lexer.Token>) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match ok_body:
    case True{}:
      ((Ast.DefTop{Ast.Definition{key, binders, Ast.NoTerm{}, body, False{}, span(file, beg, token_end_of(after_body, token_end(header)))}}, after_body), True{})
    case False{}:
      definition_failure(file, key, binders, beg, token_end(header), rest)

def feedback_resume_Kont_322047(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: List<&2, Ast.TelescopeItem>, lexical_capture_13: Lexer.Token, lexical_capture_15: List<&2, Lexer.Token>, result: ((Ast.DefBody & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
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

def feedback_make_Kont_321678(capture_1: Lexer.Token, capture_2: String, capture_3: String, capture_4: Nat, capture_5: List<&2, Ast.TelescopeItem>, capture_6: List<&2, Scope>, capture_7: Nat) -> FeedbackFrame:
  Kont_321678{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7}

def step_definition_header_branch_0(+file: String, key: String, +beg: Nat, binders: List<&2, Ast.TelescopeItem>, +scope: List<&2, Scope>, +depth: Nat, +header: Lexer.Token, +rest: List<&2, Lexer.Token>) -> FeedbackControl:
  feedback_attach(step_parse_term(file, rest, scope, depth, 0n), feedback_make_Kont_321678(header, file, key, beg, binders, scope, depth))

def feedback_make_Kont_322047(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: List<&2, Ast.TelescopeItem>, lexical_capture_13: Lexer.Token, lexical_capture_15: List<&2, Lexer.Token>) -> FeedbackFrame:
  Kont_322047{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_13, lexical_capture_15}

def step_definition_header_branch_1(+file: String, key: String, +beg: Nat, binders: List<&2, Ast.TelescopeItem>, +scope: List<&2, Scope>, +depth: Nat, +header: Lexer.Token, +rest: List<&2, Lexer.Token>) -> FeedbackControl:
  feedback_attach(step_parse_definition_body(file, rest, scope, depth), feedback_make_Kont_322047(file, key, beg, binders, header, rest))

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

def feedback_consumer_325018(v_321: Pair(Pair(Pair(Pair(List<&2, Ast.TelescopeItem>, List<&2, Lexer.Token>), List<&2, Scope>), Nat), Bool), v_1: String, v_3: String, v_5: Nat) -> FeedbackControl:
  match v_321:
    case ((((v_322, v_323), v_324), v_325), v_326):
      step_parse_definition_binders_result(v_326, v_322, v_323, v_324, v_325, v_1, v_3, v_5)

def feedback_resume_Kont_325042(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, result: ((((List<&2, Ast.TelescopeItem> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool)) -> FeedbackControl:
  feedback_consumer_325018(result, lexical_capture_1, lexical_capture_3, lexical_capture_5)

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

def feedback_resume_Kont_330212(result: ((Ast.TopLevel & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_6(with_top_result(result, top => after => ok => ((mark_unsafe(top, True{}), after), ok)))

def feedback_resume_Kont_330347(result: ((Ast.TopLevel & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_6(with_top_result(result, top => after => _ => ((top, after), False{})))

def feedback_make_parse_type_constructor_fields_result(ok_fields: Bool, fields: List<&2, Ast.TelescopeItem>, after_fields: List<&2, Lexer.Token>, file: String, open: Lexer.Token, after_open: List<&2, Lexer.Token>, col: Nat, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.ConstructorDecl>, key: String, beg: Nat) -> FeedbackRequest:
  Request_parse_type_constructor_fields_result{ok_fields, fields, after_fields, file, open, after_open, col, scope, depth, acc, key, beg}

def feedback_consumer_332927(v_323: Pair(Pair(Pair(Pair(List<&2, Ast.TelescopeItem>, List<&2, Lexer.Token>), List<&2, Scope>), Nat), Bool), v_3: String, v_26: Lexer.Token, v_27: List<&2, Lexer.Token>, v_9: Nat, v_12: List<&2, Scope>, v_14: Nat, v_16: List<&2, Ast.ConstructorDecl>, v_18: String, v_20: Nat) -> FeedbackControl:
  match v_323:
    case ((((v_324, v_325), v_326), v_327), v_328):
      FeedbackControl{FeedbackCall{feedback_make_parse_type_constructor_fields_result(v_328, v_324, v_325, v_3, v_26, v_27, v_9, v_12, v_14, v_16, v_18, v_20)}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_resume_Kont_332964(lexical_capture_3: String, lexical_capture_26: Lexer.Token, lexical_capture_27: List<&2, Lexer.Token>, lexical_capture_9: Nat, lexical_capture_12: List<&2, Scope>, lexical_capture_14: Nat, lexical_capture_16: List<&2, Ast.ConstructorDecl>, lexical_capture_18: String, lexical_capture_20: Nat, result: ((((List<&2, Ast.TelescopeItem> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool)) -> FeedbackControl:
  feedback_consumer_332927(result, lexical_capture_3, lexical_capture_26, lexical_capture_27, lexical_capture_9, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_18, lexical_capture_20)

def parse_type_header_constructors_result(ok_constructors: Bool, constructors: List<&2, Ast.ConstructorDecl>, +after_constructors: List<&2, Lexer.Token>, file: String, key: String, beg: Nat, params: List<&2, Ast.TelescopeItem>, +kind: Ast.SyntaxTerm) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  declaration = { Ast.TypeDecl{key, params, kind, constructors, span(file, beg, token_end_of(after_constructors, token_end_first(kind)))} : Ast.TypeDecl }
  ((Ast.TypeTop{declaration}, after_constructors), ok_constructors)

def with_constructor_decls_result(result: (List<&2, Ast.ConstructorDecl> & List<&2, Lexer.Token>) & Bool, use: List<&2, Ast.ConstructorDecl> -> List<&2, Lexer.Token> -> Bool -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool) -> (Ast.TopLevel & List<&2, Lexer.Token>) & Bool:
  match result:
    case ((constructors, after), ok):
      use(constructors, after, ok)

def feedback_resume_Kont_335020(lexical_capture_6: String, lexical_capture_8: String, lexical_capture_10: Nat, lexical_capture_14: List<&2, Ast.TelescopeItem>, lexical_capture_2: Ast.SyntaxTerm, result: ((List<&2, Ast.ConstructorDecl> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_pack_6(with_constructor_decls_result(result, constructors => after_constructors => ok_constructors => parse_type_header_constructors_result(ok_constructors, constructors, after_constructors, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_14, lexical_capture_2)))

def feedback_make_Kont_335020(lexical_capture_6: String, lexical_capture_8: String, lexical_capture_10: Nat, lexical_capture_14: List<&2, Ast.TelescopeItem>, lexical_capture_2: Ast.SyntaxTerm) -> FeedbackFrame:
  Kont_335020{lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_14, lexical_capture_2}

def step_parse_type_constructors(file: String, +tokens: List<&2, Lexer.Token>, col: Nat, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.ConstructorDecl>) -> FeedbackControl:
  step_parse_type_constructors_scan(file, tokens, skip_lines(tokens), col, scope, depth, acc)

def step_parse_type_header_kind_result(ok_kind: Bool, +kind: Ast.SyntaxTerm, +after_kind: List<&2, Lexer.Token>, +file: String, +key: String, +beg: Nat, col: Nat, params: List<&2, Ast.TelescopeItem>, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match ok_kind after_kind:
    case True{} +colon <> after_colon:
      match colon:
        case Lexer.TokenInfo{ _, ":", _, _, _, _}:
          feedback_attach(step_parse_type_constructors(file, after_colon, col, scope, depth, Nil{}), feedback_make_Kont_335020(file, key, beg, params, kind))
        case Lexer.TokenInfo{feedback_field_6_0, feedback_field_6_1, feedback_field_6_2, feedback_field_6_3, feedback_field_6_4, feedback_field_6_5}:
          feedback_pack_6(type_failure(file, key, beg, token_beg((Lexer.TokenInfo{feedback_field_6_0, feedback_field_6_1, feedback_field_6_2, feedback_field_6_3, feedback_field_6_4, feedback_field_6_5} : Lexer.Token)), after_kind))
    case _ _:
      feedback_pack_6(type_failure(file, key, beg, token_end_first(kind), after_kind))

def feedback_consumer_335838(v_324: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_3: String, v_5: Nat, v_7: Nat, v_9: List<&2, Ast.TelescopeItem>, v_11: List<&2, Lexer.Token>, v_16: List<&2, Scope>, v_18: Nat) -> FeedbackControl:
  match v_324:
    case ((v_325, v_326), v_327):
      step_parse_type_header_kind_result(v_327, v_325, v_326, v_1, v_3, v_5, v_7, v_9, v_11, v_16, v_18)

def feedback_resume_Kont_335852(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: List<&2, Ast.TelescopeItem>, lexical_capture_11: List<&2, Lexer.Token>, lexical_capture_16: List<&2, Scope>, lexical_capture_18: Nat, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_335838(result, lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_16, lexical_capture_18)

def step_parse_type_params_result(ok_params: Bool, params: List<&2, Ast.TelescopeItem>, +after_params: List<&2, Lexer.Token>, open: Lexer.Token, +file: String, +key: String, +beg: Nat, col: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match ok_params:
    case True{}:
      step_parse_type_header(file, key, beg, col, params, after_params, scope, depth)
    case False{}:
      feedback_pack_6(type_failure(file, key, beg, token_end(open), after_params))

def feedback_consumer_337429(v_326: Pair(Pair(Pair(Pair(List<&2, Ast.TelescopeItem>, List<&2, Lexer.Token>), List<&2, Scope>), Nat), Bool), v_26: Lexer.Token, v_1: String, v_19: String, v_5: Nat, v_7: Nat) -> FeedbackControl:
  match v_326:
    case ((((v_327, v_328), v_329), v_330), v_331):
      step_parse_type_params_result(v_331, v_327, v_328, v_26, v_1, v_19, v_5, v_7, v_329, v_330)

def feedback_resume_Kont_337453(lexical_capture_26: Lexer.Token, lexical_capture_1: String, lexical_capture_19: String, lexical_capture_5: Nat, lexical_capture_7: Nat, result: ((((List<&2, Ast.TelescopeItem> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool)) -> FeedbackControl:
  feedback_consumer_337429(result, lexical_capture_26, lexical_capture_1, lexical_capture_19, lexical_capture_5, lexical_capture_7)

def feedback_consumer_337895(v_325: Pair(Pair(Pair(Pair(List<&2, Ast.TelescopeItem>, List<&2, Lexer.Token>), List<&2, Scope>), Nat), Bool), v_26: Lexer.Token, v_1: String, v_19: String, v_5: Nat, v_7: Nat) -> FeedbackControl:
  match v_325:
    case ((((v_326, v_327), v_328), v_329), v_330):
      step_parse_type_params_result(v_330, v_326, v_327, v_26, v_1, v_19, v_5, v_7, v_328, v_329)

def feedback_resume_Kont_337919(lexical_capture_26: Lexer.Token, lexical_capture_1: String, lexical_capture_19: String, lexical_capture_5: Nat, lexical_capture_7: Nat, result: ((((List<&2, Ast.TelescopeItem> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool)) -> FeedbackControl:
  feedback_consumer_337895(result, lexical_capture_26, lexical_capture_1, lexical_capture_19, lexical_capture_5, lexical_capture_7)

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

def feedback_resume_Kont_339950(lexical_capture_12: String, lexical_capture_14: String, lexical_capture_3: List<&2, Ast.Clause>, lexical_capture_16: Nat, lexical_capture_17: Lexer.Token, lexical_capture_5: List<&2, Lexer.Token>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
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

def feedback_consumer_343876(v_327: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_31: String, v_32: Nat, v_33: Nat, v_5: Nat, v_7: Bool, v_8: Ast.Quantity, v_11: List<&2, Scope>, v_13: Nat, v_15: List<&2, Ast.Clause>) -> FeedbackControl:
  match v_327:
    case ((v_328, v_329), v_330):
      step_parse_law_clause_type_result(v_330, v_328, v_329, v_1, v_31, v_32, v_33, v_5, v_7, v_8, v_11, v_13, v_15)

def feedback_resume_Kont_343898(lexical_capture_1: String, lexical_capture_31: String, lexical_capture_32: Nat, lexical_capture_33: Nat, lexical_capture_5: Nat, lexical_capture_7: Bool, lexical_capture_8: Ast.Quantity, lexical_capture_11: List<&2, Scope>, lexical_capture_13: Nat, lexical_capture_15: List<&2, Ast.Clause>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_343876(result, lexical_capture_1, lexical_capture_31, lexical_capture_32, lexical_capture_33, lexical_capture_5, lexical_capture_7, lexical_capture_8, lexical_capture_11, lexical_capture_13, lexical_capture_15)

def step_parse_law_clause_condition_result(ok_condition: Bool, +condition: Ast.SyntaxTerm, +after_condition: List<&2, Lexer.Token>, +file: String, beg: Nat, universal: Bool, quantity: Ast.Quantity, key: String, key_beg: Nat, ty: Ast.SyntaxTerm, +next_scope: List<&2, Scope>, +next_depth: Nat, +acc: List<&2, Ast.Clause>) -> FeedbackControl:
  match ok_condition:
    case True{}:
      clause = { Ast.ClauseFor{universal, quantity, key, ty, Some{condition}, span(file, key_beg, token_end_first(condition))} : Ast.Clause }
      step_parse_law_clauses(file, after_condition, next_scope, next_depth, clause <> acc)
    case False{}:
      feedback_pack_0(((((List.reverse(&2, Ast.Clause, acc), after_condition), next_scope), next_depth), False{}))

def feedback_consumer_345842(v_328: Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool), v_1: String, v_7: Nat, v_9: Bool, v_10: Ast.Quantity, v_12: String, v_14: Nat, v_17: Ast.SyntaxTerm, v_20: List<&2, Scope>, v_22: Nat, v_24: List<&2, Ast.Clause>) -> FeedbackControl:
  match v_328:
    case ((v_329, v_330), v_331):
      step_parse_law_clause_condition_result(v_331, v_329, v_330, v_1, v_7, v_9, v_10, v_12, v_14, v_17, v_20, v_22, v_24)

def feedback_resume_Kont_345864(lexical_capture_1: String, lexical_capture_7: Nat, lexical_capture_9: Bool, lexical_capture_10: Ast.Quantity, lexical_capture_12: String, lexical_capture_14: Nat, lexical_capture_17: Ast.SyntaxTerm, lexical_capture_20: List<&2, Scope>, lexical_capture_22: Nat, lexical_capture_24: List<&2, Ast.Clause>, result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_345842(result, lexical_capture_1, lexical_capture_7, lexical_capture_9, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_17, lexical_capture_20, lexical_capture_22, lexical_capture_24)

def feedback_make_Kont_339950(lexical_capture_12: String, lexical_capture_14: String, lexical_capture_3: List<&2, Ast.Clause>, lexical_capture_16: Nat, lexical_capture_17: Lexer.Token, lexical_capture_5: List<&2, Lexer.Token>) -> FeedbackFrame:
  Kont_339950{lexical_capture_12, lexical_capture_14, lexical_capture_3, lexical_capture_16, lexical_capture_17, lexical_capture_5}

def step_parse_law_clauses_result(ok_clauses: Bool, clauses: List<&2, Ast.Clause>, +after_clauses: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, +file: String, +key: String, +beg: Nat, +colon: Lexer.Token, after_colon: List<&2, Lexer.Token>) -> FeedbackControl:
  match ok_clauses:
    case True{}:
      feedback_attach(step_parse_body(file, after_clauses, scope, depth, 0n), feedback_make_Kont_339950(file, key, clauses, beg, colon, after_clauses))
    case False{}:
      feedback_pack_6(law_failure(file, key, beg, token_end(colon), after_colon))

def feedback_consumer_348146(v_329: Pair(Pair(Pair(Pair(List<&2, Ast.Clause>, List<&2, Lexer.Token>), List<&2, Scope>), Nat), Bool), v_1: String, v_17: String, v_5: Nat, v_24: Lexer.Token, v_25: List<&2, Lexer.Token>) -> FeedbackControl:
  match v_329:
    case ((((v_330, v_331), v_332), v_333), v_334):
      step_parse_law_clauses_result(v_334, v_330, v_331, v_332, v_333, v_1, v_17, v_5, v_24, v_25)

def feedback_resume_Kont_348170(lexical_capture_1: String, lexical_capture_17: String, lexical_capture_5: Nat, lexical_capture_24: Lexer.Token, lexical_capture_25: List<&2, Lexer.Token>, result: ((((List<&2, Ast.Clause> & List<&2, Lexer.Token>) & List<&2, Scope>) & Nat) & Bool)) -> FeedbackControl:
  feedback_consumer_348146(result, lexical_capture_1, lexical_capture_17, lexical_capture_5, lexical_capture_24, lexical_capture_25)

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

def feedback_consumer_352761(v_333: Pair(Pair(Ast.TopLevel, List<&2, Lexer.Token>), Bool), v_12: Map<&2, TopOwner>, v_19: List<&2, Lexer.Token>, v_3: List<&2, Lexer.Token>, v_1: String, v_7: String, v_9: List<&2, Ast.TopLevel>) -> FeedbackControl:
  match v_333:
    case ((+v_334, v_335), v_336):
      FeedbackControl{FeedbackCall{feedback_make_parse_top_result(top_owner_checked_result(top_owner_query(v_334, v_12), v_334, v_336, v_19), v_334, v_335, v_3, v_1, v_7, v_9)}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_resume_Kont_352782(lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>, result: ((Ast.TopLevel & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_352761(result, lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9)

def feedback_consumer_353051(v_332: Pair(Pair(Ast.TopLevel, List<&2, Lexer.Token>), Bool), v_12: Map<&2, TopOwner>, v_19: List<&2, Lexer.Token>, v_3: List<&2, Lexer.Token>, v_1: String, v_7: String, v_9: List<&2, Ast.TopLevel>) -> FeedbackControl:
  match v_332:
    case ((+v_333, v_334), v_335):
      FeedbackControl{FeedbackCall{feedback_make_parse_top_result(top_owner_checked_result(top_owner_query(v_333, v_12), v_333, v_335, v_19), v_333, v_334, v_3, v_1, v_7, v_9)}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_resume_Kont_353072(lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>, result: ((Ast.TopLevel & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_353051(result, lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9)

def feedback_consumer_353344(v_331: Pair(Pair(Ast.TopLevel, List<&2, Lexer.Token>), Bool), v_12: Map<&2, TopOwner>, v_19: List<&2, Lexer.Token>, v_3: List<&2, Lexer.Token>, v_1: String, v_7: String, v_9: List<&2, Ast.TopLevel>) -> FeedbackControl:
  match v_331:
    case ((+v_332, v_333), v_334):
      FeedbackControl{FeedbackCall{feedback_make_parse_top_result(top_owner_checked_result(top_owner_query(v_332, v_12), v_332, v_334, v_19), v_332, v_333, v_3, v_1, v_7, v_9)}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_resume_Kont_353365(lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>, result: ((Ast.TopLevel & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_353344(result, lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9)

def feedback_consumer_353635(v_330: Pair(Pair(Ast.TopLevel, List<&2, Lexer.Token>), Bool), v_12: Map<&2, TopOwner>, v_19: List<&2, Lexer.Token>, v_3: List<&2, Lexer.Token>, v_1: String, v_7: String, v_9: List<&2, Ast.TopLevel>) -> FeedbackControl:
  match v_330:
    case ((+v_331, v_332), v_333):
      FeedbackControl{FeedbackCall{feedback_make_parse_top_result(top_owner_checked_result(top_owner_query(v_331, v_12), v_331, v_333, v_19), v_331, v_332, v_3, v_1, v_7, v_9)}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_resume_Kont_353656(lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>, result: ((Ast.TopLevel & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_353635(result, lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9)

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

def feedback_resume_Kont_355557(lexical_capture_7: String, lexical_capture_3: List<&2, Ast.ModuleImport>, result: ((List<&2, Ast.TopLevel> & Bool) & List<&2, Lexer.Token>)) -> FeedbackControl:
  feedback_pack_17(with_top_declarations_result(result, declarations => ok => rest => parse_module_declarations_result(ok, declarations, rest, lexical_capture_7, lexical_capture_3)))

def feedback_make_Kont_355557(lexical_capture_7: String, lexical_capture_3: List<&2, Ast.ModuleImport>) -> FeedbackFrame:
  Kont_355557{lexical_capture_7, lexical_capture_3}

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
      feedback_attach(step_parse_top(file, after_imports, file, Nil{}), feedback_make_Kont_355557(file, imports))
    case False{}:
      feedback_pack_17(ParseFailure{ "invalid module import", "import path with optional as-name", observed(after_imports), error_span(file, after_imports)})

def feedback_consumer_355990(v_334: Pair(Pair(List<&2, Ast.ModuleImport>, List<&2, Lexer.Token>), Bool), v_3: String) -> FeedbackControl:
  match v_334:
    case ((v_335, v_336), v_337):
      step_parse_module_imports_result(v_337, v_335, v_336, v_3)

def feedback_resume_Kont_356010(lexical_capture_3: String, result: ((List<&2, Ast.ModuleImport> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  feedback_consumer_355990(result, lexical_capture_3)

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
    case Kont_130823{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8}:
      match value:
        case Value_4{result_0_0, result_0_1, result_1_0_0, result_1_0_1, result_1_1}:
          feedback_resume_Kont_130823(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, ((result_0_0, result_0_1), ((result_1_0_0, result_1_0_1), result_1_1)))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_136112{capture_1}:
      match value:
        case Value_14{result}:
          feedback_resume_Kont_136112(capture_1, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_136348{capture_1}:
      match value:
        case Value_13{result}:
          feedback_resume_Kont_136348(capture_1, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_136857{capture_1, capture_2}:
      match value:
        case Value_14{result}:
          feedback_resume_Kont_136857(capture_1, capture_2, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_138004{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8}:
      match value:
        case Value_13{result}:
          feedback_resume_Kont_138004(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_139735{capture_1, capture_2, capture_3}:
      match value:
        case Value_4{result_0_0, result_0_1, result_1_0_0, result_1_0_1, result_1_1}:
          feedback_resume_Kont_139735(capture_1, capture_2, capture_3, ((result_0_0, result_0_1), ((result_1_0_0, result_1_0_1), result_1_1)))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_140566{capture_1, capture_2}:
      match value:
        case Value_4{result_0_0, result_0_1, result_1_0_0, result_1_0_1, result_1_1}:
          feedback_resume_Kont_140566(capture_1, capture_2, ((result_0_0, result_0_1), ((result_1_0_0, result_1_0_1), result_1_1)))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_143905{capture_1, capture_2, capture_3, capture_4, capture_5}:
      match value:
        case Value_4{result_0_0, result_0_1, result_1_0_0, result_1_0_1, result_1_1}:
          feedback_resume_Kont_143905(capture_1, capture_2, capture_3, capture_4, capture_5, ((result_0_0, result_0_1), ((result_1_0_0, result_1_0_1), result_1_1)))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_149803{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6}:
      match value:
        case Value_4{result_0_0, result_0_1, result_1_0_0, result_1_0_1, result_1_1}:
          feedback_resume_Kont_149803(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, ((result_0_0, result_0_1), ((result_1_0_0, result_1_0_1), result_1_1)))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_171361{capture_1, capture_2}:
      match value:
        case Value_18{result}:
          feedback_resume_Kont_171361(capture_1, capture_2, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_180515{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7}:
      match value:
        case Value_9{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_180515(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_182131{capture_1, capture_2, capture_3, capture_4}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_182131(capture_1, capture_2, capture_3, capture_4, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_188212{capture_1, capture_2}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_188212(capture_1, capture_2, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_188724{capture_1, capture_2, capture_3, capture_4, capture_5}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_188724(capture_1, capture_2, capture_3, capture_4, capture_5, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_190051{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10, capture_11}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_190051(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10, capture_11, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_193125{lexical_capture_4, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_13, lexical_capture_29, lexical_capture_15, lexical_capture_17, lexical_capture_22}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_193125(lexical_capture_4, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_13, lexical_capture_29, lexical_capture_15, lexical_capture_17, lexical_capture_22, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_194056{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_194056(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_195068{lexical_capture_4, lexical_capture_10, lexical_capture_12, lexical_capture_22, lexical_capture_13, lexical_capture_29}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_195068(lexical_capture_4, lexical_capture_10, lexical_capture_12, lexical_capture_22, lexical_capture_13, lexical_capture_29, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_195719{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10, capture_11}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_195719(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, capture_10, capture_11, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_197784{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_197784(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_198352{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_198352(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_199714{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_6, lexical_capture_7, lexical_capture_11, lexical_capture_13, lexical_capture_18}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_199714(lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_6, lexical_capture_7, lexical_capture_11, lexical_capture_13, lexical_capture_18, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_202679{capture_1, capture_2, capture_3, capture_4, capture_5}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_202679(capture_1, capture_2, capture_3, capture_4, capture_5, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_203834{capture_1, capture_2, capture_3, capture_4, capture_5}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_203834(capture_1, capture_2, capture_3, capture_4, capture_5, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_205019{lexical_capture_4, lexical_capture_5, lexical_capture_7}:
      match value:
        case Value_9{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_205019(lexical_capture_4, lexical_capture_5, lexical_capture_7, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_205711{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_205711(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_206436{capture_1, capture_2, capture_3, capture_4, capture_5}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_206436(capture_1, capture_2, capture_3, capture_4, capture_5, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_206773{capture_1, capture_2, capture_3, capture_4, capture_5}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_206773(capture_1, capture_2, capture_3, capture_4, capture_5, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_209330{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7}:
      match value:
        case Value_9{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_209330(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_210566{capture_1, capture_2, capture_3, capture_4, capture_5}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_210566(capture_1, capture_2, capture_3, capture_4, capture_5, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_210989{capture_1, capture_2}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_210989(capture_1, capture_2, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_211890{capture_1, capture_2, capture_3}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_211890(capture_1, capture_2, capture_3, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_214756{capture_1, capture_2, capture_3, capture_4, capture_5}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_214756(capture_1, capture_2, capture_3, capture_4, capture_5, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_218383{lexical_capture_98, lexical_capture_99, lexical_capture_100, lexical_capture_107}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_218383(lexical_capture_98, lexical_capture_99, lexical_capture_100, lexical_capture_107, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_218057{lexical_capture_98, lexical_capture_99, lexical_capture_100, lexical_capture_107}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_218057(lexical_capture_98, lexical_capture_99, lexical_capture_100, lexical_capture_107, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_217717{lexical_capture_98, lexical_capture_99, lexical_capture_100, lexical_capture_107}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_217717(lexical_capture_98, lexical_capture_99, lexical_capture_100, lexical_capture_107, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_216886{lexical_capture_49, lexical_capture_50, lexical_capture_51, lexical_capture_52, lexical_capture_53, lexical_capture_55, lexical_capture_56, lexical_capture_57}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_216886(lexical_capture_49, lexical_capture_50, lexical_capture_51, lexical_capture_52, lexical_capture_53, lexical_capture_55, lexical_capture_56, lexical_capture_57, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_219577{lexical_capture_1, lexical_capture_3, lexical_capture_4, lexical_capture_8}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_219577(lexical_capture_1, lexical_capture_3, lexical_capture_4, lexical_capture_8, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_219930{lexical_capture_1}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_219930(lexical_capture_1, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_220317{lexical_capture_2, lexical_capture_3, lexical_capture_0, lexical_capture_5}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_220317(lexical_capture_2, lexical_capture_3, lexical_capture_0, lexical_capture_5, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_222919{lexical_capture_4, lexical_capture_2, lexical_capture_6, lexical_capture_9, lexical_capture_11}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_222919(lexical_capture_4, lexical_capture_2, lexical_capture_6, lexical_capture_9, lexical_capture_11, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_223326{lexical_capture_4, lexical_capture_2, lexical_capture_6}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_223326(lexical_capture_4, lexical_capture_2, lexical_capture_6, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_226118{lexical_capture_1, lexical_capture_5, lexical_capture_10, lexical_capture_12}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_226118(lexical_capture_1, lexical_capture_5, lexical_capture_10, lexical_capture_12, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_226642{lexical_capture_2, lexical_capture_3, lexical_capture_0, lexical_capture_5, lexical_capture_10}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_226642(lexical_capture_2, lexical_capture_3, lexical_capture_0, lexical_capture_5, lexical_capture_10, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_228444{lexical_capture_1, lexical_capture_2, lexical_capture_6, lexical_capture_9, lexical_capture_11}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_228444(lexical_capture_1, lexical_capture_2, lexical_capture_6, lexical_capture_9, lexical_capture_11, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_229380{lexical_capture_6, lexical_capture_21, lexical_capture_8, lexical_capture_10, lexical_capture_13, lexical_capture_15}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_229380(lexical_capture_6, lexical_capture_21, lexical_capture_8, lexical_capture_10, lexical_capture_13, lexical_capture_15, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_230983{lexical_capture_1, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_12}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_230983(lexical_capture_1, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_12, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_231779{lexical_capture_7, lexical_capture_28, lexical_capture_6, lexical_capture_11}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_231779(lexical_capture_7, lexical_capture_28, lexical_capture_6, lexical_capture_11, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_232455{lexical_capture_1, lexical_capture_2, lexical_capture_4, lexical_capture_6, lexical_capture_9, lexical_capture_11}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_232455(lexical_capture_1, lexical_capture_2, lexical_capture_4, lexical_capture_6, lexical_capture_9, lexical_capture_11, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_235478{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_20}:
      match value:
        case Value_9{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_235478(lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_20, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_235238{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_14}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_235238(lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_14, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_238873{lexical_capture_3, lexical_capture_8, lexical_capture_10, lexical_capture_13, lexical_capture_15, lexical_capture_17}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_238873(lexical_capture_3, lexical_capture_8, lexical_capture_10, lexical_capture_13, lexical_capture_15, lexical_capture_17, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_240566{lexical_capture_2, lexical_capture_4, lexical_capture_6, lexical_capture_8, lexical_capture_9, lexical_capture_0, lexical_capture_22}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_240566(lexical_capture_2, lexical_capture_4, lexical_capture_6, lexical_capture_8, lexical_capture_9, lexical_capture_0, lexical_capture_22, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_242754{lexical_capture_1, lexical_capture_23, lexical_capture_25, lexical_capture_10, lexical_capture_11, lexical_capture_6, lexical_capture_8}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_242754(lexical_capture_1, lexical_capture_23, lexical_capture_25, lexical_capture_10, lexical_capture_11, lexical_capture_6, lexical_capture_8, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_244006{lexical_capture_1, lexical_capture_22, lexical_capture_5, lexical_capture_24, lexical_capture_10}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_244006(lexical_capture_1, lexical_capture_22, lexical_capture_5, lexical_capture_24, lexical_capture_10, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_245814{lexical_capture_1, lexical_capture_5, lexical_capture_14, lexical_capture_16}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_245814(lexical_capture_1, lexical_capture_5, lexical_capture_14, lexical_capture_16, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_247124{lexical_capture_3, lexical_capture_4, lexical_capture_6, lexical_capture_7}:
      match value:
        case Value_9{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_247124(lexical_capture_3, lexical_capture_4, lexical_capture_6, lexical_capture_7, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_247617{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5}:
      match value:
        case Value_16{result}:
          feedback_resume_Kont_247617(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_247908{lexical_capture_1, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_3}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_247908(lexical_capture_1, lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_3, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_250740{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6}:
      match value:
        case Value_16{result}:
          feedback_resume_Kont_250740(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_251384{+lexical_capture_3, lexical_capture_30, +lexical_capture_5, lexical_capture_15, lexical_capture_17, lexical_capture_19, lexical_capture_7}:
      match value:
        case Value_9{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_251384(lexical_capture_3, lexical_capture_30, lexical_capture_5, lexical_capture_15, lexical_capture_17, lexical_capture_19, lexical_capture_7, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_257580{+lexical_capture_1, lexical_capture_2, +lexical_capture_18, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_19}:
      match value:
        case Value_9{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_257580(lexical_capture_1, lexical_capture_2, lexical_capture_18, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_19, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_254116{lexical_capture_1, lexical_capture_2, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_39}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_254116(lexical_capture_1, lexical_capture_2, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_39, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_260048{lexical_capture_6, lexical_capture_7, lexical_capture_9, lexical_capture_20, lexical_capture_14, lexical_capture_16, lexical_capture_18, lexical_capture_11}:
      match value:
        case Value_9{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_260048(lexical_capture_6, lexical_capture_7, lexical_capture_9, lexical_capture_20, lexical_capture_14, lexical_capture_16, lexical_capture_18, lexical_capture_11, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_261509{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6}:
      match value:
        case Value_16{result}:
          feedback_resume_Kont_261509(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_262420{lexical_capture_1, lexical_capture_2, lexical_capture_4, lexical_capture_6, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_262420(lexical_capture_1, lexical_capture_2, lexical_capture_4, lexical_capture_6, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_266459{lexical_capture_3, lexical_capture_5, lexical_capture_8, lexical_capture_13, lexical_capture_15, lexical_capture_17, lexical_capture_19}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_266459(lexical_capture_3, lexical_capture_5, lexical_capture_8, lexical_capture_13, lexical_capture_15, lexical_capture_17, lexical_capture_19, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_267754{lexical_capture_3, lexical_capture_4, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_267754(lexical_capture_3, lexical_capture_4, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_268872{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8}:
      match value:
        case Value_16{result}:
          feedback_resume_Kont_268872(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_270151{lexical_capture_17, lexical_capture_3, lexical_capture_4, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15, lexical_capture_6}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_270151(lexical_capture_17, lexical_capture_3, lexical_capture_4, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15, lexical_capture_6, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_272695{lexical_capture_6, lexical_capture_7, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_15, lexical_capture_17, lexical_capture_19}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_272695(lexical_capture_6, lexical_capture_7, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_15, lexical_capture_17, lexical_capture_19, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_273854{capture_0, capture_1, capture_2, capture_4, capture_5, capture_6, capture_7, capture_8}:
      match value:
        case Value_11{result}:
          feedback_resume_Kont_273854(capture_0, capture_1, capture_2, capture_4, capture_5, capture_6, capture_7, capture_8, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_275637{lexical_capture_1, lexical_capture_2, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_275637(lexical_capture_1, lexical_capture_2, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_278142{lexical_capture_3, lexical_capture_5, lexical_capture_8, lexical_capture_13, lexical_capture_15, lexical_capture_17, lexical_capture_19}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_278142(lexical_capture_3, lexical_capture_5, lexical_capture_8, lexical_capture_13, lexical_capture_15, lexical_capture_17, lexical_capture_19, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_286456{lexical_capture_1}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_286456(lexical_capture_1, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_288017{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_288017(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_289909{lexical_capture_3, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_22}:
      match value:
        case Value_2{result_0_0_0, result_0_0_1, result_0_1, result_1}:
          feedback_resume_Kont_289909(lexical_capture_3, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_22, (((result_0_0_0, result_0_0_1), result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_291369{lexical_capture_3, lexical_capture_7, lexical_capture_13, lexical_capture_15, lexical_capture_17}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_291369(lexical_capture_3, lexical_capture_7, lexical_capture_13, lexical_capture_15, lexical_capture_17, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_292028{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_14, lexical_capture_16, lexical_capture_17}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_292028(lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_14, lexical_capture_16, lexical_capture_17, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_293608{lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_19, lexical_capture_11}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_293608(lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_19, lexical_capture_11, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_294231{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_14, lexical_capture_16}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_294231(lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_14, lexical_capture_16, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_296679{lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_12, lexical_capture_14}:
      match value:
        case Value_4{result_0_0, result_0_1, result_1_0_0, result_1_0_1, result_1_1}:
          feedback_resume_Kont_296679(lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_12, lexical_capture_14, ((result_0_0, result_0_1), ((result_1_0_0, result_1_0_1), result_1_1)))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_297498{lexical_capture_4, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15, lexical_capture_17, lexical_capture_20, lexical_capture_22}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_297498(lexical_capture_4, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15, lexical_capture_17, lexical_capture_20, lexical_capture_22, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_298751{lexical_capture_2, lexical_capture_5, lexical_capture_12, lexical_capture_14}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_298751(lexical_capture_2, lexical_capture_5, lexical_capture_12, lexical_capture_14, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_299333{lexical_capture_1, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_12}:
      match value:
        case Value_9{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_299333(lexical_capture_1, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_12, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_299821{lexical_capture_1, lexical_capture_13, lexical_capture_3, lexical_capture_5}:
      match value:
        case Value_9{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_299821(lexical_capture_1, lexical_capture_13, lexical_capture_3, lexical_capture_5, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_302984{lexical_capture_1, lexical_capture_6, lexical_capture_8, lexical_capture_10}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_302984(lexical_capture_1, lexical_capture_6, lexical_capture_8, lexical_capture_10, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_303571{lexical_capture_3, lexical_capture_5, lexical_capture_9, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_18}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_303571(lexical_capture_3, lexical_capture_5, lexical_capture_9, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_18, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_306612{capture_1, capture_2, capture_3, capture_4}:
      match value:
        case Value_18{result}:
          feedback_resume_Kont_306612(capture_1, capture_2, capture_3, capture_4, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_307637{lexical_capture_5, lexical_capture_3, lexical_capture_15}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_307637(lexical_capture_5, lexical_capture_3, lexical_capture_15, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_312883{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8}:
      match value:
        case Value_16{result}:
          feedback_resume_Kont_312883(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_313531{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_313531(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_316332{capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9}:
      match value:
        case Value_16{result}:
          feedback_resume_Kont_316332(capture_0, capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, capture_9, result)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_316984{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_316984(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, capture_8, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_318578{}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_318578(((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_320249{lexical_capture_0, lexical_capture_2, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_5}:
      match value:
        case Value_3{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_320249(lexical_capture_0, lexical_capture_2, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_5, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_321678{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_321678(capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_322047{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_13, lexical_capture_15}:
      match value:
        case Value_3{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_322047(lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_13, lexical_capture_15, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_325042{lexical_capture_1, lexical_capture_3, lexical_capture_5}:
      match value:
        case Value_1{result_0_0_0_0, result_0_0_0_1, result_0_0_1, result_0_1, result_1}:
          feedback_resume_Kont_325042(lexical_capture_1, lexical_capture_3, lexical_capture_5, ((((result_0_0_0_0, result_0_0_0_1), result_0_0_1), result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_330347{}:
      match value:
        case Value_6{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_330347(((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_330212{}:
      match value:
        case Value_6{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_330212(((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_332964{lexical_capture_3, lexical_capture_26, lexical_capture_27, lexical_capture_9, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_18, lexical_capture_20}:
      match value:
        case Value_1{result_0_0_0_0, result_0_0_0_1, result_0_0_1, result_0_1, result_1}:
          feedback_resume_Kont_332964(lexical_capture_3, lexical_capture_26, lexical_capture_27, lexical_capture_9, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_18, lexical_capture_20, ((((result_0_0_0_0, result_0_0_0_1), result_0_0_1), result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_335020{lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_14, lexical_capture_2}:
      match value:
        case Value_7{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_335020(lexical_capture_6, lexical_capture_8, lexical_capture_10, lexical_capture_14, lexical_capture_2, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_335852{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_16, lexical_capture_18}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_335852(lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_16, lexical_capture_18, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_337919{lexical_capture_26, lexical_capture_1, lexical_capture_19, lexical_capture_5, lexical_capture_7}:
      match value:
        case Value_1{result_0_0_0_0, result_0_0_0_1, result_0_0_1, result_0_1, result_1}:
          feedback_resume_Kont_337919(lexical_capture_26, lexical_capture_1, lexical_capture_19, lexical_capture_5, lexical_capture_7, ((((result_0_0_0_0, result_0_0_0_1), result_0_0_1), result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_337453{lexical_capture_26, lexical_capture_1, lexical_capture_19, lexical_capture_5, lexical_capture_7}:
      match value:
        case Value_1{result_0_0_0_0, result_0_0_0_1, result_0_0_1, result_0_1, result_1}:
          feedback_resume_Kont_337453(lexical_capture_26, lexical_capture_1, lexical_capture_19, lexical_capture_5, lexical_capture_7, ((((result_0_0_0_0, result_0_0_0_1), result_0_0_1), result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_339950{lexical_capture_12, lexical_capture_14, lexical_capture_3, lexical_capture_16, lexical_capture_17, lexical_capture_5}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_339950(lexical_capture_12, lexical_capture_14, lexical_capture_3, lexical_capture_16, lexical_capture_17, lexical_capture_5, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_343898{lexical_capture_1, lexical_capture_31, lexical_capture_32, lexical_capture_33, lexical_capture_5, lexical_capture_7, lexical_capture_8, lexical_capture_11, lexical_capture_13, lexical_capture_15}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_343898(lexical_capture_1, lexical_capture_31, lexical_capture_32, lexical_capture_33, lexical_capture_5, lexical_capture_7, lexical_capture_8, lexical_capture_11, lexical_capture_13, lexical_capture_15, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_345864{lexical_capture_1, lexical_capture_7, lexical_capture_9, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_17, lexical_capture_20, lexical_capture_22, lexical_capture_24}:
      match value:
        case Value_5{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_345864(lexical_capture_1, lexical_capture_7, lexical_capture_9, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_17, lexical_capture_20, lexical_capture_22, lexical_capture_24, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_348170{lexical_capture_1, lexical_capture_17, lexical_capture_5, lexical_capture_24, lexical_capture_25}:
      match value:
        case Value_0{result_0_0_0_0, result_0_0_0_1, result_0_0_1, result_0_1, result_1}:
          feedback_resume_Kont_348170(lexical_capture_1, lexical_capture_17, lexical_capture_5, lexical_capture_24, lexical_capture_25, ((((result_0_0_0_0, result_0_0_0_1), result_0_0_1), result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_353656{lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9}:
      match value:
        case Value_6{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_353656(lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_353365{lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9}:
      match value:
        case Value_6{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_353365(lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_353072{lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9}:
      match value:
        case Value_6{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_353072(lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_352782{lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9}:
      match value:
        case Value_6{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_352782(lexical_capture_12, lexical_capture_19, lexical_capture_3, lexical_capture_1, lexical_capture_7, lexical_capture_9, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_355557{lexical_capture_7, lexical_capture_3}:
      match value:
        case Value_10{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_355557(lexical_capture_7, lexical_capture_3, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}
    case Kont_356010{lexical_capture_3}:
      match value:
        case Value_8{result_0_0, result_0_1, result_1}:
          feedback_resume_Kont_356010(lexical_capture_3, ((result_0_0, result_0_1), result_1))
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_resume(saved: FeedbackKont, value: FeedbackValue, child_progress: Progress) -> FeedbackResume:
  match saved:
    case FeedbackKont{frame, progress}:
      feedback_pack_resume(feedback_compose_progress(progress, child_progress), feedback_resume_frame(frame, value))

def feedback_use_resume(resumed: FeedbackResume, use: FeedbackControl -> FeedbackRun) -> FeedbackRun:
  match resumed:
    case FeedbackResume{control, _, _}:
      use(control)

def feedback_drive(fuel: FeedbackFuel, step: FeedbackControl, stack: List<&2, FeedbackKont>) -> FeedbackRun:
  match fuel:
    case FeedbackFuelEnd{}: feedback_finish(step, stack)
    case FeedbackFuelCell{remaining}:
      match step:
        case FeedbackControl{action, pending, progress, _}:
          match action:
            case FeedbackInvariant{}:
              feedback_failure(progress, pending, stack)
            case FeedbackCall{request}:
              feedback_drive(remaining, feedback_dispatch(request), List.append(&2, FeedbackKont, feedback_save_progress(progress, pending), stack))
            case FeedbackDone{value}:
              match pending:
                case frame <> tail:
                  feedback_use_resume(feedback_resume(frame, value, progress), control => feedback_drive(remaining, control, List.append(&2, FeedbackKont, tail, stack)))
                case Nil{}:
                  match stack:
                    case frame <> tail:
                      feedback_use_resume(feedback_resume(frame, value, progress), control => feedback_drive(remaining, control, tail))
                    case Nil{}: FeedbackComplete{value, progress}

def merge_symbol_pair_result(result: SymbolPairClass, beg: Nat, end: Nat, line: Nat, col: Nat, middle_end: Nat) -> SymbolCombineMode:
  match result:
    case SymbolPairMerged{pair}:
      SymbolCombineMerged{Lexer.TokenInfo{Lexer.SymbolToken{}, pair, beg, middle_end, line, col}, 1n}
    case SymbolPairUnmerged{left}:
      SymbolCombineUnmerged{Lexer.TokenInfo{Lexer.SymbolToken{}, left, beg, end, line, col}}

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

def combine_symbols_acc(tokens: List<&2, Lexer.Token>, mode: SymbolCombineMode, reversed: List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:
  match tokens mode:
    case +token <> +rest SymbolCombineScan{}:
      combine_symbols_acc(rest, scan_symbol_mode(token, rest), reversed)
    case Nil{} SymbolCombineScan{}:
      List.reverse(&2, Lexer.Token, reversed)
    case +_ <> rest SymbolCombineMerged{merged, 1n}:
      combine_symbols_acc(rest, SymbolCombineScan{}, merged <> reversed)
    case +_ <> rest SymbolCombineMerged{merged, 2n}:
      combine_symbols_acc(rest, SymbolCombineSkip{merged}, reversed)
    case +_ <> rest SymbolCombineMerged{merged, _}:
      combine_symbols_acc(rest, SymbolCombineScan{}, merged <> reversed)
    case Nil{} SymbolCombineMerged{merged, _}:
      List.reverse(&2, Lexer.Token, merged <> reversed)
    case +next <> +rest SymbolCombineUnmerged{token}:
      combine_symbols_acc(rest, scan_symbol_mode(next, rest), token <> reversed)
    case Nil{} SymbolCombineUnmerged{token}:
      List.reverse(&2, Lexer.Token, token <> reversed)
    case +_ <> rest SymbolCombineSkip{merged}:
      combine_symbols_acc(rest, SymbolCombineScan{}, merged <> reversed)
    case Nil{} SymbolCombineSkip{merged}:
      List.reverse(&2, Lexer.Token, merged <> reversed)

def combine_symbols(tokens: List<&2, Lexer.Token>, mode: SymbolCombineMode) -> List<&2, Lexer.Token>:
  combine_symbols_acc(tokens, mode, Nil{})

# The reversed prefix bounds native and emitted-JS stacks independently of the
# token count. Scanning and merged-token spans retain their original order.

def feedback_make_Kont_356010(lexical_capture_3: String) -> FeedbackFrame:
  Kont_356010{lexical_capture_3}

def step_parse_imports(file: String, +tokens: List<&2, Lexer.Token>, acc: List<&2, Ast.ModuleImport>) -> FeedbackControl:
  step_parse_imports_scan(file, tokens, skip_lines(tokens), acc)

def step_parse_module_tokens(+tokens: List<&2, Lexer.Token>, +file: String) -> FeedbackControl:
  match tokens:
    case +_ <> _:
      feedback_attach(step_parse_imports(file, tokens, Nil{}), feedback_make_Kont_356010(file))
    case Nil{}:
      feedback_pack_17(ParseFailure{ "empty lexer output", "a source token", "end of input", span(file, 0n, 0n)})

def step_parse(file: String, source: String) -> FeedbackControl:
  step_parse_module_tokens(combine_symbols(Lexer.tokens(source), SymbolCombineScan{}), file)

def parse_with_fuel(fuel: FeedbackFuel, file: String, source: String) -> FeedbackRun:
  feedback_drive(fuel, step_parse(file, source), Nil{})

# Bend owns parsing, expansion, checking and emission; Node drives typed steps.
def parsed_module(namespace: String, module: Ast.Module) -> Loader.LoadedModule:
  Loader.LoadedModule{namespace, module}

def expand_modules_start(modules: List<&2, Loader.LoadedModule>) -> Template.TemplateRun<Template.ExpandResult>:
  Template.template_start(modules)

def template_step(-R: Type, run: Template.TemplateRun<R>) -> Template.TemplateRun<R>:
  Template.template_step(R, run)

def check_expanded_start(modules: List<&2, Loader.LoadedModule>) -> CheckerCore.CheckerRun<Checked.CheckResult>:
  CheckerCore.checker_start(modules)

def inspect_checked_start(program: Checked.CheckedProgram) -> CheckerCore.CheckerRun<Checked.Inspection>:
  CheckerCore.checker_inspect_start(program)

def checker_step(-R: Type, run: CheckerCore.CheckerRun<R>) -> CheckerCore.CheckerRun<R>:
  CheckerCore.checker_step(R, run)

def emit_modules_start(program: Checked.CheckedProgram, files: List<&2, BIR.SourceFile>) -> JSEmit.EmitterRun<JSEmit.EmitResult>:
  JSEmit.emitter_start(program, files)

def emit_library_start(program: Checked.CheckedProgram, exports: List<&2, String>, files: List<&2, BIR.SourceFile>) -> JSEmit.EmitterRun<JSEmit.EmitResult>:
  JSEmit.emitter_library_start(program, exports, files)

def emitter_step(-R: Type, run: JSEmit.EmitterRun<R>) -> JSEmit.EmitterRun<R>:
  JSEmit.emitter_step(R, run)

def emit_c_modules_start(program: Checked.CheckedProgram, runtime: String, files: List<&2, BIR.SourceFile>) -> CEmit.CEmitterRun<CEmit.EmitResult>:
  CEmit.cemit_start(program, runtime, files)

def emit_c_library_start(program: Checked.CheckedProgram, exports: List<&2, String>, runtime: String, files: List<&2, BIR.SourceFile>) -> CEmit.CEmitterRun<CEmit.EmitResult>:
  CEmit.cemit_library_start(program, exports, runtime, files)

def c_emitter_step(-R: Type, run: CEmit.CEmitterRun<R>) -> CEmit.CEmitterRun<R>:
  CEmit.cemit_step(R, run)
