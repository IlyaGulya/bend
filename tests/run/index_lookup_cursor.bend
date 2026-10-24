import Base
import ../../bend2/selfhost/index_lookup.bend as IndexLookup

def lookup(map: Map<&2, U32>, key: String) -> String:
  U32.show(Maybe.default(&2, U32, IndexLookup.find(U32, map, key), 999))

# Public Map constructors may move backward, even though Map.set does not.
def backward_character() -> Map<&2, U32>:
  MNode{33n, MTip{}, MNode{32n, MLeaf{"ab", 2}, MLeaf{"ab", 1}}}

def backward_bit() -> Map<&2, U32>:
  MNode{32n, MTip{}, MNode{1n, MLeaf{"ab", 8}, MTip{}}}

def past_end_reset() -> Map<&2, U32>:
  MNode{132n, MNode{32n, MTip{}, MLeaf{"ab", 9}}, MTip{}}

# A NUL has a presence bit; it is not an exhausted key.
def nul_key() -> Map<&2, U32>:
  MNode{0n, MLeaf{"", 5}, MLeaf{"\u{0}A", 10}}

# Positions count Unicode scalars, not UTF-16 code units or UTF-8 bytes.
def supplementary_key() -> Map<&2, U32>:
  MNode{33n, MTip{}, MNode{32n, MLeaf{"🙂a", 12}, MTip{}}}

def prefixes() -> Map<&2, U32>:
  Map.set(&2, U32, Map.set(&2, U32, MTip{}, "a", 21), "ab", 22)

def main() -> IO(Unit):
  IO.print(String.join([
    lookup(MTip{}, "ab"),
    lookup(MLeaf{"a", 3}, "ab"),
    lookup(backward_character(), "ab"),
    lookup(backward_bit(), "ab"),
    lookup(past_end_reset(), "ab"),
    lookup(nul_key(), ""),
    lookup(nul_key(), "\u{0}A"),
    lookup(supplementary_key(), "🙂a"),
    lookup(prefixes(), "a"),
    lookup(prefixes(), "ab"),
    lookup(prefixes(), "abc")
  ], ","))

#|999,999,1,8,9,5,10,12,21,22,999
