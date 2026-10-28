# C target fixture: a heap closure local is used once in each exclusive ADT
# match arm, and the taken Fast arm ends in a tail apply.  The fallback
# continuation would need the same closure to reach Slow, so a
# reachability-blind region keep would copy it on the Fast tail path where a
# move is legal.  c_target_region_leave_repeat covers the genuinely-live
# region obligation after a match.
import Base

type Choice is Data:
  Fast{}
  Slow{}

def inc10(x: U32) -> U32:
  U32.add(x, 10)

def run(choice: Choice, g: U32 -> U32) -> U32:
  h : (U32 -> U32) = x => (g(x) : U32)
  match choice:
    case Fast{}:
      h(1)
    case Slow{}:
      h(2)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(run(Fast{}, inc10)))
    IO.print(U32.show(run(Slow{}, inc10)))

#|11
#|12
