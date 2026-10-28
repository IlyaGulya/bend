import Base
import ../bend2/selfhost/backend_ir.bend as BIR
import ../bend2/selfhost/checked_frontend.bend as Checked
import ./emitter_steps_v1.bend as Emit

def emit_modules_start(program: Checked.CheckedProgram, files: List<&2, BIR.SourceFile>) -> Emit.EmitterRun<Emit.EmitResult>:
  Emit.emitter_start(program, files)

def emit_library_start(program: Checked.CheckedProgram, exports: List<&2, String>, files: List<&2, BIR.SourceFile>) -> Emit.EmitterRun<Emit.EmitResult>:
  Emit.emitter_library_start(program, exports, files)

def emitter_step(-R: Type, run: Emit.EmitterRun<R>) -> Emit.EmitterRun<R>:
  Emit.emitter_step(R, run)

def lower_start(program: Checked.CheckedProgram) -> Emit.EmitterRun<Emit.cps_provider_1_ProgramResult>:
  Emit.emitter_chunk(Emit.cps_provider_1_ProgramResult, 64n, Emit.EmitterRunState{Emit.cps_provider_1_ProgramResult, Emit.emitter_body_cps_provider_1_lower(program), Emit.EmitterStackDone{{==}}})

def plan_start(program: BIR.Program) -> Emit.EmitterRun<Emit.cps_provider_8_MultiPlan>:
  Emit.emitter_chunk(Emit.cps_provider_8_MultiPlan, 64n, Emit.EmitterRunState{Emit.cps_provider_8_MultiPlan, Emit.emitter_body_cps_provider_8_multi_plan(program), Emit.EmitterStackDone{{==}}})

def scalar_start(program: BIR.Program) -> Emit.EmitterRun<BIR.Program>:
  Emit.emitter_chunk(BIR.Program, 64n, Emit.EmitterRunState{BIR.Program, Emit.emitter_body_cps_provider_8_js_scalar_program(program), Emit.EmitterStackDone{{==}}})
