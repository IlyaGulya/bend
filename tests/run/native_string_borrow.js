io_eff(CID(heap.check), (value, expected) => {
  if (value !== expected) {
    throw new Error("unexpected native string result");
  }
  return 0;
});
