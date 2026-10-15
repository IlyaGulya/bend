import {Session} from 'node:inspector';
import {mkdirSync,mkdtempSync,writeFileSync,existsSync} from 'node:fs';
import {join,resolve} from 'node:path';
import {threadId,isMainThread} from 'node:worker_threads';

// Only the emitted fixture child receives this preload URL. CLI --cpu-prof
// captures its startup and unchanged artifact; the preload records resources
// without replacing its entrypoint, output, exception handling or exit status.
const childContext=new URL(import.meta.url).searchParams.get('childProfile');
if(childContext){
 const context=JSON.parse(childContext);
 const startedAt=new Date().toISOString(),startedMs=performance.now(),cpuStart=process.cpuUsage(),memoryStart=process.memoryUsage();
 const identity={pid:process.pid,threadId,isMainThread};
 const base={schemaVersion:1,kind:'selfhost-fixture-child',...context,...identity,startedAt,startElapsedMs:startedMs,memoryStart,metricsScope:'preload entry through process exit; CLI CPU profile also includes earlier Node startup',cpuScope:'child process',profileScope:'child main isolate'};
 writeFileSync(join(context.runDirectory,'started.json'),JSON.stringify({...base,status:'started'},null,2)+'\n',{flag:'wx'});
 process.on('exit',exitCode=>{
  const endedAt=new Date().toISOString(),endedMs=performance.now(),cpuUs=process.cpuUsage(cpuStart),memoryEnd=process.memoryUsage();
  writeFileSync(join(context.runDirectory,'summary.json'),JSON.stringify({...base,status:exitCode===0?'completed':'error',exitCode,boundary:{phase:'child-exit'},endedAt,endElapsedMs:endedMs,wallMs:endedMs-startedMs,cpuUs,cpuMs:(cpuUs.user+cpuUs.system)/1000,memoryEnd},null,2)+'\n',{flag:'wx'});
 });
}

// A local inspector Session invokes these callbacks synchronously on Node 23.
// Failing explicitly on a different implementation avoids profiling the wrong
// interval while the compiler continues its synchronous execution.
function post(session,method,params={}){
 let completed=false,result,error;
 session.post(method,params,(failure,value)=>{completed=true;error=failure;result=value;});
 if(!completed)throw Error('Selfhost CPU profiling requires synchronous local inspector callbacks: '+method);
 if(error)throw error;
 return result;
}

