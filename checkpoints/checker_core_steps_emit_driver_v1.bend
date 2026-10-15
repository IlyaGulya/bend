import ./checker_core_steps_v1.bend as CheckerCore
import Base
import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/ast.bend as Ast
import ./js_emit_steps_v1.bend as JSEmit

# DIAGNOSTIC: CHECK ALREADY-TEMPLATE-EXPANDED MODULES.
# The host must establish the template-free/expanded precondition.
def parsed_module(namespace: String, module: Ast.Module) -> Loader.LoadedModule:
  Loader.LoadedModule{namespace, module}

def check_expanded_start(modules: List<&2, Loader.LoadedModule>) -> CheckerCore.CheckerProgress<CheckerCore.CheckResult>:
  CheckerCore.checker_start(modules)

def checker_step(request: CheckerCore.CheckerRequest) -> CheckerCore.CheckerProgress<CheckerCore.checker_result(request)>:
  CheckerCore.checker_step(request)

def emit_modules_start(modules: List<&2, Loader.LoadedModule>) -> JSEmit.EmitterProgress<JSEmit.EmitResult>:
  JSEmit.emitter_start(modules)

def emitter_step(request: JSEmit.EmitterRequest) -> JSEmit.EmitterProgress<JSEmit.emitter_result(request)>:
  JSEmit.emitter_step(request)
