import Base
import ../checkpoints/template_steps_v1.bend as Template
import ../checkpoints/checker_core_steps_v1.bend as Checker
import ../checkpoints/emitter_steps_v1.bend as Emit
import ../bend2/selfhost/backend_ir.bend as BIR
import ../bend2/selfhost/ast.bend as Ast
import ../checkpoints/native_stage_profile_generated_fixture.bend as EmitFixture

# Diagnostic-only typed view for the native chunk driver. It reports the
# operational shape of the progress value after one bounded chunk (64 native
# advances). It never inspects a request payload and never claims a source
# substage or a CPU cost; the C side only counts shapes per phase.
type NativeTemplateStageView<-A: Type> is Type:
  NativeTemplateStageFinished{take: Unit -> Template.TemplateValue<A>}
  NativeTemplateStageMore{next: Unit -> Template.TemplateRun<A>, stage: U32}

type NativeCheckerStageView<-A: Type> is Type:
  NativeCheckerStageFinished{take: Unit -> Checker.CheckerValue<A>}
  NativeCheckerStageMore{next: Unit -> Checker.CheckerRun<A>, stage: U32}

type NativeEmitterStageView<-A: Type> is Type:
  NativeEmitterStageFinished{take: Unit -> Emit.EmitterValue<A>}
  NativeEmitterStageMore{next: Unit -> Emit.EmitterRun<A>, stage: U32}

type NativeEmitOutcome is Data:
  NativeEmitSuccess{source: String}
  NativeEmitFailure{message: String, span: Ast.SourceSpan}

# Emitter stage codes: 0 Finished, 1 Direct (erased scheduling request),
# 2 Bound, 100+N Pending whose outer request-group variant is N. Only the
# outer request group is classified; payload fields stay owned and untouched.
def native_emitter_stage_state(-A: Type, -B: Type, progress: Emit.EmitterProgress<B>, stack: Emit.EmitterStack<B, A>) -> NativeEmitterStageView<A>:
  match progress:
    case Emit.EmitterFinished{box}:
      NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterFinished{box}, stack}, 0}
    case Emit.EmitterPending{request, resume}:
      match request:
        case Emit.EmitterRequestGroup_0{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_0{inner}, resume}, stack}, 100}
        case Emit.EmitterRequestGroup_1{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_1{inner}, resume}, stack}, 101}
        case Emit.EmitterRequestGroup_2{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_2{inner}, resume}, stack}, 102}
        case Emit.EmitterRequestGroup_3{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_3{inner}, resume}, stack}, 103}
        case Emit.EmitterRequestGroup_4{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_4{inner}, resume}, stack}, 104}
        case Emit.EmitterRequestGroup_5{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_5{inner}, resume}, stack}, 105}
        case Emit.EmitterRequestGroup_6{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_6{inner}, resume}, stack}, 106}
        case Emit.EmitterRequestGroup_7{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_7{inner}, resume}, stack}, 107}
        case Emit.EmitterRequestGroup_8{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_8{inner}, resume}, stack}, 108}
        case Emit.EmitterRequestGroup_9{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_9{inner}, resume}, stack}, 109}
        case Emit.EmitterRequestGroup_10{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_10{inner}, resume}, stack}, 110}
        case Emit.EmitterRequestGroup_11{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_11{inner}, resume}, stack}, 111}
        case Emit.EmitterRequestGroup_12{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_12{inner}, resume}, stack}, 112}
        case Emit.EmitterRequestGroup_13{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_13{inner}, resume}, stack}, 113}
        case Emit.EmitterRequestGroup_14{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_14{inner}, resume}, stack}, 114}
        case Emit.EmitterRequestGroup_15{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_15{inner}, resume}, stack}, 115}
        case Emit.EmitterRequestGroup_16{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_16{inner}, resume}, stack}, 116}
        case Emit.EmitterRequestGroup_17{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_17{inner}, resume}, stack}, 117}
        case Emit.EmitterRequestGroup_18{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_18{inner}, resume}, stack}, 118}
        case Emit.EmitterRequestGroup_19{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_19{inner}, resume}, stack}, 119}
        case Emit.EmitterRequestGroup_20{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_20{inner}, resume}, stack}, 120}
        case Emit.EmitterRequestGroup_21{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_21{inner}, resume}, stack}, 121}
        case Emit.EmitterRequestGroup_22{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_22{inner}, resume}, stack}, 122}
        case Emit.EmitterRequestGroup_23{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_23{inner}, resume}, stack}, 123}
        case Emit.EmitterRequestGroup_24{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_24{inner}, resume}, stack}, 124}
        case Emit.EmitterRequestGroup_25{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_25{inner}, resume}, stack}, 125}
        case Emit.EmitterRequestGroup_26{inner}:
          NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterPending{Emit.EmitterRequestGroup_26{inner}, resume}, stack}, 126}
    case Emit.EmitterDirect{R, request, arguments, invoke, resume}:
      NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterDirect{R, request, arguments, invoke, resume}, stack}, 1}
    case Emit.EmitterBound{C, inner, resume}:
      NativeEmitterStageMore{unit => Emit.EmitterRunState{B, Emit.EmitterBound{C, inner, resume}, stack}, 2}

