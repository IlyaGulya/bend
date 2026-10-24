import Base
import ./backend_ir.bend as BIR
import ./index_lookup.bend as IndexLookup
import ./c_backend_link.bend as Link
import ./c_backend_layout.bend as CLay
import ./c_backend_physical.bend as Phys

# The C target for Backend IR.
#
# emit(program, runtime) renders a BIR.Program into one C translation unit: the
# Bend C runtime template with its four marker sections filled by this
# program's tables, segments, static image and effect sources. It reads no
# syntax tree, no checker environment, no source alias: every name, id and
# layout below is either a BIR field or a fact of the runtime ABI.
#
# Runtime ABI targeted (all of it observable in the runtime source handed in):
#
#   // Tables   CID_*/FID_* macros, CID_T{arity,hot}, FID_T{arity,resw,flags},
#              STAT_LEN, WL_RESW, BANGS, WL_BANK/WL_SIG/WL_ALL/WL_LOAD/
#              WL_LAST/WL_SAVE/WL_TAKE/WL_TABLE, MAIN_FID, MAIN_PURE, BLK_SHR,
#              SHOW_DESC/SHOW_NAMES under !DEVICE
#   // Spins    CONSTV u64 STAT_IMG[]
#   // Segments WL_CASE(<fid>) bodies, entered with arguments in registers
#   // Requests hand-written effect C sources, with CID(k)/FID(k) rewritten
#
# Calling convention. Every code, lazy declaration, foreign request and the
# main value is one entry; an entry's arity is how many Term registers it
# takes. A function value is always a one-short closure term_clo(fid, block of
# arity-1 values), so the runtime's own FID_CLO_APPLY, IO loop and effect
# callbacks can apply it. A k-argument partial application is its own stage
# entry: stage k takes k+1 registers, closes stage k+1 over them, and the last
# stage is the code body. Tail calls bounce through a generated trampoline, so
# tail recursion never grows the C stack.
#
# Representation is the runtime's: Nat/U32/F32 unboxed words, Bool 0/1, Data a
# term_ctr(cid, node) (or a foreign file's packed term_pak(cid, word)), Char a
# packed scalar, String the runtime SCon codepoint list, Word its WCon chain,
# Array a TAG_ARR block. ConstructorLayout.native, the same field the JS
# backend reads in $type_runtime_value, decides native constructors; an
# unknown marker is a reported failure, never a guess.

type EmitResult is Data:
  EmitSuccess{source: String}
  EmitFailure{message: String}

# A resolved C effect source: the adapter loads it, the renderer embeds the
# bytes with the namespace's short-name aliases.
type CImport is Data:
  CImport{path: String, namespace: String, source: String}

type Part is Data:
  PartOk{text: String}
  PartFail{message: String}

type CidRow is Data:
  CidRow{cid: U32, key: String, arity: Nat}
type EntryKind is Data:
  KindCode{id: U32, captures: Nat, params: List<&2, BIR.Parameter>, body: BIR.Block}
  KindStage{next: U32}
  KindLazy{body: BIR.Block}
  KindForeign{key: String, args: Nat}
  KindNative{primitive: BIR.Primitive, count: Nat}
  KindMain{}
  KindEmit{}
  KindApply{}
  KindExit{}
  KindEnter{}

type Entry is Data:
  Entry{index: U32, arity: Nat, kind: EntryKind}

type Scan is Data:
  Scan{closures: Map<&2, Nat>, reads: Map<&2, Bool>, fkeys: List<&2, String>, farity: Map<&2, Nat>}

type Build is Data:
  Build{
    entries: List<&2, Entry>,
    by_code: Map<&2, U32>,
    by_key: Map<&2, U32>,
    by_foreign: Map<&2, U32>,
    by_native: Map<&2, U32>,
    stages: Map<&2, U32>,
    next: U32
  }

type Plan is Data:
  Plan{
    cids: List<&2, CidRow>,
    cid_macros: Map<&2, String>,
    fid_macros: Map<&2, String>,
    entries: List<&2, Entry>,
    by_code: Map<&2, U32>,
    by_key: Map<&2, U32>,
    by_foreign: Map<&2, U32>,
    by_native: Map<&2, U32>,
    stages: Map<&2, U32>,
    constructors: List<&2, BIR.ConstructorLayout>,
    families: List<&2, BIR.Family>,
    declarations: List<&2, BIR.Declaration>,
    main_pure: Bool,
    show_desc: String,
    show_names: String,
    imports: List<&2, CImport>,
    fkeys: List<&2, String>,
    ctx: CLay.Context
  }

# The stable entry facts control generation consults: every lookup is by the
# exact numeric id or declared key, never by a suffix.
type Sig is Data:
  Sig{
    entries: List<&2, Entry>,
    by_code: Map<&2, U32>,
    by_key: Map<&2, U32>,
    by_foreign: Map<&2, U32>,
    by_native: Map<&2, U32>,
    stages: Map<&2, U32>,
    declarations: List<&2, BIR.Declaration>,
    cids: List<&2, CidRow>,
    apply_fid: U32
  }

type PlanResult is Data:
  PlanOk{plan: Plan}
  PlanFail{message: String}

# One named local of the segment being emitted: its BIR id and the C expression
# that holds its value now.
type Env is Data:
  Env{id: U32, expr: String}

# A value a synthesized segment must receive: a local of the enclosing segment
# or a lexical capture slot of the code it belongs to.
type CapRef is Data:
  CapLocalRef{id: U32}
  CapSlotRef{slot: U32}

# The same reference with the expression to capture it, and the order it is
# passed in. A continuation takes its captures on the stack, a region in
# registers.
type Cap is Data:
  CapLocal{id: U32, expr: String}
  CapSlot{slot: U32, expr: String}

type Region is Data:
  Region{label: U32, fid: U32, refs: List<&2, CapRef>}

type SegText is Data:
  SegText{fid: U32, arity: Nat, resw: Nat, text: String}

type Ctx is Data:
  Ctx{
    sig: Sig,
    plan: Plan,
    env: List<&2, Env>,
    caps: List<&2, String>,
    caps_n: Nat,
    regions: List<&2, Region>,
    self_fid: Maybe<&2, U32>,
    next: U32,
    segs: List<&2, SegText>,
    outs: List<&2, String>,
    spin: Bool,
    max_arity: Nat
  }

type Step is Data:
  StepOk{text: String, ctx: Ctx}
  StepFail{message: String}

type Control is Data:
  ControlOk{segments: String, rows: List<&2, SegText>, max_arity: Nat}
  ControlFail{message: String}

# ---------------------------------------------------------------------------
# Entries
# ---------------------------------------------------------------------------

def build_new() -> Build:
  Build{Nil{}, Map.new(&2, U32), Map.new(&2, U32), Map.new(&2, U32), Map.new(&2, U32), Map.new(&2, U32), 0}

def build_entries(program: BIR.Program, +scan: Scan) -> Build:
  match program:
    case BIR.Program{codes, +declarations, constructors, families, type_functions, end}:
      build_foreign(scan, build_native(scan, declarations, build_lazy(declarations, build_codes(codes, declarations, scan, build_new()))))

def build_codes(codes: List<&2, BIR.Code>, +declarations: List<&2, BIR.Declaration>, +scan: Scan, +build: Build) -> Build:
  match codes:
    case Nil{}: build
    case +code <> rest:
      match code:
        case BIR.Code{id, captures, parameters, body}:
          build_codes(rest, declarations, scan, build_one_code(declarations, scan, build, id, List.length(&2, BIR.Use, captures), parameters, body))

def code_key(declarations: List<&2, BIR.Declaration>, +id: U32) -> Maybe<&2, String>:
  match declarations:
    case Nil{}: None{}
    case +item <> rest:
      match item:
        case BIR.FunctionDeclaration{key, code, parameters}: code_key_one(U32.is_eq(code, id), key, rest, id)
        case _: code_key(rest, id)

def code_key_one(found: Bool, key: String, rest: List<&2, BIR.Declaration>, id: U32) -> Maybe<&2, String>:
  match found:
    case True{}: Some{key}
    case False{}: code_key(rest, id)

def scan_reads(scan: Scan) -> Map<&2, Bool>:
  match scan:
    case Scan{closures, reads, fkeys, farity}: reads

def scan_closures(scan: Scan) -> Map<&2, Nat>:
  match scan:
    case Scan{closures, reads, fkeys, farity}: closures

def code_stem(id: U32) -> String:
  String.append("c", U32.show(id))

def native_stem(key: String) -> String:
  String.append("n", key)

def foreign_stem(key: String) -> String:
  String.append("f", key)

def stage_key(stem: String, count: Nat) -> String:
  String.concat([stem, ":", Nat.show(count)])

# A code read as a value must curry from zero arguments; a code reached only
# through closures needs a wrapper from its smallest captured prefix; a code
# only called directly starts at its real entry.
def code_stage_start(declarations: List<&2, BIR.Declaration>, +scan: Scan, +id: U32, +arity: Nat) -> Nat:
  match code_key(declarations, id):
    case None{}: stage_from_closures(scan, id, arity)
    case Some{key}:
      match map_flag(scan_reads(scan), key):
        case True{}: 0n
        case False{}: stage_from_closures(scan, id, arity)

def stage_from_closures(scan: Scan, id: U32, +arity: Nat) -> Nat:
  match IndexLookup.find(Nat, scan_closures(scan), U32.show(id)):
    case Some{value}: nat_min(value, arity)
    case None{}: arity

def build_one_code(declarations: List<&2, BIR.Declaration>, scan: Scan, build: Build, +id: U32, +captures: Nat, +parameters: List<&2, BIR.Parameter>, body: BIR.Block) -> Build:
  +arity = Nat.add(captures, List.length(&2, BIR.Parameter, parameters))
  start = code_stage_start(declarations, scan, id, arity)
  build_with_code(stage_code(build, code_stem(id), start, arity, id, captures, parameters, body), id)

def stage_code(build: Build, stem: String, start: Nat, arity: Nat, id: U32, captures: Nat, parameters: List<&2, BIR.Parameter>, body: BIR.Block) -> Build:
  build_staged(build, stem, start, arity, KindCode{id, captures, parameters, body})

def build_staged(+build: Build, +stem: String, +stage: Nat, +arity: Nat, +real: EntryKind) -> Build:
  match Nat.is_lt(stage, Nat.sub(arity, 1n)):
    case True{}:
      match build:
        case Build{entries, by_code, by_key, by_foreign, by_native, stages, +next}:
          staged = Map.set(&2, U32, stages, stage_key(stem, stage), next)
          build_staged(Build{Entry{next, Nat.add(stage, 1n), KindStage{U32.inc(next)}} <> entries, by_code, by_key, by_foreign, by_native, staged, U32.inc(next)}, stem, Nat.add(stage, 1n), arity, real)
    case False{}: build_entry(build, real)

def entry_kind_arity(kind: EntryKind) -> Nat:
  match kind:
    case KindCode{id, captures, params, body}: Nat.add(captures, List.length(&2, BIR.Parameter, params))
    case KindStage{next}: 0n
    case KindLazy{body}: 0n
    case KindForeign{key, args}: Nat.add(args, 1n)
    case KindNative{primitive, count}: count
    case KindMain{}: 0n
    case KindEmit{}: 1n
    case KindApply{}: 2n
    case KindExit{}: 0n
    case KindEnter{}: 0n

def build_entry(build: Build, +kind: EntryKind) -> Build:
  match build:
    case Build{entries, by_code, by_key, by_foreign, by_native, stages, +next}:
      Build{Entry{next, entry_kind_arity(kind), kind} <> entries, by_code, by_key, by_foreign, by_native, stages, U32.inc(next)}

def build_with_code(build: Build, id: U32) -> Build:
  match build:
    case Build{entries, by_code, by_key, by_foreign, by_native, stages, +next}:
      Build{entries, Map.set(&2, U32, by_code, U32.show(id), U32.sub(next, 1)), by_key, by_foreign, by_native, stages, next}

def build_with_key(build: Build, key: String) -> Build:
  match build:
    case Build{entries, by_code, by_key, by_foreign, by_native, stages, +next}:
      Build{entries, by_code, Map.set(&2, U32, by_key, key, U32.sub(next, 1)), by_foreign, by_native, stages, next}

def build_with_foreign(build: Build, key: String) -> Build:
  match build:
    case Build{entries, by_code, by_key, by_foreign, by_native, stages, +next}:
      Build{entries, by_code, by_key, Map.set(&2, U32, by_foreign, key, U32.sub(next, 1)), by_native, stages, next}

def build_with_native(build: Build, key: String) -> Build:
  match build:
    case Build{entries, by_code, by_key, by_foreign, by_native, stages, +next}:
      Build{entries, by_code, by_key, by_foreign, Map.set(&2, U32, by_native, key, U32.sub(next, 1)), stages, next}

def build_lazy(declarations: List<&2, BIR.Declaration>, +build: Build) -> Build:
  match declarations:
    case Nil{}: build
    case +item <> rest:
      match item:
        case BIR.LazyDeclaration{key, body}: build_lazy(rest, build_with_key(build_entry(build, KindLazy{body}), key))
        case _: build_lazy(rest, build)

def live_quantities(quantities: List<&2, BIR.Quantity>, +count: Nat) -> Nat:
  match quantities:
    case Nil{}: count
    case +quantity <> rest: live_quantities(rest, live_quantity_next(quantity, count))

def live_quantity_next(quantity: BIR.Quantity, +count: Nat) -> Nat:
  match quantity:
    case BIR.Erased{}: count
    case _: Nat.add(count, 1n)

# A native declaration is only a callable value: direct uses are PrimitiveCall,
# so an unread native needs no runtime entry at all.
def build_native(+scan: Scan, declarations: List<&2, BIR.Declaration>, +build: Build) -> Build:
  match declarations:
    case Nil{}: build
    case +item <> rest:
      match item:
        case BIR.NativeDeclaration{key, primitive, quantities}: build_native_one(rest, scan, build, key, primitive, live_quantities(quantities, 0n))
        case _: build_native(scan, rest, build)

def build_native_one(+rest: List<&2, BIR.Declaration>, +scan: Scan, +build: Build, +key: String, primitive: BIR.Primitive, +count: Nat) -> Build:
  match Bool.and(map_flag(scan_reads(scan), key), Nat.is_gt(count, 0n)):
    case False{}: build_native(scan, rest, build)
    case True{}:
      build_native(scan, rest, build_with_native(stage_native(build, native_stem(key), count, primitive), key))

def stage_native(build: Build, stem: String, +count: Nat, primitive: BIR.Primitive) -> Build:
  build_staged(build, stem, 0n, count, KindNative{primitive, count})

def build_foreign(scan: Scan, build: Build) -> Build:
  match scan:
    case Scan{closures, reads, fkeys, farity}: build_foreign_each(fkeys, farity, reads, build)

def build_foreign_each(keys: List<&2, String>, +farity: Map<&2, Nat>, +reads: Map<&2, Bool>, +build: Build) -> Build:
  match keys:
    case Nil{}: build
    case +key <> rest:
      +live = map_nat(farity, key)
      +arity = Nat.add(live, 1n)
      start = foreign_stage_start(map_flag(reads, key), arity)
      build_foreign_each(rest, farity, reads, build_with_foreign(stage_foreign(build, foreign_stem(key), start, arity, key, live), key))

def stage_foreign(build: Build, stem: String, start: Nat, arity: Nat, key: String, live: Nat) -> Build:
  build_staged(build, stem, start, arity, KindForeign{key, live})

def foreign_stage_start(read: Bool, arity: Nat) -> Nat:
  match read:
    case True{}: 0n
    case False{}: arity

# The main entry is the program's top segment: it tail-calls the main
# declaration, and the runtime's four own segments follow it.
def finish_entries(build: Build) -> Build:
  match build:
    case Build{entries, by_code, by_key, by_foreign, by_native, stages, +next}:
      last = U32.inc(U32.inc(U32.inc(U32.inc(U32.inc(next)))))
      Build{finish_top(Entry{next, 0n, KindMain{}}, Entry{U32.inc(next), 1n, KindEmit{}}, Entry{U32.inc(U32.inc(next)), 2n, KindApply{}}, Entry{U32.inc(U32.inc(U32.inc(next))), 0n, KindExit{}}, Entry{U32.inc(U32.inc(U32.inc(U32.inc(next)))), 0n, KindEnter{}}, entries), by_code, by_key, by_foreign, by_native, stages, last}

def finish_top(top: Entry, emit: Entry, apply: Entry, exit: Entry, enter: Entry, entries: List<&2, Entry>) -> List<&2, Entry>:
  enter <> exit <> apply <> emit <> (top <> entries)

def entries_ascending(entries: List<&2, Entry>) -> List<&2, Entry>:
  List.reverse(&2, Entry, entries)

def fid_macro_map(declarations: List<&2, BIR.Declaration>, build: Build) -> Map<&2, String>:
  match build:
    case Build{all, by_code, by_key, by_foreign, by_native, stages, next}:
      fid_macros_runtime(fid_macros_declarations(declarations, by_code, by_key, by_foreign, by_native, Map.new(&2, String)))

def fid_macros_declarations(declarations: List<&2, BIR.Declaration>, +by_code: Map<&2, U32>, +by_key: Map<&2, U32>, +by_foreign: Map<&2, U32>, +by_native: Map<&2, U32>, +acc: Map<&2, String>) -> Map<&2, String>:
  match declarations:
    case Nil{}: acc
    case +item <> rest:
      match item:
        case BIR.FunctionDeclaration{key, code, parameters}:
          fid_macros_declarations(rest, by_code, by_key, by_foreign, by_native, map_set_first(acc, key, fid_symbol(map_u32(by_code, U32.show(code)))))
        case BIR.LazyDeclaration{+key, body}:
          fid_macros_declarations(rest, by_code, by_key, by_foreign, by_native, map_set_first(acc, key, fid_symbol(map_u32(by_key, key))))
        case BIR.ForeignDeclaration{+key, _, _, arity, _, _, _, _, _}:
          fid_macros_declarations(rest, by_code, by_key, by_foreign, by_native, map_set_first(acc, key, fid_symbol(map_u32(by_foreign, key))))
        case BIR.NativeDeclaration{+key, primitive, quantities}:
          match IndexLookup.find(U32, by_native, key):
            case Some{index}: fid_macros_declarations(rest, by_code, by_key, by_foreign, by_native, map_set_first(acc, key, fid_symbol(index)))
            case None{}: fid_macros_declarations(rest, by_code, by_key, by_foreign, by_native, acc)
        case _: fid_macros_declarations(rest, by_code, by_key, by_foreign, by_native, acc)

# ---------------------------------------------------------------------------
# Plan: main kind, native constructor tables, show descriptors
# ---------------------------------------------------------------------------

def plan_make(+program: BIR.Program, imports: List<&2, CImport>) -> PlanResult:
  +scan = scan_program(program)
  cids = cid_rows(program, scan)
  match program:
    case BIR.Program{codes, declarations, constructors, families, type_functions, end}:
      plan_finish(program, scan, cids, constructors, families, declarations, end, imports)

def plan_finish(program: BIR.Program, scan: Scan, cids: List<&2, CidRow>, constructors: List<&2, BIR.ConstructorLayout>, +families: List<&2, BIR.Family>, declarations: List<&2, BIR.Declaration>, +end: BIR.Ending, imports: List<&2, CImport>) -> PlanResult:
  plan_pure(end, families, plan_top(program, scan, cids, constructors, families, declarations, end, imports))

def plan_top(+program: BIR.Program, +scan: Scan, +cids: List<&2, CidRow>, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, +declarations: List<&2, BIR.Declaration>, end: BIR.Ending, imports: List<&2, CImport>) -> PlanResult:
  +build = finish_entries(build_entries(program, scan))
  PlanOk{Plan{cids, cid_macro_map(cids), fid_macro_map(declarations, build), entries_ascending(build_entries_of(build)), by_code_of(build), by_key_of(build), by_foreign_of(build), by_native_of(build), stages_of(build), constructors, families, declarations, True{}, "{ 0 }", "", imports, fkeys_of(scan), CLay.context(program)}}

def plan_pure(end: BIR.Ending, families: List<&2, BIR.Family>, inner: PlanResult) -> PlanResult:
  match inner:
    case PlanFail{message}: PlanFail{message}
    case PlanOk{plan}: plan_set_pure(end, families, plan)

# The C target produces one executable translation unit and its runtime calls
# MAIN_FID; a library ending has no C consumer, so it is refused, never invented.
def plan_set_pure(end: BIR.Ending, families: List<&2, BIR.Family>, plan: Plan) -> PlanResult:
  match end:
    case BIR.Library{exports}: PlanFail{"the C target emits an executable: a library ending has no C runtime entry point"}
    case BIR.Executable{main_type}: plan_executable(main_type, families, plan)

def plan_set_pure_flags(plan: Plan, pure: Bool, desc: String, names: String) -> Plan:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, imports, fkeys, ctx}:
      Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, pure, desc, names, imports, fkeys, ctx}

def fid_macros_runtime(acc: Map<&2, String>) -> Map<&2, String>:
  fid_macros_runtime_one(map_set_first(acc, "Clo~apply", "FID_CLO_APPLY"))

def fid_macros_runtime_one(acc: Map<&2, String>) -> Map<&2, String>:
  map_set_first(acc, "IO~emit", "FID_IO_EMIT")

def plan_executable(+main_type: BIR.Descriptor, families: List<&2, BIR.Family>, plan: Plan) -> PlanResult:
  match descriptor_head(main_type):
    case None{}: PlanFail{"the main type is not a resolvable type descriptor"}
    case Some{+key}:
      match family_key(key, families):
        case None{}: PlanFail{String.append("the main type `", String.append(key, "` is not a declared family"))}
        case Some{family}: plan_executable_family(family, main_type, plan)

def plan_executable_family(+family: BIR.Family, +main_type: BIR.Descriptor, +plan: Plan) -> PlanResult:
  match family:
    case BIR.Family{key, name, native, quantity_prefix, arity, arms}:
      match native:
        case Some{tag}: plan_executable_io(String.eq(tag, "IO"), family, main_type, plan)
        case None{}: plan_executable_show(family, main_type, plan)

def plan_executable_io(is_io: Bool, family: BIR.Family, main_type: BIR.Descriptor, +plan: Plan) -> PlanResult:
  match is_io:
    case True{}: PlanOk{plan_set_pure_flags(plan, False{}, "{ 0 }", "")}
    case False{}: plan_executable_show(family, main_type, plan)

def plan_executable_show(family: BIR.Family, main_type: BIR.Descriptor, plan: Plan) -> PlanResult:
  match plan:
    case Plan{+cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, +constructors, +families, declarations, main_pure, _, _, imports, fkeys, ctx}:
      show = Phys.show_build(ctx, main_type, constructors, families)
      match show:
        case Phys.ShowFail{message}: PlanFail{message}
        case Phys.ShowOk{desc, names}:
          PlanOk{Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, True{}, desc, names, imports, fkeys, ctx}}

