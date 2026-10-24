import ../bend2/selfhost/checked_frontend.bend as Checked
import ../bend2/selfhost/backend_ir.bend as BIR
import ./js_emit_steps_v1.bend as JSEmit

def emit_modules_start(program: Checked.CheckedProgram, files: List<&2, BIR.SourceFile>) -> JSEmit.EmitterRun<JSEmit.EmitResult>:
  JSEmit.emitter_start(program, files)

def emit_library_start(program: Checked.CheckedProgram, exports: List<&2, String>, files: List<&2, BIR.SourceFile>) -> JSEmit.EmitterRun<JSEmit.EmitResult>:
  JSEmit.emitter_library_start(program, exports, files)

def emitter_step(-R: Type, run: JSEmit.EmitterRun<R>) -> JSEmit.EmitterRun<R>:
  JSEmit.emitter_step(R, run)
