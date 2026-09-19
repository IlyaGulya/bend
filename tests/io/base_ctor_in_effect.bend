# io (io_base_ctor_in_effect): the effect above lays Base Unit through CID_UNIT,
# and the program declares its own UNIT{} beside it. The effect's include must
# redirect CID_UNIT to the macro Base's Unit was allocated, not to the one the
# user's constructor took: with the user's UNIT{} never laid, the include used
# to name an undefined CID_UNIT, and with it laid, the effect would hand back
# the user's constructor.
import Base
import ./base_unit_effect.bend as M

type X is Data:
  UNIT{}

def is_unit(u: Unit) -> String:
  match u:
    case Unit{}:
      "unit"

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    u : Unit <- M.unit.make()
    IO.print(is_unit(u))

#|unit
