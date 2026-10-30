import assert from 'node:assert/strict';
import {Worker,isMainThread,workerData} from 'node:worker_threads';
import {readFileSync,writeFileSync,realpathSync} from 'node:fs';
import {resolve,dirname,posix,isAbsolute} from 'node:path';
import {pathToFileURL} from 'node:url';
import {ABI,authenticate,hash,sha,json,save,verify,tag,list,items} from './common.mjs';
import {instrument} from './probes.mjs';
if(isMainThread){
 const request=resolve(process.argv[2]);
 const worker=new Worker(new URL(import.meta.url),{workerData:{request},resourceLimits:{stackSizeMb:256,maxOldGenerationSizeMb:6144,maxYoungGenerationSizeMb:128}});
 await new Promise((done,reject)=>{worker.once('error',reject);worker.once('exit',code=>code===0?done():reject(Error('image worker exit '+code)));});
}else{
 const q=json(workerData.request),record={status:'RUNNING',diagnosticOnly:true,compilerAccepted:false,worker:{stackMiB:256,oldMiB:6144,youngMiB:128},parserFuel:8000000,quantum:64,abi:ABI,inputs:{},steps:{},runtime:{execPath:process.execPath,versions:process.versions,execArgv:process.execArgv},requestSha256:hash(workerData.request)};
 let probe;
 try{
  verify(q.pins);const {build,manifest,pins}=authenticate(q.repo,q.build);
  const runtimePath=resolve(q.repo,'evals/checker_core_step_runtime.mjs');record.inputs[realpathSync(runtimePath)]=hash(runtimePath);
  const rt=await import(pathToFileURL(runtimePath).href);
  const carrier=rt.sourceFileTagFromRoot(readFileSync(build.sourcePath,'utf8'),'compiled');record.carrier={tag:carrier,producer:'canonical component builder',root:build.sourcePath,rootSha256:build.sourceSha256};
  let source=readFileSync(build.artifactPath,'utf8'),image=build.artifactPath;
  rt.verifySourceFileCarrier(source,carrier);
  if(q.instrument){probe=instrument(source,{repo:q.repo,manifest,experiment:q.experiment,target:q.target});image=q.output+'.probe.mjs';writeFileSync(image,probe.source,{flag:'wx'});record.instrumentation={originalSha256:sha(source),instrumentedSha256:sha(probe.source),sites:probe.sites};}
  const api=(await import(pathToFileURL(image).href)).default;for(const k of ABI)assert.equal(typeof api[k],'function','missing ABI '+k);
  const read=p=>{const real=realpathSync(p),text=readFileSync(real,'utf8'),digest=sha(text);if(record.inputs[real])assert.equal(record.inputs[real],digest);record.inputs[real]=digest;return text;};
  const seen=new Map(),active=new Set(),modules=[],files=[];
  const namespace=(scope,path)=>path==='Base'?'':posix.normalize(isAbsolute(path)?path.replace(/\.bend$/,''):posix.dirname(scope)+'/'+path.replace(/\.bend$/,''));
  function visit(file,scope){
   const at=realpathSync(file);assert.ok(!active.has(at),'import cycle '+at);if(seen.has(at)){assert.equal(seen.get(at),scope,'namespace conflict');return;}seen.set(at,scope);active.add(at);
   let fuel={$:'FeedbackFuelEnd'};for(let i=0;i<8000000;i++)fuel={$:'FeedbackFuelCell',tail:fuel};
   const feedback=api.parse_with_fuel(fuel,at,read(at));fuel=undefined;
   assert.equal(tag(feedback),'FeedbackComplete','parser fuel '+at);const parsed=feedback.value.result;
   assert.equal(tag(parsed),'ParseSuccess','own parser '+at+': '+parsed.message);const m=parsed.module;
   for(const top of items(m.declarations))if(tag(top.definition?.body)==='DefImports')for(const declared of items(top.definition.body.paths))if(declared.endsWith('.'+q.target)){
    const path=rt.sourceFilePath(at,declared);files.push({path,source:read(path)});
   }
   for(const imported of items(m.imports)){
    const path=imported.path;assert.equal(typeof path,'string');assert.ok(!/^0x[0-9a-f]+\//.test(path),'unresolved hub import');
    if(path.endsWith('.js')||path.endsWith('.c'))continue;
    visit(path==='Base'?resolve(q.repo,'bend2/base.bend'):resolve(dirname(at),path),namespace(scope,path));
   }
   modules.push(api.parsed_module(scope,m));active.delete(at);
  }
  visit(q.source,'');record.moduleCount=seen.size;record.foreignFiles=files.map(f=>({path:f.path,sha256:sha(f.source)}));
  const observer=name=>({onFinish(_value,count){record.steps[name]=count;}});
  const expanded=rt.runTemplateSteps(api,list(modules),observer('template'));assert.equal(tag(expanded),'ExpandSuccess','own expansion: '+expanded.message);
  const checked=rt.runCheckerSteps(api,expanded.modules,observer('checker'));record.diagnostic=checked.diagnostic;assert.equal(tag(checked),'CheckSuccess','own checker: '+checked.diagnostic?.message);
  const bag=rt.sourceFiles(files,carrier);let emitted;
  if(q.target==='c'){
   const runtime=read(resolve(q.repo,'bend2/selfhost/c_runtime.c'));
   emitted=q.exports?rt.runCLibraryEmitterSteps(api,checked.program,list(q.exports),runtime,bag,observer('emitter')):rt.runCEmitterSteps(api,checked.program,runtime,bag,observer('emitter'));
  }else emitted=q.exports?rt.runLibraryEmitterSteps(api,checked.program,list(q.exports),bag,observer('emitter')):rt.runEmitterSteps(api,checked.program,bag,observer('emitter'));
  if(q.expectedError!==undefined){assert.equal(tag(emitted),'EmitFailure');assert.equal(emitted.message+'\n',q.expectedError);record.expectedRejection={phase:'emit',message:emitted.message};}
  else{assert.equal(tag(emitted),'EmitSuccess','own emitter: '+emitted.message);assert.equal(typeof emitted.source,'string');writeFileSync(q.output,emitted.source,{flag:'wx'});record.output={path:q.output,sha256:sha(emitted.source),bytes:Buffer.byteLength(emitted.source)};}
  if(probe)record.probe=probe.finish(q.expectedError===undefined);
  verify(record.inputs);verify(pins);verify(q.pins);record.status='PASS';
 }catch(error){record.status='FAIL';record.error=String(error?.stack??error);process.exitCode=1;}
 save(q.report,record);
}
