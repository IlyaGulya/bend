import Base
import ./ast.bend as Ast


def pattern_list_depth(patterns: List<&2, Ast.SyntaxPattern>) -> Nat:
  match patterns:
    case Nil{}:
      0n
    case +pattern <> rest:
      match pattern:
        case Ast.PatternVar{key, index, quantity, span}:
          1n + pattern_list_depth(rest)
        case Ast.PatternCtr{key, fields, span}:
          pattern_list_depth(fields) + pattern_list_depth(rest)



def shift_var(shifted: Bool, key: String, index: Nat, by: Nat, span: Ast.SourceSpan) -> Ast.SyntaxTerm:
  match shifted:
    case True{}:
      Ast.TermVar{key, index + by, span}
    case False{}:
      Ast.TermVar{key, index, span}

@unsafe
def map_syntax_terms(+f: Ast.SyntaxTerm -> Ast.SyntaxTerm, terms: List<&2, Ast.SyntaxTerm>) -> List<&2, Ast.SyntaxTerm>:
  match terms:
    case Nil{}:
      Nil{}
    case +term <> rest:
      f(term) <> map_syntax_terms(f, rest)

@unsafe
def shift_at(term: Ast.SyntaxTerm, +cutoff: Nat, +by: Nat, +depth: Nat) -> Ast.SyntaxTerm:
  match term:
    case Ast.TermVar{key, +index, span}:
      shift_var(Nat.is_ge(index, Nat.add(cutoff, depth)), key, index, by, span)
    case Ast.TermRef{key, span}: Ast.TermRef{key, span}
    case Ast.TermBang{inner, span}: Ast.TermBang{shift_at(inner, cutoff, by, depth), span}
    case Ast.TermSub{index, value, body, span}:
      Ast.TermSub{index, shift_at(value, cutoff, by, depth), shift_at(body, cutoff, by, depth + 1n), span}
    case Ast.TermLet{+keys, indexes, quantities, values, body, span}:
      Ast.TermLet{keys, indexes, quantities, map_syntax_terms(value => shift_at(value, cutoff, by, depth), values), shift_at(body, cutoff, by, depth + List.length(&2, String, keys)), span}
    case Ast.TermAnn{value, ty, span}: Ast.TermAnn{shift_at(value, cutoff, by, depth), shift_at(ty, cutoff, by, depth), span}
    case Ast.TermTemplate{value, span}: Ast.TermTemplate{shift_at(value, cutoff, by, depth), span}
    case Ast.TermType{kind, span}: Ast.TermType{shift_at(kind, cutoff, by, depth), span}
    case Ast.TermQuant{}: Ast.TermQuant{}
    case Ast.TermQuantity{quantity, span}: Ast.TermQuantity{quantity, span}
    case Ast.TermMin{left, right, span}: Ast.TermMin{shift_at(left, cutoff, by, depth), shift_at(right, cutoff, by, depth), span}
    case Ast.TermAll{quantity, key, index, ty, body, span}:
      Ast.TermAll{quantity, key, index, shift_at(ty, cutoff, by, depth), shift_at(body, cutoff, by, depth + 1n), span}
    case Ast.TermLam{quantity, key, index, body, span}:
      Ast.TermLam{quantity, key, index, shift_at(body, cutoff, by, depth + 1n), span}
    case Ast.TermApp{fn, arg, span}: Ast.TermApp{shift_at(fn, cutoff, by, depth), shift_at(arg, cutoff, by, depth), span}
    case Ast.TermAdt{key, args, refs, span}: Ast.TermAdt{key, map_syntax_terms(value => shift_at(value, cutoff, by, depth), args), refs, span}
    case Ast.TermFill{head, args, span}: Ast.TermFill{shift_at(head, cutoff, by, depth), map_syntax_terms(value => shift_at(value, cutoff, by, depth), args), span}
    case Ast.TermPlus{head, args, span}: Ast.TermPlus{shift_at(head, cutoff, by, depth), map_syntax_terms(value => shift_at(value, cutoff, by, depth), args), span}
    case Ast.TermCtr{key, args, span}: Ast.TermCtr{key, map_syntax_terms(value => shift_at(value, cutoff, by, depth), args), span}
    case Ast.TermMat{key, head, matched, span}: Ast.TermMat{key, shift_at(head, cutoff, by, depth), shift_at(matched, cutoff, by, depth), span}
    case Ast.TermAbsurd{span}: Ast.TermAbsurd{span}
    case Ast.TermEqual{left, right, ty, span}: Ast.TermEqual{shift_at(left, cutoff, by, depth), shift_at(right, cutoff, by, depth), shift_at(ty, cutoff, by, depth), span}
    case Ast.TermRefl{span}: Ast.TermRefl{span}
    case Ast.TermRewrite{equation, proof, body, span}: Ast.TermRewrite{shift_at(equation, cutoff, by, depth), shift_at(proof, cutoff, by, depth), shift_at(body, cutoff, by, depth), span}
    case Ast.TermHole{key, span}: Ast.TermHole{key, span}
    case Ast.BodyMatch{scrutinees, cases, span}: Ast.BodyMatch{map_syntax_terms(value => shift_at(value, cutoff, by, depth), scrutinees), map_syntax_terms(value => shift_at(value, cutoff, by, depth), cases), span}
    case Ast.BodyCase{+patterns, body, span}: Ast.BodyCase{patterns, shift_at(body, cutoff, by, depth + pattern_list_depth(patterns)), span}
    case Ast.BodyLocal{+patterns, quantity, values, body, span}: Ast.BodyLocal{patterns, quantity, map_syntax_terms(value => shift_at(value, cutoff, by, depth), values), shift_at(body, cutoff, by, depth + pattern_list_depth(patterns)), span}
    case Ast.BodyReply{term, span}: Ast.BodyReply{shift_at(term, cutoff, by, depth), span}

