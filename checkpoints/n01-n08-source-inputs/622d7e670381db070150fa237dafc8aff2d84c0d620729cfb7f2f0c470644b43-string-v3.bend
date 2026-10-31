# Retain string-index descriptors in aggregate field types while giving every
# child a live word; the zero-field aggregate failed C packed-node admission.
import Base

type Label<-text: String> is Type:
  Label{value: U32}

type Labels is Type:
  Labels{empty: Label<"">, ascii: Label<"abc">, astral: Label<"\u{1f600}">, nul: Label<"\u{0}">}

def count(value: Labels) -> U32:
  match value:
    case Labels{Label{a}, Label{b}, Label{c}, Label{d}}:
      U32.add(U32.add(a, b), U32.add(c, d))

def main() -> IO(Unit):
  IO.print(U32.show(count(Labels{Label{1}, Label{1}, Label{1}, Label{1}})))

#|4
