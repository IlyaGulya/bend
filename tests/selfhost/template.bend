import Base
import ../../bend2/selfhost/ast.bend as Ast
import ../../bend2/selfhost/loaded_module.bend as Loader
import ../../bend2/selfhost/template.bend as Template

law main:
  IO(Unit)

def instance_key(term: Ast.SyntaxTerm) -> Maybe<&2, String>:
  match term:
    case Ast.TermApp{ Ast.TermRef{key,  _},  _,  _}: Some{key}
    case _: None{}

def find_definition_by_equality(equal: Bool, declaration: Ast.TopLevel, rest: List<&2, Ast.TopLevel>, key: String) -> Maybe<&2, Ast.Definition>:
  match equal:
    case True{}:
      match declaration:
        case Ast.DefTop{definition}: Some{definition}
        case _: None{}
    case False{}:
      match rest:
        case Nil{}: None{}
        case +next <> tail:
          match next:
            case Ast.DefTop{ Ast.Definition{found, binders, result, body, unsafe, span}}:
              definition = Ast.Definition{found, binders, result, body, unsafe, span}
              find_definition_by_equality(String.eq(found, key), Ast.DefTop{definition}, tail, key)
            case _: find_definition_by_equality(False{}, next, tail, key)
def find_definition(declarations: List<&2, Ast.TopLevel>, key: String) -> Maybe<&2, Ast.Definition>:
  match declarations:
    case Nil{}: None{}
    case +declaration <> rest:
      match declaration:
        case Ast.DefTop{ Ast.Definition{found, _, _, _, _, _}}:
          find_definition_by_equality(String.eq(found, key), declaration, rest, key)
        case _: find_definition_by_equality(False{}, declaration, rest, key)


def recursive_reference(definition: Ast.Definition, key: String) -> Bool:
  match definition:
    case Ast.Definition{_, _, _, Ast.DefTerm{ Ast.TermApp{ Ast.TermRef{ found,  _},  Ast.TermVar{_, 0n, _},  _}}, _, _}:
      String.eq(found, key)
    case _: False{}

def same_quantity(left: Ast.Quantity, right: Ast.Quantity) -> Bool:
  match left right:
    case Ast.QZero{} Ast.QZero{}: True{}
    case Ast.QOne{} Ast.QOne{}: True{}
    case Ast.QMany{} Ast.QMany{}: True{}
    case _ _: False{}
def specialized_pair(definition: Ast.Definition, expected_binder_quantity: Ast.Quantity, expected_result_quantity: Ast.Quantity) -> Bool:
  match definition:
    case Ast.Definition{_, [Ast.Binder{Ast.QOne{}, _, _, Ast.TermType{ Ast.TermQuantity{ binder_quantity,  _},  _}, _}], Ast.SomeTerm{ Ast.TermType{ Ast.TermQuantity{ result_quantity,  _},  _}}, _, _, _}:
      Bool.and(same_quantity(binder_quantity, expected_binder_quantity), same_quantity(result_quantity, expected_result_quantity))
    case _: False{}


def call_has_type_arg(term: Ast.SyntaxTerm) -> Bool:
  match term:
    case Ast.TermApp{ Ast.TermRef{ _,  _},  Ast.TermType{ _,  _},  _}: True{}
    case _: False{}

def bool_to_nat(value: Bool) -> Nat:
  match value:
    case True{}: 1n
    case False{}: 0n

def count_instances(declarations: List<&2, Ast.TopLevel>, prefix: String) -> Nat:
  match declarations:
    case Nil{}: 0n
    case +Ast.DefTop{ Ast.Definition{key, _, _, _, _, _}} <> rest:
      bool_to_nat(String.starts_with(key, prefix)) + count_instances(rest, prefix)
    case +_ <> rest: count_instances(rest, prefix)



def two_argument_second_definition(second: Maybe<&2, Ast.Definition>, def_a: Ast.Definition, declarations: List<&2, Ast.TopLevel>, key_a: String, key_b: String) -> Bool:
  match second:
    case Some{def_b}:
      Bool.and(count_instances(declarations, "T~") == 2n, Bool.and(Bool.and(specialized_pair(def_a, Ast.QMany{}, Ast.QOne{}), specialized_pair(def_b, Ast.QOne{}, Ast.QMany{})), Bool.and(recursive_reference(def_a, key_a), recursive_reference(def_b, key_b))))
    case _: False{}
