import Base
import ../bend2/selfhost/loaded_module.bend as Loader
import ./checker_core_slice.bend as CheckerCore

# DIAGNOSTIC: native component entry for already-template-expanded modules.
def check_expanded(modules: List<&2, Loader.LoadedModule>) -> CheckerCore.CheckResult:
  CheckerCore.check_modules(modules, Nil{})
