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
type Goal is Data:
  SingleGoal{}
  CaseGoal{acc: List<&2, Pattern>, before_scope: List<&2, String>, before_depth: Nat}

type ScanOutcome is Data:
  SingleOutcome{pattern: Pattern, after: List<&2, Token>, scope: List<&2, String>, depth: Nat, ok: Bool}
  CaseOutcome{patterns: List<&2, Pattern>, after: List<&2, Token>, scope: List<&2, String>, depth: Nat, ok: Bool}

def finish(goal: Goal, pattern: Pattern, after: List<&2, Token>, scope: List<&2, String>, depth: Nat, ok: Bool) -> ScanOutcome:
  match goal ok:
    case SingleGoal{} status:
      SingleOutcome{pattern, after, scope, depth, status}
    case CaseGoal{acc, before_scope, before_depth} True{}:
      CaseOutcome{List.reverse(&2, Pattern, pattern <> acc), after, scope, depth, False{}}
    case CaseGoal{acc, before_scope, before_depth} False{}:
      CaseOutcome{List.reverse(&2, Pattern, acc), after, before_scope, before_depth, False{}}


# Only this function recurses; every self-call receives a tail from match tokens.
def scan(+tokens: List<&2, Token>, mode: Mode, frames: List<&2, Frame>, +scope: List<&2, String>, +depth: Nat, goal: Goal) -> ScanOutcome:
  match tokens mode:
    case Symbol{"+"} <> +rest Expect{QOne{}}:
      scan(rest, Expect{QMany{}}, frames, scope, depth, goal)
    case Symbol{"-"} <> +rest Expect{QOne{}}:
      finish(goal, Variable{"", QOne{}, depth}, tokens, scope, depth, False{})
    case Name{key} <> (Symbol{"{"} <> +after_open) Expect{quantity}:
      scan(after_open, Expect{QOne{}}, Frame{key, Nil{}, scope, depth} <> frames, scope, depth, goal)
    case Name{+key} <> +rest Expect{quantity}:
      scan(rest, Completed{Variable{key, quantity, depth}}, frames, key <> scope, depth + 1n, goal)
    case Line{} <> +rest Expect{quantity}:
      scan(rest, Expect{quantity}, frames, scope, depth, goal)
    case Symbol{"}"} <> +rest Expect{quantity}:
      match frames:
        case Frame{key, fields, root_scope, root_depth} <> parents:
          scan(rest, Completed{Constructor{key, List.reverse(&2, Pattern, fields)}}, parents, scope, depth, goal)
        case Nil{}:
          finish(goal, Variable{"", quantity, depth}, tokens, scope, depth, False{})
    case Symbol{","} <> +rest Completed{pattern}:
      match frames:
        case Frame{key, fields, root_scope, root_depth} <> parents:
          scan(rest, Expect{QOne{}}, Frame{key, pattern <> fields, root_scope, root_depth} <> parents, scope, depth, goal)
        case Nil{}:
          match goal:
            case SingleGoal{}:
              SingleOutcome{pattern, tokens, scope, depth, True{}}
            case CaseGoal{acc, before_scope, before_depth}:
              scan(rest, Expect{QOne{}}, Nil{}, scope, depth, CaseGoal{pattern <> acc, scope, depth})
    case Symbol{":"} <> +rest Completed{pattern}:
      match frames:
        case Frame{key, fields, root_scope, root_depth} <> parents:
          finish(goal, Constructor{key, List.reverse(&2, Pattern, pattern <> fields)}, tokens, root_scope, root_depth, False{})
        case Nil{}:
          match goal:
            case SingleGoal{}:
              SingleOutcome{pattern, tokens, scope, depth, True{}}
            case CaseGoal{acc, before_scope, before_depth}:
              CaseOutcome{List.reverse(&2, Pattern, pattern <> acc), tokens, scope, depth, True{}}
    case Symbol{"}"} <> +rest Completed{pattern}:
      match frames:
        case Frame{key, fields, root_scope, root_depth} <> parents:
          scan(rest, Completed{Constructor{key, List.reverse(&2, Pattern, pattern <> fields)}}, parents, scope, depth, goal)
        case Nil{}:
          finish(goal, pattern, tokens, scope, depth, True{})
    case Line{} <> +rest Completed{pattern}:
      match frames:
        case +_ <> _:
          scan(rest, Completed{pattern}, frames, scope, depth, goal)
        case Nil{}:
          match goal:
            case SingleGoal{}:
              SingleOutcome{pattern, tokens, scope, depth, True{}}
            case CaseGoal{acc, before_scope, before_depth}:
              scan(rest, Completed{pattern}, Nil{}, scope, depth, CaseGoal{acc, before_scope, before_depth})
    case Name{key} <> (Symbol{"{"} <> +after_open) Completed{pattern}:
      match frames:
        case Frame{parent, fields, root_scope, root_depth} <> parents:
          scan(after_open, Expect{QOne{}}, Frame{key, Nil{}, scope, depth} <> (Frame{parent, pattern <> fields, root_scope, root_depth} <> parents), scope, depth, goal)
        case Nil{}:
          finish(goal, pattern, tokens, scope, depth, True{})
    case Name{+key} <> +rest Completed{pattern}:
      match frames:
        case Frame{parent, fields, root_scope, root_depth} <> parents:
          scan(rest, Completed{Variable{key, QOne{}, depth}}, Frame{parent, pattern <> fields, root_scope, root_depth} <> parents, key <> scope, depth + 1n, goal)
        case Nil{}:
          finish(goal, pattern, tokens, scope, depth, True{})
    case Symbol{"+"} <> +rest Completed{pattern}:
      match frames:
        case Frame{parent, fields, root_scope, root_depth} <> parents:
          scan(rest, Expect{QMany{}}, Frame{parent, pattern <> fields, root_scope, root_depth} <> parents, scope, depth, goal)
        case Nil{}:
          finish(goal, pattern, tokens, scope, depth, True{})
    case _ Completed{pattern}:
      match frames:
        case Frame{key, fields, root_scope, root_depth} <> parents:
          finish(goal, Constructor{key, List.reverse(&2, Pattern, pattern <> fields)}, tokens, root_scope, root_depth, False{})
        case Nil{}:
          finish(goal, pattern, tokens, scope, depth, True{})
    case _ Expect{quantity}:
      match frames:
        case Frame{key, fields, root_scope, root_depth} <> parents:
          finish(goal, Constructor{key, List.reverse(&2, Pattern, fields)}, tokens, root_scope, root_depth, False{})
        case Nil{}:
          finish(goal, Variable{"", quantity, depth}, tokens, scope, depth, False{})

