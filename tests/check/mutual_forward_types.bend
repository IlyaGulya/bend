# A datatype is a header, not code: the native book declares every family up
# front, so a field, index telescope or kind may name a family declared later in
# the same module. This pins the forward index telescope, a two-way mutual field
# pair and a three-family cycle in one checked, runnable program; only live
# definitions keep to source order.
import Base

# B is declared before the index type in its telescope.
type Indexed<X: A> is Data:
  MkIndexed{}

type A is Data:
  MkA{}

# A two-way mutual field pair with a finite base sector.
type Layout is Data:
  LayoutWord{word: U32}
  LayoutData{arms: LayArm}

type LayArm is Data:
  LayArm{fields: Layout}

# The three-family cycle of the CLay form/nest group.
type Nest is Data:
  Nest{make: Fill}

type Fill is Data:
  FillWord{}
  FillForm{arms: FormArm}

type FormArm is Data:
  FormArm{fields: Nest}

def layout_word(l: Layout) -> U32:
  match l:
    case LayoutWord{w}: w
    case LayoutData{arms}: 40

def fill_tag(f: Fill) -> U32:
  match f:
    case FillWord{}: 0
    case FillForm{arms}: 7

def indexed_tag(i: Indexed<MkA{}>) -> U32:
  5

def main() -> U32:
  (layout_word(LayoutData{LayArm{LayoutWord{2}}}) + fill_tag(FillForm{FormArm{Nest{FillWord{}}}}) + indexed_tag(MkIndexed{}) : U32)

#|52
