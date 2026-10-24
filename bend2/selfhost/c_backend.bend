import Base
import ./backend_ir.bend as BIR
import ./index_lookup.bend as IndexLookup
import ./c_backend_link.bend as Link

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
  PartOk{String}
  PartFail{message: String}

type CidRow is Data:
  CidRow{cid: U32, key: String, arity: Nat}

type Kind is Data:
  KindCode{id: U32, captures: Nat, params: List<&2, BIR.Parameter>, body: BIR.Block}
  KindStage{id: U32, count: Nat}
  KindLazy{body: BIR.Block}
  KindForeign{key: String, args: Nat}
  KindNative{primitive: BIR.Primitive, count: Nat}
  KindMain{}
  KindLibrary{}
  KindEmit{}
  KindApply{}
  KindExit{}
  KindEnter{}

type Entry is Data:
  Entry{index: U32, arity: Nat, kind: Kind}

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
    library: Bool,
    exports: List<&2, BIR.Export>,
    imports: List<&2, CImport>,
    fkeys: List<&2, String>
  }

type PlanResult is Data:
  PlanOk{plan: Plan}
  PlanFail{message: String}

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
def c_escape_char(char: Char) -> String:
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

def member(items: List<&2, String>, key: String) -> Bool:
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
    case None{}: 0u

def map_str(map: Map<&2, String>, key: String) -> String:
  match IndexLookup.find(String, map, key):
    case Some{value}: value
    case None{}: ""

def map_set_first(map: Map<&2, String>, key: String, value: String) -> Map<&2, String>:
  match IndexLookup.find(String, map, key):
    case Some{_}: map
    case None{}: Map.set(&2, String, map, key, value)

def map_set_first_u32(map: Map<&2, U32>, key: String, value: U32) -> Map<&2, U32>:
  match IndexLookup.find(U32, map, key):
    case Some{_}: map
    case None{}: Map.set(&2, U32, map, key, value)

def nat_min(left: Nat, right: Nat) -> Nat:
  match Nat.is_lt(left, right):
    case True{}: left
    case False{}: right

def nat_max(left: Nat, right: Nat) -> Nat:
  match Nat.is_lt(left, right):
    case True{}: right
    case False{}: left

def last_segment(key: String) -> String:
  last_segment_list(String.split(key, '.'), key)

def last_segment_list(rest: List<&2, String>, previous: String) -> String:
  match rest:
    case Nil{}: previous
    case +one <> tail: last_segment_list(tail, one)

def list_index_of(items: List<&2, String>, key: String, index: U32) -> Maybe<&2, U32>:
  match items:
    case Nil{}: None{}
    case +item <> rest: list_index_one(String.eq(item, key), key, item, rest, index)

def list_index_one(same: Bool, key: String, item: String, rest: List<&2, String>, index: U32) -> Maybe<&2, U32>:
  match same:
    case True{}: Some{index}
    case False{}: list_index_of(rest, key, U32.inc(index))

def list_index(items: List<&2, String>, key: String) -> Maybe<&2, U32>:
  list_index_of(items, key, 0u)

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

def entry_at(entries: List<&2, Entry>, index: U32) -> Maybe<&2, Entry>:
  match entries:
    case Nil{}: None{}
    case +entry <> rest:
      match entry:
        case Entry{index: known, arity, kind}: entry_at_one(U32.is_eq(known, index), entry, rest, index)

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

def max_arity_each(entries: List<&2, Entry>, acc: Nat) -> Nat:
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

def scan_codes(codes: List<&2, BIR.Code>, scan: Scan) -> Scan:
  match codes:
    case Nil{}: scan
    case +code <> rest:
      match code:
        case BIR.Code{_, captures, parameters, body}: scan_codes(rest, scan_block(body, scan))

def scan_declarations(items: List<&2, BIR.Declaration>, scan: Scan) -> Scan:
  match items:
    case Nil{}: scan
    case +item <> rest: scan_declarations(rest, scan_declaration(item, scan))

def scan_declaration(item: BIR.Declaration, scan: Scan) -> Scan:
  match item:
    case BIR.FunctionDeclaration{key, code, parameters}: scan
    case BIR.LazyDeclaration{key, body}: scan_block(body, scan)
    case BIR.NativeDeclaration{key, primitive, quantities}: scan
    case BIR.ForeignDeclaration{key, _, _, arity, _, _, _, _, _}: scan_foreign(scan, key, arity)

def scan_foreign(scan: Scan, key: String, arity: Nat) -> Scan:
  match scan:
    case Scan{closures, reads, fkeys, farity}:
      match member(fkeys, key):
        case True{}: scan
        case False{}: Scan{closures, reads, fkeys <> [key], Map.set(&2, Nat, farity, key, arity)}

def scan_read(scan: Scan, key: String) -> Scan:
  match scan:
    case Scan{closures, reads, fkeys, farity}:
      Scan{closures, Map.set(&2, Bool, reads, key, True{}), fkeys, farity}

def scan_close(scan: Scan, code: U32, count: Nat) -> Scan:
  match scan:
    case Scan{closures, reads, fkeys, farity}:
      Scan{scan_close_min(closures, U32.show(code), count), reads, fkeys, farity}

def scan_close_min(map: Map<&2, Nat>, key: String, count: Nat) -> Map<&2, Nat>:
  match IndexLookup.find(Nat, map, key):
    case Some{old}: Map.set(&2, Nat, map, key, nat_min(old, count))
    case None{}: Map.set(&2, Nat, map, key, count)

def scan_atom(atom: BIR.Atom, scan: Scan) -> Scan:
  match atom:
    case BIR.Symbol{_, key}: scan_read(scan, key)
    case _: scan

def scan_argument(arg: BIR.Arg, scan: Scan) -> Scan:
  match arg:
    case BIR.Arg{_, value}: scan_atom(value, scan)

def scan_arguments(args: List<&2, BIR.Arg>, scan: Scan) -> Scan:
  match args:
    case Nil{}: scan
    case +arg <> rest: scan_arguments(rest, scan_argument(arg, scan))

def scan_fields(fields: List<&2, BIR.Field>, scan: Scan) -> Scan:
  match fields:
    case Nil{}: scan
    case +field <> rest:
      match field:
        case BIR.Field{_, _, _, value}: scan_fields(rest, scan_atom(value, scan))

def scan_op(op: BIR.Op, scan: Scan) -> Scan:
  match op:
    case BIR.Copy{value}: scan_atom(value, scan)
    case BIR.PrimitiveCall{primitive, args}: scan_arguments(args, scan)
    case BIR.Closure{code, captures, parameters}: scan_arguments(captures, scan_close(scan, code, List.length(&2, BIR.Arg, captures)))
    case BIR.Direct{code, args}: scan_arguments(args, scan)
    case BIR.Apply{fn, arg}: scan_argument(arg, scan_atom(fn, scan))
    case BIR.LoadSymbol{_, key}: scan_read(scan, key)
    case BIR.Construct{constructor, tag, fields}: scan_fields(fields, scan)
    case BIR.Project{value, constructor, field, key}: scan_atom(value, scan)
    case BIR.HasTag{value, constructor, tag}: scan_atom(value, scan)
    case _: scan

def scan_block(block: BIR.Block, scan: Scan) -> Scan:
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
      cid_foreign_rows(scan, cid_ctor_rows(constructors, 0u, Nil{}))

def cid_ctor_rows(rows: List<&2, BIR.ConstructorLayout>, index: U32, acc: List<&2, CidRow>) -> List<&2, CidRow>:
  match rows:
    case Nil{}: List.reverse(&2, CidRow, acc)
    case +row <> rest:
      match row:
        case BIR.ConstructorLayout{_, key, _, fields}:
          cid_ctor_rows(rest, U32.inc(index), CidRow{index, key, List.length(&2, Maybe<&2, String>, fields)} <> acc)

def cid_foreign_rows(scan: Scan, acc: List<&2, CidRow>) -> List<&2, CidRow>:
  match scan:
    case Scan{closures, reads, fkeys, farity}: cid_foreign_each(fkeys, farity, U32.from_nat(List.length(&2, CidRow, acc)), acc)

def cid_foreign_each(keys: List<&2, String>, farity: Map<&2, Nat>, index: U32, acc: List<&2, CidRow>) -> List<&2, CidRow>:
  match keys:
    case Nil{}: acc
    case +key <> rest:
      cid_foreign_each(rest, farity, U32.inc(index), List.append(&2, CidRow, acc, [CidRow{index, key, Nat.add(map_nat(farity, key), 1n)}]))

def cid_lookup(key: String, cids: List<&2, CidRow>) -> U32:
  match cids:
    case Nil{}: 0u
    case +row <> rest:
      match row:
        case CidRow{cid, key: known, arity}: cid_lookup_one(String.eq(key, known), key, cid, rest)

def cid_lookup_one(same: Bool, key: String, cid: U32, rest: List<&2, CidRow>) -> U32:
  match same:
    case True{}: cid
    case False{}: cid_lookup(key, rest)

def cid_short_one(same: Bool, short: String, cid: U32, rest: List<&2, CidRow>) -> Maybe<&2, U32>:
  match same:
    case True{}: Some{cid}
    case False{}: cid_short(short, rest)

def cid_short(short: String, cids: List<&2, CidRow>) -> Maybe<&2, U32>:
  match cids:
    case Nil{}: None{}
    case +row <> rest:
      match row:
        case CidRow{cid, key, arity}: cid_short_one(String.eq(short, key), short, cid, rest)

def cid_c(short: String, cids: List<&2, CidRow>) -> Part:
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

def fid_symbol_of(key: String, by_code: Map<&2, U32>, by_foreign: Map<&2, U32>) -> String:
  match IndexLookup.find(U32, by_code, key):
    case Some{index}: fid_symbol(index)
    case None{}: fid_symbol(map_u32(by_foreign, key))

# The regenerated runtime template still spells the fixed prelude constructors
# symbolically (gen_c_runtime.ts maps CID(k)/FID(k) to CID_<UPPER(k)>). These
# aliases are the only authoritative symbolic names: each resolves through its
# exact program key and a missing key is a hard error, never a guessed name.
def runtime_cid_alias(alias: String, key: String, cids: List<&2, CidRow>) -> Part:
  match find_cid_row(key, cids):
    case None{}: PartFail(cat(["the program has no `", key, "` constructor for the runtime symbol ", alias]))
    case Some{row}:
      match row:
        case CidRow{cid, key, arity}: okp(cat(["#define ", alias, " ", cid_symbol(cid), "\n"]))

def find_cid_row(key: String, cids: List<&2, CidRow>) -> Maybe<&2, CidRow>:
  match cids:
    case Nil{}: None{}
    case +row <> rest:
      match row:
        case CidRow{_, key: known, _}: find_cid_row_one(String.eq(key, known), row, key, rest)

def find_cid_row_one(same: Bool, row: CidRow, key: String, rest: List<&2, CidRow>) -> Maybe<&2, CidRow>:
  match same:
    case True{}: Some{row}
    case False{}: find_cid_row(key, rest)

