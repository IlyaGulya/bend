#!/usr/bin/env bun
// Comparable clean root-to-JS runs. Source algorithms and artifacts are pinned;
// this driver performs IO and advances opaque native-owned Run values only.
import {createHash} from 'node:crypto';
import {readFileSync,writeFileSync,existsSync,realpathSync} from 'node:fs';
import {resolve,dirname,posix,isAbsolute} from 'node:path';
import {pathToFileURL,fileURLToPath} from 'node:url';
import {Worker,isMainThread,workerData} from 'node:worker_threads';
import {getHeapStatistics} from 'node:v8';
import {runHeavyGate} from './heavy_gate.ts';
import {ABI,workloadRows,corpusFor,runtimeManifest,runNativeStage0,requireNativeRun} from './native_seed_runtime.mjs';
import {runTemplateSteps,runCheckerSteps,runLibraryEmitterSteps,sourceFiles,sourceFileTagFromRoot} from './checker_core_step_runtime.mjs';

const script=fileURLToPath(import.meta.url);
const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
const hash=path=>sha(readFileSync(path));
const save=(path,value)=>writeFileSync(path,JSON.stringify(value,null,2)+'\n');
const tag=value=>typeof value?.$==='string'?value.$.split('.').at(-1):null;
const items=value=>{const out=[];while(tag(value)==='Con'){out.push(value.head);value=value.tail;}if(tag(value)!=='Nil')throw Error('Malformed native list');return out;};
const list=values=>values.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const fuelEnd=Object.freeze({$:'FeedbackFuelEnd'}),fuelPrototype={get tail(){return fuel(this.remaining-1);}};
function fuel(remaining){if(remaining===0)return fuelEnd;const node=Object.create(fuelPrototype);node.$='FeedbackFuelCell';node.remaining=remaining;return node;}
function verify(pins){for(const [path,digest]of Object.entries(pins))if(realpathSync(path)!==path||hash(path)!==digest)throw Error('Pinned input drift: '+path);}
function requestAt(path){
  const request=JSON.parse(readFileSync(path,'utf8'));
  if(request.schemaVersion!==1||!request.pins||!request.inputs||JSON.stringify(request.exports)!==JSON.stringify(ABI))throw Error('Invalid throughput request');
  if(request.limits?.memoryMiB!==8192||request.limits?.rssMiB!==8192||request.limits?.timeoutMs!==600000)throw Error('Throughput guard must retain original limits');
  verify(request.pins);verify(request.inputs);
  return request;
}
async function run(mode,requestPath,requestSha256,reportPath){
  if(hash(requestPath)!==requestSha256)throw Error('Throughput request drift');
  const request=requestAt(requestPath),output=reportPath+'.output.mjs';
  if(existsSync(output))throw Error('Output path already exists');
  const report={schemaVersion:1,status:'RUNNING',diagnosticOnly:true,acceptanceEvidence:false,mode,request:requestPath,requestSha256,source:request.root,sourceSha256:hash(request.root),runtime:{execPath:process.execPath,versions:process.versions,execArgv:process.execArgv,heapLimitBytes:getHeapStatistics().heap_size_limit},limits:request.limits,workerPolicy:{stackMiB:256,oldGenerationMiB:6144,youngGenerationMiB:128},exports:ABI,phases:[],checksExcluded:0,outputPatches:0};
  const started=performance.now();save(reportPath,report);
  const phase=async(name,action)=>{
    const before=performance.now(),cpu=process.cpuUsage();report.activePhase=name;save(reportPath,report);
    const result=await action(),used=process.cpuUsage(cpu);
    report.phases.push({phase:name,elapsedMs:performance.now()-before,userCpuMs:used.user/1000,systemCpuMs:used.system/1000,memoryEnd:process.memoryUsage()});delete report.activePhase;save(reportPath,report);return result;
  };
  try{
    let source;
    if(mode==='native'){
      const work=workloadRows(request.root,'js'),corpus=corpusFor(work);
      if(JSON.stringify(Object.fromEntries([...work.sources,...work.externals].map(row=>[row.file,row.sha256]).sort()))!==JSON.stringify(Object.fromEntries(Object.entries(request.inputs).sort())))throw Error('Native source closure differs from request');
      const manifest=reportPath+'.runtime.tsv',exportsPath=reportPath+'.exports.txt';
      writeFileSync(manifest,runtimeManifest(corpus),{flag:'wx'});writeFileSync(exportsPath,ABI.join('\n')+'\n',{flag:'wx'});
      const native=runNativeStage0(request.binary,{root:request.root,base:resolve(request.repository,'bend2/base.bend'),manifest,exports:exportsPath,phase:'compile',output},{timeoutMs:request.limits.timeoutMs});
      writeFileSync(reportPath+'.native.stdout',native.stdout,{flag:'wx'});writeFileSync(reportPath+'.native.stderr',native.stderr,{flag:'wx'});
      requireNativeRun(native,{phases:['parse','expand','check','emit'],sources:work.sources.length,output});
      report.native={command:native.command,status:native.status,signal:native.signal,elapsedMs:native.elapsedMs,begins:native.begins,fuel:native.fuel,result:native.results};
      report.phases=native.phases;report.moduleCount=work.sources.length;
      report.phaseCpuScope='Native process RUSAGE_SELF; wrapper and guardian excluded';
    }else if(mode==='ts'){
      const {K,C}=await phase('startup',async()=>({K:await import(pathToFileURL(resolve(request.repository,'bend2/bend.ts')).href),C:await import(pathToFileURL(resolve(request.repository,'bend2/comp.ts')).href)}));
      const book=K.book_nil(),observed=new Set();
      class Inputs extends Map{set(path,namespace){if(namespace===null)observed.add(realpathSync(path));return super.set(path,namespace);}}
      await phase('load-parse-expand',()=>K.book_load(book,request.root,'',new Inputs()));
      for(const def of Object.values(book.tlds))if(def.$==='Def')for(const path of def.i??[])if(path.endsWith('.js'))observed.add(realpathSync(path));
      if(observed.size!==Object.keys(request.inputs).length||[...observed].some(path=>!Object.hasOwn(request.inputs,path)))throw Error('TS source closure differs from request');
      await phase('check',()=>K.book_valid(book));
      if(book.hols)throw Error('Unfilled TS book');
      const definitions=Object.values(book.tlds).filter(def=>def.$==='Def'&&def.v!==null);
      if(definitions.some(def=>def.e===undefined))throw Error('Unchecked TS body');
      report.checkedDefinitions=definitions.length;report.validationEvents=book.order.length;
      source=await phase('emit',()=>C.js_lib(book,true,ABI));
      report.phaseCpuScope='Node process-wide CPU; includes worker/helper threads, excludes child processes';
    }else if(mode==='js'){
      const api=await phase('startup',async()=>(await import(pathToFileURL(request.image).href)).default);
      if(!api||!ABI.every(key=>typeof api[key]==='function'))throw Error('Emitted compiler ABI incomplete');
      let modules=[],files=[],declarations=0;
      await phase('load-parse',()=>{
        const seen=new Map(),active=new Set(),observed=new Set(),foreign=new Map();
        const observe=path=>{const real=realpathSync(path);if(!Object.hasOwn(request.inputs,real))throw Error('Unexpected input: '+real);observed.add(real);return real;};
        const namespace=(scope,path)=>path==='Base'?'':posix.normalize(isAbsolute(path)?path.replace(/\.bend$/,''):posix.dirname(scope)+'/'+path.replace(/\.bend$/,''));
        const foreignSource=(file,path)=>{const real=observe(resolve(dirname(file),path));foreign.set(real,readFileSync(real,'utf8'));};
        const visit=(file,scope)=>{
          const real=observe(file);if(active.has(real))throw Error('Import cycle: '+real);
          if(seen.has(real)){if(seen.get(real)!==scope)throw Error('Namespace conflict');return;}seen.set(real,scope);active.add(real);
          const feedback=api.parse_with_fuel(fuel(8000000),real,readFileSync(real,'utf8'));
          if(tag(feedback)!=='FeedbackComplete'||tag(feedback.value.result)!=='ParseSuccess')throw Error('Own parser rejected '+real);
          const module=feedback.value.result.module;declarations+=items(module.declarations).length;
          for(const top of items(module.declarations))if(tag(top)==='DefTop'&&tag(top.definition.body)==='DefImports')for(const path of items(top.definition.body.paths))if(path.endsWith('.js'))foreignSource(real,path);
          for(const imported of items(module.imports)){const path=imported.path;if(path.endsWith('.js'))foreignSource(real,path);else if(!path.endsWith('.c'))visit(path==='Base'?resolve(request.repository,'bend2/base.bend'):resolve(dirname(real),path),namespace(scope,path));}
          modules.push(api.parsed_module(scope,module));active.delete(real);
        };
        visit(request.root,'');
        if(observed.size!==Object.keys(request.inputs).length)throw Error('Own parser omitted a frozen input');
        report.moduleCount=seen.size;report.sourceDeclarations=declarations;files=[...foreign].map(([path,source])=>({path,source}));modules=list(modules);
      });
      const stepCounts={};
      let expanded=await phase('expand',()=>runTemplateSteps({...api,expand_modules_start:input=>{modules=undefined;return api.expand_modules_start(input);}},modules,{onFinish(_,steps){stepCounts.expand=steps;}}));
      if(tag(expanded)!=='ExpandSuccess')throw Error('Own expansion failed');
      let checked=await phase('check',()=>runCheckerSteps({...api,check_expanded_start:input=>{expanded=undefined;return api.check_expanded_start(input);}},expanded.modules,{onFinish(_,steps){stepCounts.check=steps;}}));
      if(tag(checked)!=='CheckSuccess')throw Error('Own checking failed');
      const carrier=sourceFileTagFromRoot(readFileSync(request.root,'utf8'),'selfhost');
      const emitted=await phase('emit',()=>runLibraryEmitterSteps({...api,emit_library_start:(program,names,sources)=>{checked=undefined;return api.emit_library_start(program,names,sources);}},checked.program,list(ABI),sourceFiles(files,carrier),{onFinish(_,steps){stepCounts.emit=steps;}}));
      if(tag(emitted)!=='EmitSuccess')throw Error('Own emission failed');source=emitted.source;
      report.stepCounts=stepCounts;report.phaseCpuScope='Node process-wide CPU; includes worker/helper threads, excludes child processes';
    }else throw Error('Unknown throughput mode: '+mode);
    report.pipelineElapsedMs=performance.now()-started;
    if(source!==undefined){writeFileSync(output,source,{flag:'wx'});source=undefined;}
    report.output={path:output,bytes:readFileSync(output).length,sha256:hash(output)};
    if(mode!=='ts'&&request.expectedSelfhostOutput&&report.output.sha256!==request.expectedSelfhostOutput)throw Error('Unchanged G21 output bytes differ');
    verify(request.pins);verify(request.inputs);
    report.status='PASS';
  }catch(error){report.status='FAIL';report.error=String(error);report.stack=error?.stack;process.exitCode=1;}
  report.totalElapsedMs=performance.now()-started;save(reportPath,report);console.log(JSON.stringify({status:report.status,mode,report:reportPath,pipelineElapsedMs:report.pipelineElapsedMs,phases:report.phases.map(row=>({phase:row.phase,elapsedMs:row.elapsedMs})),output:report.output,error:report.error}));
}
if(!isMainThread){await run(workerData.mode,workerData.requestPath,workerData.requestSha256,workerData.reportPath);}
else if(process.argv[2]==='--worker'){
  const [,mode,requestPath,requestSha256,reportPath]=process.argv.slice(2);
  if(!mode||!requestPath||!requestSha256||!reportPath)throw Error('Expected worker arguments');
  const child=new Worker(new URL(import.meta.url),{workerData:{mode,requestPath,requestSha256,reportPath},resourceLimits:{stackSizeMb:256,maxOldGenerationSizeMb:6144,maxYoungGenerationSizeMb:128}});
  await new Promise((done,reject)=>{child.once('error',reject);child.once('exit',code=>code===0?done():reject(Error('Throughput worker failed: '+code)));});
}else{
  const [mode,requestPath,reportPath]=process.argv.slice(2);
  if(!['ts','native','js'].includes(mode)||!requestPath||!reportPath||process.argv.length!==5)throw Error('Usage: bun evals/selfhost_throughput.mjs ts|native|js REQUEST.json FRESH-REPORT.json');
  if(existsSync(reportPath))throw Error('Use a fresh report path');
  const request=requestAt(resolve(requestPath));save(reportPath,{schemaVersion:1,status:'RUNNING',mode,diagnosticOnly:true,acceptanceEvidence:false});
  const guarded=await runHeavyGate([request.node,'--experimental-strip-types','--max-old-space-size=6144','--max-semi-space-size=128',script,'--worker',mode,resolve(requestPath),hash(requestPath),resolve(reportPath)],{...request.limits,pollMs:10,label:'Frozen full-root throughput '+mode});
  const report=JSON.parse(readFileSync(reportPath,'utf8'));report.guardian=guarded;
  if(guarded.status!=='PASS'||report.status!=='PASS'){report.status='FAIL';process.exitCode=guarded.exitCode||1;}
  save(reportPath,report);
}
