import Base
import /Users/ilyagulya/Projects/My/bend/evals/descriptor_nf_smoke.bend as Smoke

def main() -> IO(Unit):
  match Smoke.main(Nil{}):
    case Smoke.NfSmoke{bits}: IO.print(bits)

#|11111111111111111111111111111111111111
