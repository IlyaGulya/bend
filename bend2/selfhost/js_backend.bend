import Base
import ./ast.bend as Ast
import ./backend_ir.bend as BIR
import ./index_lookup.bend as IndexLookup

# Target selection is explicit. A foreign declaration names its own declared
# import alternatives, and this target takes the first declared .js path; it
# never derives one path from another. A missing alternative is a target error,
# never undefined success. link() is pure: it names the files the CLI must read
# and splices them once each, so one module's state is one module's state.
type EmitResult is Data:
  EmitSuccess{source: String}
  EmitFailure{message: String, span: Ast.SourceSpan}
type LinkSource is Data:
  LinkSource{path: String, namespace: String, span: Ast.SourceSpan}
type LinkResult is Data:
  LinkSuccess{sources: List<&2, LinkSource>}
  LinkFailure{message: String, span: Ast.SourceSpan}
# The host supplies BIR.SourceFile bytes, nothing else: namespace, span and
# selection are BIR facts that link() derives, and the join is by exact
# declared path. The host never invents a namespace or inspects the program.
type JSParameter is Data:
  JSParameterNat{}
  JSParameterOther{}
  JSParameterUnresolved{}
def js_source(sources: List<&2, String>) -> Maybe<&2, String>:
  match sources:
    case Nil{}: None{}
    case +path <> rest: js_source_ext(String.ends_with(path, ".js"), path, rest)
def js_source_ext(ends: Bool, +path: String, rest: List<&2, String>) -> Maybe<&2, String>:
  match ends:
    case True{}: Some{path}
    case False{}: js_source(rest)
# One path splices once, under one namespace: a second namespace would rewrite
# its CID(k) differently, so it is a compile error, never a silent first wins.
def link_add(path: String, namespace: String, span: Ast.SourceSpan, planned: List<&2, LinkSource>) -> LinkResult:
  match planned:
    case Nil{}: LinkSuccess{[LinkSource{path, namespace, span}]}
    case +item <> rest:
      match item:
        case LinkSource{+known, known_namespace, _}:
          link_add_known(String.eq(path, known), String.eq(namespace, known_namespace), path, namespace, span, known, planned, item, rest)
def link_add_known(same_path: Bool, same_namespace: Bool, +path: String, +namespace: String, +span: Ast.SourceSpan, known: String, planned: List<&2, LinkSource>, item: LinkSource, rest: List<&2, LinkSource>) -> LinkResult:
  match same_path:
    case True{}: link_add_namespace(same_namespace, path, span, planned)
    case False{}: link_add_tail(link_add(path, namespace, span, rest), item)
def link_add_namespace(same_namespace: Bool, +path: String, +span: Ast.SourceSpan, planned: List<&2, LinkSource>) -> LinkResult:
  match same_namespace:
    case True{}: LinkSuccess{planned}
    case False{}: LinkFailure{String.append("bend: ", String.append(path, " is imported from two namespaces")), span}
def link_add_tail(inner: LinkResult, item: LinkSource) -> LinkResult:
  match inner:
    case LinkSuccess{+values}: LinkSuccess{item <> values}
    case LinkFailure{message, span}: LinkFailure{message, span}
def link_declarations(items: List<&2, BIR.Declaration>, acc: List<&2, LinkSource>) -> LinkResult:
  match items:
    case Nil{}: LinkSuccess{List.reverse(&2, LinkSource, acc)}
    case +item <> rest:
      match item:
        case BIR.ForeignDeclaration{_, namespace, imported, _, decl_sources, _, span, _, _}:
          link_declaration_source(js_source(decl_sources), namespace, imported, span, acc, rest)
        case _: link_declarations(rest, acc)
def link_declaration_source(found: Maybe<&2, String>, +namespace: String, +imported: String, +span: Ast.SourceSpan, acc: List<&2, LinkSource>, rest: List<&2, BIR.Declaration>) -> LinkResult:
  match found:
    case Some{+path}: link_declaration_plan(link_add(path, namespace, span, acc), rest)
    case None{}: LinkFailure{String.append("bend: foreign definition has no .js import: ", imported), span}
def link_declaration_plan(planned: LinkResult, rest: List<&2, BIR.Declaration>) -> LinkResult:
  match planned:
    case LinkSuccess{sources}: link_declarations(rest, sources)
    case LinkFailure{message, span}: LinkFailure{message, span}
# A foreign request and a constructor must not share one name: the request
# escapes as that key while the constructor lives in the same tag space.
def constructors_named(items: List<&2, BIR.ConstructorLayout>, key: String) -> Bool:
  match items:
    case Nil{}: False{}
    case BIR.ConstructorLayout{_, +known, _, _} <> rest:
      constructors_named_same(String.eq(key, known), rest, key)
def constructors_named_same(same: Bool, rest: List<&2, BIR.ConstructorLayout>, +key: String) -> Bool:
  match same:
    case True{}: True{}
    case False{}: constructors_named(rest, key)
def foreign_name_check(items: List<&2, BIR.Declaration>, constructors: List<&2, BIR.ConstructorLayout>) -> Maybe<&2, LinkResult>:
  match items:
    case Nil{}: None{}
    case +item <> rest:
      match item:
        case BIR.ForeignDeclaration{key, _, _, _, _, _, span, _, _}:
          foreign_name_check_named(constructors_named(constructors, key), key, span, rest, constructors)
        case _: foreign_name_check(rest, constructors)
def foreign_name_check_named(same: Bool, +key: String, +span: Ast.SourceSpan, rest: List<&2, BIR.Declaration>, constructors: List<&2, BIR.ConstructorLayout>) -> Maybe<&2, LinkResult>:
  match same:
    case True{}: Some{LinkFailure{String.append(key, " names both a constructor and a foreign def: name one apart"), span}}
    case False{}: foreign_name_check(rest, constructors)
        case _: foreign_name_check(rest, constructors)
def link_checked(check: Maybe<&2, LinkResult>, values: List<&2, BIR.Declaration>) -> LinkResult:
  match check:
    case Some{failure}: failure
    case None{}: link_declarations(values, Nil{})
def link(program: BIR.Program) -> LinkResult:
  match program:
    case BIR.Program{_, values, constructors, _, _, _}:
      link_checked(foreign_name_check(values, constructors), values)

# An effect source is spliced verbatim, so its CID(<key>) spellings are the
# only syntax this target resolves: the program, not the module, owns the name
# of a constructor or def. The pass is lexical: comments, strings and template
# literals are copied through, and a whole CID(<key>) is replaced by the quoted
# canonical key. A key this program does not declare is a compile error that
# names the file, never a tag no match knows.
type JSCidResult is Data:
  JSCidDone{source: String}
  JSCidFailure{message: String}
type JSMode is Data:
  JSCode{}
  JSLineComment{}
  JSBlockComment{}
  JSDoubleQuote{}
  JSSingleQuote{}
  JSBacktick{}
type JSScan is Data:
  JSScanComplete{output: List<&2, Char>}
  JSScanRefused{message: String}
type JSKeyScan is Data:
  JSKeyFound{key: String, rest: List<&2, Char>}
  JSKeyAbsent{}

def js_key_candidate(+namespace: String, +key: String) -> String:
  js_key_join(String.eq(namespace, ""), namespace, key)
def js_key_join(empty: Bool, +namespace: String, +key: String) -> String:
  match empty:
    case True{}: key
    case False{}: String.append(namespace, String.append(".", key))
def js_key_member(+keys: Map<&2, Bool>, key: String) -> Bool:
  js_key_member_found(IndexLookup.find(Bool, keys, key))
def js_key_member_found(found: Maybe<&2, Bool>) -> Bool:
  match found:
    case Some{_}: True{}
    case None{}: False{}
# The module's own namespace first, then the key as the source spells it.
def js_key_resolve(+keys: Map<&2, Bool>, +namespace: String, +key: String) -> Maybe<&2, String>:
  js_key_resolve_qualified(js_key_member(keys, js_key_candidate(namespace, key)), keys, namespace, key)
def js_key_resolve_qualified(member: Bool, +keys: Map<&2, Bool>, +namespace: String, +key: String) -> Maybe<&2, String>:
  match member:
    case True{}: Some{js_key_candidate(namespace, key)}
    case False{}: js_key_resolve_bare(js_key_member(keys, key), key)
def js_key_resolve_bare(member: Bool, +key: String) -> Maybe<&2, String>:
  match member:
    case True{}: Some{key}
    case False{}: None{}

def js_key_declaration(item: BIR.Declaration, keys: Map<&2, Bool>) -> Map<&2, Bool>:
  match item:
    case BIR.FunctionDeclaration{key, _, _}: Map.set(&2, Bool, keys, key, True{})
    case BIR.LazyDeclaration{key, _}: Map.set(&2, Bool, keys, key, True{})
    case BIR.NativeDeclaration{key, _, _}: Map.set(&2, Bool, keys, key, True{})
    case BIR.ForeignDeclaration{key, _, _, _, _, _, _, _, _}: Map.set(&2, Bool, keys, key, True{})
def js_key_declarations(items: List<&2, BIR.Declaration>, keys: Map<&2, Bool>) -> Map<&2, Bool>:
  match items:
    case Nil{}: keys
    case +item <> rest: js_key_declarations(rest, js_key_declaration(item, keys))
def js_key_layouts(items: List<&2, BIR.ConstructorLayout>, keys: Map<&2, Bool>) -> Map<&2, Bool>:
  match items:
    case Nil{}: keys
    case BIR.ConstructorLayout{_, key, _, _} <> rest: js_key_layouts(rest, Map.set(&2, Bool, keys, key, True{}))
def js_key_families(items: List<&2, BIR.Family>, keys: Map<&2, Bool>) -> Map<&2, Bool>:
  match items:
    case Nil{}: keys
    case BIR.Family{key, _, _, _, _, _} <> rest: js_key_families(rest, Map.set(&2, Bool, keys, key, True{}))
def js_key_functions(items: List<&2, BIR.TypeFunction>, keys: Map<&2, Bool>) -> Map<&2, Bool>:
  match items:
    case Nil{}: keys
    case BIR.TypeFunction{key, _, _, _, _} <> rest: js_key_functions(rest, Map.set(&2, Bool, keys, key, True{}))
# Native authority, not spelling: a descriptor head names host IO/Nat only when
# the closed BIR family or type function declares that native marker. A module
# that shadows the name cannot become host IO or host Nat.
def js_native_families(items: List<&2, BIR.Family>, natives: Map<&2, String>) -> Map<&2, String>:
  match items:
    case Nil{}: natives
    case BIR.Family{key, _, native, _, _, _} <> rest: js_native_family(native, key, rest, natives)
# A family with no native marker is recorded as ""; a USER TYPE FUNCTION with
# no native marker is recorded as "TF". A family cannot alias another type, so
# "" is ordinary; a type function can alias Nat/IO, and classifying it without
# closed reduction would be a guess, so "TF" is unresolved here.
def js_native_family(native: Maybe<&2, String>, key: String, rest: List<&2, BIR.Family>, natives: Map<&2, String>) -> Map<&2, String>:
  match native:
    case None{}: js_native_families(rest, Map.set(&2, String, natives, key, ""))
    case Some{name}: js_native_families(rest, Map.set(&2, String, natives, key, name))
def js_native_functions(items: List<&2, BIR.TypeFunction>, natives: Map<&2, String>) -> Map<&2, String>:
  match items:
    case Nil{}: natives
    case BIR.TypeFunction{key, native, _, _, _} <> rest: js_native_function(native, key, rest, natives)
def js_native_function(native: Maybe<&2, String>, key: String, rest: List<&2, BIR.TypeFunction>, natives: Map<&2, String>) -> Map<&2, String>:
  match native:
    case None{}: js_native_functions(rest, Map.set(&2, String, natives, key, "TF"))
    case Some{name}: js_native_functions(rest, Map.set(&2, String, natives, key, name))
def js_native_markers(program: BIR.Program) -> Map<&2, String>:
  match program:
    case BIR.Program{_, _, _, families, type_functions, _}:
      js_native_functions(type_functions, js_native_families(families, Map.new(&2, String)))

def js_known_keys(program: BIR.Program) -> Map<&2, Bool>:
  match program:
    case BIR.Program{_, declarations, constructors, families, type_functions, _}:
      js_key_functions(type_functions, js_key_families(families, js_key_layouts(constructors, js_key_declarations(declarations, Map.new(&2, Bool)))))

def js_cid(applied: JSScan) -> JSCidResult:
  match applied:
    case JSScanComplete{output}: JSCidDone{String.from_list(List.reverse(&2, Char, output))}
    case JSScanRefused{message}: JSCidFailure{message}

def js_word(+char: Char) -> Bool:
  match char:
    case '_': True{}
    case _: Bool.or(Char.is_alpha(char), Char.is_digit(char))
def js_key_char(+char: Char) -> Bool:
  match char:
    case '.': True{}
    case '/': True{}
    case '~': True{}
    case '-': True{}
    case _: js_word(char)

# A lookahead decides once whether a literal closes; one that does not is not
# a literal, so its text stays code, exactly as the accepted compiler reads it.
def js_text_closes(chars: List<&2, Char>, +terminator: Char, +newline_ends: Bool) -> Bool:
  match chars:
    case Nil{}: False{}
    case '\\' <> rest: js_text_closes_escape(rest, terminator, newline_ends)
    case +char <> rest: js_text_closes_step(Char.is_eq(char, terminator), char, rest, terminator, newline_ends)
def js_text_closes_escape(rest: List<&2, Char>, terminator: Char, newline_ends: Bool) -> Bool:
  match rest:
    case Nil{}: False{}
    case _ <> more: js_text_closes(more, terminator, newline_ends)
def js_text_closes_step(same: Bool, char: Char, rest: List<&2, Char>, terminator: Char, +newline_ends: Bool) -> Bool:
  match same:
    case True{}: True{}
    case False{}: js_text_closes_newline(Bool.and(newline_ends, Char.is_eq(char, '\n')), rest, terminator, newline_ends)
def js_text_closes_newline(ends: Bool, rest: List<&2, Char>, terminator: Char, newline_ends: Bool) -> Bool:
  match ends:
    case True{}: False{}
    case False{}: js_text_closes(rest, terminator, newline_ends)
def js_block_closes(chars: List<&2, Char>) -> Bool:
  match chars:
    case Nil{}: False{}
    case '*' <> rest: js_block_closes_star(rest)
    case _ <> rest: js_block_closes(rest)
def js_block_closes_star(+rest: List<&2, Char>) -> Bool:
  match rest:
    case '/' <> _: True{}
    case _: js_block_closes(rest)

def js_emit_chars(chars: List<&2, Char>, +output: List<&2, Char>) -> List<&2, Char>:
  match chars:
    case Nil{}: output
    case char <> rest: js_emit_chars(rest, char <> output)

def js_scan(chars: List<&2, Char>, mode: JSMode, word: Bool, +output: List<&2, Char>, +keys: Map<&2, Bool>, +namespace: String) -> JSScan:
  match chars:
    case Nil{}: JSScanComplete{output}
    case char <> rest: js_scan_mode(mode, char, rest, word, output, keys, namespace)
def js_scan_mode(mode: JSMode, +char: Char, +rest: List<&2, Char>, word: Bool, +output: List<&2, Char>, +keys: Map<&2, Bool>, +namespace: String) -> JSScan:
  match mode:
    case JSCode{}: js_scan_code(char, rest, word, output, keys, namespace)
    case JSLineComment{}: js_scan_line(char, rest, output, keys, namespace)
    case JSBlockComment{}: js_scan_block(char, rest, output, keys, namespace)
    case JSDoubleQuote{}: js_scan_text(char, rest, JSDoubleQuote{}, '\"', output, keys, namespace)
    case JSSingleQuote{}: js_scan_text(char, rest, JSSingleQuote{}, '\'', output, keys, namespace)
    case JSBacktick{}: js_scan_text(char, rest, JSBacktick{}, '`', output, keys, namespace)

def js_scan_code(+char: Char, +rest: List<&2, Char>, +word: Bool, +output: List<&2, Char>, +keys: Map<&2, Bool>, +namespace: String) -> JSScan:
  match char:
    case '/': js_scan_slash(rest, output, keys, namespace)
    case '\"': js_scan(rest, Bool.pick(JSMode, js_text_closes(rest, '\"', True{}), JSDoubleQuote{}, JSCode{}), False{}, char <> output, keys, namespace)
    case '\'': js_scan(rest, Bool.pick(JSMode, js_text_closes(rest, '\'', True{}), JSSingleQuote{}, JSCode{}), False{}, char <> output, keys, namespace)
    case '`': js_scan(rest, Bool.pick(JSMode, js_text_closes(rest, '`', False{}), JSBacktick{}, JSCode{}), False{}, char <> output, keys, namespace)
    case 'C': js_scan_cid(word, rest, output, keys, namespace)
    case _: js_scan(rest, JSCode{}, js_word(char), char <> output, keys, namespace)
def js_scan_slash(+rest: List<&2, Char>, +output: List<&2, Char>, +keys: Map<&2, Bool>, +namespace: String) -> JSScan:
  match rest:
    case '/' <> more: js_scan(more, JSLineComment{}, False{}, '/' <> ('/' <> output), keys, namespace)
    case '*' <> +more: js_scan(more, Bool.pick(JSMode, js_block_closes(more), JSBlockComment{}, JSCode{}), False{}, '*' <> ('/' <> output), keys, namespace)
    case _: js_scan(rest, JSCode{}, False{}, '/' <> output, keys, namespace)

# A failed shape copies its prefix and resumes after it: I, D and ( can never
# begin an invocation themselves, so nothing is skipped.
def js_scan_cid(word: Bool, +rest: List<&2, Char>, +output: List<&2, Char>, +keys: Map<&2, Bool>, +namespace: String) -> JSScan:
  match word:
    case True{}: js_scan(rest, JSCode{}, True{}, 'C' <> output, keys, namespace)
    case False{}: js_scan_cid_prefix(rest, output, keys, namespace)
def js_scan_cid_prefix(+rest: List<&2, Char>, +output: List<&2, Char>, +keys: Map<&2, Bool>, +namespace: String) -> JSScan:
  match rest:
    case 'I' <> 'D' <> '(' <> +more: js_scan_cid_key(js_collect_key(more, Nil{}), more, output, keys, namespace)
    case _: js_scan(rest, JSCode{}, True{}, 'C' <> output, keys, namespace)
def js_scan_cid_key(pending: JSKeyScan, more: List<&2, Char>, +output: List<&2, Char>, +keys: Map<&2, Bool>, +namespace: String) -> JSScan:
  match pending:
    case JSKeyFound{key, rest}: js_scan_cid_found(key, rest, output, keys, namespace)
    case JSKeyAbsent{}: js_scan(more, JSCode{}, False{}, '(' <> ('D' <> ('I' <> ('C' <> output))), keys, namespace)
def js_scan_cid_found(key: String, rest: List<&2, Char>, output: List<&2, Char>, keys: Map<&2, Bool>, namespace: String) -> JSScan:
  js_scan_cid_resolved(js_key_resolve(keys, namespace, key), key, rest, output, keys, namespace)
def js_scan_cid_resolved(resolved: Maybe<&2, String>, +key: String, rest: List<&2, Char>, output: List<&2, Char>, keys: Map<&2, Bool>, namespace: String) -> JSScan:
  match resolved:
    case Some{found}: js_scan(rest, JSCode{}, False{}, js_emit_chars(String.to_list(js_quote(found)), output), keys, namespace)
    case None{}: JSScanRefused{String.append("CID(", String.append(key, ") names no constructor or def"))}

def js_collect_key(chars: List<&2, Char>, +collected: List<&2, Char>) -> JSKeyScan:
  match chars:
    case Nil{}: JSKeyAbsent{}
    case ')' <> rest: js_collect_key_close(collected, rest)
    case +char <> rest: js_collect_key_more(js_key_char(char), char, rest, collected)
def js_collect_key_close(+collected: List<&2, Char>, rest: List<&2, Char>) -> JSKeyScan:
  match collected:
    case Nil{}: JSKeyAbsent{}
    case _: JSKeyFound{String.from_list(List.reverse(&2, Char, collected)), rest}
def js_collect_key_more(valid: Bool, char: Char, rest: List<&2, Char>, collected: List<&2, Char>) -> JSKeyScan:
  match valid:
    case True{}: js_collect_key(rest, char <> collected)
    case False{}: JSKeyAbsent{}

def js_scan_line(+char: Char, +rest: List<&2, Char>, +output: List<&2, Char>, +keys: Map<&2, Bool>, +namespace: String) -> JSScan:
  match char:
    case '\n': js_scan(rest, JSCode{}, False{}, char <> output, keys, namespace)
    case '\\': js_scan_line_more(rest, output, keys, namespace)
    case _: js_scan(rest, JSLineComment{}, False{}, char <> output, keys, namespace)
def js_scan_line_more(+rest: List<&2, Char>, +output: List<&2, Char>, +keys: Map<&2, Bool>, +namespace: String) -> JSScan:
  match rest:
    case '\n' <> more: js_scan(more, JSLineComment{}, False{}, '\n' <> ('\\' <> output), keys, namespace)
    case _: js_scan(rest, JSLineComment{}, False{}, '\\' <> output, keys, namespace)
def js_scan_block(+char: Char, +rest: List<&2, Char>, +output: List<&2, Char>, +keys: Map<&2, Bool>, +namespace: String) -> JSScan:
  match char:
    case '*': js_scan_block_more(rest, output, keys, namespace)
    case _: js_scan(rest, JSBlockComment{}, False{}, char <> output, keys, namespace)
def js_scan_block_more(+rest: List<&2, Char>, +output: List<&2, Char>, +keys: Map<&2, Bool>, +namespace: String) -> JSScan:
  match rest:
    case '/' <> more: js_scan(more, JSCode{}, False{}, '/' <> ('*' <> output), keys, namespace)
    case _: js_scan(rest, JSBlockComment{}, False{}, '*' <> output, keys, namespace)

# A backslash owns the character after it. The lookahead promised a terminator,
# so the escape walk cannot reach the end of the input here.
def js_scan_text(+char: Char, +rest: List<&2, Char>, +mode: JSMode, terminator: Char, +output: List<&2, Char>, +keys: Map<&2, Bool>, +namespace: String) -> JSScan:
  match char:
    case '\\': js_scan_text_more(rest, mode, output, keys, namespace)
    case _: js_scan_text_plain(Char.is_eq(char, terminator), char, rest, mode, output, keys, namespace)
def js_scan_text_plain(same: Bool, +char: Char, +rest: List<&2, Char>, mode: JSMode, +output: List<&2, Char>, +keys: Map<&2, Bool>, +namespace: String) -> JSScan:
  match same:
    case True{}: js_scan(rest, JSCode{}, False{}, char <> output, keys, namespace)
    case False{}: js_scan(rest, mode, False{}, char <> output, keys, namespace)
def js_scan_text_more(rest: List<&2, Char>, mode: JSMode, +output: List<&2, Char>, keys: Map<&2, Bool>, namespace: String) -> JSScan:
  match rest:
    case Nil{}: JSScanComplete{'\\' <> output}
    case char <> more: js_scan(more, mode, False{}, char <> ('\\' <> output), keys, namespace)

type JSEffects is Data:
  JSEffectsReady{text: String}
  JSEffectsFailure{message: String, span: Ast.SourceSpan}

def js_source_text(items: List<&2, BIR.SourceFile>, path: String) -> Maybe<&2, String>:
  match items:
    case Nil{}: None{}
    case BIR.SourceFile{+known, source} <> rest:
      js_source_text_same(String.eq(path, known), source, rest, path)
def js_source_text_same(same: Bool, source: String, rest: List<&2, BIR.SourceFile>, +path: String) -> Maybe<&2, String>:
  match same:
    case True{}: Some{source}
    case False{}: js_source_text(rest, path)

# Each file is spliced once, in its own function scope, so its state is shared
# by every def it registers and its helpers cannot shadow the runtime's.
def js_effect_chunk(source: String) -> String:
  String.append("(() => {\n", String.append(source, "\n})();\n\n"))
def js_effect_sources(links: List<&2, LinkSource>, loaded: List<&2, BIR.SourceFile>, +keys: Map<&2, Bool>, acc: List<&2, String>) -> JSEffects:
  match links:
    case Nil{}: JSEffectsReady{String.join(List.reverse(&2, String, acc), "")}
    case +link <> rest:
      match link:
        case LinkSource{path, namespace, span}:
          js_effect_text(js_source_text(loaded, path), path, namespace, span, rest, loaded, keys, acc)
def js_effect_text(found: Maybe<&2, String>, +path: String, +namespace: String, +span: Ast.SourceSpan, rest: List<&2, LinkSource>, loaded: List<&2, BIR.SourceFile>, +keys: Map<&2, Bool>, acc: List<&2, String>) -> JSEffects:
  match found:
    case None{}: JSEffectsFailure{String.append("bend: missing JavaScript foreign source ", path), span}
    case Some{text}: js_effect_scan(js_cid(js_scan(String.to_list(text), JSCode{}, False{}, Nil{}, keys, namespace)), path, span, rest, loaded, keys, acc)
def js_effect_scan(result: JSCidResult, +path: String, +span: Ast.SourceSpan, rest: List<&2, LinkSource>, loaded: List<&2, BIR.SourceFile>, +keys: Map<&2, Bool>, acc: List<&2, String>) -> JSEffects:
  match result:
    case JSCidFailure{message}: JSEffectsFailure{String.append(String.append(path, ": "), message), span}
    case JSCidDone{source}: js_effect_sources(rest, loaded, keys, js_effect_chunk(source) <> acc)

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
    case _: js_escape_other(Char.to_u32(char), char)
# A Char that is no Unicode scalar is packed in Bend's own data: the sentinel
# DC00 and three 11-bit pieces. A literal carries that value as its four code
# units, so generated source never holds a raw internal Char and publishing the
# program as text later cannot lose it. Scalars stay literal.
def js_escape_other(code: U32, char: Char) -> String:
  js_escape_packed(js_char_packed(code), code, char)
def js_escape_packed(packed: Bool, code: U32, char: Char) -> String:
  match packed:
    case True{}: cat(["\\udc00", js_hex_escape(U32.div(code, 4194304)), js_hex_escape(U32.mod(U32.div(code, 2048), 2048)), js_hex_escape(U32.mod(code, 2048))])
    case False{}: String.from_list([char])
def js_char_packed(code: U32) -> Bool:
  Bool.or(Bool.and(U32.is_ge(code, 55296), U32.is_lt(code, 57344)), U32.is_gt(code, 1114111))
def js_hex_escape(unit: U32) -> String:
  cat(["\\u", js_hex_digit(U32.div(unit, 4096)), js_hex_digit(U32.mod(U32.div(unit, 256), 16)), js_hex_digit(U32.mod(U32.div(unit, 16), 16)), js_hex_digit(U32.mod(unit, 16))])
def js_hex_digit(value: U32) -> String:
  match value:
    case 0: "0"
    case 1: "1"
    case 2: "2"
    case 3: "3"
    case 4: "4"
    case 5: "5"
    case 6: "6"
    case 7: "7"
    case 8: "8"
    case 9: "9"
    case 10: "a"
    case 11: "b"
    case 12: "c"
    case 13: "d"
    case 14: "e"
    case 15: "f"
    case _: "0"

# Only the bounded escape is on append's left; never copy a growing prefix.
def js_quote_chars(chars: List<&2, Char>) -> String:
  match chars:
    case Nil{}: "\""
    case +char <> rest:
      String.append(js_escape_char(char), js_quote_chars(rest))

def js_quote(text: String) -> String:
  String.append("\"", js_quote_chars(String.to_list(text)))

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
    case BIR.TextValue{value}: js_quote(value)
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
  tail_call_name(code_name(code), values)
def tail_call_name(name: String, +values: List<&2, String>) -> String:
  +count = List.length(&2, String, values)
  tail_call_name_selected(name, values, count, Bool.and(Nat.is_gt(count, 0n), Nat.is_le(count, 32n)))
def tail_call_name_selected(name: String, +values: List<&2, String>, count: Nat, selected: Bool) -> String:
  match selected:
    case True{}: tail_call_named_name(name, String.join(values, ","), count)
    case False{}: cat(["run_many(", name, ",[", String.join(values, ","), "],$td)"])
def tail_call_named_name(+name: String, +joined: String, count: Nat) -> String:
  cat(["($td<64?", name, "(", String.append(joined, ",$td+1"), "):run_named", Nat.show(count), "(", name, ",", String.append(joined, ",$td"), ")"])
def multi_tail_call(code: U32, +values: List<&2, String>) -> String:
  +count = Nat.add(List.length(&2, String, values), 1n)
  multi_tail_selected(Bool.and(Nat.is_gt(count, 0n), Nat.is_le(count, 32n)), code, values, count)
def multi_tail_selected(selected: Bool, code: U32, +values: List<&2, String>, count: Nat) -> String:
  match selected:
    case True{}: multi_tail_named(code, String.join(values, ","), count)
    case False{}: cat(["run_many(", code_name(code), ",[", String.join(values, ","), ",$mr],$td)"])
def multi_tail_named(+code: U32, +joined: String, count: Nat) -> String:
  cat(["($td<64?", code_name(code), "(", String.append(joined, ",$mr,$td+1"), "):run_named", Nat.show(count), "(", code_name(code), ",", String.append(joined, ",$mr,$td"), ")"])
# A tail call keeps the caller's JavaScript frame, so the machine bounds the
# depth: $td counts the frames the current chain has already used and the call
# is direct only below 64. The guard is emitted at the call site instead of
# left to run_named<count>, because that helper receives the callee as a value,
# so its one call site is shared by every code body and cannot be resolved to
# one. A site that names its own callee stays monomorphic. The boundary arm is
# run_named<count> unchanged: it re-reads the same $td, and past 64 frames the
# call returns the pending marker that the machine dispatches with a fresh
# depth. Only one arm runs, so the atoms are read once.
def tail_call_selected(code: U32, values: List<&2, String>, count: Nat, selected: Bool) -> String:
  tail_call_name_selected(code_name(code), values, count, selected)
def public_closure(names: List<&2, String>, body: String) -> String:
  match names:
    case Nil{}: body
    case name <> rest:
      cat(["run_clo((", name, ",$raw=undefined)=>{const $base0=$ksp,$sp0=$sp;return run_force(", public_closure(rest, body), ",$raw,$base0,$sp0);})"])
def closure(code: U32, +captures: List<&2, BIR.Arg>, +parameters: List<&2, BIR.Parameter>) -> String:
  closure_named(code_name(code), captures, parameters)
def closure_named(name: String, +captures: List<&2, BIR.Arg>, +parameters: List<&2, BIR.Parameter>) -> String:
  +names = captured_names(captures, 0)
  +params = parameter_names(parameters)
  body = public_closure(params, tail_call_name(name, List.append(&2, String, names, params)))
  closure_captures(captures, names, body)
def multi_closure(ctx: JsCtx, code: U32, +captures: List<&2, BIR.Arg>, +parameters: List<&2, BIR.Parameter>) -> String:
  closure_named(multi_target_name(js_ctx_targets(ctx), code), captures, parameters)
def closure_captures(+captures: List<&2, BIR.Arg>, names: List<&2, String>, body: String) -> String:
  match captures:
    case Nil{}: body
    case _: cat(["((", String.join(names, ","), ")=>", body, ")(", String.join(arguments(captures), ","), ")"])
# A field key is a compile-time string in BIR, so the emitted object can name it
# as a literal property instead of computing it. comp.ts already spells every
# field that way and computes only `__proto__`, whose literal form sets a
# prototype instead of defining a field; the selfhost target wrote every field
# as a computed store, which hands the key back to the runtime on each
# allocation and denies the engine the shared literal map that makes a record
# allocation a clone. The same key is a named property of the projection below
# whenever it is a plain JavaScript identifier, so a read needs no keyed lookup.
def js_field_text(key: String) -> String:
  js_field_proto(String.eq(key, "__proto__"), key)
def js_field_proto(proto: Bool, +key: String) -> String:
  match proto:
    case True{}: cat(["[", js_quote(key), "]:"])
    case False{}: cat([js_quote(key), ":"])
def js_plain_key(key: String) -> Bool:
  js_plain_key_first(String.eq(key, "__proto__"), String.to_list(key))
def js_plain_key_first(proto: Bool, chars: List<&2, Char>) -> Bool:
  match proto:
    case True{}: False{}
    case False{}: js_plain_key_chars(chars)
def js_plain_key_chars(chars: List<&2, Char>) -> Bool:
  match chars:
    case Nil{}: False{}
    case +head <> rest: js_plain_key_head(js_plain_head(head), rest)
def js_plain_key_head(head: Bool, rest: List<&2, Char>) -> Bool:
  match head:
    case True{}: js_plain_key_tail(rest)
    case False{}: False{}
def js_plain_key_tail(chars: List<&2, Char>) -> Bool:
  match chars:
    case Nil{}: True{}
    case +head <> rest: js_plain_key_tail_more(js_word(head), rest)
def js_plain_key_tail_more(word: Bool, rest: List<&2, Char>) -> Bool:
  match word:
    case True{}: js_plain_key_tail(rest)
    case False{}: False{}
def js_plain_head(+char: Char) -> Bool:
  match char:
    case '_': True{}
    case '$': True{}
    case _: Char.is_alpha(char)
# A projection of a numeric atom keeps the keyed spelling: `123.a` is not a
# JavaScript expression, and only a Word or Nat atom renders as bare digits.
def js_member_text(value: BIR.Atom, key: String) -> String:
  js_member_selected(js_member_atom(value), js_plain_key(key), key)
def js_member_atom(value: BIR.Atom) -> Bool:
  match value:
    case BIR.Word{_}: False{}
    case BIR.Natural{_}: False{}
    case _: True{}
def js_member_selected(referenced: Bool, plain: Bool, +key: String) -> String:
  match referenced:
    case False{}: cat(["[", js_quote(key), "]"])
    case True{}: js_member_plain(plain, key)
def js_member_plain(plain: Bool, +key: String) -> String:
  match plain:
    case True{}: String.append(".", key)
    case False{}: cat(["[", js_quote(key), "]"])
def record_fields(fields: List<&2, BIR.Field>) -> String:
  match fields:
    case Nil{}: ""
    case BIR.Field{_, key, _, value} <> rest:
      cat([",", js_field_text(key), atom(value), record_fields(rest)])
# A foreign definition is a request constructor. BIR application is unary, so
# the value is curried: one arrow per live parameter and then the continuation.
# The request names the effect the source registered; its continuation is the
# one the caller supplied. A Nat answer is checked as the host hands it back,
# which is where comp.ts puts nat_in, so an out-of-range number fails here.
def foreign_parameters(count: Nat, index: Nat) -> List<&2, String>:
  match count:
    case 0n: Nil{}
    case 1n+rest: cat(["$f", Nat.show(index)]) <> foreign_parameters(rest, (index + 1n : Nat))
def foreign_arrow(names: List<&2, String>, body: String) -> String:
  match names:
    case Nil{}: body
    case name <> rest: cat([name, "=>", foreign_arrow(rest, body)])
