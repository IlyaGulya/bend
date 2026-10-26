#!/usr/bin/env bun
/**
 * Build: bun --smol evals/native_compiler_experiment.ts --mode=build
 *   --corpus=MANIFEST.json --artifact=FRESH_BINARY --report=FRESH.json
 *   [--v8-log-dir=FRESH_DIRECTORY] (build-only statistical sampling diagnostic)
 *   [--build-timeout-ms=90000] (build-only downward bound; default/max600000)
 *   [--trace-c=true] (per-pass/definition/spin/cache profiling; off by default)
 *   [--cc-pipeline=direct|llvm-split] (build-only; direct by default, no fallback)
 *   [--llvm-bin=PATH] (split-only opt/llvm-split directory; otherwise use PATH)
 *   [--cc-opt=0|1|2|3] (direct defaults3; split defaults/requires1)
 *   [--profile-dir=FRESH_DIR] (opt-in diagnostic scoped profile)
 *   [--profile-raw=true] (also stream fine-grain events.jsonl)
 *   [--profile-sampling=true] (V8 inspector CPU1ms/allocation4MiB per sampled span)
 *
 * llvm-split requires Darwin arm64, Apple clang21 selected by CC, matching
 * LLVM21 opt/llvm-split and the macOS SDK (SDKROOT or xcrun). It emits raw
 * bitcode at O1 without LLVM passes, runs mem2reg/always-inline and the normal
 * CGSCC inliner, splits four ways, then runs at most three O1 backend children
 * and links normally. Source/ABI/target/tool facts and Darwin time -lp
 * CPU/maxRSS receipts are preserved per stage. The same outer8GiB/10ms/600s
 * guardian includes all children; separate codegen exits before the backend.
 * The whole-build guardian timer includes fresh validation/codegen. Pipeline
 * and per-stage timers cover only the backend, not a complete producer cycle.
 * This is an explicit compilation tradeoff, not official-default flags or a
 * fixedpoint proof. Selecting direct still invokes the original single-TU CC.
 * Run: bun --smol evals/native_compiler_experiment.ts --mode=run
 *   --corpus=MANIFEST.json --build=BUILD.json --report=FRESH.json
 *   [--phase=check|compile|compile-c|compile-c-module] [--threads=1]
 *   [--exports=EXPORTS.json] [--runtime-c=RUNTIME.c]
 *   [--expect-js=ACCEPTED_COMPILER.js]
 *
 * Both commands acquire the existing heavy_gate lease. Build uses the unchanged
 * canonical kernel, validates every body in the compiler root and host bridge,
 * then calls compile_book and clang (official CPU flags by default). Run
 * freshly reads the entire frozen corpus and uses only Bend parsing/expansion/
 * checking/emission. C owns IO/import loading and opaque native Run chunk
 * orchestration, outside Bend's totality proof. No ASTs are serialized or cached.
 * A byte-identical accepted JS image is an optional semantic smoke, not a native
 * binary bootstrap/fixedpoint proof. Multithread results are separate runs.
 * Low-volume NATIVE_BUILD_PROGRESS boundaries are persisted synchronously to
 * REPORT.events.jsonl and REPORT.progress.json before each blocking phase.
 * Guardian/interrupt failures preserve that last phase in the main report.
 */
import {createHash} from 'node:crypto';
import {appendFileSync, closeSync, existsSync, mkdirSync, openSync, readFileSync, readdirSync, realpathSync, writeFileSync} from 'node:fs';
import {dirname, join, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawn} from 'node:child_process';
import {Worker, isMainThread, workerData} from 'node:worker_threads';
import {runHeavyGate, guardHeavyGate} from './heavy_gate.ts';
import {officialKernelSha256} from './release_identity.ts';
import {requireCorpusCoversWorkload, workloadRows, corpusFor, runtimeManifest} from './native_seed_runtime.mjs';
import type * as Bend from '../bend2/bend.ts';
import type * as Comp from '../bend2/comp.ts';

const script = fileURLToPath(import.meta.url), root = resolve(dirname(script), '..');
const kernelPath = join(root, 'bend2/bend.ts'), compilerPath = join(root, 'bend2/comp.ts');
const bridge = join(root, 'evals/native_compiler_driver.bend');
const kernelSha256 = officialKernelSha256(root);
// Historical accepted emitted image for --expect-js fixedpoint comparisons;
// it identifies one accepted v40 artifact, never the current compiler source.
const acceptedCompilerSha256 = '84b19ce89aad6da90b1aedb7b8fff2ed8ef659636754801c91290424c19a7da2';
const compilerABI=['parsed_module','parse_with_fuel','expand_modules_start','template_step','check_expanded_start','inspect_checked_start','checker_step','emit_modules_start','emit_library_start','emitter_step','emit_c_modules_start','emit_c_library_start','c_emitter_step'];
const frozenV41CorpusSha256='29a28b1d03966fbc923e592fccdb8b774666d38162bea5c12d33a5a1e6c4b258';
const guard = {memoryMiB:8192, rssMiB:8192, pollMs:10, timeoutMs:600000};
const boundary = {host:'trusted C file/import loader and serial opaque native Run chunk driver',
  sourceAlgorithms:'unchanged canonical Bend parser/expansion/checker/JS library emitter',
  hostChecking:false, hostParsing:false, embeddedSource:false, cachedAst:false,
  parserFuelRepresentation:'eager native 8M-cell chain per source; JS harness uses lazy cells for the same finite fuel; allocation time remains included in parse',
  fuelMemoryEvidence:'per-source native process RSS high-water before/after allocation (not isolated live-byte attribution); guardian samples whole-tree RSS and physical footprint including fuel',
  outputPatches:0, checksExcluded:0, nativeBinaryBootstrap:false};
const sha = (value:string|Uint8Array) => createHash('sha256').update(value).digest('hex');
const hash = (path:string) => sha(readFileSync(path));
const json = (path:string) => JSON.parse(readFileSync(path,'utf8'));
const save = (path:string, value:unknown) => writeFileSync(path, JSON.stringify(value,null,2)+'\n');
const create = (path:string, value:string) => writeFileSync(path,value,{flag:'wx'});
let canonicalKernel:typeof Bend|undefined;
let reportWritable=false;
type CorpusFile = {path:string;sha256:string;namespace?:string;external?:boolean};
type Corpus = {directory:string;root:string;exports:string[];files:CorpusFile[]};
type Options = {mode:string;corpus:string;report:string;artifact?:string;build?:string;
  phase:string;threads:number;exports?:string;runtimeC?:string;expectJs?:string;internal?:string;v8LogDir?:string;buildTimeoutMs:number;traceC:boolean;ccOpt:number;
  ccPipeline:'direct'|'llvm-split';llvmBin?:string;profileDir?:string;profileRaw:boolean;profileSampling:boolean};
