# C target physical emission
# ===========================
#
# Storage (Fill/Unfill, construct/project, array cells) and the pure-main
# SHOW_DESC/SHOW_NAMES, from the frozen CLay oracle and Backend IR facts only.
# No entry/table/segment emission (CIRControl), no layout rule of its own.
#
# Representation: every callable value is ONE Term. Nat/U32/F32 are raw words;
# every other ADT is a tagged Term (term_ctr over the constructor's node
# layout, term_pak for a zero/one-w32 node). LayoutData describes storage in a
# node or an array cell only, so the show root is boxed.
#
# Ownership: a Many operand is term_keep(e,w,1) (or kept whole before an inline
# unbox, whose ctr_take then bumps the child references); an Affine operand is
# rfc_seal(e,w) in node storage and taken as-is by array writes. A read of a
# sealed node goes through ctr_take; an unsealed term is the only owner. An
# erased slot is a loud failure.
#
# Arrays take their element cell from CLay.array_cell(types[0]) (arr/words/lgs)
# and convert elements through Fill/Unfill.
#
# This kernel admits matches only on parameters/pattern binders, has no
# forward references and no mutual recursion. Conversion is therefore a
# worklist of Jobs with one self-recursive driver (fuel-bounded), and SHOW is a
# worklist of ShowJobs with its own driver; every expansion helper is
# non-recursive and defined before use.

import Base
import ./backend_ir.bend as BIR
import ./c_backend_layout.bend as CLay
import ./index_lookup.bend as IndexLookup



type Part is Data:
  PartOk{text: String}
  PartFail{message: String}

type CidSym is Data:
  CidSym{cid: U32, key: String}

type World is Data:
  World{ctx: CLay.Context, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, cids: List<&2, CidSym>}

type Code is Data:
  CodeOk{lines: List<&2, String>}
  CodeFail{message: String}

type Operand is Data:
  Operand{use: BIR.Use, text: String}

# ---------------------------------------------------------------------------
# Code assembly
# ---------------------------------------------------------------------------

type Dst is Data:
  DstSeq{buf: String, cursor: String}
  DstOut{out: String}

type Src is Data:
  SrcOne{text: String}
  SrcNode{base: String, fb: String, cursor: String, packed: Bool}
  SrcBlock{loc: String, at: String, arr: Bool, keep: Bool, cursor: String}
  SrcBuf{buf: String, cursor: String}

type Job is Data:
  JText{text: String}
  JConv{take: CLay.Unfill, make: CLay.Fill, src: Src, dst: Dst, tag: String}
  JFail{message: String}

type CellOut is Data:
  CellOk{layout: CLay.Layout, arr: Bool, words: Nat, lgs: Nat}
  CellFail{message: String}

type ShowWord is Data:
  ShowNum{value: Nat}
  ShowCid{value: Nat}

type ShowPatch is Data:
  ShowPatchAt{at: Nat, to: Nat}

type ShowState is Data:
  ShowState{words: List<&2, ShowWord>, patches: List<&2, ShowPatch>, memo: Map<&2, Nat>, names: List<&2, String>, error: Maybe<&2, String>}

type ShowJob is Data:
  ShowNode{ty: BIR.Descriptor, layout: CLay.Layout, patch: Maybe<&2, Nat>}

type ShowAdvance is Data:
  ShowNext{state: ShowState, kids: List<&2, ShowJob>}

type ShowRun is Data:
  ShowDone{state: ShowState}

type ShowOut is Data:
  ShowOk{desc: String, names: String}
  ShowFail{message: String}

type ShowKind is Data:
  ShowKindOk{kind: Nat}
  ShowKindFailed{message: String}

type ShowNorm is Data:
  ShowNormOk{descriptor: BIR.Descriptor}
  ShowNormFailed{message: String}

type ShowToken is Data:
  ShowTokDesc{descriptor: BIR.Descriptor}
  ShowTokText{text: String}
  ShowTokPat{pattern: BIR.DescriptorPattern}

def world(+pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pcids: List<&2, CidSym>) -> World:
  World{pctx, pconstructors, pfamilies, pcids}

def join_text(+pparts: List<&2, String>) -> String:
  String.join(pparts, "")

def code_line(+ptext: String) -> Code:
  CodeOk{[ptext]}

def code_empty() -> Code:
  CodeOk{Nil{}}

def code_seq(+pa: Code, +pb: Code) -> Code:
  match pa:
    case CodeFail{message}: CodeFail{message}
    case CodeOk{lines}:
      match pb:
        case CodeFail{message}: CodeFail{message}
        case CodeOk{more}: CodeOk{List.append(&2, String, lines, more)}

def code_text(+plines: List<&2, String>, +pexpression: String) -> String:
  match plines:
    case Nil{}: pexpression
    case +line <> +rest: join_text(["({\n", String.join(plines, "\n"), "\n", pexpression, ";\n})"])

def part_of(+pcode: Code, +pexpression: String) -> Part:
  match pcode:
    case CodeFail{+message}: PartFail{message}
    case CodeOk{+lines}: PartOk(code_text(lines, pexpression))

# ---------------------------------------------------------------------------
# Lookups
# ---------------------------------------------------------------------------

def ctor_find(+pid: U32, +prows: List<&2, BIR.ConstructorLayout>) -> Maybe<&2, BIR.ConstructorLayout>:
  match prows:
    case Nil{}: None{}
    case +row <> +rest:
      match row:
        case BIR.ConstructorLayout{id, key, native, fields}:
          same = U32.is_eq(pid, id)
          Bool.pick(Maybe<&2, BIR.ConstructorLayout>, same, Some{row}, ctor_find(pid, rest))

def ctor_of(+pid: U32, +pw: World) -> Maybe<&2, BIR.ConstructorLayout>:
  match pw:
    case World{ctx, constructors, families, cids}: ctor_find(pid, constructors)

def cid_find(+pwant: String, +pcids: List<&2, CidSym>) -> Maybe<&2, U32>:
  match pcids:
    case Nil{}: None{}
    case +row <> +rest:
      match row:
        case CidSym{cid, key}:
          same = String.eq(pwant, key)
          Bool.pick(Maybe<&2, U32>, same, Some{cid}, cid_find(pwant, rest))

def cid_of(+pkey: String, +pw: World) -> Maybe<&2, U32>:
  match pw:
    case World{ctx, constructors, families, cids}: cid_find(pkey, cids)

def cid_text_of(+pfound: Maybe<&2, U32>) -> Maybe<&2, String>:
  match pfound:
    case Some{cid}: Some{join_text([U32.show(cid), "u"])}
    case None{}: None{}

def cid_text(+pkey: String, +pw: World) -> Maybe<&2, String>:
  found = cid_of(pkey, pw)
  cid_text_of(found)

def intrinsic_marker(+pmarker: String) -> Bool:
  match pmarker:
    case "Nat.Zero": True{}
    case "Nat.Succ": True{}
    case "U32.U32": True{}
    case "F32.F32": True{}
    case "Char.Chr": True{}
    case "Bool.True": True{}
    case "Bool.False": True{}
    case "String.SNil": True{}
    case "String.SCon": True{}
    case "Array.ALeaf": True{}
    case "Array.ANode": True{}
    case _: False{}

# ---------------------------------------------------------------------------
# Cursors, jobs and their expansion helpers
# ---------------------------------------------------------------------------

def dst_write(+pdst: Dst, +pexpression: String) -> List<&2, Job>:
  match pdst:
    case DstSeq{buf, cursor}: [JText{join_text([buf, "[", cursor, "] = ", pexpression, "; ", cursor, " += 1;"])}]
    case DstOut{out}: [JText{join_text([out, " = ", pexpression, ";"])}]

def dst_word(+pdst: Dst, +pword: CLay.CWord, +pexpression: String) -> List<&2, Job>:
  match pword:
    case CLay.CWord32{}: dst_write(pdst, join_text(["((u64)(u32)(", pexpression, "))"]))
    case CLay.CWord64{}: dst_write(pdst, pexpression)
    case CLay.CWordBox{}: dst_write(pdst, pexpression)

def dst_decl(+pbuf: String, +pcursor: String, +pcount: Nat) -> String:
  join_text(["u64 ", pbuf, "[", Nat.show(pcount), "]; for (u32 ", pcursor, "i = 0; ", pcursor, "i < ", Nat.show(pcount), "; ", pcursor, "i += 1) { ", pbuf, "[", pcursor, "i] = 0; } u32 ", pcursor, " = 0;"])

def dst_mark(+pdst: Dst, +ptag: Nat) -> String:
  value = Nat.show(ptag)
  match pdst:
    case DstSeq{buf, cursor}: join_text([buf, "[", cursor, "]", " = ", value, "; ", cursor, " += 1;"])
    case DstOut{out}: join_text([out, " = ", value, ";"])

def src_read_node(+pbase: String, +pfb: String, +pcursor: String, +ppacked: Bool, +ptag: String) -> List<&2, Job>:
  match ppacked:
    case True{}: [JText{join_text(["u64 ", ptag, "w = ", pbase, ";"])}]
    case False{}: [JText{join_text(["u64 ", ptag, "w = ((", pbase, " != 0) ? e.mem[", pbase, " + ", pcursor, "] : (u64)", pfb, "[", pcursor, "]); ", pcursor, " += 1;"])}]

def src_read_arr(+ploc: String, +pat: String, +pkeep: Bool, +pcursor: String, +ptag: String) -> List<&2, Job>:
  match pkeep:
    case True{}: [JText{join_text(["u64 ", ptag, "w = blk_keep(e, ", ploc, " + ", pat, " + ", pcursor, "); ", pcursor, " += 1;"])}]
    case False{}: [JText{join_text(["u64 ", ptag, "w = blk_read(e.mem, true, ", ploc, ", ", pat, " + ", pcursor, "); ", pcursor, " += 1;"])}]

def src_read_block(+ploc: String, +pat: String, +parr: Bool, +pkeep: Bool, +pcursor: String, +ptag: String) -> List<&2, Job>:
  match parr:
    case True{}: src_read_arr(ploc, pat, pkeep, pcursor, ptag)
    case False{}: [JText{join_text(["u64 ", ptag, "w = ((u64)blk_read(e.mem, false, ", ploc, ", ", pat, " + ", pcursor, ")); ", pcursor, " += 1;"])}]

def src_read(+psrc: Src, +ptag: String) -> List<&2, Job>:
  match psrc:
    case SrcOne{text}: [JText{join_text(["u64 ", ptag, "w = ", text, ";"])}]
    case SrcNode{base, fb, cursor, packed}: src_read_node(base, fb, cursor, packed, ptag)
    case SrcBlock{loc, at, arr, keep, cursor}: src_read_block(loc, at, arr, keep, cursor, ptag)
    case SrcBuf{buf, cursor}: [JText{join_text(["u64 ", ptag, "w = ", buf, "[", cursor, "]; ", cursor, " += 1;"])}]

def form_tagged(+parms: List<&2, CLay.FormArm>) -> Bool:
  match parms:
    case Nil{}: False{}
    case +only <> Nil{}: False{}
    case _: True{}

def max_node_words(+parms: List<&2, CLay.FormArm>, +pacc: Nat) -> Nat:
  match parms:
    case Nil{}: pacc
    case +arm <> +rest:
      match arm:
        case CLay.FormArm{key, tag, packed, node_words, fields}: max_node_words(rest, Nat.max(pacc, node_words))

def max_term_decl(+pfb: String, +pcount: Nat) -> String:
  match pcount:
    case 0n: ""
    case _: join_text(["Term ", pfb, "[", Nat.show(pcount), "];"])

# The source of one arm: its canonical node storage.

def arm_seed(+ppacked: Bool, +pnode_words: Nat, +pt: String, +ptag: String, +pfb: String) -> List<&2, Job>:
  match ppacked:
    case True{}: Nil{}
    case False{}: arm_seed_words(pnode_words, pt, ptag, pfb)

def arm_seed_words(+pnode_words: Nat, +pt: String, +ptag: String, +pfb: String) -> List<&2, Job>:
  match pnode_words:
    case 0n: Nil{}
    case _: [JText{join_text(["u64 ", ptag, "s = term_rfc(", pt, ") ? ctr_take(e, ", pt, ", ", Nat.show(pnode_words), ", ", pfb, ") : term_loc(", pt, "); u32 ", ptag, "i = 0;"])}]

def arm_src(+ppacked: Bool, +pnode_words: Nat, +pt: String, +ptag: String, +pfb: String) -> Src:
  match ppacked:
    case True{}:
      match pnode_words:
        case 0n: SrcOne{"0"}
        case _: SrcOne{join_text(["((u64)term_loc(", pt, "))"])}
    case False{}: SrcNode{join_text([ptag, "s"]), pfb, join_text([ptag, "i"]), False{}}

# Arm expansion: emits the case block and the nested JConv jobs.

def nests_jobs(+pw: World, +pnests: List<&2, CLay.Nest>, +psrc: Src, +pdst: Dst, +ptag: String, +pindex: Nat) -> List<&2, Job>:
  match pnests:
    case Nil{}: Nil{}
    case +nest <> +rest:
      match nest:
        case CLay.Nest{at, offset, take, make}:
          List.append(&2, Job, [JConv{take, make, psrc, pdst, join_text([ptag, "f", Nat.show(pindex)])}], nests_jobs(pw, rest, psrc, pdst, ptag, Nat.add(pindex, 1n)))

# Expand one conversion into jobs. This function never calls itself or another
# expander: nested work becomes JConv entries in the returned list.

def arm_release(+ppacked: Bool, +pnode_words: Nat, +ptag: String) -> List<&2, Job>:
  match ppacked:
    case True{}: Nil{}
    case False{}:
      match pnode_words:
        case 0n: Nil{}
        case _: [JText{join_text(["if (", ptag, "s != 0) { spare_free(e, cls_fit(", Nat.show(pnode_words), "), ", ptag, "s); }"])}]

def jobs_arm_body(+pw: World, +pcid: U32, +ptag_index: Nat, +ppacked: Bool, +pnode_words: Nat, +pfields: List<&2, CLay.Nest>, +pt: String, +pdst: Dst, +ptag: String, +ptagged: Bool, +pfb: String, +pmode: Nat) -> List<&2, Job>:
  List.append(&2, Job, Bool.pick(List<&2, Job>, ptagged, one_job(JText{dst_mark(pdst, ptag_index)}), Nil{}), List.append(&2, Job, arm_seed(ppacked, pnode_words, pt, ptag, pfb), List.append(&2, Job, nests_jobs(pw, pfields, arm_src(ppacked, pnode_words, pt, ptag, pfb), pdst, ptag, 0n), arm_release(ppacked, pnode_words, ptag))))

def jobs_arm(+pw: World, +pcid: U32, +ptag_index: Nat, +ppacked: Bool, +pnode_words: Nat, +pfields: List<&2, CLay.Nest>, +pt: String, +pdst: Dst, +ptag: String, +ptagged: Bool, +pfb: String, +pmode: Nat) -> List<&2, Job>:
  List.append(&2, Job, [JText{join_text(["case ", U32.show(pcid), "u: {"])}], List.append(&2, Job, jobs_arm_body(pw, pcid, ptag_index, ppacked, pnode_words, pfields, pt, pdst, ptag, ptagged, pfb, pmode), [JText{"} break;"}]))

def arm_jobs(+pw: World, +pfound: Maybe<&2, U32>, +parm: CLay.FormArm, +pt: String, +pdst: Dst, +ptag: String, +ptagged: Bool, +pfb: String, +pmode: Nat) -> List<&2, Job>:
  match pfound:
    case None{}: [JText{"default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;"}]
    case Some{cid}:
      match parm:
        case CLay.FormArm{key, tag, packed, node_words, fields}:
          jobs_arm(pw, cid, tag, packed, node_words, fields, pt, pdst, ptag, ptagged, pfb, pmode)

def unbox_cases(+pw: World, +parms: List<&2, CLay.FormArm>, +pt: String, +pdst: Dst, +ptag: String, +ptagged: Bool, +pfb: String) -> List<&2, Job>:
  match parms:
    case Nil{}: Nil{}
    case +arm <> +rest:
      match arm:
        case CLay.FormArm{key, tag, packed, node_words, fields}:
          found = cid_of(key, pw)
          List.append(&2, Job, arm_jobs(pw, found, arm, pt, pdst, ptag, ptagged, pfb, 0n), unbox_cases(pw, rest, pt, pdst, ptag, ptagged, pfb))

def expand_unbox(+pw: World, +parms: List<&2, CLay.FormArm>, +psrc: Src, +pdst: Dst, +ptag: String) -> List<&2, Job>:
  t = join_text([ptag, "t"])
  fb = join_text([ptag, "f"])
  count = max_node_words(parms, 0n)
  tagged = form_tagged(parms)
  head = List.append(&2, Job, src_read(psrc, ptag), List.append(&2, Job, [JText{join_text(["Term ", t, " = ", ptag, "w;"])}], [JText{max_term_decl(fb, count)}]))
  cases = unbox_cases(pw, parms, t, pdst, ptag, tagged, fb)
  List.append(&2, Job, head, List.append(&2, Job, [JText{join_text(["switch (term_aux(", t, ")) {"])}], List.append(&2, Job, cases, [JText{"}"}])))

def expand_word_take(+pw: World, +pmake: CLay.Fill, +psrc: Src, +pdst: Dst, +ptag: String) -> List<&2, Job>:
  match pmake:
    case CLay.FillWord{}: List.append(&2, Job, src_read(psrc, ptag), dst_write(pdst, join_text([ptag, "w"])))
    case CLay.FillForm{words, arms}: expand_unbox(pw, arms, psrc, pdst, ptag)

def nest_take(+pfield: CLay.Nest) -> CLay.Unfill:
  match pfield:
    case CLay.Nest{at, offset, take, make}: take

def nest_make(+pfield: CLay.Nest) -> CLay.Fill:
  match pfield:
    case CLay.Nest{at, offset, take, make}: make

# Each pair is its own conversion in the same block, so each pair needs its
# own cursor name: two fields of one arm are two declarations of distinct
# temporaries, never a redefinition of one.
def field_pair_jobs(+pw: World, +pfields: List<&2, CLay.Nest>, +pout_fields: List<&2, CLay.Nest>, +psrc: Src, +pdst: Dst, +ptag: String, +pindex: Nat) -> List<&2, Job>:
  match pfields:
    case Nil{}:
      match pout_fields:
        case Nil{}: Nil{}
        case _: [JFail{"the constructor's slots and fields differ"}]
    case +field <> +rest:
      match pout_fields:
        case Nil{}: [JFail{"the constructor's slots and fields differ"}]
        case +out_field <> +out_rest:
          tag = join_text([ptag, "p", Nat.show(pindex)])
          List.append(&2, Job, [JConv{nest_take(field), nest_make(out_field), psrc, pdst, tag}], field_pair_jobs(pw, rest, out_rest, psrc, pdst, ptag, Nat.add(pindex, 1n)))

def form_fields(+parm: CLay.FormArm) -> List<&2, CLay.Nest>:
  match parm:
    case CLay.FormArm{key, tag, packed, node_words, fields}: fields

# One arm of an inline conversion, in destination order: the arm's tag word
# when the layout stores one (the arm's own ordinal, which is the same on the
# two sides of one declared type), then every field pair. A form stores a
# leading tag word only when its type has more than one arm (c_backend_layout
# form_arms), so an untagged form writes no tag word at all.
def forms_arm_body(+pw: World, +parm_tag: Nat, +pfields: List<&2, CLay.Nest>, +pfound: Maybe<&2, CLay.FormArm>, +psrc: Src, +pdst: Dst, +ptag: String, +pdst_tagged: Bool) -> List<&2, Job>:
  match pfound:
    case None{}: [JText{"(void)err_fail(\"the inline conversion target has no arm\");"}]
    case Some{target}:
      List.append(&2, Job, Bool.pick(List<&2, Job>, pdst_tagged, one_job(JText{dst_mark(pdst, parm_tag)}), Nil{}), field_pair_jobs(pw, pfields, form_fields(target), psrc, pdst, ptag, 0n))

def forms_arm_case(+pw: World, +pfound: Maybe<&2, CLay.FormArm>, +parm: CLay.FormArm, +psrc: Src, +pdst: Dst, +ptag: String, +pindex: Nat, +pdst_tagged: Bool) -> List<&2, Job>:
  match parm:
    case CLay.FormArm{key, tag, packed, node_words, fields}:
      body = forms_arm_body(pw, tag, fields, pfound, psrc, pdst, ptag, pdst_tagged)
      List.append(&2, Job, [JText{join_text(["case ", Nat.show(pindex), ": {"])}], List.append(&2, Job, body, [JText{"} break;"}]))

def form_arm_by_key(+pwant: String, +parms: List<&2, CLay.FormArm>) -> Maybe<&2, CLay.FormArm>:
  match parms:
    case Nil{}: None{}
    case +arm <> +rest:
      match arm:
        case CLay.FormArm{key, tag, packed, node_words, fields}:
          same = String.eq(pwant, key)
          Bool.pick(Maybe<&2, CLay.FormArm>, same, Some{arm}, form_arm_by_key(pwant, rest))

def forms_cases(+pw: World, +parms: List<&2, CLay.FormArm>, +pmake_arms: List<&2, CLay.FormArm>, +psrc: Src, +pdst: Dst, +ptag: String, +pdst_tagged: Bool, +pindex: Nat) -> List<&2, Job>:
  match parms:
    case Nil{}: Nil{}
    case +arm <> +rest:
      match arm:
        case CLay.FormArm{key, tag, packed, node_words, fields}:
          found = form_arm_by_key(key, pmake_arms)
          block = forms_arm_case(pw, found, arm, psrc, pdst, ptag, pindex, pdst_tagged)
          List.append(&2, Job, block, forms_cases(pw, rest, pmake_arms, psrc, pdst, ptag, pdst_tagged, Nat.add(pindex, 1n)))

# Two inline forms. A form stores a leading tag word exactly when its type has
# more than one arm, so the source tag is read and switched on only then; a
# one-arm form has no tag to read and its single arm converts in place. The
# destination stores its arm's tag word under the same rule.
def expand_forms(+pw: World, +ptake_arms: List<&2, CLay.FormArm>, +pmake_arms: List<&2, CLay.FormArm>, +psrc: Src, +pdst: Dst, +ptag: String) -> List<&2, Job>:
  dst_tagged = form_tagged(pmake_arms)
  match ptake_arms:
    case Nil{}: Nil{}
    case +only <> Nil{}: forms_single(pw, only, pmake_arms, psrc, pdst, ptag, dst_tagged)
    case _:
      cases = forms_cases(pw, ptake_arms, pmake_arms, psrc, pdst, ptag, dst_tagged, 0n)
      List.append(&2, Job, src_read(psrc, ptag), List.append(&2, Job, [JText{join_text(["switch ((u32)(", ptag, "w)) {"])}], List.append(&2, Job, cases, [JText{"}"}])))

