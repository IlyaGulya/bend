import Base
import ./ast.bend as Ast
import ./scope_lookup.bend as Scope

# Compiler-private descriptors retain original spans, arbitrary Nat indexes and
# quantities. Child/name handles are U32; all list ranges are inline flat tapes.

type Node is Data:
  TermVar{key_id: U32, index: Nat, span: Ast.SourceSpan}
  TermRef{key_id: U32, span: Ast.SourceSpan}
  TermBang{term_id: U32, span: Ast.SourceSpan}
  TermSub{index: Nat, value_id: U32, body_id: U32, span: Ast.SourceSpan}
  TermLet{keys_start: U32, keys_count: U32, indexes_start: U32, indexes_count: U32, quantities_start: U32, quantities_count: U32, values_start: U32, values_count: U32, body_id: U32, span: Ast.SourceSpan}
  TermAnn{term_id: U32, ty_id: U32, span: Ast.SourceSpan}
  TermTemplate{term_id: U32, span: Ast.SourceSpan}
  TermType{kind_id: U32, span: Ast.SourceSpan}
  TermQuant{}
  TermQuantity{quantity: Ast.Quantity, span: Ast.SourceSpan}
  TermMin{left_id: U32, right_id: U32, span: Ast.SourceSpan}
  TermAll{quantity: Ast.Quantity, key_id: U32, index: Nat, ty_id: U32, body_id: U32, span: Ast.SourceSpan}
  TermLam{quantity: Maybe<&2, Ast.Quantity>, key_id: U32, index: Nat, body_id: U32, span: Ast.SourceSpan}
  TermApp{fn_id: U32, arg_id: U32, span: Ast.SourceSpan}
  TermAdt{key_id: U32, args_start: U32, args_count: U32, refs_start: U32, refs_count: U32, span: Ast.SourceSpan}
  TermFill{head_id: U32, args_start: U32, args_count: U32, span: Ast.SourceSpan}
  TermPlus{head_id: U32, args_start: U32, args_count: U32, span: Ast.SourceSpan}
  TermCtr{key_id: U32, args_start: U32, args_count: U32, span: Ast.SourceSpan}
  TermString{chars: List<&2, U32>, names: Ast.StringLiteralNames, span: Ast.SourceSpan}
  TermMat{key_id: U32, head_id: U32, matched_id: U32, span: Ast.SourceSpan}
  TermAbsurd{span: Ast.SourceSpan}
  TermEqual{left_id: U32, right_id: U32, ty_id: U32, span: Ast.SourceSpan}
  TermRefl{span: Ast.SourceSpan}
  TermRewrite{equation_id: U32, proof_id: U32, body_id: U32, span: Ast.SourceSpan}
  TermHole{key_id: U32, span: Ast.SourceSpan}
  BodyMatch{scrutinees_start: U32, scrutinees_count: U32, cases_start: U32, cases_count: U32, span: Ast.SourceSpan}
  BodyCase{patterns_start: U32, patterns_count: U32, body_id: U32, span: Ast.SourceSpan}
  BodyLocal{patterns_start: U32, patterns_count: U32, quantity: Ast.Quantity, values_start: U32, values_count: U32, body_id: U32, span: Ast.SourceSpan}
  BodyReply{term_id: U32, span: Ast.SourceSpan}

type Pattern is Data:
  PatternVar{key_id: U32, index: Nat, quantity: Ast.Quantity, span: Ast.SourceSpan}
  PatternCtr{key_id: U32, fields_start: U32, fields_count: U32, span: Ast.SourceSpan}

type Binder is Data:
  Binder{quantity: Ast.Quantity, key_id: U32, index: Nat, ty_id: U32, span: Ast.SourceSpan}
  TemplateBinder{key_id: U32, index: Nat, ty_id: U32, span: Ast.SourceSpan}

type NodePool is Type:
  NodePool{items: Array<Node>, used: U32, capacity: U32, depth: Nat}

type PatternPool is Type:
  PatternPool{items: Array<Pattern>, used: U32, capacity: U32, depth: Nat}

type BinderPool is Type:
  BinderPool{items: Array<Binder>, used: U32, capacity: U32, depth: Nat}

type WordPool is Type:
  WordPool{items: Array<U32>, used: U32, capacity: U32, depth: Nat}

type NaturalPool is Type:
  NaturalPool{items: Array<Nat>, used: U32, capacity: U32, depth: Nat}

type NamePool is Type:
  NamePool{items: Array<String>, used: U32, capacity: U32, depth: Nat}

# A slot owns only an exact signature and its live result handle, never an Arena.
# Nat index/depth remain arbitrary precision; hashes only choose a candidate.
# Transient-lane slots carry the rewind epoch they were written under, so a
# rewind invalidates them by generation instead of rewriting all 4096 slots.
type SubstMemoEntry is Data:
  SubstMemoEmpty{}
  SubstMemoSaved{node_id: U32, index: Nat, value_id: U32, depth: Nat, output_id: U32, epoch: Nat}
  CtrLeafSaved{key_id: U32, span: Ast.SourceSpan, output_id: U32}
  PublishedTerm{node_id: U32, output_id: U32, epoch: Nat}
  ScalarSchemaOpen{scope: Scope.ArenaGlobalScope}
  ScalarSchemaSaved{scope: Scope.ArenaGlobalScope, selected: Scope.ArenaGlobal, valid: Bool}
  StringSchemaSaved{scope: Scope.ArenaGlobalScope, selected: Scope.ArenaGlobal, valid: Bool}

# Scope-independent constructor-prefix summaries; source range tags stay in the
# exact key. Slots survive appends, but every rewind invalidates range reuse.
type CasePrefixEntry is Data:
  CasePrefixEmpty{}
  CasePrefixSaved{start: U32, count: U32, heads: Map<&2, U32>, barrier: U32, source_generation: Nat}

# Pool order: nodes, patterns, binders, words, naturals, names.
# counts[2 * pool] is used; counts[2 * pool + 1] is capacity.
# depths[pool] retains the Array allocation depth independently of rewind.
# depths[6] is a monotonically increasing rewind generation; pool growth keeps it.
# Primitive metadata arrays keep the threaded Arena layout bounded.
# Metadata lanes share their owning pool capacity/depth, are written on every
# append, and clear the identical discarded suffix on rewind. Published nodes,
# patterns, binders and their tape ranges are immutable; fill every reserved
# word/natural before publishing a descriptor. The substitution memo belongs to
# the transient declaration-local lifetime: each slot records depths[6] at put
# time and a rewind increments that generation, so every earlier slot is
# invisible without clearing the table. Snapshot lanes (scalar/string schema,
# source constructor leaves) live in the source arena, whose generation is fixed.
type Arena is Type:
  Arena{nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, counts: Array<U32>, depths: Array<Nat>, name_ids: Map<&2, U32>, node_closed: Array<U32>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>}

type Mark is Data:
  Mark{nodes: U32, patterns: U32, binders: U32, words: U32, naturals: U32, names: U32}

# Source helpers are dependency-ordered; recursion is self-recursive on Nat.

def empty_span() -> Ast.SourceSpan:
  Ast.SpanOf{SNil{}, 0n, 0n}

def empty() -> Arena:
  Arena{Array.new(Node, 0n, TermQuant{}), Array.new(Pattern, 0n, PatternVar{0, 0n, Ast.QZero{}, empty_span()}), Array.new(Binder, 0n, TemplateBinder{0, 0n, 0, empty_span()}), Array.new(U32, 0n, 0), Array.new(Nat, 0n, 0n), Array.new(String, 0n, SNil{}), Array.set(U32, Array.set(U32, Array.set(U32, Array.set(U32, Array.set(U32, Array.set(U32, Array.new(U32, 4n, 0), 1, 1), 3, 1), 5, 1), 7, 1), 9, 1), 11, 1), Array.new(Nat, 3n, 0n), Map.new(&2, U32), Array.new(U32, 0n, 0), Array.new(Nat, 0n, 0n), Array.new(Nat, 0n, 0n), Array.new(CasePrefixEntry, 6n, CasePrefixEmpty{}), Array.new(SubstMemoEntry, 12n, SubstMemoEmpty{})}

def node_pool.copy.loop(remaining: Nat, fresh: Array<Node>, +offset: U32, result: Array<Node> & Node) -> Array<Node>:
  match remaining:
    case 0n:
      match result:
        case Tuple{old, value}:
          Array.set(Node, fresh, offset, value)
    case 1n+rest:
      match result:
        case Tuple{old, value}:
          node_pool.copy.loop(rest, Array.set(Node, fresh, offset, value), U32.add(offset, 1), Array.get(Node, old, U32.add(offset, 1)))

def node_pool.copy(old: Array<Node>, fresh: Array<Node>, remaining: Nat, +offset: U32) -> Array<Node>:
  match remaining:
    case 0n: fresh
    case 1n+rest:
      node_pool.copy.loop(rest, fresh, offset, Array.get(Node, old, offset))

def node_pool.room_select(items: Array<Node>, used: U32, +capacity: U32, +depth: Nat, full: Bool) -> NodePool:
  match full:
    case False{}:
      NodePool{items, used, capacity, depth}
    case True{}:
      NodePool{node_pool.copy(items, Array.new(Node, Nat.add(depth, 1n), TermQuant{}), U32.to_nat(capacity), 0), used, U32.shl(capacity), Nat.add(depth, 1n)}

def node_pool.room(pool: NodePool) -> NodePool:
  match pool:
    case NodePool{items, +used, +capacity, depth}:
      node_pool.room_select(items, used, capacity, depth, U32.is_eq(used, capacity))

def node_pool.put_room(pool: NodePool, value: Node) -> NodePool & U32:
  match pool:
    case NodePool{items, +used, capacity, depth}:
      (NodePool{Array.set(Node, items, used, value), U32.add(used, 1), capacity, depth}, used)

def node_pool.put(pool: NodePool, value: Node) -> NodePool & U32:
  node_pool.put_room(node_pool.room(pool), value)



def node_pool.clear(remaining: Nat, items: Array<Node>, +offset: U32) -> Array<Node>:
  match remaining:
    case 0n: items
    case 1n+rest:
      node_pool.clear(rest, Array.set(Node, items, offset, TermQuant{}), U32.add(offset, 1))


def pattern_pool.copy.loop(remaining: Nat, fresh: Array<Pattern>, +offset: U32, result: Array<Pattern> & Pattern) -> Array<Pattern>:
  match remaining:
    case 0n:
      match result:
        case Tuple{old, value}:
          Array.set(Pattern, fresh, offset, value)
    case 1n+rest:
      match result:
        case Tuple{old, value}:
          pattern_pool.copy.loop(rest, Array.set(Pattern, fresh, offset, value), U32.add(offset, 1), Array.get(Pattern, old, U32.add(offset, 1)))

