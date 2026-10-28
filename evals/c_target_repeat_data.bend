# C target fixture: one Many caller argument reaches two calls of an AFFINE
# identity. The caller's value stays live across both calls, so the residual
# use must share Data for each callee's formal, not move at the first call.
import Base

def ident(s: String) -> String:
  s

def measure(+s: String) -> Nat:
  Nat.add(String.length(ident(s)), String.length(ident(s)))

def main() -> IO(Unit):
  IO.print(Nat.show(measure("abcd")))

#|8