def descriptor_head(descriptor: BIR.Descriptor) -> Maybe<&2, String>:
  match descriptor:
    case BIR.DescriptorRef{key, args}: Some{key}
    case BIR.DescriptorApplication{fn, arg}: descriptor_head(fn)
    case BIR.DescriptorFill{head, args}: descriptor_head(head)
    case BIR.DescriptorPlus{head, args}: descriptor_head(head)
    case BIR.DescriptorNamedFill{key, head, args}: descriptor_head(head)
    case BIR.DescriptorNamedPlus{key, head, args}: descriptor_head(head)
    case _: None{}

def family_key(+key: String, families: List<&2, BIR.Family>) -> Maybe<&2, BIR.Family>:
  match families:
    case Nil{}: None{}
    case +family <> rest:
      match family:
        case BIR.Family{known, name, native, quantity_prefix, arity, arms}:
          match Bool.or(String.eq(key, known), String.eq(key, name)):
            case True{}: Some{family}
            case False{}: family_key(key, rest)

def build_entries_of(build: Build) -> List<&2, Entry>:
  match build:
    case Build{entries, _, _, _, _, _, _}: entries

def by_code_of(build: Build) -> Map<&2, U32>:
  match build:
    case Build{_, by_code, _, _, _, _, _}: by_code

def by_key_of(build: Build) -> Map<&2, U32>:
  match build:
    case Build{_, _, by_key, _, _, _, _}: by_key

def by_foreign_of(build: Build) -> Map<&2, U32>:
  match build:
    case Build{_, _, _, by_foreign, _, _, _}: by_foreign

def by_native_of(build: Build) -> Map<&2, U32>:
  match build:
    case Build{_, _, _, _, by_native, _, _}: by_native

def stages_of(build: Build) -> Map<&2, U32>:
  match build:
    case Build{_, _, _, _, _, stages, _}: stages

def fkeys_of(scan: Scan) -> List<&2, String>:
  match scan:
    case Scan{closures, reads, fkeys, farity}: fkeys


# ---------------------------------------------------------------------------
# Small helpers
# ---------------------------------------------------------------------------

def cat(parts: List<&2, String>) -> String:
  String.join(parts, "")

def okp(text: String) -> Part:
  PartOk{text}

def failp(message: String) -> Part:
  PartFail{message}

def part_join(parts: List<&2, Part>) -> Part:
  match parts:
    case Nil{}: PartOk{""}
    case +part <> rest:
      match part:
        case PartFail{message}: PartFail{message}
        case PartOk{text}: part_append(text, part_join(rest))

def part_append(text: String, rest: Part) -> Part:
  match rest:
    case PartFail{message}: PartFail{message}
    case PartOk{after}: PartOk{String.append(text, after)}

def part_first(parts: List<&2, Part>) -> String:
  match parts:
    case Nil{}: ""
    case +part <> rest:
      match part:
        case PartFail{message}: message
        case PartOk{text}: part_first(rest)

def part_require(parts: List<&2, Part>) -> Maybe<&2, String>:
  match parts:
    case Nil{}: Some{""}
    case +part <> rest:
      match part:
        case PartFail{message}: None{}
        case PartOk{text}: part_require(rest)

# Macro names are injective over source keys: a separator . ~ - ? becomes one
# underscore and a literal underscore doubles, so `foo.bar` and `foo_bar` never
# merge. The runtime's own spellings (Clo~apply, IO~emit, SNil, SCon) are
# preserved exactly. No unique-suffix guessing: a clash would be a bug here.
def c_escape_char(+char: Char) -> String:
  match char:
    case '\"': "\\\""
    case '\\': "\\\\"
    case '\n': "\\n"
    case '\r': "\\r"
    case '\t': "\\t"
    case _: String.from_list([char])

def c_quote_chars(chars: List<&2, Char>) -> String:
  match chars:
    case Nil{}: "\""
    case +char <> rest: String.append(c_escape_char(char), c_quote_chars(rest))

def c_quote(text: String) -> String:
  String.append("\"", c_quote_chars(String.to_list(text)))

def nat_c(value: Nat) -> String:
  cat([Nat.show(value), "ull"])

def u32_c(value: U32) -> String:
  cat([U32.show(value), "u"])

def list_at(items: List<&2, String>, index: Nat) -> String:
  match items index:
    case Nil{} _: ""
    case +item <> _ 0n: item
    case _ <> rest 1n+rest_index: list_at(rest, rest_index)

def member(items: List<&2, String>, +key: String) -> Bool:
  match items:
    case Nil{}: False{}
    case +item <> rest: member_one(String.eq(item, key), key, rest)

def member_one(same: Bool, key: String, rest: List<&2, String>) -> Bool:
  match same:
    case True{}: True{}
    case False{}: member(rest, key)

def map_flag(map: Map<&2, Bool>, key: String) -> Bool:
  match IndexLookup.find(Bool, map, key):
    case Some{value}: value
    case None{}: False{}

def map_nat(map: Map<&2, Nat>, key: String) -> Nat:
  match IndexLookup.find(Nat, map, key):
    case Some{value}: value
    case None{}: 0n

def map_u32(map: Map<&2, U32>, key: String) -> U32:
  match IndexLookup.find(U32, map, key):
    case Some{value}: value
    case None{}: 0

def map_str(map: Map<&2, String>, key: String) -> String:
  match IndexLookup.find(String, map, key):
    case Some{value}: value
    case None{}: ""

def map_set_first(+map: Map<&2, String>, +key: String, value: String) -> Map<&2, String>:
  match IndexLookup.find(String, map, key):
    case Some{_}: map
    case None{}: Map.set(&2, String, map, key, value)

def map_set_first_u32(+map: Map<&2, U32>, +key: String, value: U32) -> Map<&2, U32>:
  match IndexLookup.find(U32, map, key):
    case Some{_}: map
    case None{}: Map.set(&2, U32, map, key, value)

def nat_min(+left: Nat, +right: Nat) -> Nat:
  match Nat.is_lt(left, right):
    case True{}: left
    case False{}: right

def nat_max(+left: Nat, +right: Nat) -> Nat:
  match Nat.is_lt(left, right):
    case True{}: right
    case False{}: left

def last_segment(+key: String) -> String:
  last_segment_list(String.split(key, '.'), key)

def last_segment_list(rest: List<&2, String>, previous: String) -> String:
  match rest:
    case Nil{}: previous
    case +one <> tail: last_segment_list(tail, one)

def list_index_of(items: List<&2, String>, +key: String, index: U32) -> Maybe<&2, U32>:
  match items:
    case Nil{}: None{}
    case +item <> rest: list_index_one(String.eq(item, key), key, item, rest, index)

def list_index_one(same: Bool, key: String, item: String, rest: List<&2, String>, +index: U32) -> Maybe<&2, U32>:
  match same:
    case True{}: Some{index}
    case False{}: list_index_of(rest, key, U32.inc(index))

def list_index(items: List<&2, String>, key: String) -> Maybe<&2, U32>:
  list_index_of(items, key, 0)

def ctor_keys(constructors: List<&2, BIR.ConstructorLayout>) -> List<&2, String>:
  match constructors:
    case Nil{}: Nil{}
    case +row <> rest:
      match row:
        case BIR.ConstructorLayout{_, key, _, _}: key <> ctor_keys(rest)

def ctor_index(key: String, constructors: List<&2, BIR.ConstructorLayout>) -> String:
  match list_index(ctor_keys(constructors), key):
    case Some{value}: String.append(U32.show(value), "u")
    case None{}: "0u"

def entry_at(entries: List<&2, Entry>, +index: U32) -> Maybe<&2, Entry>:
  match entries:
    case Nil{}: None{}
    case +entry <> rest:
      match entry:
        case Entry{known, arity, kind}: entry_at_one(U32.is_eq(known, index), entry, rest, index)

def entry_at_one(found: Bool, entry: Entry, rest: List<&2, Entry>, index: U32) -> Maybe<&2, Entry>:
  match found:
    case True{}: Some{entry}
    case False{}: entry_at(rest, index)

def entry_arity(entries: List<&2, Entry>, index: U32) -> Nat:
  match entry_at(entries, index):
    case Some{Entry{_, arity, _}}: arity
    case None{}: 0n

def max_arity(entries: List<&2, Entry>) -> Nat:
  max_arity_each(entries, 2n)

def max_arity_each(entries: List<&2, Entry>, +acc: Nat) -> Nat:
  match entries:
    case Nil{}: acc
    case +entry <> rest:
      match entry:
        case Entry{index, arity, kind}: max_arity_each(rest, nat_max(acc, arity))

# ---------------------------------------------------------------------------
# Scan
# ---------------------------------------------------------------------------

def scan_new() -> Scan:
  Scan{Map.new(&2, Nat), Map.new(&2, Bool), Nil{}, Map.new(&2, Nat)}

def scan_program(program: BIR.Program) -> Scan:
  match program:
    case BIR.Program{codes, declarations, constructors, families, type_functions, end}:
      scan_declarations(declarations, scan_codes(codes, scan_new()))

def scan_codes(codes: List<&2, BIR.Code>, +scan: Scan) -> Scan:
  match codes:
    case Nil{}: scan
    case +code <> rest:
      match code:
        case BIR.Code{_, captures, parameters, body}: scan_codes(rest, scan_block(body, scan))

def scan_declarations(items: List<&2, BIR.Declaration>, +scan: Scan) -> Scan:
  match items:
    case Nil{}: scan
    case +item <> rest: scan_declarations(rest, scan_declaration(item, scan))

def scan_declaration(item: BIR.Declaration, +scan: Scan) -> Scan:
  match item:
    case BIR.FunctionDeclaration{key, code, parameters}: scan
    case BIR.LazyDeclaration{key, body}: scan_block(body, scan)
    case BIR.NativeDeclaration{key, primitive, quantities}: scan
    case BIR.ForeignDeclaration{key, _, _, arity, _, _, _, _, _}: scan_foreign(scan, key, arity)

def scan_foreign(scan: Scan, +key: String, arity: Nat) -> Scan:
  match scan:
    case Scan{+closures, +reads, +fkeys, +farity}:
      match member(fkeys, key):
        case True{}: Scan{closures, reads, fkeys, farity}
        case False{}: Scan{closures, reads, List.append(&2, String, fkeys, [key]), Map.set(&2, Nat, farity, key, arity)}

def scan_read(scan: Scan, key: String) -> Scan:
  match scan:
    case Scan{closures, reads, fkeys, farity}:
      Scan{closures, Map.set(&2, Bool, reads, key, True{}), fkeys, farity}

def scan_close(scan: Scan, code: U32, count: Nat) -> Scan:
  match scan:
    case Scan{closures, reads, fkeys, farity}:
      Scan{scan_close_min(closures, U32.show(code), count), reads, fkeys, farity}

def scan_close_min(+map: Map<&2, Nat>, +key: String, +count: Nat) -> Map<&2, Nat>:
  match IndexLookup.find(Nat, map, key):
    case Some{old}: Map.set(&2, Nat, map, key, nat_min(old, count))
    case None{}: Map.set(&2, Nat, map, key, count)

def scan_atom(atom: BIR.Atom, +scan: Scan) -> Scan:
  match atom:
    case BIR.Symbol{_, key}: scan_read(scan, key)
    case _: scan

def scan_argument(arg: BIR.Arg, scan: Scan) -> Scan:
  match arg:
    case BIR.Arg{_, value}: scan_atom(value, scan)

def scan_arguments(args: List<&2, BIR.Arg>, +scan: Scan) -> Scan:
  match args:
    case Nil{}: scan
    case +arg <> rest: scan_arguments(rest, scan_argument(arg, scan))

def scan_fields(fields: List<&2, BIR.Field>, +scan: Scan) -> Scan:
  match fields:
    case Nil{}: scan
    case +field <> rest:
      match field:
        case BIR.Field{_, _, _, value}: scan_fields(rest, scan_atom(value, scan))

def scan_op(op: BIR.Op, +scan: Scan) -> Scan:
  match op:
    case BIR.Copy{value}: scan_atom(value, scan)
    case BIR.PrimitiveCall{primitive, args, types}: scan_arguments(args, scan)
    case BIR.Closure{code, +captures, parameters}: scan_arguments(captures, scan_close(scan, code, List.length(&2, BIR.Arg, captures)))
    case BIR.Direct{code, args}: scan_arguments(args, scan)
    case BIR.Apply{fn, arg}: scan_argument(arg, scan_atom(fn, scan))
    case BIR.LoadSymbol{_, key}: scan_read(scan, key)
    case BIR.Construct{constructor, tag, fields}: scan_fields(fields, scan)
    case BIR.Project{value, constructor, field, key}: scan_atom(value, scan)
    case BIR.HasTag{value, constructor, tag}: scan_atom(value, scan)
    case _: scan

def scan_block(block: BIR.Block, +scan: Scan) -> Scan:
  match block:
    case BIR.Return{value}: scan_atom(value, scan)
    case BIR.Let{id, op, next}: scan_block(next, scan_op(op, scan))
    case BIR.Branch{condition, yes, no}: scan_block(no, scan_block(yes, scan_atom(condition, scan)))
    case BIR.Region{label, body, next}: scan_block(next, scan_block(body, scan))
    case BIR.LeaveRegion{label}: scan
    case BIR.TailDirect{code, args}: scan_arguments(args, scan)
    case BIR.TailApply{fn, arg}: scan_argument(arg, scan_atom(fn, scan))
    case BIR.Failure{message}: scan

# ---------------------------------------------------------------------------
# Cid rows
# ---------------------------------------------------------------------------

def cid_rows(program: BIR.Program, scan: Scan) -> List<&2, CidRow>:
  match program:
    case BIR.Program{codes, declarations, constructors, families, type_functions, end}:
      cid_foreign_rows(scan, cid_ctor_rows(constructors, 0, Nil{}))

def cid_ctor_rows(rows: List<&2, BIR.ConstructorLayout>, +index: U32, +acc: List<&2, CidRow>) -> List<&2, CidRow>:
  match rows:
    case Nil{}: List.reverse(&2, CidRow, acc)
    case +row <> rest:
      match row:
        case BIR.ConstructorLayout{_, key, _, fields}:
          cid_ctor_rows(rest, U32.inc(index), CidRow{index, key, List.length(&2, Maybe<&2, String>, fields)} <> acc)

def cid_foreign_rows(scan: Scan, +acc: List<&2, CidRow>) -> List<&2, CidRow>:
  match scan:
    case Scan{closures, reads, fkeys, farity}: cid_foreign_each(fkeys, farity, U32.from_nat(List.length(&2, CidRow, acc)), acc)

def cid_foreign_each(keys: List<&2, String>, +farity: Map<&2, Nat>, +index: U32, +acc: List<&2, CidRow>) -> List<&2, CidRow>:
  match keys:
    case Nil{}: acc
    case +key <> rest:
      cid_foreign_each(rest, farity, U32.inc(index), List.append(&2, CidRow, acc, [CidRow{index, key, Nat.add(map_nat(farity, key), 1n)}]))

def cid_lookup(+key: String, cids: List<&2, CidRow>) -> U32:
  match cids:
    case Nil{}: 0
    case +row <> rest:
      match row:
        case CidRow{cid, known, arity}: cid_lookup_one(String.eq(key, known), key, cid, rest)

def cid_lookup_one(same: Bool, key: String, cid: U32, rest: List<&2, CidRow>) -> U32:
  match same:
    case True{}: cid
    case False{}: cid_lookup(key, rest)

def cid_short_one(same: Bool, short: String, cid: U32, rest: List<&2, CidRow>) -> Maybe<&2, U32>:
  match same:
    case True{}: Some{cid}
    case False{}: cid_short(short, rest)

def cid_short(+short: String, cids: List<&2, CidRow>) -> Maybe<&2, U32>:
  match cids:
    case Nil{}: None{}
    case +row <> rest:
      match row:
        case CidRow{cid, key, arity}: cid_short_one(String.eq(short, key), short, cid, rest)

def cid_c(+short: String, cids: List<&2, CidRow>) -> Part:
  match cid_short(short, cids):
    case Some{cid}: PartOk{String.append(U32.show(cid), "u")}
    case None{}: PartFail{String.append("the program has no `", String.append(short, "` constructor, which the C runtime contract requires") )}

def cid_macro_map(cids: List<&2, CidRow>) -> Map<&2, String>:
  cid_macro_each(cids, Map.new(&2, String))

# A CID symbol is its stable numeric id. Source keys are never turned into C
# identifiers: exact keys live only in lookup/display/export strings.
def cid_symbol(index: U32) -> String:
  String.append("CID_", U32.show(index))

def fid_symbol(index: U32) -> String:
  String.append("FID_", U32.show(index))

def fid_symbol_of(+key: String, by_code: Map<&2, U32>, by_foreign: Map<&2, U32>) -> String:
  match IndexLookup.find(U32, by_code, key):
    case Some{index}: fid_symbol(index)
    case None{}: fid_symbol(map_u32(by_foreign, key))

# The regenerated runtime template still spells the fixed prelude constructors
# symbolically (gen_c_runtime.ts maps CID(k)/FID(k) to CID_<UPPER(k)>). These
# aliases are the only authoritative symbolic names: each resolves through its
# exact program key and a missing key is a hard error, never a guessed name.
def runtime_cid_alias(+alias: String, +key: String, cids: List<&2, CidRow>) -> Part:
  match find_cid_row(key, cids):
    case None{}: PartFail{cat(["the program has no `", key, "` constructor for the runtime symbol ", alias])}
    case Some{row}:
      match row:
        case CidRow{cid, key, arity}: okp(cat(["#define ", alias, " ", cid_symbol(cid), "\n"]))

def find_cid_row(+key: String, cids: List<&2, CidRow>) -> Maybe<&2, CidRow>:
  match cids:
    case Nil{}: None{}
    case +row <> rest:
      match row:
        case CidRow{_, known, _}: find_cid_row_one(String.eq(key, known), row, key, rest)

def find_cid_row_one(same: Bool, row: CidRow, key: String, rest: List<&2, CidRow>) -> Maybe<&2, CidRow>:
  match same:
    case True{}: Some{row}
    case False{}: find_cid_row(key, rest)

def runtime_cid_aliases(+cids: List<&2, CidRow>) -> Part:
  part_join([
    runtime_cid_alias("CID_NIL", "Nil", cids),
    runtime_cid_alias("CID_CON", "Con", cids),
    runtime_cid_alias("CID_TUPLE", "Tuple", cids),
    runtime_cid_alias("CID_SNIL", "SNil", cids),
    runtime_cid_alias("CID_SCON", "SCon", cids),
    runtime_cid_alias("CID_WCON", "WCon", cids),
    runtime_cid_alias("CID_EMIT", "Emit", cids),
    runtime_cid_alias("CID_HALT", "Halt", cids),
    runtime_cid_alias("CID_EXIT", "Exit", cids),
    runtime_cid_alias("CID_FAIL", "Fail", cids),
    runtime_cid_alias("CID_DONE", "Done", cids),
    runtime_cid_alias("CID_READY", "Ready", cids),
    runtime_cid_alias("CID_WAIT", "Wait", cids),
    runtime_cid_alias("CID_NONE", "None", cids),
    runtime_cid_alias("CID_SOME", "Some", cids)
  ])

def cid_of_row(row: CidRow) -> U32:
  match row:
    case CidRow{cid, key, arity}: cid

def cid_macro_each(cids: List<&2, CidRow>, +acc: Map<&2, String>) -> Map<&2, String>:
  match cids:
    case Nil{}: acc
    case +row <> rest:
      match row:
        case CidRow{_, key, _}:
          cid_macro_each(rest, map_set_first(acc, key, cid_symbol(cid_of_row(row))))

# ---------------------------------------------------------------------------
# Native constructor layout
# ---------------------------------------------------------------------------

def layout_of(+id: U32, constructors: List<&2, BIR.ConstructorLayout>) -> Maybe<&2, BIR.ConstructorLayout>:
  match constructors:
    case Nil{}: None{}
    case +row <> rest:
      match row:
        case BIR.ConstructorLayout{known, key, native, fields}: layout_one(U32.is_eq(id, known), row, id, rest)

def layout_one(found: Bool, row: BIR.ConstructorLayout, id: U32, rest: List<&2, BIR.ConstructorLayout>) -> Maybe<&2, BIR.ConstructorLayout>:
  match found:
    case True{}: Some{row}
    case False{}: layout_of(id, rest)

def key_layout(+key: String, constructors: List<&2, BIR.ConstructorLayout>) -> Maybe<&2, BIR.ConstructorLayout>:
  match constructors:
    case Nil{}: None{}
    case +row <> rest:
      match row:
        case BIR.ConstructorLayout{id, +known, native, fields}:
          match Bool.or(String.eq(key, known), String.eq(key, last_segment(known))):
            case True{}: Some{row}
            case False{}: key_layout(key, rest)

def native_kind_of(+id: U32, constructors: List<&2, BIR.ConstructorLayout>) -> String:
  match layout_of(id, constructors):
    case Some{row}:
      match row:
        case BIR.ConstructorLayout{id, key, native, fields}: native_kind(native)
    case None{}: "plain"

def native_kind(native: Maybe<&2, String>) -> String:
  match native:
    case None{}: "generic"
    case Some{marker}: native_marker(marker)

# Only the intrinsic families of the C runtime have their own representation:
# WORDS {U32, F32, Nat} and Array. Every other constructor, all Base ADTs
# included, is the generic ctr_build form: term_pak(cid, 0) for no live field,
# term_pak(cid, word) for one w32 live field, a node otherwise.
def native_marker(+marker: String) -> String:
  match String.eq(marker, "Nat.Zero"):
    case True{}: "natzero"
    case False{}: native_marker_1(marker)

def native_marker_1(+marker: String) -> String:
  match String.eq(marker, "Nat.Succ"):
    case True{}: "natsucc"
    case False{}: native_marker_2(marker)

def native_marker_2(+marker: String) -> String:
  match String.eq(marker, "U32.U32"):
    case True{}: "u32"
    case False{}: native_marker_3(marker)

def native_marker_3(+marker: String) -> String:
  match String.eq(marker, "F32.F32"):
    case True{}: "f32"
    case False{}: native_marker_4(marker)

def native_marker_4(+marker: String) -> String:
  match String.eq(marker, "Array.ALeaf"):
    case True{}: "aleaf"
    case False{}: native_marker_5(marker)

def native_marker_5(marker: String) -> String:
  match String.eq(marker, "Array.ANode"):
    case True{}: "anode"
    case False{}: "generic"

def packed_ctor(+id: U32, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>) -> Bool:
  match layout_of(id, constructors):
    case None{}: False{}
    case Some{row}:
      match row:
        case BIR.ConstructorLayout{id, key, native, fields}: packed_arm(key, families)

def packed_arm(+key: String, families: List<&2, BIR.Family>) -> Bool:
  match arm_of(key, families):
    case None{}: False{}
    case Some{arm}:
      match arm:
        case BIR.DescriptorArm{key, fields}: packed_fields(fields)

