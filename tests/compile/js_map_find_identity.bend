# Native Map.find must preserve host field observation order and return the
# stored value itself, without inspecting that value's fields.
import Base

type JsMapValue is Data:
  JsMapValue{number: U32}

def lookup(+map: Map<&2, JsMapValue>, +key: String) -> Maybe<&2, JsMapValue>:
  Map.find(JsMapValue, map, key)

def Host.probe(direct: @+map: Map<&2, JsMapValue> -> @+key: String -> Maybe<&2, JsMapValue>,
  first_class: @+map: Map<&2, JsMapValue> -> @+key: String -> Maybe<&2, JsMapValue>) -> IO(U32):
  import "./js_map_find_identity.js"

def main() -> IO(Unit):
  do IO<Unit>:
    result : U32 <- Host.probe(map => key => lookup(map, key), Map.find(JsMapValue))
    IO.print(U32.show(result))

#|19
