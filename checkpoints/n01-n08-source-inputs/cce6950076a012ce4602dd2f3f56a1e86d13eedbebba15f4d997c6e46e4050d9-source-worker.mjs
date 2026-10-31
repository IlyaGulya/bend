import assert from 'node:assert/strict';
import {Worker,isMainThread,workerData} from 'node:worker_threads';
import {readFileSync,writeFileSync,realpathSync} from 'node:fs';
import {resolve,dirname,posix,isAbsolute} from 'node:path';
import {pathToFileURL} from 'node:url';
import {authenticate,ABI,ROOT,json,tag,list,items,verify,hashPath,sha} from './authority.mjs';
const save=(p,v)=>writeFileSync(p,JSON.stringify(v,(_,x)=>typeof x==='bigint'?String(x):x,2)+'\n');
const end=Object.freeze({$:'FeedbackFuelEnd'}),proto={get tail(){return fuel(this.remaining-1);}};
function fuel(n){if(!n)return end;const x=Object.create(proto);x.$='FeedbackFuelCell';x.remaining=n;return x;}
if(isMainThread){const worker=new Worker(new URL(import.meta.url),{workerData:{request:realpathSync(process.argv[2])},resourceLimits:{stackSizeMb:256,maxOldGenerationSizeMb:6144,maxYoungGenerationSizeMb:128}});await new Promise((yes,no)=>{worker.once('error',no);worker.once('exit',c=>c===0?yes():no(Error('source worker exited '+c)));});}
else{
 const q=json(workerData.request),record={schemaVersion:1,status:'RUNNING',diagnosticOnly:true,compilerAccepted:false,performanceAccepted:false,newFixedpointClaim:false,request:{path:workerData.request,sha256:hashPath(workerData.request)},inputs:{},steps:{},phases:[],plugins:[],runtime:{execPath:process.execPath,versions:process.versions,execArgv:process.execArgv},worker:{stackMiB:256,oldMiB:6144,youngMiB:128},parserFuel:8000000,quantum:64};
 const plugins=[];const started=performance.now();
 try{
  const auth=authenticate();record.authority=auth.proof;verify(q.pins??{});let image=auth.image,source=readFileSync(image,'utf8');
  for(const p of q.plugins??[]){const plugin=await import(pathToFileURL(p).href),result=plugin.instrument(source,{repository:ROOT,image,directory:dirname(q.report),target:q.target});assert.equal(typeof result.source,'string');record.plugins.push({path:p,sha256:hashPath(p),inputSha256:sha(source),outputSha256:sha(result.source),metadata:result.metadata});source=result.source;plugins.push(plugin);}
  if(plugins.length){image=q.report+'.instrumented.mjs';writeFileSync(image,source,{flag:'wx'});record.instrumented={path:image,sha256:sha(source)};}source=undefined;
  const imported=await import(pathToFileURL(image).href),api=imported.default;for(const k of ABI)assert.equal(typeof api[k],'function',k);for(const p of plugins)await p.onLoaded?.(imported);
  const rt=await import(pathToFileURL(ROOT+'/evals/checker_core_step_runtime.mjs').href);rt.verifySourceFileCarrier(readFileSync(auth.image,'utf8'),auth.carrier);
  const phase=(name,action)=>{globalThis.__allExperimentPhase=name;const start=performance.now(),value=action();for(const p of plugins)p.onPhase?.(name,value);record.phases.push({name,elapsedMs:performance.now()-start});save(q.report,record);return value;};
  const read=p=>{const real=realpathSync(p),text=readFileSync(real,'utf8'),digest=sha(text);if(record.inputs[real])assert.equal(record.inputs[real],digest);record.inputs[real]=digest;return text;};
  const seen=new Map(),active=new Set();let modules=[],files=[];
  const namespace=(scope,path)=>path==='Base'?'':posix.normalize(isAbsolute(path)?path.replace(/\.bend$/,''):posix.dirname(scope)+'/'+path.replace(/\.bend$/,''));
  function visit(file,scope){
   const at=realpathSync(file);assert.ok(!active.has(at),'import cycle '+at);if(seen.has(at)){assert.equal(seen.get(at),scope);return;}seen.set(at,scope);active.add(at);
   const f=api.parse_with_fuel(fuel(8000000),at,read(at));assert.equal(tag(f),'FeedbackComplete','parser fuel '+at);const parsed=f.value.result;assert.equal(tag(parsed),'ParseSuccess','own parser '+at+': '+parsed.message);const m=parsed.module;
   for(const top of items(m.declarations))if(tag(top.definition?.body)==='DefImports')for(const declared of items(top.definition.body.paths))if(declared.endsWith('.'+q.target)){const path=rt.sourceFilePath(at,declared);files.push({path,source:read(path)});}
   for(const imp of items(m.imports)){const p=imp.path;if(p.endsWith('.js')||p.endsWith('.c'))continue;assert.ok(!/^0x[0-9a-f]+\//.test(p),'unresolved hub import');visit(p==='Base'?resolve(ROOT,'bend2/base.bend'):resolve(dirname(at),p),namespace(scope,p));}
   modules.push(api.parsed_module(scope,m));active.delete(at);
  }
  phase('parse',()=>visit(q.source,''));record.moduleCount=seen.size;record.foreignFiles=files.map(f=>({path:f.path,sha256:sha(f.source)}));
  const observer=name=>({onStep(index,run){for(const p of plugins)p.onStep?.(name,index,run);},onFinish(v,n){record.steps[name]=n;for(const p of plugins)p.onFinish?.(name,v,n);}});
  let expanded=phase('expand',()=>rt.runTemplateSteps(api,list(modules),observer('Template')));modules=undefined;assert.equal(tag(expanded),'ExpandSuccess','own expansion: '+expanded.message);
  let checked=phase('check',()=>rt.runCheckerSteps(api,expanded.modules,observer('Checker')));expanded=undefined;
  if(q.expectedCheckError!==undefined){assert.equal(tag(checked),'CheckFailure');assert.equal(checked.diagnostic.message,q.expectedCheckError);record.expectedRejection={phase:'check',diagnostic:checked.diagnostic};}
  else{
   assert.equal(tag(checked),'CheckSuccess','own checker: '+checked.diagnostic?.message);
   const bag=rt.sourceFiles(files,auth.carrier);let emitted;
   if(q.target==='c'){const runtime=read(ROOT+'/bend2/selfhost/c_runtime.c');emitted=phase('emit',()=>q.exports?rt.runCLibraryEmitterSteps(api,checked.program,list(q.exports),runtime,bag,observer('Emitter')):rt.runCEmitterSteps(api,checked.program,runtime,bag,observer('Emitter')));}
   else emitted=phase('emit',()=>q.exports?rt.runLibraryEmitterSteps(api,checked.program,list(q.exports),bag,observer('Emitter')):rt.runEmitterSteps(api,checked.program,bag,observer('Emitter')));
   checked=undefined;
   if(q.expectedError!==undefined){assert.equal(tag(emitted),'EmitFailure');assert.equal(emitted.message,q.expectedError);record.expectedRejection={phase:'emit',message:emitted.message};}
   else{assert.equal(tag(emitted),'EmitSuccess','own emitter: '+emitted.message);writeFileSync(q.output,emitted.source,{flag:'wx'});record.output={path:q.output,sha256:sha(emitted.source),bytes:Buffer.byteLength(emitted.source)};}
  }
  record.snapshots=plugins.map((p,i)=>({path:record.plugins[i].path,snapshot:p.snapshot?.()??null}));verify(record.inputs);verify(auth.pins);verify(q.pins??{});record.status='PASS';
 }catch(error){record.status='FAIL';record.error=String(error);record.stack=error?.stack;record.snapshots=plugins.map((p,i)=>({path:record.plugins[i]?.path,snapshot:p.snapshot?.()??null}));process.exitCode=1;}
 record.elapsedMs=performance.now()-started;save(q.report,record);console.log(JSON.stringify({status:record.status,source:q.source,target:q.target,report:q.report,steps:record.steps,error:record.error}));
}
