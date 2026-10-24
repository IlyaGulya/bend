import Base
import ./index_lookup.bend as IndexLookup

# Hand-written C names ids as CID(<key>) and FID(<key>): the id tables belong
# to the program being linked, so an effect source is written once and its id
# spellings are decided per build. This pass owns only that substitution.
#
# It is lexical, not textual. Comments and literals are copied through, so a
# comment that merely quotes "CID(x) names no constructor or def" links fine
# and an identifier such as MY_CID(x) is never a call. An invocation is a whole
# CID(<key>) or FID(<key>) whose key is one or more of [A-Za-z0-9_.~/-].
#
# Resolution is exact: IndexLookup.find with the caller's map and the key as
# written, so a miss never falls back to a last segment, an alias or another
# namespace. A miss is recorded and reported as a link failure naming the
# spelling, never as an invented id; the scan keeps its result order.
#
# One pass over the characters. A quote or block comment is entered only if it
# closes, as the accepted compiler reads the same source, and a backslash
# splices the next line for both LF and CRLF.
type LinkResult is Data:
  LinkSuccess{source: String}
  LinkFailure{message: String}

# ---------------------------------------------------------------------------
# Linear text construction
#
# Base's String.append recurses over its first argument, String.concat recurses
# over its first element, and String.from_list/String.to_list recurse once per
# character; every one of those is non-tail, so assembling a large translation
# unit through them grows the stack with the text. The helpers here are all tail
# calls: text_of_pieces reverses only the piece list, seeds the accumulator with
# the last piece and prepends the rest through text_prepend, so no step walks an
# already built string and the transient character list is bounded by the
# largest piece. Per-character cost is one cons per pass, not a constant-time
# guarantee independent of the allocator:
#   chars_rev(s, acc)     = reverse(s) ++ acc        (walk s forward, cons)
#   text_of_rev(chars, a) = a with chars prepended in reverse (walk forward, cons
#                           onto the String as SCon)
#   pieces_rev(parts, a)  = reverse(parts) concatenated onto a char list
#   text_of_pieces(parts) = parts concatenated in order
# Concatenating k parts therefore costs one walk over each part's characters and
# no choice of chunk size; if peak temporary space ever matters, folding pieces
# in reverse keeps the temporary list at the largest piece instead of the whole
# text, at the cost of rebuilding each piece separately.
def chars_rev(source: String, +acc: List<&2, Char>) -> List<&2, Char>:
  match source:
    case SNil{}: acc
    case SCon{head, tail}: chars_rev(tail, head <> acc)

def text_of_rev(chars: List<&2, Char>, +acc: String) -> String:
  match chars:
    case Nil{}: acc
    case +char <> rest: text_of_rev(rest, SCon{char, acc})

# text_prepend links a source in front of an already built string without
# walking or copying that string: chars_rev holds only the source's characters,
# and each one is consed onto acc.
def text_prepend(source: String, +acc: String) -> String:
  text_of_rev(chars_rev(source, Nil{}), acc)

# Pieces are folded from the end: the last piece becomes the accumulator, and
# every earlier piece is prepended. No step walks the accumulator, so k pieces
# cost one pass over their own characters and the temporary character list never
# exceeds the largest piece.
def pieces_fold(parts: List<&2, String>, +acc: String) -> String:
  match parts:
    case Nil{}: acc
    case +part <> rest: pieces_fold(rest, text_prepend(part, acc))

def pieces_from_end(reversed: List<&2, String>) -> String:
  match reversed:
    case Nil{}: ""
    case +last <> rest: pieces_fold(rest, last)

def text_of_pieces(parts: List<&2, String>) -> String:
  pieces_from_end(List.reverse(&2, String, parts))

def text_of_string(source: String) -> String:
  text_of_rev(chars_rev(source, Nil{}), "")

# The scanner reads characters in text order; chars_rev hands back the reverse,
# so the forward list is one tail-recursive List.reverse away.
def chars_forward(source: String) -> List<&2, Char>:
  List.reverse(&2, Char, chars_rev(source, Nil{}))

