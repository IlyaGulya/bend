# js backend: a nested pattern that can fail leaves one case and resumes the
# remaining ones, and a case that calls before its own leave keeps a private
# region frame while the neighbouring arm joins. The record each arm takes apart
# is bound, not boxed, across that leave, and the tail call that walks the loop
# carries a freshly built record into the same destructuring.
import Base

type Node is Data:
  Leaf{v: U32}
  Pair{l: U32, r: U32}

type Wrap is Data:
  Wrap{node: Node, tag: U32}

def scale(l: U32, r: U32) -> U32:
  U32.add(U32.mul(l, 2), r)

def deep(w: Wrap) -> U32:
  match w:
    case Wrap{Pair{l, r}, tag}: U32.add(scale(l, r), tag)
    case Wrap{Leaf{v}, tag}: U32.add(U32.mul(v, 3), tag)

def spin(n: Nat, w: Wrap) -> U32:
  match n:
    case 0n: deep(w)
    case 1n+p: spin(p, Wrap{Pair{U32.add(U32.from_nat(p), 1), U32.mul(U32.from_nat(p), 2)}, U32.add(U32.from_nat(p), 3)})

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(deep(Wrap{Pair{2, 5}, 4})))
    IO.print(U32.show(spin(3n, Wrap{Leaf{1}, 1})))
    IO.print(U32.show(deep(Wrap{Leaf{7}, 1})))

#|13
#|5
#|22
