# EXPERIMENTAL / FUEL-PARAMETRIC / NOT SELFHOST GREEN

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

type DefinitionHeaderAction is Data:
  DefinitionHeaderRow0{}
  DefinitionHeaderRow1{}
  DefinitionHeaderRow2{}

type FeedbackValue is Data:
  Value_0{result_0_0_0_0: List<&2, Ast.Clause>, result_0_0_0_1: List<&2, Lexer.Token>, result_0_0_1: List<&2, Scope>, result_0_1: Nat, result_1: Bool}
  Value_1{result_0_0_0_0: List<&2, Ast.TelescopeItem>, result_0_0_0_1: List<&2, Lexer.Token>, result_0_0_1: List<&2, Scope>, result_0_1: Nat, result_1: Bool}
  Value_2{result_0_0_0: List<&2, Ast.SyntaxTerm>, result_0_0_1: List<&2, Lexer.Token>, result_0_1: Nat, result_1: Bool}
  Value_3{result_0_0: Ast.DefBody, result_0_1: List<&2, Lexer.Token>, result_1: Bool}
  Value_4{result_0_0: Ast.SyntaxTerm, result_0_1: List<&2, Lexer.Token>, result_1: Bool}
  Value_5{result_0_0: Ast.TopLevel, result_0_1: List<&2, Lexer.Token>, result_1: Bool}
  Value_6{result_0_0: List<&2, Ast.ConstructorDecl>, result_0_1: List<&2, Lexer.Token>, result_1: Bool}
  Value_7{result_0_0: List<&2, Ast.ModuleImport>, result_0_1: List<&2, Lexer.Token>, result_1: Bool}
  Value_8{result_0_0: List<&2, Ast.SyntaxTerm>, result_0_1: List<&2, Lexer.Token>, result_1: Bool}
  Value_9{result_0_0: List<&2, Ast.TopLevel>, result_0_1: Bool, result_1: List<&2, Lexer.Token>}
  Value_10{result: ParseResult}

type Progress is Data:
  NoProgress{}
  Consumed{}

type FeedbackCursorWitness is Data:
  WitnessNone{}
  WitnessTail{progress: Progress}
  WitnessFields{fields: List<&2, FeedbackCursorWitness>}

