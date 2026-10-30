import Base
import ../../../Users/ilyagulya/Projects/My/bend/bend2/selfhost/checker_arena.bend as Arena
import ../../../Users/ilyagulya/Projects/My/bend/evals/checker_arena_growth_smoke.bend as Growth

# The hot edge is put_word.result -> metadata_write -> put_word.tables.
# Arrays remain affine and flow through the actual arena implementation.
# Growth.mixed/reserved add every pool, rewind/regrowth, discarded-slot zeroing,
# and zero-length reservation checks; no host Array implementation is substituted.
def appended(remaining: Nat, +next: U32, result: Arena.Arena & U32) -> Arena.Arena:
  match result:
    case Tuple{arena, _}: fill(remaining, next, arena)

def fill(remaining: Nat, +next: U32, arena: Arena.Arena) -> Arena.Arena:
  match remaining:
    case 0n: arena
    case 1n+rest: appended(rest, U32.add(next, 1), Arena.put_word(arena, next))

def read_result(expected: U32, bad: U32, result: Arena.Arena & U32) -> Arena.Arena & U32:
  match result:
    case Tuple{arena, actual}: (arena, U32.add(bad, Bool.to_u32(U32.is_ne(expected, actual))))

def scan(remaining: Nat, +id: U32, result: Arena.Arena & U32) -> U32:
  match remaining result:
    case 0n Tuple{_, bad}: bad
    case 1n+rest Tuple{arena, bad}: scan(rest, U32.add(id, 1), read_result(U32.add(id, 17), bad, Arena.word(arena, id)))

def count_result(+expected: U32, result: Arena.Arena & U32) -> U32:
  match result:
    case Tuple{arena, actual}: scan(U32.to_nat(expected), 0, (arena, Bool.to_u32(U32.is_ne(expected, actual))))

def boundary(+count: U32) -> U32:
  count_result(count, Arena.word_count(fill(U32.to_nat(count), 17, Arena.empty())))

# Export probe for a future E05-qualified three-image driver: one fresh call is
# cold; any bounded repetitions in the same isolate must be reported as warm.
# Returns an error count, zero on success. No claims about timings before runs.
def probe(rounds: Nat) -> U32:
  match rounds:
    case 0n: 0
    case 1n+rest:
      U32.add(boundary(63), U32.add(boundary(64), U32.add(boundary(65), U32.add(Growth.mixed(), U32.add(Growth.reserved(), probe(rest))))))

def main() -> IO(Unit):
  IO.print(U32.show(probe(1n)))

#|0
