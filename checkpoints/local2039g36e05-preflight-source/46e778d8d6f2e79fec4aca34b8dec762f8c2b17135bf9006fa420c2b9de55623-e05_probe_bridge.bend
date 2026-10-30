import Base
import ../bend2/selfhost/backend_ir.bend as BIR
import ../bend2/selfhost/loaded_module.bend as Loader
import ./e05_probe_steps.bend as Probe

def inspect_start(program: BIR.Program) -> Probe.TemplateRun<Probe.Inspection>:
  Probe.template_chunk(Probe.Inspection, 64n, Probe.TemplateRunState{Probe.Inspection, Probe.TemplatePending{Probe.TemplateRequestGroup_0{Probe.TemplateRequest_inspect{program}}, box => Probe.TemplateFinished{box}}, Probe.TemplateStackDone{{==}}})

def schema_start() -> Probe.TemplateRun<Probe.SchemaBundle>:
  Probe.template_chunk(Probe.SchemaBundle, 64n, Probe.TemplateRunState{Probe.SchemaBundle, Probe.TemplatePending{Probe.TemplateRequestGroup_0{Probe.TemplateRequest_schema{}}, box => Probe.TemplateFinished{box}}, Probe.TemplateStackDone{{==}}})

def render_case_start(program: BIR.Program, target: Bool, files: List<&2, BIR.SourceFile>) -> Probe.TemplateRun<Probe.ProbeSource>:
  Probe.template_chunk(Probe.ProbeSource, 64n, Probe.TemplateRunState{Probe.ProbeSource, Probe.TemplatePending{Probe.TemplateRequestGroup_0{Probe.TemplateRequest_render_case{program, target, files}}, box => Probe.TemplateFinished{box}}, Probe.TemplateStackDone{{==}}})

def suite_start(modules: List<&2, Loader.LoadedModule>) -> Probe.TemplateRun<Probe.ProbeBatch>:
  Probe.template_start(modules)

def template_step(-R: Type, run: Probe.TemplateRun<R>) -> Probe.TemplateRun<R>:
  Probe.template_step(R, run)
