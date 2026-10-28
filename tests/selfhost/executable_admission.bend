import Base
import ../../bend2/selfhost/ast.bend as Ast
import ../../bend2/selfhost/loaded_module.bend as Loader
import ../../checkpoints/checker_core_steps_v1.bend as Checker
import ../../bend2/selfhost/checked_frontend.bend as Checked
import ../../checkpoints/emitter_steps_v1.bend as Emit

@unsafe
def finish(run: Checker.CheckerRun<Checked.CheckResult>) -> Checked.CheckResult:
  match run:
    case Checker.CheckerRunFinished{Checker.CheckerValue{value}}: value
    case Checker.CheckerRunState{A, progress, stack}: finish(Checker.checker_step(Checked.CheckResult, Checker.CheckerRunState{A, progress, stack}))

def check(module: Ast.Module) -> Checked.CheckResult:
  finish(Checker.checker_start([Loader.LoadedModule{"", module}]))

@unsafe
def finish_emit(run: Emit.EmitterRun<Emit.EmitResult>) -> Emit.EmitResult:
  match run:
    case Emit.EmitterRunFinished{Emit.EmitterValue{value}}: value
    case Emit.EmitterRunState{A, progress, stack}: finish_emit(Emit.emitter_step(Emit.EmitResult, Emit.EmitterRunState{A, progress, stack}))

def unit_decl(+sp: Ast.SourceSpan) -> Ast.TopLevel:
  Ast.TypeTop{Ast.TypeDecl{"Unit", [], Ast.TermType{Ast.TermQuantity{Ast.QMany{}, sp}, sp}, [Ast.Constructor{"Unit", [], sp}], sp}}

def mainless_module() -> Ast.Module:
  +sp = {Ast.SpanOf{"entry.bend", 0n, 1n} : Ast.SourceSpan}
  +ty = {Ast.TermRef{"Unit", sp} : Ast.SyntaxTerm}
  definition = {Ast.Definition{"twice", [Ast.Binder{Ast.QOne{}, "x", 0n, ty, sp}], Ast.SomeTerm{ty}, Ast.DefTerm{Ast.TermVar{"x", 0n, sp}}, False{}, sp} : Ast.Definition}
  Ast.Module{"entry.bend", [], [unit_decl(sp), Ast.DefTop{definition}]}

def main_module(result: Ast.OptionalTerm) -> Ast.Module:
  +sp = {Ast.SpanOf{"entry.bend", 0n, 1n} : Ast.SourceSpan}
  definition = {Ast.Definition{"main", [], result, Ast.DefTerm{Ast.TermAnn{Ast.TermCtr{"Unit", [], sp}, Ast.TermRef{"Unit", sp}, sp}}, False{}, sp} : Ast.Definition}
  Ast.Module{"entry.bend", [], [unit_decl(sp), Ast.DefTop{definition}]}

def executable_result(result: Emit.EmitResult, accepted: String, rejected: String) -> IO(Unit):
  match result:
    case Emit.EmitSuccess{_}: IO.print(accepted)
    case Emit.EmitFailure{_, _}: IO.print(rejected)

def executable(result: Checked.CheckResult, accepted: String, rejected: String) -> IO(Unit):
  match result:
    case Checked.CheckSuccess{program}: executable_result(finish_emit(Emit.emitter_start(program, [])), accepted, rejected)
    case Checked.CheckFailure{_}: IO.print("entry-check-failed")

def library_result(result: Checked.CheckResult) -> IO(Unit):
  match result:
    case Checked.CheckSuccess{program}: executable_result(finish_emit(Emit.emitter_library_start(program, [], [])), "library-mainless-accepted", "library-mainless-rejected")
    case Checked.CheckFailure{_}: IO.print("library-check-failed")

def main() -> IO(Unit):
  sp = {Ast.SpanOf{"entry.bend", 0n, 1n} : Ast.SourceSpan}
  do IO<Unit>:
    Unit <- executable(check(mainless_module()), "missing-main-accepted", "missing-main-rejected")
    Unit <- executable(check(main_module(Ast.SomeTerm{Ast.TermRef{"Unit", sp}})), "executable-main-accepted", "executable-main-rejected")
    Unit <- executable(check(main_module(Ast.NoTerm{})), "inferred-main-accepted", "inferred-main-rejected")
    library_result(check(mainless_module()))

#|missing-main-rejected
#|executable-main-accepted
#|inferred-main-accepted
#|library-mainless-accepted
