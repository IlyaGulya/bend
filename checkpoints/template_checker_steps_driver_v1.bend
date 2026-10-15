import Base
import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/ast.bend as Ast
import ./template_steps_v1.bend as Template
import ./checker_core_steps_v1.bend as CheckerCore
import ./js_emit_steps_v1.bend as JSEmit

# Diagnostic fixture pipeline; not a parser-containing bootstrap root.
def parsed_module(namespace: String, module: Ast.Module) -> Loader.LoadedModule:
  Loader.LoadedModule{namespace, module}

def expand_modules_start(modules: List<&2, Loader.LoadedModule>) -> Template.TemplateProgress<Template.ExpandResult>:
  Template.template_start(modules)

def template_step(request: Template.TemplateRequest) -> Template.TemplateProgress<Template.template_result(request)>:
  Template.template_step(request)

def check_expanded_start(modules: List<&2, Loader.LoadedModule>) -> CheckerCore.CheckerProgress<CheckerCore.CheckResult>:
  CheckerCore.checker_start(modules)

def checker_step(request: CheckerCore.CheckerRequest) -> CheckerCore.CheckerProgress<CheckerCore.checker_result(request)>:
  CheckerCore.checker_step(request)

def emit_modules_start(modules: List<&2, Loader.LoadedModule>) -> JSEmit.EmitterProgress<JSEmit.EmitResult>:
  JSEmit.emitter_start(modules)

# Consumer-only diagnostic export; these are program APIs, not compiler APIs.
def emit_library_probe_start(modules: List<&2, Loader.LoadedModule>) -> JSEmit.EmitterProgress<JSEmit.EmitResult>:
  JSEmit.emitter_step(JSEmit.EmitterRequest_emit_library{modules, ["zero", "one", "pack", "make_pack", "apply", "identity", "identity_probe", "erased_probe", "specialized_probe"]})

def emitter_step(request: JSEmit.EmitterRequest) -> JSEmit.EmitterProgress<JSEmit.emitter_result(request)>:
  JSEmit.emitter_step(request)
