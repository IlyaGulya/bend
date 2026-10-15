import Base
import ../../bend2/selfhost/path.bend as Path

law main:
  IO(Unit)

def main():
  relative_ns = Path.namespace("", "./lib/child.bend")
  parent_ns = Path.namespace("dir/current", "../shared.bend")
  absolute_ns = Path.namespace("", "/tmp/base.bend")
  package_ns = Path.namespace("", "0xabc123/lib.bend")
  IO.print(String.join([Path.normalize("src/../lib/./x.bend"), Path.normalize("/a//../b"), Path.normalize("../../a"), Path.resolve("src/main.bend", "../lib/mod.bend"), Path.resolve("/tmp/bend/main.bend", "/pkg/x.bend"), Path.dirname("main.bend"), relative_ns, parent_ns, absolute_ns, package_ns], "\n"))


#|lib/x.bend
#|/b
#|../../a
#|lib/mod.bend
#|/pkg/x.bend
#|.
#|lib/child
#|shared
#|/tmp/base
#|0xabc123/lib