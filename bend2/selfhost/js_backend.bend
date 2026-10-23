import Base
import ./backend_ir.bend as BIR
import ./index_lookup.bend as IndexLookup

type TagArm is Data:
  TagArm{label: U32, condition: U32, tag: String, body: BIR.Block}
type TaggedRegion is Data:
  TaggedRegion{label: U32, condition: U32, subject: BIR.Atom, tag: String, body: BIR.Block, rest: BIR.Block}
type TagGroup is Data:
  TagGroup{arms: List<&2, TagArm>, rest: BIR.Block, count: Nat}

# This module consumes only target IR. All name resolution, erasure, call-shape
# selection and native provenance decisions are completed by lowering.
def cat(parts: List<&2, String>) -> String:
  String.join(parts, "")
def js_escape_char(char: Char) -> String:
  match char:
    case '\"': "\\\""
    case '\\': "\\\\"
    case '\n': "\\n"
    case '\r': "\\r"
    case '\t': "\\t"
    case '\u{0}': "\\u0000"
    case _: String.from_list([char])

def js_quote_chars(chars: List<&2, Char>, acc: String) -> String:
  match chars:
    case Nil{}: String.append(acc, "\"")
    case +char <> rest:
      escaped = js_escape_char(char)
      js_quote_chars(rest, String.append(acc, escaped))

def js_quote(text: String) -> String:
  js_quote_chars(String.to_list(text), "\"")

def bool_source(value: Bool) -> String:
  match value:
    case True{}: "true"
    case False{}: "false"
def optional_text(value: Maybe<&2, String>) -> String:
  match value:
    case None{}: "null"
    case Some{text}: js_quote(text)
def local(id: U32) -> String:
  cat(["$v", U32.show(id)])
def capture(slot: U32) -> String:
  cat(["$c", U32.show(slot)])
def code_name(id: U32) -> String:
  cat(["$b", U32.show(id)])
def atom(value: BIR.Atom) -> String:
  match value:
    case BIR.Local{id}: local(id)
    case BIR.Capture{slot}: capture(slot)
    case BIR.Symbol{_, key}: cat(["$D[", js_quote(key), "]"])
    case BIR.Word{value}: U32.show(value)
    case BIR.Natural{value}: Nat.show(value)
    case BIR.FloatBits{bits}: cat(["f32_from_bits(", U32.show(bits), ")"])
    case BIR.Text{value}: js_quote(value)
    case BIR.Boolean{value}: bool_source(value)
    case BIR.Null{}: "null"
    case BIR.Undefined{}: "undefined"
def arguments(values: List<&2, BIR.Arg>) -> List<&2, String>:
  match values:
    case Nil{}: Nil{}
    case BIR.Arg{_, value} <> rest: atom(value) <> arguments(rest)
def parameter_names(values: List<&2, BIR.Parameter>) -> List<&2, String>:
  match values:
    case Nil{}: Nil{}
    case BIR.Parameter{id, _} <> rest: local(id) <> parameter_names(rest)
def capture_names(values: List<&2, BIR.Use>, +index: U32) -> List<&2, String>:
  match values:
    case Nil{}: Nil{}
    case _ <> rest: capture(index) <> capture_names(rest, U32.inc(index))
def captured_names(values: List<&2, BIR.Arg>, +index: U32) -> List<&2, String>:
  match values:
    case Nil{}: Nil{}
    case _ <> rest: capture(index) <> captured_names(rest, U32.inc(index))
def call(code: U32, values: List<&2, String>) -> String:
  cat([code_name(code), "(", String.join(values, ","), ")"])
def tail_call(code: U32, +values: List<&2, String>) -> String:
  +count = List.length(&2, String, values)
  tail_call_selected(code, values, count, Bool.and(Nat.is_gt(count, 0n), Nat.is_le(count, 32n)))
def tail_call_selected(code: U32, values: List<&2, String>, count: Nat, selected: Bool) -> String:
  match selected:
    case True{}: cat(["run_named", Nat.show(count), "(", code_name(code), ",", String.join(values, ","), ",$td)"])
    case False{}: cat(["run_many(", code_name(code), ",[", String.join(values, ","), "],$td)"])
def public_closure(names: List<&2, String>, body: String) -> String:
  match names:
    case Nil{}: body
    case name <> rest:
      cat(["run_clo((", name, ",$raw=undefined)=>run_force(", public_closure(rest, body), ",$raw))"])
def closure(code: U32, +captures: List<&2, BIR.Arg>, +parameters: List<&2, BIR.Parameter>) -> String:
  +names = captured_names(captures, 0)
  +params = parameter_names(parameters)
  body = public_closure(params, tail_call(code, List.append(&2, String, names, params)))
  closure_captures(captures, names, body)
def closure_captures(+captures: List<&2, BIR.Arg>, names: List<&2, String>, body: String) -> String:
  match captures:
    case Nil{}: body
    case _: cat(["((", String.join(names, ","), ")=>", body, ")(", String.join(arguments(captures), ","), ")"])
def record_fields(fields: List<&2, BIR.Field>) -> String:
  match fields:
    case Nil{}: ""
    case BIR.Field{_, key, _, value} <> rest:
      cat([",[", js_quote(key), "]:", atom(value), record_fields(rest)])
def foreign(+path: String, +key: String, arity: Nat) -> String:
  cat(["$effect(require(", js_quote(path), ")[", js_quote(key), "],require(", js_quote(path), ")[", js_quote(String.append(key, "_need")), "],", Nat.show(arity), ")"])
def operation(op: BIR.Op) -> String:
  match op:
    case BIR.Copy{value}: atom(value)
    case BIR.PrimitiveCall{primitive, args}: cat([primitive_name(primitive), "(", String.join(arguments(args), ","), ")"])
    case BIR.Closure{code, captures, parameters}: closure(code, captures, parameters)
    case BIR.Direct{code, args}: cat(["run_loop(", call(code, arguments(args)), ")"])
    case BIR.Apply{fn, BIR.Arg{_, value}}: cat(["run_loop(run_tail(", atom(fn), ",", atom(value), "))"])
    case BIR.LoadSymbol{_, key}: cat(["$D[", js_quote(key), "]"])
    case BIR.Construct{_, tag, fields}: cat(["({$:", js_quote(tag), record_fields(fields), "})"])
    case BIR.Project{value, _, _, key}: cat([atom(value), "[", js_quote(key), "]"])
    case BIR.HasTag{value, _, tag}: tag_test(atom(value), tag)
    case BIR.DescriptorValue{value}: descriptor(value)
    case BIR.Foreign{path, key, arity}: foreign(path, key, arity)
def tag_test(+value: String, tag: String) -> String:
  cat(["(", value, "&&", value, ".$===", js_quote(tag), ")"])
# Group only immutable local/capture tag guards whose failure leaves that case.
# Distinct tags may jump directly; a failed nested pattern still reaches the
# original remaining cases. Keep every case label and condition binding.
def tag_subject_same(left: BIR.Atom, right: BIR.Atom) -> Bool:
  match left right:
    case BIR.Local{a} BIR.Local{b}: U32.is_eq(a, b)
    case BIR.Capture{a} BIR.Capture{b}: U32.is_eq(a, b)
    case _ _: False{}
def tagged_region_checked(valid: Bool, region: TaggedRegion) -> Maybe<&2, TaggedRegion>:
  match valid:
    case True{}: Some{region}
    case False{}: None{}
def tagged_region(input: BIR.Block) -> Maybe<&2, TaggedRegion>:
  match input:
    case BIR.Region{+label, BIR.Let{+condition, BIR.HasTag{+subject, _, tag}, BIR.Branch{BIR.Local{test}, body, BIR.LeaveRegion{failed}}}, rest}:
      tagged_region_checked(Bool.and(U32.is_eq(label, failed), Bool.and(U32.is_eq(condition, test), tag_subject_same(subject, subject))), TaggedRegion{label, condition, subject, tag, body, rest})
    case _: None{}
def tag_unseen(value: Maybe<&2, Bool>) -> Bool:
  match value:
    case None{}: True{}
    case Some{_}: False{}
def tag_group_selected(selected: Bool, subject: BIR.Atom, arm: TaggedRegion, input: BIR.Block, arms: List<&2, TagArm>, seen: Map<&2, Bool>, count: Nat) -> TagGroup:
  match selected:
    case False{}: TagGroup{arms, input, count}
    case True{}:
      match arm:
        case TaggedRegion{label, condition, _, +tag, body, rest}:
          tag_group(subject, rest, TagArm{label, condition, tag, body} <> arms, Map.set(&2, Bool, seen, tag, True{}), Nat.add(count, 1n))
def tag_group_view(view: Maybe<&2, TaggedRegion>, +subject: BIR.Atom, input: BIR.Block, arms: List<&2, TagArm>, +seen: Map<&2, Bool>, count: Nat) -> TagGroup:
  match view:
    case None{}: TagGroup{arms, input, count}
    case Some{+arm}:
      match arm:
        case TaggedRegion{_, _, candidate, +tag, _, _}:
          tag_group_selected(Bool.and(tag_subject_same(subject, candidate), tag_unseen(IndexLookup.find(Bool, seen, tag))), subject, arm, input, arms, seen, count)
def tag_group(subject: BIR.Atom, +input: BIR.Block, arms: List<&2, TagArm>, seen: Map<&2, Bool>, count: Nat) -> TagGroup:
  tag_group_view(tagged_region(input), subject, input, arms, seen, count)
def tag_arms(arms: List<&2, TagArm>) -> String:
  match arms:
    case Nil{}: ""
    case TagArm{label, condition, tag, body} <> rest:
      cat(["case ", js_quote(tag), ":{$case", U32.show(label), ":{const ", local(condition), "=true;", block(body), "}break;}", tag_arms(rest)])
def ordinary_region(label: U32, body: BIR.Block, next: BIR.Block) -> String:
  cat(["$case", U32.show(label), ":{", block(body), "}", block(next)])
def tag_render_selected(selected: Bool, subject: BIR.Atom, arms: List<&2, TagArm>, rest: BIR.Block, label: U32, body: BIR.Block, next: BIR.Block) -> String:
  match selected:
    case False{}: ordinary_region(label, body, next)
    case True{}: cat(["switch(", atom(subject), "?.$){", tag_arms(List.reverse(&2, TagArm, arms)), "}", block(rest)])