# What crosses to or from a host is one value model: a Nat comes in as a number
# that nat_in checks, and text is sanitized in both directions, so a host can
# never hand a lone surrogate in as a Char or a String.
def foreign_kont(checked: Bool, text: Bool, f32: Bool) -> String:
  match text:
    case True{}: "((x)=>$k(str_in(x)))"
    case False{}: foreign_kont_scalar(checked, f32)
def foreign_kont_scalar(checked: Bool, f32: Bool) -> String:
  match f32:
    case True{}: "((x)=>$k(Math.fround(x)))"
    case False{}: foreign_kont_nat(checked)
def foreign_kont_nat(checked: Bool) -> String:
  match checked:
    case True{}: "((x)=>$k(nat_in(x)))"
    case False{}: "$k"
def foreign_answer_kont(checked: Bool, answer: Maybe<&2, BIR.Descriptor>, +natives: Map<&2, String>) -> String:
  match answer:
    case Some{+value}: foreign_kont(checked, js_text_descriptor(value, natives), js_f32_descriptor(value, natives))
    case None{}: foreign_kont(checked, False{}, False{})
def foreign_request(+key: String, count: Nat, parameters: List<&2, BIR.Descriptor>, checked: Bool, result: BIR.Descriptor, +natives: Map<&2, String>) -> String:
  names = foreign_parameters(count, 0n)
  body = cat(["({$:", js_quote(key), ",args:[", String.join(foreign_arguments(names, parameters, natives), ","), "],kont:", foreign_answer_kont(checked, js_io_answer(result, natives), natives), "})"])
  cat(["$D[", js_quote(key), "]=", foreign_arrow(List.append(&2, String, names, ["$k"]), body), ";\n"])
# A Char or a String leaves Bend as text: a code that is no Unicode scalar is
# written U+FFFD at the seam, exactly where the host reads it. The answer is
# host text too, so the continuation reads it back the same way.
def foreign_arguments(names: List<&2, String>, parameters: List<&2, BIR.Descriptor>, +natives: Map<&2, String>) -> List<&2, String>:
  match names:
    case Nil{}: Nil{}
    case name <> rest:
      match parameters:
        case Nil{}: name <> foreign_arguments(rest, Nil{}, natives)
        case +item <> more: foreign_argument(js_text_descriptor(item, natives), name) <> foreign_arguments(rest, more, natives)
def foreign_argument(text: Bool, name: String) -> String:
  match text:
    case True{}: cat(["str_out(", name, ")"])
    case False{}: name
type JSDescriptorHead is Data:
  JSDescriptorHead{key: String, args: List<&2, BIR.Descriptor>}
def js_text_descriptor(value: BIR.Descriptor, +natives: Map<&2, String>) -> Bool:
  js_text_head(js_descriptor_head(value), natives)
def js_text_head(head: Maybe<&2, JSDescriptorHead>, +natives: Map<&2, String>) -> Bool:
  match head:
    case Some{JSDescriptorHead{key, _}}: Bool.or(js_native_is(natives, key, "Char"), js_native_is(natives, key, "String"))
    case None{}: False{}
def js_f32_descriptor(value: BIR.Descriptor, +natives: Map<&2, String>) -> Bool:
  js_f32_head(js_descriptor_head(value), natives)
def js_f32_head(head: Maybe<&2, JSDescriptorHead>, +natives: Map<&2, String>) -> Bool:
  match head:
    case Some{JSDescriptorHead{key, _}}: js_native_is(natives, key, "F32")
    case None{}: False{}

# The answer type of a foreign IO(A) is the continuation's domain A. The
# descriptor of the declared result is the only authoritative source: a named
# or unnamed application whose head is IO carries A as its argument.
def js_descriptor_head(value: BIR.Descriptor) -> Maybe<&2, JSDescriptorHead>:
  match value:
    case BIR.DescriptorRef{key, args}: Some{JSDescriptorHead{key, args}}
    case BIR.DescriptorConstructor{key, args}: Some{JSDescriptorHead{key, args}}
    case BIR.DescriptorNamedFill{key, _, args}: Some{JSDescriptorHead{key, args}}
    case BIR.DescriptorNamedPlus{key, _, args}: Some{JSDescriptorHead{key, args}}
    case BIR.DescriptorFill{head, args}: js_descriptor_head_fill(js_descriptor_head(head), args)
    case BIR.DescriptorPlus{head, args}: js_descriptor_head_fill(js_descriptor_head(head), args)
    case BIR.DescriptorApplication{fn, arg}: js_descriptor_head_applied(js_descriptor_head(fn), arg)
    case _: None{}
def js_descriptor_head_fill(head: Maybe<&2, JSDescriptorHead>, args: List<&2, BIR.Descriptor>) -> Maybe<&2, JSDescriptorHead>:
  match head:
    case Some{JSDescriptorHead{key, _}}: Some{JSDescriptorHead{key, args}}
    case None{}: None{}
def js_descriptor_head_applied(head: Maybe<&2, JSDescriptorHead>, arg: BIR.Descriptor) -> Maybe<&2, JSDescriptorHead>:
  match head:
    case Some{JSDescriptorHead{key, args}}: Some{JSDescriptorHead{key, List.append(&2, BIR.Descriptor, args, [arg])}}
    case None{}: None{}
def js_native_is(+natives: Map<&2, String>, key: String, name: String) -> Bool:
  js_native_is_found(IndexLookup.find(String, natives, key), name)
def js_native_is_found(found: Maybe<&2, String>, name: String) -> Bool:
  match found:
    case Some{value}: String.eq(value, name)
    case None{}: False{}
def js_io_answer(value: BIR.Descriptor, +natives: Map<&2, String>) -> Maybe<&2, BIR.Descriptor>:
  js_io_answer_head(js_descriptor_head(value), natives)
def js_io_answer_head(head: Maybe<&2, JSDescriptorHead>, +natives: Map<&2, String>) -> Maybe<&2, BIR.Descriptor>:
  match head:
    case Some{JSDescriptorHead{key, args}}: js_io_answer_named(js_native_is(natives, key, "IO"), args)
    case None{}: None{}
def js_io_answer_named(io: Bool, args: List<&2, BIR.Descriptor>) -> Maybe<&2, BIR.Descriptor>:
  match io:
    case True{}: js_first_descriptor(args)
    case False{}: None{}
def js_first_descriptor(items: List<&2, BIR.Descriptor>) -> Maybe<&2, BIR.Descriptor>:
  match items:
    case Nil{}: None{}
    case +item <> _: Some{item}
def js_nat_descriptor(value: BIR.Descriptor, +natives: Map<&2, String>) -> Bool:
  js_nat_descriptor_head(js_descriptor_head(value), natives)
def js_nat_descriptor_head(head: Maybe<&2, JSDescriptorHead>, +natives: Map<&2, String>) -> Bool:
  match head:
    case Some{JSDescriptorHead{key, args}}: js_nat_descriptor_named(js_native_is(natives, key, "Nat"), args)
    case None{}: False{}
def js_nat_descriptor_named(nat: Bool, args: List<&2, BIR.Descriptor>) -> Bool:
  match nat:
    case True{}: Nat.is_eq(List.length(&2, BIR.Descriptor, args), 0n)
    case False{}: False{}
def js_bool_of_parameter(value: JSParameter) -> Bool:
  match value:
    case JSParameterNat{}: True{}
    case _: False{}
def js_nat_answer(value: BIR.Descriptor, +natives: Map<&2, String>) -> Bool:
  js_nat_answer_io(js_io_answer(value, natives), natives)
def js_nat_answer_io(answer: Maybe<&2, BIR.Descriptor>, +natives: Map<&2, String>) -> Bool:
  match answer:
    case Some{item}: js_nat_descriptor(item, natives)
    case None{}: False{}
def operation(op: BIR.Op, ctx: JsCtx) -> String:
  match op:
    case BIR.Copy{value}: atom(value)
    case BIR.PrimitiveCall{primitive, args, _}: cat([primitive_name(primitive), "(", String.join(arguments(args), ","), ")"])
    case BIR.Closure{code, captures, parameters}: multi_closure(ctx, code, captures, parameters)
    # A strict call is never an inline operation: let_step gives Direct and
    # Apply the private-frame split, and the machine resumes their
    # continuation. These two arms keep the renderer total.
    case BIR.Direct{code, args}: cat(["run_loop(", multi_target_name(js_ctx_targets(ctx), code), "(", String.join(arguments(args), ","), "))"])
    case BIR.Apply{fn, BIR.Arg{_, value}}: cat(["run_loop(run_tail(", atom(fn), ",", atom(value), "))"])
    case BIR.LoadSymbol{_, key}: cat(["$D[", js_quote(key), "]"])
    case BIR.Construct{_, tag, fields}: cat(["({$:", js_quote(tag), record_fields(fields), "})"])
    case BIR.Project{value, _, _, key}: cat([atom(value), js_member_text(value, key)])
    case BIR.HasTag{value, _, tag}: tag_test(atom(value), tag)
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
def tag_group_selected(selected: Bool, subject: BIR.Atom, arm: TaggedRegion, input: BIR.Block, ctx: JsCtx, arms: List<&2, TagArm>, seen: Map<&2, Bool>, count: Nat) -> TagGroup:
  match selected:
    case False{}: TagGroup{arms, input, count}
    case True{}:
      match arm:
        case TaggedRegion{label, condition, _, +tag, body, rest}:
          tag_group_arm(js_ctx_frame(ctx, label), subject, rest, ctx, TagArm{label, condition, tag, body} <> arms, Map.set(&2, Bool, seen, tag, True{}), count)
# A frame-form region owns its leaves on the private stack, so it cannot join a
# switch arm: the arm body is not the place its `next` block is reached from.
def tag_group_arm(framed: Bool, subject: BIR.Atom, rest: BIR.Block, ctx: JsCtx, arms: List<&2, TagArm>, seen: Map<&2, Bool>, count: Nat) -> TagGroup:
  match framed:
    case True{}: TagGroup{arms, rest, count}
    case False{}: tag_group(subject, rest, ctx, arms, seen, Nat.add(count, 1n))
def tag_group_view(view: Maybe<&2, TaggedRegion>, +subject: BIR.Atom, input: BIR.Block, ctx: JsCtx, arms: List<&2, TagArm>, +seen: Map<&2, Bool>, count: Nat) -> TagGroup:
  match view:
    case None{}: TagGroup{arms, input, count}
    case Some{+arm}:
      match arm:
        case TaggedRegion{_, _, candidate, +tag, _, _}:
          tag_group_selected(Bool.and(tag_subject_same(subject, candidate), tag_unseen(IndexLookup.find(Bool, seen, tag))), subject, arm, input, ctx, arms, seen, count)
def tag_group(subject: BIR.Atom, +input: BIR.Block, ctx: JsCtx, arms: List<&2, TagArm>, seen: Map<&2, Bool>, count: Nat) -> TagGroup:
  tag_group_view(tagged_region(input), subject, input, ctx, arms, seen, count)
def tag_arms(arms: List<&2, TagArm>, ctx: JsCtx) -> String:
  match arms:
    case Nil{}: ""
    case TagArm{label, condition, tag, body} <> rest:
      cat(["case ", js_quote(tag), ":{$case", U32.show(label), ":{const ", local(condition), "=true;", block(body, ctx), "}break;}", tag_arms(rest, ctx)])
def ordinary_region(label: U32, body: BIR.Block, next: BIR.Block, ctx: JsCtx) -> String:
  cat(["$case", U32.show(label), ":{", block(body, ctx), "}", block(next, ctx)])
def tag_render_selected(selected: Bool, subject: BIR.Atom, arms: List<&2, TagArm>, rest: BIR.Block, label: U32, body: BIR.Block, next: BIR.Block, ctx: JsCtx) -> String:
  match selected:
    case False{}: ordinary_region(label, body, next, ctx)
    case True{}: cat(["switch(", atom(subject), "?.$){", tag_arms(List.reverse(&2, TagArm, arms), ctx), "}", block(rest, ctx)])
def tag_render_group(group: TagGroup, subject: BIR.Atom, label: U32, body: BIR.Block, next: BIR.Block, ctx: JsCtx) -> String:
  match group:
    case TagGroup{arms, rest, +count}: tag_render_selected(Nat.is_gt(count, 2n), subject, arms, rest, label, body, next, ctx)
def region_view(view: Maybe<&2, TaggedRegion>, label: U32, body: BIR.Block, next: BIR.Block, ctx: JsCtx) -> String:
  match view:
    case None{}: ordinary_region(label, body, next, ctx)
    case Some{arm}:
      match arm:
        case TaggedRegion{case_label, condition, +subject, +tag, case_body, rest}:
          tag_render_group(tag_group(subject, rest, ctx, [TagArm{case_label, condition, tag, case_body}], Map.set(&2, Bool, Map.new(&2, Bool), tag, True{}), 1n), subject, label, body, next, ctx)
def region(+label: U32, +body: BIR.Block, +next: BIR.Block, ctx: JsCtx) -> String:
  match js_ctx_frame(ctx, label):
    case True{}: region_frame(label, body, next, ctx)
    case False{}: region_view(tagged_region(BIR.Region{label, body, next}), label, body, next, ctx)
def block(body: BIR.Block, ctx: JsCtx) -> String:
  match body:
    case BIR.Return{value}: return_step(value, ctx)
    case BIR.Let{id, op, next}: let_step(id, op, next, ctx)
    case BIR.Branch{condition, yes, no}: cat(["if(", atom(condition), "){", block(yes, ctx), "}else{", block(no, ctx), "}"])
    case BIR.Region{label, body, next}: region(label, body, next, ctx)
    case BIR.LeaveRegion{label}: leave_step(label, ctx)
    case BIR.TailDirect{code, args}: tail_step(code, args, ctx)
    case BIR.TailApply{fn, BIR.Arg{_, value}}: cat(["return run_tail(", atom(fn), ",", atom(value), ");"])
    case BIR.Failure{message}: cat(["throw ", js_quote(message), ";"])
# One plan for the whole program: the layouts, the one result width, the fixed
# point over codes and parameter positions, and the two rewritten bodies of every
# transformed code. Any rewrite that cannot be proven sets `ok` false, and the
# target then emits exactly the source it emitted before.
def multi_codes_facts(items: List<&2, BIR.Code>, layouts: Map<&2, MultiLayout>, width: Nat, acc: Map<&2, MultiCodeFact>) -> Map<&2, MultiCodeFact>:
  match items:
    case Nil{}: acc
    case code <> rest: multi_codes_fact_one(code, rest, layouts, width, acc)
def multi_codes_fact_one(code: BIR.Code, rest: List<&2, BIR.Code>, layouts: Map<&2, MultiLayout>, width: Nat, acc: Map<&2, MultiCodeFact>) -> Map<&2, MultiCodeFact>:
  match code:
    case BIR.Code{id, captures, parameters, body}:
      multi_codes_facts(rest, layouts, width, Map.set(&2, MultiCodeFact, acc, U32.show(id), multi_code_fact_build(id, captures, parameters, body, layouts, width)))
def multi_sites_map(items: List<&2, BIR.Code>, facts: Map<&2, MultiCodeFact>, acc: Map<&2, List<&2, MultiSiteF>>) -> Map<&2, List<&2, MultiSiteF>>:
  match items:
    case Nil{}: acc
    case BIR.Code{id, _, _, _} <> rest:
      multi_sites_map(rest, facts, Map.set(&2, List<&2, MultiSiteF>, acc, U32.show(id), multi_fact_sites(multi_fact_of(facts, id))))
def multi_fact_sites(fact: MultiCodeFact) -> List<&2, MultiSiteF>:
  match fact:
    case MultiCodeFact{_, sites, _, _, _, _, _, _}: sites
def multi_params_boxed(items: List<&2, BIR.Parameter>, acc: List<&2, MultiParam>) -> List<&2, MultiParam>:
  match items:
    case Nil{}: List.reverse(&2, MultiParam, acc)
    case BIR.Parameter{id, _} <> rest: multi_params_boxed(rest, MultiParam{id, False{}, 0, Nil{}} <> acc)
def multi_params_unboxed(items: List<&2, BIR.Parameter>, index: Nat, up: Map<&2, Bool>, code: U32, width: Nat, acc: List<&2, MultiParam>) -> List<&2, MultiParam>:
  match items:
    case Nil{}: List.reverse(&2, MultiParam, acc)
    case BIR.Parameter{id, _} <> rest:
      multi_params_unboxed(rest, (index + 1n : Nat), up, code, width, multi_param_one(multi_up_get(up, code, index), id, width) <> acc)
def multi_param_one(unboxed: Bool, id: U32, width: Nat) -> MultiParam:
  match unboxed:
    case True{}: MultiParam{id, True{}, multi_fresh(id, 7n), multi_fresh_ids(id, width)}
    case False{}: MultiParam{id, False{}, 0, Nil{}}
def multi_params_find(items: List<&2, MultiParam>, id: U32) -> MultiParam:
  match items:
    case Nil{}: MultiParam{id, False{}, 0, Nil{}}
    case MultiParam{known, unboxed, tag, fields} <> rest: multi_params_pick(U32.is_eq(known, id), MultiParam{known, unboxed, tag, fields}, rest, id)
def multi_params_pick(same: Bool, item: MultiParam, rest: List<&2, MultiParam>, id: U32) -> MultiParam:
  match same:
    case True{}: item
    case False{}: multi_params_find(rest, id)
def multi_params_map(items: List<&2, MultiParam>, acc: Map<&2, MultiParam>) -> Map<&2, MultiParam>:
  match items:
    case Nil{}: acc
    case MultiParam{id, _, _, _} <> rest: multi_params_map(rest, Map.set(&2, MultiParam, acc, U32.show(id), multi_params_find(items, id)))
def multi_param_names(items: List<&2, MultiParam>) -> List<&2, String>:
  match items:
    case Nil{}: Nil{}
    case MultiParam{id, unboxed, tag, fields} <> rest: multi_param_name(id, unboxed, tag, fields) <> multi_param_names(rest)
def multi_param_name(id: U32, unboxed: Bool, tag: U32, fields: List<&2, U32>) -> List<&2, String>:
  match unboxed:
    case False{}: [local(id)]
    case True{}: local(tag) <> multi_local_names(fields)
def multi_local_names(items: List<&2, U32>) -> List<&2, String>:
  match items:
    case Nil{}: Nil{}
    case +item <> rest: local(item) <> multi_local_names(rest)
def multi_render_plain(body: BIR.Block, parameters: List<&2, BIR.Parameter>) -> MultiRender:
  multi_render_plain_made(js_scalar(body), parameters)
def multi_render_plain_made(scoped: BIR.Block, parameters: List<&2, BIR.Parameter>) -> MultiRender:
  MultiRender{scoped, plan_of(scoped), multi_params_boxed(parameters, Nil{}), Map.new(&2, MultiWindow), Map.new(&2, Bool), Map.new(&2, Bool), False{}, False{}, 0n, False{}}
def multi_render_code(code: BIR.Code, layouts: Map<&2, MultiLayout>, width: Nat, state: MultiUp, acc: Map<&2, MultiRender>) -> Map<&2, MultiRender>:
  match code:
    case BIR.Code{id, _, parameters, body}: multi_render_pair(multi_multi_get(multi_prev_multi(state), id), id, parameters, body, layouts, width, state, acc)
def multi_render_pair(multi: Bool, id: U32, parameters: List<&2, BIR.Parameter>, body: BIR.Block, layouts: Map<&2, MultiLayout>, width: Nat, state: MultiUp, acc: Map<&2, MultiRender>) -> Map<&2, MultiRender>:
  match multi:
    case False{}: Map.set(&2, MultiRender, acc, multi_render_key(id, False{}), multi_render_primary(id, parameters, body, layouts, width, state, False{}))
    case True{}: multi_render_two(id, parameters, body, layouts, width, state, acc)
def multi_render_two(id: U32, parameters: List<&2, BIR.Parameter>, body: BIR.Block, layouts: Map<&2, MultiLayout>, width: Nat, state: MultiUp, acc: Map<&2, MultiRender>) -> Map<&2, MultiRender>:
  Map.set(&2, MultiRender, Map.set(&2, MultiRender, acc, multi_render_key(id, False{}), multi_render_primary(id, parameters, body, layouts, width, state, True{})), multi_render_key(id, True{}), multi_render_public(id, parameters, body, layouts, width, state))
def multi_render_primary(id: U32, parameters: List<&2, BIR.Parameter>, body: BIR.Block, layouts: Map<&2, MultiLayout>, width: Nat, state: MultiUp, private: Bool) -> MultiRender:
  multi_render_make(id, body, layouts, width, state, private, False{}, multi_render_params(private, parameters, multi_prev_up(state), id, width))
# Only a selected multi code may take tag plus words: a code that failed the
# result or arity proof keeps boxed parameters even where its own uses could be
# projected, because its callers route the boxed entry and no public duplicate
# exists for it.
def multi_render_params(private: Bool, parameters: List<&2, BIR.Parameter>, up: Map<&2, Bool>, id: U32, width: Nat) -> List<&2, MultiParam>:
  match private:
    case True{}: multi_params_unboxed(parameters, 0n, up, id, width, Nil{})
    case False{}: multi_params_boxed(parameters, Nil{})
def multi_render_public(id: U32, parameters: List<&2, BIR.Parameter>, body: BIR.Block, layouts: Map<&2, MultiLayout>, width: Nat, state: MultiUp) -> MultiRender:
  multi_render_make(id, body, layouts, width, state, False{}, True{}, multi_params_boxed(parameters, Nil{}))
def multi_render_make(id: U32, body: BIR.Block, layouts: Map<&2, MultiLayout>, width: Nat, state: MultiUp, private: Bool, public: Bool, params: List<&2, MultiParam>) -> MultiRender:
  multi_render_done(multi_rewrite(body, MRewCtx{id, layouts, multi_prev_multi(state), multi_prev_up(state), width, multi_params_map(params, Map.new(&2, MultiParam)), private, None{}, None{}, Map.new(&2, MultiCtor), multi_uses(body)}, multi_seed_of(id)), private, public, params, width)
# A synthetic conversion names a hoisted continuation, so its id must be unique
# over the whole program, not over one rendering: the owner contributes a block
# of 64 names and the traversal consumes two per conversion. Site and parameter
# names come from the disjoint 0x60000000 range, so the three spaces cannot meet.
def multi_seed_of(id: U32) -> Nat:
  Nat.mul(U32.to_nat(id), 64n)
def multi_render_done(rw: MultiRew, private: Bool, public: Bool, params: List<&2, MultiParam>, width: Nat) -> MultiRender:
  match rw:
    case MultiRew{body, windows, sites, mr, _, failed, _, _}:
      multi_render_final(body, windows, sites, mr, Bool.or(failed, multi_render_frames(private, body)), private, public, params, width)
def multi_render_frames(private: Bool, body: BIR.Block) -> Bool:
  match private:
    case True{}: Bool.not(multi_frames_ok(body, plan_of(body)))
    case False{}: False{}
def multi_render_final(body: BIR.Block, windows: Map<&2, MultiWindow>, sites: Map<&2, Bool>, mr: Map<&2, Bool>, failed: Bool, private: Bool, public: Bool, params: List<&2, MultiParam>, width: Nat) -> MultiRender:
  MultiRender{body, plan_of(body), params, windows, sites, mr, private, public, width, failed}
def multi_render_key(id: U32, public: Bool) -> String:
  multi_render_key_pick(public, id)
def multi_render_key_pick(public: Bool, id: U32) -> String:
  match public:
    case True{}: cat(["u", U32.show(id)])
    case False{}: cat(["r", U32.show(id)])
def multi_renders(items: List<&2, BIR.Code>, layouts: Map<&2, MultiLayout>, width: Nat, state: MultiUp, acc: Map<&2, MultiRender>) -> Map<&2, MultiRender>:
  match items:
    case Nil{}: acc
    case code <> rest: multi_renders(rest, layouts, width, state, multi_render_code(code, layouts, width, state, acc))
def multi_render_failed(found: Maybe<&2, MultiRender>) -> Bool:
  match found:
    case Some{MultiRender{_, _, _, _, _, _, _, _, _, failed}}: failed
    case None{}: False{}
def multi_render_of_key(renders: Map<&2, MultiRender>, +key: String) -> Maybe<&2, MultiRender>:
  IndexLookup.find(MultiRender, renders, key)
def multi_renders_failed(items: List<&2, BIR.Code>, renders: Map<&2, MultiRender>, acc: Bool) -> Bool:
  match items:
    case Nil{}: acc
    case BIR.Code{id, _, _, _} <> rest: multi_renders_failed(rest, renders, Bool.or(acc, multi_render_failed(multi_render_of_key(renders, multi_render_key(id, False{})))))
def multi_plan(program: BIR.Program) -> MultiPlan:
  match program:
    case BIR.Program{codes, _, constructors, _, _, _}: multi_plan_build(codes, constructors)
def multi_plan_build(codes: List<&2, BIR.Code>, constructors: List<&2, BIR.ConstructorLayout>) -> MultiPlan:
  multi_plan_width(codes, multi_layouts(constructors, Map.new(&2, MultiLayout)))
def multi_plan_width(codes: List<&2, BIR.Code>, layouts: Map<&2, MultiLayout>) -> MultiPlan:
  multi_plan_state(codes, layouts, multi_program_width(codes, 0n))
def multi_plan_state(codes: List<&2, BIR.Code>, layouts: Map<&2, MultiLayout>, width: Nat) -> MultiPlan:
  multi_plan_facts(codes, layouts, width, multi_codes_facts(codes, layouts, width, Map.new(&2, MultiCodeFact)))
def multi_plan_facts(codes: List<&2, BIR.Code>, layouts: Map<&2, MultiLayout>, width: Nat, facts: Map<&2, MultiCodeFact>) -> MultiPlan:
  multi_plan_final(codes, layouts, width, facts, multi_fwd_index(codes, multi_sites_map(codes, facts, Map.new(&2, List<&2, MultiSiteF>)), Map.new(&2, List<&2, MultiFwd>)))
def multi_plan_final(codes: List<&2, BIR.Code>, layouts: Map<&2, MultiLayout>, width: Nat, facts: Map<&2, MultiCodeFact>, fwds: Map<&2, List<&2, MultiFwd>>) -> MultiPlan:
  multi_plan_made(codes, layouts, width, multi_round_start(codes, facts, fwds, Map.new(&2, Bool), layouts, width))
def multi_plan_made(codes: List<&2, BIR.Code>, layouts: Map<&2, MultiLayout>, width: Nat, state: MultiUp) -> MultiPlan:
  multi_plan_join(codes, layouts, width, state, multi_renders(codes, layouts, width, state, Map.new(&2, MultiRender)))
def multi_plan_join(codes: List<&2, BIR.Code>, layouts: Map<&2, MultiLayout>, width: Nat, state: MultiUp, renders: Map<&2, MultiRender>) -> MultiPlan:
  multi_plan_ok_join(Bool.not(multi_renders_failed(codes, renders, False{})), layouts, width, multi_prev_multi(state), renders)
def multi_plan_ok_join(ok: Bool, layouts: Map<&2, MultiLayout>, width: Nat, multi: Map<&2, Bool>, renders: Map<&2, MultiRender>) -> MultiPlan:
  MultiPlan{multi_plan_targets(ok, multi), layouts, renders, width, ok}
def multi_plan_targets(ok: Bool, multi: Map<&2, Bool>) -> Map<&2, Bool>:
  match ok:
    case True{}: multi
    case False{}: Map.new(&2, Bool)
def multi_render_choose(plan: MultiPlan, code: BIR.Code, public: Bool) -> MultiRender:
  match plan:
    case MultiPlan{_, _, renders, _, ok}: multi_render_lookup(ok, renders, code, public)
def multi_render_lookup(ok: Bool, renders: Map<&2, MultiRender>, code: BIR.Code, public: Bool) -> MultiRender:
  match code:
    case BIR.Code{id, _, parameters, body}: multi_render_lookup_ok(ok, multi_render_of_key(renders, multi_render_key(id, public)), parameters, body)
def multi_render_lookup_ok(ok: Bool, found: Maybe<&2, MultiRender>, parameters: List<&2, BIR.Parameter>, body: BIR.Block) -> MultiRender:
  match ok:
    case False{}: multi_render_plain(body, parameters)
    case True{}: multi_render_found(found, body, parameters)
def multi_render_found(found: Maybe<&2, MultiRender>, body: BIR.Block, parameters: List<&2, BIR.Parameter>) -> MultiRender:
  match found:
    case Some{+item}: item
    case None{}: multi_render_plain(body, parameters)
def multi_render_primary_of(plan: MultiPlan, code: BIR.Code) -> MultiRender:
  multi_render_choose(plan, code, False{})
def multi_render_public_of(plan: MultiPlan, code: BIR.Code) -> MultiRender:
  multi_render_choose(plan, code, True{})

def multi_plan_multi(plan: MultiPlan) -> Map<&2, Bool>:
  match plan:
    case MultiPlan{multi, _, _, _, _}: multi
def multi_plan_ok(plan: MultiPlan) -> Bool:
  match plan:
    case MultiPlan{_, _, _, _, ok}: ok
def multi_code_name(id: U32, public: Bool) -> String:
  match public:
    case True{}: code_name_pub(id)
    case False{}: code_name(id)
def multi_owner(id: U32, public: Bool) -> String:
  match public:
    case True{}: cat([U32.show(id), "P"])
    case False{}: U32.show(id)
def multi_render_plan(render: MultiRender) -> Plan:
  match render:
    case MultiRender{_, plan, _, _, _, _, _, _, _, _}: plan
def multi_render_body(render: MultiRender) -> BIR.Block:
  match render:
    case MultiRender{body, _, _, _, _, _, _, _, _, _}: body
def multi_render_params(render: MultiRender) -> List<&2, MultiParam>:
  match render:
    case MultiRender{_, _, params, _, _, _, _, _, _, _}: params
def multi_render_private(render: MultiRender) -> Bool:
  match render:
    case MultiRender{_, _, _, _, _, _, private, _, _, _}: private
def multi_signature(captures: List<&2, BIR.Use>, render: MultiRender) -> List<&2, String>:
  multi_sig_names(multi_render_private(render), List.append(&2, String, capture_names(captures, 0), multi_param_names(multi_render_params(render))))
def multi_sig_names(private: Bool, names: List<&2, String>) -> List<&2, String>:
  match private:
    case True{}: List.append(&2, String, names, ["$mr", "$td=0"])
    case False{}: List.append(&2, String, names, ["$td=0"])
def multi_code_emit(id: U32, captures: List<&2, BIR.Use>, render: MultiRender, plan: MultiPlan, public: Bool) -> String:
  multi_code_emit_ctx(js_ctx_multi(multi_owner(id, public), multi_render_plan(render), multi_plan_multi(plan), render), id, captures, render, public)
def multi_code_emit_ctx(ctx: JsCtx, id: U32, captures: List<&2, BIR.Use>, render: MultiRender, public: Bool) -> String:
  cat(["function ", multi_code_name(id, public), "(", String.join(multi_signature(captures, render), ","), "){", block(multi_render_body(render), ctx), "}\n", String.join(conts(multi_render_body(render), ctx), "")])
def code(item: BIR.Code, plan: MultiPlan) -> String:
  match item:
    case BIR.Code{id, captures, _, _}: multi_code_emit(id, captures, multi_render_primary_of(plan, item), plan, False{})
def codes(items: List<&2, BIR.Code>, plan: MultiPlan) -> String:
  match items:
    case Nil{}: ""
    case item <> rest: cat([code(item, plan), multi_public_code(item, plan), codes(rest, plan)])
def multi_public_code(item: BIR.Code, plan: MultiPlan) -> String:
  match item:
    case BIR.Code{id, captures, _, _}: multi_public_pick(multi_multi_get(multi_plan_multi(plan), id), multi_plan_ok(plan), id, captures, item, plan)
def multi_public_pick(multi: Bool, ok: Bool, id: U32, captures: List<&2, BIR.Use>, item: BIR.Code, plan: MultiPlan) -> String:
  match multi:
    case False{}: ""
    case True{}: multi_public_ok(ok, id, captures, item, plan)
def multi_public_ok(ok: Bool, id: U32, captures: List<&2, BIR.Use>, item: BIR.Code, plan: MultiPlan) -> String:
  match ok:
    case False{}: ""
    case True{}: multi_code_emit(id, captures, multi_render_public_of(plan, item), plan, True{})

# A rendered block belongs to one owner, a code body or a lazy declaration
# body, and sees the frame-form regions around it. `frames` names exactly the
# regions whose `next` block the private frame stack owns, so a leave there
# renders as a frame unwind instead of a JavaScript break. A call continuation
# is named after the call's own local id, which WF-2 makes program-unique.
# `plan` is that one body's capture plan: the split emission and the hoisted
# declaration of the same continuation read one entry, and the plan dies with
# the body that built it.
type JsCtx is Data:
  JsCtx{owner: String, plan: Plan, frames: List<&2, U32>, multi: Map<&2, Bool>, render: MultiRender}
def js_ctx(owner: String, plan: Plan) -> JsCtx:
  JsCtx{owner, plan, Nil{}, Map.new(&2, Bool), multi_render_plain_state(plan)}
def js_ctx_multi(owner: String, plan: Plan, multi: Map<&2, Bool>, render: MultiRender) -> JsCtx:
  JsCtx{owner, plan, Nil{}, multi, render}
def multi_render_plain_state(plan: Plan) -> MultiRender:
  MultiRender{BIR.Failure{""}, plan, Nil{}, Map.new(&2, MultiWindow), Map.new(&2, Bool), Map.new(&2, Bool), False{}, False{}, 0n, False{}}
def js_ctx_inside(ctx: JsCtx, label: U32) -> JsCtx:
  match ctx:
    case JsCtx{owner, plan, frames, multi, render}: JsCtx{owner, plan, label <> frames, multi, render}
def js_ctx_owner(ctx: JsCtx) -> String:
  match ctx:
    case JsCtx{owner, _, _, _, _}: owner
def js_ctx_has(ctx: JsCtx, label: U32) -> Bool:
  match ctx:
    case JsCtx{_, _, frames, _, _}: frame_has(frames, label)
def js_ctx_cont(ctx: JsCtx, id: U32) -> Caps:
  match ctx:
    case JsCtx{_, plan, _, _, _}: plan_cont(plan, id)
def js_ctx_thunk(ctx: JsCtx, label: U32) -> Caps:
  match ctx:
    case JsCtx{_, plan, _, _, _}: plan_thunk(plan, label)
def js_ctx_frame(ctx: JsCtx, label: U32) -> Bool:
  match ctx:
    case JsCtx{_, plan, _, _, _}: plan_frame(plan, label)
def js_ctx_targets(ctx: JsCtx) -> Map<&2, Bool>:
  match ctx:
    case JsCtx{_, _, _, multi, _}: multi
def js_ctx_render(ctx: JsCtx) -> MultiRender:
  match ctx:
    case JsCtx{_, _, _, _, render}: render
def js_ctx_private(ctx: JsCtx) -> Bool:
  match js_ctx_render(ctx):
    case MultiRender{_, _, _, _, _, _, private, _, _, _}: private
def js_ctx_public(ctx: JsCtx) -> Bool:
  match js_ctx_render(ctx):
    case MultiRender{_, _, _, _, _, _, _, public, _, _}: public
