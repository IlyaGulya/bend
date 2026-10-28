# Native Map reads: a fully applied, owned Map.get/has/seek reads the trie in
# place. These checks answer what Base's source answers: a read returns the map
# with its content intact and usable again, a hit shares the stored value while
# the map keeps its own reference, a miss answers and releases the default, and
# seek returns the query and shares the candidate key with the leaf.
import Base

def b2u(b: Bool) -> U32:
  match b:
    case False{}:
      0
    case True{}:
      1

def none_str(x: Maybe<&2, String>) -> U32:
  match x:
    case None{}:
      1
    case Some{k}:
      0

def has_key(x: Maybe<&2, String>, w: String) -> U32:
  match x:
    case None{}:
      0
    case Some{k}:
      b2u(String.eq(k, w))

def any_key(x: Maybe<&2, String>) -> U32:
  match x:
    case None{}:
      0
    case Some{+k}:
      b2u(Bool.or(String.eq(k, "ab"),
        Bool.or(String.eq(k, "ba"), String.eq(k, "abc"))))

# A value whose storage is a node, not a word.
type Pair2 is Data:
  Pair2{x: U32, y: U32}

# A nested value whose boxed node holds boxed fields.
type Inner is Data:
  Inner{s: String, n: Nat}

type Outer is Data:
  Outer{s: String, i: Inner}

# U32 values: get, miss, has, has, seek and a set on the map each read hands
# back. Every read consumes what it is given, so each returned map keeps the
# content the source rebuilt, including a hit's shared value and a released
# default.
def seed_u32() -> Map<&2, U32>:
  Map.set(&2, U32, Map.set(&2, U32, Map.set(&2, U32, Map.new(&2, U32),
    "ab", 10), "ba", 20), "abc", 30)

def u32_after_set(hit: U32, miss: U32, here: Bool, absent: Bool, query: String,
  cand: Maybe<&2, String>, r: Map<&2, U32> & U32) -> U32:
  (m6, five) = r
  U32.add(U32.mul(hit, 100000),
    U32.add(U32.mul(miss, 10000),
      U32.add(U32.mul(b2u(here), 1000),
        U32.add(U32.mul(b2u(absent), 100),
          U32.add(U32.mul(b2u(String.eq(query, "ba")), 10),
            U32.add(has_key(cand, "ba"), five))))))

def u32_after_seek(hit: U32, miss: U32, here: Bool, absent: Bool,
  r: Map<&2, U32> & String & Maybe<&2, String>) -> U32:
  (m5, query, cand) = r
  u32_after_set(hit, miss, here, absent, query, cand,
    Map.get(U32, 0, Map.set(&2, U32, m5, "ab", 5), "ab"))

def u32_after_absent(hit: U32, miss: U32, here: Bool,
  r: Map<&2, U32> & Bool) -> U32:
  (m4, absent) = r
  u32_after_seek(hit, miss, here, absent, Map.seek(&2, U32, m4, "ba"))

def u32_after_has(hit: U32, miss: U32, r: Map<&2, U32> & Bool) -> U32:
  (m3, here) = r
  u32_after_absent(hit, miss, here, Map.has(&2, U32, m3, "zz"))

def u32_after_miss(hit: U32, r: Map<&2, U32> & U32) -> U32:
  (m2, miss) = r
  u32_after_has(hit, miss, Map.has(&2, U32, m2, "ba"))

def u32_after_get(r: Map<&2, U32> & U32) -> U32:
  (m1, hit) = r
  u32_after_miss(hit, Map.get(U32, 77, m1, "zz"))

def u32_get(m: Map<&2, U32>) -> U32:
  u32_after_get(Map.get(U32, 0, m, "ab"))

# An empty map and a one-leaf map: the default and the boolean answer without
# a descent, and seek still returns the query.
def empty_after_seek(v: U32, h: Bool,
  r: Map<&2, U32> & String & Maybe<&2, String>) -> U32:
  (m3, q, cand) = r
  U32.add(U32.mul(v, 100),
    U32.add(U32.mul(b2u(h), 10),
      U32.add(none_str(cand), b2u(String.eq(q, "k")))))

