# io (io_nat_alias_export): a closed type-function alias of Nat crosses the
# export seam as a Nat. The shared normalization pass reduces the alias to the
# Nat family before js_lib sees it, so the host guard still rejects a negative,
# fractional, BigInt or too-large argument and a good one still runs.
import Base

def NatAlias.host_export() -> IO(U32):
  import "./nat_alias_export.js"

def main() -> IO(Unit):
  do IO<Unit>:
    value : U32 <- NatAlias.host_export()
    IO.print(U32.show(value))

#|0
