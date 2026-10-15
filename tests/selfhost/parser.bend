import Base
import ../../bend2/selfhost/parser.bend as Parser
import ../../bend2/selfhost/ast.bend as Ast

law main:
  IO(Unit)

def identity_scope(module: Ast.Module) -> Bool:
  match module:
    case Ast.Module{ _,  _,  Ast.DefTop{ Ast.Definition{ _,  _,  _,  Ast.DefTerm{ Ast.BodyReply{term, _}},  _,  _}} <> _}:
      match term:
        case Ast.TermLam{ None{},  _,  0n,  Ast.TermVar{ _,  0n,  _},  _}:
          True{}
        case _:
          False{}
    case _:
      False{}


def many_lambda_scope(module: Ast.Module) -> Bool:
  match module:
    case Ast.Module{ _,  _,  Ast.DefTop{ Ast.Definition{ _,  _,  _,  Ast.DefTerm{ Ast.BodyReply{ Ast.TermLam{ Some{ Ast.QMany{}},  "x",  0n,  Ast.TermVar{ "x",  0n,  _},  _},  _}},  _,  _}} <> _}:
      True{}
    case _:
      False{}

def type_fields_scope(module: Ast.Module) -> Bool:
  match module:
    case Ast.Module{ _,  _,  Ast.TypeTop{ Ast.TypeDecl{ "Box",  [Ast.Binder{ _,  "a",  0n,  _,  _}],  _,  [Ast.Constructor{ "Box",  [Ast.Binder{ _,  "value",  1n,  Ast.TermVar{ "a",  0n,  _},  _}],  _}],  _}} <> _}:
      True{}
    case _:
      False{}
def has_base_import(module: Ast.Module) -> Bool:
  match module:
    case Ast.Module{ "imports.bend",  Ast.ModuleImport{ "Base",  "Base",  Ast.SpanOf{ "imports.bend",  0n,  11n}} <> Nil{},  _}:
      True{}
    case _:
      False{}
def has_named_import(module: Ast.Module) -> Bool:
  match module:
    case Ast.Module{ "alias.bend",  Ast.ModuleImport{ "lib.bend",  "Lib",  Ast.SpanOf{ "alias.bend",  0n,  24n}} <> Nil{},  _}:
      True{}
    case _:
      False{}

def law_clause_scope(module: Ast.Module) -> Bool:
  match module:
    case Ast.Module{ _,  _,  Ast.LawTop{ Ast.LawDecl{ "Claim",  Ast.ClauseFor{ True{},  Ast.QMany{},  "x",  _,  Some{ Ast.TermVar{ "x",  0n,  _}},  _} <> Nil{},  Ast.BodyReply{ _, _},  _}} <> Nil{}}:
      True{}
    case _:
      False{}

def match_pattern_scope(module: Ast.Module) -> Bool:
  match module:
    case Ast.Module{ _,  _,  Ast.DefTop{ Ast.Definition{ _,  _,  _,  Ast.DefTerm{ Ast.BodyMatch{ [Ast.TermRef{ "x",  _}, Ast.TermRef{ "y",  _}],  [Ast.BodyCase{ [Ast.PatternCtr{ "C",  [Ast.PatternVar{ "a",  0n,  Ast.QOne{},  _}],  _}, Ast.PatternVar{ "b",  1n,  Ast.QOne{},  _}],  Ast.BodyReply{ Ast.TermVar{ "a",  1n,  _},  _},  _}],  _}},  _,  _}} <> _}:
      True{}
    case _:
      False{}
def nat_pattern_sugar(module: Ast.Module) -> Bool:
  match module:
    case Ast.Module{ _,  _,  Ast.DefTop{ Ast.Definition{ _,  _,  _,  Ast.DefTerm{ Ast.BodyMatch{ [_],  [Ast.BodyCase{ [Ast.PatternCtr{ "Succ",  [Ast.PatternCtr{ "Succ",  [Ast.PatternCtr{ "Zero",  [],  _}],  _}],  _}],  _,  _}],  _}},  _,  _}} <> _}:
      True{}
    case _:
      False{}

