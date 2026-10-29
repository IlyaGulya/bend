io_eff(CID(dispose), (f) => {
  if (typeof f !== "function") {
    throw new Error("expected a retained compiler row closure");
  }
  return 5;
});