# ---------------------------------------------------------------------------
# C string literals
#
# A C literal's bytes are what the runtime reads, and the runtime reads exactly
# the count the renderer passes, so both come from one UTF-8 encoding of the
# text. Bytes are written as three-digit octal escapes: unlike \x they cannot
# absorb a following hex digit, and they are unambiguous for NUL. Printable
# ASCII stays readable; quote, backslash and the three C whitespace escapes use
# their short forms. Definitions are ordered because the checker requires a
# definition before its use and does not accept a computed match scrutinee.
def utf8_bytes_deep_of(bmp: Bool, +code: U32) -> List<&2, U32>:
  match bmp:
    case True{}: [U32.or(224, U32.shrn(code, 12n)), U32.or(128, U32.and(U32.shrn(code, 6n), 63)), U32.or(128, U32.and(code, 63))]
    case False{}: [U32.or(240, U32.shrn(code, 18n)), U32.or(128, U32.and(U32.shrn(code, 12n), 63)), U32.or(128, U32.and(U32.shrn(code, 6n), 63)), U32.or(128, U32.and(code, 63))]

def utf8_bytes_deep(+code: U32) -> List<&2, U32>:
  utf8_bytes_deep_of(U32.is_lt(code, 65536), code)

def utf8_bytes_wide_of(two: Bool, +code: U32) -> List<&2, U32>:
  match two:
    case True{}: [U32.or(192, U32.shrn(code, 6n)), U32.or(128, U32.and(code, 63))]
    case False{}: utf8_bytes_deep(code)

def utf8_bytes_wide(+code: U32) -> List<&2, U32>:
  utf8_bytes_wide_of(U32.is_lt(code, 2048), code)

def utf8_bytes_of(small: Bool, +code: U32) -> List<&2, U32>:
  match small:
    case True{}: [code]
    case False{}: utf8_bytes_wide(code)

def utf8_bytes(+code: U32) -> List<&2, U32>:
  utf8_bytes_of(U32.is_lt(code, 128), code)

def oct3(+byte: U32) -> String:
  text_of_pieces(["\\", U32.show(U32.and(U32.shrn(byte, 6n), 7)), U32.show(U32.and(U32.shrn(byte, 3n), 7)), U32.show(U32.and(byte, 7))])

def octals(bytes: List<&2, U32>, +acc: String) -> String:
  match bytes:
    case Nil{}: acc
    case +byte <> rest: octals(rest, String.append(acc, oct3(byte)))

# Byte width of one code point, computed from the code alone: no byte list and
# no character list, so a long text costs one SCon walk with head recursion.
def utf8_width_wide(bmp: Bool) -> Nat:
  match bmp:
    case True{}: 3n
    case False{}: 4n

def utf8_width_two(two: Bool, bmp: Bool) -> Nat:
  match two:
    case True{}: 2n
    case False{}: utf8_width_wide(bmp)

def utf8_width_of(small: Bool, two: Bool, bmp: Bool) -> Nat:
  match small:
    case True{}: 1n
    case False{}: utf8_width_two(two, bmp)

def utf8_width(+code: U32) -> Nat:
  utf8_width_of(U32.is_lt(code, 128), U32.is_lt(code, 2048), U32.is_lt(code, 65536))

def utf8_len_go(text: String, +acc: Nat) -> Nat:
  match text:
    case SNil{}: acc
    case SCon{head, tail}: utf8_len_go(tail, Nat.add(acc, utf8_width(Char.to_u32(head))))

def utf8_byte_len(+text: String) -> Nat:
  utf8_len_go(text, 0n)

def literal_high(code: U32) -> String:
  octals(utf8_bytes(code), "")

def literal_wide_of(ascii: Bool, +code: U32, +char: Char) -> String:
  match ascii:
    case True{}: String.from_list([char])
    case False{}: literal_high(code)

def literal_wide(+code: U32, +char: Char) -> String:
  literal_wide_of(U32.is_lt(code, 127), code, char)

def literal_plain_of(printable: Bool, +char: Char) -> String:
  match printable:
    case True{}: literal_wide(Char.to_u32(char), char)
    case False{}: literal_high(Char.to_u32(char))

def literal_plain(+char: Char) -> String:
  literal_plain_of(U32.is_ge(Char.to_u32(char), 32), char)

def literal_piece(char: Char) -> String:
  match char:
    case '"': "\\\""
    case '\\': "\\\\"
    case '\n': "\\n"
    case '\r': "\\r"
    case '\t': "\\t"
    case _: literal_plain(char)

# Escaped pieces in text order followed by the closing quote: the input is the
# reversed character list, so consing each escaped piece yields text order, and
# the closing quote is seeded first. The literal is then built once, without
# materialising the body and copying it.
def literal_pieces(chars: List<&2, Char>, +acc: List<&2, String>) -> List<&2, String>:
  match chars:
    case Nil{}: acc
    case +char <> rest: literal_pieces(rest, literal_piece(char) <> acc)

def c_string_literal(+text: String) -> String:
  text_of_pieces("\"" <> literal_pieces(chars_rev(text, Nil{}), ["\""]))