def f32_literal(module: Ast.Module) -> Bool:
  match module:
    case Ast.Module{ _,  _,  Ast.DefTop{ Ast.Definition{ _,  _,  _,  Ast.DefTerm{ Ast.BodyReply{ Ast.TermCtr{ "F32",  [_],  _},  _}},  _,  _}} <> _}:
      True{}
    case _:
      False{}

def parallel_let_scope(module: Ast.Module) -> Bool:
  match module:
    case Ast.Module{ _,  _,  Ast.DefTop{ Ast.Definition{ _,  _,  _,  Ast.DefTerm{ Ast.BodyLocal{ [Ast.PatternVar{ "x",  0n,  Ast.QOne{},  _}, Ast.PatternVar{ "y",  1n,  Ast.QOne{},  _}],  Ast.QOne{},  [Ast.TermCtr{ "U32",  _,  _}, Ast.TermCtr{ "U32",  _,  _}],  Ast.BodyReply{ Ast.TermVar{ "y",  0n,  _},  _},  _}},  _,  _}} <> _}:
      True{}
    case _:
      False{}

def operator_precedence(module: Ast.Module) -> Bool:
  match module:
    case Ast.Module{ _,  _,  Ast.DefTop{ Ast.Definition{ _,  _,  _,  Ast.DefTerm{ Ast.BodyReply{ Ast.TermApp{ Ast.TermApp{ Ast.TermRef{ ".add",  _},  Ast.TermCtr{ "U32",  _,  _},  _},  Ast.TermApp{ Ast.TermApp{ Ast.TermRef{ ".mul",  _},  Ast.TermCtr{ "U32",  _,  _},  _},  Ast.TermCtr{ "U32",  _,  _},  _},  _},  _}},  _,  _}} <> _}:
      True{}
    case _:
      False{}

def annotation_term(module: Ast.Module) -> Bool:
  match module:
    case Ast.Module{ _,  _,  Ast.DefTop{ Ast.Definition{ _,  _,  _,  Ast.DefTerm{ Ast.BodyReply{ Ast.TermAnn{ Ast.TermType{ _,  _},  Ast.TermType{ _,  _},  _},  _}},  _,  _}} <> _}:
      True{}
    case _:
      False{}

def do_typed_assignment(module: Ast.Module) -> Bool:
  match module:
    case Ast.Module{ _,  _,  Ast.DefTop{ Ast.Definition{ _,  _,  _,  Ast.DefTerm{ Ast.BodyReply{ Ast.TermLet{ ["x"],  [0n],  [Ast.QOne{}],  [Ast.TermAnn{ Ast.TermType{ _,  _},  Ast.TermType{ _,  _},  _}],  Ast.TermApp{ Ast.TermRef{ "M.pure",  _},  Ast.TermVar{ "x",  0n,  _},  _},  _},  _}},  _,  _}} <> _}:
      True{}
    case _:
      False{}

def template_syntax(module: Ast.Module) -> Bool:
  match module:
    case Ast.Module{ _,  _,  Ast.DefTop{ Ast.Definition{ _,  [Ast.TemplateBinder{ "x",  0n,  Ast.TermType{ _,  _},  _}],  _,  Ast.DefTerm{ Ast.BodyReply{ Ast.TermApp{ Ast.TermRef{ "T",  _},  Ast.TermTemplate{ Ast.TermVar{ "x",  0n,  _},  _},  _},  _}},  _,  _}} <> _}:
      True{}
    case _:
      False{}
def fill_syntax(module: Ast.Module) -> Bool:
  match module:
    case Ast.Module{ _,  _,  Ast.DefTop{ Ast.Definition{ _,  _,  _,  Ast.DefTerm{ Ast.BodyReply{ Ast.TermFill{ Ast.TermRef{ "Box",  _},  [Ast.TermType{ _,  _}],  _},  _}},  _,  _}} <> _}:
      True{}
    case _:
      False{}

def plus_syntax(module: Ast.Module) -> Bool:
  match module:
    case Ast.Module{ _,  _,  Ast.DefTop{ Ast.Definition{ _,  _,  _,  Ast.DefTerm{ Ast.BodyReply{ Ast.TermPlus{ Ast.TermRef{ "Box",  _},  [Ast.TermType{ _,  _}],  _},  _}},  _,  _}} <> _}:
      True{}
    case _:
      False{}
