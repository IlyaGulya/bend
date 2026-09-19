// Unit
// ====

// This module's spelling, from wherever the program sits, and Base's Unit is
// what EFFECTS.md lays from a user effect.
Term unit_make_run(Env e, Term* f, IoWork* w) {
  return term_pak(CID_UNIT, 0);
}

static void __attribute__((constructor)) unit_make_use(void) {
  io_eff(CID_UNIT_MAKE, unit_make_run, 0);
}
