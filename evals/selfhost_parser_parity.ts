import {sourceOracle} from './bootstrap_source_oracle.ts';
import type {SourceOracleResult} from './bootstrap_source_oracle.ts';
import {coreBookHash,canonicalDeclarationsHash} from './parser_full_semantic_normalize.ts';
import type {Node,Value} from './parser_full_semantic_normalize.ts';
import {readNativeAstArena} from './bootstrap_ast_transport.ts';
import {readFileSync,writeFileSync,mkdirSync,mkdtempSync,unlinkSync,existsSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {dirname,join,resolve} from 'node:path';
import {Worker,isMainThread,parentPort,workerData} from 'node:worker_threads';
import {spawn} from 'node:child_process';
import {createInterface} from 'node:readline';
import {fileURLToPath} from 'node:url';
import {guardHeavyGate} from './heavy_gate.ts';

export type ParityRequest={file:string;source:string;transport:string;recordInputs:boolean;profileContext?:Record<string,unknown>};
export type ParityResult={
 stage0ASTHash:string;compiledASTHash:string;transportSha256:string;
 transportSpanCount:number;transportSpanSha256:string;
 normalizationLedger:{observation:SourceOracleResult['observation'];exclusions:SourceOracleResult['exclusions']};
 declarations:number;inputFiles:SourceOracleResult['inputFiles'];loadContexts:SourceOracleResult['loadContexts'];
};
type Observe=(boundary:string)=>void;
const node=(value:unknown):Node=>{if(!value||typeof value!=='object'||Array.isArray(value)||!('tag' in value)||typeof value.tag!=='string'||!('fields' in value)||!Array.isArray(value.fields))throw Error('Expected complete AST constructor');return value as Node;};

export async function parserParity(request:ParityRequest,observe:Observe=()=>{}):Promise<ParityResult>{
 const {file,source,transport,recordInputs}=request;
 if(readFileSync(file,'utf8')!==source)throw Error('Source changed before full parity');
 observe('source-before');
 const oracle=await sourceOracle(file,source,{preloadBase:false,recordInputs});
 if(!oracle.accepted)throw Error('Complete source oracle failed: '+String(oracle.error)+'; '+JSON.stringify(oracle.failure));
 const environment=oracle.normalizationBook();observe('source-complete');
 const stage0ASTHash=coreBookHash(environment,oracle.declarations.map(d=>d.key),oracle.imports.map(i=>({path:i.path,alias:i.alias})),file,dirname(file)+'/');
 observe('expected-complete');
 const {arena,sha256:transportSha256}=await readNativeAstArena(transport);
 if(arena.tag(arena.root)!=='ParseSuccess')throw Error('Expected transported ParseSuccess module');
 const module=arena.field(arena.root,'module');
 if(arena.tag(module)!=='Module')throw Error('Expected complete AST module');
 if(arena.semantic(arena.field(module,'path'))!==file)throw Error('Transported module lost its actual source path');
 const spanHash=createHash('sha256');let spanCount=0;
 function authenticateSpans(value:Value){
  const pending:Value[]=[value],seen=new Set<object>();
  while(pending.length){
   const current=pending.pop()!;
   if(!current||typeof current!=='object'||seen.has(current))continue;
   seen.add(current);
   const fields=Array.isArray(current)?current:current.fields;
   if(!Array.isArray(current)&&current.tag==='SpanOf'){
    const [at,beg,end]=fields;
    if(fields.length!==3||at!==file||typeof beg!=='number'||typeof end!=='number'||!Number.isSafeInteger(beg)||!Number.isSafeInteger(end)||beg<0||end<beg||end>source.length)throw Error('Transported AST lost an actual UTF-16 source span');
    spanHash.update(JSON.stringify(fields));spanCount++;
   }else for(let i=fields.length-1;i>=0;i--)if(i in fields)pending.push(fields[i]);
  }
 }
 observe('transport-decoded');
 const imports=[...arena.list(arena.field(module,'imports'))].map(cursor=>{const value=node(arena.semantic(cursor));authenticateSpans(value);return value;});
 const semanticImports=imports.map(v=>{if(typeof v.fields[0]!=='string'||typeof v.fields[1]!=='string')throw Error('Malformed full AST import');return {path:v.fields[0],alias:v.fields[1]};});
 const adjustedImports=semanticImports.map(v=>({...v,path:oracle.imports.find(i=>i.alias===v.alias)?.namespace||v.path}));
 function* declarations(){
  for(const cursor of arena.list(arena.field(module,'declarations'))){
   const value=arena.semantic(cursor);authenticateSpans(value);yield value;
  }
 }
 const compiledASTHash=canonicalDeclarationsHash(adjustedImports,declarations(),environment,source,semanticImports);observe('actual-complete');
 return {stage0ASTHash,compiledASTHash,transportSha256,transportSpanCount:spanCount,transportSpanSha256:spanHash.digest('hex'),normalizationLedger:{observation:oracle.observation,exclusions:oracle.exclusions},declarations:oracle.declarations.length,inputFiles:oracle.inputFiles,loadContexts:oracle.loadContexts};
}

export async function isolatedParserParity(request:ParityRequest,observe:(event:Record<string,unknown>)=>void){
 if(process.env.SELFHOST_CPU_PROFILE_DIR)return profiledParserParity(request,observe);
 const worker=new Worker(new URL(import.meta.url),{workerData:request});
 let result:ParityResult|undefined;
 let timer:NodeJS.Timeout|undefined;
 await new Promise<void>((resolve,reject)=>{
  timer=setTimeout(()=>{void worker.terminate();reject(Error('Isolated full parity exceeded 300000 ms'));},300000);
  worker.on('message',message=>{if(message.event==='memory')observe(message);else if(message.event==='result')result=message.result;else if(message.event==='failure')reject(Error(message.error));});
  worker.on('error',reject);
  worker.on('exit',code=>{code===0&&result?resolve():reject(Error('Isolated full parity did not complete: '+code));});
 }).finally(()=>{clearTimeout(timer);return worker.terminate();});
 return result!;
}

// CLI profiling gives the oracle its own process/profile, never the compiler's
// paused process or the orchestration thread. The inherited guardian still
// accounts for this descendant under the unchanged aggregate 8 GiB limits.
async function profiledParserParity(request:ParityRequest,observe:(event:Record<string,unknown>)=>void){
 if(!process.versions.bun)throw Error('Parser oracle CPU profiling requires the Bun runtime');
 const directory=resolve(process.env.SELFHOST_CPU_PROFILE_DIR!);mkdirSync(directory,{recursive:true});
 const run=mkdtempSync(join(directory,'parser-oracle-'));
 const requestPath=join(run,'request.json'),profile=join(run,'parser-oracle.cpuprofile'),summary=join(run,'summary.json');
 const {source,...receipt}=request;
 const sourceSha256=createHash('sha256').update(source).digest('hex');
 writeFileSync(requestPath,JSON.stringify({...receipt,sourceSha256,profile,summary})+'\n',{flag:'wx'});
 const command=[process.execPath,'--smol','--cpu-prof','--cpu-prof-name=parser-oracle.cpuprofile','--cpu-prof-dir='+run,fileURLToPath(import.meta.url),'--profile-oracle='+requestPath];
 const started=performance.now(),startedAt=new Date().toISOString();
 const child=spawn(command[0]!,command.slice(1),{stdio:['ignore','pipe','inherit']});
 let result:ParityResult|undefined,failure:unknown,timedOut=false;
 const completed=new Promise<{code:number|null;signal:string|null}>((done,reject)=>{
  child.once('error',reject);child.once('close',(code,signal)=>done({code,signal}));
 });
 // Observe spawn failure immediately even while stdout is being consumed.
 void completed.catch(()=>{});
 const timer=setTimeout(()=>{timedOut=true;child.kill('SIGKILL');},300000);
 let exit:{code:number|null;signal:string|null}|undefined;
 try{
  for await(const line of createInterface({input:child.stdout!})){
   const message=JSON.parse(line);
   if(message.event==='result')result=message.result;
   else if(message.event==='failure')failure=Error(message.error);
   else observe({...message,profile,summary,command});
  }
  exit=await completed;
  if(timedOut)throw Error('Isolated full parity exceeded 300000 ms');
  if(failure)throw failure;
  if(exit.code!==0||!result)throw Error('Profiled full parity did not complete: '+exit.code);
  return result;
 }catch(error){
  failure??=error;throw error;
 }finally{
  clearTimeout(timer);
  if(!exit){child.kill('SIGKILL');try{exit=await completed;}catch(error){failure??=error;}}
  writeFileSync(join(run,'exit.json'),JSON.stringify({schemaVersion:1,role:'parser-oracle',pid:child.pid,parentPid:process.pid,command,startedAt,wallMs:performance.now()-started,exit,timedOut,error:failure?String(failure):undefined,profile,profileWritten:existsSync(profile),summary,summaryWritten:existsSync(summary),file:request.file,sourceSha256,context:request.profileContext},null,2)+'\n',{flag:'wx'});
  unlinkSync(requestPath);
 }
}

async function profileOracleChild(requestPath:string){
 await guardHeavyGate(fileURLToPath(import.meta.url),{label:'Selfhost parser parity oracle'});
 const receipt=JSON.parse(readFileSync(requestPath,'utf8')) as Omit<ParityRequest,'source'> & {sourceSha256:string;profile:string;summary:string};
 const started=performance.now(),startedAt=new Date().toISOString(),cpuStart=process.cpuUsage();
 const boundaries:Record<string,unknown>[]=[],phases:Record<string,unknown>[]=[];
 const maxObservedMemoryBytes={rss:0,heapTotal:0,heapUsed:0,external:0,arrayBuffers:0};
 let previousWall=started,previousCpu=cpuStart,previousBoundary='parity-start';
 const identity={role:'parser-oracle',pid:process.pid,parentPid:process.ppid,runtime:'bun',runtimeVersion:process.versions.bun,file:receipt.file,sourceSha256:receipt.sourceSha256,transport:receipt.transport,context:receipt.profileContext};
 const send=(message:Record<string,unknown>)=>process.stdout.write(JSON.stringify(message)+'\n');
 const sample=(boundary:string)=>{
  const now=performance.now(),cpu=process.cpuUsage(),memory=process.memoryUsage();
  for(const key of Object.keys(maxObservedMemoryBytes) as (keyof typeof maxObservedMemoryBytes)[])maxObservedMemoryBytes[key]=Math.max(maxObservedMemoryBytes[key],memory[key]);
  const row={oracleBoundary:boundary,wallMs:now-started,cpuUserMs:(cpu.user-cpuStart.user)/1000,cpuSystemMs:(cpu.system-cpuStart.system)/1000,...memory};
  boundaries.push(row);
  if(boundary!=='parity-start')phases.push({from:previousBoundary,to:boundary,wallMs:now-previousWall,cpuUserMs:(cpu.user-previousCpu.user)/1000,cpuSystemMs:(cpu.system-previousCpu.system)/1000,memoryAtEnd:memory});
  previousWall=now;previousCpu=cpu;previousBoundary=boundary;
  send({event:'memory',...identity,...row});
 };
 let result:ParityResult|undefined,error:unknown;
 try{
  sample('parity-start');
  const source=readFileSync(receipt.file,'utf8');
  if(createHash('sha256').update(source).digest('hex')!==receipt.sourceSha256)throw Error('Source changed before profiled full parity');
  result=await parserParity({...receipt,source},sample);
 }catch(cause){error=cause;process.exitCode=2;}
 finally{
  sample(error?'parity-failed':'parity-complete');
  const cpu=process.cpuUsage();
  // Boundary memory is sampled, not an allocation peak. resourceUsage contains
  // the runtime's process high-water counters; no manual collection is used.
  const evidence={
   schemaVersion:1,...identity,startedAt,profile:receipt.profile,
   profileScope:'whole oracle process, including startup; phase timing covers parity only',samplingIntervalMicroseconds:1000,
   parityCompleted:!!result,semanticParity:!!result&&result.stage0ASTHash===result.compiledASTHash,error:error?String(error):undefined,
   wallMs:performance.now()-started,cpuUserMs:(cpu.user-cpuStart.user)/1000,cpuSystemMs:(cpu.system-cpuStart.system)/1000,
   processCpuAtStartMicroseconds:cpuStart,processCpuAtEndMicroseconds:cpu,resourceUsage:process.resourceUsage(),
   memoryObservation:'memoryUsage values and maxima are observed only at named boundaries, not allocation peaks',maxObservedMemoryBytes,boundaries,phases,
   sourceReceipt:{file:receipt.file,sourceSha256:receipt.sourceSha256,inputClosureRecorded:receipt.recordInputs,inputFiles:result?.inputFiles,loadContexts:result?.loadContexts},
   parity:result?{stage0ASTHash:result.stage0ASTHash,compiledASTHash:result.compiledASTHash,transportSha256:result.transportSha256,normalizationLedger:result.normalizationLedger,declarations:result.declarations}:undefined,
  };
  writeFileSync(receipt.summary,JSON.stringify(evidence,null,2)+'\n',{flag:'wx'});
  send({event:'oracle-profile',...identity,profile:receipt.profile,summary:receipt.summary,wallMs:evidence.wallMs,cpuUserMs:evidence.cpuUserMs,cpuSystemMs:evidence.cpuSystemMs});
 }
 if(error)send({event:'failure',error:String(error)});
 else send({event:'result',result});
}

if(!isMainThread){
 try{const result=await parserParity(workerData,boundary=>parentPort!.postMessage({event:'memory',oracleBoundary:boundary,...process.memoryUsage()}));parentPort!.postMessage({event:'result',result});}
 catch(error){parentPort!.postMessage({event:'failure',error:String(error)});process.exitCode=2;}
 finally{parentPort!.close();}
}

if(isMainThread&&process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 const argument=process.argv[2];
 if(!argument?.startsWith('--profile-oracle=')||process.argv.length!==3)throw Error('Expected --profile-oracle=REQUEST.json');
 await profileOracleChild(argument.slice('--profile-oracle='.length));
}
