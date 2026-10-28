# String.eq and the four order tests are String.cmp's cases: a comparison
# reads both strings in place on the native lane and only releases them, so a
# shared or self-aliased input survives, NUL and full-U32 characters keep
# their unsigned order, and long equal strings never recurse. String.order
# stays the order-only walk; these checks compare the two answers.
import Base

def check(ok: Bool, what: String) -> IO(Unit):
  match ok:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, what)

def b2u(b: Bool) -> U32:
  match b:
    case False{}:
      0
    case True{}:
      1

def same_bool(want: Bool, got: Bool) -> Bool:
  match want got:
    case True{} True{}:
      True{}
    case False{} False{}:
      True{}
    case _ _:
      False{}

def rank(c: Cmp) -> U32:
  match c:
    case LT{}:
      0
    case EQ{}:
      1
    case GT{}:
      2

def order_rank(a: String, b: String) -> U32:
  rank(String.order(a, b))

def is_eq_rank(r: U32) -> Bool:
  U32.is_eq(r, 1)

def is_lt_rank(r: U32) -> Bool:
  U32.is_eq(r, 0)

def is_gt_rank(r: U32) -> Bool:
  U32.is_eq(r, 2)

def is_le_rank(r: U32) -> Bool:
  Bool.or(U32.is_eq(r, 0), U32.is_eq(r, 1))

def is_ge_rank(r: U32) -> Bool:
  Bool.or(U32.is_eq(r, 1), U32.is_eq(r, 2))

# The differential: every predicate must answer the order String.order walks.
def agrees(a: String, b: String) -> Bool:
  Bool.and(Bool.and(Bool.and(Bool.and(
    same_bool(String.eq(a, b), is_eq_rank(order_rank(a, b))),
    same_bool(String.is_lt(a, b), is_lt_rank(order_rank(a, b)))),
    same_bool(String.is_le(a, b), is_le_rank(order_rank(a, b)))),
    same_bool(String.is_gt(a, b), is_gt_rank(order_rank(a, b)))),
    same_bool(String.is_ge(a, b), is_ge_rank(order_rank(a, b))))

def expect(a: String, b: String, want: U32) -> IO(Unit):
  check(Bool.and(agrees(a, b), U32.is_eq(order_rank(a, b), want)),
    "string comparison disagrees with String.order")

# A shared string is compared with itself and with a literal, so both the
# argument copies and the caller's own reference must come back intact.
def self_ok(+s: String, w: String) -> Bool:
  Bool.and(String.eq(s, s), Bool.and(String.eq(s, w), String.is_le(s, s)))

def first(a: String, b: String) -> Bool:
  f = String.eq
  f(a, b)

def partial(a: String, b: String) -> Bool:
  f = String.eq(a)
  f(b)

def rep(n: Nat, +c: Char, acc: String) -> String:
  match n:
    case 0n:
      acc
    case 1n+p:
      rep(p, c, SCon{c, acc})

# Fifty thousand equal characters: the comparison must not keep a stack per
# character, and a differing character still decides the order.
def long_equal_ok() -> Bool:
  +a = { rep(50000n, Chr{97}, "") : String }
  +b = { rep(50000n, Chr{97}, "") : String }
  Bool.and(String.eq(a, b), String.is_le(a, b))

def long_order_ok() -> Bool:
  +b = { rep(50000n, Chr{97}, "") : String }
  +c = { rep(50000n, Chr{97}, "b") : String }
  +d = { rep(50000n, Chr{97}, "c") : String }
  Bool.and(String.is_lt(c, d), Bool.and(String.is_gt(c, b),
    String.is_ge(d, c)))

def cycle(n: Nat, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+more:
      +s = { String.append("ab", "cd") : String }
      ok = Bool.and(String.eq(s, "abcd"), Bool.and(String.is_lt(s, "abce"),
        Bool.and(String.eq(s, s), String.is_ge("abcd", s))))
      cycle(more, U32.add(acc, b2u(ok)))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- expect("", "", 1)
    Unit <- expect("", "a", 0)
    Unit <- expect("a", "", 2)
    Unit <- expect("a", "a", 1)
    Unit <- expect("a", "ab", 0)
    Unit <- expect("ab", "a", 2)
    Unit <- expect("ab", "ba", 0)
    Unit <- expect("B", "a", 0)
    Unit <- expect("é", "z", 2)
    Unit <- expect("\u{0}", "", 2)
    Unit <- expect("", "\u{0}", 0)
    Unit <- expect("\u{0}", "\u{0}", 1)
    Unit <- expect("\u{0}a", "\u{0}b", 0)
    Unit <- expect("a\u{0}", "\u{0}a", 2)
    Unit <- expect("\u{ffffffff}", "\u{0}", 2)
    Unit <- expect("\u{80000000}", "\u{7fffffff}", 2)
    Unit <- expect("\u{10000}", "\u{ffff}", 2)
    Unit <- expect("abc", "abd", 0)
    Unit <- expect("abc", "abcd", 0)
    Unit <- check(self_ok("shared", "shared"), "self comparison")
    Unit <- check(String.eq(String.append("sha", "red"), "shared"),
      "appended literal comparison")
    Unit <- check(Bool.and(first("first", "first"), Bool.not(first("a", "b"))),
      "first-class String.eq")
    Unit <- check(Bool.and(partial("parts", "parts"),
      Bool.not(partial("x", "y"))), "partial String.eq")
    Unit <- check(long_equal_ok(), "long equal strings")
    Unit <- check(long_order_ok(), "long differing strings")
    Unit <- check(U32.is_eq(cycle(1000n, 0), 1000), "comparison cycle")
    IO.print("String.eq and the order tests read both strings in place")

#|String.eq and the order tests read both strings in place
