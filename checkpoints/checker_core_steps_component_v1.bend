import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/checked_frontend.bend as Checked
import ./checker_core_steps_v1.bend as CheckerCore

def check_expanded_start(modules: List<&2, Loader.LoadedModule>) -> CheckerCore.CheckerRun<Checked.CheckResult>:
  CheckerCore.checker_start(modules)

def inspect_checked_start(program: Checked.CheckedProgram) -> CheckerCore.CheckerRun<Checked.Inspection>:
  CheckerCore.checker_inspect_start(program)

def checker_step(-R: Type, run: CheckerCore.CheckerRun<R>) -> CheckerCore.CheckerRun<R>:
  CheckerCore.checker_step(R, run)
