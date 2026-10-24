import ../bend2/selfhost/checked_frontend.bend as Checked
import ../bend2/selfhost/backend_ir.bend as BIR
import ./emitter_steps_v1.bend as Emit

def emit_modules_start(program: Checked.CheckedProgram, files: List<&2, BIR.SourceFile>) -> Emit.EmitterRun<Emit.EmitResult>:
  Emit.emitter_start(program, files)

def emit_library_start(program: Checked.CheckedProgram, exports: List<&2, String>, files: List<&2, BIR.SourceFile>) -> Emit.EmitterRun<Emit.EmitResult>:
  Emit.emitter_library_start(program, exports, files)

def emitter_step(-R: Type, run: Emit.EmitterRun<R>) -> Emit.EmitterRun<R>:
  Emit.emitter_step(R, run)

def emit_c_modules_start(program: Checked.CheckedProgram, runtime: String, files: List<&2, BIR.SourceFile>) -> Emit.EmitterRun<Emit.EmitResult>:
  Emit.cemit_start(program, runtime, files)

def emit_c_library_start(program: Checked.CheckedProgram, exports: List<&2, String>, runtime: String, files: List<&2, BIR.SourceFile>) -> Emit.EmitterRun<Emit.EmitResult>:
  Emit.cemit_library_start(program, exports, runtime, files)

def c_emitter_step(-R: Type, run: Emit.EmitterRun<R>) -> Emit.EmitterRun<R>:
  Emit.emitter_step(R, run)
