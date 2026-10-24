import ./checker_core_owned_v1.bend as CheckerCore
import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/ast.bend as Ast
import ../bend2/selfhost/backend_ir.bend as BIR
import ../bend2/selfhost/checked_frontend.bend as Checked

def parsed_module(namespace: String, module: Ast.Module) -> Loader.LoadedModule:
  Loader.LoadedModule{namespace, module}

def check_expanded(modules: List<&2, Loader.LoadedModule>) -> Checked.CheckResult:
  CheckerCore.check_modules(modules, Nil{})
