# Map.find is the read-only twin of Map.get: the map and the query are
# consumed, a hit shares the value the map held, and a miss answers None.
# These checks answer what Base's portable source answers on every lane:
# arbitrary and backward MNode positions, NUL and full-U32 keys, unique and
# shared maps, boxed and nested values, generic wrappers, first-class and
# partial calls, and a borrowed map that two lookups read.
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

def u32_of(x: Maybe<&2, U32>, d: U32) -> U32:
  match x:
    case None{}:
      d
    case Some{v}:
      v

def none_u32(x: Maybe<&2, U32>) -> Bool:
  Maybe.is_none(&2, U32, x)

def hit_u32(x: Maybe<&2, U32>, +want: U32) -> Bool:
  U32.is_eq(u32_of(x, U32.add(want, 1)), want)

def str_of(x: Maybe<&2, String>, d: String) -> String:
  match x:
    case None{}:
      d
    case Some{v}:
      v

def same_str(x: Maybe<&2, String>, +want: String) -> Bool:
  String.eq(str_of(x, String.append("miss:", want)), want)

# Value shapes: a packed word, an inline node and a nested node of boxes.
type Flag is Data:
  Flag{v: U32}

type Pair2 is Data:
  Pair2{x: U32, y: U32}

type Inner is Data:
  Inner{s: String, n: Nat}

type Outer is Data:
  Outer{s: String, i: Inner}

def flag_of(x: Maybe<&2, Flag>, d: Flag) -> Flag:
  match x:
    case None{}:
      d
    case Some{v}:
      v

def flag_val(p: Flag) -> U32:
  Flag{v} = p
  v

def pair_digest(p: Pair2, ex: U32, ey: U32) -> U32:
  Pair2{x, y} = p
  U32.add(U32.mul(b2u(U32.is_eq(x, ex)), 10), b2u(U32.is_eq(y, ey)))

def pair_of(x: Maybe<&2, Pair2>, d: Pair2) -> Pair2:
  match x:
    case None{}:
      d
    case Some{v}:
      v

def inner_digest(p: Inner, es: String, en: Nat) -> U32:
  Inner{s, n} = p
  U32.add(U32.mul(b2u(String.eq(s, es)), 10), b2u(Nat.is_eq(n, en)))

def outer_digest(p: Outer, es: String, ins: String, en: Nat) -> U32:
  Outer{s, i} = p
  U32.add(U32.mul(b2u(String.eq(s, es)), 100), inner_digest(i, ins, en))

def outer_of(x: Maybe<&2, Outer>, d: Outer) -> Outer:
  match x:
    case None{}:
      d
    case Some{v}:
      v

# A generic consumer: the read answers the generic boxed value and the
# caller's instantiated type lays it out.
def gen_find(-V: Data, m: Map<&2, V>, k: String) -> Maybe<&2, V>:
  Map.find(V, m, k)

def gen_u32(m: Map<&2, U32>, k: String, want: U32) -> Bool:
  hit_u32(gen_find(U32, m, k), want)

def gen_str(m: Map<&2, String>, k: String, want: String) -> Bool:
  same_str(gen_find(String, m, k), want)

def gen_outer(m: Map<&2, Outer>, k: String, es: String, ins: String,
  en: Nat) -> Bool:
  U32.is_eq(outer_digest(outer_of(gen_find(Outer, m, k), Outer{"", Inner{"",
    0n}}), es, ins, en), 111)

# A first-class lookup and a partial application are closures of the source
# definition: they must answer the same words without the in-place path.
def fc_find(g: @+map: Map<&2, U32> -> @+key: String -> Maybe<&2, U32>,
  m: Map<&2, U32>, k: String, want: U32) -> Bool:
  hit_u32(g(m, k), want)

def part_find(f: @+key: String -> Maybe<&2, U32>, k: String, want: U32) -> Bool:
  hit_u32(f(k), want)