def pattern_pool.copy(old: Array<Pattern>, fresh: Array<Pattern>, remaining: Nat, +offset: U32) -> Array<Pattern>:
  match remaining:
    case 0n: fresh
    case 1n+rest:
      pattern_pool.copy.loop(rest, fresh, offset, Array.get(Pattern, old, offset))

def pattern_pool.room_select(items: Array<Pattern>, used: U32, +capacity: U32, +depth: Nat, full: Bool) -> PatternPool:
  match full:
    case False{}:
      PatternPool{items, used, capacity, depth}
    case True{}:
      PatternPool{pattern_pool.copy(items, Array.new(Pattern, Nat.add(depth, 1n), PatternVar{0, 0n, Ast.QZero{}, empty_span()}), U32.to_nat(capacity), 0), used, U32.shl(capacity), Nat.add(depth, 1n)}

def pattern_pool.room(pool: PatternPool) -> PatternPool:
  match pool:
    case PatternPool{items, +used, +capacity, depth}:
      pattern_pool.room_select(items, used, capacity, depth, U32.is_eq(used, capacity))

def pattern_pool.put_room(pool: PatternPool, value: Pattern) -> PatternPool & U32:
  match pool:
    case PatternPool{items, +used, capacity, depth}:
      (PatternPool{Array.set(Pattern, items, used, value), U32.add(used, 1), capacity, depth}, used)

def pattern_pool.put(pool: PatternPool, value: Pattern) -> PatternPool & U32:
  pattern_pool.put_room(pattern_pool.room(pool), value)



def pattern_pool.clear(remaining: Nat, items: Array<Pattern>, +offset: U32) -> Array<Pattern>:
  match remaining:
    case 0n: items
    case 1n+rest:
      pattern_pool.clear(rest, Array.set(Pattern, items, offset, PatternVar{0, 0n, Ast.QZero{}, empty_span()}), U32.add(offset, 1))


def binder_pool.copy.loop(remaining: Nat, fresh: Array<Binder>, +offset: U32, result: Array<Binder> & Binder) -> Array<Binder>:
  match remaining:
    case 0n:
      match result:
        case Tuple{old, value}:
          Array.set(Binder, fresh, offset, value)
    case 1n+rest:
      match result:
        case Tuple{old, value}:
          binder_pool.copy.loop(rest, Array.set(Binder, fresh, offset, value), U32.add(offset, 1), Array.get(Binder, old, U32.add(offset, 1)))

def binder_pool.copy(old: Array<Binder>, fresh: Array<Binder>, remaining: Nat, +offset: U32) -> Array<Binder>:
  match remaining:
    case 0n: fresh
    case 1n+rest:
      binder_pool.copy.loop(rest, fresh, offset, Array.get(Binder, old, offset))

def binder_pool.room_select(items: Array<Binder>, used: U32, +capacity: U32, +depth: Nat, full: Bool) -> BinderPool:
  match full:
    case False{}:
      BinderPool{items, used, capacity, depth}
    case True{}:
      BinderPool{binder_pool.copy(items, Array.new(Binder, Nat.add(depth, 1n), TemplateBinder{0, 0n, 0, empty_span()}), U32.to_nat(capacity), 0), used, U32.shl(capacity), Nat.add(depth, 1n)}

def binder_pool.room(pool: BinderPool) -> BinderPool:
  match pool:
    case BinderPool{items, +used, +capacity, depth}:
      binder_pool.room_select(items, used, capacity, depth, U32.is_eq(used, capacity))

def binder_pool.put_room(pool: BinderPool, value: Binder) -> BinderPool & U32:
  match pool:
    case BinderPool{items, +used, capacity, depth}:
      (BinderPool{Array.set(Binder, items, used, value), U32.add(used, 1), capacity, depth}, used)

def binder_pool.put(pool: BinderPool, value: Binder) -> BinderPool & U32:
  binder_pool.put_room(binder_pool.room(pool), value)



def binder_pool.clear(remaining: Nat, items: Array<Binder>, +offset: U32) -> Array<Binder>:
  match remaining:
    case 0n: items
    case 1n+rest:
      binder_pool.clear(rest, Array.set(Binder, items, offset, TemplateBinder{0, 0n, 0, empty_span()}), U32.add(offset, 1))


def word_pool.copy.loop(remaining: Nat, fresh: Array<U32>, +offset: U32, result: Array<U32> & U32) -> Array<U32>:
  match remaining:
    case 0n:
      match result:
        case Tuple{old, value}:
          Array.set(U32, fresh, offset, value)
    case 1n+rest:
      match result:
        case Tuple{old, value}:
          word_pool.copy.loop(rest, Array.set(U32, fresh, offset, value), U32.add(offset, 1), Array.get(U32, old, U32.add(offset, 1)))

def word_pool.copy(old: Array<U32>, fresh: Array<U32>, remaining: Nat, +offset: U32) -> Array<U32>:
  match remaining:
    case 0n: fresh
    case 1n+rest:
      word_pool.copy.loop(rest, fresh, offset, Array.get(U32, old, offset))

def word_pool.room_select(items: Array<U32>, used: U32, +capacity: U32, +depth: Nat, full: Bool) -> WordPool:
  match full:
    case False{}:
      WordPool{items, used, capacity, depth}
    case True{}:
      WordPool{word_pool.copy(items, Array.new(U32, Nat.add(depth, 1n), 0), U32.to_nat(capacity), 0), used, U32.shl(capacity), Nat.add(depth, 1n)}

def word_pool.room(pool: WordPool) -> WordPool:
  match pool:
    case WordPool{items, +used, +capacity, depth}:
      word_pool.room_select(items, used, capacity, depth, U32.is_eq(used, capacity))

def word_pool.put_room(pool: WordPool, value: U32) -> WordPool & U32:
  match pool:
    case WordPool{items, +used, capacity, depth}:
      (WordPool{Array.set(U32, items, used, value), U32.add(used, 1), capacity, depth}, used)

def word_pool.put(pool: WordPool, value: U32) -> WordPool & U32:
  word_pool.put_room(word_pool.room(pool), value)



def word_pool.clear(remaining: Nat, items: Array<U32>, +offset: U32) -> Array<U32>:
  match remaining:
    case 0n: items
    case 1n+rest:
      word_pool.clear(rest, Array.set(U32, items, offset, 0), U32.add(offset, 1))



def natural_pool.copy.loop(remaining: Nat, fresh: Array<Nat>, +offset: U32, result: Array<Nat> & Nat) -> Array<Nat>:
  match remaining:
    case 0n:
      match result:
        case Tuple{old, value}:
          Array.set(Nat, fresh, offset, value)
    case 1n+rest:
      match result:
        case Tuple{old, value}:
          natural_pool.copy.loop(rest, Array.set(Nat, fresh, offset, value), U32.add(offset, 1), Array.get(Nat, old, U32.add(offset, 1)))

def natural_pool.copy(old: Array<Nat>, fresh: Array<Nat>, remaining: Nat, +offset: U32) -> Array<Nat>:
  match remaining:
    case 0n: fresh
    case 1n+rest:
      natural_pool.copy.loop(rest, fresh, offset, Array.get(Nat, old, offset))

def natural_pool.room_select(items: Array<Nat>, used: U32, +capacity: U32, +depth: Nat, full: Bool) -> NaturalPool:
  match full:
    case False{}:
      NaturalPool{items, used, capacity, depth}
    case True{}:
      NaturalPool{natural_pool.copy(items, Array.new(Nat, Nat.add(depth, 1n), 0n), U32.to_nat(capacity), 0), used, U32.shl(capacity), Nat.add(depth, 1n)}

def natural_pool.room(pool: NaturalPool) -> NaturalPool:
  match pool:
    case NaturalPool{items, +used, +capacity, depth}:
      natural_pool.room_select(items, used, capacity, depth, U32.is_eq(used, capacity))

def natural_pool.put_room(pool: NaturalPool, value: Nat) -> NaturalPool & U32:
  match pool:
    case NaturalPool{items, +used, capacity, depth}:
      (NaturalPool{Array.set(Nat, items, used, value), U32.add(used, 1), capacity, depth}, used)

def natural_pool.put(pool: NaturalPool, value: Nat) -> NaturalPool & U32:
  natural_pool.put_room(natural_pool.room(pool), value)



def natural_pool.clear(remaining: Nat, items: Array<Nat>, +offset: U32) -> Array<Nat>:
  match remaining:
    case 0n: items
    case 1n+rest:
      natural_pool.clear(rest, Array.set(Nat, items, offset, 0n), U32.add(offset, 1))



def name_pool.copy.loop(remaining: Nat, fresh: Array<String>, +offset: U32, result: Array<String> & String) -> Array<String>:
  match remaining:
    case 0n:
      match result:
        case Tuple{old, value}:
          Array.set(String, fresh, offset, value)
    case 1n+rest:
      match result:
        case Tuple{old, value}:
          name_pool.copy.loop(rest, Array.set(String, fresh, offset, value), U32.add(offset, 1), Array.get(String, old, U32.add(offset, 1)))

def name_pool.copy(old: Array<String>, fresh: Array<String>, remaining: Nat, +offset: U32) -> Array<String>:
  match remaining:
    case 0n: fresh
    case 1n+rest:
      name_pool.copy.loop(rest, fresh, offset, Array.get(String, old, offset))

def name_pool.room_select(items: Array<String>, used: U32, +capacity: U32, +depth: Nat, full: Bool) -> NamePool:
  match full:
    case False{}:
      NamePool{items, used, capacity, depth}
    case True{}:
      NamePool{name_pool.copy(items, Array.new(String, Nat.add(depth, 1n), SNil{}), U32.to_nat(capacity), 0), used, U32.shl(capacity), Nat.add(depth, 1n)}

def name_pool.room(pool: NamePool) -> NamePool:
  match pool:
    case NamePool{items, +used, +capacity, depth}:
      name_pool.room_select(items, used, capacity, depth, U32.is_eq(used, capacity))

def name_pool.put_room(pool: NamePool, value: String) -> NamePool & U32:
  match pool:
    case NamePool{items, +used, capacity, depth}:
      (NamePool{Array.set(String, items, used, value), U32.add(used, 1), capacity, depth}, used)

def name_pool.put(pool: NamePool, value: String) -> NamePool & U32:
  name_pool.put_room(name_pool.room(pool), value)

def name_pool.get.result_1(used: U32, capacity: U32, depth: Nat, result: Array<String> & String) -> NamePool & String:
  match result:
    case Tuple{items2, value}:
      (NamePool{items2, used, capacity, depth}, value)

def name_pool.get(pool: NamePool, +id: U32) -> NamePool & String:
  match pool:
    case NamePool{items, used, capacity, depth}:
      name_pool.get.result_1(used, capacity, depth, Array.get(String, items, id))

