import Base
import ./ast.bend as AST
import ./path.bend as Path
import ./loaded_module.bend as Loader

type EmitResult is Data:
  EmitSuccess{source: String}
  EmitFailure{message: String, span: AST.SourceSpan}

def js_escape_char(char: Char) -> String:
  match char:
    case '\"': "\\\""
    case '\\': "\\\\"
    case '\n': "\\n"
    case '\r': "\\r"
    case '\t': "\\t"
    case '\u{0}': "\\u0000"
    case _: String.from_list([char])

def js_comma_prefix(first: Bool) -> String:
  match first:
    case True{}: ""
    case False{}: ","

def js_quote_chars(chars: List<&2, Char>, acc: String) -> String:
  match chars:
    case Nil{}: String.append(acc, "\"")
    case +char <> rest:
      escaped = js_escape_char(char)
      js_quote_chars(rest, String.append(acc, escaped))

def js_quote(text: String) -> String:
  js_quote_chars(String.to_list(text), "\"")


def env_at(env: List<&2, String>, index: Nat) -> String:
  match env:
    case Nil{}: "undefined"
    case +name <> rest:
      match index:
        case 0n: name
        case _: env_at(rest, index - 1n)

def env_push(name: String, env: List<&2, String>) -> List<&2, String>:
  name <> env


