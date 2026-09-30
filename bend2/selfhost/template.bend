import Base
import ./ast.bend as Ast
import ./core.bend as Core
import ./loader.bend as Loader
import ./sha256.bend as SHA256
import ./path.bend as Path

type ExpandResult is Data:
  ExpandSuccess{modules: List<&2, Loader.LoadedModule>}
  ExpandFailure{message: String, span: Ast.SourceSpan}

type ApplicationSpine is Data:
  ApplicationSpine{head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan}

type TemplateDef is Data:
  TemplateDef{key: String, namespace: String, imports: List<&2, Ast.ModuleImport>, existing_keys: List<&2, String>, alias_key: String, definition: Ast.Definition}

type GeneratedIdentity is Data:
  GeneratedIdentity{key: String, template_key: String, local_key: String, identity: String}

type GeneratedBuild is Data:
  GeneratedBuild{definitions: List<&2, Ast.TopLevel>, identities: List<&2, GeneratedIdentity>, collision: Maybe<&2, Ast.SourceSpan>}

type GeneratedRound is Data:
  GeneratedRound{modules: List<&2, Loader.LoadedModule>, changed: Bool, identities: List<&2, GeneratedIdentity>, collision: Maybe<&2, Ast.SourceSpan>}

def span_of(term: Ast.SyntaxTerm) -> Ast.SourceSpan:
  match term:
    case Ast.TermVar{_, _, span}: span
    case Ast.TermRef{_, span}: span
    case Ast.TermBang{_, span}: span
    case Ast.TermSub{_, _, _, span}: span
    case Ast.TermLet{_, _, _, _, _, span}: span
    case Ast.TermAnn{_, _, span}: span
    case Ast.TermTemplate{_, span}: span
    case Ast.TermType{_, span}: span
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
    case Ast.TermQuant{}: Ast.SpanOf{ "",  0n,  0n}


def collect_templates(modules: List<&2, Loader.LoadedModule>) -> List<&2, TemplateDef>:
  match modules:
    case Nil{}: Nil{}
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{namespace,  Ast.Module{ _, imports, declarations}}:
          List.append(&2, TemplateDef, collect_template_decls(namespace, imports, top_keys(declarations), declarations), collect_templates(rest))

def top_keys(declarations: List<&2, Ast.TopLevel>) -> List<&2, String>:
  match declarations:
    case Nil{}: Nil{}
    case +declaration <> rest:
      match declaration:
        case Ast.DefTop{ Ast.Definition{key,  _,  _,  _,  _,  _}}: key <> top_keys(rest)
        case Ast.TypeTop{ Ast.TypeDecl{key,  _,  _,  _,  _}}: key <> top_keys(rest)
        case Ast.LawTop{ Ast.LawDecl{key,  _,  _,  _}}: key <> top_keys(rest)

def collect_template_decls(namespace: String, imports: List<&2, Ast.ModuleImport>, existing_keys: List<&2, String>, declarations: List<&2, Ast.TopLevel>) -> List<&2, TemplateDef>:
  match declarations:
    case Nil{}: Nil{}
    case +decl <> rest:
      match decl:
        case Ast.DefTop{ Ast.Definition{key, binders, result, body, unsafe, span}}:
          collect_template_decl(namespace, imports, existing_keys, key, binders, result, body, unsafe, span, rest, has_template_binder(binders))
        case _: collect_template_decls(namespace, imports, existing_keys, rest)

def collect_template_decl(namespace: String, imports: List<&2, Ast.ModuleImport>, existing_keys: List<&2, String>, key: String, binders: List<&2, Ast.TelescopeItem>, result: Ast.OptionalTerm, body: Ast.DefBody, unsafe: Bool, span: Ast.SourceSpan, rest: List<&2, Ast.TopLevel>, is_template: Bool) -> List<&2, TemplateDef>:
  match is_template:
    case True{}:
      canonical = qualify(namespace, key)
      d = Ast.Definition{key, binders, result, body, unsafe, span}
      TemplateDef{ canonical, namespace, imports, existing_keys,  "",  d} <> collect_template_decls(namespace, imports, existing_keys, rest)
    case False{}: collect_template_decls(namespace, imports, existing_keys, rest)

def has_template_binder(binders: List<&2, Ast.TelescopeItem>) -> Bool:
  match binders:
    case Nil{}: False{}
    case +binder <> rest:
      match binder:
        case Ast.TemplateBinder{ _,  _,  _,  _}: True{}
        case Ast.Binder{ _,  _,  _,  _,  _}: has_template_binder(rest)

def qualify(namespace: String, key: String) -> String:
  qualify_match(namespace, key, String.eq(namespace, ""))

def qualify_match(namespace: String, key: String, empty: Bool) -> String:
  match empty:
    case True{}: key
    case False{}: namespace ++ "." ++ key

def find_template(key: String, templates: List<&2, TemplateDef>) -> Maybe<&2, TemplateDef>:
  match templates:
    case Nil{}: None{}
    case +item <> rest:
      match item:
        case TemplateDef{ found,  _,  _,  _, alias_key,  _}:
          find_template_match(key, item, rest, Bool.or(String.eq(found, key), String.eq(alias_key, key)))

def find_template_match(key: String, item: TemplateDef, rest: List<&2, TemplateDef>, matches: Bool) -> Maybe<&2, TemplateDef>:
  match matches:
    case True{}: Some{item}
    case False{}: find_template(key, rest)
def flatten_application(term: Ast.SyntaxTerm) -> ApplicationSpine:
  match term:
    case Ast.TermApp{fn, arg, span}:
      flatten_append(flatten_application(fn), arg, span)

    case _:
      ApplicationSpine{ term,  Nil{},  span_of(term)}
def flatten_append(spine: ApplicationSpine, arg: Ast.SyntaxTerm, span: Ast.SourceSpan) -> ApplicationSpine:
  match spine:
    case ApplicationSpine{head, args,  _}: ApplicationSpine{head,  List.append(&2, Ast.SyntaxTerm, args, [arg]), span}

def leading_template_count(binders: List<&2, Ast.TelescopeItem>) -> Nat:
  match binders:
    case +Ast.TemplateBinder{ _,  _,  _,  _} <> rest: 1n + leading_template_count(rest)
    case _: 0n

def template_for_head(head: Ast.SyntaxTerm, templates: List<&2, TemplateDef>) -> Maybe<&2, TemplateDef>:
  match head:
    case Ast.TermRef{key,  _}: find_template(key, templates)
    case Ast.TermBang{term,  _}: template_for_head(term, templates)
    case _: None{}

def take_template_args(args: List<&2, Ast.SyntaxTerm>, count: Nat) -> Maybe<&2, List<&2, Ast.SyntaxTerm>>:
  match count:
    case 0n: Some{Nil{}}
    case _:
      match args:
        case +Ast.TermTemplate{term,  _} <> rest:
          take_template_arg(term, take_template_args(rest, count - 1n))
        case _: None{}

def take_template_arg(term: Ast.SyntaxTerm, result: Maybe<&2, List<&2, Ast.SyntaxTerm>>) -> Maybe<&2, List<&2, Ast.SyntaxTerm>>:
  match result:
    case Some{value}: Some{term <> value}
    case None{}: None{}

def reapply_args(head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan) -> Ast.SyntaxTerm:
  match args:
    case Nil{}: head
    case +arg <> rest:
      reapply_args(Ast.TermApp{ head, arg, span}, rest, span)


def generated_local_key(template: TemplateDef, values: List<&2, Ast.SyntaxTerm>) -> String:
  match template:
    case TemplateDef{key,  _,  _, existing_keys,  _,  _}:
      identity = encode_string(key) ++ serialize_terms(values)
      base = "T~" ++ SHA256.hash(identity)
      fresh_generated_key(base, existing_keys, 0n)

def fresh_generated_key(base: String, existing: List<&2, String>, attempt: Nat) -> String:
  candidate = match attempt:
    case 0n: base
    case _: base ++ "~" ++ Nat.show(attempt)
  fresh_generated_key_match(base, existing, attempt, candidate, has_string(candidate, existing))

def fresh_generated_key_match(base: String, existing: List<&2, String>, attempt: Nat, candidate: String, found: Bool) -> String:
  match found:
    case True{}: fresh_generated_key(base, existing, attempt + 1n)
    case False{}: candidate

def generated_key(template: TemplateDef, values: List<&2, Ast.SyntaxTerm>) -> String:
  match template:
    case TemplateDef{ _, namespace,  _,  _,  _,  _}:
      qualify(namespace, generated_local_key(template, values))

def encode_string(value: String) -> String:
  Nat.show(String.length(value)) ++ ":" ++ value

def encode_quantity(quantity: Ast.Quantity) -> String:
  match quantity:
    case Ast.QZero{}: "0"
    case Ast.QOne{}: "1"
    case Ast.QMany{}: "m"

def serialize_strings(values: List<&2, String>) -> String:
  match values:
    case Nil{}: "]"
    case +value <> rest: encode_string(value) ++ ";" ++ serialize_strings(rest)

