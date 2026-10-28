/* Same retained-page invariant and threshold as tests/run/list_rebox_sum.c;
   only the diagnostic string names this shape. H_BUMP is the arena frontier
   in pages of 128 u64; one QUANTUM is 4096 words (32 pages). */
static Term own_rebox_heap_run(Env e, Term* f, IoWork* w) {
  if (f[0] != f[1]) {
    err_fail("unexpected ownership result");
  }
  u32 pages = a32_load(a32_at(e.mem, H_BUMP));
  if (f[2] && pages > f[2] + (QUANTUM >> PAGE_BITS)) {
    err_fail("rebox rebuild retains heap pages");
  }
  return (Term)pages;
}

static void __attribute__((constructor)) own_rebox_heap_use(void) {
  io_eff(CID(heap.check), own_rebox_heap_run);
}
