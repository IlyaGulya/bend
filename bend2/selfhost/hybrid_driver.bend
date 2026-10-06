import Base
import ./loaded_module.bend as Loader
import ./checker.bend as Checker
import ./js_emit.bend as JSEmit
import ./ast.bend as AST

# JS-only driver for already parsed/resolved target modules. Never invokes
# Loader.load or Parser.parse and never imports the C backend.
def span_text(span: AST.SourceSpan) -> String:
  match span:
    case AST.SpanOf{file, beg, end}:
      file ++ ":" ++ Nat.show(beg) ++ "-" ++ Nat.show(end)

def report(span: AST.SourceSpan, message: String) -> IO(U32):
  do IO<U32>:
    Unit <- IO.print_err("Error: " ++ message ++ "\nLocation: " ++ span_text(span) ++ "\n")
    return 1

def finish_write(file: File, written: Result<&1, &1, U32 & String, Unit>) -> IO(U32):
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

def write_opened(output: String, source: String, opened: Result<&1, &1, U32 & String, File>) -> IO(U32):
  match opened:
    case Fail{error}:
      (_, message) = error
      do IO<U32>:
        Unit <- IO.print_err("Error: cannot open output " ++ output ++ ": " ++ message ++ "\n")
        return 1
    case Done{file}:
      do IO<U32>:
        written : File & Result<&1, &1, U32 & String, Unit> <- File.write(file, source)
        (file, result) = written
        return finish_write(file, result)

def write_output(output: String, source: String) -> IO(U32):
  do IO<U32>:
    opened : Result<&1, &1, U32 & String, File> <- File.open(output, "w")
    return write_opened(output, source, opened)

def emit(checked: List<&2, Loader.LoadedModule>, output: String) -> IO(U32):
  match JSEmit.emit(checked):
    case JSEmit.EmitFailure{message, span}: report(span, message)
    case JSEmit.EmitSuccess{source}: write_output(output, source)

def compile_checked(result: Checker.CheckResult, output: String) -> IO(U32):
  match result:
    case Checker.CheckFailure{Checker.Diagnostic{file, span, message, expected, observed}}:
      report(span, message ++ "\n- expected: " ++ expected ++ "\n- observed: " ++ observed)
    case Checker.CheckSuccess{modules}: emit(modules, output)

def compile(modules: List<&2, Loader.LoadedModule>, output: String) -> IO(U32):
  compile_checked(Checker.check(modules), output)
