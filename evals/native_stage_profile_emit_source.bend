# Source input for the diagnostic Emitter probe: a closed arithmetic/closure
# program with no foreign imports, checked through the production pipeline.
import Base

def plus3(x: U32) -> U32:
  U32.add(x, 3)

def apply_once(f: U32 -> U32, x: U32) -> U32:
  f(x)

def main() -> U32:
  apply_once(plus3, 4)
