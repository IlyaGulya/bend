import Base
import ./ast.bend as Ast
import ./checked_frontend.bend as Checked
import ./backend_lower.bend as BackendLower
import ./js_backend.bend as Backend

# JavaScript is one target of the shared lowering. This module only renders the
# backend IR, so it owns no semantic decision and no second copy of the lowering.
type EmitResult is Data:
  EmitSuccess{source: String}
  EmitFailure{message: String, span: Ast.SourceSpan}

def emit_result(result: BackendLower.ProgramResult) -> EmitResult:
  match result:
    case BackendLower.LowerFailure{message, span}: EmitFailure{message, span}
    case BackendLower.Lowered{program}: EmitSuccess{Backend.emit(program)}
def emit(program: Checked.CheckedProgram) -> EmitResult:
  emit_result(BackendLower.lower(program))
def emit_library(program: Checked.CheckedProgram, exports: List<&2, String>) -> EmitResult:
  emit_result(BackendLower.lower_library(program, exports))
