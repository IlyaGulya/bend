# Native Map reads on maps that are never copied: the whole program hands each
# trie to one reader, so no map node is shared and every leaf field is held
# plainly. A hit still shares the stored value with the answer, and seek still
# shares the candidate key, so the read must leave the leaf holding its own
# counted copy while the answer holds another, and the map must keep answering
# afterwards.
import Base

def b2u(b: Bool) -> U32:
  match b:
    case False{}:
      0
    case True{}:
      1

def has_key(x: Maybe<&2, String>, w: String) -> U32:
  match x:
    case None{}:
      0
    case Some{k}:
      b2u(String.eq(k, w))

type Inner is Data:
  Inner{s: String, n: Nat}

type Outer is Data:
  Outer{s: String, i: Inner}

def inner_digest(p: Inner, es: String, en: Nat) -> U32:
  Inner{s, n} = p
  U32.add(U32.mul(b2u(String.eq(s, es)), 10), b2u(Nat.is_eq(n, en)))

def outer_digest(p: Outer, es: String, ins: String, en: Nat) -> U32:
  Outer{s, i} = p
  U32.add(U32.mul(b2u(String.eq(s, es)), 100), inner_digest(i, ins, en))

# String values: two hits and a seek share three words out of two leaves that
# are never copied, and a set on the returned map then reads a fourth.
def str_map() -> Map<&2, String>:
  Map.set(&2, String, Map.set(&2, String, Map.new(&2, String), "k", "alpha"),
    "l", "beta")

def str_end(v: String, w: String, q: String, cand: Maybe<&2, String>,
  r: Map<&2, String> & String) -> U32:
  (m4, x) = r
  U32.add(U32.mul(b2u(String.eq(v, "alpha")), 10000),
    U32.add(U32.mul(b2u(String.eq(w, "beta")), 1000),
      U32.add(U32.mul(has_key(cand, "k"), 100),
        U32.add(U32.mul(b2u(String.eq(q, "k")), 10),
          b2u(String.eq(x, "gamma"))))))

def str_seek(v: String, w: String,
  r: Map<&2, String> & String & Maybe<&2, String>) -> U32:
  (m3, q, cand) = r
  str_end(v, w, q, cand,
    Map.get(String, String.append("z", "z"),
      Map.set(&2, String, m3, "k", "gamma"), "k"))

def str_next(v: String, r: Map<&2, String> & String) -> U32:
  (m2, w) = r
  str_seek(v, w, Map.seek(&2, String, m2, "k"))

def str_after(r: Map<&2, String> & String) -> U32:
  (m1, v) = r
  str_next(v, Map.get(String, String.append("y", "y"), m1, "l"))

def str_reads(m: Map<&2, String>) -> U32:
  str_after(Map.get(String, "zz", m, "k"))

# A boxed value the caller also holds: storing a copy must leave the caller's
# own string whole, and the answer's copy must equal it.
def alias_get(s: String, r: Map<&2, String> & String) -> U32:
  (m2, v) = r
  U32.add(U32.mul(b2u(String.eq(s, "shared")), 10),
    b2u(String.eq(v, "shared")))

def alias_after(s: String, m: Map<&2, String>) -> U32:
  alias_get(s, Map.get(String, "zz", m, "k"))

def alias_value(+s: String) -> U32:
  alias_after(s, Map.set(&2, String, Map.new(&2, String), "k", s))

# Node-shaped values: both answers' words come from leaves that are never
# copied, and the default is released on the hit.
def outer_map() -> Map<&2, Outer>:
  Map.set(&2, Outer, Map.set(&2, Outer, Map.new(&2, Outer), "k",
    Outer{"aa", Inner{"bb", 12n}}), "l", Outer{"cc", Inner{"dd", 34n}})

def outer_end(v: Outer, w: Outer, q: String, cand: Maybe<&2, String>,
  r: Map<&2, Outer> & Outer) -> U32:
  (m4, x) = r
  U32.add(U32.mul(outer_digest(v, "aa", "bb", 12n), 10000),
    U32.add(U32.mul(outer_digest(w, "cc", "dd", 34n), 100),
      U32.add(U32.mul(has_key(cand, "k"), 10),
        outer_digest(x, "gg", "hh", 7n))))

def outer_seek(v: Outer, w: Outer,
  r: Map<&2, Outer> & String & Maybe<&2, String>) -> U32:
  (m3, q, cand) = r
  outer_end(v, w, q, cand, Map.get(Outer, Outer{"ee", Inner{"ff", 0n}},
    Map.set(&2, Outer, m3, "k", Outer{"gg", Inner{"hh", 7n}}), "k"))

def outer_next(v: Outer, r: Map<&2, Outer> & Outer) -> U32:
  (m2, w) = r
  outer_seek(v, w, Map.seek(&2, Outer, m2, "k"))

def outer_after(r: Map<&2, Outer> & Outer) -> U32:
  (m1, v) = r
  outer_next(v, Map.get(Outer, Outer{"ee", Inner{"ff", 0n}}, m1, "l"))

def outer_reads(m: Map<&2, Outer>) -> U32:
  outer_after(Map.get(Outer, Outer{"ee", Inner{"ff", 0n}}, m, "k"))

# A one-word value type packs into the constructor word: the hit's answer and
# the miss's default both come back as that word.
type Flag is Data:
  Flag{v: U32}

def flag_of(p: Flag) -> U32:
  Flag{v} = p
  v

def flag_miss(r: Map<&2, Flag> & Flag) -> U32:
  (m2, d) = r
  U32.mul(flag_of(d), 10)

def flag_after(r: Map<&2, Flag> & Flag) -> U32:
  (m1, v) = r
  U32.add(flag_of(v), flag_miss(Map.get(Flag, Flag{9}, m1, "zz")))

def flag_reads(m: Map<&2, Flag>) -> U32:
  flag_after(Map.get(Flag, Flag{0}, m, "k"))

def flag_map() -> Map<&2, Flag>:
  Map.set(&2, Flag, Map.new(&2, Flag), "k", Flag{3})

# A single-leaf string map: the root is the leaf the hit shares.
def solo_miss(r: Map<&2, String> & String) -> U32:
  (m2, d) = r
  b2u(String.eq(d, "qq"))

def solo_after(r: Map<&2, String> & String) -> U32:
  (m1, v) = r
  U32.add(U32.mul(b2u(String.eq(v, "alpha")), 10),
    solo_miss(Map.get(String, String.append("q", "q"), m1, "zz")))

def solo_reads(m: Map<&2, String>) -> U32:
  solo_after(Map.get(String, String.append("q", "q"), m, "k"))

def solo_map() -> Map<&2, String>:
  Map.set(&2, String, Map.new(&2, String), "k", "alpha")

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(str_reads(str_map())))
    Unit <- IO.print(U32.show(alias_value(String.append("sha", "red"))))
    Unit <- IO.print(U32.show(outer_reads(outer_map())))
    Unit <- IO.print(U32.show(flag_reads(flag_map())))
    IO.print(U32.show(solo_reads(solo_map())))
#|11111
#|11
#|1121221
#|93
#|11
