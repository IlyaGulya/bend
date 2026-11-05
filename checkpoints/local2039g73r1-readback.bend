type Bit is Data:
  BitZero{}
  BitOne{}
type Duo is Type:
  Duo{-ty: Type, left: Bit, -unused: Type, right: Bit}
def zero() -> Bit:
  BitZero{}
def one() -> Bit:
  BitOne{}
def pack(left: Bit, right: Bit) -> Duo:
  Duo{Bit, left, Bit, right}
def make_pack(left: Bit) -> (Bit -> Duo):
  right => pack(left, right)
def apply(f: Bit -> Duo, x: Bit) -> Duo:
  f(x)
def identity(a, -A: Kind(a), x: A) -> A:
  x
def identity_probe(x: Bit) -> Bit:
  identity(&2, Bit, x)
def ignore(-ghost: Bit, value: Bit) -> Bit:
  value
def erased_probe(f: Bit -> Bit, value: Bit) -> Bit:
  ignore(f(BitZero{}), value)
def specialize(~A: Type, x: A) -> A:
  x
def specialized_probe(x: Bit) -> Bit:
  specialize(~Bit, x)
def local_twice(action: Bit -> Bit, input: Bit) -> Duo:
  +value = action(input)
  pack(value, value)
def local_unused(action: Bit -> Bit, input: Bit) -> Bit:
  unused = action(input)
  BitZero{}
def local_order(first: Bit -> Bit, second: Bit -> Bit, left: Bit, right: Bit) -> Duo:
  a = first(left)
  b = second(right)
  pack(a, b)
def make_after(action: Bit -> Bit, input: Bit) -> (Bit -> Duo):
  value = action(input)
  rest => pack(value, rest)
def over_order(first: Bit -> Bit, second: Bit -> Bit, left: Bit, right: Bit) -> Duo:
  make_after(first, left)(second(right))
def over_generic(make: Bit -> (Bit -> Duo), argument: Bit -> Bit, left: Bit, right: Bit) -> Duo:
  make(left)(argument(right))
def constructor_match() -> (Bit -> Bit):
  \{BitZero: BitOne{}; BitOne: BitZero{}; \{}}
