import Base

# A row read makes runtime-created recursive children independently owned.
type Node is Data:
  Leaf{value: U32}
  Branch{child: Node}

def make(value: U32) -> Node:
  Branch{Leaf{value}}

def leaf(value: Node) -> U32:
  match value:
    case Leaf{word}: word
    case Branch{child}: 0

def branch(value: Node) -> U32:
  match value:
    case Leaf{word}: 0
    case Branch{child}: leaf(child)

def read(result: CompilerRows(Node) & Node) -> U32:
  match result:
    case Tuple{rows, value}: branch(value)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    +x : U32 = U32.add(17, U32.from_nat(List.length(&1, String, args)))
    IO.print(U32.show(Bool.pick(U32, U32.is_eq(read(CompilerRows.get(Node, CompilerRows.new(Node, 0n, make(x)), 0)), x), 1, 0)))
    IO.print(U32.show(Bool.pick(U32, U32.is_eq(read(CompilerRows.get(Node, CompilerRows.append(Node, CompilerRows.new(Node, 0n, Leaf{0}), make(x)), 0)), x), 1, 0)))

#|1
#|1
