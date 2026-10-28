# A scheduler-shaped record chain covers different constructor field orders,
# erased fields, narrower arms, tail forwarding and recursion past 64 frames.
# Stored and overlapping results must remain independent. Nested patterns can
# fail and fall through after a call without losing the surrounding frame.
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

type JsMultiQuad is Data:
  JsMultiQuad{a: U32, b: U32, c: U32, d: U32}

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

# Both results stay live across another split before their words are forwarded.
def overlapping() -> U32:
  x = roll(JsMultiRun{5, 7})
  y = roll(JsMultiRun{3, 2})
  a = roll(x)
  b = roll(y)
  U32.add(describe(a), describe(b))

# The second private call must materialize its result, not consume x boxed.
def escape_after_forward() -> U32:
  x = roll(JsMultiRun{5, 7})
  y = roll(x)
  stash_read(stash(y))

# Forward a parameter through a call whose result is stored before it is read.
def relay(r: JsMultiSched) -> JsMultiSched:
  p = stash(roll(r))
  JsMultiHalt{stash_read(p)}

def relay_reach(z: U32) -> U32:
  describe(settle(relay(JsMultiHalt{z})))

# Mutually recursive forwarding preserves fields through the entire tail chain.
def quad_a(a: U32, b: U32, c: U32, d: U32, e: U32, f: U32, g: U32, h: U32, i: U32) -> JsMultiQuad:
  JsMultiQuad{U32.add(a, b), U32.add(c, d), U32.add(e, f), U32.add(g, U32.add(h, i))}

def quad_b(x: U32) -> JsMultiQuad:
  quad_a(x, 2, 3, 4, 5, 6, 7, 8, 9)

def quad_c(x: U32) -> JsMultiQuad:
  quad_b(x)

def quad_sum(q: JsMultiQuad) -> U32:
  match q:
    case JsMultiQuad{a, b, c, d}:
      U32.add(U32.add(a, b), U32.add(c, d))

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
    Unit <- IO.print(U32.show(after_d()))
    Unit <- IO.print(U32.show(overlapping()))
    Unit <- IO.print(U32.show(escape_after_forward()))
    Unit <- IO.print(U32.show(relay_reach(41)))
    IO.print(U32.show(quad_sum(quad_c(1))))

#|75
#|1025
#|10011
#|24
#|35
#|76
#|89
#|58
#|20044
#|45