def parse_pattern(tokens: List<&2, Token>) -> ScanOutcome:
  scan(tokens, Expect{QOne{}}, Nil{}, Nil{}, 0n, SingleGoal{})

def parse_case_list(tokens: List<&2, Token>) -> ScanOutcome:
  scan(tokens, Expect{QOne{}}, Nil{}, Nil{}, 0n, CaseGoal{Nil{}, Nil{}, 0n})

def test_variable(result: ScanOutcome) -> Bool:
  match result:
    case SingleOutcome{Variable{"x", QOne{}, 0n}, Nil{}, ["x"], 1n, True{}}: True{}
    case _: False{}

def test_quantity(result: ScanOutcome) -> Bool:
  match result:
    case SingleOutcome{Variable{"x", QMany{}, 0n}, Nil{}, ["x"], 1n, True{}}: True{}
    case _: False{}

def test_minus(result: ScanOutcome) -> Bool:
  match result:
    case SingleOutcome{_, Symbol{"-"} <> (Name{"x"} <> Nil{}), Nil{}, 0n, False{}}: True{}
    case _: False{}

def test_empty(result: ScanOutcome) -> Bool:
  match result:
    case SingleOutcome{Constructor{"Zero", Nil{}}, Nil{}, Nil{}, 0n, True{}}: True{}
    case _: False{}

def test_two(result: ScanOutcome) -> Bool:
  match result:
    case SingleOutcome{Constructor{"Pair", [Variable{"x", QOne{}, 0n}, Variable{"y", QOne{}, 1n}]}, Nil{}, ["y", "x"], 2n, True{}}: True{}
    case _: False{}

