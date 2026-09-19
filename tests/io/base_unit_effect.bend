# io (io_base_unit_effect): a foreign .c lays Base constructors as well as its
# own module's -- EFFECTS.md writes term_pak(CID_UNIT, 0) for Unit -- so the
# include must redirect Base's spellings for it too. Alone it has no main:
# checked and interpreted only.
import Base

law unit.make:
  IO(Unit)

def unit.make():
  import "./base_unit_effect.c"
  import "./base_unit_effect.js"

#|All terms check, but 1 def relies on unsafe or foreign code:
#|- unit.make
