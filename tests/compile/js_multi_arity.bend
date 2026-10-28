# Record calls straddle the 32-live-argument fast path: 31 scalars plus one
# record fit, while 32 scalars plus one record require the general path.
# Both preserve argument order and the returned constructor fields.
import Base

type JsMultiSched is Data:
  JsMultiRun{fuel: U32, pc: U32}
  JsMultiStep{pc: U32, fuel: U32}
  JsMultiMark{-witness: U32, value: U32, back: U32}
  JsMultiHalt{value: U32}

def describe(r: JsMultiSched) -> U32:
  match r:
    case JsMultiRun{fuel, pc}: U32.add(U32.mul(fuel, 10), pc)
    case JsMultiStep{pc, fuel}: U32.add(U32.mul(pc, 10), fuel)
    case JsMultiMark{w, value, back}: U32.add(U32.add(value, U32.mul(back, 2)), 1000)
    case JsMultiHalt{value}: U32.add(value, 10000)

def total31(a0: U32, a1: U32, a2: U32, a3: U32, a4: U32, a5: U32, a6: U32, a7: U32, a8: U32, a9: U32, a10: U32, a11: U32, a12: U32, a13: U32, a14: U32, a15: U32, a16: U32, a17: U32, a18: U32, a19: U32, a20: U32, a21: U32, a22: U32, a23: U32, a24: U32, a25: U32, a26: U32, a27: U32, a28: U32, a29: U32, a30: U32) -> U32:
  U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(a0, a1), a2), a3), a4), a5), a6), a7), a8), a9), a10), a11), a12), a13), a14), a15), a16), a17), a18), a19), a20), a21), a22), a23), a24), a25), a26), a27), a28), a29), a30)

def finish(total: U32, r: JsMultiSched) -> JsMultiSched:
  match r:
    case JsMultiRun{fuel, pc}: JsMultiHalt{U32.add(total, U32.add(fuel, pc))}
    case JsMultiStep{pc, fuel}: JsMultiHalt{U32.add(total, U32.add(pc, fuel))}
    case JsMultiMark{w, value, back}: JsMultiHalt{U32.add(total, U32.add(value, back))}
    case JsMultiHalt{value}: JsMultiHalt{U32.add(total, value)}

def wide31(a0: U32, a1: U32, a2: U32, a3: U32, a4: U32, a5: U32, a6: U32, a7: U32, a8: U32, a9: U32, a10: U32, a11: U32, a12: U32, a13: U32, a14: U32, a15: U32, a16: U32, a17: U32, a18: U32, a19: U32, a20: U32, a21: U32, a22: U32, a23: U32, a24: U32, a25: U32, a26: U32, a27: U32, a28: U32, a29: U32, a30: U32, r: JsMultiSched) -> JsMultiSched:
  finish(total31(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30), r)

def wide32(a0: U32, a1: U32, a2: U32, a3: U32, a4: U32, a5: U32, a6: U32, a7: U32, a8: U32, a9: U32, a10: U32, a11: U32, a12: U32, a13: U32, a14: U32, a15: U32, a16: U32, a17: U32, a18: U32, a19: U32, a20: U32, a21: U32, a22: U32, a23: U32, a24: U32, a25: U32, a26: U32, a27: U32, a28: U32, a29: U32, a30: U32, a31: U32, r: JsMultiSched) -> JsMultiSched:
  finish(U32.add(total31(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20, a21, a22, a23, a24, a25, a26, a27, a28, a29, a30), a31), r)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(describe(wide31(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, JsMultiRun{3, 4}))))
    IO.print(U32.show(describe(wide32(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, JsMultiRun{5, 6}))))

#|10503
#|10539
