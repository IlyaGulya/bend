#!/usr/bin/env bun
// Test-only JS runner for the typed-step library. NOT a production CLI and not
// a shell for a real compiler: the official CLI and the native backend are
// separate targets.
//
// The emitted compiler image is a library of the public step ABI, not a
// process, so this harness drives exactly that ABI (parsed_module/expand/check/
// emit*), supplies the passive List<&2, BIR.SourceFile> bag from the actual
// bytes of the declared `.js` alternatives, and never invents link metadata.
// `--library` asks for the explicit library entry and `--exports=NAME[,NAME]`
// overrides its export set; without them `-o out.js` is the whole-module entry,
// matching the official CLI where `-o out.mjs` selects a library.
//
// usage: bun evals/candidate_host.ts --candidate=PATH [--parser=PATH]
//   [--candidate-build=CANONICAL_NATIVE_BUILD] [--base=PATH] [--library]
//   [--exports=a,b] <input.bend> -o <output>
//   Opt-in diagnostic stage report: [--stage-profile=DIR] [--stage-progress]
//   [--stage-manifest=PATH ...] [--stage-receipt=PATH ...]. Ordinary output and
//   diagnostics are unchanged.
//   Memo candidates can publish their explicit native Data counters with
//   [--memo-report=PATH --memo-binding=AUTHENTICATED_STAGE1_BINDING].
import {createHash} from 'node:crypto';
import {readFileSync,realpathSync,writeFileSync} from 'node:fs';
import {dirname,isAbsolute,posix,resolve} from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {
 sourceFileEntries,sourceFiles,SELFHOST_SOURCE_FILE_TAG,sourceFileTagFromRoot,
 runTemplateSteps,runCheckerSteps,runLibraryEmitterSteps,runEmitterSteps,
 runCEmitterSteps,runCLibraryEmitterSteps,
} from './checker_core_step_runtime.mjs';
import {createStageProfile,createStepAttribution,stageParentDeclaration,loadStageManifests} from './compiler_stage_profile.mjs';

const ROOT=resolve(dirname(fileURLToPath(import.meta.url)),'..');

let stage:any;
let memoProfile:any,memoSaved=false;
function fail(message:string):never{
 try{stage?.fail(message);}catch(error){console.error('candidate: stage profile close failed: '+String(error));}
 console.error('candidate: '+message);
 process.exit(1);
}
// Runtime terms cross from generated JS, so every read is one validated guard.
const objectOf=(value:unknown):Record<string,unknown>|undefined=>
 value!==null&&typeof value==='object'&&!Array.isArray(value)?value as Record<string,unknown>:undefined;
const tag=(value:unknown):string|undefined=>{
 const object=objectOf(value),name=object?.$;
 return typeof name==='string'?name.slice(name.lastIndexOf('.')+1):undefined;
};
function items(value:unknown):unknown[]{
 const out:unknown[]=[];
 for(;;){
  const object=objectOf(value),kind=tag(value);
  if(kind==='Nil')return out;
  if(kind!=='Con'||object===undefined)fail('malformed native list from the candidate');
  out.push(object.head);
  value=object.tail;
 }
}
const list=(values:unknown[]):unknown=>values.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});

