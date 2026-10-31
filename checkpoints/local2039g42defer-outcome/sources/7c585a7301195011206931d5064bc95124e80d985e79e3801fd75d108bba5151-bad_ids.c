
static Term bad_ids_run(Env e, Term* f, IoWork* w) { return f[0]; }
static void __attribute__((constructor)) bad_ids_use(void) {
  io_eff(CID(no_such_effect), bad_ids_run);
}
