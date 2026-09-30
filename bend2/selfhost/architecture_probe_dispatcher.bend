import Base

type ProbeState is Data:
  ProbeState{remaining: Nat, total: Nat}
type ProbeRequest is Data:
  Continue{state: ProbeState}
  Finished{state: ProbeState}

def advance_state(amount: Nat, state: ProbeState) -> ProbeState:
  match state:
    case ProbeState{remaining, total}:
      ProbeState{remaining, total + amount}

def advance_request(request: ProbeRequest, amount: Nat) -> ProbeRequest:
  match request:
    case Continue{state}:
      Continue{advance_state(amount, state)}
    case Finished{state}:
      Finished{state}

def finish_request(request: ProbeRequest) -> ProbeState:
  match request:
    case Continue{state}:
      state
    case Finished{state}:
      state

def run_dispatch(steps: List<&2, Nat>, request: ProbeRequest) -> ProbeState:
  match steps:
    case Nil{}:
      finish_request(request)
    case +step <> rest:
      run_dispatch(rest, advance_request(request, step))

def show_state(state: ProbeState) -> String:
  match state:
    case ProbeState{remaining, total}:
      String.concat(["(", Nat.show(total), "n, ", Nat.show(remaining), "n)"])

law main:
  IO(Unit)

def main():
  IO.print(show_state(run_dispatch([1n, 1n, 1n], Continue{ProbeState{1n, 0n}})))

#|(3n, 1n)
