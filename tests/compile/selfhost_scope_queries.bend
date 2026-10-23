import Base
import ../../bend2/selfhost/checker_ir.bend as IR
import ../../bend2/selfhost/scope_lookup.bend as Scope

def global(key: String, namespace: String, local: String, kind: Scope.GlobalKind) -> Scope.ArenaGlobal:
  Scope.ArenaGlobal{key, namespace, local, 0, IR.NoTerm{}, kind}

def has_key(value: Maybe<&2, Scope.ArenaGlobal>, expected: String) -> Bool:
  match value:
    case Some{Scope.ArenaGlobal{key, _, _, _, _, _}}: String.eq(key, expected)
    case None{}: False{}

def missing(value: Maybe<&2, Scope.ArenaGlobal>) -> Bool:
  match value:
    case Some{_}: False{}
    case None{}: True{}

def result(valid: Bool) -> String:
  match valid:
    case True{}: "scope-query-ok"
    case False{}: "scope-query-failed"

def run(+query: String) -> String:
  +definition = global("definition", "D", "item", Scope.GlobalDefinition{})
  +family = global("family", "F", "item", Scope.GlobalFamily{})
  +constructor = global("constructor", "C", "item", Scope.GlobalConstructor{})
  +bucket = {Scope.ArenaGlobalBucket{definition, Some{family}, Some{constructor}, Some{definition}} : Scope.ArenaGlobalBucket}
  +values = Map.set(&2, Scope.ArenaGlobalBucket, MTip{}, query, bucket)
  +index = {Scope.ArenaGlobalIndex{values, MTip{}, MTip{}, True{}} : Scope.ArenaGlobalIndex}
  +plain = {Scope.ArenaGlobalScope{[], index, 1n} : Scope.ArenaGlobalScope}
  +visible = {Scope.ArenaVisibleScope{[], values} : Scope.ArenaGlobalScope}
  +unsafe = {Scope.ArenaUnsafeScope{Scope.ArenaUnsafeScope{visible}} : Scope.ArenaGlobalScope}
  +generic = has_key(Scope.lookup(query, plain), "family")
  +selected = has_key(Scope.lookup_kind(query, Scope.GlobalDefinition{}, unsafe), "definition")
  +selected_constructor = has_key(Scope.lookup_kind(query, Scope.GlobalConstructor{}, visible), "constructor")
  +alias = String.eq(Scope.canonical_name(query, unsafe), "F.item")
  +unknown = String.eq(Scope.canonical_name("unknown", plain), "unknown")
  +absent = missing(Scope.lookup("unknown", unsafe))
  +fallback = has_key(Scope.bucket(Scope.ArenaGlobalBucket{definition, None{}, None{}, Some{definition}}), "definition")
  +absent_kind = missing(Scope.bucket_kind(Scope.ArenaGlobalBucket{definition, None{}, None{}, Some{definition}}, Scope.GlobalFamily{}))
  +unqualified = String.eq(Scope.canonical_name_result(query, Some{global("root", "", "item", Scope.GlobalFamily{})}), "item")
  +lookup_checks = Bool.and(generic, Bool.and(selected, Bool.and(selected_constructor, Bool.and(alias, Bool.and(unknown, Bool.and(absent, Bool.and(fallback, Bool.and(absent_kind, unqualified))))))))
  +shadow = global("shadow", "S", "item", Scope.GlobalFamily{})
  +shadow_bucket = {Scope.ArenaGlobalBucket{shadow, Some{shadow}, None{}, None{}} : Scope.ArenaGlobalBucket}
  +shadow_values = Map.set(&2, Scope.ArenaGlobalBucket, values, "F.item", shadow_bucket)
  +shadow_scope = {Scope.ArenaVisibleScope{[], shadow_values} : Scope.ArenaGlobalScope}
  +alias_equal = Scope.equal_names(query, "F.item", unsafe)
  +distinct = Bool.not(Scope.equal_names(query, "unknown", unsafe))
  +shadow_distinct = Bool.not(Scope.equal_names(query, "F.item", shadow_scope))
  result(Bool.and(lookup_checks, Bool.and(alias_equal, Bool.and(distinct, shadow_distinct))))

def main() -> IO(Unit):
  do IO<Unit>:
    seed : U32 <- IO.thread_count()
    IO.print(run(U32.show(seed)))

#|scope-query-ok
