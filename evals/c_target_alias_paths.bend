# C target fixture: a Many String field is aliased into a second local and
# both aliases of the same projected path are consumed. The second read must
# share the path's root instead of detaching the cell twice.
import Base

type PairS is Data:
  PairS{+a: String, +b: String}

def alias_paths(p: PairS) -> Nat:
  match p:
    case PairS{a, b}:
      x = a
      Nat.add(String.length(x), String.length(a))

def main() -> IO(Unit):
  IO.print(Nat.show(alias_paths(PairS{"abcd", "z"})))

#|8
