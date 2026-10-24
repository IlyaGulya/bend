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
    case _: String.from_list([char])

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
def foreign_kont(checked: Bool) -> String:
  match checked:
    case True{}: "((x)=>$k(nat_in(x)))"
    case False{}: "$k"
def foreign_request(+key: String, count: Nat, checked: Bool) -> String:
  names = foreign_parameters(count, 0n)
  body = cat(["({$:", js_quote(key), ",args:[", String.join(names, ","), "],kont:", foreign_kont(checked), "})"])
  cat(["$D[", js_quote(key), "]=", foreign_arrow(List.append(&2, String, names, ["$k"]), body), ";\n"])

# The answer type of a foreign IO(A) is the continuation's domain A. The
# descriptor of the declared result is the only authoritative source: a named
# or unnamed application whose head is IO carries A as its argument.
type JSDescriptorHead is Data:
  JSDescriptorHead{key: String, args: List<&2, BIR.Descriptor>}
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
    case True{}: js_parameter_arity_count(Nat.is_eq(List.length(&2, BIR.Descriptor, args), 0n))
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
def operation(op: BIR.Op) -> String:
  match op:
    case BIR.Copy{value}: atom(value)
    case BIR.PrimitiveCall{primitive, args, _}: cat([primitive_name(primitive), "(", String.join(arguments(args), ","), ")"])
    case BIR.Closure{code, captures, parameters}: closure(code, captures, parameters)
    case BIR.Direct{code, args}: cat(["run_loop(", call(code, arguments(args)), ")"])
    case BIR.Apply{fn, BIR.Arg{_, value}}: cat(["run_loop(run_tail(", atom(fn), ",", atom(value), "))"])
    case BIR.LoadSymbol{_, key}: cat(["$D[", js_quote(key), "]"])
    case BIR.Construct{_, tag, fields}: cat(["({$:", js_quote(tag), record_fields(fields), "})"])
    case BIR.Project{value, _, _, key}: cat([atom(value), "[", js_quote(key), "]"])
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
def declaration(item: BIR.Declaration, +natives: Map<&2, String>) -> String:
  match item:
    case BIR.FunctionDeclaration{key, code, parameters}:
      cat(["$D[", js_quote(key), "]=", closure(code, Nil{}, parameters), ";\n"])
    case BIR.LazyDeclaration{key, body}:
      deferred(key, cat(["(()=>{", block(body), "})()"]))
    case BIR.NativeDeclaration{key, primitive, uses}:
      native_declaration(key, primitive, uses)
    case BIR.ForeignDeclaration{key, _, imported, arity, decl_sources, _, _, _, result}:
      foreign_declaration(key, imported, decl_sources, arity, result, natives)
def foreign_declaration(+key: String, imported: String, sources: List<&2, String>, arity: Nat, result: BIR.Descriptor, +natives: Map<&2, String>) -> String:
  foreign_source(js_source(sources), key, imported, arity, result, natives)
def foreign_source(chosen: Maybe<&2, String>, +key: String, +imported: String, arity: Nat, result: BIR.Descriptor, +natives: Map<&2, String>) -> String:
  match chosen:
    case Some{_}: foreign_request(key, arity, js_nat_answer(result, natives))
    case None{}:
      # link() rejects this declaration before emission; keep the render total.
      deferred(key, cat(["(()=>{throw new Error(", js_quote(String.append("bend: foreign definition has no .js import: ", imported)), ")})()"]))
def native_declaration(+key: String, primitive: BIR.Primitive, +uses: List<&2, BIR.Quantity>) -> String:
  cat(["$D[", js_quote(key), "]=", primitive_public(primitive), ";\n$TYPEF[", js_quote(key), "]={n:", Nat.show(List.length(&2, BIR.Quantity, uses)), ",q:[", String.join(quantities(uses), ","), "],intrinsic:$D[", js_quote(key), "]};\n"])
def declarations(items: List<&2, BIR.Declaration>, +natives: Map<&2, String>) -> String:
  match items:
    case Nil{}: ""
    case item <> rest: cat([declaration(item, natives), declarations(rest, natives)])
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
    case +item <> rest: export_argument(js_parameter(item, natives), index) <> export_arguments(rest, natives, (index + 1n : Nat))
