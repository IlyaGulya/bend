import Base
import ./ast.bend as Ast


# A cursor owns the selected suffix, its absolute character position and bit.
# Keep the full key separately for leaf equality and arbitrary backward nodes.
type FindCursor is Data:
  FindCursor{index: Nat, suffix: String, bit: Bool}

def find.leaf(-V: Data, +value: V, same: Bool) -> Maybe<&2, V>:
  match same:
    case False{}: None{}
    case True{}: Some{value}

# A leaf ignores its prospective bit.
def find.position(-V: Data, map: Map<&2, V>) -> Nat:
  match map:
    case MNode{pos, _, _}: pos
    case _: 0n

# Seeking discards a prefix; it never rebuilds it on return.
def find.seek(cursor: String, skip: Nat) -> String:
  match cursor skip:
    case SCon{_, tail} 1n+rest: find.seek(tail, rest)
    case cursor _: cursor

# Exactly Map.bit's presence bit followed by 32 MSB-first character bits.
def find.bit(cursor: String, off: Nat) -> Bool:
  match cursor off:
    case SNil{} _: False{}
    case SCon{_, _} 0n: True{}
    case SCon{Chr{word}, _} 1n+bit: Map.bit.u(word, Nat.sub(31n, bit))

def find.cursor(index: Nat, +suffix: String, off: Nat) -> FindCursor:
  FindCursor{index, suffix, find.bit(suffix, off)}

def find.next.reset(reset: Bool, +key: String, +index: Nat, suffix: String, +ci: Nat, off: Nat) -> FindCursor:
  match reset:
    case False{}: find.cursor(ci, find.seek(suffix, Nat.sub(ci, index)), off)
    case True{}: find.cursor(ci, find.seek(key, ci), off)

def find.next.at(co: Nat & Nat, +key: String, +index: Nat, suffix: String) -> FindCursor:
  match co:
    case Tuple{+ci, off}: find.next.reset(Nat.is_lt(ci, index), key, index, suffix, ci, off)

def find.next(+key: String, index: Nat, suffix: String, position: Nat) -> FindCursor:
  find.next.at(Nat.divmod(position, 33n), key, index, suffix)

def find.go(-V: Data, +map: Map<&2, V>, +key: String, cursor: FindCursor) -> Maybe<&2, V>:
  match map cursor:
    case MTip{} _: None{}
    case MLeaf{k, v} _: find.leaf(V, v, String.eq(key, k))
    case MNode{_, +lo, _} FindCursor{index, suffix, False{}}:
      find.go(V, lo, key, find.next(key, index, suffix, find.position(V, lo)))
    case MNode{_, _, +hi} FindCursor{index, suffix, True{}}:
      find.go(V, hi, key, find.next(key, index, suffix, find.position(V, hi)))

def find(-V: Data, +map: Map<&2, V>, +key: String) -> Maybe<&2, V>:
  find.go(V, map, key, find.next(key, 0n, key, find.position(V, map)))

# Checked constructors end in a literal canonical family, under telescopes.
# Non-declaration-shaped types retain the checker's general reduction path.
def constructor_owner(+ty: Ast.SyntaxTerm) -> Maybe<&2, String>:
  match ty:
    case Ast.TermAll{_, _, _, _, body, _}: constructor_owner(body)
    case Ast.TermAdt{key, _, _, _}: Some{key}
    case _: None{}