def js_ctx_width(ctx: JsCtx) -> Nat:
  match js_ctx_render(ctx):
    case MultiRender{_, _, _, _, _, _, _, _, width, _}: width
def js_ctx_params(ctx: JsCtx) -> List<&2, MultiParam>:
  match js_ctx_render(ctx):
    case MultiRender{_, _, params, _, _, _, _, _, _, _}: params
def js_ctx_param(ctx: JsCtx, id: U32) -> Maybe<&2, MultiParam>:
  multi_param_get(multi_params_map(js_ctx_params(ctx), Map.new(&2, MultiParam)), id)
def js_ctx_site(ctx: JsCtx, id: U32) -> Bool:
  match js_ctx_render(ctx):
    case MultiRender{_, _, _, _, sites, _, _, _, _, _}: multi_site_get(sites, id)
def multi_site_get(sites: Map<&2, Bool>, id: U32) -> Bool:
  multi_up_found(IndexLookup.find(Bool, sites, cat(["k", U32.show(id)])))
def js_ctx_window(ctx: JsCtx, id: U32) -> Maybe<&2, MultiWindow>:
  match js_ctx_render(ctx):
    case MultiRender{_, _, _, windows, _, _, _, _, _, _}: IndexLookup.find(MultiWindow, windows, cat(["k", U32.show(id)]))
def js_ctx_mr(ctx: JsCtx, id: U32) -> Bool:
  match js_ctx_render(ctx):
    case MultiRender{_, _, _, _, _, mr, _, _, _, _}: multi_up_found(IndexLookup.find(Bool, mr, cat(["k", U32.show(id)])))
def cont_name_ctx(ctx: JsCtx, id: U32) -> String:
  match js_ctx_public(ctx):
    case True{}: cat(["$kp", U32.show(id)])
    case False{}: cont_name(id)
def code_name_pub(id: U32) -> String:
  cat(["$b", U32.show(id), "_pub"])
def multi_target_name(multi: Map<&2, Bool>, code: U32) -> String:
  multi_target_pick(multi_multi_get(multi, code), code)
def multi_target_pick(known: Bool, code: U32) -> String:
  match known:
    case True{}: code_name_pub(code)
    case False{}: code_name(code)
def frame_has(frames: List<&2, U32>, label: U32) -> Bool:
  match frames:
    case Nil{}: False{}
    case +item <> rest: frame_has_one(U32.is_eq(item, label), rest, label)
def frame_has_one(same: Bool, rest: List<&2, U32>, label: U32) -> Bool:
  match same:
    case True{}: True{}
    case False{}: frame_has(rest, label)
def cont_name(id: U32) -> String:
  cat(["$k", U32.show(id)])
def thunk_name(owner: String, label: U32) -> String:
  cat(["$r", owner, "_", U32.show(label)])

# One plan per immutable body, decided from the tail up. A suffix records the
# values it reads at its last traversal position, the whole read set, and the
# locals it binds, so a preceding op extends it without rescanning the block it
# precedes. The split emission and the hoisted continuation/thunk declaration
# therefore read one entry, and a long split chain is analyzed once instead of
# once per referring site.
#
# Region frame facts are decided in the same pass. A region's leaves stay inside
# one JavaScript function unless a non-tail call splits the block; the region
# owns a private frame exactly then, and every leave of a frame-form region
# unwinds the private stack, so a region with a frame is always correct. `after`
# is a leave of that label a split already preceded, `reach` is any reachable
# leave of it, and a subtree's answer for an incoming split flag is
# Bool.or(after, Bool.and(split, reach)).
type Caps is Data:
  Caps{locals: List<&2, U32>, slots: List<&2, U32>}
type Suffix is Data:
  Suffix{locals: List<&2, U32>, slots: List<&2, U32>, read_local: Map<&2, Bool>, read_slot: Map<&2, Bool>, bound: Map<&2, Bool>}
type Held is Data:
  Held{items: List<&2, U32>, read: Map<&2, Bool>}
type FrameBits is Data:
  FrameBits{label: U32, after: Bool, reach: Bool}
type Plan is Data:
  Plan{conts: Map<&2, Caps>, thunks: Map<&2, Caps>, frames: Map<&2, Bool>}
type Step is Data:
  Step{state: Suffix, facts: List<&2, FrameBits>, plan: Plan}
def split_op(op: BIR.Op) -> Bool:
  match op:
    case BIR.Direct{_, _}: True{}
    case BIR.Apply{_, _}: True{}
    case _: False{}

# Every value a block reads, in reverse traversal order with duplicates kept.
# A continuation body is a function of its own, so a read outside it is a value
# the creating frame owns: WF-2 makes that a local bound before the split or a
# capture slot of the code, and nothing else.
type Reads is Data:
  Reads{locals: List<&2, U32>, slots: List<&2, U32>}
def reads_new() -> Reads:
  Reads{Nil{}, Nil{}}
def reads_local(id: U32, reads: Reads) -> Reads:
  match reads:
    case Reads{locals, slots}: Reads{id <> locals, slots}
def reads_slot(slot: U32, reads: Reads) -> Reads:
  match reads:
    case Reads{locals, slots}: Reads{locals, slot <> slots}
def atom_reads(value: BIR.Atom, reads: Reads) -> Reads:
  match value:
    case BIR.Local{id}: reads_local(id, reads)
    case BIR.Capture{slot}: reads_slot(slot, reads)
    case _: reads
def arg_reads(arg: BIR.Arg, reads: Reads) -> Reads:
  match arg:
    case BIR.Arg{_, value}: atom_reads(value, reads)
def args_reads(args: List<&2, BIR.Arg>, reads: Reads) -> Reads:
  match args:
    case Nil{}: reads
    case +item <> rest: args_reads(rest, arg_reads(item, reads))
def apply_reads(fn: BIR.Atom, arg: BIR.Arg, reads: Reads) -> Reads:
  arg_reads(arg, atom_reads(fn, reads))
def field_reads(field: BIR.Field, reads: Reads) -> Reads:
  match field:
    case BIR.Field{_, _, _, value}: atom_reads(value, reads)
def fields_reads(fields: List<&2, BIR.Field>, reads: Reads) -> Reads:
  match fields:
    case Nil{}: reads
    case +item <> rest: fields_reads(rest, field_reads(item, reads))
def op_reads(op: BIR.Op, reads: Reads) -> Reads:
  match op:
    case BIR.Copy{value}: atom_reads(value, reads)
    case BIR.PrimitiveCall{_, args, _}: args_reads(args, reads)
    case BIR.Closure{_, captures, _}: args_reads(captures, reads)
    case BIR.Direct{_, args}: args_reads(args, reads)
    case BIR.Apply{fn, arg}: apply_reads(fn, arg, reads)
    case BIR.Construct{_, _, fields}: fields_reads(fields, reads)
    case BIR.Project{value, _, _, _}: atom_reads(value, reads)
    case BIR.HasTag{value, _, _}: atom_reads(value, reads)
    case _: reads

# A suffix is the state of the block that follows a site: each value once, at
# its last traversal position, the whole read set, and the locals it binds.
# Reads arrive in reverse traversal order, so the first appearance there is that
# last position: folding a site's own reads onto the suffix of the block after
# it costs one step per read and never rescans that block.
def suffix_empty() -> Suffix:
  Suffix{Nil{}, Nil{}, Map.new(&2, Bool), Map.new(&2, Bool), Map.new(&2, Bool)}
def suffix_fold(items: List<&2, U32>, held: Held) -> Held:
  match items:
    case Nil{}: held
    case +item <> rest:
      match held:
        case Held{acc, read}: suffix_fold_one(item, rest, acc, read)
def suffix_fold_one(item: U32, rest: List<&2, U32>, +acc: List<&2, U32>, read: Map<&2, Bool>) -> Held:
  +key = U32.show(item)
  match IndexLookup.find(Bool, read, key):
    case Some{_}: suffix_fold(rest, Held{acc, read})
    case None{}: suffix_fold(rest, Held{item <> acc, Map.set(&2, Bool, read, key, True{})})
def suffix_reads(locals: List<&2, U32>, slots: List<&2, U32>, rest: Suffix) -> Suffix:
  match rest:
    case Suffix{known, known_slots, read_local, read_slot, bound}:
      suffix_folded(suffix_fold(locals, Held{known, read_local}), suffix_fold(slots, Held{known_slots, read_slot}), bound)
def suffix_folded(locals: Held, slots: Held, bound: Map<&2, Bool>) -> Suffix:
  match locals slots:
    case Held{known, read_local} Held{known_slots, read_slot}:
      Suffix{known, known_slots, read_local, read_slot, bound}
def suffix_atom(value: BIR.Atom, rest: Suffix) -> Suffix:
  match atom_reads(value, reads_new()):
    case Reads{locals, slots}: suffix_reads(locals, slots, rest)
def suffix_args(args: List<&2, BIR.Arg>, rest: Suffix) -> Suffix:
  match args_reads(args, reads_new()):
    case Reads{locals, slots}: suffix_reads(locals, slots, rest)
def suffix_apply(fn: BIR.Atom, arg: BIR.Arg, rest: Suffix) -> Suffix:
  match apply_reads(fn, arg, reads_new()):
    case Reads{locals, slots}: suffix_reads(locals, slots, rest)
def suffix_op(op: BIR.Op, rest: Suffix) -> Suffix:
  match op_reads(op, reads_new()):
    case Reads{locals, slots}: suffix_reads(locals, slots, rest)
def suffix_prefix(items: List<&2, U32>, held: Map<&2, Bool>, acc: List<&2, U32>) -> List<&2, U32>:
  match items:
    case Nil{}: acc
    case +item <> rest: suffix_prefix(rest, held, suffix_prefix_one(item, held, acc))
def suffix_prefix_one(item: U32, held: Map<&2, Bool>, acc: List<&2, U32>) -> List<&2, U32>:
  match IndexLookup.find(Bool, held, U32.show(item)):
    case Some{_}: acc
    case None{}: item <> acc
# Two suffixes in traversal order: a value the right side also reads lands at
# its right-hand position, so the left keeps only what the right does not read.
def suffix_join(left: Suffix, right: Suffix) -> Suffix:
  match left right:
    case Suffix{locals, slots, read_local, read_slot, bound} Suffix{later, later_slots, later_local, later_slot, later_bound}:
      Suffix{suffix_joined(locals, later_local, later), suffix_joined(slots, later_slot, later_slots), Map.union(&2, Bool, read_local, later_local), Map.union(&2, Bool, read_slot, later_slot), Map.union(&2, Bool, bound, later_bound)}
def suffix_joined(items: List<&2, U32>, held: Map<&2, Bool>, later: List<&2, U32>) -> List<&2, U32>:
  List.append(&2, U32, List.reverse(&2, U32, suffix_prefix(items, held, Nil{})), later)
def suffix_bind(id: U32, state: Suffix) -> Suffix:
  match state:
    case Suffix{locals, slots, read_local, read_slot, bound}:
      Suffix{locals, slots, read_local, read_slot, Map.set(&2, Bool, bound, U32.show(id), True{})}
# `result` is the split's own local: it arrives as the continuation's argument,
# never as a capture. A region thunk has no such local.
def suffix_caps(state: Suffix, result: Maybe<&2, U32>) -> Caps:
  match state:
    case Suffix{locals, slots, _, _, bound}:
      Caps{caps_bound(locals, bound, result, Nil{}), slots}
def caps_bound(items: List<&2, U32>, bound: Map<&2, Bool>, result: Maybe<&2, U32>, acc: List<&2, U32>) -> List<&2, U32>:
  match items:
    case Nil{}: List.reverse(&2, U32, acc)
    case +item <> rest: caps_bound(rest, bound, result, caps_bound_one(item, bound, result, acc))
def caps_bound_one(item: U32, bound: Map<&2, Bool>, result: Maybe<&2, U32>, acc: List<&2, U32>) -> List<&2, U32>:
  match IndexLookup.find(Bool, bound, U32.show(item)):
    case Some{_}: acc
    case None{}: caps_result(item, result, acc)
def caps_result(item: U32, result: Maybe<&2, U32>, acc: List<&2, U32>) -> List<&2, U32>:
  match result:
    case None{}: item <> acc
    case Some{id}: caps_result_id(U32.is_eq(item, id), item, acc)
def caps_result_id(same: Bool, item: U32, acc: List<&2, U32>) -> List<&2, U32>:
  match same:
    case True{}: acc
    case False{}: item <> acc
def caps_locals(caps: Caps) -> List<&2, U32>:
  match caps:
    case Caps{locals, _}: locals
def caps_slots(caps: Caps) -> List<&2, U32>:
  match caps:
    case Caps{_, slots}: slots
def cap_total(caps: Caps) -> Nat:
  Nat.add(List.length(&2, U32, caps_locals(caps)), List.length(&2, U32, caps_slots(caps)))

# Region frame facts. A fact is one claim about one label, decided from the
# bottom up: `after` is a leave of that label a split already preceded, `reach`
# is any reachable leave of it, and a subtree's answer for an incoming split
# flag is Bool.or(after, Bool.and(split, reach)). Claims are never merged away:
# a lookup ORs every claim it sees, so a branch or a region only concatenates
# its children's claims, and a nested frame-form region lifts them all.
def fact_after(facts: List<&2, FrameBits>, label: U32) -> Bool:
  match facts:
    case Nil{}: False{}
    case FrameBits{known, after, _} <> rest: fact_after_here(U32.is_eq(known, label), after, rest, label)
def fact_after_here(same: Bool, after: Bool, rest: List<&2, FrameBits>, label: U32) -> Bool:
  match same:
    case True{}: Bool.or(after, fact_after(rest, label))
    case False{}: fact_after(rest, label)
def facts_merge(left: List<&2, FrameBits>, right: List<&2, FrameBits>) -> List<&2, FrameBits>:
  List.append(&2, FrameBits, left, right)
# A split before this subtree makes every leave in it reachable after a split.
def facts_elevate(facts: List<&2, FrameBits>) -> List<&2, FrameBits>:
  match facts:
    case Nil{}: Nil{}
    case FrameBits{label, after, reach} <> rest: FrameBits{label, Bool.or(after, reach), reach} <> facts_elevate(rest)
def facts_inject(facts: List<&2, FrameBits>, split: Bool) -> List<&2, FrameBits>:
  match split:
    case False{}: facts
    case True{}: facts_elevate(facts)

def plan_empty() -> Plan:
  Plan{Map.new(&2, Caps), Map.new(&2, Caps), Map.new(&2, Bool)}
def plan_cont_add(plan: Plan, id: U32, caps: Caps) -> Plan:
  match plan:
    case Plan{conts, thunks, frames}: Plan{Map.set(&2, Caps, conts, U32.show(id), caps), thunks, frames}
def plan_thunk_add(plan: Plan, label: U32, caps: Caps) -> Plan:
  match plan:
    case Plan{conts, thunks, frames}: Plan{conts, Map.set(&2, Caps, thunks, U32.show(label), caps), frames}
def plan_frame_add(plan: Plan, label: U32, need: Bool) -> Plan:
  match plan:
    case Plan{conts, thunks, frames}: Plan{conts, thunks, Map.set(&2, Bool, frames, U32.show(label), need)}
def plan_cont(plan: Plan, id: U32) -> Caps:
  match plan:
    case Plan{conts, _, _}: plan_caps(conts, U32.show(id))
def plan_thunk(plan: Plan, label: U32) -> Caps:
  match plan:
    case Plan{_, thunks, _}: plan_caps(thunks, U32.show(label))
def plan_frame(plan: Plan, label: U32) -> Bool:
  match plan:
    case Plan{_, _, frames}: plan_flag(frames, U32.show(label))
# The pass below registers exactly the sites the renderer visits, so a missing
# entry is unreachable; the empty answer keeps both readers total.
def plan_caps(map: Map<&2, Caps>, key: String) -> Caps:
  match IndexLookup.find(Caps, map, key):
    case Some{+caps}: caps
    case None{}: Caps{Nil{}, Nil{}}
def plan_flag(map: Map<&2, Bool>, key: String) -> Bool:
  match IndexLookup.find(Bool, map, key):
    case Some{+flag}: flag
    case None{}: False{}

# One bottom-up pass decides every suffix, every frame fact and both lookup
# tables at once. A node returns the state of the block it covers, so its
# parent extends that state instead of rescanning it, and the plan itself is
# threaded through the walk, so a body pays one insertion per site it has, not
# one merge per node.
def plan_of(body: BIR.Block) -> Plan:
  match plan_block(body, plan_empty()):
    case Step{_, _, plan}: plan
def plan_block(body: BIR.Block, plan: Plan) -> Step:
  match body:
    case BIR.Return{value}: plan_leaf(suffix_atom(value, suffix_empty()), plan)
    case BIR.TailDirect{_, args}: plan_leaf(suffix_args(args, suffix_empty()), plan)
    case BIR.TailApply{fn, arg}: plan_leaf(suffix_apply(fn, arg, suffix_empty()), plan)
    case BIR.Failure{_}: plan_leaf(suffix_empty(), plan)
    case BIR.LeaveRegion{label}: Step{suffix_empty(), [FrameBits{label, False{}, True{}}], plan}
    case BIR.Let{id, op, next}: plan_let(id, op, plan_block(next, plan))
    case BIR.Branch{condition, yes, no}: plan_branch(condition, plan_block(yes, plan), no)
    case BIR.Region{label, body, next}: plan_region(label, plan_block(body, plan), next)
def plan_leaf(state: Suffix, plan: Plan) -> Step:
  Step{state, Nil{}, plan}
def plan_let(id: U32, op: BIR.Op, step: Step) -> Step:
  match step:
    case Step{state, facts, plan}:
      match split_op(op):
        case True{}: Step{suffix_bind(id, suffix_op(op, state)), facts_inject(facts, True{}), plan_cont_add(plan, id, suffix_caps(state, Some{id}))}
        case False{}: Step{suffix_bind(id, suffix_op(op, state)), facts, plan}
def plan_branch(condition: BIR.Atom, yes: Step, no: BIR.Block) -> Step:
  match yes:
    case Step{yes_state, yes_facts, plan}:
      match plan_block(no, plan):
        case Step{no_state, no_facts, plan2}:
          Step{suffix_atom(condition, suffix_join(yes_state, no_state)), facts_merge(yes_facts, no_facts), plan2}
def plan_region(label: U32, body: Step, next: BIR.Block) -> Step:
  match body:
    case Step{body_state, body_facts, plan}:
      need = fact_after(body_facts, label)
      match plan_block(next, plan):
        case Step{next_state, next_facts, plan2}:
          facts = facts_merge(body_facts, facts_inject(next_facts, need))
          Step{suffix_join(body_state, next_state), facts, plan_region_sites(plan2, label, need, next_state)}
def plan_region_sites(plan: Plan, label: U32, need: Bool, next_state: Suffix) -> Plan:
  match need:
    case False{}: plan_frame_add(plan, label, False{})
    case True{}: plan_thunk_add(plan_frame_add(plan, label, True{}), label, suffix_caps(next_state, None{}))

# A record that never leaves its own body is a binding, not a value. When every
# use of a `Construct` local in the block that follows it is a `Project` of one
# of that record's own fields, the record is never observed: each projection
# reads a value the constructing frame already holds and the allocation is gone.
# This is decided from this body's BIR alone. A local that is returned, passed,
# tail-called, captured, copied, stored in another record, tag-tested or named
# by any other operand still escapes: a value that reaches another code, a
# closure, a foreign function, the host or the public trampoline keeps its boxed
# record, so no escaping or aliased record is rewritten here.
#
# A field read is not always a read. A `Symbol` atom runs a lazy declaration's
# getter, which may reenter, and a `FloatBits` atom allocates a fresh view, so a
# record holding either is left alone; every field of an eliminated record is a
# value its constructing frame evaluated once, and dropping the constructor
# therefore drops only the allocation, not an evaluation. Scalars are read where
# the record was projected, inside the same frame or the same restored capture,
# so an evaluated value, a capture order and an exception order are unchanged.
#
# The rewrite runs before the capture plan: the substituted value is what a
# continuation after a split must capture, and `block`, `conts` and `plan_of`
# then all read the rewritten body, so the plan and the split emission cannot
# disagree. It removes one object literal per site and never duplicates one, so
# it cannot grow the program.
def js_scalar(body: BIR.Block) -> BIR.Block:
  match body:
    case BIR.Let{id, BIR.Construct{constructor, tag, fields}, next}:
      js_scalar_let(id, constructor, tag, fields, next)
    case BIR.Let{id, op, next}: BIR.Let{id, op, js_scalar(next)}
    case BIR.Branch{condition, yes, no}: BIR.Branch{condition, js_scalar(yes), js_scalar(no)}
    case BIR.Region{label, inner, next}: BIR.Region{label, js_scalar(inner), js_scalar(next)}
    case _: body
# A record with an evaluated field keeps its constructor, so its block is never
# even scanned: the common `Symbol` field of a static record is rejected here.
def js_scalar_let(id: U32, constructor: U32, tag: String, fields: List<&2, BIR.Field>, next: BIR.Block) -> BIR.Block:
  js_scalar_repeatable(js_scalar_fields(fields), id, constructor, tag, fields, next)
def js_scalar_repeatable(repeatable: Bool, id: U32, constructor: U32, tag: String, fields: List<&2, BIR.Field>, next: BIR.Block) -> BIR.Block:
  match repeatable:
    case True{}: js_scalar_escapes(js_scalar_block_ok(next, id, fields), id, constructor, tag, fields, next)
    case False{}: BIR.Let{id, BIR.Construct{constructor, tag, fields}, js_scalar(next)}
# `js_scalar_block_ok` answers whether the block leaves the record unobserved,
# so its True answer is the one that removes the allocation: a block that
# returns, passes or otherwise names the record keeps the constructor.
def js_scalar_escapes(unobserved: Bool, id: U32, constructor: U32, tag: String, fields: List<&2, BIR.Field>, next: BIR.Block) -> BIR.Block:
  match unobserved:
    case True{}: js_scalar(js_scalar_block(next, id, fields))
    case False{}: BIR.Let{id, BIR.Construct{constructor, tag, fields}, js_scalar(next)}

def js_scalar_fields(fields: List<&2, BIR.Field>) -> Bool:
  match fields:
    case Nil{}: True{}
    case BIR.Field{_, _, _, value} <> rest: js_scalar_fields_value(js_scalar_value(value), rest)
def js_scalar_fields_value(repeatable: Bool, rest: List<&2, BIR.Field>) -> Bool:
  match repeatable:
    case True{}: js_scalar_fields(rest)
    case False{}: False{}
# Values that are already evaluated: reading one again is a read of the same
# JavaScript binding, in the frame that built the record or in the capture that
# restored it. The two excluded atoms are the two that evaluate something.
def js_scalar_value(value: BIR.Atom) -> Bool:
  match value:
    case BIR.Symbol{_, _}: False{}
    case BIR.FloatBits{_}: False{}
    case BIR.Local{_}: True{}
    case BIR.Capture{_}: True{}
    case BIR.Word{_}: True{}
    case BIR.Natural{_}: True{}
    case BIR.TextValue{_}: True{}
    case BIR.Boolean{_}: True{}
    case BIR.Null{}: True{}
    case BIR.Undefined{}: True{}
# True when the record is observed as a value anywhere in the block: every
# operand form is classified by the read set `op_reads` already computes, so
# this pass adds no second traversal rule of its own.
def js_scalar_block_ok(body: BIR.Block, id: U32, fields: List<&2, BIR.Field>) -> Bool:
  match body:
    case BIR.Return{value}: Bool.not(js_scalar_atom_used(value, id))
    case BIR.Let{_, op, next}: Bool.and(js_scalar_op_ok(op, id, fields), js_scalar_block_ok(next, id, fields))
    case BIR.Branch{condition, yes, no}:
      Bool.and(Bool.not(js_scalar_atom_used(condition, id)), Bool.and(js_scalar_block_ok(yes, id, fields), js_scalar_block_ok(no, id, fields)))
    case BIR.Region{_, inner, next}: Bool.and(js_scalar_block_ok(inner, id, fields), js_scalar_block_ok(next, id, fields))
    case BIR.LeaveRegion{_}: True{}
    case BIR.TailDirect{_, args}: Bool.not(js_scalar_args_used(args, id))
    case BIR.TailApply{fn, arg}: Bool.not(js_scalar_reads(apply_reads(fn, arg, reads_new()), id))
    case BIR.Failure{_}: True{}
def js_scalar_op_ok(op: BIR.Op, id: U32, fields: List<&2, BIR.Field>) -> Bool:
  match op:
    case BIR.Project{value, _, _, key}: js_scalar_project_ok(value, key, id, fields)
    case _: Bool.not(js_scalar_reads(op_reads(op, reads_new()), id))
# A projection of this record is its one observation: the field must exist and
# be a value, not an evaluation. A projection of anything else cannot name a
# local, so it is not a use of this record.
def js_scalar_project_ok(value: BIR.Atom, +key: String, id: U32, fields: List<&2, BIR.Field>) -> Bool:
  match value:
    case BIR.Local{known}: js_scalar_project_local(U32.is_eq(known, id), key, fields)
    case _: True{}
def js_scalar_project_local(same: Bool, +key: String, fields: List<&2, BIR.Field>) -> Bool:
  match same:
    case True{}: js_scalar_project_field(js_scalar_field_at(fields, key))
    case False{}: True{}
def js_scalar_project_field(found: Maybe<&2, BIR.Atom>) -> Bool:
  match found:
    case Some{value}: js_scalar_value(value)
    case None{}: False{}
def js_scalar_field_at(fields: List<&2, BIR.Field>, key: String) -> Maybe<&2, BIR.Atom>:
  match fields:
    case Nil{}: None{}
    case BIR.Field{_, +known, _, value} <> rest: js_scalar_field_at_same(String.eq(key, known), value, rest, key)
def js_scalar_field_at_same(same: Bool, value: BIR.Atom, rest: List<&2, BIR.Field>, +key: String) -> Maybe<&2, BIR.Atom>:
  match same:
    case True{}: Some{value}
    case False{}: js_scalar_field_at(rest, key)
def js_scalar_reads(reads: Reads, id: U32) -> Bool:
  match reads:
    case Reads{locals, _}: js_scalar_mentions(locals, id)
def js_scalar_mentions(items: List<&2, U32>, id: U32) -> Bool:
  match items:
    case Nil{}: False{}
    case +item <> rest: js_scalar_mentions_one(U32.is_eq(item, id), rest, id)
def js_scalar_mentions_one(same: Bool, rest: List<&2, U32>, id: U32) -> Bool:
  match same:
    case True{}: True{}
    case False{}: js_scalar_mentions(rest, id)
def js_scalar_atom_used(value: BIR.Atom, id: U32) -> Bool:
  js_scalar_reads(atom_reads(value, reads_new()), id)
def js_scalar_args_used(args: List<&2, BIR.Arg>, id: U32) -> Bool:
  js_scalar_reads(args_reads(args, reads_new()), id)
# The scan above admitted this block, so every projection of this local resolves
# to a field of the record it came from; a projection that resolves nothing
# belongs to another value and keeps its spelling.
def js_scalar_block(body: BIR.Block, id: U32, fields: List<&2, BIR.Field>) -> BIR.Block:
  match body:
    case BIR.Let{next_id, op, next}:
      BIR.Let{next_id, js_scalar_op(op, id, fields), js_scalar_block(next, id, fields)}
    case BIR.Branch{condition, yes, no}:
      BIR.Branch{condition, js_scalar_block(yes, id, fields), js_scalar_block(no, id, fields)}
    case BIR.Region{label, inner, next}:
      BIR.Region{label, js_scalar_block(inner, id, fields), js_scalar_block(next, id, fields)}
    case _: body
def js_scalar_op(op: BIR.Op, id: U32, fields: List<&2, BIR.Field>) -> BIR.Op:
  match op:
    case BIR.Project{value, constructor, field, key}:
      js_scalar_projection(js_scalar_projected(value, key, id, fields), value, constructor, field, key)
    case _: op
def js_scalar_projected(value: BIR.Atom, +key: String, id: U32, fields: List<&2, BIR.Field>) -> Maybe<&2, BIR.Atom>:
  match value:
    case BIR.Local{known}: js_scalar_projected_local(U32.is_eq(known, id), key, fields)
    case _: None{}
def js_scalar_projected_local(same: Bool, +key: String, fields: List<&2, BIR.Field>) -> Maybe<&2, BIR.Atom>:
  match same:
    case True{}: js_scalar_field_at(fields, key)
    case False{}: None{}
def js_scalar_projection(found: Maybe<&2, BIR.Atom>, value: BIR.Atom, constructor: U32, field: U32, +key: String) -> BIR.Op:
  match found:
    case Some{atom}: BIR.Copy{atom}
    case None{}: BIR.Project{value, constructor, field, key}

# A record a code returns, and a record parameter it only destructures, can
# travel as a tag word plus field words in the machine's own argument stack
# instead of as an object. The convention is decided per code from BIR alone and
# it is two-sided or not at all: a code that can return this way also renders a
# boxed public body, so every value a host, native, foreign function or first
# class closure can name keeps exactly the object it has today.
#
# The window is the machine's existing argument stack, never a buffer. A call
# site stores its captures, then passes `$mr = $sp` measured after those stores,
# and the callee writes the tag plus W field words at `$mr+1..`. The callee's own
# result width is the program's one width W, so a producer, a parameter forward
# and a consumer all agree on how many words exist and none can truncate another.
# A consumer binds those words at `$base+cap_total+1..` in the continuation that
# receives the tag, before anything else runs, and clears them immediately after
# binding. Nothing reserves or pops a window, so the split abort, the frame pop
# and the depth bound stay exactly the machine's own.
#
# Escapes are decided by BIR: a parameter stays unboxed only when every use is a
# tag test, a field projection under a tag refinement for that value, or the
# code's whole result; every call site of that position must then be able to
# supply tag plus words. Results stay unboxed only when every value path is a
# record literal returned at once, a whole record parameter, a throw, or a tail
# call into another code that is itself unboxed. Anything else keeps today's
# object, which is always a correct answer, and a code whose rewrite is not
# proven emits exactly the source it emitted before.
type MultiLayout is Data:
  MultiLayout{tag: String, keys: List<&2, String>}
type MultiParam is Data:
  MultiParam{id: U32, unboxed: Bool, tag: U32, fields: List<&2, U32>}
type MultiWindow is Data:
  MultiWindow{width: Nat, fields: List<&2, U32>, box: Maybe<&2, U32>}
type MultiShape is Data:
  MultiCtorShape{constructor: U32, width: Nat}
  MultiParamShape{position: Nat}
  MultiResultShape{}
  MultiOtherShape{}
type MultiSiteF is Data:
  MultiSiteF{key: String, callee: U32, tail: Bool, shapes: List<&2, MultiShape>}
type MultiCtor is Data:
  MultiCtor{constructor: U32, tag: String, fields: List<&2, BIR.Field>}
type MultiScan is Data:
  MultiScan{bindings: Map<&2, MultiCtor>, sites: List<&2, MultiSiteF>}
type MultiFact is Data:
  MultiFact{result_ok: Bool, width: Nat, sites: List<&2, MultiSiteF>}
type MultiUp is Data:
  MultiUp{up: Map<&2, Bool>, multi: Map<&2, Bool>}
type MultiSubst is Data:
  MultiSubst{id: U32, tag: BIR.Atom, fields: List<&2, BIR.Atom>, param: Bool}
type MultiRew is Data:
  MultiRew{body: BIR.Block, windows: Map<&2, MultiWindow>, sites: Map<&2, Bool>, mr: Map<&2, Bool>, dropped: Map<&2, Bool>, failed: Bool, own_mr: Bool, next: Nat}
type MultiRender is Data:
  MultiRender{body: BIR.Block, plan: Plan, params: List<&2, MultiParam>, windows: Map<&2, MultiWindow>, sites: Map<&2, Bool>, mr: Map<&2, Bool>, private: Bool, public: Bool, width: Nat, failed: Bool}
type MultiPlan is Data:
  MultiPlan{multi: Map<&2, Bool>, layouts: Map<&2, MultiLayout>, renders: Map<&2, MultiRender>, width: Nat, ok: Bool}

def multi_live_keys(items: List<&2, Maybe<&2, String>>, acc: List<&2, String>) -> List<&2, String>:
  match items:
    case Nil{}: List.reverse(&2, String, acc)
    case item <> rest: multi_live_key(item, rest, acc)
def multi_live_key(item: Maybe<&2, String>, rest: List<&2, Maybe<&2, String>>, acc: List<&2, String>) -> List<&2, String>:
  match item:
    case Some{+key}: multi_live_keys(rest, key <> acc)
    case None{}: multi_live_keys(rest, acc)
def multi_layouts(items: List<&2, BIR.ConstructorLayout>, layouts: Map<&2, MultiLayout>) -> Map<&2, MultiLayout>:
  match items:
    case Nil{}: layouts
    case BIR.ConstructorLayout{id, +key, _, fields} <> rest:
      multi_layout_add(multi_layouts(rest, layouts), id, key, fields)
def multi_layout_add(layouts: Map<&2, MultiLayout>, id: U32, +key: String, fields: List<&2, Maybe<&2, String>>) -> Map<&2, MultiLayout>:
  Map.set(&2, MultiLayout, layouts, U32.show(id), MultiLayout{tag: key, keys: multi_live_keys(fields, Nil{})})
def multi_layout(layouts: Map<&2, MultiLayout>, id: U32) -> Maybe<&2, MultiLayout>:
  IndexLookup.find(MultiLayout, layouts, U32.show(id))
def multi_layout_keys(layouts: Map<&2, MultiLayout>, id: U32) -> List<&2, String>:
  multi_layout_keys_of(multi_layout(layouts, id))
def multi_layout_keys_of(found: Maybe<&2, MultiLayout>) -> List<&2, String>:
  match found:
    case Some{MultiLayout{_, keys}}: keys
    case None{}: Nil{}
def multi_layout_tag(layouts: Map<&2, MultiLayout>, id: U32) -> Maybe<&2, String>:
  multi_layout_tag_of(multi_layout(layouts, id))
def multi_layout_tag_of(found: Maybe<&2, MultiLayout>) -> Maybe<&2, String>:
  match found:
    case Some{MultiLayout{tag, _}}: Some{tag}
    case None{}: None{}
def multi_key_at(items: List<&2, String>, key: String, index: Nat) -> Maybe<&2, Nat>:
  match items:
    case Nil{}: None{}
    case +head <> rest: multi_key_at_step(String.eq(head, key), rest, key, index)
def multi_key_at_step(same: Bool, rest: List<&2, String>, +key: String, index: Nat) -> Maybe<&2, Nat>:
  match same:
    case True{}: Some{index}
    case False{}: multi_key_at(rest, key, (index + 1n : Nat))
def multi_keys_eq(left: List<&2, String>, right: List<&2, String>) -> Bool:
  match left:
    case Nil{}: multi_keys_empty(right)
    case +head <> rest: multi_keys_tail(right, head, rest)
def multi_keys_empty(right: List<&2, String>) -> Bool:
  match right:
    case Nil{}: True{}
    case _: False{}