def tag_render_group(group: TagGroup, subject: BIR.Atom, label: U32, body: BIR.Block, next: BIR.Block) -> String:
  match group:
    case TagGroup{arms, rest, +count}: tag_render_selected(Nat.is_gt(count, 2n), subject, arms, rest, label, body, next)
def region_view(view: Maybe<&2, TaggedRegion>, label: U32, body: BIR.Block, next: BIR.Block) -> String:
  match view:
    case None{}: ordinary_region(label, body, next)
    case Some{arm}:
      match arm:
        case TaggedRegion{case_label, condition, +subject, +tag, case_body, rest}:
          tag_render_group(tag_group(subject, rest, [TagArm{case_label, condition, tag, case_body}], Map.set(&2, Bool, Map.new(&2, Bool), tag, True{}), 1n), subject, label, body, next)
def region(+label: U32, +body: BIR.Block, +next: BIR.Block) -> String:
  region_view(tagged_region(BIR.Region{label, body, next}), label, body, next)
def block(body: BIR.Block) -> String:
  match body:
    case BIR.Return{value}: cat(["return ", atom(value), ";"])
    case BIR.Let{id, op, next}: cat(["const ", local(id), "=", operation(op), ";", block(next)])
    case BIR.Branch{condition, yes, no}: cat(["if(", atom(condition), "){", block(yes), "}else{", block(no), "}"])
    case BIR.Region{label, body, next}: region(label, body, next)
    case BIR.LeaveRegion{label}: cat(["break $case", U32.show(label), ";"])
    case BIR.TailDirect{code, args}: cat(["return ", tail_call(code, arguments(args)), ";"])
    case BIR.TailApply{fn, BIR.Arg{_, value}}: cat(["return run_tail(", atom(fn), ",", atom(value), ");"])
    case BIR.Failure{message}: cat(["throw ", js_quote(message), ";"])
def code(item: BIR.Code) -> String:
  match item:
    case BIR.Code{id, captures, parameters, body}:
      names = List.append(&2, String, capture_names(captures, 0), parameter_names(parameters))
      cat(["function ", code_name(id), "(", String.join(List.append(&2, String, names, ["$td=0"]), ","), "){", block(body), "}\n"])
def codes(items: List<&2, BIR.Code>) -> String:
  match items:
    case Nil{}: ""
    case item <> rest: cat([code(item), codes(rest)])

def primitive_name(value: BIR.Primitive) -> String:
  match value:
    case BIR.PrimU32Add{}: "$p_u32_add"
    case BIR.PrimU32Sub{}: "$p_u32_sub"
    case BIR.PrimU32Mul{}: "$p_u32_mul"
    case BIR.PrimU32Div{}: "$p_u32_div"
    case BIR.PrimNatAdd{}: "$p_nat_add"
    case BIR.PrimNatSub{}: "$p_nat_sub"
    case BIR.PrimNatMul{}: "$p_nat_mul"
    case BIR.PrimNatCmp{}: "$p_nat_cmp"
    case BIR.PrimNatMin{}: "$p_nat_min"
    case BIR.PrimNatMax{}: "$p_nat_max"
    case BIR.PrimStringAppend{}: "$p_string_append"
    case BIR.PrimBoolOr{}: "$p_bool_or"
    case BIR.PrimBoolXor{}: "$p_bool_xor"
    case BIR.PrimU32IsZero{}: "$p_u32_is_zero"
    case BIR.PrimF32Asin{}: "$p_f32_asin"
    case BIR.PrimF32Acos{}: "$p_f32_acos"
    case BIR.PrimF32Atan{}: "$p_f32_atan"
    case BIR.PrimF32Sinh{}: "$p_f32_sinh"
    case BIR.PrimF32Cosh{}: "$p_f32_cosh"
    case BIR.PrimF32Tanh{}: "$p_f32_tanh"
    case BIR.PrimU32Mod{}: "$p_u32_mod"
    case BIR.PrimU32And{}: "$p_u32_and"
    case BIR.PrimU32Or{}: "$p_u32_or"
    case BIR.PrimU32Xor{}: "$p_u32_xor"
    case BIR.PrimU32IsEq{}: "$p_u32_is_eq"
    case BIR.PrimU32IsNe{}: "$p_u32_is_ne"
    case BIR.PrimU32IsLt{}: "$p_u32_is_lt"
    case BIR.PrimU32IsLe{}: "$p_u32_is_le"
    case BIR.PrimU32IsGt{}: "$p_u32_is_gt"
    case BIR.PrimU32IsGe{}: "$p_u32_is_ge"
    case BIR.PrimU32Inc{}: "$p_u32_inc"
    case BIR.PrimU32Not{}: "$p_u32_not"
    case BIR.PrimU32Shl{}: "$p_u32_shl"
    case BIR.PrimU32Shr{}: "$p_u32_shr"
    case BIR.PrimU32Shln{}: "$p_u32_shln"
    case BIR.PrimU32Shrn{}: "$p_u32_shrn"
    case BIR.PrimU32Cmp{}: "$p_u32_cmp"
    case BIR.PrimU32ToNat{}: "$p_u32_to_nat"
    case BIR.PrimU32FromNat{}: "$p_u32_from_nat"
    case BIR.PrimF32Add{}: "$p_f32_add"
    case BIR.PrimF32Sub{}: "$p_f32_sub"
    case BIR.PrimF32Mul{}: "$p_f32_mul"
    case BIR.PrimF32Div{}: "$p_f32_div"
    case BIR.PrimF32Mod{}: "$p_f32_mod"
    case BIR.PrimF32Neg{}: "$p_f32_neg"
    case BIR.PrimF32Sqrt{}: "$p_f32_sqrt"
    case BIR.PrimF32Abs{}: "$p_f32_abs"
    case BIR.PrimF32ToU32{}: "$p_f32_to_u32"
    case BIR.PrimF32Bits{}: "$p_f32_bits"
    case BIR.PrimF32Show{}: "$p_f32_show"
    case BIR.PrimF32Read{}: "$p_f32_read"
    case BIR.PrimF32IsEq{}: "$p_f32_is_eq"
    case BIR.PrimF32IsNe{}: "$p_f32_is_ne"
    case BIR.PrimF32IsLt{}: "$p_f32_is_lt"
    case BIR.PrimF32IsLe{}: "$p_f32_is_le"
    case BIR.PrimF32IsGt{}: "$p_f32_is_gt"
    case BIR.PrimF32IsGe{}: "$p_f32_is_ge"
    case BIR.PrimF32Pow{}: "$p_f32_pow"
    case BIR.PrimF32Atan2{}: "$p_f32_atan2"
    case BIR.PrimF32Exp{}: "$p_f32_exp"
    case BIR.PrimF32Log{}: "$p_f32_log"
    case BIR.PrimF32Log2{}: "$p_f32_log2"
    case BIR.PrimF32Log10{}: "$p_f32_log10"
    case BIR.PrimF32Sin{}: "$p_f32_sin"
    case BIR.PrimF32Cos{}: "$p_f32_cos"
    case BIR.PrimF32Tan{}: "$p_f32_tan"
    case BIR.PrimF32Floor{}: "$p_f32_floor"
    case BIR.PrimF32Ceil{}: "$p_f32_ceil"
    case BIR.PrimF32Trunc{}: "$p_f32_trunc"
    case BIR.PrimF32ToNat{}: "$p_f32_to_nat"
    case BIR.PrimU32ToF32{}: "$p_u32_to_f32"
    case BIR.PrimNatDouble{}: "$p_nat_double"
    case BIR.PrimNatIsLt{}: "$p_nat_is_lt"
    case BIR.PrimNatDivmod{}: "$p_nat_divmod"
    case BIR.PrimStringEq{}: "$p_string_eq"
    case BIR.PrimMapBit{}: "$p_map_bit"
    case BIR.PrimStringCmp{}: "$p_string_cmp"
    case BIR.PrimStringToList{}: "$p_string_to_list"
    case BIR.PrimStringLength{}: "$p_string_length"
    case BIR.PrimArrayNew{}: "$p_array_new"
    case BIR.PrimArraySet{}: "$p_array_set"
    case BIR.PrimArrayGet{}: "$p_array_get"
    case BIR.PrimArraySwap{}: "$p_array_swap"
    case BIR.PrimArraySize{}: "$p_array_size"
    case BIR.PrimArrayClone{}: "$p_array_clone"
    case BIR.PrimNatPredecessor{}: "$p_nat_predecessor"
    case BIR.PrimNatSuccessor{}: "$p_nat_successor"
    case BIR.PrimCharNew{}: "$p_char_new"
    case BIR.PrimCharCode{}: "$p_char_code"
    case BIR.PrimStringHead{}: "$p_string_head"
    case BIR.PrimStringTail{}: "$p_string_tail"
    case BIR.PrimWordToU32{}: "$p_word_to_u32"
    case BIR.PrimU32ToWord{}: "$p_u32_to_word"
    case BIR.PrimF32FromBits{}: "$p_f32_from_bits"
    case BIR.PrimF32FromWord{}: "$p_f32_from_word"
    case BIR.PrimF32ToWord{}: "$p_f32_to_word"
    case BIR.PrimArrayLeaf{}: "$p_array_leaf"
    case BIR.PrimArrayNode{}: "$p_array_node"
    case BIR.PrimArrayLeafValue{}: "$p_array_leaf_value"
    case BIR.PrimArrayLeft{}: "$p_array_left"
    case BIR.PrimArrayRight{}: "$p_array_right"
    case BIR.PrimIsArrayLeaf{}: "$p_is_array_leaf"
    case BIR.PrimIsArrayNode{}: "$p_is_array_node"
    case BIR.PrimIsNatZero{}: "$p_is_nat_zero"
    case BIR.PrimIsNatSuccessor{}: "$p_is_nat_successor"
    case BIR.PrimIsStringEmpty{}: "$p_is_string_empty"
    case BIR.PrimIsStringNonempty{}: "$p_is_string_nonempty"
    case BIR.PrimIsTrue{}: "$p_is_true"
    case BIR.PrimIsFalse{}: "$p_is_false"
    case BIR.PrimSameValue{}: "$p_same_value"
    case BIR.PrimFloatBitsEqual{}: "$p_float_bits_equal"

