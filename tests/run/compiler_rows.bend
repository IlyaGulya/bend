import Base

# Reads outlive rewind and owner disposal; wide Nat, IEEE -0 and UTF-16 survive.
type Row is Data:
  Empty{}
  Payload{word: U32, wide: Nat, bits: F32, text: String, child: List<&2, U32>}
  Wide{a0: U32, a1: U32, a2: U32, a3: U32, a4: U32, a5: U32, a6: U32, a7: U32, a8: U32, a9: U32, a10: U32, a11: U32, a12: U32, a13: U32, a14: U32, a15: U32, a16: U32, a17: U32, a18: U32, a19: U32, a20: U32, a21: U32, a22: U32, a23: U32, a24: U32, a25: U32, a26: U32, a27: U32, a28: U32, a29: U32, a30: U32, a31: U32, tail: Nat}

def from_bits(value: U32) -> F32:
  match value:
    case U32{word}: F32{word}

def payload() -> Row:
  Payload{4294967295, Nat.add(4294967295n, 2n), from_bits(2147483648), "😀λ", [7, 9]}

def child_tail(first: U32, rest: List<&2, U32>) -> Bool:
  match rest:
    case Nil{}: False{}
    case Con{head, tail}: Bool.and(U32.is_eq(first, 7), Bool.and(U32.is_eq(head, 9), Nat.is_eq(List.length(&2, U32, tail), 0n)))

def child_ok(values: List<&2, U32>) -> Bool:
  match values:
    case Nil{}: False{}
    case Con{head, tail}: child_tail(head, tail)

def score(value: Row) -> U32:
  match value:
    case Empty{}: 0
    case Payload{word, wide, bits, text, child}:
      Bool.pick(U32, Bool.and(U32.is_eq(word, 4294967295), Bool.and(Nat.is_eq(wide, Nat.add(4294967295n, 2n)), Bool.and(U32.is_eq(F32.bits(bits), 2147483648), Bool.and(String.eq(text, "😀λ"), child_ok(child))))), 1, 0)
    case Wide{_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, tail}:
      Bool.pick(U32, Nat.is_eq(tail, Nat.add(4294967295n, 2n)), 33, 0)

def result_score(result: CompilerRows(Row) & Row) -> U32:
  match result:
    case Tuple{rows, value}: score(value)

def grown() -> CompilerRows(Row):
  CompilerRows.append(Row, CompilerRows.append(Row, CompilerRows.new(Row, 0n, Empty{}), payload()), Empty{})

def kept_zero(value: Row, result: CompilerRows(Row) & Row) -> U32:
  match result:
    case Tuple{empty, zero}: U32.add(U32.mul(score(value), 10), score(zero))

def kept(result: CompilerRows(Row) & Row) -> U32:
  match result:
    case Tuple{rows, value}:
      kept_zero(value, CompilerRows.get(Row, CompilerRows.rewind(Row, rows, 0), 0))

def reused(rows: CompilerRows(Row)) -> U32:
  result_score(CompilerRows.get(Row, CompilerRows.append(Row, CompilerRows.rewind(Row, rows, 0), payload()), 2))

def use_get(get: CompilerRows(Row) -> @+index: U32 -> CompilerRows(Row) & Row, rows: CompilerRows(Row)) -> U32:
  result_score(get(rows, 0))

def use_append(append: CompilerRows(Row) -> Row -> CompilerRows(Row), rows: CompilerRows(Row)) -> U32:
  result_score(CompilerRows.get(Row, append(rows, payload()), 0))

def use_grow(grow: CompilerRows(Row) -> CompilerRows(Row), rows: CompilerRows(Row)) -> U32:
  result_score(CompilerRows.get(Row, grow(rows), 2))

def use_rewind(rewind: CompilerRows(Row) -> @+target: U32 -> CompilerRows(Row), rows: CompilerRows(Row)) -> U32:
  result_score(CompilerRows.get(Row, rewind(rows, 0), 0))

def use_new(new: @+depth: Nat -> @+zero: Row -> CompilerRows(Row)) -> U32:
  result_score(CompilerRows.get(Row, new(0n, payload()), 4294967295))

def use_partial(get: @+index: U32 -> CompilerRows(Row) & Row) -> U32:
  result_score(get(0))

def wide() -> Row:
  Wide{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, Nat.add(4294967295n, 2n)}

def scalar(result: CompilerRows(U32) & U32) -> U32:
  match result:
    case Tuple{rows, value}: value

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(result_score(CompilerRows.get(Row, CompilerRows.new(Row, 0n, payload()), 0))))
    IO.print(U32.show(result_score(CompilerRows.get(Row, grown(), 4294967294))))
    IO.print(U32.show(result_score(CompilerRows.get(Row, CompilerRows.grow(Row, grown()), 2))))
    IO.print(U32.show(kept(CompilerRows.get(Row, grown(), 0))))
    IO.print(U32.show(reused(grown())))
    IO.print(U32.show(use_get(CompilerRows.get(Row), grown())))
    IO.print(U32.show(use_append(CompilerRows.append(Row), CompilerRows.new(Row, 0n, Empty{}))))
    IO.print(U32.show(use_grow(CompilerRows.grow(Row), grown())))
    IO.print(U32.show(use_rewind(CompilerRows.rewind(Row), grown())))
    IO.print(U32.show(use_new(CompilerRows.new(Row))))
    IO.print(U32.show(use_partial(CompilerRows.get(Row, grown()))))
    IO.print(U32.show(result_score(CompilerRows.get(Row, CompilerRows.append(Row, CompilerRows.new(Row, 0n, Empty{}), wide()), 0))))
    IO.print(U32.show(scalar(CompilerRows.get(U32, CompilerRows.append(U32, CompilerRows.new(U32, 0n, 0), 4294967295), 0))))

#|1
#|1
#|0
#|10
#|1
#|1
#|1
#|0
#|0
#|1
#|1
#|33
#|4294967295
