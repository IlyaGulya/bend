import Base

# H = 2 administrative transitions between token-consuming transitions.
# A chunk is the compile-time literal H + 1 = 3 cells, never a computed Nat.
type Token is Data:
  Good{}
  Bad{}

type FuelData is Data:
  FuelEnd{}
  FuelCell{tail: FuelData}

type MachineState is Data:
  Request{}
  Resume{}
  Consume{}
  Terminal{}

type Outcome is Data:
  Success{transitions: Nat}
  ParserFailure{transitions: Nat}
  InternalInvariantExhausted{transitions: Nat}

def chunk(tail: FuelData) -> FuelData:
  FuelCell{FuelCell{FuelCell{tail}}}

# The only recursive constructor call receives the direct matched token tail.
# Thus build_fuel([]) = 3 cells and build_fuel(t <> ts) = 3 + cells(ts).
# No length computation, multiplication, guessed allowance, or fuel recursion.
def build_fuel(+tokens: List<&2, Token>) -> FuelData:
  match tokens:
    case Nil{}:
      chunk(FuelEnd{})
    case _ <> +tail:
      chunk(build_fuel(tail))

# This observer is not part of fuel construction or the driver.
def count_fuel(+fuel: FuelData) -> Nat:
  match fuel:
    case FuelEnd{}: 0n
    case FuelCell{+tail}: 1n + count_fuel(tail)

# Terminal observation is not a transition and requires no cell.
# Each Request, Resume, or Consume transition consumes exactly one direct cell.
# Exhaustion is an internal invariant result, never a grammar failure.
def drive(+fuel: FuelData, state: MachineState, +tokens: List<&2, Token>, transitions: Nat) -> Outcome:
  match fuel, state, tokens:
    case _, Terminal{}, _:
      Success{transitions}
    case FuelEnd{}, Request{}, _:
      InternalInvariantExhausted{transitions}
    case FuelCell{+tail}, Request{}, +remaining:
      drive(tail, Resume{}, remaining, transitions + 1n)
    case FuelEnd{}, Resume{}, _:
      InternalInvariantExhausted{transitions}
    case FuelCell{+tail}, Resume{}, +remaining:
      drive(tail, Consume{}, remaining, transitions + 1n)
    case FuelEnd{}, Consume{}, _:
      InternalInvariantExhausted{transitions}
    case FuelCell{+tail}, Consume{}, Nil{}:
      drive(tail, Terminal{}, Nil{}, transitions + 1n)
    case FuelCell{+tail}, Consume{}, Good{} <> +rest:
      drive(tail, Request{}, rest, transitions + 1n)
    case FuelCell{_}, Consume{}, Bad{} <> _:
      ParserFailure{transitions + 1n}

def show_outcome(outcome: Outcome) -> String:
  match outcome:
    case Success{transitions}: String.concat(["success:", Nat.show(transitions)])
    case ParserFailure{transitions}: String.concat(["parser-failure:", Nat.show(transitions)])
    case InternalInvariantExhausted{transitions}: String.concat(["internal-exhausted:", Nat.show(transitions)])

law main:
  IO(Unit)

def main():
  IO.print(String.concat([
    "counts=", Nat.show(count_fuel(build_fuel(Nil{}))), ",",
    Nat.show(count_fuel(build_fuel([Good{}]))), ",",
    Nat.show(count_fuel(build_fuel([Good{}, Good{}]))),
    ";n0=", show_outcome(drive(build_fuel(Nil{}), Request{}, Nil{}, 0n)),
    ";n1=", show_outcome(drive(build_fuel([Good{}]), Request{}, [Good{}], 0n)),
    ";n2=", show_outcome(drive(build_fuel([Good{}, Good{}]), Request{}, [Good{}, Good{}], 0n)),
    ";terminal-empty=", show_outcome(drive(FuelEnd{}, Terminal{}, Nil{}, 0n)),
    ";request-empty=", show_outcome(drive(FuelEnd{}, Request{}, Nil{}, 0n)),
    ";short=", show_outcome(drive(FuelCell{FuelCell{FuelEnd{}}}, Request{}, Nil{}, 0n)),
    ";bad=", show_outcome(drive(build_fuel([Bad{}]), Request{}, [Bad{}], 0n))
  ]))

#|counts=3,6,9;n0=success:3;n1=success:6;n2=success:9;terminal-empty=success:0;request-empty=internal-exhausted:0;short=internal-exhausted:2;bad=parser-failure:3
