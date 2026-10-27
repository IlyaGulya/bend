#!/usr/bin/env bun
/** Diagnostic off/on profiling-overhead harness for candidate_host.ts.
 * Off legs are ordinary; on legs add only --stage-profile. Same pinned image
 * and source closure, fresh dirs, alternating pairs, one heavy_gate per leg.
 *
 * usage: bun evals/compiler_profile_overhead.ts --source=PATH --candidate=PATH
 *   --report=PATH [--parser=PATH] [--base=PATH] [--candidate-build=PATH]
 *   [--target=js|c] [--exports=NAME,...] [--pairs=N] [--node=PATH]
 *   [--timeout-ms=600000] [--stage-manifest=PATH ...] [--stage-receipt=PATH ...]
 *
 * Library output defaults to the 13-entry ABI; target js; fresh mkdtemp work
 * dir; 8192 MiB footprint/RSS, 10 ms poll, 1 s term grace; 600000 ms default
 * deadline (larger is diagnostic-only). Darwin /usr/bin/time -lp wait4 receipts
 * only; no fallback. Candidate/parser/base/source/C runtime/manifests/receipts/
 * candidate-build receipt + provenance closure/helpers/worker are pinned before
 * and after every leg; base must be the canonical repo base so workloadRows is
 * a complete closure. Node/Bun executables are recorded, not hashed. Drift,
 * non-terminal guardian, lock-busy/resource limit, incomplete profile or
 * unequal output bytes fail. No retries, output patches, emitted-program runs
 * or acceptance claims: every record is diagnosticOnly, acceptanceEvidence false.
 * Canonical root-release seed images need --candidate-build so candidate_host
 * derives the root carrier; stage1 selfhost images may omit it.
 */
