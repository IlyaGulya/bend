# Ordinary producer input, never a hand-built FIR carrier.
# Expected output is source-derived, not an executed claim.
import Base

type Box is Type:
  Box{fn: U32 -> U32}

type Nested is Type:
  Nested{fn: U32 -> Box}

def invoke(box: Box, x: U32) -> U32:
  match box:
    case Box{fn}: fn(x)

def wide(+a: U32, b: U32, c: U32, d: U32, e: U32, f: U32, g: U32, h: U32) -> Box:
  Box{x => U32.add(U32.add(U32.add(U32.add(a, b), U32.add(c, d)), U32.add(U32.add(e, f), U32.add(g, h))), U32.add(a, U32.add(a, x)))}

def nested(+outer: U32) -> Nested:
  Nested{middle => Box{inner => U32.add(outer, U32.add(middle, inner))}}

def invoke_nested(value: Nested) -> U32:
  match value:
    case Nested{fn}: invoke(fn(10), 20)

# Separate definition parameter identities can repeat under different owners.
# They do not prove an identity collision inside ONE live capture search.
# The observer's identityCollisionDifferentOwner counter is the coverage oracle.
def left(x: U32) -> Box:
  Box{y => U32.add(x, y)}

def right(x: U32) -> Box:
  Box{y => U32.mul(x, y)}

def branch(choice: Bool, fn: U32 -> U32) -> U32:
  held : (U32 -> U32) = x => (fn(x) : U32)
  match choice:
    case True{}: held(1)
    case False{}: held(2)

def plus10(x: U32) -> U32:
  U32.add(x, 10)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(invoke(wide(1, 2, 3, 4, 5, 6, 7, 8), 1)))
    Unit <- IO.print(U32.show(invoke_nested(nested(7))))
    Unit <- IO.print(U32.show(invoke(left(4), 3)))
    Unit <- IO.print(U32.show(invoke(right(4), 3)))
    Unit <- IO.print(U32.show(branch(True{}, plus10)))
    IO.print(U32.show(branch(False{}, plus10)))

#|39
#|37
#|7
#|12
#|11
#|12
