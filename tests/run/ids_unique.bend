# reversible C ids keep case, punctuation, runtime names and fixed macros apart
import Base

type Lower is Data:
  done{}
  T{}

def lower(l: Lower) -> U32:
  match l:
    case done{}:
      1
    case T{}:
      100000

def a.b(xs: List<String>) -> U32:
  match xs:
    case Nil{}:
      10
    case h <> t:
      (a.b(t) + 1 : U32)

def a_b(xs: List<String>) -> U32:
  match xs:
    case Nil{}:
      100
    case h <> t:
      (a_b(t) + 1 : U32)

def io_emit(xs: List<String>) -> U32:
  match xs:
    case Nil{}:
      1000
    case h <> t:
      (io_emit(t) + 1 : U32)

def clo_apply(xs: List<String>) -> U32:
  match xs:
    case Nil{}:
      10000
    case h <> t:
      (clo_apply(t) + 1 : U32)

def EXIT(xs: List<String>) -> U32:
  match xs:
    case Nil{}:
      1000000
    case h <> t:
      (EXIT(t) + 1 : U32)

def main() -> IO(Unit):
  do IO<Unit>:
    w : List<String> <- IO.args()
    x : List<String> <- IO.args()
    y : List<String> <- IO.args()
    z : List<String> <- IO.args()
    e : List<String> <- IO.args()
    IO.print(U32.show((EXIT(e) + lower(T{}) + lower(done{}) + a.b(w)
      + a_b(x) + io_emit(y) + clo_apply(z) : U32)))

#|1111111