function args_parse(){
 const values=new Map<string,string>(),flags=new Set<string>(),positional:string[]=[],manifests:string[]=[],receipts:string[]=[];
 const rest=process.argv.slice(2);
 for(let i=0;i<rest.length;i+=1){
  const arg=rest[i]!;
  if(arg==='--library'||arg==='--stage-progress'){flags.add(arg);continue;}
  if(arg==='-o'){
   const value=rest[++i];
   if(value===undefined||values.has('-o'))fail('-o needs one output path');
   values.set('-o',value);
   continue;
  }
  if(arg.startsWith('--')){
   const at=arg.indexOf('='),name=at<0?arg:arg.slice(0,at),value=at<0?rest[++i]:arg.slice(at+1);
   if(name==='--stage-manifest'||name==='--stage-receipt'){
    if(value===undefined)fail(name+' needs one path');
    (name==='--stage-manifest'?manifests:receipts).push(resolve(value));
    continue;
   }
   if(!['--candidate','--candidate-build','--parser','--base','--exports','--runtime-c','--source-tag','--stage-profile','--checked-out','--sources-out','--work-census','--work-census-binding','--work-census-ms','--memo-report','--memo-binding'].includes(name)||value===undefined||values.has(name))fail('unknown or duplicate option '+arg);
   values.set(name,value);
   continue;
  }
  positional.push(arg);
 }
 if(positional.length!==1)fail('expected exactly one input .bend file');
 if(!values.has('--candidate'))fail('required --candidate=PATH');
 if(values.has('--source-tag')){const sourceTag=values.get('--source-tag')!;if(!sourceTag||/[\r\n\t]/.test(sourceTag))fail('--source-tag needs one nominal constructor tag');}
 if(!values.has('-o'))fail('required -o <output>');
 if(flags.has('--stage-progress')&&!values.has('--stage-profile'))fail('--stage-progress needs --stage-profile=DIR');
 if(values.has('--work-census')&&(!values.has('--stage-profile')||!values.has('--work-census-binding')||manifests.length===0))fail('--work-census needs --stage-profile, --work-census-binding and --stage-manifest');
 if((values.has('--work-census-binding')||values.has('--work-census-ms'))&&!values.has('--work-census'))fail('work census options need --work-census');
 if(values.has('--memo-report')&&(!values.has('--stage-profile')||!values.has('--memo-binding')||manifests.length===0))fail('--memo-report needs --stage-profile, --memo-binding and --stage-manifest');
 if(values.has('--memo-binding')&&!values.has('--memo-report'))fail('--memo-binding needs --memo-report');
 const workCensusMs=Number(values.get('--work-census-ms')??80000);
 if(!Number.isSafeInteger(workCensusMs)||workCensusMs<1||workCensusMs>120000)fail('--work-census-ms must be 1..120000');
 const output=values.get('-o')!;
 return {candidate:resolve(values.get('--candidate')!),parser:values.has('--parser')?resolve(values.get('--parser')!):undefined,
  candidateBuild:values.has('--candidate-build')?resolve(values.get('--candidate-build')!):undefined,
  base:resolve(values.get('--base')??posix.join(ROOT,'bend2/base.bend')),exports:values.get('--exports')?.split(','),
  library:flags.has('--library')||output.endsWith('.mjs'),input:resolve(positional[0]!),output:resolve(output),
  runtimeC:values.has('--runtime-c')?resolve(values.get('--runtime-c')!):undefined,
  sourceTag:values.get('--source-tag'),
  stageProfile:values.has('--stage-profile')?resolve(values.get('--stage-profile')!):undefined,
  checkedOut:values.has('--checked-out')?resolve(values.get('--checked-out')!):undefined,
  sourcesOut:values.has('--sources-out')?resolve(values.get('--sources-out')!):undefined,
  workCensus:values.has('--work-census')?resolve(values.get('--work-census')!):undefined,
  workCensusBinding:values.has('--work-census-binding')?resolve(values.get('--work-census-binding')!):undefined,
  workCensusMs,
  memoReport:values.has('--memo-report')?resolve(values.get('--memo-report')!):undefined,
  memoBinding:values.has('--memo-binding')?resolve(values.get('--memo-binding')!):undefined,
  stageManifests:manifests,stageReceipts:receipts,stageProgress:flags.has('--stage-progress')};
}