type ProfileToken = {id:number;name:string};
type ProfileSpan = {id:number;name:string;status:string;wallMs:number;parentId:number|null};
type CompileBookObserver = {observe:(stage:string,name:string,state:Record<string,unknown>)=>void;readonly passes:number;readonly releases:number};
type CompilerProfile = {
  runDirectory:string;reportPath:string;rawDetail:boolean;
  begin(name:string,details?:Record<string,unknown>,options?:{sample?:boolean}):ProfileToken;
  end(token:ProfileToken,status?:string,details?:Record<string,unknown>):ProfileSpan;
  abortOpen(status?:string,details?:Record<string,unknown>,options?:{keep?:ProfileToken}):number;
  record(observation:Record<string,unknown>):{id:number};
  finish(status?:string,error?:unknown):Record<string,unknown>;
};
function options():Options {
  const flags = new Map<string,string>();
  for (const arg of process.argv.slice(2)) {
    const at=arg.indexOf('='), key=arg.slice(0,at), value=arg.slice(at+1);
    if(at<0||!['--mode','--corpus','--report','--artifact','--build','--phase','--threads','--exports','--runtime-c','--expect-js','--internal','--v8-log-dir','--build-timeout-ms','--trace-c','--cc-opt','--cc-pipeline','--llvm-bin','--profile-dir','--profile-raw','--profile-sampling'].includes(key)||!value||flags.has(key))throw Error('Expected unique documented --option=value');
    flags.set(key,value);
  }
  for(const key of ['--mode','--corpus','--report'])if(!flags.has(key))throw Error('Missing '+key);
  const mode=flags.get('--mode')!,phase=flags.get('--phase')??'compile',threads=Number(flags.get('--threads')??'1');
  const cPhase=phase.startsWith('compile-c');
  if(!['build','run'].includes(mode)||!['check','compile','compile-c','compile-c-module'].includes(phase)||!Number.isInteger(threads)||threads<1||threads>128)throw Error('Invalid mode, phase, or supported thread count (1..128)');
  if(mode==='build'&&!flags.has('--artifact')||mode==='run'&&!flags.has('--build'))throw Error('Build requires --artifact; run requires --build');
  if(flags.has('--expect-js')&&(mode!=='run'||phase!=='compile'||flags.has('--exports')))throw Error('--expect-js is an explicit frozen v40 full-compile smoke only');
  if(flags.has('--runtime-c')&&(mode!=='run'||!cPhase))throw Error('--runtime-c is run-only and C-phase-only');
  if(mode==='run'&&cPhase&&!flags.has('--runtime-c'))throw Error('A native C phase requires --runtime-c');
  if(flags.has('--v8-log-dir')&&mode!=='build')throw Error('--v8-log-dir is build-only and not a benchmark timing');
  const buildTimeoutMs=Number(flags.get('--build-timeout-ms')??'600000');
  if(!Number.isSafeInteger(buildTimeoutMs)||buildTimeoutMs<1||buildTimeoutMs>600000||flags.has('--build-timeout-ms')&&mode!=='build')throw Error('--build-timeout-ms is build-only and may only lower the 600000 ms deadline');
  if(flags.has('--trace-c')&&(mode!=='build'||flags.get('--trace-c')!=='true'))throw Error('--trace-c=true is a build-only diagnostic');
  const profileDir=flags.has('--profile-dir')?resolve(flags.get('--profile-dir')!):undefined;
  for(const name of ['--profile-raw','--profile-sampling'])
    if(flags.has(name)&&(flags.get(name)!=='true'||!profileDir))throw Error(name+'=true requires --profile-dir and is an opt-in diagnostic');
  if(flags.has('--cc-opt')&&(mode!=='build'||!/^[0-3]$/.test(flags.get('--cc-opt')!)))throw Error('--cc-opt is build-only and must be 0, 1, 2 or 3');
  const ccPipeline=flags.get('--cc-pipeline')??'direct';
  if(!['direct','llvm-split'].includes(ccPipeline)||flags.has('--cc-pipeline')&&mode!=='build')throw Error('--cc-pipeline=direct|llvm-split is build-only');
  if(flags.has('--llvm-bin')&&(mode!=='build'||ccPipeline!=='llvm-split'))throw Error('--llvm-bin requires a build with --cc-pipeline=llvm-split');
  const ccOpt=Number(flags.get('--cc-opt')??(ccPipeline==='llvm-split'?'1':'3'));
  if(ccPipeline==='llvm-split'&&ccOpt!==1)throw Error('--cc-pipeline=llvm-split requires --cc-opt=1');
  const path=(name:string)=>flags.has(name)?resolve(flags.get(name)!):undefined;
  return {mode,corpus:path('--corpus')!,report:path('--report')!,artifact:path('--artifact'),build:path('--build'),phase,threads,exports:path('--exports'),runtimeC:path('--runtime-c'),expectJs:path('--expect-js'),internal:flags.get('--internal'),v8LogDir:path('--v8-log-dir'),buildTimeoutMs,traceC:flags.has('--trace-c'),ccOpt,ccPipeline:ccPipeline as Options['ccPipeline'],llvmBin:path('--llvm-bin'),profileDir,profileRaw:flags.get('--profile-raw')==='true',profileSampling:flags.get('--profile-sampling')==='true'};
}
function corpus(path:string):Corpus {
  const manifest=json(path) as Corpus;
  const frozen=hash(path)===frozenV41CorpusSha256;
  const expectedABI=frozen?compilerABI.filter(name=>name!=='inspect_checked_start'):compilerABI;
  if(!Array.isArray(manifest.files)||!manifest.files.length||frozen&&manifest.files.length!==50||!Array.isArray(manifest.exports)||JSON.stringify(manifest.exports)!==JSON.stringify(expectedABI))throw Error('Expected complete compiler corpus and exact public ABI (historical v41 requires its captured manifest hash)');
  manifest.directory=realpathSync(manifest.directory);
  const seen=new Set<string>();
  for(const row of manifest.files){
    const path=realpathSync(resolve(manifest.directory,row.path));
    if(!path.startsWith(manifest.directory+'/')||seen.has(path)||hash(path)!==row.sha256||/[\t\r\n]/.test(path+(row.namespace??'')))throw Error('Frozen corpus drift or invalid row: '+row.path);
    if(row.external!==true&&typeof row.namespace!=='string')throw Error('Source row lacks namespace');
    seen.add(path);
  }
  if(!manifest.files.some(row=>row.path===manifest.root&&row.namespace===''))throw Error('Root missing from manifest');
  return manifest;
}
function pins(o:Options):Record<string,string>{
  const paths=[script,join(root,'evals/native_compiler_llvm.ts'),kernelPath,compilerPath,bridge,join(root,'evals/native_compiler_host.c'),join(root,'bend2/base.bend'),join(root,'evals/heavy_gate.ts'),join(root,'evals/heavy_gate_native.c'),o.corpus];
  const result=Object.fromEntries(paths.map(path=>[realpathSync(path),hash(path)]));
  if(hash(kernelPath)!==kernelSha256)throw Error('Canonical kernel pin mismatch');
  return result;
}
function verify(expected:Record<string,string>){for(const [path,digest]of Object.entries(expected))if(hash(path)!==digest)throw Error('Protected input changed: '+path);}
async function child(command:string,args:string[],onLine?:(line:string)=>void):Promise<{pid:number|undefined}>{
  const process_=spawn(command,args,{stdio:['ignore','pipe','pipe']});
  const childPid=process_.pid;
  let stdout='',stderr='';
  const consume=(chunk:Buffer,which:'stdout'|'stderr')=>{
    process[which].write(chunk);
    if(which==='stdout')stdout+=chunk.toString();else stderr+=chunk.toString();
    let pending=which==='stdout'?stdout:stderr;
    for(;;){const at=pending.indexOf('\n');if(at<0)break;onLine?.(pending.slice(0,at));pending=pending.slice(at+1);}
    if(which==='stdout')stdout=pending;else stderr=pending;
  };
  process_.stdout.on('data',(chunk:Buffer)=>consume(chunk,'stdout'));
  process_.stderr.on('data',(chunk:Buffer)=>consume(chunk,'stderr'));
  await new Promise<void>((yes,no)=>{process_.once('error',no);process_.once('close',(code,signal)=>code===0?yes():no(Error(command+' failed: '+String(code)+' '+String(signal))));});
  if(stdout)onLine?.(stdout);if(stderr)onLine?.(stderr);
  return {pid:childPid};
}
function jsonRecord(text:string):Record<string,unknown>{
  const value:unknown=JSON.parse(text);
  if(!value||typeof value!=='object'||Array.isArray(value))throw Error('Expected native protocol object');
  return value as Record<string,unknown>;
}
function optionalPin(path:string|undefined):{path:string;sha256:string|null}|null{
  return path?{path,sha256:existsSync(path)?hash(path):null}:null;
}
async function openProfile(o:Options,stage:string,execution:Record<string,unknown>):Promise<CompilerProfile|undefined>{
  if(!o.profileDir)return undefined;
  // The collector is deliberately a runtime-selected diagnostic module: a
  // static import would load inspector plumbing into every no-profile build
  // and into the Bun supervisor, changing the ordinary path this feature must
  // leave untouched.
  const {createCompilerProfile}=await import('./compiler_profile.mjs') as {
    createCompilerProfile(config:Record<string,unknown>):Promise<CompilerProfile>};
  const inputsPath=o.report+'.inputs.json';
  let sourcePins:Record<string,string>|null=null,inputsSha256:string|null=null;
  try{if(existsSync(inputsPath)){inputsSha256=hash(inputsPath);sourcePins=json(inputsPath) as Record<string,string>;}}catch{}
  return createCompilerProfile({directory:join(o.profileDir,stage),
    execution:{stage,...execution,
      reportPath:o.report,reportAtOpenSha256:optionalPin(o.report)?.sha256??null,
      corpusPath:o.corpus,corpusSha256:hash(o.corpus),
      scriptPath:script,scriptSha256:hash(script),
      collectorPath:join(root,'evals/compiler_profile.mjs'),
      collectorSha256:hash(join(root,'evals/compiler_profile.mjs')),
      inspectorHelperPath:join(root,'evals/selfhost_cpu_profile.mjs'),
      inspectorHelperSha256:hash(join(root,'evals/selfhost_cpu_profile.mjs')),
      kernelPath,kernelSha256,
      compilerPath,compilerSha256:hash(compilerPath),
      basePath:join(root,'bend2/base.bend'),baseSha256:hash(join(root,'bend2/base.bend')),
      bridgePath:bridge,bridgeSha256:hash(bridge),
      inputsPath,inputsSha256,sourcePins,
      artifact:optionalPin(o.artifact),
      build:optionalPin(o.build)},
    rawDetail:o.profileRaw,
    sampling:o.profileSampling?{cpuIntervalUs:1000,allocationIntervalBytes:4194304}:false});
}
function profileRunSummary(o:Options,stage:string,treeStopped:boolean|null):Record<string,unknown>{
  if(!o.profileDir)return {status:'DISABLED'};
  const base=join(o.profileDir,stage);
  const runs=existsSync(base)?readdirSync(base).filter(name=>name.startsWith('profile-')):[];
  const resolved=treeStopped===true;
  const liveness=resolved
    ? 'not live: the guardian reported reportPhase=complete and ownedTreeStopped=true'
    : 'unknown: no complete+ownedTreeStopped=true guardian evidence; a finalized profile or provisional guardian decision is not process-liveness proof';
  if(runs.length!==1)return {status:'INCOMPLETE',stage,runDirectory:null,path:null,live:resolved?false:null,liveness,
    reason:runs.length===0?'no collector run directory was published':'expected one collector run directory, found '+runs.length};
  const runDirectory=join(base,runs[0]),path=join(runDirectory,'summary.json'),checkpointPath=join(runDirectory,'checkpoint.json');
  const readCheckpoint=()=>{
    try{return existsSync(checkpointPath)?json(checkpointPath) as Record<string,unknown>:null;}catch{return null;}
  };
  if(!existsSync(path)){
    const runPath=join(runDirectory,'run.json');
    let runRecord:Record<string,unknown>|undefined;
    try{runRecord=existsSync(runPath)?json(runPath) as Record<string,unknown>:undefined;}
    catch(error){runRecord=undefined;}
    const checkpoint=readCheckpoint();
    return {status:'INCOMPLETE',stage,runDirectory,path:null,live:resolved?false:null,liveness,
      measurementStatus:'incomplete',incompleteEvidence:true,
      reason:'collector summary was not finalized (worker error, signal or guardian termination before finish)',
      execution:checkpoint?.execution??null,
      checkpointPath,checkpoint,
      runRecord:runRecord?{status:runRecord.status,pid:(runRecord.identity as Record<string,unknown>|undefined)?.pid,
        startedAt:runRecord.startedAt,rawDetail:runRecord.rawDetail}:null,
      eventsPath:runRecord?.rawDetail?join(runDirectory,'events.jsonl'):null};
  }
  let summary:Record<string,unknown>;
  try{summary=json(path) as Record<string,unknown>;}
  catch(error){return {status:'INCOMPLETE',stage,runDirectory,path,live:resolved?false:null,liveness,
    reason:'collector summary is unreadable (partial write or concurrent finalization): '+String(error),
    execution:readCheckpoint()?.execution??null,checkpointPath,checkpoint:readCheckpoint()};}
  if(!['completed','failed','aborted'].includes(String(summary.status)))return {status:'INCOMPLETE',stage,runDirectory,path,
    live:resolved?false:null,liveness,reason:'invalid collector status '+String(summary.status),
    execution:summary.execution??null,checkpointPath,checkpoint:readCheckpoint()};
  const totals=summary.summary as Record<string,unknown>|undefined;
  return {status:summary.status,stage,path,runDirectory,live:resolved?false:null,liveness,
    measurementStatus:summary.measurementStatus,incompleteEvidence:summary.incompleteEvidence,
    unclosedSpans:totals?.unclosedSpans,
    execution:summary.execution??null,checkpointPath,
    spanCount:totals?.spanCount,summarizedSpanCount:totals?.summarizedSpanCount,
    failedSpans:totals?.failedSpans,abortedSpans:totals?.abortedSpans,
    failedSpanCount:totals?.failedSpanCount,abortedSpanCount:totals?.abortedSpanCount,
    sampledSpans:totals?.sampledSpans,observationKinds:totals?.observationKinds,
    observationCount:totals?.observationCount,aggregatedFineObservations:totals?.aggregatedFineObservations,
    eventsPath:(summary.run as Record<string,unknown>|undefined)?.eventsPath??null};
}

