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
  if(workerData.emitterGuard){
   phase('compiled-emitter-guard');
   const emission=runEmitterSteps(component,modules);
   if(tag(emission)!=='EmitFailure')throw Error('Unexpanded template reached successful emission');
   if(emission.span.file!==workerData.file||emission.span.beg!==BigInt(workerData.source.indexOf('~'))||emission.span.end<=emission.span.beg||emission.span.end>BigInt(workerData.source.length))throw Error('Emitter failure did not retain the actual template source span');
   phase('complete');
   parentPort.postMessage({passed:true,status:'PASS',name:workerData.name,criterion:'Direct emission rejects actual parsed unexpanded template',emitterTag:tag(emission),message:emission.message,span:emission.span,checkerRun:false,phases});
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
   emission=runEmitterSteps(component,checked.modules);
   if(tag(emission)!=='EmitSuccess')throw Error('Target emission failed: '+emission.message+' at '+emission.span.file+':'+emission.span.beg+'-'+emission.span.end);
   temporary=mkdtempSync(join(tmpdir(),'bend-checker-target-'));const file=join(temporary,'main.js');writeFileSync(file,emission.source);
   phase('emitted-program-run');
   const run=spawnSync(process.execPath,[file],{encoding:'utf8',timeout:30000});
   if(run.error||run.status!==0)throw Error('Emitted target failed: '+String(run.error??run.stderr));
   output=run.stdout.trim();emitted=true;
   if(output!==workerData.output)throw Error('Emitted target output mismatch: expected '+workerData.output+' observed '+output);
  }
  phase('complete');
  parentPort.postMessage({passed:true,status:'PASS',name:workerData.name,accepted,checkerTag:tag(checked),diagnostic:accepted?undefined:checked.diagnostic,emitterTag:tag(emission),emitted,output,templateFreePrecondition:true,checkerDriver:'trusted Node LIFO continuation loop outside native termination proof',emitterDriver:'trusted Node LIFO continuation loop outside native termination proof',phases});
  }
 }catch(error){parentPort.postMessage({passed:false,status:'FAIL',name:workerData.name,error:String(error),diagnostic:observedCheck?.diagnostic,parseFailure:tag(observedParse)==='ParseFailure'?observedParse:undefined,phases});}
 finally{if(temporary)rmSync(temporary,{recursive:true,force:true});}
}
