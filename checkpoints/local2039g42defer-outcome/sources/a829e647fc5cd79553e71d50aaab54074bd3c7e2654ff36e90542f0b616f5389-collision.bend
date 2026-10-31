import Base

def a.b(x: U32) -> U32:
  (x + 1 : U32)

def a_b(x: U32) -> U32:
  (x + 2 : U32)

def check.ids(value: U32) -> IO(U32):
  import "./collision.c"
  import "./collision.js"

def main() -> IO(Unit):
  do IO<Unit>:
    value : U32 <- check.ids((a.b(10) + a_b(20) : U32))
    IO.print(U32.show(value))

#|33
