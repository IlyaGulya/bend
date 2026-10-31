# Five left-associated applications, with named and bound-function heads.
# Ordinary affine Type parameters are consumed by the type-function body.
# Grounding: tests/reg/array_open_element_family.bend:19-20, Id(A: Type)->Type.
# Unlike a type index, a Type-valued definition body cannot read a -a binder.
# Family indices remain erased; no checker rule or compiler setting is changed.
import Base

def Family(a: Type, b: Type, c: Type, d: Type, e: Type) -> Type:
  a

def Alias(a: Type, b: Type, c: Type, d: Type, e: Type) -> Type:
  Family(a)(b)(c)(d)(e)

type Named is Type:
  Named{value: Alias(U32)(Bool)(Nat)(String)(Unit)}

type Bound<-f: Type -> Type -> Type -> Type -> Type -> Type> is Type:
  Bound{value: f(U32)(Bool)(Nat)(String)(Unit)}

def read_named(value: Named) -> U32:
  match value:
    case Named{x}: x

def read_bound(value: Bound<Family>) -> U32:
  match value:
    case Bound{x}: x

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(read_named(Named{17})))
    IO.print(U32.show(read_bound(Bound{23})))

#|17
#|23