def packed_fields(fields: List<&2, BIR.DescriptorField>) -> Bool:
  match live_fields(fields, Nil{}):
    case +only <> Nil{}:
      match only:
        case BIR.DescriptorField{key, quantity, ty}: field_w32(ty)
    case _: False{}

def field_w32(ty: BIR.Descriptor) -> Bool:
  match descriptor_head(ty):
    case None{}: False{}
    case Some{+key}: field_w32_key(String.eq(last_segment(key), "U32"), String.eq(last_segment(key), "F32"))

def field_w32_key(is_u32: Bool, is_f32: Bool) -> Bool:
  match is_u32:
    case True{}: True{}
    case False{}: is_f32

def live_fields(fields: List<&2, BIR.DescriptorField>, +acc: List<&2, BIR.DescriptorField>) -> List<&2, BIR.DescriptorField>:
  match fields:
    case Nil{}: List.reverse(&2, BIR.DescriptorField, acc)
    case +field <> rest:
      match field:
        case BIR.DescriptorField{key, quantity, ty}: live_fields(rest, live_field_add(quantity, field, acc))

def live_field_add(quantity: BIR.Quantity, field: BIR.DescriptorField, +acc: List<&2, BIR.DescriptorField>) -> List<&2, BIR.DescriptorField>:
  match quantity:
    case BIR.Erased{}: acc
    case _: field <> acc

def arm_of(key: String, families: List<&2, BIR.Family>) -> Maybe<&2, BIR.DescriptorArm>:
  match families:
    case Nil{}: None{}
    case +family <> rest:
      match family:
        case BIR.Family{owner, name, native, quantity_prefix, arity, arms}: arms_find(key, arms, rest)

def arms_find(+key: String, arms: List<&2, BIR.DescriptorArm>, +rest: List<&2, BIR.Family>) -> Maybe<&2, BIR.DescriptorArm>:
  match arms:
    case Nil{}: arm_of(key, rest)
    case +arm <> tail:
      match arm:
        case BIR.DescriptorArm{+known, fields}:
          match Bool.or(String.eq(key, known), String.eq(last_segment(key), last_segment(known))):
            case True{}: Some{arm}
            case False{}: arms_find(key, tail, rest)

# Project.field is a source ordinal, erased slots included; the node keeps
# only live fields, so map the ordinal through the arm's quantities.
def live_index(+key: String, +ordinal: U32, families: List<&2, BIR.Family>) -> Nat:
  match arm_of(key, families):
    case None{}: U32.to_nat(ordinal)
    case Some{arm}:
      match arm:
        case BIR.DescriptorArm{key, fields}: live_index_fields(fields, U32.to_nat(ordinal), 0n, 0n)

def live_index_fields(fields: List<&2, BIR.DescriptorField>, +ordinal: Nat, +source: Nat, +live: Nat) -> Nat:
  match fields:
    case Nil{}: live
    case +field <> rest:
      match field:
        case BIR.DescriptorField{key, quantity, ty}:
          match Nat.is_eq(source, ordinal):
            case True{}: live
            case False{}: live_index_fields(rest, ordinal, Nat.add(source, 1n), live_index_next(quantity, live))

def live_index_next(quantity: BIR.Quantity, +live: Nat) -> Nat:
  match quantity:
    case BIR.Erased{}: live
    case _: Nat.add(live, 1n)

def ctor_cid(+id: U32, constructors: List<&2, BIR.ConstructorLayout>, cids: List<&2, CidRow>) -> Part:
  match layout_of(id, constructors):
    case None{}: failp(String.append("BIR names constructor id ", String.append(U32.show(id), " with no layout")))
    case Some{row}:
      match row:
        case BIR.ConstructorLayout{id, key, native, fields}: PartOk{String.append(U32.show(cid_lookup(key, cids)), "u")}

# ---------------------------------------------------------------------------
# Atoms and operations
# ---------------------------------------------------------------------------

def atom_part(atom: BIR.Atom, +plan: Plan) -> Part:
  match atom:
    case BIR.Local{id}: okp(cat(["lv", U32.show(id)]))
    case BIR.Capture{slot}: okp(cat(["x[", U32.show(slot), "]"]))
    case BIR.Symbol{_, key}: symbol_part(key, plan)
    case BIR.Word{value}: okp(u32_c(value))
    case BIR.Natural{value}: okp(nat_c(value))
    case BIR.FloatBits{bits}: okp(U32.show(bits))
    case BIR.Text{+value}: okp(cat(["bend_text(e, ", c_quote(value), ", ", Nat.show(String.length(value)), ")"]))
    case BIR.Boolean{value}: bool_lit_part(bool_name(value), plan)
    case BIR.Null{}: okp("0")
    case BIR.Undefined{}: okp("0")
    case _: failp("BIR atom form has no C rendering")

def bool_name(value: Bool) -> String:
  match value:
    case True{}: "True"
    case False{}: "False"

def bool_lit_part(which: String, plan: Plan) -> Part:
  match pcid(which, plan):
    case PartOk{c}: PartOk{cat(["term_pak(", c, ", 0)"])}
    case PartFail{message}: PartFail{message}

def symbol_part(+key: String, +plan: Plan) -> Part:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, imports, fkeys, ctx}:
      symbol_part_decl(find_declaration(key, declarations), key, plan)

def find_declaration(+key: String, declarations: List<&2, BIR.Declaration>) -> Maybe<&2, BIR.Declaration>:
  match declarations:
    case Nil{}: None{}
    case +item <> rest:
      match item:
        case BIR.FunctionDeclaration{known, code, parameters}: find_declaration_one(String.eq(key, known), item, key, rest)
        case BIR.LazyDeclaration{known, body}: find_declaration_one(String.eq(key, known), item, key, rest)
        case BIR.NativeDeclaration{known, primitive, quantities}: find_declaration_one(String.eq(key, known), item, key, rest)
        case BIR.ForeignDeclaration{known, namespace, imported, arity, sources, quantities, span, parameter_types, result}: find_declaration_one(String.eq(key, known), item, key, rest)
        case _: find_declaration(key, rest)

def find_declaration_one(found: Bool, item: BIR.Declaration, key: String, rest: List<&2, BIR.Declaration>) -> Maybe<&2, BIR.Declaration>:
  match found:
    case True{}: Some{item}
    case False{}: find_declaration(key, rest)

def symbol_part_decl(found: Maybe<&2, BIR.Declaration>, +key: String, plan: Plan) -> Part:
  match found:
    case None{}: failp(cat(["BIR reads symbol `", key, "` with no declaration"]))
    case Some{item}: symbol_part_item(item, key, plan)

def symbol_part_item(item: BIR.Declaration, +key: String, plan: Plan) -> Part:
  match plan:
    case Plan{cids, cid_macros, fid_macros, +entries, by_code, by_key, by_foreign, by_native, +stages, constructors, families, declarations, main_pure, show_desc, show_names, imports, fkeys, ctx}:
      match item:
        case BIR.FunctionDeclaration{known, +code, parameters}:
          symbol_value(IndexLookup.find(U32, by_code, U32.show(code)), code_stem(code), entries, stages)
        case BIR.ForeignDeclaration{known, _, _, arity, _, _, _, _, _}:
          symbol_value(IndexLookup.find(U32, by_foreign, key), foreign_stem(key), entries, stages)
        case BIR.NativeDeclaration{known, primitive, quantities}:
          symbol_value(IndexLookup.find(U32, by_native, key), native_stem(key), entries, stages)
        case BIR.LazyDeclaration{known, body}:
          failp(cat(["the lazy `", key, "` is evaluated by LoadSymbol, never a first-class value"]))
        case _: failp("BIR declaration form has no C value")

# A first-class function of arity one is the real entry; every wider one is the
# arity-one wrapper that closes the next stage, so the runtime's one-argument
# FID_CLO_APPLY stays exact.
def symbol_value(found: Maybe<&2, U32>, +stem: String, entries: List<&2, Entry>, stages: Map<&2, U32>) -> Part:
  match found:
    case None{}: PartFail{"BIR symbol has no entry"}
    case Some{+fid}:
      +arity = entry_arity(entries, fid)
      match Nat.is_eq(arity, 0n):
        case True{}: PartFail{"BIR symbol names a nullary entry, which only LoadSymbol evaluates"}
        case False{}:
          match Nat.is_eq(arity, 1n):
            case True{}: PartOk{cat(["term_clo(FID_", U32.show(fid), ", 0)"])}
            case False{}:
              match IndexLookup.find(U32, stages, stage_key(stem, 0n)):
                case Some{stage}: PartOk{cat(["term_clo(FID_", U32.show(stage), ", 0)"])}
                case None{}: PartFail{cat(["BIR symbol `", stem, "` has no arity-one stage entry"])}

def args_parts(args: List<&2, BIR.Arg>, +plan: Plan) -> List<&2, Part>:
  match args:
    case Nil{}: Nil{}
    case +arg <> rest:
      match arg:
        case BIR.Arg{_, value}: atom_part(value, plan) <> args_parts(rest, plan)

def arg_strings(args: List<&2, BIR.Arg>, plan: Plan) -> Maybe<&2, List<&2, String>>:
  arg_strings_each(args_parts(args, plan), Nil{})

def arg_strings_each(parts: List<&2, Part>, +acc: List<&2, String>) -> Maybe<&2, List<&2, String>>:
  match parts:
    case Nil{}: Some{List.reverse(&2, String, acc)}
    case +part <> rest:
      match part:
        case PartFail{message}: None{}
        case PartOk{text}: arg_strings_each(rest, text <> acc)

def call_args(+values: List<&2, String>) -> String:
  match values:
    case Nil{}: "0"
    case _: cat(["(Term[]){", String.join(values, ", "), "}"])

def op_part(op: BIR.Op, +plan: Plan) -> Part:
  match op:
    case BIR.Copy{value}: atom_part(value, plan)
    case BIR.PrimitiveCall{primitive, args, types}: prim_call_typed(primitive, args, types, plan)
    case BIR.Construct{constructor, tag, fields}: construct_part(constructor, fields, plan)
    case BIR.Project{value, constructor, field, key}: project_part(value, constructor, field, plan)
    case BIR.HasTag{value, constructor, tag}: hastag_part(value, constructor, plan)
    case BIR.Closure{code, captures, parameters}: failp("a BIR closure is a control operation, not a pure C expression")
    case BIR.Direct{code, args}: failp("a BIR call is a control operation, not a pure C expression")
    case BIR.Apply{fn, arg}: failp("a BIR application is a control operation, not a pure C expression")
    case BIR.LoadSymbol{_, key}: failp("a BIR symbol load is a control operation, not a pure C expression")
    case _: failp("BIR operation form has no C rendering")

def field_values(fields: List<&2, BIR.Field>, +plan: Plan) -> List<&2, Part>:
  match fields:
    case Nil{}: Nil{}
    case +field <> rest:
      match field:
        case BIR.Field{_, _, _, value}: atom_part(value, plan) <> field_values(rest, plan)

def all_arms_nullary(arms: List<&2, BIR.DescriptorArm>) -> Bool:
  match arms:
    case Nil{}: True{}
    case +arm <> rest:
      match arm:
        case BIR.DescriptorArm{key, fields}: all_arms_nullary_one(Nat.is_eq(List.length(&2, BIR.DescriptorField, live_fields(fields, Nil{})), 0n), rest)

def all_arms_nullary_one(nullary: Bool, rest: List<&2, BIR.DescriptorArm>) -> Bool:
  match nullary:
    case True{}: all_arms_nullary(rest)
    case False{}: False{}

def family_arms_of(key: String, families: List<&2, BIR.Family>) -> Maybe<&2, List<&2, BIR.DescriptorArm>>:
  match families:
    case Nil{}: None{}
    case +family <> rest:
      match family:
        case BIR.Family{owner, name, native, quantity_prefix, arity, +arms}: family_arms_check(arm_member(key, arms), arms, rest)

def arm_member(+key: String, arms: List<&2, BIR.DescriptorArm>) -> Bool:
  match arms:
    case Nil{}: False{}
    case +arm <> rest:
      match arm:
        case BIR.DescriptorArm{+known, fields}: arm_member_one(Bool.or(String.eq(key, known), String.eq(last_segment(key), last_segment(known))), key, rest)

def arm_member_one(found: Bool, key: String, rest: List<&2, BIR.DescriptorArm>) -> Bool:
  match found:
    case True{}: True{}
    case False{}: arm_member(key, rest)

def family_arms_check(found: Bool, arms: List<&2, BIR.DescriptorArm>, rest: List<&2, BIR.Family>) -> Maybe<&2, List<&2, BIR.DescriptorArm>>:
  match found:
    case True{}: Some{arms}
    case False{}: family_arms_rest(rest)

def family_arms_rest(rest: List<&2, BIR.Family>) -> Maybe<&2, List<&2, BIR.DescriptorArm>>:
  match rest:
    case Nil{}: None{}
    case +family <> tail:
      match family:
        case BIR.Family{key, name, native, quantity_prefix, arity, arms}: Some{arms}

def arm_index(+key: String, arms: List<&2, BIR.DescriptorArm>, index: Nat) -> Maybe<&2, Nat>:
  match arms:
    case Nil{}: None{}
    case +arm <> rest:
      match arm:
        case BIR.DescriptorArm{+known, fields}: arm_index_one(Bool.or(String.eq(key, known), String.eq(last_segment(key), last_segment(known))), key, rest, index)

def arm_index_one(found: Bool, key: String, rest: List<&2, BIR.DescriptorArm>, +index: Nat) -> Maybe<&2, Nat>:
  match found:
    case True{}: Some{index}
    case False{}: arm_index(key, rest, Nat.add(index, 1n))

# An inline enum is a family with more than one arm, all of them nullary; its
# values are the raw arm index, exactly as the current C emitter lays them out.
def inline_tag_arms(key: String, +arms: List<&2, BIR.DescriptorArm>) -> Maybe<&2, Nat>:
  match Bool.and(all_arms_nullary(arms), Nat.is_gt(List.length(&2, BIR.DescriptorArm, arms), 1n)):
    case True{}: arm_index(key, arms, 0n)
    case False{}: None{}

def construct_part(+constructor: U32, +fields: List<&2, BIR.Field>, +plan: Plan) -> Part:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, +constructors, families, declarations, main_pure, show_desc, show_names, imports, fkeys, ctx}:
      construct_values(constructor, native_kind_of(constructor, constructors), field_values(fields, plan), ctor_cid(constructor, constructors, cids), List.length(&2, BIR.Field, fields), packed_ctor(constructor, constructors, families))

def construct_values(constructor: U32, kind: String, values: List<&2, Part>, cid_part: Part, count: Nat, packed: Bool) -> Part:
  match values_part(values, Nil{}):
    case None{}: failp("BIR constructor field has no C value")
    case Some{args}: construct_kind(kind, args, cid_part, count, packed)

def values_part(values: List<&2, Part>, +acc: List<&2, String>) -> Maybe<&2, List<&2, String>>:
  match values:
    case Nil{}: Some{List.reverse(&2, String, acc)}
    case +part <> rest:
      match part:
        case PartFail{message}: None{}
        case PartOk{text}: values_part(rest, text <> acc)

def construct_kind(kind: String, +args: List<&2, String>, cid_part: Part, count: Nat, packed: Bool) -> Part:
  match base_construct(kind, args):
    case Some{text}: PartOk{text}
    case None{}:
      match cid_part:
        case PartFail{message}: PartFail{message}
        case PartOk{cid}: construct_generic(args, cid, count, packed)

def construct_generic(args: List<&2, String>, +cid: String, +count: Nat, packed: Bool) -> Part:
  match Nat.is_eq(count, 0n):
    case True{}: PartOk{cat(["term_pak(", cid, ", 0)"])}
    case False{}: construct_generic_n(args, cid, count, packed)

def construct_generic_n(+args: List<&2, String>, +cid: String, +count: Nat, packed: Bool) -> Part:
  match Bool.and(packed, Nat.is_eq(count, 1n)):
    case True{}: PartOk{cat(["term_pak(", cid, ", (u64)(", list_at(args, 0n), "))"])}
    case False{}: PartOk{cat(["bend_node(e, ", cid, ", ", Nat.show(count), ", ", call_args(args), ")"])}

def base_construct(+kind: String, args: List<&2, String>) -> Maybe<&2, String>:
  match String.eq(kind, "natzero"):
    case True{}: Some{"0"}
    case False{}: base_construct_1(kind, args)

def base_construct_1(+kind: String, +args: List<&2, String>) -> Maybe<&2, String>:
  match String.eq(kind, "natsucc"):
    case True{}: Some{cat(["nat_chk(e, ", list_at(args, 0n), " + 1)"])}
    case False{}: base_construct_2(kind, args)

def base_construct_2(+kind: String, +args: List<&2, String>) -> Maybe<&2, String>:
  match String.eq(kind, "u32"):
    case True{}: Some{cat(["term_word(e, ", list_at(args, 0n), ")"])}
    case False{}: base_construct_3(kind, args)

def base_construct_3(+kind: String, +args: List<&2, String>) -> Maybe<&2, String>:
  match String.eq(kind, "f32"):
    case True{}: Some{cat(["term_word(e, ", list_at(args, 0n), ")"])}
    case False{}: base_construct_4(kind, args)

def base_construct_4(+kind: String, +args: List<&2, String>) -> Maybe<&2, String>:
  match String.eq(kind, "aleaf"):
    case True{}: Some{cat(["bend_array_leaf(e, ", list_at(args, 0n), ")"])}
    case False{}: base_construct_5(kind, args)

def base_construct_5(kind: String, +args: List<&2, String>) -> Maybe<&2, String>:
  match String.eq(kind, "anode"):
    case True{}: Some{cat(["blk_node(e, ", list_at(args, 0n), ", ", list_at(args, 1n), ")"])}
    case False{}: None{}

def project_part(value: BIR.Atom, +constructor: U32, field: U32, +plan: Plan) -> Part:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, +constructors, families, declarations, main_pure, show_desc, show_names, imports, fkeys, ctx}:
      project_values(atom_part(value, plan), native_kind_of(constructor, constructors), ctor_key_of(constructor, constructors), field, families)

def ctor_key_of(+id: U32, constructors: List<&2, BIR.ConstructorLayout>) -> String:
  match layout_of(id, constructors):
    case Some{row}:
      match row:
        case BIR.ConstructorLayout{id, key, native, fields}: key
    case None{}: ""

def project_values(value: Part, kind: String, key: String, field: U32, families: List<&2, BIR.Family>) -> Part:
  match value:
    case PartFail{message}: PartFail{message}
    case PartOk{text}: PartOk{project_expr(kind, text, key, field, families)}

def project_expr(+kind: String, +value: String, key: String, field: U32, families: List<&2, BIR.Family>) -> String:
  match String.eq(kind, "natsucc"):
    case True{}: cat(["bend_nat_pred(", value, ")"])
    case False{}: project_expr_1(kind, value, key, field, families)

def project_expr_1(+kind: String, +value: String, key: String, field: U32, families: List<&2, BIR.Family>) -> String:
  match String.eq(kind, "u32"):
    case True{}: cat(["term_word(e, ", value, ")"])
    case False{}: project_expr_2(kind, value, key, field, families)

def project_expr_2(+kind: String, +value: String, key: String, field: U32, families: List<&2, BIR.Family>) -> String:
  match String.eq(kind, "f32"):
    case True{}: value
    case False{}: project_expr_3(kind, value, key, field, families)

def project_expr_3(+kind: String, +value: String, key: String, field: U32, families: List<&2, BIR.Family>) -> String:
  match String.eq(kind, "aleaf"):
    case True{}: cat(["bend_array_leaf_value(e, ", value, ")"])
    case False{}: project_expr_4(kind, value, key, field, families)

def project_expr_4(kind: String, +value: String, key: String, +field: U32, families: List<&2, BIR.Family>) -> String:
  match String.eq(kind, "anode"):
    case True{}: project_anode(value, field)
    case False{}: cat(["bend_project(e, ", value, ", ", Nat.show(live_index(key, field, families)), ")"])

def project_anode(+value: String, field: U32) -> String:
  match U32.is_eq(field, 0):
    case True{}: cat(["blk_half(e, ", value, ", 0)"])
    case False{}: cat(["blk_half(e, ", value, ", 1)"])

def hastag_part(value: BIR.Atom, +constructor: U32, +plan: Plan) -> Part:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, +constructors, families, declarations, main_pure, show_desc, show_names, imports, fkeys, ctx}:
      hastag_values(atom_part(value, plan), native_kind_of(constructor, constructors), ctor_cid(constructor, constructors, cids))

def hastag_values(value: Part, kind: String, cid_part: Part) -> Part:
  match value:
    case PartFail{message}: PartFail{message}
    case PartOk{text}: hastag_expr(kind, text, cid_part)

def hastag_expr(+kind: String, +value: String, cid_part: Part) -> Part:
  match String.eq(kind, "natzero"):
    case True{}: okp(cat(["(", value, " == 0)"]))
    case False{}: hastag_expr_1(kind, value, cid_part)

def hastag_expr_1(+kind: String, +value: String, cid_part: Part) -> Part:
  match String.eq(kind, "natsucc"):
    case True{}: okp(cat(["(", value, " > 0)"]))
    case False{}: hastag_expr_2(kind, value, cid_part)

def hastag_expr_2(+kind: String, value: String, cid_part: Part) -> Part:
  match String.eq(kind, "u32"):
    case True{}: okp("1")
    case False{}: hastag_expr_3(kind, value, cid_part)

def hastag_expr_3(+kind: String, value: String, cid_part: Part) -> Part:
  match String.eq(kind, "f32"):
    case True{}: okp("1")
    case False{}: hastag_expr_4(kind, value, cid_part)

def hastag_expr_4(+kind: String, +value: String, cid_part: Part) -> Part:
  match String.eq(kind, "aleaf"):
    case True{}: okp(cat(["((u32)blk_cls(", value, ") == 0)"]))
    case False{}: hastag_expr_5(kind, value, cid_part)

def hastag_expr_5(kind: String, +value: String, cid_part: Part) -> Part:
  match String.eq(kind, "anode"):
    case True{}: okp(cat(["((u32)blk_cls(", value, ") != 0)"]))
    case False{}: hastag_node(value, cid_part)

def hastag_node(value: String, cid_part: Part) -> Part:
  match cid_part:
    case PartFail{message}: PartFail{message}
    case PartOk{cid}: PartOk{cat(["bend_hastag(", value, ", ", cid, ")"])}

# ---------------------------------------------------------------------------
# Primitives
# ---------------------------------------------------------------------------

# The checked op carries its instantiated type arguments. Array operations need
# exactly one element Descriptor; until the CIRLayouts cell plan is consumed the
# target refuses them instead of assuming arr/lgs/words.
def prim_call_typed(+primitive: BIR.Primitive, +args: List<&2, BIR.Arg>, types: List<&2, BIR.Descriptor>, +plan: Plan) -> Part:
  match is_array_primitive(primitive):
    case True{}: prim_array_part(primitive, args, types, plan)
    case False{}: prim_call_part(primitive, args, plan)