const o=args_parse();
const target=o.output.endsWith('.c')?'c':'js';
// Opt-in diagnostic identity. Ordinary runs never touch the collector.
const fileSha=(path:string)=>createHash('sha256').update(readFileSync(path)).digest('hex');
// Carrier identity belongs to the compiler image, never the program it compiles.
// A canonical seed must supply its native build proof; selfhost images retain
// the canonical qualified carrier used by their compiler root.
let sourceTag=SELFHOST_SOURCE_FILE_TAG;
if(o.candidateBuild!==undefined){
 const build=objectOf(JSON.parse(readFileSync(o.candidateBuild,'utf8')));
 if(!build||build.status!=='JS_GENERATED_NOT_YET_EXECUTED'||build.checksExcluded!==0||build.outputPatches!==0||
  build.checkedOutputRetention!=='native e'||typeof build.artifactPath!=='string'||
  realpathSync(build.artifactPath)!==realpathSync(o.candidate)||build.artifactSha256!==fileSha(o.candidate)||
  typeof build.sourcePath!=='string'||build.sourceSha256!==fileSha(build.sourcePath)||
  objectOf(build.guardian)?.status!=='PASS'||typeof build.provenancePath!=='string')
  fail('candidate-build is not this canonical native image');
 const {provenanceSha256,...provenance}=JSON.parse(readFileSync(build.provenancePath,'utf8'));
 if(provenanceSha256!==build.provenanceSha256||
  createHash('sha256').update(JSON.stringify(provenance)).digest('hex')!==provenanceSha256)
  fail('candidate-build provenance changed');
 for(const field of ['protectedPins','loadedInputs']){
  const pins=objectOf(provenance[field]);
  if(!pins||Object.keys(pins).length===0)fail('candidate-build lacks '+field);
  for(const [path,hash]of Object.entries(pins))if(fileSha(path)!==hash)fail('candidate-build input changed: '+path);
 }
 sourceTag=sourceFileTagFromRoot(readFileSync(build.sourcePath,'utf8'),'compiled');
}
if(o.sourceTag!==undefined&&o.sourceTag!==sourceTag)fail('--source-tag differs from the compiler image carrier ('+sourceTag+')');
if(o.stageProfile!==undefined){
 const inputPath=realpathSync(o.input),parserPath=realpathSync(o.parser??o.candidate);
 // Executing script and enclosing-profile declaration are opt-in diagnostics:
 // ordinary runs never read, hash or parse them. A declared parent is validated
 // against that collector run's own run.json by the stage helper.
 let parentProfile:unknown=null;
 try{parentProfile=stageParentDeclaration(process.env.SELFHOST_STAGE_PARENT);}
 catch(error){fail('invalid SELFHOST_STAGE_PARENT: '+String(error));}
 stage=await createStageProfile({
  directory:o.stageProfile,rawDetail:o.stageProgress,manifestPaths:o.stageManifests,
  artifact:{path:realpathSync(o.candidate),sha256:fileSha(o.candidate)},receiptPaths:o.stageReceipts,
  executingScript:fileURLToPath(import.meta.url),
  parentProfile,
  execution:{stage:'selfhost-candidate',mode:'typed-step',target,
   sourcePath:inputPath,sourceSha256:fileSha(inputPath),
   candidatePath:realpathSync(o.candidate),candidateSha256:fileSha(o.candidate),
   parserPath,parserSha256:fileSha(parserPath),
   basePath:realpathSync(o.base),baseSha256:fileSha(o.base),
   sourceFileTag:sourceTag,candidateBuild:o.candidateBuild??null,library:o.library,exports:o.exports??null,outputPath:o.output,
   command:[process.execPath,...process.argv.slice(2)],
   scope:'candidate_host.ts typed-step ABI; source emission only, no external link step'},
 });
 process.on('exit',code=>{
  try{if(stage!==undefined&&!stage.finished)stage.finish(code===0?'completed':'failed',code===0?undefined:'candidate host exited '+code);}
  catch(error){console.error('candidate: stage profile close failed: '+String(error));}
 });
 // Preserve the real exception in the report before Node/Bun prints it and exits.
 process.on('uncaughtExceptionMonitor',error=>{try{stage?.fail(error);}catch{};});
}
const importSpan=stage?.span('startup-import',{candidatePath:o.candidate,parserPath:o.parser??o.candidate});
// Both paths are runtime-selected by the caller, so a static import is impossible.
const candidate=objectOf((await import(pathToFileURL(o.candidate).href)).default);
const requiredStart=target==='c'?'emit_c_modules_start':'emit_modules_start';
const requiredLibraryStart=target==='c'?'emit_c_library_start':'emit_library_start';
if(candidate===undefined||typeof candidate.parsed_module!=='function'||typeof candidate.check_expanded_start!=='function'
 ||typeof candidate[requiredStart]!=='function'||(o.library&&typeof candidate[requiredLibraryStart]!=='function'))
 fail('candidate lacks the typed '+target+' step ABI ('+requiredStart+(o.library?'/'+requiredLibraryStart:'')+')');
