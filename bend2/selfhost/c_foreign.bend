import Base
import ./ast.bend as Ast
import ./loaded_module.bend as Loader
import ./path.bend as Path

type ForeignDefinition is Data:
  ForeignDefinition{namespace: String, key: String, full_key: String, binders: List<&2, Ast.TelescopeItem>, result: Ast.OptionalTerm, source_path: String, source: String}

type LoadResult is Data:
  LoadSuccess{definitions: List<&2, ForeignDefinition>}
  LoadFailure{file: String, span: Ast.SourceSpan, message: String}

type SourceResult is Data:
  SourceSuccess{source: String}
  SourceFailure{message: String}

type CachedSource is Data:
  CachedSource{path: String, source: String}

type ScanResult is Data:
  ScanSuccess{definitions: List<&2, ForeignDefinition>, sources: List<&2, CachedSource>}
  ScanFailure{failure: LoadResult}

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
                return SourceFailure{ "unable to read C import: " ++ U32.show(code) ++ " " ++ message}
          case Fail{error}:
            (code, message) = error
            Unit <- File.close(file)
            return SourceFailure{ "unable to size C import: " ++ U32.show(code) ++ " " ++ message}
      case Fail{error}:
        (code, message) = error
        return SourceFailure{ "unable to open C import: " ++ U32.show(code) ++ " " ++ message}

def source_matches(equal: Bool, path: String, source: String, rest: List<&2, CachedSource>) -> Maybe<&2, String>:
  match equal:
    case True{}: Some{source}
    case False{}: find_source(path, rest)

def find_source(path: String, sources: List<&2, CachedSource>) -> Maybe<&2, String>:
  match sources:
    case +entry <> rest:
      match entry:
        case CachedSource{ known, source}:
          source_matches(String.eq(path, known), path, source, rest)
    case Nil{}: None{}

def foreign_key_empty(empty: Bool, namespace: String, key: String) -> String:
  match empty:
    case True{}: key
    case False{}: namespace ++ "." ++ key

def foreign_key(namespace: String, key: String) -> String:
  foreign_key_empty(String.is_empty(namespace), namespace, key)

def find_c_import_suffix(is_c: Bool, path: String, rest: List<&2, String>) -> Maybe<&2, String>:
  match is_c:
    case True{}: Some{path}
    case False{}: find_c_import(rest)

def find_c_import(paths: List<&2, String>) -> Maybe<&2, String>:
  match paths:
    case +path <> rest:
      find_c_import_suffix(String.ends_with(path, ".c"), path, rest)
    case Nil{}: None{}

def foreign_definition(namespace: String, module_path: String, definition: Ast.Definition, paths: List<&2, String>, sources: List<&2, CachedSource>, definitions: List<&2, ForeignDefinition>) -> IO(ScanResult):
  foreign_import_lookup(find_c_import(paths), namespace, module_path, definition, sources, definitions)

def foreign_import_lookup(found: Maybe<&2, String>, namespace: String, module_path: String, definition: Ast.Definition, sources: List<&2, CachedSource>, definitions: List<&2, ForeignDefinition>) -> IO(ScanResult):
  do IO<ScanResult>:
    match found:
      case None{}:
        match definition:
          case Ast.Definition{ _,  _,  _,  _,  _, span}:
            return ScanFailure{ LoadFailure{ module_path, span,  "foreign definition has no .c import"}}
      case Some{relative_path}:
        source_path = Path.resolve(module_path, relative_path)
        foreign_source_lookup(find_source(source_path, sources), namespace, module_path, definition, source_path, sources, definitions)

def foreign_source_lookup(found: Maybe<&2, String>, namespace: String, module_path: String, definition: Ast.Definition, source_path: String, sources: List<&2, CachedSource>, definitions: List<&2, ForeignDefinition>) -> IO(ScanResult):
  do IO<ScanResult>:
    match found:
      case Some{source}:
        match definition:
          case Ast.Definition{key, binders, result,  _,  _,  _}:
            foreign = ForeignDefinition{namespace, key,  foreign_key(namespace, key), binders, result, source_path, source}
            return ScanSuccess{ foreign <> definitions, sources}
      case None{}:
        loaded : SourceResult <- read_source(source_path)
        match loaded:
          case SourceFailure{message}:
            match definition:
              case Ast.Definition{ _,  _,  _,  _,  _, span}:
                return ScanFailure{ LoadFailure{ module_path, span, message}}
          case SourceSuccess{source}:
            match definition:
              case Ast.Definition{key, binders, result,  _,  _,  _}:
                foreign = ForeignDefinition{namespace, key,  foreign_key(namespace, key), binders, result, source_path, source}
                return ScanSuccess{ foreign <> definitions,  CachedSource{source_path, source} <> sources}

def scan_declarations(namespace: String, module_path: String, declarations: List<&2, Ast.TopLevel>, sources: List<&2, CachedSource>, definitions: List<&2, ForeignDefinition>) -> IO(ScanResult):
  do IO<ScanResult>:
    match declarations:
      case +declaration <> rest:
        match declaration:
          case Ast.DefTop{definition}:
            match definition:
              case Ast.Definition{ _,  _,  _,  Ast.DefImports{paths},  _,  _}:
                found : ScanResult <- foreign_definition(namespace, module_path, definition, paths, sources, definitions)
                match found:
                  case ScanFailure{failure}: return ScanFailure{failure}
                  case ScanSuccess{ next_definitions,  next_sources}:
                    next : ScanResult <- scan_declarations(namespace, module_path, rest, next_sources, next_definitions)
                    return next
              case _:
                next : ScanResult <- scan_declarations(namespace, module_path, rest, sources, definitions)
                return next
          case _:
            next : ScanResult <- scan_declarations(namespace, module_path, rest, sources, definitions)
            return next
      case Nil{}:
        return ScanSuccess{definitions, sources}

def scan_modules(modules: List<&2, Loader.LoadedModule>, sources: List<&2, CachedSource>, definitions: List<&2, ForeignDefinition>) -> IO(ScanResult):
  do IO<ScanResult>:
    match modules:
      case +loaded <> rest:
        match loaded:
          case Loader.LoadedModule{namespace,  Ast.Module{path,  _, declarations}}:
            scanned : ScanResult <- scan_declarations(namespace, path, declarations, sources, definitions)
            match scanned:
              case ScanFailure{failure}: return ScanFailure{failure}
              case ScanSuccess{ next_definitions,  next_sources}:
                next : ScanResult <- scan_modules(rest, next_sources, next_definitions)
                return next
      case Nil{}:
        return ScanSuccess{definitions, sources}

def load(modules: List<&2, Loader.LoadedModule>) -> IO(LoadResult):
  do IO<LoadResult>:
    scanned : ScanResult <- scan_modules(modules, Nil{}, Nil{})
    match scanned:
      case ScanFailure{failure}: return failure
      case ScanSuccess{definitions,  _}:
        return LoadSuccess{ List.reverse(&2, ForeignDefinition, definitions)}
