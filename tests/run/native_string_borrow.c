/* Same H_BUMP frontier invariant as list_rebox_sum: one 4096-word
   QUANTUM, or 32 one-KiB pages, may be acquired after warm-up. */
static Term native_string_heap_run(Env e, Term* f, IoWork* w) {
  if (f[0] != f[1]) {
    err_fail("unexpected native string result");
  }
  u32 pages = a32_load(a32_at(e.mem, H_BUMP));
  if (f[2] && pages > f[2] + (QUANTUM >> PAGE_BITS)) {
    err_fail("borrowed native string retains heap pages");
  }
  return (Term)pages;
}

static void __attribute__((constructor)) native_string_heap_use(void) {
  io_eff(CID(heap.check), native_string_heap_run);
}
