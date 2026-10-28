# C target fixture: a match binds one affine field and drops the other, so the
# emitter must release the unbound field exactly once. Expected 5.
import Base

type Box is Data:
  Box{left: U32, right: U32}

def first(b: Box) -> U32:
  match b:
    case Box{l, _}:
      l

def main() -> IO(Unit):
  IO.print(U32.show(first(Box{5, 9})))

#|5
