import Base
import ./ast.bend as Ast
import ./checked_frontend.bend as Checked
import ./backend_ir.bend as BIR
import ./backend_lower.bend as BackendLower
import ./c_backend.bend as CBackend

# The C target adapter owns IO: it lowers checked FIR once, reads the actual
# runtime and the declared .c alternatives of each foreign definition, and
# passes those bytes to the target renderer. The renderer decides representation
# and embedding; it never opens a file and never sees source syntax.
type EmitResult is Data:
  EmitSuccess{source: String}
  EmitFailure{message: String, span: Ast.SourceSpan}

type SourceResult is Data:
  ReadSuccess{path: String, source: String}
  ReadFailure{message: String}

type CImportPlan is Data:
  CImportPlan{path: String, namespace: String, span: Ast.SourceSpan}

type PlanResult is Data:
  PlanSuccess{imports: List<&2, CImportPlan>}
  PlanFailure{message: String, span: Ast.SourceSpan}

type LoadResult is Data:
  LoadSuccess{imports: List<&2, CBackend.CImport>}
  LoadFailure{message: String, span: Ast.SourceSpan}

def no_span() -> Ast.SourceSpan:
  Ast.SpanOf{"", 0n, 0n}

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

# Declared alternatives only. The first .c in source order is this target's
# choice; a missing alternative is a compile error, never a derived path.
def foreign_c_source(sources: List<&2, String>) -> Maybe<&2, String>:
  match sources:
    case Nil{}: None{}
    case +path <> rest:
      match String.ends_with(path, ".c"):
        case True{}: Some{path}
        case False{}: foreign_c_source(rest)

def plan_prepend(result: PlanResult, item: CImportPlan) -> PlanResult:
  match result:
    case PlanSuccess{imports}: PlanSuccess{item <> imports}
    case PlanFailure{message, span}: PlanFailure{message, span}

def plan_add(path: String, namespace: String, span: Ast.SourceSpan, planned: List<&2, CImportPlan>) -> PlanResult:
  match planned:
    case Nil{}: PlanSuccess{[CImportPlan{path, namespace, span}]}
    case +item <> rest:
      match item:
        case CImportPlan{+known, known_namespace, _}:
          match String.eq(path, known):
            case True{}:
              match String.eq(namespace, known_namespace):
                case True{}: PlanSuccess{planned}
                case False{}: PlanFailure{String.concat(["bend: ", path, " is imported from two foreign namespaces"]), span}
            case False{}: plan_prepend(plan_add(path, namespace, span, rest), item)

def plan_declaration(item: BIR.Declaration, planned: List<&2, CImportPlan>) -> PlanResult:
  match item:
    case BIR.ForeignDeclaration{_, namespace, imported, _, sources, _, span, _, _}:
      match foreign_c_source(sources):
        case Some{path}: plan_add(path, namespace, span, planned)
        case None{}: PlanFailure{String.append("bend: foreign definition has no .c import: ", imported), span}
    case _: PlanSuccess{planned}

def plan_declarations(items: List<&2, BIR.Declaration>, planned: List<&2, CImportPlan>) -> PlanResult:
  match items:
    case Nil{}: PlanSuccess{planned}
    case +item <> rest:
      match plan_declaration(item, planned):
        case PlanFailure{message, span}: PlanFailure{message, span}
        case PlanSuccess{imports}: plan_declarations(rest, imports)

def load_imports(plans: List<&2, CImportPlan>, loaded: List<&2, CBackend.CImport>) -> IO(LoadResult):
  match plans:
    case Nil{}: IO.pure(LoadResult, LoadSuccess{List.reverse(&2, CBackend.CImport, loaded)})
    case +plan <> rest:
      match plan:
        case CImportPlan{path, namespace, span}:
          do IO<LoadResult>:
            read : SourceResult <- read_source(path)
            match read:
              case ReadFailure{message}: return LoadFailure{message, span}
              case ReadSuccess{_, source}:
                return load_imports(rest, CBackend.CImport{path, namespace, source} <> loaded)

def render(program: BIR.Program, runtime: String, imports: List<&2, CBackend.CImport>) -> EmitResult:
  match CBackend.emit(program, runtime, imports):
    case CBackend.EmitSuccess{source}: EmitSuccess{source}
    case CBackend.EmitFailure{message}: EmitFailure{message, no_span()}

def emit_planned(program: BIR.Program, runtime_path: String, plan: PlanResult) -> IO(EmitResult):
  match plan:
    case PlanFailure{message, span}: IO.pure(EmitResult, EmitFailure{message, span})
    case PlanSuccess{imports}:
      do IO<EmitResult>:
        runtime : SourceResult <- read_source(runtime_path)
        match runtime:
          case ReadFailure{message}: return EmitFailure{message, no_span()}
          case ReadSuccess{_, source}:
            loaded : LoadResult <- load_imports(imports, Nil{})
            match loaded:
              case LoadFailure{message, span}: return EmitFailure{message, span}
              case LoadSuccess{imports}:
                return render(program, source, imports)

def emit_lowered(program: BIR.Program, runtime_path: String) -> IO(EmitResult):
  match program:
    case BIR.Program{_, declarations, _, _, _, _}:
      emit_planned(program, runtime_path, plan_declarations(declarations, Nil{}))

def emit(checked: Checked.CheckedProgram, runtime_path: String) -> IO(EmitResult):
  match BackendLower.lower(checked):
    case BackendLower.LowerFailure{message, span}:
      IO.pure(EmitResult, EmitFailure{message, span})
    case BackendLower.Lowered{program}:
      emit_lowered(program, runtime_path)
