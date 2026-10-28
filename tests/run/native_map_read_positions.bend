# Public MNode positions. Base's Map.bit reads the query from its head for
# every node it visits, so a trie may name a position before the one just read,
# one past the key's end, or a Nat far past it. The native read keeps one
# cursor over the key and goes back to the head when a node asks earlier, so
# every one of these tries must answer exactly as the source does.
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

# Bit 33 of "a" is past its end, so the root goes low to a node whose bit 0 is
# the first character: that read must restart at the head, and it does select
# the "b" leaf.
def back_tree() -> Map<&2, U32>:
  MNode{33n, MNode{0n, MLeaf{"a", 5}, MLeaf{"b", 7}}, MTip{}}

def back_hit(miss: U32, here: Bool, q: String, cand: Maybe<&2, String>,
  r: Map<&2, U32> & U32) -> U32:
  (m4, hit) = r
  U32.add(U32.mul(miss, 10000),
    U32.add(U32.mul(b2u(here), 1000),
      U32.add(U32.mul(b2u(String.eq(q, "a")), 100),
        U32.add(U32.mul(has_key(cand, "b"), 10), hit))))

def back_seek(miss: U32, here: Bool,
  r: Map<&2, U32> & String & Maybe<&2, String>) -> U32:
  (m3, q, cand) = r
  back_hit(miss, here, q, cand, Map.get(U32, 41, m3, "b"))

def back_has(miss: U32, r: Map<&2, U32> & Bool) -> U32:
  (m2, here) = r
  back_seek(miss, here, Map.seek(&2, U32, m2, "a"))

def back_after(r: Map<&2, U32> & U32) -> U32:
  (m1, miss) = r
  back_has(miss, Map.has(&2, U32, m1, "a"))

def back_reads(+m: Map<&2, U32>) -> U32:
  back_after(Map.get(U32, 41, m, "a"))

# A position far past a short key reads zero and follows the low child: the
# query never walks to it and never wraps the index.
def huge_tree() -> Map<&2, U32>:
  MNode{Nat.add(Nat.mul(4294967295n, 65536n), 65535n),
    MLeaf{"h", 1}, MLeaf{"h", 2}}

def huge_has(v: U32, r: Map<&2, U32> & Bool) -> U32:
  (m2, h) = r
  U32.add(U32.mul(v, 10), b2u(h))

def huge_after(r: Map<&2, U32> & U32) -> U32:
  (m1, v) = r
  huge_has(v, Map.has(&2, U32, m1, "h"))

def huge_reads(+m: Map<&2, U32>) -> U32:
  huge_after(Map.get(U32, 9, m, "h"))

# A leaf root answers a mismatching query with the leaf's own key as the
# candidate, and its default or false from the comparison.
def leaf_tree() -> Map<&2, U32>:
  MLeaf{"solo", 3}

def leaf_hit(miss: U32, q: String, cand: Maybe<&2, String>, h: Bool,
  r: Map<&2, U32> & String & Maybe<&2, String>) -> U32:
  (m4, q2, cand2) = r
  U32.add(U32.mul(miss, 10000),
    U32.add(U32.mul(b2u(String.eq(q, "zz")), 1000),
      U32.add(U32.mul(has_key(cand, "solo"), 100),
        U32.add(U32.mul(b2u(h), 10),
          U32.add(U32.mul(has_key(cand2, "solo"), 1),
            U32.mul(b2u(String.eq(q2, "solo")), 0))))))

def leaf_has(miss: U32, q: String, cand: Maybe<&2, String>,
  r: Map<&2, U32> & Bool) -> U32:
  (m3, h) = r
  leaf_hit(miss, q, cand, h, Map.seek(&2, U32, m3, "solo"))

def leaf_seek(miss: U32,
  r: Map<&2, U32> & String & Maybe<&2, String>) -> U32:
  (m2, q, cand) = r
  leaf_has(miss, q, cand, Map.has(&2, U32, m2, "zz"))

def leaf_after(r: Map<&2, U32> & U32) -> U32:
  (m1, miss) = r
  leaf_seek(miss, Map.seek(&2, U32, m1, "zz"))

def leaf_reads(+m: Map<&2, U32>) -> U32:
  leaf_after(Map.get(U32, 6, m, "zz"))