def runtime_cid_aliases(cids: List<&2, CidRow>) -> Part:
  part_join([
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

def cid_macro_each(cids: List<&2, CidRow>, acc: Map<&2, String>) -> Map<&2, String>:
  match cids:
    case Nil{}: acc
    case +row <> rest:
      match row:
        case CidRow{_, key, _}:
          cid_macro_each(rest, map_set_first(acc, key, cid_symbol(cid_of_row(row))))

# ---------------------------------------------------------------------------
# Entries
# ---------------------------------------------------------------------------

def build_entries(program: BIR.Program, scan: Scan) -> Build:
  match program:
    case BIR.Program{codes, declarations, constructors, families, type_functions, end}:
      build_foreign(scan, build_native(declarations, build_lazy(declarations, build_codes(codes, declarations, scan, build_new()))))

def build_new() -> Build:
  Build{Nil{}, Map.new(&2, U32), Map.new(&2, U32), Map.new(&2, U32), Map.new(&2, U32), Map.new(&2, U32), 0u}

def build_codes(codes: List<&2, BIR.Code>, declarations: List<&2, BIR.Declaration>, scan: Scan, build: Build) -> Build:
  match codes:
    case Nil{}: build
    case +code <> rest:
      match code:
        case BIR.Code{id, captures, parameters, body}:
          build_codes(rest, declarations, scan, build_one_code(declarations, scan, build, id, List.length(&2, BIR.Use, captures), parameters, body))

def code_key(declarations: List<&2, BIR.Declaration>, id: U32) -> Maybe<&2, String>:
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

def closure_map(scan: Scan) -> Map<&2, Nat>:
  match scan:
    case Scan{closures, reads, fkeys, farity}: closures

def code_stage_start(declarations: List<&2, BIR.Declaration>, scan: Scan, id: U32, arity: Nat) -> Nat:
  match code_key(declarations, id):
    case None{}: stage_from_closures(scan, id, arity)
    case Some{key}: stage_from_key(map_flag(scan_reads(scan), key), scan, id, arity)

def stage_from_key(read: Bool, scan: Scan, id: U32, arity: Nat) -> Nat:
  match read:
    case True{}: 0n
    case False{}: stage_from_closures(scan, id, arity)

def stage_from_closures(scan: Scan, id: U32, arity: Nat) -> Nat:
  match IndexLookup.find(Nat, closure_map(scan), U32.show(id)):
    case Some{value}: nat_min(value, arity)
    case None{}: arity

def build_one_code(declarations: List<&2, BIR.Declaration>, scan: Scan, build: Build, id: U32, captures: Nat, parameters: List<&2, BIR.Parameter>, body: BIR.Block) -> Build:
  arity = Nat.add(captures, List.length(&2, BIR.Parameter, parameters))
  build_stage(build, id, captures, parameters, body, code_stage_start(declarations, scan, id, arity), arity)

def build_stage(build: Build, id: U32, captures: Nat, parameters: List<&2, BIR.Parameter>, body: BIR.Block, stage: Nat, arity: Nat) -> Build:
  match Nat.is_lt(stage, arity):
    case True{}: build_stage_one(build, id, captures, parameters, body, stage, arity)
    case False{}: build_real(build, id, captures, parameters, body, arity)

def build_stage_one(build: Build, id: U32, captures: Nat, parameters: List<&2, BIR.Parameter>, body: BIR.Block, stage: Nat, arity: Nat) -> Build:
  match build:
    case Build{entries, by_code, by_key, by_foreign, by_native, stages, next}:
      entry = Entry{next, Nat.add(stage, 1n), KindStage{id, Nat.add(stage, 1n)}}
      stages_next = Map.set(&2, U32, stage_key(id, stage), next, stages)
      build_stage(Build{entry <> entries, by_code, by_key, by_foreign, by_native, stages_next, U32.inc(next)}, id, captures, parameters, body, Nat.add(stage, 1n), arity)

def stage_key(id: U32, count: Nat) -> String:
  String.append(U32.show(id), String.append(":", Nat.show(count)))

def build_real(build: Build, id: U32, captures: Nat, parameters: List<&2, BIR.Parameter>, body: BIR.Block, arity: Nat) -> Build:
  match build:
    case Build{entries, by_code, by_key, by_foreign, by_native, stages, next}:
      entry = Entry{next, arity, KindCode{id, captures, parameters, body}}
      Build{entry <> entries, Map.set(&2, U32, U32.show(id), next, by_code), by_key, by_foreign, by_native, stages, U32.inc(next)}

def build_lazy(declarations: List<&2, BIR.Declaration>, build: Build) -> Build:
  match declarations:
    case Nil{}: build
    case +item <> rest:
      match item:
        case BIR.LazyDeclaration{key, body}: build_lazy(rest, build_lazy_one(build, key, body))
        case _: build_lazy(rest, build)

def build_lazy_one(build: Build, key: String, body: BIR.Block) -> Build:
  match build:
    case Build{entries, by_code, by_key, by_foreign, by_native, stages, next}:
      entry = Entry{next, 0n, KindLazy{body}}
      Build{entry <> entries, by_code, Map.set(&2, U32, key, next, by_key), by_foreign, by_native, stages, U32.inc(next)}


def live_quantities(quantities: List<&2, BIR.Quantity>, count: Nat) -> Nat:
  match quantities:
    case Nil{}: count
    case +quantity <> rest: live_quantities(rest, live_quantity_next(quantity, count))

def live_quantity_next(quantity: BIR.Quantity, count: Nat) -> Nat:
  match quantity:
    case BIR.Erased{}: count
    case _: Nat.add(count, 1n)

def native_bind(first: Bool, map: Map<&2, U32>, key: String, index: U32) -> Map<&2, U32>:
  match first:
    case True{}: Map.set(&2, U32, map, key, index)
    case False{}: map

def build_native(declarations: List<&2, BIR.Declaration>, build: Build) -> Build:
  match declarations:
    case Nil{}: build
    case +item <> rest:
      match item:
        case BIR.NativeDeclaration{key, primitive, quantities}: build_native_one(rest, build, key, primitive, live_quantities(quantities, 0n))
        case _: build_native(rest, build)

def build_native_one(rest: List<&2, BIR.Declaration>, build: Build, key: String, primitive: BIR.Primitive, count: Nat) -> Build:
  match Nat.is_eq(count, 0n):
    case True{}: build_native(rest, build)
    case False{}: build_native_stage(rest, build, key, primitive, count, 0n, True{})

def build_native_stage(rest: List<&2, BIR.Declaration>, build: Build, key: String, primitive: BIR.Primitive, count: Nat, stage: Nat, first: Bool) -> Build:
  match build:
    case Build{entries, by_code, by_key, by_foreign, by_native, stages, next}:
      match Nat.is_lt(Nat.add(stage, 1n), count):
        case True{}:
          entry = Entry{next, Nat.add(stage, 1n), KindStage{0u, Nat.add(stage, 1n)}}
          bound = native_bind(first, by_native, key, next)
          build_native_stage(rest, Build{entry <> entries, by_code, by_key, by_foreign, bound, stages, U32.inc(next)}, key, primitive, count, Nat.add(stage, 1n), False{})
        case False{}:
          entry = Entry{next, count, KindNative{primitive, count}}
          bound = native_bind(first, by_native, key, next)
          build_native(rest, Build{entry <> entries, by_code, by_key, by_foreign, bound, stages, U32.inc(next)})

def arg_names(count: Nat, index: Nat) -> List<&2, String>:
  match Nat.is_lt(index, count):
    case True{}: cat(["x[", Nat.show(index), "]"]) <> arg_names(count, Nat.add(index, 1n))
    case False{}: Nil{}

def build_foreign(scan: Scan, build: Build) -> Build:
  match scan:
    case Scan{closures, reads, fkeys, farity}: build_foreign_each(fkeys, farity, build)

def build_foreign_each(keys: List<&2, String>, farity: Map<&2, Nat>, build: Build) -> Build:
  match keys:
    case Nil{}: build
    case +key <> rest:
      match build:
        case Build{entries, by_code, by_key, by_foreign, by_native, stages, next}:
          entry = Entry{next, Nat.add(map_nat(farity, key), 1n), KindForeign{key, map_nat(farity, key)}}
          build_foreign_each(rest, farity, Build{entry <> entries, by_code, by_key, Map.set(&2, U32, key, next, by_foreign), by_native, stages, U32.inc(next)})

# Final order: program entries, the top (main or library action), then the
# runtime's own four segments, whose bodies the runtime supplies.
def finish_entries(build: Build, library: Bool) -> Build:
  match build:
    case Build{entries, by_code, by_key, by_foreign, by_native, stages, next}:
      top = Entry{next, top_arity(library), top_kind(library)}
      build_runtime(Build{top <> entries, by_code, by_key, by_foreign, by_native, stages, U32.inc(next)})

def top_arity(library: Bool) -> Nat:
  match library:
    case True{}: 1n
    case False{}: 0n

def top_kind(library: Bool) -> Kind:
  match library:
    case True{}: KindLibrary{}
    case False{}: KindMain{}

def build_runtime(build: Build) -> Build:
  match build:
    case Build{entries, by_code, by_key, by_foreign, by_native, stages, next}:
      emit = Entry{next, 1n, KindEmit{}}
      apply = Entry{U32.inc(next), 2n, KindApply{}}
      exit = Entry{U32.inc(U32.inc(next)), 0n, KindExit{}}
      enter = Entry{U32.inc(U32.inc(U32.inc(next))), 0n, KindEnter{}}
      last = U32.inc(U32.inc(U32.inc(U32.inc(next))))
      Build{enter <> exit <> apply <> emit <> entries, by_code, by_key, by_foreign, by_native, stages, last}

def entries_ascending(entries: List<&2, Entry>) -> List<&2, Entry>:
  List.reverse(&2, Entry, entries)

def fid_macro_map(declarations: List<&2, BIR.Declaration>, build: Build) -> Map<&2, String>:
  match build:
    case Build{entries: all, by_code, by_key, by_foreign, by_native, stages, next}:
      fid_macros_runtime(fid_macros_declarations(declarations, by_code, by_foreign, Map.new(&2, String)))

def fid_macros_declarations(declarations: List<&2, BIR.Declaration>, by_code: Map<&2, U32>, by_foreign: Map<&2, U32>, acc: Map<&2, String>) -> Map<&2, String>:
  match declarations:
    case Nil{}: acc
    case +item <> rest:
      match item:
        case BIR.FunctionDeclaration{key, code, parameters}:
          fid_macros_declarations(rest, by_code, by_foreign, map_set_first(acc, key, fid_symbol_of(key, by_code, by_foreign)))
        case BIR.ForeignDeclaration{key, _, _, arity, _, _, _, _, _}:
          fid_macros_declarations(rest, by_code, by_foreign, map_set_first(acc, key, fid_symbol_of(key, by_code, by_foreign)))
        case _: fid_macros_declarations(rest, by_code, by_foreign, acc)

# ---------------------------------------------------------------------------
# Plan: main kind, native constructor tables, show descriptors
# ---------------------------------------------------------------------------

def plan_make(program: BIR.Program, imports: List<&2, CImport>) -> PlanResult:
  scan = scan_program(program)
  cids = cid_rows(program, scan)
  match program:
    case BIR.Program{codes, declarations, constructors, families, type_functions, end}:
      plan_finish(program, scan, cids, constructors, families, declarations, end, imports)

def plan_finish(program: BIR.Program, scan: Scan, cids: List<&2, CidRow>, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, declarations: List<&2, BIR.Declaration>, end: BIR.Ending, imports: List<&2, CImport>) -> PlanResult:
  plan_pure(end, families, plan_top(program, scan, cids, constructors, families, declarations, end, imports))

def plan_top(program: BIR.Program, scan: Scan, cids: List<&2, CidRow>, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, declarations: List<&2, BIR.Declaration>, end: BIR.Ending, imports: List<&2, CImport>) -> PlanResult:
  library = ending_library(end)
  build = finish_entries(build_entries(program, scan), library)
  PlanOk{Plan{cids, cid_macro_map(cids), fid_macro_map(declarations, build), entries_ascending(build_entries_of(build)), by_code_of(build), by_key_of(build), by_foreign_of(build), by_native_of(build), stages_of(build), constructors, families, declarations, True{}, "{ 0 }", "", library, ending_exports(end), imports, fkeys_of(scan)}}

def plan_pure(end: BIR.Ending, families: List<&2, BIR.Family>, inner: PlanResult) -> PlanResult:
  match inner:
    case PlanFail{message}: PlanFail{message}
    case PlanOk{plan}:
      plan_set_pure(end, families, plan)

def plan_set_pure(end: BIR.Ending, families: List<&2, BIR.Family>, plan: Plan) -> PlanResult:
  match end:
    case BIR.Library{exports}: PlanOk{plan_set_pure_flags(plan, False{}, "{ 0 }", "")}
    case BIR.Executable{main_type}: plan_executable(main_type, families, plan)

def plan_set_pure_flags(plan: Plan, pure: Bool, desc: String, names: String) -> Plan:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, library, exports, imports, fkeys}:
      Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, pure, desc, names, library, exports, imports, fkeys}

def fid_macros_runtime(acc: Map<&2, String>) -> Map<&2, String>:
  fid_macros_runtime_one(map_set_first(acc, "Clo~apply", "FID_CLO_APPLY"))

def fid_macros_runtime_one(acc: Map<&2, String>) -> Map<&2, String>:
  map_set_first(acc, "IO~emit", "FID_IO_EMIT")

def plan_executable(main_type: BIR.Descriptor, families: List<&2, BIR.Family>, plan: Plan) -> PlanResult:
  match descriptor_head(main_type):
    case None{}: PlanFail{"the main type is not a resolvable type descriptor"}
    case Some{key}:
      match family_key(key, families):
        case None{}: PlanFail{String.append("the main type `", String.append(key, "` is not a declared family"))}
        case Some{family}: plan_executable_family(family, main_type, plan)

def plan_executable_family(family: BIR.Family, main_type: BIR.Descriptor, plan: Plan) -> PlanResult:
  match family:
    case BIR.Family{key, name, native, quantity_prefix, arity, arms}:
      match native:
        case Some{tag}: plan_executable_io(String.eq(tag, "IO"), family, main_type, plan)
        case None{}: plan_executable_show(family, main_type, plan)

def plan_executable_io(is_io: Bool, family: BIR.Family, main_type: BIR.Descriptor, plan: Plan) -> PlanResult:
  match is_io:
    case True{}: PlanOk{plan_set_pure_flags(plan, False{}, "{ 0 }", "")}
    case False{}: plan_executable_show(family, main_type, plan)

def plan_executable_show(family: BIR.Family, main_type: BIR.Descriptor, plan: Plan) -> PlanResult:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, library, exports, imports, fkeys}:
      match show_cells(main_type, Nil{}, constructors, families, cids):
        case None{}: PlanFail{"the main value's type has no C show layout"}
        case Some{cells}:
          PlanOk{Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, True{}, cells, show_names(constructors), library, exports, imports, fkeys}}

def show_names(constructors: List<&2, BIR.ConstructorLayout>) -> String:
  show_names_each(ctor_keys(constructors), Nil{})

def show_names_each(keys: List<&2, String>, acc: List<&2, String>) -> String:
  match keys:
    case Nil{}: String.join(List.reverse(&2, String, acc), ", ")
    case +key <> rest: show_names_each(rest, c_quote(key) <> acc)

def descriptor_head(descriptor: BIR.Descriptor) -> Maybe<&2, String>:
  match descriptor:
    case BIR.DescriptorRef{key, args}: Some{key}
    case BIR.DescriptorApplication{fn, arg}: descriptor_head(fn)
    case BIR.DescriptorFill{head, args}: descriptor_head(head)
    case BIR.DescriptorPlus{head, args}: descriptor_head(head)
    case BIR.DescriptorNamedFill{key, head, args}: descriptor_head(head)
    case BIR.DescriptorNamedPlus{key, head, args}: descriptor_head(head)
    case _: None{}

def family_key(key: String, families: List<&2, BIR.Family>) -> Maybe<&2, BIR.Family>:
  match families:
    case Nil{}: None{}
    case +family <> rest:
      match family:
        case BIR.Family{key: known, name, native, quantity_prefix, arity, arms}:
          match Bool.or(String.eq(key, known), String.eq(key, name)):
            case True{}: Some{family}
            case False{}: family_key(key, rest)

def ending_library(end: BIR.Ending) -> Bool:
  match end:
    case BIR.Library{exports}: True{}
    case BIR.Executable{main_type}: False{}

def ending_exports(end: BIR.Ending) -> List<&2, BIR.Export>:
  match end:
    case BIR.Library{exports}: exports
    case BIR.Executable{main_type}: Nil{}

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

# Descriptor parameter references are de Bruijn indices from the applied end.
def show_cells(descriptor: BIR.Descriptor, args: List<&2, BIR.Descriptor>, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, cids: List<&2, CidRow>) -> Maybe<&2, String>:
  match descriptor:
    case BIR.DescriptorParameter{index}: show_cells(descriptor_arg(args, index), Nil{}, constructors, families, cids)
    case BIR.DescriptorRef{key, fargs}: show_ref(key, fargs, constructors, families, cids)
    case BIR.DescriptorKind{quantity}: show_cells(quantity, args, constructors, families, cids)
    case BIR.DescriptorNull{}: Some{"0"}
    case _: None{}

def list_at_descriptor(args: List<&2, BIR.Descriptor>, index: Nat) -> BIR.Descriptor:
  list_at_descriptor_rest(args, index)

def list_at_descriptor_rest(args: List<&2, BIR.Descriptor>, index: Nat) -> BIR.Descriptor:
  match args:
    case Nil{}: BIR.DescriptorNull{}
    case +value <> rest:
      match index:
        case 0n: value
        case 1n+left: list_at_descriptor(rest, left)

# DescriptorParameter is indexed from the applied end, as the JS runtime does.
def descriptor_arg(args: List<&2, BIR.Descriptor>, index: Nat) -> BIR.Descriptor:
  count = List.length(&2, BIR.Descriptor, args)
  descriptor_arg_guard(Nat.is_lt(index, count), args, Nat.sub(Nat.sub(count, 1n), index))

def descriptor_arg_guard(valid: Bool, args: List<&2, BIR.Descriptor>, position: Nat) -> BIR.Descriptor:
  match valid:
    case True{}: list_at_descriptor(args, position)
    case False{}: BIR.DescriptorNull{}

def show_ref(key: String, fargs: List<&2, BIR.Descriptor>, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, cids: List<&2, CidRow>) -> Maybe<&2, String>:
  match family_key(key, families):
    case None{}: None{}
    case Some{family}: show_family(family, fargs, constructors, families, cids)

def show_family(family: BIR.Family, args: List<&2, BIR.Descriptor>, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, cids: List<&2, CidRow>) -> Maybe<&2, String>:
  match family:
    case BIR.Family{key, name, native, quantity_prefix, arity, arms}:
      match native:
        case Some{tag}: show_native(String.eq(tag, "Nat"), String.eq(tag, "U32"), String.eq(tag, "F32"), String.eq(tag, "Char"), String.eq(tag, "String"), String.eq(tag, "Eql"), String.eq(tag, "Array"), tag, family, args, constructors, families, cids)
        case None{}: show_data_family(family, args, constructors, families, cids)

