import Base
import ./ast.bend as Ast


# One read-only trie lookup for every index. Base owns the walk because Base
# declares the Map layout: the native compiler lowers it to a single in-place
# pass with one cursor over the query and non-consuming string comparison, and
# every other lane runs the same portable source. The map and the query are
# consumed and a hit shares the value the map held, so public MNode positions
# (including backward or arbitrary ones) answer exactly as Map.bit reads them.
def find(-V: Data, +map: Map<&2, V>, +key: String) -> Maybe<&2, V>:
  Map.find(V, map, key)

# Checked constructors end in a literal canonical family, under telescopes.
# Non-declaration-shaped types retain the checker's general reduction path.
def constructor_owner(+ty: Ast.SyntaxTerm) -> Maybe<&2, String>:
  match ty:
    case Ast.TermAll{_, _, _, _, body, _}: constructor_owner(body)
    case Ast.TermAdt{key, _, _, _}: Some{key}
    case _: None{}