# Keys past the Unicode scalars, a NUL, and a prefix of another key: the bits
# and the unsigned code comparison must both stay exact.
def odd_keys() -> Map<&2, U32>:
  Map.set(&2, U32, Map.set(&2, U32, Map.set(&2, U32, Map.new(&2, U32),
    "\u{0}a", 11), "\u{ffffffff}", 22), "\u{80000000}b", 33)

def odd_seek(a: U32, b: U32, c: U32, d: U32, h: Bool,
  r: Map<&2, U32> & String & Maybe<&2, String>) -> U32:
  (m6, q, cand) = r
  U32.add(U32.mul(a, 1000000),
    U32.add(U32.mul(b, 100000),
      U32.add(U32.mul(c, 10000),
        U32.add(U32.mul(d, 1000),
          U32.add(U32.mul(b2u(h), 100),
            U32.add(U32.mul(b2u(String.eq(q, "\u{80000000}b")), 10),
              has_key(cand, "\u{80000000}b")))))))

def odd_has(a: U32, b: U32, c: U32, d: U32,
  r: Map<&2, U32> & Bool) -> U32:
  (m5, h) = r
  odd_seek(a, b, c, d, h, Map.seek(&2, U32, m5, "\u{80000000}b"))

def odd_miss(a: U32, b: U32, c: U32, r: Map<&2, U32> & U32) -> U32:
  (m4, d) = r
  odd_has(a, b, c, d, Map.has(&2, U32, m4, "\u{ffffffff}\u{0}"))

def odd_c(a: U32, b: U32, r: Map<&2, U32> & U32) -> U32:
  (m3, c) = r
  odd_miss(a, b, c, Map.get(U32, 90, m3, "\u{0}"))

def odd_b(a: U32, r: Map<&2, U32> & U32) -> U32:
  (m2, b) = r
  odd_c(a, b, Map.get(U32, 90, m2, "\u{80000000}b"))

def odd_after(r: Map<&2, U32> & U32) -> U32:
  (m1, a) = r
  odd_b(a, Map.get(U32, 90, m1, "\u{ffffffff}"))

def odd_reads(m: Map<&2, U32>) -> U32:
  odd_after(Map.get(U32, 90, m, "\u{0}a"))

# One key a prefix of the next: a miss past every leaf must not hit a prefix.
def prefix_map() -> Map<&2, U32>:
  Map.set(&2, U32, Map.set(&2, U32, Map.set(&2, U32, Map.new(&2, U32),
    "a", 1), "ab", 2), "abc", 3)

def prefix_has(a: U32, b: U32, c: U32, d: U32,
  r: Map<&2, U32> & Bool) -> U32:
  (m5, h) = r
  U32.add(U32.mul(a, 10000),
    U32.add(U32.mul(b, 1000),
      U32.add(U32.mul(c, 100),
        U32.add(U32.mul(d, 10), b2u(h)))))

def prefix_miss(a: U32, b: U32, c: U32, r: Map<&2, U32> & U32) -> U32:
  (m4, d) = r
  prefix_has(a, b, c, d, Map.has(&2, U32, m4, "abcd"))

def prefix_c(a: U32, b: U32, r: Map<&2, U32> & U32) -> U32:
  (m3, c) = r
  prefix_miss(a, b, c, Map.get(U32, 60, m3, "abcd"))

def prefix_b(a: U32, r: Map<&2, U32> & U32) -> U32:
  (m2, b) = r
  prefix_c(a, b, Map.get(U32, 60, m2, "abc"))

def prefix_after(r: Map<&2, U32> & U32) -> U32:
  (m1, a) = r
  prefix_b(a, Map.get(U32, 60, m1, "ab"))

def prefix_reads(m: Map<&2, U32>) -> U32:
  prefix_after(Map.get(U32, 60, m, "a"))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(back_reads(back_tree())))
    Unit <- IO.print(U32.show(huge_reads(huge_tree())))
    Unit <- IO.print(U32.show(leaf_reads(leaf_tree())))
    Unit <- IO.print(U32.show(odd_reads(odd_keys())))
    IO.print(U32.show(prefix_reads(prefix_map())))
#|410117
#|11
#|61101
#|13620011
#|12900
