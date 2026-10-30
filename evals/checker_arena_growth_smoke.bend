import Base
import ../bend2/selfhost/checker_arena.bend as Arena
import ../bend2/selfhost/ast.bend as Ast

# Every pool crosses growth boundaries, retains its prefix through rewind, then
# replaces the discarded suffix and grows again. All reads use the arena API.
def keep(result: Arena.Arena & U32) -> Arena.Arena:
  match result:
    case Tuple{arena, _}: arena

def append_name(round: U32, result: Arena.Arena & U32) -> Arena.Arena:
  match result:
    case Tuple{arena, _}: keep(Arena.put_name_value(arena, U32.show(round)))

def append_natural(+round: U32, result: Arena.Arena & U32) -> Arena.Arena:
  match result:
    case Tuple{arena, _}: append_name(round, Arena.put_natural(arena, U32.to_nat(round)))

def append_word(+round: U32, result: Arena.Arena & U32) -> Arena.Arena:
  match result:
    case Tuple{arena, _}: append_natural(round, Arena.put_word(arena, round))

def append_binder(+round: U32, result: Arena.Arena & U32) -> Arena.Arena:
  match result:
    case Tuple{arena, _}: append_word(round, Arena.put_binder(arena, Arena.TemplateBinder{round, 0n, 0, Arena.empty_span()}))

def append_pattern(+round: U32, result: Arena.Arena & U32) -> Arena.Arena:
  match result:
    case Tuple{arena, _}: append_binder(round, Arena.put_pattern(arena, Arena.PatternVar{round, 0n, Ast.QZero{}, Arena.empty_span()}))

def append(+round: U32, arena: Arena.Arena) -> Arena.Arena:
  append_pattern(round, Arena.put_node(arena, Arena.TermHole{round, Arena.empty_span()}))

def fill(remaining: Nat, +value: U32, arena: Arena.Arena) -> Arena.Arena:
  match remaining:
    case 0n: arena
    case 1n+rest: fill(rest, U32.add(value, 1), append(value, arena))

def node_key(value: Arena.Node) -> U32:
  match value:
    case Arena.TermHole{key, _}: key
    case _: 4294967295

def pattern_key(value: Arena.Pattern) -> U32:
  match value:
    case Arena.PatternVar{key, _, _, _}: key
    case _: 4294967295

def binder_key(value: Arena.Binder) -> U32:
  match value:
    case Arena.TemplateBinder{key, _, _, _}: key
    case _: 4294967295

def node_read(result: Arena.Arena & Arena.Node) -> Arena.Arena & U32:
  match result:
    case Tuple{arena, value}: (arena, node_key(value))

def pattern_read(result: Arena.Arena & Arena.Pattern) -> Arena.Arena & U32:
  match result:
    case Tuple{arena, value}: (arena, pattern_key(value))

def binder_read(result: Arena.Arena & Arena.Binder) -> Arena.Arena & U32:
  match result:
    case Tuple{arena, value}: (arena, binder_key(value))

def expect(expected: U32, bad: U32, result: Arena.Arena & U32) -> Arena.Arena & U32:
  match result:
    case Tuple{arena, actual}: (arena, U32.add(bad, Bool.to_u32(U32.is_ne(expected, actual))))

def check_node(id: U32, expected: U32, result: Arena.Arena & U32) -> Arena.Arena & U32:
  match result:
    case Tuple{arena, bad}: expect(expected, bad, node_read(Arena.get_node(arena, id)))

def check_pattern(id: U32, expected: U32, result: Arena.Arena & U32) -> Arena.Arena & U32:
  match result:
    case Tuple{arena, bad}: expect(expected, bad, pattern_read(Arena.get_pattern(arena, id)))

def check_binder(id: U32, expected: U32, result: Arena.Arena & U32) -> Arena.Arena & U32:
  match result:
    case Tuple{arena, bad}: expect(expected, bad, binder_read(Arena.get_binder(arena, id)))

def check_word(id: U32, expected: U32, result: Arena.Arena & U32) -> Arena.Arena & U32:
  match result:
    case Tuple{arena, bad}: expect(expected, bad, Arena.word(arena, id))

def natural_read(expected: Nat, bad: U32, result: Arena.Arena & Nat) -> Arena.Arena & U32:
  match result:
    case Tuple{arena, actual}: (arena, U32.add(bad, Bool.to_u32(Bool.not(Nat.is_eq(expected, actual)))))

def check_natural(id: U32, expected: U32, result: Arena.Arena & U32) -> Arena.Arena & U32:
  match result:
    case Tuple{arena, bad}: natural_read(U32.to_nat(expected), bad, Arena.natural(arena, id))

