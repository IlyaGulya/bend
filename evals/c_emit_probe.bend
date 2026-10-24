# C emission probe: runs the renderer's own library smoke through the ordinary
# compiler and prints the emitted translation unit, so it can be handed straight
# to clang. Stdout is the C source; diagnostics go to stderr.
import Base
import ./c_backend_library_smoke.bend as Smoke

def main() -> IO(Unit):
  IO.print(Smoke.rendered())
