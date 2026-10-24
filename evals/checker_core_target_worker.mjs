import {Worker,isMainThread,parentPort,workerData} from 'node:worker_threads';
import {readFileSync,writeFileSync,mkdtempSync,rmSync} from 'node:fs';
import {resolve,join} from 'node:path';
import {tmpdir} from 'node:os';
import {pathToFileURL} from 'node:url';
import {spawnSync} from 'node:child_process';
import {runCheckerSteps,runEmitterSteps} from './checker_core_step_runtime.mjs';

const tag=value=>value?.$?.split('.').at(-1);
if(isMainThread){
 const [,,requestPath,resultPath]=process.argv;
 if(!requestPath||!resultPath)throw Error('Expected request and result paths');
 const request=JSON.parse(readFileSync(requestPath,'utf8'));
 const worker=new Worker(new URL(import.meta.url),{workerData:request,resourceLimits:{stackSizeMb:256}});
 worker.on('message',result=>{writeFileSync(resultPath,JSON.stringify(result,(_,value)=>typeof value==='bigint'?value.toString():value,2)+'\n');if(!result.passed)process.exitCode=2;});
 worker.on('error',error=>{writeFileSync(resultPath,JSON.stringify({passed:false,status:'runtime-error',error:String(error)})+'\n');process.exitCode=2;});
 worker.on('exit',code=>{if(code)process.exitCode=code;});
}else{
 const phases=[];
 const phase=name=>phases.push({name,elapsedMs:performance.now(),rssBytes:process.memoryUsage().rss});
 let temporary,observedCheck,observedParse;
 try{
  phase('imports');
  const parser=(await import(pathToFileURL(resolve(workerData.parser)).href)).default;
  const component=(await import(pathToFileURL(resolve(workerData.component)).href)).default;
  let fuel={$:'FeedbackFuelEnd'};for(let i=0;i<2000000;i++)fuel={$:'FeedbackFuelCell',tail:fuel};
  phase('compiled-parse');
  const feedback=parser.parse_with_fuel(fuel,workerData.file,workerData.source);
  observedParse=feedback.value?.result;
  if(tag(feedback)!=='FeedbackComplete'||tag(feedback.value?.result)!=='ParseSuccess')throw Error('Target parser did not accept: '+tag(feedback.value?.result??feedback));
  const module=feedback.value.result.module;
  const loaded=component.parsed_module('',module),modules={$:'Con',head:loaded,tail:{$:'Nil'}};
  if(workerData.uncheckedGuard){
   phase('compiled-checked-boundary-guard');
   let refused=false;
   try{runEmitterSteps(component,modules);}catch(error){if(!String(error).includes('expected owning CheckedProgram'))throw error;refused=true;}
   if(!refused)throw Error('Unchecked syntax crossed the FIR emitter boundary');
   const checked=runCheckerSteps(component,modules);
   const rejected=tag(checked)==='CheckSuccess'?runEmitterSteps(component,checked.program):checked;
   if(!['CheckFailure','EmitFailure'].includes(tag(rejected)))throw Error('Unexpanded template reached successful emission');
   const {message,span}=tag(rejected)==='CheckFailure'?rejected.diagnostic:rejected;
   if(span.file!==workerData.file||Number(span.beg)!==workerData.source.indexOf('~')||Number(span.end)<=Number(span.beg)||Number(span.end)>workerData.source.length)throw Error('Typed pipeline failure did not retain the actual template source span');
   phase('complete');
   parentPort.postMessage({passed:true,status:'PASS',name:workerData.name,criterion:'Unchecked syntax cannot cross the emitter boundary; native typed pipeline rejects unexpanded template',checkerTag:tag(checked),rejectionTag:tag(rejected),message,span,uncheckedEmissionRefused:true,phases});
  }else{
  const pending=[module];
  while(pending.length){const value=pending.pop();if(!value||typeof value!=='object')continue;const key=tag(value);if(key==='TemplateBinder'||key==='TermTemplate')throw Error('Target violates already-expanded Template-free precondition');for(const [key,child]of Object.entries(value))if(key!=='$')pending.push(child);}
  phase('compiled-check');
  const checked=runCheckerSteps(component,modules),accepted=tag(checked)==='CheckSuccess';
  observedCheck=checked;
  if(accepted!==workerData.accepted)throw Error('Checker acceptance mismatch: '+workerData.name+' observed '+tag(checked));
  let emitted,emission,output;
  if(accepted){
   phase('compiled-emit');
   emission=runEmitterSteps(component,checked.program);
   if(tag(emission)!=='EmitSuccess')throw Error('Target emission failed: '+emission.message+' at '+emission.span.file+':'+emission.span.beg+'-'+emission.span.end);
   temporary=mkdtempSync(join(tmpdir(),'bend-checker-target-'));const file=join(temporary,'main.js');writeFileSync(file,emission.source);
   phase('emitted-program-run');
   const run=spawnSync(process.execPath,[file],{encoding:'utf8',timeout:30000});
   if(run.error||run.status!==0)throw Error('Emitted target failed: '+String(run.error??run.stderr));
   output=run.stdout.trim();emitted=true;
   if(output!==workerData.output)throw Error('Emitted target output mismatch: expected '+workerData.output+' observed '+output);
  }
  phase('complete');
  parentPort.postMessage({passed:true,status:'PASS',name:workerData.name,accepted,checkerTag:tag(checked),diagnostic:accepted?undefined:checked.diagnostic,emitterTag:tag(emission),emitted,output,templateFreePrecondition:true,checkerDriver:'trusted Node opaque native Run chunk loop outside native termination proof',emitterDriver:'trusted Node opaque native Run chunk loop outside native termination proof',phases});
  }
 }catch(error){parentPort.postMessage({passed:false,status:'FAIL',name:workerData.name,error:String(error),diagnostic:observedCheck?.diagnostic,parseFailure:tag(observedParse)==='ParseFailure'?observedParse:undefined,phases});}
 finally{if(temporary)rmSync(temporary,{recursive:true,force:true});}
}
