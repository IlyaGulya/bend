# All four Bool.xor inputs cross a function boundary and are observed by
# Bool.show, which requires a canonical False/True constructor, not raw 0/1.
import Base

def xor_text(a: Bool, b: Bool) -> String:
  Bool.show(Bool.xor(a, b))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(xor_text(False{}, False{}))
    Unit <- IO.print(xor_text(False{}, True{}))
    Unit <- IO.print(xor_text(True{}, False{}))
    IO.print(xor_text(True{}, True{}))

#|False
#|True
#|True
#|False
