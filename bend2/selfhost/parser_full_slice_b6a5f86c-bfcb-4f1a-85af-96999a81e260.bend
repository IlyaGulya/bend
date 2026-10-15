# EXPERIMENTAL / FUEL-PARAMETRIC / NOT SELFHOST GREEN

import Base
import ./ast.bend as Ast
import ./lexer.bend as Lexer

type ParseResult is Data:
  ParseSuccess{module: Ast.Module}
  ParseFailure{message: String, expected: String, observed: String, span: Ast.SourceSpan}

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

type FeedbackFrame is Data:
  KontProgress{}
  Kont_116133{capture_1: String, capture_2: String, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Lexer.Token>, capture_6: List<&2, Scope>, capture_7: Nat}
  Kont_117987{capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Lexer.Token>}
  Kont_121034{capture_1: String, capture_2: Nat}
  Kont_121546{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Nat, capture_5: Nat}
  Kont_122613{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: Nat, capture_8: Nat, capture_9: List<&2, Scope>, capture_10: Nat, capture_11: Nat}
  Kont_124136{lexical_capture_4: String, lexical_capture_6: String, lexical_capture_8: List<&2, Ast.SyntaxTerm>, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_13: Ast.SyntaxTerm, lexical_capture_29: Ast.SyntaxTerm, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_22: Nat}
  Kont_125059{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Nat, capture_7: Nat, capture_8: List<&2, Scope>, capture_9: Nat, capture_10: Nat}
  Kont_126071{lexical_capture_4: String, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_22: Nat, lexical_capture_13: Ast.SyntaxTerm, lexical_capture_29: Ast.SyntaxTerm}
  Kont_126714{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: String, capture_5: Nat, capture_6: Ast.SyntaxTerm, capture_7: Nat, capture_8: Nat, capture_9: List<&2, Scope>, capture_10: Nat, capture_11: Nat}
  Kont_128779{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Ast.SyntaxTerm, capture_5: Nat, capture_6: Nat, capture_7: List<&2, Scope>, capture_8: Nat, capture_9: Nat}
  Kont_129317{capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Nat, capture_5: Nat, capture_6: List<&2, Scope>, capture_7: Nat, capture_8: Nat}
  Kont_130649{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: List<&2, Ast.SyntaxTerm>, lexical_capture_6: Ast.SyntaxTerm, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_18: Nat}
  Kont_134352{capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: Nat}
  Kont_135006{capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Scope>, capture_5: Nat}
  Kont_136191{lexical_capture_4: String, lexical_capture_5: Ast.SyntaxTerm, lexical_capture_7: Nat}
  Kont_136883{capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Scope>, capture_6: Nat}
  Kont_137461{capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Ast.SyntaxTerm, capture_4: Nat, capture_5: Nat}
  Kont_137310{capture_1: String, capture_2: Ast.SyntaxTerm, capture_3: Ast.SyntaxTerm, capture_4: Nat, capture_5: Nat}
  Kont_138911{capture_1: String, capture_2: Nat, capture_3: Nat, capture_4: List<&2, Lexer.Token>, capture_5: Nat, capture_6: List<&2, Scope>, capture_7: Nat}
  Kont_140147{capture_1: String, capture_2: List<&2, Lexer.Token>, capture_3: Nat, capture_4: List<&2, Scope>, capture_5: Nat}
  Kont_140570{capture_1: String, capture_2: Ast.SyntaxTerm}
  Kont_141471{capture_1: String, capture_2: List<&2, Scope>, capture_3: Nat}
  Kont_144337{capture_1: String, capture_2: String, capture_3: Nat, capture_4: List<&2, Scope>, capture_5: Nat}
  Kont_147964{lexical_capture_98: String, lexical_capture_99: String, lexical_capture_100: Ast.SyntaxTerm, lexical_capture_107: Nat}
  Kont_147638{lexical_capture_98: String, lexical_capture_99: String, lexical_capture_100: Ast.SyntaxTerm, lexical_capture_107: Nat}
  Kont_147298{lexical_capture_98: String, lexical_capture_99: String, lexical_capture_100: Ast.SyntaxTerm, lexical_capture_107: Nat}
  Kont_146467{lexical_capture_49: String, lexical_capture_50: String, lexical_capture_51: Ast.SyntaxTerm, lexical_capture_52: List<&2, Lexer.Token>, lexical_capture_53: String, lexical_capture_55: Nat, lexical_capture_56: List<&2, Scope>, lexical_capture_57: Nat}
  Kont_149158{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_8: Nat}
  Kont_149511{lexical_capture_1: String}
  Kont_150061{lexical_capture_6: String, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_9: Nat}
  Kont_151120{lexical_capture_7: String, lexical_capture_5: Ast.SyntaxTerm, lexical_capture_9: Nat}
  Kont_150872{lexical_capture_7: String, lexical_capture_5: Ast.SyntaxTerm, lexical_capture_9: Nat, lexical_capture_12: List<&2, Scope>, lexical_capture_14: Nat}
  Kont_152688{lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_10: List<&2, Scope>, lexical_capture_12: Nat}
  Kont_153371{lexical_capture_6: String, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_9: Nat, lexical_capture_14: Nat}
  Kont_153930{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_6: Nat, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat}
  Kont_154866{lexical_capture_6: String, lexical_capture_21: String, lexical_capture_8: Nat, lexical_capture_10: Nat, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat}
  Kont_156469{lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_10: List<&2, Scope>, lexical_capture_12: Nat}
  Kont_157257{lexical_capture_7: Ast.SyntaxTerm, lexical_capture_26: Ast.SyntaxTerm, lexical_capture_6: String, lexical_capture_11: Nat}
  Kont_157973{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_4: String, lexical_capture_8: Nat, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat}
  Kont_159032{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat}
  Kont_158804{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_14: Nat}
  Kont_161077{lexical_capture_3: String, lexical_capture_8: List<&2, Lexer.Token>, lexical_capture_10: String, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: List<&2, Ast.SyntaxTerm>}
  Kont_162876{lexical_capture_6: String, lexical_capture_8: String, lexical_capture_10: Nat, lexical_capture_12: Nat, lexical_capture_13: Ast.Quantity, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_36: Nat}
  Kont_163768{lexical_capture_1: String, lexical_capture_23: String, lexical_capture_25: Nat, lexical_capture_10: Nat, lexical_capture_11: Ast.Quantity, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat}
  Kont_165020{lexical_capture_1: String, lexical_capture_22: String, lexical_capture_5: Nat, lexical_capture_24: Nat, lexical_capture_10: Nat}
  Kont_166816{lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat}
  Kont_168126{lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_6: Nat, lexical_capture_7: Lexer.Token}
  Kont_168812{lexical_capture_1: String, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat, lexical_capture_10: Nat}
  Kont_172866{lexical_capture_3: String, lexical_capture_30: Ast.SyntaxTerm, lexical_capture_5: Lexer.Token, lexical_capture_15: List<&2, Scope>, lexical_capture_17: Nat, lexical_capture_19: Nat}
  Kont_177865{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_16: Lexer.Token, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: Nat}
  Kont_174429{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: Nat, lexical_capture_35: Nat}
  Kont_180327{lexical_capture_6: String, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_9: Lexer.Token, lexical_capture_20: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, lexical_capture_18: Nat}
  Kont_182346{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_4: List<&2, Lexer.Token>, lexical_capture_6: List<&2, Lexer.Token>, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat}
  Kont_185933{lexical_capture_3: String, lexical_capture_5: String, lexical_capture_8: Ast.SyntaxTerm, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_19: Nat}
  Kont_187228{lexical_capture_3: String, lexical_capture_4: Ast.SyntaxTerm, lexical_capture_9: List<&2, Scope>, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat}
  Kont_188873{lexical_capture_15: Bool, lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_4: List<&2, Lexer.Token>}
  Kont_191388{lexical_capture_6: String, lexical_capture_7: Ast.SyntaxTerm, lexical_capture_8: Ast.SyntaxTerm, lexical_capture_10: Nat, lexical_capture_12: Nat, lexical_capture_15: List<&2, Scope>, lexical_capture_17: Nat, lexical_capture_19: Nat}
  Kont_193195{lexical_capture_1: String, lexical_capture_2: Ast.SyntaxTerm, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: Nat, lexical_capture_13: Nat, lexical_capture_15: Nat}
  Kont_195614{lexical_capture_3: String, lexical_capture_5: String, lexical_capture_8: Ast.SyntaxTerm, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_19: Nat}
  Kont_199032{lexical_capture_1: String}
  Kont_202119{capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: Nat, capture_6: List<&2, Ast.SyntaxTerm>}
  Kont_203102{lexical_capture_3: List<&2, Ast.SyntaxPattern>, lexical_capture_5: List<&2, Lexer.Token>, lexical_capture_8: List<&2, Scope>, lexical_capture_10: Nat, lexical_capture_12: String, lexical_capture_14: Nat, lexical_capture_16: Nat, lexical_capture_19: List<&2, Scope>, lexical_capture_21: Nat, lexical_capture_22: Ast.Quantity}
  Kont_205492{lexical_capture_3: List<&2, Ast.SyntaxTerm>, lexical_capture_7: List<&2, Ast.SyntaxPattern>, lexical_capture_13: Ast.Quantity, lexical_capture_15: String, lexical_capture_17: Nat}
  Kont_206151{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, lexical_capture_17: Ast.Quantity}
  Kont_207731{lexical_capture_3: String, lexical_capture_5: String, lexical_capture_7: Nat, lexical_capture_10: Ast.SyntaxPattern, lexical_capture_19: Ast.Quantity, lexical_capture_11: Ast.SyntaxTerm}
  Kont_208346{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat}
  Kont_209507{lexical_capture_4: Ast.SyntaxPattern, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: String, lexical_capture_13: List<&2, Lexer.Token>, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_20: List<&2, Scope>, lexical_capture_22: Nat}
  Kont_210760{lexical_capture_2: Ast.SyntaxTerm, lexical_capture_5: Ast.SyntaxPattern, lexical_capture_12: String, lexical_capture_14: Nat}
  Kont_211342{lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_10: List<&2, Scope>, lexical_capture_12: Nat}
  Kont_211985{lexical_capture_5: List<&2, Ast.SyntaxTerm>, lexical_capture_21: Lexer.Token, lexical_capture_7: String, lexical_capture_9: Nat}
  Kont_213847{lexical_capture_1: String, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat, lexical_capture_10: List<&2, Ast.SyntaxTerm>}
  Kont_214434{lexical_capture_3: String, lexical_capture_5: List<&2, Lexer.Token>, lexical_capture_9: Nat, lexical_capture_12: List<&2, Scope>, lexical_capture_14: Nat, lexical_capture_16: Nat, lexical_capture_18: List<&2, Ast.SyntaxTerm>}
  Kont_218739{lexical_capture_5: List<&2, Ast.SyntaxPattern>, lexical_capture_3: String, lexical_capture_15: Nat}
  Kont_223069{capture_1: String, capture_2: List<&2, Ast.TelescopeItem>, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: String, capture_6: Nat}
  Kont_225981{capture_1: String, capture_2: String, capture_3: Ast.Quantity, capture_4: Nat, capture_5: List<&2, Ast.TelescopeItem>, capture_6: List<&2, Scope>, capture_7: Nat}
  Kont_227629{}
  Kont_228464{lexical_capture_0: Lexer.Token, lexical_capture_2: List<&2, Lexer.Token>, lexical_capture_8: String, lexical_capture_10: String, lexical_capture_12: Nat, lexical_capture_14: List<&2, Ast.TelescopeItem>, lexical_capture_5: Ast.SyntaxTerm}
  Kont_230090{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: List<&2, Ast.TelescopeItem>, lexical_capture_21: Lexer.Token, lexical_capture_22: List<&2, Lexer.Token>}
  Kont_229920{capture_1: Lexer.Token, capture_2: String, capture_3: String, capture_4: Nat, capture_5: List<&2, Ast.TelescopeItem>, capture_6: List<&2, Scope>, capture_7: Nat}
  Kont_231478{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat}
  Kont_236818{}
  Kont_239408{lexical_capture_3: String, lexical_capture_26: Lexer.Token, lexical_capture_27: List<&2, Lexer.Token>, lexical_capture_9: Nat, lexical_capture_12: List<&2, Scope>, lexical_capture_14: Nat, lexical_capture_16: List<&2, Ast.ConstructorDecl>, lexical_capture_18: String, lexical_capture_20: Nat}
  Kont_241464{lexical_capture_6: String, lexical_capture_8: String, lexical_capture_10: Nat, lexical_capture_14: List<&2, Ast.TelescopeItem>, lexical_capture_2: Ast.SyntaxTerm}
  Kont_242296{lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: List<&2, Ast.TelescopeItem>, lexical_capture_11: List<&2, Lexer.Token>, lexical_capture_16: List<&2, Scope>, lexical_capture_18: Nat}
  Kont_243897{lexical_capture_26: Lexer.Token, lexical_capture_1: String, lexical_capture_19: String, lexical_capture_5: Nat, lexical_capture_7: Nat}
  Kont_245918{lexical_capture_12: String, lexical_capture_14: String, lexical_capture_3: List<&2, Ast.Clause>, lexical_capture_16: Nat, lexical_capture_17: Lexer.Token, lexical_capture_5: List<&2, Lexer.Token>}
  Kont_249858{lexical_capture_1: String, lexical_capture_31: String, lexical_capture_32: Nat, lexical_capture_33: Nat, lexical_capture_5: Nat, lexical_capture_7: Bool, lexical_capture_8: Ast.Quantity, lexical_capture_11: List<&2, Scope>, lexical_capture_13: Nat, lexical_capture_15: List<&2, Ast.Clause>}
  Kont_251824{lexical_capture_1: String, lexical_capture_7: Nat, lexical_capture_9: Bool, lexical_capture_10: Ast.Quantity, lexical_capture_12: String, lexical_capture_14: Nat, lexical_capture_17: Ast.SyntaxTerm, lexical_capture_20: List<&2, Scope>, lexical_capture_22: Nat, lexical_capture_24: List<&2, Ast.Clause>}
  Kont_254130{lexical_capture_1: String, lexical_capture_17: String, lexical_capture_5: Nat, lexical_capture_24: Lexer.Token, lexical_capture_25: List<&2, Lexer.Token>}
  Kont_256407{lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>}
  Kont_256184{lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>}
  Kont_255959{lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>}
  Kont_255737{lexical_capture_3: List<&2, Lexer.Token>, lexical_capture_1: String, lexical_capture_7: String, lexical_capture_9: List<&2, Ast.TopLevel>}
  Kont_258194{lexical_capture_7: String, lexical_capture_3: List<&2, Ast.ModuleImport>}
  Kont_258647{lexical_capture_3: String}

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
  Request_parse_top_result{ok: Bool, top: Ast.TopLevel, after: List<&2, Lexer.Token>, tokens: List<&2, Lexer.Token>, file: String, path: String, acc: List<&2, Ast.TopLevel>}
  Request_parse_type_constructor_fields_result{ok_fields: Bool, fields: List<&2, Ast.TelescopeItem>, after_fields: List<&2, Lexer.Token>, file: String, open: Lexer.Token, after_open: List<&2, Lexer.Token>, col: Nat, scope: List<&2, Scope>, depth: Nat, acc: List<&2, Ast.ConstructorDecl>, key: String, beg: Nat}

