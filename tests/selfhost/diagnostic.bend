import Base
import ../../bend2/selfhost/ast.bend as AST
import ../../bend2/selfhost/diagnostic.bend as Diagnostic

law main:
  IO(Unit)

def main():
  IO.print(Diagnostic.format("parse failed", "a term", "')'", AST.SpanOf{ "example.bend",  3n,  4n}, "\n🙂x"))


#| Error: parse failed
#| - expected: a term
#| - observed: ')'
#| Location: example.bend:2:3
#|  2 | 🙂x
#|    |   ^