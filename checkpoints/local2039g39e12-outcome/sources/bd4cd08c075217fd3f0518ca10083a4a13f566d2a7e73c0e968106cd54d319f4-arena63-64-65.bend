import Base
import /Users/ilyagulya/Projects/My/bend/bend2/selfhost/checker_arena.bend as Arena

def grow(n: Nat, arena: Arena.Arena) -> Arena.Arena:
  match n:
    case 0n: arena
    case 1n+p: again(p, Arena.put_node(arena, Arena.TermQuant{}))

def again(n: Nat, result: Arena.Arena & U32) -> Arena.Arena:
  match result:
    case Tuple{arena, _}: grow(n, arena)

def count(result: Arena.Arena & U32) -> U32:
  match result:
    case Tuple{_, n}: n

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(count(Arena.node_count(grow(63n, Arena.empty())))))
    IO.print(U32.show(count(Arena.node_count(grow(64n, Arena.empty())))))
    IO.print(U32.show(count(Arena.node_count(grow(65n, Arena.empty())))))

#|63
#|64
#|65
