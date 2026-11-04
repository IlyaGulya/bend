import Base

def count(n: Nat) -> Nat:
  match n:
    case 0n: 0n
    case 1n+p: Nat.add(count(p), 1n)

def host.extra(f: Nat -> Nat) -> IO(Nat):
  import "./extra.js"

def main() -> IO(Unit):
  do IO<Unit>:
    value : Nat <- host.extra(n => count(n))
    IO.print(Nat.show(value))

#|20000