def empty_after_has(v: U32, r: Map<&2, U32> & Bool) -> U32:
  (m2, h) = r
  empty_after_seek(v, h, Map.seek(&2, U32, m2, "k"))

def empty_after_get(r: Map<&2, U32> & U32) -> U32:
  (m1, v) = r
  empty_after_has(v, Map.has(&2, U32, m1, "k"))

def empty_reads(m: Map<&2, U32>) -> U32:
  empty_after_get(Map.get(U32, 7, m, "k"))

def leaf_after_seek(v: U32, w: U32,
  r: Map<&2, U32> & String & Maybe<&2, String>) -> U32:
  (m3, q, cand) = r
  U32.add(U32.add(U32.mul(v, 10000), U32.mul(w, 1000)),
    U32.add(U32.mul(b2u(String.eq(q, "zz")), 100),
      U32.add(has_key(cand, "k"), 0)))

def leaf_after_miss(v: U32, r: Map<&2, U32> & U32) -> U32:
  (m2, w) = r
  leaf_after_seek(v, w, Map.seek(&2, U32, m2, "zz"))

def leaf_after_get(r: Map<&2, U32> & U32) -> U32:
  (m1, v) = r
  leaf_after_miss(v, Map.get(U32, 8, m1, "x"))

def leaf_get(m: Map<&2, U32>) -> U32:
  leaf_after_get(Map.get(U32, 8, m, "k"))

# A map's own copy: a readable map is Data, so two reads share one trie, and
# each answer's candidate is one of the map's own keys.
def fresh_seek(v: U32,
  r: Map<&2, U32> & String & Maybe<&2, String>) -> U32:
  (m2, q, cand) = r
  U32.add(U32.mul(v, 10), any_key(cand))

def fresh_after(r: Map<&2, U32> & U32) -> U32:
  (m1, v) = r
  fresh_seek(v, Map.seek(&2, U32, m1, "Ab"))

def u32_get_fresh(m: Map<&2, U32>) -> U32:
  fresh_after(Map.get(U32, 0, m, "ab"))

def shared_reads(+m: Map<&2, U32>) -> U32:
  U32.add(u32_get_fresh(m), u32_get_fresh(m))

# String values: the stored value is a box the map and the answer both hold.
def seed_str() -> Map<&2, String>:
  Map.set(&2, String, Map.set(&2, String, Map.new(&2, String), "s", "hello"),
    "t", "world")

def str_seek(v: String, d: String, w: String,
  r: Map<&2, String> & String & Maybe<&2, String>) -> U32:
  (m4, q, cand) = r
  U32.add(U32.mul(b2u(String.eq(v, "hello")), 10000),
    U32.add(U32.mul(b2u(String.eq(d, "fallback")), 1000),
      U32.add(U32.mul(b2u(String.eq(w, "world")), 100),
        U32.add(U32.mul(has_key(cand, "t"), 10),
          b2u(String.eq(q, "t"))))))

def str_more(v: String, d: String, r: Map<&2, String> & String) -> U32:
  (m3, w) = r
  str_seek(v, d, w, Map.seek(&2, String, m3, "t"))

def str_then(v: String, r: Map<&2, String> & String) -> U32:
  (m2, d) = r
  str_more(v, d, Map.get(String, "fallback", m2, "t"))

def str_after(r: Map<&2, String> & String) -> U32:
  (m1, v) = r
  str_then(v, Map.get(String, "fallback", m1, "zz"))

def str_reads(m: Map<&2, String>) -> U32:
  str_after(Map.get(String, "fallback", m, "s"))

# A reusable default is copied into a hit and released there while the caller's
# own string stays whole.
def release_hit(d: String, v: String, r: Map<&2, String> & String) -> U32:
  (m2, w) = r
  U32.add(U32.mul(b2u(String.eq(d, "fallback")), 100),
    U32.add(U32.mul(b2u(String.eq(v, "hello")), 10),
      b2u(String.eq(w, "fallback"))))