def forms_single(+pw: World, +parm: CLay.FormArm, +pmake_arms: List<&2, CLay.FormArm>, +psrc: Src, +pdst: Dst, +ptag: String, +pdst_tagged: Bool) -> List<&2, Job>:
  match parm:
    case CLay.FormArm{key, tag, packed, node_words, fields}:
      forms_arm_body(pw, tag, fields, form_arm_by_key(key, pmake_arms), psrc, pdst, ptag, pdst_tagged)

def pack_jobs(+pcid: U32, +pcount: Nat, +ppacked: Bool, +pnw: String, +pout: String, +ptag: String) -> List<&2, Job>:
  match pcount:
    case 0n: [JText{join_text([pout, " = term_pak(", U32.show(pcid), "u, 0);"])}]
    case _:
      match ppacked:
        case True{}: [JText{join_text([pout, " = term_pak(", U32.show(pcid), "u, (u64)", pnw, "[0]);"])}]
        case False{}:
          at = join_text([ptag, "l"])
          [JText{join_text(["u64 ", at, " = heap_alloc(e, cls_fit(", Nat.show(pcount), ")); for (u32 ", at, "i = 0; ", at, "i < ", Nat.show(pcount), "; ", at, "i += 1) { e.mem[", at, " + ", at, "i] = ", pnw, "[", at, "i]; } ", pout, " = term_ctr(", U32.show(pcid), "u, ", at, ");"])}]

# One arm of a boxed conversion: the node payload words (no tag word: the
# constructor id is the Term's own), then the packed Term.

def arm_block_jobs(+pw: World, +pcid: U32, +parm: CLay.FormArm, +psrc: Src, +pout: String, +ptag: String, +pindex: Nat) -> List<&2, Job>:
  match parm:
    case CLay.FormArm{key, tag, packed, node_words, fields}:
      nw = join_text([ptag, "w"])
      cur = join_text([ptag, "j"])
      List.append(&2, Job, one_job(JText{dst_decl(nw, cur, node_words)}), List.append(&2, Job, nests_jobs(pw, fields, psrc, DstSeq{nw, cur}, join_text([ptag, "x", Nat.show(pindex)]), 0n), pack_jobs(pcid, node_words, packed, nw, pout, ptag)))

def box_arm_jobs(+pw: World, +pfound: Maybe<&2, U32>, +parm: CLay.FormArm, +psrc: Src, +pout: String, +ptag: String, +pindex: Nat) -> List<&2, Job>:
  match pfound:
    case None{}: [JText{"default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;"}]
    case Some{cid}: List.append(&2, Job, [JText{join_text(["case ", Nat.show(pindex), ": {"])}], List.append(&2, Job, arm_block_jobs(pw, cid, parm, psrc, pout, ptag, pindex), [JText{"} break;"}]))

def box_cases(+pw: World, +parms: List<&2, CLay.FormArm>, +psrc: Src, +pout: String, +ptag: String, +ptagged: Bool, +pindex: Nat) -> List<&2, Job>:
  match parms:
    case Nil{}: Nil{}
    case +arm <> +rest:
      match arm:
        case CLay.FormArm{key, tag, packed, node_words, fields}:
          found = cid_of(key, pw)
          block = box_arm_jobs(pw, found, arm, psrc, pout, ptag, pindex)
          List.append(&2, Job, block, box_cases(pw, rest, psrc, pout, ptag, ptagged, Nat.add(pindex, 1n)))

def box_untagged(+pw: World, +parms: List<&2, CLay.FormArm>, +psrc: Src, +pout: String, +ptag: String) -> List<&2, Job>:
  match parms:
    case Nil{}: Nil{}
    case +arm <> Nil{}:
      match arm:
        case CLay.FormArm{key, tag, packed, node_words, fields}:
          match cid_of(key, pw):
            case None{}: [JText{"(void)err_fail(\"the constructor tag is not a declared constructor\");"}]
            case Some{cid}: arm_block_jobs(pw, cid, arm, psrc, pout, ptag, 0n)
    case _: Nil{}

def expand_box(+pw: World, +parms: List<&2, CLay.FormArm>, +psrc: Src, +pdst: Dst, +ptag: String) -> List<&2, Job>:
  r = join_text([ptag, "r"])
  bool_ = form_tagged(parms)
  List.append(&2, Job, [JText{join_text(["Term ", r, " = 0;"])}], expand_box_body(bool_, pw, parms, psrc, pdst, ptag, r))

def expand_box_body(+ptagged: Bool, +pw: World, +parms: List<&2, CLay.FormArm>, +psrc: Src, +pdst: Dst, +ptag: String, +pr: String) -> List<&2, Job>:
  match ptagged:
    case True{}:
      List.append(&2, Job, src_read(psrc, ptag), List.append(&2, Job, [JText{join_text(["switch ((u32)(", ptag, "w)) {"])}], List.append(&2, Job, box_cases(pw, parms, psrc, pr, ptag, True{}, 0n), List.append(&2, Job, [JText{"}"}], dst_write(pdst, pr)))))
    case False{}:
      List.append(&2, Job, box_untagged(pw, parms, psrc, pr, ptag), dst_write(pdst, pr))

def expand_form_take(+pw: World, +parms: List<&2, CLay.FormArm>, +pmake: CLay.Fill, +psrc: Src, +pdst: Dst, +ptag: String) -> List<&2, Job>:
  match pmake:
    case CLay.FillWord{}: expand_box(pw, parms, psrc, pdst, ptag)
    case CLay.FillForm{words, arms}: expand_forms(pw, parms, arms, psrc, pdst, ptag)

# Box an inline value into one Term.

def expand_conv(+pw: World, +ptake: CLay.Unfill, +pmake: CLay.Fill, +psrc: Src, +pdst: Dst, +ptag: String) -> List<&2, Job>:
  match ptake:
    case CLay.UnfillWord{}: expand_word_take(pw, pmake, psrc, pdst, ptag)
    case CLay.UnfillForm{words, arms}: expand_form_take(pw, arms, pmake, psrc, pdst, ptag)

def run_jobs(+pjobs: List<&2, Job>, +pw: World, +pacc: List<&2, String>) -> Code:
  match pjobs:
    case Nil{}: CodeOk(pacc)
    case +job <> +rest:
      match job:
        case JText{text}: run_jobs(rest, pw, List.append(&2, String, pacc, [text]))
        case JFail{message}: CodeFail{message}
        case JConv{take, make, src, dst, tag}: run_jobs(List.append(&2, Job, expand_conv(pw, take, make, src, dst, tag), rest), pw, pacc)

# ---------------------------------------------------------------------------
# Fill / Unfill entry points
# ---------------------------------------------------------------------------

def fill_plan_jobs(+pfill: CLay.Fill, +pterm: String, +pdst: Dst, +ptag: String) -> List<&2, Job>:
  match pfill:
    case CLay.FillWord{}: [JFail{"a data layout produced a one-word fill"}]
    case CLay.FillForm{words, arms}: [JConv{CLay.UnfillWord{}, pfill, SrcOne{pterm}, pdst, ptag}]

def fill_result_jobs(+pfr: CLay.FillResult, +pterm: String, +pdst: Dst, +ptag: String) -> List<&2, Job>:
  match pfr:
    case CLay.FillFailed{message}: [JFail{message}]
    case CLay.FillFound{fill}: fill_plan_jobs(fill, pterm, pdst, ptag)

def fill_data_jobs(+pw: World, +playout: CLay.Layout, +pterm: String, +pdst: Dst, +ptag: String) -> List<&2, Job>:
  match pw:
    case World{ctx, constructors, families, cids}:
      fr = CLay.layout_fill(ctx, playout)
      fill_result_jobs(fr, pterm, pdst, ptag)

def fill_jobs(+pw: World, +playout: CLay.Layout, +pterm: String, +pdst: Dst, +ptag: String) -> List<&2, Job>:
  match playout:
    case CLay.LayoutWord{word}: dst_word(pdst, word, pterm)
    case CLay.LayoutBox{reason}: dst_write(pdst, pterm)
    case CLay.LayoutData{words, arms}: fill_data_jobs(pw, playout, pterm, pdst, ptag)

def unfill_result_jobs(+pur: CLay.UnfillResult, +psrc: Src, +pout: String, +ptag: String) -> List<&2, Job>:
  match pur:
    case CLay.UnfillFailed{message}: [JFail{message}]
    case CLay.UnfillFound{unfill}: [JConv{unfill, CLay.FillWord{}, psrc, DstOut{pout}, ptag}]

# ---------------------------------------------------------------------------
# Construct / Project / HasTag
# ---------------------------------------------------------------------------

def unfill_data_jobs(+pw: World, +playout: CLay.Layout, +psrc: Src, +pout: String, +ptag: String) -> List<&2, Job>:
  match pw:
    case World{ctx, constructors, families, cids}:
      ur = CLay.layout_unfill(ctx, playout)
      unfill_result_jobs(ur, psrc, pout, ptag)

def unfill_word_jobs(+pword: CLay.CWord, +psrc: Src, +pout: String, +ptag: String) -> List<&2, Job>:
  match pword:
    case CLay.CWord32{}: List.append(&2, Job, src_read(psrc, ptag), [JText{join_text([pout, " = ((u64)(u32)(", ptag, "w));"])}])
    case _: List.append(&2, Job, src_read(psrc, ptag), [JText{join_text([pout, " = ", ptag, "w;"])}])

def unfill_jobs(+pw: World, +playout: CLay.Layout, +psrc: Src, +pout: String, +ptag: String) -> List<&2, Job>:
  match playout:
    case CLay.LayoutWord{word}: unfill_word_jobs(word, psrc, pout, ptag)
    case CLay.LayoutBox{reason}: List.append(&2, Job, src_read(psrc, ptag), [JText{join_text([pout, " = ", ptag, "w;"])}])
    case CLay.LayoutData{words, arms}: unfill_data_jobs(pw, playout, psrc, pout, ptag)

def operand_code(+playout: CLay.Layout, +puse: BIR.Use, +ptext: String, +ptag: String) -> Code:
  match playout:
    case CLay.LayoutData{words, arms}:
      match puse:
        case BIR.Many{}: code_line(join_text(["Term ", ptag, "v = term_keep(e, ", ptext, ", 1);"]))
        case _: code_empty()
    case _: code_empty()

def operand_name(+playout: CLay.Layout, +puse: BIR.Use, +ptext: String, +ptag: String) -> String:
  match playout:
    case CLay.LayoutData{words, arms}:
      match puse:
        case BIR.Many{}: join_text([ptag, "v"])
        case _: join_text(["(", ptext, ")"])
    case _: join_text(["(", ptext, ")"])

def text_jobs(+plines: List<&2, String>) -> List<&2, Job>:
  match plines:
    case Nil{}: Nil{}
    case +line <> +rest: List.append(&2, Job, [JText{line}], text_jobs(rest))

def code_jobs(+pcode: Code) -> List<&2, Job>:
  match pcode:
    case CodeFail{message}: [JFail{message}]
    case CodeOk{lines}: text_jobs(lines)

def fill_slots_jobs(+pw: World, +pslots: List<&2, CLay.NodeSlot>, +pfields: List<&2, Operand>) -> List<&2, Job>:
  match pslots:
    case Nil{}:
      match pfields:
        case Nil{}: Nil{}
        case _: [JFail{"the constructor's slots and fields differ"}]
    case +slot <> +rest:
      match pfields:
        case Nil{}: [JFail{"the constructor's slots and fields differ"}]
        case +field <> +rest_fields:
          match slot:
            case CLay.NodeSlot{ordinal, offset, layout}:
              match field:
                case Operand{use, text}:
                  tag = join_text(["s", U32.show(ordinal)])
                  code = operand_code(layout, use, text, tag)
                  term = operand_name(layout, use, text, tag)
                  List.append(&2, Job, code_jobs(code), List.append(&2, Job, fill_jobs(pw, layout, term, DstSeq{"w0", "o0"}, tag), fill_slots_jobs(pw, rest, rest_fields)))

def layout_is_data(+playout: CLay.Layout) -> Bool:
  match playout:
    case CLay.LayoutData{words, arms}: True{}
    case _: False{}

def seal_box_many(+pcur: String, +pfrom_data: Bool) -> List<&2, Job>:
  match pfrom_data:
    case True{}: [JText{join_text([pcur, " += 1;"])}]
    case False{}: [JText{join_text(["w0[", pcur, "] = term_keep(e, w0[", pcur, "], 1); ", pcur, " += 1;"])}]

def seal_box(+puse: BIR.Use, +pcur: String, +pfrom_data: Bool) -> List<&2, Job>:
  match puse:
    case BIR.Many{}: seal_box_many(pcur, pfrom_data)
    case _: [JText{join_text(["w0[", pcur, "] = rfc_seal(e, w0[", pcur, "]); ", pcur, " += 1;"])}]

def seal_kind(+puse: BIR.Use, +pkind: CLay.CWord, +pcur: String, +pfrom_data: Bool) -> List<&2, Job>:
  match pkind:
    case CLay.CWord32{}: [JText{join_text([pcur, " += 1;"])}]
    case CLay.CWord64{}: [JText{join_text([pcur, " += 1;"])}]
    case CLay.CWordBox{}: seal_box(puse, pcur, pfrom_data)

def seal_kind_walk(+puse: BIR.Use, +pkinds: List<&2, CLay.CWord>, +pcur: String, +pfrom_data: Bool) -> List<&2, Job>:
  match pkinds:
    case Nil{}: Nil{}
    case +kind <> +rest: List.append(&2, Job, seal_kind(puse, kind, pcur, pfrom_data), seal_kind_walk(puse, rest, pcur, pfrom_data))

def seal_slots_jobs(+pw: World, +pslots: List<&2, CLay.NodeSlot>, +pfields: List<&2, Operand>) -> List<&2, Job>:
  match pslots:
    case Nil{}:
      match pfields:
        case Nil{}: Nil{}
        case _: one_job(JFail{"the constructor's slots and fields differ"})
    case +slot <> +rest:
      match pfields:
        case Nil{}: one_job(JFail{"the constructor's slots and fields differ"})
        case +field <> +rest_fields:
          match slot:
            case CLay.NodeSlot{ordinal, offset, layout}:
              match field:
                case Operand{use, text}:
                  List.append(&2, Job, one_job(JText{String.append(String.append(String.append(String.append("u32 k", U32.show(ordinal)), " = "), Nat.show(offset)), ";")}), List.append(&2, Job, seal_kind_walk(use, CLay.layout_kinds(layout), String.append("k", U32.show(ordinal)), layout_is_data(layout)), seal_slots_jobs(pw, rest, rest_fields)))

def one_job(+pjob: Job) -> List<&2, Job>:
  [pjob]

def construct_words(+pw: World, +pcid: U32, +pcount: Nat, +pslots: List<&2, CLay.NodeSlot>, +poperands: List<&2, Operand>) -> Part:
  jobs = List.append(&2, Job, one_job(JText{dst_decl("w0", "o0", pcount)}), List.append(&2, Job, fill_slots_jobs(pw, pslots, poperands), List.append(&2, Job, seal_slots_jobs(pw, pslots, poperands), one_job(JText{String.append(String.append(String.append(String.append("u64 n0 = heap_alloc(e, cls_fit(", Nat.show(pcount)), ")); for (u32 n0i = 0; n0i < "), Nat.show(pcount)), "; n0i += 1) { e.mem[n0 + n0i] = w0[n0i]; }")}))))
  part_of(run_jobs(jobs, pw, Nil{}), String.append(String.append("term_ctr(", U32.show(pcid)), "u, n0)"))

def codeSeqPack(+pcode: Code, +pw: World, +playout: CLay.Layout, +pterm: String, +pcid: U32) -> Code:
  jobs = List.append(&2, Job, one_job(JText{"u64 w0[1]; w0[0] = 0; u32 o0 = 0;"}), List.append(&2, Job, code_jobs(pcode), fill_jobs(pw, playout, pterm, DstSeq{"w0", "o0"}, "p0")))
  run_jobs(jobs, pw, Nil{})

def construct_packed_one(+pw: World, +pcid: U32, +pslot: CLay.NodeSlot, +pfield: Operand) -> Part:
  match pslot:
    case CLay.NodeSlot{ordinal, offset, layout}:
      match pfield:
        case Operand{use, text}:
          code = operand_code(layout, use, text, "p0")
          term = operand_name(layout, use, text, "p0")
          part_of(codeSeqPack(code, pw, layout, term, pcid), join_text(["term_pak(", U32.show(pcid), "u, (u64)w0[0])"]))

def construct_packed(+pw: World, +pcid: U32, +pkey: String, +pnode: CLay.Node, +poperands: List<&2, Operand>) -> Part:
  match pnode:
    case CLay.Node{words, slots, packed}:
      match slots:
        case Nil{}:
          match poperands:
            case Nil{}: PartOk{join_text(["term_pak(", U32.show(pcid), "u, 0)"])}
            case _: PartFail{join_text(["the constructor `", pkey, "` has an inconsistent packed node"])}
        case +slot <> Nil{}:
          match poperands:
            case +field <> Nil{}: construct_packed_one(pw, pcid, slot, field)
            case _: PartFail{join_text(["the constructor `", pkey, "` has an inconsistent packed node"])}
        case _: PartFail{join_text(["the constructor `", pkey, "` has an inconsistent packed node"])}

def construct_packed_flag(+ppacked: Bool, +pw: World, +pcid: U32, +pkey: String, +pnode: CLay.Node, +poperands: List<&2, Operand>) -> Part:
  match ppacked:
    case True{}: construct_packed(pw, pcid, pkey, pnode, poperands)
    case False{}:
      match pnode:
        case CLay.Node{words, slots, packed}: construct_words(pw, pcid, List.length(&2, CLay.CWord, words), slots, poperands)

def construct_count(+psame: Bool, +pw: World, +pcid: U32, +pkey: String, +pnode: CLay.Node, +poperands: List<&2, Operand>) -> Part:
  match psame:
    case False{}: PartFail{join_text(["the constructor `", pkey, "` has a different live field count than its value arguments"])}
    case True{}:
      match pnode:
        case CLay.Node{words, slots, packed}: construct_packed_flag(packed, pw, pcid, pkey, pnode, poperands)

def construct_node(+pw: World, +pcid: U32, +pkey: String, +pnode: CLay.Node, +poperands: List<&2, Operand>) -> Part:
  match pnode:
    case CLay.Node{words, slots, packed}:
      same = Nat.is_eq(List.length(&2, CLay.NodeSlot, slots), List.length(&2, Operand, poperands))
      construct_count(same, pw, pcid, pkey, pnode, poperands)

def construct_layout(+pnode: CLay.NodeResult, +pw: World, +pcid: U32, +pkey: String, +poperands: List<&2, Operand>) -> Part:
  match pnode:
    case CLay.NodeFailed{message}: PartFail{message}
    case CLay.NodeFound{node}: construct_node(pw, pcid, pkey, node, poperands)

def construct_cid(+pfound: Maybe<&2, U32>, +pw: World, +pkey: String, +poperands: List<&2, Operand>) -> Part:
  match pfound:
    case None{}: PartFail{join_text(["the constructor `", pkey, "` has no canonical CID row"])}
    case Some{cid}:
      match pw:
        case World{ctx, constructors, families, cids}:
          node = CLay.node_layout(ctx, pkey)
          construct_layout(node, pw, cid, pkey, poperands)

def construct_generic(+pw: World, +pkey: String, +poperands: List<&2, Operand>) -> Part:
  found = cid_of(pkey, pw)
  construct_cid(found, pw, pkey, poperands)

def construct_marker(+pintr: Bool, +pw: World, +pkey: String, +poperands: List<&2, Operand>) -> Part:
  match pintr:
    case True{}: PartFail{join_text(["the intrinsic constructor `", pkey, "` must be lowered to its primitive before C emission"])}
    case False{}: construct_generic(pw, pkey, poperands)

def construct_native(+pnative: Maybe<&2, String>, +pw: World, +pkey: String, +poperands: List<&2, Operand>) -> Part:
  match pnative:
    case None{}: construct_generic(pw, pkey, poperands)
    case Some{marker}: construct_marker(intrinsic_marker(marker), pw, pkey, poperands)

def construct_row(+pfound: Maybe<&2, BIR.ConstructorLayout>, +pw: World, +poperands: List<&2, Operand>) -> Part:
  match pfound:
    case None{}: PartFail{"BIR constructs a constructor with no layout row"}
    case Some{row}:
      match row:
        case BIR.ConstructorLayout{id, key, native, fields}: construct_native(native, pw, key, poperands)

def construct_part(+pconstructor: U32, +poperands: List<&2, Operand>, +pw: World) -> Part:
  row = ctor_of(pconstructor, pw)
  construct_row(row, pw, poperands)

def term_decl_text(+pcount: Nat) -> String:
  match pcount:
    case 0n: ""
    case _: join_text(["Term b0f[", Nat.show(pcount), "];"])

def project_prelude(+playout: CLay.Layout, +pvalue: String, +pcount: Nat, +poffset: Nat) -> String:
  head = join_text(["Term b0t = ", pvalue, ";", term_decl_text(pcount), "u64 b0s = term_rfc(b0t) ? ctr_take(e, b0t, ", Nat.show(pcount), ", b0f) : term_loc(b0t); u32 b0i = ", Nat.show(poffset), ";"])
  match playout:
    case CLay.LayoutWord{word}: join_text([head, " Term b0r = 0;"])
    case CLay.LayoutBox{reason}: join_text([head, " Term b0r = 0;"])
    case CLay.LayoutData{words, arms}: head

def project_words(+pw: World, +playout: CLay.Layout, +poffset: Nat, +pcount: Nat, +pvalue: String) -> Part:
  jobs = List.append(&2, Job, one_job(JText{project_prelude(playout, pvalue, pcount, poffset)}), unfill_jobs(pw, playout, SrcNode{"b0s", "b0f", "b0i", False{}}, "b0r", "b0"))
  part_of(run_jobs(jobs, pw, Nil{}), "b0r")