def prim_array_part(+primitive: BIR.Primitive, args: List<&2, BIR.Arg>, types: List<&2, BIR.Descriptor>, plan: Plan) -> Part:
  match types:
    case Nil{}: failp(cat(["array primitive `", primitive_label(primitive), "` carries no instantiated element Descriptor; lowering must supply PrimitiveCall.types"]))
    case _: failp(cat(["array primitive `", primitive_label(primitive), "` needs the CIRLayouts element cell plan (arr/words/lgs) before this target can lay it out"]))

def is_array_primitive(primitive: BIR.Primitive) -> Bool:
  match primitive:
    case BIR.PrimArrayNew{}: True{}
    case BIR.PrimArrayGet{}: True{}
    case BIR.PrimArraySet{}: True{}
    case BIR.PrimArraySwap{}: True{}
    case BIR.PrimArraySize{}: True{}
    case BIR.PrimArrayClone{}: True{}
    case BIR.PrimArrayLeaf{}: True{}
    case BIR.PrimArrayNode{}: True{}
    case BIR.PrimArrayLeafValue{}: True{}
    case BIR.PrimArrayLeft{}: True{}
    case BIR.PrimArrayRight{}: True{}
    case BIR.PrimIsArrayLeaf{}: True{}
    case BIR.PrimIsArrayNode{}: True{}
    case _: False{}

def primitive_label(primitive: BIR.Primitive) -> String:
  match primitive:
    case BIR.PrimArrayNew{}: "array_new"
    case BIR.PrimArrayGet{}: "array_get"
    case BIR.PrimArraySet{}: "array_set"
    case BIR.PrimArraySwap{}: "array_swap"
    case BIR.PrimArraySize{}: "array_size"
    case BIR.PrimArrayClone{}: "array_clone"
    case BIR.PrimArrayLeaf{}: "array_leaf"
    case BIR.PrimArrayNode{}: "array_node"
    case BIR.PrimArrayLeafValue{}: "array_leaf_value"
    case BIR.PrimArrayLeft{}: "array_left"
    case BIR.PrimArrayRight{}: "array_right"
    case BIR.PrimIsArrayLeaf{}: "is_array_leaf"
    case BIR.PrimIsArrayNode{}: "is_array_node"
    case _: "primitive"

def prim_call_part(primitive: BIR.Primitive, args: List<&2, BIR.Arg>, +plan: Plan) -> Part:
  match arg_strings(args, plan):
    case None{}: failp("BIR argument has no C value")
    case Some{values}: prim_part(primitive, values, plan)

def pcid(short: String, plan: Plan) -> Part:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, imports, fkeys, ctx}:
      cid_c(short, cids)

def prim_part(primitive: BIR.Primitive, +a: List<&2, String>, +plan: Plan) -> Part:
  +a0 = list_at(a, 0n)
  +a1 = list_at(a, 1n)
  +a2 = list_at(a, 2n)
  match primitive:
    case BIR.PrimU32Add{}: okp(cat(["U32_BIN(", a0, ", +, ", a1, ")"]))
    case BIR.PrimU32Sub{}: okp(cat(["U32_BIN(", a0, ", -, ", a1, ")"]))
    case BIR.PrimU32Mul{}: okp(cat(["U32_BIN(", a0, ", *, ", a1, ")"]))
    case BIR.PrimU32Div{}: okp(cat(["((u32)(", a1, ") == 0 ? 0 : (u64)U32_QUO((u32)(", a0, "), (u32)(", a1, ")))"]))
    case BIR.PrimU32Mod{}: okp(cat(["((u32)(", a1, ") == 0 ? ", a0, " : U32_BIN(", a0, ", -, U32_QUO((u32)(", a0, "), (u32)(", a1, ")) * ", a1, "))"]))
    case BIR.PrimU32And{}: okp(cat(["U32_BIN(", a0, ", &, ", a1, ")"]))
    case BIR.PrimU32Or{}: okp(cat(["U32_BIN(", a0, ", |, ", a1, ")"]))
    case BIR.PrimU32Xor{}: okp(cat(["U32_BIN(", a0, ", ^, ", a1, ")"]))
    case BIR.PrimU32IsEq{}: okp(cat(["U32_BIN(", a0, ", ==, ", a1, ")"]))
    case BIR.PrimU32IsNe{}: okp(cat(["U32_BIN(", a0, ", !=, ", a1, ")"]))
    case BIR.PrimU32IsLt{}: okp(cat(["U32_BIN(", a0, ", <, ", a1, ")"]))
    case BIR.PrimU32IsLe{}: okp(cat(["U32_BIN(", a0, ", <=, ", a1, ")"]))
    case BIR.PrimU32IsGt{}: okp(cat(["U32_BIN(", a0, ", >, ", a1, ")"]))
    case BIR.PrimU32IsGe{}: okp(cat(["U32_BIN(", a0, ", >=, ", a1, ")"]))
    case BIR.PrimU32IsZero{}: okp(cat(["U32_BIN(", a0, ", ==, 0)"]))
    case BIR.PrimU32Inc{}: okp(cat(["U32_BIN(", a0, ", +, 1)"]))
    case BIR.PrimU32Not{}: okp(cat(["((u64)~(u32)(", a0, "))"]))
    case BIR.PrimU32Shl{}: okp(cat(["U32_BIN(", a0, ", <<, 1)"]))
    case BIR.PrimU32Shr{}: okp(cat(["U32_BIN(", a0, ", >>, 1)"]))
    case BIR.PrimU32Shln{}: okp(cat(["(", a1, " >= 32 ? 0 : U32_BIN(", a0, ", <<, ", a1, "))"]))
    case BIR.PrimU32Shrn{}: okp(cat(["(", a1, " >= 32 ? 0 : U32_BIN(", a0, ", >>, ", a1, "))"]))
    case BIR.PrimU32ToNat{}: okp(cat(["((u64)", a0, ")"]))
    case BIR.PrimU32FromNat{}: okp(cat(["((u64)(u32)(", a0, "))"]))
    case BIR.PrimU32ToF32{}: okp(cat(["f32_rewrap((f32)(u32)(", a0, "))"]))
    case BIR.PrimU32Cmp{}: cmp3_part(a0, a1, plan)
    case BIR.PrimNatAdd{}: okp(cat(["nat_chk(e, ", a0, " + ", a1, ")"]))
    case BIR.PrimNatSub{}: okp(cat(["(", a0, " < ", a1, " ? 0 : ", a0, " - ", a1, ")"]))
    case BIR.PrimNatMul{}: okp(cat(["nat_mul(e, ", a0, ", ", a1, ")"]))
    case BIR.PrimNatCmp{}: cmp3_part(a0, a1, plan)
    case BIR.PrimNatMin{}: okp(cat(["(", a0, " < ", a1, " ? ", a0, " : ", a1, ")"]))
    case BIR.PrimNatMax{}: okp(cat(["(", a0, " > ", a1, " ? ", a0, " : ", a1, ")"]))
    case BIR.PrimNatIsLt{}: okp(cat(["(", a0, " < ", a1, ")"]))
    case BIR.PrimNatDouble{}: okp(cat(["nat_chk(e, ", a0, " + ", a0, ")"]))
    case BIR.PrimNatPredecessor{}: okp(cat(["bend_nat_pred(", a0, ")"]))
    case BIR.PrimNatSuccessor{}: okp(cat(["nat_chk(e, ", a0, " + 1)"]))
    case BIR.PrimNatDivmod{}: divmod_part(a0, a1, plan)
    case BIR.PrimBoolOr{}: bool2_part("bend_bool_or", a0, a1, plan)
    case BIR.PrimBoolXor{}: bool2_part("bend_bool_xor", a0, a1, plan)
    case BIR.PrimF32Add{}: f32_bin("+", a0, a1)
    case BIR.PrimF32Sub{}: f32_bin("-", a0, a1)
    case BIR.PrimF32Mul{}: f32_bin("*", a0, a1)
    case BIR.PrimF32Div{}: f32_bin("/", a0, a1)
    case BIR.PrimF32Mod{}: okp(cat(["f32_rewrap((f32)fmod(f32_unbox(", a0, "), f32_unbox(", a1, ")))"]))
    case BIR.PrimF32Neg{}: okp(cat(["f32_rewrap(-f32_unbox(", a0, "))"]))
    case BIR.PrimF32Sqrt{}: f32_un("sqrt", a0)
    case BIR.PrimF32Abs{}: f32_un("fabs", a0)
    case BIR.PrimF32Exp{}: f32_un("exp", a0)
    case BIR.PrimF32Log{}: f32_un("log", a0)
    case BIR.PrimF32Log2{}: f32_un("log2", a0)
    case BIR.PrimF32Log10{}: f32_un("log10", a0)
    case BIR.PrimF32Sin{}: f32_un("sin", a0)
    case BIR.PrimF32Cos{}: f32_un("cos", a0)
    case BIR.PrimF32Tan{}: f32_un("tan", a0)
    case BIR.PrimF32Asin{}: f32_un("asin", a0)
    case BIR.PrimF32Acos{}: f32_un("acos", a0)
    case BIR.PrimF32Atan{}: f32_un("atan", a0)
    case BIR.PrimF32Sinh{}: f32_un("sinh", a0)
    case BIR.PrimF32Cosh{}: f32_un("cosh", a0)
    case BIR.PrimF32Tanh{}: f32_un("tanh", a0)
    case BIR.PrimF32Floor{}: f32_un("floor", a0)
    case BIR.PrimF32Ceil{}: f32_un("ceil", a0)
    case BIR.PrimF32Trunc{}: f32_un("trunc", a0)
    case BIR.PrimF32Pow{}: okp(cat(["f32_rewrap((f32)pow(f32_unbox(", a0, "), f32_unbox(", a1, ")))"]))
    case BIR.PrimF32Atan2{}: okp(cat(["f32_rewrap((f32)atan2(f32_unbox(", a0, "), f32_unbox(", a1, ")))"]))
    case BIR.PrimF32IsEq{}: f32_cmp("==", a0, a1)
    case BIR.PrimF32IsNe{}: f32_cmp("!=", a0, a1)
    case BIR.PrimF32IsLt{}: f32_cmp("<", a0, a1)
    case BIR.PrimF32IsLe{}: f32_cmp("<=", a0, a1)
    case BIR.PrimF32IsGt{}: f32_cmp(">", a0, a1)
    case BIR.PrimF32IsGe{}: f32_cmp(">=", a0, a1)
    case BIR.PrimF32ToU32{}: okp(cat(["f32_to_u32(", a0, ")"]))
    case BIR.PrimF32Bits{}: okp(a0)
    case BIR.PrimF32FromBits{}: okp(a0)
    case BIR.PrimF32Show{}: okp(cat(["f32_show(e, ", a0, ")"]))
    case BIR.PrimF32Read{}: okp(cat(["f32_read(e, ", a0, ")"]))
    case BIR.PrimF32ToNat{}: okp(cat(["bend_f32_to_nat(e, ", a0, ")"]))
    case BIR.PrimStringAppend{}: str2("bend_str_append", "SCon", a0, a1, plan)
    case BIR.PrimStringEq{}: str2("bend_str_eq", "SCon", a0, a1, plan)
    case BIR.PrimStringLength{}: str1("bend_str_length", "SCon", a0, plan)
    case BIR.PrimStringToList{}: str_to_list(a0, plan)
    case BIR.PrimStringCmp{}: str_cmp(a0, a1, plan)
    case BIR.PrimStringHead{}: str1("bend_str_head", "SCon", a0, plan)
    case BIR.PrimStringTail{}: str_tail(a0, plan)
    case BIR.PrimMapBit{}: map_bit_part(a0, a1, plan)
    case BIR.PrimArrayNew{}: okp(cat(["bend_array_new(e, ", a0, ", ", a1, ")"]))
    case BIR.PrimArrayGet{}: arr2("bend_array_get", a0, a1, plan)
    case BIR.PrimArraySet{}: okp(cat(["bend_array_set(e, ", a0, ", ", a1, ", ", a2, ")"]))
    case BIR.PrimArraySwap{}: arr_swap(a0, a1, a2, plan)
    case BIR.PrimArraySize{}: arr1("bend_array_size", a0, plan)
    case BIR.PrimArrayClone{}: arr1("bend_array_clone", a0, plan)
    case BIR.PrimArrayLeaf{}: okp(cat(["bend_array_leaf(e, ", a0, ")"]))
    case BIR.PrimArrayNode{}: okp(cat(["blk_node(e, ", a0, ", ", a1, ")"]))
    case BIR.PrimArrayLeafValue{}: okp(cat(["bend_array_leaf_value(e, ", a0, ")"]))
    case BIR.PrimArrayLeft{}: okp(cat(["blk_half(e, ", a0, ", 0)"]))
    case BIR.PrimArrayRight{}: okp(cat(["blk_half(e, ", a0, ", 1)"]))
    case BIR.PrimIsArrayLeaf{}: okp(cat(["((u32)blk_cls(", a0, ") == 0)"]))
    case BIR.PrimIsArrayNode{}: okp(cat(["((u32)blk_cls(", a0, ") != 0)"]))
    case BIR.PrimIsNatZero{}: okp(cat(["(", a0, " == 0)"]))
    case BIR.PrimIsNatSuccessor{}: okp(cat(["(", a0, " > 0)"]))
    case BIR.PrimIsStringEmpty{}: str_empty("bend_str_empty", "SNil", a0, plan)
    case BIR.PrimIsStringNonempty{}: str_empty_neg(a0, plan)
    case BIR.PrimIsTrue{}: is_bool_part("True", a0, plan)
    case BIR.PrimIsFalse{}: is_bool_part("False", a0, plan)
    case BIR.PrimSameValue{}: okp(cat(["(", a0, " == ", a1, ")"]))
    case BIR.PrimFloatBitsEqual{}: okp(cat(["(", a0, " == ", a1, ")"]))
    case BIR.PrimCharNew{}: char_new_part(a0, plan)
    case BIR.PrimCharCode{}: okp(cat(["term_loc(", a0, ")"]))
    case BIR.PrimWordToU32{}: okp(cat(["term_word(e, ", a0, ")"]))
    case BIR.PrimU32ToWord{}: word_part(a0, plan)
    case BIR.PrimF32FromWord{}: okp(cat(["term_word(e, ", a0, ")"]))
    case BIR.PrimF32ToWord{}: word_part(a0, plan)
    case _: failp("BIR primitive has no C rendering")

def f32_bin(op: String, a0: String, a1: String) -> Part:
  okp(cat(["f32_rewrap(f32_unbox(", a0, ") ", op, " f32_unbox(", a1, "))"]))

def f32_un(name: String, a0: String) -> Part:
  okp(cat(["f32_rewrap((f32)", name, "(f32_unbox(", a0, ")))"]))

def f32_cmp(op: String, a0: String, a1: String) -> Part:
  okp(cat(["((u64)(f32_unbox(", a0, ") ", op, " f32_unbox(", a1, ")))"]))

def bool2_part(fn: String, a0: String, a1: String, plan: Plan) -> Part:
  match plan:
    case Plan{+cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, imports, fkeys, ctx}:
      bool2_c(fn, a0, a1, cid_c("True", cids), cid_c("False", cids))

def bool2_c(fn: String, a0: String, a1: String, t: Part, f: Part) -> Part:
  match t f:
    case PartOk{tc} PartOk{fc}: okp(cat([fn, "(e, ", tc, ", ", fc, ", ", a0, ", ", a1, ")"]))
    case PartFail{message} _: PartFail{message}
    case _ PartFail{message}: PartFail{message}

def is_bool_part(which: String, value: String, plan: Plan) -> Part:
  match pcid(which, plan):
    case PartFail{message}: PartFail{message}
    case PartOk{cid}: okp(cat(["term_aux(", value, ") == (u64)", cid]))

def cmp3_part(a0: String, a1: String, +plan: Plan) -> Part:
  lt = pcid("LT", plan)
  eq = pcid("EQ", plan)
  gt = pcid("GT", plan)
  match lt eq gt:
    case PartOk{lt_c} PartOk{eq_c} PartOk{gt_c}:
      PartOk{cat(["bend_cmp3(e, ", lt_c, ", ", eq_c, ", ", gt_c, ", ", a0, ", ", a1, ")"])}
    case PartFail{message} _ _: PartFail{message}
    case _ PartFail{message} _: PartFail{message}
    case _ _ PartFail{message}: PartFail{message}

def divmod_part(a0: String, a1: String, plan: Plan) -> Part:
  tuple = pcid("Tuple", plan)
  match tuple:
    case PartFail{message}: PartFail{message}
    case PartOk{t}: PartOk{cat(["bend_divmod(e, ", t, ", ", a0, ", ", a1, ")"])}

def str2(name: String, cid: String, a0: String, a1: String, plan: Plan) -> Part:
  match pcid(cid, plan):
    case PartFail{message}: PartFail{message}
    case PartOk{c}: PartOk{cat([name, "(e, ", c, ", ", a0, ", ", a1, ")"])}

def str1(name: String, cid: String, a0: String, plan: Plan) -> Part:
  match pcid(cid, plan):
    case PartFail{message}: PartFail{message}
    case PartOk{c}: PartOk{cat([name, "(e, ", c, ", ", a0, ")"])}

def str_empty(name: String, cid: String, a0: String, plan: Plan) -> Part:
  match pcid(cid, plan):
    case PartFail{message}: PartFail{message}
    case PartOk{c}: PartOk{cat([name, "(", a0, ", ", c, ")"])}

def str_empty_neg(a0: String, plan: Plan) -> Part:
  match pcid("SNil", plan):
    case PartFail{message}: PartFail{message}
    case PartOk{c}: PartOk{cat(["(!bend_str_empty(", a0, ", ", c, "))"])}

def str_tail(a0: String, +plan: Plan) -> Part:
  match pcid("SCon", plan) pcid("SNil", plan):
    case PartOk{scon} PartOk{snil}: PartOk{cat(["bend_str_tail(e, ", scon, ", ", snil, ", ", a0, ")"])}
    case PartFail{message} _: PartFail{message}
    case _ PartFail{message}: PartFail{message}

def str_to_list(a0: String, +plan: Plan) -> Part:
  match pcid("SCon", plan) pcid("SNil", plan) pcid("Con", plan) pcid("Nil", plan):
    case PartOk{scon} PartOk{snil} PartOk{con} PartOk{nil}:
      PartOk{cat(["bend_str_to_list(e, ", scon, ", ", snil, ", ", con, ", ", nil, ", ", a0, ")"])}
    case PartFail{message} _ _ _: PartFail{message}
    case _ PartFail{message} _ _: PartFail{message}
    case _ _ PartFail{message} _: PartFail{message}
    case _ _ _ PartFail{message}: PartFail{message}

def str_cmp(a0: String, a1: String, +plan: Plan) -> Part:
  match pcid("SCon", plan) pcid("Tuple", plan) pcid("LT", plan) pcid("EQ", plan) pcid("GT", plan):
    case PartOk{scon} PartOk{tuple} PartOk{lt} PartOk{eq} PartOk{gt}:
      PartOk{cat(["bend_str_cmp(e, ", scon, ", ", tuple, ", ", lt, ", ", eq, ", ", gt, ", ", a0, ", ", a1, ")"])}
    case PartFail{message} _ _ _ _: PartFail{message}
    case _ PartFail{message} _ _ _: PartFail{message}
    case _ _ PartFail{message} _ _: PartFail{message}
    case _ _ _ PartFail{message} _: PartFail{message}
    case _ _ _ _ PartFail{message}: PartFail{message}

def map_bit_part(a0: String, a1: String, +plan: Plan) -> Part:
  match pcid("SCon", plan) pcid("Tuple", plan) pcid("True", plan) pcid("False", plan):
    case PartOk{scon} PartOk{tuple} PartOk{t} PartOk{f}:
      PartOk{cat(["bend_map_bit(e, ", scon, ", ", tuple, ", ", t, ", ", f, ", ", a0, ", ", a1, ")"])}
    case PartFail{message} _ _ _: PartFail{message}
    case _ PartFail{message} _ _: PartFail{message}
    case _ _ PartFail{message} _: PartFail{message}
    case _ _ _ PartFail{message}: PartFail{message}

def arr1(name: String, a0: String, plan: Plan) -> Part:
  match pcid("Tuple", plan):
    case PartFail{message}: PartFail{message}
    case PartOk{t}: PartOk{cat([name, "(e, ", t, ", ", a0, ")"])}

def arr2(name: String, a0: String, a1: String, plan: Plan) -> Part:
  match pcid("Tuple", plan):
    case PartFail{message}: PartFail{message}
    case PartOk{t}: PartOk{cat([name, "(e, ", t, ", ", a0, ", ", a1, ")"])}

def arr_swap(a0: String, a1: String, a2: String, plan: Plan) -> Part:
  match pcid("Tuple", plan):
    case PartFail{message}: PartFail{message}
    case PartOk{t}: PartOk{cat(["bend_array_swap(e, ", t, ", ", a0, ", ", a1, ", ", a2, ")"])}

def char_new_part(a0: String, plan: Plan) -> Part:
  match pcid("Chr", plan):
    case PartFail{message}: PartFail{message}
    case PartOk{c}: PartOk{cat(["term_pak(", c, ", (u64)(", a0, "))"])}

def word_part(a0: String, +plan: Plan) -> Part:
  match pcid("WCon", plan) pcid("WNil", plan):
    case PartOk{con} PartOk{nil}: PartOk{cat(["bend_u32_to_word(e, ", con, ", ", nil, ", ", a0, ")"])}
    case PartFail{message} _: PartFail{message}
    case _ PartFail{message}: PartFail{message}

# ---------------------------------------------------------------------------
# Control generation
# ---------------------------------------------------------------------------
#
# One path: every entry is a WL_CASE segment, parameters arrive in r0.., a
# return is r0 plus WL_RETN(1), a tail call is a musttail WL_JMP, a self tail is
# WL_AGAIN inside the entry's WL_SPIN, and a call that must return here is a
# synthesized continuation entry. A continuation takes its captured words on
# the stack (FID_T resw = 1) and its result in r0, so the runtime's own FID_EXIT
# hands it the result through the task node its caller built.

# -- lists of U32 ids -------------------------------------------------------

def u32_member(items: List<&2, U32>, +key: U32) -> Bool:
  match items:
    case Nil{}: False{}
    case +item <> rest:
      match U32.is_eq(item, key):
        case True{}: True{}
        case False{}: u32_member(rest, key)

def u32_add(+items: List<&2, U32>, +key: U32) -> List<&2, U32>:
  match u32_member(items, key):
    case True{}: items
    case False{}: key <> items

# -- atoms and ops: which locals and capture slots are read -----------------

