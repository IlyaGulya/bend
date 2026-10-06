import Base
import ./ast.bend as Ast
import ./parser.bend as Parser
import ./path.bend as Path
import ./sha256.bend as SHA256
import ./loaded_module.bend as Modules

type LoadResult is Data:
  LoadSuccess{modules: List<&2, Modules.LoadedModule>}
  LoadFailure{file: String, span: Ast.SourceSpan, message: String, expected: String, observed: String}

type ReadResult is Data:
  ReadSuccess{source: String}
  ReadFailure{message: String}

type Assignment is Data:
  Assignment{path: String, namespace: String}

type WorkResult is Data:
  WorkSuccess{modules: List<&2, Modules.LoadedModule>, assignments: List<&2, Assignment>}
  WorkFailure{failure: LoadResult}

type WorkItem is Data:
  FileItem{path: String, namespace: String, import_span: Ast.SourceSpan, stack: List<&2, String>}
  ImportsItem{module: Ast.Module, namespace: String, imports: List<&2, Ast.ModuleImport>, stack: List<&2, String>}
  FinishItem{module: Ast.Module, namespace: String}
  AssignmentItem{found: Maybe<&2, String>, resolved: String, child_namespace: String, source_file: String, span: Ast.SourceSpan, stack: List<&2, String>, continuation: WorkItem, pending: List<&2, WorkItem>}
  NamespaceItem{equal: Bool, resolved: String, child_namespace: String, previous_namespace: String, source_file: String, span: Ast.SourceSpan, stack: List<&2, String>, continuation: WorkItem, pending: List<&2, WorkItem>}
  ExistingItem{exists: Bool, resolved: String, child_namespace: String, span: Ast.SourceSpan, stack: List<&2, String>, continuation: WorkItem, pending: List<&2, WorkItem>}
  CycleItem{cyclic: Bool, path: String, namespace: String, import_span: Ast.SourceSpan, stack: List<&2, String>, pending: List<&2, WorkItem>}
  FileExistsItem{exists: Bool, path: String, namespace: String, import_span: Ast.SourceSpan, stack: List<&2, String>, pending: List<&2, WorkItem>}
  ParsedItem{parsed: Parser.ParseResult, path: String, namespace: String, import_span: Ast.SourceSpan, stack: List<&2, String>, pending: List<&2, WorkItem>}
type PackageEntry is Data:
  PackageEntry{hash: String, path: String}

type ManifestResult is Data:
  ManifestSuccess{entries: List<&2, PackageEntry>}
  ManifestFailure{observed: String}
type ManifestStage is Data:
  ManifestStart{}
  ManifestPending{empty: Bool, trimmed: String, fields: List<&2, String>}

type PackageCheck is Data:
  PackageCheckSuccess{}
  PackageCheckFailure{message: String, observed: String}
type PackageStage is Data:
  PackageStart{}
  PackagePending{safe: Bool, valid: Bool, hash: String, path: String}

type ImportResolution is Data:
  ImportTarget{path: String, namespace: String}
  ImportFailure{message: String, expected: String, observed: String}

type LibraryResult is Data:
  LibrarySuccess{path: String}
  LibraryFailure{observed: String}

def failure(file: String, span: Ast.SourceSpan, message: String, expected: String, observed: String) -> LoadResult:
  LoadFailure{file, span, message, expected, observed}

def file_span(file: String) -> Ast.SourceSpan:
  Ast.SpanOf{file,  0n,  0n}

def read_file(path: String) -> IO(ReadResult):
  do IO<ReadResult>:
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
                return ReadSuccess{source}
              case Fail{error}:
                (code, message) = error
                Unit <- File.close(file)
                return ReadFailure{ U32.show(code) ++ " " ++ message}
          case Fail{error}:
            (code, message) = error
            Unit <- File.close(file)
            return ReadFailure{ U32.show(code) ++ " " ++ message}
      case Fail{error}:
        (code, message) = error
        return ReadFailure{ U32.show(code) ++ " " ++ message}