def export_argument(parameter: JSParameter, index: Nat) -> String:
  match parameter:
    case JSParameterNat{}: cat(["nat_in(arguments[", Nat.show(index), "])"])
    case _: cat(["arguments[", Nat.show(index), "]"])
def export_unresolved(+key: String, items: List<&2, BIR.Descriptor>, +natives: Map<&2, String>) -> Bool:
  match items:
    case Nil{}: False{}
    case +item <> rest: export_unresolved_item(js_parameter(item, natives), key, rest, natives)
def export_unresolved_item(kind: JSParameter, +key: String, rest: List<&2, BIR.Descriptor>, +natives: Map<&2, String>) -> Bool:
  match kind:
    case JSParameterUnresolved{}: True{}
    case _: export_unresolved(key, rest, natives)
def export_field(item: BIR.Export, +natives: Map<&2, String>) -> String:
  match item:
    case BIR.Export{+key, None{}, +parameters}:
      cat(["[", js_quote(key), "]:(...args)=>$run($D[", js_quote(key), "],[", String.join(export_arguments(parameters, natives, 0n), ","), "])"])
    case BIR.Export{+key, Some{BIR.Entry{code, +arity}}, +parameters}:
      cat(["[", js_quote(key), "](){return arguments.length===", Nat.show(arity), "?run_loop(", call(code, export_arguments(parameters, natives, 0n)), "):$run($D[", js_quote(key), "],[", String.join(export_arguments(parameters, natives, 0n), ","), "]);}"])
def export_fields(items: List<&2, BIR.Export>, +natives: Map<&2, String>) -> List<&2, String>:
  match items:
    case Nil{}: Nil{}
    case item <> rest: export_field(item, natives) <> export_fields(rest, natives)
def ending(item: BIR.Ending, +natives: Map<&2, String>) -> String:
  match item:
    case BIR.Executable{main_type}: js_main(descriptor(main_type))
    case BIR.Library{exports}: cat(["export default {", String.join(export_fields(exports, natives), ","), "};\n"])
# A generic export parameter is a real abstract domain: it is not Nat and the
# host passes it through unchanged. Only a missing canonical symbol fails.
def export_check(items: List<&2, BIR.Export>, +natives: Map<&2, String>) -> Maybe<&2, String>:
  match items:
    case Nil{}: None{}
    case BIR.Export{+key, _, parameters} <> rest:
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
  match program:
    case BIR.Program{bodies, values, layouts, types, functions, end}:
      cat([js_runtime(), js_runtime_extra(), js_runtime_show(), js_runtime_cli(), js_runtime_io(), js_runtime_array(), js_runtime_foreign(), js_runtime_namespace(), primitive_runtime(), constructor_layouts(layouts), families(types), type_functions(functions), effects, codes(bodies), declarations(values, natives), ending(end, natives)])