def two_argument_definitions(first: Maybe<&2, Ast.Definition>, second: Maybe<&2, Ast.Definition>, declarations: List<&2, Ast.TopLevel>, key_a: String, key_b: String) -> Bool:
  match first:
    case Some{def_a}: two_argument_second_definition(second, def_a, declarations, key_a, key_b)
    case _: False{}
def two_argument_valid_keys(valid: Bool, key_a: String, key_b: String, declarations: List<&2, Ast.TopLevel>) -> Bool:
  match valid:
    case True{}:
      two_argument_definitions(find_definition(declarations, key_a), find_definition(declarations, key_b), declarations, key_a, key_b)
    case _: False{}
def two_argument_second_key(second: Maybe<&2, String>, key_a: String, left: Ast.SyntaxTerm, right: Ast.SyntaxTerm, declarations: List<&2, Ast.TopLevel>) -> Bool:
  match second:
    case Some{key_b}:
      two_argument_valid_keys(Bool.and(Bool.not(String.eq(key_a, key_b)), Bool.and(call_has_type_arg(left), call_has_type_arg(right))), key_a, key_b, declarations)
    case _: False{}

def two_argument_keys(first: Maybe<&2, String>, second: Maybe<&2, String>, left: Ast.SyntaxTerm, right: Ast.SyntaxTerm, declarations: List<&2, Ast.TopLevel>) -> Bool:
  match first:
    case Some{key_a}: two_argument_second_key(second, key_a, left, right, declarations)
    case _: False{}

def two_argument_use(use: Maybe<&2, Ast.Definition>, declarations: List<&2, Ast.TopLevel>) -> Bool:
  match use:
    case Some{ Ast.Definition{_, _, _, Ast.DefTerm{ Ast.TermMin{left, right, _}}, _, _}}:
      two_argument_keys(instance_key(left), instance_key(right), left, right, declarations)
    case _: False{}

def two_argument_result(result: Template.ExpandResult) -> Bool:
  match result:
    case Template.ExpandSuccess{ [Loader.LoadedModule{ "", Ast.Module{ _, _, declarations}}]}:
      two_argument_use(find_definition(declarations, "use_pair"), declarations)
    case _: False{}

def test_two_template_arguments(sp: Ast.SourceSpan, type_a: Ast.SyntaxTerm, type_b: Ast.SyntaxTerm) -> Bool:
  pair_template = Ast.Definition{
     "pair",
     [
      Ast.TemplateBinder{ "A",  0n,  Ast.TermQuant{},  sp},
      Ast.TemplateBinder{ "B",  1n,  Ast.TermQuant{},  sp},
      Ast.Binder{ Ast.QOne{},  "x",  0n,  Ast.TermVar{ "B",  0n,  sp},  sp}
    ],
     Ast.SomeTerm{ Ast.TermVar{ "A",  2n,  sp}},
     Ast.DefTerm{ Ast.TermApp{
       Ast.TermApp{
         Ast.TermApp{
           Ast.TermRef{ "pair",  sp},
           Ast.TermTemplate{ Ast.TermVar{ "A",  2n,  sp},  sp},
           sp
        },
         Ast.TermTemplate{ Ast.TermVar{ "B",  1n,  sp},  sp},
         sp
      },
       Ast.TermVar{ "x",  0n,  sp},
       sp
    }},
     True{},
     sp
  }
  first_call = Ast.TermApp{
     Ast.TermApp{
       Ast.TermApp{
         Ast.TermRef{ "pair",  sp},
         Ast.TermTemplate{ type_a,  sp},
         sp
      },
       Ast.TermTemplate{ type_b,  sp},
       sp
    },
     type_a,
     sp
  }
  second_call = Ast.TermApp{
     Ast.TermApp{
       Ast.TermApp{
         Ast.TermRef{ "pair",  sp},
         Ast.TermTemplate{ type_b,  sp},
         sp
      },
       Ast.TermTemplate{ type_a,  sp},
       sp
    },
     type_b,
     sp
  }
  use = Ast.Definition{ "use_pair",  Nil{},  Ast.NoTerm{},  Ast.DefTerm{ Ast.TermMin{ first_call,  second_call,  sp}},  False{},  sp}
  loaded = Loader.LoadedModule{ "",  Ast.Module{ "pair.bend",  Nil{},  [Ast.DefTop{ pair_template}, Ast.DefTop{ use}]}}
  two_argument_result(Template.expand([loaded]))


