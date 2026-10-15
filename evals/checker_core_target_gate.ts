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
 {name:'single-enum-match-repeated-constructor',source:bit+'def flip(x: Bit) -> Bit:\n  match x:\n    case BitZero{}: BitOne{}\n    case BitZero{}: BitOne{}\n    case BitOne{}: BitZero{}\ndef main() -> Bit:\n  flip(BitZero{})\n',accepted:false},
 {name:'joint-match-complete',source:bit+'def xor(left: Bit, right: Bit) -> Bit:\n  match left right:\n    case BitZero{} BitZero{}: BitZero{}\n    case BitZero{} BitOne{}: BitOne{}\n    case BitOne{} BitZero{}: BitOne{}\n    case BitOne{} BitOne{}: BitZero{}\ndef main() -> Bit:\n  xor(BitOne{}, BitZero{})\n',accepted:true,output:'BitOne{}'},
 {name:'joint-match-incomplete',source:bit+'def xor(left: Bit, right: Bit) -> Bit:\n  match left right:\n    case BitZero{} BitZero{}: BitZero{}\n    case BitZero{} BitOne{}: BitOne{}\n    case BitOne{} BitZero{}: BitOne{}\ndef main() -> Bit:\n  xor(BitOne{}, BitZero{})\n',accepted:false},
 {name:'nested-field-pattern',source:bit+'type Box is Type:\n  Box{value: Bit}\ntype Envelope is Type:\n  Envelope{box: Box}\ndef unwrap(x: Envelope) -> Bit:\n  match x:\n    case Envelope{Box{value}}: value\ndef main() -> Bit:\n  unwrap(Envelope{Box{BitOne{}}})\n',accepted:true,output:'BitOne{}'},
 {name:'partial-family-application',source:bit+'type Family<-A: Type, -B: Type> is Type:\n  FamilyCtr{left: A, right: B}\ndef partial(x: Bit) -> (@-B: Type -> Type):\n  Family(Bit)\ndef main() -> Bit:\n  BitOne{}\n',accepted:true,output:'BitOne{}'},
 {name:'emitter-template-binder-guard',source:'def identity(~A: Type, x: A) -> A:\n  x\n',accepted:false,emitterGuard:true},
 {name:'emitter-template-term-guard',source:bit+'def main() -> Bit:\n  ~BitOne{}\n',accepted:false,emitterGuard:true},
];
const temporary=mkdtempSync(join(tmpdir(),'bend-checker-gate-')),sidecars=report+'.cases';mkdirSync(sidecars,{recursive:true});mkdirSync(dirname(report),{recursive:true});
const rows:any[]=[];
function save(){
 const runtime=resolve('evals/checker_core_step_runtime.mjs'),runtimeSha256=sha(runtime);
 const driverBoundary={runtime,runtimeSha256,orchestration:'trusted Node LIFO continuation loop',sharedInternalLoop:'runSteps',nativeTerminationProofIncludesDriver:false};
 writeFileSync(report,JSON.stringify({
  criterion:'Actual compiled parser -> native Bend checker steps driven by Node -> template-free checked modules -> native Bend JSEmit steps driven by Node -> execute returned emitted JS unchanged',
  additionalCriterion:'Direct native emission rejects parsed unexpanded template binders/terms with their actual source spans; these guards intentionally skip the template-free checker entrypoint',
  checkerDriver:{...driverBoundary,startExport:'check_expanded_start',stepExport:'checker_step',checkerLogic:'native-validated Bend steps and continuations'},
  emitterDriver:{...driverBoundary,startExport:'emit_modules_start',stepExport:'emitter_step',emitterLogic:'native-validated Bend steps and continuations'},
  proofBoundary:'Native validation covers checker and emitter Bend steps and their dependent continuations. Both Node request/continuation drivers use one shared trusted LIFO loop and are outside the native termination proof.',
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
  rows.push({...row,name:fixture.name,source:fixture.source,expectedAccepted:fixture.accepted,expectedOutput:fixture.output,guardian,passed:row.passed===true&&guardian.status==='PASS'});save();console.log(JSON.stringify(rows.at(-1)));
 }
}finally{rmSync(temporary,{recursive:true,force:true});}
if(rows.some(row=>!row.passed))process.exitCode=2;
