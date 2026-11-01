import Base
import ./backend_ir.bend as BIR
import ./descriptor_nf.bend as NF
import ./descriptor_key.bend as Key

# All state belongs to one compilation. Each intern table has at most limit
# entries; the two result tables together have at most limit entries. No table
# evicts or reassigns an ID. Pending misses reserve no slot: save rechecks the
# current store after nested queries, and never replaces an existing answer.
type Intern is Data:
  Intern{values: Map<&2, Nat>, size: Nat}
type InternResult is Data:
  InternResult{table: Intern, id: Maybe<&2, Nat>}
type Counts is Data:
  Counts{nf_hits: Nat, nf_misses: Nat, reach_hits: Nat, reach_misses: Nat, nf_entries: Nat, reach_entries: Nat, disabled: Nat}
type Store is Data:
  Store{limit: Nat, scope_table: Intern, descriptor_table: Intern, env_table: Intern, nfs: Map<&2, NF.Nf>, reaches: Map<&2, Bool>, counts: Counts}
type Report is Data:
  Report{nf_hits: Nat, nf_misses: Nat, reach_hits: Nat, reach_misses: Nat, nf_entries: Nat, reach_entries: Nat, interned: Nat, scopes: Nat, disabled: Nat}
type ScopeResult is Data:
  ScopeResult{store: Store, scope: String}
type NfLookup is Data:
  NfHit{store: Store, value: NF.Nf}
  NfMiss{store: Store, key: Maybe<&2, String>}
type ReachLookup is Data:
  ReachHit{store: Store, value: Bool}
  ReachMiss{store: Store, key: Maybe<&2, String>}
type QueryIds is Data:
  QueryIds{descriptor: Nat, env: Nat}
type Prepared is Data:
  Prepared{store: Store, ids: Maybe<&2, QueryIds>}
type CountEvent is Data:
  CountNfHit{}
  CountNfMiss{}
  CountReachHit{}
  CountReachMiss{}
  CountNfEntry{}
  CountReachEntry{}
  CountDisabled{}

def new_intern() -> Intern:
  Intern{Map.new(&2, Nat), 0n}

def new_store(limit: Nat) -> Store:
  Store{limit, new_intern(), new_intern(), new_intern(), Map.new(&2, NF.Nf), Map.new(&2, Bool), Counts{0n, 0n, 0n, 0n, 0n, 0n, 0n}}

def intern_size(table: Intern) -> Nat:
  match table:
    case Intern{values, size}: size

def report(store: Store) -> Report:
  match store:
    case Store{limit, scope_table, descriptor_table, env_table, nfs, reaches, counts}:
      match counts:
        case Counts{nf_hits, nf_misses, reach_hits, reach_misses, nf_entries, reach_entries, disabled}:
          Report{nf_hits, nf_misses, reach_hits, reach_misses, nf_entries, reach_entries, Nat.add(intern_size(descriptor_table), intern_size(env_table)), intern_size(scope_table), disabled}

# disabled counts refused scope admission, uncachable query misses, and pending
# saves that lost their available slot to nested work. It is not a result value.
def count(counts: Counts, event: CountEvent) -> Counts:
  match counts:
    case Counts{nh, nm, rh, rm, ne, re, disabled}:
      match event:
        case CountNfHit{}: Counts{1n+nh, nm, rh, rm, ne, re, disabled}
        case CountNfMiss{}: Counts{nh, 1n+nm, rh, rm, ne, re, disabled}
        case CountReachHit{}: Counts{nh, nm, 1n+rh, rm, ne, re, disabled}
        case CountReachMiss{}: Counts{nh, nm, rh, 1n+rm, ne, re, disabled}
        case CountNfEntry{}: Counts{nh, nm, rh, rm, 1n+ne, re, disabled}
        case CountReachEntry{}: Counts{nh, nm, rh, rm, ne, 1n+re, disabled}
        case CountDisabled{}: Counts{nh, nm, rh, rm, ne, re, 1n+disabled}

def counted(store: Store, event: CountEvent) -> Store:
  match store:
    case Store{limit, scope_table, descriptor_table, env_table, nfs, reaches, counts}:
      Store{limit, scope_table, descriptor_table, env_table, nfs, reaches, count(counts, event)}

def has_room(+limit: Nat, counts: Counts) -> Bool:
  match counts:
    case Counts{nh, nm, rh, rm, ne, re, disabled}:
      Nat.is_lt(Nat.add(ne, re), limit)