def native_template_stage_state(-A: Type, -B: Type, progress: Template.TemplateProgress<B>, stack: Template.TemplateStack<B, A>) -> NativeTemplateStageView<A>:
  match progress:
    case Template.TemplateFinished{box}:
      NativeTemplateStageMore{unit => Template.TemplateRunState{B, Template.TemplateFinished{box}, stack}, 0}
    case Template.TemplatePending{request, resume}:
      NativeTemplateStageMore{unit => Template.TemplateRunState{B, Template.TemplatePending{request, resume}, stack}, 1}
    case Template.TemplateDirect{R, request, arguments, invoke, resume}:
      NativeTemplateStageMore{unit => Template.TemplateRunState{B, Template.TemplateDirect{R, request, arguments, invoke, resume}, stack}, 2}
    case Template.TemplateBound{C, inner, resume}:
      NativeTemplateStageMore{unit => Template.TemplateRunState{B, Template.TemplateBound{C, inner, resume}, stack}, 3}

def native_checker_stage_state(-A: Type, -B: Type, progress: Checker.CheckerProgress<B>, stack: Checker.CheckerStack<B, A>) -> NativeCheckerStageView<A>:
  match progress:
    case Checker.CheckerFinished{box}:
      NativeCheckerStageMore{unit => Checker.CheckerRunState{B, Checker.CheckerFinished{box}, stack}, 0}
    case Checker.CheckerPending{request, resume}:
      NativeCheckerStageMore{unit => Checker.CheckerRunState{B, Checker.CheckerPending{request, resume}, stack}, 1}
    case Checker.CheckerDirect{R, request, arguments, invoke, resume}:
      NativeCheckerStageMore{unit => Checker.CheckerRunState{B, Checker.CheckerDirect{R, request, arguments, invoke, resume}, stack}, 2}
    case Checker.CheckerBound{C, inner, resume}:
      NativeCheckerStageMore{unit => Checker.CheckerRunState{B, Checker.CheckerBound{C, inner, resume}, stack}, 3}

def native_template_stage_ready(-A: Type, run: Template.TemplateRun<A>) -> NativeTemplateStageView<A>:
  match run:
    case Template.TemplateRunFinished{box}:
      NativeTemplateStageFinished{unit => box}
    case Template.TemplateRunState{B, progress, stack}:
      native_template_stage_state(A, B, progress, stack)

def native_template_stage_view(-A: Type, run: Template.TemplateRun<A>) -> NativeTemplateStageView<A>:
  native_template_stage_ready(A, Template.template_chunk(A, 64n, run))

def native_checker_stage_ready(-A: Type, run: Checker.CheckerRun<A>) -> NativeCheckerStageView<A>:
  match run:
    case Checker.CheckerRunFinished{box}:
      NativeCheckerStageFinished{unit => box}
    case Checker.CheckerRunState{B, progress, stack}:
      native_checker_stage_state(A, B, progress, stack)

