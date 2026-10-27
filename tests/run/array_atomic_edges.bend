# Atomics forward shared storage, wrap indices, return the old scalar, and
# retain CAS partial-application and binary32 bit semantics.
import Base

def fadd_read(old: F32, r: Array<F32> & F32) -> IO(Unit):
  (_, now) = r
  do IO<Unit>:
    Unit <- IO.print(U32.show(F32.bits(old)))
    IO.print(U32.show(F32.bits(now)))

def fadd_show(r: Array<F32> & F32) -> IO(Unit):
  (a, old) = r
  fadd_read(old, Array.get(F32, a, 1))

def floats() -> IO(Unit):
  do IO<Unit>:
    Unit <- fadd_show(Array.atomic.fadd(Array.new(F32, 1n,
      F32.neg(0.0)), 3, 0.0))
    fadd_show(Array.atomic.fadd(Array.new(F32, 1n,
      16777216.0), 3, 1.0))

def hit(a: Array<U32>) -> Array<U32> & U32:
  compare = Array.atomic.cas(a, 9)
  replace = compare(42)
  replace(7)

def hit_read(old: U32, r: Array<U32> & U32) -> IO(Unit):
  (_, now) = r
  do IO<Unit>:
    Unit <- IO.print(U32.show(old))
    Unit <- IO.print(U32.show(now))
    floats()

def hit_show(r: Array<U32> & U32) -> IO(Unit):
  (a, old) = r
  hit_read(old, Array.get(U32, a, 1))

def miss(a: Array<U32>) -> Array<U32> & U32:
  compare = Array.atomic.cas(a, 9)
  replace = compare(41)
  replace(7)

def miss_read(old: U32, r: Array<U32> & U32) -> IO(Unit):
  (a, now) = r
  do IO<Unit>:
    Unit <- IO.print(U32.show(old))
    Unit <- IO.print(U32.show(now))
    hit_show(hit(a))

def miss_show(r: Array<U32> & U32) -> IO(Unit):
  (a, old) = r
  miss_read(old, Array.get(U32, a, 1))

def add_read(old: U32, r: Array<U32> & U32) -> IO(Unit):
  (_, now) = r
  do IO<Unit>:
    Unit <- IO.print(U32.show(old))
    Unit <- IO.print(U32.show(now))
    miss_show(miss(Array.new(U32, 2n, 42)))

def add_show(b: Array<U32>, r: Array<U32> & U32) -> IO(Unit):
  (a, old) = r
  add_read(old, Array.get(U32, Array.join(U32, b, a), 1))

def start(r: Array<U32> & Array<U32>) -> IO(Unit):
  (a, b) = r
  add_show(b, Array.atomic.add(a, 5, 3))

def main() -> IO(Unit):
  start(Array.fork(U32, Array.new(U32, 2n, 4294967295)))

#|4294967295
#|2
#|42
#|42
#|42
#|7
#|2147483648
#|0
#|1266679808
#|1266679808
