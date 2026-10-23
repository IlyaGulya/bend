import Base
import ../../bend2/selfhost/ast.bend as Ast
import ../../bend2/selfhost/checker.bend as Checker
import ../../bend2/selfhost/checked_frontend.bend as Checked
import ../../bend2/selfhost/loaded_module.bend as Loader

def marked_identity_application(term: Ast.SyntaxTerm) -> Bool:
  match term:
    case Ast.TermApp{fn,  _,  _}:
      match fn:
        case Ast.TermBang{ Ast.TermRef{key,  _},  _}: String.eq(key, "identity")
        case _: False{}
    case _: False{}

def marked_identity_declaration_key(matches: Bool, body: Ast.DefBody, rest: List<&2, Ast.TopLevel>) -> Bool:
  match matches body:
    case True{} Ast.DefTerm{term}: marked_identity_application(term)
    case True{} _: False{}
    case False{} _: marked_identity_declaration(rest)

def print_bang_preserved(preserved: Bool):
  match preserved:
    case True{}: IO.print("checker-bang-preserved")
    case False{}: IO.print("checker-bang-not-preserved")

def check_result_output(result: Checked.CheckResult, success: String, failure: String):
  match result:
    case Checked.CheckSuccess{_}: IO.print(success)
    case Checked.CheckFailure{_}: IO.print(failure)

def check_single_result_output(result: Checked.CheckResult, success: String, failure: String):
  match result:
    case Checked.CheckSuccess{Checked.CheckedProgram{_, modules, _, _}}:
      match modules:
        case [_]: IO.print(success)
        case _: IO.print(failure)
    case Checked.CheckFailure{_}: IO.print(failure)

def check_triple_result_output(result: Checked.CheckResult, success: String, failure: String):
  match result:
    case Checked.CheckSuccess{Checked.CheckedProgram{_, modules, _, _}}:
      match modules:
        case [_, _, _]: IO.print(success)
        case _: IO.print(failure)
    case Checked.CheckFailure{_}: IO.print(failure)

def check_dependent_application(result: Checked.CheckResult):
  match result:
    case Checked.CheckSuccess{program}:
      IO.print("checker-dependent-application-ok")
      IO.print("checker-bang-head-ok")
      print_bang_inspection(Checker.inspect_checked(program))
    case Checked.CheckFailure{_}: IO.print("checker-dependent-application-failed")

def print_bang_inspection(inspection: Checked.Inspection):
  match inspection:
    case Checked.Inspection{_, modules}: print_bang_preserved(returned_bang_preserved(modules))
    case Checked.InspectionFailure{_, Checked.Diagnostic{_, _, message, _, _}}:
      IO.print("checker-inspection-failed: " ++ message)

def marked_identity_declaration(declarations: List<&2, Ast.TopLevel>) -> Bool:
  match declarations:
    case Nil{}: False{}
    case +declaration <> rest:
      match declaration:
        case Ast.DefTop{ Ast.Definition{key,  _,  _, body,  _,  _}}:
          marked_identity_declaration_key(String.eq(key, "use_identity"), body, rest)
        case _: marked_identity_declaration(rest)

def returned_bang_preserved(modules: List<&2, Loader.LoadedModule>) -> Bool:
  match modules:
    case +loaded <> _:
      match loaded:
        case Loader.LoadedModule{ _,  Ast.Module{ _,  _, declarations}}: marked_identity_declaration(declarations)
    case Nil{}: False{}
def check_bool_module_result(result: Checked.CheckResult):
  match result:
    case Checked.CheckSuccess{Checked.CheckedProgram{_, modules, _, _}}:
      match modules:
        case [_]:
          IO.print("checker-constructor-typing-ok")
          IO.print("checker-multi-column-match-ok")
          IO.print("checker-dependent-pattern-match-ok")
          IO.print("checker-field-pattern-match-ok")
          IO.print("checker-parameter-match-ok")
          IO.print("checker-erased-argument-ok")
          IO.print("checker-erased-constructor-field-ok")
          IO.print("checker-erased-local-function-ok")
          IO.print("checker-let-function-quantity-ok")
          IO.print("checker-pattern-function-quantity-ok")
          IO.print("checker-nested-lambda-quantity-ok")
          IO.print("checker-branch-use-alternatives-ok")
          IO.print("checker-pattern-field-scaling-ok")
        case _: IO.print("checker-constructor-typing-failed")
    case Checked.CheckFailure{_}: IO.print("checker-constructor-typing-failed")

def check_nested_result(result: Checked.CheckResult):
  match result:
    case Checked.CheckSuccess{Checked.CheckedProgram{_, modules, _, _}}:
      match modules:
        case [_]:
          IO.print("checker-nested-match-ok")
          IO.print("checker-nested-matrix-match-ok")
        case _: IO.print("checker-nested-match-failed")
    case Checked.CheckFailure{_}: IO.print("checker-nested-match-failed")

def check_exhaustiveness_result(result: Checked.CheckResult):
  match result:
    case Checked.CheckFailure{_}: IO.print("checker-exhaustiveness-error")
    case Checked.CheckSuccess{_}: IO.print("checker-exhaustiveness-accepted")

def check_affine_result(result: Checked.CheckResult):
  match result:
    case Checked.CheckFailure{Checked.Diagnostic{_, _, _, _, _}}: IO.print("checker-affine-duplicate-rejected")
    case Checked.CheckSuccess{_}: IO.print("checker-affine-duplicate-accepted")

law main:
  IO(Unit)

