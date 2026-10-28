/* The retained-page invariant of tests/run/list_rebox_sum.c, byte-for-byte
   the same bound: H_BUMP is the arena frontier in pages of 128 u64 (1 KiB);
   a QUANTUM is 4096 words (32 pages); a program that releases what it
   consumes advances the frontier by at most one QUANTUM between two
   readings. f[2] == 0 is the warm-up reading, which skips the comparison. */
static Term own_cons_heap_run(Env e, Term* f, IoWork* w) {
  if (f[0] != f[1]) {
    err_fail("unexpected ownership result");
  }
  u32 pages = a32_load(a32_at(e.mem, H_BUMP));
  if (f[2] && pages > f[2] + (QUANTUM >> PAGE_BITS)) {
    err_fail("minimal ownership retains heap pages");
  }
  return (Term)pages;
}

static void __attribute__((constructor)) own_cons_heap_use(void) {
  io_eff(CID(heap.check), own_cons_heap_run);
}