def test_nested(result: ScanOutcome) -> Bool:
  match result:
    case SingleOutcome{Constructor{"Box", [Constructor{"Inner", [Variable{"v", QOne{}, 0n}]}]}, Nil{}, ["v"], 1n, True{}}: True{}
    case _: False{}

def test_sibling(result: ScanOutcome) -> Bool:
  match result:
    case SingleOutcome{Constructor{"Box", [Constructor{"Inner", [Variable{"v", QOne{}, 0n}]}, Variable{"tail", QOne{}, 1n}]}, Nil{}, ["tail", "v"], 2n, True{}}: True{}
    case _: False{}

def test_lines(result: ScanOutcome) -> Bool:
  match result:
    case SingleOutcome{Constructor{"Pair", [Variable{"x", QOne{}, 0n}, Variable{"y", QOne{}, 1n}]}, Nil{}, ["y", "x"], 2n, True{}}: True{}
    case _: False{}

def test_remainder(result: ScanOutcome) -> Bool:
  match result:
    case SingleOutcome{Variable{"x", QOne{}, 0n}, Symbol{":"} <> Nil{}, ["x"], 1n, True{}}: True{}
    case _: False{}

def test_constructor_remainder(result: ScanOutcome) -> Bool:
  match result:
    case SingleOutcome{Constructor{"Zero", Nil{}}, Symbol{":"} <> Nil{}, Nil{}, 0n, True{}}: True{}
    case _: False{}

def test_failure(result: ScanOutcome) -> Bool:
  match result:
    case SingleOutcome{Constructor{"Pair", [Variable{"x", QOne{}, 0n}]}, Symbol{"?"} <> Nil{}, Nil{}, 0n, False{}}: True{}
    case _: False{}

def test_case_one(result: ScanOutcome) -> Bool:
  match result:
    case CaseOutcome{[Variable{"x", QOne{}, 0n}], Symbol{":"} <> Nil{}, ["x"], 1n, True{}}: True{}
    case _: False{}

def test_case_two(result: ScanOutcome) -> Bool:
  match result:
    case CaseOutcome{[Variable{"x", QOne{}, 0n}, Variable{"y", QOne{}, 1n}], Symbol{":"} <> Nil{}, ["y", "x"], 2n, True{}}: True{}
    case _: False{}

def test_case_constructor(result: ScanOutcome) -> Bool:
  match result:
    case CaseOutcome{[Constructor{"Foo", [Variable{"x", QOne{}, 0n}]}, Variable{"y", QOne{}, 1n}], Symbol{":"} <> Nil{}, ["y", "x"], 2n, True{}}: True{}
    case _: False{}

def test_case_nested(result: ScanOutcome) -> Bool:
  match result:
    case CaseOutcome{[Constructor{"Foo", [Constructor{"Bar", [Variable{"x", QOne{}, 0n}]}, Variable{"z", QOne{}, 1n}]}, Constructor{"Tail", Nil{}}], Symbol{":"} <> Nil{}, ["z", "x"], 2n, True{}}: True{}
    case _: False{}

def test_case_lines(result: ScanOutcome) -> Bool:
  match result:
    case CaseOutcome{[Variable{"x", QOne{}, 0n}, Variable{"y", QOne{}, 1n}], Symbol{":"} <> Nil{}, ["y", "x"], 2n, True{}}: True{}
    case _: False{}

def test_case_bad_second(result: ScanOutcome) -> Bool:
  match result:
    case CaseOutcome{[Variable{"x", QOne{}, 0n}], Symbol{"?"} <> Nil{}, ["x"], 1n, False{}}: True{}
    case _: False{}

def test_case_missing_colon(result: ScanOutcome) -> Bool:
  match result:
    case CaseOutcome{[Variable{"x", QOne{}, 0n}, Variable{"y", QOne{}, 1n}], Nil{}, ["y", "x"], 2n, False{}}: True{}
    case _: False{}

