# js multi-result: how wide a signature the window convention can take. An
# unboxed record parameter costs one tag plus its live slots on top of the
# ordinary parameters, and the window adds its own base, so a code with 28
# scalar parameters and one two-field record is the widest shape that still
# fills the 32-argument fast path ($tailArgs and run_named through 32). The
# 29-scalar twin is one past that: admitted or boxed, it must print the same
# numbers, so a boundary decision that changes only the calling convention is
# still observable here.
import Base

type JsMultiSched is Data:
  JsMultiRun{fuel: U32, pc: U32}
  JsMultiStep{pc: U32, fuel: U32}
  JsMultiMark{-witness: U32, value: U32, back: U32}
  JsMultiHalt{value: U32}

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

def total28(a0: U32, a1: U32, a2: U32, a3: U32, a4: U32, a5: U32, a6: U32,
    a7: U32, a8: U32, a9: U32, a10: U32, a11: U32, a12: U32, a13: U32,
    a14: U32, a15: U32, a16: U32, a17: U32, a18: U32, a19: U32, a20: U32,
    a21: U32, a22: U32, a23: U32, a24: U32, a25: U32, a26: U32, a27: U32) -> U32:
  U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(a0, a1), U32.add(a2, a3)), U32.add(a4, a5)), U32.add(a6, a7)), U32.add(a8, a9)), U32.add(a10, a11)), U32.add(a12, a13)), U32.add(a14, a15)), U32.add(a16, a17)), U32.add(a18, a19)), U32.add(a20, a21)), U32.add(a22, a23)), U32.add(a24, a25)), U32.add(a26, a27))

def wide28_go(total: U32, r: JsMultiSched) -> JsMultiSched:
  match r:
    case JsMultiRun{fuel, pc}:
      JsMultiHalt{U32.add(total, U32.add(fuel, pc))}
    case JsMultiStep{pc, fuel}:
      JsMultiHalt{U32.add(total, U32.add(pc, fuel))}
    case JsMultiMark{w, value, back}:
      JsMultiHalt{U32.add(total, U32.add(value, back))}
    case JsMultiHalt{value}:
      JsMultiHalt{U32.add(total, value)}

def wide28(a0: U32, a1: U32, a2: U32, a3: U32, a4: U32, a5: U32, a6: U32,
    a7: U32, a8: U32, a9: U32, a10: U32, a11: U32, a12: U32, a13: U32,
    a14: U32, a15: U32, a16: U32, a17: U32, a18: U32, a19: U32, a20: U32,
    a21: U32, a22: U32, a23: U32, a24: U32, a25: U32, a26: U32, a27: U32,
    r: JsMultiSched) -> JsMultiSched:
  wide28_go(total28(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12,
    a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27), r)

def total29(a0: U32, a1: U32, a2: U32, a3: U32, a4: U32, a5: U32, a6: U32,
    a7: U32, a8: U32, a9: U32, a10: U32, a11: U32, a12: U32, a13: U32,
    a14: U32, a15: U32, a16: U32, a17: U32, a18: U32, a19: U32, a20: U32,
    a21: U32, a22: U32, a23: U32, a24: U32, a25: U32, a26: U32, a27: U32,
    a28: U32) -> U32:
  U32.add(total28(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12,
    a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27), a28)

def wide29_go(total: U32, r: JsMultiSched) -> JsMultiSched:
  match r:
    case JsMultiRun{fuel, pc}:
      JsMultiHalt{U32.add(total, U32.add(fuel, pc))}
    case JsMultiStep{pc, fuel}:
      JsMultiHalt{U32.add(total, U32.add(pc, fuel))}
    case JsMultiMark{w, value, back}:
      JsMultiHalt{U32.add(total, U32.add(value, back))}
    case JsMultiHalt{value}:
      JsMultiHalt{U32.add(total, value)}

def wide29(a0: U32, a1: U32, a2: U32, a3: U32, a4: U32, a5: U32, a6: U32,
    a7: U32, a8: U32, a9: U32, a10: U32, a11: U32, a12: U32, a13: U32,
    a14: U32, a15: U32, a16: U32, a17: U32, a18: U32, a19: U32, a20: U32,
    a21: U32, a22: U32, a23: U32, a24: U32, a25: U32, a26: U32, a27: U32,
    a28: U32, r: JsMultiSched) -> JsMultiSched:
  wide29_go(total29(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12,
    a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27,
    a28), r)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(describe(wide28(
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, JsMultiRun{3, 4}))))
    IO.print(U32.show(describe(wide29(
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, JsMultiRun{5, 6}))))

#|10413
#|10446
