import Base
import ../checkpoints/emitter_steps_v1.bend as Emit
import ../bend2/selfhost/backend_ir.bend as BIR

def result_message(box: Emit.EmitterValue<Emit.cps_provider_6_EmitResult>) -> String:
  match box:
    case Emit.EmitterValue{value}:
      match value:
        case Emit.cps_provider_6_EmitSuccess{source}: "EMIT_SUCCESS"
        case Emit.cps_provider_6_EmitFailure{message, span}: message

def emit_message(run: Emit.EmitterRun<Emit.cps_provider_6_EmitResult>) -> String:
  match run:
    case Emit.EmitterRunFinished{box}: result_message(box)
    case Emit.EmitterRunState{B, progress, stack}: "INCOMPLETE"

def start(program: BIR.Program, runtime: String, files: List<&2, BIR.SourceFile>) -> Emit.EmitterRun<Emit.cps_provider_6_EmitResult>:
  Emit.EmitterRunState{Emit.cps_provider_6_EmitResult,
    Emit.EmitterPending{Emit.EmitterRequestGroup_18{Emit.EmitterRequest_cps_provider_6_render{program, runtime, files}}, box => Emit.EmitterFinished{box}},
    Emit.EmitterStackDone{{==}}}

def step(run: Emit.EmitterRun<Emit.cps_provider_6_EmitResult>) -> Emit.EmitterRun<Emit.cps_provider_6_EmitResult>:
  Emit.emitter_chunk(Emit.cps_provider_6_EmitResult, 64n, run)
