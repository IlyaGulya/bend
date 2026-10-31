# Bodies copied from the parent-identified genuine-checker accepted
# /private/tmp/bend-e01-e13-jbsb4I/inspection-probe.bend.
# Only main/expectation are added; this executable version is unexecuted.
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

def local_order(first: Bit -> Bit, second: Bit -> Bit, left: Bit, right: Bit) -> Duo:
  a = first(left)
  b = second(right)
  pack(a, b)

def make_after(action: Bit -> Bit, input: Bit) -> (Bit -> Duo):
  value = action(input)
  rest => pack(value, rest)

def over_order(first: Bit -> Bit, second: Bit -> Bit, left: Bit, right: Bit) -> Duo:
  make_after(first, left)(second(right))

def main() -> Duo:
  over_order(x => identity_probe(x), x => specialized_probe(x), zero(), one())

#|Duo{BitZero{}, BitOne{}}
