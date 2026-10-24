import Base
import ./ast.bend as AST
import ./loader.bend as Loader
import ./checker.bend as Checker
import ./checked_frontend.bend as Checked
import ./backend_ir.bend as BIR
import ./backend_lower.bend as BackendLower
import ./js_backend.bend as JSBackend
import ./js_link.bend as JSLink
import ./c_emit.bend as CEmit

type Config is Data:
  Config{source: String, output: String, base: String, runtime: String}

type ArgsResult is Data:
  ArgsSuccess{config: Config}
  ArgsFailure{message: String}

def usage() -> String:
  "Usage: bend2 <source.bend> -o <out.js|out.c> --base <base.bend> [--runtime-c <c_runtime.c>]"

def parse_runtime_option(valid: Bool, runtime_option: String, source: String, output: String, base: String, runtime: String) -> ArgsResult:
  match valid:
    case True{}: ArgsSuccess{ Config{source, output, base, runtime}}
    case False{}: ArgsFailure{ "unknown option " ++ runtime_option}

def parse_base_option(valid: Bool, source: String, output: String, base: String, rest: List<&2, String>) -> ArgsResult:
  match valid:
    case False{}: ArgsFailure{ "expected --base after output"}
    case True{}:
      match rest:
        case Nil{}:
          ArgsSuccess{ Config{source, output, base, "bend2/selfhost/c_runtime.c"}}
        case +runtime_option <> +runtime <> Nil{}:
          parse_runtime_option(String.eq(runtime_option, "--runtime-c"), runtime_option, source, output, base, runtime)
        case +unknown <> _:
          ArgsFailure{ "unexpected argument " ++ unknown}

def parse_output_option(valid: Bool, source: String, output: String, base_option: String, base: String, rest: List<&2, String>) -> ArgsResult:
  match valid:
    case False{}: ArgsFailure{ "expected -o after source"}
    case True{}:
      parse_base_option(String.eq(base_option, "--base"), source, output, base, rest)

def parse_args(args: List<&2, String>) -> ArgsResult:
  match args:
    case +source <> +option <> +output <> +base_option <> +base <> rest:
      parse_output_option(String.eq(option, "-o"), source, output, base_option, base, rest)
    case _:
      ArgsFailure{ "missing required arguments"}

def span_text(span: AST.SourceSpan) -> String:
  match span:
    case AST.SpanOf{file, beg, end}:
      file ++ ":" ++ Nat.show(beg) ++ "-" ++ Nat.show(end)

def diagnostic(file: String, span: AST.SourceSpan, message: String, expected: String, observed: String) -> IO(U32):
  IO.bind(Unit, U32,
    IO.print_err(
      "Error: " ++ message ++ "\nLocation: " ++ span_text(span) ++
      "\n- expected: " ++ expected ++ "\n- observed: " ++ observed ++ "\n"
    ),
    _ => IO.pure(U32, 1)
  )

def emit_diagnostic(span: AST.SourceSpan, message: String) -> IO(U32):
  match span:
    case AST.SpanOf{file,  _,  _}:
      IO.bind(Unit, U32,
        IO.print_err("Error: " ++ message ++ "\nLocation: " ++ span_text(span) ++ "\n"),
        _ => IO.pure(U32, 1)
      )

def finish_write(path: String, file: File, write_result: Result<&1, &1, U32 & String, Unit>) -> IO(U32):
  match write_result:
    case Done{ _}:
      do IO<U32>:
        Unit <- File.close(file)
        return 0
    case Fail{error}:
      (code, message) = error
      do IO<U32>:
        Unit <- File.close(file)
        Unit <- IO.print_err("Error: cannot write output " ++ path ++ ": " ++ U32.show(code) ++ " " ++ message ++ "\n")
        return 1

def handle_open(path: String, source: String, opened: Result<&1, &1, U32 & String, File>) -> IO(U32):
  match opened:
    case Fail{error}:
      (code, message) = error
      do IO<U32>:
        Unit <- IO.print_err("Error: cannot open output " ++ path ++ ": " ++ U32.show(code) ++ " " ++ message ++ "\n")
        return 1
    case Done{file}:
      do IO<U32>:
        written : File & Result<&1, &1, U32 & String, Unit> <- File.write(file, source)
        (file, write_result) = written
        return finish_write(path, file, write_result)

def write_output(path: String, source: String) -> IO(U32):
  do IO<U32>:
    opened : Result<&1, &1, U32 & String, File> <- File.open(path, "w")
    return handle_open(path, source, opened)

