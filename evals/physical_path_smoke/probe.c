static Term phys_probe_run(Env e, Term* f, IoWork* w) {
  (void)w;
  Term r0 = ({
Term pbt = (((Term)f[0])); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; pbr = ((u64)(u32)(e.mem[pbn + 0]));
pbr;
});
  Term r1 = ({
Term pbt = (((Term)f[0])); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; pbr = ((u64)(u32)(e.mem[pbn + 1]));
pbr;
});
  if (r0 != 3 || r1 != 4) { err_fail("phys_probe: pair projection mismatch"); }
  u64 static_loc = term_peek(e.mem, f[1]);
  Term static_before = e.mem[static_loc];
  Term static_field = ({
Term pbt = (((Term)f[1])); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; if (term_triv(pbt)) { { Term pbb = term_keep(e, e.mem[pbn + 0], 1); if (pbb != e.mem[pbn + 0]) { if (!(!term_triv(pbt) && !(term_rfc(pbt) && (a32_load(a32_at(e.mem, term_loc(pbt))) & RFC_CNT) > 1))) { (void)err_fail("a shared node has an unsealed field"); } e.mem[pbn + 0] = pbb; } pbr = pbb; }
 } else { if (!(!term_triv(pbt) && !(term_rfc(pbt) && (a32_load(a32_at(e.mem, term_loc(pbt))) & RFC_CNT) > 1))) { (void)err_fail("a shared node cannot give away a field"); } pbr = e.mem[pbn + 0]; e.mem[pbn + 0] = 0;
 } pbr;
});
  if (e.mem[static_loc] != static_before) { err_fail("phys_probe: static transfer mutated the image"); }
  if (static_field != static_before) { err_fail("phys_probe: static copy changed the word"); }
  u64 child_loc = heap_alloc(e, cls_fit(1));
  e.mem[child_loc] = 7;
  Term child = term_ctr(CID(BoxS), child_loc);
  u64 ploc = heap_alloc(e, cls_fit(1));
  e.mem[ploc] = child;
  Term parent = term_ctr(CID(BoxS), ploc);
  Term moved = ({
Term pbt = (parent); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; if (term_triv(pbt)) { { Term pbb = term_keep(e, e.mem[pbn + 0], 1); if (pbb != e.mem[pbn + 0]) { if (!(!term_triv(pbt) && !(term_rfc(pbt) && (a32_load(a32_at(e.mem, term_loc(pbt))) & RFC_CNT) > 1))) { (void)err_fail("a shared node has an unsealed field"); } e.mem[pbn + 0] = pbb; } pbr = pbb; }
 } else { if (!(!term_triv(pbt) && !(term_rfc(pbt) && (a32_load(a32_at(e.mem, term_loc(pbt))) & RFC_CNT) > 1))) { (void)err_fail("a shared node cannot give away a field"); } pbr = e.mem[pbn + 0]; e.mem[pbn + 0] = 0;
 } pbr;
});
  if (moved != child) { err_fail("phys_probe: unique detach did not return the child"); }
  if (e.mem[ploc] != 0) { err_fail("phys_probe: unique detach kept the slot"); }
  term_sink(e, child);
  term_sink(e, parent);
  u64 child2_loc = heap_alloc(e, cls_fit(1));
  e.mem[child2_loc] = 8;
  Term child2 = rfc_seal(e, term_ctr(CID(BoxS), child2_loc));
  u64 ploc2 = heap_alloc(e, cls_fit(1));
  e.mem[ploc2] = child2;
  Term parent2 = term_ctr(CID(BoxS), ploc2);
  Term shared = term_keep(e, parent2, 1);
  u32 shared_before = a32_load(a32_at(e.mem, term_loc(child2))) & RFC_CNT;
  Term shared_field = ({
Term pbt = (shared); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; if (term_triv(pbt) || !(!term_triv(pbt) && !(term_rfc(pbt) && (a32_load(a32_at(e.mem, term_loc(pbt))) & RFC_CNT) > 1))) { { Term pbb = term_keep(e, e.mem[pbn + 0], 1); if (pbb != e.mem[pbn + 0]) { if (!(!term_triv(pbt) && !(term_rfc(pbt) && (a32_load(a32_at(e.mem, term_loc(pbt))) & RFC_CNT) > 1))) { (void)err_fail("a shared node has an unsealed field"); } e.mem[pbn + 0] = pbb; } pbr = pbb; }
 } else { pbr = e.mem[pbn + 0]; e.mem[pbn + 0] = 0;
 } pbr;
});
  if (e.mem[ploc2] != child2) { err_fail("phys_probe: shared consume changed the sealed word"); }
  u32 shared_after = a32_load(a32_at(e.mem, term_loc(child2))) & RFC_CNT;
  if (shared_after <= shared_before) { err_fail("phys_probe: shared consume did not take a reference"); }
  if (shared_field != child2) { err_fail("phys_probe: shared consume returned another word"); }
  term_sink(e, shared_field);
  term_sink(e, shared);
  term_sink(e, parent2);
  Term flv = ({
Term pbt = (((Term)f[2])); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; if (term_triv(pbt)) { { Term pbbuf[1];   pbbuf[0] = e.mem[pbn + 4];
u32 pbi = 0; Term pbl = 0; ({
Term pblcr = 0;
u64 pblcw[1]; for (u32 pblcji = 0; pblcji < 1; pblcji += 1) { pblcw[pblcji] = 0; } u32 pblcj = 0;
u64 pblcx0f0w = ((0 != 0) ? e.mem[0 + pbi] : (u64)pbbuf[pbi]); pbi += 1;
pblcw[pblcj] = pblcx0f0w; pblcj += 1;
pblcr = term_pak(2u, (u64)pblcw[0]);
pbl = pblcr;
pbl;
}); pbr = pbl; }
 } else { if (!(!term_triv(pbt) && !(term_rfc(pbt) && (a32_load(a32_at(e.mem, term_loc(pbt))) & RFC_CNT) > 1))) { (void)err_fail("a shared node cannot give away a field"); } { Term pbbuf[1];   pbbuf[0] = e.mem[pbn + 4];
u32 pbi = 0; Term pbl = 0; ({
Term pblcr = 0;
u64 pblcw[1]; for (u32 pblcji = 0; pblcji < 1; pblcji += 1) { pblcw[pblcji] = 0; } u32 pblcj = 0;
u64 pblcx0f0w = ((0 != 0) ? e.mem[0 + pbi] : (u64)pbbuf[pbi]); pbi += 1;
pblcw[pblcj] = pblcx0f0w; pblcj += 1;
pblcr = term_pak(2u, (u64)pblcw[0]);
pbl = pblcr;
pbl;
}); pbr = pbl; }
 } pbr;
});
  if (term_tag(flv) != TAG_PAK || term_peek(e.mem, flv) != 5) { err_fail("phys_probe: seg detach lost Fl"); }
  Term unitv = ({
Term pbt = (((Term)f[1])); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; pbr = term_pak(5u, 0);
pbr;
});
  if (term_tag(unitv) != TAG_PAK) { err_fail("phys_probe: zero-word copy lost Unit"); }
  return 1;
}

static void __attribute__((constructor)) phys_probe_use(void) {
  io_eff(CID(probe), phys_probe_run);
}