def show_native(is_nat: Bool, is_u32: Bool, is_f32: Bool, is_char: Bool, is_string: Bool, is_eql: Bool, is_array: Bool, tag: String, family: BIR.Family, args: List<&2, BIR.Descriptor>, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, cids: List<&2, CidRow>) -> Maybe<&2, String>:
  match is_nat is_u32 is_f32 is_char is_string is_eql is_array:
    case True{} _ _ _ _ _ _: Some{"2"}
    case False{} True{} _ _ _ _ _: Some{"0"}
    case False{} False{} True{} _ _ _ _: Some{"1"}
    case False{} False{} False{} True{} _ _ _: Some{"3, 1"}
    case False{} False{} False{} False{} True{} _ _: Some{"4"}
    case False{} False{} False{} False{} False{} True{} _: Some{"5"}
    case False{} False{} False{} False{} False{} False{} True{}: show_array(args, constructors, families, cids)
    case _: show_data_family(family, args, constructors, families, cids)

def show_array(args: List<&2, BIR.Descriptor>, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, cids: List<&2, CidRow>) -> Maybe<&2, String>:
  match args:
    case +element <> rest:
      match show_cells(element, Nil{}, constructors, families, cids):
        case Some{cells}: Some{cat(["6, 3, 31, ", cells])}
        case None{}: None{}
    case Nil{}: None{}

def show_data_family(family: BIR.Family, args: List<&2, BIR.Descriptor>, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, cids: List<&2, CidRow>) -> Maybe<&2, String>:
  match family:
    case BIR.Family{key, name, native, quantity_prefix, arity, arms}: show_data_arms(arms, args, constructors, families, cids)

def show_data_arms(arms: List<&2, BIR.DescriptorArm>, args: List<&2, BIR.Descriptor>, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, cids: List<&2, CidRow>) -> Maybe<&2, String>:
  match arms:
    case Nil{}: None{}
    case +first <> rest: show_data_first(first, arms, args, constructors, families, cids)

def show_data_first(first: BIR.DescriptorArm, arms: List<&2, BIR.DescriptorArm>, args: List<&2, BIR.Descriptor>, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, cids: List<&2, CidRow>) -> Maybe<&2, String>:
  match bool_arms(arms):
    case True{}: show_bool(arms, cids)
    case False{}: show_data_arms_body(arms, args, constructors, families, cids)

# Bool is the runtime's one inline two-arm Data: its arms are the native
# False/True markers, and its whole show layout is the inline form.
def bool_arms(arms: List<&2, BIR.DescriptorArm>) -> Bool:
  match arms:
    case Nil{}: False{}
    case +first <> rest: bool_arms_rest(last_segment_of_arm(first), rest)

def last_segment_of_arm(arm: BIR.DescriptorArm) -> String:
  match arm:
    case BIR.DescriptorArm{key, fields}: last_segment(key)

def bool_arms_rest(first: String, rest: List<&2, BIR.DescriptorArm>) -> Bool:
  match rest:
    case Nil{}: False{}
    case +second <> tail: bool_arms_tail(String.eq(first, "False"), last_segment_of_arm(second), tail)

def bool_arms_tail(is_false: Bool, second: String, tail: List<&2, BIR.DescriptorArm>) -> Bool:
  match tail:
    case Nil{}: Bool.and(is_false, String.eq(second, "True"))
    case _: False{}

def show_bool(arms: List<&2, BIR.DescriptorArm>, cids: List<&2, CidRow>) -> Maybe<&2, String>:
  match arms:
    case Nil{}: None{}
    case +false_arm <> rest: show_bool_rest(rest, cids)

def show_bool_rest(rest: List<&2, BIR.DescriptorArm>, cids: List<&2, CidRow>) -> Maybe<&2, String>:
  match rest:
    case Nil{}: None{}
    case +true_arm <> tail: show_bool_cells(cids)

def show_bool_cells(cids: List<&2, CidRow>) -> Maybe<&2, String>:
  match cid_short("False", cids) cid_short("True", cids):
    case Some{false_cid} Some{true_cid}:
      Some{cat(["7, 1, 2, 0, ", U32.show(false_cid), ", 0, 1, ", U32.show(true_cid), ", 0"])}
    case _ _: None{}

def show_data_arms_body(arms: List<&2, BIR.DescriptorArm>, args: List<&2, BIR.Descriptor>, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, cids: List<&2, CidRow>) -> Maybe<&2, String>:
  cells = show_arm_cells(arms, args, constructors, families, cids)
  show_data_wrap(cells, arms)

def show_data_wrap(cells: Maybe<&2, List<&2, String>>, arms: List<&2, BIR.DescriptorArm>) -> Maybe<&2, String>:
  match cells:
    case None{}: None{}
    case Some{parts}: Some{cat([cat(["7, 1, ", Nat.show(List.length(&2, BIR.DescriptorArm, arms)), ", "]), String.join(parts, ", ")])}

def show_arm_cells(arms: List<&2, BIR.DescriptorArm>, args: List<&2, BIR.Descriptor>, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, cids: List<&2, CidRow>) -> Maybe<&2, List<&2, String>>:
  match arms:
    case Nil{}: Some{Nil{}}
    case +arm <> rest: show_arm_pair(show_arm_cell(arm, args, constructors, families, cids), show_arm_cells(rest, args, constructors, families, cids))

def show_arm_pair(one: Maybe<&2, String>, rest: Maybe<&2, List<&2, String>>) -> Maybe<&2, List<&2, String>>:
  match one rest:
    case Some{cell} Some{cells}: Some{cell <> cells}
    case _ _: None{}

def show_arm_cell(arm: BIR.DescriptorArm, args: List<&2, BIR.Descriptor>, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, cids: List<&2, CidRow>) -> Maybe<&2, String>:
  match arm:
    case BIR.DescriptorArm{key, fields}: show_arm_cell_fields(key, fields, args, constructors, families, cids)

def show_arm_cell_fields(key: String, fields: List<&2, BIR.DescriptorField>, args: List<&2, BIR.Descriptor>, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, cids: List<&2, CidRow>) -> Maybe<&2, String>:
  match cid_short(key, cids):
    case None{}: None{}
    case Some{cid}:
      cells = show_field_cells(fields, args, 0n, constructors, families, cids)
      show_arm_wrap(cells, ctor_index(key, constructors), cid, List.length(&2, BIR.DescriptorField, fields))

def show_arm_wrap(cells: Maybe<&2, List<&2, String>>, name_index: String, cid: U32, count: Nat) -> Maybe<&2, String>:
  match cells:
    case None{}: None{}
    case Some{parts}: Some{cat([name_index, cat([", ", U32.show(cid), ", ", Nat.show(count), cat([", ", String.join(parts, ", ")])])])}

def show_field_cells(fields: List<&2, BIR.DescriptorField>, args: List<&2, BIR.Descriptor>, offset: Nat, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, cids: List<&2, CidRow>) -> Maybe<&2, List<&2, String>>:
  match fields:
    case Nil{}: Some{Nil{}}
    case +field <> rest:
      match field:
        case BIR.DescriptorField{key, quantity, ty}: show_field_pair(show_field_cell(ty, offset, args, constructors, families, cids), show_field_cells(rest, args, Nat.add(offset, 1n), constructors, families, cids))

def show_field_cell(ty: BIR.Descriptor, offset: Nat, args: List<&2, BIR.Descriptor>, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, cids: List<&2, CidRow>) -> Maybe<&2, String>:
  match show_cells(ty, args, constructors, families, cids):
    case None{}: None{}
    case Some{cell}: Some{cat([Nat.show(offset), ", ", cell])}

def show_field_pair(one: Maybe<&2, String>, rest: Maybe<&2, List<&2, String>>) -> Maybe<&2, List<&2, String>>:
  match one rest:
    case Some{cell} Some{cells}: Some{cell <> cells}
    case _ _: None{}

# ---------------------------------------------------------------------------
# Native constructor layout
# ---------------------------------------------------------------------------

def layout_of(id: U32, constructors: List<&2, BIR.ConstructorLayout>) -> Maybe<&2, BIR.ConstructorLayout>:
  match constructors:
    case Nil{}: None{}
    case +row <> rest:
      match row:
        case BIR.ConstructorLayout{id: known, key, native, fields}: layout_one(U32.is_eq(id, known), row, id, rest)

def layout_one(found: Bool, row: BIR.ConstructorLayout, id: U32, rest: List<&2, BIR.ConstructorLayout>) -> Maybe<&2, BIR.ConstructorLayout>:
  match found:
    case True{}: Some{row}
    case False{}: layout_of(id, rest)

def key_layout(key: String, constructors: List<&2, BIR.ConstructorLayout>) -> Maybe<&2, BIR.ConstructorLayout>:
  match constructors:
    case Nil{}: None{}
    case +row <> rest:
      match row:
        case BIR.ConstructorLayout{id, key: known, native, fields}:
          match Bool.or(String.eq(key, known), String.eq(key, last_segment(known))):
            case True{}: Some{row}
            case False{}: key_layout(key, rest)

def native_kind_of(id: U32, constructors: List<&2, BIR.ConstructorLayout>) -> String:
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
def native_marker(marker: String) -> String:
  match String.eq(marker, "Nat.Zero"):
    case True{}: "natzero"
    case False{}: native_marker_1(marker)

def native_marker_1(marker: String) -> String:
  match String.eq(marker, "Nat.Succ"):
    case True{}: "natsucc"
    case False{}: native_marker_2(marker)

def native_marker_2(marker: String) -> String:
  match String.eq(marker, "U32.U32"):
    case True{}: "u32"
    case False{}: native_marker_3(marker)

def native_marker_3(marker: String) -> String:
  match String.eq(marker, "F32.F32"):
    case True{}: "f32"
    case False{}: native_marker_4(marker)

def native_marker_4(marker: String) -> String:
  match String.eq(marker, "Array.ALeaf"):
    case True{}: "aleaf"
    case False{}: native_marker_5(marker)

def native_marker_5(marker: String) -> String:
  match String.eq(marker, "Array.ANode"):
    case True{}: "anode"
    case False{}: "generic"

def packed_ctor(id: U32, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>) -> Bool:
  match layout_of(id, constructors):
    case None{}: False{}
    case Some{row}:
      match row:
        case BIR.ConstructorLayout{id, key, native, fields}: packed_arm(key, families)

def packed_arm(key: String, families: List<&2, BIR.Family>) -> Bool:
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
    case Some{key}: field_w32_key(String.eq(last_segment(key), "U32"), String.eq(last_segment(key), "F32"))

def field_w32_key(is_u32: Bool, is_f32: Bool) -> Bool:
  match is_u32:
    case True{}: True{}
    case False{}: is_f32

def live_fields(fields: List<&2, BIR.DescriptorField>, acc: List<&2, BIR.DescriptorField>) -> List<&2, BIR.DescriptorField>:
  match fields:
    case Nil{}: List.reverse(&2, BIR.DescriptorField, acc)
    case +field <> rest:
      match field:
        case BIR.DescriptorField{key, quantity, ty}: live_fields(rest, live_field_add(quantity, field, acc))

def live_field_add(quantity: BIR.Quantity, field: BIR.DescriptorField, acc: List<&2, BIR.DescriptorField>) -> List<&2, BIR.DescriptorField>:
  match quantity:
    case BIR.Erased{}: acc
    case _: field <> acc

def arm_of(key: String, families: List<&2, BIR.Family>) -> Maybe<&2, BIR.DescriptorArm>:
  match families:
    case Nil{}: None{}
    case +family <> rest:
      match family:
        case BIR.Family{key: owner, name, native, quantity_prefix, arity, arms}: arms_find(key, arms, rest)

def arms_find(key: String, arms: List<&2, BIR.DescriptorArm>, rest: List<&2, BIR.Family>) -> Maybe<&2, BIR.DescriptorArm>:
  match arms:
    case Nil{}: arm_of(key, rest)
    case +arm <> tail:
      match arm:
        case BIR.DescriptorArm{key: known, fields}:
          match Bool.or(String.eq(key, known), String.eq(last_segment(key), last_segment(known))):
            case True{}: Some{arm}
            case False{}: arms_find(key, tail, rest)

# Project.field is a source ordinal, erased slots included; the node keeps
# only live fields, so map the ordinal through the arm's quantities.
def live_index(key: String, ordinal: U32, families: List<&2, BIR.Family>) -> Nat:
  match arm_of(key, families):
    case None{}: U32.to_nat(ordinal)
    case Some{arm}:
      match arm:
        case BIR.DescriptorArm{key, fields}: live_index_fields(fields, U32.to_nat(ordinal), 0n, 0n)

def live_index_fields(fields: List<&2, BIR.DescriptorField>, ordinal: Nat, source: Nat, live: Nat) -> Nat:
  match fields:
    case Nil{}: live
    case +field <> rest:
      match field:
        case BIR.DescriptorField{key, quantity, ty}:
          match Nat.is_eq(source, ordinal):
            case True{}: live
            case False{}: live_index_fields(rest, ordinal, Nat.add(source, 1n), live_index_next(quantity, live))

def live_index_next(quantity: BIR.Quantity, live: Nat) -> Nat:
  match quantity:
    case BIR.Erased{}: live
    case _: Nat.add(live, 1n)

def ctor_cid(id: U32, constructors: List<&2, BIR.ConstructorLayout>, cids: List<&2, CidRow>) -> Part:
  match layout_of(id, constructors):
    case None{}: failp(String.append("BIR names constructor id ", String.append(U32.show(id), " with no layout")))
    case Some{row}:
      match row:
        case BIR.ConstructorLayout{id, key, native, fields}: PartOk{String.append(U32.show(cid_lookup(key, cids)), "u")}

# ---------------------------------------------------------------------------
# Atoms and operations
# ---------------------------------------------------------------------------

def atom_part(atom: BIR.Atom, plan: Plan) -> Part:
  match atom:
    case BIR.Local{id}: okp(cat(["lv", U32.show(id)]))
    case BIR.Capture{slot}: okp(cat(["x[", U32.show(slot), "]"]))
    case BIR.Symbol{_, key}: symbol_part(key, plan)
    case BIR.Word{value}: okp(u32_c(value))
    case BIR.Natural{value}: okp(nat_c(value))
    case BIR.FloatBits{bits}: okp(U32.show(bits))
    case BIR.Text{value}: okp(cat(["bend_text(e, ", c_quote(value), ", ", Nat.show(String.length(value)), ")"]))
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

def symbol_part(key: String, plan: Plan) -> Part:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, library, exports, imports, fkeys}:
      symbol_part_decl(find_declaration(key, declarations), key, plan)

def find_declaration(key: String, declarations: List<&2, BIR.Declaration>) -> Maybe<&2, BIR.Declaration>:
  match declarations:
    case Nil{}: None{}
    case +item <> rest:
      match item:
        case BIR.FunctionDeclaration{key: known, code, parameters}: find_declaration_one(String.eq(key, known), item, key, rest)
        case BIR.LazyDeclaration{key: known, body}: find_declaration_one(String.eq(key, known), item, key, rest)
        case BIR.NativeDeclaration{key: known, primitive, quantities}: find_declaration_one(String.eq(key, known), item, key, rest)
        case BIR.ForeignDeclaration{key: known, namespace, imported, arity, sources, quantities, span, parameter_types, result}: find_declaration_one(String.eq(key, known), item, key, rest)
        case _: find_declaration(key, rest)

