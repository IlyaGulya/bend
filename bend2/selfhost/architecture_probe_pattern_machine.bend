import Base

type Quantity is Data:
  QOne{}
  QMany{}
  QZero{}

type ProbeToken is Data:
  ProbeName{key: String}
  ProbeSymbol{value: String}

type ProbePattern is Data:
  ProbeVariable{key: String, quantity: Quantity, depth: Nat}
  ProbeConstructor{key: String, fields: List<&2, ProbePattern>}

type PatternState is Data:
  Atom{original: List<&2, ProbeToken>, scope: List<&2, String>, depth: Nat}
  Named{original: List<&2, ProbeToken>, quantity: Quantity, scope: List<&2, String>, depth: Nat}
  Fields{scanned: List<&2, ProbeToken>, original: List<&2, ProbeToken>, key: String, scope: List<&2, String>, depth: Nat, root_scope: List<&2, String>, root_depth: Nat, acc: List<&2, ProbePattern>}

def parse_variable(tokens: List<&2, ProbeToken>, quantity: Quantity, scope: List<&2, String>, +depth: Nat) -> (ProbePattern & List<&2, ProbeToken>) & ((List<&2, String> & Nat) & Bool):
  match tokens:
    case ProbeName{+key} <> +rest:
      ((ProbeVariable{key, quantity, depth}, rest), ((key <> scope, depth + 1n), True{}))
    case _:
      ((ProbeVariable{"", quantity, depth}, tokens), ((scope, depth), False{}))

def field_separator_step(key: String, root_scope: List<&2, String>, root_depth: Nat, +acc: List<&2, ProbePattern>, +pattern: ProbePattern, separator: ProbeToken, +after_separator: List<&2, ProbeToken>, +next_scope: List<&2, String>, +next_depth: Nat, use_done: ProbePattern -> List<&2, ProbeToken> -> List<&2, String> -> Nat -> Bool -> (ProbePattern & List<&2, ProbeToken>) & ((List<&2, String> & Nat) & Bool), use_continue: List<&2, ProbeToken> -> ProbePattern -> List<&2, String> -> Nat -> (ProbePattern & List<&2, ProbeToken>) & ((List<&2, String> & Nat) & Bool)) -> (ProbePattern & List<&2, ProbeToken>) & ((List<&2, String> & Nat) & Bool):
  match separator:
    case ProbeSymbol{","}:
      use_continue(after_separator, pattern, next_scope, next_depth)
    case ProbeSymbol{"}"}:
      use_done(ProbeConstructor{key, List.reverse(&2, ProbePattern, pattern <> acc)}, after_separator, next_scope, next_depth, True{})
    case _:
      use_done(ProbeConstructor{key, List.reverse(&2, ProbePattern, pattern <> acc)}, separator <> after_separator, root_scope, root_depth, False{})

def pattern_fields_step(key: String, root_scope: List<&2, String>, root_depth: Nat, +acc: List<&2, ProbePattern>, result: (ProbePattern & List<&2, ProbeToken>) & ((List<&2, String> & Nat) & Bool), use_done: ProbePattern -> List<&2, ProbeToken> -> List<&2, String> -> Nat -> Bool -> (ProbePattern & List<&2, ProbeToken>) & ((List<&2, String> & Nat) & Bool), use_continue: List<&2, ProbeToken> -> ProbePattern -> List<&2, String> -> Nat -> (ProbePattern & List<&2, ProbeToken>) & ((List<&2, String> & Nat) & Bool)) -> (ProbePattern & List<&2, ProbeToken>) & ((List<&2, String> & Nat) & Bool):
  match result:
    case ((pattern, +separator <> +after_separator), ((next_scope, next_depth), True{})):
      field_separator_step(key, root_scope, root_depth, acc, pattern, separator, after_separator, next_scope, next_depth, use_done, use_continue)
    case ((pattern, Nil{}), ((_, _), True{})):
      use_done(ProbeConstructor{key, List.reverse(&2, ProbePattern, pattern <> acc)}, Nil{}, root_scope, root_depth, False{})
    case ((_, after_pattern), ((_, _), False{})):
      use_done(ProbeConstructor{key, List.reverse(&2, ProbePattern, acc)}, after_pattern, root_scope, root_depth, False{})

