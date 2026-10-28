import Base
import ../checkpoints/emitter_steps_v1.bend as Emit
import ../bend2/selfhost/checked_frontend.bend as Checked

def start(program: Checked.CheckedProgram) -> Emit.EmitterRun<Emit.cps_provider_1_ProgramResult>:
  Emit.EmitterRunState{Emit.cps_provider_1_ProgramResult,
    Emit.EmitterPending{Emit.EmitterRequestGroup_5{Emit.EmitterRequest_cps_provider_1_lower{program}}, box => Emit.EmitterFinished{box}},
    Emit.EmitterStackDone{{==}}}

def step(run: Emit.EmitterRun<Emit.cps_provider_1_ProgramResult>) -> Emit.EmitterRun<Emit.cps_provider_1_ProgramResult>:
  Emit.emitter_chunk(Emit.cps_provider_1_ProgramResult, 64n, run)
