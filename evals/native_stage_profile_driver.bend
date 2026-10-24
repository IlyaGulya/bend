import Base
import ../checkpoints/template_steps_v1.bend as Template
import ../checkpoints/checker_core_steps_v1.bend as Checker

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
# Profile-only native entry points. The production native_experiment keeps its
# 14 callback positions and 13 public names; this diagnostic driver is built as
# a separate small component and never participates in acceptance.
def native_stage_template(start: Unit -> Template.TemplateRun<Unit>, view: (@-A: Type -> @run: Template.TemplateRun<A> -> NativeTemplateStageView<A>)) -> IO(Unit):
  import "./native_stage_profile_host.c"

def native_stage_checker(start: Unit -> Checker.CheckerRun<Unit>, view: (@-A: Type -> @run: Checker.CheckerRun<A> -> NativeCheckerStageView<A>)) -> IO(Unit):
  import "./native_stage_profile_host.c"

def native_stage_template_pending(start: Unit -> Template.TemplateRun<Unit>, view: (@-A: Type -> @run: Template.TemplateRun<A> -> NativeTemplateStageView<A>)) -> IO(Unit):
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

def profile_checker_start(unit: Unit) -> Checker.CheckerRun<Unit>:
  Checker.CheckerRunState{Unit, Checker.CheckerFinished{profile_checker_value()}, profile_checker_stack(200n)}

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- native_stage_template(profile_template_start, native_template_stage_view)
    Unit <- native_stage_checker(profile_checker_start, native_checker_stage_view)
    Unit <- native_stage_template_pending(profile_template_pending_start, native_template_stage_view)
    return Unit{}