def parse_pattern_machine(+tokens: List<&2, ProbeToken>, state: PatternState) -> (ProbePattern & List<&2, ProbeToken>) & ((List<&2, String> & Nat) & Bool):
  match tokens:
    case ProbeSymbol{"+"} <> +after_field:
      match state:
        case Atom{original, scope, depth}:
          parse_pattern_machine(after_field, Named{after_field, QMany{}, scope, depth})
        case Named{original, quantity, scope, depth}:
          parse_variable(original, quantity, scope, depth)
        case Fields{scanned, original, key, scope, depth, root_scope, root_depth, acc}:
          pattern_fields_step(key, root_scope, root_depth, acc, parse_pattern_machine(after_field, Named{after_field, QMany{}, scope, depth}),
            result_pattern => result_after => result_scope => result_depth => result_ok => ((result_pattern, result_after), ((result_scope, result_depth), result_ok)),
            after_separator => pattern => next_scope => next_depth =>
              parse_pattern_machine(after_separator, Fields{after_separator, after_separator, key, next_scope, next_depth, root_scope, root_depth, pattern <> acc}))
    case ProbeSymbol{"-"} <> +after_field:
      match state:
        case Atom{original, scope, depth}:
          parse_pattern_machine(after_field, Named{after_field, QZero{}, scope, depth})
        case Named{original, quantity, scope, depth}:
          parse_variable(original, quantity, scope, depth)
        case Fields{scanned, original, key, scope, depth, root_scope, root_depth, acc}:
          pattern_fields_step(key, root_scope, root_depth, acc, parse_pattern_machine(after_field, Named{after_field, QZero{}, scope, depth}),
            result_pattern => result_after => result_scope => result_depth => result_ok => ((result_pattern, result_after), ((result_scope, result_depth), result_ok)),
            after_separator => pattern => next_scope => next_depth =>
              parse_pattern_machine(after_separator, Fields{after_separator, after_separator, key, next_scope, next_depth, root_scope, root_depth, pattern <> acc}))
    case ProbeName{key} <> (ProbeSymbol{"{"} <> +after_open):
      match state:
        case Atom{original, scope, depth}:
          parse_pattern_machine(after_open, Fields{after_open, after_open, key, scope, depth, scope, depth, Nil{}})
        case Named{original, quantity, scope, depth}:
          parse_pattern_machine(after_open, Fields{after_open, after_open, key, scope, depth, scope, depth, Nil{}})
        case Fields{scanned, original, parent_key, scope, depth, root_scope, root_depth, acc}:
          pattern_fields_step(parent_key, root_scope, root_depth, acc, parse_pattern_machine(after_open, Fields{after_open, after_open, key, scope, depth, scope, depth, Nil{}}),
            result_pattern => result_after => result_scope => result_depth => result_ok => ((result_pattern, result_after), ((result_scope, result_depth), result_ok)),
            after_separator => pattern => next_scope => next_depth =>
              parse_pattern_machine(after_separator, Fields{after_separator, after_separator, parent_key, next_scope, next_depth, root_scope, root_depth, pattern <> acc}))
    case ProbeName{key} <> (+_ <> _):
      match state:
        case Atom{original, scope, depth}:
          parse_variable(original, QOne{}, scope, depth)
        case Named{original, quantity, scope, depth}:
          parse_variable(original, quantity, scope, depth)
        case Fields{scanned, original, parent_key, scope, depth, root_scope, root_depth, acc}:
          pattern_fields_step(parent_key, root_scope, root_depth, acc, parse_variable(original, QOne{}, scope, depth),
            result_pattern => result_after => result_scope => result_depth => result_ok => ((result_pattern, result_after), ((result_scope, result_depth), result_ok)),
            after_separator => pattern => next_scope => next_depth =>
              parse_pattern_machine(after_separator, Fields{after_separator, after_separator, parent_key, next_scope, next_depth, root_scope, root_depth, pattern <> acc}))
    case ProbeName{key} <> Nil{}:
      match state:
        case Atom{original, scope, depth}:
          parse_variable(original, QOne{}, scope, depth)
        case Named{original, quantity, scope, depth}:
          parse_variable(original, quantity, scope, depth)
        case Fields{scanned, original, parent_key, scope, depth, root_scope, root_depth, acc}:
          pattern_fields_step(parent_key, root_scope, root_depth, acc, parse_variable(original, QOne{}, scope, depth),
            result_pattern => result_after => result_scope => result_depth => result_ok => ((result_pattern, result_after), ((result_scope, result_depth), result_ok)),
            after_separator => pattern => next_scope => next_depth =>
              parse_pattern_machine(after_separator, Fields{after_separator, after_separator, parent_key, next_scope, next_depth, root_scope, root_depth, pattern <> acc}))
    case ProbeSymbol{"}"} <> +after_close:
      match state:
        case Fields{scanned, original, key, scope, depth, root_scope, root_depth, acc}:
          ((ProbeConstructor{key, List.reverse(&2, ProbePattern, acc)}, after_close), ((scope, depth), True{}))
        case Atom{original, scope, depth}:
          ((ProbeVariable{"", QOne{}, depth}, tokens), ((scope, depth), False{}))
        case Named{original, quantity, scope, depth}:
          parse_variable(original, quantity, scope, depth)
    case +_ <> _:
      match state:
        case Atom{original, scope, depth}:
          parse_variable(original, QOne{}, scope, depth)
        case Named{original, quantity, scope, depth}:
          parse_variable(original, quantity, scope, depth)
        case Fields{scanned, original, key, scope, depth, root_scope, root_depth, acc}:
          pattern_fields_step(key, root_scope, root_depth, acc, parse_variable(original, QOne{}, scope, depth),
            result_pattern => result_after => result_scope => result_depth => result_ok => ((result_pattern, result_after), ((result_scope, result_depth), result_ok)),
            after_separator => pattern => next_scope => next_depth =>
              parse_pattern_machine(after_separator, Fields{after_separator, after_separator, key, next_scope, next_depth, root_scope, root_depth, pattern <> acc}))
    case Nil{}:
      match state:
        case Atom{original, scope, depth}:
          ((ProbeVariable{"", QOne{}, depth}, Nil{}), ((scope, depth), False{}))
        case Named{original, quantity, scope, depth}:
          parse_variable(Nil{}, quantity, scope, depth)
        case Fields{scanned, original, key, scope, depth, root_scope, root_depth, acc}:
          ((ProbeConstructor{key, List.reverse(&2, ProbePattern, acc)}, Nil{}), ((root_scope, root_depth), False{}))