def primitive_public(value: BIR.Primitive) -> String:
  match value:
    case BIR.PrimU32Add{}: "(a)=>(b)=>((a+b)>>>0)"
    case BIR.PrimU32Sub{}: "(a)=>(b)=>((a-b)>>>0)"
    case BIR.PrimU32Mul{}: "(a)=>(b)=>(Math.imul(a,b)>>>0)"
    case BIR.PrimU32Div{}: "(a)=>(b)=>(b===0?0:(a/b)>>>0)"
    case BIR.PrimNatAdd{}: "(a)=>(b)=>nat_chk(a+b)"
    case BIR.PrimNatSub{}: "(a)=>(b)=>(a<b?0:a-b)"
    case BIR.PrimNatMul{}: "(a)=>(b)=>nat_chk(a*b)"
    case BIR.PrimNatCmp{}: "(a)=>(b)=>cmp_new(a,b)"
    case BIR.PrimNatMin{}: "(a)=>(b)=>(a<b?a:b)"
    case BIR.PrimNatMax{}: "(a)=>(b)=>(a>b?a:b)"
    case BIR.PrimStringAppend{}: "(a)=>(b)=>a+b"
    case BIR.PrimBoolOr{}: "(a)=>(b)=>a||b"
    case BIR.PrimBoolXor{}: "(a)=>(b)=>a!==b"
    case BIR.PrimU32IsZero{}: "(a)=>a===0"
    case BIR.PrimF32Asin{}: "(a)=>Math.fround(Math.asin(a))"
    case BIR.PrimF32Acos{}: "(a)=>Math.fround(Math.acos(a))"
    case BIR.PrimF32Atan{}: "(a)=>Math.fround(Math.atan(a))"
    case BIR.PrimF32Sinh{}: "(a)=>Math.fround(Math.sinh(a))"
    case BIR.PrimF32Cosh{}: "(a)=>Math.fround(Math.cosh(a))"
    case BIR.PrimF32Tanh{}: "(a)=>Math.fround(Math.tanh(a))"
    case BIR.PrimU32Mod{}: "(a)=>(b)=>(b===0?a:a%b)"
    case BIR.PrimU32And{}: "(a)=>(b)=>((a&b)>>>0)"
    case BIR.PrimU32Or{}: "(a)=>(b)=>((a|b)>>>0)"
    case BIR.PrimU32Xor{}: "(a)=>(b)=>((a^b)>>>0)"
    case BIR.PrimU32IsEq{}: "(a)=>(b)=>a===b"
    case BIR.PrimU32IsNe{}: "(a)=>(b)=>a!==b"
    case BIR.PrimU32IsLt{}: "(a)=>(b)=>a<b"
    case BIR.PrimU32IsLe{}: "(a)=>(b)=>a<=b"
    case BIR.PrimU32IsGt{}: "(a)=>(b)=>a>b"
    case BIR.PrimU32IsGe{}: "(a)=>(b)=>a>=b"
    case BIR.PrimU32Inc{}: "(a)=>(a+1)>>>0"
    case BIR.PrimU32Not{}: "(a)=>(~a)>>>0"
    case BIR.PrimU32Shl{}: "(a)=>(a<<1)>>>0"
    case BIR.PrimU32Shr{}: "(a)=>a>>>1"
    case BIR.PrimU32Shln{}: "(a)=>(b)=>b>=32?0:(a<<b)>>>0"
    case BIR.PrimU32Shrn{}: "(a)=>(b)=>b>=32?0:a>>>b"
    case BIR.PrimU32Cmp{}: "(a)=>(b)=>cmp_new(a,b)"
    case BIR.PrimU32ToNat{}: "(a)=>a"
    case BIR.PrimU32FromNat{}: "(a)=>a>>>0"
    case BIR.PrimF32Add{}: "(a)=>(b)=>Math.fround(a+b)"
    case BIR.PrimF32Sub{}: "(a)=>(b)=>Math.fround(a-b)"
    case BIR.PrimF32Mul{}: "(a)=>(b)=>Math.fround(a*b)"
    case BIR.PrimF32Div{}: "(a)=>(b)=>Math.fround(a/b)"
    case BIR.PrimF32Mod{}: "(a)=>(b)=>Math.fround(a%b)"
    case BIR.PrimF32Neg{}: "(a)=>-a"
    case BIR.PrimF32Sqrt{}: "(a)=>Math.fround(Math.sqrt(a))"
    case BIR.PrimF32Abs{}: "(a)=>Math.fround(Math.abs(a))"
    case BIR.PrimF32ToU32{}: "(a)=>(a>=1&&a<4294967296?Math.floor(a):0)"
    case BIR.PrimF32Bits{}: "(a)=>f32_bits(a)"
    case BIR.PrimF32Show{}: "(a)=>f32_show(a)"
    case BIR.PrimF32Read{}: "(a)=>f32_read(a)"
    case BIR.PrimF32IsEq{}: "(a)=>(b)=>a===b"
    case BIR.PrimF32IsNe{}: "(a)=>(b)=>a!==b"
    case BIR.PrimF32IsLt{}: "(a)=>(b)=>a<b"
    case BIR.PrimF32IsLe{}: "(a)=>(b)=>a<=b"
    case BIR.PrimF32IsGt{}: "(a)=>(b)=>a>b"
    case BIR.PrimF32IsGe{}: "(a)=>(b)=>a>=b"
    case BIR.PrimF32Pow{}: "(a)=>(b)=>Math.fround(Math.pow(a,b))"
    case BIR.PrimF32Atan2{}: "(a)=>(b)=>Math.fround(Math.atan2(a,b))"
    case BIR.PrimF32Exp{}: "(a)=>Math.fround(Math.exp(a))"
    case BIR.PrimF32Log{}: "(a)=>Math.fround(Math.log(a))"
    case BIR.PrimF32Log2{}: "(a)=>Math.fround(Math.log2(a))"
    case BIR.PrimF32Log10{}: "(a)=>Math.fround(Math.log10(a))"
    case BIR.PrimF32Sin{}: "(a)=>Math.fround(Math.sin(a))"
    case BIR.PrimF32Cos{}: "(a)=>Math.fround(Math.cos(a))"
    case BIR.PrimF32Tan{}: "(a)=>Math.fround(Math.tan(a))"
    case BIR.PrimF32Floor{}: "(a)=>Math.fround(Math.floor(a))"
    case BIR.PrimF32Ceil{}: "(a)=>Math.fround(Math.ceil(a))"
    case BIR.PrimF32Trunc{}: "(a)=>Math.fround(Math.trunc(a))"
    case BIR.PrimF32ToNat{}: "(a)=>Math.floor(a)"
    case BIR.PrimU32ToF32{}: "(a)=>Math.fround(a)"
    case BIR.PrimNatDouble{}: "(a)=>nat_chk(a+a)"
    case BIR.PrimNatIsLt{}: "(a)=>(b)=>a<b"
    case BIR.PrimNatDivmod{}: "(a)=>(b)=>nat_divmod(a,b)"
    case BIR.PrimStringEq{}: "(a)=>(b)=>a===b"
    case BIR.PrimMapBit{}: "(key)=>(position)=>{const character=Math.floor(position/33);if(character>=key.length)return tuple(key,false);const offset=position%33;let at=0;for(let i=0;i<character&&at<key.length;i++)at+=key.codePointAt(at)>65535?2:1;return tuple(key,at<key.length&&(offset===0||((key.codePointAt(at)>>>(32-offset))&1)!==0));}"
    case BIR.PrimStringCmp{}: "(a)=>(b)=>{let i=0,j=0,order=0;if(a!==b){while(i<a.length&&j<b.length){const x=a.codePointAt(i),y=b.codePointAt(j);if(x!==y){order=x<y?-1:1;break;}i+=x>65535?2:1;j+=y>65535?2:1;}if(order===0)order=i<a.length?1:j<b.length?-1:0;}return tuple(tuple(a,b),cmp_new(order,0));}"
    case BIR.PrimStringToList{}: "(text)=>{let tail={$:\"Nil\"};for(let i=text.length;i>0;){const end=i,low=text.charCodeAt(--i);if(low>=0xDC00&&low<=0xDFFF&&i>0){const high=text.charCodeAt(i-1);if(high>=0xD800&&high<=0xDBFF)--i;}tail={$:\"Con\",head:text.slice(i,end),tail};}return tail;}"
    case BIR.PrimStringLength{}: "(a)=>[...a].length"
    case BIR.PrimArrayNew{}: "(a)=>(b)=>array_new(a,b)"
    case BIR.PrimArraySet{}: "(a)=>(i)=>(v)=>(a[i%a.length]=v,a)"
    case BIR.PrimArrayGet{}: "(a)=>(i)=>tuple(a,a[i%a.length])"
    case BIR.PrimArraySwap{}: "(a)=>(i)=>(v)=>array_swap(a,i,v)"
    case BIR.PrimArraySize{}: "(a)=>tuple(a,a.length)"
    case BIR.PrimArrayClone{}: "(a)=>tuple(a,a.slice())"
    case BIR.PrimNatPredecessor{}: "(a)=>a-1"
    case BIR.PrimNatSuccessor{}: "(a)=>nat_chk(a+1)"
    case BIR.PrimCharNew{}: "(a)=>char_new(a)"
    case BIR.PrimCharCode{}: "(a)=>a.codePointAt(0)"
    case BIR.PrimStringHead{}: "(a)=>String.fromCodePoint(a.codePointAt(0))"
    case BIR.PrimStringTail{}: "(a)=>$string_tail(a)"
    case BIR.PrimWordToU32{}: "(a)=>word_to_u32(a)"
    case BIR.PrimU32ToWord{}: "(a)=>u32_to_word(a)"
    case BIR.PrimF32FromBits{}: "(a)=>f32_from_bits(a)"
    case BIR.PrimF32FromWord{}: "(a)=>f32_from_bits(word_to_u32(a))"
    case BIR.PrimF32ToWord{}: "(a)=>u32_to_word(f32_bits(a))"
    case BIR.PrimArrayLeaf{}: "(a)=>[a]"
    case BIR.PrimArrayNode{}: "(a)=>(b)=>array_node(a,b)"
    case BIR.PrimArrayLeafValue{}: "(a)=>a[0]"
    case BIR.PrimArrayLeft{}: "(a)=>a.slice(0,a.length>>1)"
    case BIR.PrimArrayRight{}: "(a)=>a.slice(a.length>>1)"
    case BIR.PrimIsArrayLeaf{}: "(a)=>a.length===1"
    case BIR.PrimIsArrayNode{}: "(a)=>a.length!==1"
    case BIR.PrimIsNatZero{}: "(a)=>a===0"
    case BIR.PrimIsNatSuccessor{}: "(a)=>a>0"
    case BIR.PrimIsStringEmpty{}: "(a)=>a===\"\""
    case BIR.PrimIsStringNonempty{}: "(a)=>a!==\"\""
    case BIR.PrimIsTrue{}: "(a)=>a===true"
    case BIR.PrimIsFalse{}: "(a)=>a===false"
    case BIR.PrimSameValue{}: "(a)=>(b)=>a===b"
    case BIR.PrimFloatBitsEqual{}: "(a)=>(b)=>f32_bits(a)===b"

