import Base
import /private/tmp/bend-e01-e13-jbsb4I/normalizer-source-04/descriptor-nf-native-matches.bend as Smoke

def print_smoke(value: Smoke.NfSmoke) -> IO(Unit):
  match value:
    case Smoke.NfSmoke{bits}: IO.print(bits)

def main() -> IO(Unit):
  print_smoke(Smoke.main(Nil{}))

#|11111111111111111111111111111111111111
