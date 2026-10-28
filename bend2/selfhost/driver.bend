import Base
import ./ast.bend as AST
import ./loader.bend as Loader
import ./checker.bend as Checker
import ./checked_frontend.bend as Checked
import ./backend_ir.bend as BIR
import ./backend_lower.bend as BackendLower
import ./emitter.bend as Emitter
import ./js_link.bend as JSLink
import ./c_emit.bend as CEmit
import ./target_io.bend as TargetIO

# The CLI owns one lowering and one target dispatch. Kernel shape rules this
# module follows: a `do` block holds binds and one final term, so every decision
# after a bind lives in a helper whose body is a match; a match scrutinizes a
# parameter or a case-bound field, never a computed or let-bound value; a handle
# op's tuple destructures at a body head; and each callee is defined before its
# caller.
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
  do IO<U32>:
    Unit <- IO.print_err(
      "Error: " ++ message ++ "\nLocation: " ++ span_text(span) ++
      "\n- expected: " ++ expected ++ "\n- observed: " ++ observed ++ "\n"
    )
    return 1

# The span is consumed by its match, so the location is rebuilt from the bound
# fields instead of reusing the whole span.
def emit_diagnostic(span: AST.SourceSpan, message: String) -> IO(U32):
  match span:
    case AST.SpanOf{file, beg, end}:
      do IO<U32>:
        Unit <- IO.print_err("Error: " ++ message ++ "\nLocation: " ++ file ++ ":" ++ Nat.show(beg) ++ "-" ++ Nat.show(end) ++ "\n")
        return 1

def finish_write(path: String, file: File, write_result: Result<&1, &1, (U32 & String), Unit>) -> IO(U32):
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

def finish_written(path: String, written: File & Result<&1, &1, (U32 & String), Unit>) -> IO(U32):
  (file, write_result) = written
  finish_write(path, file, write_result)

def handle_open(path: String, source: String, opened: Result<&1, &1, (U32 & String), File>) -> IO(U32):
  match opened:
    case Fail{error}:
      (code, message) = error
      do IO<U32>:
        Unit <- IO.print_err("Error: cannot open output " ++ path ++ ": " ++ U32.show(code) ++ " " ++ message ++ "\n")
        return 1
    case Done{file}:
      do IO<U32>:
        written : File & Result<&1, &1, (U32 & String), Unit> <- File.write(file, source)
        finish_written(path, written)

def write_output(path: String, source: String) -> IO(U32):
  do IO<U32>:
    opened : Result<&1, &1, (U32 & String), File> <- File.open(path, "w")
    return handle_open(path, source, opened)

def compile_emitted(emitted: Emitter.EmitResult, output: String) -> IO(U32):
  match emitted:
    case Emitter.EmitFailure{message, span}:
      emit_diagnostic(span, message)
    case Emitter.EmitSuccess{source}:
      write_output(output, source)

def compile_js_loaded(program: BIR.Program, output: String, loaded: TargetIO.LoadResult) -> IO(U32):
  match loaded:
    case TargetIO.LoadFailure{message, span}:
      emit_diagnostic(span, message)
    case TargetIO.LoadSuccess{files}:
      compile_emitted(Emitter.emit_bir(program, files), output)

# The CLI owns target-link IO for JavaScript: js_link selects the declared .js
# alternative of every foreign definition and reads exactly those bytes, so the
# renderer stays pure and a missing target is a compile diagnostic naming the
# declared path, never a runtime require failure or undefined success.
def compile_js_bir(program: BIR.Program, output: String) -> IO(U32):
  do IO<U32>:
    loaded : TargetIO.LoadResult <- JSLink.load(program)
    compile_js_loaded(program, output, loaded)

def compile_c_loaded(program: BIR.Program, output: String, loaded: CEmit.LoadResult) -> IO(U32):
  match loaded:
    case CEmit.LoadFailure{message, span}:
      emit_diagnostic(span, message)
    case CEmit.LoadSuccess{runtime_source, files}:
      compile_emitted(Emitter.emit_c_bir(program, runtime_source, files), output)

# The C adapter reads the runtime and exactly the declared .c alternatives; the
# shared emitter renders that same lowered program. A missing target is a
# compile diagnostic naming its path, never a derived alternative.
def compile_c_bir(program: BIR.Program, output: String, runtime: String) -> IO(U32):
  do IO<U32>:
    loaded : CEmit.LoadResult <- CEmit.load(program, runtime)
    compile_c_loaded(program, output, loaded)

# The CLI already rejected every other extension, so this dispatch is total:
# the output is either the JavaScript target or the C target.
def dispatch_output(is_js: Bool, program: BIR.Program, output: String, runtime: String) -> IO(U32):
  match is_js:
    case True{}:
      compile_js_bir(program, output)
    case False{}:
      compile_c_bir(program, output, runtime)

def compile_lowered(lowered: BackendLower.ProgramResult, output: String, runtime: String) -> IO(U32):
  match lowered:
    case BackendLower.LowerFailure{message, span}:
      emit_diagnostic(span, message)
    case BackendLower.Lowered{program}:
      dispatch_output(String.ends_with(output, ".js"), program, output, runtime)

# One lowering per compile: the CLI lowers the checked program once, and that
# single BIR.Program both plans the declared target files and is rendered by
# the shared emitter. Target dispatch never lowers again.
def compile_checked(checked_result: Checked.CheckResult, output: String, runtime: String) -> IO(U32):
  match checked_result:
    case Checked.CheckFailure{Checked.Diagnostic{file, span, message, expected, observed}}:
      diagnostic(file, span, message, expected, observed)
    case Checked.CheckSuccess{program}:
      compile_lowered(BackendLower.lower(program), output, runtime)

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

# The output name is read more than once (both extensions, then the config), so
# its field is marked reusable.
def handle_args_config(config: Config) -> IO(U32):
  match config:
    case Config{source, +output, base, runtime}:
      handle_output_extension(Bool.or(String.ends_with(output, ".js"), String.ends_with(output, ".c")), output, Config{source, output, base, runtime})

def handle_args(result: ArgsResult) -> IO(U32):
  match result:
    case ArgsFailure{message}:
      do IO<U32>:
        Unit <- IO.print_err("Error: " ++ message ++ "\n" ++ usage() ++ "\n")
        return 1
    case ArgsSuccess{config}:
      handle_args_config(config)

def main() -> IO(U32):
  do IO<U32>:
    args : List<&2, String> <- IO.args()
    return handle_args(parse_args(args))