def project_packed_prelude(+playout: CLay.Layout, +pvalue: String) -> String:
  head = join_text(["Term b0t = ", pvalue, ";"])
  match playout:
    case CLay.LayoutWord{word}: join_text([head, " Term b0r = 0;"])
    case CLay.LayoutBox{reason}: join_text([head, " Term b0r = 0;"])
    case CLay.LayoutData{words, arms}: head

def project_packed(+pw: World, +playout: CLay.Layout, +pvalue: String) -> Part:
  jobs = List.append(&2, Job, one_job(JText{project_packed_prelude(playout, pvalue)}), unfill_jobs(pw, playout, SrcOne{"((u64)term_loc(b0t))"}, "b0r", "b0"))
  part_of(run_jobs(jobs, pw, Nil{}), "b0r")

def project_packed_flag(+ppacked: Bool, +pw: World, +playout: CLay.Layout, +poffset: Nat, +pcount: Nat, +pvalue: String) -> Part:
  match ppacked:
    case True{}: project_packed(pw, playout, pvalue)
    case False{}: project_words(pw, playout, poffset, pcount, pvalue)

# Unified borrowed path engine
# ============================
#
# Steps: PathField (constructor + declared field ordinal), PathHalf (low/high
# half of an array value, element Descriptor), PathLeafCell (the single cell of
# an array leaf, element Descriptor). A PathField descends an inline form, a
# boxed Term or a cell; PathHalf/PathLeafCell need an array value. The owner
# chain starts at the root Term and gains every boxed Term/array Term reached;
# effective uniqueness is the conjunction, effective static status the
# disjunction. Only an all-unique non-static chain may clear source cells; a
# static or shared owner forces copy/keep-with-writeback. The parent and
# unselected siblings are never freed here; the root's frame sink drops them.

type PathStep is Data:
  PathField{constructor: U32, field: U32}
  PathHalf{low: Bool, element: BIR.Descriptor}
  PathLeafCell{element: BIR.Descriptor}

type PathState is Data:
  StSlot{offset: Nat, layout: CLay.Layout, base: String, uniq: String, stat: String, packed: Bool}
  StArray{loc: String, cls: String, lgs: Nat, cell: CLay.Layout, arr: String, off: String, buf: Bool, uniq: String, stat: String}
  StCell{loc: String, arr: String, index: String, cls: String, layout: CLay.Layout, lgs: Nat, buf: Bool, uniq: String, stat: String}
  StBufField{loc: String, index: String, layout: CLay.Layout, uniq: String, stat: String}

type PathResult is Data:
  PathOk{state: PathState}
  PathFail{message: String}

def unique_expr(+pterm: String) -> String:
  join_text(["(!term_triv(", pterm, ") && !(term_rfc(", pterm, ") && (a32_load(a32_at(e.mem, term_loc(", pterm, "))) & RFC_CNT) > 1))"])

def static_expr(+pterm: String) -> String:
  join_text(["term_triv(", pterm, ")"])

def and_expr(+pa: String, +pb: String) -> String:
  join_text(["(", pa, " && ", pb, ")"])

def or_expr(+pa: String, +pb: String) -> String:
  join_text(["(", pa, " || ", pb, ")"])

def nat_if(+pcond: Bool, +pa: Nat, +pb: Nat) -> Nat:
  match pcond:
    case True{}: pa
    case False{}: pb

def live_ordinal(+pfields: List<&2, BIR.DescriptorField>, +pwant: U32) -> Maybe<&2, U32>:
  live_walk(pfields, U32.to_nat(pwant), 0n, 0n)

def live_walk(+pfields: List<&2, BIR.DescriptorField>, +pwant: Nat, +pat: Nat, +plive: Nat) -> Maybe<&2, U32>:
  match pfields:
    case Nil{}: None{}
    case +field <> rest:
      match field:
        case BIR.DescriptorField{key, quantity, ty}:
          match Nat.is_eq(pat, pwant):
            case True{}:
              match quantity:
                case BIR.Erased{}: None{}
                case _: Some{U32.from_nat(plive)}
            case False{}: live_walk(rest, pwant, Nat.add(pat, 1n), live_next(quantity, plive))

def live_next(+pquantity: BIR.Quantity, +plive: Nat) -> Nat:
  match pquantity:
    case BIR.Erased{}: plive
    case _: Nat.add(plive, 1n)

def arm_fields_of(+parms: List<&2, CLay.LayArm>, +pkey: String) -> Maybe<&2, List<&2, CLay.Layout>>:
  match parms:
    case Nil{}: None{}
    case +arm <> rest:
      match arm:
        case CLay.LayArm{key, fields}:
          same = String.eq(key, pkey)
          Bool.pick(Maybe<&2, List<&2, CLay.Layout>>, same, Some{fields}, arm_fields_of(rest, pkey))

def arm_descriptor_fields(+pw: World, +pkey: String) -> Maybe<&2, List<&2, BIR.DescriptorField>>:
  match pw:
    case World{ctx, constructors, families, cids}: family_arm_fields(families, pkey)

def family_arm_fields(+pfamilies: List<&2, BIR.Family>, +pkey: String) -> Maybe<&2, List<&2, BIR.DescriptorField>>:
  match pfamilies:
    case Nil{}: None{}
    case +family <> rest:
      match family:
        case BIR.Family{key, name, native, quantity_prefix, arity, arms}:
          match descriptor_arm_fields(arms, pkey):
            case None{}: family_arm_fields(rest, pkey)
            case Some{fields}: Some{fields}

def descriptor_arm_fields(+parms: List<&2, BIR.DescriptorArm>, +pkey: String) -> Maybe<&2, List<&2, BIR.DescriptorField>>:
  match parms:
    case Nil{}: None{}
    case +arm <> rest:
      match arm:
        case BIR.DescriptorArm{key, fields}:
          same = String.eq(key, pkey)
          Bool.pick(Maybe<&2, List<&2, BIR.DescriptorField>>, same, Some{fields}, descriptor_arm_fields(rest, pkey))

def step_key(+pw: World, +pconstructor: U32) -> Maybe<&2, String>:
  match ctor_of(pconstructor, pw):
    case None{}: None{}
    case Some{row}:
      match row:
        case BIR.ConstructorLayout{id, key, native, fields}: Some{key}

def cell_lgs(+pw: World, +pelement: BIR.Descriptor) -> Maybe<&2, CLay.Cell>:
  match pw:
    case World{ctx, constructors, families, cids}:
      match CLay.array_cell(ctx, pelement):
        case CLay.CellFailed{message}: None{}
        case CLay.CellFound{cell}: Some{cell}


def not_bool(+pb: Bool) -> Bool:
  match pb:
    case True{}: False{}
    case False{}: True{}

def live_ordinal_in(+pfields: List<&2, BIR.DescriptorField>, +pindex: U32, +pdeclared: U32, +plive: U32) -> Maybe<&2, U32>:
  match pfields:
    case Nil{}: None{}
    case +field <> rest:
      match field:
        case BIR.DescriptorField{key, quantity, ty}:
          match U32.is_eq(pindex, pdeclared):
            case True{}:
              match CLay.live_field(quantity):
                case True{}: Some{plive}
                case False{}: None{}
            case False{}:
              match CLay.live_field(quantity):
                case True{}: live_ordinal_in(rest, U32.inc(pindex), pdeclared, U32.inc(plive))
                case False{}: live_ordinal_in(rest, U32.inc(pindex), pdeclared, plive)

def inline_slot(+playouts: List<&2, CLay.Layout>, +plive: Nat, +pat: Nat) -> Maybe<&2, CLay.NodeSlot>:
  match playouts:
    case Nil{}: None{}
    case +layout <> rest:
      match plive:
        case 0n: Some{CLay.NodeSlot{0, pat, layout}}
        case 1n+p: inline_slot(rest, p, Nat.add(pat, CLay.layout_words(layout)))

def inline_start(+parms: List<&2, CLay.LayArm>) -> Nat:
  match Nat.is_gt(List.length(&2, CLay.LayArm, parms), 1n):
    case True{}: 1n
    case False{}: 0n

def state_array(+pw: World, +pterm: String, +puniq: String, +pstat: String, +pelement: BIR.Descriptor) -> PathResult:
  match cell_lgs(pw, pelement):
    case None{}: PathFail{"the array element has no cell layout"}
    case Some{cell}:
      match cell:
        case CLay.Cell{layout, arr, words, lgs}:
          PathOk{StArray{join_text(["blk_loc(e.mem, ", pterm, ")"]), join_text(["((u32)blk_cls(", pterm, "))"]), lgs, layout, join_text(["(term_tag(", pterm, ") == TAG_ARR)"]), "0", not_bool(arr), puniq, pstat}}

def state_from_array_value(+pw: World, +pterm: String, +puniq: String, +pstat: String, +pelement: BIR.Descriptor) -> PathResult:
  state_array(pw, pterm, and_expr(puniq, unique_expr(pterm)), or_expr(pstat, static_expr(pterm)), pelement)

def resolve_field(+pw: World, +pstate: PathState, +pconstructor: U32, +pfield: U32, +prest: List<&2, PathStep>) -> PathResult:
  match step_key(pw, pconstructor):
    case None{}: PathFail{join_text(["BIR projects constructor ", U32.show(pconstructor), " with no layout row"])}
    case Some{key}:
      match pstate:
        case StSlot{offset, layout, base, uniq, stat, packed}:
          resolve_slot_field(pw, key, pfield, offset, layout, base, uniq, stat, packed, prest)
        case StCell{loc, arr, index, cls, layout, lgs, buf, uniq, stat}:
          resolve_cell_field(pw, key, pfield, loc, buf, index, layout, lgs, uniq, stat, prest)
        case StBufField{loc, index, layout, uniq, stat}:
          resolve_buf_field(pw, key, pfield, loc, index, layout, uniq, stat, prest)
        case StArray{loc, cls, lgs, cell, arr, off, buf, uniq, stat}: PathFail{"a Project on an array value needs an element leaf-cell step"}

def resolve_slot_field(+pw: World, +pkey: String, +pdeclared: U32, +poffset: Nat, +playout: CLay.Layout, +pbase: String, +puniq: String, +pstat: String, +ppacked: Bool, +prest: List<&2, PathStep>) -> PathResult:
  match ppacked:
    case True{}:
      match playout:
        case CLay.LayoutData{words, arms}:
          match arm_fields_of(arms, pkey):
            case None{}: PathFail{join_text(["the packed form has no arm `", pkey, "`"])}
            case Some{layouts}:
              match arm_descriptor_fields(pw, pkey):
                case None{}: PathFail{join_text(["the packed arm `", pkey, "` has no declared fields"])}
                case Some{birfields}:
                  match live_ordinal_in(birfields, U32.from_nat(0n), pdeclared, U32.from_nat(0n)):
                    case None{}: PathFail{join_text(["the projection of `", pkey, "` names an erased packed field"])}
                    case Some{live}:
                      match inline_slot(layouts, U32.to_nat(live), 0n):
                        case None{}: PathFail{join_text(["the packed arm `", pkey, "` has no live field ", U32.show(pdeclared)])}
                        case Some{slot}:
                          match slot:
                            case CLay.NodeSlot{ordinal, offset, layout}: advance(pw, StSlot{0n, layout, pbase, puniq, pstat, True{}}, prest)
        case CLay.LayoutWord{word}: PathFail{"a raw packed word has no nested projection"}
        case CLay.LayoutBox{reason}: PathFail{"a packed value cannot hold a boxed field"}
    case False{}:
      match playout:
        case CLay.LayoutData{words, arms}:
          match arm_fields_of(arms, pkey):
            case None{}: PathFail{join_text(["the inline form has no arm `", pkey, "`"])}
            case Some{layouts}:
              match arm_descriptor_fields(pw, pkey):
                case None{}: PathFail{join_text(["the inline arm `", pkey, "` has no declared fields"])}
                case Some{birfields}:
                  match live_ordinal_in(birfields, U32.from_nat(0n), pdeclared, U32.from_nat(0n)):
                    case None{}: PathFail{join_text(["the projection of `", pkey, "` names an erased field"])}
                    case Some{live}:
                      match inline_slot(layouts, U32.to_nat(live), inline_start(arms)):
                        case None{}: PathFail{join_text(["the inline arm `", pkey, "` has no live field ", U32.show(pdeclared)])}
                        case Some{slot}:
                          match slot:
                            case CLay.NodeSlot{ordinal, offset, layout}: advance(pw, StSlot{Nat.add(poffset, offset), layout, pbase, puniq, pstat, False{}}, prest)
        case CLay.LayoutBox{reason}:
          at = join_text(["e.mem[", pbase, " + ", Nat.show(poffset), "]"])
          resolve_node_slot(pw, pkey, pdeclared, 0n, join_text(["term_peek(e.mem, (", at, "))"]), and_expr(puniq, unique_expr(at)), or_expr(pstat, static_expr(at)), prest)
        case CLay.LayoutWord{word}: PathFail{"a nested Project path continues through a raw word"}

def resolve_cell_field(+pw: World, +pkey: String, +pdeclared: U32, +ploc: String, +pbuf: Bool, +pindex: String, +playout: CLay.Layout, +plgs: Nat, +puniq: String, +pstat: String, +prest: List<&2, PathStep>) -> PathResult:
  match playout:
    case CLay.LayoutBox{reason}:
      match pbuf:
        case True{}: PathFail{"a BUF array cell cannot contain a boxed field"}
        case False{}: resolve_slot_field(pw, pkey, pdeclared, 0n, playout, join_text([ploc, " + (", pindex, ")"]), puniq, pstat, False{}, prest)
    case CLay.LayoutData{words, arms}:
      match arm_fields_of(arms, pkey):
        case None{}: PathFail{join_text(["the inline cell has no arm `", pkey, "`"])}
        case Some{layouts}:
          match arm_descriptor_fields(pw, pkey):
            case None{}: PathFail{join_text(["the inline cell arm `", pkey, "` has no declared fields"])}
            case Some{birfields}:
              match live_ordinal_in(birfields, U32.from_nat(0n), pdeclared, U32.from_nat(0n)):
                case None{}: PathFail{join_text(["the projection of `", pkey, "` names an erased cell field"])}
                case Some{live}:
                  match inline_slot(layouts, U32.to_nat(live), inline_start(arms)):
                    case None{}: PathFail{join_text(["the inline cell arm `", pkey, "` has no live field ", U32.show(pdeclared)])}
                    case Some{slot}:
                      match slot:
                        case CLay.NodeSlot{ordinal, offset, layout}:
                          match pbuf:
                            case True{}: advance(pw, StBufField{ploc, join_text([pindex, " + ", Nat.show(offset)]), layout, puniq, pstat}, prest)
                            case False{}: advance(pw, StSlot{offset, layout, join_text([ploc, " + (", pindex, ")"]), puniq, pstat, False{}}, prest)
    case CLay.LayoutWord{word}: PathFail{"a nested Project path continues through a raw cell word"}

def resolve_buf_field(+pw: World, +pkey: String, +pdeclared: U32, +ploc: String, +pindex: String, +playout: CLay.Layout, +puniq: String, +pstat: String, +prest: List<&2, PathStep>) -> PathResult:
  match playout:
    case CLay.LayoutData{words, arms}:
      match arm_fields_of(arms, pkey):
        case None{}: PathFail{join_text(["the BUF inline form has no arm `", pkey, "`"])}
        case Some{layouts}:
          match arm_descriptor_fields(pw, pkey):
            case None{}: PathFail{join_text(["the BUF inline arm `", pkey, "` has no declared fields"])}
            case Some{birfields}:
              match live_ordinal_in(birfields, U32.from_nat(0n), pdeclared, U32.from_nat(0n)):
                case None{}: PathFail{join_text(["the projection of `", pkey, "` names an erased BUF field"])}
                case Some{live}:
                  match inline_slot(layouts, U32.to_nat(live), inline_start(arms)):
                    case None{}: PathFail{join_text(["the BUF inline arm `", pkey, "` has no live field ", U32.show(pdeclared)])}
                    case Some{slot}:
                      match slot:
                        case CLay.NodeSlot{ordinal, offset, layout}: advance(pw, StBufField{ploc, join_text([pindex, " + ", Nat.show(offset)]), layout, puniq, pstat}, prest)
    case CLay.LayoutBox{reason}: PathFail{"a BUF inline form cannot hold a boxed field"}
    case CLay.LayoutWord{word}: PathFail{"a BUF raw word has no nested projection"}

def resolve_node_slot(+pw: World, +pkey: String, +pdeclared: U32, +pstart: Nat, +pbase: String, +puniq: String, +pstat: String, +prest: List<&2, PathStep>) -> PathResult:
  match pw:
    case World{ctx, constructors, families, cids}:
      match CLay.node_slot(ctx, pkey, pdeclared):
        case CLay.SlotErased{}: PathFail{join_text(["the projection of `", pkey, "` names an erased field"])}
        case CLay.SlotFailed{message}: PathFail{message}
        case CLay.SlotFound{slot}:
          match slot:
            case CLay.NodeSlot{ordinal, offset, layout}: advance(pw, StSlot{Nat.add(pstart, offset), layout, pbase, puniq, pstat, False{}}, prest)

def root_array_path(+pw: World, +pelement: BIR.Descriptor, +psteps: List<&2, PathStep>) -> PathResult:
  match state_from_array_value(pw, "pbt", unique_expr("pbt"), static_expr("pbt"), pelement):
    case PathFail{message}: PathFail{message}
    case PathOk{state}: advance(pw, state, psteps)

def advance(+pw: World, +pstate: PathState, +psteps: List<&2, PathStep>) -> PathResult:
  match psteps:
    case Nil{}: PathOk{pstate}
    case +step <> rest:
      match step:
        case PathField{constructor, field}:
          match resolve_field(pw, pstate, constructor, field, rest):
            case PathFail{message}: PathFail{message}
            case PathOk{state}: PathOk{state}
        case PathHalf{low, element}:
          match half_state(pw, pstate, low, element, rest):
            case PathFail{message}: PathFail{message}
            case PathOk{state}: advance(pw, state, rest)
        case PathLeafCell{element}:
          match leaf_state(pw, pstate, element, rest):
            case PathFail{message}: PathFail{message}
            case PathOk{state}: advance(pw, state, rest)

def array_from_state(+pw: World, +pstate: PathState, +pelement: BIR.Descriptor) -> PathResult:
  match pstate:
    case StArray{loc, cls, lgs, cell, arr, off, buf, uniq, stat}: PathOk{pstate}
    case StSlot{offset, layout, base, uniq, stat, packed}:
      match layout:
        case CLay.LayoutBox{reason}:
          term = join_text(["e.mem[", base, " + ", Nat.show(offset), "]"])
          state_from_array_value(pw, term, uniq, stat, pelement)
        case _: PathFail{"an array half or leaf needs a boxed array value"}
    case StCell{loc, arr, index, cls, layout, lgs, buf, uniq, stat}:
      match layout:
        case CLay.LayoutBox{reason}:
          term = join_text(["blk_read(e.mem, ", arr, ", ", loc, ", (u32)(", index, "))"])
          state_from_array_value(pw, term, uniq, stat, pelement)
        case _: PathFail{"an array half or leaf needs a boxed array element"}
    case StBufField{loc, index, layout, uniq, stat}: PathFail{"an array half or leaf needs a boxed array element"}

def half_state(+pw: World, +pstate: PathState, +plow: Bool, +pelement: BIR.Descriptor, +prest: List<&2, PathStep>) -> PathResult:
  match array_from_state(pw, pstate, pelement):
    case PathFail{message}: PathFail{message}
    case PathOk{array_state}:
      match array_state:
        case StArray{loc, cls, lgs, cell, arr, off, buf, uniq, stat}:
          newoff = join_text(["(u64)((", off, ") + ", Bool.pick(String, plow, "0", join_text(["(1ull << ((", cls, ") - 1))"])), ")"])
          newcls = join_text(["((", cls, ") - 1)"])
          PathOk{StArray{loc, newcls, lgs, cell, arr, newoff, buf, uniq, stat}}
        case _: PathFail{"not an array state"}

def leaf_state(+pw: World, +pstate: PathState, +pelement: BIR.Descriptor, +prest: List<&2, PathStep>) -> PathResult:
  match array_from_state(pw, pstate, pelement):
    case PathFail{message}: PathFail{message}
    case PathOk{array_state}:
      match array_state:
        case StArray{loc, cls, lgs, cell, arr, off, buf, uniq, stat}: PathOk{StCell{loc, arr, off, cls, cell, lgs, buf, uniq, stat}}
        case _: PathFail{"not an array state"}

def resolve_path(+pw: World, +psteps: List<&2, PathStep>) -> PathResult:
  match psteps:
    case Nil{}: PathFail{"a Project path is empty"}
    case +first <> rest:
      match first:
        case PathField{constructor, field}:
          match step_key(pw, constructor):
            case None{}: PathFail{join_text(["BIR projects constructor ", U32.show(constructor), " with no layout row"])}
            case Some{key}:
              match pw:
                case World{ctx, constructors, families, cids}:
                  match CLay.node_layout(ctx, key):
                    case CLay.NodeFailed{message}: PathFail{message}
                    case CLay.NodeFound{found}:
                      match found:
                        case CLay.Node{words, slots, packed}:
                          match packed:
                            case True{}:
                              match CLay.node_slot(ctx, key, field):
                                case CLay.SlotFound{slot}:
                                  match slot:
                                    case CLay.NodeSlot{ordinal, offset, layout}: advance(pw, StSlot{0n, layout, "pbn", "0", "1", True{}}, rest)
                                case CLay.SlotErased{}: PathFail{"a packed projection names an erased field"}
                                case CLay.SlotFailed{message}: PathFail{message}
                            case False{}:
                              resolve_node_slot(pw, key, field, 0n, "pbn", unique_expr("pbt"), static_expr("pbt"), rest)
        case PathHalf{low, element}: root_array_path(pw, element, psteps)
        case PathLeafCell{element}: root_array_path(pw, element, psteps)

def path_prelude(+proot: String) -> String:
  join_text(["Term pbt = (", proot, "); u64 pbn = term_peek(e.mem, pbt); Term pbr = 0; "])

def path_expr(+proot: String, +pbody: String) -> String:
  join_text(["({\n", path_prelude(proot), pbody, "pbr;\n})"])

