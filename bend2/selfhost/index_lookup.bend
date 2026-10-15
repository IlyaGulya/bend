import Base
import ./ast.bend as Ast


# Read only the selected subtree; Map.bit preserves the borrowed key and uses
# the same presence/MSB-first encoding for monotone and arbitrary public maps.
def find.leaf(-V: Data, +value: V, same: Bool) -> Maybe<&2, V>:
  match same:
    case False{}: None{}
    case True{}: Some{value}

# Compute the selected child's bit before the next structurally decreasing call.
# A leaf ignores that bit. No branch closure or reconstructed map is needed.
def find.position(-V: Data, map: Map<&2, V>) -> Nat:
  match map:
    case MNode{pos, _, _}: pos
    case _: 0n

def find.go(-V: Data, +map: Map<&2, V>, bits: String & Bool) -> Maybe<&2, V>:
  match map bits:
    case MTip{} _: None{}
    case MLeaf{k, v} Tuple{key, _}: find.leaf(V, v, String.eq(key, k))
    case MNode{_, +lo, _} Tuple{+key, False{}}:
      find.go(V, lo, Map.bit(key, find.position(V, lo)))
    case MNode{_, _, +hi} Tuple{+key, True{}}:
      find.go(V, hi, Map.bit(key, find.position(V, hi)))

def find(-V: Data, +map: Map<&2, V>, +key: String) -> Maybe<&2, V>:
  find.go(V, map, Map.bit(key, find.position(V, map)))

# Checked constructors end in a literal canonical family, under telescopes.
# Non-declaration-shaped types retain the checker's general reduction path.
def constructor_owner(+ty: Ast.SyntaxTerm) -> Maybe<&2, String>:
  match ty:
    case Ast.TermAll{_, _, _, _, body, _}: constructor_owner(body)
    case Ast.TermAdt{key, _, _, _}: Some{key}
    case _: None{}
