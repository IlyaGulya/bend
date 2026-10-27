# Borrowed primitives must not retain the owned arguments of a value call or
# a freshly allocated literal. Both paths use the existing 32-page frontier
# invariant; values and aliases must remain correct while references are freed.
import Base

def length_value(s: String) -> Nat:
  f = String.length
  f(s)

def equal_value(a: String, b: String) -> Bool:
  f = String.eq
  f(a, b)

def length_fresh(s: String) -> Nat:
  Nat.add(String.length("ab"), Bool.pick(Nat, String.eq("a", "b"), 9000n, 0n))

def append_value(+head: String, +tail: String) -> String:
  f = String.append
  f(head, tail)

def append_projected(pair: String & String) -> String:
  match pair:
    case Tuple{+head, tail}: String.append(head, head)

def value_cycle(n: Nat, acc: U32) -> U32:
  match n:
    case 0n: acc
    case 1n+more:
      +s = { "ab" : String }
      +joined = append_value(s, s)
      size = U32.from_nat(length_value(s))
      ok = Bool.and(String.eq(joined, "abab"), Bool.and(equal_value(s, s), String.eq(s, "ab")))
      error = Bool.pick(U32, ok, 0, 9000)
      value_cycle(more, U32.add(acc, U32.add(size, error)))

def fresh_cycle(n: Nat, acc: U32) -> U32:
  match n:
    case 0n: acc
    case 1n+more:
      +s = { "ab" : String }
      size = U32.from_nat(String.length(String.append("a", s)))
      error = Bool.pick(U32, U32.is_eq(size, 3), 0, 9000)
      fresh_cycle(more, U32.add(acc, U32.add(U32.from_nat(length_fresh(s)), error)))

def heap.check(value: U32, expected: U32, before: U32) -> IO(U32):
  import "./native_string_borrow.c"
  import "./native_string_borrow.js"

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(Nat.show(length_value("ab")))
    Unit <- IO.print(append_value("", "z"))
    Unit <- IO.print(append_projected(("ab", "discard")))
    +before : U32 <- heap.check(value_cycle(1000n, 0), 2000, 0)
    after : U32 <- heap.check(value_cycle(20000n, 0), 40000, before)
    +fresh_before : U32 <- heap.check(fresh_cycle(1000n, 0), 2000, 0)
    fresh_after : U32 <- heap.check(fresh_cycle(20000n, 0), 40000, fresh_before)
    IO.print("bounded")

#|2
#|z
#|abab
#|bounded
