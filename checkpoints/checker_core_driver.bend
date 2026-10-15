import Base
import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/ast.bend as Ast
import ./checker_core_slice.bend as CheckerCore
import ../bend2/selfhost/js_emit.bend as JSEmit

# DIAGNOSTIC: CHECK ALREADY-TEMPLATE-EXPANDED MODULES.
# The host must establish the template-free/expanded precondition.
def parsed_module(namespace: String, module: Ast.Module) -> Loader.LoadedModule:
  Loader.LoadedModule{namespace, module}

def check_expanded(modules: List<&2, Loader.LoadedModule>) -> CheckerCore.CheckResult:
  CheckerCore.check_modules(modules, Nil{})

def emit_modules(modules: List<&2, Loader.LoadedModule>) -> JSEmit.EmitResult:
  JSEmit.emit(modules)