def name_pool.clear(remaining: Nat, items: Array<String>, +offset: U32) -> Array<String>:
  match remaining:
    case 0n: items
    case 1n+rest:
      name_pool.clear(rest, Array.set(String, items, offset, SNil{}), U32.add(offset, 1))

def name_pool.rewind(pool: NamePool, +target: U32) -> NamePool:
  match pool:
    case NamePool{items, used, capacity, depth}:
      NamePool{name_pool.clear(U32.to_nat(U32.sub(used, target)), items, target), target, capacity, depth}

type MetadataRead is Type:
  MetadataRead{counts: Array<U32>, depths: Array<Nat>, used: U32, capacity: U32, depth: Nat}

type MetadataTables is Type:
  MetadataTables{counts: Array<U32>, depths: Array<Nat>}

def metadata_read.depth(counts: Array<U32>, used: U32, capacity: U32, result: Array<Nat> & Nat) -> MetadataRead:
  match result:
    case Tuple{depths, depth}: MetadataRead{counts, depths, used, capacity, depth}

def metadata_read.capacity(depths: Array<Nat>, +slot: U32, used: U32, result: Array<U32> & U32) -> MetadataRead:
  match result:
    case Tuple{counts, capacity}: metadata_read.depth(counts, used, capacity, Array.get(Nat, depths, slot))

def metadata_read.used(depths: Array<Nat>, +slot: U32, result: Array<U32> & U32) -> MetadataRead:
  match result:
    case Tuple{counts, used}: metadata_read.capacity(depths, slot, used, Array.get(U32, counts, U32.add(U32.mul(slot, 2), 1)))

def metadata_read(counts: Array<U32>, depths: Array<Nat>, +slot: U32) -> MetadataRead:
  metadata_read.used(depths, slot, Array.get(U32, counts, U32.mul(slot, 2)))

def metadata_write(counts: Array<U32>, depths: Array<Nat>, +slot: U32, used: U32, capacity: U32, depth: Nat) -> MetadataTables:
  MetadataTables{Array.set(U32, Array.set(U32, counts, U32.mul(slot, 2), used), U32.add(U32.mul(slot, 2), 1), capacity), Array.set(Nat, depths, slot, depth)}

def get_node.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, counts: Array<U32>, depths: Array<Nat>, name_ids: Map<&2, U32>, result: Array<Node> & Node) -> Arena & Node:
  match result:
    case Tuple{items, value}: (Arena{items, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, value)

def get_node(arena: Arena, +id: U32) -> Arena & Node:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      get_node.result(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, patterns, binders, words, naturals, names, counts, depths, name_ids, Array.get(Node, nodes, id))

def node_count.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, depths: Array<Nat>, name_ids: Map<&2, U32>, result: Array<U32> & U32) -> Arena & U32:
  match result:
    case Tuple{counts, used}: (Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, used)

def node_count(arena: Arena) -> Arena & U32:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      node_count.result(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, binders, words, naturals, names, depths, name_ids, Array.get(U32, counts, 0))

def get_pattern.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, counts: Array<U32>, depths: Array<Nat>, name_ids: Map<&2, U32>, result: Array<Pattern> & Pattern) -> Arena & Pattern:
  match result:
    case Tuple{items, value}: (Arena{nodes, items, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, value)

def get_pattern(arena: Arena, +id: U32) -> Arena & Pattern:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      get_pattern.result(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, binders, words, naturals, names, counts, depths, name_ids, Array.get(Pattern, patterns, id))

def pattern_count.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, depths: Array<Nat>, name_ids: Map<&2, U32>, result: Array<U32> & U32) -> Arena & U32:
  match result:
    case Tuple{counts, used}: (Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, used)

def pattern_count(arena: Arena) -> Arena & U32:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      pattern_count.result(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, binders, words, naturals, names, depths, name_ids, Array.get(U32, counts, 2))

def get_binder.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, counts: Array<U32>, depths: Array<Nat>, name_ids: Map<&2, U32>, result: Array<Binder> & Binder) -> Arena & Binder:
  match result:
    case Tuple{items, value}: (Arena{nodes, patterns, items, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, value)

def get_binder(arena: Arena, +id: U32) -> Arena & Binder:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      get_binder.result(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, words, naturals, names, counts, depths, name_ids, Array.get(Binder, binders, id))

def put_binder.tables(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, name_ids: Map<&2, U32>, id: U32, result: MetadataTables) -> Arena & U32:
  match result:
    case MetadataTables{counts, depths}: (Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, id)

def put_binder.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, counts: Array<U32>, depths: Array<Nat>, name_ids: Map<&2, U32>, result: BinderPool & U32) -> Arena & U32:
  match result:
    case Tuple{pool, id}:
      match pool:
        case BinderPool{items, used, capacity, depth}:
          put_binder.tables(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, items, words, naturals, names, name_ids, id, metadata_write(counts, depths, 2, used, capacity, depth))

def put_binder.metadata(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, name_ids: Map<&2, U32>, value: Binder, result: MetadataRead) -> Arena & U32:
  match result:
    case MetadataRead{counts, depths, used, capacity, depth}:
      put_binder.result(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, words, naturals, names, counts, depths, name_ids, binder_pool.put(BinderPool{binders, used, capacity, depth}, value))

def put_binder(arena: Arena, value: Binder) -> Arena & U32:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      put_binder.metadata(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, binders, words, naturals, names, name_ids, value, metadata_read(counts, depths, 2))

def binder_count.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, depths: Array<Nat>, name_ids: Map<&2, U32>, result: Array<U32> & U32) -> Arena & U32:
  match result:
    case Tuple{counts, used}: (Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, used)

def binder_count(arena: Arena) -> Arena & U32:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      binder_count.result(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, binders, words, naturals, names, depths, name_ids, Array.get(U32, counts, 4))

def word.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, naturals: Array<Nat>, names: Array<String>, counts: Array<U32>, depths: Array<Nat>, name_ids: Map<&2, U32>, result: Array<U32> & U32) -> Arena & U32:
  match result:
    case Tuple{items, value}: (Arena{nodes, patterns, binders, items, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, value)

def word(arena: Arena, +id: U32) -> Arena & U32:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      word.result(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, binders, naturals, names, counts, depths, name_ids, Array.get(U32, words, id))

def put_word.tables(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, name_ids: Map<&2, U32>, id: U32, result: MetadataTables) -> Arena & U32:
  match result:
    case MetadataTables{counts, depths}: (Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, id)

def put_word.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, naturals: Array<Nat>, names: Array<String>, counts: Array<U32>, depths: Array<Nat>, name_ids: Map<&2, U32>, result: WordPool & U32) -> Arena & U32:
  match result:
    case Tuple{pool, id}:
      match pool:
        case WordPool{items, used, capacity, depth}:
          put_word.tables(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, binders, items, naturals, names, name_ids, id, metadata_write(counts, depths, 3, used, capacity, depth))

def put_word.metadata(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, name_ids: Map<&2, U32>, value: U32, result: MetadataRead) -> Arena & U32:
  match result:
    case MetadataRead{counts, depths, used, capacity, depth}:
      put_word.result(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, binders, naturals, names, counts, depths, name_ids, word_pool.put(WordPool{words, used, capacity, depth}, value))

def put_word(arena: Arena, value: U32) -> Arena & U32:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      put_word.metadata(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, binders, words, naturals, names, name_ids, value, metadata_read(counts, depths, 3))

def word_count.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, depths: Array<Nat>, name_ids: Map<&2, U32>, result: Array<U32> & U32) -> Arena & U32:
  match result:
    case Tuple{counts, used}: (Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, used)

def word_count(arena: Arena) -> Arena & U32:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      word_count.result(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, binders, words, naturals, names, depths, name_ids, Array.get(U32, counts, 6))

# One U32 per node slot: bits 1/2 certify local/childless closed nodes,
# bits 4/8 certify trusted bounds/closed terms, and bit 16 certifies an immutable
# SOURCE-only constructor tree. Queries always retain their original region tag.
def node_is_closed.mask.select(local: Bool) -> U32:
  match local:
    case True{}: 1
    case False{}: 2

def node_is_closed.mask(id: U32) -> U32:
  node_is_closed.mask.select(U32.is_eq(U32.and(id, 2147483648), 0))

def node_is_closed.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, mask: U32, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, counts: Array<U32>, depths: Array<Nat>, name_ids: Map<&2, U32>, result: Array<U32> & U32) -> Arena & Bool:
  match result:
    case Tuple{node_closed, flags}:
      (Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, U32.is_ne(U32.and(flags, mask), 0))

def node_is_closed.local(arena: Arena, +id: U32) -> Arena & Bool:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      node_is_closed.result(case_prefix, subst_memo, node_bounds, pattern_depths, node_is_closed.mask(id), nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, Array.get(U32, node_closed, U32.and(id, 2147483647)))

def node_is_closed.count.order(arena: Arena, +id: U32, order: Cmp) -> Arena & Bool:
  match order:
    case LT{}: node_is_closed.local(arena, id)
    case _: (arena, False{})

def node_is_closed.count(+id: U32, result: Arena & U32) -> Arena & Bool:
  match result:
    case Tuple{arena, used}:
      node_is_closed.count.order(arena, id, U32.cmp(U32.and(id, 2147483647), used))

def node_is_closed(arena: Arena, +id: U32) -> Arena & Bool:
  node_is_closed.count(id, node_count(arena))

# Store certificates use independent flags: 4 trusts the encoded bound; 8
# authorizes closed compound transient terms. Local source/leaf bits stay 1/2.
def node_has_flag.local(arena: Arena, +id: U32, mask: U32) -> Arena & Bool:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      node_is_closed.result(case_prefix, subst_memo, node_bounds, pattern_depths, mask, nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, Array.get(U32, node_closed, id))

def node_has_flag.order(arena: Arena, id: U32, mask: U32, order: Cmp) -> Arena & Bool:
  match order:
    case LT{}: node_has_flag.local(arena, id, mask)
    case _: (arena, False{})

def node_has_flag.count(+id: U32, mask: U32, result: Arena & U32) -> Arena & Bool:
  match result:
    case Tuple{arena, used}: node_has_flag.order(arena, id, mask, U32.cmp(id, used))

def node_has_flag(arena: Arena, id: U32, mask: U32) -> Arena & Bool:
  node_has_flag.count(id, mask, node_count(arena))

def node_is_trusted_closed(arena: Arena, id: U32) -> Arena & Bool:
  node_has_flag(arena, U32.and(id, 2147483647), 10)

