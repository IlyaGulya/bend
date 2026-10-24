# C target fixture: a wide constructor with mixed-arity U32 fields.
#
# The value is built from fourteen distinct parameters, so the emitted C fills
# a multiword node at run time without reusing a scalar binder. The match
# projects every field, and the sum runs through U32.add calls (no literal
# folding). Expected: 3+4+5+...+16 = 133.
import Base

type Wide is Data:
  Wide{a: U32, b: U32, c: U32, d: U32, e: U32, f: U32, g: U32,
       h: U32, i: U32, j: U32, k: U32, l: U32, m: U32, n: U32}

def build(a: U32, b: U32, c: U32, d: U32, e: U32, f: U32, g: U32,
          h: U32, i: U32, j: U32, k: U32, l: U32, m: U32, n: U32) -> Wide:
  Wide{a, b, c, d, e, f, g, h, i, j, k, l, m, n}

def pick(w: Wide) -> U32:
  match w:
    case Wide{a, b, c, d, e, f, g, h, i, j, k, l, m, n}:
      U32.add(a, U32.add(b, U32.add(c, U32.add(d, U32.add(e, U32.add(f,
        U32.add(g, U32.add(h, U32.add(i, U32.add(j, U32.add(k, U32.add(l,
          U32.add(m, n)))))))))))))

def main() -> IO(Unit):
  IO.print(U32.show(pick(build(3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16))))

#|133
