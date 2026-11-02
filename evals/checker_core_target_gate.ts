import {runHeavyGate} from './heavy_gate.ts';
import {readFileSync,writeFileSync,mkdtempSync,mkdirSync,rmSync,existsSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {resolve,join,dirname} from 'node:path';
import {tmpdir} from 'node:os';
const options=new Map(process.argv.slice(2).map(arg=>{const at=arg.indexOf('=');if(at<0)throw Error('Expected --option=value');return [arg.slice(0,at),arg.slice(at+1)];}));
const component=options.get('--component');if(!component)throw Error('Required --component');
const parser=resolve(options.get('--parser')??'checkpoints/bootstrap-parser-rebuild-compat-three-list-linear-v1.js');
const report=resolve(options.get('--report')??'checkpoints/checker-core-target-gate-v1.json');
const sha=(path:string)=>createHash('sha256').update(readFileSync(path)).digest('hex');
const bit='type Bit is Data:\n  BitZero{}\n  BitOne{}\n';
const duo='type Duo is Type:\n  Duo{left: Bit, right: Bit}\n';
const usagePair=bit+'type Pair is Data:\n  Pair{left: Bit, right: Bit}\n';
const usagePack=usagePair+'def pack(left: Bit, right: Bit) -> Pair:\n  Pair{left, right}\n';
const usagePick=bit+'def pick(-A: Type, live: A, -erased: A) -> A:\n  live\n';
const fixtures=[
 {name:'enum-constant',source:bit+'def main() -> Bit:\n  BitOne{}\n',accepted:true,output:'BitOne{}'},
 {name:'affine-identity',source:bit+'def identity(x: Bit) -> Bit:\n  x\ndef main() -> Bit:\n  identity(BitZero{})\n',accepted:true,output:'BitZero{}'},
 {name:'reusable-duplicate',source:bit+duo+'def twice(+x: Bit) -> Duo:\n  Duo{x, x}\ndef main() -> Duo:\n  twice(BitOne{})\n',accepted:true,output:'Duo{BitOne{}, BitOne{}}'},
 {name:'return-type-mismatch',source:bit+'type Other is Data:\n  Other{}\ndef wrong(x: Bit) -> Other:\n  x\n',accepted:false},
 {name:'affine-duplicate',source:bit+duo+'def twice(x: Bit) -> Duo:\n  Duo{x, x}\n',accepted:false},
 {name:'undefined-reference',source:bit+'def main() -> Bit:\n  absent\n',accepted:false},
 {name:'inherited-reusable-lambda',source:bit+duo+'def twice() -> (@+x: Bit -> Duo):\n  x => Duo{x, x}\ndef main() -> Duo:\n  twice()(BitOne{})\n',accepted:true,output:'Duo{BitOne{}, BitOne{}}'},
 {name:'promoted-reusable-lambda',source:bit+duo+'def twice() -> (Bit -> Duo):\n  +x => Duo{x, x}\ndef main() -> Duo:\n  twice()(BitZero{})\n',accepted:true,output:'Duo{BitZero{}, BitZero{}}'},
 {name:'affine-lambda-duplicate',source:bit+duo+'def twice() -> (Bit -> Duo):\n  x => Duo{x, x}\n',accepted:false},
 {name:'promoted-lambda-lower-kind',source:'type Token is Type:\n  Token{}\ndef identity() -> (Token -> Token):\n  +x => x\n',accepted:false},
 {name:'recursive-datatype',source:'type Chain is Data:\n  Stop{}\n  Link{tail: Chain}\ndef main() -> Chain:\n  Link{Stop{}}\n',accepted:true,output:'Link{Stop{}}'},
 {name:'self-referential-datatype-kind',source:'type Loop is Kind(Loop):\n  LoopCtor{}\ndef main() -> Loop:\n  LoopCtor{}\n',accepted:false},
 {name:'single-enum-match-complete',source:bit+'def flip(x: Bit) -> Bit:\n  match x:\n    case BitZero{}: BitOne{}\n    case BitOne{}: BitZero{}\ndef main() -> Bit:\n  flip(BitZero{})\n',accepted:true,output:'BitOne{}'},
 {name:'single-enum-match-incomplete',source:bit+'def flip(x: Bit) -> Bit:\n  match x:\n    case BitZero{}: BitOne{}\ndef main() -> Bit:\n  flip(BitZero{})\n',accepted:false},
 {name:'joint-match-complete',source:bit+'def xor(left: Bit, right: Bit) -> Bit:\n  match left right:\n    case BitZero{} BitZero{}: BitZero{}\n    case BitZero{} BitOne{}: BitOne{}\n    case BitOne{} BitZero{}: BitOne{}\n    case BitOne{} BitOne{}: BitZero{}\ndef main() -> Bit:\n  xor(BitOne{}, BitZero{})\n',accepted:true,output:'BitOne{}'},
 {name:'joint-match-incomplete',source:bit+'def xor(left: Bit, right: Bit) -> Bit:\n  match left right:\n    case BitZero{} BitZero{}: BitZero{}\n    case BitZero{} BitOne{}: BitOne{}\n    case BitOne{} BitZero{}: BitOne{}\ndef main() -> Bit:\n  xor(BitOne{}, BitZero{})\n',accepted:false},
 {name:'nested-field-pattern',source:bit+'type Box is Type:\n  Box{value: Bit}\ntype Envelope is Type:\n  Envelope{box: Box}\ndef unwrap(x: Envelope) -> Bit:\n  match x:\n    case Envelope{Box{value}}: value\ndef main() -> Bit:\n  unwrap(Envelope{Box{BitOne{}}})\n',accepted:true,output:'BitOne{}'},
 {name:'partial-family-application',source:bit+'type Family<-A: Type, -B: Type> is Type:\n  FamilyCtr{left: A, right: B}\ndef partial(x: Bit) -> (@-B: Type -> Type):\n  Family(Bit)\ndef main() -> Bit:\n  BitOne{}\n',accepted:true,output:'BitOne{}'},
 {name:'checked-template-binder-guard',source:'def identity(~A: Type, x: A) -> A:\n  x\n',accepted:false,uncheckedGuard:true},
 {name:'checked-template-term-guard',source:bit+'def main() -> Bit:\n  ~BitOne{}\n',accepted:false,uncheckedGuard:true},
 // A datatype is a header, not code: native declares every family up front, so a
 // field, index or kind may name any family in the module. These pin the whole
 // mutual group, the forward index telescope and the CLay layout/form cycles.
 {name:'mutual-datatype-fields',source:'type A is Data:\n  MkA{f: B}\n  AEnd{}\ntype B is Data:\n  MkB{f: A}\n  BEnd{}\ndef main() -> A:\n  MkA{MkB{AEnd{}}}\n',accepted:true,output:'MkA{MkB{AEnd{}}}'},
 {name:'forward-index-datatype',source:'type B<X: A> is Data:\n  MkB{}\ntype A is Data:\n  MkA{}\ndef main() -> B<MkA{}>:\n  MkB{}\n',accepted:true,output:'MkB{}'},
 {name:'mutual-layout-arm-group',source:'type Layout is Data:\n  LayoutWord{}\n  LayoutData{arms: LayArm}\ntype LayArm is Data:\n  LayArm{fields: Layout}\ndef main() -> Layout:\n  LayoutData{LayArm{LayoutWord{}}}\n',accepted:true,output:'LayoutData{LayArm{LayoutWord{}}}'},
 {name:'mutual-form-nest-cycle',source:'type Nest is Data:\n  Nest{make: Fill}\ntype Fill is Data:\n  FillWord{}\n  FillForm{arms: FormArm}\ntype FormArm is Data:\n  FormArm{fields: Nest}\ndef main() -> Fill:\n  FillForm{FormArm{Nest{FillWord{}}}}\n',accepted:true,output:'FillForm{FormArm{Nest{FillWord{}}}}'},
 {name:'unknown-forward-datatype',source:'type A is Data:\n  MkA{f: B}\ndef main() -> A:\n  MkA{MkB{}}\n',accepted:false,failure:{beg:25,end:26,observed:'B'}},
 {name:'duplicate-datatype-header',source:'type A is Data:\n  MkA{}\n',second:'type A is Data:\n  MkA2{}\n',duplicateDeclaration:true,accepted:false},
 {name:'ill-kinded-forward-field',source:'type A is Data:\n  MkA{f: B}\ntype B is Type:\n  MkB{}\ndef main() -> A:\n  MkA{MkB{}}\n',accepted:false,failure:{beg:25,end:26}},
 // Original covered rows remain usage obligations even when checked occurrences
 // omit them. Keep these sources identical to the frozen G50 safety controls.
 {name:'covered-one',source:usagePair+'def choose(x: Bit, v: Bit) -> Pair:\n  match x:\n    case BitZero{}: Pair{BitZero{}, BitZero{}}\n    case BitOne{}: Pair{BitZero{}, BitZero{}}\n    case other: Pair{v, BitZero{}}\ndef main() -> Pair:\n  choose(BitZero{}, BitOne{})\n',accepted:true,output:'Pair{BitZero{}, BitZero{}}'},
 {name:'covered-many',source:usagePair+'def choose(x: Bit, +v: Bit) -> Pair:\n  match x:\n    case BitZero{}: Pair{BitZero{}, BitZero{}}\n    case BitOne{}: Pair{BitZero{}, BitZero{}}\n    case other: Pair{v, v}\ndef main() -> Pair:\n  choose(BitZero{}, BitOne{})\n',accepted:true,output:'Pair{BitZero{}, BitZero{}}'},
 {name:'covered-affine-duplicate',source:usagePair+'def choose(x: Bit, v: Bit) -> Pair:\n  match x:\n    case BitZero{}: Pair{BitZero{}, BitZero{}}\n    case BitOne{}: Pair{BitZero{}, BitZero{}}\n    case other: Pair{v, v}\n',accepted:false,failure:{beg:109,end:115}},
 {name:'covered-erased-use',source:usagePair+'def choose(x: Bit, -v: Bit) -> Pair:\n  match x:\n    case BitZero{}: Pair{BitZero{}, BitZero{}}\n    case BitOne{}: Pair{BitZero{}, BitZero{}}\n    case other: Pair{v, BitZero{}}\n',accepted:false,failure:{beg:110,end:116}},
 {name:'typed-local-reusable',source:usagePair+'def identity(x: Bit) -> Bit:\n  x\ndef main() -> Pair:\n  +value = identity(BitOne{})\n  Pair{value, value}\n',accepted:true,output:'Pair{BitOne{}, BitOne{}}'},
 {name:'typed-local-affine-duplicate',source:usagePair+'def identity(x: Bit) -> Bit:\n  x\ndef bad(x: Bit) -> Pair:\n  value = identity(x)\n  Pair{value, value}\n',accepted:false,failure:{beg:150,end:155}},
 {name:'typed-local-dependent-scope',source:usagePair+'def identity(-A: Type, x: A) -> A:\n  x\ndef local(-A: Type, x: A) -> A:\n  value = identity(A, x)\n  value\ndef main() -> Bit:\n  local(Bit, BitOne{})\n',accepted:true,output:'BitOne{}'},
 // Do not pin the incidental acceptance of duplicating an unchecked covered
 // local alias. The dummy is unused; direct outer-v use is the obligation here.
 {name:'covered-local-outer-affine',source:usagePair+'def choose(x: Bit, v: Bit) -> Pair:\n  match x:\n    case BitZero{}: Pair{BitZero{}, BitZero{}}\n    case BitOne{}: Pair{BitZero{}, BitZero{}}\n    case other:\n      dummy = BitZero{}\n      Pair{v, v}\n',accepted:false,failure:{beg:109,end:115}},
 {name:'covered-local-outer-erased',source:usagePair+'def choose(x: Bit, -v: Bit) -> Pair:\n  match x:\n    case BitZero{}: Pair{BitZero{}, BitZero{}}\n    case BitOne{}: Pair{BitZero{}, BitZero{}}\n    case other:\n      dummy = BitZero{}\n      Pair{v, BitZero{}}\n',accepted:false,failure:{beg:110,end:116}},
 // Curried source applications exercise head facts. An explicit annotation
 // rebuilds checked term handles, so the same obligations must survive fallback.
 {name:'usage-curried-single',source:usagePack+'def good(x: Bit) -> Pair:\n  pack(x)(BitZero{})\ndef main() -> Pair:\n  good(BitOne{})\n',accepted:true,output:'Pair{BitOne{}, BitZero{}}'},
 {name:'usage-curried-duplicate',source:usagePack+'def bad(x: Bit) -> Pair:\n  pack(x)(x)\n',accepted:false,failure:{beg:usagePack.length+8,end:usagePack.length+14}},
 {name:'usage-annotation-single',source:usagePack+'def good(x: Bit) -> Pair:\n  pack({x : Bit})(BitZero{})\ndef main() -> Pair:\n  good(BitOne{})\n',accepted:true,output:'Pair{BitOne{}, BitZero{}}'},
 {name:'usage-annotation-duplicate',source:usagePack+'def bad(x: Bit) -> Pair:\n  pack({x : Bit})(x)\n',accepted:false,failure:{beg:usagePack.length+8,end:usagePack.length+14}},
 // Local value facts belong to the outer scope; the body still uses the
 // original lexical environment and each instantiated formal's quantity.
 {name:'usage-local-function-single',source:usagePack+'def good(x: Bit) -> Pair:\n  fn = pack\n  fn(x, BitZero{})\ndef main() -> Pair:\n  good(BitOne{})\n',accepted:true,output:'Pair{BitOne{}, BitZero{}}'},
 {name:'usage-local-function-duplicate',source:usagePack+'def bad(x: Bit) -> Pair:\n  fn = pack\n  fn(x, x)\n',accepted:false,failure:{beg:usagePack.length+8,end:usagePack.length+14}},
 {name:'usage-local-function-erased',source:bit+'def ignore(-x: Bit) -> Bit:\n  BitZero{}\ndef good(-x: Bit) -> Bit:\n  fn = ignore\n  fn(x)\ndef main() -> Bit:\n  good(BitOne{})\n',accepted:true,output:'BitZero{}'},
 {name:'usage-local-function-dependent',source:usagePick+'def good(x: Bit) -> Bit:\n  fn = pick(Bit)\n  fn(x, x)\ndef main() -> Bit:\n  good(BitOne{})\n',accepted:true,output:'BitOne{}'},
 {name:'usage-local-function-dependent-live',source:usagePick+'def bad(-x: Bit) -> Bit:\n  fn = pick(Bit)\n  fn(x, x)\n',accepted:false,failure:{beg:usagePick.length+9,end:usagePick.length+15}},
 // Usage closes have distinct error order; source refinements and lexical local
 // quantities must survive before any FIR pruning or semantic substitution.
 {name:"usage-g55-lambda-error-before-usage",source:usagePair+"def bad() -> (Bit -> Pair):\n  value => Pair{value, {value : absent}}\n",accepted:false,failure:{beg:150,end:156}},
 {name:"usage-g55-lambda-body-mismatch-before-usage",source:usagePair+"def bad() -> (Bit -> Bit):\n  value => Pair{value, value}\n",accepted:false,failure:{beg:128,end:146}},
 {name:"usage-g55-pattern-usage-before-undefined",source:usagePair+"def bad(box: Pair) -> Pair:\n  match box:\n    case Pair{value, other}: Pair{{value : absent}, value}\n",accepted:false,failure:{beg:135,end:190}},
 {name:"usage-g55-pattern-branch-independent",source:usagePair+"def good(tag: Bit, value: Bit) -> Bit:\n  match tag:\n    case BitZero{}: value\n    case BitOne{}: value\ndef main() -> Bit:\n  good(BitZero{}, BitOne{})\n",accepted:true,output:"BitOne{}"},
 {name:"usage-g55-body-error-before-final-affinity",source:usagePair+"def bad(value: Bit) -> Pair:\n  Pair{value, {value : absent}}\n",accepted:false,failure:{beg:142,end:148}},
 {name:"usage-g55-erased-application-argument-plus-live",source:usagePair+"def ignore(-x: Bit) -> Bit:\n  BitZero{}\ndef good(value: Bit) -> Pair:\n  Pair{ignore(value), value}\ndef main() -> Pair:\n  good(BitOne{})\n",accepted:true,output:"Pair{BitZero{}, BitOne{}}"},
 {name:"usage-g55-erased-argument-still-typechecked",source:usagePair+"def ignore(-x: Bit) -> Bit:\n  BitZero{}\ndef bad(value: Bit) -> Bit:\n  ignore({value : absent})\n",accepted:false,failure:{beg:176,end:182}},
 {name:"usage-g55-erased-constructor-field-plus-live",source:usagePair+"type Ghost is Data:\n  Ghost{-hidden: Bit, live: Bit}\ndef good(value: Bit) -> Ghost:\n  Ghost{value, value}\ndef read(box: Ghost) -> Bit:\n  match box:\n    case Ghost{hidden, live}: live\ndef main() -> Bit:\n  read(good(BitOne{}))\n",accepted:true,output:"BitOne{}"},
 {name:"usage-g55-beta-ignored-argument",source:usagePair+"def good(value: Bit) -> Pair:\n  Pair{({x => BitZero{} : Bit -> Bit})(value), value}\n",accepted:false,failure:{beg:99,end:109}},
 {name:"usage-g55-early-local-undefined-after-duplicate-typed-value",source:usagePair+"def bad() -> Pair:\n  value = {BitZero{} : Bit}\n  Pair{value, {value : absent}}\n",accepted:false,failure:{beg:111,end:116}},
 {name:"usage-g55-early-local-undefined-before-duplicate-typed-value",source:usagePair+"def bad() -> Pair:\n  value = {BitZero{} : Bit}\n  Pair{{value : absent}, value}\n",accepted:false,failure:{beg:111,end:116}},
 {name:"usage-g55-early-local-erased-versus-body-error-typed-value",source:usagePair+"def bad() -> Pair:\n  -value = {BitZero{} : Bit}\n  Pair{value, {BitZero{} : absent}}\n",accepted:false,failure:{beg:111,end:117}},
 {name:"usage-g55-termination-before-final-duplicate-call",source:usagePair+"def combine(left: Bit, right: Bit) -> Bit:\n  left\ndef bad(value: Bit) -> Bit:\n  combine(bad(value), value)\n",accepted:false,failure:{beg:140,end:197}},
 {name:"usage-g55-source-lexical-erased-dependent-local-typed-flag",source:usagePair+"def choose_type(flag: Bit) -> Type:\n  match flag:\n    case BitZero{}: (@-x: Bit -> Bit)\n    case BitOne{}: (Bit -> Bit)\ndef make(flag: Bit) -> choose_type(flag):\n  match flag:\n    case BitZero{}: x => BitZero{}\n    case BitOne{}: x => x\ndef good(-x: Bit) -> Bit:\n  flag = {BitZero{} : Bit}\n  fn = make(flag)\n  fn(x)\ndef main() -> Bit:\n  good(BitOne{})\n",accepted:false,failure:{beg:337,end:343}},
 {name:"usage-g55-source-lexical-live-dependent-local-typed-flag",source:usagePair+"def choose_type(flag: Bit) -> Type:\n  match flag:\n    case BitZero{}: (@-x: Bit -> Bit)\n    case BitOne{}: (Bit -> Bit)\ndef make(flag: Bit) -> choose_type(flag):\n  match flag:\n    case BitZero{}: x => BitZero{}\n    case BitOne{}: x => x\ndef good(x: Bit) -> Bit:\n  flag = {BitZero{} : Bit}\n  fn = make(flag)\n  fn(x)\ndef main() -> Bit:\n  good(BitOne{})\n",accepted:true,output:"BitZero{}"},
 {name:"usage-g55-nested-alternative-max",source:usagePair+"def good(tag: Bit, other: Bit, value: Bit) -> Bit:\n  match tag:\n    case BitZero{}:\n      match other:\n        case BitZero{}: value\n        case BitOne{}: value\n    case BitOne{}: value\ndef main() -> Bit:\n  good(BitZero{}, BitOne{}, BitOne{})\n",accepted:true,output:"BitOne{}"},
 {name:"usage-g55-nested-alternative-one-bad-row",source:usagePair+"def bad(tag: Bit, other: Bit, value: Bit) -> Pair:\n  match tag:\n    case BitZero{}:\n      match other:\n        case BitZero{}: Pair{value, BitZero{}}\n        case BitOne{}: Pair{value, value}\n    case BitOne{}: Pair{value, BitZero{}}\n",accepted:false,failure:{beg:120,end:130}},
 {name:"usage-g55-local-shadowed-levels",source:usagePair+"def identity(x: Bit) -> Bit:\n  x\ndef good(x: Bit) -> Pair:\n  discarded = identity(x)\n  +x = identity(BitZero{})\n  Pair{x, x}\ndef main() -> Pair:\n  good(BitOne{})\n",accepted:true,output:"Pair{BitZero{}, BitZero{}}"},
 {name:"usage-g55-sequential-local-values-duplicate-outer",source:usagePair+"def identity(x: Bit) -> Bit:\n  x\ndef bad(x: Bit) -> Pair:\n  one = identity(x)\n  two = identity(x)\n  Pair{one, two}\n",accepted:false,failure:{beg:131,end:137}},
 // Typed do assignments exercise TermLet, whose usage check precedes even
 // initializer inference; this order differs from ordinary source locals.
 {name:"usage-g55-do-let-affine-single",source:usagePair+"def main() -> Pair:\n  do Pair<>:\n    value : Bit = BitOne{}\n    Pair{value, BitZero{}}\n",accepted:true,output:"Pair{BitOne{}, BitZero{}}"},
 {name:"usage-g55-do-let-quantity-before-value-error",source:usagePair+"def bad() -> Pair:\n  do Pair<>:\n    value : Bit = absent\n    Pair{value, value}\n",accepted:false,failure:{beg:126,end:170}},
 {name:"usage-g55-do-let-quantity-before-body-error",source:usagePair+"def bad() -> Pair:\n  do Pair<>:\n    value : Bit = BitOne{}\n    Pair{{value : absent}, value}\n",accepted:false,failure:{beg:126,end:183}},
 {name:"usage-g55-do-let-value-type-error",source:usagePair+"def bad() -> Pair:\n  do Pair<>:\n    value : Bit = absent\n    Pair{value, BitZero{}}\n",accepted:false,failure:{beg:140,end:146}},
 {name:"usage-g55-do-let-many",source:usagePair+"def main() -> Pair:\n  do Pair<>:\n    +value : Bit = BitOne{}\n    Pair{value, value}\n",accepted:true,output:"Pair{BitOne{}, BitOne{}}"},
];
const temporary=mkdtempSync(join(tmpdir(),'bend-checker-gate-')),sidecars=report+'.cases';mkdirSync(sidecars,{recursive:true});mkdirSync(dirname(report),{recursive:true});
const rows:any[]=[];
function save(){
 const runtime=resolve('evals/checker_core_step_runtime.mjs'),runtimeSha256=sha(runtime);
 const driverBoundary={runtime,runtimeSha256,orchestration:'trusted Node opaque native Run chunk loop',sharedInternalLoop:'runSteps',nativeTerminationProofIncludesDriver:false};
 writeFileSync(report,JSON.stringify({
  criterion:'Actual compiled parser -> native Bend checker steps driven by Node -> owning CheckedProgram -> native Bend JSEmit steps driven by Node -> execute returned emitted JS unchanged',
  additionalCriterion:'Strict emitter boundary refuses raw syntax; native checking then typed emission rejects parsed unexpanded template binders/terms with their actual source spans',
  datatypeHeaderCriterion:'Native datatypes are headers: a forward or mutual family field, index telescope or kind resolves before its declaration, while undefined names, duplicate headers, ill-kinded fields and non-declaration bodies are still rejected by their own categories',
  checkerDriver:{...driverBoundary,startExport:'check_expanded_start',stepExport:'checker_step',checkerLogic:'native-validated Bend steps and continuations'},
  emitterDriver:{...driverBoundary,startExport:'emit_modules_start',stepExport:'emitter_step',emitterLogic:'native-validated Bend steps and continuations'},
  proofBoundary:'Native validation covers checker and emitter Bend steps and their dependent continuations. Both Node opaque Run drivers use one shared trusted chunk loop and are outside the native termination proof.',
  parser,parserSha256:sha(parser),component:resolve(component!),componentSha256:sha(component!),
  limits:{memoryMiB:8192,rssMiB:8192,pollMs:10,workerStackMiB:256,parserFuel:2000000,maxHeavyChildren:1},
  finished:rows.length===fixtures.length,passed:rows.length===fixtures.length&&rows.every(row=>row.passed),rows,
 },null,2)+'\n');
}
save();
try{
 for(const fixture of fixtures){
  const request=join(temporary,fixture.name+'.json'),result=join(sidecars,fixture.name+'.json');
  writeFileSync(request,JSON.stringify({...fixture,file:join(temporary,fixture.name+'.bend'),parser,component:resolve(component)}));
  const guardian=await runHeavyGate(['node',resolve('evals/checker_core_target_worker.mjs'),request,result],{label:'Compiled CheckerCore target '+fixture.name,memoryMiB:8192,rssMiB:8192,pollMs:10});
  const row=existsSync(result)?JSON.parse(readFileSync(result,'utf8')):{passed:false,status:'NO_RESULT'};
  // A negative fixture pins the blamed source span, and its identity where the
  // missing or duplicated name is the point; never diagnostic prose. The worker
  // has already asserted the structured outcome for spliced duplicate modules.
  const failure=fixture.failure,diagnostic=row.diagnostic;
  const spanObserved=failure===undefined||(diagnostic?.span?.file===join(temporary,fixture.name+'.bend')&&diagnostic?.span?.beg===failure.beg&&diagnostic?.span?.end===failure.end);
  const identityObserved=failure?.observed===undefined||diagnostic?.observed===failure.observed;
  const structureObserved=spanObserved&&identityObserved;
  rows.push({...row,name:fixture.name,source:fixture.source,expectedAccepted:fixture.accepted,expectedOutput:fixture.output,expectedFailure:failure,structureObserved,guardian,passed:row.passed===true&&structureObserved&&guardian.status==='PASS'});save();console.log(JSON.stringify(rows.at(-1)));
 }
}finally{rmSync(temporary,{recursive:true,force:true});}
if(rows.some(row=>!row.passed))process.exitCode=2;