# Add the positive constructor-tree witness without touching descriptor or bound
# lanes. Callers prove the complete source tree first; bounded writes reject
# tagged, unknown and discarded IDs rather than masking them into live slots.
def node_ctor_certify.flags(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, +id: U32, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, counts: Array<U32>, depths: Array<Nat>, name_ids: Map<&2, U32>, result: Array<U32> & U32) -> Arena:
  match result:
    case Tuple{node_closed, flags}:
      Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, Array.set(U32, node_closed, id, U32.or(flags, 16)), node_bounds, pattern_depths, case_prefix, subst_memo}

def node_ctor_certify.local(arena: Arena, +id: U32) -> Arena:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      node_ctor_certify.flags(case_prefix, subst_memo, node_bounds, pattern_depths, id, nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, Array.get(U32, node_closed, id))

def node_ctor_certify.order(arena: Arena, id: U32, order: Cmp) -> Arena:
  match order:
    case LT{}: node_ctor_certify.local(arena, id)
    case _: arena

def node_ctor_certify.count(+id: U32, result: Arena & U32) -> Arena:
  match result:
    case Tuple{arena, used}: node_ctor_certify.order(arena, id, U32.cmp(id, used))

def node_ctor_certify.source(arena: Arena, id: U32, local: Bool) -> Arena:
  match local:
    case False{}: arena
    case True{}: node_ctor_certify.count(id, node_count(arena))

def node_ctor_certify(arena: Arena, +id: U32) -> Arena:
  node_ctor_certify.source(arena, id, U32.is_eq(U32.and(id, 2147483648), 0))

# Encoded Nat metadata: 0 means uncertified; 1+bound means a known local
# free-variable bound (node lane) or binder count (pattern lane). No Nat index
# is narrowed. The separate U32 flags cache exactly the closed/leaf predicates.
def bound_max.select(left: Nat, right: Nat, greater: Bool) -> Nat:
  match greater:
    case True{}: left
    case False{}: right

def bound_max(+left: Nat, +right: Nat) -> Nat:
  bound_max.select(left, right, Nat.is_ge(left, right))

def bound_read.node.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, counts: Array<U32>, depths: Array<Nat>, name_ids: Map<&2, U32>, node_closed: Array<U32>, pattern_depths: Array<Nat>, result: Array<Nat> & Nat) -> Arena & Nat:
  match result:
    case Tuple{node_bounds, value}: (Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, value)

def bound_read.node(arena: Arena, id: U32) -> Arena & Nat:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      bound_read.node.result(case_prefix, subst_memo, nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, pattern_depths, Array.get(Nat, node_bounds, id))

def bound_read.pattern.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, counts: Array<U32>, depths: Array<Nat>, name_ids: Map<&2, U32>, node_closed: Array<U32>, node_bounds: Array<Nat>, result: Array<Nat> & Nat) -> Arena & Nat:
  match result:
    case Tuple{pattern_depths, value}: (Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, value)

def bound_read.pattern(arena: Arena, id: U32) -> Arena & Nat:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      bound_read.pattern.result(case_prefix, subst_memo, nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, Array.get(Nat, pattern_depths, id))

def bound_read.pool(arena: Arena, id: U32, pattern: Bool) -> Arena & Nat:
  match pattern:
    case False{}: bound_read.node(arena, id)
    case True{}: bound_read.pattern(arena, id)

def bound_read.order(arena: Arena, id: U32, pattern: Bool, order: Cmp) -> Arena & Nat:
  match order:
    case LT{}: bound_read.pool(arena, id, pattern)
    case _: (arena, 0n)

def bound_read.count(+id: U32, pattern: Bool, result: Arena & U32) -> Arena & Nat:
  match result:
    case Tuple{arena, used}: bound_read.order(arena, id, pattern, U32.cmp(id, used))

def bound_read.kind(arena: Arena, id: U32, pattern: Bool) -> Arena & Nat:
  match pattern:
    case False{}: bound_read.count(id, False{}, node_count(arena))
    case True{}: bound_read.count(id, True{}, pattern_count(arena))

def bound_read.local(arena: Arena, id: U32, pattern: Bool, local: Bool) -> Arena & Nat:
  match local:
    case False{}: (arena, 0n)
    case True{}: bound_read.kind(arena, id, pattern)

def bound_read(arena: Arena, +id: U32, pattern: Bool) -> Arena & Nat:
  bound_read.local(arena, id, pattern, U32.is_eq(U32.and(id, 2147483648), 0))

def node_bound.flag(+id: U32, result: Arena & Bool) -> Arena & Nat:
  match result:
    case Tuple{arena, trusted}:
      match trusted:
        case False{}: (arena, 0n)
        case True{}: bound_read.node(arena, id)

# These accessors take owner-local IDs, after the store chooses the region.
def node_bound(arena: Arena, +id: U32, trusted: Bool) -> Arena & Nat:
  match trusted:
    case False{}: bound_read.kind(arena, id, False{})
    case True{}: node_bound.flag(id, node_has_flag(arena, id, 4))

def node_certificate_flags.bound(bound: Nat) -> U32:
  match bound:
    case 0n: 12
    case 1n+_: 4

def node_certificate_flags(encoded: Nat) -> U32:
  match encoded:
    case 0n: 0
    case 1n+bound: node_certificate_flags.bound(bound)

def node_certify.flags(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, +id: U32, +encoded: Nat, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, counts: Array<U32>, depths: Array<Nat>, name_ids: Map<&2, U32>, result: Array<U32> & U32) -> Arena:
  match result:
    case Tuple{node_closed, flags}:
      Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, Array.set(U32, node_closed, id, U32.or(U32.and(flags, 19), node_certificate_flags(encoded))), Array.set(Nat, node_bounds, id, encoded), pattern_depths, case_prefix, subst_memo}

def node_certify.local(arena: Arena, +id: U32, +encoded: Nat) -> Arena:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      node_certify.flags(case_prefix, subst_memo, node_bounds, pattern_depths, id, encoded, nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, Array.get(U32, node_closed, id))

def node_certify.order(arena: Arena, +id: U32, +encoded: Nat, order: Cmp) -> Arena:
  match order:
    case LT{}: node_certify.local(arena, id, encoded)
    case _: arena

def node_certify.count(+id: U32, encoded: Nat, result: Arena & U32) -> Arena:
  match result:
    case Tuple{arena, used}: node_certify.order(arena, id, encoded, U32.cmp(id, used))

def node_certify(arena: Arena, id: U32, encoded: Nat) -> Arena:
  node_certify.count(id, encoded, node_count(arena))

def bound_merge.result(left: Nat, result: Arena & Nat) -> Arena & Nat:
  match result:
    case Tuple{arena, encoded}:
      match encoded:
        case 0n: (arena, 0n)
        case 1n+right: (arena, Nat.add(bound_max(left, right), 1n))

def bound_node.then(id: U32, result: Arena & Nat) -> Arena & Nat:
  match result:
    case Tuple{arena, encoded}:
      match encoded:
        case 0n: (arena, 0n)
        case 1n+left: bound_merge.result(left, bound_read(arena, id, False{}))

def bound_node.two(arena: Arena, first: U32, second: U32) -> Arena & Nat:
  bound_node.then(second, bound_read(arena, first, False{}))

def bound_node.three(arena: Arena, first: U32, second: U32, third: U32) -> Arena & Nat:
  bound_node.then(third, bound_node.two(arena, first, second))

def bound_node.remove(depth: Nat, result: Arena & Nat) -> Arena & Nat:
  match result:
    case Tuple{arena, encoded}:
      match encoded:
        case 0n: (arena, 0n)
        case 1n+bound: (arena, Nat.add(Nat.sub(bound, depth), 1n))

def bound_node.binder.first(body: U32, depth: Nat, result: Arena & Nat) -> Arena & Nat:
  match result:
    case Tuple{arena, encoded}:
      match encoded:
        case 0n: (arena, 0n)
        case 1n+left: bound_merge.result(left, bound_node.remove(depth, bound_read(arena, body, False{})))

def bound_range.combine.kind(arena: Arena, left: Nat, right: Nat, pattern: Bool) -> Arena & Nat:
  match pattern:
    case False{}: (arena, Nat.add(bound_max(left, right), 1n))
    case True{}: (arena, Nat.add(Nat.add(left, right), 1n))

def bound_range.combine(left: Nat, pattern: Bool, result: Arena & Nat) -> Arena & Nat:
  match result:
    case Tuple{arena, encoded}:
      match encoded:
        case 0n: (arena, 0n)
        case 1n+right: bound_range.combine.kind(arena, left, right, pattern)

def bound_range.word(left: Nat, +pattern: Bool, result: Arena & U32) -> Arena & Nat:
  match result:
    case Tuple{arena, id}: bound_range.combine(left, pattern, bound_read(arena, id, pattern))

def bound_range.loop(remaining: Nat, +offset: U32, +stride: U32, +pattern: Bool, result: Arena & Nat) -> Arena & Nat:
  match remaining:
    case 0n: result
    case 1n+rest:
      match result:
        case Tuple{arena, encoded}:
          match encoded:
            case 0n: (arena, 0n)
            case 1n+left:
              bound_range.loop(rest, U32.add(offset, stride), stride, pattern, bound_range.word(left, pattern, word(arena, offset)))

def bound_range.length(arena: Arena, start: U32, count: U32, stride: U32, pattern: Bool, order: Cmp) -> Arena & Nat:
  match order:
    case GT{}: (arena, 0n)
    case _: bound_range.loop(U32.to_nat(count), start, stride, pattern, (arena, 1n))

def bound_range.forward.start(arena: Arena, +start: U32, +count: U32, used: U32, pattern: Bool, order: Cmp) -> Arena & Nat:
  match order:
    case GT{}: (arena, 0n)
    case _: bound_range.length(arena, start, count, 1, pattern, U32.cmp(count, U32.sub(used, start)))

def bound_range.forward(+start: U32, count: U32, pattern: Bool, result: Arena & U32) -> Arena & Nat:
  match result:
    case Tuple{arena, +used}: bound_range.forward.start(arena, start, count, used, pattern, U32.cmp(start, used))

def bound_range.reverse.start(arena: Arena, +start: U32, +count: U32, pattern: Bool, order: Cmp) -> Arena & Nat:
  match order:
    case LT{}: bound_range.length(arena, start, count, 4294967295, pattern, U32.cmp(count, U32.add(start, 1)))
    case _: (arena, 0n)

def bound_range.reverse(+start: U32, count: U32, pattern: Bool, result: Arena & U32) -> Arena & Nat:
  match result:
    case Tuple{arena, used}: bound_range.reverse.start(arena, start, count, pattern, U32.cmp(start, used))

def bound_range.direction(start: U32, count: U32, pattern: Bool, result: Arena & U32, forward: Bool) -> Arena & Nat:
  match forward:
    case True{}: bound_range.forward(start, count, pattern, result)
    case False{}: bound_range.reverse(U32.and(start, 1073741823), count, pattern, result)