def import_alias_key(prefixed: Bool, local_definition: Maybe<&2, Ast.Definition>) -> Bool:
  match prefixed:
    case True{}:
      match local_definition:
        case Some{_}: True{}
        case None{}: False{}
    case _: False{}

def import_alias_use(use: Maybe<&2, Ast.Definition>, library_declarations: List<&2, Ast.TopLevel>) -> Bool:
  match use:
    case Some{ Ast.Definition{_, _, _, Ast.DefTerm{ Ast.TermApp{ Ast.TermRef{ generated_key, _}, Ast.TermType{ _, _}, _}}, _, _}}:
      import_alias_key(String.starts_with(generated_key, "lib.T~"), find_definition(library_declarations, String.drop(generated_key, 4n)))
    case _: False{}

def import_alias_result(result: Template.ExpandResult) -> Bool:
  match result:
    case Template.ExpandSuccess{ [Loader.LoadedModule{ "lib", Ast.Module{ _, _, library_declarations}}, Loader.LoadedModule{ "", Ast.Module{ _, _, root_declarations}}]}:
      import_alias_use(find_definition(root_declarations, "use_alias"), library_declarations)
    case _: False{}
def test_import_alias(sp: Ast.SourceSpan, type_a: Ast.SyntaxTerm) -> Bool:
  template_definition = Ast.Definition{
     "alias_id",
     [
      Ast.TemplateBinder{ "A",  0n,  Ast.TermQuant{},  sp},
      Ast.Binder{ Ast.QOne{},  "x",  0n,  Ast.TermVar{ "A",  0n,  sp},  sp}
    ],
     Ast.SomeTerm{ Ast.TermVar{ "A",  1n,  sp}},
     Ast.DefTerm{ Ast.TermVar{ "x",  0n,  sp}},
     False{},
     sp
  }
  library = Loader.LoadedModule{ "lib",  Ast.Module{ "lib.bend",  Nil{},  [Ast.DefTop{ template_definition}]}}
  import = Ast.ModuleImport{ "lib.bend",  "Lib",  sp}
  use = Ast.Definition{
     "use_alias",
     Nil{},
     Ast.NoTerm{},
     Ast.DefTerm{ Ast.TermApp{
       Ast.TermApp{
         Ast.TermRef{ "Lib.alias_id",  sp},
         Ast.TermTemplate{ type_a,  sp},
         sp
      },
       type_a,
       sp
    }},
     False{},
     sp
  }
  root = Loader.LoadedModule{ "",  Ast.Module{ "root.bend",  [import],  [Ast.DefTop{ use}]}}
  import_alias_result(Template.expand([library, root]))


def namespace_caller_result(caller: Maybe<&2, Ast.Definition>, a_declarations: List<&2, Ast.TopLevel>, b_declarations: List<&2, Ast.TopLevel>) -> Bool:
  match caller:
    case Some{ Ast.Definition{_, _, _, Ast.DefTerm{ Ast.TermRef{key, _}}, _, _}}:
      Bool.and(count_instances(a_declarations, "T~") == 1n, Bool.and(count_instances(b_declarations, "T~") == 0n, String.starts_with(key, "a.T~")))
    case _: False{}
def namespace_result(result: Template.ExpandResult) -> Bool:
  match result:
    case Template.ExpandSuccess{ [Loader.LoadedModule{"a", Ast.Module{_, _, a_declarations}}, Loader.LoadedModule{"b", Ast.Module{_, _, b_declarations}}, Loader.LoadedModule{"", Ast.Module{_, _, root_declarations}}]}:
      namespace_caller_result(find_definition(root_declarations, "caller"), a_declarations, b_declarations)
    case _: False{}

