# The foreign implementation alone uses this constructor; neither its public
# signature nor a Bend value roots the family. CID(...) must still provide its
# real node arity so construction and destruction agree.
import Base

type CidOnlyPair is Data:
  CidOnlyPair{left: U32, right: U32}

def cid_only_sum() -> IO(U32):
  import "./cid_only_family.c"
  import "./cid_only_family.js"

def main() -> IO(Unit):
  do IO<Unit>:
    value: U32 <- cid_only_sum()
    IO.print(U32.show(value))

#|42
