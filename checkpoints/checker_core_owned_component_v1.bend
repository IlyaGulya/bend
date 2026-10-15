import ../bend2/selfhost/loaded_module.bend as Loader
import ./checker_core_owned_v1.bend as CheckerCore

def check_expanded(modules: List<&2, Loader.LoadedModule>) -> CheckerCore.CheckResult:
  CheckerCore.check_modules(modules, Nil{})
