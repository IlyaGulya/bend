# C target fixture: four-constructor match with a default arm and a partially
# applied call site.
#
# `Mark` has four constructors and the match also needs a default arm; the
# tagged value is produced from a run-time Bool so the tag test is real. The
# local `plus3` is a first-class closure applied inside `apply_once`; a function
# value has kind Type and is affine, so it is applied once, not copied.
# Expected: mark(D)=4, apply_once(plus3,3)=plus3(6)=9, sum=13.
import Base

type Mark is Data:
  A{}
  B{}
  C{}
  D{}

def pick(flag: Bool) -> Mark:
  match flag:
    case True{}: D{}
    case False{}: C{}

def weight(m: Mark) -> U32:
  match m:
    case A{}: 1
    case B{}: 2
    case C{}: 3
    case D{}: 4
    case _: 0

def plus3(x: U32) -> U32:
  U32.add(x, 3)

def apply_once(f: U32 -> U32, x: U32) -> U32:
  f(U32.add(x, 3))

def main() -> IO(Unit):
  m = pick(U32.is_eq(3, 3))
  IO.print(U32.show(U32.add(weight(m), apply_once(plus3, 3))))

#|13
