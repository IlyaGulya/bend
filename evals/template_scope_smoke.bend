import Base
import ../bend2/selfhost/ast.bend as Ast
import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/template.bend as Template

# Boundary regressions for expansion scope that the current template suite
# does not pin:
# 1. a generated definition whose substituted body still contains an unclosed
#    template application must still be rejected, at its own application span;
# 2. generation identity for g(template f(template U32)) with f earlier than g
#    must use the requesting template suffix [g], leaving nested f
#    unspecialized in g's key even though final rewriting specializes it.

def find_definition(declarations: List<&2, Ast.TopLevel>, +key: String) -> Maybe<&2, Ast.Definition>:
  match declarations:
    case Nil{}: None{}
    case +declaration <> rest:
      match declaration:
        case Ast.DefTop{ Ast.Definition{found, binders, result, body, unsafe, span}}:
          match String.eq(found, key):
            case True{}: Some{ Ast.Definition{found, binders, result, body, unsafe, span}}
            case False{}: find_definition(rest, key)
        case _: find_definition(rest, key)

def same_source_span(found: Ast.SourceSpan, expected: Ast.SourceSpan) -> Bool:
  match found expected:
    case Ast.SpanOf{found_file, found_beg, found_end} Ast.SpanOf{file, beg, end}:
      Bool.and(String.eq(found_file, file), Bool.and(Nat.is_eq(found_beg, beg), Nat.is_eq(found_end, end)))

def unclosed_generated_result(result: Template.ExpandResult) -> Bool:
  match result:
    case Template.ExpandFailure{ _, Ast.SpanOf{ "template_scope.bend", 7n, 9n}}: True{}
    case _: False{}

def test_unclosed_generated_body(+sp: Ast.SourceSpan) -> Bool:
  app_span = Ast.SpanOf{ "template_scope.bend",  7n,  9n}
  type_a = Ast.TermType{ Ast.TermQuantity{ Ast.QOne{},  sp},  sp}
  inner = Ast.Definition{
     "inner",
     [Ast.TemplateBinder{ "T",  0n,  Ast.TermQuant{},  sp}],
     Ast.NoTerm{},
     Ast.DefTerm{ Ast.TermAbsurd{ sp}},
     False{},
     sp
  }
  outer = Ast.Definition{
     "outer",
     [
      Ast.TemplateBinder{ "T",  0n,  Ast.TermQuant{},  sp},
      Ast.Binder{ Ast.QOne{},  "y",  0n,  Ast.TermQuant{},  sp}
     ],
     Ast.NoTerm{},
     Ast.DefTerm{ Ast.TermApp{ Ast.TermRef{ "inner",  app_span},  Ast.TermVar{ "y",  0n,  sp},  app_span}},
     False{},
     sp
  }
  call = Ast.TermApp{ Ast.TermRef{ "outer",  sp},  Ast.TermTemplate{ type_a,  sp},  sp}
  caller = Ast.Definition{ "caller",  Nil{},  Ast.NoTerm{},  Ast.DefTerm{ call},  False{},  sp}
  loaded = Loader.LoadedModule{ "",  Ast.Module{ "template_scope.bend",  Nil{},  [Ast.DefTop{ inner}, Ast.DefTop{ outer}, Ast.DefTop{ caller}]}}
  unclosed_generated_result(Template.expand([loaded]))

def collect_instance_keys(declarations: List<&2, Ast.TopLevel>, acc: List<&2, String>) -> List<&2, String>:
  match declarations:
    case Nil{}: List.reverse(&2, String, acc)
    case +declaration <> rest:
      match declaration:
        case Ast.DefTop{ Ast.Definition{key,  _,  _,  _,  _,  _}}:
          match String.starts_with(key, "T~"):
            case True{}: collect_instance_keys(rest, key <> acc)
            case False{}: collect_instance_keys(rest, acc)
        case _: collect_instance_keys(rest, acc)

