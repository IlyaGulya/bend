# C target fixture: one-word array cells through Phys.array_part.
#
# Array.new makes four U32 cells, set writes a value, get lets the value escape
# the owned array, swap exchanges a cell with the rest of the chain, clone
# forks the array, and size reads both lengths. Every scalar binder is used at
# most once, so the program stays inside the checked linear-use subset.
# Expected 15: get(1)=7, swap old=0, and two singleton sizes after clone.
import Base

def value_of(pair: Array<U32> & U32) -> U32:
  (arr, v) = pair
  v

def length_of(pair: Array<U32> & U32) -> U32:
  (arr, n) = pair
  n

def both_sizes(pair: Array<U32> & Array<U32>) -> U32:
  (a, b) = pair
  U32.add(length_of(Array.size(U32, a)), length_of(Array.size(U32, b)))

def tail_after(arr: Array<U32>) -> U32:
  both_sizes(Array.clone(U32, arr))

def after_swap(pair: Array<U32> & U32) -> U32:
  (arr, old) = pair
  U32.add(old, tail_after(arr))

def after_get(pair: Array<U32> & U32) -> U32:
  (arr, got) = pair
  U32.add(got, after_swap(Array.swap(U32, arr, 0, 9)))

def main() -> IO(Unit):
  a = Array.new(U32, 2n, 0)
  b = Array.set(U32, a, 1, 7)
  IO.print(U32.show(after_get(Array.get(U32, b, 1))))

#|15
