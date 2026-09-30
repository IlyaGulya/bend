import Base
import ./ast.bend as AST

type Position is Data:
  At{line: Nat, column: Nat}

type PositionStep is Data:
  Stop{}
  Newline{}
  Narrow{}
  Wide{}

def width(c: Char) -> Nat:
  Bool.pick(Nat, U32.is_gt(Char.to_u32(c), 65535), 2n, 1n)

def position_step_flags(before: Bool, newline: Bool, wide: Bool) -> PositionStep:
  match before newline wide:
    case True{} _ _: Stop{}
    case False{} True{} _: Newline{}
    case False{} False{} True{}: Wide{}
    case False{} False{} False{}: Narrow{}

def position_step(cs: List<&2, Char>, offset: Nat) -> PositionStep:
  match cs:
    case Nil{}: Stop{}
    case +c <> _:
      position_step_flags(Nat.is_lt(offset, width(c)), Char.is_eq(c, '\n'), U32.is_gt(Char.to_u32(c), 65535))

def locate(cs: List<&2, Char>, +offset: Nat, line: Nat, column: Nat, step: PositionStep) -> Position:
  match cs step:
    case Nil{} _: At{line, column}
    case +_ <> +_ Stop{}: At{line, column}
    case +_ <> rest Newline{}:
      locate(rest, offset - 1n, line + 1n, 1n, position_step(rest, offset - 1n))
    case +_ <> rest Narrow{}:
      locate(rest, offset - 1n, line, column + 1n, position_step(rest, offset - 1n))
    case +_ <> rest Wide{}:
      locate(rest, offset - 2n, line, column + 2n, position_step(rest, offset - 2n))

def locate_start(+cs: List<&2, Char>, +offset: Nat, line: Nat, column: Nat) -> Position:
  locate(cs, offset, line, column, position_step(cs, offset))
def line_at(lines: List<&2, String>, line: Nat) -> String:
  match lines line:
    case Nil{} _: SNil{}
    case +text <> _ 1n: text
    case +_ <> rest 1n+more: line_at(rest, more)
    case +_ <> _ _: SNil{}

def location_text(file: String, line: Nat, column: Nat) -> String:
  location = String.append(file, String.append(":", String.append(Nat.show(line), String.append(":", Nat.show(column)))))
  String.append("\nLocation: ", location)

def excerpt_text(number: String, excerpt: String) -> String:
  String.append("\n  ", String.append(number, String.append(" | ", excerpt)))

def caret_text(column: Nat) -> String:
  String.append("\n    | ", String.append(String.repeat(" ", column - 1n), "^"))

def format_position(position: Position, message: String, expected: String, observed: String, file: String, source: String) -> String:
  match position:
    case At{+line, +column}:
      number = Nat.show(line)
      excerpt = line_at(String.lines(source), line)
      header = String.append(String.append("Error: ", message), String.append("\n- expected: ", expected))
      observed_line = String.append("\n- observed: ", observed)
      details = String.append(location_text(file, line, column), excerpt_text(number, excerpt))
      String.append(String.append(header, observed_line), String.append(details, caret_text(column)))
def format(message: String, expected: String, observed: String, span: AST.SourceSpan, +source: String) -> String:
  match span:
    case AST.SpanOf{file, beg,  _}:
      format_position(locate_start(String.to_list(source), beg, 1n, 1n), message, expected, observed, file, source)

