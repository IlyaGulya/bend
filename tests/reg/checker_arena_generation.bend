import Base
import ../../bend2/selfhost/checker_arena.bend as Arena

def flag(value: Bool) -> U32:
  match value:
    case True{}: 1
    case False{}: 0

def grow_result(result: Arena.Arena & U32) -> Arena.Arena:
  match result:
    case Tuple{arena, _}: arena
def grow(arena: Arena.Arena) -> Arena.Arena:
  grow_result(Arena.reserve_words(arena, 1000))

def after_regrowth(+expected: Nat, stable: U32, advanced: U32, result: Arena.Arena & Nat) -> IO(Unit):
  match result:
    case Tuple{_, generation}:
      IO.print(U32.show(U32.add(stable, U32.add(U32.mul(advanced, 2), U32.mul(flag(Nat.is_eq(expected, generation)), 4)))))
def after_rewind(before: Nat, stable: U32, result: Arena.Arena & Nat) -> IO(Unit):
  match result:
    case Tuple{arena, +generation}:
      after_regrowth(generation, stable, flag(Nat.is_gt(generation, before)), Arena.generation(grow(arena)))
def marked(before: Nat, stable: U32, result: Arena.Arena & Arena.Mark) -> IO(Unit):
  match result:
    case Tuple{arena, saved}:
      after_rewind(before, stable, Arena.generation(Arena.rewind(arena, saved)))
def after_growth(+before: Nat, result: Arena.Arena & Nat) -> IO(Unit):
  match result:
    case Tuple{arena, generation}:
      marked(before, flag(Nat.is_eq(before, generation)), Arena.mark(arena))
def initial(result: Arena.Arena & Nat) -> IO(Unit):
  match result:
    case Tuple{arena, generation}:
      after_growth(generation, Arena.generation(grow(arena)))
def main() -> IO(Unit):
  initial(Arena.generation(Arena.empty()))

#|7