def primitive_runtime() -> String:
  "const $p_u32_add=(a,b)=>((a+b)>>>0);\nconst $p_u32_sub=(a,b)=>((a-b)>>>0);\nconst $p_u32_mul=(a,b)=>(Math.imul(a,b)>>>0);\nconst $p_u32_div=(a,b)=>(b===0?0:(a/b)>>>0);\nconst $p_nat_add=(a,b)=>nat_chk(a+b);\nconst $p_nat_sub=(a,b)=>(a<b?0:a-b);\nconst $p_nat_mul=(a,b)=>nat_chk(a*b);\nconst $p_nat_cmp=(a,b)=>cmp_new(a,b);\nconst $p_nat_min=(a,b)=>(a<b?a:b);\nconst $p_nat_max=(a,b)=>(a>b?a:b);\nconst $p_string_append=(a,b)=>a+b;\nconst $p_bool_or=(a,b)=>a||b;\nconst $p_bool_xor=(a,b)=>a!==b;\nconst $p_u32_is_zero=(a)=>a===0;\nconst $p_f32_asin=(a)=>Math.fround(Math.asin(a));\nconst $p_f32_acos=(a)=>Math.fround(Math.acos(a));\nconst $p_f32_atan=(a)=>Math.fround(Math.atan(a));\nconst $p_f32_sinh=(a)=>Math.fround(Math.sinh(a));\nconst $p_f32_cosh=(a)=>Math.fround(Math.cosh(a));\nconst $p_f32_tanh=(a)=>Math.fround(Math.tanh(a));\nconst $p_u32_mod=(a,b)=>(b===0?a:a%b);\nconst $p_u32_and=(a,b)=>((a&b)>>>0);\nconst $p_u32_or=(a,b)=>((a|b)>>>0);\nconst $p_u32_xor=(a,b)=>((a^b)>>>0);\nconst $p_u32_is_eq=(a,b)=>a===b;\nconst $p_u32_is_ne=(a,b)=>a!==b;\nconst $p_u32_is_lt=(a,b)=>a<b;\nconst $p_u32_is_le=(a,b)=>a<=b;\nconst $p_u32_is_gt=(a,b)=>a>b;\nconst $p_u32_is_ge=(a,b)=>a>=b;\nconst $p_u32_inc=(a)=>(a+1)>>>0;\nconst $p_u32_not=(a)=>(~a)>>>0;\nconst $p_u32_shl=(a)=>(a<<1)>>>0;\nconst $p_u32_shr=(a)=>a>>>1;\nconst $p_u32_shln=(a,b)=>b>=32?0:(a<<b)>>>0;\nconst $p_u32_shrn=(a,b)=>b>=32?0:a>>>b;\nconst $p_u32_cmp=(a,b)=>cmp_new(a,b);\nconst $p_u32_to_nat=(a)=>a;\nconst $p_u32_from_nat=(a)=>a>>>0;\nconst $p_f32_add=(a,b)=>Math.fround(a+b);\nconst $p_f32_sub=(a,b)=>Math.fround(a-b);\nconst $p_f32_mul=(a,b)=>Math.fround(a*b);\nconst $p_f32_div=(a,b)=>Math.fround(a/b);\nconst $p_f32_mod=(a,b)=>Math.fround(a%b);\nconst $p_f32_neg=(a)=>-a;\nconst $p_f32_sqrt=(a)=>Math.fround(Math.sqrt(a));\nconst $p_f32_abs=(a)=>Math.fround(Math.abs(a));\nconst $p_f32_to_u32=(a)=>(a>=1&&a<4294967296?Math.floor(a):0);\nconst $p_f32_bits=(a)=>f32_bits(a);\nconst $p_f32_show=(a)=>f32_show(a);\nconst $p_f32_read=(a)=>f32_read(a);\nconst $p_f32_is_eq=(a,b)=>a===b;\nconst $p_f32_is_ne=(a,b)=>a!==b;\nconst $p_f32_is_lt=(a,b)=>a<b;\nconst $p_f32_is_le=(a,b)=>a<=b;\nconst $p_f32_is_gt=(a,b)=>a>b;\nconst $p_f32_is_ge=(a,b)=>a>=b;\nconst $p_f32_pow=(a,b)=>Math.fround(Math.pow(a,b));\nconst $p_f32_atan2=(a,b)=>Math.fround(Math.atan2(a,b));\nconst $p_f32_exp=(a)=>Math.fround(Math.exp(a));\nconst $p_f32_log=(a)=>Math.fround(Math.log(a));\nconst $p_f32_log2=(a)=>Math.fround(Math.log2(a));\nconst $p_f32_log10=(a)=>Math.fround(Math.log10(a));\nconst $p_f32_sin=(a)=>Math.fround(Math.sin(a));\nconst $p_f32_cos=(a)=>Math.fround(Math.cos(a));\nconst $p_f32_tan=(a)=>Math.fround(Math.tan(a));\nconst $p_f32_floor=(a)=>Math.fround(Math.floor(a));\nconst $p_f32_ceil=(a)=>Math.fround(Math.ceil(a));\nconst $p_f32_trunc=(a)=>Math.fround(Math.trunc(a));\nconst $p_f32_to_nat=(a)=>Math.floor(a);\nconst $p_u32_to_f32=(a)=>Math.fround(a);\nconst $p_nat_double=(a)=>nat_chk(a+a);\nconst $p_nat_is_lt=(a,b)=>a<b;\nconst $p_nat_divmod=(a,b)=>nat_divmod(a,b);\nconst $p_string_eq=(a,b)=>a===b;\nconst $p_map_bit=(key,position)=>{const character=Math.floor(position/33);if(character>=key.length)return tuple(key,false);const offset=position%33;let at=0;for(let i=0;i<character&&at<key.length;i++)at+=key.codePointAt(at)>65535?2:1;return tuple(key,at<key.length&&(offset===0||((key.codePointAt(at)>>>(32-offset))&1)!==0));};\nconst $p_string_cmp=(a,b)=>{let i=0,j=0,order=0;if(a!==b){while(i<a.length&&j<b.length){const x=a.codePointAt(i),y=b.codePointAt(j);if(x!==y){order=x<y?-1:1;break;}i+=x>65535?2:1;j+=y>65535?2:1;}if(order===0)order=i<a.length?1:j<b.length?-1:0;}return tuple(tuple(a,b),cmp_new(order,0));};\nconst $p_string_to_list=(text)=>{let tail={$:\"Nil\"};for(let i=text.length;i>0;){const end=i,low=text.charCodeAt(--i);if(low>=0xDC00&&low<=0xDFFF&&i>0){const high=text.charCodeAt(i-1);if(high>=0xD800&&high<=0xDBFF)--i;}tail={$:\"Con\",head:text.slice(i,end),tail};}return tail;};\nconst $p_string_length=(a)=>[...a].length;\nconst $p_array_new=(a,b)=>array_new(a,b);\nconst $p_array_set=(a,i,v)=>(a[i%a.length]=v,a);\nconst $p_array_get=(a,i)=>tuple(a,a[i%a.length]);\nconst $p_array_swap=(a,i,v)=>array_swap(a,i,v);\nconst $p_array_size=(a)=>tuple(a,a.length);\nconst $p_array_clone=(a)=>tuple(a,a.slice());\nconst $p_nat_predecessor=(a)=>a-1;\nconst $p_nat_successor=(a)=>nat_chk(a+1);\nconst $p_char_new=(a)=>char_new(a);\nconst $p_char_code=(a)=>a.codePointAt(0);\nconst $p_string_head=(a)=>String.fromCodePoint(a.codePointAt(0));\nconst $p_string_tail=(a)=>$string_tail(a);\nconst $p_word_to_u32=(a)=>word_to_u32(a);\nconst $p_u32_to_word=(a)=>u32_to_word(a);\nconst $p_f32_from_bits=(a)=>f32_from_bits(a);\nconst $p_f32_from_word=(a)=>f32_from_bits(word_to_u32(a));\nconst $p_f32_to_word=(a)=>u32_to_word(f32_bits(a));\nconst $p_array_leaf=(a)=>[a];\nconst $p_array_node=(a,b)=>array_node(a,b);\nconst $p_array_leaf_value=(a)=>a[0];\nconst $p_array_left=(a)=>a.slice(0,a.length>>1);\nconst $p_array_right=(a)=>a.slice(a.length>>1);\nconst $p_is_array_leaf=(a)=>a.length===1;\nconst $p_is_array_node=(a)=>a.length!==1;\nconst $p_is_nat_zero=(a)=>a===0;\nconst $p_is_nat_successor=(a)=>a>0;\nconst $p_is_string_empty=(a)=>a===\"\";\nconst $p_is_string_nonempty=(a)=>a!==\"\";\nconst $p_is_true=(a)=>a===true;\nconst $p_is_false=(a)=>a===false;\nconst $p_same_value=(a,b)=>a===b;\nconst $p_float_bits_equal=(a,b)=>f32_bits(a)===b;\n"

def quantity(value: BIR.Quantity) -> String:
  match value:
    case BIR.Erased{}: "0"
    case BIR.Once{}: "1"
    case BIR.Unrestricted{}: "2"
