import {createHash} from 'node:crypto';
import {readFileSync,writeFileSync,existsSync,realpathSync} from 'node:fs';
import {resolve,dirname,posix,isAbsolute} from 'node:path';
import {pathToFileURL,fileURLToPath} from 'node:url';
import {Worker,isMainThread,workerData} from 'node:worker_threads';
import {getHeapStatistics} from 'node:v8';
import {runHeavyGate} from '/Users/ilyagulya/Projects/My/bend/evals/heavy_gate.ts';
import {ABI} from '/Users/ilyagulya/Projects/My/bend/evals/native_seed_runtime.mjs';
import {runTemplateSteps,runCheckerSteps,runLibraryEmitterSteps,sourceFiles,sourceFileTagFromRoot} from '/Users/ilyagulya/Projects/My/bend/evals/checker_core_step_runtime.mjs';
const self=fileURLToPath(import.meta.url),repository='/Users/ilyagulya/Projects/My/bend';
const sha=bytes=>createHash('sha256').update(bytes).digest('hex'),hash=path=>sha(readFileSync(path));
const save=(path,value)=>writeFileSync(path,JSON.stringify(value,(_,v)=>typeof v==='bigint'?String(v):v,2)+'\n');
const tag=value=>typeof value?.$==='string'?value.$.split('.').at(-1):null;
const items=value=>{const out=[];while(tag(value)==='Con'){out.push(value.head);value=value.tail;}if(tag(value)!=='Nil')throw Error('Malformed native list');return out;};
const list=values=>values.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const fuelEnd=Object.freeze({$:'FeedbackFuelEnd'}),fuelPrototype={get tail(){return fuel(this.remaining-1);}};
function fuel(remaining){if(remaining===0)return fuelEnd;const value=Object.create(fuelPrototype);value.$='FeedbackFuelCell';value.remaining=remaining;return value;}
function verify(pins){for(const [path,digest]of Object.entries(pins))if(realpathSync(path)!==path||hash(path)!==digest)throw Error('Pinned input drift: '+path);}
async function execute(configPath,reportPath){
 const config=JSON.parse(readFileSync(configPath,'utf8')),request=JSON.parse(readFileSync(config.request,'utf8'));
 verify(request.pins);verify(request.inputs);verify(config.pins);
 if(JSON.stringify(request.exports)!==JSON.stringify(ABI))throw Error('ABI mismatch');
 const plugins=[];let source=readFileSync(request.image,'utf8');
 const report={schemaVersion:1,status:'RUNNING',diagnosticOnly:true,compilerAccepted:false,performanceAccepted:false,newFixedpointClaim:false,request:{path:config.request,sha256:hash(config.request)},config:{path:configPath,sha256:hash(configPath)},driver:{path:self,sha256:hash(self)},image:{path:request.image,sha256:hash(request.image)},root:{path:request.root,sha256:hash(request.root)},inputPins:request.inputs,limits:request.limits,runtime:{execPath:process.execPath,versions:process.versions,execArgv:process.execArgv,heapSizeLimit:getHeapStatistics().heap_size_limit},worker:{stackMiB:256,oldMiB:6144,youngMiB:128},plugins:[],phases:[],stepCounts:{}};
 const started=performance.now();
 const snapshots=()=>Object.fromEntries(plugins.map(({path,api})=>[path,api.snapshot?.()??null]));
 const phase=async(name,action)=>{
  globalThis.__allExperimentPhase=name;report.activePhase=name;save(reportPath,report);
  const before=performance.now(),cpu=process.cpuUsage(),result=await action(),used=process.cpuUsage(cpu);
  for(const {api}of plugins)await api.onPhase?.(name,result);
  report.phases.push({phase:name,elapsedMs:performance.now()-before,userCpuMs:used.user/1000,systemCpuMs:used.system/1000,memoryEnd:process.memoryUsage(),snapshots:snapshots()});delete report.activePhase;save(reportPath,report);return result;
 };
const observe=kind=>({onStep(index,run){for(const {api}of plugins)api.onStep?.(kind,index,run);if(index>0&&index%1048576===0){report.partial={kind,index,elapsedMs:performance.now()-started,memory:process.memoryUsage(),snapshots:snapshots()};save(reportPath,report);}},onFinish(value,steps){report.stepCounts[kind]=steps;for(const {api}of plugins)api.onFinish?.(kind,value,steps);}});
 try{
  globalThis.__allExperimentPhase='instrument';
  for(const path of config.plugins){const api=await import(pathToFileURL(path).href),result=api.instrument(source,{repository,image:request.image,directory:dirname(reportPath)});if(typeof result?.source!=='string')throw Error('Bad instrumentation output '+path);report.plugins.push({path,sha256:hash(path),inputSha256:sha(source),outputSha256:sha(result.source),metadata:result.metadata});source=result.source;plugins.push({path,api});}
  const instrumented=reportPath+'.instrumented.mjs';writeFileSync(instrumented,source,{flag:'wx'});report.instrumented={path:instrumented,sha256:sha(source),bytes:Buffer.byteLength(source)};source=undefined;save(reportPath,report);
  const api=await phase('startup',async()=>(await import(pathToFileURL(instrumented).href)).default);if(!ABI.every(key=>typeof api?.[key]==='function'))throw Error('Image ABI incomplete');
  let modules=[],files=[];
  await phase('load-parse',()=>{
   const seen=new Map(),active=new Set(),observed=new Set(),foreign=new Map();
   const observe=path=>{const real=realpathSync(path);if(!Object.hasOwn(request.inputs,real))throw Error('Unexpected input '+real);observed.add(real);return real;};
   const namespace=(scope,path)=>path==='Base'?'':posix.normalize(isAbsolute(path)?path.replace(/\.bend$/,''):posix.dirname(scope)+'/'+path.replace(/\.bend$/,''));
   const foreignSource=(file,path)=>{const real=observe(resolve(dirname(file),path));foreign.set(real,readFileSync(real,'utf8'));};
   const visit=(file,scope)=>{
    const real=observe(file);if(active.has(real))throw Error('Import cycle '+real);if(seen.has(real)){if(seen.get(real)!==scope)throw Error('Namespace conflict');return;}seen.set(real,scope);active.add(real);
    const feedback=api.parse_with_fuel(fuel(8000000),real,readFileSync(real,'utf8'));if(tag(feedback)!=='FeedbackComplete'||tag(feedback.value.result)!=='ParseSuccess')throw Error('Own parser rejected '+real);
    const module=feedback.value.result.module;
    for(const top of items(module.declarations))if(tag(top)==='DefTop'&&tag(top.definition.body)==='DefImports')for(const path of items(top.definition.body.paths))if(path.endsWith('.js'))foreignSource(real,path);
    for(const imported of items(module.imports)){const path=imported.path;if(path.endsWith('.js'))foreignSource(real,path);else if(!path.endsWith('.c'))visit(path==='Base'?resolve(request.repository,'bend2/base.bend'):resolve(dirname(real),path),namespace(scope,path));}
    modules.push(api.parsed_module(scope,module));active.delete(real);
   };
   visit(request.root,'');if(observed.size!==Object.keys(request.inputs).length)throw Error('Own parser omitted frozen input');report.moduleCount=seen.size;modules=list(modules);files=[...foreign].map(([path,source])=>({path,source}));
  });
  let expanded=await phase('expand',()=>runTemplateSteps({...api,expand_modules_start:input=>{modules=undefined;return api.expand_modules_start(input);}},modules,observe('Template')));if(tag(expanded)!=='ExpandSuccess')throw Error('Own expansion failed');
  let checked=await phase('check',()=>runCheckerSteps({...api,check_expanded_start:input=>{expanded=undefined;return api.check_expanded_start(input);}},expanded.modules,observe('Checker')));if(tag(checked)!=='CheckSuccess')throw Error('Own checker failed');
  const carrier=sourceFileTagFromRoot(readFileSync(request.root,'utf8'),'selfhost');
  const emitted=await phase('emit',()=>runLibraryEmitterSteps({...api,emit_library_start:(program,names,sources)=>{checked=undefined;return api.emit_library_start(program,names,sources);}},checked.program,list(ABI),sourceFiles(files,carrier),observe('Emitter')));if(tag(emitted)!=='EmitSuccess')throw Error('Own emission failed');
  const output=reportPath+'.output.mjs';writeFileSync(output,emitted.source,{flag:'wx'});report.output={path:output,sha256:hash(output),bytes:Buffer.byteLength(emitted.source)};
  if(report.output.sha256!==request.expectedSelfhostOutput)throw Error('Changed compiler output bytes');verify(request.pins);verify(request.inputs);verify(config.pins);report.status='PASS';
 }catch(error){report.status='FAIL';report.error=String(error);report.stack=error?.stack;process.exitCode=1;}
 globalThis.__allExperimentPhase='complete';report.snapshots=snapshots();report.elapsedMs=performance.now()-started;save(reportPath,report);console.log(JSON.stringify({status:report.status,report:reportPath,elapsedMs:report.elapsedMs,stepCounts:report.stepCounts,output:report.output,error:report.error}));
}
if(!isMainThread)await execute(workerData.config,workerData.report);
else if(process.argv[2]==='--worker'){
 const worker=new Worker(new URL(import.meta.url),{workerData:{config:resolve(process.argv[3]),report:resolve(process.argv[4])},resourceLimits:{stackSizeMb:256,maxOldGenerationSizeMb:6144,maxYoungGenerationSizeMb:128}});
 await new Promise((done,reject)=>{worker.once('error',reject);worker.once('exit',code=>code===0?done():reject(Error('Census worker exit '+code)));});
}else{
 const [configPath,reportPath]=process.argv.slice(2);if(!configPath||!reportPath||existsSync(reportPath))throw Error('Expected config and fresh report');
 const config=JSON.parse(readFileSync(configPath,'utf8')),request=JSON.parse(readFileSync(config.request,'utf8'));save(reportPath,{schemaVersion:1,status:'STARTING',diagnosticOnly:true});
 const command=[request.node,'--experimental-strip-types','--max-old-space-size=6144','--max-semi-space-size=128',self,'--worker',resolve(configPath),resolve(reportPath)],guardian=await runHeavyGate(command,{memoryMiB:8192,rssMiB:8192,pollMs:10,timeoutMs:600000,label:'Complete E01-E13 compiler census'});
 const report=JSON.parse(readFileSync(reportPath,'utf8'));report.guardian=guardian;report.command=command;if(guardian.status!=='PASS'||report.status!=='PASS'){report.status='FAIL';process.exitCode=1;}save(reportPath,report);
}
