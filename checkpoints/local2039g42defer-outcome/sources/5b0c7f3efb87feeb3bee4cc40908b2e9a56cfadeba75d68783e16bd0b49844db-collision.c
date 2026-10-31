
static Term collision_run(Env e, Term* f, IoWork* w) {
  if (FID(a.b) == FID(a_b)) err_fail("colliding function IDs");
  return f[0];
}
static void __attribute__((constructor)) collision_use(void) {
  io_eff(CID(check.ids), collision_run);
}