# Only CodeMode can start an invocation; Key collects a candidate's key.
type Mode is Data:
  CodeMode{}
  LineComment{}
  BlockComment{}
  DoubleQuote{}
  SingleQuote{}
  Backtick{}
  KeyMode{head: Char, collected: List<&2, Char>}

# The output is accumulated reversed and flipped once at the end. The first
# missing key is recorded here rather than branched on mid-scan.
type Scan is Data:
  ScanComplete{output: List<&2, Char>, failure: Maybe<&2, String>}

def link_complete(failure: Maybe<&2, String>, output: List<&2, Char>) -> LinkResult:
  match failure:
    case Some{message}: LinkFailure{message}
    case None{}: LinkSuccess{text_of_rev(output, "")}

def link_result(result: Scan) -> LinkResult:
  match result:
    case ScanComplete{output, failure}: link_complete(failure, output)

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

# A backslash owns the next line too when the next line is spliced: CR LF is
# one newline, so the escape may consume three characters.
# Lookahead: does this quote close before a newline, and does this comment
# close at all? A literal that does not close is not a literal.
def text_closes(chars: List<&2, Char>, +terminator: Char, +newline_ends: Bool) -> Bool:
  match chars:
    case Nil{}: False{}
    case '\\' <> rest:
      match rest:
        case Nil{}: False{}
        case '\r' <> '\n' <> more: text_closes(more, terminator, newline_ends)
        case _ <> more: text_closes(more, terminator, newline_ends)
    case +char <> rest:
      Bool.pick(Bool, Char.is_eq(char, terminator), True{}, Bool.pick(Bool, Bool.and(newline_ends, Char.is_eq(char, '\n')), False{}, text_closes(rest, terminator, newline_ends)))

def block_closes(chars: List<&2, Char>) -> Bool:
  match chars:
    case Nil{}: False{}
    case '*' <> rest:
      match rest:
        case '/' <> _: True{}
        case _: block_closes(rest)
    case _ <> rest: block_closes(rest)

def code_entry_slash(rest: List<&2, Char>) -> Mode:
  match rest:
    case '/' <> _: LineComment{}
    case '*' <> more: Bool.pick(Mode, block_closes(more), BlockComment{}, CodeMode{})
    case _: CodeMode{}

def code_entry(char: Char, +rest: List<&2, Char>) -> Mode:
  match char:
    case '/': code_entry_slash(rest)
    case '\"': Bool.pick(Mode, text_closes(rest, '\"', True{}), DoubleQuote{}, CodeMode{})
    case '\'': Bool.pick(Mode, text_closes(rest, '\'', True{}), SingleQuote{}, CodeMode{})
    case '`': Bool.pick(Mode, text_closes(rest, '`', False{}), Backtick{}, CodeMode{})
    case _: CodeMode{}

def emit_chars(chars: List<&2, Char>, +output: List<&2, Char>) -> List<&2, Char>:
  match chars:
    case Nil{}: output
    case char <> rest: emit_chars(rest, char <> output)

def resolved_text(found: Maybe<&2, String>) -> String:
  match found:
    case Some{value}: value
    case None{}: ""

def first_problem(+old: Maybe<&2, String>, message: String) -> Maybe<&2, String>:
  match old:
    case None{}: Some{message}
    case Some{_}: old

def prefix_named(cid: Bool) -> String:
  match cid:
    case True{}: "CID("
    case False{}: "FID("

def prefix_text(head: Char) -> String:
  prefix_named(Char.is_eq(head, 'C'))

def missing_id(head: Char, key: String) -> String:
  String.append(prefix_text(head), String.append(key, ") names no constructor or def"))

def next_failure(head: Char, key: String, found: Maybe<&2, String>, +old: Maybe<&2, String>) -> Maybe<&2, String>:
  match found:
    case Some{_}: old
    case None{}: first_problem(old, missing_id(head, key))

def lookup_named(cid: Bool, cids: Map<&2, String>, fids: Map<&2, String>, +key: String) -> Maybe<&2, String>:
  match cid:
    case True{}: IndexLookup.find(String, cids, key)
    case False{}: IndexLookup.find(String, fids, key)

def lookup_id(head: Char, cids: Map<&2, String>, fids: Map<&2, String>, +key: String) -> Maybe<&2, String>:
  lookup_named(Char.is_eq(head, 'C'), cids, fids, key)

