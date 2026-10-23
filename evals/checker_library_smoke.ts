#!/usr/bin/env bun
/** Temporary real consumer smoke, not a compiler-root/bootstrap fixedpoint.
 * Build all nine diagnostic exports with checker_core_component_build.ts:
 * --file=checkpoints/template_checker_steps_driver_v1.bend
 * --exports=parsed_module,expand_modules_start,template_step,check_expanded_start,inspect_checked_start,checker_step,emit_modules_start,emit_library_start,emitter_step
 * Then: bun --smol evals/checker_library_smoke.ts --component=PATH.js
 * --component-build=PREFIX.result.json --report=FRESH.json
 * Required --parser=PATH.js --parser-build=PATH.native-build.result.json from a
 * fresh canonical schema3 producer; optional --component-provenance.
 */
import {runHeavyGate,guardHeavyGate} from './heavy_gate.ts';
import {sourceOracle} from './bootstrap_source_oracle.ts';
import {canonicalCore,normalizeCoreBook,normalizeImports} from './parser_full_semantic_normalize.ts';
import type {Node,Value} from './parser_full_semantic_normalize.ts';
import {decodeNativeAst,nativeAstValue,semanticHash} from './bootstrap_ast_transport.ts';
import {readAcceptedParserBuild} from './selfhost_driver_source.ts';
import {createHash} from 'node:crypto';
import {readFileSync,writeFileSync,existsSync,mkdirSync,realpathSync} from 'node:fs';
import {resolve,dirname,join} from 'node:path';
import {spawn} from 'node:child_process';
import type {ChildProcess} from 'node:child_process';
import {createInterface} from 'node:readline';

