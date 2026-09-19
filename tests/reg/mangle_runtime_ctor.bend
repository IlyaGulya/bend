# regression witness: a constructor whose name folds to the same C macro as a
# constructor the runtime builds and matches by name. `SCON` folds to SCON, and
# CID_SCON is the String constructor the runtime walks strings with
# (while (term_aux(s) == CID_SCON), term_pak(CID_SNIL, 0)): if the user's
# constructor wins that spelling, the runtime reads a string as that
# constructor and stops walking it early. The user constructor is used, so it
# reaches the constructor table. Before the runtime names were reserved this
# program printed the wrong thing in the C lane instead of being refused.
import Base

type S is Data:
  SCON{}

def tag(s: S) -> U32:
  match s:
    case SCON{}:
      0

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("hello")
    IO.print(U32.show(tag(SCON{})))

#|hello
#|0