def shift(cutoff: Nat, by: Nat, term: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  shift_at(term, cutoff, by, 0n)

def subst_var(is_target: Bool, is_above: Bool, depth: Nat, replacement: Ast.SyntaxTerm, key: String, found: Nat, span: Ast.SourceSpan) -> Ast.SyntaxTerm:
  match is_target:
    case True{}:
      shift(0n, depth, replacement)
    case False{}:
      match is_above:
        case True{}:
          Ast.TermVar{key, found - 1n, span}
        case False{}:
          Ast.TermVar{key, found, span}

@unsafe
def subst_at(+index: Nat, +replacement: Ast.SyntaxTerm, +depth: Nat, term: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  match term:
    case Ast.TermVar{key, +found, span}:
      +target = index + depth
      subst_var(Nat.is_eq(found, target), Nat.is_gt(found, target), depth, replacement, key, found, span)
    case Ast.TermRef{key, span}: Ast.TermRef{key, span}
    case Ast.TermBang{inner, span}: Ast.TermBang{subst_at(index, replacement, depth, inner), span}
    case Ast.TermSub{sub_index, value, body, span}:
      Ast.TermSub{sub_index, subst_at(index, replacement, depth, value), subst_at(index, replacement, depth + 1n, body), span}
    case Ast.TermLet{+keys, indexes, quantities, values, body, span}:
      Ast.TermLet{keys, indexes, quantities, map_syntax_terms(value => subst_at(index, replacement, depth, value), values), subst_at(index, replacement, depth + List.length(&2, String, keys), body), span}
    case Ast.TermAnn{value, ty, span}: Ast.TermAnn{subst_at(index, replacement, depth, value), subst_at(index, replacement, depth, ty), span}
    case Ast.TermTemplate{value, span}: Ast.TermTemplate{subst_at(index, replacement, depth, value), span}
    case Ast.TermType{kind, span}: Ast.TermType{subst_at(index, replacement, depth, kind), span}
    case Ast.TermQuant{}: Ast.TermQuant{}
    case Ast.TermQuantity{quantity, span}: Ast.TermQuantity{quantity, span}
    case Ast.TermMin{left, right, span}: Ast.TermMin{subst_at(index, replacement, depth, left), subst_at(index, replacement, depth, right), span}
    case Ast.TermAll{quantity, key, binder_index, ty, body, span}:
      Ast.TermAll{quantity, key, binder_index, subst_at(index, replacement, depth, ty), subst_at(index, replacement, depth + 1n, body), span}
    case Ast.TermLam{quantity, key, binder_index, body, span}:
      Ast.TermLam{quantity, key, binder_index, subst_at(index, replacement, depth + 1n, body), span}
    case Ast.TermApp{fn, arg, span}: Ast.TermApp{subst_at(index, replacement, depth, fn), subst_at(index, replacement, depth, arg), span}
    case Ast.TermAdt{key, args, refs, span}: Ast.TermAdt{key, map_syntax_terms(value => subst_at(index, replacement, depth, value), args), refs, span}
    case Ast.TermFill{head, args, span}: Ast.TermFill{subst_at(index, replacement, depth, head), map_syntax_terms(value => subst_at(index, replacement, depth, value), args), span}
    case Ast.TermPlus{head, args, span}: Ast.TermPlus{subst_at(index, replacement, depth, head), map_syntax_terms(value => subst_at(index, replacement, depth, value), args), span}
    case Ast.TermCtr{key, args, span}: Ast.TermCtr{key, map_syntax_terms(value => subst_at(index, replacement, depth, value), args), span}
    case Ast.TermMat{key, head, matched, span}: Ast.TermMat{key, subst_at(index, replacement, depth, head), subst_at(index, replacement, depth, matched), span}
    case Ast.TermAbsurd{span}: Ast.TermAbsurd{span}
    case Ast.TermEqual{left, right, ty, span}:
      Ast.TermEqual{subst_at(index, replacement, depth, left), subst_at(index, replacement, depth, right), subst_at(index, replacement, depth, ty), span}
    case Ast.TermRefl{span}: Ast.TermRefl{span}
    case Ast.TermRewrite{equation, proof, body, span}:
      Ast.TermRewrite{subst_at(index, replacement, depth, equation), subst_at(index, replacement, depth, proof), subst_at(index, replacement, depth, body), span}
    case Ast.TermHole{key, span}: Ast.TermHole{key, span}
    case Ast.BodyMatch{scrutinees, cases, span}:
      Ast.BodyMatch{map_syntax_terms(value => subst_at(index, replacement, depth, value), scrutinees), map_syntax_terms(value => subst_at(index, replacement, depth, value), cases), span}
    case Ast.BodyCase{+patterns, body, span}:
      Ast.BodyCase{patterns, subst_at(index, replacement, depth + pattern_list_depth(patterns), body), span}
    case Ast.BodyLocal{+patterns, quantity, values, body, span}:
      Ast.BodyLocal{patterns, quantity, map_syntax_terms(value => subst_at(index, replacement, depth, value), values), subst_at(index, replacement, depth + pattern_list_depth(patterns), body), span}
    case Ast.BodyReply{term, span}: Ast.BodyReply{subst_at(index, replacement, depth, term), span}

def subst(index: Nat, replacement: Ast.SyntaxTerm, term: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  subst_at(index, replacement, 0n, term)
