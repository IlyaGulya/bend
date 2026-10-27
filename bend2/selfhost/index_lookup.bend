import Base
import ./ast.bend as Ast


def find.leaf(-V: Data, +value: V, same: Bool) -> Maybe<&2, V>:
  match same:
    case False{}: None{}
    case True{}: Some{value}

# A leaf ignores its prospective bit.
def find.position(-V: Data, map: Map<&2, V>) -> Nat:
  match map:
    case MNode{pos, _, _}: pos
    case _: 0n

# Use the canonical presence/MSB-first bit operation on the original key.
# Reading never rebuilds a Map spine, and arbitrary backward positions work.
def find.bit(key: String, position: Nat) -> Bool:
  Pair.snd(String, Bool, Map.bit(key, position))

def find.go(-V: Data, +map: Map<&2, V>, +key: String, bit: Bool) -> Maybe<&2, V>:
  match map bit:
    case MTip{} _: None{}
    case MLeaf{k, v} _: find.leaf(V, v, String.eq(key, k))
    case MNode{_, +lo, _} False{}:
      find.go(V, lo, key, find.bit(key, find.position(V, lo)))
    case MNode{_, _, +hi} True{}:
      find.go(V, hi, key, find.bit(key, find.position(V, hi)))

def find(-V: Data, +map: Map<&2, V>, +key: String) -> Maybe<&2, V>:
  find.go(V, map, key, find.bit(key, find.position(V, map)))

# Checked constructors end in a literal canonical family, under telescopes.
# Non-declaration-shaped types retain the checker's general reduction path.
def constructor_owner(+ty: Ast.SyntaxTerm) -> Maybe<&2, String>:
  match ty:
    case Ast.TermAll{_, _, _, _, body, _}: constructor_owner(body)
    case Ast.TermAdt{key, _, _, _}: Some{key}
    case _: None{}
