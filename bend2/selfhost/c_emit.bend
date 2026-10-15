import Base
import ./ast.bend as AST
import ./core.bend as Core
import ./c_parts.bend as CParts
import ./c_assemble.bend as CAssembly
import ./loaded_module.bend as Loader
import ./c_foreign.bend as CForeign

type EmitResult is Data:
  EmitSuccess{source: String}
  EmitFailure{message: String, span: AST.SourceSpan}
type RuntimeReadResult is Data:
  RuntimeReadSuccess{source: String}
  RuntimeReadFailure{message: String}


type IndexedDefinition is Data:
  IndexedDefinition{namespace: String, key: String, full_key: String, binders: List<&2, AST.TelescopeItem>, result: AST.OptionalTerm, body: AST.DefBody, unsafe: Bool, span: AST.SourceSpan}
type LiftedTerm is Data:
  LiftedTerm{term: AST.SyntaxTerm, helpers: List<&2, IndexedDefinition>}
type LiftedTerms is Data:
  LiftedTerms{terms: List<&2, AST.SyntaxTerm>, helpers: List<&2, IndexedDefinition>}

type IndexedConstructor is Data:
  IndexedConstructor{namespace: String, key: String, full_key: String, fields: List<&2, AST.TelescopeItem>}

type IndexedType is Data:
  IndexedType{namespace: String, key: String, full_key: String, params: List<&2, AST.TelescopeItem>, kind: AST.SyntaxTerm, constructors: List<&2, AST.ConstructorDecl>, span: AST.SourceSpan}

type PatternOpen is Data:
  PatternOpen{source: String, values: List<&2, String>, next: Nat}
type MainConstant is Data:
  MainNat{value: Nat}
  MainU32{value: Nat}
  MainBool{value: Nat}
  MainF32{value: Nat}
def c_lambda_key(span: AST.SourceSpan) -> String:
  match span:
    case AST.SpanOf{file, beg, end}:
      String.concat(["__lambda_", c_identifier(file), "_", Nat.show(beg), "_", Nat.show(end)])

def c_lambda_binders(count: Nat, index: Nat, span: AST.SourceSpan) -> List<&2, AST.TelescopeItem>:
  match count:
    case 0n: Nil{}
    case 1n+remaining:
      name = String.append("_capture", Nat.show(index))
      ty = AST.TermRef{ "Nat", span}
      AST.Binder{ AST.QMany{},  name, index, ty, span} <> c_lambda_binders(remaining, index + 1n, span)

def c_lambda_definition(term: AST.SyntaxTerm, captures: Nat, span: AST.SourceSpan) -> IndexedDefinition:
  key = c_lambda_key(span)
  IndexedDefinition{
     "",
    key,
     key,
     c_lambda_binders(captures + 1n, 0n, span),
     AST.NoTerm{},
     AST.DefTerm{term},
     False{},
    span
  }

def c_pattern_var_count(pattern: AST.SyntaxPattern) -> Nat:
  match pattern:
    case AST.PatternVar{ _,  _,  _,  _}: 1n
    case AST.PatternCtr{ _, fields,  _}: c_pattern_vars_count(fields)

def c_pattern_vars_count(patterns: List<&2, AST.SyntaxPattern>) -> Nat:
  match patterns:
    case Nil{}: 0n
    case +pattern <> rest: c_pattern_var_count(pattern) + c_pattern_vars_count(rest)
def c_collect_terms(terms: List<&2, AST.SyntaxTerm>, arity: Nat, locals: Nat) -> List<&2, IndexedDefinition>:
  match terms:
    case Nil{}: Nil{}
    case +term <> rest:
      List.append(&2, IndexedDefinition, c_term_lambdas(term, arity, locals), c_collect_terms(rest, arity, locals))

def c_collect_cases(cases: List<&2, AST.SyntaxTerm>, arity: Nat, locals: Nat) -> List<&2, IndexedDefinition>:
  match cases:
    case Nil{}: Nil{}
    case +term <> rest:
      match term:
        case AST.BodyCase{patterns, body,  _}:
          one = c_term_lambdas(body, arity, locals + c_pattern_vars_count(patterns))
          List.append(&2, IndexedDefinition, one, c_collect_cases(rest, arity, locals))
        case _: c_collect_cases(rest, arity, locals)

def c_term_lambdas(term: AST.SyntaxTerm, arity: Nat, locals: Nat) -> List<&2, IndexedDefinition>:
  match term:
    case AST.TermLam{ Some{ AST.QZero{}},  _,  _, body,  _}:
      c_term_lambdas(body, arity, locals + 1n)
    case AST.TermLam{ _,  _,  _, body, span}:
      c_lambda_definition(term, captures, span) <> c_term_lambdas(body, captures + 1n, 0n)
    case AST.TermBang{term,  _}: c_term_lambdas(term, arity, locals)
    case AST.TermApp{fn, arg,  _}:
      List.append(&2, IndexedDefinition, c_term_lambdas(fn, arity, locals), c_term_lambdas(arg, arity, locals))
    case AST.TermAnn{term,  _,  _}: c_term_lambdas(term, arity, locals)
    case AST.TermTemplate{term,  _}: c_term_lambdas(term, arity, locals)
    case AST.TermSub{index, value, body,  _}:
      c_term_lambdas(Core.subst(index, value, body), arity, locals)
    case AST.TermLet{ _,  _,  _, values, body,  _}:
      List.append(&2, IndexedDefinition, c_collect_terms(values, arity, locals), c_term_lambdas(substitute_let_values(List.reverse(&2, AST.SyntaxTerm, values), body), arity, locals))
    case AST.TermCtr{ _, args,  _}: c_collect_terms(args, arity, locals)
    case AST.TermString{_, _, _}: Nil{}
    case AST.TermAdt{ _, args,  _,  _}: c_collect_terms(args, arity, locals)
    case AST.TermFill{head, args,  _}:
      List.append(&2, IndexedDefinition, c_term_lambdas(head, arity, locals), c_collect_terms(args, arity, locals))
    case AST.TermPlus{head, args,  _}:
      List.append(&2, IndexedDefinition, c_term_lambdas(head, arity, locals), c_collect_terms(args, arity, locals))
    case AST.TermMat{ _, head, matched,  _}:
      List.append(&2, IndexedDefinition, c_term_lambdas(head, arity, locals), c_term_lambdas(matched, arity, locals))
    case AST.TermRewrite{equation, proof, body,  _}:
      List.append(&2, IndexedDefinition, c_term_lambdas(equation, arity, locals), List.append(&2, IndexedDefinition, c_term_lambdas(proof, arity, locals), c_term_lambdas(body, arity, locals)))
    case AST.TermEqual{left, right,  _,  _}:
      List.append(&2, IndexedDefinition, c_term_lambdas(left, arity, locals), c_term_lambdas(right, arity, locals))
    case AST.BodyMatch{scrutinees, cases,  _}:
      List.append(&2, IndexedDefinition, c_collect_terms(scrutinees, arity, locals), c_collect_cases(cases, arity, locals))
    case AST.BodyLocal{patterns,  _, values, body,  _}:
      List.append(&2, IndexedDefinition, c_collect_terms(values, arity, locals), c_term_lambdas(body, arity, locals + c_pattern_vars_count(patterns)))
    case AST.BodyReply{term,  _}: c_term_lambdas(term, arity, locals)
    case _: Nil{}
type CBook is Data:
  CBook{definitions: List<&2, IndexedDefinition>, types: List<&2, IndexedType>, constructors: List<&2, IndexedConstructor>, main: Maybe<&2, IndexedDefinition>}


def qualify(namespace: String, key: String) -> String:
  c_qualify_result(String.eq(namespace, ""), namespace, key)

def c_qualify_result(empty: Bool, namespace: String, key: String) -> String:
  match empty:
    case True{}: key
    case False{}: String.append(namespace, String.append(".", key))

def c_identifier_char(char: Char) -> Char:
  match char:
    case '_': '_'
    case _:
      c_identifier_char_valid(Bool.or(Char.is_alpha(char), Char.is_digit(char)), char)

def c_identifier_char_valid(valid: Bool, char: Char) -> Char:
  match valid:
    case True{}: char
    case False{}: '_'

def c_identifier_chars(chars: List<&2, Char>) -> List<&2, Char>:
  match chars:
    case +char <> rest: c_identifier_char(char) <> c_identifier_chars(rest)

def c_identifier(name: String) -> String:
  String.from_list(c_identifier_chars(String.to_list(name)))

def cid_macro(name: String) -> String:
  String.append("CID_", String.to_upper(c_identifier(name)))

def fid_macro(name: String) -> String:
  String.append("FID_", String.to_upper(c_identifier(name)))

def join_strings(items: List<&2, String>, separator: String) -> String:
  match items:
    case Nil{}: ""
    case +item <> rest:
      match rest:
        case Nil{}: item
        case _: String.append(item, String.append(separator, join_strings(rest, separator)))

def nat_list(items: List<&2, Nat>, separator: String) -> String:
  match items:
    case Nil{}: ""
    case +item <> rest:
      match rest:
        case Nil{}: Nat.show(item)
        case _: String.append(Nat.show(item), String.append(separator, nat_list(rest, separator)))

def string_list(items: List<&2, String>) -> String:
  match items:
    case Nil{}: ""
    case +item <> rest:
      match rest:
        case Nil{}: item
        case _: String.append(item, String.append(", ", string_list(rest)))
def constructor_arity(fields: List<&2, AST.TelescopeItem>) -> Nat:
  match fields:
    case Nil{}: 0n
    case +field <> rest:
      match field:
        case AST.Binder{ AST.QZero{},  _,  _,  _,  _}:
          constructor_arity(rest)
        case AST.Binder{ _,  _,  _,  _,  _}:
          1n + constructor_arity(rest)
        case AST.TemplateBinder{ _,  _,  _,  _}:
          constructor_arity(rest)

def constructor_id_lines(constructors: List<&2, IndexedConstructor>, index: Nat) -> String:
  match constructors:
    case Nil{}: ""
    case +constructor <> rest:
      match constructor:
        case IndexedConstructor{ _,  _, full_key,  _}:
          String.append("#define ", String.append(cid_macro(full_key), String.append(" ", String.append(Nat.show(index), String.append("\n", constructor_id_lines(rest, index + 1n))))))

def constructor_arity_values(constructors: List<&2, IndexedConstructor>) -> List<&2, Nat>:
  match constructors:
    case Nil{}: Nil{}
    case +constructor <> rest:
      match constructor:
        case IndexedConstructor{_, _, _, fields}: constructor_arity(fields) <> constructor_arity_values(rest)

def c_has_constructor(constructors: List<&2, IndexedConstructor>, key: String) -> Bool:
  match constructors:
    case Nil{}: False{}
    case +constructor <> rest:
      match constructor:
        case IndexedConstructor{ _,  _, full_key,  _}:
          Bool.or(String.eq(full_key, key), c_has_constructor(rest, key))

def c_foreign_id_lines(definitions: List<&2, CForeign.ForeignDefinition>, constructors: List<&2, IndexedConstructor>, index: Nat) -> String:
  match definitions:
    case Nil{}: ""
    case +definition <> rest:
      match definition:
        case CForeign.ForeignDefinition{ _,  _, full_key,  _,  _,  _,  _}:
          c_foreign_id_line(c_has_constructor(constructors, full_key), rest, constructors, index, full_key)

def c_foreign_id_line(is_constructor: Bool, rest: List<&2, CForeign.ForeignDefinition>, constructors: List<&2, IndexedConstructor>, index: Nat, full_key: String) -> String:
  match is_constructor:
    case True{}: c_foreign_id_lines(rest, constructors, index)
    case False{}:
      String.append("#define ", String.append(cid_macro(full_key), String.append(" ", String.append(Nat.show(index), String.append("\n", c_foreign_id_lines(rest, constructors, index + 1n))))))

def c_foreign_arity_values(definitions: List<&2, CForeign.ForeignDefinition>, constructors: List<&2, IndexedConstructor>) -> List<&2, Nat>:
  match definitions:
    case Nil{}: Nil{}
    case +definition <> rest:
      match definition:
        case CForeign.ForeignDefinition{ _,  _, full_key, binders,  _,  _,  _}:
          c_foreign_arity_value(c_has_constructor(constructors, full_key), rest, constructors, binders)

def c_foreign_arity_value(is_constructor: Bool, rest: List<&2, CForeign.ForeignDefinition>, constructors: List<&2, IndexedConstructor>, binders: List<&2, AST.TelescopeItem>) -> List<&2, Nat>:
  match is_constructor:
    case False{}: List.length(&2, AST.TelescopeItem, c_live_binders(binders)) + 1n <> c_foreign_arity_values(rest, constructors)

def c_constructor_tables(constructors: List<&2, IndexedConstructor>, foreigns: List<&2, CForeign.ForeignDefinition>) -> String:
  lines = constructor_id_lines(constructors, 0n)
  foreign_lines = c_foreign_id_lines(foreigns, constructors, List.length(&2, IndexedConstructor, constructors))
  arities = List.append(&2, Nat, constructor_arity_values(constructors), c_foreign_arity_values(foreigns, constructors))
  String.append(lines, String.append(foreign_lines, String.append("CONSTV u8 CID_ARITY_T[] = { ", String.append(nat_list(arities, ", "), " };\n"))))
def constructor_index(constructors: List<&2, IndexedConstructor>, key: String, index: Nat) -> Nat:
  match constructors:
    case Nil{}: 0n
    case +constructor <> rest:
      match constructor:
        case IndexedConstructor{ _,  local, full_key,  _}:
          constructor_index_match(Bool.or(String.eq(full_key, key), String.eq(local, key)), rest, key, index)

def constructor_index_match(found: Bool, rest: List<&2, IndexedConstructor>, key: String, index: Nat) -> Nat:
  match found:
    case True{}: index
    case False{}: constructor_index(rest, key, index + 1n)

def main_constant_kind(constant: MainConstant) -> Nat:
  match constant:
    case MainNat{ _}: 2n
    case MainU32{ _}: 0n
    case MainBool{ _}: 7n
    case MainF32{ _}: 1n

def main_constant_expr(constant: MainConstant) -> String:
  match constant:
    case MainNat{value}: String.append("nat_chk(e, ", String.append(Nat.show(value), "ull)"))
    case MainU32{value}: String.append("(u32)", Nat.show(value))
    case MainBool{value}: Nat.show(value)
    case MainF32{value}: String.append("(u32)", Nat.show(value))

def main_show_cells(constructors: List<&2, IndexedConstructor>, constant: MainConstant) -> String:
  match constant:
    case MainBool{ _}:
      String.append("7, 0, 2, 0, ", String.append(Nat.show(constructor_index(constructors, "False", 0n)), String.append(", 0, 1, ", String.append(Nat.show(constructor_index(constructors, "True", 0n)), ", 0"))))
    case _: Nat.show(main_constant_kind(constant))
def main_show_names(constant: MainConstant) -> String:
  match constant:
    case MainBool{ _}: "\"False\", \"True\""
    case _: "\"False\", \"True\""

def main_tables(constructors: List<&2, IndexedConstructor>, foreigns: List<&2, CForeign.ForeignDefinition>, constant: MainConstant) -> String:
  String.concat([
    c_constructor_tables(constructors, foreigns),
    "#define FID_MAIN 0\n#define FID_IO_EMIT 1\n#define FID_CLO_APPLY 2\n#define FID_EXIT 3\n#define FID_ENTER 4\n",
    "CONSTV u8 FID_ARITY_T[] = { 0, 1, 2 };\nCONSTV u8 FID_FLAG_T[] = { 2, 2, 2 };\nCONSTV u8 FID_RESW_T[] = { 0, 0, 0 };\n",
    "#define STAT_LEN 0\n#define IO_HOTS 63\n#define WL_RESW 1\n#define BANGS 0\n",
    "#define WL_BANK Term r0, r1;\n",
    "#define WL_SIG Env e, Stk sp, u32 seq, u32 rn, Term r0, Term r1\n",
    "#define WL_ALL e, sp, seq, rn, r0, r1\n",
    "#define WL_LOAD(A, N) do { if ((N) <= 0) break; r0 = e.mem[(A) + 0]; if ((N) <= 1) break; r1 = e.mem[(A) + 1]; } while (0);\n",
    "#define WL_LAST(X) switch (war) { case 0: r0 = (X); break; case 1: r1 = (X); break; }\n",
    "#define WL_SAVE(V) (V)[0] = r0\n#define WL_TAKE(V) r0 = (V)[0]\n",
    "#define WL_TABLE WL_X(FID_MAIN) WL_X(FID_IO_EMIT) WL_X(FID_CLO_APPLY) WL_X(FID_EXIT)\n",
    "#define MAIN_FID FID_MAIN\n#define MAIN_PURE 1\n",
    "#if !DEVICE\nstatic const u32 SHOW_DESC[] = { ", main_show_cells(constructors, constant), " };\nstatic const char* SHOW_NAMES[] = { ", main_show_names(constant), " };\n#endif\n"
  ])

def main_segment(constant: MainConstant) -> String:
  String.append(
    "  WL_CASE(FID_MAIN)\n  {\n    WL_OPEN\n    r0 = ",
    String.append(main_constant_expr(constant), ";\n    WL_RETN(1);\n  }}\n"))

def main_spins() -> String:
  "CONSTV u64 STAT_IMG[] = { 0 };"
def key_is(key: String, short: String) -> Bool:
  Bool.or(String.eq(key, short), String.ends_with(key, String.append(".", short)))



def word_value(term: AST.SyntaxTerm, value: Nat) -> Maybe<&2, Nat>:
  match term:
    case AST.TermAnn{term,  _,  _}: word_value(term, value)
    case AST.TermTemplate{ _,  _}: None{}
    case AST.TermCtr{key, args,  _}: word_value_ctr(key, args, value)
    case _: None{}

def word_value_ctr(key: String, args: List<&2, AST.SyntaxTerm>, value: Nat) -> Maybe<&2, Nat>:
  word_value_nil(key_is(key, "WNil"), key, args, value)

def word_value_nil(is_nil: Bool, key: String, args: List<&2, AST.SyntaxTerm>, value: Nat) -> Maybe<&2, Nat>:
  match is_nil:
    case True{}: Some{value}
    case False{}: word_value_con(key_is(key, "WCon"), args, value)

def word_value_con(is_con: Bool, args: List<&2, AST.SyntaxTerm>, value: Nat) -> Maybe<&2, Nat>:
  match is_con:
    case True{}:
      match args:
        case +bit <> +tail <> Nil{}:
          match bit:
            case AST.TermCtr{ bit_key,  Nil{},  _}:
              word_value_bit(key_is(bit_key, "True"), key_is(bit_key, "False"), tail, value)
            case _: None{}
        case _: None{}
    case False{}: None{}

def word_value_bit(is_true: Bool, is_false: Bool, tail: AST.SyntaxTerm, value: Nat) -> Maybe<&2, Nat>:
  match is_true:
    case True{}: word_value(tail, value * 2n + 1n)
    case False{}: word_value_false_bit(is_false, tail, value)

def word_value_false_bit(is_false: Bool, tail: AST.SyntaxTerm, value: Nat) -> Maybe<&2, Nat>:
  match is_false:
    case True{}: word_value(tail, value * 2n)
    case False{}: None{}
def u32_from_syntax(term: AST.SyntaxTerm, expected: String) -> Maybe<&2, Nat>:
  match term:
    case AST.TermAnn{term,  _,  _}: u32_from_syntax(term, expected)
    case AST.TermTemplate{ _,  _}: None{}
    case AST.TermCtr{key, args,  _}: u32_from_syntax_ctr(key_is(key, expected), args)
    case _: None{}

def u32_from_syntax_ctr(is_expected: Bool, args: List<&2, AST.SyntaxTerm>) -> Maybe<&2, Nat>:
  match is_expected:
    case True{}:
      match args:
        case +word <> Nil{}: word_value(word, 0n)
        case _: None{}
    case False{}: None{}

def bool_from_syntax(term: AST.SyntaxTerm) -> Maybe<&2, Nat>:
  match term:
    case AST.TermAnn{term,  _,  _}: bool_from_syntax(term)
    case AST.TermTemplate{ _,  _}: None{}
    case AST.TermCtr{key,  Nil{},  _}: bool_from_syntax_ctr(key_is(key, "False"), key_is(key, "True"))
    case _: None{}

def bool_from_syntax_ctr(is_false: Bool, is_true: Bool) -> Maybe<&2, Nat>:
  match is_false:
    case True{}: Some{0n}
    case False{}: bool_from_syntax_true(is_true)

def bool_from_syntax_true(is_true: Bool) -> Maybe<&2, Nat>:
  match is_true:
    case True{}: Some{1n}
    case False{}: None{}


def main_result_key(term: AST.SyntaxTerm) -> String:
  match term:
    case AST.TermRef{key,  _}: key
    case AST.TermAdt{key,  _,  _,  _}: key
    case AST.TermApp{fn,  _,  _}: main_result_key(fn)
    case AST.TermSub{ _,  _, body,  _}: main_result_key(body)
    case AST.TermAnn{ _, ty,  _}: main_result_key(ty)
    case AST.TermTemplate{ _,  _}: ""
    case AST.TermFill{head,  _,  _}: main_result_key(head)
    case AST.TermPlus{head,  _,  _}: main_result_key(head)
    case _: ""

def constant_for_type(term: AST.SyntaxTerm, type_key: String, definitions: List<&2, IndexedDefinition>) -> Maybe<&2, MainConstant>:
  constant_for_nat(key_is(type_key, "Nat"), term, type_key, definitions)

def constant_for_nat(is_nat: Bool, term: AST.SyntaxTerm, type_key: String, definitions: List<&2, IndexedDefinition>) -> Maybe<&2, MainConstant>:
  match is_nat:
    case True{}: constant_for_nat_result(nat_eval(term, definitions, 128n))
    case False{}: constant_for_u32(key_is(type_key, "U32"), term, type_key, definitions)

def constant_for_nat_result(result: Maybe<&2, Nat>) -> Maybe<&2, MainConstant>:
  match result:
    case Some{value}: Some{MainNat{value}}
    case None{}: None{}

def constant_for_u32(is_u32: Bool, term: AST.SyntaxTerm, type_key: String, definitions: List<&2, IndexedDefinition>) -> Maybe<&2, MainConstant>:
  match is_u32:
    case True{}: constant_for_u32_result(u32_from_syntax(term, "U32"))
    case False{}: constant_for_f32(key_is(type_key, "F32"), term, type_key, definitions)

def constant_for_u32_result(result: Maybe<&2, Nat>) -> Maybe<&2, MainConstant>:
  match result:
    case Some{value}: Some{MainU32{value}}
    case None{}: None{}

def constant_for_f32(is_f32: Bool, term: AST.SyntaxTerm, type_key: String, definitions: List<&2, IndexedDefinition>) -> Maybe<&2, MainConstant>:
  match is_f32:
    case True{}: constant_for_f32_result(u32_from_syntax(term, "F32"))
    case False{}: constant_for_bool(key_is(type_key, "Bool"), term)

def constant_for_f32_result(result: Maybe<&2, Nat>) -> Maybe<&2, MainConstant>:
  match result:
    case Some{value}: Some{MainF32{value}}
    case None{}: None{}

def constant_for_bool(is_bool: Bool, term: AST.SyntaxTerm) -> Maybe<&2, MainConstant>:
  match is_bool:
    case True{}: constant_for_bool_result(bool_from_syntax(term))
    case False{}: None{}

def constant_for_bool_result(result: Maybe<&2, Nat>) -> Maybe<&2, MainConstant>:
  match result:
    case Some{value}: Some{MainBool{value}}
    case None{}: None{}

def find_definition(key: String, definitions: List<&2, IndexedDefinition>) -> Maybe<&2, IndexedDefinition>:
  match definitions:
    case Nil{}: None{}
    case +definition <> rest:
      match definition:
        case IndexedDefinition{namespace,  local, full_key,  _,  _,  _,  _,  _}:
          find_definition_match(Bool.or(String.eq(key, full_key), Bool.and(String.eq(namespace, ""), String.eq(key, local))), definition, rest, key)

def find_definition_match(found: Bool, definition: IndexedDefinition, rest: List<&2, IndexedDefinition>, key: String) -> Maybe<&2, IndexedDefinition>:
  match found:
    case True{}: Some{definition}
    case False{}: find_definition(key, rest)
def c_definition_reference(key: String, definitions: List<&2, IndexedDefinition>) -> Maybe<&2, String>:
  c_definition_reference_result(find_definition(key, definitions))

def c_definition_reference_result(found: Maybe<&2, IndexedDefinition>) -> Maybe<&2, String>:
  match found:
    case Some{ IndexedDefinition{ _,  _, full_key,  _,  _,  AST.DefImports{ _},  _,  _}}:
      Some{"(((u64)TAG_CLO << 56) | ((u64)" ++ fid_macro(full_key) ++ " << 40))"}
    case Some{ IndexedDefinition{ _,  _, full_key, binders,  _,  _,  _,  _}}:
      c_definition_reference_arity(c_live_binder_count(binders), full_key)
    case None{}: None{}

def c_definition_reference_arity(count: Nat, full_key: String) -> Maybe<&2, String>:
  match count:
    case 1n+remaining:
      Some{String.append("(((u64)TAG_CLO << 56) | ((u64)", String.append(fid_macro(full_key), " << 40))"))}

def substitute_let_values(values: List<&2, AST.SyntaxTerm>, body: AST.SyntaxTerm) -> AST.SyntaxTerm:
  match values:
    case Nil{}: body
    case +value <> rest:
      substitute_let_values(rest, Core.subst(0n, value, body))

type AppSpine is Data:
  AppSpine{head: AST.SyntaxTerm, args: List<&2, AST.SyntaxTerm>}
type BangCall is Data:
  BangCall{key: String, args: List<&2, AST.SyntaxTerm>}
type BangSplit is Data:
  BangSplit{key: String, args: List<&2, AST.SyntaxTerm>, captures: List<&2, AST.SyntaxTerm>, rest: AST.SyntaxTerm}

def c_capture_placeholder(index: Nat, span: AST.SourceSpan) -> AST.SyntaxTerm:
  AST.TermVar{ "__bang_capture", index, span}

def c_split_bang(term: AST.SyntaxTerm) -> Maybe<&2, BangSplit>:
  match term:
    case AST.TermApp{fn, arg, span}:
      c_split_bang_app_fn(c_split_bang(fn), fn, arg, span)

    case AST.TermAnn{ inner, ty, span}: c_split_bang_wrap(c_split_bang(inner), ty, span)
    case AST.TermTemplate{ inner, span}: c_split_bang_template(c_split_bang(inner), span)
    case AST.TermSub{index, value, body,  _}: c_split_bang(Core.subst(index, value, body))
    case AST.TermLet{ _,  _,  _, values, body,  _}: c_split_bang(substitute_let_values(List.reverse(&2, AST.SyntaxTerm, values), body))
    case AST.TermMin{left, right, span}: c_split_bang_min_left(c_split_bang(left), left, right, span)
    case AST.TermCtr{key, args, span}: c_split_bang_terms_ctr(c_split_bang_terms(args), key, span)
    case AST.TermString{_, _, _}: None{}
    case AST.TermAdt{key, args, refs, span}: c_split_bang_terms_adt(c_split_bang_terms(args), key, refs, span)
    case AST.TermFill{head, args, span}: c_split_bang_fill_head(c_split_bang(head), head, args, span)
    case AST.TermPlus{head, args, span}: c_split_bang_plus_head(c_split_bang(head), head, args, span)
    case AST.TermMat{key, head, matched, span}: c_split_bang_mat_head(c_split_bang(head), key, head, matched, span)
    case AST.TermEqual{left, right, ty, span}: c_split_bang_equal_left(c_split_bang(left), left, right, ty, span)
    case AST.TermRewrite{equation, proof, body, span}: c_split_bang_rewrite_equation(c_split_bang(equation), equation, proof, body, span)
    case AST.BodyMatch{scrutinees, cases, span}: c_split_bang_body_match(c_split_bang_terms(scrutinees), cases, span)
    case AST.BodyLocal{patterns, quantity, values, body, span}: c_split_bang_body_local(c_split_bang_terms(values), patterns, quantity, body, span)
    case AST.BodyReply{ inner, span}: c_split_bang_body_reply(c_split_bang(inner), span)
    case AST.TermBang{}: None{}
    case _: None{}

