# SHOW data-kind regression for the C target: a pure main whose value is Base
# data, not a word. Base marks List native for its representation, and the
# reference show still prints it as data (kind 7, one arm record per
# constructor) because only U32, F32, Nat, Char, String, Eql and Array have a
# fixed kind. The C descriptor must carry the two List arms, their CIDs, the
# Con field offsets and each arm's bracket, so this run prints the list itself.
import Base

def main() -> List<U32>:
  [1, 2]

#|Con(1, 2, Nil)