type FeedbackFrame is Data:
  KontProgress{}
  Kont_145241{capture_1: String, capture_2: String, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Lexer.Token>, capture_6: List<&2, Scope>, capture_7: Nat}
  Kont_146857{capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Lexer.Token>}
  Kont_152951{capture_1: String, capture_2: Nat}
  Kont_153463{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Nat, capture_5: Nat}
  Kont_154790{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: Nat, capture_8: Nat, capture_9: List<&2, Scope>, capture_10: Nat, capture_11: Nat}
  Kont_157864{lexical_capture_4: String, lexical_capture_6: String, lexical_capture_8: List<&2, Ast.SyntaxTerm>, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_13: Ast.SyntaxTerm, lexical_capture_29: Ast.SyntaxTerm, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_22: Nat}
  Kont_158787{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Nat, capture_7: Nat, capture_8: List<&2, Scope>, capture_9: Nat, capture_10: Nat}
  Kont_159799{lexical_capture_4: String, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_22: Nat, lexical_capture_13: Ast.SyntaxTerm, lexical_capture_29: Ast.SyntaxTerm}
  Kont_160442{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: Nat, capture_8: Nat, capture_9: List<&2, Scope>, capture_10: Nat, capture_11: Nat}
  Kont_162507{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Ast.SyntaxTerm, capture_5: Nat, capture_6: Nat, capture_7: List<&2, Scope>, capture_8: Nat, capture_9: Nat}
  Kont_163045{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Nat, capture_5: Nat, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: Nat}
  Kont_164377{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: List<&2, Ast.SyntaxTerm>, lexical_capture_6: Ast.SyntaxTerm, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_18: Nat}
  Kont_168080{capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: Nat}
  Kont_168734{capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Scope>, capture_5: Nat}
  Kont_169919{lexical_capture_4: String, lexical_capture_5: Ast.SyntaxTerm, lexical_capture_7: Nat}
  Kont_170611{capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Scope>, capture_6: Nat}
  Kont_171336{capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Ast.SyntaxTerm, capture_4: Nat, capture_5: Nat}
  Kont_171673{capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Ast.SyntaxTerm, capture_4: Nat, capture_5: Nat}
  Kont_174230{capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Lexer.Token>, capture_5: Nat, capture_6: List<&2, Scope>, capture_7: Nat}
  Kont_175466{capture_1: String, capture_2: List<&2, Lexer.Token>, capture_3: Nat, capture_4: List<&2, Scope>, capture_5: Nat}
  Kont_175889{capture_1: String, capture_2: Ast.SyntaxTerm}
  Kont_176790{capture_1: String, capture_2: List<&2, Scope>, capture_3: Nat}
  Kont_179656{capture_1: String, capture_2: String, capture_3: Nat, capture_4: List<&2, Scope>, capture_5: Nat}
  Kont_183283{lexical_capture_98: String, lexical_capture_99: String, lexical_capture_100: Ast.SyntaxTerm, lexical_capture_107: Nat}
  Kont_182957{lexical_capture_98: String, lexical_capture_99: String, lexical_capture_100: Ast.SyntaxTerm, lexical_capture_107: Nat}
  Kont_182617{lexical_capture_98: String, lexical_capture_99: String, lexical_capture_100: Ast.SyntaxTerm, lexical_capture_107: Nat}
  Kont_181786{lexical_capture_49: String, lexical_capture_50: String, lexical_capture_51: Ast.SyntaxTerm, lexical_capture_52: List<&2, Lexer.Token>, lexical_capture_53: String, lexical_capture_55: Nat, lexical_capture_56: List<&2, Scope>, lexical_capture_57: Nat}
  Kont_184477{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_8: Nat}
  Kont_184830{lexical_capture_1: String}
  Kont_185217{lexical_capture_2: String, lexical_capture_3: Ast.SyntaxTerm, lexical_capture_0: Ast.SyntaxTerm, lexical_capture_5: Nat}
  Kont_187819{lexical_capture_4: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: Nat, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat}
  Kont_188226{lexical_capture_4: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: Nat}
  Kont_191018{lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_10: List<&2, Scope>, lexical_capture_12: Nat}
  Kont_191542{lexical_capture_2: String, lexical_capture_3: Ast.SyntaxTerm, lexical_capture_0: Ast.SyntaxTerm, lexical_capture_5: Nat, lexical_capture_10: Nat}
  Kont_193344{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: Nat, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat}
  Kont_194280{lexical_capture_6: String, lexical_capture_21: String, lexical_capture_8: Nat, lexical_capture_10: Nat, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat}
  Kont_195883{lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_10: List<&2, Scope>, lexical_capture_12: Nat}
  Kont_196671{lexical_capture_7: Ast.SyntaxTerm, lexical_capture_26: Ast.SyntaxTerm, lexical_capture_6: String, lexical_capture_11: Nat}
  Kont_197246{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_4: String, lexical_capture_6: Nat, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat}
  Kont_199474{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat}
  Kont_199246{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_14: Nat}
  Kont_201519{lexical_capture_3: String, lexical_capture_8: List<&2, Lexer.Token>, lexical_capture_10: String, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: List<&2, Ast.SyntaxTerm>}
  Kont_203154{lexical_capture_2: String, lexical_capture_4: String, lexical_capture_6: Nat, lexical_capture_8: Nat, lexical_capture_9: Ast.Quantity, lexical_capture_0: Ast.SyntaxTerm, lexical_capture_22: Nat}
  Kont_205334{lexical_capture_1: String, lexical_capture_23: String, lexical_capture_25: Nat, lexical_capture_10: Nat, lexical_capture_11: Ast.Quantity, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat}
  Kont_206586{lexical_capture_1: String, lexical_capture_22: String, lexical_capture_5: Nat, lexical_capture_24: Nat, lexical_capture_10: Nat}
  Kont_208382{lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat}
  Kont_209692{lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_6: Nat, lexical_capture_7: Lexer.Token}
  Kont_210378{lexical_capture_1: String, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat, lexical_capture_10: Nat}
  Kont_214432{lexical_capture_3: String, lexical_capture_30: Ast.SyntaxTerm, lexical_capture_5: Lexer.Token, lexical_capture_15: List<&2, Scope>, lexical_capture_17: Nat, lexical_capture_19: Nat}
  Kont_219431{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_16: Lexer.Token, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: Nat}
  Kont_215995{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: Nat, lexical_capture_35: Nat}
  Kont_221893{lexical_capture_6: String, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_9: Lexer.Token, lexical_capture_20: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, lexical_capture_18: Nat}
  Kont_223912{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_4: List<&2, Lexer.Token>, lexical_capture_6: List<&2, Lexer.Token>, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat}
  Kont_227499{lexical_capture_3: String, lexical_capture_5: String, lexical_capture_8: Ast.SyntaxTerm, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_19: Nat}
  Kont_228794{lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat}
  Kont_230439{lexical_capture_15: Bool, lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_4: List<&2, Lexer.Token>}
  Kont_232954{lexical_capture_6: String, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_8: Ast.SyntaxTerm, lexical_capture_10: Nat, lexical_capture_12: Nat, lexical_capture_15: List<&2, Scope>, lexical_capture_17: Nat, lexical_capture_19: Nat}
  Kont_235896{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat}
  Kont_238315{lexical_capture_3: String, lexical_capture_5: String, lexical_capture_8: Ast.SyntaxTerm, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_19: Nat}
  Kont_245664{lexical_capture_1: String}
  Kont_248751{capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: Nat, capture_6: List<&2, Ast.SyntaxTerm>}
  Kont_249734{lexical_capture_3: List<&2, Ast.SyntaxPattern>, lexical_capture_5: List<&2, Lexer.Token>, lexical_capture_8: List<&2, Scope>, lexical_capture_10: Nat, lexical_capture_12: String, lexical_capture_14: Nat, lexical_capture_16: Nat, lexical_capture_19: List<&2, Scope>, lexical_capture_21: Nat, lexical_capture_22: Ast.Quantity}
  Kont_252124{lexical_capture_3: List<&2, Ast.SyntaxTerm>, lexical_capture_7: List<&2, Ast.SyntaxPattern>, lexical_capture_13: Ast.Quantity, lexical_capture_15: String, lexical_capture_17: Nat}
  Kont_252783{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, lexical_capture_17: Ast.Quantity}
  Kont_254363{lexical_capture_3: String, lexical_capture_5: String, lexical_capture_7: Nat, lexical_capture_10: Ast.SyntaxPattern, lexical_capture_19: Ast.Quantity, lexical_capture_11: Ast.SyntaxTerm}
  Kont_254978{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat}
  Kont_256139{lexical_capture_4: Ast.SyntaxPattern, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: String, lexical_capture_13: List<&2, Lexer.Token>, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_20: List<&2, Scope>, lexical_capture_22: Nat}
  Kont_257392{lexical_capture_2: Ast.SyntaxTerm, lexical_capture_5: Ast.SyntaxPattern, lexical_capture_12: String, lexical_capture_14: Nat}
  Kont_257974{lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_10: List<&2, Scope>, lexical_capture_12: Nat}
  Kont_258462{lexical_capture_1: List<&2, Ast.SyntaxTerm>, lexical_capture_13: Lexer.Token, lexical_capture_3: String, lexical_capture_5: Nat}
  Kont_261627{lexical_capture_1: String, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat, lexical_capture_10: List<&2, Ast.SyntaxTerm>}
  Kont_262214{lexical_capture_3: String, lexical_capture_5: List<&2, Lexer.Token>, lexical_capture_9: Nat, lexical_capture_12: List<&2, Scope>, lexical_capture_14: Nat, lexical_capture_16: Nat, lexical_capture_18: List<&2, Ast.SyntaxTerm>}
  Kont_266519{lexical_capture_5: List<&2, Ast.SyntaxPattern>, lexical_capture_3: String, lexical_capture_15: Nat}
  Kont_271890{capture_1: String, capture_2: List<&2, Ast.TelescopeItem>, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: String, capture_6: Nat}
  Kont_274802{capture_1: String, capture_2: String, capture_3: Ast.Quantity, capture_4: Nat, capture_5: List<&2, Ast.TelescopeItem>, capture_6: List<&2, Scope>, capture_7: Nat}
  Kont_276375{}
  Kont_278046{lexical_capture_0: Lexer.Token, lexical_capture_2: List<&2, Lexer.Token>, lexical_capture_8: String, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_14: List<&2, Ast.TelescopeItem>, lexical_capture_5: Ast.SyntaxTerm}
  Kont_279475{capture_1: Lexer.Token, capture_2: String, capture_3: String, capture_4: Nat, capture_5: List<&2, Ast.TelescopeItem>, capture_6: List<&2, Scope>, capture_7: Nat}
  Kont_279844{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: List<&2, Ast.TelescopeItem>, lexical_capture_13: Lexer.Token, lexical_capture_15: List<&2, Lexer.Token>}
  Kont_282839{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat}
  Kont_288234{}
  Kont_290824{lexical_capture_3: String, lexical_capture_26: Lexer.Token, lexical_capture_27: List<&2, Lexer.Token>, lexical_capture_9: Nat, lexical_capture_12: List<&2, Scope>, lexical_capture_14: Nat, lexical_capture_16: List<&2, Ast.ConstructorDecl>, lexical_capture_18: String, lexical_capture_20: Nat}
  Kont_292880{lexical_capture_6: String, lexical_capture_8: String, lexical_capture_10: Nat, lexical_capture_14: List<&2, Ast.TelescopeItem>, lexical_capture_2: Ast.SyntaxTerm}
  Kont_293712{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: List<&2, Ast.TelescopeItem>, lexical_capture_11: List<&2, Lexer.Token>, lexical_capture_16: List<&2, Scope>, lexical_capture_18: Nat}
  Kont_295313{lexical_capture_26: Lexer.Token, lexical_capture_1: String, lexical_capture_19: String, lexical_capture_5: Nat, lexical_capture_7: Nat}
  Kont_297334{lexical_capture_12: String, lexical_capture_14: String, lexical_capture_3: List<&2, Ast.Clause>, lexical_capture_16: Nat, lexical_capture_17: Lexer.Token, lexical_capture_5: List<&2, Lexer.Token>}
  Kont_301274{lexical_capture_1: String, lexical_capture_31: String, lexical_capture_32: Nat, lexical_capture_33: Nat, lexical_capture_5: Nat, lexical_capture_7: Bool, lexical_capture_8: Ast.Quantity, lexical_capture_11: List<&2, Scope>, lexical_capture_13: Nat, lexical_capture_15: List<&2, Ast.Clause>}
  Kont_303240{lexical_capture_1: String, lexical_capture_7: Nat, lexical_capture_9: Bool, lexical_capture_10: Ast.Quantity, lexical_capture_12: String, lexical_capture_14: Nat, lexical_capture_17: Ast.SyntaxTerm, lexical_capture_20: List<&2, Scope>, lexical_capture_22: Nat, lexical_capture_24: List<&2, Ast.Clause>}
  Kont_305546{lexical_capture_1: String, lexical_capture_17: String, lexical_capture_5: Nat, lexical_capture_24: Lexer.Token, lexical_capture_25: List<&2, Lexer.Token>}
  Kont_310952{lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>}
  Kont_310661{lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>}
  Kont_310368{lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>}
  Kont_310078{lexical_capture_12: Map<&2, TopOwner>, lexical_capture_19: List<&2, Lexer.Token>, lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>}
  Kont_312853{lexical_capture_7: String, lexical_capture_3: List<&2, Ast.ModuleImport>}
  Kont_313306{lexical_capture_3: String}

