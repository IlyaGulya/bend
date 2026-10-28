# A non-tail call hands its value back to a continuation of the private frame
# machine, not to a JavaScript return address: a constructor field, a primitive
# operand, a first-class application and a bound scrutinee all resume there.
# The depths here stay inside the reference evaluator; the stack boundary itself
# is witnessed by evals/repro_js_non_tail_stack.bend.
import Base

def chars.go(n: Nat, acc: List<&2, Char>) -> List<&2, Char>:
  match n:
    case 0n:
      acc
    case 1n+rest:
      chars.go(rest, 'x' <> acc)

# String.from_list builds its tail as an SCon field, so its recursive call is an
# argument of a constructor and never a tail call.
def built(n: Nat) -> Nat:
  String.length(String.from_list(chars.go(n, Nil{})))

# The recursive value is consumed by Nat.add, so this call is not a tail call.
def depth(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+rest:
      Nat.add(depth(rest), 1n)

# A first-class function applied to a non-tail call's result. Each level gets
# a fresh affine increment function; the caller's `f` is consumed exactly once.
def applied(n: Nat, f: Nat -> Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+rest:
      Nat.add(f(applied(rest, x => Nat.add(x, 1n))), 1n)

# A non-tail result is passed on instead of matched in place: the kernel matches
# a parameter or a bound field only, so depth(rest) resumes as the argument of a
# call whose callee matches that parameter. nest.after names no def defined below
# it, so every callee is filled before its caller.
def nest.after(probe: Nat) -> Nat:
  match probe:
    case 0n:
      1n
    case 1n+p:
      Nat.add(p, 1n)

def nested(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+rest:
      nest.after(depth(rest))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(Nat.show(built(200n)))
    Unit <- IO.print(Nat.show(depth(200n)))
    Unit <- IO.print(Nat.show(applied(200n, x => Nat.add(x, 1n))))
    Unit <- IO.print(Nat.show(nested(5n)))
    IO.pure(Unit, Unit{})

#|200
#|200
#|400
#|4