def release_after(+d: String, r: Map<&2, String> & String) -> U32:
  (m1, v) = r
  release_hit(d, v, Map.get(String, d, m1, "zz"))

def default_release(+d: String, m: Map<&2, String>) -> U32:
  release_after(d, Map.get(String, d, m, "s"))

# A node-shaped value type: the answer's words come from the boxed value.
def seed_pair() -> Map<&2, Pair2>:
  Map.set(&2, Pair2, Map.set(&2, Pair2, Map.new(&2, Pair2), "p", Pair2{3, 4}),
    "q", Pair2{5, 6})

def pair_digest(p: Pair2, ex: U32, ey: U32) -> U32:
  Pair2{x, y} = p
  U32.add(U32.mul(b2u(U32.is_eq(x, ex)), 10), b2u(U32.is_eq(y, ey)))

def pair_miss(v: Pair2, r: Map<&2, Pair2> & Pair2) -> U32:
  (m2, w) = r
  U32.add(U32.mul(pair_digest(v, 3, 4), 100), pair_digest(w, 8, 9))

def pair_after(r: Map<&2, Pair2> & Pair2) -> U32:
  (m1, v) = r
  pair_miss(v, Map.get(Pair2, Pair2{8, 9}, m1, "zz"))

def pair_reads(m: Map<&2, Pair2>) -> U32:
  pair_after(Map.get(Pair2, Pair2{0, 0}, m, "p"))

# A nested node value holding boxed fields: the hit's strings survive the
# default's release, and the map's own copy answers a second read.
def seed_outer() -> Map<&2, Outer>:
  Map.set(&2, Outer, Map.set(&2, Outer, Map.new(&2, Outer), "o",
    Outer{"aa", Inner{"bb", 12n}}), "p", Outer{"cc", Inner{"dd", 34n}})

def seed_outer_q() -> Map<&2, Outer>:
  Map.set(&2, Outer, Map.new(&2, Outer), "q", Outer{"gg", Inner{"hh", 2n}})

def inner_digest(p: Inner, es: String, en: Nat) -> U32:
  Inner{s, n} = p
  U32.add(U32.mul(b2u(String.eq(s, es)), 10), b2u(Nat.is_eq(n, en)))

def outer_digest(p: Outer, es: String, ins: String, en: Nat) -> U32:
  Outer{s, i} = p
  U32.add(U32.mul(b2u(String.eq(s, es)), 100), inner_digest(i, ins, en))

def outer_miss(v: Outer, r: Map<&2, Outer> & Outer) -> U32:
  (m2, w) = r
  U32.add(U32.mul(outer_digest(v, "aa", "bb", 12n), 10000),
    outer_digest(w, "dd", "ee", 56n))

def outer_after(r: Map<&2, Outer> & Outer) -> U32:
  (m1, v) = r
  outer_miss(v, Map.get(Outer, Outer{"dd", Inner{"ee", 56n}}, m1, "zz"))

def outer_reads(m: Map<&2, Outer>) -> U32:
  outer_after(Map.get(Outer, Outer{"dd", Inner{"ee", 56n}}, m, "o"))

# A reusable default of a nested boxed value: the hit releases its copy, the
# miss answers another copy, and the caller's own value stays whole while the
# returned map is consumed by the next read.
def god_miss(d: Outer, v: Outer, r: Map<&2, Outer> & Outer) -> U32:
  (m2, w) = r
  U32.add(U32.mul(outer_digest(v, "aa", "bb", 12n), 100),
    U32.add(U32.mul(outer_digest(w, "dd", "ee", 56n), 10),
      outer_digest(d, "dd", "ee", 56n)))

def god_after(+d: Outer, r: Map<&2, Outer> & Outer) -> U32:
  (m1, v) = r
  god_miss(d, v, Map.get(Outer, d, m1, "zz"))

