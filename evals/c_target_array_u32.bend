# C target fixture: one-word array cells through Phys.array_part.
#
# Array.new makes four U32 cells, set writes a value, get lets the value escape
# the owned array, swap exchanges a cell and returns the old value, clone forks
# the array, and size reads the forked length. Expected 15 from get(1)=7 and
# swap(0, 9) old=0, plus clone size 4, plus 4: 7+0+4+4 = 15.
import Base

def main() -> IO(Unit):
  a = Array.new(U32, 2n, 0)
  b = Array.set(U32, a, 1, 7)
  (c, got) = Array.get(U32, b, 1)
  (d, old) = Array.swap(U32, c, 0, 9)
  (e, copy) = Array.clone(U32, d)
  (f, n) = Array.size(U32, e)
  (g, m) = Array.size(U32, copy)
  IO.print(U32.show(U32.add(got, U32.add(old, U32.add(n, m)))))

#|15
