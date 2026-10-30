import Base
import /Users/ilyagulya/Projects/My/bend/checkpoints/local2039g37e06preflight03/consumers/descriptor-nf-native-matches.bend as Smoke

def print_smoke(value: Smoke.NfSmoke) -> IO(Unit):
  match value:
    case Smoke.NfSmoke{bits}: IO.print(bits)

def main() -> IO(Unit):
  print_smoke(Smoke.main(Nil{}))

#|11111111111111111111111111111111111111