type FeedbackKont is Data:
  FeedbackKont{frame: FeedbackFrame, progress: Progress}

type FeedbackRequest is Data:
  Request_parse_atom_scan{file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat}
  Request_parse_body_scan{file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, parent_col: Nat}
  Request_parse_case_row_indented{is_indented: Bool, file: String, tokens: List<&2, Lexer.Token>, rest: List<&2, Lexer.Token>, parent_col: Nat, scope: List<&2, Scope>, depth: Nat, arity: Nat, acc: List<&2, Ast.SyntaxTerm>, beg: Nat, col: Nat}
  Request_parse_def_binders_scan{file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.TelescopeItem>}
  Request_parse_do_typed_bind{file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat}
  Request_parse_imports_result{ok: Bool, item: Ast.ModuleImport, after: List<&2, Lexer.Token>, file: String, acc: List<&2, Ast.ModuleImport>}
  Request_parse_law_clause_condition_scan{file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, beg: Nat, universal: Bool, quantity: Ast.Quantity, key: String, key_beg: Nat, key_end: Nat, ty: Ast.SyntaxTerm, next_scope: List<&2, Scope>, next_depth: Nat, acc: List<&2, Ast.Clause>}
  Request_parse_local_values_next{next: Lexer.Token, after_next: List<&2, Lexer.Token>, value: Ast.SyntaxTerm, file: String, scope: List<&2, Scope>, depth: Nat, line: Nat, acc: List<&2, Ast.SyntaxTerm>}
  Request_parse_match_chain_state{state: MatchChainState}
  Request_parse_term_args_first_result{ok: Bool, term: Ast.SyntaxTerm, after: List<&2, Lexer.Token>, file: String, tokens: List<&2, Lexer.Token>, close: String, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.SyntaxTerm>}
  Request_parse_term_tail{file: String, left: Ast.SyntaxTerm, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, level: Nat}
  Request_parse_terms_until_colon_result{ok: Bool, term: Ast.SyntaxTerm, after: List<&2, Lexer.Token>, file: String, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.SyntaxTerm>}
  Request_parse_top_result{validation_0: Map<&2, TopOwner>, validation_1: Bool, top: Ast.TopLevel, after: List<&2, Lexer.Token>, tokens: List<&2, Lexer.Token>, file: String, path: String, acc: List<&2, Ast.TopLevel>}
  Request_parse_type_constructor_fields_result{ok_fields: Bool, fields: List<&2, Ast.TelescopeItem>, after_fields: List<&2, Lexer.Token>, file: String, open: Lexer.Token, after_open: List<&2, Lexer.Token>, col: Nat, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.ConstructorDecl>, key: String, beg: Nat}

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

