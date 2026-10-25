# Isolation ladder case 2 (diagnostic, not acceptance): the minimal projected
# Bool read. One unpacked bool field (packed would take the older path), read
# into a canonical Bool and printed. No do block, no Bool.or, no second call
# in the same frame.
#
# The constructor is passed directly instead of bound to an unannotated local:
# an unannotated constructor let has no expected type and the checker reports
# `term form cannot infer` (checker.bend:3751), which is an input defect, not
# a backend result.
#
# Expected: True (the single built arm is True, so a constant Fill tag 1
# cannot change this result).
import Base

type FlagBox is Data:
  FlagBox{flag: Bool, pad: U32}

def get(p: FlagBox) -> Bool:
  match p:
    case FlagBox{flag, _}:
      flag

def main() -> IO(Unit):
  IO.print(Bool.show(get(FlagBox{True{}, 0})))

#|True
