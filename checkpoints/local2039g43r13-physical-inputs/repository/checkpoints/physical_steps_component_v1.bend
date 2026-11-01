import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/backend_ir.bend as BIR
import ./physical_steps_v1.bend as Template

def expand_modules_start(modules: List<&2, Loader.LoadedModule>) -> Template.TemplateRun<Template.PhysSmoke>:
  Template.template_start(modules)

def template_step(-R: Type, run: Template.TemplateRun<R>) -> Template.TemplateRun<R>:
  Template.template_step(R, run)