# A laid-out cell/form copy. pbase is the payload/block address expression.
def keep_copy(+pbase: String, +punique: String, +pstatic: String, +pslot: Nat, +pabs: Nat, +playout: CLay.Layout, +pindent: String) -> String:
  match playout:
    case CLay.LayoutWord{word}:
      join_text([pindent, "pbbuf[", Nat.show(Nat.sub(pabs, pslot)), "] = e.mem[", pbase, " + ", Nat.show(pabs), "];\n"])
    case CLay.LayoutBox{reason}:
      at = join_text(["e.mem[", pbase, " + ", Nat.show(pabs), "]"])
      join_text([pindent, "{ Term pbb = term_keep(e, ", at, ", 1); if (pbb != ", at, ") { if (", pstatic, ") { (void)err_fail(\"a static image would need a keep wrapper\"); } else if (!", punique, ") { (void)err_fail(\"a shared owner has an unsealed cell child\"); } else { ", at, " = pbb; } } pbbuf[", Nat.show(Nat.sub(pabs, pslot)), "] = (u64)pbb; }\n"])
    case CLay.LayoutData{words, arms}:
      match arms:
        case Nil{}: ""
        case +only <> Nil{}:
          match only:
            case CLay.LayArm{key, fields}: keep_copy_fields(pbase, punique, pstatic, pslot, pabs, fields, pindent)
        case _:
          join_text([pindent, "pbbuf[", Nat.show(Nat.sub(pabs, pslot)), "] = e.mem[", pbase, " + ", Nat.show(pabs), "];\n", pindent, "switch ((u32)e.mem[", pbase, " + ", Nat.show(pabs), "]) {\n", keep_copy_cases(pbase, punique, pstatic, pslot, Nat.add(pabs, 1n), arms, pindent, 0n), pindent, "}\n"])

def keep_copy_fields(+pbase: String, +punique: String, +pstatic: String, +pslot: Nat, +pabs: Nat, +fields: List<&2, CLay.Layout>, +pindent: String) -> String:
  match fields:
    case Nil{}: ""
    case +layout <> rest:
      join_text([keep_copy(pbase, punique, pstatic, pslot, pabs, layout, pindent), keep_copy_fields(pbase, punique, pstatic, pslot, Nat.add(pabs, CLay.layout_words(layout)), rest, pindent)])

def keep_copy_cases(+pbase: String, +punique: String, +pstatic: String, +pslot: Nat, +pabs: Nat, +parms: List<&2, CLay.LayArm>, +pindent: String, +pindex: Nat) -> String:
  match parms:
    case Nil{}: join_text([pindent, "default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;\n"])
    case +arm <> rest:
      match arm:
        case CLay.LayArm{key, fields}:
          join_text([pindent, "case ", Nat.show(pindex), ": {\n", keep_copy_fields(pbase, punique, pstatic, pslot, pabs, fields, join_text([pindent, "  "])), pindent, "} break;\n", keep_copy_cases(pbase, punique, pstatic, pslot, pabs, rest, pindent, Nat.add(pindex, 1n))])

def move_copy(+pbase: String, +pslot: Nat, +pabs: Nat, +playout: CLay.Layout, +pindent: String) -> String:
  match playout:
    case CLay.LayoutWord{word}: join_text([pindent, "pbbuf[", Nat.show(Nat.sub(pabs, pslot)), "] = e.mem[", pbase, " + ", Nat.show(pabs), "];\n"])
    case CLay.LayoutBox{reason}: join_text([pindent, "pbbuf[", Nat.show(Nat.sub(pabs, pslot)), "] = e.mem[", pbase, " + ", Nat.show(pabs), "]; e.mem[", pbase, " + ", Nat.show(pabs), "] = 0;\n"])
    case CLay.LayoutData{words, arms}:
      match arms:
        case Nil{}: ""
        case +only <> Nil{}:
          match only:
            case CLay.LayArm{key, fields}: move_copy_fields(pbase, pslot, pabs, fields, pindent)
        case _:
          join_text([pindent, "pbbuf[", Nat.show(Nat.sub(pabs, pslot)), "] = e.mem[", pbase, " + ", Nat.show(pabs), "];\n", pindent, "switch ((u32)e.mem[", pbase, " + ", Nat.show(pabs), "]) {\n", move_copy_cases(pbase, pslot, Nat.add(pabs, 1n), arms, pindent, 0n), pindent, "}\n"])

def move_copy_fields(+pbase: String, +pslot: Nat, +pabs: Nat, +fields: List<&2, CLay.Layout>, +pindent: String) -> String:
  match fields:
    case Nil{}: ""
    case +layout <> rest:
      join_text([move_copy(pbase, pslot, pabs, layout, pindent), move_copy_fields(pbase, pslot, Nat.add(pabs, CLay.layout_words(layout)), rest, pindent)])

def move_copy_cases(+pbase: String, +pslot: Nat, +pabs: Nat, +parms: List<&2, CLay.LayArm>, +pindent: String, +pindex: Nat) -> String:
  match parms:
    case Nil{}: join_text([pindent, "default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;\n"])
    case +arm <> rest:
      match arm:
        case CLay.LayArm{key, fields}:
          join_text([pindent, "case ", Nat.show(pindex), ": {\n", move_copy_fields(pbase, pslot, pabs, fields, join_text([pindent, "  "])), pindent, "} break;\n", move_copy_cases(pbase, pslot, pabs, rest, pindent, Nat.add(pindex, 1n))])

def raw_word_expr(+pbase: String, +poffset: Nat, +pword: CLay.CWord) -> String:
  read = join_text(["e.mem[", pbase, " + ", Nat.show(poffset), "]"])
  match pword:
    case CLay.CWord32{}: join_text(["((u64)(u32)(", read, "))"])
    case _: read

# A packed inline form is one canonical Term of its arm. The layout plan
# already says how the laid-out word is read back: a nullary arm has no word,
# a one-w32 arm carries its word in term_pak, and every arm with a boxed or
# wider field would need an allocating node, which a borrowed view cannot do
# without taking ownership from the source. Only the exactly-one-w32 form is
# therefore a nonallocating canonical view.
def packed_form_body(+pw: World, +playout: CLay.Layout, +psource: String) -> Part:
  match playout:
    case CLay.LayoutData{words, arms}:
      match words:
        case Nil{}: zero_value_body(pw, playout)
        case +word <> Nil{}:
          match word:
            case CLay.CWord32{}:
              jobs = unfill_jobs(pw, playout, SrcOne{psource}, "pbl", "pblc")
              part = part_of(run_jobs(jobs, pw, Nil{}), "pbl")
              match part:
                case PartFail{message}: PartFail{message}
                case PartOk{text}: PartOk{join_text(["{ Term pbl = 0; ", text, "; pbr = pbl; }\n"])}
            case _: PartFail{"an inline form with a boxed or wider field has no nonallocating canonical Term read; use a typed consumer"}
        case _: PartFail{"a multiword inline form has no nonallocating canonical Term read; use a typed consumer"}
    case _: PartFail{"a packed form read needs a data layout"}

def read_body(+pw: World, +pstate: PathState) -> Part:
  match pstate:
    case StSlot{offset, layout, base, uniq, stat, packed}:
      match packed:
        case True{}:
          match layout:
            case CLay.LayoutWord{word}:
              match word:
                case CLay.CWord32{}: PartOk{"pbr = ((u64)(u32)pbn);\n"}
                case _: PartOk{"pbr = pbn;\n"}
            case CLay.LayoutData{words, arms}: packed_data_value(pw, layout)
            case CLay.LayoutBox{reason}: PartFail{"a packed value has no boxed field"}
        case False{}:
          match layout:
            case CLay.LayoutWord{word}: PartOk{join_text(["pbr = ", raw_word_expr(base, offset, word), ";\n"])}
            case CLay.LayoutBox{reason}: PartOk{join_text(["pbr = e.mem[", base, " + ", Nat.show(offset), "];\n"])}
            case CLay.LayoutData{words, arms}:
              match words:
                case Nil{}: packed_form_body(pw, layout, "0")
                case +word <> rest: packed_form_body(pw, layout, raw_word_expr(base, offset, word))
    case StArray{loc, cls, lgs, cell, arr, off, buf, uniq, stat}:
      PartOk{join_text(["if (", arr, ") { pbr = term_blk(true, (u32)(", cls, "), (u64)((u64)(", loc, ") + (u64)(", off, "))); } else { u64 pboff = (u64)(", off, "); if ((pboff & 1ull) != 0ull) { (void)err_fail(\"a mid-block BUF cell has no Term view; a consumer must read it through blk_read\"); } pbr = term_blk(false, (u32)(", cls, "), (u64)((u64)(", loc, ") + (pboff >> 1))); }\n"])}
    case StCell{loc, arr, index, cls, layout, lgs, buf, uniq, stat}:
      match layout:
        case CLay.LayoutWord{word}:
          match word:
            case CLay.CWord32{}: PartOk{join_text(["pbr = ((u64)(u32)(blk_read(e.mem, ", arr, ", ", loc, ", (u32)(", index, "))));\n"])}
            case _: PartOk{join_text(["pbr = (u64)(blk_read(e.mem, ", arr, ", ", loc, ", (u32)(", index, ")));\n"])}
        case CLay.LayoutBox{reason}:
          match buf:
            case True{}: PartFail{"a BUF array cell cannot contain a boxed field"}
            case False{}: PartOk{join_text(["pbr = blk_read(e.mem, ", arr, ", ", loc, ", (u32)(", index, "));\n"])}
        case CLay.LayoutData{words, arms}: packed_form_body(pw, layout, join_text(["blk_read(e.mem, ", arr, ", ", loc, ", (u32)(", index, "))"]))
    case StBufField{loc, index, layout, uniq, stat}:
      match layout:
        case CLay.LayoutWord{word}:
          match word:
            case CLay.CWord32{}: PartOk{join_text(["pbr = ((u64)(u32)blk_read(e.mem, false, ", loc, ", (u32)(", index, ")));\n"])}
            case _: PartFail{"a BUF raw field is not one w32 cell"}
        case CLay.LayoutData{words, arms}: packed_form_body(pw, layout, join_text(["blk_read(e.mem, false, ", loc, ", (u32)(", index, "))"]))
        case CLay.LayoutBox{reason}: PartFail{"a BUF inline form cannot hold a box"}

def tag_single(+pw: World, +pkey: String, +pexpected: Maybe<&2, U32>, +ptarget: String) -> Part:
  match cid_of(pkey, pw):
    case None{}: PartFail{join_text(["the arm `", pkey, "` has no canonical CID"])}
    case Some{cid}:
      match pexpected:
        case None{}: PartOk{join_text([ptarget, " = ", U32.show(cid), "u;\n"])}
        case Some{want}: PartOk{join_text([ptarget, " = (", U32.show(cid), "u == ", U32.show(want), "u);\n"])}

def tag_multi(+pw: World, +pbase: String, +poffset: Nat, +parms: List<&2, CLay.LayArm>, +pexpected: Maybe<&2, U32>, +pindex: Nat, +pacc: String, +ptarget: String) -> Part:
  match parms:
    case Nil{}: PartOk{join_text(["switch ((u32)e.mem[", pbase, " + ", Nat.show(poffset), "]) {\n", pacc, "default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;\n}\n"])}
    case +arm <> rest:
      match arm:
        case CLay.LayArm{key, fields}:
          match cid_of(key, pw):
            case None{}: PartFail{join_text(["the arm `", key, "` has no canonical CID"])}
            case Some{cid}: tag_multi(pw, pbase, poffset, rest, pexpected, Nat.add(pindex, 1n), tag_case_line(pacc, pindex, cid, pexpected, ptarget), ptarget)

def tag_case_line(+pacc: String, +pindex: Nat, +pcid: U32, +pexpected: Maybe<&2, U32>, +ptarget: String) -> String:
  match pexpected:
    case None{}: join_text([pacc, "case ", Nat.show(pindex), ": ", ptarget, " = ", U32.show(pcid), "u; break;\n"])
    case Some{want}: join_text([pacc, "case ", Nat.show(pindex), ": ", ptarget, " = (", U32.show(pcid), "u == ", U32.show(want), "u); break;\n"])


def tag_multi_packed(+pw: World, +parms: List<&2, CLay.LayArm>, +pexpected: Maybe<&2, U32>, +ptarget: String) -> Part:
  tag_multi_packed_go(pw, parms, pexpected, 0n, "", ptarget)

def tag_multi_packed_go(+pw: World, +parms: List<&2, CLay.LayArm>, +pexpected: Maybe<&2, U32>, +pindex: Nat, +pacc: String, +ptarget: String) -> Part:
  match parms:
    case Nil{}: PartOk{join_text(["switch ((u32)pbn) {\n", pacc, "default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;\n}\n"])}
    case +arm <> rest:
      match arm:
        case CLay.LayArm{key, fields}:
          match cid_of(key, pw):
            case None{}: PartFail{join_text(["the arm `", key, "` has no canonical CID"])}
            case Some{cid}: tag_multi_packed_go(pw, rest, pexpected, Nat.add(pindex, 1n), tag_case_line(pacc, pindex, cid, pexpected, ptarget), ptarget)

def tag_multi_buf(+pw: World, +ploc: String, +pindex: String, +parms: List<&2, CLay.LayArm>, +pexpected: Maybe<&2, U32>, +ptarget: String) -> Part:
  tag_multi_buf_go(pw, ploc, pindex, parms, pexpected, 0n, "", ptarget)

def tag_multi_buf_go(+pw: World, +ploc: String, +pindex: String, +parms: List<&2, CLay.LayArm>, +pexpected: Maybe<&2, U32>, +pindexn: Nat, +pacc: String, +ptarget: String) -> Part:
  match parms:
    case Nil{}: PartOk{join_text(["switch ((u32)blk_read(e.mem, false, ", ploc, ", (u32)(", pindex, "))) {\n", pacc, "default: (void)err_fail(\"the constructor tag is not a declared constructor\"); break;\n}\n"])}
    case +arm <> rest:
      match arm:
        case CLay.LayArm{key, fields}:
          match cid_of(key, pw):
            case None{}: PartFail{join_text(["the arm `", key, "` has no canonical CID"])}
            case Some{cid}: tag_multi_buf_go(pw, ploc, pindex, rest, pexpected, Nat.add(pindexn, 1n), tag_case_line(pacc, pindexn, cid, pexpected, ptarget), ptarget)


def tag_body(+pw: World, +pstate: PathState, +pexpected: Maybe<&2, U32>, +ptarget: String) -> Part:
  match pstate:
    case StSlot{offset, layout, base, uniq, stat, packed}:
      match packed:
        case True{}:
          match layout:
            case CLay.LayoutData{words, arms}:
              match arms:
                case +only <> Nil{}:
                  match only:
                    case CLay.LayArm{key, fields}: tag_single(pw, key, pexpected, ptarget)
                case _: tag_multi_packed(pw, arms, pexpected, ptarget)
            case _: PartFail{"a packed word is not a constructor tag"}
        case False{}:
          match layout:
            case CLay.LayoutData{words, arms}:
              match arms:
                case Nil{}: PartFail{"a data layout has no arms"}
                case +only <> Nil{}:
                  match only:
                    case CLay.LayArm{key, fields}: tag_single(pw, key, pexpected, ptarget)
                case _: tag_multi(pw, base, offset, arms, pexpected, 0n, "", ptarget)
            case CLay.LayoutBox{reason}:
              term = join_text(["e.mem[", base, " + ", Nat.show(offset), "]"])
              match pexpected:
                case None{}: PartOk{join_text([ptarget, " = term_aux(", term, ");\n"])}
                case Some{want}: PartOk{join_text([ptarget, " = (term_aux(", term, ") == ", U32.show(want), "u);\n"])}
            case CLay.LayoutWord{word}: PartFail{"a tag test needs a data field"}
    case StCell{loc, arr, index, cls, layout, lgs, buf, uniq, stat}:
      match layout:
        case CLay.LayoutData{words, arms}:
          match arms:
            case Nil{}: PartFail{"a data layout has no arms"}
            case +only <> Nil{}:
              match only:
                case CLay.LayArm{key, fields}: tag_single(pw, key, pexpected, ptarget)
            case _:
              match buf:
                case True{}: tag_multi_buf(pw, loc, index, arms, pexpected, ptarget)
                case False{}: tag_multi(pw, join_text([loc, " + (", index, ")"]), 0n, arms, pexpected, 0n, "", ptarget)
        case CLay.LayoutBox{reason}:
          term = join_text(["blk_read(e.mem, ", arr, ", ", loc, ", (u32)(", index, "))"])
          match pexpected:
            case None{}: PartOk{join_text([ptarget, " = term_aux(", term, ");\n"])}
            case Some{want}: PartOk{join_text([ptarget, " = (term_aux(", term, ") == ", U32.show(want), "u);\n"])}
        case _: PartFail{"a tag test needs a data field"}
    case StBufField{loc, index, layout, uniq, stat}:
      match layout:
        case CLay.LayoutData{words, arms}:
          match arms:
            case Nil{}: PartFail{"a data layout has no arms"}
            case +only <> Nil{}:
              match only:
                case CLay.LayArm{key, fields}: tag_single(pw, key, pexpected, ptarget)
            case _: tag_multi_buf(pw, loc, index, arms, pexpected, ptarget)
        case _: PartFail{"a tag test needs a data field"}
    case StArray{loc, cls, lgs, cell, arr, off, buf, uniq, stat}: PartFail{"a tag test needs a data field"}

def copy_slot_body(+pw: World, +pstate: PathState) -> Part:
  match pstate:
    case StSlot{offset, layout, base, uniq, stat, packed}:
      match packed:
        case True{}:
          match layout:
            case CLay.LayoutWord{word}:
              match word:
                case CLay.CWord32{}: PartOk{"pbr = ((u64)(u32)pbn);\n"}
                case _: PartOk{"pbr = pbn;\n"}
            case CLay.LayoutData{words, arms}: packed_data_copy(pw, layout)
            case CLay.LayoutBox{reason}: PartFail{"a packed value has no boxed field"}
        case False{}:
          match layout:
            case CLay.LayoutWord{word}: PartOk{join_text(["pbr = ", raw_word_expr(base, offset, word), ";\n"])}
            case CLay.LayoutBox{reason}: box_copy_body(base, offset, uniq, stat)
            case CLay.LayoutData{words, arms}: data_copy_body(pw, layout, base, offset, uniq, stat)
    case _: PartFail{"not a field slot"}

def packed_data_value(+pw: World, +playout: CLay.Layout) -> Part:
  jobs = unfill_jobs(pw, playout, SrcOne{"((u64)pbn)"}, "pbl", "pblc")
  part = part_of(run_jobs(jobs, pw, Nil{}), "pbl")
  match part:
    case PartFail{message}: PartFail{message}
    case PartOk{text}: PartOk{join_text(["{ Term pbl = 0; ", text, "; pbr = pbl; }\n"])}

def packed_data_copy(+pw: World, +playout: CLay.Layout) -> Part:
  jobs = unfill_jobs(pw, playout, SrcOne{"((u64)pbn)"}, "pbl", "pblc")
  part = part_of(run_jobs(jobs, pw, Nil{}), "pbl")
  match part:
    case PartFail{message}: PartFail{message}
    case PartOk{text}: PartOk{join_text(["{ Term pbl = 0; ", text, "; pbr = pbl; }\n"])}

def box_copy_body(+pbase: String, +poffset: Nat, +puniq: String, +pstat: String) -> Part:
  at = join_text(["e.mem[", pbase, " + ", Nat.show(poffset), "]"])
  PartOk{join_text(["{ Term pbb = term_keep(e, ", at, ", 1); if (pbb != ", at, ") { if (", pstat, ") { (void)err_fail(\"a static image would need a keep wrapper\"); } else if (!", puniq, ") { (void)err_fail(\"a shared owner has an unsealed field\"); } else { ", at, " = pbb; } } pbr = pbb; }\n"])}

def data_copy_body(+pw: World, +playout: CLay.Layout, +pbase: String, +poffset: Nat, +puniq: String, +pstat: String) -> Part:
  count = CLay.layout_words(playout)
  match count:
    case 0n: zero_value_body(pw, playout)
    case _:
      jobs = unfill_jobs(pw, playout, SrcNode{"0", "pbbuf", "pbi", False{}}, "pbl", "pblc")
      part = part_of(run_jobs(jobs, pw, Nil{}), "pbl")
      match part:
        case PartFail{message}: PartFail{message}
        case PartOk{text}: PartOk{join_text(["{ Term pbbuf[", Nat.show(count), "]; ", keep_copy(pbase, puniq, pstat, poffset, poffset, playout, ""), "u32 pbi = 0; Term pbl = 0; ", text, "; pbr = pbl; }\n"])}

def zero_value_body(+pw: World, +playout: CLay.Layout) -> Part:
  match playout:
    case CLay.LayoutData{words, arms}:
      match arms:
        case +only <> Nil{}:
          match only:
            case CLay.LayArm{key, fields}:
              match cid_of(key, pw):
                case None{}: PartFail{join_text(["the arm `", key, "` has no canonical CID"])}
                case Some{cid}: PartOk{join_text(["pbr = term_pak(", U32.show(cid), "u, 0);\n"])}
        case _: PartFail{"a zero-word field must have exactly one constructor"}
    case _: PartFail{"a zero-word field is not a data layout"}




def buf_clear_words(+ploc: String, +pindex: String, +pcount: Nat, +pat: Nat, +pindent: String) -> String:
  match Nat.is_eq(pat, pcount):
    case True{}: ""
    case False{}: join_text([pindent, "blk_write(e.mem, false, ", ploc, ", (u32)((", pindex, ") + ", Nat.show(pat), "u), 0);\n", buf_clear_words(ploc, pindex, pcount, Nat.add(pat, 1n), pindent)])