def multi_keys_tail(right: List<&2, String>, +head: String, left: List<&2, String>) -> Bool:
  match right:
    case Nil{}: False{}
    case +known <> rest: multi_keys_head(String.eq(head, known), rest, head, left)
def multi_keys_head(same: Bool, right: List<&2, String>, +head: String, left: List<&2, String>) -> Bool:
  match same:
    case True{}: multi_keys_eq(left, right)
    case False{}: False{}

# A fresh name is a function of the site or parameter that owns it and a slot, so
# two renderings of one body and the analysis itself always choose one spelling.
def multi_fresh(id: U32, slot: Nat) -> U32:
  U32.add(U32.add(U32.mul(id, 8n : Nat), U32.from_nat(slot)), U32.from_nat(1610612736n))
def multi_fresh_ids(id: U32, count: Nat) -> List<&2, U32>:
  multi_fresh_range(id, count, 0n, Nil{})
def multi_fresh_range(id: U32, count: Nat, index: Nat, acc: List<&2, U32>) -> List<&2, U32>:
  match Nat.is_lt(index, count):
    case True{}: multi_fresh_range(id, count, (index + 1n : Nat), multi_fresh(id, index) <> acc)
    case False{}: List.reverse(&2, U32, acc)

type MultiRef is Data:
  MultiRef{id: U32, tag: String}
type MultiFwd is Data:
  MultiFwd{caller: U32, shape: MultiShape}

def multi_names(value: BIR.Atom, id: U32) -> Bool:
  match value:
    case BIR.Local{known}: U32.is_eq(known, id)
    case _: False{}
def multi_arg_only_names(arg: BIR.Arg, id: U32) -> Bool:
  match arg:
    case BIR.Arg{_, value}: multi_names(value, id)
def multi_args_name(args: List<&2, BIR.Arg>, id: U32) -> Bool:
  match args:
    case Nil{}: False{}
    case +item <> rest: multi_args_name_one(multi_arg_names(item, id), rest, id)
def multi_args_name_one(named: Bool, rest: List<&2, BIR.Arg>, id: U32) -> Bool:
  match named:
    case True{}: True{}
    case False{}: multi_args_name(rest, id)
def multi_fields_name(fields: List<&2, BIR.Field>, id: U32) -> Bool:
  match fields:
    case Nil{}: False{}
    case BIR.Field{_, _, _, value} <> rest: multi_fields_name_one(multi_names(value, id), rest, id)
def multi_fields_name_one(named: Bool, rest: List<&2, BIR.Field>, id: U32) -> Bool:
  match named:
    case True{}: True{}
    case False{}: multi_fields_name(rest, id)

def multi_uses(body: BIR.Block) -> Map<&2, Nat>:
  multi_uses_block(body, Map.new(&2, Nat))
def multi_use_atom(value: BIR.Atom, uses: Map<&2, Nat>) -> Map<&2, Nat>:
  match value:
    case BIR.Local{id}: multi_use_one(uses, id)
    case _: uses
def multi_use_one(uses: Map<&2, Nat>, id: U32) -> Map<&2, Nat>:
  multi_use_add(IndexLookup.find(Nat, uses, U32.show(id)), uses, id)
def multi_use_add(found: Maybe<&2, Nat>, uses: Map<&2, Nat>, id: U32) -> Map<&2, Nat>:
  match found:
    case Some{count}: Map.set(&2, Nat, uses, U32.show(id), Nat.add(count, 1n))
    case None{}: Map.set(&2, Nat, uses, U32.show(id), 1n)
def multi_use_arg(arg: BIR.Arg, uses: Map<&2, Nat>) -> Map<&2, Nat>:
  match arg:
    case BIR.Arg{_, value}: multi_use_atom(value, uses)
def multi_use_args(args: List<&2, BIR.Arg>, uses: Map<&2, Nat>) -> Map<&2, Nat>:
  match args:
    case Nil{}: uses
    case +item <> rest: multi_use_args(rest, multi_use_arg(item, uses))
def multi_use_field(field: BIR.Field, uses: Map<&2, Nat>) -> Map<&2, Nat>:
  match field:
    case BIR.Field{_, _, _, value}: multi_use_atom(value, uses)
def multi_use_fields(fields: List<&2, BIR.Field>, uses: Map<&2, Nat>) -> Map<&2, Nat>:
  match fields:
    case Nil{}: uses
    case +item <> rest: multi_use_fields(rest, multi_use_field(item, uses))
def multi_use_op(op: BIR.Op, uses: Map<&2, Nat>) -> Map<&2, Nat>:
  match op:
    case BIR.Copy{value}: multi_use_atom(value, uses)
    case BIR.PrimitiveCall{_, args, _}: multi_use_args(args, uses)
    case BIR.Closure{_, captures, _}: multi_use_args(captures, uses)
    case BIR.Direct{_, args}: multi_use_args(args, uses)
    case BIR.Apply{fn, arg}: multi_use_arg(arg, multi_use_atom(fn, uses))
    case BIR.LoadSymbol{_, _}: uses
    case BIR.Construct{_, _, fields}: multi_use_fields(fields, uses)
    case BIR.Project{value, _, _, _}: multi_use_atom(value, uses)
    case BIR.HasTag{value, _, _}: multi_use_atom(value, uses)
def multi_uses_block(body: BIR.Block, uses: Map<&2, Nat>) -> Map<&2, Nat>:
  match body:
    case BIR.Return{value}: multi_use_atom(value, uses)
    case BIR.Let{_, op, next}: multi_uses_block(next, multi_use_op(op, uses))
    case BIR.Branch{condition, yes, no}: multi_uses_block(no, multi_uses_block(yes, multi_use_atom(condition, uses)))
    case BIR.Region{_, inner, next}: multi_uses_block(next, multi_uses_block(inner, uses))
    case BIR.LeaveRegion{_}: uses
    case BIR.TailDirect{_, args}: multi_use_args(args, uses)
    case BIR.TailApply{fn, arg}: multi_use_arg(arg, multi_use_atom(fn, uses))
    case BIR.Failure{_}: uses

def multi_param_index(items: List<&2, BIR.Parameter>, index: Nat, acc: Map<&2, Nat>) -> Map<&2, Nat>:
  match items:
    case Nil{}: acc
    case BIR.Parameter{id, _} <> rest:
      multi_param_index(rest, (index + 1n : Nat), Map.set(&2, Nat, acc, U32.show(id), index))
def multi_param_of(params: Map<&2, Nat>, id: U32) -> Maybe<&2, Nat>:
  IndexLookup.find(Nat, params, U32.show(id))
def multi_up_key(code: U32, position: Nat) -> String:
  cat([U32.show(code), ":", Nat.show(position)])
def multi_up_get(up: Map<&2, Bool>, code: U32, position: Nat) -> Bool:
  multi_up_found(IndexLookup.find(Bool, up, multi_up_key(code, position)))
def multi_up_found(found: Maybe<&2, Bool>) -> Bool:
  match found:
    case Some{flag}: flag
    case None{}: False{}
def multi_multi_get(multi: Map<&2, Bool>, code: U32) -> Bool:
  multi_multi_found(IndexLookup.find(Bool, multi, U32.show(code)))
def multi_multi_found(found: Maybe<&2, Bool>) -> Bool:
  match found:
    case Some{flag}: flag
    case None{}: False{}
def multi_banned(banned: Map<&2, Bool>, code: U32) -> Bool:
  multi_multi_get(banned, code)

def multi_ctor_one_use(uses: Map<&2, Nat>, local: U32) -> Bool:
  multi_ctor_one_found(IndexLookup.find(Nat, uses, U32.show(local)))
def multi_ctor_one_found(found: Maybe<&2, Nat>) -> Bool:
  match found:
    case Some{count}: Nat.is_eq(count, 1n)
    case None{}: False{}
def multi_fields_inert(fields: List<&2, BIR.Field>) -> Bool:
  match fields:
    case Nil{}: True{}
    case BIR.Field{_, _, _, value} <> rest: multi_fields_tail(js_scalar_value(value), rest)
def multi_fields_tail(inert: Bool, rest: List<&2, BIR.Field>) -> Bool:
  match inert:
    case True{}: multi_fields_inert(rest)
    case False{}: False{}
def multi_field_keys(fields: List<&2, BIR.Field>, acc: List<&2, String>) -> List<&2, String>:
  match fields:
    case Nil{}: List.reverse(&2, String, acc)
    case BIR.Field{_, +key, _, _} <> rest: multi_field_keys(rest, key <> acc)
def multi_field_width(fields: List<&2, BIR.Field>) -> Nat:
  List.length(&2, BIR.Field, fields)
def multi_ctor_openable(uses: Map<&2, Nat>, layouts: Map<&2, MultiLayout>, local: U32, constructor: U32, fields: List<&2, BIR.Field>) -> Bool:
  multi_ctor_openable_uses(multi_ctor_one_use(uses, local), layouts, constructor, fields)
def multi_ctor_openable_uses(one: Bool, layouts: Map<&2, MultiLayout>, constructor: U32, fields: List<&2, BIR.Field>) -> Bool:
  match one:
    case False{}: False{}
    case True{}: Bool.and(multi_fields_inert(fields), multi_keys_eq(multi_field_keys(fields, Nil{}), multi_layout_keys(layouts, constructor)))

def multi_binding(bindings: Map<&2, MultiCtor>, id: U32) -> Maybe<&2, MultiCtor>:
  IndexLookup.find(MultiCtor, bindings, U32.show(id))
def multi_cur_is(cur: Maybe<&2, U32>, id: U32) -> Bool:
  match cur:
    case Some{known}: U32.is_eq(known, id)
    case None{}: False{}
def multi_shape(value: BIR.Atom, layouts: Map<&2, MultiLayout>, uses: Map<&2, Nat>, params: Map<&2, Nat>, bindings: Map<&2, MultiCtor>, cur: Maybe<&2, U32>) -> MultiShape:
  match value:
    case BIR.Local{id}: multi_shape_local(id, layouts, uses, params, bindings, cur)
    case _: MultiOtherShape{}
def multi_shape_local(id: U32, layouts: Map<&2, MultiLayout>, uses: Map<&2, Nat>, params: Map<&2, Nat>, bindings: Map<&2, MultiCtor>, cur: Maybe<&2, U32>) -> MultiShape:
  multi_shape_kind(multi_cur_is(cur, id), multi_param_of(params, id), multi_binding(bindings, id), layouts, uses, id)
def multi_shape_kind(result: Bool, position: Maybe<&2, Nat>, binding: Maybe<&2, MultiCtor>, layouts: Map<&2, MultiLayout>, uses: Map<&2, Nat>, id: U32) -> MultiShape:
  match result:
    case True{}: MultiResultShape{}
    case False{}: multi_shape_bound(position, binding, layouts, uses, id)
def multi_shape_bound(position: Maybe<&2, Nat>, binding: Maybe<&2, MultiCtor>, layouts: Map<&2, MultiLayout>, uses: Map<&2, Nat>, id: U32) -> MultiShape:
  match position:
    case Some{index}: MultiParamShape{position: index}
    case None{}: multi_shape_binding(binding, layouts, uses, id)
def multi_shape_binding(binding: Maybe<&2, MultiCtor>, layouts: Map<&2, MultiLayout>, uses: Map<&2, Nat>, id: U32) -> MultiShape:
  match binding:
    case Some{MultiCtor{constructor, _, fields}}: multi_shape_open(multi_ctor_openable(uses, layouts, id, constructor, fields), constructor, fields)
    case None{}: MultiOtherShape{}
def multi_shape_open(openable: Bool, constructor: U32, fields: List<&2, BIR.Field>) -> MultiShape:
  match openable:
    case True{}: MultiCtorShape{constructor, width: multi_field_width(fields)}
    case False{}: MultiOtherShape{}
def multi_shapes(args: List<&2, BIR.Arg>, layouts: Map<&2, MultiLayout>, uses: Map<&2, Nat>, params: Map<&2, Nat>, bindings: Map<&2, MultiCtor>, cur: Maybe<&2, U32>) -> List<&2, MultiShape>:
  match args:
    case Nil{}: Nil{}
    case BIR.Arg{_, value} <> rest:
      multi_shape(value, layouts, uses, params, bindings, cur) <> multi_shapes(rest, layouts, uses, params, bindings, cur)

def multi_scan(body: BIR.Block, st: MultiScan, layouts: Map<&2, MultiLayout>, uses: Map<&2, Nat>, params: Map<&2, Nat>, cur: Maybe<&2, U32>, owner: U32) -> MultiScan:
  match body:
    case BIR.Return{_}: st
    case BIR.Let{id, op, next}: multi_scan_let(id, op, next, st, layouts, uses, params, cur, owner)
    case BIR.Branch{_, yes, no}: multi_scan(no, multi_scan(yes, st, layouts, uses, params, cur, owner), layouts, uses, params, cur, owner)
    case BIR.Region{_, inner, next}: multi_scan(next, multi_scan(inner, st, layouts, uses, params, cur, owner), layouts, uses, params, cur, owner)
    case BIR.LeaveRegion{_}: st
    case BIR.TailDirect{code, args}: multi_scan_tail(code, args, st, layouts, uses, params, cur, owner)
    case BIR.TailApply{_, _}: st
    case BIR.Failure{_}: st
def multi_scan_let(id: U32, op: BIR.Op, next: BIR.Block, st: MultiScan, layouts: Map<&2, MultiLayout>, uses: Map<&2, Nat>, params: Map<&2, Nat>, cur: Maybe<&2, U32>, owner: U32) -> MultiScan:
  match op:
    case BIR.Construct{constructor, tag, fields}: multi_scan_bind(id, constructor, tag, fields, next, st, layouts, uses, params, cur, owner)
    case BIR.Direct{code, args}: multi_scan_direct(id, code, args, next, st, layouts, uses, params, cur, owner)
    case BIR.Apply{_, _}: multi_scan(next, st, layouts, uses, params, Some{id}, owner)
    case _: multi_scan(next, st, layouts, uses, params, cur, owner)
def multi_scan_bind(id: U32, constructor: U32, tag: String, fields: List<&2, BIR.Field>, next: BIR.Block, st: MultiScan, layouts: Map<&2, MultiLayout>, uses: Map<&2, Nat>, params: Map<&2, Nat>, cur: Maybe<&2, U32>, owner: U32) -> MultiScan:
  match st:
    case MultiScan{bindings, sites}:
      multi_scan(next, MultiScan{Map.set(&2, MultiCtor, bindings, U32.show(id), MultiCtor{constructor, tag, fields}), sites}, layouts, uses, params, cur, owner)
def multi_scan_direct(id: U32, code: U32, args: List<&2, BIR.Arg>, next: BIR.Block, st: MultiScan, layouts: Map<&2, MultiLayout>, uses: Map<&2, Nat>, params: Map<&2, Nat>, cur: Maybe<&2, U32>, owner: U32) -> MultiScan:
  match st:
    case MultiScan{bindings, sites}:
      multi_scan(next, MultiScan{bindings, MultiSiteF{key: cat(["k", U32.show(id)]), callee: code, tail: False{}, shapes: multi_shapes(args, layouts, uses, params, bindings, cur)} <> sites}, layouts, uses, params, Some{id}, owner)
def multi_scan_tail(code: U32, args: List<&2, BIR.Arg>, st: MultiScan, layouts: Map<&2, MultiLayout>, uses: Map<&2, Nat>, params: Map<&2, Nat>, cur: Maybe<&2, U32>, owner: U32) -> MultiScan:
  match st:
    case MultiScan{bindings, sites}:
      MultiScan{bindings, MultiSiteF{key: cat(["t", U32.show(owner), ":", Nat.show(List.length(&2, MultiSiteF, sites))]), callee: code, tail: True{}, shapes: multi_shapes(args, layouts, uses, params, bindings, cur)} <> sites}

def multi_return_ok(value: BIR.Atom, up: Map<&2, Bool>, code: U32, params: Map<&2, Nat>) -> Bool:
  match value:
    case BIR.Local{id}: multi_return_local(up, code, params, id)
    case _: False{}
def multi_return_local(up: Map<&2, Bool>, code: U32, params: Map<&2, Nat>, id: U32) -> Bool:
  multi_return_pos(multi_param_of(params, id), up, code)
def multi_return_pos(position: Maybe<&2, Nat>, up: Map<&2, Bool>, code: U32) -> Bool:
  match position:
    case Some{index}: multi_up_get(up, code, index)
    case None{}: False{}
# A value path is a place a code hands its caller a value. Every one of them is
# either a record literal returned at once, a whole unboxed parameter, a throw or
# a tail call; a tail call into another convention code is checked by the fixed
# point, since only then does the tag agree with the caller's window.
def multi_result_ok(body: BIR.Block, up: Map<&2, Bool>, code: U32, params: Map<&2, Nat>) -> Bool:
  match body:
    case BIR.Return{value}: multi_return_ok(value, up, code, params)
    case BIR.Let{id, op, next}: multi_let_result_ok(id, op, next, up, code, params)
    case BIR.Branch{_, yes, no}: Bool.and(multi_result_ok(yes, up, code, params), multi_result_ok(no, up, code, params))
    case BIR.Region{_, inner, next}: Bool.and(multi_result_ok(inner, up, code, params), multi_result_ok(next, up, code, params))
    case BIR.LeaveRegion{_}: True{}
    case BIR.TailDirect{_, _}: True{}
    case BIR.TailApply{_, _}: False{}
    case BIR.Failure{_}: True{}
def multi_let_result_ok(id: U32, op: BIR.Op, next: BIR.Block, up: Map<&2, Bool>, code: U32, params: Map<&2, Nat>) -> Bool:
  match op:
    case BIR.Construct{_, _, _}: multi_construct_result(id, next, up, code, params)
    case _: multi_result_ok(next, up, code, params)
def multi_construct_result(id: U32, next: BIR.Block, up: Map<&2, Bool>, code: U32, params: Map<&2, Nat>) -> Bool:
  match next:
    case BIR.Return{BIR.Local{known}}: multi_construct_same(U32.is_eq(known, id), next, up, code, params)
    case _: multi_result_ok(next, up, code, params)
def multi_construct_same(same: Bool, next: BIR.Block, up: Map<&2, Bool>, code: U32, params: Map<&2, Nat>) -> Bool:
  match same:
    case True{}: True{}
    case False{}: multi_result_ok(next, up, code, params)
def multi_local_width(body: BIR.Block, width: Nat) -> Nat:
  match body:
    case BIR.Return{_}: width
    case BIR.Let{id, op, next}: multi_width_let(id, op, next, width)
    case BIR.Branch{_, yes, no}: multi_local_width(no, multi_local_width(yes, width))
    case BIR.Region{_, inner, next}: multi_local_width(next, multi_local_width(inner, width))
    case _: width
def multi_width_let(id: U32, op: BIR.Op, next: BIR.Block, width: Nat) -> Nat:
  match op:
    case BIR.Construct{_, _, fields}: multi_width_ctor(id, next, multi_field_width(fields), width)
    case _: multi_local_width(next, width)
def multi_width_ctor(id: U32, next: BIR.Block, count: Nat, width: Nat) -> Nat:
  match next:
    case BIR.Return{BIR.Local{known}}: multi_width_same(U32.is_eq(known, id), next, count, width)
    case _: multi_local_width(next, width)
def multi_width_same(same: Bool, next: BIR.Block, count: Nat, width: Nat) -> Nat:
  match same:
    case True{}: Nat.max(count, width)
    case False{}: multi_local_width(next, width)

# A framed region's next block is its own function and cannot see the code's
# window, so a value path there would have no place to write. These codes keep
# the boxed body.
def multi_no_value(body: BIR.Block) -> Bool:
  match body:
    case BIR.Return{_}: False{}
    case BIR.Let{_, _, next}: multi_no_value(next)
    case BIR.Branch{_, yes, no}: Bool.and(multi_no_value(yes), multi_no_value(no))
    case BIR.Region{_, inner, next}: Bool.and(multi_no_value(inner), multi_no_value(next))
    case BIR.LeaveRegion{_}: True{}
    case BIR.TailDirect{_, _}: False{}
    case BIR.TailApply{_, _}: False{}
    case BIR.Failure{_}: True{}
def multi_frames_ok(body: BIR.Block, plan: Plan) -> Bool:
  match body:
    case BIR.Return{_}: True{}
    case BIR.Let{_, _, next}: multi_frames_ok(next, plan)
    case BIR.Branch{_, yes, no}: Bool.and(multi_frames_ok(yes, plan), multi_frames_ok(no, plan))
    case BIR.Region{label, inner, next}: multi_region_frames(label, inner, next, plan)
    case _: True{}
def multi_region_frames(label: U32, inner: BIR.Block, next: BIR.Block, plan: Plan) -> Bool:
  match plan_frame(plan, label):
    case True{}: Bool.and(multi_no_value(next), multi_frames_ok(inner, plan))
    case False{}: Bool.and(multi_frames_ok(inner, plan), multi_frames_ok(next, plan))

def multi_ref_tag(refs: List<&2, MultiRef>, id: U32) -> Maybe<&2, String>:
  match refs:
    case Nil{}: None{}
    case MultiRef{known, tag} <> rest: multi_ref_step(U32.is_eq(known, id), tag, rest, id)
def multi_ref_step(same: Bool, tag: String, rest: List<&2, MultiRef>, id: U32) -> Maybe<&2, String>:
  match same:
    case True{}: Some{tag}
    case False{}: multi_ref_tag(rest, id)
def multi_return_names(value: BIR.Atom, p: U32) -> Bool:
  match value:
    case BIR.Local{known}: U32.is_eq(known, p)
    case _: True{}
def multi_project_ok(value: BIR.Atom, constructor: U32, key: String, layouts: Map<&2, MultiLayout>, width: Nat, refs: List<&2, MultiRef>, p: U32) -> Bool:
  match value:
    case BIR.Local{known}: multi_project_local(U32.is_eq(known, p), constructor, key, layouts, width, refs, p)
    case _: True{}
def multi_project_local(same: Bool, constructor: U32, key: String, layouts: Map<&2, MultiLayout>, width: Nat, refs: List<&2, MultiRef>, p: U32) -> Bool:
  match same:
    case False{}: True{}
    case True{}: multi_project_refined(multi_ref_tag(refs, p), constructor, key, layouts, width)
# The runtime tag of the value must be the constructor the projection was
# resolved against, and the key must be a field of that constructor inside the
# program width; the enclosing tag test is what proves the tag.
def multi_project_refined(tag: Maybe<&2, String>, constructor: U32, key: String, layouts: Map<&2, MultiLayout>, width: Nat) -> Bool:
  match tag:
    case None{}: False{}
    case Some{known}: multi_project_layout(String.eq(known, multi_layout_tag_text(layouts, constructor)), multi_layout(layouts, constructor), key, width)
def multi_layout_tag_text(layouts: Map<&2, MultiLayout>, constructor: U32) -> String:
  multi_layout_tag_text_of(multi_layout_tag(layouts, constructor))
def multi_layout_tag_text_of(found: Maybe<&2, String>) -> String:
  match found:
    case Some{+tag}: tag
    case None{}: ""
def multi_project_layout(same_tag: Bool, layout: Maybe<&2, MultiLayout>, key: String, width: Nat) -> Bool:
  match same_tag:
    case False{}: False{}
    case True{}: multi_project_slot(multi_layout_keys_of(layout), key, width)
def multi_project_slot(keys: List<&2, String>, key: String, width: Nat) -> Bool:
  multi_project_index(multi_key_at(keys, key, 0n), width)
def multi_project_index(slot: Maybe<&2, Nat>, width: Nat) -> Bool:
  match slot:
    case Some{index}: Nat.is_lt(index, width)
    case None{}: False{}

def multi_op_uses(op: BIR.Op, p: U32, layouts: Map<&2, MultiLayout>, width: Nat, refs: List<&2, MultiRef>) -> Bool:
  match op:
    case BIR.Copy{value}: multi_names_ok(value, p)
    case BIR.PrimitiveCall{_, args, _}: Bool.not(multi_args_name(args, p))
    case BIR.Closure{_, captures, _}: Bool.not(multi_args_name(captures, p))
    case BIR.Direct{_, args}: Bool.not(multi_args_name(args, p))
    case BIR.Apply{fn, arg}: Bool.not(multi_arg_names(fn, arg, p))
    case BIR.LoadSymbol{_, _}: True{}
    case BIR.Construct{_, _, fields}: Bool.not(multi_fields_name(fields, p))
    case BIR.Project{value, constructor, _, key}: multi_project_ok(value, constructor, key, layouts, width, refs, p)
    case BIR.HasTag{value, _, _}: multi_names_ok(value, p)
def multi_names_ok(value: BIR.Atom, p: U32) -> Bool:
  Bool.not(multi_names(value, p))
def multi_arg_names(fn: BIR.Atom, arg: BIR.Arg, p: U32) -> Bool:
  Bool.or(multi_names(fn, p), multi_arg_names_one(arg, p))
def multi_arg_names_one(arg: BIR.Arg, p: U32) -> Bool:
  match arg:
    case BIR.Arg{_, value}: multi_names(value, p)
def multi_uses_of(body: BIR.Block, p: U32, layouts: Map<&2, MultiLayout>, width: Nat, refs: List<&2, MultiRef>) -> Bool:
  match body:
    case BIR.Return{value}: multi_return_names(value, p)
    case BIR.Let{test, op, next}: multi_let_uses(test, op, next, p, layouts, width, refs)
    case BIR.Branch{condition, yes, no}: Bool.and(multi_names_ok(condition, p), Bool.and(multi_uses_of(yes, p, layouts, width, refs), multi_uses_of(no, p, layouts, width, refs)))
    case BIR.Region{_, inner, next}: Bool.and(multi_uses_of(inner, p, layouts, width, refs), multi_uses_of(next, p, layouts, width, refs))
    case BIR.LeaveRegion{_}: True{}
    case BIR.TailDirect{_, args}: Bool.not(multi_args_name(args, p))
    case BIR.TailApply{fn, arg}: Bool.not(multi_arg_names(fn, arg, p))
    case BIR.Failure{_}: True{}
def multi_let_uses(test: U32, op: BIR.Op, next: BIR.Block, p: U32, layouts: Map<&2, MultiLayout>, width: Nat, refs: List<&2, MultiRef>) -> Bool:
  match op:
    case BIR.HasTag{BIR.Local{known}, _, tag}: multi_tag_uses(U32.is_eq(known, p), test, next, p, layouts, width, refs, tag)
    case _: Bool.and(multi_op_uses(op, p, layouts, width, refs), multi_uses_of(next, p, layouts, width, refs))
def multi_tag_uses(own: Bool, test: U32, next: BIR.Block, p: U32, layouts: Map<&2, MultiLayout>, width: Nat, refs: List<&2, MultiRef>, tag: String) -> Bool:
  match own:
    case False{}: multi_uses_of(next, p, layouts, width, refs)
    case True{}: multi_tag_branch(test, next, p, layouts, width, refs, tag)
def multi_tag_branch(test: U32, next: BIR.Block, p: U32, layouts: Map<&2, MultiLayout>, width: Nat, refs: List<&2, MultiRef>, tag: String) -> Bool:
  match next:
    case BIR.Branch{BIR.Local{known}, yes, no}:
      multi_tag_arm(U32.is_eq(known, test), yes, no, p, layouts, width, refs, tag)
    case _: multi_uses_of(next, p, layouts, width, refs)
def multi_tag_arm(same: Bool, yes: BIR.Block, no: BIR.Block, p: U32, layouts: Map<&2, MultiLayout>, width: Nat, refs: List<&2, MultiRef>, tag: String) -> Bool:
  match same:
    case False{}: multi_uses_of(yes, p, layouts, width, refs)
    case True{}: Bool.and(multi_uses_of(yes, p, layouts, width, MultiRef{p, tag} <> refs), multi_uses_of(no, p, layouts, width, refs))
def multi_param_static(body: BIR.Block, p: U32, layouts: Map<&2, MultiLayout>, width: Nat) -> Bool:
  multi_uses_of(body, p, layouts, width, Nil{})

def multi_tail_targets(sites: List<&2, MultiSiteF>, acc: List<&2, U32>) -> List<&2, U32>:
  match sites:
    case Nil{}: List.reverse(&2, U32, acc)
    case MultiSiteF{_, callee, tail, _} <> rest: multi_tail_targets(rest, multi_tail_target(tail, callee, acc))
def multi_tail_target(tail: Bool, callee: U32, acc: List<&2, U32>) -> List<&2, U32>:
  match tail:
    case True{}: callee <> acc
    case False{}: acc
def multi_tails_multi(targets: List<&2, U32>, multi: Map<&2, Bool>) -> Bool:
  match targets:
    case Nil{}: True{}
    case +code <> rest: Bool.and(multi_multi_get(multi, code), multi_tails_multi(rest, multi))
def multi_rendered(items: List<&2, BIR.Parameter>, index: Nat, up: Map<&2, Bool>, code: U32, width: Nat, acc: Nat) -> Nat:
  match items:
    case Nil{}: acc
    case _ <> rest: multi_rendered(rest, (index + 1n : Nat), up, code, width, multi_rendered_one(multi_up_get(up, code, index), width, acc))
def multi_rendered_one(unboxed: Bool, width: Nat, acc: Nat) -> Nat:
  match unboxed:
    case True{}: Nat.add(acc, Nat.add(width, 1n))
    case False{}: Nat.add(acc, 1n)
def multi_arity_ok(code: BIR.Code, up: Map<&2, Bool>, width: Nat) -> Bool:
  match code:
    case BIR.Code{id, captures, parameters, _}:
      multi_arity_check(parameters, id, up, width, List.length(&2, BIR.Use, captures))
def multi_arity_check(parameters: List<&2, BIR.Parameter>, code: U32, up: Map<&2, Bool>, width: Nat, captured: Nat) -> Bool:
  multi_arity_count(multi_rendered(parameters, 0n, up, code, width, captured))
def multi_arity_count(rendered: Nat) -> Bool:
  Bool.and(Nat.is_gt(rendered, 0n), multi_arity_bound(Nat.add(rendered, 1n)))
def multi_arity_bound(count: Nat) -> Bool:
  Nat.is_le(count, 32n)
def multi_shape_open_at(shape: MultiShape, up: Map<&2, Bool>, caller: U32) -> Bool:
  match shape:
    case MultiCtorShape{_, _}: True{}
    case MultiParamShape{position}: multi_up_get(up, caller, position)
    case MultiResultShape{}: True{}
    case MultiOtherShape{}: False{}
def multi_forwards_ok(fwds: List<&2, MultiFwd>, up: Map<&2, Bool>) -> Bool:
  match fwds:
    case Nil{}: True{}
    case MultiFwd{caller, shape} <> rest: Bool.and(multi_shape_open_at(shape, up, caller), multi_forwards_ok(rest, up))
def multi_fwd_index(items: List<&2, BIR.Code>, sites: Map<&2, List<&2, MultiSiteF>>, acc: Map<&2, List<&2, MultiFwd>>) -> Map<&2, List<&2, MultiFwd>>:
  match items:
    case Nil{}: acc
    case code <> rest: multi_fwd_code(code, multi_sites_of(sites, code), rest, sites, acc)
def multi_sites_of(sites: Map<&2, List<&2, MultiSiteF>>, code: BIR.Code) -> List<&2, MultiSiteF>:
  match code:
    case BIR.Code{id, _, _, _}: multi_sites_found(IndexLookup.find(List<&2, MultiSiteF>, sites, U32.show(id)))
def multi_sites_found(found: Maybe<&2, List<&2, MultiSiteF>>) -> List<&2, MultiSiteF>:
  match found:
    case Some{items}: items
    case None{}: Nil{}
def multi_fwd_code(code: BIR.Code, sites: List<&2, MultiSiteF>, rest: List<&2, BIR.Code>, index: Map<&2, List<&2, MultiSiteF>>, acc: Map<&2, List<&2, MultiFwd>>) -> Map<&2, List<&2, MultiFwd>>:
  match code:
    case BIR.Code{id, _, _, _}: multi_fwd_index(rest, index, multi_fwd_sites(sites, id, acc))
def multi_fwd_sites(sites: List<&2, MultiSiteF>, caller: U32, acc: Map<&2, List<&2, MultiFwd>>) -> Map<&2, List<&2, MultiFwd>>:
  match sites:
    case Nil{}: acc
    case MultiSiteF{_, callee, _, shapes} <> rest: multi_fwd_sites(rest, caller, multi_fwd_shapes(shapes, callee, caller, 0n, acc))
def multi_fwd_shapes(shapes: List<&2, MultiShape>, callee: U32, caller: U32, position: Nat, acc: Map<&2, List<&2, MultiFwd>>) -> Map<&2, List<&2, MultiFwd>>:
  match shapes:
    case Nil{}: acc
    case +shape <> rest:
      multi_fwd_shapes(rest, callee, caller, (position + 1n : Nat), multi_fwd_add(acc, callee, position, MultiFwd{caller, shape}))
def multi_fwd_add(acc: Map<&2, List<&2, MultiFwd>>, callee: U32, position: Nat, item: MultiFwd) -> Map<&2, List<&2, MultiFwd>>:
  +key = multi_up_key(callee, position)
  multi_fwd_set(acc, key, IndexLookup.find(List<&2, MultiFwd>, acc, key), item)
def multi_fwd_set(acc: Map<&2, List<&2, MultiFwd>>, +key: String, found: Maybe<&2, List<&2, MultiFwd>>, item: MultiFwd) -> Map<&2, List<&2, MultiFwd>>:
  match found:
    case Some{items}: Map.set(&2, List<&2, MultiFwd>, acc, key, item <> items)
    case None{}: Map.set(&2, List<&2, MultiFwd>, acc, key, [item])

def multi_forwards_at(fwds: Map<&2, List<&2, MultiFwd>>, code: U32, position: Nat) -> List<&2, MultiFwd>:
  multi_forwards_found(IndexLookup.find(List<&2, MultiFwd>, fwds, multi_up_key(code, position)))
def multi_forwards_found(found: Maybe<&2, List<&2, MultiFwd>>) -> List<&2, MultiFwd>:
  match found:
    case Some{items}: items
    case None{}: Nil{}

type MultiCodeFact is Data:
  MultiCodeFact{width: Nat, sites: List<&2, MultiSiteF>, statics: Map<&2, Bool>, params: List<&2, BIR.Parameter>, captures: Nat, frames: Bool, pidx: Map<&2, Nat>, body: BIR.Block}

def multi_program_width(items: List<&2, BIR.Code>, width: Nat) -> Nat:
  match items:
    case Nil{}: width
    case code <> rest: multi_program_width(rest, multi_width_cap(multi_code_local_width(code), width))
def multi_code_local_width(code: BIR.Code) -> Nat:
  match code:
    case BIR.Code{_, _, _, body}: multi_local_width(body, 0n)
def multi_width_cap(local: Nat, width: Nat) -> Nat:
  multi_width_keep(Nat.is_le(local, 4n), local, width)
def multi_width_keep(small: Bool, local: Nat, width: Nat) -> Nat:
  match small:
    case True{}: Nat.max(local, width)
    case False{}: width

