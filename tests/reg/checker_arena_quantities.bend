import Base
import ../../bend2/selfhost/checker_arena.bend as Arena
import ../../bend2/selfhost/ast.bend as Ast

def quantity_tag(q: Ast.Quantity) -> U32:
  match q:
    case Ast.QZero{}: 0
    case Ast.QOne{}: 1
    case Ast.QMany{}: 2

def main() -> IO(Unit):
  a = quantity_tag(Arena.word_quantity(0))
  b = quantity_tag(Arena.word_quantity(1))
  c = quantity_tag(Arena.word_quantity(2))
  d = quantity_tag(Arena.word_quantity(4294967295))
  e = Arena.quantity_word(Ast.QZero{})
  f = Arena.quantity_word(Ast.QOne{})
  g = Arena.quantity_word(Ast.QMany{})
  sum = U32.add(a, U32.add(U32.mul(b, 10), U32.add(U32.mul(c, 100), U32.add(U32.mul(d, 1000), U32.add(U32.mul(e, 10000), U32.add(U32.mul(f, 100000), U32.mul(g, 1000000)))))))
  IO.print(U32.show(sum))

#|2102210