def optional_quantity(value: Maybe<&2, BIR.Quantity>) -> String:
  match value:
    case None{}: "null"
    case Some{item}: quantity(item)
def quantities(values: List<&2, BIR.Quantity>) -> List<&2, String>:
  match values:
    case Nil{}: Nil{}
    case value <> rest: quantity(value) <> quantities(rest)
def descriptor_pattern(value: BIR.DescriptorPattern) -> String:
  match value:
    case BIR.DescriptorBinder{use}: cat(["({v:true,q:", quantity(use), "})"])
    case BIR.DescriptorConstructorPattern{key, fields}:
      cat(["({c:", js_quote(key), ",s:\"\",i:{},fields:[", String.join(descriptor_patterns(fields), ","), "]})"])
def descriptor_patterns(values: List<&2, BIR.DescriptorPattern>) -> List<&2, String>:
  match values:
    case Nil{}: Nil{}
    case value <> rest: descriptor_pattern(value) <> descriptor_patterns(rest)
def descriptors(values: List<&2, BIR.Descriptor>) -> List<&2, String>:
  match values:
    case Nil{}: Nil{}
    case value <> rest: descriptor(value) <> descriptors(rest)

def descriptor(value: BIR.Descriptor) -> String:
  match value:
    case BIR.DescriptorNull{}: cat(["null"])
    case BIR.DescriptorRef{key, args}: cat(["({r:", js_quote(key), ",a:[", String.join(descriptors(args), ","), "],s:\"\",i:{}})"])
    case BIR.DescriptorParameter{index}: cat(["({p:", Nat.show(index), "})"])
    case BIR.DescriptorQuantityKind{}: cat(["({k:\"QK\"})"])
    case BIR.DescriptorQuantity{value}: cat(["({k:\"Q\",v:", quantity(value), "})"])
    case BIR.DescriptorKind{value}: cat(["({kind:", descriptor(value), "})"])
    case BIR.DescriptorMinimum{left, right}: cat(["({min:", descriptor(left), ",right:", descriptor(right), "})"])
    case BIR.DescriptorArrow{use, domain, body}: cat(["({all:", descriptor(domain), ",q:", quantity(use), ",body:", descriptor(body), "})"])
    case BIR.DescriptorLambda{use, body}: cat(["({lam:", descriptor(body), ",q:", optional_quantity(use), "})"])
    case BIR.DescriptorConstructor{key, args}: cat(["({c:", js_quote(key), ",a:[", String.join(descriptors(args), ","), "],s:\"\",i:{}})"])
    case BIR.DescriptorApplication{fn, arg}: cat(["({app:", descriptor(fn), ",arg:", descriptor(arg), "})"])
    case BIR.DescriptorSubstitution{index, value, body}: cat(["({sub:", Nat.show(index), ",value:", descriptor(value), ",body:", descriptor(body), "})"])
    case BIR.DescriptorLet{values, body}: cat(["({let:[", String.join(descriptors(values), ","), "],body:", descriptor(body), "})"])
    case BIR.DescriptorLocal{patterns, values, body}: cat(["({local:[", String.join(descriptors(values), ","), "],pat:[", String.join(descriptor_patterns(patterns), ","), "],body:", descriptor(body), "})"])
    case BIR.DescriptorMatch{values, cases}: cat(["({match:[", String.join(descriptors(values), ","), "],cases:[", String.join(descriptors(cases), ","), "]})"])
    case BIR.DescriptorCase{patterns, body}: cat(["({pat:[", String.join(descriptor_patterns(patterns), ","), "],body:", descriptor(body), "})"])
    case BIR.DescriptorBind{value, body}: cat(["({bind:", descriptor(value), ",body:", descriptor(body), "})"])
    case BIR.DescriptorEquality{left, right, ty}: cat(["({k:\"E\",left:", descriptor(left), ",right:", descriptor(right), ",ty:", descriptor(ty), "})"])
    case BIR.DescriptorReflexivity{}: cat(["({k:\"Refl\"})"])
    case BIR.DescriptorFailure{message}: cat(["({fail:", js_quote(message), "})"])
    case BIR.DescriptorFill{head, args}: cat(["({sugar:", descriptor(head), ",a:[", String.join(descriptors(args), ","), "],f:1})"])
    case BIR.DescriptorPlus{head, args}: cat(["({sugar:", descriptor(head), ",a:[", String.join(descriptors(args), ","), "],f:2})"])
    case BIR.DescriptorNamedFill{key, head, args}: cat(["({r:", js_quote(key), ",h:", descriptor(head), ",a:[", String.join(descriptors(args), ","), "],s:\"\",i:{},f:1})"])
    case BIR.DescriptorNamedPlus{key, head, args}: cat(["({r:", js_quote(key), ",h:", descriptor(head), ",a:[", String.join(descriptors(args), ","), "],s:\"\",i:{},f:2})"])

def deferred(key: String, value: String) -> String:
  cat(["Object.defineProperty($D,", js_quote(key), ",{enumerable:true,configurable:true,get(){return run_loop(", value, ");}});\n"])
def declaration(item: BIR.Declaration) -> String:
  match item:
    case BIR.FunctionDeclaration{key, code, parameters}:
      cat(["$D[", js_quote(key), "]=", closure(code, Nil{}, parameters), ";\n"])
    case BIR.LazyDeclaration{key, body}:
      deferred(key, cat(["(()=>{", block(body), "})()"]))
    case BIR.NativeDeclaration{key, primitive, uses}:
      native_declaration(key, primitive, uses)
    case BIR.ForeignDeclaration{key, path, imported, arity}:
      deferred(key, foreign(path, imported, arity))
def native_declaration(+key: String, primitive: BIR.Primitive, +uses: List<&2, BIR.Quantity>) -> String:
  cat(["$D[", js_quote(key), "]=", primitive_public(primitive), ";\n$TYPEF[", js_quote(key), "]={n:", Nat.show(List.length(&2, BIR.Quantity, uses)), ",q:[", String.join(quantities(uses), ","), "],intrinsic:$D[", js_quote(key), "]};\n"])
def declarations(items: List<&2, BIR.Declaration>) -> String:
  match items:
    case Nil{}: ""
    case item <> rest: cat([declaration(item), declarations(rest)])
def field_names(items: List<&2, Maybe<&2, String>>) -> List<&2, String>:
  match items:
    case Nil{}: Nil{}
    case item <> rest: optional_text(item) <> field_names(rest)
def constructor_layout(item: BIR.ConstructorLayout) -> String:
  match item:
    case BIR.ConstructorLayout{_, key, native, fields}:
      constructor_layout_source(key, optional_text(native), String.join(field_names(fields), ","))
def constructor_layout_source(+key: String, native: String, fields: String) -> String:
  cat(["$FIELDS[", js_quote(key), "]=[", fields, "];\n$PRIMITIVES[", js_quote(key), "]=", native, ";\n"])
def constructor_layouts(items: List<&2, BIR.ConstructorLayout>) -> String:
  match items:
    case Nil{}: ""
    case item <> rest: cat([constructor_layout(item), constructor_layouts(rest)])
def descriptor_field_types(items: List<&2, BIR.DescriptorField>) -> List<&2, String>:
  match items:
    case Nil{}: Nil{}
    case BIR.DescriptorField{_, _, ty} <> rest: descriptor(ty) <> descriptor_field_types(rest)
def descriptor_field_quantities(items: List<&2, BIR.DescriptorField>) -> List<&2, String>:
  match items:
    case Nil{}: Nil{}
    case BIR.DescriptorField{_, use, _} <> rest: quantity(use) <> descriptor_field_quantities(rest)
def descriptor_field_names(items: List<&2, BIR.DescriptorField>) -> List<&2, String>:
  match items:
    case Nil{}: Nil{}
    case BIR.DescriptorField{key, _, _} <> rest: optional_text(key) <> descriptor_field_names(rest)
def descriptor_arm(item: BIR.DescriptorArm) -> String:
  match item:
    case BIR.DescriptorArm{key, +fields}:
      cat(["[", js_quote(key), "]:{types:[", String.join(descriptor_field_types(fields), ","), "],q:[", String.join(descriptor_field_quantities(fields), ","), "],fields:[", String.join(descriptor_field_names(fields), ","), "]}"])
def descriptor_arms(items: List<&2, BIR.DescriptorArm>) -> List<&2, String>:
  match items:
    case Nil{}: Nil{}
    case item <> rest: descriptor_arm(item) <> descriptor_arms(rest)
def parameter_info(key: String, prefix: Nat, arity: Nat) -> String:
  cat(["$PARAMS[", js_quote(key), "]={q:", Nat.show(prefix), ",n:", Nat.show(arity), "};\n"])
def family(item: BIR.Family) -> String:
  match item:
    case BIR.Family{+key, name, native, prefix, arity, arms}:
      cat([parameter_info(key, prefix, arity), "$TYPE[", js_quote(key), "]={name:", js_quote(name), ",native:", optional_text(native), ",arms:{", String.join(descriptor_arms(arms), ","), "}};\n"])
def families(items: List<&2, BIR.Family>) -> String:
  match items:
    case Nil{}: ""
    case item <> rest: cat([family(item), families(rest)])
def type_function(item: BIR.TypeFunction) -> String:
  match item:
    case BIR.TypeFunction{+key, native, prefix, +arity, body}:
      cat([parameter_info(key, prefix, arity), "$TYPEF[", js_quote(key), "]={n:", Nat.show(arity), ",native:", optional_text(native), ",body:", descriptor(body), "};\n"])
def type_functions(items: List<&2, BIR.TypeFunction>) -> String:
  match items:
    case Nil{}: ""
    case item <> rest: cat([type_function(item), type_functions(rest)])
def export_arguments(count: Nat, index: Nat) -> List<&2, String>:
  match count:
    case 0n: Nil{}
    case 1n+rest: cat(["arguments[", Nat.show(index), "]"]) <> export_arguments(rest, (index + 1n : Nat))
def export_field(item: BIR.Export) -> String:
  match item:
    case BIR.Export{+key, None{}}:
      cat(["[", js_quote(key), "]:(...args)=>$run($D[", js_quote(key), "],args)"])
    case BIR.Export{+key, Some{BIR.Entry{code, +arity}}}:
      cat(["[", js_quote(key), "](){return arguments.length===", Nat.show(arity), "?run_loop(", call(code, export_arguments(arity, 0n)), "):$run($D[", js_quote(key), "],arguments);}"])
