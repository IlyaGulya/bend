import Base

type ProbeState is Data:
  ProbeState{remaining: Nat, total: Nat}

def advance_state(amount: Nat, state: ProbeState) -> ProbeState:
  match state:
    case ProbeState{remaining, total}:
      ProbeState{remaining, total + amount}

def identity_state(state: ProbeState) -> ProbeState:
  state

def run_callback(steps: List<&2, Nat>, state: ProbeState, next: ProbeState -> ProbeState) -> ProbeState:
  match steps:
    case Nil{}:
      next(state)
    case +step <> rest:
      run_callback(rest, advance_state(step, state), next)

def show_state(state: ProbeState) -> String:
  match state:
    case ProbeState{remaining, total}:
      String.concat(["(", Nat.show(total), "n, ", Nat.show(remaining), "n)"])

law main:
  IO(Unit)

def main():
  IO.print(show_state(run_callback([1n, 1n, 1n], ProbeState{1n, 0n}, identity_state)))

#|(3n, 1n)