def find_declaration_one(found: Bool, item: BIR.Declaration, key: String, rest: List<&2, BIR.Declaration>) -> Maybe<&2, BIR.Declaration>:
  match found:
    case True{}: Some{item}
    case False{}: find_declaration(key, rest)

def symbol_part_decl(found: Maybe<&2, BIR.Declaration>, key: String, plan: Plan) -> Part:
  match found:
    case None{}: failp(cat(["BIR reads symbol `", key, "` with no declaration"]))
    case Some{item}: symbol_part_item(item, key, plan)

def symbol_part_item(item: BIR.Declaration, key: String, plan: Plan) -> Part:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, library, exports, imports, fkeys}:
      symbol_emit(item, key, entries, by_code, by_key, by_foreign, by_native, stages)

def symbol_emit(item: BIR.Declaration, key: String, entries: List<&2, Entry>, by_code: Map<&2, U32>, by_key: Map<&2, U32>, by_foreign: Map<&2, U32>, by_native: Map<&2, U32>, stages: Map<&2, U32>) -> Part:
  match item:
    case BIR.FunctionDeclaration{key, code, parameters}:
      real = map_u32(by_code, U32.show(code))
      arity = entry_arity(entries, real)
      symbol_function(arity, code, real, stages)
    case BIR.LazyDeclaration{key, body}:
      PartOk{cat(["bend_run(e, ", U32.show(map_u32(by_key, key)), ", 0, 0)"])}
    case BIR.ForeignDeclaration{key, _, _, arity, _, _, _, _, _}:
      PartOk{cat(["bend_closure(e, ", U32.show(map_u32(by_foreign, key)), ", 0, 0)"])}
    case BIR.NativeDeclaration{key, primitive, quantities}:
      failp(cat(["the C target has no first-class native primitive value for `", key, "` (declare it as a def)")])
    case _: failp("BIR declaration form has no C value")

def native_value_part(key: String, by_native: Map<&2, U32>) -> Part:
  match IndexLookup.find(U32, by_native, key):
    case Some{index}: PartOk(cat(["bend_closure(e, ", U32.show(index), ", 0, 0)"]))
    case None{}: PartFail(cat(["native declaration `", key, "` has no live parameters, so it has no C value form"]))

def symbol_function(arity: Nat, code: U32, real: U32, stages: Map<&2, U32>) -> Part:
  match Nat.is_eq(arity, 0n):
    case True{}: PartOk{cat(["bend_run(e, ", U32.show(real), ", 0, 0)"])}
    case False{}:
      stage = map_u32(stages, stage_key(code, 0n))
      PartOk{cat(["bend_closure(e, ", U32.show(stage), ", 0, 0)"])}

def args_parts(args: List<&2, BIR.Arg>, plan: Plan) -> List<&2, Part>:
  match args:
    case Nil{}: Nil{}
    case +arg <> rest:
      match arg:
        case BIR.Arg{_, value}: atom_part(value, plan) <> args_parts(rest, plan)

def arg_strings(args: List<&2, BIR.Arg>, plan: Plan) -> Maybe<&2, List<&2, String>>:
  arg_strings_each(args_parts(args, plan), Nil{})

def arg_strings_each(parts: List<&2, Part>, acc: List<&2, String>) -> Maybe<&2, List<&2, String>>:
  match parts:
    case Nil{}: Some{List.reverse(&2, String, acc)}
    case +part <> rest:
      match part:
        case PartFail{message}: None{}
        case PartOk{text}: arg_strings_each(rest, text <> acc)

def call_args(values: List<&2, String>) -> String:
  match values:
    case Nil{}: "0"
    case _: cat(["(Term[]){", String.join(values, ", "), "}"])

def op_part(op: BIR.Op, plan: Plan) -> Part:
  match op:
    case BIR.Copy{value}: atom_part(value, plan)
    case BIR.PrimitiveCall{primitive, args}: prim_call_part(primitive, args, plan)
    case BIR.Closure{code, captures, parameters}: closure_part(code, captures, parameters, plan)
    case BIR.Direct{code, args}: direct_part(code, args, plan)
    case BIR.Apply{fn, arg}: apply_part(fn, arg, plan)
    case BIR.LoadSymbol{_, key}: symbol_part(key, plan)
    case BIR.Construct{constructor, tag, fields}: construct_part(constructor, fields, plan)
    case BIR.Project{value, constructor, field, key}: project_part(value, constructor, field, plan)
    case BIR.HasTag{value, constructor, tag}: hastag_part(value, constructor, plan)
    case _: failp("BIR operation form has no C rendering")

def direct_part(code: U32, args: List<&2, BIR.Arg>, plan: Plan) -> Part:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, library, exports, imports, fkeys}:
      direct_values(map_u32(by_code, U32.show(code)), arg_strings(args, plan))

def direct_values(real: U32, values: Maybe<&2, List<&2, String>>) -> Part:
  match values:
    case None{}: failp("BIR argument has no C value")
    case Some{args}: PartOk{cat(["bend_run(e, ", U32.show(real), ", ", call_args(args), ", ", Nat.show(List.length(&2, String, args)), ")"])}

def closure_part(code: U32, captures: List<&2, BIR.Arg>, parameters: List<&2, BIR.Parameter>, plan: Plan) -> Part:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, library, exports, imports, fkeys}:
      closure_values(code, List.length(&2, BIR.Arg, captures), parameters, map_u32(by_code, U32.show(code)), stages, arg_strings(captures, plan))

def closure_values(code: U32, count: Nat, parameters: List<&2, BIR.Parameter>, real: U32, stages: Map<&2, U32>, values: Maybe<&2, List<&2, String>>) -> Part:
  match values:
    case None{}: failp("BIR capture has no C value")
    case Some{captures}:
      match List.length(&2, BIR.Parameter, parameters):
        case 0n: PartOk{cat(["bend_run(e, ", U32.show(real), ", ", call_args(captures), ", ", Nat.show(count), ")"])}
        case _:
          stage = map_u32(stages, stage_key(code, count))
          PartOk{cat(["bend_closure(e, ", U32.show(stage), ", ", Nat.show(count), ", ", call_args(captures), ")"])}

def apply_part(fn: BIR.Atom, arg: BIR.Arg, plan: Plan) -> Part:
  fn_value = atom_part(fn, plan)
  match arg:
    case BIR.Arg{_, value}: apply_values(fn_value, atom_part(value, plan))

def apply_values(fn_value: Part, arg_value: Part) -> Part:
  match fn_value arg_value:
    case PartOk{fn_text} PartOk{arg_text}: PartOk{cat(["bend_apply(e, ", fn_text, ", ", arg_text, ")"])}
    case PartFail{message} _: PartFail{message}
    case _ PartFail{message}: PartFail{message}

def field_values(fields: List<&2, BIR.Field>, plan: Plan) -> List<&2, Part>:
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
        case BIR.Family{key: owner, name, native, quantity_prefix, arity, arms}: family_arms_check(arm_member(key, arms), arms, rest)

def arm_member(key: String, arms: List<&2, BIR.DescriptorArm>) -> Bool:
  match arms:
    case Nil{}: False{}
    case +arm <> rest:
      match arm:
        case BIR.DescriptorArm{key: known, fields}: arm_member_one(Bool.or(String.eq(key, known), String.eq(last_segment(key), last_segment(known))), key, rest)

def arm_member_one(found: Bool, key: String, rest: List<&2, BIR.DescriptorArm>) -> Bool:
  match found:
    case True{}: True{}
    case False{}: arm_member(key, rest)

def family_arms_check(found: Bool, arms: List<&2, BIR.DescriptorArm>, rest: List<&2, BIR.Family>) -> Maybe<&2, List<&2, BIR.DescriptorArm>>:
  match found:
    case True{}: Some(arms)
    case False{}: family_arms_rest(rest)

def family_arms_rest(rest: List<&2, BIR.Family>) -> Maybe<&2, List<&2, BIR.DescriptorArm>>:
  match rest:
    case Nil{}: None{}
    case +family <> tail:
      match family:
        case BIR.Family{key, name, native, quantity_prefix, arity, arms}: Some(arms)

def arm_index(key: String, arms: List<&2, BIR.DescriptorArm>, index: Nat) -> Maybe<&2, Nat>:
  match arms:
    case Nil{}: None{}
    case +arm <> rest:
      match arm:
        case BIR.DescriptorArm{key: known, fields}: arm_index_one(Bool.or(String.eq(key, known), String.eq(last_segment(key), last_segment(known))), key, rest, index)

def arm_index_one(found: Bool, key: String, rest: List<&2, BIR.DescriptorArm>, index: Nat) -> Maybe<&2, Nat>:
  match found:
    case True{}: Some(index)
    case False{}: arm_index(key, rest, Nat.add(index, 1n))

# An inline enum is a family with more than one arm, all of them nullary; its
# values are the raw arm index, exactly as the current C emitter lays them out.
def inline_tag_arms(key: String, arms: List<&2, BIR.DescriptorArm>) -> Maybe<&2, Nat>:
  match Bool.and(all_arms_nullary(arms), Nat.is_gt(List.length(&2, BIR.DescriptorArm, arms), 1n)):
    case True{}: arm_index(key, arms, 0n)
    case False{}: None{}

def construct_part(constructor: U32, fields: List<&2, BIR.Field>, plan: Plan) -> Part:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, library, exports, imports, fkeys}:
      construct_values(constructor, native_kind_of(constructor, constructors), field_values(fields, plan), ctor_cid(constructor, constructors, cids), List.length(&2, BIR.Field, fields), packed_ctor(constructor, constructors, families))

def construct_values(constructor: U32, kind: String, values: List<&2, Part>, cid_part: Part, count: Nat, packed: Bool) -> Part:
  match values_part(values, Nil{}):
    case None{}: failp("BIR constructor field has no C value")
    case Some{args}: construct_kind(kind, args, cid_part, count, packed)

def values_part(values: List<&2, Part>, acc: List<&2, String>) -> Maybe<&2, List<&2, String>>:
  match values:
    case Nil{}: Some{List.reverse(&2, String, acc)}
    case +part <> rest:
      match part:
        case PartFail{message}: None{}
        case PartOk{text}: values_part(rest, text <> acc)

def construct_kind(kind: String, args: List<&2, String>, cid_part: Part, count: Nat, packed: Bool) -> Part:
  match base_construct(kind, args):
    case Some{text}: PartOk{text}
    case None{}:
      match cid_part:
        case PartFail{message}: PartFail{message}
        case PartOk{cid}: construct_generic(args, cid, count, packed)

def construct_generic(args: List<&2, String>, cid: String, count: Nat, packed: Bool) -> Part:
  match Nat.is_eq(count, 0n):
    case True{}: PartOk{cat(["term_pak(", cid, ", 0)"])}
    case False{}: construct_generic_n(args, cid, count, packed)

def construct_generic_n(args: List<&2, String>, cid: String, count: Nat, packed: Bool) -> Part:
  match Bool.and(packed, Nat.is_eq(count, 1n)):
    case True{}: PartOk{cat(["term_pak(", cid, ", (u64)(", list_at(args, 0n), "))"])}
    case False{}: PartOk{cat(["bend_node(e, ", cid, ", ", Nat.show(count), ", ", call_args(args), ")"])}

def base_construct(kind: String, args: List<&2, String>) -> Maybe<&2, String>:
  match String.eq(kind, "natzero"):
    case True{}: Some{"0"}
    case False{}: base_construct_1(kind, args)

def base_construct_1(kind: String, args: List<&2, String>) -> Maybe<&2, String>:
  match String.eq(kind, "natsucc"):
    case True{}: Some{cat(["nat_chk(e, ", list_at(args, 0n), " + 1)"])}
    case False{}: base_construct_2(kind, args)

def base_construct_2(kind: String, args: List<&2, String>) -> Maybe<&2, String>:
  match String.eq(kind, "u32"):
    case True{}: Some{cat(["term_word(e, ", list_at(args, 0n), ")"])}
    case False{}: base_construct_3(kind, args)

def base_construct_3(kind: String, args: List<&2, String>) -> Maybe<&2, String>:
  match String.eq(kind, "f32"):
    case True{}: Some{cat(["term_word(e, ", list_at(args, 0n), ")"])}
    case False{}: base_construct_4(kind, args)

def base_construct_4(kind: String, args: List<&2, String>) -> Maybe<&2, String>:
  match String.eq(kind, "aleaf"):
    case True{}: Some{cat(["bend_array_leaf(e, ", list_at(args, 0n), ")"])}
    case False{}: base_construct_5(kind, args)

def base_construct_5(kind: String, args: List<&2, String>) -> Maybe<&2, String>:
  match String.eq(kind, "anode"):
    case True{}: Some{cat(["blk_node(e, ", list_at(args, 0n), ", ", list_at(args, 1n), ")"])}
    case False{}: None{}

def project_part(value: BIR.Atom, constructor: U32, field: U32, plan: Plan) -> Part:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, library, exports, imports, fkeys}:
      project_values(atom_part(value, plan), native_kind_of(constructor, constructors), ctor_key_of(constructor, constructors), field, families)

def ctor_key_of(id: U32, constructors: List<&2, BIR.ConstructorLayout>) -> String:
  match layout_of(id, constructors):
    case Some{row}:
      match row:
        case BIR.ConstructorLayout{id, key, native, fields}: key
    case None{}: ""

def project_values(value: Part, kind: String, key: String, field: U32, families: List<&2, BIR.Family>) -> Part:
  match value:
    case PartFail{message}: PartFail{message}
    case PartOk{text}: PartOk{project_expr(kind, text, key, field, families)}

def project_expr(kind: String, value: String, key: String, field: U32, families: List<&2, BIR.Family>) -> String:
  match String.eq(kind, "natsucc"):
    case True{}: cat(["bend_nat_pred(", value, ")"])
    case False{}: project_expr_1(kind, value, key, field, families)

def project_expr_1(kind: String, value: String, key: String, field: U32, families: List<&2, BIR.Family>) -> String:
  match String.eq(kind, "u32"):
    case True{}: cat(["term_word(e, ", value, ")"])
    case False{}: project_expr_2(kind, value, key, field, families)

def project_expr_2(kind: String, value: String, key: String, field: U32, families: List<&2, BIR.Family>) -> String:
  match String.eq(kind, "f32"):
    case True{}: value
    case False{}: project_expr_3(kind, value, key, field, families)

def project_expr_3(kind: String, value: String, key: String, field: U32, families: List<&2, BIR.Family>) -> String:
  match String.eq(kind, "aleaf"):
    case True{}: cat(["bend_array_leaf_value(e, ", value, ")"])
    case False{}: project_expr_4(kind, value, key, field, families)

def project_expr_4(kind: String, value: String, key: String, field: U32, families: List<&2, BIR.Family>) -> String:
  match String.eq(kind, "anode"):
    case True{}: project_anode(value, field)
    case False{}: cat(["bend_project(e, ", value, ", ", Nat.show(live_index(key, field, families)), ")"])

def project_anode(value: String, field: U32) -> String:
  match U32.is_eq(field, 0u):
    case True{}: cat(["blk_half(e, ", value, ", 0)"])
    case False{}: cat(["blk_half(e, ", value, ", 1)"])

def hastag_part(value: BIR.Atom, constructor: U32, plan: Plan) -> Part:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, library, exports, imports, fkeys}:
      hastag_values(atom_part(value, plan), native_kind_of(constructor, constructors), ctor_cid(constructor, constructors, cids))

