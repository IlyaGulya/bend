import Base
import ../bend2/selfhost/ast.bend as Ast
import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/checked_frontend.bend as Checked
import ../checkpoints/checker_core_steps_v1.bend as Checker

# Drive the admitted checker, not its unlowered source. Each call retains the
# production quantum; the fixture supplies closed, already-expanded modules.
def outcome_value(result: Checked.CheckResult) -> U32:
  match result:
    case Checked.CheckSuccess{_}: 1
    case Checked.CheckFailure{_}: 2

# Exhausting this test driver's budget is distinct from either checker verdict.
def outcome(fuel: Nat, run: Checker.CheckerRun<Checked.CheckResult>) -> U32:
  match fuel run:
    case 0n _: 0
    case 1n+rest Checker.CheckerRunFinished{Checker.CheckerValue{value}}:
      outcome_value(value)
    case 1n+rest Checker.CheckerRunState{A, progress, stack}:
      outcome(rest, Checker.checker_step(Checked.CheckResult, Checker.CheckerRunState{A, progress, stack}))

def use_quant(+sp: Ast.SourceSpan) -> Ast.Definition:
  Ast.Definition{"use_quant",
    [Ast.Binder{Ast.QOne{}, "q", 0n, Ast.TermQuant{}, sp}],
    Ast.NoTerm{}, Ast.DefTerm{Ast.TermVar{"q", 0n, sp}}, False{}, sp}

def call_quant(+name: String, +index: Nat, +sp: Ast.SourceSpan) -> Ast.SyntaxTerm:
  Ast.TermApp{Ast.TermRef{"use_quant", sp}, Ast.TermVar{name, index, sp}, sp}

def single_module(+sp: Ast.SourceSpan) -> Loader.LoadedModule:
  definition = {Ast.Definition{"single_use",
    [Ast.Binder{Ast.QOne{}, "left", 0n, Ast.TermQuant{}, sp},
     Ast.Binder{Ast.QOne{}, "right", 1n, Ast.TermQuant{}, sp}],
    Ast.NoTerm{},
    Ast.DefTerm{Ast.TermMin{call_quant("left", 1n, sp), call_quant("right", 0n, sp), sp}},
    False{}, sp} : Ast.Definition}
  Loader.LoadedModule{"", Ast.Module{"single-use.bend", Nil{},
    [Ast.DefTop{use_quant(sp)}, Ast.DefTop{definition}]}}

def duplicate_module(+sp: Ast.SourceSpan) -> Loader.LoadedModule:
  definition = {Ast.Definition{"duplicate_use",
    [Ast.Binder{Ast.QOne{}, "q", 0n, Ast.TermQuant{}, sp}],
    Ast.NoTerm{},
    Ast.DefTerm{Ast.TermMin{call_quant("q", 0n, sp), call_quant("q", 0n, sp), sp}},
    False{}, sp} : Ast.Definition}
  Loader.LoadedModule{"", Ast.Module{"duplicate-use.bend", Nil{},
    [Ast.DefTop{use_quant(sp)}, Ast.DefTop{definition}]}}

def report(ok: Bool, yes: String, no: String) -> IO(Unit):
  match ok:
    case True{}: IO.print(yes)
    case False{}: IO.print(no)

def main() -> IO(Unit):
  +sp = {Ast.SpanOf{"application.bend", 0n, 1n} : Ast.SourceSpan}
  do IO<Unit>:
    report(U32.is_eq(outcome(100000n, Checker.checker_start([single_module(sp)])), 1),
      "checker-application-single-use-ok", "checker-application-single-use-failed")
    report(U32.is_eq(outcome(100000n, Checker.checker_start([duplicate_module(sp)])), 2),
      "checker-application-affine-duplicate-rejected", "checker-application-affine-duplicate-accepted")

#| checker-application-single-use-ok
#| checker-application-affine-duplicate-rejected
