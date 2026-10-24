import Base
import ./ast.bend as Ast
import ./checked_frontend.bend as Checked
import ./backend_ir.bend as BIR
import ./backend_lower.bend as BackendLower
import ./c_emit_core.bend as CEmitCore

# The C target's IO adapter. The pure seam in c_emit_core lowers once and
# joins BIR-declared targets to passive bytes; this module only reads the
# runtime and exactly the declared .c alternatives, so a missing file is a
# compile diagnostic naming its path and never a derived target.
type EmitResult is Data:
  EmitSuccess{source: String}
  EmitFailure{message: String, span: Ast.SourceSpan}

type SourceResult is Data:
  ReadSuccess{path: String, source: String}
  ReadFailure{message: String}

type LoadResult is Data:
  LoadSuccess{files: List<&2, BIR.SourceFile>}
  LoadFailure{message: String, span: Ast.SourceSpan}

def read_source(path: String) -> IO(SourceResult):
  do IO<SourceResult>:
    opened : Result<&1, &1, U32 & String, File> <- File.open(path, "r")
    match opened:
      case Done{file}:
        sized : File & Result<&1, &1, U32 & String, U32> <- File.size(file)
        (file, size_result) = sized
        match size_result:
          case Done{size}:
            loaded : File & Result<&1, &1, U32 & String, String> <- File.read(file, size)
            (file, read_result) = loaded
            match read_result:
              case Done{source}:
                Unit <- File.close(file)
                return ReadSuccess{path, source}
              case Fail{error}:
                (code, message) = error
                Unit <- File.close(file)
                return ReadFailure{String.concat(["cannot read ", path, ": ", U32.show(code), " ", message])}
          case Fail{error}:
            (code, message) = error
            Unit <- File.close(file)
            return ReadFailure{String.concat(["cannot size ", path, ": ", U32.show(code), " ", message])}
      case Fail{error}:
        (code, message) = error
        return ReadFailure{String.concat(["cannot open ", path, ": ", U32.show(code), " ", message])}

# The plan is the renderer's BIR-derived choice; this adapter reads only those
# exact paths and hands the bytes back as value.
def load_imports(plans: List<&2, CEmitCore.CImportPlan>, loaded: List<&2, BIR.SourceFile>) -> IO(LoadResult):
  match plans:
    case Nil{}: IO.pure(LoadResult, LoadSuccess{List.reverse(&2, BIR.SourceFile, loaded)})
    case +plan <> rest:
      match plan:
        case CEmitCore.CImportPlan{+path, namespace, span}:
          do IO<LoadResult>:
            read : SourceResult <- read_source(path)
            match read:
              case ReadFailure{message}: return LoadFailure{message, span}
              case ReadSuccess{_, source}:
                return load_imports(rest, BIR.SourceFile{path, source} <> loaded)

def converted(result: CEmitCore.EmitResult) -> EmitResult:
  match result:
    case CEmitCore.EmitSuccess{source}: EmitSuccess{source}
    case CEmitCore.EmitFailure{message, span}: EmitFailure{message, span}

def render(program: BIR.Program, runtime: String, files: List<&2, BIR.SourceFile>) -> EmitResult:
  converted(CEmitCore.render(program, runtime, files))

def emit_planned(program: BIR.Program, runtime_path: String, plan: CEmitCore.PlanResult) -> IO(EmitResult):
  match plan:
    case CEmitCore.PlanFailure{message, span}: IO.pure(EmitResult, EmitFailure{message, span})
    case CEmitCore.PlanSuccess{imports}:
      do IO<EmitResult>:
        runtime : SourceResult <- read_source(runtime_path)
        match runtime:
          case ReadFailure{message}: return EmitFailure{message, no_span()}
          case ReadSuccess{_, source}:
            loaded : LoadResult <- load_imports(imports, Nil{})
            match loaded:
              case LoadFailure{message, span}: return EmitFailure{message, span}
              case LoadSuccess{files}:
                return render(program, source, files)

def no_span() -> Ast.SourceSpan:
  Ast.SpanOf{"", 0n, 0n}

def emit_lowered(program: BIR.Program, runtime_path: String) -> IO(EmitResult):
  match program:
    case BIR.Program{_, declarations, _, _, _, _}:
      emit_planned(program, runtime_path, CEmitCore.plan_declarations(declarations, Nil{}))

def emit(checked: Checked.CheckedProgram, runtime_path: String) -> IO(EmitResult):
  match BackendLower.lower(checked):
    case BackendLower.LowerFailure{message, span}:
      IO.pure(EmitResult, EmitFailure{message, span})
    case BackendLower.Lowered{program}:
      emit_lowered(program, runtime_path)
