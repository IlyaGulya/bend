# String values in family indices, not only runtime String expressions.
import Base

type Label<-text: String> is Data:
  Label{}

type Labels is Type:
  Labels{empty: Label<"">, ascii: Label<"abc">, astral: Label<"\u{1f600}">, nul: Label<"\u{0}">}

def count(value: Labels) -> U32:
  match value:
    case Labels{Label{}, Label{}, Label{}, Label{}}: 4

def main() -> IO(Unit):
  IO.print(U32.show(count(Labels{Label{}, Label{}, Label{}, Label{}})))

#|4
