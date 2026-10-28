# A record that crosses the host seam keeps the object it was
# given. The effect builds a host object with its own extra key, an own getter
# and a private prototype, then applies two closures that forward the same
# record and one that matches it. Each forwarder must return that object
# itself, without reading a field it did not already read; the matcher must
# still see the record's live fields.
import Base

type JsMultiGauge is Data:
  JsMultiGauge{value: U32, tag: U32}

def gauge_pass(c: JsMultiGauge) -> JsMultiGauge:
  c

def gauge_roundtrip(c: JsMultiGauge) -> JsMultiGauge:
  gauge_pass(c)

def gauge_read(c: JsMultiGauge) -> U32:
  match c:
    case JsMultiGauge{v, t}:
      U32.add(U32.mul(v, 10), t)

def Host.probe(f: JsMultiGauge -> JsMultiGauge,
    g: JsMultiGauge -> JsMultiGauge,
    h: JsMultiGauge -> U32) -> IO(U32):
  import "./js_multi_identity.js"

def main() -> IO(Unit):
  do IO<Unit>:
    v : U32 <- Host.probe(c => gauge_roundtrip(c), c => gauge_pass(c),
      c => gauge_read(c))
    IO.print(U32.show(v))

#|213
