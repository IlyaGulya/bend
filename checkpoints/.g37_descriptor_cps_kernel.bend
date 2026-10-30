import Base
import ./descriptor_nf_steps_v1.bend as Steps

def print_smoke(value: Steps.NfSmoke) -> IO(Unit):
  match value:
    case Steps.NfSmoke{bits}: IO.print(bits)

@unsafe def drive(run: Steps.TemplateRun<Steps.NfSmoke>) -> IO(Unit):
  match run:
    case Steps.TemplateRunFinished{Steps.TemplateValue{value}}: print_smoke(value)
    case rest: drive(Steps.template_step(Steps.NfSmoke, rest))

def main() -> IO(Unit):
  drive(Steps.template_start(Nil{}))

#|11111111111111111111111111111111111111
