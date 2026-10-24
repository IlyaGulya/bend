import ../bend2/selfhost/checked_frontend.bend as Checked
import ../bend2/selfhost/backend_ir.bend as BIR
import ./c_emit_steps_v1.bend as CEmit

def emit_c_modules_start(program: Checked.CheckedProgram, runtime: String, files: List<&2, BIR.SourceFile>) -> CEmit.CEmitterRun<CEmit.EmitResult>:
  CEmit.cemit_start(program, runtime, files)

def emit_c_library_start(program: Checked.CheckedProgram, exports: List<&2, String>, runtime: String, files: List<&2, BIR.SourceFile>) -> CEmit.CEmitterRun<CEmit.EmitResult>:
  CEmit.cemit_library_start(program, exports, runtime, files)

def c_emitter_step(-R: Type, run: CEmit.CEmitterRun<R>) -> CEmit.CEmitterRun<R>:
  CEmit.cemit_step(R, run)