def buf_field_body(+pw: World, +playout: CLay.Layout, +ploc: String, +pindex: String, +pmove: Bool) -> Part:
  match playout:
    case CLay.LayoutWord{word}:
      match word:
        case CLay.CWord32{}:
          read = join_text(["((u64)(u32)blk_read(e.mem, false, ", ploc, ", (u32)(", pindex, ")))"])
          clear = buf_move_clear(ploc, pindex, 1n, pmove)
          PartOk{join_text(["pbr = ", read, "; ", clear, "\n"])}
        case _: PartFail{"a BUF raw field is not one w32 cell"}
    case CLay.LayoutData{words, arms}:
      match words:
        case Nil{}: zero_value_body(pw, playout)
        case _:
          jobs = unfill_jobs(pw, playout, SrcBlock{ploc, pindex, False{}, False{}, "pbc"}, "pbl", "pblc")
          match part_of(run_jobs(jobs, pw, Nil{}), "pbl"):
            case PartFail{message}: PartFail{message}
            case PartOk{text}:
              clear = buf_move_clear(ploc, pindex, CLay.layout_words(playout), pmove)
              PartOk{join_text(["Term pbl = 0; u32 pbc = 0; Term pblc = 0; ", text, "; ", clear, " pbr = pbl;\n"])}
    case CLay.LayoutBox{reason}: PartFail{"a BUF inline form cannot hold a box"}

def buf_move_clear(+ploc: String, +pindex: String, +pcount: Nat, +pmove: Bool) -> String:
  match pmove:
    case True{}: buf_clear_words(ploc, pindex, pcount, 0n, "")
    case False{}: ""

def cell_arr_body(+pw: World, +playout: CLay.Layout, +ploc: String, +pindex: String, +puniq: String, +pstat: String, +pmove: Bool) -> Part:
  match pmove:
    case True{}: data_move_body(pw, playout, join_text([ploc, " + (", pindex, ")"]), 0n)
    case False{}: data_copy_body(pw, playout, join_text([ploc, " + (", pindex, ")"]), 0n, puniq, pstat)

def cell_move_clear(+ploc: String, +pindex: String, +pspan: Nat, +pmove: Bool) -> String:
  match pmove:
    case True{}: buf_clear_span(ploc, pindex, pspan, 0n, "      ")
    case False{}: ""

def cell_data_body(+pw: World, +playout: CLay.Layout, +ploc: String, +parr: String, +pindex: String, +plgs: Nat, +puniq: String, +pstat: String, +pmove: Bool) -> Part:
  span = pow2(plgs)
  jobs = unfill_jobs(pw, playout, SrcBlock{ploc, pindex, False{}, False{}, "pbc"}, "pbl", "pblc")
  match part_of(run_jobs(jobs, pw, Nil{}), "pbl"):
    case PartFail{message}: PartFail{message}
    case PartOk{btext}:
      match cell_arr_body(pw, playout, ploc, pindex, puniq, pstat, pmove):
        case PartFail{message}: PartFail{message}
        case PartOk{abody}:
          move_clear = cell_move_clear(ploc, pindex, span, pmove)
          PartOk{join_text(["if (", parr, ") { ", abody, " } else { Term pbl = 0; u32 pbc = 0; Term pblc = 0; ", btext, "; ", move_clear, " pbr = pbl; }\n"])}

def buf_clear_span(+ploc: String, +pindex: String, +pspan: Nat, +pat: Nat, +pindent: String) -> String:
  match Nat.is_eq(pat, pspan):
    case True{}: ""
    case False{}: join_text([pindent, "blk_write(e.mem, false, ", ploc, ", (u32)((", pindex, ") + ", Nat.show(pat), "ull), 0);\n", buf_clear_span(ploc, pindex, pspan, Nat.add(pat, 1n), pindent)])

def copy_cell_body(+pw: World, +pstate: PathState) -> Part:
  match pstate:
    case StCell{loc, arr, index, cls, layout, lgs, buf, uniq, stat}:
      match layout:
        case CLay.LayoutWord{word}:
          match word:
            case CLay.CWord32{}: PartOk{join_text(["pbr = ((u64)(u32)(blk_read(e.mem, ", arr, ", ", loc, ", (u32)(", index, "))));\n"])}
            case _: PartOk{join_text(["pbr = (u64)(blk_read(e.mem, ", arr, ", ", loc, ", (u32)(", index, ")));\n"])}
        case CLay.LayoutBox{reason}:
          match buf:
            case True{}: PartFail{"a BUF array cell cannot contain a boxed field"}
            case False{}: PartOk{join_text(["{ Term pv = blk_read(e.mem, ", arr, ", ", loc, ", (u32)(", index, ")); Term pk = term_keep(e, pv, 1); if (pk != pv) { if (", stat, ") { (void)err_fail(\"a static image would need a keep wrapper\"); } else if (!", uniq, ") { (void)err_fail(\"a shared owner has an unsealed cell child\"); } else { blk_write(e.mem, ", arr, ", ", loc, ", (u32)(", index, "), pk); } } pbr = pk; }\n"])}
        case CLay.LayoutData{words, arms}: cell_data_body(pw, layout, loc, arr, index, lgs, uniq, stat, False{})
    case _: PartFail{"not a cell"}

def copy_padding(+pspan: Nat, +pwords: Nat, +pindent: String) -> String:
  match Nat.is_eq(pwords, pspan):
    case True{}: ""
    case False{}: join_text([pindent, "e.mem[pdst + ", Nat.show(pwords), "] = e.mem[psrc + ", Nat.show(pwords), "];\n", copy_padding(pspan, Nat.add(pwords, 1n), pindent)])

def array_inner(+pmove: Bool, +puniq: String, +pstat: String, +pcell: CLay.Layout) -> String:
  match pmove:
    case True{}: move_copy("psrc", 0n, 0n, pcell, "    ")
    case False{}: keep_copy("psrc", puniq, pstat, 0n, 0n, pcell, "    ")

def array_copy_body(+pstate: PathState, +pmove: Bool) -> Part:
  match pstate:
    case StArray{loc, cls, lgs, cell, arr, off, buf, uniq, stat}:
      span = pow2(lgs)
      words = CLay.layout_words(cell)
      inner = array_inner(pmove, uniq, stat, cell)
      padding = copy_padding(span, words, "    ")
      body = join_text(["u64 pal = (u64)(", loc, "); u32 pac = (u32)(", cls, "); bool paarr = ", arr, "; u64 pnl = 0;\nif (paarr) { pnl = heap_alloc(e, blk_wcls(true, pac)); u64 pacount = (1ull << (pac - ", Nat.show(lgs), ")); for (u64 pe = 0; pe < pacount; pe += 1) { u64 psrc = pal + (", off, ") + (pe << ", Nat.show(lgs), "); u64 pdst = pnl + (pe << ", Nat.show(lgs), "); { Term pbbuf[", Nat.show(span), "]; ", inner, padding, "for (u64 pj = 0; pj < ", Nat.show(words), "; pj += 1) { e.mem[pdst + pj] = pbbuf[pj]; } } } } else { pnl = heap_alloc(e, blk_wcls(false, pac)); u64 pacells = (1ull << pac); for (u64 pi = 0; pi < pacells; pi += 1) { blk_write(e.mem, false, pnl, (u32)pi, blk_read(e.mem, false, pal, (u32)((", off, ") + pi))); } } pbr = term_blk(paarr, pac, pnl);\n"])
      PartOk{body}
    case _: PartFail{"not an array"}

def pow2(+pn: Nat) -> Nat:
  match pn:
    case 0n: 1n
    case 1n+p: Nat.mul(2n, pow2(p))

def move_cell_body(+pw: World, +pstate: PathState) -> Part:
  match pstate:
    case StCell{loc, arr, index, cls, layout, lgs, buf, uniq, stat}:
      match layout:
        case CLay.LayoutWord{word}:
          match word:
            case CLay.CWord32{}: PartOk{join_text(["pbr = ((u64)(u32)(blk_read(e.mem, ", arr, ", ", loc, ", (u32)(", index, ")))); blk_write(e.mem, ", arr, ", ", loc, ", (u32)(", index, "), 0);\n"])}
            case _: PartOk{join_text(["pbr = (u64)(blk_read(e.mem, ", arr, ", ", loc, ", (u32)(", index, "))); blk_write(e.mem, ", arr, ", ", loc, ", (u32)(", index, "), 0);\n"])}
        case CLay.LayoutBox{reason}:
          match buf:
            case True{}: PartFail{"a BUF array cell cannot contain a boxed field"}
            case False{}: PartOk{join_text(["pbr = blk_read(e.mem, ", arr, ", ", loc, ", (u32)(", index, ")); blk_write(e.mem, ", arr, ", ", loc, ", (u32)(", index, "), 0);\n"])}
        case CLay.LayoutData{words, arms}: cell_data_body(pw, layout, loc, arr, index, lgs, uniq, stat, True{})
    case _: PartFail{"not a cell"}

def move_slot_body(+pw: World, +pstate: PathState) -> Part:
  match pstate:
    case StSlot{offset, layout, base, uniq, stat, packed}:
      match packed:
        case True{}: copy_slot_body(pw, pstate)
        case False{}:
          match layout:
            case CLay.LayoutWord{word}: PartOk{join_text(["pbr = ", raw_word_expr(base, offset, word), ";\n"])}
            case CLay.LayoutBox{reason}: PartOk{join_text(["pbr = e.mem[", base, " + ", Nat.show(offset), "]; e.mem[", base, " + ", Nat.show(offset), "] = 0;\n"])}
            case CLay.LayoutData{words, arms}: data_move_body(pw, layout, base, offset)
    case _: PartFail{"not a field slot"}

def data_move_body(+pw: World, +playout: CLay.Layout, +pbase: String, +poffset: Nat) -> Part:
  count = CLay.layout_words(playout)
  match count:
    case 0n: zero_value_body(pw, playout)
    case _:
      jobs = unfill_jobs(pw, playout, SrcNode{"0", "pbbuf", "pbi", False{}}, "pbl", "pblc")
      match part_of(run_jobs(jobs, pw, Nil{}), "pbl"):
        case PartFail{message}: PartFail{message}
        case PartOk{text}: PartOk{join_text(["{ Term pbbuf[", Nat.show(count), "]; ", move_copy(pbase, poffset, poffset, playout, ""), "u32 pbi = 0; Term pbl = 0; ", text, "; pbr = pbl; }\n"])}

def state_stat(+pstate: PathState) -> String:
  match pstate:
    case StSlot{offset, layout, base, uniq, stat, packed}: stat
    case StArray{loc, cls, lgs, cell, arr, off, buf, uniq, stat}: stat
    case StCell{loc, arr, index, cls, layout, lgs, buf, uniq, stat}: stat
    case StBufField{loc, index, layout, uniq, stat}: stat

def state_uniq(+pstate: PathState) -> String:
  match pstate:
    case StSlot{offset, layout, base, uniq, stat, packed}: uniq
    case StArray{loc, cls, lgs, cell, arr, off, buf, uniq, stat}: uniq
    case StCell{loc, arr, index, cls, layout, lgs, buf, uniq, stat}: uniq
    case StBufField{loc, index, layout, uniq, stat}: uniq

def path_body_copy(+pw: World, +pstate: PathState) -> Part:
  match pstate:
    case StSlot{offset, layout, base, uniq, stat, packed}: copy_slot_body(pw, pstate)
    case StCell{loc, arr, index, cls, layout, lgs, buf, uniq, stat}: copy_cell_body(pw, pstate)
    case StArray{loc, cls, lgs, cell, arr, off, buf, uniq, stat}: array_copy_body(pstate, False{})
    case StBufField{loc, index, layout, uniq, stat}: buf_field_body(pw, layout, loc, index, False{})

def path_body_move(+pw: World, +pstate: PathState) -> Part:
  match pstate:
    case StSlot{offset, layout, base, uniq, stat, packed}: move_slot_body(pw, pstate)
    case StCell{loc, arr, index, cls, layout, lgs, buf, uniq, stat}: move_cell_body(pw, pstate)
    case StArray{loc, cls, lgs, cell, arr, off, buf, uniq, stat}: array_copy_body(pstate, True{})
    case StBufField{loc, index, layout, uniq, stat}: buf_field_body(pw, layout, loc, index, True{})

def path_read(+proot: String, +psteps: List<&2, PathStep>, +pw: World) -> Part:
  match resolve_path(pw, psteps):
    case PathFail{message}: PartFail{message}
    case PathOk{state}:
      match read_body(pw, state):
        case PartFail{message}: PartFail{message}
        case PartOk{body}: PartOk{path_expr(proot, body)}


def runtime_cid_of_ctor(+pw: World, +pid: U32) -> Maybe<&2, U32>:
  match ctor_of(pid, pw):
    case None{}: None{}
    case Some{ctor}:
      match ctor:
        case BIR.ConstructorLayout{id, key, native, fields}: cid_of(key, pw)

def canonical_bool(+pw: World, +pcond: String) -> Part:
  match cid_text("True", pw):
    case None{}: PartFail{"the runtime has no canonical True CID"}
    case Some{pt}:
      match cid_text("False", pw):
        case None{}: PartFail{"the runtime has no canonical False CID"}
        case Some{pf}: PartOk{join_text(["pbr = bend_bool(e, ", pt, ", ", pf, ", ", pcond, ");\n"])}

def path_hastag(+proot: String, +psteps: List<&2, PathStep>, +pexpected: U32, +pw: World) -> Part:
  match resolve_path(pw, psteps):
    case PathFail{message}: PartFail{message}
    case PathOk{state}:
      match runtime_cid_of_ctor(pw, pexpected):
        case None{}: PartFail{join_text(["the BIR constructor id ", U32.show(pexpected), " has no canonical runtime CID"])}
        case Some{want}:
          match tag_body(pw, state, Some{want}, "pbpred"):
            case PartFail{message}: PartFail{message}
            case PartOk{body}:
              match canonical_bool(pw, "pbpred"):
                case PartFail{message}: PartFail{message}
                case PartOk{value}: PartOk{path_expr(proot, join_text(["u32 pbpred = 0; { ", body, " } ", value]))}

def path_copy(+proot: String, +psteps: List<&2, PathStep>, +pw: World) -> Part:
  match resolve_path(pw, psteps):
    case PathFail{message}: PartFail{message}
    case PathOk{state}:
      match path_body_copy(pw, state):
        case PartFail{message}: PartFail{message}
        case PartOk{body}: PartOk{path_expr(proot, body)}

def path_consume(+proot: String, +psteps: List<&2, PathStep>, +pw: World) -> Part:
  match resolve_path(pw, psteps):
    case PathFail{message}: PartFail{message}
    case PathOk{state}:
      match path_body_copy(pw, state):
        case PartFail{message}: PartFail{message}
        case PartOk{copy}:
          match path_body_move(pw, state):
            case PartFail{message}: PartFail{message}
            case PartOk{moved}:
              body = join_text(["if (", state_stat(state), " || !", state_uniq(state), ") { ", copy, " } else { ", moved, " } "])
              PartOk{path_expr(proot, body)}

def path_is_leaf(+proot: String, +psteps: List<&2, PathStep>, +pw: World) -> Part:
  match resolve_path(pw, psteps):
    case PathFail{message}: PartFail{message}
    case PathOk{state}:
      match state:
        case StArray{loc, cls, lgs, cell, arr, off, buf, uniq, stat}:
          cond = join_text(["((u32)(", cls, ") == ", Nat.show(lgs), "u)"])
          match canonical_bool(pw, cond):
            case PartFail{message}: PartFail{message}
            case PartOk{value}: PartOk{path_expr(proot, value)}
        case _: PartFail{"an array leaf test needs an array slice"}

def path_is_node(+proot: String, +psteps: List<&2, PathStep>, +pw: World) -> Part:
  match resolve_path(pw, psteps):
    case PathFail{message}: PartFail{message}
    case PathOk{state}:
      match state:
        case StArray{loc, cls, lgs, cell, arr, off, buf, uniq, stat}:
          cond = join_text(["((u32)(", cls, ") > ", Nat.show(lgs), "u)"])
          match canonical_bool(pw, cond):
            case PartFail{message}: PartFail{message}
            case PartOk{value}: PartOk{path_expr(proot, value)}
        case _: PartFail{"an array node test needs an array slice"}

def project_plan(+pplan: CLay.UnfillResult, +pw: World, +pnode: CLay.Node, +playout: CLay.Layout, +poffset: Nat, +pvalue: String) -> Part:
  match pplan:
    case CLay.UnfillFailed{message}: PartFail{message}
    case CLay.UnfillFound{unfill}:
      match pnode:
        case CLay.Node{words, slots, packed}: project_packed_flag(packed, pw, playout, poffset, List.length(&2, CLay.CWord, words), pvalue)

def project_slot(+pslot: CLay.SlotResult, +pw: World, +pnode: CLay.Node, +pkey: String, +pfield: U32, +pvalue: String) -> Part:
  match pslot:
    case CLay.SlotErased{}: PartFail{join_text(["the projection of `", pkey, "` names an erased field, which has no storage"])}
    case CLay.SlotFailed{message}: PartFail{message}
    case CLay.SlotFound{found}:
      match found:
        case CLay.NodeSlot{ordinal, offset, layout}:
          match pw:
            case World{ctx, constructors, families, cids}:
              plan = CLay.slot_unfill(ctx, pkey, pfield)
              project_plan(plan, pw, pnode, layout, offset, pvalue)

def project_layout(+pnode: CLay.NodeResult, +pw: World, +pkey: String, +pfield: U32, +pvalue: String) -> Part:
  match pnode:
    case CLay.NodeFailed{message}: PartFail{message}
    case CLay.NodeFound{node}:
      match pw:
        case World{ctx, constructors, families, cids}:
          slot = CLay.node_slot(ctx, pkey, pfield)
          project_slot(slot, pw, node, pkey, pfield, pvalue)

def project_node(+pw: World, +pkey: String, +pfield: U32, +pvalue: String) -> Part:
  match pw:
    case World{ctx, constructors, families, cids}:
      node = CLay.node_layout(ctx, pkey)
      project_layout(node, pw, pkey, pfield, pvalue)

def project_marker(+pintr: Bool, +pvalue: String, +pkey: String, +pfield: U32, +pw: World) -> Part:
  match pintr:
    case True{}: PartFail{join_text(["the intrinsic constructor `", pkey, "` must be lowered to its primitive before C projection"])}
    case False{}: project_node(pw, pkey, pfield, pvalue)

def project_native(+pnative: Maybe<&2, String>, +pvalue: String, +pkey: String, +pfield: U32, +pw: World) -> Part:
  match pnative:
    case None{}: project_node(pw, pkey, pfield, pvalue)
    case Some{marker}: project_marker(intrinsic_marker(marker), pvalue, pkey, pfield, pw)

def project_row(+pfound: Maybe<&2, BIR.ConstructorLayout>, +pvalue: String, +pfield: U32, +pw: World) -> Part:
  match pfound:
    case None{}: PartFail{"BIR projects a constructor with no layout row"}
    case Some{row}:
      match row:
        case BIR.ConstructorLayout{id, key, native, fields}: project_native(native, pvalue, key, pfield, pw)

def project_part(+pvalue: String, +pconstructor: U32, +pfield: U32, +pw: World) -> Part:
  row = ctor_of(pconstructor, pw)
  project_row(row, pvalue, pfield, pw)

def hastag_bools(+pt: Maybe<&2, String>, +pf: Maybe<&2, String>, +pcid: U32, +pvalue: String) -> Part:
  match pt:
    case None{}: PartFail{"the C runtime contract needs the `True` constructor for a tag test"}
    case Some{tc}:
      match pf:
        case None{}: PartFail{"the C runtime contract needs the `False` constructor for a tag test"}
        case Some{fc}: PartOk{join_text(["bend_bool(e, ", tc, ", ", fc, ", (u64)bend_hastag(", pvalue, ", ", U32.show(pcid), "u))"])}

def hastag_cid(+pfound: Maybe<&2, U32>, +pvalue: String, +pw: World) -> Part:
  match pfound:
    case None{}: PartFail{"the tagged constructor has no canonical CID row"}
    case Some{cid}: hastag_bools(cid_text("True", pw), cid_text("False", pw), cid, pvalue)

def hastag_row(+pfound: Maybe<&2, BIR.ConstructorLayout>, +pvalue: String, +pw: World) -> Part:
  match pfound:
    case None{}: PartFail{"BIR has-tags a constructor with no layout row"}
    case Some{row}:
      match row:
        case BIR.ConstructorLayout{id, key, native, fields}: hastag_cid(cid_of(key, pw), pvalue, pw)

def hastag_part(+pvalue: String, +pconstructor: U32, +pw: World) -> Part:
  row = ctor_of(pconstructor, pw)
  hastag_row(row, pvalue, pw)

# ---------------------------------------------------------------------------
# Arrays
# ---------------------------------------------------------------------------

def arr_flag(+parr: Bool) -> String:
  match parr:
    case True{}: "true"
    case False{}: "false"

def array_label(+pprimitive: BIR.Primitive) -> String:
  match pprimitive:
    case BIR.PrimArrayNew{}: "array_new"
    case BIR.PrimArrayGet{}: "array_get"
    case BIR.PrimArraySet{}: "array_set"
    case BIR.PrimArraySwap{}: "array_swap"
    case BIR.PrimArrayAtomicAdd{}: "array_atomic_add"
    case BIR.PrimArrayAtomicMin{}: "array_atomic_min"
    case BIR.PrimArrayAtomicMax{}: "array_atomic_max"
    case BIR.PrimArrayAtomicAnd{}: "array_atomic_and"
    case BIR.PrimArrayAtomicOr{}: "array_atomic_or"
    case BIR.PrimArrayAtomicXor{}: "array_atomic_xor"
    case BIR.PrimArrayAtomicExch{}: "array_atomic_exch"
    case BIR.PrimArrayAtomicCas{}: "array_atomic_cas"
    case BIR.PrimArrayAtomicFadd{}: "array_atomic_fadd"
    case BIR.PrimArraySize{}: "array_size"
    case BIR.PrimArrayClone{}: "array_clone"
    case BIR.PrimArrayLeaf{}: "array_leaf"
    case BIR.PrimArrayNode{}: "array_node"
    case BIR.PrimIsArrayLeaf{}: "is_array_leaf"
    case BIR.PrimIsArrayNode{}: "is_array_node"
    case _: "array"

def array_cell_result(+pcell: CLay.CellResult) -> CellOut:
  match pcell:
    case CLay.CellFailed{message}: CellFail{message}
    case CLay.CellFound{cell}:
      match cell:
        case CLay.Cell{layout, arr, words, lgs}: CellOk{layout, arr, words, lgs}

def array_cell(+pw: World, +ptypes: List<&2, BIR.Descriptor>, +pprimitive: BIR.Primitive) -> CellOut:
  match ptypes:
    case Nil{}: CellFail{join_text(["the array primitive `", array_label(pprimitive), "` carries no instantiated element Descriptor; lowering must supply PrimitiveCall.types"])}
    case +element <> Nil{}:
      match pw:
        case World{ctx, constructors, families, cids}: array_cell_result(CLay.array_cell(ctx, element))
    case _: CellFail{join_text(["the array primitive `", array_label(pprimitive), "` must carry exactly one element Descriptor"])}