def atom_locals(atom: BIR.Atom, +acc: List<&2, U32>) -> List<&2, U32>:
  match atom:
    case BIR.Local{id}: u32_add(acc, id)
    case _: acc

def arg_locals(arg: BIR.Arg, acc: List<&2, U32>) -> List<&2, U32>:
  match arg:
    case BIR.Arg{use, value}: atom_locals(value, acc)

def args_locals(args: List<&2, BIR.Arg>, +acc: List<&2, U32>) -> List<&2, U32>:
  match args:
    case Nil{}: acc
    case +arg <> rest: args_locals(rest, arg_locals(arg, acc))

def field_locals(fields: List<&2, BIR.Field>, +acc: List<&2, U32>) -> List<&2, U32>:
  match fields:
    case Nil{}: acc
    case +field <> rest:
      match field:
        case BIR.Field{identity, key, use, value}: field_locals(rest, atom_locals(value, acc))

def op_locals(op: BIR.Op, +acc: List<&2, U32>) -> List<&2, U32>:
  match op:
    case BIR.Copy{value}: atom_locals(value, acc)
    case BIR.PrimitiveCall{primitive, args, types}: args_locals(args, acc)
    case BIR.Closure{code, captures, parameters}: args_locals(captures, acc)
    case BIR.Direct{code, args}: args_locals(args, acc)
    case BIR.Apply{fn, arg}: arg_locals(arg, atom_locals(fn, acc))
    case BIR.Construct{constructor, tag, fields}: field_locals(fields, acc)
    case BIR.Project{value, constructor, field, key}: atom_locals(value, acc)
    case BIR.HasTag{value, constructor, tag}: atom_locals(value, acc)
    case _: acc

def block_locals(block: BIR.Block, +acc: List<&2, U32>) -> List<&2, U32>:
  match block:
    case BIR.Return{value}: atom_locals(value, acc)
    case BIR.Let{id, op, next}: block_locals(next, op_locals(op, acc))
    case BIR.Branch{condition, yes, no}: block_locals(no, block_locals(yes, atom_locals(condition, acc)))
    case BIR.Region{label, body, next}: block_locals(next, block_locals(body, acc))
    case BIR.LeaveRegion{label}: acc
    case BIR.TailDirect{code, args}: args_locals(args, acc)
    case BIR.TailApply{fn, arg}: arg_locals(arg, atom_locals(fn, acc))
    case BIR.Failure{message}: acc

def atom_slots(atom: BIR.Atom, +acc: List<&2, U32>) -> List<&2, U32>:
  match atom:
    case BIR.Capture{slot}: u32_add(acc, slot)
    case _: acc

def arg_slots(arg: BIR.Arg, acc: List<&2, U32>) -> List<&2, U32>:
  match arg:
    case BIR.Arg{use, value}: atom_slots(value, acc)

def args_slots(args: List<&2, BIR.Arg>, +acc: List<&2, U32>) -> List<&2, U32>:
  match args:
    case Nil{}: acc
    case +arg <> rest: args_slots(rest, arg_slots(arg, acc))

def field_slots(fields: List<&2, BIR.Field>, +acc: List<&2, U32>) -> List<&2, U32>:
  match fields:
    case Nil{}: acc
    case +field <> rest:
      match field:
        case BIR.Field{identity, key, use, value}: field_slots(rest, atom_slots(value, acc))

def op_slots(op: BIR.Op, +acc: List<&2, U32>) -> List<&2, U32>:
  match op:
    case BIR.Copy{value}: atom_slots(value, acc)
    case BIR.PrimitiveCall{primitive, args, types}: args_slots(args, acc)
    case BIR.Closure{code, captures, parameters}: args_slots(captures, acc)
    case BIR.Direct{code, args}: args_slots(args, acc)
    case BIR.Apply{fn, arg}: arg_slots(arg, atom_slots(fn, acc))
    case BIR.Construct{constructor, tag, fields}: field_slots(fields, acc)
    case BIR.Project{value, constructor, field, key}: atom_slots(value, acc)
    case BIR.HasTag{value, constructor, tag}: atom_slots(value, acc)
    case _: acc

def block_slots(block: BIR.Block, +acc: List<&2, U32>) -> List<&2, U32>:
  match block:
    case BIR.Return{value}: atom_slots(value, acc)
    case BIR.Let{id, op, next}: block_slots(next, op_slots(op, acc))
    case BIR.Branch{condition, yes, no}: block_slots(no, block_slots(yes, atom_slots(condition, acc)))
    case BIR.Region{label, body, next}: block_slots(next, block_slots(body, acc))
    case BIR.LeaveRegion{label}: acc
    case BIR.TailDirect{code, args}: args_slots(args, acc)
    case BIR.TailApply{fn, arg}: arg_slots(arg, atom_slots(fn, acc))
    case BIR.Failure{message}: acc

# -- environment and captures ----------------------------------------------

def env_get(env: List<&2, Env>, +id: U32) -> Maybe<&2, String>:
  match env:
    case Nil{}: None{}
    case +binding <> rest:
      match binding:
        case Env{known, expr}: env_get_one(U32.is_eq(known, id), expr, rest, id)

def env_get_one(found: Bool, expr: String, rest: List<&2, Env>, id: U32) -> Maybe<&2, String>:
  match found:
    case True{}: Some{expr}
    case False{}: env_get(rest, id)

def region_refs(regions: List<&2, Region>, +acc: List<&2, CapRef>) -> List<&2, CapRef>:
  match regions:
    case Nil{}: acc
    case +row <> rest:
      match row:
        case Region{label, fid, refs}: region_refs(rest, List.append(&2, CapRef, refs, acc))

def refs_have_local(refs: List<&2, CapRef>, +id: U32) -> Bool:
  match refs:
    case Nil{}: False{}
    case +ref <> rest:
      match ref:
        case CapLocalRef{known}: refs_local_check(U32.is_eq(known, id), rest, id)
        case _: refs_have_local(rest, id)

def refs_local_check(same: Bool, rest: List<&2, CapRef>, id: U32) -> Bool:
  match same:
    case True{}: True{}
    case False{}: refs_have_local(rest, id)

def refs_have_slot(refs: List<&2, CapRef>, +slot: U32) -> Bool:
  match refs:
    case Nil{}: False{}
    case +ref <> rest:
      match ref:
        case CapSlotRef{known}: refs_slot_check(U32.is_eq(known, slot), rest, slot)
        case _: refs_have_slot(rest, slot)

def refs_slot_check(same: Bool, rest: List<&2, CapRef>, slot: U32) -> Bool:
  match same:
    case True{}: True{}
    case False{}: refs_have_slot(rest, slot)

def env_refs(env: List<&2, Env>, +used: List<&2, U32>, +inherited: List<&2, CapRef>, +acc: List<&2, CapRef>) -> List<&2, CapRef>:
  match env:
    case Nil{}: List.reverse(&2, CapRef, acc)
    case +binding <> rest:
      match binding:
        case Env{+id, expr}: env_refs(rest, used, inherited, env_ref_add(u32_member(used, id), refs_have_local(inherited, id), id, acc))

def env_ref_add(used: Bool, inherited: Bool, id: U32, +acc: List<&2, CapRef>) -> List<&2, CapRef>:
  match Bool.or(used, inherited):
    case True{}: CapLocalRef{id} <> acc
    case False{}: acc

def slot_refs(+slot: Nat, +caps_n: Nat, +used: List<&2, U32>, +inherited: List<&2, CapRef>, +acc: List<&2, CapRef>) -> List<&2, CapRef>:
  match Nat.is_lt(slot, caps_n):
    case False{}: acc
    case True{}:
      +id = U32.from_nat(slot)
      slot_refs(Nat.add(slot, 1n), caps_n, used, inherited, slot_ref_add(u32_member(used, id), refs_have_slot(inherited, id), id, acc))

def slot_ref_add(used: Bool, inherited: Bool, slot: U32, +acc: List<&2, CapRef>) -> List<&2, CapRef>:
  match Bool.or(used, inherited):
    case True{}: CapSlotRef{slot} <> acc
    case False{}: acc

# Every value the remaining block reads from before its own bindings, plus every
# value an enclosing region may need on its LeaveRegion jump.
def needed_refs(+block: BIR.Block, +ctx: Ctx) -> List<&2, CapRef>:
  used = block_locals(block, Nil{})
  slots = block_slots(block, Nil{})
  +inherited = region_refs(ctx_regions(ctx), Nil{})
  locals = env_refs(ctx_env(ctx), used, inherited, Nil{})
  slots_done = slot_refs(0n, ctx_caps_n(ctx), slots, inherited, Nil{})
  List.append(&2, CapRef, locals, List.reverse(&2, CapRef, slots_done))

def refs_caps(refs: List<&2, CapRef>, +ctx: Ctx) -> Maybe<&2, List<&2, Cap>>:
  match refs:
    case Nil{}: Some{Nil{}}
    case +ref <> rest:
      match cap_of_ref(ref, ctx) refs_caps(rest, ctx):
        case Some{cap} Some{caps}: Some{cap <> caps}
        case _ _: None{}

def cap_of_ref(ref: CapRef, +ctx: Ctx) -> Maybe<&2, Cap>:
  match ref:
    case CapLocalRef{+id}:
      match env_get(ctx_env(ctx), id):
        case Some{expr}: Some{CapLocal{id, expr}}
        case None{}: None{}
    case CapSlotRef{+slot}:
      match Nat.is_lt(U32.to_nat(slot), ctx_caps_n(ctx)):
        case False{}: None{}
        case True{}: Some{CapSlot{slot, list_at(ctx_caps(ctx), U32.to_nat(slot))}}

def capture_for(block: BIR.Block, +ctx: Ctx) -> Maybe<&2, List<&2, Cap>>:
  refs_caps(needed_refs(block, ctx), ctx)


def ctx_sig(c: Ctx) -> Sig:
  match c:
    case Ctx{sig, plan, env, caps, caps_n, regions, self_fid, next, segs, outs, spin, max_arity}: sig

def ctx_plan(c: Ctx) -> Plan:
  match c:
    case Ctx{sig, plan, env, caps, caps_n, regions, self_fid, next, segs, outs, spin, max_arity}: plan

def ctx_env(c: Ctx) -> List<&2, Env>:
  match c:
    case Ctx{sig, plan, env, caps, caps_n, regions, self_fid, next, segs, outs, spin, max_arity}: env

def ctx_caps(c: Ctx) -> List<&2, String>:
  match c:
    case Ctx{sig, plan, env, caps, caps_n, regions, self_fid, next, segs, outs, spin, max_arity}: caps

def ctx_caps_n(c: Ctx) -> Nat:
  match c:
    case Ctx{sig, plan, env, caps, caps_n, regions, self_fid, next, segs, outs, spin, max_arity}: caps_n

def ctx_regions(c: Ctx) -> List<&2, Region>:
  match c:
    case Ctx{sig, plan, env, caps, caps_n, regions, self_fid, next, segs, outs, spin, max_arity}: regions

def ctx_self(c: Ctx) -> Maybe<&2, U32>:
  match c:
    case Ctx{sig, plan, env, caps, caps_n, regions, self_fid, next, segs, outs, spin, max_arity}: self_fid

def ctx_next(c: Ctx) -> U32:
  match c:
    case Ctx{sig, plan, env, caps, caps_n, regions, self_fid, next, segs, outs, spin, max_arity}: next

def ctx_segs(c: Ctx) -> List<&2, SegText>:
  match c:
    case Ctx{sig, plan, env, caps, caps_n, regions, self_fid, next, segs, outs, spin, max_arity}: segs

def ctx_outs(c: Ctx) -> List<&2, String>:
  match c:
    case Ctx{sig, plan, env, caps, caps_n, regions, self_fid, next, segs, outs, spin, max_arity}: outs

def ctx_spin(c: Ctx) -> Bool:
  match c:
    case Ctx{sig, plan, env, caps, caps_n, regions, self_fid, next, segs, outs, spin, max_arity}: spin

def ctx_max(c: Ctx) -> Nat:
  match c:
    case Ctx{sig, plan, env, caps, caps_n, regions, self_fid, next, segs, outs, spin, max_arity}: max_arity

def sig_entries(s: Sig) -> List<&2, Entry>:
  match s:
    case Sig{entries, by_code, by_key, by_foreign, by_native, stages, declarations, cids, apply_fid}: entries

def sig_by_code(s: Sig) -> Map<&2, U32>:
  match s:
    case Sig{entries, by_code, by_key, by_foreign, by_native, stages, declarations, cids, apply_fid}: by_code

def sig_by_key(s: Sig) -> Map<&2, U32>:
  match s:
    case Sig{entries, by_code, by_key, by_foreign, by_native, stages, declarations, cids, apply_fid}: by_key

def sig_by_foreign(s: Sig) -> Map<&2, U32>:
  match s:
    case Sig{entries, by_code, by_key, by_foreign, by_native, stages, declarations, cids, apply_fid}: by_foreign

def sig_by_native(s: Sig) -> Map<&2, U32>:
  match s:
    case Sig{entries, by_code, by_key, by_foreign, by_native, stages, declarations, cids, apply_fid}: by_native

def sig_stages(s: Sig) -> Map<&2, U32>:
  match s:
    case Sig{entries, by_code, by_key, by_foreign, by_native, stages, declarations, cids, apply_fid}: stages

def sig_decls(s: Sig) -> List<&2, BIR.Declaration>:
  match s:
    case Sig{entries, by_code, by_key, by_foreign, by_native, stages, declarations, cids, apply_fid}: declarations

def sig_cids(s: Sig) -> List<&2, CidRow>:
  match s:
    case Sig{entries, by_code, by_key, by_foreign, by_native, stages, declarations, cids, apply_fid}: cids

def sig_apply(s: Sig) -> U32:
  match s:
    case Sig{entries, by_code, by_key, by_foreign, by_native, stages, declarations, cids, apply_fid}: apply_fid

# -- C text helpers ---------------------------------------------------------

def a_name(index: Nat) -> String:
  String.append("a", Nat.show(index))

def r_name(index: Nat) -> String:
  String.append("r", Nat.show(index))

def lv_name(id: U32) -> String:
  String.append("lv", U32.show(id))

def a_decls(count: Nat) -> String:
  a_decls_at(0n, count)

def a_decls_at(+index: Nat, +count: Nat) -> String:
  match Nat.is_lt(index, count):
    case True{}: String.concat(["    Term ", a_name(index), " = ", r_name(index), ";\n", a_decls_at(Nat.add(index, 1n), count)])
    case False{}: ""

def x_decl(+count: Nat) -> String:
  match Nat.is_eq(count, 0n):
    case True{}: ""
    case False{}: String.concat(["    Term x[", Nat.show(count), "];\n"])

def x_fill_a(count: Nat) -> String:
  x_fill_a_at(0n, count)

def x_fill_a_at(+index: Nat, +count: Nat) -> String:
  match Nat.is_lt(index, count):
    case True{}: String.concat(["    x[", Nat.show(index), "] = a", Nat.show(index), ";\n", x_fill_a_at(Nat.add(index, 1n), count)])
    case False{}: ""

def params_bind(params: List<&2, BIR.Parameter>, +captures: Nat, +index: Nat) -> String:
  match params:
    case Nil{}: ""
    case +param <> rest:
      match param:
        case BIR.Parameter{id, use}:
          String.concat(["    Term ", lv_name(id), " = ", a_name(Nat.add(captures, index)), ";\n", params_bind(rest, captures, Nat.add(index, 1n))])

def params_env(params: List<&2, BIR.Parameter>, +captures: Nat, +index: Nat, +acc: List<&2, Env>) -> List<&2, Env>:
  match params:
    case Nil{}: List.reverse(&2, Env, acc)
    case +param <> rest:
      match param:
        case BIR.Parameter{id, use}:
          params_env(rest, captures, Nat.add(index, 1n), Env{id, String.concat(["a", Nat.show(Nat.add(captures, index))])} <> acc)

def a_caps(count: Nat) -> List<&2, String>:
  a_caps_at(0n, count)

def a_caps_at(+index: Nat, +count: Nat) -> List<&2, String>:
  match Nat.is_lt(index, count):
    case True{}: a_name(index) <> a_caps_at(Nat.add(index, 1n), count)
    case False{}: Nil{}

def caps_assign(caps: List<&2, Cap>, +index: Nat) -> String:
  match caps:
    case Nil{}: ""
    case +cap <> rest:
      match cap:
        case CapLocal{id, expr}: String.concat(["    ", r_name(index), " = ", expr, ";\n", caps_assign(rest, Nat.add(index, 1n))])
        case CapSlot{slot, expr}: String.concat(["    ", r_name(index), " = ", expr, ";\n", caps_assign(rest, Nat.add(index, 1n))])

def regs_assign(values: List<&2, String>, +index: Nat) -> String:
  match values:
    case Nil{}: ""
    case +value <> rest: String.concat(["    ", r_name(index), " = ", value, ";\n", regs_assign(rest, Nat.add(index, 1n))])

def k_decls(caps: List<&2, Cap>, +index: Nat) -> String:
  match caps:
    case Nil{}: ""
    case +cap <> rest:
      String.concat(["    Term k", Nat.show(index), " = STK(", Nat.show(index), ");\n", k_decls(rest, Nat.add(index, 1n))])

def cap_intro(caps: List<&2, Cap>, +index: Nat, +locals: String, +slots: String) -> String:
  match caps:
    case Nil{}: String.concat([locals, slots])
    case +cap <> rest:
      match cap:
        case CapLocal{id, expr}: cap_intro(rest, Nat.add(index, 1n), String.concat([locals, "    Term ", lv_name(id), " = k", Nat.show(index), ";\n"]), slots)
        case CapSlot{slot, expr}: cap_intro(rest, Nat.add(index, 1n), locals, String.concat([slots, "    x[", U32.show(slot), "] = k", Nat.show(index), ";\n"]))

def cap_intro_a(caps: List<&2, Cap>, +index: Nat, +locals: String, +slots: String) -> String:
  match caps:
    case Nil{}: String.concat([locals, slots])
    case +cap <> rest:
      match cap:
        case CapLocal{id, expr}: cap_intro_a(rest, Nat.add(index, 1n), String.concat([locals, "    Term ", lv_name(id), " = a", Nat.show(index), ";\n"]), slots)
        case CapSlot{slot, expr}: cap_intro_a(rest, Nat.add(index, 1n), locals, String.concat([slots, "    x[", U32.show(slot), "] = a", Nat.show(index), ";\n"]))

def cap_locals_env(caps: List<&2, Cap>, +acc: List<&2, Env>) -> List<&2, Env>:
  match caps:
    case Nil{}: List.reverse(&2, Env, acc)
    case +cap <> rest:
      match cap:
        case CapLocal{+id, expr}: cap_locals_env(rest, Env{id, lv_name(id)} <> acc)
        case CapSlot{slot, expr}: cap_locals_env(rest, acc)

def caps_lookup(caps: List<&2, Cap>, +slot: U32) -> Bool:
  match caps:
    case Nil{}: False{}
    case +cap <> rest:
      match cap:
        case CapSlot{known, expr}: caps_lookup_one(U32.is_eq(known, slot), rest, slot)
        case _: caps_lookup(rest, slot)

def caps_lookup_one(same: Bool, rest: List<&2, Cap>, slot: U32) -> Bool:
  match same:
    case True{}: True{}
    case False{}: caps_lookup(rest, slot)

def cap_slots_exprs(+caps: List<&2, Cap>, +count: Nat, +index: Nat, +acc: List<&2, String>) -> List<&2, String>:
  match Nat.is_lt(index, count):
    case False{}: List.reverse(&2, String, acc)
    case True{}:
      +slot = U32.from_nat(index)
      value = cap_slot_value(caps_lookup(caps, slot), slot)
      cap_slots_exprs(caps, count, Nat.add(index, 1n), value <> acc)

def cap_slot_value(found: Bool, slot: U32) -> String:
  match found:
    case True{}: String.concat(["x[", U32.show(slot), "]"])
    case False{}: "0"

# comp.ts call frame: the caller pushes [held words..., continuation FID] and
# WL_RETN dispatches to that FID after sp -= 1. The continuation pops the held
# words (WL_POPN(caps)), finds them at STK(0..caps-1), and the return words in
# r0... No task trio is installed at a call site.
def cont_prologue(+caps: List<&2, Cap>, caps_n: Nat, result: U32) -> String:
  String.concat([
    "    WL_POPN(", Nat.show(List.length(&2, Cap, caps)), ");\n",
    x_decl(caps_n),
    cap_stk_intro(caps, 0n, "", ""),
    "    Term ", lv_name(result), " = r0;\n"
  ])

def cap_stk_intro(+caps: List<&2, Cap>, +index: Nat, +locals: String, +slots: String) -> String:
  match caps:
    case Nil{}: String.concat([locals, slots])
    case +cap <> rest:
      match cap:
        case CapLocal{id, expr}: cap_stk_intro(rest, Nat.add(index, 1n), String.concat([locals, "    Term ", lv_name(id), " = STK(", Nat.show(index), ");\n"]), slots)
        case CapSlot{slot, expr}: cap_stk_intro(rest, Nat.add(index, 1n), locals, String.concat([slots, "    x[", U32.show(slot), "] = STK(", Nat.show(index), ");\n"]))

def region_prologue(+caps: List<&2, Cap>, caps_n: Nat) -> String:
  String.concat([a_decls(List.length(&2, Cap, caps)), x_decl(caps_n), cap_intro_a(caps, 0n, "", "")])

def a_rebinds(count: Nat) -> String:
  a_rebinds_at(0n, count)

def a_rebinds_at(+index: Nat, +count: Nat) -> String:
  match Nat.is_lt(index, count):
    case True{}: String.concat(["    ", a_name(index), " = ", r_name(index), ";\n", a_rebinds_at(Nat.add(index, 1n), count)])
    case False{}: ""

# Runtime-owned entries have symbolic WL_CASE definitions in the template, so a
# jump to one must spell its symbolic name; a numeric FID_<n> would refer to a
# function that is never defined.
def fid_name(+target: U32, +entries: List<&2, Entry>) -> String:
  match U32.is_eq(target, rt_entry(entries, 2n)):
    case True{}: "FID_IO_EMIT"
    case False{}:
      match U32.is_eq(target, rt_entry(entries, 3n)):
        case True{}: "FID_CLO_APPLY"
        case False{}:
          match U32.is_eq(target, rt_entry(entries, 4n)):
            case True{}: "FID_EXIT"
            case False{}:
              match U32.is_eq(target, rt_entry(entries, 5n)):
                case True{}: "FID_ENTER"
                case False{}: String.concat(["FID_", U32.show(target)])

# comp.ts reads a segment's incoming registers and stack words before
# WL_OPEN: WL_OPEN declares the outgoing register bank, so a read after it
# would see an uninitialised local. The prologue therefore stays outside.
def case_text(+index: U32, +prologue: String, +body: String, +spin: Bool) -> String:
  String.concat(["  WL_CASE(FID_", U32.show(index), ")\n  {\n", prologue, "    WL_OPEN\n", spin_open(spin), body, spin_close(spin), "  }}\n\n"])