# A borrowed map read twice: the callee never owns the trie, so both calls
# must answer and the caller's map must survive them.
def probe(map: Map<&2, U32>, key: String) -> U32:
  u32_of(Map.find(U32, map, key), 99)

def probe_twice(+map: Map<&2, U32>, +key: String) -> U32:
  U32.add(U32.mul(probe(map, key), 10), probe(map, key))

# A shared map keeps its own copy while a lookup consumes another.
def shared_read(+m: Map<&2, U32>) -> U32:
  U32.add(U32.mul(u32_of(Map.find(U32, m, "ab"), 0), 100),
    U32.add(U32.mul(b2u(Pair.snd(Map<&2, U32>, Bool,
      Map.has(&2, U32, m, "ab"))), 10),
      u32_of(Map.find(U32, m, "zz"), 7)))

def seed_u32() -> Map<&2, U32>:
  Map.set(&2, U32, Map.set(&2, U32, Map.set(&2, U32, Map.new(&2, U32),
    "ab", 5), "ba", 6), "abc", 7)

def first_class() -> Bool:
  Bool.and(fc_find(Map.find(U32), seed_u32(), "ab", 5),
    Bool.and(Bool.not(fc_find(Map.find(U32), seed_u32(), "zz", 43)),
      part_find(Map.find(U32, seed_u32()), "ba", 6)))

def seed_str() -> Map<&2, String>:
  Map.set(&2, String, Map.set(&2, String, Map.new(&2, String), "s", "hello"),
    "t", "world")

def seed_outer() -> Map<&2, Outer>:
  Map.set(&2, Outer, Map.set(&2, Outer, Map.new(&2, Outer), "o",
    Outer{"aa", Inner{"bb", 12n}}), "p", Outer{"cc", Inner{"dd", 34n}})

def seed_pair() -> Map<&2, Pair2>:
  Map.set(&2, Pair2, Map.set(&2, Pair2, Map.new(&2, Pair2), "p", Pair2{3, 4}),
    "q", Pair2{5, 6})

def full_keys() -> Map<&2, U32>:
  Map.set(&2, U32, Map.set(&2, U32, Map.new(&2, U32), "\u{ffffffff}", 31),
    "\u{80000000}", 32)

def prefix_keys() -> Map<&2, U32>:
  Map.set(&2, U32, Map.set(&2, U32, Map.set(&2, U32, Map.new(&2, U32),
    "a", 1), "ab", 2), "abc", 3)

