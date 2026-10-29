static u32 rows_seen;
static u32 rows_pages;

static Term rows_dispose_run(Env e, Term* f, IoWork* w) {
  Term closure = f[0];
  if (term_tag(closure) != TAG_CLO || term_loc(closure) < HEAP_OFF
    || fid_arity(term_aux(closure)) != 2) {
    err_fail("expected a closure owning compiler rows");
  }
  Term capture = e.mem[term_loc(closure)];
  if (term_tag(capture) != TAG_ARR || term_loc(capture) < HEAP_OFF) {
    err_fail("expected an owned compiler row capture");
  }
  term_drop(e, closure);
  u32 pages = a32_load(a32_at(e.mem, H_BUMP));
  if (++rows_seen == 1024) {
    rows_pages = pages;
  }
  if (rows_seen > 1024 && pages > rows_pages + (QUANTUM >> PAGE_BITS)) {
    err_fail("compiler row disposal retains heap pages");
  }
  return (Term)5;
}

static void __attribute__((constructor)) rows_dispose_use(void) {
  io_eff(CID(dispose), rows_dispose_run);
}
