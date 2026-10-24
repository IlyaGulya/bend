# Experimental native CPU host. Loaded after the unchanged compiler root into
# its canonical book; all definitions in both roots are validated normally.
import Base
import ../bend2/selfhost/ast.bend as Ast
import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/backend_ir.bend as BIR
import ../bend2/selfhost/checked_frontend.bend as Checked
import ../checkpoints/template_steps_v1.bend as Template
import ../checkpoints/checker_core_steps_v1.bend as Checker
import ../checkpoints/js_emit_steps_v1.bend as Emitter
import ../checkpoints/c_emit_steps_v1.bend as CEmitter

# The loader closure owns the parser's original immutable Module. The host can
# inspect import paths but cannot replace a parsed tree or checked result.
type NativeParsed is Type:
  NativeParsed{imports: List<&2, String>, foreign: List<&2, String>, load: String -> Loader.LoadedModule}
  NativeParseFailure{message: String}

type NativeResult<-A: Type> is Type:
  NativeAccepted{value: A}
  NativeRejected{message: String}

def native_import_paths(imports: List<&2, Ast.ModuleImport>) -> List<&2, String>:
  match imports:
    case Ast.ModuleImport{path, _, _} <> rest:
      path <> native_import_paths(rest)
    case Nil{}:
      Nil{}

# The declared alternatives are BIR metadata. The host filters the `.js`
# variant and reads only those bytes; it never derives a target path or a
# namespace of its own.
def native_foreign_body(body: Ast.DefBody, rest: List<&2, String>) -> List<&2, String>:
  match body:
    case Ast.DefImports{paths}: List.append(&2, String, paths, rest)
    case _: rest

def native_foreign_definition(definition: Ast.Definition, rest: List<&2, String>) -> List<&2, String>:
  match definition:
    case Ast.Definition{_, _, _, body, _, _}: native_foreign_body(body, rest)

def native_foreign_paths(declarations: List<&2, Ast.TopLevel>) -> List<&2, String>:
  match declarations:
    case Nil{}: Nil{}
    case +top <> rest:
      match top:
        case Ast.DefTop{definition}: native_foreign_definition(definition, native_foreign_paths(rest))
        case _: native_foreign_paths(rest)

def native_parse_success(+module: Ast.Module) -> NativeParsed:
  match module:
    case Ast.Module{_, imports, declarations}:
      NativeParsed{native_import_paths(imports), native_foreign_paths(declarations), namespace => parsed_module(namespace, module)}

def native_parse_result(result: FeedbackRun) -> NativeParsed:
  match result:
    case FeedbackComplete{Value_17{ParseSuccess{module}}, _}:
      native_parse_success(module)
    case FeedbackComplete{Value_17{ParseFailure{message, _, _, _}}, _}:
      NativeParseFailure{message}
    case _:
      NativeParseFailure{"parser fuel exhausted or feedback invariant failure"}

def native_parse(input: FeedbackFuel & (String & String)) -> NativeParsed:
  (fuel, (file, source)) = input
  native_parse_result(parse_with_fuel(fuel, file, source))

def native_expand_value(result: Template.ExpandResult) -> NativeResult<List<&2, Loader.LoadedModule>>:
  match result:
    case Template.ExpandSuccess{modules}: NativeAccepted{modules}
    case Template.ExpandFailure{message, _}: NativeRejected{message}

def native_expand_result(box: Template.TemplateValue<Template.ExpandResult>) -> NativeResult<List<&2, Loader.LoadedModule>>:
  match box:
    case Template.TemplateValue{value}: native_expand_value(value)

# The host selects the unchanged public emitter entry point as data, so both
# library emission and the runnable module emission used by source fixtures go
# through the same checked JSEmit steps. No host-side source rewriting. The
# host builds the one public BIR.SourceFile carrier directly from actual bytes.
type NativeEmit is Data:
  NativeLibrary{exports: List<&2, String>, files: List<&2, BIR.SourceFile>}
  NativeModule{files: List<&2, BIR.SourceFile>}

def native_emit_start(program: Checked.CheckedProgram, request: NativeEmit) -> Emitter.EmitterRun<Emitter.EmitResult>:
  match request:
    case NativeLibrary{exports, files}: emit_library_start(program, exports, files)
    case NativeModule{files}: emit_modules_start(program, files)

def native_check_value(result: Checked.CheckResult) -> NativeResult<(NativeEmit -> Emitter.EmitterRun<Emitter.EmitResult>)>:
  match result:
    case Checked.CheckSuccess{program}: NativeAccepted{request => native_emit_start(program, request)}
    case Checked.CheckFailure{Checked.Diagnostic{_, _, message, _, _}}: NativeRejected{message}

