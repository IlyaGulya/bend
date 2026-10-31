# Minimized from tests/check/convoy_dependent.bend (pick_inner and num).
# Candidate only: shared published term identity must be observed, not assumed.
import Base

type Owner is Type:
  Owner{n: Nat}

type Box<-original: Owner> is Type:
  Box{owner: Owner, -same: {owner == original : Owner}}

def pick(-original: Owner, owner: Owner, -same: {owner == original : Owner}, a: Bool, b: Bool) -> Box<original>:
  match a:
    case False{}:
      match b:
        case False{}: Box{owner, same}
        case True{}: Box{owner, same}
    case True{}: Box{owner, same}

def num(-original: Owner, box: Box<original>) -> Nat:
  match box:
    case Box{owner, same}:
      match owner:
        case Owner{n}: n

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(Nat.show(num(Owner{31n}, pick(Owner{31n}, Owner{31n}, {==}, False{}, True{}))))
    IO.print(Nat.show(num(Owner{47n}, pick(Owner{47n}, Owner{47n}, {==}, True{}, False{}))))

#|31
#|47
