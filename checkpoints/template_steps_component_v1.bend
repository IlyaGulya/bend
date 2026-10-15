import ../bend2/selfhost/loaded_module.bend as Loader
import ./template_steps_v1.bend as Template

def expand_modules_start(modules: List<&2, Loader.LoadedModule>) -> Template.TemplateProgress<Template.ExpandResult>:
  Template.template_start(modules)

def template_step(request: Template.TemplateRequest) -> Template.TemplateProgress<Template.template_result(request)>:
  Template.template_step(request)
