import Base
import ./backend_ir.bend as BIR
import ./js_backend.bend as JSBackend
import ./target_io.bend as TargetIO

# The JavaScript target's IO adapter: the renderer selects the declared .js
# alternative of every foreign definition and stays pure, and this module reads
# exactly those bytes through target_io and hands them back as passive
# BIR.SourceFile values. Selection, namespace and span are BIR facts that
# js_backend.link derives, so nothing here invents a namespace, a derived path
# or a target spelling; a missing file is a compile diagnostic naming the
# declared path.
#
# Kernel shape rules: a match cannot scrutinize a computed value, so the pure
# link result is bound with IO.pure and matched as a parameter; and each callee
# is defined before its caller.
def planned(links: List<&2, JSBackend.LinkSource>, acc: List<&2, TargetIO.PlannedFile>) -> List<&2, TargetIO.PlannedFile>:
  match links:
    case Nil{}: List.reverse(&2, TargetIO.PlannedFile, acc)
    case +link <> rest:
      match link:
        case JSBackend.LinkSource{path, _, span}: planned(rest, TargetIO.PlannedFile{path, span} <> acc)

def load_links(links: JSBackend.LinkResult) -> IO(TargetIO.LoadResult):
  match links:
    case JSBackend.LinkFailure{message, span}: TargetIO.failed(message, span)
    case JSBackend.LinkSuccess{sources}: TargetIO.read_files(planned(sources, Nil{}), Nil{})

# Selection and loading share one list: the renderer can never splice a file
# this adapter did not read.
def load(program: BIR.Program) -> IO(TargetIO.LoadResult):
  do IO<TargetIO.LoadResult>:
    links : JSBackend.LinkResult <- IO.pure(JSBackend.LinkResult, JSBackend.link(program))
    load_links(links)
