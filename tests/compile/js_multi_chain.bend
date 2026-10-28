# js multi-result: a scheduler-shaped chain whose steps hand a record to the
# next code instead of allocating one object per step.
#
# `settle` is the producer: every arm builds one of four constructors, so one
# window width covers the program while the live keys differ. JsMultiRun{fuel,
# pc} and JsMultiStep{pc, fuel} put a different key in the same slot,
# JsMultiMark's first field is erased, and JsMultiHalt is narrower. `roll`
# forwards a record through a tail call, `chunk` recurses past 64 frames, and
# its zero arm returns its own parameter, so a forwarded result is destructured
# by the next `settle`. `stash` is an ordinary boxed consumer: its tuple field
# can only hold a real record, so the private result is materialized exactly
# once before it is stored, and `describe` reads the fields back. `unwrap` is
# the nested-pattern region shape: its arms nest constructor patterns that can
# fail, and each arm calls `scale` before it leaves.
import Base

type JsMultiSched is Data:
  JsMultiRun{fuel: U32, pc: U32}
  JsMultiStep{pc: U32, fuel: U32}
  JsMultiMark{-witness: U32, value: U32, back: U32}
  JsMultiHalt{value: U32}

type JsMultiWake is Data:
  JsMultiReady{slot: U32}
  JsMultiParked{slot: U32}

type JsMultiWrapped is Data:
  JsMultiWrapped{wake: JsMultiWake, sched: JsMultiSched, tag: U32}

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

def scale(l: U32, r: U32) -> U32:
  U32.add(U32.mul(l, 2), r)

def unwrap(w: JsMultiWrapped) -> U32:
  match w:
    case JsMultiWrapped{JsMultiReady{n}, JsMultiRun{fuel, pc}, tag}:
      U32.add(scale(fuel, pc), U32.add(n, tag))
    case JsMultiWrapped{JsMultiReady{n}, JsMultiStep{pc, fuel}, tag}:
      U32.add(scale(fuel, pc), U32.add(n, tag))
    case JsMultiWrapped{JsMultiParked{n}, sched, tag}:
      U32.add(describe(sched), U32.add(n, tag))
    case JsMultiWrapped{JsMultiReady{n}, sched, tag}:
      U32.add(describe(sched), U32.add(n, tag))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(describe(chunk(131n, JsMultiRun{5, 7}))))
    Unit <- IO.print(U32.show(describe(chunk(3n, JsMultiMark{0, 11, 4}))))
    Unit <- IO.print(U32.show(describe(chunk(2n, JsMultiHalt{9}))))
    Unit <- IO.print(U32.show(unwrap(JsMultiWrapped{JsMultiReady{3}, chunk(131n, JsMultiRun{5, 7}), 4})))
    Unit <- IO.print(U32.show(unwrap(JsMultiWrapped{JsMultiParked{6}, chunk(130n, JsMultiStep{2, 8}), 1})))
    IO.print(U32.show(after_d()))

#|75
#|1025
#|10011
#|24
#|35
#|76
