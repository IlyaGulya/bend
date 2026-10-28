import Base

# Resource-boundary witness, not a full compiler acceptance fixture: every line
# needs a non-tail call depth far past a default JavaScript machine stack, and
# none of them is a String.from_list special case.
#
#   built   60000 codepoints through SCon constructor fields (the shape that
#           failed first while parsing the whole compiler root)
#   depth   20000 non-tail Nat returns consumed by Nat.add
#   applied 20000 non-tail returns through a first-class application; f adds one
#           and each level also adds one, so the answer is twice the depth
def chars.go(n: Nat, acc: List<&2, Char>) -> List<&2, Char>:
  match n:
    case 0n:
      acc
    case 1n+rest:
      chars.go(rest, 'x' <> acc)

def built(n: Nat) -> Nat:
  String.length(String.from_list(chars.go(n, Nil{})))

def depth(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+rest:
      Nat.add(depth(rest), 1n)

def applied(n: Nat, f: Nat -> Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+rest:
      Nat.add(f(applied(rest, x => Nat.add(x, 1n))), 1n)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(Nat.show(built(60000n)))
    Unit <- IO.print(Nat.show(depth(20000n)))
    Unit <- IO.print(Nat.show(applied(20000n, x => Nat.add(x, 1n))))
    IO.pure(Unit, Unit{})

#|60000
#|20000
#|40000
