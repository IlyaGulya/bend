io_eff(CID(dispose), (f) => {
  if (typeof f !== "function") {
    throw new Error("expected a retained compiler word closure");
  }
  return 5;
});
