import Base
import ../../bend2/selfhost/ast.bend as Ast
import ../../bend2/selfhost/checker_arena.bend as Arena

# These variants do not occur in the frozen compiler root. Preserve every field.
def span() -> Ast.SourceSpan:
  Ast.SpanOf{"😀λ.bend", Nat.add(4294967295n, 1n), Nat.add(4294967295n, 3n)}

def span_ok(value: Ast.SourceSpan) -> Bool:
  match value:
    case Ast.SpanOf{file, beg, end}:
      Bool.and(String.eq(file, "😀λ.bend"), Bool.and(Nat.is_eq(beg, Nat.add(4294967295n, 1n)), Nat.is_eq(end, Nat.add(4294967295n, 3n))))

def score(value: Arena.Node) -> U32:
  match value:
    case Arena.TermLet{a, b, c, d, e, f, g, h, body, src_span}:
      Bool.pick(U32, span_ok(src_span), U32.add(a, U32.add(b, U32.add(c, U32.add(d, U32.add(e, U32.add(f, U32.add(g, U32.add(h, body)))))))), 0)
    case Arena.TermSub{index, value, body, src_span}:
      Bool.pick(U32, Bool.and(Nat.is_eq(index, Nat.add(4294967295n, 2n)), span_ok(src_span)), U32.add(value, body), 0)
    case Arena.TermHole{key, src_span}: Bool.pick(U32, span_ok(src_span), key, 0)
    case Arena.TermMat{key, head, matched, src_span}: Bool.pick(U32, span_ok(src_span), U32.add(key, U32.add(head, matched)), 0)
    case Arena.TermTemplate{term, src_span}: Bool.pick(U32, span_ok(src_span), term, 0)
    case Arena.TermVar{key, index, src_span}: Bool.pick(U32, Bool.and(Nat.is_eq(index, Nat.add(4294967295n, 7n)), span_ok(src_span)), key, 0)
    case _: 0

def result(result: CompilerRows(Arena.Node) & Arena.Node) -> U32:
  match result:
    case Tuple{rows, value}: score(value)

def roundtrip(value: Arena.Node) -> U32:
  result(CompilerRows.get(Arena.Node, CompilerRows.append(Arena.Node, CompilerRows.new(Arena.Node, 0n, Arena.TermQuant{}), value), 0))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(roundtrip(Arena.TermLet{1, 2, 3, 4, 5, 6, 7, 8, 9, span()})))
    IO.print(U32.show(roundtrip(Arena.TermSub{Nat.add(4294967295n, 2n), 4294967295, 3, span()})))
    IO.print(U32.show(roundtrip(Arena.TermHole{4294967295, span()})))
    IO.print(U32.show(roundtrip(Arena.TermMat{11, 13, 17, span()})))
    IO.print(U32.show(roundtrip(Arena.TermTemplate{101, span()})))
    IO.print(U32.show(roundtrip(Arena.TermVar{103, Nat.add(4294967295n, 7n), span()})))

#|45
#|2
#|4294967295
#|41
#|101
#|103
