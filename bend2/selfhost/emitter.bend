import Base
import ./ast.bend as Ast
import ./checked_frontend.bend as Checked
import ./backend_ir.bend as BIR
import ./js_emit.bend as JS
import ./c_emit_core.bend as CEmit

# One production emitter composition: both target entry paths meet here and
# share one lowering. Each target keeps its canonical glue module; the typed
# generator composes backend_lower, lower_catalog, descriptor_nf and both
# target backends exactly once, so this module lowers the owning checked
# program once per call and never reads source syntax or file bytes itself.
#
# Both paths return the same inert result. The caller's foreign bytes stay
# passive BIR.SourceFile values; this boundary only forwards them.
type EmitResult is Data:
  EmitSuccess{source: String}
  EmitFailure{message: String, span: Ast.SourceSpan}

def emitted_js(result: JS.EmitResult) -> EmitResult:
  match result:
    case JS.EmitSuccess{source}: EmitSuccess{source}
    case JS.EmitFailure{message, span}: EmitFailure{message, span}

def emitted_c(result: CEmit.EmitResult) -> EmitResult:
  match result:
    case CEmit.EmitSuccess{source}: EmitSuccess{source}
    case CEmit.EmitFailure{message, span}: EmitFailure{message, span}

def emit(program: Checked.CheckedProgram, files: List<&2, BIR.SourceFile>) -> EmitResult:
  emitted_js(JS.emit(program, files))

def emit_library(program: Checked.CheckedProgram, exports: List<&2, String>, files: List<&2, BIR.SourceFile>) -> EmitResult:
  emitted_js(JS.emit_library(program, exports, files))

def emit_c(program: Checked.CheckedProgram, runtime: String, files: List<&2, BIR.SourceFile>) -> EmitResult:
  emitted_c(CEmit.emit(program, runtime, files))

def emit_c_library(program: Checked.CheckedProgram, exports: List<&2, String>, runtime: String, files: List<&2, BIR.SourceFile>) -> EmitResult:
  emitted_c(CEmit.emit_library(program, exports, runtime, files))