def feedback_pack_4(result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  match result:
    case ((result_0_0, result_0_1), result_1):
      FeedbackControl{FeedbackDone{Value_4{result_0_0, result_0_1, result_1}}, Nil{}, NoProgress{}, NoProgress{}}

def span(file: String, beg: Nat, end: Nat) -> Ast.SourceSpan:
  Ast.SpanOf{file, beg, end}

def u32_bit(file: String, bit_value: Nat, beg: Nat, end: Nat) -> Ast.SyntaxTerm:
  match bit_value:
    case 0n: Ast.TermCtr{ "False",  Nil{},  span(file, beg, end)}
    case _: Ast.TermCtr{ "True",  Nil{},  span(file, beg, end)}

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

def string_chars_cons_result(result: Ast.SyntaxTerm & Bool, chr: Ast.SyntaxTerm, file: String, beg: Nat, end: Nat) -> Ast.SyntaxTerm & Bool:
  match result:
    case (next, ok):
      (Ast.TermCtr{"SCon", [chr, next], span(file, beg, end)}, ok)

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

def parse_string(file: String, text: String, beg: Nat, end: Nat, rest: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  parse_string_result(string_chars(file, String.to_list(strip_quotes(text)), beg, end), rest)

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

def feedback_make_Kont_146857(capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Lexer.Token>) -> FeedbackFrame:
  Kont_146857{capture_1, capture_2, capture_3, capture_4}

def feedback_make_Kont_145241(capture_1: String, capture_2: String, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Lexer.Token>, capture_6: List<&2, Scope>, capture_7: Nat) -> FeedbackFrame:
  Kont_145241{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7}

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

def feedback_make_Kont_153463(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Nat, capture_5: Nat) -> FeedbackFrame:
  Kont_153463{capture_1, capture_2, capture_3, capture_4, capture_5}

def feedback_make_parse_do_typed_bind(file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> FeedbackRequest:
  Request_parse_do_typed_bind{file, monad, args, tokens, beg, end, scope, depth, col}

def feedback_make_Kont_210378(lexical_capture_1: String, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat, lexical_capture_10: Nat) -> FeedbackFrame:
  Kont_210378{lexical_capture_1, lexical_capture_6, lexical_capture_8, lexical_capture_10}

def feedback_make_parse_atom_scan(file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackRequest:
  Request_parse_atom_scan{file, tokens, scanned, scope, depth}

def step_parse_atom(file: String, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  FeedbackControl{FeedbackCall{feedback_make_parse_atom_scan(file, tokens, skip_lines(tokens), scope, depth)}, Nil{}, NoProgress{}, NoProgress{}}

def step_parse_term(+file: String, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, level: Nat) -> FeedbackControl:
  feedback_attach(step_parse_atom(file, tokens, scope, depth), feedback_make_Kont_210378(file, scope, depth, level))

def step_parse_do_return_scan(+file: String, +key: String, +args: List<&2, Ast.SyntaxTerm>, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +beg: Nat, +end: Nat, +scope: List<&2, Scope>, +depth: Nat, col: Nat) -> FeedbackControl:
  match scanned:
    case +return_token <> +rest:
      match return_token:
        case Lexer.TokenInfo{Lexer.NameToken{}, "return", _, _, _, _}:
          feedback_attach(step_parse_term(file, rest, scope, depth, 0n), feedback_make_Kont_153463(file, key, args, beg, end))
        case Lexer.TokenInfo{feedback_field_6_0, feedback_field_6_1, feedback_field_6_2, feedback_field_6_3, feedback_field_6_4, feedback_field_6_5}:
          FeedbackControl{FeedbackCall{feedback_make_parse_do_typed_bind(file, key, args, (Lexer.TokenInfo{feedback_field_6_0, feedback_field_6_1, feedback_field_6_2, feedback_field_6_3, feedback_field_6_4, feedback_field_6_5} : Lexer.Token) <> rest, beg, end, scope, depth, col)}, Nil{}, NoProgress{}, NoProgress{}}
    case Nil{}:
      feedback_pack_4(((Ast.TermHole{"parse-error: expected return in do block", span(file, beg, end)}, Nil{}), False{}))

def step_parse_do_return(file: String, key: String, args: List<&2, Ast.SyntaxTerm>, +tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> FeedbackControl:
  step_parse_do_return_scan(file, key, args, tokens, skip_lines(tokens), beg, end, scope, depth, col)

def token_beg(token: Lexer.Token) -> Nat:
  match token:
    case Lexer.TokenInfo{ _,  _, beg,  _,  _,  _}:
      beg

def token_end(token: Lexer.Token) -> Nat:
  match token:
    case Lexer.TokenInfo{ _,  _,  _, end,  _,  _}:
      end

def step_parse_do_atom_colon(+colon: Lexer.Token, +after_colon: List<&2, Lexer.Token>, args: List<&2, Ast.SyntaxTerm>, +file: String, key: String, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match colon:
    case Lexer.TokenInfo{_, ":", +_, +_, +_, +_}:
      step_parse_do_return(file, key, args, after_colon, beg, end, scope, depth, do_first_col(after_colon))
    case Lexer.TokenInfo{+feedback_field_4_0, +feedback_field_4_1, +feedback_field_4_2, +feedback_field_4_3, +feedback_field_4_4, +feedback_field_4_5}:
      feedback_pack_4(((Ast.TermHole{"parse-error: expected : after do parameters", span(file, token_beg((Lexer.TokenInfo{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4, feedback_field_4_5} : Lexer.Token)), token_end((Lexer.TokenInfo{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4, feedback_field_4_5} : Lexer.Token)))}, (Lexer.TokenInfo{feedback_field_4_0, feedback_field_4_1, feedback_field_4_2, feedback_field_4_3, feedback_field_4_4, feedback_field_4_5} : Lexer.Token) <> after_colon), False{}))

def step_parse_do_atom_args_result(result: (List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool, +file: String, key: String, beg: Nat, +end: Nat, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  match result:
    case ((args, +colon <> after_colon), True{}):
      step_parse_do_atom_colon(colon, after_colon, args, file, key, beg, end, scope, depth)
    case ((_, after_args), False{}):
      feedback_pack_4(((Ast.TermHole{"parse-error: expected do parameters", span(file, end, end)}, after_args), False{}))
    case _:
      feedback_pack_4(((Ast.TermHole{"parse-error: expected do parameters", span(file, end, end)}, tokens), False{}))

def feedback_pack_8(result: ((List<&2, Ast.SyntaxTerm> & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  match result:
    case ((result_0_0, result_0_1), result_1):
      FeedbackControl{FeedbackDone{Value_8{result_0_0, result_0_1, result_1}}, Nil{}, NoProgress{}, NoProgress{}}

def feedback_make_Kont_201519(lexical_capture_3: String, lexical_capture_8: List<&2, Lexer.Token>, lexical_capture_10: String, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: List<&2, Ast.SyntaxTerm>) -> FeedbackFrame:
  Kont_201519{lexical_capture_3, lexical_capture_8, lexical_capture_10, lexical_capture_13, lexical_capture_15, lexical_capture_17}

def step_parse_term_args_first(is_close: Bool, +file: String, token: Lexer.Token, rest: List<&2, Lexer.Token>, +tokens: List<&2, Lexer.Token>, close: String, +scope: List<&2, Scope>, +depth: Nat, +acc: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match is_close:
    case True{}:
      feedback_pack_8(((List.reverse(&2, Ast.SyntaxTerm, acc), rest), True{}))
    case False{}:
      feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_201519(file, tokens, close, scope, depth, acc))

def token_text(token: Lexer.Token) -> String:
  match token:
    case Lexer.TokenInfo{ _, text,  _,  _,  _,  _}:
      text

def step_parse_term_args(file: String, +tokens: List<&2, Lexer.Token>, +close: String, scope: List<&2, Scope>, depth: Nat, +acc: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match tokens:
    case +token <> +rest:
      step_parse_term_args_first(Bool.or(String.eq(token_text(token), close), Bool.and(String.eq(close, ">"), String.eq(token_text(token), "<>"))), file, token, rest, tokens, close, scope, depth, acc)
    case Nil{}:
      feedback_pack_8(((List.reverse(&2, Ast.SyntaxTerm, acc), Nil{}), False{}))

def step_parse_do_atom(+file: String, +tokens: List<&2, Lexer.Token>, +beg: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match tokens:
    case +monad <> +rest:
      match monad:
        case Lexer.TokenInfo{Lexer.NameToken{}, +key, _, +end, _, _}:
          match rest:
            case +open <> +after_open:
              match open:
                case Lexer.TokenInfo{_, "<", _, _, _, _}:
                  feedback_attach(step_parse_term_args(file, after_open, ">", scope, depth, Nil{}), feedback_make_Kont_145241(file, key, beg, end, tokens, scope, depth))
                case Lexer.TokenInfo{_, "<>", _, _, _, _}:
                  step_parse_do_atom_args_result(((Nil{}, after_open), True{}), file, key, beg, end, tokens, scope, depth)
                case Lexer.TokenInfo{+feedback_field_12_0, +feedback_field_12_1, +feedback_field_12_2, +feedback_field_12_3, +feedback_field_12_4, +feedback_field_12_5}:
                  feedback_pack_4(((Ast.TermHole{"parse-error: expected < after do monad", span(file, token_beg((Lexer.TokenInfo{feedback_field_12_0, feedback_field_12_1, feedback_field_12_2, feedback_field_12_3, feedback_field_12_4, feedback_field_12_5} : Lexer.Token)), token_end((Lexer.TokenInfo{feedback_field_12_0, feedback_field_12_1, feedback_field_12_2, feedback_field_12_3, feedback_field_12_4, feedback_field_12_5} : Lexer.Token)))}, rest), False{}))
            case Nil{}:
              feedback_pack_4(((Ast.TermHole{"parse-error: expected do monad parameters", span(file, end, end)}, rest), False{}))
        case Lexer.TokenInfo{+feedback_field_16_0, +feedback_field_16_1, +feedback_field_16_2, +feedback_field_16_3, +feedback_field_16_4, +feedback_field_16_5}:
          feedback_pack_4(((Ast.TermHole{"parse-error: expected do monad", span(file, token_beg((Lexer.TokenInfo{feedback_field_16_0, feedback_field_16_1, feedback_field_16_2, feedback_field_16_3, feedback_field_16_4, feedback_field_16_5} : Lexer.Token)), token_end((Lexer.TokenInfo{feedback_field_16_0, feedback_field_16_1, feedback_field_16_2, feedback_field_16_3, feedback_field_16_4, feedback_field_16_5} : Lexer.Token)))}, tokens), False{}))
    case Nil{}:
      feedback_pack_4(((Ast.TermHole{"parse-error: expected do monad", span(file, beg, beg)}, Nil{}), False{}))

def extend_scope_result(is_underscore: Bool, key: String, index: Nat, scope: List<&2, Scope>) -> List<&2, Scope>:
  match is_underscore:
    case True{}:
      scope
    case False{}:
      Scope{key, index} <> scope

def extend_scope(+key: String, index: Nat, scope: List<&2, Scope>) -> List<&2, Scope>:
  extend_scope_result(String.eq(key, "_"), key, index, scope)

def feedback_make_Kont_199246(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_14: Nat) -> FeedbackFrame:
  Kont_199246{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_14}

def feedback_make_Kont_199474(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat) -> FeedbackFrame:
  Kont_199474{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7}

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

def parse_name_term_lookup(found: Maybe<&2, Nat>, file: String, key: String, beg: Nat, end: Nat, tokens: List<&2, Lexer.Token>) -> (Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool:
  match found:
    case Some{index}:
      ((Ast.TermVar{key, index,  span(file, beg, end)}, tokens), True{})
    case None{}:
      ((Ast.TermRef{key,  span(file, beg, end)}, tokens), True{})

def step_parse_name_term(+file: String, +key: String, +beg: Nat, +end: Nat, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match tokens:
    case +next <> +rest:
      match next:
        case Lexer.TokenInfo{ _, "=>",  _,  _,  _,  _}:
          next_scope = extend_scope(key, depth, scope)
          feedback_attach(step_parse_term(file, rest, next_scope, depth + 1n, 0n), feedback_make_Kont_199246(file, key, beg, end, depth))
        case Lexer.TokenInfo{ _, "{",  _,  _,  _,  _}:
          feedback_attach(step_parse_term_args(file, rest, "}", scope, depth, Nil{}), feedback_make_Kont_199474(file, key, beg, end))
        case _:
          feedback_pack_4(parse_name_term_lookup(lookup(key, scope, depth), file, key, beg, end, tokens))
    case Nil{}:
      feedback_pack_4(parse_name_term_lookup(lookup(key, scope, depth), file, key, beg, end, Nil{}))

def step_parse_atom_name_dispatch(text: String, +file: String, +scope: List<&2, Scope>, +depth: Nat, +rest: List<&2, Lexer.Token>, +beg: Nat, +end: Nat) -> FeedbackControl:
  match text:
    case "do":
      step_parse_do_atom(file, rest, beg, scope, depth)
    case "Type":
      feedback_pack_4(((Ast.TermType{ Ast.TermQuantity{ Ast.QOne{},  span(file, beg, end)},  span(file, beg, end)}, rest), True{}))
    case "Data":
      feedback_pack_4(((Ast.TermType{ Ast.TermQuantity{ Ast.QMany{},  span(file, beg, end)},  span(file, beg, end)}, rest), True{}))
    case "Quant":
      feedback_pack_4(((Ast.TermQuant{}, rest), True{}))
    case "Kind":
      match rest:
        case +open <> +more:
          match open:
            case Lexer.TokenInfo{ _, "(",  _,  _,  _,  _}:
              feedback_attach(step_parse_term(file, more, scope, depth, 0n), feedback_make_Kont_146857(file, beg, end, rest))
            case _:
              feedback_pack_4(((Ast.TermHole{ "parse-error: expected (",  span(file, beg, end)}, rest), False{}))
        case Nil{}:
          feedback_pack_4(((Ast.TermHole{ "parse-error: expected (",  span(file, beg, end)}, rest), False{}))
    case SNil{}:
      step_parse_name_term(file, (SNil{} : String), beg, end, rest, scope, depth)
    case SCon{feedback_field_20_0, feedback_field_20_1}:
      step_parse_name_term(file, (SCon{feedback_field_20_0, feedback_field_20_1} : String), beg, end, rest, scope, depth)

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

def parse_atom_symbol_row_10(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat) -> Pair(Pair(Ast.SyntaxTerm, List<&2, Lexer.Token>), Bool):
  ((Ast.TermHole{ "parse-error: expected a term",  span(file, beg, end)}, tokens), False{})

def feedback_make_Kont_168734(capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Scope>, capture_5: Nat) -> FeedbackFrame:
  Kont_168734{capture_1, capture_2, capture_3, capture_4, capture_5}

def step_parse_list(+file: String, +tokens: List<&2, Lexer.Token>, +beg: Nat, +end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match tokens:
    case +close <> after_close:
      match close:
        case Lexer.TokenInfo{_, "]", _, _, _, _}:
          feedback_pack_4(((Ast.TermCtr{"Nil", Nil{}, span(file, beg, token_end(close))}, after_close), True{}))
        case Lexer.TokenInfo{feedback_field_6_0, feedback_field_6_1, feedback_field_6_2, feedback_field_6_3, feedback_field_6_4, feedback_field_6_5}:
          feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_168734(file, beg, token_end((Lexer.TokenInfo{feedback_field_6_0, feedback_field_6_1, feedback_field_6_2, feedback_field_6_3, feedback_field_6_4, feedback_field_6_5} : Lexer.Token)), scope, depth))
    case Nil{}:
      feedback_pack_4(((Ast.TermHole{"parse-error: expected ]", span(file, end, end)}, Nil{}), False{}))

def step_parse_atom_symbol_row_1(+file: String, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat, end: Nat) -> FeedbackControl:
  step_parse_list(file, rest, beg, end, scope, depth)

def feedback_make_Kont_174230(capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Lexer.Token>, capture_5: Nat, capture_6: List<&2, Scope>, capture_7: Nat) -> FeedbackFrame:
  Kont_174230{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7}

def step_parse_parenthesized(+file: String, +tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term_args(file, tokens, ")", scope, depth, Nil{}), feedback_make_Kont_174230(file, beg, end, tokens, col, scope, depth))

def step_parse_atom_symbol_row_2(+file: String, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat, end: Nat, col: Nat) -> FeedbackControl:
  step_parse_parenthesized(file, rest, beg, end, col, scope, depth)

def feedback_make_Kont_195883(lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_10: List<&2, Scope>, lexical_capture_12: Nat) -> FeedbackFrame:
  Kont_195883{lexical_capture_1, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_12}

def step_parse_rewrite(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_195883(file, beg, end, scope, depth))

def step_parse_atom_symbol_row_3(+file: String, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat, end: Nat) -> FeedbackControl:
  step_parse_rewrite(file, rest, beg, end, scope, depth)

def feedback_make_Kont_205334(lexical_capture_1: String, lexical_capture_23: String, lexical_capture_25: Nat, lexical_capture_10: Nat, lexical_capture_11: Ast.Quantity, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat) -> FeedbackFrame:
  Kont_205334{lexical_capture_1, lexical_capture_23, lexical_capture_25, lexical_capture_10, lexical_capture_11, lexical_capture_6, lexical_capture_8}

def step_parse_all_named(+file: String, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +beg: Nat, quantity: Ast.Quantity) -> FeedbackControl:
  match tokens:
    case +name <> +rest:
      match name:
        case Lexer.TokenInfo{ Lexer.NameToken{},  key,  _,  +key_end,  _,  _}:
          match rest:
            case +colon <> after_colon:
              match colon:
                case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
                  feedback_attach(step_parse_term(file, after_colon, scope, depth, 1n), feedback_make_Kont_205334(file, key, key_end, beg, quantity, scope, depth))
                case Lexer.TokenInfo{+feedback_field_10_0, +feedback_field_10_1, +feedback_field_10_2, +feedback_field_10_3, +feedback_field_10_4, +feedback_field_10_5}:
                  feedback_pack_4(((Ast.TermHole{ "parse-error: expected :",  span(file, token_beg((Lexer.TokenInfo{feedback_field_10_0, feedback_field_10_1, feedback_field_10_2, feedback_field_10_3, feedback_field_10_4, feedback_field_10_5} : Lexer.Token)), token_end((Lexer.TokenInfo{feedback_field_10_0, feedback_field_10_1, feedback_field_10_2, feedback_field_10_3, feedback_field_10_4, feedback_field_10_5} : Lexer.Token)))}, rest), False{}))
            case Nil{}:
              feedback_pack_4(((Ast.TermHole{ "parse-error: expected :",  span(file, beg, key_end)}, rest), False{}))
        case Lexer.TokenInfo{feedback_field_14_0, feedback_field_14_1, feedback_field_14_2, feedback_field_14_3, feedback_field_14_4, feedback_field_14_5}:
          feedback_pack_4(((Ast.TermHole{ "parse-error: expected a binder",  span(file, beg, token_end((Lexer.TokenInfo{feedback_field_14_0, feedback_field_14_1, feedback_field_14_2, feedback_field_14_3, feedback_field_14_4, feedback_field_14_5} : Lexer.Token)))}, tokens), False{}))
    case Nil{}:
      feedback_pack_4(((Ast.TermHole{ "parse-error: expected a binder",  span(file, beg, beg)}, Nil{}), False{}))

def step_parse_all(+file: String, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +beg: Nat, +quantity: Ast.Quantity) -> FeedbackControl:
  match tokens:
    case +prefix <> +rest:
      match prefix:
        case Lexer.TokenInfo{ _, "+",  _,  _,  _,  _}:
          step_parse_all_named(file, rest, scope, depth, beg, Ast.QMany{})
        case Lexer.TokenInfo{ _, "-",  _,  _,  _,  _}:
          step_parse_all_named(file, rest, scope, depth, beg, Ast.QZero{})
        case _:
          step_parse_all_named(file, tokens, scope, depth, beg, quantity)
    case Nil{}:
      step_parse_all_named(file, Nil{}, scope, depth, beg, quantity)

def step_parse_atom_symbol_row_4(+file: String, scope: List<&2, Scope>, depth: Nat, rest: List<&2, Lexer.Token>, beg: Nat) -> FeedbackControl:
  step_parse_all(file, rest, scope, depth, beg, Ast.QMany{})

def step_parse_amp(+file: String, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +beg: Nat, end: Nat) -> FeedbackControl:
  match tokens:
    case +quantity <> +rest:
      match quantity:
        case Lexer.TokenInfo{ _, "0",  _,  _,  _,  _}:
          feedback_pack_4(((Ast.TermQuantity{ Ast.QZero{},  span(file, beg, token_end(quantity))}, rest), True{}))
        case Lexer.TokenInfo{ _, "1",  _,  _,  _,  _}:
          feedback_pack_4(((Ast.TermQuantity{ Ast.QOne{},  span(file, beg, token_end(quantity))}, rest), True{}))
        case Lexer.TokenInfo{ _, "2",  _,  _,  _,  _}:
          feedback_pack_4(((Ast.TermQuantity{ Ast.QMany{},  span(file, beg, token_end(quantity))}, rest), True{}))
        case _:
          step_parse_all(file, tokens, scope, depth, beg, Ast.QOne{})
    case Nil{}:
      step_parse_all(file, Nil{}, scope, depth, beg, Ast.QOne{})

