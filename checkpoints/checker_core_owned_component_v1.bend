import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/checked_frontend.bend as Checked
import ./checker_core_owned_v1.bend as CheckerCore

def check_expanded(modules: List<&2, Loader.LoadedModule>) -> Checked.CheckResult:
  CheckerCore.check_modules(modules, Nil{})