def c_split_bang_wrap(found: Maybe<&2, BangSplit>, ty: AST.SyntaxTerm, span: AST.SourceSpan) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{key, args, captures, rest}}: Some{BangSplit{key, args, captures, AST.TermAnn{rest, ty, span}}}
    case None{}: None{}

def c_split_bang_template(found: Maybe<&2, BangSplit>, span: AST.SourceSpan) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{key, args, captures, rest}}: Some{BangSplit{key, args, captures, AST.TermTemplate{rest, span}}}
    case None{}: None{}

def c_split_bang_rewrite_equation(found: Maybe<&2, BangSplit>, equation: AST.SyntaxTerm, proof: AST.SyntaxTerm, body: AST.SyntaxTerm, span: AST.SourceSpan) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{key, args, captures, rest}}: Some{BangSplit{key, args, captures, AST.TermRewrite{rest, proof, body, span}}}
    case None{}: c_split_bang_rewrite_proof(c_split_bang(proof), equation, proof, body, span)

def c_split_bang_rewrite_proof(found: Maybe<&2, BangSplit>, equation: AST.SyntaxTerm, proof: AST.SyntaxTerm, body: AST.SyntaxTerm, span: AST.SourceSpan) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{key, args, captures, rest}}:
      slot = List.length(&2, AST.SyntaxTerm, captures)
      Some{BangSplit{key, args, List.append(&2, AST.SyntaxTerm, captures, [equation]), AST.TermRewrite{c_capture_placeholder(slot, span), rest, body, span}}}
    case None{}: c_split_bang_rewrite_body(c_split_bang(body), equation, proof, span)

def c_split_bang_rewrite_body(found: Maybe<&2, BangSplit>, equation: AST.SyntaxTerm, proof: AST.SyntaxTerm, span: AST.SourceSpan) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{key, args, captures, rest}}:
      slot = List.length(&2, AST.SyntaxTerm, captures)
      next_captures = List.append(&2, AST.SyntaxTerm, List.append(&2, AST.SyntaxTerm, captures, [proof]), [equation])
      Some{BangSplit{key, args, next_captures, AST.TermRewrite{c_capture_placeholder(slot + 1n, span), c_capture_placeholder(slot, span), rest, span}}}
    case None{}: None{}

def c_split_bang_body_match(found: Maybe<&2, BangSplit>, cases: List<&2, AST.SyntaxTerm>, span: AST.SourceSpan) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{key, args, captures, next_scrutinees}}: Some{BangSplit{key, args, captures, AST.BodyMatch{next_scrutinees, cases, span}}}
    case None{}: None{}

def c_split_bang_body_local(found: Maybe<&2, BangSplit>, patterns: List<&2, AST.SyntaxPattern>, quantity: AST.Quantity, body: AST.SyntaxTerm, span: AST.SourceSpan) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{key, args, captures, next_values}}: Some{BangSplit{key, args, captures, AST.BodyLocal{patterns, quantity, next_values, body, span}}}
    case None{}: None{}

def c_split_bang_body_reply(found: Maybe<&2, BangSplit>, span: AST.SourceSpan) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{key, args, captures, rest}}: Some{BangSplit{key, args, captures, AST.BodyReply{rest, span}}}
    case None{}: None{}

def c_split_bang_min_left(found: Maybe<&2, BangSplit>, left: AST.SyntaxTerm, right: AST.SyntaxTerm, span: AST.SourceSpan) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{key, args, captures, rest}}: Some{BangSplit{key, args, captures, AST.TermMin{rest, right, span}}}
    case None{}: c_split_bang_min_right(c_split_bang(right), left, right, span)

def c_split_bang_min_right(found: Maybe<&2, BangSplit>, left: AST.SyntaxTerm, right: AST.SyntaxTerm, span: AST.SourceSpan) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{key, args, captures, rest}}:
      slot = List.length(&2, AST.SyntaxTerm, captures)
      Some{BangSplit{key, args, List.append(&2, AST.SyntaxTerm, captures, [left]), AST.TermMin{c_capture_placeholder(slot, span), rest, span}}}
    case None{}: None{}

def c_split_bang_terms_ctr(found: Maybe<&2, BangSplit>, key: String, span: AST.SourceSpan) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{bang_key, bang_args, captures, new_args}}: Some{BangSplit{bang_key, bang_args, captures, AST.TermCtr{key, new_args, span}}}
    case None{}: None{}

def c_split_bang_terms_adt(found: Maybe<&2, BangSplit>, key: String, refs: List<&2, AST.SyntaxTerm>, span: AST.SourceSpan) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{bang_key, bang_args, captures, new_args}}: Some{BangSplit{bang_key, bang_args, captures, AST.TermAdt{key, new_args, refs, span}}}
    case None{}: None{}

def c_split_bang_fill_head(found: Maybe<&2, BangSplit>, head: AST.SyntaxTerm, args: List<&2, AST.SyntaxTerm>, span: AST.SourceSpan) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{key, bang_args, captures, rest}}: Some{BangSplit{key, bang_args, captures, AST.TermFill{rest, args, span}}}
    case None{}: c_split_bang_fill_args(c_split_bang_terms(args), head, args, span)

def c_split_bang_fill_args(found: Maybe<&2, BangSplit>, head: AST.SyntaxTerm, args: List<&2, AST.SyntaxTerm>, span: AST.SourceSpan) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{key, bang_args, captures, new_args}}:
      slot = List.length(&2, AST.SyntaxTerm, captures)
      Some{BangSplit{key, bang_args, List.append(&2, AST.SyntaxTerm, captures, [head]), AST.TermFill{c_capture_placeholder(slot, span), new_args, span}}}
    case None{}: None{}

def c_split_bang_plus_head(found: Maybe<&2, BangSplit>, head: AST.SyntaxTerm, args: List<&2, AST.SyntaxTerm>, span: AST.SourceSpan) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{key, bang_args, captures, rest}}: Some{BangSplit{key, bang_args, captures, AST.TermPlus{rest, args, span}}}
    case None{}: c_split_bang_plus_args(c_split_bang_terms(args), head, args, span)

def c_split_bang_plus_args(found: Maybe<&2, BangSplit>, head: AST.SyntaxTerm, args: List<&2, AST.SyntaxTerm>, span: AST.SourceSpan) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{key, bang_args, captures, new_args}}:
      slot = List.length(&2, AST.SyntaxTerm, captures)
      Some{BangSplit{key, bang_args, List.append(&2, AST.SyntaxTerm, captures, [head]), AST.TermPlus{c_capture_placeholder(slot, span), new_args, span}}}
    case None{}: None{}

def c_split_bang_mat_head(found: Maybe<&2, BangSplit>, key: String, head: AST.SyntaxTerm, matched: AST.SyntaxTerm, span: AST.SourceSpan) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{bang_key, args, captures, rest}}: Some{BangSplit{bang_key, args, captures, AST.TermMat{key, rest, matched, span}}}
    case None{}: c_split_bang_mat_matched(c_split_bang(matched), key, head, matched, span)

def c_split_bang_mat_matched(found: Maybe<&2, BangSplit>, key: String, head: AST.SyntaxTerm, matched: AST.SyntaxTerm, span: AST.SourceSpan) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{bang_key, args, captures, rest}}:
      slot = List.length(&2, AST.SyntaxTerm, captures)
      Some{BangSplit{bang_key, args, List.append(&2, AST.SyntaxTerm, captures, [head]), AST.TermMat{key, c_capture_placeholder(slot, span), rest, span}}}
    case None{}: None{}

def c_split_bang_equal_left(found: Maybe<&2, BangSplit>, left: AST.SyntaxTerm, right: AST.SyntaxTerm, ty: AST.SyntaxTerm, span: AST.SourceSpan) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{key, args, captures, rest}}: Some{BangSplit{key, args, captures, AST.TermEqual{rest, right, ty, span}}}
    case None{}: c_split_bang_equal_right(c_split_bang(right), left, right, ty, span)

def c_split_bang_equal_right(found: Maybe<&2, BangSplit>, left: AST.SyntaxTerm, right: AST.SyntaxTerm, ty: AST.SyntaxTerm, span: AST.SourceSpan) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{key, args, captures, rest}}:
      slot = List.length(&2, AST.SyntaxTerm, captures)
      Some{BangSplit{key, args, List.append(&2, AST.SyntaxTerm, captures, [left]), AST.TermEqual{c_capture_placeholder(slot, span), rest, ty, span}}}
    case None{}: None{}
    case AST.TermBang{}: None{}
    case _: None{}

def c_split_bang_app_fn(found: Maybe<&2, BangSplit>, fn: AST.SyntaxTerm, arg: AST.SyntaxTerm, span: AST.SourceSpan) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{key, args, captures, rest}}: Some{BangSplit{key, args, captures,  AST.TermApp{ rest, arg, span}}}
    case None{}: c_split_bang_app_arg(c_split_bang(arg), fn, arg, span)

def c_split_bang_app_arg(found: Maybe<&2, BangSplit>, fn: AST.SyntaxTerm, arg: AST.SyntaxTerm, span: AST.SourceSpan) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{key, args, captures, rest}}:
      slot = List.length(&2, AST.SyntaxTerm, captures)
      Some{BangSplit{key, args,  List.append(&2, AST.SyntaxTerm, captures, [fn]),  AST.TermApp{ c_capture_placeholder(slot, span),  rest, span}}}
    case None{}: c_split_bang_app_call(c_bang_call(AST.TermApp{fn, arg, span}), span)

def c_split_bang_app_call(found: Maybe<&2, BangCall>, span: AST.SourceSpan) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangCall{key,  call_args}}: Some{BangSplit{key,  call_args,  Nil{},  AST.TermVar{ "__bang_value",  0n, span}}}
    case None{}: None{}
def c_term_span(term: AST.SyntaxTerm) -> AST.SourceSpan:
  match term:
    case AST.TermVar{_, _, span}: span
    case AST.TermRef{_, span}: span
    case AST.TermBang{_, span}: span
    case AST.TermSub{_, _, _, span}: span
    case AST.TermLet{_, _, _, _, _, span}: span
    case AST.TermAnn{_, _, span}: span
    case AST.TermTemplate{_, span}: span
    case AST.TermType{_, span}: span
    case AST.TermMin{_, _, span}: span
    case AST.TermAll{_, _, _, _, _, span}: span
    case AST.TermLam{_, _, _, _, span}: span
    case AST.TermApp{_, _, span}: span
    case AST.TermAdt{_, _, _, span}: span
    case AST.TermFill{_, _, span}: span
    case AST.TermPlus{_, _, span}: span
    case AST.TermCtr{_, _, span}: span
    case AST.TermString{_, _, span}: span
    case AST.TermMat{_, _, _, span}: span
    case AST.TermAbsurd{span}: span
    case AST.TermEqual{_, _, _, span}: span
    case AST.TermRefl{span}: span
    case AST.TermRewrite{_, _, _, span}: span
    case AST.TermHole{_, span}: span
    case AST.BodyMatch{_, _, span}: span
    case AST.BodyCase{_, _, span}: span
    case AST.BodyLocal{_, _, _, _, span}: span
    case AST.BodyReply{_, span}: span
    case _: AST.SpanOf{ "",  0n,  0n}
def c_split_bang_terms(terms: List<&2, AST.SyntaxTerm>) -> Maybe<&2, BangSplit>:
  match terms:
    case Nil{}: None{}
    case +term <> rest:
      c_split_bang_terms_first(c_split_bang(term), term, rest)

def c_split_bang_terms_first(found: Maybe<&2, BangSplit>, term: AST.SyntaxTerm, rest: List<&2, AST.SyntaxTerm>) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{key, args, captures, new_term}}: Some{BangSplit{key, args, captures, new_term <> rest}}
    case None{}: c_split_bang_terms_rest(c_split_bang_terms(rest), term)

def c_split_bang_terms_rest(found: Maybe<&2, BangSplit>, term: AST.SyntaxTerm) -> Maybe<&2, BangSplit>:
  match found:
    case Some{BangSplit{key, args, captures, new_rest}}:
      slot = List.length(&2, AST.SyntaxTerm, captures)
      Some{BangSplit{key, args, List.append(&2, AST.SyntaxTerm, captures, [term]), c_capture_placeholder(slot, c_term_span(term)) <> new_rest}}
    case None{}: None{}

def c_definition_bang_split(definition: IndexedDefinition) -> Maybe<&2, BangSplit>:
  match definition:
    case IndexedDefinition{ _, key,  _,  _,  _,  AST.DefTerm{ AST.TermLam{ _,  _,  _, body,  _}},  _,  _}:
      c_definition_bang_lambda(String.starts_with(key, "__lambda_"), body)
    case IndexedDefinition{ _,  _,  _,  _,  _,  AST.DefTerm{term},  _,  _}: c_split_bang(term)
    case _: None{}

def c_definition_bang_lambda(is_lambda: Bool, body: AST.SyntaxTerm) -> Maybe<&2, BangSplit>:
  match is_lambda:
    case True{}: c_split_bang(body)
    case False{}: None{}


def c_bang_continuation_key(key: String) -> String:
  String.append(key, "__cemit_k")

def c_bang_continuation_binder(span: AST.SourceSpan) -> AST.TelescopeItem:
  AST.Binder{ AST.QMany{},  "__bang_value",  0n,  AST.TermRef{ "Nat", span}, span}
def c_bang_capture_binders(captures: List<&2, AST.SyntaxTerm>, span: AST.SourceSpan) -> List<&2, AST.TelescopeItem>:
  match captures:
    case Nil{}: Nil{}
    case +_ <> rest:
      AST.Binder{ AST.QMany{},  "__bang_capture",  0n,  AST.TermRef{ "Nat", span}, span} <> c_bang_capture_binders(rest, span)