def bound_range.count(+start: U32, count: U32, pattern: Bool, result: Arena & U32) -> Arena & Nat:
  bound_range.direction(start, count, pattern, result, U32.is_eq(U32.and(start, 1073741824), 0))

def bound_range.local(arena: Arena, start: U32, count: U32, pattern: Bool, local: Bool) -> Arena & Nat:
  match local:
    case False{}: (arena, 0n)
    case True{}: bound_range.count(start, count, pattern, word_count(arena))

def bound_range.empty(arena: Arena, +start: U32, count: U32, pattern: Bool, empty: Bool) -> Arena & Nat:
  match empty:
    case True{}: (arena, 1n)
    case False{}: bound_range.local(arena, start, count, pattern, U32.is_eq(U32.and(start, 2147483648), 0))

def bound_range(arena: Arena, start: U32, +count: U32, pattern: Bool) -> Arena & Nat:
  bound_range.empty(arena, start, count, pattern, U32.is_eq(count, 0))

def bound_range.then(start: U32, count: U32, result: Arena & Nat) -> Arena & Nat:
  match result:
    case Tuple{arena, encoded}:
      match encoded:
        case 0n: (arena, 0n)
        case 1n+left: bound_merge.result(left, bound_range(arena, start, count, False{}))

def bound_pattern.body(body: U32, result: Arena & Nat) -> Arena & Nat:
  match result:
    case Tuple{arena, encoded}:
      match encoded:
        case 0n: (arena, 0n)
        case 1n+depth: bound_node.remove(depth, bound_read(arena, body, False{}))

def bound_pattern.local.body(body: U32, values_start: U32, values_count: U32, result: Arena & Nat) -> Arena & Nat:
  match result:
    case Tuple{arena, encoded}:
      match encoded:
        case 0n: (arena, 0n)
        case 1n+depth: bound_node.binder.first(body, depth, bound_range(arena, values_start, values_count, False{}))

def bound_pattern.value(arena: Arena, value: Pattern) -> Arena & Nat:
  match value:
    case PatternVar{_, _, _, _}: (arena, 2n)
    case PatternCtr{_, fields_start, fields_count, _}: bound_range(arena, fields_start, fields_count, True{})

def bound_node.value(arena: Arena, value: Node) -> Arena & Nat:
  match value:
    case TermVar{_, index, _}: (arena, Nat.add(index, 2n))
    case TermRef{_, _}: (arena, 1n)
    case TermBang{term_id, _}: bound_read(arena, term_id, False{})
    case TermSub{_, value_id, body_id, _}: bound_node.binder.first(body_id, 1n, bound_read(arena, value_id, False{}))
    case TermLet{_, keys_count, _, _, _, _, values_start, values_count, body_id, _}: bound_node.binder.first(body_id, U32.to_nat(keys_count), bound_range(arena, values_start, values_count, False{}))
    case TermAnn{term_id, ty_id, _}: bound_node.two(arena, term_id, ty_id)
    case TermTemplate{term_id, _}: bound_read(arena, term_id, False{})
    case TermType{kind_id, _}: bound_read(arena, kind_id, False{})
    case TermQuant{}: (arena, 1n)
    case TermQuantity{_, _}: (arena, 1n)
    case TermMin{left_id, right_id, _}: bound_node.two(arena, left_id, right_id)
    case TermAll{_, _, _, ty_id, body_id, _}: bound_node.binder.first(body_id, 1n, bound_read(arena, ty_id, False{}))
    case TermLam{_, _, _, body_id, _}: bound_node.remove(1n, bound_read(arena, body_id, False{}))
    case TermApp{fn_id, arg_id, _}: bound_node.two(arena, fn_id, arg_id)
    case TermAdt{_, args_start, args_count, _, _, _}: bound_range(arena, args_start, args_count, False{})
    case TermFill{head_id, args_start, args_count, _}: bound_range.then(args_start, args_count, bound_read(arena, head_id, False{}))
    case TermPlus{head_id, args_start, args_count, _}: bound_range.then(args_start, args_count, bound_read(arena, head_id, False{}))
    case TermCtr{_, args_start, args_count, _}: bound_range(arena, args_start, args_count, False{})
    case TermString{_, _, _}: (arena, 1n)
    case TermMat{_, head_id, matched_id, _}: bound_node.two(arena, head_id, matched_id)
    case TermAbsurd{_}: (arena, 1n)
    case TermEqual{left_id, right_id, ty_id, _}: bound_node.three(arena, left_id, right_id, ty_id)
    case TermRefl{_}: (arena, 1n)
    case TermRewrite{equation_id, proof_id, body_id, _}: bound_node.three(arena, equation_id, proof_id, body_id)
    case TermHole{_, _}: (arena, 1n)
    case BodyMatch{scrutinees_start, scrutinees_count, cases_start, cases_count, _}: bound_range.then(cases_start, cases_count, bound_range(arena, scrutinees_start, scrutinees_count, False{}))
    case BodyCase{patterns_start, patterns_count, body_id, _}: bound_pattern.body(body_id, bound_range(arena, patterns_start, patterns_count, True{}))
    case BodyLocal{patterns_start, patterns_count, _, values_start, values_count, body_id, _}: bound_pattern.local.body(body_id, values_start, values_count, bound_range(arena, patterns_start, patterns_count, True{}))
    case BodyReply{term_id, _}: bound_read(arena, term_id, False{})

def node_closed.leaf(value: Node) -> U32:
  match value:
    case TermRef{_, _}: 3
    case TermQuant{}: 3
    case TermQuantity{_, _}: 3
    case TermAbsurd{_}: 3
    case TermRefl{_}: 3
    case TermHole{_, _}: 3
    case _: 1

def node_closed.flags.bound(bound: Nat, leaf: U32) -> U32:
  match bound:
    case 0n: leaf
    case 1n+_: 0

def node_closed.flags(encoded: Nat, leaf: U32) -> U32:
  match encoded:
    case 0n: 0
    case 1n+bound: node_closed.flags.bound(bound, leaf)

def bound_pool.room.select(items: Array<Nat>, capacity: U32, +depth: Nat, full: Bool) -> Array<Nat>:
  match full:
    case False{}: items
    case True{}: natural_pool.copy(items, Array.new(Nat, Nat.add(depth, 1n), 0n), U32.to_nat(capacity), 0)

def bound_pool.room(items: Array<Nat>, used: U32, +capacity: U32, depth: Nat) -> Array<Nat>:
  bound_pool.room.select(items, capacity, depth, U32.is_eq(used, capacity))

def put_pattern.tables(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, name_ids: Map<&2, U32>, id: U32, result: MetadataTables) -> Arena & U32:
  match result:
    case MetadataTables{counts, depths}: (Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, id)

def put_pattern.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, counts: Array<U32>, depths: Array<Nat>, name_ids: Map<&2, U32>, result: PatternPool & U32) -> Arena & U32:
  match result:
    case Tuple{pool, id}:
      match pool:
        case PatternPool{items, used, capacity, depth}:
          put_pattern.tables(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, items, binders, words, naturals, names, name_ids, id, metadata_write(counts, depths, 1, used, capacity, depth))

def put_pattern.metadata(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, encoded: Nat, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, name_ids: Map<&2, U32>, value: Pattern, result: MetadataRead) -> Arena & U32:
  match result:
    case MetadataRead{counts, depths, +used, +capacity, +depth}:
      put_pattern.result(case_prefix, subst_memo, node_bounds, Array.set(Nat, bound_pool.room(pattern_depths, used, capacity, depth), used, encoded), node_closed, nodes, binders, words, naturals, names, counts, depths, name_ids, pattern_pool.put(PatternPool{patterns, used, capacity, depth}, value))

def put_pattern.bound_append(arena: Arena, value: Pattern, encoded: Nat) -> Arena & U32:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      put_pattern.metadata(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, encoded, nodes, patterns, binders, words, naturals, names, name_ids, value, metadata_read(counts, depths, 1))

def put_pattern.bound_result(value: Pattern, result: Arena & Nat) -> Arena & U32:
  match result:
    case Tuple{arena, encoded}: put_pattern.bound_append(arena, value, encoded)

def put_pattern(arena: Arena, +value: Pattern) -> Arena & U32:
  put_pattern.bound_result(value, bound_pattern.value(arena, value))

def node_closed.room.select(items: Array<U32>, capacity: U32, +depth: Nat, full: Bool) -> Array<U32>:
  match full:
    case False{}: items
    case True{}: word_pool.copy(items, Array.new(U32, Nat.add(depth, 1n), 0), U32.to_nat(capacity), 0)

def node_closed.room(items: Array<U32>, used: U32, +capacity: U32, depth: Nat) -> Array<U32>:
  node_closed.room.select(items, capacity, depth, U32.is_eq(used, capacity))

def put_node.tables(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, name_ids: Map<&2, U32>, id: U32, result: MetadataTables) -> Arena & U32:
  match result:
    case MetadataTables{counts, depths}: (Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, id)

def put_node.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, counts: Array<U32>, depths: Array<Nat>, name_ids: Map<&2, U32>, result: NodePool & U32) -> Arena & U32:
  match result:
    case Tuple{pool, id}:
      match pool:
        case NodePool{items, used, capacity, depth}:
          put_node.tables(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, items, patterns, binders, words, naturals, names, name_ids, id, metadata_write(counts, depths, 0, used, capacity, depth))

def put_node.metadata(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, flags: U32, encoded: Nat, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, name_ids: Map<&2, U32>, value: Node, result: MetadataRead) -> Arena & U32:
  match result:
    case MetadataRead{counts, depths, +used, +capacity, +depth}:
      put_node.result(case_prefix, subst_memo, Array.set(Nat, bound_pool.room(node_bounds, used, capacity, depth), used, encoded), pattern_depths, Array.set(U32, node_closed.room(node_closed, used, capacity, depth), used, flags), patterns, binders, words, naturals, names, counts, depths, name_ids, node_pool.put(NodePool{nodes, used, capacity, depth}, value))

def put_node.closed_append(arena: Arena, value: Node, flags: U32, encoded: Nat) -> Arena & U32:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      put_node.metadata(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, flags, encoded, nodes, patterns, binders, words, naturals, names, name_ids, value, metadata_read(counts, depths, 0))

def put_node.closed_result(+value: Node, result: Arena & Nat) -> Arena & U32:
  match result:
    case Tuple{arena, +encoded}:
      put_node.closed_append(arena, value, node_closed.flags(encoded, node_closed.leaf(value)), encoded)

def put_node(arena: Arena, +value: Node) -> Arena & U32:
  put_node.closed_result(value, bound_node.value(arena, value))

# The store computes this bound from the original descriptor and full-tagged
# children before append. Do not repeat the arena-local (source-only) traversal.
def put_node_certified(arena: Arena, +value: Node, +encoded: Nat) -> Arena & U32:
  put_node.closed_append(arena, value, U32.or(node_closed.flags(encoded, node_closed.leaf(value)), node_certificate_flags(encoded)), encoded)


