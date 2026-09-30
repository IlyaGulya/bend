import Base
import ./c_parts.bend as CParts

type AssemblyResult is Data:
  AssemblySuccess{source: String}
  AssemblyFailure{marker: String, observed: String}

type MarkerPass is Data:
  MarkerPass{lines: List<&2, String>, count: Nat}

def marker_count(lines: List<&2, String>, title: String, rule: String) -> Nat:
  match lines:
    case +line <> rest:
      match rest:
        case +next <> tail:
          marker_count_title(line, next, tail, rest, title, rule, String.eq(line, title))
        case Nil{}: 0n
    case Nil{}: 0n

def marker_count_title(line: String, next: String, tail: List<&2, String>, rest: List<&2, String>, title: String, rule: String, matches: Bool) -> Nat:
  match matches:
    case True{}: marker_count_rule(next, tail, rest, title, rule, String.eq(next, rule))
    case False{}: marker_count(rest, title, rule)

def marker_count_rule(next: String, tail: List<&2, String>, rest: List<&2, String>, title: String, rule: String, matches: Bool) -> Nat:
  match matches:
    case True{}: 1n + marker_count(tail, title, rule)
    case False{}: marker_count(rest, title, rule)


def insert_marker(lines: List<&2, String>, title: String, rule: String, block: String) -> MarkerPass:
  match lines:
    case +line <> rest:
      match rest:
        case +next <> tail:
          insert_marker_title(line, next, tail, rest, title, rule, block, String.eq(line, title))
        case Nil{}: MarkerPass{ [line],  0n}
    case Nil{}: MarkerPass{ Nil{},  0n}

def insert_marker_title(line: String, next: String, tail: List<&2, String>, rest: List<&2, String>, title: String, rule: String, block: String, matches: Bool) -> MarkerPass:
  match matches:
    case True{}: insert_marker_rule(line, next, tail, rest, title, rule, block, String.eq(next, rule))
    case False{}:
      prepend_marker(insert_marker(rest, title, rule, block), line)

def prepend_marker(inserted: MarkerPass, line: String) -> MarkerPass:
  match inserted:
    case MarkerPass{ after, count}: MarkerPass{ line <> after, count}

def insert_marker_rule(line: String, next: String, tail: List<&2, String>, rest: List<&2, String>, title: String, rule: String, block: String, matches: Bool) -> MarkerPass:
  match matches:
    case True{}: insert_marker_block(line, next, tail, title, rule, block, String.is_empty(block))
    case False{}:
      prepend_marker(insert_marker(rest, title, rule, block), line)

def insert_marker_block(line: String, next: String, tail: List<&2, String>, title: String, rule: String, block: String, empty: Bool) -> MarkerPass:
  match empty:
    case True{}:
      insert_marker_keep(insert_marker(tail, title, rule, block), line, next)
    case False{}:
      insert_marker_replace(insert_marker(tail, title, rule, block), line, next, block)

def insert_marker_keep(inserted: MarkerPass, line: String, next: String) -> MarkerPass:
  match inserted:
    case MarkerPass{ after, count}: MarkerPass{ line <> (next <> after), count + 1n}

def insert_marker_replace(inserted: MarkerPass, line: String, next: String, block: String) -> MarkerPass:
  match inserted:
    case MarkerPass{ after, count}: MarkerPass{ line <> (String.append(next, String.append("\n\n", block)) <> after), count + 1n}

def assemble_marker(source: String, title: String, rule: String, block: String) -> AssemblyResult:
  lines = String.split(source, '\n')
  count = marker_count(lines, title, rule)
  assemble_marker_count(lines, count, title, rule, block)

def assemble_marker_count(lines: List<&2, String>, count: Nat, title: String, rule: String, block: String) -> AssemblyResult:
  match count:
    case 1n:
      assemble_marker_result(insert_marker(lines, title, rule, block))
    case _:
      AssemblyFailure{ title,  Nat.show(count)}

def assemble_marker_result(inserted: MarkerPass) -> AssemblyResult:
  match inserted:
    case MarkerPass{ after,  _}:
      AssemblySuccess{ String.join(after, '\n')}

def assemble(template: String, parts: CParts.Parts) -> AssemblyResult:
  match parts:
    case CParts.Parts{tables, spins, segments, requests}:
      assemble_tables(assemble_marker(template, "// Tables", "// ======", tables), spins, segments, requests)

def assemble_tables(result: AssemblyResult, spins: String, segments: String, requests: String) -> AssemblyResult:
  match result:
    case AssemblyFailure{marker, observed}: AssemblyFailure{marker, observed}
    case AssemblySuccess{source}:
      assemble_spins(assemble_marker(source, "// Spins", "// =====", spins), segments, requests)

def assemble_spins(result: AssemblyResult, segments: String, requests: String) -> AssemblyResult:
  match result:
    case AssemblyFailure{marker, observed}: AssemblyFailure{marker, observed}
    case AssemblySuccess{source}:
      assemble_segments(assemble_marker(source, "// Segments", "// ========", segments), requests)

def assemble_segments(result: AssemblyResult, requests: String) -> AssemblyResult:
  match result:
    case AssemblyFailure{marker, observed}: AssemblyFailure{marker, observed}
    case AssemblySuccess{source}:
      assemble_marker(source, "// Requests", "// ========", requests)