def native_check_result(box: Checker.CheckerValue<Checked.CheckResult>) -> NativeResult<(NativeEmit -> Emitter.EmitterRun<Emitter.EmitResult>)>:
  match box:
    case Checker.CheckerValue{value}: native_check_value(value)

# The C target uses the same passive carrier and the same opaque chunk protocol;
# only the request differs (it carries the runtime source bytes) and the result
# type is CEmit's. The host builds the request, never a second carrier.
# Direct fields: a nested Data field would be inlined at its value-layout
# width, so the request mirrors the authoritative node layout instead of
# carrying a boxed aggregate. Book order rules: these live definitions must
# precede their first use.
type NativeCEmit is Data:
  NativeCLibrary{exports: List<&2, String>, runtime: String, files: List<&2, BIR.SourceFile>}
  NativeCModule{runtime: String, files: List<&2, BIR.SourceFile>}

def native_c_emit_start(program: Checked.CheckedProgram, request: NativeCEmit) -> CEmitter.CEmitterRun<CEmitter.EmitResult>:
  match request:
    case NativeCLibrary{exports, runtime, files}: emit_c_library_start(program, exports, runtime, files)
    case NativeCModule{runtime, files}: emit_c_modules_start(program, runtime, files)

def native_c_check_value(result: Checked.CheckResult) -> NativeResult<(NativeCEmit -> CEmitter.CEmitterRun<CEmitter.EmitResult>)>:
  match result:
    case Checked.CheckSuccess{program}: NativeAccepted{request => native_c_emit_start(program, request)}
    case Checked.CheckFailure{Checked.Diagnostic{_, _, message, _, _}}: NativeRejected{message}

def native_c_check_result(box: Checker.CheckerValue<Checked.CheckResult>) -> NativeResult<(NativeCEmit -> CEmitter.CEmitterRun<CEmitter.EmitResult>)>:
  match box:
    case Checker.CheckerValue{value}: native_c_check_value(value)

def native_c_emit(input: (NativeCEmit -> CEmitter.CEmitterRun<CEmitter.EmitResult>) & NativeCEmit) -> CEmitter.CEmitterRun<CEmitter.EmitResult>:
  (emit, request) = input
  emit(request)

def native_emit(input: (NativeEmit -> Emitter.EmitterRun<Emitter.EmitResult>) & NativeEmit) -> Emitter.EmitterRun<Emitter.EmitResult>:
  (emit, request) = input
  emit(request)

def native_emit_value(result: Emitter.EmitResult) -> NativeResult<String>:
  match result:
    case Emitter.EmitSuccess{source}: NativeAccepted{source}
    case Emitter.EmitFailure{message, _}: NativeRejected{message}

def native_emit_result(box: Emitter.EmitterValue<Emitter.EmitResult>) -> NativeResult<String>:
  match box:
    case Emitter.EmitterValue{value}: native_emit_value(value)

# Native reflection advances chunk64 before exposing only one owning thunk.
# C never observes the existential progress/stack or a source continuation.
type NativeTemplateView<-A: Type> is Type:
  NativeTemplateFinished{take: Unit -> Template.TemplateValue<A>}
  NativeTemplateMore{next: Unit -> Template.TemplateRun<A>}

type NativeCheckerView<-A: Type> is Type:
  NativeCheckerFinished{take: Unit -> Checker.CheckerValue<A>}
  NativeCheckerMore{next: Unit -> Checker.CheckerRun<A>}

type NativeEmitterView<-A: Type> is Type:
  NativeEmitterFinished{take: Unit -> Emitter.EmitterValue<A>}
  NativeEmitterMore{next: Unit -> Emitter.EmitterRun<A>}

def native_template_view_ready(-A: Type, run: Template.TemplateRun<A>) -> NativeTemplateView<A>:
  match run:
    case Template.TemplateRunFinished{box}:
      NativeTemplateFinished{unit => box}
    case Template.TemplateRunState{B, progress, stack}:
      NativeTemplateMore{unit => Template.TemplateRunState{B, progress, stack}}

def native_template_view(-A: Type, run: Template.TemplateRun<A>) -> NativeTemplateView<A>:
  native_template_view_ready(A, Template.template_chunk(A, 64n, run))

def native_checker_view_ready(-A: Type, run: Checker.CheckerRun<A>) -> NativeCheckerView<A>:
  match run:
    case Checker.CheckerRunFinished{box}:
      NativeCheckerFinished{unit => box}
    case Checker.CheckerRunState{B, progress, stack}:
      NativeCheckerMore{unit => Checker.CheckerRunState{B, progress, stack}}

