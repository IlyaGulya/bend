# C target fixture: an arm projects a String field and reads it twice, next to
# an arm that returns a constant. The leave/residual path must follow the
# taken arm and must not count an unreachable sibling continuation.
import Base

type Wrapper is Data:
  Wrapper{+text: String}

def branch(flag: Bool, w: Wrapper) -> Nat:
  match flag:
    case True{}:
      7n
    case False{}:
      match w:
        case Wrapper{text}:
          Nat.add(String.length(text), String.length(text))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Nat.show(branch(True{}, Wrapper{"abc"})))
    IO.print(Nat.show(branch(False{}, Wrapper{"abc"})))

#|7
#|6
