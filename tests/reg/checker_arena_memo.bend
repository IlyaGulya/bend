import Base
import ../../bend2/selfhost/checker_arena.bend as Arena

# The transient memo is invalidated by the rewind epoch, not by rewriting every
# slot. Pin the consumer-visible lifecycle on both transient lanes: a live put is
# readable, a rewind makes it invisible, the same key/id re-put after that rewind
# answers with the new value, and a second rewind invalidates it again.

def flag(value: Bool) -> U32:
  match value:
    case True{}: 1
    case False{}: 0

def saved_entry(entry: Arena.SubstMemoEntry, expected: U32, weight: U32) -> U32:
  match entry:
    case Arena.SubstMemoSaved{_, _, _, _, output_id, _}:
      U32.mul(flag(U32.is_eq(output_id, expected)), weight)
    case _: 0

def empty_entry(entry: Arena.SubstMemoEntry, weight: U32) -> U32:
  match entry:
    case Arena.SubstMemoEmpty{}: weight
    case _: 0

def published_entry(entry: Arena.SubstMemoEntry, expected: U32, weight: U32) -> U32:
  match entry:
    case Arena.PublishedTerm{_, output_id, _}:
      U32.mul(flag(U32.is_eq(output_id, expected)), weight)
    case _: 0

def publication_twice_invalidated(score: U32, result: Arena.Arena & Arena.SubstMemoEntry) -> U32:
  match result:
    case Tuple{_, entry}:
      U32.add(score, empty_entry(entry, 128))

def publication_marked_again(score: U32, result: Arena.Arena & Arena.Mark) -> U32:
  match result:
    case Tuple{arena, saved}:
      publication_twice_invalidated(score, Arena.subst_memo_get(Arena.rewind(arena, saved), 7, 0))

def publication_reput(score: U32, result: Arena.Arena & Arena.SubstMemoEntry) -> U32:
  match result:
    case Tuple{arena, entry}:
      +scored = U32.add(score, published_entry(entry, 400, 64))
      publication_marked_again(scored, Arena.mark(arena))

def publication_invalidated(score: U32, result: Arena.Arena & Arena.SubstMemoEntry) -> U32:
  match result:
    case Tuple{arena, entry}:
      +scored = U32.add(score, empty_entry(entry, 32))
      publication_reput(scored, Arena.subst_memo_get(Arena.publication_memo_put(arena, 7, 400), 7, 0))

def publication_marked(score: U32, result: Arena.Arena & Arena.Mark) -> U32:
  match result:
    case Tuple{arena, saved}:
      publication_invalidated(score, Arena.subst_memo_get(Arena.rewind(arena, saved), 7, 0))

def publication_live(score: U32, result: Arena.Arena & Arena.SubstMemoEntry) -> U32:
  match result:
    case Tuple{arena, entry}:
      +scored = U32.add(score, published_entry(entry, 300, 16))
      publication_marked(scored, Arena.mark(arena))

def subst_twice_invalidated(score: U32, result: Arena.Arena & Arena.SubstMemoEntry) -> U32:
  match result:
    case Tuple{arena, entry}:
      +scored = U32.add(score, empty_entry(entry, 8))
      publication_live(scored, Arena.subst_memo_get(Arena.publication_memo_put(arena, 7, 300), 7, 0))

def subst_marked_again(score: U32, result: Arena.Arena & Arena.Mark) -> U32:
  match result:
    case Tuple{arena, saved}:
      subst_twice_invalidated(score, Arena.subst_memo_get(Arena.rewind(arena, saved), 1, 2))

def subst_reput(score: U32, result: Arena.Arena & Arena.SubstMemoEntry) -> U32:
  match result:
    case Tuple{arena, entry}:
      +scored = U32.add(score, saved_entry(entry, 200, 4))
      subst_marked_again(scored, Arena.mark(arena))

def subst_invalidated(score: U32, result: Arena.Arena & Arena.SubstMemoEntry) -> U32:
  match result:
    case Tuple{arena, entry}:
      +scored = U32.add(score, empty_entry(entry, 2))
      subst_reput(scored, Arena.subst_memo_get(Arena.subst_memo_put(arena, 1, 3n, 2, 4n, 200), 1, 2))

def subst_marked(score: U32, result: Arena.Arena & Arena.Mark) -> U32:
  match result:
    case Tuple{arena, saved}:
      subst_invalidated(score, Arena.subst_memo_get(Arena.rewind(arena, saved), 1, 2))

def subst_live(result: Arena.Arena & Arena.SubstMemoEntry) -> U32:
  match result:
    case Tuple{arena, entry}:
      subst_marked(saved_entry(entry, 100, 1), Arena.mark(arena))

def main() -> U32:
  subst_live(Arena.subst_memo_get(Arena.subst_memo_put(Arena.empty(), 1, 3n, 2, 4n, 100), 1, 2))

#|255