const ABI=['parsed_module','expand_modules_start','template_step','check_expanded_start','inspect_checked_start','checker_step','emit_modules_start','emit_library_start','emitter_step'];
const limits={memoryMiB:8192,rssMiB:8192,pollMs:10,workerStackMiB:256,parserFuel:2000000,maxHeavyChildren:1};
const sha=(bytes:string|Uint8Array)=>createHash('sha256').update(bytes).digest('hex');
const hash=(path:string)=>sha(readFileSync(path));
function object(value:unknown):Record<string,any>{
 if(!value||typeof value!=='object'||Array.isArray(value))throw Error('Expected report/protocol object');
 return value as Record<string,any>;
}
const json=(path:string)=>object(JSON.parse(readFileSync(path,'utf8')));
const save=(path:string,value:unknown)=>writeFileSync(path,JSON.stringify(value,(_,v)=>typeof v==='bigint'?String(v):v,2)+'\n');
function astNode(value:Value):Node{
 if(!value||typeof value!=='object'||Array.isArray(value)||typeof value.tag!=='string'||!Array.isArray(value.fields))throw Error('Expected full semantic AST constructor');
 return value;
}
function optionsOf(){
 const values=new Map<string,string>();let worker=false;
 for(const arg of process.argv.slice(2)){
  if(arg==='--worker'&&!worker){worker=true;continue;}
  const at=arg.indexOf('='),key=arg.slice(0,at),value=arg.slice(at+1);
  if(at<0||!['--component','--component-build','--report','--parser','--parser-build','--component-provenance'].includes(key)||!value||values.has(key))throw Error('Expected unique --option=value');
  values.set(key,value);
 }
 for(const key of ['--component','--component-build','--report','--parser','--parser-build'])if(!values.has(key))throw Error('Required '+key);
 const componentBuild=resolve(values.get('--component-build')!),parserBuild=resolve(values.get('--parser-build')!);
 return {worker,component:resolve(values.get('--component')!),componentBuild,componentProvenance:resolve(values.get('--component-provenance')??componentBuild.replace(/\.result\.json$/,'.provenance.json')),report:resolve(values.get('--report')!),parser:resolve(values.get('--parser')!),parserBuild};
}
function nativeBuild(path:string,artifact:string){
 const build=json(path),guardian=object(build.guardian);
 for(const key of ['eventsFullyValidated','checkedDefinitions'])if(!Number.isSafeInteger(build[key])||build[key]<=0)throw Error('Missing full native '+key);
 if(build.eventsFullyValidated<build.checkedDefinitions||build.status!=='JS_GENERATED_NOT_YET_EXECUTED'||build.checksExcluded!==0||build.outputPatches!==0||guardian.status!=='PASS'||typeof build.artifactPath!=='string'||realpathSync(build.artifactPath)!==realpathSync(artifact)||build.artifactSha256!==hash(artifact))throw Error('Incomplete or mismatched native build provenance: '+path);
 return {...build,guardian,buildReport:path,buildReportSha256:hash(path)};
}
const source=`type Bit is Data:
  BitZero{}
  BitOne{}
type Duo is Type:
  Duo{-ty: Type, left: Bit, -unused: Type, right: Bit}
def zero() -> Bit:
  BitZero{}
def one() -> Bit:
  BitOne{}
def pack(left: Bit, right: Bit) -> Duo:
  Duo{Bit, left, Bit, right}
def make_pack(left: Bit) -> (Bit -> Duo):
  right => pack(left, right)
def apply(f: Bit -> Duo, x: Bit) -> Duo:
  f(x)
def identity(a, -A: Kind(a), x: A) -> A:
  x
def identity_probe(x: Bit) -> Bit:
  identity(&2, Bit, x)
def ignore(-ghost: Bit, value: Bit) -> Bit:
  value
def erased_probe(f: Bit -> Bit, value: Bit) -> Bit:
  ignore(f(BitZero{}), value)
def specialize(~A: Type, x: A) -> A:
  x
def specialized_probe(x: Bit) -> Bit:
  specialize(~Bit, x)
def local_twice(action: Bit -> Bit, input: Bit) -> Duo:
  +value = action(input)
  pack(value, value)
def local_unused(action: Bit -> Bit, input: Bit) -> Bit:
  unused = action(input)
  BitZero{}
def local_order(first: Bit -> Bit, second: Bit -> Bit, left: Bit, right: Bit) -> Duo:
  a = first(left)
  b = second(right)
  pack(a, b)
def make_after(action: Bit -> Bit, input: Bit) -> (Bit -> Duo):
  value = action(input)
  rest => pack(value, rest)
def over_order(first: Bit -> Bit, second: Bit -> Bit, left: Bit, right: Bit) -> Duo:
  make_after(first, left)(second(right))
def over_generic(make: Bit -> (Bit -> Duo), argument: Bit -> Bit, left: Bit, right: Bit) -> Duo:
  make(left)(argument(right))
def constructor_match() -> (Bit -> Bit):
  \\{BitZero: BitOne{}; BitOne: BitZero{}; \\{}}
`;
const o=optionsOf(),sidecars=o.report+'.cases';
const root=resolve('checkpoints/template_checker_steps_driver_v1.bend');
const criterion='Smoke-only real library consumer: accepted compiled parsing with complete semantic AST parity, actual Template expansion, actual Checked.CheckSuccess.program and owner-preserving inspection, actual native JSEmit library steps, then positional ESM/curried/erased consumer behavior on the unchanged returned JS.';
const boundary={orchestration:'trusted Node native List packaging and shared LIFO continuation driver',nativeTerminationProofIncludesDriver:false,hostCheckingExpansionEmission:false,hostParserUse:'full semantic oracle only; never compiler inputs',bootstrapFixedpointClaim:false,fullCompilerRoot:false,libraryStartExport:'emit_library_start',sharedRuntimeStartSelection:'runLibraryEmitterSteps selects typed public start with explicit consumer exports',legacyIODriver:false,legacyCBackend:false};
mkdirSync(dirname(o.report),{recursive:true});
if(!o.worker){
 if(existsSync(o.report)||existsSync(sidecars))throw Error('Use a fresh report path; evidence is never overwritten');
 save(o.report,{status:'IN_PROGRESS',passed:false,compilerBootstrapGreen:false,selfhostGreen:false,smokeOnly:true,criterion,boundary,limits,requiredExports:ABI});
 const guardian=await runHeavyGate([process.execPath,'--smol',import.meta.path,...process.argv.slice(2),'--worker'],{label:'Actual checked ESM library consumer smoke',...limits});
 const result=json(o.report),passed=result.passed===true&&guardian.status==='PASS';
 save(o.report,{...result,guardian,passed,compilerBootstrapGreen:false,selfhostGreen:false,smokeOnly:true,status:passed?'LIBRARY_CONSUMER_SMOKE_PASS':guardian.status==='RESOURCE_LIMIT'?'RESOURCE_LIMIT':guardian.status==='LOCK_BUSY'?'LOCK_BUSY':'FAIL'});
 if(!passed)process.exitCode=2;
}else{
 await guardHeavyGate(import.meta.path,{label:'Actual checked ESM library consumer smoke'});
 mkdirSync(sidecars,{recursive:true});
 let phase='native-preflight',child:ChildProcess|undefined;
 const state:Record<string,any>={status:'IN_PROGRESS',passed:false,compilerBootstrapGreen:false,selfhostGreen:false,smokeOnly:true,criterion,boundary,limits,requiredExports:ABI,inputs:{},events:[],stages:[],parseRows:[]};
 const flush=()=>save(o.report,state);
 const failure=(error:unknown)=>{state.failure??={phase,error:String(error)};state.status='FAIL';state.passed=false;flush();};
 try{
  for(const path of [root,o.component,o.componentBuild,o.componentProvenance,o.parser,o.parserBuild,resolve('evals/selfhost_driver_source.ts'),import.meta.path,resolve('evals/checker_library_smoke_worker.mjs'),resolve('evals/checker_core_step_runtime.mjs'),resolve('evals/bootstrap_source_oracle.ts'),resolve('evals/bootstrap_ast_transport.ts'),resolve('evals/parser_full_semantic_normalize.ts')])state.inputs[path]=hash(path);
  const acceptedParser=readAcceptedParserBuild(o.parserBuild);
  const component=nativeBuild(o.componentBuild,o.component),parser=nativeBuild(acceptedParser.parserBuild,o.parser);
  for(const [path,digest]of Object.entries(acceptedParser.authenticatedInputs))state.inputs[path]=digest;
  state.inputs[acceptedParser.provenancePath]=hash(acceptedParser.provenancePath);
  if(typeof component.sourcePath!=='string'||realpathSync(component.sourcePath)!==realpathSync(root)||component.sourceSha256!==hash(root)||!Array.isArray(component.exports)||component.exports.length!==ABI.length||!ABI.every(name=>component.exports.includes(name))||!Number.isSafeInteger(component.liveBodies)||component.liveBodies<=0||component.checkedDefinitions<component.liveBodies)throw Error('Component must validate all bodies of this exact nine-export diagnostic root');
  const provenance=json(o.componentProvenance),{provenanceSha256,...payload}=provenance;
  if(provenanceSha256!==component.provenanceSha256||sha(JSON.stringify(payload))!==provenanceSha256||provenance.schemaVersion!==4||provenance.sourceSha256!==component.sourceSha256||provenance.checksExcluded!==0||provenance.outputPatches!==0)throw Error('Component complete-source provenance mismatch');
  const componentProducerPins=object(provenance.protectedPins);
  for(const [field,path]of [['compiler',resolve('bend2/comp.ts')],['kernel',resolve('bend2/bend.ts')]]){
   if(typeof provenance[field+'Path']!=='string'||realpathSync(provenance[field+'Path'])!==realpathSync(path)||provenance[field+'Sha256']!==hash(path)||componentProducerPins[realpathSync(path)]!==hash(path))throw Error('Fresh smoke component producer identity mismatch: '+field);
  }
  const lifetime=object(provenance.kernelObservation),bodies=provenance.checkedDefinitions;
  if(lifetime.kernelUnmodified!==true||lifetime.sourceValueReplacement!==false||lifetime.parserSubstitutions!==0
    ||provenance.loadMode!=='CANONICAL_NATIVE_UNMODIFIED'||provenance.checkedOutputRetention!=='native e'||component.checkedOutputRetention!=='native e')throw Error('Native kernel or checked output contract changed');
  if(!Number.isSafeInteger(bodies)||bodies<=0)throw Error('Missing native checked bodies');
  for(const field of ['checkedDefinitions','nativeCheckedBodies','expectedSourceDefinitions'])if(provenance[field]!==bodies||component[field]!==bodies)throw Error('Incomplete smoke native checked-body coverage: '+field);
  const loadedInputs=object(provenance.loadedInputs);
  if(!Object.keys(loadedInputs).length||!Object.entries(loadedInputs).some(([path,pin])=>realpathSync(path)===realpathSync(root)&&pin===hash(root)))throw Error('Native source closure omits diagnostic root');
  for(const [path,pin]of Object.entries(loadedInputs)){
   if(typeof pin!=='string'||hash(path)!==pin)throw Error('Native-validated source closure drift: '+path);
   state.inputs[path]=pin;
  }
  state.inputs[acceptedParser.parserSource]=hash(acceptedParser.parserSource);
  state.native={component,parser,componentProvenance:{path:o.componentProvenance,sha256:hash(o.componentProvenance),provenanceSha256,loadedInputs},allComponentBodiesValidated:true,checksExcluded:0,outputPatches:0};
  const file=join(sidecars,'library-consumer.bend');writeFileSync(file,source,{flag:'wx'});
  state.source={file:realpathSync(file),sha256:sha(source),bytes:Buffer.byteLength(source),text:source,imports:[]};state.inputs[file]=hash(file);flush();
  const request=join(sidecars,'request.json');save(request,{component:o.component,parser:o.parser,sidecars,file:state.source.file,sourceSha256:sha(source)});
  child=spawn('node',[resolve('evals/checker_library_smoke_worker.mjs'),request],{stdio:['pipe','pipe','inherit']});
  const completed=new Promise<number>((done,reject)=>{child!.once('error',reject);child!.once('close',code=>done(code??125));});
  for await(const line of createInterface({input:child.stdout!})){
   const message=object(JSON.parse(line));if(typeof message.phase==='string')phase=message.phase;
   if(message.event==='parse'){
    if(message.file!==state.source.file||message.sourceSha256!==sha(source)||message.parserSha256!==hash(o.parser)||typeof message.transport!=='string')throw Error('Compiled parse does not match authenticated smoke inputs');
    const oracle=await sourceOracle(message.file,source,{preloadBase:false});
    if(!oracle.accepted)throw Error('Full semantic source oracle failed: '+String(oracle.error)+'; '+JSON.stringify(oracle.failure));
    if(oracle.imports.length!==0)throw Error('Smoke program unexpectedly imports other modules');
    const environment=oracle.normalizationBook();
    const stage0ASTHash=semanticHash(normalizeCoreBook(environment,oracle.declarations.map(d=>d.key),[],message.file,dirname(message.file)+'/').semantic);
    const parsed=decodeNativeAst(readFileSync(message.transport,'utf8'));
    if(!parsed||typeof parsed!=='object'||Array.isArray(parsed)||!('module'in parsed))throw Error('Expected complete transported ParseSuccess module');
    const module=astNode(nativeAstValue(parsed.module));
    if(!Array.isArray(module.fields[1]))throw Error('Expected full AST imports');
    const imports=module.fields[1].map(astNode),actual=canonicalCore(module,environment,source).semantic;
    actual.imports=normalizeImports(imports.map(v=>{if(typeof v.fields[0]!=='string'||typeof v.fields[1]!=='string')throw Error('Malformed AST import');return {path:v.fields[0],alias:v.fields[1]};}));
    const compiledASTHash=semanticHash(actual);
    const row={file:message.file,sourceSha256:message.sourceSha256,parserSha256:message.parserSha256,transport:message.transport,transportSha256:hash(message.transport),stage0ASTHash,compiledASTHash,semanticParity:stage0ASTHash===compiledASTHash,fullSemanticFields:true,normalizationLedger:{observation:oracle.observation,exclusions:oracle.exclusions},declarations:oracle.declarations.length};
    state.parseRows.push(row);flush();
    if(!row.semanticParity)throw Error('Complete semantic AST mismatch');
    child.stdin!.write(JSON.stringify({approved:true})+'\n');Bun.gc(true);
   }else if(message.event==='stage'){state.stages.push(message);flush();}
   else if(message.event==='artifact'){if(typeof message.path!=='string'||message.sha256!==hash(message.path)||message.outputPatches!==0)throw Error('Returned emitted library artifact mismatch');state.artifact=message;flush();}
   else if(message.event==='result'){
    const result=object(message.result);
    if(result.passed!==true&&result.passed!==false)throw Error('Malformed smoke result');
    Object.assign(state,result);flush();
   }else{state.events.push(message);flush();}
  }
  const exit=await completed;
  if(exit!==0||state.passed!==true||state.failure||state.parseRows.length!==1||!state.parseRows[0].semanticParity||state.stages.length!==2||state.stages[0].result!=='ExpandSuccess'||state.stages[1].result!=='CheckSuccess'||!state.artifact||!state.runtime?.artifactExecutedUnchanged)throw Error('Consumer smoke did not establish all required native/parity/runtime evidence');
  for(const stage of state.stages)if(hash(stage.transport.path)!==stage.transport.sha256)throw Error('Native stage transport changed');
  if(hash(state.artifact.path)!==state.artifact.sha256)throw Error('Consumer artifact changed');
  for(const [path,pin]of Object.entries(state.inputs))if(hash(path)!==pin)throw Error('Protected input changed: '+path);
  state.status='LIBRARY_CONSUMER_SMOKE_PASS';state.compilerBootstrapGreen=false;state.selfhostGreen=false;flush();
 }catch(error){failure(error);child?.kill('SIGTERM');process.exitCode=2;}
}
