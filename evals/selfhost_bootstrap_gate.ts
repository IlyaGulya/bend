#!/usr/bin/env bun
/** PURE step-component bootstrap (not the legacy IO/C driver).
 * bun --smol evals/selfhost_bootstrap_gate.ts --component=PATH.js
 *   --component-build=PATH.result.json --root=PATH.bend
 *   --root-manifest=PATH.json --report=PATH.json
 * Required --parser=PATH.js --parser-build=PATH.native-build.result.json.
 * The parser and native component carry schema4 full-validation/input-closure
 * proofs from the unmodified canonical kernel and export the complete ABI below.
 * Native checked bodies stay in memory until their final emission; stages consume
 * only fresh parser ASTs. Both stage images are actual, unchanged JSEmit results.
 * Optional SELFHOST_CPU_PROFILE_DIR profiles fresh parser-oracle processes;
 * each parser-oracle-* directory records its exact source/phase receipt,
 * CPU/wall/boundary-memory summary and command/exit evidence. Profiling does
 * not turn fixture/cache or parse-only diagnostics into bootstrap acceptance.
 */
import {runHeavyGate,guardHeavyGate} from './heavy_gate.ts';
import {authenticateNativeSeedBuild} from './native_seed_runtime.mjs';
import {parserParity,isolatedParserParity} from './selfhost_parser_parity.ts';
import {decodeNativeAst} from './bootstrap_ast_transport.ts';
import {readAcceptedParserBuild} from './selfhost_driver_source.ts';
import {createHash} from 'node:crypto';
import {readFileSync,writeFileSync,existsSync,mkdirSync,realpathSync,copyFileSync} from 'node:fs';
import {resolve,dirname,join,relative} from 'node:path';
import {spawn} from 'node:child_process';
import type {ChildProcess} from 'node:child_process';
import {createInterface} from 'node:readline';

