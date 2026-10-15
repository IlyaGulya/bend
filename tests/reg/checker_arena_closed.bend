import Base
import ../../bend2/selfhost/checker_arena.bend as Arena

def flag(value: Bool) -> U32:
  match value:
    case True{}: 1
    case False{}: 0

def finish(result: Arena.Arena & Bool, closed: Bool, tagged: Bool, open: Bool) -> U32:
  match result:
    case Tuple{_, reused_closed}:
      U32.add(flag(closed), U32.add(U32.mul(flag(tagged), 10), U32.add(U32.mul(flag(open), 100), U32.mul(flag(reused_closed), 1000))))

def reused(result: Arena.Arena & U32, closed: Bool, tagged: Bool, open: Bool) -> U32:
  match result:
    case Tuple{arena, id}: finish(Arena.node_is_closed(arena, id), closed, tagged, open)

def opened(result: Arena.Arena & Bool, saved: Arena.Mark, closed: Bool, tagged: Bool) -> U32:
  match result:
    case Tuple{arena, open}: reused(Arena.put_node(Arena.rewind(arena, saved), Arena.TermQuant{}), closed, tagged, open)

def variable(result: Arena.Arena & U32, saved: Arena.Mark, closed: Bool, tagged: Bool) -> U32:
  match result:
    case Tuple{arena, id}: opened(Arena.node_is_closed(arena, id), saved, closed, tagged)

def marked(result: Arena.Arena & Arena.Mark, closed: Bool, tagged: Bool) -> U32:
  match result:
    case Tuple{arena, saved}:
      variable(Arena.put_node(arena, Arena.TermVar{0, Nat.add(4294967295n, 1n), Arena.empty_span()}), saved, closed, tagged)

def tagged(result: Arena.Arena & Bool, closed: Bool) -> U32:
  match result:
    case Tuple{arena, temporary}: marked(Arena.mark(arena), closed, temporary)

def closed(result: Arena.Arena & Bool, id: U32) -> U32:
  match result:
    case Tuple{arena, certificate}: tagged(Arena.node_is_closed(arena, U32.or(id, 2147483648)), certificate)

def compound(result: Arena.Arena & U32) -> U32:
  match result:
    case Tuple{arena, +id}: closed(Arena.node_is_closed(arena, id), id)

def leaf(result: Arena.Arena & U32) -> U32:
  match result:
    case Tuple{arena, id}: compound(Arena.put_node(arena, Arena.TermType{id, Arena.empty_span()}))

def main() -> U32:
  leaf(Arena.put_node(Arena.empty(), Arena.TermQuant{}))

#|1001