def hastag_values(value: Part, kind: String, cid_part: Part) -> Part:
  match value:
    case PartFail{message}: PartFail{message}
    case PartOk{text}: hastag_expr(kind, text, cid_part)

def hastag_expr(kind: String, value: String, cid_part: Part) -> Part:
  match String.eq(kind, "natzero"):
    case True{}: okp(cat(["(", value, " == 0)"]))
    case False{}: hastag_expr_1(kind, value, cid_part)

def hastag_expr_1(kind: String, value: String, cid_part: Part) -> Part:
  match String.eq(kind, "natsucc"):
    case True{}: okp(cat(["(", value, " > 0)"]))
    case False{}: hastag_expr_2(kind, value, cid_part)

def hastag_expr_2(kind: String, value: String, cid_part: Part) -> Part:
  match String.eq(kind, "u32"):
    case True{}: okp("1")
    case False{}: hastag_expr_3(kind, value, cid_part)

def hastag_expr_3(kind: String, value: String, cid_part: Part) -> Part:
  match String.eq(kind, "f32"):
    case True{}: okp("1")
    case False{}: hastag_expr_4(kind, value, cid_part)

def hastag_expr_4(kind: String, value: String, cid_part: Part) -> Part:
  match String.eq(kind, "aleaf"):
    case True{}: okp(cat(["((u32)blk_cls(", value, ") == 0)"]))
    case False{}: hastag_expr_5(kind, value, cid_part)

def hastag_expr_5(kind: String, value: String, cid_part: Part) -> Part:
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

def prim_call_part(primitive: BIR.Primitive, args: List<&2, BIR.Arg>, plan: Plan) -> Part:
  match arg_strings(args, plan):
    case None{}: failp("BIR argument has no C value")
    case Some{values}: prim_part(primitive, values, plan)

def pcid(short: String, plan: Plan) -> Part:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, library, exports, imports, fkeys}:
      cid_c(short, cids)

def prim_part(primitive: BIR.Primitive, a: List<&2, String>, plan: Plan) -> Part:
  a0 = list_at(a, 0n)
  a1 = list_at(a, 1n)
  a2 = list_at(a, 2n)
  match primitive:
    case BIR.PrimU32Add{}: okp(cat(["U32_BIN(", a0, ", +, ", a1, ")"]))
    case BIR.PrimU32Sub{}: okp(cat(["U32_BIN(", a0, ", -, ", a1, ")"]))
    case BIR.PrimU32Mul{}: okp(cat(["U32_BIN(", a0, ", *, ", a1, ")"]))
    case BIR.PrimU32Div{}: okp(cat(["((u32)(", a1, ") == 0 ? 0 : (u64)U32_QUO((u32)(", a0, "), (u32)(", a1, ")))"]))
    case BIR.PrimU32Mod{}: okp(cat(["((u32)(", a1, ") == 0 ? ", a0, " : U32_BIN(", a0, ", -, U32_QUO((u32)(", a0, "), (u32)(", a1, ")) * ", a1, "))"]))
    case BIR.PrimU32And{}: okp(cat(["U32_BIN(", a0, ", &, ", a1, ")"]))
    case BIR.PrimU32Or{}: okp(cat(["U32_BIN(", a0, ", |, ", a1, ")"]))
    case BIR.PrimU32Xor{}: okp(cat(["U32_BIN(", a0, ", ^, ", a1, ")"]))
    case BIR.PrimU32IsEq{}: okp(cat(["U32_BIN(", a0, ", ==, ", a1, ")"])), plan
    case BIR.PrimU32IsNe{}: okp(cat(["U32_BIN(", a0, ", !=, ", a1, ")"])), plan
    case BIR.PrimU32IsLt{}: okp(cat(["U32_BIN(", a0, ", <, ", a1, ")"])), plan
    case BIR.PrimU32IsLe{}: okp(cat(["U32_BIN(", a0, ", <=, ", a1, ")"])), plan
    case BIR.PrimU32IsGt{}: okp(cat(["U32_BIN(", a0, ", >, ", a1, ")"])), plan
    case BIR.PrimU32IsGe{}: okp(cat(["U32_BIN(", a0, ", >=, ", a1, ")"])), plan
    case BIR.PrimU32IsZero{}: okp(cat(["U32_BIN(", a0, ", ==, 0)"])), plan
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
    case BIR.PrimNatIsLt{}: okp(cat(["(", a0, " < ", a1, ")"])), plan
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
    case BIR.PrimF32IsEq{}: f32_cmp("==", a0, a1), plan
    case BIR.PrimF32IsNe{}: f32_cmp("!=", a0, a1), plan
    case BIR.PrimF32IsLt{}: f32_cmp("<", a0, a1), plan
    case BIR.PrimF32IsLe{}: f32_cmp("<=", a0, a1), plan
    case BIR.PrimF32IsGt{}: f32_cmp(">", a0, a1), plan
    case BIR.PrimF32IsGe{}: f32_cmp(">=", a0, a1), plan
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
    case BIR.PrimIsArrayLeaf{}: okp(cat(["((u32)blk_cls(", a0, ") == 0)"])), plan
    case BIR.PrimIsArrayNode{}: okp(cat(["((u32)blk_cls(", a0, ") != 0)"])), plan
    case BIR.PrimIsNatZero{}: okp(cat(["(", a0, " == 0)"])), plan
    case BIR.PrimIsNatSuccessor{}: okp(cat(["(", a0, " > 0)"])), plan
    case BIR.PrimIsStringEmpty{}: str_empty("bend_str_empty", "SNil", a0, plan), plan
    case BIR.PrimIsStringNonempty{}: str_empty_neg(a0, plan), plan
    case BIR.PrimIsTrue{}: is_bool_part("True", a0, plan)
    case BIR.PrimIsFalse{}: is_bool_part("False", a0, plan)
    case BIR.PrimSameValue{}: okp(cat(["(", a0, " == ", a1, ")"])), plan
    case BIR.PrimFloatBitsEqual{}: okp(cat(["(", a0, " == ", a1, ")"])), plan
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
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, library, exports, imports, fkeys}:
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

def cmp3_part(a0: String, a1: String, plan: Plan) -> Part:
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

def str_tail(a0: String, plan: Plan) -> Part:
  match pcid("SCon", plan) pcid("SNil", plan):
    case PartOk{scon} PartOk{snil}: PartOk{cat(["bend_str_tail(e, ", scon, ", ", snil, ", ", a0, ")"])}
    case PartFail{message} _: PartFail{message}
    case _ PartFail{message}: PartFail{message}

def str_to_list(a0: String, plan: Plan) -> Part:
  match pcid("SCon", plan) pcid("SNil", plan) pcid("Con", plan) pcid("Nil", plan):
    case PartOk{scon} PartOk{snil} PartOk{con} PartOk{nil}:
      PartOk{cat(["bend_str_to_list(e, ", scon, ", ", snil, ", ", con, ", ", nil, ", ", a0, ")"])}
    case PartFail{message} _ _ _: PartFail{message}
    case _ PartFail{message} _ _: PartFail{message}
    case _ _ PartFail{message} _: PartFail{message}
    case _ _ _ PartFail{message}: PartFail{message}

def str_cmp(a0: String, a1: String, plan: Plan) -> Part:
  match pcid("SCon", plan) pcid("Tuple", plan) pcid("LT", plan) pcid("EQ", plan) pcid("GT", plan):
    case PartOk{scon} PartOk{tuple} PartOk{lt} PartOk{eq} PartOk{gt}:
      PartOk{cat(["bend_str_cmp(e, ", scon, ", ", tuple, ", ", lt, ", ", eq, ", ", gt, ", ", a0, ", ", a1, ")"])}
    case PartFail{message} _ _ _ _: PartFail{message}
    case _ PartFail{message} _ _ _: PartFail{message}
    case _ _ PartFail{message} _ _: PartFail{message}
    case _ _ _ PartFail{message} _: PartFail{message}
    case _ _ _ _ PartFail{message}: PartFail{message}

def map_bit_part(a0: String, a1: String, plan: Plan) -> Part:
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

def word_part(a0: String, plan: Plan) -> Part:
  match pcid("WCon", plan) pcid("WNil", plan):
    case PartOk{con} PartOk{nil}: PartOk{cat(["bend_u32_to_word(e, ", con, ", ", nil, ", ", a0, ")"])}
    case PartFail{message} _: PartFail{message}
    case _ PartFail{message}: PartFail{message}

# ---------------------------------------------------------------------------
# Blocks
# ---------------------------------------------------------------------------

def block_locals(block: BIR.Block, acc: List<&2, String>) -> List<&2, String>:
  match block:
    case BIR.Return{value}: acc
    case BIR.Let{id, op, next}: block_locals(next, local_add(acc, id))
    case BIR.Branch{condition, yes, no}: block_locals(no, block_locals(yes, acc))
    case BIR.Region{label, body, next}: block_locals(next, block_locals(body, acc))
    case BIR.LeaveRegion{label}: acc
    case BIR.TailDirect{code, args}: acc
    case BIR.TailApply{fn, arg}: acc
    case BIR.Failure{message}: acc
    case _: acc

def local_add(acc: List<&2, String>, id: U32) -> List<&2, String>:
  match member(acc, U32.show(id)):
    case True{}: acc
    case False{}: U32.show(id) <> acc

def locals_decl(ids: List<&2, String>) -> String:
  match ids:
    case Nil{}: ""
    case +id <> rest: cat(["  Term lv", id, " = 0;\n", locals_decl(rest)])

def params_bind(params: List<&2, BIR.Parameter>, captures: Nat, index: Nat) -> String:
  match params:
    case Nil{}: ""
    case +param <> rest:
      match param:
        case BIR.Parameter{id, use}:
          cat(["  Term lv", U32.show(id), " = x[", Nat.show(Nat.add(captures, index)), "];\n", params_bind(rest, captures, Nat.add(index, 1n))])

def block_part(block: BIR.Block, plan: Plan) -> Part:
  match block:
    case BIR.Return{value}: block_return(value, plan)
    case BIR.Let{id, op, next}: block_let(id, op, next, plan)
    case BIR.Branch{condition, yes, no}: block_branch(condition, yes, no, plan)
    case BIR.Region{label, body, next}: block_region(label, body, next, plan)
    case BIR.LeaveRegion{label}: okp(cat(["  goto bend_r", U32.show(label), ";\n"]))
    case BIR.TailDirect{code, args}: block_tail_direct(code, args, plan)
    case BIR.TailApply{fn, arg}: block_tail_apply(fn, arg, plan)
    case BIR.Failure{message}: okp(cat(["  return bend_fail(e, ", c_quote(message), ");\n"]))
    case _: failp("BIR block form has no C rendering")

def block_return(value: BIR.Atom, plan: Plan) -> Part:
  match atom_part(value, plan):
    case PartFail{message}: PartFail{message}
    case PartOk{text}: PartOk{cat(["  return ", text, ";\n"])}

def block_let(id: U32, op: BIR.Op, next: BIR.Block, plan: Plan) -> Part:
  match op_part(op, plan) :
    case PartFail{message}: PartFail{message}
    case PartOk{text}: block_let_text(id, text, next, plan)

def block_let_text(id: U32, text: String, next: BIR.Block, plan: Plan) -> Part:
  match block_part(next, plan):
    case PartFail{message}: PartFail{message}
    case PartOk{after}: PartOk{cat(["  Term lv", U32.show(id), " = ", text, ";\n", after])}

def block_branch(condition: BIR.Atom, yes: BIR.Block, no: BIR.Block, plan: Plan) -> Part:
  cond = cond_part_of(atom_part(condition, plan), plan)
  match cond block_part(yes, plan) block_part(no, plan):
    case PartOk{cond_text} PartOk{yes_text} PartOk{no_text}:
      PartOk{cat(["  if (", cond_text, ") {\n", yes_text, "  } else {\n", no_text, "  }\n"])}
    case PartFail{message} _ _: PartFail{message}
    case _ PartFail{message} _: PartFail{message}
    case _ _ PartFail{message}: PartFail{message}

def cond_part_of(part: Part, plan: Plan) -> Part:
  match part:
    case PartFail{message}: PartFail{message}
    case PartOk{text}: cond_part(text, pcid("True", plan))

def cond_part(cond: String, true_cid: Part) -> Part:
  match true_cid:
    case PartFail{message}: PartFail{message}
    case PartOk{cid}: okp(cat(["term_aux(", cond, ") == (u64)", cid]))

# ---------------------------------------------------------------------------
# Blocks
# ---------------------------------------------------------------------------

def block_region(label: U32, body: BIR.Block, next: BIR.Block, plan: Plan) -> Part:
  match block_part(body, plan) block_part(next, plan):
    case PartOk{body_text} PartOk{next_text}:
      PartOk{cat(["  {\n", body_text, "  }\n  bend_r", U32.show(label), ": ;\n", next_text])}
    case PartFail{message} _: PartFail{message}
    case _ PartFail{message}: PartFail{message}

def block_tail_direct(code: U32, args: List<&2, BIR.Arg>, plan: Plan) -> Part:
  match direct_part(code, args, plan):
    case PartFail{message}: PartFail{message}
    case PartOk{_}: block_tail_direct_values(code, arg_strings(args, plan), plan)

def block_tail_direct_values(code: U32, values: Maybe<&2, List<&2, String>>, plan: Plan) -> Part:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, library, exports, imports, fkeys}:
      tail_direct_values(map_u32(by_code, U32.show(code)), values)

def tail_direct_values(real: U32, values: Maybe<&2, List<&2, String>>) -> Part:
  match values:
    case None{}: failp("BIR argument has no C value")
    case Some{args}: PartOk{tail_direct_text(real, args)}

def tail_direct_text(real: U32, args: List<&2, String>) -> String:
  match args:
    case Nil{}: cat(["  *tc = ", U32.show(real), "; *tn = 0; return 0;\n"])
    case _:
      cat(["  { Term ta[", Nat.show(List.length(&2, String, args)), "]; ", tail_stores(args, 0n), "for (u32 i = 0; i < ", Nat.show(List.length(&2, String, args)), "; i += 1) { tb[i] = ta[i]; } *tc = ", U32.show(real), "; *tn = ", Nat.show(List.length(&2, String, args)), "; return 0; }\n"])

def tail_stores(args: List<&2, String>, index: Nat) -> String:
  match args:
    case Nil{}: ""
    case +arg <> rest: cat(["ta[", Nat.show(index), "] = ", arg, "; ", tail_stores(rest, Nat.add(index, 1n))])

def block_tail_apply(fn: BIR.Atom, arg: BIR.Arg, plan: Plan) -> Part:
  fn_value = atom_part(fn, plan)
  match arg:
    case BIR.Arg{_, value}: block_tail_apply_values(fn_value, atom_part(value, plan))

def block_tail_apply_values(fn_value: Part, arg_value: Part) -> Part:
  match fn_value arg_value:
    case PartOk{fn_text} PartOk{arg_text}:
      PartOk{cat(["  return bend_tail_apply(e, ", fn_text, ", ", arg_text, ", tc, tn, tb);\n"])}
    case PartFail{message} _: PartFail{message}
    case _ PartFail{message}: PartFail{message}

# ---------------------------------------------------------------------------
# Entry bodies and segments
# ---------------------------------------------------------------------------