def multi_code_fact(code: BIR.Code, layouts: Map<&2, MultiLayout>, width: Nat) -> MultiCodeFact:
  match code:
    case BIR.Code{id, captures, parameters, body}:
      multi_code_fact_build(id, captures, parameters, body, layouts, width)
def multi_code_fact_build(id: U32, captures: List<&2, BIR.Use>, parameters: List<&2, BIR.Parameter>, body: BIR.Block, layouts: Map<&2, MultiLayout>, width: Nat) -> MultiCodeFact:
  +pidx = multi_param_index(parameters, 0n, Map.new(&2, Nat))
  +uses = multi_uses(body)
  +scan = multi_scan(body, MultiScan{Map.new(&2, MultiCtor), Nil{}}, layouts, uses, pidx, None{}, id)
  multi_fact_from_scan(scan, List.length(&2, BIR.Use, captures), parameters, pidx, body, layouts, width, id)
def multi_fact_from_scan(scan: MultiScan, captured: Nat, parameters: List<&2, BIR.Parameter>, pidx: Map<&2, Nat>, body: BIR.Block, layouts: Map<&2, MultiLayout>, width: Nat, id: U32) -> MultiCodeFact:
  match scan:
    case MultiScan{_, sites}:
      MultiCodeFact{width: multi_local_width(body, 0n), sites, statics: multi_statics(parameters, 0n, id, body, layouts, width, Map.new(&2, Bool)), params: parameters, captures: captured, frames: multi_frames_ok(body, plan_of(body)), pidx, body}
def multi_statics(items: List<&2, BIR.Parameter>, index: Nat, id: U32, body: BIR.Block, layouts: Map<&2, MultiLayout>, width: Nat, acc: Map<&2, Bool>) -> Map<&2, Bool>:
  match items:
    case Nil{}: acc
    case BIR.Parameter{pid, _} <> rest:
      multi_statics(rest, (index + 1n : Nat), id, body, layouts, width, Map.set(&2, Bool, acc, multi_up_key(id, index), multi_param_static(body, pid, layouts, width)))
def multi_fact_ups(fact: MultiCodeFact, id: U32, prev: MultiUp, banned: Map<&2, Bool>, fwds: Map<&2, List<&2, MultiFwd>>, acc: MultiUp) -> MultiUp:
  match fact:
    case MultiCodeFact{_, _, statics, params, _, _, _, _}:
      multi_ups_of(params, 0n, id, statics, prev, banned, fwds, acc)
def multi_ups_of(items: List<&2, BIR.Parameter>, index: Nat, id: U32, statics: Map<&2, Bool>, prev: MultiUp, banned: Map<&2, Bool>, fwds: Map<&2, List<&2, MultiFwd>>, acc: MultiUp) -> MultiUp:
  match items:
    case Nil{}: acc
    case _ <> rest:
      multi_ups_of(rest, (index + 1n : Nat), id, statics, prev, banned, fwds, multi_ups_set(acc, multi_up_key(id, index), multi_pos_up(statics, id, index, prev, banned, fwds)))
def multi_ups_set(acc: MultiUp, +key: String, flag: Bool) -> MultiUp:
  match acc:
    case MultiUp{up, multi}: MultiUp{Map.set(&2, Bool, up, key, flag), multi}
def multi_pos_up(statics: Map<&2, Bool>, id: U32, index: Nat, prev: MultiUp, banned: Map<&2, Bool>, fwds: Map<&2, List<&2, MultiFwd>>) -> Bool:
  multi_pos_up_static(multi_static_at(statics, id, index), id, index, prev, banned, fwds)
def multi_static_at(statics: Map<&2, Bool>, id: U32, index: Nat) -> Bool:
  multi_up_found(IndexLookup.find(Bool, statics, multi_up_key(id, index)))
def multi_pos_up_static(static: Bool, id: U32, index: Nat, prev: MultiUp, banned: Map<&2, Bool>, fwds: Map<&2, List<&2, MultiFwd>>) -> Bool:
  match static:
    case False{}: False{}
    case True{}: Bool.and(Bool.not(multi_banned(banned, id)), multi_forwards_ok(multi_forwards_at(fwds, id, index), multi_prev_up(prev)))
def multi_prev_up(prev: MultiUp) -> Map<&2, Bool>:
  match prev:
    case MultiUp{up, _}: up
def multi_prev_multi(prev: MultiUp) -> Map<&2, Bool>:
  match prev:
    case MultiUp{_, multi}: multi
def multi_fact_multi(fact: MultiCodeFact, id: U32, prev: MultiUp, banned: Map<&2, Bool>, width: Nat) -> Bool:
  match fact:
    case MultiCodeFact{fact_width, sites, _, params, captures, frames, pidx, body}:
      multi_fact_decided(Bool.not(multi_banned(banned, id)), id, body, fact_width, captures, frames, params, pidx, sites, prev, width)
def multi_fact_decided(free: Bool, id: U32, body: BIR.Block, fact_width: Nat, captures: Nat, frames: Bool, params: List<&2, BIR.Parameter>, pidx: Map<&2, Nat>, sites: List<&2, MultiSiteF>, prev: MultiUp, width: Nat) -> Bool:
  match free:
    case False{}: False{}
    case True{}: multi_fact_checked(id, body, fact_width, captures, frames, params, pidx, sites, prev, width)
def multi_fact_checked(id: U32, body: BIR.Block, fact_width: Nat, captures: Nat, frames: Bool, params: List<&2, BIR.Parameter>, pidx: Map<&2, Nat>, sites: List<&2, MultiSiteF>, prev: MultiUp, width: Nat) -> Bool:
  match frames:
    case False{}: False{}
    case True{}: multi_fact_result(id, body, fact_width, captures, params, pidx, sites, prev, width)
def multi_fact_result(id: U32, body: BIR.Block, fact_width: Nat, captures: Nat, params: List<&2, BIR.Parameter>, pidx: Map<&2, Nat>, sites: List<&2, MultiSiteF>, prev: MultiUp, width: Nat) -> Bool:
  multi_fact_shapes(multi_result_ok(body, multi_prev_up(prev), id, pidx), id, body, fact_width, captures, params, pidx, sites, prev, width)
def multi_fact_shapes(result: Bool, id: U32, body: BIR.Block, fact_width: Nat, captures: Nat, params: List<&2, BIR.Parameter>, pidx: Map<&2, Nat>, sites: List<&2, MultiSiteF>, prev: MultiUp, width: Nat) -> Bool:
  match result:
    case False{}: False{}
    case True{}: multi_fact_arity(multi_arity_check(params, id, multi_prev_up(prev), width, captures), fact_width, sites, prev)
def multi_fact_arity(arity: Bool, fact_width: Nat, sites: List<&2, MultiSiteF>, prev: MultiUp) -> Bool:
  match arity:
    case False{}: False{}
    case True{}: Bool.and(Nat.is_le(fact_width, 4n), multi_tails_multi(multi_tail_targets(sites, Nil{}), multi_prev_multi(prev)))
def multi_round(items: List<&2, BIR.Code>, facts: Map<&2, MultiCodeFact>, fwds: Map<&2, List<&2, MultiFwd>>, banned: Map<&2, Bool>, layouts: Map<&2, MultiLayout>, width: Nat, prev: MultiUp, acc: MultiUp) -> MultiUp:
  match items:
    case Nil{}: acc
    case code <> rest: multi_round_code(code, rest, facts, fwds, banned, layouts, width, prev, acc)
def multi_round_code(code: BIR.Code, rest: List<&2, BIR.Code>, facts: Map<&2, MultiCodeFact>, fwds: Map<&2, List<&2, MultiFwd>>, banned: Map<&2, Bool>, layouts: Map<&2, MultiLayout>, width: Nat, prev: MultiUp, acc: MultiUp) -> MultiUp:
  match code:
    case BIR.Code{id, _, _, _}: multi_round_fact(id, rest, multi_fact_of(facts, id), facts, fwds, banned, layouts, width, prev, acc)
def multi_fact_of(facts: Map<&2, MultiCodeFact>, id: U32) -> MultiCodeFact:
  match IndexLookup.find(MultiCodeFact, facts, U32.show(id)):
    case Some{+item}: item
    case None{}: MultiCodeFact{0n, Nil{}, Map.new(&2, Bool), Nil{}, 0n, False{}, Map.new(&2, Nat), BIR.Failure{""}}
def multi_round_fact(id: U32, rest: List<&2, BIR.Code>, fact: MultiCodeFact, facts: Map<&2, MultiCodeFact>, fwds: Map<&2, List<&2, MultiFwd>>, banned: Map<&2, Bool>, layouts: Map<&2, MultiLayout>, width: Nat, prev: MultiUp, acc: MultiUp) -> MultiUp:
  multi_round_next(rest, facts, fwds, banned, layouts, width, prev, multi_prev_add(multi_fact_ups(fact, id, prev, banned, fwds, acc), id, multi_fact_multi(fact, id, prev, banned, width)))
def multi_prev_add(acc: MultiUp, id: U32, flag: Bool) -> MultiUp:
  match acc:
    case MultiUp{up, multi}: MultiUp{up, Map.set(&2, Bool, multi, U32.show(id), flag)}
def multi_round_next(rest: List<&2, BIR.Code>, facts: Map<&2, MultiCodeFact>, fwds: Map<&2, List<&2, MultiFwd>>, banned: Map<&2, Bool>, layouts: Map<&2, MultiLayout>, width: Nat, prev: MultiUp, acc: MultiUp) -> MultiUp:
  multi_round(rest, facts, fwds, banned, layouts, width, prev, acc)
def multi_round_n(items: List<&2, BIR.Code>, facts: Map<&2, MultiCodeFact>, fwds: Map<&2, List<&2, MultiFwd>>, banned: Map<&2, Bool>, layouts: Map<&2, MultiLayout>, width: Nat, left: Nat, state: MultiUp) -> MultiUp:
  match Nat.is_gt(left, 0n):
    case True{}: multi_round_n(items, facts, fwds, banned, layouts, width, Nat.sub(left, 1n), multi_round(items, facts, fwds, banned, layouts, width, state, MultiUp{Map.new(&2, Bool), Map.new(&2, Bool)}))
    case False{}: state
# The loop starts from the optimistic candidate, never from the empty map: a
# position is assumed unboxed and a code is assumed multi, and each round removes
# only what its premises do not support. Starting empty would make every premise
# about a neighbour false on the first pass, so a self-forwarding tail recursion
# (chunk forwarding its own record parameter) or any mutually forwarding pair
# would never seed at all. Removal is monotone, so the iteration settles at the
# greatest fixed point the rules allow.
def multi_round_start(items: List<&2, BIR.Code>, facts: Map<&2, MultiCodeFact>, fwds: Map<&2, List<&2, MultiFwd>>, banned: Map<&2, Bool>, layouts: Map<&2, MultiLayout>, width: Nat) -> MultiUp:
  multi_round_n(items, facts, fwds, banned, layouts, width, 12n, multi_round_seed(items, Map.new(&2, Bool), Map.new(&2, Bool)))
def multi_round_seed(items: List<&2, BIR.Code>, multi: Map<&2, Bool>, up: Map<&2, Bool>) -> MultiUp:
  match items:
    case Nil{}: MultiUp{up, multi}
    case code <> rest: multi_round_seed_one(code, rest, multi, up)
def multi_round_seed_one(code: BIR.Code, rest: List<&2, BIR.Code>, multi: Map<&2, Bool>, up: Map<&2, Bool>) -> MultiUp:
  match code:
    case BIR.Code{id, _, parameters, _}:
      multi_round_seed(rest, Map.set(&2, Bool, multi, U32.show(id), True{}), multi_seed_ups(parameters, 0n, id, up))
def multi_seed_ups(items: List<&2, BIR.Parameter>, index: Nat, id: U32, up: Map<&2, Bool>) -> Map<&2, Bool>:
  match items:
    case Nil{}: up
    case _ <> rest: multi_seed_ups(rest, (index + 1n : Nat), id, Map.set(&2, Bool, up, multi_up_key(id, index), True{}))

type MRewCtx is Data:
  MRewCtx{code: U32, layouts: Map<&2, MultiLayout>, multi: Map<&2, Bool>, up: Map<&2, Bool>, width: Nat, params: Map<&2, MultiParam>, private: Bool, sub: Maybe<&2, MultiSubst>, cur: Maybe<&2, U32>, bindings: Map<&2, MultiCtor>, uses: Map<&2, Nat>}

def multi_param_get(params: Map<&2, MultiParam>, id: U32) -> Maybe<&2, MultiParam>:
  IndexLookup.find(MultiParam, params, U32.show(id))
def multi_param_unboxed(params: Map<&2, MultiParam>, id: U32) -> Bool:
  multi_param_unboxed_of(multi_param_get(params, id))
def multi_param_unboxed_of(found: Maybe<&2, MultiParam>) -> Bool:
  match found:
    case Some{MultiParam{_, unboxed, _, _}}: unboxed
    case None{}: False{}
def multi_param_tag(params: Map<&2, MultiParam>, id: U32) -> U32:
  multi_param_tag_of(multi_param_get(params, id), id)
def multi_param_tag_of(found: Maybe<&2, MultiParam>, id: U32) -> U32:
  match found:
    case Some{MultiParam{_, _, tag, _}}: tag
    case None{}: id
def multi_param_fields(params: Map<&2, MultiParam>, id: U32) -> List<&2, U32>:
  multi_param_fields_of(multi_param_get(params, id))
def multi_param_fields_of(found: Maybe<&2, MultiParam>) -> List<&2, U32>:
  match found:
    case Some{MultiParam{_, _, _, fields}}: fields
    case None{}: Nil{}

def multi_nth(items: List<&2, BIR.Atom>, index: Nat) -> BIR.Atom:
  match items:
    case Nil{}: BIR.Undefined{}
    case +item <> rest: multi_nth_step(Nat.is_eq(index, 0n), item, rest, index)
def multi_nth_step(here: Bool, item: BIR.Atom, rest: List<&2, BIR.Atom>, index: Nat) -> BIR.Atom:
  match here:
    case True{}: item
    case False{}: multi_nth(rest, Nat.sub(index, 1n))
def multi_atom_list(items: List<&2, U32>) -> List<&2, BIR.Atom>:
  match items:
    case Nil{}: Nil{}
    case +item <> rest: BIR.Local{item} <> multi_atom_list(rest)
def multi_pad(items: List<&2, BIR.Atom>, width: Nat) -> List<&2, BIR.Atom>:
  multi_pad_range(items, width, 0n, Nil{})
def multi_pad_range(items: List<&2, BIR.Atom>, width: Nat, index: Nat, acc: List<&2, BIR.Atom>) -> List<&2, BIR.Atom>:
  multi_pad_step(Nat.is_lt(index, width), items, width, index, acc)
def multi_pad_step(more: Bool, items: List<&2, BIR.Atom>, width: Nat, index: Nat, acc: List<&2, BIR.Atom>) -> List<&2, BIR.Atom>:
  match more:
    case False{}: List.reverse(&2, BIR.Atom, acc)
    case True{}: multi_pad_take(items, width, index, acc)
def multi_pad_take(items: List<&2, BIR.Atom>, width: Nat, index: Nat, acc: List<&2, BIR.Atom>) -> List<&2, BIR.Atom>:
  match items:
    case Nil{}: multi_pad_range(Nil{}, width, (index + 1n : Nat), BIR.Undefined{} <> acc)
    case +item <> rest: multi_pad_range(rest, width, (index + 1n : Nat), item <> acc)

# The tag plus the field words of one argument. A record literal is opened in its
# constructor's own field order, an unboxed parameter forwards its own words, and
# a window forwards the words its continuation already bound.
def multi_forward_atoms(value: BIR.Atom, layouts: Map<&2, MultiLayout>, params: Map<&2, MultiParam>, bindings: Map<&2, MultiCtor>, sub: Maybe<&2, MultiSubst>, width: Nat) -> List<&2, BIR.Atom>:
  match value:
    case BIR.Local{id}: multi_forward_local(id, layouts, params, bindings, sub, width)
    case _: multi_pad([value], width)
def multi_forward_local(id: U32, layouts: Map<&2, MultiLayout>, params: Map<&2, MultiParam>, bindings: Map<&2, MultiCtor>, sub: Maybe<&2, MultiSubst>, width: Nat) -> List<&2, BIR.Atom>:
  multi_forward_kind(multi_param_get(params, id), multi_binding(bindings, id), sub, id, layouts, params, width, bindings)
def multi_forward_kind(position: Maybe<&2, MultiParam>, binding: Maybe<&2, MultiCtor>, sub: Maybe<&2, MultiSubst>, id: U32, layouts: Map<&2, MultiLayout>, params: Map<&2, MultiParam>, width: Nat, bindings: Map<&2, MultiCtor>) -> List<&2, BIR.Atom>:
  match position:
    case Some{MultiParam{known, unboxed, tag, fields}}: multi_forward_flags(unboxed, tag, fields, binding, sub, id, layouts, params, width, bindings, known)
    case None{}: multi_forward_other(binding, sub, id, layouts, params, width, bindings)
def multi_forward_flags(unboxed: Bool, tag: U32, fields: List<&2, U32>, binding: Maybe<&2, MultiCtor>, sub: Maybe<&2, MultiSubst>, id: U32, layouts: Map<&2, MultiLayout>, params: Map<&2, MultiParam>, width: Nat, bindings: Map<&2, MultiCtor>, known: U32) -> List<&2, BIR.Atom>:
  match unboxed:
    case True{}: BIR.Local{tag} <> multi_pad(multi_atom_list(fields), width)
    case False{}: multi_forward_other(binding, sub, id, layouts, params, width, bindings)
def multi_forward_other(binding: Maybe<&2, MultiCtor>, sub: Maybe<&2, MultiSubst>, id: U32, layouts: Map<&2, MultiLayout>, params: Map<&2, MultiParam>, width: Nat, bindings: Map<&2, MultiCtor>) -> List<&2, BIR.Atom>:
  match binding:
    case Some{MultiCtor{_, tag, fields}}: BIR.TextValue{tag} <> multi_pad(multi_field_atoms(fields), width)
    case None{}: multi_forward_sub(sub, id, width)
def multi_field_atoms(fields: List<&2, BIR.Field>) -> List<&2, BIR.Atom>:
  match fields:
    case Nil{}: Nil{}
    case BIR.Field{_, _, _, value} <> rest: value <> multi_field_atoms(rest)
def multi_forward_sub(sub: Maybe<&2, MultiSubst>, id: U32, width: Nat) -> List<&2, BIR.Atom>:
  match sub:
    case Some{MultiSubst{known, tag, fields, param}}:
      multi_forward_window(U32.is_eq(known, id), tag, fields, width)
    case None{}: multi_pad(Nil{}, width)
def multi_forward_window(own: Bool, tag: BIR.Atom, fields: List<&2, BIR.Atom>, width: Nat) -> List<&2, BIR.Atom>:
  match own:
    case False{}: multi_pad(Nil{}, width)
    case True{}: tag <> multi_pad(fields, width)

# A position is required when the callee was proven to unbox it. The value then
# has to be openable from BIR alone; the caller's frame is never asked to read a
# field it did not already read.
def multi_open_arg(value: BIR.Atom, required: Bool, ctx: MRewCtx) -> Bool:
  match required:
    case False{}: True{}
    case True{}: multi_open_value(value, ctx)
def multi_open_value(value: BIR.Atom, ctx: MRewCtx) -> Bool:
  match value:
    case BIR.Local{id}: multi_open_local(id, ctx)
    case _: False{}
def multi_open_local(id: U32, ctx: MRewCtx) -> Bool:
  match ctx:
    case MRewCtx{_, layouts, _, _, width, params, private, sub, _, bindings, uses}:
      multi_open_kind(multi_param_get(params, id), multi_binding(bindings, id), sub, id, layouts, width, private, uses)
def multi_open_kind(position: Maybe<&2, MultiParam>, binding: Maybe<&2, MultiCtor>, sub: Maybe<&2, MultiSubst>, id: U32, layouts: Map<&2, MultiLayout>, width: Nat, private: Bool, uses: Map<&2, Nat>) -> Bool:
  match position:
    case Some{MultiParam{_, unboxed, _, _}}: multi_open_flags(unboxed, binding, sub, id, layouts, width, private, uses)
    case None{}: multi_open_other(binding, sub, id, layouts, width, private, uses)
def multi_open_flags(unboxed: Bool, binding: Maybe<&2, MultiCtor>, sub: Maybe<&2, MultiSubst>, id: U32, layouts: Map<&2, MultiLayout>, width: Nat, private: Bool, uses: Map<&2, Nat>) -> Bool:
  match unboxed:
    case True{}: True{}
    case False{}: multi_open_other(binding, sub, id, layouts, width, private, uses)
def multi_open_other(binding: Maybe<&2, MultiCtor>, sub: Maybe<&2, MultiSubst>, id: U32, layouts: Map<&2, MultiLayout>, width: Nat, private: Bool, uses: Map<&2, Nat>) -> Bool:
  match binding:
    case Some{MultiCtor{constructor, _, fields}}: multi_open_ctor(multi_ctor_openable(uses, layouts, id, constructor, fields), Nat.is_le(multi_field_width(fields), width))
    case None{}: multi_open_sub(sub, id, private)
def multi_open_ctor(openable: Bool, fits: Bool) -> Bool:
  Bool.and(openable, fits)
def multi_open_sub(sub: Maybe<&2, MultiSubst>, id: U32, private: Bool) -> Bool:
  match sub:
    case Some{MultiSubst{known, tag, fields, param}}: multi_open_window(U32.is_eq(known, id), param, fields)
    case None{}: False{}
def multi_open_window(own: Bool, param: Bool, fields: List<&2, BIR.Atom>) -> Bool:
  multi_open_window_step(own, param, fields)
def multi_open_window_step(own: Bool, param: Bool, fields: List<&2, BIR.Atom>) -> Bool:
  match own:
    case False{}: False{}
    case True{}: Bool.not(param)

def multi_args_open(args: List<&2, BIR.Arg>, callee: U32, ctx: MRewCtx) -> Bool:
  multi_args_open_at(args, callee, 0n, ctx)
def multi_args_open_at(args: List<&2, BIR.Arg>, callee: U32, index: Nat, ctx: MRewCtx) -> Bool:
  match args:
    case Nil{}: True{}
    case BIR.Arg{_, value} <> rest:
      multi_args_open_step(multi_open_arg(value, multi_up_get(multi_ctx_up(ctx), callee, index), ctx), rest, callee, index, ctx)
def multi_ctx_up(ctx: MRewCtx) -> Map<&2, Bool>:
  match ctx:
    case MRewCtx{_, _, _, up, _, _, _, _, _, _, _}: up
def multi_args_open_step(open: Bool, rest: List<&2, BIR.Arg>, callee: U32, index: Nat, ctx: MRewCtx) -> Bool:
  match open:
    case False{}: False{}
    case True{}: multi_args_open_at(rest, callee, (index + 1n : Nat), ctx)
def multi_expand_args(args: List<&2, BIR.Arg>, callee: U32, ctx: MRewCtx) -> List<&2, BIR.Arg>:
  multi_expand_at(args, callee, 0n, ctx)
def multi_expand_at(args: List<&2, BIR.Arg>, callee: U32, index: Nat, ctx: MRewCtx) -> List<&2, BIR.Arg>:
  match args:
    case Nil{}: Nil{}
    case BIR.Arg{use, value} <> rest:
      multi_expand_one(use, value, multi_up_get(multi_ctx_up(ctx), callee, index), rest, callee, index, ctx)
def multi_expand_one(use: BIR.Use, value: BIR.Atom, required: Bool, rest: List<&2, BIR.Arg>, callee: U32, index: Nat, ctx: MRewCtx) -> List<&2, BIR.Arg>:
  match required:
    case False{}: BIR.Arg{use, value} <> multi_expand_at(rest, callee, (index + 1n : Nat), ctx)
    case True{}: multi_expand_forward(use, value, rest, callee, index, ctx)
def multi_expand_forward(use: BIR.Use, value: BIR.Atom, rest: List<&2, BIR.Arg>, callee: U32, index: Nat, ctx: MRewCtx) -> List<&2, BIR.Arg>:
  match ctx:
    case MRewCtx{_, layouts, _, _, width, params, _, sub, _, bindings, _}:
      multi_expand_atoms(multi_forward_atoms(value, layouts, params, bindings, sub, width), use) <> multi_expand_at(rest, callee, (index + 1n : Nat), ctx)
def multi_expand_atoms(items: List<&2, BIR.Atom>, use: BIR.Use) -> List<&2, BIR.Arg>:
  match items:
    case Nil{}: Nil{}
    case +item <> rest: BIR.Arg{use, item} <> multi_expand_atoms(rest, use)
def multi_subst_args(args: List<&2, BIR.Arg>, ctx: MRewCtx) -> List<&2, BIR.Arg>:
  match args:
    case Nil{}: Nil{}
    case BIR.Arg{use, value} <> rest: BIR.Arg{use, multi_atom(value, ctx)} <> multi_subst_args(rest, ctx)
def multi_atom(value: BIR.Atom, ctx: MRewCtx) -> BIR.Atom:
  value

def multi_site_args(args: List<&2, BIR.Arg>, callee: U32, id: U32, ctx: MRewCtx, index: Nat) -> Bool:
  match args:
    case Nil{}: True{}
    case BIR.Arg{_, value} <> rest:
      multi_site_arg(multi_names(value, id), multi_up_get(multi_ctx_up(ctx), callee, index), rest, callee, id, ctx, index)
def multi_site_arg(named: Bool, required: Bool, rest: List<&2, BIR.Arg>, callee: U32, id: U32, ctx: MRewCtx, index: Nat) -> Bool:
  match named:
    case False{}: multi_site_args(rest, callee, id, ctx, (index + 1n : Nat))
    case True{}: multi_site_arg_required(required, rest, callee, id, ctx, index)
def multi_site_arg_required(required: Bool, rest: List<&2, BIR.Arg>, callee: U32, id: U32, ctx: MRewCtx, index: Nat) -> Bool:
  match required:
    case True{}: multi_site_args(rest, callee, id, ctx, (index + 1n : Nat))
    case False{}: False{}
def multi_site_op(op: BIR.Op, id: U32, ctx: MRewCtx, refs: List<&2, MultiRef>) -> Bool:
  match op:
    case BIR.Project{value, constructor, _, key}: multi_site_project(value, constructor, key, id, ctx, refs)
    case BIR.HasTag{value, _, _}: Bool.not(multi_names(value, id))
    case BIR.Direct{callee, args}: multi_site_args(args, callee, id, ctx, 0n)
    case BIR.Copy{value}: Bool.not(multi_names(value, id))
    case BIR.PrimitiveCall{_, args, _}: Bool.not(multi_args_name(args, id))
    case BIR.Closure{_, captures, _}: Bool.not(multi_args_name(captures, id))
    case BIR.Apply{fn, arg}: Bool.not(multi_arg_names(fn, arg, id))
    case BIR.LoadSymbol{_, _}: True{}
    case BIR.Construct{_, _, fields}: Bool.not(multi_fields_name(fields, id))
def multi_site_project(value: BIR.Atom, constructor: U32, key: String, id: U32, ctx: MRewCtx, refs: List<&2, MultiRef>) -> Bool:
  match value:
    case BIR.Local{known}: multi_site_project_local(U32.is_eq(known, id), constructor, key, id, ctx, refs)
    case _: True{}
def multi_site_project_local(same: Bool, constructor: U32, key: String, id: U32, ctx: MRewCtx, refs: List<&2, MultiRef>) -> Bool:
  match same:
    case False{}: True{}
    case True{}:
      match ctx:
        case MRewCtx{_, layouts, _, _, width, _, _, _, _, _, _}: multi_project_ok(BIR.Local{id}, constructor, key, layouts, width, refs, id)
def multi_site_uses(body: BIR.Block, id: U32, ctx: MRewCtx, refs: List<&2, MultiRef>) -> Bool:
  match body:
    case BIR.Return{value}: Bool.not(multi_names(value, id))
    case BIR.Let{test, op, next}: multi_site_let(test, op, next, id, ctx, refs)
    case BIR.Branch{condition, yes, no}: Bool.and(Bool.not(multi_names(condition, id)), Bool.and(multi_site_uses(yes, id, ctx, refs), multi_site_uses(no, id, ctx, refs)))
    case BIR.Region{_, inner, next}: Bool.and(multi_site_uses(inner, id, ctx, refs), multi_site_uses(next, id, ctx, refs))
    case BIR.LeaveRegion{_}: True{}
    case BIR.TailDirect{callee, args}: multi_site_args(args, callee, id, ctx, 0n)
    case BIR.TailApply{fn, arg}: Bool.not(multi_arg_names(fn, arg, id))
    case BIR.Failure{_}: True{}
def multi_site_let(test: U32, op: BIR.Op, next: BIR.Block, id: U32, ctx: MRewCtx, refs: List<&2, MultiRef>) -> Bool:
  match op:
    case BIR.HasTag{BIR.Local{known}, _, tag}: multi_site_tag(U32.is_eq(known, id), test, next, id, ctx, refs, tag)
    case _: Bool.and(multi_site_op(op, id, ctx, refs), multi_site_uses(next, id, ctx, refs))
def multi_site_tag(own: Bool, test: U32, next: BIR.Block, id: U32, ctx: MRewCtx, refs: List<&2, MultiRef>, tag: String) -> Bool:
  match own:
    case False{}: multi_site_uses(next, id, ctx, refs)
    case True{}: multi_site_tag_branch(test, next, id, ctx, refs, tag)
def multi_site_tag_branch(test: U32, next: BIR.Block, id: U32, ctx: MRewCtx, refs: List<&2, MultiRef>, tag: String) -> Bool:
  match next:
    case BIR.Branch{BIR.Local{known}, yes, no}: multi_site_tag_arm(U32.is_eq(known, test), yes, no, id, ctx, refs, tag)
    case _: multi_site_uses(next, id, ctx, refs)
def multi_site_tag_arm(same: Bool, yes: BIR.Block, no: BIR.Block, id: U32, ctx: MRewCtx, refs: List<&2, MultiRef>, tag: String) -> Bool:
  match same:
    case False{}: multi_site_uses(yes, id, ctx, refs)
    case True{}: Bool.and(multi_site_uses(yes, id, ctx, MultiRef{id, tag} <> refs), multi_site_uses(no, id, ctx, refs))

def multi_slot_at(keys: List<&2, String>, key: String) -> Nat:
  multi_slot_of(multi_key_at(keys, key, 0n))
def multi_slot_of(found: Maybe<&2, Nat>) -> Nat:
  match found:
    case Some{index}: index
    case None{}: 0n
def multi_op_rewrite(op: BIR.Op, ctx: MRewCtx) -> BIR.Op:
  match op:
    case BIR.Project{value, constructor, field, key}: multi_project_rewrite(value, constructor, field, key, ctx)
    case BIR.HasTag{value, constructor, tag}: multi_has_tag_rewrite(value, constructor, tag, ctx)
    case BIR.Copy{value}: BIR.Copy{multi_atom(value, ctx)}
    case BIR.PrimitiveCall{primitive, args, types}: BIR.PrimitiveCall{primitive, multi_subst_args(args, ctx), types}
    case BIR.Closure{code, captures, parameters}: BIR.Closure{code, multi_subst_args(captures, ctx), parameters}
    case BIR.Direct{code, args}: BIR.Direct{code, multi_subst_args(args, ctx)}
    case BIR.Apply{fn, arg}: BIR.Apply{multi_atom(fn, ctx), multi_subst_arg(arg, ctx)}
    case BIR.LoadSymbol{id, key}: BIR.LoadSymbol{id, key}
    case BIR.Construct{constructor, tag, fields}: BIR.Construct{constructor, tag, multi_subst_fields(fields, ctx)}
def multi_subst_arg(arg: BIR.Arg, ctx: MRewCtx) -> BIR.Arg:
  match arg:
    case BIR.Arg{use, value}: BIR.Arg{use, multi_atom(value, ctx)}
def multi_subst_fields(fields: List<&2, BIR.Field>, ctx: MRewCtx) -> List<&2, BIR.Field>:
  match fields:
    case Nil{}: Nil{}
    case BIR.Field{identity, key, use, value} <> rest: BIR.Field{identity, key, use, multi_atom(value, ctx)} <> multi_subst_fields(rest, ctx)
def multi_project_rewrite(value: BIR.Atom, constructor: U32, field: U32, key: String, ctx: MRewCtx) -> BIR.Op:
  match value:
    case BIR.Local{known}: multi_project_local_rewrite(known, constructor, field, key, ctx)
    case _: BIR.Project{multi_atom(value, ctx), constructor, field, key}
def multi_project_local_rewrite(known: U32, constructor: U32, field: U32, key: String, ctx: MRewCtx) -> BIR.Op:
  match ctx:
    case MRewCtx{_, layouts, _, _, _, params, _, sub, _, _, _}:
      multi_project_choose(multi_param_get(params, known), sub, known, layouts, constructor, field, key)
def multi_project_choose(position: Maybe<&2, MultiParam>, sub: Maybe<&2, MultiSubst>, known: U32, layouts: Map<&2, MultiLayout>, constructor: U32, field: U32, key: String) -> BIR.Op:
  match position:
    case Some{MultiParam{_, unboxed, _, fields}}: multi_project_flags(unboxed, fields, sub, known, layouts, constructor, field, key)
    case None{}: multi_project_sub(sub, known, layouts, constructor, field, key)
def multi_project_flags(unboxed: Bool, fields: List<&2, U32>, sub: Maybe<&2, MultiSubst>, known: U32, layouts: Map<&2, MultiLayout>, constructor: U32, field: U32, key: String) -> BIR.Op:
  match unboxed:
    case True{}: BIR.Copy{multi_nth(multi_atom_list(fields), multi_slot_at(multi_layout_keys(layouts, constructor), key))}
    case False{}: multi_project_sub(sub, known, layouts, constructor, field, key)
def multi_project_sub(sub: Maybe<&2, MultiSubst>, known: U32, layouts: Map<&2, MultiLayout>, constructor: U32, field: U32, key: String) -> BIR.Op:
  match sub:
    case Some{MultiSubst{id, _, fields, _}}:
      multi_project_window(U32.is_eq(id, known), fields, layouts, constructor, field, key)
    case None{}: BIR.Project{BIR.Local{known}, constructor, field, key}
def multi_project_sub(sub: Maybe<&2, MultiSubst>, known: U32, layouts: Map<&2, MultiLayout>, constructor: U32, field: U32, key: String) -> BIR.Op:
  match sub:
    case Some{MultiSubst{id, _, fields, _}}:
      multi_project_window(U32.is_eq(id, known), BIR.Local{known}, fields, layouts, constructor, field, key)
    case None{}: BIR.Project{BIR.Local{known}, constructor, field, key}
def multi_project_window(own: Bool, value: BIR.Atom, fields: List<&2, BIR.Atom>, layouts: Map<&2, MultiLayout>, constructor: U32, field: U32, key: String) -> BIR.Op:
  match own:
    case False{}: BIR.Project{value, constructor, field, key}
    case True{}: BIR.Copy{multi_nth(fields, multi_slot_at(multi_layout_keys(layouts, constructor), key))}