def serialize_nats(values: List<&2, Nat>) -> String:
  match values:
    case Nil{}: "]"
    case +value <> rest: Nat.show(value) ++ ";" ++ serialize_nats(rest)

def serialize_quantities(values: List<&2, Ast.Quantity>) -> String:
  match values:
    case Nil{}: "]"
    case +value <> rest: encode_quantity(value) ++ ";" ++ serialize_quantities(rest)

def serialize_patterns(values: List<&2, Ast.SyntaxPattern>) -> String:
  match values:
    case Nil{}: "]"
    case +value <> rest: serialize_pattern(value) ++ ";" ++ serialize_patterns(rest)

def serialize_pattern(pattern: Ast.SyntaxPattern) -> String:
  match pattern:
    case Ast.PatternVar{ _, index, quantity,  _}: "v" ++ Nat.show(index) ++ encode_quantity(quantity) ++ ";"
    case Ast.PatternCtr{key, fields,  _}: "c" ++ encode_string(key) ++ serialize_patterns(fields)

def serialize_terms(values: List<&2, Ast.SyntaxTerm>) -> String:
  match values:
    case Nil{}: "]"
    case +value <> rest: serialize_term(value) ++ ";" ++ serialize_terms(rest)

def serialize_term(term: Ast.SyntaxTerm) -> String:
  match term:
    case Ast.TermVar{_, index, _}: "v" ++ Nat.show(index) ++ ";"
    case Ast.TermRef{key,  _}: "r" ++ encode_string(key)
    case Ast.TermBang{ value,  _}: "!" ++ serialize_term(value)
    case Ast.TermSub{index, value, body,  _}: "s" ++ Nat.show(index) ++ ";" ++ serialize_term(value) ++ serialize_term(body)
    case Ast.TermLet{keys, indexes, quantities, values, body,  _}: "l" ++ serialize_strings(keys) ++ serialize_nats(indexes) ++ serialize_quantities(quantities) ++ serialize_terms(values) ++ serialize_term(body)
    case Ast.TermAnn{ value, ty,  _}: "a" ++ serialize_term(value) ++ serialize_term(ty)
    case Ast.TermTemplate{ value,  _}: "t" ++ serialize_term(value)
    case Ast.TermType{kind,  _}: "T" ++ serialize_term(kind)
    case Ast.TermQuant{}: "q;"
    case Ast.TermQuantity{quantity,  _}: "Q" ++ encode_quantity(quantity) ++ ";"
    case Ast.TermMin{left, right,  _}: "m" ++ serialize_term(left) ++ serialize_term(right)
    case Ast.TermAll{quantity, _, _, ty, body, _}: "A" ++ encode_quantity(quantity) ++ serialize_term(ty) ++ serialize_term(body)
    case Ast.TermLam{quantity, _, _, body, _}: "L" ++ serialize_optional_quantity(quantity) ++ serialize_term(body)
    case Ast.TermApp{fn, arg,  _}: "p" ++ serialize_term(fn) ++ serialize_term(arg)
    case Ast.TermAdt{key, args, refs,  _}: "d" ++ encode_string(key) ++ serialize_terms(args) ++ serialize_strings(refs)
    case Ast.TermFill{head, args,  _}: "f" ++ serialize_term(head) ++ serialize_terms(args)
    case Ast.TermPlus{head, args,  _}: "+" ++ serialize_term(head) ++ serialize_terms(args)
    case Ast.TermCtr{key, args,  _}: "c" ++ encode_string(key) ++ serialize_terms(args)
    case Ast.TermMat{key, head, matched,  _}: "M" ++ encode_string(key) ++ serialize_term(head) ++ serialize_term(matched)
    case Ast.TermAbsurd{ _}: "!"
    case Ast.TermEqual{left, right, ty,  _}: "=" ++ serialize_term(left) ++ serialize_term(right) ++ serialize_term(ty)
    case Ast.TermRefl{ _}: "R"
    case Ast.TermRewrite{equation, proof, body,  _}: "w" ++ serialize_term(equation) ++ serialize_term(proof) ++ serialize_term(body)
    case Ast.TermHole{key,  _}: "h" ++ encode_string(key)
    case Ast.BodyMatch{scrutinees, cases,  _}: "B" ++ serialize_terms(scrutinees) ++ serialize_terms(cases)
    case Ast.BodyCase{patterns, body,  _}: "C" ++ serialize_patterns(patterns) ++ serialize_term(body)
    case Ast.BodyLocal{patterns, quantity, values, body,  _}: "D" ++ serialize_patterns(patterns) ++ encode_quantity(quantity) ++ serialize_terms(values) ++ serialize_term(body)
    case Ast.BodyReply{ value,  _}: "Y" ++ serialize_term(value)

def serialize_optional_quantity(value: Maybe<&2, Ast.Quantity>) -> String:
  match value:
    case None{}: "n"
    case Some{value}: "s" ++ encode_quantity(value)

def strip_namespace(key: String, namespace: String) -> String:
  strip_namespace_match(key, namespace, String.eq(namespace, ""))

def strip_namespace_match(key: String, namespace: String, empty: Bool) -> String:
  match empty:
    case True{}: key
    case False{}: strip_namespace_prefix(key, namespace ++ ".")

def strip_namespace_prefix(key: String, prefix: String) -> String:
  strip_namespace_prefix_match(key, prefix, String.starts_with(key, prefix))

def strip_namespace_prefix_match(key: String, prefix: String, starts: Bool) -> String:
  match starts:
    case True{}: String.drop(key, String.length(prefix))
    case False{}: key

def expand_term(term: Ast.SyntaxTerm, templates: List<&2, TemplateDef>) -> Ast.SyntaxTerm:
  match term:
    case Ast.TermVar{key, index, span}: Ast.TermVar{key, index, span}
    case Ast.TermRef{key, span}: Ast.TermRef{key, span}
    case Ast.TermBang{ inner, span}: Ast.TermBang{ expand_term(inner, templates), span}
    case Ast.TermSub{index, value, body, span}: Ast.TermSub{index,  expand_term(value, templates),  expand_term(body, templates), span}
    case Ast.TermLet{keys, indexes, quantities, values, body, span}: Ast.TermLet{keys, indexes, quantities,  expand_terms(values, templates),  expand_term(body, templates), span}
    case Ast.TermAnn{ inner, ty, span}: Ast.TermAnn{ expand_term(inner, templates),  expand_term(ty, templates), span}
    case Ast.TermTemplate{ inner, span}: Ast.TermTemplate{ expand_term(inner, templates), span}
    case Ast.TermType{kind, span}: Ast.TermType{ expand_term(kind, templates), span}
    case Ast.TermQuant{}: term
    case Ast.TermQuantity{quantity, span}: Ast.TermQuantity{quantity, span}
    case Ast.TermMin{left, right, span}: Ast.TermMin{ expand_term(left, templates),  expand_term(right, templates), span}
    case Ast.TermAll{quantity, key, index, ty, body, span}: Ast.TermAll{quantity, key, index,  expand_term(ty, templates),  expand_term(body, templates), span}
    case Ast.TermLam{quantity, key, index, body, span}: Ast.TermLam{quantity, key, index,  expand_term(body, templates), span}
    case Ast.TermApp{fn, arg, span}: expand_application(fn, arg, span, templates)
    case Ast.TermAdt{key, args, refs, span}: Ast.TermAdt{key,  expand_terms(args, templates), refs, span}
    case Ast.TermFill{head, args, span}: Ast.TermFill{ expand_term(head, templates),  expand_terms(args, templates), span}
    case Ast.TermPlus{head, args, span}: Ast.TermPlus{ expand_term(head, templates),  expand_terms(args, templates), span}
    case Ast.TermCtr{key, args, span}: Ast.TermCtr{key,  expand_terms(args, templates), span}
    case Ast.TermMat{key, head, matched, span}: Ast.TermMat{key,  expand_term(head, templates),  expand_term(matched, templates), span}
    case Ast.TermAbsurd{span}: term
    case Ast.TermEqual{left, right, ty, span}: Ast.TermEqual{ expand_term(left, templates),  expand_term(right, templates),  expand_term(ty, templates), span}
    case Ast.TermRefl{span}: term
    case Ast.TermRewrite{equation, proof, body, span}: Ast.TermRewrite{ expand_term(equation, templates),  expand_term(proof, templates),  expand_term(body, templates), span}
    case Ast.TermHole{key, span}: term
    case Ast.BodyMatch{scrutinees, cases, span}: Ast.BodyMatch{ expand_terms(scrutinees, templates),  expand_terms(cases, templates), span}
    case Ast.BodyCase{patterns, body, span}: Ast.BodyCase{patterns,  expand_term(body, templates), span}
    case Ast.BodyLocal{patterns, quantity, values, body, span}: Ast.BodyLocal{patterns, quantity,  expand_terms(values, templates),  expand_term(body, templates), span}
    case Ast.BodyReply{ inner, span}: Ast.BodyReply{ expand_term(inner, templates), span}

