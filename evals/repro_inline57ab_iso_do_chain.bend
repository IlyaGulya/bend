# Isolation ladder case 1 (diagnostic, not acceptance): the minimal do-block
# shape, with no data projection and no inline form. If this fails to emit,
# the fresh component blocks every do-block program before any Bool/Char/Fill
# boundary is reachable.
#
# Expected: a then b.
import Base

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print("a")
    IO.print("b")

#|a
#|b
