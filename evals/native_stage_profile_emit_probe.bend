import Base
import ./native_stage_profile_emit_fixture.bend as F
import ../checkpoints/emitter_steps_v1.bend as Emit
import ../bend2/selfhost/backend_ir.bend as BIR

def result_message(box: Emit.EmitterValue<Emit.cps_provider_2_EmitResult>) -> String:
  match box:
    case Emit.EmitterValue{value}:
      match value:
        case Emit.cps_provider_2_EmitSuccess{source}: "EMIT_SUCCESS"
        case Emit.cps_provider_2_EmitFailure{message}: message

def emit_message(run: Emit.EmitterRun<Emit.cps_provider_2_EmitResult>) -> String:
  match run:
    case Emit.EmitterRunFinished{box}: result_message(box)
    case Emit.EmitterRunState{B, progress, stack}: "INCOMPLETE"

def emit_start() -> Emit.EmitterRun<Emit.cps_provider_2_EmitResult>:
  Emit.EmitterRunState{Emit.cps_provider_2_EmitResult,
    Emit.EmitterPending{Emit.EmitterRequestGroup_12{Emit.EmitterRequest_cps_provider_2_emit{
      F.program(), F.runtime(), Nil{}}}, box => Emit.EmitterFinished{box}},
    Emit.EmitterStackDone{{==}}}

def emit_step(run: Emit.EmitterRun<Emit.cps_provider_2_EmitResult>) -> Emit.EmitterRun<Emit.cps_provider_2_EmitResult>:
  Emit.emitter_chunk(Emit.cps_provider_2_EmitResult, 64n, run)
