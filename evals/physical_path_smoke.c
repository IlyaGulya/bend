static Term bend_fail(Env e, const char* m) { (void)e; err_fail(m); return 0; }
static Term bend_bool(Env e, u32 t, u32 f, u64 c) { (void)e; return term_pak(c != 0 ? t : f, 0); }
static Term bend_tuple(Env e, u32 tc, Term a, Term b) { u64 l = heap_alloc(e, cls_fit(2)); e.mem[l] = a; e.mem[l + 1] = b; return term_ctr(tc, l); }
static Term phys_view_probe_run(Env e, Term* f, IoWork* w) {
  (void)w;
  Term pair_value = (Term)f[0];
  Term box_value = (Term)f[1];
  Term seg_value = (Term)f[2];
  Term av[1]; av[0] = 7;
  Term arr_root = blk_new(e, false, 4, 0, 1, av);
  Term lv[1]; lv[0] = 9;
  Term arr_leaf = blk_new(e, false, 0, 0, 1, lv);
  Term lva[1]; lva[0] = 52;
  Term leafv = blk_new(e, false, 0, 0, 1, lva);
  Term lwb[1]; lwb[0] = 53;
  Term leafw = blk_new(e, false, 0, 0, 1, lwb);
  Term box_child = e.mem[term_peek(e.mem, box_value) + 0];
  u64 boxm_loc = heap_alloc(e, cls_fit(2));
  e.mem[boxm_loc + 0] = 0;
  e.mem[boxm_loc + 1] = 21;
  Term boxm_value = term_ctr(9, boxm_loc);
  u64 rect_loc = heap_alloc(e, cls_fit(2));
  e.mem[rect_loc + 0] = 22;
  e.mem[rect_loc + 1] = 23;
  Term rect_value = term_ctr(11, rect_loc);
  Term nv[1]; nv[0] = 41;
  Term nat_leaf = blk_new(e, false, 0, 0, 1, nv);
  Term wv[3]; wv[0] = 31; wv[1] = 32; wv[2] = 33;
  Term wide_leaf = blk_new(e, false, 0, 2, 3, wv);
  u64 shared_child_loc = heap_alloc(e, cls_fit(1));
  e.mem[shared_child_loc] = 99;
  Term shared_child = rfc_seal(e, term_ctr(12, shared_child_loc));
  u64 shared_loc = heap_alloc(e, cls_fit(1));
  e.mem[shared_loc] = shared_child;
  Term shared_parent = term_ctr(4, shared_loc);
  Term shared_value = term_keep(e, shared_parent, 1);
  u32 shared_before = a32_load(a32_at(e.mem, term_loc(shared_child))) & RFC_CNT;
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
  Term r12 = ({
Term pbt = (boxm_value); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; u32 pbpred = 0; { switch ((u32)e.mem[pbn + 0]) {
case 0: pbpred = (10u == 10u); break;
case 1: pbpred = (11u == 10u); break;
default: (void)bend_fail(e, "the constructor tag is not a declared constructor"); break;
}
 } pbr = bend_bool(e, 7u, 8u, pbpred);
pbr;
});
  Term r13 = ({
Term pbt = (boxm_value); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; if (term_triv(pbt) || !(!term_triv(pbt) && !(term_rfc(pbt) && (a32_load(a32_at(e.mem, term_loc(pbt))) & RFC_CNT) > 1))) { pbr = ((u64)(u32)(e.mem[pbn + 1]));
 } else { pbr = ((u64)(u32)(e.mem[pbn + 1]));
 } pbr;
});
  Term r14 = ({
Term pbt = (rect_value); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; if (term_triv(pbt) || !(!term_triv(pbt) && !(term_rfc(pbt) && (a32_load(a32_at(e.mem, term_loc(pbt))) & RFC_CNT) > 1))) { pbr = ((u64)(u32)(e.mem[pbn + 0]));
 } else { pbr = ((u64)(u32)(e.mem[pbn + 0]));
 } pbr;
});
  Term r15 = ({
Term pbt = (rect_value); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; if (term_triv(pbt) || !(!term_triv(pbt) && !(term_rfc(pbt) && (a32_load(a32_at(e.mem, term_loc(pbt))) & RFC_CNT) > 1))) { pbr = ((u64)(u32)(e.mem[pbn + 1]));
 } else { pbr = ((u64)(u32)(e.mem[pbn + 1]));
 } pbr;
});
  Term r16 = ({
Term pbt = (nat_leaf); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; if ((term_triv(pbt) || term_triv(pbt)) || !((!term_triv(pbt) && !(term_rfc(pbt) && (a32_load(a32_at(e.mem, term_loc(pbt))) & RFC_CNT) > 1)) && (!term_triv(pbt) && !(term_rfc(pbt) && (a32_load(a32_at(e.mem, term_loc(pbt))) & RFC_CNT) > 1)))) { pbr = (u64)(blk_read(e.mem, (term_tag(pbt) == TAG_ARR), blk_loc(e.mem, pbt), (u32)(0)));
 } else { pbr = (u64)(blk_read(e.mem, (term_tag(pbt) == TAG_ARR), blk_loc(e.mem, pbt), (u32)(0))); blk_write(e.mem, (term_tag(pbt) == TAG_ARR), blk_loc(e.mem, pbt), (u32)(0), 0);
 } pbr;
});
  Term r17 = ({
Term pbt = (wide_leaf); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; if ((term_triv(pbt) || term_triv(pbt)) || !((!term_triv(pbt) && !(term_rfc(pbt) && (a32_load(a32_at(e.mem, term_loc(pbt))) & RFC_CNT) > 1)) && (!term_triv(pbt) && !(term_rfc(pbt) && (a32_load(a32_at(e.mem, term_loc(pbt))) & RFC_CNT) > 1)))) { if ((term_tag(pbt) == TAG_ARR)) { { Term pbbuf[3]; pbbuf[0] = e.mem[blk_loc(e.mem, pbt) + (0) + 0];
pbbuf[1] = e.mem[blk_loc(e.mem, pbt) + (0) + 1];
pbbuf[2] = e.mem[blk_loc(e.mem, pbt) + (0) + 2];
u32 pbi = 0; Term pbl = 0; ({
Term pblcr = 0;
u64 pblcw[3]; for (u32 pblcji = 0; pblcji < 3; pblcji += 1) { pblcw[pblcji] = 0; } u32 pblcj = 0;
u64 pblcx0f0w = ((0 != 0) ? e.mem[0 + pbi] : (u64)pbbuf[pbi]); pbi += 1;
pblcw[pblcj] = pblcx0f0w; pblcj += 1;
u64 pblcx0f1w = ((0 != 0) ? e.mem[0 + pbi] : (u64)pbbuf[pbi]); pbi += 1;
pblcw[pblcj] = pblcx0f1w; pblcj += 1;
u64 pblcx0f2w = ((0 != 0) ? e.mem[0 + pbi] : (u64)pbbuf[pbi]); pbi += 1;
pblcw[pblcj] = pblcx0f2w; pblcj += 1;
u64 pblcl = heap_alloc(e, cls_fit(3)); for (u32 pblcli = 0; pblcli < 3; pblcli += 1) { e.mem[pblcl + pblcli] = pblcw[pblcli]; } pblcr = term_ctr(12u, pblcl);
pbl = pblcr;
pbl;
}); pbr = pbl; }
 } else { Term pbl = 0; u32 pbc = 0; Term pblc = 0; ({
Term pblcr = 0;
u64 pblcw[3]; for (u32 pblcji = 0; pblcji < 3; pblcji += 1) { pblcw[pblcji] = 0; } u32 pblcj = 0;
u64 pblcx0f0w = ((u64)blk_read(e.mem, false, blk_loc(e.mem, pbt), 0 + pbc)); pbc += 1;
pblcw[pblcj] = pblcx0f0w; pblcj += 1;
u64 pblcx0f1w = ((u64)blk_read(e.mem, false, blk_loc(e.mem, pbt), 0 + pbc)); pbc += 1;
pblcw[pblcj] = pblcx0f1w; pblcj += 1;
u64 pblcx0f2w = ((u64)blk_read(e.mem, false, blk_loc(e.mem, pbt), 0 + pbc)); pbc += 1;
pblcw[pblcj] = pblcx0f2w; pblcj += 1;
u64 pblcl = heap_alloc(e, cls_fit(3)); for (u32 pblcli = 0; pblcli < 3; pblcli += 1) { e.mem[pblcl + pblcli] = pblcw[pblcli]; } pblcr = term_ctr(12u, pblcl);
pbl = pblcr;
pbl;
});  pbr = pbl; }
 } else { if ((term_tag(pbt) == TAG_ARR)) { { Term pbbuf[3]; pbbuf[0] = e.mem[blk_loc(e.mem, pbt) + (0) + 0];
pbbuf[1] = e.mem[blk_loc(e.mem, pbt) + (0) + 1];
pbbuf[2] = e.mem[blk_loc(e.mem, pbt) + (0) + 2];
u32 pbi = 0; Term pbl = 0; ({
Term pblcr = 0;
u64 pblcw[3]; for (u32 pblcji = 0; pblcji < 3; pblcji += 1) { pblcw[pblcji] = 0; } u32 pblcj = 0;
u64 pblcx0f0w = ((0 != 0) ? e.mem[0 + pbi] : (u64)pbbuf[pbi]); pbi += 1;
pblcw[pblcj] = pblcx0f0w; pblcj += 1;
u64 pblcx0f1w = ((0 != 0) ? e.mem[0 + pbi] : (u64)pbbuf[pbi]); pbi += 1;
pblcw[pblcj] = pblcx0f1w; pblcj += 1;
u64 pblcx0f2w = ((0 != 0) ? e.mem[0 + pbi] : (u64)pbbuf[pbi]); pbi += 1;
pblcw[pblcj] = pblcx0f2w; pblcj += 1;
u64 pblcl = heap_alloc(e, cls_fit(3)); for (u32 pblcli = 0; pblcli < 3; pblcli += 1) { e.mem[pblcl + pblcli] = pblcw[pblcli]; } pblcr = term_ctr(12u, pblcl);
pbl = pblcr;
pbl;
}); pbr = pbl; }
 } else { Term pbl = 0; u32 pbc = 0; Term pblc = 0; ({
Term pblcr = 0;
u64 pblcw[3]; for (u32 pblcji = 0; pblcji < 3; pblcji += 1) { pblcw[pblcji] = 0; } u32 pblcj = 0;
u64 pblcx0f0w = ((u64)blk_read(e.mem, false, blk_loc(e.mem, pbt), 0 + pbc)); pbc += 1;
pblcw[pblcj] = pblcx0f0w; pblcj += 1;
u64 pblcx0f1w = ((u64)blk_read(e.mem, false, blk_loc(e.mem, pbt), 0 + pbc)); pbc += 1;
pblcw[pblcj] = pblcx0f1w; pblcj += 1;
u64 pblcx0f2w = ((u64)blk_read(e.mem, false, blk_loc(e.mem, pbt), 0 + pbc)); pbc += 1;
pblcw[pblcj] = pblcx0f2w; pblcj += 1;
u64 pblcl = heap_alloc(e, cls_fit(3)); for (u32 pblcli = 0; pblcli < 3; pblcli += 1) { e.mem[pblcl + pblcli] = pblcw[pblcli]; } pblcr = term_ctr(12u, pblcl);
pbl = pblcr;
pbl;
});       blk_write(e.mem, false, blk_loc(e.mem, pbt), (u32)((0) + 0ull), 0);
      blk_write(e.mem, false, blk_loc(e.mem, pbt), (u32)((0) + 1ull), 0);
      blk_write(e.mem, false, blk_loc(e.mem, pbt), (u32)((0) + 2ull), 0);
      blk_write(e.mem, false, blk_loc(e.mem, pbt), (u32)((0) + 3ull), 0);
 pbr = pbl; }
 } pbr;
});
  Term r18 = ({
Term pbt = (shared_value); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; if (term_triv(pbt) || !(!term_triv(pbt) && !(term_rfc(pbt) && (a32_load(a32_at(e.mem, term_loc(pbt))) & RFC_CNT) > 1))) { { Term pbb = term_keep(e, e.mem[pbn + 0], 1); if (pbb != e.mem[pbn + 0]) { if (term_triv(pbt)) { (void)bend_fail(e, "a static image would need a keep wrapper"); } else if (!(!term_triv(pbt) && !(term_rfc(pbt) && (a32_load(a32_at(e.mem, term_loc(pbt))) & RFC_CNT) > 1))) { (void)bend_fail(e, "a shared owner has an unsealed field"); } else { e.mem[pbn + 0] = pbb; } } pbr = pbb; }
 } else { pbr = e.mem[pbn + 0]; e.mem[pbn + 0] = 0;
 } pbr;
});
  Term r19 = ({
Term pbt = (seg_value); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; if (term_triv(pbt) || !(!term_triv(pbt) && !(term_rfc(pbt) && (a32_load(a32_at(e.mem, term_loc(pbt))) & RFC_CNT) > 1))) { pbr = ((u64)(u32)(e.mem[pbn + 2]));
 } else { pbr = ((u64)(u32)(e.mem[pbn + 2]));
 } pbr;
});
  Term r20 = ({
Term a0 = arr_root; Term i0 = 0; u64 l0 = blk_loc(e.mem, a0); u32 g0 = (u32)blk_at(a0, (u64)(u32)i0, 0); u32 c0 = 0; Term r0 = 0;
u64 agw = ((u64)blk_read(e.mem, false, l0, g0 + c0)); c0 += 1;
r0 = ((u64)(u32)(agw));
bend_tuple(e, 13u, a0, r0);
});
  Term r21 = ({
Term a0 = arr_root; Term i0 = 0; u64 l0 = blk_loc(e.mem, a0); u32 g0 = (u32)blk_at(a0, (u64)(u32)i0, 0); Term old0[1]; u32 c0 = 0;
old0[c0] = blk_read(e.mem, false, l0, g0 + c0); c0 += 1;
u64 w0[1]; for (u32 o0i = 0; o0i < 1; o0i += 1) { w0[o0i] = 0; } u32 o0 = 0;
u32 asc = 0;
w0[o0] = ((u64)(u32)((8))); o0 += 1;
asc += 1;
c0 = 0;
blk_write(e.mem, false, l0, g0 + c0, w0[c0]); c0 += 1;
c0 = 0;
c0 += 1;
a0;
});
  Term r22 = ({
Term a0 = arr_root; Term i0 = 1; u64 l0 = blk_loc(e.mem, a0); u32 g0 = (u32)blk_at(a0, (u64)(u32)i0, 0); Term old0[1]; u32 c0 = 0; Term r0 = 0;
old0[c0] = blk_read(e.mem, false, l0, g0 + c0); c0 += 1;
u64 w0[1]; for (u32 o0i = 0; o0i < 1; o0i += 1) { w0[o0i] = 0; } u32 o0 = 0;
u32 awc = 0;
w0[o0] = ((u64)(u32)((9))); o0 += 1;
awc += 1;
c0 = 0;
blk_write(e.mem, false, l0, g0 + c0, w0[c0]); c0 += 1;
u32 oc0 = 0;
u64 awoldw = old0[oc0]; oc0 += 1;
r0 = ((u64)(u32)(awoldw));
bend_tuple(e, 13u, a0, r0);
});
  Term r23 = ({
Term a0 = arr_root;
bend_tuple(e, 13u, a0, blk_copy(e, a0));
});
  Term r24 = ({
u64 w0[1]; for (u32 o0i = 0; o0i < 1; o0i += 1) { w0[o0i] = 0; } u32 o0 = 0;
u32 alc = 0;
w0[o0] = ((u64)(u32)((51))); o0 += 1;
alc += 1;
Term f0[1]; for (u32 f0i = 0; f0i < 1; f0i += 1) { f0[f0i] = w0[f0i]; }
blk_new(e, false, 0, 0, 1, f0);
});
  Term r25 = blk_node(e, leafv, leafw);

  if ((u32)r0 != 3 || (u32)r1 != 4) { err_fail("view probe: Pair fields wrong"); }
  if (term_aux(r2) != 7u) { err_fail("view probe: Pt hastag is not canonical True"); }
  if ((u32)r3 != 1u) { err_fail("view probe: Seg inline Pt.x wrong"); }
  if (term_aux(r4) != 2u || term_peek(e.mem, r4) != 5u) { err_fail("view probe: Seg Fl wrong"); }
  if (r5 != box_child) { err_fail("view probe: BoxP consume lost the child"); }
  if (term_aux(r6) != 5u) { err_fail("view probe: Unit copy wrong"); }
  if (term_tag(r7) != TAG_BUF || (u32)blk_cls(r7) != 3 || blk_read(e.mem, false, blk_loc(e.mem, r7), 0) != 8 || blk_read(e.mem, false, blk_loc(e.mem, r7), 7) != 7) { err_fail("view probe: array low half Term view wrong"); }
  if (term_tag(r8) != TAG_BUF || (u32)blk_cls(r8) != 3) { err_fail("view probe: array high half copy shape wrong"); }
  for (u32 pi = 0; pi < 8; pi += 1) { if (blk_read(e.mem, false, blk_loc(e.mem, r8), pi) != 7) { err_fail("view probe: array high half copy cell wrong"); } }
  if (blk_read(e.mem, false, blk_loc(e.mem, arr_root), 15) != 7) { err_fail("view probe: array copy mutated the source"); }
  if ((u32)r9 != 9u || blk_read(e.mem, false, blk_loc(e.mem, arr_leaf), 0) != 0) { err_fail("view probe: array leaf consume wrong"); }
  if (term_aux(r10) != 8u || term_aux(r11) != 7u) { err_fail("view probe: array is_leaf/is_node not canonical Bool"); }
  if (term_aux(r12) != 7u) { err_fail("view probe: multiarm Circle tag wrong"); }
  if ((u32)r13 != 21u) { err_fail("view probe: multiarm nested Circle payload wrong"); }
  if ((u32)r14 != 22u || (u32)r15 != 23u) { err_fail("view probe: Rect fields wrong"); }
  if ((u32)r16 != 41u || blk_read(e.mem, false, blk_loc(e.mem, nat_leaf), 0) != 0) { err_fail("view probe: Nat leaf consume wrong"); }
  if (term_aux(r17) != 12u || e.mem[term_peek(e.mem, r17) + 0] != 31 || e.mem[term_peek(e.mem, r17) + 1] != 32 || e.mem[term_peek(e.mem, r17) + 2] != 33) { err_fail("view probe: Wide leaf unfill wrong"); }
  for (u32 wi = 0; wi < 4; wi += 1) { if (blk_read(e.mem, false, blk_loc(e.mem, wide_leaf), wi) != 0) { err_fail("view probe: Wide leaf source was not cleared"); } }
  u32 shared_after = a32_load(a32_at(e.mem, term_loc(shared_child))) & RFC_CNT;
  if (r18 != shared_child || e.mem[shared_loc] != shared_child || shared_after <= shared_before) { err_fail("view probe: shared consume did not keep the sealed child"); }
  if ((u32)r19 != 3u) { err_fail("view probe: Seg second Pt.x at offset 2 wrong"); }

  u64 t20 = term_peek(e.mem, r20);
  if (e.mem[t20 + 0] != arr_root || (u32)e.mem[t20 + 1] != 7u) { err_fail("view probe: array_get tuple wrong"); }
  if (r21 != arr_root || blk_read(e.mem, false, blk_loc(e.mem, arr_root), 0) != 8) { err_fail("view probe: array_set wrong"); }
  u64 t22 = term_peek(e.mem, r22);
  if ((u32)e.mem[t22 + 1] != 7u || blk_read(e.mem, false, blk_loc(e.mem, arr_root), 1) != 9) { err_fail("view probe: array_swap wrong"); }
  u64 t23 = term_peek(e.mem, r23);
  if ((u32)blk_cls((Term)e.mem[t23 + 1]) != 4 || blk_read(e.mem, false, blk_loc(e.mem, (Term)e.mem[t23 + 1]), 0) != 8) { err_fail("view probe: array_clone wrong"); }
  if (term_tag(r24) != TAG_BUF || (u32)blk_cls(r24) != 0 || blk_read(e.mem, false, blk_loc(e.mem, r24), 0) != 51) { err_fail("view probe: array_leaf op wrong"); }
  if (term_tag(r25) != TAG_BUF || (u32)blk_cls(r25) != 1 || blk_read(e.mem, false, blk_loc(e.mem, r25), 0) != 52 || blk_read(e.mem, false, blk_loc(e.mem, r25), 1) != 53) { err_fail("view probe: array_node op wrong"); }
  term_sink(e, (Term)e.mem[t23 + 1]); term_sink(e, r20); term_sink(e, r22); term_sink(e, r23); term_sink(e, r24); term_sink(e, r25);
  term_sink(e, r18); term_sink(e, shared_value); term_sink(e, shared_parent);
  term_sink(e, r2); term_sink(e, r4); term_sink(e, r5); term_sink(e, r6); term_sink(e, r7); term_sink(e, r8); term_sink(e, r10); term_sink(e, r11); term_sink(e, r12); term_sink(e, r17);
  return 1;
}
static void __attribute__((constructor)) phys_view_probe_use(void) { io_eff(CID(probe), phys_view_probe_run); }
