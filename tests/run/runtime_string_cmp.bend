# String.cmp returns both consumed strings and the same lexicographic Cmp.
# Covers NUL, full-U32 character codes, prefixes, direct, partial, first-class
# and shared-alias calls. The C helper only reads, so both inputs come back.
import Base

def check(ok: Bool, what: String) -> IO(Unit):
  match ok:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, what)

def rank(c: Cmp) -> U32:
  match c:
    case LT{}:
      0
    case EQ{}:
      1
    case GT{}:
      2

# The pair is a parameter here, so the destructuring match scrutinizes a
# parameter, and the comparison result is passed as a computed last argument.
def pair_ok(ra: String, rb: String, order: U32, r: (String & String) & Cmp) -> U32:
  ((xa, xb), got) = r
  Bool.pick(U32, Bool.and(String.eq(ra, xa),
    Bool.and(String.eq(rb, xb), U32.is_eq(order, rank(got)))), 0, 1)

def expect(a: String, b: String, ra: String, rb: String, order: U32) -> IO(Unit):
  check(U32.is_eq(0, pair_ok(ra, rb, order, String.cmp(a, b))),
    "String.cmp returned inputs or order")

def first(a: String, b: String, ra: String, rb: String, order: U32) -> IO(Unit):
  f = String.cmp
  check(U32.is_eq(0, pair_ok(ra, rb, order, f(a, b))),
    "first-class String.cmp returned inputs or order")

def partial(a: String, b: String, ra: String, rb: String, order: U32) -> IO(Unit):
  f = String.cmp(a)
  check(U32.is_eq(0, pair_ok(ra, rb, order, f(b))),
    "partial String.cmp returned inputs or order")

def shared(+s: String, +ra: String, order: U32) -> IO(Unit):
  check(U32.is_eq(0, pair_ok(ra, ra, order, String.cmp(s, s))),
    "aliased String.cmp returned inputs or order")

# Fresh shared strings per turn: the head cell is kept for the second use, and
# the returned strings must stay intact while references are released.
def cycle(n: Nat, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+more:
      +base = { "shared-prefix" : String }
      +long = { String.append(base, "tail") : String }
      ok = pair_ok("shared-prefixtail", "shared-prefix", 2, String.cmp(long, base))
      +self = { String.append("self-", "alias") : String }
      ok2 = pair_ok("self-alias", "self-alias", 1, String.cmp(self, self))
      cycle(more, U32.add(acc, U32.add(ok, ok2)))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- expect("", "", "", "", 1)
    Unit <- expect("", "a", "", "a", 0)
    Unit <- expect("a", "", "a", "", 2)
    Unit <- expect("a", "a", "a", "a", 1)
    Unit <- expect("a", "ab", "a", "ab", 0)
    Unit <- expect("ab", "a", "ab", "a", 2)
    Unit <- expect("ab", "ba", "ab", "ba", 0)
    Unit <- expect("b", "a", "b", "a", 2)
    Unit <- expect("\u{0}", "", "\u{0}", "", 2)
    Unit <- expect("", "\u{0}", "", "\u{0}", 0)
    Unit <- expect("\u{0}", "\u{0}", "\u{0}", "\u{0}", 1)
    Unit <- expect("\u{0}a", "\u{0}b", "\u{0}a", "\u{0}b", 0)
    Unit <- expect("a\u{0}", "\u{0}a", "a\u{0}", "\u{0}a", 2)
    Unit <- expect("\u{ffffffff}", "\u{0}", "\u{ffffffff}", "\u{0}", 2)
    Unit <- expect("\u{80000000}", "\u{7fffffff}", "\u{80000000}",
      "\u{7fffffff}", 2)
    Unit <- expect("\u{10000}", "\u{ffff}", "\u{10000}", "\u{ffff}", 2)
    Unit <- expect("\u{ffffffff}", "\u{ffffffff}", "\u{ffffffff}",
      "\u{ffffffff}", 1)
    Unit <- first("first", "firstly", "first", "firstly", 0)
    Unit <- partial("part", "parts", "part", "parts", 0)
    Unit <- shared("alias", "alias", 1)
    check(U32.is_eq(cycle(1000n, 0), 0), "shared comparison cycle")
    IO.print("String.cmp returns both inputs and the order")

#|String.cmp returns both inputs and the order
