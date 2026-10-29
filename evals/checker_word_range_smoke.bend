import Base
import ../checkpoints/checker_core_steps_v1.bend as Checker
import ../bend2/selfhost/checker_arena.bend as Arena

# Regenerate owned source and checker steps before running this smoke.
# Copy order is observable on overlapping ranges; a snapshot or memmove is wrong.
def fill(remaining: Nat, +value: U32, result: Arena.Arena & U32) -> Arena.Arena:
  match remaining result:
    case 0n Tuple{arena, _}: arena
    case 1n+rest Tuple{arena, _}:
      fill(rest, U32.add(value, 1), Arena.put_word(arena, value))

def fresh() -> Checker.ArenaStore:
  Checker.ArenaStore{fill(8n, 1, (Arena.empty(), 0)), fill(8n, 21, (Arena.empty(), 0))}

def check_words_step(expected: List<&2, U32>, +start: U32, ok: Bool, result: Checker.ArenaResult<U32>) -> Checker.ArenaResult<Bool>:
  match expected result:
    case Nil{} Checker.ArenaResult{store, _}: {Checker.ArenaResult{store, ok} : Checker.ArenaResult<Bool>}
    case +head <> Nil{} Checker.ArenaResult{store, value}:
      {Checker.ArenaResult{store, Bool.and(ok, U32.is_eq(value, head))} : Checker.ArenaResult<Bool>}
    case +head <> rest Checker.ArenaResult{store, value}:
      check_words_step(rest, U32.add(start, 1), Bool.and(ok, U32.is_eq(value, head)), Checker.checker_pure_arena_get_word(store, U32.add(start, 1)))

def check_words(store: Checker.ArenaStore, +start: U32, expected: List<&2, U32>) -> Checker.ArenaResult<Bool>:
  check_words_step(expected, start, True{}, Checker.checker_pure_arena_get_word(store, start))

def check_counts(ok: Bool, source_result: Arena.Arena & U32, transient_result: Arena.Arena & U32) -> Bool:
  match source_result transient_result:
    case Tuple{_, source_count} Tuple{_, transient_count}:
      Bool.and(ok, Bool.and(U32.is_eq(source_count, 8), U32.is_eq(transient_count, 8)))

def check_finish(source_ok: Bool, result: Checker.ArenaResult<Bool>) -> Bool:
  match result:
    case Checker.ArenaResult{Checker.ArenaStore{source_arena, transient_arena}, transient_ok}:
      check_counts(Bool.and(source_ok, transient_ok), Arena.word_count(source_arena), Arena.word_count(transient_arena))

def check_transient(expected: List<&2, U32>, result: Checker.ArenaResult<Bool>) -> Bool:
  match result:
    case Checker.ArenaResult{store, source_ok}: check_finish(source_ok, check_words(store, 2147483648, expected))

def check(store: Checker.ArenaStore, source: List<&2, U32>, transient: List<&2, U32>) -> Bool:
  check_transient(transient, check_words(store, 0, source))

def outcome(fuel: Nat, source: List<&2, U32>, transient: List<&2, U32>, run: Checker.CheckerRun<Checker.ArenaStore>) -> Bool:
  match fuel run:
    case 0n _: False{}
    case 1n+rest Checker.CheckerRunFinished{Checker.CheckerValue{store}}: check(store, source, transient)
    case 1n+rest Checker.CheckerRunState{A, progress, stack}:
      outcome(rest, source, transient, Checker.checker_step(Checker.ArenaStore, Checker.CheckerRunState{A, progress, stack}))

def copy(source: U32, destination: U32, remaining: Nat, offset: U32) -> Checker.CheckerRun<Checker.ArenaStore>:
  Checker.CheckerRunState{Checker.ArenaStore, Checker.checker_body_arena_copy_word_range(fresh(), source, destination, remaining, offset), Checker.CheckerStackDone{{==}}}

def report(label: String, run: Checker.CheckerRun<Checker.ArenaStore>, source: List<&2, U32>, transient: List<&2, U32>) -> IO(Unit):
  IO.print(String.append(label, U32.show(Bool.to_u32(outcome(10000n, source, transient, run)))))

def main() -> IO(Unit):
  do IO<Unit>:
    report("source-overlap:", copy(0, 1, 3n, 0), [1, 1, 1, 1, 5, 6, 7, 8], [21, 22, 23, 24, 25, 26, 27, 28])
    report("transient-reverse-overlap:", copy(3221225475, 3221225474, 3n, 0), [1, 2, 3, 4, 5, 6, 7, 8], [24, 24, 24, 24, 25, 26, 27, 28])
    report("source-to-transient:", copy(2, 2147483652, 2n, 0), [1, 2, 3, 4, 5, 6, 7, 8], [21, 22, 23, 24, 3, 4, 27, 28])
    report("transient-to-source:", copy(2147483648, 1, 3n, 0), [1, 21, 22, 23, 5, 6, 7, 8], [21, 22, 23, 24, 25, 26, 27, 28])
    report("reverse-source:", copy(1073741831, 2147483648, 3n, 0), [1, 2, 3, 4, 5, 6, 7, 8], [8, 7, 6, 24, 25, 26, 27, 28])
    report("reverse-destination:", copy(0, 3221225479, 3n, 0), [1, 2, 3, 4, 5, 6, 7, 8], [21, 22, 23, 24, 25, 3, 2, 1])
    report("nonzero-offset:", copy(0, 2147483648, 3n, 2), [1, 2, 3, 4, 5, 6, 7, 8], [21, 22, 3, 4, 5, 26, 27, 28])
    report("empty-invalid-handles:", copy(4294967295, 4294967295, 0n, 4294967295), [1, 2, 3, 4, 5, 6, 7, 8], [21, 22, 23, 24, 25, 26, 27, 28])
    report("tag-wrap:", copy(0, 2147483648, 2n, 2147483647), [21, 2, 3, 4, 5, 6, 7, 8], [21, 22, 23, 24, 25, 26, 27, 8])

#|source-overlap:1
#|transient-reverse-overlap:1
#|source-to-transient:1
#|transient-to-source:1
#|reverse-source:1
#|reverse-destination:1
#|nonzero-offset:1
#|empty-invalid-handles:1
#|tag-wrap:1
