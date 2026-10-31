# Four descriptor-string indices with a single live U32 record field.
# Uses the one-field erased-index box pattern from
# tests/compile/erased_argument.bend:5-16, and value-indexed families from
# tests/compile/gpu_reach_closure_instances.bend:15-16.
# There is no aggregate of four zero-field indexed constructors.
import Base

type Label<-text: String> is Type:
  Label{value: U32}

# The four literal paths are in ordinary parameter-type descriptors.
# lower_catalog.telescope_binder calls descriptor on each binder type.
def empty(value: Label<"">) -> U32:
  match value:
    case Label{x}: x

def ascii(value: Label<"abc">) -> U32:
  match value:
    case Label{x}: x

def astral(value: Label<"\u{1f600}">) -> U32:
  match value:
    case Label{x}: x

def nul(value: Label<"\u{0}">) -> U32:
  match value:
    case Label{x}: x

def main() -> IO(Unit):
  IO.print(U32.show(U32.add(U32.add(empty(Label{1}), ascii(Label{1})), U32.add(astral(Label{1}), nul(Label{1})))))

#|4