# Trusted target runtime; public/native callback and reflection ABI is retained.
def js_runtime() -> String:
  "const $D = Object.create(null);\nconst $BEND_TAIL = Symbol(\"bend.tail\");\nconst $td = 64;\nconst $TAIL_PENDING = Object.create(null), $tailArgs = Array(32);\nlet $tailFn, $tailCount=0, $tailUnary, $tailRest;\nfunction tail_many(f,a) { $tailFn=f; $tailCount=-2; $tailRest=a; return $TAIL_PENDING; }\nfunction tail_unary(f,x) { $tailFn=f; $tailCount=-1; $tailUnary=x; return $TAIL_PENDING; }\nfunction tail_named(f,n) { $tailFn=f; $tailCount=n; return $TAIL_PENDING; }\nfunction $run(f, xs) { let x=run_loop(f); for (const a of xs) x=run_loop(x(a)); return x; }\nfunction run_loop(x) { while (x===$TAIL_PENDING) { const f=$tailFn, count=$tailCount; $tailFn=undefined; $tailCount=0; if(count===-1) { const a=$tailUnary; $tailUnary=undefined; x=f(a,$BEND_TAIL); } else x=tail_dispatch(f,count); } return x; }\nfunction tail_dispatch(f,count) { switch(count) {\ncase -2: { const a=$tailRest; $tailRest=undefined; return f(...a); }\ncase 1: { const a0=$tailArgs[0]; $tailArgs[0]=undefined; return f(a0); }\ncase 2: { const a0=$tailArgs[0],a1=$tailArgs[1]; $tailArgs[0]=$tailArgs[1]=undefined; return f(a0,a1); }\ncase 3: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=undefined; return f(a0,a1,a2); }\ncase 4: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=undefined; return f(a0,a1,a2,a3); }\ncase 5: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=undefined; return f(a0,a1,a2,a3,a4); }\ncase 6: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=undefined; return f(a0,a1,a2,a3,a4,a5); }\ncase 7: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=undefined; return f(a0,a1,a2,a3,a4,a5,a6); }\ncase 8: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7); }\ncase 9: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8); }\ncase 10: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9); }\ncase 11: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10); }\ncase 12: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11); }\ncase 13: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12); }\ncase 14: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13); }\ncase 15: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14); }\ncase 16: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15); }\ncase 17: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16); }\ncase 18: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17); }\ncase 19: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18); }\ncase 20: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19); }\ncase 21: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20); }\ncase 22: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21); }\ncase 23: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22); }\ncase 24: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23); }\ncase 25: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24); }\ncase 26: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25); }\ncase 27: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26); }\ncase 28: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27); }\ncase 29: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28); }\ncase 30: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28],a29=$tailArgs[29]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=$tailArgs[29]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29); }\ncase 31: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28],a29=$tailArgs[29],a30=$tailArgs[30]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=$tailArgs[29]=$tailArgs[30]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30); }\ncase 32: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28],a29=$tailArgs[29],a30=$tailArgs[30],a31=$tailArgs[31]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=$tailArgs[29]=$tailArgs[30]=$tailArgs[31]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31); }\ndefault: throw \"bend: invalid private tail frame\";\n} }\nfunction run_force(x,raw) { return raw===$BEND_TAIL?x:run_loop(x); }\nfunction run_many(f,a,d=$td) { return d<64?f(...a,d+1):tail_many(f,a); }\nfunction run_tail(f,x) { const j=f[$BEND_TAIL]; return j ? tail_unary(j,x) : f(x); }\nfunction run_clo(j) { j[$BEND_TAIL]=j; return j; }\nfunction nat_chk(x) { if(x>281474976710655) throw \"bend: a Nat past the largest immediate 2^48-1\"; return x; }\nfunction char_new(x) { if(x>0x10ffff || (x>=0xd800 && x<=0xdfff)) throw \"bend: \"+x+\" is not a Unicode scalar value\"; return String.fromCodePoint(x); }\nfunction cmp_new(a,b) { return {$:a<b?\"LT\":a===b?\"EQ\":\"GT\"}; }\nfunction word_to_u32(w) { let x=0; for(let i=0;w.$===\"WCon\";i++,w=w.tail) if(w.head)x|=1<<i; return x>>>0; }\nfunction u32_to_word(x) { let w={$:\"WNil\"}; for(let i=31;i>=0;i--) w={$:\"WCon\",head:!!((x>>>i)&1),tail:w}; return w; }\nfunction run_named1(f,a0,d) { return d<64?f(a0,d+1):($tailArgs[0]=a0,tail_named(f,1)); }\nfunction run_named2(f,a0,a1,d) { return d<64?f(a0,a1,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,tail_named(f,2)); }\nfunction run_named3(f,a0,a1,a2,d) { return d<64?f(a0,a1,a2,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,tail_named(f,3)); }\nfunction run_named4(f,a0,a1,a2,a3,d) { return d<64?f(a0,a1,a2,a3,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,tail_named(f,4)); }\nfunction run_named5(f,a0,a1,a2,a3,a4,d) { return d<64?f(a0,a1,a2,a3,a4,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,tail_named(f,5)); }\nfunction run_named6(f,a0,a1,a2,a3,a4,a5,d) { return d<64?f(a0,a1,a2,a3,a4,a5,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,tail_named(f,6)); }\nfunction run_named7(f,a0,a1,a2,a3,a4,a5,a6,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,tail_named(f,7)); }\nfunction run_named8(f,a0,a1,a2,a3,a4,a5,a6,a7,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,tail_named(f,8)); }\nfunction run_named9(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,tail_named(f,9)); }\nfunction run_named10(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,tail_named(f,10)); }\nfunction run_named11(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,tail_named(f,11)); }\nfunction run_named12(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,tail_named(f,12)); }\nfunction run_named13(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,tail_named(f,13)); }\nfunction run_named14(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,tail_named(f,14)); }\nfunction run_named15(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,tail_named(f,15)); }\nfunction run_named16(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,tail_named(f,16)); }\nfunction run_named17(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,tail_named(f,17)); }\nfunction run_named18(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,tail_named(f,18)); }\nfunction run_named19(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,tail_named(f,19)); }\nfunction run_named20(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,tail_named(f,20)); }\nfunction run_named21(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,tail_named(f,21)); }\nfunction run_named22(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,tail_named(f,22)); }\nfunction run_named23(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,tail_named(f,23)); }\nfunction run_named24(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,tail_named(f,24)); }\nfunction run_named25(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,tail_named(f,25)); }\nfunction run_named26(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,tail_named(f,26)); }\nfunction run_named27(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,tail_named(f,27)); }\nfunction run_named28(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,tail_named(f,28)); }\nfunction run_named29(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,tail_named(f,29)); }\nfunction run_named30(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,$tailArgs[29]=a29,tail_named(f,30)); }\nfunction run_named31(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,$tailArgs[29]=a29,$tailArgs[30]=a30,tail_named(f,31)); }\nfunction run_named32(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,$tailArgs[29]=a29,$tailArgs[30]=a30,$tailArgs[31]=a31,tail_named(f,32)); }\n"
