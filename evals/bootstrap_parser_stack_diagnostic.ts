import {runHeavyGate} from './heavy_gate.ts';
import {createHash} from 'node:crypto';
import {readFileSync,writeFileSync,mkdtempSync,mkdirSync,rmSync,existsSync} from 'node:fs';
import {resolve,dirname,join} from 'node:path';
import {tmpdir} from 'node:os';

// One chosen prefix per invocation, always in a fresh artifact process/thread.
// Declaration offsets are column-zero candidates, not stage0-validated cuts.
// This runner diagnoses stages only; it makes no semantic/parity claim.
const worker=resolve(import.meta.dir,'bootstrap_parser_isolated_worker.mjs');
const sha=(data:string|Uint8Array)=>createHash('sha256').update(data).digest('hex');
const save=(path:string,value:unknown)=>writeFileSync(path,JSON.stringify(value,null,2)+'\n');
type Job={artifact:string;request:string;transport:string;status:string};
const childArg=process.argv.find(argument=>argument.startsWith('--child='));
if(childArg){
 const job:Job=JSON.parse(readFileSync(childArg.slice(8),'utf8'));
 const child=Bun.spawn(['node',worker,job.artifact,job.request,job.transport,job.status],{stdin:'ignore',stdout:'inherit',stderr:'inherit'});
 const code=await child.exited;
 if(!existsSync(job.status))throw Error('Artifact worker exited '+code+' without a status');
 const result=JSON.parse(readFileSync(job.status,'utf8'));
 process.exitCode=code!==0?code:['accepted','rejection'].includes(result.status)?0:2;
}else{
 const options=new Map<string,string>();
 for(let i=2;i<process.argv.length;i++){
  const argument=process.argv[i],equals=argument.indexOf('='),name=equals<0?argument:argument.slice(0,equals);
  if(!['--artifact','--report','--module','--prefix-chars','--declarations','--timeout-ms'].includes(name))throw Error('Unknown option '+name);
  const value=equals<0?process.argv[++i]:argument.slice(equals+1);
  if(!value)throw Error('Missing value for '+name);
  if(options.has(name))throw Error('Duplicate option '+name);
  options.set(name,value);
 }
 const integer=(text:string,name:string,min:number,max:number)=>{
  const value=Number(text);
  if(!Number.isSafeInteger(value)||value<min||value>max)throw Error(name+' must be an integer between '+min+' and '+max);
  return value;
 };
 if(options.has('--prefix-chars')===options.has('--declarations'))throw Error('Choose exactly one of --prefix-chars or --declarations');
 const manifestPath=resolve('checkpoints/bootstrap-real-source-corpus.json');
 const manifest=JSON.parse(readFileSync(manifestPath,'utf8'));
 const selector=options.get('--module')??'2';
 const item=manifest.modules.find((entry:{id:number})=>String(entry.id)===selector);
 if(!item)throw Error('Unknown frozen module '+selector);
 const source=readFileSync(item.snapshot,'utf8');
 if(sha(source)!==item.sourceSha256)throw Error('Frozen source snapshot hash mismatch');
 const candidates=[...source.matchAll(/^(?:def |type |law |@unsafe\b).*$/gm)].map(match=>({offset:match.index!,header:match[0]}));
 let end:number,declarations:number|undefined;
 if(options.has('--prefix-chars'))end=integer(options.get('--prefix-chars')!,'--prefix-chars',0,source.length);
 else{
  declarations=integer(options.get('--declarations')!,'--declarations',0,candidates.length);
  end=candidates[declarations]?.offset??source.length;
 }
 const prefix=source.slice(0,end),timeoutMs=integer(options.get('--timeout-ms')??'120000','--timeout-ms',1,Number.MAX_SAFE_INTEGER);
 const artifact=resolve(options.get('--artifact')??'checkpoints/bootstrap-parser-rebuild-f32-bounded-v1.js');
 const artifactSha256=sha(readFileSync(artifact));
 const report=resolve(options.get('--report')??'checkpoints/bootstrap-parser-stack-diagnostic.json');
 mkdirSync(dirname(report),{recursive:true});
 const temporary=mkdtempSync(join(tmpdir(),'bend-stack-diagnostic-'));
 const job:Job={artifact,request:join(temporary,'request.json'),transport:report+'.ast.json',status:report+'.worker.json'};
 const metadata={criterion:'single-prefix compiled stack stage diagnosis only',module:item.id,file:item.file,snapshot:item.snapshot,sourceSha256:item.sourceSha256,prefixSha256:sha(prefix),sourceChars:source.length,prefixChars:end,declarations,candidateCount:candidates.length,lastCandidate:declarations?candidates[declarations-1]:undefined,nextCandidate:candidates.find(candidate=>candidate.offset>=end),boundaryMethod:'column-zero candidates only; no stage0 boundary/parity proof',artifact,artifactSha256,limits:{timeoutMs,memoryMiB:8192,rssMiB:8192,pollMs:10,maxHeavyChildren:1,fuel:2000000},workerStatus:job.status,workerPhases:job.status+'.phases.jsonl',transport:job.transport};
 save(report,{...metadata,finished:false});
 try{
  save(job.request,{file:item.file,source:prefix});
  const jobPath=join(temporary,'job.json');save(jobPath,job);
  for(const path of [job.status,job.status+'.phases.jsonl',job.transport])rmSync(path,{force:true});
  const guardian=await runHeavyGate(['node',worker,'--supervise',process.execPath,import.meta.path,jobPath,job.status,String(timeoutMs)],{label:'Compiled parser single-prefix stack diagnosis '+item.id,memoryMiB:8192,rssMiB:8192,pollMs:10});
  const result=existsSync(job.status)?JSON.parse(readFileSync(job.status,'utf8')):{status:'runtime-error',error:'No worker status; inspect guardian and persisted phase sidecar'};
  save(report,{...metadata,finished:true,status:guardian.status==='RESOURCE_LIMIT'?'resource-limit':result.status,result,guardian});
  if(guardian.status!=='PASS'||!['accepted','rejection'].includes(result.status))process.exitCode=2;
 }finally{rmSync(temporary,{recursive:true,force:true});}
}