def test_same_name_namespaces(sp: Ast.SourceSpan, type_a: Ast.SyntaxTerm) -> Bool:
  a_template = Ast.Definition{ "map",  [Ast.TemplateBinder{ "T",  0n,  Ast.TermQuant{},  sp}],  Ast.NoTerm{},  Ast.DefTerm{ type_a},  False{},  sp}
  b_template = Ast.Definition{ "map",  [Ast.TemplateBinder{ "T",  0n,  Ast.TermQuant{},  sp}],  Ast.NoTerm{},  Ast.DefTerm{ type_a},  False{},  sp}
  a_module = Loader.LoadedModule{ "a",  Ast.Module{ "a.bend",  Nil{},  [Ast.DefTop{ a_template}]}}
  b_module = Loader.LoadedModule{ "b",  Ast.Module{ "b.bend",  Nil{},  [Ast.DefTop{ b_template}]}}
  a_import = Ast.ModuleImport{ "a.bend",  "A",  sp}
  b_import = Ast.ModuleImport{ "b.bend",  "B",  sp}
  call = Ast.TermApp{ Ast.TermRef{ "A.map",  sp},  Ast.TermTemplate{ type_a,  sp},  sp}
  caller = Ast.Definition{ "caller",  Nil{},  Ast.NoTerm{},  Ast.DefTerm{ call},  False{},  sp}
  root = Loader.LoadedModule{ "",  Ast.Module{ "root.bend",  [a_import, b_import],  [Ast.DefTop{ caller}]}}
  namespace_result(Template.expand([a_module, b_module, root]))



def nested_argument_outer_result(outer_generated: Bool, outer: Maybe<&2, Ast.Definition>, root_declarations: List<&2, Ast.TopLevel>, lib_declarations: List<&2, Ast.TopLevel>) -> Bool:
  match outer:
    case Some{ Ast.Definition{_, Nil{}, _, Ast.DefTerm{ Ast.TermRef{key, _}}, _, _}}:
      Bool.and(outer_generated, Bool.and(String.starts_with(key, "lib.T~"), Bool.and(count_instances(root_declarations, "T~") == 1n, count_instances(lib_declarations, "T~") == 1n)))
    case _: False{}
def nested_argument_caller_result(caller: Maybe<&2, Ast.Definition>, root_declarations: List<&2, Ast.TopLevel>, lib_declarations: List<&2, Ast.TopLevel>) -> Bool:
  match caller:
    case Some{ Ast.Definition{_, _, _, Ast.DefTerm{ Ast.TermRef{outer_key, _}}, _, _}}:
      nested_argument_outer_result(String.starts_with(outer_key, "T~"), find_definition(root_declarations, outer_key), root_declarations, lib_declarations)
    case _: False{}
def nested_argument_result(result: Template.ExpandResult) -> Bool:
  match result:
    case Template.ExpandSuccess{ [Loader.LoadedModule{ "lib", Ast.Module{ _, _, lib_declarations}}, Loader.LoadedModule{ "", Ast.Module{ _, _, root_declarations}}]}:
      nested_argument_caller_result(find_definition(root_declarations, "caller"), root_declarations, lib_declarations)
    case _: False{}

def test_nested_imported_template_argument(sp: Ast.SourceSpan, type_a: Ast.SyntaxTerm) -> Bool:
  inner = Ast.Definition{ "inner",  [Ast.TemplateBinder{ "T",  0n,  Ast.TermQuant{},  sp}],  Ast.NoTerm{},  Ast.DefTerm{ Ast.TermAbsurd{ sp}},  False{},  sp}
  library = Loader.LoadedModule{ "lib",  Ast.Module{ "lib.bend",  Nil{},  [Ast.DefTop{ inner}]}}
  import = Ast.ModuleImport{ "lib.bend",  "Lib",  sp}
  outer = Ast.Definition{ "outer",  [Ast.TemplateBinder{ "T",  0n,  Ast.TermQuant{},  sp}],  Ast.NoTerm{},  Ast.DefTerm{ Ast.TermVar{ "T",  0n,  sp}},  False{},  sp}
  inner_call = Ast.TermApp{ Ast.TermRef{ "Lib.inner",  sp},  Ast.TermTemplate{ type_a,  sp},  sp}
  outer_call = Ast.TermApp{ Ast.TermRef{ "outer",  sp},  Ast.TermTemplate{ inner_call,  sp},  sp}
  caller = Ast.Definition{ "caller",  Nil{},  Ast.NoTerm{},  Ast.DefTerm{ outer_call},  False{},  sp}
  root = Loader.LoadedModule{ "",  Ast.Module{ "root.bend",  [import],  [Ast.DefTop{ outer}, Ast.DefTop{ caller}]}}
  nested_argument_result(Template.expand([library, root]))


def same_source_span(found: Ast.SourceSpan, expected: Ast.SourceSpan) -> Bool:
  match found:
    case Ast.SpanOf{ found_file, found_beg, found_end}:
      match expected:
        case Ast.SpanOf{ file, beg, end}: Bool.and(String.eq(found_file, file), Bool.and(found_beg == beg, found_end == end))
    case _: False{}

