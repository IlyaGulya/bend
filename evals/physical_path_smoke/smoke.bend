import Base

type U0 is Data:
  U0{}

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

law probe:
  for pair: PairS
  for boxp: BoxS
  for seg: SegS
  IO(U32)

def probe(pair, boxp, seg):
  import "./probe.c"
  import "./probe.js"

def main() -> IO(Unit):
  do IO<Unit>:
    r : U32 <- probe(PairS{3, 4}, BoxS{"hi", U0{}}, SegS{PtS{1, 2}, PtS{3, 4}, FlS{5}})
    IO.print("ok")

#|ok
