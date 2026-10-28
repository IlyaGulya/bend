# js multi-result: a host effect reenters compiled code while the caller's
# split still owns its capture slots, throws through the machine, and then
# calls the machine again. The reentered calls run the same record chain as
# the outer program, so their result windows sit above the outer frame's own
# slots; the outer continuation then reads the outer capture and materializes
# a record of its own. A window that moved, cleared, or reused the caller's
# base would change the printed numbers, and an unwind that lost the outer
# scheduler would fail the second call.
import Base

type JsMultiSched is Data:
  JsMultiRun{fuel: U32, pc: U32}
  JsMultiStep{pc: U32, fuel: U32}
  JsMultiMark{-witness: U32, value: U32, back: U32}
  JsMultiHalt{value: U32}

def settle(r: JsMultiSched) -> JsMultiSched:
  match r:
    case JsMultiRun{fuel, pc}:
      JsMultiStep{pc, fuel}
    case JsMultiStep{pc, fuel}:
      JsMultiRun{fuel, pc}
    case JsMultiMark{w, value, back}:
      JsMultiMark{0, value, U32.add(back, 1)}
    case JsMultiHalt{value}:
      JsMultiHalt{U32.add(value, 1)}

def roll(r: JsMultiSched) -> JsMultiSched:
  settle(r)

def chunk(n: Nat, r: JsMultiSched) -> JsMultiSched:
  match n:
    case 0n:
      r
    case 1n+p:
      chunk(p, roll(r))

def describe(r: JsMultiSched) -> U32:
  match r:
    case JsMultiRun{fuel, pc}:
      U32.add(U32.mul(fuel, 10), pc)
    case JsMultiStep{pc, fuel}:
      U32.add(U32.mul(pc, 10), fuel)
    case JsMultiMark{w, value, back}:
      U32.add(U32.add(value, U32.mul(back, 2)), 1000)
    case JsMultiHalt{value}:
      U32.add(value, 10000)

def stash(r: JsMultiSched) -> JsMultiSched & U32:
  (r, 1)

def stash_read(p: JsMultiSched & U32) -> U32:
  (r, n) = p
  U32.add(describe(r), n)

def after_d() -> U32:
  stash_read(stash(chunk(131n, JsMultiRun{5, 7})))

def chain3(z: U32) -> U32:
  describe(chunk(3n, JsMultiRun{z, 1}))

def chain2(z: U32) -> U32:
  describe(chunk(2n, JsMultiHalt{z}))

def overflow(n: Nat) -> Nat:
  Nat.add(n, 1n)

def Host.reenter(f: U32 -> U32, x: U32,
    g: Nat -> Nat, h: U32 -> U32) -> IO(U32):
  import "./js_multi_reentrant.js"

def orchestrate(+x: U32) -> IO(U32):
  do IO<U32>:
    y : U32 <- Host.reenter(z => chain3(z), x, n => overflow(n),
      z => chain2(z))
    return U32.add(U32.add(x, y), after_d())

def main() -> IO(Unit):
  do IO<Unit>:
    a : U32 <- orchestrate(7)
    Unit <- IO.print(U32.show(a))
    IO.print(U32.show(after_d()))

#|10109
#|76