def entry_body(entry: Entry, plan: Plan) -> Part:
  match entry:
    case Entry{index, arity, kind}: entry_body_kind(index, arity, kind, plan)

def entry_body_kind(index: U32, arity: Nat, kind: Kind, plan: Plan) -> Part:
  match kind:
    case KindCode{id, captures, params, body}: entry_body_code(index, captures, params, body, plan)
    case KindLazy{body}: entry_body_block(index, Nil{}, body, plan)
    case KindStage{id, count}: entry_body_stage(index, count)
    case KindForeign{key, args}: entry_body_foreign(index, key, args, plan)
    case KindNative{primitive, count}: entry_body_native(index, primitive, count, plan)
    case KindMain{}: entry_body_main(index, plan)
    case KindLibrary{}: entry_body_library(index, plan)
    case _: okp("")

def entry_header(index: U32) -> String:
  cat(["static Term bend_e", U32.show(index), "(Env e, Term* x, u32 n, u32* tc, u32* tn, Term* tb) {\n  (void)n;\n"])

def entry_body_code(index: U32, captures: Nat, params: List<&2, BIR.Parameter>, body: BIR.Block, plan: Plan) -> Part:
  entry_body_block_params(index, captures, params, body, plan)

def entry_body_block(index: U32, params: List<&2, BIR.Parameter>, body: BIR.Block, plan: Plan) -> Part:
  entry_body_block_params(index, 0n, params, body, plan)

def entry_body_block_params(index: U32, captures: Nat, params: List<&2, BIR.Parameter>, body: BIR.Block, plan: Plan) -> Part:
  match block_part(body, plan):
    case PartFail{message}: PartFail{message}
    case PartOk{text}:
      PartOk{cat([entry_header(index), "  (void)tc;\n  (void)tn;\n  (void)tb;\n", locals_decl(block_locals(body, Nil{})), params_bind(params, captures, 0n), text, "  *tc = BEND_NOT_TAIL; return 0;\n}\n\n"])}

def entry_body_native(index: U32, primitive: BIR.Primitive, count: Nat, plan: Plan) -> Part:
  match prim_part(primitive, arg_names(count, 0n), plan):
    case PartFail{message}: PartFail{message}
    case PartOk{text}:
      PartOk{cat([entry_header(index), "  (void)x;\n  (void)tc;\n  (void)tn;\n  (void)tb;\n  return ", text, ";\n}\n\n"])}

def entry_body_stage(index: U32, count: Nat) -> Part:
  okp(cat([entry_header(index), "  (void)tc;\n  (void)tn;\n  (void)tb;\n  Term v[BEND_MAX_ARITY];\n  for (u32 j = 0; j < ", Nat.show(count), "; j += 1) { v[j] = x[j]; }\n  return bend_closure(e, ", U32.show(U32.inc(index)), ", ", Nat.show(count), ", v);\n}\n\n"]))

def entry_body_foreign(index: U32, key: String, args: Nat, plan: Plan) -> Part:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, library, exports, imports, fkeys}:
      foreign_types_part(index, key, args, find_declaration(key, declarations), families, cids)

def foreign_types_part(index: U32, key: String, args: Nat, found: Maybe<&2, BIR.Declaration>, families: List<&2, BIR.Family>, cids: List<&2, CidRow>) -> Part:
  match found:
    case Some{decl}: foreign_types_decl(index, key, args, decl, families, cids)
    case None{}: PartFail(cat(["foreign `", key, "` has no declaration"]))

def foreign_types_decl(index: U32, key: String, args: Nat, decl: BIR.Declaration, families: List<&2, BIR.Family>, cids: List<&2, CidRow>) -> Part:
  match decl:
    case BIR.ForeignDeclaration{_, _, _, _, _, _, _, parameter_types, result}: foreign_types_checked(index, key, args, parameter_types, result, families, cids)
    case _: PartFail(cat(["foreign `", key, "` is not a ForeignDeclaration"]))

def foreign_types_checked(index: U32, key: String, args: Nat, types: List<&2, BIR.Descriptor>, result: BIR.Descriptor, families: List<&2, BIR.Family>, cids: List<&2, CidRow>) -> Part:
  foreign_body_boxed(index, key, args, types, families, cids)

def foreign_body_boxed(index: U32, key: String, args: Nat, types: List<&2, BIR.Descriptor>, families: List<&2, BIR.Family>, cids: List<&2, CidRow>) -> Part:
  arity = Nat.add(args, 1n)
  boxed = arg_names(arity, 0n)
  PartOk(cat([entry_header(index), "  (void)x;\n  (void)tc;\n  (void)tn;\n  (void)tb;\n  Term v[BEND_MAX_ARITY];\n  ", box_stores(boxed, 0n), "  return bend_node(e, ", U32.show(cid_lookup(key, cids)), ", ", Nat.show(arity), ", v);\n}\n\n"]))

def box_stores(args: List<&2, String>, index: Nat) -> String:
  match args:
    case Nil{}: ""
    case +arg <> rest: cat(["v[", Nat.show(index), "] = ", arg, "; ", box_stores(rest, Nat.add(index, 1n))])

def entry_body_main(index: U32, plan: Plan) -> Part:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, library, exports, imports, fkeys}:
      main_body(index, find_declaration("main", declarations), by_code, by_key, entries)

def main_body(index: U32, found: Maybe<&2, BIR.Declaration>, by_code: Map<&2, U32>, by_key: Map<&2, U32>, entries: List<&2, Entry>) -> Part:
  match found:
    case None{}: failp("no root main definition")
    case Some{item}: main_body_item(index, item, by_code, by_key, entries)

def main_body_item(index: U32, item: BIR.Declaration, by_code: Map<&2, U32>, by_key: Map<&2, U32>, entries: List<&2, Entry>) -> Part:
  match item:
    case BIR.FunctionDeclaration{key, code, parameters}:
      match List.length(&2, BIR.Parameter, parameters):
        case 0n: PartOk{cat([entry_header(index), "  (void)tc;\n  (void)tn;\n  (void)tb;\n  return bend_run(e, ", U32.show(map_u32(by_code, U32.show(code))), ", 0, 0);\n}\n\n"])}
        case _: failp("the C target's main must take no parameters")
    case BIR.LazyDeclaration{key, body}:
      PartOk{cat([entry_header(index), "  (void)tc;\n  (void)tn;\n  (void)tb;\n  return bend_run(e, ", U32.show(map_u32(by_key, key)), ", 0, 0);\n}\n\n"])}
    case BIR.NativeDeclaration{key, primitive, quantities}: failp("a native declaration cannot be a program main")
    case BIR.ForeignDeclaration{key, _, _, arity, _, _, _, _, _}: failp("a foreign declaration cannot be a program main")
    case _: failp("BIR declaration form cannot be a program main")

def entry_body_library(index: U32, plan: Plan) -> Part:
  match pcid("Exit", plan):
    case PartOk{exit_cid}:
      PartOk(cat([entry_header(index), "  (void)x;\n  (void)tc;\n  (void)tn;\n  (void)tb;\n  Term v[1];\n  v[0] = 0;\n  return bend_node(e, ", exit_cid, ", 1, v);\n}\n\n"]))
    case PartFail{message}:
      failp(cat(["the C target needs the IO.OP Exit constructor for a library artifact: ", message]))

def entry_bodies(entries: List<&2, Entry>, plan: Plan) -> Part:
  match entries:
    case Nil{}: okp("")
    case +entry <> rest: part_append(entry_body(entry, plan), entry_bodies(rest, plan))

def reserved_entry(kind: Kind) -> Bool:
  match kind:
    case KindEmit{}: True{}
    case KindApply{}: True{}
    case KindExit{}: True{}
    case KindEnter{}: True{}
    case _: False{}

def entry_segment(entry: Entry) -> Part:
  match entry:
    case Entry{index, arity, kind}: segment_body(index, arity, kind)

# ---------------------------------------------------------------------------
# Tables
# ---------------------------------------------------------------------------

def cid_define(row: CidRow) -> String:
  match row:
    case CidRow{cid, key, arity}: cat(["#define ", cid_symbol(cid), " ", U32.show(cid), "\n"])

def cid_defines(cids: List<&2, CidRow>) -> String:
  match cids:
    case Nil{}: ""
    case +row <> rest: cat([cid_define(row), cid_defines(rest)])

def cid_table(cids: List<&2, CidRow>) -> String:
  match cids:
    case Nil{}: " };\n"
    case +row <> rest:
      match row:
        case CidRow{cid, key, arity}: cat(["{ ", Nat.show(arity), ", 0 }, ", cid_table(rest)])

def fid_define(entry: Entry) -> String:
  match entry:
    case Entry{index, arity, kind}: cat(["#define FID_", U32.show(index), " ", U32.show(index), "\n"])

def fid_table(entries: List<&2, Entry>) -> String:
  match entries:
    case Nil{}: " };\n"
    case +entry <> rest:
      match entry:
        case Entry{index, arity, kind}: cat(["{ ", Nat.show(arity), ", 0, 2 }, ", fid_table(rest)])

def registers(count: Nat) -> List<&2, String>:
  registers_each(count, 0n)

def registers_each(count: Nat, index: Nat) -> List<&2, String>:
  match Nat.is_lt(index, count):
    case True{}: registers_name(index, Nat.is_eq(index, 6n)) <> registers_each(count, Nat.add(index, 1n))
    case False{}: Nil{}

def registers_name(index: Nat, has_rp: Bool) -> List<&2, String>:
  match has_rp:
    case True{}: ["rp"]
    case False{}: [cat(["r", Nat.show(index)])]

def register_list(names: List<&2, String>, prefix: String) -> String:
  match names:
    case Nil{}: ""
    case +name <> rest: cat([prefix, name, register_tail(rest, prefix)])

def register_tail(rest: List<&2, String>, prefix: String) -> String:
  match rest:
    case Nil{}: ""
    case _: cat([", ", register_list(rest, prefix)])

def register_decls(count: Nat) -> String:
  cat([register_list(registers(count), "Term "), ";"])

def register_names(count: Nat) -> String:
  register_list(registers(count), "")

def wl_load_rows(count: Nat, index: Nat) -> String:
  match Nat.is_lt(index, count):
    case True{}:
      cat(["    if ((N) <= ", Nat.show(index), ") break; ", register_load_name(index), " = e.mem[(A) + ", Nat.show(index), "]; \\\n", wl_load_rows(count, Nat.add(index, 1n))])
    case False{}: ""

def register_load_name(index: Nat) -> String:
  match Nat.is_eq(index, 6n):
    case True{}: "rp"
    case False{}: cat(["r", Nat.show(index)])

def wl_last_rows(count: Nat, index: Nat) -> String:
  match Nat.is_lt(index, count):
    case True{}:
      cat(["    case ", Nat.show(index), ": ", register_load_name(index), " = (X); \\\n      break; \\\n", wl_last_rows(count, Nat.add(index, 1n))])
    case False{}: ""

def wl_save_rows(count: Nat, index: Nat) -> String:
  match Nat.is_lt(index, count):
    case True{}: cat(["(V)[", Nat.show(index), "] = ", register_load_name(index), "; ", wl_save_rows(count, Nat.add(index, 1n))])
    case False{}: ""

def wl_take_rows(count: Nat, index: Nat) -> String:
  match Nat.is_lt(index, count):
    case True{}: cat([register_load_name(index), " = (V)[", Nat.show(index), "]; ", wl_take_rows(count, Nat.add(index, 1n))])
    case False{}: ""

def wl_table_rows(entries: List<&2, Entry>, last: U32) -> String:
  match entries:
    case Nil{}: ""
    case +entry <> rest:
      match entry:
        case Entry{index, arity, kind}: wl_table_one(U32.is_gt(index, last), index, rest, last)

def wl_table_one(done: Bool, index: U32, rest: List<&2, Entry>, last: U32) -> String:
  match done:
    case True{}: ""
    case False{}: cat(["WL_X(", U32.show(index), ") ", wl_table_rows(rest, last)])

def entry_at_kind(entries: List<&2, Entry>, want: Nat) -> Maybe<&2, Entry>:
  match entries:
    case Nil{}: None{}
    case +entry <> rest:
      match entry:
        case Entry{index, arity, kind}:
          match Nat.is_eq(kind_want(kind), want):
            case True{}: Some{entry}
            case False{}: entry_at_kind(rest, want)

def kind_want(kind: Kind) -> Nat:
  match kind:
    case KindMain{}: 1n
    case KindLibrary{}: 1n
    case KindEmit{}: 2n
    case KindApply{}: 3n
    case KindExit{}: 4n
    case KindEnter{}: 5n
    case _: 0n

def rt_entry(entries: List<&2, Entry>, want: Nat) -> U32:
  match entry_at_kind(entries, want):
    case Some{Entry{index, arity, kind}}: index
    case None{}: 0u

def segment_body(index: U32, arity: Nat, kind: Kind) -> Part:
  match reserved_entry(kind):
    case True{}: okp("")
    case False{}: PartOk{cat(["  WL_CASE(", U32.show(index), ")\n  {\n", segment_regs(arity, 0n), "    WL_OPEN\n", segment_decl(arity), segment_fills(arity, 0n), "    r0 = bend_run(e, ", U32.show(index), ", ", segment_args(arity), ", ", Nat.show(arity), ");\n    WL_RETN(1);\n  }}\n\n"])}

def segment_regs(arity: Nat, index: Nat) -> String:
  match Nat.is_lt(index, arity):
    case True{}: cat(["    Term _x", Nat.show(index), " = r", Nat.show(index), ";\n", segment_regs(arity, Nat.add(index, 1n))])
    case False{}: ""

def segment_decl(arity: Nat) -> String:
  match Nat.is_eq(arity, 0n):
    case True{}: ""
    case False{}: "    Term _xs[BEND_MAX_ARITY];\n"

def segment_fills(arity: Nat, index: Nat) -> String:
  match Nat.is_lt(index, arity):
    case True{}: cat(["    _xs[", Nat.show(index), "] = _x", Nat.show(index), ";\n", segment_fills(arity, Nat.add(index, 1n))])
    case False{}: ""

def segment_args(arity: Nat) -> String:
  match Nat.is_eq(arity, 0n):
    case True{}: "0"
    case False{}: "_xs"

def entry_segments(entries: List<&2, Entry>) -> Part:
  match entries:
    case Nil{}: okp("")
    case +entry <> rest: part_append(entry_segment(entry), entry_segments(rest))

# ---------------------------------------------------------------------------
# C tables and helpers
# ---------------------------------------------------------------------------

def fid_define_at(key: String, index: U32) -> String:
  cat(["#define ", fid_symbol(index), " ", U32.show(index), "\n"])

def decl_fid_defines(declarations: List<&2, BIR.Declaration>, by_code: Map<&2, U32>, by_key: Map<&2, U32>, by_foreign: Map<&2, U32>) -> String:
  match declarations:
    case Nil{}: ""
    case +item <> rest:
      match item:
        case BIR.FunctionDeclaration{key, code, parameters}:
          cat([fid_define_at(key, map_u32(by_code, U32.show(code))), decl_fid_defines(rest, by_code, by_key, by_foreign)])
        case BIR.LazyDeclaration{key, body}:
          cat([fid_define_at(key, map_u32(by_key, key)), decl_fid_defines(rest, by_code, by_key, by_foreign)])
        case BIR.ForeignDeclaration{key, _, _, arity, _, _, _, _, _}:
          cat([fid_define_at(key, map_u32(by_foreign, key)), decl_fid_defines(rest, by_code, by_key, by_foreign)])
        case _: decl_fid_defines(rest, by_code, by_key, by_foreign)

