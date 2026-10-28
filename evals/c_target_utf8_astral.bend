# C target fixture: a non-BMP literal (U+1D11E) is four UTF-8 bytes. The C
# emitter must pass the byte count to bend_text; the expected line is the
# printed text, not the escape spelling.
import Base

def main() -> IO(Unit):
  IO.print("𝄞")

#|𝄞