def main():
  sp = Ast.SpanOf{ "check.bend",  0n,  1n}
  type_term = Ast.TermType{ Ast.TermQuantity{ Ast.QOne{},  sp},  sp}
  data_kind = Ast.TermType{ Ast.TermQuantity{ Ast.QMany{},  sp},  sp}
  identity = Ast.Definition{
     "identity",
     [Ast.Binder{ Ast.QOne{},  "x",  0n,  type_term,  sp}],
     Ast.NoTerm{},
     Ast.DefTerm{ Ast.TermVar{ "x",  0n,  sp}},
     False{},
     sp
  }
  use_identity = Ast.Definition{
     "use_identity",
     Nil{},
     Ast.SomeTerm{ type_term},
     Ast.DefTerm{ Ast.TermApp{
       Ast.TermBang{ Ast.TermRef{ "identity",  sp},  sp},
       type_term,
       sp
    }},
     False{},
     sp
  }
  beta = Ast.Definition{
     "beta",
     Nil{},
     Ast.SomeTerm{ type_term},
     Ast.DefTerm{ Ast.TermApp{
       Ast.TermLam{ None{},  "z",  0n,  Ast.TermVar{ "z",  0n,  sp},  sp},
       type_term,
       sp
    }},
     False{},
     sp
  }
  beta_conversion_type = Ast.TermApp{
     Ast.TermLam{ None{},  "t",  0n,  Ast.TermVar{ "t",  0n,  sp},  sp},
     type_term,
     sp
  }
  beta_conversion = Ast.Definition{
     "beta_conversion",
     Nil{},
     Ast.SomeTerm{ beta_conversion_type},
     Ast.DefTerm{ type_term},
     False{},
     sp
  }
  module = Ast.Module{
     "check.bend",
     Nil{},
     [Ast.DefTop{ identity}, Ast.DefTop{ use_identity}, Ast.DefTop{ beta}, Ast.DefTop{ beta_conversion}]
  }
  loaded = Loader.LoadedModule{ "", module}
  check_dependent_application(Checker.check([loaded]))
  local_binding = Ast.Definition{
     "local_binding",
     Nil{},
     Ast.NoTerm{},
     Ast.DefTerm{ Ast.BodyLocal{ [Ast.PatternVar{ "local",  0n,  Ast.QOne{},  sp}],  Ast.QOne{},  [type_term],  Ast.TermVar{ "local",  0n,  sp},  sp}},
     False{},
     sp
  }
  local_module = Ast.Module{ "local.bend",  Nil{},  [Ast.DefTop{ local_binding}]}
  local_loaded = Loader.LoadedModule{ "",  local_module}
  check_single_result_output(Checker.check([local_loaded]), "checker-local-binding-ok", "checker-local-binding-failed")
  invalid_bang = Ast.Definition{ "invalid_bang",  Nil{},  Ast.NoTerm{},  Ast.DefTerm{ Ast.TermBang{ Ast.TermRef{ "identity",  sp},  sp}},  False{},  sp}
  invalid_bang_module = Ast.Module{ "invalid_bang.bend",  Nil{},  [Ast.DefTop{ identity}, Ast.DefTop{ invalid_bang}]}
  invalid_bang_loaded = Loader.LoadedModule{ "",  invalid_bang_module}
  check_result_output(Checker.check([invalid_bang_loaded]), "checker-standalone-bang-accepted", "checker-standalone-bang-rejected")

  invalid_bang_argument = Ast.Definition{ "invalid_bang_argument",  Nil{},  Ast.SomeTerm{ type_term},  Ast.DefTerm{ Ast.TermApp{ Ast.TermLam{ None{},  "ignored",  0n,  type_term,  sp},  Ast.TermBang{ Ast.TermRef{ "identity",  sp},  sp},  sp}},  False{},  sp}
  invalid_bang_argument_module = Ast.Module{ "invalid_bang_argument.bend",  Nil{},  [Ast.DefTop{ identity}, Ast.DefTop{ invalid_bang_argument}]}
  invalid_bang_argument_loaded = Loader.LoadedModule{ "",  invalid_bang_argument_module}
  check_result_output(Checker.check([invalid_bang_argument_loaded]), "checker-bang-argument-accepted", "checker-bang-argument-rejected")

  constant = Ast.Definition{ "constant",  Nil{},  Ast.SomeTerm{ type_term},  Ast.DefTerm{ type_term},  False{},  sp}
  dep_module = Ast.Module{ "dep.bend",  Nil{},  [Ast.DefTop{ identity}, Ast.DefTop{ constant}]}
  dep_loaded = Loader.LoadedModule{ "dep",  dep_module}
  dep2_span = Ast.SpanOf{ "dep2.bend",  0n,  0n}
  dep2_import = Ast.ModuleImport{ "dep.bend",  "D",  dep2_span}
  alias_constant = Ast.Definition{ "alias_constant",  Nil{},  Ast.NoTerm{},  Ast.DefTerm{ Ast.TermRef{ "D.constant",  dep2_span}},  False{},  dep2_span}
  dep2_module = Ast.Module{ "dep2.bend",  [dep2_import],  [Ast.DefTop{ alias_constant}]}
  dep2_loaded = Loader.LoadedModule{ "dep2",  dep2_module}
  root_span = Ast.SpanOf{ "root.bend",  0n,  0n}
  imported = Ast.ModuleImport{ "dep.bend",  "Dep",  root_span}
  imported_two = Ast.ModuleImport{ "dep2.bend",  "Dep2",  root_span}
  imported_use = Ast.Definition{
     "imported_use",
     Nil{},
     Ast.SomeTerm{ type_term},
     Ast.DefTerm{ Ast.TermApp{
       Ast.TermRef{ "Dep.identity",  root_span},
       type_term,
       root_span
    }},
     False{},
     root_span
  }
  alias_value_use = Ast.Definition{ "alias_value_use",  Nil{},  Ast.SomeTerm{ Ast.TermRef{ "Dep2.alias_constant",  root_span}},  Ast.DefTerm{ type_term},  False{},  root_span}
  root_module = Ast.Module{ "root.bend",  [imported, imported_two],  [Ast.DefTop{ imported_use}, Ast.DefTop{ alias_value_use}]}
  root_loaded = Loader.LoadedModule{ "",  root_module}
  check_triple_result_output(Checker.check([dep_loaded, dep2_loaded, root_loaded]), "checker-import-alias-ok", "checker-import-alias-failed")

  bool_type = Ast.TypeDecl{
     "Bool",
     Nil{},
     data_kind,
     [Ast.Constructor{ "True",  Nil{},  sp}, Ast.Constructor{ "False",  Nil{},  sp}, Ast.Constructor{ "Wrap",  [Ast.Binder{ Ast.QOne{},  "value",  0n,  Ast.TermAdt{ "Bool",  Nil{},  Nil{},  sp},  sp}],  sp}],
     sp
  }
  truth = Ast.Definition{
     "truth",
     Nil{},
     Ast.SomeTerm{ Ast.TermAdt{ "Bool",  Nil{},  Nil{},  sp}},
     Ast.DefTerm{ Ast.TermCtr{ "True",  Nil{},  sp}},
     False{},
     sp
  }
  wrapped_truth = Ast.Definition{
     "wrapped_truth",
     Nil{},
     Ast.SomeTerm{ Ast.TermAdt{ "Bool",  Nil{},  Nil{},  sp}},
     Ast.DefTerm{ Ast.TermCtr{ "Wrap",  [Ast.TermCtr{ "True",  Nil{},  sp}],  sp}},
     False{},
     sp
  }
  promoted_lambda = Ast.Definition{
     "promoted_lambda",
     Nil{},
     Ast.SomeTerm{ Ast.TermAll{ Ast.QOne{},  "value",  0n,  Ast.TermAdt{ "Bool",  Nil{},  Nil{},  sp},  type_term,  sp}},
     Ast.DefTerm{ Ast.TermLam{ Some{ Ast.QMany{}},  "value",  0n,  type_term,  sp}},
     False{},
     sp
  }
  bit_type = Ast.TypeDecl{ "Bit",  Nil{},  data_kind,  [Ast.Constructor{ "B0",  Nil{},  sp}, Ast.Constructor{ "B1",  Nil{},  sp}],  sp}
  one_box_type = Ast.TypeDecl{ "OneBox",  Nil{},  data_kind,  [Ast.Constructor{ "OneBoxCtr",  [Ast.Binder{ Ast.QOne{},  "value",  0n,  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  sp}],  sp}],  sp}
  one_fn_box_type = Ast.TypeDecl{ "OneFnBox",  Nil{},  data_kind,  [Ast.Constructor{ "OneFnBoxCtr",  [Ast.Binder{ Ast.QOne{},  "fn",  0n,  Ast.TermAll{ Ast.QZero{},  "erased",  0n,  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  sp},  sp}],  sp}],  sp}
  pair_match = Ast.Definition{
     "pair_match",
     [Ast.Binder{ Ast.QOne{},  "x",  0n,  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  sp}, Ast.Binder{ Ast.QOne{},  "y",  1n,  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  sp}],
     Ast.SomeTerm{ Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp}},
     Ast.DefTerm{ Ast.BodyMatch{
       [Ast.TermVar{ "x",  1n,  sp}, Ast.TermVar{ "y",  0n,  sp}],
       [
        Ast.BodyCase{ [Ast.PatternCtr{ "B0",  Nil{},  sp}, Ast.PatternCtr{ "B0",  Nil{},  sp}],  Ast.TermCtr{ "B0",  Nil{},  sp},  sp},
        Ast.BodyCase{ [Ast.PatternCtr{ "B0",  Nil{},  sp}, Ast.PatternCtr{ "B1",  Nil{},  sp}],  Ast.TermCtr{ "B0",  Nil{},  sp},  sp},
        Ast.BodyCase{ [Ast.PatternCtr{ "B1",  Nil{},  sp}, Ast.PatternCtr{ "B0",  Nil{},  sp}],  Ast.TermCtr{ "B0",  Nil{},  sp},  sp},
        Ast.BodyCase{ [Ast.PatternCtr{ "B1",  Nil{},  sp}, Ast.PatternCtr{ "B1",  Nil{},  sp}],  Ast.TermCtr{ "B0",  Nil{},  sp},  sp}
      ],
       sp
    }},
     False{},
     sp
  }
  dependent_pair_match = Ast.Definition{
     "dependent_pair_match",
     [Ast.Binder{ Ast.QOne{},  "x",  0n,  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  sp}, Ast.Binder{ Ast.QOne{},  "y",  1n,  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  sp}],
     Ast.SomeTerm{ Ast.TermEqual{ Ast.TermVar{ "x",  1n,  sp},  Ast.TermVar{ "x",  1n,  sp},  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  sp}},
     Ast.DefTerm{ Ast.BodyMatch{
       [Ast.TermVar{ "x",  1n,  sp}, Ast.TermVar{ "y",  0n,  sp}],
       [
        Ast.BodyCase{ [Ast.PatternCtr{ "B0",  Nil{},  sp}, Ast.PatternCtr{ "B0",  Nil{},  sp}],  Ast.TermRefl{ sp},  sp},
        Ast.BodyCase{ [Ast.PatternCtr{ "B0",  Nil{},  sp}, Ast.PatternCtr{ "B1",  Nil{},  sp}],  Ast.TermRefl{ sp},  sp},
        Ast.BodyCase{ [Ast.PatternCtr{ "B1",  Nil{},  sp}, Ast.PatternCtr{ "B0",  Nil{},  sp}],  Ast.TermRefl{ sp},  sp},
        Ast.BodyCase{ [Ast.PatternCtr{ "B1",  Nil{},  sp}, Ast.PatternCtr{ "B1",  Nil{},  sp}],  Ast.TermRefl{ sp},  sp}
      ],
       sp
    }},
     False{},
     sp
  }
  wrapped_pair_match = Ast.Definition{
     "wrapped_pair_match",
     [Ast.Binder{ Ast.QOne{},  "x",  0n,  Ast.TermAdt{ "Bool",  Nil{},  Nil{},  sp},  sp}, Ast.Binder{ Ast.QOne{},  "y",  1n,  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  sp}],
     Ast.SomeTerm{ Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp}},
     Ast.DefTerm{ Ast.BodyMatch{
       [Ast.TermVar{ "x",  1n,  sp}, Ast.TermVar{ "y",  0n,  sp}],
       [
        Ast.BodyCase{ [Ast.PatternCtr{ "True",  Nil{},  sp}, Ast.PatternCtr{ "B0",  Nil{},  sp}],  Ast.TermCtr{ "B0",  Nil{},  sp},  sp},
        Ast.BodyCase{ [Ast.PatternCtr{ "True",  Nil{},  sp}, Ast.PatternCtr{ "B1",  Nil{},  sp}],  Ast.TermCtr{ "B0",  Nil{},  sp},  sp},
        Ast.BodyCase{ [Ast.PatternCtr{ "False",  Nil{},  sp}, Ast.PatternCtr{ "B0",  Nil{},  sp}],  Ast.TermCtr{ "B0",  Nil{},  sp},  sp},
        Ast.BodyCase{ [Ast.PatternCtr{ "False",  Nil{},  sp}, Ast.PatternCtr{ "B1",  Nil{},  sp}],  Ast.TermCtr{ "B0",  Nil{},  sp},  sp},
        Ast.BodyCase{ [Ast.PatternCtr{ "Wrap",  [Ast.PatternVar{ "ignored",  2n,  Ast.QZero{},  sp}],  sp}, Ast.PatternCtr{ "B0",  Nil{},  sp}],  Ast.TermCtr{ "B0",  Nil{},  sp},  sp},
        Ast.BodyCase{ [Ast.PatternCtr{ "Wrap",  [Ast.PatternVar{ "ignored",  2n,  Ast.QZero{},  sp}],  sp}, Ast.PatternCtr{ "B1",  Nil{},  sp}],  Ast.TermCtr{ "B0",  Nil{},  sp},  sp}
      ],
       sp
    }},
     False{},
     sp
  }
  computed_match = Ast.Definition{
     "computed_match",
     Nil{},
     Ast.SomeTerm{ Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp}},
     Ast.DefTerm{ Ast.BodyMatch{
       [Ast.TermAnn{ Ast.TermCtr{ "B0",  Nil{},  sp},  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  sp}],
       [
        Ast.BodyCase{ [Ast.PatternCtr{ "B0",  Nil{},  sp}],  Ast.TermCtr{ "B0",  Nil{},  sp},  sp},
        Ast.BodyCase{ [Ast.PatternCtr{ "B1",  Nil{},  sp}],  Ast.TermCtr{ "B0",  Nil{},  sp},  sp}
      ],
       sp
    }},
     False{},
     sp
  }
  branch_use_once = Ast.Definition{ "branch_use_once",  [Ast.Binder{ Ast.QOne{},  "x",  0n,  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  sp}, Ast.Binder{ Ast.QOne{},  "input",  1n,  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  sp}],  Ast.SomeTerm{ Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp}},  Ast.DefTerm{ Ast.BodyMatch{ [Ast.TermVar{ "input",  0n,  sp}],  [Ast.BodyCase{ [Ast.PatternCtr{ "B0",  Nil{},  sp}],  Ast.TermVar{ "x",  1n,  sp},  sp}, Ast.BodyCase{ [Ast.PatternCtr{ "B1",  Nil{},  sp}],  Ast.TermVar{ "x",  1n,  sp},  sp}],  sp}},  False{},  sp}
  duplicate_bits = Ast.Definition{ "duplicate_bits",  [Ast.Binder{ Ast.QOne{},  "first",  0n,  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  sp}, Ast.Binder{ Ast.QOne{},  "second",  1n,  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  sp}],  Ast.SomeTerm{ Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp}},  Ast.DefTerm{ Ast.TermCtr{ "B0",  Nil{},  sp}},  False{},  sp}
  reuse_field = Ast.Definition{ "reuse_field",  [Ast.Binder{ Ast.QMany{},  "boxed",  0n,  Ast.TermAdt{ "OneBox",  Nil{},  Nil{},  sp},  sp}],  Ast.SomeTerm{ Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp}},  Ast.DefTerm{ Ast.BodyMatch{ [Ast.TermVar{ "boxed",  0n,  sp}],  [Ast.BodyCase{ [Ast.PatternCtr{ "OneBoxCtr",  [Ast.PatternVar{ "value",  1n,  Ast.QMany{},  sp}],  sp}],  Ast.TermApp{ Ast.TermApp{ Ast.TermRef{ "duplicate_bits",  sp},  Ast.TermVar{ "value",  0n,  sp},  sp},  Ast.TermVar{ "value",  0n,  sp},  sp},  sp}],  sp}},  False{},  sp}
  ignore_definition = Ast.Definition{ "ignore_bit",  [Ast.Binder{ Ast.QZero{},  "erased",  0n,  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  sp}],  Ast.SomeTerm{ Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp}},  Ast.DefTerm{ Ast.TermCtr{ "B0",  Nil{},  sp}},  False{},  sp}
  let_erased_application = Ast.Definition{ "let_erased_application",  [Ast.Binder{ Ast.QZero{},  "x",  0n,  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  sp}],  Ast.SomeTerm{ Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp}},  Ast.DefTerm{ Ast.TermLet{ ["fn"],  [0n],  [Ast.QOne{}],  [Ast.TermRef{ "ignore_bit",  sp}],  Ast.TermApp{ Ast.TermVar{ "fn",  0n,  sp},  Ast.TermVar{ "x",  1n,  sp},  sp},  sp}},  False{},  sp}
  pattern_erased_application = Ast.Definition{ "pattern_erased_application",  [Ast.Binder{ Ast.QZero{},  "x",  0n,  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  sp}, Ast.Binder{ Ast.QOne{},  "box",  1n,  Ast.TermAdt{ "OneFnBox",  Nil{},  Nil{},  sp},  sp}],  Ast.SomeTerm{ Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp}},  Ast.DefTerm{ Ast.BodyMatch{ [Ast.TermVar{ "box",  0n,  sp}],  [Ast.BodyCase{ [Ast.PatternCtr{ "OneFnBoxCtr",  [Ast.PatternVar{ "fn",  1n,  Ast.QOne{},  sp}],  sp}],  Ast.TermApp{ Ast.TermVar{ "fn",  0n,  sp},  Ast.TermVar{ "x",  2n,  sp},  sp},  sp}],  sp}},  False{},  sp}
  nested_lambda_erased_application = Ast.Definition{ "nested_lambda_erased_application",  [Ast.Binder{ Ast.QZero{},  "x",  0n,  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  sp}],  Ast.SomeTerm{ Ast.TermAll{ Ast.QOne{},  "fn",  0n,  Ast.TermAll{ Ast.QZero{},  "erased",  0n,  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  sp},  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  sp}},  Ast.DefTerm{ Ast.TermLam{ None{},  "fn",  0n,  Ast.TermApp{ Ast.TermVar{ "fn",  0n,  sp},  Ast.TermVar{ "x",  1n,  sp},  sp},  sp}},  False{},  sp}
  erased_application = Ast.Definition{ "erased_application",  [Ast.Binder{ Ast.QZero{},  "x",  0n,  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  sp}],  Ast.SomeTerm{ Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp}},  Ast.DefTerm{ Ast.TermApp{ Ast.TermRef{ "ignore_bit",  sp},  Ast.TermVar{ "x",  0n,  sp},  sp}},  False{},  sp}
  apply_erased_parameter = Ast.Definition{ "apply_erased_parameter",  [Ast.Binder{ Ast.QOne{},  "fn",  0n,  Ast.TermAll{ Ast.QZero{},  "erased",  0n,  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  sp},  sp}, Ast.Binder{ Ast.QZero{},  "x",  1n,  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  sp}],  Ast.SomeTerm{ Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp}},  Ast.DefTerm{ Ast.TermApp{ Ast.TermVar{ "fn",  1n,  sp},  Ast.TermVar{ "x",  0n,  sp},  sp}},  False{},  sp}
  erased_constructor_field = Ast.Definition{ "erased_constructor_field",  [Ast.Binder{ Ast.QZero{},  "x",  0n,  Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp},  sp}],  Ast.SomeTerm{ Ast.TermAdt{ "ErasedBox",  Nil{},  Nil{},  sp}},  Ast.DefTerm{ Ast.TermCtr{ "ErasedBoxCtr",  [Ast.TermVar{ "x",  0n,  sp}],  sp}},  False{},  sp}
  filled_bit = Ast.Definition{ "filled_bit",  Nil{},  Ast.SomeTerm{ Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp}},  Ast.DefTerm{ Ast.TermFill{ Ast.TermRef{ "Bit",  sp},  Nil{},  sp}},  False{},  sp}
  bool_module = Ast.Module{ "bool.bend",  Nil{},  [Ast.TypeTop{ bool_type}, Ast.TypeTop{ bit_type}, Ast.TypeTop{ one_box_type}, Ast.TypeTop{ erased_box_type}, Ast.TypeTop{ one_fn_box_type}, Ast.DefTop{ truth}, Ast.DefTop{ wrapped_truth}, Ast.DefTop{ promoted_lambda}, Ast.DefTop{ pair_match}, Ast.DefTop{ dependent_pair_match}, Ast.DefTop{ wrapped_pair_match}, Ast.DefTop{ branch_use_once}, Ast.DefTop{ duplicate_bits}, Ast.DefTop{ reuse_field}, Ast.DefTop{ ignore_definition}, Ast.DefTop{ let_erased_application}, Ast.DefTop{ pattern_erased_application}, Ast.DefTop{ nested_lambda_erased_application}, Ast.DefTop{ erased_application}, Ast.DefTop{ apply_erased_parameter}, Ast.DefTop{ erased_constructor_field}, Ast.DefTop{ filled_bit}]}
  bool_loaded = Loader.LoadedModule{ "",  bool_module}
  check_bool_module_result(Checker.check([bool_loaded]))
  computed_module = Ast.Module{ "computed-match.bend",  Nil{},  [Ast.TypeTop{ bit_type}, Ast.DefTop{ computed_match}]}
  computed_loaded = Loader.LoadedModule{ "",  computed_module}
  check_result_output(Checker.check([computed_loaded]), "checker-computed-match-accepted", "checker-computed-match-rejected")
  let_computed_match = Ast.Definition{ "let_computed_match",  Nil{},  Ast.SomeTerm{ Ast.TermAdt{ "Bit",  Nil{},  Nil{},  sp}},  Ast.DefTerm{ Ast.TermLet{ ["local"],  [0n],  [Ast.QOne{}],  [Ast.TermCtr{ "B0",  Nil{},  sp}],  Ast.BodyMatch{ [Ast.TermVar{ "local",  0n,  sp}],  [Ast.BodyCase{ [Ast.PatternCtr{ "B0",  Nil{},  sp}],  Ast.TermCtr{ "B0",  Nil{},  sp},  sp}],  sp},  sp}},  False{},  sp}
  let_match_module = Ast.Module{ "let-match.bend",  Nil{},  [Ast.TypeTop{ bit_type}, Ast.DefTop{ let_computed_match}]}
  let_match_loaded = Loader.LoadedModule{ "",  let_match_module}
  check_result_output(Checker.check([let_match_loaded]), "checker-let-bound-match-accepted", "checker-let-bound-match-rejected")
  collision = Ast.Definition{ "Bool",  Nil{},  Ast.NoTerm{},  Ast.DefTerm{ Ast.TermCtr{ "True",  Nil{},  sp}},  False{},  sp}
  collision_module = Ast.Module{ "collision.bend",  Nil{},  [Ast.TypeTop{ bool_type}, Ast.DefTop{ collision}]}
  collision_loaded = Loader.LoadedModule{ "",  collision_module}
  check_result_output(Checker.check([collision_loaded]), "checker-family-collision-accepted", "checker-family-collision-rejected")


  law = Ast.LawDecl{ "law_type",  Nil{},  type_term,  sp}
  law_fill = Ast.Definition{ "law_type",  Nil{},  Ast.NoTerm{},  Ast.DefTerm{ type_term},  False{},  sp}
  law_module = Ast.Module{ "law.bend",  Nil{},  [Ast.LawTop{ law}, Ast.DefTop{ law_fill}]}
  law_loaded = Loader.LoadedModule{ "",  law_module}
  check_single_result_output(Checker.check([law_loaded]), "checker-law-fill-ok", "checker-law-fill-failed")
  rewrite_equation_type = Ast.TermEqual{ type_term,  type_term,  type_term,  sp}
  rewrite_equation = Ast.TermAnn{ Ast.TermRefl{ sp},  rewrite_equation_type,  sp}
  rewrite_proof = Ast.TermLam{ None{},  "x",  0n,  Ast.TermLam{ None{},  "proof",  0n,  type_term,  sp},  sp}
  rewrite_definition = Ast.Definition{ "rewrite_identity",  Nil{},  Ast.SomeTerm{ type_term},  Ast.DefTerm{ Ast.TermRewrite{ rewrite_equation,  rewrite_proof,  type_term,  sp}},  False{},  sp}
  rewrite_module = Ast.Module{ "rewrite.bend",  Nil{},  [Ast.DefTop{ rewrite_definition}]}
  rewrite_loaded = Loader.LoadedModule{ "",  rewrite_module}
  check_single_result_output(Checker.check([rewrite_loaded]), "checker-rewrite-ok", "checker-rewrite-failed")

  io_type = Ast.Definition{ "IO",  Nil{},  Ast.SomeTerm{ type_term},  Ast.DefTerm{ type_term},  False{},  sp}
  foreign_import = Ast.Definition{ "foreign_call",  Nil{},  Ast.SomeTerm{ Ast.TermRef{ "IO",  sp}},  Ast.DefImports{ ["foreign.c"]},  False{},  sp}
  foreign_module = Ast.Module{ "foreign.bend",  Nil{},  [Ast.DefTop{ io_type}, Ast.DefTop{ foreign_import}]}
  foreign_loaded = Loader.LoadedModule{ "",  foreign_module}
  check_single_result_output(Checker.check([foreign_loaded]), "checker-foreign-io-ok", "checker-foreign-io-failed")
  io_alias = Ast.Definition{ "OtherIO",  Nil{},  Ast.SomeTerm{ type_term},  Ast.DefTerm{ Ast.TermRef{ "IO",  sp}},  False{},  sp}
  foreign_alias = Ast.Definition{ "foreign_alias",  Nil{},  Ast.SomeTerm{ Ast.TermRef{ "OtherIO",  sp}},  Ast.DefImports{ ["foreign.c"]},  False{},  sp}
  foreign_alias_module = Ast.Module{ "foreign_alias.bend",  Nil{},  [Ast.DefTop{ io_type}, Ast.DefTop{ io_alias}, Ast.DefTop{ foreign_alias}]}
  foreign_alias_loaded = Loader.LoadedModule{ "",  foreign_alias_module}
  check_result_output(Checker.check([foreign_alias_loaded]), "checker-foreign-alias-accepted", "checker-foreign-alias-rejected")

  nat_type = Ast.TypeDecl{ "NatN",  Nil{},  data_kind,  [Ast.Constructor{ "ZeroN",  Nil{},  sp}, Ast.Constructor{ "SuccN",  [Ast.Binder{ Ast.QOne{},  "predecessor",  0n,  Ast.TermAdt{ "NatN",  Nil{},  Nil{},  sp},  sp}],  sp}],  sp}
  recursive_match = Ast.Definition{
     "recursive_match",
     [Ast.Binder{ Ast.QOne{},  "n",  0n,  Ast.TermAdt{ "NatN",  Nil{},  Nil{},  sp},  sp}],
     Ast.SomeTerm{ Ast.TermAdt{ "NatN",  Nil{},  Nil{},  sp}},
     Ast.DefTerm{ Ast.BodyMatch{
       [Ast.TermVar{ "n",  0n,  sp}],
       [
        Ast.BodyCase{ [Ast.PatternCtr{ "ZeroN",  Nil{},  sp}],  Ast.TermCtr{ "ZeroN",  Nil{},  sp},  sp},
        Ast.BodyCase{ [Ast.PatternCtr{ "SuccN",  [Ast.PatternVar{ "predecessor",  1n,  Ast.QOne{},  sp}],  sp}],  Ast.TermApp{ Ast.TermRef{ "recursive_match",  sp},  Ast.TermVar{ "predecessor",  0n,  sp},  sp},  sp}
      ],
       sp
    }},
     False{},
     sp
  }
  recursive_module = Ast.Module{ "recursive.bend",  Nil{},  [Ast.TypeTop{ nat_type}, Ast.DefTop{ recursive_match}]}
  recursive_loaded = Loader.LoadedModule{ "",  recursive_module}
  check_single_result_output(Checker.check([recursive_loaded]), "checker-decreasing-recursion-ok", "checker-decreasing-recursion-failed")

  unit_type = Ast.TypeDecl{ "Unit",  Nil{},  data_kind,  [Ast.Constructor{ "Only",  Nil{},  sp}],  sp}
  box_type = Ast.TypeDecl{ "Box",  Nil{},  data_kind,  [Ast.Constructor{ "Boxed",  [Ast.Binder{ Ast.QOne{},  "value",  0n,  Ast.TermAdt{ "Unit",  Nil{},  Nil{},  sp},  sp}],  sp}],  sp}
  nested_match = Ast.Definition{
     "nested_match",
     [Ast.Binder{ Ast.QOne{},  "box",  0n,  Ast.TermAdt{ "Box",  Nil{},  Nil{},  sp},  sp}],
     Ast.SomeTerm{ Ast.TermAdt{ "Unit",  Nil{},  Nil{},  sp}},
     Ast.DefTerm{ Ast.BodyMatch{
       [Ast.TermVar{ "box",  0n,  sp}],
       [Ast.BodyCase{
         [Ast.PatternCtr{ "Boxed",  [Ast.PatternCtr{ "Only",  Nil{},  sp}],  sp}],
         Ast.TermCtr{ "Only",  Nil{},  sp},
         sp
      }],
       sp
    }},
     False{},
     sp
  }
  nested_pair_match = Ast.Definition{
     "nested_pair_match",
     [Ast.Binder{ Ast.QOne{},  "box",  0n,  Ast.TermAdt{ "Box",  Nil{},  Nil{},  sp},  sp}, Ast.Binder{ Ast.QOne{},  "unit",  1n,  Ast.TermAdt{ "Unit",  Nil{},  Nil{},  sp},  sp}],
     Ast.SomeTerm{ Ast.TermAdt{ "Unit",  Nil{},  Nil{},  sp}},
     Ast.DefTerm{ Ast.BodyMatch{
       [Ast.TermVar{ "box",  1n,  sp}, Ast.TermVar{ "unit",  0n,  sp}],
       [Ast.BodyCase{ [Ast.PatternCtr{ "Boxed",  [Ast.PatternCtr{ "Only",  Nil{},  sp}],  sp}, Ast.PatternCtr{ "Only",  Nil{},  sp}],  Ast.TermCtr{ "Only",  Nil{},  sp},  sp}],
       sp
    }},
     False{},
     sp
  }
  nested_module = Ast.Module{ "nested.bend",  Nil{},  [Ast.TypeTop{ unit_type}, Ast.TypeTop{ box_type}, Ast.DefTop{ nested_match}, Ast.DefTop{ nested_pair_match}]}
  nested_loaded = Loader.LoadedModule{ "",  nested_module}
  check_nested_result(Checker.check([nested_loaded]))

  choice_type = Ast.TypeDecl{ "Choice",  Nil{},  data_kind,  [Ast.Constructor{ "Choice0",  Nil{},  sp}, Ast.Constructor{ "Choice1",  Nil{},  sp}],  sp}
  choice_box_type = Ast.TypeDecl{ "ChoiceBox",  Nil{},  data_kind,  [Ast.Constructor{ "ChoiceBoxed",  [Ast.Binder{ Ast.QOne{},  "choice",  0n,  Ast.TermAdt{ "Choice",  Nil{},  Nil{},  sp},  sp}],  sp}],  sp}
  incomplete_nested = Ast.Definition{
     "incomplete_nested",
     [Ast.Binder{ Ast.QOne{},  "box",  0n,  Ast.TermAdt{ "ChoiceBox",  Nil{},  Nil{},  sp},  sp}],
     Ast.SomeTerm{ Ast.TermAdt{ "Unit",  Nil{},  Nil{},  sp}},
     Ast.DefTerm{ Ast.BodyMatch{
       [Ast.TermVar{ "box",  0n,  sp}],
       [Ast.BodyCase{ [Ast.PatternCtr{ "ChoiceBoxed",  [Ast.PatternCtr{ "Choice0",  Nil{},  sp}],  sp}],  Ast.TermCtr{ "Only",  Nil{},  sp},  sp}],
       sp
    }},
     False{},
     sp
  }
  incomplete_nested_module = Ast.Module{ "nested-incomplete.bend",  Nil{},  [Ast.TypeTop{ unit_type}, Ast.TypeTop{ choice_type}, Ast.TypeTop{ choice_box_type}, Ast.DefTop{ incomplete_nested}]}
  incomplete_nested_loaded = Loader.LoadedModule{ "",  incomplete_nested_module}
  check_result_output(Checker.check([incomplete_nested_loaded]), "checker-nested-exhaustiveness-accepted", "checker-nested-exhaustiveness-rejected")

  incomplete = Ast.Definition{
     "incomplete",
     Nil{},
     Ast.SomeTerm{ Ast.TermAll{
       Ast.QOne{},
       "value",
       0n,
       Ast.TermAdt{ "Bool",  Nil{},  Nil{},  sp},
       type_term,
       sp
    }},
     Ast.DefTerm{ Ast.TermAbsurd{ sp}},
     False{},
     sp
  }
  incomplete_module = Ast.Module{ "incomplete.bend",  Nil{},  [Ast.TypeTop{ bool_type}, Ast.DefTop{ incomplete}]}
  incomplete_loaded = Loader.LoadedModule{ "",  incomplete_module}
  check_exhaustiveness_result(Checker.check([incomplete_loaded]))

  duplicate = Ast.Definition{
     "duplicate",
     [Ast.Binder{ Ast.QOne{},  "q",  0n,  Ast.TermQuant{},  sp}],
     Ast.NoTerm{},
     Ast.DefTerm{ Ast.TermMin{
       Ast.TermVar{ "q",  0n,  sp},
       Ast.TermVar{ "q",  0n,  sp},
       sp
    }},
     False{},
     sp
  }
  duplicate_module = Ast.Module{ "affine.bend",  Nil{},  [Ast.DefTop{ duplicate}]}
  duplicate_loaded = Loader.LoadedModule{ "",  duplicate_module}
  check_affine_result(Checker.check([duplicate_loaded]))
  loop_definition = Ast.Definition{
     "loop",
     Nil{},
     Ast.SomeTerm{ type_term},
     Ast.DefTerm{ Ast.TermRef{ "loop",  sp}},
     False{},
     sp
  }
  loop_module = Ast.Module{ "loop.bend",  Nil{},  [Ast.DefTop{ loop_definition}]}
  loop_loaded = Loader.LoadedModule{ "",  loop_module}
  check_result_output(Checker.check([loop_loaded]), "checker-termination-accepted", "checker-termination-rejected")


  unsafe_loop_definition = Ast.Definition{ "unsafe_loop",  Nil{},  Ast.SomeTerm{ type_term},  Ast.DefTerm{ Ast.TermRef{ "unsafe_loop",  sp}},  True{},  sp}
  unsafe_loop_module = Ast.Module{ "unsafe.bend",  Nil{},  [Ast.DefTop{ unsafe_loop_definition}]}
  unsafe_loop_loaded = Loader.LoadedModule{ "",  unsafe_loop_module}
  check_single_result_output(Checker.check([unsafe_loop_loaded]), "checker-unsafe-recursion-ok", "checker-unsafe-recursion-failed")

  forward_reference = Ast.Definition{ "before",  Nil{},  Ast.SomeTerm{ type_term},  Ast.DefTerm{ Ast.TermRef{ "after",  sp}},  False{},  sp}
  later_definition = Ast.Definition{ "after",  Nil{},  Ast.SomeTerm{ type_term},  Ast.DefTerm{ type_term},  False{},  sp}
  order_module = Ast.Module{ "order.bend",  Nil{},  [Ast.DefTop{ forward_reference}, Ast.DefTop{ later_definition}]}
  order_loaded = Loader.LoadedModule{ "",  order_module}
  check_result_output(Checker.check([order_loaded]), "checker-declaration-order-accepted", "checker-declaration-order-rejected")

