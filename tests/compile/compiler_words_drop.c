static u32 words_seen;
static u32 words_pages;

static Term words_dispose_run(Env e, Term* f, IoWork* w) {
  Term closure = f[0];
  if (term_tag(closure) != TAG_CLO || term_loc(closure) < HEAP_OFF
    || fid_arity(term_aux(closure)) != 2) {
    err_fail("expected a closure owning compiler words");
  }
  Term capture = e.mem[term_loc(closure)];
  if (term_tag(capture) != TAG_BUF || term_loc(capture) < HEAP_OFF
    || blk_cls(capture) != 4) {
    err_fail("expected a packed compiler word capture");
  }
  term_drop(e, closure);
  u32 pages = a32_load(a32_at(e.mem, H_BUMP));
  if (++words_seen == 1024) {
    words_pages = pages;
  }
  if (words_seen > 1024 && pages > words_pages + (QUANTUM >> PAGE_BITS)) {
    err_fail("compiler word disposal retains heap pages");
  }
  return (Term)5;
}

static void __attribute__((constructor)) words_dispose_use(void) {
  io_eff(CID(dispose), words_dispose_run);
}