def operand_at(+pargs: List<&2, Operand>, +pindex: Nat) -> Maybe<&2, Operand>:
  match pargs:
    case Nil{}: None{}
    case +arg <> +rest:
      match pindex:
        case 0n: Some{arg}
        case 1n+left: operand_at(rest, left)

def operand_text(+poperand: Operand) -> String:
  match poperand:
    case Operand{use, text}: text

def operand_use(+poperand: Operand) -> BIR.Use:
  match poperand:
    case Operand{use, text}: use

def keep_text(+poperand: Operand) -> String:
  match poperand:
    case Operand{use, text}:
      match use:
        case BIR.Many{}: join_text(["term_keep(e, ", text, ", 1)"])
        case _: text

def tuple_cid(+pt: Maybe<&2, String>, +parray: String, +pelement: String) -> Part:
  match pt:
    case Some{tc}: PartOk{join_text(["bend_tuple(e, ", tc, ", ", parray, ", ", pelement, ")"])}
    case None{}: PartFail{"the C runtime contract needs the `Tuple` constructor for an array result"}

def tuple_part(+pw: World, +parray: String, +pelement: String) -> Part:
  tuple_cid(cid_text("Tuple", pw), parray, pelement)

def seal_cell_box(+puse: BIR.Use, +pcur: String) -> List<&2, Job>:
  match puse:
    case BIR.Many{}: [JText{join_text(["w0[", pcur, "] = term_keep(e, w0[", pcur, "], 1); ", pcur, " += 1;"])}]
    case _: [JText{join_text([pcur, " += 1;"])}]

def seal_cell_kind(+puse: BIR.Use, +pkind: CLay.CWord, +pcur: String) -> List<&2, Job>:
  match pkind:
    case CLay.CWord32{}: [JText{join_text([pcur, " += 1;"])}]
    case CLay.CWord64{}: [JText{join_text([pcur, " += 1;"])}]
    case CLay.CWordBox{}: seal_cell_box(puse, pcur)

def seal_cell_walk(+puse: BIR.Use, +pkinds: List<&2, CLay.CWord>, +pcur: String) -> List<&2, Job>:
  match pkinds:
    case Nil{}: Nil{}
    case +kind <> +rest: List.append(&2, Job, seal_cell_kind(puse, kind, pcur), seal_cell_walk(puse, rest, pcur))

def elem_fill_operand(+pw: World, +playout: CLay.Layout, +puse: BIR.Use, +pcode: Code, +pterm: String, +ptag: String) -> List<&2, Job>:
  cursor = join_text([ptag, "c"])
  jobs = List.append(&2, Job, one_job(JText{join_text(["u32 ", cursor, " = 0;"])}), List.append(&2, Job, code_jobs(pcode), List.append(&2, Job, fill_jobs(pw, playout, pterm, DstSeq{"w0", "o0"}, ptag), seal_cell_walk(puse, CLay.layout_kinds(playout), cursor))))
  jobs

def elem_fill(+pw: World, +playout: CLay.Layout, +puse: BIR.Use, +ptext: String, +ptag: String) -> List<&2, Job>:
  elem_fill_operand(pw, playout, puse, operand_code(playout, puse, ptext, ptag), operand_name(playout, puse, ptext, ptag), ptag)

def elem_stores(+pwords: Nat) -> String:
  join_text(["Term f0[", Nat.show(pwords), "]; for (u32 f0i = 0; f0i < ", Nat.show(pwords), "; f0i += 1) { f0[f0i] = w0[f0i]; }"])

def elem_decl(+pwords: Nat) -> String:
  dst_decl("w0", "o0", pwords)

def run_part(+pjobs: List<&2, Job>, +pw: World, +pexpression: String) -> Part:
  part_of(run_jobs(pjobs, pw, Nil{}), pexpression)

def array_new_ops(+pdim: Maybe<&2, Operand>, +pvalue: Maybe<&2, Operand>, +pw: World, +playout: CLay.Layout, +parr: Bool, +pwords: Nat, +plgs: Nat) -> Part:
  match pdim:
    case None{}: PartFail{"array_new needs the dimension and the value"}
    case Some{dim}:
      match pvalue:
        case None{}: PartFail{"array_new needs the dimension and the value"}
        case Some{value}:
          tail = List.append(&2, Job, [JText{elem_stores(pwords)}], Nil{})
          jobs = List.append(&2, Job, ([JText{elem_decl(pwords)}]), List.append(&2, Job, elem_fill(pw, playout, operand_use(value), operand_text(value), "an"), tail))
          run_part(jobs, pw, join_text(["blk_new(e, ", arr_flag(parr), ", (u64)(", operand_text(dim), "), ", Nat.show(plgs), ", ", Nat.show(pwords), ", f0)"]))

def tuple_and_code(+ptuple: Part, +pcode: Code) -> Part:
  match ptuple:
    case PartFail{message}: PartFail{message}
    case PartOk{text}: part_of(pcode, text)

def array_get_ops(+parray: Maybe<&2, Operand>, +pindex: Maybe<&2, Operand>, +pw: World, +playout: CLay.Layout, +parr: Bool, +plgs: Nat) -> Part:
  match parray:
    case None{}: PartFail{"array_get needs the array and the index"}
    case Some{array}:
      match pindex:
        case None{}: PartFail{"array_get needs the array and the index"}
        case Some{index}:
          jobs = List.append(&2, Job, ([JText{join_text(["Term a0 = ", keep_text(array), "; Term i0 = ", operand_text(index), "; u64 l0 = blk_loc(e.mem, a0); u32 g0 = (u32)blk_at(a0, (u64)(u32)i0, ", Nat.show(plgs), "); u32 c0 = 0; Term r0 = 0;"])}]), unfill_jobs(pw, playout, SrcBlock{"l0", "g0", parr, True{}, "c0"}, "r0", "ag"))
          code = run_jobs(jobs, pw, Nil{})
          tuple_and_code(tuple_part(pw, "a0", "r0"), code)

def old_read_cell(+parr: Bool, +pcur: String) -> List<&2, Job>:
  [JText{join_text(["old0[", pcur, "] = blk_read(e.mem, ", arr_flag(parr), ", l0, g0 + ", pcur, "); ", pcur, " += 1;"])}]

def kinds_box_jobs(+pkinds: List<&2, CLay.CWord>, +pcur: String, +parr: Bool) -> List<&2, Job>:
  match pkinds:
    case Nil{}: Nil{}
    case +kind <> +rest:
      List.append(&2, Job, old_read_cell(parr, pcur), kinds_box_jobs(rest, pcur, parr))

def old_sink_jobs(+pkinds: List<&2, CLay.CWord>, +pcur: String) -> List<&2, Job>:
  match pkinds:
    case Nil{}: Nil{}
    case +kind <> +rest:
      match kind:
        case CLay.CWordBox{}: List.append(&2, Job, [JText{join_text(["term_sink(e, old0[", pcur, "]); ", pcur, " += 1;"])}], old_sink_jobs(rest, pcur))
        case _: List.append(&2, Job, [JText{join_text([pcur, " += 1;"])}], old_sink_jobs(rest, pcur))

def write_jobs(+parr: Bool, +pkinds: List<&2, CLay.CWord>, +pcur: String) -> List<&2, Job>:
  match pkinds:
    case Nil{}: Nil{}
    case +kind <> +rest: List.append(&2, Job, [JText{join_text(["blk_write(e.mem, ", arr_flag(parr), ", l0, g0 + ", pcur, ", w0[", pcur, "]); ", pcur, " += 1;"])}], write_jobs(parr, rest, pcur))

def array_set_run(+parray: Operand, +pindex: Operand, +pvalue: Operand, +pw: World, +playout: CLay.Layout, +parr: Bool, +pwords: Nat, +plgs: Nat) -> Part:
  kinds = CLay.layout_kinds(playout)
  old = kinds_box_jobs(kinds, "c0", parr)
  rest = List.append(&2, Job, [JText{"c0 = 0;"}], List.append(&2, Job, write_jobs(parr, kinds, "c0"), List.append(&2, Job, [JText{"c0 = 0;"}], old_sink_jobs(kinds, "c0"))))
  jobs = List.append(&2, Job, ([JText{join_text(["Term a0 = ", keep_text(parray), "; Term i0 = ", operand_text(pindex), "; u64 l0 = blk_loc(e.mem, a0); u32 g0 = (u32)blk_at(a0, (u64)(u32)i0, ", Nat.show(plgs), "); Term old0[", Nat.show(pwords), "]; u32 c0 = 0;"])}]), List.append(&2, Job, old, List.append(&2, Job, [JText{elem_decl(pwords)}], List.append(&2, Job, elem_fill(pw, playout, operand_use(pvalue), operand_text(pvalue), "as"), rest))))
  part_of(run_jobs(jobs, pw, Nil{}), "a0")

def array_set_ops(+parray: Maybe<&2, Operand>, +pindex: Maybe<&2, Operand>, +pvalue: Maybe<&2, Operand>, +pw: World, +playout: CLay.Layout, +parr: Bool, +pwords: Nat, +plgs: Nat) -> Part:
  match parray:
    case None{}: PartFail{"array_set needs the array, the index and the value"}
    case Some{array}:
      match pindex:
        case None{}: PartFail{"array_set needs the array, the index and the value"}
        case Some{index}:
          match pvalue:
            case None{}: PartFail{"array_set needs the array, the index and the value"}
            case Some{value}: array_set_run(array, index, value, pw, playout, parr, pwords, plgs)

def array_swap_run(+parray: Operand, +pindex: Operand, +pvalue: Operand, +pw: World, +playout: CLay.Layout, +parr: Bool, +pwords: Nat, +plgs: Nat) -> Part:
  kinds = CLay.layout_kinds(playout)
  old = kinds_box_jobs(kinds, "c0", parr)
  unfill = unfill_jobs(pw, playout, SrcBuf{"old0", "oc0"}, "r0", "awold")
  rest = List.append(&2, Job, [JText{"c0 = 0;"}], List.append(&2, Job, write_jobs(parr, kinds, "c0"), List.append(&2, Job, [JText{"u32 oc0 = 0;"}], unfill)))
  jobs = List.append(&2, Job, ([JText{join_text(["Term a0 = ", keep_text(parray), "; Term i0 = ", operand_text(pindex), "; u64 l0 = blk_loc(e.mem, a0); u32 g0 = (u32)blk_at(a0, (u64)(u32)i0, ", Nat.show(plgs), "); Term old0[", Nat.show(pwords), "]; u32 c0 = 0; Term r0 = 0;"])}]), List.append(&2, Job, old, List.append(&2, Job, [JText{elem_decl(pwords)}], List.append(&2, Job, elem_fill(pw, playout, operand_use(pvalue), operand_text(pvalue), "aw"), rest))))
  code = run_jobs(jobs, pw, Nil{})
  tuple_and_code(tuple_part(pw, "a0", "r0"), code)

def array_swap_ops(+parray: Maybe<&2, Operand>, +pindex: Maybe<&2, Operand>, +pvalue: Maybe<&2, Operand>, +pw: World, +playout: CLay.Layout, +parr: Bool, +pwords: Nat, +plgs: Nat) -> Part:
  match parray:
    case None{}: PartFail{"array_swap needs the array, the index and the value"}
    case Some{array}:
      match pindex:
        case None{}: PartFail{"array_swap needs the array, the index and the value"}
        case Some{index}:
          match pvalue:
            case None{}: PartFail{"array_swap needs the array, the index and the value"}
            case Some{value}: array_swap_run(array, index, value, pw, playout, parr, pwords, plgs)

def array_size_ops(+parray: Maybe<&2, Operand>, +pw: World, +plgs: Nat) -> Part:
  match parray:
    case Some{array}:
      code = run_jobs(one_job(JText{join_text(["Term a0 = ", keep_text(array), ";"])}), pw, Nil{})
      tuple_and_code(tuple_part(pw, "a0", join_text(["(1ull << (blk_cls(a0) - ", Nat.show(plgs), "))"])), code)
    case None{}: PartFail{"array_size needs the array"}

def array_clone_ops(+parray: Maybe<&2, Operand>, +pw: World) -> Part:
  match parray:
    case Some{array}:
      code = run_jobs(one_job(JText{join_text(["Term a0 = ", keep_text(array), ";"])}), pw, Nil{})
      tuple_and_code(tuple_part(pw, "a0", "blk_copy(e, a0)"), code)
    case None{}: PartFail{"array_clone needs the array"}

# An atomic takes a fixed scalar array: Array<U32> keeps one u32 per element and
# Array<F32> one raw binary32 word, so the lane needs no erased element
# Descriptor and no PrimitiveCall.types. blk_at(a, i, 0) is the runtime's own
# index modulo of the block's word count, and the helper works on the block's
# buffer itself, never a copy, so a second fork handle sees the same cell. The
# pair is the forwarded handle and the OLD word; cas compares the expected word
# before storing the replacement and leaves the cell untouched otherwise. The
# array operand is always a bound Term name and each scalar operand appears
# exactly once, so the whole operation is one C expression.
def atomic_cell_text(+parray: String, +pindex: String) -> String:
  join_text(["blk_ptr(e.mem, blk_loc(e.mem, ", parray, "), blk_at(", parray, ", (u64)(u32)(", pindex, "), 0))"])

def atomic_call_text(+parray: String, +pindex: String, +pvalue: String, +pname: String) -> String:
  join_text(["(u64)", pname, "(", atomic_cell_text(parray, pindex), ", (u32)(", pvalue, "))"])

def atomic_cas_text(+parray: String, +pindex: String, +pexpected: String, +preplacement: String) -> String:
  join_text(["(u64)a32_cmpx(", atomic_cell_text(parray, pindex), ", (u32)(", pexpected, "), (u32)(", preplacement, "))"])

def atomic_helper(+pprimitive: BIR.Primitive) -> Part:
  match pprimitive:
    case BIR.PrimArrayAtomicAdd{}: PartOk{"a32_add"}
    case BIR.PrimArrayAtomicMin{}: PartOk{"a32_min"}
    case BIR.PrimArrayAtomicMax{}: PartOk{"a32_max"}
    case BIR.PrimArrayAtomicAnd{}: PartOk{"a32_and"}
    case BIR.PrimArrayAtomicOr{}: PartOk{"a32_or"}
    case BIR.PrimArrayAtomicXor{}: PartOk{"a32_xor"}
    case BIR.PrimArrayAtomicExch{}: PartOk{"a32_exch"}
    case BIR.PrimArrayAtomicFadd{}: PartOk{"a32_fadd"}
    case _: PartFail{join_text(["the primitive `", array_label(pprimitive), "` has no a32 read-modify-write helper"])}

def atomic_pair(+pexpr: String, +parray: String, +pw: World) -> Part:
  tuple_cid(cid_text("Tuple", pw), parray, pexpr)

def atomic_three_operands(+pprimitive: BIR.Primitive, +parray: Operand, +pindex: Operand, +pvalue: Operand, +pw: World) -> Part:
  match atomic_helper(pprimitive):
    case PartFail{message}: PartFail{message}
    case PartOk{name}:
      code = run_jobs(one_job(JText{join_text(["Term a0 = ", keep_text(parray), ";"])}), pw, Nil{})
      tuple_and_code(atomic_pair(atomic_call_text("a0", operand_text(pindex), operand_text(pvalue), name), "a0", pw), code)

def atomic_three_pargs(+pprimitive: BIR.Primitive, +pargs: List<&2, Operand>, +pw: World) -> Part:
  match pargs:
    case [array, index, value]: atomic_three_operands(pprimitive, array, index, value, pw)
    case _: PartFail{join_text([array_label(pprimitive), " takes the array, the index and the value"])}

def atomic_cas_pargs(+pargs: List<&2, Operand>, +pw: World) -> Part:
  match pargs:
    case [array, index, expected, replacement]:
      code = run_jobs(one_job(JText{join_text(["Term a0 = ", keep_text(array), ";"])}), pw, Nil{})
      tuple_and_code(atomic_pair(atomic_cas_text("a0", operand_text(index), operand_text(expected), operand_text(replacement)), "a0", pw), code)
    case _: PartFail{"array_atomic_cas takes the array, the index, the expected word and the replacement"}

def atomic_pargs(+pprimitive: BIR.Primitive, +pargs: List<&2, Operand>, +pw: World) -> Part:
  match pprimitive:
    case BIR.PrimArrayAtomicCas{}: atomic_cas_pargs(pargs, pw)
    case _: atomic_three_pargs(pprimitive, pargs, pw)

# A first-class atomic native value is entered with its live arguments in
# registers a0.., so the same expression is built over those names.
def atomic_three_regs(+pprimitive: BIR.Primitive, +pargs: List<&2, String>, +pw: World) -> Part:
  match pargs:
    case [array, index, value]:
      match atomic_helper(pprimitive):
        case PartFail{message}: PartFail{message}
        case PartOk{name}: atomic_pair(atomic_call_text(array, index, value, name), array, pw)
    case _: PartFail{join_text([array_label(pprimitive), " takes the array, the index and the value"])}

def atomic_cas_regs(+pargs: List<&2, String>, +pw: World) -> Part:
  match pargs:
    case [array, index, expected, replacement]: atomic_pair(atomic_cas_text(array, index, expected, replacement), array, pw)
    case _: PartFail{"array_atomic_cas takes the array, the index, the expected word and the replacement"}

def atomic_prim_part(+pprimitive: BIR.Primitive, +pargs: List<&2, String>, +pw: World) -> Part:
  match pprimitive:
    case BIR.PrimArrayAtomicCas{}: atomic_cas_regs(pargs, pw)
    case _: atomic_three_regs(pprimitive, pargs, pw)

def array_leaf_ops(+pvalue: Maybe<&2, Operand>, +pw: World, +playout: CLay.Layout, +parr: Bool, +pwords: Nat, +plgs: Nat) -> Part:
  match pvalue:
    case Some{value}:
      jobs = List.append(&2, Job, [JText{elem_decl(pwords)}], List.append(&2, Job, elem_fill(pw, playout, operand_use(value), operand_text(value), "al"), [JText{elem_stores(pwords)}]))
      run_part(jobs, pw, join_text(["blk_new(e, ", arr_flag(parr), ", 0, ", Nat.show(plgs), ", ", Nat.show(pwords), ", f0)"]))
    case None{}: PartFail{"array_leaf needs the element value"}

def array_node_ops(+pleft: Maybe<&2, Operand>, +pright: Maybe<&2, Operand>) -> Part:
  match pleft:
    case None{}: PartFail{"array_node needs the two halves"}
    case Some{left}:
      match pright:
        case None{}: PartFail{"array_node needs the two halves"}
        case Some{right}: PartOk{join_text(["blk_node(e, ", keep_text(left), ", ", keep_text(right), ")"])}

def array_is_cond(+pwhich: Nat, +parray: Operand) -> String:
  match pwhich:
    case 0n: join_text(["((u32)blk_cls(", operand_text(parray), ") == 0)"])
    case _: join_text(["((u32)blk_cls(", operand_text(parray), ") != 0)"])

def array_is_bools(+pt: Maybe<&2, String>, +pf: Maybe<&2, String>, +pwhich: Nat, +parray: Operand) -> Part:
  match pt:
    case None{}: PartFail{"the C runtime contract needs the `True` constructor for an array tag test"}
    case Some{tc}:
      match pf:
        case None{}: PartFail{"the C runtime contract needs the `False` constructor for an array tag test"}
        case Some{fc}: PartOk{join_text(["bend_bool(e, ", tc, ", ", fc, ", (u64)", array_is_cond(pwhich, parray), ")"])}

def array_is_ops(+parray: Maybe<&2, Operand>, +pwhich: Nat, +pw: World) -> Part:
  match parray:
    case Some{array}: array_is_bools(cid_text("True", pw), cid_text("False", pw), pwhich, array)
    case None{}: PartFail{"an array tag test needs the array"}

def array_new_cell(+pcell: CellOut, +pargs: List<&2, Operand>, +pw: World) -> Part:
  match pcell:
    case CellFail{message}: PartFail{message}
    case CellOk{layout, arr, words, lgs}: array_new_ops(operand_at(pargs, 0n), operand_at(pargs, 1n), pw, layout, arr, words, lgs)

def array_get_cell(+pcell: CellOut, +pargs: List<&2, Operand>, +pw: World) -> Part:
  match pcell:
    case CellFail{message}: PartFail{message}
    case CellOk{layout, arr, words, lgs}: array_get_ops(operand_at(pargs, 0n), operand_at(pargs, 1n), pw, layout, arr, lgs)

def array_set_cell(+pcell: CellOut, +pargs: List<&2, Operand>, +pw: World) -> Part:
  match pcell:
    case CellFail{message}: PartFail{message}
    case CellOk{layout, arr, words, lgs}: array_set_ops(operand_at(pargs, 0n), operand_at(pargs, 1n), operand_at(pargs, 2n), pw, layout, arr, words, lgs)

def array_swap_cell(+pcell: CellOut, +pargs: List<&2, Operand>, +pw: World) -> Part:
  match pcell:
    case CellFail{message}: PartFail{message}
    case CellOk{layout, arr, words, lgs}: array_swap_ops(operand_at(pargs, 0n), operand_at(pargs, 1n), operand_at(pargs, 2n), pw, layout, arr, words, lgs)

def array_size_cell(+pcell: CellOut, +pargs: List<&2, Operand>, +pw: World) -> Part:
  match pcell:
    case CellFail{message}: PartFail{message}
    case CellOk{layout, arr, words, lgs}: array_size_ops(operand_at(pargs, 0n), pw, lgs)

def array_clone_cell(+pcell: CellOut, +pargs: List<&2, Operand>, +pw: World) -> Part:
  match pcell:
    case CellFail{message}: PartFail{message}
    case CellOk{layout, arr, words, lgs}: array_clone_ops(operand_at(pargs, 0n), pw)

def array_leaf_cell(+pcell: CellOut, +pargs: List<&2, Operand>, +pw: World) -> Part:
  match pcell:
    case CellFail{message}: PartFail{message}
    case CellOk{layout, arr, words, lgs}: array_leaf_ops(operand_at(pargs, 0n), pw, layout, arr, words, lgs)

