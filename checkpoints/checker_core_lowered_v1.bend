import Base
import ../bend2/selfhost/ast.bend as Ast
import ../bend2/selfhost/path.bend as Path
import ../bend2/selfhost/loaded_module.bend as Loader

type Diagnostic is Data:
  Diagnostic{file: String, span: Ast.SourceSpan, message: String, expected: String, observed: String}
type CheckResult is Data:
  CheckSuccess{modules: List<&2, Loader.LoadedModule>}
  CheckFailure{diagnostic: Diagnostic}
type Binding is Data:
  Binding{key: String, quantity: Ast.Quantity, ty: Ast.SyntaxTerm}
type Global is Data:
  Global{key: String, namespace: String, local_key: String, ty: Ast.SyntaxTerm, value: Ast.OptionalTerm, family: Bool}
type UsageEntry is Data:
  Usage{index: Nat, quantity: Ast.Quantity}
type TermOrder is Data:
  OrderLess{}
  OrderEqual{}
  OrderGreater{}
type Inference is Data:
  Inferred{term: Ast.SyntaxTerm, ty: Ast.SyntaxTerm}
  InferenceFailure{diagnostic: Diagnostic}
type ScrutineeTyping is Data:
  ScrutineeTypes{types: List<&2, Ast.SyntaxTerm>}
  ScrutineeTypeFailure{diagnostic: Diagnostic}
type PatternTyping is Data:
  PatternTyped{env: List<&2, Binding>, value: Ast.SyntaxTerm}
  PatternTypeFailure{diagnostic: Diagnostic}
type PatternFields is Data:
  PatternFieldsTyped{env: List<&2, Binding>, values: List<&2, Ast.SyntaxTerm>, result: Ast.SyntaxTerm}
  PatternFieldsFailure{diagnostic: Diagnostic}
type FamilyLowering is Data:
  FamilyTerm{term: Ast.SyntaxTerm}
  FamilyFailure{diagnostic: Diagnostic}
type State is Data:
  State{globals: List<&2, Global>}
  StateFailure{diagnostic: Diagnostic}

def span_file(span: Ast.SourceSpan) -> String:
  match span:
    case Ast.SpanOf{file,  _,  _}: file


def term_span(term: Ast.SyntaxTerm) -> Ast.SourceSpan:
  match term:
    case Ast.TermVar{_, _, span}: span
    case Ast.TermRef{_, span}: span
    case Ast.TermBang{_, span}: span
    case Ast.TermSub{_, _, _, span}: span
    case Ast.TermLet{_, _, _, _, _, span}: span
    case Ast.TermAnn{_, _, span}: span
    case Ast.TermTemplate{_, span}: span
    case Ast.TermType{_, span}: span
    case Ast.TermQuant{}: Ast.SpanOf{ "",  0n,  0n}
    case Ast.TermQuantity{_, span}: span
    case Ast.TermMin{_, _, span}: span
    case Ast.TermAll{_, _, _, _, _, span}: span
    case Ast.TermLam{_, _, _, _, span}: span
    case Ast.TermApp{_, _, span}: span
    case Ast.TermAdt{_, _, _, span}: span
    case Ast.TermFill{_, _, span}: span
    case Ast.TermPlus{_, _, span}: span
    case Ast.TermCtr{_, _, span}: span
    case Ast.TermMat{_, _, _, span}: span
    case Ast.TermAbsurd{span}: span
    case Ast.TermEqual{_, _, _, span}: span
    case Ast.TermRefl{span}: span
    case Ast.TermRewrite{_, _, _, span}: span
    case Ast.TermHole{_, span}: span
    case Ast.BodyMatch{_, _, span}: span
    case Ast.BodyCase{_, _, span}: span
    case Ast.BodyLocal{_, _, _, _, span}: span
    case Ast.BodyReply{_, span}: span
def fail(+span: Ast.SourceSpan, message: String, expected: String, observed: String) -> Inference:
  InferenceFailure{ Diagnostic{ span_file(span), span, message, expected, observed}}

def same_quantity(a: Ast.Quantity, b: Ast.Quantity) -> Bool:
  match a b:
    case Ast.QZero{} Ast.QZero{}: True{}
    case Ast.QOne{} Ast.QOne{}: True{}
    case Ast.QMany{} Ast.QMany{}: True{}
    case _ _: False{}

def quantity_join(a: Ast.Quantity, b: Ast.Quantity) -> Ast.Quantity:
  match a b:
    case Ast.QMany{} _: Ast.QMany{}
    case _ Ast.QMany{}: Ast.QMany{}
    case Ast.QOne{} Ast.QOne{}: Ast.QMany{}
    case Ast.QZero{} _: b
    case _ _: a
def quantity_alternative(a: Ast.Quantity, b: Ast.Quantity) -> Ast.Quantity:
  match a b:
    case Ast.QMany{} _: Ast.QMany{}
    case _ Ast.QMany{}: Ast.QMany{}
    case Ast.QZero{} _: b
    case _ Ast.QZero{}: a
    case _ _: Ast.QOne{}


def quantity_fits(actual: Ast.Quantity, demand: Ast.Quantity) -> Bool:
  match actual demand:
    case Ast.QZero{} _: True{}
    case Ast.QOne{} Ast.QZero{}: False{}
    case Ast.QMany{} Ast.QZero{}: False{}
    case Ast.QOne{} Ast.QOne{}: True{}
    case Ast.QMany{} Ast.QOne{}: False{}
    case _ _: True{}

def constructor_field_demand(+scrutinee: Ast.Quantity, field: Ast.Quantity) -> Ast.Quantity:
  match field:
    case Ast.QZero{}: Ast.QZero{}
    case Ast.QOne{}: scrutinee
    case Ast.QMany{}: quantity_join(scrutinee, scrutinee)

def pattern_quantity_allowed(available: Ast.Quantity, requested: Ast.Quantity) -> Bool:
  match available requested:
    case Ast.QZero{} Ast.QZero{}: True{}
    case Ast.QOne{} Ast.QZero{}: True{}
    case Ast.QOne{} Ast.QOne{}: True{}
    case Ast.QMany{} _: True{}
    case _ _: False{}

def checker_scc_fused_lookup_binding(env: List<&2, Binding>, index: Nat) -> Maybe<&2, Binding>:
  match env index:
    case +binding <> rest 0n: Some{binding}
    case +binding <> rest 1n+more: checker_scc_fused_lookup_binding(rest, more)
    case Nil{} _: None{}

def lookup_binding(index: Nat, env: List<&2, Binding>) -> Maybe<&2, Binding>:
  checker_scc_fused_lookup_binding(env, index)

def lookup_binding_head(index: Nat, binding: Binding, rest: List<&2, Binding>) -> Maybe<&2, Binding>:
  match index:
    case 0n: Some{binding}
    case 1n+more: lookup_binding(more, rest)

def lookup_global(+key: String, globals: List<&2, Global>) -> Maybe<&2, Global>:
  match globals:
    case +global <> rest:
      match global:
        case Global{ found,  _,  _,  _,  _,  _}:
          Bool.pick(Maybe<&2, Global>, String.eq(key, found), Some{global}, lookup_global(key, rest))
    case Nil{}: None{}

def lookup_global_match(found: String, global: Global, rest: List<&2, Global>, +key: String) -> Maybe<&2, Global>:
  Bool.pick(Maybe<&2, Global>, String.eq(key, found), Some{global}, lookup_global(key, rest))

def canonical_key(+namespace: String, +key: String) -> String:
  Bool.pick(String, String.eq(namespace, ""), key, String.append(namespace, String.append(".", key)))

def current_scope(globals: List<&2, Global>, +namespace: String) -> List<&2, Global>:
  match globals:
    case Nil{}: Nil{}
    case +global <> rest:
      match global:
        case Global{ _,  +owner, +local_key, ty, value, family}:
          +tail = current_scope(rest, namespace)
          Bool.pick(List<&2, Global>, String.eq(namespace, owner), Global{ local_key,  owner, local_key, ty, value, family} <> tail, tail)

def import_scope_base(+alias: String, +local_key: String, +owner: String, +ty: Ast.SyntaxTerm, +value: Ast.OptionalTerm, +family: Bool, +tail: List<&2, Global>) -> List<&2, Global>:
  +prefixed = {Global{ String.append(alias, String.append(".", local_key)),  owner, local_key, ty, value, family} : Global}
  Bool.pick(List<&2, Global>, String.eq(alias, "Base"), Global{ local_key,  owner, local_key, ty, value, family} <> (prefixed <> tail), prefixed <> tail)

def import_scope_target(+owner: String, alias: String, target: String, local_key: String, ty: Ast.SyntaxTerm, value: Ast.OptionalTerm, family: Bool, +tail: List<&2, Global>) -> List<&2, Global>:
  Bool.pick(List<&2, Global>, String.eq(owner, target), import_scope_base(alias, local_key, owner, ty, value, family, tail), tail)

def import_scope(globals: List<&2, Global>, +alias: String, +target: String) -> List<&2, Global>:
  match globals:
    case Nil{}: Nil{}
    case +global <> rest:
      match global:
        case Global{ _,  owner, local_key, ty, value, family}:
          tail = import_scope(rest, alias, target)
          import_scope_target(owner, alias, target, local_key, ty, value, family, tail)

def imported_scope(imports: List<&2, Ast.ModuleImport>, +globals: List<&2, Global>, +parent_namespace: String) -> List<&2, Global>:
  match imports:
    case Nil{}: Nil{}
    case +item <> rest:
      match item:
        case Ast.ModuleImport{path, alias,  _}:
          target = Path.namespace(parent_namespace, path)
          List.append(&2, Global, import_scope(globals, alias, target), imported_scope(rest, globals, parent_namespace))

def base_scope(globals: List<&2, Global>) -> List<&2, Global>:
  import_scope(globals, "Base", "")

def visible_globals(+globals: List<&2, Global>, +namespace: String, imports: List<&2, Ast.ModuleImport>) -> List<&2, Global>:
  List.append(&2, Global, current_scope(globals, namespace), List.append(&2, Global, imported_scope(imports, globals, namespace), base_scope(globals)))
def resolve_family_key_found(global: Global) -> String:
  match global:
    case Global{ _, namespace, local_key,  _,  _,  _}: canonical_key(namespace, local_key)

def resolve_family_key_result(key: String, found: Maybe<&2, Global>) -> String:
  match found:
    case Some{global}: resolve_family_key_found(global)
    case None{}: key

def resolve_family_key(+key: String, globals: List<&2, Global>) -> String:
  resolve_family_key_result(key, lookup_global(key, globals))

def family_equal(a: String, b: String, +globals: List<&2, Global>) -> Bool:
  String.eq(resolve_family_key(a, globals), resolve_family_key(b, globals))

def family_failure(+span: Ast.SourceSpan, message: String, expected: String, observed: String) -> FamilyLowering:
  FamilyFailure{ Diagnostic{ span_file(span), span, message, expected, observed}}

def lower_family_sugar_variable(valid: Bool, head: Ast.SyntaxTerm, span: Ast.SourceSpan) -> FamilyLowering:
  Bool.pick(FamilyLowering, valid, FamilyTerm{ head}, family_failure(span, "datatype sugar requires a declared datatype", "a datatype family head", "a variable or invalid head"))
def family_head_args(head: Ast.SyntaxTerm) -> List<&2, Ast.SyntaxTerm>:
  match head:
    case Ast.TermAdt{ _, args,  _,  _}: args
    case Ast.TermAnn{term,  _,  _}: family_head_args(term)
    case _: Nil{}

def quantity_arguments(count: Nat, +quantity: Ast.Quantity, +span: Ast.SourceSpan) -> List<&2, Ast.SyntaxTerm>:
  match count:
    case 0n: Nil{}
    case 1n+more: Ast.TermQuantity{quantity, span} <> quantity_arguments(more, quantity, span)

def lower_family_sugar_filled(valid: Bool, +supplied: List<&2, Ast.SyntaxTerm>, quantified: Nat, span: Ast.SourceSpan) -> List<&2, Ast.SyntaxTerm>:
  Bool.pick(List<&2, Ast.SyntaxTerm>, valid, List.append(&2, Ast.SyntaxTerm, quantity_arguments(quantified, Ast.QOne{}, span), supplied), supplied)

def canonical_name_global(global: Global) -> String:
  match global:
    case Global{ _, namespace, local_key,  _,  _,  _}: canonical_key(namespace, local_key)

def canonical_name_result(key: String, found: Maybe<&2, Global>) -> String:
  match found:
    case Some{global}: canonical_name_global(global)
    case None{}: key

def canonical_name(+key: String, globals: List<&2, Global>) -> String:
  canonical_name_result(key, lookup_global(key, globals))

def set_quantity_prefix(args: List<&2, Ast.SyntaxTerm>, count: Nat, +quantity: Ast.Quantity, +span: Ast.SourceSpan) -> List<&2, Ast.SyntaxTerm>:
  match args count:
    case _ 0n: args
    case +_ <> rest 1n+more: Ast.TermQuantity{quantity, span} <> set_quantity_prefix(rest, more, quantity, span)
    case Nil{} _: Nil{}

def family_head_refs(head: Ast.SyntaxTerm) -> List<&2, String>:
  match head:
    case Ast.TermAdt{ _,  _, refs,  _}: refs
    case Ast.TermAnn{term,  _,  _}: family_head_refs(term)
    case _: Nil{}

def lower_family_sugar_complete(valid: Bool, key: String, head: Ast.SyntaxTerm, filled: List<&2, Ast.SyntaxTerm>, quantified: Nat, +span: Ast.SourceSpan, globals: List<&2, Global>) -> FamilyLowering:
  Bool.pick(FamilyLowering, valid, FamilyTerm{ Ast.TermAdt{ canonical_name(key, globals),  set_quantity_prefix(filled, quantified, Ast.QMany{}, span),  family_head_refs(head), span}}, family_failure(span, "plus datatype application is missing parameters", "a complete family instance", "an incomplete family application"))

def lower_family_sugar_plus_quantity(+quantified: Nat, complete: Bool, key: String, head: Ast.SyntaxTerm, filled: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, globals: List<&2, Global>) -> FamilyLowering:
  match quantified:
    case 0n: family_failure(span, "plus requires a datatype with quantity parameters", "a family with quantified parameters", "a family without quantity parameters")
    case _:
      lower_family_sugar_complete(complete, key, head, filled, quantified, span, globals)

def lower_family_sugar_promote(plus: Bool, complete: Bool, key: String, head: Ast.SyntaxTerm, filled: List<&2, Ast.SyntaxTerm>, quantified: Nat, span: Ast.SourceSpan, globals: List<&2, Global>) -> FamilyLowering:
  match plus:
    case True{}: lower_family_sugar_plus_quantity(quantified, complete, key, head, filled, span, globals)
    case False{}: FamilyTerm{ Ast.TermAdt{ canonical_name(key, globals),  filled,  family_head_refs(head), span}}

def family_head_key(head: Ast.SyntaxTerm) -> Maybe<&2, String>:
  match head:
    case Ast.TermRef{key,  _}: Some{key}
    case Ast.TermAdt{key,  _,  _,  _}: Some{key}
    case Ast.TermAnn{term,  _,  _}: family_head_key(term)
    case _: None{}

def application_type_view(term: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  match term:
    case Ast.TermBang{ Ast.TermRef{key,  ref_span},  _}: Ast.TermRef{key,  ref_span}
    case Ast.TermApp{fn, arg, span}: Ast.TermApp{ application_type_view(fn), arg, span}
    case Ast.TermAnn{ inner, ty, span}: Ast.TermAnn{ application_type_view(inner), ty, span}
    case Ast.TermSub{index, value, body,  _}: application_type_view(Core.subst(index, value, body))
    case _: term

type CheckerSccInput39 is Data:
  CheckerSccCall_family_lowered_whnf{fuel: Nat, original: Ast.SyntaxTerm, globals: List<&2, Global>, lowering: FamilyLowering}
  CheckerSccCall_whnf_ref_type{ty_view: Ast.SyntaxTerm, more: Nat, term: Ast.SyntaxTerm, value: Ast.SyntaxTerm, globals: List<&2, Global>}
  CheckerSccCall_whnf_ref_global{global: Global, more: Nat, term: Ast.SyntaxTerm, globals: List<&2, Global>}
  CheckerSccCall_whnf_ref_result{found: Maybe<&2, Global>, more: Nat, term: Ast.SyntaxTerm, globals: List<&2, Global>}
  CheckerSccCall_whnf_application{fn_type: Ast.SyntaxTerm, more: Nat, term: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, globals: List<&2, Global>}
  CheckerSccCall_whnf{fuel: Nat, term: Ast.SyntaxTerm, globals: List<&2, Global>}
  CheckerSccCall_family_arity_view{view: Ast.SyntaxTerm, globals: List<&2, Global>}
  CheckerSccCall_family_arity{ty: Ast.SyntaxTerm, globals: List<&2, Global>}
  CheckerSccCall_family_quant_prefix_domain{domain_view: Ast.SyntaxTerm, body: Ast.SyntaxTerm, globals: List<&2, Global>}
  CheckerSccCall_family_quant_prefix_view{view: Ast.SyntaxTerm, globals: List<&2, Global>}
  CheckerSccCall_family_quant_prefix{ty: Ast.SyntaxTerm, globals: List<&2, Global>}
  CheckerSccCall_lower_family_sugar_family{+ty: Ast.SyntaxTerm, key: String, +head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, plus: Bool, +span: Ast.SourceSpan, +globals: List<&2, Global>}
  CheckerSccCall_lower_family_sugar_global{global: Global, +key: String, head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, plus: Bool, span: Ast.SourceSpan, globals: List<&2, Global>}
  CheckerSccCall_lower_family_sugar_global_result{found: Maybe<&2, Global>, +key: String, head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, plus: Bool, span: Ast.SourceSpan, globals: List<&2, Global>}
  CheckerSccCall_lower_family_sugar_key_result{found: Maybe<&2, String>, head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, plus: Bool, span: Ast.SourceSpan, +globals: List<&2, Global>}
  CheckerSccCall_lower_family_sugar{head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, plus: Bool, span: Ast.SourceSpan, globals: List<&2, Global>}

def checker_scc_result_39(request: CheckerSccInput39) -> Type:
  match request:
    case CheckerSccCall_family_lowered_whnf{fuel, original, globals, lowering}: Ast.SyntaxTerm
    case CheckerSccCall_whnf_ref_type{ty_view, more, term, value, globals}: Ast.SyntaxTerm
    case CheckerSccCall_whnf_ref_global{global, more, term, globals}: Ast.SyntaxTerm
    case CheckerSccCall_whnf_ref_result{found, more, term, globals}: Ast.SyntaxTerm
    case CheckerSccCall_whnf_application{fn_type, more, term, arg, globals}: Ast.SyntaxTerm
    case CheckerSccCall_whnf{fuel, term, globals}: Ast.SyntaxTerm
    case CheckerSccCall_family_arity_view{view, globals}: Nat
    case CheckerSccCall_family_arity{ty, globals}: Nat
    case CheckerSccCall_family_quant_prefix_domain{domain_view, body, globals}: Nat
    case CheckerSccCall_family_quant_prefix_view{view, globals}: Nat
    case CheckerSccCall_family_quant_prefix{ty, globals}: Nat
    case CheckerSccCall_lower_family_sugar_family{+ty, key, +head, args, plus, +span, +globals}: FamilyLowering
    case CheckerSccCall_lower_family_sugar_global{global, +key, head, args, plus, span, globals}: FamilyLowering
    case CheckerSccCall_lower_family_sugar_global_result{found, +key, head, args, plus, span, globals}: FamilyLowering
    case CheckerSccCall_lower_family_sugar_key_result{found, head, args, plus, span, +globals}: FamilyLowering
    case CheckerSccCall_lower_family_sugar{head, args, plus, span, globals}: FamilyLowering

def checker_scc_run_39(request: CheckerSccInput39) -> checker_scc_result_39(request):
  match request:
    case CheckerSccCall_family_lowered_whnf{fuel, original, globals, lowering}:
      match lowering:
        case FamilyTerm{term}: checker_scc_run_39(CheckerSccCall_whnf{fuel, term, globals})
        case FamilyFailure{ _}: original

    case CheckerSccCall_whnf_ref_type{ty_view, more, term, value, globals}:
      match ty_view:
        case Ast.TermAll{ _,  _,  _,  _,  _,  _}: term
        case _: checker_scc_run_39(CheckerSccCall_whnf{more, value, globals})

    case CheckerSccCall_whnf_ref_global{global, more, term, globals}:
      match global:
        case Global{ _,  _,  _, ty,  Ast.SomeTerm{ value},  _}: checker_scc_run_39(CheckerSccCall_whnf_ref_type{checker_scc_run_39(CheckerSccCall_whnf{more, ty, globals}), more, term, value, globals})
        case _: term

    case CheckerSccCall_whnf_ref_result{found, more, term, globals}:
      match found:
        case Some{global}: checker_scc_run_39(CheckerSccCall_whnf_ref_global{global, more, term, globals})
        case None{}: term

    case CheckerSccCall_whnf_application{fn_type, more, term, arg, globals}:
      match fn_type:
        case Ast.TermLam{ _,  _,  _, body,  _}: checker_scc_run_39(CheckerSccCall_whnf{more, Core.subst(0n, arg, body), globals})
        case _: term

    case CheckerSccCall_whnf{fuel, term, globals}:
      match fuel:
        case 0n: term
        case 1n+more:
          match term:
            case Ast.TermSub{index, value, body,  _}: checker_scc_run_39(CheckerSccCall_whnf{more, Core.subst(index, value, body), globals})
            case Ast.TermAnn{ inner,  _,  _}: checker_scc_run_39(CheckerSccCall_whnf{more, inner, globals})
            case Ast.TermFill{head, args, span}: checker_scc_run_39(CheckerSccCall_family_lowered_whnf{more, term, globals, checker_scc_run_39(CheckerSccCall_lower_family_sugar{head, args, False{}, span, globals})})
            case Ast.TermPlus{head, args, span}: checker_scc_run_39(CheckerSccCall_family_lowered_whnf{more, term, globals, checker_scc_run_39(CheckerSccCall_lower_family_sugar{head, args, True{}, span, globals})})
            case Ast.TermRef{key,  _}: checker_scc_run_39(CheckerSccCall_whnf_ref_result{lookup_global(key, globals), more, term, globals})
            case Ast.TermApp{fn, arg, span}: checker_scc_run_39(CheckerSccCall_whnf_application{checker_scc_run_39(CheckerSccCall_whnf{more, application_type_view(fn), globals}), more, term, arg, globals})
            case _: term

    case CheckerSccCall_family_arity_view{view, globals}:
      match view:
        case Ast.TermAll{ _,  _,  _,  _, body,  _}: 1n + checker_scc_run_39(CheckerSccCall_family_arity{body, globals})
        case _: 0n

    case CheckerSccCall_family_arity{ty, globals}:
      checker_scc_run_39(CheckerSccCall_family_arity_view{checker_scc_run_39(CheckerSccCall_whnf{64n, ty, globals}), globals})

    case CheckerSccCall_family_quant_prefix_domain{domain_view, body, globals}:
      match domain_view:
        case Ast.TermQuant{}: 1n + checker_scc_run_39(CheckerSccCall_family_quant_prefix{body, globals})
        case _: 0n

    case CheckerSccCall_family_quant_prefix_view{view, globals}:
      match view:
        case Ast.TermAll{ _,  _,  _,  domain, body,  _}: checker_scc_run_39(CheckerSccCall_family_quant_prefix_domain{checker_scc_run_39(CheckerSccCall_whnf{64n, domain, globals}), body, globals})
        case _: 0n

    case CheckerSccCall_family_quant_prefix{ty, globals}:
      checker_scc_run_39(CheckerSccCall_family_quant_prefix_view{checker_scc_run_39(CheckerSccCall_whnf{64n, ty, globals}), globals})
    case CheckerSccCall_lower_family_sugar_family{+ty, key, +head, args, plus, +span, +globals}:
      +arity = checker_scc_run_39(CheckerSccCall_family_arity{ty, globals})
      +quantified = checker_scc_run_39(CheckerSccCall_family_quant_prefix{ty, globals})
      +supplied = List.append(&2, Ast.SyntaxTerm, family_head_args(head), args)
      +filled = lower_family_sugar_filled(Nat.is_eq(List.length(&2, Ast.SyntaxTerm, supplied) + quantified, arity), supplied, quantified, span)
      lower_family_sugar_promote(plus, Nat.is_eq(List.length(&2, Ast.SyntaxTerm, filled), arity), key, head, filled, quantified, span, globals)

    case CheckerSccCall_lower_family_sugar_global{global, +key, head, args, plus, span, globals}:
      match global:
        case Global{ _,  _,  _, ty,  _,  True{}}: checker_scc_run_39(CheckerSccCall_lower_family_sugar_family{ty, key, head, args, plus, span, globals})
        case Global{ _,  _,  _,  _,  _,  False{}}: family_failure(span, String.append("name is not a datatype: ", key), "a declared datatype", key)

    case CheckerSccCall_lower_family_sugar_global_result{found, +key, head, args, plus, span, globals}:
      match found:
        case None{}: family_failure(span, String.append("unknown datatype ", key), "a declared datatype", key)
        case Some{global}: checker_scc_run_39(CheckerSccCall_lower_family_sugar_global{global, key, head, args, plus, span, globals})

    case CheckerSccCall_lower_family_sugar_key_result{found, head, args, plus, span, +globals}:
      match found:
        case None{}: family_failure(span, "datatype sugar requires a family name", "a declared datatype", "a non-family expression")
        case Some{+key}: checker_scc_run_39(CheckerSccCall_lower_family_sugar_global_result{lookup_global(key, globals), key, head, args, plus, span, globals})

    case CheckerSccCall_lower_family_sugar{head, args, plus, span, globals}:
      match head:
        case Ast.TermVar{_, _, _}: lower_family_sugar_variable(plus && List.is_empty(&2, Ast.SyntaxTerm, args), head, span)
        case _: checker_scc_run_39(CheckerSccCall_lower_family_sugar_key_result{family_head_key(head), head, args, plus, span, globals})


def family_lowered_whnf(fuel: Nat, original: Ast.SyntaxTerm, globals: List<&2, Global>, lowering: FamilyLowering) -> Ast.SyntaxTerm:
  checker_scc_run_39(CheckerSccCall_family_lowered_whnf{fuel, original, globals, lowering})

def whnf_ref_type(ty_view: Ast.SyntaxTerm, more: Nat, term: Ast.SyntaxTerm, value: Ast.SyntaxTerm, globals: List<&2, Global>) -> Ast.SyntaxTerm:
  checker_scc_run_39(CheckerSccCall_whnf_ref_type{ty_view, more, term, value, globals})

def whnf_ref_global(global: Global, more: Nat, term: Ast.SyntaxTerm, globals: List<&2, Global>) -> Ast.SyntaxTerm:
  checker_scc_run_39(CheckerSccCall_whnf_ref_global{global, more, term, globals})

def whnf_ref_result(found: Maybe<&2, Global>, more: Nat, term: Ast.SyntaxTerm, globals: List<&2, Global>) -> Ast.SyntaxTerm:
  checker_scc_run_39(CheckerSccCall_whnf_ref_result{found, more, term, globals})

def whnf_application(fn_type: Ast.SyntaxTerm, more: Nat, term: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, globals: List<&2, Global>) -> Ast.SyntaxTerm:
  checker_scc_run_39(CheckerSccCall_whnf_application{fn_type, more, term, arg, globals})

def whnf(fuel: Nat, term: Ast.SyntaxTerm, globals: List<&2, Global>) -> Ast.SyntaxTerm:
  checker_scc_run_39(CheckerSccCall_whnf{fuel, term, globals})

def family_arity_view(view: Ast.SyntaxTerm, globals: List<&2, Global>) -> Nat:
  checker_scc_run_39(CheckerSccCall_family_arity_view{view, globals})

def family_arity(ty: Ast.SyntaxTerm, globals: List<&2, Global>) -> Nat:
  checker_scc_run_39(CheckerSccCall_family_arity{ty, globals})

def family_quant_prefix_domain(domain_view: Ast.SyntaxTerm, body: Ast.SyntaxTerm, globals: List<&2, Global>) -> Nat:
  checker_scc_run_39(CheckerSccCall_family_quant_prefix_domain{domain_view, body, globals})

def family_quant_prefix_view(view: Ast.SyntaxTerm, globals: List<&2, Global>) -> Nat:
  checker_scc_run_39(CheckerSccCall_family_quant_prefix_view{view, globals})

def family_quant_prefix(ty: Ast.SyntaxTerm, globals: List<&2, Global>) -> Nat:
  checker_scc_run_39(CheckerSccCall_family_quant_prefix{ty, globals})

def lower_family_sugar_family(+ty: Ast.SyntaxTerm, key: String, +head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, plus: Bool, +span: Ast.SourceSpan, +globals: List<&2, Global>) -> FamilyLowering:
  checker_scc_run_39(CheckerSccCall_lower_family_sugar_family{ty, key, head, args, plus, span, globals})

def lower_family_sugar_global(global: Global, +key: String, head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, plus: Bool, span: Ast.SourceSpan, globals: List<&2, Global>) -> FamilyLowering:
  checker_scc_run_39(CheckerSccCall_lower_family_sugar_global{global, key, head, args, plus, span, globals})

def lower_family_sugar_global_result(found: Maybe<&2, Global>, +key: String, head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, plus: Bool, span: Ast.SourceSpan, globals: List<&2, Global>) -> FamilyLowering:
  checker_scc_run_39(CheckerSccCall_lower_family_sugar_global_result{found, key, head, args, plus, span, globals})

def lower_family_sugar_key_result(found: Maybe<&2, String>, head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, plus: Bool, span: Ast.SourceSpan, +globals: List<&2, Global>) -> FamilyLowering:
  checker_scc_run_39(CheckerSccCall_lower_family_sugar_key_result{found, head, args, plus, span, globals})

def lower_family_sugar(head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, plus: Bool, span: Ast.SourceSpan, globals: List<&2, Global>) -> FamilyLowering:
  checker_scc_run_39(CheckerSccCall_lower_family_sugar{head, args, plus, span, globals})

def equal_refs(a: List<&2, String>, b: List<&2, String>, globals: List<&2, Global>) -> Bool:
  match a b:
    case Nil{} Nil{}: True{}
    case +x <> xs +y <> ys:
      Bool.pick(Bool, String.eq(canonical_name(x, globals), canonical_name(y, globals)), equal_refs(xs, ys, globals), False{})
    case _ _: False{}

type CheckerSccInput41 is Data:
  CheckerSccCall_equal_term{a: Ast.SyntaxTerm, b: Ast.SyntaxTerm, globals: List<&2, Global>}
  CheckerSccCall_equal_raw{a: Ast.SyntaxTerm, b: Ast.SyntaxTerm, globals: List<&2, Global>}
  CheckerSccCall_equal_lists{a: List<&2, Ast.SyntaxTerm>, b: List<&2, Ast.SyntaxTerm>, globals: List<&2, Global>}

def checker_scc_result_41(request: CheckerSccInput41) -> Type:
  match request:
    case CheckerSccCall_equal_term{a, b, globals}: Bool
    case CheckerSccCall_equal_raw{a, b, globals}: Bool
    case CheckerSccCall_equal_lists{a, b, globals}: Bool

def checker_scc_run_41(request: CheckerSccInput41) -> checker_scc_result_41(request):
  match request:
    case CheckerSccCall_equal_term{a, b, globals}:
      checker_scc_run_41(CheckerSccCall_equal_raw{whnf(64n, a, globals), whnf(64n, b, globals), globals})

    case CheckerSccCall_equal_raw{a, b, globals}:
      match a b:
        case Ast.TermType{ ak,  _} Ast.TermType{ bk,  _}: checker_scc_run_41(CheckerSccCall_equal_term{ak, bk, globals})
        case Ast.TermQuantity{ aq,  _} Ast.TermQuantity{ bq,  _}: same_quantity(aq, bq)
        case Ast.TermQuant{} Ast.TermQuant{}: True{}
        case Ast.TermBang{ ai,  _} Ast.TermBang{ bi,  _}: checker_scc_run_41(CheckerSccCall_equal_term{ai, bi, globals})
        case Ast.TermBang{ inner,  _} _: checker_scc_run_41(CheckerSccCall_equal_term{inner, b, globals})
        case _ Ast.TermBang{ inner,  _}: checker_scc_run_41(CheckerSccCall_equal_term{a, inner, globals})
        case Ast.TermVar{ _,  ai,  _} Ast.TermVar{ _,  bi,  _}: Nat.is_eq(ai, bi)
        case Ast.TermRef{ ak,  _} Ast.TermRef{ bk,  _}: String.eq(canonical_name(ak, globals), canonical_name(bk, globals))
        case Ast.TermAll{ aq,  _,  _,  at,  ab,  _} Ast.TermAll{ bq,  _,  _,  bt,  bb,  _}:
          Bool.and(same_quantity(aq, bq), Bool.and(checker_scc_run_41(CheckerSccCall_equal_term{at, bt, globals}), checker_scc_run_41(CheckerSccCall_equal_term{ab, bb, globals})))
        case Ast.TermApp{ af,  ax,  _} Ast.TermApp{ bf,  bx,  _}:
          Bool.and(checker_scc_run_41(CheckerSccCall_equal_term{af, bf, globals}), checker_scc_run_41(CheckerSccCall_equal_term{ax, bx, globals}))
        case Ast.TermAdt{ ak,  aa,  ar,  _} Ast.TermAdt{ bk,  ba,  br,  _}:
          Bool.and(family_equal(ak, bk, globals), Bool.and(checker_scc_run_41(CheckerSccCall_equal_lists{aa, ba, globals}), equal_refs(ar, br, globals)))
        case Ast.TermHole{ ak,  _} Ast.TermHole{ bk,  _}: String.eq(ak, bk)
        case _ _: False{}

    case CheckerSccCall_equal_lists{a, b, globals}:
      match a b:
        case Nil{} Nil{}: True{}
        case +x <> xs +y <> ys:
          Bool.pick(Bool, checker_scc_run_41(CheckerSccCall_equal_term{x, y, globals}), checker_scc_run_41(CheckerSccCall_equal_lists{xs, ys, globals}), False{})
        case _ _: False{}


def equal_term(a: Ast.SyntaxTerm, b: Ast.SyntaxTerm, globals: List<&2, Global>) -> Bool:
  checker_scc_run_41(CheckerSccCall_equal_term{a, b, globals})

def equal_raw(a: Ast.SyntaxTerm, b: Ast.SyntaxTerm, globals: List<&2, Global>) -> Bool:
  checker_scc_run_41(CheckerSccCall_equal_raw{a, b, globals})

def equal_lists(a: List<&2, Ast.SyntaxTerm>, b: List<&2, Ast.SyntaxTerm>, globals: List<&2, Global>) -> Bool:
  checker_scc_run_41(CheckerSccCall_equal_lists{a, b, globals})

type CheckerSccInput42 is Data:
  CheckerSccCall_fits_kind_whnf{a: Ast.SyntaxTerm, b: Ast.SyntaxTerm, source: Ast.SyntaxTerm, target: Ast.SyntaxTerm, globals: List<&2, Global>}
  CheckerSccCall_fits_kind{source: Ast.SyntaxTerm, target: Ast.SyntaxTerm, globals: List<&2, Global>}

def checker_scc_result_42(request: CheckerSccInput42) -> Type:
  match request:
    case CheckerSccCall_fits_kind_whnf{a, b, source, target, globals}: Bool
    case CheckerSccCall_fits_kind{source, target, globals}: Bool

def checker_scc_run_42(request: CheckerSccInput42) -> checker_scc_result_42(request):
  match request:
    case CheckerSccCall_fits_kind_whnf{a, b, source, target, globals}:
      match a b:
        case Ast.TermQuantity{ Ast.QMany{},  _} _: True{}
        case _ Ast.TermQuantity{ Ast.QZero{},  _}: True{}
        case _ Ast.TermQuantity{ Ast.QOne{},  _}: True{}
        case Ast.TermMin{ a,  b,  _} _:
          Bool.and(checker_scc_run_42(CheckerSccCall_fits_kind{a, target, globals}), checker_scc_run_42(CheckerSccCall_fits_kind{b, target, globals}))
        case _ Ast.TermMin{ a,  b,  _}:
          Bool.or(checker_scc_run_42(CheckerSccCall_fits_kind{source, a, globals}), checker_scc_run_42(CheckerSccCall_fits_kind{source, b, globals}))
        case _ _: equal_term(source, target, globals)

    case CheckerSccCall_fits_kind{source, target, globals}:
      checker_scc_run_42(CheckerSccCall_fits_kind_whnf{whnf(64n, source, globals), whnf(64n, target, globals), source, target, globals})


def fits_kind_whnf(a: Ast.SyntaxTerm, b: Ast.SyntaxTerm, source: Ast.SyntaxTerm, target: Ast.SyntaxTerm, globals: List<&2, Global>) -> Bool:
  checker_scc_run_42(CheckerSccCall_fits_kind_whnf{a, b, source, target, globals})

def fits_kind(source: Ast.SyntaxTerm, target: Ast.SyntaxTerm, globals: List<&2, Global>) -> Bool:
  checker_scc_run_42(CheckerSccCall_fits_kind{source, target, globals})

def has_canonical_name(key: String, names: List<&2, String>, globals: List<&2, Global>) -> Bool:
  match names:
    case Nil{}: False{}
    case +name <> rest:
      target = canonical_name(key, globals)
      Bool.pick(Bool, String.eq(target, canonical_name(name, globals)), True{}, has_canonical_name(key, rest, globals))
def refs_contain_all(need: List<&2, String>, have: List<&2, String>, globals: List<&2, Global>) -> Bool:
  match need:
    case Nil{}: True{}
    case +key <> rest:
      Bool.pick(Bool, has_canonical_name(key, have, globals), refs_contain_all(rest, have, globals), False{})

type CheckerSccInput45 is Data:
  CheckerSccCall_fits_term_whnf{a: Ast.SyntaxTerm, b: Ast.SyntaxTerm, globals: List<&2, Global>}
  CheckerSccCall_fits_term{source: Ast.SyntaxTerm, target: Ast.SyntaxTerm, globals: List<&2, Global>}

def checker_scc_result_45(request: CheckerSccInput45) -> Type:
  match request:
    case CheckerSccCall_fits_term_whnf{a, b, globals}: Bool
    case CheckerSccCall_fits_term{source, target, globals}: Bool

def checker_scc_run_45(request: CheckerSccInput45) -> checker_scc_result_45(request):
  match request:
    case CheckerSccCall_fits_term_whnf{a, b, globals}:
      match a b:
        case Ast.TermType{ g,  _} Ast.TermType{ h,  _}: fits_kind(g, h, globals)
        case Ast.TermAll{ aq,  _,  _,  at,  ab,  _} Ast.TermAll{ bq,  _,  _,  bt,  bb,  _}:
          Bool.and(same_quantity(aq, bq), Bool.and(checker_scc_run_45(CheckerSccCall_fits_term{bt, at, globals}), checker_scc_run_45(CheckerSccCall_fits_term{ab, bb, globals})))
        case Ast.TermAdt{ ak,  aa,  ar,  _} Ast.TermAdt{ bk,  ba,  br,  _}:
          Bool.and(family_equal(ak, bk, globals), Bool.and(equal_lists(aa, ba, globals), refs_contain_all(br, ar, globals)))
        case _ _: equal_term(a, b, globals)

    case CheckerSccCall_fits_term{source, target, globals}:
      checker_scc_run_45(CheckerSccCall_fits_term_whnf{whnf(64n, source, globals), whnf(64n, target, globals), globals})


def fits_term_whnf(a: Ast.SyntaxTerm, b: Ast.SyntaxTerm, globals: List<&2, Global>) -> Bool:
  checker_scc_run_45(CheckerSccCall_fits_term_whnf{a, b, globals})

def fits_term(source: Ast.SyntaxTerm, target: Ast.SyntaxTerm, globals: List<&2, Global>) -> Bool:
  checker_scc_run_45(CheckerSccCall_fits_term{source, target, globals})

def check_lambda_body_use(valid: Bool, checked: Ast.SyntaxTerm, annotated: Maybe<&2, Ast.Quantity>, key: String, span: Ast.SourceSpan, expected: Ast.SyntaxTerm) -> Inference:
  Bool.pick(Inference, valid, Inferred{ Ast.TermLam{ annotated, key,  0n,  checked, span},  expected}, fail(span, String.append("invalid use quantity for ", key), "within the lambda quantity", "too many uses"))

def usage_get(index: Nat, usages: List<&2, UsageEntry>) -> Ast.Quantity:
  match usages:
    case Nil{}: Ast.QZero{}
    case +entry <> rest:
      match entry:
        case Usage{ found, quantity}: Bool.pick(Ast.Quantity, Nat.is_eq(found, index), quantity, usage_get(index, rest))

def substituted_usage_expected(expected: Maybe<&2, Ast.SyntaxTerm>, index: Nat, value: Ast.SyntaxTerm) -> Maybe<&2, Ast.SyntaxTerm>:
  match expected:
    case Some{ty}: Some{Core.subst(index, value, ty)}
    case None{}: None{}

def usage_merge_quantity(alternatives: Bool, old: Ast.Quantity, quantity: Ast.Quantity) -> Ast.Quantity:
  match alternatives:
    case True{}: quantity_alternative(old, quantity)
    case False{}: quantity_join(old, quantity)

def usage_set(index: Nat, quantity: Ast.Quantity, usages: List<&2, UsageEntry>) -> List<&2, UsageEntry>:
  match usages:
    case Nil{}: [Usage{index, quantity}]
    case +entry <> rest:
      match entry:
        case Usage{ found,  _}: Bool.pick(List<&2, UsageEntry>, Nat.is_eq(found, index), Usage{index, quantity} <> rest, entry <> usage_set(index, quantity, rest))

def usage_merge(left: List<&2, UsageEntry>, right: List<&2, UsageEntry>, alternatives: Bool) -> List<&2, UsageEntry>:
  match right:
    case Nil{}: left
    case +entry <> rest:
      match entry:
        case Usage{index, quantity}:
          old = usage_get(index, left)
          merged = usage_merge_quantity(alternatives, old, quantity)
          usage_merge(usage_set(index, merged, left), rest, alternatives)

def usage_unknown_type(span: Ast.SourceSpan) -> Ast.SyntaxTerm:
  Ast.TermType{ Ast.TermQuantity{ Ast.QMany{}, span}, span}

def lambda_quantity_mismatch(quantity: Ast.Quantity, expected: Ast.Quantity) -> Maybe<&2, Ast.Quantity>:
  match quantity expected:
    case Ast.QMany{} Ast.QOne{}: Some{Ast.QMany{}}
    case _ _: None{}

def lambda_quantity(annotated: Maybe<&2, Ast.Quantity>, expected: Ast.Quantity) -> Maybe<&2, Ast.Quantity>:
  match annotated:
    case None{}: Some{expected}
    case Some{quantity}:
      Bool.pick(Maybe<&2, Ast.Quantity>, same_quantity(quantity, expected), Some{expected}, lambda_quantity_mismatch(quantity, expected))

def usage_inferred_type(result: Inference, span: Ast.SourceSpan) -> Ast.SyntaxTerm:
  match result:
    case Inferred{ _, ty}: ty
    case InferenceFailure{ _}: usage_unknown_type(span)

def infer_local_reference(found: Maybe<&2, Binding>, key: String, term: Ast.SyntaxTerm, span: Ast.SourceSpan) -> Inference:
  match found:
    case Some{binding}:
      match binding:
        case Binding{ _,  _, ty}: Inferred{term, ty}
    case None{}: fail(span, String.append("unbound variable ", key), "a bound variable", key)

def infer_global_reference(found: Maybe<&2, Global>, key: String, term: Ast.SyntaxTerm, span: Ast.SourceSpan) -> Inference:
  match found:
    case Some{global}:
      match global:
        case Global{ _,  _,  _, ty,  _,  _}: Inferred{term, ty}
    case None{}: fail(span, String.append("unknown name ", key), "a declared name", key)

def infer_term_annotation_inner(result: Inference, checked_ty: Ast.SyntaxTerm, term: Ast.SyntaxTerm, span: Ast.SourceSpan) -> Inference:
  match result:
    case Inferred{ checked,  _}: Inferred{ Ast.TermAnn{ checked,  checked_ty, span},  checked_ty}
    case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}

def infer_type_annotation_result(result: Inference, term: Ast.SyntaxTerm, span: Ast.SourceSpan) -> Inference:
  match result:
    case Inferred{ _,  Ast.TermQuant{}}: Inferred{term,  Ast.TermType{ Ast.TermQuantity{ Ast.QOne{}, span}, span}}
    case Inferred{ _,  _}: fail(span, "kind annotation is not a quantity", "Quant", "a non-quantity")
    case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}

def infer_min_results(left_result: Inference, right_result: Inference, term: Ast.SyntaxTerm, span: Ast.SourceSpan) -> Inference:
  match left_result right_result:
    case Inferred{ _,  Ast.TermQuant{}} Inferred{ _,  Ast.TermQuant{}}: Inferred{term,  Ast.TermQuant{}}
    case InferenceFailure{diagnostic} _: InferenceFailure{diagnostic}
    case _ InferenceFailure{diagnostic}: InferenceFailure{diagnostic}
    case _ _: fail(span, "minimum operands must be quantities", "Quant", "a non-quantity")

def check_infer_term_sort(result: Inference, term: Ast.SyntaxTerm, span: Ast.SourceSpan) -> Inference:
  match result:
    case Inferred{ _,  Ast.TermType{ _, _}}: Inferred{term,  Ast.TermType{ Ast.TermQuantity{ Ast.QOne{}, span}, span}}
    case Inferred{ _,  _}: fail(span, "function codomain is not a type", "a type", "a term")
    case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}

def infer_application_check(result: Inference, term: Ast.SyntaxTerm, codomain: Ast.SyntaxTerm) -> Inference:
  match result:
    case Inferred{ checked_arg,  _}: Inferred{term,  Core.subst(0n, checked_arg, codomain)}
    case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}

def application_has_bang(term: Ast.SyntaxTerm) -> Bool:
  match term:
    case Ast.TermBang{ Ast.TermRef{ _,  _},  _}: True{}
    case Ast.TermApp{fn,  _,  _}: application_has_bang(fn)
    case Ast.TermAnn{ inner,  _,  _}: application_has_bang(inner)
    case Ast.TermSub{index, value, body,  _}: application_has_bang(Core.subst(index, value, body))
    case _: False{}

type CheckerSccInput64 is Data:
  CheckerSccCall_application_argument_bangs_valid_terms{terms: List<&2, Ast.SyntaxTerm>}
  CheckerSccCall_application_argument_bangs_valid{term: Ast.SyntaxTerm}
  CheckerSccCall_application_bangs_valid{term: Ast.SyntaxTerm}

def checker_scc_result_64(request: CheckerSccInput64) -> Type:
  match request:
    case CheckerSccCall_application_argument_bangs_valid_terms{terms}: Bool
    case CheckerSccCall_application_argument_bangs_valid{term}: Bool
    case CheckerSccCall_application_bangs_valid{term}: Bool

def checker_scc_run_64(request: CheckerSccInput64) -> checker_scc_result_64(request):
  match request:
    case CheckerSccCall_application_argument_bangs_valid_terms{terms}:
      match terms:
        case Nil{}: True{}
        case +term <> rest: checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{term}) && checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid_terms{rest})

    case CheckerSccCall_application_argument_bangs_valid{term}:
      match term:
        case Ast.TermBang{_, _}: False{}
        case Ast.TermSub{index, value, body,  _}: checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{Core.subst(index, value, body)})
        case Ast.TermLet{ _,  _,  _, values, body,  _}: checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid_terms{values}) && checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{body})
        case Ast.TermAnn{ inner, ty,  _}: checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{inner}) && checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{ty})
        case Ast.TermTemplate{ inner,  _}: checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{inner})
        case Ast.TermType{kind,  _}: checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{kind})
        case Ast.TermMin{left, right,  _}: checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{left}) && checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{right})
        case Ast.TermAll{ _,  _,  _, ty, body,  _}: checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{ty}) && checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{body})
        case Ast.TermLam{ _,  _,  _, body,  _}: checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{body})
        case Ast.TermApp{fn, arg,  _}: checker_scc_run_64(CheckerSccCall_application_bangs_valid{fn}) && checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{arg})
        case Ast.TermAdt{ _, args,  _,  _}: checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid_terms{args})
        case Ast.TermFill{head, args,  _}: checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{head}) && checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid_terms{args})
        case Ast.TermPlus{head, args,  _}: checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{head}) && checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid_terms{args})
        case Ast.TermCtr{ _, args,  _}: checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid_terms{args})
        case Ast.TermMat{ _, head, matched,  _}: checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{head}) && checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{matched})
        case Ast.TermEqual{left, right, ty,  _}: checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{left}) && checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{right}) && checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{ty})
        case Ast.TermRewrite{equation, proof, body,  _}: checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{equation}) && checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{proof}) && checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{body})
        case Ast.BodyMatch{scrutinees, cases,  _}: checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid_terms{scrutinees}) && checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid_terms{cases})
        case Ast.BodyCase{ _, body,  _}: checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{body})
        case Ast.BodyLocal{ _,  _, values, body,  _}: checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid_terms{values}) && checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{body})
        case Ast.BodyReply{ inner,  _}: checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{inner})
        case _: True{}
    case CheckerSccCall_application_bangs_valid{term}:
      match term:
        case Ast.TermBang{ Ast.TermRef{ _,  _},  _}: True{}
        case Ast.TermBang{_, _}: False{}
        case Ast.TermApp{fn, arg,  _}: checker_scc_run_64(CheckerSccCall_application_bangs_valid{fn}) && checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{arg})
        case Ast.TermAnn{ inner, ty,  _}: checker_scc_run_64(CheckerSccCall_application_bangs_valid{inner}) && checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{ty})
        case Ast.TermSub{index, value, body,  _}: checker_scc_run_64(CheckerSccCall_application_bangs_valid{Core.subst(index, value, body)})
        case _: True{}


def application_argument_bangs_valid_terms(terms: List<&2, Ast.SyntaxTerm>) -> Bool:
  checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid_terms{terms})

def application_argument_bangs_valid(term: Ast.SyntaxTerm) -> Bool:
  checker_scc_run_64(CheckerSccCall_application_argument_bangs_valid{term})

def application_bangs_valid(term: Ast.SyntaxTerm) -> Bool:
  checker_scc_run_64(CheckerSccCall_application_bangs_valid{term})

def infer_equal_endpoints(left_result: Inference, right_result: Inference, left: Ast.SyntaxTerm, right: Ast.SyntaxTerm, ty: Ast.SyntaxTerm, term: Ast.SyntaxTerm, span: Ast.SourceSpan, globals: List<&2, Global>) -> Inference:
  match left_result right_result:
    case Inferred{ _,  lt} Inferred{ _,  rt}:
      Bool.pick(Inference, Bool.and(fits_term(lt, ty, globals), fits_term(rt, ty, globals)), Inferred{term,  Ast.TermType{ Ast.TermQuantity{ Ast.QMany{}, span}, span}}, fail(span, "equation endpoint has the wrong type", "the equation type", "an incompatible type"))
    case InferenceFailure{diagnostic} _: InferenceFailure{diagnostic}
    case _ InferenceFailure{diagnostic}: InferenceFailure{diagnostic}

def substitute_many(values: List<&2, Ast.SyntaxTerm>, body: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  match values:
    case Nil{}: body
    case +value <> rest: substitute_many(rest, Core.subst(0n, value, body))

def local_pattern_quantities_match(patterns: List<&2, Ast.SyntaxPattern>, quantity: Ast.Quantity) -> Bool:
  match patterns:
    case Nil{}: True{}
    case +pattern <> rest:
      match pattern:
        case Ast.PatternVar{ _,  _,  found,  _}: Bool.and(same_quantity(found, quantity), local_pattern_quantities_match(rest, quantity))
        case Ast.PatternCtr{_, _, _}: False{}

def shift_expected(expected: Maybe<&2, Ast.SyntaxTerm>, amount: Nat) -> Maybe<&2, Ast.SyntaxTerm>:
  match expected:
    case Some{value}: Some{Core.shift(0n, amount, value)}
    case None{}: None{}

def term_usage_map_argument_expected_view(view: Ast.SyntaxTerm) -> Maybe<&2, Ast.SyntaxTerm>:
  match view:
    case Ast.TermAll{ _,  _,  _, ty,  _,  _}: Some{ty}
    case _: None{}

def term_usage_map_argument_expected(found: Maybe<&2, Ast.SyntaxTerm>, globals: List<&2, Global>) -> Maybe<&2, Ast.SyntaxTerm>:
  match found:
    case Some{fn_ty}: term_usage_map_argument_expected_view(whnf(64n, fn_ty, globals))
    case None{}: None{}

def function_type_of_binding_result(found: Maybe<&2, Binding>) -> Maybe<&2, Ast.SyntaxTerm>:
  match found:
    case None{}: None{}
    case Some{binding}:
      match binding:
        case Binding{ _,  _, ty}: Some{ty}

def function_type_of_global_result(found: Maybe<&2, Global>) -> Maybe<&2, Ast.SyntaxTerm>:
  match found:
    case None{}: None{}
    case Some{global}:
      match global:
        case Global{ _,  _,  _, ty,  _,  _}: Some{ty}

def function_type_of_application_view(view: Ast.SyntaxTerm, arg: Ast.SyntaxTerm) -> Maybe<&2, Ast.SyntaxTerm>:
  match view:
    case Ast.TermAll{ _,  _,  _,  _, body,  _}: Some{Core.subst(0n, arg, body)}
    case _: None{}

def function_type_of_application_result(found: Maybe<&2, Ast.SyntaxTerm>, arg: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>) -> Maybe<&2, Ast.SyntaxTerm>:
  match found:
    case None{}: None{}
    case Some{ty}: function_type_of_application_view(whnf(64n, ty, globals), arg)

def function_type_of(term: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>) -> Maybe<&2, Ast.SyntaxTerm>:
  match term:
    case Ast.TermBang{ inner,  _}: function_type_of(inner, env, globals)
    case Ast.TermSub{index, value, body,  _}: function_type_of(Core.subst(index, value, body), env, globals)
    case Ast.TermAnn{ _, ty,  _}: Some{ty}
    case Ast.TermVar{ _, index,  _}: function_type_of_binding_result(lookup_binding(index, env))
    case Ast.TermRef{key,  _}: function_type_of_global_result(lookup_global(key, globals))
    case Ast.TermApp{fn, arg,  _}: function_type_of_application_result(function_type_of(fn, env, globals), arg, env, globals)
    case _: None{}

def function_quantity_from_type_view(view: Ast.SyntaxTerm) -> Maybe<&2, Ast.Quantity>:
  match view:
    case Ast.TermAll{quantity,  _,  _,  _,  _,  _}: Some{quantity}
    case _: None{}

def function_quantity_from_type(ty: Ast.SyntaxTerm, globals: List<&2, Global>) -> Maybe<&2, Ast.Quantity>:
  function_quantity_from_type_view(whnf(64n, ty, globals))

def function_argument_quantity_result(found: Maybe<&2, Ast.SyntaxTerm>, globals: List<&2, Global>) -> Maybe<&2, Ast.Quantity>:
  match found:
    case Some{ ty}: function_quantity_from_type(ty, globals)
    case None{}: None{}

def function_argument_quantity(fn: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>) -> Maybe<&2, Ast.Quantity>:
  function_argument_quantity_result(function_type_of(fn, env, globals), globals)

def collect_telescope_quantities_view(view: Ast.SyntaxTerm, current: Ast.SyntaxTerm, depth: Nat, globals: List<&2, Global>) -> List<&2, Ast.Quantity>:
  match view:
    case Ast.TermAll{quantity, key,  _, ty, body,  _}:
      neutral = Ast.TermVar{key,  depth,  term_span(ty)}
      quantity <> collect_telescope_quantities_view(whnf(64n, Core.subst(0n, neutral, body), globals), Core.subst(0n, neutral, body), depth + 1n, globals)
    case _: Nil{}

def collect_telescope_quantities(current: Ast.SyntaxTerm, depth: Nat, globals: List<&2, Global>) -> List<&2, Ast.Quantity>:
  collect_telescope_quantities_view(whnf(64n, current, globals), current, depth, globals)

def family_parameter_quantities_result(found: Maybe<&2, Global>, globals: List<&2, Global>) -> List<&2, Ast.Quantity>:
  match found:
    case None{}: Nil{}
    case Some{global}:
      match global:
        case Global{ _,  _,  _, ty,  _,  _}: collect_telescope_quantities(ty, 0n, globals)

def family_parameter_quantities(family: String, globals: List<&2, Global>) -> List<&2, Ast.Quantity>:
  family_parameter_quantities_result(lookup_global(family, globals), globals)

type CheckerSccInput84 is Data:
  CheckerSccCall_initial_telescope_count_view{view: Ast.SyntaxTerm, globals: List<&2, Global>}
  CheckerSccCall_initial_telescope_count{term: Ast.SyntaxTerm, globals: List<&2, Global>}

def checker_scc_result_84(request: CheckerSccInput84) -> Type:
  match request:
    case CheckerSccCall_initial_telescope_count_view{view, globals}: Nat
    case CheckerSccCall_initial_telescope_count{term, globals}: Nat

def checker_scc_run_84(request: CheckerSccInput84) -> checker_scc_result_84(request):
  match request:
    case CheckerSccCall_initial_telescope_count_view{view, globals}:
      match view:
        case Ast.TermAll{ _,  _,  _,  _, body,  _}: 1n + checker_scc_run_84(CheckerSccCall_initial_telescope_count{body, globals})
        case _: 0n

    case CheckerSccCall_initial_telescope_count{term, globals}:
      checker_scc_run_84(CheckerSccCall_initial_telescope_count_view{whnf(64n, term, globals), globals})


def initial_telescope_count_view(view: Ast.SyntaxTerm, globals: List<&2, Global>) -> Nat:
  checker_scc_run_84(CheckerSccCall_initial_telescope_count_view{view, globals})

def initial_telescope_count(term: Ast.SyntaxTerm, globals: List<&2, Global>) -> Nat:
  checker_scc_run_84(CheckerSccCall_initial_telescope_count{term, globals})

type CheckerSccInput85 is Data:
  CheckerSccCall_drop_telescope_view{view: Ast.SyntaxTerm, rest: Nat, term: Ast.SyntaxTerm, globals: List<&2, Global>}
  CheckerSccCall_drop_telescope{count: Nat, term: Ast.SyntaxTerm, globals: List<&2, Global>}

def checker_scc_result_85(request: CheckerSccInput85) -> Type:
  match request:
    case CheckerSccCall_drop_telescope_view{view, rest, term, globals}: Ast.SyntaxTerm
    case CheckerSccCall_drop_telescope{count, term, globals}: Ast.SyntaxTerm

def checker_scc_run_85(request: CheckerSccInput85) -> checker_scc_result_85(request):
  match request:
    case CheckerSccCall_drop_telescope_view{view, rest, term, globals}:
      match view:
        case Ast.TermAll{ _,  _,  _,  _, body,  _}: checker_scc_run_85(CheckerSccCall_drop_telescope{rest, body, globals})
        case _: term

    case CheckerSccCall_drop_telescope{count, term, globals}:
      match count:
        case 0n: term
        case 1n+rest: checker_scc_run_85(CheckerSccCall_drop_telescope_view{whnf(64n, term, globals), rest, term, globals})


def drop_telescope_view(view: Ast.SyntaxTerm, rest: Nat, term: Ast.SyntaxTerm, globals: List<&2, Global>) -> Ast.SyntaxTerm:
  checker_scc_run_85(CheckerSccCall_drop_telescope_view{view, rest, term, globals})

def drop_telescope(count: Nat, term: Ast.SyntaxTerm, globals: List<&2, Global>) -> Ast.SyntaxTerm:
  checker_scc_run_85(CheckerSccCall_drop_telescope{count, term, globals})

def constructor_field_quantities_family_global(found: Maybe<&2, Global>, ty: Ast.SyntaxTerm, globals: List<&2, Global>) -> List<&2, Ast.Quantity>:
  match found:
    case None{}: Nil{}
    case Some{family_global}:
      match family_global:
        case Global{ _,  _,  _,  family_ty,  _,  _}:
          parameters = initial_telescope_count(family_ty, globals)
          collect_telescope_quantities(drop_telescope(parameters, ty, globals), 0n, globals)

def constructor_field_quantities_family(found: Maybe<&2, String>, ty: Ast.SyntaxTerm, globals: List<&2, Global>) -> List<&2, Ast.Quantity>:
  match found:
    case None{}: Nil{}
    case Some{family}: constructor_field_quantities_family_global(lookup_global(resolve_family_key(family, globals), globals), ty, globals)

def constructor_family_view(view: Ast.SyntaxTerm, globals: List<&2, Global>) -> Maybe<&2, String>:
  match view:
    case Ast.TermAll{ _,  _,  _,  _, body,  _}: constructor_family_view(whnf(64n, body, globals), globals)
    case Ast.TermAdt{key,  _,  _,  _}: Some{key}
    case _: None{}

def constructor_family(ty: Ast.SyntaxTerm, globals: List<&2, Global>) -> Maybe<&2, String>:
  constructor_family_view(whnf(64n, ty, globals), globals)



def constructor_field_quantities_global(global: Global, globals: List<&2, Global>) -> List<&2, Ast.Quantity>:
  match global:
    case Global{ _,  _,  _, ty,  _,  _}: constructor_field_quantities_family(constructor_family(ty, globals), ty, globals)

def constructor_field_quantities_result(found: Maybe<&2, Global>, globals: List<&2, Global>) -> List<&2, Ast.Quantity>:
  match found:
    case None{}: Nil{}
    case Some{global}: constructor_field_quantities_global(global, globals)

def constructor_field_quantities(constructor: String, globals: List<&2, Global>) -> List<&2, Ast.Quantity>:
  constructor_field_quantities_result(lookup_global(constructor, globals), globals)

def apply_prefix(args: List<&2, Ast.SyntaxTerm>, ty: Ast.SyntaxTerm) -> Maybe<&2, Ast.SyntaxTerm>:
  match args:
    case Nil{}: Some{ty}
    case +arg <> rest:
      match ty:
        case Ast.TermAll{ _,  _,  _,  _, body,  _}:
          apply_prefix(rest, Core.subst(0n, arg, body))
        case _: None{}

def constructor_usage_expected_view(view: Ast.SyntaxTerm, family: String, parameter_count: Nat, ty: Ast.SyntaxTerm, globals: List<&2, Global>) -> Maybe<&2, Ast.SyntaxTerm>:
  match view:
    case Ast.TermAdt{ expected_family,  parameters,  _,  _}:
      expected_matches = String.eq(resolve_family_key(expected_family, globals), resolve_family_key(family, globals))
      Bool.pick(Maybe<&2, Ast.SyntaxTerm>, expected_matches, apply_prefix(parameters, ty), Some{drop_telescope(parameter_count, ty, globals)})
    case _: Some{drop_telescope(parameter_count, ty, globals)}

def constructor_usage_expected(expected: Maybe<&2, Ast.SyntaxTerm>, family: String, parameter_count: Nat, ty: Ast.SyntaxTerm, globals: List<&2, Global>) -> Maybe<&2, Ast.SyntaxTerm>:
  match expected:
    case Some{ expected_ty}: constructor_usage_expected_view(whnf(64n, expected_ty, globals), family, parameter_count, ty, globals)
    case None{}: Some{drop_telescope(parameter_count, ty, globals)}

def constructor_usage_family_global(found: Maybe<&2, Global>, family: String, ty: Ast.SyntaxTerm, expected: Maybe<&2, Ast.SyntaxTerm>, globals: List<&2, Global>) -> Maybe<&2, Ast.SyntaxTerm>:
  match found:
    case None{}: None{}
    case Some{family_global}:
      match family_global:
        case Global{ _,  _,  _,  family_ty,  _,  _}:
          parameter_count = initial_telescope_count(family_ty, globals)
          constructor_usage_expected(expected, family, parameter_count, ty, globals)

def constructor_usage_family(found: Maybe<&2, String>, ty: Ast.SyntaxTerm, expected: Maybe<&2, Ast.SyntaxTerm>, globals: List<&2, Global>) -> Maybe<&2, Ast.SyntaxTerm>:
  match found:
    case None{}: None{}
    case Some{family}:
      constructor_usage_family_global(lookup_global(resolve_family_key(family, globals), globals), family, ty, expected, globals)

def constructor_usage_global(global: Global, expected: Maybe<&2, Ast.SyntaxTerm>, globals: List<&2, Global>) -> Maybe<&2, Ast.SyntaxTerm>:
  match global:
    case Global{ _,  _,  _, ty,  _,  _}: constructor_usage_family(constructor_family(ty, globals), ty, expected, globals)

def constructor_usage_global_result(found: Maybe<&2, Global>, expected: Maybe<&2, Ast.SyntaxTerm>, globals: List<&2, Global>) -> Maybe<&2, Ast.SyntaxTerm>:
  match found:
    case None{}: None{}
    case Some{global}: constructor_usage_global(global, expected, globals)

def constructor_usage_field_type(key: String, expected: Maybe<&2, Ast.SyntaxTerm>, globals: List<&2, Global>) -> Maybe<&2, Ast.SyntaxTerm>:
  constructor_usage_global_result(lookup_global(key, globals), expected, globals)

def maybe_shift_index(index: Maybe<&2, Nat>, offset: Nat) -> Maybe<&2, Nat>:
  match index:
    case Some{value}: Some{value + offset}
    case None{}: None{}

def scrutinee_variable_index(term: Ast.SyntaxTerm, globals: List<&2, Global>) -> Maybe<&2, Nat>:
  match term:
    case Ast.TermVar{ _, index,  _}: Some{index}
    case _: None{}
def binding_quantity_result(found: Maybe<&2, Binding>) -> Ast.Quantity:
  match found:
    case Some{binding}:
      match binding:
        case Binding{ _, quantity,  _}: quantity
    case None{}: Ast.QOne{}

def binding_quantity_or_one(index: Nat, env: List<&2, Binding>) -> Ast.Quantity:
  binding_quantity_result(lookup_binding(index, env))

def optional_source_quantity(source_index: Maybe<&2, Nat>, env: List<&2, Binding>) -> Ast.Quantity:
  match source_index:
    case Some{value}: binding_quantity_or_one(value, env)
    case None{}: Ast.QOne{}

type CheckerSccInput106 is Data:
  CheckerSccCall_pattern_value{pattern: Ast.SyntaxPattern, final_depth: Nat}
  CheckerSccCall_pattern_values{patterns: List<&2, Ast.SyntaxPattern>, final_depth: Nat}

def checker_scc_result_106(request: CheckerSccInput106) -> Type:
  match request:
    case CheckerSccCall_pattern_value{pattern, final_depth}: Ast.SyntaxTerm
    case CheckerSccCall_pattern_values{patterns, final_depth}: List<&2, Ast.SyntaxTerm>

def checker_scc_run_106(request: CheckerSccInput106) -> checker_scc_result_106(request):
  match request:
    case CheckerSccCall_pattern_value{pattern, final_depth}:
      match pattern:
        case Ast.PatternVar{key, index,  _, span}: Ast.TermVar{key,  final_depth - index - 1n, span}
        case Ast.PatternCtr{key, fields, span}: Ast.TermCtr{key,  checker_scc_run_106(CheckerSccCall_pattern_values{fields, final_depth}), span}

    case CheckerSccCall_pattern_values{patterns, final_depth}:
      match patterns:
        case Nil{}: Nil{}
        case +pattern <> rest: checker_scc_run_106(CheckerSccCall_pattern_value{pattern, final_depth}) <> checker_scc_run_106(CheckerSccCall_pattern_values{rest, final_depth})


def pattern_value(pattern: Ast.SyntaxPattern, final_depth: Nat) -> Ast.SyntaxTerm:
  checker_scc_run_106(CheckerSccCall_pattern_value{pattern, final_depth})

def pattern_values(patterns: List<&2, Ast.SyntaxPattern>, final_depth: Nat) -> List<&2, Ast.SyntaxTerm>:
  checker_scc_run_106(CheckerSccCall_pattern_values{patterns, final_depth})

type CheckerSccInput107 is Data:
  CheckerSccCall_replace_free_terms{terms: List<&2, Ast.SyntaxTerm>, index: Nat, replacement: Ast.SyntaxTerm, depth: Nat}
  CheckerSccCall_replace_free_cases{cases: List<&2, Ast.SyntaxTerm>, index: Nat, replacement: Ast.SyntaxTerm, depth: Nat}
  CheckerSccCall_replace_free_term{term: Ast.SyntaxTerm, index: Nat, replacement: Ast.SyntaxTerm, depth: Nat}

def checker_scc_result_107(request: CheckerSccInput107) -> Type:
  match request:
    case CheckerSccCall_replace_free_terms{terms, index, replacement, depth}: List<&2, Ast.SyntaxTerm>
    case CheckerSccCall_replace_free_cases{cases, index, replacement, depth}: List<&2, Ast.SyntaxTerm>
    case CheckerSccCall_replace_free_term{term, index, replacement, depth}: Ast.SyntaxTerm

def checker_scc_run_107(request: CheckerSccInput107) -> checker_scc_result_107(request):
  match request:
    case CheckerSccCall_replace_free_terms{terms, index, replacement, depth}:
      match terms:
        case Nil{}: Nil{}
        case +term <> rest: checker_scc_run_107(CheckerSccCall_replace_free_term{term, index, replacement, depth}) <> checker_scc_run_107(CheckerSccCall_replace_free_terms{rest, index, replacement, depth})

    case CheckerSccCall_replace_free_cases{cases, index, replacement, depth}:
      match cases:
        case Nil{}: Nil{}
        case +case_term <> rest:
          match case_term:
            case Ast.BodyCase{patterns, body, span}: Ast.BodyCase{patterns,  checker_scc_run_107(CheckerSccCall_replace_free_term{body, index, replacement, depth + Core.pattern_list_depth(patterns)}), span} <> checker_scc_run_107(CheckerSccCall_replace_free_cases{rest, index, replacement, depth})
            case _: checker_scc_run_107(CheckerSccCall_replace_free_term{case_term, index, replacement, depth}) <> checker_scc_run_107(CheckerSccCall_replace_free_cases{rest, index, replacement, depth})

    case CheckerSccCall_replace_free_term{term, index, replacement, depth}:
      match term:
        case Ast.TermVar{key,  found, span}:
          Bool.pick(Ast.SyntaxTerm, Nat.is_eq(found, index + depth), Core.shift(0n, depth, replacement), Ast.TermVar{key,  found, span})
        case Ast.TermBang{ inner, span}: Ast.TermBang{ checker_scc_run_107(CheckerSccCall_replace_free_term{inner, index, replacement, depth}), span}
        case Ast.TermRef{_, _}: term
        case Ast.TermSub{ sub_index, value, body,  _}: checker_scc_run_107(CheckerSccCall_replace_free_term{Core.subst(sub_index, value, body), index, replacement, depth})
        case Ast.TermLet{keys, indexes, quantities, values, body, span}: Ast.TermLet{keys, indexes, quantities,  checker_scc_run_107(CheckerSccCall_replace_free_terms{values, index, replacement, depth}),  checker_scc_run_107(CheckerSccCall_replace_free_term{body, index, replacement, depth + List.length(&2, String, keys)}), span}
        case Ast.TermAnn{ inner, ty, span}: Ast.TermAnn{ checker_scc_run_107(CheckerSccCall_replace_free_term{inner, index, replacement, depth}),  checker_scc_run_107(CheckerSccCall_replace_free_term{ty, index, replacement, depth}), span}
        case Ast.TermTemplate{ inner, span}: Ast.TermTemplate{ checker_scc_run_107(CheckerSccCall_replace_free_term{inner, index, replacement, depth}), span}
        case Ast.TermType{kind, span}: Ast.TermType{ checker_scc_run_107(CheckerSccCall_replace_free_term{kind, index, replacement, depth}), span}
        case Ast.TermMin{left, right, span}: Ast.TermMin{ checker_scc_run_107(CheckerSccCall_replace_free_term{left, index, replacement, depth}),  checker_scc_run_107(CheckerSccCall_replace_free_term{right, index, replacement, depth}), span}
        case Ast.TermAll{quantity, key,  binder_index, ty, body, span}: Ast.TermAll{quantity, key,  binder_index,  checker_scc_run_107(CheckerSccCall_replace_free_term{ty, index, replacement, depth}),  checker_scc_run_107(CheckerSccCall_replace_free_term{body, index, replacement, depth + 1n}), span}
        case Ast.TermLam{quantity, key,  binder_index, body, span}: Ast.TermLam{quantity, key,  binder_index,  checker_scc_run_107(CheckerSccCall_replace_free_term{body, index, replacement, depth + 1n}), span}
        case Ast.TermApp{fn, arg, span}: Ast.TermApp{ checker_scc_run_107(CheckerSccCall_replace_free_term{fn, index, replacement, depth}),  checker_scc_run_107(CheckerSccCall_replace_free_term{arg, index, replacement, depth}), span}
        case Ast.TermAdt{key, args, refs, span}: Ast.TermAdt{key,  checker_scc_run_107(CheckerSccCall_replace_free_terms{args, index, replacement, depth}), refs, span}
        case Ast.TermFill{head, args, span}: Ast.TermFill{ checker_scc_run_107(CheckerSccCall_replace_free_term{head, index, replacement, depth}),  checker_scc_run_107(CheckerSccCall_replace_free_terms{args, index, replacement, depth}), span}
        case Ast.TermPlus{head, args, span}: Ast.TermPlus{ checker_scc_run_107(CheckerSccCall_replace_free_term{head, index, replacement, depth}),  checker_scc_run_107(CheckerSccCall_replace_free_terms{args, index, replacement, depth}), span}
        case Ast.TermCtr{key, args, span}: Ast.TermCtr{key,  checker_scc_run_107(CheckerSccCall_replace_free_terms{args, index, replacement, depth}), span}
        case Ast.TermMat{key, head, matched, span}: Ast.TermMat{key,  checker_scc_run_107(CheckerSccCall_replace_free_term{head, index, replacement, depth}),  checker_scc_run_107(CheckerSccCall_replace_free_term{matched, index, replacement, depth}), span}
        case Ast.TermEqual{left, right, ty, span}: Ast.TermEqual{ checker_scc_run_107(CheckerSccCall_replace_free_term{left, index, replacement, depth}),  checker_scc_run_107(CheckerSccCall_replace_free_term{right, index, replacement, depth}),  checker_scc_run_107(CheckerSccCall_replace_free_term{ty, index, replacement, depth}), span}
        case Ast.TermRewrite{equation, proof, body, span}: Ast.TermRewrite{ checker_scc_run_107(CheckerSccCall_replace_free_term{equation, index, replacement, depth}),  checker_scc_run_107(CheckerSccCall_replace_free_term{proof, index, replacement, depth}),  checker_scc_run_107(CheckerSccCall_replace_free_term{body, index, replacement, depth}), span}
        case Ast.BodyMatch{scrutinees, cases, span}: Ast.BodyMatch{ checker_scc_run_107(CheckerSccCall_replace_free_terms{scrutinees, index, replacement, depth}),  checker_scc_run_107(CheckerSccCall_replace_free_cases{cases, index, replacement, depth}), span}
        case Ast.BodyCase{patterns, body, span}: Ast.BodyCase{patterns,  checker_scc_run_107(CheckerSccCall_replace_free_term{body, index, replacement, depth + Core.pattern_list_depth(patterns)}), span}
        case Ast.BodyLocal{patterns, quantity, values, body, span}: Ast.BodyLocal{patterns, quantity,  checker_scc_run_107(CheckerSccCall_replace_free_terms{values, index, replacement, depth}),  checker_scc_run_107(CheckerSccCall_replace_free_term{body, index, replacement, depth + Core.pattern_list_depth(patterns)}), span}
        case Ast.BodyReply{ inner, span}: Ast.BodyReply{ checker_scc_run_107(CheckerSccCall_replace_free_term{inner, index, replacement, depth}), span}
        case _: term


def replace_free_terms(terms: List<&2, Ast.SyntaxTerm>, index: Nat, replacement: Ast.SyntaxTerm, depth: Nat) -> List<&2, Ast.SyntaxTerm>:
  checker_scc_run_107(CheckerSccCall_replace_free_terms{terms, index, replacement, depth})

def replace_free_cases(cases: List<&2, Ast.SyntaxTerm>, index: Nat, replacement: Ast.SyntaxTerm, depth: Nat) -> List<&2, Ast.SyntaxTerm>:
  checker_scc_run_107(CheckerSccCall_replace_free_cases{cases, index, replacement, depth})

def replace_free_term(term: Ast.SyntaxTerm, index: Nat, replacement: Ast.SyntaxTerm, depth: Nat) -> Ast.SyntaxTerm:
  checker_scc_run_107(CheckerSccCall_replace_free_term{term, index, replacement, depth})

def shift_terms(terms: List<&2, Ast.SyntaxTerm>, by: Nat) -> List<&2, Ast.SyntaxTerm>:
  match terms:
    case Nil{}: Nil{}
    case +term <> rest: Core.shift(0n, by, term) <> shift_terms(rest, by)

def replace_match_types(source_index: Maybe<&2, Nat>, added: Nat, types: List<&2, Ast.SyntaxTerm>, value: Ast.SyntaxTerm) -> List<&2, Ast.SyntaxTerm>:
  match source_index:
    case Some{ index}: replace_free_terms(shift_terms(types, added), index + added, value, 0n)
    case None{}: shift_terms(types, added)

def check_pattern_variable_result(valid: Bool, pattern: Ast.SyntaxPattern, key: String, quantity: Ast.Quantity, ty: Ast.SyntaxTerm, final_depth: Nat, env: List<&2, Binding>, span: Ast.SourceSpan) -> PatternTyping:
  Bool.pick(PatternTyping, valid, PatternTyped{ Binding{key, quantity, ty} <> env,  pattern_value(pattern, final_depth)}, PatternTypeFailure{ Diagnostic{ span_file(span), span,  "pattern quantity exceeds constructor field quantity",  "within the field quantity",  "an excessive pattern quantity"}})

def check_pattern_variable_field_quantity(quantity: Maybe<&2, Ast.Quantity>, pattern: Ast.SyntaxPattern, key: String, requested: Ast.Quantity, ty: Ast.SyntaxTerm, final_depth: Nat, env: List<&2, Binding>, span: Ast.SourceSpan) -> PatternTyping:
  match quantity:
    case Some{ allowed}: check_pattern_variable_result(quantity_fits(requested, allowed), pattern, key, requested, ty, final_depth, env, span)
    case None{}: PatternTyped{ Binding{key, requested, ty} <> env,  pattern_value(pattern, final_depth)}

def check_pattern_result_view(view: Ast.SyntaxTerm, key: String, values: List<&2, Ast.SyntaxTerm>, next_env: List<&2, Binding>, ty: Ast.SyntaxTerm, span: Ast.SourceSpan, globals: List<&2, Global>) -> PatternTyping:
  match view:
    case Ast.TermAll{ _,  _,  _,  _,  _,  _}: PatternTypeFailure{ Diagnostic{ span_file(span), span,  "constructor pattern omits fields",  "one pattern per constructor field",  "too few field patterns"}}
    case _: Bool.pick(PatternTyping, fits_term(view, ty, globals), PatternTyped{ next_env,  Ast.TermCtr{ canonical_name(key, globals),  values, span}}, PatternTypeFailure{ Diagnostic{ span_file(span), span,  "constructor parameters do not match scrutinee",  "the scrutinee datatype instance",  "different parameters"}})

def check_pattern_fields_result(result: PatternFields, key: String, ty: Ast.SyntaxTerm, span: Ast.SourceSpan, globals: List<&2, Global>) -> PatternTyping:
  match result:
    case PatternFieldsFailure{diagnostic}: PatternTypeFailure{diagnostic}
    case PatternFieldsTyped{ next_env, values, result}: check_pattern_result_view(whnf(64n, result, globals), key, values, next_env, ty, span, globals)

def check_pattern_fields_empty_view(view: Ast.SyntaxTerm, current: Ast.SyntaxTerm, env: List<&2, Binding>, span: Ast.SourceSpan) -> PatternFields:
  match view:
    case Ast.TermAll{ _,  _,  _,  _,  _,  _}: PatternFieldsFailure{ Diagnostic{ span_file(span), span,  "constructor pattern omits fields",  "one pattern per constructor field",  "too few field patterns"}}
    case _: PatternFieldsTyped{env,  Nil{},  current}

def check_pattern_fields_recursive_result(result: PatternFields, rest: List<&2, Ast.SyntaxPattern>, value: Ast.SyntaxTerm) -> PatternFields:
  match result:
    case PatternFieldsFailure{diagnostic}: PatternFieldsFailure{diagnostic}
    case PatternFieldsTyped{ final_env, values, result}: PatternFieldsTyped{ final_env,  Core.shift(0n, Core.pattern_list_depth(rest), value) <> values, result}

def maybe_quantity_or_one(quantity: Maybe<&2, Ast.Quantity>) -> Ast.Quantity:
  match quantity:
    case Some{value}: value
    case None{}: Ast.QOne{}

type CheckerSccInput117 is Data:
  CheckerSccCall_check_pattern_fields_typed_result{result: PatternTyping, rest: List<&2, Ast.SyntaxPattern>, codomain: Ast.SyntaxTerm, final_depth: Nat, scrutinee_quantity: Ast.Quantity, env: List<&2, Binding>, globals: List<&2, Global>, span: Ast.SourceSpan}
  CheckerSccCall_check_pattern_fields_view{view: Ast.SyntaxTerm, pattern: Ast.SyntaxPattern, rest: List<&2, Ast.SyntaxPattern>, final_depth: Nat, scrutinee_quantity: Ast.Quantity, env: List<&2, Binding>, globals: List<&2, Global>, span: Ast.SourceSpan}
  CheckerSccCall_check_pattern_typed_fields{patterns: List<&2, Ast.SyntaxPattern>, current: Ast.SyntaxTerm, final_depth: Nat, scrutinee_quantity: Ast.Quantity, env: List<&2, Binding>, globals: List<&2, Global>, span: Ast.SourceSpan}
  CheckerSccCall_check_pattern_applied_result{applied: Maybe<&2, Ast.SyntaxTerm>, fields: List<&2, Ast.SyntaxPattern>, field_quantity: Maybe<&2, Ast.Quantity>, key: String, ty: Ast.SyntaxTerm, final_depth: Nat, env: List<&2, Binding>, span: Ast.SourceSpan, globals: List<&2, Global>}
  CheckerSccCall_check_pattern_family_result{found: Maybe<&2, String>, family: String, parameters: List<&2, Ast.SyntaxTerm>, constructor_ty: Ast.SyntaxTerm, fields: List<&2, Ast.SyntaxPattern>, field_quantity: Maybe<&2, Ast.Quantity>, key: String, ty: Ast.SyntaxTerm, final_depth: Nat, env: List<&2, Binding>, span: Ast.SourceSpan, globals: List<&2, Global>}
  CheckerSccCall_check_pattern_global{global: Global, family: String, parameters: List<&2, Ast.SyntaxTerm>, fields: List<&2, Ast.SyntaxPattern>, field_quantity: Maybe<&2, Ast.Quantity>, key: String, ty: Ast.SyntaxTerm, final_depth: Nat, env: List<&2, Binding>, span: Ast.SourceSpan, globals: List<&2, Global>}
  CheckerSccCall_check_pattern_global_result{found: Maybe<&2, Global>, family: String, parameters: List<&2, Ast.SyntaxTerm>, fields: List<&2, Ast.SyntaxPattern>, field_quantity: Maybe<&2, Ast.Quantity>, key: String, ty: Ast.SyntaxTerm, final_depth: Nat, env: List<&2, Binding>, span: Ast.SourceSpan, globals: List<&2, Global>}
  CheckerSccCall_check_pattern_exclusion_result{excluded: Bool, key: String, refs: List<&2, String>, family: String, parameters: List<&2, Ast.SyntaxTerm>, fields: List<&2, Ast.SyntaxPattern>, field_quantity: Maybe<&2, Ast.Quantity>, ty: Ast.SyntaxTerm, final_depth: Nat, env: List<&2, Binding>, span: Ast.SourceSpan, globals: List<&2, Global>}
  CheckerSccCall_check_pattern_typed_view{view: Ast.SyntaxTerm, fields: List<&2, Ast.SyntaxPattern>, field_quantity: Maybe<&2, Ast.Quantity>, key: String, ty: Ast.SyntaxTerm, final_depth: Nat, env: List<&2, Binding>, span: Ast.SourceSpan, globals: List<&2, Global>}
  CheckerSccCall_check_pattern_typed{pattern: Ast.SyntaxPattern, ty: Ast.SyntaxTerm, field_quantity: Maybe<&2, Ast.Quantity>, final_depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>}

def checker_scc_result_117(request: CheckerSccInput117) -> Type:
  match request:
    case CheckerSccCall_check_pattern_fields_typed_result{result, rest, codomain, final_depth, scrutinee_quantity, env, globals, span}: PatternFields
    case CheckerSccCall_check_pattern_fields_view{view, pattern, rest, final_depth, scrutinee_quantity, env, globals, span}: PatternFields
    case CheckerSccCall_check_pattern_typed_fields{patterns, current, final_depth, scrutinee_quantity, env, globals, span}: PatternFields
    case CheckerSccCall_check_pattern_applied_result{applied, fields, field_quantity, key, ty, final_depth, env, span, globals}: PatternTyping
    case CheckerSccCall_check_pattern_family_result{found, family, parameters, constructor_ty, fields, field_quantity, key, ty, final_depth, env, span, globals}: PatternTyping
    case CheckerSccCall_check_pattern_global{global, family, parameters, fields, field_quantity, key, ty, final_depth, env, span, globals}: PatternTyping
    case CheckerSccCall_check_pattern_global_result{found, family, parameters, fields, field_quantity, key, ty, final_depth, env, span, globals}: PatternTyping
    case CheckerSccCall_check_pattern_exclusion_result{excluded, key, refs, family, parameters, fields, field_quantity, ty, final_depth, env, span, globals}: PatternTyping
    case CheckerSccCall_check_pattern_typed_view{view, fields, field_quantity, key, ty, final_depth, env, span, globals}: PatternTyping
    case CheckerSccCall_check_pattern_typed{pattern, ty, field_quantity, final_depth, env, globals}: PatternTyping

def checker_scc_run_117(request: CheckerSccInput117) -> checker_scc_result_117(request):
  match request:
    case CheckerSccCall_check_pattern_fields_typed_result{result, rest, codomain, final_depth, scrutinee_quantity, env, globals, span}:
      match result:
        case PatternTypeFailure{diagnostic}: PatternFieldsFailure{diagnostic}
        case PatternTyped{ next_env, value}: check_pattern_fields_recursive_result(checker_scc_run_117(CheckerSccCall_check_pattern_typed_fields{rest, Core.subst(0n, value, codomain), final_depth, scrutinee_quantity, next_env, globals, span}), rest, value)

    case CheckerSccCall_check_pattern_fields_view{view, pattern, rest, final_depth, scrutinee_quantity, env, globals, span}:
      match view:
        case Ast.TermAll{quantity,  _,  _,  domain,  codomain,  _}:
          pattern_depth = List.length(&2, Binding, env) + Core.pattern_depth(pattern)
          field_demand = constructor_field_demand(scrutinee_quantity, quantity)
          checker_scc_run_117(CheckerSccCall_check_pattern_fields_typed_result{checker_scc_run_117(CheckerSccCall_check_pattern_typed{pattern, domain, Some{field_demand}, pattern_depth, env, globals}), rest, codomain, final_depth, scrutinee_quantity, env, globals, span})
        case _: PatternFieldsFailure{ Diagnostic{ span_file(span), span,  "constructor pattern has too many fields",  "a remaining constructor field",  "an extra field pattern"}}

    case CheckerSccCall_check_pattern_typed_fields{patterns, current, final_depth, scrutinee_quantity, env, globals, span}:
      match patterns:
        case Nil{}: check_pattern_fields_empty_view(whnf(64n, current, globals), current, env, span)
        case +pattern <> rest: checker_scc_run_117(CheckerSccCall_check_pattern_fields_view{whnf(64n, current, globals), pattern, rest, final_depth, scrutinee_quantity, env, globals, span})

    case CheckerSccCall_check_pattern_applied_result{applied, fields, field_quantity, key, ty, final_depth, env, span, globals}:
      match applied:
        case None{}: PatternTypeFailure{ Diagnostic{ span_file(span), span,  "constructor parameters do not match datatype",  "matching family parameters",  "an incompatible constructor"}}
        case Some{field_ty}: check_pattern_fields_result(checker_scc_run_117(CheckerSccCall_check_pattern_typed_fields{fields, field_ty, final_depth, maybe_quantity_or_one(field_quantity), env, globals, span}), key, ty, span, globals)

    case CheckerSccCall_check_pattern_family_result{found, family, parameters, constructor_ty, fields, field_quantity, key, ty, final_depth, env, span, globals}:
      match found:
        case None{}: PatternTypeFailure{ Diagnostic{ span_file(span), span,  "match pattern is not a constructor",  "a datatype constructor",  key}}
        case Some{found_family}:
          Bool.pick(PatternTyping, family_equal(found_family, family, globals), checker_scc_run_117(CheckerSccCall_check_pattern_applied_result{apply_prefix(parameters, constructor_ty), fields, field_quantity, key, ty, final_depth, env, span, globals}), PatternTypeFailure{ Diagnostic{ span_file(span), span,  "match constructor belongs to another datatype",  family,  found_family}})

    case CheckerSccCall_check_pattern_global{global, family, parameters, fields, field_quantity, key, ty, final_depth, env, span, globals}:
      match global:
        case Global{ _,  _,  _,  constructor_ty,  _,  _}: checker_scc_run_117(CheckerSccCall_check_pattern_family_result{constructor_family(constructor_ty, globals), family, parameters, constructor_ty, fields, field_quantity, key, ty, final_depth, env, span, globals})

    case CheckerSccCall_check_pattern_global_result{found, family, parameters, fields, field_quantity, key, ty, final_depth, env, span, globals}:
      match found:
        case None{}: PatternTypeFailure{ Diagnostic{ span_file(span), span,  String.append("unknown constructor ", key),  "a declared constructor",  key}}
        case Some{global}: checker_scc_run_117(CheckerSccCall_check_pattern_global{global, family, parameters, fields, field_quantity, key, ty, final_depth, env, span, globals})

    case CheckerSccCall_check_pattern_exclusion_result{excluded, key, refs, family, parameters, fields, field_quantity, ty, final_depth, env, span, globals}:
      Bool.pick(PatternTyping, excluded, PatternTypeFailure{ Diagnostic{ span_file(span), span,  "constructor is excluded from this datatype goal",  "a remaining constructor",  key}}, checker_scc_run_117(CheckerSccCall_check_pattern_global_result{lookup_global(key, globals), family, parameters, fields, field_quantity, key, ty, final_depth, env, span, globals}))

    case CheckerSccCall_check_pattern_typed_view{view, fields, field_quantity, key, ty, final_depth, env, span, globals}:
      match view:
        case Ast.TermAdt{ family,  parameters, refs,  _}: checker_scc_run_117(CheckerSccCall_check_pattern_exclusion_result{has_canonical_name(key, refs, globals), key, refs, family, parameters, fields, field_quantity, ty, final_depth, env, span, globals})
        case _: PatternTypeFailure{ Diagnostic{ span_file(span), span,  "match scrutinee is not a datatype",  "a datatype",  "a non-datatype"}}

    case CheckerSccCall_check_pattern_typed{pattern, ty, field_quantity, final_depth, env, globals}:
      match pattern:
        case Ast.PatternVar{key,  _, quantity, span}: check_pattern_variable_field_quantity(field_quantity, pattern, key, quantity, ty, final_depth, env, span)
        case Ast.PatternCtr{key, fields, span}: checker_scc_run_117(CheckerSccCall_check_pattern_typed_view{whnf(64n, ty, globals), fields, field_quantity, key, ty, final_depth, env, span, globals})


def check_pattern_fields_typed_result(result: PatternTyping, rest: List<&2, Ast.SyntaxPattern>, codomain: Ast.SyntaxTerm, final_depth: Nat, scrutinee_quantity: Ast.Quantity, env: List<&2, Binding>, globals: List<&2, Global>, span: Ast.SourceSpan) -> PatternFields:
  checker_scc_run_117(CheckerSccCall_check_pattern_fields_typed_result{result, rest, codomain, final_depth, scrutinee_quantity, env, globals, span})

def check_pattern_fields_view(view: Ast.SyntaxTerm, pattern: Ast.SyntaxPattern, rest: List<&2, Ast.SyntaxPattern>, final_depth: Nat, scrutinee_quantity: Ast.Quantity, env: List<&2, Binding>, globals: List<&2, Global>, span: Ast.SourceSpan) -> PatternFields:
  checker_scc_run_117(CheckerSccCall_check_pattern_fields_view{view, pattern, rest, final_depth, scrutinee_quantity, env, globals, span})

def check_pattern_typed_fields(patterns: List<&2, Ast.SyntaxPattern>, current: Ast.SyntaxTerm, final_depth: Nat, scrutinee_quantity: Ast.Quantity, env: List<&2, Binding>, globals: List<&2, Global>, span: Ast.SourceSpan) -> PatternFields:
  checker_scc_run_117(CheckerSccCall_check_pattern_typed_fields{patterns, current, final_depth, scrutinee_quantity, env, globals, span})

def check_pattern_applied_result(applied: Maybe<&2, Ast.SyntaxTerm>, fields: List<&2, Ast.SyntaxPattern>, field_quantity: Maybe<&2, Ast.Quantity>, key: String, ty: Ast.SyntaxTerm, final_depth: Nat, env: List<&2, Binding>, span: Ast.SourceSpan, globals: List<&2, Global>) -> PatternTyping:
  checker_scc_run_117(CheckerSccCall_check_pattern_applied_result{applied, fields, field_quantity, key, ty, final_depth, env, span, globals})

def check_pattern_family_result(found: Maybe<&2, String>, family: String, parameters: List<&2, Ast.SyntaxTerm>, constructor_ty: Ast.SyntaxTerm, fields: List<&2, Ast.SyntaxPattern>, field_quantity: Maybe<&2, Ast.Quantity>, key: String, ty: Ast.SyntaxTerm, final_depth: Nat, env: List<&2, Binding>, span: Ast.SourceSpan, globals: List<&2, Global>) -> PatternTyping:
  checker_scc_run_117(CheckerSccCall_check_pattern_family_result{found, family, parameters, constructor_ty, fields, field_quantity, key, ty, final_depth, env, span, globals})

def check_pattern_global(global: Global, family: String, parameters: List<&2, Ast.SyntaxTerm>, fields: List<&2, Ast.SyntaxPattern>, field_quantity: Maybe<&2, Ast.Quantity>, key: String, ty: Ast.SyntaxTerm, final_depth: Nat, env: List<&2, Binding>, span: Ast.SourceSpan, globals: List<&2, Global>) -> PatternTyping:
  checker_scc_run_117(CheckerSccCall_check_pattern_global{global, family, parameters, fields, field_quantity, key, ty, final_depth, env, span, globals})

def check_pattern_global_result(found: Maybe<&2, Global>, family: String, parameters: List<&2, Ast.SyntaxTerm>, fields: List<&2, Ast.SyntaxPattern>, field_quantity: Maybe<&2, Ast.Quantity>, key: String, ty: Ast.SyntaxTerm, final_depth: Nat, env: List<&2, Binding>, span: Ast.SourceSpan, globals: List<&2, Global>) -> PatternTyping:
  checker_scc_run_117(CheckerSccCall_check_pattern_global_result{found, family, parameters, fields, field_quantity, key, ty, final_depth, env, span, globals})

def check_pattern_exclusion_result(excluded: Bool, key: String, refs: List<&2, String>, family: String, parameters: List<&2, Ast.SyntaxTerm>, fields: List<&2, Ast.SyntaxPattern>, field_quantity: Maybe<&2, Ast.Quantity>, ty: Ast.SyntaxTerm, final_depth: Nat, env: List<&2, Binding>, span: Ast.SourceSpan, globals: List<&2, Global>) -> PatternTyping:
  checker_scc_run_117(CheckerSccCall_check_pattern_exclusion_result{excluded, key, refs, family, parameters, fields, field_quantity, ty, final_depth, env, span, globals})

def check_pattern_typed_view(view: Ast.SyntaxTerm, fields: List<&2, Ast.SyntaxPattern>, field_quantity: Maybe<&2, Ast.Quantity>, key: String, ty: Ast.SyntaxTerm, final_depth: Nat, env: List<&2, Binding>, span: Ast.SourceSpan, globals: List<&2, Global>) -> PatternTyping:
  checker_scc_run_117(CheckerSccCall_check_pattern_typed_view{view, fields, field_quantity, key, ty, final_depth, env, span, globals})

def check_pattern_typed(pattern: Ast.SyntaxPattern, ty: Ast.SyntaxTerm, field_quantity: Maybe<&2, Ast.Quantity>, final_depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>) -> PatternTyping:
  checker_scc_run_117(CheckerSccCall_check_pattern_typed{pattern, ty, field_quantity, final_depth, env, globals})

type CheckerSccInput118 is Data:
  CheckerSccCall_usage_pattern_env_result{result: PatternTyping, pattern: Ast.SyntaxPattern, pattern_rest: List<&2, Ast.SyntaxPattern>, type_rest: List<&2, Ast.SyntaxTerm>, scrutinee_rest: List<&2, Ast.SyntaxTerm>, env: List<&2, Binding>, globals: List<&2, Global>, remaining: Nat, offset: Nat, added: Nat, source_index: Nat}
  CheckerSccCall_usage_pattern_env{patterns: List<&2, Ast.SyntaxPattern>, types: List<&2, Ast.SyntaxTerm>, scrutinees: List<&2, Ast.SyntaxTerm>, env: List<&2, Binding>, globals: List<&2, Global>, remaining: Nat, offset: Nat}

def checker_scc_result_118(request: CheckerSccInput118) -> Type:
  match request:
    case CheckerSccCall_usage_pattern_env_result{result, pattern, pattern_rest, type_rest, scrutinee_rest, env, globals, remaining, offset, added, source_index}: List<&2, Binding>
    case CheckerSccCall_usage_pattern_env{patterns, types, scrutinees, env, globals, remaining, offset}: List<&2, Binding>

def checker_scc_run_118(request: CheckerSccInput118) -> checker_scc_result_118(request):
  match request:
    case CheckerSccCall_usage_pattern_env_result{result, pattern, pattern_rest, type_rest, scrutinee_rest, env, globals, remaining, offset, added, source_index}:
      match result:
        case PatternTypeFailure{ _}: env
        case PatternTyped{ next_env,  _}:
          branch_value = pattern_value(pattern, List.length(&2, Binding, env) + remaining)
          branch_types = replace_match_types(source_index, added, type_rest, branch_value)
          checker_scc_run_118(CheckerSccCall_usage_pattern_env{pattern_rest, branch_types, scrutinee_rest, next_env, globals, remaining - added, offset + added})

    case CheckerSccCall_usage_pattern_env{patterns, types, scrutinees, env, globals, remaining, offset}:
      match patterns types scrutinees:
        case Nil{} Nil{} Nil{}: env
        case +pattern <> pattern_rest +ty <> type_rest +scrutinee <> scrutinee_rest:
          added = Core.pattern_depth(pattern)
          source_index = maybe_shift_index(scrutinee_variable_index(scrutinee, globals), offset)
          field_quantity = Some{optional_source_quantity(source_index, env)}
          checker_scc_run_118(CheckerSccCall_usage_pattern_env_result{check_pattern_typed(pattern, ty, field_quantity, List.length(&2, Binding, env) + remaining, env, globals), pattern, pattern_rest, type_rest, scrutinee_rest, env, globals, remaining, offset, added, source_index})
        case _ _ _: env


def usage_pattern_env_result(result: PatternTyping, pattern: Ast.SyntaxPattern, pattern_rest: List<&2, Ast.SyntaxPattern>, type_rest: List<&2, Ast.SyntaxTerm>, scrutinee_rest: List<&2, Ast.SyntaxTerm>, env: List<&2, Binding>, globals: List<&2, Global>, remaining: Nat, offset: Nat, added: Nat, source_index: Nat) -> List<&2, Binding>:
  checker_scc_run_118(CheckerSccCall_usage_pattern_env_result{result, pattern, pattern_rest, type_rest, scrutinee_rest, env, globals, remaining, offset, added, source_index})

def usage_pattern_env(patterns: List<&2, Ast.SyntaxPattern>, types: List<&2, Ast.SyntaxTerm>, scrutinees: List<&2, Ast.SyntaxTerm>, env: List<&2, Binding>, globals: List<&2, Global>, remaining: Nat, offset: Nat) -> List<&2, Binding>:
  checker_scc_run_118(CheckerSccCall_usage_pattern_env{patterns, types, scrutinees, env, globals, remaining, offset})

def replace_match_expected(source_index: Maybe<&2, Nat>, added: Nat, expected: Ast.SyntaxTerm, value: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  match source_index:
    case Some{ index}: replace_free_term(Core.shift(0n, added, expected), index + added, value, 0n)
    case None{}: Core.shift(0n, added, expected)

def usage_expected_known(patterns: List<&2, Ast.SyntaxPattern>, scrutinees: List<&2, Ast.SyntaxTerm>, expected_ty: Ast.SyntaxTerm, env_size: Nat, total_depth: Nat, offset: Nat, globals: List<&2, Global>) -> Maybe<&2, Ast.SyntaxTerm>:
  match patterns scrutinees:
    case Nil{} Nil{}: Some{expected_ty}
    case +pattern <> pattern_rest +scrutinee <> scrutinee_rest:
      added = Core.pattern_depth(pattern)
      source_index = maybe_shift_index(scrutinee_variable_index(scrutinee, globals), offset)
      branch_value = pattern_value(pattern, env_size + total_depth)
      next_expected = replace_match_expected(source_index, added, expected_ty, branch_value)
      usage_expected_known(pattern_rest, scrutinee_rest, next_expected, env_size, total_depth, offset + added, globals)
    case _ _: Some{expected_ty}

def usage_expected_patterns(patterns: List<&2, Ast.SyntaxPattern>, scrutinees: List<&2, Ast.SyntaxTerm>, expected: Maybe<&2, Ast.SyntaxTerm>, env_size: Nat, total_depth: Nat, offset: Nat, globals: List<&2, Global>) -> Maybe<&2, Ast.SyntaxTerm>:
  match expected:
    case None{}: None{}
    case Some{expected_ty}: usage_expected_known(patterns, scrutinees, expected_ty, env_size, total_depth, offset, globals)

def infer_scrutinee_types_rest(result: ScrutineeTyping, ty: Ast.SyntaxTerm) -> ScrutineeTyping:
  match result:
    case ScrutineeTypes{types}: ScrutineeTypes{ ty <> types}
    case ScrutineeTypeFailure{diagnostic}: ScrutineeTypeFailure{diagnostic}

def lambda_domain_valid_result(result: Inference, span: Ast.SourceSpan, globals: List<&2, Global>) -> Bool:
  match result:
    case Inferred{ _,  domain_kind}: fits_term(domain_kind, Ast.TermType{ Ast.TermQuantity{ Ast.QMany{}, span}, span}, globals)
    case InferenceFailure{ _}: False{}
def lambda_promotes(annotated: Maybe<&2, Ast.Quantity>, expected: Ast.Quantity) -> Bool:
  match annotated expected:
    case Some{ Ast.QMany{}} Ast.QOne{}: True{}
    case _ _: False{}

def check_ctr_fields_fit(valid: Bool, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, span: Ast.SourceSpan) -> Inference:
  Bool.pick(Inference, valid, Inferred{ whole,  expected}, fail(span, "constructor result does not match expected datatype", "the expected datatype", "a different result type"))

def check_ctr_fields_result(result: Inference, whole: Ast.SyntaxTerm) -> Inference:
  match result:
    case Inferred{ _,  result_ty}: Inferred{ whole,  result_ty}
    case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}

def mat_branch_goal_view(view: Ast.SyntaxTerm, codomain: Ast.SyntaxTerm, key: String, args: List<&2, Ast.SyntaxTerm>, depth: Nat, span: Ast.SourceSpan, globals: List<&2, Global>) -> Ast.SyntaxTerm:
  match view:
    case Ast.TermAll{quantity,  field_key, index, ty, body,  binder_span}:
      next_args = Ast.TermVar{ field_key,  0n, span} <> shift_terms(args, 1n)
      next_body = mat_branch_goal_view(whnf(64n, body, globals), Core.shift(0n, 1n, codomain), key, next_args, depth + 1n, span, globals)
      Ast.TermAll{quantity,  field_key, index, ty, next_body,  binder_span}
    case _:
      ctr = Ast.TermCtr{key, args, span}
      Core.subst(depth, ctr, codomain)

def mat_branch_goal(field_ty: Ast.SyntaxTerm, codomain: Ast.SyntaxTerm, key: String, args: List<&2, Ast.SyntaxTerm>, depth: Nat, span: Ast.SourceSpan, globals: List<&2, Global>) -> Ast.SyntaxTerm:
  mat_branch_goal_view(whnf(64n, field_ty, globals), codomain, key, args, depth, span, globals)

def check_match_default_result(result: Inference, whole: Ast.SyntaxTerm, expected: Ast.SyntaxTerm) -> Inference:
  match result:
    case Inferred{ _,  _}: Inferred{ whole,  expected}
    case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}

def check_term_absurd_residual(has_reachable: Bool, term: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm) -> Inference:
  Bool.pick(Inference, has_reachable, fail(span, "match is not exhaustive", "all remaining constructors", "an uncovered constructor"), Inferred{term,  expected})

type CheckerSccInput131 is Data:
  CheckerSccCall_index_terms_compatible_view{a: Ast.SyntaxTerm, b: Ast.SyntaxTerm, globals: List<&2, Global>}
  CheckerSccCall_index_terms_compatible{left: Ast.SyntaxTerm, right: Ast.SyntaxTerm, globals: List<&2, Global>}
  CheckerSccCall_index_term_lists_compatible{left: List<&2, Ast.SyntaxTerm>, right: List<&2, Ast.SyntaxTerm>, globals: List<&2, Global>}

def checker_scc_result_131(request: CheckerSccInput131) -> Type:
  match request:
    case CheckerSccCall_index_terms_compatible_view{a, b, globals}: Bool
    case CheckerSccCall_index_terms_compatible{left, right, globals}: Bool
    case CheckerSccCall_index_term_lists_compatible{left, right, globals}: Bool

def checker_scc_run_131(request: CheckerSccInput131) -> checker_scc_result_131(request):
  match request:
    case CheckerSccCall_index_terms_compatible_view{a, b, globals}:
      match a b:
        case Ast.TermVar{ _,  _,  _} _: True{}
        case _ Ast.TermVar{ _,  _,  _}: True{}
        case Ast.TermHole{ _,  _} _: True{}
        case _ Ast.TermHole{ _,  _}: True{}
        case Ast.TermCtr{ left_key,  left_args,  _} Ast.TermCtr{ right_key,  right_args,  _}:
          Bool.and(String.eq(left_key, right_key), Bool.and(Nat.is_eq(List.length(&2, Ast.SyntaxTerm, left_args), List.length(&2, Ast.SyntaxTerm, right_args)), checker_scc_run_131(CheckerSccCall_index_term_lists_compatible{left_args, right_args, globals})))
        case Ast.TermAdt{ left_key,  left_args,  _,  _} Ast.TermAdt{ right_key,  right_args,  _,  _}:
          Bool.and(family_equal(left_key, right_key, globals), Bool.and(Nat.is_eq(List.length(&2, Ast.SyntaxTerm, left_args), List.length(&2, Ast.SyntaxTerm, right_args)), checker_scc_run_131(CheckerSccCall_index_term_lists_compatible{left_args, right_args, globals})))
        case _ _: True{}

    case CheckerSccCall_index_terms_compatible{left, right, globals}:
      Bool.or(equal_term(left, right, globals), checker_scc_run_131(CheckerSccCall_index_terms_compatible_view{whnf(64n, left, globals), whnf(64n, right, globals), globals}))

    case CheckerSccCall_index_term_lists_compatible{left, right, globals}:
      match left right:
        case Nil{} Nil{}: True{}
        case +left_term <> left_rest +right_term <> right_rest:
          Bool.pick(Bool, checker_scc_run_131(CheckerSccCall_index_terms_compatible{left_term, right_term, globals}), checker_scc_run_131(CheckerSccCall_index_term_lists_compatible{left_rest, right_rest, globals}), False{})
        case _ _: False{}


def index_terms_compatible_view(a: Ast.SyntaxTerm, b: Ast.SyntaxTerm, globals: List<&2, Global>) -> Bool:
  checker_scc_run_131(CheckerSccCall_index_terms_compatible_view{a, b, globals})

def index_terms_compatible(left: Ast.SyntaxTerm, right: Ast.SyntaxTerm, globals: List<&2, Global>) -> Bool:
  checker_scc_run_131(CheckerSccCall_index_terms_compatible{left, right, globals})

def index_term_lists_compatible(left: List<&2, Ast.SyntaxTerm>, right: List<&2, Ast.SyntaxTerm>, globals: List<&2, Global>) -> Bool:
  checker_scc_run_131(CheckerSccCall_index_term_lists_compatible{left, right, globals})

def constructor_result_term(result: Ast.SyntaxTerm, expected_family: String, expected_args: List<&2, Ast.SyntaxTerm>, globals: List<&2, Global>) -> Bool:
  match result:
    case Ast.TermAll{ _,  _,  _,  _,  _,  _}: True{}
    case Ast.TermAdt{ result_family,  result_args,  _,  _}: Bool.and(family_equal(result_family, expected_family, globals), index_term_lists_compatible(result_args, expected_args, globals))
    case _: True{}

def constructor_result_applied(applied: Maybe<&2, Ast.SyntaxTerm>, expected_family: String, expected_args: List<&2, Ast.SyntaxTerm>, globals: List<&2, Global>) -> Bool:
  match applied:
    case None{}: False{}
    case Some{result}: constructor_result_term(whnf(64n, result, globals), expected_family, expected_args, globals)

def constructor_result_global(global: Global, expected_family: String, expected_args: List<&2, Ast.SyntaxTerm>, globals: List<&2, Global>) -> Bool:
  match global:
    case Global{ _,  _,  _,  constructor_ty,  _,  _}: constructor_result_applied(apply_prefix(expected_args, constructor_ty), expected_family, expected_args, globals)

def constructor_result_lookup(found: Maybe<&2, Global>, expected_family: String, expected_args: List<&2, Ast.SyntaxTerm>, globals: List<&2, Global>) -> Bool:
  match found:
    case None{}: False{}
    case Some{global}: constructor_result_global(global, expected_family, expected_args, globals)

def constructor_result_view(view: Ast.SyntaxTerm, constructor: String, globals: List<&2, Global>) -> Bool:
  match view:
    case Ast.TermAdt{ expected_family,  expected_args,  _,  _}: constructor_result_lookup(lookup_global(constructor, globals), expected_family, expected_args, globals)
    case _: False{}

def constructor_result_possible(ty: Ast.SyntaxTerm, constructor: String, globals: List<&2, Global>) -> Bool:
  constructor_result_view(whnf(64n, ty, globals), constructor, globals)


def constructor_pattern_reachable_result(result: PatternTyping, ty: Ast.SyntaxTerm, constructor: String, globals: List<&2, Global>) -> Bool:
  match result:
    case PatternTyped{ _,  _}: True{}
    case PatternTypeFailure{ _}: constructor_result_possible(ty, constructor, globals)

def constructor_pattern_reachable(ty: Ast.SyntaxTerm, constructor: String, globals: List<&2, Global>) -> Bool:
  span = Ast.SpanOf{ "",  0n,  0n}
  pattern = Ast.PatternCtr{ constructor,  Nil{}, span}
  constructor_pattern_reachable_result(check_pattern_typed(pattern, ty, Some{Ast.QOne{}}, 0n, Nil{}, globals), ty, constructor, globals)
type CheckerSccInput140 is Data:
  CheckerSccCall_filter_reachable_result{reachable: Bool, constructor: String, rest: List<&2, String>, ty: Ast.SyntaxTerm, globals: List<&2, Global>}
  CheckerSccCall_filter_reachable_constructors{constructors: List<&2, String>, ty: Ast.SyntaxTerm, globals: List<&2, Global>}

def checker_scc_result_140(request: CheckerSccInput140) -> Type:
  match request:
    case CheckerSccCall_filter_reachable_result{reachable, constructor, rest, ty, globals}: List<&2, String>
    case CheckerSccCall_filter_reachable_constructors{constructors, ty, globals}: List<&2, String>

def checker_scc_run_140(request: CheckerSccInput140) -> checker_scc_result_140(request):
  match request:
    case CheckerSccCall_filter_reachable_result{reachable, constructor, rest, ty, globals}:
      match reachable:
        case True{}: constructor <> checker_scc_run_140(CheckerSccCall_filter_reachable_constructors{rest, ty, globals})
        case False{}: checker_scc_run_140(CheckerSccCall_filter_reachable_constructors{rest, ty, globals})

    case CheckerSccCall_filter_reachable_constructors{constructors, ty, globals}:
      match constructors:
        case Nil{}: Nil{}
        case +constructor <> rest: checker_scc_run_140(CheckerSccCall_filter_reachable_result{constructor_pattern_reachable(ty, constructor, globals), constructor, rest, ty, globals})


def filter_reachable_result(reachable: Bool, constructor: String, rest: List<&2, String>, ty: Ast.SyntaxTerm, globals: List<&2, Global>) -> List<&2, String>:
  checker_scc_run_140(CheckerSccCall_filter_reachable_result{reachable, constructor, rest, ty, globals})

def filter_reachable_constructors(constructors: List<&2, String>, ty: Ast.SyntaxTerm, globals: List<&2, Global>) -> List<&2, String>:
  checker_scc_run_140(CheckerSccCall_filter_reachable_constructors{constructors, ty, globals})

type CheckerSccInput141 is Data:
  CheckerSccCall_family_constructor_keys_for_type{found: Maybe<&2, String>, key: String, rest: List<&2, Global>, family: String, refs: List<&2, String>, acc: List<&2, String>, globals: List<&2, Global>}
  CheckerSccCall_family_constructor_keys_inner{globals: List<&2, Global>, family: String, refs: List<&2, String>, acc: List<&2, String>}

def checker_scc_result_141(request: CheckerSccInput141) -> Type:
  match request:
    case CheckerSccCall_family_constructor_keys_for_type{found, key, rest, family, refs, acc, globals}: List<&2, String>
    case CheckerSccCall_family_constructor_keys_inner{globals, family, refs, acc}: List<&2, String>

def checker_scc_run_141(request: CheckerSccInput141) -> checker_scc_result_141(request):
  match request:
    case CheckerSccCall_family_constructor_keys_for_type{found, key, rest, family, refs, acc, globals}:
      match found:
        case Some{found_family}:
          canonical = canonical_name(key, globals)
          include = Bool.not(Bool.or(has_canonical_name(canonical, refs, globals), has_canonical_name(canonical, acc, globals)))
          next_acc = Bool.pick(List<&2, String>, family_equal(found_family, family, globals), Bool.pick(List<&2, String>, include, canonical <> acc, acc), acc)
          checker_scc_run_141(CheckerSccCall_family_constructor_keys_inner{rest, family, refs, next_acc})
        case None{}: checker_scc_run_141(CheckerSccCall_family_constructor_keys_inner{rest, family, refs, acc})

    case CheckerSccCall_family_constructor_keys_inner{globals, family, refs, acc}:
      match globals:
        case Nil{}: List.reverse(&2, String, acc)
        case +global <> rest:
          match global:
            case Global{key,  _,  _, ty,  Ast.NoTerm{},  _}: checker_scc_run_141(CheckerSccCall_family_constructor_keys_for_type{constructor_family(ty, globals), key, rest, family, refs, acc, globals})
            case _: checker_scc_run_141(CheckerSccCall_family_constructor_keys_inner{rest, family, refs, acc})


def family_constructor_keys_for_type(found: Maybe<&2, String>, key: String, rest: List<&2, Global>, family: String, refs: List<&2, String>, acc: List<&2, String>, globals: List<&2, Global>) -> List<&2, String>:
  checker_scc_run_141(CheckerSccCall_family_constructor_keys_for_type{found, key, rest, family, refs, acc, globals})

def family_constructor_keys_inner(globals: List<&2, Global>, family: String, refs: List<&2, String>, acc: List<&2, String>) -> List<&2, String>:
  checker_scc_run_141(CheckerSccCall_family_constructor_keys_inner{globals, family, refs, acc})

def family_constructor_keys(globals: List<&2, Global>, family: String, refs: List<&2, String>) -> List<&2, String>:
  family_constructor_keys_inner(globals, family, refs, Nil{})

def constructors_for_type_view(view: Ast.SyntaxTerm, ty: Ast.SyntaxTerm, globals: List<&2, Global>) -> List<&2, String>:
  match view:
    case Ast.TermAdt{key,  _, refs,  _}:
      family = resolve_family_key(key, globals)
      filter_reachable_constructors(family_constructor_keys(globals, family, refs), ty, globals)
    case _: Nil{}

def constructors_for_type(ty: Ast.SyntaxTerm, globals: List<&2, Global>) -> List<&2, String>:
  constructors_for_type_view(whnf(64n, ty, globals), ty, globals)

def residual_has_reachable_constructor(family: String, parameters: List<&2, Ast.SyntaxTerm>, refs: List<&2, String>, span: Ast.SourceSpan, globals: List<&2, Global>) -> Bool:
  ty = Ast.TermAdt{ family,  parameters, refs, span}
  Bool.not(List.is_empty(&2, String, constructors_for_type(ty, globals)))

def check_term_absurd_input_view(view: Ast.SyntaxTerm, term: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, globals: List<&2, Global>) -> Inference:
  match view:
    case Ast.TermAdt{ family, args, refs,  adt_span}: check_term_absurd_residual(residual_has_reachable_constructor(resolve_family_key(family, globals), args, refs, adt_span, globals), term, span, expected)
    case _: fail(span, "absurd match requires a datatype", "a datatype", "a non-datatype")

def check_term_absurd_view(view: Ast.SyntaxTerm, term: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, globals: List<&2, Global>) -> Inference:
  match view:
    case Ast.TermAll{ _,  _,  _,  input_ty,  _,  _}: check_term_absurd_input_view(whnf(64n, input_ty, globals), term, span, expected, globals)
    case _: fail(span, "absurd match requires a function goal", "a dependent function type", "a non-function type")

def check_term_refl_equal(equal: Bool, term: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm) -> Inference:
  Bool.pick(Inference, equal, Inferred{term,  expected}, fail(span, "refl endpoints are not convertible", "equal endpoints", "unequal endpoints"))

def check_term_refl_view(view: Ast.SyntaxTerm, term: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, globals: List<&2, Global>) -> Inference:
  match view:
    case Ast.TermEqual{left, right,  _,  _}: check_term_refl_equal(equal_term(left, right, globals), term, span, expected)
    case _: fail(span, "refl requires an equation type", "an equation type", "a non-equation")

def rewrite_body_result(result: Inference, whole: Ast.SyntaxTerm, expected: Ast.SyntaxTerm) -> Inference:
  match result:
    case Inferred{ _,  _}: Inferred{ whole,  expected}
    case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}

def check_body_matrix_result(covers: Bool, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm) -> Inference:
  Bool.pick(Inference, covers, Inferred{ whole,  expected}, fail(span, "match is not exhaustive", "all nested constructor cases", "an uncovered nested constructor"))

def all_variable_patterns(patterns: List<&2, Ast.SyntaxPattern>) -> Bool:
  match patterns:
    case Nil{}: True{}
    case +pattern <> rest:
      match pattern:
        case Ast.PatternVar{ _,  _,  _,  _}: all_variable_patterns(rest)
        case _: False{}

def collect_constructor_field_types_view(view: Ast.SyntaxTerm, span: Ast.SourceSpan, globals: List<&2, Global>, depth: Nat) -> List<&2, Ast.SyntaxTerm>:
  match view:
    case Ast.TermAll{ _, key,  _,  domain, body,  _}:
      neutral = Ast.TermVar{key,  depth, span}
      next = Core.subst(0n, neutral, body)
      domain <> collect_constructor_field_types_view(whnf(64n, next, globals), span, globals, depth + 1n)
    case _: Nil{}

def collect_constructor_field_types(current: Ast.SyntaxTerm, span: Ast.SourceSpan, globals: List<&2, Global>, depth: Nat) -> List<&2, Ast.SyntaxTerm>:
  collect_constructor_field_types_view(whnf(64n, current, globals), span, globals, depth)

def constructor_field_types_applied(applied: Maybe<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, globals: List<&2, Global>) -> List<&2, Ast.SyntaxTerm>:
  match applied:
    case Some{field_ty}: collect_constructor_field_types(field_ty, span, globals, 0n)
    case None{}: Nil{}

def constructor_field_types_family(found: Maybe<&2, String>, family: String, parameters: List<&2, Ast.SyntaxTerm>, constructor_ty: Ast.SyntaxTerm, span: Ast.SourceSpan, globals: List<&2, Global>) -> List<&2, Ast.SyntaxTerm>:
  match found:
    case None{}: Nil{}
    case Some{found_family}:
      Bool.pick(List<&2, Ast.SyntaxTerm>, family_equal(found_family, family, globals), constructor_field_types_applied(apply_prefix(parameters, constructor_ty), span, globals), Nil{})

def constructor_field_types_global(global: Global, family: String, parameters: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, globals: List<&2, Global>) -> List<&2, Ast.SyntaxTerm>:
  match global:
    case Global{ _,  _,  _,  constructor_ty,  _,  _}: constructor_field_types_family(constructor_family(constructor_ty, globals), family, parameters, constructor_ty, span, globals)

def constructor_field_types_lookup(found: Maybe<&2, Global>, family: String, parameters: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, globals: List<&2, Global>) -> List<&2, Ast.SyntaxTerm>:
  match found:
    case None{}: Nil{}
    case Some{global}: constructor_field_types_global(global, family, parameters, span, globals)

def constructor_field_types_view(view: Ast.SyntaxTerm, constructor: String, ty: Ast.SyntaxTerm, globals: List<&2, Global>) -> List<&2, Ast.SyntaxTerm>:
  match view:
    case Ast.TermAdt{ family,  parameters,  _, span}: constructor_field_types_lookup(lookup_global(constructor, globals), family, parameters, span, globals)
    case _: Nil{}

def constructor_field_types_for_type(ty: Ast.SyntaxTerm, constructor: String, globals: List<&2, Global>) -> List<&2, Ast.SyntaxTerm>:
  constructor_field_types_view(whnf(64n, ty, globals), constructor, ty, globals)

def wildcard_patterns(count: Nat, span: Ast.SourceSpan) -> List<&2, Ast.SyntaxPattern>:
  match count:
    case 0n: Nil{}
    case 1n+rest: Ast.PatternVar{ "",  0n,  Ast.QZero{}, span} <> wildcard_patterns(rest, span)

def specialize_pattern_rows(rows: List<&2, List<&2, Ast.SyntaxPattern>>, constructor: String, arity: Nat, globals: List<&2, Global>) -> List<&2, List<&2, Ast.SyntaxPattern>>:
  match rows:
    case Nil{}: Nil{}
    case +row <> rest:
      match row:
        case Nil{}: Nil{} <> specialize_pattern_rows(rest, constructor, arity, globals)
        case +pattern <> tail:
          match pattern:
            case Ast.PatternVar{ _,  _,  _, span}:
              fields = wildcard_patterns(arity, span)
              List.append(&2, Ast.SyntaxPattern, fields, tail) <> specialize_pattern_rows(rest, constructor, arity, globals)
            case Ast.PatternCtr{key, fields,  _}:
              Bool.pick(List<&2, List<&2, Ast.SyntaxPattern>>, Bool.and(String.eq(canonical_name(key, globals), constructor), Nat.is_eq(List.length(&2, Ast.SyntaxPattern, fields), arity)), List.append(&2, Ast.SyntaxPattern, fields, tail) <> specialize_pattern_rows(rest, constructor, arity, globals), specialize_pattern_rows(rest, constructor, arity, globals))

type CheckerSccInput163 is Data:
  CheckerSccCall_matrix_covers_recursive_result{covered: Bool, rest: List<&2, String>, ty: Ast.SyntaxTerm, rows: List<&2, List<&2, Ast.SyntaxPattern>>, rest_types: List<&2, Ast.SyntaxTerm>, globals: List<&2, Global>}
  CheckerSccCall_matrix_covers_constructors{constructors: List<&2, String>, ty: Ast.SyntaxTerm, rows: List<&2, List<&2, Ast.SyntaxPattern>>, rest_types: List<&2, Ast.SyntaxTerm>, globals: List<&2, Global>}
  CheckerSccCall_matrix_covers_types{types: List<&2, Ast.SyntaxTerm>, rows: List<&2, List<&2, Ast.SyntaxPattern>>, globals: List<&2, Global>}
  CheckerSccCall_matrix_covers{types: List<&2, Ast.SyntaxTerm>, rows: List<&2, List<&2, Ast.SyntaxPattern>>, globals: List<&2, Global>}

def checker_scc_result_163(request: CheckerSccInput163) -> Type:
  match request:
    case CheckerSccCall_matrix_covers_recursive_result{covered, rest, ty, rows, rest_types, globals}: Bool
    case CheckerSccCall_matrix_covers_constructors{constructors, ty, rows, rest_types, globals}: Bool
    case CheckerSccCall_matrix_covers_types{types, rows, globals}: Bool
    case CheckerSccCall_matrix_covers{types, rows, globals}: Bool

def checker_scc_run_163(request: CheckerSccInput163) -> checker_scc_result_163(request):
  match request:
    case CheckerSccCall_matrix_covers_recursive_result{covered, rest, ty, rows, rest_types, globals}:
      match covered:
        case True{}: checker_scc_run_163(CheckerSccCall_matrix_covers_constructors{rest, ty, rows, rest_types, globals})
        case False{}: False{}

    case CheckerSccCall_matrix_covers_constructors{constructors, ty, rows, rest_types, globals}:
      match constructors:
        case Nil{}: True{}
        case +constructor <> rest:
          field_types = constructor_field_types_for_type(ty, constructor, globals)
          arity = List.length(&2, Ast.SyntaxTerm, field_types)
          specialized = specialize_pattern_rows(rows, constructor, arity, globals)
          Bool.pick(Bool, List.is_empty(&2, List<&2, Ast.SyntaxPattern>, specialized), False{}, checker_scc_run_163(CheckerSccCall_matrix_covers_recursive_result{checker_scc_run_163(CheckerSccCall_matrix_covers{List.append(&2, Ast.SyntaxTerm, field_types, rest_types), specialized, globals}), rest, ty, rows, rest_types, globals}))

    case CheckerSccCall_matrix_covers_types{types, rows, globals}:
      match types:
        case Nil{}: False{}
        case +ty <> rest_types: checker_scc_run_163(CheckerSccCall_matrix_covers_constructors{constructors_for_type(ty, globals), ty, rows, rest_types, globals})

    case CheckerSccCall_matrix_covers{types, rows, globals}:
      match rows:
        case +row <> _:
          Bool.pick(Bool, all_variable_patterns(row), True{}, checker_scc_run_163(CheckerSccCall_matrix_covers_types{types, rows, globals}))
        case Nil{}: False{}


def matrix_covers_recursive_result(covered: Bool, rest: List<&2, String>, ty: Ast.SyntaxTerm, rows: List<&2, List<&2, Ast.SyntaxPattern>>, rest_types: List<&2, Ast.SyntaxTerm>, globals: List<&2, Global>) -> Bool:
  checker_scc_run_163(CheckerSccCall_matrix_covers_recursive_result{covered, rest, ty, rows, rest_types, globals})

def matrix_covers_constructors(constructors: List<&2, String>, ty: Ast.SyntaxTerm, rows: List<&2, List<&2, Ast.SyntaxPattern>>, rest_types: List<&2, Ast.SyntaxTerm>, globals: List<&2, Global>) -> Bool:
  checker_scc_run_163(CheckerSccCall_matrix_covers_constructors{constructors, ty, rows, rest_types, globals})

def matrix_covers_types(types: List<&2, Ast.SyntaxTerm>, rows: List<&2, List<&2, Ast.SyntaxPattern>>, globals: List<&2, Global>) -> Bool:
  checker_scc_run_163(CheckerSccCall_matrix_covers_types{types, rows, globals})

def matrix_covers(types: List<&2, Ast.SyntaxTerm>, rows: List<&2, List<&2, Ast.SyntaxPattern>>, globals: List<&2, Global>) -> Bool:
  checker_scc_run_163(CheckerSccCall_matrix_covers{types, rows, globals})

def check_body_cases_result(result: Inference, cases: List<&2, Ast.SyntaxTerm>, ty: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm) -> Inference:
  match result:
    case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}
    case Inferred{ _,  _}: check_body_matrix_result(matrix_covers([ty], case_pattern_rows(cases), globals), span, expected, whole)

def check_body_case_catchall_result(result: Inference, whole: Ast.SyntaxTerm, expected: Ast.SyntaxTerm) -> Inference:
  match result:
    case Inferred{ _,  _}: Inferred{ whole,  expected}
    case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}

def root_pattern_quantity_result(found: Maybe<&2, Binding>, quantity: Ast.Quantity) -> Bool:
  match found:
    case Some{binding}:
      match binding:
        case Binding{ _,  available,  _}: pattern_quantity_allowed(available, quantity)
    case None{}: False{}

def root_pattern_quantity_allowed(pattern: Ast.SyntaxPattern, source_index: Nat, env: List<&2, Binding>) -> Bool:
  match pattern:
    case Ast.PatternVar{ _,  _, quantity,  _}:
      root_pattern_quantity_result(lookup_binding(source_index, env), quantity)
    case Ast.PatternCtr{ _,  _,  _}: True{}

def optional_root_pattern_quantity_allowed(pattern: Ast.SyntaxPattern, source_index: Maybe<&2, Nat>, env: List<&2, Binding>) -> Bool:
  match source_index:
    case Some{value}: root_pattern_quantity_allowed(pattern, value, env)
    case None{}: True{}

def check_body_match_many_rows_result(result: Inference, types: List<&2, Ast.SyntaxTerm>, scrutinees: List<&2, Ast.SyntaxTerm>, cases: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm) -> Inference:
  match result:
    case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}
    case Inferred{ _,  _}: Bool.pick(Inference, matrix_covers(types, case_pattern_rows(cases), globals), Inferred{ whole,  expected}, fail(span, "match is not exhaustive", "all combinations of constructors", "an uncovered constructor combination"))

def pattern_source_span(pattern: Ast.SyntaxPattern) -> Ast.SourceSpan:
  match pattern:
    case Ast.PatternVar{ _,  _,  _, span}: span
    case Ast.PatternCtr{ _,  _, span}: span

type CheckerSccInput171 is Data:
  CheckerSccCall_match_scrutinee_binding{found: Maybe<&2, Binding>, rest: List<&2, Ast.SyntaxTerm>, env: List<&2, Binding>}
  CheckerSccCall_match_scrutinees_valid{scrutinees: List<&2, Ast.SyntaxTerm>, env: List<&2, Binding>}

def checker_scc_result_171(request: CheckerSccInput171) -> Type:
  match request:
    case CheckerSccCall_match_scrutinee_binding{found, rest, env}: Bool
    case CheckerSccCall_match_scrutinees_valid{scrutinees, env}: Bool

def checker_scc_run_171(request: CheckerSccInput171) -> checker_scc_result_171(request):
  match request:
    case CheckerSccCall_match_scrutinee_binding{found, rest, env}:
      match found:
        case Some{_}: checker_scc_run_171(CheckerSccCall_match_scrutinees_valid{rest, env})
        case None{}: False{}

    case CheckerSccCall_match_scrutinees_valid{scrutinees, env}:
      match scrutinees:
        case Nil{}: True{}
        case +scrutinee <> rest:
          match scrutinee:
            case Ast.TermVar{ _, index,  _}:
              checker_scc_run_171(CheckerSccCall_match_scrutinee_binding{lookup_binding(index, env), rest, env})
            case _: False{}


def match_scrutinee_binding(found: Maybe<&2, Binding>, rest: List<&2, Ast.SyntaxTerm>, env: List<&2, Binding>) -> Bool:
  checker_scc_run_171(CheckerSccCall_match_scrutinee_binding{found, rest, env})

def match_scrutinees_valid(scrutinees: List<&2, Ast.SyntaxTerm>, env: List<&2, Binding>) -> Bool:
  checker_scc_run_171(CheckerSccCall_match_scrutinees_valid{scrutinees, env})

def check_term_inferred(result: Inference, expected: Ast.SyntaxTerm, term: Ast.SyntaxTerm, globals: List<&2, Global>) -> Inference:
  match result:
    case Inferred{ checked, ty}: Bool.pick(Inference, fits_term(ty, expected, globals), Inferred{ checked,  expected}, fail(term_span(term), "term has the wrong type", "the expected type", "an incompatible type"))
    case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}

type CheckerSccInput173 is Data:
  CheckerSccCall_infer_adt_args_view{args: List<&2, Ast.SyntaxTerm>, current: Ast.SyntaxTerm, view: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, span: Ast.SourceSpan}
  CheckerSccCall_infer_adt_arg_check{result: Inference, rest: List<&2, Ast.SyntaxTerm>, codomain: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, span: Ast.SourceSpan}
  CheckerSccCall_infer_adt_args{args: List<&2, Ast.SyntaxTerm>, current: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, span: Ast.SourceSpan}
  CheckerSccCall_validate_terms_result{result: Inference, rest: List<&2, Ast.SyntaxTerm>, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_validate_terms{terms: List<&2, Ast.SyntaxTerm>, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_check_local_quantities{keys: List<&2, String>, quantities: List<&2, Ast.Quantity>, body: Ast.SyntaxTerm, remaining: Nat, span: Ast.SourceSpan, usage_env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_check_local_pattern_uses{patterns: List<&2, Ast.SyntaxPattern>, body: Ast.SyntaxTerm, remaining: Nat, usage_env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_check_body_local_uses_result{result: Maybe<&2, Diagnostic>, patterns: List<&2, Ast.SyntaxPattern>, values: List<&2, Ast.SyntaxTerm>, body: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>, usage_env: List<&2, Binding>}
  CheckerSccCall_check_body_local_terms_result{result: Maybe<&2, Diagnostic>, patterns: List<&2, Ast.SyntaxPattern>, values: List<&2, Ast.SyntaxTerm>, body: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_check_body_local_quantity_result{matches: Bool, patterns: List<&2, Ast.SyntaxPattern>, quantity: Ast.Quantity, values: List<&2, Ast.SyntaxTerm>, body: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_check_body_local_length_result{matches: Bool, patterns: List<&2, Ast.SyntaxPattern>, quantity: Ast.Quantity, values: List<&2, Ast.SyntaxTerm>, body: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_check_body_local{patterns: List<&2, Ast.SyntaxPattern>, quantity: Ast.Quantity, values: List<&2, Ast.SyntaxTerm>, body: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_infer_family_sugar_result{lowering: FamilyLowering, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_infer_family_sugar{head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, plus: Bool, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_infer_application_result_view{view: Ast.SyntaxTerm, term: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_infer_application_result{term: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, function_ty: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_infer_global_adt{found: Maybe<&2, Global>, key: String, args: List<&2, Ast.SyntaxTerm>, term: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_infer_term_annotation_result{result: Inference, inner: Ast.SyntaxTerm, term: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_infer_equal_type{result: Inference, left: Ast.SyntaxTerm, right: Ast.SyntaxTerm, ty: Ast.SyntaxTerm, term: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_infer_application_result_of_function{result: Inference, term: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_infer_application_unfolded{view: Ast.SyntaxTerm, fn: Ast.SyntaxTerm, term: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_infer_application_bang{is_bang: Bool, fn: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, term: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_infer_application_valid{valid: Bool, fn: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, term: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_infer_all_domain{result: Inference, quantity: Ast.Quantity, key: String, ty: Ast.SyntaxTerm, body: Ast.SyntaxTerm, term: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_infer_let_values{result: Maybe<&2, Diagnostic>, keys: List<&2, String>, values: List<&2, Ast.SyntaxTerm>, body: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_infer_let_validated{result: Maybe<&2, Diagnostic>, values: List<&2, Ast.SyntaxTerm>, body: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_infer_let_lengths{valid: Bool, values: List<&2, Ast.SyntaxTerm>, body: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_infer{term: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_check_match_head_result{result: Inference, matched: Ast.SyntaxTerm, default_ty: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_check_match_applied{applied: Maybe<&2, Ast.SyntaxTerm>, key: String, head: Ast.SyntaxTerm, matched: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, family: String, parameters: List<&2, Ast.SyntaxTerm>, refs: List<&2, String>, quantity: Ast.Quantity, scrutinee: String, index: Nat, body: Ast.SyntaxTerm, found_family: String}
  CheckerSccCall_check_match_family_equal{matches: Bool, found_family: String, key: String, head: Ast.SyntaxTerm, matched: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, family: String, parameters: List<&2, Ast.SyntaxTerm>, refs: List<&2, String>, quantity: Ast.Quantity, scrutinee: String, index: Nat, body: Ast.SyntaxTerm, constructor_ty: Ast.SyntaxTerm}
  CheckerSccCall_check_match_family_result{found: Maybe<&2, String>, key: String, head: Ast.SyntaxTerm, matched: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, family: String, family_key: String, parameters: List<&2, Ast.SyntaxTerm>, refs: List<&2, String>, quantity: Ast.Quantity, scrutinee: String, index: Nat, body: Ast.SyntaxTerm, constructor_ty: Ast.SyntaxTerm}
  CheckerSccCall_check_match_global{constructor: Global, key: String, head: Ast.SyntaxTerm, matched: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, family: String, family_key: String, parameters: List<&2, Ast.SyntaxTerm>, refs: List<&2, String>, quantity: Ast.Quantity, scrutinee: String, index: Nat, body: Ast.SyntaxTerm}
  CheckerSccCall_check_match_constructor{found: Maybe<&2, Global>, key: String, head: Ast.SyntaxTerm, matched: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, family: String, family_key: String, parameters: List<&2, Ast.SyntaxTerm>, refs: List<&2, String>, quantity: Ast.Quantity, scrutinee: String, index: Nat, body: Ast.SyntaxTerm}
  CheckerSccCall_check_match_unexcluded{excluded: Bool, key: String, head: Ast.SyntaxTerm, matched: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, family: String, family_key: String, parameters: List<&2, Ast.SyntaxTerm>, refs: List<&2, String>, quantity: Ast.Quantity, scrutinee: String, index: Nat, body: Ast.SyntaxTerm}
  CheckerSccCall_check_match_input_view{view: Ast.SyntaxTerm, key: String, head: Ast.SyntaxTerm, matched: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, quantity: Ast.Quantity, scrutinee: String, index: Nat, body: Ast.SyntaxTerm}
  CheckerSccCall_check_match_goal_view{view: Ast.SyntaxTerm, key: String, head: Ast.SyntaxTerm, matched: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm}
  CheckerSccCall_check_match{key: String, head: Ast.SyntaxTerm, matched: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm}
  CheckerSccCall_check_body_case_body_result{result: Inference, rest: List<&2, Ast.SyntaxTerm>, family: String, parameters: List<&2, Ast.SyntaxTerm>, scrutinee_ty: Ast.SyntaxTerm, scrutinee_index: Maybe<&2, Nat>, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, removed: List<&2, String>, span: Ast.SourceSpan, key: String}
  CheckerSccCall_check_body_case_pattern_result{result: PatternTyping, pattern: Ast.SyntaxPattern, rest: List<&2, Ast.SyntaxTerm>, family: String, parameters: List<&2, Ast.SyntaxTerm>, scrutinee_ty: Ast.SyntaxTerm, scrutinee_index: Maybe<&2, Nat>, body: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, removed: List<&2, String>, span: Ast.SourceSpan, key: String}
  CheckerSccCall_check_body_case_constructor_uses{valid: Bool, pattern: Ast.SyntaxPattern, rest: List<&2, Ast.SyntaxTerm>, family: String, parameters: List<&2, Ast.SyntaxTerm>, scrutinee_ty: Ast.SyntaxTerm, scrutinee_index: Maybe<&2, Nat>, body: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, removed: List<&2, String>, span: Ast.SourceSpan, key: String, pattern_span: Ast.SourceSpan}
  CheckerSccCall_check_body_case_constructor_seen{seen: Bool, pattern: Ast.SyntaxPattern, rest: List<&2, Ast.SyntaxTerm>, family: String, parameters: List<&2, Ast.SyntaxTerm>, scrutinee_ty: Ast.SyntaxTerm, scrutinee_index: Maybe<&2, Nat>, body: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, removed: List<&2, String>, span: Ast.SourceSpan, key: String, pattern_span: Ast.SourceSpan}
  CheckerSccCall_check_body_case_catchall_usage{valid: Bool, key: String, quantity: Ast.Quantity, pattern: Ast.SyntaxPattern, scrutinee_ty: Ast.SyntaxTerm, scrutinee_index: Maybe<&2, Nat>, body: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, pattern_span: Ast.SourceSpan}
  CheckerSccCall_check_body_case_catchall{rest: List<&2, Ast.SyntaxTerm>, key: String, quantity: Ast.Quantity, pattern: Ast.SyntaxPattern, scrutinee_ty: Ast.SyntaxTerm, scrutinee_index: Maybe<&2, Nat>, body: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, pattern_span: Ast.SourceSpan}
  CheckerSccCall_check_body_case_pattern{pattern: Ast.SyntaxPattern, rest: List<&2, Ast.SyntaxTerm>, family: String, parameters: List<&2, Ast.SyntaxTerm>, scrutinee_ty: Ast.SyntaxTerm, scrutinee_index: Maybe<&2, Nat>, body: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, removed: List<&2, String>, span: Ast.SourceSpan, pattern_span: Ast.SourceSpan}
  CheckerSccCall_check_body_case_term{case_term: Ast.SyntaxTerm, rest: List<&2, Ast.SyntaxTerm>, family: String, parameters: List<&2, Ast.SyntaxTerm>, scrutinee_ty: Ast.SyntaxTerm, scrutinee_index: Maybe<&2, Nat>, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, removed: List<&2, String>, span: Ast.SourceSpan}
  CheckerSccCall_check_body_cases{cases: List<&2, Ast.SyntaxTerm>, family: String, parameters: List<&2, Ast.SyntaxTerm>, scrutinee_ty: Ast.SyntaxTerm, scrutinee_index: Maybe<&2, Nat>, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, removed: List<&2, String>, span: Ast.SourceSpan}
  CheckerSccCall_check_body_match_type_view{view: Ast.SyntaxTerm, scrutinee: Ast.SyntaxTerm, cases: List<&2, Ast.SyntaxTerm>, ty: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm}
  CheckerSccCall_check_body_match_type{scrutinee: Ast.SyntaxTerm, cases: List<&2, Ast.SyntaxTerm>, ty: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm}
  CheckerSccCall_infer_scrutinee_types_result{result: Inference, rest: List<&2, Ast.SyntaxTerm>, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_infer_scrutinee_types{scrutinees: List<&2, Ast.SyntaxTerm>, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_pattern_uses_valid{pattern: Ast.SyntaxPattern, body: Ast.SyntaxTerm, remaining: Nat, globals: List<&2, Global>}
  CheckerSccCall_pattern_uses_valid_list{patterns: List<&2, Ast.SyntaxPattern>, body: Ast.SyntaxTerm, remaining: Nat, globals: List<&2, Global>}
  CheckerSccCall_check_body_pattern_vector_typed{result: PatternTyping, pattern_rest: List<&2, Ast.SyntaxPattern>, type_rest: List<&2, Ast.SyntaxTerm>, scrutinee_rest: List<&2, Ast.SyntaxTerm>, pattern: Ast.SyntaxPattern, body: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, remaining: Nat, offset: Nat, span: Ast.SourceSpan, source_index: Maybe<&2, Nat>, added: Nat}
  CheckerSccCall_check_body_pattern_vector{patterns: List<&2, Ast.SyntaxPattern>, types: List<&2, Ast.SyntaxTerm>, scrutinees: List<&2, Ast.SyntaxTerm>, body: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, remaining: Nat, offset: Nat, span: Ast.SourceSpan}
  CheckerSccCall_check_body_pattern_rows_result{result: Inference, rest: List<&2, Ast.SyntaxTerm>, types: List<&2, Ast.SyntaxTerm>, scrutinees: List<&2, Ast.SyntaxTerm>, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, span: Ast.SourceSpan}
  CheckerSccCall_check_body_pattern_rows_catchall{valid: Bool, patterns: List<&2, Ast.SyntaxPattern>, body: Ast.SyntaxTerm, case_span: Ast.SourceSpan, rest: List<&2, Ast.SyntaxTerm>, types: List<&2, Ast.SyntaxTerm>, scrutinees: List<&2, Ast.SyntaxTerm>, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, span: Ast.SourceSpan}
  CheckerSccCall_check_body_pattern_rows_length{valid: Bool, patterns: List<&2, Ast.SyntaxPattern>, body: Ast.SyntaxTerm, case_span: Ast.SourceSpan, rest: List<&2, Ast.SyntaxTerm>, types: List<&2, Ast.SyntaxTerm>, scrutinees: List<&2, Ast.SyntaxTerm>, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, span: Ast.SourceSpan}
  CheckerSccCall_check_body_pattern_rows_case{case_term: Ast.SyntaxTerm, rest: List<&2, Ast.SyntaxTerm>, types: List<&2, Ast.SyntaxTerm>, scrutinees: List<&2, Ast.SyntaxTerm>, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, span: Ast.SourceSpan}
  CheckerSccCall_check_body_pattern_rows{cases: List<&2, Ast.SyntaxTerm>, types: List<&2, Ast.SyntaxTerm>, scrutinees: List<&2, Ast.SyntaxTerm>, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, span: Ast.SourceSpan}
  CheckerSccCall_check_body_match_many_types_result{result: ScrutineeTyping, scrutinees: List<&2, Ast.SyntaxTerm>, cases: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm}
  CheckerSccCall_check_body_match_many{scrutinees: List<&2, Ast.SyntaxTerm>, cases: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm}
  CheckerSccCall_check_body_match_first_result{result: Inference, scrutinee: Ast.SyntaxTerm, cases: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm}
  CheckerSccCall_check_body_match_scrutinees{scrutinees: List<&2, Ast.SyntaxTerm>, cases: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm}
  CheckerSccCall_check_body_match_valid{valid: Bool, scrutinees: List<&2, Ast.SyntaxTerm>, cases: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm}
  CheckerSccCall_check_body_match{scrutinees: List<&2, Ast.SyntaxTerm>, cases: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm}
  CheckerSccCall_rewrite_body_type_view{view: Ast.SyntaxTerm, body: Ast.SyntaxTerm, body_ty: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm}
  CheckerSccCall_rewrite_left_applied_result{applied: Maybe<&2, Ast.SyntaxTerm>, body: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm}
  CheckerSccCall_rewrite_fits_result{fits: Bool, left: Ast.SyntaxTerm, p_ty: Ast.SyntaxTerm, body: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm}
  CheckerSccCall_rewrite_equation_applied_result{applied: Maybe<&2, Ast.SyntaxTerm>, right: Ast.SyntaxTerm, left: Ast.SyntaxTerm, p_ty: Ast.SyntaxTerm, body: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm}
  CheckerSccCall_rewrite_proof_result{result: Inference, right: Ast.SyntaxTerm, left: Ast.SyntaxTerm, checked_equation: Ast.SyntaxTerm, p_ty: Ast.SyntaxTerm, body: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm}
  CheckerSccCall_rewrite_equation_view{view: Ast.SyntaxTerm, checked_equation: Ast.SyntaxTerm, proof: Ast.SyntaxTerm, body: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm}
  CheckerSccCall_rewrite_equation_result{result: Inference, proof: Ast.SyntaxTerm, body: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm}
  CheckerSccCall_check_rewrite{equation: Ast.SyntaxTerm, proof: Ast.SyntaxTerm, body: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm}
  CheckerSccCall_lambda_domain_valid{domain: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_check_lambda_domain_result{valid: Bool, annotated: Maybe<&2, Ast.Quantity>, key: String, body: Ast.SyntaxTerm, quantity: Ast.Quantity, domain: Ast.SyntaxTerm, codomain: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_check_lambda_promotes_result{promotes: Bool, annotated: Maybe<&2, Ast.Quantity>, key: String, body: Ast.SyntaxTerm, quantity: Ast.Quantity, domain: Ast.SyntaxTerm, codomain: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_check_lambda_quantity_result{found: Maybe<&2, Ast.Quantity>, annotated: Maybe<&2, Ast.Quantity>, key: String, body: Ast.SyntaxTerm, domain: Ast.SyntaxTerm, codomain: Ast.SyntaxTerm, span: Ast.SourceSpan, expected_quantity: Ast.Quantity, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_check_lambda_body{annotated: Maybe<&2, Ast.Quantity>, key: String, body: Ast.SyntaxTerm, expected_quantity: Ast.Quantity, domain: Ast.SyntaxTerm, codomain: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_check_lambda_body_result{result: Inference, annotated: Maybe<&2, Ast.Quantity>, key: String, body: Ast.SyntaxTerm, quantity: Ast.Quantity, domain: Ast.SyntaxTerm, codomain: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_check_term_lambda_view{view: Ast.SyntaxTerm, annotated: Maybe<&2, Ast.Quantity>, key: String, body: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_check_term_constructor_apply{found: Maybe<&2, Ast.SyntaxTerm>, key: String, args: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, parameters: List<&2, Ast.SyntaxTerm>, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, term: Ast.SyntaxTerm}
  CheckerSccCall_check_term_constructor_global{global: Global, key: String, args: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, parameters: List<&2, Ast.SyntaxTerm>, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, term: Ast.SyntaxTerm}
  CheckerSccCall_check_term_constructor_global_result{found: Maybe<&2, Global>, key: String, args: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, parameters: List<&2, Ast.SyntaxTerm>, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, term: Ast.SyntaxTerm}
  CheckerSccCall_check_term_constructor_allowed{allowed: Bool, key: String, args: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, parameters: List<&2, Ast.SyntaxTerm>, refs: List<&2, String>, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, term: Ast.SyntaxTerm}
  CheckerSccCall_check_term_constructor_view{view: Ast.SyntaxTerm, key: String, args: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, term: Ast.SyntaxTerm}
  CheckerSccCall_check_term{term: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, expected: Ast.SyntaxTerm}
  CheckerSccCall_usage_let_env{keys: List<&2, String>, quantities: List<&2, Ast.Quantity>, values: List<&2, Ast.SyntaxTerm>, value_env: List<&2, Binding>, acc: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_usage_local_env{patterns: List<&2, Ast.SyntaxPattern>, values: List<&2, Ast.SyntaxTerm>, value_env: List<&2, Binding>, acc: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_term_usage_map_constructor_view{view: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, rest: List<&2, Ast.SyntaxTerm>, args: List<&2, Ast.SyntaxTerm>, ty: Ast.SyntaxTerm, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_constructor_argument_usage{quantity: Ast.Quantity, arg: Ast.SyntaxTerm, domain: Ast.SyntaxTerm, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_term_usage_map_constructor_args{args: List<&2, Ast.SyntaxTerm>, ty: Ast.SyntaxTerm, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_term_usage_map_lambda_quantity{found: Maybe<&2, Ast.Quantity>, key: String, body: Ast.SyntaxTerm, span: Ast.SourceSpan, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>, domain: Ast.SyntaxTerm, codomain: Ast.SyntaxTerm}
  CheckerSccCall_term_usage_map_lambda_view{view: Ast.SyntaxTerm, annotated: Maybe<&2, Ast.Quantity>, key: String, body: Ast.SyntaxTerm, span: Ast.SourceSpan, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_term_usage_map_lambda_expected{expected: Maybe<&2, Ast.SyntaxTerm>, annotated: Maybe<&2, Ast.Quantity>, key: String, body: Ast.SyntaxTerm, span: Ast.SourceSpan, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_term_usage_map_application_quantity{found: Maybe<&2, Ast.Quantity>, fn: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_term_usage_map_family_result{result: FamilySugar, head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>, expected: Maybe<&2, Ast.SyntaxTerm>}
  CheckerSccCall_term_usage_map_constructor_result{found: Maybe<&2, Ast.SyntaxTerm>, key: String, args: List<&2, Ast.SyntaxTerm>, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_term_usage_map_scrutinee_result{result: ScrutineeTyping, scrutinees: List<&2, Ast.SyntaxTerm>, cases: List<&2, Ast.SyntaxTerm>, scrutinee_usage: List<&2, UsageEntry>, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>, expected: Maybe<&2, Ast.SyntaxTerm>}
  CheckerSccCall_term_usage_map{term: Ast.SyntaxTerm, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>, expected: Maybe<&2, Ast.SyntaxTerm>}
  CheckerSccCall_term_usage_map_cases{cases: List<&2, Ast.SyntaxTerm>, scrutinees: List<&2, Ast.SyntaxTerm>, types: List<&2, Ast.SyntaxTerm>, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>, expected: Maybe<&2, Ast.SyntaxTerm>}
  CheckerSccCall_term_usage_map_case{case_term: Ast.SyntaxTerm, scrutinees: List<&2, Ast.SyntaxTerm>, types: List<&2, Ast.SyntaxTerm>, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>, expected: Maybe<&2, Ast.SyntaxTerm>}
  CheckerSccCall_term_usage_map_list{terms: List<&2, Ast.SyntaxTerm>, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_term_usage_map_quantified_list{terms: List<&2, Ast.SyntaxTerm>, quantities: List<&2, Ast.Quantity>, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_use_count_with_globals{term: Ast.SyntaxTerm, wanted: Nat, depth: Nat, globals: List<&2, Global>}
  CheckerSccCall_use_count_with_context{term: Ast.SyntaxTerm, wanted: Nat, env: List<&2, Binding>, globals: List<&2, Global>}
  CheckerSccCall_use_count_with_expected{term: Ast.SyntaxTerm, wanted: Nat, env: List<&2, Binding>, globals: List<&2, Global>, expected: Ast.SyntaxTerm}
  CheckerSccCall_check_ctr_fields_arg{result: Inference, rest: List<&2, Ast.SyntaxTerm>, body: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, span: Ast.SourceSpan}
  CheckerSccCall_check_ctr_fields_view{view: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, rest: List<&2, Ast.SyntaxTerm>, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, span: Ast.SourceSpan}
  CheckerSccCall_check_ctr_fields{args: List<&2, Ast.SyntaxTerm>, ty: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, span: Ast.SourceSpan}

def checker_scc_result_173(request: CheckerSccInput173) -> Type:
  match request:
    case CheckerSccCall_infer_adt_args_view{args, current, view, env, globals, whole, span}: Inference
    case CheckerSccCall_infer_adt_arg_check{result, rest, codomain, env, globals, whole, span}: Inference
    case CheckerSccCall_infer_adt_args{args, current, env, globals, whole, span}: Inference
    case CheckerSccCall_validate_terms_result{result, rest, env, globals}: Maybe<&2, Diagnostic>
    case CheckerSccCall_validate_terms{terms, env, globals}: Maybe<&2, Diagnostic>
    case CheckerSccCall_check_local_quantities{keys, quantities, body, remaining, span, usage_env, globals}: Maybe<&2, Diagnostic>
    case CheckerSccCall_check_local_pattern_uses{patterns, body, remaining, usage_env, globals}: Maybe<&2, Diagnostic>
    case CheckerSccCall_check_body_local_uses_result{result, patterns, values, body, span, env, globals, usage_env}: Inference
    case CheckerSccCall_check_body_local_terms_result{result, patterns, values, body, span, env, globals}: Inference
    case CheckerSccCall_check_body_local_quantity_result{matches, patterns, quantity, values, body, span, env, globals}: Inference
    case CheckerSccCall_check_body_local_length_result{matches, patterns, quantity, values, body, span, env, globals}: Inference
    case CheckerSccCall_check_body_local{patterns, quantity, values, body, span, env, globals}: Inference
    case CheckerSccCall_infer_family_sugar_result{lowering, env, globals}: Inference
    case CheckerSccCall_infer_family_sugar{head, args, plus, span, env, globals}: Inference
    case CheckerSccCall_infer_application_result_view{view, term, arg, span, env, globals}: Inference
    case CheckerSccCall_infer_application_result{term, arg, function_ty, span, env, globals}: Inference
    case CheckerSccCall_infer_global_adt{found, key, args, term, span, env, globals}: Inference
    case CheckerSccCall_infer_term_annotation_result{result, inner, term, span, env, globals}: Inference
    case CheckerSccCall_infer_equal_type{result, left, right, ty, term, span, env, globals}: Inference
    case CheckerSccCall_infer_application_result_of_function{result, term, arg, span, env, globals}: Inference
    case CheckerSccCall_infer_application_unfolded{view, fn, term, arg, span, env, globals}: Inference
    case CheckerSccCall_infer_application_bang{is_bang, fn, arg, term, span, env, globals}: Inference
    case CheckerSccCall_infer_application_valid{valid, fn, arg, term, span, env, globals}: Inference
    case CheckerSccCall_infer_all_domain{result, quantity, key, ty, body, term, span, env, globals}: Inference
    case CheckerSccCall_infer_let_values{result, keys, values, body, span, env, globals}: Inference
    case CheckerSccCall_infer_let_validated{result, values, body, span, env, globals}: Inference
    case CheckerSccCall_infer_let_lengths{valid, values, body, span, env, globals}: Inference
    case CheckerSccCall_infer{term, env, globals}: Inference
    case CheckerSccCall_check_match_head_result{result, matched, default_ty, whole, expected, env, globals}: Inference
    case CheckerSccCall_check_match_applied{applied, key, head, matched, span, expected, env, globals, whole, family, parameters, refs, quantity, scrutinee, index, body, found_family}: Inference
    case CheckerSccCall_check_match_family_equal{matches, found_family, key, head, matched, span, expected, env, globals, whole, family, parameters, refs, quantity, scrutinee, index, body, constructor_ty}: Inference
    case CheckerSccCall_check_match_family_result{found, key, head, matched, span, expected, env, globals, whole, family, family_key, parameters, refs, quantity, scrutinee, index, body, constructor_ty}: Inference
    case CheckerSccCall_check_match_global{constructor, key, head, matched, span, expected, env, globals, whole, family, family_key, parameters, refs, quantity, scrutinee, index, body}: Inference
    case CheckerSccCall_check_match_constructor{found, key, head, matched, span, expected, env, globals, whole, family, family_key, parameters, refs, quantity, scrutinee, index, body}: Inference
    case CheckerSccCall_check_match_unexcluded{excluded, key, head, matched, span, expected, env, globals, whole, family, family_key, parameters, refs, quantity, scrutinee, index, body}: Inference
    case CheckerSccCall_check_match_input_view{view, key, head, matched, span, expected, env, globals, whole, quantity, scrutinee, index, body}: Inference
    case CheckerSccCall_check_match_goal_view{view, key, head, matched, span, expected, env, globals, whole}: Inference
    case CheckerSccCall_check_match{key, head, matched, span, expected, env, globals, whole}: Inference
    case CheckerSccCall_check_body_case_body_result{result, rest, family, parameters, scrutinee_ty, scrutinee_index, expected, whole, env, globals, removed, span, key}: Inference
    case CheckerSccCall_check_body_case_pattern_result{result, pattern, rest, family, parameters, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, removed, span, key}: Inference
    case CheckerSccCall_check_body_case_constructor_uses{valid, pattern, rest, family, parameters, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, removed, span, key, pattern_span}: Inference
    case CheckerSccCall_check_body_case_constructor_seen{seen, pattern, rest, family, parameters, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, removed, span, key, pattern_span}: Inference
    case CheckerSccCall_check_body_case_catchall_usage{valid, key, quantity, pattern, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, pattern_span}: Inference
    case CheckerSccCall_check_body_case_catchall{rest, key, quantity, pattern, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, pattern_span}: Inference
    case CheckerSccCall_check_body_case_pattern{pattern, rest, family, parameters, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, removed, span, pattern_span}: Inference
    case CheckerSccCall_check_body_case_term{case_term, rest, family, parameters, scrutinee_ty, scrutinee_index, expected, whole, env, globals, removed, span}: Inference
    case CheckerSccCall_check_body_cases{cases, family, parameters, scrutinee_ty, scrutinee_index, expected, whole, env, globals, removed, span}: Inference
    case CheckerSccCall_check_body_match_type_view{view, scrutinee, cases, ty, span, expected, env, globals, whole}: Inference
    case CheckerSccCall_check_body_match_type{scrutinee, cases, ty, span, expected, env, globals, whole}: Inference
    case CheckerSccCall_infer_scrutinee_types_result{result, rest, env, globals}: ScrutineeTyping
    case CheckerSccCall_infer_scrutinee_types{scrutinees, env, globals}: ScrutineeTyping
    case CheckerSccCall_pattern_uses_valid{pattern, body, remaining, globals}: Bool
    case CheckerSccCall_pattern_uses_valid_list{patterns, body, remaining, globals}: Bool
    case CheckerSccCall_check_body_pattern_vector_typed{result, pattern_rest, type_rest, scrutinee_rest, pattern, body, expected, env, globals, remaining, offset, span, source_index, added}: Inference
    case CheckerSccCall_check_body_pattern_vector{patterns, types, scrutinees, body, expected, env, globals, remaining, offset, span}: Inference
    case CheckerSccCall_check_body_pattern_rows_result{result, rest, types, scrutinees, expected, whole, env, globals, span}: Inference
    case CheckerSccCall_check_body_pattern_rows_catchall{valid, patterns, body, case_span, rest, types, scrutinees, expected, whole, env, globals, span}: Inference
    case CheckerSccCall_check_body_pattern_rows_length{valid, patterns, body, case_span, rest, types, scrutinees, expected, whole, env, globals, span}: Inference
    case CheckerSccCall_check_body_pattern_rows_case{case_term, rest, types, scrutinees, expected, whole, env, globals, span}: Inference
    case CheckerSccCall_check_body_pattern_rows{cases, types, scrutinees, expected, whole, env, globals, span}: Inference
    case CheckerSccCall_check_body_match_many_types_result{result, scrutinees, cases, span, expected, env, globals, whole}: Inference
    case CheckerSccCall_check_body_match_many{scrutinees, cases, span, expected, env, globals, whole}: Inference
    case CheckerSccCall_check_body_match_first_result{result, scrutinee, cases, span, expected, env, globals, whole}: Inference
    case CheckerSccCall_check_body_match_scrutinees{scrutinees, cases, span, expected, env, globals, whole}: Inference
    case CheckerSccCall_check_body_match_valid{valid, scrutinees, cases, span, expected, env, globals, whole}: Inference
    case CheckerSccCall_check_body_match{scrutinees, cases, span, expected, env, globals, whole}: Inference
    case CheckerSccCall_rewrite_body_type_view{view, body, body_ty, span, expected, env, globals, whole}: Inference
    case CheckerSccCall_rewrite_left_applied_result{applied, body, span, expected, env, globals, whole}: Inference
    case CheckerSccCall_rewrite_fits_result{fits, left, p_ty, body, span, expected, env, globals, whole}: Inference
    case CheckerSccCall_rewrite_equation_applied_result{applied, right, left, p_ty, body, span, expected, env, globals, whole}: Inference
    case CheckerSccCall_rewrite_proof_result{result, right, left, checked_equation, p_ty, body, span, expected, env, globals, whole}: Inference
    case CheckerSccCall_rewrite_equation_view{view, checked_equation, proof, body, span, expected, env, globals, whole}: Inference
    case CheckerSccCall_rewrite_equation_result{result, proof, body, span, expected, env, globals, whole}: Inference
    case CheckerSccCall_check_rewrite{equation, proof, body, span, expected, env, globals, whole}: Inference
    case CheckerSccCall_lambda_domain_valid{domain, span, env, globals}: Bool
    case CheckerSccCall_check_lambda_domain_result{valid, annotated, key, body, quantity, domain, codomain, span, expected, env, globals}: Inference
    case CheckerSccCall_check_lambda_promotes_result{promotes, annotated, key, body, quantity, domain, codomain, span, expected, env, globals}: Inference
    case CheckerSccCall_check_lambda_quantity_result{found, annotated, key, body, domain, codomain, span, expected_quantity, expected, env, globals}: Inference
    case CheckerSccCall_check_lambda_body{annotated, key, body, expected_quantity, domain, codomain, span, expected, env, globals}: Inference
    case CheckerSccCall_check_lambda_body_result{result, annotated, key, body, quantity, domain, codomain, span, expected, env, globals}: Inference
    case CheckerSccCall_check_term_lambda_view{view, annotated, key, body, span, expected, env, globals}: Inference
    case CheckerSccCall_check_term_constructor_apply{found, key, args, span, parameters, expected, env, globals, term}: Inference
    case CheckerSccCall_check_term_constructor_global{global, key, args, span, parameters, expected, env, globals, term}: Inference
    case CheckerSccCall_check_term_constructor_global_result{found, key, args, span, parameters, expected, env, globals, term}: Inference
    case CheckerSccCall_check_term_constructor_allowed{allowed, key, args, span, parameters, refs, expected, env, globals, term}: Inference
    case CheckerSccCall_check_term_constructor_view{view, key, args, span, expected, env, globals, term}: Inference
    case CheckerSccCall_check_term{term, env, globals, expected}: Inference
    case CheckerSccCall_usage_let_env{keys, quantities, values, value_env, acc, globals}: List<&2, Binding>
    case CheckerSccCall_usage_local_env{patterns, values, value_env, acc, globals}: List<&2, Binding>
    case CheckerSccCall_term_usage_map_constructor_view{view, arg, rest, args, ty, depth, env, globals}: List<&2, UsageEntry>
    case CheckerSccCall_constructor_argument_usage{quantity, arg, domain, depth, env, globals}: List<&2, UsageEntry>
    case CheckerSccCall_term_usage_map_constructor_args{args, ty, depth, env, globals}: List<&2, UsageEntry>
    case CheckerSccCall_term_usage_map_lambda_quantity{found, key, body, span, depth, env, globals, domain, codomain}: List<&2, UsageEntry>
    case CheckerSccCall_term_usage_map_lambda_view{view, annotated, key, body, span, depth, env, globals}: List<&2, UsageEntry>
    case CheckerSccCall_term_usage_map_lambda_expected{expected, annotated, key, body, span, depth, env, globals}: List<&2, UsageEntry>
    case CheckerSccCall_term_usage_map_application_quantity{found, fn, arg, depth, env, globals}: List<&2, UsageEntry>
    case CheckerSccCall_term_usage_map_family_result{result, head, args, depth, env, globals, expected}: List<&2, UsageEntry>
    case CheckerSccCall_term_usage_map_constructor_result{found, key, args, depth, env, globals}: List<&2, UsageEntry>
    case CheckerSccCall_term_usage_map_scrutinee_result{result, scrutinees, cases, scrutinee_usage, depth, env, globals, expected}: List<&2, UsageEntry>
    case CheckerSccCall_term_usage_map{term, depth, env, globals, expected}: List<&2, UsageEntry>
    case CheckerSccCall_term_usage_map_cases{cases, scrutinees, types, depth, env, globals, expected}: List<&2, UsageEntry>
    case CheckerSccCall_term_usage_map_case{case_term, scrutinees, types, depth, env, globals, expected}: List<&2, UsageEntry>
    case CheckerSccCall_term_usage_map_list{terms, depth, env, globals}: List<&2, UsageEntry>
    case CheckerSccCall_term_usage_map_quantified_list{terms, quantities, depth, env, globals}: List<&2, UsageEntry>
    case CheckerSccCall_use_count_with_globals{term, wanted, depth, globals}: Ast.Quantity
    case CheckerSccCall_use_count_with_context{term, wanted, env, globals}: Ast.Quantity
    case CheckerSccCall_use_count_with_expected{term, wanted, env, globals, expected}: Ast.Quantity
    case CheckerSccCall_check_ctr_fields_arg{result, rest, body, expected, env, globals, whole, span}: Inference
    case CheckerSccCall_check_ctr_fields_view{view, arg, rest, expected, env, globals, whole, span}: Inference
    case CheckerSccCall_check_ctr_fields{args, ty, expected, env, globals, whole, span}: Inference

def checker_scc_run_173(request: CheckerSccInput173) -> checker_scc_result_173(request):
  match request:
    case CheckerSccCall_infer_adt_args_view{args, current, view, env, globals, whole, span}:
      match args:
        case Nil{}:
          match view:
            case Ast.TermAll{ _,  _,  _,  _,  _,  _}: fail(span, "datatype has too few parameters", "all family parameters", "an underapplied family")
            case _: Inferred{ whole,  current}
        case +arg <> rest:
          match view:
            case Ast.TermAll{ _,  _,  _,  domain,  codomain,  _}:
              checker_scc_run_173(CheckerSccCall_infer_adt_arg_check{checker_scc_run_173(CheckerSccCall_check_term{arg, env, globals, domain}), rest, codomain, env, globals, whole, span})
            case _: fail(span, "datatype has too many parameters", "a remaining parameter", "an extra parameter")

    case CheckerSccCall_infer_adt_arg_check{result, rest, codomain, env, globals, whole, span}:
      match result:
        case Inferred{ checked_arg,  _}: checker_scc_run_173(CheckerSccCall_infer_adt_args{rest, Core.subst(0n, checked_arg, codomain), env, globals, whole, span})
        case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}

    case CheckerSccCall_infer_adt_args{args, current, env, globals, whole, span}:
      checker_scc_run_173(CheckerSccCall_infer_adt_args_view{args, current, whnf(64n, current, globals), env, globals, whole, span})

    case CheckerSccCall_validate_terms_result{result, rest, env, globals}:
      match result:
        case Inferred{ _,  _}: checker_scc_run_173(CheckerSccCall_validate_terms{rest, env, globals})
        case InferenceFailure{diagnostic}: Some{diagnostic}

    case CheckerSccCall_validate_terms{terms, env, globals}:
      match terms:
        case Nil{}: None{}
        case +term <> rest: checker_scc_run_173(CheckerSccCall_validate_terms_result{checker_scc_run_173(CheckerSccCall_infer{term, env, globals}), rest, env, globals})

    case CheckerSccCall_check_local_quantities{keys, quantities, body, remaining, span, usage_env, globals}:
      match keys quantities:
        case Nil{} Nil{}: None{}
        case +key <> key_rest +quantity <> quantity_rest:
          target = remaining - 1n
          Bool.pick(Maybe<&2, Diagnostic>, quantity_fits(checker_scc_run_173(CheckerSccCall_use_count_with_context{body, target, usage_env, globals}), quantity), checker_scc_run_173(CheckerSccCall_check_local_quantities{key_rest, quantity_rest, body, target, span, usage_env, globals}), Some{Diagnostic{ span_file(span), span,  String.append("invalid local binding use quantity for ", key),  "within the declared quantity",  "too many uses"}})
        case _ _: Some{Diagnostic{ span_file(span), span,  "let binding lists have different lengths",  "parallel names and quantities",  "inconsistent let binders"}}
    case CheckerSccCall_check_local_pattern_uses{patterns, body, remaining, usage_env, globals}:
      match patterns:
        case Nil{}: None{}
        case +pattern <> rest:
          match pattern:
            case Ast.PatternVar{key,  _, quantity, span}:
              target = remaining - 1n
              Bool.pick(Maybe<&2, Diagnostic>, quantity_fits(checker_scc_run_173(CheckerSccCall_use_count_with_context{body, target, usage_env, globals}), quantity), checker_scc_run_173(CheckerSccCall_check_local_pattern_uses{rest, body, target, usage_env, globals}), Some{Diagnostic{ span_file(span), span,  String.append("invalid local binding use quantity for ", key),  "within the declared quantity",  "too many uses"}})
            case Ast.PatternCtr{ _,  _, span}:
              Some{Diagnostic{ span_file(span), span,  "local bindings require identifier patterns",  "one identifier per local value",  "a constructor pattern"}}

    case CheckerSccCall_check_body_local_uses_result{result, patterns, values, body, span, env, globals, usage_env}:
      match result:
        case Some{diagnostic}: InferenceFailure{diagnostic}
        case None{}: checker_scc_run_173(CheckerSccCall_infer{substitute_many(List.reverse(&2, Ast.SyntaxTerm, values), body), env, globals})

    case CheckerSccCall_check_body_local_terms_result{result, patterns, values, body, span, env, globals}:
      match result:
        case Some{diagnostic}: InferenceFailure{diagnostic}
        case None{}:
          usage_env = checker_scc_run_173(CheckerSccCall_usage_local_env{patterns, values, env, env, globals})
          checker_scc_run_173(CheckerSccCall_check_body_local_uses_result{checker_scc_run_173(CheckerSccCall_check_local_pattern_uses{patterns, body, List.length(&2, Ast.SyntaxPattern, patterns), usage_env, globals}), patterns, values, body, span, env, globals, usage_env})

    case CheckerSccCall_check_body_local_quantity_result{matches, patterns, quantity, values, body, span, env, globals}:
      match matches:
        case True{}: checker_scc_run_173(CheckerSccCall_check_body_local_terms_result{checker_scc_run_173(CheckerSccCall_validate_terms{values, env, globals}), patterns, values, body, span, env, globals})
        case False{}: fail(span, "local binder quantity differs from its pattern quantity", "the declared local quantity", "an inconsistent pattern quantity")

    case CheckerSccCall_check_body_local_length_result{matches, patterns, quantity, values, body, span, env, globals}:
      match matches:
        case True{}: checker_scc_run_173(CheckerSccCall_check_body_local_quantity_result{local_pattern_quantities_match(patterns, quantity), patterns, quantity, values, body, span, env, globals})
        case False{}: fail(span, "local binding names and values have different lengths", "one value per name", "mismatched local bindings")

    case CheckerSccCall_check_body_local{patterns, quantity, values, body, span, env, globals}:
      checker_scc_run_173(CheckerSccCall_check_body_local_length_result{Nat.is_eq(List.length(&2, Ast.SyntaxPattern, patterns), List.length(&2, Ast.SyntaxTerm, values)), patterns, quantity, values, body, span, env, globals})
    case CheckerSccCall_infer_family_sugar_result{lowering, env, globals}:
      match lowering:
        case FamilyTerm{term}: checker_scc_run_173(CheckerSccCall_infer{term, env, globals})
        case FamilyFailure{diagnostic}: InferenceFailure{diagnostic}

    case CheckerSccCall_infer_family_sugar{head, args, plus, span, env, globals}:
      checker_scc_run_173(CheckerSccCall_infer_family_sugar_result{lower_family_sugar(head, args, plus, span, globals), env, globals})
    case CheckerSccCall_infer_application_result_view{view, term, arg, span, env, globals}:
      match view:
        case Ast.TermAll{ _,  _,  _,  domain,  codomain,  _}: infer_application_check(checker_scc_run_173(CheckerSccCall_check_term{arg, env, globals, domain}), term, codomain)
        case _: fail(span, "application target is not a function", "a function type", "a non-function type")

    case CheckerSccCall_infer_application_result{term, arg, function_ty, span, env, globals}:
      checker_scc_run_173(CheckerSccCall_infer_application_result_view{whnf(64n, function_ty, globals), term, arg, span, env, globals})

    case CheckerSccCall_infer_global_adt{found, key, args, term, span, env, globals}:
      match found:
        case Some{global}:
          match global:
            case Global{ _,  _,  _, ty,  _,  _}: checker_scc_run_173(CheckerSccCall_infer_adt_args{args, ty, env, globals, term, span})
        case None{}: fail(span, String.append("unknown datatype ", key), "a declared datatype", key)

    case CheckerSccCall_infer_term_annotation_result{result, inner, term, span, env, globals}:
      match result:
        case Inferred{ checked_ty,  _}: infer_term_annotation_inner(checker_scc_run_173(CheckerSccCall_check_term{inner, env, globals, checked_ty}), checked_ty, term, span)
        case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}

    case CheckerSccCall_infer_equal_type{result, left, right, ty, term, span, env, globals}:
      match result:
        case Inferred{ _,  Ast.TermType{ _, _}}: infer_equal_endpoints(checker_scc_run_173(CheckerSccCall_infer{left, env, globals}), checker_scc_run_173(CheckerSccCall_infer{right, env, globals}), left, right, ty, term, span, globals)
        case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}
        case _: fail(span, "equation annotation is not a type", "a type", "a non-type")
    case CheckerSccCall_infer_application_result_of_function{result, term, arg, span, env, globals}:
      match result:
        case Inferred{ _,  function_ty}: checker_scc_run_173(CheckerSccCall_infer_application_result{term, arg, function_ty, span, env, globals})
        case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}

    case CheckerSccCall_infer_application_unfolded{view, fn, term, arg, span, env, globals}:
      match view:
        case Ast.TermLam{ _,  _,  _, body,  _}: checker_scc_run_173(CheckerSccCall_infer{Core.subst(0n, arg, body), env, globals})
        case _: checker_scc_run_173(CheckerSccCall_infer_application_result_of_function{checker_scc_run_173(CheckerSccCall_infer{application_type_view(fn), env, globals}), term, arg, span, env, globals})

    case CheckerSccCall_infer_application_bang{is_bang, fn, arg, term, span, env, globals}:
      typed_fn = application_type_view(fn)
      Bool.pick(Inference, is_bang, checker_scc_run_173(CheckerSccCall_infer_application_result_of_function{checker_scc_run_173(CheckerSccCall_infer{typed_fn, env, globals}), term, arg, span, env, globals}), checker_scc_run_173(CheckerSccCall_infer_application_unfolded{whnf(64n, typed_fn, globals), fn, term, arg, span, env, globals}))

    case CheckerSccCall_infer_application_valid{valid, fn, arg, term, span, env, globals}:
      Bool.pick(Inference, valid, checker_scc_run_173(CheckerSccCall_infer_application_bang{application_has_bang(fn), fn, arg, term, span, env, globals}), fail(span, "bang marker is only valid on a named application head", "a named function application", "a bang on a non-name"))

    case CheckerSccCall_infer_all_domain{result, quantity, key, ty, body, term, span, env, globals}:
      match result:
        case Inferred{ _,  domain_sort}:
          expected_domain_sort = Ast.TermType{ Ast.TermQuantity{quantity, span}, span}
          Bool.pick(Inference, fits_term(domain_sort, expected_domain_sort, globals), check_infer_term_sort(checker_scc_run_173(CheckerSccCall_infer{body, Binding{key, quantity, ty} <> env, globals}), term, span), fail(span, "function domain has insufficient kind", "the binder quantity's kind", "a smaller kind"))
        case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}

    case CheckerSccCall_infer_let_values{result, keys, values, body, span, env, globals}:
      match result:
        case Some{diagnostic}: InferenceFailure{diagnostic}
        case None{}: checker_scc_run_173(CheckerSccCall_infer_let_lengths{Nat.is_eq(List.length(&2, String, keys), List.length(&2, Ast.SyntaxTerm, values)), values, body, span, env, globals})

    case CheckerSccCall_infer_let_validated{result, values, body, span, env, globals}:
      match result:
        case None{}: checker_scc_run_173(CheckerSccCall_infer{substitute_many(List.reverse(&2, Ast.SyntaxTerm, values), body), env, globals})
        case Some{diagnostic}: InferenceFailure{diagnostic}

    case CheckerSccCall_infer_let_lengths{valid, values, body, span, env, globals}:
      Bool.pick(Inference, valid, checker_scc_run_173(CheckerSccCall_infer_let_validated{checker_scc_run_173(CheckerSccCall_validate_terms{values, env, globals}), values, body, span, env, globals}), fail(span, "let binding names and values have different lengths", "one value per name", "mismatched let"))
    case CheckerSccCall_infer{term, env, globals}:
      match term:
        case Ast.TermVar{key, index, span}: infer_local_reference(lookup_binding(index, env), key, term, span)
        case Ast.TermBang{_, span}: fail(span, "bang marker is only valid on a named application head", "a named function application", "a standalone bang marker")
        case Ast.TermRef{key, span}: infer_global_reference(lookup_global(key, globals), key, term, span)
        case Ast.TermAdt{key, args,  _, span}: checker_scc_run_173(CheckerSccCall_infer_global_adt{lookup_global(key, globals), key, args, term, span, env, globals})
        case Ast.TermFill{head, args, span}: checker_scc_run_173(CheckerSccCall_infer_family_sugar{head, args, False{}, span, env, globals})
        case Ast.TermPlus{head, args, span}: checker_scc_run_173(CheckerSccCall_infer_family_sugar{head, args, True{}, span, env, globals})
        case Ast.TermAnn{ inner, ty, span}: checker_scc_run_173(CheckerSccCall_infer_term_annotation_result{checker_scc_run_173(CheckerSccCall_check_term{ty, env, globals, Ast.TermType{ Ast.TermQuantity{ Ast.QOne{}, span}, span}}), inner, term, span, env, globals})
        case Ast.TermTemplate{ _, span}: fail(span, "template term must be expanded before semantic checking", "an expanded term", "an unexpanded template")
        case Ast.TermType{kind, span}: infer_type_annotation_result(checker_scc_run_173(CheckerSccCall_infer{kind, env, globals}), term, span)
        case Ast.TermQuantity{ _,  _}: Inferred{term,  Ast.TermQuant{}}
        case Ast.TermQuant{}: Inferred{term,  Ast.TermType{ Ast.TermQuantity{ Ast.QOne{},  Ast.SpanOf{ "",  0n,  0n}},  Ast.SpanOf{ "",  0n,  0n}}}
        case Ast.TermMin{left, right, span}: infer_min_results(checker_scc_run_173(CheckerSccCall_infer{left, env, globals}), checker_scc_run_173(CheckerSccCall_infer{right, env, globals}), term, span)
        case Ast.TermAll{quantity, key, _, ty, body, span}: checker_scc_run_173(CheckerSccCall_infer_all_domain{checker_scc_run_173(CheckerSccCall_infer{ty, env, globals}), quantity, key, ty, body, term, span, env, globals})
        case Ast.TermApp{fn, arg, span}: checker_scc_run_173(CheckerSccCall_infer_application_valid{application_bangs_valid(fn) && application_argument_bangs_valid(arg), fn, arg, term, span, env, globals})
        case Ast.TermEqual{left, right, ty, span}: checker_scc_run_173(CheckerSccCall_infer_equal_type{checker_scc_run_173(CheckerSccCall_infer{ty, env, globals}), left, right, ty, term, span, env, globals})
        case Ast.TermLet{keys,  _, quantities, values, body, span}:
          usage_env = checker_scc_run_173(CheckerSccCall_usage_let_env{keys, quantities, values, env, env, globals})
          checker_scc_run_173(CheckerSccCall_infer_let_values{checker_scc_run_173(CheckerSccCall_check_local_quantities{keys, quantities, body, List.length(&2, String, keys), span, usage_env, globals}), keys, values, body, span, env, globals})
        case Ast.BodyLocal{patterns, quantity, values, body, span}: checker_scc_run_173(CheckerSccCall_check_body_local{patterns, quantity, values, body, span, env, globals})
        case Ast.BodyReply{term,  _}: checker_scc_run_173(CheckerSccCall_infer{term, env, globals})
        case Ast.TermHole{key, span}: fail(span, String.append("unsolved hole ", key), "a complete term", "a hole")
        case _: fail(term_span(term), "term form cannot infer", "an inferable term", "an annotated expression")

    case CheckerSccCall_check_match_head_result{result, matched, default_ty, whole, expected, env, globals}:
      match result:
        case Inferred{ _,  _}: check_match_default_result(checker_scc_run_173(CheckerSccCall_check_term{matched, env, globals, default_ty}), whole, expected)
        case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}

    case CheckerSccCall_check_match_applied{applied, key, head, matched, span, expected, env, globals, whole, family, parameters, refs, quantity, scrutinee, index, body, found_family}:
      match applied:
        case Some{field_ty}:
          branch_ty = mat_branch_goal(field_ty, body, key, Nil{}, 0n, span, globals)
          next_refs = List.append(&2, String, refs, [canonical_name(key, globals)])
          residual = Ast.TermAdt{ family,  parameters,  next_refs, span}
          default_ty = Ast.TermAll{quantity,  scrutinee, index,  residual, body, span}
          checker_scc_run_173(CheckerSccCall_check_match_head_result{checker_scc_run_173(CheckerSccCall_check_term{head, env, globals, branch_ty}), matched, default_ty, whole, expected, env, globals})
        case None{}: fail(span, "constructor parameters do not match the datatype", "matching parameter telescope", "incompatible parameters")

    case CheckerSccCall_check_match_family_equal{matches, found_family, key, head, matched, span, expected, env, globals, whole, family, parameters, refs, quantity, scrutinee, index, body, constructor_ty}:
      Bool.pick(Inference, matches, checker_scc_run_173(CheckerSccCall_check_match_applied{apply_prefix(parameters, constructor_ty), key, head, matched, span, expected, env, globals, whole, family, parameters, refs, quantity, scrutinee, index, body, found_family}), fail(span, "constructor belongs to another datatype", family, found_family))

    case CheckerSccCall_check_match_family_result{found, key, head, matched, span, expected, env, globals, whole, family, family_key, parameters, refs, quantity, scrutinee, index, body, constructor_ty}:
      match found:
        case Some{found_family}: checker_scc_run_173(CheckerSccCall_check_match_family_equal{String.eq(found_family, family_key), found_family, key, head, matched, span, expected, env, globals, whole, family, parameters, refs, quantity, scrutinee, index, body, constructor_ty})
        case None{}: fail(span, "match branch is not a constructor", "a constructor of the scrutinee datatype", key)

    case CheckerSccCall_check_match_global{constructor, key, head, matched, span, expected, env, globals, whole, family, family_key, parameters, refs, quantity, scrutinee, index, body}:
      match constructor:
        case Global{ _,  _,  _,  constructor_ty,  _,  _}: checker_scc_run_173(CheckerSccCall_check_match_family_result{constructor_family(constructor_ty, globals), key, head, matched, span, expected, env, globals, whole, family, family_key, parameters, refs, quantity, scrutinee, index, body, constructor_ty})

    case CheckerSccCall_check_match_constructor{found, key, head, matched, span, expected, env, globals, whole, family, family_key, parameters, refs, quantity, scrutinee, index, body}:
      match found:
        case Some{constructor}: checker_scc_run_173(CheckerSccCall_check_match_global{constructor, key, head, matched, span, expected, env, globals, whole, family, family_key, parameters, refs, quantity, scrutinee, index, body})
        case None{}: fail(span, String.append("unknown constructor ", key), "a declared constructor", key)

    case CheckerSccCall_check_match_unexcluded{excluded, key, head, matched, span, expected, env, globals, whole, family, family_key, parameters, refs, quantity, scrutinee, index, body}:
      match excluded:
        case True{}: fail(span, "constructor is already excluded from this match", "an unmatched constructor", key)
        case False{}: checker_scc_run_173(CheckerSccCall_check_match_constructor{lookup_global(key, globals), key, head, matched, span, expected, env, globals, whole, family, family_key, parameters, refs, quantity, scrutinee, index, body})

    case CheckerSccCall_check_match_input_view{view, key, head, matched, span, expected, env, globals, whole, quantity, scrutinee, index, body}:
      match view:
        case Ast.TermAdt{ family,  parameters, refs,  _}:
          checker_scc_run_173(CheckerSccCall_check_match_unexcluded{has_canonical_name(key, refs, globals), key, head, matched, span, expected, env, globals, whole, family, resolve_family_key(family, globals), parameters, refs, quantity, scrutinee, index, body})
        case _: fail(span, "match scrutinee is not a datatype", "a datatype", "a non-datatype")

    case CheckerSccCall_check_match_goal_view{view, key, head, matched, span, expected, env, globals, whole}:
      match view:
        case Ast.TermAll{quantity,  scrutinee, index,  input_ty, body,  _}:
          checker_scc_run_173(CheckerSccCall_check_match_input_view{whnf(64n, input_ty, globals), key, head, matched, span, expected, env, globals, whole, quantity, scrutinee, index, body})
        case _: fail(span, "match requires a function goal", "a dependent function type", "a non-function type")

    case CheckerSccCall_check_match{key, head, matched, span, expected, env, globals, whole}:
      checker_scc_run_173(CheckerSccCall_check_match_goal_view{whnf(64n, expected, globals), key, head, matched, span, expected, env, globals, whole})


    case CheckerSccCall_check_body_case_body_result{result, rest, family, parameters, scrutinee_ty, scrutinee_index, expected, whole, env, globals, removed, span, key}:
      match result:
        case Inferred{ _,  _}: checker_scc_run_173(CheckerSccCall_check_body_cases{rest, family, parameters, scrutinee_ty, scrutinee_index, expected, whole, env, globals, canonical_name(key, globals) <> removed, span})
        case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}

    case CheckerSccCall_check_body_case_pattern_result{result, pattern, rest, family, parameters, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, removed, span, key}:
      match result:
        case PatternTypeFailure{diagnostic}: InferenceFailure{diagnostic}
        case PatternTyped{ branch_env,  _}:
          branch_value = pattern_value(pattern, List.length(&2, Binding, env) + Core.pattern_depth(pattern))
          branch_expected = replace_match_expected(scrutinee_index, Core.pattern_depth(pattern), expected, branch_value)
          checker_scc_run_173(CheckerSccCall_check_body_case_body_result{checker_scc_run_173(CheckerSccCall_check_term{body, branch_env, globals, branch_expected}), rest, family, parameters, scrutinee_ty, scrutinee_index, expected, whole, env, globals, removed, span, key})

    case CheckerSccCall_check_body_case_constructor_uses{valid, pattern, rest, family, parameters, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, removed, span, key, pattern_span}:
      Bool.pick(Inference, valid,
        checker_scc_run_173(CheckerSccCall_check_body_case_pattern_result{check_pattern_typed(pattern, Ast.TermAdt{ family,  parameters,  removed,  pattern_span}, Some{optional_source_quantity(scrutinee_index, env)}, List.length(&2, Binding, env) + Core.pattern_depth(pattern), env, globals), pattern, rest, family, parameters, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, removed, span, key}),
        fail(pattern_span, "invalid use quantity for pattern binder", "within the pattern binder quantity", "too many uses"))

    case CheckerSccCall_check_body_case_constructor_seen{seen, pattern, rest, family, parameters, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, removed, span, key, pattern_span}:
      Bool.pick(Inference, seen, fail(pattern_span, "constructor appears twice in match", "an unmatched constructor", key), checker_scc_run_173(CheckerSccCall_check_body_case_constructor_uses{checker_scc_run_173(CheckerSccCall_pattern_uses_valid{pattern, body, Core.pattern_depth(pattern), globals}), pattern, rest, family, parameters, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, removed, span, key, pattern_span}))

    case CheckerSccCall_check_body_case_catchall_usage{valid, key, quantity, pattern, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, pattern_span}:
      Bool.pick(Inference, valid,
        check_body_case_catchall_result(checker_scc_run_173(CheckerSccCall_check_term{body, Binding{key, quantity,  scrutinee_ty} <> env, globals, replace_match_expected(scrutinee_index, 1n, expected, pattern_value(pattern, List.length(&2, Binding, env) + 1n))}), whole, expected),
        fail(pattern_span, String.append("invalid use quantity for ", key), "within the pattern binder quantity", "too many uses"))

    case CheckerSccCall_check_body_case_catchall{rest, key, quantity, pattern, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, pattern_span}:
      match rest:
        case Nil{}: checker_scc_run_173(CheckerSccCall_check_body_case_catchall_usage{Bool.and(optional_root_pattern_quantity_allowed(pattern, scrutinee_index, env), quantity_fits(checker_scc_run_173(CheckerSccCall_use_count_with_globals{body, 0n, 0n, globals}), quantity)), key, quantity, pattern, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, pattern_span})
        case _: fail(pattern_span, "catch-all pattern must be last", "the final match case", "a following case")

    case CheckerSccCall_check_body_case_pattern{pattern, rest, family, parameters, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, removed, span, pattern_span}:
      match pattern:
        case Ast.PatternCtr{key,  _,  pattern_span}: checker_scc_run_173(CheckerSccCall_check_body_case_constructor_seen{has_canonical_name(key, removed, globals), pattern, rest, family, parameters, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, removed, span, key, pattern_span})
        case Ast.PatternVar{key, _, quantity, pattern_span}: checker_scc_run_173(CheckerSccCall_check_body_case_catchall{rest, key, quantity, pattern, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, pattern_span})

    case CheckerSccCall_check_body_case_term{case_term, rest, family, parameters, scrutinee_ty, scrutinee_index, expected, whole, env, globals, removed, span}:
      match case_term:
        case Ast.BodyCase{ +pattern <> Nil{}, body,  case_span}: checker_scc_run_173(CheckerSccCall_check_body_case_pattern{pattern, rest, family, parameters, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, removed, span, case_span})
        case _: fail(span, "invalid match case", "a checked case pattern", "an invalid case")

    case CheckerSccCall_check_body_cases{cases, family, parameters, scrutinee_ty, scrutinee_index, expected, whole, env, globals, removed, span}:
      match cases:
        case Nil{}: Bool.pick(Inference, residual_has_reachable_constructor(family, parameters, removed, span, globals), fail(span, "match is not exhaustive", "all remaining constructors", "an uncovered constructor"), Inferred{ whole,  expected})
        case +case_term <> rest: checker_scc_run_173(CheckerSccCall_check_body_case_term{case_term, rest, family, parameters, scrutinee_ty, scrutinee_index, expected, whole, env, globals, removed, span})

    case CheckerSccCall_check_body_match_type_view{view, scrutinee, cases, ty, span, expected, env, globals, whole}:
      match view:
        case Ast.TermAdt{key,  parameters, refs,  _}:
          check_body_cases_result(checker_scc_run_173(CheckerSccCall_check_body_cases{cases, resolve_family_key(key, globals), parameters, ty, scrutinee_variable_index(scrutinee, globals), expected, whole, env, globals, refs, span}), cases, ty, span, expected, env, globals, whole)
        case _: fail(span, "match scrutinee is not a datatype", "a datatype", "a non-datatype")

    case CheckerSccCall_check_body_match_type{scrutinee, cases, ty, span, expected, env, globals, whole}:
      checker_scc_run_173(CheckerSccCall_check_body_match_type_view{whnf(64n, ty, globals), scrutinee, cases, ty, span, expected, env, globals, whole})

    case CheckerSccCall_infer_scrutinee_types_result{result, rest, env, globals}:
      match result:
        case Inferred{ _, ty}: infer_scrutinee_types_rest(checker_scc_run_173(CheckerSccCall_infer_scrutinee_types{rest, env, globals}), ty)
        case InferenceFailure{diagnostic}: ScrutineeTypeFailure{diagnostic}

    case CheckerSccCall_infer_scrutinee_types{scrutinees, env, globals}:
      match scrutinees:
        case Nil{}: ScrutineeTypes{ Nil{}}
        case +scrutinee <> rest:
          checker_scc_run_173(CheckerSccCall_infer_scrutinee_types_result{checker_scc_run_173(CheckerSccCall_infer{scrutinee, env, globals}), rest, env, globals})

    case CheckerSccCall_pattern_uses_valid{pattern, body, remaining, globals}:
      match pattern:
        case Ast.PatternVar{ _,  _, quantity,  _}:
          quantity_fits(checker_scc_run_173(CheckerSccCall_use_count_with_globals{body, remaining - 1n, 0n, globals}), quantity)
        case Ast.PatternCtr{ _, fields,  _}: checker_scc_run_173(CheckerSccCall_pattern_uses_valid_list{fields, body, remaining, globals})

    case CheckerSccCall_pattern_uses_valid_list{patterns, body, remaining, globals}:
      match patterns:
        case Nil{}: True{}
        case +pattern <> rest:
          Bool.pick(Bool, checker_scc_run_173(CheckerSccCall_pattern_uses_valid{pattern, body, remaining, globals}), checker_scc_run_173(CheckerSccCall_pattern_uses_valid_list{rest, body, remaining - Core.pattern_depth(pattern), globals}), False{})

    case CheckerSccCall_check_body_pattern_vector_typed{result, pattern_rest, type_rest, scrutinee_rest, pattern, body, expected, env, globals, remaining, offset, span, source_index, added}:
      match result:
        case PatternTypeFailure{diagnostic}: InferenceFailure{diagnostic}
        case PatternTyped{ next_env,  _}:
          branch_value = pattern_value(pattern, List.length(&2, Binding, env) + remaining)
          branch_expected = replace_match_expected(maybe_shift_index(source_index, offset), added, expected, branch_value)
          branch_types = replace_match_types(maybe_shift_index(source_index, offset), added, type_rest, branch_value)
          checker_scc_run_173(CheckerSccCall_check_body_pattern_vector{pattern_rest, branch_types, scrutinee_rest, body, branch_expected, next_env, globals, remaining - added, offset + added, span})

    case CheckerSccCall_check_body_pattern_vector{patterns, types, scrutinees, body, expected, env, globals, remaining, offset, span}:
      match patterns types scrutinees:
        case Nil{} Nil{} Nil{}: checker_scc_run_173(CheckerSccCall_check_term{body, env, globals, expected})
        case +pattern <> pattern_rest +ty <> type_rest +scrutinee <> scrutinee_rest:
          added = Core.pattern_depth(pattern)
          source_index = scrutinee_variable_index(scrutinee, globals)
          valid = Bool.and(optional_root_pattern_quantity_allowed(pattern, maybe_shift_index(source_index, offset), env), checker_scc_run_173(CheckerSccCall_pattern_uses_valid{pattern, body, remaining, globals}))
          Bool.pick(Inference, valid, checker_scc_run_173(CheckerSccCall_check_body_pattern_vector_typed{check_pattern_typed(pattern, ty, Some{optional_source_quantity(maybe_shift_index(source_index, offset), env)}, List.length(&2, Binding, env) + remaining, env, globals), pattern_rest, type_rest, scrutinee_rest, pattern, body, expected, env, globals, remaining, offset, span, source_index, added}), fail(pattern_source_span(pattern), "invalid use quantity for pattern binder", "within the pattern binder quantity", "too many uses"))
    case CheckerSccCall_check_body_pattern_rows_result{result, rest, types, scrutinees, expected, whole, env, globals, span}:
      match result:
        case Inferred{ _,  _}: checker_scc_run_173(CheckerSccCall_check_body_pattern_rows{rest, types, scrutinees, expected, whole, env, globals, span})
        case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}

    case CheckerSccCall_check_body_pattern_rows_catchall{valid, patterns, body, case_span, rest, types, scrutinees, expected, whole, env, globals, span}:
      Bool.pick(Inference, valid, fail(case_span, "catch-all pattern must be last", "the final match case", "a following case"), checker_scc_run_173(CheckerSccCall_check_body_pattern_rows_result{checker_scc_run_173(CheckerSccCall_check_body_pattern_vector{patterns, types, scrutinees, body, expected, env, globals, Core.pattern_list_depth(patterns), 0n, case_span}), rest, types, scrutinees, expected, whole, env, globals, span}))

    case CheckerSccCall_check_body_pattern_rows_length{valid, patterns, body, case_span, rest, types, scrutinees, expected, whole, env, globals, span}:
      Bool.pick(Inference, valid, checker_scc_run_173(CheckerSccCall_check_body_pattern_rows_catchall{Bool.and(all_variable_patterns(patterns), Bool.not(List.is_empty(&2, Ast.SyntaxTerm, rest))), patterns, body, case_span, rest, types, scrutinees, expected, whole, env, globals, span}), fail(case_span, "case pattern count differs from scrutinee count", "one pattern per scrutinee", "a mismatched pattern vector"))

    case CheckerSccCall_check_body_pattern_rows_case{case_term, rest, types, scrutinees, expected, whole, env, globals, span}:
      match case_term:
        case Ast.BodyCase{patterns, body,  case_span}: checker_scc_run_173(CheckerSccCall_check_body_pattern_rows_length{Nat.is_eq(List.length(&2, Ast.SyntaxPattern, patterns), List.length(&2, Ast.SyntaxTerm, types)), patterns, body, case_span, rest, types, scrutinees, expected, whole, env, globals, span})
        case _: fail(span, "invalid match case", "a checked case pattern", "an invalid case")

    case CheckerSccCall_check_body_pattern_rows{cases, types, scrutinees, expected, whole, env, globals, span}:
      match cases:
        case Nil{}: Inferred{ whole,  expected}
        case +case_term <> rest: checker_scc_run_173(CheckerSccCall_check_body_pattern_rows_case{case_term, rest, types, scrutinees, expected, whole, env, globals, span})

    case CheckerSccCall_check_body_match_many_types_result{result, scrutinees, cases, span, expected, env, globals, whole}:
      match result:
        case ScrutineeTypeFailure{diagnostic}: InferenceFailure{diagnostic}
        case ScrutineeTypes{types}: check_body_match_many_rows_result(checker_scc_run_173(CheckerSccCall_check_body_pattern_rows{cases, types, scrutinees, expected, whole, env, globals, span}), types, scrutinees, cases, span, expected, env, globals, whole)

    case CheckerSccCall_check_body_match_many{scrutinees, cases, span, expected, env, globals, whole}:
      checker_scc_run_173(CheckerSccCall_check_body_match_many_types_result{checker_scc_run_173(CheckerSccCall_infer_scrutinee_types{scrutinees, env, globals}), scrutinees, cases, span, expected, env, globals, whole})

    case CheckerSccCall_check_body_match_first_result{result, scrutinee, cases, span, expected, env, globals, whole}:
      match result:
        case Inferred{ _, ty}: checker_scc_run_173(CheckerSccCall_check_body_match_type{scrutinee, cases, ty, span, expected, env, globals, whole})
        case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}

    case CheckerSccCall_check_body_match_scrutinees{scrutinees, cases, span, expected, env, globals, whole}:
      match scrutinees:
        case Nil{}: fail(span, "match requires at least one scrutinee", "a nonempty scrutinee list", "an empty match")
        case +scrutinee <> rest:
          match rest:
            case Nil{}: checker_scc_run_173(CheckerSccCall_check_body_match_first_result{checker_scc_run_173(CheckerSccCall_infer{scrutinee, env, globals}), scrutinee, cases, span, expected, env, globals, whole})
            case _: checker_scc_run_173(CheckerSccCall_check_body_match_many{scrutinees, cases, span, expected, env, globals, whole})

    case CheckerSccCall_check_body_match_valid{valid, scrutinees, cases, span, expected, env, globals, whole}:
      match valid:
        case False{}: fail(span, "match scrutinees must be parameters or bound fields", "a parameter or field variable", "a computed, constructed, or local value")
        case True{}: checker_scc_run_173(CheckerSccCall_check_body_match_scrutinees{scrutinees, cases, span, expected, env, globals, whole})

    case CheckerSccCall_check_body_match{scrutinees, cases, span, expected, env, globals, whole}:
      checker_scc_run_173(CheckerSccCall_check_body_match_valid{match_scrutinees_valid(scrutinees, env), scrutinees, cases, span, expected, env, globals, whole})
    case CheckerSccCall_rewrite_body_type_view{view, body, body_ty, span, expected, env, globals, whole}:
      match view:
        case Ast.TermEqual{ a,  b,  _,  _}: Bool.pick(Inference, equal_term(a, b, globals), rewrite_body_result(checker_scc_run_173(CheckerSccCall_check_term{body, env, globals, body_ty}), whole, expected), fail(span, "rewrite reflexivity goal is not reflexive", "equal endpoints", "unequal endpoints"))
        case _: rewrite_body_result(checker_scc_run_173(CheckerSccCall_check_term{body, env, globals, body_ty}), whole, expected)

    case CheckerSccCall_rewrite_left_applied_result{applied, body, span, expected, env, globals, whole}:
      match applied:
        case Some{body_ty}: checker_scc_run_173(CheckerSccCall_rewrite_body_type_view{whnf(64n, body_ty, globals), body, body_ty, span, expected, env, globals, whole})
        case None{}: fail(span, "rewrite predicate cannot apply to the left endpoint", "a predicate application", "an invalid application")

    case CheckerSccCall_rewrite_fits_result{fits, left, p_ty, body, span, expected, env, globals, whole}:
      Bool.pick(Inference, fits, checker_scc_run_173(CheckerSccCall_rewrite_left_applied_result{apply_prefix([left, Ast.TermRefl{span}], p_ty), body, span, expected, env, globals, whole}), fail(span, "rewrite result does not fit the goal", "the expected type", "an incompatible rewritten type"))

    case CheckerSccCall_rewrite_equation_applied_result{applied, right, left, p_ty, body, span, expected, env, globals, whole}:
      match applied:
        case Some{result_ty}: checker_scc_run_173(CheckerSccCall_rewrite_fits_result{fits_term(result_ty, expected, globals), left, p_ty, body, span, expected, env, globals, whole})
        case None{}: fail(span, "rewrite predicate cannot apply to equation", "a predicate application", "an invalid application")

    case CheckerSccCall_rewrite_proof_result{result, right, left, checked_equation, p_ty, body, span, expected, env, globals, whole}:
      match result:
        case Inferred{ _,  _}: checker_scc_run_173(CheckerSccCall_rewrite_equation_applied_result{apply_prefix([right, checked_equation], p_ty), right, left, p_ty, body, span, expected, env, globals, whole})
        case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}

    case CheckerSccCall_rewrite_equation_view{view, checked_equation, proof, body, span, expected, env, globals, whole}:
      match view:
        case Ast.TermEqual{left, right, ty,  _}:
          x = Ast.TermVar{ "x",  0n, span}
          shifted_left = Core.shift(0n, 1n, left)
          shifted_ty = Core.shift(0n, 1n, ty)
          evidence_ty = Ast.TermEqual{ shifted_left,  x,  shifted_ty, span}
          sort = Ast.TermType{ Ast.TermQuantity{ Ast.QOne{}, span}, span}
          p_ty = Ast.TermAll{ Ast.QOne{}, "x", 0n, ty, Ast.TermAll{ Ast.QOne{},  "e",  0n,  evidence_ty,  sort, span}, span}
          checker_scc_run_173(CheckerSccCall_rewrite_proof_result{checker_scc_run_173(CheckerSccCall_check_term{proof, env, globals, p_ty}), right, left, checked_equation, p_ty, body, span, expected, env, globals, whole})
        case _: fail(span, "rewrite evidence is not an equation", "an equation {a == b : T}", "a non-equation")

    case CheckerSccCall_rewrite_equation_result{result, proof, body, span, expected, env, globals, whole}:
      match result:
        case Inferred{ checked_equation,  equation_ty}: checker_scc_run_173(CheckerSccCall_rewrite_equation_view{whnf(64n, equation_ty, globals), checked_equation, proof, body, span, expected, env, globals, whole})
        case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}

    case CheckerSccCall_check_rewrite{equation, proof, body, span, expected, env, globals, whole}:
      checker_scc_run_173(CheckerSccCall_rewrite_equation_result{checker_scc_run_173(CheckerSccCall_infer{equation, env, globals}), proof, body, span, expected, env, globals, whole})

    case CheckerSccCall_lambda_domain_valid{domain, span, env, globals}:
      lambda_domain_valid_result(checker_scc_run_173(CheckerSccCall_infer{domain, env, globals}), span, globals)

    case CheckerSccCall_check_lambda_domain_result{valid, annotated, key, body, quantity, domain, codomain, span, expected, env, globals}:
      Bool.pick(Inference, valid, fail(span, "promoted lambda domain has insufficient kind", "a domain valid at Kind(&2)", "a lower-kind domain"), (checker_scc_arg_111481_0 => checker_scc_run_173(CheckerSccCall_check_lambda_body_result{annotated, key, body, quantity, domain, codomain, span, expected, env, globals, checker_scc_arg_111481_0})))

    case CheckerSccCall_check_lambda_promotes_result{promotes, annotated, key, body, quantity, domain, codomain, span, expected, env, globals}:
      Bool.pick(Inference, promotes, checker_scc_run_173(CheckerSccCall_check_lambda_domain_result{checker_scc_run_173(CheckerSccCall_lambda_domain_valid{domain, span, env, globals}), annotated, key, body, quantity, domain, codomain, span, expected, env, globals}), (checker_scc_arg_112085_0 => checker_scc_run_173(CheckerSccCall_check_lambda_body_result{annotated, key, body, quantity, domain, codomain, span, expected, env, globals, checker_scc_arg_112085_0})))

    case CheckerSccCall_check_lambda_quantity_result{found, annotated, key, body, domain, codomain, span, expected_quantity, expected, env, globals}:
      match found:
        case None{}: fail(span, "lambda quantity annotation does not match its function type", "the expected binder quantity (or an explicit Many promotion)", "an incompatible lambda quantity")
        case Some{quantity}: checker_scc_run_173(CheckerSccCall_check_lambda_promotes_result{lambda_promotes(annotated, expected_quantity), annotated, key, body, quantity, domain, codomain, span, expected, env, globals})

    case CheckerSccCall_check_lambda_body{annotated, key, body, expected_quantity, domain, codomain, span, expected, env, globals}:
      checker_scc_run_173(CheckerSccCall_check_lambda_quantity_result{lambda_quantity(annotated, expected_quantity), annotated, key, body, domain, codomain, span, expected_quantity, expected, env, globals})

    case CheckerSccCall_check_lambda_body_result{result, annotated, key, body, quantity, domain, codomain, span, expected, env, globals}:
      match result:
        case Inferred{ checked,  _}: check_lambda_body_use(quantity_fits(checker_scc_run_173(CheckerSccCall_use_count_with_expected{body, 0n, Binding{key, quantity,  domain} <> env, globals, codomain}), quantity), checked, annotated, key, span, expected)
        case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}

    case CheckerSccCall_check_term_lambda_view{view, annotated, key, body, span, expected, env, globals}:
      match view:
        case Ast.TermAll{quantity,  _,  _, ty,  codomain,  _}: checker_scc_run_173(CheckerSccCall_check_lambda_body{annotated, key, body, quantity, ty, codomain, span, expected, env, globals})
        case _: fail(span, "lambda requires a function type", "a function type", "a non-function type")

    case CheckerSccCall_check_term_constructor_apply{found, key, args, span, parameters, expected, env, globals, term}:
      match found:
        case Some{field_ty}: checker_scc_run_173(CheckerSccCall_check_ctr_fields{args, field_ty, expected, env, globals, term, span})
        case None{}: fail(span, "constructor parameter telescope does not match datatype", "constructor parameters", "an incompatible telescope")

    case CheckerSccCall_check_term_constructor_global{global, key, args, span, parameters, expected, env, globals, term}:
      match global:
        case Global{ _,  _,  _, ty,  _,  _}: checker_scc_run_173(CheckerSccCall_check_term_constructor_apply{apply_prefix(parameters, ty), key, args, span, parameters, expected, env, globals, term})

    case CheckerSccCall_check_term_constructor_global_result{found, key, args, span, parameters, expected, env, globals, term}:
      match found:
        case Some{global}: checker_scc_run_173(CheckerSccCall_check_term_constructor_global{global, key, args, span, parameters, expected, env, globals, term})
        case None{}: fail(span, String.append("unknown constructor ", key), "a declared constructor", key)

    case CheckerSccCall_check_term_constructor_allowed{allowed, key, args, span, parameters, refs, expected, env, globals, term}:
      match allowed:
        case True{}: fail(span, "constructor is excluded from this datatype goal", "a remaining constructor", key)
        case False{}: checker_scc_run_173(CheckerSccCall_check_term_constructor_global_result{lookup_global(key, globals), key, args, span, parameters, expected, env, globals, term})

    case CheckerSccCall_check_term_constructor_view{view, key, args, span, expected, env, globals, term}:
      match view:
        case Ast.TermAdt{ _,  parameters, refs,  _}: checker_scc_run_173(CheckerSccCall_check_term_constructor_allowed{has_canonical_name(key, refs, globals), key, args, span, parameters, refs, expected, env, globals, term})
        case _: fail(span, "constructor requires a datatype goal", "a datatype", "a non-datatype type")

    case CheckerSccCall_check_term{term, env, globals, expected}:
      match term:
        case Ast.TermHole{key, span}:
          Bool.pick(Inference, String.eq(key, "TODO"), Inferred{term,  expected}, fail(span, String.append("unsolved hole ", key), "a complete term", "a hole"))
        case Ast.TermLam{ annotated, key,  _, body, span}:
          checker_scc_run_173(CheckerSccCall_check_term_lambda_view{whnf(64n, expected, globals), annotated, key, body, span, expected, env, globals})
        case Ast.TermCtr{key, args, span}:
          checker_scc_run_173(CheckerSccCall_check_term_constructor_view{whnf(64n, expected, globals), key, args, span, expected, env, globals, term})
        case Ast.TermMat{key, head, matched, span}:
          checker_scc_run_173(CheckerSccCall_check_match{key, head, matched, span, expected, env, globals, term})
        case Ast.TermAbsurd{span}:
          check_term_absurd_view(whnf(64n, expected, globals), term, span, expected, globals)
        case Ast.TermRefl{span}:
          check_term_refl_view(whnf(64n, expected, globals), term, span, expected, globals)
        case Ast.TermRewrite{equation, proof, body, span}:
          checker_scc_run_173(CheckerSccCall_check_rewrite{equation, proof, body, span, expected, env, globals, term})
        case Ast.BodyMatch{scrutinees, cases, span}: checker_scc_run_173(CheckerSccCall_check_body_match{scrutinees, cases, span, expected, env, globals, term})
        case Ast.BodyReply{term,  _}: checker_scc_run_173(CheckerSccCall_check_term{term, env, globals, expected})
        case _:
          check_term_inferred(checker_scc_run_173(CheckerSccCall_infer{term, env, globals}), expected, term, globals)

    case CheckerSccCall_usage_let_env{keys, quantities, values, value_env, acc, globals}:
      match keys quantities values:
        case Nil{} Nil{} Nil{}: acc
        case +key <> key_rest +quantity <> quantity_rest +value <> value_rest:
          ty = usage_inferred_type(checker_scc_run_173(CheckerSccCall_infer{value, value_env, globals}), term_span(value))
          checker_scc_run_173(CheckerSccCall_usage_let_env{key_rest, quantity_rest, value_rest, value_env, Binding{key, quantity, ty} <> acc, globals})
        case _ _ _: acc

    case CheckerSccCall_usage_local_env{patterns, values, value_env, acc, globals}:
      match patterns values:
        case Nil{} Nil{}: acc
        case Ast.PatternVar{key, _, quantity, _} <> pattern_rest +value <> value_rest:
          ty = usage_inferred_type(checker_scc_run_173(CheckerSccCall_infer{value, value_env, globals}), term_span(value))
          checker_scc_run_173(CheckerSccCall_usage_local_env{pattern_rest, value_rest, value_env, Binding{key, quantity, ty} <> acc, globals})
        case Ast.PatternCtr{_, _, _} <> _ +_ <> _: acc
        case _ _: acc

    case CheckerSccCall_term_usage_map_constructor_view{view, arg, rest, args, ty, depth, env, globals}:
      match view:
        case Ast.TermAll{quantity,  _,  _,  domain, body,  _}:
          arg_usage = checker_scc_run_173(CheckerSccCall_constructor_argument_usage{quantity, arg, domain, depth, env, globals})
          usage_merge(arg_usage, checker_scc_run_173(CheckerSccCall_term_usage_map_constructor_args{rest, Core.subst(0n, arg, body), depth, env, globals}), False{})
        case _: checker_scc_run_173(CheckerSccCall_term_usage_map_list{args, depth, env, globals})

    case CheckerSccCall_constructor_argument_usage{quantity, arg, domain, depth, env, globals}:
      match quantity:
        case Ast.QZero{}: Nil{}
        case _: checker_scc_run_173(CheckerSccCall_term_usage_map{arg, depth, env, globals, Some{domain}})

    case CheckerSccCall_term_usage_map_constructor_args{args, ty, depth, env, globals}:
      match args:
        case Nil{}: Nil{}
        case +arg <> rest: checker_scc_run_173(CheckerSccCall_term_usage_map_constructor_view{whnf(64n, ty, globals), arg, rest, args, ty, depth, env, globals})

    case CheckerSccCall_term_usage_map_lambda_quantity{found, key, body, span, depth, env, globals, domain, codomain}:
      match found:
        case Some{quantity}: checker_scc_run_173(CheckerSccCall_term_usage_map{body, depth + 1n, Binding{key, quantity,  domain} <> env, globals, Some{codomain}})
        case None{}:
          unknown = usage_unknown_type(span)
          checker_scc_run_173(CheckerSccCall_term_usage_map{body, depth + 1n, Binding{key,  Ast.QMany{},  unknown} <> env, globals, None{}})

    case CheckerSccCall_term_usage_map_lambda_view{view, annotated, key, body, span, depth, env, globals}:
      match view:
        case Ast.TermAll{ expected_quantity,  _,  _,  domain,  codomain,  _}:
          checker_scc_run_173(CheckerSccCall_term_usage_map_lambda_quantity{lambda_quantity(annotated, expected_quantity), key, body, span, depth, env, globals, domain, codomain})
        case _:
          unknown = usage_unknown_type(span)
          checker_scc_run_173(CheckerSccCall_term_usage_map{body, depth + 1n, Binding{key,  Ast.QMany{},  unknown} <> env, globals, None{}})

    case CheckerSccCall_term_usage_map_lambda_expected{expected, annotated, key, body, span, depth, env, globals}:
      match expected:
        case Some{ expected_type}: checker_scc_run_173(CheckerSccCall_term_usage_map_lambda_view{whnf(64n, expected_type, globals), annotated, key, body, span, depth, env, globals})
        case None{}:
          unknown = usage_unknown_type(span)
          checker_scc_run_173(CheckerSccCall_term_usage_map{body, depth + 1n, Binding{key,  Ast.QMany{},  unknown} <> env, globals, None{}})

    case CheckerSccCall_term_usage_map_application_quantity{found, fn, arg, depth, env, globals}:
      match found:
        case Some{ Ast.QZero{}}: checker_scc_run_173(CheckerSccCall_term_usage_map{fn, depth, env, globals, None{}})
        case _:
          arg_expected = term_usage_map_argument_expected(function_type_of(fn, env, globals), globals)
          usage_merge(checker_scc_run_173(CheckerSccCall_term_usage_map{fn, depth, env, globals, None{}}), checker_scc_run_173(CheckerSccCall_term_usage_map{arg, depth, env, globals, arg_expected}), False{})

    case CheckerSccCall_term_usage_map_family_result{result, head, args, depth, env, globals, expected}:
      match result:
        case FamilyTerm{term}: checker_scc_run_173(CheckerSccCall_term_usage_map{term, depth, env, globals, expected})
        case FamilyFailure{ _}: usage_merge(checker_scc_run_173(CheckerSccCall_term_usage_map{head, depth, env, globals, None{}}), checker_scc_run_173(CheckerSccCall_term_usage_map_list{args, depth, env, globals}), False{})

    case CheckerSccCall_term_usage_map_constructor_result{found, key, args, depth, env, globals}:
      match found:
        case Some{field_ty}: checker_scc_run_173(CheckerSccCall_term_usage_map_constructor_args{args, field_ty, depth, env, globals})
        case None{}: checker_scc_run_173(CheckerSccCall_term_usage_map_quantified_list{args, constructor_field_quantities(key, globals), depth, env, globals})

    case CheckerSccCall_term_usage_map_scrutinee_result{result, scrutinees, cases, scrutinee_usage, depth, env, globals, expected}:
      match result:
        case ScrutineeTypes{types}: usage_merge(scrutinee_usage, checker_scc_run_173(CheckerSccCall_term_usage_map_cases{cases, scrutinees, types, depth, env, globals, expected}), False{})
        case ScrutineeTypeFailure{ _}: usage_merge(scrutinee_usage, checker_scc_run_173(CheckerSccCall_term_usage_map_cases{cases, scrutinees, Nil{}, depth, env, globals, expected}), False{})
    case CheckerSccCall_term_usage_map{term, depth, env, globals, expected}:
      match term:
        case Ast.TermVar{ _, index,  _}:
          Bool.pick(List<&2, UsageEntry>, Nat.is_ge(index, depth), [Usage{ index - depth,  Ast.QOne{}}], Nil{})
        case Ast.TermBang{ inner,  _}: checker_scc_run_173(CheckerSccCall_term_usage_map{inner, depth, env, globals, expected})
        case Ast.TermSub{index, value, body,  _}:
          inner_expected = substituted_usage_expected(expected, index, value)
          checker_scc_run_173(CheckerSccCall_term_usage_map{Core.subst(index, value, body), depth, env, globals, inner_expected})
        case Ast.TermAnn{ inner, ty,  _}: checker_scc_run_173(CheckerSccCall_term_usage_map{inner, depth, env, globals, Some{ty}})
        case Ast.TermTemplate{ _,  _}: Nil{}
        case Ast.TermType{ _,  _}: Nil{}
        case Ast.TermMin{left, right,  _}: usage_merge(checker_scc_run_173(CheckerSccCall_term_usage_map{left, depth, env, globals, None{}}), checker_scc_run_173(CheckerSccCall_term_usage_map{right, depth, env, globals, None{}}), False{})
        case Ast.TermAll{ _,  _,  _,  _,  _,  _}: Nil{}
        case Ast.TermLam{ annotated, key,  _, body, span}:
          checker_scc_run_173(CheckerSccCall_term_usage_map_lambda_expected{expected, annotated, key, body, span, depth, env, globals})
        case Ast.TermLet{keys,  _, quantities, values, body,  _}:
          local_env = checker_scc_run_173(CheckerSccCall_usage_let_env{keys, quantities, values, env, env, globals})
          body_expected = shift_expected(expected, List.length(&2, String, keys))
          usage_merge(checker_scc_run_173(CheckerSccCall_term_usage_map_quantified_list{values, quantities, depth, env, globals}), checker_scc_run_173(CheckerSccCall_term_usage_map{body, depth + List.length(&2, String, keys), local_env, globals, body_expected}), False{})
        case Ast.TermApp{ Ast.TermLam{ _,  _,  _, body,  _}, arg,  _}:
          checker_scc_run_173(CheckerSccCall_term_usage_map{Core.subst(0n, arg, body), depth, env, globals, expected})
        case Ast.TermApp{fn, arg,  _}:
          checker_scc_run_173(CheckerSccCall_term_usage_map_application_quantity{function_argument_quantity(fn, env, globals), fn, arg, depth, env, globals})
        case Ast.TermFill{head, args, span}: checker_scc_run_173(CheckerSccCall_term_usage_map_family_result{lower_family_sugar(head, args, False{}, span, globals), head, args, depth, env, globals, expected})
        case Ast.TermPlus{head, args, span}: checker_scc_run_173(CheckerSccCall_term_usage_map_family_result{lower_family_sugar(head, args, True{}, span, globals), head, args, depth, env, globals, expected})
        case Ast.TermAdt{key, args,  _,  _}: checker_scc_run_173(CheckerSccCall_term_usage_map_quantified_list{args, family_parameter_quantities(resolve_family_key(key, globals), globals), depth, env, globals})
        case Ast.TermCtr{key, args,  _}:
          checker_scc_run_173(CheckerSccCall_term_usage_map_constructor_result{constructor_usage_field_type(key, expected, globals), key, args, depth, env, globals})
        case Ast.TermMat{ _, head, matched,  _}: usage_merge(checker_scc_run_173(CheckerSccCall_term_usage_map{head, depth, env, globals, None{}}), checker_scc_run_173(CheckerSccCall_term_usage_map{matched, depth, env, globals, None{}}), False{})
        case Ast.TermEqual{ _,  _,  _,  _}: Nil{}
        case Ast.TermRewrite{equation,  _, body,  _}: usage_merge(checker_scc_run_173(CheckerSccCall_term_usage_map{equation, depth, env, globals, None{}}), checker_scc_run_173(CheckerSccCall_term_usage_map{body, depth, env, globals, expected}), False{})
        case Ast.BodyMatch{scrutinees, cases,  _}:
          scrutinee_usage = checker_scc_run_173(CheckerSccCall_term_usage_map_list{scrutinees, depth, env, globals})
          checker_scc_run_173(CheckerSccCall_term_usage_map_scrutinee_result{checker_scc_run_173(CheckerSccCall_infer_scrutinee_types{scrutinees, env, globals}), scrutinees, cases, scrutinee_usage, depth, env, globals, expected})
        case Ast.BodyCase{patterns, body,  _}:
          checker_scc_run_173(CheckerSccCall_term_usage_map{body, depth + Core.pattern_list_depth(patterns), env, globals, shift_expected(expected, Core.pattern_list_depth(patterns))})
        case Ast.BodyLocal{patterns,  _, values, body,  _}:
          local_env = checker_scc_run_173(CheckerSccCall_usage_local_env{patterns, values, env, env, globals})
          usage_merge(checker_scc_run_173(CheckerSccCall_term_usage_map_list{values, depth, env, globals}), checker_scc_run_173(CheckerSccCall_term_usage_map{body, depth + Core.pattern_list_depth(patterns), local_env, globals, shift_expected(expected, Core.pattern_list_depth(patterns))}), False{})
        case Ast.BodyReply{ inner,  _}: checker_scc_run_173(CheckerSccCall_term_usage_map{inner, depth, env, globals, expected})
        case _: Nil{}

    case CheckerSccCall_term_usage_map_cases{cases, scrutinees, types, depth, env, globals, expected}:
      match cases:
        case Nil{}: Nil{}
        case +case_term <> rest:
          branch_map = checker_scc_run_173(CheckerSccCall_term_usage_map_case{case_term, scrutinees, types, depth, env, globals, expected})
          usage_merge(branch_map, checker_scc_run_173(CheckerSccCall_term_usage_map_cases{rest, scrutinees, types, depth, env, globals, expected}), True{})

    case CheckerSccCall_term_usage_map_case{case_term, scrutinees, types, depth, env, globals, expected}:
      match case_term:
        case Ast.BodyCase{patterns, body, _}:
          branch_env = usage_pattern_env(patterns, types, scrutinees, env, globals, Core.pattern_list_depth(patterns), 0n)
          branch_expected = usage_expected_patterns(patterns, scrutinees, expected, List.length(&2, Binding, env), Core.pattern_list_depth(patterns), 0n, globals)
          checker_scc_run_173(CheckerSccCall_term_usage_map{body, depth + Core.pattern_list_depth(patterns), branch_env, globals, branch_expected})
        case _: checker_scc_run_173(CheckerSccCall_term_usage_map{case_term, depth, env, globals, expected})
    case CheckerSccCall_term_usage_map_list{terms, depth, env, globals}:
      match terms:
        case Nil{}: Nil{}
        case +term <> rest: usage_merge(checker_scc_run_173(CheckerSccCall_term_usage_map{term, depth, env, globals, None{}}), checker_scc_run_173(CheckerSccCall_term_usage_map_list{rest, depth, env, globals}), False{})

    case CheckerSccCall_term_usage_map_quantified_list{terms, quantities, depth, env, globals}:
      match terms quantities:
        case Nil{} Nil{}: Nil{}
        case +term <> term_rest +quantity <> quantity_rest:
          match quantity:
            case Ast.QZero{}: checker_scc_run_173(CheckerSccCall_term_usage_map_quantified_list{term_rest, quantity_rest, depth, env, globals})
            case _: usage_merge(checker_scc_run_173(CheckerSccCall_term_usage_map{term, depth, env, globals, None{}}), checker_scc_run_173(CheckerSccCall_term_usage_map_quantified_list{term_rest, quantity_rest, depth, env, globals}), False{})
        case _ _: checker_scc_run_173(CheckerSccCall_term_usage_map_list{terms, depth, env, globals})


    case CheckerSccCall_use_count_with_globals{term, wanted, depth, globals}:
      usage_get(wanted, checker_scc_run_173(CheckerSccCall_term_usage_map{term, depth, Nil{}, globals, None{}}))

    case CheckerSccCall_use_count_with_context{term, wanted, env, globals}:
      usage_get(wanted, checker_scc_run_173(CheckerSccCall_term_usage_map{term, 0n, env, globals, None{}}))

    case CheckerSccCall_use_count_with_expected{term, wanted, env, globals, expected}:
      usage_get(wanted, checker_scc_run_173(CheckerSccCall_term_usage_map{term, 0n, env, globals, Some{expected}}))


    case CheckerSccCall_check_ctr_fields_arg{result, rest, body, expected, env, globals, whole, span}:
      match result:
        case Inferred{ checked,  _}: check_ctr_fields_result(checker_scc_run_173(CheckerSccCall_check_ctr_fields{rest, Core.subst(0n, checked, body), expected, env, globals, whole, span}), whole)
        case InferenceFailure{diagnostic}: InferenceFailure{diagnostic}

    case CheckerSccCall_check_ctr_fields_view{view, arg, rest, expected, env, globals, whole, span}:
      match view:
        case Ast.TermAll{ _,  _,  _,  domain, body,  _}: checker_scc_run_173(CheckerSccCall_check_ctr_fields_arg{checker_scc_run_173(CheckerSccCall_check_term{arg, env, globals, domain}), rest, body, expected, env, globals, whole, span})
        case _: fail(span, "constructor has too many fields", "a remaining field", "an extra field")

    case CheckerSccCall_check_ctr_fields{args, ty, expected, env, globals, whole, span}:
      match args:
        case Nil{}: check_ctr_fields_fit(fits_term(ty, expected, globals), expected, whole, span)
        case +arg <> rest: checker_scc_run_173(CheckerSccCall_check_ctr_fields_view{whnf(64n, ty, globals), arg, rest, expected, env, globals, whole, span})


def infer_adt_args_view(args: List<&2, Ast.SyntaxTerm>, current: Ast.SyntaxTerm, view: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, span: Ast.SourceSpan) -> Inference:
  checker_scc_run_173(CheckerSccCall_infer_adt_args_view{args, current, view, env, globals, whole, span})

def infer_adt_arg_check(result: Inference, rest: List<&2, Ast.SyntaxTerm>, codomain: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, span: Ast.SourceSpan) -> Inference:
  checker_scc_run_173(CheckerSccCall_infer_adt_arg_check{result, rest, codomain, env, globals, whole, span})

def infer_adt_args(args: List<&2, Ast.SyntaxTerm>, current: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, span: Ast.SourceSpan) -> Inference:
  checker_scc_run_173(CheckerSccCall_infer_adt_args{args, current, env, globals, whole, span})

def validate_terms_result(result: Inference, rest: List<&2, Ast.SyntaxTerm>, env: List<&2, Binding>, globals: List<&2, Global>) -> Maybe<&2, Diagnostic>:
  checker_scc_run_173(CheckerSccCall_validate_terms_result{result, rest, env, globals})

def validate_terms(terms: List<&2, Ast.SyntaxTerm>, env: List<&2, Binding>, globals: List<&2, Global>) -> Maybe<&2, Diagnostic>:
  checker_scc_run_173(CheckerSccCall_validate_terms{terms, env, globals})

def check_local_quantities(keys: List<&2, String>, quantities: List<&2, Ast.Quantity>, body: Ast.SyntaxTerm, remaining: Nat, span: Ast.SourceSpan, usage_env: List<&2, Binding>, globals: List<&2, Global>) -> Maybe<&2, Diagnostic>:
  checker_scc_run_173(CheckerSccCall_check_local_quantities{keys, quantities, body, remaining, span, usage_env, globals})

def check_local_pattern_uses(patterns: List<&2, Ast.SyntaxPattern>, body: Ast.SyntaxTerm, remaining: Nat, usage_env: List<&2, Binding>, globals: List<&2, Global>) -> Maybe<&2, Diagnostic>:
  checker_scc_run_173(CheckerSccCall_check_local_pattern_uses{patterns, body, remaining, usage_env, globals})

def check_body_local_uses_result(result: Maybe<&2, Diagnostic>, patterns: List<&2, Ast.SyntaxPattern>, values: List<&2, Ast.SyntaxTerm>, body: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>, usage_env: List<&2, Binding>) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_local_uses_result{result, patterns, values, body, span, env, globals, usage_env})

def check_body_local_terms_result(result: Maybe<&2, Diagnostic>, patterns: List<&2, Ast.SyntaxPattern>, values: List<&2, Ast.SyntaxTerm>, body: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_local_terms_result{result, patterns, values, body, span, env, globals})

def check_body_local_quantity_result(matches: Bool, patterns: List<&2, Ast.SyntaxPattern>, quantity: Ast.Quantity, values: List<&2, Ast.SyntaxTerm>, body: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_local_quantity_result{matches, patterns, quantity, values, body, span, env, globals})

def check_body_local_length_result(matches: Bool, patterns: List<&2, Ast.SyntaxPattern>, quantity: Ast.Quantity, values: List<&2, Ast.SyntaxTerm>, body: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_local_length_result{matches, patterns, quantity, values, body, span, env, globals})

def check_body_local(patterns: List<&2, Ast.SyntaxPattern>, quantity: Ast.Quantity, values: List<&2, Ast.SyntaxTerm>, body: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_local{patterns, quantity, values, body, span, env, globals})

def infer_family_sugar_result(lowering: FamilyLowering, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_infer_family_sugar_result{lowering, env, globals})

def infer_family_sugar(head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, plus: Bool, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_infer_family_sugar{head, args, plus, span, env, globals})

def infer_application_result_view(view: Ast.SyntaxTerm, term: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_infer_application_result_view{view, term, arg, span, env, globals})

def infer_application_result(term: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, function_ty: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_infer_application_result{term, arg, function_ty, span, env, globals})

def infer_global_adt(found: Maybe<&2, Global>, key: String, args: List<&2, Ast.SyntaxTerm>, term: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_infer_global_adt{found, key, args, term, span, env, globals})

def infer_term_annotation_result(result: Inference, inner: Ast.SyntaxTerm, term: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_infer_term_annotation_result{result, inner, term, span, env, globals})

def infer_equal_type(result: Inference, left: Ast.SyntaxTerm, right: Ast.SyntaxTerm, ty: Ast.SyntaxTerm, term: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_infer_equal_type{result, left, right, ty, term, span, env, globals})

def infer_application_result_of_function(result: Inference, term: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_infer_application_result_of_function{result, term, arg, span, env, globals})

def infer_application_unfolded(view: Ast.SyntaxTerm, fn: Ast.SyntaxTerm, term: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_infer_application_unfolded{view, fn, term, arg, span, env, globals})

def infer_application_bang(is_bang: Bool, fn: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, term: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_infer_application_bang{is_bang, fn, arg, term, span, env, globals})

def infer_application_valid(valid: Bool, fn: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, term: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_infer_application_valid{valid, fn, arg, term, span, env, globals})

def infer_all_domain(result: Inference, quantity: Ast.Quantity, key: String, ty: Ast.SyntaxTerm, body: Ast.SyntaxTerm, term: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_infer_all_domain{result, quantity, key, ty, body, term, span, env, globals})

def infer_let_values(result: Maybe<&2, Diagnostic>, keys: List<&2, String>, values: List<&2, Ast.SyntaxTerm>, body: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_infer_let_values{result, keys, values, body, span, env, globals})

def infer_let_validated(result: Maybe<&2, Diagnostic>, values: List<&2, Ast.SyntaxTerm>, body: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_infer_let_validated{result, values, body, span, env, globals})

def infer_let_lengths(valid: Bool, values: List<&2, Ast.SyntaxTerm>, body: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_infer_let_lengths{valid, values, body, span, env, globals})

def infer(term: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_infer{term, env, globals})

def check_match_head_result(result: Inference, matched: Ast.SyntaxTerm, default_ty: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_match_head_result{result, matched, default_ty, whole, expected, env, globals})

def check_match_applied(applied: Maybe<&2, Ast.SyntaxTerm>, key: String, head: Ast.SyntaxTerm, matched: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, family: String, parameters: List<&2, Ast.SyntaxTerm>, refs: List<&2, String>, quantity: Ast.Quantity, scrutinee: String, index: Nat, body: Ast.SyntaxTerm, found_family: String) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_match_applied{applied, key, head, matched, span, expected, env, globals, whole, family, parameters, refs, quantity, scrutinee, index, body, found_family})

def check_match_family_equal(matches: Bool, found_family: String, key: String, head: Ast.SyntaxTerm, matched: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, family: String, parameters: List<&2, Ast.SyntaxTerm>, refs: List<&2, String>, quantity: Ast.Quantity, scrutinee: String, index: Nat, body: Ast.SyntaxTerm, constructor_ty: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_match_family_equal{matches, found_family, key, head, matched, span, expected, env, globals, whole, family, parameters, refs, quantity, scrutinee, index, body, constructor_ty})

def check_match_family_result(found: Maybe<&2, String>, key: String, head: Ast.SyntaxTerm, matched: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, family: String, family_key: String, parameters: List<&2, Ast.SyntaxTerm>, refs: List<&2, String>, quantity: Ast.Quantity, scrutinee: String, index: Nat, body: Ast.SyntaxTerm, constructor_ty: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_match_family_result{found, key, head, matched, span, expected, env, globals, whole, family, family_key, parameters, refs, quantity, scrutinee, index, body, constructor_ty})

def check_match_global(constructor: Global, key: String, head: Ast.SyntaxTerm, matched: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, family: String, family_key: String, parameters: List<&2, Ast.SyntaxTerm>, refs: List<&2, String>, quantity: Ast.Quantity, scrutinee: String, index: Nat, body: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_match_global{constructor, key, head, matched, span, expected, env, globals, whole, family, family_key, parameters, refs, quantity, scrutinee, index, body})

def check_match_constructor(found: Maybe<&2, Global>, key: String, head: Ast.SyntaxTerm, matched: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, family: String, family_key: String, parameters: List<&2, Ast.SyntaxTerm>, refs: List<&2, String>, quantity: Ast.Quantity, scrutinee: String, index: Nat, body: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_match_constructor{found, key, head, matched, span, expected, env, globals, whole, family, family_key, parameters, refs, quantity, scrutinee, index, body})

def check_match_unexcluded(excluded: Bool, key: String, head: Ast.SyntaxTerm, matched: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, family: String, family_key: String, parameters: List<&2, Ast.SyntaxTerm>, refs: List<&2, String>, quantity: Ast.Quantity, scrutinee: String, index: Nat, body: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_match_unexcluded{excluded, key, head, matched, span, expected, env, globals, whole, family, family_key, parameters, refs, quantity, scrutinee, index, body})

def check_match_input_view(view: Ast.SyntaxTerm, key: String, head: Ast.SyntaxTerm, matched: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, quantity: Ast.Quantity, scrutinee: String, index: Nat, body: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_match_input_view{view, key, head, matched, span, expected, env, globals, whole, quantity, scrutinee, index, body})

def check_match_goal_view(view: Ast.SyntaxTerm, key: String, head: Ast.SyntaxTerm, matched: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_match_goal_view{view, key, head, matched, span, expected, env, globals, whole})

def check_match(key: String, head: Ast.SyntaxTerm, matched: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_match{key, head, matched, span, expected, env, globals, whole})

def check_body_case_body_result(result: Inference, rest: List<&2, Ast.SyntaxTerm>, family: String, parameters: List<&2, Ast.SyntaxTerm>, scrutinee_ty: Ast.SyntaxTerm, scrutinee_index: Maybe<&2, Nat>, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, removed: List<&2, String>, span: Ast.SourceSpan, key: String) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_case_body_result{result, rest, family, parameters, scrutinee_ty, scrutinee_index, expected, whole, env, globals, removed, span, key})

def check_body_case_pattern_result(result: PatternTyping, pattern: Ast.SyntaxPattern, rest: List<&2, Ast.SyntaxTerm>, family: String, parameters: List<&2, Ast.SyntaxTerm>, scrutinee_ty: Ast.SyntaxTerm, scrutinee_index: Maybe<&2, Nat>, body: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, removed: List<&2, String>, span: Ast.SourceSpan, key: String) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_case_pattern_result{result, pattern, rest, family, parameters, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, removed, span, key})

def check_body_case_constructor_uses(valid: Bool, pattern: Ast.SyntaxPattern, rest: List<&2, Ast.SyntaxTerm>, family: String, parameters: List<&2, Ast.SyntaxTerm>, scrutinee_ty: Ast.SyntaxTerm, scrutinee_index: Maybe<&2, Nat>, body: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, removed: List<&2, String>, span: Ast.SourceSpan, key: String, pattern_span: Ast.SourceSpan) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_case_constructor_uses{valid, pattern, rest, family, parameters, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, removed, span, key, pattern_span})

def check_body_case_constructor_seen(seen: Bool, pattern: Ast.SyntaxPattern, rest: List<&2, Ast.SyntaxTerm>, family: String, parameters: List<&2, Ast.SyntaxTerm>, scrutinee_ty: Ast.SyntaxTerm, scrutinee_index: Maybe<&2, Nat>, body: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, removed: List<&2, String>, span: Ast.SourceSpan, key: String, pattern_span: Ast.SourceSpan) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_case_constructor_seen{seen, pattern, rest, family, parameters, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, removed, span, key, pattern_span})

def check_body_case_catchall_usage(valid: Bool, key: String, quantity: Ast.Quantity, pattern: Ast.SyntaxPattern, scrutinee_ty: Ast.SyntaxTerm, scrutinee_index: Maybe<&2, Nat>, body: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, pattern_span: Ast.SourceSpan) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_case_catchall_usage{valid, key, quantity, pattern, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, pattern_span})

def check_body_case_catchall(rest: List<&2, Ast.SyntaxTerm>, key: String, quantity: Ast.Quantity, pattern: Ast.SyntaxPattern, scrutinee_ty: Ast.SyntaxTerm, scrutinee_index: Maybe<&2, Nat>, body: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, pattern_span: Ast.SourceSpan) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_case_catchall{rest, key, quantity, pattern, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, pattern_span})

def check_body_case_pattern(pattern: Ast.SyntaxPattern, rest: List<&2, Ast.SyntaxTerm>, family: String, parameters: List<&2, Ast.SyntaxTerm>, scrutinee_ty: Ast.SyntaxTerm, scrutinee_index: Maybe<&2, Nat>, body: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, removed: List<&2, String>, span: Ast.SourceSpan, pattern_span: Ast.SourceSpan) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_case_pattern{pattern, rest, family, parameters, scrutinee_ty, scrutinee_index, body, expected, whole, env, globals, removed, span, pattern_span})

def check_body_case_term(case_term: Ast.SyntaxTerm, rest: List<&2, Ast.SyntaxTerm>, family: String, parameters: List<&2, Ast.SyntaxTerm>, scrutinee_ty: Ast.SyntaxTerm, scrutinee_index: Maybe<&2, Nat>, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, removed: List<&2, String>, span: Ast.SourceSpan) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_case_term{case_term, rest, family, parameters, scrutinee_ty, scrutinee_index, expected, whole, env, globals, removed, span})

def check_body_cases(cases: List<&2, Ast.SyntaxTerm>, family: String, parameters: List<&2, Ast.SyntaxTerm>, scrutinee_ty: Ast.SyntaxTerm, scrutinee_index: Maybe<&2, Nat>, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, removed: List<&2, String>, span: Ast.SourceSpan) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_cases{cases, family, parameters, scrutinee_ty, scrutinee_index, expected, whole, env, globals, removed, span})

def check_body_match_type_view(view: Ast.SyntaxTerm, scrutinee: Ast.SyntaxTerm, cases: List<&2, Ast.SyntaxTerm>, ty: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_match_type_view{view, scrutinee, cases, ty, span, expected, env, globals, whole})

def check_body_match_type(scrutinee: Ast.SyntaxTerm, cases: List<&2, Ast.SyntaxTerm>, ty: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_match_type{scrutinee, cases, ty, span, expected, env, globals, whole})

def infer_scrutinee_types_result(result: Inference, rest: List<&2, Ast.SyntaxTerm>, env: List<&2, Binding>, globals: List<&2, Global>) -> ScrutineeTyping:
  checker_scc_run_173(CheckerSccCall_infer_scrutinee_types_result{result, rest, env, globals})

def infer_scrutinee_types(scrutinees: List<&2, Ast.SyntaxTerm>, env: List<&2, Binding>, globals: List<&2, Global>) -> ScrutineeTyping:
  checker_scc_run_173(CheckerSccCall_infer_scrutinee_types{scrutinees, env, globals})

def pattern_uses_valid(pattern: Ast.SyntaxPattern, body: Ast.SyntaxTerm, remaining: Nat, globals: List<&2, Global>) -> Bool:
  checker_scc_run_173(CheckerSccCall_pattern_uses_valid{pattern, body, remaining, globals})

def pattern_uses_valid_list(patterns: List<&2, Ast.SyntaxPattern>, body: Ast.SyntaxTerm, remaining: Nat, globals: List<&2, Global>) -> Bool:
  checker_scc_run_173(CheckerSccCall_pattern_uses_valid_list{patterns, body, remaining, globals})

def check_body_pattern_vector_typed(result: PatternTyping, pattern_rest: List<&2, Ast.SyntaxPattern>, type_rest: List<&2, Ast.SyntaxTerm>, scrutinee_rest: List<&2, Ast.SyntaxTerm>, pattern: Ast.SyntaxPattern, body: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, remaining: Nat, offset: Nat, span: Ast.SourceSpan, source_index: Maybe<&2, Nat>, added: Nat) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_pattern_vector_typed{result, pattern_rest, type_rest, scrutinee_rest, pattern, body, expected, env, globals, remaining, offset, span, source_index, added})

def check_body_pattern_vector(patterns: List<&2, Ast.SyntaxPattern>, types: List<&2, Ast.SyntaxTerm>, scrutinees: List<&2, Ast.SyntaxTerm>, body: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, remaining: Nat, offset: Nat, span: Ast.SourceSpan) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_pattern_vector{patterns, types, scrutinees, body, expected, env, globals, remaining, offset, span})

def check_body_pattern_rows_result(result: Inference, rest: List<&2, Ast.SyntaxTerm>, types: List<&2, Ast.SyntaxTerm>, scrutinees: List<&2, Ast.SyntaxTerm>, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, span: Ast.SourceSpan) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_pattern_rows_result{result, rest, types, scrutinees, expected, whole, env, globals, span})

def check_body_pattern_rows_catchall(valid: Bool, patterns: List<&2, Ast.SyntaxPattern>, body: Ast.SyntaxTerm, case_span: Ast.SourceSpan, rest: List<&2, Ast.SyntaxTerm>, types: List<&2, Ast.SyntaxTerm>, scrutinees: List<&2, Ast.SyntaxTerm>, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, span: Ast.SourceSpan) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_pattern_rows_catchall{valid, patterns, body, case_span, rest, types, scrutinees, expected, whole, env, globals, span})

def check_body_pattern_rows_length(valid: Bool, patterns: List<&2, Ast.SyntaxPattern>, body: Ast.SyntaxTerm, case_span: Ast.SourceSpan, rest: List<&2, Ast.SyntaxTerm>, types: List<&2, Ast.SyntaxTerm>, scrutinees: List<&2, Ast.SyntaxTerm>, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, span: Ast.SourceSpan) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_pattern_rows_length{valid, patterns, body, case_span, rest, types, scrutinees, expected, whole, env, globals, span})

def check_body_pattern_rows_case(case_term: Ast.SyntaxTerm, rest: List<&2, Ast.SyntaxTerm>, types: List<&2, Ast.SyntaxTerm>, scrutinees: List<&2, Ast.SyntaxTerm>, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, span: Ast.SourceSpan) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_pattern_rows_case{case_term, rest, types, scrutinees, expected, whole, env, globals, span})

def check_body_pattern_rows(cases: List<&2, Ast.SyntaxTerm>, types: List<&2, Ast.SyntaxTerm>, scrutinees: List<&2, Ast.SyntaxTerm>, expected: Ast.SyntaxTerm, whole: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, span: Ast.SourceSpan) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_pattern_rows{cases, types, scrutinees, expected, whole, env, globals, span})

def check_body_match_many_types_result(result: ScrutineeTyping, scrutinees: List<&2, Ast.SyntaxTerm>, cases: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_match_many_types_result{result, scrutinees, cases, span, expected, env, globals, whole})

def check_body_match_many(scrutinees: List<&2, Ast.SyntaxTerm>, cases: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_match_many{scrutinees, cases, span, expected, env, globals, whole})

def check_body_match_first_result(result: Inference, scrutinee: Ast.SyntaxTerm, cases: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_match_first_result{result, scrutinee, cases, span, expected, env, globals, whole})

def check_body_match_scrutinees(scrutinees: List<&2, Ast.SyntaxTerm>, cases: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_match_scrutinees{scrutinees, cases, span, expected, env, globals, whole})

def check_body_match_valid(valid: Bool, scrutinees: List<&2, Ast.SyntaxTerm>, cases: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_match_valid{valid, scrutinees, cases, span, expected, env, globals, whole})

def check_body_match(scrutinees: List<&2, Ast.SyntaxTerm>, cases: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_body_match{scrutinees, cases, span, expected, env, globals, whole})

def rewrite_body_type_view(view: Ast.SyntaxTerm, body: Ast.SyntaxTerm, body_ty: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_rewrite_body_type_view{view, body, body_ty, span, expected, env, globals, whole})

def rewrite_left_applied_result(applied: Maybe<&2, Ast.SyntaxTerm>, body: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_rewrite_left_applied_result{applied, body, span, expected, env, globals, whole})

def rewrite_fits_result(fits: Bool, left: Ast.SyntaxTerm, p_ty: Ast.SyntaxTerm, body: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_rewrite_fits_result{fits, left, p_ty, body, span, expected, env, globals, whole})

def rewrite_equation_applied_result(applied: Maybe<&2, Ast.SyntaxTerm>, right: Ast.SyntaxTerm, left: Ast.SyntaxTerm, p_ty: Ast.SyntaxTerm, body: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_rewrite_equation_applied_result{applied, right, left, p_ty, body, span, expected, env, globals, whole})

def rewrite_proof_result(result: Inference, right: Ast.SyntaxTerm, left: Ast.SyntaxTerm, checked_equation: Ast.SyntaxTerm, p_ty: Ast.SyntaxTerm, body: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_rewrite_proof_result{result, right, left, checked_equation, p_ty, body, span, expected, env, globals, whole})

def rewrite_equation_view(view: Ast.SyntaxTerm, checked_equation: Ast.SyntaxTerm, proof: Ast.SyntaxTerm, body: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_rewrite_equation_view{view, checked_equation, proof, body, span, expected, env, globals, whole})

def rewrite_equation_result(result: Inference, proof: Ast.SyntaxTerm, body: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_rewrite_equation_result{result, proof, body, span, expected, env, globals, whole})

def check_rewrite(equation: Ast.SyntaxTerm, proof: Ast.SyntaxTerm, body: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_rewrite{equation, proof, body, span, expected, env, globals, whole})

def lambda_domain_valid(domain: Ast.SyntaxTerm, span: Ast.SourceSpan, env: List<&2, Binding>, globals: List<&2, Global>) -> Bool:
  checker_scc_run_173(CheckerSccCall_lambda_domain_valid{domain, span, env, globals})

def check_lambda_domain_result(valid: Bool, annotated: Maybe<&2, Ast.Quantity>, key: String, body: Ast.SyntaxTerm, quantity: Ast.Quantity, domain: Ast.SyntaxTerm, codomain: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_lambda_domain_result{valid, annotated, key, body, quantity, domain, codomain, span, expected, env, globals})

def check_lambda_promotes_result(promotes: Bool, annotated: Maybe<&2, Ast.Quantity>, key: String, body: Ast.SyntaxTerm, quantity: Ast.Quantity, domain: Ast.SyntaxTerm, codomain: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_lambda_promotes_result{promotes, annotated, key, body, quantity, domain, codomain, span, expected, env, globals})

def check_lambda_quantity_result(found: Maybe<&2, Ast.Quantity>, annotated: Maybe<&2, Ast.Quantity>, key: String, body: Ast.SyntaxTerm, domain: Ast.SyntaxTerm, codomain: Ast.SyntaxTerm, span: Ast.SourceSpan, expected_quantity: Ast.Quantity, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_lambda_quantity_result{found, annotated, key, body, domain, codomain, span, expected_quantity, expected, env, globals})

def check_lambda_body(annotated: Maybe<&2, Ast.Quantity>, key: String, body: Ast.SyntaxTerm, expected_quantity: Ast.Quantity, domain: Ast.SyntaxTerm, codomain: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_lambda_body{annotated, key, body, expected_quantity, domain, codomain, span, expected, env, globals})

def check_lambda_body_result(result: Inference, annotated: Maybe<&2, Ast.Quantity>, key: String, body: Ast.SyntaxTerm, quantity: Ast.Quantity, domain: Ast.SyntaxTerm, codomain: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_lambda_body_result{result, annotated, key, body, quantity, domain, codomain, span, expected, env, globals})

def check_term_lambda_view(view: Ast.SyntaxTerm, annotated: Maybe<&2, Ast.Quantity>, key: String, body: Ast.SyntaxTerm, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_term_lambda_view{view, annotated, key, body, span, expected, env, globals})

def check_term_constructor_apply(found: Maybe<&2, Ast.SyntaxTerm>, key: String, args: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, parameters: List<&2, Ast.SyntaxTerm>, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, term: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_term_constructor_apply{found, key, args, span, parameters, expected, env, globals, term})

def check_term_constructor_global(global: Global, key: String, args: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, parameters: List<&2, Ast.SyntaxTerm>, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, term: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_term_constructor_global{global, key, args, span, parameters, expected, env, globals, term})

def check_term_constructor_global_result(found: Maybe<&2, Global>, key: String, args: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, parameters: List<&2, Ast.SyntaxTerm>, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, term: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_term_constructor_global_result{found, key, args, span, parameters, expected, env, globals, term})

def check_term_constructor_allowed(allowed: Bool, key: String, args: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, parameters: List<&2, Ast.SyntaxTerm>, refs: List<&2, String>, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, term: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_term_constructor_allowed{allowed, key, args, span, parameters, refs, expected, env, globals, term})

def check_term_constructor_view(view: Ast.SyntaxTerm, key: String, args: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, term: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_term_constructor_view{view, key, args, span, expected, env, globals, term})

def check_term(term: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, expected: Ast.SyntaxTerm) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_term{term, env, globals, expected})

def usage_let_env(keys: List<&2, String>, quantities: List<&2, Ast.Quantity>, values: List<&2, Ast.SyntaxTerm>, value_env: List<&2, Binding>, acc: List<&2, Binding>, globals: List<&2, Global>) -> List<&2, Binding>:
  checker_scc_run_173(CheckerSccCall_usage_let_env{keys, quantities, values, value_env, acc, globals})

def usage_local_env(patterns: List<&2, Ast.SyntaxPattern>, values: List<&2, Ast.SyntaxTerm>, value_env: List<&2, Binding>, acc: List<&2, Binding>, globals: List<&2, Global>) -> List<&2, Binding>:
  checker_scc_run_173(CheckerSccCall_usage_local_env{patterns, values, value_env, acc, globals})

def term_usage_map_constructor_view(view: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, rest: List<&2, Ast.SyntaxTerm>, args: List<&2, Ast.SyntaxTerm>, ty: Ast.SyntaxTerm, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>) -> List<&2, UsageEntry>:
  checker_scc_run_173(CheckerSccCall_term_usage_map_constructor_view{view, arg, rest, args, ty, depth, env, globals})

def constructor_argument_usage(quantity: Ast.Quantity, arg: Ast.SyntaxTerm, domain: Ast.SyntaxTerm, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>) -> List<&2, UsageEntry>:
  checker_scc_run_173(CheckerSccCall_constructor_argument_usage{quantity, arg, domain, depth, env, globals})

def term_usage_map_constructor_args(args: List<&2, Ast.SyntaxTerm>, ty: Ast.SyntaxTerm, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>) -> List<&2, UsageEntry>:
  checker_scc_run_173(CheckerSccCall_term_usage_map_constructor_args{args, ty, depth, env, globals})

def term_usage_map_lambda_quantity(found: Maybe<&2, Ast.Quantity>, key: String, body: Ast.SyntaxTerm, span: Ast.SourceSpan, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>, domain: Ast.SyntaxTerm, codomain: Ast.SyntaxTerm) -> List<&2, UsageEntry>:
  checker_scc_run_173(CheckerSccCall_term_usage_map_lambda_quantity{found, key, body, span, depth, env, globals, domain, codomain})

def term_usage_map_lambda_view(view: Ast.SyntaxTerm, annotated: Maybe<&2, Ast.Quantity>, key: String, body: Ast.SyntaxTerm, span: Ast.SourceSpan, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>) -> List<&2, UsageEntry>:
  checker_scc_run_173(CheckerSccCall_term_usage_map_lambda_view{view, annotated, key, body, span, depth, env, globals})

def term_usage_map_lambda_expected(expected: Maybe<&2, Ast.SyntaxTerm>, annotated: Maybe<&2, Ast.Quantity>, key: String, body: Ast.SyntaxTerm, span: Ast.SourceSpan, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>) -> List<&2, UsageEntry>:
  checker_scc_run_173(CheckerSccCall_term_usage_map_lambda_expected{expected, annotated, key, body, span, depth, env, globals})

def term_usage_map_application_quantity(found: Maybe<&2, Ast.Quantity>, fn: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>) -> List<&2, UsageEntry>:
  checker_scc_run_173(CheckerSccCall_term_usage_map_application_quantity{found, fn, arg, depth, env, globals})

def term_usage_map_family_result(result: FamilySugar, head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>, expected: Maybe<&2, Ast.SyntaxTerm>) -> List<&2, UsageEntry>:
  checker_scc_run_173(CheckerSccCall_term_usage_map_family_result{result, head, args, depth, env, globals, expected})

def term_usage_map_constructor_result(found: Maybe<&2, Ast.SyntaxTerm>, key: String, args: List<&2, Ast.SyntaxTerm>, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>) -> List<&2, UsageEntry>:
  checker_scc_run_173(CheckerSccCall_term_usage_map_constructor_result{found, key, args, depth, env, globals})

def term_usage_map_scrutinee_result(result: ScrutineeTyping, scrutinees: List<&2, Ast.SyntaxTerm>, cases: List<&2, Ast.SyntaxTerm>, scrutinee_usage: List<&2, UsageEntry>, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>, expected: Maybe<&2, Ast.SyntaxTerm>) -> List<&2, UsageEntry>:
  checker_scc_run_173(CheckerSccCall_term_usage_map_scrutinee_result{result, scrutinees, cases, scrutinee_usage, depth, env, globals, expected})

def term_usage_map(term: Ast.SyntaxTerm, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>, expected: Maybe<&2, Ast.SyntaxTerm>) -> List<&2, UsageEntry>:
  checker_scc_run_173(CheckerSccCall_term_usage_map{term, depth, env, globals, expected})

def term_usage_map_cases(cases: List<&2, Ast.SyntaxTerm>, scrutinees: List<&2, Ast.SyntaxTerm>, types: List<&2, Ast.SyntaxTerm>, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>, expected: Maybe<&2, Ast.SyntaxTerm>) -> List<&2, UsageEntry>:
  checker_scc_run_173(CheckerSccCall_term_usage_map_cases{cases, scrutinees, types, depth, env, globals, expected})

def term_usage_map_case(case_term: Ast.SyntaxTerm, scrutinees: List<&2, Ast.SyntaxTerm>, types: List<&2, Ast.SyntaxTerm>, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>, expected: Maybe<&2, Ast.SyntaxTerm>) -> List<&2, UsageEntry>:
  checker_scc_run_173(CheckerSccCall_term_usage_map_case{case_term, scrutinees, types, depth, env, globals, expected})

def term_usage_map_list(terms: List<&2, Ast.SyntaxTerm>, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>) -> List<&2, UsageEntry>:
  checker_scc_run_173(CheckerSccCall_term_usage_map_list{terms, depth, env, globals})

def term_usage_map_quantified_list(terms: List<&2, Ast.SyntaxTerm>, quantities: List<&2, Ast.Quantity>, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>) -> List<&2, UsageEntry>:
  checker_scc_run_173(CheckerSccCall_term_usage_map_quantified_list{terms, quantities, depth, env, globals})

def use_count_with_globals(term: Ast.SyntaxTerm, wanted: Nat, depth: Nat, globals: List<&2, Global>) -> Ast.Quantity:
  checker_scc_run_173(CheckerSccCall_use_count_with_globals{term, wanted, depth, globals})

def use_count_with_context(term: Ast.SyntaxTerm, wanted: Nat, env: List<&2, Binding>, globals: List<&2, Global>) -> Ast.Quantity:
  checker_scc_run_173(CheckerSccCall_use_count_with_context{term, wanted, env, globals})

def use_count_with_expected(term: Ast.SyntaxTerm, wanted: Nat, env: List<&2, Binding>, globals: List<&2, Global>, expected: Ast.SyntaxTerm) -> Ast.Quantity:
  checker_scc_run_173(CheckerSccCall_use_count_with_expected{term, wanted, env, globals, expected})

def check_ctr_fields_arg(result: Inference, rest: List<&2, Ast.SyntaxTerm>, body: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, span: Ast.SourceSpan) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_ctr_fields_arg{result, rest, body, expected, env, globals, whole, span})

def check_ctr_fields_view(view: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, rest: List<&2, Ast.SyntaxTerm>, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, span: Ast.SourceSpan) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_ctr_fields_view{view, arg, rest, expected, env, globals, whole, span})

def check_ctr_fields(args: List<&2, Ast.SyntaxTerm>, ty: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>, whole: Ast.SyntaxTerm, span: Ast.SourceSpan) -> Inference:
  checker_scc_run_173(CheckerSccCall_check_ctr_fields{args, ty, expected, env, globals, whole, span})

def canonicalize_strings(values: List<&2, String>, globals: List<&2, Global>) -> List<&2, String>:
  match values:
    case Nil{}: Nil{}
    case +value <> rest: canonical_name(value, globals) <> canonicalize_strings(rest, globals)

type CheckerSccInput175 is Data:
  CheckerSccCall_canonicalize_patterns{patterns: List<&2, Ast.SyntaxPattern>, globals: List<&2, Global>}
  CheckerSccCall_canonicalize_pattern{pattern: Ast.SyntaxPattern, globals: List<&2, Global>}

def checker_scc_result_175(request: CheckerSccInput175) -> Type:
  match request:
    case CheckerSccCall_canonicalize_patterns{patterns, globals}: List<&2, Ast.SyntaxPattern>
    case CheckerSccCall_canonicalize_pattern{pattern, globals}: Ast.SyntaxPattern

def checker_scc_run_175(request: CheckerSccInput175) -> checker_scc_result_175(request):
  match request:
    case CheckerSccCall_canonicalize_patterns{patterns, globals}:
      match patterns:
        case Nil{}: Nil{}
        case +pattern <> rest: checker_scc_run_175(CheckerSccCall_canonicalize_pattern{pattern, globals}) <> checker_scc_run_175(CheckerSccCall_canonicalize_patterns{rest, globals})

    case CheckerSccCall_canonicalize_pattern{pattern, globals}:
      match pattern:
        case Ast.PatternVar{key, index, quantity, span}: Ast.PatternVar{key, index, quantity, span}
        case Ast.PatternCtr{key, fields, span}: Ast.PatternCtr{ canonical_name(key, globals),  checker_scc_run_175(CheckerSccCall_canonicalize_patterns{fields, globals}), span}


def canonicalize_patterns(patterns: List<&2, Ast.SyntaxPattern>, globals: List<&2, Global>) -> List<&2, Ast.SyntaxPattern>:
  checker_scc_run_175(CheckerSccCall_canonicalize_patterns{patterns, globals})

def canonicalize_pattern(pattern: Ast.SyntaxPattern, globals: List<&2, Global>) -> Ast.SyntaxPattern:
  checker_scc_run_175(CheckerSccCall_canonicalize_pattern{pattern, globals})

type CheckerSccInput176 is Data:
  CheckerSccCall_canonicalize_terms{terms: List<&2, Ast.SyntaxTerm>, globals: List<&2, Global>}
  CheckerSccCall_canonicalize_term{term: Ast.SyntaxTerm, globals: List<&2, Global>}

def checker_scc_result_176(request: CheckerSccInput176) -> Type:
  match request:
    case CheckerSccCall_canonicalize_terms{terms, globals}: List<&2, Ast.SyntaxTerm>
    case CheckerSccCall_canonicalize_term{term, globals}: Ast.SyntaxTerm

def checker_scc_run_176(request: CheckerSccInput176) -> checker_scc_result_176(request):
  match request:
    case CheckerSccCall_canonicalize_terms{terms, globals}:
      match terms:
        case Nil{}: Nil{}
        case +term <> rest: checker_scc_run_176(CheckerSccCall_canonicalize_term{term, globals}) <> checker_scc_run_176(CheckerSccCall_canonicalize_terms{rest, globals})

    case CheckerSccCall_canonicalize_term{term, globals}:
      match term:
        case Ast.TermVar{key, index, span}: Ast.TermVar{key, index, span}
        case Ast.TermRef{key, span}: Ast.TermRef{ canonical_name(key, globals), span}
        case Ast.TermBang{ inner, span}: Ast.TermBang{ checker_scc_run_176(CheckerSccCall_canonicalize_term{inner, globals}), span}
        case Ast.TermSub{index, value, body, span}: Ast.TermSub{index,  checker_scc_run_176(CheckerSccCall_canonicalize_term{value, globals}),  checker_scc_run_176(CheckerSccCall_canonicalize_term{body, globals}), span}
        case Ast.TermAnn{ inner, ty, span}: Ast.TermAnn{ checker_scc_run_176(CheckerSccCall_canonicalize_term{inner, globals}),  checker_scc_run_176(CheckerSccCall_canonicalize_term{ty, globals}), span}
        case Ast.TermTemplate{ inner, span}: Ast.TermTemplate{ checker_scc_run_176(CheckerSccCall_canonicalize_term{inner, globals}), span}
        case Ast.TermLet{keys, indexes, quantities, values, body, span}: Ast.TermLet{keys, indexes, quantities,  checker_scc_run_176(CheckerSccCall_canonicalize_terms{values, globals}),  checker_scc_run_176(CheckerSccCall_canonicalize_term{body, globals}), span}
        case Ast.TermType{kind, span}: Ast.TermType{ checker_scc_run_176(CheckerSccCall_canonicalize_term{kind, globals}), span}
        case Ast.TermQuant{}: term
        case Ast.TermQuantity{quantity, span}: Ast.TermQuantity{quantity, span}
        case Ast.TermMin{left, right, span}: Ast.TermMin{ checker_scc_run_176(CheckerSccCall_canonicalize_term{left, globals}),  checker_scc_run_176(CheckerSccCall_canonicalize_term{right, globals}), span}
        case Ast.TermAll{quantity, key, index, ty, body, span}: Ast.TermAll{quantity, key, index,  checker_scc_run_176(CheckerSccCall_canonicalize_term{ty, globals}),  checker_scc_run_176(CheckerSccCall_canonicalize_term{body, globals}), span}
        case Ast.TermLam{quantity, key, index, body, span}: Ast.TermLam{quantity, key, index,  checker_scc_run_176(CheckerSccCall_canonicalize_term{body, globals}), span}
        case Ast.TermApp{fn, arg, span}: Ast.TermApp{ checker_scc_run_176(CheckerSccCall_canonicalize_term{fn, globals}),  checker_scc_run_176(CheckerSccCall_canonicalize_term{arg, globals}), span}
        case Ast.TermFill{head, args, span}: Ast.TermFill{ checker_scc_run_176(CheckerSccCall_canonicalize_term{head, globals}),  checker_scc_run_176(CheckerSccCall_canonicalize_terms{args, globals}), span}
        case Ast.TermPlus{head, args, span}: Ast.TermPlus{ checker_scc_run_176(CheckerSccCall_canonicalize_term{head, globals}),  checker_scc_run_176(CheckerSccCall_canonicalize_terms{args, globals}), span}
        case Ast.TermAdt{key, args, refs, span}: Ast.TermAdt{ canonical_name(key, globals),  checker_scc_run_176(CheckerSccCall_canonicalize_terms{args, globals}),  canonicalize_strings(refs, globals), span}
        case Ast.TermCtr{key, args, span}: Ast.TermCtr{ canonical_name(key, globals),  checker_scc_run_176(CheckerSccCall_canonicalize_terms{args, globals}), span}
        case Ast.TermMat{key, head, matched, span}: Ast.TermMat{ canonical_name(key, globals),  checker_scc_run_176(CheckerSccCall_canonicalize_term{head, globals}),  checker_scc_run_176(CheckerSccCall_canonicalize_term{matched, globals}), span}
        case Ast.TermAbsurd{_}: term
        case Ast.TermEqual{left, right, ty, span}: Ast.TermEqual{ checker_scc_run_176(CheckerSccCall_canonicalize_term{left, globals}),  checker_scc_run_176(CheckerSccCall_canonicalize_term{right, globals}),  checker_scc_run_176(CheckerSccCall_canonicalize_term{ty, globals}), span}
        case Ast.TermRefl{_}: term
        case Ast.TermRewrite{equation, proof, body, span}: Ast.TermRewrite{ checker_scc_run_176(CheckerSccCall_canonicalize_term{equation, globals}),  checker_scc_run_176(CheckerSccCall_canonicalize_term{proof, globals}),  checker_scc_run_176(CheckerSccCall_canonicalize_term{body, globals}), span}
        case Ast.TermHole{_, _}: term
        case Ast.BodyMatch{scrutinees, cases, span}: Ast.BodyMatch{ checker_scc_run_176(CheckerSccCall_canonicalize_terms{scrutinees, globals}),  checker_scc_run_176(CheckerSccCall_canonicalize_terms{cases, globals}), span}
        case Ast.BodyCase{patterns, body, span}: Ast.BodyCase{ canonicalize_patterns(patterns, globals),  checker_scc_run_176(CheckerSccCall_canonicalize_term{body, globals}), span}
        case Ast.BodyLocal{patterns, quantity, values, body, span}: Ast.BodyLocal{ canonicalize_patterns(patterns, globals), quantity,  checker_scc_run_176(CheckerSccCall_canonicalize_terms{values, globals}),  checker_scc_run_176(CheckerSccCall_canonicalize_term{body, globals}), span}
        case Ast.BodyReply{term, span}: Ast.BodyReply{ checker_scc_run_176(CheckerSccCall_canonicalize_term{term, globals}), span}


def canonicalize_terms(terms: List<&2, Ast.SyntaxTerm>, globals: List<&2, Global>) -> List<&2, Ast.SyntaxTerm>:
  checker_scc_run_176(CheckerSccCall_canonicalize_terms{terms, globals})

def canonicalize_term(term: Ast.SyntaxTerm, globals: List<&2, Global>) -> Ast.SyntaxTerm:
  checker_scc_run_176(CheckerSccCall_canonicalize_term{term, globals})

def binder_count(binders: List<&2, Ast.TelescopeItem>) -> Nat:
  match binders:
    case Nil{}: 0n
    case +_ <> rest: 1n + binder_count(rest)

def check_binder_uses(binders: List<&2, Ast.TelescopeItem>, remaining: Nat, term: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, env: List<&2, Binding>, globals: List<&2, Global>) -> Maybe<&2, Diagnostic>:
  match binders:
    case Nil{}: None{}
    case +binder <> rest:
      match binder:
        case Ast.Binder{quantity, key,  _,  _, span}:
          target = remaining - 1n
          Bool.pick(Maybe<&2, Diagnostic>, quantity_fits(use_count_with_expected(term, target, env, globals, expected), quantity), check_binder_uses(rest, target, term, expected, env, globals), Some{Diagnostic{ span_file(span), span,  String.append("invalid use quantity for ", key),  "within the binder quantity",  "too many uses"}})
        case Ast.TemplateBinder{key,  _,  _, span}:
          target = remaining - 1n
          Bool.pick(Maybe<&2, Diagnostic>, quantity_fits(use_count_with_expected(term, target, env, globals, expected), Ast.QZero{}), check_binder_uses(rest, target, term, expected, env, globals), Some{Diagnostic{ span_file(span), span,  String.append("compile-time template binder used at runtime: ", key),  "no runtime uses",  "a runtime use"}})

def binders_env(binders: List<&2, Ast.TelescopeItem>, env: List<&2, Binding>) -> List<&2, Binding>:
  match binders:
    case Nil{}: env
    case +binder <> rest:
      match binder:
        case Ast.Binder{quantity, key,  _, ty,  _}: binders_env(rest, Binding{key, quantity, ty} <> env)
        case Ast.TemplateBinder{key,  _, ty,  _}: binders_env(rest, Binding{key,  Ast.QZero{}, ty} <> env)

def binders_type(binders: List<&2, Ast.TelescopeItem>, result: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  match binders:
    case Nil{}: result
    case +binder <> rest:
      match binder:
        case Ast.Binder{quantity, key, index, ty, span}: Ast.TermAll{quantity, key, index, ty,  binders_type(rest, result), span}
        case Ast.TemplateBinder{key, index, ty, span}: Ast.TermAll{ Ast.QZero{}, key, index, ty,  binders_type(rest, result), span}

def parameter_vars(params: List<&2, Ast.TelescopeItem>, remaining: Nat, span: Ast.SourceSpan) -> List<&2, Ast.SyntaxTerm>:
  match params:
    case Nil{}: Nil{}
    case +param <> rest:
      match param:
        case Ast.Binder{ _, key,  _,  _,  _}:
          target = remaining - 1n
          Ast.TermVar{key,  target, span} <> parameter_vars(rest, target, span)
        case Ast.TemplateBinder{key,  _,  _,  _}:
          target = remaining - 1n
          Ast.TermVar{key,  target, span} <> parameter_vars(rest, target, span)

def live_field_goal(quantity: Ast.Quantity, depth: Nat, family_kind: Ast.SyntaxTerm, span: Ast.SourceSpan) -> Ast.SyntaxTerm:
  match quantity:
    case Ast.QOne{}: Core.shift(0n, depth, family_kind)
    case _: Ast.TermType{Ast.TermQuantity{quantity, span}, span}

type CheckerSccInput183 is Data:
  CheckerSccCall_check_live_fields_result{result: Inference, rest: List<&2, Ast.TelescopeItem>, family_kind: Ast.SyntaxTerm, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>, key: String, quantity: Ast.Quantity, ty: Ast.SyntaxTerm, span: Ast.SourceSpan}
  CheckerSccCall_check_live_fields{fields: List<&2, Ast.TelescopeItem>, family_kind: Ast.SyntaxTerm, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>}

def checker_scc_result_183(request: CheckerSccInput183) -> Type:
  match request:
    case CheckerSccCall_check_live_fields_result{result, rest, family_kind, depth, env, globals, key, quantity, ty, span}: Maybe<&2, Diagnostic>
    case CheckerSccCall_check_live_fields{fields, family_kind, depth, env, globals}: Maybe<&2, Diagnostic>

def checker_scc_run_183(request: CheckerSccInput183) -> checker_scc_result_183(request):
  match request:
    case CheckerSccCall_check_live_fields_result{result, rest, family_kind, depth, env, globals, key, quantity, ty, span}:
      match result:
        case Inferred{ _,  _}: checker_scc_run_183(CheckerSccCall_check_live_fields{rest, family_kind, depth + 1n, Binding{key, quantity, ty} <> env, globals})
        case InferenceFailure{diagnostic}: Some{diagnostic}

    case CheckerSccCall_check_live_fields{fields, family_kind, depth, env, globals}:
      match fields:
        case Nil{}: None{}
        case +field <> rest:
          match field:
            case Ast.Binder{quantity, key,  _, ty, span}:
              field_goal = live_field_goal(quantity, depth, family_kind, span)
              checker_scc_run_183(CheckerSccCall_check_live_fields_result{check_term(ty, env, globals, field_goal), rest, family_kind, depth, env, globals, key, quantity, ty, span})
            case Ast.TemplateBinder{key, _, _, span}: Some{Diagnostic{ span_file(span), span,  String.append("constructor field cannot be a compile-time template binder: ", key),  "a runtime constructor field",  "a template binder"}}


def check_live_fields_result(result: Inference, rest: List<&2, Ast.TelescopeItem>, family_kind: Ast.SyntaxTerm, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>, key: String, quantity: Ast.Quantity, ty: Ast.SyntaxTerm, span: Ast.SourceSpan) -> Maybe<&2, Diagnostic>:
  checker_scc_run_183(CheckerSccCall_check_live_fields_result{result, rest, family_kind, depth, env, globals, key, quantity, ty, span})

def check_live_fields(fields: List<&2, Ast.TelescopeItem>, family_kind: Ast.SyntaxTerm, depth: Nat, env: List<&2, Binding>, globals: List<&2, Global>) -> Maybe<&2, Diagnostic>:
  checker_scc_run_183(CheckerSccCall_check_live_fields{fields, family_kind, depth, env, globals})

type CheckerSccInput184 is Data:
  CheckerSccCall_check_constructors_fields_result{result: Maybe<&2, Diagnostic>, rest: List<&2, Ast.ConstructorDecl>, family: String, params: List<&2, Ast.TelescopeItem>, family_kind: Ast.SyntaxTerm, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>, span: Ast.SourceSpan, key: String, ctr_span: Ast.SourceSpan, ctr_ty: Ast.SyntaxTerm}
  CheckerSccCall_check_constructors_type_result{result: Inference, fields: List<&2, Ast.TelescopeItem>, rest: List<&2, Ast.ConstructorDecl>, family: String, params: List<&2, Ast.TelescopeItem>, family_kind: Ast.SyntaxTerm, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>, span: Ast.SourceSpan, key: String, ctr_span: Ast.SourceSpan, ctr_ty: Ast.SyntaxTerm}
  CheckerSccCall_check_constructors_unique{found: Maybe<&2, Global>, fields: List<&2, Ast.TelescopeItem>, rest: List<&2, Ast.ConstructorDecl>, family: String, params: List<&2, Ast.TelescopeItem>, family_kind: Ast.SyntaxTerm, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>, span: Ast.SourceSpan, key: String, ctr_span: Ast.SourceSpan}
  CheckerSccCall_check_constructors{constructors: List<&2, Ast.ConstructorDecl>, family: String, params: List<&2, Ast.TelescopeItem>, family_kind: Ast.SyntaxTerm, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>, span: Ast.SourceSpan}

def checker_scc_result_184(request: CheckerSccInput184) -> Type:
  match request:
    case CheckerSccCall_check_constructors_fields_result{result, rest, family, params, family_kind, namespace, globals, visible, span, key, ctr_span, ctr_ty}: State
    case CheckerSccCall_check_constructors_type_result{result, fields, rest, family, params, family_kind, namespace, globals, visible, span, key, ctr_span, ctr_ty}: State
    case CheckerSccCall_check_constructors_unique{found, fields, rest, family, params, family_kind, namespace, globals, visible, span, key, ctr_span}: State
    case CheckerSccCall_check_constructors{constructors, family, params, family_kind, namespace, globals, visible, span}: State

def checker_scc_run_184(request: CheckerSccInput184) -> checker_scc_result_184(request):
  match request:
    case CheckerSccCall_check_constructors_fields_result{result, rest, family, params, family_kind, namespace, globals, visible, span, key, ctr_span, ctr_ty}:
      match result:
        case Some{diagnostic}: StateFailure{diagnostic}
        case None{}:
          canonical = Global{ canonical_key(namespace, key), namespace,  key,  canonicalize_term(ctr_ty, visible),  Ast.NoTerm{},  False{}}
          local = Global{key, namespace,  key,  ctr_ty,  Ast.NoTerm{},  False{}}
          checker_scc_run_184(CheckerSccCall_check_constructors{rest, family, params, family_kind, namespace, canonical <> globals, local <> visible, span})

    case CheckerSccCall_check_constructors_type_result{result, fields, rest, family, params, family_kind, namespace, globals, visible, span, key, ctr_span, ctr_ty}:
      match result:
        case Inferred{ _,  Ast.TermType{ _, _}}: checker_scc_run_184(CheckerSccCall_check_constructors_fields_result{check_live_fields(fields, family_kind, 0n, binders_env(params, Nil{}), visible), rest, family, params, family_kind, namespace, globals, visible, span, key, ctr_span, ctr_ty})
        case Inferred{ _,  _}: StateFailure{ Diagnostic{ span_file(ctr_span),  ctr_span,  String.append("constructor type is invalid: ", key),  "a constructor telescope returning its family",  "an invalid telescope"}}
        case InferenceFailure{diagnostic}: StateFailure{diagnostic}

    case CheckerSccCall_check_constructors_unique{found, fields, rest, family, params, family_kind, namespace, globals, visible, span, key, ctr_span}:
      match found:
        case Some{_}: StateFailure{ Diagnostic{ span_file(ctr_span),  ctr_span,  String.append("duplicate constructor: ", key),  "a fresh constructor name",  "an existing declaration"}}
        case None{}:
          param_terms = parameter_vars(params, binder_count(params), ctr_span)
          result_args = shift_terms(param_terms, binder_count(fields))
          result = Ast.TermAdt{ canonical_key(namespace, family),  result_args,  Nil{},  ctr_span}
          ctr_ty = binders_type(params, binders_type(fields, result))
          checker_scc_run_184(CheckerSccCall_check_constructors_type_result{infer(ctr_ty, Nil{}, visible), fields, rest, family, params, family_kind, namespace, globals, visible, span, key, ctr_span, ctr_ty})

    case CheckerSccCall_check_constructors{constructors, family, params, family_kind, namespace, globals, visible, span}:
      match constructors:
        case Nil{}: State{globals}
        case +constructor <> rest:
          match constructor:
            case Ast.Constructor{key, fields,  ctr_span}:
              checker_scc_run_184(CheckerSccCall_check_constructors_unique{lookup_global(canonical_key(namespace, key), globals), fields, rest, family, params, family_kind, namespace, globals, visible, span, key, ctr_span})



def check_constructors_fields_result(result: Maybe<&2, Diagnostic>, rest: List<&2, Ast.ConstructorDecl>, family: String, params: List<&2, Ast.TelescopeItem>, family_kind: Ast.SyntaxTerm, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>, span: Ast.SourceSpan, key: String, ctr_span: Ast.SourceSpan, ctr_ty: Ast.SyntaxTerm) -> State:
  checker_scc_run_184(CheckerSccCall_check_constructors_fields_result{result, rest, family, params, family_kind, namespace, globals, visible, span, key, ctr_span, ctr_ty})

def check_constructors_type_result(result: Inference, fields: List<&2, Ast.TelescopeItem>, rest: List<&2, Ast.ConstructorDecl>, family: String, params: List<&2, Ast.TelescopeItem>, family_kind: Ast.SyntaxTerm, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>, span: Ast.SourceSpan, key: String, ctr_span: Ast.SourceSpan, ctr_ty: Ast.SyntaxTerm) -> State:
  checker_scc_run_184(CheckerSccCall_check_constructors_type_result{result, fields, rest, family, params, family_kind, namespace, globals, visible, span, key, ctr_span, ctr_ty})

def check_constructors_unique(found: Maybe<&2, Global>, fields: List<&2, Ast.TelescopeItem>, rest: List<&2, Ast.ConstructorDecl>, family: String, params: List<&2, Ast.TelescopeItem>, family_kind: Ast.SyntaxTerm, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>, span: Ast.SourceSpan, key: String, ctr_span: Ast.SourceSpan) -> State:
  checker_scc_run_184(CheckerSccCall_check_constructors_unique{found, fields, rest, family, params, family_kind, namespace, globals, visible, span, key, ctr_span})

def check_constructors(constructors: List<&2, Ast.ConstructorDecl>, family: String, params: List<&2, Ast.TelescopeItem>, family_kind: Ast.SyntaxTerm, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>, span: Ast.SourceSpan) -> State:
  checker_scc_run_184(CheckerSccCall_check_constructors{constructors, family, params, family_kind, namespace, globals, visible, span})

def check_type_decl_result(result: Inference, key: String, params: List<&2, Ast.TelescopeItem>, kind: Ast.SyntaxTerm, constructors: List<&2, Ast.ConstructorDecl>, family: Global, family_local: Global, family_ty: Ast.SyntaxTerm, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>, span: Ast.SourceSpan) -> State:
  match result:
    case Inferred{ _,  Ast.TermType{ _, _}}: check_constructors(constructors, canonical_key(namespace, key), params, kind, namespace, family <> globals, family <> (family_local <> visible), span)
    case Inferred{ _,  _}: StateFailure{ Diagnostic{ span_file(span), span,  String.append("datatype signature is invalid: ", key),  "a kinded family signature",  "an invalid signature"}}
    case InferenceFailure{diagnostic}: StateFailure{diagnostic}

def check_import_foreign_head(found: Maybe<&2, String>, full_ty: Ast.SyntaxTerm, key: String, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>, span: Ast.SourceSpan) -> State:
  match found:
    case Some{head}:
      Bool.pick(State, String.eq(canonical_name(head, visible), canonical_name("IO", visible)), State{ Global{ canonical_key(namespace, key), namespace,  key,  canonicalize_term(full_ty, visible),  Ast.NoTerm{},  False{}} <> globals}, StateFailure{ Diagnostic{ span_file(span), span,  "foreign definition must return base IO directly",  "an IO result",  "a non-IO result"}})
    case None{}: StateFailure{ Diagnostic{ span_file(span), span,  "foreign definition must return base IO directly",  "an IO result",  "a non-IO result"}}

def foreign_head(term: Ast.SyntaxTerm) -> Maybe<&2, String>:
  match term:
    case Ast.TermRef{key,  _}: Some{key}
    case Ast.TermApp{fn,  _,  _}: foreign_head(fn)
    case Ast.TermAnn{ inner,  _,  _}: foreign_head(inner)
    case Ast.TermAll{ _, key, index,  _, body, span}:
      foreign_head(Core.subst(0n, Ast.TermVar{key,  0n, span}, body))
    case _: None{}

def check_import_type_result(result: Inference, key: String, full_ty: Ast.SyntaxTerm, result_ty: Ast.SyntaxTerm, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>, span: Ast.SourceSpan) -> State:
  match result:
    case Inferred{ _,  Ast.TermType{ _, _}}: check_import_foreign_head(foreign_head(result_ty), full_ty, key, namespace, globals, visible, span)
    case Inferred{ _,  _}: StateFailure{ Diagnostic{ span_file(span), span,  String.append("foreign signature is not a type: ", key),  "a type",  "a non-type"}}
    case InferenceFailure{diagnostic}: StateFailure{diagnostic}
def check_type_decl(declaration: Ast.TypeDecl, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>) -> State:
  match declaration:
    case Ast.TypeDecl{key, params, kind, constructors, span}:
      family_ty = binders_type(params, kind)
      family = Global{ canonical_key(namespace, key), namespace,  key,  canonicalize_term(family_ty, visible),  Ast.NoTerm{},  True{}}
      family_local = Global{key, namespace,  key,  family_ty,  Ast.NoTerm{},  True{}}
      check_type_decl_result(infer(family_ty, Nil{}, family <> (family_local <> visible)), key, params, kind, constructors, family, family_local, family_ty, namespace, globals, visible, span)

def check_import_definition(key: String, binders: List<&2, Ast.TelescopeItem>, result: Ast.OptionalTerm, paths: List<&2, String>, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>, span: Ast.SourceSpan) -> State:
  match result:
    case Ast.SomeTerm{ result_ty}:
      full_ty = binders_type(binders, result_ty)
      check_import_type_result(infer(full_ty, Nil{}, visible), key, full_ty, result_ty, namespace, globals, visible, span)
    case Ast.NoTerm{}: StateFailure{ Diagnostic{ span_file(span), span,  String.append("foreign definition has no signature: ", key),  "a declared result type",  "no result type"}}

def application_head(term: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  match term:
    case Ast.TermBang{ inner,  _}: application_head(inner)
    case Ast.TermApp{fn,  _,  _}: application_head(fn)
    case Ast.TermAnn{ inner,  _,  _}: application_head(inner)
    case Ast.TermSub{index, value, body,  _}: application_head(Core.subst(index, value, body))
    case _: term

def application_args(term: Ast.SyntaxTerm) -> List<&2, Ast.SyntaxTerm>:
  match term:
    case Ast.TermApp{fn, arg,  _}: List.append(&2, Ast.SyntaxTerm, application_args(fn), [arg])
    case Ast.TermAnn{ inner,  _,  _}: application_args(inner)
    case Ast.TermSub{index, value, body,  _}: application_args(Core.subst(index, value, body))
    case _: Nil{}

def strip_order_annotation(term: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  match term:
    case Ast.TermAnn{ inner,  _,  _}: strip_order_annotation(inner)
    case _: term

type CheckerSccInput194 is Data:
  CheckerSccCall_term_descend{quantity: Ast.Quantity, actual: Ast.SyntaxTerm, original: Ast.SyntaxTerm}
  CheckerSccCall_term_descend_raw{quantity: Ast.Quantity, actual: Ast.SyntaxTerm, original: Ast.SyntaxTerm}
  CheckerSccCall_term_descend_live{actual: Ast.SyntaxTerm, original: Ast.SyntaxTerm}
  CheckerSccCall_term_descend_constructor_result{result: TermOrder, actual: Ast.SyntaxTerm, original_args: List<&2, Ast.SyntaxTerm>}
  CheckerSccCall_term_descend_list_result{result: TermOrder, actual_rest: List<&2, Ast.SyntaxTerm>, original_rest: List<&2, Ast.SyntaxTerm>}
  CheckerSccCall_term_descend_list{actual: List<&2, Ast.SyntaxTerm>, original: List<&2, Ast.SyntaxTerm>}
  CheckerSccCall_term_is_subterm_result{result: TermOrder, actual: Ast.SyntaxTerm, rest: List<&2, Ast.SyntaxTerm>}
  CheckerSccCall_term_is_subterm{actual: Ast.SyntaxTerm, fields: List<&2, Ast.SyntaxTerm>}

def checker_scc_result_194(request: CheckerSccInput194) -> Type:
  match request:
    case CheckerSccCall_term_descend{quantity, actual, original}: TermOrder
    case CheckerSccCall_term_descend_raw{quantity, actual, original}: TermOrder
    case CheckerSccCall_term_descend_live{actual, original}: TermOrder
    case CheckerSccCall_term_descend_constructor_result{result, actual, original_args}: TermOrder
    case CheckerSccCall_term_descend_list_result{result, actual_rest, original_rest}: TermOrder
    case CheckerSccCall_term_descend_list{actual, original}: TermOrder
    case CheckerSccCall_term_is_subterm_result{result, actual, rest}: TermOrder
    case CheckerSccCall_term_is_subterm{actual, fields}: TermOrder

def checker_scc_run_194(request: CheckerSccInput194) -> checker_scc_result_194(request):
  match request:
    case CheckerSccCall_term_descend{quantity, actual, original}:
      checker_scc_run_194(CheckerSccCall_term_descend_raw{quantity, strip_order_annotation(actual), strip_order_annotation(original)})

    case CheckerSccCall_term_descend_raw{quantity, actual, original}:
      match quantity:
        case Ast.QZero{}: OrderEqual{}
        case _: checker_scc_run_194(CheckerSccCall_term_descend_live{actual, original})

    case CheckerSccCall_term_descend_live{actual, original}:
      match actual original:
        case Ast.TermVar{_, actual_index, _} Ast.TermVar{_, original_index, _}:
          Bool.pick(TermOrder, Nat.is_eq(actual_index, original_index), OrderEqual{}, OrderGreater{})
        case Ast.TermCtr{actual_key, actual_args, _} Ast.TermCtr{original_key, original_args, _}:
          Bool.pick(TermOrder, String.eq(actual_key, original_key), checker_scc_run_194(CheckerSccCall_term_descend_constructor_result{checker_scc_run_194(CheckerSccCall_term_descend_list{actual_args, original_args}), actual, original_args}), checker_scc_run_194(CheckerSccCall_term_is_subterm{actual, original_args}))
        case _ Ast.TermCtr{_, original_args, _}: checker_scc_run_194(CheckerSccCall_term_is_subterm{actual, original_args})
        case _ _: OrderGreater{}

    case CheckerSccCall_term_descend_constructor_result{result, actual, original_args}:
      match result:
        case OrderEqual{}: OrderEqual{}
        case OrderLess{}: OrderLess{}
        case OrderGreater{}: checker_scc_run_194(CheckerSccCall_term_is_subterm{actual, original_args})
    case CheckerSccCall_term_descend_list_result{result, actual_rest, original_rest}:
      match result:
        case OrderEqual{}: checker_scc_run_194(CheckerSccCall_term_descend_list{actual_rest, original_rest})
        case OrderLess{}: OrderLess{}
        case OrderGreater{}: OrderGreater{}

    case CheckerSccCall_term_descend_list{actual, original}:
      match actual original:
        case Nil{} Nil{}: OrderEqual{}
        case +actual_term <> actual_rest +original_term <> original_rest: checker_scc_run_194(CheckerSccCall_term_descend_list_result{checker_scc_run_194(CheckerSccCall_term_descend{Ast.QOne{}, actual_term, original_term}), actual_rest, original_rest})
        case _ _: OrderGreater{}

    case CheckerSccCall_term_is_subterm_result{result, actual, rest}:
      match result:
        case OrderGreater{}: checker_scc_run_194(CheckerSccCall_term_is_subterm{actual, rest})
        case _: OrderLess{}

    case CheckerSccCall_term_is_subterm{actual, fields}:
      match fields:
        case Nil{}: OrderGreater{}
        case +field <> rest: checker_scc_run_194(CheckerSccCall_term_is_subterm_result{checker_scc_run_194(CheckerSccCall_term_descend{Ast.QOne{}, actual, field}), actual, rest})


def term_descend(quantity: Ast.Quantity, actual: Ast.SyntaxTerm, original: Ast.SyntaxTerm) -> TermOrder:
  checker_scc_run_194(CheckerSccCall_term_descend{quantity, actual, original})

def term_descend_raw(quantity: Ast.Quantity, actual: Ast.SyntaxTerm, original: Ast.SyntaxTerm) -> TermOrder:
  checker_scc_run_194(CheckerSccCall_term_descend_raw{quantity, actual, original})

def term_descend_live(actual: Ast.SyntaxTerm, original: Ast.SyntaxTerm) -> TermOrder:
  checker_scc_run_194(CheckerSccCall_term_descend_live{actual, original})

def term_descend_constructor_result(result: TermOrder, actual: Ast.SyntaxTerm, original_args: List<&2, Ast.SyntaxTerm>) -> TermOrder:
  checker_scc_run_194(CheckerSccCall_term_descend_constructor_result{result, actual, original_args})

def term_descend_list_result(result: TermOrder, actual_rest: List<&2, Ast.SyntaxTerm>, original_rest: List<&2, Ast.SyntaxTerm>) -> TermOrder:
  checker_scc_run_194(CheckerSccCall_term_descend_list_result{result, actual_rest, original_rest})

def term_descend_list(actual: List<&2, Ast.SyntaxTerm>, original: List<&2, Ast.SyntaxTerm>) -> TermOrder:
  checker_scc_run_194(CheckerSccCall_term_descend_list{actual, original})

def term_is_subterm_result(result: TermOrder, actual: Ast.SyntaxTerm, rest: List<&2, Ast.SyntaxTerm>) -> TermOrder:
  checker_scc_run_194(CheckerSccCall_term_is_subterm_result{result, actual, rest})

def term_is_subterm(actual: Ast.SyntaxTerm, fields: List<&2, Ast.SyntaxTerm>) -> TermOrder:
  checker_scc_run_194(CheckerSccCall_term_is_subterm{actual, fields})

type CheckerSccInput195 is Data:
  CheckerSccCall_recursive_call_decrease_result{result: TermOrder, args_rest: List<&2, Ast.SyntaxTerm>, columns_rest: List<&2, Ast.SyntaxTerm>, quantities_rest: List<&2, Ast.Quantity>}
  CheckerSccCall_recursive_call_decreases{args: List<&2, Ast.SyntaxTerm>, columns: List<&2, Ast.SyntaxTerm>, quantities: List<&2, Ast.Quantity>}

def checker_scc_result_195(request: CheckerSccInput195) -> Type:
  match request:
    case CheckerSccCall_recursive_call_decrease_result{result, args_rest, columns_rest, quantities_rest}: Bool
    case CheckerSccCall_recursive_call_decreases{args, columns, quantities}: Bool

def checker_scc_run_195(request: CheckerSccInput195) -> checker_scc_result_195(request):
  match request:
    case CheckerSccCall_recursive_call_decrease_result{result, args_rest, columns_rest, quantities_rest}:
      match result:
        case OrderLess{}: True{}
        case OrderEqual{}: checker_scc_run_195(CheckerSccCall_recursive_call_decreases{args_rest, columns_rest, quantities_rest})
        case OrderGreater{}: False{}

    case CheckerSccCall_recursive_call_decreases{args, columns, quantities}:
      match args columns quantities:
        case Nil{} _ _: False{}
        case _ Nil{} _: False{}
        case _ _ Nil{}: False{}
        case +arg <> args_rest +column <> columns_rest +quantity <> quantities_rest:
          checker_scc_run_195(CheckerSccCall_recursive_call_decrease_result{term_descend(quantity, arg, column), args_rest, columns_rest, quantities_rest})


def recursive_call_decrease_result(result: TermOrder, args_rest: List<&2, Ast.SyntaxTerm>, columns_rest: List<&2, Ast.SyntaxTerm>, quantities_rest: List<&2, Ast.Quantity>) -> Bool:
  checker_scc_run_195(CheckerSccCall_recursive_call_decrease_result{result, args_rest, columns_rest, quantities_rest})

def recursive_call_decreases(args: List<&2, Ast.SyntaxTerm>, columns: List<&2, Ast.SyntaxTerm>, quantities: List<&2, Ast.Quantity>) -> Bool:
  checker_scc_run_195(CheckerSccCall_recursive_call_decreases{args, columns, quantities})

def binders_quantities(binders: List<&2, Ast.TelescopeItem>) -> List<&2, Ast.Quantity>:
  match binders:
    case Nil{}: Nil{}
    case +binder <> rest:
      match binder:
        case Ast.Binder{quantity,  _,  _,  _,  _}: quantity <> binders_quantities(rest)
        case Ast.TemplateBinder{ _,  _,  _,  _}: Ast.QZero{} <> binders_quantities(rest)

type CheckerSccInput197 is Data:
  CheckerSccCall_replace_order_var{term: Ast.SyntaxTerm, index: Nat, replacement: Ast.SyntaxTerm}
  CheckerSccCall_replace_order_vars{terms: List<&2, Ast.SyntaxTerm>, index: Nat, replacement: Ast.SyntaxTerm}

def checker_scc_result_197(request: CheckerSccInput197) -> Type:
  match request:
    case CheckerSccCall_replace_order_var{term, index, replacement}: Ast.SyntaxTerm
    case CheckerSccCall_replace_order_vars{terms, index, replacement}: List<&2, Ast.SyntaxTerm>

def checker_scc_run_197(request: CheckerSccInput197) -> checker_scc_result_197(request):
  match request:
    case CheckerSccCall_replace_order_var{term, index, replacement}:
      match term:
        case Ast.TermVar{key,  found, span}:
          Bool.pick(Ast.SyntaxTerm, Nat.is_eq(found, index), replacement, Ast.TermVar{key,  found, span})
        case Ast.TermCtr{key, args, span}: Ast.TermCtr{key,  checker_scc_run_197(CheckerSccCall_replace_order_vars{args, index, replacement}), span}
        case _: term

    case CheckerSccCall_replace_order_vars{terms, index, replacement}:
      match terms:
        case Nil{}: Nil{}
        case +term <> rest: checker_scc_run_197(CheckerSccCall_replace_order_var{term, index, replacement}) <> checker_scc_run_197(CheckerSccCall_replace_order_vars{rest, index, replacement})


def replace_order_var(term: Ast.SyntaxTerm, index: Nat, replacement: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  checker_scc_run_197(CheckerSccCall_replace_order_var{term, index, replacement})

def replace_order_vars(terms: List<&2, Ast.SyntaxTerm>, index: Nat, replacement: Ast.SyntaxTerm) -> List<&2, Ast.SyntaxTerm>:
  checker_scc_run_197(CheckerSccCall_replace_order_vars{terms, index, replacement})

def branch_order_column(column: Ast.SyntaxTerm, scrutinees: List<&2, Ast.SyntaxTerm>, patterns: List<&2, Ast.SyntaxPattern>, final_depth: Nat, added: Nat) -> Ast.SyntaxTerm:
  match scrutinees patterns:
    case Nil{} _: Core.shift(0n, added, column)
    case _ Nil{}: Core.shift(0n, added, column)
    case Ast.TermVar{_, index, _} <> scrutinee_rest +pattern <> pattern_rest:
      shifted = Core.shift(0n, added, column)
      replacement = pattern_value(pattern, final_depth)
      branch_order_column(replace_order_var(shifted, index + added, replacement), scrutinee_rest, pattern_rest, final_depth, added)
    case +_ <> scrutinee_rest +_ <> pattern_rest:
      branch_order_column(Core.shift(0n, added, column), scrutinee_rest, pattern_rest, final_depth, added)

def branch_order_columns(columns: List<&2, Ast.SyntaxTerm>, scrutinees: List<&2, Ast.SyntaxTerm>, patterns: List<&2, Ast.SyntaxPattern>, final_depth: Nat, added: Nat) -> List<&2, Ast.SyntaxTerm>:
  match columns:
    case Nil{}: Nil{}
    case +column <> rest: branch_order_column(column, scrutinees, patterns, final_depth, added) <> branch_order_columns(rest, scrutinees, patterns, final_depth, added)

def constructor_field_arity_family_global(found: Maybe<&2, Global>, ty: Ast.SyntaxTerm, globals: List<&2, Global>) -> Maybe<&2, Nat>:
  match found:
    case None{}: None{}
    case Some{family_global}:
      match family_global:
        case Global{ _,  _,  _,  family_ty,  _,  _}:
          parameters = initial_telescope_count(family_ty, globals)
          Some{initial_telescope_count(drop_telescope(parameters, ty, globals), globals)}

def constructor_field_arity_family(found: Maybe<&2, String>, ty: Ast.SyntaxTerm, globals: List<&2, Global>) -> Maybe<&2, Nat>:
  match found:
    case None{}: None{}
    case Some{family}: constructor_field_arity_family_global(lookup_global(family, globals), ty, globals)

def constructor_field_arity_global(global: Global, globals: List<&2, Global>) -> Maybe<&2, Nat>:
  match global:
    case Global{ _,  _,  _, ty,  _,  _}: constructor_field_arity_family(constructor_family(ty, globals), ty, globals)

def constructor_field_arity_result(found: Maybe<&2, Global>, globals: List<&2, Global>) -> Maybe<&2, Nat>:
  match found:
    case None{}: None{}
    case Some{global}: constructor_field_arity_global(global, globals)

def constructor_field_arity(key: String, globals: List<&2, Global>) -> Maybe<&2, Nat>:
  constructor_field_arity_result(lookup_global(key, globals), globals)

def replace_first_column_with_value(columns: List<&2, Ast.SyntaxTerm>, value: Ast.SyntaxTerm) -> List<&2, Ast.SyntaxTerm>:
  match columns:
    case Nil{}: Nil{}
    case +_ <> rest: value <> rest


type CheckerSccInput206 is Data:
  CheckerSccCall_recursion_terminates_mat_head{head: Ast.SyntaxTerm, key: String, matched_key: String, field_count: Nat, columns: List<&2, Ast.SyntaxTerm>, quantities: List<&2, Ast.Quantity>, depth: Nat, fields: List<&2, Ast.SyntaxTerm>, globals: List<&2, Global>}
  CheckerSccCall_recursion_terminates_application_view{view: Ast.SyntaxTerm, term: Ast.SyntaxTerm, fn: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, key: String, columns: List<&2, Ast.SyntaxTerm>, quantities: List<&2, Ast.Quantity>, depth: Nat, globals: List<&2, Global>}
  CheckerSccCall_recursion_terminates_mat_arity{found: Maybe<&2, Nat>, head: Ast.SyntaxTerm, matched: Ast.SyntaxTerm, matched_key: String, key: String, columns: List<&2, Ast.SyntaxTerm>, quantities: List<&2, Ast.Quantity>, depth: Nat, globals: List<&2, Global>}
  CheckerSccCall_recursion_terminates{term: Ast.SyntaxTerm, key: String, columns: List<&2, Ast.SyntaxTerm>, quantities: List<&2, Ast.Quantity>, depth: Nat, globals: List<&2, Global>}
  CheckerSccCall_recursion_terminates_cases{cases: List<&2, Ast.SyntaxTerm>, scrutinees: List<&2, Ast.SyntaxTerm>, key: String, columns: List<&2, Ast.SyntaxTerm>, quantities: List<&2, Ast.Quantity>, depth: Nat, globals: List<&2, Global>}
  CheckerSccCall_recursion_terminates_list{terms: List<&2, Ast.SyntaxTerm>, key: String, columns: List<&2, Ast.SyntaxTerm>, quantities: List<&2, Ast.Quantity>, depth: Nat, globals: List<&2, Global>}
  CheckerSccCall_recursion_terminates_call_args{args: List<&2, Ast.SyntaxTerm>, key: String, columns: List<&2, Ast.SyntaxTerm>, quantities: List<&2, Ast.Quantity>, depth: Nat, globals: List<&2, Global>}

def checker_scc_result_206(request: CheckerSccInput206) -> Type:
  match request:
    case CheckerSccCall_recursion_terminates_mat_head{head, key, matched_key, field_count, columns, quantities, depth, fields, globals}: Bool
    case CheckerSccCall_recursion_terminates_application_view{view, term, fn, arg, key, columns, quantities, depth, globals}: Bool
    case CheckerSccCall_recursion_terminates_mat_arity{found, head, matched, matched_key, key, columns, quantities, depth, globals}: Bool
    case CheckerSccCall_recursion_terminates{term, key, columns, quantities, depth, globals}: Bool
    case CheckerSccCall_recursion_terminates_cases{cases, scrutinees, key, columns, quantities, depth, globals}: Bool
    case CheckerSccCall_recursion_terminates_list{terms, key, columns, quantities, depth, globals}: Bool
    case CheckerSccCall_recursion_terminates_call_args{args, key, columns, quantities, depth, globals}: Bool

def checker_scc_run_206(request: CheckerSccInput206) -> checker_scc_result_206(request):
  match request:
    case CheckerSccCall_recursion_terminates_mat_head{head, key, matched_key, field_count, columns, quantities, depth, fields, globals}:
      match head field_count:
        case _ 0n:
          value = Ast.TermCtr{ matched_key,  fields,  term_span(head)}
          next_columns = replace_first_column_with_value(shift_terms(columns, List.length(&2, Ast.SyntaxTerm, fields)), value)
          checker_scc_run_206(CheckerSccCall_recursion_terminates{head, key, next_columns, quantities, depth + List.length(&2, Ast.SyntaxTerm, fields), globals})
        case Ast.TermLam{Some{Ast.QZero{}}, _, _, _, _} 1n+_: True{}
        case Ast.TermLam{_, _, _, body, span} 1n+rest:
          next_fields = List.append(&2, Ast.SyntaxTerm, shift_terms(fields, 1n), [Ast.TermVar{"", 0n, span}])
          checker_scc_run_206(CheckerSccCall_recursion_terminates_mat_head{body, key, matched_key, rest, columns, quantities, depth, next_fields, globals})
        case _ _: False{}

    case CheckerSccCall_recursion_terminates_application_view{view, term, fn, arg, key, columns, quantities, depth, globals}:
      match view:
        case Ast.TermRef{ found,  _}:
          Bool.pick(Bool, String.eq(found, key), Bool.and(recursive_call_decreases(application_args(term), columns, quantities), checker_scc_run_206(CheckerSccCall_recursion_terminates_call_args{application_args(term), key, columns, quantities, depth, globals})), Bool.and(checker_scc_run_206(CheckerSccCall_recursion_terminates{fn, key, columns, quantities, depth, globals}), checker_scc_run_206(CheckerSccCall_recursion_terminates{arg, key, columns, quantities, depth, globals})))
        case _: checker_scc_run_206(CheckerSccCall_recursion_terminates{fn, key, columns, quantities, depth, globals}) && checker_scc_run_206(CheckerSccCall_recursion_terminates{arg, key, columns, quantities, depth, globals})

    case CheckerSccCall_recursion_terminates_mat_arity{found, head, matched, matched_key, key, columns, quantities, depth, globals}:
      match found:
        case Some{ field_count}: checker_scc_run_206(CheckerSccCall_recursion_terminates_mat_head{head, key, canonical_name(matched_key, globals), field_count, columns, quantities, depth, Nil{}, globals}) && checker_scc_run_206(CheckerSccCall_recursion_terminates{matched, key, columns, quantities, depth, globals})
        case None{}: checker_scc_run_206(CheckerSccCall_recursion_terminates{head, key, columns, quantities, depth, globals}) && checker_scc_run_206(CheckerSccCall_recursion_terminates{matched, key, columns, quantities, depth, globals})

    case CheckerSccCall_recursion_terminates{term, key, columns, quantities, depth, globals}:
      match term:
        case Ast.TermRef{ found,  _}: Bool.not(String.eq(found, key))
        case Ast.TermBang{ inner,  _}: checker_scc_run_206(CheckerSccCall_recursion_terminates{inner, key, columns, quantities, depth, globals})
        case Ast.TermApp{fn, arg,  _}: checker_scc_run_206(CheckerSccCall_recursion_terminates_application_view{application_head(term), term, fn, arg, key, columns, quantities, depth, globals})
        case Ast.TermFill{head, args,  _}: checker_scc_run_206(CheckerSccCall_recursion_terminates{head, key, columns, quantities, depth, globals}) && checker_scc_run_206(CheckerSccCall_recursion_terminates_list{args, key, columns, quantities, depth, globals})
        case Ast.TermPlus{head, args,  _}: checker_scc_run_206(CheckerSccCall_recursion_terminates{head, key, columns, quantities, depth, globals}) && checker_scc_run_206(CheckerSccCall_recursion_terminates_list{args, key, columns, quantities, depth, globals})
        case Ast.TermMat{ matched_key, head, matched,  _}: checker_scc_run_206(CheckerSccCall_recursion_terminates_mat_arity{constructor_field_arity(matched_key, globals), head, matched, matched_key, key, columns, quantities, depth, globals})
        case Ast.TermLam{ Some{ Ast.QZero{}},  _,  _,  _,  _}: True{}
        case Ast.TermLam{ _,  _,  _, body,  _}: checker_scc_run_206(CheckerSccCall_recursion_terminates{body, key, shift_terms(columns, 1n), quantities, depth + 1n, globals})
        case Ast.TermAll{_, _, _, _, _, _}: True{}
        case Ast.TermType{_, _}: True{}
        case Ast.TermMin{left, right,  _}: checker_scc_run_206(CheckerSccCall_recursion_terminates{left, key, columns, quantities, depth, globals}) && checker_scc_run_206(CheckerSccCall_recursion_terminates{right, key, columns, quantities, depth, globals})
        case Ast.TermAdt{_, _, _, _}: True{}
        case Ast.TermCtr{ _, args,  _}: checker_scc_run_206(CheckerSccCall_recursion_terminates_list{args, key, columns, quantities, depth, globals})
        case Ast.TermEqual{_, _, _, _}: True{}
        case Ast.TermRewrite{equation,  _, body,  _}: checker_scc_run_206(CheckerSccCall_recursion_terminates{equation, key, columns, quantities, depth, globals}) && checker_scc_run_206(CheckerSccCall_recursion_terminates{body, key, columns, quantities, depth, globals})
        case Ast.TermAnn{ inner,  _,  _}: checker_scc_run_206(CheckerSccCall_recursion_terminates{inner, key, columns, quantities, depth, globals})
        case Ast.TermTemplate{ _,  _}: True{}
        case Ast.TermLet{keys, _, _, values, body, _}: checker_scc_run_206(CheckerSccCall_recursion_terminates_list{values, key, columns, quantities, depth, globals}) && checker_scc_run_206(CheckerSccCall_recursion_terminates{body, key, shift_terms(columns, List.length(&2, String, keys)), quantities, depth + List.length(&2, String, keys), globals})
        case Ast.TermSub{index, value, body,  _}: checker_scc_run_206(CheckerSccCall_recursion_terminates{Core.subst(index, value, body), key, columns, quantities, depth, globals})
        case Ast.BodyMatch{scrutinees, cases,  _}: checker_scc_run_206(CheckerSccCall_recursion_terminates_list{scrutinees, key, columns, quantities, depth, globals}) && checker_scc_run_206(CheckerSccCall_recursion_terminates_cases{cases, scrutinees, key, columns, quantities, depth, globals})
        case Ast.BodyCase{ _, body,  _}: checker_scc_run_206(CheckerSccCall_recursion_terminates{body, key, columns, quantities, depth, globals})
        case Ast.BodyLocal{patterns, _, values, body, _}: checker_scc_run_206(CheckerSccCall_recursion_terminates_list{values, key, columns, quantities, depth, globals}) && checker_scc_run_206(CheckerSccCall_recursion_terminates{body, key, shift_terms(columns, Core.pattern_list_depth(patterns)), quantities, depth + Core.pattern_list_depth(patterns), globals})
        case Ast.BodyReply{ inner,  _}: checker_scc_run_206(CheckerSccCall_recursion_terminates{inner, key, columns, quantities, depth, globals})
        case Ast.TermHole{_, _}: True{}
        case _: True{}

    case CheckerSccCall_recursion_terminates_cases{cases, scrutinees, key, columns, quantities, depth, globals}:
      match cases:
        case Nil{}: True{}
        case +case_term <> rest:
          match case_term:
            case Ast.BodyCase{patterns, body,  _}:
              added = Core.pattern_list_depth(patterns)
              next_columns = branch_order_columns(columns, scrutinees, patterns, depth + added, added)
              checker_scc_run_206(CheckerSccCall_recursion_terminates{body, key, next_columns, quantities, depth + added, globals}) && checker_scc_run_206(CheckerSccCall_recursion_terminates_cases{rest, scrutinees, key, columns, quantities, depth, globals})
            case _: checker_scc_run_206(CheckerSccCall_recursion_terminates{case_term, key, columns, quantities, depth, globals}) && checker_scc_run_206(CheckerSccCall_recursion_terminates_cases{rest, scrutinees, key, columns, quantities, depth, globals})

    case CheckerSccCall_recursion_terminates_list{terms, key, columns, quantities, depth, globals}:
      match terms:
        case Nil{}: True{}
        case +term <> rest: checker_scc_run_206(CheckerSccCall_recursion_terminates{term, key, columns, quantities, depth, globals}) && checker_scc_run_206(CheckerSccCall_recursion_terminates_list{rest, key, columns, quantities, depth, globals})

    case CheckerSccCall_recursion_terminates_call_args{args, key, columns, quantities, depth, globals}:
      match args quantities:
        case Nil{} _: True{}
        case +arg <> args_rest +quantity <> quantities_rest:
          match quantity:
            case Ast.QZero{}: checker_scc_run_206(CheckerSccCall_recursion_terminates_call_args{args_rest, key, columns, quantities_rest, depth, globals})
            case _: checker_scc_run_206(CheckerSccCall_recursion_terminates{arg, key, columns, quantities, depth, globals}) && checker_scc_run_206(CheckerSccCall_recursion_terminates_call_args{args_rest, key, columns, quantities_rest, depth, globals})
        case +arg <> args_rest Nil{}: checker_scc_run_206(CheckerSccCall_recursion_terminates{arg, key, columns, quantities, depth, globals}) && checker_scc_run_206(CheckerSccCall_recursion_terminates_list{args_rest, key, columns, quantities, depth, globals})


def recursion_terminates_mat_head(head: Ast.SyntaxTerm, key: String, matched_key: String, field_count: Nat, columns: List<&2, Ast.SyntaxTerm>, quantities: List<&2, Ast.Quantity>, depth: Nat, fields: List<&2, Ast.SyntaxTerm>, globals: List<&2, Global>) -> Bool:
  checker_scc_run_206(CheckerSccCall_recursion_terminates_mat_head{head, key, matched_key, field_count, columns, quantities, depth, fields, globals})

def recursion_terminates_application_view(view: Ast.SyntaxTerm, term: Ast.SyntaxTerm, fn: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, key: String, columns: List<&2, Ast.SyntaxTerm>, quantities: List<&2, Ast.Quantity>, depth: Nat, globals: List<&2, Global>) -> Bool:
  checker_scc_run_206(CheckerSccCall_recursion_terminates_application_view{view, term, fn, arg, key, columns, quantities, depth, globals})

def recursion_terminates_mat_arity(found: Maybe<&2, Nat>, head: Ast.SyntaxTerm, matched: Ast.SyntaxTerm, matched_key: String, key: String, columns: List<&2, Ast.SyntaxTerm>, quantities: List<&2, Ast.Quantity>, depth: Nat, globals: List<&2, Global>) -> Bool:
  checker_scc_run_206(CheckerSccCall_recursion_terminates_mat_arity{found, head, matched, matched_key, key, columns, quantities, depth, globals})

def recursion_terminates(term: Ast.SyntaxTerm, key: String, columns: List<&2, Ast.SyntaxTerm>, quantities: List<&2, Ast.Quantity>, depth: Nat, globals: List<&2, Global>) -> Bool:
  checker_scc_run_206(CheckerSccCall_recursion_terminates{term, key, columns, quantities, depth, globals})

def recursion_terminates_cases(cases: List<&2, Ast.SyntaxTerm>, scrutinees: List<&2, Ast.SyntaxTerm>, key: String, columns: List<&2, Ast.SyntaxTerm>, quantities: List<&2, Ast.Quantity>, depth: Nat, globals: List<&2, Global>) -> Bool:
  checker_scc_run_206(CheckerSccCall_recursion_terminates_cases{cases, scrutinees, key, columns, quantities, depth, globals})

def recursion_terminates_list(terms: List<&2, Ast.SyntaxTerm>, key: String, columns: List<&2, Ast.SyntaxTerm>, quantities: List<&2, Ast.Quantity>, depth: Nat, globals: List<&2, Global>) -> Bool:
  checker_scc_run_206(CheckerSccCall_recursion_terminates_list{terms, key, columns, quantities, depth, globals})

def recursion_terminates_call_args(args: List<&2, Ast.SyntaxTerm>, key: String, columns: List<&2, Ast.SyntaxTerm>, quantities: List<&2, Ast.Quantity>, depth: Nat, globals: List<&2, Global>) -> Bool:
  checker_scc_run_206(CheckerSccCall_recursion_terminates_call_args{args, key, columns, quantities, depth, globals})

def check_termination_result(terminates: Bool, key: String, span: Ast.SourceSpan) -> Maybe<&2, Diagnostic>:
  Bool.pick(Maybe<&2, Diagnostic>, terminates, None{}, Some{Diagnostic{ span_file(span), span,  String.append("definition is not structurally terminating: ", key),  "a strictly decreasing recursive call",  "a non-decreasing or unguarded call"}})

def check_termination(unsafe: Bool, key: String, binders: List<&2, Ast.TelescopeItem>, term: Ast.SyntaxTerm, span: Ast.SourceSpan, globals: List<&2, Global>) -> Maybe<&2, Diagnostic>:
  match unsafe:
    case True{}: None{}
    case False{}:
      count = binder_count(binders)
      columns = parameter_vars(binders, count, span)
      quantities = binders_quantities(binders)
      check_termination_result(recursion_terminates(term, key, columns, quantities, count, globals), key, span)

def validate_definition_termination(result: Maybe<&2, Diagnostic>, binders: List<&2, Ast.TelescopeItem>, term: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, globals: List<&2, Global>) -> Maybe<&2, Diagnostic>:
  match result:
    case Some{diagnostic}: Some{diagnostic}
    case None{}: check_binder_uses(binders, binder_count(binders), term, expected, binders_env(binders, Nil{}), globals)

def validate_definition_uses(unsafe: Bool, key: String, binders: List<&2, Ast.TelescopeItem>, term: Ast.SyntaxTerm, expected: Ast.SyntaxTerm, span: Ast.SourceSpan, globals: List<&2, Global>) -> Maybe<&2, Diagnostic>:
  validate_definition_termination(check_termination(unsafe, key, binders, term, span, globals), binders, term, expected, globals)


def store_definition_declared(global: Global, key: String, namespace: String, canonical_ty: Ast.SyntaxTerm, canonical_term: Ast.SyntaxTerm, globals: List<&2, Global>, visible: List<&2, Global>, span: Ast.SourceSpan) -> State:
  match global:
    case Global{ _,  _,  _,  declared_ty,  Ast.NoTerm{},  _}:
      canonical_declared_ty = canonicalize_term(declared_ty, visible)
      Bool.pick(State, fits_term(canonical_ty, canonical_declared_ty, visible), State{ Global{ canonical_key(namespace, key), namespace,  key,  canonical_declared_ty,  Ast.SomeTerm{ canonical_term},  False{}} <> globals}, StateFailure{ Diagnostic{ span_file(span), span,  String.append("definition does not fill its declared type: ", key),  "the existing declaration type",  "an incompatible inferred type"}})
    case _: StateFailure{ Diagnostic{ span_file(span), span,  String.append("duplicate declaration: ", key),  "a fresh declaration name",  "an existing definition"}}

def store_definition_result(found: Maybe<&2, Global>, key: String, namespace: String, canonical_ty: Ast.SyntaxTerm, canonical_term: Ast.SyntaxTerm, globals: List<&2, Global>, visible: List<&2, Global>, span: Ast.SourceSpan) -> State:
  match found:
    case None{}: State{ Global{ canonical_key(namespace, key), namespace,  key,  canonical_ty,  Ast.SomeTerm{ canonical_term},  False{}} <> globals}
    case Some{global}: store_definition_declared(global, key, namespace, canonical_ty, canonical_term, globals, visible, span)

def store_definition(key: String, namespace: String, full_ty: Ast.SyntaxTerm, term: Ast.SyntaxTerm, globals: List<&2, Global>, visible: List<&2, Global>, span: Ast.SourceSpan) -> State:
  canonical_ty = canonicalize_term(full_ty, visible)
  canonical_term = canonicalize_term(term, visible)
  store_definition_result(lookup_global(canonical_key(namespace, key), globals), key, namespace, canonical_ty, canonical_term, globals, visible, span)

def check_definition_declared_type(result: Inference, key: String, declared_full: Ast.SyntaxTerm, declared_ty: Ast.SyntaxTerm, checked: Ast.SyntaxTerm, inferred_ty: Ast.SyntaxTerm, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>, span: Ast.SourceSpan) -> State:
  match result:
    case Inferred{ _,  Ast.TermType{ _, _}}:
      Bool.pick(State, fits_term(inferred_ty, declared_ty, visible), store_definition(key, namespace, declared_full, checked, globals, visible, span), StateFailure{ Diagnostic{ span_file(span), span,  String.append("definition body has the wrong type: ", key),  "the declared result type",  "an incompatible inferred type"}})
    case Inferred{ _,  _}: StateFailure{ Diagnostic{ span_file(span), span,  "definition signature is not a type",  "a type",  "a non-type"}}
    case InferenceFailure{diagnostic}: StateFailure{diagnostic}

def check_definition_inferred_type(result: Inference, key: String, full_ty: Ast.SyntaxTerm, checked: Ast.SyntaxTerm, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>, span: Ast.SourceSpan) -> State:
  match result:
    case Inferred{ _,  Ast.TermType{ _, _}}: store_definition(key, namespace, full_ty, checked, globals, visible, span)
    case Inferred{ _,  _}: StateFailure{ Diagnostic{ span_file(span), span,  "inferred definition signature is not a type",  "a type",  "a non-type"}}
    case InferenceFailure{diagnostic}: StateFailure{diagnostic}

def check_definition_finish(result: Ast.OptionalTerm, key: String, binders: List<&2, Ast.TelescopeItem>, checked: Ast.SyntaxTerm, inferred_ty: Ast.SyntaxTerm, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>, span: Ast.SourceSpan) -> State:
  match result:
    case Ast.SomeTerm{ declared_ty}:
      declared_full = binders_type(binders, declared_ty)
      check_definition_declared_type(infer(declared_full, Nil{}, visible), key, declared_full, declared_ty, checked, inferred_ty, namespace, globals, visible, span)
    case Ast.NoTerm{}:
      full_ty = binders_type(binders, inferred_ty)
      check_definition_inferred_type(infer(full_ty, Nil{}, visible), key, full_ty, checked, namespace, globals, visible, span)

def check_definition_uses_result(result: Maybe<&2, Diagnostic>, signature: Ast.OptionalTerm, key: String, binders: List<&2, Ast.TelescopeItem>, term: Ast.SyntaxTerm, checked: Ast.SyntaxTerm, inferred_ty: Ast.SyntaxTerm, unsafe: Bool, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>, span: Ast.SourceSpan) -> State:
  match result:
    case Some{diagnostic}: StateFailure{diagnostic}
    case None{}: check_definition_finish(signature, key, binders, checked, inferred_ty, namespace, globals, visible, span)

def definition_expected_body(signature: Ast.OptionalTerm, inferred_ty: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  match signature:
    case Ast.SomeTerm{declared_ty}: declared_ty
    case Ast.NoTerm{}: inferred_ty

def check_definition_term_result(result: Inference, signature: Ast.OptionalTerm, key: String, binders: List<&2, Ast.TelescopeItem>, term: Ast.SyntaxTerm, unsafe: Bool, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>, span: Ast.SourceSpan) -> State:
  match result:
    case Inferred{ checked,  inferred_ty}:
      expected_body = definition_expected_body(signature, inferred_ty)
      check_definition_uses_result(validate_definition_uses(unsafe, key, binders, term, expected_body, span, visible), signature, key, binders, term, checked, inferred_ty, unsafe, namespace, globals, visible, span)
    case InferenceFailure{diagnostic}: StateFailure{diagnostic}

def definition_visible_self(result: Ast.OptionalTerm, key: String, namespace: String, binders: List<&2, Ast.TelescopeItem>, visible: List<&2, Global>) -> List<&2, Global>:
  match result:
    case Ast.SomeTerm{declared_ty}:
      self_ty = binders_type(binders, declared_ty)
      Global{key, namespace, key, self_ty, Ast.NoTerm{}, False{}} <> (Global{canonical_key(namespace, key), namespace, key, self_ty, Ast.NoTerm{}, False{}} <> visible)
    case Ast.NoTerm{}: visible

def definition_term_inference(result: Ast.OptionalTerm, term: Ast.SyntaxTerm, binders: List<&2, Ast.TelescopeItem>, visible: List<&2, Global>) -> Inference:
  match result:
    case Ast.SomeTerm{declared_ty}: check_term(term, binders_env(binders, Nil{}), visible, declared_ty)
    case Ast.NoTerm{}: infer(term, binders_env(binders, Nil{}), visible)
def check_definition_body(body: Ast.DefBody, key: String, binders: List<&2, Ast.TelescopeItem>, result: Ast.OptionalTerm, unsafe: Bool, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>, span: Ast.SourceSpan) -> State:
  match body:
    case Ast.DefTerm{term}:
      visible_self = definition_visible_self(result, key, namespace, binders, visible)
      term_result = definition_term_inference(result, term, binders, visible_self)
      check_definition_term_result(term_result, result, key, binders, term, unsafe, namespace, globals, visible_self, span)
    case Ast.DefImports{paths}: check_import_definition(key, binders, result, paths, namespace, globals, visible, span)

def check_definition(definition: Ast.Definition, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>) -> State:
  match definition:
    case Ast.Definition{key, binders, result, body, unsafe, span}:
      check_definition_body(body, key, binders, result, unsafe, namespace, globals, visible, span)

def law_domain(condition: Maybe<&2, Ast.SyntaxTerm>, ty: Ast.SyntaxTerm, key: String, span: Ast.SourceSpan) -> Ast.SyntaxTerm:
  match condition:
    case None{}: ty
    case Some{predicate}: Ast.TermApp{Ast.TermApp{Ast.TermRef{"Exists", span}, ty, span}, Ast.TermLam{None{}, key, 0n, predicate, span}, span}

def law_quantifier(universal: Bool, quantity: Ast.Quantity, key: String, domain: Ast.SyntaxTerm, rest_ty: Ast.SyntaxTerm, span: Ast.SourceSpan) -> Ast.SyntaxTerm:
  match universal:
    case True{}: Ast.TermAll{quantity, key, 0n, domain, rest_ty, span}
    case False{}: Ast.TermApp{Ast.TermApp{Ast.TermRef{"Exists", span}, domain, span}, Ast.TermLam{None{}, key, 0n, rest_ty, span}, span}

def law_type(clauses: List<&2, Ast.Clause>, body: Ast.SyntaxTerm) -> Ast.SyntaxTerm:
  match clauses:
    case Nil{}: body
    case +clause <> rest:
      match clause:
        case Ast.ClauseFor{universal, quantity, key, ty, condition, span}:
          domain = law_domain(condition, ty, key, span)
          rest_ty = law_type(rest, body)
          law_quantifier(universal, quantity, key, domain, rest_ty, span)

def check_law_result(result: Inference, key: String, ty: Ast.SyntaxTerm, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>) -> State:
  match result:
    case Inferred{ _,  _}: State{ Global{ canonical_key(namespace, key), namespace,  key,  canonicalize_term(ty, visible),  Ast.NoTerm{},  False{}} <> globals}
    case InferenceFailure{diagnostic}: StateFailure{diagnostic}

def check_law(declaration: Ast.LawDecl, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>) -> State:
  match declaration:
    case Ast.LawDecl{key, clauses, body, span}:
      ty = law_type(clauses, body)
      check_law_result(check_term(ty, Nil{}, visible, Ast.TermType{ Ast.TermQuantity{ Ast.QOne{}, span}, span}), key, ty, namespace, globals, visible)

def has_string(key: String, values: List<&2, String>) -> Bool:
  match values:
    case Nil{}: False{}
    case +value <> rest:
      Bool.or(String.eq(key, value), has_string(key, rest))

def check_definition_once_global(global: Global, definition: Ast.Definition, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>, key: String, span: Ast.SourceSpan, replaceable_keys: List<&2, String>) -> State:
  match global:
    case Global{ _,  _,  _,  _,  Ast.NoTerm{},  _}:
      Bool.pick(State, has_string(key, replaceable_keys), check_definition(definition, namespace, globals, visible), StateFailure{ Diagnostic{ span_file(span), span,  String.append("duplicate declaration: ", key),  "a fresh declaration name",  "an existing declaration"}})
    case _: StateFailure{ Diagnostic{ span_file(span), span,  String.append("duplicate declaration: ", key),  "a fresh declaration name",  "an existing definition"}}

def check_definition_once_result(found: Maybe<&2, Global>, definition: Ast.Definition, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>, key: String, span: Ast.SourceSpan, replaceable_keys: List<&2, String>) -> State:
  match found:
    case None{}: check_definition(definition, namespace, globals, visible)
    case Some{global}: check_definition_once_global(global, definition, namespace, globals, visible, key, span, replaceable_keys)

def check_definition_once(definition: Ast.Definition, namespace: String, globals: List<&2, Global>, visible: List<&2, Global>, key: String, span: Ast.SourceSpan, replaceable_keys: List<&2, String>) -> State:
  check_definition_once_result(lookup_global(canonical_key(namespace, key), globals), definition, namespace, globals, visible, key, span, replaceable_keys)


type CheckerSccInput233 is Data:
  CheckerSccCall_check_declarations_step{result: State, rest: List<&2, Ast.TopLevel>, namespace: String, imports: List<&2, Ast.ModuleImport>, replaceable_keys: List<&2, String>}
  CheckerSccCall_check_declarations_type_result{found: Maybe<&2, Global>, declaration: Ast.TypeDecl, rest: List<&2, Ast.TopLevel>, namespace: String, imports: List<&2, Ast.ModuleImport>, globals: List<&2, Global>, visible: List<&2, Global>, replaceable_keys: List<&2, String>, key: String, span: Ast.SourceSpan}
  CheckerSccCall_check_declarations_law_result{found: Maybe<&2, Global>, declaration: Ast.LawDecl, rest: List<&2, Ast.TopLevel>, namespace: String, imports: List<&2, Ast.ModuleImport>, globals: List<&2, Global>, visible: List<&2, Global>, replaceable_keys: List<&2, String>, key: String, span: Ast.SourceSpan}
  CheckerSccCall_check_declarations{declarations: List<&2, Ast.TopLevel>, namespace: String, imports: List<&2, Ast.ModuleImport>, globals: List<&2, Global>, replaceable_keys: List<&2, String>}

def checker_scc_result_233(request: CheckerSccInput233) -> Type:
  match request:
    case CheckerSccCall_check_declarations_step{result, rest, namespace, imports, replaceable_keys}: State
    case CheckerSccCall_check_declarations_type_result{found, declaration, rest, namespace, imports, globals, visible, replaceable_keys, key, span}: State
    case CheckerSccCall_check_declarations_law_result{found, declaration, rest, namespace, imports, globals, visible, replaceable_keys, key, span}: State
    case CheckerSccCall_check_declarations{declarations, namespace, imports, globals, replaceable_keys}: State

def checker_scc_run_233(request: CheckerSccInput233) -> checker_scc_result_233(request):
  match request:
    case CheckerSccCall_check_declarations_step{result, rest, namespace, imports, replaceable_keys}:
      match result:
        case State{ next}: checker_scc_run_233(CheckerSccCall_check_declarations{rest, namespace, imports, next, replaceable_keys})
        case StateFailure{diagnostic}: StateFailure{diagnostic}

    case CheckerSccCall_check_declarations_type_result{found, declaration, rest, namespace, imports, globals, visible, replaceable_keys, key, span}:
      match found:
        case Some{_}: StateFailure{ Diagnostic{ span_file(span), span,  String.append("duplicate declaration: ", key),  "a fresh datatype name",  "an existing declaration"}}
        case None{}: checker_scc_run_233(CheckerSccCall_check_declarations_step{check_type_decl(declaration, namespace, globals, visible), rest, namespace, imports, replaceable_keys})

    case CheckerSccCall_check_declarations_law_result{found, declaration, rest, namespace, imports, globals, visible, replaceable_keys, key, span}:
      match found:
        case Some{_}: StateFailure{ Diagnostic{ span_file(span), span,  String.append("duplicate declaration: ", key),  "a fresh law name",  "an existing declaration"}}
        case None{}: checker_scc_run_233(CheckerSccCall_check_declarations_step{check_law(declaration, namespace, globals, visible), rest, namespace, imports, key <> replaceable_keys})

    case CheckerSccCall_check_declarations{declarations, namespace, imports, globals, replaceable_keys}:
      match declarations:
        case Nil{}: State{globals}
        case +declaration <> rest:
          match declaration:
            case Ast.DefTop{definition}:
              match definition:
                case Ast.Definition{key,  _,  _,  _,  _, span}:
                  visible = visible_globals(globals, namespace, imports)
                  checker_scc_run_233(CheckerSccCall_check_declarations_step{check_definition_once(definition, namespace, globals, visible, key, span, replaceable_keys), rest, namespace, imports, replaceable_keys})
            case Ast.TypeTop{declaration}:
              match declaration:
                case Ast.TypeDecl{key,  _,  _,  _, span}:
                  visible = visible_globals(globals, namespace, imports)
                  checker_scc_run_233(CheckerSccCall_check_declarations_type_result{lookup_global(canonical_key(namespace, key), globals), declaration, rest, namespace, imports, globals, visible, replaceable_keys, key, span})
            case Ast.LawTop{declaration}:
              match declaration:
                case Ast.LawDecl{key,  _,  _, span}:
                  visible = visible_globals(globals, namespace, imports)
                  checker_scc_run_233(CheckerSccCall_check_declarations_law_result{lookup_global(canonical_key(namespace, key), globals), declaration, rest, namespace, imports, globals, visible, replaceable_keys, key, span})


def check_declarations_step(result: State, rest: List<&2, Ast.TopLevel>, namespace: String, imports: List<&2, Ast.ModuleImport>, replaceable_keys: List<&2, String>) -> State:
  checker_scc_run_233(CheckerSccCall_check_declarations_step{result, rest, namespace, imports, replaceable_keys})

def check_declarations_type_result(found: Maybe<&2, Global>, declaration: Ast.TypeDecl, rest: List<&2, Ast.TopLevel>, namespace: String, imports: List<&2, Ast.ModuleImport>, globals: List<&2, Global>, visible: List<&2, Global>, replaceable_keys: List<&2, String>, key: String, span: Ast.SourceSpan) -> State:
  checker_scc_run_233(CheckerSccCall_check_declarations_type_result{found, declaration, rest, namespace, imports, globals, visible, replaceable_keys, key, span})

def check_declarations_law_result(found: Maybe<&2, Global>, declaration: Ast.LawDecl, rest: List<&2, Ast.TopLevel>, namespace: String, imports: List<&2, Ast.ModuleImport>, globals: List<&2, Global>, visible: List<&2, Global>, replaceable_keys: List<&2, String>, key: String, span: Ast.SourceSpan) -> State:
  checker_scc_run_233(CheckerSccCall_check_declarations_law_result{found, declaration, rest, namespace, imports, globals, visible, replaceable_keys, key, span})

def check_declarations(declarations: List<&2, Ast.TopLevel>, namespace: String, imports: List<&2, Ast.ModuleImport>, globals: List<&2, Global>, replaceable_keys: List<&2, String>) -> State:
  checker_scc_run_233(CheckerSccCall_check_declarations{declarations, namespace, imports, globals, replaceable_keys})

def check_modules_result(result: CheckResult, loaded: Loader.LoadedModule) -> CheckResult:
  match result:
    case CheckSuccess{ checked}: CheckSuccess{ loaded <> checked}
    case CheckFailure{diagnostic}: CheckFailure{diagnostic}

type CheckerSccInput235 is Data:
  CheckerSccCall_check_modules_declarations{result: State, loaded: Loader.LoadedModule, rest: List<&2, Loader.LoadedModule>}
  CheckerSccCall_check_modules_module{module: Ast.Module, loaded: Loader.LoadedModule, namespace: String, rest: List<&2, Loader.LoadedModule>, globals: List<&2, Global>}
  CheckerSccCall_check_modules{modules: List<&2, Loader.LoadedModule>, globals: List<&2, Global>}

def checker_scc_result_235(request: CheckerSccInput235) -> Type:
  match request:
    case CheckerSccCall_check_modules_declarations{result, loaded, rest}: CheckResult
    case CheckerSccCall_check_modules_module{module, loaded, namespace, rest, globals}: CheckResult
    case CheckerSccCall_check_modules{modules, globals}: CheckResult

def checker_scc_run_235(request: CheckerSccInput235) -> checker_scc_result_235(request):
  match request:
    case CheckerSccCall_check_modules_declarations{result, loaded, rest}:
      match result:
        case State{ next}: check_modules_result(checker_scc_run_235(CheckerSccCall_check_modules{rest, next}), loaded)
        case StateFailure{diagnostic}: CheckFailure{diagnostic}

    case CheckerSccCall_check_modules_module{module, loaded, namespace, rest, globals}:
      match module:
        case Ast.Module{ _, imports, declarations}:
          checker_scc_run_235(CheckerSccCall_check_modules_declarations{check_declarations(declarations, namespace, imports, globals, Nil{}), loaded, rest})

    case CheckerSccCall_check_modules{modules, globals}:
      match modules:
        case Nil{}: CheckSuccess{ Nil{}}
        case +loaded <> rest:
          match loaded:
            case Loader.LoadedModule{namespace, module}: checker_scc_run_235(CheckerSccCall_check_modules_module{module, loaded, namespace, rest, globals})


def check_modules_declarations(result: State, loaded: Loader.LoadedModule, rest: List<&2, Loader.LoadedModule>) -> CheckResult:
  checker_scc_run_235(CheckerSccCall_check_modules_declarations{result, loaded, rest})

def check_modules_module(module: Ast.Module, loaded: Loader.LoadedModule, namespace: String, rest: List<&2, Loader.LoadedModule>, globals: List<&2, Global>) -> CheckResult:
  checker_scc_run_235(CheckerSccCall_check_modules_module{module, loaded, namespace, rest, globals})

def check_modules(modules: List<&2, Loader.LoadedModule>, globals: List<&2, Global>) -> CheckResult:
  checker_scc_run_235(CheckerSccCall_check_modules{modules, globals})