def name_read(expected: String, bad: U32, result: Arena.Arena & String) -> Arena.Arena & U32:
  match result:
    case Tuple{arena, actual}: (arena, U32.add(bad, Bool.to_u32(Bool.not(String.eq(expected, actual)))))

def check_name(id: U32, expected: U32, result: Arena.Arena & U32) -> Arena.Arena & U32:
  match result:
    case Tuple{arena, bad}: name_read(U32.show(expected), bad, Arena.name_text(arena, id))

def check_all(+id: U32, +expected: U32, result: Arena.Arena & U32) -> Arena.Arena & U32:
  check_name(id, expected, check_natural(id, expected, check_word(id, expected, check_binder(id, expected, check_pattern(id, expected, check_node(id, expected, result))))))

def expected(+id: U32) -> U32:
  U32.add(id, U32.add(10, U32.mul(7, Bool.to_u32(U32.is_ge(id, 3)))))

def scan(remaining: Nat, +id: U32, result: Arena.Arena & U32) -> U32:
  match remaining result:
    case 0n Tuple{_, bad}: bad
    case 1n+rest Tuple{arena, bad}: scan(rest, U32.add(id, 1), check_all(id, expected(id), (arena, bad)))

def count_bad(+expected: U32, saved: Arena.Mark) -> U32:
  match saved:
    case Arena.Mark{nodes, patterns, binders, words, naturals, names}:
      U32.add(Bool.to_u32(U32.is_ne(nodes, expected)), U32.add(Bool.to_u32(U32.is_ne(patterns, expected)), U32.add(Bool.to_u32(U32.is_ne(binders, expected)), U32.add(Bool.to_u32(U32.is_ne(words, expected)), U32.add(Bool.to_u32(U32.is_ne(naturals, expected)), Bool.to_u32(U32.is_ne(names, expected)))))))

def final_read(result: Arena.Arena & Arena.Mark) -> U32:
  match result:
    case Tuple{arena, saved}: scan(18n, 0, (arena, count_bad(18, saved)))

def replaced(saved: Arena.Mark, arena: Arena.Arena) -> U32:
  final_read(Arena.mark(fill(15n, 20, Arena.rewind(arena, saved))))

def marked(result: Arena.Arena & Arena.Mark) -> U32:
  match result:
    case Tuple{arena, saved}: replaced(saved, fill(6n, 90, arena))

def mixed() -> U32:
  marked(Arena.mark(fill(3n, 10, Arena.empty())))

# Bulk reserve still publishes capacity/depth, including zero-length reserves.
# Seed a discarded slot with a stale value; reservation must explicitly zero it.
def reserved_count(bad: U32, result: Arena.Arena & U32) -> U32:
  match result:
    case Tuple{_, count}: U32.add(bad, Bool.to_u32(U32.is_ne(count, 8)))

def reserved_zero(bad: U32, result: Arena.Arena & U32) -> U32:
  match result:
    case Tuple{arena, start}: reserved_count(U32.add(bad, Bool.to_u32(U32.is_ne(start, 8))), Arena.word_count(arena))

def reserved_finish(bad: U32, result: Arena.Arena & U32) -> U32:
  match result:
    case Tuple{arena, added}: reserved_zero(U32.add(bad, added), Arena.reserve_words(arena, 0))

def scan_reserved(start: U32, result: Arena.Arena & U32) -> U32:
  match result:
    case Tuple{arena, bad}: reserved_finish(U32.add(bad, Bool.to_u32(U32.is_ne(start, 5))), check_word(4, 9, check_word(5, 0, check_word(6, 0, check_word(7, 0, (arena, 0))))))

def reserved_read(result: Arena.Arena & U32) -> U32:
  match result:
    case Tuple{arena, start}: scan_reserved(start, (arena, 0))

def reserved_rewind(saved: Arena.Mark, arena: Arena.Arena) -> U32:
  reserved_read(Arena.reserve_words(Arena.set_word(Arena.rewind(arena, saved), 6, 99), 3))

def reserved_marked(result: Arena.Arena & Arena.Mark) -> U32:
  match result:
    case Tuple{arena, saved}: reserved_rewind(saved, keep(Arena.put_word(arena, 7)))

def reserved_prefix(result: Arena.Arena & U32) -> U32:
  match result:
    case Tuple{arena, _}: reserved_marked(Arena.mark(keep(Arena.put_word(arena, 9))))

def reserved() -> U32:
  reserved_prefix(Arena.reserve_words(Arena.empty(), 4))

def report(label: String, bad: U32) -> IO(Unit):
  IO.print(String.append(label, U32.show(Bool.to_u32(U32.is_zero(bad)))))

def main() -> IO(Unit):
  do IO<Unit>:
    report("mixed-growth-rewind:", mixed())
    report("reserved:", reserved())

#|mixed-growth-rewind:1
#|reserved:1
