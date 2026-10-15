import Base

type Parcel is Data:
  Parcel{-ghost: U32, payload: U32}
  Vacant{-ghost: U32}

def ignore(-ghost: U32, payload: U32) -> U32:
  payload

def read(value: Parcel) -> U32:
  match value:
    case Parcel{ghost, payload}: ignore(ghost, payload)
    case Vacant{ghost}: ignore(ghost, 7)

def main() -> IO(Unit):
  filled = read(Parcel{13, 41})
  empty = read(Vacant{19})
  IO.print(U32.show(U32.add(filled, empty)))

#|48