def intern(limit: Nat, table: Intern, +key: String) -> InternResult:
  match table:
    case Intern{+values, +size}:
      match Map.find(Nat, values, key):
        case Some{id}: InternResult{Intern{values, size}, Some{id}}
        case None{}:
          match Nat.is_lt(size, limit):
            case True{}: InternResult{Intern{Map.set(&2, Nat, values, key, size), 1n+size}, Some{size}}
            case False{}: InternResult{Intern{values, size}, None{}}

# Full codec strings always start with K1;. Compact scope IDs start with @s,
# and are assigned only after an exact full-key lookup in this Store.
def scope_intern(store: Store, +key: String) -> ScopeResult:
  match store:
    case Store{+limit, scope_table, descriptor_table, env_table, nfs, reaches, counts}:
      match intern(limit, scope_table, key):
        case InternResult{table, id}:
          match id:
            case Some{value}:
              ScopeResult{Store{limit, table, descriptor_table, env_table, nfs, reaches, counts}, String.append("@s", Nat.show(value))}
            case None{}:
              ScopeResult{Store{limit, table, descriptor_table, env_table, nfs, reaches, count(counts, CountDisabled{})}, key}

# Semantic environments are structural, including original descriptors in
# abstract values, output binder levels, arrow levels and closure captures.
def val_chunks(value: NF.NfVal, tail: List<&2, String>) -> List<&2, String>:
  match value:
    case NF.NfType{key, args}:
      "v0;" <> Key.string_chunks(key, env_chunks(args, tail))
    case NF.NfCtor{key, args}:
      "v1;" <> Key.string_chunks(key, env_chunks(args, tail))
    case NF.NfQuantity{quantity}:
      "v2;" <> Key.quantity_chunks(quantity, tail)
    case NF.NfKind{quantity}:
      "v3;" <> val_chunks(quantity, tail)
    case NF.NfOther{source}:
      "v4;" <> Key.descriptor_chunks(source, tail)
    case NF.NfMissing{source}:
      "v5;" <> Key.descriptor_chunks(source, tail)
    case NF.NfBinder{level}:
      "v6;" <> Key.nat_chunks(level, tail)
    case NF.NfArrow{quantity, domain, body, level}:
      "v7;" <> Key.quantity_chunks(quantity, val_chunks(domain, val_chunks(body, Key.nat_chunks(level, tail))))
    case NF.NfClosure{quantity, body, env}:
      "v8;" <> Key.maybe_quantity_chunks(quantity, Key.descriptor_chunks(body, env_chunks(env, tail)))

def env_chunks(env: List<&2, NF.NfVal>, tail: List<&2, String>) -> List<&2, String>:
  match env:
    case Nil{}: "z" <> tail
    case value <> rest: "c" <> val_chunks(value, env_chunks(rest, tail))

def env_key(env: List<&2, NF.NfVal>) -> String:
  Key.finish("E;" <> env_chunks(env, Nil{}))

def prepare(store: Store, descriptor: BIR.Descriptor, env: List<&2, NF.NfVal>) -> Prepared:
  match store:
    case Store{+limit, scope_table, descriptor_table, env_table, nfs, reaches, counts}:
      match intern(limit, descriptor_table, Key.descriptor_key(descriptor)):
        case InternResult{table, id}:
          match id:
            case None{}:
              Prepared{Store{limit, scope_table, table, env_table, nfs, reaches, counts}, None{}}
            case Some{descriptor_id}:
              match intern(limit, env_table, env_key(env)):
                case InternResult{env_table_next, env_id}:
                  Prepared{Store{limit, scope_table, table, env_table_next, nfs, reaches, counts}, query_ids(descriptor_id, env_id)}

def query_ids(descriptor: Nat, env: Maybe<&2, Nat>) -> Maybe<&2, QueryIds>:
  match env:
    case None{}: None{}
    case Some{id}: Some{QueryIds{descriptor, id}}

def ids_chunks(ids: QueryIds, tail: List<&2, String>) -> List<&2, String>:
  match ids:
    case QueryIds{descriptor, env}: Key.nat_chunks(descriptor, Key.nat_chunks(env, tail))

