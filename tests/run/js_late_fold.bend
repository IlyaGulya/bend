import Base

def early(c: Bool, a: U32, b: U32) -> U32:
  Bool.pick(U32, c, a, b)

def lookup(x: U32) -> U32:
  match x:
    case 0: early(True{}, 1, 2)
    case _: early(False{}, 3, 4)

def main() -> U32:
  lookup(0)

#|1
