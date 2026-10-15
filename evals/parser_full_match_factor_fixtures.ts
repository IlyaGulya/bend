/** Generic source fixtures. No parser declaration or grammar dependencies. */
export const matrixPrefix = `import Base
type Cell is Data:
  Cell{flag: Bool, key: String, a: Nat, b: Nat, c: Nat, d: Nat}
type Phase is Data:
  Open{flag: Bool, value: Nat}
  Closed{value: Nat}
`;
export const pathologicalMatrix = matrixPrefix + `
def matrix(+cells: List<&2, Cell>, phase: Phase) -> Nat:
  match cells phase:
    case Cell{True{}, "+", a, b, c, d} <> +rest Open{True{}, +ignored}:
      1n
    case Cell{_, "-", a, b, _, _} <> +rest Open{True{}, _}:
      2n
    case Cell{False{}, key, a, b, _, _} <> (Cell{_, "{", _, _, _, _} <> +rest) Open{True{}, _}:
      3n
    case Cell{False{}, key, _, b, _, _} <> (Cell{_, "{", _, _, _, _} <> +rest) Open{flag, a}:
      4n
    case Cell{False{}, +key, a, b, _, _} <> +rest Open{True{}, _}:
      5n
    case Cell{False{}, +key, _, b, _, _} <> +rest Open{flag, a}:
      6n
    case Cell{True{}, +key, +a, +b, c, d} <> +rest Open{flag, _}:
      7n
    case _ Closed{value}:
      value
    case _ _:
      9n
`;
export const orderedMatrix = `import Base
type Box is Data:
  Filled{value: Sigma<&2, &2, Nat, _ => Bool>}
  Empty{}
def matrix(+boxes: List<&2, Box>, flag: Bool) -> Nat:
  match boxes flag:
    case Filled{(+value, True{})} <> _ True{}:
      value
    case +whole False{}:
      List.length(&2, Box, whole)
    case Filled{(_, _)} <> _ _:
      22n
    case _ _:
      33n
`;
export const affineMatrix = `import Base
type Resource is Type:
  Resource{value: Nat}
def matrix(resource: Resource, flag: Bool) -> Nat:
  match resource flag:
    case Resource{value} True{}:
      value
    case Resource{other} _:
      other
`;
/** Both calls consume a Lone resource; an unused + pattern is not contraction. */
export const invalidAffineMatrix = `import Base
type Resource is Type:
  Resource{value: Nat}
def consume(resource: Resource) -> Nat:
  match resource:
    case Resource{value}:
      value
def matrix(resource: Resource, flag: Bool) -> Nat:
  match resource flag:
    case Resource{value} True{}:
      value
    case whole _:
      Nat.add(consume(whole), consume(whole))
`;
export const semanticCases = [
  {name:'ordered-product', source:orderedMatrix, inputs:[['[Filled{(7n, True{})}]','True{}',7],['[Filled{(7n, False{})}]','True{}',22],['[Filled{(7n, True{})}]','False{}',1],['[]','False{}',0],['[]','True{}',33],['[Empty{}]','True{}',33]]},
  {name:'affine-resource', source:affineMatrix, inputs:[['Resource{12n}','True{}',12],['Resource{13n}','False{}',13]]},
  {name:'wide-matrix',source:pathologicalMatrix,inputs:[['[Cell{True{}, "+", 0n, 0n, 0n, 0n}]','Open{True{}, 0n}',1],['[Cell{True{}, "-", 0n, 0n, 0n, 0n}]','Open{True{}, 0n}',2],['[Cell{False{}, "x", 0n, 0n, 0n, 0n}, Cell{True{}, "{", 0n, 0n, 0n, 0n}]','Open{True{}, 0n}',3],['[Cell{False{}, "x", 0n, 0n, 0n, 0n}, Cell{True{}, "{", 0n, 0n, 0n, 0n}]','Open{False{}, 0n}',4],['[Cell{False{}, "x", 0n, 0n, 0n, 0n}]','Open{True{}, 0n}',5],['[Cell{False{}, "x", 0n, 0n, 0n, 0n}]','Open{False{}, 0n}',6],['[Cell{True{}, "x", 0n, 0n, 0n, 0n}]','Open{False{}, 0n}',7],['[]','Closed{8n}',8],['[]','Open{True{}, 0n}',9]]},
] as const;
