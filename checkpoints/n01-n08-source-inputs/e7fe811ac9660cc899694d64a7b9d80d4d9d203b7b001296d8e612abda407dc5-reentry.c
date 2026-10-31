/* Same supported effect callback ABI as tests/io/foreign_runtime_apply.c.
 * Each callback closure and argument transfers once into Clo~apply.
 * The outer IO continuation remains owned by IoWork, not by this callback.
 * This fixture intentionally has no recoverable-error/longjmp contract. */
static Term witness_reenter_run(Env e, Term* f, IoWork* w) {
  (void)w;
  puts("callback-before");
  u64 at = task_node(e, FID(Clo~apply), TERM_HOLE, 0, 0);
  e.mem[at] = f[0];
  e.mem[at + 1] = f[1];
  Term result = corpus_eval(e.mem, term_tsk(FID(Clo~apply), at));
  if (err_seen(e.mem)) err_fail("witness closure application failed");
  printf("nested-call:%u\n", (unsigned)(u32)result);
  puts("callback-after");
  return result;
}

static void __attribute__((constructor)) witness_reenter_use(void) {
  io_eff(CID(Host.reenter), witness_reenter_run);
}