def multi_has_tag_rewrite(value: BIR.Atom, constructor: U32, tag: String, ctx: MRewCtx) -> BIR.Op:
  match value:
    case BIR.Local{known}: multi_has_tag_local(known, constructor, tag, ctx)
    case _: BIR.HasTag{multi_atom(value, ctx), constructor, tag}
def multi_has_tag_local(known: U32, constructor: U32, tag: String, ctx: MRewCtx) -> BIR.Op:
  match ctx:
    case MRewCtx{_, _, _, _, _, params, _, sub, _, _, _}:
      multi_has_tag_choose(multi_param_get(params, known), sub, known, constructor, tag)
def multi_has_tag_choose(position: Maybe<&2, MultiParam>, sub: Maybe<&2, MultiSubst>, known: U32, constructor: U32, tag: String) -> BIR.Op:
  match position:
    case Some{MultiParam{_, unboxed, tagid, _}}: multi_has_tag_flags(unboxed, tagid, sub, known, constructor, tag)
    case None{}: multi_has_tag_sub(sub, known, constructor, tag)
def multi_has_tag_flags(unboxed: Bool, tagid: U32, sub: Maybe<&2, MultiSubst>, known: U32, constructor: U32, tag: String) -> BIR.Op:
  match unboxed:
    case True{}: multi_tag_eq(BIR.Local{tagid}, tag, constructor)
    case False{}: multi_has_tag_sub(sub, known, constructor, tag)
def multi_has_tag_sub(sub: Maybe<&2, MultiSubst>, known: U32, constructor: U32, tag: String) -> BIR.Op:
  match sub:
    case Some{MultiSubst{id, _, _, _}}: multi_has_tag_window(U32.is_eq(id, known), known, constructor, tag)
    case None{}: BIR.HasTag{BIR.Local{known}, constructor, tag}
def multi_has_tag_window(own: Bool, known: U32, constructor: U32, tag: String) -> BIR.Op:
  match own:
    case False{}: BIR.HasTag{BIR.Local{known}, constructor, tag}
    case True{}: multi_tag_eq(BIR.Local{known}, tag, constructor)
def multi_tag_eq(value: BIR.Atom, tag: String, constructor: U32) -> BIR.Op:
  BIR.PrimitiveCall{BIR.PrimStringEq{}, [BIR.Arg{BIR.Many{}, value}, BIR.Arg{BIR.Many{}, BIR.TextValue{tag}}], Nil{}}

def multi_site_private(callee: U32, args: List<&2, BIR.Arg>, next: BIR.Block, id: U32, ctx: MRewCtx) -> Bool:
  Bool.and(multi_multi_get(multi_ctx_multi(ctx), callee), Bool.and(multi_args_open(args, callee, ctx), multi_site_uses(next, id, ctx, Nil{})))
def multi_ctx_multi(ctx: MRewCtx) -> Map<&2, Bool>:
  match ctx:
    case MRewCtx{_, _, multi, _, _, _, _, _, _, _, _}: multi
def multi_ctx_private(ctx: MRewCtx) -> Bool:
  match ctx:
    case MRewCtx{_, _, _, _, _, _, private, _, _, _, _}: private
def multi_counter_id(seed: Nat) -> U32:
  U32.add(U32.from_nat(seed), U32.from_nat(2013265920n))
def multi_return_param(value: BIR.Atom, ctx: MRewCtx) -> Bool:
  match value:
    case BIR.Local{id}: Bool.and(multi_ctx_private(ctx), multi_param_unboxed(multi_ctx_params(ctx), id))
    case _: False{}
def multi_ctx_params(ctx: MRewCtx) -> Map<&2, MultiParam>:
  match ctx:
    case MRewCtx{_, _, _, _, _, params, _, _, _, _, _}: params
def multi_ctx_layouts(ctx: MRewCtx) -> Map<&2, MultiLayout>:
  match ctx:
    case MRewCtx{_, layouts, _, _, _, _, _, _, _, _, _}: layouts
def multi_ctx_width(ctx: MRewCtx) -> Nat:
  match ctx:
    case MRewCtx{_, _, _, _, width, _, _, _, _, _, _}: width
def multi_ctx_bindings(ctx: MRewCtx) -> Map<&2, MultiCtor>:
  match ctx:
    case MRewCtx{_, _, _, _, _, _, _, _, _, bindings, _}: bindings
def multi_ctx_uses(ctx: MRewCtx) -> Map<&2, Nat>:
  match ctx:
    case MRewCtx{_, _, _, _, _, _, _, _, _, _, uses}: uses
def multi_ctx_sub(ctx: MRewCtx) -> Maybe<&2, MultiSubst>:
  match ctx:
    case MRewCtx{_, _, _, _, _, _, _, sub, _, _, _}: sub
def multi_ctx_cur(ctx: MRewCtx) -> Maybe<&2, U32>:
  match ctx:
    case MRewCtx{_, _, _, _, _, _, _, _, cur, _, _}: cur

def multi_window_fields(seed: U32, width: Nat) -> List<&2, BIR.Atom>:
  multi_atom_list(multi_fresh_ids(seed, width))

def multi_rewrite(body: BIR.Block, ctx: MRewCtx, seed: Nat) -> MultiRew:
  match body:
    case BIR.Return{value}: MultiRew{body, Map.new(&2, MultiWindow), Map.new(&2, Bool), Map.new(&2, Bool), Map.new(&2, Bool), False{}, multi_return_param(value, ctx), seed}
    case BIR.Let{id, op, next}: multi_rewrite_let(id, op, next, ctx, seed)
    case BIR.Branch{condition, yes, no}: multi_rewrite_branch(condition, yes, no, ctx, seed)
    case BIR.Region{label, inner, next}: multi_rewrite_region(label, inner, next, ctx, seed)
    case BIR.LeaveRegion{_}: MultiRew{body, Map.new(&2, MultiWindow), Map.new(&2, Bool), Map.new(&2, Bool), Map.new(&2, Bool), False{}, False{}, seed}
    case BIR.TailDirect{code, args}: multi_rewrite_tail(code, args, ctx, seed)
    case BIR.TailApply{fn, arg}: MultiRew{BIR.TailApply{multi_atom(fn, ctx), multi_subst_arg(arg, ctx)}, Map.new(&2, MultiWindow), Map.new(&2, Bool), Map.new(&2, Bool), Map.new(&2, Bool), False{}, False{}, seed}
    case BIR.Failure{message}: MultiRew{body, Map.new(&2, MultiWindow), Map.new(&2, Bool), Map.new(&2, Bool), Map.new(&2, Bool), False{}, False{}, seed}
def multi_rewrite_let(id: U32, op: BIR.Op, next: BIR.Block, ctx: MRewCtx, seed: Nat) -> MultiRew:
  match op:
    case BIR.Construct{constructor, tag, fields}: multi_rewrite_construct(id, constructor, tag, fields, next, ctx, seed)
    case BIR.Direct{code, args}: multi_rewrite_direct(id, code, args, next, ctx, seed)
    case BIR.Apply{fn, arg}: multi_rewrite_apply(id, fn, arg, next, ctx, seed)
    case _: multi_rewrite_op(id, op, next, ctx, seed)
def multi_rewrite_construct(id: U32, constructor: U32, tag: String, fields: List<&2, BIR.Field>, next: BIR.Block, ctx: MRewCtx, seed: Nat) -> MultiRew:
  match ctx:
    case MRewCtx{code, layouts, multi, up, width, params, private, sub, _, bindings, uses}:
      multi_rewrite_construct_bind(id, constructor, tag, fields, next, MRewCtx{code, layouts, multi, up, width, params, private, sub, multi_ctx_cur(ctx), Map.set(&2, MultiCtor, bindings, U32.show(id), MultiCtor{constructor, tag, fields}), uses}, seed)
def multi_rewrite_construct_bind(id: U32, constructor: U32, tag: String, fields: List<&2, BIR.Field>, next: BIR.Block, ctx: MRewCtx, seed: Nat) -> MultiRew:
  +b = BIR.Construct{constructor, tag, fields}
  +r = multi_rewrite(next, ctx, seed)
  multi_rew_make(BIR.Let{id, b, r.body}, r, multi_window_result(id, next, ctx, r.own_mr))
def multi_window_result(id: U32, next: BIR.Block, ctx: MRewCtx, own: Bool) -> Bool:
  match next:
    case BIR.Return{BIR.Local{known}}: multi_window_result_same(Bool.and(U32.is_eq(known, id), multi_ctx_private(ctx)), own)
    case _: own
def multi_window_result_same(same: Bool, own: Bool) -> Bool:
  match same:
    case True{}: True{}
    case False{}: own
def multi_rew_make(body: BIR.Block, r: MultiRew, own: Bool) -> MultiRew:
  match r:
    case MultiRew{_, windows, sites, mr, dropped, failed, _, next}:
      MultiRew{body, windows, sites, mr, dropped, failed, own, next}
def multi_rewrite_direct(id: U32, code: U32, args: List<&2, BIR.Arg>, next: BIR.Block, ctx: MRewCtx, seed: Nat) -> MultiRew:
  multi_rewrite_direct_decide(multi_site_private(code, args, next, id, ctx), id, code, args, next, ctx, seed)
def multi_rewrite_direct_decide(priv: Bool, id: U32, code: U32, args: List<&2, BIR.Arg>, next: BIR.Block, ctx: MRewCtx, seed: Nat) -> MultiRew:
  match priv:
    case True{}: multi_rewrite_direct_private(id, code, args, next, ctx, seed)
    case False{}: multi_rewrite_direct_pub(id, code, args, next, ctx, seed)
def multi_rewrite_direct_private(id: U32, code: U32, args: List<&2, BIR.Arg>, next: BIR.Block, ctx: MRewCtx, seed: Nat) -> MultiRew:
  match ctx:
    case MRewCtx{code: owner, layouts, multi, up, width, params, private, _, _, bindings, uses}:
      multi_rewrite_direct_body(id, code, args, next, MRewCtx{owner, layouts, multi, up, width, params, private, Some{MultiSubst{id, BIR.Local{id}, multi_window_fields(id, width), False{}}}, Some{id}, bindings, uses}, seed, True{})
def multi_rewrite_direct_pub(id: U32, code: U32, args: List<&2, BIR.Arg>, next: BIR.Block, ctx: MRewCtx, seed: Nat) -> MultiRew:
  match ctx:
    case MRewCtx{code: owner, layouts, multi, up, width, params, private, sub, _, bindings, uses}:
      multi_rewrite_direct_body(id, code, args, next, MRewCtx{owner, layouts, multi, up, width, params, private, sub, Some{id}, bindings, uses}, seed, False{})
def multi_rewrite_direct_body(id: U32, code: U32, args: List<&2, BIR.Arg>, next: BIR.Block, ctx: MRewCtx, seed: Nat, priv: Bool) -> MultiRew:
  +r = multi_rewrite(next, ctx, seed)
  multi_rewrite_site(id, code, args, r, ctx, priv)
def multi_rewrite_site(id: U32, code: U32, args: List<&2, BIR.Arg>, r: MultiRew, ctx: MRewCtx, priv: Bool) -> MultiRew:
  match r:
    case MultiRew{body, windows, sites, mr, dropped, failed, own, next}:
      multi_rewrite_site_applied(id, code, args, body, windows, sites, mr, dropped, failed, own, next, ctx, priv)
def multi_rewrite_site_applied(id: U32, code: U32, args: List<&2, BIR.Arg>, body: BIR.Block, windows: Map<&2, MultiWindow>, sites: Map<&2, Bool>, mr: Map<&2, Bool>, dropped: Map<&2, Bool>, failed: Bool, own: Bool, seed: Nat, ctx: MRewCtx, priv: Bool) -> MultiRew:
  +key = cat(["k", U32.show(id)])
  multi_rewrite_site_route(priv, id, code, args, body, windows, sites, mr, dropped, failed, own, seed, ctx, key)
def multi_rewrite_site_route(priv: Bool, id: U32, code: U32, args: List<&2, BIR.Arg>, body: BIR.Block, windows: Map<&2, MultiWindow>, sites: Map<&2, Bool>, mr: Map<&2, Bool>, dropped: Map<&2, Bool>, failed: Bool, own: Bool, seed: Nat, ctx: MRewCtx, +key: String) -> MultiRew:
  match priv:
    case False{}:
      MultiRew{BIR.Let{id, BIR.Direct{code, multi_subst_args(args, ctx)}, body}, windows, Map.set(&2, Bool, sites, key, False{}), mr, dropped, Bool.or(failed, Bool.and(own, Bool.not(multi_ctx_private(ctx)))), False{}, seed}
    case True{}:
      MultiRew{BIR.Let{id, BIR.Direct{code, multi_expand_args(args, code, ctx)}, body}, Map.set(&2, MultiWindow, windows, key, MultiWindow{multi_ctx_width(ctx), multi_fresh_ids(id, multi_ctx_width(ctx)), None{}}), Map.set(&2, Bool, sites, key, True{}), Map.set(&2, Bool, mr, key, own), dropped, Bool.or(failed, Bool.and(own, Bool.not(multi_ctx_private(ctx)))), own, seed}
def multi_rewrite_apply(id: U32, fn: BIR.Atom, arg: BIR.Arg, next: BIR.Block, ctx: MRewCtx, seed: Nat) -> MultiRew:
  +r = multi_rewrite(next, ctx, seed)
  multi_rewrite_apply_made(id, fn, arg, r, ctx)
def multi_rewrite_apply_made(id: U32, fn: BIR.Atom, arg: BIR.Arg, r: MultiRew, ctx: MRewCtx) -> MultiRew:
  match r:
    case MultiRew{body, windows, sites, mr, dropped, failed, own, next}:
      MultiRew{BIR.Let{id, BIR.Apply{multi_atom(fn, ctx), multi_subst_arg(arg, ctx)}, body}, windows, sites, mr, dropped, failed, own, next}
def multi_rewrite_op(id: U32, op: BIR.Op, next: BIR.Block, ctx: MRewCtx, seed: Nat) -> MultiRew:
  +r = multi_rewrite(next, ctx, seed)
  multi_rewrite_op_made(id, op, r, ctx)
def multi_rewrite_op_made(id: U32, op: BIR.Op, r: MultiRew, ctx: MRewCtx) -> MultiRew:
  match r:
    case MultiRew{body, windows, sites, mr, dropped, failed, own, next}:
      MultiRew{BIR.Let{id, multi_op_rewrite(op, ctx), body}, windows, sites, mr, dropped, failed, own, next}
def multi_rewrite_branch(condition: BIR.Atom, yes: BIR.Block, no: BIR.Block, ctx: MRewCtx, seed: Nat) -> MultiRew:
  multi_rewrite_branch_join(condition, multi_rewrite(yes, ctx, seed), no, ctx, seed)
def multi_rewrite_branch_join(condition: BIR.Atom, r1: MultiRew, no: BIR.Block, ctx: MRewCtx, seed: Nat) -> MultiRew:
  match r1:
    case MultiRew{yb, w1, s1, m1, d1, f1, o1, seed2}:
      multi_rewrite_branch_finish(condition, yb, w1, s1, m1, d1, f1, o1, ctx, multi_rewrite(no, ctx, seed2))
def multi_rewrite_branch_finish(condition: BIR.Atom, yb: BIR.Block, w1: Map<&2, MultiWindow>, s1: Map<&2, Bool>, m1: Map<&2, Bool>, d1: Map<&2, Bool>, f1: Bool, o1: Bool, ctx: MRewCtx, r2: MultiRew) -> MultiRew:
  match r2:
    case MultiRew{nb, w2, s2, m2, d2, f2, o2, next}:
      MultiRew{BIR.Branch{condition, yb, nb}, Map.union(&2, MultiWindow, w1, w2), Map.union(&2, Bool, s1, s2), Map.union(&2, Bool, m1, m2), Map.union(&2, Bool, d1, d2), Bool.or(f1, f2), Bool.or(o1, o2), next}
def multi_rewrite_region(label: U32, inner: BIR.Block, next: BIR.Block, ctx: MRewCtx, seed: Nat) -> MultiRew:
  multi_rewrite_region_join(label, next, ctx, multi_rewrite(inner, ctx, seed))
def multi_rewrite_region_join(label: U32, next: BIR.Block, ctx: MRewCtx, r1: MultiRew) -> MultiRew:
  match r1:
    case MultiRew{ib, w1, s1, m1, d1, f1, o1, seed2}:
      multi_rewrite_region_finish(label, ib, w1, s1, m1, d1, f1, o1, ctx, multi_rewrite(next, ctx, seed2))
def multi_rewrite_region_finish(label: U32, ib: BIR.Block, w1: Map<&2, MultiWindow>, s1: Map<&2, Bool>, m1: Map<&2, Bool>, d1: Map<&2, Bool>, f1: Bool, o1: Bool, ctx: MRewCtx, r2: MultiRew) -> MultiRew:
  match r2:
    case MultiRew{nb, w2, s2, m2, d2, f2, o2, next2}:
      MultiRew{BIR.Region{label, ib, nb}, Map.union(&2, MultiWindow, w1, w2), Map.union(&2, Bool, s1, s2), Map.union(&2, Bool, m1, m2), Map.union(&2, Bool, d1, d2), Bool.or(f1, f2), Bool.or(o1, o2), next2}
def multi_rewrite_tail(code: U32, args: List<&2, BIR.Arg>, ctx: MRewCtx, seed: Nat) -> MultiRew:
  multi_rewrite_tail_private(multi_ctx_private(ctx), code, args, ctx, seed)
def multi_rewrite_tail_private(priv: Bool, code: U32, args: List<&2, BIR.Arg>, ctx: MRewCtx, seed: Nat) -> MultiRew:
  match priv:
    case True{}:
      MultiRew{BIR.TailDirect{code, multi_tail_expand(code, args, ctx)}, Map.new(&2, MultiWindow), Map.new(&2, Bool), Map.new(&2, Bool), Map.new(&2, Bool), Bool.not(multi_args_open(args, code, ctx)), True{}, seed}
    case False{}: multi_rewrite_tail_convert(multi_tail_convertible(code, args, ctx), code, args, ctx, seed)
def multi_tail_expand(code: U32, args: List<&2, BIR.Arg>, ctx: MRewCtx) -> List<&2, BIR.Arg>:
  multi_expand_args(args, code, ctx)
def multi_tail_convertible(code: U32, args: List<&2, BIR.Arg>, ctx: MRewCtx) -> Bool:
  Bool.and(multi_multi_get(multi_ctx_multi(ctx), code), Bool.and(multi_args_open(args, code, ctx), multi_tail_arity_ok(args, code, ctx)))
def multi_tail_arity_ok(args: List<&2, BIR.Arg>, code: U32, ctx: MRewCtx) -> Bool:
  multi_arity_bound(Nat.add(multi_expanded_count(args, code, ctx, 0n), 1n))
def multi_expanded_count(args: List<&2, BIR.Arg>, code: U32, ctx: MRewCtx, index: Nat) -> Nat:
  match args:
    case Nil{}: 0n
    case _ <> rest: Nat.add(multi_expanded_one(multi_up_get(multi_ctx_up(ctx), code, index), ctx), multi_expanded_count(rest, code, (index + 1n : Nat), ctx))
def multi_expanded_one(required: Bool, ctx: MRewCtx) -> Nat:
  match required:
    case True{}: Nat.add(multi_ctx_width(ctx), 1n)
    case False{}: 1n
def multi_rewrite_tail_convert(convert: Bool, code: U32, args: List<&2, BIR.Arg>, ctx: MRewCtx, seed: Nat) -> MultiRew:
  match convert:
    case False{}: multi_rewrite_tail_pub(code, args, ctx, seed)
    case True{}: multi_rewrite_tail_converted(code, args, ctx, seed)
def multi_rewrite_tail_pub(code: U32, args: List<&2, BIR.Arg>, ctx: MRewCtx, seed: Nat) -> MultiRew:
  MultiRew{BIR.TailDirect{code, multi_subst_args(args, ctx)}, Map.new(&2, MultiWindow), Map.new(&2, Bool), Map.new(&2, Bool), Map.new(&2, Bool), multi_args_sub_named(args, ctx), False{}, seed}
def multi_args_sub_named(args: List<&2, BIR.Arg>, ctx: MRewCtx) -> Bool:
  match multi_ctx_sub(ctx):
    case Some{MultiSubst{id, _, _, _}}: multi_args_name(args, id)
    case None{}: False{}
def multi_rewrite_tail_converted(code: U32, args: List<&2, BIR.Arg>, ctx: MRewCtx, seed: Nat) -> MultiRew:
  +cid = multi_counter_id(seed)
  +bid = U32.inc(cid)
  +key = cat(["k", U32.show(cid)])
  +win = MultiWindow{multi_ctx_width(ctx), Nil{}, Some{bid}}
  MultiRew{BIR.Let{cid, BIR.Direct{code, multi_expand_args(args, code, ctx)}, BIR.Return{BIR.Local{bid}}}, Map.set(&2, MultiWindow, Map.new(&2, MultiWindow), key, win), Map.set(&2, Bool, Map.new(&2, Bool), key, True{}), Map.set(&2, Bool, Map.new(&2, Bool), key, False{}), Map.new(&2, Bool), False{}, False{}, Nat.add(seed, 2n)}

# A split writes the continuation's captures above the private stack pointer
# and hands the callee and its continuation to the machine: it stores the frame
# itself, so the machine's dispatch reads only the callee and its arity, and no
# frame-global is left between the split and the resumed continuation.
# Arguments are evaluated into block-scoped temporaries first: a lazy symbol
# read is itself a machine run, and it must not disturb the tail slots already
# filled.
def let_step(id: U32, op: BIR.Op, next: BIR.Block, ctx: JsCtx) -> String:
  match multi_let_special(id, op, next, ctx):
    case Some{text}: text
    case None{}: let_step_plain(id, op, next, ctx)
def let_step_plain(id: U32, op: BIR.Op, next: BIR.Block, ctx: JsCtx) -> String:
  match op:
    case BIR.Direct{code, args}: split_direct(id, code, args, ctx)
    case BIR.Apply{fn, arg}: split_apply(id, fn, arg, js_ctx_cont(ctx, id), ctx)
    case _: cat(["const ", local(id), "=", operation(op, ctx), ";", block(next, ctx)])
def return_step(value: BIR.Atom, ctx: JsCtx) -> String:
  match multi_return_forward(value, ctx):
    case Some{text}: text
    case None{}: cat(["return ", atom(value), ";"])
def multi_return_forward(value: BIR.Atom, ctx: JsCtx) -> Maybe<&2, String>:
  match value:
    case BIR.Local{id}: multi_param_forward(js_ctx_private(ctx), js_ctx_param(ctx, id), js_ctx_width(ctx))
    case _: None{}
def multi_param_forward(private: Bool, found: Maybe<&2, MultiParam>, width: Nat) -> Maybe<&2, String>:
  match private:
    case False{}: None{}
    case True{}: multi_param_forward_of(found, width)
def multi_param_forward_of(found: Maybe<&2, MultiParam>, width: Nat) -> Maybe<&2, String>:
  match found:
    case Some{MultiParam{_, unboxed, tag, fields}}: multi_param_forward_flags(unboxed, tag, fields, width)
    case None{}: None{}
def multi_param_forward_flags(unboxed: Bool, tag: U32, fields: List<&2, U32>, width: Nat) -> Maybe<&2, String>:
  match unboxed:
    case True{}: Some{multi_window_write(local(tag), multi_atom_list(fields), width)}
    case False{}: None{}
def multi_window_write(tag: String, items: List<&2, BIR.Atom>, width: Nat) -> String:
  cat([multi_window_stores(items, width, 0n), "return ", tag, ";"])
def multi_window_stores(items: List<&2, BIR.Atom>, width: Nat, index: Nat) -> String:
  match Nat.is_lt(index, width):
    case True{}: cat(["$stArgs[$mr+", Nat.show(Nat.add(index, 1n)), "]=", atom(multi_nth(items, index)), ";", multi_window_stores(items, width, (index + 1n : Nat))])
    case False{}: ""
def multi_let_special(id: U32, op: BIR.Op, next: BIR.Block, ctx: JsCtx) -> Maybe<&2, String>:
  match op:
    case BIR.Construct{_, tag, fields}: multi_result_construct(id, tag, fields, next, ctx)
    case _: None{}
def multi_result_construct(id: U32, tag: String, fields: List<&2, BIR.Field>, next: BIR.Block, ctx: JsCtx) -> Maybe<&2, String>:
  match next:
    case BIR.Return{BIR.Local{known}}: multi_result_same(Bool.and(U32.is_eq(known, id), js_ctx_private(ctx)), tag, fields, ctx)
    case _: None{}
def multi_result_same(same: Bool, tag: String, fields: List<&2, BIR.Field>, ctx: JsCtx) -> Maybe<&2, String>:
  match same:
    case False{}: None{}
    case True{}: Some{multi_window_write(js_quote(tag), multi_field_atoms(fields), js_ctx_width(ctx))}
def tail_step(code: U32, args: List<&2, BIR.Arg>, ctx: JsCtx) -> String:
  match js_ctx_private(ctx):
    case True{}: cat(["return ", multi_tail_call(code, arguments(args)), ";"])
    case False{}: cat(["return ", tail_call_name(multi_target_name(js_ctx_targets(ctx), code), arguments(args)), ";"])
def split_direct(id: U32, code: U32, args: List<&2, BIR.Arg>, ctx: JsCtx) -> String:
  split_direct_route(js_ctx_site(ctx, id), id, code, args, js_ctx_cont(ctx, id), ctx)
def split_direct_route(private: Bool, id: U32, code: U32, args: List<&2, BIR.Arg>, caps: Caps, ctx: JsCtx) -> String:
  match private:
    case True{}: split_direct_make(code_name(code), id, args, caps, ctx, True{})
    case False{}: split_direct_make(multi_target_name(js_ctx_targets(ctx), code), id, args, caps, ctx, False{})
def split_direct_make(name: String, id: U32, args: List<&2, BIR.Arg>, caps: Caps, ctx: JsCtx, private: Bool) -> String:
  +count = List.length(&2, BIR.Arg, args)
  +fits = multi_split_fits(count, private, js_ctx_mr(ctx, id))
  split_direct_selected(fits, name, id, args, caps, count, ctx, private, js_ctx_mr(ctx, id))
def multi_split_fits(count: Nat, private: Bool, mr: Bool) -> Bool:
  Bool.and(Nat.is_gt(count, 0n), Nat.is_le(multi_split_count(count, private, mr), 32n))
def multi_split_count(count: Nat, private: Bool, mr: Bool) -> Nat:
  multi_split_added(private, Nat.add(count, multi_split_mr(mr)))
def multi_split_added(private: Bool, count: Nat) -> Nat:
  match private:
    case True{}: Nat.add(count, 1n)
    case False{}: count
def multi_split_mr(mr: Bool) -> Nat:
  match mr:
    case True{}: 1n
    case False{}: 0n
def split_direct_selected(selected: Bool, name: String, id: U32, args: List<&2, BIR.Arg>, caps: Caps, count: Nat, ctx: JsCtx, private: Bool, mr: Bool) -> String:
  match selected:
    case True{}: split_direct_args(name, id, args, caps, count, ctx, private, mr)
    case False{}: split_direct_many(name, id, args, caps, ctx, private, mr)
def split_direct_args(name: String, id: U32, args: List<&2, BIR.Arg>, caps: Caps, count: Nat, ctx: JsCtx, private: Bool, mr: Bool) -> String:
  +total = Nat.add(cap_total(caps), multi_split_mr(mr))
  cat(["{const ", arg_temps(args, 0n), ";", cap_stores(caps_locals(caps)), slot_stores(caps_slots(caps)), multi_mr_store(mr), "if($td<64){const $kb=$sp-", Nat.show(total), ",$ki=$split_enter(", cont_name_ctx(ctx, id), ",$kb);try{return $split_done(", name, "(", String.join(multi_call_arg_names(args, 0n, private), ","), "),$ki,$td+1);}catch($e){$split_abort($ki,$kb);throw $e;}}", arg_moves(count, 0n), multi_window_move(private, count), "return $split(", name, ",", Nat.show(multi_split_count(count, private, mr)), ",", cont_name_ctx(ctx, id), ",$sp-", Nat.show(total), ");}"])
def multi_mr_store(mr: Bool) -> String:
  match mr:
    case True{}: "$stArgs[$sp++]=$mr;"
    case False{}: ""
def multi_window_move(private: Bool, count: Nat) -> String:
  match private:
    case True{}: cat(["$tailArgs[", Nat.show(count), "]=$sp;"])
    case False{}: ""
def multi_call_arg_names(args: List<&2, BIR.Arg>, index: Nat, private: Bool) -> List<&2, String>:
  List.append(&2, String, multi_call_arg_tail(arg_temp_only(args, index), private), ["$td+1"])
def multi_call_arg_tail(names: List<&2, String>, private: Bool) -> List<&2, String>:
  match private:
    case True{}: List.append(&2, String, names, ["$sp"])
    case False{}: names
def arg_temp_only(args: List<&2, BIR.Arg>, index: Nat) -> List<&2, String>:
  match args:
    case Nil{}: Nil{}
    case _ <> rest: cat(["$a", Nat.show(index)]) <> arg_temp_only(rest, (index + 1n : Nat))
def split_direct_many(name: String, id: U32, args: List<&2, BIR.Arg>, caps: Caps, ctx: JsCtx, private: Bool, mr: Bool) -> String:
  cat([cap_stores(caps_locals(caps)), slot_stores(caps_slots(caps)), multi_mr_store(mr), "return $splitm(", name, ",[", String.join(arguments(args), private_arg_tail(private)), "],", cont_name_ctx(ctx, id), ",$sp-", Nat.show(Nat.add(cap_total(caps), multi_split_mr(mr))), ");"])
def private_arg_tail(private: Bool, mr: Bool) -> String:
  private_arg_tail_one(private)
def split_apply(id: U32, fn: BIR.Atom, arg: BIR.Arg, caps: Caps, ctx: JsCtx) -> String:
  cat([cap_stores(caps_locals(caps)), slot_stores(caps_slots(caps)), multi_mr_store(js_ctx_mr(ctx, id)), "return $split1(", atom(fn), ",", arg_atom(arg), ",", cont_name_ctx(ctx, id), ",$sp-", Nat.show(multi_window_offset(caps, js_ctx_mr(ctx, id))), ");"])
def arg_atom(arg: BIR.Arg) -> String:
  match arg:
    case BIR.Arg{_, value}: atom(value)
def arg_temps(args: List<&2, BIR.Arg>, index: Nat) -> String:
  match args:
    case Nil{}: ""
    case +item <> rest: cat(["$a", Nat.show(index), "=", arg_atom(item), arg_temps_tail(rest, (index + 1n : Nat))])
def arg_temps_tail(rest: List<&2, BIR.Arg>, index: Nat) -> String:
  match rest:
    case Nil{}: ""
    case _: cat([",", arg_temps(rest, index)])
def arg_temp_names(args: List<&2, BIR.Arg>, index: Nat) -> List<&2, String>:
  match args:
    case Nil{}: ["$td+1"]
    case _ <> rest: cat(["$a", Nat.show(index)]) <> arg_temp_names(rest, (index + 1n : Nat))
def arg_moves(count: Nat, index: Nat) -> String:
  arg_moves_at(Nat.is_lt(index, count), count, index)
def arg_moves_at(more: Bool, count: Nat, index: Nat) -> String:
  match more:
    case True{}: cat(["$tailArgs[", Nat.show(index), "]=$a", Nat.show(index), ";", arg_moves(count, (index + 1n : Nat))])
    case False{}: ""
def cap_stores(items: List<&2, U32>) -> String:
  match items:
    case Nil{}: ""
    case +item <> rest: cat(["$stArgs[$sp++]=", local(item), ";", cap_stores(rest)])
def slot_stores(items: List<&2, U32>) -> String:
  match items:
    case Nil{}: ""
    case +item <> rest: cat(["$stArgs[$sp++]=", capture(item), ";", slot_stores(rest)])
def cap_binds(items: List<&2, U32>, index: Nat) -> String:
  match items:
    case Nil{}: ""
    case +item <> rest: cat(["const ", local(item), "=$stArgs[$base+", Nat.show(index), "];", cap_binds(rest, (index + 1n : Nat))])
def slot_binds(items: List<&2, U32>, index: Nat) -> String:
  match items:
    case Nil{}: ""
    case +item <> rest: cat(["const ", capture(item), "=$stArgs[$base+", Nat.show(index), "];", slot_binds(rest, (index + 1n : Nat))])
def cont_of(id: U32, next: BIR.Block, ctx: JsCtx) -> String:
  +caps = js_ctx_cont(ctx, id)
  cat(["function ", cont_name_ctx(ctx, id), "(", local(id), ",$base,$td=0){", cap_binds(caps_locals(caps), 0n), slot_binds(caps_slots(caps), List.length(&2, U32, caps_locals(caps))), multi_cont_extra(id, caps, ctx), block(next, ctx), "}\n"])
def multi_cont_extra(id: U32, caps: Caps, ctx: JsCtx) -> String:
  cat([multi_mr_bind(js_ctx_mr(ctx, id), caps), multi_window_extra(js_ctx_window(ctx, id), id, multi_window_offset(caps, js_ctx_mr(ctx, id)))])
def multi_window_offset(caps: Caps, mr: Bool) -> Nat:
  Nat.add(cap_total(caps), multi_mr_flag(mr))
def multi_mr_flag(mr: Bool) -> Nat:
  match mr:
    case True{}: 1n
    case False{}: 0n
def multi_mr_bind(mr: Bool, caps: Caps) -> String:
  match mr:
    case True{}: cat(["const $mr=$stArgs[$base+", Nat.show(cap_total(caps)), "];"])
    case False{}: ""
def multi_window_extra(window: Maybe<&2, MultiWindow>, id: U32, offset: Nat) -> String:
  match window:
    case Some{MultiWindow{width, fields, box}}: cat([multi_slot_binds(fields, offset, 0n), multi_box_bind(box, id, offset), multi_slot_clear(width, offset, 0n)])
    case None{}: ""
def multi_slot_binds(items: List<&2, U32>, offset: Nat, index: Nat) -> String:
  match items:
    case Nil{}: ""
    case +item <> rest: cat(["const ", local(item), "=$stArgs[$base+", Nat.show(Nat.add(Nat.add(offset, 1n), index)), "];", multi_slot_binds(rest, offset, (index + 1n : Nat))])
def multi_box_bind(box: Maybe<&2, U32>, id: U32, offset: Nat) -> String:
  match box:
    case Some{target}: cat(["const ", local(target), "=$multi_box(", local(id), ",$base,", Nat.show(offset), ");"])
    case None{}: ""
def multi_slot_clear(width: Nat, offset: Nat, index: Nat) -> String:
  match Nat.is_lt(index, width):
    case True{}: cat(["$stArgs[$base+", Nat.show(Nat.add(Nat.add(offset, 1n), index)), "]=undefined;", multi_slot_clear(width, offset, (index + 1n : Nat))])
    case False{}: ""
def thunk_of(owner: String, label: U32, next: BIR.Block, ctx: JsCtx) -> String:
  +caps = js_ctx_thunk(ctx, label)
  cat(["function ", thunk_name(owner, label), "($x,$base,$td=0){", cap_binds(caps_locals(caps), 0n), slot_binds(caps_slots(caps), List.length(&2, U32, caps_locals(caps))), block(next, ctx), "}\n"])
