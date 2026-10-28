import Base

type U0 is Data:
  U0{}

type WideP is Data:
  WideP{a: U32, b: U32, c: U32}

type Shape is Data:
  Circle{r: U32}
  Rect{w: U32, h: U32}

type BoxM is Data:
  BoxM{s: Shape}

type Wrap is Data:
  Wrap{w: FlS}

type E is Data:
  E{live: U32}

type BoxArrT is Data:
  BoxArrT{a: U32}

type Choice is Data:
  ChA{a: U32}
  ChB{b: U32}

type Choice0 is Data:
  CA{}
  CB{}

type WrapE is Data:
  WrapE{e: Choice0}


type PairS is Data:
  PairS{a: U32, b: U32}

type PtS is Data:
  PtS{x: U32, y: U32}

type FlS is Data:
  FlS{z: U32}

type SegS is Data:
  SegS{p1: PtS, p2: PtS, f: FlS}

type BoxS is Data:
  BoxS{t: String, u: U0}

type FlagsS is Data:
  FlagsS{a: Bool, b: Bool}

law probe:
  for pair: PairS
  for boxp: BoxS
  for seg: SegS
  for cb: U32 -> U32
  for wide: WideP
  for shape: Shape
  for boxm: BoxM
  for wrap: Wrap
  for erased: E
  for boxarr: BoxArrT
  for choice: Choice
  for choice0: Choice0
  for wrape: WrapE
  for flags: FlagsS
  for chars: Array<Char>
  IO(U32)

def probe(pair, boxp, seg, cb, wide, shape, boxm, wrap, erased, boxarr, choice, choice0, wrape, flags, chars):
  import "./physical_path_probe.c"

def main() -> IO(Unit):
  cap: U32 = 7
  f: U32 -> U32 = x => U32.add(x, cap)
  do IO<Unit>:
    r : U32 <- probe(PairS{3, 4}, BoxS{"hi", U0{}}, SegS{PtS{1, 2}, PtS{3, 4}, FlS{5}}, f,
      WideP{1, 2, 3}, Circle{4}, BoxM{Circle{4}}, Wrap{FlS{5}}, E{6}, BoxArrT{7}, ChA{8}, CA{}, WrapE{CA{}}, FlagsS{False{}, True{}}, Array.new(Char, 0n, 'λ'))
    IO.print("ok")

#|ok