type FeedbackAction is Data:
  FeedbackCall{request: FeedbackRequest}
  FeedbackDone{value: FeedbackValue}
  FeedbackInvariant{}

type FeedbackControl is Data:
  FeedbackControl{action: FeedbackAction, pending: List<&2, FeedbackKont>, progress: Progress, own_progress: Progress}

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

def feedback_pack_4(result: ((Ast.SyntaxTerm & List<&2, Lexer.Token>) & Bool)) -> FeedbackControl:
  match result:
    case ((result_0_0, result_0_1), result_1):
      FeedbackControl{FeedbackDone{Value_4{result_0_0, result_0_1, result_1}}, Nil{}, NoProgress{}, NoProgress{}}

def span(file: String, beg: Nat, end: Nat) -> Ast.SourceSpan:
  Ast.SpanOf{file, beg, end}

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

def feedback_make_Kont_168812(lexical_capture_1: String, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat, lexical_capture_10: Nat) -> FeedbackFrame:
  Kont_168812{lexical_capture_1, lexical_capture_6, lexical_capture_8, lexical_capture_10}

def feedback_make_parse_atom_scan(file: String, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackRequest:
  Request_parse_atom_scan{file, tokens, scanned, scope, depth}

def step_parse_atom(file: String, +tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  FeedbackControl{FeedbackCall{feedback_make_parse_atom_scan(file, tokens, skip_lines(tokens), scope, depth)}, Nil{}, NoProgress{}, NoProgress{}}

def step_parse_term(+file: String, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, level: Nat) -> FeedbackControl:
  feedback_attach(step_parse_atom(file, tokens, scope, depth), feedback_make_Kont_168812(file, scope, depth, level))

def token_beg(token: Lexer.Token) -> Nat:
  match token:
    case Lexer.TokenInfo{ _,  _, beg,  _,  _,  _}:
      beg

def token_end(token: Lexer.Token) -> Nat:
  match token:
    case Lexer.TokenInfo{ _,  _,  _, end,  _,  _}:
      end

def feedback_make_Kont_116133(capture_1: String, capture_2: String, capture_3: Nat, capture_4: Nat, capture_5: List<&2, Lexer.Token>, capture_6: List<&2, Scope>, capture_7: Nat) -> FeedbackFrame:
  Kont_116133{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6, capture_7}

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

def feedback_make_Kont_121546(capture_1: String, capture_2: String, capture_3: List<&2, Ast.SyntaxTerm>, capture_4: Nat, capture_5: Nat) -> FeedbackFrame:
  Kont_121546{capture_1, capture_2, capture_3, capture_4, capture_5}

def feedback_make_parse_do_typed_bind(file: String, monad: String, args: List<&2, Ast.SyntaxTerm>, tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> FeedbackRequest:
  Request_parse_do_typed_bind{file, monad, args, tokens, beg, end, scope, depth, col}

def step_parse_do_return_scan(+file: String, +key: String, +args: List<&2, Ast.SyntaxTerm>, tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +beg: Nat, +end: Nat, +scope: List<&2, Scope>, +depth: Nat, col: Nat) -> FeedbackControl:
  match scanned:
    case +return_token <> +rest:
      match return_token:
        case Lexer.TokenInfo{Lexer.NameToken{}, "return", _, _, _, _}:
          feedback_attach(step_parse_term(file, rest, scope, depth, 0n), feedback_make_Kont_121546(file, key, args, beg, end))
        case Lexer.TokenInfo{feedback_field_6_0, feedback_field_6_1, feedback_field_6_2, feedback_field_6_3, feedback_field_6_4, feedback_field_6_5}:
          FeedbackControl{FeedbackCall{feedback_make_parse_do_typed_bind(file, key, args, (Lexer.TokenInfo{feedback_field_6_0, feedback_field_6_1, feedback_field_6_2, feedback_field_6_3, feedback_field_6_4, feedback_field_6_5} : Lexer.Token) <> rest, beg, end, scope, depth, col)}, Nil{}, NoProgress{}, NoProgress{}}
    case Nil{}:
      feedback_pack_4(((Ast.TermHole{"parse-error: expected return in do block", span(file, beg, end)}, Nil{}), False{}))

def step_parse_do_return(file: String, key: String, args: List<&2, Ast.SyntaxTerm>, +tokens: List<&2, Lexer.Token>, beg: Nat, end: Nat, scope: List<&2, Scope>, depth: Nat, col: Nat) -> FeedbackControl:
  step_parse_do_return_scan(file, key, args, tokens, skip_lines(tokens), beg, end, scope, depth, col)

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

def feedback_make_Kont_161077(lexical_capture_3: String, lexical_capture_8: List<&2, Lexer.Token>, lexical_capture_10: String, lexical_capture_13: List<&2, Scope>, lexical_capture_15: Nat, lexical_capture_17: List<&2, Ast.SyntaxTerm>) -> FeedbackFrame:
  Kont_161077{lexical_capture_3, lexical_capture_8, lexical_capture_10, lexical_capture_13, lexical_capture_15, lexical_capture_17}

def step_parse_term_args_first(is_close: Bool, +file: String, token: Lexer.Token, rest: List<&2, Lexer.Token>, +tokens: List<&2, Lexer.Token>, close: String, +scope: List<&2, Scope>, +depth: Nat, +acc: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match is_close:
    case True{}:
      feedback_pack_8(((List.reverse(&2, Ast.SyntaxTerm, acc), rest), True{}))
    case False{}:
      feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_161077(file, tokens, close, scope, depth, acc))

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
                  feedback_attach(step_parse_term_args(file, after_open, ">", scope, depth, Nil{}), feedback_make_Kont_116133(file, key, beg, end, tokens, scope, depth))
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

def drop_nat_suffix(+text: String) -> String:
  drop_nat_suffix_reversed(List.reverse(&2, Char, String.to_list(text)), text)

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

def feedback_make_Kont_203102(lexical_capture_3: List<&2, Ast.SyntaxPattern>, lexical_capture_5: List<&2, Lexer.Token>, lexical_capture_8: List<&2, Scope>, lexical_capture_10: Nat, lexical_capture_12: String, lexical_capture_14: Nat, lexical_capture_16: Nat, lexical_capture_19: List<&2, Scope>, lexical_capture_21: Nat, lexical_capture_22: Ast.Quantity) -> FeedbackFrame:
  Kont_203102{lexical_capture_3, lexical_capture_5, lexical_capture_8, lexical_capture_10, lexical_capture_12, lexical_capture_14, lexical_capture_16, lexical_capture_19, lexical_capture_21, lexical_capture_22}

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

def feedback_make_Kont_202119(capture_1: List<&2, Lexer.Token>, capture_2: String, capture_3: List<&2, Scope>, capture_4: Nat, capture_5: Nat, capture_6: List<&2, Ast.SyntaxTerm>) -> FeedbackFrame:
  Kont_202119{capture_1, capture_2, capture_3, capture_4, capture_5, capture_6}

def step_parse_local_values(+file: String, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, line: Nat, acc: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_202119(tokens, file, scope, depth, line, acc))

def token_end_of(tokens: List<&2, Lexer.Token>, fallback: Nat) -> Nat:
  match tokens:
    case +token <> _:
      token_beg(token)
    case Nil{}:
      fallback

def step_parse_parallel_binders_result(ok_patterns: Bool, patterns: List<&2, Ast.SyntaxPattern>, +after_equals: List<&2, Lexer.Token>, next_scope: List<&2, Scope>, next_depth: Nat, +file: String, +beg: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat, quantity: Ast.Quantity) -> FeedbackControl:
  match ok_patterns:
    case True{}:
      feedback_attach(step_parse_local_values(file, after_equals, scope, depth, first_line(after_equals), Nil{}), feedback_make_Kont_203102(patterns, after_equals, next_scope, next_depth, file, beg, col, scope, depth, quantity))
    case False{}:
      feedback_pack_4(((Ast.TermHole{ "parse-error: expected parallel binders",  span(file, beg, token_end_of(after_equals, beg))}, after_equals), False{}))

def feedback_consumer_202411(v_527: Pair(Pair(Pair(Pair(List<&2, Ast.SyntaxPattern>, List<&2, Lexer.Token>), List<&2, Scope>), Nat), Bool), v_1: String, v_5: Nat, v_7: Nat, v_10: List<&2, Scope>, v_12: Nat, v_13: Ast.Quantity) -> FeedbackControl:
  match v_527:
    case ((((v_528, v_529), v_530), v_531), v_532):
      step_parse_parallel_binders_result(v_532, v_528, v_529, v_530, v_531, v_1, v_5, v_7, v_10, v_12, v_13)

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

def step_parse_parallel_local(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat, +quantity: Ast.Quantity) -> FeedbackControl:
  feedback_consumer_202411(parse_local_binders(file, tokens, scope, depth, quantity, Nil{}), file, beg, col, scope, depth, quantity)

def feedback_make_Kont_199032(lexical_capture_1: String) -> FeedbackFrame:
  Kont_199032{lexical_capture_1}

def step_parse_reply(+file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_199032(file))

def step_decl_parallel_or_reply(is_parallel: Bool, +file: String, tokens: List<&2, Lexer.Token>, group: List<&2, Lexer.Token>, beg: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat, quantity: Ast.Quantity) -> FeedbackControl:
  match is_parallel:
    case True{}:
      step_parse_parallel_local(file, group, beg, col, scope, depth, quantity)
    case False{}:
      step_parse_reply(file, tokens, scope, depth)

def feedback_make_Kont_208346(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat) -> FeedbackFrame:
  Kont_208346{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_14, lexical_capture_16}

def step_parse_array_write_local(+file: String, key: String, beg: Nat, key_end: Nat, col: Nat, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_208346(file, key, beg, key_end, col, scope, depth))

def step_decl_local_name_group(is_array_write: Bool, is_array: Bool, +file: String, tokens: List<&2, Lexer.Token>, +token: Lexer.Token, +rest: List<&2, Lexer.Token>, key: String, +beg: Nat, end: Nat, +col: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match is_array_write:
    case True{}:
      step_parse_array_write_local(file, key, beg, end, col, token <> rest, scope, depth)
    case False{}:
      step_decl_parallel_or_reply(is_array, file, tokens, token <> rest, beg, col, scope, depth, Ast.QOne{})

def feedback_make_Kont_209507(lexical_capture_4: Ast.SyntaxPattern, lexical_capture_7: List<&2, Scope>, lexical_capture_9: Nat, lexical_capture_11: String, lexical_capture_13: List<&2, Lexer.Token>, lexical_capture_15: Nat, lexical_capture_17: Nat, lexical_capture_20: List<&2, Scope>, lexical_capture_22: Nat) -> FeedbackFrame:
  Kont_209507{lexical_capture_4, lexical_capture_7, lexical_capture_9, lexical_capture_11, lexical_capture_13, lexical_capture_15, lexical_capture_17, lexical_capture_20, lexical_capture_22}

def step_parse_destructuring_pattern_result(ok_pattern: Bool, after_pattern: List<&2, Lexer.Token>, pattern: Ast.SyntaxPattern, next_scope: List<&2, Scope>, next_depth: Nat, +file: String, +tokens: List<&2, Lexer.Token>, beg: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  match ok_pattern after_pattern:
    case True{} +equals <> after_equals:
      match equals:
        case Lexer.TokenInfo{ _, "=",  _,  _,  _,  _}:
          feedback_attach(step_parse_term(file, after_equals, scope, depth, 0n), feedback_make_Kont_209507(pattern, next_scope, next_depth, file, tokens, beg, col, scope, depth))
        case _:
          step_parse_reply(file, tokens, scope, depth)
    case _ _:
      step_parse_reply(file, tokens, scope, depth)

def feedback_consumer_208732(v_531: Pair(Pair(Ast.SyntaxPattern, List<&2, Lexer.Token>), Pair(Pair(List<&2, Scope>, Nat), Bool)), v_1: String, v_3: List<&2, Lexer.Token>, v_5: Nat, v_7: Nat, v_10: List<&2, Scope>, v_12: Nat) -> FeedbackControl:
  match v_531:
    case ((v_532, v_533), (v_534, v_535), v_536):
      step_parse_destructuring_pattern_result(v_536, v_533, v_532, v_534, v_535, v_1, v_3, v_5, v_7, v_10, v_12)

def pattern_finish(goal: PatternScanGoal, pattern: Ast.SyntaxPattern, after: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, ok: Bool) -> PatternScanOutcome:
  match goal ok:
    case PatternSingleGoal{} status:
      PatternSingleOutcome{pattern, after, scope, depth, status}
    case PatternCaseGoal{acc, before_scope, before_depth} True{}:
      PatternCaseOutcome{List.reverse(&2, Ast.SyntaxPattern, pattern <> acc), after, scope, depth, False{}}
    case PatternCaseGoal{acc, before_scope, before_depth} False{}:
      PatternCaseOutcome{List.reverse(&2, Ast.SyntaxPattern, acc), after, before_scope, before_depth, False{}}

def nat_pattern(+file: String, value: Nat, +beg: Nat, +end: Nat) -> Ast.SyntaxPattern:
  match value:
    case 0n:
      Ast.PatternCtr{ "Zero",  Nil{},  span(file, beg, end)}
    case 1n+rest:
      Ast.PatternCtr{ "Succ",  [nat_pattern(file, rest, beg, end)],  span(file, beg, end)}

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
    case _ PatternBadNat{beg, end}:
      pattern_finish(goal, Ast.PatternVar{"", depth, Ast.QOne{}, span(file, beg, end)}, tokens, scope, depth, False{})
    case Lexer.TokenInfo{Lexer.NewlineToken{}, _, _, _, _, _} <> +rest PatternExpect{quantity, beg}:
      pattern_scan(rest, file, PatternExpect{quantity, beg}, frames, scope, depth, goal)
    case Lexer.TokenInfo{_, "}", _, close_end, _, _} <> +rest PatternExpect{quantity, +beg}:
      match frames:
        case PatternFrameOf{key, start, end, fields, root_scope, root_depth} <> parents:
          pattern_scan(rest, file, PatternCompleted{Ast.PatternCtr{key, List.reverse(&2, Ast.SyntaxPattern, fields), span(file, start, close_end)}}, parents, scope, depth, goal)
        case Nil{}:
          pattern_finish(goal, Ast.PatternVar{"", depth, quantity, span(file, beg, beg)}, tokens, scope, depth, False{})
    case Lexer.TokenInfo{_, ",", _, _, _, _} <> +rest PatternCompleted{pattern}:
      match frames:
        case PatternFrameOf{key, beg, end, fields, root_scope, root_depth} <> parents:
          pattern_scan(rest, file, PatternExpect{Ast.QOne{}, 0n}, PatternFrameOf{key, beg, end, pattern <> fields, root_scope, root_depth} <> parents, scope, depth, goal)
        case Nil{}:
          match goal:
            case PatternSingleGoal{}:
              PatternSingleOutcome{pattern, tokens, scope, depth, True{}}
            case PatternCaseGoal{acc, before_scope, before_depth}:
              pattern_scan(rest, file, PatternExpect{Ast.QOne{}, 0n}, Nil{}, scope, depth, PatternCaseGoal{pattern <> acc, scope, depth})
    case Lexer.TokenInfo{_, ":", _, _, _, _} <> +rest PatternCompleted{pattern}:
      match frames:
        case PatternFrameOf{key, beg, end, fields, root_scope, root_depth} <> parents:
          pattern_finish(goal, Ast.PatternCtr{key, List.reverse(&2, Ast.SyntaxPattern, pattern <> fields), span(file, beg, end)}, tokens, root_scope, root_depth, False{})
        case Nil{}:
          match goal:
            case PatternSingleGoal{}:
              PatternSingleOutcome{pattern, tokens, scope, depth, True{}}
            case PatternCaseGoal{acc, before_scope, before_depth}:
              PatternCaseOutcome{List.reverse(&2, Ast.SyntaxPattern, pattern <> acc), tokens, scope, depth, True{}}
    case Lexer.TokenInfo{_, "}", _, close_end, _, _} <> +rest PatternCompleted{pattern}:
      match frames:
        case PatternFrameOf{key, beg, end, fields, root_scope, root_depth} <> parents:
          pattern_scan(rest, file, PatternCompleted{Ast.PatternCtr{key, List.reverse(&2, Ast.SyntaxPattern, pattern <> fields), span(file, beg, close_end)}}, parents, scope, depth, goal)
        case Nil{}:
          pattern_finish(goal, pattern, tokens, scope, depth, True{})
    case Lexer.TokenInfo{Lexer.NewlineToken{}, _, _, _, _, _} <> +rest PatternCompleted{pattern}:
      match frames:
        case +_ <> _:
          pattern_scan(rest, file, PatternCompleted{pattern}, frames, scope, depth, goal)
        case Nil{}:
          match goal:
            case PatternSingleGoal{}:
              PatternSingleOutcome{pattern, tokens, scope, depth, True{}}
            case PatternCaseGoal{acc, before_scope, before_depth}:
              pattern_scan(rest, file, PatternCompleted{pattern}, Nil{}, scope, depth, PatternCaseGoal{acc, before_scope, before_depth})
    case Lexer.TokenInfo{Lexer.NameToken{}, key, beg, end, _, _} <> (Lexer.TokenInfo{_, "{", _, _, _, _} <> +after_open) PatternCompleted{pattern}:
      match frames:
        case PatternFrameOf{parent, start, parent_end, fields, root_scope, root_depth} <> parents:
          pattern_scan(after_open, file, PatternExpect{Ast.QOne{}, 0n}, PatternFrameOf{key, beg, end, Nil{}, scope, depth} <> (PatternFrameOf{parent, start, parent_end, pattern <> fields, root_scope, root_depth} <> parents), scope, depth, goal)
        case Nil{}:
          pattern_finish(goal, pattern, tokens, scope, depth, True{})
    case Lexer.TokenInfo{Lexer.NameToken{}, +key, beg, end, _, _} <> +rest PatternCompleted{pattern}:
      match frames:
        case PatternFrameOf{parent, start, parent_end, fields, root_scope, root_depth} <> parents:
          pattern_scan(rest, file, PatternCompleted{Ast.PatternVar{key, depth, Ast.QOne{}, span(file, beg, end)}}, PatternFrameOf{parent, start, parent_end, pattern <> fields, root_scope, root_depth} <> parents, extend_scope(key, depth, scope), depth + 1n, goal)
        case Nil{}:
          pattern_finish(goal, pattern, tokens, scope, depth, True{})
    case Lexer.TokenInfo{_, "+", beg, _, _, _} <> +rest PatternCompleted{pattern}:
      match frames:
        case PatternFrameOf{parent, start, parent_end, fields, root_scope, root_depth} <> parents:
          pattern_scan(rest, file, PatternExpect{Ast.QMany{}, beg}, PatternFrameOf{parent, start, parent_end, pattern <> fields, root_scope, root_depth} <> parents, scope, depth, goal)
        case Nil{}:
          pattern_finish(goal, pattern, tokens, scope, depth, True{})
    case _ PatternCompleted{pattern}:
      match frames:
        case PatternFrameOf{key, beg, end, fields, root_scope, root_depth} <> parents:
          pattern_finish(goal, Ast.PatternCtr{key, List.reverse(&2, Ast.SyntaxPattern, pattern <> fields), span(file, beg, end)}, tokens, root_scope, root_depth, False{})
        case Nil{}:
          pattern_finish(goal, pattern, tokens, scope, depth, True{})
    case _ PatternExpect{quantity, +beg}:
      match frames:
        case PatternFrameOf{key, start, end, fields, root_scope, root_depth} <> parents:
          pattern_finish(goal, Ast.PatternCtr{key, List.reverse(&2, Ast.SyntaxPattern, fields), span(file, start, end)}, tokens, root_scope, root_depth, False{})
        case Nil{}:
          pattern_finish(goal, Ast.PatternVar{"", depth, quantity, span(file, beg, beg)}, tokens, scope, depth, False{})

def pattern_single_result(result: PatternScanOutcome, file: String, depth: Nat) -> (Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool):
  match result:
    case PatternSingleOutcome{pattern, after, scope, next_depth, ok}:
      ((pattern, after), ((scope, next_depth), ok))
    case PatternCaseOutcome{patterns, after, scope, next_depth, ok}:
      ((Ast.PatternVar{"", depth, Ast.QOne{}, span(file, 0n, 0n)}, after), ((scope, next_depth), False{}))

def parse_pattern_atom(+file: String, tokens: List<&2, Lexer.Token>, scope: List<&2, Scope>, +depth: Nat) -> (Ast.SyntaxPattern & List<&2, Lexer.Token>) & ((List<&2, Scope> & Nat) & Bool):
  pattern_single_result(pattern_scan(tokens, file, PatternExpect{Ast.QOne{}, 0n}, Nil{}, scope, depth, PatternSingleGoal{}), file, depth)

def step_parse_destructuring_local(+file: String, +tokens: List<&2, Lexer.Token>, beg: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  feedback_consumer_208732(parse_pattern_atom(file, tokens, scope, depth), file, tokens, beg, col, scope, depth)

def feedback_make_Kont_206151(lexical_capture_1: String, lexical_capture_3: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_9: Nat, lexical_capture_14: List<&2, Scope>, lexical_capture_16: Nat, lexical_capture_17: Ast.Quantity) -> FeedbackFrame:
  Kont_206151{lexical_capture_1, lexical_capture_3, lexical_capture_5, lexical_capture_7, lexical_capture_9, lexical_capture_14, lexical_capture_16, lexical_capture_17}

def step_parse_local_body(+file: String, key: String, beg: Nat, key_end: Nat, col: Nat, tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, quantity: Ast.Quantity) -> FeedbackControl:
  feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_206151(file, key, beg, key_end, col, scope, depth, quantity))

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

def feedback_make_Kont_211342(lexical_capture_1: String, lexical_capture_5: Nat, lexical_capture_7: Nat, lexical_capture_10: List<&2, Scope>, lexical_capture_12: Nat) -> FeedbackFrame:
  Kont_211342{lexical_capture_1, lexical_capture_5, lexical_capture_7, lexical_capture_10, lexical_capture_12}

def feedback_make_Kont_213847(lexical_capture_1: String, lexical_capture_6: List<&2, Scope>, lexical_capture_8: Nat, lexical_capture_10: List<&2, Ast.SyntaxTerm>) -> FeedbackFrame:
  Kont_213847{lexical_capture_1, lexical_capture_6, lexical_capture_8, lexical_capture_10}

def step_parse_terms_until_colon(+file: String, +tokens: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +acc: List<&2, Ast.SyntaxTerm>) -> FeedbackControl:
  match tokens:
    case +token <> rest:
      match token:
        case Lexer.TokenInfo{ _, ":",  _,  _,  _,  _}:
          feedback_pack_8(((List.reverse(&2, Ast.SyntaxTerm, acc), tokens), True{}))
        case _:
          feedback_attach(step_parse_term(file, tokens, scope, depth, 0n), feedback_make_Kont_213847(file, scope, depth, acc))
    case Nil{}:
      feedback_pack_8(((List.reverse(&2, Ast.SyntaxTerm, acc), Nil{}), False{}))

def step_parse_match_body(+file: String, tokens: List<&2, Lexer.Token>, beg: Nat, col: Nat, +scope: List<&2, Scope>, +depth: Nat) -> FeedbackControl:
  feedback_attach(step_parse_terms_until_colon(file, tokens, scope, depth, Nil{}), feedback_make_Kont_211342(file, beg, col, scope, depth))

def step_parse_body_scan(+file: String, +tokens: List<&2, Lexer.Token>, scanned: List<&2, Lexer.Token>, +scope: List<&2, Scope>, +depth: Nat, +parent_col: Nat) -> FeedbackControl:
  match scanned:
    case +token <> +rest:
      match token:
        case Lexer.TokenInfo{ Lexer.NameToken{},  "match", beg,  _,  _, col}:
          step_parse_match_body(file, rest, beg, col, scope, depth)
        case Lexer.TokenInfo{ Lexer.NameToken{},  +key, +beg, +end,  _, col}:
          match rest:
            case +next <> after_next:
              match next:
                case Lexer.TokenInfo{ _, "=",  _,  _,  _,  _}:
                  step_parse_local_body(file, key, beg, end, parent_col, after_next, scope, depth, Ast.QOne{})
                case Lexer.TokenInfo{ _, "{",  _,  _,  _,  _}:
                  step_parse_destructuring_local(file, tokens, beg, parent_col, scope, depth)
                case Lexer.TokenInfo{ _, "[",  _,  _,  _,  _}:
                  step_decl_local_name_group(local_array_write(rest), True{}, file, tokens, token, rest, key, beg, end, parent_col, scope, depth)
                case _:
                  step_decl_local_name_group(local_group_has_equal(rest), False{}, file, tokens, token, rest, key, beg, end, parent_col, scope, depth)
            case _:
              step_parse_reply(file, tokens, scope, depth)
        case Lexer.TokenInfo{ Lexer.SymbolToken{},  "+", beg,  _,  _, col}:
          step_decl_parallel_or_reply(local_group_has_equal(rest), file, tokens, rest, beg, parent_col, scope, depth, Ast.QMany{})
        case Lexer.TokenInfo{ Lexer.SymbolToken{},  "-", beg,  _,  _, col}:
          step_parse_erased_local(file, rest, beg, parent_col, scope, depth)
        case _:
          step_parse_reply(file, tokens, scope, depth)
    case Nil{}:
      feedback_pack_4(((Ast.TermHole{ "parse-error: expected a body",  span(file, 0n, 0n)}, Nil{}), False{}))