def native_checker_stage_view(-A: Type, run: Checker.CheckerRun<A>) -> NativeCheckerStageView<A>:
  native_checker_stage_ready(A, Checker.checker_chunk(A, 64n, run))

def native_emitter_stage_ready(-A: Type, run: Emit.EmitterRun<A>) -> NativeEmitterStageView<A>:
  match run:
    case Emit.EmitterRunFinished{box}:
      NativeEmitterStageFinished{unit => box}
    case Emit.EmitterRunState{B, progress, stack}:
      native_emitter_stage_state(A, B, progress, stack)

def native_emitter_stage_view(-A: Type, run: Emit.EmitterRun<A>) -> NativeEmitterStageView<A>:
  native_emitter_stage_ready(A, Emit.emitter_chunk(A, 64n, run))
# Profile-only native entry points. The production native_experiment keeps its
# 14 callback positions and 13 public names; this diagnostic driver is built as
# a separate small component and never participates in acceptance.
def native_stage_template(start: Unit -> Template.TemplateRun<Unit>, view: (@-A: Type -> @run: Template.TemplateRun<A> -> NativeTemplateStageView<A>)) -> IO(Unit):
  import "./native_stage_profile_host.c"

def native_stage_checker(start: Unit -> Checker.CheckerRun<Unit>, view: (@-A: Type -> @run: Checker.CheckerRun<A> -> NativeCheckerStageView<A>)) -> IO(Unit):
  import "./native_stage_profile_host.c"

def native_stage_template_pending(start: Unit -> Template.TemplateRun<Unit>, view: (@-A: Type -> @run: Template.TemplateRun<A> -> NativeTemplateStageView<A>)) -> IO(Unit):
  import "./native_stage_profile_host.c"

def native_stage_emitter(start: Unit -> Emit.EmitterRun<Emit.cps_provider_6_EmitResult>, view: (@-A: Type -> @run: Emit.EmitterRun<A> -> NativeEmitterStageView<A>), outcome: (@box: Emit.EmitterValue<Emit.cps_provider_6_EmitResult> -> NativeEmitOutcome)) -> IO(NativeEmitOutcome):
  import "./native_stage_profile_host.c"

# The fixture seeds the real generated Run machine with a finite finished-value
# stack. Chunk64 unwinds it one frame per advance, so the host observes genuine
# bounded chunk transitions without inventing a compiler request or source span.
def profile_template_value() -> Template.TemplateValue<Unit>:
  Template.TemplateValue{Unit{}}

def profile_template_resume(box: Template.TemplateValue<Unit>) -> Template.TemplateProgress<Unit>:
  Template.TemplateFinished{box}

def profile_template_stack(n: Nat) -> Template.TemplateStack<Unit, Unit>:
  match n:
    case 0n: Template.TemplateStackDone{{==}}
    case 1n+rest: Template.TemplateStackMore{Unit, profile_template_resume, profile_template_stack(rest)}

def profile_checker_value() -> Checker.CheckerValue<Unit>:
  Checker.CheckerValue{Unit{}}

def profile_checker_resume(box: Checker.CheckerValue<Unit>) -> Checker.CheckerProgress<Unit>:
  Checker.CheckerFinished{box}

def profile_checker_stack(n: Nat) -> Checker.CheckerStack<Unit, Unit>:
  match n:
    case 0n: Checker.CheckerStackDone{{==}}
    case 1n+rest: Checker.CheckerStackMore{Unit, profile_checker_resume, profile_checker_stack(rest)}

def profile_template_bound(n: Nat, inner: Template.TemplateProgress<Unit>) -> Template.TemplateProgress<Unit>:
  match n:
    case 0n: inner
    case 1n+rest: Template.TemplateBound{Unit, profile_template_bound(rest, inner), profile_template_resume}

def profile_template_pending() -> Template.TemplateProgress<Unit>:
  Template.TemplatePending{Template.TemplateRequestGroup_0{Template.TemplateRequest_strip_namespace{"a", "b"}}, box => Template.TemplateFinished{Template.TemplateValue{Unit{}}}}