def compile_js_emit(emitted: JSBackend.EmitResult, output: String) -> IO(U32):
  match emitted:
    case JSBackend.EmitFailure{message, span}:
      emit_diagnostic(span, message)
    case JSBackend.EmitSuccess{source}:
      write_output(output, source)

# The CLI owns target-link IO for JavaScript too: js_link selects the declared
# .js alternative of every foreign definition and reads exactly those bytes, so
# the renderer stays pure and a missing target is a compile diagnostic naming
# the declared path, never a runtime require failure or undefined success.
def compile_js_linked(program: BIR.Program, output: String) -> IO(U32):
  do IO<U32>:
    loaded : JSLink.LoadResult <- JSLink.load(program)
    match loaded:
      case JSLink.LoadFailure{message, span}:
        emit_diagnostic(span, message)
      case JSLink.LoadSuccess{files}:
        return compile_js_emit(JSBackend.emit_linked(program, files), output)

def compile_js(checked: Checked.CheckedProgram, output: String) -> IO(U32):
  match BackendLower.lower(checked):
    case BackendLower.LowerFailure{message, span}:
      emit_diagnostic(span, message)
    case BackendLower.Lowered{program}:
      compile_js_linked(program, output)

def compile_c_emit(emitted: CEmit.EmitResult, output: String) -> IO(U32):
  match emitted:
    case CEmit.EmitFailure{message, span}:
      emit_diagnostic(span, message)
    case CEmit.EmitSuccess{source}:
      write_output(output, source)

# The C adapter lowers the checked program once and sequences its own runtime
# and foreign-source reads; the driver only awaits that IO.
def compile_c(checked: Checked.CheckedProgram, output: String, runtime: String) -> IO(U32):
  do IO<U32>:
    emitted : CEmit.EmitResult <- CEmit.emit(checked, runtime)
    return compile_c_emit(emitted, output)

def dispatch_c(is_c: Bool, checked: Checked.CheckedProgram, output: String, runtime: String) -> IO(U32):
  match is_c:
    case False{}:
      do IO<U32>:
        Unit <- IO.print_err("Error: unsupported output extension: " ++ output ++ "\n" ++ usage() ++ "\n")
        return 1
    case True{}:
      compile_c(checked, output, runtime)

def dispatch_output(is_js: Bool, checked: Checked.CheckedProgram, output: String, runtime: String) -> IO(U32):
  match is_js:
    case True{}:
      compile_js(checked, output)
    case False{}:
      dispatch_c(String.ends_with(output, ".c"), checked, output, runtime)

def compile_checked(checked_result: Checked.CheckResult, output: String, runtime: String) -> IO(U32):
  match checked_result:
    case Checked.CheckFailure{Checked.Diagnostic{file, span, message, expected, observed}}:
      diagnostic(file, span, message, expected, observed)
    case Checked.CheckSuccess{program}:
      dispatch_output(String.ends_with(output, ".js"), program, output, runtime)

def compile_loaded(loaded: Loader.LoadResult, output: String, runtime: String) -> IO(U32):
  match loaded:
    case Loader.LoadFailure{file, span, message, expected, observed}:
      diagnostic(file, span, message, expected, observed)
    case Loader.LoadSuccess{modules}:
      compile_checked(Checker.check(modules), output, runtime)

def compile_config(config: Config) -> IO(U32):
  match config:
    case Config{source, output, base, runtime}:
      do IO<U32>:
        loaded : Loader.LoadResult <- Loader.load(base, source)
        return compile_loaded(loaded, output, runtime)

def handle_output_extension(valid: Bool, output: String, config: Config) -> IO(U32):
  match valid:
    case True{}:
      compile_config(config)
    case False{}:
      do IO<U32>:
        Unit <- IO.print_err("Error: unsupported output extension: " ++ output ++ "\n" ++ usage() ++ "\n")
        return 1

def handle_args(result: ArgsResult) -> IO(U32):
  match result:
    case ArgsFailure{message}:
      do IO<U32>:
        Unit <- IO.print_err("Error: " ++ message ++ "\n" ++ usage() ++ "\n")
        return 1
    case ArgsSuccess{Config{source, output, base, runtime}}:
      handle_output_extension(Bool.or(String.ends_with(output, ".js"), String.ends_with(output, ".c")), output, Config{source, output, base, runtime})

def main() -> IO(U32):
  do IO<U32>:
    args : List<&2, String> <- IO.args()
    return handle_args(parse_args(args))
