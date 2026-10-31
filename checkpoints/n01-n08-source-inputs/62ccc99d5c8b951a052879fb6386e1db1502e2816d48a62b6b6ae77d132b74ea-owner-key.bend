# Source-authored direct API witness for the CURRENT capture_found implementation.
# This is not evidence that the checker produces colliding slots in one frame.
# No arena, FIR, checked program or runtime owner is constructed here.
import Base
import /Users/ilyagulya/Projects/My/bend/bend2/selfhost/backend_lower.bend as Lower
import /Users/ilyagulya/Projects/My/bend/bend2/selfhost/backend_ir.bend as BIR

def slots() -> List<&2, Lower.Capture>:
  [Lower.Capture{Lower.Slot{7, 1, BIR.Null{}, BIR.Many{}}, 2},
   Lower.Capture{Lower.Slot{9, 1, BIR.Null{}, BIR.Many{}}, 1},
   Lower.Capture{Lower.Slot{7, 2, BIR.Null{}, BIR.Many{}}, 0}]

def index(found: Maybe<&2, U32>) -> U32:
  match found:
    case Some{value}: value
    case None{}: 99

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(index(Lower.capture_found(slots(), 7, 1))))
    Unit <- IO.print(U32.show(index(Lower.capture_found(slots(), 9, 1))))
    Unit <- IO.print(U32.show(index(Lower.capture_found(slots(), 7, 2))))
    IO.print(U32.show(index(Lower.capture_found(slots(), 8, 1))))

#|2
#|1
#|0
#|99
