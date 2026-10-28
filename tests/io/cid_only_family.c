Term cid_only_sum_run(Env e, Term* f, IoWork* w) {
  Term pair = io_node(e, CID(CidOnlyPair), (Term)20, (Term)22);
  u64 at = term_peek(e.mem, pair);
  Term answer = e.mem[at] + e.mem[at + 1];
  term_drop(e, pair);
  return answer;
}

static void __attribute__((constructor)) cid_only_family_use(void) {
  io_eff(CID(cid_only_sum), cid_only_sum_run);
}
