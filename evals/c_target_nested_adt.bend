# C target fixture: nested ADTs built and projected at run time.
#
# Seg{Pt{1,2}, Pt{3,4}, Fl{5}} reaches both tags and every leaf through
# Construct/Project; the checksum uses U32.add so the emitted C cannot fold
# the result to a literal. Expected: 1+2+3+4+5 = 15.
import Base

type Pt is Data:
  Pt{x: U32, y: U32}

type Fl is Data:
  Fl{v: U32}

type Seg is Data:
  Seg{lo: Pt, hi: Pt, flag: Fl}

def swap(+a: U32, +b: U32) -> Pt:
  Pt{b, a}

def build(+n: U32) -> Seg:
  Seg{swap(n, U32.add(n, 1)), Pt{U32.add(n, 2), U32.add(n, 3)}, Fl{U32.add(n, 4)}}

def sum(p: Pt) -> U32:
  match p:
    case Pt{x, y}: U32.add(x, y)

def checksum(s: Seg) -> U32:
  match s:
    case Seg{lo, hi, flag}:
      match flag:
        case Fl{v}: U32.add(sum(lo), U32.add(sum(hi), v))

def main() -> IO(Unit):
  IO.print(U32.show(checksum(build(1))))

#|15
