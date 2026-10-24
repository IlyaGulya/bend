# A dependent/erased value is displayed through canonical type descriptors:
# List is indexed by its element quantity and Maybe by its element type, both
# erased at run time, while main's printer must still spell every element.
import Base

law main:
  List<&1, Maybe<&1, U32>>

def main():
  [Some{1}, None{}, Some{4294967295}]

#|[Some{1}, None{}, Some{4294967295}]
