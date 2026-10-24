# Library ABI fixture for the typed C step seam. Control's caller drives the
# six-symbol C library ABI: exact names/order, direct arity, a partial export
# that returns a closure, two nullary factories that must re-evaluate (distinct
# closure terms), and the returned closure applied through the runtime.
import Base

def add(a: U32, b: U32) -> U32:
  U32.add(a, b)

def symbol_add(a: U32, b: U32) -> U32:
  U32.add(b, a)

def partial(x: U32) -> U32 -> U32:
  y => U32.add(x, y)

def zero() -> U32:
  9

def factory() -> U32 -> U32:
  x => U32.add(x, 5)

def mk() -> U32:
  9
