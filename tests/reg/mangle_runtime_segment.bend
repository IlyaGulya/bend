# regression witness: a user def whose name folds to the same C macro as a
# segment the runtime writes out by name. `clo.apply` folds to CLO_APPLY, and
# FID_CLO_APPLY is the runtime's closure-apply segment (WL_CASE(FID_CLO_APPLY),
# task_node(e, FID_CLO_APPLY, ...)): the runtime means its own segment, so a
# name taken from it sends a closure application into the user's def. The def is
# recursive on purpose -- a flat one is inlined and never gets a segment -- and
# main applies a closure (List.filter with ~is_odd) so the runtime's own apply
# path runs. Before the runtime names were reserved this program either did not
# compile ("two names mangle to FID_CLO_APPLY", when both reached the table) or
# compiled into two WL_CASE labels with one name.
import Base

def clo.apply(+n: Nat) -> U32:
  match n:
    case 0n:
      41
    case 1n+p:
      (clo.apply(p) + 1 : U32)

def is_odd(x: U32) -> Bool:
  Bool.not(U32.is_even(x))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(clo.apply(1n)))
    IO.print(U32.show(U32.from_nat(List.length(&2, U32, List.filter(~U32, ~is_odd, [1, 2, 3, 4, 5])))))

#|42
#|3
