# A captured function stored in a constructor field, extracted, and applied:
# make(k) captures k, unwrap returns the field itself (a valid affine program
# that moves the field out of the parent), and main applies the result.
import Base

type FBox is Type:
  MkF{f: U32 -> U32}

def make(k: U32) -> FBox:
  MkF{x => U32.add(x, k)}

def unwrap(b: FBox) -> U32 -> U32:
  match b:
    case MkF{f}:
      f

def main() -> IO(Unit):
  IO.print(U32.show(unwrap(make(3))(4)))

#|7
