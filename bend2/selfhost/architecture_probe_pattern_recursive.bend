import Base

type Quantity is Data:
  QOne{}
  QMany{}
  QZero{}

type Token is Data:
  Name{key: String}
  Symbol{text: String}

type Pattern is Data:
  Variable{key: String, quantity: Quantity, depth: Nat}
  Constructor{key: String, fields: List<&2, Pattern>}

# This helper only decodes a variable; it never calls the driver.
def variable(+key: String, quantity: Quantity, rest: List<&2, Token>, scope: List<&2, String>, +depth: Nat) -> (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool):
  ((Variable{key, quantity, depth}, rest), ((key <> scope, depth + 1n), True{}))

# Result forwarding is acyclic; the continuation is the caller's next field.
def field_result(result: (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool), parent: String, acc: List<&2, Pattern>, root_scope: List<&2, String>, root_depth: Nat, use_next: List<&2, Token> -> List<&2, String> -> Nat -> List<&2, Pattern> -> (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool)) -> (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool):
  match result:
    case ((pattern, Symbol{","} <> after_comma), ((next_scope, next_depth), True{})):
      use_next(after_comma, next_scope, next_depth, pattern <> acc)
    case ((pattern, Symbol{"}"} <> rest), ((next_scope, next_depth), True{})):
      ((Constructor{parent, List.reverse(&2, Pattern, pattern <> acc)}, rest), ((next_scope, next_depth), True{}))
    case ((pattern, rest), ((next_scope, next_depth), True{})):
      ((Constructor{parent, List.reverse(&2, Pattern, pattern <> acc)}, rest), ((root_scope, root_depth), False{}))
    case ((_, rest), ((_, _), False{})):
      ((Constructor{parent, List.reverse(&2, Pattern, acc)}, rest), ((root_scope, root_depth), False{}))

# None = one pattern; Some = constructor's next field. No generic state machine.
def parse_driver(+tokens: List<&2, Token>, quantity: Quantity, scope: List<&2, String>, depth: Nat, parent: Maybe<&2, String>, acc: List<&2, Pattern>, root_scope: List<&2, String>, root_depth: Nat) -> (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool):
  match tokens parent:
    case Symbol{"+"} <> +rest None{}:
      parse_driver(rest, QMany{}, scope, depth, None{}, Nil{}, scope, depth)
    case Symbol{"-"} <> +rest None{}:
      parse_driver(rest, QZero{}, scope, depth, None{}, Nil{}, scope, depth)
    case Name{key} <> (Symbol{"{"} <> +after_open) None{}:
      parse_driver(after_open, QOne{}, scope, depth, Some{key}, Nil{}, scope, depth)
    case Name{key} <> +rest None{}:
      variable(key, quantity, rest, scope, depth)
    case Symbol{"}"} <> +rest Some{parent_key}:
      ((Constructor{parent_key, List.reverse(&2, Pattern, acc)}, rest), ((scope, depth), True{}))
    case Name{key} <> (Symbol{"{"} <> +after_open) Some{parent_key}:
      field_result(parse_driver(after_open, QOne{}, scope, depth, Some{key}, Nil{}, scope, depth), parent_key, acc, root_scope, root_depth,
        after_comma => next_scope => next_depth => next_acc => parse_driver(after_comma, QOne{}, next_scope, next_depth, Some{parent_key}, next_acc, root_scope, root_depth))
    case Name{key} <> +rest Some{parent_key}:
      field_result(variable(key, QOne{}, rest, scope, depth), parent_key, acc, root_scope, root_depth,
        after_comma => next_scope => next_depth => next_acc => parse_driver(after_comma, QOne{}, next_scope, next_depth, Some{parent_key}, next_acc, root_scope, root_depth))
    case Symbol{"+"} <> (Name{key} <> +rest) Some{parent_key}:
      field_result(variable(key, QMany{}, rest, scope, depth), parent_key, acc, root_scope, root_depth,
        after_comma => next_scope => next_depth => next_acc => parse_driver(after_comma, QOne{}, next_scope, next_depth, Some{parent_key}, next_acc, root_scope, root_depth))
    case Symbol{"-"} <> (Name{key} <> +rest) Some{parent_key}:
      field_result(variable(key, QZero{}, rest, scope, depth), parent_key, acc, root_scope, root_depth,
        after_comma => next_scope => next_depth => next_acc => parse_driver(after_comma, QOne{}, next_scope, next_depth, Some{parent_key}, next_acc, root_scope, root_depth))
    case _ None{}:
      ((Variable{"", quantity, depth}, tokens), ((scope, depth), False{}))
    case _ Some{parent_key}:
      ((Constructor{parent_key, List.reverse(&2, Pattern, acc)}, tokens), ((root_scope, root_depth), False{}))

def parse_pattern(tokens: List<&2, Token>) -> (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool):
  parse_driver(tokens, QOne{}, Nil{}, 0n, None{}, Nil{}, Nil{}, 0n)

def test_variable(result: (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((Variable{"x", QOne{}, 0n}, Nil{}), ((["x"], 1n), True{})): True{}
    case _: False{}

def test_named(result: (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((Variable{"x", QMany{}, 0n}, Nil{}), ((["x"], 1n), True{})): True{}
    case _: False{}

def test_zero(result: (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((Constructor{"Zero", Nil{}}, Nil{}), ((Nil{}, 0n), True{})): True{}
    case _: False{}

def test_multiple(result: (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((Constructor{"Pair", [Variable{"x", QOne{}, 0n}, Variable{"y", QOne{}, 1n}]}, Nil{}), ((["y", "x"], 2n), True{})): True{}
    case _: False{}

def test_nested(result: (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((Constructor{"Box", [Constructor{"Inner", [Variable{"v", QOne{}, 0n}]}, Variable{"tail", QOne{}, 1n}]}, Nil{}), ((["tail", "v"], 2n), True{})): True{}
    case _: False{}

def test_remainder(result: (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((Constructor{"Zero", Nil{}}, Symbol{"!"} <> Nil{}), ((Nil{}, 0n), True{})): True{}
    case _: False{}

def test_failure(result: (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((Constructor{"Pair", [Variable{"x", QOne{}, 0n}]}, Symbol{"?"} <> _), ((Nil{}, 0n), False{})): True{}
    case _: False{}

def bool_text(value: Bool) -> String:
  match value:
    case True{}: "true"
    case False{}: "false"

law main:
  IO(Unit)

def main():
  IO.print(String.concat(["variable=", bool_text(test_variable(parse_pattern([Name{"x"}]))), ";named=", bool_text(test_named(parse_pattern([Symbol{"+"}, Name{"x"}]))), ";zero=", bool_text(test_zero(parse_pattern([Name{"Zero"}, Symbol{"{"}, Symbol{"}"}]))), ";multiple=", bool_text(test_multiple(parse_pattern([Name{"Pair"}, Symbol{"{"}, Name{"x"}, Symbol{","}, Name{"y"}, Symbol{"}"}]))), ";nested=", bool_text(test_nested(parse_pattern([Name{"Box"}, Symbol{"{"}, Name{"Inner"}, Symbol{"{"}, Name{"v"}, Symbol{"}"}, Symbol{","}, Name{"tail"}, Symbol{"}"}]))), ";remainder=", bool_text(test_remainder(parse_pattern([Name{"Zero"}, Symbol{"{"}, Symbol{"}"}, Symbol{"!"}]))), ";failure=", bool_text(test_failure(parse_pattern([Name{"Pair"}, Symbol{"{"}, Name{"x"}, Symbol{"?"}])))]))
