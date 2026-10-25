static Term bend_fail(Env e, const char* m) { (void)e; err_fail(m); return 0; }
static Term bend_bool(Env e, u32 t, u32 f, u64 c) { (void)e; return term_pak(c != 0 ? t : f, 0); }
static Term bend_tuple(Env e, u32 tc, Term a, Term b) { u64 l = heap_alloc(e, cls_fit(2)); e.mem[l] = a; e.mem[l + 1] = b; return term_ctr(tc, l); }
static Term probe_array(Env e) { Term v[1]; v[0] = 7; return blk_new(e, false, 4, 0, 1, v); }
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
  u64 boxm_loc = heap_alloc(e, cls_fit(3));
  e.mem[boxm_loc + 0] = 0;
  e.mem[boxm_loc + 1] = 21;
  e.mem[boxm_loc + 2] = 0;
  Term boxm_value = term_ctr(CID_BOXM, boxm_loc);
  u64 rect_loc = heap_alloc(e, cls_fit(2));
  e.mem[rect_loc + 0] = 22;
  e.mem[rect_loc + 1] = 23;
  Term rect_value = term_ctr(CID_RECT, rect_loc);
  Term nv[1]; nv[0] = 4294967303ull;
  Term nat_leaf = blk_new(e, true, 0, 0, 1, nv);
  Term wv[3]; wv[0] = 31; wv[1] = 32; wv[2] = 33;
  Term wide_leaf = blk_new(e, false, 0, 2, 3, wv);
  u64 shared_child_loc = heap_alloc(e, cls_fit(1));
  e.mem[shared_child_loc] = 99;
  Term shared_child = rfc_seal(e, term_ctr(CID_BOXS, shared_child_loc));
  u64 shared_loc = heap_alloc(e, cls_fit(1));
  e.mem[shared_loc] = shared_child;
  Term shared_parent = term_ctr(CID_BOXS, shared_loc);
  Term shared_value = term_keep(e, shared_parent, 1);
  u32 shared_before = a32_load(a32_at(e.mem, term_loc(shared_child))) & RFC_CNT;
  Term erased_value = term_pak(CID_E, 77);
  Term wrap_value = term_pak(CID_WRAP, 5);
  Term ptv[2]; ptv[0] = 71; ptv[1] = 72;
  Term pt_leaf = blk_new(e, false, 0, 1, 2, ptv);
  Term inv[1]; inv[0] = 81;
  Term inner_arr = blk_new(e, false, 1, 0, 1, inv);
  Term outerv[1]; outerv[0] = inner_arr;
  Term outer_leaf = blk_new(e, true, 0, 0, 1, outerv);
  Term ptav[2]; ptav[0] = 91; ptav[1] = 92;
  Term ptarr = blk_new(e, false, 0, 1, 2, ptav);
  u64 boxarr_loc = heap_alloc(e, cls_fit(1));
  e.mem[boxarr_loc] = ptarr;
  Term boxarr_value = term_ctr(CID_BOXARRT, boxarr_loc);
  Term cv[2]; cv[0] = 1; cv[1] = 42;
  Term choice_leaf = blk_new(e, false, 0, 1, 2, cv);
  Term real_callable = (Term)f[3];
  if (term_triv(real_callable) || term_tag(real_callable) != TAG_CLO || term_loc(real_callable) == 0) { err_fail("view probe: the foreign callable is not a heap closure"); }
  Term clv[1]; clv[0] = real_callable;
  Term callable_leaf = blk_new(e, true, 0, 0, 1, clv);
  u64 tag_child_loc = heap_alloc(e, cls_fit(3));
  e.mem[tag_child_loc + 0] = 99;
  e.mem[tag_child_loc + 1] = 0;
  e.mem[tag_child_loc + 2] = 0;
  Term tag_child = term_ctr(CID_WIDEP, tag_child_loc);
  u64 tag_loc = heap_alloc(e, cls_fit(1));
  e.mem[tag_loc + 0] = tag_child;
  Term tagged_value = term_ctr(CID_BOXS, tag_loc);
  Term wrap_a_value = term_pak(CID_WRAPE, 0);
  Term wrap_b_value = term_pak(CID_WRAPE, 1);
  Term flags_value = (Term)f[13];
  if (term_aux(flags_value) != CID_FLAGSS) { err_fail("view probe: foreign FlagsS argument is not the real runtime constructor"); }

  Term r0 = /*@@r0@@*/;
  Term r1 = /*@@r1@@*/;
  Term r2 = /*@@r2@@*/;
  Term r3 = /*@@r3@@*/;
  Term r4 = /*@@r4@@*/;
  Term r5 = /*@@r5@@*/;
  Term r6 = /*@@r6@@*/;
  Term r7 = /*@@r7@@*/;
  Term r8 = /*@@r8@@*/;
  Term r9 = /*@@r9@@*/;
  Term r10 = /*@@r10@@*/;
  Term r11 = /*@@r11@@*/;
  Term r12 = /*@@r12@@*/;
  Term r13 = /*@@r13@@*/;
  Term r14 = /*@@r14@@*/;
  Term r15 = /*@@r15@@*/;
  Term r16 = /*@@r16@@*/;
  Term r17 = /*@@r17@@*/;
  Term r18 = /*@@r18@@*/;
  Term r19 = /*@@r19@@*/;
  Term r20 = /*@@r20@@*/;
  Term r21 = /*@@r21@@*/;
  Term r22;
  { Term arr_root = probe_array(e); r22 = /*@@r22@@*/; }
  Term r23;
  { Term arr_root = probe_array(e); r23 = /*@@r23@@*/; }
  Term r24;
  { Term arr_root = probe_array(e); r24 = /*@@r24@@*/; }
  Term r25;
  { Term arr_root = probe_array(e); r25 = /*@@r25@@*/; }
  Term r26 = /*@@r26@@*/;
  Term r27 = /*@@r27@@*/;
  Term r28 = /*@@r28@@*/;
  Term r29 = /*@@r29@@*/;
  Term r30 = /*@@r30@@*/;
  Term r31 = /*@@r31@@*/;
  Term r32 = /*@@r32@@*/;
  Term r33 = /*@@r33@@*/;
  Term r34 = /*@@r34@@*/;
  Term r35 = /*@@r35@@*/;
  Term r36 = /*@@r36@@*/;
  Term r37 = /*@@r37@@*/;
  Term r38 = /*@@r38@@*/;
  Term r39 = /*@@r39@@*/;
  Term r40 = /*@@r40@@*/;
  Term r41 = /*@@r41@@*/;
  Term r42 = /*@@r42@@*/;
  Term r43 = /*@@r43@@*/;

  if ((u32)r0 != 3 || (u32)r1 != 4) { err_fail("view probe: Pair fields wrong"); }
  if (term_aux(r2) != 14u) { err_fail("view probe: Pt hastag is not canonical True"); }
  if ((u32)r3 != 1u) { err_fail("view probe: Seg inline Pt.x wrong"); }
  if (term_aux(r4) != 34u || term_peek(e.mem, r4) != 5u) { err_fail("view probe: Seg Fl wrong"); }
  if (r5 != box_child) { err_fail("view probe: BoxP consume lost the child"); }
  if (term_aux(r6) != 15u) { err_fail("view probe: Unit copy wrong"); }
  if (term_tag(r7) != TAG_BUF || (u32)blk_cls(r7) != 3 || blk_read(e.mem, false, blk_loc(e.mem, r7), 0) != 7 || blk_read(e.mem, false, blk_loc(e.mem, r7), 7) != 7) { err_fail("view probe: array low half Term view wrong"); }
  if (term_tag(r8) != TAG_BUF || (u32)blk_cls(r8) != 3) { err_fail("view probe: array high half copy shape wrong"); }
  for (u32 pi = 0; pi < 8; pi += 1) { if (blk_read(e.mem, false, blk_loc(e.mem, r8), pi) != 7) { err_fail("view probe: array high half copy cell wrong"); } }
  if (blk_read(e.mem, false, blk_loc(e.mem, arr_root), 15) != 7) { err_fail("view probe: array views mutated the source"); }
  if ((u32)r9 != 9u || blk_read(e.mem, false, blk_loc(e.mem, arr_leaf), 0) != 0) { err_fail("view probe: array leaf consume wrong"); }
  if (term_aux(r10) != 13u || term_aux(r11) != 14u) { err_fail("view probe: array is_leaf/is_node not canonical Bool"); }
  if (term_aux(r12) != 14u) { err_fail("view probe: multiarm Circle tag wrong"); }
  if ((u32)r13 != 21u) { err_fail("view probe: multiarm nested Circle payload wrong"); }
  if ((u32)r14 != 22u || (u32)r15 != 23u) { err_fail("view probe: Rect fields wrong"); }
  if (term_aux(r16) != 19u || e.mem[term_peek(e.mem, r16) + 0] != 31 || e.mem[term_peek(e.mem, r16) + 1] != 32 || e.mem[term_peek(e.mem, r16) + 2] != 33) { err_fail("view probe: Wide leaf unfill wrong"); }
  for (u32 wi = 0; wi < 4; wi += 1) { if (blk_read(e.mem, false, blk_loc(e.mem, wide_leaf), wi) != 0) { err_fail("view probe: Wide leaf source was not cleared"); } }
  if ((u64)r17 != 4294967303ull || (u64)r18 != 4294967303ull || (u64)r19 != 4294967303ull) { err_fail("view probe: Nat full 48-bit word lost"); }
  if (blk_read(e.mem, true, blk_loc(e.mem, nat_leaf), 0) != 0) { err_fail("view probe: Nat consume did not clear the ARR cell"); }
  u32 shared_after = a32_load(a32_at(e.mem, term_loc(shared_child))) & RFC_CNT;
  if (r20 != shared_child || e.mem[shared_loc] != shared_child || shared_after <= shared_before) { err_fail("view probe: shared consume did not keep the sealed child"); }
  if ((u32)r21 != 3u) { err_fail("view probe: Seg second Pt.x at offset 2 wrong"); }
  u64 t22 = term_peek(e.mem, r22);
  if ((u32)e.mem[t22 + 1] != 7u || blk_read(e.mem, false, blk_loc(e.mem, (Term)e.mem[t22 + 0]), 0) != 7) { err_fail("view probe: array_get tuple wrong"); }
  if (blk_read(e.mem, false, blk_loc(e.mem, r23), 0) != 8) { err_fail("view probe: array_set wrong"); }
  u64 t24 = term_peek(e.mem, r24);
  if ((u32)e.mem[t24 + 1] != 7u || blk_read(e.mem, false, blk_loc(e.mem, (Term)e.mem[t24 + 0]), 1) != 9) { err_fail("view probe: array_swap wrong"); }
  u64 t25 = term_peek(e.mem, r25);
  if ((u32)blk_cls((Term)e.mem[t25 + 0]) != 4 || (u32)blk_cls((Term)e.mem[t25 + 1]) != 4 ||
      blk_read(e.mem, false, blk_loc(e.mem, (Term)e.mem[t25 + 0]), 0) != 7 ||
      blk_read(e.mem, false, blk_loc(e.mem, (Term)e.mem[t25 + 1]), 0) != 7 ||
      (Term)e.mem[t25 + 0] == (Term)e.mem[t25 + 1]) { err_fail("view probe: array_clone wrong"); }
  if (term_tag(r26) != TAG_BUF || (u32)blk_cls(r26) != 0 || blk_read(e.mem, false, blk_loc(e.mem, r26), 0) != 51) { err_fail("view probe: array_leaf op wrong"); }
  if (term_tag(r27) != TAG_BUF || (u32)blk_cls(r27) != 1 || blk_read(e.mem, false, blk_loc(e.mem, r27), 0) != 52 || blk_read(e.mem, false, blk_loc(e.mem, r27), 1) != 53) { err_fail("view probe: array_node op wrong"); }
  if ((u32)r28 != 77u) { err_fail("view probe: erased-live packed field wrong"); }
  if ((u32)r29 != 5u) { err_fail("view probe: packed nested Fl wrapper wrong"); }
  if ((u32)r30 != 71u || blk_read(e.mem, false, blk_loc(e.mem, pt_leaf), 0) != 0) { err_fail("view probe: BUF Pt.x wrong"); }
  if ((u32)r31 != 81u) { err_fail("view probe: nested array leaf wrong"); }
  if ((u32)r32 != 91u) { err_fail("view probe: mixed ADT->Array->ADT field wrong"); }
  if ((u32)r33 != 42u || blk_read(e.mem, false, blk_loc(e.mem, choice_leaf), 1) != 0) { err_fail("view probe: variant cell field wrong"); }
  if (term_aux(r34) != 14u) { err_fail("view probe: variant cell tag/cid conversion wrong"); }
  if (r35 == 0 || blk_read(e.mem, true, blk_loc(e.mem, callable_leaf), 0) != 0) { err_fail("view probe: callable cell consume wrong"); }
  if (term_aux(r36) != 14u || e.mem[tag_loc + 0] != tag_child) { err_fail("view probe: boxed tag wrong"); }
  if (term_aux(r37) != 14u || term_aux(r38) != 13u || term_aux(r39) != 14u) { err_fail("view probe: packed enum tag wrong"); }
  if (term_aux(r40) != 28u || term_aux(r41) != 29u) { err_fail("view probe: packed enum unfill wrong"); }
  if (term_aux(r42) != CID_FALSE) { err_fail("view probe: inline Bool false tag did not canonicalize to False"); }
  if (term_aux(r43) != CID_TRUE) { err_fail("view probe: inline Bool true tag did not canonicalize to True"); }
  u64 box_slot = term_peek(e.mem, box_value);
  bool box_static = term_triv(box_value);
  bool box_shared = !box_static && term_rfc(box_value) && (a32_load(a32_at(e.mem, term_loc(box_value))) & RFC_CNT) > 1;
  Term box_after = e.mem[box_slot];
  if (!box_static && !box_shared) { if (box_after != 0) { err_fail("view probe: unique box field was not cleared"); } }
  else if (box_after == 0) { err_fail("view probe: shared/static box field was cleared"); }
  term_sink(e, r35); term_sink(e, callable_leaf);
  term_sink(e, r20); term_sink(e, shared_value); term_sink(e, shared_parent);
  term_sink(e, boxm_value); term_sink(e, rect_value); term_sink(e, tagged_value);
  term_sink(e, boxarr_value); term_sink(e, outer_leaf); term_sink(e, pt_leaf); term_sink(e, choice_leaf);
  term_sink(e, wide_leaf); term_sink(e, nat_leaf); term_sink(e, arr_leaf); term_sink(e, arr_root);
  term_sink(e, r8); term_sink(e, r16); term_sink(e, r22); term_sink(e, r23); term_sink(e, r24); term_sink(e, r25);
  term_sink(e, r26); term_sink(e, r27);
  term_sink(e, r2); term_sink(e, r4); term_sink(e, r5); term_sink(e, r6); term_sink(e, r10); term_sink(e, r11);
  term_sink(e, r12); term_sink(e, r34); term_sink(e, r36); term_sink(e, r37); term_sink(e, r38); term_sink(e, r39);
  term_sink(e, r42); term_sink(e, r43);
  for (u32 fi = 0; fi < 14; fi += 1) { term_sink(e, f[fi]); }
  return 1;
}
static void __attribute__((constructor)) phys_view_probe_use(void) { io_eff(CID(probe), phys_view_probe_run); }
