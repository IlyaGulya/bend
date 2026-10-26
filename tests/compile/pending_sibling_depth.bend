# pending siblings: a left-nested product keeps one sibling pending at every
# level the emitter descends, while a chain whose recursive field is last has
# none; one helper is prepared by every caller that reaches it
# ported from bend3: a shared helper is called from distinct definitions
import Base

type Q is Data:
  Leaf{v: U32}
  Pair{a: Q, b: U32}

law sumq:
  for q: Q
  U32

def sumq(q):
  match q:
    case Leaf{v}:
      v
    case Pair{a, b}:
      x = sumq(a)
      U32.add(x, b)

type Ch is Data:
  Stop{z: U32}
  Step{h: U32, t: Ch}

law sumc:
  for c: Ch
  U32

def sumc(c):
  match c:
    case Stop{z}:
      z
    case Step{h, t}:
      r = sumc(t)
      U32.add(h, r)

law bump:
  for n: U32
  U32

def bump(n):
  U32.add(n, 1)

law w1:
  for n: U32
  U32

def w1(n):
  bump(n)

law w2:
  for n: U32
  U32

def w2(n):
  bump(n)

law w3:
  for n: U32
  U32

def w3(n):
  bump(n)

law main.out:
  U32

def main.out():
  q: Q = Pair{Pair{Pair{Pair{Pair{Leaf{1}, 2}, 3}, 4}, 5}, 6}
  U32.add(sumq(q), U32.add(w3(w2(w1(0))), sumc(Step{1, Step{2, Step{3, Stop{0}}}})))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|30
