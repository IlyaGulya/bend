# Foreign C spells an imported constructor locally (CID_OFF).
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
