# Source-authored normal-return C/JS callback witness; execution is pending.
# Owner is Type, so each suspended continuation retains an affine value.
import Base

type Owner is Type:
  Owner{value: U32}

def read_owner(owner: Owner) -> U32:
  match owner:
    case Owner{value}: value

# Non-tail recursion keeps each Owner live while the nested call runs.
def nested(n: Nat, owner: Owner) -> U32:
  match n:
    case 0n: read_owner(owner)
    case 1n+p:
      value = nested(p, Owner{1})
      U32.add(read_owner(owner), value)

def Host.reenter(step: U32 -> U32, value: U32) -> IO(U32):
  import "./reentry.c"
  import "./reentry.js"

def run(n: Nat, owner: Owner) -> IO(U32):
  do IO<U32>:
    value : U32 <- Host.reenter(x => nested(n, Owner{x}), 7)
    return U32.add(read_owner(owner), value)

def main() -> IO(Unit):
  do IO<Unit>:
    a : U32 <- run(63n, Owner{1000})
    Unit <- IO.print(U32.show(a))
    b : U32 <- run(64n, Owner{2000})
    Unit <- IO.print(U32.show(b))
    c : U32 <- run(65n, Owner{3000})
    IO.print(U32.show(c))

#|callback-before
#|nested-call:70
#|callback-after
#|1070
#|callback-before
#|nested-call:71
#|callback-after
#|2071
#|callback-before
#|nested-call:72
#|callback-after
#|3072
