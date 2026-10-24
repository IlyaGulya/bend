import Base
import ./ast.bend as Ast
import ./backend_ir.bend as BIR
import ./js_backend.bend as JSBackend

# The JavaScript target's IO adapter, the twin of c_emit's plan/load: the
# renderer selects the declared .js alternative of every foreign definition and
# stays pure, and this module reads exactly those bytes and hands them back as
# value. A missing file is a compile diagnostic that names the declared path,
# never an undefined module read or a derived alternative.
type LoadResult is Data:
  LoadSuccess{files: List<&2, JSBackend.SourceFile>}
  LoadFailure{message: String, span: Ast.SourceSpan}
type SourceResult is Data:
  SourceSuccess{source: String}
  SourceFailure{message: String}

def read_source(path: String) -> IO(SourceResult):
  do IO<SourceResult>:
    opened : Result<&1, &1, U32 & String, File> <- File.open(path, "r")
    match opened:
      case Done{file}:
        sized : File & Result<&1, &1, U32 & String, U32> <- File.size(file)
        (file, size_result) = sized
        match size_result:
          case Done{size}:
            loaded : File & Result<&1, &1, U32 & String, String> <- File.read(file, size)
            (file, read_result) = loaded
            match read_result:
              case Done{source}:
                Unit <- File.close(file)
                return SourceSuccess{source}
              case Fail{error}:
                (code, message) = error
                Unit <- File.close(file)
                return SourceFailure{String.concat(["cannot read ", path, ": ", U32.show(code), " ", message])}
          case Fail{error}:
            (code, message) = error
            Unit <- File.close(file)
            return SourceFailure{String.concat(["cannot size ", path, ": ", U32.show(code), " ", message])}
      case Fail{error}:
        (code, message) = error
        return SourceFailure{String.concat(["cannot open ", path, ": ", U32.show(code), " ", message])}

def load_sources(links: List<&2, JSBackend.LinkSource>, loaded: List<&2, JSBackend.SourceFile>) -> IO(LoadResult):
  match links:
    case Nil{}: IO.pure(LoadResult, LoadSuccess{List.reverse(&2, JSBackend.SourceFile, loaded)})
    case +link <> rest:
      match link:
        case JSBackend.LinkSource{path, namespace, span}:
          do IO<LoadResult>:
            read : SourceResult <- read_source(path)
            match read:
              case SourceFailure{message}: return LoadFailure{message, span}
              case SourceSuccess{source}:
                return load_sources(rest, JSBackend.SourceFile{path, source} <> loaded)

def load_links(links: JSBackend.LinkResult) -> IO(LoadResult):
  match links:
    case JSBackend.LinkFailure{message, span}: IO.pure(LoadResult, LoadFailure{message, span})
    case JSBackend.LinkSuccess{sources}: load_sources(sources, Nil{})

# Selection and loading share one list: the renderer can never splice a file
# this adapter did not read.
def load(program: BIR.Program) -> IO(LoadResult):
  load_links(JSBackend.link(program))