def rejects_bare_result(result: Template.ExpandResult, span: Ast.SourceSpan) -> Bool:
  match result:
    case Template.ExpandFailure{ _, found}: same_source_span(found, span)
    case _: False{}
def rejects_bare_template_reference(span: Ast.SourceSpan) -> Bool:
  template_definition = Ast.Definition{ "needs_value",  [Ast.TemplateBinder{ "T",  0n,  Ast.TermQuant{}, span}],  Ast.NoTerm{},  Ast.DefTerm{ Ast.TermAbsurd{span}},  False{}, span}
  caller = Ast.Definition{ "caller",  Nil{},  Ast.NoTerm{},  Ast.DefTerm{ Ast.TermRef{ "needs_value", span}},  False{}, span}
  loaded = Loader.LoadedModule{ "",  Ast.Module{ "invalid.bend",  Nil{},  [Ast.DefTop{ template_definition}, Ast.DefTop{ caller}]}}
  rejects_bare_result(Template.expand([loaded]), span)


def rejects_late_result(result: Template.ExpandResult, span: Ast.SourceSpan) -> Bool:
  match result:
    case Template.ExpandFailure{ _, Ast.SpanOf{ found_file, found_beg, found_end}}:
      match span:
        case Ast.SpanOf{file, beg, end}: Bool.and(String.eq(found_file, file), Bool.and(found_beg == beg, found_end == end))
    case _: False{}
def rejects_late_template_binder(span: Ast.SourceSpan) -> Bool:
  invalid = Ast.Definition{ "invalid_template",  [Ast.Binder{ Ast.QOne{},  "x",  0n,  Ast.TermQuant{}, span}, Ast.TemplateBinder{ "T",  1n,  Ast.TermQuant{}, span}],  Ast.NoTerm{},  Ast.DefTerm{ Ast.TermAbsurd{span}},  False{}, span}
  loaded = Loader.LoadedModule{ "",  Ast.Module{ "invalid.bend",  Nil{},  [Ast.DefTop{ invalid}]}}
  rejects_late_result(Template.expand([loaded]), span)


def rejects_argument_result(result: Template.ExpandResult) -> Bool:
  match result:
    case Template.ExpandFailure{ _, Ast.SpanOf{ "template.bend", 7n, 9n}}: True{}
    case _: False{}
def rejects_argument(argument: Ast.SyntaxTerm, span: Ast.SourceSpan, source_span: Ast.SourceSpan) -> Bool:
  template_definition = Ast.Definition{
     "needs_value",
     [Ast.TemplateBinder{ "T",  0n,  Ast.TermQuant{},  source_span}],
     Ast.NoTerm{},
     Ast.DefTerm{ Ast.TermType{ Ast.TermQuantity{ Ast.QOne{},  source_span},  source_span}},
     False{},
     source_span
  }
  caller = Ast.Definition{
     "caller",
     Nil{},
     Ast.NoTerm{},
     Ast.DefTerm{ Ast.TermApp{ Ast.TermRef{ "needs_value", span},  argument, span}},
     False{},
     source_span
  }
  loaded = Loader.LoadedModule{ "",  Ast.Module{ "invalid.bend",  Nil{},  [Ast.DefTop{ template_definition}, Ast.DefTop{ caller}]}}
  rejects_argument_result(Template.expand([loaded]))


def test_invalid_arguments(sp: Ast.SourceSpan, type_a: Ast.SyntaxTerm) -> Bool:
  app_span = Ast.SpanOf{ "template.bend",  7n,  9n}
  open_argument = Ast.TermTemplate{ Ast.TermVar{ "free",  0n,  sp},  sp}
  Bool.and(rejects_argument(open_argument, app_span, sp), rejects_argument(type_a, app_span, sp))

def poly_instance_result(instance: Maybe<&2, Ast.Definition>, call_key: String) -> Bool:
  match instance:
    case Some{ Ast.Definition{generated_key, [Ast.Binder{ Ast.QOne{}, "x", _, Ast.TermType{ Ast.TermQuantity{ Ast.QOne{}, _}, _}, _}], Ast.SomeTerm{ Ast.TermType{ Ast.TermQuantity{ Ast.QOne{}, _}, _}}, Ast.DefTerm{ Ast.TermApp{ Ast.TermRef{ recursive_key, _}, Ast.TermVar{ "x", 0n, _}, _}}, True{}, _}}:
      Bool.and(String.eq(call_key, generated_key), String.eq(recursive_key, generated_key))
    case _: False{}