def array_write_syntax(module: Ast.Module) -> Bool:
  match module:
    case Ast.Module{ _,  _,  Ast.DefTop{ Ast.Definition{ _,  _,  _,  Ast.DefTerm{ Ast.BodyLocal{ [Ast.PatternVar{ "a",  0n,  Ast.QOne{},  _}],  Ast.QOne{},  [Ast.TermApp{ Ast.TermApp{ Ast.TermApp{ Ast.TermApp{ Ast.TermRef{ "Array.set",  _},  _,  _},  _,  _},  _,  _},  _,  _}],  Ast.BodyReply{ Ast.TermVar{ "a",  0n,  _},  _},  _}},  _,  _}} <> _}:
      True{}
    case _:
      False{}
def multi_arm_mat(module: Ast.Module) -> Bool:
  match module:
    case Ast.Module{ _,  _,  Ast.DefTop{ Ast.Definition{ _,  _,  _,  Ast.DefTerm{ Ast.BodyReply{ Ast.TermMat{ "x",  Ast.TermType{ _,  _},  Ast.TermMat{ "y",  Ast.TermType{ _,  _},  Ast.TermType{ _,  _},  _},  _},  _}},  _,  _}} <> _}:
      True{}
    case _:
      False{}
def typed_operator_namespace(module: Ast.Module) -> Bool:
  match module:
    case Ast.Module{ _,  _,  Ast.DefTop{ Ast.Definition{ _,  _,  _,  Ast.DefTerm{ Ast.BodyReply{ Ast.TermApp{ Ast.TermApp{ Ast.TermRef{ "U32.add",  _},  Ast.TermCtr{ "U32",  _,  _},  _},  Ast.TermApp{ Ast.TermApp{ Ast.TermRef{ "U32.mul",  _},  Ast.TermCtr{ "U32",  _,  _},  _},  Ast.TermCtr{ "U32",  _,  _},  _},  _},  _}},  _,  _}} <> _}:
      True{}
    case _:
      False{}
def bang_call_shape(module: Ast.Module) -> Bool:
  match module:
    case Ast.Module{ _,  _,  Ast.DefTop{ Ast.Definition{ _,  _,  _,  Ast.DefTerm{ Ast.BodyReply{ Ast.TermApp{ Ast.TermApp{ Ast.TermBang{ Ast.TermRef{ "f",  _},  _},  Ast.TermRef{ "x",  _},  _},  Ast.TermRef{ "y",  _},  _},  _}},  _,  _}} <> _}:
      True{}
    case _:
      False{}

def report_bool(ok: Bool, success: String, failure: String) -> IO(Unit):
  match ok:
    case True{}:
      IO.print(success)
    case False{}:
      IO.print(failure)

def report_import(result: Parser.ParseResult) -> IO(Unit):
  match result:
    case Parser.ParseSuccess{module}:
      report_bool(has_base_import(module), "parser-import-ok", "parser-import-failed")
    case _:
      IO.print("parser-import-failed")

def report_alias_import(result: Parser.ParseResult) -> IO(Unit):
  match result:
    case Parser.ParseSuccess{module}:
      report_bool(has_named_import(module), "parser-import-alias-ok", "parser-import-alias-failed")
    case _:
      IO.print("parser-import-alias-failed")

def report_many_lambda(result: Parser.ParseResult) -> IO(Unit):
  match result:
    case Parser.ParseSuccess{module}:
      report_bool(many_lambda_scope(module), "parser-many-lambda-ok", "parser-many-lambda-failed")
    case _:
      IO.print("parser-many-lambda-failed")

def report_f32(result: Parser.ParseResult) -> IO(Unit):
  match result:
    case Parser.ParseSuccess{module}:
      report_bool(f32_literal(module), "parser-f32-ok", "parser-f32-failed")
    case _:
      IO.print("parser-f32-failed")

def report_type_scope(result: Parser.ParseResult) -> IO(Unit):
  match result:
    case Parser.ParseSuccess{module}:
      report_bool(type_fields_scope(module), "parser-type-scope-ok", "parser-type-scope-failed")
    case _:
      IO.print("parser-type-scope-failed")

def report_law_scope(result: Parser.ParseResult) -> IO(Unit):
  match result:
    case Parser.ParseSuccess{module}:
      report_bool(law_clause_scope(module), "parser-law-clause-ok", "parser-law-clause-failed")
    case _:
      IO.print("parser-law-clause-failed")

