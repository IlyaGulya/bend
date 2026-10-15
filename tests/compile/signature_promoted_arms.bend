# Signature discovery promotes only binders shared by every match arm.
# An eta-short arm must retain its closure ABI; erased promoted binders do
# not become runtime parameters.
import Base

law choose:
  for b: Bool
  @-a: Type -> @x: a -> a

def choose(b):
  match b:
    case False{}:
      a => x => x
    case True{}:
      a => x => x

law inc:
  for x: U32
  U32

def inc(x):
  U32.add(x, 1)

law mixed:
  for b: Bool
  @x: U32 -> U32

def mixed(b):
  match b:
    case False{}:
      x => x
    case True{}:
      inc

law main:
  IO(Unit)

def main():
  a = choose(False{}, U32, 7)
  b = choose(True{}, U32, 11)
  c = mixed(False{}, 13)
  d = mixed(True{}, 17)
  IO.print(U32.show(U32.add(U32.add(a, b), U32.add(c, d))))

#|49