def c_capture_expression_values(terms: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, List<&2, String>>:
  match terms:
    case Nil{}: Some{Nil{}}
    case +term <> rest:
      c_capture_expression_pair(c_expr_env(term, definitions, arity, locals), c_capture_expression_values(rest, definitions, arity, locals))

def c_capture_expression_pair(one: Maybe<&2, String>, rest: Maybe<&2, List<&2, String>>) -> Maybe<&2, List<&2, String>>:
  match one rest:
    case Some{value} Some{values}: Some{value <> values}
    case _ _: None{}

def c_capture_terms_supported(captures: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Bool:
  c_capture_terms_supported_result(c_capture_expression_values(captures, definitions, arity, locals))

def c_capture_terms_supported_result(result: Maybe<&2, List<&2, String>>) -> Bool:
  match result:
    case Some{ _}: True{}
    case None{}: False{}

def c_register_values(count: Nat, index: Nat) -> String:
  match count:
    case 0n: ""
    case 1n+rest:
      String.append("r", String.append(Nat.show(index), c_call_separator(c_register_values(rest, index + 1n))))

def c_register_value_list(count: Nat, index: Nat) -> List<&2, String>:
  match count:
    case 0n: Nil{}
    case 1n+rest: String.append("r", Nat.show(index)) <> c_register_value_list(rest, index + 1n)

def c_capture_task_values(values: List<&2, String>, index: Nat) -> String:
  match values:
    case Nil{}: ""
    case +value <> rest:
      String.concat(["      e.mem[__bend_cont + ", Nat.show(index), "] = ", value, ";\n", c_capture_task_values(rest, index + 1n)])

def c_capture_task_values_reverse(values: List<&2, String>, index: Nat) -> String:
  match values:
    case Nil{}: ""
    case +value <> rest:
      String.concat([c_capture_task_values_reverse(rest, index + 1n), "      e.mem[__bend_cont + ", Nat.show(index), "] = ", value, ";\n"])
def c_bang_segment_to(current_key: String, continuation_key: String, bang: BangCall, prefix_terms: List<&2, AST.SyntaxTerm>, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>, wrap: Bool) -> Maybe<&2, String>:
  capture_count = c_live_binder_count(binders)
  c_bang_segment_to_result(c_capture_expression_values(prefix_terms, definitions, 0n, c_segment_binder_env(binders, 0n)), current_key, continuation_key, bang, binders, definitions, wrap, capture_count)

def c_bang_segment_to_result(found: Maybe<&2, List<&2, String>>, current_key: String, continuation_key: String, bang: BangCall, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>, wrap: Bool, capture_count: Nat) -> Maybe<&2, String>:
  match found:
    case Some{prefix_values}: c_bang_segment_context(current_key, continuation_key, bang, 0n, c_segment_binder_env(binders, 0n), prefix_values, c_register_value_list(capture_count, 0n), definitions, wrap)
    case None{}: None{}

def c_bang_segment_context(current_key: String, continuation_key: String, bang: BangCall, arity: Nat, locals: List<&2, String>, prefix_values: List<&2, String>, capture_values: List<&2, String>, definitions: List<&2, IndexedDefinition>, wrap: Bool) -> Maybe<&2, String>:
  match bang:
    case BangCall{key, args}:
      c_bang_segment_target(find_definition(key, definitions), current_key, continuation_key, args, arity, locals, prefix_values, capture_values, definitions, wrap)

def c_bang_segment_target(found: Maybe<&2, IndexedDefinition>, current_key: String, continuation_key: String, args: List<&2, AST.SyntaxTerm>, arity: Nat, locals: List<&2, String>, prefix_values: List<&2, String>, capture_values: List<&2, String>, definitions: List<&2, IndexedDefinition>, wrap: Bool) -> Maybe<&2, String>:
  match found:
    case Some{IndexedDefinition{_, _, target_key, target_binders, _, _, _, _}}:
      live_args = c_live_arguments(target_binders, args, definitions, arity, locals)
      c_bang_segment_target_arity(Nat.is_eq(List.length(&2, AST.SyntaxTerm, live_args), c_live_binder_count(target_binders)), target_key, target_binders, live_args, current_key, continuation_key, arity, locals, prefix_values, capture_values, definitions, wrap)
    case None{}: None{}

def c_bang_segment_target_arity(valid: Bool, target_key: String, target_binders: List<&2, AST.TelescopeItem>, live_args: List<&2, AST.SyntaxTerm>, current_key: String, continuation_key: String, arity: Nat, locals: List<&2, String>, prefix_values: List<&2, String>, capture_values: List<&2, String>, definitions: List<&2, IndexedDefinition>, wrap: Bool) -> Maybe<&2, String>:
  match valid:
    case False{}: None{}
    case True{}:
      c_bang_segment_rows(c_bang_rows(live_args, 0n, definitions, arity, locals, True{}), c_bang_rows(live_args, 0n, definitions, arity, locals, False{}), target_key, current_key, continuation_key, prefix_values, capture_values, definitions, wrap)

def c_bang_segment_prefix(wrap: Bool, current_key: String) -> String:
  match wrap:
    case True{}: String.concat(["  WL_CASE(", fid_macro(current_key), ")\n  {\n    WL_OPEN\n"])
    case False{}: ""

def c_bang_segment_suffix(wrap: Bool) -> String:
  match wrap:
    case True{}: "  }}\n"
    case False{}: ""

def c_bang_segment_rows(tasks: Maybe<&2, String>, registers: Maybe<&2, String>, target_key: String, current_key: String, continuation_key: String, prefix_values: List<&2, String>, capture_values: List<&2, String>, definitions: List<&2, IndexedDefinition>, wrap: Bool) -> Maybe<&2, String>:
  match tasks registers:
    case Some{task_rows} Some{register_rows}:
      target_fid = fid_macro(target_key)
      cont_fid = fid_macro(continuation_key)
      capture_count = List.length(&2, String, prefix_values) + List.length(&2, String, capture_values)
      task_captures = String.append(c_capture_task_values_reverse(prefix_values, List.length(&2, String, capture_values)), c_capture_task_values(capture_values, 0n))
      prefix = c_bang_segment_prefix(wrap, current_key)
      suffix = c_bang_segment_suffix(wrap)
      Some{String.concat([
        prefix, "    Loc __bend_cont = task_node(e, ", cont_fid, ", WL_CONT, WL_IDX, 1);\n",
        task_captures, "    if (!seq) {\n      Loc __bend_task = task_node(e, ", target_fid, ", term_tsk(", cont_fid, ", __bend_cont), ", Nat.show(capture_count), ", 0);\n",
        task_rows, "      return term_tsk(", target_fid, ", __bend_task);\n    }\n",
        "    WL_CONT = term_tsk(", cont_fid, ", __bend_cont);\n    WL_IDX = ", Nat.show(capture_count), ";\n",
        register_rows, "    WL_JMP(", target_fid, ");\n", suffix
      ])}
    case _ _: None{}

def c_replace_bang_placeholder_terms(terms: List<&2, AST.SyntaxTerm>, index: Nat) -> List<&2, AST.SyntaxTerm>:
  match terms:
    case Nil{}: Nil{}
    case +term <> rest: c_replace_bang_placeholder(term, index) <> c_replace_bang_placeholder_terms(rest, index)

def c_replace_bang_placeholder_cases(cases: List<&2, AST.SyntaxTerm>, index: Nat) -> List<&2, AST.SyntaxTerm>:
  match cases:
    case Nil{}: Nil{}
    case +one <> rest:
      match one:
        case AST.BodyCase{patterns, body, span}: AST.BodyCase{patterns,  c_replace_bang_placeholder(body, index), span} <> c_replace_bang_placeholder_cases(rest, index)
        case AST.BodyLocal{patterns, quantity, values, body, span}: AST.BodyLocal{patterns, quantity,  c_replace_bang_placeholder_terms(values, index),  c_replace_bang_placeholder(body, index), span} <> c_replace_bang_placeholder_cases(rest, index)
        case AST.BodyReply{term, span}: AST.BodyReply{ c_replace_bang_placeholder(term, index), span} <> c_replace_bang_placeholder_cases(rest, index)
        case _: one <> c_replace_bang_placeholder_cases(rest, index)

def c_replace_bang_placeholder(term: AST.SyntaxTerm, index: Nat) -> AST.SyntaxTerm:
  match term:
    case AST.TermVar{ "__bang_value",  offset, span}: AST.TermVar{ "__bang_value_done",  offset - index - 1n, span}
    case AST.TermVar{ "__bang_capture",  offset, span}: AST.TermVar{ "__bang_capture_done",  (2n * index) + 1n - offset, span}
    case AST.TermApp{fn, arg, span}: AST.TermApp{ c_replace_bang_placeholder(fn, index),  c_replace_bang_placeholder(arg, index), span}
    case AST.TermAnn{ inner, ty, span}: AST.TermAnn{ c_replace_bang_placeholder(inner, index),  c_replace_bang_placeholder(ty, index), span}
    case AST.TermTemplate{ inner, span}: AST.TermTemplate{ c_replace_bang_placeholder(inner, index), span}
    case AST.TermMin{left, right, span}: AST.TermMin{ c_replace_bang_placeholder(left, index),  c_replace_bang_placeholder(right, index), span}
    case AST.TermCtr{key, args, span}: AST.TermCtr{key,  c_replace_bang_placeholder_terms(args, index), span}
    case AST.TermString{_, _, _}: term
    case AST.TermAdt{key, args, refs, span}: AST.TermAdt{key,  c_replace_bang_placeholder_terms(args, index), refs, span}
    case AST.TermFill{head, args, span}: AST.TermFill{ c_replace_bang_placeholder(head, index),  c_replace_bang_placeholder_terms(args, index), span}
    case AST.TermPlus{head, args, span}: AST.TermPlus{ c_replace_bang_placeholder(head, index),  c_replace_bang_placeholder_terms(args, index), span}
    case AST.TermMat{key, head, matched, span}: AST.TermMat{key,  c_replace_bang_placeholder(head, index),  c_replace_bang_placeholder(matched, index), span}
    case AST.TermEqual{left, right, ty, span}: AST.TermEqual{ c_replace_bang_placeholder(left, index),  c_replace_bang_placeholder(right, index),  c_replace_bang_placeholder(ty, index), span}
    case AST.TermRewrite{equation, proof, body, span}: AST.TermRewrite{ c_replace_bang_placeholder(equation, index),  c_replace_bang_placeholder(proof, index),  c_replace_bang_placeholder(body, index), span}
    case AST.BodyMatch{scrutinees, cases, span}: AST.BodyMatch{ c_replace_bang_placeholder_terms(scrutinees, index),  c_replace_bang_placeholder_cases(cases, index), span}
    case AST.BodyReply{ inner, span}: AST.BodyReply{ c_replace_bang_placeholder(inner, index), span}
    case AST.BodyLocal{patterns, quantity, values, body, span}: AST.BodyLocal{patterns, quantity,  c_replace_bang_placeholder_terms(values, index),  c_replace_bang_placeholder(body, index), span}
    case _: term

def c_make_bang_continuations(definition: IndexedDefinition, next_key: String) -> List<&2, IndexedDefinition>:
  match definition:
    case IndexedDefinition{ _,  _,  _, binders, result,  AST.DefTerm{term}, unsafe, span}:
      c_make_bang_continuations_result(c_definition_bang_split(definition), binders, result, unsafe, span, next_key)
    case _: Nil{}

def c_make_bang_continuations_result(found: Maybe<&2, BangSplit>, binders: List<&2, AST.TelescopeItem>, result: AST.OptionalTerm, unsafe: Bool, span: AST.SourceSpan, next_key: String) -> List<&2, IndexedDefinition>:
  match found:
    case Some{BangSplit{_, _, captures, rest}}:
      capture_count = List.length(&2, AST.SyntaxTerm, captures)
      cont_binders = List.append(&2, AST.TelescopeItem, List.append(&2, AST.TelescopeItem, binders, c_bang_capture_binders(captures, span)), [c_bang_continuation_binder(span)])
      cont_term = c_replace_bang_placeholder(Core.shift(0n, 1n + capture_count, rest), capture_count)
      continuation = IndexedDefinition{ "", next_key, next_key, cont_binders, result, AST.DefTerm{cont_term}, unsafe, span}
      continuation <> c_make_bang_continuations(continuation, c_bang_continuation_key(next_key))
    case None{}: Nil{}

def c_append_bang_continuations(definitions: List<&2, IndexedDefinition>) -> List<&2, IndexedDefinition>:
  match definitions:
    case Nil{}: Nil{}
    case +definition <> rest:
      match definition:
        case IndexedDefinition{ _,  _, full_key,  _,  _,  _,  _,  _}:
          List.append(&2, IndexedDefinition, c_make_bang_continuations(definition, c_bang_continuation_key(full_key)), c_append_bang_continuations(rest))

def c_match_continuation_key(key: String, index: Nat) -> String:
  String.concat([key, "__cemit_case_", Nat.show(index), "__cemit_k"])

def c_match_case_continuations(cases: List<&2, AST.SyntaxTerm>, current_key: String, binders: List<&2, AST.TelescopeItem>, result: AST.OptionalTerm, unsafe: Bool, span: AST.SourceSpan, index: Nat) -> List<&2, IndexedDefinition>:
  match cases:
    case Nil{}: Nil{}
    case +one <> rest:
      current = c_match_case_continuation(one, current_key, binders, result, unsafe, span, index)
      List.append(&2, IndexedDefinition, current, c_match_case_continuations(rest, current_key, binders, result, unsafe, span, index + 1n))

def c_match_case_continuation(one: AST.SyntaxTerm, current_key: String, binders: List<&2, AST.TelescopeItem>, result: AST.OptionalTerm, unsafe: Bool, span: AST.SourceSpan, index: Nat) -> List<&2, IndexedDefinition>:
  match one:
    case AST.BodyCase{patterns, body, _}: c_match_case_bang_continuation(c_split_bang(body), patterns, current_key, binders, result, unsafe, span, index)
    case _: Nil{}

def c_match_case_bang_continuation(found: Maybe<&2, BangSplit>, patterns: List<&2, AST.SyntaxPattern>, current_key: String, binders: List<&2, AST.TelescopeItem>, result: AST.OptionalTerm, unsafe: Bool, span: AST.SourceSpan, index: Nat) -> List<&2, IndexedDefinition>:
  match found:
    case Some{BangSplit{_, _, captures, continuation_body}}:
      next_key = c_match_continuation_key(current_key, index)
      capture_count = List.length(&2, AST.SyntaxTerm, captures)
      pattern_binders = c_pattern_binders(patterns)
      next_binders = List.append(&2, AST.TelescopeItem, List.append(&2, AST.TelescopeItem, List.append(&2, AST.TelescopeItem, binders, pattern_binders), c_bang_capture_binders(captures, span)), [c_bang_continuation_binder(span)])
      next_body = c_replace_bang_placeholder(Core.shift(0n, 1n + capture_count, continuation_body), capture_count)
      continuation = IndexedDefinition{ "", next_key, next_key, next_binders, result, AST.DefTerm{next_body}, unsafe, span}
      [continuation]
    case None{}: Nil{}

def c_definition_match_term(definition: IndexedDefinition) -> Maybe<&2, AST.SyntaxTerm>:
  match definition:
    case IndexedDefinition{ _,  _,  _,  _,  _,  AST.DefTerm{ AST.BodyMatch{scrutinees, cases, span}},  _,  _}:
      Some{AST.BodyMatch{scrutinees, cases, span}}
    case IndexedDefinition{ _,  _,  _,  _,  _,  AST.DefTerm{ AST.BodyLocal{patterns,  _, values, body, span}},  _,  _}:
      Some{AST.BodyMatch{ values,  [AST.BodyCase{patterns, body, span}], span}}
    case _: None{}
def c_match_continuations(definition: IndexedDefinition) -> List<&2, IndexedDefinition>:
  match definition:
    case IndexedDefinition{ _,  _, full_key, binders, result,  _, unsafe, span}:
      c_match_continuations_result(c_definition_match_term(definition), full_key, binders, result, unsafe, span)

def c_match_continuations_result(found: Maybe<&2, AST.SyntaxTerm>, full_key: String, binders: List<&2, AST.TelescopeItem>, result: AST.OptionalTerm, unsafe: Bool, span: AST.SourceSpan) -> List<&2, IndexedDefinition>:
  match found:
    case Some{AST.BodyMatch{_, cases, _}}: c_match_case_continuations(cases, full_key, binders, result, unsafe, span, 0n)
    case _: Nil{}

def c_append_match_continuations(definitions: List<&2, IndexedDefinition>) -> List<&2, IndexedDefinition>:
  match definitions:
    case Nil{}: Nil{}
    case +definition <> rest:
      List.append(&2, IndexedDefinition, c_match_continuations(definition), c_append_match_continuations(rest))

def nat_eval(term: AST.SyntaxTerm, definitions: List<&2, IndexedDefinition>, fuel: Nat) -> Maybe<&2, Nat>:
  match fuel:
    case 0n: None{}
    case 1n+remaining:
      match term:
        case AST.TermAnn{term,  _,  _}: nat_eval(term, definitions, remaining)
        case AST.TermSub{index, value, body,  _}:
          nat_eval(Core.subst(index, value, body), definitions, remaining)
        case AST.TermLet{keys, indexes, quantities, values, body,  _}:
          nat_eval(substitute_let_values(List.reverse(&2, AST.SyntaxTerm, values), body), definitions, remaining)
        case AST.TermRef{key,  _}: nat_eval_reference(find_definition(key, definitions), definitions, remaining)
        case AST.TermCtr{key, args,  _}: nat_eval_constructor(key_is(key, "Zero"), key, args, definitions, remaining)
        case AST.TermApp{ _,  _,  _}: nat_eval_spine(app_spine(term), definitions, remaining)
        case _: None{}

def nat_eval_reference(found: Maybe<&2, IndexedDefinition>, definitions: List<&2, IndexedDefinition>, remaining: Nat) -> Maybe<&2, Nat>:
  match found:
    case Some{IndexedDefinition{_, _, _, Nil{}, _, AST.DefTerm{value}, _, _}}: nat_eval(value, definitions, remaining)
    case _: None{}

def nat_eval_constructor(is_zero: Bool, key: String, args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, remaining: Nat) -> Maybe<&2, Nat>:
  match is_zero:
    case True{}: Some{0n}
    case False{}: nat_eval_successor(key_is(key, "Succ"), args, definitions, remaining)

def nat_eval_successor(is_succ: Bool, args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, remaining: Nat) -> Maybe<&2, Nat>:
  match is_succ:
    case True{}:
      match args:
        case +next <> Nil{}: nat_eval_successor_value(nat_eval(next, definitions, remaining))
        case _: None{}
    case False{}: None{}

def nat_eval_successor_value(result: Maybe<&2, Nat>) -> Maybe<&2, Nat>:
  match result:
    case Some{value}: Some{nat_clamp(value + 1n)}
    case None{}: None{}

def nat_eval_spine(spine: AppSpine, definitions: List<&2, IndexedDefinition>, remaining: Nat) -> Maybe<&2, Nat>:
  match spine:
    case AppSpine{head, args}: nat_eval_call(head, args, definitions, remaining)

def app_spine(term: AST.SyntaxTerm) -> AppSpine:
  match term:
    case AST.TermApp{fn, arg,  _}: app_spine_add(app_spine(fn), arg)
    case AST.TermAnn{term,  _,  _}: app_spine(term)
    case AST.TermTemplate{term,  _}: app_spine(term)
    case AST.TermBang{ _,  _}: AppSpine{ term,  Nil{}}

def app_spine_add(spine: AppSpine, arg: AST.SyntaxTerm) -> AppSpine:
  match spine:
    case AppSpine{head, args}: AppSpine{head, List.append(&2, AST.SyntaxTerm, args, [arg])}

def c_bang_call(term: AST.SyntaxTerm) -> Maybe<&2, BangCall>:
  c_bang_call_spine(app_spine(term))

def c_bang_call_spine(spine: AppSpine) -> Maybe<&2, BangCall>:
  match spine:
    case AppSpine{AST.TermBang{AST.TermRef{key, _}, _}, args}: Some{BangCall{key, args}}
    case _: None{}
def c_segment_binder_env(binders: List<&2, AST.TelescopeItem>, index: Nat) -> List<&2, String>:
  match binders:
    case Nil{}: Nil{}
    case +binder <> rest:
      match binder:
        case AST.Binder{ AST.QZero{},  _,  _,  _,  _}: List.append(&2, String, c_segment_binder_env(rest, index), ["0"])
        case AST.Binder{ _,  _,  _,  _,  _}: List.append(&2, String, c_segment_binder_env(rest, index + 1n), [String.append("r", Nat.show(index))])
        case AST.TemplateBinder{ _,  _,  _,  _}: List.append(&2, String, c_segment_binder_env(rest, index), ["0"])

def c_bang_rows(args: List<&2, AST.SyntaxTerm>, index: Nat, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>, task: Bool) -> Maybe<&2, String>:
  match args:
    case Nil{}: Some{""}
    case +arg <> rest:
      c_bang_rows_pair(c_expr_env(arg, definitions, arity, locals), c_bang_rows(rest, index + 1n, definitions, arity, locals, task), index, task)

def c_bang_rows_pair(value: Maybe<&2, String>, tail: Maybe<&2, String>, index: Nat, task: Bool) -> Maybe<&2, String>:
  match value tail:
    case Some{source} Some{rest}:
      match task:
        case True{}: Some{String.append(String.concat(["    e.mem[__bend_task + ", Nat.show(index), "] = ", source, ";\n"]), rest)}
        case False{}: Some{String.append(String.concat(["    r", Nat.show(index), " = ", source, ";\n"]), rest)}
    case _ _: None{}

def c_bang_supported(key: String, args: List<&2, AST.SyntaxTerm>, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>) -> Bool:
  c_bang_supported_context(key, args, binder_count(binders), c_binder_env(binders, 0n), definitions)

def c_bang_supported_context(key: String, args: List<&2, AST.SyntaxTerm>, arity: Nat, locals: List<&2, String>, definitions: List<&2, IndexedDefinition>) -> Bool:
  c_bang_supported_definition(find_definition(key, definitions), args, arity, locals, definitions)

def c_bang_supported_definition(found: Maybe<&2, IndexedDefinition>, args: List<&2, AST.SyntaxTerm>, arity: Nat, locals: List<&2, String>, definitions: List<&2, IndexedDefinition>) -> Bool:
  match found:
    case Some{IndexedDefinition{_, _, _, target_binders, _, _, _, _}}:
      live_args = c_live_arguments(target_binders, args, definitions, arity, locals)
      c_bang_supported_arity(Nat.is_eq(List.length(&2, AST.SyntaxTerm, live_args), c_live_binder_count(target_binders)), live_args, definitions, arity, locals)
    case None{}: False{}

def c_bang_supported_arity(valid: Bool, live_args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Bool:
  match valid:
    case True{}: c_bang_rows_supported(c_bang_rows(live_args, 0n, definitions, arity, locals, False{}))
    case False{}: False{}

def c_bang_rows_supported(found: Maybe<&2, String>) -> Bool:
  match found:
    case Some{_}: True{}
    case None{}: False{}

def c_bang_segment(current_key: String, bang: BangCall, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>) -> Maybe<&2, String>:
  match bang:
    case BangCall{key, args}:
      locals = c_segment_binder_env(binders, 0n)
      c_bang_segment_definition(find_definition(key, definitions), current_key, args, binders, definitions, locals)

def c_bang_segment_definition(found: Maybe<&2, IndexedDefinition>, current_key: String, args: List<&2, AST.SyntaxTerm>, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>, locals: List<&2, String>) -> Maybe<&2, String>:
  match found:
    case Some{IndexedDefinition{_, _, target_key, target_binders, _, _, _, _}}:
      live_args = c_live_arguments(target_binders, args, definitions, c_live_binder_count(binders), locals)
      c_bang_segment_arity(Nat.is_eq(List.length(&2, AST.SyntaxTerm, live_args), c_live_binder_count(target_binders)), target_key, current_key, live_args, binders, definitions, locals)
    case None{}: None{}

def c_bang_segment_arity(valid: Bool, target_key: String, current_key: String, live_args: List<&2, AST.SyntaxTerm>, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>, locals: List<&2, String>) -> Maybe<&2, String>:
  match valid:
    case False{}: None{}
    case True{}:
      c_bang_segment_rows(c_bang_rows(live_args, 0n, definitions, c_live_binder_count(binders), locals, True{}), c_bang_rows(live_args, 0n, definitions, c_live_binder_count(binders), locals, False{}), target_key, current_key)

def c_bang_segment_rows(tasks: Maybe<&2, String>, registers: Maybe<&2, String>, target_key: String, current_key: String) -> Maybe<&2, String>:
  match tasks registers:
    case Some{task_rows} Some{register_rows}:
      fid = fid_macro(target_key)
      Some{String.concat([
        "  WL_CASE(", fid_macro(current_key), ")\n  {\n    WL_OPEN\n    if (!seq) {\n      Loc __bend_task = task_node(e, ", fid, ", WL_CONT, WL_IDX, 0);\n",
        task_rows, "      return term_tsk(", fid, ", __bend_task);\n    }\n",
        register_rows, "    WL_JMP(", fid, ");\n  }}\n"
      ])}
    case _ _: None{}
def c_apply_args(head: AST.SyntaxTerm, args: List<&2, AST.SyntaxTerm>, span: AST.SourceSpan) -> AST.SyntaxTerm:
  match args:
    case Nil{}: head
    case +arg <> rest: c_apply_args(AST.TermApp{ head, arg, span}, rest, span)

def c_substitute_call_args(args: List<&2, AST.SyntaxTerm>, body: AST.SyntaxTerm) -> AST.SyntaxTerm:
  match args:
    case Nil{}: body
    case +arg <> rest: c_substitute_call_args(rest, Core.subst(0n, arg, body))

def c_has_lambda_term(term: AST.SyntaxTerm) -> Bool:
  match term:
    case AST.TermLam{ _,  _,  _,  _,  _}: True{}
    case AST.TermAnn{term,  _,  _}: c_has_lambda_term(term)
    case AST.TermTemplate{term,  _}: c_has_lambda_term(term)
    case AST.TermSub{ _, value, body,  _}: Bool.or(c_has_lambda_term(value), c_has_lambda_term(body))
    case _: False{}

def c_has_lambda(args: List<&2, AST.SyntaxTerm>) -> Bool:
  match args:
    case Nil{}: False{}
    case +arg <> rest: Bool.or(c_has_lambda_term(arg), c_has_lambda(rest))
def c_beta_apply(body: AST.SyntaxTerm, args: List<&2, AST.SyntaxTerm>, span: AST.SourceSpan, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  match args:
    case +arg <> rest:
      c_expr_env(c_apply_args(Core.subst(0n, arg, body), rest, span), definitions, arity, locals)
    case Nil{}: None{}

def binder_count(binders: List<&2, AST.TelescopeItem>) -> Nat:
  match binders:
    case Nil{}: 0n
    case +binder <> rest:
      match binder:
        case AST.Binder{ _,  _,  _,  _,  _}: 1n + binder_count(rest)
        case AST.TemplateBinder{ _,  _,  _,  _}: 1000000000000000000n

def c_live_binder_count(binders: List<&2, AST.TelescopeItem>) -> Nat:
  match binders:
    case Nil{}: 0n
    case +binder <> rest:
      match binder:
        case AST.Binder{ AST.QZero{},  _,  _,  _,  _}: c_live_binder_count(rest)
        case AST.Binder{ _,  _,  _,  _,  _}: 1n + c_live_binder_count(rest)
        case AST.TemplateBinder{ _,  _,  _,  _}: c_live_binder_count(rest)

def c_binder_env(binders: List<&2, AST.TelescopeItem>, index: Nat) -> List<&2, String>:
  match binders:
    case Nil{}: Nil{}
    case +binder <> rest:
      match binder:
        case AST.Binder{ AST.QZero{},  _,  _,  _,  _}: List.append(&2, String, c_binder_env(rest, index), ["0"])
        case AST.Binder{ _,  _,  _,  _,  _}: List.append(&2, String, c_binder_env(rest, index + 1n), [String.append("a", Nat.show(index))])
        case AST.TemplateBinder{ _,  _,  _,  _}: List.append(&2, String, c_binder_env(rest, index), ["0"])

def c_erased_term(term: AST.SyntaxTerm, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Bool:
  match term:
    case AST.TermVar{_, _, _}: c_erased_result(c_expr_env(term, definitions, arity, locals))
    case _: False{}

def c_erased_result(found: Maybe<&2, String>) -> Bool:
  match found:
    case Some{value}: String.eq(value, "0")
    case None{}: False{}

def c_live_arguments(binders: List<&2, AST.TelescopeItem>, args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> List<&2, AST.SyntaxTerm>:
  c_live_arguments_arity(Nat.is_eq(List.length(&2, AST.SyntaxTerm, args), c_live_binder_count(binders)), binders, args, definitions, arity, locals)

def c_live_arguments_arity(valid: Bool, binders: List<&2, AST.TelescopeItem>, args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> List<&2, AST.SyntaxTerm>:
  match valid:
    case True{}:
      c_live_arguments_first(binders, args, definitions, arity, locals)
    case False{}: c_filter_live_arguments(binders, args)

def c_live_arguments_first(binders: List<&2, AST.TelescopeItem>, args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> List<&2, AST.SyntaxTerm>:
  match binders args:
    case +AST.Binder{AST.QZero{}, _, _, _, _} <> _ +arg <> _:
      c_live_arguments_erased(c_erased_term(arg, definitions, arity, locals), binders, args)
    case _: args

def c_live_arguments_erased(erased: Bool, binders: List<&2, AST.TelescopeItem>, args: List<&2, AST.SyntaxTerm>) -> List<&2, AST.SyntaxTerm>:
  match erased:
    case True{}: c_filter_live_arguments(binders, args)
    case False{}: args

def c_filter_live_arguments(binders: List<&2, AST.TelescopeItem>, args: List<&2, AST.SyntaxTerm>) -> List<&2, AST.SyntaxTerm>:
  match binders args:
    case Nil{} rest: rest
    case +binder <> binders_rest +arg <> args_rest:
      match binder:
        case AST.Binder{ AST.QZero{},  _,  _,  _,  _}: c_filter_live_arguments(binders_rest, args_rest)
        case AST.Binder{ _,  _,  _,  _,  _}: arg <> c_filter_live_arguments(binders_rest, args_rest)
        case AST.TemplateBinder{ _,  _,  _,  _}: c_filter_live_arguments(binders_rest, args_rest)
    case _ _: Nil{}

def c_fn_name(key: String) -> String:
  String.append("bend_fn_", c_identifier(key))

def c_parameter_names(count: Nat, index: Nat) -> String:
  match count:
    case 0n: ""
    case 1n+remaining:
      match index:
        case 0n: String.append("Term a", Nat.show(index))
        case _:
          String.append("Term a", String.append(Nat.show(index), String.append(", ", c_parameter_names(remaining, index + 1n))))

def c_argument_values(args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  match args:
    case Nil{}: Some{""}
    case +arg <> rest:
      c_argument_values_pair(c_expr_env(arg, definitions, arity, locals), c_argument_values(rest, definitions, arity, locals))

def c_argument_values_pair(one: Maybe<&2, String>, tail: Maybe<&2, String>) -> Maybe<&2, String>:
  match one tail:
    case Some{value} Some{rest}: c_argument_values_join(value, rest, String.is_empty(rest))
    case _ _: None{}

def c_argument_values_join(value: String, rest: String, empty: Bool) -> Maybe<&2, String>:
  match empty:
    case True{}: Some{value}
    case False{}: Some{String.append(value, String.append(", ", rest))}
def c_take_args(args: List<&2, AST.SyntaxTerm>, count: Nat) -> List<&2, AST.SyntaxTerm>:
  match count args:
    case 0n _: Nil{}
    case 1n+rest_count +arg <> rest: arg <> c_take_args(rest, rest_count)
    case _ _: Nil{}

def c_drop_args(args: List<&2, AST.SyntaxTerm>, count: Nat) -> List<&2, AST.SyntaxTerm>:
  match count args:
    case 0n _: args
    case 1n+rest_count +_ <> rest: c_drop_args(rest, rest_count)
    case _ _: Nil{}
def c_expr_overapplied_call(full_key: String, call_arity: Nat, args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  prefix = c_take_args(args, call_arity)
  suffix = c_drop_args(args, call_arity)
  c_expr_overapplied_values(c_argument_values(prefix, definitions, arity, locals), c_argument_values(suffix, definitions, arity, locals), full_key, suffix, definitions)

def c_expr_overapplied_values(prefix: Maybe<&2, String>, suffix_values: Maybe<&2, String>, full_key: String, suffix: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>) -> Maybe<&2, String>:
  match prefix suffix_values:
    case Some{prefix_values} Some{suffix_source}:
      call = String.append(c_fn_name(full_key), String.append("(e", String.append(c_call_separator(prefix_values), ")")))
      Some{c_indirect_call(call, suffix_source, List.length(&2, AST.SyntaxTerm, suffix), definitions)}
    case _ _: None{}



def c_closure_captures(count: Nat, index: Nat) -> String:
  match count:
    case 0n: ""
    case 1n+remaining:
      value = String.append("e.mem[term_peek(e, __bend_clo) + ", String.append(Nat.show(index), "]"))
      String.append(value, String.append(", ", c_closure_captures(remaining, index + 1n)))

def c_indirect_function_arity(user_arity: Nat, continuation: Bool) -> Nat:
  match continuation:
    case True{}: user_arity + 1n
    case False{}: user_arity

def c_indirect_regular_case(full_key: String, binders: List<&2, AST.TelescopeItem>, rest: List<&2, IndexedDefinition>, args: String, arity: Nat, continuation: Bool) -> String:
  user_arity = c_live_binder_count(binders)
  function_arity = c_indirect_function_arity(user_arity, continuation)
  c_indirect_regular_case_size(function_arity < arity, Nat.is_eq(function_arity, arity), full_key, binders, rest, args, arity, function_arity)

def c_indirect_regular_case_size(too_small: Bool, exact: Bool, full_key: String, binders: List<&2, AST.TelescopeItem>, rest: List<&2, IndexedDefinition>, args: String, arity: Nat, function_arity: Nat) -> String:
  match too_small:
    case True{}: c_indirect_cases(rest, args, arity)
    case False{}: c_indirect_regular_case_exact(exact, full_key, rest, args, arity, function_arity)

def c_indirect_regular_case_exact(exact: Bool, full_key: String, rest: List<&2, IndexedDefinition>, args: String, arity: Nat, function_arity: Nat) -> String:
  match exact:
    case True{}:
      row = String.append("case ", String.append(fid_macro(full_key), String.append(": if ((__bend_clo & LOC_MASK) == 0) __bend_result = ", String.append(c_fn_name(full_key), String.append("(e", String.append(c_call_separator(args), ")); else err_post(e.mem, ERR_FIDS); break; "))))))
      String.append(row, c_indirect_cases(rest, args, arity))
    case False{}:
      captures = function_arity - arity
      capture_args = c_closure_captures(captures, 0n)
      callargs = String.append(capture_args, args)
      partial = String.append("bend_closure_make(e, ", String.append(fid_macro(full_key), String.append(", ", String.append(Nat.show(arity), String.append(", (Term[]){", String.append(args, "})"))))))
      row = String.append("case ", String.append(fid_macro(full_key), String.append(": if ((__bend_clo & LOC_MASK) == 0) __bend_result = ", String.append(partial, "; else __bend_result = ", String.append(c_fn_name(full_key), String.append("(e", String.append(c_call_separator(callargs), ")); break; ")))))))
      String.append(row, c_indirect_cases(rest, args, arity))

def c_indirect_cases(definitions: List<&2, IndexedDefinition>, args: String, arity: Nat) -> String:
  match definitions:
    case Nil{}: ""
    case +definition <> rest:
      match definition:
        case IndexedDefinition{_, key, full_key, binders, _, AST.DefTerm{AST.TermLam{_, _, _, _, _}}, _, _}:
          c_indirect_lambda_case(String.starts_with(key, "__lambda_"), key, full_key, binders, rest, args, arity)
        case IndexedDefinition{_, _, full_key, binders, _, AST.DefImports{_}, _, _}:
          c_indirect_regular_case(full_key, binders, rest, args, arity, True{})
        case IndexedDefinition{_, _, full_key, binders, _, _, _, _}:
          c_indirect_regular_case(full_key, binders, rest, args, arity, False{})

def c_indirect_lambda_case(is_lambda: Bool, key: String, full_key: String, binders: List<&2, AST.TelescopeItem>, rest: List<&2, IndexedDefinition>, args: String, arity: Nat) -> String:
  match is_lambda:
    case True{}:
      captures = binder_count(binders) - 1n
      c_indirect_lambda_arity(Nat.is_eq(arity, 1n), captures, full_key, rest, args, arity)
    case False{}: c_indirect_regular_case(full_key, binders, rest, args, arity, False{})

def c_indirect_lambda_arity(single: Bool, captures: Nat, full_key: String, rest: List<&2, IndexedDefinition>, args: String, arity: Nat) -> String:
  match single:
    case True{}:
      callargs = String.append(c_closure_captures(captures, 0n), args)
      row = String.append("case ", String.append(fid_macro(full_key), String.append(": __bend_result = ", String.append(c_fn_name(full_key), String.append("(e", String.append(c_call_separator(callargs), ")); break; "))))))
      String.append(row, c_indirect_cases(rest, args, arity))
    case False{}: c_indirect_cases(rest, args, arity)

def c_indirect_call(closure: String, args: String, arity: Nat, definitions: List<&2, IndexedDefinition>) -> String:
  String.append("({ Term __bend_clo = ", String.append(closure, String.append("; Term __bend_result = 0; if (term_tag(__bend_clo) == TAG_CLO) { switch (term_aux(__bend_clo)) { ", String.append(c_indirect_cases(definitions, args, arity), String.append("default: err_post(e.mem, ERR_FIDS); } } else { err_post(e.mem, ERR_FIDS); } __bend_result; })")))))

def c_call_separator(values: String) -> String:
  c_call_separator_empty(String.is_empty(values), values)

def c_call_separator_empty(empty: Bool, values: String) -> String:
  match empty:
    case True{}: ""
    case False{}: String.append(", ", values)

def c_capture_arguments(count: Nat, index: Nat) -> String:
  match count:
    case 0n: ""
    case 1n+remaining:
      String.append("a", String.append(Nat.show(index), c_call_separator(c_capture_arguments(remaining, index + 1n))))

def c_capture_values(arity: Nat, locals: List<&2, String>) -> String:
  arguments = c_capture_arguments(arity, 0n)
  local_values = c_join_values(List.reverse(&2, String, locals))
  c_capture_values_arguments(String.is_empty(arguments), arguments, local_values)

def c_capture_values_arguments(empty: Bool, arguments: String, local_values: String) -> String:
  match empty:
    case True{}: local_values
    case False{}: c_capture_values_locals(String.is_empty(local_values), arguments, local_values)

def c_capture_values_locals(empty: Bool, arguments: String, local_values: String) -> String:
  match empty:
    case True{}: arguments
    case False{}: String.append(arguments, String.append(", ", local_values))

def c_join_values(values: List<&2, String>) -> String:
  match values:
    case Nil{}: ""
    case +value <> rest:
      match rest:
        case Nil{}: value
        case _: String.append(value, String.append(", ", c_join_values(rest)))

def c_lambda_value_pointer(count: Nat, values: String) -> String:
  match count:
    case 0n: "NULL"
    case _: String.append("(Term[]){", String.append(values, "}"))

def c_lambda_value(span: AST.SourceSpan, arity: Nat, locals: List<&2, String>) -> String:
  count = arity + List.length(&2, String, locals)
  values = c_capture_values(arity, locals)
  pointer = c_lambda_value_pointer(count, values)
  String.append("bend_closure_make(e, ", String.append(fid_macro(c_lambda_key(span)), String.append(", ", String.append(Nat.show(count), String.append(", ", String.append(pointer, ")"))))))


def c_u32_op(operator: String, a: String, b: String) -> String:
  String.concat(["((u32)(", a, ") ", operator, " (u32)(", b, "))"])

def c_u32_binary(key: String, a: String, b: String) -> Maybe<&2, String>:
  c_u32_add(String.ends_with(key, "U32.add"), key, a, b)

def c_u32_add(is_add: Bool, key: String, a: String, b: String) -> Maybe<&2, String>:
  match is_add:
    case True{}: Some{c_u32_op("+", a, b)}
    case False{}: c_u32_sub(String.ends_with(key, "U32.sub"), key, a, b)

def c_u32_sub(is_sub: Bool, key: String, a: String, b: String) -> Maybe<&2, String>:
  match is_sub:
    case True{}: Some{c_u32_op("-", a, b)}
    case False{}: c_u32_mul(String.ends_with(key, "U32.mul"), key, a, b)

def c_u32_mul(is_mul: Bool, key: String, a: String, b: String) -> Maybe<&2, String>:
  match is_mul:
    case True{}: Some{c_u32_op("*", a, b)}
    case False{}: c_u32_div(String.ends_with(key, "U32.div"), key, a, b)

def c_u32_div(is_div: Bool, key: String, a: String, b: String) -> Maybe<&2, String>:
  match is_div:
    case True{}: Some{String.concat(["((u32)(", b, ") == 0 ? 0 : ((u32)(", a, ") / (u32)(", b, ")))"])}
    case False{}: c_u32_mod(String.ends_with(key, "U32.mod"), key, a, b)

def c_u32_mod(is_mod: Bool, key: String, a: String, b: String) -> Maybe<&2, String>:
  match is_mod:
    case True{}: Some{String.concat(["((u32)(", b, ") == 0 ? (u32)(", a, ") : ((u32)(", a, ") % (u32)(", b, ")))"])}
    case False{}: c_u32_and(String.ends_with(key, "U32.and"), key, a, b)

def c_u32_and(is_and: Bool, key: String, a: String, b: String) -> Maybe<&2, String>:
  match is_and:
    case True{}: Some{c_u32_op("&", a, b)}
    case False{}: c_u32_or(String.ends_with(key, "U32.or"), key, a, b)

def c_u32_or(is_or: Bool, key: String, a: String, b: String) -> Maybe<&2, String>:
  match is_or:
    case True{}: Some{c_u32_op("|", a, b)}
    case False{}: c_u32_xor(String.ends_with(key, "U32.xor"), key, a, b)

def c_u32_xor(is_xor: Bool, key: String, a: String, b: String) -> Maybe<&2, String>:
  match is_xor:
    case True{}: Some{c_u32_op("^", a, b)}
    case False{}: c_u32_eq(String.ends_with(key, "U32.is_eq"), key, a, b)

def c_u32_eq(is_eq: Bool, key: String, a: String, b: String) -> Maybe<&2, String>:
  match is_eq:
    case True{}: Some{c_u32_op("==", a, b)}
    case False{}: c_u32_ne(String.ends_with(key, "U32.is_ne"), key, a, b)

def c_u32_ne(is_ne: Bool, key: String, a: String, b: String) -> Maybe<&2, String>:
  match is_ne:
    case True{}: Some{c_u32_op("!=", a, b)}
    case False{}: c_u32_lt(String.ends_with(key, "U32.is_lt"), key, a, b)

def c_u32_lt(is_lt: Bool, key: String, a: String, b: String) -> Maybe<&2, String>:
  match is_lt:
    case True{}: Some{c_u32_op("<", a, b)}
    case False{}: c_u32_le(String.ends_with(key, "U32.is_le"), key, a, b)

def c_u32_le(is_le: Bool, key: String, a: String, b: String) -> Maybe<&2, String>:
  match is_le:
    case True{}: Some{c_u32_op("<=", a, b)}
    case False{}: c_u32_gt(String.ends_with(key, "U32.is_gt"), key, a, b)

def c_u32_gt(is_gt: Bool, key: String, a: String, b: String) -> Maybe<&2, String>:
  match is_gt:
    case True{}: Some{c_u32_op(">", a, b)}
    case False{}: c_u32_ge(String.ends_with(key, "U32.is_ge"), key, a, b)

def c_u32_ge(is_ge: Bool, key: String, a: String, b: String) -> Maybe<&2, String>:
  match is_ge:
    case True{}: Some{c_u32_op(">=", a, b)}
    case False{}: c_u32_shln(String.ends_with(key, "U32.shln"), key, a, b)

def c_u32_shln(is_shln: Bool, key: String, a: String, b: String) -> Maybe<&2, String>:
  match is_shln:
    case True{}: Some{String.concat(["((u32)(", b, ") >= 32 ? 0 : ((u32)(", a, ") << (u32)(", b, ")))"])}
    case False{}: c_u32_shrn(String.ends_with(key, "U32.shrn"), a, b)

def c_u32_shrn(is_shrn: Bool, a: String, b: String) -> Maybe<&2, String>:
  match is_shrn:
    case True{}: Some{String.concat(["((u32)(", b, ") >= 32 ? 0 : ((u32)(", a, ") >> (u32)(", b, ")))"])}
    case False{}: None{}

def c_u32_unary(key: String, value: String) -> Maybe<&2, String>:
  c_u32_is_zero(String.ends_with(key, "U32.is_zero"), key, value)

def c_u32_is_zero(is_zero: Bool, key: String, value: String) -> Maybe<&2, String>:
  match is_zero:
    case True{}: Some{String.concat(["((u32)(", value, ") == 0)"])}
    case False{}: c_u32_not(String.ends_with(key, "U32.not"), key, value)

def c_u32_not(is_not: Bool, key: String, value: String) -> Maybe<&2, String>:
  match is_not:
    case True{}: Some{String.concat(["((u32)~(u32)(", value, "))"])}
    case False{}: c_u32_inc(String.ends_with(key, "U32.inc"), key, value)

def c_u32_inc(is_inc: Bool, key: String, value: String) -> Maybe<&2, String>:
  match is_inc:
    case True{}: Some{String.concat(["((u32)(", value, ") + 1)"])}
    case False{}: c_u32_shl(String.ends_with(key, "U32.shl"), key, value)

def c_u32_shl(is_shl: Bool, key: String, value: String) -> Maybe<&2, String>:
  match is_shl:
    case True{}: Some{String.concat(["((u32)(", value, ") << 1)"])}
    case False{}: c_u32_shr(String.ends_with(key, "U32.shr"), value)

def c_u32_shr(is_shr: Bool, value: String) -> Maybe<&2, String>:
  match is_shr:
    case True{}: Some{String.concat(["((u32)(", value, ") >> 1)"])}
    case False{}: None{}

def c_f32_binary(key: String, a: String, b: String) -> Maybe<&2, String>:
  c_f32_binary_flags(String.ends_with(key, "F32.add"), String.ends_with(key, "F32.sub"), String.ends_with(key, "F32.mul"), String.ends_with(key, "F32.div"), String.ends_with(key, "F32.mod"), String.ends_with(key, "F32.is_eq"), String.ends_with(key, "F32.is_ne"), String.ends_with(key, "F32.is_lt"), String.ends_with(key, "F32.is_le"), String.ends_with(key, "F32.is_gt"), String.ends_with(key, "F32.is_ge"), String.ends_with(key, "F32.pow"), String.ends_with(key, "F32.atan2"), a, b)

def c_f32_binary_flags(add: Bool, sub: Bool, mul: Bool, div: Bool, modulo: Bool, is_eq: Bool, is_ne: Bool, is_lt: Bool, is_le: Bool, is_gt: Bool, is_ge: Bool, power: Bool, atan2: Bool, a: String, b: String) -> Maybe<&2, String>:
  match add sub mul div modulo is_eq is_ne is_lt is_le is_gt is_ge power atan2:
    case True{} _ _ _ _ _ _ _ _ _ _ _ _: Some{String.concat(["f32_rewrap((f32)(f32_unbox(", a, ") + f32_unbox(", b, ")))"])}
    case False{} True{} _ _ _ _ _ _ _ _ _ _ _: Some{String.concat(["f32_rewrap((f32)(f32_unbox(", a, ") - f32_unbox(", b, ")))"])}
    case False{} False{} True{} _ _ _ _ _ _ _ _ _ _: Some{String.concat(["f32_rewrap((f32)(f32_unbox(", a, ") * f32_unbox(", b, ")))"])}
    case False{} False{} False{} True{} _ _ _ _ _ _ _ _ _: Some{String.concat(["f32_rewrap((f32)(f32_unbox(", a, ") / f32_unbox(", b, ")))"])}
    case False{} False{} False{} False{} True{} _ _ _ _ _ _ _ _: Some{String.concat(["f32_rewrap((f32)fmod(f32_unbox(", a, "), f32_unbox(", b, ")))"])}
    case False{} False{} False{} False{} False{} True{} _ _ _ _ _ _ _: Some{String.concat(["((u64)(f32_unbox(", a, ") == f32_unbox(", b, ")))"])}
    case False{} False{} False{} False{} False{} False{} True{} _ _ _ _ _ _: Some{String.concat(["((u64)(f32_unbox(", a, ") != f32_unbox(", b, ")))"])}
    case False{} False{} False{} False{} False{} False{} False{} True{} _ _ _ _ _: Some{String.concat(["((u64)(f32_unbox(", a, ") < f32_unbox(", b, ")))"])}
    case False{} False{} False{} False{} False{} False{} False{} False{} True{} _ _ _ _: Some{String.concat(["((u64)(f32_unbox(", a, ") <= f32_unbox(", b, ")))"])}
    case False{} False{} False{} False{} False{} False{} False{} False{} False{} True{} _ _ _: Some{String.concat(["((u64)(f32_unbox(", a, ") > f32_unbox(", b, ")))"])}
    case False{} False{} False{} False{} False{} False{} False{} False{} False{} False{} True{} _ _: Some{String.concat(["((u64)(f32_unbox(", a, ") >= f32_unbox(", b, ")))"])}
    case False{} False{} False{} False{} False{} False{} False{} False{} False{} False{} False{} True{} _: Some{String.concat(["f32_rewrap((f32)pow(f32_unbox(", a, "), f32_unbox(", b, ")))"])}
    case False{} False{} False{} False{} False{} False{} False{} False{} False{} False{} False{} False{} True{}: Some{String.concat(["f32_rewrap((f32)atan2(f32_unbox(", a, "), f32_unbox(", b, ")))"])}
    case _ _ _ _ _ _ _ _ _ _ _ _ _: None{}

def c_f32_math(name: String, value: String) -> String:
  String.concat(["f32_rewrap((f32)", name, "(f32_unbox(", value, ")))"])

def c_f32_math_unary(key: String, value: String) -> Maybe<&2, String>:
  c_f32_math_sqrt(String.ends_with(key, "F32.sqrt"), key, value)

def c_f32_math_sqrt(found: Bool, key: String, value: String) -> Maybe<&2, String>:
  match found:
    case True{}: Some{c_f32_math("sqrt", value)}
    case False{}: c_f32_math_exp(String.ends_with(key, "F32.exp"), key, value)

def c_f32_math_exp(found: Bool, key: String, value: String) -> Maybe<&2, String>:
  match found:
    case True{}: Some{c_f32_math("exp", value)}
    case False{}: c_f32_math_log(String.ends_with(key, "F32.log"), key, value)

def c_f32_math_log(found: Bool, key: String, value: String) -> Maybe<&2, String>:
  match found:
    case True{}: Some{c_f32_math("log", value)}
    case False{}: c_f32_math_log2(String.ends_with(key, "F32.log2"), key, value)

def c_f32_math_log2(found: Bool, key: String, value: String) -> Maybe<&2, String>:
  match found:
    case True{}: Some{c_f32_math("log2", value)}
    case False{}: c_f32_math_log10(String.ends_with(key, "F32.log10"), key, value)

def c_f32_math_log10(found: Bool, key: String, value: String) -> Maybe<&2, String>:
  match found:
    case True{}: Some{c_f32_math("log10", value)}
    case False{}: c_f32_math_sin(String.ends_with(key, "F32.sin"), key, value)

def c_f32_math_sin(found: Bool, key: String, value: String) -> Maybe<&2, String>:
  match found:
    case True{}: Some{c_f32_math("sin", value)}
    case False{}: c_f32_math_cos(String.ends_with(key, "F32.cos"), key, value)

def c_f32_math_cos(found: Bool, key: String, value: String) -> Maybe<&2, String>:
  match found:
    case True{}: Some{c_f32_math("cos", value)}
    case False{}: c_f32_math_tan(String.ends_with(key, "F32.tan"), key, value)

def c_f32_math_tan(found: Bool, key: String, value: String) -> Maybe<&2, String>:
  match found:
    case True{}: Some{c_f32_math("tan", value)}
    case False{}: c_f32_math_asin(String.ends_with(key, "F32.asin"), key, value)

def c_f32_math_asin(found: Bool, key: String, value: String) -> Maybe<&2, String>:
  match found:
    case True{}: Some{c_f32_math("asin", value)}
    case False{}: c_f32_math_acos(String.ends_with(key, "F32.acos"), key, value)

def c_f32_math_acos(found: Bool, key: String, value: String) -> Maybe<&2, String>:
  match found:
    case True{}: Some{c_f32_math("acos", value)}
    case False{}: c_f32_math_atan(String.ends_with(key, "F32.atan"), key, value)

def c_f32_math_atan(found: Bool, key: String, value: String) -> Maybe<&2, String>:
  match found:
    case True{}: Some{c_f32_math("atan", value)}
    case False{}: c_f32_math_sinh(String.ends_with(key, "F32.sinh"), key, value)

def c_f32_math_sinh(found: Bool, key: String, value: String) -> Maybe<&2, String>:
  match found:
    case True{}: Some{c_f32_math("sinh", value)}
    case False{}: c_f32_math_cosh(String.ends_with(key, "F32.cosh"), key, value)

def c_f32_math_cosh(found: Bool, key: String, value: String) -> Maybe<&2, String>:
  match found:
    case True{}: Some{c_f32_math("cosh", value)}
    case False{}: c_f32_math_tanh(String.ends_with(key, "F32.tanh"), key, value)

def c_f32_math_tanh(found: Bool, key: String, value: String) -> Maybe<&2, String>:
  match found:
    case True{}: Some{c_f32_math("tanh", value)}
    case False{}: c_f32_math_floor(String.ends_with(key, "F32.floor"), key, value)

def c_f32_math_floor(found: Bool, key: String, value: String) -> Maybe<&2, String>:
  match found:
    case True{}: Some{c_f32_math("floor", value)}
    case False{}: c_f32_math_ceil(String.ends_with(key, "F32.ceil"), key, value)

def c_f32_math_ceil(found: Bool, key: String, value: String) -> Maybe<&2, String>:
  match found:
    case True{}: Some{c_f32_math("ceil", value)}
    case False{}: c_f32_math_trunc(String.ends_with(key, "F32.trunc"), key, value)

def c_f32_math_trunc(found: Bool, key: String, value: String) -> Maybe<&2, String>:
  match found:
    case True{}: Some{c_f32_math("trunc", value)}
    case False{}: c_f32_math_abs(String.ends_with(key, "F32.abs"), value)

def c_f32_math_abs(found: Bool, value: String) -> Maybe<&2, String>:
  match found:
    case True{}: Some{c_f32_math("fabs", value)}
    case False{}: None{}

def c_f32_unary(key: String, value: String) -> Maybe<&2, String>:
  c_f32_unary_neg(String.ends_with(key, "F32.neg"), key, value)

def c_f32_unary_neg(found: Bool, key: String, value: String) -> Maybe<&2, String>:
  match found:
    case True{}: Some{String.concat(["f32_rewrap(-f32_unbox(", value, "))"])}
    case False{}: c_f32_unary_to_u32(String.ends_with(key, "F32.to_u32"), key, value)

def c_f32_unary_to_u32(found: Bool, key: String, value: String) -> Maybe<&2, String>:
  match found:
    case True{}: Some{String.concat(["f32_to_u32(", value, ")"])}
    case False{}: c_f32_unary_bits(String.ends_with(key, "F32.bits"), key, value)

def c_f32_unary_bits(found: Bool, key: String, value: String) -> Maybe<&2, String>:
  match found:
    case True{}: Some{value}
    case False{}: c_f32_unary_to_f32(String.ends_with(key, "U32.to_f32"), key, value)

def c_f32_unary_to_f32(found: Bool, key: String, value: String) -> Maybe<&2, String>:
  match found:
    case True{}: Some{String.concat(["f32_rewrap((f32)(u32)(", value, "))"])}
    case False{}: c_f32_math_unary(key, value)

def c_last_two(args: List<&2, AST.SyntaxTerm>) -> Maybe<&2, List<&2, AST.SyntaxTerm>>:
  match args:
    case +first <> +second <> rest:
      match rest:
        case Nil{}: Some{[first, second]}
        case _: c_last_two(rest)
    case _: None{}

def c_native_io_bind(args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  c_native_io_bind_args(c_last_two(args), definitions, arity, locals)

def c_native_io_bind_args(found: Maybe<&2, List<&2, AST.SyntaxTerm>>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  match found:
    case Some{[action, callback]}:
      c_native_io_bind_values(c_argument_values([action, callback], definitions, arity, locals))
    case _: None{}

def c_native_io_bind_values(found: Maybe<&2, String>) -> Maybe<&2, String>:
  match found:
    case Some{values}: Some{String.concat(["bend_closure_make(e, FID_CEMIT_IO_BIND, 2, (Term[]){", values, "})"])}
    case None{}: None{}

def c_native_call(key: String, args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  c_native_call_io(String.ends_with(key, "IO.bind"), key, args, definitions, arity, locals)

def c_native_call_io(is_io: Bool, key: String, args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  match is_io:
    case True{}: c_native_io_bind(args, definitions, arity, locals)
    case False{}: c_native_call_base(key, args, definitions, arity, locals)

def c_native_call_base(key: String, args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  c_native_call_double(String.ends_with(key, "Nat.double"), key, args, definitions, arity, locals)

def c_native_call_double(is_double: Bool, key: String, args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  match is_double:
    case True{}:
      match args:
        case +arg <> Nil{}: c_native_double_value(c_expr_env(arg, definitions, arity, locals))
        case _: None{}
    case False{}: c_native_call_args(key, args, definitions, arity, locals)

def c_native_double_value(found: Maybe<&2, String>) -> Maybe<&2, String>:
  match found:
    case Some{value}: Some{String.append("nat_chk(e, ", String.append(value, String.append(" + ", String.append(value, ")"))))}
    case None{}: None{}

def c_native_call_args(key: String, args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  match args:
    case +left <> +right <> Nil{}:
      c_native_binary_values(c_expr_env(left, definitions, arity, locals), c_expr_env(right, definitions, arity, locals), key)
    case +arg <> Nil{}:
      c_native_unary_value(c_expr_env(arg, definitions, arity, locals), key)
    case _: None{}

def c_native_binary_values(left: Maybe<&2, String>, right: Maybe<&2, String>, key: String) -> Maybe<&2, String>:
  match left right:
    case Some{a} Some{b}: c_native_binary_key(String.ends_with(key, "Nat.add"), String.ends_with(key, "Nat.sub"), String.ends_with(key, "Nat.mul"), String.ends_with(key, "Nat.div"), String.ends_with(key, "Nat.mod"), key, a, b)
    case _ _: None{}

def c_native_binary_key(add: Bool, sub: Bool, mul: Bool, div: Bool, modulo: Bool, key: String, a: String, b: String) -> Maybe<&2, String>:
  match add:
    case True{}: Some{String.append("nat_chk(e, ", String.append(a, String.append(" + ", String.append(b, ")"))))}
    case False{}: c_native_binary_sub(sub, mul, div, modulo, key, a, b)

def c_native_binary_sub(sub: Bool, mul: Bool, div: Bool, modulo: Bool, key: String, a: String, b: String) -> Maybe<&2, String>:
  match sub:
    case True{}: Some{String.append("((", String.append(a, String.append(" < ", String.append(b, String.append(") ? 0 : ", String.append(a, String.append(" - ", String.append(b, ")"))))))))}
    case False{}: c_native_binary_mul(mul, div, modulo, key, a, b)

def c_native_binary_mul(mul: Bool, div: Bool, modulo: Bool, key: String, a: String, b: String) -> Maybe<&2, String>:
  match mul:
    case True{}: Some{String.append("nat_mul(e, ", String.append(a, String.append(", ", String.append(b, ")"))))}
    case False{}: c_native_binary_div(div, modulo, key, a, b)

def c_native_binary_div(div: Bool, modulo: Bool, key: String, a: String, b: String) -> Maybe<&2, String>:
  match div:
    case True{}: Some{String.append("((", String.append(b, String.append(") == 0 ? 0 : (", String.append(a, String.append(") / (", String.append(b, "))"))))))}
    case False{}: c_native_binary_mod(modulo, key, a, b)

def c_native_binary_mod(modulo: Bool, key: String, a: String, b: String) -> Maybe<&2, String>:
  match modulo:
    case True{}: Some{String.append("((", String.append(b, String.append(") == 0 ? (", String.append(a, String.append(") : (", String.append(a, String.append(") % (", String.append(b, "))"))))))))}
    case False{}: c_native_binary_float(c_f32_binary(key, a, b), key, a, b)

def c_native_binary_float(found: Maybe<&2, String>, key: String, a: String, b: String) -> Maybe<&2, String>:
  match found:
    case Some{value}: Some{value}
    case None{}: c_u32_binary(key, a, b)

def c_native_unary_value(found: Maybe<&2, String>, key: String) -> Maybe<&2, String>:
  match found:
    case Some{value}: c_native_unary_key(String.ends_with(key, "U32.to_nat"), String.ends_with(key, "U32.from_nat"), key, value)
    case None{}: None{}

def c_native_unary_key(to_nat: Bool, from_nat: Bool, key: String, value: String) -> Maybe<&2, String>:
  match to_nat:
    case True{}: Some{String.append("((u32)", String.append(value, ")"))}
    case False{}: c_native_unary_from_nat(from_nat, key, value)

def c_native_unary_from_nat(from_nat: Bool, key: String, value: String) -> Maybe<&2, String>:
  match from_nat:
    case True{}: Some{String.append("((u32)", String.append(value, ")"))}
    case False{}: c_native_unary_u32(c_u32_unary(key, value), key, value)

def c_native_unary_u32(found: Maybe<&2, String>, key: String, value: String) -> Maybe<&2, String>:
  match found:
    case Some{unary}: Some{unary}
    case None{}: c_f32_unary(key, value)

def c_env_lookup(locals: List<&2, String>, index: Nat) -> Maybe<&2, String>:
  match locals:
    case Nil{}: None{}
    case +value <> rest:
      match index:
        case 0n: Some{value}
        case 1n+remaining: c_env_lookup(rest, remaining)

def c_field_expr(value: String, index: Nat) -> String:
  String.append("e.mem[term_peek(e, ", String.append(value, String.append(") + ", String.append(Nat.show(index), "]"))))

def c_pattern_fields_test(fields: List<&2, AST.SyntaxPattern>, value: String, index: Nat) -> Maybe<&2, String>:
  match fields:
    case Nil{}: Some{"1"}
    case +field <> rest:
      field_value = c_field_expr(value, index)
      c_pattern_fields_result(c_pattern_test(field, field_value), c_pattern_fields_test(rest, value, index + 1n))

def c_pattern_fields_result(one: Maybe<&2, String>, more: Maybe<&2, String>) -> Maybe<&2, String>:
  match one more:
    case Some{first} Some{rest}: c_pattern_fields_join(String.eq(rest, "1"), first, rest)
    case _ _: None{}

def c_pattern_fields_join(single: Bool, first: String, rest: String) -> Maybe<&2, String>:
  match single:
    case True{}: Some{first}
    case False{}: Some{String.append("(", String.append(first, String.append(" && ", String.append(rest, ")"))))}

def c_generic_pattern_test(key: String, fields: List<&2, AST.SyntaxPattern>, value: String) -> Maybe<&2, String>:
  c_generic_pattern_test_fields(c_pattern_fields_test(fields, value, 0n), key, value)

def c_generic_pattern_test_fields(found: Maybe<&2, String>, key: String, value: String) -> Maybe<&2, String>:
  match found:
    case Some{children}: c_generic_pattern_test_empty(String.eq(children, "1"), children, key, value)
    case None{}: None{}

def c_generic_pattern_test_empty(empty: Bool, children: String, key: String, value: String) -> Maybe<&2, String>:
  match empty:
    case True{}:
      Some{String.append("(term_tag(", String.append(value, String.append(") == TAG_CTR && term_aux(", String.append(value, String.append(") == ", String.append(cid_macro(key), ")"))))))}
    case False{}:
      Some{String.append("(term_tag(", String.append(value, String.append(") == TAG_CTR && term_aux(", String.append(value, String.append(") == ", String.append(cid_macro(key), String.append(" && ", String.append(children, ")"))))))))}

def c_pattern_test(pattern: AST.SyntaxPattern, value: String) -> Maybe<&2, String>:
  match pattern:
    case AST.PatternVar{_, _, _, _}: Some{"1"}
    case AST.PatternCtr{key, fields, _}:
      c_pattern_test_constructor(key_is(key, "False"), key_is(key, "True"), key_is(key, "Zero"), key_is(key, "Succ"), key, fields, value)

def c_pattern_test_constructor(is_false: Bool, is_true: Bool, is_zero: Bool, is_succ: Bool, key: String, fields: List<&2, AST.SyntaxPattern>, value: String) -> Maybe<&2, String>:
  match is_false is_true is_zero is_succ:
    case True{} _ _ _: c_pattern_test_nullary(fields, value, "0")
    case False{} True{} _ _: c_pattern_test_nullary(fields, value, "1")
    case False{} False{} True{} _: c_pattern_test_nullary(fields, value, "0")
    case False{} False{} False{} True{}: c_pattern_test_successor(fields, value)
    case _ _ _ _: c_generic_pattern_test(key, fields, value)

def c_pattern_test_nullary(fields: List<&2, AST.SyntaxPattern>, value: String, bit: String) -> Maybe<&2, String>:
  match fields:
    case Nil{}: Some{String.append("(", String.append(value, String.append(" == ", String.append(bit, ")"))))}
    case _: None{}

def c_pattern_test_successor(fields: List<&2, AST.SyntaxPattern>, value: String) -> Maybe<&2, String>:
  match fields:
    case +field <> Nil{}: c_pattern_test_successor_field(c_pattern_test(field, String.append("(", String.append(value, " - 1)"))), value)
    case _: None{}

def c_pattern_test_successor_field(found: Maybe<&2, String>, value: String) -> Maybe<&2, String>:
  match found:
    case Some{test}: Some{String.append("(", String.append(value, String.append(" > 0 && ", String.append(test, ")"))))}
    case None{}: None{}

def c_pattern_fields_open(fields: List<&2, AST.SyntaxPattern>, array: String, index: Nat, seed: Nat) -> PatternOpen:
  match fields:
    case Nil{}: PatternOpen{"", Nil{}, seed}
    case +field <> rest:
      field_value = String.append(array, String.append("[", String.append(Nat.show(index), "]")))
      c_pattern_fields_open_one(c_pattern_open(field, field_value, seed), rest, array, index, field_value)

def c_pattern_fields_open_one(one: PatternOpen, rest: List<&2, AST.SyntaxPattern>, array: String, index: Nat, field_value: String) -> PatternOpen:
  match one:
    case PatternOpen{source, values, next}:
      c_pattern_fields_open_rest(c_pattern_fields_open(rest, array, index + 1n, next), source, values)

def c_pattern_fields_open_rest(more: PatternOpen, source: String, values: List<&2, String>) -> PatternOpen:
  match more:
    case PatternOpen{after, after_values, last}: PatternOpen{String.append(source, after), List.append(&2, String, values, after_values), last}

def c_pattern_open(pattern: AST.SyntaxPattern, value: String, seed: Nat) -> PatternOpen:
  match pattern:
    case AST.PatternVar{ _,  _,  AST.QZero{},  _}:
      PatternOpen{ String.append("term_drop(e, ", String.append(value, "); ")),  ["0"],  seed}
    case AST.PatternVar{ _,  _,  _,  _}:
      captured = String.append("__bend_var", Nat.show(seed))
      PatternOpen{ String.concat(["Term ", captured, " = term_keep(e, ", value, "); "]),  [captured],  seed + 1n}
    case AST.PatternCtr{key, fields, _}:
      c_pattern_open_constructor(Bool.or(key_is(key, "False"), Bool.or(key_is(key, "True"), key_is(key, "Zero"))), key_is(key, "Succ"), key, fields, value, seed)

def c_pattern_open_constructor(is_nullary: Bool, is_succ: Bool, key: String, fields: List<&2, AST.SyntaxPattern>, value: String, seed: Nat) -> PatternOpen:
  match is_nullary:
    case True{}: PatternOpen{"", Nil{}, seed}
    case False{}: c_pattern_open_succ(is_succ, key, fields, value, seed)

def c_pattern_open_succ(is_succ: Bool, key: String, fields: List<&2, AST.SyntaxPattern>, value: String, seed: Nat) -> PatternOpen:
  match is_succ:
    case True{}: c_pattern_open_successor(fields, value, seed)
    case False{}: c_pattern_open_fields(fields, value, seed)

def c_pattern_open_successor(fields: List<&2, AST.SyntaxPattern>, value: String, seed: Nat) -> PatternOpen:
  match fields:
    case +field <> Nil{}: c_pattern_open(field, String.append("(", String.append(value, " - 1)")), seed)
    case _: PatternOpen{"", Nil{}, seed}

def c_pattern_open_fields(fields: List<&2, AST.SyntaxPattern>, value: String, seed: Nat) -> PatternOpen:
  match fields:
    case Nil{}: PatternOpen{"", Nil{}, seed}
    case _:
      count = List.length(&2, AST.SyntaxPattern, fields)
      array = String.append("__bend_fields", Nat.show(seed))
      take = String.append("Term ", String.append(array, String.append("[", String.append(Nat.show(count), String.append("]; spare_free(e, cls_fit(", String.append(Nat.show(count), String.append("), ctr_take(e, ", String.append(value, String.append(", ", String.append(Nat.show(count), String.append(", ", String.append(array, "))); "))))))))))))
      c_pattern_open_fields_result(c_pattern_fields_open(fields, array, 0n, seed + 1n), take)

def c_pattern_open_fields_result(children: PatternOpen, take: String) -> PatternOpen:
  match children:
    case PatternOpen{source, values, next}: PatternOpen{String.append(take, source), values, next}

def c_match_cases(cases: List<&2, AST.SyntaxTerm>, values: List<&2, String>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  match cases:
    case Nil{}: None{}
    case +term <> rest:
      match term:
        case AST.BodyCase{patterns, body, _}:
          c_match_case_patterns(c_pattern_test_list(patterns, values), c_pattern_open_list(patterns, values, 0n), body, rest, values, definitions, arity, locals)
        case _: c_match_cases(rest, values, definitions, arity, locals)

def c_match_case_patterns(test: Maybe<&2, String>, opened: Maybe<&2, PatternOpen>, body: AST.SyntaxTerm, rest: List<&2, AST.SyntaxTerm>, values: List<&2, String>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  match test opened:
    case Some{condition} Some{PatternOpen{open_source, names, _}}:
      branch_locals = List.append(&2, String, List.reverse(&2, String, names), locals)
      c_match_case_body(c_expr_env(body, definitions, arity, branch_locals), c_match_cases(rest, values, definitions, arity, locals), condition, open_source)
    case _ _: None{}

def c_match_case_body(branch: Maybe<&2, String>, remaining: Maybe<&2, String>, test: String, open_source: String) -> Maybe<&2, String>:
  match branch remaining:
    case Some{body} Some{tail}: Some{String.append("((", String.append(test, String.append(") ? ({ ", String.append(open_source, String.append(body, String.append("; }) : (", String.append(tail, "))")))))))}
    case Some{body} None{}: Some{String.append("((", String.append(test, String.append(") ? ({ ", String.append(open_source, String.append(body, "; }) : 0)")))))}
    case _ _: None{}

def c_constructor_stores(args: List<&2, AST.SyntaxTerm>, index: Nat, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  match args:
    case Nil{}: Some{""}
    case +arg <> rest:
      c_constructor_stores_pair(c_expr_env(arg, definitions, arity, locals), c_constructor_stores(rest, index + 1n, definitions, arity, locals), index)

def c_constructor_stores_pair(value: Maybe<&2, String>, more: Maybe<&2, String>, index: Nat) -> Maybe<&2, String>:
  match value more:
    case Some{source} Some{tail}:
      row = String.append("e.mem[__bend_loc + ", String.append(Nat.show(index), String.append("] = term_keep(e, ", String.append(source, "); "))))
      Some{String.append(row, tail)}
    case _ _: None{}

def c_constructor_expr(key: String, args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  match args:
    case Nil{}: Some{String.append("(((u64)TAG_CTR << 56) | ((u64)", String.append(cid_macro(key), " << 40))"))}
    case _:
      c_constructor_expr_stores(c_constructor_stores(args, 0n, definitions, arity, locals), key, args)

def c_constructor_expr_stores(found: Maybe<&2, String>, key: String, args: List<&2, AST.SyntaxTerm>) -> Maybe<&2, String>:
  match found:
    case Some{stores}:
      size = List.length(&2, AST.SyntaxTerm, args)
      Some{String.append("({ Loc __bend_loc = heap_alloc(e, cls_fit(", String.append(Nat.show(size), String.append(")); ", String.append(stores, String.append("(((u64)TAG_CTR << 56) | ((u64)", String.append(cid_macro(key), String.append(" << 40) | (u64)__bend_loc); })")))))))}
    case None{}: None{}

def c_char_literal(term: AST.SyntaxTerm) -> Maybe<&2, String>:
  match term:
    case AST.TermCtr{key, +value <> Nil{}, _}:
      c_char_literal_key(key_is(key, "Chr"), value)
    case _: None{}

def c_char_literal_key(is_char: Bool, value: AST.SyntaxTerm) -> Maybe<&2, String>:
  match is_char:
    case True{}: c_char_literal_value(u32_from_syntax(value, "U32"))
    case False{}: None{}

def c_char_literal_value(found: Maybe<&2, Nat>) -> Maybe<&2, String>:
  match found:
    case Some{code}: Some{String.append("(u32)", Nat.show(code))}
    case None{}: None{}

def c_word_literal(term: AST.SyntaxTerm, key: String) -> Maybe<&2, String>:
  c_word_literal_u32(key_is(key, "U32"), term, key)

def c_word_literal_u32(is_u32: Bool, term: AST.SyntaxTerm, key: String) -> Maybe<&2, String>:
  match is_u32:
    case True{}: c_word_literal_value(u32_from_syntax(term, "U32"))
    case False{}: c_word_literal_f32(key_is(key, "F32"), term)

def c_word_literal_f32(is_f32: Bool, term: AST.SyntaxTerm) -> Maybe<&2, String>:
  match is_f32:
    case True{}: c_word_literal_value(u32_from_syntax(term, "F32"))
    case False{}: c_char_literal(term)

def c_word_literal_value(found: Maybe<&2, Nat>) -> Maybe<&2, String>:
  match found:
    case Some{value}: Some{String.append("(u32)", Nat.show(value))}
    case None{}: None{}
def c_expr_env(term: AST.SyntaxTerm, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  match term:
    case AST.TermVar{ _, index,  _}:
      local_count = List.length(&2, String, locals)
      c_expr_var_locals(index < local_count, index, local_count, arity, locals)
    case AST.TermRef{key,  _}: c_definition_reference(key, definitions)
    case AST.TermAnn{term,  _,  _}: c_expr_env(term, definitions, arity, locals)
    case AST.TermTemplate{term,  _}: c_expr_env(term, definitions, arity, locals)
    case AST.TermLam{ Some{ AST.QZero{}},  _,  _, body,  _}: "0" <> locals
    case AST.TermLam{ _,  _,  _,  _, span}: Some{c_lambda_value(span, arity, locals)}
    case AST.TermSub{index, value, body,  _}: c_expr_env(Core.subst(index, value, body), definitions, arity, locals)
    case AST.TermLet{ _,  _,  _, values, body,  _}:
      c_expr_env(substitute_let_values(List.reverse(&2, AST.SyntaxTerm, values), body), definitions, arity, locals)
    case AST.TermCtr{key, args,  _}:
      c_expr_constructor(c_word_literal(term, key), key, args, definitions, arity, locals)
    case AST.TermString{chars, names, span}: c_expr_env(AST.string_desugar(chars, names, span), definitions, arity, locals)
    case AST.TermApp{ _,  _,  _}: c_expr_spine(app_spine(term), definitions, arity, locals)
    case AST.BodyReply{term,  _}: c_expr_env(term, definitions, arity, locals)
    case AST.BodyMatch{scrutinees, cases,  _}:
      match scrutinees:
        case +_ <> _:
          values = c_match_scrutinee_names(List.length(&2, AST.SyntaxTerm, scrutinees), 0n)
          c_expr_match_pair(c_match_scrutinee_source(scrutinees, definitions, arity, locals, 0n), c_match_cases(cases, values, definitions, arity, locals))
        case _: None{}
    case AST.BodyLocal{patterns,  _, values, body, span}:
      c_expr_env(AST.BodyMatch{ values,  [AST.BodyCase{patterns, body, span}], span}, definitions, arity, locals)
    case AST.TermMat{ _, head, matched, span}:
      c_expr_env(AST.TermApp{ head,  matched, span}, definitions, arity, locals)
    case AST.TermRewrite{ _,  _, body,  _}: c_expr_env(body, definitions, arity, locals)
    case _: None{}

def c_expr_var_locals(local: Bool, index: Nat, local_count: Nat, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  match local:
    case True{}: c_env_lookup(locals, index)
    case False{}: c_expr_var_parameter(index - local_count < arity, index, local_count, arity)

def c_expr_var_parameter(parameter: Bool, index: Nat, local_count: Nat, arity: Nat) -> Maybe<&2, String>:
  match parameter:
    case True{}: Some{String.append("a", Nat.show(arity - (index - local_count) - 1n))}
    case False{}: None{}

def c_expr_constructor(word: Maybe<&2, String>, key: String, args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  match word:
    case Some{value}: Some{value}
    case None{}: c_expr_constructor_zero(Bool.or(key_is(key, "False"), key_is(key, "Zero")), key, args, definitions, arity, locals)

def c_expr_constructor_zero(is_zero: Bool, key: String, args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  match is_zero:
    case True{}: Some{"0"}
    case False{}: c_expr_constructor_true(key_is(key, "True"), key, args, definitions, arity, locals)

def c_expr_constructor_true(is_true: Bool, key: String, args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  match is_true:
    case True{}: Some{"1"}
    case False{}: c_expr_constructor_succ(key_is(key, "Succ"), key, args, definitions, arity, locals)

def c_expr_constructor_succ(is_succ: Bool, key: String, args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  match is_succ:
    case True{}: c_expr_successor(args, definitions, arity, locals)
    case False{}: c_constructor_expr(key, args, definitions, arity, locals)

def c_expr_successor(args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  match args:
    case +item <> Nil{}: c_expr_successor_value(c_expr_env(item, definitions, arity, locals))
    case _: None{}

def c_expr_successor_value(found: Maybe<&2, String>) -> Maybe<&2, String>:
  match found:
    case Some{value}: Some{String.append("nat_chk(e, ", String.append(value, " + 1)"))}
    case None{}: None{}

def c_expr_match_pair(source: Maybe<&2, String>, result: Maybe<&2, String>) -> Maybe<&2, String>:
  match source result:
    case Some{scrutinee_source} Some{body}: Some{String.concat(["({ ", scrutinee_source, body, "; })"])}
    case _ _: None{}

def c_expr_spine(spine: AppSpine, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  match spine:
    case AppSpine{AST.TermLam{_, _, _, body, span}, args}: c_beta_apply(body, args, span, definitions, arity, locals)
    case AppSpine{AST.TermRef{key, _}, args}: c_expr_reference_call(c_native_call(key, args, definitions, arity, locals), key, args, definitions, arity, locals)
    case AppSpine{AST.TermVar{key, index, span}, args}:
      c_expr_variable_call(c_expr_env(AST.TermVar{key, index, span}, definitions, arity, locals), c_argument_values(args, definitions, arity, locals), args, definitions)
    case _: None{}

def c_expr_variable_call(closure: Maybe<&2, String>, values: Maybe<&2, String>, args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>) -> Maybe<&2, String>:
  match closure values:
    case Some{fn} Some{arguments}: Some{c_indirect_call(fn, arguments, List.length(&2, AST.SyntaxTerm, args), definitions)}
    case _ _: None{}

def c_expr_reference_call(native: Maybe<&2, String>, key: String, args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  match native:
    case Some{value}: Some{value}
    case None{}: c_expr_reference_definition(find_definition(key, definitions), args, definitions, arity, locals)

def c_expr_reference_definition(found: Maybe<&2, IndexedDefinition>, args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  match found:
    case Some{IndexedDefinition{_, _, full_key, binders, _, AST.DefTerm{_}, _, _}}:
      c_expr_definition_call(c_live_arguments(binders, args, definitions, arity, locals), full_key, c_live_binder_count(binders), definitions, arity, locals)
    case Some{IndexedDefinition{_, _, full_key, binders, _, AST.DefImports{_}, _, _}}:
      c_expr_import_call(c_live_arguments(binders, args, definitions, arity, locals), full_key, c_live_binder_count(binders), definitions, arity, locals)
    case None{}: None{}

def c_expr_definition_call(args: List<&2, AST.SyntaxTerm>, full_key: String, call_arity: Nat, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  arg_count = List.length(&2, AST.SyntaxTerm, args)
  c_expr_definition_call_size(Nat.is_eq(call_arity, arg_count), arg_count < call_arity, args, full_key, call_arity, definitions, arity, locals)

def c_expr_definition_call_size(exact: Bool, under: Bool, args: List<&2, AST.SyntaxTerm>, full_key: String, call_arity: Nat, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  match exact:
    case True{}: c_expr_definition_values(c_argument_values(args, definitions, arity, locals), full_key)
    case False{}: c_expr_definition_call_under(under, args, full_key, call_arity, definitions, arity, locals)

def c_expr_definition_values(values: Maybe<&2, String>, full_key: String) -> Maybe<&2, String>:
  match values:
    case Some{source}: Some{String.append(c_fn_name(full_key), String.append("(e", String.append(c_call_separator(source), ")")))}
    case None{}: None{}

def c_expr_definition_call_under(under: Bool, args: List<&2, AST.SyntaxTerm>, full_key: String, call_arity: Nat, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  match under:
    case True{}: c_expr_closure_values(c_argument_values(args, definitions, arity, locals), full_key, List.length(&2, AST.SyntaxTerm, args))
    case False{}: c_expr_overapplied_call(full_key, call_arity, args, definitions, arity, locals)

def c_expr_closure_values(values: Maybe<&2, String>, full_key: String, arg_count: Nat) -> Maybe<&2, String>:
  match values:
    case Some{source}: Some{String.append("bend_closure_make(e, ", String.append(fid_macro(full_key), String.append(", ", String.append(Nat.show(arg_count), String.append(", (Term[]){", String.append(source, "})"))))))}
    case None{}: None{}

def c_expr_import_call(args: List<&2, AST.SyntaxTerm>, full_key: String, call_arity: Nat, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  c_expr_import_call_size(Nat.is_eq(call_arity, List.length(&2, AST.SyntaxTerm, args)), args, full_key, definitions, arity, locals)

def c_expr_import_call_size(exact: Bool, args: List<&2, AST.SyntaxTerm>, full_key: String, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>) -> Maybe<&2, String>:
  match exact:
    case True{}: c_expr_closure_values(c_argument_values(args, definitions, arity, locals), full_key, List.length(&2, AST.SyntaxTerm, args))
    case False{}: None{}

def c_expr(term: AST.SyntaxTerm, definitions: List<&2, IndexedDefinition>, arity: Nat) -> Maybe<&2, String>:
  c_expr_env(term, definitions, arity, Nil{})
def c_definition_supported(definition: IndexedDefinition, definitions: List<&2, IndexedDefinition>) -> Bool:
  match definition:
    case IndexedDefinition{ _,  _,  _, binders,  _, body,  _,  _}:
      match body:
        case AST.DefTerm{term}:
          c_definition_supported_term(binder_count(binders) > 1000000n, term, definition, binders, definitions)
        case _: False{}

def c_definition_supported_term(too_many: Bool, term: AST.SyntaxTerm, definition: IndexedDefinition, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>) -> Bool:
  match too_many:
    case True{}: False{}
    case False{}: c_definition_supported_expression(c_expr_env(term, definitions, 0n, c_binder_env(binders, 0n)), term, definition, binders, definitions)

def c_definition_supported_expression(expr: Maybe<&2, String>, term: AST.SyntaxTerm, definition: IndexedDefinition, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>) -> Bool:
  match expr:
    case Some{_}: True{}
    case None{}: c_definition_supported_bang_call(c_bang_call(term), term, definition, binders, definitions)

def c_definition_supported_bang_call(bang: Maybe<&2, BangCall>, term: AST.SyntaxTerm, definition: IndexedDefinition, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>) -> Bool:
  match bang:
    case Some{BangCall{key, args}}: c_bang_supported(key, args, binders, definitions)
    case None{}: c_definition_supported_split(c_split_bang(term), definition, binders, definitions)

def c_definition_supported_split(split: Maybe<&2, BangSplit>, definition: IndexedDefinition, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>) -> Bool:
  match split:
    case Some{BangSplit{key, args, captures, _}}: Bool.and(c_bang_supported(key, args, binders, definitions), c_capture_terms_supported(captures, definitions, 0n, c_binder_env(binders, 0n)))
    case None{}: c_match_definition_supported(definition, definitions)

def supported_definitions(definitions: List<&2, IndexedDefinition>) -> List<&2, IndexedDefinition>:
  match definitions:
    case Nil{}: Nil{}
    case +definition <> rest:
      supported_definitions_one(c_definition_supported(definition, definitions), definition, rest)

def supported_definitions_one(supported: Bool, definition: IndexedDefinition, rest: List<&2, IndexedDefinition>) -> List<&2, IndexedDefinition>:
  match supported:
    case True{}: definition <> supported_definitions(rest)
    case False{}: supported_definitions(rest)

def c_parameter_names(count: Nat, index: Nat) -> String:
  match count:
    case 0n: ""
    case 1n+remaining:
      String.append("Term a", String.append(Nat.show(index), c_call_separator(c_parameter_names(remaining, index + 1n))))

def c_parameter_declarations(count: Nat, index: Nat) -> String:
  String.append("Env e", c_call_separator(c_parameter_names(count, index)))

def c_argument_registers(count: Nat, index: Nat) -> String:
  match count:
    case 0n: ""
    case 1n+remaining:
      String.append("r", String.append(Nat.show(index), c_call_separator(c_argument_registers(remaining, index + 1n))))

def c_foreign_helper_store(count: Nat, index: Nat) -> String:
  match count:
    case 0n: ""
    case 1n+remaining:
      String.concat(["    e.mem[__bend_req + ", Nat.show(index), "] = a", Nat.show(index), ";\n", c_foreign_helper_store(remaining, index + 1n)])

def c_helper_prototypes(definitions: List<&2, IndexedDefinition>) -> String:
  match definitions:
    case Nil{}: ""
    case +definition <> rest:
      match definition:
        case IndexedDefinition{ _,  _, full_key, binders,  _,  AST.DefImports{ _},  _,  _}:
          arity = c_live_binder_count(binders) + 1n
          String.append("static Term ", String.append(c_fn_name(full_key), String.append("(", String.append(c_parameter_declarations(arity, 0n), String.append(");\n", c_helper_prototypes(rest))))))
        case IndexedDefinition{ _,  _, full_key, binders,  _,  _,  _,  _}:
          String.append("static Term ", String.append(c_fn_name(full_key), String.append("(", String.append(c_parameter_declarations(c_live_binder_count(binders), 0n), String.append(");\n", c_helper_prototypes(rest))))))

def c_helper_bodies(definitions: List<&2, IndexedDefinition>, all_definitions: List<&2, IndexedDefinition>) -> String:
  match definitions:
    case Nil{}: ""
    case +definition <> rest:
      match definition:
        case IndexedDefinition{_, _, full_key, binders, _, AST.DefImports{_}, _, _}:
          arity = c_live_binder_count(binders) + 1n
          stores = c_foreign_helper_store(arity, 0n)
          String.concat(["static Term ", c_fn_name(full_key), "(", c_parameter_declarations(arity, 0n), ") {\n  Loc __bend_req = heap_alloc(e, cls_fit(", Nat.show(arity), "));\n", stores, "  return (((u64)TAG_CTR << 56) | ((u64)", cid_macro(full_key), " << 40) | (u64)__bend_req);\n}\n", c_helper_bodies(rest, all_definitions)])
        case IndexedDefinition{_, key, full_key, binders, _, AST.DefTerm{AST.TermLam{quantity, lambda_key, index, lambda_body, span}}, _, _}:
          c_helper_lambda(String.starts_with(key, "__lambda_"), full_key, binders, quantity, lambda_key, index, lambda_body, span, rest, all_definitions)
        case IndexedDefinition{_, _, full_key, binders, _, AST.DefTerm{term}, _, _}:
          c_helper_term(c_expr_env(term, all_definitions, 0n, c_binder_env(binders, 0n)), full_key, c_live_binder_count(binders), rest, all_definitions)
        case _: c_helper_bodies(rest, all_definitions)

def c_helper_lambda(is_lambda: Bool, full_key: String, binders: List<&2, AST.TelescopeItem>, quantity: AST.Quantity, lambda_key: String, index: Nat, lambda_body: AST.SyntaxTerm, span: AST.SourceSpan, rest: List<&2, IndexedDefinition>, all_definitions: List<&2, IndexedDefinition>) -> String:
  match is_lambda:
    case True{}: c_helper_lambda_body(c_expr_env(lambda_body, all_definitions, binder_count(binders), Nil{}), full_key, binder_count(binders), rest, all_definitions)
    case False{}:
      term = AST.TermLam{quantity, lambda_key, index, lambda_body, span}
      c_helper_term(c_expr_env(term, all_definitions, 0n, c_binder_env(binders, 0n)), full_key, c_live_binder_count(binders), rest, all_definitions)

def c_helper_lambda_body(found: Maybe<&2, String>, full_key: String, arity: Nat, rest: List<&2, IndexedDefinition>, all_definitions: List<&2, IndexedDefinition>) -> String:
  c_helper_body_result(found, full_key, arity, rest, all_definitions)

def c_helper_term(found: Maybe<&2, String>, full_key: String, arity: Nat, rest: List<&2, IndexedDefinition>, all_definitions: List<&2, IndexedDefinition>) -> String:
  c_helper_body_result(found, full_key, arity, rest, all_definitions)

def c_helper_body_result(found: Maybe<&2, String>, full_key: String, arity: Nat, rest: List<&2, IndexedDefinition>, all_definitions: List<&2, IndexedDefinition>) -> String:
  match found:
    case Some{value}: String.append("static Term ", String.append(c_fn_name(full_key), String.append("(", String.append(c_parameter_declarations(arity, 0n), String.append(") { return ", String.append(value, String.append("; }\n", c_helper_bodies(rest, all_definitions))))))))
    case None{}: c_helper_bodies(rest, all_definitions)

def c_helper_source(definitions: List<&2, IndexedDefinition>) -> String:
  String.concat([
    "static Nat nat_chk(Env e, Nat n);\nstatic Nat nat_mul(Env e, Nat a, Nat b);\nstatic void err_post(Corpus H, Err code);\nstatic Cls cls_fit(u32 words);\nstatic Loc heap_alloc(Env e, Cls cls);\nstatic Loc term_peek(Env e, Term t);\nstatic Term term_keep(Env e, Term t);\nstatic void term_drop(Env e, Term t);\nstatic Loc ctr_take(Env e, Term t, u32 n, THR Term* out);\nstatic void spare_free(Env e, Cls cls, Loc loc);\nstatic u64 term_tag(Term t);\nstatic u64 term_aux(Term t);\nstatic Term bend_closure_make(Env e, Fid fid, u32 n, THR Term* values);\n",
    "static Term bend_closure_make(Env e, Fid fid, u32 n, THR Term* values) { Loc loc = 0; if (n != 0) { loc = heap_alloc(e, cls_fit(n)); for (u32 i = 0; i < n; i += 1) e.mem[loc + i] = term_keep(e, values[i]); } return ((u64)TAG_CLO << 56) | ((u64)fid << 40) | (u64)loc; }\n",
    c_helper_prototypes(definitions),
    c_helper_bodies(definitions, definitions)
  ])

def c_fid_definitions(definitions: List<&2, IndexedDefinition>, index: Nat) -> String:
  match definitions:
    case Nil{}: ""
    case +definition <> rest:
      match definition:
        case IndexedDefinition{ _,  _, full_key,  _,  _,  _,  _,  _}:
          String.append("#define ", String.append(fid_macro(full_key), String.append(" ", String.append(Nat.show(index), String.append("\n", c_fid_definitions(rest, index + 1n))))))

def c_definition_arity(definition: IndexedDefinition) -> Nat:
  match definition:
    case IndexedDefinition{ _,  _,  _, binders,  _,  AST.DefImports{ _},  _,  _}: c_live_binder_count(binders) + 1n
    case IndexedDefinition{ _,  _,  _, binders,  _,  _,  _,  _}: c_live_binder_count(binders)

def c_foreign_segment(full_key: String, arity: Nat) -> String:
  stores = c_foreign_store(arity, 0n)
  String.concat(["  WL_CASE(", fid_macro(full_key), ")\n  {\n    WL_OPEN\n    Loc __bend_req = heap_alloc(e, cls_fit(", Nat.show(arity), "));\n", stores, "    r0 = term_ctr(", cid_macro(full_key), ", __bend_req);\n    WL_RETN(1);\n  }}\n"])

def c_foreign_store(count: Nat, index: Nat) -> String:
  match count:
    case 0n: ""
    case 1n+remaining:
      String.concat(["    e.mem[__bend_req + ", Nat.show(index), "] = r", Nat.show(index), ";\n", c_foreign_store(remaining, index + 1n)])

def c_function_arities(definitions: List<&2, IndexedDefinition>) -> List<&2, Nat>:
  match definitions:
    case Nil{}: Nil{}
    case +definition <> rest: c_definition_arity(definition) <> c_function_arities(rest)
def c_string_member(key: String, keys: List<&2, String>) -> Bool:
  match keys:
    case Nil{}: False{}
    case +one <> rest: c_string_member_result(String.eq(key, one), key, rest)

def c_string_member_result(same: Bool, key: String, rest: List<&2, String>) -> Bool:
  match same:
    case True{}: True{}
    case False{}: c_string_member(key, rest)

def c_add_bang_key(key: String, definitions: List<&2, IndexedDefinition>, keys: List<&2, String>) -> List<&2, String>:
  c_add_bang_key_definition(find_definition(key, definitions), keys)

def c_add_bang_key_definition(found: Maybe<&2, IndexedDefinition>, keys: List<&2, String>) -> List<&2, String>:
  match found:
    case Some{IndexedDefinition{_, _, full_key, _, _, _, _, _}}:
      c_add_bang_key_member(c_string_member(full_key, keys), full_key, keys)
    case None{}: keys

def c_add_bang_key_member(member: Bool, full_key: String, keys: List<&2, String>) -> List<&2, String>:
  match member:
    case True{}: keys
    case False{}: full_key <> keys

def c_match_bang_keys(cases: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, keys: List<&2, String>) -> List<&2, String>:
  match cases:
    case Nil{}: keys
    case +one <> rest:
      next_keys = c_match_bang_keys_one(one, definitions, keys)
      c_match_bang_keys(rest, definitions, next_keys)

def c_match_bang_keys_one(one: AST.SyntaxTerm, definitions: List<&2, IndexedDefinition>, keys: List<&2, String>) -> List<&2, String>:
  match one:
    case AST.BodyCase{_, body, _}: c_match_bang_keys_split(c_split_bang(body), definitions, keys)
    case _: keys

def c_match_bang_keys_split(found: Maybe<&2, BangSplit>, definitions: List<&2, IndexedDefinition>, keys: List<&2, String>) -> List<&2, String>:
  match found:
    case Some{BangSplit{key, _, _, _}}: c_add_bang_key(key, definitions, keys)
    case None{}: keys

def c_bang_keys(definitions: List<&2, IndexedDefinition>, keys: List<&2, String>) -> List<&2, String>:
  match definitions:
    case Nil{}: keys
    case +definition <> rest:
      match definition:
        case IndexedDefinition{_, _, _, _, _, AST.DefTerm{term}, _, _}:
          match term:
            case AST.BodyMatch{_, cases, _}: c_bang_keys(rest, c_match_bang_keys(cases, definitions, keys))
            case _: c_bang_keys_definition_split(c_definition_bang_split(definition), rest, definitions, keys)
        case _: c_bang_keys(rest, keys)

def c_bang_keys_definition_split(found: Maybe<&2, BangSplit>, rest: List<&2, IndexedDefinition>, definitions: List<&2, IndexedDefinition>, keys: List<&2, String>) -> List<&2, String>:
  match found:
    case Some{BangSplit{key, _, _, _}}: c_bang_keys(rest, c_add_bang_key(key, definitions, keys))
    case None{}: c_bang_keys(rest, keys)

def c_fid_flag_values(definitions: List<&2, IndexedDefinition>, bang_keys: List<&2, String>) -> List<&2, Nat>:
  match definitions:
    case Nil{}: Nil{}
    case +definition <> rest:
      match definition:
        case IndexedDefinition{_, _, full_key, _, _, _, _, _}:
          c_fid_flag_value(c_string_member(full_key, bang_keys)) <> c_fid_flag_values(rest, bang_keys)

def c_fid_flag_value(is_bang: Bool) -> Nat:
  match is_bang:
    case True{}: 3n
    case False{}: 2n

def c_fid_resw_values(definitions: List<&2, IndexedDefinition>) -> List<&2, Nat>:
  match definitions:
    case Nil{}: Nil{}
    case +definition <> rest:
      match definition:
        case IndexedDefinition{_, _, full_key, _, _, _, _, _}:
          c_fid_resw_value(String.contains(full_key, "__cemit_k")) <> c_fid_resw_values(rest)

def c_fid_resw_value(is_continuation: Bool) -> Nat:
  match is_continuation:
    case True{}: 1n
    case False{}: 0n



def c_segment_regular(full_key: String, binders: List<&2, AST.TelescopeItem>) -> String:
  arity = c_live_binder_count(binders)
  args = c_argument_registers(arity, 0n)
  call = String.append(c_fn_name(full_key), String.append("(e", String.append(c_call_separator(args), ")")))
  String.append("  WL_CASE(", String.append(fid_macro(full_key), String.append(")\n  {\n    WL_OPEN\n    r0 = ", String.append(call, ";\n    WL_RETN(1);\n  }}\n"))))

def c_segments(definitions: List<&2, IndexedDefinition>) -> String:
  match definitions:
    case Nil{}: ""
    case +definition <> rest:
      match definition:
        case IndexedDefinition{_, _, full_key, binders, _, AST.DefImports{_}, _, _}:
          String.append(c_foreign_segment(full_key, c_live_binder_count(binders) + 1n), c_segments(rest))
        case IndexedDefinition{_, _, full_key, binders, _, AST.DefTerm{term}, _, _}:
          c_segments_term(c_match_bang_segment(definition, definitions), full_key, binders, term, definition, definitions, rest)
        case _: c_segments(rest)

def c_segments_term(match_segment: Maybe<&2, String>, full_key: String, binders: List<&2, AST.TelescopeItem>, term: AST.SyntaxTerm, definition: IndexedDefinition, definitions: List<&2, IndexedDefinition>, rest: List<&2, IndexedDefinition>) -> String:
  match match_segment:
    case Some{segment}: String.append(segment, c_segments(rest))
    case None{}: c_segments_bang_call(c_bang_call(term), full_key, binders, term, definition, definitions, rest)

def c_segments_bang_call(found: Maybe<&2, BangCall>, full_key: String, binders: List<&2, AST.TelescopeItem>, term: AST.SyntaxTerm, definition: IndexedDefinition, definitions: List<&2, IndexedDefinition>, rest: List<&2, IndexedDefinition>) -> String:
  match found:
    case Some{bang}: c_segments_direct_bang(c_bang_segment(full_key, bang, binders, definitions), full_key, binders, rest)
    case None{}: c_segments_split(c_definition_bang_split(definition), full_key, binders, definitions, rest)

def c_segments_direct_bang(found: Maybe<&2, String>, full_key: String, binders: List<&2, AST.TelescopeItem>, rest: List<&2, IndexedDefinition>) -> String:
  match found:
    case Some{segment}: String.append(segment, c_segments(rest))
    case None{}: String.append(c_segment_regular(full_key, binders), c_segments(rest))

def c_segments_split(found: Maybe<&2, BangSplit>, full_key: String, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>, rest: List<&2, IndexedDefinition>) -> String:
  match found:
    case Some{BangSplit{key, args, captures, _}}:
      c_segments_split_segment(c_bang_segment_to(full_key, c_bang_continuation_key(full_key), BangCall{key, args}, captures, binders, definitions, True{}), full_key, binders, rest)
    case None{}: String.append(c_segment_regular(full_key, binders), c_segments(rest))

def c_segments_split_segment(found: Maybe<&2, String>, full_key: String, binders: List<&2, AST.TelescopeItem>, rest: List<&2, IndexedDefinition>) -> String:
  match found:
    case Some{segment}: String.append(segment, c_segments(rest))
    case None{}: String.append(c_segment_regular(full_key, binders), c_segments(rest))
def c_pattern_test_list(patterns: List<&2, AST.SyntaxPattern>, values: List<&2, String>) -> Maybe<&2, String>:
  match patterns values:
    case Nil{} Nil{}: Some{"1"}
    case +pattern <> rest_patterns +value <> rest_values:
      c_pattern_test_list_pair(c_pattern_test(pattern, value), c_pattern_test_list(rest_patterns, rest_values))
    case _ _: None{}

def c_pattern_test_list_pair(test: Maybe<&2, String>, rest: Maybe<&2, String>) -> Maybe<&2, String>:
  match test rest:
    case Some{condition} Some{tail}: Some{String.concat(["(", condition, " && ", tail, ")"])}
    case _ _: None{}

def c_pattern_open_list(patterns: List<&2, AST.SyntaxPattern>, values: List<&2, String>, seed: Nat) -> Maybe<&2, PatternOpen>:
  match patterns values:
    case Nil{} Nil{}: Some{PatternOpen{"", Nil{}, seed}}
    case +pattern <> rest_patterns +value <> rest_values:
      c_pattern_open_list_first(c_pattern_open(pattern, value, seed), rest_patterns, rest_values)
    case _ _: None{}

def c_pattern_open_list_first(first: PatternOpen, rest_patterns: List<&2, AST.SyntaxPattern>, rest_values: List<&2, String>) -> Maybe<&2, PatternOpen>:
  match first:
    case PatternOpen{first_source, first_values, next_seed}:
      c_pattern_open_list_rest(c_pattern_open_list(rest_patterns, rest_values, next_seed), first_source, first_values)

def c_pattern_open_list_rest(found: Maybe<&2, PatternOpen>, first_source: String, first_values: List<&2, String>) -> Maybe<&2, PatternOpen>:
  match found:
    case Some{PatternOpen{rest_source, rest_values, next}}:
      Some{PatternOpen{String.append(first_source, rest_source), List.append(&2, String, first_values, rest_values), next}}
    case None{}: None{}

def c_match_scrutinee_names(count: Nat, index: Nat) -> List<&2, String>:
  match count:
    case 0n: Nil{}
    case 1n+rest: String.concat(["__bend_scrut", Nat.show(index)]) <> c_match_scrutinee_names(rest, index + 1n)

def c_match_scrutinee_source(scrutinees: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, arity: Nat, locals: List<&2, String>, index: Nat) -> Maybe<&2, String>:
  match scrutinees:
    case Nil{}: Some{""}
    case +scrutinee <> rest:
      c_match_scrutinee_pair(c_expr_env(scrutinee, definitions, arity, locals), c_match_scrutinee_source(rest, definitions, arity, locals, index + 1n), index)

def c_match_scrutinee_pair(value: Maybe<&2, String>, tail: Maybe<&2, String>, index: Nat) -> Maybe<&2, String>:
  match value tail:
    case Some{source} Some{rest}: Some{String.concat(["    Term __bend_scrut", Nat.show(index), " = term_keep(e, ", source, ");\n", rest])}
    case _ _: None{}

def c_match_case_segment(cases: List<&2, AST.SyntaxTerm>, values: List<&2, String>, current_key: String, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>, index: Nat) -> Maybe<&2, String>:
  match cases:
    case Nil{}: Some{"err_post(e.mem, ERR_TAGS); return 0;\n"}
    case +one <> rest:
      match one:
        case AST.BodyCase{patterns, body, _}:
          c_match_case_segment_patterns(c_pattern_test_list(patterns, values), c_pattern_open_list(patterns, values, index), patterns, body, rest, values, current_key, binders, definitions, index)
        case _: c_match_case_segment(rest, values, current_key, binders, definitions, index + 1n)

def c_match_case_segment_patterns(test: Maybe<&2, String>, opened: Maybe<&2, PatternOpen>, patterns: List<&2, AST.SyntaxPattern>, body: AST.SyntaxTerm, rest: List<&2, AST.SyntaxTerm>, values: List<&2, String>, current_key: String, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>, index: Nat) -> Maybe<&2, String>:
  match test opened:
    case Some{condition} Some{PatternOpen{open_source, names, _}}:
      pattern_binders = c_pattern_binders(patterns)
      branch_locals = List.append(&2, String, List.reverse(&2, String, names), c_segment_binder_env(binders, 0n))
      branch_captures = List.append(&2, String, c_register_value_list(c_live_binder_count(binders), 0n), c_pattern_live_values(pattern_binders, names))
      c_match_case_segment_branch(c_split_bang(body), body, rest, values, current_key, binders, definitions, index, condition, open_source, branch_locals, branch_captures)
    case _ _: c_match_case_segment(rest, values, current_key, binders, definitions, index + 1n)

def c_pattern_binders_from_names(names: List<&2, String>, values: List<&2, String>) -> List<&2, AST.TelescopeItem>:
  c_pattern_binders_from_count(List.length(&2, String, names), values)

def c_pattern_binders_from_count(count: Nat, values: List<&2, String>) -> List<&2, AST.TelescopeItem>:
  c_pattern_binders_from_values(values, count)

def c_pattern_binders_from_values(values: List<&2, String>, count: Nat) -> List<&2, AST.TelescopeItem>:
  c_pattern_binders(c_pattern_dummy_patterns(count))

def c_match_case_segment_branch(split: Maybe<&2, BangSplit>, body: AST.SyntaxTerm, rest: List<&2, AST.SyntaxTerm>, values: List<&2, String>, current_key: String, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>, index: Nat, condition: String, open_source: String, branch_locals: List<&2, String>, branch_captures: List<&2, String>) -> Maybe<&2, String>:
  match split:
    case Some{BangSplit{key, args, captures, _}}:
      c_match_case_segment_captures(c_capture_expression_values(captures, definitions, 0n, branch_locals), key, args, rest, values, current_key, binders, definitions, index, condition, open_source, branch_locals, branch_captures)
    case None{}:
      c_match_case_segment_body(c_expr_env(body, definitions, 0n, branch_locals), rest, values, current_key, binders, definitions, index, condition, open_source)

def c_match_case_segment_captures(found: Maybe<&2, String>, key: String, args: List<&2, AST.SyntaxTerm>, rest: List<&2, AST.SyntaxTerm>, values: List<&2, String>, current_key: String, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>, index: Nat, condition: String, open_source: String, branch_locals: List<&2, String>, branch_captures: List<&2, String>) -> Maybe<&2, String>:
  match found:
    case Some{prefix_values}:
      c_match_case_segment_join(c_bang_segment_context(current_key, c_match_continuation_key(current_key, index), BangCall{key, args}, 0n, branch_locals, prefix_values, branch_captures, definitions, False{}), c_match_case_segment(rest, values, current_key, binders, definitions, index + 1n), condition, open_source)
    case None{}: None{}

def c_match_case_segment_body(found: Maybe<&2, String>, rest: List<&2, AST.SyntaxTerm>, values: List<&2, String>, current_key: String, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>, index: Nat, condition: String, open_source: String) -> Maybe<&2, String>:
  match found:
    case Some{expr}:
      c_match_case_segment_join(Some{String.concat(["r0 = ", expr, "; WL_RETN(1);\n"])}, c_match_case_segment(rest, values, current_key, binders, definitions, index + 1n), condition, open_source)
    case None{}: None{}

def c_match_case_segment_join(branch: Maybe<&2, String>, remaining: Maybe<&2, String>, condition: String, open_source: String) -> Maybe<&2, String>:
  match branch remaining:
    case Some{body} Some{tail}: Some{String.concat(["if (", condition, ") {\n", open_source, body, "} else {\n", tail, "}\n"])}
    case Some{body} None{}: Some{String.concat(["if (", condition, ") {\n", open_source, body, "}\n"])}
    case _ _: None{}

def c_match_bang_segment(definition: IndexedDefinition, definitions: List<&2, IndexedDefinition>) -> Maybe<&2, String>:
  match definition:
    case IndexedDefinition{_, _, full_key, binders, _, _, _, _}:
      c_match_bang_segment_definition(c_definition_match_term(definition), full_key, binders, definitions)

def c_match_bang_segment_definition(found: Maybe<&2, AST.SyntaxTerm>, full_key: String, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>) -> Maybe<&2, String>:
  match found:
    case Some{AST.BodyMatch{+first_scrutinee <> rest_scrutinees, cases, _}}:
      c_match_bang_segment_has_bang(c_match_has_bang(cases), first_scrutinee <> rest_scrutinees, cases, full_key, binders, definitions)
    case _: None{}

def c_match_bang_segment_has_bang(has_bang: Bool, scrutinees: List<&2, AST.SyntaxTerm>, cases: List<&2, AST.SyntaxTerm>, full_key: String, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>) -> Maybe<&2, String>:
  match has_bang:
    case False{}: None{}
    case True{}:
      locals = c_segment_binder_env(binders, 0n)
      values = c_match_scrutinee_names(List.length(&2, AST.SyntaxTerm, scrutinees), 0n)
      c_match_bang_segment_source(c_match_scrutinee_source(scrutinees, definitions, 0n, locals, 0n), c_match_case_segment(cases, values, full_key, binders, definitions, 0n), full_key)

def c_match_bang_segment_source(source: Maybe<&2, String>, cases: Maybe<&2, String>, full_key: String) -> Maybe<&2, String>:
  match source cases:
    case Some{scrutinee_source} Some{case_source}:
      Some{String.concat(["  WL_CASE(", fid_macro(full_key), ")\n  {\n    WL_OPEN\n", scrutinee_source, case_source, "  }}\n"])}
    case _ _: None{}

def c_match_has_bang(cases: List<&2, AST.SyntaxTerm>) -> Bool:
  match cases:
    case Nil{}: False{}
    case +one <> rest:
      match one:
        case AST.BodyCase{_, body, _}: c_match_has_bang_split(c_split_bang(body), rest)
        case _: c_match_has_bang(rest)

def c_match_has_bang_split(found: Maybe<&2, BangSplit>, rest: List<&2, AST.SyntaxTerm>) -> Bool:
  match found:
    case Some{_}: True{}
    case None{}: c_match_has_bang(rest)

def c_pattern_dummy_values(patterns: List<&2, AST.SyntaxPattern>) -> List<&2, String>:
  match patterns:
    case Nil{}: Nil{}
    case +_ <> rest: "0" <> c_pattern_dummy_values(rest)

def c_match_cases_supported(cases: List<&2, AST.SyntaxTerm>, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>) -> Bool:
  match cases:
    case Nil{}: True{}
    case +one <> rest:
      match one:
        case AST.BodyCase{patterns, body, _}:
          c_match_cases_supported_patterns(c_pattern_test_list(patterns, c_pattern_dummy_values(patterns)), c_pattern_open_list(patterns, c_pattern_dummy_values(patterns), 0n), patterns, body, rest, binders, definitions)
        case _: False{}

def c_match_cases_supported_patterns(test: Maybe<&2, String>, opened: Maybe<&2, PatternOpen>, patterns: List<&2, AST.SyntaxPattern>, body: AST.SyntaxTerm, rest: List<&2, AST.SyntaxTerm>, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>) -> Bool:
  match test opened:
    case Some{_} Some{PatternOpen{_, values, _}}:
      locals = List.append(&2, String, List.reverse(&2, String, values), c_binder_env(binders, 0n))
      c_match_cases_supported_body(c_expr_env(body, definitions, 0n, locals), body, rest, binders, definitions, locals)
    case _ _: False{}

def c_match_cases_supported_body(expr: Maybe<&2, String>, body: AST.SyntaxTerm, rest: List<&2, AST.SyntaxTerm>, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>, locals: List<&2, String>) -> Bool:
  match expr:
    case Some{_}: c_match_cases_supported(rest, binders, definitions)
    case None{}: c_match_cases_supported_bang(c_split_bang(body), rest, binders, definitions, locals)

def c_match_cases_supported_bang(found: Maybe<&2, BangSplit>, rest: List<&2, AST.SyntaxTerm>, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>, locals: List<&2, String>) -> Bool:
  match found:
    case Some{BangSplit{key, args, captures, _}}:
      Bool.and(Bool.and(c_bang_supported_context(key, args, 0n, locals, definitions), c_capture_terms_supported(captures, definitions, 0n, locals)), c_match_cases_supported(rest, binders, definitions))
    case None{}: False{}

def c_match_definition_supported(definition: IndexedDefinition, definitions: List<&2, IndexedDefinition>) -> Bool:
  match definition:
    case IndexedDefinition{_, _, _, binders, _, _, _, _}:
      c_match_definition_supported_term(c_definition_match_term(definition), binders, definitions)

def c_match_definition_supported_term(found: Maybe<&2, AST.SyntaxTerm>, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>) -> Bool:
  match found:
    case Some{AST.BodyMatch{+first_scrutinee <> rest_scrutinees, cases, _}}:
      scrutinees = first_scrutinee <> rest_scrutinees
      c_match_definition_supported_scrutinees(c_capture_terms_supported(scrutinees, definitions, 0n, c_binder_env(binders, 0n)), cases, binders, definitions)
    case _: False{}

def c_match_definition_supported_scrutinees(valid: Bool, cases: List<&2, AST.SyntaxTerm>, binders: List<&2, AST.TelescopeItem>, definitions: List<&2, IndexedDefinition>) -> Bool:
  match valid:
    case True{}: c_match_cases_supported(cases, binders, definitions)
    case False{}: False{}
def c_pattern_binders(patterns: List<&2, AST.SyntaxPattern>) -> List<&2, AST.TelescopeItem>:
  match patterns:
    case Nil{}: Nil{}
    case +pattern <> rest: List.append(&2, AST.TelescopeItem, c_pattern_binders_one(pattern), c_pattern_binders(rest))

def c_pattern_binders_one(pattern: AST.SyntaxPattern) -> List<&2, AST.TelescopeItem>:
  match pattern:
    case AST.PatternVar{key, index, quantity, span}:
      [AST.Binder{quantity, key, index,  AST.TermRef{ "Nat", span}, span}]
    case AST.PatternCtr{ _, fields,  _}: c_pattern_binders(fields)

def c_pattern_live_values(binders: List<&2, AST.TelescopeItem>, values: List<&2, String>) -> List<&2, String>:
  match binders values:
    case Nil{} Nil{}: Nil{}
    case +AST.Binder{ AST.QZero{},  _,  _,  _,  _} <> binders_rest +_ <> values_rest: c_pattern_live_values(binders_rest, values_rest)
    case +_ <> binders_rest +value <> values_rest: value <> c_pattern_live_values(binders_rest, values_rest)
    case _ _: Nil{}

def c_io_special_segments(definitions: List<&2, IndexedDefinition>) -> String:
  bind_action = c_indirect_call("__bend_m", "__bend_cont", 1n, definitions)
  callback_action = c_indirect_call("__bend_f", "__bend_x", 1n, definitions)
  callback_result = c_indirect_call("__bend_action", "__bend_k", 1n, definitions)
  String.concat([
    "  WL_CASE(FID_CEMIT_IO_BIND)\n  {\n    Term __bend_m = r0; Term __bend_f = r1; Term __bend_k = r2;\n    WL_OPEN\n    Term __bend_cont = bend_closure_make(e, FID_CEMIT_BIND_CONT, 2, (Term[]){ __bend_f, __bend_k });\n    r0 = ", bind_action, ";\n    WL_RETN(1);\n  }}\n",
    "  WL_CASE(FID_CEMIT_BIND_CONT)\n  {\n    Term __bend_f = r0; Term __bend_k = r1; Term __bend_x = r2;\n    WL_OPEN\n    Term __bend_action = ", callback_action, ";\n    r0 = ", callback_result, ";\n    WL_RETN(1);\n  }}\n"
  ])
def maximum_function_arity(definitions: List<&2, IndexedDefinition>) -> Nat:
  match definitions:
    case Nil{}: 0n
    case +definition <> rest:
      current = c_definition_arity(definition)
      remaining = maximum_function_arity(rest)
      match current > remaining:
        case True{}: current
        case False{}: remaining

def c_call_refs(definitions: List<&2, IndexedDefinition>) -> String:
  match definitions:
    case Nil{}: ""
    case +definition <> rest:
      match definition:
        case IndexedDefinition{ _,  _, full_key,  _,  _,  _,  _,  _}:
          String.append("WL_X(", String.append(fid_macro(full_key), String.append(") ", c_call_refs(rest))))

def c_repeat_nat(value: Nat, count: Nat) -> List<&2, Nat>:
  match count:
    case 0n: Nil{}
    case 1n+remaining: value <> c_repeat_nat(value, remaining)
def c_register_declarations(count: Nat, index: Nat) -> String:
  match count:
    case 0n: ""
    case 1n+remaining:
      String.append("Term r", String.append(Nat.show(index), c_call_separator(c_register_declarations(remaining, index + 1n))))

def c_register_names(count: Nat, index: Nat) -> String:
  match count:
    case 0n: ""
    case 1n+remaining:
      String.append("r", String.append(Nat.show(index), c_call_separator(c_register_names(remaining, index + 1n))))

def c_load_rows(count: Nat, index: Nat) -> String:
  match count:
    case 0n: ""
    case 1n+remaining:
      String.append("    if ((N) <= ", String.append(Nat.show(index), String.append(") break; r", String.append(Nat.show(index), String.append(" = e.mem[(A) + ", String.append(Nat.show(index), String.append("]; \\\n", c_load_rows(remaining, index + 1n))))))))

def c_last_rows(count: Nat, index: Nat) -> String:
  match count:
    case 0n: ""
    case 1n+remaining:
      String.append("    case ", String.append(Nat.show(index), String.append(": r", String.append(Nat.show(index), String.append(" = (X); break; \\\n", c_last_rows(remaining, index + 1n))))))


def c_show_arm_count(constructors: List<&2, AST.ConstructorDecl>) -> Nat:
  List.length(&2, AST.ConstructorDecl, constructors)

def c_show_kind(type_key: String) -> Nat:
  c_show_kind_flags(key_is(type_key, "Nat"), key_is(type_key, "U32"), key_is(type_key, "F32"), key_is(type_key, "Char"), key_is(type_key, "String"), key_is(type_key, "Eql"))

def c_show_kind_flags(is_nat: Bool, is_u32: Bool, is_f32: Bool, is_char: Bool, is_string: Bool, is_eql: Bool) -> Nat:
  match is_nat is_u32 is_f32 is_char is_string is_eql:
    case True{} _ _ _ _ _: 2n
    case False{} True{} _ _ _ _: 0n
    case False{} False{} True{} _ _ _: 1n
    case False{} False{} False{} True{} _ _: 3n
    case False{} False{} False{} False{} True{} _: 4n
    case False{} False{} False{} False{} False{} True{}: 5n
    case _ _ _ _ _ _: 0n

def c_show_type_width(type_key: String, types: List<&2, IndexedType>, depth: Nat) -> Nat:
  match depth >= 8n:
    case True{}: 1n
    case False{}: c_show_type_width_found(c_find_type(type_key, types), type_key, types, depth)

def c_show_type_width_found(found: Maybe<&2, IndexedType>, type_key: String, types: List<&2, IndexedType>, depth: Nat) -> Nat:
  match found:
    case Some{IndexedType{_, _, _, _, _, arms, _}}:
      count = c_show_arm_count(arms)
      3n + count * 3n + c_show_arm_field_count(arms) * 2n + c_show_arm_child_cells(arms, type_key, types, depth + 1n)
    case None{}: 1n

def c_show_child_width(type_key: String, root_key: String, types: List<&2, IndexedType>, depth: Nat) -> Nat:
  c_show_child_width_flags(String.eq(type_key, root_key), key_is(type_key, "Bool"), key_is(type_key, "Char"), c_builtin_show_key(type_key), type_key, root_key, types, depth)

def c_show_child_width_flags(is_root: Bool, is_bool: Bool, is_char: Bool, is_builtin: Bool, type_key: String, root_key: String, types: List<&2, IndexedType>, depth: Nat) -> Nat:
  match is_root is_bool is_char is_builtin:
    case True{} _ _ _: 0n
    case False{} True{} _ _: 9n
    case False{} False{} True{} _: 2n
    case False{} False{} False{} True{}: 1n
    case _ _ _ _: c_show_type_width(type_key, types, depth + 1n)

def c_show_child_cells(fields: List<&2, AST.TelescopeItem>, root_key: String, types: List<&2, IndexedType>, depth: Nat) -> Nat:
  match fields:
    case Nil{}: 0n
    case +field <> rest:
      match field:
        case AST.Binder{ _,  _,  _, ty,  _}: c_show_child_width(main_result_key(ty), root_key, types, depth) + c_show_child_cells(rest, root_key, types, depth)
        case AST.TemplateBinder{ _,  _,  _,  _}: c_show_child_cells(rest, root_key, types, depth)

def c_show_field_count(fields: List<&2, AST.TelescopeItem>) -> Nat:
  match fields:
    case Nil{}: 0n
    case +field <> rest:
      match field:
        case AST.Binder{ _,  _,  _,  _,  _}: 1n + c_show_field_count(rest)
        case AST.TemplateBinder{ _,  _,  _,  _}: c_show_field_count(rest)

def c_show_field_cells(fields: List<&2, AST.TelescopeItem>, index: Nat, desc_index: Nat, root_key: String, types: List<&2, IndexedType>, depth: Nat) -> String:
  match fields:
    case Nil{}: ""
    case +field <> rest:
      match field:
        case AST.Binder{_, _, _, ty, _}:
          type_key = main_result_key(ty)
          width = c_show_child_width(type_key, root_key, types, depth)
          String.append(c_show_field_cell(String.eq(type_key, root_key), index, desc_index), c_show_field_cells(rest, index + 1n, desc_index + width, root_key, types, depth))
        case AST.TemplateBinder{_, _, _, _}: c_show_field_cells(rest, index, desc_index, root_key, types, depth)

def c_show_field_cell(is_root: Bool, index: Nat, desc_index: Nat) -> String:
  match is_root:
    case True{}: String.concat([", ", Nat.show(index), ", 0"])
    case False{}: String.concat([", ", Nat.show(index), ", ", Nat.show(desc_index)])

def c_show_child_descriptors(fields: List<&2, AST.TelescopeItem>, constructors: List<&2, IndexedConstructor>, root_key: String, types: List<&2, IndexedType>, depth: Nat, desc_index: Nat) -> String:
  match fields:
    case Nil{}: ""
    case +field <> rest:
      match field:
        case AST.Binder{_, _, _, ty, _}:
          type_key = main_result_key(ty)
          width = c_show_child_width(type_key, root_key, types, depth)
          suffix = c_show_child_descriptor_suffix(String.eq(type_key, root_key), key_is(type_key, "Bool"), key_is(type_key, "Char"), c_builtin_show_key(type_key), type_key, constructors, types, depth, desc_index)
          String.concat([suffix, c_show_child_descriptors(rest, constructors, root_key, types, depth, desc_index + width)])
        case AST.TemplateBinder{_, _, _, _}: c_show_child_descriptors(rest, constructors, root_key, types, depth, desc_index)

def c_show_child_descriptor_suffix(is_root: Bool, is_bool: Bool, is_char: Bool, is_builtin: Bool, type_key: String, constructors: List<&2, IndexedConstructor>, types: List<&2, IndexedType>, depth: Nat, desc_index: Nat) -> String:
  match is_root is_bool is_char is_builtin:
    case True{} _ _ _: ""
    case False{} True{} _ _: String.concat([", 7, 0, 2, ", Nat.show(constructor_index(constructors, "False", 0n)), ", 0, 1, ", Nat.show(constructor_index(constructors, "True", 0n)), ", 0"])
    case False{} False{} True{} _: ", 3, 0"
    case False{} False{} False{} True{}: String.concat([", ", Nat.show(c_show_kind(type_key))])
    case _ _ _ _: c_show_type_descriptor(type_key, types, constructors, depth + 1n, desc_index)

def c_show_arm_field_count(constructors: List<&2, AST.ConstructorDecl>) -> Nat:
  match constructors:
    case Nil{}: 0n
    case +constructor <> rest:
      match constructor:
        case AST.Constructor{ _, fields,  _}: c_show_field_count(fields) + c_show_arm_field_count(rest)

def c_show_arm_child_cells(constructors: List<&2, AST.ConstructorDecl>, root_key: String, types: List<&2, IndexedType>, depth: Nat) -> Nat:
  match constructors:
    case Nil{}: 0n
    case +constructor <> rest:
      match constructor:
        case AST.Constructor{ _, fields,  _}: c_show_child_cells(fields, root_key, types, depth) + c_show_arm_child_cells(rest, root_key, types, depth)

def c_show_arm_cells(namespace: String, constructors: List<&2, AST.ConstructorDecl>, cids: List<&2, IndexedConstructor>, child_index: Nat, root_key: String, types: List<&2, IndexedType>, depth: Nat) -> String:
  match constructors:
    case Nil{}: ""
    case +constructor <> rest:
      match constructor:
        case AST.Constructor{key, fields,  _}:
          field_count = c_show_field_count(fields)
          children = c_show_child_cells(fields, root_key, types, depth)
          name_id = constructor_index(cids, qualify(namespace, key), 0n) + 2n
          String.concat([", ", Nat.show(name_id), ", ", cid_macro(qualify(namespace, key)), ", ", Nat.show(field_count), c_show_field_cells(fields, 0n, child_index, root_key, types, depth), c_show_arm_cells(namespace, rest, cids, child_index + children, root_key, types, depth)])

def c_show_type_descriptor(type_key: String, types: List<&2, IndexedType>, constructors: List<&2, IndexedConstructor>, depth: Nat, node_index: Nat) -> String:
  match depth >= 8n:
    case True{}: ", 0"
    case False{}: c_show_type_descriptor_found(c_find_type(type_key, types), type_key, types, constructors, depth, node_index)

def c_show_type_descriptor_found(found: Maybe<&2, IndexedType>, type_key: String, types: List<&2, IndexedType>, constructors: List<&2, IndexedConstructor>, depth: Nat, node_index: Nat) -> String:
  match found:
    case Some{IndexedType{namespace, _, _, _, _, arms, _}}:
      count = c_show_arm_count(arms)
      child_start = node_index + 3n + count * 3n + c_show_arm_field_count(arms) * 2n
      String.concat([", 7, 1, ", Nat.show(count), c_show_arm_cells(namespace, arms, constructors, child_start, type_key, types, depth + 1n), c_show_arm_child_descriptors(arms, constructors, type_key, types, depth + 1n, child_start)])
    case None{}: ", 0"

def c_show_arm_child_descriptors(constructors: List<&2, AST.ConstructorDecl>, cids: List<&2, IndexedConstructor>, root_key: String, types: List<&2, IndexedType>, depth: Nat, desc_index: Nat) -> String:
  match constructors:
    case Nil{}: ""
    case +constructor <> rest:
      match constructor:
        case AST.Constructor{ _, fields,  _}:
          children = c_show_child_cells(fields, root_key, types, depth)
          String.concat([c_show_child_descriptors(fields, cids, root_key, types, depth, desc_index), c_show_arm_child_descriptors(rest, cids, root_key, types, depth, desc_index + children)])
def c_show_names(constructors: List<&2, IndexedConstructor>) -> String:
  match constructors:
    case Nil{}: ""
    case +constructor <> rest:
      match constructor:
        case IndexedConstructor{ _, key,  _,  _}: String.concat(["\"", key, "\", ", c_show_names(rest)])

def c_find_type(type_key: String, types: List<&2, IndexedType>) -> Maybe<&2, IndexedType>:
  match types:
    case Nil{}: None{}
    case +one <> rest:
      match one:
        case IndexedType{_, _, full_key, _, _, _, _}:
          c_find_type_match(String.eq(type_key, full_key), type_key, one, rest)

def c_find_type_match(same: Bool, type_key: String, one: IndexedType, rest: List<&2, IndexedType>) -> Maybe<&2, IndexedType>:
  match same:
    case True{}: Some{one}
    case False{}: c_find_type(type_key, rest)

def c_custom_show_source(type_key: String, types: List<&2, IndexedType>, constructors: List<&2, IndexedConstructor>) -> String:
  c_custom_show_type(c_find_type(type_key, types), type_key, types, constructors)

def c_custom_show_type(found: Maybe<&2, IndexedType>, type_key: String, types: List<&2, IndexedType>, constructors: List<&2, IndexedConstructor>) -> String:
  match found:
    case Some{IndexedType{namespace, _, _, _, _, arms, _}}:
      count = c_show_arm_count(arms)
      child_start = 3n + count * 3n + c_show_arm_field_count(arms) * 2n
      String.concat([
        "#if !DEVICE\nstatic const u32 SHOW_DESC[] = { 7, 1, ", Nat.show(count),
        c_show_arm_cells(namespace, arms, constructors, child_start, type_key, types, 0n),
        c_show_arm_child_descriptors(arms, constructors, type_key, types, 0n, child_start), " };\n",
        "static const char* SHOW_NAMES[] = { \"False\", \"True\", ", c_show_names(constructors), "};\n#endif\n"
      ])
    case None{}: "#if !DEVICE\nstatic const u32 SHOW_DESC[] = { 0 };\nstatic const char* SHOW_NAMES[] = { \"False\", \"True\" };\n#endif\n"

def c_builtin_show_key(type_key: String) -> Bool:
  Bool.or(key_is(type_key, "Nat"), Bool.or(key_is(type_key, "U32"), Bool.or(key_is(type_key, "F32"), Bool.or(key_is(type_key, "Char"), Bool.or(key_is(type_key, "String"), key_is(type_key, "Eql"))))))

def dynamic_show_source(type_key: String, types: List<&2, IndexedType>, constructors: List<&2, IndexedConstructor>) -> String:
  dynamic_show_source_bool(key_is(type_key, "Bool"), type_key, types, constructors)

def dynamic_show_source_bool(is_bool: Bool, type_key: String, types: List<&2, IndexedType>, constructors: List<&2, IndexedConstructor>) -> String:
  match is_bool:
    case True{}:
      String.concat([
        "#if !DEVICE\nstatic const u32 SHOW_DESC[] = { 7, 0, 2, 0, ",
        Nat.show(constructor_index(constructors, "False", 0n)), ", 0, 1, ",
        Nat.show(constructor_index(constructors, "True", 0n)), ", 0 };\n",
        "static const char* SHOW_NAMES[] = { \"False\", \"True\" };\n#endif\n"
      ])
    case False{}: dynamic_show_source_builtin(c_builtin_show_key(type_key), type_key, types, constructors)

def dynamic_show_source_builtin(is_builtin: Bool, type_key: String, types: List<&2, IndexedType>, constructors: List<&2, IndexedConstructor>) -> String:
  match is_builtin:
    case True{}: String.concat(["#if !DEVICE\nstatic const u32 SHOW_DESC[] = { ", dynamic_show_key(type_key), " };\nstatic const char* SHOW_NAMES[] = { \"False\", \"True\" };\n#endif\n"])
    case False{}: c_custom_show_source(type_key, types, constructors)

def dynamic_show_key(type_key: String) -> String:
  dynamic_show_key_flags(key_is(type_key, "Nat"), key_is(type_key, "U32"), key_is(type_key, "F32"), key_is(type_key, "Char"), key_is(type_key, "String"), key_is(type_key, "Eql"))

def dynamic_show_key_flags(is_nat: Bool, is_u32: Bool, is_f32: Bool, is_char: Bool, is_string: Bool, is_eql: Bool) -> String:
  match is_nat is_u32 is_f32 is_char is_string is_eql:
    case True{} _ _ _ _ _: "2"
    case False{} True{} _ _ _ _: "0"
    case False{} False{} True{} _ _ _: "1"
    case False{} False{} False{} True{} _ _: "3, 0"
    case False{} False{} False{} False{} True{} _: "4"
    case False{} False{} False{} False{} False{} True{}: "5"
    case _ _ _ _ _ _: "0"

def c_dynamic_tables_main_key(main: IndexedDefinition) -> String:
  match main:
    case IndexedDefinition{_, _, full_key, _, _, _, _, _}: full_key

def c_dynamic_tables_main_type(main: IndexedDefinition) -> String:
  match main:
    case IndexedDefinition{_, _, _, _, AST.SomeTerm{term}, _, _, _}: main_result_key(term)
    case _: ""

def c_dynamic_tables(types: List<&2, IndexedType>, constructors: List<&2, IndexedConstructor>, foreigns: List<&2, CForeign.ForeignDefinition>, definitions: List<&2, IndexedDefinition>, main: IndexedDefinition) -> String:
  count = List.length(&2, IndexedDefinition, definitions)
  bang_keys = c_bang_keys(definitions, Nil{})
  regs0 = maximum_function_arity(definitions)
  regs = c_dynamic_tables_registers(regs0 > 3n, regs0)
  main_key = c_dynamic_tables_main_key(main)
  main_type = c_dynamic_tables_main_type(main)
  io_main = key_is(main_type, "IO")
  String.concat([
    c_fid_definitions(definitions, 0n),
    "#define FID_IO_EMIT ", Nat.show(count), "\n#define FID_CLO_APPLY ", Nat.show(count + 1n), "\n#define FID_EXIT ", Nat.show(count + 2n), "\n#define FID_ENTER ", Nat.show(count + 3n), "\n#define FID_CEMIT_IO_BIND ", Nat.show(count + 4n), "\n#define FID_CEMIT_BIND_CONT ", Nat.show(count + 5n), "\n",
    "CONSTV u8 FID_ARITY_T[] = { ", nat_list(List.append(&2, Nat, c_function_arities(definitions), [1n, 2n, 0n, 0n, 3n, 3n]), ", "), " };\n",
    "CONSTV u8 FID_FLAG_T[] = { ", nat_list(List.append(&2, Nat, c_fid_flag_values(definitions, bang_keys), c_repeat_nat(2n, 6n)), ", "), " };\n",
    "CONSTV u8 FID_RESW_T[] = { ", nat_list(List.append(&2, Nat, c_fid_resw_values(definitions), c_repeat_nat(0n, 6n)), ", "), " };\n",
    c_constructor_tables(constructors, foreigns),
    "#define STAT_LEN 0\n#define IO_HOTS 63\n#define WL_RESW 1\n#define BANGS ", Nat.show(List.length(&2, String, bang_keys)), "\n",
    "#define WL_BANK ", c_register_declarations(regs, 0n), ";\n",
    "#define WL_SIG Env e, Stk sp, u32 seq, u32 rn, ", c_register_declarations(regs, 0n), "\n",
    "#define WL_ALL e, sp, seq, rn, ", c_register_names(regs, 0n), "\n",
    "#define WL_LOAD(A, N) do { \\\n", c_load_rows(regs, 0n), "  } while (0);\n",
    "#define WL_LAST(X) switch (war) { \\\n", c_last_rows(regs, 0n), "  }\n",
    "#define WL_SAVE(V) (V)[0] = r0\n#define WL_TAKE(V) r0 = (V)[0]\n",
    "#define WL_TABLE ", c_call_refs(definitions), "WL_X(FID_IO_EMIT) WL_X(FID_CLO_APPLY) WL_X(FID_EXIT) WL_X(FID_CEMIT_IO_BIND) WL_X(FID_CEMIT_BIND_CONT)\n",
    dynamic_tables_tables_main(main_key, io_main, main_type, types, constructors),
    c_helper_source(definitions)
  ])
def c_dynamic_tables_registers(at_least_three: Bool, regs: Nat) -> Nat:
  match at_least_three:
    case True{}: regs
    case False{}: 3n

def dynamic_tables_tables_main(main_key: String, io_main: Bool, main_type: String, types: List<&2, IndexedType>, constructors: List<&2, IndexedConstructor>) -> String:
  match io_main:
    case True{}:
      String.concat(["#define MAIN_FID ", fid_macro(main_key), "\n#define MAIN_PURE 0\n", dynamic_show_source("Nat", types, constructors)])
    case False{}:
      String.concat(["#define MAIN_FID ", fid_macro(main_key), "\n#define MAIN_PURE 1\n", dynamic_show_source(main_type, types, constructors)])

def first_order_binders(binders: List<&2, AST.TelescopeItem>) -> Bool:
  match binders:
    case Nil{}: True{}
    case +binder <> rest:
      match binder:
        case AST.Binder{ AST.QZero{},  _,  _,  _,  _}: first_order_binders(rest)
        case AST.Binder{_, _, _, ty, _}: first_order_type(ty, rest)
        case AST.TemplateBinder{_, _, _, _}: False{}

def first_order_type(ty: AST.SyntaxTerm, rest: List<&2, AST.TelescopeItem>) -> Bool:
  match ty:
    case AST.TermAll{_, _, _, _, _, _}: first_order_binders(rest)
    case _ : first_order_type_empty(String.is_empty(main_result_key(ty)), rest)

def first_order_type_empty(is_empty: Bool, rest: List<&2, AST.TelescopeItem>) -> Bool:
  match is_empty:
    case True{}: False{}
    case False{}: first_order_binders(rest)

def filter_supported_functions(definitions: List<&2, IndexedDefinition>, all_definitions: List<&2, IndexedDefinition>) -> List<&2, IndexedDefinition>:
  match definitions:
    case Nil{}: Nil{}
    case +definition <> rest:
      match definition:
        case IndexedDefinition{_, _, _, binders, _, _, _, _}:
          filter_supported_function_one(Bool.and(first_order_binders(binders), c_definition_supported(definition, all_definitions)), definition, rest, all_definitions)

def filter_supported_function_one(supported: Bool, definition: IndexedDefinition, rest: List<&2, IndexedDefinition>, all_definitions: List<&2, IndexedDefinition>) -> List<&2, IndexedDefinition>:
  match supported:
    case True{}: definition <> filter_supported_functions(rest, all_definitions)
    case False{}: filter_supported_functions(rest, all_definitions)

def stabilize_supported_functions(definitions: List<&2, IndexedDefinition>) -> List<&2, IndexedDefinition>:
  next = filter_supported_functions(definitions, definitions)
  stabilize_supported_functions_same(Nat.is_eq(List.length(&2, IndexedDefinition, next), List.length(&2, IndexedDefinition, definitions)), next)

def stabilize_supported_functions_same(same: Bool, next: List<&2, IndexedDefinition>) -> List<&2, IndexedDefinition>:
  match same:
    case True{}: next
    case False{}: stabilize_supported_functions(next)

def remove_main_function(main: IndexedDefinition, definitions: List<&2, IndexedDefinition>) -> List<&2, IndexedDefinition>:
  match definitions:
    case Nil{}: Nil{}
    case +definition <> rest:
      match definition main:
        case IndexedDefinition{_, _, main_key, _, _, _, _, _} IndexedDefinition{_, _, def_key, _, _, _, _, _}:
          remove_main_function_same(String.eq(main_key, def_key), main, definition, rest)

def remove_main_function_same(same: Bool, main: IndexedDefinition, definition: IndexedDefinition, rest: List<&2, IndexedDefinition>) -> List<&2, IndexedDefinition>:
  match same:
    case True{}: remove_main_function(main, rest)
    case False{}: definition <> remove_main_function(main, rest)

def first_order_functions(main: IndexedDefinition, definitions: List<&2, IndexedDefinition>) -> List<&2, IndexedDefinition>:
  remove_main_function(main, stabilize_supported_functions(supported_definitions(definitions)))

def c_definition_lambdas(definitions: List<&2, IndexedDefinition>) -> List<&2, IndexedDefinition>:
  match definitions:
    case Nil{}: Nil{}
    case +definition <> rest:
      match definition:
        case IndexedDefinition{ _,  _,  _, binders,  _,  AST.DefTerm{term},  _,  _}:
          List.append(&2, IndexedDefinition, c_term_lambdas(term, binder_count(binders), 0n), c_definition_lambdas(rest))
        case _: c_definition_lambdas(rest)

def c_lift_terms(terms: List<&2, AST.SyntaxTerm>, owner: String, binders: List<&2, AST.TelescopeItem>) -> LiftedTerms:
  match terms:
    case Nil{}: LiftedTerms{ Nil{},  Nil{}}
    case +term <> rest:
      first = c_lift_term(term, owner, binders, False{})
      remaining = c_lift_terms(rest, owner, binders)
      LiftedTerms{ first.term <> remaining.terms,  List.append(&2, IndexedDefinition, first.helpers, remaining.helpers)}

def c_lift_cases(cases: List<&2, AST.SyntaxTerm>, owner: String, binders: List<&2, AST.TelescopeItem>) -> LiftedTerms:
  match cases:
    case Nil{}: LiftedTerms{ Nil{},  Nil{}}
    case +one <> rest:
      match one:
        case AST.BodyCase{patterns, body, span}:
          lifted = c_lift_term(body, owner, List.append(&2, AST.TelescopeItem, binders, c_pattern_binders(patterns)), False{})
          remaining = c_lift_cases(rest, owner, binders)
          LiftedTerms{ AST.BodyCase{patterns,  lifted.term, span} <> remaining.terms,  List.append(&2, IndexedDefinition, lifted.helpers, remaining.helpers)}
        case _:
          remaining = c_lift_cases(rest, owner, binders)
          LiftedTerms{ one <> remaining.terms,  remaining.helpers}

def c_lift_context_args(binders: List<&2, AST.TelescopeItem>, total: Nat) -> List<&2, AST.SyntaxTerm>:
  match binders:
    case Nil{}: Nil{}
    case +one <> rest:
      match one:
        case AST.Binder{ AST.QZero{},  _,  _,  _,  _}: c_lift_context_args(rest, total - 1n)
        case AST.Binder{ _, key,  _,  _, span}: AST.TermVar{key,  total - 1n, span} <> c_lift_context_args(rest, total - 1n)
        case AST.TemplateBinder{ _,  _,  _,  _}: c_lift_context_args(rest, total - 1n)

def c_lift_helper_key(owner: String, span: AST.SourceSpan) -> String:
  match span:
    case AST.SpanOf{ _, beg, end}: String.concat([owner, "__cemit_nested_", Nat.show(beg), "_", Nat.show(end)])
    case _: String.concat([owner, "__cemit_nested_0_0"])

def c_lift_apply(head: AST.SyntaxTerm, args: List<&2, AST.SyntaxTerm>, span: AST.SourceSpan) -> AST.SyntaxTerm:
  match args:
    case Nil{}: head
    case +arg <> rest: c_lift_apply(AST.TermApp{ head, arg, span}, rest, span)

def c_lift_match(scrutinees: List<&2, AST.SyntaxTerm>, cases: List<&2, AST.SyntaxTerm>, span: AST.SourceSpan, owner: String, binders: List<&2, AST.TelescopeItem>, root: Bool) -> LiftedTerm:
  scr = c_lift_terms(scrutinees, owner, binders)
  cs = c_lift_cases(cases, owner, binders)
  match_term = AST.BodyMatch{scr.terms, cs.terms, span}
  c_lift_match_scrutinees(c_split_bang_terms(scr.terms), root, match_term, scr.helpers, cs.helpers, cases, owner, binders, span)

def c_lift_match_scrutinees(found: Maybe<&2, BangSplit>, root: Bool, match_term: AST.SyntaxTerm, scr_helpers: List<&2, IndexedDefinition>, case_helpers: List<&2, IndexedDefinition>, cases: List<&2, AST.SyntaxTerm>, owner: String, binders: List<&2, AST.TelescopeItem>, span: AST.SourceSpan) -> LiftedTerm:
  match found:
    case Some{_}: c_lift_match_choice(root, match_term, scr_helpers, case_helpers, owner, binders, span)
    case None{}: c_lift_match_choice(Bool.or(root, Bool.not(c_match_has_bang(cases))), match_term, scr_helpers, case_helpers, owner, binders, span)

def c_lift_match_choice(keep: Bool, match_term: AST.SyntaxTerm, scr_helpers: List<&2, IndexedDefinition>, case_helpers: List<&2, IndexedDefinition>, owner: String, binders: List<&2, AST.TelescopeItem>, span: AST.SourceSpan) -> LiftedTerm:
  match keep:
    case True{}: LiftedTerm{match_term, List.append(&2, IndexedDefinition, scr_helpers, case_helpers)}
    case False{}:
      helper_key = c_lift_helper_key(owner, span)
      args = c_lift_context_args(binders, List.length(&2, AST.TelescopeItem, binders))
      head = AST.TermBang{AST.TermRef{helper_key, span}, span}
      call = c_lift_apply(head, args, span)
      helper = IndexedDefinition{"", helper_key, helper_key, binders, AST.NoTerm{}, AST.DefTerm{match_term}, False{}, span}
      LiftedTerm{call, helper <> List.append(&2, IndexedDefinition, scr_helpers, case_helpers)}
def c_lift_let_binders(keys: List<&2, String>, indexes: List<&2, Nat>, quantities: List<&2, AST.Quantity>, span: AST.SourceSpan) -> List<&2, AST.TelescopeItem>:
  match keys indexes quantities:
    case Nil{} Nil{} Nil{}: Nil{}
    case +key <> rest_keys +index <> rest_indexes +quantity <> rest_quantities:
      AST.Binder{quantity, key, index,  AST.TermRef{ "Nat", span}, span} <> c_lift_let_binders(rest_keys, rest_indexes, rest_quantities, span)
    case _: Nil{}

def c_lift_term(term: AST.SyntaxTerm, owner: String, binders: List<&2, AST.TelescopeItem>, root: Bool) -> LiftedTerm:
  match term:
    case AST.BodyMatch{scrutinees, cases, span}: c_lift_match(scrutinees, cases, span, owner, binders, root)
    case AST.BodyLocal{patterns, quantity, values, body, span}:
      vals = c_lift_terms(values, owner, binders)
      body_binders = List.append(&2, AST.TelescopeItem, binders, c_pattern_binders(patterns))
      b = c_lift_term(body, owner, body_binders, False{})
      match root:
        case True{}: LiftedTerm{ AST.BodyLocal{patterns, quantity,  vals.terms,  b.term, span},  List.append(&2, IndexedDefinition, vals.helpers, b.helpers)}
        case False{}:
          lifted = c_lift_match(vals.terms, [AST.BodyCase{patterns,  b.term, span}], span, owner, binders, False{})
          LiftedTerm{ lifted.term,  List.append(&2, IndexedDefinition, vals.helpers, List.append(&2, IndexedDefinition, b.helpers, lifted.helpers))}
    case AST.TermLet{keys, indexes, quantities, values, body, span}:
      vals = c_lift_terms(values, owner, binders)
      extended = List.append(&2, AST.TelescopeItem, binders, c_lift_let_binders(keys, indexes, quantities, span))
      b = c_lift_term(body, owner, extended, False{})
      LiftedTerm{ AST.TermLet{keys, indexes, quantities,  vals.terms,  b.term, span},  List.append(&2, IndexedDefinition, vals.helpers, b.helpers)}
    case AST.TermBang{ value, span}:
      v = c_lift_term(value, owner, binders, False{})
      LiftedTerm{ AST.TermBang{ v.term, span},  v.helpers}
    case AST.TermApp{fn, arg, span}:
      f = c_lift_term(fn, owner, binders, False{})
      a = c_lift_term(arg, owner, binders, False{})
      LiftedTerm{ AST.TermApp{ f.term,  a.term, span},  List.append(&2, IndexedDefinition, f.helpers, a.helpers)}
    case AST.TermAnn{ value, ty, span}:
      v = c_lift_term(value, owner, binders, False{})
      t = c_lift_term(ty, owner, binders, False{})
      LiftedTerm{ AST.TermAnn{ v.term,  t.term, span},  List.append(&2, IndexedDefinition, v.helpers, t.helpers)}
    case AST.TermTemplate{ value, span}:
      v = c_lift_term(value, owner, binders, False{})
      LiftedTerm{ AST.TermTemplate{ v.term, span},  v.helpers}
    case AST.TermMin{left, right, span}:
      l = c_lift_term(left, owner, binders, False{})
      r = c_lift_term(right, owner, binders, False{})
      LiftedTerm{ AST.TermMin{ l.term,  r.term, span},  List.append(&2, IndexedDefinition, l.helpers, r.helpers)}
    case AST.TermCtr{key, args, span}:
      a = c_lift_terms(args, owner, binders)
      LiftedTerm{ AST.TermCtr{key,  a.terms, span},  a.helpers}
    case AST.TermString{_, _, _}: LiftedTerm{term, Nil{}}
    case AST.TermAdt{key, args, refs, span}:
      a = c_lift_terms(args, owner, binders)
      LiftedTerm{ AST.TermAdt{key,  a.terms, refs, span},  a.helpers}
    case AST.TermFill{head, args, span}:
      h = c_lift_term(head, owner, binders, False{})
      a = c_lift_terms(args, owner, binders)
      LiftedTerm{ AST.TermFill{ h.term,  a.terms, span},  List.append(&2, IndexedDefinition, h.helpers, a.helpers)}
    case AST.TermPlus{head, args, span}:
      h = c_lift_term(head, owner, binders, False{})
      a = c_lift_terms(args, owner, binders)
      LiftedTerm{ AST.TermPlus{ h.term,  a.terms, span},  List.append(&2, IndexedDefinition, h.helpers, a.helpers)}
    case AST.TermMat{key, head, matched, span}:
      h = c_lift_term(head, owner, binders, False{})
      m = c_lift_term(matched, owner, binders, False{})
      LiftedTerm{ AST.TermMat{key,  h.term,  m.term, span},  List.append(&2, IndexedDefinition, h.helpers, m.helpers)}
    case AST.TermEqual{left, right, ty, span}:
      l = c_lift_term(left, owner, binders, False{})
      r = c_lift_term(right, owner, binders, False{})
      t = c_lift_term(ty, owner, binders, False{})
      LiftedTerm{ AST.TermEqual{ l.term,  r.term,  t.term, span},  List.append(&2, IndexedDefinition, l.helpers, List.append(&2, IndexedDefinition, r.helpers, t.helpers))}
    case AST.TermRewrite{equation, proof, body, span}:
      e = c_lift_term(equation, owner, binders, False{})
      p = c_lift_term(proof, owner, binders, False{})
      b = c_lift_term(body, owner, binders, False{})
      LiftedTerm{ AST.TermRewrite{ e.term,  p.term,  b.term, span},  List.append(&2, IndexedDefinition, e.helpers, List.append(&2, IndexedDefinition, p.helpers, b.helpers))}
    case AST.TermLam{quantity, key, index, body, span}:
      b = c_lift_term(body, owner, c_lift_lambda_binder(quantity, key, index, span, binders), False{})
      LiftedTerm{ AST.TermLam{quantity, key, index,  b.term, span},  b.helpers}
    case AST.TermAll{quantity, key, index, ty, body, span}:
      t = c_lift_term(ty, owner, binders, False{})
      extended = List.append(&2, AST.TelescopeItem, binders, [AST.Binder{quantity, key, index, ty, span}])
      b = c_lift_term(body, owner, extended, False{})
      LiftedTerm{ AST.TermAll{quantity, key, index,  t.term,  b.term, span},  List.append(&2, IndexedDefinition, t.helpers, b.helpers)}
    case AST.TermSub{index, value, body, span}:
      v = c_lift_term(value, owner, binders, False{})
      b = c_lift_term(Core.subst(index, v.term, body), owner, binders, False{})
      LiftedTerm{ b.term,  List.append(&2, IndexedDefinition, v.helpers, b.helpers)}
    case AST.BodyReply{ value, span}:
      v = c_lift_term(value, owner, binders, False{})
      LiftedTerm{ AST.BodyReply{ v.term, span},  v.helpers}
    case _: LiftedTerm{term,  Nil{}}

def c_lift_definition(definition: IndexedDefinition) -> LiftedTerm:
  match definition:
    case IndexedDefinition{namespace, key, full_key, binders, result,  AST.DefTerm{term}, unsafe, span}:
      lifted = c_lift_term(term, full_key, binders, True{})
      updated = IndexedDefinition{namespace, key, full_key, binders, result,  AST.DefTerm{ lifted.term}, unsafe, span}
      LiftedTerm{ AST.TermRef{ full_key, span},  updated <> lifted.helpers}
    case _:
      LiftedTerm{ AST.TermRef{ "",  AST.SpanOf{ "",  0n,  0n}},  [definition]}

def c_lift_definitions(definitions: List<&2, IndexedDefinition>) -> List<&2, IndexedDefinition>:
  match definitions:
    case Nil{}: Nil{}
    case +definition <> rest:
      lifted = c_lift_definition(definition)

      List.append(&2, IndexedDefinition, lifted.helpers, c_lift_definitions(rest))

def c_lift_lambda_binder(quantity: Maybe<&2, AST.Quantity>, key: String, index: Nat, span: AST.SourceSpan, binders: List<&2, AST.TelescopeItem>) -> List<&2, AST.TelescopeItem>:
  match quantity:
    case Some{value}: List.append(&2, AST.TelescopeItem, binders, [AST.Binder{ value, key, index,  AST.TermRef{ "Nat", span}, span}])
    case None{}: List.append(&2, AST.TelescopeItem, binders, [AST.Binder{ AST.QMany{}, key, index,  AST.TermRef{ "Nat", span}, span}])

def dynamic_definitions(main: IndexedDefinition, definitions: List<&2, IndexedDefinition>, foreigns: List<&2, CForeign.ForeignDefinition>, span: AST.SourceSpan) -> List<&2, IndexedDefinition>:
  regular = main <> first_order_functions(main, definitions)
  lambda_definitions = c_definition_lambdas(regular)
  base_lambdas = List.append(&2, IndexedDefinition, regular, lambda_definitions)
  match_continuations = c_append_match_continuations(base_lambdas)
  with_matches = List.append(&2, IndexedDefinition, base_lambdas, match_continuations)
  continuations = c_append_bang_continuations(with_matches)
  continuation_lambdas = c_definition_lambdas(continuations)
  with_continuations = List.append(&2, IndexedDefinition, with_matches, continuations)
  with_all_lambdas = List.append(&2, IndexedDefinition, with_continuations, continuation_lambdas)
  final_continuations = c_append_bang_continuations(continuation_lambdas)
  final_match_continuations = c_append_match_continuations(continuation_lambdas)
  with_final_continuations = List.append(&2, IndexedDefinition, with_all_lambdas, final_continuations)
  with_all = List.append(&2, IndexedDefinition, with_final_continuations, final_match_continuations)
  List.append(&2, IndexedDefinition, with_all, c_index_foreigns(foreigns, span))

def emit_dynamic_runtime(runtime: String, types: List<&2, IndexedType>, constructors: List<&2, IndexedConstructor>, foreigns: List<&2, CForeign.ForeignDefinition>, definitions: List<&2, IndexedDefinition>, main: IndexedDefinition, requests: String, span: AST.SourceSpan) -> EmitResult:
  segments = String.append(c_segments(definitions), c_io_special_segments(definitions))
  parts = CParts.Parts{c_dynamic_tables(types, constructors, foreigns, definitions, main), main_spins(), segments, requests}
  emit_assembly_result(CAssembly.assemble(runtime, parts), span)

def emit_assembly_result(result: CAssembly.AssemblyResult, span: AST.SourceSpan) -> EmitResult:
  match result:
    case CAssembly.AssemblySuccess{source}: EmitSuccess{source}
    case CAssembly.AssemblyFailure{marker, observed}:
      EmitFailure{String.append("invalid C runtime template marker ", String.append(marker, String.append(": ", observed))), span}

def nat_clamp(value: Nat) -> Nat:
  match value > 281474976710655n:
    case True{}: 281474976710656n
    case False{}: value

def nat_binary(key: String, left: Nat, right: Nat) -> Maybe<&2, Nat>:
  nat_binary_add(String.ends_with(key, "Nat.add"), key, left, right)

def nat_binary_add(is_add: Bool, key: String, left: Nat, right: Nat) -> Maybe<&2, Nat>:
  match is_add:
    case True{}: Some{nat_clamp(left + right)}
    case False{}: nat_binary_sub(String.ends_with(key, "Nat.sub"), key, left, right)

def nat_binary_sub(is_sub: Bool, key: String, left: Nat, right: Nat) -> Maybe<&2, Nat>:
  match is_sub:
    case True{}: nat_binary_subtract(left > right, left, right)
    case False{}: nat_binary_mul(String.ends_with(key, "Nat.mul"), key, left, right)

def nat_binary_subtract(left_greater: Bool, left: Nat, right: Nat) -> Maybe<&2, Nat>:
  match left_greater:
    case True{}: Some{left - right}
    case False{}: Some{0n}

def nat_binary_mul(is_mul: Bool, key: String, left: Nat, right: Nat) -> Maybe<&2, Nat>:
  match is_mul:
    case True{}: Some{nat_clamp(left * right)}
    case False{}: nat_binary_div(String.ends_with(key, "Nat.div"), key, left, right)

def nat_binary_div(is_div: Bool, key: String, left: Nat, right: Nat) -> Maybe<&2, Nat>:
  match is_div:
    case True{}: nat_binary_divide(Nat.is_eq(right, 0n), left, right)
    case False{}: nat_binary_mod(String.ends_with(key, "Nat.mod"), left, right)

def nat_binary_divide(zero: Bool, left: Nat, right: Nat) -> Maybe<&2, Nat>:
  match zero:
    case True{}: Some{0n}
    case False{}: Some{left / right}

def nat_binary_mod(is_mod: Bool, left: Nat, right: Nat) -> Maybe<&2, Nat>:
  match is_mod:
    case True{}: nat_binary_modulo(Nat.is_eq(right, 0n), left, right)
    case False{}: None{}

def nat_binary_modulo(zero: Bool, left: Nat, right: Nat) -> Maybe<&2, Nat>:
  match zero:
    case True{}: Some{left}
    case False{}: Some{Nat.mod(left, right)}
def nat_power(base: Nat, exponent: Nat, fuel: Nat) -> Maybe<&2, Nat>:
  match exponent:
    case 0n: Some{1n}
    case _:
      match fuel:
        case 0n: None{}
        case 1n+remaining:
          nat_power_result(nat_power(base, exponent - 1n, remaining), base)

def nat_power_result(found: Maybe<&2, Nat>, base: Nat) -> Maybe<&2, Nat>:
  match found:
    case Some{value}: Some{nat_clamp(base * value)}
    case None{}: None{}


def nat_eval_call(fn: AST.SyntaxTerm, args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, fuel: Nat) -> Maybe<&2, Nat>:
  match fn:
    case AST.TermRef{key, _}: nat_eval_call_u32(key_is(key, "U32.to_nat"), key, args, definitions, fuel)
    case _: None{}

def nat_eval_call_u32(is_u32_conversion: Bool, key: String, args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, fuel: Nat) -> Maybe<&2, Nat>:
  match is_u32_conversion:
    case True{}:
      match args:
        case +arg <> Nil{}: u32_from_syntax(arg, "U32")
        case _: None{}
    case False{}: nat_eval_call_args(key, args, definitions, fuel)

def nat_eval_call_args(key: String, args: List<&2, AST.SyntaxTerm>, definitions: List<&2, IndexedDefinition>, fuel: Nat) -> Maybe<&2, Nat>:
  match args:
    case +left <> +right <> Nil{}:
      nat_eval_call_binary(nat_eval(left, definitions, fuel), nat_eval(right, definitions, fuel), key, fuel)
    case +arg <> Nil{}:
      nat_eval_call_double(key_is(key, "Nat.double"), arg, definitions, fuel)
    case _: None{}

def nat_eval_call_binary(left: Maybe<&2, Nat>, right: Maybe<&2, Nat>, key: String, fuel: Nat) -> Maybe<&2, Nat>:
  match left right:
    case Some{a} Some{b}: nat_eval_call_power(String.ends_with(key, "Nat.pow"), key, a, b, fuel)
    case _ _: None{}

def nat_eval_call_power(is_power: Bool, key: String, a: Nat, b: Nat, fuel: Nat) -> Maybe<&2, Nat>:
  match is_power:
    case True{}: nat_power(a, b, fuel)
    case False{}: nat_binary(key, a, b)

def nat_eval_call_double(is_double: Bool, arg: AST.SyntaxTerm, definitions: List<&2, IndexedDefinition>, fuel: Nat) -> Maybe<&2, Nat>:
  match is_double:
    case True{}: nat_eval_double_value(nat_eval(arg, definitions, fuel))
    case False{}: None{}

def nat_eval_double_value(found: Maybe<&2, Nat>) -> Maybe<&2, Nat>:
  match found:
    case Some{value}: Some{nat_clamp(value * 2n)}
    case None{}: None{}

def inferred_constant(term: AST.SyntaxTerm, definitions: List<&2, IndexedDefinition>) -> Maybe<&2, MainConstant>:
  inferred_constant_nat(nat_eval(term, definitions, 128n), term)

def inferred_constant_nat(found: Maybe<&2, Nat>, term: AST.SyntaxTerm) -> Maybe<&2, MainConstant>:
  match found:
    case Some{value}: Some{MainNat{value}}
    case None{}: inferred_constant_u32(u32_from_syntax(term, "U32"), term)

def inferred_constant_u32(found: Maybe<&2, Nat>, term: AST.SyntaxTerm) -> Maybe<&2, MainConstant>:
  match found:
    case Some{value}: Some{MainU32{value}}
    case None{}: inferred_constant_f32(u32_from_syntax(term, "F32"), term)

def inferred_constant_f32(found: Maybe<&2, Nat>, term: AST.SyntaxTerm) -> Maybe<&2, MainConstant>:
  match found:
    case Some{value}: Some{MainF32{value}}
    case None{}: inferred_constant_bool(bool_from_syntax(term))

def inferred_constant_bool(found: Maybe<&2, Bool>) -> Maybe<&2, MainConstant>:
  match found:
    case Some{value}: Some{MainBool{value}}
    case None{}: None{}

def pure_constant_main(main: IndexedDefinition, definitions: List<&2, IndexedDefinition>) -> Maybe<&2, MainConstant>:
  match main:
    case IndexedDefinition{ _,  _,  _, binders, result, body,  _,  _}:
      match binders:
        case Nil{}:
          match body:
            case AST.DefTerm{term}:
              match result:
                case AST.NoTerm{}: inferred_constant(term, definitions)
                case AST.SomeTerm{ result_type}: constant_for_type(term, main_result_key(result_type), definitions)
            case _: None{}
        case _: None{}
def source_span(main: Maybe<&2, IndexedDefinition>) -> AST.SourceSpan:
  match main:
    case Some{ IndexedDefinition{ _,  _,  _,  _,  _,  _,  _, span}}: span
    case None{}: AST.SpanOf{ "",  0n,  0n}

def c_foreign_alias_open(constructors: List<&2, IndexedConstructor>, prefix: String) -> String:
  match constructors:
    case Nil{}: ""
    case +constructor <> rest:
      match constructor:
        case IndexedConstructor{_, _, full_key, _}:
          c_foreign_alias_open_one(String.starts_with(full_key, prefix), full_key, rest, prefix)

def c_foreign_alias_open_one(matches: Bool, full_key: String, rest: List<&2, IndexedConstructor>, prefix: String) -> String:
  match matches:
    case True{}:
      local = String.drop(full_key, String.length(prefix))
      alias = cid_macro(local)
      String.concat(["#pragma push_macro(\"", alias, "\")\n#define ", alias, " ", cid_macro(full_key), "\n", c_foreign_alias_open(rest, prefix)])
    case False{}: c_foreign_alias_open(rest, prefix)

def c_foreign_alias_close(constructors: List<&2, IndexedConstructor>, prefix: String) -> String:
  match constructors:
    case Nil{}: ""
    case +constructor <> rest:
      match constructor:
        case IndexedConstructor{_, _, full_key, _}:
          c_foreign_alias_close_one(String.starts_with(full_key, prefix), full_key, rest, prefix)

def c_foreign_alias_close_one(matches: Bool, full_key: String, rest: List<&2, IndexedConstructor>, prefix: String) -> String:
  match matches:
    case True{}:
      local = String.drop(full_key, String.length(prefix))
      alias = cid_macro(local)
      String.concat(["#pragma pop_macro(\"", alias, "\")\n", c_foreign_alias_close(rest, prefix)])
    case False{}: c_foreign_alias_close(rest, prefix)

def c_foreign_seen(path: String, seen: List<&2, String>) -> Bool:
  match seen:
    case Nil{}: False{}
    case +known <> rest: c_foreign_seen_equal(String.eq(path, known), path, rest)

def c_foreign_seen_equal(same: Bool, path: String, rest: List<&2, String>) -> Bool:
  match same:
    case True{}: True{}
    case False{}: c_foreign_seen(path, rest)

def c_live_binders(binders: List<&2, AST.TelescopeItem>) -> List<&2, AST.TelescopeItem>:
  match binders:
    case Nil{}: Nil{}
    case +binder <> rest:
      match binder:
        case AST.Binder{ AST.QZero{},  _,  _,  _,  _}: c_live_binders(rest)
        case AST.Binder{ _,  _,  _,  _,  _}: binder <> c_live_binders(rest)
        case AST.TemplateBinder{ _,  _,  _,  _}: c_live_binders(rest)

def c_foreign_alias_constructors(definitions: List<&2, CForeign.ForeignDefinition>) -> List<&2, IndexedConstructor>:
  match definitions:
    case Nil{}: Nil{}
    case +definition <> rest:
      match definition:
        case CForeign.ForeignDefinition{namespace, key, full_key, binders,  _,  _,  _}:
          IndexedConstructor{namespace, key, full_key,  c_live_binders(binders)} <> c_foreign_alias_constructors(rest)

def c_index_foreign(definition: CForeign.ForeignDefinition, span: AST.SourceSpan) -> IndexedDefinition:
  match definition:
    case CForeign.ForeignDefinition{namespace, key, full_key, binders, result, source_path,  _}:
      IndexedDefinition{namespace, key, full_key,  c_live_binders(binders), result,  AST.DefImports{ [source_path]},  False{}, span}

def c_index_foreigns(definitions: List<&2, CForeign.ForeignDefinition>, span: AST.SourceSpan) -> List<&2, IndexedDefinition>:
  match definitions:
    case Nil{}: Nil{}
    case +definition <> rest: c_index_foreign(definition, span) <> c_index_foreigns(rest, span)
def c_foreign_requests(definitions: List<&2, CForeign.ForeignDefinition>, constructors: List<&2, IndexedConstructor>, seen: List<&2, String>) -> String:
  match definitions:
    case Nil{}: ""
    case +definition <> rest:
      match definition:
        case CForeign.ForeignDefinition{namespace, _, _, _, _, source_path, source}:
          c_foreign_request_seen(c_foreign_seen(source_path, seen), namespace, source_path, source, rest, constructors, seen)

def c_foreign_request_seen(already_seen: Bool, namespace: String, source_path: String, source: String, rest: List<&2, CForeign.ForeignDefinition>, constructors: List<&2, IndexedConstructor>, seen: List<&2, String>) -> String:
  match already_seen:
    case True{}: c_foreign_requests(rest, constructors, seen)
    case False{}: c_foreign_request_prefix(String.is_empty(namespace), namespace, source_path, source, rest, constructors, seen)

def c_foreign_request_prefix(empty: Bool, namespace: String, source_path: String, source: String, rest: List<&2, CForeign.ForeignDefinition>, constructors: List<&2, IndexedConstructor>, seen: List<&2, String>) -> String:
  match empty:
    case True{}: c_foreign_request_source(".", source_path, source, rest, constructors, seen)
    case False{}: c_foreign_request_source(namespace ++ ".", source_path, source, rest, constructors, seen)

def c_foreign_request_source(prefix: String, source_path: String, source: String, rest: List<&2, CForeign.ForeignDefinition>, constructors: List<&2, IndexedConstructor>, seen: List<&2, String>) -> String:
  aliases = c_foreign_alias_open(constructors, prefix)
  closes = c_foreign_alias_close(constructors, prefix)
  String.concat([aliases, source, "\n", closes, c_foreign_requests(rest, constructors, source_path <> seen)])

def emit_parts(constructors: List<&2, IndexedConstructor>, foreigns: List<&2, CForeign.ForeignDefinition>, constant: MainConstant, requests: String) -> CParts.Parts:
  CParts.Parts{
     main_tables(constructors, foreigns, constant),
     main_spins(),
     main_segment(constant),
    requests
  }

def emit_main_runtime(runtime: String, constructors: List<&2, IndexedConstructor>, foreigns: List<&2, CForeign.ForeignDefinition>, constant: MainConstant, requests: String, span: AST.SourceSpan) -> EmitResult:
  emit_assembly_result(CAssembly.assemble(runtime, emit_parts(constructors, foreigns, constant, requests)), span)

def main_is_first_order(main: IndexedDefinition, functions: List<&2, IndexedDefinition>) -> Bool:
  match main:
    case IndexedDefinition{_, _, _, binders, AST.SomeTerm{result_type}, AST.DefTerm{term}, _, _}:
      main_is_first_order_binders(binders, String.is_empty(main_result_key(result_type)), term, main, functions)
    case _: False{}

def main_is_first_order_binders(binders: List<&2, AST.TelescopeItem>, empty_type: Bool, term: AST.SyntaxTerm, main: IndexedDefinition, functions: List<&2, IndexedDefinition>) -> Bool:
  match binders:
    case Nil{}: main_is_first_order_type(empty_type, term, main, functions)
    case _: False{}

def main_is_first_order_type(empty_type: Bool, term: AST.SyntaxTerm, main: IndexedDefinition, functions: List<&2, IndexedDefinition>) -> Bool:
  match empty_type:
    case True{}: False{}
    case False{}: main_is_first_order_expr(c_expr(term, functions, binder_count(c_live_binders_from_main(main))), term, main, functions)

def c_live_binders_from_main(main: IndexedDefinition) -> List<&2, AST.TelescopeItem>:
  match main:
    case IndexedDefinition{_, _, _, binders, _, _, _, _}: binders

def main_is_first_order_expr(expr: Maybe<&2, String>, term: AST.SyntaxTerm, main: IndexedDefinition, functions: List<&2, IndexedDefinition>) -> Bool:
  match expr:
    case Some{_}: True{}
    case None{}: main_is_first_order_bang(c_bang_call(term), term, main, functions)

def main_is_first_order_bang(found: Maybe<&2, BangCall>, term: AST.SyntaxTerm, main: IndexedDefinition, functions: List<&2, IndexedDefinition>) -> Bool:
  match found:
    case Some{BangCall{key, args}}: c_bang_supported(key, args, c_live_binders_from_main(main), functions)
    case None{}: main_is_first_order_split(c_split_bang(term), main, functions)

def main_is_first_order_split(found: Maybe<&2, BangSplit>, main: IndexedDefinition, functions: List<&2, IndexedDefinition>) -> Bool:
  match found:
    case Some{BangSplit{key, args, _, _}}: c_bang_supported(key, args, c_live_binders_from_main(main), functions)
    case None{}: c_match_definition_supported(main, functions)

def emit_loaded_book(book: CBook, runtime_path: String, foreigns: List<&2, CForeign.ForeignDefinition>) -> IO(EmitResult):
  do IO<EmitResult>:
    aliases = List.append(&2, IndexedConstructor, book.constructors, c_foreign_alias_constructors(foreigns))
    requests = c_foreign_requests(foreigns, aliases, Nil{})
    match book.main:
      case None{}: return EmitFailure{"no root main definition", source_span(book.main)}
      case Some{main}:
        emitted : EmitResult <- emit_loaded_book_constant(pure_constant_main(main, book.definitions), book, runtime_path, foreigns, requests)
        return emitted

def emit_loaded_book_constant(found: Maybe<&2, MainConstant>, book: CBook, runtime_path: String, foreigns: List<&2, CForeign.ForeignDefinition>, requests: String) -> IO(EmitResult):
  do IO<EmitResult>:
    match found:
      case Some{constant}:
        loaded : RuntimeReadResult <- read_runtime(runtime_path)
        return emit_loaded_book_constant_runtime(loaded, book, foreigns, constant, requests)
      case None{}:
        lifted_definitions = c_lift_definitions(book.definitions)
        emitted : EmitResult <- emit_loaded_book_main(find_main(lifted_definitions), lifted_definitions, book, runtime_path, foreigns, requests)
        return emitted

def emit_loaded_book_constant_runtime(loaded: RuntimeReadResult, book: CBook, foreigns: List<&2, CForeign.ForeignDefinition>, constant: MainConstant, requests: String) -> EmitResult:
  match loaded:
    case RuntimeReadFailure{message}: EmitFailure{String.append("unable to read C runtime: ", message), source_span(book.main)}
    case RuntimeReadSuccess{source}: emit_main_runtime(source, book.constructors, foreigns, constant, requests, source_span(book.main))

def emit_loaded_book_main(found: Maybe<&2, IndexedDefinition>, lifted_definitions: List<&2, IndexedDefinition>, book: CBook, runtime_path: String, foreigns: List<&2, CForeign.ForeignDefinition>, requests: String) -> IO(EmitResult):
  do IO<EmitResult>:
    match found:
      case None{}: return EmitFailure{"no root main definition", source_span(book.main)}
      case Some{lifted_main}:
        functions = dynamic_definitions(lifted_main, lifted_definitions, foreigns, source_span(book.main))
        emitted : EmitResult <- emit_loaded_book_dynamic(main_is_first_order(lifted_main, functions), lifted_main, book, runtime_path, foreigns, functions, requests)
        return emitted

def emit_loaded_book_dynamic(first_order: Bool, lifted_main: IndexedDefinition, book: CBook, runtime_path: String, foreigns: List<&2, CForeign.ForeignDefinition>, functions: List<&2, IndexedDefinition>, requests: String) -> IO(EmitResult):
  do IO<EmitResult>:
    match first_order:
      case False{}: return EmitFailure{"C emitter cannot lower this main outside the supported first-order Nat/U32 subset", source_span(book.main)}
      case True{}:
        loaded : RuntimeReadResult <- read_runtime(runtime_path)
        return emit_loaded_book_dynamic_runtime(loaded, book, lifted_main, foreigns, functions, requests)

def emit_loaded_book_dynamic_runtime(loaded: RuntimeReadResult, book: CBook, lifted_main: IndexedDefinition, foreigns: List<&2, CForeign.ForeignDefinition>, functions: List<&2, IndexedDefinition>, requests: String) -> EmitResult:
  match loaded:
    case RuntimeReadFailure{message}: EmitFailure{String.append("unable to read C runtime: ", message), source_span(book.main)}
    case RuntimeReadSuccess{source}:
      emit_dynamic_runtime(source, book.types, book.constructors, foreigns, functions, lifted_main, requests, source_span(book.main))

def emit(modules: List<&2, Loader.LoadedModule>, runtime_path: String) -> IO(EmitResult):
  do IO<EmitResult>:
    book = index_book(modules)
    loaded : CForeign.LoadResult <- CForeign.load(modules)
    match loaded:
      case CForeign.LoadFailure{file, span, message}:
        return EmitFailure{message, span}
      case CForeign.LoadSuccess{definitions}:
        emitted : EmitResult <- emit_loaded_book(book, runtime_path, definitions)
        return emitted




def index_constructors(namespace: String, constructors: List<&2, AST.ConstructorDecl>) -> List<&2, IndexedConstructor>:
  match constructors:
    case Nil{}: Nil{}
    case +constructor <> rest:
      match constructor:
        case AST.Constructor{key, fields,  _}:
          IndexedConstructor{namespace, key,  qualify(namespace, key), fields} <> index_constructors(namespace, rest)

def index_declaration(namespace: String, declaration: AST.TopLevel) -> List<&2, IndexedDefinition>:
  match declaration:
    case AST.DefTop{definition}:
      match definition:
        case AST.Definition{key, binders, result, body, unsafe, span}:
          [IndexedDefinition{namespace, key,  qualify(namespace, key), binders, result, body, unsafe, span}]
    case _: Nil{}

def index_declarations(namespace: String, declarations: List<&2, AST.TopLevel>) -> List<&2, IndexedDefinition>:
  match declarations:
    case Nil{}: Nil{}
    case +declaration <> rest:
      List.append(&2, IndexedDefinition, index_declaration(namespace, declaration), index_declarations(namespace, rest))

def constructors_declaration(namespace: String, declaration: AST.TopLevel) -> List<&2, IndexedConstructor>:
  match declaration:
    case AST.TypeTop{ AST.TypeDecl{ _,  _,  _, constructors,  _}}:
      index_constructors(namespace, constructors)
    case _: Nil{}

def constructors_declarations(namespace: String, declarations: List<&2, AST.TopLevel>) -> List<&2, IndexedConstructor>:
  match declarations:
    case Nil{}: Nil{}
    case +declaration <> rest:
      List.append(&2, IndexedConstructor, constructors_declaration(namespace, declaration), constructors_declarations(namespace, rest))
def type_declaration(namespace: String, declaration: AST.TopLevel) -> List<&2, IndexedType>:
  match declaration:
    case AST.TypeTop{ AST.TypeDecl{key, params, kind, constructors, span}}:
      [IndexedType{namespace, key,  qualify(namespace, key), params, kind, constructors, span}]
    case _: Nil{}

def types_declarations(namespace: String, declarations: List<&2, AST.TopLevel>) -> List<&2, IndexedType>:
  match declarations:
    case Nil{}: Nil{}
    case +declaration <> rest:
      List.append(&2, IndexedType, type_declaration(namespace, declaration), types_declarations(namespace, rest))


def index_modules(modules: List<&2, Loader.LoadedModule>, definitions: List<&2, IndexedDefinition>, types: List<&2, IndexedType>, constructors: List<&2, IndexedConstructor>) -> CBook:
  match modules:
    case Nil{}:
      CBook{definitions, types, constructors,  find_main(definitions)}
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{namespace,  AST.Module{ _,  _, declarations}}:
          next_definitions = List.append(&2, IndexedDefinition, definitions, index_declarations(namespace, declarations))
          next_types = List.append(&2, IndexedType, types, types_declarations(namespace, declarations))
          next_constructors = List.append(&2, IndexedConstructor, constructors, constructors_declarations(namespace, declarations))
          index_modules(rest, next_definitions, next_types, next_constructors)

def index_book(modules: List<&2, Loader.LoadedModule>) -> CBook:
  index_modules(modules, Nil{}, Nil{}, Nil{})

def find_main(definitions: List<&2, IndexedDefinition>) -> Maybe<&2, IndexedDefinition>:
  match definitions:
    case Nil{}: None{}
    case +definition <> rest:
      match definition:
        case IndexedDefinition{namespace, key, _, _, _, _, _, _}:
          find_main_namespace(String.eq(namespace, ""), String.eq(key, "main"), definition, rest)

def find_main_namespace(global: Bool, is_main: Bool, definition: IndexedDefinition, rest: List<&2, IndexedDefinition>) -> Maybe<&2, IndexedDefinition>:
  match global:
    case True{}: find_main_key(is_main, definition, rest)
    case False{}: find_main(rest)

def find_main_key(is_main: Bool, definition: IndexedDefinition, rest: List<&2, IndexedDefinition>) -> Maybe<&2, IndexedDefinition>:
  match is_main:
    case True{}: Some{definition}
    case False{}: find_main(rest)
def read_runtime(path: String) -> IO(RuntimeReadResult):
  do IO<RuntimeReadResult>:
    opened : Result<&1, &1, U32 & String, File> <- File.open(path, "r")
    match opened:
      case Done{file}:
        sized : File & Result<&1, &1, U32 & String, U32> <- File.size(file)
        (file, size_result) = sized
        match size_result:
          case Done{size}:
            loaded : File & Result<&1, &1, U32 & String, String> <- File.read(file, size)
            (file, read_result) = loaded
            match read_result:
              case Done{source}:
                Unit <- File.close(file)
                return RuntimeReadSuccess{source}
              case Fail{error}:
                (code, message) = error
                Unit <- File.close(file)
                return RuntimeReadFailure{ U32.show(code) ++ " " ++ message}
          case Fail{error}:
            (code, message) = error
            Unit <- File.close(file)
            return RuntimeReadFailure{ U32.show(code) ++ " " ++ message}
      case Fail{error}:
        (code, message) = error
        return RuntimeReadFailure{ U32.show(code) ++ " " ++ message}