const parserModule=o.parser===undefined?candidate:objectOf((await import(pathToFileURL(o.parser).href)).default);
if(typeof parserModule?.parse_with_fuel!=='function')fail('no compiled parser: pass --parser=PATH or export parse_with_fuel');
stage?.end(importSpan!,'completed',{target,library:o.library,parserModule:o.parser===undefined?'candidate':'separate'});
if(o.memoReport!==undefined)await initializeMemoObserver();

let parsedSources=0,fuelCells=0,sourceBytes=0;
function parse(file:string,source:string):Record<string,unknown>{
 const fuelSpan=o.stageProgress?stage?.span('parse-fuel-construct',{file,summary:false}):undefined;
 let fuel:unknown={$:'FeedbackFuelEnd'};
 for(let i=0;i<8000000;i+=1)fuel={$:'FeedbackFuelCell',tail:fuel};
 if(fuelSpan!==undefined)stage!.end(fuelSpan,'completed',{cells:8000000});
 if(stage!==undefined){parsedSources+=1;fuelCells+=8000000;sourceBytes+=Buffer.byteLength(source);}
 const parserSpan=o.stageProgress?stage?.span('parse-module-call',{file,summary:false}):undefined;
 const feedback=objectOf(parserModule!.parse_with_fuel(fuel,file,source));
 if(parserSpan!==undefined)stage!.end(parserSpan,'completed',{feedback:tag(feedback)});
 if(tag(feedback)!=='FeedbackComplete')fail('parser feedback did not complete for '+file);
 const result=objectOf(objectOf(feedback?.value)?.result);
 if(tag(result)!=='ParseSuccess')fail('parser rejected '+file+': '+String(result?.message??tag(result)));
 const module=objectOf(result?.module);
 if(module===undefined)fail('parser returned no module for '+file);
 return module;
}
const namespace_of=(parent:string,path:string):string=>
 path==='Base'?'':posix.normalize(isAbsolute(path)?path.replace(/\.bend$/,''):posix.dirname(parent)+'/'+path.replace(/\.bend$/,''));

