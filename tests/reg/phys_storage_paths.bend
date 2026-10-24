# storage witness: nested Seg(Pt, Pt, Fl) projection, a multi-arm tag and a
# packed one-word node, a shared node used twice, and Array get/set/swap/
# clone on U32 and on a wide record. The body is the C backend's physical
# Fill/Unfill/Construct/Project/array path, and the #| line is the run.
import Base

type Pt is Data:
  Pt{x: U32, y: U32}

type Fl is Data:
  Fl{z: U32}

type Seg is Data:
  Seg{from: Pt, to: Pt, fl: Fl}

type Choice is Data:
  ChA{a: U32}
  ChB{b: U32}
  ChC{c: U32}

type One is Data:
  One{v: U32}

type Wide is Data:
  Wide{p: U32, q: U32, r: U32, s: U32, t: U32, u: U32, v: U32, w: U32}

def mk_pt(x: U32, y: U32) -> Pt:
  Pt{x, y}

def seg() -> Seg:
  Seg{Pt{1, 2}, Pt{3, 4}, Fl{5}}

def read_seg(s: Seg) -> U32:
  match s:
    case Seg{from, to, fl}:
      match from:
        case Pt{x, y}:
          match to:
            case Pt{x2, y2}:
              match fl:
                case Fl{z}:
                  (U32.add(x, U32.add(U32.mul(y, 10), U32.add(U32.mul(x2, 100), U32.add(U32.mul(y2, 1000), U32.mul(z, 10000))))) : U32)

def read_choice(c: Choice) -> U32:
  match c:
    case ChA{a}: U32.add(a, 1)
    case ChB{b}: U32.add(b, 100)
    case ChC{c}: U32.add(c, 200)

def read_one(o: One) -> U32:
  match o:
    case One{v}: v

def plus_twice(+p: Pt, +q: Pt) -> U32:
  match p:
    case Pt{x, y}:
      match q:
        case Pt{a, b}:
          (U32.add(U32.add(x, y), U32.add(a, b)) : U32)

def read_wide(w: Wide) -> U32:
  match w:
    case Wide{p, q, r, s, t, u, v, x}:
      (U32.add(p, U32.add(U32.mul(q, 2), U32.add(U32.mul(r, 3), U32.add(U32.mul(s, 4), U32.add(U32.mul(t, 5), U32.add(U32.mul(u, 6), U32.add(U32.mul(v, 7), U32.mul(x, 8)))))))) : U32)

def after_get3(r: Array<U32> & U32, j: U32, i: U32, old: U32) -> U32:
  (x, k) = r
  (U32.add(i, U32.add(U32.mul(j, 10), U32.add(U32.mul(k, 100), U32.mul(old, 1000)))) : U32)

def after_get2(r: Array<U32> & U32, i: U32, old: U32) -> U32:
  (x, j) = r
  after_get3(Array.get(U32, x, 3), j, i, old)

def after_get1(r: Array<U32> & U32, old: U32) -> U32:
  (x, i) = r
  after_get2(Array.get(U32, x, 2), i, old)

def u32_cells(r: Array<U32> & U32) -> U32:
  (x, old) = r
  after_get1(Array.get(U32, x, 1), old)

def wide_after_get(r: Array<Wide> & Wide, old: Wide) -> U32:
  (x, i) = r
  (U32.add(read_wide(old), U32.mul(read_wide(i), 3)) : U32)

def wide_cells(r: Array<Wide> & Wide) -> U32:
  (x, old) = r
  wide_after_get(Array.get(Wide, x, 1), old)

def cloned_u32(r: Array<U32> & Array<U32>) -> U32:
  (orig, copy) = r
  u32_cells(Array.swap(U32, Array.set(U32, copy, 1, 7), 2, 9))

def array_u32() -> U32:
  a = [10 : U32*4n]
  cloned_u32(Array.clone(U32, a))

def cloned_wide(r: Array<Wide> & Array<Wide>) -> U32:
  (orig, copy) = r
  wide_cells(Array.swap(Wide, copy, 1, Wide{17, 18, 19, 20, 21, 22, 23, 24}))

def array_wide() -> U32:
  a = [Wide{1, 2, 3, 4, 5, 6, 7, 8} : Wide*2n]
  cloned_wide(Array.clone(Wide, a))

def nat_after1(r: Array<Nat> & Nat, old: Nat) -> String:
  (x, v) = r
  String.append(Nat.show(old), String.append(",", Nat.show(v)))

def nat_cells(r: Array<Nat> & Nat) -> String:
  (x, old) = r
  nat_after1(Array.get(Nat, x, 0), old)

def cloned_nat(r: Array<Nat> & Array<Nat>) -> String:
  (orig, copy) = r
  nat_cells(Array.swap(Nat, Array.set(Nat, copy, 1, 7n), 0, 9n))

def nat_text() -> String:
  a = [3n : Nat*2n]
  cloned_nat(Array.clone(Nat, a))

def main.out() -> U32:
  s = read_seg(seg())
  c = U32.add(read_choice(ChB{7}), U32.add(read_choice(ChC{8}), read_choice(ChA{9})))
  o = read_one(One{11})
  p = mk_pt(2, 3)
  q = mk_pt(4, 5)
  sh = plus_twice(p, q)
  u = array_u32()
  w = array_wide()
  (U32.add(s, U32.add(U32.mul(c, 10), U32.add(U32.mul(o, 100), U32.add(U32.mul(sh, 1000), U32.add(U32.mul(u, 10000), U32.mul(w, 1000000)))))) : U32)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(main.out()))
    IO.print(nat_text())

#|2655042671
#|3,9
