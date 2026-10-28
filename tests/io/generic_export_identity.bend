# io (io_generic_export_identity): a generic export parameter is a real
# abstract domain. It crosses the host seam unchanged, with no guessed Nat
# guard and no compile failure, so the identity function returns negative,
# fractional and string arguments as they came.
import Base

def Generic.host_export() -> IO(U32):
  import "./generic_export_identity.js"

def main() -> IO(Unit):
  do IO<Unit>:
    value : U32 <- Generic.host_export()
    IO.print(U32.show(value))

#|0