def array_part(+pprimitive: BIR.Primitive, +pargs: List<&2, Operand>, +ptypes: List<&2, BIR.Descriptor>, +pw: World) -> Part:
  match is_atomic_primitive(pprimitive):
    case True{}: atomic_pargs(pprimitive, pargs, pw)
    case False{}: array_cell_part(pprimitive, pargs, ptypes, pw)

def array_cell_part(+pprimitive: BIR.Primitive, +pargs: List<&2, Operand>, +ptypes: List<&2, BIR.Descriptor>, +pw: World) -> Part:
  match pprimitive:
    case BIR.PrimArrayNew{}: array_new_cell(array_cell(pw, ptypes, pprimitive), pargs, pw)
    case BIR.PrimArrayGet{}: array_get_cell(array_cell(pw, ptypes, pprimitive), pargs, pw)
    case BIR.PrimArraySet{}: array_set_cell(array_cell(pw, ptypes, pprimitive), pargs, pw)
    case BIR.PrimArraySwap{}: array_swap_cell(array_cell(pw, ptypes, pprimitive), pargs, pw)
    case BIR.PrimArraySize{}: array_size_cell(array_cell(pw, ptypes, pprimitive), pargs, pw)
    case BIR.PrimArrayClone{}: array_clone_cell(array_cell(pw, ptypes, pprimitive), pargs, pw)
    case BIR.PrimArrayLeaf{}: array_leaf_cell(array_cell(pw, ptypes, pprimitive), pargs, pw)
    case BIR.PrimArrayNode{}: array_node_ops(operand_at(pargs, 0n), operand_at(pargs, 1n))
    case BIR.PrimIsArrayLeaf{}: array_is_ops(operand_at(pargs, 0n), 0n, pw)
    case BIR.PrimIsArrayNode{}: array_is_ops(operand_at(pargs, 0n), 1n, pw)
    case _: PartFail{"this primitive is not an array operation"}

# The nine atomics are array-shaped but fixed scalar, so they never consult the
# element Descriptor cell plan that every other array operation requires.
def is_atomic_primitive(+pprimitive: BIR.Primitive) -> Bool:
  match pprimitive:
    case BIR.PrimArrayAtomicAdd{}: True{}
    case BIR.PrimArrayAtomicMin{}: True{}
    case BIR.PrimArrayAtomicMax{}: True{}
    case BIR.PrimArrayAtomicAnd{}: True{}
    case BIR.PrimArrayAtomicOr{}: True{}
    case BIR.PrimArrayAtomicXor{}: True{}
    case BIR.PrimArrayAtomicExch{}: True{}
    case BIR.PrimArrayAtomicCas{}: True{}
    case BIR.PrimArrayAtomicFadd{}: True{}
    case _: False{}

def is_array_primitive(+pprimitive: BIR.Primitive) -> Bool:
  match pprimitive:
    case BIR.PrimArrayNew{}: True{}
    case BIR.PrimArrayGet{}: True{}
    case BIR.PrimArraySet{}: True{}
    case BIR.PrimArraySwap{}: True{}
    case BIR.PrimArraySize{}: True{}
    case BIR.PrimArrayClone{}: True{}
    case BIR.PrimArrayLeaf{}: True{}
    case BIR.PrimArrayNode{}: True{}
    case BIR.PrimIsArrayLeaf{}: True{}
    case BIR.PrimIsArrayNode{}: True{}
    case _: False{}

# ---------------------------------------------------------------------------
# SHOW_DESC / SHOW_NAMES
# ---------------------------------------------------------------------------
#
# The descriptor is ONE FLAT WORD ARRAY: a cell's id is the WORD OFFSET where
# its cell starts (show.push(kind) - 1 in the reference); every reference slot
# holds that offset, patched when the child is processed. kind = position of
# the normalized key in U32 F32 Nat Char String . Array & 7 (Eql 5), else 7.
# Char [3, box]; Array [6, element offset, lgs]; Data [7, box, arm count] then
# per arm [name index, cid, field count, bracket] (Tuple 2, Con/Nil 1) then per
# field [offset, cell]. box = 1 iff the storage layout is one Term; field
# offsets start at the tag word (!box && arms > 1) and advance by the field
# layout's words. Cells are memoized on full normalized (type, layout) identity
# BEFORE their children. SHOW_NAMES is the arm names in first-emission order.
# An erased field refuses the build.

def show_state0() -> ShowState:
  ShowState{Nil{}, Nil{}, Map.new(&2, Nat), Nil{}, None{}}

def show_words(+pst: ShowState) -> List<&2, ShowWord>:
  match pst:
    case ShowState{words, patches, memo, names, error}: words

def show_patches(+pst: ShowState) -> List<&2, ShowPatch>:
  match pst:
    case ShowState{words, patches, memo, names, error}: patches

def show_memo(+pst: ShowState) -> Map<&2, Nat>:
  match pst:
    case ShowState{words, patches, memo, names, error}: memo

def show_names(+pst: ShowState) -> List<&2, String>:
  match pst:
    case ShowState{words, patches, memo, names, error}: names

def show_error(+pst: ShowState) -> Maybe<&2, String>:
  match pst:
    case ShowState{words, patches, memo, names, error}: error

def show_state_set_memo(+pst: ShowState, +pmemo: Map<&2, Nat>) -> ShowState:
  match pst:
    case ShowState{words, patches, memo, names, error}: ShowState{words, patches, pmemo, names, error}

def show_state_error(+pst: ShowState, +pmessage: String) -> ShowState:
  match pst:
    case ShowState{words, patches, memo, names, error}: ShowState{words, patches, memo, names, Some{pmessage}}

def show_next_state(+padv: ShowAdvance) -> ShowState:
  match padv:
    case ShowNext{state, kids}: state

def show_next_kids(+padv: ShowAdvance) -> List<&2, ShowJob>:
  match padv:
    case ShowNext{state, kids}: kids

def show_append_word(+pst: ShowState, +pword: ShowWord) -> ShowState:
  match pst:
    case ShowState{words, patches, memo, names, error}: ShowState{List.append(&2, ShowWord, words, [pword]), patches, memo, names, error}

def show_append_num(+pst: ShowState, +pvalue: Nat) -> ShowState:
  show_append_word(pst, ShowNum{pvalue})

def show_append_cid(+pst: ShowState, +pvalue: Nat) -> ShowState:
  show_append_word(pst, ShowCid{pvalue})

def show_append_name(+pst: ShowState, +pname: String) -> ShowState:
  match pst:
    case ShowState{words, patches, memo, names, error}: ShowState{words, patches, memo, List.append(&2, String, names, [pname]), error}

def show_append_patch(+pst: ShowState, +pat: Nat, +pto: Nat) -> ShowState:
  match pst:
    case ShowState{words, patches, memo, names, error}: ShowState{words, List.append(&2, ShowPatch, [ShowPatchAt{pat, pto}], patches), memo, names, error}

def show_apply_patch(+pst: ShowState, +ppatch: Maybe<&2, Nat>, +pto: Nat) -> ShowState:
  match ppatch:
    case Some{at}: show_append_patch(pst, at, pto)
    case None{}: pst

def show_native_kind(+pmarker: String) -> ShowKind:
  match pmarker:
    case "U32": ShowKindOk{0n}
    case "F32": ShowKindOk{1n}
    case "Nat": ShowKindOk{2n}
    case "Char": ShowKindOk{3n}
    case "String": ShowKindOk{4n}
    case "Array": ShowKindOk{6n}
    case _: ShowKindOk{7n}

# comp.show_main takes the SHOW kind from the whnf's own form: only the word and
# character families, String and Array have a fixed kind, and every other
# *declared datatype* is kind 7, printed as data. So the native marker decides a
# kind only for a family this build declares (the base library's marker is the
# family's own name, and its ordinary datatypes — Bool, Maybe, List, Sigma and
# the rest — are data like any other). A head that is no datatype at all is
# refused rather than guessed from its spelling: that covers IO, an under-applied
# type former such as Word or App, and IO.OP, which the reference show also
# refuses by name even though it is a declared type, because its values are
# requests rather than data.
def show_kind_family(+pkey: String, +pctx: CLay.Context) -> ShowKind:
  match CLay.family_lookup(pkey, CLay.context_families(pctx)):
    case None{}: ShowKindFailed{"main's type is a type former and cannot be printed"}
    case Some{family}:
      match family:
        case BIR.Family{key, name, native, quantity_prefix, arity, arms}:
          match String.eq(key, "IO.OP"):
            case True{}: ShowKindFailed{"main's type IO.OP cannot be printed as data"}
            case False{}:
              match native:
                case Some{marker}: show_native_kind(marker)
                case None{}: ShowKindOk{7n}

def show_kind_head(+phead: CLay.HeadResult, +pctx: CLay.Context) -> ShowKind:
  match phead:
    case CLay.HeadFailed{message}: ShowKindFailed{message}
    case CLay.HeadEquality{}: ShowKindOk{5n}
    case CLay.HeadBoxed{reason}: ShowKindFailed{"main's type is abstract or open and cannot be printed"}
    case CLay.HeadFound{key, native}: show_kind_family(key, pctx)

def show_kind(+pctx: CLay.Context, +pty: BIR.Descriptor) -> ShowKind:
  head = CLay.head_native(pctx, pty)
  show_kind_head(head, pctx)

def show_box_flag(+playout: CLay.Layout) -> Nat:
  match playout:
    case CLay.LayoutBox{reason}: 1n
    case _: 0n

def show_tag_plain(+pcount: Nat) -> Nat:
  match pcount:
    case 0n: 0n
    case 1n: 0n
    case _: 1n

def show_tag_start(+pbox: Nat, +pcount: Nat) -> Nat:
  match pbox:
    case 1n: 0n
    case _: show_tag_plain(pcount)

def show_quote(+ptext: String) -> String:
  join_text(["\u{22}", ptext, "\u{22}"])

def show_name_sep(+prest: List<&2, String>) -> String:
  match prest:
    case Nil{}: ""
    case _: ","

def show_render_names(+pnames: List<&2, String>) -> String:
  match pnames:
    case Nil{}: ""
    case +name <> +rest: String.append(String.append(show_quote(name), show_name_sep(rest)), show_render_names(rest))

def show_render_sep_flag(+pempty: Bool) -> String:
  match pempty:
    case True{}: ""
    case False{}: ","

def show_render_sep(+pacc: String) -> String:
  empty = String.is_empty(pacc)
  show_render_sep_flag(empty)

def show_render_word(+pword: ShowWord) -> String:
  match pword:
    case ShowNum{value}: Nat.show(value)
    case ShowCid{value}: join_text(["CID_", Nat.show(value)])

# --- layout/field facts used by SHOW -------------------------------------

def show_render_words(+pwords: List<&2, ShowWord>, +pacc: String) -> String:
  match pwords:
    case Nil{}: pacc
    case +word <> +rest: show_render_words(rest, join_text([pacc, show_render_sep(pacc), show_render_word(word)]))

def family_arms(+pwant: String, +pfamilies: List<&2, BIR.Family>) -> Maybe<&2, List<&2, BIR.DescriptorArm>>:
  match pfamilies:
    case Nil{}: None{}
    case +family <> +rest:
      match family:
        case BIR.Family{key, name, native, quantity_prefix, arity, arms}:
          same = String.eq(pwant, key)
          Bool.pick(Maybe<&2, List<&2, BIR.DescriptorArm>>, same, Some{arms}, family_arms(pwant, rest))

def ctor_find_key(+pwant: String, +prows: List<&2, BIR.ConstructorLayout>) -> Maybe<&2, BIR.ConstructorLayout>:
  match prows:
    case Nil{}: None{}
    case +row <> +rest:
      match row:
        case BIR.ConstructorLayout{id, key, native, fields}:
          same = String.eq(key, pwant)
          Bool.pick(Maybe<&2, BIR.ConstructorLayout>, same, Some{row}, ctor_find_key(pwant, rest))

def show_cid_found(+pfound: Maybe<&2, BIR.ConstructorLayout>) -> Maybe<&2, Nat>:
  match pfound:
    case None{}: None{}
    case Some{row}:
      match row:
        case BIR.ConstructorLayout{id, key, native, fields}: Some{U32.to_nat(id)}

def show_cid_of_key(+pwant: String, +pconstructors: List<&2, BIR.ConstructorLayout>) -> Maybe<&2, Nat>:
  show_cid_found(ctor_find_key(pwant, pconstructors))

def show_arm_bracket_name(+pname: String) -> Nat:
  match pname:
    case "Tuple": 2n
    case "Con": 1n
    case "Nil": 1n
    case _: 0n

# The bracket of an arm is decided by the exact constructor key, as
# comp.show_main decides it: a module's own `Nil` is not Base's List arm, so the
# key is compared whole and never by its last segment.
def show_arm_bracket(+pkey: String) -> Nat:
  show_arm_bracket_name(pkey)

def show_erased_present(+pfields: List<&2, BIR.DescriptorField>) -> Bool:
  match pfields:
    case Nil{}: False{}
    case +field <> +rest:
      match field:
        case BIR.DescriptorField{key, quantity, ty}:
          match quantity:
            case BIR.Erased{}: True{}
            case _: show_erased_present(rest)

def show_field_at_each(+pfields: List<&2, BIR.DescriptorField>, +pordinal: Nat, +pindex: Nat) -> Maybe<&2, BIR.DescriptorField>:
  match pfields:
    case Nil{}: None{}
    case +field <> +rest:
      same = Nat.is_eq(pindex, pordinal)
      Bool.pick(Maybe<&2, BIR.DescriptorField>, same, Some{field}, show_field_at_each(rest, pordinal, Nat.add(pindex, 1n)))

def show_field_at(+pfields: List<&2, BIR.DescriptorField>, +pordinal: U32) -> Maybe<&2, BIR.DescriptorField>:
  show_field_at_each(pfields, U32.to_nat(pordinal), 0n)

def show_arm_layouts_each(+parms: List<&2, CLay.LayArm>, +pkey: String) -> Maybe<&2, List<&2, CLay.Layout>>:
  match parms:
    case Nil{}: None{}
    case +arm <> +rest:
      match arm:
        case CLay.LayArm{key, fields}:
          same = String.eq(key, pkey)
          Bool.pick(Maybe<&2, List<&2, CLay.Layout>>, same, Some{fields}, show_arm_layouts_each(rest, pkey))

def show_arm_layouts(+playout: CLay.Layout, +pkey: String) -> Maybe<&2, List<&2, CLay.Layout>>:
  match playout:
    case CLay.LayoutWord{word}: None{}
    case CLay.LayoutBox{reason}: None{}
    case CLay.LayoutData{words, arms}: show_arm_layouts_each(arms, pkey)

def show_node_layout_slots(+pnode: CLay.NodeResult) -> Maybe<&2, List<&2, CLay.NodeSlot>>:
  match pnode:
    case CLay.NodeFailed{message}: None{}
    case CLay.NodeFound{node}:
      match node:
        case CLay.Node{words, slots, packed}: Some{slots}

def show_word_key(+pword: CLay.CWord) -> String:
  match pword:
    case CLay.CWord32{}: "32"
    case CLay.CWord64{}: "64"
    case CLay.CWordBox{}: "x"

def show_box_key(+preason: CLay.BoxReason) -> String:
  match preason:
    case CLay.BoxOpen{}: "open"
    case CLay.BoxUnresolved{key}: join_text(["U", lk_text(key)])
    case CLay.BoxArray{}: "array"
    case CLay.BoxIo{}: "io"
    case CLay.BoxRecursive{key}: join_text(["R", lk_text(key)])
    case CLay.BoxWide{words}: join_text(["wide:", Nat.show(words)])

def lk_text(+ptext: String) -> String:
  join_text([Nat.show(String.length(ptext)), ":", ptext])

def lk_words(+pwords: List<&2, CLay.CWord>) -> String:
  match pwords:
    case Nil{}: ""
    case +word <> +rest: join_text([show_word_key(word), ",", lk_words(rest)])

def lk_fields(+pfields: List<&2, CLay.Layout>) -> String:
  match pfields:
    case Nil{}: ""
    case +field <> +rest: join_text([show_layout_key(field), ",", lk_fields(rest)])

def lk_arms(+parms: List<&2, CLay.LayArm>) -> String:
  match parms:
    case Nil{}: ""
    case +arm <> +rest:
      match arm:
        case CLay.LayArm{key, fields}:
          join_text(["A", lk_text(key), ":", Nat.show(List.length(&2, CLay.Layout, fields)), ":", lk_fields(fields), ";", lk_arms(rest)])

def show_layout_key(+playout: CLay.Layout) -> String:
  match playout:
    case CLay.LayoutWord{word}: join_text(["w", show_word_key(word)])
    case CLay.LayoutBox{reason}: join_text(["B", show_box_key(reason)])
    case CLay.LayoutData{words, arms}: join_text(["D", Nat.show(List.length(&2, CLay.CWord, words)), ":", lk_words(words), ":", Nat.show(List.length(&2, CLay.LayArm, arms)), ":", lk_arms(arms)])

def show_arg_tokens(+pargs: List<&2, BIR.Descriptor>, +pfirst: Bool) -> List<&2, ShowToken>:
  match pargs:
    case Nil{}: Nil{}
    case +arg <> +rest:
      sep = Bool.pick(List<&2, ShowToken>, pfirst, Nil{}, [ShowTokText{","}])
      List.append(&2, ShowToken, sep, List.append(&2, ShowToken, [ShowTokDesc{arg}], show_arg_tokens(rest, False{})))

def show_quantity_key(+pquantity: BIR.Quantity) -> String:
  match pquantity:
    case BIR.Erased{}: "0"
    case BIR.Once{}: "1"
    case BIR.Unrestricted{}: "2"

# --- SHOW advance ---------------------------------------------------------

def show_maybe_quantity_key(+pmaybe: Maybe<&2, BIR.Quantity>) -> String:
  match pmaybe:
    case None{}: "-"
    case Some{quantity}: show_quantity_key(quantity)

def show_pat_tokens(+ppatterns: List<&2, BIR.DescriptorPattern>, +pfirst: Bool) -> List<&2, ShowToken>:
  match ppatterns:
    case Nil{}: Nil{}
    case +pattern <> +rest:
      sep = Bool.pick(List<&2, ShowToken>, pfirst, Nil{}, [ShowTokText{","}])
      List.append(&2, ShowToken, sep, List.append(&2, ShowToken, [ShowTokPat{pattern}], show_pat_tokens(rest, False{})))

def show_pat_expand(+ppattern: BIR.DescriptorPattern) -> List<&2, ShowToken>:
  match ppattern:
    case BIR.DescriptorBinder{quantity}: [ShowTokText{"b"}, ShowTokText{show_quantity_key(quantity)}]
    case BIR.DescriptorConstructorPattern{key, fields}: List.append(&2, ShowToken, [ShowTokText{"c"}, ShowTokText{key}, ShowTokText{"("}], List.append(&2, ShowToken, show_pat_tokens(fields, True{}), [ShowTokText{")"}]))

def show_desc_expand(+pty: BIR.Descriptor) -> List<&2, ShowToken>:
  match pty:
    case BIR.DescriptorRef{key, args}: List.append(&2, ShowToken, [ShowTokText{"R"}, ShowTokText{key}, ShowTokText{"("}], List.append(&2, ShowToken, show_arg_tokens(args, True{}), [ShowTokText{")"}]))
    case BIR.DescriptorApplication{fn, arg}: [ShowTokText{"a"}, ShowTokDesc{fn}, ShowTokDesc{arg}]
    case BIR.DescriptorFill{head, args}: List.append(&2, ShowToken, List.append(&2, ShowToken, [ShowTokText{"F"}, ShowTokDesc{head}, ShowTokText{"["}], show_arg_tokens(args, True{})), [ShowTokText{"]"}])
    case BIR.DescriptorPlus{head, args}: List.append(&2, ShowToken, List.append(&2, ShowToken, [ShowTokText{"P"}, ShowTokDesc{head}, ShowTokText{"["}], show_arg_tokens(args, True{})), [ShowTokText{"]"}])
    case BIR.DescriptorNamedFill{key, head, args}: List.append(&2, ShowToken, [ShowTokText{"f"}, ShowTokText{key}, ShowTokDesc{head}, ShowTokText{"["}], List.append(&2, ShowToken, show_arg_tokens(args, True{}), [ShowTokText{"]"}]))
    case BIR.DescriptorNamedPlus{key, head, args}: List.append(&2, ShowToken, [ShowTokText{"q"}, ShowTokText{key}, ShowTokDesc{head}, ShowTokText{"["}], List.append(&2, ShowToken, show_arg_tokens(args, True{}), [ShowTokText{"]"}]))
    case BIR.DescriptorParameter{index}: [ShowTokText{"p"}, ShowTokText{Nat.show(index)}]
    case BIR.DescriptorNull{}: [ShowTokText{"n"}]
    case BIR.DescriptorKind{quantity}: [ShowTokText{"K"}, ShowTokDesc{quantity}]
    case BIR.DescriptorQuantity{quantity}: [ShowTokText{"Q"}, ShowTokText{show_quantity_key(quantity)}]
    case BIR.DescriptorQuantityKind{}: [ShowTokText{"Z"}]
    case BIR.DescriptorMinimum{left, right}: [ShowTokText{"m"}, ShowTokDesc{left}, ShowTokDesc{right}]
    case BIR.DescriptorArrow{quantity, domain, body}: [ShowTokText{"A"}, ShowTokText{show_quantity_key(quantity)}, ShowTokDesc{domain}, ShowTokDesc{body}]
    case BIR.DescriptorLambda{quantity, body}: [ShowTokText{"L"}, ShowTokText{show_maybe_quantity_key(quantity)}, ShowTokDesc{body}]
    case BIR.DescriptorConstructor{key, args}: List.append(&2, ShowToken, [ShowTokText{"C"}, ShowTokText{key}, ShowTokText{"("}], List.append(&2, ShowToken, show_arg_tokens(args, True{}), [ShowTokText{")"}]))
    case BIR.DescriptorFailure{message}: [ShowTokText{"!"}, ShowTokText{message}]
    case BIR.DescriptorSubstitution{index, value, body}: [ShowTokText{"S"}, ShowTokText{Nat.show(index)}, ShowTokDesc{value}, ShowTokDesc{body}]
    case BIR.DescriptorLet{values, body}: List.append(&2, ShowToken, [ShowTokText{"E"}, ShowTokText{Nat.show(List.length(&2, BIR.Descriptor, values))}], List.append(&2, ShowToken, show_arg_tokens(values, True{}), [ShowTokDesc{body}]))
    case BIR.DescriptorLocal{patterns, values, body}: List.append(&2, ShowToken, [ShowTokText{"l"}, ShowTokText{Nat.show(List.length(&2, BIR.DescriptorPattern, patterns))}, ShowTokText{Nat.show(List.length(&2, BIR.Descriptor, values))}], List.append(&2, ShowToken, show_pat_tokens(patterns, True{}), List.append(&2, ShowToken, show_arg_tokens(values, True{}), [ShowTokDesc{body}])))
    case BIR.DescriptorMatch{values, cases}: List.append(&2, ShowToken, [ShowTokText{"M"}, ShowTokText{Nat.show(List.length(&2, BIR.Descriptor, values))}, ShowTokText{Nat.show(List.length(&2, BIR.Descriptor, cases))}], List.append(&2, ShowToken, show_arg_tokens(values, True{}), show_arg_tokens(cases, True{})))
    case BIR.DescriptorCase{patterns, body}: List.append(&2, ShowToken, [ShowTokText{"c"}, ShowTokText{Nat.show(List.length(&2, BIR.DescriptorPattern, patterns))}], List.append(&2, ShowToken, show_pat_tokens(patterns, True{}), [ShowTokDesc{body}]))
    case BIR.DescriptorBind{value, body}: [ShowTokText{"b"}, ShowTokDesc{value}, ShowTokDesc{body}]
    case BIR.DescriptorEquality{left, right, ty}: [ShowTokText{"="}, ShowTokDesc{left}, ShowTokDesc{right}, ShowTokDesc{ty}]
    case BIR.DescriptorReflexivity{}: [ShowTokText{"r"}]