import {createHash} from 'node:crypto';
import {closeSync,existsSync,mkdirSync,mkdtempSync,openSync,readFileSync,readdirSync,realpathSync,statSync,writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {dirname,isAbsolute,join,resolve} from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {ABI,workloadRows} from './native_seed_runtime.mjs';

const REPO=realpathSync(resolve(dirname(fileURLToPath(import.meta.url)),'..'));
const MiB=1024*1024;
const LIMITS=Object.freeze({memoryMiB:8192,rssMiB:8192,pollMs:10,termGraceMs:1000});
const ACCEPTANCE_TIMEOUT_MS=600000;
const TIME='-lp';
const ADAPTER=`import {Worker} from 'node:worker_threads';
import {pathToFileURL} from 'node:url';
const [script,...argv]=process.argv.slice(2);
if(!script)throw Error('Expected candidate runner and arguments');
const worker=new Worker(pathToFileURL(script),{argv,resourceLimits:{stackSizeMb:256,maxOldGenerationSizeMb:3072}});
worker.once('error',error=>{console.error(error);process.exitCode=1;});
worker.once('exit',code=>{process.exitCode=code;});
`;
const sha=value=>createHash('sha256').update(value).digest('hex');
const hashFile=path=>sha(readFileSync(path));
const text=error=>error instanceof Error?error.message:String(error);
function must(condition,message){if(!condition)throw Error(message);}
function pin(path){
 const real=realpathSync(path),bytes=readFileSync(real);
 return {path:real,bytes:bytes.length,sha256:sha(bytes)};
}
function number(value,name,min,max){
 const parsed=Number(value);
 must(Number.isSafeInteger(parsed)&&parsed>=min&&parsed<=max,name+' must be an integer in '+min+'..'+max);
 return parsed;
}
function options(argv){
 const values=new Map(),manifests=[],receipts=[];
 const valued={
  '--source':true,'--candidate':true,'--parser':true,'--base':true,'--target':true,
  '--candidate-build':true,'--exports':true,'--pairs':true,'--report':true,'--node':true,'--timeout-ms':true,
 };
 for(let i=0;i<argv.length;i+=1){
  const argument=argv[i];
  must(typeof argument==='string'&&argument.startsWith('--'),'unexpected argument: '+String(argument));
  const equals=argument.indexOf('='),name=equals<0?argument:argument.slice(0,equals);
  const value=equals<0?argv[++i]:argument.slice(equals+1);
  must(value!==undefined&&value!=='','missing value for '+name);
  if(name==='--stage-manifest'||name==='--stage-receipt'){(name==='--stage-manifest'?manifests:receipts).push(value);continue;}
  must(valued[name]===true,'unknown option '+name);
  must(!values.has(name),'duplicate option '+name);
  values.set(name,value);
 }
 const result={
  source:values.get('--source'),candidate:values.get('--candidate'),report:values.get('--report'),
  parser:values.get('--parser'),base:values.get('--base'),candidateBuild:values.get('--candidate-build'),target:values.get('--target')??'js',
  exports:values.get('--exports')??ABI.join(','),pairs:number(values.get('--pairs')??2,'--pairs',2,64),
  node:values.get('--node')??'node',timeoutMs:number(values.get('--timeout-ms')??ACCEPTANCE_TIMEOUT_MS,'--timeout-ms',1,2147483647),
  manifests,receipts,
 };
 must(result.source&&result.candidate&&result.report,'required --source, --candidate and --report');
 must(result.target==='js'||result.target==='c','--target must be js or c');
 const exports=result.exports.split(',');
 must(exports.length>0&&exports.every(name=>/^[A-Za-z_][A-Za-z0-9_]*$/.test(name))&&new Set(exports).size===exports.length,
  '--exports needs unique comma-separated Bend identifiers');
 return {...result,exportsList:exports};
}
function program(command,cwd){
 let path=command;
 if(!command.includes('/')){
  const which=spawnSync('/usr/bin/which',[command],{encoding:'utf8',timeout:60000});
  must(which.status===0&&String(which.stdout).trim(),'node executable not found: '+command);
  path=String(which.stdout).trim().split('\n')[0];
 }else if(!isAbsolute(command))path=resolve(cwd,command);
 const resolved=realpathSync(path);
 const version=spawnSync(resolved,['--version'],{encoding:'utf8',timeout:60000});
 must(!version.error&&version.status===0,'node --version failed: '+command);
 return {command,path:resolved,version:String(version.stdout).trim().split('\n')[0]};
}
function configure(input,cwd){
 const file=(value,label)=>{
  const absolute=isAbsolute(value)?value:resolve(cwd,value);
  let real;
  try{real=realpathSync(absolute);}catch(error){throw Error(label+' is not readable: '+absolute+': '+text(error));}
  must(statSync(real).isFile(),label+' is not a regular file: '+real);
  return real;
 };
 const source=file(input.source,'--source'),candidate=file(input.candidate,'--candidate');
 const parser=input.parser===undefined?candidate:file(input.parser,'--parser');
 const canonicalBase=realpathSync(join(REPO,'bend2/base.bend'));
 const base=file(input.base??canonicalBase,'--base');
 must(base===canonicalBase,'--base must be the canonical repo base: workloadRows hardcodes Base to '+canonicalBase);
 const runtimeC=input.target==='c'?file(join(REPO,'bend2/selfhost/c_runtime.c'),'--runtime-c'):null;
 const candidateBuild=input.candidateBuild===undefined?null:file(input.candidateBuild,'--candidate-build');
 const candidateBuildPins=[];
 if(candidateBuild!==null){
  const build=JSON.parse(readFileSync(candidateBuild,'utf8'));
  must(build&&typeof build.provenancePath==='string','candidate build receipt has no provenancePath');
  const provenance=realpathSync(build.provenancePath);
  candidateBuildPins.push(provenance);
  const document=JSON.parse(readFileSync(provenance,'utf8'));
  for(const field of ['protectedPins','loadedInputs']){
   const pins=document[field];
   must(pins&&typeof pins==='object','candidate build provenance lacks '+field);
   for(const path of Object.keys(pins))candidateBuildPins.push(realpathSync(path));
  }
 }
 const config={
  source,candidate,parser,parserSeparate:input.parser!==undefined&&parser!==candidate,base,runtimeC,target:input.target,
  candidateBuild,candidateBuildPins,
  exportsList:input.exportsList,exportsArg:input.exportsList.join(','),pairs:input.pairs,timeoutMs:input.timeoutMs,
  manifests:input.manifests.map(path=>file(path,'--stage-manifest')),
  receipts:input.receipts.map(path=>file(path,'--stage-receipt')),
  node:program(input.node,cwd),reportPath:resolve(cwd,input.report),
  candidateHost:realpathSync(join(REPO,'evals/candidate_host.ts')),
  heavyGate:realpathSync(join(REPO,'evals/heavy_gate.ts')),
  stageHelper:realpathSync(join(REPO,'evals/compiler_stage_profile.mjs')),
  collector:realpathSync(join(REPO,'evals/compiler_profile.mjs')),
  nativeRuntime:realpathSync(join(REPO,'evals/native_seed_runtime.mjs')),
  stepRuntime:realpathSync(join(REPO,'evals/checker_core_step_runtime.mjs')),
  harness:realpathSync(fileURLToPath(import.meta.url)),
 };
 config.harnessFiles=[config.nativeRuntime,config.stepRuntime,config.candidateHost,config.heavyGate,config.stageHelper,config.collector,config.harness];
 config.receiptProvenance=config.receipts.map(path=>{
  const document=JSON.parse(readFileSync(path,'utf8'));
  return typeof document.provenancePath==='string'?realpathSync(document.provenancePath):null;
 }).filter(path=>path!==null);
 config.env={...process.env};
 for(const name of ['SELFHOST_STAGE_PARENT','SELFHOST_STAGE_PROFILE_DIR','SELFHOST_STAGE_PROGRESS'])delete config.env[name];
 return config;
}
function closure(config){return workloadRows(config.source,config.target);}
function closureDigest(rows){
 return sha(JSON.stringify([rows.sources.map(row=>[row.path,row.sha256,row.namespace]),rows.externals.map(row=>[row.path,row.sha256])]));
}
function pinMap(config,rows){
 const map=new Map();
 for(const row of rows.sources)map.set(row.file,row.sha256);
 for(const row of rows.externals)map.set(row.file,row.sha256);
 const add=path=>{const real=realpathSync(path);map.set(real,hashFile(real));};
 for(const path of [config.source,config.candidate,config.parser,config.base,config.worker,...config.manifests,...config.receipts,...config.receiptProvenance,...config.candidateBuildPins,...config.harnessFiles])add(path);
 if(config.candidateBuild!==null)add(config.candidateBuild);
 if(config.runtimeC!==null)add(config.runtimeC);
 return map;
}
function pinDigest(map){return sha(JSON.stringify([...map.entries()].sort((left,right)=>left[0].localeCompare(right[0]))));}
function drift(expected,actual,where){
 const problems=[];
 for(const [path,digest] of expected)if(actual.get(path)!==digest)problems.push(path);
 for(const path of actual.keys())if(!expected.has(path))problems.push('added '+path);
 must(problems.length===0,'input drift '+where+' ('+problems.length+'): '+problems.slice(0,6).join('; '));
}
function timeReceipt(bytes){
 const lines=bytes.split('\n');
 const last=pattern=>{let found=null;for(const line of lines){const match=pattern.exec(line);if(match!==null)found=match;}return found;};
 const real=last(/^real\s+([0-9.]+)$/),user=last(/^user\s+([0-9.]+)$/),system=last(/^sys\s+([0-9.]+)$);
 const rss=last(/^\s*([0-9]+)\s+maximum resident set size$/),footprint=last(/^\s*([0-9]+)\s+peak memory footprint$/);
 must(real&&user&&system&&rss,'missing /usr/bin/time -lp wait4 receipt');
 return {source:'/usr/bin/time -lp Darwin wait4',realMs:Number(real[1])*1000,userMs:Number(user[1])*1000,
  systemMs:Number(system[1])*1000,maxRssBytes:Number(rss[1]),peakFootprintBytes:footprint?Number(footprint[1]):null};
}
function guardian(bytes,command,config){
 const lines=bytes.split('\n').filter(line=>line.startsWith('HEAVY_GATE '));
 must(lines.length===1,'expected one HEAVY_GATE receipt, observed '+lines.length);
 const record=JSON.parse(lines[0].slice('HEAVY_GATE '.length));
 must(JSON.stringify(record.command)===JSON.stringify(command),'guardian command receipt differs');
 must(record.reportPhase==='complete'&&record.ownedTreeStopped===true,'guardian receipt is not terminal');
 must(record.status==='PASS'&&record.reason==='command_exit','guardian status is '+record.status+': '+record.reason);
 must(record.commandExitCode===0&&record.commandSignal===0,'guardian command did not exit cleanly');
 must(record.memoryLimitBytes===LIMITS.memoryMiB*MiB&&record.rssLimitBytes===LIMITS.rssMiB*MiB&&record.timeoutMs===config.timeoutMs,
  'guardian limits differ from the explicit request');
 return record;
}
function profile(config,profileDirectory,output,reported){
 const entries=readdirSync(profileDirectory,{withFileTypes:true}).filter(entry=>entry.isDirectory()&&entry.name.startsWith('profile-'));
 must(entries.length===1,'expected one collector run, observed '+entries.length);
 const runDirectory=join(profileDirectory,entries[0].name),summaryPath=join(runDirectory,'summary.json');
 const summaryPin=pin(summaryPath),summary=JSON.parse(readFileSync(summaryPin.path,'utf8'));
 must(summary.kind==='compiler-profile'&&summary.schemaVersion===1&&summary.diagnosticOnly===true&&summary.acceptanceEvidence===false,
  'collector summary kind or diagnostic flags differ');
 must(summary.measurementStatus==='complete'&&summary.incompleteEvidence===false&&summary.status==='completed'&&
  summary.workloadStatus==='completed'&&summary.error===null,'collector profile is not complete');
 must(summary.summary?.unclosedSpans?.count===0,'collector profile has unclosed spans');
 must(summary.run?.rawDetail===false&&summary.sampling?.config===null&&summary.sampling?.status==='disabled',
  'collector profile unexpectedly retained raw detail or sampling');
 const execution=summary.execution;
 must(execution&&execution.stage==='selfhost-candidate'&&execution.mode==='typed-step'&&execution.target===config.target,
  'profile execution identity differs');
 must(execution.sourcePath===config.source&&execution.sourceSha256===hashFile(config.source)&&
  execution.candidatePath===config.candidate&&execution.candidateSha256===hashFile(config.candidate)&&
  execution.parserPath===config.parser&&execution.parserSha256===hashFile(config.parser)&&
  execution.basePath===config.base&&execution.baseSha256===hashFile(config.base),'profile inputs differ from pins');
 must(execution.outputPath===output&&execution.library===true&&
  JSON.stringify(execution.exports??null)===JSON.stringify(config.exportsList),'profile output identity differs');
 must((execution.candidateBuild??null)===(config.candidateBuild??null),'profile candidate-build differs from the flag');
 const sources=execution.profileSources;
 must(sources&&typeof sources==='object','profile has no source provenance');
 for(const [key,path] of [['executingScript',config.candidateHost],['stageHelper',config.stageHelper],['collector',config.collector]])
  must(sources[key]&&sources[key].path===path&&sources[key].sha256===hashFile(path),'profile provenance differs for '+key);
 must(realpathSync(reported)===summaryPin.path,'reported profile path differs from the collector summary');
 const link=summary.observations?.find(row=>row.name==='collector-profile-id');
 must(link&&link.values?.profileId===summary.profileId,'collector profileId link is absent or differs');
 return {diagnosticOnly:true,acceptanceEvidence:false,runDirectory,summaryPath:summaryPin.path,
  summaryBytes:summaryPin.bytes,summarySha256:summaryPin.sha256,profileId:summary.profileId,
  measurementStatus:summary.measurementStatus,runWallMs:summary.run.wallMs,spanCount:summary.summary.spanCount,
  observationCount:summary.summary.observationCount,execution:{command:execution.command??null,
  sourceSha256:execution.sourceSha256,candidateSha256:execution.candidateSha256,parserSha256:execution.parserSha256,baseSha256:execution.baseSha256},
  profileSources:sources};
}
function leg(config,initial,row){
 const pair=row.pair,kind=row.kind,directory=join(config.workRoot,'p'+pair+'-'+kind);
 const output=join(directory,config.target==='c'?'out.c':'out.js'),profileDirectory=kind==='on'?join(directory,'profile'):null;
 const host=[`--candidate=${config.candidate}`];
 if(config.candidateBuild!==null)host.push(`--candidate-build=${config.candidateBuild}`);
 if(config.parserSeparate)host.push(`--parser=${config.parser}`);
 host.push(`--base=${config.base}`,'--library',`--exports=${config.exportsArg}`);
 if(config.target==='c')host.push(`--runtime-c=${config.runtimeC}`);
 for(const path of config.manifests)host.push(`--stage-manifest=${path}`);
 for(const path of config.receipts)host.push(`--stage-receipt=${path}`);
 if(profileDirectory!==null)host.push(`--stage-profile=${profileDirectory}`);
 host.push(config.source,'-o',output);
 const node=[config.node.path,'--experimental-strip-types',config.worker,config.candidateHost,...host];
 const command=['/usr/bin/time',TIME,...node];
 const gate=[process.execPath,config.heavyGate,'--memory-mib',String(LIMITS.memoryMiB),'--rss-mib',String(LIMITS.rssMiB),
  '--poll-ms',String(LIMITS.pollMs),'--term-grace-ms',String(LIMITS.termGraceMs),'--timeout-ms',String(config.timeoutMs),'--',...command];
 const stdoutPath=join(directory,'stdout.log'),stderrPath=join(directory,'stderr.log');
 Object.assign(row,{directory,argv:{gate,command,node,host},logs:{stdout:{path:stdoutPath},stderr:{path:stderrPath}}});
 mkdirSync(directory);
 const rowsBefore=closure(config),closureBefore=closureDigest(rowsBefore),before=pinMap(config,rowsBefore);
 row.pins={before:pinDigest(before),closureBefore,entries:before.size};
 drift(initial,before,'before pair-'+pair+'-'+kind);
 const outFd=openSync(stdoutPath,'wx',0o644);
 let errFd;
 try{errFd=openSync(stderrPath,'wx',0o644);}catch(error){closeSync(outFd);throw error;}
 let run;
 try{run=spawnSync(gate[0],gate.slice(1),{cwd:REPO,env:config.env,stdio:['ignore',outFd,errFd],
  timeout:Math.min(2147483647,config.timeoutMs+300000),killSignal:'SIGKILL'});}finally{closeSync(outFd);closeSync(errFd);}
 must(!run.error,'heavy-gate launcher failed: '+text(run.error));
 const stdout=readFileSync(stdoutPath,'utf8'),stderr=readFileSync(stderrPath,'utf8');
 row.logs={stdout:{path:stdoutPath,bytes:Buffer.byteLength(stdout),sha256:sha(stdout)},
  stderr:{path:stderrPath,bytes:Buffer.byteLength(stderr),sha256:sha(stderr)}};
 row.diagnostics={candidateLines:stderr.split('\n').filter(line=>line.startsWith('candidate: '))};
 const guardianRecord=guardian(stderr,command,config);
 must(run.status===guardianRecord.exitCode&&guardianRecord.supervisorExitCode===run.status,'guardian exit differs from launcher exit');
 row.guardian=guardianRecord;
 row.child=timeReceipt(stderr);
 const lines=stdout.split('\n').map(line=>line.trim()).filter(Boolean);
 must(lines.length>0,'candidate printed no result');
 const result=JSON.parse(lines[lines.length-1]);
 must(result.output===output,'candidate output path differs from -o');
 must(existsSync(output),'candidate reported success but wrote no output');
 const outputPin=pin(output);
 must(result.sha256===outputPin.sha256&&result.bytes===outputPin.bytes,'candidate result differs from output bytes');
 must(result.target===config.target&&result.library===true&&
  JSON.stringify(result.exports)===JSON.stringify(config.exportsList),'candidate result identity differs');
 must(Number.isSafeInteger(result.modules)&&result.modules>0,'candidate module count is missing');
 must(row.diagnostics.candidateLines.length===0,'successful leg produced candidate diagnostics');
 row.output={path:output,bytes:outputPin.bytes,sha256:outputPin.sha256};
 row.candidate={sha256:result.sha256,bytes:result.bytes,target:result.target,library:result.library,
  exports:result.exports,modules:result.modules,foreignFiles:result.foreignFiles};
 if(profileDirectory===null){
  must(result.stageProfile===undefined&&!existsSync(join(directory,'profile')),'off leg produced profile evidence');
 }else{
  must(typeof result.stageProfile==='string','on leg result carries no stageProfile');
  row.profile=profile(config,profileDirectory,output,result.stageProfile);
 }
 const rowsAfter=closure(config),closureAfter=closureDigest(rowsAfter),after=pinMap(config,rowsAfter);
 drift(before,after,'after pair-'+pair+'-'+kind);
 drift(initial,after,'between legs at pair-'+pair+'-'+kind);
 must(closureAfter===closureBefore,'source closure digest changed during the leg');
 row.pins={before:pinDigest(before),after:pinDigest(after),closureBefore,closureAfter,entries:after.size};
}
function statistics(summaryLegs,metric){
 const values=summaryLegs.map(metric),sorted=[...values].sort((left,right)=>left-right);
 const middle=sorted.length>>1,median=sorted.length%2===1?sorted[middle]:(sorted[middle-1]+sorted[middle])/2;
 return {values,median,min:sorted[0],max:sorted[sorted.length-1],range:sorted[sorted.length-1]-sorted[0]};
}
function summarise(legs){
 const metrics=[['wallMs',row=>row.child.realMs],['userMs',row=>row.child.userMs],['systemMs',row=>row.child.systemMs],
  ['cpuMs',row=>row.child.userMs+row.child.systemMs],['childMaxRssBytes',row=>row.child.maxRssBytes],
  ['guardianElapsedMs',row=>row.guardian.elapsedMs],['guardianPeakRssBytes',row=>row.guardian.peakRssBytes],
  ['guardianPeakFootprintBytes',row=>row.guardian.peakFootprintBytes]];
 const off=legs.filter(row=>row.kind==='off'),on=legs.filter(row=>row.kind==='on');
 const perKind={off:{},on:{}},comparison={};
 for(const [name,metric] of metrics){
  const baseline=statistics(off,metric),observed=statistics(on,metric);
  perKind.off[name]=baseline;perKind.on[name]=observed;
  comparison[name]={offMedian:baseline.median,onMedian:observed.median,delta:observed.median-baseline.median,
   ratio:baseline.median===0?null:observed.median/baseline.median,
   percentDelta:baseline.median===0?null:(observed.median/baseline.median-1)*100};
 }
 return {diagnosticOnly:true,acceptanceEvidence:false,perKind,comparison,
  note:'0.01 s wait4 resolution; alternating operational samples, not isolated instrumentation cost or exclusive CPU'};
}
function main(){
 const cwd=process.cwd();
 let input;
 try{input=options(process.argv.slice(2));}catch(error){console.error('compiler_profile_overhead: '+text(error));process.exitCode=2;return;}
 const reportPath=resolve(cwd,input.report);
 if(existsSync(reportPath)){console.error('compiler_profile_overhead: report exists: '+reportPath);process.exitCode=2;return;}
 let reportParent;
 try{reportParent=statSync(dirname(reportPath));}catch(error){console.error('compiler_profile_overhead: report parent unreadable: '+text(error));process.exitCode=2;return;}
 if(!reportParent.isDirectory()){console.error('compiler_profile_overhead: report parent is not a directory');process.exitCode=2;return;}
 let reportFd;
 try{reportFd=openSync(reportPath,'wx',0o644);}catch(error){console.error('compiler_profile_overhead: cannot create report: '+text(error));process.exitCode=2;return;}
 const report={schemaVersion:1,kind:'compiler-profile-overhead-diagnostic',status:'FAIL',diagnosticOnly:true,
  acceptanceEvidence:false,createdAt:new Date().toISOString(),finishedAt:null,error:null,failedAt:null,
  scope:'alternating off/on operational comparison of candidate_host.ts on one pinned image and closure; off legs omit --stage-profile and on legs add only it; child wall/user/system/maxRSS are Darwin /usr/bin/time -lp wait4 receipts and guardian RSS/footprint are separate samples; no reruns, retries, output patching, emitted-program execution or acceptance claim',
  limits:{...LIMITS,timeoutMs:input.timeoutMs,acceptanceTimeoutMs:ACCEPTANCE_TIMEOUT_MS,
   diagnosticTimeoutOnly:input.timeoutMs>ACCEPTANCE_TIMEOUT_MS},
  runtime:{harness:{execPath:process.execPath,versions:process.versions,argv:process.argv.slice()},node:null,time:{path:'/usr/bin/time',args:[TIME]}},
  paths:null,pins:null,legs:[],summary:null};
 let failure=null,phase='configure';
 try{
  must(process.platform==='darwin','this harness requires Darwin /usr/bin/time -lp; other platforms are unsupported');
  must(typeof process.versions.bun==='string','run this harness with bun');
  must(existsSync('/usr/bin/time'),'/usr/bin/time is unavailable');
  process.chdir(REPO);
  const config=configure(input,cwd);
  config.workRoot=mkdtempSync(join(tmpdir(),'bend2039g7-overhead-'));
  config.worker=join(config.workRoot,'candidate-worker.mjs');
  writeFileSync(config.worker,ADAPTER,{flag:'wx',mode:0o644});
  report.runtime.node=config.node;
  report.runtime.semantics={node:'recorded by path and version, not hashed; runtime immutability is not claimed',
   bun:'recorded by process.execPath and process.versions.bun, not hashed; runtime immutability is not claimed'};
  report.paths={repoRoot:REPO,report:reportPath,workRoot:config.workRoot,source:config.source,candidate:config.candidate,
   parser:config.parser,parserSeparate:config.parserSeparate,base:config.base,runtimeC:config.runtimeC,
   candidateBuild:config.candidateBuild,stepRuntime:config.stepRuntime,
   manifests:config.manifests,receipts:config.receipts,worker:config.worker,node:config.node.path,
   heavyGate:config.heavyGate,candidateHost:config.candidateHost,stageHelper:config.stageHelper,collector:config.collector};
  phase='initial-pins';
  const rows=closure(config),initial=pinMap(config,rows);
  report.pins={closure:{root:config.source,target:config.target,digest:closureDigest(rows),
   sources:rows.sources.map(row=>({path:row.path,sha256:row.sha256,namespace:row.namespace})),
   externals:rows.externals.map(row=>({path:row.path,sha256:row.sha256}))},
   candidateBuild:config.candidateBuild,candidateBuildClosure:config.candidateBuildPins,
   files:[...initial.entries()].map(([path,digest])=>({path,sha256:digest})).sort((left,right)=>left.path.localeCompare(right.path)),
   digest:pinDigest(initial),entries:initial.size};
  for(let pair=1;pair<=config.pairs;pair+=1){
   for(const kind of pair%2===1?['off','on']:['on','off']){
    phase='pair-'+pair+'-'+kind;
    const row={pair,kind,sequence:report.legs.length+1,status:'RUNNING',diagnosticOnly:true,acceptanceEvidence:false,
     directory:null,argv:null,logs:null,pins:null,guardian:null,child:null,profile:null,output:null,
     candidate:null,diagnostics:{candidateLines:[]},error:null};
    report.legs.push(row);
    try{leg(config,initial,row);row.status='PASS';}
    catch(error){row.status='FAIL';row.error=text(error);throw error;}
   }
  }
  phase='cross-leg-checks';
  const legs=report.legs;
  must(legs.length===config.pairs*2,'leg count differs from pairs');
  const hosts=legs.map(row=>row.argv.host.map(argument=>argument===row.output.path?'<output>':argument)
   .filter(argument=>!argument.startsWith('--stage-profile=')));
  must(new Set(hosts.map(host=>JSON.stringify(host))).size===1,'leg arguments differ beyond --stage-profile and output path');
  must(legs.every(row=>row.argv.host.filter(argument=>argument.startsWith('--stage-profile=')).length===(row.kind==='on'?1:0)),
   'leg carries the wrong number of --stage-profile options');
  const reference=readFileSync(legs[0].output.path);
  for(const row of legs)must(readFileSync(row.output.path).equals(reference),'output bytes differ in '+row.sequence);
  must(new Set(legs.map(row=>row.output.sha256)).size===1,'output digests differ');
  must(new Set(legs.map(row=>row.output.bytes)).size===1,'output sizes differ');
  const identities=legs.map(row=>JSON.stringify({sha256:row.candidate.sha256,bytes:row.candidate.bytes,
   target:row.candidate.target,library:row.candidate.library,exports:row.candidate.exports,
   modules:row.candidate.modules,foreignFiles:row.candidate.foreignFiles}));
  must(new Set(identities).size===1,'candidate identity differs across legs');
  must(legs.filter(row=>row.kind==='on').every(row=>row.profile&&row.profile.measurementStatus==='complete'),
   'an on leg lacks a complete collector profile');
  report.summary=summarise(legs);
  report.status='PASS';
 }catch(error){failure=error;report.error=text(error);report.failedAt=phase;report.status='FAIL';}
 report.finishedAt=new Date().toISOString();
 try{writeFileSync(reportFd,JSON.stringify(report,null,2)+'\n');}finally{closeSync(reportFd);}
 console.log(JSON.stringify({status:report.status,report:reportPath,legs:report.legs.length,error:report.error??undefined}));
 if(failure!==null)process.exitCode=1;
}
main();