def runtime_defines(entries: List<&2, Entry>) -> String:
  cat([
    "#define FID_MAIN ", U32.show(rt_entry(entries, 1n)), "\n",
    "#define FID_IO_EMIT ", U32.show(rt_entry(entries, 2n)), "\n",
    "#define FID_CLO_APPLY ", U32.show(rt_entry(entries, 3n)), "\n",
    "#define FID_EXIT ", U32.show(rt_entry(entries, 4n)), "\n",
    "#define FID_ENTER ", U32.show(rt_entry(entries, 5n)), "\n"
  ])

def wl_macros(regs: Nat) -> String:
  cat([
    "#define WL_RESW 1\n#define BANGS 0\n\n",
    "#define WL_BANK ", register_decls(regs), "\n\n",
    "#define WL_LOAD(A, N) do { \\\n", wl_load_rows(regs, 0n), "  } while (0);\n\n",
    "#define WL_LAST(X) switch (war) { \\\n", wl_last_rows(regs, 0n), "  }\n\n",
    "#define WL_SAVE(V) ", wl_save_rows(1n, 0n), "\n",
    "#define WL_TAKE(V) ", wl_take_rows(1n, 0n), "\n\n",
    "#define WL_SIG Env e, DEV Term* sp, u32 seq, u32 rn, ", register_names(regs), "\n",
    "#define WL_ALL e, sp, seq, rn, ", register_names(regs), "\n"
  ])

def dispatch_prototypes(entries: List<&2, Entry>) -> String:
  match entries:
    case Nil{}: ""
    case +entry <> rest:
      match entry:
        case Entry{index, arity, kind}:
          cat(["static Term bend_e", U32.show(index), "(Env e, Term* x, u32 n, u32* tc, u32* tn, Term* tb);\n", dispatch_prototypes(rest)])

def dispatch_cases(entries: List<&2, Entry>) -> String:
  match entries:
    case Nil{}: ""
    case +entry <> rest:
      match entry:
        case Entry{index, arity, kind}:
          cat(["  case ", U32.show(index), ": return bend_e", U32.show(index), "(e, x, n, tc, tn, tb);\n", dispatch_cases(rest)])

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

def helper_core(max: Nat, cases: String) -> String:
  cat([
    "#define BEND_MAX_ARITY ", Nat.show(max), "\n",
    "#define BEND_NOT_TAIL 0xffffffffu\n\n",
    "static Term bend_dispatch(Env e, u32 code, Term* x, u32 n, u32* tc, u32* tn, Term* tb);\n\n",
    "static Term bend_fail(Env e, const char* msg) {\n#if DEVICE\n  (void)msg;\n  err_post(e.mem, ERR_DEEP);\n  return 0;\n#else\n  fflush(stdout);\n  fprintf(stderr, \"bend: %s\\n\", msg);\n  fflush(stderr);\n  _exit(1);\n#endif\n}\n\n",
    "static Term bend_node(Env e, u32 cid, u32 n, THR Term* v) {\n  u64 l = 0;\n  if (n != 0) {\n    l = heap_alloc(e, cls_fit(n));\n    for (u32 i = 0; i < n; i += 1) {\n      e.mem[l + i] = v[i];\n    }\n  }\n  return term_ctr(cid, l);\n}\n\n",
    "static Term bend_closure(Env e, u32 code, u32 n, THR Term* v) {\n  u64 l = 0;\n  if (n != 0) {\n    l = heap_alloc(e, cls_fit(n));\n    for (u32 i = 0; i < n; i += 1) {\n      e.mem[l + i] = term_keep(e, v[i], 1);\n    }\n  }\n  return ((u64)TAG_CLO << 56) | ((u64)code << 40) | l;\n}\n\n",
    "static Term bend_run(Env e, u32 code, Term* args, u32 n) {\n  Term buf[BEND_MAX_ARITY];\n  if (n > BEND_MAX_ARITY) {\n    return bend_fail(e, \"bend: call arity over the C render maximum\");\n  }\n  for (u32 i = 0; i < n; i += 1) {\n    buf[i] = args[i];\n  }\n  for (;;) {\n    u32 tc = BEND_NOT_TAIL;\n    u32 tn = 0;\n    Term v = bend_dispatch(e, code, buf, n, &tc, &tn, buf);\n    if (tc == BEND_NOT_TAIL) {\n      return v;\n    }\n    code = tc;\n    n = tn;\n  }\n}\n\n",
    "static Term bend_apply(Env e, Term f, Term a) {\n  if (term_tag(f) != TAG_CLO) {\n    return bend_fail(e, \"bend: applying a non-function\");\n  }\n  u32 code = (u32)term_aux(f);\n  u32 ar = (u32)FID_T[code][0];\n  u32 k = ar > 0 ? ar - 1 : 0;\n  u64 loc = term_loc(f);\n  Term v[BEND_MAX_ARITY];\n  for (u32 i = 0; i < k; i += 1) {\n    v[i] = loc != 0 ? e.mem[loc + i] : 0;\n  }\n  if (k >= BEND_MAX_ARITY) {\n    return bend_fail(e, \"bend: closure arity over the C render maximum\");\n  }\n  v[k] = a;\n  spare_free(e, cls_fit(k), loc);\n  return bend_run(e, code, v, k + 1);\n}\n\n",
    "static Term bend_tail_apply(Env e, Term f, Term a, u32* tc, u32* tn, Term* tb) {\n  if (term_tag(f) != TAG_CLO) {\n    return bend_fail(e, \"bend: applying a non-function\");\n  }\n  u32 code = (u32)term_aux(f);\n  u32 ar = (u32)FID_T[code][0];\n  u32 k = ar > 0 ? ar - 1 : 0;\n  u64 loc = term_loc(f);\n  Term v[BEND_MAX_ARITY];\n  for (u32 i = 0; i < k; i += 1) {\n    v[i] = loc != 0 ? e.mem[loc + i] : 0;\n  }\n  if (k >= BEND_MAX_ARITY) {\n    return bend_fail(e, \"bend: closure arity over the C render maximum\");\n  }\n  v[k] = a;\n  spare_free(e, cls_fit(k), loc);\n  for (u32 i = 0; i <= k; i += 1) {\n    tb[i] = v[i];\n  }\n  *tc = code;\n  *tn = k + 1;\n  return 0;\n}\n\n",
    "static Term bend_project(Env e, Term v, u32 field) {\n  if (term_tag(v) == TAG_PAK) {\n    return term_loc(v);\n  }\n  return e.mem[term_peek(e.mem, v) + field];\n}\n\n",
    "static u64 bend_hastag(Term v, u32 cid) {\n  u64 tag = term_tag(v);\n  return (tag == TAG_CTR || tag == TAG_PAK) && term_aux(v) == (u64)cid;\n}\n\n",
    "static Nat bend_nat_pred(Nat v) {\n  return v == 0 ? 0 : v - 1;\n}\n\n",
    "static Nat bend_f32_to_nat(Env e, Term v) {\n  f32 x = f32_unbox(v);\n  return nat_chk(e, x < 0.0f ? 0 : (u64)x);\n}\n\n",
    "static Term bend_text(Env e, const char* p, u64 n) {\n  return io_str(e, p, n);\n}\n\n",
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
    "static Term bend_array_leaf_value(Env e, Term a) {\n  return blk_read(e.mem, true, term_peek(e.mem, a), 0);\n}\n\n",
    "static Term bend_dispatch(Env e, u32 code, Term* x, u32 n, u32* tc, u32* tn, Term* tb) {\n  switch (code) {\n", cases, "  default: return bend_fail(e, \"bend: invalid entry\");\n  }\n}\n\n"
  ])

def tables_part(plan: Plan) -> Part:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, library, exports, imports, fkeys}:
      tables_render(plan, cids, entries, declarations, by_code, by_key, by_foreign, main_pure, show_desc, show_names)

def tables_render(plan: Plan, cids: List<&2, CidRow>, entries: List<&2, Entry>, declarations: List<&2, BIR.Declaration>, by_code: Map<&2, U32>, by_key: Map<&2, U32>, by_foreign: Map<&2, U32>, main_pure: Bool, show_desc: String, show_names: String) -> Part:
  regs = max_arity(entries)
  bodies = entry_bodies(entries, plan)
  exports = exports_part(plan)
  match bodies exports:
    case PartFail{message} _: PartFail{message}
    case _ PartFail{message}: PartFail{message}
    case PartOk{body_text} PartOk{export_text}:
      PartOk{cat([
        part_text(runtime_cid_aliases(cids)),
        cid_defines(cids),
        decl_fid_defines(declarations, by_code, by_key, by_foreign),
        runtime_defines(entries), "\n",
        "CONSTV u8 CID_T[][2] = { ", cid_table(cids), "\n",
        "CONSTV u8 FID_T[][3] = { ", fid_table(entries), "\n",
        "#define STAT_LEN 0\n\n",
        wl_macros(regs), "\n",
        "#define WL_TABLE ", wl_table_rows(entries, rt_entry(entries, 4n)), "\n",
        "#define MAIN_FID FID_MAIN\n",
        "#define MAIN_PURE ", main_pure_text(main_pure), "\n",
        "#define BLK_SHR 0\n\n",
        "#if !DEVICE\nstatic const u32 SHOW_DESC[] = { ", show_desc, " };\nstatic const char* SHOW_NAMES[] = { ", show_names, " };\n#endif\n\n",
        "#if !DEVICE\n",
        helper_prototypes(),
        dispatch_prototypes(entries),
        helper_core(max_arity(entries), dispatch_cases(entries)),
        body_text,
        export_text,
        "#endif\n"
      ])}

def main_pure_text(pure: Bool) -> String:
  match pure:
    case True{}: "1"
    case False{}: "0"

def spins_part() -> Part:
  okp("CONSTV u64 STAT_IMG[] = { 0 };\n")

def segments_part(plan: Plan) -> Part:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, library, exports, imports, fkeys}:
      PartOk{cat(["#if !DEVICE\n", part_text(entry_segments(entries)), "#endif\n"])}

def part_text(part: Part) -> String:
  match part:
    case PartOk{text}: text
    case PartFail{message}: ""

# ---------------------------------------------------------------------------
# Effect sources
# ---------------------------------------------------------------------------

def requests_part(plan: Plan) -> Part:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, library, exports, imports, fkeys}:
      requests_check(imports, fkeys, declarations, constructors, cids, declarations)

def requests_check(imports: List<&2, CImport>, fkeys: List<&2, String>, declarations: List<&2, BIR.Declaration>, constructors: List<&2, BIR.ConstructorLayout>, cids: List<&2, CidRow>, decls: List<&2, BIR.Declaration>) -> Part:
  match requests_uncovered(fkeys, imports, declarations):
    case Some{key}: failp(cat(["no C import source was resolved for foreign `", key, "`; the adapter must pass the selected .c alternative"]))
    case None{}: requests_each(imports, constructors, decls, cids)

def requests_uncovered(fkeys: List<&2, String>, imports: List<&2, CImport>, declarations: List<&2, BIR.Declaration>) -> Maybe<&2, String>:
  match fkeys:
    case Nil{}: None{}
    case +key <> rest: requests_uncovered_one(foreign_namespace(key, declarations), key, rest, imports, declarations)

def foreign_namespace(key: String, declarations: List<&2, BIR.Declaration>) -> Maybe<&2, String>:
  match find_declaration(key, declarations):
    case Some{decl}: foreign_namespace_item(decl)
    case None{}: None{}

def foreign_namespace_item(decl: BIR.Declaration) -> Maybe<&2, String>:
  match decl:
    case BIR.ForeignDeclaration{_, namespace, _, _, _, _, _, _, _}: Some(namespace)
    case _: None{}

def requests_uncovered_one(namespace: Maybe<&2, String>, key: String, rest: List<&2, String>, imports: List<&2, CImport>, declarations: List<&2, BIR.Declaration>) -> Maybe<&2, String>:
  match namespace:
    case None{}: Some(key)
    case Some{space}:
      match import_has_namespace(imports, space):
        case True{}: requests_uncovered(rest, imports, declarations)
        case False{}: Some(key)

def import_has_namespace(imports: List<&2, CImport>, namespace: String) -> Bool:
  match imports:
    case Nil{}: False{}
    case +imp <> rest:
      match imp:
        case CImport{_, own, _}: import_has_namespace_one(String.eq(own, namespace), rest, namespace)

def import_has_namespace_one(found: Bool, rest: List<&2, CImport>, namespace: String) -> Bool:
  match found:
    case True{}: True{}
    case False{}: import_has_namespace(rest, namespace)

def requests_each(imports: List<&2, CImport>, constructors: List<&2, BIR.ConstructorLayout>, declarations: List<&2, BIR.Declaration>, cids: List<&2, CidRow>) -> Part:
  match imports:
    case Nil{}: okp("")
    case +imp <> rest:
      match imp:
        case CImport{path, namespace, source}:
          block = cat([
            "/* effect source: ", path, " */\n",
            source, "\n"
          ])
          part_append(rewrite_source(block, namespace, cids, declarations), requests_each(rest, constructors, declarations, cids))

def rewrite_source(source: String, namespace: String, cids: List<&2, CidRow>, declarations: List<&2, BIR.Declaration>) -> Part:
  cid_map = namespaced_map(cid_exact_map(cids), cid_keys(cids), namespace)
  fid_exact = fid_exact_map(declarations)
  fid_map = namespaced_map(fid_exact, fid_keys(declarations), namespace)
  match Link.rewrite(source, cid_map, fid_map):
    case Link.LinkSuccess{source: linked}: PartOk(linked)
    case Link.LinkFailure{message}: PartFail(message)

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

def insert_section(lines: List<&2, String>, title: String, block: String) -> Maybe<&2, List<&2, String>>:
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
    case Some{one}: Some{String.join(one, '\n')}

# ---------------------------------------------------------------------------
# CID(k) / FID(k) rewriting
# ---------------------------------------------------------------------------

def cid_exact_map(cids: List<&2, CidRow>) -> Map<&2, String>:
  cid_exact_each(cids, Map.new(&2, String))

def cid_exact_each(cids: List<&2, CidRow>, acc: Map<&2, String>) -> Map<&2, String>:
  match cids:
    case Nil{}: acc
    case +row <> rest:
      match row:
        case CidRow{cid, key, _}: cid_exact_each(rest, Map.set(&2, String, acc, key, cid_symbol(cid)))

# A short name is usable only when exactly one emitted key ends with it and no
# key equals it, so Base's Con/Nil/Some/True can never shadow a user type.
def fid_exact_map(declarations: List<&2, BIR.Declaration>, by_code: Map<&2, U32>, by_foreign: Map<&2, U32>, by_native: Map<&2, U32>) -> Map<&2, String>:
  fid_exact_decl(declarations, fid_fixed(Map.new(&2, String)), by_code, by_foreign, by_native)

def namespaced_map(exact: Map<&2, String>, keys: List<&2, String>, namespace: String) -> Map<&2, String>:
  namespaced_each(exact, keys, namespace)

