function host_adapter_probe(factory, identity) {
  let reads = 0;
  const proto = {host_mark: 7};
  const payload = Object.create(proto);
  Object.defineProperties(payload, {
    $: {value: CID(JsAdapterRecord), enumerable: true},
    value: {get() { reads++; return 91; }, enumerable: true},
    extra: {value: 5, enumerable: true},
  });
  const plain = n => n + 1;
  let nested;
  const reenter = n => {
    nested = factory(plain)(payload)(n + 10);
    return n + 1;
  };
  const first = factory(reenter)(payload)(7);
  let threw = false;
  try {
    factory(() => { throw new Error("adapter callback failure"); })(payload)(27);
  } catch (error) {
    threw = String(error).includes("adapter callback failure");
  }
  if (!threw) throw new Error("factory swallowed the callback failure");
  const second = factory(plain)(payload)(8);
  if (first === nested || first === second || nested === second)
    throw new Error("fresh results alias another call's result");
  for (const result of [first, nested, second]) {
    if (result.payload !== payload) throw new Error("factory replaced the host payload");
    if (Object.keys(result).join(",") !== "$,payload,value")
      throw new Error("factory changed result own keys");
    if (Object.getPrototypeOf(result) !== Object.prototype)
      throw new Error("factory changed result prototype");
  }
  if (reads !== 0 || Object.getPrototypeOf(payload) !== proto || payload.extra !== 5)
    throw new Error("factory inspected or changed the host payload");
  if (identity(first) !== first) throw new Error("identity replaced a retained result");
  if (first.value !== 8 || nested.value !== 18 || second.value !== 9)
    throw new Error("reentry or unwind overwrote a retained result");
  return first.value + nested.value + second.value;
}

io_eff(CID(Host.probe), host_adapter_probe);