def test_case_unexpected(result: ScanOutcome) -> Bool:
  match result:
    case CaseOutcome{[Variable{"x", QOne{}, 0n}, Variable{"y", QOne{}, 1n}], Symbol{"!"} <> Nil{}, ["y", "x"], 2n, False{}}: True{}
    case _: False{}

def bool_text(value: Bool) -> String:
  match value:
    case True{}: "true"
    case False{}: "false"

def case_output() -> String:
  String.concat([";case-one=", bool_text(test_case_one(parse_case_list([Name{"x"}, Symbol{":"}]))), ";case-two=", bool_text(test_case_two(parse_case_list([Name{"x"}, Symbol{","}, Name{"y"}, Symbol{":"}]))), ";case-constructor=", bool_text(test_case_constructor(parse_case_list([Name{"Foo"}, Symbol{"{"}, Name{"x"}, Symbol{"}"}, Symbol{","}, Name{"y"}, Symbol{":"}]))), ";case-nested=", bool_text(test_case_nested(parse_case_list([Name{"Foo"}, Symbol{"{"}, Name{"Bar"}, Symbol{"{"}, Name{"x"}, Symbol{"}"}, Symbol{","}, Name{"z"}, Symbol{"}"}, Symbol{","}, Name{"Tail"}, Symbol{"{"}, Symbol{"}"}, Symbol{":"}]))), ";case-lines=", bool_text(test_case_lines(parse_case_list([Name{"x"}, Line{}, Symbol{","}, Line{}, Name{"y"}, Line{}, Symbol{":"}]))), ";case-bad-second=", bool_text(test_case_bad_second(parse_case_list([Name{"x"}, Symbol{","}, Symbol{"?"}]))), ";case-missing-colon=", bool_text(test_case_missing_colon(parse_case_list([Name{"x"}, Symbol{","}, Name{"y"}]))), ";case-unexpected=", bool_text(test_case_unexpected(parse_case_list([Name{"x"}, Symbol{","}, Name{"y"}, Symbol{"!"}])))] )
law main:
  IO(Unit)

def main():
  IO.print(String.concat(["variable=", bool_text(test_variable(parse_pattern([Name{"x"}]))), ";quantity=", bool_text(test_quantity(parse_pattern([Symbol{"+"}, Name{"x"}]))), ";minus=", bool_text(test_minus(parse_pattern([Symbol{"-"}, Name{"x"}]))), ";empty=", bool_text(test_empty(parse_pattern([Name{"Zero"}, Symbol{"{"}, Symbol{"}"}]))), ";two=", bool_text(test_two(parse_pattern([Name{"Pair"}, Symbol{"{"}, Name{"x"}, Symbol{","}, Name{"y"}, Symbol{"}"}]))), ";nested=", bool_text(test_nested(parse_pattern([Name{"Box"}, Symbol{"{"}, Name{"Inner"}, Symbol{"{"}, Name{"v"}, Symbol{"}"}, Symbol{"}"}]))), ";sibling=", bool_text(test_sibling(parse_pattern([Name{"Box"}, Symbol{"{"}, Name{"Inner"}, Symbol{"{"}, Name{"v"}, Symbol{"}"}, Symbol{","}, Name{"tail"}, Symbol{"}"}]))), ";lines=", bool_text(test_lines(parse_pattern([Name{"Pair"}, Symbol{"{"}, Line{}, Name{"x"}, Line{}, Symbol{","}, Line{}, Name{"y"}, Line{}, Symbol{"}"}]))), ";remainder=", bool_text(test_remainder(parse_pattern([Name{"x"}, Symbol{":"}]))), ";constructor-remainder=", bool_text(test_constructor_remainder(parse_pattern([Name{"Zero"}, Symbol{"{"}, Symbol{"}"}, Symbol{":"}]))), ";failure=", bool_text(test_failure(parse_pattern([Name{"Pair"}, Symbol{"{"}, Name{"x"}, Symbol{"?"}]))), ";omitted-comma=", bool_text(test_two(parse_pattern([Name{"Pair"}, Symbol{"{"}, Name{"x"}, Line{}, Name{"y"}, Symbol{"}"}]))), case_output()]))