def expand_application(fn: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, span: Ast.SourceSpan, templates: List<&2, TemplateDef>) -> Ast.SyntaxTerm:
  application = Ast.TermApp{fn, arg, span}
  expand_application_spine(fn, arg, span, templates, flatten_application(application))

def expand_application_spine(fn: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, span: Ast.SourceSpan, templates: List<&2, TemplateDef>, spine: ApplicationSpine) -> Ast.SyntaxTerm:
  match spine:
    case ApplicationSpine{head, args, _}:
      expand_application_template(fn, arg, span, templates, head, args, template_for_head(head, templates))

def expand_application_template(fn: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, span: Ast.SourceSpan, templates: List<&2, TemplateDef>, head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, found: Maybe<&2, TemplateDef>) -> Ast.SyntaxTerm:
  match found:
    case None{}: Ast.TermApp{ expand_term(fn, templates), expand_term(arg, templates), span}
    case Some{ template}:
      arity = match template:
        case TemplateDef{_, _, _, _, _, Ast.Definition{_, binders, _, _, _, _}}: leading_template_count(binders)
      expand_application_arguments(fn, arg, span, templates, head, args, template, arity, take_template_args(args, arity))

def expand_application_arguments(fn: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, span: Ast.SourceSpan, templates: List<&2, TemplateDef>, head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, template: TemplateDef, arity: Nat, values: Maybe<&2, List<&2, Ast.SyntaxTerm>>) -> Ast.SyntaxTerm:
  match values:
    case None{}: Ast.TermApp{ expand_term(fn, templates), expand_term(arg, templates), span}
    case Some{ actuals}:
      runtime_args = drop_args(args, arity)
      expanded_values = expand_terms(actuals, templates)
      specialized = specialize_head(head, generated_key(template, expanded_values))
      reapply_args(specialized, expand_terms(runtime_args, templates), span)

def specialize_head(head: Ast.SyntaxTerm, key: String) -> Ast.SyntaxTerm:
  match head:
    case Ast.TermRef{_, span}: Ast.TermRef{key, span}
    case Ast.TermBang{ _, span}: Ast.TermBang{ Ast.TermRef{key, span}, span}
    case _: head

def drop_args(args: List<&2, Ast.SyntaxTerm>, count: Nat) -> List<&2, Ast.SyntaxTerm>:
  match count:
    case 0n: args
    case _:
      match args:
        case +_ <> rest: drop_args(rest, count - 1n)
        case Nil{}: Nil{}


def specialize_definition(template: TemplateDef, values: List<&2, Ast.SyntaxTerm>) -> Ast.Definition:
  match template:
    case TemplateDef{ _,  _,  _,  _,  _,  Ast.Definition{key, binders, result, body, unsafe, span}}:
      (specialized_binders, specialized_result, specialized_body) = specialize_prefix(binders, values, result, body)
      Ast.Definition{ generated_local_key(template, values),  specialized_binders,  specialized_result,  specialized_body, unsafe, span}

def specialize_prefix(binders: List<&2, Ast.TelescopeItem>, values: List<&2, Ast.SyntaxTerm>, result: Ast.OptionalTerm, body: Ast.DefBody) -> (List<&2, Ast.TelescopeItem> & Ast.OptionalTerm) & Ast.DefBody:
  match binders values:
    case +Ast.TemplateBinder{ _,  _,  _,  _} <> rest_binders +value <> rest_values:
      substitution_index = binder_count(rest_binders)
      next_binders = substitute_binders(rest_binders, 0n, value)
      next_result = substitute_optional(result, substitution_index, value)
      next_body = substitute_body(body, substitution_index, value)
      specialize_prefix(next_binders, rest_values, next_result, next_body)
    case _, _:
      (binders, result, body)

def binder_count(binders: List<&2, Ast.TelescopeItem>) -> Nat:
  match binders:
    case Nil{}: 0n
    case +_ <> rest: 1n + binder_count(rest)

def substitute_binders(binders: List<&2, Ast.TelescopeItem>, index: Nat, replacement: Ast.SyntaxTerm) -> List<&2, Ast.TelescopeItem>:
  match binders:
    case Nil{}: Nil{}
    case +binder <> rest:
      match binder:
        case Ast.Binder{quantity, key,  binder_index, ty, span}:
          Ast.Binder{quantity, key,  binder_index,  Core.subst(index, replacement, ty), span} <> substitute_binders(rest, index + 1n, replacement)
        case Ast.TemplateBinder{key,  binder_index, ty, span}:
          Ast.TemplateBinder{key,  binder_index,  Core.subst(index, replacement, ty), span} <> substitute_binders(rest, index + 1n, replacement)

def substitute_optional(value: Ast.OptionalTerm, index: Nat, replacement: Ast.SyntaxTerm) -> Ast.OptionalTerm:
  match value:
    case Ast.NoTerm{}: value
    case Ast.SomeTerm{term}: Ast.SomeTerm{Core.subst(index, replacement, term)}

def substitute_body(value: Ast.DefBody, index: Nat, replacement: Ast.SyntaxTerm) -> Ast.DefBody:
  match value:
    case Ast.DefTerm{term}: Ast.DefTerm{Core.subst(index, replacement, term)}
    case Ast.DefImports{paths}: value
def expand_terms(terms: List<&2, Ast.SyntaxTerm>, templates: List<&2, TemplateDef>) -> List<&2, Ast.SyntaxTerm>:
  match terms:
    case Nil{}: Nil{}
    case +term <> rest: expand_term(term, templates) <> expand_terms(rest, templates)

def strip_template_decls(namespace: String, declarations: List<&2, Ast.TopLevel>, templates: List<&2, TemplateDef>, identities: List<&2, GeneratedIdentity>) -> List<&2, Ast.TopLevel>:
  match declarations:
    case Nil{}: Nil{}
    case +decl <> rest:
      match decl:
        case Ast.DefTop{ Ast.Definition{key, binders, result, body, unsafe, span}}:
          strip_template_definition(namespace, key, binders, result, body, unsafe, span, rest, templates, identities, has_template_binder(binders))
        case Ast.TypeTop{ Ast.TypeDecl{key, params, kind, constructors, span}}:
          Ast.TypeTop{ Ast.TypeDecl{key,  expand_binders(params, templates),  expand_term(kind, templates),  expand_constructors(constructors, templates), span}} <> strip_template_decls(namespace, rest, templates, identities)
        case Ast.LawTop{ Ast.LawDecl{key, clauses, body, span}}:
          Ast.LawTop{ Ast.LawDecl{key,  expand_clauses(clauses, templates),  expand_term(body, templates), span}} <> strip_template_decls(namespace, rest, templates, identities)

def strip_template_definition(namespace: String, key: String, binders: List<&2, Ast.TelescopeItem>, result: Ast.OptionalTerm, body: Ast.DefBody, unsafe: Bool, span: Ast.SourceSpan, rest: List<&2, Ast.TopLevel>, templates: List<&2, TemplateDef>, identities: List<&2, GeneratedIdentity>, is_template: Bool) -> List<&2, Ast.TopLevel>:
  match is_template:
    case True{}:
      strip_canonical_template(namespace, rest, templates, identities, canonical_template_key(key, templates))
    case False{}:
      strip_instance_or_definition(namespace, key, Ast.Definition{key, binders, result, body, unsafe, span}, rest, templates, identities, is_template_instance(namespace, key, identities))

def strip_canonical_template(namespace: String, rest: List<&2, Ast.TopLevel>, templates: List<&2, TemplateDef>, identities: List<&2, GeneratedIdentity>, canonical: Maybe<&2, String>) -> List<&2, Ast.TopLevel>:
  match canonical:
    case Some{ value}: List.append(&2, Ast.TopLevel, template_instances(rest, value, templates, identities), strip_template_decls(namespace, rest, templates, identities))
    case None{}: strip_template_decls(namespace, rest, templates, identities)

def strip_instance_or_definition(namespace: String, key: String, definition: Ast.Definition, rest: List<&2, Ast.TopLevel>, templates: List<&2, TemplateDef>, identities: List<&2, GeneratedIdentity>, is_instance: Bool) -> List<&2, Ast.TopLevel>:
  match is_instance:
    case True{}: strip_template_decls(namespace, rest, templates, identities)
    case False{}: Ast.DefTop{ expand_definition(definition, templates)} <> strip_template_decls(namespace, rest, templates, identities)

def canonical_template_key(local_key: String, templates: List<&2, TemplateDef>) -> Maybe<&2, String>:
  match templates:
    case Nil{}: None{}
    case +template <> rest:
      match template:
        case TemplateDef{key, namespace,  _,  _,  _,  _}:
          canonical_template_match(local_key, key, rest, String.eq(local_key, strip_namespace(key, namespace)))

def canonical_template_match(local_key: String, key: String, rest: List<&2, TemplateDef>, matches: Bool) -> Maybe<&2, String>:
  match matches:
    case True{}: Some{key}
    case False{}: canonical_template_key(local_key, rest)

def generated_local_keys(template_key: String, identities: List<&2, GeneratedIdentity>) -> List<&2, String>:
  match identities:
    case Nil{}: Nil{}
    case +entry <> rest:
      match entry:
        case GeneratedIdentity{_, owner, local_key, _}:
          generated_local_key_match(template_key, local_key, rest, String.eq(template_key, owner))

