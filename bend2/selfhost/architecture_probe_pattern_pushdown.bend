import Base

type Quantity is Data:
  QOne{}
  QMany{}
  QZero{}

type Token is Data:
  Name{key: String}
  Symbol{text: String}
  Line{}

type Pattern is Data:
  Variable{key: String, quantity: Quantity, depth: Nat}
  Constructor{key: String, fields: List<&2, Pattern>}

type Mode is Data:
  Expect{quantity: Quantity}
  Completed{pattern: Pattern}

type Frame is Data:
  Frame{key: String, fields: List<&2, Pattern>, root_scope: List<&2, String>, root_depth: Nat}

# Only this function recurses; every call passes a direct tail bound by match tokens.
def scan(+tokens: List<&2, Token>, mode: Mode, frames: List<&2, Frame>, +scope: List<&2, String>, +depth: Nat) -> (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool):
  match tokens mode:
    case Symbol{"+"} <> +rest Expect{QOne{}}:
      scan(rest, Expect{QMany{}}, frames, scope, depth)
    case Symbol{"-"} <> +rest Expect{QOne{}}:
      ((Variable{"", QOne{}, depth}, tokens), ((scope, depth), False{}))
    case Name{key} <> (Symbol{"{"} <> +after_open) Expect{quantity}:
      scan(after_open, Expect{QOne{}}, Frame{key, Nil{}, scope, depth} <> frames, scope, depth)
    case Name{+key} <> +rest Expect{quantity}:
      scan(rest, Completed{Variable{key, quantity, depth}}, frames, key <> scope, depth + 1n)
    case Line{} <> +rest Expect{quantity}:
      scan(rest, Expect{quantity}, frames, scope, depth)
    case Symbol{"}"} <> +rest Expect{quantity}:
      match frames:
        case Frame{key, fields, root_scope, root_depth} <> parents:
          scan(rest, Completed{Constructor{key, List.reverse(&2, Pattern, fields)}}, parents, scope, depth)
        case Nil{}:
          ((Variable{"", quantity, depth}, tokens), ((scope, depth), False{}))
    case Symbol{","} <> +rest Completed{pattern}:
      match frames:
        case Frame{key, fields, root_scope, root_depth} <> parents:
          scan(rest, Expect{QOne{}}, Frame{key, pattern <> fields, root_scope, root_depth} <> parents, scope, depth)
        case Nil{}:
          ((pattern, tokens), ((scope, depth), True{}))
    case Symbol{"}"} <> +rest Completed{pattern}:
      match frames:
        case Frame{key, fields, root_scope, root_depth} <> parents:
          scan(rest, Completed{Constructor{key, List.reverse(&2, Pattern, pattern <> fields)}}, parents, scope, depth)
        case Nil{}:
          ((pattern, tokens), ((scope, depth), True{}))
    case Line{} <> +rest Completed{pattern}:
      match frames:
        case +_ <> _:
          scan(rest, Completed{pattern}, frames, scope, depth)
        case Nil{}:
          ((pattern, tokens), ((scope, depth), True{}))
    case Name{key} <> (Symbol{"{"} <> +after_open) Completed{pattern}:
      match frames:
        case Frame{parent, fields, root_scope, root_depth} <> parents:
          scan(after_open, Expect{QOne{}}, Frame{key, Nil{}, scope, depth} <> (Frame{parent, pattern <> fields, root_scope, root_depth} <> parents), scope, depth)
        case Nil{}:
          ((pattern, tokens), ((scope, depth), True{}))
    case Name{+key} <> +rest Completed{pattern}:
      match frames:
        case Frame{parent, fields, root_scope, root_depth} <> parents:
          scan(rest, Completed{Variable{key, QOne{}, depth}}, Frame{parent, pattern <> fields, root_scope, root_depth} <> parents, key <> scope, depth + 1n)
        case Nil{}:
          ((pattern, tokens), ((scope, depth), True{}))
    case Symbol{"+"} <> +rest Completed{pattern}:
      match frames:
        case Frame{parent, fields, root_scope, root_depth} <> parents:
          scan(rest, Expect{QMany{}}, Frame{parent, pattern <> fields, root_scope, root_depth} <> parents, scope, depth)
        case Nil{}:
          ((pattern, tokens), ((scope, depth), True{}))
    case _ Completed{pattern}:
      match frames:
        case Frame{key, fields, root_scope, root_depth} <> parents:
          ((Constructor{key, List.reverse(&2, Pattern, pattern <> fields)}, tokens), ((root_scope, root_depth), False{}))
        case Nil{}:
          ((pattern, tokens), ((scope, depth), True{}))
    case _ Expect{quantity}:
      match frames:
        case Frame{key, fields, root_scope, root_depth} <> parents:
          ((Constructor{key, List.reverse(&2, Pattern, fields)}, tokens), ((root_scope, root_depth), False{}))
        case Nil{}:
          ((Variable{"", quantity, depth}, tokens), ((scope, depth), False{}))

