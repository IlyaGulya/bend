# regression witness: two defs whose names differ only by a dot against an
# underscore -- `Thing.field` and `thing_field` -- both compile to the C macro
# FID_THING_FIELD, and the emitter refused the program outright ("two names
# mangle to FID_THING_FIELD"). The names are legal Bend and mean different
# things, so a program that uses both could not be built for the C lane at
# all. Both defs are recursive here on purpose: a flat def is inlined into its
# caller and never gets a segment, so only a non-flat one reaches the table.
# The fold from a name to its macro stays what it was (`.` becomes `_`, letters
# go up); what changed is that a name folding onto one already taken gets a
# numbered suffix, so the pair above becomes FID_THING_FIELD and
# FID_THING_FIELD_2. The two defs answer differently (n and n + 1) so a wrong
# merge of the two would print 0.
import Base

type Thing is Data:
  Thing{field: U32}

def Thing.field(+t: Thing, n: Nat) -> U32:
  match n:
    case 0n:
      0
    case 1n+p:
      (Thing.field(t, p) + 1 : U32)

def thing_field(t: Thing, n: Nat) -> U32:
  match n:
    case 0n:
      1
    case 1n+p:
      (thing_field(t, p) + 1 : U32)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    +n : Nat <- IO.pure(Nat, List.length(&1, String, args))
    IO.print(U32.show((Thing.field(Thing{7}, n) + thing_field(Thing{7}, n) : U32)))

#|1