def package_library() -> IO(LibraryResult):
  do IO<LibraryResult>:
    configured : Result<&1, &1, U32 & String, String> <- IO.get_env("BEND_LIB")
    match configured:
      case Done{value}:
        return LibrarySuccess{ Path.normalize(value)}
      case Fail{ _}:
        home_result : Result<&1, &1, U32 & String, String> <- IO.get_env("HOME")
        match home_result:
          case Done{value}:
            return LibrarySuccess{ Path.normalize(value ++ "/.bend/lib")}
          case Fail{error}:
            (code, message) = error
            return LibraryFailure{ U32.show(code) ++ " " ++ message}

def parse_manifest_lines(lines: List<&2, String>, entries: List<&2, PackageEntry>, stage: ManifestStage) -> ManifestResult:
  match lines stage:
    case Nil{} ManifestStart{}:
      ManifestSuccess{ List.reverse(&2, PackageEntry, entries)}
    case Nil{} ManifestPending{empty, trimmed, fields}:
      match empty:
        case True{}:
          ManifestSuccess{ List.reverse(&2, PackageEntry, entries)}
        case False{}:
          match fields:
            case +hash <> +path <> Nil{}:
              ManifestSuccess{ List.reverse(&2, PackageEntry{hash, path} <> entries)}
            case _:
              ManifestFailure{ trimmed}
    case +line <> rest ManifestStart{}:
      trimmed = String.trim(line)
      parse_manifest_lines(rest, entries, ManifestPending{String.is_empty(trimmed), trimmed, String.split(trimmed, ' ')})
    case +line <> rest ManifestPending{empty, trimmed, fields}:
      match empty:
        case True{}:
          next_trimmed = String.trim(line)
          parse_manifest_lines(rest, entries, ManifestPending{String.is_empty(next_trimmed), next_trimmed, String.split(next_trimmed, ' ')})
        case False{}:
          match fields:
            case +hash <> +path <> Nil{}:
              next_trimmed = String.trim(line)
              parse_manifest_lines(rest, PackageEntry{hash, path} <> entries, ManifestPending{String.is_empty(next_trimmed), next_trimmed, String.split(next_trimmed, ' ')})
            case _:
              ManifestFailure{ trimmed}

def manifest_has_path(path: String, entries: List<&2, PackageEntry>, found: Bool) -> Bool:
  match entries found:
    case _ True{}: True{}
    case Nil{} False{}: False{}
    case +entry <> rest False{}:
      match entry:
        case PackageEntry{ _,  entry_path}:
          manifest_has_path(path, rest, String.eq(path, entry_path))
def package_source_hash_matches(matches: Bool, path: String) -> PackageCheck:
  match matches:
    case False{}:
      PackageCheckFailure{ "cached package source hash mismatch",  path}
    case True{}:
      PackageCheckSuccess{}

def package_entry_check(root: String, safe: Bool, valid: Bool, hash: String, path: String) -> IO(PackageCheck):
  do IO<PackageCheck>:
    match safe valid:
      case False{} _:
        return PackageCheckFailure{ "unsafe path in cached package manifest",  path}
      case True{} False{}:
        return PackageCheckFailure{ "invalid source hash in cached package manifest",  hash}
      case True{} True{}:
        source_path = Path.normalize(root ++ "/" ++ path)
        source_result : ReadResult <- read_file(source_path)
        match source_result:
          case ReadFailure{message}:
            return PackageCheckFailure{ "cached package source is missing; remote fetching requires an HTTP effect",  path ++ ": " ++ message}
          case ReadSuccess{source}:
            digest = SHA256.hash(source)
            return package_source_hash_matches(String.starts_with(digest, hash), path)

def package_entry_stage(entry: PackageEntry) -> PackageStage:
  match entry:
    case PackageEntry{hash, path}:
      absolute_path = String.append("/", path)
      PackagePending{String.eq(Path.normalize(absolute_path), absolute_path), String.length(hash) >= 32n, hash, path}