def show_render_tokens(+ptokens: List<&2, ShowToken>, +pacc: String) -> Maybe<&2, String>:
  match ptokens:
    case Nil{}: Some{pacc}
    case +tok <> +rest:
      match tok:
        case ShowTokText{text}: show_render_tokens(rest, join_text([pacc, Nat.show(String.length(text)), ":", text]))
        case ShowTokDesc{descriptor}: show_render_tokens(List.append(&2, ShowToken, show_desc_expand(descriptor), rest), pacc)
        case ShowTokPat{pattern}: show_render_tokens(List.append(&2, ShowToken, show_pat_expand(pattern), rest), pacc)

def show_descriptor_key(+pty: BIR.Descriptor) -> Maybe<&2, String>:
  show_render_tokens([ShowTokDesc{pty}], "")

def show_array_cell(+pcell: CLay.CellResult, +pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pelement: BIR.Descriptor, +pat: Nat, +pst: ShowState) -> ShowAdvance:
  match pcell:
    case CLay.CellFailed{message}: ShowNext{show_state_error(pst, message), Nil{}}
    case CLay.CellFound{cell}:
      match cell:
        case CLay.Cell{layout, arr, words, lgs}:
          st = show_append_num(show_append_num(show_append_num(pst, 6n), 0n), lgs)
          ShowNext{st, [ShowNode{pelement, layout, Some{Nat.add(pat, 1n)}}]}

def show_array_element(+pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pelement: BIR.Descriptor, +pat: Nat, +pst: ShowState) -> ShowAdvance:
  cell = CLay.array_cell(pctx, pelement)
  show_array_cell(cell, pctx, pconstructors, pfamilies, pelement, pat, pst)

def show_array_args(+pargs: CLay.ArgsResult, +pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pty: BIR.Descriptor, +pat: Nat, +pst: ShowState) -> ShowAdvance:
  match pargs:
    case CLay.ArgsFailed{message}: ShowNext{show_state_error(pst, message), Nil{}}
    case CLay.ArgsOk{values}:
      match values:
        case +element <> +rest: show_array_element(pctx, pconstructors, pfamilies, element, pat, pst)
        case Nil{}: ShowNext{show_state_error(pst, "an Array descriptor without an element type cannot be printed"), Nil{}}

def show_advance_array(+pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pty: BIR.Descriptor, +pat: Nat, +pst: ShowState) -> ShowAdvance:
  args = CLay.head_args(pctx, pty)
  show_array_args(args, pctx, pconstructors, pfamilies, pty, pat, pst)

def box_advance(+pkid: ShowJob, +padv: ShowAdvance) -> ShowAdvance:
  ShowNext{show_next_state(padv), List.append(&2, ShowJob, [pkid], show_next_kids(padv))}

def fields_box_each(+pslots: List<&2, CLay.NodeSlot>, +pfields: List<&2, BIR.DescriptorField>, +pst: ShowState) -> ShowAdvance:
  match pslots:
    case Nil{}:
      match pfields:
        case Nil{}: ShowNext{pst, Nil{}}
        case _: ShowNext{show_state_error(pst, "a constructor node's slots and fields differ"), Nil{}}
    case +slot <> +rest:
      match pfields:
        case Nil{}: ShowNext{show_state_error(pst, "a constructor node's slots and fields differ"), Nil{}}
        case +field <> +rest_fields:
          match slot:
            case CLay.NodeSlot{ordinal, offset, layout}:
              match field:
                case BIR.DescriptorField{key, quantity, ty}:
                  box_advance(ShowNode{ty, layout, Some{Nat.add(List.length(&2, ShowWord, show_words(pst)), 1n)}}, fields_box_each(rest, rest_fields, show_append_num(show_append_num(pst, offset), 0n)))

def fields_box_slots(+pslots: Maybe<&2, List<&2, CLay.NodeSlot>>, +pfields: List<&2, BIR.DescriptorField>, +pst: ShowState) -> ShowAdvance:
  match pslots:
    case None{}: ShowNext{show_state_error(pst, "a constructor node has no slots for SHOW"), Nil{}}
    case Some{values}: fields_box_each(values, pfields, pst)

def fields_box(+pctx: CLay.Context, +pkey: String, +pfields: List<&2, BIR.DescriptorField>, +pst: ShowState) -> ShowAdvance:
  node = CLay.node_layout(pctx, pkey)
  slots = show_node_layout_slots(node)
  fields_box_slots(slots, pfields, pst)

def fields_inline_each(+playouts: List<&2, CLay.Layout>, +pfields: List<&2, BIR.DescriptorField>, +pat: Nat, +pst: ShowState) -> ShowAdvance:
  match playouts:
    case Nil{}:
      match pfields:
        case Nil{}: ShowNext{pst, Nil{}}
        case _: ShowNext{show_state_error(pst, "an inline arm's fields and layouts differ"), Nil{}}
    case +layout <> +rest_layouts:
      match pfields:
        case Nil{}: ShowNext{show_state_error(pst, "an inline arm's fields and layouts differ"), Nil{}}
        case +field <> +rest_fields:
          match field:
            case BIR.DescriptorField{key, quantity, ty}:
              slot_at = Nat.add(List.length(&2, ShowWord, show_words(pst)), 1n)
              st = show_append_num(show_append_num(pst, pat), 0n)
              adv = fields_inline_each(rest_layouts, rest_fields, Nat.add(pat, CLay.layout_words(layout)), st)
              ShowNext{show_next_state(adv), List.append(&2, ShowJob, [ShowNode{ty, layout, Some{slot_at}}], show_next_kids(adv))}

def fields_inline_layouts(+playouts: Maybe<&2, List<&2, CLay.Layout>>, +pfields: List<&2, BIR.DescriptorField>, +pat: Nat, +pst: ShowState) -> ShowAdvance:
  match playouts:
    case None{}: ShowNext{show_state_error(pst, "the inline layout has no SHOW arm"), Nil{}}
    case Some{values}: fields_inline_each(values, pfields, pat, pst)

def fields_inline(+pctx: CLay.Context, +pkey: String, +pfields: List<&2, BIR.DescriptorField>, +playout: CLay.Layout, +pcount: Nat, +pat: Nat, +pst: ShowState) -> ShowAdvance:
  layouts = show_arm_layouts(playout, pkey)
  fields_inline_layouts(layouts, pfields, pat, pst)

def fields_advance(+pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pkey: String, +pfields: List<&2, BIR.DescriptorField>, +playout: CLay.Layout, +pbox: Nat, +pcount: Nat, +pst: ShowState) -> ShowAdvance:
  match pbox:
    case 1n: fields_box(pctx, pkey, pfields, pst)
    case _: fields_inline(pctx, pkey, pfields, playout, pcount, show_tag_start(pbox, pcount), pst)

# Boxed arms read node slots (declared layouts); inline arms read the value
# layout's arm and advance by each field's words.

def show_data_arm_header(+pfields: List<&2, BIR.DescriptorField>, +pkey: String, +prest: List<&2, BIR.DescriptorArm>, +pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pty: BIR.Descriptor, +playout: CLay.Layout, +pbox: Nat, +pcount: Nat, +pst: ShowState) -> ShowAdvance:
  show_data_arm_cid(show_cid_of_key(pkey, pconstructors), pfields, pkey, prest, pctx, pconstructors, pfamilies, pty, playout, pbox, pcount, pst)

def show_data_arm_rest(+pfirst: ShowAdvance, +prest: List<&2, BIR.DescriptorArm>, +pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pty: BIR.Descriptor, +playout: CLay.Layout, +pbox: Nat, +pcount: Nat) -> ShowAdvance:
  match pfirst:
    case ShowNext{state, kids}:
      match show_data_arms(prest, pctx, pconstructors, pfamilies, pty, playout, pbox, pcount, state):
        case ShowNext{state, kids2}: ShowNext{state, List.append(&2, ShowJob, kids, kids2)}

def show_data_arm_cid(+pcid: Maybe<&2, Nat>, +pfields: List<&2, BIR.DescriptorField>, +pkey: String, +prest: List<&2, BIR.DescriptorArm>, +pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pty: BIR.Descriptor, +playout: CLay.Layout, +pbox: Nat, +pcount: Nat, +pst: ShowState) -> ShowAdvance:
  match pcid:
    case None{}: ShowNext{show_state_error(pst, join_text(["the constructor `", pkey, "` has no assigned C id"])), Nil{}}
    case Some{cid}:
      index = List.length(&2, String, show_names(pst))
      st = show_append_num(show_append_cid(show_append_num(pst, index), cid), List.length(&2, BIR.DescriptorField, pfields))
      st2 = show_append_name(show_append_num(st, show_arm_bracket(pkey)), pkey)
      show_data_arm_rest(fields_advance(pctx, pconstructors, pfamilies, pkey, pfields, playout, pbox, pcount, st2), prest, pctx, pconstructors, pfamilies, pty, playout, pbox, pcount)

def show_data_arm_erased(+perased: Bool, +pfields: List<&2, BIR.DescriptorField>, +pkey: String, +prest: List<&2, BIR.DescriptorArm>, +pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pty: BIR.Descriptor, +playout: CLay.Layout, +pbox: Nat, +pcount: Nat, +pst: ShowState) -> ShowAdvance:
  match perased:
    case True{}: ShowNext{show_state_error(pst, "main's type has an erased field and cannot be printed"), Nil{}}
    case False{}: show_data_arm_header(pfields, pkey, prest, pctx, pconstructors, pfamilies, pty, playout, pbox, pcount, pst)

def show_data_arm_live(+pfields: List<&2, BIR.DescriptorField>, +pkey: String, +prest: List<&2, BIR.DescriptorArm>, +pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pty: BIR.Descriptor, +playout: CLay.Layout, +pbox: Nat, +pcount: Nat, +pst: ShowState) -> ShowAdvance:
  erased = show_erased_present(pfields)
  show_data_arm_erased(erased, pfields, pkey, prest, pctx, pconstructors, pfamilies, pty, playout, pbox, pcount, pst)

def show_data_arm(+pfound: CLay.FieldsResult, +pkey: String, +prest: List<&2, BIR.DescriptorArm>, +pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pty: BIR.Descriptor, +playout: CLay.Layout, +pbox: Nat, +pcount: Nat, +pst: ShowState) -> ShowAdvance:
  match pfound:
    case CLay.FieldsFailed{message}: ShowNext{show_state_error(pst, message), Nil{}}
    case CLay.FieldsFound{fields}: show_data_arm_live(fields, pkey, prest, pctx, pconstructors, pfamilies, pty, playout, pbox, pcount, pst)

def show_data_arms(+parms: List<&2, BIR.DescriptorArm>, +pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pty: BIR.Descriptor, +playout: CLay.Layout, +pbox: Nat, +pcount: Nat, +pst: ShowState) -> ShowAdvance:
  match parms:
    case Nil{}: ShowNext{pst, Nil{}}
    case +arm <> +rest:
      match arm:
        case BIR.DescriptorArm{key, fields}:
          found = CLay.arm_fields(pctx, key, pty)
          show_data_arm(found, key, rest, pctx, pconstructors, pfamilies, pty, playout, pbox, pcount, pst)

def show_data_count(+parms: List<&2, BIR.DescriptorArm>, +pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pty: BIR.Descriptor, +playout: CLay.Layout, +pat: Nat, +pst: ShowState) -> ShowAdvance:
  box = show_box_flag(playout)
  count = List.length(&2, BIR.DescriptorArm, parms)
  st = show_append_num(show_append_num(show_append_num(pst, 7n), box), count)
  show_data_arms(parms, pctx, pconstructors, pfamilies, pty, playout, box, count, st)

def show_data_arms_maybe(+parms: Maybe<&2, List<&2, BIR.DescriptorArm>>, +pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pty: BIR.Descriptor, +playout: CLay.Layout, +pat: Nat, +pst: ShowState, +pkey: String) -> ShowAdvance:
  match parms:
    case None{}: ShowNext{show_state_error(pst, join_text(["the datatype `", pkey, "` has no constructors"])), Nil{}}
    case Some{values}: show_data_count(values, pctx, pconstructors, pfamilies, pty, playout, pat, pst)

def show_data_key(+pkey: String, +pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pty: BIR.Descriptor, +playout: CLay.Layout, +pat: Nat, +pst: ShowState) -> ShowAdvance:
  arms = family_arms(pkey, pfamilies)
  show_data_arms_maybe(arms, pctx, pconstructors, pfamilies, pty, playout, pat, pst, pkey)

def show_data_head(+phead: CLay.HeadResult, +pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pty: BIR.Descriptor, +playout: CLay.Layout, +pat: Nat, +pst: ShowState) -> ShowAdvance:
  match phead:
    case CLay.HeadFailed{message}: ShowNext{show_state_error(pst, message), Nil{}}
    case CLay.HeadEquality{}: ShowNext{show_state_error(pst, "the equality type has no data arms to print"), Nil{}}
    case CLay.HeadBoxed{reason}: ShowNext{show_state_error(pst, "main's type is abstract or open and cannot be printed"), Nil{}}
    case CLay.HeadFound{key, native}: show_data_key(key, pctx, pconstructors, pfamilies, pty, playout, pat, pst)

def show_advance_data(+pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pty: BIR.Descriptor, +playout: CLay.Layout, +pat: Nat, +pst: ShowState) -> ShowAdvance:
  head = CLay.head_native(pctx, pty)
  show_data_head(head, pctx, pconstructors, pfamilies, pty, playout, pat, pst)

def show_advance_n(+pkind: Nat, +pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pty: BIR.Descriptor, +playout: CLay.Layout, +pat: Nat, +pst: ShowState) -> ShowAdvance:
  match pkind:
    case 3n: ShowNext{show_append_num(show_append_num(pst, 3n), show_box_flag(playout)), Nil{}}
    case 6n: show_advance_array(pctx, pconstructors, pfamilies, pty, pat, pst)
    case 7n: show_advance_data(pctx, pconstructors, pfamilies, pty, playout, pat, pst)
    case _: ShowNext{show_append_num(pst, pkind), Nil{}}

def show_advance_kind(+pkind: ShowKind, +pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pty: BIR.Descriptor, +playout: CLay.Layout, +pat: Nat, +pst: ShowState) -> ShowAdvance:
  match pkind:
    case ShowKindFailed{message}: ShowNext{show_state_error(pst, message), Nil{}}
    case ShowKindOk{kind}: show_advance_n(kind, pctx, pconstructors, pfamilies, pty, playout, pat, pst)

def show_advance_memo(+pfound: Maybe<&2, Nat>, +pkey: String, +pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pty: BIR.Descriptor, +playout: CLay.Layout, +ppatch: Maybe<&2, Nat>, +pst: ShowState) -> ShowAdvance:
  match pfound:
    case Some{offset}: ShowNext{show_apply_patch(pst, ppatch, offset), Nil{}}
    case None{}:
      at = List.length(&2, ShowWord, show_words(pst))
      memo = Map.set(&2, Nat, show_memo(pst), pkey, at)
      st = show_apply_patch(show_state_set_memo(pst, memo), ppatch, at)
      kind = show_kind(pctx, pty)
      show_advance_kind(kind, pctx, pconstructors, pfamilies, pty, playout, at, st)

def show_advance_norm(+pnorm: ShowNorm, +pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pty: BIR.Descriptor, +playout: CLay.Layout, +ppatch: Maybe<&2, Nat>, +pst: ShowState) -> ShowAdvance:
  match pnorm:
    case ShowNormFailed{message}: ShowNext{show_state_error(pst, message), Nil{}}
    case ShowNormOk{descriptor}:
      show_advance_key(show_descriptor_key(descriptor), pctx, pconstructors, pfamilies, pty, playout, ppatch, pst)

def show_advance_key(+pkey: Maybe<&2, String>, +pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pty: BIR.Descriptor, +playout: CLay.Layout, +ppatch: Maybe<&2, Nat>, +pst: ShowState) -> ShowAdvance:
  match pkey:
    case None{}: ShowNext{show_state_error(pst, "the show descriptor key did not finish"), Nil{}}
    case Some{text}:
      key = join_text([Nat.show(String.length(text)), ":", text, show_layout_key(playout)])
      found = IndexLookup.find(Nat, show_memo(pst), key)
      show_advance_memo(found, key, pctx, pconstructors, pfamilies, pty, playout, ppatch, pst)

def show_norm_result(+presult: CLay.NormResult) -> ShowNorm:
  match presult:
    case CLay.NormOk{descriptor}: ShowNormOk{descriptor}
    case CLay.NormFailed{message}: ShowNormFailed{message}

def show_norm(+pctx: CLay.Context, +pty: BIR.Descriptor) -> ShowNorm:
  show_norm_result(CLay.norm(pctx, pty))

def show_advance_error(+pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pty: BIR.Descriptor, +playout: CLay.Layout, +ppatch: Maybe<&2, Nat>, +perror: Maybe<&2, String>, +pst: ShowState) -> ShowAdvance:
  match perror:
    case Some{message}: ShowNext{pst, Nil{}}
    case None{}:
      norm = show_norm(pctx, pty)
      show_advance_norm(norm, pctx, pconstructors, pfamilies, pty, playout, ppatch, pst)

def show_advance_st(+pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pty: BIR.Descriptor, +playout: CLay.Layout, +ppatch: Maybe<&2, Nat>, +pst: ShowState) -> ShowAdvance:
  match pst:
    case ShowState{words, patches, memo, names, error}: show_advance_error(pctx, pconstructors, pfamilies, pty, playout, ppatch, error, pst)

def show_advance_job(+pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pjob: ShowJob, +pst: ShowState) -> ShowAdvance:
  match pjob:
    case ShowNode{ty, layout, patch}: show_advance_st(pctx, pconstructors, pfamilies, ty, layout, patch, pst)

def run_show(+pctx: CLay.Context, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>, +pjobs: List<&2, ShowJob>, +pst: ShowState) -> ShowRun:
  match pjobs:
    case Nil{}: ShowDone{pst}
    case +job <> +rest:
      adv = show_advance_job(pctx, pconstructors, pfamilies, job, pst)
      run_show(pctx, pconstructors, pfamilies, List.append(&2, ShowJob, show_next_kids(adv), rest), show_next_state(adv))

def show_set_word(+pwords: List<&2, ShowWord>, +pat: Nat, +pvalue: ShowWord, +pindex: Nat) -> List<&2, ShowWord>:
  match pwords:
    case Nil{}: Nil{}
    case +word <> +rest:
      same = Nat.is_eq(pindex, pat)
      Bool.pick(List<&2, ShowWord>, same, List.append(&2, ShowWord, [pvalue], rest), List.append(&2, ShowWord, [word], show_set_word(rest, pat, pvalue, Nat.add(pindex, 1n))))

def show_apply_patches(+pwords: List<&2, ShowWord>, +ppatches: List<&2, ShowPatch>) -> List<&2, ShowWord>:
  match ppatches:
    case Nil{}: pwords
    case +patch <> +rest:
      match patch:
        case ShowPatchAt{at, to}: show_apply_patches(show_set_word(pwords, at, ShowNum{to}, 0n), rest)

def show_finish(+perror: Maybe<&2, String>, +pst: ShowState) -> ShowOut:
  match perror:
    case Some{message}: ShowFail{message}
    case None{}: ShowOk{show_render_words(show_apply_patches(show_words(pst), show_patches(pst)), ""), show_render_names(show_names(pst))}

def show_result(+prun: ShowRun) -> ShowOut:
  match prun:
    case ShowDone{state}: show_finish(show_error(state), state)

def show_root_layout(+playout: CLay.Layout) -> CLay.Layout:
  match playout:
    case CLay.LayoutWord{word}: playout
    case CLay.LayoutBox{reason}: playout
    case CLay.LayoutData{words, arms}: CLay.LayoutBox{CLay.BoxWide{List.length(&2, CLay.CWord, words)}}

def show_root(+pvl: CLay.LayoutResult, +pctx: CLay.Context, +pmain: BIR.Descriptor, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>) -> ShowOut:
  match pvl:
    case CLay.LayoutFailed{message}: ShowFail{message}
    case CLay.LayoutFound{layout}:
      run = run_show(pctx, pconstructors, pfamilies, [ShowNode{pmain, show_root_layout(layout), None{}}], show_state0())
      show_result(run)

# A callable result is ONE Term: a raw word for Nat/U32/F32, a tagged term for
# every other ADT, so the show root is boxed for a non-word layout.

def show_build(+pctx: CLay.Context, +pmain: BIR.Descriptor, +pconstructors: List<&2, BIR.ConstructorLayout>, +pfamilies: List<&2, BIR.Family>) -> ShowOut:
  vl = CLay.value_layout(pctx, pmain)
  show_root(vl, pctx, pmain, pconstructors, pfamilies)