def region_frame(label: U32, body: BIR.Block, next: BIR.Block, ctx: JsCtx) -> String:
  +caps = js_ctx_thunk(ctx, label)
  cat([cap_stores(caps_locals(caps)), slot_stores(caps_slots(caps)), "$frame(", thunk_name(js_ctx_owner(ctx), label), ",$sp-", Nat.show(cap_total(caps)), ");", block(body, js_ctx_inside(ctx, label))])
def leave_step(label: U32, ctx: JsCtx) -> String:
  match js_ctx_has(ctx, label):
    case True{}: cat(["$leaveThunk=", thunk_name(js_ctx_owner(ctx), label), ";return $LEAVE_PENDING;"])
    case False{}: cat(["break $case", U32.show(label), ";"])
# Every continuation and region thunk a block needs, in the same order the
# renderer reaches them. Function declarations hoist, so they follow their
# owner's body in the emitted program.
def conts(body: BIR.Block, ctx: JsCtx) -> List<&2, String>:
  match body:
    case BIR.Let{id, op, next}: conts_let(id, op, next, ctx)
    case BIR.Branch{_, yes, no}: List.append(&2, String, conts(yes, ctx), conts(no, ctx))
    case BIR.Region{label, body, next}: conts_region(label, body, next, ctx)
    case _: Nil{}
def conts_let(id: U32, op: BIR.Op, next: BIR.Block, ctx: JsCtx) -> List<&2, String>:
  match split_op(op):
    case True{}: cont_of(id, next, ctx) <> conts(next, ctx)
    case False{}: conts(next, ctx)
def conts_region(label: U32, body: BIR.Block, next: BIR.Block, ctx: JsCtx) -> List<&2, String>:
  match js_ctx_frame(ctx, label):
    case True{}: thunk_of(js_ctx_owner(ctx), label, next, ctx) <> List.append(&2, String, conts(body, js_ctx_inside(ctx, label)), conts(next, ctx))
    case False{}: List.append(&2, String, conts(body, ctx), conts(next, ctx))

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
    case BIR.PrimArrayAtomicAdd{}: "$p_array_atomic_add"
    case BIR.PrimArrayAtomicMin{}: "$p_array_atomic_min"
    case BIR.PrimArrayAtomicMax{}: "$p_array_atomic_max"
    case BIR.PrimArrayAtomicAnd{}: "$p_array_atomic_and"
    case BIR.PrimArrayAtomicOr{}: "$p_array_atomic_or"
    case BIR.PrimArrayAtomicXor{}: "$p_array_atomic_xor"
    case BIR.PrimArrayAtomicExch{}: "$p_array_atomic_exch"
    case BIR.PrimArrayAtomicCas{}: "$p_array_atomic_cas"
    case BIR.PrimArrayAtomicFadd{}: "$p_array_atomic_fadd"
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
    case BIR.PrimF32Pow{}: "(a)=>(b)=>f32_pow(a,b)"
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
    case BIR.PrimMapBit{}: "(key)=>(position)=>$p_map_bit(key,position)"
    case BIR.PrimStringCmp{}: "(a)=>(b)=>$p_string_cmp(a,b)"
    case BIR.PrimStringToList{}: "(text)=>$p_string_to_list(text)"
    case BIR.PrimStringLength{}: "(a)=>$p_string_length(a)"
    case BIR.PrimArrayNew{}: "(a)=>(b)=>array_new(a,b)"
    case BIR.PrimArraySet{}: "(a)=>(i)=>(v)=>(a[i%a.length]=v,a)"
    case BIR.PrimArrayGet{}: "(a)=>(i)=>tuple(a,a[i%a.length])"
    case BIR.PrimArraySwap{}: "(a)=>(i)=>(v)=>array_swap(a,i,v)"
    case BIR.PrimArrayAtomicAdd{}: "(a)=>(i)=>(v)=>array_rmw(a,i,(o)=>((o+v)>>>0))"
    case BIR.PrimArrayAtomicMin{}: "(a)=>(i)=>(v)=>array_rmw(a,i,(o)=>Math.min(o,v))"
    case BIR.PrimArrayAtomicMax{}: "(a)=>(i)=>(v)=>array_rmw(a,i,(o)=>Math.max(o,v))"
    case BIR.PrimArrayAtomicAnd{}: "(a)=>(i)=>(v)=>array_rmw(a,i,(o)=>((o&v)>>>0))"
    case BIR.PrimArrayAtomicOr{}: "(a)=>(i)=>(v)=>array_rmw(a,i,(o)=>((o|v)>>>0))"
    case BIR.PrimArrayAtomicXor{}: "(a)=>(i)=>(v)=>array_rmw(a,i,(o)=>((o^v)>>>0))"
    case BIR.PrimArrayAtomicExch{}: "(a)=>(i)=>(v)=>array_rmw(a,i,(o)=>v)"
    case BIR.PrimArrayAtomicCas{}: "(a)=>(i)=>(x)=>(v)=>array_rmw(a,i,(o)=>(o===x?v:o))"
    case BIR.PrimArrayAtomicFadd{}: "(a)=>(i)=>(v)=>array_rmw(a,i,(o)=>Math.fround(o+v))"
    case BIR.PrimArraySize{}: "(a)=>tuple(a,a.length)"
    case BIR.PrimArrayClone{}: "(a)=>tuple(a,a.slice())"
    case BIR.PrimNatPredecessor{}: "(a)=>a-1"
    case BIR.PrimNatSuccessor{}: "(a)=>nat_chk(a+1)"
    case BIR.PrimCharNew{}: "(a)=>char_new(a)"
    case BIR.PrimCharCode{}: "(a)=>char_code(a)"
    case BIR.PrimStringHead{}: "(a)=>a.slice(0,char_len(a))"
    case BIR.PrimStringTail{}: "(a)=>a.slice(char_len(a))"
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
  "const $p_u32_add=(a,b)=>((a+b)>>>0);\nconst $p_u32_sub=(a,b)=>((a-b)>>>0);\nconst $p_u32_mul=(a,b)=>(Math.imul(a,b)>>>0);\nconst $p_u32_div=(a,b)=>(b===0?0:(a/b)>>>0);\nconst $p_nat_add=(a,b)=>nat_chk(a+b);\nconst $p_nat_sub=(a,b)=>(a<b?0:a-b);\nconst $p_nat_mul=(a,b)=>nat_chk(a*b);\nconst $p_nat_cmp=(a,b)=>cmp_new(a,b);\nconst $p_nat_min=(a,b)=>(a<b?a:b);\nconst $p_nat_max=(a,b)=>(a>b?a:b);\nconst $p_string_append=(a,b)=>a+b;\nconst $p_bool_or=(a,b)=>a||b;\nconst $p_bool_xor=(a,b)=>a!==b;\nconst $p_u32_is_zero=(a)=>a===0;\nconst $p_f32_asin=(a)=>Math.fround(Math.asin(a));\nconst $p_f32_acos=(a)=>Math.fround(Math.acos(a));\nconst $p_f32_atan=(a)=>Math.fround(Math.atan(a));\nconst $p_f32_sinh=(a)=>Math.fround(Math.sinh(a));\nconst $p_f32_cosh=(a)=>Math.fround(Math.cosh(a));\nconst $p_f32_tanh=(a)=>Math.fround(Math.tanh(a));\nconst $p_u32_mod=(a,b)=>(b===0?a:a%b);\nconst $p_u32_and=(a,b)=>((a&b)>>>0);\nconst $p_u32_or=(a,b)=>((a|b)>>>0);\nconst $p_u32_xor=(a,b)=>((a^b)>>>0);\nconst $p_u32_is_eq=(a,b)=>a===b;\nconst $p_u32_is_ne=(a,b)=>a!==b;\nconst $p_u32_is_lt=(a,b)=>a<b;\nconst $p_u32_is_le=(a,b)=>a<=b;\nconst $p_u32_is_gt=(a,b)=>a>b;\nconst $p_u32_is_ge=(a,b)=>a>=b;\nconst $p_u32_inc=(a)=>(a+1)>>>0;\nconst $p_u32_not=(a)=>(~a)>>>0;\nconst $p_u32_shl=(a)=>(a<<1)>>>0;\nconst $p_u32_shr=(a)=>a>>>1;\nconst $p_u32_shln=(a,b)=>b>=32?0:(a<<b)>>>0;\nconst $p_u32_shrn=(a,b)=>b>=32?0:a>>>b;\nconst $p_u32_cmp=(a,b)=>cmp_new(a,b);\nconst $p_u32_to_nat=(a)=>a;\nconst $p_u32_from_nat=(a)=>a>>>0;\nconst $p_f32_add=(a,b)=>Math.fround(a+b);\nconst $p_f32_sub=(a,b)=>Math.fround(a-b);\nconst $p_f32_mul=(a,b)=>Math.fround(a*b);\nconst $p_f32_div=(a,b)=>Math.fround(a/b);\nconst $p_f32_mod=(a,b)=>Math.fround(a%b);\nconst $p_f32_neg=(a)=>-a;\nconst $p_f32_sqrt=(a)=>Math.fround(Math.sqrt(a));\nconst $p_f32_abs=(a)=>Math.fround(Math.abs(a));\nconst $p_f32_to_u32=(a)=>(a>=1&&a<4294967296?Math.floor(a):0);\nconst $p_f32_bits=(a)=>f32_bits(a);\nconst $p_f32_show=(a)=>f32_show(a);\nconst $p_f32_read=(a)=>f32_read(a);\nconst $p_f32_is_eq=(a,b)=>a===b;\nconst $p_f32_is_ne=(a,b)=>a!==b;\nconst $p_f32_is_lt=(a,b)=>a<b;\nconst $p_f32_is_le=(a,b)=>a<=b;\nconst $p_f32_is_gt=(a,b)=>a>b;\nconst $p_f32_is_ge=(a,b)=>a>=b;\nconst $p_f32_pow=(a,b)=>f32_pow(a,b);\nconst $p_f32_atan2=(a,b)=>Math.fround(Math.atan2(a,b));\nconst $p_f32_exp=(a)=>Math.fround(Math.exp(a));\nconst $p_f32_log=(a)=>Math.fround(Math.log(a));\nconst $p_f32_log2=(a)=>Math.fround(Math.log2(a));\nconst $p_f32_log10=(a)=>Math.fround(Math.log10(a));\nconst $p_f32_sin=(a)=>Math.fround(Math.sin(a));\nconst $p_f32_cos=(a)=>Math.fround(Math.cos(a));\nconst $p_f32_tan=(a)=>Math.fround(Math.tan(a));\nconst $p_f32_floor=(a)=>Math.fround(Math.floor(a));\nconst $p_f32_ceil=(a)=>Math.fround(Math.ceil(a));\nconst $p_f32_trunc=(a)=>Math.fround(Math.trunc(a));\nconst $p_f32_to_nat=(a)=>Math.floor(a);\nconst $p_u32_to_f32=(a)=>Math.fround(a);\nconst $p_nat_double=(a)=>nat_chk(a+a);\nconst $p_nat_is_lt=(a,b)=>a<b;\nconst $p_nat_divmod=(a,b)=>nat_divmod(a,b);\nconst $p_string_eq=(a,b)=>a===b;\nconst $p_map_bit=(key,position)=>{const character=Math.floor(position/33);if(character>=key.length)return tuple(key,false);const offset=position%33;let at=0;for(let i=0;i<character&&at<key.length;i++)at+=char_len(key,at);return tuple(key,at<key.length&&(offset===0||((char_code_at(key,at)>>>(32-offset))&1)!==0));};\nconst $p_string_cmp=(a,b)=>{let i=0,j=0,order=0;if(a!==b){while(i<a.length&&j<b.length){const x=char_code_at(a,i),y=char_code_at(b,j);if(x!==y){order=x<y?-1:1;break;}i+=char_len(a,i);j+=char_len(b,j);}if(order===0)order=i<a.length?1:j<b.length?-1:0;}return tuple(tuple(a,b),cmp_new(order,0));};\nconst $p_string_to_list=(text)=>{let tail={$:\"Nil\"};for(let i=text.length;i>0;){let n=1;if(i>=4&&text.charCodeAt(i-4)===0xDC00)n=4;else if(i>=2&&text.charCodeAt(i-1)>=0xDC00&&text.charCodeAt(i-1)<=0xDFFF&&text.charCodeAt(i-2)>=0xD800&&text.charCodeAt(i-2)<=0xDBFF)n=2;tail={$:\"Con\",head:text.slice(i-n,i),tail};i-=n;}return tail;};\nconst $p_string_length=(a)=>[...str_out(a)].length;\nconst $p_array_new=(a,b)=>array_new(a,b);\nconst $p_array_set=(a,i,v)=>(a[i%a.length]=v,a);\nconst $p_array_get=(a,i)=>tuple(a,a[i%a.length]);\nconst $p_array_swap=(a,i,v)=>array_swap(a,i,v);\nconst $p_array_atomic_add=(a,i,v)=>array_rmw(a,i,(o)=>((o+v)>>>0));\nconst $p_array_atomic_min=(a,i,v)=>array_rmw(a,i,(o)=>Math.min(o,v));\nconst $p_array_atomic_max=(a,i,v)=>array_rmw(a,i,(o)=>Math.max(o,v));\nconst $p_array_atomic_and=(a,i,v)=>array_rmw(a,i,(o)=>((o&v)>>>0));\nconst $p_array_atomic_or=(a,i,v)=>array_rmw(a,i,(o)=>((o|v)>>>0));\nconst $p_array_atomic_xor=(a,i,v)=>array_rmw(a,i,(o)=>((o^v)>>>0));\nconst $p_array_atomic_exch=(a,i,v)=>array_rmw(a,i,(o)=>v);\nconst $p_array_atomic_cas=(a,i,x,v)=>array_rmw(a,i,(o)=>(o===x?v:o));\nconst $p_array_atomic_fadd=(a,i,v)=>array_rmw(a,i,(o)=>Math.fround(o+v));\nconst $p_array_size=(a)=>tuple(a,a.length);\nconst $p_array_clone=(a)=>tuple(a,a.slice());\nconst $p_nat_predecessor=(a)=>a-1;\nconst $p_nat_successor=(a)=>nat_chk(a+1);\nconst $p_char_new=(a)=>char_new(a);\nconst $p_char_code=(a)=>char_code(a);\nconst $p_string_head=(a)=>a.slice(0,char_len(a));\nconst $p_string_tail=(a)=>a.slice(char_len(a));\nconst $p_word_to_u32=(a)=>word_to_u32(a);\nconst $p_u32_to_word=(a)=>u32_to_word(a);\nconst $p_f32_from_bits=(a)=>f32_from_bits(a);\nconst $p_f32_from_word=(a)=>f32_from_bits(word_to_u32(a));\nconst $p_f32_to_word=(a)=>u32_to_word(f32_bits(a));\nconst $p_array_leaf=(a)=>[a];\nconst $p_array_node=(a,b)=>array_node(a,b);\nconst $p_array_leaf_value=(a)=>a[0];\nconst $p_array_left=(a)=>a.slice(0,a.length>>1);\nconst $p_array_right=(a)=>a.slice(a.length>>1);\nconst $p_is_array_leaf=(a)=>a.length===1;\nconst $p_is_array_node=(a)=>a.length!==1;\nconst $p_is_nat_zero=(a)=>a===0;\nconst $p_is_nat_successor=(a)=>a>0;\nconst $p_is_string_empty=(a)=>a===\"\";\nconst $p_is_string_nonempty=(a)=>a!==\"\";\nconst $p_is_true=(a)=>a===true;\nconst $p_is_false=(a)=>a===false;\nconst $p_same_value=(a,b)=>a===b;\nconst $p_float_bits_equal=(a,b)=>f32_bits(a)===b;\n"

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
  cat(["Object.defineProperty($D,", js_quote(key), ",{enumerable:true,configurable:true,get(){const $base0=$ksp,$sp0=$sp;return run_base(", value, ",$base0,$sp0);}});\n"])
def declaration(item: BIR.Declaration, +natives: Map<&2, String>, index: Nat, plan: MultiPlan) -> String:
  match item:
    case BIR.FunctionDeclaration{key, code, parameters}:
      cat(["$D[", js_quote(key), "]=", closure_named(multi_target_name(multi_plan_multi(plan), code), Nil{}, parameters), ";\n"])
    case BIR.LazyDeclaration{key, body}:
      scoped = js_scalar(body)
      +ctx = js_ctx(cat(["L", Nat.show(index)]), plan_of(scoped))
      cat([deferred(key, cat(["(()=>{", block(scoped, ctx), "})()"])), String.join(conts(scoped, ctx), "")])
    case BIR.NativeDeclaration{key, primitive, uses}:
      native_declaration(key, primitive, uses)
    case BIR.ForeignDeclaration{key, _, imported, arity, decl_sources, _, _, parameter_types, result}:
      foreign_declaration(key, imported, decl_sources, arity, parameter_types, result, natives)
def foreign_declaration(+key: String, imported: String, sources: List<&2, String>, arity: Nat, parameters: List<&2, BIR.Descriptor>, result: BIR.Descriptor, +natives: Map<&2, String>) -> String:
  foreign_source(js_source(sources), key, imported, arity, parameters, result, natives)
def foreign_source(chosen: Maybe<&2, String>, +key: String, +imported: String, arity: Nat, parameters: List<&2, BIR.Descriptor>, result: BIR.Descriptor, +natives: Map<&2, String>) -> String:
  match chosen:
    case Some{_}: foreign_request(key, arity, parameters, js_nat_answer(result, natives), result, natives)
    case None{}:
      # link() rejects this declaration before emission; keep the render total.
      deferred(key, cat(["(()=>{throw new Error(", js_quote(String.append("bend: foreign definition has no .js import: ", imported)), ")})()"]))
def native_declaration(+key: String, primitive: BIR.Primitive, +uses: List<&2, BIR.Quantity>) -> String:
  cat(["$D[", js_quote(key), "]=", primitive_public(primitive), ";\n$TYPEF[", js_quote(key), "]={n:", Nat.show(List.length(&2, BIR.Quantity, uses)), ",q:[", String.join(quantities(uses), ","), "],intrinsic:$D[", js_quote(key), "]};\n"])
def declarations(items: List<&2, BIR.Declaration>, +natives: Map<&2, String>, index: Nat, plan: MultiPlan) -> String:
  match items:
    case Nil{}: ""
    case item <> rest: cat([declaration(item, natives, index, plan), declarations(rest, natives, (index + 1n : Nat), plan)])
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
# A host parameter crosses the export seam as a number. It is a Nat only when
# the export's published live parameter descriptor resolves to the family whose
# BIR native is Nat; a polymorphic or missing descriptor is refused by name,
# never treated as unguarded Nat and never silently adapted.
def js_parameter(value: BIR.Descriptor, +natives: Map<&2, String>) -> JSParameter:
  js_parameter_head(js_descriptor_head(value), natives, value)
def js_parameter_head(head: Maybe<&2, JSDescriptorHead>, +natives: Map<&2, String>, value: BIR.Descriptor) -> JSParameter:
  match head:
    case Some{JSDescriptorHead{key, args}}: js_parameter_marker(js_native_is(natives, key, "Nat"), IndexLookup.find(String, natives, key), args, value)
    case None{}: js_parameter_unresolved(value)
# A concrete Nat is guarded; a known non-Nat family is not. A head absent from
# the type table is an unresolved concrete alias, and a user type function with
# no native marker is a closed alias this renderer cannot reduce: both fail
# loudly rather than silently skipping a possible Nat.
def js_parameter_marker(nat: Bool, marker: Maybe<&2, String>, args: List<&2, BIR.Descriptor>, value: BIR.Descriptor) -> JSParameter:
  match nat:
    case True{}: js_parameter_arity(args)
    case False{}: js_parameter_other(marker, value)
def js_parameter_other(marker: Maybe<&2, String>, value: BIR.Descriptor) -> JSParameter:
  match marker:
    case Some{name}: js_parameter_known(name, value)
    case None{}: JSParameterUnresolved{}
def js_parameter_known(name: String, value: BIR.Descriptor) -> JSParameter:
  js_parameter_alias(String.eq(name, "TF"), value)
def js_parameter_alias(alias: Bool, value: BIR.Descriptor) -> JSParameter:
  match alias:
    case True{}: JSParameterUnresolved{}
    case False{}: JSParameterOther{}
def js_parameter_arity(args: List<&2, BIR.Descriptor>) -> JSParameter:
  js_parameter_arity_count(Nat.is_eq(List.length(&2, BIR.Descriptor, args), 0n))
def js_parameter_arity_count(empty: Bool) -> JSParameter:
  match empty:
    case True{}: JSParameterNat{}
    case False{}: JSParameterOther{}
# An abstract (generic) domain is unconstrained, not Nat: it crosses as it is,
# with no guessed guard and no failure. Only a missing canonical symbol (a
# DescriptorFailure published by lowering) is an error.
def js_parameter_unresolved(value: BIR.Descriptor) -> JSParameter:
  match value:
    case BIR.DescriptorFailure{_}: JSParameterUnresolved{}
    case _: JSParameterOther{}
def export_arguments(items: List<&2, BIR.Descriptor>, +natives: Map<&2, String>, index: Nat) -> List<&2, String>:
  match items:
    case Nil{}: Nil{}
    case +item <> rest: export_argument(js_parameter(item, natives), js_text_descriptor(item, natives), js_f32_descriptor(item, natives), index) <> export_arguments(rest, natives, (index + 1n : Nat))
def export_argument(parameter: JSParameter, text: Bool, f32: Bool, index: Nat) -> String:
  match parameter:
    case JSParameterNat{}: cat(["nat_in(arguments[", Nat.show(index), "])"])
    case _: export_argument_scalar(text, f32, index)
def export_argument_scalar(text: Bool, f32: Bool, index: Nat) -> String:
  match text:
    case True{}: cat(["str_in(arguments[", Nat.show(index), "])"])
    case False{}: export_argument_float(f32, index)
def export_argument_float(f32: Bool, index: Nat) -> String:
  match f32:
    case True{}: cat(["Math.fround(arguments[", Nat.show(index), "])"])
    case False{}: cat(["arguments[", Nat.show(index), "]"])
def export_unresolved(+key: String, items: List<&2, BIR.Descriptor>, +natives: Map<&2, String>) -> Bool:
  match items:
    case Nil{}: False{}
    case +item <> rest: export_unresolved_item(js_parameter(item, natives), key, rest, natives)
def export_unresolved_item(kind: JSParameter, +key: String, rest: List<&2, BIR.Descriptor>, +natives: Map<&2, String>) -> Bool:
  match kind:
    case JSParameterUnresolved{}: True{}
    case _: export_unresolved(key, rest, natives)
def export_field(item: BIR.Export, +natives: Map<&2, String>, multi: Map<&2, Bool>) -> String:
  match item:
    case BIR.Export{+key, None{}, +parameters, +result}:
      export_curried(key, parameters, result, natives)
    case BIR.Export{+key, Some{BIR.Entry{code, +arity}}, +parameters, +result}:
      export_entry_field(key, code, arity, parameters, result, natives, multi)
# The published signature is the host ABI, and a returned arrow's domain is one
# of its parameters. A direct entry runs the code only when the entry arity and
# the published parameter count agree; otherwise the call goes through the
# public signature, which evaluates a zero-argument definition first and then
# applies the arguments the host supplied.
def export_entry_field(+key: String, code: U32, arity: Nat, parameters: List<&2, BIR.Descriptor>, result: BIR.Descriptor, +natives: Map<&2, String>, multi: Map<&2, Bool>) -> String:
  match Nat.is_eq(arity, List.length(&2, BIR.Descriptor, parameters)):
    case True{}: export_direct_field(key, code, parameters, result, natives, multi)
    case False{}: cat(["[", js_quote(key), "](){return ", export_curried_call(key, parameters, result, natives), ";}"])
def export_direct_field(+key: String, code: U32, parameters: List<&2, BIR.Descriptor>, result: BIR.Descriptor, +natives: Map<&2, String>, multi: Map<&2, Bool>) -> String:
  cat(["[", js_quote(key), "](){if(arguments.length!==", Nat.show(List.length(&2, BIR.Descriptor, parameters)), ")return ", export_curried_call(key, parameters, result, natives), ";const $base0=$ksp,$sp0=$sp;return ", export_result(result, natives, cat(["run_base(", multi_target_name(multi, code), "(", String.join(export_arguments(parameters, natives, 0n), ","), ")", ",$base0,$sp0)"])), ";}"])
# A completed export result is host text when its declared type is a Char or a
# String, so it crosses with str_out. A partial application returns a function,
# which is never normalized as text.
def export_result(result: BIR.Descriptor, +natives: Map<&2, String>, value: String) -> String:
  match js_text_descriptor(result, natives):
    case True{}: cat(["str_out(", value, ")"])
    case False{}: value
def export_nat_indices(items: List<&2, BIR.Descriptor>, +natives: Map<&2, String>, index: Nat) -> List<&2, Nat>:
  match items:
    case Nil{}: Nil{}
    case +item <> rest:
      match js_parameter(item, natives):
        case JSParameterNat{}: index <> export_nat_indices(rest, natives, (index + 1n : Nat))
        case _: export_nat_indices(rest, natives, (index + 1n : Nat))

def export_nat_index_texts(items: List<&2, Nat>) -> List<&2, String>:
  match items:
    case Nil{}: Nil{}
    case item <> rest: Nat.show(item) <> export_nat_index_texts(rest)

def export_nat_indexes(items: List<&2, BIR.Descriptor>, +natives: Map<&2, String>) -> String:
  String.join(export_nat_index_texts(export_nat_indices(items, natives, 0n)), ",")

def export_text_indices(items: List<&2, BIR.Descriptor>, +natives: Map<&2, String>, index: Nat) -> List<&2, Nat>:
  match items:
    case Nil{}: Nil{}
    case +item <> rest: export_text_index(js_text_descriptor(item, natives), rest, natives, index)
def export_text_index(text: Bool, rest: List<&2, BIR.Descriptor>, +natives: Map<&2, String>, index: Nat) -> List<&2, Nat>:
  match text:
    case True{}: index <> export_text_indices(rest, natives, (index + 1n : Nat))
    case False{}: export_text_indices(rest, natives, (index + 1n : Nat))

def export_f32_indices(items: List<&2, BIR.Descriptor>, +natives: Map<&2, String>, index: Nat) -> List<&2, Nat>:
  match items:
    case Nil{}: Nil{}
    case +item <> rest: export_f32_index(js_f32_descriptor(item, natives), rest, natives, index)
def export_f32_index(f32: Bool, rest: List<&2, BIR.Descriptor>, +natives: Map<&2, String>, index: Nat) -> List<&2, Nat>:
  match f32:
    case True{}: index <> export_f32_indices(rest, natives, (index + 1n : Nat))
    case False{}: export_f32_indices(rest, natives, (index + 1n : Nat))

def export_text_indexes(items: List<&2, BIR.Descriptor>, +natives: Map<&2, String>) -> String:
  String.join(export_nat_index_texts(export_text_indices(items, natives, 0n)), ",")

def export_f32_indexes(items: List<&2, BIR.Descriptor>, +natives: Map<&2, String>) -> String:
  String.join(export_nat_index_texts(export_f32_indices(items, natives, 0n)), ",")

# A completed public call is host text when its codomain is a Char or a String;
# a partial application returns a closure and is never normalized as text.
def export_result_normalizer(result: BIR.Descriptor, +natives: Map<&2, String>) -> String:
  match js_text_descriptor(result, natives):
    case True{}: "((v)=>str_out(v))"
    case False{}: "((v)=>v)"
def export_curried(key: String, parameters: List<&2, BIR.Descriptor>, result: BIR.Descriptor, +natives: Map<&2, String>) -> String:
  cat(["[", js_quote(key), "]:", export_curried_value(key, parameters, result, natives)])

def export_curried_value(key: String, parameters: List<&2, BIR.Descriptor>, result: BIR.Descriptor, +natives: Map<&2, String>) -> String:
  cat(["$curried($D[", js_quote(key), "],", Nat.show(List.length(&2, BIR.Descriptor, parameters)), ",[", export_nat_indexes(parameters, natives), "],[", export_text_indexes(parameters, natives), "],[", export_f32_indexes(parameters, natives), "],", export_result_normalizer(result, natives), ")"])

def export_curried_call(key: String, parameters: List<&2, BIR.Descriptor>, result: BIR.Descriptor, +natives: Map<&2, String>) -> String:
  cat([export_curried_value(key, parameters, result, natives), "(...arguments)"])

def export_fields(items: List<&2, BIR.Export>, +natives: Map<&2, String>, multi: Map<&2, Bool>) -> List<&2, String>:
  match items:
    case Nil{}: Nil{}
    case item <> rest: export_field(item, natives, multi) <> export_fields(rest, natives, multi)
def ending(item: BIR.Ending, +natives: Map<&2, String>, plan: MultiPlan) -> String:
  match item:
    case BIR.Executable{main_type}: js_main(descriptor(main_type))
    case BIR.Library{exports}: cat(["export default {", String.join(export_fields(exports, natives, multi_plan_multi(plan)), ","), "};\n"])
# A generic export parameter is a real abstract domain: it is not Nat and the
# host passes it through unchanged. Only a missing canonical symbol fails.
def export_check(items: List<&2, BIR.Export>, +natives: Map<&2, String>) -> Maybe<&2, String>:
  match items:
    case Nil{}: None{}
    case BIR.Export{+key, _, parameters, _} <> rest:
      export_check_one(export_unresolved(key, parameters, natives), key, rest, natives)
def export_check_one(bad: Bool, +key: String, rest: List<&2, BIR.Export>, +natives: Map<&2, String>) -> Maybe<&2, String>:
  match bad:
    case True{}: Some{String.append(key, " has an export parameter with no canonical type")}
    case False{}: export_check(rest, natives)
def ending_check(item: BIR.Ending, +natives: Map<&2, String>) -> Maybe<&2, String>:
  match item:
    case BIR.Library{exports}: export_check(exports, natives)
    case BIR.Executable{_}: None{}
def emit_linked(program: BIR.Program, loaded: List<&2, BIR.SourceFile>) -> EmitResult:
  emit_linked_plan(link(program), program, loaded)
def emit_linked_plan(planned: LinkResult, program: BIR.Program, loaded: List<&2, BIR.SourceFile>) -> EmitResult:
  match planned:
    case LinkFailure{message, span}: EmitFailure{message, span}
    case LinkSuccess{sources}: emit_checked(program, sources, loaded)
def emit_checked(+program: BIR.Program, sources: List<&2, LinkSource>, loaded: List<&2, BIR.SourceFile>) -> EmitResult:
  match program:
    case BIR.Program{_, _, _, _, _, end}:
      emit_checked_exports(ending_check(end, js_native_markers(program)), program, sources, loaded)
def emit_checked_exports(check: Maybe<&2, String>, program: BIR.Program, sources: List<&2, LinkSource>, loaded: List<&2, BIR.SourceFile>) -> EmitResult:
  match check:
    case Some{message}: EmitFailure{message, Ast.SpanOf{"", 0n, 0n}}
    case None{}: emit_effects(program, js_effect_sources(sources, loaded, js_known_keys(program), Nil{}))
def emit_effects(program: BIR.Program, effects: JSEffects) -> EmitResult:
  match effects:
    case JSEffectsFailure{message, span}: EmitFailure{message, span}
    case JSEffectsReady{text}: EmitSuccess{program_source(program, text)}
def program_source(program: BIR.Program, effects: String) -> String:
  +natives = js_native_markers(program)
  +plan = multi_plan(program)
  match program:
    case BIR.Program{bodies, values, layouts, types, functions, end}:
      cat([js_runtime(), js_runtime_direct(), js_runtime_extra(), js_runtime_show(), js_runtime_cli(), js_runtime_io(), js_runtime_array(), js_runtime_foreign(), js_runtime_namespace(), primitive_runtime(), constructor_layouts(layouts), families(types), type_functions(functions), effects, codes(bodies, plan), declarations(values, natives, 0n, plan), ending(end, natives, plan)])

# Publish the same continuation frame before a bounded direct call. A pending
# result or an unpopped region frame belongs to run_base; only an ordinary
# synchronous result with our frame on top can resume here. Thread depth into
# the continuation too, so a chain of completed calls cannot reset the bound.
def js_runtime_direct() -> String:
  "function $multi_box(t,b,c) { const ks=$FIELDS[t]; if(ks===undefined) throw \"bend: unresolved multi-result tag\"; const o={$:t}; for(let i=0;i<ks.length;i++) o[ks[i]]=$stArgs[b+c+1+i]; return o; }\nfunction $split_enter(k,b) { const i=$ksp++; $kFn[i]=k; $kBase[i]=b; $kKind[i]=0; return i; }\nfunction $split_done(x,i,d) { if(x===$TAIL_PENDING||x===$CALL_PENDING||x===$LEAVE_PENDING||$ksp!==i+1)return x; const k=$kFn[i],b=$kBase[i]; $kFn[i]=undefined; $ksp=i; $sp=b; return k(x,b,d); }\nfunction $split_abort(i,b) { while($ksp>i)$kFn[--$ksp]=undefined; $sp=b; $tailFn=undefined; $tailCount=0; }\n"

