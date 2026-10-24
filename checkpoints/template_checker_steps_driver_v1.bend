import Base
import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/ast.bend as Ast
import ../bend2/selfhost/checked_frontend.bend as Checked
import ../bend2/selfhost/backend_ir.bend as BIR
import ./template_steps_v1.bend as Template
import ./checker_core_steps_v1.bend as CheckerCore
import ./emitter_steps_v1.bend as Emit

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

def emit_modules_start(program: Checked.CheckedProgram, files: List<&2, BIR.SourceFile>) -> Emit.EmitterRun<Emit.EmitResult>:
  Emit.emitter_start(program, files)

def emit_library_start(program: Checked.CheckedProgram, exports: List<&2, String>, files: List<&2, BIR.SourceFile>) -> Emit.EmitterRun<Emit.EmitResult>:
  Emit.emitter_library_start(program, exports, files)

def emitter_step(-R: Type, run: Emit.EmitterRun<R>) -> Emit.EmitterRun<R>:
  Emit.emitter_step(R, run)

def emit_c_modules_start(program: Checked.CheckedProgram, runtime: String, files: List<&2, BIR.SourceFile>) -> Emit.EmitterRun<Emit.EmitResult>:
  Emit.cemit_start(program, runtime, files)

def emit_c_library_start(program: Checked.CheckedProgram, exports: List<&2, String>, runtime: String, files: List<&2, BIR.SourceFile>) -> Emit.EmitterRun<Emit.EmitResult>:
  Emit.cemit_library_start(program, exports, runtime, files)

def c_emitter_step(-R: Type, run: Emit.EmitterRun<R>) -> Emit.EmitterRun<R>:
  Emit.emitter_step(R, run)
