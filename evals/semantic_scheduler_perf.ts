#!/usr/bin/env bun
/** Fast source-compiler development benchmark; never qualification.
 * Reuses an existing image, freshly parses/checks/emits each small fixture,
 * compiles its C and checks literal stdout. No compiler/native rebuild or AST cache.
 * --image=COMPILER.mjs --node=NODE --source=FIXTURE.bend --out=FRESH_DIR
 * [--host=HOST.ts] [--repository=REPO] [--samples=1] [--budget-ms=20000]
 */
import {createHash} from 'node:crypto';
import {existsSync,mkdirSync,readFileSync,writeFileSync} from 'node:fs';
import {resolve,join,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {runHeavyGate} from './heavy_gate.ts';

const values=new Map<string,string>();
for(const argument of process.argv.slice(2)){
 const at=argument.indexOf('='),key=argument.slice(0,at),value=argument.slice(at+1);
 if(at<0||!['--image','--node','--source','--out','--host','--repository','--samples','--budget-ms'].includes(key)||!value||values.has(key))throw Error('Expected unique documented --option=value');
 values.set(key,value);
}
for(const key of ['--image','--node','--source','--out'])if(!values.has(key))throw Error('Missing '+key);
const repository=resolve(values.get('--repository')??join(dirname(fileURLToPath(import.meta.url)),'..'));
const image=resolve(values.get('--image')!),node=resolve(values.get('--node')!),source=resolve(values.get('--source')!),out=resolve(values.get('--out')!);
const host=resolve(values.get('--host')??join(repository,'evals/candidate_host.ts'));
const samples=Number(values.get('--samples')??1),budgetMs=Number(values.get('--budget-ms')??20000);
if(!Number.isSafeInteger(samples)||samples<1||samples>10)throw Error('samples must be 1..10');
if(!Number.isSafeInteger(budgetMs)||budgetMs<1||budgetMs>60000)throw Error('fast benchmark budget must be 1..60000ms, not the final qualification deadline');
if(existsSync(out))throw Error('Use a fresh output directory: '+out);
const fixture=readFileSync(source,'utf8'),expected=fixture.split('\n').filter(line=>line.startsWith('#|')).map(line=>line.slice(2)).join('\n');
if(!fixture.split('\n').some(line=>line.startsWith('#|')))throw Error('Representative fixture must declare literal expected stdout');
const hash=(path:string)=>createHash('sha256').update(readFileSync(path)).digest('hex');
const pins=Object.fromEntries([source,image,node,host,join(repository,'evals/candidate_consumer_worker.mjs'),join(repository,'bend2/base.bend'),join(repository,'bend2/selfhost/c_runtime.c')].map(path=>[path,hash(path)]));
mkdirSync(out,{recursive:true});
const save=(name:string,value:unknown)=>writeFileSync(join(out,name),JSON.stringify(value,null,2)+'\n',{flag:'wx'});
const rows:any[]=[],commands:{sample:number;stage:string;argv:string[]}[]=[];
const limits={memoryMiB:8192,rssMiB:8192,pollMs:10,timeoutMs:budgetMs};
const base={schemaVersion:1,kind:'representative-semantic-scheduler-performance',acceptanceEvidence:false,
 source,image,repository,samples,budgetMs,limits,pins,expected,
 scope:'Reduced development workload, not original scheduler/native bootstrap/fixedpoint/strict12; source compiler algorithms run inside the supplied image'};
async function guarded(sample:number,name:string,argv:string[],directory:string){
 commands.push({sample,stage:name,argv});
 const result=await runHeavyGate(['/bin/sh','-c','out=$1; err=$2; shift 2; exec "$@" >"$out" 2>"$err"','sh',join(directory,name+'.stdout'),join(directory,name+'.stderr'),...argv],{...limits,label:'Representative scheduler '+sample+' '+name});
 writeFileSync(join(directory,name+'.guard.json'),JSON.stringify(result,null,2)+'\n',{flag:'wx'});
 if(result.status!=='PASS'||result.ownedTreeStopped!==true)throw Error(name+' failed: '+result.reason);
 return result;
}
try{
 for(let sample=0;sample<samples;sample++){
  const directory=join(out,'sample-'+sample);mkdirSync(directory);
  const c=join(directory,'program.c'),binary=join(directory,'program');
  const emit=await guarded(sample,'emit',[node,'--experimental-strip-types',join(repository,'evals/candidate_consumer_worker.mjs'),host,
   '--candidate='+image,'--parser='+image,'--stage-profile='+join(directory,'stages'),source,'-o',c,
   '--base',join(repository,'bend2/base.bend'),'--runtime-c',join(repository,'bend2/selfhost/c_runtime.c')],directory);
  const emitted=JSON.parse(readFileSync(join(directory,'emit.stdout'),'utf8').trim());
  const profile=JSON.parse(readFileSync(emitted.stageProfile,'utf8'));
  const phases=profile.spans.filter((span:any)=>span.parentId===null).map((span:any)=>({name:span.name,status:span.status,wallMs:span.wallMs}));
  if(!phases.some((phase:any)=>phase.name==='emit'&&phase.status==='completed'))throw Error('Source emitter phase did not complete');
  const clang=await guarded(sample,'clang',['/usr/bin/clang','-std=c11','-O0','-ferror-limit=0','-pthread','-lm','-o',binary,c],directory);
  const run=await guarded(sample,'run',[binary],directory),observed=readFileSync(join(directory,'run.stdout'),'utf8').trimEnd();
  if(observed!==expected)throw Error('Representative executable stdout mismatch');
  rows.push({sample,phases,emit,clang,run,CSourceSha256:hash(c),CBytes:readFileSync(c).length,observed,profile:emitted.stageProfile});
  save('sample-'+sample+'.json',{...base,status:'RUNNING',completedSamples:rows.length,rows,commands});
 }
 for(const [path,digest]of Object.entries(pins))if(hash(path)!==digest)throw Error('Benchmark input changed: '+path);
 const result={...base,status:'REPRESENTATIVE_PERF_PASS',rows,commands};save('outcome.json',result);
 console.log(JSON.stringify({status:result.status,acceptanceEvidence:false,source,rows:rows.map(row=>({sample:row.sample,
  emitWallMs:row.phases.find((phase:any)=>phase.name==='emit').wallMs,pipelineWallMs:row.emit.elapsedMs,
  clangMs:row.clang.elapsedMs,runMs:row.run.elapsedMs,CBytes:row.CBytes})),out}));
}catch(error){save('outcome.json',{...base,status:'REPRESENTATIVE_PERF_FAIL',rows,commands,error:String(error)});console.error(error);process.exitCode=1;}