// The declared target alternative is BIR metadata: the host reads exactly the
// path BIR resolves from it. Real read failures stay failures that name it.
const files:unknown[]=[];
const modules:unknown[]=[];
const seen=new Set<string>();
const moduleScopes=o.workCensus===undefined?undefined:new Map<string,string>();
const inputFile=realpathSync(o.input);
let rootModule:Record<string,unknown>|undefined;
function visit(file:string,scope:string){
 const at=realpathSync(file);
 if(seen.has(at))return;
 seen.add(at);
 moduleScopes?.set(at,scope);
 const fileSpan=o.stageProgress?stage?.span('parse-file',{file:at,summary:false}):undefined;
 const module=parse(at,readFileSync(at,'utf8'));
 if(fileSpan!==undefined)stage!.end(fileSpan,'completed',{file:at});
 if(at===inputFile)rootModule=module;
 for(const top of items(module.declarations)){
  const definition=objectOf(objectOf(top)?.definition);
  if(tag(definition?.body)!=='DefImports')continue;
  for(const declared of items(objectOf(definition?.body)?.paths)){
   if(typeof declared==='string'&&declared.endsWith('.'+target)){
    try{files.push(...sourceFileEntries(at,[declared]));}
    catch(error){fail('cannot read declared .'+target+' target '+declared+' of '+at+': '+String(error));}
   }
  }
 }
 for(const imported of items(module.imports)){
  const path=objectOf(imported)?.path;
  if(typeof path!=='string'||/^0x[0-9a-f]+\//.test(path))fail('malformed import in '+at);
  if(path.endsWith('.js')||path.endsWith('.c'))continue;
  visit(path==='Base'?o.base:resolve(dirname(at),path),namespace_of(scope,path));
 }
 modules.push(candidate!.parsed_module(scope,module));
}
const parseSpan=stage?.span('parse-import-fuel',{input:o.input,target});
visit(o.input,'');
stage?.end(parseSpan!,'completed',{modules:modules.length,foreignFiles:files.length});
stage?.record({kind:'phase-exact-counters',scope:'candidate host',name:'parse-import-fuel',
 values:{modules:modules.length,parses:parsedSources,fuelCells,sourceBytes,foreignFiles:files.length,parserFuelCellsPerParse:8000000},
 unitsByField:{modules:'modules',parses:'parses',fuelCells:'fuel-cells',sourceBytes:'bytes',foreignFiles:'files',parserFuelCellsPerParse:'fuel-cells'},
 source:'candidate_host.ts',details:{phase:'parse-import-fuel',
  note:'one eager parser feedback chain per parsed module; fuelCells is the exact constructed cell count, not semantic fuel consumed'}});
const bag=sourceFiles(files,sourceTag);
let workCensus:any,demandCapture:any,workCpu:any,workCensusSaved=false,workObserverWallMs=0;
let queryCensus:any,queryRunTag:string|undefined,queryCaptures:Map<string,any>|undefined;
let isWorkCensusStop:(error:unknown)=>boolean=()=>false;
function saveWorkCensus(error?:unknown){
 if(workCensus===undefined||workCensusSaved)return;
 const intentional=isWorkCensusStop(error);
 writeFileSync(o.workCensus!,JSON.stringify({schemaVersion:1,acceptanceEvidence:false,
  status:intentional?'INTENTIONAL_DIAGNOSTIC_STOP':error===undefined?'COMPLETED':'ERROR',
  error:error===undefined?null:String(error),workObserverWallMs,cpuProfileDirectory:o.workCensus+'.profiles',
  observerTimeScope:'measured callback wall, including census analysis; overlaps compiler phase spans',
  work:workCensus.report(),demand:demandCapture.report(),
  ...(queryCensus===undefined?{}:{queries:queryCensus.report()})},null,2)+'\n',{flag:'wx'});
 workCensusSaved=true;
}
function observeSemanticQuery(run:any){
 if(queryCensus===undefined||run?.$!==queryRunTag)return;
 const capture=queryCaptures!.get(run.payload?.$);
 if(capture===undefined)return;
 // Work census already validated this same single-event Span against its
 // authenticated trace table; match the passive data to that exact Begin.
 const event=run.events.head;
 if(event.$!==capture.beginTag||event.site!==capture.site)throw Error('query payload is not on its authenticated Begin boundary');
 queryCensus.observe(capture.kind,run.payload,capture.provenance);
}
function workObserver(attributes:any){
 if(workCensus===undefined)return attributes;
 return {
  onStep(step:number,run:unknown){
   const started=performance.now();
   try{attributes?.onStep?.(step,run);demandCapture.observeRun(run);workCensus.onStep(step,run);observeSemanticQuery(run);}
   finally{workObserverWallMs+=performance.now()-started;}
  },
  onFinish(value:unknown,steps:number){attributes?.onFinish?.(value,steps);workCensus.onFinish(value,steps);},
  onError(error:unknown,steps:number){attributes?.onError?.(error,steps);workCensus.onError(error,steps);},
 };
}

async function initializeMemoObserver(){
 const {authenticateCensusBinding}=await import('./compiler_demand_diagnostic.mjs');
 const binding=authenticateCensusBinding(o.memoBinding!);
 if(binding.artifactPath!==realpathSync(o.candidate)||binding.artifactSha256!==fileSha(o.candidate))fail('memo binding belongs to another native compiler image');
 const manifests=o.stageManifests.map(path=>({path,document:JSON.parse(readFileSync(path,'utf8'))}))
  .filter(row=>row.document.semanticMemo!==undefined);
 if(manifests.length!==1)fail('memo report requires exactly one semantic-memo generation manifest');
 const {path,document}=manifests[0]!,{generationManifestSha256,...proof}=document;
 if(generationManifestSha256!==createHash('sha256').update(JSON.stringify(proof)).digest('hex'))fail('memo generation manifest self-authentication failed');
 const output=document.generationConfig?.output,hash=document.outputs?.[output];
 if(typeof output!=='string'||typeof hash!=='string'||fileSha(output)!==hash||binding.loadedInputs[realpathSync(output)]!==hash)fail('memo engine source is not bound to the native-produced image');
 const memo=document.semanticMemo,report=memo.report;
 const fields=['nf_hits','nf_misses','reach_hits','reach_misses','nf_entries','reach_entries','interned','scopes','disabled'];
 if(document.progressABI!=='typed-native-stack-v58m'||memo.protocolVersion!==1||memo.quantum!==64
  ||report?.runField!=='memo'||report.runConstructor!==document.nativeChunk.runFinishedConstructor
  ||report.kind!=='Data'||report.retainsStore!==false||typeof report.constructor!=='string'
  ||!Array.isArray(report.fields)||report.fields.length!==fields.length
  ||report.fields.some((row:any,index:number)=>row.name!==fields[index]||row.type!=='Nat'))fail('memo report native Data schema drift');
 memoProfile={artifactSha256:binding.artifactSha256,bindingPath:o.memoBinding,bindingSha256:fileSha(o.memoBinding!),
  manifestPath:path,manifestSha256:fileSha(path),generationManifestSha256,constructor:report.constructor,fields};
}

function memoObserver(attributes:any){
 if(o.memoReport===undefined)return attributes;
 return {...attributes,onMemo(report:unknown,steps:number){
  if(memoSaved)fail('memo engine published more than one final report');
  const value=objectOf(report),constructor=value?.$;
  if(typeof constructor!=='string'||!(constructor===memoProfile.constructor||constructor.endsWith('.'+memoProfile.constructor)))fail('memo report constructor differs from the authenticated native schema');
  const counts:Record<string,string>={};
  for(const field of memoProfile.fields){
   const descriptor=Object.getOwnPropertyDescriptor(value!,field),count=descriptor?.value;
   if(!descriptor||!Object.hasOwn(descriptor,'value')
    ||!(typeof count==='bigint'&&count>=0n||typeof count==='number'&&Number.isSafeInteger(count)&&count>=0))fail('memo report counter is not native Nat Data: '+field);
   counts[field]=String(count);
  }
  writeFileSync(o.memoReport!,JSON.stringify({schemaVersion:1,kind:'native-owned-semantic-query-report',acceptanceEvidence:false,
   ...memoProfile,constructor,steps,counts},null,2)+'\n',{flag:'wx'});
  memoSaved=true;
 }};
}

// One attributed phase: a real span plus exact host-step counters and sampled
// typed progress. A thrown step error still closes the span failed and records
// the samples observed before it.
function attributedPhase(name:string,protocol:string,inputs:Record<string,unknown>,run:(observe:unknown)=>unknown,success:(value:unknown)=>boolean):unknown{
 if(stage===undefined)return run(undefined);
 // Census owns bounded trace aggregates; do not duplicate every NF bracket
 // into the general collector's retained per-call span list.
 const attributes=protocol==='Emitter'&&workCensus!==undefined?undefined:createStepAttribution(name,protocol,stage.manifestTable,stage.profile);
 const token=stage.span(name,inputs);
 if(protocol==='Emitter')workCpu?.mark('emit',inputs);
 let value:unknown;
 try{value=run(protocol==='Emitter'?memoObserver(workObserver(attributes)):attributes);}
 catch(error){
  if(protocol==='Emitter')workCpu?.finish(error);
  stage.end(token,isWorkCensusStop(error)?'aborted':'failed',{error:String(error)});attributes?.record(stage.profile);saveWorkCensus(error);
  if(isWorkCensusStop(error)){
   stage.finish('aborted',error);
   console.log(JSON.stringify({status:'INTENTIONAL_DIAGNOSTIC_STOP',acceptanceEvidence:false,report:o.workCensus}));
   process.exit(0);
  }
  throw error;
 }
 if(protocol==='Emitter')workCpu?.finish();
 const ok=success(value),message=String(objectOf(objectOf(value)?.diagnostic)?.message??objectOf(value)?.message??tag(value));
 stage.end(token,ok?'completed':'failed',{result:tag(value),...(ok?{}:{error:message})});
 attributes?.record(stage.profile);
 return value;
}

function checkedProgram():unknown{
 const loaded=list(modules);
 const expanded=attributedPhase('template-expand','Template',{inputModules:modules.length},
  observe=>typeof candidate!.expand_modules_start==='function'?runTemplateSteps(candidate,loaded,observe):{$:'ExpandSuccess',modules:loaded},
  value=>tag(value)==='ExpandSuccess');
 if(tag(expanded)!=='ExpandSuccess')fail('template expansion failed: '+String(objectOf(expanded)?.message??''));
 const checked=attributedPhase('check-signature-body','Checker',{inputModules:modules.length},
  observe=>runCheckerSteps(candidate,objectOf(expanded)?.modules,observe),
  value=>tag(value)==='CheckSuccess');
 if(tag(checked)!=='CheckSuccess')fail('checking failed: '+String(objectOf(objectOf(checked)?.diagnostic)?.message??''));
 return objectOf(checked)?.program;
}

// The host cannot re-derive the official CLI's type-based IO filter from a
// syntax tree, so the default library export set is every term-bodied
// definition this module declares, in source order; --exports overrides it.
function declaredExports():string[]{
 const keys:string[]=[];
 for(const top of items(rootModule?.declarations)){
  const definition=objectOf(objectOf(top)?.definition);
  if(tag(top)==='DefTop'&&typeof definition?.key==='string'&&tag(definition.body)==='DefTerm')keys.push(definition.key);
 }
 return keys;
}

const program=checkedProgram();
if(o.checkedOut)writeFileSync(o.checkedOut,JSON.stringify(program));
if(o.sourcesOut)writeFileSync(o.sourcesOut,JSON.stringify(files));
const exports=o.exports??declaredExports();
let runtime:string|undefined;
if(target==='c'){
 try{runtime=readFileSync(o.runtimeC,'utf8');}
 catch(error){fail('cannot read C runtime '+o.runtimeC+': '+String(error));}
}
if(o.workCensus!==undefined){
 const [{authenticateCensusBinding},{createWorkCensus,isWorkCensusStop:stopped},{createDemandCapture}]=await Promise.all([
  import('./compiler_demand_diagnostic.mjs'),import('./compiler_work_census.mjs'),import('./compiler_demand_census.mjs')]);
 const binding=authenticateCensusBinding(o.workCensusBinding!);
 if(binding.artifactPath!==realpathSync(o.candidate)||binding.artifactSha256!==fileSha(o.candidate))fail('work census binding belongs to another compiler image');
 const table=loadStageManifests(o.stageManifests,{artifactSha256:binding.artifactSha256,receipt:binding});
 const documents=o.stageManifests.map(path=>JSON.parse(readFileSync(path,'utf8')));
 const traced=documents.filter(document=>document.trace?.programCapture!==undefined);
 if(traced.length!==1||traced[0].trace.programCapture.birImport!=='../bend2/selfhost/backend_ir.bend')fail('work census needs one authenticated passive BIR.Program carrier');
 const requestManifests=documents.flatMap(document=>{
  const output=document.generationConfig?.output;
  if(typeof output!=='string')return [];
  const path=resolve(ROOT,output),namespace=moduleScopes?.get(path);
  if(namespace===undefined)return [];
  if(document.outputs?.[output]!==fileSha(path))fail('request census manifest differs from the actual imported module');
  return [{document,namespace}];
 });
 workCensus=createWorkCensus({table,maxSteps:1000000000,maxWallMs:o.workCensusMs,sampleEvery:1024});
 demandCapture=createDemandCapture({manifest:table,programCapture:traced[0].trace.programCapture,
  birProgramTag:sourceTag.slice(0,-'SourceFile'.length)+'Program',
  producerIdentity:binding.artifactSha256,inputSha256:fileSha(o.input),
  analysisOptions:{maxNodes:8000000,maxEdges:4000000,requestManifests}});
 const querySpecs=traced[0].trace.queryCaptures;
 if(querySpecs!==undefined){
  const trace=table.traceTables.find((row:any)=>row.status==='verified');
  if(!trace||typeof trace.namespace!=='string'||!Array.isArray(querySpecs)||querySpecs.length!==2)fail('query census needs one verified native trace and both query schemas');
  const {createQueryCensus}=await import('./compiler_query_census.mjs');
  queryCensus=createQueryCensus({immutableData:true,maxNodes:500000,maxQueries:100000,maxBytes:134217728,maxWorkPerQuery:16000000});
  queryRunTag=trace.constructors.run;queryCaptures=new Map();
  const kinds=new Set<string>();
  for(const capture of querySpecs){
   const fields=capture.kind==='nf'?['context','descriptor','env','level','fuel']
    :capture.kind==='reach'?['context','descriptor','env','target','seen','fuel']:undefined;
   const root=trace.roots.find((row:any)=>row.site===capture.site&&row.status==='verified');
   const source=capture.kind==='nf'?'bend2/selfhost/descriptor_nf.bend':'bend2/selfhost/c_backend_layout.bend';
   const name=capture.kind==='nf'?'nf':'reaches';
   if(!fields||kinds.has(capture.kind)||capture.runField!=='payload'||typeof capture.constructor!=='string'
    ||!root||root.source!==source||root.canonicalName!==name
    ||!Array.isArray(capture.fields)||capture.fields.length!==fields.length
    ||capture.fields.some((field:any,index:number)=>field.name!==fields[index]||field.argument!==index))fail('query census source schema drift');
   kinds.add(capture.kind);
   const tag=trace.namespace+'.'+capture.constructor;
   if(queryCaptures.has(tag))fail('duplicate query payload constructor');
   queryCaptures.set(tag,{kind:capture.kind,site:capture.site,beginTag:trace.constructors.begin,
    provenance:{artifactSha256:binding.artifactSha256,generationManifestSha256:trace.generationManifestSha256,
     site:capture.site,source:root.source,canonicalName:root.canonicalName,
     canonicalDeclarationSha256:root.canonicalDeclarationSha256}});
  }
 }
 isWorkCensusStop=stopped;
 const {createCpuProfiler}=await import('./selfhost_cpu_profile.mjs');
 workCpu=createCpuProfiler(o.workCensus+'.profiles',{stage:'bounded-emitter-work-census',candidateSha256:binding.artifactSha256,acceptanceEvidence:false});
 process.on('exit',code=>{if(!workCensusSaved)saveWorkCensus(code===0?undefined:Error('candidate host exited '+code));});
}
const emitted=attributedPhase('emit','Emitter',{target,library:o.library,exports:o.library?exports.length:null},
 observe=>target==='c'
  ? o.library
   ? runCLibraryEmitterSteps(candidate,program,list(exports),runtime!,bag,observe)
   : runCEmitterSteps(candidate,program,runtime!,bag,observe)
  : o.library
   ? runLibraryEmitterSteps(candidate,program,list(exports),bag,observe)
   : runEmitterSteps(candidate,program,bag,observe),
 value=>tag(value)==='EmitSuccess');
if(tag(emitted)!=='EmitSuccess')fail('emission failed: '+String(objectOf(emitted)?.message??''));
if(o.memoReport!==undefined&&!memoSaved)fail('memo engine finished without its declared Data report');
saveWorkCensus();
const source=objectOf(emitted)?.source;
if(typeof source!=='string')fail('emission returned no source');
const outputSpan=stage?.span('output-write',{output:o.output,bytes:Buffer.byteLength(source)});
const digest=createHash('sha256').update(source).digest('hex');
writeFileSync(o.output,source);
stage?.end(outputSpan!,'completed',{output:o.output,bytes:Buffer.byteLength(source)});
stage?.record({kind:'phase-exact-counters',scope:'candidate host',name:'output-write',
 values:{bytes:Buffer.byteLength(source),modules:modules.length,foreignFiles:files.length},
 unitsByField:{bytes:'bytes',modules:'modules',foreignFiles:'files'},
 source:'candidate_host.ts',details:{phase:'output-write',note:'bytes are the emitted source size; the hash is content identity, not a performance metric'}});
if(stage!==undefined)stage.finish('completed');
const result:Record<string,unknown>={output:o.output,bytes:Buffer.byteLength(source),sha256:digest,target,library:o.library,exports:o.library?exports:undefined,modules:seen.size,foreignFiles:files.length,runtime:target==='c'?o.runtimeC:undefined};
if(stage!==undefined)result.stageProfile=stage.reportPath;
console.log(JSON.stringify(result));
