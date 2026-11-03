#!/usr/bin/env bun
/** Read-only G56 calibration analysis. Never imports compiler images or launches jobs. */
import {existsSync, readFileSync, realpathSync, writeFileSync} from 'node:fs';
import {basename, dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {ABI, corpusFor, hashPath, workloadRows} from './native_seed_runtime.mjs';

type ObjectRow = Record<string, any>;
type Verdict = 'PASS' | 'FAIL' | 'INCONCLUSIVE' | 'INVALID';
type Direction = 'improvement' | 'regression' | 'equivalent' | 'inconclusive';
export interface PairedStatistics {
  n:number; logRatios:number[]; meanLog:number|null; varianceLog:number|null;
  geometricMeanRatio:number|null; ci95:number[]|null; baselineMedian:number|null; variantMedian:number|null;
}
interface Thresholds {practicalBand:number; stationarityMedian:number; orderLogDifference:number; magnitudeLogTolerance:number}
interface PairPlan {variant:string; corpus:string; session:string; order:('baseline'|'variant')[]; reports:{baseline:string; variant:string}}
interface Plan {
  schemaVersion:1; baseline:string;
  corpora:{id:string; kind:'full'|'screen'; manifest:string; manifestSha256?:string; role?:'control'}[];
  images:{id:string; image:string; receipt:string; sha256:string; origin:'native'}[];
  pairs:PairPlan[]; thresholds:Thresholds;
  execution?:{profiling:boolean; oneHeavyLane:boolean; freshProcesses:boolean};
  preregistered?:boolean;
  runtime?:{nodeSha256:string};
  holdout?:{variant:string; operational:boolean; selectionFrozenBeforeResponses:boolean};
  structuralDecisions?:Record<string, ObjectRow>;
}
const MiB = 1024 * 1024;
const limits = {memoryMiB:8192, rssMiB:8192, pollMs:10, timeoutMs:600000};
const workerPolicy = {stackMiB:256, oldGenerationMiB:6144, youngGenerationMiB:128};
const flags = ['--experimental-strip-types', '--max-old-space-size=6144', '--max-semi-space-size=128'];
// These are the existing, frozen throughput request pins, not newly generated drivers.
const tools:Record<string,string> = {
  'selfhost_throughput.mjs':'1a806befee02216a9499f6b4dcde7e2326e01f0a5b96bbd36b75295344c50317',
  'checker_core_step_runtime.mjs':'00cd400ac0452a3681bf6491db08be51f9ae3a33ff2baf88654a9763eb5073ed',
  'selfhost_cpu_profile.mjs':'5d5fc8d329a3b600522c58eeac59c49c515109bc7f48845d8177cb520129a1c0',
  'native_seed_runtime.mjs':'7f81a9b9013853355910b93bf59586b2acbcda4de7bcaa08d7942ebf45c0147a',
  'heavy_gate.ts':'e72f2b81970be76734df918e35b1a4289d0fb194039e5ca20e9785e5ac0ee015',
};
const object = (x:any):x is ObjectRow => x !== null && typeof x === 'object' && !Array.isArray(x);
const finite = (x:any):x is number => typeof x === 'number' && Number.isFinite(x);
const positive = (x:any):x is number => finite(x) && x > 0;
const digest = (x:any):x is string => typeof x === 'string' && /^[a-f0-9]{64}$/.test(x);
function requireThat(condition:any, reason:string):asserts condition {if (!condition) throw Error(reason);}
function canonical(x:any):string {
  if (Array.isArray(x)) return '[' + x.map(canonical).join(',') + ']';
  if (object(x)) return '{' + Object.keys(x).sort().map(k => JSON.stringify(k)+':'+canonical(x[k])).join(',') + '}';
  return JSON.stringify(x);
}
const same = (a:any,b:any) => canonical(a) === canonical(b);
const mean = (xs:number[]) => xs.reduce((a,b) => a+b,0)/xs.length;
export function median(xs:number[]):number|null {
  if (!xs.length) return null;
  const a = [...xs].sort((x,y) => x-y), m = Math.floor(a.length/2);
  return a.length%2 ? a[m]! : (a[m-1]!+a[m]!)/2;
}
const variance = (xs:number[]) => {const m = mean(xs); return xs.reduce((s,x) => s+(x-m)**2,0)/(xs.length-1);};
// Lanczos log-gamma and continued-fraction incomplete beta give Student-t quantiles
// for both integer paired degrees of freedom and fractional Welch degrees of freedom.
function logGamma(z:number):number {
  const c = [676.5203681218851,-1259.1392167224028,771.32342877765313,-176.61502916214059,12.507343278686905,-0.13857109526572012,9.9843695780195716e-6,1.5056327351493116e-7];
  if (z < 0.5) return Math.log(Math.PI)-Math.log(Math.sin(Math.PI*z))-logGamma(1-z);
  z -= 1; let x = 0.99999999999980993;
  for (let i=0;i<c.length;i++) x += c[i]!/(z+i+1);
  const t = z+7.5;
  return 0.5*Math.log(2*Math.PI)+(z+0.5)*Math.log(t)-t+Math.log(x);
}
function betaFraction(a:number,b:number,x:number):number {
  const tiny = 1e-300, safe = (v:number) => Math.abs(v)<tiny ? tiny : v;
  let c=1, d=1/safe(1-(a+b)*x/(a+1)), h=d;
  for (let m=1;m<=300;m++) {
    let aa=m*(b-m)*x/((a+2*m-1)*(a+2*m));
    d=1/safe(1+aa*d); c=safe(1+aa/c); h*=d*c;
    aa=-(a+m)*(a+b+m)*x/((a+2*m)*(a+2*m+1));
    d=1/safe(1+aa*d); c=safe(1+aa/c); const delta=d*c; h*=delta;
    if (Math.abs(delta-1)<3e-14) return h;
  }
  throw Error('Student-t incomplete beta did not converge');
}
function beta(x:number,a:number,b:number):number {
  if (x<=0) return 0; if (x>=1) return 1;
  const factor=Math.exp(logGamma(a+b)-logGamma(a)-logGamma(b)+a*Math.log(x)+b*Math.log1p(-x));
  return x<(a+1)/(a+b+2) ? factor*betaFraction(a,b,x)/a : 1-factor*betaFraction(b,a,1-x)/b;
}
export function studentT95(df:number):number {
  requireThat(positive(df), 'Student-t requires positive degrees of freedom');
  const cdf=(t:number) => 1-0.5*beta(df/(df+t*t),df/2,0.5);
  let lo=0, hi=1; while (cdf(hi)<0.975) hi*=2;
  for (let i=0;i<90;i++) {const mid=(lo+hi)/2; if(cdf(mid)<0.975)lo=mid;else hi=mid;}
  return (lo+hi)/2;
}
export function pairedStats(baseline:number[], variant:number[]):PairedStatistics {
  requireThat(baseline.length===variant.length && baseline.every(positive) && variant.every(positive), 'Paired metrics must be equally sized, finite and positive');
  const logs=baseline.map((x,i) => Math.log(variant[i]!/x)), n=logs.length;
  if (!n) return {n, logRatios:logs, meanLog:null, varianceLog:null, geometricMeanRatio:null, ci95:null, baselineMedian:null, variantMedian:null};
  const m=mean(logs), v=n>1?variance(logs):null, half=v===null?null:studentT95(n-1)*Math.sqrt(v/n);
  return {n, logRatios:logs, meanLog:m, varianceLog:v, geometricMeanRatio:Math.exp(m),
    ci95:half===null?null:[Math.exp(m-half),Math.exp(m+half)], baselineMedian:median(baseline), variantMedian:median(variant)};
}
export function classifyRatio(ci:number[]|null, practicalBand:number):Direction {
  if (!ci || ci.length!==2 || !ci.every(positive) || ci[0]!>ci[1]!) return 'inconclusive';
  if (ci[1]!<1-practicalBand) return 'improvement';
  if (ci[0]!>1+practicalBand) return 'regression';
  if (ci[0]!>=1-practicalBand && ci[1]!<=1+practicalBand) return 'equivalent';
  return 'inconclusive';
}
export function independentDifference(screen:PairedStatistics, full:PairedStatistics) {
  if (screen.n<2 || full.n<2 || screen.varianceLog===null || full.varianceLog===null || screen.meanLog===null || full.meanLog===null) return null;
  const a=screen.varianceLog/screen.n, b=full.varianceLog/full.n, v=a+b;
  const df=v===0 ? null : v*v/(a*a/(screen.n-1)+b*b/(full.n-1));
  const m=screen.meanLog-full.meanLog, half=df===null?0:studentT95(df)*Math.sqrt(v);
  return {meanLogDifference:m, ci95:[m-half,m+half], degreesOfFreedom:df, method:'Independent paired cohorts; Welch-Satterthwaite Student-t (zero variance gives a degenerate interval)'};
}
function load(path:string):ObjectRow {const value=JSON.parse(readFileSync(path,'utf8')); requireThat(object(value),'Expected JSON object: '+path); return value;}
function capture(reasons:string[], action:()=>void) {try {action();} catch(error) {reasons.push(String(error));}}
function checkLimits(value:any) {requireThat(object(value) && Object.entries(limits).every(([k,v])=>value[k]===v),'Original limits must be 8192MiB RSS/footprint, 10ms poll, 600000ms timeout');}
function checkGuardian(g:any, timed:boolean) {
  requireThat(object(g) && g.status==='PASS' && g.reportPhase==='complete' && g.ownedTreeStopped===true && g.exitCode===0 && g.supervisorExitCode===0 && g.commandExitCode===0 && g.commandSignal===0,'Guardian did not complete successfully');
  if(timed) {
    requireThat(g.memoryLimitBytes===8192*MiB && g.rssLimitBytes===8192*MiB && g.timeoutMs===600000,'Guardian limits drift');
    requireThat(positive(g.peakRssBytes) && positive(g.peakFootprintBytes) && g.peakRssBytes<=g.rssLimitBytes && g.peakFootprintBytes<=g.memoryLimitBytes,'Guardian resource limit violation or missing peaks');
    requireThat(positive(g.elapsedMs) && g.elapsedMs<=g.timeoutMs,'Guardian elapsed time exceeds original deadline');
  }
}
function validatePlan(p:any):asserts p is Plan {
  requireThat(p.schemaVersion===1 && p.baseline==='G50','Expected schemaVersion 1 and baseline G50');
  requireThat(Array.isArray(p.images) && p.images.length>=2 && p.images.length<=3,'Expected native baseline and one or two variants');
  requireThat(Array.isArray(p.corpora) && p.corpora.length>0 && p.corpora.length<=5,'Expected one to five corpora, including at most three candidates and one control');
  requireThat(Array.isArray(p.pairs) && p.pairs.length<=60,'Expected bounded pairs array (at most 60)');
  for(const rows of [p.images,p.corpora]) requireThat(rows.every((r:any)=>object(r)&&typeof r.id==='string'&&r.id.length>0) && new Set(rows.map((r:any)=>r.id)).size===rows.length,'Missing or duplicate image/corpus id');
  requireThat(p.images.some((x:any)=>x.id===p.baseline),'Baseline image missing');
  requireThat(p.images.every((x:any)=>typeof x.image==='string'&&typeof x.receipt==='string'&&digest(x.sha256)),'Image paths and SHA-256 are required');
  requireThat(p.corpora.every((x:any)=>['full','screen'].includes(x.kind)&&typeof x.manifest==='string'),'Invalid corpus kind or manifest');
  requireThat(p.corpora.filter((x:any)=>x.kind==='full').length<=1 && p.corpora.filter((x:any)=>x.kind==='screen'&&x.role!=='control').length<=3 && p.corpora.filter((x:any)=>x.role==='control').length<=1,'At most one full reference, three candidates and one control');
  requireThat(object(p.thresholds) && same(p.thresholds,{practicalBand:0.02,stationarityMedian:0.05,orderLogDifference:0.03,magnitudeLogTolerance:0.03}),'Plan must explicitly pin G56 tolerances 0.02/0.05/0.03/0.03');
  for(const x of p.pairs) {
    requireThat(object(x) && p.images.some((i:any)=>i.id===x.variant&&i.id!==p.baseline) && p.corpora.some((c:any)=>c.id===x.corpus),'Unknown pair variant/corpus');
    requireThat(typeof x.session==='string'&&x.session.length>0&&(same(x.order,['baseline','variant'])||same(x.order,['variant','baseline'])),'Pair needs session and AB or BA order');
    requireThat(object(x.reports)&&typeof x.reports.baseline==='string'&&typeof x.reports.variant==='string','Pair needs both report paths');
  }
}

export function analyzeCalibration(planPath:string):ObjectRow {
  const planFile=realpathSync(planPath), base=dirname(planFile), plan=load(planFile);
  const output:ObjectRow={schemaVersion:1, status:'INCONCLUSIVE', diagnosticOnly:true, acceptanceEvidence:false,
    plan:{path:planFile,sha256:hashPath(planFile)}, errors:[], images:[], corpora:[], cells:[], pairs:[], rejectedCells:[], matrix:[], comparisons:[], qualification:[],
    scope:'Fresh own-image parse/expand/check of these frozen inputs, native-produced images driven in js mode; checker-wall screening calibration only.',
    limitations:[
      'Six-pair Student-t intervals assume independent pairs and approximately normal log effects; small n does not establish the distribution or robust tail behavior.',
      'Paired cohorts are independent across full and screen; no baseline pooling across variants, sessions or corpora.',
      'CPU is process-wide, including helper threads, not isolated checker CPU. Phase CPU sums exclude pipeline overhead; guardian peaks are sampled whole-tree peaks.',
      'G55 is only an operational holdout: its history is already known. Historical one-pair wall signs are not calibration truth.',
      'Structural decisions and execution/preregistration attestations are caller assertions with hashed evidence, not automatically established by the timing reports.',
      'Reports cannot attest absence of profiling environment or prior response-based selection; missing plan attestations prevent qualification.',
      'Checking emitter source does not execute emission. No compiler correctness acceptance, emitter calibration, future optimization or arbitrary-project guarantee.',
      'Raw reports remain untouched. Missing/failed cells are retained, never replaced, retried or counted as timing pairs.',
    ]};
  try {validatePlan(plan);} catch(error) {output.errors.push(String(error)); output.status='INVALID'; return output;}
  const p:Plan=plan;
  output.thresholds=p.thresholds;
  output.structuralThresholds={majorCategoryFraction:0.05,maxSyntaxTotalVariation:0.20,minAttributableCpuSamples:1000,maxCpuFamilyTotalVariation:0.20,maxUnclassifiedFraction:0.20};
  const pathAt=(path:string)=>resolve(base,path);
  const realAt=(path:string)=>realpathSync(pathAt(path));
  const imageMap=new Map<string,ObjectRow>(), corpusMap=new Map<string,ObjectRow>();
  for(const image of p.images) {
    const row:ObjectRow={...image,image:pathAt(image.image),receipt:pathAt(image.receipt),reasons:[]};
    capture(row.reasons,()=>{
      requireThat(image.origin==='native','Canonical/native mixing forbidden');
      row.image=realAt(image.image); row.receipt=realAt(image.receipt); row.receiptSha256=hashPath(row.receipt);
      requireThat(hashPath(row.image)===image.sha256,'Pinned image SHA-256 drift');
      const r=load(row.receipt);
      requireThat(r.status==='NATIVE_FULL_COMPILE_PASS','Receipt does not identify a successful native full compile');
      requireThat(typeof r.output==='string'&&realAt(r.output)===row.image&&r.outputSha256===image.sha256,'Producer output path/hash differs from selected image');
      requireThat(r.boundary?.outputPatches===0&&r.boundary?.checksExcluded===0&&r.boundary?.cachedAst===false&&r.boundary?.hostChecking===false&&r.boundary?.hostParsing===false,'Producer boundary was patched, excluded, replayed or host-interpreted');
      requireThat(r.result?.result==='EmitSuccess'&&same(r.exports,ABI),'Native compile lacks EmitSuccess or ABI13');
      requireThat(Array.isArray(r.command)&&r.command.at(-2)==='compile'&&realAt(r.command.at(-1))===row.image,'Native compile command does not identify output');
      requireThat(same(r.phases?.map((x:any)=>x.phase),['parse','expand','check','emit']),'Native producer did not complete every compile phase');
      checkGuardian(r.guardian,false);
      row.producer={status:r.status,command:r.command,outputSha256:r.outputSha256,build:r.build,buildSha256:r.buildSha256,corpus:r.corpus,corpusSha256:r.corpusSha256};
    });
    row.status=row.reasons.length?'INVALID':'PASS'; imageMap.set(image.id,row); output.images.push(row);
  }
  for(const corpus of p.corpora) {
    const row:ObjectRow={...corpus,manifest:pathAt(corpus.manifest),reasons:[]};
    capture(row.reasons,()=>{
      row.manifest=realAt(corpus.manifest); row.manifestSha256=hashPath(row.manifest);
      if(corpus.manifestSha256!==undefined)requireThat(digest(corpus.manifestSha256)&&row.manifestSha256===corpus.manifestSha256,'Plan-pinned corpus manifest hash drift');
      const m=load(row.manifest);
      requireThat(m.schemaVersion===1&&typeof m.directory==='string'&&typeof m.root==='string'&&same(m.exports,ABI)&&Array.isArray(m.files),'Invalid ordinary corpus manifest');
      row.directory=realAt(m.directory); row.root=realpathSync(resolve(row.directory,m.root));
      const old=process.cwd(); let actual:any;
      // workloadRows resolves Base from cwd; do not replace its namespace/foreign-source rules.
      try {process.chdir(row.directory); actual=corpusFor(workloadRows(row.root,'js'));} finally {process.chdir(old);}
      const expected=new Map<string,any>();
      for(const f of m.files) {
        requireThat(object(f)&&typeof f.path==='string'&&digest(f.sha256),'Malformed corpus file');
        const file=realpathSync(resolve(row.directory,f.path));
        requireThat(!expected.has(file),'Duplicate corpus path or alias: '+file);
        expected.set(file,{sha256:f.sha256,external:f.external===true,namespace:f.external===true?null:f.namespace});
      }
      const observed=new Map<string,any>(actual.files.map((f:any)=>[realpathSync(resolve(row.directory,f.path)),{sha256:f.sha256,external:f.external===true,namespace:f.external===true?null:f.namespace}]));
      requireThat(same(Object.fromEntries(expected),Object.fromEntries(observed)),'Frozen manifest differs from complete authentic workload closure (including foreign files and namespaces)');
      row.inputs=Object.fromEntries([...expected].map(([file,v])=>[file,v.sha256]));
      row.moduleCount=actual.files.filter((f:any)=>!f.external).length; row.fileCount=actual.files.length;
      row.fingerprint=m.fingerprint??null; row.provenance=m.provenance??null;
    });
    row.status=row.reasons.length?'INVALID':'PASS'; corpusMap.set(corpus.id,row); output.corpora.push(row);
  }
  const seenReports=new Map<string,ObjectRow[]>(), seenRequests=new Map<string,ObjectRow[]>();
  function cell(reportName:string, imageId:string, corpusId:string, pairIndex:number, role:string):ObjectRow {
    const c:ObjectRow={pairIndex,role,image:imageId,corpus:corpusId,report:pathAt(reportName),reasons:[],pendingReasons:[],status:'INVALID'};
    const image=imageMap.get(imageId)!, corpus=corpusMap.get(corpusId)!;
    let r:ObjectRow|undefined, q:ObjectRow|undefined;
    if(!existsSync(c.report)) {
      c.pendingReasons.push('Scheduled report is missing; no timing row admitted');
      output.cells.push(c); return c;
    }
    capture(c.reasons,()=>{
      c.report=realAt(reportName); c.reportSha256=hashPath(c.report); r=load(c.report);
      const peers=seenReports.get(c.report)??[]; peers.push(c); seenReports.set(c.report,peers);
      if(r.status==='RUNNING') {
        c.pendingReasons.push('Scheduled report is still RUNNING; no timing row admitted');
        return;
      }
      requireThat(typeof r.request==='string','Report has no actual request path');
      c.request=realAt(r.request); c.requestSha256=hashPath(c.request); q=load(c.request);
      const requests=seenRequests.get(c.request)??[]; requests.push(c); seenRequests.set(c.request,requests);
    });
    if(image.status!=='PASS')c.reasons.push('Image rejected: '+image.reasons.join('; '));
    if(corpus.status!=='PASS')c.reasons.push('Corpus rejected: '+corpus.reasons.join('; '));
    if(r&&q) {
      const report=r, request=q;
      capture(c.reasons,()=>{
        requireThat(report.schemaVersion===1&&report.status==='PASS'&&report.mode==='js'&&report.stopAfter==='check','Report is missing, incomplete, failed, or not js/check');
        requireThat(report.requestSha256===c.requestSha256,'Actual request digest differs from report');
        requireThat(report.diagnosticOnly===true&&report.acceptanceEvidence===false,'Diagnostic/acceptance scope changed');
        requireThat(report.checksExcluded===0&&report.outputPatches===0&&!Object.hasOwn(report,'output')&&!Object.hasOwn(report,'activePhase')&&!Object.hasOwn(report,'error'),'Checks excluded, output patched, unexpected output, or incomplete/failed phase');
        requireThat(request.schemaVersion===1&&request.stopAfter==='check'&&!Object.hasOwn(request,'expectedSelfhostOutput')&&same(request.exports,ABI)&&same(report.exports,ABI),'Request stop policy or ABI drift');
        requireThat(realAt(request.image)===image.image&&realAt(request.root)===corpus.root&&realAt(report.source)===corpus.root&&realAt(request.repository)===corpus.directory,'Request image/root/repository identity drift');
        requireThat(report.sourceSha256===corpus.inputs?.[corpus.root]&&same(request.inputs,corpus.inputs),'Request frozen closure/hash drift');
        requireThat(report.moduleCount===corpus.moduleCount&&Number.isSafeInteger(report.sourceDeclarations)&&report.sourceDeclarations>0,'Successful own-parse module/declaration evidence missing');
        checkLimits(request.limits); checkLimits(report.limits);
        requireThat(same(report.workerPolicy,workerPolicy),'Worker stack/heap policy drift');
        checkGuardian(report.guardian,true);
      });
      capture(c.reasons,()=>{
        requireThat(object(request.pins),'Missing request pins');
        for(const [path,sha] of Object.entries(request.pins)) requireThat(digest(sha)&&realpathSync(path)===path&&hashPath(path)===sha,'Pinned file drift: '+path);
        requireThat(request.pins[image.image]===image.sha256,'Actual request does not pin selected image');
        c.toolPins={};
        for(const [name,sha] of Object.entries(tools)) {
          const matches=Object.keys(request.pins).filter(path=>basename(path)===name);
          requireThat(matches.length===1&&request.pins[matches[0]!]===sha,'Original tool pin missing/drift: '+name);
          c.toolPins[name]={path:matches[0],sha256:sha};
        }
        const driver=c.toolPins['selfhost_throughput.mjs'].path;
        for(const name of Object.keys(tools)) requireThat(c.toolPins[name].path===realpathSync(resolve(dirname(driver),name)),'Pinned tool is not the actual driver sibling: '+name);
        c.guardianHelper={path:realpathSync(resolve(dirname(driver),'heavy_gate_native.c'))};
        c.guardianHelper.sha256=hashPath(c.guardianHelper.path);
        requireThat(c.guardianHelper.sha256==='1ff233edacdbf13c6ffd4a8bf38cbf153629e8c76be4860deec8a5b591d3fa8b','Original guardian native helper drift');
        requireThat(same(report.runtime?.execArgv,flags)&&typeof report.runtime?.versions?.node==='string'&&positive(report.runtime?.heapLimitBytes),'Runtime version/flags missing or changed');
        const node=realAt(request.node);
        requireThat(realAt(report.runtime.execPath)===node,'Reported runtime differs from request Node');
        c.runtime={...report.runtime,execPath:node,sha256:hashPath(node)};
        if(p.runtime)requireThat(digest(p.runtime.nodeSha256)&&c.runtime.sha256===p.runtime.nodeSha256,'Plan-pinned Node binary drift');
        const command=report.guardian.command;
        requireThat(Array.isArray(command)&&command.length===10&&realAt(command[0])===node&&same(command.slice(1,4),flags)&&realAt(command[4])===driver&&command[5]==='--worker'&&command[6]==='js'&&realAt(command[7])===c.request&&command[8]===c.requestSha256&&realAt(command[9])===c.report,'Guardian command does not authenticate this exact js/check worker, request and report');
      });
      capture(c.reasons,()=>{
        requireThat(same(report.phases?.map((x:any)=>x.phase),['startup','load-parse','expand','check']),'Own startup/parse/expand/check phases missing, duplicated, or reordered');
        for(const phase of report.phases)requireThat(positive(phase.elapsedMs)&&finite(phase.userCpuMs)&&phase.userCpuMs>=0&&finite(phase.systemCpuMs)&&phase.systemCpuMs>=0&&positive(phase.memoryEnd?.rss)&&positive(phase.memoryEnd?.heapUsed),'Invalid phase wall/CPU/memory evidence');
        requireThat(positive(report.pipelineElapsedMs)&&positive(report.totalElapsedMs)&&report.totalElapsedMs>=report.pipelineElapsedMs&&report.totalElapsedMs<=600000,'Invalid pipeline or total duration');
        requireThat(report.pipelineElapsedMs>=report.phases.reduce((s:number,x:any)=>s+x.elapsedMs,0),'Pipeline wall less than phase sum');
        requireThat(Number.isSafeInteger(report.stepCounts?.check)&&report.stepCounts.check>0&&Number.isSafeInteger(report.stepCounts?.expand)&&report.stepCounts.expand>0&&!Object.hasOwn(report.stepCounts,'emit'),'Completed public scheduler chunk counts missing');
        requireThat(report.phaseCpuScope==='Node process-wide CPU; includes worker/helper threads, excludes child processes','Unexpected CPU measurement scope');
        const check=report.phases[3];
        c.metrics={checkerWallMs:check.elapsedMs,checkerProcessCpuMs:check.userCpuMs+check.systemCpuMs,pipelineWallMs:report.pipelineElapsedMs,
          phaseProcessCpuSumMs:report.phases.reduce((s:number,x:any)=>s+x.userCpuMs+x.systemCpuMs,0),checkerChunks:report.stepCounts.check,
          peakRssBytes:report.guardian.peakRssBytes,peakFootprintBytes:report.guardian.peakFootprintBytes};
        requireThat(Object.values(c.metrics).every(positive),'Missing/nonpositive secondary metric');
        c.stageObservations={phases:report.phases,stepCounts:report.stepCounts,moduleCount:report.moduleCount,sourceDeclarations:report.sourceDeclarations,pipelineElapsedMs:report.pipelineElapsedMs,totalElapsedMs:report.totalElapsedMs,phaseCpuScope:report.phaseCpuScope};
      });
    }
    output.cells.push(c); return c;
  }
  for(let i=0;i<p.pairs.length;i++) {
    const pair=p.pairs[i]!;
    const baseline=cell(pair.reports.baseline,p.baseline,pair.corpus,i,'baseline');
    const variant=cell(pair.reports.variant,pair.variant,pair.corpus,i,'variant');
    output.pairs.push({...pair,index:i,cellIndices:[output.cells.indexOf(baseline),output.cells.indexOf(variant)]});
  }
  for(const [label,groups] of [['report',seenReports],['request',seenRequests]] as const)for(const [path,cells]of groups)if(cells.length>1)for(const c of cells)c.reasons.push('Reused '+label+' is not a fresh independent cell: '+path);
  const identities=output.cells.filter((c:any)=>c.reasons.length===0&&c.pendingReasons.length===0).map((c:any)=>canonical({tools:c.toolPins,helper:c.guardianHelper,runtime:c.runtime}));
  if(new Set(identities).size>1)for(const c of output.cells)if(c.reasons.length===0&&c.pendingReasons.length===0)c.reasons.push('Runtime/driver/helper identity differs across compared cells');
  for(const c of output.cells)c.status=c.reasons.length?'INVALID':c.pendingReasons.length?'INCONCLUSIVE':'PASS';
  for(const pair of output.pairs) {
    const [b,v]=pair.cellIndices.map((i:number)=>output.cells[i]);
    pair.status=b.status==='INVALID'||v.status==='INVALID'?'INVALID':b.status==='PASS'&&v.status==='PASS'?'PASS':'INCONCLUSIVE';
    pair.reasons=[...b.reasons.concat(b.pendingReasons).map((s:string)=>'baseline: '+s),...v.reasons.concat(v.pendingReasons).map((s:string)=>'variant: '+s)];
    pair.checkerWallLogRatio=pair.status==='PASS'?Math.log(v.metrics.checkerWallMs/b.metrics.checkerWallMs):null;
  }
  const attestationReasons:string[]=[];
  if(p.execution?.profiling!==false||p.execution?.oneHeavyLane!==true||p.execution?.freshProcesses!==true)attestationReasons.push('Missing unprofiled, exclusive-lane, fresh-process execution attestation');
  if(p.preregistered!==true)attestationReasons.push('Fixed schedule/corpus selection not attested preregistered');
  if(!digest(p.runtime?.nodeSha256))attestationReasons.push('Node binary was observed but not plan-pinned');
  output.attestations={execution:p.execution??null,preregistered:p.preregistered??null,runtime:p.runtime??null,holdout:p.holdout??null,reasons:attestationReasons};
  for(const variant of p.images.filter(x=>x.id!==p.baseline))for(const corpus of p.corpora) {
    const scheduled=output.pairs.filter((x:any)=>x.variant===variant.id&&x.corpus===corpus.id);
    const accepted=scheduled.filter((x:any)=>x.status==='PASS');
    const b=accepted.map((x:any)=>output.cells[x.cellIndices[0]]), v=accepted.map((x:any)=>output.cells[x.cellIndices[1]]);
    const metrics:ObjectRow={};
    for(const key of ['checkerWallMs','checkerProcessCpuMs','pipelineWallMs','phaseProcessCpuSumMs','checkerChunks','peakRssBytes','peakFootprintBytes'])metrics[key]=pairedStats(b.map((c:any)=>c.metrics[key]),v.map((c:any)=>c.metrics[key]));
    const sessions=[...new Set(scheduled.map((x:any)=>x.session))] as string[];
    const sessionSummaries=sessions.map(session=>{
      const rows=accepted.filter((x:any)=>x.session===session);
      return {session,scheduled:scheduled.filter((x:any)=>x.session===session).length,n:rows.length,
        baselineCheckerMedian:median(rows.map((x:any)=>output.cells[x.cellIndices[0]].metrics.checkerWallMs)),
        variantCheckerMedian:median(rows.map((x:any)=>output.cells[x.cellIndices[1]].metrics.checkerWallMs)),
        meanLogRatio:rows.length?mean(rows.map((x:any)=>x.checkerWallLogRatio)):null};
    });
    const ab=accepted.filter((x:any)=>x.order[0]==='baseline').map((x:any)=>x.checkerWallLogRatio);
    const ba=accepted.filter((x:any)=>x.order[0]==='variant').map((x:any)=>x.checkerWallLogRatio);
    const medians=sessionSummaries.map(x=>x.baselineCheckerMedian);
    const drift=medians.length===2&&medians.every(positive)?Math.max(...medians as number[])/Math.min(...medians as number[])-1:null;
    const orderEffect=ab.length&&ba.length?Math.abs(mean(ab)-mean(ba)):null;
    const reasons=[...attestationReasons];
    const complete=scheduled.length===6&&accepted.length===6&&sessions.length===2&&sessionSummaries.every(x=>x.n===3)&&ab.length===3&&ba.length===3;
    if(!complete)reasons.push('Requires exactly six fresh pairs, two sessions of three, three AB and three BA; pilot/incomplete schedule cannot qualify');
    if(drift!==null&&drift>p.thresholds.stationarityMedian)reasons.push('Baseline session-median drift exceeds 5%');
    if(orderEffect!==null&&orderEffect>p.thresholds.orderLogDifference)reasons.push('AB/BA mean log effects differ by more than 0.03');
    const wall=classifyRatio(metrics.checkerWallMs.ci95,p.thresholds.practicalBand);
    const cpu=classifyRatio(metrics.checkerProcessCpuMs.ci95,p.thresholds.practicalBand);
    if((wall==='improvement'&&cpu==='regression')||(wall==='regression'&&cpu==='improvement'))reasons.push('Confident checker wall/CPU directions are opposite; throughput interpretation requires investigation');
    const invalid=scheduled.some((x:any)=>x.status==='INVALID')||imageMap.get(variant.id)!.status==='INVALID'||imageMap.get(p.baseline)!.status==='INVALID'||corpusMap.get(corpus.id)!.status==='INVALID';
    const direction:Direction=!invalid&&!reasons.length?wall:'inconclusive';
    output.matrix.push({variant:variant.id,corpus:corpus.id,kind:corpus.kind,role:corpus.role??null,scheduledPairs:scheduled.length,acceptedPairs:accepted.length,
      pairIndices:scheduled.map((x:any)=>x.index),status:invalid?'INVALID':direction==='inconclusive'?'INCONCLUSIVE':'PASS',direction,
      descriptiveWallClassification:wall,descriptiveCpuClassification:cpu,metrics,sessionSummaries,
      guards:{completeSixPairSchedule:complete,baselineSessionMedianRelativeDrift:drift,orderMeanLogDifference:orderEffect,abPairs:ab.length,baPairs:ba.length},reasons});
  }
  function structural(id:string):ObjectRow {
    const decision=p.structuralDecisions?.[id], reasons:string[]=[], gates:ObjectRow={};
    if(!decision||decision.complete!==true)reasons.push('Structural decisions incomplete');
    for(const key of ['actualCheckerInput','syntaxCoverage','syntaxTotalVariation','cpuFamilies','tailsAndOmissions']) {
      const gate=decision?.gates?.[key], errors:string[]=[];
      if(!gate||!['PASS','FAIL','INCONCLUSIVE'].includes(gate.status)||typeof gate.reason!=='string'||!gate.reason.length)errors.push('Missing explicit gate status/reason');
      if(!Array.isArray(gate?.evidence)||!gate.evidence.length)errors.push('No hashed structural evidence');
      else for(const ref of gate.evidence)capture(errors,()=>{
        requireThat(object(ref)&&typeof ref.path==='string'&&digest(ref.sha256),'Malformed structural evidence reference');
        requireThat(hashPath(realAt(ref.path))===ref.sha256,'Structural evidence hash drift');
      });
      gates[key]={decision:gate??null,errors};
      if(errors.length||gate?.status==='INCONCLUSIVE')reasons.push(key+': insufficient structural authority');
    }
    const invalid=Object.values(gates).some((x:any)=>x.errors.some((s:string)=>s.includes('hash drift')));
    const fail=Object.values(gates).some((x:any)=>x.decision?.status==='FAIL');
    return {status:invalid?'INVALID':fail?'FAIL':reasons.length?'INCONCLUSIVE':'PASS',complete:decision?.complete===true,gates,reasons,
      authority:'Caller-reviewed structural decisions; evidence digests checked, semantic judgments not recomputed'};
  }
  const full=p.corpora.find(x=>x.kind==='full');
  for(const corpus of p.corpora.filter(x=>x.kind==='screen')) {
    const shape=structural(corpus.id);
    for(const variant of p.images.filter(x=>x.id!==p.baseline)) {
      const s=output.matrix.find((x:any)=>x.variant===variant.id&&x.corpus===corpus.id);
      const f=full?output.matrix.find((x:any)=>x.variant===variant.id&&x.corpus===full.id):undefined;
      const reasons:string[]=[];
      const baselineScreen=s.metrics.pipelineWallMs.baselineMedian, baselineFull=f?.metrics.pipelineWallMs.baselineMedian??null;
      const descriptiveBudget:Verdict=!positive(baselineScreen)||!positive(baselineFull)?'INCONCLUSIVE':baselineScreen<=45000&&baselineScreen/baselineFull<=0.25?'PASS':'FAIL';
      const budget:Verdict=s.guards.completeSixPairSchedule&&f?.guards.completeSixPairSchedule?descriptiveBudget:'INCONCLUSIVE';
      let direction:Verdict='INCONCLUSIVE', magnitude:Verdict='INCONCLUSIVE';
      const difference=f?independentDifference(s.metrics.checkerWallMs,f.metrics.checkerWallMs):null;
      if(s.status==='INVALID'||f?.status==='INVALID'||shape.status==='INVALID')direction=magnitude='INVALID';
      else if(s.direction!=='inconclusive'&&f&&f.direction!=='inconclusive'&&shape.status==='PASS') {
        direction=s.direction===f.direction?'PASS':'FAIL';
        if(difference) {
          const [lo,hi]=difference.ci95, tolerance=p.thresholds.magnitudeLogTolerance;
          magnitude=lo!>=-tolerance&&hi!<=tolerance?'PASS':hi!<-tolerance||lo!>tolerance?'FAIL':'INCONCLUSIVE';
        }
      } else reasons.push('Full/screen effect or structural authority unresolved; no directional agreement inferred');
      if(shape.status==='FAIL')reasons.push('Structural gate failed');
      if(budget!=='PASS')reasons.push('Fast budget requires baseline pipeline median <=45s and <=25% matched full');
      output.comparisons.push({variant:variant.id,screen:corpus.id,full:full?.id??null,direction,magnitude,independentLogDifference:difference,
        structural:shape,budget:{status:budget,descriptiveStatus:descriptiveBudget,baselineScreenMedianMs:baselineScreen,baselineFullMedianMs:baselineFull,maxScreenMs:45000,maxFullFraction:0.25},reasons});
    }
    const rows=output.comparisons.filter((x:any)=>x.screen===corpus.id), holdout=p.holdout;
    const holdoutValid=holdout?.operational===true&&holdout.selectionFrozenBeforeResponses===true&&['G55','G55B'].includes(holdout.variant)&&rows.some((x:any)=>x.variant===holdout.variant);
    const variantsComplete=rows.some((x:any)=>x.variant==='G53')&&holdoutValid;
    let status:Verdict=rows.some((x:any)=>x.direction==='INVALID')?'INVALID':rows.some((x:any)=>x.direction==='FAIL'||x.structural.status==='FAIL'||x.budget.status==='FAIL')?'FAIL':
      corpus.role!=='control'&&variantsComplete&&rows.every((x:any)=>x.direction==='PASS'&&x.budget.status==='PASS')?'PASS':'INCONCLUSIVE';
    output.qualification.push({corpus:corpus.id,status,checkerDirectionQualified:status==='PASS',checkerMagnitudeQualified:status==='PASS'&&rows.every((x:any)=>x.magnitude==='PASS'),
      reasons:[...(corpus.role==='control'?['Named control, not a representative candidate']:[]),...(!variantsComplete?['Requires resolved G53 and operational G55/G55B holdout comparisons with selection frozen before responses']:[])],
      scope:status==='PASS'?'This frozen source corpus matches resolved checker-wall directions for the measured native G53 and G55/G55B images versus G50, under original limits; no broader representativeness claim.':'Representative checker screening qualification not established; retain narrower matrix observations.'});
  }
  const invalid=output.images.some((x:any)=>x.status==='INVALID')||output.corpora.some((x:any)=>x.status==='INVALID')||output.cells.some((x:any)=>x.status==='INVALID')||output.qualification.some((x:any)=>x.status==='INVALID');
  output.status=invalid?'INVALID':output.qualification.some((x:any)=>x.status==='PASS')?'PASS':output.qualification.some((x:any)=>x.status==='FAIL')?'FAIL':'INCONCLUSIVE';
  output.rejectedCells=output.cells.filter((x:any)=>x.status!=='PASS').map((x:any)=>({pairIndex:x.pairIndex,role:x.role,status:x.status,report:x.report,request:x.request??null,requestSha256:x.requestSha256??null,reasons:x.reasons.concat(x.pendingReasons)}));
  return output;
}

if (process.argv[1] && resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
  const args=process.argv.slice(2);
  if(args.length!==2)throw Error('Usage: bun evals/selfhost_corpus_calibration.ts PLAN.json FRESH-REPORT.json');
  const report=analyzeCalibration(args[0]!);
  writeFileSync(resolve(args[1]!),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
  console.log(JSON.stringify({status:report.status,report:resolve(args[1]!),qualification:report.qualification}));
  if(report.status==='INVALID')process.exitCode=1;
}