def poly_use_result(use: Maybe<&2, Ast.Definition>, declarations: List<&2, Ast.TopLevel>) -> Bool:
  match use:
    case None{}: False{}
    case Some{ Ast.Definition{_, _, _, Ast.DefTerm{ Ast.TermApp{ Ast.TermRef{ call_key, _}, Ast.TermType{ Ast.TermQuantity{ Ast.QOne{}, _}, _}, _}}, _, _}}:
      poly_instance_result(find_definition(declarations, call_key), call_key)
    case _: False{}

def poly_result_is_specialized(declarations: List<&2, Ast.TopLevel>) -> Bool:
  poly_use_result(find_definition(declarations, "use_poly_id"), declarations)


def zero_runtime_instance_result(instance: Maybe<&2, Ast.Definition>, key: String) -> Bool:
  match instance:
    case Some{ Ast.Definition{generated_key, Nil{}, _, Ast.DefTerm{ Ast.TermType{ _, _}}, _, _}}: String.eq(key, generated_key)
    case _: False{}
def zero_runtime_use_result(use: Maybe<&2, Ast.Definition>, declarations: List<&2, Ast.TopLevel>) -> Bool:
  match use:
    case Some{ Ast.Definition{_, _, _, Ast.DefTerm{ Ast.TermBang{ Ast.TermRef{key, _}, _}}, _, _}}:
      zero_runtime_instance_result(find_definition(declarations, key), key)
    case _: False{}

def zero_runtime_expansion(declarations: List<&2, Ast.TopLevel>) -> Bool:
  zero_runtime_use_result(find_definition(declarations, "use_constant"), declarations)


def zero_runtime_result(result: Template.ExpandResult) -> Bool:
  match result:
    case Template.ExpandSuccess{ [Loader.LoadedModule{ "", Ast.Module{ _, _, declarations}}]}:
      zero_runtime_expansion(declarations)
    case _: False{}
def test_zero_runtime_arguments(sp: Ast.SourceSpan, type_a: Ast.SyntaxTerm) -> Bool:
  template_definition = Ast.Definition{
     "constant",
     [Ast.TemplateBinder{ "A",  0n,  Ast.TermQuant{},  sp}],
     Ast.SomeTerm{ Ast.TermVar{ "A",  0n,  sp}},
     Ast.DefTerm{ Ast.TermVar{ "A",  0n,  sp}},
     False{},
     sp
  }
  use = Ast.Definition{ "use_constant",  Nil{},  Ast.NoTerm{},  Ast.DefTerm{ Ast.TermApp{ Ast.TermBang{ Ast.TermRef{ "constant",  sp},  sp},  Ast.TermTemplate{ type_a,  sp},  sp}},  False{},  sp}
  loaded = Loader.LoadedModule{ "",  Ast.Module{ "zero.bend",  Nil{},  [Ast.DefTop{ template_definition}, Ast.DefTop{ use}]}}
  zero_runtime_result(Template.expand([loaded]))


def repeat_text(value: String, count: Nat) -> String:
  match count:
    case 0n: ""
    case _: value ++ repeat_text(value, count - 1n)


def bounded_caller_result(caller: Maybe<&2, Ast.Definition>) -> Bool:
  match caller:
    case Some{ Ast.Definition{_, _, _, Ast.DefTerm{ Ast.TermRef{key, _}}, _, _}}:
      String.length(key) <= 80n
    case _: False{}
def bounded_result(result: Template.ExpandResult) -> Bool:
  match result:
    case Template.ExpandSuccess{ [Loader.LoadedModule{ "", Ast.Module{ _, _, declarations}}]}:
      bounded_caller_result(find_definition(declarations, "caller"))
    case _: False{}
