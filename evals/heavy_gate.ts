#!/usr/bin/env bun
/** Exclusive, sampled resource lane for heavyweight commands.
 * Usage: bun evals/heavy_gate.ts [options] -- command args...
 * Options: --memory-mib (3072), --rss-mib (2048), --poll-ms (100),
 * --term-grace-ms (1000), --timeout-ms (600000), --lock-path. Equivalent
 * HEAVY_GATE_* variables use MEMORY_MIB, RSS_MIB, POLL_MS, TERM_GRACE_MS,
 * TIMEOUT_MS, LOCK_PATH suffixes. Deadlines cancel work; they are not language fuel.
 * Output is streamed; the final HEAVY_GATE JSON record is written to stderr.
 * Requires a C compiler once per helper source/platform hash. No heavy command
 * is started if compilation, sampling, authentication, or lock setup fails.
 * This is a periodic safety monitor, not a hard allocation quota. Commands
 * receive EOF on stdin; stdout/stderr are inherited without output buffering.
 */
import {spawn} from 'node:child_process';
import {createHash,randomBytes} from 'node:crypto';
import {mkdir,readFile,rename,rm,lstat,open,writeFile} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {dirname,join,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

export type HeavyGateStatus='PASS'|'FAIL'|'RESOURCE_LIMIT'|'LOCK_BUSY';
export interface HeavyGateOptions {
 label?:string;
 memoryMiB?:number;
 rssMiB?:number;
 pollMs?:number;
 termGraceMs?:number;
 timeoutMs?:number;
 lockPath?:string;
}
export interface HeavyGateResult {
 status:HeavyGateStatus;
 reportPhase:'decision'|'complete';
 ownedTreeStopped:boolean|null;
 reason:string;
 command:string[];
 label:string;
 commandExitCode:number;
 commandSignal:number;
 peakRssBytes:number;
 peakFootprintBytes:number;
 elapsedMs:number;
 exitCode:number;
 reportPath:string;
 memoryLimitBytes:number;
 rssLimitBytes:number;
 timeoutMs:number;
}
const MiB=1024*1024;
const leaseToken='HEAVY_GATE_LEASE_TOKEN';
const leasePath='HEAVY_GATE_LEASE_PATH';
const privateDirectory=join(tmpdir(),`bend-heavy-gate-${process.getuid!()}`);
const defaultTimeoutMs=600000;
const maximumTimeoutMs=2147483647;
const helperCompilationTimeoutMs=60000;
class HelperDeadlineError extends Error {
 readonly timeoutMs:number;
 constructor(timeoutMs:number){
  super(`heavy-gate helper timed out after ${timeoutMs} ms`);
  this.timeoutMs=timeoutMs;
 }
}

/** Bound small helper subprocesses too, including their compiler process group. */
async function helperExit(command:string,args:string[],timeoutMs:number):Promise<number>{
 const child=spawn(command,args,{detached:true,stdio:['ignore','inherit','inherit']});
 const completion=Promise.withResolvers<number>();
 let timedOut=false,interrupted=false;
 let killTimer:NodeJS.Timeout|undefined;
 const killGroup=(signal:NodeJS.Signals)=>{
  if(child.pid)try{process.kill(-child.pid,signal);}catch(error){
   if((error as NodeJS.ErrnoException).code!=='ESRCH')throw error;
  }
 };
 const stop=()=>{
  if(killTimer)return;
  killGroup('SIGTERM');
  killTimer=setTimeout(()=>killGroup('SIGKILL'),1000);
 };
 const onSignal=()=>{interrupted=true;stop();};
 const timer=setTimeout(()=>{timedOut=true;stop();},timeoutMs);
 process.on('SIGINT',onSignal);process.on('SIGTERM',onSignal);process.on('SIGHUP',onSignal);
 child.once('error',completion.reject);
 child.once('close',code=>completion.resolve(code??125));
 try{
  const code=await completion.promise;
  if(timedOut)throw new HelperDeadlineError(timeoutMs);
  if(interrupted)throw Error('heavy-gate helper interrupted');
  return code;
 }finally{
  clearTimeout(timer);
  if(killTimer){
   clearTimeout(killTimer);
   // The root may exit on TERM while a compiler descendant ignores it.
   killGroup('SIGKILL');
  }
  process.off('SIGINT',onSignal);process.off('SIGTERM',onSignal);process.off('SIGHUP',onSignal);
 }
}

async function secureDirectory(path:string):Promise<void>{
 await mkdir(path,{recursive:true,mode:0o700});
 const info=await lstat(path);
 if(!info.isDirectory()||info.isSymbolicLink()||info.uid!==process.getuid!()||(info.mode&0o077)!==0)
  throw Error(`heavy-gate directory must be owned by this user with mode 0700: ${path}`);
}
let helperPromise:Promise<string>|undefined;
async function prepareNativeHelper(timeoutMs:number):Promise<string>{
 if(process.platform!=='darwin'&&process.platform!=='linux')throw Error(`unsupported heavy-gate platform: ${process.platform}`);
 await secureDirectory(privateDirectory);
 const source=resolve(dirname(fileURLToPath(import.meta.url)),'heavy_gate_native.c');
 const hash=createHash('sha256').update(await readFile(source)).update(process.platform).update(process.arch).digest('hex').slice(0,24);
 const executable=join(privateDirectory,`supervisor-${hash}`);
 try{
  const info=await lstat(executable);
  if(!info.isFile()||info.isSymbolicLink()||info.uid!==process.getuid!()||(info.mode&0o022)!==0)throw Error('unsafe native helper cache');
  return executable;
 }catch(error){if((error as NodeJS.ErrnoException).code!=='ENOENT')throw error;}
 const temporary=`${executable}.${process.pid}.${randomBytes(8).toString('hex')}`;
 try{
  const code=await helperExit(process.env.CC??'cc',['-O2','-std=c11','-Wall','-Wextra',source,'-o',temporary],
   Math.min(timeoutMs,helperCompilationTimeoutMs));
  if(code!==0)throw Error(`heavy-gate native helper compilation exited ${code}`);
  await rename(temporary,executable);
 }finally{await rm(temporary,{force:true});}
 return executable;
}
function integer(value:unknown,name:string,min:number,max:number):number{
 const number=Number(value);
 if(!Number.isSafeInteger(number)||number<min||number>max)throw Error(`${name} must be an integer between ${min} and ${max}`);
 return number;
}
function normalize(options:HeavyGateOptions):Required<HeavyGateOptions>{
 return {
  label:options.label??'heavy command',
  memoryMiB:integer(options.memoryMiB??process.env.HEAVY_GATE_MEMORY_MIB??3072,'memory-mib',1,1048576),
  rssMiB:integer(options.rssMiB??process.env.HEAVY_GATE_RSS_MIB??2048,'rss-mib',1,1048576),
  pollMs:integer(options.pollMs??process.env.HEAVY_GATE_POLL_MS??100,'poll-ms',10,1000),
  termGraceMs:integer(options.termGraceMs??process.env.HEAVY_GATE_TERM_GRACE_MS??1000,'term-grace-ms',0,10000),
  timeoutMs:integer(options.timeoutMs??process.env.HEAVY_GATE_TIMEOUT_MS??defaultTimeoutMs,'timeout-ms',1,maximumTimeoutMs),
  lockPath:resolve(options.lockPath??process.env.HEAVY_GATE_LOCK_PATH??join(privateDirectory,'exclusive.lock')),
 };
}
/** Extract only gate options, preserving the command's positional arguments. */
export function parseHeavyGateOptions(args:readonly string[]):{options:HeavyGateOptions;args:string[]}{
 const options:HeavyGateOptions={},remaining:string[]=[];
 const names:Record<string,keyof HeavyGateOptions>={
  '--memory-mib':'memoryMiB','--rss-mib':'rssMiB','--poll-ms':'pollMs',
  '--term-grace-ms':'termGraceMs','--timeout-ms':'timeoutMs','--lock-path':'lockPath',
 };
 for(let i=0;i<args.length;i++){
  const argument=args[i]!;
  if(argument==='--'){remaining.push(...args.slice(i));break;}
  const equals=argument.indexOf('=');
  const name=equals<0?argument:argument.slice(0,equals),key=names[name];
  if(!key){remaining.push(argument);continue;}
  const value=equals<0?args[++i]:argument.slice(equals+1);
  if(value===undefined||value==='')throw Error(`missing value for ${name}`);
  if(key==='lockPath')options.lockPath=value;
  else (options as Record<string,unknown>)[key]=Number(value);
 }
 return {options,args:remaining};
}
async function authenticatedLease(timeoutMs:number):Promise<boolean>{
 const token=process.env[leaseToken],path=process.env[leasePath];
 if(!token||!path)return false;
 if(!/^[a-f0-9]{64}$/.test(token))return false;
 const helper=await (helperPromise??=prepareNativeHelper(timeoutMs));
 const code=await helperExit(helper,['--authenticate',path,token],Math.min(timeoutMs,5000));
 if(code===2)throw Error('heavy-gate inherited lease deadline expired');
 return code===0;
}
/** Public behavior seam. Never nests: guarded entrypoints authenticate the lease. */
export async function runHeavyGate(command:readonly string[],options:HeavyGateOptions={}):Promise<HeavyGateResult>{
 if(command.length===0||!command[0])throw Error('heavy-gate requires a command');
 const settings=normalize(options),helper=await (helperPromise??=prepareNativeHelper(settings.timeoutMs));
 // The default directory is private. Custom lock directories must be private too.
 await secureDirectory(dirname(settings.lockPath));
 const token=randomBytes(32).toString('hex');
 const reportPath=join(privateDirectory,`report-${Date.now()}-${randomBytes(8).toString('hex')}.json`);
 const reportFile=await open(reportPath,'wx',0o600);
 const child=spawn(helper,['--run',settings.lockPath,token,String(settings.memoryMiB*MiB),String(settings.rssMiB*MiB),
  String(settings.pollMs),String(settings.termGraceMs),String(settings.timeoutMs),'--',...command],{
  stdio:['pipe','inherit','inherit',reportFile.fd],
  // The supervisor owns the deadline and the owned process tree. It must not
  // die with the launcher's process group: a group SIGKILL of the launcher
  // otherwise leaves an empty receipt and no terminal outcome. Its stdin is
  // the lifeline; EOF/HUP from a dead launcher is handled natively.
  detached:true,
  env:{...process.env,[leaseToken]:token,[leasePath]:settings.lockPath},
 });
 const stop=()=>{if(!child.stdin?.destroyed)child.stdin?.end('s');};
 process.on('SIGINT',stop);process.on('SIGTERM',stop);process.on('SIGHUP',stop);
 // Keep the pipe open: EOF also triggers cleanup when the JS parent disappears.
 child.stdin?.on('error',()=>{});
 let exitCode:number;
 try{
  const completion=Promise.withResolvers<number>();
  child.once('error',completion.reject);
  child.once('close',(code,signal)=>completion.resolve(code??(signal?128:125)));
  exitCode=await completion.promise;
 }finally{
  process.off('SIGINT',stop);process.off('SIGTERM',stop);process.off('SIGHUP',stop);
  child.stdin?.destroy();
  await reportFile.close();
 }
 // A private file avoids fast-exit races on Bun's extra-stdio pipe delivery.
 const reportSize=(await lstat(reportPath)).size;
 if(reportSize===0||reportSize>16384)throw Error(`heavy-gate supervisor exited ${exitCode} without a valid bounded report`);
 const record=JSON.parse(await readFile(reportPath,'utf8'));
 if(!['PASS','FAIL','RESOURCE_LIMIT','LOCK_BUSY'].includes(record.status))throw Error('invalid heavy-gate supervisor status');
 // A decision-phase record is provisional: the supervisor may still be
 // cleaning the owned tree and can be killed before the final record. Only a
 // complete record with the owned tree confirmed stopped may be a success;
 // any missing or provisional evidence is a failure, never PASS.
 const reportPhase=record.reportPhase==='complete'?'complete':'decision';
 const ownedTreeStopped=record.ownedTreeStopped===true?true:record.ownedTreeStopped===false?false:null;
 let status=record.status as HeavyGateStatus;
 if((reportPhase!=='complete'||ownedTreeStopped===false||ownedTreeStopped===null)&&status==='PASS')status='FAIL';
 const result:HeavyGateResult={...record,status,reportPhase,ownedTreeStopped,command:[...command],label:settings.label,exitCode,
  reportPath,memoryLimitBytes:settings.memoryMiB*MiB,rssLimitBytes:settings.rssMiB*MiB,timeoutMs:settings.timeoutMs};
 await writeFile(reportPath,JSON.stringify(result)+'\n',{mode:0o600});
 console.error('HEAVY_GATE '+JSON.stringify(result));
 return result;
}
/** Call before book loading/checking/generation or any other heavyweight work. */
export async function guardHeavyGate(scriptPath:string,options:{label:string}):Promise<void>{
 const parsed=parseHeavyGateOptions(process.argv.slice(2));
 process.argv.splice(2,process.argv.length-2,...parsed.args);
 // Authenticated descendants retain the native parent's original deadline;
 // their CLI/environment options cannot start a fresh time allowance.
 if(await authenticatedLease(normalize(parsed.options).timeoutMs))return;
 const result=await runHeavyGate([process.execPath,resolve(scriptPath),...parsed.args],{...parsed.options,label:options.label});
 process.exit(result.exitCode);
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 try{
  const argv=process.argv.slice(2),separator=argv.indexOf('--');
  if(separator<0)throw Error('usage: bun evals/heavy_gate.ts [options] -- command args...');
  const parsed=parseHeavyGateOptions(argv.slice(0,separator));
  if(parsed.args.length)throw Error(`unknown heavy-gate option: ${parsed.args[0]}`);
  const result=await runHeavyGate(argv.slice(separator+1),parsed.options);
  process.exitCode=result.exitCode;
 }catch(error){
  console.error('HEAVY_GATE '+JSON.stringify({status:'FAIL',
   reason:error instanceof HelperDeadlineError?'helper_deadline_exceeded':'runner_error',
   ...(error instanceof HelperDeadlineError?{timeoutMs:error.timeoutMs}:{}),error:String(error)}));
  process.exitCode=125;
 }
}
