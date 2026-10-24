import Base

# Hand-written C names ids as CID(<key>) and FID(<key>): the id tables belong
# to the program being linked, so an effect source is written once and its id
# spellings are decided per build. This pass owns only that substitution.
#
# It is lexical, not textual. Comments and literals are copied through, so a
# comment that merely quotes "CID(x) names no constructor or def" links fine
# and an identifier such as MY_CID(x) is never a call. An invocation is a whole
# CID(<key>) or FID(<key>) whose key is one or more of [A-Za-z0-9_.~/-].
#
# Resolution is exact. The caller states, per input, which spelling maps to
# which id; nothing here falls back to a last segment, an alias or another
# namespace, because the caller already knows the input's namespace. A miss is
# a link failure that names the spelling, never an invented id.
#
# The traversal is one pass over the characters. Each step consumes the literal
# it is inside of, and a lookahead decides once whether a quote or block comment
# is terminated: an unterminated one is not a literal, so its text stays code,
# exactly as the accepted compiler reads the same source.
type LinkResult is Data:
  LinkSuccess{source: String}
  LinkFailure{message: String}

# Only CodeMode can start an invocation.
type Mode is Data:
  CodeMode{}
  LineComment{}
  BlockComment{}
  DoubleQuote{}
  SingleQuote{}
  Backtick{}

# The output is accumulated reversed and flipped once at the end.
type Scan is Data:
  ScanComplete{output: List<&2, Char>}
  ScanRefused{message: String}

# A prospective key is inspected without consuming it, so a shape that turns
# out not to be an invocation copies its own prefix through unchanged.
type KeyScan is Data:
  KeyFound{key: String, rest: List<&2, Char>}
  KeyAbsent{}

def rewrite(source: String, cids: Map<&2, String>, fids: Map<&2, String>) -> LinkResult:
  link_result(scan(String.to_list(source), CodeMode{}, False{}, Nil{}, cids, fids))

def link_result(result: Scan) -> LinkResult:
  match result:
    case ScanComplete{output}: LinkSuccess{String.from_list(List.reverse(&2, Char, output))}
    case ScanRefused{message}: LinkFailure{message}

def is_word(+char: Char) -> Bool:
  match char:
    case '_': True{}
    case _: Bool.or(Char.is_alpha(char), Char.is_digit(char))

def is_key_char(+char: Char) -> Bool:
  match char:
    case '.': True{}
    case '/': True{}
    case '~': True{}
    case '-': True{}
    case _: is_word(char)

# Lookahead: does this quote close before a newline, and does this comment
# close at all? A literal that does not close is not a literal.
def text_closes(chars: List<&2, Char>, +terminator: Char, +newline_ends: Bool) -> Bool:
  match chars:
    case Nil{}: False{}
    case '\\' <> rest: text_closes_escape(rest, terminator, newline_ends)
    case +char <> rest: text_closes_step(Char.is_eq(char, terminator), char, rest, terminator, newline_ends)

def text_closes_escape(rest: List<&2, Char>, terminator: Char, newline_ends: Bool) -> Bool:
  match rest:
    case Nil{}: False{}
    case _ <> more: text_closes(more, terminator, newline_ends)

def text_closes_step(same: Bool, char: Char, rest: List<&2, Char>, terminator: Char, +newline_ends: Bool) -> Bool:
  match same:
    case True{}: True{}
    case False{}: text_closes_newline(Bool.and(newline_ends, Char.is_eq(char, '\n')), rest, terminator, newline_ends)

def text_closes_newline(ends: Bool, rest: List<&2, Char>, terminator: Char, newline_ends: Bool) -> Bool:
  match ends:
    case True{}: False{}
    case False{}: text_closes(rest, terminator, newline_ends)

def block_closes(chars: List<&2, Char>) -> Bool:
  match chars:
    case Nil{}: False{}
    case '*' <> rest: block_closes_star(rest)
    case _ <> rest: block_closes(rest)

def block_closes_star(+rest: List<&2, Char>) -> Bool:
  match rest:
    case '/' <> _: True{}
    case _: block_closes(rest)

# Read-only: Map.has and Map.get rebuild nothing, so the caller's map keeps
# serving the rest of the pass.
def lookup(map: Map<&2, String>, +key: String) -> Maybe<&2, String>:
  lookup_pair(Map.has(&2, String, map, key), key)

def lookup_pair(has: Map<&2, String> & Bool, key: String) -> Maybe<&2, String>:
  match has:
    case (rest, found): lookup_present(found, rest, key)

def lookup_present(found: Bool, map: Map<&2, String>, key: String) -> Maybe<&2, String>:
  match found:
    case True{}: lookup_value(Map.get(String, "", map, key))
    case False{}: None{}

