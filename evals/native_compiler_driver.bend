# Experimental native CPU host. Loaded after the unchanged compiler root into
# its canonical book; all definitions in both roots are validated normally.
import Base
import ../bend2/selfhost/ast.bend as Ast
import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/checked_frontend.bend as Checked
import ../checkpoints/template_steps_v1.bend as Template
import ../checkpoints/checker_core_steps_v1.bend as Checker
import ../checkpoints/js_emit_steps_v1.bend as Emitter

# The loader closure owns the parser's original immutable Module. The host can
# inspect import paths but cannot replace a parsed tree or checked result.
type NativeParsed is Type:
  NativeParsed{imports: List<&2, String>, load: String -> Loader.LoadedModule}
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

def native_parse_success(+module: Ast.Module) -> NativeParsed:
  match module:
    case Ast.Module{_, imports, _}:
      NativeParsed{native_import_paths(imports), namespace => parsed_module(namespace, module)}

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

def native_check_value(result: Checked.CheckResult) -> NativeResult<List<&2, String> -> Emitter.EmitterProgress<Emitter.EmitResult>>:
  match result:
    case Checked.CheckSuccess{program}: NativeAccepted{exports => emit_library_start(program, exports)}
    case Checked.CheckFailure{Checked.Diagnostic{_, _, message, _, _}}: NativeRejected{message}

def native_check_result(box: Checker.CheckerValue<Checked.CheckResult>) -> NativeResult<List<&2, String> -> Emitter.EmitterProgress<Emitter.EmitResult>>:
  match box:
    case Checker.CheckerValue{value}: native_check_value(value)

def native_emit(input: (List<&2, String> -> Emitter.EmitterProgress<Emitter.EmitResult>) & List<&2, String>) -> Emitter.EmitterProgress<Emitter.EmitResult>:
  (emit, exports) = input
  emit(exports)

def native_emit_value(result: Emitter.EmitResult) -> NativeResult<String>:
  match result:
    case Emitter.EmitSuccess{source}: NativeAccepted{source}
    case Emitter.EmitFailure{message, _}: NativeRejected{message}

def native_emit_result(box: Emitter.EmitterValue<Emitter.EmitResult>) -> NativeResult<String>:
  match box:
    case Emitter.EmitterValue{value}: native_emit_value(value)

# A nonrecursive reflection step hides the native backend's flattened request
# layouts from C without erasing the relationship between next and resume.
# The existential result type preserves the SAME boxed next/resume domain.
type NativeTemplateView<-A: Type> is Type:
  NativeTemplateFinished{take: Unit -> Template.TemplateValue<A>}
  NativeTemplateMore{-B: Type, next: Unit -> Template.TemplateProgress<B>, resume: (@box: Template.TemplateValue<B> -> Template.TemplateProgress<A>)}

type NativeCheckerView<-A: Type> is Type:
  NativeCheckerFinished{take: Unit -> Checker.CheckerValue<A>}
  NativeCheckerMore{-B: Type, next: Unit -> Checker.CheckerProgress<B>, resume: (@box: Checker.CheckerValue<B> -> Checker.CheckerProgress<A>)}

type NativeEmitterView<-A: Type> is Type:
  NativeEmitterFinished{take: Unit -> Emitter.EmitterValue<A>}
  NativeEmitterMore{-B: Type, next: Unit -> Emitter.EmitterProgress<B>, resume: (@box: Emitter.EmitterValue<B> -> Emitter.EmitterProgress<A>)}

def native_template_view_ready(-A: Type, progress: Template.TemplateProgress<A>) -> NativeTemplateView<A>:
  match progress:
    case Template.TemplateFinished{box}:
      NativeTemplateFinished{unit => box}
    case Template.TemplatePending{request, resume}:
      NativeTemplateMore{Template.template_result(request), unit => template_step(request), resume}
    case Template.TemplateDirect{R, request, arguments, invoke, resume}:
      NativeTemplateMore{Template.template_result(request), unit => invoke(arguments), resume}
    case Template.TemplateBound{B, inner, resume}:
      NativeTemplateMore{B, unit => inner, resume}

def native_template_view(-A: Type, progress: Template.TemplateProgress<A>) -> NativeTemplateView<A>:
  native_template_view_ready(A, Template.template_chunk(A, 64n, progress))

def native_checker_view_ready(-A: Type, progress: Checker.CheckerProgress<A>) -> NativeCheckerView<A>:
  match progress:
    case Checker.CheckerFinished{box}:
      NativeCheckerFinished{unit => box}
    case Checker.CheckerPending{request, resume}:
      NativeCheckerMore{Checker.checker_result(request), unit => checker_step(request), resume}
    case Checker.CheckerDirect{R, request, arguments, invoke, resume}:
      NativeCheckerMore{Checker.checker_result(request), unit => invoke(arguments), resume}
    case Checker.CheckerBound{B, inner, resume}:
      NativeCheckerMore{B, unit => inner, resume}

def native_checker_view(-A: Type, progress: Checker.CheckerProgress<A>) -> NativeCheckerView<A>:
  native_checker_view_ready(A, Checker.checker_chunk(A, 64n, progress))

def native_emitter_view_ready(-A: Type, progress: Emitter.EmitterProgress<A>) -> NativeEmitterView<A>:
  match progress:
    case Emitter.EmitterFinished{box}:
      NativeEmitterFinished{unit => box}
    case Emitter.EmitterPending{request, resume}:
      NativeEmitterMore{Emitter.emitter_result(request), unit => emitter_step(request), resume}
    case Emitter.EmitterDirect{R, request, arguments, invoke, resume}:
      NativeEmitterMore{Emitter.emitter_result(request), unit => invoke(arguments), resume}
    case Emitter.EmitterBound{B, inner, resume}:
      NativeEmitterMore{B, unit => inner, resume}

def native_emitter_view(-A: Type, progress: Emitter.EmitterProgress<A>) -> NativeEmitterView<A>:
  native_emitter_view_ready(A, Emitter.emitter_chunk(A, 64n, progress))

# C drives only the existing typed request/invoke/resume domains. Each affine
# progress, argument record and continuation is consumed once. Reused callbacks
# below are closed, capture-free values (the C boundary checks that fact).
def native_experiment(
  parse: (FeedbackFuel & (String & String)) -> NativeParsed,
  expand: List<&2, Loader.LoadedModule> -> Template.TemplateProgress<Template.ExpandResult>,
  template_view: (@-A: Type -> @progress: Template.TemplateProgress<A> -> NativeTemplateView<A>),
  expand_result: Template.TemplateValue<Template.ExpandResult> -> NativeResult<List<&2, Loader.LoadedModule>>,
  check: List<&2, Loader.LoadedModule> -> Checker.CheckerProgress<Checked.CheckResult>,
  checker_view: (@-A: Type -> @progress: Checker.CheckerProgress<A> -> NativeCheckerView<A>),
  check_result: Checker.CheckerValue<Checked.CheckResult> -> NativeResult<List<&2, String> -> Emitter.EmitterProgress<Emitter.EmitResult>>,
  emit: ((List<&2, String> -> Emitter.EmitterProgress<Emitter.EmitResult>) & List<&2, String>) -> Emitter.EmitterProgress<Emitter.EmitResult>,
  emitter_view: (@-A: Type -> @progress: Emitter.EmitterProgress<A> -> NativeEmitterView<A>),
  emit_result: Emitter.EmitterValue<Emitter.EmitResult> -> NativeResult<String>
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
    native_emit_result
  )