#| checker-dependent-application-ok
#| checker-bang-head-ok
#| checker-bang-preserved
#| checker-local-binding-ok
#| checker-standalone-bang-rejected
#| checker-bang-argument-rejected
#| checker-import-alias-ok
#| checker-constructor-typing-ok
#| checker-multi-column-match-ok
#| checker-dependent-pattern-match-ok
#| checker-field-pattern-match-ok
#| checker-parameter-match-ok
#| checker-let-function-quantity-ok
#| checker-pattern-function-quantity-ok
#| checker-nested-lambda-quantity-ok
#| checker-branch-use-alternatives-ok
#| checker-computed-match-rejected
#| checker-let-bound-match-rejected
#| checker-erased-argument-ok
#| checker-erased-constructor-field-ok
#| checker-erased-local-function-ok
#| checker-pattern-field-scaling-ok
#| checker-family-collision-rejected
#| checker-law-fill-ok
#| checker-rewrite-ok
#| checker-foreign-io-ok
#| checker-foreign-alias-rejected
#| checker-decreasing-recursion-ok
#| checker-nested-match-ok
#| checker-nested-matrix-match-ok
#| checker-nested-exhaustiveness-rejected
#| checker-exhaustiveness-error
#| checker-affine-duplicate-rejected
#| checker-termination-rejected
#| checker-unsafe-recursion-ok
#| checker-declaration-order-rejected
