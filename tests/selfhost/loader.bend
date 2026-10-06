import Base
import ../../bend2/selfhost/loader.bend as Loader
import ../../bend2/selfhost/ast.bend as Ast
import ../../bend2/selfhost/loaded_module.bend as Modules

def put(path: String, source: String) -> IO(Unit):
  do IO<Unit>:
    file : File <- IO.try(File, File.open(path, "w"))
    written : File & Result<&1, &1, U32 & String, Unit> <- File.write(file, source)
    (file, result) = written
    Unit <- IO.pass(Unit, result)
    File.close(file)

def module_rows(modules: List<&2, Modules.LoadedModule>) -> List<&2, String>:
  match modules:
    case +loaded <> rest:
      match loaded:
        case Modules.LoadedModule{namespace,  Ast.Module{path,  _,  _}}:
          (namespace ++ "|" ++ path) <> module_rows(rest)
    case Nil{}: Nil{}

def show_loaded(result: Loader.LoadResult) -> IO(Unit):
  match result:
    case Loader.LoadSuccess{modules}:
      IO.print(String.join(module_rows(modules), "\n"))
    case Loader.LoadFailure{ _,  _, message,  _,  _}:
      IO.print("unexpected failure: " ++ message)

def show_failure(result: Loader.LoadResult, expected: String) -> IO(Unit):
  match result:
    case Loader.LoadSuccess{ _}:
      IO.print("unexpected success")
    case Loader.LoadFailure{ _,  _, message,  _,  _}:
      IO.print(Bool.pick(String, String.eq(message, expected), "failure-ok", "wrong failure: " ++ message))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- put("/tmp/bend_selfhost_loader_base.bend", "def base() -> Type : Type\n")
    Unit <- put("/tmp/bend_selfhost_loader_shared.bend", "def shared() -> Type : Type\n")
    Unit <- put("/tmp/bend_selfhost_loader_child.bend", "import \"../tmp/bend_selfhost_loader_shared.bend\" as Shared\ndef child() -> Type : Type\n")
    Unit <- put("/tmp/bend_selfhost_loader_root.bend", "import Base\nimport \"./bend_selfhost_loader_child.bend\" as Child\nimport \"./bend_selfhost_loader_child.bend\" as Alternate\nimport Base\ndef root() -> Type : Type\n")
    loaded : Loader.LoadResult <- Loader.load("/tmp/bend_selfhost_loader_base.bend", "/tmp/bend_selfhost_loader_root.bend")
    Unit <- show_loaded(loaded)
    Unit <- put("/tmp/bend_selfhost_loader_cycle_a.bend", "import \"./bend_selfhost_loader_cycle_b.bend\" as B\ndef a() -> Type : Type\n")
    Unit <- put("/tmp/bend_selfhost_loader_cycle_b.bend", "import \"./bend_selfhost_loader_cycle_a.bend\" as A\ndef b() -> Type : Type\n")
    cycle : Loader.LoadResult <- Loader.load("/tmp/bend_selfhost_loader_base.bend", "/tmp/bend_selfhost_loader_cycle_a.bend")
    Unit <- show_failure(cycle, "import cycle detected")
    Unit <- put("/tmp/bend_selfhost_loader_missing_root.bend", "import \"./bend_selfhost_loader_absent.bend\" as Absent\ndef root() -> Type : Type\n")
    missing : Loader.LoadResult <- Loader.load("/tmp/bend_selfhost_loader_base.bend", "/tmp/bend_selfhost_loader_missing_root.bend")
    Unit <- show_failure(missing, "unable to read source file")
    Unit <- put("/tmp/bend_selfhost_loader_conflict_root.bend", "import \"./bend_selfhost_loader_shared.bend\" as First\nimport \"/tmp/bend_selfhost_loader_shared.bend\" as Second\ndef root() -> Type : Type\n")
    conflict : Loader.LoadResult <- Loader.load("/tmp/bend_selfhost_loader_base.bend", "/tmp/bend_selfhost_loader_conflict_root.bend")
    Unit <- show_failure(conflict, "module imported into conflicting namespaces")
    Unit <- put("/tmp/bend_selfhost_loader_package_root.bend", "import \"0x0123456789abcdef0123456789abcdef/pkg.bend\" as P\ndef root() -> Type : Type\n")
    package : Loader.LoadResult <- Loader.load("/tmp/bend_selfhost_loader_base.bend", "/tmp/bend_selfhost_loader_package_root.bend")
    Unit <- show_failure(package, "cached package manifest is unavailable; remote fetching requires an HTTP effect")
    read_error : Loader.LoadResult <- Loader.load("/tmp/bend_selfhost_loader_base.bend", "/tmp")
    show_failure(read_error, "unable to read source file")

#||/tmp/bend_selfhost_loader_base.bend
#|../tmp/bend_selfhost_loader_shared|/tmp/bend_selfhost_loader_shared.bend
#|bend_selfhost_loader_child|/tmp/bend_selfhost_loader_child.bend
#||/tmp/bend_selfhost_loader_root.bend
#|failure-ok
#|failure-ok
#|failure-ok
#|failure-ok
#|failure-ok