def parse_pattern(tokens: List<&2, Token>) -> (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool):
  scan(tokens, Expect{QOne{}}, Nil{}, Nil{}, 0n)

def test_variable(result: (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((Variable{"x", QOne{}, 0n}, Nil{}), ((["x"], 1n), True{})): True{}
    case _: False{}

def test_quantity(result: (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((Variable{"x", QMany{}, 0n}, Nil{}), ((["x"], 1n), True{})): True{}
    case _: False{}

def test_minus(result: (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((_, Symbol{"-"} <> (Name{"x"} <> Nil{})), ((Nil{}, 0n), False{})): True{}
    case _: False{}

def test_empty(result: (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((Constructor{"Zero", Nil{}}, Nil{}), ((Nil{}, 0n), True{})): True{}
    case _: False{}

def test_two(result: (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((Constructor{"Pair", [Variable{"x", QOne{}, 0n}, Variable{"y", QOne{}, 1n}]}, Nil{}), ((["y", "x"], 2n), True{})): True{}
    case _: False{}

def test_nested(result: (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((Constructor{"Box", [Constructor{"Inner", [Variable{"v", QOne{}, 0n}]}]}, Nil{}), ((["v"], 1n), True{})): True{}
    case _: False{}

def test_sibling(result: (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((Constructor{"Box", [Constructor{"Inner", [Variable{"v", QOne{}, 0n}]}, Variable{"tail", QOne{}, 1n}]}, Nil{}), ((["tail", "v"], 2n), True{})): True{}
    case _: False{}

def test_lines(result: (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((Constructor{"Pair", [Variable{"x", QOne{}, 0n}, Variable{"y", QOne{}, 1n}]}, Nil{}), ((["y", "x"], 2n), True{})): True{}
    case _: False{}

def test_remainder(result: (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((Variable{"x", QOne{}, 0n}, Symbol{":"} <> Nil{}), ((["x"], 1n), True{})): True{}
    case _: False{}

def test_constructor_remainder(result: (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((Constructor{"Zero", Nil{}}, Symbol{":"} <> Nil{}), ((Nil{}, 0n), True{})): True{}
    case _: False{}

def test_failure(result: (Pattern & List<&2, Token>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((Constructor{"Pair", [Variable{"x", QOne{}, 0n}]}, Symbol{"?"} <> Nil{}), ((Nil{}, 0n), False{})): True{}
    case _: False{}

def bool_text(value: Bool) -> String:
  match value:
    case True{}: "true"
    case False{}: "false"

law main:
  IO(Unit)

def main():
  IO.print(String.concat(["variable=", bool_text(test_variable(parse_pattern([Name{"x"}]))), ";quantity=", bool_text(test_quantity(parse_pattern([Symbol{"+"}, Name{"x"}]))), ";minus=", bool_text(test_minus(parse_pattern([Symbol{"-"}, Name{"x"}]))), ";empty=", bool_text(test_empty(parse_pattern([Name{"Zero"}, Symbol{"{"}, Symbol{"}"}]))), ";two=", bool_text(test_two(parse_pattern([Name{"Pair"}, Symbol{"{"}, Name{"x"}, Symbol{","}, Name{"y"}, Symbol{"}"}]))), ";nested=", bool_text(test_nested(parse_pattern([Name{"Box"}, Symbol{"{"}, Name{"Inner"}, Symbol{"{"}, Name{"v"}, Symbol{"}"}, Symbol{"}"}]))), ";sibling=", bool_text(test_sibling(parse_pattern([Name{"Box"}, Symbol{"{"}, Name{"Inner"}, Symbol{"{"}, Name{"v"}, Symbol{"}"}, Symbol{","}, Name{"tail"}, Symbol{"}"}]))), ";lines=", bool_text(test_lines(parse_pattern([Name{"Pair"}, Symbol{"{"}, Line{}, Name{"x"}, Line{}, Symbol{","}, Line{}, Name{"y"}, Line{}, Symbol{"}"}]))), ";remainder=", bool_text(test_remainder(parse_pattern([Name{"x"}, Symbol{":"}]))), ";constructor-remainder=", bool_text(test_constructor_remainder(parse_pattern([Name{"Zero"}, Symbol{"{"}, Symbol{"}"}, Symbol{":"}]))), ";failure=", bool_text(test_failure(parse_pattern([Name{"Pair"}, Symbol{"{"}, Name{"x"}, Symbol{"?"}]))), ";omitted-comma=", bool_text(test_two(parse_pattern([Name{"Pair"}, Symbol{"{"}, Name{"x"}, Line{}, Name{"y"}, Symbol{"}"}])))]))