def js_runtime_extra() -> String:
  "function f32_from_bits(x) { return new Float32Array(new Uint32Array([x]).buffer)[0]; }\nfunction f32_bits(x) { return new Uint32Array(new Float32Array([x]).buffer)[0]; }\nfunction tuple(a,b) { return {$:\"Tuple\",fst:a,snd:b}; }\nfunction f32_show(x) { if(x!==x) return \"nan\"; if(!Number.isFinite(x)||Object.is(x,-0)) return x<0?\"-inf\":x===0?\"-0\":\"inf\"; let s=\"x\"; for(let p=1;p<=9&&Math.fround(Number(s))!==x;p++) s=String(Number(x.toExponential(p-1))); return s; }\nfunction f32_read(s) { const re=/^\\s*[+-]?((\\d+\\.?\\d*|\\.\\d+)(e[+-]?\\d+)?|inf(inity)?|nan)$/i; const v=Number(s.replace(/inf\\w*/i,\"Infinity\")); return re.test(s)?{$:\"Some\",value:Math.fround(v)}:{$:\"None\"}; }\nfunction nat_divmod(a,b) { return b===0?tuple(0,a):tuple(Math.trunc(a/b),a%b); }\nfunction nat_in(n) { return Number.isInteger(n)&&n>=0&&n<=9007199254740992?n:nat_chk(1/0); }\nfunction array_new(n,v) { if(n>31) throw \"bend: an array past the deepest block class 31\"; return Array(2 ** n).fill(v); }\nfunction array_node(a,b) { if(a.length!==b.length) throw \"bend: runtime fail-stop\"; return a.concat(b); }\n"
def js_runtime_array() -> String:
  "function array_swap(a,i,v) { const at=i%a.length, old=a[at]; a[at]=v; return tuple(a,old); }\nfunction $string_tail(s) { return s.slice(s.codePointAt(0)>0xFFFF?2:1); }\n"
def js_runtime_foreign() -> String:
  "const $0eff=Object.create(null);\nfunction io_emit(value) { return {$:\"Emit\",value}; }\nfunction io_eff(k,run) { if(arguments.length>2)throw new Error(\"bend: \"+k+\" takes no need: an effect that waits parks itself\"); if(k in $0eff)throw new Error(\"bend: two effects register \"+k); $0eff[k]=run; }\n"
