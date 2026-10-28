# js backend: a field key is a compile-time string, so a plain identifier is a
# literal property and a named projection. __proto__ keeps the computed
# spelling, because a literal of that name sets a prototype instead of defining
# a field, and toString keeps an own property in front of the inherited one.
# Both spellings must project the same values through a record that escapes and
# through one that is only bound.
import Base

type Keys is Data:
  Keys{__proto__: U32, toString: U32, value: U32}

def build(+x: U32) -> Keys:
  Keys{x, U32.add(x, 1), U32.add(x, 2)}

def widen(k: Keys) -> U32:
  Keys{a, b, c} = k
  U32.add(U32.add(a, b), c)

def scalar(+x: U32) -> U32:
  widen(Keys{x, U32.add(x, 1), U32.add(x, 2)})

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(widen(build(10))))
    IO.print(U32.show(scalar(1)))

#|33
#|6