def set_word(arena: Arena, id: U32, value: U32) -> Arena:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}: Arena{nodes, patterns, binders, Array.set(U32, words, id, value), naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}

def natural.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, names: Array<String>, counts: Array<U32>, depths: Array<Nat>, name_ids: Map<&2, U32>, result: Array<Nat> & Nat) -> Arena & Nat:
  match result:
    case Tuple{items, value}: (Arena{nodes, patterns, binders, words, items, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, value)

def natural(arena: Arena, +id: U32) -> Arena & Nat:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      natural.result(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, binders, words, names, counts, depths, name_ids, Array.get(Nat, naturals, id))

def put_natural.tables(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, name_ids: Map<&2, U32>, id: U32, result: MetadataTables) -> Arena & U32:
  match result:
    case MetadataTables{counts, depths}: (Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, id)

def put_natural.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, names: Array<String>, counts: Array<U32>, depths: Array<Nat>, name_ids: Map<&2, U32>, result: NaturalPool & U32) -> Arena & U32:
  match result:
    case Tuple{pool, id}:
      match pool:
        case NaturalPool{items, used, capacity, depth}:
          put_natural.tables(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, binders, words, items, names, name_ids, id, metadata_write(counts, depths, 4, used, capacity, depth))

def put_natural.metadata(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, name_ids: Map<&2, U32>, value: Nat, result: MetadataRead) -> Arena & U32:
  match result:
    case MetadataRead{counts, depths, used, capacity, depth}:
      put_natural.result(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, binders, words, names, counts, depths, name_ids, natural_pool.put(NaturalPool{naturals, used, capacity, depth}, value))

def put_natural(arena: Arena, value: Nat) -> Arena & U32:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      put_natural.metadata(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, binders, words, naturals, names, name_ids, value, metadata_read(counts, depths, 4))

def natural_count.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, depths: Array<Nat>, name_ids: Map<&2, U32>, result: Array<U32> & U32) -> Arena & U32:
  match result:
    case Tuple{counts, used}: (Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, used)

def natural_count(arena: Arena) -> Arena & U32:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      natural_count.result(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, binders, words, naturals, names, depths, name_ids, Array.get(U32, counts, 8))

def set_natural(arena: Arena, id: U32, value: Nat) -> Arena:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}: Arena{nodes, patterns, binders, words, Array.set(Nat, naturals, id, value), names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}

def name_text.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, counts: Array<U32>, depths: Array<Nat>, name_ids: Map<&2, U32>, result: Array<String> & String) -> Arena & String:
  match result:
    case Tuple{items, value}: (Arena{nodes, patterns, binders, words, naturals, items, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, value)

def name_text(arena: Arena, +id: U32) -> Arena & String:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      name_text.result(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, binders, words, naturals, counts, depths, name_ids, Array.get(String, names, id))

def put_name_value.tables(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, name_ids: Map<&2, U32>, id: U32, result: MetadataTables) -> Arena & U32:
  match result:
    case MetadataTables{counts, depths}: (Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, id)

def put_name_value.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, counts: Array<U32>, depths: Array<Nat>, name_ids: Map<&2, U32>, result: NamePool & U32) -> Arena & U32:
  match result:
    case Tuple{pool, id}:
      match pool:
        case NamePool{items, used, capacity, depth}:
          put_name_value.tables(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, binders, words, naturals, items, name_ids, id, metadata_write(counts, depths, 5, used, capacity, depth))

def put_name_value.metadata(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, name_ids: Map<&2, U32>, value: String, result: MetadataRead) -> Arena & U32:
  match result:
    case MetadataRead{counts, depths, used, capacity, depth}:
      put_name_value.result(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, binders, words, naturals, counts, depths, name_ids, name_pool.put(NamePool{names, used, capacity, depth}, value))

def put_name_value(arena: Arena, value: String) -> Arena & U32:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      put_name_value.metadata(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, binders, words, naturals, names, name_ids, value, metadata_read(counts, depths, 5))

def name_count.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, depths: Array<Nat>, name_ids: Map<&2, U32>, result: Array<U32> & U32) -> Arena & U32:
  match result:
    case Tuple{counts, used}: (Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, used)

def name_count(arena: Arena) -> Arena & U32:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      name_count.result(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, binders, words, naturals, names, depths, name_ids, Array.get(U32, counts, 10))

def name.insert(+text: String, result: Arena & U32) -> Arena & U32:
  match result:
    case Tuple{arena, +id}:
      match arena:
        case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}: (Arena{nodes, patterns, binders, words, naturals, names, counts, depths, Map.set(&2, U32, name_ids, text, id), node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, id)

def name.found(arena: Arena, +text: String, +id: U32, missing: Bool) -> Arena & U32:
  match missing:
    case False{}: (arena, id)
    case True{}: name.insert(text, put_name_value(arena, text))

def name.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, +text: String, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, counts: Array<U32>, depths: Array<Nat>, result: Map<&2, U32> & U32) -> Arena & U32:
  match result:
    case Tuple{name_ids, +id}: name.found(Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, text, id, U32.is_eq(id, 4294967295))

def name(arena: Arena, +text: String) -> Arena & U32:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      name.result(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, text, nodes, patterns, binders, words, naturals, names, counts, depths, Map.get(U32, 4294967295, name_ids, text))

# Reserve through the pool so Arena metadata is published only once. Every slot
# is written even when existing capacity contains a discarded or stale value.
def word_pool.reserve.zero(pool: WordPool) -> WordPool:
  match pool:
    case WordPool{items, +used, capacity, depth}:
      WordPool{Array.set(U32, items, used, 0), U32.add(used, 1), capacity, depth}

def word_pool.reserve(remaining: Nat, pool: WordPool) -> WordPool:
  match remaining:
    case 0n: pool
    case 1n+rest:
      word_pool.reserve(rest, word_pool.reserve.zero(word_pool.room(pool)))

def reserve_words.metadata(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, name_ids: Map<&2, U32>, count: U32, result: MetadataRead) -> Arena & U32:
  match result:
    case MetadataRead{counts, depths, +used, capacity, depth}:
      put_word.result(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, binders, naturals, names, counts, depths, name_ids, (word_pool.reserve(U32.to_nat(count), WordPool{words, used, capacity, depth}), used))

def reserve_words(arena: Arena, +count: U32) -> Arena & U32:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      reserve_words.metadata(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, binders, words, naturals, names, name_ids, count, metadata_read(counts, depths, 3))

def reserve_naturals.loop(remaining: Nat, result: Arena & U32) -> Arena:
  match remaining:
    case 0n:
      match result:
        case Tuple{arena, _}: arena
    case 1n+rest:
      match result:
        case Tuple{arena, _}:
          reserve_naturals.loop(rest, put_natural(arena, 0n))

def reserve_naturals.go(arena: Arena, remaining: Nat) -> Arena:
  match remaining:
    case 0n: arena
    case 1n+rest:
      reserve_naturals.loop(rest, put_natural(arena, 0n))

def reserve_naturals.result_1(+count: U32, result: Arena & U32) -> Arena & U32:
  match result:
    case Tuple{arena2, start}:
      (reserve_naturals.go(arena2, U32.to_nat(count)), start)

def reserve_naturals(arena: Arena, +count: U32) -> Arena & U32:
  reserve_naturals.result_1(count, natural_count(arena))

def quantity_word(quantity: Ast.Quantity) -> U32:
  match quantity:
    case Ast.QZero{}: 0
    case Ast.QOne{}: 1
    case Ast.QMany{}: 2

# Comparing once preserves the affine input and the exact 0/1/default decoder
# within the common native/selfhost constructor-pattern grammar.
def word_quantity.order(order: Cmp) -> Ast.Quantity:
  match order:
    case LT{}: Ast.QZero{}
    case EQ{}: Ast.QOne{}
    case GT{}: Ast.QMany{}

def word_quantity(value: U32) -> Ast.Quantity:
  word_quantity.order(U32.cmp(value, 1))

def mark.result_6(nodes: U32, patterns: U32, binders: U32, words: U32, naturals: U32, result: Arena & U32) -> Arena & Mark:
  match result:
    case Tuple{arena6, names}:
      (arena6, Mark{nodes, patterns, binders, words, naturals, names})

def mark.result_5(nodes: U32, patterns: U32, binders: U32, words: U32, result: Arena & U32) -> Arena & Mark:
  match result:
    case Tuple{arena5, naturals}:
      mark.result_6(nodes, patterns, binders, words, naturals, name_count(arena5))

def mark.result_4(nodes: U32, patterns: U32, binders: U32, result: Arena & U32) -> Arena & Mark:
  match result:
    case Tuple{arena4, words}:
      mark.result_5(nodes, patterns, binders, words, natural_count(arena4))

def mark.result_3(nodes: U32, patterns: U32, result: Arena & U32) -> Arena & Mark:
  match result:
    case Tuple{arena3, binders}:
      mark.result_4(nodes, patterns, binders, word_count(arena3))

def mark.result_2(nodes: U32, result: Arena & U32) -> Arena & Mark:
  match result:
    case Tuple{arena2, patterns}:
      mark.result_3(nodes, patterns, binder_count(arena2))

def mark.result_1(result: Arena & U32) -> Arena & Mark:
  match result:
    case Tuple{arena1, nodes}:
      mark.result_2(nodes, pattern_count(arena1))

def mark(arena: Arena) -> Arena & Mark:
  mark.result_1(node_count(arena))

def names.forget.loop(remaining: Nat, ids: Map<&2, U32>, +offset: U32, result: NamePool & String) -> NamePool & Map<&2, U32>:
  match remaining:
    case 0n:
      match result:
        case Tuple{pool, text}:
          (pool, Map.del(&2, U32, ids, text))
    case 1n+rest:
      match result:
        case Tuple{pool, text}:
          names.forget.loop(rest, Map.del(&2, U32, ids, text), U32.add(offset, 1), name_pool.get(pool, U32.add(offset, 1)))

def names.forget(pool: NamePool, ids: Map<&2, U32>, remaining: Nat, +offset: U32) -> NamePool & Map<&2, U32>:
  match remaining:
    case 0n: (pool, ids)
    case 1n+rest:
      names.forget.loop(rest, ids, offset, name_pool.get(pool, offset))

def names.rewind.result_1(+target: U32, result: NamePool & Map<&2, U32>) -> NamePool & Map<&2, U32>:
  match result:
    case Tuple{pool2, ids2}:
      (name_pool.rewind(pool2, target), ids2)

def names.rewind(pool: NamePool, ids: Map<&2, U32>, +target: U32) -> NamePool & Map<&2, U32>:
  match pool:
    case NamePool{items, +used, capacity, depth}:
      names.rewind.result_1(target, names.forget(NamePool{items, used, capacity, depth}, ids, U32.to_nat(U32.sub(used, target)), target))