def spin_open(spin: Bool) -> String:
  match spin:
    case True{}: "    WL_SPIN\n"
    case False{}: ""

def spin_close(spin: Bool) -> String:
  match spin:
    case True{}: "    WL_SPUN\n"
    case False{}: ""

# -- block emission ---------------------------------------------------------

def block_ctl(block: BIR.Block, +ctx: Ctx) -> Step:
  match block:
    case BIR.Return{value}: return_ctl(value, ctx)
    case BIR.Let{id, op, next}: let_ctl(id, op, next, ctx)
    case BIR.Branch{condition, yes, no}: branch_ctl(condition, yes, no, ctx)
    case BIR.Region{label, body, next}: region_ctl(label, body, next, ctx)
    case BIR.LeaveRegion{label}: leave_ctl(label, ctx)
    case BIR.TailDirect{code, args}: tail_direct_ctl(code, args, ctx)
    case BIR.TailApply{fn, arg}: tail_apply_ctl(fn, arg, ctx)
    case BIR.Failure{message}: failure_ctl(ctx)
    case _: StepFail{"BIR block form has no C rendering"}

def return_ctl(value: BIR.Atom, +ctx: Ctx) -> Step:
  match atom_part(value, ctx_plan(ctx)):
    case PartFail{message}: StepFail{message}
    case PartOk{text}: StepOk{String.concat(["    r0 = ", text, ";\n    WL_RETN(1);\n"]), ctx}

def failure_ctl(ctx: Ctx) -> Step:
  StepOk{"    err_post(e.mem, ERR_TAGS);\n    return 0;\n", ctx}

def let_ctl(+id: U32, +op: BIR.Op, +next: BIR.Block, +ctx: Ctx) -> Step:
  match op:
    case BIR.Direct{code, args}: direct_ctl(id, code, args, next, ctx)
    case BIR.Apply{fn, arg}: apply_ctl(id, fn, arg, next, ctx)
    case BIR.LoadSymbol{sym, key}: load_symbol_ctl(id, key, next, ctx)
    case BIR.Closure{code, captures, parameters}: closure_ctl(id, code, captures, parameters, next, ctx)
    case _: pure_let(id, op, next, ctx)

def pure_let(+id: U32, op: BIR.Op, next: BIR.Block, +ctx: Ctx) -> Step:
  match op_part(op, ctx_plan(ctx)):
    case PartFail{message}: StepFail{message}
    case PartOk{text}:
      match block_ctl(next, Ctx{ctx_sig(ctx), ctx_plan(ctx), Env{id, lv_name(id)} <> ctx_env(ctx), ctx_caps(ctx), ctx_caps_n(ctx), ctx_regions(ctx), ctx_self(ctx), ctx_next(ctx), ctx_segs(ctx), ctx_outs(ctx), ctx_spin(ctx), ctx_max(ctx)}):
        case StepFail{message}: StepFail{message}
        case StepOk{body, after}: StepOk{String.concat(["    Term ", lv_name(id), " = ", text, ";\n", body]), after}

def cond_part_of(part: Part, plan: Plan) -> Part:
  match part:
    case PartFail{message}: PartFail{message}
    case PartOk{text}: cond_part(text, pcid("True", plan))

def cond_part(cond: String, true_cid: Part) -> Part:
  match true_cid:
    case PartFail{message}: PartFail{message}
    case PartOk{cid}: okp(cat(["term_aux(", cond, ") == (u64)", cid]))

def branch_ctl(condition: BIR.Atom, yes: BIR.Block, no: BIR.Block, +ctx: Ctx) -> Step:
  match atom_part(condition, ctx_plan(ctx)):
    case PartFail{message}: StepFail{message}
    case PartOk{value}:
      match cond_part_of(PartOk{value}, ctx_plan(ctx)):
        case PartFail{message}: StepFail{message}
        case PartOk{cond}:
          match block_ctl(yes, ctx):
            case StepFail{message}: StepFail{message}
            case StepOk{ty, cy}:
              match block_ctl(no, cy):
                case StepFail{message}: StepFail{message}
                case StepOk{tn, cn}:
                  StepOk{String.concat(["    if (", cond, ") {\n", ty, "    } else {\n", tn, "    }\n"]), cn}

# A region's next block runs in its own entry and is reached only by
# LeaveRegion, whose tail jump reuses the current frame.
def region_ctl(label: U32, body: BIR.Block, +next: BIR.Block, +ctx: Ctx) -> Step:
  match capture_for(next, ctx):
    case None{}: StepFail{"BIR region reads a value that is not in scope"}
    case Some{caps}: region_next(label, body, next, ctx, caps, ctx_next(ctx), needed_refs(next, ctx))

def region_next(+label: U32, body: BIR.Block, next: BIR.Block, +ctx: Ctx, +caps: List<&2, Cap>, +fid: U32, +refs: List<&2, CapRef>) -> Step:
  match block_ctl(next, Ctx{ctx_sig(ctx), ctx_plan(ctx), cap_locals_env(caps, Nil{}), cap_slots_exprs(caps, ctx_caps_n(ctx), 0n, Nil{}), ctx_caps_n(ctx), Region{label, fid, refs} <> ctx_regions(ctx), None{}, U32.inc(fid), ctx_segs(ctx), ctx_outs(ctx), False{}, nat_max(ctx_max(ctx), List.length(&2, Cap, caps))}):
    case StepFail{message}: StepFail{message}
    case StepOk{tn, cn}: region_body(label, body, ctx, caps, fid, refs, tn, cn)

def region_body(label: U32, body: BIR.Block, +ctx: Ctx, +caps: List<&2, Cap>, +fid: U32, refs: List<&2, CapRef>, tn: String, +cn: Ctx) -> Step:
  match block_ctl(body, Ctx{ctx_sig(ctx), ctx_plan(ctx), ctx_env(ctx), ctx_caps(ctx), ctx_caps_n(ctx), Region{label, fid, refs} <> ctx_regions(ctx), ctx_self(ctx), ctx_next(cn), SegText{fid, List.length(&2, Cap, caps), 0n, case_text(fid, region_prologue(caps, ctx_caps_n(ctx)), tn, False{})} <> ctx_segs(cn), ctx_outs(cn), ctx_spin(ctx), ctx_max(cn)}):
    case StepFail{message}: StepFail{message}
    case StepOk{tb, +cb}:
      StepOk{tb, Ctx{ctx_sig(cb), ctx_plan(cb), ctx_env(cb), ctx_caps(cb), ctx_caps_n(cb), ctx_regions(ctx), ctx_self(ctx), ctx_next(cb), ctx_segs(cb), ctx_outs(cb), ctx_spin(cb), ctx_max(cb)}}

def find_region(regions: List<&2, Region>, +label: U32) -> Maybe<&2, Region>:
  match regions:
    case Nil{}: None{}
    case +row <> rest:
      match row:
        case Region{known, fid, refs}: find_region_one(U32.is_eq(known, label), row, rest, label)

def find_region_one(found: Bool, row: Region, rest: List<&2, Region>, label: U32) -> Maybe<&2, Region>:
  match found:
    case True{}: Some{row}
    case False{}: find_region(rest, label)

def leave_ctl(label: U32, +ctx: Ctx) -> Step:
  match find_region(ctx_regions(ctx), label):
    case None{}: StepFail{"BIR LeaveRegion names no enclosing region"}
    case Some{region}:
      match region:
        case Region{known, fid, refs}:
          match refs_caps(refs, ctx):
            case None{}: StepFail{"BIR LeaveRegion reads a value that is not in scope"}
            case Some{caps}:
              StepOk{String.concat([caps_assign(caps, 0n), "    WL_JMP(", fid_name(fid, sig_entries(ctx_sig(ctx))), ");\n"]), ctx}

def tail_direct_ctl(+code: U32, args: List<&2, BIR.Arg>, +ctx: Ctx) -> Step:
  match IndexLookup.find(U32, sig_by_code(ctx_sig(ctx)), U32.show(code)):
    case None{}: StepFail{String.concat(["BIR tail call names code ", U32.show(code), " with no entry"])}
    case Some{+target}:
      match arg_strings(args, ctx_plan(ctx)):
        case None{}: StepFail{"BIR tail argument has no C value"}
        case Some{+values}:
          match Nat.is_eq(List.length(&2, String, values), entry_arity(sig_entries(ctx_sig(ctx)), target)):
            case False{}: StepFail{"BIR tail call arity disagrees with its entry"}
            case True{}:
              match ctx_self(ctx):
                case Some{self}:
                  match U32.is_eq(self, target):
                    case True{}: self_tail(target, values, ctx)
                    case False{}: StepOk{String.concat([regs_assign(values, 0n), "    WL_JMP(", fid_name(target, sig_entries(ctx_sig(ctx))), ");\n"]), ctx}
                case None{}: StepOk{String.concat([regs_assign(values, 0n), "    WL_JMP(", fid_name(target, sig_entries(ctx_sig(ctx))), ");\n"]), ctx}

def self_tail(+target: U32, values: List<&2, String>, +ctx: Ctx) -> Step:
  +arity = entry_arity(sig_entries(ctx_sig(ctx)), target)
  text = String.concat([regs_assign(values, 0n), a_rebinds(arity), "    WL_AGAIN(", fid_name(target, sig_entries(ctx_sig(ctx))), ");\n"])
  StepOk{text, Ctx{ctx_sig(ctx), ctx_plan(ctx), ctx_env(ctx), ctx_caps(ctx), ctx_caps_n(ctx), ctx_regions(ctx), ctx_self(ctx), ctx_next(ctx), ctx_segs(ctx), ctx_outs(ctx), True{}, ctx_max(ctx)}}

def tail_apply_ctl(fn: BIR.Atom, arg: BIR.Arg, +ctx: Ctx) -> Step:
  match atom_part(fn, ctx_plan(ctx)):
    case PartFail{message}: StepFail{message}
    case PartOk{fn_text}:
      match arg:
        case BIR.Arg{use, value}:
          match atom_part(value, ctx_plan(ctx)):
            case PartFail{message}: StepFail{message}
            case PartOk{arg_text}:
              StepOk{String.concat(["    r0 = ", fn_text, ";\n    r1 = ", arg_text, ";\n    WL_JMP(FID_CLO_APPLY);\n"]), ctx}

def direct_ctl(result: U32, +code: U32, args: List<&2, BIR.Arg>, next: BIR.Block, +ctx: Ctx) -> Step:
  match IndexLookup.find(U32, sig_by_code(ctx_sig(ctx)), U32.show(code)):
    case None{}: StepFail{String.concat(["BIR call names code ", U32.show(code), " with no entry"])}
    case Some{target}:
      match arg_strings(args, ctx_plan(ctx)):
        case None{}: StepFail{"BIR call argument has no C value"}
        case Some{values}: call_ctl(target, values, result, next, ctx)

def apply_ctl(result: U32, fn: BIR.Atom, arg: BIR.Arg, next: BIR.Block, +ctx: Ctx) -> Step:
  match atom_part(fn, ctx_plan(ctx)):
    case PartFail{message}: StepFail{message}
    case PartOk{fn_text}:
      match arg:
        case BIR.Arg{use, value}:
          match atom_part(value, ctx_plan(ctx)):
            case PartFail{message}: StepFail{message}
            case PartOk{arg_text}: call_ctl(sig_apply(ctx_sig(ctx)), [fn_text, arg_text], result, next, ctx)

def call_ctl(+target: U32, +args: List<&2, String>, result: U32, +next: BIR.Block, +ctx: Ctx) -> Step:
  match Nat.is_eq(List.length(&2, String, args), entry_arity(sig_entries(ctx_sig(ctx)), target)):
    case False{}: StepFail{String.concat(["BIR call passes ", Nat.show(List.length(&2, String, args)), " arguments to an entry of arity ", Nat.show(entry_arity(sig_entries(ctx_sig(ctx)), target))])}
    case True{}:
      match capture_for(next, ctx):
        case None{}: StepFail{"BIR continuation reads a value that is not in scope"}
        case Some{caps}: call_next(target, args, result, next, ctx, caps)

def call_next(target: U32, args: List<&2, String>, +result: U32, next: BIR.Block, +ctx: Ctx, +caps: List<&2, Cap>) -> Step:
  match block_ctl(next, Ctx{ctx_sig(ctx), ctx_plan(ctx), Env{result, lv_name(result)} <> cap_locals_env(caps, Nil{}), cap_slots_exprs(caps, ctx_caps_n(ctx), 0n, Nil{}), ctx_caps_n(ctx), ctx_regions(ctx), None{}, U32.inc(ctx_next(ctx)), ctx_segs(ctx), ctx_outs(ctx), False{}, nat_max(ctx_max(ctx), Nat.add(List.length(&2, Cap, caps), 1n))}):
    case StepFail{message}: StepFail{message}
    case StepOk{text, cn}: call_done(target, args, caps, result, ctx, text, cn)

def call_done(target: U32, args: List<&2, String>, +caps: List<&2, Cap>, result: U32, +ctx: Ctx, text: String, +cn: Ctx) -> Step:
  +fid = ctx_next(ctx)
  +count = List.length(&2, Cap, caps)
  StepOk{call_head(fid, count, caps, args, target, sig_entries(ctx_sig(ctx))), Ctx{ctx_sig(cn), ctx_plan(cn), ctx_env(cn), ctx_caps(cn), ctx_caps_n(cn), ctx_regions(cn), ctx_self(cn), ctx_next(cn), SegText{fid, Nat.add(count, 1n), 1n, case_text(fid, cont_prologue(caps, ctx_caps_n(ctx), result), text, False{})} <> ctx_segs(cn), ctx_outs(cn), ctx_spin(cn), ctx_max(cn)}}

def arg_stores(+node: String, args: List<&2, String>, +index: Nat) -> String:
  match args:
    case Nil{}: ""
    case +arg <> rest: String.concat(["      e.mem[", node, " + ", Nat.show(index), "] = ", arg, ";\n", arg_stores(node, rest, Nat.add(index, 1n))])

# A call site follows comp.ts exactly: the sync path stores the continuation
# frame as plain words and pushes it; the sequential path builds the
# continuation task from the current frame's WL_CONT/WL_IDX and does not
# touch the stack. Both share the callee register load.
def call_head(+fid: U32, +count: Nat, +caps: List<&2, Cap>, +args: List<&2, String>, +target: U32, +entries: List<&2, Entry>) -> String:
  +node = String.concat(["kc", U32.show(fid)])
  +callee = String.concat(["kc", U32.show(fid), "t"])
  String.concat([
    "    if (seq) {\n",
    "      WL_ROOM(", Nat.show(Nat.add(count, 1n)), ");\n",
    cap_stk_stores(caps, 0n),
    "      STK(", Nat.show(count), ") = FID_", U32.show(fid), ";\n",
    "      WL_PUSHN(", Nat.show(Nat.add(count, 1n)), ");\n",
    "    } else {\n",
    "      u64 ", node, " = task_node(e, FID_", U32.show(fid), ", WL_CONT, WL_IDX, 1);\n",
    cap_stores(node, caps, 0n),
    "      WL_CONT = term_tsk(FID_", U32.show(fid), ", ", node, ");\n",
    "      WL_IDX = ", Nat.show(count), ";\n",
    "    }\n",
    "    if (!DEVICE && !seq && fid_nofk(", fid_name(target, entries), ")) {\n",
    "      u64 ", callee, " = task_node(e, ", fid_name(target, entries), ", WL_CONT, WL_IDX, 0);\n",
    arg_stores(callee, args, 0n),
    "      return term_tsk(", fid_name(target, entries), ", ", callee, ");\n",
    "    }\n",
    regs_assign(args, 0n),
    "    WL_JMP(", fid_name(target, entries), ");\n"
  ])

def cap_stk_stores(+caps: List<&2, Cap>, +index: Nat) -> String:
  match caps:
    case Nil{}: ""
    case +cap <> rest:
      match cap:
        case CapLocal{id, expr}: String.concat(["    STK(", Nat.show(index), ") = ", expr, ";\n", cap_stk_stores(rest, Nat.add(index, 1n))])
        case CapSlot{slot, expr}: String.concat(["    STK(", Nat.show(index), ") = ", expr, ";\n", cap_stk_stores(rest, Nat.add(index, 1n))])

def cap_stores(+node: String, caps: List<&2, Cap>, +index: Nat) -> String:
  match caps:
    case Nil{}: ""
    case +cap <> rest:
      match cap:
        case CapLocal{id, expr}: String.concat(["    e.mem[", node, " + ", Nat.show(index), "] = ", expr, ";\n", cap_stores(node, rest, Nat.add(index, 1n))])
        case CapSlot{slot, expr}: String.concat(["    e.mem[", node, " + ", Nat.show(index), "] = ", expr, ";\n", cap_stores(node, rest, Nat.add(index, 1n))])

# A foreign or native value is a staged closure; a nullary read yields the
# arity-one closure the runtime applies once with the continuation.
def load_symbol_ctl(+result: U32, +key: String, +next: BIR.Block, +ctx: Ctx) -> Step:
  match find_declaration(key, sig_decls(ctx_sig(ctx))):
    case None{}: StepFail{String.concat(["BIR reads `", key, "` with no declaration"])}
    case Some{item}:
      match item:
        case BIR.FunctionDeclaration{known, +code, parameters}:
          match Nat.is_eq(List.length(&2, BIR.Parameter, parameters), 0n):
            case False{}: StepFail{String.concat(["BIR reads the parameterised `", known, "` as a lazy symbol"])}
            case True{}:
              match IndexLookup.find(U32, sig_by_code(ctx_sig(ctx)), U32.show(code)):
                case None{}: StepFail{String.concat(["BIR reads code ", U32.show(code), " with no entry"])}
                case Some{target}: call_ctl(target, Nil{}, result, next, ctx)
        case BIR.LazyDeclaration{known, body}:
          match IndexLookup.find(U32, sig_by_key(ctx_sig(ctx)), key):
            case None{}: StepFail{String.concat(["BIR reads lazy `", key, "` with no entry"])}
            case Some{target}: call_ctl(target, Nil{}, result, next, ctx)
        case BIR.ForeignDeclaration{+key, _, _, arity, _, _, _, _, _}:
          match IndexLookup.find(U32, sig_by_foreign(ctx_sig(ctx)), key):
            case Some{fid}: value_bind_entry(result, fid, foreign_stem(key), next, ctx)
            case None{}: StepFail{String.concat(["foreign `", key, "` has no entry"])}
        case BIR.NativeDeclaration{+key, primitive, quantities}:
          match IndexLookup.find(U32, sig_by_native(ctx_sig(ctx)), key):
            case Some{fid}: value_bind_entry(result, fid, native_stem(key), next, ctx)
            case None{}: StepFail{String.concat(["native `", key, "` has no first-class C value"])}
        case _: StepFail{"BIR declaration form has no C value"}

def value_bind_entry(+result: U32, fid: U32, stem: String, next: BIR.Block, +ctx: Ctx) -> Step:
  match value_closure(fid, stem, ctx):
    case None{}: StepFail{"BIR symbol has no arity-one value entry"}
    case Some{expr}:
      match block_ctl(next, Ctx{ctx_sig(ctx), ctx_plan(ctx), Env{result, lv_name(result)} <> ctx_env(ctx), ctx_caps(ctx), ctx_caps_n(ctx), ctx_regions(ctx), ctx_self(ctx), ctx_next(ctx), ctx_segs(ctx), ctx_outs(ctx), ctx_spin(ctx), ctx_max(ctx)}):
        case StepFail{message}: StepFail{message}
        case StepOk{body, after}: StepOk{String.concat(["    Term ", lv_name(result), " = ", expr, ";\n", body]), after}

def value_closure(+fid: U32, stem: String, +ctx: Ctx) -> Maybe<&2, String>:
  +arity = entry_arity(sig_entries(ctx_sig(ctx)), fid)
  match Nat.is_eq(arity, 0n):
    case True{}: None{}
    case False{}:
      match Nat.is_eq(arity, 1n):
        case True{}: Some{String.concat(["term_clo(FID_", U32.show(fid), ", 0)"])}
        case False{}:
          match IndexLookup.find(U32, sig_stages(ctx_sig(ctx)), stage_key(stem, 0n)):
            case Some{stage}: Some{String.concat(["term_clo(FID_", U32.show(stage), ", 0)"])}
            case None{}: None{}

def closure_ctl(result: U32, +code: U32, +captures: List<&2, BIR.Arg>, parameters: List<&2, BIR.Parameter>, next: BIR.Block, +ctx: Ctx) -> Step:
  match IndexLookup.find(U32, sig_by_code(ctx_sig(ctx)), U32.show(code)):
    case None{}: StepFail{String.concat(["BIR closure names code ", U32.show(code), " with no entry"])}
    case Some{+real}:
      +total = entry_arity(sig_entries(ctx_sig(ctx)), real)
      +captured = List.length(&2, BIR.Arg, captures)
      +remaining = List.length(&2, BIR.Parameter, parameters)
      match Nat.is_eq(remaining, 0n):
        case True{}: StepFail{"BIR closure has no remaining parameter"}
        case False{}:
          match Nat.is_eq(Nat.add(captured, remaining), total):
            case False{}: StepFail{"BIR closure capture count disagrees with its code entry"}
            case True{}:
              match arg_strings(captures, ctx_plan(ctx)):
                case None{}: StepFail{"BIR capture has no C value"}
                case Some{values}: closure_bind(result, code, captured, total, real, values, next, ctx)

def closure_bind(+result: U32, code: U32, +captured: Nat, total: Nat, real: U32, values: List<&2, String>, next: BIR.Block, +ctx: Ctx) -> Step:
  match closure_entry(code, captured, total, real, ctx):
    case None{}: StepFail{"BIR closure has no staged entry"}
    case Some{fid}:
      match block_ctl(next, Ctx{ctx_sig(ctx), ctx_plan(ctx), Env{result, lv_name(result)} <> ctx_env(ctx), ctx_caps(ctx), ctx_caps_n(ctx), ctx_regions(ctx), ctx_self(ctx), ctx_next(ctx), ctx_segs(ctx), ctx_outs(ctx), ctx_spin(ctx), ctx_max(ctx)}):
        case StepFail{message}: StepFail{message}
        case StepOk{body, after}: StepOk{String.concat([closure_text(result, captured, fid, values), body]), after}

def closure_text(+result: U32, +captured: Nat, fid: U32, values: List<&2, String>) -> String:
  +node = String.concat(["nd", U32.show(result)])
  String.concat([closure_alloc_decl(captured, node, values), "    Term ", lv_name(result), " = term_clo(FID_", U32.show(fid), ", ", closure_ptr(captured, node), ");\n"])

