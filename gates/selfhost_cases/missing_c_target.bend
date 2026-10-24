# A foreign definition's .c target file is absent while its .js twin is
# present. The JS lane must compile and run; the C lane must report a real
# diagnostic naming the missing C target, not emit an undefined symbol or
# succeed. gates/selfhost.ts reads the #|!c line as a per-lane compile
# diagnostic.
import Base

law native.value:
  IO(U32)

def native.value():
  import "./missing_c_target.js"
  import "./missing_c_target.c"

law main:
  IO(U32)

def main():
  do IO<U32>:
    x : U32 <- native.value()
    u : Unit <- IO.print(U32.show(x))
    return 0

#|42
#|!c missing_c_target.c
