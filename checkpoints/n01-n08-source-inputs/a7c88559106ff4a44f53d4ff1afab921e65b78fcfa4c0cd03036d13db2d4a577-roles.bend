# Independent obligations: selected declaration owner, erased field position,
# and ScalarOccurrence payload bits that are not arena handles.
import Base
import ./left.bend as Left
import ./right.bend as Right

type Row is Data:
  Row{-witness: U32, left: U32, right: U32}

def read_row(row: Row) -> U32:
  match row:
    case Row{witness, left, right}: U32.add(U32.mul(left, 100), right)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(read_row(Row{99, Left.value(), Right.value()})))
    Unit <- IO.print(U32.show(2147483648))
    IO.print(U32.show(4294967295))

#|1129
#|2147483648
#|4294967295