def verify_package_entries(root: String, entries: List<&2, PackageEntry>, stage: PackageStage) -> IO(PackageCheck):
  do IO<PackageCheck>:
    match entries stage:
      case Nil{} PackageStart{}:
        return PackageCheckSuccess{}
      case Nil{} PackagePending{safe, valid, hash, path}:
        checked : PackageCheck <- package_entry_check(root, safe, valid, hash, path)
        return checked
      case +entry <> rest PackageStart{}:
        verify_package_entries(root, rest, package_entry_stage(entry))
      case +entry <> rest PackagePending{safe, valid, hash, path}:
        checked : PackageCheck <- package_entry_check(root, safe, valid, hash, path)
        match checked:
          case PackageCheckFailure{message, observed}:
            return PackageCheckFailure{message, observed}
          case PackageCheckSuccess{}:
            verify_package_entries(root, rest, package_entry_stage(entry))



def resolve_package_manifest_entries(listed: Bool, parent_namespace: String, import_path: String, root: String, relative_path: String, entries: List<&2, PackageEntry>) -> IO(ImportResolution):
  do IO<ImportResolution>:
    match listed:
      case False{}:
        return ImportFailure{ "requested file is not listed in the cached package manifest",  "a manifest entry for the imported path",  relative_path}
      case True{}:
        checked : PackageCheck <- verify_package_entries(root, entries, PackageStart{})
        match checked:
          case PackageCheckFailure{message, observed}:
            return ImportFailure{message,  "a cached package with verified source hashes", observed}
          case PackageCheckSuccess{}:
            file = Path.normalize(root ++ "/" ++ relative_path)
            return ImportTarget{ file,  Path.namespace(parent_namespace, import_path)}

def resolve_parsed_manifest(parsed: ManifestResult, parent_namespace: String, import_path: String, root: String, relative_path: String) -> IO(ImportResolution):
  do IO<ImportResolution>:
    match parsed:
      case ManifestFailure{observed}:
        return ImportFailure{ "malformed cached package manifest",  "hash and relative path per line", observed}
      case ManifestSuccess{entries}:
        resolve_package_manifest_entries(manifest_has_path(relative_path, entries, False{}), parent_namespace, import_path, root, relative_path, entries)

def resolve_package_manifest_hash(matches: Bool, parent_namespace: String, import_path: String, root: String, relative_path: String, package_hash: String, digest: String, manifest: String) -> IO(ImportResolution):
  do IO<ImportResolution>:
    match matches:
      case False{}:
        return ImportFailure{ "cached package manifest hash mismatch",  package_hash,  digest}
      case True{}:
        resolve_parsed_manifest(parse_manifest(manifest), parent_namespace, import_path, root, relative_path)

def resolve_package_hash_length(long_enough: Bool, parent_namespace: String, import_path: String, root: String, relative_path: String, package_hash: String, digest: String, manifest: String) -> IO(ImportResolution):
  do IO<ImportResolution>:
    match long_enough:
      case False{}:
        return ImportFailure{ "package hash prefix is too short",  "at least 32 hexadecimal characters",  package_hash}
      case True{}:
        resolve_package_manifest_hash(String.starts_with(digest, package_hash), parent_namespace, import_path, root, relative_path, package_hash, digest, manifest)

def resolve_package_parts(parts: List<&2, String>, parent_namespace: String, import_path: String) -> IO(ImportResolution):
  do IO<ImportResolution>:
    match parts:
      case +package <> relative_parts:
        relative_path = String.join(relative_parts, '/')
        library_result : LibraryResult <- package_library()
        match library_result:
          case LibraryFailure{observed}:
            return ImportFailure{ "cached package lookup requires BEND_LIB or HOME",  "a package cache directory", observed}
          case LibrarySuccess{ library}:
            root = Path.normalize(library ++ "/" ++ package)
            manifest_path = Path.normalize(root ++ "/manifest")
            manifest_result : ReadResult <- read_file(manifest_path)
            match manifest_result:
              case ReadFailure{message}:
                return ImportFailure{ "cached package manifest is unavailable; remote fetching requires an HTTP effect",  "a cached, verified package manifest",  message}
              case ReadSuccess{manifest}:
                package_hash = String.drop(package, 2n)
                digest = SHA256.hash(manifest)
                resolve_package_hash_length(String.length(package_hash) >= 32n, parent_namespace, import_path, root, relative_path, package_hash, digest, manifest)
      case Nil{}:
        return ImportFailure{ "malformed package path",  "0x<hash>/<path>",  import_path}

