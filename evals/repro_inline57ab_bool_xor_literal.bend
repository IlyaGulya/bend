# Control for the projected Bool.xor witness: same operation and observation,
# but no record or borrowed projection.
import Base

def main() -> IO(Unit):
  IO.print(Bool.show(Bool.xor(True{}, True{})))

#|False