const ABI=['parsed_module','parse_with_fuel','expand_modules_start','template_step','check_expanded_start','inspect_checked_start','checker_step','emit_modules_start','emit_library_start','emitter_step','emit_c_modules_start','emit_c_library_start','c_emitter_step'];
const limits={memoryMiB:8192,rssMiB:8192,pollMs:10,workerStackMiB:256,workerOldGenerationMiB:6144,workerYoungGenerationMiB:128,parserFuel:8000000,maxHeavyChildren:1};
const sha=(bytes:string|Uint8Array)=>createHash('sha256').update(bytes).digest('hex');
const hash=(path:string)=>sha(readFileSync(path));
function object(value:unknown):Record<string,unknown>{
 if(!value||typeof value!=='object'||Array.isArray(value))throw Error('Expected report/protocol object');
 return value as Record<string,unknown>;
}
const json=(path:string)=>object(JSON.parse(readFileSync(path,'utf8')));
function buildReport(path:string){
 const value=json(path),guardian=object(value.guardian);
 for(const key of ['eventsFullyValidated','checkedDefinitions'])if(typeof value[key]!=='number'||!Number.isSafeInteger(value[key])||value[key]<=0)throw Error('Missing full native '+key);
 for(const key of ['artifactPath','artifactSha256'])if(typeof value[key]!=='string')throw Error('Missing native '+key);
 return {...value,checksExcluded:value.checksExcluded,outputPatches:value.outputPatches,guardianStatus:guardian.status,artifactPath:value.artifactPath as string,artifactSha256:value.artifactSha256 as string,sourcePath:value.sourcePath,sourceSha256:value.sourceSha256,exports:Array.isArray(value.exports)?value.exports:[]};
}
const save=(path:string,value:unknown)=>writeFileSync(path,JSON.stringify(value,(_,v)=>typeof v==='bigint'?String(v):v,2)+'\n');
function argumentsOf(){
 const options=new Map<string,string>();let worker=false;
 for(const argument of process.argv.slice(2)){
  if(argument==='--worker'&&!worker){worker=true;continue;}
  const at=argument.indexOf('='),key=argument.slice(0,at),value=argument.slice(at+1);
  if(at<0||!['--component','--component-build','--native-build','--native-corpus','--root','--root-manifest','--report','--parser','--parser-build','--fixture','--parse-only','--profile-root'].includes(key)||!value||options.has(key))throw Error('Expected unique --option=value');
  options.set(key,value);
 }
 const native=options.has('--native-build')||options.has('--native-corpus');
 if(native&&!(options.has('--native-build')&&options.has('--native-corpus')))throw Error('Native seed mode requires both --native-build and --native-corpus');
 if(native&&(options.has('--component')||options.has('--component-build')))throw Error('Native seed mode takes no JS component build');
 for(const key of [...(native?['--native-build','--native-corpus']:['--component','--component-build']),'--root','--report','--parser','--parser-build',...(!options.has('--fixture')?['--root-manifest']:[])])if(!options.has(key))throw Error('Required '+key);
 if(options.has('--parse-only')&&(options.get('--parse-only')!=='true'||options.has('--fixture')))throw Error('--parse-only=true requires the full root, not a fixture');
 if(options.has('--profile-root')&&(options.get('--profile-root')!=='true'||options.has('--fixture')||options.has('--parse-only')||!process.env.SELFHOST_CPU_PROFILE_DIR))throw Error('--profile-root=true requires the full root and SELFHOST_CPU_PROFILE_DIR, without fixture/parse-only modes');
 const parserBuild=resolve(options.get('--parser-build')!);
 return {worker,component:options.has('--component')?resolve(options.get('--component')!):undefined,componentBuild:options.has('--component-build')?resolve(options.get('--component-build')!):undefined,nativeBuild:options.has('--native-build')?resolve(options.get('--native-build')!):undefined,nativeCorpus:options.has('--native-corpus')?resolve(options.get('--native-corpus')!):undefined,root:resolve(options.get('--root')!),rootManifest:options.has('--root-manifest')?resolve(options.get('--root-manifest')!):undefined,report:resolve(options.get('--report')!),parser:resolve(options.get('--parser')!),parserBuild,fixture:options.get('--fixture'),parseOnly:options.has('--parse-only'),profileRoot:options.has('--profile-root')};
}
const o=argumentsOf(),sidecars=o.report+'.cases';mkdirSync(dirname(o.report),{recursive:true});
// Persistent inputs/results exist only for --fixture diagnostics. Full compiler
// bootstrap always creates fresh sources and executes every parser/oracle.
const diagnosticCache=o.fixture?join(dirname(o.report),'.bootstrap-diagnostic-cache-v1'):undefined;
const requiredExports=o.fixture?ABI.filter(name=>name!=='parse_with_fuel'&&name!=='emit_library_start'):ABI;
const criterion=o.nativeBuild?'Accepted native parser + full natively checked compiler root built by the unchanged canonical kernel/compiler under the original native build policy; native stage0 parses/checks/emits real stage-one JS from the exact same root and executes the original seed fixtures; stage one uses its own parser and steps to emit stage two; require byte-identical JS and full semantic AST oracle parity.':o.profileRoot?'Diagnostic fresh full compiler-root parsing, complete semantic oracle parity, original approved parser AST reuse, expansion, full checking, actual library emission and unchanged stage-one library import; no fixture-suite or stage-two/fixedpoint acceptance.':o.parseOnly?'Diagnostic fresh full compiler-root parsing, complete semantic oracle parity and original approved parser AST reuse; no checking, emission, stage execution or fixedpoint acceptance.':o.fixture?'Diagnostic single Template fixture: accepted compiled parsing and full AST parity (fresh or exact authenticated diagnostic reuse), expansion, checking and execution; no bootstrap/fixedpoint claim.':'Accepted native parser + native-validated Template/Checker/JSEmit steps emit full parser-and-step compiler source as stage one; execute its unchanged library, use its own parser and steps to emit stage two from identical Bend sources; require the full native validated closure, byte-identical JS (the JS byte fixed point) and full semantic AST oracle parity, then execute stage-two specialization/failure fixtures. C emission is not exercised by this lane: C behaviour is established only by the separate authenticated C fixture rows, never by declared exports here.';
const nativeBoundary=o.nativeBuild?{host:'trusted C file/import loader and serial opaque native Run chunk driver',sourceAlgorithms:'unchanged canonical Bend parser/expansion/checker/JS library emitter compiled by the canonical kernel/compiler',hostChecking:false,hostParsing:false,embeddedSource:false,cachedAst:false,seed:'native stage0 executable built from this exact root',stageTwoParser:'stage-one emitted parse_with_fuel, never the seed parser',outputPatches:0,checksExcluded:0}:undefined;
// legacyCBackend means "the legacy AST C backend is not in use". The current C
// seam (c_emit_steps over checked FIR) is a new backend, so this field stays
// false and the C surface is reported separately below, from observed evidence.
const boundary=nativeBoundary??{orchestration:'trusted host file loading/import resolution and shared Node opaque native Run chunk driver',nativeTerminationProofIncludesDriver:false,hostCheckingExpansionEmission:false,hostParserUse:'full semantic AST oracle only; never compiler inputs',compilerAstInput:'Original immutable parser result after complete transport validation and full native semantic/span parity approval; transport rehashed before use',nativeCheckedBodies:'seed-native component retains original checked e in memory; never inputs to Bend bootstrap stages',legacyIODriver:false,legacyCBackend:false,legacyCBackendMeans:'legacy AST C backend not used; the new c_emit seam is not legacy and does not set this flag'};
if(!o.worker){
 if(existsSync(o.report)||existsSync(sidecars))throw Error('Use a fresh report path; bootstrap evidence is never overwritten');
 save(o.report,{status:'IN_PROGRESS',passed:false,selfhostGreen:false,criterion,boundary,limits,root:o.root,requiredExports});
 const guardian=await runHeavyGate([process.execPath,'--smol',import.meta.path,...process.argv.slice(2),'--worker'],{label:'Real full selfhost step bootstrap',...limits});
 const result=existsSync(o.report)?json(o.report):{};
 const diagnosticComplete=(o.parseOnly||o.profileRoot)&&result.diagnosticPhaseComplete===true&&guardian.status==='PASS';
 const passed=!o.parseOnly&&!o.profileRoot&&result.passed===true&&guardian.status==='PASS';
 // Observed, not declared: the root text is read back and the C surface is
 // reported separately from whether any C emission actually ran in this lane.
 const observedRoot=existsSync(o.root)?readFileSync(o.root,'utf8'):'';
 const cSurface={
  exportsRequired:requiredExports.filter(name=>name.startsWith('emit_c_')||name==='c_emitter_step'),
  seamImported:observedRoot.includes('import ./c_emit_steps_v1.bend as CEmit'),
  wrappersPresent:['emit_c_modules_start','emit_c_library_start','c_emitter_step'].filter(name=>observedRoot.includes('def '+name+'(')),
  emissionExercised:typeof result.cEmissionRows==='number'&&result.cEmissionRows>0,
  scope:'observed from the root text only: the declared C surface and the seam import. This lane runs no C emission, so it makes no C behaviour claim; C behaviour is established by the separate authenticated C fixture rows.'};
 save(o.report,{...result,guardian,cSurface,passed,diagnosticOnly:!!o.parseOnly||!!o.fixture||o.profileRoot,bootstrapAcceptance:!o.parseOnly&&!o.fixture&&!o.profileRoot,compilerBootstrapGreen:passed&&!o.fixture,selfhostGreen:false,broaderSelfhostGreen:'Not established: legacy IO/C driver and product-wide backend/differential gates are outside this compiler-root acceptance',status:diagnosticComplete?(o.profileRoot?'ROOT_COMPILER_PROFILE_PASS':'ROOT_PARSE_DIAGNOSTIC_PASS'):passed?(o.fixture?'TEMPLATE_FIXTURE_PASS':o.nativeBuild?'NATIVE_SEED_BOOTSTRAP_FIXEDPOINT':'PURE_STEP_BOOTSTRAP_FIXEDPOINT'):guardian.status==='RESOURCE_LIMIT'?'RESOURCE_LIMIT':guardian.status==='LOCK_BUSY'?'LOCK_BUSY':'FAIL'});
 if(!passed&&!diagnosticComplete)process.exitCode=2;
}else{
 await guardHeavyGate(import.meta.path,{label:'Real full selfhost step bootstrap'});
 mkdirSync(sidecars,{recursive:true});
 const events:Record<string,unknown>[]=[],parseRows:Record<string,unknown>[]=[],fixtureRows:Record<string,unknown>[]=[];
 let phase='prerequisites',child:ChildProcess|undefined;
 const state:{[key:string]:unknown;passed:boolean;selfhostGreen:boolean;status:string;inputs:Record<string,string>;artifacts:Record<string,unknown>;failure?:Record<string,unknown>}={status:'IN_PROGRESS',passed:false,selfhostGreen:false,criterion,boundary,limits,root:o.root,requiredExports,events,parseRows,fixtureRows,artifacts:{},inputs:{}};
 const flush=()=>save(o.report,state);
 const fail=(error:unknown,details:Record<string,unknown>={})=>{state.failure??={phase,error:String(error),...details};state.status='FAIL';flush();};
 try{
  state.inputs=Object.fromEntries([o.root,...(o.rootManifest?[o.rootManifest]:[]),...(o.component?[o.component]:[]),...(o.componentBuild?[o.componentBuild]:[]),...(o.nativeBuild?[o.nativeBuild,o.nativeCorpus!]:[]),o.parser,o.parserBuild,resolve('evals/selfhost_driver_source.ts'),resolve('evals/checker_core_step_runtime.mjs'),resolve('evals/bootstrap_source_oracle.ts'),resolve('evals/bootstrap_ast_transport.ts'),resolve('evals/parser_full_semantic_normalize.ts'),resolve('evals/selfhost_parser_parity.ts'),resolve('evals/native_seed_runtime.mjs'),import.meta.path,resolve('evals/selfhost_bootstrap_worker.mjs'),resolve('evals/selfhost_cpu_profile.mjs')].map(path=>[path,hash(path)]));flush();
  const acceptedParser=readAcceptedParserBuild(o.parserBuild);
  const parserBuild=buildReport(acceptedParser.parserBuild);
  let protectedPins:Record<string,any>,loadedInputs:Record<string,any>;
  if(o.nativeBuild){
   const nativeSeed=authenticateNativeSeedBuild(o.nativeBuild,{root:realpathSync(o.root),corpusPath:o.nativeCorpus!,limits});
   protectedPins=nativeSeed.protectedPins;loadedInputs=nativeSeed.loadedInputs;
   for(const [path,digest]of Object.entries(protectedPins))state.inputs[path]=String(digest);
   for(const [path,digest]of Object.entries(loadedInputs))state.inputs[path]=String(digest);
   for(const path of ['evals/heavy_gate.ts','evals/heavy_gate_native.c'])if(protectedPins[realpathSync(path)]!==hash(path))throw Error('Missing native stage0 guardian identity');
   // The native build loads the bridge, the accepted parser and the whole root
   // in one canonical book; every workload source must be in that exact closure.
   for(const row of nativeSeed.corpus.files){
    const real=realpathSync(resolve(nativeSeed.corpus.directory,row.path));
    if(loadedInputs[real]!==row.sha256)throw Error('Native stage0 did not validate the actual workload bytes: '+real);
   }
   state.nativeSeed={build:o.nativeBuild,buildSha256:hash(o.nativeBuild),binary:nativeSeed.binary,binarySha256:nativeSeed.binarySha256,
    corpus:nativeSeed.corpusPath,corpusSha256:nativeSeed.corpusSha256,checkedDefinitions:nativeSeed.report.checkedDefinitions,
    expectedSourceDefinitions:nativeSeed.report.expectedSourceDefinitions,eventsFullyValidated:nativeSeed.report.eventsFullyValidated,
    cPath:nativeSeed.report.cPath,cSha256:nativeSeed.report.cSha256,guardian:nativeSeed.report.guardian};
   state.nativeSeedInputs=Object.fromEntries(nativeSeed.corpus.files.map((row:any)=>[resolve(nativeSeed.corpus.directory,row.path),row.sha256]));
   const backendIr=realpathSync(resolve('bend2/selfhost/backend_ir.bend'));
   const sourceFileRow=nativeSeed.corpus.files.find((row:any)=>row.external!==true&&typeof row.path==='string'&&realpathSync(resolve(nativeSeed.corpus.directory,row.path))===backendIr);
   if(!sourceFileRow||typeof sourceFileRow.namespace!=='string')throw Error('Native workload does not load the canonical BIR module');
   state.nativeSourceFileTag=sourceFileRow.namespace+'.SourceFile';
  }else{
  // Provenance: the JS seed component is produced by the official compiler,
  // which keeps the BIR module in the root namespace, so its carrier is bare.
  state.sourceFileTag='SourceFile';
  const componentBuild=buildReport(o.componentBuild!);
  for(const [name,build,artifact]of [['component',componentBuild,o.component!],['parser',parserBuild,o.parser]] as const){
   if(build.checksExcluded!==0||build.guardianStatus!=='PASS'||build.artifactSha256!==hash(artifact)||realpathSync(build.artifactPath)!==realpathSync(artifact))throw Error(name+' lacks exact complete native build provenance');
  }
  for(const [path,digest]of Object.entries(acceptedParser.authenticatedInputs)){
   state.inputs[path]=digest;
  }
  state.inputs[acceptedParser.provenancePath]=hash(acceptedParser.provenancePath);
  if(componentBuild.outputPatches!==0||typeof componentBuild.sourcePath!=='string'||realpathSync(componentBuild.sourcePath)!==realpathSync(o.root)||componentBuild.sourceSha256!==hash(o.root)||!requiredExports.every(name=>componentBuild.exports.includes(name)))throw Error('Native component must validate this exact root and its complete required ABI');
  // Authenticate the builder that actually emitted this component, not a
  // historical compiler pin or the current hash substituted into old evidence.
  if(componentBuild.status!=='JS_GENERATED_NOT_YET_EXECUTED'||typeof componentBuild.provenancePath!=='string'||typeof componentBuild.provenanceSha256!=='string')throw Error('Missing canonical component builder proof');
  const provenancePath=realpathSync(componentBuild.provenancePath),record=json(provenancePath);
  const {provenanceSha256,...provenance}=record;
  if(provenance.schemaVersion!==4||provenanceSha256!==componentBuild.provenanceSha256||sha(JSON.stringify(provenance))!==provenanceSha256)throw Error('Canonical builder provenance hash/version mismatch');
  protectedPins=object(provenance.protectedPins);loadedInputs=object(provenance.loadedInputs);
  const runtime=object(provenance.runtime),guard=object(provenance.guard);
  for(const [field,path]of [['compilerPath',resolve('bend2/comp.ts')],['kernelPath',resolve('bend2/bend.ts')],['runnerPath',resolve('evals/checker_core_component_build.ts')]] as const){
   const digest=provenance[field.replace('Path','Sha256')];
   if(typeof provenance[field]!=='string'||realpathSync(provenance[field] as string)!==realpathSync(path)||digest!==hash(path)||protectedPins[realpathSync(path)]!==digest)throw Error('Canonical builder identity mismatch: '+field);
  }
  if(provenance.checksExcluded!==0||provenance.outputPatches!==0||provenance.sourcePath!==componentBuild.sourcePath||provenance.sourceSha256!==componentBuild.sourceSha256||JSON.stringify(provenance.exports)!==JSON.stringify(componentBuild.exports)
   ||runtime.name!=='node'||runtime.manualGC!==false||guard.memoryMiB!==limits.memoryMiB||guard.rssMiB!==limits.rssMiB||guard.pollMs!==limits.pollMs)throw Error('Canonical builder acceptance contract changed');
  const nativeLifetime=object(provenance.kernelObservation);
  if(nativeLifetime.kernelUnmodified!==true||nativeLifetime.sourceValueReplacement!==false||nativeLifetime.parserSubstitutions!==0
   ||provenance.loadMode!=='CANONICAL_NATIVE_UNMODIFIED'||provenance.checkedOutputRetention!=='native e'||componentBuild.checkedOutputRetention!=='native e')throw Error('Native kernel or checked output contract changed');
  const buildRuntime=object(componentBuild.runtime),componentGuardian=object(componentBuild.guardian),bodies=provenance.checkedDefinitions;
  if(!Number.isSafeInteger(bodies)||Number(bodies)<=0)throw Error('Missing native checked bodies');
  for(const field of ['checkedDefinitions','nativeCheckedBodies','expectedSourceDefinitions']){
   if(provenance[field]!==bodies||componentBuild[field]!==bodies)throw Error('Native validation does not cover every actual body: '+field);
  }
  if(provenance.eventsFullyValidated!==componentBuild.eventsFullyValidated
   ||JSON.stringify(buildRuntime)!==JSON.stringify(runtime)||runtime.heapLimitMiB!==3072
   ||componentGuardian.memoryLimitBytes!==limits.memoryMiB*1024*1024||componentGuardian.rssLimitBytes!==limits.rssMiB*1024*1024)throw Error('Native full-validation/automatic-GC/guardian contract changed');
  const pinBuildInputs=(pins:Record<string,unknown>,label:string)=>{
   if(!Object.keys(pins).length)throw Error('Missing canonical builder '+label);
   for(const [path,pin]of Object.entries(pins)){
    if(typeof pin!=='string'||!/^[0-9a-f]{64}$/.test(pin)||resolve(path)!==path||realpathSync(path)!==path||hash(path)!==pin||(state.inputs[path]!==undefined&&state.inputs[path]!==pin))throw Error('Canonical builder input drift: '+path);
    state.inputs[path]=pin;
   }
  };
  pinBuildInputs(protectedPins,'protected inputs');pinBuildInputs(loadedInputs,'loaded source closure');
  if(loadedInputs[realpathSync(o.root)]!==componentBuild.sourceSha256)throw Error('Canonical builder did not authenticate the actual root bytes');
  for(const path of ['evals/heavy_gate.ts','evals/heavy_gate_native.c'])if(protectedPins[realpathSync(path)]!==hash(path))throw Error('Missing canonical builder guardian identity');
  state.inputs[provenancePath]=hash(provenancePath);
  state.componentBuilder={provenancePath,provenanceSha256,compilerPath:provenance.compilerPath,compilerSha256:provenance.compilerSha256,runnerPath:provenance.runnerPath,runnerSha256:provenance.runnerSha256,loadedInputs,nativeCheckedBodies:provenance.nativeCheckedBodies,expectedSourceDefinitions:provenance.expectedSourceDefinitions};
  }
  const parserSource=acceptedParser.parserSource;
  state.parserSource={file:parserSource,sha256:hash(parserSource)};
  const diagnosticCodePaths=['bend2/bend.ts','bend2/comp.ts','evals/bootstrap_source_oracle.ts','evals/parser_full_semantic_normalize.ts','evals/parser_full_graph.ts','evals/bootstrap_ast_transport.ts','evals/selfhost_parser_parity.ts','evals/selfhost_bootstrap_worker.mjs','evals/checker_core_step_runtime.mjs'].map(path=>resolve(path));
  const diagnosticEnvironment=diagnosticCache?{
   schemaVersion:2,parser:realpathSync(o.parser),parserSha256:hash(o.parser),parserBuildSha256:hash(o.parserBuild),parserProvenance:acceptedParser.provenancePath,parserProvenanceSha256:hash(acceptedParser.provenancePath),parserSource,parserSourceSha256:hash(parserSource),
   parserFuel:limits.parserFuel,code:Object.fromEntries([...diagnosticCodePaths,import.meta.path].map(path=>[realpathSync(path),hash(path)])),
   cwd:realpathSync('.'),root:realpathSync(o.root),platform:process.platform,arch:process.arch,versions:process.versions,
   bendLib:process.env.BEND_LIB??null,bendHub:process.env.BEND_HUB??null,home:process.env.HOME??null,preloadBase:false,
  }:undefined;
  if(diagnosticCache){mkdirSync(join(diagnosticCache,'parses'),{recursive:true});for(const path of diagnosticCodePaths)state.inputs[path]=hash(path);}
  let diagnosticSourcesRegenerated=false;
  if(diagnosticCache)state.diagnosticCache={path:diagnosticCache,scope:'--fixture diagnostic seed parser only; disabled for every full-bootstrap parser/fixture boundary',authentication:'exact source bytes, parser/native build proof, code/runtime, realpaths, namespaces, observed import closure and full semantic parity proof + exact native transport SHA256'};
  const cacheBase=(message:Record<string,unknown>)=>{
   if(!diagnosticEnvironment||!message.cacheContext||message.parserSha256!==diagnosticEnvironment.parserSha256)throw Error('Diagnostic cache outside accepted seed-parser context');
   for(const [path,pin]of Object.entries(diagnosticEnvironment.code))if(realpathSync(path)!==path||hash(path)!==pin)throw Error('Diagnostic code provenance drift');
   for(const [path,pin]of [[o.parser,diagnosticEnvironment.parserSha256],[o.parserBuild,diagnosticEnvironment.parserBuildSha256],[diagnosticEnvironment.parserProvenance,diagnosticEnvironment.parserProvenanceSha256],[parserSource,diagnosticEnvironment.parserSourceSha256]])if(hash(path)!==pin)throw Error('Diagnostic parser provenance drift');
   const file=realpathSync(String(message.file));
   if(file!==message.file||hash(file)!==message.sourceBytesSha256||sha(readFileSync(file,'utf8'))!==message.sourceSha256)throw Error('Diagnostic source drift');
   return sha(JSON.stringify({environment:diagnosticEnvironment,file,sourceSha256:message.sourceSha256,sourceBytesSha256:message.sourceBytesSha256,context:message.cacheContext}));
  };
  const authenticateInputs=(inputs:unknown)=>{
   if(!Array.isArray(inputs)||!inputs.length)throw Error('Missing complete oracle input closure');
   for(const input of inputs){
    const pin=object(input);
    if(typeof pin.requested!=='string'||typeof pin.file!=='string'||typeof pin.sha256!=='string'||typeof pin.sourceSha256!=='string'
     ||realpathSync(pin.requested)!==pin.file||hash(pin.file)!==pin.sha256||sha(readFileSync(pin.file,'utf8'))!==pin.sourceSha256)throw Error('Oracle input closure drift');
   }
  };
  const diagnosticInputRealpaths=new Map<string,string>();
  const pinInputs=(inputs:unknown)=>{
   if(!Array.isArray(inputs))throw Error('Missing oracle input closure');
   for(const input of inputs){
    const pin=object(input),path=String(pin.requested),digest=String(pin.sha256);
    if(state.inputs[path]!==undefined&&state.inputs[path]!==digest)throw Error('Oracle input changed across diagnostic parses: '+path);
    state.inputs[path]=digest;diagnosticInputRealpaths.set(path,String(pin.file));
   }
  };
  const cacheHits=new Map<number,Record<string,unknown>>();
  const readCache=(message:Record<string,unknown>)=>{
   try{
    if(diagnosticSourcesRegenerated)return;
    const base=cacheBase(message),manifest=join(diagnosticCache!,'parses',base+'.json'),manifestBytes=readFileSync(manifest),entry=object(JSON.parse(manifestBytes.toString('utf8'))),payload=object(entry.payload);
    if(entry.sha256!==sha(JSON.stringify(payload))||payload.schemaVersion!==1||payload.base!==base||payload.key!==sha(JSON.stringify({base,inputs:payload.inputs,contexts:payload.contexts})))return;
    authenticateInputs(payload.inputs);
    if(!Array.isArray(payload.contexts)||!payload.contexts.length)return;
    const proof=object(payload.proof),ledger=object(proof.normalizationLedger),observation=object(ledger.observation);
    if(proof.file!==message.file||proof.sourceSha256!==message.sourceSha256||proof.sourceBytesSha256!==message.sourceBytesSha256||proof.parserSha256!==message.parserSha256
     ||proof.semanticParity!==true||proof.fullSemanticAST!==true||proof.oracleAccepted!==true||proof.parserFeedback!=='FeedbackComplete'||proof.parserFuel!==limits.parserFuel
     ||typeof proof.stage0ASTHash!=='string'||!/^[0-9a-f]{64}$/.test(proof.stage0ASTHash)||proof.stage0ASTHash!==proof.compiledASTHash
     ||typeof proof.transportSha256!=='string'||!/^[0-9a-f]{64}$/.test(proof.transportSha256)||payload.transportSha256!==proof.transportSha256
     ||!Number.isSafeInteger(proof.declarations)||Number(proof.declarations)<0||observation.stage0Sha256!==hash(resolve('bend2/bend.ts'))||!Array.isArray(observation.edits)||!observation.edits.length||!Array.isArray(ledger.exclusions))return;
    const transport=join(diagnosticCache!,'parses',proof.transportSha256+'.ast.json'),encoded=readFileSync(transport);
    if(sha(encoded)!==proof.transportSha256)return;
    const parsed=decodeNativeAst(encoded.toString('utf8'));
    if(!parsed||typeof parsed!=='object'||Array.isArray(parsed)||typeof parsed.$!=='string'||parsed.$.split('.').at(-1)!=='ParseSuccess'||!parsed.module)return;
    const current=join(sidecars,'parse-cache-'+message.id+'.ast.json'),proofPath=join(sidecars,'parse-cache-'+message.id+'.proof.json');
    writeFileSync(current,encoded,{flag:'wx'});writeFileSync(proofPath,manifestBytes,{flag:'wx'});
    pinInputs(payload.inputs);
    return {...proof,phase,transport:current,cache:{hit:true,key:payload.key,manifest:proofPath,manifestSha256:sha(manifestBytes),sourceManifest:manifest}};
   }catch{return;}
  };
  const storeCache=(message:Record<string,unknown>,proof:Record<string,unknown>,inputs:unknown,contexts:unknown)=>{
   const base=cacheBase(message);authenticateInputs(inputs);pinInputs(inputs);
   const transportSha256=String(proof.transportSha256),transport=join(diagnosticCache!,'parses',transportSha256+'.ast.json');
   copyFileSync(String(proof.transport),transport);
   if(hash(transport)!==transportSha256)throw Error('Diagnostic transport changed while publishing parity proof');
   const payload={schemaVersion:1,base,key:sha(JSON.stringify({base,inputs,contexts})),inputs,contexts,proof,transportSha256};
   save(join(diagnosticCache!,'parses',base+'.json'),{payload,sha256:sha(JSON.stringify(payload))});
   return payload.key;
  };
  let rootComposition:Record<string,unknown>|undefined;
  if(!o.fixture){
  const manifest=json(o.rootManifest!),embedding=object(manifest.embedding);
  const parserText=readFileSync(parserSource,'utf8'),rootText=readFileSync(o.root,'utf8');
  const declarationStart=parserText.search(/^(?:type|def) /m);
  if(declarationStart<0||manifest.schemaVersion!==1||manifest.parserSourceSha256!==parserBuild.sourceSha256||manifest.outputSha256!==hash(o.root)||typeof manifest.parserSource!=='string'||realpathSync(manifest.parserSource)!==parserSource||typeof manifest.output!=='string'||realpathSync(manifest.output)!==realpathSync(o.root)||typeof manifest.parserBuild!=='string'||realpathSync(manifest.parserBuild)!==realpathSync(o.parserBuild))throw Error('Exact accepted parser/root composition provenance mismatch');
  if(manifest.parserBodiesChanged!==0||manifest.parserDatatypesChanged!==0||manifest.parserRequestKontChanged!==false||manifest.parserDeclarationStart!==declarationStart||!Array.isArray(manifest.importChanges)||manifest.importChanges.length!==3)throw Error('Parser declarations or composition contract changed');
  const declarations=parserText.slice(declarationStart),originalHeader=parserText.slice(0,declarationStart);
  let relocatedHeader=originalHeader;
  for(const entry of manifest.importChanges){
   const change=object(entry);
   if(typeof change.before!=='string'||typeof change.after!=='string')throw Error('Malformed parser import relocation');
   const imported=/^import (\S+)( as [A-Za-z_][A-Za-z0-9_]*)$/.exec(change.before);
   if(!imported||imported[1]==='Base'||!imported[1]!.endsWith('.bend')||relocatedHeader.split(change.before+'\n').length!==2)throw Error('Non-import or duplicate parser relocation');
   let path=relative(dirname(o.root),resolve(dirname(parserSource),imported[1]!)).replaceAll('\\','/');
   if(!path.startsWith('.'))path='./'+path;
   if(change.after!=='import '+path+imported[2])throw Error('Parser import relocation changes its actual target or alias');
   relocatedHeader=relocatedHeader.replace(change.before+'\n',change.after+'\n');
  }
  if(relocatedHeader!==originalHeader)throw Error('Compiler root must preserve native parser constructor namespaces');
  const expectedImports='import ../bend2/selfhost/loaded_module.bend as Loader\nimport ../bend2/selfhost/backend_ir.bend as BIR\nimport ../bend2/selfhost/checked_frontend.bend as Checked\nimport ./template_steps_v1.bend as Template\nimport ./checker_core_steps_v1.bend as CheckerCore\nimport ./js_emit_steps_v1.bend as JSEmit\nimport ./c_emit_steps_v1.bend as CEmit\n\n';
  const expectedPrefix=relocatedHeader+expectedImports;
  if(embedding.start!==expectedPrefix.length||embedding.chars!==declarations.length||embedding.sha256!==sha(declarations)||manifest.parserDeclarationSha256!==sha(declarations)||rootText.slice(0,expectedPrefix.length)!==expectedPrefix||rootText.slice(expectedPrefix.length,expectedPrefix.length+declarations.length)!==declarations||sha(rootText.slice(expectedPrefix.length+declarations.length))!==manifest.wrapperSha256)throw Error('Root does not contain the exact complete accepted parser declaration suffix and import-only prefix');
  const wrapperNames=[...rootText.slice(expectedPrefix.length+declarations.length).matchAll(/^def ([A-Za-z_]\w*)\(/gm)].map(match=>match[1]);
  if(JSON.stringify(wrapperNames)!==JSON.stringify(ABI.filter(name=>name!=='parse_with_fuel')))throw Error('Root must expose the exact nine typed compiler wrappers plus the accepted parser entrypoint');
  if(typeof manifest.generator!=='string'||hash(manifest.generator)!==manifest.generatorSha256)throw Error('Root composition generator provenance drift');
  state.inputs[parserSource]=hash(parserSource);state.inputs[manifest.generator]=hash(manifest.generator);
  rootComposition={manifest:o.rootManifest,manifestSha256:hash(o.rootManifest!),rootSha256:hash(o.root),parserSourceSha256:hash(parserSource),parserDeclarationSha256:sha(declarations),embedding,exactParserDeclarations:true};
  state.rootComposition=rootComposition;
  }
  const bit='type Bit is Data:\n  BitZero{}\n  BitOne{}\n';
  const count='type Count is Data:\n  CZero{}\n  CSucc{pred: Count}\n';
  const bits=count+'law Bits:\n  for n: Count\n  Data\ntype Bits.Empty is Data:\n  BNil{}\ntype Bits.More<-p: Count> is Data:\n  BCons{tail: Bits(p)}\ndef Bits(n):\n  match n:\n    case CZero{}: Bits.Empty\n    case CSucc{p}: Bits.More(p)\n';
  const pair='type Sigma<a, b, -A: Kind(a), -B: @-x: A -> Kind(b)> is Kind(a <&> b):\n  Tuple{fst: A, snd: B(fst)}\nlaw Pair:\n  for -A: Type\n  for -B: Type\n  Type\ndef Pair(A, B):\n  Sigma<&1, &1, A, _ => B>\n';
  const tree='type Tree<a, -A: Kind(a)> is Kind(a):\n  Leaf{}\n  Branch{left: Tree<a, A>, right: Tree<a, A>}\n';
  const stringShadow=bit+'type Bool is Data:\n  False{}\n  True{}\ntype Word is Data:\n  WNil{}\n  WCon{head: Bool, tail: Word}\ntype U32 is Data:\n  U32{data: Word}\ntype Char is Data:\n  Chr{code: U32}\ntype String is Data:\n  SNil{}\n  SCon{head: Char, tail: String}\n';
  writeFileSync(join(sidecars,'specialization-lib.bend'),'import Base\n'+bit+'def identity(~A: Type, x: A) -> A:\n  x\n',{flag:'wx'});
  writeFileSync(join(sidecars,'alias-name-lib.bend'),bit,{flag:'wx'});
  writeFileSync(join(sidecars,'scope-left-lib.bend'),bit,{flag:'wx'});
  writeFileSync(join(sidecars,'scope-right-lib.bend'),bit,{flag:'wx'});
  writeFileSync(join(sidecars,'string-literal-lib.bend'),'import Base\ndef keep(~text: String) -> String:\n  text\n',{flag:'wx'});
  const indexImport=relative(diagnosticCache?join(diagnosticCache,'sources','case'):sidecars,resolve('bend2/selfhost/index_lookup.bend'));
  const fixtures=[
   {name:'type-specialization',source:'import Base\n'+bit+'def identity(~A: Type, x: A) -> A:\n  x\ndef main() -> Bit:\n  identity(~Bit, identity(~Bit, BitOne{}))\n',accepted:true,output:'BitOne{}'},
   {name:'constructor-eliminator-hit',source:bit+'def matcher() -> Bit -> Bit:\n  \\{BitZero: BitOne{}; BitOne: BitZero{}; \\{}}\ndef main() -> Bit:\n  matcher()(BitZero{})\n',accepted:true,output:'BitOne{}'},
   {name:'constructor-eliminator-default',source:bit+'def matcher() -> Bit -> Bit:\n  \\{BitZero: BitOne{}; BitOne: BitZero{}; \\{}}\ndef main() -> Bit:\n  matcher()(BitOne{})\n',accepted:true,output:'BitZero{}'},
   {name:'tag-dispatch-nested-fallthrough',source:bit+'type Choice is Data:\n  ChoiceA{value: Bit}\n  ChoiceB{}\n  ChoiceC{}\n  ChoiceD{}\ntype Results is Data:\n  Results{a: Bit, b: Bit, c: Bit, d: Bit, e: Bit}\ndef choose(x: Choice) -> Bit:\n  match x:\n    case ChoiceA{BitZero{}}: BitZero{}\n    case ChoiceB{}: BitOne{}\n    case ChoiceC{}: BitZero{}\n    case ChoiceA{BitOne{}}: BitOne{}\n    case _: BitOne{}\ndef main() -> Results:\n  Results{choose(ChoiceA{BitZero{}}), choose(ChoiceA{BitOne{}}), choose(ChoiceB{}), choose(ChoiceC{}), choose(ChoiceD{})}\n',accepted:true,output:'Results{BitZero{}, BitOne{}, BitOne{}, BitZero{}, BitOne{}}'},
   {name:'root-match-local-order',source:bit+'type Result is Data:\n  Result{first: Bit, last: Bit, skipped: Bit}\ndef first(a: Bit, b: Bit) -> Bit:\n  match a:\n    case BitZero{}: b\n    case BitOne{}: BitZero{}\ndef last(a: Bit, b: Bit) -> Bit:\n  match b:\n    case BitZero{}: a\n    case BitOne{}: BitZero{}\ndef skipped(a: Bit, b: Bit, c: Bit) -> Bit:\n  match a c:\n    case BitZero{} BitOne{}: b\n    case _ _: BitZero{}\ndef main() -> Result:\n  Result{first(BitZero{}, BitZero{}), last(BitOne{}, BitZero{}), skipped(BitZero{}, BitOne{}, BitOne{})}\n',accepted:true,output:'Result{BitZero{}, BitOne{}, BitOne{}}'},
   {name:'native-nat-extrema-boundaries',source:'import Base\n'+bit+'def select(value: Bool) -> Bit:\n  match value:\n    case True{}: BitOne{}\n    case False{}: BitZero{}\ndef upper() -> Nat:\n  Nat.add(Nat.mul(16777215n, 16777216n), 16777215n)\ndef main() -> Bit:\n  select(Bool.and(Nat.is_eq(Nat.min(upper(), 0n), 0n), Bool.and(Nat.is_eq(Nat.max(0n, upper()), upper()), Bool.and(Nat.is_eq(Nat.min(7n, 7n), 7n), Nat.is_eq(Nat.max(11n, 3n), 11n)))))\n',accepted:true,output:'BitOne{}'},
   {name:'source-tail-large-recursion',source:'import Base\n'+bit+'def descend(n: Nat) -> Bit:\n  match n:\n    case 0n: BitOne{}\n    case 1n+rest: descend(rest)\ndef main() -> Bit:\n  descend(65536n)\n',accepted:true,output:'BitOne{}'},
   {name:'nullary-array-freshness',source:'import Base\n'+bit+'def fresh() -> Array<U32>:\n  Array.new(U32, 0n, 0)\ndef choose(same: Bool) -> Bit:\n  match same:\n    case True{}: BitOne{}\n    case False{}: BitZero{}\ndef classify(a: U32, b: U32) -> Bit:\n  choose(Bool.and(U32.is_eq(a, 7), U32.is_zero(b)))\ndef second_result(first: U32, pair: Array<U32> & U32) -> Bit:\n  (array, second) = pair\n  classify(first, second)\ndef first_result(pair: Array<U32> & U32) -> Bit:\n  (array, first) = pair\n  second_result(first, Array.get(U32, fresh(), 0))\ndef main() -> Bit:\n  first_result(Array.get(U32, Array.set(U32, fresh(), 0, 7), 0))\n',accepted:true,output:'BitOne{}'},
   {name:'aliased-specialization',source:'import Base\nimport ./specialization-lib.bend as Lib\ndef main() -> Lib.Bit:\n  Lib.identity(~Lib.Bit, Lib.BitOne{})\n',accepted:true,output:'specialization-lib.BitOne{}'},
   {name:'callback-specialization',source:'import Base\n'+bit+'def apply(~f: Bit -> Bit, x: Bit) -> Bit:\n  f(x)\ndef main() -> Bit:\n  apply(~(x => x), BitZero{})\n',accepted:true,output:'BitZero{}'},
   {name:'specialized-type-error',source:'import Base\n'+bit+'type Other is Data:\n  Other{}\ndef identity(~A: Type, x: A) -> A:\n  x\ndef main() -> Other:\n  identity(~Bit, BitOne{})\n',accepted:false,failurePhase:'check'},
   {name:'runtime-template-capture',source:'import Base\n'+bit+'def identity(~x: Bit) -> Bit:\n  x\ndef runtime(x: Bit) -> Bit:\n  identity(~x)\ndef main() -> Bit:\n  runtime(BitOne{})\n',accepted:false,failurePhase:'expand'},
   {name:'template-generation-rounds',source:'import Base\n'+bit+'def inner(~A: Type, x: A) -> A:\n  x\ndef outer(~A: Type, x: A) -> A:\n  inner(~A, x)\ndef main() -> Bit:\n  outer(~Bit, inner(~Bit, BitOne{}))\n',accepted:true,output:'BitOne'},
   {name:'readonly-index-boundaries',source:'import Base\nimport '+indexImport+' as Index\n'+bit+'def found_value(actual: Maybe<&2, Bit>, expected: Bit) -> Bool:\n  match actual expected:\n    case Some{BitZero{}} BitZero{}: True{}\n    case Some{BitOne{}} BitOne{}: True{}\n    case _ _: False{}\ndef found(+map: Map<&2, Bit>, key: String, expected: Bit) -> Bool:\n  found_value(Index.find(Bit, map, key), expected)\ndef absent(actual: Maybe<&2, Bit>) -> Bool:\n  match actual:\n    case None{}: True{}\n    case Some{_}: False{}\ndef main() -> Bit:\n  m0 = Map.set(&2, Bit, MTip{}, "", BitZero{})\n  m1 = Map.set(&2, Bit, m0, "a", BitOne{})\n  m2 = Map.set(&2, Bit, m1, "ab", BitZero{})\n  m3 = Map.set(&2, Bit, m2, "λ😀", BitOne{})\n  +map = Map.set(&2, Bit, m3, "a", BitZero{})\n  ok = Bool.and(found(map, "", BitZero{}), Bool.and(found(map, "a", BitZero{}), Bool.and(found(map, "ab", BitZero{}), Bool.and(found(map, "λ😀", BitOne{}), Bool.and(absent(Index.find(Bit, map, "abc")), absent(Index.find(Bit, map, "λ")))))))\n  Bool.pick(Bit, ok, BitOne{}, BitZero{})\n',accepted:true,output:'BitOne'},
   {name:'readonly-index-nonmonotone',source:'import Base\nimport '+indexImport+' as Index\n'+bit+'def arbitrary_map() -> Map<&2, Bit>:\n  MNode{33n, MNode{0n, MLeaf{"", BitZero{}}, MLeaf{"a", BitOne{}}}, MLeaf{"ab", BitZero{}}}\ndef has(actual: Maybe<&2, Bit>, expected: Bit) -> Bool:\n  match actual expected:\n    case Some{BitZero{}} BitZero{}: True{}\n    case Some{BitOne{}} BitOne{}: True{}\n    case _ _: False{}\ndef absent(actual: Maybe<&2, Bit>) -> Bool:\n  match actual:\n    case None{}: True{}\n    case Some{_}: False{}\ndef main() -> Bit:\n  +map = arbitrary_map()\n  ok = Bool.and(has(Index.find(Bit, map, ""), BitZero{}), Bool.and(has(Index.find(Bit, map, "a"), BitOne{}), Bool.and(has(Index.find(Bit, map, "ab"), BitZero{}), absent(Index.find(Bit, map, "ac")))))\n  Bool.pick(Bit, ok, BitOne{}, BitZero{})\n',accepted:true,output:'BitOne'},
   {name:'dependent-kind-binding',source:bit+'type Either<a, b, -A: Kind(a), -B: Kind(b)> is Kind(a <&> b):\n  Inl{value: A}\n  Inr{value: B}\ndef identity(a, -A: Kind(a), x: A) -> A:\n  x\ndef main() -> Bit:\n  identity(&2, Bit, BitOne{})\n',accepted:true,output:'BitOne{}'},
   {name:'law-completion-binding',source:'type Nat is Data:\n  Zero{}\n  Succ{pred: Nat}\nlaw Word:\n  for n: Nat\n  Data\ntype Word.Nil is Data:\n  WNil{}\ntype Word.Con<-p: Nat> is Data:\n  WCon{tail: Word(p)}\ndef Word(n):\n  match n:\n    case 0n: Word.Nil\n    case 1n+p: Word.Con(p)\ndef main() -> Word(0n):\n  WNil{}\n',accepted:true,output:'WNil{}'},
   {name:'forward-family-definition',source:'type Nat is Data:\n  Zero{}\n  Succ{pred: Nat}\ntype Word.Nil is Data:\n  WNil{}\ntype Word.Con<-p: Nat> is Data:\n  WCon{tail: Word(p)}\ndef Word(n: Nat) -> Data:\n  match n:\n    case 0n: Word.Nil\n    case 1n+p: Word.Con(p)\ndef main() -> Word(0n):\n  WNil{}\n',accepted:true,output:'WNil{}'},
   {name:'forward-definition-call',source:bit+'def first(x: Bit) -> Bit:\n  later(x)\ndef later(x: Bit) -> Bit:\n  x\ndef main() -> Bit:\n  first(BitOne{})\n',accepted:true,output:'BitOne{}'},
  {name:'named-entry-separator-collision',source:count+'def a.b(x: Count) -> Count:\n  CSucc{x}\ndef a_46_b(x: Count) -> Count:\n  CSucc{CSucc{x}}\ndef main() -> Count:\n  a.b(a_46_b(CZero{}))\n',accepted:true,output:'CSucc{CSucc{CSucc{CZero{}}}}'},
   {name:'forward-definition-invalid-body',source:bit+'type Other is Data:\n  Other{}\ndef first(x: Bit) -> Bit:\n  later(x)\ndef later(x: Bit) -> Bit:\n  Other{}\ndef main() -> Bit:\n  first(BitOne{})\n',accepted:false,failurePhase:'check'},
   {name:'recursive-neutral-application-equality',source:'type Nat is Data:\n  Zero{}\n  Succ{pred: Nat}\ntype Bool is Data:\n  False{}\n  True{}\ndef ge(a: Nat, b: Nat) -> Bool:\n  match a b:\n    case 0n 0n: True{}\n    case 0n 1n+_: False{}\n    case 1n+_ 0n: True{}\n    case 1n+ap 1n+bp: ge(ap, bp)\nlaw ge_refl:\n  for a: Nat\n  {ge(a, a) == True{} : Bool}\ndef ge_refl(a):\n  match a:\n    case 0n: {==}\n    case 1n+p: ge_refl(p)\ndef main() -> Bool:\n  True{}\n',accepted:true,output:'True{}'},
   {name:'application-order',source:bit+'type Duo is Data:\n  Duo{left: Bit, right: Bit}\ndef pack(left: Bit, right: Bit) -> Duo:\n  Duo{left, right}\ndef main() -> Duo:\n  pack(BitOne{}, BitZero{})\n',accepted:true,output:'Duo{BitOne{}, BitZero{}}'},
   {name:'annotated-banged-partial-application',source:bit+'def select(left: Bit, right: Bit) -> Bit:\n  left\ndef main() -> Bit:\n  {select!(BitOne{}) : Bit -> Bit}(BitZero{})\n',accepted:true,output:'BitOne{}'},
   {name:'annotated-banged-partial-result-mismatch',source:bit+count+'def select(left: Bit, right: Bit) -> Bit:\n  left\ndef main() -> Bit:\n  {select!(BitOne{}) : Bit -> Count}(BitZero{})\n',accepted:false,failurePhase:'check'},
   {name:'renamed-dependent-law-completion',source:bit+'law identity:\n  for -A: Type\n  for value: A\n  A\ndef identity(T, x):\n  x\ndef main() -> Bit:\n  identity(Bit, BitOne{})\n',accepted:true,output:'BitOne{}'},
   {name:'law-completion-result-mismatch',source:bit+'law identity:\n  for -A: Type\n  for value: A\n  A\ndef identity(T, x):\n  BitZero{}\ndef main() -> Bit:\n  identity(Bit, BitOne{})\n',accepted:false,failurePhase:'check'},
   {name:'partial-family-application',source:bit+'type Family<-A: Type, -B: Type> is Type:\n  FamilyCtr{left: A, right: B}\ndef partial(x: Bit) -> (@-B: Type -> Type):\n  Family(Bit)\ndef main() -> Bit:\n  BitOne{}\n',accepted:true,output:'BitOne{}'},
   {name:'affine-duplicate',source:bit+'type Duo is Type:\n  Duo{left: Bit, right: Bit}\ndef twice(x: Bit) -> Duo:\n  Duo{x, x}\ndef main() -> Duo:\n  twice(BitOne{})\n',accepted:false,failurePhase:'check'},
   {name:'dependent-field-pattern',source:bit+'type Cell<-A: Type> is Type:\n  CellCtr{value: A}\ndef unwrap(-A: Type, x: Cell(A)) -> A:\n  match x:\n    case CellCtr{value}: value\ndef main() -> Bit:\n  unwrap(Bit, CellCtr{BitOne{}})\n',accepted:true,output:'BitOne{}'},
   {name:'indexed-family-parameter-mismatch',source:bit+'type Nat is Data:\n  Zero{}\n  Succ{pred: Nat}\ntype Indexed<-n: Nat> is Data:\n  IndexedCtr{value: Bit}\ndef wrong(x: Indexed(0n)) -> Indexed(1n):\n  x\ndef main() -> Bit:\n  BitOne{}\n',accepted:false,failurePhase:'check'},
   {name:'equality-congruence-rewrite',source:bit+'law cong:\n  for -A: Type\n  for -B: Type\n  for -f: A -> B\n  for -a: A\n  for -b: A\n  for e: {a == b : A}\n  {f(a) == f(b) : B}\ndef cong(A, B, f, a, b, e):\n  %e : {f(a) == f(_) : B}\n  {==}\ndef main() -> Bit:\n  BitOne{}\n',accepted:true,output:'BitOne{}'},
   {name:'rewrite-result-mismatch',source:bit+'def wrong(-A: Type, -a: A, -b: A, e: {a == b : A}) -> {a == b : A}:\n  %e : {b == _ : A}\n  {==}\ndef main() -> Bit:\n  BitOne{}\n',accepted:false,failurePhase:'check'},
   {name:'empty-datatype-match',source:bit+'type Empty is Data:\ndef absurd(-A: Type, e: Empty) -> A:\n  match e:\ndef main() -> Bit:\n  BitOne{}\n',accepted:true,output:'BitOne{}'},
   {name:'nonempty-datatype-empty-match',source:bit+'def wrong(x: Bit) -> Bit:\n  match x:\ndef main() -> Bit:\n  BitOne{}\n',accepted:false,failurePhase:'check'},
   {name:'abstract-type-empty-match',source:bit+'def wrong(-A: Type, x: A) -> Bit:\n  match x:\ndef main() -> Bit:\n  BitOne{}\n',accepted:false,failurePhase:'check'},
   {name:'aliased-constructor-conversion',source:'import ./alias-name-lib.bend as Lib\ndef flip(x: Lib.Bit) -> Lib.Bit:\n  match x:\n    case Lib.BitZero{}: Lib.BitOne{}\n    case Lib.BitOne{}: Lib.BitZero{}\ndef main() -> Lib.Bit:\n  flip(Lib.BitZero{})\n',accepted:true,output:'alias-name-lib.BitOne{}'},
   {name:'distinct-imported-family-mismatch',source:'import ./scope-left-lib.bend as Left\nimport ./scope-right-lib.bend as Right\ndef main() -> Left.Bit:\n  Right.BitZero{}\n',accepted:false,failurePhase:'check'},
   {name:'same-module-alias-family-equality',source:'import ./scope-left-lib.bend as Left\nimport ./scope-left-lib.bend as Right\ndef convert(x: Left.Bit) -> Right.Bit:\n  x\ndef main() -> Right.Bit:\n  convert(Left.BitOne{})\n',accepted:true,output:'scope-left-lib.BitOne{}'},
   {name:'same-module-alias-constructor-rows',source:'import ./scope-left-lib.bend as Left\nimport ./scope-left-lib.bend as Right\ntype Other is Data:\n  Other{}\ndef flip(x: Left.Bit) -> Left.Bit:\n  match x:\n    case Right.BitZero{}: Left.BitOne{}\n    case Left.BitZero{}: Other{}\n    case Right.BitOne{}: Left.BitZero{}\ndef finish(x: Left.Bit) -> Left.Bit:\n  match x:\n    case Right.BitZero{}: flip(Left.BitZero{})\n    case Right.BitOne{}: Left.BitZero{}\ndef main() -> Left.Bit:\n  finish(flip(Left.BitOne{}))\n',accepted:true,output:'scope-left-lib.BitOne{}'},
  {name:'alias-dependent-conversion',source:'import ./scope-left-lib.bend as Left\nimport ./scope-left-lib.bend as Right\ndef flip(x: Left.Bit) -> Left.Bit:\n  match x:\n    case Right.BitZero{}: Left.BitOne{}\n    case Right.BitOne{}: Left.BitZero{}\ntype Tag<-index: Left.Bit> is Data:\n  Tag{}\ndef convert(x: Tag(flip(Left.BitZero{}))) -> Tag(Right.BitOne{}):\n  x\ndef main() -> Left.Bit:\n  flip(Left.BitZero{})\n',accepted:true,output:'scope-left-lib.BitOne{}'},
  {name:'stuck-first-row-dependent-conversion',source:count+'def collapse(n: Count) -> Count:\n  match n:\n    case CSucc{CZero{}}: CZero{}\n    case CSucc{p}: CSucc{CZero{}}\n    case CZero{}: CZero{}\ntype Tag<-index: Count> is Data:\n  Tag{}\ndef wrong(-p: Count, x: Tag(collapse(CSucc{p}))) -> Tag(CSucc{CZero{}}):\n  x\ndef main() -> Count:\n  CZero{}\n',accepted:false,failurePhase:'check'},
   {name:'local-imported-family-mismatch',source:'import ./scope-left-lib.bend as Lib\n'+bit+'def main() -> Bit:\n  Lib.BitOne{}\n',accepted:false,failurePhase:'check'},
   {name:'datatype-constructor-shared-name',source:bit+'type Wrapper is Data:\n  Wrapper{payload: Bit}\ndef main() -> Wrapper:\n  Wrapper{BitOne{}}\n',accepted:true,output:'Wrapper{BitOne{}}'},
   {name:'constructor-args-field',source:bit+'type FieldBox is Data:\n  WithArgs{args: Bit, next: Bit}\ndef first(box: FieldBox) -> Bit:\n  match box:\n    case WithArgs{head, tail}: head\ndef main() -> Bit:\n  first(WithArgs{BitOne{}, BitZero{}})\n',accepted:true,output:'BitOne{}'},
   {name:'structural-predecessor-recursion',source:count+'def twice(n: Count) -> Count:\n  match n:\n    case CZero{}: CZero{}\n    case CSucc{p}: CSucc{CSucc{twice(p)}}\ndef main() -> Count:\n  twice(CSucc{CSucc{CZero{}}})\n',accepted:true,output:'CSucc{CSucc{CSucc{CSucc{CZero{}}}}}'},
   {name:'structural-original-input-recursion',source:count+'def wrong(+n: Count) -> Count:\n  match n:\n    case CZero{}: CZero{}\n    case CSucc{p}: wrong(n)\ndef main() -> Count:\n  CZero{}\n',accepted:false,failurePhase:'check'},
   {name:'structural-equal-input-recursion',source:count+'def wrong(n: Count) -> Count:\n  match n:\n    case CZero{}: CZero{}\n    case CSucc{p}: wrong(CSucc{p})\ndef main() -> Count:\n  CZero{}\n',accepted:false,failurePhase:'check'},
   {name:'structural-growing-input-recursion',source:count+'def wrong(n: Count) -> Count:\n  match n:\n    case CZero{}: CZero{}\n    case CSucc{p}: wrong(CSucc{CSucc{p}})\ndef main() -> Count:\n  CZero{}\n',accepted:false,failurePhase:'check'},
   {name:'recursive-matrix-variable-column',source:bit+count+'def select(a: Count, b: Count) -> Bit:\n  match a b:\n    case CZero{} CZero{}: BitZero{}\n    case CZero{} CSucc{q}: BitOne{}\n    case CSucc{p} CZero{}: BitZero{}\n    case CSucc{p} CSucc{q}: BitOne{}\ndef main() -> Bit:\n  select(CSucc{CZero{}}, CSucc{CZero{}})\n',accepted:true,output:'BitOne{}'},
   {name:'recursive-matrix-incomplete-variable-column',source:bit+count+'def wrong(a: Count, b: Count) -> Bit:\n  match a b:\n    case CZero{} _: BitZero{}\n    case CSucc{p} CZero{}: BitZero{}\ndef main() -> Bit:\n  BitOne{}\n',accepted:false,failurePhase:'check'},
   {name:'copied-constructor-field-quantity',source:count+'def keep(a: Count, b: Count) -> Count:\n  a\ndef copied(+n: Count) -> Count:\n  match n:\n    case CZero{}: CZero{}\n    case CSucc{p}: keep(p, p)\ndef main() -> Count:\n  copied(CSucc{CZero{}})\n',accepted:true,output:'CZero{}'},
   {name:'affine-constructor-field-quantity',source:count+'def keep(a: Count, b: Count) -> Count:\n  a\ndef wrong(n: Count) -> Count:\n  match n:\n    case CZero{}: CZero{}\n    case CSucc{p}: keep(p, p)\ndef main() -> Count:\n  CZero{}\n',accepted:false,failurePhase:'check'},
   {name:'erased-constructor-field-quantity',source:bit+'type ErasedFields is Data:\n  ErasedBox{-value: Bit}\ndef wrong(+box: ErasedFields) -> Bit:\n  match box:\n    case ErasedBox{value}: value\ndef main() -> Bit:\n  BitOne{}\n',accepted:false,failurePhase:'check'},
   {name:'erased-constructor-default-binding',source:bit+'type ErasedFields is Data:\n  ErasedBox{-ghost: Bit, value: Bit}\ndef ignore(-ghost: Bit, value: Bit) -> Bit:\n  value\ndef read(+box: ErasedFields) -> Bit:\n  match box:\n    case ErasedBox{ghost, value}: ignore(ghost, value)\ndef main() -> Bit:\n  read(ErasedBox{BitZero{}, BitOne{}})\n',accepted:true,output:'BitOne{}'},
   {name:'long-unicode-string-pattern-tail',source:'import Base\n'+bit+'type Results is Data:\n  Results{first: Bit, second: Bit, other: Bit}\ndef select(text: String) -> Bit:\n  match text:\n    case "🙂compiler-root-pattern-tail": BitOne{}\n    case "🙂compiler-root-pattern-tall": BitZero{}\n    case _: BitOne{}\ndef main() -> Results:\n  Results{select("🙂compiler-root-pattern-tail"), select("🙂compiler-root-pattern-tall"), select("🙂compiler-root-pattern-other")}\n',accepted:true,output:'Results{BitOne{},BitZero{},BitOne{}}'},
   {name:'compact-string-native-scalars-and-explicit-equivalence',source:'import Base\n'+bit+'def choose(value: Bool) -> Bit:\n  match value:\n    case True{}: BitOne{}\n    case False{}: BitZero{}\ndef main() -> Bit:\n  choose(Bool.and(String.eq("A", SCon{Chr{65}, SNil{}}), Bool.and(String.eq("", SNil{}), Bool.and(String.eq("😀\\0\\n\\t\\\\\\\"", "\\u{1f600}\\u{0}\\u{a}\\u{9}\\u{5c}\\u{22}"), String.eq("long-unicode-λ-😀-compiler-root-string", "long-unicode-λ-😀-compiler-root-string")))))\n',accepted:true,output:'BitOne{}'},
   {name:'compact-string-imported-template-alias-capture',source:'import Base\nimport ./string-literal-lib.bend as Lib\n'+bit+'def choose(value: Bool) -> Bit:\n  match value:\n    case True{}: BitOne{}\n    case False{}: BitZero{}\ndef main() -> Bit:\n  choose(String.eq(Lib.keep(~"😀\\0alias-captured"), "😀\\0alias-captured"))\n',accepted:true,output:'BitOne{}'},
   {name:'compact-string-primitive-like-shadow-fallback',source:stringShadow+'def select(text: String) -> Bit:\n  match text:\n    case "A": BitOne{}\n    case _: BitZero{}\ndef main() -> Bit:\n  select(SCon{Chr{65}, SNil{}})\n',accepted:true,output:'BitOne{}'},
   {name:'compact-string-dependent-explicit-constructor-equality',source:'import Base\n'+bit+'def witness() -> {"A" == SCon{Chr{65}, SNil{}} : String}:\n  {==}\ndef choose(-proof: {"A" == SCon{Chr{65}, SNil{}} : String}) -> Bit:\n  BitOne{}\ndef main() -> Bit:\n  choose(witness())\n',accepted:true,output:'BitOne{}'},
   {name:'compact-string-template-empty-unused-constructors',source:'type String is Data:\n  SNil{}\ndef keep(~text: String) -> String:\n  text\ndef main() -> String:\n  keep(~"")\n',accepted:true,output:'SNil{}'},
   {name:'compact-string-template-zero-unused-true',source:bit+'type Bool is Data:\n  False{}\ntype Word is Data:\n  WNil{}\n  WCon{head: Bool, tail: Word}\ntype U32 is Data:\n  U32{data: Word}\ntype Char is Data:\n  Chr{code: U32}\ntype String is Data:\n  SNil{}\n  SCon{head: Char, tail: String}\ndef keep(~text: String) -> String:\n  text\ndef select(text: String) -> Bit:\n  match text:\n    case "\\0": BitOne{}\n    case _: BitZero{}\ndef main() -> Bit:\n  select(keep(~"\\0"))\n',accepted:true,output:'BitOne{}'},
   {name:'compact-string-invalid-scalar-custom-constructor-fallback',source:stringShadow+'def keep(~text: String) -> String:\n  text\ndef select(text: String) -> Bit:\n  match text:\n    case "\\u{110000}": BitOne{}\n    case _: BitZero{}\ndef main() -> Bit:\n  select(keep(~"\\u{110000}"))\n',accepted:true,output:'BitOne{}'},
   {name:'compact-string-tail120001-callback',source:'import Base\n'+bit+'def apply(f: String -> Bit, text: String) -> Bit:\n  f(text)\ndef observe(text: String) -> Bit:\n  match text:\n    case "tail😀": BitOne{}\n    case _: BitZero{}\ndef descend(n: Nat, text: String) -> Bit:\n  match n:\n    case 0n: apply(observe, text)\n    case 1n+rest: descend(rest, text)\ndef main() -> Bit:\n  descend(120001n, "tail😀")\n',accepted:true,output:'BitOne{}'},
   {name:'patricia-selected-branch-unicode',source:'import Base\nimport ../../bend2/selfhost/index_lookup.bend as Lookup\n'+bit+'def query(key: String) -> Maybe<&2, Nat>:\n  Lookup.find(Nat, MNode{0n, MLeaf{"", 1n}, MNode{66n, MLeaf{"😀", 2n}, MLeaf{"unselected", 3n}}}, key)\ndef observe(a: Maybe<&2, Nat>, b: Maybe<&2, Nat>, c: Maybe<&2, Nat>) -> Bit:\n  match a b c:\n    case Some{1n} Some{2n} None{}: BitOne{}\n    case _ _ _: BitZero{}\ndef main() -> Bit:\n  observe(query(""), query("😀"), query("missing"))\n',accepted:true,output:'BitOne{}'},
   {name:'mixed-named-closure-tail120001',source:'import Base\n'+bit+'def apply(f: Bit -> Bit, value: Bit) -> Bit:\n  f(value)\ndef descend(n: Nat) -> Bit:\n  match n:\n    case 0n: BitOne{}\n    case 1n+rest: apply(ignored => descend(rest), BitZero{})\ndef main() -> Bit:\n  descend(120001n)\n',accepted:true,output:'BitOne{}'},
   {name:'private-tail-register-boundaries',source:"import Base\ntype Bit is Data:\n  BitZero{}\n  BitOne{}\ntype RegisterResults is Data:\n  Results{left: Nat, right: Nat, narrow: Nat, wide: Nat}\ndef bounce(n: Nat, value: Nat) -> Nat:\n  match n:\n    case 0n: value\n    case 1n+rest: bounce(rest, value)\ndef arity32(a0: Nat, a1: Nat, a2: Nat, a3: Nat, a4: Nat, a5: Nat, a6: Nat, a7: Nat, a8: Nat, a9: Nat, a10: Nat, a11: Nat, a12: Nat, a13: Nat, a14: Nat, a15: Nat, a16: Nat, a17: Nat, a18: Nat, a19: Nat, a20: Nat, a21: Nat, a22: Nat, a23: Nat, a24: Nat, a25: Nat, a26: Nat, a27: Nat, a28: Nat, a29: Nat, a30: Nat, a31: Nat) -> Nat:\n  Nat.add(a0, a31)\ndef invoke32(n: Nat) -> Nat:\n  match n:\n    case 0n: arity32(1n, 2n, 3n, 4n, 5n, 6n, 7n, 8n, 9n, 10n, 11n, 12n, 13n, 14n, 15n, 16n, 17n, 18n, 19n, 20n, 21n, 22n, 23n, 24n, 25n, 26n, 27n, 28n, 29n, 30n, 31n, 32n)\n    case 1n+rest: invoke32(rest)\ndef arity40(a0: Nat, a1: Nat, a2: Nat, a3: Nat, a4: Nat, a5: Nat, a6: Nat, a7: Nat, a8: Nat, a9: Nat, a10: Nat, a11: Nat, a12: Nat, a13: Nat, a14: Nat, a15: Nat, a16: Nat, a17: Nat, a18: Nat, a19: Nat, a20: Nat, a21: Nat, a22: Nat, a23: Nat, a24: Nat, a25: Nat, a26: Nat, a27: Nat, a28: Nat, a29: Nat, a30: Nat, a31: Nat, a32: Nat, a33: Nat, a34: Nat, a35: Nat, a36: Nat, a37: Nat, a38: Nat, a39: Nat) -> Nat:\n  Nat.add(a0, a39)\ndef invoke40(n: Nat) -> Nat:\n  match n:\n    case 0n: arity40(1n, 2n, 3n, 4n, 5n, 6n, 7n, 8n, 9n, 10n, 11n, 12n, 13n, 14n, 15n, 16n, 17n, 18n, 19n, 20n, 21n, 22n, 23n, 24n, 25n, 26n, 27n, 28n, 29n, 30n, 31n, 32n, 33n, 34n, 35n, 36n, 37n, 38n, 39n, 40n)\n    case 1n+rest: invoke40(rest)\ndef observe(value: RegisterResults) -> Bit:\n  match value:\n    case Results{1n, 2n, 33n, 41n}: BitOne{}\n    case _: BitZero{}\ndef main() -> Bit:\n  observe(Results{bounce(64n, 1n), bounce(65n, 2n), invoke32(64n), invoke40(64n)})\n",accepted:true,output:'BitOne{}'},
   {name:'compact-string-invalid-native-scalar-deferred-branch',source:'import Base\n'+bit+'def select(value: Bool) -> Bit:\n  match value:\n    case True{}: BitOne{}\n    case False{}: BitZero{}\ndef branch(flag: Bool) -> Bit:\n  match flag:\n    case True{}: BitOne{}\n    case False{}: select(String.eq("\\u{110000}", "unused"))\ndef main() -> Bit:\n  branch(True{})\n',accepted:true,output:'BitOne{}'},
   {name:'dependent-match-goal-refinement',source:bits+'def zero(n: Count) -> Bits(n):\n  match n:\n    case CZero{}: BNil{}\n    case CSucc{p}: BCons{zero(p)}\ndef main() -> Bits(CSucc{CZero{}}):\n  zero(CSucc{CZero{}})\n',accepted:true,output:'BCons{BNil{}}'},
   {name:'dependent-vector-goal-refinement',source:bits+'def zero(n: Count) -> Bits(n):\n  match n:\n    case CZero{}: BNil{}\n    case CSucc{p}: BCons{zero(p)}\ndef choose(n: Count, m: Count) -> Bits(n):\n  match n m:\n    case CZero{} _: BNil{}\n    case CSucc{p} _: BCons{zero(p)}\ndef main() -> Bits(CSucc{CZero{}}):\n  choose(CSucc{CZero{}}, CZero{})\n',accepted:true,output:'BCons{BNil{}}'},
   {name:'dependent-nested-binding-refinement',source:bit+bits+'def replay(n: Count, w: Bits(n)) -> Bits(n):\n  match n:\n    case CZero{}: BNil{}\n    case CSucc{p}:\n      match w:\n        case BCons{tail}: BCons{tail}\ndef observe(w: Bits(CSucc{CZero{}})) -> Bit:\n  match w:\n    case BCons{tail}: BitOne{}\ndef main() -> Bit:\n  observe(replay(CSucc{CZero{}}, BCons{BNil{}}))\n',accepted:true,output:'BitOne'},
   {name:'dependent-tuple-local-binding',source:bit+bits+pair+'def push(-p: Count, c: Bit, r: Bit & Bits(p)) -> Bit & Bits(CSucc{p}):\n  (hi, tail) = r\n  (hi, BCons{tail})\ndef observe(r: Bit & Bits(CSucc{CZero{}})) -> Bit:\n  (hi, tail) = r\n  hi\ndef main() -> Bit:\n  observe(push(CZero{}, BitZero{}, (BitOne{}, BNil{})))\n',accepted:true,output:'BitOne'},
   {name:'neutral-tuple-distinct-index',source:bit+bits+pair+'def wrong(-p: Count, -q: Count, r: Bit & Bits(p)) -> Bit & Bits(q):\n  (hi, tail) = r\n  (hi, tail)\ndef main() -> Bit:\n  BitOne{}\n',accepted:false,failurePhase:'check'},
   {name:'neutral-family-distinct-branches',source:bit+bits+pair+'law Swap:\n  for n: Count\n  Data\ndef Swap(n):\n  match n:\n    case CZero{}: Bits.More(CZero{})\n    case CSucc{p}: Bits.Empty\ndef wrong(-p: Count, r: Bit & Bits(p)) -> Bit & Swap(p):\n  (hi, tail) = r\n  (hi, tail)\ndef main() -> Bit:\n  BitOne{}\n',accepted:false,failurePhase:'check'},
   {name:'nested-constructor-cases-disjoint',source:bit+'type Box is Data:\n  Box{value: Bit}\ndef flip(box: Box) -> Bit:\n  match box:\n    case Box{BitZero{}}: BitOne{}\n    case Box{BitOne{}}: BitZero{}\ndef main() -> Bit:\n  flip(Box{BitZero{}})\n',accepted:true,output:'BitOne'},
   {name:'nested-constructor-case-duplicate',source:bit+'type Box is Data:\n  Box{value: Bit}\ndef first(box: Box) -> Bit:\n  match box:\n    case Box{BitZero{}}: BitOne{}\n    case Box{BitZero{}}: BitZero{}\n    case Box{BitOne{}}: BitZero{}\ndef main() -> Bit:\n  first(Box{BitZero{}})\n',accepted:true,output:'BitOne'},
   {name:'nested-constructor-ordered-fallback',source:bit+'type Box is Data:\n  Box{value: Bit}\ndef choose(box: Box) -> Bit:\n  match box:\n    case Box{BitZero{}}: BitOne{}\n    case Box{value}: value\ndef main() -> Bit:\n  choose(Box{BitZero{}})\n',accepted:true,output:'BitOne'},
   {name:'nested-constructor-unreachable-union',source:bit+'type Box is Data:\n  Box{value: Bit}\ndef first(box: Box) -> Bit:\n  match box:\n    case Box{BitZero{}}: BitOne{}\n    case Box{BitOne{}}: BitZero{}\n    case Box{value}: value\ndef main() -> Bit:\n  first(Box{BitZero{}})\n',accepted:true,output:'BitOne'},
   {name:'annotated-constructor-equality',source:bit+bits+'law witness:\n  for p: Count\n  for -w: Bits(p)\n  {BCons{w} == BCons{w} : Bits.More(p)}\ndef witness(p, w):\n  {==}\ndef main() -> Bit:\n  BitOne{}\n',accepted:true,output:'BitOne'},
   {name:'annotated-equality-wrong-constructor',source:bit+bits+'law wrong:\n  for p: Count\n  for -w: Bits(p)\n  {BCons{w} == BNil{} : Bits.More(p)}\ndef main() -> Bit:\n  BitOne{}\n',accepted:false,failurePhase:'check'},
   {name:'annotated-equality-wrong-type',source:bit+bits+'law wrong:\n  for p: Count\n  for -w: Bits(p)\n  {w == w : Bit}\ndef main() -> Bit:\n  BitOne{}\n',accepted:false,failurePhase:'check'},
   {name:'promoted-data-constructor-field',source:count+'type Box is Data:\n  Box{value: Count}\ndef keep(a: Count, b: Count) -> Count:\n  a\ndef copy(box: Box) -> Count:\n  match box:\n    case Box{+value}: keep(value, value)\ndef main() -> Count:\n  copy(Box{CSucc{CZero{}}})\n',accepted:true,output:'CSucc{CZero{}}'},
   {name:'promoted-affine-constructor-field',source:bit+'type Token is Type:\n  Token{}\ntype Box is Type:\n  Box{value: Token}\ndef wrong(box: Box) -> Token:\n  match box:\n    case Box{+value}: value\ndef main() -> Bit:\n  BitOne{}\n',accepted:false,failurePhase:'check'},
   {name:'promoted-data-tuple-field',source:bit+count+pair+'def keep(a: Count, b: Count) -> Count:\n  a\ndef copy(r: Bit & Count) -> Count:\n  (b, +n) = r\n  keep(n, n)\ndef main() -> Count:\n  copy((BitOne{}, CSucc{CZero{}}))\n',accepted:true,output:'CSucc{CZero{}}'},
   {name:'promoted-affine-tuple-field',source:bit+pair+'type Token is Type:\n  Token{}\ndef wrong(r: Bit & Token) -> Token:\n  (b, +value) = r\n  value\ndef main() -> Bit:\n  BitOne{}\n',accepted:false,failurePhase:'check'},
   {name:'nested-structural-recursive-calls',source:bit+count+tree+'def collect(a, -A: Kind(a), tree: Tree<a, A>, acc: Count) -> Count:\n  match tree:\n    case Leaf{}: acc\n    case Branch{left, right}: collect(a, A, left, collect(a, A, right, acc))\ndef main() -> Count:\n  collect(&2, Bit, Branch{Leaf{}, Leaf{}}, CSucc{CZero{}})\n',accepted:true,output:'CSucc{CZero{}}'},
   {name:'nested-structural-invalid-inner-call',source:bit+count+tree+'def wrong(a, -A: Kind(a), tree: Tree<a, A>, acc: Count) -> Count:\n  match tree:\n    case Leaf{}: acc\n    case Branch{left, right}: wrong(a, A, left, wrong(a, A, Branch{Leaf{}, Leaf{}}, acc))\ndef main() -> Count:\n  CZero{}\n',accepted:false,failurePhase:'check'},
   {name:'closed-local-annotation-usage',source:bit+'def select(literal: Bit, value: Bit) -> Bit:\n  value\ndef choose(value: Bit) -> Bit:\n  literal = {BitOne{} : Bit}\n  select(literal, value)\ndef main() -> Bit:\n  choose(BitOne{})\n',accepted:true,output:'BitOne{}'},
   {name:'closed-local-annotation-type-error',source:bit+count+'def wrong(value: Bit) -> Bit:\n  literal = {CZero{} : Bit}\n  value\ndef main() -> Bit:\n  BitOne{}\n',accepted:false,failurePhase:'check'},
   {name:'parallel-local-outer-scope',source:bit+count+'def identity(n: Count) -> Count:\n  n\ndef keep(a: Count, b: Count) -> Count:\n  a\ndef parallel(+n: Count, other: Bit) -> Count:\n  a b = identity(n) identity(n)\n  keep(a, b)\ndef main() -> Count:\n  parallel(CSucc{CZero{}}, BitOne{})\n',accepted:true,output:'CSucc{CZero{}}'},
   {name:'parallel-local-rhs-independence',source:count+'def identity(n: Count) -> Count:\n  n\ndef keep(a: Count, b: Count) -> Count:\n  a\ndef wrong(n: Count) -> Count:\n  a b = identity(n) identity(a)\n  keep(a, b)\ndef main() -> Count:\n  CZero{}\n',accepted:false,failurePhase:'check'},
   {name:'projected-local-erased-domain',source:bit+'def ignore(-x: Bit) -> Bit:\n  BitZero{}\ndef get() -> (@-x: Bit -> Bit):\n  ignore\ndef choose(x: Bit) -> Bit:\n  f = get()\n  unused = f(x)\n  x\ndef main() -> Bit:\n  choose(BitOne{})\n',accepted:true,output:'BitOne{}'},
   {name:'projected-local-affine-domain',source:bit+'def identity(x: Bit) -> Bit:\n  x\ndef get() -> (Bit -> Bit):\n  identity\ndef wrong(x: Bit) -> Bit:\n  f = get()\n  used = f(x)\n  x\ndef main() -> Bit:\n  BitOne{}\n',accepted:false,failurePhase:'check'},
   {name:'projected-local-invalid-annotation',source:bit+count+'def identity(x: Bit) -> Bit:\n  x\ndef wrong(x: Bit) -> Bit:\n  f = {identity : Count -> Bit}\n  unused = f(CZero{})\n  x\ndef main() -> Bit:\n  BitOne{}\n',accepted:false,failurePhase:'check'},
   {name:'dependent-match-wrong-index',source:bits+'def wrong(n: Count) -> Bits(n):\n  match n:\n    case CZero{}: BNil{}\n    case CSucc{p}: BNil{}\ndef main() -> Bits(CZero{}):\n  BNil{}\n',accepted:false,failurePhase:'check'},
  ].filter(fixture=>!o.fixture||fixture.name===o.fixture).map(fixture=>{
   const reportFile=join(sidecars,fixture.name+'.bend');writeFileSync(reportFile,fixture.source,{flag:'wx'});
   let file=reportFile;
   if(diagnosticCache){
    const libraries={'specialization-lib.bend':'import Base\n'+bit+'def identity(~A: Type, x: A) -> A:\n  x\n','alias-name-lib.bend':bit,'scope-left-lib.bend':bit,'scope-right-lib.bend':bit,'string-literal-lib.bend':'import Base\ndef keep(~text: String) -> String:\n  text\n'};
    const directory=join(diagnosticCache,'sources',sha(JSON.stringify({name:fixture.name,source:fixture.source,libraries})));
    mkdirSync(directory,{recursive:true});
    for(const [name,source]of Object.entries({...libraries,[fixture.name+'.bend']:fixture.source})){
     const path=join(directory,name);if(!existsSync(path)||readFileSync(path,'utf8')!==source){diagnosticSourcesRegenerated=true;writeFileSync(path,source);}
    }
    file=join(directory,fixture.name+'.bend');
   }
   return {...fixture,file:realpathSync(file),sourceSha256:sha(fixture.source)};
  });
  if(!fixtures.length)throw Error('Unknown diagnostic fixture: '+o.fixture);
  const request=join(sidecars,'request.json');
  save(request,{...o,limits,sidecars,fixtures,parserSource,rootComposition,sourceFileTag:o.nativeBuild?state.nativeSourceFileTag:state.sourceFileTag,componentSha256:o.nativeBuild?state.nativeSeed!.binarySha256:buildReport(o.componentBuild!).artifactSha256,parserSha256:parserBuild.artifactSha256,rootInputs:o.nativeBuild?state.nativeSeedInputs:loadedInputs,
   ...(o.nativeBuild?{native:{build:o.nativeBuild,buildSha256:hash(o.nativeBuild),binary:state.nativeSeed!.binary,binarySha256:state.nativeSeed!.binarySha256,corpus:state.nativeSeed!.corpus,corpusSha256:state.nativeSeed!.corpusSha256,cPath:state.nativeSeed!.cPath,cSha256:state.nativeSeed!.cSha256,sourceFileTag:state.nativeSourceFileTag}}:{})});
  child=spawn('node',[resolve('evals/selfhost_bootstrap_worker.mjs'),request],{stdio:['pipe','pipe','inherit']});
  const completed=new Promise<number>((done,reject)=>{child!.once('error',reject);child!.once('close',code=>done(code??125));});
  for await(const line of createInterface({input:child.stdout!})){
   const message=object(JSON.parse(line));if(typeof message.phase==='string')phase=message.phase;
   if(message.event==='parse-cache'){
    if(!o.fixture||!Number.isSafeInteger(message.id))throw Error('Diagnostic cache request outside diagnostic gate');
    const row=readCache(message);
    if(row)cacheHits.set(Number(message.id),row);
    events.push({event:'diagnostic-parse-cache',phase,file:message.file,hit:!!row});flush();
    child.stdin!.write(JSON.stringify({id:message.id,approved:true,...(row?{transport:row.transport,transportSha256:row.transportSha256}:{})})+'\n');
    continue;
   }
   if(message.event==='parse-cache-used'){
    const row=cacheHits.get(Number(message.id));if(!row)throw Error('Unapproved diagnostic cache use');
    cacheHits.delete(Number(message.id));parseRows.push(row);flush();continue;
   }
   if(message.event==='parse-cache-rejected'){cacheHits.delete(Number(message.id));events.push(message);flush();continue;}
   if(message.event==='parse'){
    for(const key of ['file','sourceSha256','sourceBytesSha256','parserSha256','transport'])if(typeof message[key]!=='string')throw Error('Malformed compiled parse message: '+key);
    if(!Number.isSafeInteger(message.id))throw Error('Malformed compiled parse message ID');
    const filePath=message.file as string,transportPath=message.transport as string;
    try{
     const file=realpathSync(filePath),source=readFileSync(file,'utf8');
     if(sha(source)!==message.sourceSha256||hash(file)!==message.sourceBytesSha256)throw Error('Source changed during compiled parsing');
     if(state.inputs[file]!==undefined&&state.inputs[file]!==message.sourceBytesSha256)throw Error('Parsed source differs from its authenticated build/input bytes: '+file);
     state.inputs[file]=message.sourceBytesSha256 as string;
     const observe=(event:Record<string,unknown>)=>{events.push({...event,event:event.event==='oracle-profile'?'oracle-profile':'oracle-memory',phase,file});flush();};
     const profiling=!!process.env.SELFHOST_CPU_PROFILE_DIR;
     const request={file,source,transport:transportPath,recordInputs:!!diagnosticCache,...(profiling?{profileContext:{phase,parseId:message.id,sourceBytesSha256:message.sourceBytesSha256,parserSha256:message.parserSha256,report:o.report,compilerWorkerPid:child.pid,diagnosticOnly:!!o.fixture||!!o.parseOnly||o.profileRoot,bootstrapAcceptance:!o.fixture&&!o.parseOnly&&!o.profileRoot}}:{})};
     // Compiler-root files get disposable oracle heaps, not accumulated
     // high-water pages alongside the unchanged native compiler worker.
     const parity=profiling||phase==='stage-one-parse'||phase==='stage-two-parse'
      ?await isolatedParserParity(request,observe)
      :await parserParity(request,oracleBoundary=>observe({oracleBoundary,...process.memoryUsage()}));
     const {stage0ASTHash,compiledASTHash,transportSha256,normalizationLedger,declarations}=parity;
     const row={phase,file,sourceSha256:sha(source),sourceBytesSha256:message.sourceBytesSha256,parserSha256:message.parserSha256,parserFuel:limits.parserFuel,parserFeedback:'FeedbackComplete',oracleAccepted:true,fullSemanticAST:true,transport:transportPath,transportSha256,stage0ASTHash,compiledASTHash,semanticParity:stage0ASTHash===compiledASTHash,normalizationLedger,declarations};
     parseRows.push(row);
     if(!row.semanticParity)throw Error('Complete semantic AST mismatch: '+file);
     if(diagnosticCache){const key=storeCache(message,row,parity.inputFiles,parity.loadContexts);Object.assign(row,{cache:{hit:false,key}});}
     flush();
     child.stdin!.write(JSON.stringify({id:message.id,approved:true,transportSha256})+'\n');
    }catch(error){fail(error,{file:message.file,sourceSha256:message.sourceSha256,transport:message.transport});child.kill('SIGTERM');break;}
   }else if(message.event==='fixture'){fixtureRows.push(message);flush();}
   else if(message.event==='native-run'){state.nativeRun=message;events.push(message);flush();}
   else if(message.event==='artifact'){
    if(typeof message.stage!=='string'||typeof message.path!=='string'||hash(message.path)!==message.sha256)throw Error('Malformed or changed emitted artifact');
    state.inputs[message.path]=String(message.sha256);state.artifacts[message.stage]=message;flush();
   }
   else if(message.event==='result'){const result=object(message.result);if(result.passed!==true&&result.passed!==false)throw Error('Malformed bootstrap result');const firstFailure=state.failure;Object.assign(state,result);if(firstFailure)state.failure=firstFailure;flush();}
   else{events.push(message);flush();}
  }
  const exit=await completed;
  if(exit!==0||state.failure||((o.parseOnly||o.profileRoot)?state.diagnosticPhaseComplete!==true:!state.passed))throw Error('Bootstrap worker failed or did not establish its requested complete boundary');
  if(o.nativeBuild){
   const artifacts=object(state.artifacts),one=object(artifacts.stageOne),two=object(artifacts.stageTwo);
   for(const [artifact,name]of [[one,'stage-one'],[two,'stage-two']] as const){
    if(typeof artifact.path!=='string'||hash(artifact.path)!==artifact.sha256||readFileSync(artifact.path).length!==artifact.bytes)throw Error('Wrong native seed emitted '+name+' image');
   }
   if(!readFileSync(String(one.path)).equals(readFileSync(String(two.path))))throw Error('Native seed fixedpoint failed: stage-one and stage-two bytes differ');
   const seedRows=fixtureRows.filter(row=>row.stage==='seed');
   if(seedRows.length!==95||new Set(seedRows.map(row=>row.name)).size!==95)throw Error('Native stage0 did not execute all original seed fixtures');
   const nativeRun=object(state.nativeRun);
   if(nativeRun.binarySha256!==state.nativeSeed!.binarySha256||nativeRun.buildSha256!==hash(o.nativeBuild))throw Error('Native stage0 run evidence differs from the authenticated build');
  }
  for(const [path,pin]of Object.entries(state.inputs))if(hash(path)!==pin)throw Error('Protected input changed: '+path);
  if(diagnosticCache){
   for(const [path,file]of diagnosticInputRealpaths)if(realpathSync(path)!==file)throw Error('Diagnostic input realpath changed: '+path);
   for(const row of parseRows){
    if(hash(String(row.transport))!==row.transportSha256)throw Error('Diagnostic full-AST transport changed');
    if(row.cache){const cache=object(row.cache);if(cache.hit===true&&hash(String(cache.manifest))!==cache.manifestSha256)throw Error('Diagnostic cached parity proof changed');}
   }
  }
  state.status=o.profileRoot?'ROOT_COMPILER_PROFILE_PASS':o.parseOnly?'ROOT_PARSE_DIAGNOSTIC_PASS':o.fixture?'TEMPLATE_FIXTURE_PASS':o.nativeBuild?'NATIVE_SEED_BOOTSTRAP_FIXEDPOINT':'PURE_STEP_BOOTSTRAP_FIXEDPOINT';state.compilerBootstrapGreen=!o.fixture&&!o.parseOnly&&!o.profileRoot;state.selfhostGreen=false;flush();
 }catch(error){fail(error);child?.kill('SIGTERM');process.exitCode=2;}
}