def rewind.natural.count(+natural_target: U32, result: Arena & U32) -> Arena:
  match result:
    case Tuple{arena, +used}:
      match arena:
        case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}: Arena{nodes, patterns, binders, words, natural_pool.clear(U32.to_nat(U32.sub(used, natural_target)), naturals, natural_target), names, Array.set(U32, counts, 8, natural_target), depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}

def rewind.natural(arena: Arena, +natural_target: U32) -> Arena:
  rewind.natural.count(natural_target, natural_count(arena))

def rewind.word.count(+word_target: U32, +natural_target: U32, result: Arena & U32) -> Arena:
  match result:
    case Tuple{arena, +used}:
      match arena:
        case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}: rewind.natural(Arena{nodes, patterns, binders, word_pool.clear(U32.to_nat(U32.sub(used, word_target)), words, word_target), naturals, names, Array.set(U32, counts, 6, word_target), depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, natural_target)

def rewind.word(arena: Arena, +word_target: U32, +natural_target: U32) -> Arena:
  rewind.word.count(word_target, natural_target, word_count(arena))

def rewind.binder.count(+binder_target: U32, +word_target: U32, +natural_target: U32, result: Arena & U32) -> Arena:
  match result:
    case Tuple{arena, +used}:
      match arena:
        case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}: rewind.word(Arena{nodes, patterns, binder_pool.clear(U32.to_nat(U32.sub(used, binder_target)), binders, binder_target), words, naturals, names, Array.set(U32, counts, 4, binder_target), depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, word_target, natural_target)

def rewind.binder(arena: Arena, +binder_target: U32, +word_target: U32, +natural_target: U32) -> Arena:
  rewind.binder.count(binder_target, word_target, natural_target, binder_count(arena))

def rewind.pattern.count(+pattern_target: U32, +binder_target: U32, +word_target: U32, +natural_target: U32, result: Arena & U32) -> Arena:
  match result:
    case Tuple{arena, +used}:
      match arena:
        case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}: rewind.binder(Arena{nodes, pattern_pool.clear(U32.to_nat(U32.sub(used, pattern_target)), patterns, pattern_target), binders, words, naturals, names, Array.set(U32, counts, 2, pattern_target), depths, name_ids, node_closed, node_bounds, natural_pool.clear(U32.to_nat(U32.sub(used, pattern_target)), pattern_depths, pattern_target), case_prefix, subst_memo}, binder_target, word_target, natural_target)

def rewind.pattern(arena: Arena, +pattern_target: U32, +binder_target: U32, +word_target: U32, +natural_target: U32) -> Arena:
  rewind.pattern.count(pattern_target, binder_target, word_target, natural_target, pattern_count(arena))

def rewind.node.count(+node_target: U32, +pattern_target: U32, +binder_target: U32, +word_target: U32, +natural_target: U32, result: Arena & U32) -> Arena:
  match result:
    case Tuple{arena, +used}:
      match arena:
        case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}: rewind.pattern(Arena{node_pool.clear(U32.to_nat(U32.sub(used, node_target)), nodes, node_target), patterns, binders, words, naturals, names, Array.set(U32, counts, 0, node_target), depths, name_ids, word_pool.clear(U32.to_nat(U32.sub(used, node_target)), node_closed, node_target), natural_pool.clear(U32.to_nat(U32.sub(used, node_target)), node_bounds, node_target), pattern_depths, case_prefix, subst_memo}, pattern_target, binder_target, word_target, natural_target)

def rewind.node(arena: Arena, +node_target: U32, +pattern_target: U32, +binder_target: U32, +word_target: U32, +natural_target: U32) -> Arena:
  rewind.node.count(node_target, pattern_target, binder_target, word_target, natural_target, node_count(arena))

def rewind.names.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, counts: Array<U32>, depths: Array<Nat>, +node_target: U32, +pattern_target: U32, +binder_target: U32, +word_target: U32, +natural_target: U32, +name_target: U32, result: NamePool & Map<&2, U32>) -> Arena:
  match result:
    case Tuple{pool, name_ids}:
      match pool:
        case NamePool{names, _, _, _}: rewind.node(Arena{nodes, patterns, binders, words, naturals, names, Array.set(U32, counts, 10, name_target), depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, node_target, pattern_target, binder_target, word_target, natural_target)

def rewind.names.metadata(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, node_closed: Array<U32>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, name_ids: Map<&2, U32>, +node_target: U32, +pattern_target: U32, +binder_target: U32, +word_target: U32, +natural_target: U32, +name_target: U32, result: MetadataRead) -> Arena:
  match result:
    case MetadataRead{counts, depths, used, capacity, depth}:
      rewind.names.result(case_prefix, subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, binders, words, naturals, counts, depths, node_target, pattern_target, binder_target, word_target, natural_target, name_target, names.rewind(NamePool{names, used, capacity, depth}, name_ids, name_target))

def rewind.depths.result(result: Array<Nat> & Nat) -> Array<Nat>:
  match result:
    case Tuple{depths, generation}: Array.set(Nat, depths, 6, Nat.add(generation, 1n))

def rewind.depths(depths: Array<Nat>) -> Array<Nat>:
  rewind.depths.result(Array.get(Nat, depths, 6))

# Reuse affine cache arrays. Allocating replacements retains old memo tables in
# enclosing native continuation frames until the complete module returns.
def rewind.case_prefix.loop(remaining: Nat, items: Array<CasePrefixEntry>, +offset: U32, +empty: CasePrefixEntry) -> Array<CasePrefixEntry>:
  match remaining:
    case 0n: items
    case 1n+rest:
      rewind.case_prefix.loop(rest, Array.set(CasePrefixEntry, items, offset, empty), U32.add(offset, 1), empty)

def rewind.case_prefix(items: Array<CasePrefixEntry>) -> Array<CasePrefixEntry>:
  rewind.case_prefix.loop(64n, items, 0, CasePrefixEmpty{})

def rewind(arena: Arena, saved: Mark) -> Arena:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      match saved:
        case Mark{node_target, pattern_target, binder_target, word_target, natural_target, name_target}:
          rewind.names.metadata(rewind.case_prefix(case_prefix), subst_memo, node_bounds, pattern_depths, node_closed, nodes, patterns, binders, words, naturals, names, name_ids, node_target, pattern_target, binder_target, word_target, natural_target, name_target, metadata_read(counts, rewind.depths(depths), 5))

# A bounded direct-mapped table: collisions replace one entry, never relax keys.
def subst_memo_slot(node_id: U32, value_id: U32) -> U32:
  U32.and(U32.xor(U32.mul(node_id, 2654435761), U32.mul(value_id, 2246822519)), 4095)

# Transient slots record the rewind epoch of their put. The generation below
# only moves forward, so an entry written before the current rewind can never
# be read again: its handles may already be reused by the live frame.
def subst_memo_entry_epoch(entry: SubstMemoEntry, current: Bool) -> SubstMemoEntry:
  match current:
    case True{}: entry
    case False{}: SubstMemoEmpty{}

def subst_memo_entry_current(entry: SubstMemoEntry, +epoch: Nat) -> SubstMemoEntry:
  match entry:
    case SubstMemoSaved{_, _, _, _, _, +saved_epoch}:
      subst_memo_entry_epoch(entry, Nat.is_eq(saved_epoch, epoch))
    case PublishedTerm{_, _, +saved_epoch}:
      subst_memo_entry_epoch(entry, Nat.is_eq(saved_epoch, epoch))
    case _: entry

def subst_memo_get.result(case_prefix: Array<CasePrefixEntry>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, counts: Array<U32>, depths: Array<Nat>, name_ids: Map<&2, U32>, node_closed: Array<U32>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, result: Array<SubstMemoEntry> & SubstMemoEntry) -> Arena & SubstMemoEntry:
  match result:
    case Tuple{subst_memo, entry}:
      (Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, entry)

def subst_memo_current_result(+epoch: Nat, result: Arena & SubstMemoEntry) -> Arena & SubstMemoEntry:
  match result:
    case Tuple{arena, entry}: (arena, subst_memo_entry_current(entry, epoch))

def subst_memo_get(arena: Arena, node_id: U32, value_id: U32) -> Arena & SubstMemoEntry:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      +epoch = Array.get(Nat, depths, 6)
      subst_memo_current_result(epoch, subst_memo_get.result(case_prefix, nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, Array.get(SubstMemoEntry, subst_memo, subst_memo_slot(node_id, value_id))))

def subst_memo_put(arena: Arena, +node_id: U32, index: Nat, +value_id: U32, depth: Nat, output_id: U32) -> Arena:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, Array.set(SubstMemoEntry, subst_memo, subst_memo_slot(node_id, value_id), SubstMemoSaved{node_id, index, value_id, depth, output_id, Array.get(Nat, depths, 6)})}

# Publication shares semantic handles only. Occurrence facts remain distinct.
# The transient owner and its rewind epoch delimit every memo entry's validity.
def publication_memo_put(arena: Arena, +node_id: U32, output_id: U32) -> Arena:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, Array.set(SubstMemoEntry, subst_memo, subst_memo_slot(node_id, 0), PublishedTerm{node_id, output_id, Array.get(Nat, depths, 6)})}

# A declaration inference frame owns this existing source-memo slot. The scope
# snapshot retains exact alias records, not merely canonical namespace text.
# Its checker wrapper clears the frame before publishing or changing scopes;
# rewinding or a colliding memo write also invalidates it conservatively.
def scalar_frame_set(arena: Arena, entry: SubstMemoEntry) -> Arena:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, Array.set(SubstMemoEntry, subst_memo, 0, entry)}

def scalar_frame_get(arena: Arena) -> Arena & SubstMemoEntry:
  subst_memo_get(arena, 0, 0)

# Source packing shares exactly equal childless descriptors, never typing facts.
# The source memo lane is otherwise unused by substitution (which owns transient).
# Rewind only advances the transient epoch, so this source lane is never cleared.
def ctr_leaf_span_equal(left: Ast.SourceSpan, right: Ast.SourceSpan) -> Bool:
  match left:
    case Ast.SpanOf{file, beg, end}:
      match right:
        case Ast.SpanOf{other_file, other_beg, other_end}:
          Bool.and(Bool.and(Nat.is_eq(beg, other_beg), Nat.is_eq(end, other_end)), String.eq(file, other_file))

def ctr_leaf_save(arena: Arena, +key_id: U32, span: Ast.SourceSpan, output_id: U32) -> Arena:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, Array.set(SubstMemoEntry, subst_memo, subst_memo_slot(key_id, 0), CtrLeafSaved{key_id, span, output_id})}

