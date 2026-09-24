# C macro collisions: ordinary names move; runtime/Base spellings do not.
import Base
import ../io/marshal_imported_nullary_type.bend as M

type Thing is Data:
  Thing{field: U32}

type S is Data:
  SCON{}

type A is Data:
  CON{}

type B is Data:
  NIL{}

type C is Data:
  OFF{}

type D is Data:
  Off{}

def Thing.field(+t: Thing, n: Nat) -> U32:
  match n:
    case 0n:
      0
    case 1n+p:
      (Thing.field(t, p) + 1 : U32)

def thing_field(t: Thing, n: Nat) -> U32:
  match n:
    case 0n:
      1
    case 1n+p:
      (thing_field(t, p) + 1 : U32)

def clo.apply(+n: Nat) -> U32:
  match n:
    case 0n:
      41
    case 1n+p:
      (clo.apply(p) + 1 : U32)

def clo_apply(+n: Nat) -> U32:
  match n:
    case 0n:
      42
    case 1n+p:
      (clo_apply(p) + 1 : U32)

def tag(s: S) -> U32:
  match s:
    case SCON{}:
      0

def is_odd(x: U32) -> Bool:
  Bool.not(U32.is_even(x))

def main() -> IO(Unit):
  do IO<Unit>:
    xs : List<String> <- IO.args()
    +n : Nat <- IO.pure(Nat, List.length(&1, String, xs))
    a : Unit <- IO.print(U32.show((Thing.field(Thing{7}, n) + thing_field(Thing{7}, n) : U32)))
    b : Unit <- IO.print("hello")
    c : Unit <- IO.print(U32.show(tag(SCON{})))
    d : Unit <- IO.print(U32.show(clo.apply(1n)))
    e : Unit <- IO.print(U32.show(clo_apply(1n)))
    f : Unit <- IO.print(U32.show(U32.from_nat(List.length(&2, U32, List.filter(~U32, ~is_odd, [1, 2, 3, 4, 5])))))
    g : Unit <- IO.print(Nat.show(n))
    x : M.Tag <- M.tag.off()
    h : Unit <- IO.print(M.tag.name(x))
    y : M.Tag <- M.tag.on()
    IO.print(M.tag.name(y))

#|1
#|hello
#|0
#|42
#|43
#|3
#|0
#|off
#|on