def parse_pattern(+tokens: List<&2, ProbeToken>, scope: List<&2, String>, +depth: Nat) -> (ProbePattern & List<&2, ProbeToken>) & ((List<&2, String> & Nat) & Bool):
  parse_pattern_machine(tokens, Atom{tokens, scope, depth})

def test_variable(result: (ProbePattern & List<&2, ProbeToken>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((ProbeVariable{"x", QOne{}, 0n}, Nil{}), ((["x"], 1n), True{})): True{}
    case _: False{}

def test_named(result: (ProbePattern & List<&2, ProbeToken>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((ProbeVariable{"x", QMany{}, 0n}, Nil{}), ((["x"], 1n), True{})): True{}
    case _: False{}

def test_zero_fields(result: (ProbePattern & List<&2, ProbeToken>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((ProbeConstructor{"Zero", Nil{}}, Nil{}), ((Nil{}, 0n), True{})): True{}
    case _: False{}

def test_multiple_fields(result: (ProbePattern & List<&2, ProbeToken>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((ProbeConstructor{"Pair", [ProbeVariable{"x", QOne{}, 0n}, ProbeVariable{"y", QOne{}, 1n}]}, Nil{}), ((["y", "x"], 2n), True{})): True{}
    case _: False{}

def test_nested_fields(result: (ProbePattern & List<&2, ProbeToken>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((ProbeConstructor{"Box", [ProbeConstructor{"Inner", [ProbeVariable{"v", QOne{}, 0n}]}, ProbeVariable{"tail", QOne{}, 1n}]}, Nil{}), ((["tail", "v"], 2n), True{})): True{}
    case _: False{}

def test_failure_remainder(result: (ProbePattern & List<&2, ProbeToken>) & ((List<&2, String> & Nat) & Bool)) -> Bool:
  match result:
    case ((ProbeConstructor{"Pair", [ProbeVariable{"x", QOne{}, 0n}]}, ProbeSymbol{"?"} <> _), ((Nil{}, 0n), False{})): True{}
    case _: False{}

def bool_text(value: Bool) -> String:
  match value:
    case True{}: "true"
    case False{}: "false"

law main:
  IO(Unit)

def main():
  IO.print(String.concat(["variable=", bool_text(test_variable(parse_pattern([ProbeName{"x"}], Nil{}, 0n))), ";named=", bool_text(test_named(parse_pattern([ProbeSymbol{"+"}, ProbeName{"x"}], Nil{}, 0n))), ";zero=", bool_text(test_zero_fields(parse_pattern([ProbeName{"Zero"}, ProbeSymbol{"{"}, ProbeSymbol{"}"}], Nil{}, 0n))), ";multiple=", bool_text(test_multiple_fields(parse_pattern([ProbeName{"Pair"}, ProbeSymbol{"{"}, ProbeName{"x"}, ProbeSymbol{","}, ProbeName{"y"}, ProbeSymbol{"}"}], Nil{}, 0n))), ";nested=", bool_text(test_nested_fields(parse_pattern([ProbeName{"Box"}, ProbeSymbol{"{"}, ProbeName{"Inner"}, ProbeSymbol{"{"}, ProbeName{"v"}, ProbeSymbol{"}"}, ProbeSymbol{","}, ProbeName{"tail"}, ProbeSymbol{"}"}], Nil{}, 0n))), ";failure-remainder=", bool_text(test_failure_remainder(parse_pattern([ProbeName{"Pair"}, ProbeSymbol{"{"}, ProbeName{"x"}, ProbeSymbol{","}, ProbeSymbol{"?"}, ProbeSymbol{"}"}], Nil{}, 0n)))]))
