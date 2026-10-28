# Private-region scalarization regression fixture.
#
# Every shape below is ordinary source: a root match (which the typed CPS
# factors into a private match helper invoked by a bare handler body). The
# helper's captures are ordered after its scrutinee while the handler's
# parameters are not, so the parameter-identical root-match contraction cannot
# absorb it; only the general private-region pass can. The chain across two
# source calls and the same-name scalar alias (`copy = value`) exercise
# continuation capture and copy scalarization. The generator must inline the
# match helper into its single caller, remove the alias, keep matches before
# locals and keep the public request handlers unchanged. Expected 9.
import Base
import ../bend2/selfhost/loaded_module.bend as Loader

type RegionSmoke is Data:
  RegionSmoke{bits: String}

def choose(extra: U32, value: U32) -> U32:
  match value:
    case 0: U32.add(extra, 7)
    case 1: U32.add(extra, 9)
    case _: U32.add(value, extra)

def forward(value: U32) -> U32:
  alias = U32.add(value, 1)
  U32.add(alias, 1)

def through(value: U32) -> U32:
  copy = value
  choose(copy, 3)

def main(modules: List<&2, Loader.LoadedModule>) -> RegionSmoke:
  RegionSmoke{U32.show(forward(through(4)))}