def profile_template_start(unit: Unit) -> Template.TemplateRun<Unit>:
  Template.TemplateRunState{Unit, profile_template_bound(65n, profile_template_pending()), profile_template_stack(0n)}

def profile_template_pending_start(unit: Unit) -> Template.TemplateRun<Unit>:
  Template.TemplateRunState{Unit, profile_template_bound(64n, profile_template_pending()), profile_template_stack(0n)}

# A real canonical Emitter request: the generated c_emit_core render path
# receives the lowered BIR.Program from a frozen real checked source, the real
# runtime and the exact declared C source files. It returns a non-empty
# EmitSuccess C translation unit or the original renderer diagnostic.
def profile_emitter_runtime() -> String:
  EmitFixture.runtime()

def profile_emitter_program() -> BIR.Program:
  EmitFixture.program()

def profile_emitter_files() -> List<&2, BIR.SourceFile>:
  EmitFixture.files()

def profile_emitter_outcome(box: Emit.EmitterValue<Emit.cps_provider_6_EmitResult>) -> NativeEmitOutcome:
  match box:
    case Emit.EmitterValue{value}:
      match value:
        case Emit.cps_provider_6_EmitSuccess{source}: NativeEmitSuccess{source}
        case Emit.cps_provider_6_EmitFailure{message, span}: NativeEmitFailure{message, span}

def profile_emitter_report(outcome: NativeEmitOutcome) -> IO(Unit):
  match outcome:
    case NativeEmitSuccess{source}: IO.print("EMIT_SUCCESS")
    case NativeEmitFailure{message, span}:
      do IO<Unit>:
        Unit <- IO.print(String.concat(["EMIT_FAILURE: ", message]))
        IO.exit(1)

def profile_emitter_pending() -> Emit.EmitterProgress<Emit.cps_provider_6_EmitResult>:
  Emit.EmitterPending{Emit.EmitterRequestGroup_18{Emit.EmitterRequest_cps_provider_6_render{
    profile_emitter_program(), profile_emitter_runtime(), profile_emitter_files()}},
    box => Emit.EmitterFinished{box}}

def profile_emitter_resume(box: Emit.EmitterValue<Emit.cps_provider_6_EmitResult>) -> Emit.EmitterProgress<Emit.cps_provider_6_EmitResult>:
  Emit.EmitterFinished{box}

def profile_emitter_bound(n: Nat, inner: Emit.EmitterProgress<Emit.cps_provider_6_EmitResult>) -> Emit.EmitterProgress<Emit.cps_provider_6_EmitResult>:
  match n:
    case 0n: inner
    case 1n+rest: Emit.EmitterBound{Emit.cps_provider_6_EmitResult, profile_emitter_bound(rest, inner), profile_emitter_resume}

def profile_emitter_stack(n: Nat) -> Emit.EmitterStack<Emit.cps_provider_6_EmitResult, Emit.cps_provider_6_EmitResult>:
  match n:
    case 0n: Emit.EmitterStackDone{{==}}
    case 1n+rest: Emit.EmitterStackMore{Emit.cps_provider_6_EmitResult, profile_emitter_resume, profile_emitter_stack(rest)}

def profile_emitter_start(unit: Unit) -> Emit.EmitterRun<Emit.cps_provider_6_EmitResult>:
  Emit.EmitterRunState{Emit.cps_provider_6_EmitResult, profile_emitter_bound(64n, profile_emitter_pending()), profile_emitter_stack(0n)}

def profile_checker_start(unit: Unit) -> Checker.CheckerRun<Unit>:
  Checker.CheckerRunState{Unit, Checker.CheckerFinished{profile_checker_value()}, profile_checker_stack(200n)}

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- native_stage_template(profile_template_start, native_template_stage_view)
    Unit <- native_stage_checker(profile_checker_start, native_checker_stage_view)
    Unit <- native_stage_template_pending(profile_template_pending_start, native_template_stage_view)
    outcome : NativeEmitOutcome <- native_stage_emitter(profile_emitter_start, native_emitter_stage_view, profile_emitter_outcome)
    Unit <- profile_emitter_report(outcome)
    return Unit{}