def nf_lookup(store: Store, scope: String, descriptor: BIR.Descriptor, env: List<&2, NF.NfVal>, level: Nat, fuel: Nat) -> NfLookup:
  match prepare(store, descriptor, env):
    case Prepared{next, ids}:
      match ids:
        case None{}:
          NfMiss{counted(counted(next, CountNfMiss{}), CountDisabled{}), None{}}
        case Some{known}:
          nf_lookup_key(next, Key.finish("Qn;" <> Key.string_chunks(scope, ids_chunks(known, Key.nat_chunks(level, Key.nat_chunks(fuel, Nil{}))))))

def nf_lookup_key(store: Store, +key: String) -> NfLookup:
  match store:
    case Store{+limit, scope_table, descriptor_table, env_table, +nfs, reaches, +counts}:
      match Map.find(NF.Nf, nfs, key):
        case Some{value}:
          NfHit{Store{limit, scope_table, descriptor_table, env_table, nfs, reaches, count(counts, CountNfHit{})}, value}
        case None{}:
          match has_room(limit, counts):
            case True{}:
              NfMiss{Store{limit, scope_table, descriptor_table, env_table, nfs, reaches, count(counts, CountNfMiss{})}, Some{key}}
            case False{}:
              NfMiss{Store{limit, scope_table, descriptor_table, env_table, nfs, reaches, count(count(counts, CountNfMiss{}), CountDisabled{})}, None{}}

def reach_lookup(store: Store, scope: String, descriptor: BIR.Descriptor, env: List<&2, NF.NfVal>, target: String, seen: List<&2, String>, fuel: Nat) -> ReachLookup:
  match prepare(store, descriptor, env):
    case Prepared{next, ids}:
      match ids:
        case None{}:
          ReachMiss{counted(counted(next, CountReachMiss{}), CountDisabled{}), None{}}
        case Some{known}:
          reach_lookup_key(next, Key.finish("Qr;" <> Key.string_chunks(scope, ids_chunks(known, Key.string_chunks(target, Key.strings_chunks(seen, Key.nat_chunks(fuel, Nil{})))))))

def reach_lookup_key(store: Store, +key: String) -> ReachLookup:
  match store:
    case Store{+limit, scope_table, descriptor_table, env_table, nfs, +reaches, +counts}:
      match Map.find(Bool, reaches, key):
        case Some{value}:
          ReachHit{Store{limit, scope_table, descriptor_table, env_table, nfs, reaches, count(counts, CountReachHit{})}, value}
        case None{}:
          match has_room(limit, counts):
            case True{}:
              ReachMiss{Store{limit, scope_table, descriptor_table, env_table, nfs, reaches, count(counts, CountReachMiss{})}, Some{key}}
            case False{}:
              ReachMiss{Store{limit, scope_table, descriptor_table, env_table, nfs, reaches, count(count(counts, CountReachMiss{}), CountDisabled{})}, None{}}

def nf_save(store: Store, key: Maybe<&2, String>, value: NF.Nf) -> Store:
  match key:
    case None{}: store
    case Some{known}: nf_save_key(store, known, value)

def nf_save_key(store: Store, +key: String, value: NF.Nf) -> Store:
  match store:
    case Store{+limit, scope_table, descriptor_table, env_table, +nfs, reaches, +counts}:
      match Map.find(NF.Nf, nfs, key):
        case Some{previous}:
          Store{limit, scope_table, descriptor_table, env_table, nfs, reaches, counts}
        case None{}:
          match has_room(limit, counts):
            case True{}:
              Store{limit, scope_table, descriptor_table, env_table, Map.set(&2, NF.Nf, nfs, key, value), reaches, count(counts, CountNfEntry{})}
            case False{}:
              Store{limit, scope_table, descriptor_table, env_table, nfs, reaches, count(counts, CountDisabled{})}

def reach_save(store: Store, key: Maybe<&2, String>, value: Bool) -> Store:
  match key:
    case None{}: store
    case Some{known}: reach_save_key(store, known, value)

def reach_save_key(store: Store, +key: String, value: Bool) -> Store:
  match store:
    case Store{+limit, scope_table, descriptor_table, env_table, nfs, +reaches, +counts}:
      match Map.find(Bool, reaches, key):
        case Some{previous}:
          Store{limit, scope_table, descriptor_table, env_table, nfs, reaches, counts}
        case None{}:
          match has_room(limit, counts):
            case True{}:
              Store{limit, scope_table, descriptor_table, env_table, nfs, Map.set(&2, Bool, reaches, key, value), count(counts, CountReachEntry{})}
            case False{}:
              Store{limit, scope_table, descriptor_table, env_table, nfs, reaches, count(counts, CountDisabled{})}
