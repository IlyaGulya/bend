# C target fixture: four-constructor match with a default arm and a
# partially applied call site.
#
# `Mark` has four constructors and the match also needs a default arm; the
# tagged value is produced from a run-time Bool so the tag test is real. The
# local `plus3` is a first-class closure that is applied inside `twice`.
# Expected: mark(D) = 4, twice(3) = 3+3+3 = 9, sum = 13.
import Base

type Mark is Data:
  A{}
  B{}
  C{}
  D{}

def mark(which: U32) -> Mark:
  match U32.is_eq(which, 3):
    case True{}: D{}
    case False{}: C{}

def weight(m: Mark) -> U32:
  match m:
    case A{}: 1
    case B{}: 2
    case C{}: 3
    case D{}: 4
    case _: 0

def twice(f: U32 -> U32, x: U32) -> U32:
  f(f(x))

def main() -> IO(Unit):
  m = mark(3)
  plus3 = x => U32.add(x, 3)
  IO.print(U32.show(U32.add(weight(m), twice(plus3, 3))))

#|13
