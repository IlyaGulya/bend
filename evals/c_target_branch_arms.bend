# C target fixture: the same affine value is consumed in two disjoint match
# arms. Liveness is per path; the arms must not sum their uses or copy the
# String cell on the taken path.
import Base

type Box is Data:
  Box{value: String}

def pick(flag: Bool, b: Box) -> String:
  match flag:
    case True{}:
      match b:
        case Box{v}:
          v
    case False{}:
      match b:
        case Box{v}:
          String.concat([v, "!"])

def main() -> IO(Unit):
  IO.print(pick(True{}, Box{"hi"}))

#|hi