def ctr_leaf_append(+key_id: U32, +span: Ast.SourceSpan, result: Arena & U32) -> Arena & U32:
  match result:
    case Tuple{arena, +output_id}: (ctr_leaf_save(arena, key_id, span, output_id), output_id)

def ctr_leaf_select(arena: Arena, +key_id: U32, +span: Ast.SourceSpan, output_id: U32, equal: Bool) -> Arena & U32:
  match equal:
    case True{}: (arena, output_id)
    case False{}: ctr_leaf_append(key_id, span, put_node(arena, TermCtr{key_id, 0, 0, span}))

def ctr_leaf_lookup(+key_id: U32, +span: Ast.SourceSpan, result: Arena & SubstMemoEntry) -> Arena & U32:
  match result:
    case Tuple{arena, entry}:
      match entry:
        case CtrLeafSaved{saved_key, saved_span, output_id}:
          ctr_leaf_select(arena, key_id, span, output_id, Bool.and(U32.is_eq(key_id, saved_key), ctr_leaf_span_equal(span, saved_span)))
        case _: ctr_leaf_append(key_id, span, put_node(arena, TermCtr{key_id, 0, 0, span}))

def put_ctr_leaf(arena: Arena, +key_id: U32, span: Ast.SourceSpan) -> Arena & U32:
  ctr_leaf_lookup(key_id, span, subst_memo_get(arena, key_id, 0))

def generation.result(case_prefix: Array<CasePrefixEntry>, subst_memo: Array<SubstMemoEntry>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, counts: Array<U32>, name_ids: Map<&2, U32>, node_closed: Array<U32>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, result: Array<Nat> & Nat) -> Arena & Nat:
  match result:
    case Tuple{depths, generation}:
      (Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, generation)

def generation(arena: Arena) -> Arena & Nat:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      generation.result(case_prefix, subst_memo, nodes, patterns, binders, words, naturals, names, counts, name_ids, node_closed, node_bounds, pattern_depths, Array.get(Nat, depths, 6))

def case_prefix_slot(start: U32, count: U32) -> U32:
  U32.and(U32.xor(U32.mul(start, 2654435761), U32.mul(count, 2246822519)), 63)

def case_prefix_get.result(subst_memo: Array<SubstMemoEntry>, nodes: Array<Node>, patterns: Array<Pattern>, binders: Array<Binder>, words: Array<U32>, naturals: Array<Nat>, names: Array<String>, counts: Array<U32>, depths: Array<Nat>, name_ids: Map<&2, U32>, node_closed: Array<U32>, node_bounds: Array<Nat>, pattern_depths: Array<Nat>, result: Array<CasePrefixEntry> & CasePrefixEntry) -> Arena & CasePrefixEntry:
  match result:
    case Tuple{case_prefix, entry}:
      (Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}, entry)

def case_prefix_get(arena: Arena, start: U32, count: U32) -> Arena & CasePrefixEntry:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      case_prefix_get.result(subst_memo, nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, Array.get(CasePrefixEntry, case_prefix, case_prefix_slot(start, count)))

def case_prefix_put(arena: Arena, +start: U32, +count: U32, heads: Map<&2, U32>, barrier: U32, source_generation: Nat) -> Arena:
  match arena:
    case Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, case_prefix, subst_memo}:
      Arena{nodes, patterns, binders, words, naturals, names, counts, depths, name_ids, node_closed, node_bounds, pattern_depths, Array.set(CasePrefixEntry, case_prefix, case_prefix_slot(start, count), CasePrefixSaved{start, count, heads, barrier, source_generation}), subst_memo}

# Validate the complete tape range before reading any prefix. Subtraction only
# occurs after start is in bounds; reverse ranges retain their direction bit.
def case_prefix_less(order: Cmp) -> Bool:
  match order:
    case LT{}: True{}
    case _: False{}

def case_prefix_at_most(order: Cmp) -> Bool:
  match order:
    case GT{}: False{}
    case _: True{}

def case_prefix_tape_used(used: U32, order: Cmp) -> U32:
  match order:
    case GT{}: 1073741824
    case _: used

def case_prefix_range_valid.direction(+start: U32, +count: U32, +used: U32, reverse: Bool) -> Bool:
  match reverse:
    case False{}: case_prefix_at_most(U32.cmp(count, U32.sub(used, start)))
    case True{}: case_prefix_at_most(U32.cmp(count, U32.add(start, 1)))

def case_prefix_range_valid.order(start: U32, count: U32, used: U32, reverse: Bool, order: Cmp) -> Bool:
  match order:
    case LT{}: case_prefix_range_valid.direction(start, count, used, reverse)
    case _: False{}

def case_prefix_range_valid.count(+start: U32, count: U32, result: Arena & U32) -> Arena & Bool:
  match result:
    case Tuple{arena, +used}:
      +bounded = case_prefix_tape_used(used, U32.cmp(used, 1073741824))
      (arena, Bool.and(U32.is_eq(U32.and(start, 2147483648), 0), case_prefix_range_valid.order(U32.and(start, 1073741823), count, bounded, U32.is_ne(U32.and(start, 1073741824), 0), U32.cmp(U32.and(start, 1073741823), bounded))))

def case_prefix_range_valid(arena: Arena, start: U32, count: U32) -> Arena & Bool:
  case_prefix_range_valid.count(start, count, word_count(arena))

def case_prefix_handle_valid(+id: U32, +used: U32) -> Bool:
  Bool.and(U32.is_eq(U32.and(id, 2147483648), 0), case_prefix_less(U32.cmp(id, used)))

def case_prefix_id_valid.count(id: U32, result: Arena & U32) -> Arena & Bool:
  match result:
    case Tuple{arena, used}: (arena, case_prefix_handle_valid(id, used))

def case_prefix_node_valid(arena: Arena, id: U32) -> Arena & Bool:
  case_prefix_id_valid.count(id, node_count(arena))

def case_prefix_pattern_valid(arena: Arena, id: U32) -> Arena & Bool:
  case_prefix_id_valid.count(id, pattern_count(arena))

def case_prefix_name_valid(arena: Arena, id: U32) -> Arena & Bool:
  case_prefix_id_valid.count(id, name_count(arena))

def case_prefix_head.text(result: Arena & String) -> Arena & Maybe<&2, String>:
  match result:
    case Tuple{arena, text}: (arena, Some{text})

def case_prefix_head.name(id: U32, result: Arena & Bool) -> Arena & Maybe<&2, String>:
  match result:
    case Tuple{arena, valid}:
      match valid:
        case False{}: (arena, None{})
        case True{}: case_prefix_head.text(name_text(arena, id))

def case_prefix_head.pattern(result: Arena & Pattern) -> Arena & Maybe<&2, String>:
  match result:
    case Tuple{arena, pattern}:
      match pattern:
        case PatternCtr{+key_id, _, _, _}: case_prefix_head.name(key_id, case_prefix_name_valid(arena, key_id))
        case _: (arena, None{})

def case_prefix_head.pattern_valid(id: U32, result: Arena & Bool) -> Arena & Maybe<&2, String>:
  match result:
    case Tuple{arena, valid}:
      match valid:
        case False{}: (arena, None{})
        case True{}: case_prefix_head.pattern(get_pattern(arena, id))

def case_prefix_head.word(result: Arena & U32) -> Arena & Maybe<&2, String>:
  match result:
    case Tuple{arena, +id}: case_prefix_head.pattern_valid(id, case_prefix_pattern_valid(arena, id))

def case_prefix_head.range(+start: U32, result: Arena & Bool) -> Arena & Maybe<&2, String>:
  match result:
    case Tuple{arena, valid}:
      match valid:
        case False{}: (arena, None{})
        case True{}: case_prefix_head.word(word(arena, U32.and(start, 1073741823)))

def case_prefix_head.single(arena: Arena, +start: U32, single: Bool) -> Arena & Maybe<&2, String>:
  match single:
    case False{}: (arena, None{})
    case True{}: case_prefix_head.range(start, case_prefix_range_valid(arena, start, 1))

def case_prefix_head.node(result: Arena & Node) -> Arena & Maybe<&2, String>:
  match result:
    case Tuple{arena, node}:
      match node:
        case BodyCase{start, +count, _, _}: case_prefix_head.single(arena, start, U32.is_eq(count, 1))
        case _: (arena, None{})

def case_prefix_head.valid(id: U32, result: Arena & Bool) -> Arena & Maybe<&2, String>:
  match result:
    case Tuple{arena, valid}:
      match valid:
        case False{}: (arena, None{})
        case True{}: case_prefix_head.node(get_node(arena, id))

def case_prefix_head(arena: Arena, +id: U32) -> Arena & Maybe<&2, String>:
  case_prefix_head.valid(id, case_prefix_node_valid(arena, id))

def case_prefix_first.missing(heads: Map<&2, U32>, name: String, offset: U32, missing: Bool) -> Map<&2, U32>:
  match missing:
    case False{}: heads
    case True{}: Map.set(&2, U32, heads, name, offset)

def case_prefix_first.result(name: String, offset: U32, result: Map<&2, U32> & U32) -> Map<&2, U32>:
  match result:
    case Tuple{heads, first}: case_prefix_first.missing(heads, name, offset, U32.is_eq(first, 4294967295))

def case_prefix_first(heads: Map<&2, U32>, +name: String, offset: U32) -> Map<&2, U32>:
  case_prefix_first.result(name, offset, Map.get(U32, 4294967295, heads, name))

def case_prefix_name(heads: Map<&2, U32>, name: String) -> Map<&2, U32> & U32:
  Map.get(U32, 4294967295, heads, name)

# This is a positive shape proof, not general closedness or equality. Published
# source descriptors and tapes are immutable; a child must be a live source node
# older than its parent, even when that child already has a witness. Rewind and
# append clear the existing flag lane, so recycled IDs cannot inherit the proof.
def ctor_source_range_valid.length(+start: U32, count: U32, +used: U32, empty: Bool) -> Bool:
  match empty:
    case True{}: case_prefix_at_most(U32.cmp(U32.and(start, 1073741823), used))
    case False{}: case_prefix_range_valid.order(U32.and(start, 1073741823), count, used, U32.is_ne(U32.and(start, 1073741824), 0), U32.cmp(U32.and(start, 1073741823), used))

def ctor_source_range_valid.count(+start: U32, +count: U32, result: Arena & U32) -> Arena & Bool:
  match result:
    case Tuple{arena, +used}:
      +bounded = case_prefix_tape_used(used, U32.cmp(used, 1073741824))
      (arena, Bool.and(U32.is_eq(U32.and(start, 2147483648), 0), ctor_source_range_valid.length(start, count, bounded, U32.is_eq(count, 0))))

def ctor_source_range_valid(arena: Arena, start: U32, count: U32) -> Arena & Bool:
  ctor_source_range_valid.count(start, count, word_count(arena))

