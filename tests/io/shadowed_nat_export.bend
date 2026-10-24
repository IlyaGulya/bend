# io (io_shadowed_nat_export): a module that declares its OWN type literally
# named Nat is NOT the host Nat: its canonical key ("shadow_nat_type.Nat") has
# authoritative native None. Its export parameter is an ordinary tagged value,
# so a raw host number crosses unconverted and no Nat bound error is raised,
# while the genuine shadow ADT value still matches.
import Base

def ShadowNat.host_export() -> IO(U32):
  import "./shadowed_nat_export.js"

def main() -> IO(Unit):
  do IO<Unit>:
    value : U32 <- ShadowNat.host_export()
    IO.print(U32.show(value))

#|0
