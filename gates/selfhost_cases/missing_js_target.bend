# A foreign definition's .js target file is absent while its C twin is
# present. The C lane must compile and run; the JS lane must report a real
# diagnostic naming the missing JS target, not call an undefined module.
import Base

law native.value:
  IO(U32)

def native.value():
  import "./missing_js_target.c"
  import "./missing_js_target.js"

law main:
  IO(U32)

def main():
  do IO<U32>:
    x : U32 <- native.value()
    u : Unit <- IO.print(U32.show(x))
    return 0

#|42
#|!js missing_js_target.js
