# A fresh result may contain an opaque host record without inspecting it.
# Host callbacks reenter the factory, throw, and retain earlier results.
import Base

type JsAdapterRecord is Data:
  JsAdapterRecord{value: U32}

type JsAdapterEnvelope is Data:
  JsAdapterEnvelope{payload: JsAdapterRecord, value: U32}

def build(read: U32 -> U32, payload: JsAdapterRecord, value: U32) -> JsAdapterEnvelope:
  JsAdapterEnvelope{payload, read(value)}

def forward(value: JsAdapterEnvelope) -> JsAdapterEnvelope:
  value

def Host.probe(factory: (U32 -> U32) -> JsAdapterRecord -> U32 -> JsAdapterEnvelope,
    identity: JsAdapterEnvelope -> JsAdapterEnvelope) -> IO(U32):
  import "./js_multi_boxed_adapter.js"

def main() -> IO(Unit):
  do IO<Unit>:
    value : U32 <- Host.probe(read => payload => n => build(read, payload, n),
      record => forward(record))
    IO.print(U32.show(value))

#|35
