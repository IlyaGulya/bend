// JS control for the same source: values only, no heap frontier to pin.
io_eff(CID(heap.check), (value, expected) => {
  if (value !== expected) {
    throw new Error("unexpected ownership result");
  }
  return 0;
});