function profileReport(o:Options,stages:string[],treeStopped:boolean|null):Record<string,unknown>{
  if(!o.profileDir)return {enabled:false};
  return {enabled:true,directory:o.profileDir,rawDetail:o.profileRaw,sampling:o.profileSampling,
    runs:Object.fromEntries(stages.map(stage=>[stage,profileRunSummary(o,stage,treeStopped)]))};
}
function endSpan(profile:CompilerProfile|undefined,token:ProfileToken|undefined,status:string,details:Record<string,unknown>={}){
  if(profile&&token)profile.end(token,status,details);
}
function diagnosticText(error:unknown):string{
  if(canonicalKernel&&error&&typeof error==='object'&&'$' in error&&error.$==='Err')
    return canonicalKernel.err_show(error as Bend.Err);
  return String(error);
}
function progress(o:Options,phase:string,event:string,details:Record<string,unknown>={}){
  const memory=process.memoryUsage(),cpu=process.cpuUsage();
  const row={phase,event,unixMs:Date.now(),pid:process.pid,worker:!isMainThread,
    rssBytes:memory.rss,heapUsedBytes:memory.heapUsed,cpuMs:(cpu.user+cpu.system)/1000,...details};
  const serialized=JSON.stringify(row)+'\n';
  appendFileSync(o.report+'.events.jsonl',serialized);
  writeFileSync(o.report+'.progress.json',serialized);
  console.error('NATIVE_BUILD_PROGRESS '+serialized.trimEnd());
}
function failure(o:Options,error:unknown,signal?:string){
  let diagnostic=String(error);
  if(canonicalKernel&&error&&typeof error==='object'&&'$' in error&&error.$==='Err')
    diagnostic=canonicalKernel.err_show(error as Bend.Err);
  const last=existsSync(o.report+'.progress.json')?json(o.report+'.progress.json'):undefined;
  const report=existsSync(o.report)?json(o.report):{boundary};
  const detail=report.failure??{phase:last?.phase??'prerequisites',diagnostic,...(signal?{signal}:{})};
  save(o.report,{...report,status:signal?'INTERRUPTED':'FAIL',failure:detail,lastProgress:last,
    lastCProgress:existsSync(o.report+'.c-progress.json')?json(o.report+'.c-progress.json'):undefined,
    ...(o.profileDir?{compilerProfile:profileReport(o,o.mode==='build'?['codegen','build']:['run'],null)}:{})});
  progress(o,detail.phase,'failure',{diagnostic:detail.diagnostic,...(signal?{signal}:{})});
}
async function compile(o:Options){
  const profile=await openProfile(o,'codegen',{mode:'build',corpus:o.corpus,artifact:o.artifact,bridge});
  if(!profile)return compileBody(o,undefined);
  const span=profile.begin('codegen-worker',{mode:'build'});
  let failureError:unknown;
  try{
    await compileBody(o,profile);
    endSpan(profile,span,'completed',{mode:'build'});
  }catch(error){
    failureError=error;
    const text=diagnosticText(error);
    try{profile.abortOpen('aborted',{error:text},{keep:span});}catch{}
    try{endSpan(profile,span,'failed',{error:text});}catch{}
    throw error;
  }
  finally{profile.finish(failureError?'failed':'completed',failureError?diagnosticText(failureError):undefined);}
}
async function compileBody(o:Options,profile?:CompilerProfile){
  progress(o,'prerequisites','worker-start');
  const start=performance.now(),protectedPins=json(o.report+'.inputs.json') as Record<string,string>;
  verify(protectedPins);const input=corpus(o.corpus),loadedInputs:Record<string,string>={};
  // Delayed import is an authentication boundary: the compiler/kernel must
  // not execute until their exact identities have been checked above.
  progress(o,'module-import','start');
  const importSpan=profile?.begin('module-import',{kernelPath,compilerPath});
  let K:typeof Bend,C:typeof Comp;
  try{
    K=await import(kernelPath) as typeof Bend;
    canonicalKernel=K;
    C=await import(compilerPath) as typeof Comp;
  }catch(error){endSpan(profile,importSpan,'failed',{error:diagnosticText(error)});throw error;}
  endSpan(profile,importSpan,'completed',{kernelSha256,compilerSha256:hash(compilerPath)});
  progress(o,'module-import','complete');
  const book=K.book_nil();
  let loadingPhase='book_load:root';
  class Inputs extends Map<string,string|null>{
    override set(path:string,namespace:string|null){
      if(namespace===null)loadedInputs[path]=hash(path);
      progress(o,loadingPhase,namespace===null?'module-start':'module-complete',{path,namespace});
      return super.set(path,namespace);
    }
  }
  const seen=new Inputs(),source=resolve(root,input.root);
  const rootLoadSpan=profile?.begin('book-load',{source,label:'root'},{sample:o.profileSampling});
  try{
    progress(o,loadingPhase,'start',{source});
    await K.book_load(book,source,'',seen);
  }catch(error){endSpan(profile,rootLoadSpan,'failed',{error:diagnosticText(error)});throw error;}
  endSpan(profile,rootLoadSpan,'completed',{events:book.order.length,modules:seen.size});
  progress(o,loadingPhase,'complete',{events:book.order.length,modules:seen.size});
  // The second root is in the SAME namespace map and source-root coordinate
  // system. No hidden-file import, concatenated source snapshot or AST patch.
  loadingPhase='book_load:bridge';
  const bridgeLoadSpan=profile?.begin('book-load',{source:bridge,label:'bridge'},{sample:o.profileSampling});
  try{
    progress(o,loadingPhase,'start',{source:bridge});
    await K.book_load(book,bridge,'',seen,undefined,dirname(source)+'/');
  }catch(error){endSpan(profile,bridgeLoadSpan,'failed',{error:diagnosticText(error)});throw error;}
  endSpan(profile,bridgeLoadSpan,'completed',{events:book.order.length,modules:seen.size});
  progress(o,loadingPhase,'complete',{events:book.order.length,modules:seen.size});
  const validationStart=performance.now();
  const validationSpan=profile?.begin('book-validation',{events:book.order.length},{sample:o.profileSampling});
  progress(o,'book_valid','start',{events:book.order.length});
  let definitions=0;
  try{
    K.book_valid(book);
    if(book.hols)throw Error('Canonical validation left holes');
    for(const definition of Object.values(book.tlds))if(definition.$==='Def'&&definition.v!==null){definitions++;if(definition.e===undefined)throw Error('Missing canonical checked body');}
  }catch(error){endSpan(profile,validationSpan,'failed',{error:diagnosticText(error)});throw error;}
  endSpan(profile,validationSpan,'completed',{events:book.order.length,checkedDefinitions:definitions});
  profile?.record({kind:'exact-counter',name:'book-validation',scope:'canonical book validation result',
    unitsByField:{events:'book events',checkedDefinitions:'definitions'},
    values:{events:book.order.length,checkedDefinitions:definitions}});
  progress(o,'book_valid','complete',{events:book.order.length,checkedDefinitions:definitions,elapsedMs:performance.now()-validationStart});
  const validationMs=performance.now()-validationStart,codegenStart=performance.now();
  progress(o,'compile_book','start',{checkedDefinitions:definitions});
  const codegenSpan=profile?.begin('compile-book',{checkedDefinitions:definitions},{sample:o.profileSampling});
  let c:string;
  let passes=0,releases=0,observer:CompileBookObserver|undefined;
  try{
    if(!o.traceC&&!profile)c=C.compile_book(book);
    else{
      const fd=o.traceC?openSync(o.report+'.c-events.jsonl','wx'):undefined;
      try{
        const {createCompileBookObserver}=await import('./compiler_profile.mjs') as {
          createCompileBookObserver(profile:CompilerProfile|undefined,options:Record<string,unknown>):CompileBookObserver};
        observer=createCompileBookObserver(profile,{rawDetail:o.profileRaw,onEvent:(stage:string,name:string,state:Record<string,unknown>)=>{
          if(fd===undefined)return;
          const row={stage,name,unixMs:Date.now(),heapUsedBytes:process.memoryUsage().heapUsed,...state};
          const serialized=JSON.stringify(row)+'\n';
          appendFileSync(fd,serialized);
          writeFileSync(o.report+'.c-progress.json',serialized);
          if(stage.startsWith('c-pass-')||stage.startsWith('c-reachability-'))
            progress(o,'compile_book',stage,{name,...state});
        }});
        c=C.compile_book(book,{observe:observer.observe});
        passes=observer.passes;releases=observer.releases;
      }finally{if(fd!==undefined)closeSync(fd);}
    }
  }catch(error){
    const text=diagnosticText(error);
    const actualPasses=observer?.passes??passes,actualReleases=observer?.releases??releases;
    try{profile?.abortOpen('aborted',{error:text,closeReason:'codegen-failure'},{keep:codegenSpan});}catch{}
    try{endSpan(profile,codegenSpan,'failed',{error:text,passes:actualPasses,releases:actualReleases});}catch{}
    passes=actualPasses;releases=actualReleases;
    throw error;
  }
  endSpan(profile,codegenSpan,'completed',{passes,releases,checkedDefinitions:definitions,cUnits:c.length});
  profile?.record({kind:'exact-counter',name:'compile_book',scope:'canonical C code generation result',units:'UTF-16 code units',
    value:c.length,details:{passes,releases,checkedDefinitions:definitions}});
  if(profile&&releases>0)profile.record({kind:'compiler-release-summary',name:'compile_book',
    scope:'in-process higher-cache release events during C generation',units:'events',value:releases});
  progress(o,'compile_book','complete',{cUnits:c.length,elapsedMs:performance.now()-codegenStart});
  progress(o,'c-publication','start');
  const publicationSpan=profile?.begin('c-publication',{artifact:o.artifact+'.c'});
  try{
    for(const definition of Object.values(book.tlds))if(definition.$==='Def')for(const path of definition.i??[])loadedInputs[realpathSync(path)]=hash(path);
    verify(protectedPins);verify(loadedInputs);corpus(o.corpus);
    create(o.artifact+'.c',c);
  }catch(error){endSpan(profile,publicationSpan,'failed',{error:diagnosticText(error)});throw error;}
  endSpan(profile,publicationSpan,'completed',{cPath:o.artifact+'.c',cSha256:sha(c)});
  save(o.report,{status:'C_GENERATED_NOT_YET_BUILT',boundary,protectedPins,loadedInputs,
    source,sourceSha256:hash(source),bridge,eventsFullyValidated:book.order.length,
    codegenTrace:o.traceC,diagnosticOnlyCodegenTiming:o.traceC||!!o.v8LogDir||!!o.profileDir,
    ccOptimization:{level:o.ccOpt,flag:'-O'+o.ccOpt,officialDefault:o.ccOpt===3,diagnosticTradeoff:o.ccOpt!==3},
    checkedDefinitions:definitions,expectedSourceDefinitions:definitions,
    checksExcluded:0,outputPatches:0,kernelSha256,compilerSha256:hash(compilerPath),
    cPath:o.artifact+'.c',cSha256:sha(c),artifact:o.artifact,
    runtime:{name:'node',node:process.versions.node,heapLimitMiB:3072,stackMiB:256,manualGC:false,
      profiling:o.profileDir
        ?{kind:'compiler profile',directory:join(o.profileDir,'codegen'),rawDetail:o.profileRaw,sampling:o.profileSampling,diagnosticOnlyTiming:true,...(o.v8LogDir?{v8LogDir:o.v8LogDir}:{})}
        :o.v8LogDir?{kind:'V8 statistical tick log',directory:o.v8LogDir,diagnosticOnlyTiming:true}:null},
    compilerProfile:o.profileDir?{directory:join(o.profileDir,'codegen'),rawDetail:o.profileRaw,sampling:o.profileSampling,reportPath:profile?.reportPath}:null,
    validationMs,codegenMs:performance.now()-codegenStart,elapsedMs:performance.now()-start});
  progress(o,'c-publication','complete',{cPath:o.artifact+'.c'});
}
async function codegenWorker(o:Options){
  await guardHeavyGate(script,{label:'Native CPU compiler code generation'});
  reportWritable=true;
  progress(o,'compiler-worker','start');
  const thread=new Worker(new URL(import.meta.url),{workerData:o,resourceLimits:{stackSizeMb:256,maxOldGenerationSizeMb:3072}});
  await new Promise<void>((yes,no)=>{thread.once('error',no);thread.once('exit',code=>code===0?yes():no(Error('Canonical C build worker failed: '+code)));});
}
async function buildWorker(o:Options){
  const profile=await openProfile(o,'build',{mode:'build',corpus:o.corpus,artifact:o.artifact,ccPipeline:o.ccPipeline});
  if(!profile)return buildWorkerBody(o,undefined);
  const span=profile.begin('build-supervisor',{mode:'build',ccPipeline:o.ccPipeline});
  let failureError:unknown;
  try{await buildWorkerBody(o,profile);}
  catch(error){failureError=error;endSpan(profile,span,'failed',{error:diagnosticText(error)});throw error;}
  finally{profile.finish(failureError?'failed':'completed',failureError?diagnosticText(failureError):undefined);}
}
async function buildWorkerBody(o:Options,profile?:CompilerProfile){
  await guardHeavyGate(script,{label:'Native CPU compiler build'});
  reportWritable=true;
  const profileFlags=o.v8LogDir?['--prof','--logfile='+join(o.v8LogDir,'native-build.v8.log')]:[];
  const args_=process.argv.slice(2).filter(arg=>!arg.startsWith('--internal='));
  // Worker exit need not return its allocator pages to the OS. Terminate the
  // entire codegen process before clang, not just the worker's JS heap.
  const codegen=['node',...profileFlags,'--experimental-strip-types','--max-old-space-size=3072',script,...args_,'--internal=codegen'];
  progress(o,'codegen-process','start',{command:codegen});
  const codegenSpan=profile?.begin('codegen-process',{command:codegen,childPid:null});
  let codegenChild:{pid:number|undefined};
  try{codegenChild=await child(codegen[0],codegen.slice(1));}
  catch(error){endSpan(profile,codegenSpan,'failed',{error:diagnosticText(error)});throw error;}
  endSpan(profile,codegenSpan,'completed',{childPid:codegenChild.pid});
  profile?.record({kind:'child-process-boundary',name:'codegen-process',
    scope:'spawned Node codegen child; parent CPU excludes the child and this host does not read child rusage',
    units:'pid',values:{pid:codegenChild.pid??null},
    details:{childCpu:null,reason:'Node spawn exposes the pid but not child rusage; the child writes its own profile'}});
  progress(o,'codegen-process','complete');
  const report=json(o.report),cc=process.env.CC??'clang';
  if(o.ccPipeline==='llvm-split'){
    // Backend-only code runs in its own guarded Bun process, never in the
    // Node codegen workers. Its source is included in the protected pins.
    progress(o,'llvm-pipeline','start');
    const pipelineSpan=profile?.begin('llvm-pipeline',{cc,llvmBin:o.llvmBin??null});
    let pipelineChild:{pid:number|undefined};
    try{pipelineChild=await child(process.execPath,['--smol',join(root,'evals/native_compiler_llvm.ts'),o.report,cc,o.llvmBin??'']);}
    catch(error){endSpan(profile,pipelineSpan,'failed',{error:diagnosticText(error)});throw error;}
    const pipeline=json(o.report).ccPipeline;
    endSpan(profile,pipelineSpan,'completed',{childPid:pipelineChild.pid,elapsedMs:pipeline.elapsedMs,status:pipeline.status});
    if(profile){
      for(const stage of pipeline.stages as Array<{name:string;status:string;wallMs?:number;userSeconds:number|null;systemSeconds:number|null;maxRssBytes:number|null;timedRealSeconds:number|null}>){
        profile.record({kind:'child-process-stage',name:stage.name,
          scope:'llvm-split child measured by /usr/bin/time -lp wait4; distinct from parent process CPU',
          unitsByField:{wallMs:'ms',timedRealSeconds:'s',userCpuMs:'ms',systemCpuMs:'ms',maxRssBytes:'bytes'},
          values:{wallMs:stage.wallMs??null,
            timedRealSeconds:stage.timedRealSeconds,userCpuMs:stage.userSeconds===null?null:stage.userSeconds*1000,
            systemCpuMs:stage.systemSeconds===null?null:stage.systemSeconds*1000,maxRssBytes:stage.maxRssBytes},
          details:{status:stage.status}});
      }
    }
    progress(o,'llvm-pipeline','complete',{elapsedMs:pipeline.elapsedMs});
    verify(report.protectedPins);verify(report.loadedInputs);corpus(o.corpus);
    save(o.report,{...report,status:'NATIVE_EXECUTABLE_BUILT_NOT_YET_RUN',artifactSha256:hash(o.artifact!),
      ccPipeline:pipeline,buildCommands:pipeline.stages.map((stage:{command:string[]})=>stage.command)});
  }else{
    // The original direct CC path remains an explicit genuine alternative.
    const args=['-std=c11','-O'+o.ccOpt,report.cPath,'-lpthread','-lm','-o',o.artifact!];
    progress(o,'clang','start',{command:[cc,...args]});
    const clangSpan=profile?.begin('clang',{command:[cc,...args]});
    let clangChild:{pid:number|undefined};
    try{clangChild=await child(cc,args);}
    catch(error){endSpan(profile,clangSpan,'failed',{error:diagnosticText(error)});throw error;}
    endSpan(profile,clangSpan,'completed',{childPid:clangChild.pid,artifact:o.artifact});
    profile?.record({kind:'child-process-boundary',name:'clang',scope:'direct clang child; parent CPU excludes the child',
      units:'pid',values:{pid:clangChild.pid??null},
      details:{childCpu:null,reason:'the direct path has no wait4 time receipt; use llvm-split for measured child CPU/maxRSS'}});
    progress(o,'clang','complete',{artifact:o.artifact});
    verify(report.protectedPins);verify(report.loadedInputs);corpus(o.corpus);
    save(o.report,{...report,status:'NATIVE_EXECUTABLE_BUILT_NOT_YET_RUN',artifactSha256:hash(o.artifact!),buildCommand:[cc,...args],ccPipeline:{kind:'direct'}});
  }
}
function exportNames(o:Options,input:Corpus):string[]{
  const data=o.exports?json(o.exports):input.exports;
  const names=Array.isArray(data)?data:data.exports;
  if(!Array.isArray(names)||!names.length||names.some(name=>typeof name!=='string'||!name||/[\r\n\t]/.test(name))||new Set(names).size!==names.length)throw Error('Expected unique public export names from the official run');
  return names;
}
async function runWorker(o:Options){
  const profile=await openProfile(o,'run',{mode:'run',phase:o.phase,threads:o.threads,corpus:o.corpus,build:o.build});
  if(!profile)return runWorkerBody(o,undefined,new Map());
  const span=profile.begin('native-run',{mode:'run',phase:o.phase,threads:o.threads});
  const phaseSpans=new Map<string,ProfileToken>();
  let failureError:unknown;
  try{await runWorkerBody(o,profile,phaseSpans);}
  catch(error){
    failureError=error;
    for(const token of phaseSpans.values())endSpan(profile,token,'failed',{error:diagnosticText(error)});
    endSpan(profile,span,'failed',{error:diagnosticText(error)});
    throw error;
  }
  finally{profile.finish(failureError?'failed':'completed',failureError?diagnosticText(failureError):undefined);}
}
async function runWorkerBody(o:Options,profile?:CompilerProfile,phaseSpans=new Map<string,ProfileToken>()){
  // This path compiles the authenticated compiler corpus root, not an arbitrary
  // fixture. Fixture C workloads call authenticateNativeSeedBuild once and then
  // runNativeStage0 with their phase-specific input manifest; no second CLI.
  await guardHeavyGate(script,{label:'Native CPU compiler execution'});
  reportWritable=true;
  const protectedPins=json(o.report+'.inputs.json') as Record<string,string>;verify(protectedPins);
  const input=corpus(o.corpus),build=json(o.build!);
  if(build.status!=='NATIVE_EXECUTABLE_BUILT_NOT_YET_RUN'||build.guardian?.status!=='PASS'||build.kernelSha256!==kernelSha256||build.checksExcluded!==0||build.outputPatches!==0||build.artifactSha256!==hash(build.artifact)||build.cSha256!==hash(build.cPath))throw Error('Native executable lacks a successful full canonical build');
  verify(build.protectedPins);verify(build.loadedInputs);
  const names=exportNames(o,input),cPhase=o.phase.startsWith('compile-c');
  const target=cPhase?'c':'js';
  const workload=workloadRows(resolve(input.directory,input.root),target);
  const effective=requireCorpusCoversWorkload(input,workload,target);
  const runtimePath=cPhase?realpathSync(o.runtimeC!):undefined,runtimeSha256=runtimePath?hash(runtimePath):undefined;
  const output=o.report+(cPhase?'.c':'.mjs');
  create(o.report+'.runtime.tsv',runtimeManifest(corpusFor(workload)));
  create(o.report+'.exports.txt',names.join('\n')+'\n');
  const phases:Array<{phase:string}> = [],begins:Array<{computeThreads:number}> = [],results:Array<{result:string;modules:number;bytes?:number}> = [];
  const fuel:Array<Record<string,unknown>> = [];
  const phaseStarts:Array<{phase:string}> = [];
  const command=[build.artifact,'--threads',String(o.threads),'--gpu','off','--',
    resolve(input.directory,input.root),resolve(input.directory,'bend2/base.bend'),
    o.report+'.runtime.tsv',o.report+'.exports.txt',o.phase,output];
  if(runtimePath)command.push(runtimePath);
  if(runtimePath)progress(o,'runtime-c','pinned',{path:runtimePath,sha256:runtimeSha256});
  profile?.record({kind:'producer-command',name:'native-run',scope:'native child command launched by the TypeScript producer',
    units:'threads',values:{threads:o.threads},details:{phase:o.phase,command}});
  const started=performance.now();
  await child(command[0],command.slice(1),line=>{
    if(line.startsWith('NATIVE_PHASE_START ')){
      const row=jsonRecord(line.slice(19));
      if(typeof row.phase!=='string')throw Error('Malformed native phase-start record');
      phaseStarts.push({...row,phase:row.phase});
      if(profile&&!phaseSpans.has(row.phase))phaseSpans.set(row.phase,profile.begin('native-phase',{phase:row.phase}));
      progress(o,row.phase,'start',{native:row});
    }
    if(line.startsWith('NATIVE_PHASE ')){
      const row=jsonRecord(line.slice(13));
      if(typeof row.phase!=='string'||![row.elapsedMs,row.userCpuMs,row.systemCpuMs].every(value=>typeof value==='number'&&Number.isFinite(value)&&value>=0))throw Error('Malformed native phase CPU/wall record');
      phases.push({...row,phase:row.phase});
      endSpan(profile,phaseSpans.get(row.phase),'completed',{childElapsedMs:row.elapsedMs,childUserCpuMs:row.userCpuMs,childSystemCpuMs:row.systemCpuMs});
      phaseSpans.delete(row.phase);
      profile?.record({kind:'child-process-phase',name:row.phase,
        scope:'native child process RUSAGE_SELF across all compute threads; distinct from and not additive with parent process CPU',
        unitsByField:{elapsedMs:'ms',userCpuMs:'ms',systemCpuMs:'ms',chunkAdvances:'chunk advances',
          chunkQuantum:'cells per chunk advance',modules:'modules',sourceBytes:'bytes',foreignBytes:'bytes',
          eagerFuelCells:'cells',fuelBuildMs:'ms'},
        values:{elapsedMs:row.elapsedMs,userCpuMs:row.userCpuMs,systemCpuMs:row.systemCpuMs,
          chunkAdvances:row.chunkAdvances??null,chunkQuantum:row.chunkQuantum??null,
          modules:row.modules??null,sourceBytes:row.sourceBytes??null,foreignBytes:row.foreignBytes??null,
          eagerFuelCells:row.eagerFuelCells??null,fuelBuildMs:row.fuelBuildMs??null},source:'NATIVE_PHASE'});
      progress(o,row.phase,'complete',{native:row});
    }
    if(line.startsWith('NATIVE_FUEL ')){
      const row=jsonRecord(line.slice(12));
      if(row.cells!==8000000||typeof row.elapsedMs!=='number'||typeof row.processPeakRssBeforeBytes!=='number'||typeof row.processPeakRssAfterBytes!=='number')throw Error('Malformed native eager-fuel record');
      fuel.push(row);
      profile?.record({kind:'child-process-fuel',name:'eager-fuel',scope:'native child RUSAGE_SELF max RSS high-water before/after one source fuel chain; not isolated live bytes',
        unitsByField:{cells:'cells',elapsedMs:'ms',processPeakRssBeforeBytes:'bytes',
          processPeakRssAfterBytes:'bytes',sourceOrdinal:'source ordinal'},
        values:{sourceOrdinal:row.sourceOrdinal??null,cells:row.cells,elapsedMs:row.elapsedMs,
          processPeakRssBeforeBytes:row.processPeakRssBeforeBytes,processPeakRssAfterBytes:row.processPeakRssAfterBytes},source:'NATIVE_FUEL'});
    }
    if(line.startsWith('NATIVE_BEGIN ')){
      const row=jsonRecord(line.slice(13));
      if(typeof row.computeThreads!=='number'||row.phaseTraceVersion!==3)throw Error('Malformed native runtime/phase-trace record');
      begins.push({...row,computeThreads:row.computeThreads});
      profile?.record({kind:'child-process-runtime',name:'native-begin',scope:'native child runtime configuration',
        unitsByField:{computeThreads:'threads',parserFuel:'cells',phaseTraceVersion:'version'},
        values:{computeThreads:row.computeThreads,parserFuel:row.parserFuel??null,phaseTraceVersion:row.phaseTraceVersion},source:'NATIVE_BEGIN'});
    }
    if(line.startsWith('NATIVE_RESULT ')){
      const row=jsonRecord(line.slice(14));
      if(typeof row.result!=='string'||typeof row.modules!=='number')throw Error('Malformed native result record');
      results.push({...row,result:row.result,modules:row.modules});
      profile?.record({kind:'child-process-result',name:row.result,scope:'native child typed whole-workload result',
        unitsByField:{modules:'modules',bytes:'bytes'},
        values:{modules:row.modules,bytes:row.bytes??null},source:'NATIVE_RESULT'});
    }
  });
  verify(protectedPins);verify(build.protectedPins);verify(build.loadedInputs);corpus(o.corpus);
  const expectedModules=input.files.filter(row=>!row.external).length;
  if(fuel.length!==expectedModules)throw Error('Missing whole-workload eager-fuel accounting');
  const begin=begins[0];
  const emitted=o.phase==='compile'||cPhase;
  if(begins.length!==1||begin?.computeThreads!==o.threads||results.length!==1||results[0].modules!==expectedModules||results[0].result!==(emitted?'EmitSuccess':'CheckSuccess'))throw Error('Missing complete typed whole-workload result');
  if(runtimePath&&hash(runtimePath)!==runtimeSha256)throw Error('Runtime source drifted during the native C emission');
  const expectedPhases=cPhase?['parse','expand','check','emit-c']:o.phase==='compile'?['parse','expand','check','emit']:['parse','expand','check'];
  if(JSON.stringify(phases.map(row=>row.phase))!==JSON.stringify(expectedPhases)||JSON.stringify(phaseStarts.map(row=>row.phase))!==JSON.stringify(expectedPhases))throw Error('Missing ordered phase-start/completion evidence');
  let semanticSmoke:unknown={status:'NOT_REQUESTED'};
  if(o.expectJs){
    if(hash(o.expectJs)!==acceptedCompilerSha256)throw Error('Expected image is not the accepted v40 fixedpoint compiler');
    if(hash(output)!==acceptedCompilerSha256||readFileSync(output).length!==readFileSync(o.expectJs).length)throw Error('Native full compiler did not reproduce the accepted compiler bytes');
    semanticSmoke={status:'PASS',kind:'exact accepted full compiler image (all bytes)',expectedSha256:acceptedCompilerSha256,bytes:readFileSync(output).length,nativeBinaryBootstrap:false};
  }
  profile?.record({kind:'exact-counter',name:'native-workload',scope:'native child whole-workload result',
    unitsByField:{modules:'modules',phases:'phases',fuelRows:'rows',threads:'threads'},
    values:{modules:results[0]?.modules??null,phases:phases.length,fuelRows:fuel.length,threads:o.threads}});
  save(o.report,{status:cPhase?'NATIVE_FULL_C_COMPILE_PASS':o.phase==='compile'?'NATIVE_FULL_COMPILE_PASS':'NATIVE_FULL_CHECK_PASS',boundary,
    build:o.build,buildSha256:hash(o.build!),protectedPins,corpus:o.corpus,corpusSha256:hash(o.corpus),
    ccOptimization:build.ccOptimization,
    threads:o.threads,multithread:o.threads>1,command,elapsedMs:performance.now()-started,workload:effective,
    phases,phaseStarts,fuel,result:results[0],exports:names,semanticSmoke,
    compilerProfile:o.profileDir?{directory:join(o.profileDir,'run'),rawDetail:o.profileRaw,sampling:o.profileSampling,reportPath:profile?.reportPath}:null,
    ...(cPhase?{runtimeC:{path:runtimePath,sha256:runtimeSha256}}:{}),
    ...(emitted?{output,outputSha256:hash(output),outputBytes:readFileSync(output).length}:{diagnosticOnly:true})});
}
async function main(o:Options){
  if(o.internal){
    // A worker that can still run JS finalizes a terminal report before exit.
    // A SIGKILLed process group cannot be caught; the parent then reports the
    // profile as INCOMPLETE with explicit liveness instead of completed.
    const stopped=new Map<NodeJS.Signals,()=>void>();
    for(const signal of ['SIGINT','SIGTERM','SIGHUP'] as const){
      const handler=()=>{failure(o,Error('Worker received '+signal),signal);process.exit(2);};
      stopped.set(signal,handler);process.once(signal,handler);
    }
    try{
      if(o.internal==='build')await buildWorker(o);
      else if(o.internal==='codegen')await codegenWorker(o);
      else if(o.internal==='run')await runWorker(o);
      else throw Error('Unknown internal operation');
    }finally{for(const [signal,handler]of stopped)process.off(signal,handler);}
    return;
  }
  mkdirSync(dirname(o.report),{recursive:true});
  if([o.report,o.report+'.inputs.json',o.report+'.progress.json',o.report+'.events.jsonl',o.report+'.c-progress.json',o.report+'.c-events.jsonl'].some(existsSync)||o.artifact&&(existsSync(o.artifact)||existsSync(o.artifact+'.c')))throw Error('Use fresh report and artifact paths');
  if(o.profileDir&&(o.profileDir===o.report||o.profileDir===o.artifact||o.profileDir.startsWith(o.report+'.')))
    throw Error('--profile-dir must not overlap the report or artifact paths');
  if(o.profileDir&&existsSync(o.profileDir))throw Error('Use a fresh --profile-dir; profile runs are not appended or mixed');
  if(o.profileDir)mkdirSync(o.profileDir,{recursive:true});
  const settings={...guard,timeoutMs:o.mode==='build'?o.buildTimeoutMs:300000};
  create(o.report,JSON.stringify({status:'IN_PROGRESS',mode:o.mode,boundary,startedAtUnixMs:Date.now(),guard:settings},null,2)+'\n');
  reportWritable=true;
  progress(o,'prerequisites','start');
  corpus(o.corpus);const protectedPins=pins(o);create(o.report+'.inputs.json',JSON.stringify(protectedPins,null,2)+'\n');
  const args=process.argv.slice(2);
  // These are supported V8 flags (node --v8-options). Default per-isolate
  // logging separates the large-stack Worker from its waiting main thread.
  // Tick logs do not depend on executing Profiler.stop in a blocked phase.
  if(o.v8LogDir)mkdirSync(o.v8LogDir);
  const command=[process.execPath,'--smol',script,...args,'--internal='+(o.mode==='build'?'build':'run')];
  const stopped=new Map<NodeJS.Signals,()=>void>();
  for(const signal of ['SIGINT','SIGTERM','SIGHUP'] as const){
    const handler=()=>failure(o,Error('Runner received '+signal),signal);
    stopped.set(signal,handler);process.once(signal,handler);
  }
  progress(o,'guardian','start',{command,timeoutMs:settings.timeoutMs});
  try{
    const guardian=await runHeavyGate(command,{...settings,label:'Native CPU compiler '+o.mode});
    const guarded=guardian as typeof guardian&{reportPhase?:unknown;ownedTreeStopped?:unknown};
    const treeStopped=guarded.reportPhase==='complete'&&guarded.ownedTreeStopped===true;
    const report=json(o.report),last=existsSync(o.report+'.progress.json')?json(o.report+'.progress.json'):undefined;
    const lastC=existsSync(o.report+'.c-progress.json')?json(o.report+'.c-progress.json'):undefined;
    const passed=guardian.status==='PASS'&&(o.mode==='build'?report.status==='NATIVE_EXECUTABLE_BUILT_NOT_YET_RUN':['NATIVE_FULL_COMPILE_PASS','NATIVE_FULL_CHECK_PASS','NATIVE_FULL_C_COMPILE_PASS'].includes(report.status));
    save(o.report,{...report,status:passed?report.status:guardian.status==='RESOURCE_LIMIT'?'RESOURCE_LIMIT':'FAIL',guardian,lastProgress:last,lastCProgress:lastC,
      ...(o.profileDir?{compilerProfile:profileReport(o,o.mode==='build'?['codegen','build']:['run'],treeStopped)}:{}),
      ...(!passed?{failure:report.failure??{phase:last?.phase??'guardian',diagnostic:guardian.reason}}:{})});
    progress(o,'guardian',passed?'complete':'failure',{guardianStatus:guardian.status,reason:guardian.reason,failedPhase:passed?undefined:last?.phase});
    if(!passed)process.exitCode=2;
  }finally{
    for(const [signal,handler]of stopped)process.off(signal,handler);
  }
}
let activeOptions:Options|undefined;
try{
  activeOptions=isMainThread?options():workerData as Options;
  if(!isMainThread){reportWritable=true;await compile(activeOptions);}else await main(activeOptions);
}catch(error){
  if(activeOptions&&reportWritable)failure(activeOptions,error);
  console.error(String(error));process.exitCode=2;
}
