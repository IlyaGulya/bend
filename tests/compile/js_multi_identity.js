// A host record carries an extra own key, a private prototype, and read
// counters behind its live fields. Forwarding must retain its identity and
// avoid reading those fields; the host return protocol may inspect the tag.
function host_probe(f, g, h) {
  let field_reads = 0;
  let getter_reads = 0;
  const proto = {host_mark: 7};
  const gauge = {$: CID(JsMultiGauge), value: 21, tag: 3, extra: 5};
  const field = (name, value) => Object.defineProperty(gauge, name, {
    enumerable: true,
    configurable: true,
    get() {
      if (name !== "$") field_reads += 1;
      return value;
    },
  });
  field("$", CID(JsMultiGauge));
  field("value", 21);
  field("tag", 3);
  Object.defineProperty(gauge, "probe", {
    enumerable: true,
    configurable: true,
    get() {
      getter_reads += 1;
      return 1;
    },
  });
  Object.setPrototypeOf(gauge, proto);
  const keys = Object.keys(gauge).join(",");
  const first = f(gauge);
  if (first !== gauge) {
    throw new Error("roundtrip did not return the host object");
  }
  const second = g(gauge);
  if (second !== gauge) {
    throw new Error("pass did not return the host object");
  }
  if (field_reads !== 0) {
    throw new Error("forwarding read a host field");
  }
  if (getter_reads !== 0) {
    throw new Error("forwarding read the host getter");
  }
  if (Object.getPrototypeOf(gauge) !== proto) {
    throw new Error("forwarding changed the prototype");
  }
  if (Object.keys(gauge).join(",") !== keys) {
    throw new Error("forwarding changed the own keys");
  }
  if (gauge.extra !== 5) {
    throw new Error("forwarding lost the extra key");
  }
  const value = h(gauge);
  if (value !== 213) {
    throw new Error("live fields read as " + value);
  }
  if (getter_reads !== 0) {
    throw new Error("destructuring read the host getter");
  }
  return value;
}

io_eff(CID(Host.probe), host_probe);