def generated_local_key_match(template_key: String, local_key: String, rest: List<&2, GeneratedIdentity>, matches: Bool) -> List<&2, String>:
  match matches:
    case True{}: local_key <> generated_local_keys(template_key, rest)
    case False{}: generated_local_keys(template_key, rest)

def has_generated_local_key(key: String, local_keys: List<&2, String>) -> Bool:
  has_string(key, local_keys)

def is_template_instance(namespace: String, local_key: String, identities: List<&2, GeneratedIdentity>) -> Bool:
  canonical_key = qualify(namespace, local_key)
  generated_identity_found(find_generated_identity(canonical_key, identities))

def generated_identity_found(identity: Maybe<&2, GeneratedIdentity>) -> Bool:
  match identity:
    case Some{ _}: True{}
    case None{}: False{}

def template_instances(declarations: List<&2, Ast.TopLevel>, template_key: String, templates: List<&2, TemplateDef>, identities: List<&2, GeneratedIdentity>) -> List<&2, Ast.TopLevel>:
  local_keys = generated_local_keys(template_key, identities)
  template_instances_for_keys(declarations, local_keys, templates)

def template_instances_for_keys(declarations: List<&2, Ast.TopLevel>, local_keys: List<&2, String>, templates: List<&2, TemplateDef>) -> List<&2, Ast.TopLevel>:
  match declarations:
    case Nil{}: Nil{}
    case +decl <> rest:
      match decl:
        case Ast.DefTop{ Ast.Definition{key, binders, result, body, unsafe, span}}:
          template_instance_definition(key, binders, result, body, unsafe, span, rest, templates, local_keys, has_generated_local_key(key, local_keys))
        case _: template_instances_for_keys(rest, local_keys, templates)

def template_instance_definition(key: String, binders: List<&2, Ast.TelescopeItem>, result: Ast.OptionalTerm, body: Ast.DefBody, unsafe: Bool, span: Ast.SourceSpan, rest: List<&2, Ast.TopLevel>, templates: List<&2, TemplateDef>, local_keys: List<&2, String>, is_instance: Bool) -> List<&2, Ast.TopLevel>:
  match is_instance:
    case True{}: Ast.DefTop{ expand_definition(Ast.Definition{key, binders, result, body, unsafe, span}, templates)} <> template_instances_for_keys(rest, local_keys, templates)
    case False{}: template_instances_for_keys(rest, local_keys, templates)

def expand_constructors(constructors: List<&2, Ast.ConstructorDecl>, templates: List<&2, TemplateDef>) -> List<&2, Ast.ConstructorDecl>:
  match constructors:
    case Nil{}: Nil{}
    case +constructor <> rest:
      match constructor:
        case Ast.Constructor{key, fields, span}:
          Ast.Constructor{key,  expand_binders(fields, templates), span} <> expand_constructors(rest, templates)

def expand_clauses(clauses: List<&2, Ast.Clause>, templates: List<&2, TemplateDef>) -> List<&2, Ast.Clause>:
  match clauses:
    case Nil{}: Nil{}
    case +clause <> rest:
      match clause:
        case Ast.ClauseFor{universal, quantity, key, ty, condition, span}:
          Ast.ClauseFor{universal, quantity, key, ty,  expand_term(ty, templates),  expand_maybe(condition, templates), span} <> expand_clauses(rest, templates)

