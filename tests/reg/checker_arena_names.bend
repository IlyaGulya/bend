import Base
import ../../bend2/selfhost/checker_arena.bend as Arena

type Probe is Data:
  Probe{key: String, expected: U32}

def wrong.result(same: Bool) -> U32:
  match same:
    case True{}: 0
    case False{}: 1

def wrong(expected: U32, actual: U32) -> U32:
  wrong.result(U32.is_eq(expected, actual))

def probe.result(expected: U32, result: Arena.Arena & U32) -> Arena.Arena & U32:
  match result:
    case Tuple{arena, id}: (arena, wrong(expected, id))

def probe(arena: Arena.Arena, row: Probe) -> Arena.Arena & U32:
  match row:
    case Probe{key, expected}: probe.result(expected, Arena.name(arena, key))

def probes.merge(bad: U32, result: Arena.Arena & U32) -> Arena.Arena & U32:
  match result:
    case Tuple{arena, others}: (arena, U32.add(bad, others))

def probes.go(rows: List<&2, Probe>, result: Arena.Arena & U32) -> Arena.Arena & U32:
  match rows result:
    case Nil{} Tuple{arena, bad}: (arena, bad)
    case row <> rest Tuple{arena, bad}:
      probes.merge(bad, probes.go(rest, probe(arena, row)))

def probes(arena: Arena.Arena, rows: List<&2, Probe>) -> Arena.Arena & U32:
  probes.go(rows, (arena, 0))

# The historical maximum-ID marker still denotes a missing entry.
def with_sentinel(arena: Arena.Arena) -> Arena.Arena:
  match arena:
    case Arena.Arena{nodes, patterns, binders, words, naturals, names, counts, depths, ids, closed, bounds, pattern_depths, prefixes, memo}:
      Arena.Arena{nodes, patterns, binders, words, naturals, names, counts, depths, Map.set(&2, U32, ids, "sentinel", 4294967295), closed, bounds, pattern_depths, prefixes, memo}

def count.result(expected: U32, bad: U32, result: Arena.Arena & U32) -> Arena.Arena & U32:
  match result:
    case Tuple{arena, actual}: (arena, U32.add(bad, wrong(expected, actual)))

def count(expected: U32, result: Arena.Arena & U32) -> Arena.Arena & U32:
  match result:
    case Tuple{arena, bad}: count.result(expected, bad, Arena.name_count(arena))

def finish(result: Arena.Arena & U32) -> IO(Unit):
  match result:
    case Tuple{_, bad}: IO.print(U32.show(bad))

def sentinel(result: Arena.Arena & U32) -> IO(Unit):
  match result:
    case Tuple{arena, bad}:
      finish(count(9, probes.merge(bad, probes(with_sentinel(arena), [Probe{"sentinel", 8}, Probe{"sentinel", 8}, Probe{"ab", 2}]))))

def restored(result: Arena.Arena & U32) -> IO(Unit):
  sentinel(count(8, result))

def rewound(bad: U32, arena: Arena.Arena) -> IO(Unit):
  restored(probes.merge(bad, probes(arena, [Probe{"replacement", 5}, Probe{"temp", 6}, Probe{"temporary", 7}, Probe{"ab", 2}, Probe{"😀", 4}])))

def temporary(saved: Arena.Mark, bad: U32, result: Arena.Arena & U32) -> IO(Unit):
  match result:
    case Tuple{arena, others}: rewound(U32.add(bad, others), Arena.rewind(arena, saved))

def marked(bad: U32, result: Arena.Arena & Arena.Mark) -> IO(Unit):
  match result:
    case Tuple{arena, saved}:
      temporary(saved, bad, probes(arena, [Probe{"temp", 5}, Probe{"temporary", 6}, Probe{"я", 3}]))

def initial(result: Arena.Arena & U32) -> IO(Unit):
  match result:
    case Tuple{arena, bad}: marked(bad, Arena.mark(arena))

def main() -> IO(Unit):
  initial(count(5, probes(Arena.empty(), [Probe{"", 0}, Probe{"a", 1}, Probe{"ab", 2}, Probe{"я", 3}, Probe{"😀", 4}, Probe{"a", 1}, Probe{"", 0}, Probe{"я", 3}])))

#|0