def instance_span_result(definition: Maybe<&2, Ast.Definition>, span: Ast.SourceSpan) -> Bool:
  match definition:
    case Some{ Ast.Definition{_,  _,  _,  _,  _, found}}: same_source_span(found, span)
    case None{}: False{}

def suffix_instances_result(result: Template.ExpandResult, f_key: String, g_key: String, f_span: Ast.SourceSpan, g_span: Ast.SourceSpan) -> Bool:
  match result:
    case Template.ExpandSuccess{ [Loader.LoadedModule{ "", Ast.Module{ _,  _, declarations}}]}:
      keys = collect_instance_keys(declarations, Nil{})
      Bool.and(
        String.eq(String.join(keys, "|"), f_key ++ "|" ++ g_key),
        Bool.and(
          instance_span_result(find_definition(declarations, f_key), f_span),
          instance_span_result(find_definition(declarations, g_key), g_span)
        )
      )
    case _: False{}

def test_suffix_scoped_actual(+sp: Ast.SourceSpan) -> Bool:
  +f_span = Ast.SpanOf{ "template_scope.bend",  0n,  1n}
  +g_span = Ast.SpanOf{ "template_scope.bend",  2n,  3n}
  +app_span = Ast.SpanOf{ "template_scope.bend",  7n,  9n}
  +type_a = Ast.TermType{ Ast.TermQuantity{ Ast.QOne{},  sp},  sp}
  +f_definition = Ast.Definition{
     "f",
     [Ast.TemplateBinder{ "T",  0n,  Ast.TermQuant{},  f_span}],
     Ast.NoTerm{},
     Ast.DefTerm{ Ast.TermAbsurd{ f_span}},
     False{},
     f_span
  }
  +g_definition = Ast.Definition{
     "g",
     [Ast.TemplateBinder{ "T",  0n,  Ast.TermQuant{},  g_span}],
     Ast.NoTerm{},
     Ast.DefTerm{ Ast.TermVar{ "T",  0n,  g_span}},
     False{},
     g_span
  }
  +f_app = Ast.TermApp{ Ast.TermRef{ "f",  app_span},  Ast.TermTemplate{ type_a,  app_span},  app_span}
  call = Ast.TermApp{ Ast.TermRef{ "g",  app_span},  Ast.TermTemplate{ f_app,  app_span},  app_span}
  caller = Ast.Definition{ "caller",  Nil{},  Ast.NoTerm{},  Ast.DefTerm{ call},  False{},  sp}
  loaded = Loader.LoadedModule{ "",  Ast.Module{ "template_scope.bend",  Nil{},  [Ast.DefTop{ f_definition}, Ast.DefTop{ g_definition}, Ast.DefTop{ caller}]}}
  f_template = Template.TemplateDef{ "f",  "",  Nil{},  ["f", "g", "caller"],  "",  f_definition,  Nil{}}
  g_template = Template.TemplateDef{ "g",  "",  Nil{},  ["f", "g", "caller"],  "",  g_definition,  Nil{}}
  +f_key = Template.generated_local_key(f_template, [type_a])
  +g_key = Template.generated_local_key(g_template, [f_app])
  specialized_g_key = Template.generated_local_key(g_template, [Ast.TermRef{ f_key,  app_span}])
  Bool.and(Bool.not(String.eq(g_key, specialized_g_key)), suffix_instances_result(Template.expand([loaded]), f_key, g_key, f_span, g_span))

type TemplateScopeSmoke is Data:
  TemplateScopeSmoke{failures: U32}

def main(modules: List<&2, Loader.LoadedModule>) -> TemplateScopeSmoke:
  +sp = Ast.SpanOf{ "template_scope.bend",  0n,  1n}
  TemplateScopeSmoke{U32.add(
    Bool.pick(U32, test_unclosed_generated_body(sp), 0, 1),
    Bool.pick(U32, test_suffix_scoped_actual(sp), 0, 1))}