def js_runtime_namespace() -> String:
  "function $key(k,s,a) { let p=null; for (const alias of Object.keys(a)) if(k.startsWith(alias+\".\") && (p===null || alias.length>p.length)) p=alias; const n=p===null?undefined:a[p]; return n===undefined?(s?s+\".\"+k:k):(n?n+\".\":\"\")+k.slice(p.length+1); }\nfunction $resolve(k,s,a) { const q=$key(k,s,a); return $D[Object.hasOwn($D,q)?q:k]; }\nconst $FIELDS=Object.create(null), $PRIMITIVES=Object.create(null), $TYPE=Object.create(null), $TYPEF=Object.create(null), $PARAMS=Object.create(null);\nfunction $ctr(k,x,s,a) { const q=$key(k,s,a), key=Object.hasOwn($FIELDS,q)?q:k, fs=$FIELDS[key]; if(!fs||fs.length!==x.length)throw \"bend: unresolved constructor layout\"; const v={$:key}; for(let i=0;i<fs.length;i++){const f=fs[i];if(f!==null){if(f===\"__proto__\")Object.defineProperty(v,f,{value:x[i],enumerable:true,writable:true,configurable:true});else v[f]=x[i];}} return v; }\nfunction $project(v,k,i,s,a) { const q=$key(k,s,a),fs=$FIELDS[q]||$FIELDS[k]; if(!fs)throw \"bend: unresolved constructor layout\"; for(const f of fs)if(f!==null&&i--===0)return v[f]; throw \"bend: constructor field count mismatch\"; }\n"
def js_runtime_cli() -> String:
  "const cli_args=[];\nfunction cli(argv) { for(let i=0;i<argv.length;i++){ if(argv[i]===\"--\"){cli_args.push(...argv.slice(i+1));break;} if(argv[i]===\"--help\"){process.stdout.write(\"usage: \"+process.argv[1]+\"\\n\");process.exit(0);} if(argv[i]===\"--threads\"||argv[i]===\"--gpu\"){i++;} else cli_args.push(argv[i]); } }\n"