# One lookup per turn over a rebuilt trie, hit and miss, so a lost or
# over-released reference would surface as a refcount or heap failure.
def cycle(n: Nat, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+more:
      +m = Map.set(&2, U32, Map.set(&2, U32, Map.new(&2, U32), "a", 1), "b", 2)
      here = U32.add(u32_of(Map.find(U32, m, "b"), 0),
        u32_of(Map.find(U32, Map.set(&2, U32, m, "c", 3), "c"), 0))
      miss = u32_of(Map.find(U32, MNode{0n, MLeaf{"a", 1}, MLeaf{"b", 2}}, "z"),
        4)
      cycle(more, U32.add(acc, U32.add(here, miss)))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- check(none_u32(Map.find(U32, MTip{}, "k")), "Tip lookup is None")
    Unit <- check(hit_u32(Map.find(U32, MLeaf{"k", 5}, "k"), 5), "leaf hit")
    Unit <- check(none_u32(Map.find(U32, MLeaf{"k", 5}, "x")), "leaf miss")
    Unit <- check(hit_u32(Map.find(U32, MNode{0n, MLeaf{"cd", 2},
      MLeaf{"ab", 1}}, "ab"), 1), "first character bit")
    Unit <- check(hit_u32(Map.find(U32, MNode{Nat.add(Nat.mul(4294967295n,
      65536n), 65535n), MLeaf{"h", 1}, MLeaf{"h", 2}}, "h"), 1), "huge position")
    Unit <- check(hit_u32(Map.find(U32, MNode{32n, MLeaf{"ab", 2},
      MLeaf{"ab", 1}}, "ab"), 1), "backward character position")
    Unit <- check(hit_u32(Map.find(U32, MNode{1n, MLeaf{"ab", 8}, MTip{}},
      "ab"), 8), "backward bit position")
    Unit <- check(hit_u32(Map.find(U32, MNode{132n, MNode{32n, MTip{},
      MLeaf{"ab", 9}}, MTip{}}, "ab"), 9), "past-end reset")
    Unit <- check(hit_u32(Map.find(U32, MNode{0n, MLeaf{"", 5},
      MLeaf{"\u{0}A", 10}}, ""), 5), "NUL query reads its own leaf")
    Unit <- check(hit_u32(Map.find(U32, MNode{0n, MLeaf{"", 5},
      MLeaf{"\u{0}A", 10}}, "\u{0}A"), 10), "NUL is a character")
    Unit <- check(hit_u32(Map.find(U32, MNode{33n, MTip{}, MNode{32n,
      MLeaf{"🙂a", 12}, MTip{}}}, "🙂a"), 12), "supplementary character")
    Unit <- check(hit_u32(Map.find(U32, prefix_keys(), "a"), 1), "prefix a")
    Unit <- check(hit_u32(Map.find(U32, prefix_keys(), "ab"), 2), "prefix ab")
    Unit <- check(hit_u32(Map.find(U32, prefix_keys(), "abc"), 3), "prefix abc")
    Unit <- check(none_u32(Map.find(U32, prefix_keys(), "abcd")),
      "longer than every prefix")
    Unit <- check(hit_u32(Map.find(U32, full_keys(), "\u{ffffffff}"), 31),
      "largest U32 key")
    Unit <- check(hit_u32(Map.find(U32, full_keys(), "\u{80000000}"), 32),
      "sign-bit U32 key")
    Unit <- check(same_str(Map.find(String, seed_str(), "s"), "hello"),
      "string value survives the consumed map")
    Unit <- check(Bool.not(same_str(Map.find(String, seed_str(), "zz"),
      "miss:zz")), "string miss is None")
    Unit <- check(U32.is_eq(pair_digest(pair_of(Map.find(Pair2, seed_pair(),
      "p"), Pair2{0, 0}), 3, 4), 11), "node value")
    Unit <- check(U32.is_eq(outer_digest(outer_of(Map.find(Outer, seed_outer(),
      "o"), Outer{"", Inner{"", 0n}}), "aa", "bb", 12n), 111),
      "nested boxed value")
    Unit <- check(U32.is_eq(flag_val(flag_of(Map.find(Flag, MLeaf{"k", Flag{3}},
      "k"), Flag{0})), 3), "packed value")
    Unit <- check(gen_u32(seed_u32(), "ba", 6), "generic U32 lookup")
    Unit <- check(gen_str(seed_str(), "t", "world"), "generic String lookup")
    Unit <- check(gen_outer(seed_outer(), "p", "cc", "dd", 34n),
      "generic nested lookup")
    Unit <- check(first_class(), "first-class and partial lookup")
    Unit <- check(U32.is_eq(probe_twice(seed_u32(), "ab"), 55),
      "borrowed map read twice")
    Unit <- check(U32.is_eq(shared_read(seed_u32()), 517), "shared map survives")
    Unit <- check(hit_u32(Map.find(U32, seed_u32(), "abc"), 7),
      "canonical trie hit")
    Unit <- check(U32.is_eq(Pair.snd(Map<&2, U32>, U32,
      Map.get(U32, 0, seed_u32(), "ba")), 6), "Map.get still answers")
    Unit <- check(U32.is_eq(cycle(2000n, 0), 18000), "lookup cycle")
    IO.print("map find reads the trie in place")

#|map find reads the trie in place