def export_fields(items: List<&2, BIR.Export>) -> List<&2, String>:
  match items:
    case Nil{}: Nil{}
    case item <> rest: export_field(item) <> export_fields(rest)
def ending(item: BIR.Ending) -> String:
  match item:
    case BIR.Executable{main_type}: js_main(descriptor(main_type))
    case BIR.Library{exports}: cat(["export default {", String.join(export_fields(exports), ","), "};\n"])
def emit(program: BIR.Program) -> String:
  match program:
    case BIR.Program{bodies, values, layouts, types, functions, end}:
      cat([js_runtime(), js_runtime_extra(), js_runtime_show(), js_runtime_cli(), js_runtime_io(), js_runtime_array(), js_runtime_foreign(), js_runtime_namespace(), primitive_runtime(), constructor_layouts(layouts), families(types), type_functions(functions), codes(bodies), declarations(values), ending(end)])

# Trusted target runtime; public/native callback and reflection ABI is retained.
def js_runtime() -> String:
  "const $D = Object.create(null);\nconst $BEND_TAIL = Symbol(\"bend.tail\");\nconst $td = 64;\nconst $TAIL_PENDING = Object.create(null), $tailArgs = Array(32);\nlet $tailFn, $tailCount=0, $tailUnary, $tailRest;\nfunction tail_many(f,a) { $tailFn=f; $tailCount=-2; $tailRest=a; return $TAIL_PENDING; }\nfunction tail_unary(f,x) { $tailFn=f; $tailCount=-1; $tailUnary=x; return $TAIL_PENDING; }\nfunction tail_named(f,n) { $tailFn=f; $tailCount=n; return $TAIL_PENDING; }\nfunction $run(f, xs) { let x=run_loop(f); for (const a of xs) x=run_loop(x(a)); return x; }\nfunction run_loop(x) { while (x===$TAIL_PENDING) { const f=$tailFn, count=$tailCount; $tailFn=undefined; $tailCount=0; if(count===-1) { const a=$tailUnary; $tailUnary=undefined; x=f(a,$BEND_TAIL); } else x=tail_dispatch(f,count); } return x; }\nfunction tail_dispatch(f,count) { switch(count) {\ncase -2: { const a=$tailRest; $tailRest=undefined; return f(...a); }\ncase 1: { const a0=$tailArgs[0]; $tailArgs[0]=undefined; return f(a0); }\ncase 2: { const a0=$tailArgs[0],a1=$tailArgs[1]; $tailArgs[0]=$tailArgs[1]=undefined; return f(a0,a1); }\ncase 3: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=undefined; return f(a0,a1,a2); }\ncase 4: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=undefined; return f(a0,a1,a2,a3); }\ncase 5: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=undefined; return f(a0,a1,a2,a3,a4); }\ncase 6: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=undefined; return f(a0,a1,a2,a3,a4,a5); }\ncase 7: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=undefined; return f(a0,a1,a2,a3,a4,a5,a6); }\ncase 8: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7); }\ncase 9: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8); }\ncase 10: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9); }\ncase 11: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10); }\ncase 12: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11); }\ncase 13: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12); }\ncase 14: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13); }\ncase 15: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14); }\ncase 16: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15); }\ncase 17: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16); }\ncase 18: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17); }\ncase 19: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18); }\ncase 20: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19); }\ncase 21: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20); }\ncase 22: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21); }\ncase 23: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22); }\ncase 24: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23); }\ncase 25: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24); }\ncase 26: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25); }\ncase 27: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26); }\ncase 28: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27); }\ncase 29: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28); }\ncase 30: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28],a29=$tailArgs[29]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=$tailArgs[29]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29); }\ncase 31: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28],a29=$tailArgs[29],a30=$tailArgs[30]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=$tailArgs[29]=$tailArgs[30]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30); }\ncase 32: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28],a29=$tailArgs[29],a30=$tailArgs[30],a31=$tailArgs[31]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=$tailArgs[29]=$tailArgs[30]=$tailArgs[31]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31); }\ndefault: throw \"bend: invalid private tail frame\";\n} }\nfunction run_force(x,raw) { return raw===$BEND_TAIL?x:run_loop(x); }\nfunction run_many(f,a,d=$td) { return d<64?f(...a,d+1):tail_many(f,a); }\nfunction run_tail(f,x) { const j=f[$BEND_TAIL]; return j ? tail_unary(j,x) : f(x); }\nfunction run_clo(j) { j[$BEND_TAIL]=j; return j; }\nfunction nat_chk(x) { if(x>281474976710655) throw \"bend: a Nat past the largest immediate 2^48-1\"; return x; }\nfunction char_new(x) { if(x>0x10ffff || (x>=0xd800 && x<=0xdfff)) throw \"bend: \"+x+\" is not a Unicode scalar value\"; return String.fromCodePoint(x); }\nfunction cmp_new(a,b) { return {$:a<b?\"LT\":a===b?\"EQ\":\"GT\"}; }\nfunction word_to_u32(w) { let x=0; for(let i=0;w.$===\"WCon\";i++,w=w.tail) if(w.head)x|=1<<i; return x>>>0; }\nfunction u32_to_word(x) { let w={$:\"WNil\"}; for(let i=31;i>=0;i--) w={$:\"WCon\",head:!!((x>>>i)&1),tail:w}; return w; }\nfunction run_named1(f,a0,d) { return d<64?f(a0,d+1):($tailArgs[0]=a0,tail_named(f,1)); }\nfunction run_named2(f,a0,a1,d) { return d<64?f(a0,a1,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,tail_named(f,2)); }\nfunction run_named3(f,a0,a1,a2,d) { return d<64?f(a0,a1,a2,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,tail_named(f,3)); }\nfunction run_named4(f,a0,a1,a2,a3,d) { return d<64?f(a0,a1,a2,a3,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,tail_named(f,4)); }\nfunction run_named5(f,a0,a1,a2,a3,a4,d) { return d<64?f(a0,a1,a2,a3,a4,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,tail_named(f,5)); }\nfunction run_named6(f,a0,a1,a2,a3,a4,a5,d) { return d<64?f(a0,a1,a2,a3,a4,a5,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,tail_named(f,6)); }\nfunction run_named7(f,a0,a1,a2,a3,a4,a5,a6,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,tail_named(f,7)); }\nfunction run_named8(f,a0,a1,a2,a3,a4,a5,a6,a7,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,tail_named(f,8)); }\nfunction run_named9(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,tail_named(f,9)); }\nfunction run_named10(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,tail_named(f,10)); }\nfunction run_named11(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,tail_named(f,11)); }\nfunction run_named12(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,tail_named(f,12)); }\nfunction run_named13(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,tail_named(f,13)); }\nfunction run_named14(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,tail_named(f,14)); }\nfunction run_named15(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,tail_named(f,15)); }\nfunction run_named16(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,tail_named(f,16)); }\nfunction run_named17(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,tail_named(f,17)); }\nfunction run_named18(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,tail_named(f,18)); }\nfunction run_named19(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,tail_named(f,19)); }\nfunction run_named20(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,tail_named(f,20)); }\nfunction run_named21(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,tail_named(f,21)); }\nfunction run_named22(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,tail_named(f,22)); }\nfunction run_named23(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,tail_named(f,23)); }\nfunction run_named24(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,tail_named(f,24)); }\nfunction run_named25(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,tail_named(f,25)); }\nfunction run_named26(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,tail_named(f,26)); }\nfunction run_named27(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,tail_named(f,27)); }\nfunction run_named28(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,tail_named(f,28)); }\nfunction run_named29(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,tail_named(f,29)); }\nfunction run_named30(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,$tailArgs[29]=a29,tail_named(f,30)); }\nfunction run_named31(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,$tailArgs[29]=a29,$tailArgs[30]=a30,tail_named(f,31)); }\nfunction run_named32(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,$tailArgs[29]=a29,$tailArgs[30]=a30,$tailArgs[31]=a31,tail_named(f,32)); }\n"
def js_runtime_extra() -> String:
  "function f32_from_bits(x) { return new Float32Array(new Uint32Array([x]).buffer)[0]; }\nfunction f32_bits(x) { return new Uint32Array(new Float32Array([x]).buffer)[0]; }\nfunction tuple(a,b) { return {$:\"Tuple\",fst:a,snd:b}; }\nfunction f32_show(x) { if(x!==x) return \"nan\"; if(!Number.isFinite(x)||Object.is(x,-0)) return x<0?\"-inf\":x===0?\"-0\":\"inf\"; let s=\"x\"; for(let p=1;p<=9&&Math.fround(Number(s))!==x;p++) s=String(Number(x.toExponential(p-1))); return s; }\nfunction f32_read(s) { const re=/^\\s*[+-]?((\\d+\\.?\\d*|\\.\\d+)(e[+-]?\\d+)?|inf(inity)?|nan)$/i; const v=Number(s.replace(/inf\\w*/i,\"Infinity\")); return re.test(s)?{$:\"Some\",value:Math.fround(v)}:{$:\"None\"}; }\nfunction nat_divmod(a,b) { return b===0?tuple(0,a):tuple(Math.trunc(a/b),a%b); }\nfunction array_new(n,v) { if(n>31) throw \"bend: an array past the deepest block class 31\"; return Array(2 ** n).fill(v); }\nfunction array_node(a,b) { if(a.length!==b.length) throw \"bend: runtime fail-stop\"; return a.concat(b); }\n"
def js_runtime_array() -> String:
  "function array_swap(a,i,v) { const at=i%a.length, old=a[at]; a[at]=v; return tuple(a,old); }\nfunction $string_tail(s) { return s.slice(s.codePointAt(0)>0xFFFF?2:1); }\n"
def js_runtime_foreign() -> String:
  "function $curry(f,n,xs=[]) { return n===0 ? f(...xs) : x => $curry(f,n-1,[...xs,x]); }\nfunction io_emit(value) { return {$:\"Emit\",value}; }\nfunction $effect(f,need,n) { return $curry((...args)=>({$:\"$FFI\",run:f,need,args,kont:io_emit}),n); }\n"
