import ../bend2/selfhost/loaded_module.bend as Loader
import ./js_emit_steps_v1.bend as JSEmit

def emit_modules_start(modules: List<&2, Loader.LoadedModule>) -> JSEmit.EmitterProgress<JSEmit.EmitResult>:
  JSEmit.emitter_start(modules)

def emitter_step(request: JSEmit.EmitterRequest) -> JSEmit.EmitterProgress<JSEmit.emitter_result(request)>:
  JSEmit.emitter_step(request)