def resolve_package(parent_namespace: String, import_path: String) -> IO(ImportResolution):
  resolve_package_parts(String.split(import_path, '/'), parent_namespace, import_path)
def resolve_import_base(is_base: Bool, base_file: String, parent_namespace: String, source_file: String, import_path: String) -> IO(ImportResolution):
  do IO<ImportResolution>:
    match is_base:
      case True{}:
        return ImportTarget{ base_file,  Path.namespace(parent_namespace, import_path)}
      case False{}:
        resolved_path = Path.resolve(source_file, import_path)
        return ImportTarget{ resolved_path,  Path.namespace(parent_namespace, import_path)}

def resolve_import_package(is_package: Bool, base_file: String, parent_namespace: String, source_file: String, import_path: String) -> IO(ImportResolution):
  do IO<ImportResolution>:
    match is_package:
      case True{}:
        resolved : ImportResolution <- resolve_package(parent_namespace, import_path)
        return resolved
      case False{}:
        resolve_import_base(String.eq(import_path, "Base"), base_file, parent_namespace, source_file, import_path)

def resolve_import(base_file: String, parent_namespace: String, source_file: String, import_path: String) -> IO(ImportResolution):
  resolve_import_package(Path.package_path(import_path), base_file, parent_namespace, source_file, import_path)

def find_assignment(path: String, assignments: List<&2, Assignment>, matches: Bool, namespace: String) -> Maybe<&2, String>:
  match assignments matches:
    case _ True{}: Some{namespace}
    case Nil{} False{}: None{}
    case +entry <> rest False{}:
      match entry:
        case Assignment{ found, found_namespace}:
          find_assignment(path, rest, String.eq(path, found), found_namespace)

def has_module(path: String, modules: List<&2, Modules.LoadedModule>, matches: Bool) -> Bool:
  match modules matches:
    case _ True{}: True{}
    case Nil{} False{}: False{}
    case +loaded <> rest False{}:
      match loaded:
        case Modules.LoadedModule{ _,  Ast.Module{ found,  _,  _}}:
          has_module(path, rest, String.eq(path, found))

def in_stack(path: String, stack: List<&2, String>, matches: Bool) -> Bool:
  match stack matches:
    case _ True{}: True{}
    case Nil{} False{}: False{}
    case +found <> rest False{}:
      in_stack(path, rest, String.eq(path, found))

def add_assignment(assignments: List<&2, Assignment>, path: String, namespace: String) -> List<&2, Assignment>:
  Assignment{path, namespace} <> assignments

def append_module(modules: List<&2, Modules.LoadedModule>, namespace: String, module: Ast.Module) -> List<&2, Modules.LoadedModule>:
  List.append(&2, Modules.LoadedModule, modules, [Modules.LoadedModule{namespace, module}])

