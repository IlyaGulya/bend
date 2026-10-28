import Base
import ../../bend2/selfhost/ast.bend as Ast
import ../../checkpoints/checker_core_steps_v1.bend as Checker
import ../../bend2/selfhost/checked_frontend.bend as Checked
import ../../bend2/selfhost/loaded_module.bend as Loader

@unsafe
def finish(run: Checker.CheckerRun<Checked.CheckResult>) -> Checked.CheckResult:
  match run:
    case Checker.CheckerRunFinished{Checker.CheckerValue{value}}: value
    case Checker.CheckerRunState{A, progress, stack}: finish(Checker.checker_step(Checked.CheckResult, Checker.CheckerRunState{A, progress, stack}))

def check(modules: List<&2, Loader.LoadedModule>) -> Checked.CheckResult:
  finish(Checker.checker_start(modules))

def rejects_at_span(diagnostic: Checked.Diagnostic, expected: Ast.SourceSpan) -> Bool:
  match diagnostic:
    case Checked.Diagnostic{_, Ast.SpanOf{found_file, found_beg, found_end}, _, _, _}:
      match expected:
        case Ast.SpanOf{file, beg, end}: Bool.and(String.eq(found_file, file), Bool.and(Nat.is_eq(found_beg, beg), Nat.is_eq(found_end, end)))


def report_span(valid: Bool) -> IO(Unit):
  match valid:
    case True{}: IO.print("checker-datatype-template-parameter-rejected")
    case False{}: IO.print("checker-datatype-template-parameter-misplaced")

def report_datatype_template_parameter(result: Checked.CheckResult, expected: Ast.SourceSpan) -> IO(Unit):
  match result:
    case Checked.CheckFailure{diagnostic}: report_span(rejects_at_span(diagnostic, expected))
    case Checked.CheckSuccess{_}: IO.print("checker-datatype-template-parameter-accepted")

def report_datatype_parameter_control(result: Checked.CheckResult) -> IO(Unit):
  match result:
    case Checked.CheckSuccess{_}: IO.print("checker-datatype-erased-parameter-ok")
    case Checked.CheckFailure{_}: IO.print("checker-datatype-erased-parameter-failed")

law main:
  IO(Unit)

def main():
  +sp = {Ast.SpanOf{"check.bend", 0n, 1n} : Ast.SourceSpan}
  type_term = {Ast.TermType{Ast.TermQuantity{Ast.QOne{}, sp}, sp} : Ast.SyntaxTerm}
  +data_kind = {Ast.TermType{Ast.TermQuantity{Ast.QMany{}, sp}, sp} : Ast.SyntaxTerm}
  # The expanded checker boundary must reject a retained template parameter at
  # that parameter's span, not accept it and leave failure to the backend.
  +template_parameter_span = {Ast.SpanOf{"datatype-parameter.bend", 21n, 27n} : Ast.SourceSpan}
  template_parameter_type = {Ast.TypeDecl{
     "TemplateParameterBox",
     [Ast.TemplateBinder{"a", 0n, type_term, template_parameter_span}],
     data_kind,
     Nil{},
     sp
  } : Ast.TypeDecl}
  template_parameter_module = {Ast.Module{"datatype-parameter.bend", Nil{}, [Ast.TypeTop{template_parameter_type}]} : Ast.Module}
  template_parameter_loaded = {Loader.LoadedModule{"", template_parameter_module} : Loader.LoadedModule}

  # The ordinary erased parameter and its constructor field remain accepted.
  erased_parameter_span = {Ast.SpanOf{"datatype-parameter.bend", 40n, 44n} : Ast.SourceSpan}
  erased_parameter_type = {Ast.TypeDecl{
     "ErasedParameterBox",
     [Ast.Binder{Ast.QZero{}, "A", 0n, data_kind, erased_parameter_span}],
     data_kind,
     [Ast.Constructor{"ErasedParameterBoxCtr", [Ast.Binder{Ast.QOne{}, "value", 1n, Ast.TermVar{"A", 0n, sp}, sp}], sp}],
     sp
  } : Ast.TypeDecl}
  erased_parameter_module = {Ast.Module{"datatype-parameter-control.bend", Nil{}, [Ast.TypeTop{erased_parameter_type}]} : Ast.Module}
  erased_parameter_loaded = {Loader.LoadedModule{"", erased_parameter_module} : Loader.LoadedModule}
  do IO<Unit>:
    Unit <- report_datatype_template_parameter(check([template_parameter_loaded]), template_parameter_span)
    report_datatype_parameter_control(check([erased_parameter_loaded]))

#|checker-datatype-template-parameter-rejected
#|checker-datatype-erased-parameter-ok
