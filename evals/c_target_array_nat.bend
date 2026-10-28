# C target fixture: Nat element cells. Nat is native scalar storage in the
# cell type, so the descriptor must reach CLay.array_cell as Nat, not U32 or a
# boxed word. Expected 7 from the set cell.
import Base

def element(pair: Array<Nat> & Nat) -> Nat:
  (a, v) = pair
  v

def main() -> IO(Unit):
  a = Array.new(Nat, 2n, 0n)
  b = Array.set(Nat, a, 1, 7n)
  IO.print(Nat.show(element(Array.get(Nat, b, 1))))

#|7
