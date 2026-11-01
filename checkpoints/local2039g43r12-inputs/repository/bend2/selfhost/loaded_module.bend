import Base
import ./ast.bend as Ast

type LoadedModule is Data:
  LoadedModule{namespace: String, module: Ast.Module}
