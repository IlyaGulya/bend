import Base
import ../../bend2/selfhost/loaded_module.bend as Loader
import ../../bend2/selfhost/parser.bend as Parser
import ../../bend2/selfhost/checker.bend as Checker
import ../../bend2/selfhost/checked_frontend.bend as Checked
import ../../bend2/selfhost/backend_lower.bend as BackendLower

# Executable-mode entry admission is decided once in the catalog, before either
# target renders. These fixtures use the public parser -> checker -> lowering
# seam, never a hand-built BIR value.

def mainless_source() -> String:
  "type Unit is Data:\n  Unit{}\n\ndef twice(x: Unit) -> Unit:\n  x\n"

def executable_source() -> String:
  "type Unit is Data:\n  Unit{}\n\ndef main() -> Unit:\n  Unit{}\n"

def inferred_source() -> String:
  "type Unit is Data:\n  Unit{}\n\ndef main():\n  Unit{}\n"

def missing_main_result(result: Checked.CheckResult):
  match result:
    case Checked.CheckSuccess{program}:
      match BackendLower.lower(program):
        case BackendLower.LowerFailure{_, _}: IO.print("missing-main-rejected")
        case BackendLower.Lowered{_}: IO.print("missing-main-accepted")
    case Checked.CheckFailure{Checked.Diagnostic{_, _, message, _, _}}:
      IO.print("missing-main-check-failed: " ++ message)

def missing_main(parsed: Parser.ParseResult):
  match parsed:
    case Parser.ParseSuccess{module}:
      missing_main_result(Checker.check([Loader.LoadedModule{"", module}]))
    case Parser.ParseFailure{message, _, _, _}:
      IO.print("missing-main-parse-failed: " ++ message)

def executable_main_result(result: Checked.CheckResult):
  match result:
    case Checked.CheckSuccess{program}:
      match BackendLower.lower(program):
        case BackendLower.Lowered{_}: IO.print("executable-main-accepted")
        case BackendLower.LowerFailure{_, _}: IO.print("executable-main-rejected")
    case Checked.CheckFailure{Checked.Diagnostic{_, _, message, _, _}}:
      IO.print("executable-main-check-failed: " ++ message)

def executable_main(parsed: Parser.ParseResult):
  match parsed:
    case Parser.ParseSuccess{module}:
      executable_main_result(Checker.check([Loader.LoadedModule{"", module}]))
    case Parser.ParseFailure{message, _, _, _}:
      IO.print("executable-main-parse-failed: " ++ message)

def inferred_main_result(result: Checked.CheckResult):
  match result:
    case Checked.CheckSuccess{program}:
      match BackendLower.lower(program):
        case BackendLower.Lowered{_}: IO.print("inferred-main-accepted")
        case BackendLower.LowerFailure{_, _}: IO.print("inferred-main-rejected")
    case Checked.CheckFailure{Checked.Diagnostic{_, _, message, _, _}}:
      IO.print("inferred-main-check-failed: " ++ message)

def inferred_main(parsed: Parser.ParseResult):
  match parsed:
    case Parser.ParseSuccess{module}:
      inferred_main_result(Checker.check([Loader.LoadedModule{"", module}]))
    case Parser.ParseFailure{message, _, _, _}:
      IO.print("inferred-main-parse-failed: " ++ message)

def library_mainless_result(result: Checked.CheckResult):
  match result:
    case Checked.CheckSuccess{program}:
      match BackendLower.lower_library(program, []):
        case BackendLower.Lowered{_}: IO.print("library-mainless-accepted")
        case BackendLower.LowerFailure{_, _}: IO.print("library-mainless-rejected")
    case Checked.CheckFailure{Checked.Diagnostic{_, _, message, _, _}}:
      IO.print("library-mainless-check-failed: " ++ message)

def library_mainless(parsed: Parser.ParseResult):
  match parsed:
    case Parser.ParseSuccess{module}:
      library_mainless_result(Checker.check([Loader.LoadedModule{"", module}]))
    case Parser.ParseFailure{message, _, _, _}:
      IO.print("library-mainless-parse-failed: " ++ message)

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    missing_main(Parser.parse("missing-main.bend", mainless_source()))
    executable_main(Parser.parse("executable.bend", executable_source()))
    inferred_main(Parser.parse("inferred.bend", inferred_source()))
    library_mainless(Parser.parse("library.bend", mainless_source()))

#| missing-main-rejected
#| executable-main-accepted
#| inferred-main-accepted
#| library-mainless-accepted
