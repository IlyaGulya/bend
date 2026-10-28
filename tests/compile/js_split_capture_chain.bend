# A split's continuation binds exactly the values its own suffix still reads:
# one bottom-up capture plan decides that for every split of the body at once.
# The chain below keeps every earlier local live across six non-tail calls, so
# each continuation captures a longer prefix and the call's own result arrives
# as its argument instead of as a capture; `duplicate` reads one value twice
# before the split, so the last read position decides its capture order; the
# closure in `nested` contributes a capture slot beside a parameter; and
# `area`'s `Line` row splits before its own leave, so that row needs a private
# frame while the rows around it stay joinable.
import Base

type Shape is Data:
  Dot{}
  Line{n: U32}
  Box{n: U32, m: U32}

def scaled(k: U32, x: U32) -> U32:
  U32.add(U32.mul(k, 3), x)

def chain(+a: U32, +b: U32, +c: U32) -> U32:
  +p = scaled(1, a)
  +q = scaled(2, U32.add(p, b))
  +r = scaled(3, U32.add(q, c))
  +s = scaled(4, U32.add(r, a))
  +t = scaled(5, U32.add(s, b))
  u = scaled(6, U32.add(t, c))
  U32.add(U32.add(p, q), U32.add(U32.add(r, s), U32.add(t, u)))

def duplicate(+x: U32) -> U32:
  U32.add(scaled(U32.add(x, 1), x), scaled(x, U32.add(x, 2)))

def apply2(f: U32 -> U32, g: U32 -> U32, x: U32) -> U32:
  g(f(x))

def nested(+a: U32, b: U32) -> U32:
  apply2(x => U32.add(x, scaled(3, a)), x => U32.add(x, scaled(3, a)), b)

def area(s: Shape) -> U32:
  match s:
    case Dot{}:
      0
    case Line{+n}:
      U32.add(scaled(2, n), n)
    case Box{n, m}:
      U32.mul(n, m)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(chain(1, 2, 3)))
    IO.print(U32.show(duplicate(5)))
    IO.print(U32.show(nested(4, 6)))
    IO.print(U32.show(U32.add(area(Dot{}), U32.add(area(Line{4}), area(Box{2, 5})))))

#|206
#|45
#|32
#|24