def js_runtime_namespace() -> String:
  "function $key(k,s,a) { let p=null; for (const alias of Object.keys(a)) if(k.startsWith(alias+\".\") && (p===null || alias.length>p.length)) p=alias; const n=p===null?undefined:a[p]; return n===undefined?(s?s+\".\"+k:k):(n?n+\".\":\"\")+k.slice(p.length+1); }\nfunction $resolve(k,s,a) { const q=$key(k,s,a); return $D[Object.hasOwn($D,q)?q:k]; }\nconst $FIELDS=Object.create(null), $PRIMITIVES=Object.create(null), $TYPE=Object.create(null), $TYPEF=Object.create(null), $PARAMS=Object.create(null);\nfunction $ctr(k,x,s,a) { const q=$key(k,s,a), key=Object.hasOwn($FIELDS,q)?q:k, fs=$FIELDS[key]; if(!fs||fs.length!==x.length)throw \"bend: unresolved constructor layout\"; const v={$:key}; for(let i=0;i<fs.length;i++){const f=fs[i];if(f!==null){if(f===\"__proto__\")Object.defineProperty(v,f,{value:x[i],enumerable:true,writable:true,configurable:true});else v[f]=x[i];}} return v; }\nfunction $project(v,k,i,s,a) { const q=$key(k,s,a),fs=$FIELDS[q]||$FIELDS[k]; if(!fs)throw \"bend: unresolved constructor layout\"; for(const f of fs)if(f!==null&&i--===0)return v[f]; throw \"bend: constructor field count mismatch\"; }\n"
def js_runtime_cli() -> String:
  "const cli_args=[];\nfunction cli(argv) { for(let i=0;i<argv.length;i++){ if(argv[i]===\"--\"){cli_args.push(...argv.slice(i+1));break;} if(argv[i]===\"--help\"){process.stdout.write(\"usage: \"+process.argv[1]+\"\\n\");process.exit(0);} if(argv[i]===\"--threads\"||argv[i]===\"--gpu\"){i++;} else cli_args.push(argv[i]); } }\n"
def js_runtime_io() -> String:
  "function io_out(fd,data) { const fs=require(\"fs\"), b=Buffer.from(data); let at=0; while(at<b.length) at+=fs.writeSync(fd,b,at,b.length-at); }\nfunction io_errs(message) { io_out(2,io_bytes(message+\"\\n\")); }\nfunction io_bytes(text) { return new TextEncoder().encode(text); }\nfunction io_text(bytes,n) { return new TextDecoder(\"utf-8\",{ignoreBOM:true}).decode(bytes.subarray(0,n)); }\nfunction io_tuple_pair(snd,fst) { return tuple(fst,snd); }\nfunction io_tup(...xs) { if(xs.length!==2)return xs.reduceRight(io_tuple_pair); return tuple(xs[0],xs[1]); }\nfunction io_done(value) { return {$:\"Done\",value}; }\nfunction io_sys() { if(globalThis.BEND_SYS===undefined){const ffi=require(\"bun:ffi\"), mac=process.platform===\"darwin\", err=mac?\"__error\":\"__errno_location\", T={i:\"i32\",u:\"u32\",U:\"u64\",I:\"i64\",p:\"ptr\",c:\"cstring\"}, vari=mac&&process.arch===\"arm64\", lib=ffi.dlopen(mac?\"libSystem.dylib\":\"libc.so.6\",Object.fromEntries((\"socket:iii>i bind:ipu>i listen:ii>i connect:ipu>i accept:ipp>i send:ipUi>I recv:ipUi>I read:ipU>I pread:ipUI>I sendto:ipUipu>I recvfrom:ipUipp>I close:i>i poll:pui>i setsockopt:iiipu>i\"+(vari?\" fcntl:iiiiiiiii>i\":\" fcntl:iii>i\")+\" getsockopt:iiipp>i strerror:i>c \"+err+\":>p\").split(\" \").map(s=>{const [name,args,ret]=s.split(/[:>]/);return [name,{args:[...args].map(a=>T[a]),returns:T[ret]}]}))), fcntl=(fd,cmd,arg)=>vari?lib.symbols.fcntl(fd,cmd,0,0,0,0,0,0,arg):lib.symbols.fcntl(fd,cmd,arg); globalThis.BEND_SYS={...lib.symbols,fcntl,ptr:ffi.ptr,mac,errno:()=>ffi.read.i32(lib.symbols[err](),0)};} return globalThis.BEND_SYS; }\nfunction io_fail(code) { return {$:\"Fail\",error:io_tup(code>>>0,String(io_sys().strerror(code)))}; }\nfunction io_push(fun,arg,fresh) { const io=globalThis.BEND_IO; io.runs.push({fun,arg}); io.live+=fresh?1:0; }\nfunction io_park_on(fd,out,k,more) { globalThis.BEND_IO.waits.push({fd,out,k,more}); }\nfunction io_wait(io) { const soon=io.waits.reduce((m,w)=>Math.min(m,w.at??m),Infinity); let ms=-1; if(soon!==Infinity)ms=Math.min(Math.max(0,Math.ceil(soon-performance.now())),2147483647); const fds=io.waits.filter(w=>w.fd!==undefined), buf=Int32Array.from(fds.flatMap(w=>[w.fd,w.out?4:1])); io_sys().poll(fds.length?io_sys().ptr(buf):null,fds.length,ms); const now=performance.now(), fire=io.waits.filter((w)=>(buf[2*fds.indexOf(w)+1]>>>16)!==0||w.at<=now); io.waits=io.waits.filter(w=>!fire.includes(w)); for(const w of fire)io_push(io_wake,w,false); }\nfunction io_wake(w) { const x=w.more(); return x===undefined?undefined:w.k(x); }\nfunction io_run(m) { const io={runs:[],live:0,waits:[]}; globalThis.BEND_IO=io; try{io_push(run_loop(m()),io_emit,true); for(;;){if(io.runs.length===0){if(io.live===0)return 0;if(io.waits.length===0){io_errs(\"bend: deadlock: every computation waits on a channel\");return 1;}io_wait(io);continue;}const s=io.runs.shift();let op=s.fun(s.arg);for(;;){if(op===undefined)break;if(op.$===\"Emit\"){io.live-=1;break;}if(op.$===\"Halt\"){io_errs(op.message);return op.code;}const need=op.need?.()||{},fd=need.read?op.args[0]:null;if(need.time||fd!==null){const more=()=>op.run(...op.args,op.kont);io.waits.push(fd===null?{at:performance.now()+Number(op.args[0]),k:op.kont,more}:{fd,k:op.kont,more});break;}const x=op.run(...op.args,op.kont);if(x===undefined)break;op=op.kont(x);}}}catch(req){if(req instanceof RangeError)throw \"bend: memory fault (machine stack overflow?)\";if(req?.$!==\"$FFI\")throw req;io_errs(\"bend: an FFI operation failed\");return 1;} }\nfunction chan_wake(row,x) { const w=row.wait.shift(); io_push(w.cont,x,false); return w.item; }\nfunction chan_take(row) { const v=row.ring.shift(); if(row.wait.length>0)row.ring.push(chan_wake(row,true)); return v; }\nfunction chan_shut(row) { row.shut=true; while(row.wait.length>0)chan_wake(row,row.wait[0].item===null?{$:\"None\"}:false); }\nfunction io_exit(main,type) { if(type&&type.name===\"IO\")return io_run(main); try{io_out(1,io_bytes($show_value(type,run_loop(main()),0)+\"\\n\"));return 0;}catch(e){io_errs(String(e));return 1;} }\n"
def js_runtime_show() -> String:
  String.append(js_runtime_type(), "function $show_chr(x,q) { const c=[...x][0]||\"\\0\", n=c.codePointAt(0), k=({10:\"n\",9:\"t\",13:\"r\",0:\"0\",92:\"\\\\\"})[n]??(c===q?q:null); return k!==null?\"\\\\\"+k:n<32||n===127?\"\\\\u{\"+n.toString(16)+\"}\":c; }\nfunction $show_list(t,x) { const xs=[]; while(x&&x.$===\"Con\") { const fs=t.arms.Con; if(!fs||!Object.hasOwn(x,\"head\")||!Object.hasOwn(x,\"tail\")) throw \"bend: malformed List.Con\"; xs.push($show_value($type(fs.types[0],t.args),x.head,0)); const next=$type(fs.types[1],t.args.concat([x.head])); x=x.tail; t=next; } if(!x||x.$!==\"Nil\") throw \"bend: malformed List.Nil\"; return \"[\"+xs.join(\", \")+\"]\"; }\nfunction $show_fields(t,x,chain) { const fs=t.arms[x.$]; if(!fs) throw \"bend: constructor absent from result datatype\"; const out=[],env=t.args.slice(); let at=0; for(let j=0;j<fs.types.length;j++) { if(fs.q[j]===0) { env.push(null); continue; } const name=fs.fields[j]; if(!Object.hasOwn(x,name))throw \"bend: constructor field count mismatch\"; const v=x[name]; at++; out.push($show_value($type(fs.types[j],env),v,chain&&at===2?\"(\":0)); env.push(v); } return out.join(\", \"); }\nfunction $show_value(t,x,chain) { if(!t) return String(x); if(t.k===\"U\") return String(x); if(t.k===\"F\") { const s=f32_show(x); return s.replace(/^-?\\d+(?=e|$)/i,\"$&.0\"); } if(t.k===\"N\") return x+\"n\"; if(t.k===\"C\") return \"'\"+$show_chr(x,\"'\")+\"'\"; if(t.k===\"S\") return \"\\\"\"+[...x].map(c=>$show_chr(c,\"\\\"\")).join(\"\")+\"\\\"\"; if(t.k===\"E\") return \"{==}\"; if(t.k===\"A\") return \"[\"+x.map(v=>$show_value(t.e,v,0)).join(\", \")+\"]\"; if(typeof x===\"boolean\") return x?\"True{}\":\"False{}\"; if(!x||typeof x!==\"object\"||!x.$) return String(x); if(t.native===\"List\") return $show_list(t,x); if(t.native===\"Sigma\"&&x.$===\"Tuple\") { const c=chain===\"(\"; return (c?\"\":\"(\")+$show_fields(t,x,true)+(c?\"\":\")\"); } if(t.k!==\"D\") throw \"bend: expected a datatype result\"; return x.$+\"{\"+$show_fields(t,x,false)+\"}\"; }\n")
