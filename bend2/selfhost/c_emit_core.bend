import Base
import ./ast.bend as Ast
import ./checked_frontend.bend as Checked
import ./backend_ir.bend as BIR
import ./backend_lower.bend as BackendLower
import ./c_backend.bend as CBackend

# The pure C target seam: it lowers the owning checked program exactly once,
# derives every declared .c target from BIR, joins those paths to the caller's
# passive bytes and renders. It opens no file, reads no source syntax and
# invents no namespace or alternative spelling: the CLI's IO adapter reads the
# declared bytes and the runtime, and a missing target is a compile failure.
type EmitResult is Data:
  EmitSuccess{source: String}
  EmitFailure{message: String, span: Ast.SourceSpan}

type CImportPlan is Data:
  CImportPlan{path: String, namespace: String, span: Ast.SourceSpan}

type PlanResult is Data:
  PlanSuccess{imports: List<&2, CImportPlan>}
  PlanFailure{message: String, span: Ast.SourceSpan}

type JoinResult is Data:
  JoinSuccess{imports: List<&2, CBackend.CImport>}
  JoinFailure{message: String, span: Ast.SourceSpan}

def no_span() -> Ast.SourceSpan:
  Ast.SpanOf{"", 0n, 0n}

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

def plan_add(+path: String, +namespace: String, span: Ast.SourceSpan, planned: List<&2, CImportPlan>) -> PlanResult:
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

def plan_declaration(item: BIR.Declaration, +planned: List<&2, CImportPlan>) -> PlanResult:
  match item:
    case BIR.ForeignDeclaration{_, namespace, imported, _, sources, _, span, _, _}:
      match foreign_c_source(sources):
        case Some{path}: plan_add(path, namespace, span, planned)
        case None{}: PlanFailure{String.append("bend: foreign definition has no .c import: ", imported), span}
    case _: PlanSuccess{planned}

def plan_declarations(items: List<&2, BIR.Declaration>, +planned: List<&2, CImportPlan>) -> PlanResult:
  match items:
    case Nil{}: PlanSuccess{planned}
    case +item <> rest:
      match plan_declaration(item, planned):
        case PlanFailure{message, span}: PlanFailure{message, span}
        case PlanSuccess{imports}: plan_declarations(rest, imports)

def find_source(+path: String, files: List<&2, BIR.SourceFile>) -> Maybe<&2, String>:
  match files:
    case Nil{}: None{}
    case BIR.SourceFile{+known, +source} <> rest:
      match String.eq(path, known):
        case True{}: Some{source}
        case False{}: find_source(path, rest)

def join_imports(plans: List<&2, CImportPlan>, +files: List<&2, BIR.SourceFile>, loaded: List<&2, CBackend.CImport>) -> JoinResult:
  match plans:
    case Nil{}: JoinSuccess{List.reverse(&2, CBackend.CImport, loaded)}
    case +plan <> rest:
      match plan:
        case CImportPlan{+path, namespace, span}:
          match find_source(path, files):
            case Some{source}: join_imports(rest, files, CBackend.CImport{path, namespace, source} <> loaded)
            case None{}: JoinFailure{String.append("bend: missing declared C target: ", path), span}

def render(program: BIR.Program, runtime: String, files: List<&2, BIR.SourceFile>) -> EmitResult:
  match program:
    case BIR.Program{_, declarations, _, _, _, _}:
      match plan_declarations(declarations, Nil{}):
        case PlanFailure{message, span}: EmitFailure{message, span}
        case PlanSuccess{imports}:
          match join_imports(imports, files, Nil{}):
            case JoinFailure{message, span}: EmitFailure{message, span}
            case JoinSuccess{imports}:
              match CBackend.emit(program, runtime, imports):
                case CBackend.EmitSuccess{source}: EmitSuccess{source}
                case CBackend.EmitFailure{message}: EmitFailure{message, no_span()}

def emit(checked: Checked.CheckedProgram, runtime: String, files: List<&2, BIR.SourceFile>) -> EmitResult:
  match BackendLower.lower(checked):
    case BackendLower.LowerFailure{message, span}: EmitFailure{message, span}
    case BackendLower.Lowered{program}: render(program, runtime, files)

def emit_library(checked: Checked.CheckedProgram, exports: List<&2, String>, runtime: String, files: List<&2, BIR.SourceFile>) -> EmitResult:
  match BackendLower.lower_library(checked, exports):
    case BackendLower.LowerFailure{message, span}: EmitFailure{message, span}
    case BackendLower.Lowered{program}: render(program, runtime, files)
