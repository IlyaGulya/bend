import Base

def absolute(path: String) -> Bool:
  match path:
    case SCon{+head, _}:
      Char.is_eq(head, '/')
    case SNil{}:
      False{}

def finish_relative(stack: List<&2, String>) -> String:
  match stack:
    case Nil{}: "."
    case +_ <> _: String.join(List.reverse(&2, String, stack), "/")

def finish(+stack: List<&2, String>, is_absolute: Bool) -> String:
  parts = List.reverse(&2, String, stack)
  joined = String.join(parts, "/")
  Bool.pick(String, is_absolute, String.append("/", joined), finish_relative(stack))

def normalize_parent_stack(+stack: List<&2, String>, is_absolute: Bool) -> List<&2, String>:
  match stack:
    case Nil{}:
      Bool.pick(List<&2, String>, is_absolute, stack, ".." <> stack)
    case +top <> tail:
      Bool.pick(List<&2, String>, String.eq(top, ".."), Bool.pick(List<&2, String>, is_absolute, stack, ".." <> stack), tail)

def normalize_parts(parts: List<&2, String>, +stack: List<&2, String>, +is_absolute: Bool) -> String:
  match parts:
    case Nil{}:
      finish(stack, is_absolute)
    case +part <> rest:
      skip = Bool.or(String.eq(part, ""), String.eq(part, "."))
      parent = String.eq(part, "..")
      parent_stack = normalize_parent_stack(stack, is_absolute)
      next_stack = Bool.pick(List<&2, String>, skip, stack, Bool.pick(List<&2, String>, parent, parent_stack, part <> stack))
      normalize_parts(rest, next_stack, is_absolute)

def normalize(+path: String) -> String:
  normalize_parts(String.split(path, '/'), Nil{}, absolute(path))

def dirname_parts(parts: List<&2, String>, acc: List<&2, String>) -> String:
  match parts:
    case Nil{}:
      String.join(List.reverse(&2, String, acc), "/")
    case +part <> rest:
      match rest:
        case Nil{}:
          String.join(List.reverse(&2, String, acc), "/")
        case _:
          dirname_parts(rest, part <> acc)

def dirname_result(raw: String, empty: Bool, is_absolute: Bool) -> String:
  match empty:
    case True{}:
      Bool.pick(String, is_absolute, "/", ".")
    case False{}:
      raw

def dirname(+path: String) -> String:
  +raw = dirname_parts(String.split(path, '/'), Nil{})
  dirname_result(raw, String.eq(raw, ""), absolute(path))

def resolve_result(from_file: String, import_path: String, is_absolute: Bool) -> String:
  match is_absolute:
    case True{}:
      normalize(import_path)
    case False{}:
      normalize(String.append(dirname(from_file), String.append("/", import_path)))

def resolve(from_file: String, +import_path: String) -> String:
  resolve_result(from_file, import_path, absolute(import_path))

def without_bend_result(+path: String, has_bend: Bool) -> String:
  match has_bend:
    case True{}: String.take(path, String.length(path) - 5n)
    case False{}: path

def without_bend(+path: String) -> String:
  without_bend_result(path, String.ends_with(path, ".bend"))

def lower_hex(+c: Char) -> Bool:
  +code = Char.to_u32(c)
  Bool.or(Char.is_digit(c), Bool.and(U32.is_ge(code, 97), U32.is_le(code, 102)))

def all_hex_step(chars: List<&2, Char>, valid: Bool) -> Bool:
  match chars valid:
    case _ False{}: False{}
    case Nil{} True{}: True{}
    case +c <> rest True{}: all_hex_step(rest, lower_hex(c))
def all_hex(chars: List<&2, Char>) -> Bool:
  all_hex_step(chars, True{})

def package_suffix(suffix: String, rest: List<&2, String>, nonempty: Bool) -> Bool:
  match rest nonempty:
    case _ False{}: False{}
    case Nil{} True{}: False{}
    case +_ <> _ True{}:
      all_hex(String.to_list(suffix))

def package_hash(hash: String, rest: List<&2, String>, starts: Bool) -> Bool:
  match starts:
    case False{}: False{}
    case True{}:
      +suffix = String.drop(hash, 2n)
      package_suffix(suffix, rest, Bool.not(String.is_empty(suffix)))

def package_parts(parts: List<&2, String>) -> Bool:
  match parts:
    case +hash <> rest:
      package_hash(hash, rest, String.starts_with(hash, "0x"))
    case Nil{}:
      False{}

def package_path(path: String) -> Bool:
  package_parts(String.split(path, '/'))

def namespace_result(parent: String, +import_path: String, is_absolute: Bool, is_package: Bool) -> String:
  match is_absolute is_package:
    case True{} _: normalize(without_bend(import_path))
    case False{} True{}: normalize(without_bend(import_path))
    case False{} False{}:
      normalize(String.append(dirname(parent), String.append("/", without_bend(import_path))))
def namespace_base(parent: String, import_path: String, is_base: Bool, is_absolute: Bool, is_package: Bool) -> String:
  match is_base:
    case True{}:
      ""
    case False{}:
      namespace_result(parent, import_path, is_absolute, is_package)

def namespace(parent: String, +import_path: String) -> String:
  namespace_base(parent, import_path, String.eq(import_path, "Base"), absolute(import_path), package_path(import_path))