# Metadata evaluation retains every source formal slot, including erased type
# arguments, but delays terms until reduction needs them. It never calls an
# ordinary erased-value function or executes an unused proof/index expression.
def js_runtime_type() -> String:
  String.append(js_runtime_native_type(), String.append(js_runtime_type_names(), String.append(js_runtime_type_patterns(), js_runtime_type_eval())))
def js_runtime_type_names() -> String:
  "function $type_key(k,s,i) { const q=$key(k,s,i||{}); return $TYPE[q]!==undefined||$TYPEF[q]!==undefined?q:k; }\nfunction $type_ctor_key(k,s,i) { const q=$key(k,s,i||{}); return $FIELDS[q]!==undefined?q:k; }\nfunction $type_delay(t,a) { if(t.k)return t; if(t.p!==undefined&&a[a.length-1-t.p]!==undefined)return a[a.length-1-t.p]; return {k:\"Thunk\",term:t,env:a,depth:a.length,done:false}; }\nfunction $type_force(v) { if(v&&v.k===\"Thunk\") { if(!v.done) { v.value=$type(v.term,v.env.length===v.depth?v.env:v.env.slice(0,v.depth)); v.done=true; } return v.value; } return v; }\nfunction $type_apply(f,x) { f=$type_force(f); if(f.k===\"L\") return $type(f.body,f.env.concat([x])); if(f.k===\"TF\"||f.k===\"DF\") return $type_named(f.key,f.args.concat([x])); throw \"bend: type expression applied a non-function\"; }\nfunction $type_named(q,ps) { const f=$TYPEF[q]; if(f) { if(ps.length<f.n)return {k:\"TF\",key:q,args:ps}; let v=f.intrinsic?$type_native_invoke(f,ps):$type(f.body,ps.length===f.n?ps:ps.slice(0,f.n)); for(let i=f.n;i<ps.length;i++)v=$type_apply(v,ps[i]); if(f.native===\"IO\")v.name=\"IO\"; return v; } const d=$TYPE[q]; if(!d) throw \"bend: unresolved type expression \"+q; const p=$PARAMS[q]; if(ps.length<p.n)return {k:\"DF\",key:q,args:ps}; if(ps.length!==p.n)throw \"bend: datatype parameter count mismatch\"; if(d.native===\"Array\") return {k:\"A\",e:$type_force(ps[0])}; const k=({U32:\"U\",F32:\"F\",Nat:\"N\",Char:\"C\",String:\"S\",Eql:\"E\"})[d.native]; return k?{k}:{k:\"D\",key:q,name:d.name,native:d.native,arms:d.arms,args:ps}; }\n"
def js_runtime_type_patterns() -> String:
  "function $type_sugar(t,a) { const h=$type(t.sugar,a),more=t.a.map(x=>$type_delay(x,a)); if(h.k===\"TF\"||h.k===\"DF\"||h.k===\"D\") { const q=h.key,p=$PARAMS[q]; let xs=h.args.concat(more); if(p&&xs.length+p.q===p.n)xs=Array.from({length:p.q},()=>({k:\"Q\",v:t.f})).concat(xs); if(p&&t.f===2)xs=xs.map((x,i)=>i<p.q?({k:\"Q\",v:2}):x); return $type_named(q,xs); } let v=h; for(const x of more)v=$type_apply(v,x); return v; }\nfunction $type_pattern(p,v,bindings) { if(p.v) { bindings.push(v); return true; } v=$type_force(v); const q=$type_ctor_key(p.c,p.s,p.i),c=$PRIMITIVES[q]||($FIELDS[q]===undefined?q:\"\"); let fields,complete=false; if(v&&v.k===\"V\") { if(v.c!==q)return false; fields=v.args; complete=true; } else if(v&&v.$===q) { const names=$FIELDS[q]; if(!names||names.length!==p.fields.length)return false; for(let j=0;j<names.length;j++){if(names[j]===null){bindings.push(null);continue;}if(!$type_pattern(p.fields[j],v[names[j]],bindings))return false;}return true; } else if(c===\"Bool.True\"&&v===true||c===\"Bool.False\"&&v===false||c===\"Nat.Zero\"&&v===0||c===\"String.SNil\"&&v===\"\") fields=[]; else if(c===\"Nat.Succ\"&&typeof v===\"number\"&&v>0)fields=[v-1]; else if(c===\"String.SCon\"&&typeof v===\"string\"&&v.length)fields=[String.fromCodePoint(v.codePointAt(0)),v.slice(v.codePointAt(0)>0xFFFF?2:1)]; else if(c===\"Char.Chr\"&&typeof v===\"string\")fields=[v.codePointAt(0)]; else if(c===\"U32.U32\"&&typeof v===\"number\")fields=[u32_to_word(v)]; else if(c===\"F32.F32\"&&typeof v===\"number\")fields=[u32_to_word(f32_bits(v))]; else if(c===\"Array.ALeaf\"&&Array.isArray(v)&&v.length===1)fields=[v[0]]; else if(c===\"Array.ANode\"&&Array.isArray(v)&&v.length!==1)fields=[v.slice(0,v.length>>1),v.slice(v.length>>1)]; else return false; let at=0; for(const field of p.fields) { if(!complete&&field.v&&field.q===0) { bindings.push(null); continue; } if(at>=fields.length||!$type_pattern(field,fields[at++],bindings))return false; } return at===fields.length; }\nfunction $type_bind(patterns,values) { if(patterns.length!==values.length)return null; const bindings=[]; for(let j=0;j<values.length;j++)if(!$type_pattern(patterns[j],values[j],bindings))return null; return bindings; }\n"
def js_runtime_type_eval() -> String:
  "function $type(t,a=[]) { if(t===null)return null; if(t===undefined)throw \"bend: missing type expression\"; if(t.p!==undefined) { const v=$type_force(a[a.length-1-t.p]); if(v===undefined||v===null)throw \"bend: unavailable type-expression binder\"; return v; } if(t.k)return $type_force(t); if(t.fail)throw t.fail; if(t.kind!==undefined)return {k:\"K\",q:$type(t.kind,a)}; if(t.min!==undefined)return {k:\"Q\",v:Math.min($type(t.min,a).v,$type(t.right,a).v)}; if(t.all!==undefined)return {k:\"Fn\",q:t.q,domain:$type(t.all,a),body:t.body,env:a}; if(t.lam!==undefined)return {k:\"L\",body:t.lam,env:a}; if(t.app!==undefined)return $type_apply($type(t.app,a),$type_delay(t.arg,a)); if(t.sub!==undefined) { const env=a.slice(); env.splice(env.length-t.sub,0,$type_delay(t.value,a)); return $type(t.body,env); } if(t.let!==undefined)return $type(t.body,a.concat(t.let.map(x=>$type_delay(x,a)))); if(t.local!==undefined) { const bs=$type_bind(t.pat,t.local.map(x=>$type_delay(x,a))); if(bs===null)throw \"bend: type expression local pattern failed\"; return $type(t.body,a.concat(bs)); } if(t.bind!==undefined)return $type(t.body,a.concat([$type_delay(t.bind,a)])); if(t.match!==undefined) { const vs=t.match.map(x=>$type_delay(x,a)); for(const c of t.cases) { const bs=$type_bind(c.pat,vs); if(bs!==null)return $type(c.body,a.concat(bs)); } throw \"bend: type expression match failed\"; } if(t.c!==undefined)return {k:\"V\",c:$type_ctor_key(t.c,t.s,t.i),args:t.a.map(x=>$type_delay(x,a))}; if(t.sugar!==undefined)return $type_sugar(t,a); if(t.f) { const q=$type_key(t.r,t.s,t.i),p=$PARAMS[q]; if(!p&&t.f===2)return $type(t.h,a); let xs=t.a||[]; if(p&&xs.length+p.q===p.n)xs=Array.from({length:p.q},()=>({k:\"Q\",v:1})).concat(xs); if(p&&t.f===2)xs=xs.map((x,i)=>i<p.q?({k:\"Q\",v:2}):x); return $type_named(q,xs.map(x=>$type_delay(x,a))); } if(t.r!==undefined)return $type_named($type_key(t.r,t.s,t.i),(t.a||[]).map(x=>$type_delay(x,a))); throw \"bend: unsupported type-expression descriptor\"; }\n"
def js_runtime_native_type() -> String:
  "function $type_native_invoke(f,ps) { let value=f.intrinsic; for(let i=0;i<f.n;i++)if(f.q[i]!==0)value=value($type_runtime_value(ps[i])); return value; }\nfunction $type_runtime_value(value) { const v=$type_force(value); if(!v||v.k!==\"V\")return v; const c=$PRIMITIVES[v.c]||($FIELDS[v.c]===undefined?v.c:\"\"),xs=v.args; switch(c) { case \"Nat.Zero\":return 0; case \"Nat.Succ\":return nat_chk($type_runtime_value(xs[0])+1); case \"Bool.False\":return false; case \"Bool.True\":return true; case \"String.SNil\":return \"\"; case \"String.SCon\":return $type_runtime_value(xs[0])+$type_runtime_value(xs[1]); case \"Char.Chr\":return char_new($type_runtime_value(xs[0])); case \"U32.U32\":return word_to_u32($type_runtime_value(xs[0])); case \"F32.F32\":return f32_from_bits(word_to_u32($type_runtime_value(xs[0]))); case \"Array.ALeaf\":return [$type_runtime_value(xs[0])]; case \"Array.ANode\":return $type_runtime_value(xs[0]).concat($type_runtime_value(xs[1])); } const fs=$FIELDS[v.c]; if(!fs||fs.length!==xs.length)throw \"bend: unresolved metadata constructor\"; const args=xs.map((x,i)=>fs[i]===null?null:$type_runtime_value(x)); return $ctr(v.c,args,\"\",{}); }\n"
def js_main(type_expression: String) -> String:
  String.append("if (typeof process !== \"undefined\" && process.argv[1] && /\\.js$/.test(process.argv[1])) { cli(process.argv.slice(2)); if(Object.hasOwn($D,\"main\")) { process.exitCode=io_exit(()=>$D[\"main\"],$type(", String.append(type_expression, ")); } }\n"))
