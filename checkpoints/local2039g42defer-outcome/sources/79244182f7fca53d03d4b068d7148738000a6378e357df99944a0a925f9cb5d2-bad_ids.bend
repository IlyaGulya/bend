import Base
def bad.ids(value: U32) -> IO(U32):
  import "./bad_ids.c"
def main() -> IO(Unit):
  do IO<Unit>:
    value : U32 <- bad.ids(1)
    IO.print(U32.show(value))
