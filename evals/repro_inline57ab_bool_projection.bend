# Minimal witness: a Bool carried in an unpacked data field is projected and
# then consumed (a) by a branch and (b) by the native Bool.or predicate.
#
# `pad: U32` is not read; it makes the constructor two laid-out words, so the
# projection reaches the unpacked-field path (a packed one-word record would
# take the older packed path and could avoid the boundary). Only True is
# built, so the Fill arm tag happens to coincide with the pre-fix constant 1;
# this witness therefore depends on the read/projection path, not on Fill.
#
# Expected: branch -> 1 (True arm), Bool.or(True, False{}) -> True.
import Base

type FlagBox is Data:
  FlagBox{flag: Bool, pad: U32}

def branch(p: FlagBox) -> U32:
  match p:
    case FlagBox{flag, _}:
      match flag:
        case True{}: 1
        case False{}: 0

def predicate(p: FlagBox) -> Bool:
  match p:
    case FlagBox{flag, _}:
      Bool.or(flag, False{})

def main() -> IO(Unit):
  do IO<Unit>:
      Unit <- IO.print(U32.show(branch(FlagBox{True{}, 0})))
      IO.print(Bool.show(predicate(FlagBox{True{}, 0})))

#|1
#|True