def js_term_args(args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  match args:
    case Nil{}: ""
    case +arg <> rest:
      match rest:
        case Nil{}: js_term(arg, env)
        case _: String.append(js_term(arg, env), String.append(", ", js_term_args(rest, env)))


def js_choose(key: String, suffix: String, expression: String, other: String) -> String:
  js_choose_result(String.ends_with(key, suffix), expression, other)

def js_choose_result(matches: Bool, expression: String, other: String) -> String:
  match matches:
    case True{}: expression
    case False{}: other
def js_reference(key: String) -> String:
  js_reference_select(key, js_is_native(key))

def js_reference_select(key: String, native: Bool) -> String:
  match native:
    case True{}: js_reference_old(key)
    case False{}: String.append("$resolve(", String.append(js_quote(key), ", $scope, $aliases)"))

def suffix_any(key: String, first: String, rest: String) -> Bool:
  Bool.or(String.ends_with(key, first), String.ends_with(key, rest))

def js_native_u32(key: String) -> Bool:
  Bool.or(js_native_u32_1(key), js_native_u32_2(key))
def js_native_u32_1(key: String) -> Bool:
  Bool.or(suffix_any(key, "u32_add", "u32_sub"), Bool.or(suffix_any(key, "u32_mul", "u32_div"), Bool.or(suffix_any(key, "u32_mod", "u32_and"), Bool.or(suffix_any(key, "u32_or", "u32_xor"), Bool.or(suffix_any(key, "u32_is_eq", "u32_is_ne"), suffix_any(key, "u32_is_lt", "u32_is_le"))))))

def js_native_u32_2(key: String) -> Bool:
  Bool.or(suffix_any(key, "u32_is_gt", "u32_is_ge"), Bool.or(suffix_any(key, "u32_inc", "u32_not"), Bool.or(suffix_any(key, "u32_shl", "u32_shr"), Bool.or(suffix_any(key, "u32_shln", "u32_shrn"), Bool.or(suffix_any(key, "u32_cmp", "u32_is_zero"), Bool.or(suffix_any(key, "u32_to_nat", "u32_from_nat"), suffix_any(key, "u32_to_f32", "u32_to_f32")))))))

def js_native_f32(key: String) -> Bool:
  Bool.or(js_native_f32_1(key), js_native_f32_2(key))
def js_native_f32_1(key: String) -> Bool:
  Bool.or(suffix_any(key, "f32_add", "f32_sub"), Bool.or(suffix_any(key, "f32_mul", "f32_div"), Bool.or(suffix_any(key, "f32_mod", "f32_neg"), Bool.or(suffix_any(key, "f32_is_eq", "f32_is_ne"), Bool.or(suffix_any(key, "f32_is_lt", "f32_is_le"), Bool.or(suffix_any(key, "f32_is_gt", "f32_is_ge"), Bool.or(suffix_any(key, "f32_sqrt", "f32_abs"), suffix_any(key, "f32_exp", "f32_log"))))))))

def js_native_f32_2(key: String) -> Bool:
  Bool.or(suffix_any(key, "f32_log2", "f32_log10"), Bool.or(suffix_any(key, "f32_sin", "f32_cos"), Bool.or(suffix_any(key, "f32_tan", "f32_pow"), Bool.or(suffix_any(key, "f32_atan2", "f32_floor"), Bool.or(suffix_any(key, "f32_ceil", "f32_trunc"), Bool.or(suffix_any(key, "f32_to_u32", "f32_bits"), Bool.or(suffix_any(key, "f32_show", "f32_read"), Bool.or(suffix_any(key, "u32_to_f32", "u32_to_f32"), js_native_f32_extra(key)))))))))
def js_native_f32_extra(key: String) -> Bool:
  Bool.or(suffix_any(key, "f32_asin", "f32_acos"), Bool.or(suffix_any(key, "f32_atan", "f32_sinh"), suffix_any(key, "f32_cosh", "f32_tanh")))

def js_native_misc(key: String) -> Bool:
  Bool.or(js_native_misc_1(key), js_native_misc_2(key))
def js_native_misc_1(key: String) -> Bool:
  Bool.or(suffix_any(key, "nat_add", "nat_sub"), Bool.or(suffix_any(key, "nat_mul", "nat_double"), Bool.or(suffix_any(key, "nat_cmp", "nat_is_lt"), Bool.or(suffix_any(key, "nat_divmod", "string_append"), suffix_any(key, "string_length", "bool_or")))))

def js_native_misc_2(key: String) -> Bool:
  Bool.or(suffix_any(key, "bool_xor", "array_new"), Bool.or(suffix_any(key, "array_set", "array_get"), Bool.or(suffix_any(key, "array_swap", "array_size"), suffix_any(key, "array_clone", "array_clone"))))

def js_is_native(key: String) -> Bool:
  Bool.or(js_native_u32(key), Bool.or(js_native_f32(key), js_native_misc(key)))

def js_reference_old(key: String) -> String:
  js_choose(key, "u32_add", "(a)=>(b)=>((a+b)>>>0)", js_reference_2(key))

def js_reference_2(key: String) -> String:
  js_choose(key, "u32_sub", "(a)=>(b)=>((a-b)>>>0)", js_reference_3(key))

def js_reference_3(key: String) -> String:
  js_choose(key, "u32_mul", "(a)=>(b)=>(Math.imul(a,b)>>>0)", js_reference_4(key))

def js_reference_4(key: String) -> String:
  js_choose(key, "u32_div", "(a)=>(b)=>(b===0?0:(a/b)>>>0)", js_reference_5(key))

def js_reference_5(key: String) -> String:
  js_choose(key, "nat_add", "(a)=>(b)=>nat_chk(a+b)", js_reference_6(key))

def js_reference_6(key: String) -> String:
  js_choose(key, "nat_sub", "(a)=>(b)=>(a<b?0n:a-b)", js_reference_7(key))

def js_reference_7(key: String) -> String:
  js_choose(key, "nat_mul", "(a)=>(b)=>nat_chk(a*b)", js_reference_8(key))

def js_reference_8(key: String) -> String:
  js_choose(key, "nat_cmp", "(a)=>(b)=>cmp_new(a,b)", js_reference_9(key))

def js_reference_9(key: String) -> String:
  js_choose(key, "string_append", "(a)=>(b)=>a+b", js_reference_10(key))

def js_reference_10(key: String) -> String:
  js_choose(key, "bool_or", "(a)=>(b)=>a||b", js_reference_11(key))

def js_reference_11(key: String) -> String:
  js_choose(key, "bool_xor", "(a)=>(b)=>a!==b", js_reference_12(key))

def js_reference_12(key: String) -> String:
  js_choose(key, "u32_is_zero", "(a)=>a===0", js_reference_more(key))


def js_reference_more(key: String) -> String:
  js_ref_f32_extra(key)

def js_ref_f32_extra(key: String) -> String:
  js_choose(key, "f32_asin", "(a)=>Math.fround(Math.asin(a))", js_choose(key, "f32_acos", "(a)=>Math.fround(Math.acos(a))", js_choose(key, "f32_atan", "(a)=>Math.fround(Math.atan(a))", js_choose(key, "f32_sinh", "(a)=>Math.fround(Math.sinh(a))", js_choose(key, "f32_cosh", "(a)=>Math.fround(Math.cosh(a))", js_choose(key, "f32_tanh", "(a)=>Math.fround(Math.tanh(a))", js_ref_array(key)))))))

def js_ref_u32(key: String) -> String:
  js_choose(key, "u32_mod", "(a)=>(b)=>(b===0?a:a%b)", js_choose(key, "u32_and", "(a)=>(b)=>((a&b)>>>0)", js_choose(key, "u32_or", "(a)=>(b)=>((a|b)>>>0)", js_choose(key, "u32_xor", "(a)=>(b)=>((a^b)>>>0)", js_choose(key, "u32_is_eq", "(a)=>(b)=>a===b", js_choose(key, "u32_is_ne", "(a)=>(b)=>a!==b", js_choose(key, "u32_is_lt", "(a)=>(b)=>a<b", js_choose(key, "u32_is_le", "(a)=>(b)=>a<=b", js_ref_u32_2(key)))))))))

def js_ref_u32_2(key: String) -> String:
  js_choose(key, "u32_is_gt", "(a)=>(b)=>a>b", js_choose(key, "u32_is_ge", "(a)=>(b)=>a>=b", js_ref_u32_3(key)))

def js_ref_u32_3(key: String) -> String:
  js_choose(key, "u32_inc", "(a)=>(a+1)>>>0", js_choose(key, "u32_not", "(a)=>(~a)>>>0", js_choose(key, "u32_shl", "(a)=>(a<<1)>>>0", js_choose(key, "u32_shr", "(a)=>a>>>1", js_choose(key, "u32_shln", "(a)=>(b)=>b>=32?0:(a<<Number(b))>>>0", js_choose(key, "u32_shrn", "(a)=>(b)=>b>=32?0:a>>>Number(b)", js_choose(key, "u32_cmp", "(a)=>(b)=>cmp_new(a,b)", js_choose(key, "u32_to_nat", "(a)=>BigInt(a)", js_choose(key, "u32_from_nat", "(a)=>Number(a&0xFFFFFFFFn)", js_ref_nat(key))))))))))
def js_ref_f32(key: String) -> String:
  js_choose(key, "f32_add", "(a)=>(b)=>Math.fround(a+b)", js_choose(key, "f32_sub", "(a)=>(b)=>Math.fround(a-b)", js_choose(key, "f32_mul", "(a)=>(b)=>Math.fround(a*b)", js_choose(key, "f32_div", "(a)=>(b)=>Math.fround(a/b)", js_choose(key, "f32_mod", "(a)=>(b)=>Math.fround(a%b)", js_choose(key, "f32_neg", "(a)=>-a", js_choose(key, "f32_sqrt", "(a)=>Math.fround(Math.sqrt(a))", js_choose(key, "f32_abs", "(a)=>Math.fround(Math.abs(a))", js_ref_f32_2(key)))))))))

def js_ref_f32_2(key: String) -> String:
  js_choose(key, "f32_to_u32", "(a)=>(a>=1&&a<4294967296?Math.floor(a):0)", js_choose(key, "f32_bits", "(a)=>f32_bits(a)", js_choose(key, "f32_show", "(a)=>f32_show(a)", js_choose(key, "f32_read", "(a)=>f32_read(a)", js_ref_f32_3(key)))))

def js_ref_f32_3(key: String) -> String:
  js_choose(key, "f32_is_eq", "(a)=>(b)=>a===b", js_choose(key, "f32_is_ne", "(a)=>(b)=>a!==b", js_choose(key, "f32_is_lt", "(a)=>(b)=>a<b", js_choose(key, "f32_is_le", "(a)=>(b)=>a<=b", js_choose(key, "f32_is_gt", "(a)=>(b)=>a>b", js_choose(key, "f32_is_ge", "(a)=>(b)=>a>=b", js_choose(key, "f32_pow", "(a)=>(b)=>Math.fround(Math.pow(a,b))", js_choose(key, "f32_atan2", "(a)=>(b)=>Math.fround(Math.atan2(a,b))", js_choose(key, "f32_exp", "(a)=>Math.fround(Math.exp(a))", js_choose(key, "f32_log", "(a)=>Math.fround(Math.log(a))", js_choose(key, "f32_log2", "(a)=>Math.fround(Math.log2(a))", js_choose(key, "f32_log10", "(a)=>Math.fround(Math.log10(a))", js_choose(key, "f32_sin", "(a)=>Math.fround(Math.sin(a))", js_choose(key, "f32_cos", "(a)=>Math.fround(Math.cos(a))", js_choose(key, "f32_tan", "(a)=>Math.fround(Math.tan(a))", js_choose(key, "f32_floor", "(a)=>Math.fround(Math.floor(a))", js_choose(key, "f32_ceil", "(a)=>Math.fround(Math.ceil(a))", js_choose(key, "f32_trunc", "(a)=>Math.fround(Math.trunc(a))", js_choose(key, "f32_to_nat", "(a)=>BigInt(Math.floor(a))", js_choose(key, "u32_to_f32", "(a)=>Math.fround(a)", String.append("$D[", String.append(js_quote(key), "]"))))))))))))))))))))))
def js_ref_nat(key: String) -> String:
  js_choose(key, "nat_double", "(a)=>nat_chk(a<<1n)", js_choose(key, "nat_is_lt", "(a)=>(b)=>a<b", js_choose(key, "nat_divmod", "(a)=>(b)=>nat_divmod(a,b)", String.append("$D[", String.append(js_quote(key), "]")))))
def js_ref_array(key: String) -> String:
  js_choose(key, "string_length", "(a)=>BigInt([...a].length)", js_choose(key, "array_new", "(a)=>(b)=>array_new(a,b)", js_choose(key, "array_set", "(a)=>(i)=>(v)=>(a[i%a.length]=v,a)", js_choose(key, "array_get", "(a)=>(i)=>tuple(a,a[i%a.length])", js_choose(key, "array_swap", "(a)=>(i)=>(v)=>array_swap(a,i,v)", js_choose(key, "array_size", "(a)=>tuple(a,a.length)", js_choose(key, "array_clone", "(a)=>tuple(a,a.slice())", js_ref_u32(key))))))))

def js_term(term: AST.SyntaxTerm, env: List<&2, String>) -> String:
  match term:
    case AST.TermVar{ _, index,  _}: env_at(env, index)
    case AST.TermRef{key,  _}: js_reference(key)

    case AST.TermSub{index, value, body,  _}: js_term_sub(index, value, body, env)
    case AST.TermLet{keys,  _, quantities, values, body,  _}:
      js_term_let(keys, quantities, values, body, env, 0n)
    case AST.TermType{ _,  _}: "null"
    case AST.TermQuant{}: "null"
    case AST.TermQuantity{ _,  _}: "null"
    case AST.TermMin{ _,  _,  _}: "null"
    case AST.TermAll{ _,  _,  _,  _,  _,  _}: "null"
    case AST.TermLam{ _,  _,  _, body,  _}:
      String.append("(($x) => ", String.append(js_term(body, env_push("$x", env)), ")"))
    case AST.TermAnn{term,  _,  _}: js_term(term, env)
    case AST.TermBang{ AST.TermRef{key,  _},  _}: js_reference(key)
    case AST.TermBang{ _,  _}: "(()=>{throw \"bend: bang head must be a named reference\"})()"
    case AST.TermFill{head,  _,  _}: js_term(head, env)
    case AST.TermPlus{head,  _,  _}: js_term(head, env)
    case AST.TermApp{ _,  _,  _}: js_app_spine(term, env)
    case AST.TermAdt{ _,  _,  _,  _}: "null"
    case AST.TermCtr{key, args,  _}: js_constructor(key, args, env)
    case AST.TermMat{ _, head, matched,  _}: js_match(head, matched, env)
    case AST.TermAbsurd{span}: "(()=>{throw \"bend: runtime fail-stop\"})()"
    case AST.TermEqual{ _,  _,  _,  _}: "null"
    case AST.TermRefl{ _}: "null"
    case AST.TermRewrite{ _,  _, body,  _}: js_term(body, env)
    case AST.TermHole{key, span}: String.append("(()=>{throw ", String.append(js_quote(String.append("bend: unsolved hole ", key)), "})()"))
    case AST.BodyReply{term,  _}: js_term(term, env)
    case AST.BodyLocal{patterns,  _, values, body, span}:
      js_body_match(values, [AST.BodyCase{patterns, body, span}], env)
    case AST.BodyCase{ _, body,  _}: js_term(body, env)
    case AST.BodyMatch{scrutinees, cases, span}:
      js_body_match(scrutinees, cases, env)

def js_app_spine(term: AST.SyntaxTerm, env: List<&2, String>) -> String:
  js_app_spine_result(js_app_spine_at(term, Nil{}), env)

def js_app_spine_result(spine: AST.SyntaxTerm & List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  match spine:
    case (head, reversed_args):
      js_app_dispatch(head, List.reverse(&2, AST.SyntaxTerm, reversed_args), env)

def js_app_dispatch(head: AST.SyntaxTerm, args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  match head:
    case AST.TermBang{ AST.TermRef{key,  _},  _}:
      js_app_chain(js_reference(key), args, env)
    case AST.TermBang{ _,  _}: "(()=>{throw \"bend: bang head must be a named reference\"})()"
    case _: js_app_chain(js_term(head, env), args, env)
def js_app_spine_at(term: AST.SyntaxTerm, args: List<&2, AST.SyntaxTerm>) -> AST.SyntaxTerm & List<&2, AST.SyntaxTerm>:
  match term:
    case AST.TermApp{fn, arg,  _}: js_app_spine_at(fn, arg <> args)
    case _: (term & args)
def js_app_chain(fn: String, args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  match args:
    case Nil{}: fn
    case +arg <> rest: js_app_chain(js_app_source(fn, arg, env), rest, env)
def js_app_source(fn: String, arg: AST.SyntaxTerm, env: List<&2, String>) -> String:
  match arg:
    case AST.TermAnn{term,  _,  _}: js_app_source(fn, term, env)
    case AST.TermTemplate{ _,  _}: "(()=>{throw \"bend: unexpanded template\"})()"
    case AST.TermType{ _,  _}: fn
    case AST.TermQuant{}: fn
    case AST.TermQuantity{ _,  _}: fn
    case AST.TermAll{ _,  _,  _,  _,  _,  _}: fn
    case AST.TermAdt{ _,  _,  _,  _}: fn
    case AST.TermEqual{ _,  _,  _,  _}: fn
    case AST.TermFill{ _,  _,  _}: fn
    case AST.TermPlus{ AST.TermRef{key,  _},  _,  _}: js_plus_app_source(fn, key)
    case AST.TermPlus{ AST.TermAdt{key,  _,  _,  _},  _,  _}: js_plus_app_source(fn, key)
    case AST.TermPlus{ AST.TermApp{ AST.TermRef{key,  _},  _,  _},  _,  _}: js_plus_app_source(fn, key)
    case AST.TermPlus{ AST.TermApp{ AST.TermAdt{key,  _,  _,  _},  _,  _},  _,  _}: js_plus_app_source(fn, key)
    case AST.TermRefl{ _}: fn
    case _: String.append("(", String.append(fn, String.append(")(", String.append(js_term(arg, env), ")"))))
def js_plus_app_source(fn: String, key: String) -> String:
  String.append("(($f)=>$PARAMS[$key(", String.append(js_quote(key), String.append(",$scope,$aliases)]?$f:$f($resolve(", String.append(js_quote(key), String.append(",$scope,$aliases))))(", String.append(fn, ")"))))))
def env_insert(env: List<&2, String>, index: Nat, name: String) -> List<&2, String>:
  match env:
    case Nil{}: [name]
    case +value <> rest:
      match index:
        case 0n: name <> (value <> rest)
        case _: value <> env_insert(rest, index - 1n, name)

def js_term_sub(index: Nat, value: AST.SyntaxTerm, body: AST.SyntaxTerm, env: List<&2, String>) -> String:
  name = "$sub"
  String.append("((", String.append(name, String.append(") => ", String.append(js_term(body, env_insert(env, index, name)), String.append(")(", String.append(js_term(value, env), ")"))))))
def js_term_let(keys: List<&2, String>, quantities: List<&2, AST.Quantity>, values: List<&2, AST.SyntaxTerm>, body: AST.SyntaxTerm, env: List<&2, String>, index: Nat) -> String:
  match keys quantities values:
    case Nil{} Nil{} Nil{}: js_term(body, env)
    case +key <> more_keys AST.QZero{} <> more_quantities +_ <> more_values:
      js_term_let(more_keys, more_quantities, more_values, body, env_push("null", env), index + 1n)
    case +key <> more_keys +quantity <> more_quantities +value <> more_values:
      name = String.append("$l", Nat.show(index))
      String.append("((", String.append(name, String.append(") => ", String.append(js_term_let(more_keys, more_quantities, more_values, body, env_push(name, env), index + 1n), String.append(")(", String.append(js_term(value, env), ")"))))))

def js_constructor(key: String, args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  js_choose(key, "Nat.Zero", "0n", js_constructor_2(key, args, env))

def js_constructor_2(key: String, args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  js_choose(key, "Bool.False", "false", js_constructor_3(key, args, env))

def js_constructor_3(key: String, args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  js_choose(key, "Bool.True", "true", js_constructor_4(key, args, env))

def js_constructor_4(key: String, args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  js_choose(key, "String.SNil", "\"\"", js_constructor_5(key, args, env))

def js_constructor_5(key: String, args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  js_choose(key, "Nat.Succ", js_constructor_nat_succ(args, env), js_constructor_6(key, args, env))

def js_constructor_nat_succ(args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  match args:
    case +arg <> _: String.append("nat_chk(", String.append(js_term(arg, env), " + 1n)"))
    case Nil{}: "0n"

def js_constructor_6(key: String, args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  js_choose(key, "Char.Chr", js_constructor_char(args, env), js_constructor_7(key, args, env))

def js_constructor_char(args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  match args:
    case +arg <> _: String.append("char_new(", String.append(js_term(arg, env), ")"))
    case Nil{}: "\"\\0\""

def js_constructor_7(key: String, args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  js_choose(key, "String.SCon", js_constructor_string(args, env), js_constructor_8(key, args, env))

def js_constructor_string(args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  match args:
    case +head <> +tail <> _:
      String.append("(", String.append(js_term(head, env), String.append(" + ", String.append(js_term(tail, env), ")"))))
    case _: "\"\""

def js_constructor_8(key: String, args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  js_choose(key, "U32.U32", js_constructor_u32(args, env), js_constructor_9(key, args, env))

def js_constructor_u32(args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  match args:
    case +arg <> _: String.append("word_to_u32(", String.append(js_term(arg, env), ")"))
    case Nil{}: "0"

def js_constructor_9(key: String, args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  js_choose(key, "F32.F32", js_constructor_f32(args, env), js_constructor_data(key, args, env))

def js_constructor_f32(args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  match args:
    case +arg <> _: String.append("f32_from_bits(word_to_u32(", String.append(js_term(arg, env), "))"))
    case Nil{}: "0"

def js_constructor_data(key: String, args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  js_choose(key, "Array.ALeaf", js_constructor_leaf(args, env), js_constructor_data_2(key, args, env))

def js_constructor_leaf(args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  match args:
    case +arg <> _: String.append("[", String.append(js_term(arg, env), "]"))
    case Nil{}: "[]"

def js_constructor_data_2(key: String, args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  js_choose(key, "Array.ANode", js_constructor_node(args, env), js_constructor_data_3(key, args, env))

def js_constructor_node(args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  match args:
    case +left <> +right <> _: String.append("array_node(", String.append(js_term(left, env), String.append(", ", String.append(js_term(right, env), ")"))))
    case _: "[]"

def js_constructor_data_3(key: String, args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  js_choose(key, "Tuple", js_constructor_tuple(args, env), js_constructor_data_4(key, args, env))

def js_constructor_tuple(args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  match args:
    case +fst <> +snd <> _: String.append("({$: \"Tuple\", args: [", String.append(js_term(fst, env), String.append(", ", String.append(js_term(snd, env), "], get fst() { return this.args[0]; }, get snd() { return this.args[1]; }})"))))
    case _: "({$: \"Tuple\"})"

def js_constructor_data_4(key: String, args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  js_choose(key, "Some", js_constructor_some(args, env), js_constructor_data_5(key, args, env))

def js_constructor_some(args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  match args:
    case +value <> _: String.append("({$: \"Some\", args: [", String.append(js_term(value, env), "], get value() { return this.args[0]; }})"))
    case Nil{}: "({$: \"Some\"})"

def js_constructor_data_5(key: String, args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  js_choose(key, "Cons", js_constructor_cons(args, env), js_constructor_data_6(key, args, env))

def js_constructor_cons(args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  match args:
    case +head <> +tail <> _: String.append("({$: \"Cons\", args: [", String.append(js_term(head, env), String.append(", ", String.append(js_term(tail, env), "], get head() { return this.args[0]; }, get tail() { return this.args[1]; }})"))))
    case _: "({$: \"Cons\"})"

def js_constructor_data_6(key: String, args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  js_choose(key, "WCon", js_constructor_wcon(args, env), js_constructor_data_7(key, args, env))

def js_constructor_wcon(args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  match args:
    case +head <> +tail <> _: String.append("({$: \"WCon\", args: [", String.append(js_term(head, env), String.append(", ", String.append(js_term(tail, env), "], get head() { return this.args[0]; }, get tail() { return this.args[1]; }})"))))
    case _: "({$: \"WCon\"})"

def js_constructor_data_7(key: String, args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  js_choose(key, "Done", js_constructor_done(args, env), js_constructor_generic(key, args, env))

def js_constructor_done(args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  match args:
    case +value <> _: String.append("({$: \"Done\", args: [", String.append(js_term(value, env), "], get value() { return this.args[0]; }})"))
    case Nil{}: "({$: \"Done\"})"

def js_constructor_generic(key: String, args: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  String.append("$ctr(", String.append(js_quote(key), String.append(", [", String.append(js_term_args(args, env), "], $scope, $aliases)"))))
def ctor_short(key: String) -> String:
  ctor_short_chars(List.reverse(&2, Char, String.to_list(key)), key)

def ctor_short_chars(reversed_key: List<&2, Char>, key: String) -> String:
  match reversed_key:
    case Nil{}: key
    case +_ <> reversed:
      ctor_suffix(List.reverse(&2, Char, reversed))

def ctor_suffix(chars: List<&2, Char>) -> String:
  match chars:
    case Nil{}: ""
    case +char <> rest:
      match char:
        case '.': String.from_list(rest)
        case '/': String.from_list(rest)
        case _: String.append(String.from_list([char]), ctor_suffix(rest))

def js_match(head: AST.SyntaxTerm, matched: AST.SyntaxTerm, env: List<&2, String>) -> String:
  String.append("(()=>{const $v=", String.append(js_term(matched, env), String.append("; return ", String.append(js_term(head, env_push("$v", env)), ";})()"))))

def js_local(values: List<&2, AST.SyntaxTerm>, body: AST.SyntaxTerm, env: List<&2, String>) -> String:
  match values:
    case Nil{}: js_term(body, env)
    case +value <> rest:
      name = "$local"
      String.append("((", String.append(name, String.append(") => ", String.append(js_local(rest, body, env_push(name, env)), String.append(")(", String.append(js_term(value, env), ")"))))))

def pattern_test(pattern: AST.SyntaxPattern, value: String) -> String:
  match pattern:
    case AST.PatternVar{ _,  _,  _,  _}: "true"
    case AST.PatternCtr{key, fields,  _}: pattern_test_ctor(key, fields, value)

def pattern_test_ctor(key: String, fields: List<&2, AST.SyntaxPattern>, value: String) -> String:
  js_choose(key, "Bool.True", String.append("(", String.append(value, " === true)")), pattern_test_ctor_2(key, fields, value))

def pattern_test_ctor_2(key: String, fields: List<&2, AST.SyntaxPattern>, value: String) -> String:
  js_choose(key, "Bool.False", String.append("(", String.append(value, " === false)")), pattern_test_ctor_3(key, fields, value))

def pattern_test_ctor_3(key: String, fields: List<&2, AST.SyntaxPattern>, value: String) -> String:
  js_choose(key, "Nat.Zero", String.append("(", String.append(value, " === 0n)")), pattern_test_ctor_4(key, fields, value))

def pattern_test_ctor_4(key: String, fields: List<&2, AST.SyntaxPattern>, value: String) -> String:
  js_choose(key, "Nat.Succ", String.append("(", String.append(value, String.append(" > 0n && ", pattern_fields_test(fields, String.append("(", String.append(value, " - 1n)")), 0n)))), pattern_test_ctor_5(key, fields, value))

def pattern_test_ctor_5(key: String, fields: List<&2, AST.SyntaxPattern>, value: String) -> String:
  js_choose(key, "String.SNil", String.append("(", String.append(value, " === \"\")")), pattern_test_ctor_6(key, fields, value))

def pattern_test_ctor_6(key: String, fields: List<&2, AST.SyntaxPattern>, value: String) -> String:
  js_choose(key, "String.SCon", String.append("(", String.append(value, " !== \"\")")), pattern_test_ctor_7(key, fields, value))

def pattern_test_ctor_7(key: String, fields: List<&2, AST.SyntaxPattern>, value: String) -> String:
  js_choose(key, "U32.U32", pattern_fields_test(fields, String.append("u32_to_word(", String.append(value, ")")), 0n), pattern_test_ctor_8(key, fields, value))

def pattern_test_ctor_8(key: String, fields: List<&2, AST.SyntaxPattern>, value: String) -> String:
  js_choose(key, "F32.F32", pattern_fields_test(fields, String.append("u32_to_word(f32_bits(", String.append(value, "))")), 0n), pattern_test_ctor_9(key, fields, value))

def pattern_test_ctor_9(key: String, fields: List<&2, AST.SyntaxPattern>, value: String) -> String:
  js_choose(key, "Array.ALeaf", String.append("(", String.append(value, ".length === 1)")), pattern_test_ctor_10(key, fields, value))

def pattern_test_ctor_10(key: String, fields: List<&2, AST.SyntaxPattern>, value: String) -> String:
  js_choose(key, "Array.ANode", String.append("(", String.append(value, ".length !== 1)")), String.append("(", String.append(value, String.append(" && ", String.append(value, String.append(".$ === ", String.append(js_quote(ctor_short(key)), String.append(" && ", pattern_fields_test(fields, value, 0n)))))))))
def pattern_fields_test(fields: List<&2, AST.SyntaxPattern>, value: String, index: Nat) -> String:
  match fields:
    case Nil{}: "true"
    case +field <> rest:
      field_value = String.append(value, String.append(".args[", String.append(Nat.show(index), "]")))
      String.append("(", String.append(pattern_test(field, field_value), String.append(" && ", pattern_fields_test(rest, value, index + 1n))))

def patterns_test(patterns: List<&2, AST.SyntaxPattern>, values: List<&2, String>) -> String:
  match patterns values:
    case Nil{} Nil{}: "true"
    case +pattern <> more_patterns +value <> more_values:
      String.append("(", String.append(pattern_test(pattern, value), String.append(" && ", patterns_test(more_patterns, more_values))))
    case _ _: "false"

def pattern_vars(pattern: AST.SyntaxPattern, value: String) -> List<&2, String>:
  match pattern:
    case AST.PatternVar{ _,  _,  AST.QZero{},  _}: ["null"]
    case AST.PatternVar{ _,  _,  _,  _}: [value]
    case AST.PatternCtr{key, fields,  _}: pattern_vars_ctr(key, fields, value)

def pattern_vars_ctr(key: String, fields: List<&2, AST.SyntaxPattern>, value: String) -> List<&2, String>:
  js_choose_vars(key, "Nat.Succ", pattern_fields_vars(fields, String.append("(", String.append(value, " - 1n)")), 0n), pattern_vars_ctr_2(key, fields, value))

def js_choose_vars(key: String, suffix: String, expression: List<&2, String>, other: List<&2, String>) -> List<&2, String>:
  js_choose_vars_result(String.ends_with(key, suffix), expression, other)

def js_choose_vars_result(matches: Bool, expression: List<&2, String>, other: List<&2, String>) -> List<&2, String>:
  match matches:
    case True{}: expression
    case False{}: other

def pattern_vars_ctr_2(key: String, fields: List<&2, AST.SyntaxPattern>, value: String) -> List<&2, String>:
  js_choose_vars(key, "String.SCon", pattern_string_fields(fields, value, 0n), pattern_vars_ctr_3(key, fields, value))

def pattern_vars_ctr_3(key: String, fields: List<&2, AST.SyntaxPattern>, value: String) -> List<&2, String>:
  js_choose_vars(key, "Char.Chr", pattern_fields_vars(fields, String.append(value, ".codePointAt(0)"), 0n), pattern_vars_ctr_4(key, fields, value))

def pattern_vars_ctr_4(key: String, fields: List<&2, AST.SyntaxPattern>, value: String) -> List<&2, String>:
  js_choose_vars(key, "U32.U32", pattern_fields_vars(fields, String.append("u32_to_word(", String.append(value, ")")), 0n), pattern_vars_ctr_5(key, fields, value))

def pattern_vars_ctr_5(key: String, fields: List<&2, AST.SyntaxPattern>, value: String) -> List<&2, String>:
  js_choose_vars(key, "F32.F32", pattern_fields_vars(fields, String.append("u32_to_word(f32_bits(", String.append(value, "))")), 0n), pattern_vars_ctr_6(key, fields, value))

def pattern_vars_ctr_6(key: String, fields: List<&2, AST.SyntaxPattern>, value: String) -> List<&2, String>:
  js_choose_vars(key, "Array.ALeaf", pattern_fields_vars(fields, String.append(value, "[0]"), 0n), pattern_vars_ctr_7(key, fields, value))

def pattern_vars_ctr_7(key: String, fields: List<&2, AST.SyntaxPattern>, value: String) -> List<&2, String>:
  js_choose_vars(key, "Array.ANode", pattern_array_fields(fields, value, 0n), pattern_fields_vars(fields, value, 0n))

def pattern_array_field_value(value: String, index: Nat) -> String:
  match index:
    case 0n: String.append(value, String.append(".slice(0, ", String.append(value, String.append(".length >> 1", ")"))))
    case _: String.append(value, String.append(".slice(", String.append(value, String.append(".length >> 1", ")"))))

def pattern_array_fields(fields: List<&2, AST.SyntaxPattern>, value: String, index: Nat) -> List<&2, String>:
  match fields:
    case Nil{}: Nil{}
    case +field <> rest:
      field_value = pattern_array_field_value(value, index)
      List.append(&2, String, pattern_vars(field, field_value), pattern_array_fields(rest, value, index + 1n))

def pattern_string_field_value(value: String, index: Nat) -> String:
  match index:
    case 0n: String.append("String.fromCodePoint(", String.append(value, ".codePointAt(0))"))
    case _: String.append(value, String.append(".slice(", String.append(value, String.append(".codePointAt(0)>0xFFFF?2:1", ")"))))

def pattern_string_fields(fields: List<&2, AST.SyntaxPattern>, value: String, index: Nat) -> List<&2, String>:
  match fields:
    case Nil{}: Nil{}
    case +field <> rest:
      field_value = pattern_string_field_value(value, index)
      List.append(&2, String, pattern_vars(field, field_value), pattern_string_fields(rest, value, index + 1n))

def pattern_fields_vars(fields: List<&2, AST.SyntaxPattern>, value: String, index: Nat) -> List<&2, String>:
  match fields:
    case Nil{}: Nil{}
    case +field <> rest:
      field_value = String.append(value, String.append(".args[", String.append(Nat.show(index), "]")))
      List.append(&2, String, pattern_vars(field, field_value), pattern_fields_vars(rest, value, index + 1n))

def patterns_vars(patterns: List<&2, AST.SyntaxPattern>, values: List<&2, String>) -> List<&2, String>:
  match patterns values:
    case Nil{} Nil{}: Nil{}
    case +pattern <> more_patterns +value <> more_values:
      List.append(&2, String, pattern_vars(pattern, value), patterns_vars(more_patterns, more_values))
    case _ _: Nil{}

def reverse_names(names: List<&2, String>) -> List<&2, String>:
  reverse_names_at(names, Nil{})

def reverse_names_at(names: List<&2, String>, acc: List<&2, String>) -> List<&2, String>:
  match names:
    case Nil{}: acc
    case +name <> rest: reverse_names_at(rest, name <> acc)

def js_case(patterns: List<&2, AST.SyntaxPattern>, body: AST.SyntaxTerm, values: List<&2, String>, env: List<&2, String>) -> String:
  test = patterns_test(patterns, values)
  case_env = List.append(&2, String, reverse_names(patterns_vars(patterns, values)), env)
  String.append("if (", String.append(test, String.append(") return ", String.append(js_term(body, case_env), ";"))))

def js_cases(cases: List<&2, AST.SyntaxTerm>, values: List<&2, String>, env: List<&2, String>) -> String:
  match cases:
    case Nil{}: "throw \"bend: runtime fail-stop\";"
    case +term <> rest:
      match term:
        case AST.BodyCase{patterns, body,  _}:
          String.append(js_case(patterns, body, values, env), String.append("\n", js_cases(rest, values, env)))
        case _: js_cases(rest, values, env)

def js_scrutinees(scrutinees: List<&2, AST.SyntaxTerm>, env: List<&2, String>, index: Nat) -> String:
  match scrutinees:
    case Nil{}: ""
    case +term <> rest:
      name = String.append("$s", Nat.show(index))
      String.append("const ", String.append(name, String.append(" = ", String.append(js_term(term, env), String.append(";\n", js_scrutinees(rest, env, index + 1n))))))

def scrutinee_names(count: Nat) -> List<&2, String>:
  scrutinee_names_at(count, 0n)

def scrutinee_names_at(count: Nat, index: Nat) -> List<&2, String>:
  match count:
    case 0n: Nil{}
    case _: String.append("$s", Nat.show(index)) <> scrutinee_names_at(count - 1n, index + 1n)

def js_body_match(scrutinees: List<&2, AST.SyntaxTerm>, cases: List<&2, AST.SyntaxTerm>, env: List<&2, String>) -> String:
  values = scrutinee_names(List.length(&2, AST.SyntaxTerm, scrutinees))
  String.append("(()=>{", String.append(js_scrutinees(scrutinees, env, 0n), String.append(js_cases(cases, values, env), "})()")))

def js_binders(binders: List<&2, AST.TelescopeItem>, env: List<&2, String>, body: AST.SyntaxTerm) -> String:
  match binders:
    case Nil{}: js_term(body, env)
    case +binder <> rest:
      match binder:
        case AST.Binder{ AST.QZero{},  _,  _,  _,  _}:
          js_binders(rest, env_push("null", env), body)
        case AST.Binder{ _,  _,  _,  _,  _}:
          name = String.append("$a", Nat.show(List.length(&2, AST.TelescopeItem, binders)))
          String.append("((", String.append(name, String.append(") => ", String.append(js_binders(rest, env_push(name, env), body), ")"))))
        case AST.TemplateBinder{ _,  _,  _,  _}: js_binders(rest, env_push("null", env), body)
def js_decl(namespace: String, source_path: String, declaration: AST.TopLevel) -> String:
  match declaration:
    case AST.DefTop{ AST.Definition{key, binders,  _, body,  _,  _}}:
      match body:
        case AST.DefTerm{term}:
          full_key = qualify(namespace, key)
          String.append("$D[", String.append(js_quote(full_key), String.append("] = ", String.append(js_binders(binders, Nil{}, term), ";"))))
        case AST.DefImports{paths}:
          full_key = qualify(namespace, key)
          String.append("$D[", String.append(js_quote(full_key), String.append("] = ", String.append(js_foreign(paths, key, source_path, binders), ";"))))
    case AST.TypeTop{ _}: ""
    case AST.LawTop{ _}: ""

def js_live_binders(binders: List<&2, AST.TelescopeItem>) -> Nat:
  match binders:
    case Nil{}: 0n
    case +binder <> rest:
      match binder:
        case AST.Binder{ AST.QZero{},  _,  _,  _,  _}: js_live_binders(rest)
        case AST.Binder{ _,  _,  _,  _,  _}: 1n + js_live_binders(rest)
        case AST.TemplateBinder{ _,  _,  _,  _}: js_live_binders(rest)
def js_foreign(paths: List<&2, String>, key: String, source_path: String, binders: List<&2, AST.TelescopeItem>) -> String:
  match paths:
    case Nil{}: "undefined"
    case +path <> rest:
      js_foreign_path(String.ends_with(path, ".js"), rest, path, key, source_path, binders)

def js_foreign_path(is_js: Bool, rest: List<&2, String>, path: String, key: String, source_path: String, binders: List<&2, AST.TelescopeItem>) -> String:
  match is_js:
    case True{}: String.append("$effect(require(", String.append(js_quote(Path.resolve(source_path, path)), String.append(")[", String.append(js_quote(key), String.append("], require(", String.append(js_quote(Path.resolve(source_path, path)), String.append(")[", String.append(js_quote(String.append(key, "_need")), String.append("], ", String.append(Nat.show(js_live_binders(binders)), ")"))))))))))
    case False{}: js_foreign(rest, key, source_path, binders)

def js_decls(namespace: String, source_path: String, declarations: List<&2, AST.TopLevel>) -> String:
  match declarations:
    case Nil{}: ""
    case +declaration <> rest: String.append(js_decl(namespace, source_path, declaration), String.append("\n", js_decls(namespace, source_path, rest)))

def find_namespace(path: String, modules: List<&2, Loader.LoadedModule>) -> Maybe<&2, String>:
  match modules:
    case Nil{}: None{}
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{namespace,  AST.Module{ found,  _,  _}}:
          js_find_namespace_path(String.eq(Path.normalize(path), Path.normalize(found)), rest, namespace, path)

def js_find_namespace_path(found: Bool, rest: List<&2, Loader.LoadedModule>, namespace: String, path: String) -> Maybe<&2, String>:
  match found:
    case True{}: Some{namespace}
    case False{}: find_namespace(path, rest)

def alias_namespace(module_path: String, import_path: String, modules: List<&2, Loader.LoadedModule>) -> String:
  alias_namespace_base(String.eq(import_path, "Base"), module_path, import_path, modules)

def alias_namespace_base(is_base: Bool, module_path: String, import_path: String, modules: List<&2, Loader.LoadedModule>) -> String:
  match is_base:
    case True{}: ""
    case False{}:
      alias_namespace_found(find_namespace(Path.resolve(module_path, import_path), modules))

def alias_namespace_found(found: Maybe<&2, String>) -> String:
  match found:
    case Some{value}: value
    case None{}: ""

def js_aliases(imports: List<&2, AST.ModuleImport>, module_path: String, modules: List<&2, Loader.LoadedModule>) -> String:
  match imports:
    case Nil{}: "{}"
    case +item <> rest:
      match item:
        case AST.ModuleImport{path, alias,  AST.SpanOf{ import_file,  _,  _}}:
          rest_aliases = js_alias_entries(rest, module_path, modules)
          prefix = String.append("{", js_quote(alias))
          named = String.append(prefix, String.append(":", js_quote(alias_namespace(import_file, path, modules))))
          String.append(named, String.append(rest_aliases, "}"))

def js_alias_entries(imports: List<&2, AST.ModuleImport>, module_path: String, modules: List<&2, Loader.LoadedModule>) -> String:
  match imports:
    case Nil{}: ""
    case +item <> rest:
      match item:
        case AST.ModuleImport{path, alias,  AST.SpanOf{ import_file,  _,  _}}:
          entry = String.append(",", js_quote(alias))
          named = String.append(entry, String.append(":", js_quote(alias_namespace(import_file, path, modules))))
          String.append(named, js_alias_entries(rest, module_path, modules))

def js_module(namespace: String, module: AST.Module, modules: List<&2, Loader.LoadedModule>) -> String:
  match module:
    case AST.Module{path, imports, declarations}:
      opener = String.append("(()=>{const $scope=", js_quote(namespace))
      aliases = String.append(";const $aliases=", js_aliases(imports, path, modules))
      body = String.append(opener, String.append(aliases, String.append(";\n", js_decls(namespace, path, declarations))))
      String.append(body, "})();\n")

def js_modules(modules: List<&2, Loader.LoadedModule>) -> String:
  match modules:
    case Nil{}: ""
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{namespace, module}:
          String.append(js_module(namespace, module, modules), js_modules(rest))
def qualify(namespace: String, key: String) -> String:
  qualify_result(String.eq(namespace, ""), namespace, key)

def qualify_result(empty: Bool, namespace: String, key: String) -> String:
  match empty:
    case True{}: key
    case False{}: String.append(namespace, String.append(".", key))
def first_span(left: Maybe<&2, AST.SourceSpan>, right: Maybe<&2, AST.SourceSpan>) -> Maybe<&2, AST.SourceSpan>:
  match left:
    case Some{value}: Some(value)
    case None{}: right

def error_terms(terms: List<&2, AST.SyntaxTerm>) -> Maybe<&2, AST.SourceSpan>:
  match terms:
    case Nil{}: None{}
    case +term <> rest: first_span(error_term(term), error_terms(rest))

def error_term(term: AST.SyntaxTerm) -> Maybe<&2, AST.SourceSpan>:
  match term:
    case AST.TermHole{ _, span}: Some(span)
    case AST.TermVar{ _,  _,  _}: None{}
    case AST.TermRef{ _,  _}: None{}
    case AST.TermBang{term,  _}: error_term(term)
    case AST.TermSub{ _, value, body,  _}: first_span(error_term(value), error_term(body))
    case AST.TermLet{ _,  _,  _, values, body,  _}: first_span(error_terms(values), error_term(body))
    case AST.TermType{kind,  _}: error_term(kind)
    case AST.TermAnn{term, ty,  _}: first_span(error_term(term), error_term(ty))
    case AST.TermTemplate{term,  _}: error_term(term)
    case AST.TermQuant{}: None{}
    case AST.TermQuantity{ _,  _}: None{}
    case AST.TermMin{left, right,  _}: first_span(error_term(left), error_term(right))
    case AST.TermAll{ _,  _,  _, ty, body,  _}: first_span(error_term(ty), error_term(body))
    case AST.TermLam{ _,  _,  _, body,  _}: error_term(body)
    case AST.TermApp{fn, arg,  _}: first_span(error_term(fn), error_term(arg))
    case AST.TermAdt{ _, args,  _,  _}: error_terms(args)
    case AST.TermCtr{ _, args,  _}: error_terms(args)
    case AST.TermFill{head, args,  _}: first_span(error_term(head), error_terms(args))
    case AST.TermPlus{head, args,  _}: first_span(error_term(head), error_terms(args))
    case AST.TermMat{ _, head, matched,  _}: first_span(error_term(head), error_term(matched))
    case AST.TermAbsurd{ _}: None{}
    case AST.TermEqual{left, right, ty,  _}: first_span(error_term(left), first_span(error_term(right), error_term(ty)))
    case AST.TermRefl{ _}: None{}
    case AST.TermRewrite{equation, proof, body,  _}: first_span(error_term(equation), first_span(error_term(proof), error_term(body)))
    case AST.BodyMatch{scrutinees, cases,  _}: first_span(error_terms(scrutinees), error_terms(cases))
    case AST.BodyCase{ _, body,  _}: error_term(body)
    case AST.BodyLocal{ _,  _, values, body,  _}: first_span(error_terms(values), error_term(body))
    case AST.BodyReply{term,  _}: error_term(term)

def error_optional_term(result: AST.OptionalTerm) -> Maybe<&2, AST.SourceSpan>:
  match result:
    case AST.NoTerm{}: None{}
    case AST.SomeTerm{term}: error_term(term)
def error_def_body(body: AST.DefBody) -> Maybe<&2, AST.SourceSpan>:
  match body:
    case AST.DefTerm{term}: error_term(term)
    case AST.DefImports{ _}: None{}

def error_decl(declaration: AST.TopLevel) -> Maybe<&2, AST.SourceSpan>:
  match declaration:
    case AST.DefTop{ AST.Definition{ _, binders, result, body,  _, span}}:
      result_error = error_optional_term(result)
      binder_errors = error_binders(binders)
      body_error = error_def_body(body)
      first_span(result_error, first_span(binder_errors, body_error))
    case AST.TypeTop{ AST.TypeDecl{ _, params, kind, constructors,  _}}:
      first_span(error_term(kind), first_span(error_binders(params), error_constructors(constructors)))
    case AST.LawTop{ AST.LawDecl{ _, clauses, body,  _}}:
      first_span(error_clauses(clauses), error_term(body))

def error_binders(binders: List<&2, AST.TelescopeItem>) -> Maybe<&2, AST.SourceSpan>:
  match binders:
    case Nil{}: None{}
    case +binder <> rest:
      match binder:
        case AST.Binder{ _,  _,  _, ty,  _}: first_span(error_term(ty), error_binders(rest))
        case AST.TemplateBinder{ _,  _, ty,  _}: first_span(error_term(ty), error_binders(rest))

def error_constructors(constructors: List<&2, AST.ConstructorDecl>) -> Maybe<&2, AST.SourceSpan>:
  match constructors:
    case Nil{}: None{}
    case +constructor <> rest:
      match constructor:
        case AST.Constructor{ _, fields,  _}: first_span(error_binders(fields), error_constructors(rest))

def error_condition(condition: Maybe<&2, AST.SyntaxTerm>) -> Maybe<&2, AST.SourceSpan>:
  match condition:
    case None{}: None{}
    case Some{term}: error_term(term)

def error_clauses(clauses: List<&2, AST.Clause>) -> Maybe<&2, AST.SourceSpan>:
  match clauses:
    case Nil{}: None{}
    case +clause <> rest:
      match clause:
        case AST.ClauseFor{ _,  _,  _, ty, condition,  _}:
          condition_error = error_condition(condition)
          first_span(error_term(ty), first_span(condition_error, error_clauses(rest)))

def error_decls(declarations: List<&2, AST.TopLevel>) -> Maybe<&2, AST.SourceSpan>:
  match declarations:
    case Nil{}: None{}
    case +declaration <> rest: first_span(error_decl(declaration), error_decls(rest))

def error_modules(modules: List<&2, Loader.LoadedModule>) -> Maybe<&2, AST.SourceSpan>:
  match modules:
    case Nil{}: None{}
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{ _,  AST.Module{ _,  _, declarations}}:
          first_span(error_decls(declarations), error_modules(rest))
def template_terms(terms: List<&2, AST.SyntaxTerm>) -> Maybe<&2, AST.SourceSpan>:
  match terms:
    case Nil{}: None{}
    case +term <> rest: first_span(template_term(term), template_terms(rest))
def template_term(term: AST.SyntaxTerm) -> Maybe<&2, AST.SourceSpan>:
  match term:
    case AST.TermTemplate{ _, span}: Some(span)
    case AST.TermVar{ _,  _,  _}: None{}
    case AST.TermRef{ _,  _}: None{}
    case AST.TermBang{term,  _}: template_term(term)
    case AST.TermSub{ _, value, body,  _}: first_span(template_term(value), template_term(body))
    case AST.TermLet{ _,  _,  _, values, body,  _}: first_span(template_terms(values), template_term(body))
    case AST.TermAnn{term, ty,  _}: first_span(template_term(term), template_term(ty))
    case AST.TermType{kind,  _}: template_term(kind)
    case AST.TermQuant{}: None{}
    case AST.TermQuantity{ _,  _}: None{}
    case AST.TermMin{left, right,  _}: first_span(template_term(left), template_term(right))
    case AST.TermAll{ _,  _,  _, ty, body,  _}: first_span(template_term(ty), template_term(body))
    case AST.TermLam{ _,  _,  _, body,  _}: template_term(body)
    case AST.TermApp{fn, arg,  _}: first_span(template_term(fn), template_term(arg))
    case AST.TermAdt{ _, args,  _,  _}: template_terms(args)
    case AST.TermFill{head, args,  _}: first_span(template_term(head), template_terms(args))
    case AST.TermPlus{head, args,  _}: first_span(template_term(head), template_terms(args))
    case AST.TermCtr{ _, args,  _}: template_terms(args)
    case AST.TermMat{ _, head, matched,  _}: first_span(template_term(head), template_term(matched))
    case AST.TermAbsurd{ _}: None{}
    case AST.TermEqual{left, right, ty,  _}: first_span(template_term(left), first_span(template_term(right), template_term(ty)))
    case AST.TermRefl{ _}: None{}
    case AST.TermRewrite{equation, proof, body,  _}: first_span(template_term(equation), first_span(template_term(proof), template_term(body)))
    case AST.TermHole{ _,  _}: None{}
    case AST.BodyMatch{scrutinees, cases,  _}: first_span(template_terms(scrutinees), template_terms(cases))
    case AST.BodyCase{ _, body,  _}: template_term(body)
    case AST.BodyLocal{ _,  _, values, body,  _}: first_span(template_terms(values), template_term(body))
    case AST.BodyReply{term,  _}: template_term(term)
def template_binders(binders: List<&2, AST.TelescopeItem>) -> Maybe<&2, AST.SourceSpan>:
  match binders:
    case Nil{}: None{}
    case +binder <> rest:
      match binder:
        case AST.Binder{ _,  _,  _, ty,  _}: first_span(template_term(ty), template_binders(rest))
        case AST.TemplateBinder{ _,  _,  _, span}: Some(span)
def template_constructors(constructors: List<&2, AST.ConstructorDecl>) -> Maybe<&2, AST.SourceSpan>:
  match constructors:
    case Nil{}: None{}
    case +constructor <> rest:
      match constructor:
        case AST.Constructor{ _, fields,  _}: first_span(template_binders(fields), template_constructors(rest))
def template_condition(condition: Maybe<&2, AST.SyntaxTerm>) -> Maybe<&2, AST.SourceSpan>:
  match condition:
    case None{}: None{}
    case Some{term}: template_term(term)

def template_clauses(clauses: List<&2, AST.Clause>) -> Maybe<&2, AST.SourceSpan>:
  match clauses:
    case Nil{}: None{}
    case +clause <> rest:
      match clause:
        case AST.ClauseFor{ _,  _,  _, ty, condition,  _}:
          condition_template = template_condition(condition)
          first_span(template_term(ty), first_span(condition_template, template_clauses(rest)))
def template_optional_term(result: AST.OptionalTerm) -> Maybe<&2, AST.SourceSpan>:
  match result:
    case AST.NoTerm{}: None{}
    case AST.SomeTerm{term}: template_term(term)
def template_def_body(body: AST.DefBody) -> Maybe<&2, AST.SourceSpan>:
  match body:
    case AST.DefTerm{term}: template_term(term)
    case AST.DefImports{ _}: None{}

def template_decl(declaration: AST.TopLevel) -> Maybe<&2, AST.SourceSpan>:
  match declaration:
    case AST.DefTop{ AST.Definition{ _, binders, result, body,  _,  _}}:
      result_template = template_optional_term(result)
      body_template = template_def_body(body)
      first_span(result_template, first_span(template_binders(binders), body_template))
    case AST.TypeTop{ AST.TypeDecl{ _, params, kind, constructors,  _}}:
      first_span(template_term(kind), first_span(template_binders(params), template_constructors(constructors)))
    case AST.LawTop{ AST.LawDecl{ _, clauses, body,  _}}:
      first_span(template_clauses(clauses), template_term(body))
def template_decls(declarations: List<&2, AST.TopLevel>) -> Maybe<&2, AST.SourceSpan>:
  match declarations:
    case Nil{}: None{}
    case +declaration <> rest: first_span(template_decl(declaration), template_decls(rest))
def template_modules(modules: List<&2, Loader.LoadedModule>) -> Maybe<&2, AST.SourceSpan>:
  match modules:
    case Nil{}: None{}
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{ _,  AST.Module{ _,  _, declarations}}:
          first_span(template_decls(declarations), template_modules(rest))
def has_js_import(paths: List<&2, String>) -> Bool:
  match paths:
    case Nil{}: False{}
    case +path <> rest: Bool.or(String.ends_with(path, ".js"), has_js_import(rest))

def foreign_error_decl(declaration: AST.TopLevel) -> Maybe<&2, AST.SourceSpan>:
  match declaration:
    case AST.DefTop{ AST.Definition{ _,  _,  _, body,  _, span}}:
      match body:
        case AST.DefImports{paths}: foreign_error_js(has_js_import(paths), span)
        case AST.DefTerm{ _}: None{}
    case AST.TypeTop{ _}: None{}
    case AST.LawTop{ _}: None{}

def foreign_error_js(found: Bool, span: AST.SourceSpan) -> Maybe<&2, AST.SourceSpan>:
  match found:
    case True{}: None{}
    case False{}: Some(span)

def foreign_error_decls(declarations: List<&2, AST.TopLevel>) -> Maybe<&2, AST.SourceSpan>:
  match declarations:
    case Nil{}: None{}
    case +declaration <> rest: first_span(foreign_error_decl(declaration), foreign_error_decls(rest))

def foreign_error_modules(modules: List<&2, Loader.LoadedModule>) -> Maybe<&2, AST.SourceSpan>:
  match modules:
    case Nil{}: None{}
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{ _,  AST.Module{ _,  _, declarations}}:
          first_span(foreign_error_decls(declarations), foreign_error_modules(rest))


def js_runtime() -> String:
  "const $D = Object.create(null);\nfunction $run(f, xs) { let x=f; for (const a of xs) x=x(a); return x; }\nfunction run_loop(x) { while (x && x.$tail) x=x.$tail(); return x; }\nfunction run_tail(f,x) { return {$tail:()=>f(x)}; }\nfunction nat_chk(x) { if(x>281474976710655n) throw \"bend: a Nat past the largest immediate 2^48-1\"; return x; }\nfunction char_new(x) { if(x>0x10ffff || (x>=0xd800 && x<=0xdfff)) throw \"bend: \"+x+\" is not a Unicode scalar value\"; return String.fromCodePoint(x); }\nfunction cmp_new(a,b) { return {$:a<b?\"LT\":a===b?\"EQ\":\"GT\"}; }\nfunction word_to_u32(w) { let x=0; for(let i=0;w.$===\"WCon\";i++,w=w.tail) if(w.head)x|=1<<i; return x>>>0; }\nfunction u32_to_word(x) { let w={$:\"WNil\"}; for(let i=31;i>=0;i--) w={$:\"WCon\",head:!!((x>>>i)&1),tail:w}; return w; }\n"
def js_runtime_extra() -> String:
  "function f32_from_bits(x) { return new Float32Array(new Uint32Array([x]).buffer)[0]; }\nfunction f32_bits(x) { return new Uint32Array(new Float32Array([x]).buffer)[0]; }\nfunction tuple(a,b) { return {$:\"Tuple\",args:[a,b],get fst(){return this.args[0]},get snd(){return this.args[1]}}; }\nfunction f32_show(x) { if(x!==x) return \"nan\"; if(!Number.isFinite(x)||Object.is(x,-0)) return x<0?\"-inf\":x===0?\"-0\":\"inf\"; let s=\"x\"; for(let p=1;p<=9&&Math.fround(Number(s))!==x;p++) s=String(Number(x.toExponential(p-1))); return s; }\nfunction f32_read(s) { const re=/^\\s*[+-]?((\\d+\\.?\\d*|\\.\\d+)(e[+-]?\\d+)?|inf(inity)?|nan)$/i; const v=Number(s.replace(/inf\\w*/i,\"Infinity\")); return re.test(s)?{$:\"Some\",args:[Math.fround(v)],get value(){return this.args[0]}}:{$:\"None\"}; }\nfunction nat_divmod(a,b) { return b===0n?tuple(0n,a):tuple(a/b,a%b); }\nfunction array_new(n,v) { if(n>31n) throw \"bend: an array past the deepest block class 31\"; return Array(2 ** Number(n)).fill(v); }\nfunction array_node(a,b) { if(a.length!==b.length) throw \"bend: runtime fail-stop\"; return a.concat(b); }\n"
def js_runtime_array() -> String:
  "function array_swap(a,i,v) { const at=i%a.length, old=a[at]; a[at]=v; return tuple(a,old); }\n"
def js_runtime_foreign() -> String:
  "function $curry(f,n,xs=[]) { return n===0 ? f(...xs) : x => $curry(f,n-1,[...xs,x]); }\nfunction $effect(f,need,n) { return $curry((...args)=>({$:\"$FFI\",run:f,need,args,kont:x=>({$:\"Emit\",value:x})}),n); }\n"
def js_runtime_namespace() -> String:
  "function $key(k,s,a) { let p=null; for (const alias of Object.keys(a)) if(k.startsWith(alias+\".\") && (p===null || alias.length>p.length)) p=alias; const n=p===null?undefined:a[p]; return n===undefined?(s?s+\".\"+k:k):(n?n+\".\":\"\")+k.slice(p.length+1); }\nfunction $resolve(k,s,a) { const q=$key(k,s,a); return $D[q]===undefined?$D[k]:$D[q]; }\nconst $FIELDS=Object.create(null), $TYPE=Object.create(null), $PARAMS=Object.create(null);\nfunction $ctr(k,x,s,a) { const q=$key(k,s,a), fs=$FIELDS[q]||[], ys=fs.length?x.filter((_,i)=>fs[i]!==null):x; const v={$:q.split(/[./]/).pop(),args:ys}; let j=0; for(const f of fs) if(f!==null){const at=j++;Object.defineProperty(v,f,{enumerable:true,get(){return ys[at];}});} return v; }\n"

def js_runtime_field_names(fields: List<&2, AST.TelescopeItem>) -> String:
  js_runtime_field_names_at(fields, True{})
def js_runtime_field_names_at(fields: List<&2, AST.TelescopeItem>, first: Bool) -> String:
  match fields:
    case Nil{}: ""
    case +field <> rest:
      match field:
        case AST.Binder{ AST.QZero{},  _,  _,  _,  _}:
          prefix = js_comma_prefix(first)
          String.append(prefix, String.append("null", js_runtime_field_names_at(rest, False{})))
        case AST.Binder{ _, key,  _,  _,  _}:
          prefix = js_comma_prefix(first)
          String.append(prefix, String.append(js_quote(key), js_runtime_field_names_at(rest, False{})))
        case AST.TemplateBinder{ _,  _,  _,  _}: String.append("null", js_runtime_field_names_at(rest, False{}))
def js_constructor_fields_one(namespace: String, constructor: AST.ConstructorDecl) -> String:
  match constructor:
    case AST.Constructor{key, fields,  _}:
      String.append("$FIELDS[", String.append(js_quote(qualify(namespace, key)), String.append("] = [", String.append(js_runtime_field_names(fields), "];\n"))))
def js_constructor_fields_constructors(namespace: String, constructors: List<&2, AST.ConstructorDecl>) -> String:
  match constructors:
    case Nil{}: ""
    case +constructor <> rest:
      String.append(js_constructor_fields_one(namespace, constructor), js_constructor_fields_constructors(namespace, rest))
def js_constructor_fields_decl(namespace: String, declaration: AST.TopLevel) -> String:
  match declaration:
    case AST.TypeTop{ AST.TypeDecl{ _,  _,  _, constructors,  _}}:
      js_constructor_fields_constructors(namespace, constructors)
    case _: ""
def js_constructor_fields_decls(namespace: String, declarations: List<&2, AST.TopLevel>) -> String:
  match declarations:
    case Nil{}: ""
    case +declaration <> rest:
      String.append(js_constructor_fields_decl(namespace, declaration), js_constructor_fields_decls(namespace, rest))
def js_constructor_fields_modules(modules: List<&2, Loader.LoadedModule>) -> String:
  match modules:
    case Nil{}: ""
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{namespace,  AST.Module{ _,  _, declarations}}:
          String.append(js_constructor_fields_decls(namespace, declarations), js_constructor_fields_modules(rest))

def js_type_ref(key: String, args: List<&2, AST.SyntaxTerm>, scope: String, aliases: String) -> String:
  String.append("({r:", String.append(js_quote(key), String.append(",a:[", String.append(js_type_args(args, scope, aliases, True{}), String.append("],s:", String.append(js_quote(scope), String.append(",i:", String.append(aliases, "})"))))))))
def js_type_args(args: List<&2, AST.SyntaxTerm>, scope: String, aliases: String, first: Bool) -> String:
  match args:
    case Nil{}: ""
    case +term <> rest:
      prefix = js_comma_prefix(first)
      String.append(prefix, String.append(js_type_term(term, scope, aliases), js_type_args(rest, scope, aliases, False{})))
def js_type_sugar_descriptor(key: String, args: List<&2, AST.SyntaxTerm>, head: AST.SyntaxTerm, mode: String, scope: String, aliases: String) -> String:
  String.append("({r:", String.append(js_quote(key), String.append(",a:[", String.append(js_type_args(args, scope, aliases, True{}), String.append("],s:", String.append(js_quote(scope), String.append(",i:", String.append(aliases, String.append(",f:", String.append(mode, String.append(",h:", String.append(js_type_term(head, scope, aliases), "})"))))))))))))
def js_type_sugar(head: AST.SyntaxTerm, args: List<&2, AST.SyntaxTerm>, mode: String, scope: String, aliases: String) -> String:
  match head:
    case AST.TermAnn{term,  _,  _}: js_type_sugar(term, args, mode, scope, aliases)
    case AST.TermRef{key,  _}: js_type_sugar_descriptor(key, args, head, mode, scope, aliases)
    case AST.TermAdt{key,  head_args,  _,  _}:
      js_type_sugar_descriptor(key, List.append(&2, AST.SyntaxTerm, head_args, args), head, mode, scope, aliases)
    case AST.TermApp{fn, arg,  _}:
      js_type_sugar(fn, arg <> args, mode, scope, aliases)
    case _: js_type_term(head, scope, aliases)
def js_is_quant_type(term: AST.SyntaxTerm) -> Bool:
  match term:
    case AST.TermQuant{}: True{}
    case AST.TermAnn{term,  _,  _}: js_is_quant_type(term)
    case _: False{}
def js_quant_param_count(params: List<&2, AST.TelescopeItem>) -> Nat:
  match params:
    case AST.Binder{_, _, _, ty, _} <> rest:
      js_quant_param_increment(js_is_quant_type(ty), rest)
    case AST.TemplateBinder{_, _, ty, _} <> rest:
      js_quant_param_increment(js_is_quant_type(ty), rest)
    case _: 0n

def js_quant_param_increment(is_quant: Bool, rest: List<&2, AST.TelescopeItem>) -> Nat:
  match is_quant:
    case True{}: 1n + js_quant_param_count(rest)
    case False{}: 0n
def js_type_term(term: AST.SyntaxTerm, scope: String, aliases: String) -> String:
  match term:
    case AST.TermFill{head, args,  _}: js_type_sugar(head, args, "1", scope, aliases)
    case AST.TermPlus{head, args,  _}: js_type_sugar(head, args, "2", scope, aliases)
    case AST.TermTemplate{ _,  _}: "(()=>{throw \"bend: unexpanded template\"})()"
    case AST.TermBang{ _,  _}: "(()=>{throw \"bend: bang term is not a type\"})()"
    case AST.TermAnn{term,  _,  _}: js_type_term(term, scope, aliases)
    case AST.TermRef{key,  _}: js_type_ref(key, Nil{}, scope, aliases)
    case AST.TermAdt{key, args,  _,  _}: js_type_ref(key, args, scope, aliases)
    case AST.TermApp{ AST.TermRef{key,  _}, arg,  _}: js_type_ref(key, [arg], scope, aliases)
    case AST.TermApp{ AST.TermAdt{key, args,  _,  _}, arg,  _}:
      js_type_ref(key, List.append(&2, AST.SyntaxTerm, args, [arg]), scope, aliases)
    case AST.TermVar{_, index, _}:
      String.append("({p:", String.append(Nat.show(index), "})"))
    case AST.TermQuant{}: "({k:\"QK\"})"
    case AST.TermQuantity{ AST.QZero{},  _}: "({k:\"Q\",v:0})"
    case AST.TermQuantity{ AST.QOne{},  _}: "({k:\"Q\",v:1})"
    case AST.TermQuantity{ AST.QMany{},  _}: "({k:\"Q\",v:2})"
    case AST.TermEqual{ _,  _,  _,  _}: "({k:\"E\"})"
    case _: "({k:\"?\"})"
def js_type_field_terms(fields: List<&2, AST.TelescopeItem>, scope: String, aliases: String, first: Bool) -> String:
  match fields:
    case Nil{}: ""
    case +field <> rest:
      match field:
        case AST.Binder{ AST.QZero{},  _,  _,  _,  _}:
          js_type_field_terms(rest, scope, aliases, first)
        case AST.Binder{ _,  _,  _, ty,  _}:
          prefix = js_comma_prefix(first)
          String.append(prefix, String.append(js_type_term(ty, scope, aliases), js_type_field_terms(rest, scope, aliases, False{})))
        case AST.TemplateBinder{ _,  _,  _,  _}: js_type_field_terms(rest, scope, aliases, first)
def js_type_arm(constructor: AST.ConstructorDecl, scope: String, aliases: String) -> String:
  match constructor:
    case AST.Constructor{key, fields,  _}:
      String.append(js_quote(ctor_short(key)), String.append(":[", String.append(js_type_field_terms(fields, scope, aliases, True{}), "]")))
def js_type_arms(constructors: List<&2, AST.ConstructorDecl>, scope: String, aliases: String, first: Bool) -> String:
  match constructors:
    case Nil{}: ""
    case +constructor <> rest:
      prefix = js_comma_prefix(first)
      String.append(prefix, String.append(js_type_arm(constructor, scope, aliases), js_type_arms(rest, scope, aliases, False{})))
def js_type_decl(namespace: String, path: String, imports: List<&2, AST.ModuleImport>, modules: List<&2, Loader.LoadedModule>, declaration: AST.TopLevel) -> String:
  match declaration:
    case AST.TypeTop{ AST.TypeDecl{key, params,  _, constructors,  _}}:
      aliases = js_aliases(imports, path, modules)
      full_key = qualify(namespace, key)
      String.append("$PARAMS[", String.append(js_quote(full_key), String.append("]={q:", String.append(Nat.show(js_quant_param_count(params)), String.append(",n:", String.append(Nat.show(List.length(&2, AST.TelescopeItem, params)), String.append(")};\n$TYPE[", String.append(js_quote(full_key), String.append("]={name:", String.append(js_quote(key), String.append(",arms:{", String.append(js_type_arms(constructors, namespace, aliases, True{}), "}};\n"))))))))))))
    case _: ""
def js_type_decls(namespace: String, path: String, imports: List<&2, AST.ModuleImport>, modules: List<&2, Loader.LoadedModule>, declarations: List<&2, AST.TopLevel>) -> String:
  match declarations:
    case Nil{}: ""
    case +declaration <> rest:
      String.append(js_type_decl(namespace, path, imports, modules, declaration), js_type_decls(namespace, path, imports, modules, rest))
def js_type_modules(modules: List<&2, Loader.LoadedModule>) -> String:
  match modules:
    case Nil{}: ""
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{namespace,  AST.Module{path, imports, declarations}}:
          String.append(js_type_decls(namespace, path, imports, modules, declarations), js_type_modules(rest))

def main_type_expr_declaration(declaration: AST.TopLevel, namespace: String, aliases: String) -> String:
  match declaration:
    case AST.DefTop{ AST.Definition{key,  _, result,  _,  _,  _}}:
      main_type_expr_is_main(String.eq(key, "main"), result, namespace, aliases)
    case _: ""

def main_type_expr_is_main(is_main: Bool, result: AST.OptionalTerm, namespace: String, aliases: String) -> String:
  match is_main:
    case False{}: ""
    case True{}:
      match result:
        case AST.SomeTerm{term}: js_type_term(term, namespace, aliases)
        case AST.NoTerm{}: ""

def main_type_expr_declarations(declarations: List<&2, AST.TopLevel>, namespace: String, aliases: String) -> String:
  match declarations:
    case Nil{}: ""
    case +declaration <> rest:
      main_type_expr_declaration_result(main_type_expr_declaration(declaration, namespace, aliases), rest, namespace, aliases)

def main_type_expr_declaration_result(found: String, rest: List<&2, AST.TopLevel>, namespace: String, aliases: String) -> String:
  main_type_expr_declaration_empty(String.eq(found, ""), found, rest, namespace, aliases)

def main_type_expr_declaration_empty(empty: Bool, found: String, rest: List<&2, AST.TopLevel>, namespace: String, aliases: String) -> String:
  match empty:
    case True{}: main_type_expr_declarations(rest, namespace, aliases)
    case False{}: found

def main_type_expr_modules(modules: List<&2, Loader.LoadedModule>) -> String:
  match modules:
    case Nil{}: "null"
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{namespace,  AST.Module{path, imports, declarations}}:
          main_type_expr_module(namespace, path, imports, declarations, rest, modules)

def main_type_expr_module(namespace: String, path: String, imports: List<&2, AST.ModuleImport>, declarations: List<&2, AST.TopLevel>, rest: List<&2, Loader.LoadedModule>, modules: List<&2, Loader.LoadedModule>) -> String:
  main_type_expr_module_scope(String.eq(namespace, ""), namespace, path, imports, declarations, rest, modules)

def main_type_expr_module_scope(is_root: Bool, namespace: String, path: String, imports: List<&2, AST.ModuleImport>, declarations: List<&2, AST.TopLevel>, rest: List<&2, Loader.LoadedModule>, modules: List<&2, Loader.LoadedModule>) -> String:
  match is_root:
    case False{}: main_type_expr_modules(rest)
    case True{}:
      main_type_expr_module_result(main_type_expr_declarations(declarations, namespace, js_aliases(imports, path, modules)), rest, modules)

def main_type_expr_module_result(found: String, rest: List<&2, Loader.LoadedModule>, modules: List<&2, Loader.LoadedModule>) -> String:
  main_type_expr_module_empty(String.eq(found, ""), found, rest)

def main_type_expr_module_empty(empty: Bool, found: String, rest: List<&2, Loader.LoadedModule>) -> String:
  match empty:
    case True{}: main_type_expr_modules(rest)
    case False{}: found

def js_runtime_cli() -> String:
  "const cli_args=[];\nfunction cli(argv) { for(let i=0;i<argv.length;i++){ if(argv[i]===\"--\"){cli_args.push(...argv.slice(i+1));break;} if(argv[i]===\"--help\"){process.stdout.write(\"usage: \"+process.argv[1]+\"\\n\");process.exit(0);} if(argv[i]===\"--threads\"||argv[i]===\"--gpu\"){i++;} else cli_args.push(argv[i]); } }\n"
def js_runtime_io() -> String:
  "function io_out(fd,data) { const fs=require(\"fs\"), b=Buffer.from(data); let at=0; while(at<b.length) at+=fs.writeSync(fd,b,at,b.length-at); }\nfunction io_errs(message) { io_out(2,io_bytes(message+\"\\n\")); }\nfunction io_bytes(text) { return new TextEncoder().encode(text); }\nfunction io_text(bytes,n) { return new TextDecoder(\"utf-8\",{ignoreBOM:true}).decode(bytes.subarray(0,n)); }\nfunction io_tup(...xs) { const args=xs, v={$:\"Tuple\",args}; for(let i=0;i<xs.length;i++) Object.defineProperty(v,[\"fst\",\"snd\"][i]||\"item\"+i,{enumerable:true,get(){return this.args[i]}}); return v; }\nfunction io_done(value) { return {$:\"Done\",value,args:[value]}; }\nfunction io_sys() { if(globalThis.BEND_SYS===undefined){const ffi=require(\"bun:ffi\"), mac=process.platform===\"darwin\", err=mac?\"__error\":\"__errno_location\", T={i:\"i32\",u:\"u32\",U:\"u64\",I:\"i64\",p:\"ptr\",c:\"cstring\"}, vari=mac&&process.arch===\"arm64\", lib=ffi.dlopen(mac?\"libSystem.dylib\":\"libc.so.6\",Object.fromEntries((\"socket:iii>i bind:ipu>i listen:ii>i connect:ipu>i accept:ipp>i send:ipUi>I recv:ipUi>I read:ipU>I pread:ipUI>I sendto:ipUipu>I recvfrom:ipUipp>I close:i>i poll:pui>i setsockopt:iiipu>i\"+(vari?\" fcntl:iiiiiiiii>i\":\" fcntl:iii>i\")+\" getsockopt:iiipp>i strerror:i>c \"+err+\":>p\").split(\" \").map(s=>{const [name,args,ret]=s.split(/[:>]/);return [name,{args:[...args].map(a=>T[a]),returns:T[ret]}]}))), fcntl=(fd,cmd,arg)=>vari?lib.symbols.fcntl(fd,cmd,0,0,0,0,0,0,arg):lib.symbols.fcntl(fd,cmd,arg); globalThis.BEND_SYS={...lib.symbols,fcntl,ptr:ffi.ptr,mac,errno:()=>ffi.read.i32(lib.symbols[err](),0)};} return globalThis.BEND_SYS; }\nfunction io_fail(code) { return {$:\"Fail\",args:[io_tup(code>>>0,String(io_sys().strerror(code)))]}; }\nfunction io_push(fun,arg,fresh) { const io=globalThis.BEND_IO; io.runs.push({fun,arg}); io.live+=fresh?1:0; }\nfunction io_park_on(fd,out,k,more) { globalThis.BEND_IO.waits.push({fd,out,k,more}); }\nfunction io_wait(io) { const soon=io.waits.reduce((m,w)=>Math.min(m,w.at??m),Infinity); let ms=-1; if(soon!==Infinity)ms=Math.min(Math.max(0,Math.ceil(soon-performance.now())),2147483647); const fds=io.waits.filter(w=>w.fd!==undefined), buf=Int32Array.from(fds.flatMap(w=>[w.fd,w.out?4:1])); io_sys().poll(fds.length?io_sys().ptr(buf):null,fds.length,ms); const now=performance.now(), fire=io.waits.filter((w)=>(buf[2*fds.indexOf(w)+1]>>>16)!==0||w.at<=now); io.waits=io.waits.filter(w=>!fire.includes(w)); for(const w of fire)io_push(io_wake,w,false); }\nfunction io_wake(w) { const x=w.more(); return x===undefined?undefined:w.k(x); }\nfunction io_run(m) { const io={runs:[],live:0,waits:[]}; globalThis.BEND_IO=io; try{io_push(run_loop(m()),x=>({$:\"Emit\",value:x}),true); for(;;){if(io.runs.length===0){if(io.live===0)return 0;if(io.waits.length===0){io_errs(\"bend: deadlock: every computation waits on a channel\");return 1;}io_wait(io);continue;}const s=io.runs.shift();let op=s.fun(s.arg);for(;;){if(op===undefined)break;if(op.$===\"Emit\"){io.live-=1;break;}if(op.$===\"Halt\"){io_errs(op.message);return op.code;}const need=op.need?.()||{},fd=need.read?op.args[0]:null;if(need.time||fd!==null){const more=()=>op.run(...op.args,op.kont);io.waits.push(fd===null?{at:performance.now()+Number(op.args[0]),k:op.kont,more}:{fd,k:op.kont,more});break;}const x=op.run(...op.args,op.kont);if(x===undefined)break;op=op.kont(x);}}}catch(req){if(req instanceof RangeError)throw \"bend: memory fault (machine stack overflow?)\";if(req?.$!==\"$FFI\")throw req;io_errs(\"bend: an FFI operation failed\");return 1;} }\nfunction chan_wake(row,x) { const w=row.wait.shift(); io_push(w.cont,x,false); return w.item; }\nfunction chan_take(row) { const v=row.ring.shift(); if(row.wait.length>0)row.ring.push(chan_wake(row,true)); return v; }\nfunction chan_shut(row) { row.shut=true; while(row.wait.length>0)chan_wake(row,row.wait[0].item===null?{$:\"None\"}:false); }\nfunction io_exit(main,type) { if(type&&type.name===\"IO\")return io_run(main); try{io_out(1,io_bytes($show_value(type,run_loop(main()),0)+\"\\n\"));return 0;}catch(e){io_errs(String(e));return 1;} }\n"
def js_runtime_show() -> String:
  "function $show_chr(x,q) { const c=[...x][0]||\"\\0\", n=c.codePointAt(0), k=({10:\"n\",9:\"t\",13:\"r\",0:\"0\",92:\"\\\\\"})[n]??(c===q?q:null); return k!==null?\"\\\\\"+k:n<32||n===127?\"\\\\u{\"+n.toString(16)+\"}\":c; }\nfunction $type(t,a=[]) { if(!t) return {k:\"?\"}; if(t.p!==undefined) return a[a.length-1-t.p]||{k:\"?\"}; if(t.k) return t; if(t.f){const q=$key(t.r,t.s,t.i||{}),p=$PARAMS[q];if(!p&&t.f===2)return $type(t.h,a);let xs=t.a||[];if(p&&xs.length+p.q===p.n)xs=[...Array(p.q)].map(()=>({k:\"Q\",v:1})).concat(xs);if(p&&t.f===2)xs=xs.map((x,i)=>i<p.q?({k:\"Q\",v:2}):x);return $type({r:t.r,s:t.s,i:t.i,a:xs},a);} const q=$key(t.r,t.s,t.i||{}), n=q.split(/[./]/).pop(), k=({U32:\"U\",F32:\"F\",Nat:\"N\",Char:\"C\",String:\"S\",Eql:\"E\"})[n]; if(k) return {k}; if(n===\"Array\") return {k:\"A\",e:$type((t.a||[])[0],a)}; const d=$TYPE[q], ps=(t.a||[]).map(x=>$type(x,a)); return {k:\"D\",name:d?d.name:n,arms:d?d.arms:{},args:ps}; }\nfunction $show_list(t,x) { const xs=[]; while(x&&x.$===\"Con\") { const a=x.args||[], fs=t.arms.Con||[]; if(a.length<2||fs.length<2) break; xs.push($show_value($type(fs[0],t.args),a[0],0)); x=a[1]; t=$type(fs[1],t.args); } if(x&&x.$!==\"Nil\") xs.push($show_value(t,x,0)); return \"[\"+xs.join(\", \")+\"]\"; }\nfunction $show_value(t,x,chain) { if(!t) return String(x); if(t.k===\"U\") return String(x); if(t.k===\"F\") { const s=f32_show(x); return s.replace(/^-?\\d+(?=e|$)/i,\"$&.0\"); } if(t.k===\"N\") return x+\"n\"; if(t.k===\"C\") return \"'\"+$show_chr(x,\"'\")+\"'\"; if(t.k===\"S\") return \"\\\"\"+[...x].map(c=>$show_chr(c,\"\\\"\")).join(\"\")+\"\\\"\"; if(t.k===\"E\") return \"{==}\"; if(t.k===\"A\") return \"[\"+x.map(v=>$show_value(t.e,v,0)).join(\", \")+\"]\"; if(typeof x===\"boolean\") return x?\"True{}\":\"False{}\"; if(!x||typeof x!==\"object\"||!x.$) return String(x); const a=x.args||[]; if(x.$===\"Nil\") return \"[]\"; if(x.$===\"Con\") return $show_list(t,x); const fs=t.arms[x.$]||[]; if(x.$===\"Tuple\") { const c=chain===\"(\"; return (c?\"\":\"(\")+a.map((v,j)=>$show_value($type(fs[j],t.args),v,j===1?\"(\":0)).join(\", \")+(c?\"\":\")\"); } return x.$+\"{\"+a.map((v,j)=>$show_value($type(fs[j],t.args),v,0)).join(\", \")+\"}\"; }\n"
def js_main(type_expression: String) -> String:
  String.append("if (typeof process !== \"undefined\" && process.argv[1] && /\\.js$/.test(process.argv[1])) { cli(process.argv.slice(2)); const $m=$D[\"main\"]; if($m!==undefined) { process.exitCode=io_exit($m,$type(", String.append(type_expression, ")); } }\n"))

def emit(modules: List<&2, Loader.LoadedModule>) -> EmitResult:
  js_emit_template(template_modules(modules), modules)

def js_emit_template(found: Maybe<&2, AST.SourceSpan>, modules: List<&2, Loader.LoadedModule>) -> EmitResult:
  match found:
    case Some{span}: EmitFailure{ "unexpanded compile-time template", span}
    case None{}: js_emit_holes(error_modules(modules), modules)

def js_emit_holes(found: Maybe<&2, AST.SourceSpan>, modules: List<&2, Loader.LoadedModule>) -> EmitResult:
  match found:
    case Some{span}: EmitFailure{ "cannot compile a hole", span}
    case None{}: js_emit_foreign(foreign_error_modules(modules), modules)

def js_emit_foreign(found: Maybe<&2, AST.SourceSpan>, modules: List<&2, Loader.LoadedModule>) -> EmitResult:
  match found:
    case Some{span}: EmitFailure{ "a foreign def without a .js import", span}
    case None{}:
      source = String.append(js_runtime(), String.append(js_runtime_extra(), String.append(js_runtime_show(), String.append(js_runtime_cli(), String.append(js_runtime_io(), String.append(js_runtime_array(), String.append(js_runtime_foreign(), String.append(js_runtime_namespace(), String.append(js_constructor_fields_modules(modules), String.append(js_type_modules(modules), String.append(js_modules(modules), js_main(main_type_expr_modules(modules)))))))))))))
      EmitSuccess{source}
