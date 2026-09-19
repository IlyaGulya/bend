# io (io_imported_ctor_fold): an imported module's effect .c spells its own
# constructors, and the compiler redirects those spellings to the macros it
# allocated for them. The redirect must name what the C wrote (CID_OFF for
# `Off`), not whatever macro the same fold was allocated to elsewhere: a
# top-level `OFF` next to the imported `Off` used to take the spelling, and
# the include then redirected `CID_OFF_2` -- a name the C never writes -- so
# CID_OFF stayed an undeclared identifier.
import Base
import ./marshal_imported_nullary_type.bend as M

type A is Data:
  OFF{}

type B is Data:
  Off{}

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    a : M.Tag <- M.tag.off()
    u : Unit <- IO.print(M.tag.name(a))
    b : M.Tag <- M.tag.on()
    IO.print(M.tag.name(b))

#|off
#|on