def native_checker_view(-A: Type, run: Checker.CheckerRun<A>) -> NativeCheckerView<A>:
  native_checker_view_ready(A, Checker.checker_chunk(A, 64n, run))

def native_emitter_view_ready(-A: Type, run: Emitter.EmitterRun<A>) -> NativeEmitterView<A>:
  match run:
    case Emitter.EmitterRunFinished{box}:
      NativeEmitterFinished{unit => box}
    case Emitter.EmitterRunState{B, progress, stack}:
      NativeEmitterMore{unit => Emitter.EmitterRunState{B, progress, stack}}

def native_emitter_view(-A: Type, run: Emitter.EmitterRun<A>) -> NativeEmitterView<A>:
  native_emitter_view_ready(A, Emitter.emitter_chunk(A, 64n, run))




def native_c_emit_value(result: CEmitter.EmitResult) -> NativeResult<String>:
  match result:
    case CEmitter.EmitSuccess{source}: NativeAccepted{source}
    case CEmitter.EmitFailure{message, _}: NativeRejected{message}

def native_c_emit_result(box: CEmitter.CEmitterValue<CEmitter.EmitResult>) -> NativeResult<String>:
  match box:
    case CEmitter.CEmitterValue{value}: native_c_emit_value(value)

type NativeCEmitterView<-A: Type> is Type:
  NativeCEmitterFinished{take: Unit -> CEmitter.CEmitterValue<A>}
  NativeCEmitterMore{next: Unit -> CEmitter.CEmitterRun<A>}

def native_c_emitter_view_ready(-A: Type, run: CEmitter.CEmitterRun<A>) -> NativeCEmitterView<A>:
  match run:
    case CEmitter.CEmitterRunFinished{box}:
      NativeCEmitterFinished{unit => box}
    case CEmitter.CEmitterRunState{B, progress, stack}:
      NativeCEmitterMore{unit => CEmitter.CEmitterRunState{B, progress, stack}}

def native_c_emitter_view(-A: Type, run: CEmitter.CEmitterRun<A>) -> NativeCEmitterView<A>:
  native_c_emitter_view_ready(A, CEmitter.cemit_chunk(A, 64n, run))

# Reused callbacks below are closed and capture-free. The native Run preserves
# the original source/result relationship; each returned thunk is consumed once.
def native_experiment(
  parse: (FeedbackFuel & (String & String)) -> NativeParsed,
  expand: List<&2, Loader.LoadedModule> -> Template.TemplateRun<Template.ExpandResult>,
  template_view: (@-A: Type -> @run: Template.TemplateRun<A> -> NativeTemplateView<A>),
  expand_result: Template.TemplateValue<Template.ExpandResult> -> NativeResult<List<&2, Loader.LoadedModule>>,
  check: List<&2, Loader.LoadedModule> -> Checker.CheckerRun<Checked.CheckResult>,
  checker_view: (@-A: Type -> @run: Checker.CheckerRun<A> -> NativeCheckerView<A>),
  check_result: Checker.CheckerValue<Checked.CheckResult> -> NativeResult<(NativeEmit -> Emitter.EmitterRun<Emitter.EmitResult>)>,
  emit: ((NativeEmit -> Emitter.EmitterRun<Emitter.EmitResult>) & NativeEmit) -> Emitter.EmitterRun<Emitter.EmitResult>,
  emitter_view: (@-A: Type -> @run: Emitter.EmitterRun<A> -> NativeEmitterView<A>),
  emit_result: Emitter.EmitterValue<Emitter.EmitResult> -> NativeResult<String>,
  c_emit: ((NativeCEmit -> CEmitter.CEmitterRun<CEmitter.EmitResult>) & NativeCEmit) -> CEmitter.CEmitterRun<CEmitter.EmitResult>,
  c_emitter_view: (@-A: Type -> @run: CEmitter.CEmitterRun<A> -> NativeCEmitterView<A>),
  c_emit_result: CEmitter.CEmitterValue<CEmitter.EmitResult> -> NativeResult<String>,
  c_check_result: Checker.CheckerValue<Checked.CheckResult> -> NativeResult<(NativeCEmit -> CEmitter.CEmitterRun<CEmitter.EmitResult>)>
) -> IO(Unit):
  import "./native_compiler_host.c"

def main() -> IO(Unit):
  native_experiment(
    native_parse,
    expand_modules_start,
    native_template_view,
    native_expand_result,
    check_expanded_start,
    native_checker_view,
    native_check_result,
    native_emit,
    native_emitter_view,
    native_emit_result,
    native_c_emit,
    native_c_emitter_view,
    native_c_emit_result,
    native_c_check_result
  )
