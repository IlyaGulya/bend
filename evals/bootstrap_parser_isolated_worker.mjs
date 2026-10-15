import {Worker,isMainThread,parentPort,workerData,threadId} from 'node:worker_threads';
import {spawn} from 'node:child_process';
import {readFileSync,writeFileSync,appendFileSync,existsSync} from 'node:fs';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';

const FUEL=2000000;
const errorText=error=>error instanceof Error?`${error.name}: ${error.message}`:String(error);
// Stack overflow frames must survive the small final status message. Increasing
// capture depth does not change the existing worker stack or memory limits.
Error.stackTraceLimit=32;
const errorDetails=error=>({error:errorText(error),errorStack:typeof error?.stack==='string'?error.stack:undefined});
function phaseRecorder(statusPath,startedAt,origin){
 return (phase,details={})=>{
  const memory=process.memoryUsage();
  const timestampMs=Date.now();
  appendFileSync(statusPath+'.phases.jsonl',JSON.stringify({phase,origin,pid:process.pid,threadId,timestampMs,rssBytes:memory.rss,heapUsed:memory.heapUsed,elapsedMs:timestampMs-startedAt,...details})+'\n');
 };
}
if(!isMainThread){
 let phase='runtime-error',failureStage='worker-start',parseCompleted=false,compiledAccepted=false,fullFileParseSuccess=false,prefixParseSuccess=false,sourceScope=workerData.scopeMetadata.sourceScope,sourceMetadata=workerData.scopeMetadata;
 const record=phaseRecorder(workerData.statusPath,workerData.startedAt,'compiled-worker');
 const parseState=()=>({parseCompleted,compiledAccepted,fullFileParseSuccess,prefixParseSuccess,sourceScope,...sourceMetadata});
 const stage=(name,details={})=>{failureStage=name;record(name,{event:'start',...parseState(),...details});};
 const completed=(details={})=>record(failureStage,{event:'complete',...parseState(),...details});
 const reply=result=>{
  stage('worker-result-transport');
  parentPort.postMessage(result);
 };
 try{
  phase='ast-transport-normalization-failure';
  stage('ast-transport-import');
  const {encodeNativeAst}=await import('./bootstrap_ast_transport.ts');
  completed();
  phase='runtime-error';
  stage('request-load');
  const request=JSON.parse(readFileSync(workerData.request,'utf8'));
  sourceScope=request.sourceScope??'full-file';
  sourceMetadata={declarations:request.declarations,originalSourceSha256:request.originalSourceSha256,sourceSha256:request.sourceSha256,prefixSha256:request.prefixSha256};
  completed({sourceChars:request.source.length});
  stage('artifact-import');
  const parser=(await import(pathToFileURL(resolve(workerData.artifact)).href)).default;
  completed();
  stage('fuel-preparation',{fuelCells:FUEL});
  let fuel={$:'FeedbackFuelEnd'};
  for(let i=0;i<FUEL;i++)fuel={$:'FeedbackFuelCell',tail:fuel};
  completed();
  stage('compiled-parse-call');
  const run=parser.parse_with_fuel(fuel,request.file,request.source);
  completed();
  stage('payload-validation-materialization');
  if(run.$!=='FeedbackComplete'){
   completed({feedbackTag:run.$});
   reply({status:'fuel-exhaustion',feedbackTag:run.$,...parseState()});
  }else{
   const value=run.value,result=value?.result,tag=result?.$?.split('.').at(-1);
   if(!/^Value_\d+$/.test(value?.$?.split('.').at(-1)??'')||!['ParseSuccess','ParseFailure'].includes(tag))
    throw Error('Invalid parser feedback payload '+value?.$);
   parseCompleted=true;compiledAccepted=tag==='ParseSuccess';
   fullFileParseSuccess=compiledAccepted&&sourceScope==='full-file';
   prefixParseSuccess=compiledAccepted&&sourceScope==='declaration-prefix';
   completed({feedbackTag:run.$,resultTag:tag});
   phase='ast-transport-normalization-failure';
   stage('ast-serialization');
   const encoded=encodeNativeAst(result);
   completed({transportChars:encoded.length});
   stage('ast-output-write');
   writeFileSync(workerData.output,encoded);
   completed();
   reply({status:tag==='ParseSuccess'?'accepted':'rejection',...parseState()});
  }
 }catch(error){
  const result={status:phase,...errorDetails(error),failureStage,...parseState()};
  // A failed diagnostic write must not replace the original parser exception.
  try{record(failureStage,{event:'error',...result});}catch{}
  parentPort.postMessage(result);
 }
}else if(process.argv[2]==='--supervise'){
 const [,, ,executable,script,jobPath,rowPath,timeoutText]=process.argv;
 const timeoutMs=Number(timeoutText);
 const child=spawn(executable,[script,'--child='+jobPath],{stdio:'inherit',detached:true});
 let timedOut=false;
 const timer=setTimeout(()=>{
  timedOut=true;
  try{process.kill(-child.pid,'SIGKILL');}catch(error){if(error.code!=='ESRCH')throw error;}
 },timeoutMs);
 child.on('error',error=>{
  clearTimeout(timer);
  writeFileSync(rowPath,JSON.stringify({status:'runtime-error',complete:false,finished:true,...errorDetails(error),failureStage:'module-process-spawn',acceptanceParity:false,semanticParity:false})+'\n');
  process.exitCode=2;
 });
 child.on('close',(code,signal)=>{
  clearTimeout(timer);
  if(timedOut){
   const previous=existsSync(rowPath)?JSON.parse(readFileSync(rowPath,'utf8')):{};
   writeFileSync(rowPath,JSON.stringify({...previous,status:'timeout',complete:false,finished:true,timeoutMs,acceptanceParity:false,semanticParity:false})+'\n');
  }else if(!existsSync(rowPath)){
   writeFileSync(rowPath,JSON.stringify({status:'runtime-error',complete:false,finished:true,error:`Module process exited ${code} (${signal}) without a result`,acceptanceParity:false,semanticParity:false})+'\n');
  }
  process.exitCode=timedOut?124:(code??2);
 });
}else{
 const [,,artifact,request,output,statusPath]=process.argv;
 if(!artifact||!request||!output||!statusPath)throw Error('Expected artifact, request, transport output and status paths');
 let scopeMetadata;
 {
  const metadata=JSON.parse(readFileSync(request,'utf8'));
  scopeMetadata={sourceScope:metadata.sourceScope??'full-file',declarations:metadata.declarations,originalSourceSha256:metadata.originalSourceSha256,sourceSha256:metadata.sourceSha256,prefixSha256:metadata.prefixSha256};
 }
 const startedAt=Date.now(),recordPhase=phaseRecorder(statusPath,startedAt,'worker-host');
 const record=(phase,details={})=>recordPhase(phase,{...scopeMetadata,...details});
 writeFileSync(statusPath+'.phases.jsonl','');
 record('worker-launch',{event:'start'});
 const worker=new Worker(new URL(import.meta.url),{resourceLimits:{stackSizeMb:256},workerData:{artifact,request,output,statusPath,startedAt,scopeMetadata}});
 record('worker-launch',{event:'complete'});
 let replied=false;
 const finish=result=>{
  if(replied)return;
  replied=true;
  result={...scopeMetadata,prefixParseSuccess:false,...result};
  record('parent-host-transport',{event:'start',status:result.status,parseCompleted:result.parseCompleted,compiledAccepted:result.compiledAccepted,fullFileParseSuccess:result.fullFileParseSuccess,prefixParseSuccess:result.prefixParseSuccess});
  writeFileSync(statusPath,JSON.stringify(result)+'\n');
  record('parent-host-transport',{event:'complete',status:result.status,parseCompleted:result.parseCompleted,compiledAccepted:result.compiledAccepted,fullFileParseSuccess:result.fullFileParseSuccess,prefixParseSuccess:result.prefixParseSuccess});
 };
 worker.on('message',message=>{finish(message);void worker.terminate();});
 worker.on('error',error=>{
  finish({status:'runtime-error',...errorDetails(error),failureStage:'worker-thread-error',parseCompleted:false,fullFileParseSuccess:false});
  process.exitCode=2;
 });
 worker.on('exit',code=>{
  if(!replied){finish({status:'runtime-error',error:'Artifact worker exited '+code,failureStage:'worker-thread-exit',parseCompleted:false,fullFileParseSuccess:false});process.exitCode=2;}
 });
}
