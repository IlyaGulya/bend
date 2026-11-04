# Extra JavaScript callback arguments must not override the private stack budget.
# The host supplies a negative third argument; the callback must ignore it.
# Tail recursion keeps this focused on host arity, not non-tail backend limits.
import Base

def count.go(n: Nat, acc: Nat) -> Nat:
  match n:
    case 0n: acc
    case 1n+p: count.go(p, Nat.add(acc, 1n))

def count(n: Nat) -> Nat:
  count.go(n, 0n)

def host.extra(f: Nat -> Nat) -> IO(Nat):
  import "./js_closure_host_depth.js"

def main() -> IO(Unit):
  do IO<Unit>:
    value : Nat <- host.extra(n => count(n))
    IO.print(Nat.show(value))

#|20000
