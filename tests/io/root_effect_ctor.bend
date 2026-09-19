# io (io_root_effect_ctor): a root module's effect .c spells its own module's
# constructors -- args.c writes CID_NIL and CID_CON for Base's List, print.c
# writes CID_UNIT -- and the root module shares its namespace with the program.
# A user constructor whose fold collides with one of those names must not take
# the spelling, or the include lays the wrong constructor. Declaring CON{} and
# NIL{} unused was enough to take CID_CON and CID_NIL and leave args.c with
# undeclared identifiers.
import Base

type A is Data:
  CON{}

type B is Data:
  NIL{}

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(Nat.show(List.length(&1, String, xs)))

#|0