def god_read(+d: Outer, m: Map<&2, Outer>) -> U32:
  god_after(d, Map.get(Outer, d, m, "o"))

# A generic consumer: the read answers the generic boxed value and the caller's
# instantiated type lays it out.
def gen_get(-V: Data, d: V, m: Map<&2, V>, k: String) -> Map<&2, V> & V:
  Map.get(V, d, m, k)

def generic_after(r0: Map<&2, U32> & U32, r1: Map<&2, U32> & U32) -> U32:
  (m0, a) = r0
  (m1, b) = r1
  U32.add(U32.mul(a, 100), b)

def generic_read(m: Map<&2, U32>) -> U32:
  generic_after(Map.get(U32, 0, m, "ab"),
    gen_get(U32, 0, Map.set(&2, U32, Map.new(&2, U32), "q", 44), "q"))

def generic_outer_after(r0: Map<&2, Outer> & Outer,
  r1: Map<&2, Outer> & Outer) -> U32:
  (m0, a) = r0
  (m1, b) = r1
  U32.add(U32.mul(outer_digest(a, "aa", "bb", 12n), 1000),
    outer_digest(b, "gg", "hh", 2n))

def generic_outer_read(m: Map<&2, Outer>) -> U32:
  generic_outer_after(Map.get(Outer, Outer{"dd", Inner{"ee", 56n}}, m, "o"),
    gen_get(Outer, Outer{"zz", Inner{"yy", 1n}}, seed_outer_q(), "q"))

# A first-class, partially applied read is a closure of the source definition:
# it must answer the same words without the in-place path.
def fc_end(v: U32, hb: Bool,
  r: Map<&2, U32> & String & Maybe<&2, String>) -> U32:
  (m3, q, cand) = r
  U32.add(U32.mul(v, 10000),
    U32.add(U32.mul(b2u(hb), 1000),
      U32.add(U32.mul(b2u(String.eq(q, "zz")), 100),
        U32.add(any_key(cand), 5))))

def fc_seek(v: U32, r: Map<&2, U32> & Bool, s: Map<&2, U32> -> String -> (Map<&2, U32> & String & Maybe<&2, String>)) -> U32:
  (m2, hb) = r
  fc_end(v, hb, s(m2, "zz"))

def fc_has(v: U32, m: Map<&2, U32>, h: Map<&2, U32> -> String -> (Map<&2, U32> & Bool)) -> U32:
  fc_seek(v, h(m, "ba"), Map.seek(&2, U32))

def fc_after(r: Map<&2, U32> & U32) -> U32:
  (m1, v) = r
  fc_has(v, m1, Map.has(&2, U32))

def fc_get(g: Map<&2, U32> -> String -> (Map<&2, U32> & U32), m: Map<&2, U32>) -> U32:
  fc_after(g(m, "ab"))

def first_class(m: Map<&2, U32>) -> U32:
  fc_get(Map.get(U32, 0), m)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(u32_get(seed_u32())))
    Unit <- IO.print(U32.show(empty_reads(Map.new(&2, U32))))
    Unit <- IO.print(U32.show(leaf_get(Map.set(&2, U32, Map.new(&2, U32),
      "k", 5))))
    Unit <- IO.print(U32.show(shared_reads(seed_u32())))
    Unit <- IO.print(U32.show(str_reads(seed_str())))
    Unit <- IO.print(U32.show(default_release("fallback", seed_str())))
    Unit <- IO.print(U32.show(pair_reads(seed_pair())))
    Unit <- IO.print(U32.show(outer_reads(seed_outer())))
    Unit <- IO.print(U32.show(god_read(Outer{"dd", Inner{"ee", 56n}},
      seed_outer())))
    Unit <- IO.print(U32.show(generic_read(seed_u32())))
    Unit <- IO.print(U32.show(generic_outer_read(seed_outer())))
    IO.print(U32.show(first_class(seed_u32())))
#|1771016
#|702
#|58101
#|202
#|11111
#|111
#|1111
#|1110111
#|12321
#|1044
#|111111
#|101106