def test_bounded_generated_key(sp: Ast.SourceSpan) -> Bool:
  template_definition = Ast.Definition{ "bounded",  [Ast.TemplateBinder{ "T",  0n,  Ast.TermQuant{},  sp}],  Ast.NoTerm{},  Ast.DefTerm{ Ast.TermAbsurd{ sp}},  False{},  sp}
  argument = Ast.TermRef{ repeat_text("longargument", 100n),  sp}
  call = Ast.TermApp{ Ast.TermRef{ "bounded",  sp},  Ast.TermTemplate{ argument,  sp},  sp}
  caller = Ast.Definition{ "caller",  Nil{},  Ast.NoTerm{},  Ast.DefTerm{ call},  False{},  sp}
  loaded = Loader.LoadedModule{ "",  Ast.Module{ "bounded.bend",  Nil{},  [Ast.DefTop{ template_definition}, Ast.DefTop{ caller}]}}
  bounded_result(Template.expand([loaded]))


def print_test_result(result: Bool, success: String, failure: String) -> IO(Unit):
  match result:
    case True{}: IO.print(success)
    case False{}: IO.print(failure)

def print_poly_expansion(result: Template.ExpandResult) -> IO(Unit):
  match result:
    case Template.ExpandFailure{ _, _}:
      IO.print("template-expansion-failed")
    case Template.ExpandSuccess{ [Loader.LoadedModule{ "", Ast.Module{ _, _, declarations}}]}:
      print_test_result(poly_result_is_specialized(declarations), "template-specialization-recursion-ok", "template-specialization-recursion-failed")
def main():
  sp = Ast.SpanOf{ "template.bend",  0n,  1n}
  type_a = Ast.TermType{ Ast.TermQuantity{ Ast.QOne{},  sp},  sp}
  template_definition = Ast.Definition{
     "poly_id",
     [
      Ast.TemplateBinder{ "A",  0n,  Ast.TermQuant{},  sp},
      Ast.Binder{ Ast.QOne{},  "x",  0n,  Ast.TermVar{ "A",  0n,  sp},  sp}
    ],
     Ast.SomeTerm{ Ast.TermVar{ "A",  1n,  sp}},
     Ast.DefTerm{ Ast.TermApp{
       Ast.TermApp{
         Ast.TermRef{ "poly_id",  sp},
         Ast.TermTemplate{ Ast.TermVar{ "A",  1n,  sp},  sp},
         sp
      },
       Ast.TermVar{ "x",  0n,  sp},
       sp
    }},
     True{},
     sp
  }
  use_definition = Ast.Definition{
     "use_poly_id",
     Nil{},
     Ast.NoTerm{},
     Ast.DefTerm{ Ast.TermApp{
       Ast.TermApp{
         Ast.TermRef{ "poly_id",  sp},
         Ast.TermTemplate{ type_a,  sp},
         sp
      },
       type_a,
       sp
    }},
     False{},
     sp
  }
  module = Ast.Module{
     "template.bend",
     Nil{},
     [Ast.DefTop{ template_definition}, Ast.DefTop{ use_definition}]
  }
  loaded = Loader.LoadedModule{ "", module}
  print_poly_expansion(Template.expand([loaded]))

  type_b = Ast.TermType{ Ast.TermQuantity{ Ast.QMany{},  sp},  sp}
  print_test_result(test_two_template_arguments(sp, type_a, type_b), "template-multi-argument-specializations-ok", "template-multi-argument-specializations-failed")
  print_test_result(test_import_alias(sp, type_a), "template-import-alias-ok", "template-import-alias-failed")
  print_test_result(test_nested_imported_template_argument(sp, type_a), "template-nested-import-argument-ok", "template-nested-import-argument-failed")
  print_test_result(test_same_name_namespaces(sp, type_a), "template-same-name-namespaces-ok", "template-same-name-namespaces-failed")
  print_test_result(test_invalid_arguments(sp, type_a), "template-invalid-arguments-rejected", "template-invalid-arguments-accepted")
  print_test_result(Bool.and(rejects_bare_template_reference(sp), rejects_late_template_binder(sp)), "template-invalid-reference-and-order-rejected", "template-invalid-reference-or-order-accepted")
  print_test_result(test_zero_runtime_arguments(sp, type_a), "template-zero-runtime-arguments-ok", "template-zero-runtime-arguments-failed")
  print_test_result(test_bounded_generated_key(sp), "template-bounded-instance-key-ok", "template-bounded-instance-key-failed")

#| template-specialization-recursion-ok

#| template-multi-argument-specializations-ok

#| template-import-alias-ok

#| template-nested-import-argument-ok

#| template-same-name-namespaces-ok

#| template-invalid-arguments-rejected

#| template-invalid-reference-and-order-rejected

#| template-zero-runtime-arguments-ok

#| template-bounded-instance-key-ok
