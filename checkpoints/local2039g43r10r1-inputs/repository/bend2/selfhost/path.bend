import Base

def absolute(path: String) -> Bool:
  match path:
    case SCon{+head, _}:
      Char.is_eq(head, '/')
    case SNil{}:
      False{}

# Components are stored backwards while scanning, then copied straight into
# the result. Only completed, nonempty components allocate stack cells.
def prepend_reverse(part: String, acc: String) -> String:
  match part:
    case SNil{}: acc
    case SCon{head, tail}: prepend_reverse(tail, SCon{head, acc})

# Keep emptiness separately rather than destructuring the growing suffix.
def finish_stack(stack: List<&2, String>, +acc: String, has_tail: Bool) -> String:
  match stack:
    case Nil{}: acc
    case part <> rest:
      finish_stack(rest, prepend_reverse(part, Bool.pick(String, has_tail, SCon{'/', acc}, acc)), True{})

def finish_result(is_absolute: Bool, joined: String) -> String:
  match is_absolute:
    case True{}: SCon{'/', joined}
    case False{}:
      match joined:
        case SNil{}: "."
        case SCon{head, tail}: SCon{head, tail}

def finish(stack: List<&2, String>, is_absolute: Bool) -> String:
  finish_result(is_absolute, finish_stack(stack, "", False{}))

def normalize_parent_stack(+stack: List<&2, String>, is_absolute: Bool) -> List<&2, String>:
  match stack:
    case Nil{}:
      Bool.pick(List<&2, String>, is_absolute, stack, ".." <> stack)
    case top <> tail:
      match top:
        case SCon{'.', SCon{'.', SNil{}}}:
          Bool.pick(List<&2, String>, is_absolute, stack, ".." <> stack)
        case _:
          tail

# Classification does not return the matched characters: retaining a whole
# String across a numeric Char pattern would reconstruct its U32 word.
def component_kind(part: String) -> Nat:
  match part:
    case SNil{}: 0n
    case SCon{'.', SNil{}}: 0n
    case SCon{'.', SCon{'.', SNil{}}}: 1n
    case _: 2n

def normalize_part_kind(kind: Nat, part: String, stack: List<&2, String>, is_absolute: Bool) -> List<&2, String>:
  match kind:
    case 0n: stack
    case 1n: normalize_parent_stack(stack, is_absolute)
    case _: part <> stack

def normalize_part(+part: String, stack: List<&2, String>, is_absolute: Bool) -> List<&2, String>:
  normalize_part_kind(component_kind(part), part, stack, is_absolute)

def normalize_cut(cut: Bool, part: String, stack: List<&2, String>, is_absolute: Bool) -> List<&2, String>:
  match cut:
    case False{}: stack
    case True{}: normalize_part(part, stack, is_absolute)

# Finish each input's last component before continuing with another input.
# This lets resolve/namespace compose at a slash without copying their inputs.
def normalize_scan(cursor: String, +part: String, +stack: List<&2, String>, +is_absolute: Bool) -> List<&2, String>:
  match cursor:
    case SNil{}: normalize_part(part, stack, is_absolute)
    case SCon{+head, tail}:
      +cut = Char.is_eq(head, '/')
      normalize_scan(tail, Bool.pick(String, cut, "", SCon{head, part}), normalize_cut(cut, part, stack, is_absolute), is_absolute)

def normalize_result(path: String, +is_absolute: Bool) -> String:
  finish(normalize_scan(path, "", Nil{}, is_absolute), is_absolute)

def normalize(+path: String) -> String:
  normalize_result(path, absolute(path))

# Count Unicode characters up to the last slash, keeping slash runs verbatim.
def dirname_length(cursor: String, +at: Nat, last: Nat) -> Nat:
  match cursor:
    case SNil{}: last
    case SCon{head, tail}:
      match head:
        case '/': dirname_length(tail, 1n+at, at)
        case _: dirname_length(tail, 1n+at, last)

def dirname_prefix(path: String, length: Nat, is_absolute: Bool) -> String:
  match length:
    case 0n: Bool.pick(String, is_absolute, "/", ".")
    case 1n+_: String.take(path, length)

def dirname(+path: String) -> String:
  dirname_prefix(path, dirname_length(path, 0n, 0n), absolute(path))

def normalize_from_result(directory: String, import_path: String, +is_absolute: Bool) -> String:
  finish(normalize_scan(import_path, "", normalize_scan(directory, "", Nil{}, is_absolute), is_absolute), is_absolute)

def normalize_from(+directory: String, import_path: String) -> String:
  normalize_from_result(directory, import_path, absolute(directory))

def resolve_result(from_file: String, import_path: String, is_absolute: Bool) -> String:
  match is_absolute:
    case True{}:
      normalize(import_path)
    case False{}:
      normalize_from(dirname(from_file), import_path)

def resolve(from_file: String, +import_path: String) -> String:
  resolve_result(from_file, import_path, absolute(import_path))

def without_bend_result(+path: String, has_bend: Bool) -> String:
  match has_bend:
    case True{}: String.take(path, (String.length(path) - 5n : Nat))
    case False{}: path

def without_bend(+path: String) -> String:
  without_bend_result(path, String.ends_with(path, ".bend"))

def lower_hex(+c: Char) -> Bool:
  +code = Char.to_u32(c)
  Bool.or(Char.is_digit(c), Bool.and(U32.is_ge(code, 97), U32.is_le(code, 102)))

def package_tail(cursor: String, nonempty: Bool, valid: Bool) -> Bool:
  match cursor valid:
    case _ False{}: False{}
    case SNil{} True{}: False{}
    case SCon{+head, tail} True{}:
      Bool.pick(Bool, Char.is_eq(head, '/'), nonempty, package_tail(tail, True{}, lower_hex(head)))

def package_path(path: String) -> Bool:
  match path:
    case SCon{'0', SCon{'x', tail}}: package_tail(tail, False{}, True{})
    case _: False{}

def namespace_result(parent: String, +import_path: String, is_absolute: Bool, is_package: Bool) -> String:
  match is_absolute is_package:
    case True{} _: normalize(without_bend(import_path))
    case False{} True{}: normalize(without_bend(import_path))
    case False{} False{}:
      normalize_from(dirname(parent), without_bend(import_path))
def namespace_base(parent: String, import_path: String, is_base: Bool, is_absolute: Bool, is_package: Bool) -> String:
  match is_base:
    case True{}:
      ""
    case False{}:
      namespace_result(parent, import_path, is_absolute, is_package)

def namespace(parent: String, +import_path: String) -> String:
  namespace_base(parent, import_path, String.eq(import_path, "Base"), absolute(import_path), package_path(import_path))

