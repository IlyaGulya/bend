function host_probe(direct, first_class) {
  const payload = Object.create({host_prototype: 7});
  Object.defineProperty(payload, "$", {value: CID(JsMapValue), enumerable: true});
  Object.defineProperty(payload, "number", {get() {throw new Error("lookup inspected the stored value");}, enumerable: true});
  payload.extra = 19;
  const leaf = (key, value) => ({$: CID(MLeaf), key, val: value});
  const expect_some = (answer, value) => {
    if (answer.$ !== CID(Some) || answer.value !== value) {
      throw new Error("lookup changed the stored value identity");
    }
  };
  for (const lookup of [direct, first_class]) {
    let reads = "";
    const observed = {$: CID(MLeaf)};
    Object.defineProperties(observed, {
      key: {get() {reads += "k"; return "hit";}},
      val: {get() {reads += "v"; return payload;}},
      unused: {get() {throw new Error("lookup read an undeclared field");}},
    });
    expect_some(lookup(observed)("hit"), payload);
    if (reads !== "kv") throw new Error("leaf hit field order: " + reads);
    reads = "";
    if (lookup(observed)("miss").$ !== CID(None)) throw new Error("leaf miss is not None");
    if (reads !== "kv") throw new Error("leaf miss field order: " + reads);
    const wrong = leaf("hit", {});
    let high = wrong;
    const node = {$: CID(MNode)};
    Object.defineProperties(node, {
      pos: {get() {return 0;}},
      lo: {get() {high = leaf("hit", payload); return {$: CID(MTip)};}},
      hi: {get() {return high;}},
    });
    expect_some(lookup(node)("hit"), payload);
    const sentinel = new Error("leaf value getter");
    const throwing = {$: CID(MLeaf), key: "hit"};
    Object.defineProperty(throwing, "val", {get() {throw sentinel;}});
    let caught = false;
    try {lookup(throwing)("miss");} catch (error) {
      if (error !== sentinel) throw error;
      caught = true;
    }
    if (!caught) throw new Error("leaf miss skipped its value getter");
    expect_some(lookup(leaf("hit", payload))("hit"), payload);
  }
  if (Object.getPrototypeOf(payload).host_prototype !== 7 || Object.keys(payload).join(",") !== "$,number,extra") {
    throw new Error("lookup mutated the stored value");
  }
  return payload.extra;
}

io_eff(CID(Host.probe), host_probe);
