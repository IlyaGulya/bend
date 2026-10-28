import Base
import ./ast.bend as AST
import ./backend_ir.bend as BIR

# Reading a declared target source is the one step every target's IO adapter
# shares: open, size, read, close, and report the exact path on failure. This
# module owns no selection policy, no extension test and no render decision: a
# target adapter hands it the BIR-declared paths, and it returns passive
# BIR.SourceFile values, so a missing file is a compile diagnostic naming its
# declared path rather than a derived alternative or an undefined read.
#
# Kernel shape rules this module follows, because the alternative is rejected:
# a `do` block holds binds and one final term, so every decision after a bind is
# delegated to a helper whose body is a match; a handle op answers the handle
# outside its Result, so each tuple destructures in the helper receiving it; a
# value reused in more than one place is marked `+`; each callee is defined
# before its caller; and a self-call must consume a syntactic tail.
type SourceResult is Data:
  SourceSuccess{source: String}
  SourceFailure{message: String}

type LoadResult is Data:
  LoadSuccess{files: List<&2, BIR.SourceFile>}
  LoadFailure{message: String, span: AST.SourceSpan}

# One declared alternative, read into exactly that path. The span travels with
# the plan so a read failure is reported at the declaration that named it.
type PlannedFile is Data:
  PlannedFile{path: String, span: AST.SourceSpan}

# A plan or read failure is inert: the caller reports the message at the span
# that named the path. Keeping it here means every adapter fails the same way.
def failed(message: String, span: AST.SourceSpan) -> IO(LoadResult):
  IO.pure(LoadResult, LoadFailure{message, span})

def read_source_closed(file: File, source: String) -> IO(SourceResult):
  do IO<SourceResult>:
    Unit <- File.close(file)
    return SourceSuccess{source}

# The prefix says which step failed; the path and code are the read's own.
def read_source_closed_failure(path: String, file: File, prefix: String, code: U32, message: String) -> IO(SourceResult):
  do IO<SourceResult>:
    Unit <- File.close(file)
    return SourceFailure{String.concat([prefix, path, ": ", U32.show(code), " ", message])}

# A tuple destructure is one product match, so the handle and its Result are
# case-bound fields: the Result stays a legal scrutinee of the next match.
def read_source_loaded(+path: String, loaded: File & Result<&1, &1, (U32 & String), String>) -> IO(SourceResult):
  (file, read_result) = loaded
  match read_result:
    case Done{source}: read_source_closed(file, source)
    case Fail{error}:
      (code, message) = error
      read_source_closed_failure(path, file, "cannot read ", code, message)

def read_source_read(+path: String, file: File, size: U32) -> IO(SourceResult):
  do IO<SourceResult>:
    loaded : File & Result<&1, &1, (U32 & String), String> <- File.read(file, size)
    read_source_loaded(path, loaded)

def read_source_sized(+path: String, sized: File & Result<&1, &1, (U32 & String), U32>) -> IO(SourceResult):
  (file, size_result) = sized
  match size_result:
    case Done{size}: read_source_read(path, file, size)
    case Fail{error}:
      (code, message) = error
      read_source_closed_failure(path, file, "cannot size ", code, message)

def read_source_size(+path: String, file: File) -> IO(SourceResult):
  do IO<SourceResult>:
    sized : File & Result<&1, &1, (U32 & String), U32> <- File.size(file)
    read_source_sized(path, sized)

def read_source_opened(+path: String, opened: Result<&1, &1, (U32 & String), File>) -> IO(SourceResult):
  match opened:
    case Done{file}: read_source_size(path, file)
    case Fail{error}:
      (code, message) = error
      IO.pure(SourceResult, SourceFailure{String.concat(["cannot open ", path, ": ", U32.show(code), " ", message])})

def read_source(+path: String) -> IO(SourceResult):
  do IO<SourceResult>:
    opened : Result<&1, &1, (U32 & String), File> <- File.open(path, "r")
    read_source_opened(path, opened)

# The continuation is affine: it is applied only for a successful read, so a
# failure stops the walk before any later planned path is opened, sized or read.
# The failure keeps the declaration span that named the path.
def read_result(span: AST.SourceSpan, next: String -> IO(LoadResult), read: SourceResult) -> IO(LoadResult):
  match read:
    case SourceFailure{message}: IO.pure(LoadResult, LoadFailure{message, span})
    case SourceSuccess{source}: next(source)

def read_one(path: String, span: AST.SourceSpan, next: String -> IO(LoadResult)) -> IO(LoadResult):
  do IO<LoadResult>:
    read : SourceResult <- read_source(path)
    read_result(span, next, read)

# Exactly the planned paths, in plan order, stopping at the first failure: no
# directory scan, no fallback, and no file the caller did not receive as a BIR
# fact. The self-call consumes the plan tail inside the continuation, which is
# the shape this kernel accepts as both a decreasing recursion and a fail-fast
# sequence.
def read_files(planned: List<&2, PlannedFile>, loaded: List<&2, BIR.SourceFile>) -> IO(LoadResult):
  match planned:
    case Nil{}: IO.pure(LoadResult, LoadSuccess{List.reverse(&2, BIR.SourceFile, loaded)})
    case +item <> rest:
      match item:
        case PlannedFile{+path, span}:
          read_one(path, span, source => read_files(rest, BIR.SourceFile{path, source} <> loaded))
