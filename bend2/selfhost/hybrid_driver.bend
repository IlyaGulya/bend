import Base
import ./loaded_module.bend as Loader
import ./checker.bend as Checker
import ./checked_frontend.bend as Checked
import ./js_emit.bend as JSEmit
import ./backend_ir.bend as BIR
import ./backend_lower.bend as BackendLower
import ./js_link.bend as JSLink
import ./target_io.bend as TargetIO
import ./ast.bend as AST

# JS-only driver for already parsed/resolved target modules. Never invokes
# Loader.load or Parser.parse and never imports the C backend.
#
# Kernel shape rules: a `do` block holds binds and one final term, so every
# decision after a bind lives in a helper whose body is a match; a match
# scrutinizes a parameter or a case-bound field, so the pure lowering result is
# bound with IO.pure and matched as a parameter; a handle op's tuple
# destructures at a body head; and each callee is defined before its caller.
def span_text(span: AST.SourceSpan) -> String:
  match span:
    case AST.SpanOf{file, beg, end}:
      file ++ ":" ++ Nat.show(beg) ++ "-" ++ Nat.show(end)

def report(span: AST.SourceSpan, message: String) -> IO(U32):
  do IO<U32>:
    Unit <- IO.print_err("Error: " ++ message ++ "\nLocation: " ++ span_text(span) ++ "\n")
    return 1

def finish_write(file: File, written: Result<&1, &1, (U32 & String), Unit>) -> IO(U32):
  match written:
    case Done{_}:
      do IO<U32>:
        Unit <- File.close(file)
        return 0
    case Fail{error}:
      (_, message) = error
      do IO<U32>:
        Unit <- File.close(file)
        Unit <- IO.print_err("Error: cannot write output: " ++ message ++ "\n")
        return 1

def finish_written(written: File & Result<&1, &1, (U32 & String), Unit>) -> IO(U32):
  (file, result) = written
  finish_write(file, result)

def write_opened(output: String, source: String, opened: Result<&1, &1, (U32 & String), File>) -> IO(U32):
  match opened:
    case Fail{error}:
      (_, message) = error
      do IO<U32>:
        Unit <- IO.print_err("Error: cannot open output " ++ output ++ ": " ++ message ++ "\n")
        return 1
    case Done{file}:
      do IO<U32>:
        written : File & Result<&1, &1, (U32 & String), Unit> <- File.write(file, source)
        finish_written(written)

def write_output(output: String, source: String) -> IO(U32):
  do IO<U32>:
    opened : Result<&1, &1, (U32 & String), File> <- File.open(output, "w")
    return write_opened(output, source, opened)

def emit_result(result: JSEmit.EmitResult, output: String) -> IO(U32):
  match result:
    case JSEmit.EmitFailure{message, span}: report(span, message)
    case JSEmit.EmitSuccess{source}: write_output(output, source)

# One lowering, one JS render entry: the same glue the shared emitter composes.
def emit_loaded(program: BIR.Program, output: String, loaded: TargetIO.LoadResult) -> IO(U32):
  match loaded:
    case TargetIO.LoadFailure{message, span}: report(span, message)
    case TargetIO.LoadSuccess{files}: emit_result(JSEmit.render(program, files), output)

def emit_lowered(program: BIR.Program, output: String) -> IO(U32):
  do IO<U32>:
    loaded : TargetIO.LoadResult <- JSLink.load(program)
    emit_loaded(program, output, loaded)

def emit_lowered_result(lowered: BackendLower.ProgramResult, output: String) -> IO(U32):
  match lowered:
    case BackendLower.LowerFailure{message, span}: report(span, message)
    case BackendLower.Lowered{program}: emit_lowered(program, output)

def emit(checked: Checked.CheckedProgram, output: String) -> IO(U32):
  do IO<U32>:
    lowered : BackendLower.ProgramResult <- IO.pure(BackendLower.ProgramResult, BackendLower.lower(checked))
    emit_lowered_result(lowered, output)

def compile_checked(result: Checked.CheckResult, output: String) -> IO(U32):
  match result:
    case Checked.CheckFailure{Checked.Diagnostic{file, span, message, expected, observed}}:
      report(span, message ++ "\n- expected: " ++ expected ++ "\n- observed: " ++ observed)
    case Checked.CheckSuccess{program}: emit(program, output)

def compile(modules: List<&2, Loader.LoadedModule>, output: String) -> IO(U32):
  compile_checked(Checker.check(modules), output)
