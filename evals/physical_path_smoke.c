static Term bend_fail(Env e, const char* m) { (void)e; err_fail(m); return 0; }
static Term bend_bool(Env e, u32 t, u32 f, u64 c) { (void)e; return term_pak(c != 0 ? t : f, 0); }
static Term phys_view_probe_run(Env e, Term* f, IoWork* w) {
  (void)w;
  Term pair_value = (Term)f[0];
  Term box_value = (Term)f[1];
  Term seg_value = (Term)f[2];
  Term av[1]; av[0] = 7;
  Term arr_root = blk_new(e, false, 4, 0, 1, av);
  Term lv[1]; lv[0] = 9;
  Term arr_leaf = blk_new(e, false, 0, 0, 1, lv);
  Term box_child = e.mem[term_peek(e.mem, box_value) + 0];
  Term r0 = ({
Term pbt = (pair_value); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; pbr = ((u64)(u32)(e.mem[pbn + 0]));
pbr;
});
  Term r1 = ({
Term pbt = (pair_value); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; pbr = ((u64)(u32)(e.mem[pbn + 1]));
pbr;
});
  Term r2 = ({
Term pbt = (seg_value); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; u32 pbpred = 0; { pbpred = (1u == 1u);
 } pbr = bend_bool(e, 7u, 8u, pbpred);
pbr;
});
  Term r3 = ({
Term pbt = (seg_value); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; if (term_triv(pbt) || !(!term_triv(pbt) && !(term_rfc(pbt) && (a32_load(a32_at(e.mem, term_loc(pbt))) & RFC_CNT) > 1))) { pbr = ((u64)(u32)(e.mem[pbn + 0]));
 } else { pbr = ((u64)(u32)(e.mem[pbn + 0]));
 } pbr;
});
  Term r4 = ({
Term pbt = (seg_value); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; if (term_triv(pbt) || !(!term_triv(pbt) && !(term_rfc(pbt) && (a32_load(a32_at(e.mem, term_loc(pbt))) & RFC_CNT) > 1))) { { Term pbbuf[1]; pbbuf[0] = e.mem[pbn + 4];
u32 pbi = 0; Term pbl = 0; ({
Term pblcr = 0;
u64 pblcw[1]; for (u32 pblcji = 0; pblcji < 1; pblcji += 1) { pblcw[pblcji] = 0; } u32 pblcj = 0;
u64 pblcx0f0w = ((0 != 0) ? e.mem[0 + pbi] : (u64)pbbuf[pbi]); pbi += 1;
pblcw[pblcj] = pblcx0f0w; pblcj += 1;
pblcr = term_pak(2u, (u64)pblcw[0]);
pbl = pblcr;
pbl;
}); pbr = pbl; }
 } else { { Term pbbuf[1]; pbbuf[0] = e.mem[pbn + 4];
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
  Term r5 = ({
Term pbt = (box_value); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; if (term_triv(pbt) || !(!term_triv(pbt) && !(term_rfc(pbt) && (a32_load(a32_at(e.mem, term_loc(pbt))) & RFC_CNT) > 1))) { { Term pbb = term_keep(e, e.mem[pbn + 0], 1); if (pbb != e.mem[pbn + 0]) { if (term_triv(pbt)) { (void)bend_fail(e, "a static image would need a keep wrapper"); } else if (!(!term_triv(pbt) && !(term_rfc(pbt) && (a32_load(a32_at(e.mem, term_loc(pbt))) & RFC_CNT) > 1))) { (void)bend_fail(e, "a shared owner has an unsealed field"); } else { e.mem[pbn + 0] = pbb; } } pbr = pbb; }
 } else { pbr = e.mem[pbn + 0]; e.mem[pbn + 0] = 0;
 } pbr;
});
  Term r6 = ({
Term pbt = (box_value); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; pbr = term_pak(5u, 0);
pbr;
});
  Term r7 = ({
Term pbt = (arr_root); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; if ((term_tag(pbt) == TAG_ARR)) { pbr = term_blk(true, (u32)(((((u32)blk_cls(pbt))) - 1)), (u64)((u64)(blk_loc(e.mem, pbt)) + (u64)((u64)((0) + 0)))); } else { u64 pboff = (u64)((u64)((0) + 0)); if ((pboff & 1ull) != 0ull) { (void)bend_fail(e, "a mid-block BUF cell has no Term view; a consumer must read it through blk_read"); } pbr = term_blk(false, (u32)(((((u32)blk_cls(pbt))) - 1)), (u64)((u64)(blk_loc(e.mem, pbt)) + (pboff >> 1))); }
pbr;
});
  Term r8 = ({
Term pbt = (arr_root); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; u64 pal = (u64)(blk_loc(e.mem, pbt)); u32 pac = (u32)(((((u32)blk_cls(pbt))) - 1)); bool paarr = (term_tag(pbt) == TAG_ARR); u64 pnl = 0;
if (paarr) { pnl = heap_alloc(e, blk_wcls(true, pac)); u64 pacount = (1ull << (pac - 0)); for (u64 pe = 0; pe < pacount; pe += 1) { u64 psrc = pal + ((u64)((0) + (1ull << ((((u32)blk_cls(pbt))) - 1)))) + (pe << 0); u64 pdst = pnl + (pe << 0); { Term pbbuf[1];     pbbuf[0] = e.mem[psrc + 0];
for (u64 pj = 0; pj < 1; pj += 1) { e.mem[pdst + pj] = pbbuf[pj]; } } } } else { pnl = heap_alloc(e, blk_wcls(false, pac)); u64 pacells = (1ull << pac); for (u64 pi = 0; pi < pacells; pi += 1) { blk_write(e.mem, false, pnl, (u32)pi, blk_read(e.mem, false, pal, (u32)(((u64)((0) + (1ull << ((((u32)blk_cls(pbt))) - 1)))) + pi))); } } pbr = term_blk(paarr, pac, pnl);
pbr;
});
  Term r9 = ({
Term pbt = (arr_leaf); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; if ((term_triv(pbt) || term_triv(pbt)) || !((!term_triv(pbt) && !(term_rfc(pbt) && (a32_load(a32_at(e.mem, term_loc(pbt))) & RFC_CNT) > 1)) && (!term_triv(pbt) && !(term_rfc(pbt) && (a32_load(a32_at(e.mem, term_loc(pbt))) & RFC_CNT) > 1)))) { pbr = ((u64)(u32)(blk_read(e.mem, (term_tag(pbt) == TAG_ARR), blk_loc(e.mem, pbt), (u32)(0))));
 } else { pbr = ((u64)(u32)(blk_read(e.mem, (term_tag(pbt) == TAG_ARR), blk_loc(e.mem, pbt), (u32)(0)))); blk_write(e.mem, (term_tag(pbt) == TAG_ARR), blk_loc(e.mem, pbt), (u32)(0), 0);
 } pbr;
});
  Term r10 = ({
Term pbt = (arr_root); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; pbr = bend_bool(e, 7u, 8u, ((u32)(((((u32)blk_cls(pbt))) - 1)) == 0u));
pbr;
});
  Term r11 = ({
Term pbt = (arr_root); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; pbr = bend_bool(e, 7u, 8u, ((u32)(((((u32)blk_cls(pbt))) - 1)) > 0u));
pbr;
});

  if ((u32)r0 != 3 || (u32)r1 != 4) { err_fail("view probe: Pair fields wrong"); }
  if (term_aux(r2) != 7u) { err_fail("view probe: Pt hastag is not canonical True"); }
  if ((u32)r3 != 1u) { err_fail("view probe: Seg inline Pt.x wrong"); }
  if (term_aux(r4) != 2u || term_peek(e.mem, r4) != 5u) { err_fail("view probe: Seg Fl wrong"); }
  if (r5 != box_child) { err_fail("view probe: BoxP consume lost the child"); }
  if (term_aux(r6) != 5u) { err_fail("view probe: Unit copy wrong"); }
  if (term_tag(r7) != TAG_BUF || (u32)blk_cls(r7) != 3 || blk_read(e.mem, false, blk_loc(e.mem, r7), 0) != 7) { err_fail("view probe: array low half Term view wrong"); }
  if (term_tag(r8) != TAG_BUF || (u32)blk_cls(r8) != 3) { err_fail("view probe: array high half copy shape wrong"); }
  for (u32 pi = 0; pi < 8; pi += 1) { if (blk_read(e.mem, false, blk_loc(e.mem, r8), pi) != 7) { err_fail("view probe: array high half copy cell wrong"); } }
  if (blk_read(e.mem, false, blk_loc(e.mem, arr_root), 15) != 7) { err_fail("view probe: array copy mutated the source"); }
  if ((u32)r9 != 9u || blk_read(e.mem, false, blk_loc(e.mem, arr_leaf), 0) != 0) { err_fail("view probe: array leaf consume wrong"); }
  if (term_aux(r10) != 8u || term_aux(r11) != 7u) { err_fail("view probe: array is_leaf/is_node not canonical Bool"); }
  term_sink(e, r2); term_sink(e, r4); term_sink(e, r5); term_sink(e, r6); term_sink(e, r7); term_sink(e, r8); term_sink(e, r10); term_sink(e, r11);
  return 1;
}
static void __attribute__((constructor)) phys_view_probe_use(void) { io_eff(CID(probe), phys_view_probe_run); }