def closure_entry(code: U32, +captured: Nat, total: Nat, real: U32, ctx: Ctx) -> Maybe<&2, U32>:
  match Nat.is_eq(Nat.add(captured, 1n), total):
    case True{}: Some{real}
    case False{}: IndexLookup.find(U32, sig_stages(ctx_sig(ctx)), stage_key(code_stem(code), captured))

def closure_alloc(+node: String, values: List<&2, String>, +index: Nat) -> String:
  match values:
    case Nil{}: ""
    case +value <> rest:
      String.concat(["    e.mem[", node, " + ", Nat.show(index), "] = ", value, ";\n", closure_alloc(node, rest, Nat.add(index, 1n))])

def closure_alloc_decl(+captured: Nat, +node: String, values: List<&2, String>) -> String:
  match Nat.is_eq(captured, 0n):
    case True{}: ""
    case False{}: String.concat(["    u64 ", node, " = heap_alloc(e, cls_fit(", Nat.show(captured), "));\n", closure_alloc(node, values, 0n)])

def closure_ptr(captured: Nat, node: String) -> String:
  match Nat.is_eq(captured, 0n):
    case True{}: "0"
    case False{}: node

# -- entries ---------------------------------------------------------------

def entries_ctl(entries: List<&2, Entry>, +ctx: Ctx) -> Step:
  match entries:
    case Nil{}: StepOk{"", ctx}
    case +entry <> rest:
      match entry_ctl(entry, ctx):
        case StepFail{message}: StepFail{message}
        case StepOk{text, c1}: entries_ctl(rest, c1)

def entry_ctl(entry: Entry, ctx: Ctx) -> Step:
  match entry:
    case Entry{index, arity, kind}: entry_kind_ctl(index, arity, kind, ctx)

def entry_kind_ctl(+index: U32, +arity: Nat, kind: EntryKind, +ctx: Ctx) -> Step:
  match kind:
    case KindCode{id, captures, params, body}: entry_code(index, arity, captures, params, body, ctx)
    case KindStage{next}: entry_stage(index, arity, next, ctx)
    case KindLazy{body}: entry_lazy(index, arity, body, ctx)
    case KindForeign{key, args}: entry_foreign(index, arity, key, args, ctx)
    case KindNative{primitive, count}: entry_native(index, arity, primitive, count, ctx)
    case KindMain{}: entry_main(index, ctx)
    case KindEmit{}: entry_reserved(index, ctx)
    case KindApply{}: entry_reserved(index, ctx)
    case KindExit{}: entry_reserved(index, ctx)
    case KindEnter{}: entry_reserved(index, ctx)

def entry_reserved(index: U32, ctx: Ctx) -> Step:
  StepOk{"", ctx}

def entry_add(index: U32, +prologue: String, +body: String, +spin: Bool, +ctx: Ctx) -> Step:
  StepOk{"", Ctx{ctx_sig(ctx), ctx_plan(ctx), ctx_env(ctx), ctx_caps(ctx), ctx_caps_n(ctx), ctx_regions(ctx), ctx_self(ctx), ctx_next(ctx), ctx_segs(ctx), case_text(index, prologue, body, spin) <> ctx_outs(ctx), False{}, ctx_max(ctx)}}

def entry_code(+index: U32, +arity: Nat, +captures: Nat, +params: List<&2, BIR.Parameter>, body: BIR.Block, +ctx: Ctx) -> Step:
  match Nat.is_eq(Nat.add(captures, List.length(&2, BIR.Parameter, params)), arity):
    case False{}: StepFail{"BIR code arity disagrees with its captures and parameters"}
    case True{}:
      match block_ctl(body, Ctx{ctx_sig(ctx), ctx_plan(ctx), params_env(params, captures, 0n, Nil{}), a_caps(captures), captures, Nil{}, Some{index}, ctx_next(ctx), ctx_segs(ctx), ctx_outs(ctx), False{}, ctx_max(ctx)}):
        case StepFail{message}: StepFail{message}
        case StepOk{text, +after}:
          entry_add(index, String.concat([a_decls(arity), x_decl(captures)]), String.concat([x_fill_a(captures), params_bind(params, captures, 0n), text]), ctx_spin(after), after)


def entry_stage(+index: U32, +arity: Nat, next: U32, ctx: Ctx) -> Step:
  +node = String.concat(["nd", U32.show(index)])
  stores = stage_stores(node, arity, 0n)
  body = String.concat([
    "    u64 ", node, " = heap_alloc(e, cls_fit(", Nat.show(arity), "));\n",
    stores,
    "    r0 = term_clo(FID_", U32.show(next), ", ", node, ");\n    WL_RETN(1);\n"
  ])
  entry_add(index, a_decls(arity), body, False{}, ctx)

def stage_stores(+node: String, +count: Nat, +index: Nat) -> String:
  match Nat.is_lt(index, count):
    case True{}: String.concat(["    e.mem[", node, " + ", Nat.show(index), "] = a", Nat.show(index), ";\n", stage_stores(node, count, Nat.add(index, 1n))])
    case False{}: ""

def entry_lazy(index: U32, arity: Nat, body: BIR.Block, +ctx: Ctx) -> Step:
  match block_ctl(body, Ctx{ctx_sig(ctx), ctx_plan(ctx), Nil{}, Nil{}, 0n, Nil{}, None{}, ctx_next(ctx), ctx_segs(ctx), ctx_outs(ctx), False{}, ctx_max(ctx)}):
    case StepFail{message}: StepFail{message}
    case StepOk{text, +after}: entry_add(index, "", text, ctx_spin(after), after)

def entry_native(index: U32, +arity: Nat, primitive: BIR.Primitive, +count: Nat, +ctx: Ctx) -> Step:
  match Nat.is_eq(arity, count):
    case False{}: StepFail{"BIR native entry arity disagrees with its live quantities"}
    case True{}:
      match prim_part(primitive, a_names(count), ctx_plan(ctx)):
        case PartFail{message}: StepFail{message}
        case PartOk{text}: entry_add(index, a_decls(arity), String.concat(["    r0 = ", text, ";\n    WL_RETN(1);\n"]), False{}, ctx)

def a_names(count: Nat) -> List<&2, String>:
  a_caps(count)

def entry_foreign(+index: U32, +arity: Nat, key: String, args: Nat, +ctx: Ctx) -> Step:
  match Nat.is_eq(arity, Nat.add(args, 1n)):
    case False{}: StepFail{"BIR foreign entry arity disagrees with its declaration"}
    case True{}:
      +node = String.concat(["nd", U32.show(index)])
      cid = cid_lookup(key, sig_cids(ctx_sig(ctx)))
      body = String.concat([
        "    u64 ", node, " = heap_alloc(e, cls_fit(", Nat.show(arity), "));\n",
        stage_stores(node, arity, 0n),
        "    r0 = term_ctr(", U32.show(cid), ", ", node, ");\n    WL_RETN(1);\n"
      ])
      entry_add(index, a_decls(arity), body, False{}, ctx)

# The top entry calls the main declaration and lets its result reach the root
# continuation the runtime installed.
def entry_main(+index: U32, +ctx: Ctx) -> Step:
  match find_declaration("main", sig_decls(ctx_sig(ctx))):
    case None{}: StepFail{"the C target has no root main definition"}
    case Some{item}:
      match item:
        case BIR.FunctionDeclaration{key, code, parameters}:
          match Nat.is_eq(List.length(&2, BIR.Parameter, parameters), 0n):
            case False{}: StepFail{"the C target's main must take no parameters"}
            case True{}: main_jump(index, IndexLookup.find(U32, sig_by_code(ctx_sig(ctx)), U32.show(code)), ctx)
        case BIR.LazyDeclaration{key, body}: main_jump(index, IndexLookup.find(U32, sig_by_key(ctx_sig(ctx)), key), ctx)
        case _: StepFail{"a native or foreign declaration cannot be the C target's main"}

def main_jump(index: U32, found: Maybe<&2, U32>, +ctx: Ctx) -> Step:
  match found:
    case None{}: StepFail{"the C target's main declaration has no entry"}
    case Some{+target}:
      match Nat.is_eq(entry_arity(sig_entries(ctx_sig(ctx)), target), 0n):
        case False{}: StepFail{"the C target's main entry must take no parameters"}
        case True{}: entry_add(index, "", String.concat(["    WL_JMP(", fid_name(target, sig_entries(ctx_sig(ctx))), ");\n"]), False{}, ctx)

# -- control plan -----------------------------------------------------------

def control_build(+plan: Plan) -> Control:
  match plan:
    case Plan{cids, cid_macros, fid_macros, +entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, imports, fkeys, ctx}:
      match entries_ctl(entries, Ctx{Sig{entries, by_code, by_key, by_foreign, by_native, stages, declarations, cids, rt_entry(entries, 3n)}, plan, Nil{}, Nil{}, 0n, Nil{}, None{}, U32.from_nat(List.length(&2, Entry, entries)), Nil{}, Nil{}, False{}, max_arity(entries)}):
        case StepFail{message}: ControlFail{message}
        case StepOk{_, +done}:
          ControlOk{String.concat([outs_text(ctx_outs(done), ""), segs_text(ctx_segs(done), "")]), rows_add_segs(ctx_segs(done), rows_add_entries(entries, Nil{})), ctx_max(done)}

def outs_text(outs: List<&2, String>, +acc: String) -> String:
  match outs:
    case Nil{}: acc
    case +text <> rest: outs_text(rest, String.append(text, acc))

def segs_text(segs: List<&2, SegText>, +acc: String) -> String:
  match segs:
    case Nil{}: acc
    case +seg <> rest:
      match seg:
        case SegText{fid, arity, resw, text}: segs_text(rest, String.append(text, acc))

def rt_entry(entries: List<&2, Entry>, want: Nat) -> U32:
  match entry_at_kind(entries, want):
    case Some{entry}:
      match entry:
        case Entry{index, arity, kind}: index
    case None{}: 0

def entry_at_kind(entries: List<&2, Entry>, +want: Nat) -> Maybe<&2, Entry>:
  match entries:
    case Nil{}: None{}
    case +entry <> rest:
      match entry:
        case Entry{index, arity, kind}:
          match Nat.is_eq(kind_want(kind), want):
            case True{}: Some{entry}
            case False{}: entry_at_kind(rest, want)

def kind_want(kind: EntryKind) -> Nat:
  match kind:
    case KindMain{}: 1n
    case KindEmit{}: 2n
    case KindApply{}: 3n
    case KindExit{}: 4n
    case KindEnter{}: 5n
    case _: 0n

# -- FID rows ---------------------------------------------------------------

def rows_add_entries(entries: List<&2, Entry>, +acc: List<&2, SegText>) -> List<&2, SegText>:
  match entries:
    case Nil{}: acc
    case +entry <> rest:
      match entry:
        case Entry{index, arity, kind}: rows_add_entries(rest, row_insert(SegText{index, arity, 0n, ""}, acc))

def rows_add_segs(segs: List<&2, SegText>, +acc: List<&2, SegText>) -> List<&2, SegText>:
  match segs:
    case Nil{}: acc
    case +seg <> rest: rows_add_segs(rest, row_insert(seg, acc))

def row_insert(+row: SegText, +rows: List<&2, SegText>) -> List<&2, SegText>:
  match rows:
    case Nil{}: [row]
    case +head <> rest:
      match row:
        case SegText{fid, arity, resw, text}:
          match head:
            case SegText{head_fid, head_arity, head_resw, head_text}:
              match U32.is_lt(fid, head_fid):
                case True{}: row <> rows
                case False{}: head <> row_insert(row, rest)

def rows_check(rows: List<&2, SegText>) -> Maybe<&2, String>:
  match rows:
    case Nil{}: None{}
    case +row <> rest:
      match row:
        case SegText{fid, arity, resw, text}:
          match Bool.and(Nat.is_le(arity, 255n), Nat.is_le(resw, 255n)):
            case True{}: rows_check(rest)
            case False{}: Some{String.concat(["entry ", U32.show(fid), " has an arity or result width the runtime table cannot store"])}

def cid_defines(cids: List<&2, CidRow>) -> String:
  match cids:
    case Nil{}: ""
    case +row <> rest:
      match row:
        case CidRow{cid, key, arity}: String.concat(["#define CID_", U32.show(cid), " ", U32.show(cid), "\n", cid_defines(rest)])

def fid_defines(rows: List<&2, SegText>) -> String:
  match rows:
    case Nil{}: ""
    case +row <> rest:
      match row:
        case SegText{+fid, arity, resw, text}: String.concat(["#define FID_", U32.show(fid), " ", U32.show(fid), "\n", fid_defines(rest)])

# CID_T[x] is {arity, hot} for the cid index x (runtime cid_arity/cid_hot).
# The hot fact is not derivable from BIR today; CIRSharing's seal plan owns it.
def cid_table(cids: List<&2, CidRow>) -> String:
  match cids:
    case Nil{}: "};\n"
    case +row <> rest:
      match row:
        case CidRow{cid, key, arity}: String.concat(["{ ", Nat.show(arity), ", 0 }, ", cid_table(rest)])

def runtime_fid_aliases(+entries: List<&2, Entry>) -> String:
  String.concat([
    "#define FID_IO_EMIT FID_", U32.show(rt_entry(entries, 2n)), "\n",
    "#define FID_CLO_APPLY FID_", U32.show(rt_entry(entries, 3n)), "\n",
    "#define FID_EXIT FID_", U32.show(rt_entry(entries, 4n)), "\n",
    "#define FID_ENTER FID_", U32.show(rt_entry(entries, 5n)), "\n"
  ])

def fid_table(rows: List<&2, SegText>) -> String:
  match rows:
    case Nil{}: " };\n"
    case +row <> rest:
      match row:
        case SegText{fid, arity, resw, text}: String.concat(["{ ", Nat.show(arity), ", ", Nat.show(resw), ", 2 }, ", fid_table(rest)])

# The runtime owns the IO_EMIT/CLO_APPLY/EXIT/ENTER cases under their symbolic
# names; their numeric rows must not also appear in WL_TABLE or the linker sees
# undefined WL_FID_<n>. The template appends WL_X(FID_ENTER) itself, so the
# table ends with the fixed EXIT row.
def wl_table_text(rows: List<&2, SegText>, +entries: List<&2, Entry>) -> String:
  wl_table_rows(rows, entries)

def wl_table_rows(rows: List<&2, SegText>, +entries: List<&2, Entry>) -> String:
  match rows:
    case Nil{}: ""
    case +row <> rest:
      match row:
        case SegText{+fid, arity, resw, text}:
          match wl_row_text(fid, entries):
            case None{}: wl_table_rows(rest, entries)
            case Some{name}: String.concat([name, " ", wl_table_rows(rest, entries)])

# One row per fid index. ENTER is dispatched by work_loop directly, so the
# table omits it (the template appends its declaration). The runtime-owned
# cases keep their symbolic names, matching the template definitions.
def wl_row_text(+fid: U32, +entries: List<&2, Entry>) -> Maybe<&2, String>:
  Some{wl_row_name(fid, entries)}

def wl_row_name(+fid: U32, +entries: List<&2, Entry>) -> String:
  match U32.is_eq(fid, rt_entry(entries, 2n)):
    case True{}: "WL_X(FID_IO_EMIT)"
    case False{}:
      match U32.is_eq(fid, rt_entry(entries, 3n)):
        case True{}: "WL_X(FID_CLO_APPLY)"
        case False{}:
          match U32.is_eq(fid, rt_entry(entries, 4n)):
            case True{}: "WL_X(FID_EXIT)"
            case False{}:
              match U32.is_eq(fid, rt_entry(entries, 5n)):
                case True{}: "WL_X(FID_ENTER)"
                case False{}: String.concat(["WL_X(FID_", U32.show(fid), ")"])

# -- runtime tables ---------------------------------------------------------

def registers_each(+count: Nat, +index: Nat) -> List<&2, String>:
  match Nat.is_lt(index, count):
    case True{}: r_name(index) <> registers_each(count, Nat.add(index, 1n))
    case False{}: Nil{}

def register_decls(count: Nat) -> String:
  register_list(registers_each(count, 0n), "Term ")

def register_names(count: Nat) -> String:
  register_list(registers_each(count, 0n), "")

def register_list(names: List<&2, String>, +prefix: String) -> String:
  match names:
    case Nil{}: ""
    case +name <> rest: String.concat([prefix, name, register_tail(rest, prefix)])

def register_tail(+rest: List<&2, String>, prefix: String) -> String:
  match rest:
    case Nil{}: ""
    case _: String.concat([", ", register_list(rest, prefix)])

def wl_load_rows(+count: Nat, +index: Nat) -> String:
  match Nat.is_lt(index, count):
    case True{}: String.concat(["    if ((N) <= ", Nat.show(index), ") break; ", r_name(index), " = e.mem[(A) + ", Nat.show(index), "]; \\\n", wl_load_rows(count, Nat.add(index, 1n))])
    case False{}: ""

def wl_last_rows(+count: Nat, +index: Nat) -> String:
  match Nat.is_lt(index, count):
    case True{}: String.concat(["    case ", Nat.show(index), ": ", r_name(index), " = (X); \\\n      break; \\\n", wl_last_rows(count, Nat.add(index, 1n))])
    case False{}: ""

def wl_macros(+regs: Nat) -> String:
  String.concat([
    "#define WL_RESW 1\n#define BANGS 0\n\n",
    "#define WL_BANK Term ", register_names(regs), ";\n\n",
    "#define WL_LOAD(A, N) do { \\\n", wl_load_rows(regs, 0n), "  } while (0);\n\n",
    "#define WL_LAST(X) switch (war) { \\\n", wl_last_rows(regs, 0n), "  }\n\n",
    "#define WL_SAVE(V) (V)[0] = r0;\n",
    "#define WL_TAKE(V) r0 = (V)[0];\n\n",
    "#define WL_SIG Env e, DEV Term* sp, u32 seq, u32 rn, ", register_decls(regs), "\n",
    "#define WL_ALL e, sp, seq, rn, ", register_names(regs), "\n"
  ])

def runtime_defines(+entries: List<&2, Entry>) -> String:
  String.concat([
    "#define FID_MAIN ", U32.show(rt_entry(entries, 1n)), "\n",
    "#define FID_IO_EMIT ", U32.show(rt_entry(entries, 2n)), "\n",
    "#define FID_CLO_APPLY ", U32.show(rt_entry(entries, 3n)), "\n",
    "#define FID_EXIT ", U32.show(rt_entry(entries, 4n)), "\n",
    "#define FID_ENTER ", U32.show(rt_entry(entries, 5n)), "\n"
  ])

def tables_part(plan: Plan, +rows: List<&2, SegText>, regs: Nat) -> Part:
  match plan:
    case Plan{+cids, cid_macros, fid_macros, +entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, imports, fkeys, ctx}:
      PartOk{String.concat([
        part_text(runtime_cid_aliases(cids)),
        cid_defines(cids),
        fid_defines(rows),
        runtime_defines(entries), "\n",
        "CONSTV u8 CID_T[][2] = { ", cid_table(cids), "\n",
        "CONSTV u8 FID_T[][3] = { ", fid_table(rows), "\n",
        "#define STAT_LEN 0\n\n",
        wl_macros(regs), "\n",
        "#define WL_TABLE ", wl_table_text(rows, entries), "\n",
        "#define MAIN_FID FID_", U32.show(rt_entry(entries, 1n)), "\n",
        "#define MAIN_PURE ", main_pure_text(main_pure), "\n",
        "#define BLK_SHR 0\n\n",
        "#if !DEVICE\nstatic const u32 SHOW_DESC[] = { ", show_desc, " };\nstatic const char* SHOW_NAMES[] = { ", show_names, " };\n#endif\n\n"
      ])}

def main_pure_text(pure: Bool) -> String:
  match pure:
    case True{}: "1"
    case False{}: "0"

# The helper core defines the C words the generated segments call inline; it
# must sit after the runtime's memory/term definitions (the Spins slot) but
# before the Segments slot. bend_text alone needs io_str, which the runtime
# defines after Spins, so it is declared here and defined in Requests.
def spins_part() -> Part:
  okp(String.concat([
    "typedef u64 Nat;\n",
    helper_core(),
    "static Term bend_text(Env e, const char* p, u64 n);\n",
    "CONSTV u64 STAT_IMG[] = { 0 };\n"
  ]))

def part_text(part: Part) -> String:
  match part:
    case PartOk{text}: text
    case PartFail{message}: ""

def helper_prototypes() -> String:
  cat([
    "static u64 nat_chk(Env e, u64 n);\n",
    "static u64 nat_mul(Env e, u64 a, u64 b);\n",
    "static void err_post(Corpus H, Err code);\n",
    "static u32 cls_fit(u32 words);\n",
    "static u64 heap_alloc(Env e, u32 cls);\n",
    "static u64 term_peek(DEV u64* H, Term t);\n",
    "static Term term_keep(Env e, Term t, u32 k);\n",
    "static void term_drop(Env e, Term t);\n",
    "static u64 ctr_take(Env e, Term t, u32 n, THR Term* out);\n",
    "static void spare_free(Env e, u32 cls, u64 loc);\n",
    "static u32 blk_cls(Term t);\n",
    "static Term blk_node(Env e, Term l, Term r);\n",
    "static Term blk_half(Env e, Term a, u32 hi);\n",
    "static Term blk_copy(Env e, Term a);\n",
    "static Term blk_new(Env e, bool arr, u64 d, u32 lgs, u32 n, THR Term* v);\n",
    "static u64 blk_at(Term a, u64 i, u32 lgs);\n",
    "static Term blk_read(DEV u64* H, bool arr, u64 loc, u32 i);\n",
    "static void blk_write(DEV u64* H, bool arr, u64 loc, u32 i, Term v);\n",
    "static Term term_word(Env e, Term w);\n",
    "static Term io_str(Env e, const char* p, u64 n);\n",
    "static Term f32_show(Env e, Term x);\n",
    "static Term f32_read(Env e, Term s);\n"
  ])

