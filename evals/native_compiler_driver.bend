# Experimental native CPU host. Loaded after the unchanged compiler root into
# its canonical book; all definitions in both roots are validated normally.
import Base
import ../bend2/selfhost/ast.bend as Ast
import ../bend2/selfhost/loaded_module.bend as Loader
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
    case FeedbackComplete{Value_15{ParseSuccess{module}}, _}:
      native_parse_success(module)
    case FeedbackComplete{Value_15{ParseFailure{message, _, _, _}}, _}:
      NativeParseFailure{message}
    case _:
      NativeParseFailure{"parser fuel exhausted or feedback invariant failure"}

def native_parse(input: FeedbackFuel & (String & String)) -> NativeParsed:
  (fuel, (file, source)) = input
  native_parse_result(parse_with_fuel(fuel, file, source))

def native_expand_result(result: Template.ExpandResult) -> NativeResult<List<&2, Loader.LoadedModule>>:
  match result:
    case Template.ExpandSuccess{modules}: NativeAccepted{modules}
    case Template.ExpandFailure{message, _}: NativeRejected{message}

def native_check_result(result: Checker.CheckResult) -> NativeResult<List<&2, Loader.LoadedModule>>:
  match result:
    case Checker.CheckSuccess{modules}: NativeAccepted{modules}
    case Checker.CheckFailure{Checker.Diagnostic{_, _, message, _, _}}: NativeRejected{message}

def native_emit(input: List<&2, Loader.LoadedModule> & List<&2, String>) -> Emitter.EmitterProgress<Emitter.EmitResult>:
  (modules, exports) = input
  emitter_step(Emitter.EmitterRequestGroup_8{Emitter.EmitterRequest_emit_library{modules, exports}})

def native_emit_result(result: Emitter.EmitResult) -> NativeResult<String>:
  match result:
    case Emitter.EmitSuccess{source}: NativeAccepted{source}
    case Emitter.EmitFailure{message, _}: NativeRejected{message}

# A nonrecursive reflection step hides the native backend's flattened request
# layouts from C without erasing the relationship between next and resume.
# The existential request remains the SAME original typed continuation index.
type NativeTemplateView<-A: Type> is Type:
  NativeTemplateFinished{value: A}
  NativeTemplateMore{-request: Template.TemplateRequest, next: Unit -> Template.TemplateProgress<Template.template_result(request)>, resume: Template.template_resume_type(Template.TemplateProgress<A>, request)}

type NativeCheckerView<-A: Type> is Type:
  NativeCheckerFinished{value: A}
  NativeCheckerMore{-request: Checker.CheckerRequest, next: Unit -> Checker.CheckerProgress<Checker.checker_result(request)>, resume: Checker.checker_resume_type(Checker.CheckerProgress<A>, request)}

type NativeEmitterView<-A: Type> is Type:
  NativeEmitterFinished{value: A}
  NativeEmitterMore{-request: Emitter.EmitterRequest, next: Unit -> Emitter.EmitterProgress<Emitter.emitter_result(request)>, resume: Emitter.emitter_resume_type(Emitter.EmitterProgress<A>, request)}

def native_template_view(-A: Type, progress: Template.TemplateProgress<A>) -> NativeTemplateView<A>:
  match progress:
    case Template.TemplateFinished{value}:
      NativeTemplateFinished{value}
    case Template.TemplatePending{request, resume}:
      NativeTemplateMore{request, unit => template_step(request), resume}
    case Template.TemplateDirect{R, request, arguments, invoke, resume}:
      NativeTemplateMore{request, unit => invoke(arguments), resume}

def native_checker_view(-A: Type, progress: Checker.CheckerProgress<A>) -> NativeCheckerView<A>:
  match progress:
    case Checker.CheckerFinished{value}:
      NativeCheckerFinished{value}
    case Checker.CheckerPending{request, resume}:
      NativeCheckerMore{request, unit => checker_step(request), resume}
    case Checker.CheckerDirect{R, request, arguments, invoke, resume}:
      NativeCheckerMore{request, unit => invoke(arguments), resume}

def native_emitter_view(-A: Type, progress: Emitter.EmitterProgress<A>) -> NativeEmitterView<A>:
  match progress:
    case Emitter.EmitterFinished{value}:
      NativeEmitterFinished{value}
    case Emitter.EmitterPending{request, resume}:
      NativeEmitterMore{request, unit => emitter_step(request), resume}
    case Emitter.EmitterDirect{R, request, arguments, invoke, resume}:
      NativeEmitterMore{request, unit => invoke(arguments), resume}

# C drives only the existing typed request/invoke/resume domains. Each affine
# progress, argument record and continuation is consumed once. Reused callbacks
# below are closed, capture-free values (the C boundary checks that fact).
def native_experiment(
  parse: (FeedbackFuel & (String & String)) -> NativeParsed,
  expand: List<&2, Loader.LoadedModule> -> Template.TemplateProgress<Template.ExpandResult>,
  template_view: (@-A: Type -> @progress: Template.TemplateProgress<A> -> NativeTemplateView<A>),
  expand_result: Template.ExpandResult -> NativeResult<List<&2, Loader.LoadedModule>>,
  check: List<&2, Loader.LoadedModule> -> Checker.CheckerProgress<Checker.CheckResult>,
  checker_view: (@-A: Type -> @progress: Checker.CheckerProgress<A> -> NativeCheckerView<A>),
  check_result: Checker.CheckResult -> NativeResult<List<&2, Loader.LoadedModule>>,
  emit: (List<&2, Loader.LoadedModule> & List<&2, String>) -> Emitter.EmitterProgress<Emitter.EmitResult>,
  emitter_view: (@-A: Type -> @progress: Emitter.EmitterProgress<A> -> NativeEmitterView<A>),
  emit_result: Emitter.EmitResult -> NativeResult<String>
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
