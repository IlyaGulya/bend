import Base
import ../../bend2/selfhost/ast.bend as Ast
import ../../bend2/selfhost/core.bend as Core

def source_span() -> Ast.SourceSpan:
  Ast.SpanOf{"capture", 0n, 1n}

def pair() -> Ast.SyntaxTerm:
  +span = source_span()
  Ast.TermCtr{"pair", [Ast.TermVar{"left", 0n, span}, Ast.TermVar{"right", 1n, span}], span}

def shifted_ok(term: Ast.SyntaxTerm, by: Nat) -> Bool:
  match term:
    case Ast.TermCtr{key, Ast.TermVar{left, a, _} <> Ast.TermVar{right, b, _} <> Nil{}, _}:
      Bool.and(String.eq(key, "pair"), Bool.and(String.eq(left, "left"), Bool.and(String.eq(right, "right"), Bool.and(Nat.is_eq(a, 0n), Nat.is_eq(b, (1n + by : Nat))))))
    case _: False{}

def substituted_ok(term: Ast.SyntaxTerm, replacement: String) -> Bool:
  match term:
    case Ast.TermCtr{key, Ast.TermRef{found, _} <> Ast.TermVar{right, index, _} <> Nil{}, _}:
      Bool.and(String.eq(key, "pair"), Bool.and(String.eq(found, replacement), Bool.and(String.eq(right, "right"), Nat.is_eq(index, 0n))))
    case _: False{}

def result(ok: Bool) -> String:
  match ok:
    case True{}: "capture-ok"
    case False{}: "capture-failed"

def run(+seed: U32) -> String:
  +by = U32.to_nat(seed)
  +replacement = U32.show(seed)
  shifted = Core.shift(1n, by, pair())
  substituted = Core.subst(0n, Ast.TermRef{replacement, Ast.SpanOf{"capture", 0n, 1n}}, pair())
  result(Bool.and(shifted_ok(shifted, by), substituted_ok(substituted, replacement)))

def main() -> IO(Unit):
  do IO<Unit>:
    seed : U32 <- IO.thread_count()
    IO.print(run(seed))

#|capture-ok