def report_match_pattern(result: Parser.ParseResult) -> IO(Unit):
  match result:
    case Parser.ParseSuccess{module}:
      report_bool(match_pattern_scope(module), "parser-match-pattern-ok", "parser-match-pattern-failed")
    case _:
      IO.print("parser-match-pattern-failed")

def report_parallel_let(result: Parser.ParseResult) -> IO(Unit):
  match result:
    case Parser.ParseSuccess{module}:
      report_bool(parallel_let_scope(module), "parser-parallel-let-ok", "parser-parallel-let-failed")
    case _:
      IO.print("parser-parallel-let-failed")

def report_operator_precedence(result: Parser.ParseResult) -> IO(Unit):
  match result:
    case Parser.ParseSuccess{module}:
      report_bool(operator_precedence(module), "parser-operator-precedence-ok", "parser-operator-precedence-failed")
    case _:
      IO.print("parser-operator-precedence-failed")

def report_annotation(result: Parser.ParseResult) -> IO(Unit):
  match result:
    case Parser.ParseSuccess{module}:
      report_bool(annotation_term(module), "parser-annotation-ok", "parser-annotation-failed")
    case _:
      IO.print("parser-annotation-failed")

def report_do_assignment(result: Parser.ParseResult) -> IO(Unit):
  match result:
    case Parser.ParseSuccess{module}:
      report_bool(do_typed_assignment(module), "parser-do-typed-assignment-ok", "parser-do-typed-assignment-failed")
    case _:
      IO.print("parser-do-typed-assignment-failed")

def report_template(result: Parser.ParseResult) -> IO(Unit):
  match result:
    case Parser.ParseSuccess{module}:
      report_bool(template_syntax(module), "parser-template-ok", "parser-template-failed")
    case _:
      IO.print("parser-template-failed")

def report_fill(result: Parser.ParseResult) -> IO(Unit):
  match result:
    case Parser.ParseSuccess{module}:
      report_bool(fill_syntax(module), "parser-fill-ok", "parser-fill-failed")
    case _:
      IO.print("parser-fill-failed")

def report_plus(result: Parser.ParseResult) -> IO(Unit):
  match result:
    case Parser.ParseSuccess{module}:
      report_bool(plus_syntax(module), "parser-plus-ok", "parser-plus-failed")
    case _:
      IO.print("parser-plus-failed")

def report_array_write(result: Parser.ParseResult) -> IO(Unit):
  match result:
    case Parser.ParseSuccess{module}:
      report_bool(array_write_syntax(module), "parser-array-write-ok", "parser-array-write-failed")
    case _:
      IO.print("parser-array-write-failed")

def report_multi_mat(result: Parser.ParseResult) -> IO(Unit):
  match result:
    case Parser.ParseSuccess{module}:
      report_bool(multi_arm_mat(module), "parser-multi-mat-ok", "parser-multi-mat-failed")
    case _:
      IO.print("parser-multi-mat-failed")

def report_typed_operator(result: Parser.ParseResult) -> IO(Unit):
  match result:
    case Parser.ParseSuccess{module}:
      report_bool(typed_operator_namespace(module), "parser-typed-operator-ok", "parser-typed-operator-failed")
    case _:
      IO.print("parser-typed-operator-failed")

def report_bang(result: Parser.ParseResult) -> IO(Unit):
  match result:
    case Parser.ParseSuccess{module}:
      report_bool(bang_call_shape(module), "parser-bang-ok", "parser-bang-failed")
    case _:
      IO.print("parser-bang-failed")

def report_invalid_bang(result: Parser.ParseResult) -> IO(Unit):
  match result:
    case Parser.ParseFailure{ _,  _,  _,  _}:
      IO.print("parser-bang-invalid-ok")
    case _:
      IO.print("parser-bang-invalid-failed")

def report_nat_pattern(result: Parser.ParseResult) -> IO(Unit):
  match result:
    case Parser.ParseSuccess{module}:
      report_bool(nat_pattern_sugar(module), "parser-nat-pattern-ok", "parser-nat-pattern-failed")
    case _:
      IO.print("parser-nat-pattern-failed")

