import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/backend_ir.bend as BIR
import ./e05_probe_steps.bend as Probe

def expand_modules_start(modules: List<&2, Loader.LoadedModule>) -> Probe.TemplateRun<Probe.ProbeBatch>:
  Probe.template_start(modules)

def template_step(-R: Type, run: Probe.TemplateRun<R>) -> Probe.TemplateRun<R>:
  Probe.template_step(R, run)