def helper_core() -> String:
  cat([
    "static Term bend_node(Env e, u32 cid, u32 n, THR Term* v) {\n  u64 l = 0;\n  if (n != 0) {\n    l = heap_alloc(e, cls_fit(n));\n    for (u32 i = 0; i < n; i += 1) {\n      e.mem[l + i] = v[i];\n    }\n  }\n  return term_ctr(cid, l);\n}\n\n",
    "static Term bend_project(Env e, Term v, u32 field) {\n  if (term_tag(v) == TAG_PAK) {\n    return term_loc(v);\n  }\n  return e.mem[term_peek(e.mem, v) + field];\n}\n\n",
    "static u64 bend_hastag(Term v, u32 cid) {\n  u64 tag = term_tag(v);\n  return (tag == TAG_CTR || tag == TAG_PAK) && term_aux(v) == (u64)cid;\n}\n\n",
    "static Nat bend_nat_pred(Nat v) {\n  return v == 0 ? 0 : v - 1;\n}\n\n",
    "static Nat bend_f32_to_nat(Env e, Term v) {\n  f32 x = f32_unbox(v);\n  return nat_chk(e, x < 0.0f ? 0 : (u64)x);\n}\n\n",
    "static Term bend_tuple(Env e, u32 cid, Term a, Term b) {\n  u64 l = heap_alloc(e, cls_fit(2));\n  e.mem[l] = a;\n  e.mem[l + 1] = b;\n  return term_ctr(cid, l);\n}\n\n",
    "static Term bend_box_enum(Env e, const u32* cids, u32 n, u64 tag) {\n  (void)e;\n  return term_pak(tag < (u64)n ? cids[tag] : (n == 0 ? 0 : cids[0]), 0);\n}\n\n",
    "static Term bend_bool(Env e, u32 t, u32 f, u64 c) {\n  (void)e;\n  return term_pak(c != 0 ? t : f, 0);\n}\n\n",
    "static Term bend_bool_or(Env e, u32 t, u32 f, Term a, Term b) {\n  (void)e;\n  return term_pak(term_aux(a) == (u64)t || term_aux(b) == (u64)t ? t : f, 0);\n}\n\n",
    "static Term bend_bool_xor(Env e, u32 t, u32 f, Term a, Term b) {\n  (void)e;\n  return term_pak(term_aux(a) == (u64)t ? term_aux(b) != (u64)t : term_aux(b) == (u64)t ? t : f, 0);\n}\n\n",
    "static Term bend_cmp3(Env e, u32 lt, u32 eq, u32 gt, Term a, Term b) {\n  return term_pak(a < b ? lt : a == b ? eq : gt, 0);\n}\n\n",
    "static Term bend_divmod(Env e, u32 cid, Term a, Term b) {\n  if (b == 0) {\n    return bend_tuple(e, cid, 0, a);\n  }\n  return bend_tuple(e, cid, a / b, a % b);\n}\n\n",
    "static Term bend_str_cons(Env e, u32 scon, u64 ch, Term tail) {\n  u64 l = heap_alloc(e, cls_fit(2));\n  e.mem[l] = ch;\n  e.mem[l + 1] = tail;\n  return term_ctr(scon, l);\n}\n\n",
    "static Term bend_str_append(Env e, u32 scon, Term a, Term b) {\n  if (term_aux(a) != (u64)scon) {\n    return b;\n  }\n  u64 l = term_peek(e.mem, a);\n  return bend_str_cons(e, scon, e.mem[l], bend_str_append(e, scon, e.mem[l + 1], b));\n}\n\n",
    "static Nat bend_str_length(Env e, u32 scon, Term a) {\n  Nat n = 0;\n  while (term_aux(a) == (u64)scon) {\n    a = e.mem[term_peek(e.mem, a) + 1];\n    n += 1;\n  }\n  return n;\n}\n\n",
    "static u32 bend_str_empty(Term a, u32 snil) {\n  return term_aux(a) == (u64)snil;\n}\n\n",
    "static Term bend_str_head(Env e, u32 scon, Term a) {\n  if (term_aux(a) != (u64)scon) {\n    return 0;\n  }\n  return e.mem[term_peek(e.mem, a)];\n}\n\n",
    "static Term bend_str_tail(Env e, u32 scon, u32 snil, Term a) {\n  if (term_aux(a) != (u64)scon) {\n    return term_pak(snil, 0);\n  }\n  return e.mem[term_peek(e.mem, a) + 1];\n}\n\n",
    "static Term bend_str_to_list(Env e, u32 scon, u32 snil, u32 con, u32 nil, Term a) {\n  if (term_aux(a) != (u64)scon) {\n    return term_pak(nil, 0);\n  }\n  u64 l = term_peek(e.mem, a);\n  Term tail = bend_str_to_list(e, scon, snil, con, nil, e.mem[l + 1]);\n  u64 n = heap_alloc(e, cls_fit(2));\n  e.mem[n] = e.mem[l];\n  e.mem[n + 1] = tail;\n  return term_ctr(con, n);\n}\n\n",
    "static u32 bend_str_eq(Env e, u32 scon, Term a, Term b) {\n  while (term_aux(a) == (u64)scon && term_aux(b) == (u64)scon) {\n    u64 la = term_peek(e.mem, a);\n    u64 lb = term_peek(e.mem, b);\n    if (e.mem[la] != e.mem[lb]) {\n      return 0;\n    }\n    a = e.mem[la + 1];\n    b = e.mem[lb + 1];\n  }\n  return term_aux(a) != (u64)scon && term_aux(b) != (u64)scon;\n}\n\n",
    "static Term bend_str_cmp(Env e, u32 scon, u32 tuple, u32 lt, u32 eq, u32 gt, Term a, Term b) {\n  Term x = a;\n  Term y = b;\n  u64 order = 1000000000ull;\n  while (term_aux(x) == (u64)scon && term_aux(y) == (u64)scon) {\n    u64 lx = term_peek(e.mem, x);\n    u64 ly = term_peek(e.mem, y);\n    if (e.mem[lx] != e.mem[ly]) {\n      order = e.mem[lx] < e.mem[ly] ? 0 : 2;\n      break;\n    }\n    x = e.mem[lx + 1];\n    y = e.mem[ly + 1];\n  }\n  if (order == 1000000000ull) {\n    u64 ex = term_aux(x) != (u64)scon;\n    u64 ey = term_aux(y) != (u64)scon;\n    order = ex && ey ? 1 : ex ? 2 : ey ? 0 : 1;\n  }\n  return bend_tuple(e, tuple, bend_tuple(e, tuple, a, b), term_pak(order == 0 ? lt : order == 1 ? eq : gt, 0));\n}\n\n",
    "static Term bend_map_bit(Env e, u32 scon, u32 tuple, u32 t, u32 f, Term key, Term pos) {\n  u64 at = 0;\n  u64 want = (u64)pos / 33ull;\n  u64 bit = (u64)pos % 33ull;\n  Term s = key;\n  while (term_aux(s) == (u64)scon && at < want) {\n    s = e.mem[term_peek(e.mem, s) + 1];\n    at += 1;\n  }\n  if (term_aux(s) != (u64)scon) {\n    return bend_tuple(e, tuple, key, term_pak(f, 0));\n  }\n  if (bit == 0) {\n    return bend_tuple(e, tuple, key, term_pak(t, 0));\n  }\n  u64 ch = e.mem[term_peek(e.mem, s)];\n  u64 set = (ch >> (32ull - bit)) & 1ull;\n  return bend_tuple(e, tuple, key, term_pak(set != 0 ? t : f, 0));\n}\n\n",
    "static Term bend_u32_to_word(Env e, u32 wcon, u32 wnil, Term x) {\n  Term w = term_pak(wnil, 0);\n  for (u32 i = 0; i < 32; i += 1) {\n    u64 l = heap_alloc(e, cls_fit(2));\n    e.mem[l] = ((u64)x >> i) & 1ull;\n    e.mem[l + 1] = w;\n    w = term_ctr(wcon, l);\n  }\n  return w;\n}\n\n",
    "static Term bend_array_new(Env e, Term v, Nat n) {\n  u64 d = 0;\n  u64 size = 1;\n  while (size < n && d < 31) {\n    size <<= 1;\n    d += 1;\n  }\n  Term one[1];\n  one[0] = v;\n  return blk_new(e, true, d, 0, 1, one);\n}\n\n",
    "static Term bend_array_set(Env e, Term a, Term i, Term v) {\n  u64 loc = term_peek(e.mem, a);\n  blk_write(e.mem, true, loc, blk_at(a, (u64)(u32)i, 0), v);\n  return a;\n}\n\n",
    "static Term bend_array_get(Env e, u32 tuple, Term a, Term i) {\n  u64 loc = term_peek(e.mem, a);\n  Term v = blk_read(e.mem, true, loc, blk_at(a, (u64)(u32)i, 0));\n  return bend_tuple(e, tuple, a, v);\n}\n\n",
    "static Term bend_array_swap(Env e, u32 tuple, Term a, Term i, Term v) {\n  u64 loc = term_peek(e.mem, a);\n  u32 ok = blk_at(a, (u64)(u32)i, 0);\n  Term old = blk_read(e.mem, true, loc, ok);\n  blk_write(e.mem, true, loc, ok, v);\n  return bend_tuple(e, tuple, a, old);\n}\n\n",
    "static Term bend_array_size(Env e, u32 tuple, Term a) {\n  return bend_tuple(e, tuple, a, 1ull << blk_cls(a));\n}\n\n",
    "static Term bend_array_clone(Env e, u32 tuple, Term a) {\n  return bend_tuple(e, tuple, a, blk_copy(e, a));\n}\n\n",
    "static Term bend_array_leaf(Env e, Term v) {\n  Term one[1];\n  one[0] = v;\n  return blk_new(e, true, 0, 0, 1, one);\n}\n\n",
    "static Term bend_array_leaf_value(Env e, Term a) {\n  return blk_read(e.mem, true, term_peek(e.mem, a), 0);\n}\n\n"
  ])

# ---------------------------------------------------------------------------
# Effect sources
# ---------------------------------------------------------------------------

def requests_part(plan: Plan) -> Part:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, imports, fkeys, ctx}:
      requests_finish(requests_check(imports, fkeys, declarations, constructors, cids, by_code, by_key, by_foreign, by_native))

def requests_finish(part: Part) -> Part:
  match part:
    case PartFail{message}: PartFail{message}
    case PartOk{text}: PartOk{String.concat([text, "static Term bend_text(Env e, const char* p, u64 n) {\n  return io_str(e, p, n);\n}\n"])}

def requests_check(+imports: List<&2, CImport>, fkeys: List<&2, String>, +declarations: List<&2, BIR.Declaration>, constructors: List<&2, BIR.ConstructorLayout>, cids: List<&2, CidRow>, by_code: Map<&2, U32>, by_key: Map<&2, U32>, by_foreign: Map<&2, U32>, by_native: Map<&2, U32>) -> Part:
  match requests_uncovered(fkeys, imports, declarations):
    case Some{key}: failp(cat(["no C import source was resolved for foreign `", key, "`; the adapter must pass the selected .c alternative"]))
    case None{}: requests_each(imports, constructors, declarations, cids, by_code, by_key, by_foreign, by_native)

def requests_uncovered(fkeys: List<&2, String>, imports: List<&2, CImport>, +declarations: List<&2, BIR.Declaration>) -> Maybe<&2, String>:
  match fkeys:
    case Nil{}: None{}
    case +key <> rest: requests_uncovered_one(foreign_namespace(key, declarations), key, rest, imports, declarations)

def foreign_namespace(key: String, declarations: List<&2, BIR.Declaration>) -> Maybe<&2, String>:
  match find_declaration(key, declarations):
    case Some{decl}: foreign_namespace_item(decl)
    case None{}: None{}

def foreign_namespace_item(decl: BIR.Declaration) -> Maybe<&2, String>:
  match decl:
    case BIR.ForeignDeclaration{_, namespace, _, _, _, _, _, _, _}: Some{namespace}
    case _: None{}

def requests_uncovered_one(namespace: Maybe<&2, String>, +key: String, rest: List<&2, String>, +imports: List<&2, CImport>, declarations: List<&2, BIR.Declaration>) -> Maybe<&2, String>:
  match namespace:
    case None{}: Some{key}
    case Some{space}:
      match import_has_namespace(imports, space):
        case True{}: requests_uncovered(rest, imports, declarations)
        case False{}: Some{key}

def import_has_namespace(imports: List<&2, CImport>, +namespace: String) -> Bool:
  match imports:
    case Nil{}: False{}
    case +imp <> rest:
      match imp:
        case CImport{_, own, _}: import_has_namespace_one(String.eq(own, namespace), rest, namespace)

def import_has_namespace_one(found: Bool, rest: List<&2, CImport>, namespace: String) -> Bool:
  match found:
    case True{}: True{}
    case False{}: import_has_namespace(rest, namespace)

def requests_each(imports: List<&2, CImport>, constructors: List<&2, BIR.ConstructorLayout>, +declarations: List<&2, BIR.Declaration>, +cids: List<&2, CidRow>, +by_code: Map<&2, U32>, +by_key: Map<&2, U32>, +by_foreign: Map<&2, U32>, +by_native: Map<&2, U32>) -> Part:
  match imports:
    case Nil{}: okp("")
    case +imp <> rest:
      match imp:
        case CImport{path, namespace, source}:
          block = cat([
            "/* effect source: ", path, " */\n",
            source, "\n"
          ])
          part_join([rewrite_source(block, namespace, cids, declarations, by_code, by_key, by_foreign, by_native), requests_each(rest, constructors, declarations, cids, by_code, by_key, by_foreign, by_native)])

def rewrite_source(source: String, +namespace: String, +cids: List<&2, CidRow>, +declarations: List<&2, BIR.Declaration>, by_code: Map<&2, U32>, by_key: Map<&2, U32>, by_foreign: Map<&2, U32>, by_native: Map<&2, U32>) -> Part:
  cid_map = namespaced_map(cid_exact_map(cids), cid_keys(cids), namespace)
  fid_exact = fid_exact_map(declarations, by_code, by_key, by_foreign, by_native)
  fid_map = namespaced_map(fid_exact, fid_keys(declarations), namespace)
  match Link.rewrite(source, cid_map, fid_map):
    case Link.LinkSuccess{linked}: PartOk{linked}
    case Link.LinkFailure{message}: PartFail{message}

def cid_keys(cids: List<&2, CidRow>) -> List<&2, String>:
  match cids:
    case Nil{}: Nil{}
    case +row <> rest:
      match row:
        case CidRow{_, key, _}: key <> cid_keys(rest)

def fid_keys(declarations: List<&2, BIR.Declaration>) -> List<&2, String>:
  match declarations:
    case Nil{}: Nil{}
    case +item <> rest:
      match item:
        case BIR.FunctionDeclaration{key, _, _}: key <> fid_keys(rest)
        case BIR.LazyDeclaration{key, _}: key <> fid_keys(rest)
        case BIR.ForeignDeclaration{key, _, _, _, _, _, _, _, _}: key <> fid_keys(rest)
        case BIR.NativeDeclaration{key, _, _}: key <> fid_keys(rest)
        case _: fid_keys(rest)

# ---------------------------------------------------------------------------
# Assembly
# ---------------------------------------------------------------------------

def insert_section(lines: List<&2, String>, +title: String, +block: String) -> Maybe<&2, List<&2, String>>:
  match lines:
    case Nil{}: None{}
    case +line <> rest:
      match String.eq(line, title):
        case True{}: insert_rule(rest, line, block)
        case False{}: insert_prefix(insert_section(rest, title, block), line)

def insert_rule(rest: List<&2, String>, line: String, block: String) -> Maybe<&2, List<&2, String>>:
  match rest:
    case Nil{}: None{}
    case +rule <> tail:
      match String.starts_with(rule, "// ==="):
        case True{}: Some{line <> (rule <> ("" <> (block <> ("" <> tail))))}
        case False{}: None{}

def insert_prefix(found: Maybe<&2, List<&2, String>>, line: String) -> Maybe<&2, List<&2, String>>:
  match found:
    case None{}: None{}
    case Some{lines}: Some{line <> lines}

def assemble(template: String, tables: String, spins: String, segments: String, requests: String) -> Maybe<&2, String>:
  match insert_section(String.split(template, '\n'), "// Tables", tables):
    case None{}: None{}
    case Some{one}: assemble_spins(one, spins, segments, requests)

def assemble_spins(lines: List<&2, String>, spins: String, segments: String, requests: String) -> Maybe<&2, String>:
  match insert_section(lines, "// Spins", spins):
    case None{}: None{}
    case Some{one}: assemble_segments(one, segments, requests)

def assemble_segments(lines: List<&2, String>, segments: String, requests: String) -> Maybe<&2, String>:
  match insert_section(lines, "// Segments", segments):
    case None{}: None{}
    case Some{one}: assemble_requests(one, requests)

def assemble_requests(lines: List<&2, String>, requests: String) -> Maybe<&2, String>:
  match insert_section(lines, "// Requests", requests):
    case None{}: None{}
    case Some{one}: Some{String.join(one, "\n")}

# ---------------------------------------------------------------------------
# CID(k) / FID(k) rewriting
# ---------------------------------------------------------------------------

def cid_exact_map(cids: List<&2, CidRow>) -> Map<&2, String>:
  cid_exact_each(cids, Map.new(&2, String))

def cid_exact_each(cids: List<&2, CidRow>, +acc: Map<&2, String>) -> Map<&2, String>:
  match cids:
    case Nil{}: acc
    case +row <> rest:
      match row:
        case CidRow{cid, key, _}: cid_exact_each(rest, Map.set(&2, String, acc, key, cid_symbol(cid)))

# Exactly as comp.ts c_ids: a source names `namespace:key` first, then the bare
# authoritative key. No suffix, case or segment guessing.
def fid_exact_map(declarations: List<&2, BIR.Declaration>, by_code: Map<&2, U32>, by_key: Map<&2, U32>, by_foreign: Map<&2, U32>, by_native: Map<&2, U32>) -> Map<&2, String>:
  fid_exact_decl(declarations, fid_fixed(Map.new(&2, String)), by_code, by_key, by_foreign, by_native)

def namespaced_map(exact: Map<&2, String>, keys: List<&2, String>, namespace: String) -> Map<&2, String>:
  namespaced_each(exact, keys, namespace)

def namespaced_each(+acc: Map<&2, String>, keys: List<&2, String>, +namespace: String) -> Map<&2, String>:
  match keys:
    case Nil{}: acc
    case +key <> rest:
      match Bool.not(String.is_empty(namespace)):
        case True{}: namespaced_each(namespaced_set(acc, key, namespace), rest, namespace)
        case False{}: namespaced_each(acc, rest, namespace)

def namespaced_set(+acc: Map<&2, String>, +key: String, namespace: String) -> Map<&2, String>:
  match IndexLookup.find(String, acc, key):
    case Some{macro}: map_set_first(acc, String.append(namespace, String.append(":", key)), macro)
    case None{}: acc

def fid_fixed(acc: Map<&2, String>) -> Map<&2, String>:
  fid_fixed_one(map_set_first(acc, "Clo~apply", "FID_CLO_APPLY"))

def fid_fixed_one(acc: Map<&2, String>) -> Map<&2, String>:
  map_set_first(acc, "IO~emit", "FID_IO_EMIT")

def fid_exact_decl(declarations: List<&2, BIR.Declaration>, +acc: Map<&2, String>, +by_code: Map<&2, U32>, +by_key: Map<&2, U32>, +by_foreign: Map<&2, U32>, +by_native: Map<&2, U32>) -> Map<&2, String>:
  match declarations:
    case Nil{}: acc
    case +item <> rest:
      match item:
        case BIR.FunctionDeclaration{key, code, parameters}:
          fid_exact_decl(rest, map_set_first(acc, key, fid_symbol(map_u32(by_code, U32.show(code)))), by_code, by_key, by_foreign, by_native)
        case BIR.LazyDeclaration{+key, body}:
          fid_exact_decl(rest, map_set_first(acc, key, fid_symbol(map_u32(by_key, key))), by_code, by_key, by_foreign, by_native)
        case BIR.ForeignDeclaration{+key, namespace, imported, arity, sources, quantities, span, parameter_types, result}:
          fid_exact_decl(rest, map_set_first(acc, key, fid_symbol(map_u32(by_foreign, key))), by_code, by_key, by_foreign, by_native)
        case BIR.NativeDeclaration{+key, primitive, quantities}:
          match IndexLookup.find(U32, by_native, key):
            case Some{index}: fid_exact_decl(rest, map_set_first(acc, key, fid_symbol(index)), by_code, by_key, by_foreign, by_native)
            case None{}: fid_exact_decl(rest, acc, by_code, by_key, by_foreign, by_native)
        case _: fid_exact_decl(rest, acc, by_code, by_key, by_foreign, by_native)

def macro_collision_cids(cids: List<&2, CidRow>) -> Maybe<&2, String>:
  macro_collision_rows(cids, Map.new(&2, String))

def macro_collision_rows(+cids: List<&2, CidRow>, seen: Map<&2, String>) -> Maybe<&2, String>:
  match cids:
    case Nil{}: None{}
    case +row <> rest:
      match row:
        case CidRow{cid, key, _}: macro_collision_one(key, cid_symbol(cid), cids, seen, rest)

def macro_collision_one(+key: String, +macro: String, cids: List<&2, CidRow>, +seen: Map<&2, String>, +rest: List<&2, CidRow>) -> Maybe<&2, String>:
  match IndexLookup.find(String, seen, macro):
    case Some{+other}:
      match String.eq(other, key):
        case True{}: macro_collision_rows(rest, seen)
        case False{}: Some{cat(["constructor keys `", other, "` and `", key, "` both sanitize to macro ", macro])}
    case None{}: macro_collision_rows(rest, Map.set(&2, String, seen, macro, key))

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def emit(program: BIR.Program, runtime: String, imports: List<&2, CImport>) -> EmitResult:
  match plan_make(program, imports):
    case PlanFail{message}: EmitFailure{message}
    case PlanOk{plan}: render(plan, runtime)

def render(+plan: Plan, runtime: String) -> EmitResult:
  match plan:
    case Plan{+cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, imports, fkeys, ctx}:
      match macro_collision_cids(cids):
        case Some{message}: EmitFailure{message}
        case None{}: render_parts(plan, runtime, cid_exact_map(cids), fid_exact_map(declarations, by_code, by_key, by_foreign, by_native))

def render_parts(+plan: Plan, runtime: String, cid_map: Map<&2, String>, fid_map: Map<&2, String>) -> EmitResult:
  match control_build(plan):
    case ControlFail{message}: EmitFailure{message}
    case ControlOk{segments, +rows, max_arity}:
      match rows_check(rows):
        case Some{message}: EmitFailure{message}
        case None{}:
          match tables_part(plan, rows, max_arity) spins_part() requests_part(plan):
            case PartFail{message} _ _: EmitFailure{message}
            case _ PartFail{message} _: EmitFailure{message}
            case _ _ PartFail{message}: EmitFailure{message}
            case PartOk{tables} PartOk{spins} PartOk{requests}: render_assemble(runtime, tables, spins, segments_text(segments), requests, cid_map, fid_map)

def segments_text(segments: String) -> String:
  String.concat(["#if !DEVICE\n", segments, "#endif\n"])

def render_assemble(runtime: String, tables: String, spins: String, segments: String, requests: String, cid_map: Map<&2, String>, fid_map: Map<&2, String>) -> EmitResult:
  match assemble(runtime, tables, spins, segments, requests):
    case None{}: EmitFailure{"the runtime source is missing one of the // Tables, // Spins, // Segments or // Requests sections"}
    case Some{source}: render_rewrite(source, cid_map, fid_map)

def render_rewrite(source: String, cid_map: Map<&2, String>, fid_map: Map<&2, String>) -> EmitResult:
  match Link.rewrite(source, cid_map, fid_map):
    case Link.LinkSuccess{linked}: EmitSuccess{linked}
    case Link.LinkFailure{message}: EmitFailure{message}
