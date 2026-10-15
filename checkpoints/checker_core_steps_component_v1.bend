import ../bend2/selfhost/loaded_module.bend as Loader
import ./checker_core_steps_v1.bend as CheckerCore

def check_expanded_start(modules: List<&2, Loader.LoadedModule>) -> CheckerCore.CheckerProgress<CheckerCore.CheckResult>:
  CheckerCore.checker_start(modules)

def checker_step(request: CheckerCore.CheckerRequest) -> CheckerCore.CheckerProgress<CheckerCore.checker_result(request)>:
  CheckerCore.checker_step(request)
