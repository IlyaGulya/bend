// The JavaScript twin of a foreign effect whose C target is deliberately
// absent; the .js lane must still compile and run.
function native_value() {
  return 42;
}

io_eff(CID(native.value), native_value);
