import Base
import ../../bend2/selfhost/ast.bend as Ast
import ../../bend2/selfhost/core.bend as Core

def sp(beg: Nat, end: Nat) -> Ast.SourceSpan:
  Ast.SpanOf{ "core", beg, end}

def var_index(term: Ast.SyntaxTerm) -> Nat:
  match term:
    case Ast.TermVar{ _, index,  _}: index
    case _: 999n

def var_key(term: Ast.SyntaxTerm) -> String:
  match term:
    case Ast.TermVar{key,  _,  _}: key
    case Ast.TermRef{key,  _}: key
    case _: "bad"

def body_of(term: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  match term:
    case Ast.TermLam{ _,  _,  _, body,  _}: body
    case Ast.TermAll{ _,  _,  _,  _, body,  _}: body
    case Ast.BodyLocal{ _,  _,  _, body,  _}: body
    case Ast.BodyCase{ _, body,  _}: body
    case Ast.TermSub{ _,  _, body,  _}: body
    case _: Ast.TermQuant{}

def var_beg(term: Ast.SyntaxTerm) -> Nat:
  match term:
    case Ast.TermVar{ _,  _,  Ast.SpanOf{ _, beg,  _}}: beg
    case _: 999n

def ann_var_is(term: Ast.SyntaxTerm, +key: String, +index: Nat) -> Bool:
  match term:
    case Ast.TermAnn{ value, ty,  _}:
      match value:
        case Ast.TermVar{ value_key,  value_index,  _}:
          match ty:
            case Ast.TermVar{ type_key,  type_index,  _}: Bool.and(Bool.and(String.eq(key, value_key), Nat.is_eq(index, value_index)), Bool.and(String.eq(key, type_key), Nat.is_eq(index, type_index)))
            case _: False{}
        case _: False{}
    case _: False{}

def ann_ref_is(term: Ast.SyntaxTerm, +key: String) -> Bool:
  match term:
    case Ast.TermAnn{ value, ty,  _}:
      match value:
        case Ast.TermRef{ value_key,  _}:
          match ty:
            case Ast.TermRef{ type_key,  _}: Bool.and(String.eq(key, value_key), String.eq(key, type_key))
            case _: False{}
        case _: False{}
    case _: False{}
def template_inner(term: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  match term:
    case Ast.TermTemplate{ inner,  _}: inner
    case _: Ast.TermQuant{}

def fill_head(term: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  match term:
    case Ast.TermFill{head,  _,  _}: head
    case _: Ast.TermQuant{}

def fill_arg(term: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  match term:
    case Ast.TermFill{ _, args,  _}:
      match args:
        case +arg <> _: arg
        case _: Ast.TermQuant{}
    case _: Ast.TermQuant{}

def plus_head(term: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  match term:
    case Ast.TermPlus{head,  _,  _}: head
    case _: Ast.TermQuant{}

def plus_arg(term: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  match term:
    case Ast.TermPlus{ _, args,  _}:
      match args:
        case +arg <> _: arg
        case _: Ast.TermQuant{}
    case _: Ast.TermQuant{}
def bang_inner(term: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  match term:
    case Ast.TermBang{ inner,  _}: inner
    case _: Ast.TermQuant{}

law main:
  IO(Unit)

def main():
  +x = {Ast.TermVar{ "x",  0n,  sp(10n, 11n)} : Ast.SyntaxTerm}
  +global = {Ast.TermRef{ "Global",  sp(20n, 26n)} : Ast.SyntaxTerm}
  +sub = {Ast.TermSub{ 0n,  global,  Ast.TermVar{ "free",  1n,  sp(80n, 84n)},  sp(79n, 84n)} : Ast.SyntaxTerm}
  +lam = {Ast.TermLam{ None{},  "x",  0n,  Ast.TermVar{ "x",  1n,  sp(30n, 31n)},  sp(29n, 31n)} : Ast.SyntaxTerm}
  +all = {Ast.TermAll{ Ast.QOne{},  "a",  0n,  x,  Ast.TermVar{ "a",  1n,  sp(40n, 41n)},  sp(39n, 41n)} : Ast.SyntaxTerm}
  +local = {Ast.BodyLocal{ [Ast.PatternVar{ "p",  0n,  Ast.QMany{},  sp(50n, 51n)}],  Ast.QMany{},  [x],  Ast.TermVar{ "p",  1n,  sp(52n, 53n)},  sp(50n, 53n)} : Ast.SyntaxTerm}
  +branch = {Ast.BodyCase{ [Ast.PatternCtr{ "Pair",  [Ast.PatternVar{ "p",  0n,  Ast.QMany{},  sp(60n, 61n)}, Ast.PatternVar{ "q",  1n,  Ast.QMany{},  sp(62n, 63n)}],  sp(60n, 63n)}],  Ast.TermVar{ "q",  2n,  sp(64n, 65n)},  sp(60n, 65n)} : Ast.SyntaxTerm}
  shadow_lam = {Ast.TermLam{ None{},  "shadow",  0n,  Ast.TermVar{ "shadow",  0n,  sp(70n, 71n)},  sp(69n, 71n)} : Ast.SyntaxTerm}
  +ann = {Ast.TermAnn{ x,  x,  sp(12n, 13n)} : Ast.SyntaxTerm}
  fill = {Ast.TermFill{ x,  [x],  sp(14n, 15n)} : Ast.SyntaxTerm}
  plus = {Ast.TermPlus{ x,  [x],  sp(16n, 17n)} : Ast.SyntaxTerm}
  wrapped_fill = {Ast.TermTemplate{ fill,  sp(14n, 15n)} : Ast.SyntaxTerm}
  +bang = {Ast.TermBang{ x,  sp(18n, 19n)} : Ast.SyntaxTerm}
  shifted_sub = Core.shift(0n, 2n, sub)
  sub_sub = Core.subst(0n, global, sub)
  shifted_lam = Core.shift(0n, 2n, lam)
  shifted_all = Core.shift(0n, 2n, all)
  shifted_local = Core.shift(0n, 2n, local)
  shifted_case = Core.shift(0n, 2n, branch)
  sub_all = Core.subst(0n, global, all)
  sub_local = Core.subst(0n, global, local)
  sub_lam = Core.subst(0n, global, lam)
  sub_case = Core.subst(0n, global, branch)
  shifted_ann = Core.shift(0n, 2n, ann)
  sub_ann = Core.subst(0n, global, ann)
  +shifted_fill = Core.shift(0n, 2n, wrapped_fill)
  +sub_plus = Core.subst(0n, global, plus)
  shifted_bang = Core.shift(0n, 2n, bang)
  sub_bang = Core.subst(0n, global, bang)
  do IO<Unit>:
    IO.print(String.join([Nat.show(var_index(body_of(shifted_sub))), ",", var_key(body_of(sub_sub)), ",", Nat.show(var_index(body_of(shifted_lam))), ",", Nat.show(var_index(body_of(shifted_all))), ",", Nat.show(var_index(body_of(shifted_local))), ",", Nat.show(var_index(body_of(shifted_case))), ",", Nat.show(var_index(body_of(local))), ",", var_key(Core.shift(0n, 3n, x)), ",", Nat.show(var_beg(Core.shift(0n, 3n, x))), ",", var_key(body_of(sub_lam)), ",", var_key(body_of(sub_all)), ",", var_key(body_of(sub_local)), ",", var_key(body_of(sub_case)), ",", Nat.show(var_index(body_of(Core.shift(0n, 2n, shadow_lam)))), ",", var_key(global), ",", Nat.show(var_beg(global))], ""))
    IO.print(Bool.pick(String, Bool.and(ann_var_is(shifted_ann, "x", 2n), ann_ref_is(sub_ann, "Global")), "annotation-ok", "annotation-failed"))
    IO.print(Bool.pick(String, Bool.and(Bool.and(Nat.is_eq(var_index(fill_head(template_inner(shifted_fill))), 2n), Nat.is_eq(var_index(fill_arg(template_inner(shifted_fill))), 2n)), Bool.and(String.eq(var_key(plus_head(sub_plus)), "Global"), String.eq(var_key(plus_arg(sub_plus)), "Global"))), "traversal-ok", "traversal-failed"))
    IO.print(Bool.pick(String, Bool.and(Nat.is_eq(var_index(bang_inner(shifted_bang)), 2n), String.eq(var_key(bang_inner(sub_bang)), "Global")), "bang-ok", "bang-failed"))

#|3,Global,3,3,3,4,1,x,10,Global,Global,Global,Global,0,Global,20
#| annotation-ok
#| traversal-ok
#| bang-ok