# A candidate key run that was not an invocation gives back everything it held:
# CID( or FID(, the collected key, and the character that ended the run.
def flush_key(+head: Char, collected: List<&2, Char>, +char: Char, output: List<&2, Char>) -> List<&2, Char>:
  char <> List.append(&2, Char, collected, '(' <> ('D' <> ('I' <> (head <> output))))

def flush_open(head: Char, collected: List<&2, Char>, output: List<&2, Char>) -> List<&2, Char>:
  List.append(&2, Char, collected, '(' <> ('D' <> ('I' <> (head <> output))))

def flush_empty(head: Char, output: List<&2, Char>) -> List<&2, Char>:
  ')' <> ('(' <> ('D' <> ('I' <> (head <> output))))

def key_text(collected: List<&2, Char>) -> String:
  text_of_rev(collected, "")



def scan(chars: List<&2, Char>, +mode: Mode, +word: Bool, +failure: Maybe<&2, String>, +output: List<&2, Char>, +cids: Map<&2, String>, +fids: Map<&2, String>) -> Scan:
  match chars:
    case Nil{}:
      match mode:
        case KeyMode{head, collected}: ScanComplete{flush_open(head, collected, output), failure}
        case _: ScanComplete{output, failure}
    case +char <> +rest:
      match char:
        case '\\':
          match rest:
            case '\n' <> more: scan(more, mode, word, failure, '\n' <> (char <> output), cids, fids)
            case '\r' <> '\n' <> more: scan(more, mode, word, failure, '\n' <> ('\r' <> (char <> output)), cids, fids)
            case escaped <> more:
              match mode:
                case DoubleQuote{}: scan(more, DoubleQuote{}, False{}, failure, escaped <> ('\\' <> output), cids, fids)
                case SingleQuote{}: scan(more, SingleQuote{}, False{}, failure, escaped <> ('\\' <> output), cids, fids)
                case Backtick{}: scan(more, Backtick{}, False{}, failure, escaped <> ('\\' <> output), cids, fids)
                case KeyMode{head, collected}: scan(rest, code_entry(char, rest), False{}, failure, flush_key(head, collected, char, output), cids, fids)
                case _: scan(rest, mode, False{}, failure, char <> output, cids, fids)
            case Nil{}:
              match mode:
                case KeyMode{head, collected}: scan(rest, code_entry(char, rest), False{}, failure, flush_key(head, collected, char, output), cids, fids)
                case _: scan(rest, mode, False{}, failure, char <> output, cids, fids)
        case '/':
          match rest:
            case '/' <> more:
              match mode:
                case CodeMode{}: scan(more, LineComment{}, False{}, failure, '/' <> ('/' <> output), cids, fids)
                case KeyMode{head, collected}: scan(rest, KeyMode{head, '/' <> collected}, False{}, failure, output, cids, fids)
                case _: scan(more, mode, False{}, failure, '/' <> ('/' <> output), cids, fids)
            case '*' <> more:
              match mode:
                case CodeMode{}: scan(more, Bool.pick(Mode, block_closes(more), BlockComment{}, CodeMode{}), False{}, failure, '*' <> ('/' <> output), cids, fids)
                case KeyMode{head, collected}: scan(rest, KeyMode{head, '/' <> collected}, False{}, failure, output, cids, fids)
                case _: scan(more, mode, False{}, failure, '*' <> ('/' <> output), cids, fids)
            case _:
              match mode:
                case KeyMode{head, collected}: scan(rest, KeyMode{head, '/' <> collected}, False{}, failure, output, cids, fids)
                case _: scan(rest, mode, False{}, failure, char <> output, cids, fids)
        case '*':
          match rest:
            case '/' <> more:
              match mode:
                case BlockComment{}: scan(more, CodeMode{}, False{}, failure, '/' <> ('*' <> output), cids, fids)
                case KeyMode{head, collected}: scan(rest, code_entry(char, rest), False{}, failure, flush_key(head, collected, char, output), cids, fids)
                case _: scan(more, mode, False{}, failure, '/' <> ('*' <> output), cids, fids)
            case _:
              match mode:
                case KeyMode{head, collected}: scan(rest, code_entry(char, rest), False{}, failure, flush_key(head, collected, char, output), cids, fids)
                case _: scan(rest, mode, False{}, failure, char <> output, cids, fids)
        case '\"':
          match mode:
            case CodeMode{}: scan(rest, Bool.pick(Mode, text_closes(rest, '\"', True{}), DoubleQuote{}, CodeMode{}), False{}, failure, char <> output, cids, fids)
            case DoubleQuote{}: scan(rest, CodeMode{}, False{}, failure, char <> output, cids, fids)
            case KeyMode{head, collected}: scan(rest, code_entry(char, rest), False{}, failure, flush_key(head, collected, char, output), cids, fids)
            case _: scan(rest, mode, word, failure, char <> output, cids, fids)
        case '\'':
          match mode:
            case CodeMode{}: scan(rest, Bool.pick(Mode, text_closes(rest, '\'', True{}), SingleQuote{}, CodeMode{}), False{}, failure, char <> output, cids, fids)
            case SingleQuote{}: scan(rest, CodeMode{}, False{}, failure, char <> output, cids, fids)
            case KeyMode{head, collected}: scan(rest, code_entry(char, rest), False{}, failure, flush_key(head, collected, char, output), cids, fids)
            case _: scan(rest, mode, word, failure, char <> output, cids, fids)
        case '`':
          match mode:
            case CodeMode{}: scan(rest, Bool.pick(Mode, text_closes(rest, '`', False{}), Backtick{}, CodeMode{}), False{}, failure, char <> output, cids, fids)
            case Backtick{}: scan(rest, CodeMode{}, False{}, failure, char <> output, cids, fids)
            case KeyMode{head, collected}: scan(rest, code_entry(char, rest), False{}, failure, flush_key(head, collected, char, output), cids, fids)
            case _: scan(rest, mode, word, failure, char <> output, cids, fids)
        case 'C':
          match rest:
            case 'I' <> 'D' <> '(' <> +more:
              match mode:
                case CodeMode{}:
                  match word:
                    case True{}: scan(rest, CodeMode{}, True{}, failure, char <> output, cids, fids)
                    case False{}: scan(more, KeyMode{char, Nil{}}, False{}, failure, output, cids, fids)
                case KeyMode{head, collected}: scan(more, KeyMode{head, 'C' <> collected}, False{}, failure, output, cids, fids)
                case _: scan(more, mode, True{}, failure, '(' <> ('D' <> ('I' <> (char <> output))), cids, fids)
            case _:
              match mode:
                case KeyMode{head, collected}: scan(rest, KeyMode{head, 'C' <> collected}, False{}, failure, output, cids, fids)
                case _: scan(rest, mode, True{}, failure, char <> output, cids, fids)
        case 'F':
          match rest:
            case 'I' <> 'D' <> '(' <> +more:
              match mode:
                case CodeMode{}:
                  match word:
                    case True{}: scan(rest, CodeMode{}, True{}, failure, char <> output, cids, fids)
                    case False{}: scan(more, KeyMode{char, Nil{}}, False{}, failure, output, cids, fids)
                case KeyMode{head, collected}: scan(more, KeyMode{head, 'F' <> collected}, False{}, failure, output, cids, fids)
                case _: scan(more, mode, True{}, failure, '(' <> ('D' <> ('I' <> (char <> output))), cids, fids)
            case _:
              match mode:
                case KeyMode{head, collected}: scan(rest, KeyMode{head, 'F' <> collected}, False{}, failure, output, cids, fids)
                case _: scan(rest, mode, True{}, failure, char <> output, cids, fids)
        case ')':
          match mode:
            case KeyMode{head, collected}:
              match collected:
                case Nil{}: scan(rest, CodeMode{}, False{}, failure, flush_empty(head, output), cids, fids)
                case _:
                  +key = key_text(collected)
                  +found = lookup_id(head, cids, fids, key)
                  scan(rest, CodeMode{}, False{}, next_failure(head, key, found, failure), emit_chars(String.to_list(resolved_text(found)), output), cids, fids)
            case _: scan(rest, mode, False{}, failure, char <> output, cids, fids)
        case '\n':
          match mode:
            case LineComment{}: scan(rest, CodeMode{}, False{}, failure, char <> output, cids, fids)
            case KeyMode{head, collected}: scan(rest, code_entry(char, rest), False{}, failure, flush_key(head, collected, char, output), cids, fids)
            case _: scan(rest, mode, False{}, failure, char <> output, cids, fids)
        case _:
          match mode:
            case KeyMode{head, collected}: scan(rest, Bool.pick(Mode, is_key_char(char), KeyMode{head, char <> collected}, code_entry(char, rest)), is_word(char), failure, Bool.pick(List<&2, Char>, is_key_char(char), output, flush_key(head, collected, char, output)), cids, fids)
            case _: scan(rest, mode, is_word(char), failure, char <> output, cids, fids)

def rewrite(source: String, cids: Map<&2, String>, fids: Map<&2, String>) -> LinkResult:
  link_result(scan(chars_forward(source), CodeMode{}, False{}, None{}, Nil{}, cids, fids))