export function createCpuProfiler(directory,execution){
 const root=resolve(directory);
 mkdirSync(root,{recursive:true});
 const runDirectory=mkdtempSync(join(root,`selfhost-${process.pid}-thread-${threadId}-`));
 const identity={pid:process.pid,threadId,isMainThread};
 const startedAt=new Date().toISOString();
 const allocationSamplingIntervalBytes=4194304;
 const run={schemaVersion:1,kind:'selfhost-worker-cpu-profile',acceptanceEvidence:false,runDirectory,startedAt,...identity,execution,runtime:{versions:process.versions,platform:process.platform,arch:process.arch,execPath:process.execPath,execArgv:process.execArgv},samplingIntervalUs:1000,allocationSamplingIntervalBytes,allocationScope:'worker-isolate allocation samples, including objects collected by minor and major GC; statistical estimates, not exact byte counts',cpuScope:'process.cpuUsage: entire process, not exclusively this worker or spawned fixture children',memoryScope:'process.memoryUsage: RSS is process-wide; other fields describe this worker isolate',profileScope:'local inspector session: this worker isolate; spawned fixture children have separate CLI CPU profiles and resource summaries'};
 writeFileSync(join(runDirectory,'run.json'),JSON.stringify(run,null,2)+'\n',{flag:'wx'});
 const session=new Session();
 let active,sequence=0;
 function stop(boundary,status='completed'){
  if(!active)return;
  const interval=active;
  const endedAt=new Date().toISOString(),endedMs=performance.now();
  const cpuUs=process.cpuUsage(interval.cpuStart),memoryEnd=process.memoryUsage();
  const {profile}=post(session,'Profiler.stop');
  const allocationProfile=post(session,'HeapProfiler.stopSampling').profile;
  active=undefined;
  writeFileSync(interval.profilePath,JSON.stringify(profile)+'\n',{flag:'wx'});
  writeFileSync(interval.allocationProfilePath,JSON.stringify(allocationProfile)+'\n',{flag:'wx'});
  const summary={schemaVersion:1,kind:'selfhost-worker-phase',runDirectory,...identity,sequence:interval.sequence,phase:interval.phase,details:interval.details,status,boundary,startedAt:interval.startedAt,endedAt,startElapsedMs:interval.startedMs,endElapsedMs:endedMs,wallMs:endedMs-interval.startedMs,cpuUs,cpuMs:(cpuUs.user+cpuUs.system)/1000,memoryStart:interval.memoryStart,memoryEnd,profilePath:interval.profilePath,allocationProfilePath:interval.allocationProfilePath};
  writeFileSync(interval.summaryPath,JSON.stringify(summary,null,2)+'\n',{flag:'wx'});
 }
 function mark(phase,details={}){
  stop({phase,details});
  const number=++sequence;
  const label=[phase,details.parserBoundary].filter(Boolean).join('-').replace(/[^A-Za-z0-9_.-]/g,'_').slice(0,120);
  const stem=join(runDirectory,String(number).padStart(6,'0')+'-'+label);
  post(session,'Profiler.start');
  post(session,'HeapProfiler.startSampling',{samplingInterval:allocationSamplingIntervalBytes,includeObjectsCollectedByMajorGC:true,includeObjectsCollectedByMinorGC:true});
  active={sequence:number,phase,details:{...details},profilePath:stem+'.cpuprofile',allocationProfilePath:stem+'.heapprofile',summaryPath:stem+'.json',startedAt:new Date().toISOString(),startedMs:performance.now(),cpuStart:process.cpuUsage(),memoryStart:process.memoryUsage()};
 }
 try{
  session.connect();
  post(session,'Profiler.enable');
  post(session,'Profiler.setSamplingInterval',{interval:1000});
  post(session,'HeapProfiler.enable');
 }catch(error){session.disconnect();throw error;}
 return {
  mark,
  childExecution(phase,details){
   const childDirectory=mkdtempSync(join(runDirectory,'fixture-child-'));
   const profilePath=join(childDirectory,'execution.cpuprofile');
   const context={runDirectory:childDirectory,parentRunDirectory:runDirectory,parent:identity,parentPhaseSequence:active?.sequence,phase,details,profilePath,acceptanceEvidence:false};
   writeFileSync(join(childDirectory,'launch.json'),JSON.stringify({...context,status:'launch-requested',requestedAt:new Date().toISOString()},null,2)+'\n',{flag:'wx'});
   const preload=new URL(import.meta.url);
   preload.searchParams.set('childProfile',JSON.stringify(context));
   return {
    args:['--cpu-prof','--cpu-prof-dir='+childDirectory,'--cpu-prof-name=execution.cpuprofile','--cpu-prof-interval=1000','--import='+preload.href],
    finish(result){
     const profileAvailable=existsSync(profilePath),summaryAvailable=existsSync(join(childDirectory,'summary.json'));
     writeFileSync(join(childDirectory,'exit.json'),JSON.stringify({...context,pid:result.pid,threadId:0,isMainThread:true,status:result.error||result.status!==0?'error':'completed',exitCode:result.status,signal:result.signal,error:result.error?String(result.error):undefined,stderr:result.stderr,profileAvailable,summaryAvailable,endedAt:new Date().toISOString()},null,2)+'\n',{flag:'wx'});
     if(!result.error&&result.status===0&&(!profileAvailable||!summaryAvailable))throw Error('Emitted fixture child CPU profiling evidence missing: '+childDirectory);
    },
   };
  },
  finish(error){
   try{
    if(error){
     const failedPhase=active?.phase;
     stop({phase:'error',failedPhase,error:String(error)},'error');
     mark('error',{failedPhase,error:String(error)});
    }
    stop({phase:'finally'},error?'error':'completed');
   }finally{session.disconnect();}
  },
 };
}
