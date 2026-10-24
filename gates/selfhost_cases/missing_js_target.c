// The C twin of a foreign effect whose JavaScript target is deliberately
// absent; the C lane must still compile and run.
Term native_value_run(Env e, Term* f, IoWork* w) {
  return (Term)(uint32_t)42;
}

static void __attribute__((constructor)) native_value_use(void) {
  io_eff(CID(native.value), native_value_run);
}