def expand_maybe(value: Maybe<&2, Ast.SyntaxTerm>, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SyntaxTerm>:
  match value:
    case None{}: None{}
    case Some{value}: Some{expand_term(value, templates)}
def expand_definition(d: Ast.Definition, templates: List<&2, TemplateDef>) -> Ast.Definition:
  match d:
    case Ast.Definition{key, binders, result, body, unsafe, span}:
      Ast.Definition{key,  expand_binders(binders, templates),  expand_optional(result, templates),  expand_body(body, templates), unsafe, span}

def expand_body(body: Ast.DefBody, templates: List<&2, TemplateDef>) -> Ast.DefBody:
  match body:
    case Ast.DefTerm{term}: Ast.DefTerm{ expand_term(term, templates)}
    case Ast.DefImports{paths}: body

def expand_optional(result: Ast.OptionalTerm, templates: List<&2, TemplateDef>) -> Ast.OptionalTerm:
  match result:
    case Ast.NoTerm{}: result
    case Ast.SomeTerm{term}: Ast.SomeTerm{ expand_term(term, templates)}

def expand_binders(binders: List<&2, Ast.TelescopeItem>, templates: List<&2, TemplateDef>) -> List<&2, Ast.TelescopeItem>:
  match binders:
    case Nil{}: Nil{}
    case +item <> rest:
      match item:
        case Ast.Binder{quantity, key, index, ty, span}: Ast.Binder{quantity, key, index,  expand_term(ty, templates), span} <> expand_binders(rest, templates)
        case Ast.TemplateBinder{key, index, ty, span}: Ast.TemplateBinder{key, index,  expand_term(ty, templates), span} <> expand_binders(rest, templates)

def find_actual(term: Ast.SyntaxTerm, template_key: String) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  match term:
    case Ast.TermApp{ _,  _,  _}:
      find_actual_spine(term, template_key, flatten_application(term))
    case Ast.TermBang{term,  _}: find_actual(term, template_key)
    case Ast.TermSub{value, body,  _}: first_actual(find_actual(value, template_key), find_actual(body, template_key))
    case Ast.TermLet{values, body,  _}: first_actual(find_actual_terms(values, template_key), find_actual(body, template_key))
    case Ast.TermAnn{ inner,  ty,  _}: first_actual(find_actual(inner, template_key), find_actual(ty, template_key))
    case Ast.TermTemplate{ inner,  _}: find_actual(inner, template_key)
    case Ast.TermType{kind,  _}: find_actual(kind, template_key)
    case Ast.TermMin{left, right,  _}: first_actual(find_actual(left, template_key), find_actual(right, template_key))
    case Ast.TermAll{ty, body,  _}: first_actual(find_actual(ty, template_key), find_actual(body, template_key))
    case Ast.TermLam{body,  _}: find_actual(body, template_key)
    case Ast.TermAdt{args,  _}: find_actual_terms(args, template_key)
    case Ast.TermFill{head, args,  _}: first_actual(find_actual(head, template_key), find_actual_terms(args, template_key))
    case Ast.TermPlus{head, args,  _}: first_actual(find_actual(head, template_key), find_actual_terms(args, template_key))
    case Ast.TermCtr{args,  _}: find_actual_terms(args, template_key)
    case Ast.TermMat{head, matched,  _}: first_actual(find_actual(head, template_key), find_actual(matched, template_key))
    case Ast.TermEqual{left, right, ty,  _}: first_actual(find_actual(left, template_key), first_actual(find_actual(right, template_key), find_actual(ty, template_key)))
    case Ast.TermRewrite{equation, proof, body,  _}: first_actual(find_actual(equation, template_key), first_actual(find_actual(proof, template_key), find_actual(body, template_key)))
    case Ast.BodyMatch{scrutinees, cases,  _}: first_actual(find_actual_terms(scrutinees, template_key), find_actual_terms(cases, template_key))
    case Ast.BodyCase{body,  _}: find_actual(body, template_key)
    case Ast.BodyLocal{values, body,  _}: first_actual(find_actual_terms(values, template_key), find_actual(body, template_key))
    case Ast.BodyReply{ inner,  _}: find_actual(inner, template_key)
    case _: Nil{}

def find_actual_spine(term: Ast.SyntaxTerm, template_key: String, spine: ApplicationSpine) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  match spine:
    case ApplicationSpine{head, args, _}: find_actual_head(term, template_key, args, head_key(head))

def find_actual_head(term: Ast.SyntaxTerm, template_key: String, args: List<&2, Ast.SyntaxTerm>, key: Maybe<&2, String>) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  match key:
    case Some{found}: find_actual_key(term, template_key, args, found, String.eq(template_key, found))
    case None{}: find_actual_application_parts(term, template_key)

def find_actual_key(term: Ast.SyntaxTerm, template_key: String, args: List<&2, Ast.SyntaxTerm>, found: String, matches: Bool) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  match matches:
    case True{}: find_actual_prefix(term, template_key, args, wrapped_prefix(args))
    case False{}: find_actual_application_parts(term, template_key)

def find_actual_prefix(term: Ast.SyntaxTerm, template_key: String, args: List<&2, Ast.SyntaxTerm>, prefix: Maybe<&2, List<&2, Ast.SyntaxTerm>>) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  match prefix:
    case Some{Nil{}}: find_actual_application_parts(term, template_key)
    case Some{values}:
      runtime_args = drop_args(args, List.length(&2, Ast.SyntaxTerm, values))
      List.append(&2, List<&2, Ast.SyntaxTerm>, [values], first_actual(find_actual_terms(values, template_key), find_actual_terms(runtime_args, template_key)))
    case None{}: Nil{}

def find_actual_application_parts(term: Ast.SyntaxTerm, template_key: String) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  match term:
    case Ast.TermApp{fn, arg, _}: first_actual(find_actual(fn, template_key), find_actual(arg, template_key))
    case _: Nil{}

def head_key(head: Ast.SyntaxTerm) -> Maybe<&2, String>:
  match head:
    case Ast.TermRef{key,  _}: Some{key}
    case Ast.TermBang{term,  _}: head_key(term)
    case _: None{}

def wrapped_prefix(args: List<&2, Ast.SyntaxTerm>) -> Maybe<&2, List<&2, Ast.SyntaxTerm>>:
  match args:
    case +Ast.TermTemplate{term,  _} <> rest:
      wrapped_prefix_cons(term, wrapped_prefix(rest))
    case _: Some{Nil{}}

def wrapped_prefix_cons(term: Ast.SyntaxTerm, result: Maybe<&2, List<&2, Ast.SyntaxTerm>>) -> Maybe<&2, List<&2, Ast.SyntaxTerm>>:
  match result:
    case Some{value}: Some{term <> value}
    case None{}: None{}

def find_actual_terms(terms: List<&2, Ast.SyntaxTerm>, template_key: String) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  match terms:
    case Nil{}: Nil{}
    case +term <> rest: first_actual(find_actual(term, template_key), find_actual_terms(rest, template_key))

def first_actual(left: List<&2, List<&2, Ast.SyntaxTerm>>, right: List<&2, List<&2, Ast.SyntaxTerm>>) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  List.append(&2, List<&2, Ast.SyntaxTerm>, left, right)

def actual_in_declarations(declarations: List<&2, Ast.TopLevel>, template_key: String) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  match declarations:
    case Nil{}: Nil{}
    case +decl <> rest:
      match decl:
        case Ast.DefTop{ Ast.Definition{_, binders, result, body, _, _}}:
          actual_definition(binders, result, body, rest, template_key, has_template_binder(binders))
        case Ast.TypeTop{ Ast.TypeDecl{_, params, kind, constructors, _}}:
          first_actual(first_actual(find_actual_binders(params, template_key), find_actual(kind, template_key)), first_actual(find_actual_constructors(constructors, template_key), actual_in_declarations(rest, template_key)))
        case Ast.LawTop{ Ast.LawDecl{_, clauses, body, _}}:
          first_actual(first_actual(find_actual_clauses(clauses, template_key), find_actual(body, template_key)), actual_in_declarations(rest, template_key))

def actual_definition(binders: List<&2, Ast.TelescopeItem>, result: Ast.OptionalTerm, body: Ast.DefBody, rest: List<&2, Ast.TopLevel>, template_key: String, is_template: Bool) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  match is_template:
    case True{}: actual_in_declarations(rest, template_key)
    case False{}:
      body_actual = match body:
        case Ast.DefTerm{term}: find_actual(term, template_key)
        case Ast.DefImports{ _}: Nil{}
      first_actual(first_actual(find_actual_binders(binders, template_key), find_actual_optional(result, template_key)), first_actual(body_actual, actual_in_declarations(rest, template_key)))

def actual_in_modules(modules: List<&2, Loader.LoadedModule>, template_key: String, templates: List<&2, TemplateDef>) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  match modules:
    case Nil{}: Nil{}
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{namespace, Ast.Module{_, imports, declarations}}:
          context = visible_templates(namespace, imports, templates)
          aliases = template_aliases(namespace, imports, template_key, templates)
          actuals = actual_in_aliases(declarations, aliases)
          first_actual(expand_actual_values(actuals, context), actual_in_modules(rest, template_key, templates))

def template_aliases(namespace: String, imports: List<&2, Ast.ModuleImport>, template_key: String, templates: List<&2, TemplateDef>) -> List<&2, String>:
  template_aliases_found(namespace, imports, template_key, find_template(template_key, templates))

def template_aliases_found(namespace: String, imports: List<&2, Ast.ModuleImport>, template_key: String, found: Maybe<&2, TemplateDef>) -> List<&2, String>:
  match found:
    case None{}: [template_key]
    case Some{ TemplateDef{ _,  owner,  _,  _,  _,  _}}:
      local = strip_namespace(template_key, owner)
      local_names = template_local_alias(namespace, owner, local, String.eq(namespace, owner))
      List.append(&2, String, [template_key], List.append(&2, String, local_names, imported_alias_names(namespace, imports, owner, local)))

def template_local_alias(namespace: String, owner: String, local: String, is_local: Bool) -> List<&2, String>:
  match is_local:
    case True{}: [local]
    case False{}: Nil{}

def imported_alias_names(namespace: String, imports: List<&2, Ast.ModuleImport>, owner: String, local: String) -> List<&2, String>:
  match imports:
    case Nil{}: Nil{}
    case +item <> rest:
      match item:
        case Ast.ModuleImport{path, alias,  _}:
          imported_alias_match(namespace, rest, owner, local, alias, String.eq(Path.namespace(namespace, path), owner))

def imported_alias_match(namespace: String, rest: List<&2, Ast.ModuleImport>, owner: String, local: String, alias: String, matches: Bool) -> List<&2, String>:
  match matches:
    case True{}: (alias ++ "." ++ local) <> imported_alias_names(namespace, rest, owner, local)
    case False{}: imported_alias_names(namespace, rest, owner, local)

def actual_in_aliases(declarations: List<&2, Ast.TopLevel>, aliases: List<&2, String>) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  match aliases:
    case Nil{}: Nil{}
    case +alias <> rest: first_actual(actual_in_declarations(declarations, alias), actual_in_aliases(declarations, rest))
def expand_actual_values(actuals: List<&2, List<&2, Ast.SyntaxTerm>>, templates: List<&2, TemplateDef>) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  match actuals:
    case Nil{}: Nil{}
    case +values <> rest: expand_terms(values, templates) <> expand_actual_values(rest, templates)

def find_actual_binders(binders: List<&2, Ast.TelescopeItem>, template_key: String) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  match binders:
    case Nil{}: Nil{}
    case +binder <> rest:
      match binder:
        case Ast.Binder{_, _, _, ty, _}: first_actual(find_actual(ty, template_key), find_actual_binders(rest, template_key))
        case Ast.TemplateBinder{_, _, ty, _}: first_actual(find_actual(ty, template_key), find_actual_binders(rest, template_key))

def find_actual_optional(value: Ast.OptionalTerm, template_key: String) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  match value:
    case Ast.NoTerm{}: Nil{}
    case Ast.SomeTerm{term}: find_actual(term, template_key)

def find_actual_constructors(constructors: List<&2, Ast.ConstructorDecl>, template_key: String) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  match constructors:
    case Nil{}: Nil{}
    case +constructor <> rest:
      match constructor:
        case Ast.Constructor{_, fields, _}: first_actual(find_actual_binders(fields, template_key), find_actual_constructors(rest, template_key))

def find_actual_clauses(clauses: List<&2, Ast.Clause>, template_key: String) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  match clauses:
    case Nil{}: Nil{}
    case +clause <> rest:
      match clause:
        case Ast.ClauseFor{_, _, _, ty, condition, _}: first_actual(find_actual(ty, template_key), first_actual(find_actual_maybe(condition, template_key), find_actual_clauses(rest, template_key)))

def find_actual_maybe(value: Maybe<&2, Ast.SyntaxTerm>, template_key: String) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  match value:
    case None{}: Nil{}
    case Some{value}: find_actual(value, template_key)
def has_string(value: String, values: List<&2, String>) -> Bool:
  match values:
    case Nil{}: False{}
    case +found <> rest:
      has_string_match(value, found, rest, String.eq(value, found))

def has_string_match(value: String, found: String, rest: List<&2, String>, matches: Bool) -> Bool:
  match matches:
    case True{}: True{}
    case False{}: has_string(value, rest)

def has_top_key(key: String, declarations: List<&2, Ast.TopLevel>) -> Bool:
  match declarations:
    case Nil{}: False{}
    case +declaration <> rest:
      match declaration:
        case Ast.DefTop{ Ast.Definition{ found,  _,  _,  _,  _,  _}}:
          Bool.or(String.eq(key, found), has_top_key(key, rest))
        case Ast.TypeTop{ Ast.TypeDecl{ found,  _,  _,  _,  _}}:
          Bool.or(String.eq(key, found), has_top_key(key, rest))
        case Ast.LawTop{ Ast.LawDecl{ found,  _,  _,  _}}:
          Bool.or(String.eq(key, found), has_top_key(key, rest))

def find_generated_identity(key: String, identities: List<&2, GeneratedIdentity>) -> Maybe<&2, GeneratedIdentity>:
  match identities:
    case Nil{}: None{}
    case +entry <> rest:
      match entry:
        case GeneratedIdentity{ found,  _,  _,  _}:
          find_generated_identity_match(key, entry, rest, found, String.eq(key, found))

def find_generated_identity_match(key: String, entry: GeneratedIdentity, rest: List<&2, GeneratedIdentity>, found: String, matches: Bool) -> Maybe<&2, GeneratedIdentity>:
  match matches:
    case True{}: Some{entry}
    case False{}: find_generated_identity(key, rest)

def template_span(template: TemplateDef) -> Ast.SourceSpan:
  match template:
    case TemplateDef{ _,  _,  _,  _,  _,  Ast.Definition{_, _, _, _, _, span}}: span

def generated_actuals(template: TemplateDef, actuals: List<&2, List<&2, Ast.SyntaxTerm>>, templates: List<&2, TemplateDef>, existing: List<&2, Ast.TopLevel>, identities: List<&2, GeneratedIdentity>) -> GeneratedBuild:
  match actuals:
    case Nil{}: GeneratedBuild{ Nil{}, identities,  None{}}
    case +values <> rest:
      expanded_values = expand_terms(values, templates)
      serialized_args = serialize_terms(expanded_values)
      template_key = match template:
        case TemplateDef{key,  _,  _,  _,  _,  _}: key
      identity = encode_string(template_key) ++ serialized_args
      local_key = generated_local_key(template, expanded_values)
      canonical_key = generated_key(template, expanded_values)
      generated_actual_case(template, rest, templates, existing, identities, template_key, identity, local_key, canonical_key, expanded_values, find_generated_identity(canonical_key, identities))

def generated_actual_case(template: TemplateDef, rest: List<&2, List<&2, Ast.SyntaxTerm>>, templates: List<&2, TemplateDef>, existing: List<&2, Ast.TopLevel>, identities: List<&2, GeneratedIdentity>, template_key: String, identity: String, local_key: String, canonical_key: String, expanded_values: List<&2, Ast.SyntaxTerm>, previous: Maybe<&2, GeneratedIdentity>) -> GeneratedBuild:
  match previous:
    case Some{ GeneratedIdentity{ _,  _,  _,  found_identity}}:
      generated_identity_collision(template, rest, templates, existing, identities, identity, found_identity, String.eq(identity, found_identity))
    case None{}: generated_actual_new(template, rest, templates, existing, identities, template_key, identity, local_key, canonical_key, expanded_values, has_top_key(local_key, existing))

def generated_identity_collision(template: TemplateDef, rest: List<&2, List<&2, Ast.SyntaxTerm>>, templates: List<&2, TemplateDef>, existing: List<&2, Ast.TopLevel>, identities: List<&2, GeneratedIdentity>, identity: String, found_identity: String, matches: Bool) -> GeneratedBuild:
  match matches:
    case False{}: GeneratedBuild{ Nil{}, identities, Some{template_span(template)}}
    case True{}: generated_actuals(template, rest, templates, existing, identities)

def generated_actual_new(template: TemplateDef, rest: List<&2, List<&2, Ast.SyntaxTerm>>, templates: List<&2, TemplateDef>, existing: List<&2, Ast.TopLevel>, identities: List<&2, GeneratedIdentity>, template_key: String, identity: String, local_key: String, canonical_key: String, expanded_values: List<&2, Ast.SyntaxTerm>, collision: Bool) -> GeneratedBuild:
  match collision:
    case True{}: GeneratedBuild{ Nil{}, identities, Some{template_span(template)}}
    case False{}:
      definition = specialize_definition(template, expanded_values)
      entry = GeneratedIdentity{ canonical_key, template_key, local_key, identity}
      generated_actual_complete(definition, generated_actuals(template, rest, templates, existing, entry <> identities))

def generated_actual_complete(definition: Ast.Definition, result: GeneratedBuild) -> GeneratedBuild:
  match result:
    case GeneratedBuild{ rest_definitions, next_identities, collision}: GeneratedBuild{ Ast.DefTop{definition} <> rest_definitions, next_identities, collision}

def generated_for_module(namespace: String, declarations: List<&2, Ast.TopLevel>, templates: List<&2, TemplateDef>, modules: List<&2, Loader.LoadedModule>, identities: List<&2, GeneratedIdentity>) -> GeneratedBuild:
  match templates:
    case Nil{}: GeneratedBuild{ Nil{}, identities,  None{}}
    case +template <> rest:
      match template:
        case TemplateDef{ template_key,  owner,  _,  _,  _,  _}:
          generated_for_module_match(namespace, declarations, templates, modules, identities, template, template_key, owner, rest, String.eq(namespace, owner))

def generated_for_module_match(namespace: String, declarations: List<&2, Ast.TopLevel>, templates: List<&2, TemplateDef>, modules: List<&2, Loader.LoadedModule>, identities: List<&2, GeneratedIdentity>, template: TemplateDef, template_key: String, owner: String, rest: List<&2, TemplateDef>, is_owner: Bool) -> GeneratedBuild:
  match is_owner:
    case False{}: generated_for_module(namespace, declarations, rest, modules, identities)
    case True{}:
      generated_for_module_here(namespace, declarations, templates, modules, identities, rest, generated_actuals(template, actual_in_modules(modules, template_key, templates), templates, declarations, identities))

def generated_for_module_here(namespace: String, declarations: List<&2, Ast.TopLevel>, templates: List<&2, TemplateDef>, modules: List<&2, Loader.LoadedModule>, identities: List<&2, GeneratedIdentity>, rest: List<&2, TemplateDef>, here: GeneratedBuild) -> GeneratedBuild:
  match here:
    case GeneratedBuild{ here_definitions, here_identities, Some{span}}: GeneratedBuild{here_definitions, here_identities, Some{span}}
    case GeneratedBuild{ here_definitions, here_identities, None{}}:
      generated_for_module_merge(here_definitions, generated_for_module(namespace, declarations, rest, modules, here_identities))

def generated_for_module_merge(here_definitions: List<&2, Ast.TopLevel>, rest: GeneratedBuild) -> GeneratedBuild:
  match rest:
    case GeneratedBuild{rest_definitions, rest_identities, collision}: GeneratedBuild{List.append(&2, Ast.TopLevel, here_definitions, rest_definitions), rest_identities, collision}

def generate_round(modules: List<&2, Loader.LoadedModule>, templates: List<&2, TemplateDef>, identities: List<&2, GeneratedIdentity>) -> GeneratedRound:
  match modules:
    case Nil{}: GeneratedRound{ Nil{},  False{}, identities,  None{}}
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{namespace,  Ast.Module{path, imports, declarations}}:
          generate_round_loaded(namespace, path, imports, declarations, rest, templates, generated_for_module(namespace, declarations, templates, modules, identities))

def generate_round_loaded(namespace: String, path: String, imports: List<&2, Ast.ModuleImport>, declarations: List<&2, Ast.TopLevel>, rest: List<&2, Loader.LoadedModule>, templates: List<&2, TemplateDef>, generated: GeneratedBuild) -> GeneratedRound:
  match generated:
    case GeneratedBuild{definitions, next_identities, build_collision}:
      generate_round_merge(namespace, path, imports, declarations, definitions, build_collision, generate_round(rest, templates, next_identities))

def generate_round_merge(namespace: String, path: String, imports: List<&2, Ast.ModuleImport>, declarations: List<&2, Ast.TopLevel>, definitions: List<&2, Ast.TopLevel>, build_collision: Maybe<&2, Ast.SourceSpan>, next: GeneratedRound) -> GeneratedRound:
  match next:
    case GeneratedRound{next_modules, changed, final_identities, next_collision}:
      GeneratedRound{
        Loader.LoadedModule{namespace, Ast.Module{path, imports, List.append(&2, Ast.TopLevel, declarations, definitions)}} <> next_modules,
        Bool.or(changed, not(List.is_empty(&2, Ast.TopLevel, definitions))),
        final_identities,
        first_invalid(build_collision, next_collision)
      }

def generate_until_stable(modules: List<&2, Loader.LoadedModule>, templates: List<&2, TemplateDef>, identities: List<&2, GeneratedIdentity>) -> GeneratedRound:
  generate_until_result(templates, generate_round(modules, templates, identities))

def generate_until_result(templates: List<&2, TemplateDef>, result: GeneratedRound) -> GeneratedRound:
  match result:
    case GeneratedRound{ next,  _,  next_identities,  Some{ span}}:
      GeneratedRound{ next,  False{},  next_identities,  Some{ span}}
    case GeneratedRound{ next,  True{},  next_identities,  None{}}:
      generate_until_stable(next, templates, next_identities)
    case GeneratedRound{ next,  False{},  next_identities,  None{}}:
      GeneratedRound{ next,  False{},  next_identities,  None{}}

def visible_templates(namespace: String, imports: List<&2, Ast.ModuleImport>, templates: List<&2, TemplateDef>) -> List<&2, TemplateDef>:
  List.append(&2, TemplateDef, local_templates(namespace, templates), List.append(&2, TemplateDef, imported_templates(namespace, imports, templates), templates))

def local_templates(namespace: String, templates: List<&2, TemplateDef>) -> List<&2, TemplateDef>:
  match templates:
    case Nil{}: Nil{}
    case +template <> rest:
      match template:
        case TemplateDef{key,  owner, imports, existing_keys,  _, definition}:
          local_template_match(namespace, rest, key, owner, imports, existing_keys, definition, String.eq(namespace, owner))

def local_template_match(namespace: String, rest: List<&2, TemplateDef>, key: String, owner: String, imports: List<&2, Ast.ModuleImport>, existing_keys: List<&2, String>, definition: Ast.Definition, is_local: Bool) -> List<&2, TemplateDef>:
  match is_local:
    case True{}: TemplateDef{key, owner, imports, existing_keys, strip_namespace(key, owner), definition} <> local_templates(namespace, rest)
    case False{}: local_templates(namespace, rest)

def imported_templates(namespace: String, imports: List<&2, Ast.ModuleImport>, templates: List<&2, TemplateDef>) -> List<&2, TemplateDef>:
  match imports:
    case Nil{}: Nil{}
    case +item <> rest:
      match item:
        case Ast.ModuleImport{path, alias,  _}:
          target = Path.namespace(namespace, path)
          List.append(&2, TemplateDef, imported_from(target, alias, templates), imported_templates(namespace, rest, templates))

def imported_from(target: String, alias: String, templates: List<&2, TemplateDef>) -> List<&2, TemplateDef>:
  match templates:
    case Nil{}: Nil{}
    case +template <> rest:
      match template:
        case TemplateDef{key,  owner, imports, existing_keys,  _, definition}:
          imported_from_match(target, alias, rest, key, owner, imports, existing_keys, definition, String.eq(target, owner))

def imported_from_match(target: String, alias: String, rest: List<&2, TemplateDef>, key: String, owner: String, imports: List<&2, Ast.ModuleImport>, existing_keys: List<&2, String>, definition: Ast.Definition, is_owner: Bool) -> List<&2, TemplateDef>:
  match is_owner:
    case True{}:
      local = strip_namespace(key, owner)
      (TemplateDef{key, owner, imports, existing_keys, alias ++ "." ++ local, definition}) <> imported_from(target, alias, rest)
    case False{}: imported_from(target, alias, rest)

def expand_modules(modules: List<&2, Loader.LoadedModule>, templates: List<&2, TemplateDef>, identities: List<&2, GeneratedIdentity>) -> List<&2, Loader.LoadedModule>:
  match modules:
    case Nil{}: Nil{}
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{namespace,  Ast.Module{path, imports, declarations}}:
          context = visible_templates(namespace, imports, templates)
          expanded = strip_template_decls(namespace, declarations, context, identities)
          Loader.LoadedModule{namespace,  Ast.Module{path, imports,  expanded}} <> expand_modules(rest, templates, identities)
 

def has_late_template_binder(binders: List<&2, Ast.TelescopeItem>, saw_runtime: Bool) -> Bool:
  match binders:
    case Nil{}: False{}
    case +binder <> rest:
      match binder:
        case Ast.TemplateBinder{ _,  _,  _,  _}:
          Bool.or(saw_runtime, has_late_template_binder(rest, saw_runtime))
        case Ast.Binder{ _,  _,  _,  _,  _}:
          has_late_template_binder(rest, True{})

def invalid_template_definitions(modules: List<&2, Loader.LoadedModule>) -> Maybe<&2, Ast.SourceSpan>:
  match modules:
    case Nil{}: None{}
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{_, Ast.Module{_, _, declarations}}:
          first_invalid(invalid_template_decls(declarations), invalid_template_definitions(rest))

def invalid_template_decls(declarations: List<&2, Ast.TopLevel>) -> Maybe<&2, Ast.SourceSpan>:
  match declarations:
    case Nil{}: None{}
    case +decl <> rest:
      match decl:
        case Ast.DefTop{ Ast.Definition{_, binders, _, _, _, span}}:
          invalid_template_decl(binders, span, rest, has_late_template_binder(binders, False{}))
        case _: invalid_template_decls(rest)

def invalid_template_decl(binders: List<&2, Ast.TelescopeItem>, span: Ast.SourceSpan, rest: List<&2, Ast.TopLevel>, invalid: Bool) -> Maybe<&2, Ast.SourceSpan>:
  match invalid:
    case True{}: Some{span}
    case False{}: invalid_template_decls(rest)

def invalid_application(term: Ast.SyntaxTerm, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:

  match term:
    case Ast.TermRef{key, span}:
      invalid_reference(span, find_template(key, templates))
    case Ast.TermApp{ _,  _,  _}:
      invalid_application_spine(term, templates, flatten_application(term))
    case Ast.TermTemplate{ inner, span}: first_invalid(Some{span}, invalid_application(inner, templates))
    case Ast.TermBang{ inner,  _}: invalid_application(inner, templates)
    case Ast.TermSub{value, body,  _}: first_invalid(invalid_application(value, templates), invalid_application(body, templates))
    case Ast.TermLet{values, body,  _}: first_invalid(invalid_terms(values, templates), invalid_application(body, templates))
    case Ast.TermAnn{ inner, ty,  _}: first_invalid(invalid_application(inner, templates), invalid_application(ty, templates))
    case Ast.TermType{kind,  _}: invalid_application(kind, templates)
    case Ast.TermMin{left, right,  _}: first_invalid(invalid_application(left, templates), invalid_application(right, templates))
    case Ast.TermAll{ty, body,  _}: first_invalid(invalid_application(ty, templates), invalid_application(body, templates))
    case Ast.TermLam{body,  _}: invalid_application(body, templates)
    case Ast.TermAdt{args,  _}: invalid_terms(args, templates)
    case Ast.TermFill{head, args,  _}: first_invalid(invalid_application(head, templates), invalid_terms(args, templates))
    case Ast.TermPlus{head, args,  _}: first_invalid(invalid_application(head, templates), invalid_terms(args, templates))
    case Ast.TermCtr{args,  _}: invalid_terms(args, templates)
    case Ast.TermMat{head, matched,  _}: first_invalid(invalid_application(head, templates), invalid_application(matched, templates))
    case Ast.TermEqual{left, right, ty,  _}: first_invalid(invalid_application(left, templates), first_invalid(invalid_application(right, templates), invalid_application(ty, templates)))
    case Ast.TermRewrite{equation, proof, body,  _}: first_invalid(invalid_application(equation, templates), first_invalid(invalid_application(proof, templates), invalid_application(body, templates)))
    case Ast.BodyMatch{scrutinees, cases,  _}: first_invalid(invalid_terms(scrutinees, templates), invalid_terms(cases, templates))
    case Ast.BodyCase{body,  _}: invalid_application(body, templates)
    case Ast.BodyLocal{values, body,  _}: first_invalid(invalid_terms(values, templates), invalid_application(body, templates))
    case Ast.BodyReply{ inner,  _}: invalid_application(inner, templates)
    case _: None{}

def invalid_reference(span: Ast.SourceSpan, found: Maybe<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match found:
    case Some{ _}: Some{span}
    case None{}: None{}

def invalid_application_spine(term: Ast.SyntaxTerm, templates: List<&2, TemplateDef>, spine: ApplicationSpine) -> Maybe<&2, Ast.SourceSpan>:
  match spine:
    case ApplicationSpine{head, args, span}:
      invalid_application_head(term, templates, head, args, span, template_for_head(head, templates))

def invalid_application_head(term: Ast.SyntaxTerm, templates: List<&2, TemplateDef>, head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, found: Maybe<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match found:
    case Some{ template}:
      arity = match template:
        case TemplateDef{_, _, _, _, _, Ast.Definition{_, binders, _, _, _, _}}: leading_template_count(binders)
      invalid_application_arity(args, arity, span, templates, List.length(&2, Ast.SyntaxTerm, args) >= arity)
    case None{}: invalid_application_parts(term, templates)

def invalid_application_arity(args: List<&2, Ast.SyntaxTerm>, arity: Nat, span: Ast.SourceSpan, templates: List<&2, TemplateDef>, enough: Bool) -> Maybe<&2, Ast.SourceSpan>:
  match enough:
    case False{}: Some{span}
    case True{}: invalid_application_arguments(args, arity, span, templates, take_template_args(args, arity))

def invalid_application_arguments(args: List<&2, Ast.SyntaxTerm>, arity: Nat, span: Ast.SourceSpan, templates: List<&2, TemplateDef>, values: Maybe<&2, List<&2, Ast.SyntaxTerm>>) -> Maybe<&2, Ast.SourceSpan>:
  match values:
    case None{}: Some{span}
    case Some{_}: first_invalid(invalid_template_args(args, arity, span, templates), invalid_terms(drop_args(args, arity), templates))

def invalid_application_parts(term: Ast.SyntaxTerm, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match term:
    case Ast.TermApp{fn, arg, _}: first_invalid(invalid_application(fn, templates), invalid_application(arg, templates))
    case _: None{}

def invalid_template_args(args: List<&2, Ast.SyntaxTerm>, count: Nat, app_span: Ast.SourceSpan, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match count:
    case 0n: None{}
    case _:
      match args:
        case +Ast.TermTemplate{term,  _} <> rest:
          invalid_template_argument(term, rest, count, app_span, templates, has_open_vars(term, 0n))
        case _: Some{app_span}

def invalid_template_argument(term: Ast.SyntaxTerm, rest: List<&2, Ast.SyntaxTerm>, count: Nat, app_span: Ast.SourceSpan, templates: List<&2, TemplateDef>, has_open: Bool) -> Maybe<&2, Ast.SourceSpan>:
  match has_open:
    case True{}: Some{app_span}
    case False{}:
      first_invalid(invalid_application(term, templates), invalid_template_args(rest, count - 1n, app_span, templates))

def has_open_vars(term: Ast.SyntaxTerm, depth: Nat) -> Bool:
  match term:
    case Ast.TermVar{_, index, _}: index >= depth
    case Ast.TermSub{_, value, body, _}: Bool.or(has_open_vars(value, depth), has_open_vars(body, depth + 1n))
    case Ast.TermLet{keys, _, _, values, body, _}: Bool.or(has_open_vars_terms(values, depth), has_open_vars(body, depth + List.length(&2, String, keys)))
    case Ast.TermAnn{ value, ty,  _}: Bool.or(has_open_vars(value, depth), has_open_vars(ty, depth))
    case Ast.TermTemplate{ value,  _}: has_open_vars(value, depth)
    case Ast.TermBang{ inner,  _}: has_open_vars(inner, depth)
    case Ast.TermType{kind,  _}: has_open_vars(kind, depth)
    case Ast.TermMin{left, right,  _}: Bool.or(has_open_vars(left, depth), has_open_vars(right, depth))
    case Ast.TermAll{_, _, _, ty, body, _}: Bool.or(has_open_vars(ty, depth), has_open_vars(body, depth + 1n))
    case Ast.TermLam{_, _, _, body, _}: has_open_vars(body, depth + 1n)
    case Ast.TermApp{fn, arg,  _}: Bool.or(has_open_vars(fn, depth), has_open_vars(arg, depth))
    case Ast.TermAdt{_, args, _, _}: has_open_vars_terms(args, depth)
    case Ast.TermFill{head, args,  _}: Bool.or(has_open_vars(head, depth), has_open_vars_terms(args, depth))
    case Ast.TermPlus{head, args,  _}: Bool.or(has_open_vars(head, depth), has_open_vars_terms(args, depth))
    case Ast.TermCtr{_, args, _}: has_open_vars_terms(args, depth)
    case Ast.TermMat{_, head, matched, _}: Bool.or(has_open_vars(head, depth), has_open_vars(matched, depth))
    case Ast.TermEqual{left, right, ty,  _}: Bool.or(has_open_vars(left, depth), Bool.or(has_open_vars(right, depth), has_open_vars(ty, depth)))
    case Ast.TermRewrite{equation, proof, body,  _}: Bool.or(has_open_vars(equation, depth), Bool.or(has_open_vars(proof, depth), has_open_vars(body, depth)))
    case Ast.BodyMatch{scrutinees, cases,  _}: Bool.or(has_open_vars_terms(scrutinees, depth), has_open_vars_terms(cases, depth))
    case Ast.BodyCase{patterns, body,  _}: has_open_vars(body, depth + Core.pattern_list_depth(patterns))
    case Ast.BodyLocal{patterns, _, values, body, _}: Bool.or(has_open_vars_terms(values, depth), has_open_vars(body, depth + Core.pattern_list_depth(patterns)))
    case Ast.BodyReply{ value,  _}: has_open_vars(value, depth)
    case _: False{}

def has_open_vars_terms(terms: List<&2, Ast.SyntaxTerm>, depth: Nat) -> Bool:
  match terms:
    case Nil{}: False{}
    case +term <> rest: Bool.or(has_open_vars(term, depth), has_open_vars_terms(rest, depth))
def invalid_terms(terms: List<&2, Ast.SyntaxTerm>, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match terms:
    case Nil{}: None{}
    case +term <> rest: first_invalid(invalid_application(term, templates), invalid_terms(rest, templates))

def first_invalid(left: Maybe<&2, Ast.SourceSpan>, right: Maybe<&2, Ast.SourceSpan>) -> Maybe<&2, Ast.SourceSpan>:
  match left:
    case Some{value}: Some{value}
    case None{}: right

def invalid_definitions(declarations: List<&2, Ast.TopLevel>, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match declarations:
    case Nil{}: None{}
    case +decl <> rest:
      match decl:
        case Ast.DefTop{ Ast.Definition{binders, result, body,  _}}:
          invalid_definition(binders, result, body, rest, templates, has_template_binder(binders))
        case Ast.TypeTop{ Ast.TypeDecl{params, kind, constructors,  _}}:
          first_invalid(first_invalid(invalid_binders(params, templates), invalid_application(kind, templates)), first_invalid(invalid_constructors(constructors, templates), invalid_definitions(rest, templates)))
        case Ast.LawTop{ Ast.LawDecl{clauses, body,  _}}:
          first_invalid(first_invalid(invalid_clauses(clauses, templates), invalid_application(body, templates)), invalid_definitions(rest, templates))

def invalid_definition(binders: List<&2, Ast.TelescopeItem>, result: Ast.OptionalTerm, body: Ast.DefBody, rest: List<&2, Ast.TopLevel>, templates: List<&2, TemplateDef>, is_template: Bool) -> Maybe<&2, Ast.SourceSpan>:
  match is_template:
    case True{}: invalid_definitions(rest, templates)
    case False{}:
      invalid_body = match body:
        case Ast.DefTerm{term}: invalid_application(term, templates)
        case Ast.DefImports{ _}: None{}
      first_invalid(first_invalid(invalid_binders(binders, templates), invalid_optional(result, templates)), first_invalid(invalid_body, invalid_definitions(rest, templates)))

def invalid_optional(value: Ast.OptionalTerm, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match value:
    case Ast.NoTerm{}: None{}
    case Ast.SomeTerm{term}: invalid_application(term, templates)

def invalid_binders(binders: List<&2, Ast.TelescopeItem>, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match binders:
    case Nil{}: None{}
    case +item <> rest:
      match item:
        case Ast.Binder{_, _, _, ty, _}: first_invalid(invalid_application(ty, templates), invalid_binders(rest, templates))
        case Ast.TemplateBinder{_, _, ty, _}: first_invalid(invalid_application(ty, templates), invalid_binders(rest, templates))

def invalid_constructors(constructors: List<&2, Ast.ConstructorDecl>, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match constructors:
    case Nil{}: None{}
    case +constructor <> rest:
      match constructor:
        case Ast.Constructor{_, fields, _}: first_invalid(invalid_binders(fields, templates), invalid_constructors(rest, templates))

def invalid_clauses(clauses: List<&2, Ast.Clause>, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match clauses:
    case Nil{}: None{}
    case +clause <> rest:
      match clause:
        case Ast.ClauseFor{_, _, _, ty, condition, _}: first_invalid(invalid_application(ty, templates), first_invalid(invalid_maybe(condition, templates), invalid_clauses(rest, templates)))

def invalid_maybe(value: Maybe<&2, Ast.SyntaxTerm>, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match value:
    case None{}: None{}
    case Some{value}: invalid_application(value, templates)

def expand(modules: List<&2, Loader.LoadedModule>) -> ExpandResult:
  template_expand_templates(modules, collect_templates(modules), invalid_template_definitions(modules))

def template_expand_templates(modules: List<&2, Loader.LoadedModule>, templates: List<&2, TemplateDef>, template_error: Maybe<&2, Ast.SourceSpan>) -> ExpandResult:
  match template_error:
    case Some{span}: ExpandFailure{"template binders must precede runtime binders", span}
    case None{}:
      template_expand_modules(modules, templates, invalid_modules(modules, templates))

def template_expand_modules(modules: List<&2, Loader.LoadedModule>, templates: List<&2, TemplateDef>, module_error: Maybe<&2, Ast.SourceSpan>) -> ExpandResult:
  match module_error:
    case Some{span}: ExpandFailure{"template application requires a compile-time template argument", span}
    case None{}:
      template_expand_round(templates, generate_until_stable(modules, templates, Nil{}))

def template_expand_round(templates: List<&2, TemplateDef>, generated: GeneratedRound) -> ExpandResult:
  match generated:
    case GeneratedRound{modules, _, _, Some{span}}: ExpandFailure{"template specialization hash collision", span}
    case GeneratedRound{modules, _, identities, None{}}:
      template_expand_generated(modules, identities, templates, invalid_modules(modules, templates))

def template_expand_generated(modules: List<&2, Loader.LoadedModule>, identities: List<&2, GeneratedIdentity>, templates: List<&2, TemplateDef>, module_error: Maybe<&2, Ast.SourceSpan>) -> ExpandResult:
  match module_error:
    case Some{span}: ExpandFailure{"template application requires a closed compile-time argument", span}
    case None{}: ExpandSuccess{expand_modules(modules, templates, identities)}

def invalid_modules(modules: List<&2, Loader.LoadedModule>, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match modules:
    case Nil{}: None{}
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{namespace,  Ast.Module{ _, imports, declarations}}:
          context = visible_templates(namespace, imports, templates)
          first_invalid(invalid_definitions(declarations, context), invalid_modules(rest, templates))