def js_runtime_io() -> String:
  "function io_out(fd,data) { const fs=require(\"fs\"), b=Buffer.from(data); let at=0; while(at<b.length){ try{ at+=fs.writeSync(fd,b,at,b.length-at); } catch(e){ if(e.code===\"EAGAIN\"||e.code===\"EINTR\")continue; if(e.code===\"EPIPE\"){process.on(\"SIGPIPE\",()=>{}).removeAllListeners(\"SIGPIPE\").kill(process.pid,\"SIGPIPE\");} try{fs.writeSync(2,\"bend: a short write on a standard stream\\n\");}catch(o){} process.exit(1);} } }\nfunction io_errs(message) { io_out(2,io_bytes(message+\"\\n\")); }\nfunction io_bytes(text) { return new TextEncoder().encode(text); }\nfunction io_text(b,n) { return new TextDecoder(\"utf-8\",{ignoreBOM:true}).decode(b.subarray(0,n)); }\nfunction io_list(b,n) { let xs={$:\"Nil\"}; while(n>0){ xs={$:\"Con\",head:b[--n],tail:xs}; } return xs; }\nfunction io_unlist(xs) { const b=[]; for(;xs.$===\"Con\";xs=xs.tail){ b.push(xs.head); } return b.some(x=>x>255)?null:Uint8Array.from(b); }\nfunction io_addr(host,port) { const part=host.split(\".\"); const deci=p=>/^(0|[1-9]\\d{0,2})$/.test(p)&&Number(p)<256; if(port>65535||part.length!==4||!part.every(deci))return null; const b=new Uint8Array(16); const head=io_sys().mac?[16,2]:[2,0]; b.set([...head,port>>8,port&255,...part.map(Number)]); return b; }\nfunction io_tup(...xs) { return xs.reduceRight((snd,fst)=>({$:\"Tuple\",fst,snd})); }\nfunction io_done(value) { return {$:\"Done\",value}; }\nfunction io_strerror(code) { try{ return String(io_sys().strerror(code)); } catch(o){ return \"errno \"+code; } }\nfunction io_fail(code,...rest) { const err=io_tup(code>>>0,io_strerror(code)); return {$:\"Fail\",error:io_tup(err,...rest)}; }\nfunction io_until(ms) { return performance.now()+Number(ms); }\nfunction io_late(at) { return at!==undefined&&performance.now()>=at; }\nfunction io_ready(at,r) { return at===undefined?r:{$:\"Ready\",value:r}; }\nfunction io_sys() { if(globalThis.BEND_SYS===undefined){ const ffi=require(\"bun:ffi\"), mac=process.platform===\"darwin\", err=mac?\"__error\":\"__errno_location\", sel=mac?\"select$DARWIN_EXTSN\":\"select\", T={i:\"i32\",u:\"u32\",U:\"u64\",I:\"i64\",p:\"ptr\",c:\"cstring\"}, vari=mac&&process.arch===\"arm64\", lib=ffi.dlopen(mac?\"libSystem.dylib\":\"libc.so.6\",Object.fromEntries((\"socket:iii>i bind:ipu>i listen:ii>i connect:ipu>i accept:ipp>i send:ipUi>I recv:ipUi>I read:ipU>I pread:ipUI>I sendto:ipUipu>I recvfrom:ipUipp>I close:i>i setsockopt:iiipu>i \"+sel+\":ipppp>i\"+(vari?\" fcntl:iiiiiiiii>i\":\" fcntl:iii>i\")+\" getsockopt:iiipp>i strerror:i>c \"+err+\":>p\").split(\" \").map(s=>{const [name,args,ret]=s.split(/[:>]/);return [name,{args:[...args].map(a=>T[a]),returns:T[ret]}]}))).symbols; const fcntl=(fd,cmd,arg)=>vari?lib.fcntl(fd,cmd,0,0,0,0,0,0,arg):lib.fcntl(fd,cmd,arg); globalThis.BEND_SYS={...lib,fcntl,select:lib[sel],ptr:ffi.ptr,mac,errno:()=>ffi.read.i32(lib[err](),0)}; } return globalThis.BEND_SYS; }\nfunction io_push(fun,arg,fresh) { const io=globalThis.BEND_IO; io.runs.push({fun,arg}); io.live+=fresh?1:0; }\nfunction io_park_on(fd,out,k,more,at) { const ws=globalThis.BEND_IO.waits; const i=ws.findLastIndex(w=>(w.at??Infinity)<=(at??Infinity)); ws.splice(i+1,0,{fd,out,k,more,at}); }\nfunction io_wait(io,block) { const soon=io.waits[0]?.at??Infinity; const ms=!block?0:soon===Infinity?-1:Math.max(0,Math.ceil(soon-performance.now())); const fds=io.waits.filter(w=>w.fd!==undefined); const top=fds.reduce((m,w)=>Math.max(m,w.fd),0); const len=(top>>6<<3)+8; const set=new Uint8Array(2*len); const at=w=>(w.out?len:0)+(w.fd>>3); for(const w of fds)set[at(w)]|=1<<(w.fd&7); const tv=new BigInt64Array([BigInt(ms/1000|0),BigInt(ms%1000*1000)]); const sys=io_sys(); if(sys.select(top+1,sys.ptr(set),sys.ptr(set,len),null,ms<0?null:sys.ptr(tv))<0){ if(sys.errno()!==4){ throw \"bend: the poller failed\"; } set.fill(0); } const now=performance.now(); const due=w=>w.at<=now||w.fd!==undefined&&set[at(w)]&1<<(w.fd&7); const todo=io.waits; io.waits=todo.filter(w=>!due(w)); for(const w of todo.filter(due)){ const x=w.more(); if(x!==undefined)io_push(w.k,x,false); } }\nfunction io_run(m) { const io={runs:[],live:0,waits:[]}; globalThis.BEND_IO=io; try{ io_push(run_loop(m()),x=>({$:\"Emit\",value:x}),true); let look=0; for(let n=0;;n+=1){ if(io.runs.length===0){ if(io.live===0)return 0; if(io.waits.length===0){ io_errs(\"bend: deadlock: every computation waits on a channel\"); return 1; } io_wait(io,true); continue; } if((n&63)===0&&io.waits.length>0){ const now=performance.now(); if(now>=look||io.waits[0].at<=now){ look=now+10; io_wait(io,false); } } const s=io.runs.shift(); let op=s.fun(s.arg); while(op!==undefined){ if(op.$===\"Emit\"){ io.live-=1; break; } if(op.$===\"Halt\"||op.$===\"Exit\"){ if(op.$===\"Halt\")io_errs(op.message); if(op.code>255){ io_errs(\"bend: exit code must be in 0..255\"); return 1; } return op.code; } const run=$0eff[op.$]; if(run===undefined){ throw \"bend: no effect registers \"+op.$; } const x=run(...op.args,op.kont); if(x===undefined)break; op=op.kont(x); } } }catch(e){ throw e instanceof RangeError?\"bend: memory fault (machine stack overflow?)\":e; } }\nfunction io_exit(main,type) { try{ if(type&&type.name===\"IO\")return io_run(main); io_out(1,io_bytes($show_value(type,run_loop(main()),0)+\"\\n\")); return 0; }catch(e){ io_errs(String(e)); return 1; } }\n"
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