# Exactly as comp.ts c_ids: a source names `namespace:key` first, then the bare
# authoritative key. No suffix, case or segment guessing.
def namespaced_each(acc: Map<&2, String>, keys: List<&2, String>, namespace: String) -> Map<&2, String>:
  match keys:
    case Nil{}: acc
    case +key <> rest:
      match Bool.not(String.is_empty(namespace)):
        case True{}: namespaced_each(namespaced_set(acc, key, namespace), rest, namespace)
        case False{}: namespaced_each(acc, rest, namespace)

def namespaced_set(acc: Map<&2, String>, key: String, namespace: String) -> Map<&2, String>:
  match IndexLookup.find(String, acc, key):
    case Some{macro}: map_set_first(acc, String.append(namespace, String.append(":", key)), macro)
    case None{}: acc

def fid_fixed(acc: Map<&2, String>) -> Map<&2, String>:
  fid_fixed_one(map_set_first(acc, "Clo~apply", "FID_CLO_APPLY"))

def fid_fixed_one(acc: Map<&2, String>) -> Map<&2, String>:
  map_set_first(acc, "IO~emit", "FID_IO_EMIT")

def fid_exact_decl(declarations: List<&2, BIR.Declaration>, acc: Map<&2, String>, by_code: Map<&2, U32>, by_foreign: Map<&2, U32>, by_native: Map<&2, U32>) -> Map<&2, String>:
  match declarations:
    case Nil{}: acc
    case +item <> rest:
      match item:
        case BIR.FunctionDeclaration{key, code, parameters}: fid_exact_decl(rest, map_set_first(acc, key, fid_exact_symbol(key, by_code, by_foreign, by_native)), by_code, by_foreign, by_native)
        case BIR.LazyDeclaration{key, body}: fid_exact_decl(rest, map_set_first(acc, key, fid_exact_symbol(key, by_code, by_foreign, by_native)), by_code, by_foreign, by_native)
        case BIR.ForeignDeclaration{key, namespace, imported, arity, sources, quantities, span, parameter_types, result}: fid_exact_decl(rest, map_set_first(acc, key, fid_exact_symbol(key, by_code, by_foreign, by_native)), by_code, by_foreign, by_native)
        case BIR.NativeDeclaration{key, primitive, quantities}: fid_exact_decl(rest, map_set_first(acc, key, fid_exact_symbol(key, by_code, by_foreign, by_native)), by_code, by_foreign, by_native)
        case _: fid_exact_decl(rest, acc, by_code, by_foreign, by_native)

def fid_exact_symbol(key: String, by_code: Map<&2, U32>, by_foreign: Map<&2, U32>, by_native: Map<&2, U32>) -> String:
  match IndexLookup.find(U32, by_code, key):
    case Some{index}: fid_symbol(index)
    case None{}: fid_native_symbol(key, by_foreign, by_native)

def fid_native_symbol(key: String, by_foreign: Map<&2, U32>, by_native: Map<&2, U32>) -> String:
  match IndexLookup.find(U32, by_native, key):
    case Some{index}: fid_symbol(index)
    case None{}: fid_symbol(map_u32(by_foreign, key))

def macro_collision_cids(cids: List<&2, CidRow>) -> Maybe<&2, String>:
  macro_collision_rows(cids, Map.new(&2, String))

def macro_collision_rows(cids: List<&2, CidRow>, seen: Map<&2, String>) -> Maybe<&2, String>:
  match cids:
    case Nil{}: None{}
    case +row <> rest:
      match row:
        case CidRow{cid, key, _}: macro_collision_one(key, cid_symbol(cid), cids, seen, rest)

def macro_collision_one(key: String, macro: String, cids: List<&2, CidRow>, seen: Map<&2, String>, rest: List<&2, CidRow>) -> Maybe<&2, String>:
  match IndexLookup.find(String, seen, macro):
    case Some{other}:
      match String.eq(other, key):
        case True{}: macro_collision_rows(rest, seen)
        case False{}: Some(cat(["constructor keys `", other, "` and `", key, "` both sanitize to macro ", macro]))
    case None{}: macro_collision_rows(rest, Map.set(&2, String, seen, macro, key))

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def emit(program: BIR.Program, runtime: String, imports: List<&2, CImport>) -> EmitResult:
  match plan_make(program, imports):
    case PlanFail{message}: EmitFailure{message}
    case PlanOk{plan}: render(plan, runtime)

def render(plan: Plan, runtime: String) -> EmitResult:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, library, exports, imports, fkeys}:
      render_checked(cids, declarations, plan, runtime)

def render_checked(cids: List<&2, CidRow>, declarations: List<&2, BIR.Declaration>, plan: Plan, runtime: String) -> EmitResult:
  match plan:
    case Plan{by_code, by_foreign, by_native, declarations: plan_decls, cids: plan_cids, cid_macros, fid_macros, entries, by_key, stages, constructors, families, main_pure, show_desc, show_names, library, exports, imports, fkeys}:
      match macro_collision_cids(cids):
        case Some{message}: EmitFailure(message)
        case None{}: render_parts(plan, runtime, cid_exact_map(cids), fid_exact_map(plan_decls, by_code, by_foreign, by_native))

def render_parts(plan: Plan, runtime: String, cid_map: Map<&2, String>, fid_map: Map<&2, String>) -> EmitResult:
  tables = tables_part(plan)
  spins = spins_part()
  segments = segments_part(plan)
  requests = requests_part(plan)
  parts = [tables, spins, segments, requests]
  match part_require(parts):
    case None{}: EmitFailure(part_first(parts))
    case Some{_}:
      render_assemble(runtime, part_text(tables), part_text(spins), part_text(segments), part_text(requests), cid_map, fid_map)

def render_assemble(runtime: String, tables: String, spins: String, segments: String, requests: String, cid_map: Map<&2, String>, fid_map: Map<&2, String>) -> EmitResult:
  match assemble(runtime, tables, spins, segments, requests):
    case None{}: EmitFailure("the runtime source is missing one of the // Tables, // Spins, // Segments or // Requests sections")
    case Some{source}: render_rewrite(source, cid_map, fid_map)

def render_rewrite(source: String, cid_map: Map<&2, String>, fid_map: Map<&2, String>) -> EmitResult:
  match Link.rewrite(source, cid_map, fid_map):
    case Link.LinkSuccess{source: linked}: EmitSuccess(linked)
    case Link.LinkFailure{message}: EmitFailure(message)

# ---------------------------------------------------------------------------
# Library exports
# ---------------------------------------------------------------------------
#
# A library artifact is still one runtime translation unit, so the host reaches
# the exports through this small C ABI. A `fast` entry calls its code directly;
# an entry-less export evaluates the symbol and applies the arguments, which is
# exactly how a read of that declaration behaves.

type ExportRow is Data:
  ExportRow{name: String, index: U32, mode: Nat, arity: Nat}

def export_rows(exports: List<&2, BIR.Export>, declarations: List<&2, BIR.Declaration>, by_code: Map<&2, U32>, by_key: Map<&2, U32>, by_foreign: Map<&2, U32>, by_native: Map<&2, U32>, stages: Map<&2, U32>, entries: List<&2, Entry>) -> Maybe<&2, List<&2, ExportRow>>:
  match exports:
    case Nil{}: Some{Nil{}}
    case +item <> rest: export_row_pair(export_row(item, declarations, by_code, by_key, by_foreign, by_native, stages, entries), export_rows(rest, declarations, by_code, by_key, by_foreign, by_native, stages, entries))

def export_row_pair(one: Maybe<&2, ExportRow>, rest: Maybe<&2, List<&2, ExportRow>>) -> Maybe<&2, List<&2, ExportRow>>:
  match one rest:
    case Some{row} Some{rows}: Some{row <> rows}
    case _ _: None{}

def export_row(item: BIR.Export, declarations: List<&2, BIR.Declaration>, by_code: Map<&2, U32>, by_key: Map<&2, U32>, by_foreign: Map<&2, U32>, by_native: Map<&2, U32>, stages: Map<&2, U32>, entries: List<&2, Entry>) -> Maybe<&2, ExportRow>:
  match item:
    case BIR.Export{key, entry, parameter_types, result}: export_entry(key, entry, parameter_types, result, declarations, by_code, by_key, by_foreign, by_native, stages, entries)

def export_entry(key: String, entry: Maybe<&2, BIR.Entry>, parameter_types: List<&2, BIR.Descriptor>, result: BIR.Descriptor, declarations: List<&2, BIR.Declaration>, by_code: Map<&2, U32>, by_key: Map<&2, U32>, by_foreign: Map<&2, U32>, by_native: Map<&2, U32>, stages: Map<&2, U32>, entries: List<&2, Entry>) -> Maybe<&2, ExportRow>:
  match entry:
    case Some{item}:
      match item:
        case BIR.Entry{code, arity}: export_direct(key, code, arity, parameter_types, by_code)
    case None{}: export_symbol(key, parameter_types, declarations, by_code, by_key, by_foreign, by_native, stages, entries)

# Entry.arity is the live parameter count (FIRContract fact). A direct host call
# is exact only when the checked parameter count agrees; otherwise the export
# table fails instead of guessing a conversion.
def export_direct(key: String, code: U32, arity: Nat, parameter_types: List<&2, BIR.Descriptor>, by_code: Map<&2, U32>) -> Maybe<&2, ExportRow>:
  match Nat.is_eq(arity, List.length(&2, BIR.Descriptor, parameter_types)):
    case True{}: Some{ExportRow{key, map_u32(by_code, U32.show(code)), 0n, arity}}
    case False{}: None{}

def export_symbol(key: String, parameter_types: List<&2, BIR.Descriptor>, declarations: List<&2, BIR.Declaration>, by_code: Map<&2, U32>, by_key: Map<&2, U32>, by_foreign: Map<&2, U32>, by_native: Map<&2, U32>, stages: Map<&2, U32>, entries: List<&2, Entry>) -> Maybe<&2, ExportRow>:
  match find_declaration(key, declarations):
    case None{}: None{}
    case Some{item}: export_symbol_item(item, key, parameter_types, by_key, by_foreign, by_native)

def export_symbol_item(item: BIR.Declaration, key: String, parameter_types: List<&2, BIR.Descriptor>, by_key: Map<&2, U32>, by_foreign: Map<&2, U32>, by_native: Map<&2, U32>) -> Maybe<&2, ExportRow>:
  n = List.length(&2, BIR.Descriptor, parameter_types)
  match item:
    case BIR.FunctionDeclaration{_, code, parameters}: Some{ExportRow{key, map_u32(by_key, key), 1n, n}}
    case BIR.LazyDeclaration{_, body}: Some{ExportRow{key, map_u32(by_key, key), 1n, n}}
    case BIR.ForeignDeclaration{_, _, _, arity, _, _, _, _, _}: export_foreign(key, n, arity, map_u32(by_foreign, key))
    case BIR.NativeDeclaration{_, _, quantities}: export_native(key, n, List.length(&2, BIR.Quantity, quantities), map_u32(by_native, key))
    case _: None{}

# The C host ABI is only exact when the published checked parameter count agrees
# with the stage's own arity: foreign request fields and native quantities.
def export_foreign(key: String, checked: Nat, declared: Nat, index: U32) -> Maybe<&2, ExportRow>:
  match Nat.is_eq(checked, declared):
    case True{}: Some{ExportRow{key, index, 1n, checked}}
    case False{}: None{}

def export_native(key: String, checked: Nat, quantities: Nat, index: U32) -> Maybe<&2, ExportRow>:
  match Nat.is_eq(checked, quantities):
    case True{}: Some{ExportRow{key, index, 1n, checked}}
    case False{}: None{}

def export_names(rows: List<&2, ExportRow>, acc: List<&2, String>) -> String:
  match rows:
    case Nil{}: String.join(List.reverse(&2, String, acc), ", ")
    case +row <> rest:
      match row:
        case ExportRow{name, index, mode, arity}: export_names(rest, c_quote(name) <> acc)

def export_indices(rows: List<&2, ExportRow>, acc: List<&2, String>) -> String:
  match rows:
    case Nil{}: String.join(List.reverse(&2, String, acc), ", ")
    case +row <> rest:
      match row:
        case ExportRow{name, index, mode, arity}: export_indices(rest, cat([U32.show(index), "u"]) <> acc)

def export_modes(rows: List<&2, ExportRow>, acc: List<&2, String>) -> String:
  match rows:
    case Nil{}: String.join(List.reverse(&2, String, acc), ", ")
    case +row <> rest:
      match row:
        case ExportRow{name, index, mode, arity}: export_modes(rest, Nat.show(mode) <> acc)

def export_arities(rows: List<&2, ExportRow>, acc: List<&2, String>) -> String:
  match rows:
    case Nil{}: String.join(List.reverse(&2, String, acc), ", ")
    case +row <> rest:
      match row:
        case ExportRow{name, index, mode, arity}: export_arities(rest, Nat.show(arity) <> acc)

def exports_c(rows: List<&2, ExportRow>) -> String:
  match rows:
    case Nil{}: ""
    case _:
      cat([
        "#define BEND_EXPORT_COUNT ", Nat.show(List.length(&2, ExportRow, rows)), "\n",
        "static const char* BEND_EXPORT_NAMES[] = { ", export_names(rows, Nil{}), " };\n",
        "static const u32 BEND_EXPORT_INDEX[] = { ", export_indices(rows, Nil{}), " };\n",
        "static const u8 BEND_EXPORT_MODE[] = { ", export_modes(rows, Nil{}), " };\n",
        "static const u8 BEND_EXPORT_ARITY[] = { ", export_arities(rows, Nil{}), " };\n",
        "u32 bend_export_count(void) {\n  return BEND_EXPORT_COUNT;\n}\n\n",
        "const char* bend_export_name(u32 i) {\n  return i < BEND_EXPORT_COUNT ? BEND_EXPORT_NAMES[i] : 0;\n}\n\n",
        "Term bend_export_call(Env e, u32 i, Term* args, u32 n) {\n",
        "  if (i >= BEND_EXPORT_COUNT) {\n    return bend_fail(e, \"bend: export index out of range\");\n  }\n",
        "  if (BEND_EXPORT_MODE[i] == 0) {\n",
        "    if (n != (u32)BEND_EXPORT_ARITY[i]) {\n      return bend_fail(e, \"bend: export called at the wrong arity\");\n    }\n",
        "    return bend_run(e, BEND_EXPORT_INDEX[i], args, n);\n  }\n",
        "  Term v = bend_run(e, BEND_EXPORT_INDEX[i], 0, 0);\n",
        "  for (u32 j = 0; j < n; j += 1) {\n    v = bend_apply(e, v, args[j]);\n  }\n",
        "  return v;\n}\n\n"
      ])

def exports_part(plan: Plan) -> Part:
  match plan:
    case Plan{cids, cid_macros, fid_macros, entries, by_code, by_key, by_foreign, by_native, stages, constructors, families, declarations, main_pure, show_desc, show_names, library, exports, imports, fkeys}:
      match export_rows(exports, declarations, by_code, by_key, by_foreign, by_native, stages, entries):
        case None{}: failp("a library export names no callable, or its checked parameter count disagrees with its entry")
        case Some{rows}: okp(exports_c(rows))