def lookup_value(result: Map<&2, String> & String) -> Maybe<&2, String>:
  match result:
    case (_, value): Some{value}

def emit_chars(chars: List<&2, Char>, +output: List<&2, Char>) -> List<&2, Char>:
  match chars:
    case Nil{}: output
    case char <> rest: emit_chars(rest, char <> output)

def scan(chars: List<&2, Char>, mode: Mode, word: Bool, +output: List<&2, Char>, cids: Map<&2, String>, fids: Map<&2, String>) -> Scan:
  match chars:
    case Nil{}: ScanComplete{output}
    case char <> rest: scan_mode(mode, char, rest, word, output, cids, fids)

def scan_mode(mode: Mode, +char: Char, +rest: List<&2, Char>, word: Bool, +output: List<&2, Char>, +cids: Map<&2, String>, +fids: Map<&2, String>) -> Scan:
  match mode:
    case CodeMode{}: scan_code(char, rest, word, output, cids, fids)
    case LineComment{}: scan_line(char, rest, output, cids, fids)
    case BlockComment{}: scan_block(char, rest, output, cids, fids)
    case DoubleQuote{}: scan_text(char, rest, DoubleQuote{}, '\"', output, cids, fids)
    case SingleQuote{}: scan_text(char, rest, SingleQuote{}, '\'', output, cids, fids)
    case Backtick{}: scan_text(char, rest, Backtick{}, '`', output, cids, fids)

# Code
# ----

def scan_code(+char: Char, +rest: List<&2, Char>, +word: Bool, +output: List<&2, Char>, +cids: Map<&2, String>, +fids: Map<&2, String>) -> Scan:
  match char:
    case '/': scan_slash(rest, output, cids, fids)
    case '\"': scan(rest, Bool.pick(Mode, text_closes(rest, '\"', True{}), DoubleQuote{}, CodeMode{}), False{}, char <> output, cids, fids)
    case '\'': scan(rest, Bool.pick(Mode, text_closes(rest, '\'', True{}), SingleQuote{}, CodeMode{}), False{}, char <> output, cids, fids)
    case '`': scan(rest, Bool.pick(Mode, text_closes(rest, '`', False{}), Backtick{}, CodeMode{}), False{}, char <> output, cids, fids)
    case 'C': scan_named(word, 'C', rest, output, cids, fids)
    case 'F': scan_named(word, 'F', rest, output, cids, fids)
    case _: scan(rest, CodeMode{}, is_word(char), char <> output, cids, fids)

def scan_slash(+rest: List<&2, Char>, +output: List<&2, Char>, +cids: Map<&2, String>, +fids: Map<&2, String>) -> Scan:
  match rest:
    case '/' <> more: scan(more, LineComment{}, False{}, '/' <> ('/' <> output), cids, fids)
    case '*' <> +more: scan(more, Bool.pick(Mode, block_closes(more), BlockComment{}, CodeMode{}), False{}, '*' <> ('/' <> output), cids, fids)
    case _: scan(rest, CodeMode{}, False{}, '/' <> output, cids, fids)

# A failed shape copies its prefix and resumes after it: I, D and ( can never
# begin an invocation themselves, so nothing is skipped.
def scan_named(word: Bool, +head: Char, +rest: List<&2, Char>, +output: List<&2, Char>, +cids: Map<&2, String>, +fids: Map<&2, String>) -> Scan:
  match word:
    case True{}: scan(rest, CodeMode{}, True{}, head <> output, cids, fids)
    case False{}: scan_named_prefix(head, rest, output, cids, fids)

def scan_named_prefix(+head: Char, +rest: List<&2, Char>, +output: List<&2, Char>, +cids: Map<&2, String>, +fids: Map<&2, String>) -> Scan:
  match rest:
    case 'I' <> 'D' <> '(' <> +more: scan_named_key(head, collect_key(more, Nil{}), more, output, cids, fids)
    case _: scan(rest, CodeMode{}, True{}, head <> output, cids, fids)

def scan_named_key(+head: Char, pending: KeyScan, more: List<&2, Char>, +output: List<&2, Char>, +cids: Map<&2, String>, +fids: Map<&2, String>) -> Scan:
  match pending:
    case KeyFound{key, rest}: apply_named(head, key, rest, output, cids, fids)
    case KeyAbsent{}: scan(more, CodeMode{}, False{}, '(' <> ('D' <> ('I' <> (head <> output))), cids, fids)

def apply_named(+head: Char, +key: String, rest: List<&2, Char>, output: List<&2, Char>, +cids: Map<&2, String>, +fids: Map<&2, String>) -> Scan:
  apply_id(head, key, lookup_id(head, cids, fids, key), rest, output, cids, fids)

def lookup_id(head: Char, cids: Map<&2, String>, fids: Map<&2, String>, key: String) -> Maybe<&2, String>:
  lookup_named(Char.is_eq(head, 'C'), cids, fids, key)

