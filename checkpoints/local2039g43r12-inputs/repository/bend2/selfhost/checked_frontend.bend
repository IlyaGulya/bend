import Base
import ./ast.bend as Ast
import ./checker_arena.bend as Arena
import ./checker_ir.bend as IR
import ./scope_lookup.bend as Scope
import ./loaded_module.bend as Loader

type Diagnostic is Data:
  Diagnostic{file: String, span: Ast.SourceSpan, message: String, expected: String, observed: String}

type FamilyMetadata is Data:
  FamilyMetadata{key: String, quantity_prefix: Nat}
type ModuleMetadata is Data:
  ModuleMetadata{namespace: String, path: String, scope: Scope.ArenaGlobalScope, families: List<&2, FamilyMetadata>}

# Success transfers the only source owner. All semantic handles reachable from
# modules, occurrence facts and signatures are published before transient rewind.
type CheckedProgram is Type:
  CheckedProgram{source: Arena.Arena, modules: List<&2, IR.LoadedModule>, signatures: List<&2, Scope.ArenaGlobal>, metadata: List<&2, ModuleMetadata>}
type CheckResult is Type:
  CheckSuccess{program: CheckedProgram}
  CheckFailure{diagnostic: Diagnostic}
type Inspection is Type:
  Inspection{program: CheckedProgram, modules: List<&2, Loader.LoadedModule>}
  InspectionFailure{program: CheckedProgram, diagnostic: Diagnostic}

def read_node_result(modules: List<&2, IR.LoadedModule>, signatures: List<&2, Scope.ArenaGlobal>, metadata: List<&2, ModuleMetadata>, result: Arena.Arena & Arena.Node) -> CheckedProgram & Arena.Node:
  match result:
    case Tuple{source, node}: (CheckedProgram{source, modules, signatures, metadata}, node)

def read_node(program: CheckedProgram, id: U32) -> CheckedProgram & Arena.Node:
  match program:
    case CheckedProgram{source, modules, signatures, metadata}:
      read_node_result(modules, signatures, metadata, Arena.get_node(source, id))