# Work is a finite graph discovered through IO; its task queue is not a source list.
@unsafe
def load_work(base_file: String, work: List<&2, WorkItem>, assignments: List<&2, Assignment>, modules: List<&2, Modules.LoadedModule>) -> IO(WorkResult):
  do IO<WorkResult>:
    match work:
      case Nil{}:
        return WorkSuccess{modules, assignments}
      case +item <> rest:
        match item:
          case FinishItem{module, namespace}:
            load_work(base_file, rest, assignments, append_module(modules, namespace, module))
          case ImportsItem{module, namespace, imports, stack}:
            match imports:
              case Nil{}:
                load_work(base_file, rest, assignments, modules)
              case +item <> remaining:
                match item:
                  case Ast.ModuleImport{import_path, _, span}:
                    source_file = match span:
                      case Ast.SpanOf{file, _, _}: file
                    resolution : ImportResolution <- resolve_import(base_file, namespace, source_file, import_path)
                    match resolution:
                      case ImportFailure{message, expected, observed}:
                        return WorkFailure{failure(source_file, span, message, expected, observed)}
                      case ImportTarget{resolved, child_namespace}:
                        continuation = ImportsItem{module, namespace, remaining, stack}
                        lookup = AssignmentItem{find_assignment(resolved, assignments, False{}, ""), resolved, child_namespace, source_file, span, stack, continuation, rest}
                        load_work(base_file, lookup <> Nil{}, assignments, modules)
          case AssignmentItem{found, resolved, child_namespace, source_file, span, stack, continuation, pending}:
            match found:
              case Some{previous_namespace}:
                namespace_check = NamespaceItem{String.eq(child_namespace, previous_namespace), resolved, child_namespace, previous_namespace, source_file, span, stack, continuation, pending}
                load_work(base_file, namespace_check <> Nil{}, assignments, modules)
              case None{}:
                next_assignments = add_assignment(assignments, resolved, child_namespace)
                load_work(base_file, FileItem{resolved, child_namespace, span, stack} <> continuation <> pending, next_assignments, modules)
          case NamespaceItem{equal, resolved, child_namespace, previous_namespace, source_file, span, stack, continuation, pending}:
            match equal:
              case False{}:
                return WorkFailure{failure(source_file, span, "one file imported into conflicting namespaces", previous_namespace, child_namespace)}
              case True{}:
                exists = ExistingItem{has_module(resolved, modules, False{}), resolved, child_namespace, span, stack, continuation, pending}
                load_work(base_file, exists <> Nil{}, assignments, modules)
          case ExistingItem{exists, resolved, child_namespace, span, stack, continuation, pending}:
            match exists:
              case True{}:
                load_work(base_file, continuation <> pending, assignments, modules)
              case False{}:
                load_work(base_file, FileItem{resolved, child_namespace, span, stack} <> continuation <> pending, assignments, modules)
          case FileItem{path, namespace, import_span, stack}:
            cycle = CycleItem{in_stack(path, stack, False{}), path, namespace, import_span, stack, rest}
            load_work(base_file, cycle <> Nil{}, assignments, modules)
          case CycleItem{cyclic, path, namespace, import_span, stack, pending}:
            match cyclic:
              case True{}:
                return WorkFailure{failure(path, import_span, "import cycle detected", "an acyclic module graph", path)}
              case False{}:
                exists = FileExistsItem{has_module(path, modules, False{}), path, namespace, import_span, stack, pending}
                load_work(base_file, exists <> Nil{}, assignments, modules)
          case FileExistsItem{exists, path, namespace, import_span, stack, pending}:
            match exists:
              case True{}:
                load_work(base_file, pending, assignments, modules)
              case False{}:
                read_result : ReadResult <- read_file(path)
                match read_result:
                  case ReadFailure{message}:
                    return WorkFailure{failure(path, import_span, "unable to read source file", "readable UTF-8 source", message)}
                  case ReadSuccess{source}:
                    parsed = ParsedItem{Parser.parse(path, source), path, namespace, import_span, stack, pending}
                    load_work(base_file, parsed <> Nil{}, assignments, modules)
          case ParsedItem{parsed, path, namespace, import_span, stack, pending}:
            match parsed:
              case Parser.ParseFailure{message, expected, observed, span}:
                return WorkFailure{failure(path, span, message, expected, observed)}
              case Parser.ParseSuccess{module}:
                imports = ImportsItem{module, namespace, module.imports, path <> stack}
                finish = FinishItem{module, namespace}
                load_work(base_file, imports <> finish <> pending, assignments, modules)
def load_file(base_file: String, path: String, namespace: String, import_span: Ast.SourceSpan, stack: List<&2, String>, assignments: List<&2, Assignment>, modules: List<&2, Modules.LoadedModule>) -> IO(WorkResult):
  load_work(base_file, [FileItem{path, namespace, import_span, stack}], assignments, modules)





def load(base_file: String, root_file: String) -> IO(LoadResult):
  base = Path.normalize(base_file)
  root = Path.normalize(root_file)
  do IO<LoadResult>:
    result : WorkResult <- load_file(base, root, "", file_span(root), Nil{}, Nil{}, Nil{})
    match result:
      case WorkSuccess{modules,  _}:
        return LoadSuccess{modules}
      case WorkFailure{ failure}:
        return failure