def lookup_named(cid: Bool, cids: Map<&2, String>, fids: Map<&2, String>, +key: String) -> Maybe<&2, String>:
  match cid:
    case True{}: lookup(cids, key)
    case False{}: lookup(fids, key)

def apply_id(head: Char, key: String, found: Maybe<&2, String>, rest: List<&2, Char>, output: List<&2, Char>, cids: Map<&2, String>, fids: Map<&2, String>) -> Scan:
  match found:
    case Some{value}: scan(rest, CodeMode{}, False{}, emit_chars(String.to_list(value), output), cids, fids)
    case None{}: ScanRefused{missing_id(head, key)}

def missing_id(head: Char, key: String) -> String:
  String.append(prefix_text(head), String.append(key, ") names no constructor or def"))

def prefix_text(head: Char) -> String:
  prefix_named(Char.is_eq(head, 'C'))

def prefix_named(cid: Bool) -> String:
  match cid:
    case True{}: "CID("
    case False{}: "FID("

# Comments
# --------

def scan_line(+char: Char, +rest: List<&2, Char>, +output: List<&2, Char>, +cids: Map<&2, String>, +fids: Map<&2, String>) -> Scan:
  match char:
    case '\n': scan(rest, CodeMode{}, False{}, char <> output, cids, fids)
    case '\\': scan_line_more(rest, output, cids, fids)
    case _: scan(rest, LineComment{}, False{}, char <> output, cids, fids)

def scan_line_more(+rest: List<&2, Char>, +output: List<&2, Char>, +cids: Map<&2, String>, +fids: Map<&2, String>) -> Scan:
  match rest:
    case '\n' <> more: scan(more, LineComment{}, False{}, '\n' <> ('\\' <> output), cids, fids)
    case _: scan(rest, LineComment{}, False{}, '\\' <> output, cids, fids)

def scan_block(+char: Char, +rest: List<&2, Char>, +output: List<&2, Char>, +cids: Map<&2, String>, +fids: Map<&2, String>) -> Scan:
  match char:
    case '*': scan_block_more(rest, output, cids, fids)
    case _: scan(rest, BlockComment{}, False{}, char <> output, cids, fids)

def scan_block_more(+rest: List<&2, Char>, +output: List<&2, Char>, +cids: Map<&2, String>, +fids: Map<&2, String>) -> Scan:
  match rest:
    case '/' <> more: scan(more, CodeMode{}, False{}, '/' <> ('*' <> output), cids, fids)
    case _: scan(rest, BlockComment{}, False{}, '*' <> output, cids, fids)

# Literals
# --------

# A backslash owns the character after it. The lookahead promised a terminator,
# so the escape walk cannot reach the end of the input here.
def scan_text(+char: Char, +rest: List<&2, Char>, +mode: Mode, terminator: Char, +output: List<&2, Char>, +cids: Map<&2, String>, +fids: Map<&2, String>) -> Scan:
  match char:
    case '\\': scan_text_more(rest, mode, output, cids, fids)
    case _: scan_text_plain(Char.is_eq(char, terminator), char, rest, mode, output, cids, fids)

def scan_text_plain(same: Bool, +char: Char, +rest: List<&2, Char>, mode: Mode, +output: List<&2, Char>, +cids: Map<&2, String>, +fids: Map<&2, String>) -> Scan:
  match same:
    case True{}: scan(rest, CodeMode{}, False{}, char <> output, cids, fids)
    case False{}: scan(rest, mode, False{}, char <> output, cids, fids)

def scan_text_more(rest: List<&2, Char>, mode: Mode, +output: List<&2, Char>, cids: Map<&2, String>, fids: Map<&2, String>) -> Scan:
  match rest:
    case Nil{}: ScanComplete{'\\' <> output}
    case char <> more: scan(more, mode, False{}, char <> ('\\' <> output), cids, fids)

# Keys
# ----

def collect_key(chars: List<&2, Char>, +collected: List<&2, Char>) -> KeyScan:
  match chars:
    case Nil{}: KeyAbsent{}
    case ')' <> rest: collect_key_close(collected, rest)
    case +char <> rest: collect_key_more(is_key_char(char), char, rest, collected)

def collect_key_close(+collected: List<&2, Char>, rest: List<&2, Char>) -> KeyScan:
  match collected:
    case Nil{}: KeyAbsent{}
    case _: KeyFound{String.from_list(List.reverse(&2, Char, collected)), rest}

def collect_key_more(valid: Bool, char: Char, rest: List<&2, Char>, collected: List<&2, Char>) -> KeyScan:
  match valid:
    case True{}: collect_key(rest, char <> collected)
    case False{}: KeyAbsent{}
