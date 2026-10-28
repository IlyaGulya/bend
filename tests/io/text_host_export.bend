# A Char or a String exported to a host is text in both directions: an argument
# is read with str_in and a completed result is published with str_out, so a
# lone surrogate a host hands in becomes U+FFFD and a Char that is no Unicode
# scalar leaves as U+FFFD. Partial application keeps the same per-parameter
# conversions, and a Nat parameter or result is untouched.
import Base

def Text.host_export() -> IO(U32):
  import "./text_host_export.js"

def main() -> IO(Unit):
  do IO<Unit>:
    value : U32 <- Text.host_export()
    IO.print(U32.show(value))

#|0
