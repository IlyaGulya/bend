import Base
import ./ast.bend as AST
import ./backend_ir.bend as BIR
import ./c_emit_core.bend as CEmitCore
import ./target_io.bend as TargetIO

# The C target's IO adapter. The pure seam in c_emit_core derives every
# declared .c alternative from BIR and renders; this module only reads the
# runtime and exactly those declared paths, so a missing file is a compile
# diagnostic naming its path and never a derived target. It performs no
# lowering: the caller's BIR.Program is already the one checked program.
#
# Kernel shape rules: a `do` block holds binds and one final term, so each
# decision after a bind lives in a helper whose body is a match; a match cannot
# scrutinize a computed value, so the pure plan is bound with IO.pure and
# matched as a parameter; and each callee is defined before its caller.
type LoadResult is Data:
  LoadSuccess{runtime: String, files: List<&2, BIR.SourceFile>}
  LoadFailure{message: String, span: AST.SourceSpan}

def planned(plans: List<&2, CEmitCore.CImportPlan>, acc: List<&2, TargetIO.PlannedFile>) -> List<&2, TargetIO.PlannedFile>:
  match plans:
    case Nil{}: List.reverse(&2, TargetIO.PlannedFile, acc)
    case +plan <> rest:
      match plan:
        case CEmitCore.CImportPlan{path, _, span}: planned(rest, TargetIO.PlannedFile{path, span} <> acc)

def no_span() -> AST.SourceSpan:
  AST.SpanOf{"", 0n, 0n}

def load_targets_read(runtime_source: String, loaded: TargetIO.LoadResult) -> IO(LoadResult):
  match loaded:
    case TargetIO.LoadFailure{message, span}: IO.pure(LoadResult, LoadFailure{message, span})
    case TargetIO.LoadSuccess{files}: IO.pure(LoadResult, LoadSuccess{runtime_source, files})

def load_targets(imports: List<&2, CEmitCore.CImportPlan>, runtime_source: String) -> IO(LoadResult):
  do IO<LoadResult>:
    loaded : TargetIO.LoadResult <- TargetIO.read_files(planned(imports, Nil{}), Nil{})
    load_targets_read(runtime_source, loaded)

# The runtime is not a component of the program, so a missing runtime has no
# source location; a missing declared target keeps its declaration span.
def load_runtime_read(imports: List<&2, CEmitCore.CImportPlan>, runtime: TargetIO.SourceResult) -> IO(LoadResult):
  match runtime:
    case TargetIO.SourceFailure{message}: IO.pure(LoadResult, LoadFailure{message, no_span()})
    case TargetIO.SourceSuccess{runtime_source}: load_targets(imports, runtime_source)

def load_runtime(runtime_path: String, imports: List<&2, CEmitCore.CImportPlan>) -> IO(LoadResult):
  do IO<LoadResult>:
    runtime : TargetIO.SourceResult <- TargetIO.read_source(runtime_path)
    load_runtime_read(imports, runtime)

# A missing .c alternative is a plan failure before any read, so the runtime
# path is not consulted for a program whose C target cannot be selected.
def load_plan(runtime_path: String, plan: CEmitCore.PlanResult) -> IO(LoadResult):
  match plan:
    case CEmitCore.PlanFailure{message, span}: IO.pure(LoadResult, LoadFailure{message, span})
    case CEmitCore.PlanSuccess{imports}: load_runtime(runtime_path, imports)

def load_planned(runtime_path: String, declarations: List<&2, BIR.Declaration>) -> IO(LoadResult):
  do IO<LoadResult>:
    plan : CEmitCore.PlanResult <- IO.pure(CEmitCore.PlanResult, CEmitCore.plan_declarations(declarations, Nil{}))
    load_plan(runtime_path, plan)

def load(program: BIR.Program, runtime_path: String) -> IO(LoadResult):
  match program:
    case BIR.Program{_, declarations, _, _, _, _}:
      load_planned(runtime_path, declarations)
