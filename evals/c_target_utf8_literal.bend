# C target fixture: non-ASCII Text atom bytes. "λx" is three UTF-8 bytes; the
# C emitter must pass the byte count to bend_text, not the character count.
# The expected line is the printed text, independent of the emitted escape form.
import Base

def main() -> IO(Unit):
  IO.print("λx")

#|λx