def report_identity_scope(result: Parser.ParseResult) -> IO(Unit):
  match result:
    case Parser.ParseSuccess{module}:
      report_bool(identity_scope(module), "parser-scope-ok", "parser-scope-failed")
    case _:
      IO.print("parser-scope-failed")

def report_parser_contract(valid: Parser.ParseResult, invalid: Parser.ParseResult) -> IO(Unit):
  match valid invalid:
    case Parser.ParseSuccess{Ast.Module{ "demo.bend",  Nil{},  Ast.DefTop{ Ast.Definition{ "value",  _,  _,  _,  _,  Ast.SpanOf{ "demo.bend",  0n,  26n}}} <> _}} Parser.ParseFailure{ _,  "a supported declaration",  "(",  Ast.SpanOf{ "bad.bend",  0n,  1n}}:
      IO.print("parser-contract-ok")
    case _ _:
      IO.print("parser-contract-failed")


def main():
  do IO<Unit>:
    report_import(Parser.parse("imports.bend", "import Base\ndef value() -> Type : Type\n"))
    report_alias_import(Parser.parse("alias.bend", "import \"lib.bend\" as Lib\ndef aliasUser() -> Type : Type\n"))
    report_many_lambda(Parser.parse("many.bend", "def many() -> Type : +x => x\n"))
    report_f32(Parser.parse("float.bend", "def float() -> Type : 1.5\n"))
    report_type_scope(Parser.parse("typed.bend", "type Box<a: Type> is Type:\n  Box{value: a}\n"))
    report_law_scope(Parser.parse("law.bend", "law Claim:\n  for +x: Type where x\n  Type\n"))
    report_match_pattern(Parser.parse("match.bend", "def check() -> Type :\n  match x, y:\n    case C{a}, b:\n      a\n"))
    report_parallel_let(Parser.parse("parallel.bend", "def pair() -> Type :\n  x y = 1 2\n    y\n"))
    report_operator_precedence(Parser.parse("ops.bend", "def ops() -> Type : 1 + 2 * 3\n"))
    report_annotation(Parser.parse("annotation.bend", "def annotation() -> Type : {Type: Type}\n"))
    report_do_assignment(Parser.parse("do-assign.bend", "def doAssign() -> Type : do M<>: x: Type = Type; return x\n"))
    report_template(Parser.parse("template.bend", "def instantiate(~x: Type) -> Type : T(~x)\n"))
    report_fill(Parser.parse("fill.bend", "def fill() -> Type : Box<Type>\n"))
    report_plus(Parser.parse("plus.bend", "def plus() -> Type : +Box<Type>\n"))
    report_array_write(Parser.parse("array-write.bend", "def update() -> Type :\n  a[i] <- v\n    a\n"))
    report_multi_mat(Parser.parse("mat.bend", "def mat() -> Type : \\{x: Type; y: Type; Type}\n"))
    report_typed_operator(Parser.parse("typed-ops.bend", "def typedOps() -> Type : (1 + 2 * 3 : U32)\n"))
    report_bang(Parser.parse("bang.bend", "def bang() -> Type : f!(x, y)\n"))
    report_invalid_bang(Parser.parse("invalid-bang.bend", "def invalid(x: Type) -> Type : x!(x)\n"))
    report_nat_pattern(Parser.parse("nat-pattern.bend", "def check() -> Type :\n  match n:\n    case 2n:\n      Type\n"))
    report_identity_scope(Parser.parse("scope.bend", "def identity() -> Type : x => x\n"))
    report_parser_contract(Parser.parse("demo.bend", "def value() -> Type : Type\n"), Parser.parse("bad.bend", "(\n"))


#| parser-import-ok
#| parser-scope-ok
#| parser-contract-ok
#| parser-type-scope-ok
#| parser-law-clause-ok
#| parser-match-pattern-ok
#| parser-many-lambda-ok
#| parser-f32-ok
#| parser-parallel-let-ok
#| parser-operator-precedence-ok
#| parser-annotation-ok
#| parser-do-typed-assignment-ok
#| parser-template-ok
#| parser-fill-ok
#| parser-plus-ok
#| parser-array-write-ok
#| parser-multi-mat-ok
#| parser-typed-operator-ok
#| parser-nat-pattern-ok
#| parser-import-alias-ok
#| parser-bang-ok
#| parser-bang-invalid-ok