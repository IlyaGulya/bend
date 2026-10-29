import Base

# Discarding an uncalled closure must release rows and their referenced payloads.
type Row is Data:
  Row{value: U32, children: List<&2, U32>}

def value(+x: U32) -> Row:
  Row{x, [x, U32.add(x, 1), U32.add(x, 2)]}

def captured_result(x: U32, result: CompilerRows(Row) & Row) -> U32:
  match result:
    case Tuple{rows, row}:
      match row:
        case Row{value, children}: U32.add(value, x)

def captured(rows: CompilerRows(Row), x: U32) -> U32:
  captured_result(x, CompilerRows.get(Row, rows, 0))

def dispose(f: U32 -> U32) -> IO(U32):
  import "./compiler_rows_drop.c"
  import "./compiler_rows_drop.js"

def loop(count: Nat, +x: U32, last: U32) -> IO(U32):
  match count:
    case 0n: IO.pure(U32, last)
    case 1n+rest:
      do IO<U32>:
        rows : CompilerRows(Row) = CompilerRows.append(Row, CompilerRows.append(Row, CompilerRows.new(Row, 2n, value(x)), value(U32.add(x, 3))), value(U32.add(x, 4)))
        result : U32 <- dispose(captured(rows))
        loop(rest, x, result)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    x : U32 = U32.from_nat(List.length(&1, String, args))
    result : U32 <- loop(20000n, x, 0)
    IO.print(U32.show(result))

#|5
