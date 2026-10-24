import Base
import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/ast.bend as Ast
import ../bend2/selfhost/checked_frontend.bend as Checked
import ./template_steps_v1.bend as Template
import ./checker_core_steps_v1.bend as CheckerCore
import ./js_emit_steps_v1.bend as JSEmit

# Diagnostic fixture pipeline; not a parser-containing bootstrap root.
def parsed_module(namespace: String, module: Ast.Module) -> Loader.LoadedModule:
  Loader.LoadedModule{namespace, module}

def expand_modules_start(modules: List<&2, Loader.LoadedModule>) -> Template.TemplateRun<Template.ExpandResult>:
  Template.template_start(modules)

def template_step(-R: Type, run: Template.TemplateRun<R>) -> Template.TemplateRun<R>:
  Template.template_step(R, run)

def check_expanded_start(modules: List<&2, Loader.LoadedModule>) -> CheckerCore.CheckerRun<Checked.CheckResult>:
  CheckerCore.checker_start(modules)

def inspect_checked_start(program: Checked.CheckedProgram) -> CheckerCore.CheckerRun<Checked.Inspection>:
  CheckerCore.checker_inspect_start(program)

def checker_step(-R: Type, run: CheckerCore.CheckerRun<R>) -> CheckerCore.CheckerRun<R>:
  CheckerCore.checker_step(R, run)

def emit_modules_start(program: Checked.CheckedProgram) -> JSEmit.EmitterRun<JSEmit.EmitResult>:
  JSEmit.emitter_start(program)

def emit_library_start(program: Checked.CheckedProgram, exports: List<&2, String>) -> JSEmit.EmitterRun<JSEmit.EmitResult>:
  JSEmit.emitter_library_start(program, exports)

def emitter_step(-R: Type, run: JSEmit.EmitterRun<R>) -> JSEmit.EmitterRun<R>:
  JSEmit.emitter_step(R, run)
