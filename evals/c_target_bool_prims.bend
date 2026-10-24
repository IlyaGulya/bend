# Bool-valued primitive regression for the C target. Each primitive must return
# a packed Bool term, so the match takes the True/False arm by value, not by
# the raw C condition. Inputs vary across the boundary values of U32, Nat,
# F32 (including NaN), String and List; numbers are the observable branch
# results, not a copy of compiler constants.
import Base

def bit(value: Bool) -> U32:
  match value:
    case True{}:
      1
    case False{}:
      0

def check_u32() -> IO(Unit):
  do IO<Unit>:
      Unit <- IO.print(U32.show(bit(U32.is_eq(0, 0))))
      Unit <- IO.print(U32.show(bit(U32.is_eq(0, 1))))
      Unit <- IO.print(U32.show(bit(U32.is_ne(0, 1))))
      Unit <- IO.print(U32.show(bit(U32.is_ne(3, 3))))
      Unit <- IO.print(U32.show(bit(U32.is_lt(0, 1))))
      Unit <- IO.print(U32.show(bit(U32.is_lt(1, 0))))
      Unit <- IO.print(U32.show(bit(U32.is_le(1, 1))))
      Unit <- IO.print(U32.show(bit(U32.is_le(2, 1))))
      Unit <- IO.print(U32.show(bit(U32.is_gt(U32.not(0), 0))))
      Unit <- IO.print(U32.show(bit(U32.is_gt(0, U32.not(0)))))
      Unit <- IO.print(U32.show(bit(U32.is_ge(0, 0))))
      Unit <- IO.print(U32.show(bit(U32.is_ge(0, 1))))
      Unit <- IO.print(U32.show(bit(U32.is_eq(U32.not(0), U32.not(0)))))
    return Unit{}

def check_nat() -> IO(Unit):
  do IO<Unit>:
      Unit <- IO.print(U32.show(bit(Nat.is_lt(0n, 1n))))
      Unit <- IO.print(U32.show(bit(Nat.is_lt(1n, 1n))))
      Unit <- IO.print(U32.show(bit(Nat.is_eq(2n, 2n))))
      Unit <- IO.print(U32.show(bit(Nat.is_ne(2n, 3n))))
      Unit <- IO.print(U32.show(bit(Nat.is_le(3n, 3n))))
      Unit <- IO.print(U32.show(bit(Nat.is_le(4n, 3n))))
      Unit <- IO.print(U32.show(bit(Nat.is_gt(4n, 3n))))
      Unit <- IO.print(U32.show(bit(Nat.is_ge(3n, 4n))))
    return Unit{}

def check_f32() -> IO(Unit):
  do IO<Unit>:
      Unit <- IO.print(U32.show(bit(F32.is_eq(1.5, 1.5))))
      Unit <- IO.print(U32.show(bit(F32.is_eq(1.5, 2.5))))
      Unit <- IO.print(U32.show(bit(F32.is_ne(1.5, 2.5))))
      Unit <- IO.print(U32.show(bit(F32.is_ne(1.5, 1.5))))
      Unit <- IO.print(U32.show(bit(F32.is_lt(1.5, 2.5))))
      Unit <- IO.print(U32.show(bit(F32.is_lt(2.5, 1.5))))
      Unit <- IO.print(U32.show(bit(F32.is_le(2.5, 2.5))))
      Unit <- IO.print(U32.show(bit(F32.is_le(3.5, 2.5))))
      Unit <- IO.print(U32.show(bit(F32.is_gt(3.5, 2.5))))
      Unit <- IO.print(U32.show(bit(F32.is_gt(2.5, 2.5))))
      Unit <- IO.print(U32.show(bit(F32.is_ge(2.5, 2.5))))
      Unit <- IO.print(U32.show(bit(F32.is_ge(1.5, 2.5))))
      Unit <- IO.print(U32.show(bit(F32.is_eq(F32.div(0.0, 0.0), F32.div(0.0, 0.0)))))
      Unit <- IO.print(U32.show(bit(F32.is_ne(F32.div(0.0, 0.0), F32.div(0.0, 0.0)))))
      Unit <- IO.print(U32.show(bit(F32.is_lt(F32.div(0.0, 0.0), 1.0))))
      Unit <- IO.print(U32.show(bit(F32.is_ge(F32.div(0.0, 0.0), 1.0))))
      Unit <- IO.print(U32.show(bit(F32.is_gt(F32.div(1.0, 0.0), 1000000.0))))
    return Unit{}

def check_string() -> IO(Unit):
  do IO<Unit>:
      Unit <- IO.print(U32.show(bit(String.eq("bend", "bend"))))
      Unit <- IO.print(U32.show(bit(String.eq("bend", "bent"))))
      Unit <- IO.print(U32.show(bit(String.eq("", ""))))
      Unit <- IO.print(U32.show(bit(String.is_empty(""))))
      Unit <- IO.print(U32.show(bit(String.is_empty("x"))))
      Unit <- IO.print(U32.show(bit(String.contains("bend", "en"))))
      Unit <- IO.print(U32.show(bit(String.contains("bend", "xy"))))
    return Unit{}

def check_list() -> IO(Unit):
  do IO<Unit>:
      Unit <- IO.print(U32.show(bit(List.is_empty(&2, U32, Nil{}))))
      Unit <- IO.print(U32.show(bit(List.is_empty(&2, U32, 1 <> Nil{}))))
    return Unit{}

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- check_u32()
    Unit <- check_nat()
    Unit <- check_f32()
    Unit <- check_string()
    Unit <- check_list()
    return Unit{}

#|1
#|0
#|1
#|0
#|1
#|0
#|1
#|0
#|1
#|0
#|1
#|0
#|1
#|1
#|0
#|1
#|1
#|1
#|0
#|1
#|0
#|1
#|0
#|1
#|0
#|1
#|0
#|1
#|0
#|1
#|0
#|1
#|0
#|0
#|1
#|0
#|0
#|1
#|1
#|0
#|1
#|1
#|0
#|1
#|0
#|1
#|0