# Trusted target runtime; public/native callback and reflection ABI is retained.
def js_runtime() -> String:
  "const $D = Object.create(null);\nconst $BEND_TAIL = Symbol(\"bend.tail\");\nconst $td = 64;\nconst $TAIL_PENDING = Object.create(null), $tailArgs = Array(32);\nconst $CALL_PENDING = Object.create(null), $LEAVE_PENDING = Object.create(null);\nconst $stArgs = [], $kFn = [], $kBase = [], $kKind = [];\nlet $sp = 0, $ksp = 0, $leaveThunk;\nfunction $split(f,count,k,base) { $tailFn=f; $tailCount=count; $kFn[$ksp]=k; $kBase[$ksp]=base; $kKind[$ksp]=0; $ksp+=1; return $CALL_PENDING; }\nfunction $splitm(f,a,k,base) { $tailFn=f; $tailCount=-2; $tailRest=a; $kFn[$ksp]=k; $kBase[$ksp]=base; $kKind[$ksp]=0; $ksp+=1; return $CALL_PENDING; }\nfunction $split1(f,x,k,base) { const j=f[$BEND_TAIL]; $tailFn=j||f; $tailCount=j?-3:-1; $tailUnary=x; $kFn[$ksp]=k; $kBase[$ksp]=base; $kKind[$ksp]=0; $ksp+=1; return $CALL_PENDING; }\nfunction $frame(t,base) { $kFn[$ksp]=t; $kBase[$ksp]=base; $kKind[$ksp]=1; $ksp+=1; }\nlet $tailFn, $tailCount=0, $tailUnary, $tailRest;\nfunction tail_many(f,a) { $tailFn=f; $tailCount=-2; $tailRest=a; return $TAIL_PENDING; }\nfunction tail_unary(f,x) { $tailFn=f; $tailCount=-1; $tailUnary=x; return $TAIL_PENDING; }\nfunction tail_named(f,n) { $tailFn=f; $tailCount=n; return $TAIL_PENDING; }\nfunction $run(f, xs, n) { let x=run_loop(f); for (let i=0;i<n;i++) x=run_call1(x,xs[i]); return x; }\nfunction $curried(f, n, g, t, x, r) { const step = (args) => function (...more) { const xs = args.concat(more); if (xs.length < n) return step(xs); for (const i of g) xs[i] = nat_in(xs[i]); for (const i of t) xs[i] = str_in(xs[i]); for (const i of x) xs[i] = Math.fround(xs[i]); return r($run(f, xs, n)); }; return step([]); }\nfunction run_loop(x) { return run_base(x,$ksp,$sp); }\nfunction run_call1(f,a) { const b0=$ksp, s0=$sp; return run_base(f(a),b0,s0); }\nfunction run_base(x,k0,s0) { try { for(;;) { while (x===$TAIL_PENDING) { const f=$tailFn, count=$tailCount; $tailFn=undefined; $tailCount=0; if(count===-1) { const a=$tailUnary; $tailUnary=undefined; x=f(a,$BEND_TAIL); } else x=tail_dispatch(f,count); } if (x===$CALL_PENDING) { const f=$tailFn, count=$tailCount; $tailFn=undefined; $tailCount=0; if(count===1) { const a0=$tailArgs[0]; $tailArgs[0]=undefined; x=f(a0); } else if(count===2) { const a0=$tailArgs[0],a1=$tailArgs[1]; $tailArgs[0]=$tailArgs[1]=undefined; x=f(a0,a1); } else if(count===-1) { const a=$tailUnary; $tailUnary=undefined; x=f(a); } else if(count===-3) { const a=$tailUnary; $tailUnary=undefined; x=f(a,$BEND_TAIL); } else x=tail_dispatch(f,count); continue; } if (x===$LEAVE_PENDING) { let i=$ksp; while(i>k0&&($kKind[i-1]===0||$kFn[i-1]!==$leaveThunk))i-=1; if(i===k0)throw \"bend: a region leave reached no private frame\"; i-=1; const t=$kFn[i], b=$kBase[i]; $kFn[i]=undefined; $ksp=i; $sp=b; x=t(undefined,b); continue; } if ($ksp===k0) { $sp=s0; return x; } $ksp-=1; const k=$kFn[$ksp], b=$kBase[$ksp], r=$kKind[$ksp]; $kFn[$ksp]=undefined; $sp=b; if(r===1) continue; x=k(x,b); } } catch(e) { $ksp=k0; $sp=s0; $tailFn=undefined; $tailCount=0; throw e; } }\nfunction tail_dispatch(f,count) { switch(count) {\ncase -2: { const a=$tailRest; $tailRest=undefined; return f(...a); }\ncase 1: { const a0=$tailArgs[0]; $tailArgs[0]=undefined; return f(a0); }\ncase 2: { const a0=$tailArgs[0],a1=$tailArgs[1]; $tailArgs[0]=$tailArgs[1]=undefined; return f(a0,a1); }\ncase 3: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=undefined; return f(a0,a1,a2); }\ncase 4: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=undefined; return f(a0,a1,a2,a3); }\ncase 5: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=undefined; return f(a0,a1,a2,a3,a4); }\ncase 6: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=undefined; return f(a0,a1,a2,a3,a4,a5); }\ncase 7: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=undefined; return f(a0,a1,a2,a3,a4,a5,a6); }\ncase 8: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7); }\ncase 9: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8); }\ncase 10: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9); }\ncase 11: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10); }\ncase 12: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11); }\ncase 13: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12); }\ncase 14: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13); }\ncase 15: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14); }\ncase 16: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15); }\ncase 17: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16); }\ncase 18: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17); }\ncase 19: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18); }\ncase 20: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19); }\ncase 21: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20); }\ncase 22: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21); }\ncase 23: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22); }\ncase 24: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23); }\ncase 25: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24); }\ncase 26: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25); }\ncase 27: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26); }\ncase 28: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27); }\ncase 29: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28); }\ncase 30: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28],a29=$tailArgs[29]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=$tailArgs[29]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29); }\ncase 31: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28],a29=$tailArgs[29],a30=$tailArgs[30]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=$tailArgs[29]=$tailArgs[30]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30); }\ncase 32: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28],a29=$tailArgs[29],a30=$tailArgs[30],a31=$tailArgs[31]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=$tailArgs[29]=$tailArgs[30]=$tailArgs[31]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31); }\ndefault: throw \"bend: invalid private tail frame\";\n} }\nfunction run_force(x,raw,b0,s0) { return raw===$BEND_TAIL?x:run_base(x,b0,s0); }\nfunction run_many(f,a,d=$td) { return d<64?f(...a,d+1):tail_many(f,a); }\nfunction run_tail(f,x) { const j=f[$BEND_TAIL]; return j ? tail_unary(j,x) : f(x); }\nfunction run_clo(j) { j[$BEND_TAIL]=j; return j; }\nfunction nat_chk(x) { if(x>281474976710655) throw \"bend: a Nat past the largest immediate 2^48-1\"; return x; }\nfunction char_new(c) { return c < 0xD800 || c >= 0xE000 && c <= 0x10FFFF ? String.fromCodePoint(c) : String.fromCharCode(0xDC00, c >>> 22, c >>> 11 & 0x7FF, c & 0x7FF); }\nfunction char_len(s, at=0) { return s[at] === \"\\uDC00\" ? 4 : s.codePointAt(at) > 0xFFFF ? 2 : 1; }\nfunction char_code_at(s, at) { return s[at] === \"\\uDC00\" ? (s.charCodeAt(at+1) << 22 | s.charCodeAt(at+2) << 11 | s.charCodeAt(at+3)) >>> 0 : s.codePointAt(at); }\nfunction char_code(s) { return char_code_at(s, 0); }\nfunction str_out(s) { return s.replace(/\\uDC00[^]{3}/gu, \"\\uFFFD\"); }\nfunction str_in(s) { return s.replace(/\\p{Cs}/gu, \"\\uFFFD\"); }\nfunction cmp_new(a,b) { return {$:a<b?\"LT\":a===b?\"EQ\":\"GT\"}; }\nfunction word_to_u32(w) { let x=0; for(let i=0;w.$===\"WCon\";i++,w=w.tail) if(w.head)x|=1<<i; return x>>>0; }\nfunction u32_to_word(x) { let w={$:\"WNil\"}; for(let i=31;i>=0;i--) w={$:\"WCon\",head:!!((x>>>i)&1),tail:w}; return w; }\nfunction run_named1(f,a0,d) { return d<64?f(a0,d+1):($tailArgs[0]=a0,tail_named(f,1)); }\nfunction run_named2(f,a0,a1,d) { return d<64?f(a0,a1,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,tail_named(f,2)); }\nfunction run_named3(f,a0,a1,a2,d) { return d<64?f(a0,a1,a2,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,tail_named(f,3)); }\nfunction run_named4(f,a0,a1,a2,a3,d) { return d<64?f(a0,a1,a2,a3,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,tail_named(f,4)); }\nfunction run_named5(f,a0,a1,a2,a3,a4,d) { return d<64?f(a0,a1,a2,a3,a4,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,tail_named(f,5)); }\nfunction run_named6(f,a0,a1,a2,a3,a4,a5,d) { return d<64?f(a0,a1,a2,a3,a4,a5,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,tail_named(f,6)); }\nfunction run_named7(f,a0,a1,a2,a3,a4,a5,a6,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,tail_named(f,7)); }\nfunction run_named8(f,a0,a1,a2,a3,a4,a5,a6,a7,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,tail_named(f,8)); }\nfunction run_named9(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,tail_named(f,9)); }\nfunction run_named10(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,tail_named(f,10)); }\nfunction run_named11(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,tail_named(f,11)); }\nfunction run_named12(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,tail_named(f,12)); }\nfunction run_named13(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,tail_named(f,13)); }\nfunction run_named14(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,tail_named(f,14)); }\nfunction run_named15(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,tail_named(f,15)); }\nfunction run_named16(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,tail_named(f,16)); }\nfunction run_named17(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,tail_named(f,17)); }\nfunction run_named18(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,tail_named(f,18)); }\nfunction run_named19(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,tail_named(f,19)); }\nfunction run_named20(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,tail_named(f,20)); }\nfunction run_named21(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,tail_named(f,21)); }\nfunction run_named22(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,tail_named(f,22)); }\nfunction run_named23(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,tail_named(f,23)); }\nfunction run_named24(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,tail_named(f,24)); }\nfunction run_named25(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,tail_named(f,25)); }\nfunction run_named26(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,tail_named(f,26)); }\nfunction run_named27(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,tail_named(f,27)); }\nfunction run_named28(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,tail_named(f,28)); }\nfunction run_named29(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,tail_named(f,29)); }\nfunction run_named30(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,$tailArgs[29]=a29,tail_named(f,30)); }\nfunction run_named31(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,$tailArgs[29]=a29,$tailArgs[30]=a30,tail_named(f,31)); }\nfunction run_named32(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,$tailArgs[29]=a29,$tailArgs[30]=a30,$tailArgs[31]=a31,tail_named(f,32)); }\n"
def js_runtime_extra() -> String:
  "function f32_from_bits(x) { return new Float32Array(new Uint32Array([x]).buffer)[0]; }\nfunction f32_bits(x) { return new Uint32Array(new Float32Array([x]).buffer)[0]; }\nfunction tuple(a,b) { return {$:\"Tuple\",fst:a,snd:b}; }\nfunction f32_show(x) { if(x!==x) return \"nan\"; if(!Number.isFinite(x)||Object.is(x,-0)) return x<0?\"-inf\":x===0?\"-0\":\"inf\"; let s=\"x\"; for(let p=1;p<=9&&Math.fround(Number(s))!==x;p++) s=String(Number(x.toExponential(p-1))); return s; }\nfunction f32_round(s) { const d=Number(s); const a=Math.abs(d); const f=Math.fround(a); const g=2*a-Math.min(f,2**128); if(g===f||Math.fround(g)!==g||g===Infinity) return Math.sign(d)*f; let k=0; while(a*2**k%1!==0) k+=1; const m=/(\\d*)\\.?(\\d*)(?:e([+-]?\\d+))?$/i.exec(s); const n=Number(m[3]??0)-m[2].length; const x=BigInt(m[1]+m[2])*2n**BigInt(k)*10n**BigInt(Math.max(n,0)); const y=BigInt(a*2**k)*10n**BigInt(Math.max(-n,0)); return Math.sign(d)*(x===y||x>y!==g>f?f:g); }\nfunction f32_pow(a,b) { return (a === 1 || a === -1 && Math.abs(b) === Infinity ? 1 : Math.fround(Math.pow(a,b))); }\nfunction f32_read(s) { const re=/^[\\t\\n\\v\\f\\r ]*[+-]?((\\d+(?:\\.\\d*)?|\\.\\d+)(e[+-]?\\d+)?|inf(inity)?|nan)$/i; const v=f32_round(s.replace(/inf\\w*/i,\"Infinity\")); return re.test(s)?{$:\"Some\",value:v}:{$:\"None\"}; }\nfunction nat_divmod(a,b) { return b===0?tuple(0,a):tuple(Math.trunc(a/b),a%b); }\nfunction nat_in(n) { if(!Number.isInteger(n)||n<0||n>9007199254740992)throw \"bend: expected a Nat host number: an integer from 0 to 2^53\"; return n; }\nfunction array_new(n,v) { if(n>31) throw \"bend: an array past the deepest block class 31\"; return Array(2 ** n).fill(v); }\nfunction array_node(a,b) { if(a.length!==b.length) throw \"bend: runtime fail-stop\"; return a.concat(b); }\n"
def js_runtime_array() -> String:
  "function array_swap(a,i,v) { const at=i%a.length, old=a[at]; a[at]=v; return tuple(a,old); }\nfunction array_rmw(a,i,f) { const at=i%a.length, old=a[at]; a[at]=f(old); return tuple(a,old); }\n"
def js_runtime_foreign() -> String:
  "const $0eff=Object.create(null);\nfunction io_emit(value) { return {$:\"Emit\",value}; }\nfunction io_eff(k,run) { if(arguments.length>2)throw new Error(\"bend: \"+k+\" takes no need: an effect that waits parks itself\"); if(k in $0eff)throw new Error(\"bend: two effects register \"+k); $0eff[k]=run; }\n"
def js_runtime_namespace() -> String:
  "function $key(k,s,a) { let p=null; for (const alias of Object.keys(a)) if(k.startsWith(alias+\".\") && (p===null || alias.length>p.length)) p=alias; const n=p===null?undefined:a[p]; return n===undefined?(s?s+\".\"+k:k):(n?n+\".\":\"\")+k.slice(p.length+1); }\nfunction $resolve(k,s,a) { const q=$key(k,s,a); return $D[Object.hasOwn($D,q)?q:k]; }\nconst $FIELDS=Object.create(null), $PRIMITIVES=Object.create(null), $TYPE=Object.create(null), $TYPEF=Object.create(null), $PARAMS=Object.create(null);\nfunction $ctr(k,x,s,a) { const q=$key(k,s,a), key=Object.hasOwn($FIELDS,q)?q:k, fs=$FIELDS[key]; if(!fs||fs.length!==x.length)throw \"bend: unresolved constructor layout\"; const v={$:key}; for(let i=0;i<fs.length;i++){const f=fs[i];if(f!==null){if(f===\"__proto__\")Object.defineProperty(v,f,{value:x[i],enumerable:true,writable:true,configurable:true});else v[f]=x[i];}} return v; }\nfunction $project(v,k,i,s,a) { const q=$key(k,s,a),fs=$FIELDS[q]||$FIELDS[k]; if(!fs)throw \"bend: unresolved constructor layout\"; for(const f of fs)if(f!==null&&i--===0)return v[f]; throw \"bend: constructor field count mismatch\"; }\n"
def js_runtime_cli() -> String:
  "let cli_args = [];\nfunction cli(argv) {\n  let rts = false;\n  cli_args.push(argv[0]);\n  for (let i = 1; i < argv.length; i += 1) {\n    const a = argv[i];\n    if (a === \"--RTS\") {\n      cli_args.push(...argv.slice(i + 1));\n      break;\n    } else if (a === \"+RTS\" || a === \"-RTS\") {\n      rts = a === \"+RTS\";\n    } else if (!rts) {\n      cli_args.push(a);\n    } else if (a === \"--help\" || a === \"--gpu-build\") {\n      io_out(1, io_bytes(a === \"--help\" ? \"usage: \" + argv[0] + \"\\n\" : \"\"));\n      process.exit(0);\n    } else {\n      const re = a === \"--threads\" ? /^0*[1-9]\\d*$/ : a === \"--gpu\"\n        ? /^(on|off|(\\d*\\.?\\d*)([GM])B)$/ : undefined;\n      const m = re?.exec(argv[++i]);\n      if (!m || m[3]\n        && !(m[2] * (m[3] === \"G\" ? 2 ** 30 : 2 ** 20) >= 16384)) {\n        io_errs(\"bend: \" + (re === undefined ? \"unknown runtime option \" + a\n          : a === \"--gpu\" ? \"expected on, off or a size like 4GB after --gpu\"\n          : \"expected a thread count of 1 or more after --threads\"));\n        process.exit(1);\n      }\n    }\n  }\n}\n"
def js_runtime_io() -> String:
  "function io_out(fd,data) { const fs=require(\"fs\"), b=Buffer.from(data); let at=0; while(at<b.length){ try{ at+=fs.writeSync(fd,b,at,b.length-at); } catch(e){ if(e.code===\"EAGAIN\"||e.code===\"EINTR\")continue; if(e.code===\"EPIPE\"){process.on(\"SIGPIPE\",()=>{}).removeAllListeners(\"SIGPIPE\").kill(process.pid,\"SIGPIPE\");} try{fs.writeSync(2,\"bend: a short write on a standard stream\\n\");}catch(o){} process.exit(1);} } }\nfunction io_errs(message) { io_out(2,io_bytes(message+\"\\n\")); }\nfunction io_bytes(text) { return new TextEncoder().encode(str_out(text)); }\nfunction io_text(b,n) { return new TextDecoder(\"utf-8\",{ignoreBOM:true}).decode(b.subarray(0,n)); }\nfunction io_list(b,n) { let xs={$:\"Nil\"}; while(n>0){ xs={$:\"Con\",head:b[--n],tail:xs}; } return xs; }\nfunction io_unlist(xs) { const b=[]; for(;xs.$===\"Con\";xs=xs.tail){ b.push(xs.head); } return b.some(x=>x>255)?null:Uint8Array.from(b); }\nfunction io_addr(host,port) { const part=host.split(\".\"); const deci=p=>/^(0|[1-9]\\d{0,2})$/.test(p)&&Number(p)<256; if(port>65535||part.length!==4||!part.every(deci))return null; const b=new Uint8Array(16); const head=io_sys().mac?[16,2]:[2,0]; b.set([...head,port>>8,port&255,...part.map(Number)]); return b; }\nfunction io_tup(...xs) { return xs.reduceRight((snd,fst)=>({$:\"Tuple\",fst,snd})); }\nfunction io_done(value) { return {$:\"Done\",value}; }\nfunction io_strerror(code) { try{ return String(io_sys().strerror(code)); } catch(o){ return \"errno \"+code; } }\nfunction io_fail(code,...rest) { const err=io_tup(code>>>0,io_strerror(code)); return {$:\"Fail\",error:io_tup(err,...rest)}; }\nfunction io_until(ms) { return performance.now()+Number(ms); }\nfunction io_late(at) { return at!==undefined&&performance.now()>=at; }\nfunction io_ready(at,r) { return at===undefined?r:{$:\"Ready\",value:r}; }\nfunction io_sys() { if(globalThis.BEND_SYS===undefined){ const ffi=require(\"bun:ffi\"), mac=process.platform===\"darwin\", err=mac?\"__error\":\"__errno_location\", sel=mac?\"select$DARWIN_EXTSN\":\"select\", T={i:\"i32\",u:\"u32\",U:\"u64\",I:\"i64\",p:\"ptr\",c:\"cstring\"}, vari=mac&&process.arch===\"arm64\", lib=ffi.dlopen(mac?\"libSystem.dylib\":\"libc.so.6\",Object.fromEntries((\"socket:iii>i bind:ipu>i listen:ii>i connect:ipu>i accept:ipp>i send:ipUi>I recv:ipUi>I read:ipU>I pread:ipUI>I sendto:ipUipu>I recvfrom:ipUipp>I close:i>i setsockopt:iiipu>i \"+sel+\":ipppp>i\"+(vari?\" fcntl:iiiiiiiii>i\":\" fcntl:iii>i\")+\" getsockopt:iiipp>i strerror:i>c \"+err+\":>p\").split(\" \").map(s=>{const [name,args,ret]=s.split(/[:>]/);return [name,{args:[...args].map(a=>T[a]),returns:T[ret]}]}))).symbols; const fcntl=(fd,cmd,arg)=>vari?lib.fcntl(fd,cmd,0,0,0,0,0,0,arg):lib.fcntl(fd,cmd,arg); globalThis.BEND_SYS={...lib,fcntl,select:lib[sel],ptr:ffi.ptr,mac,errno:()=>ffi.read.i32(lib[err](),0)}; } return globalThis.BEND_SYS; }\nfunction io_push(fun,arg,fresh) { const io=globalThis.BEND_IO; io.runs.push({fun,arg}); io.live+=fresh?1:0; }\nfunction io_park_on(fd,out,k,more,at) { const ws=globalThis.BEND_IO.waits; const i=ws.findLastIndex(w=>(w.at??Infinity)<=(at??Infinity)); ws.splice(i+1,0,{fd,out,k,more,at}); }\nfunction io_wait(io,block) { const soon=io.waits[0]?.at??Infinity; const ms=!block?0:soon===Infinity?-1:Math.max(0,Math.ceil(soon-performance.now())); const fds=io.waits.filter(w=>w.fd!==undefined); const top=fds.reduce((m,w)=>Math.max(m,w.fd),0); const len=(top>>6<<3)+8; const set=new Uint8Array(2*len); const at=w=>(w.out?len:0)+(w.fd>>3); for(const w of fds)set[at(w)]|=1<<(w.fd&7); const tv=new BigInt64Array([BigInt(ms/1000|0),BigInt(ms%1000*1000)]); const sys=io_sys(); if(sys.select(top+1,sys.ptr(set),sys.ptr(set,len),null,ms<0?null:sys.ptr(tv))<0){ if(sys.errno()!==4){ throw \"bend: the poller failed\"; } set.fill(0); } const now=performance.now(); const due=w=>w.at<=now||w.fd!==undefined&&set[at(w)]&1<<(w.fd&7); const todo=io.waits; io.waits=todo.filter(w=>!due(w)); for(const w of todo.filter(due)){ const x=w.more(); if(x!==undefined)io_push(w.k,x,false); } }\nfunction io_run(m) { const io={runs:[],live:0,waits:[]}; globalThis.BEND_IO=io; try{ io_push(run_loop(m()),x=>({$:\"Emit\",value:x}),true); let look=0; for(let n=0;;n+=1){ if(io.runs.length===0){ if(io.live===0)return 0; if(io.waits.length===0){ io_errs(\"bend: deadlock: every computation waits on a channel\"); return 1; } io_wait(io,true); continue; } if((n&63)===0&&io.waits.length>0){ const now=performance.now(); if(now>=look||io.waits[0].at<=now){ look=now+10; io_wait(io,false); } } const s=io.runs.shift(); let op=s.fun(s.arg); while(op!==undefined){ if(op.$===\"Emit\"){ io.live-=1; break; } if(op.$===\"Halt\"||op.$===\"Exit\"){ if(op.$===\"Halt\")io_errs(op.message); if(op.code>255){ io_errs(\"bend: exit code must be in 0..255\"); return 1; } return op.code; } const run=$0eff[op.$]; if(run===undefined){ throw \"bend: no effect registers \"+op.$; } const x=run(...op.args,op.kont); if(x===undefined)break; op=op.kont(x); } } }catch(e){ throw e instanceof RangeError?\"bend: memory fault (machine stack overflow?)\":e; } }\nfunction io_exit(main,type) { try{ if(type&&type.name===\"IO\")return io_run(main); io_out(1,io_bytes($show_value(type,run_loop(main()),0)+\"\\n\")); return 0; }catch(e){ io_errs(String(e)); return 1; } }\n"
def js_runtime_show() -> String:
  String.append(js_runtime_type(), "function $show_chr(s,q) { const c=char_code(s), k=({10:\"n\",9:\"t\",13:\"r\",0:\"0\",92:\"\\\\\"})[c]??(s===q&&q); return k?\"\\\\\"+k:c<32||c===127||s.length>2||(c>=0xD800&&c<0xE000)?\"\\\\u{\"+c.toString(16)+\"}\":s; }\nfunction $show_list(t,x) { const xs=[]; while(x&&x.$===\"Con\") { const fs=t.arms.Con; if(!fs||!Object.hasOwn(x,\"head\")||!Object.hasOwn(x,\"tail\")) throw \"bend: malformed List.Con\"; xs.push($show_value($type(fs.types[0],t.args),x.head,0)); const next=$type(fs.types[1],t.args.concat([x.head])); x=x.tail; t=next; } if(!x||x.$!==\"Nil\") throw \"bend: malformed List.Nil\"; return \"[\"+xs.join(\", \")+\"]\"; }\nfunction $show_fields(t,x,chain) { const fs=t.arms[x.$]; if(!fs) throw \"bend: constructor absent from result datatype\"; const out=[],env=t.args.slice(); let at=0; for(let j=0;j<fs.types.length;j++) { if(fs.q[j]===0) { env.push(null); continue; } const name=fs.fields[j]; if(!Object.hasOwn(x,name))throw \"bend: constructor field count mismatch\"; const v=x[name]; at++; out.push($show_value($type(fs.types[j],env),v,chain&&at===2?\"(\":0)); env.push(v); } return out.join(\", \"); }\nfunction $show_value(t,x,chain) { if(!t) return String(x); if(t.k===\"U\") return String(x); if(t.k===\"F\") { const s=f32_show(x); return s.replace(/^-?\\d+(?=e|$)/i,\"$&.0\"); } if(t.k===\"N\") return x+\"n\"; if(t.k===\"C\") return \"'\"+$show_chr(x,\"'\")+\"'\"; if(t.k===\"S\") return \"\\\"\"+x.replace(/\\uDC00[^]{3}|[^]/gu,c=>$show_chr(c,\"\\\"\"))+\"\\\"\"; if(t.k===\"E\") return \"{==}\"; if(t.k===\"A\") return \"[\"+x.map(v=>$show_value(t.e,v,0)).join(\", \")+\"]\"; if(typeof x===\"boolean\") return x?\"True{}\":\"False{}\"; if(!x||typeof x!==\"object\"||!x.$) return String(x); if(t.native===\"List\") return $show_list(t,x); if(t.native===\"Sigma\"&&x.$===\"Tuple\") { const c=chain===\"(\"; return (c?\"\":\"(\")+$show_fields(t,x,true)+(c?\"\":\")\"); } if(t.k!==\"D\") throw \"bend: expected a datatype result\"; return x.$+\"{\"+$show_fields(t,x,false)+\"}\"; }\n")
# Metadata evaluation retains every source formal slot, including erased type
# arguments, but delays terms until reduction needs them. It never calls an
# ordinary erased-value function or executes an unused proof/index expression.
def js_runtime_type() -> String:
  String.append(js_runtime_native_type(), String.append(js_runtime_type_names(), String.append(js_runtime_type_patterns(), js_runtime_type_eval())))
def js_runtime_type_names() -> String:
  "function $type_key(k,s,i) { const q=$key(k,s,i||{}); return $TYPE[q]!==undefined||$TYPEF[q]!==undefined?q:k; }\nfunction $type_ctor_key(k,s,i) { const q=$key(k,s,i||{}); return $FIELDS[q]!==undefined?q:k; }\nfunction $type_delay(t,a) { if(t.k)return t; if(t.p!==undefined&&a[a.length-1-t.p]!==undefined)return a[a.length-1-t.p]; return {k:\"Thunk\",term:t,env:a,depth:a.length,done:false}; }\nfunction $type_force(v) { if(v&&v.k===\"Thunk\") { if(!v.done) { v.value=$type(v.term,v.env.length===v.depth?v.env:v.env.slice(0,v.depth)); v.done=true; } return v.value; } return v; }\nfunction $type_apply(f,x) { f=$type_force(f); if(f.k===\"L\") return $type(f.body,f.env.concat([x])); if(f.k===\"TF\"||f.k===\"DF\") return $type_named(f.key,f.args.concat([x])); throw \"bend: type expression applied a non-function\"; }\nfunction $type_named(q,ps) { const f=$TYPEF[q]; if(f) { if(ps.length<f.n)return {k:\"TF\",key:q,args:ps}; let v=f.intrinsic?$type_native_invoke(f,ps):$type(f.body,ps.length===f.n?ps:ps.slice(0,f.n)); for(let i=f.n;i<ps.length;i++)v=$type_apply(v,ps[i]); if(f.native===\"IO\")v.name=\"IO\"; return v; } const d=$TYPE[q]; if(!d) throw \"bend: unresolved type expression \"+q; const p=$PARAMS[q]; if(ps.length<p.n)return {k:\"DF\",key:q,args:ps}; if(ps.length!==p.n)throw \"bend: datatype parameter count mismatch\"; if(d.native===\"Array\") return {k:\"A\",e:$type_force(ps[0])}; const k=({U32:\"U\",F32:\"F\",Nat:\"N\",Char:\"C\",String:\"S\",Eql:\"E\"})[d.native]; return k?{k}:{k:\"D\",key:q,name:d.name,native:d.native,arms:d.arms,args:ps}; }\n"
def js_runtime_type_patterns() -> String:
  "function $type_sugar(t,a) { const h=$type(t.sugar,a),more=t.a.map(x=>$type_delay(x,a)); if(h.k===\"TF\"||h.k===\"DF\"||h.k===\"D\") { const q=h.key,p=$PARAMS[q]; let xs=h.args.concat(more); if(p&&xs.length+p.q===p.n)xs=Array.from({length:p.q},()=>({k:\"Q\",v:t.f})).concat(xs); if(p&&t.f===2)xs=xs.map((x,i)=>i<p.q?({k:\"Q\",v:2}):x); return $type_named(q,xs); } let v=h; for(const x of more)v=$type_apply(v,x); return v; }\nfunction $type_pattern(p,v,bindings) { if(p.v) { bindings.push(v); return true; } v=$type_force(v); const q=$type_ctor_key(p.c,p.s,p.i),c=$PRIMITIVES[q]||($FIELDS[q]===undefined?q:\"\"); let fields,complete=false; if(v&&v.k===\"V\") { if(v.c!==q)return false; fields=v.args; complete=true; } else if(v&&v.$===q) { const names=$FIELDS[q]; if(!names||names.length!==p.fields.length)return false; for(let j=0;j<names.length;j++){if(names[j]===null){bindings.push(null);continue;}if(!$type_pattern(p.fields[j],v[names[j]],bindings))return false;}return true; } else if(c===\"Bool.True\"&&v===true||c===\"Bool.False\"&&v===false||c===\"Nat.Zero\"&&v===0||c===\"String.SNil\"&&v===\"\") fields=[]; else if(c===\"Nat.Succ\"&&typeof v===\"number\"&&v>0)fields=[v-1]; else if(c===\"String.SCon\"&&typeof v===\"string\"&&v.length)fields=[v.slice(0,char_len(v)),v.slice(char_len(v))]; else if(c===\"Char.Chr\"&&typeof v===\"string\")fields=[char_code(v)]; else if(c===\"U32.U32\"&&typeof v===\"number\")fields=[u32_to_word(v)]; else if(c===\"F32.F32\"&&typeof v===\"number\")fields=[u32_to_word(f32_bits(v))]; else if(c===\"Array.ALeaf\"&&Array.isArray(v)&&v.length===1)fields=[v[0]]; else if(c===\"Array.ANode\"&&Array.isArray(v)&&v.length!==1)fields=[v.slice(0,v.length>>1),v.slice(v.length>>1)]; else return false; let at=0; for(const field of p.fields) { if(!complete&&field.v&&field.q===0) { bindings.push(null); continue; } if(at>=fields.length||!$type_pattern(field,fields[at++],bindings))return false; } return at===fields.length; }\nfunction $type_bind(patterns,values) { if(patterns.length!==values.length)return null; const bindings=[]; for(let j=0;j<values.length;j++)if(!$type_pattern(patterns[j],values[j],bindings))return null; return bindings; }\n"
def js_runtime_type_eval() -> String:
  "function $type(t,a=[]) { if(t===null)return null; if(t===undefined)throw \"bend: missing type expression\"; if(t.p!==undefined) { const v=$type_force(a[a.length-1-t.p]); if(v===undefined||v===null)throw \"bend: unavailable type-expression binder\"; return v; } if(t.k)return $type_force(t); if(t.fail)throw t.fail; if(t.kind!==undefined)return {k:\"K\",q:$type(t.kind,a)}; if(t.min!==undefined)return {k:\"Q\",v:Math.min($type(t.min,a).v,$type(t.right,a).v)}; if(t.all!==undefined)return {k:\"Fn\",q:t.q,domain:$type(t.all,a),body:t.body,env:a}; if(t.lam!==undefined)return {k:\"L\",body:t.lam,env:a}; if(t.app!==undefined)return $type_apply($type(t.app,a),$type_delay(t.arg,a)); if(t.sub!==undefined) { const env=a.slice(); env.splice(env.length-t.sub,0,$type_delay(t.value,a)); return $type(t.body,env); } if(t.let!==undefined)return $type(t.body,a.concat(t.let.map(x=>$type_delay(x,a)))); if(t.local!==undefined) { const bs=$type_bind(t.pat,t.local.map(x=>$type_delay(x,a))); if(bs===null)throw \"bend: type expression local pattern failed\"; return $type(t.body,a.concat(bs)); } if(t.bind!==undefined)return $type(t.body,a.concat([$type_delay(t.bind,a)])); if(t.match!==undefined) { const vs=t.match.map(x=>$type_delay(x,a)); for(const c of t.cases) { const bs=$type_bind(c.pat,vs); if(bs!==null)return $type(c.body,a.concat(bs)); } throw \"bend: type expression match failed\"; } if(t.c!==undefined)return {k:\"V\",c:$type_ctor_key(t.c,t.s,t.i),args:t.a.map(x=>$type_delay(x,a))}; if(t.sugar!==undefined)return $type_sugar(t,a); if(t.f) { const q=$type_key(t.r,t.s,t.i),p=$PARAMS[q]; if(!p&&t.f===2)return $type(t.h,a); let xs=t.a||[]; if(p&&xs.length+p.q===p.n)xs=Array.from({length:p.q},()=>({k:\"Q\",v:1})).concat(xs); if(p&&t.f===2)xs=xs.map((x,i)=>i<p.q?({k:\"Q\",v:2}):x); return $type_named(q,xs.map(x=>$type_delay(x,a))); } if(t.r!==undefined)return $type_named($type_key(t.r,t.s,t.i),(t.a||[]).map(x=>$type_delay(x,a))); throw \"bend: unsupported type-expression descriptor\"; }\n"
def js_runtime_native_type() -> String:
  "function $type_native_invoke(f,ps) { let value=f.intrinsic; for(let i=0;i<f.n;i++)if(f.q[i]!==0)value=value($type_runtime_value(ps[i])); return value; }\nfunction $type_runtime_value(value) { const v=$type_force(value); if(!v||v.k!==\"V\")return v; const c=$PRIMITIVES[v.c]||($FIELDS[v.c]===undefined?v.c:\"\"),xs=v.args; switch(c) { case \"Nat.Zero\":return 0; case \"Nat.Succ\":return nat_chk($type_runtime_value(xs[0])+1); case \"Bool.False\":return false; case \"Bool.True\":return true; case \"String.SNil\":return \"\"; case \"String.SCon\":return $type_runtime_value(xs[0])+$type_runtime_value(xs[1]); case \"Char.Chr\":return char_new($type_runtime_value(xs[0])); case \"U32.U32\":return word_to_u32($type_runtime_value(xs[0])); case \"F32.F32\":return f32_from_bits(word_to_u32($type_runtime_value(xs[0]))); case \"Array.ALeaf\":return [$type_runtime_value(xs[0])]; case \"Array.ANode\":return $type_runtime_value(xs[0]).concat($type_runtime_value(xs[1])); } const fs=$FIELDS[v.c]; if(!fs||fs.length!==xs.length)throw \"bend: unresolved metadata constructor\"; const args=xs.map((x,i)=>fs[i]===null?null:$type_runtime_value(x)); return $ctr(v.c,args,\"\",{}); }\n"
def js_main(type_expression: String) -> String:
  String.append("if (typeof process !== \"undefined\" && process.argv[1] && /\\.js$/.test(process.argv[1])) { cli(process.argv.slice(1)); if(Object.hasOwn($D,\"main\")) { process.exitCode=io_exit(()=>$D[\"main\"],$type(", String.append(type_expression, ")); } }\n"))
