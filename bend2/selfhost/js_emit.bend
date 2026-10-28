import Base
import ./ast.bend as Ast
import ./checked_frontend.bend as Checked
import ./backend_ir.bend as BIR
import ./backend_lower.bend as BackendLower
import ./js_backend.bend as Backend

# JavaScript is one target of the shared lowering. This module owns no semantic
# decision and no second copy of the lowering: it lowers once, then hands the
# closed BIR and the caller's actual foreign-source bytes to the target.
#
# The bytes are passive: BIR.SourceFile{path, source} is exactly what the caller
# read. Selection, namespace and span are BIR facts that js_backend.link
# derives, so nothing here invents a namespace or inspects the checked program.
type EmitResult is Data:
  EmitSuccess{source: String}
  EmitFailure{message: String, span: Ast.SourceSpan}

def emitted(result: Backend.EmitResult) -> EmitResult:
  match result:
    case Backend.EmitFailure{message, span}: EmitFailure{message, span}
    case Backend.EmitSuccess{source}: EmitSuccess{source}

# The render entry for an already lowered program. The CLI must lower once to
# learn which declared target files the program needs, so it renders that same
# BIR.Program here instead of lowering a second time through emit.
def render(program: BIR.Program, files: List<&2, BIR.SourceFile>) -> EmitResult:
  emitted(Backend.emit_linked(program, files))

def emit_result(result: BackendLower.ProgramResult, files: List<&2, BIR.SourceFile>) -> EmitResult:
  match result:
    case BackendLower.LowerFailure{message, span}: EmitFailure{message, span}
    case BackendLower.Lowered{program}: render(program, files)

def emit(program: Checked.CheckedProgram, files: List<&2, BIR.SourceFile>) -> EmitResult:
  emit_result(BackendLower.lower(program), files)

def emit_library(program: Checked.CheckedProgram, exports: List<&2, String>, files: List<&2, BIR.SourceFile>) -> EmitResult:
  emit_result(BackendLower.lower_library(program, exports), files)
