import {spawn} from 'node:child_process';
import {createHash} from 'node:crypto';
import {accessSync,constants,mkdtempSync,readFileSync,realpathSync,rmSync,writeFileSync} from 'node:fs';
import {delimiter,dirname,isAbsolute,join,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {guardHeavyGate} from './heavy_gate.ts';

type LlvmStage={name:string;command:string[];timingCommand:string[];status:'RUNNING'|'PASS'|'FAIL';
 startedMs:number;wallMs?:number;exitCode?:number|null;signal?:string|null;stdout:string;stderr:string;
 timedRealSeconds:number|null;userSeconds:number|null;systemSeconds:number|null;maxRssBytes:number|null;error?:string};
type LlvmPipeline={kind:'llvm-split';status:'RUNNING'|'PASS'|'FAIL';optimization:'-O1'|'-O2';frontendOptimization:'-O1';partitions:4;maxBackendChildren:3;
 source:string;sourceSha256:string;artifact:string;temporaryDirectory?:string;temporaryFilesRemoved:boolean;
 elapsedMs:number;stages:LlvmStage[];toolPins:Record<string,string>;versions:Record<string,string>;sdk?:string;
 abi?:{preprocessorCommand:string[];macros:string[];driverCommand:string[];driverOutput:string};
 accounting:string;failure?:string};

function executable(command:string):string{
 const candidates=isAbsolute(command)||command.includes('/')?[resolve(command)]:(process.env.PATH??'').split(delimiter).map(directory=>join(directory,command));
 for(const candidate of candidates){
  try{accessSync(candidate,constants.X_OK);return realpathSync(candidate);}catch(error){
   if(!['ENOENT','ENOTDIR','EACCES'].includes((error as NodeJS.ErrnoException).code??''))throw error;
  }
 }
 throw Error('Executable not found: '+command);
}

/** Native backend only. The caller owns the existing whole-build guardian and
 * has already terminated the separate canonical validation/codegen process.
 * Darwin time -lp supplies real wait4 CPU/maxRSS, not Node's parent-only usage.
 */
async function buildLlvmSplit(source:string,sourceSha256:string,artifact:string,cc:string,llvmBin:string|undefined,
 optimization:LlvmPipeline['optimization'],update:(pipeline:LlvmPipeline)=>void):Promise<LlvmPipeline>{
 const started=performance.now();
 const pipeline:LlvmPipeline={kind:'llvm-split',status:'RUNNING',optimization,frontendOptimization:'-O1',partitions:4,maxBackendChildren:3,
  source,sourceSha256,artifact,temporaryFilesRemoved:false,elapsedMs:0,stages:[],toolPins:{},versions:{},
  accounting:'Darwin /usr/bin/time -lp wait4 user/system CPU and maxRSS bytes per command; stage wallMs includes launch/reap. The unchanged outer guardian samples the complete build process tree, including concurrent compiler descendants. Interrupted stages may have null resource fields.'};
 const publish=()=>{pipeline.elapsedMs=performance.now()-started;update(pipeline);};
 const run=async(name:string,command:string[],quiet=false):Promise<LlvmStage>=>{
  const stage:LlvmStage={name,command,timingCommand:['/usr/bin/time','-lp',...command],status:'RUNNING',startedMs:performance.now()-started,
   stdout:'',stderr:'',timedRealSeconds:null,userSeconds:null,systemSeconds:null,maxRssBytes:null};
  pipeline.stages.push(stage);publish();
  const wall=performance.now();
  try{
   const child=spawn(stage.timingCommand[0]!,stage.timingCommand.slice(1),{stdio:['ignore','pipe','pipe'],env:{...process.env,LC_ALL:'C'}});
   child.stdout.on('data',(chunk:Buffer)=>{stage.stdout+=chunk.toString();if(!quiet)process.stdout.write(chunk);});
   child.stderr.on('data',(chunk:Buffer)=>{stage.stderr+=chunk.toString();if(!quiet)process.stderr.write(chunk);});
   child.once('error',error=>{stage.error=String(error);});
   await new Promise<void>(done=>child.once('close',(code,signal)=>{stage.exitCode=code;stage.signal=signal;done();}));
   for(const line of stage.stderr.split('\n')){
    const time=/^(real|user|sys)\s+([0-9]+(?:\.[0-9]+)?)\s*$/.exec(line);
    if(time){
     const seconds=Number(time[2]);
     if(time[1]==='real')stage.timedRealSeconds=seconds;
     else if(time[1]==='user')stage.userSeconds=seconds;
     else stage.systemSeconds=seconds;
    }
    const rss=/^\s*([0-9]+)\s+maximum resident set size\s*$/.exec(line);
    if(rss)stage.maxRssBytes=Number(rss[1]);
   }
   stage.status=stage.exitCode===0&&!stage.error&&stage.timedRealSeconds!==null&&stage.userSeconds!==null&&stage.systemSeconds!==null&&stage.maxRssBytes!==null?'PASS':'FAIL';
   if(stage.exitCode===0&&stage.status==='FAIL'&&!stage.error)stage.error='Darwin time resource receipt is incomplete';
  }catch(error){stage.status='FAIL';stage.error=String(error);}
  stage.wallMs=performance.now()-wall;publish();return stage;
 };
 const requireStage=async(name:string,command:string[],quiet=false)=>{
  const stage=await run(name,command,quiet);
  if(stage.status!=='PASS')throw Error('LLVM pipeline '+name+' failed: '+(stage.error??String(stage.exitCode)+' '+String(stage.signal)));
  return stage;
 };
 let temporary:string|undefined;
 try{
  publish();
  if(process.platform!=='darwin'||process.arch!=='arm64')throw Error('llvm-split currently requires the measured Darwin arm64 Apple clang21 backend; use direct explicitly on other platforms');
  const clang=executable(cc),opt=executable(llvmBin?join(llvmBin,'opt'):'opt'),split=executable(llvmBin?join(llvmBin,'llvm-split'):'llvm-split');
  for(const path of [clang,opt,split,'/usr/bin/time'])pipeline.toolPins[path]=createHash('sha256').update(readFileSync(path)).digest('hex');
  for(const [name,path] of [['clang',clang],['opt',opt],['llvm-split',split]]){
   const version=await requireStage(name+'-version',[path!,'--version'],true);pipeline.versions[name!]=version.stdout.trim();
  }
  if(!/^Apple clang version 21\./.test(pipeline.versions.clang!))throw Error('llvm-split requires Apple clang21; CC selects the compiler, never an ABI macro override');
  const optVersion=/LLVM version (21\.\d+\.\d+)/.exec(pipeline.versions.opt!)?.[1];
  const splitVersion=/LLVM version (21\.\d+\.\d+)/.exec(pipeline.versions['llvm-split']!)?.[1];
  if(!optVersion||optVersion!==splitVersion)throw Error('llvm-split requires matching LLVM21 opt and llvm-split versions');
  const sdk=realpathSync(process.env.SDKROOT||(await requireStage('sdk',['/usr/bin/xcrun','--show-sdk-path'],true)).stdout.trim());
  pipeline.sdk=sdk;
  const preprocessing=[clang,'-std=c11','-O1','-E','-dM',source,'-isysroot',sdk];
  const macros=await requireStage('abi-macros',preprocessing,true);
  const driverCommand=[clang,'-std=c11','-O1','-c',source,'-isysroot',sdk,'-o',artifact,'-###'];
  const driver=await requireStage('abi-driver',driverCommand,true);
  pipeline.abi={preprocessorCommand:preprocessing,
   macros:macros.stdout.split('\n').filter(line=>/^#define (?:PRESERVE\(|WL_FN |OUTLINE |WL_JMP\(|WL_DYN\(|__OPTIMIZE__ |__apple_build_version__ |__clang_version__ |__ARM_ARCH|__ARM_FEATURE)/.test(line)),
   driverCommand,driverOutput:driver.stderr};publish();
  temporary=mkdtempSync(join(dirname(artifact),'.native-llvm-'));pipeline.temporaryDirectory=temporary;publish();
  const raw=join(temporary,'raw.bc'),prepared=join(temporary,'prepared.bc');
  await requireStage('frontend',[clang,'-std=c11','-O1','-Xclang','-disable-llvm-passes','-emit-llvm','-c',source,'-isysroot',sdk,'-o',raw]);
  await requireStage('mem2reg-always-inline',[opt,'-passes=function(mem2reg),always-inline',raw,'-o',prepared]);
  // Keep mandatory helper inlining above; ordinary selected optimization belongs to
  // each partition, not an expanding whole-module inliner before the split.
  await requireStage('split',[split,'-j4',prepared,'-o',join(temporary,'part.bc')]);
  const objects=Array.from({length:4},(_,i)=>join(temporary!,'part'+i+'.o'));
  const pending=[3,2,1,0],running=new Map<number,Promise<{id:number;stage:LlvmStage}>>();
  let firstFailure:LlvmStage|undefined;
  while(pending.length||running.size){
   while(pending.length&&running.size<pipeline.maxBackendChildren&&!firstFailure){
    const id=pending.shift()!;
    const command=[clang,optimization,'-x','ir','-c',join(temporary,'part.bc'+id),'-isysroot',sdk,'-o',objects[id]!];
    running.set(id,run('opt-codegen-'+id,command).then(stage=>({id,stage})));
   }
   if(!running.size)break;
   const completed=await Promise.race(running.values());running.delete(completed.id);
   if(completed.stage.status!=='PASS'&&!firstFailure)firstFailure=completed.stage;
  }
  // Do not launch replacement jobs or link after failure. Reap every already
  // started timed child under the same guardian before reporting the first error.
  if(firstFailure)throw Error('LLVM pipeline '+firstFailure.name+' failed: '+(firstFailure.error??firstFailure.exitCode));
  await requireStage('link',[clang,...objects,'-isysroot',sdk,'-lpthread','-lm','-o',artifact]);
  for(const [path,expected] of Object.entries(pipeline.toolPins)){
   if(createHash('sha256').update(readFileSync(path)).digest('hex')!==expected)throw Error('LLVM pipeline tool changed: '+path);
  }
  pipeline.status='PASS';return pipeline;
 }catch(error){pipeline.status='FAIL';pipeline.failure=String(error);throw error;
 }finally{
  if(temporary){rmSync(temporary,{recursive:true,force:true});pipeline.temporaryFilesRemoved=true;}
  publish();
 }
}

// Internal worker: the public experiment authenticates this source in its
// protected pins and starts it only after the entire codegen process exits.
// The inherited authenticated lease retains the original8GiB build deadline.
try{
 await guardHeavyGate(fileURLToPath(import.meta.url),{label:'Native LLVM split backend'});
 if(process.argv.length!==5)throw Error('Expected internal build-report, CC and LLVM-bin arguments');
 const reportPath=resolve(process.argv[2]!),report=JSON.parse(readFileSync(reportPath,'utf8'));
 const optimization:LlvmPipeline['optimization']=report.ccOptimization?.flag;
 if(report.status!=='C_GENERATED_NOT_YET_BUILT'||!['-O1','-O2'].includes(optimization))throw Error('LLVM worker requires a freshly generated O1/O2 public build report');
 if(createHash('sha256').update(readFileSync(report.cPath)).digest('hex')!==report.cSha256)throw Error('Generated C changed before LLVM backend');
 await buildLlvmSplit(report.cPath,report.cSha256,report.artifact,process.argv[3]!,process.argv[4]||undefined,optimization,pipeline=>{
  writeFileSync(reportPath,JSON.stringify({...report,ccPipeline:pipeline},null,2)+'\n');
 });
}catch(error){console.error(String(error));process.exitCode=2;}
