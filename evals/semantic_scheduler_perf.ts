#!/usr/bin/env bun
/** Reduced compiler development benchmark; never qualification.
 * oracle: canonical TS frontend/emitter -> real C -> clang -> literal stdout.
 * window: authenticated native-source compiler's bounded, censored NF/layout prefix.
 * emit: existing source-compiler image -> complete C only; execution explicitly unverified.
 * complete: existing source-compiler image -> complete C -> clang -> literal stdout.
 * --mode=oracle|emit|window|complete --source=FIXTURE.bend --out=FRESH_DIR
 * emit/window/complete: --image=COMPILER.mjs --node=NODE
 * window: --binding=NATIVE_BINDING.json --manifest=TRACE_MANIFEST.json [--window-ms=1000]
 * [--host=HOST.ts] [--repository=REPO] [--base=EXACT_PRELUDE.bend] [--source-tag=SourceFile] [--samples=1] [--budget-ms=20000]
 */
import {createHash} from 'node:crypto';
import {existsSync,mkdirSync,readFileSync,writeFileSync} from 'node:fs';
import {resolve,join,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {runHeavyGate} from './heavy_gate.ts';

const values=new Map<string,string>();
for(const argument of process.argv.slice(2)){
 const at=argument.indexOf('='),key=argument.slice(0,at),value=argument.slice(at+1);
 if(at<0||!['--mode','--image','--node','--source','--out','--host','--repository','--samples','--budget-ms','--binding','--manifest','--window-ms','--base','--source-tag'].includes(key)||!value||values.has(key))throw Error('Expected unique documented --option=value');
 values.set(key,value);
}
const mode=values.get('--mode')??'complete';
if(!['oracle','emit','window','complete'].includes(mode))throw Error('mode must be oracle, emit, window or complete');
for(const key of ['--source','--out',...(mode==='oracle'?[]:['--image','--node']),...(mode==='window'?['--binding','--manifest']:[])])if(!values.has(key))throw Error('Missing '+key);
if(mode!=='window'&&['--binding','--manifest','--window-ms'].some(key=>values.has(key)))throw Error('Trace options require window mode');
if(mode==='oracle'&&(values.has('--base')||values.has('--source-tag')))throw Error('Canonical oracle always uses unmodified full Base and canonical source loading');
const repository=resolve(values.get('--repository')??join(dirname(fileURLToPath(import.meta.url)),'..'));
const image=mode==='oracle'?undefined:resolve(values.get('--image')!),node=mode==='oracle'?process.execPath:resolve(values.get('--node')!);
const source=resolve(values.get('--source')!),out=resolve(values.get('--out')!);
const host=resolve(values.get('--host')??join(repository,'evals/candidate_host.ts'));
const basePath=resolve(values.get('--base')??join(repository,'bend2/base.bend'));
const samples=Number(values.get('--samples')??1),budgetMs=Number(values.get('--budget-ms')??20000),windowMs=Number(values.get('--window-ms')??1000);
if(!Number.isSafeInteger(windowMs)||windowMs<1||windowMs>120000)throw Error('window-ms must be 1..120000');
if(!Number.isSafeInteger(samples)||samples<1||samples>10)throw Error('samples must be 1..10');
if(!Number.isSafeInteger(budgetMs)||budgetMs<1||budgetMs>60000)throw Error('fast benchmark budget must be 1..60000ms, not the final qualification deadline');
if(existsSync(out))throw Error('Use a fresh output directory: '+out);
const fixture=readFileSync(source,'utf8'),expected=fixture.split('\n').filter(line=>line.startsWith('#|')).map(line=>line.slice(2)).join('\n');
if(!fixture.split('\n').some(line=>line.startsWith('#|')))throw Error('Representative fixture must declare literal expected stdout');
const hash=(path:string)=>createHash('sha256').update(readFileSync(path)).digest('hex');
const pinPaths=[fileURLToPath(import.meta.url),source,node,basePath,...['print.c','print.js'].map(path=>join(repository,'bend2/effs',path)),...(mode==='oracle'
 ?['bend2/main.ts','bend2/bend.ts','bend2/comp.ts'].map(path=>join(repository,path))
 :[image!,host,join(repository,'evals/candidate_consumer_worker.mjs'),join(repository,'bend2/selfhost/c_runtime.c')]),
 ...(mode==='window'?['--binding','--manifest'].map(key=>resolve(values.get(key)!)):[])];
const pins=Object.fromEntries(pinPaths.map(path=>[path,hash(path)]));
mkdirSync(out,{recursive:true});
const save=(name:string,value:unknown)=>writeFileSync(join(out,name),JSON.stringify(value,null,2)+'\n',{flag:'wx'});
const rows:any[]=[],commands:{sample:number;stage:string;argv:string[]}[]=[];
const limits={memoryMiB:8192,rssMiB:8192,pollMs:10,timeoutMs:budgetMs};
const base={schemaVersion:1,kind:'representative-semantic-scheduler-performance',acceptanceEvidence:false,
 mode,source,image,repository,samples,budgetMs,windowMs:mode==='window'?windowMs:null,limits,pins,expected,
 scope:'Development surrogate only: oracle uses canonical TS; emit/window never verify generated-program execution; window includes observer overhead; complete requires real C/stdout. None replaces original/native bootstrap/fixedpoint/strict12.'};
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
  const c=join(directory,'program.c'),binary=join(directory,'program'),work=join(directory,'work-census.json');
  const argv=mode==='oracle'?[node,'--smol',join(repository,'bend2/main.ts'),source,'-o',c]
   :[node,'--experimental-strip-types',join(repository,'evals/candidate_consumer_worker.mjs'),host,
    '--candidate='+image,'--parser='+image,'--stage-profile='+join(directory,'stages'),
    ...(values.has('--source-tag')?['--source-tag='+values.get('--source-tag')!]:[]),
    ...(mode==='window'?['--stage-manifest='+resolve(values.get('--manifest')!),'--stage-receipt='+resolve(values.get('--binding')!),
     '--work-census='+work,'--work-census-binding='+resolve(values.get('--binding')!),'--work-census-ms='+windowMs]:[]),
    source,'-o',c,'--base',basePath,'--runtime-c',join(repository,'bend2/selfhost/c_runtime.c')];
  const emit=await guarded(sample,'emit',argv,directory);
  let profilePath:string|undefined,phases:any[],window:any;
  if(mode==='oracle')phases=[{name:'canonical_parse_check_emit',status:'completed',wallMs:emit.elapsedMs}];
  else{
   const emitted=JSON.parse(readFileSync(join(directory,'emit.stdout'),'utf8').trim());
   if(mode==='window'){
    const census=JSON.parse(readFileSync(work,'utf8'));
    if(!['INTENTIONAL_DIAGNOSTIC_STOP','COMPLETED'].includes(census.status)||!census.work.outcome.validPairingSoFar)throw Error('Invalid bounded work census');
    window={status:census.status,report:work,window:census.work.window,hostBoundaries:census.work.hostBoundaries,
     exactTrace:census.work.exactTrace,observerWallMs:census.workObserverWallMs};
    if(census.status==='INTENTIONAL_DIAGNOSTIC_STOP'){
     rows.push({sample,emit,window,compilationCompleted:false});
     save('sample-'+sample+'.json',{...base,status:'RUNNING',completedSamples:rows.length,rows,commands});continue;
    }
   }
   profilePath=emitted.stageProfile;
   const profile=JSON.parse(readFileSync(profilePath!,'utf8'));
   phases=profile.spans.filter((span:any)=>span.parentId===null).map((span:any)=>({name:span.name,status:span.status,wallMs:span.wallMs}));
   if(!phases.some((phase:any)=>phase.name==='emit'&&phase.status==='completed'))throw Error('Source emitter phase did not complete');
  }
  const row:any={sample,phases,emit,window,compilationCompleted:true,executionVerified:false,CSourceSha256:hash(c),CBytes:readFileSync(c).length,profile:profilePath};
  rows.push(row);
  if(mode==='emit'||mode==='window'){
   save('sample-'+sample+'.json',{...base,status:'RUNNING',completedSamples:rows.length,rows,commands});continue;
  }
  row.clang=await guarded(sample,'clang',['/usr/bin/clang','-std=c11','-O0','-ferror-limit=0','-pthread','-lm','-o',binary,c],directory);
  row.run=await guarded(sample,'run',[binary],directory);
  const observed=readFileSync(join(directory,'run.stdout'),'utf8').trimEnd();row.observed=observed;
  if(observed!==expected)throw Error('Representative executable stdout mismatch');
  row.executionVerified=true;
  save('sample-'+sample+'.json',{...base,status:'RUNNING',completedSamples:rows.length,rows,commands});
 }
 for(const [path,digest]of Object.entries(pins))if(hash(path)!==digest)throw Error('Benchmark input changed: '+path);
 const result={...base,status:mode==='window'?'REPRESENTATIVE_WINDOW_OBSERVED':mode==='emit'?'REPRESENTATIVE_C_EMITTED_EXECUTION_UNVERIFIED':'REPRESENTATIVE_PERF_PASS',rows,commands};save('outcome.json',result);
 console.log(JSON.stringify({status:result.status,acceptanceEvidence:false,mode,source,rows:rows.map(row=>({sample:row.sample,
  compilationCompleted:row.compilationCompleted,executionVerified:row.executionVerified??false,emitWallMs:row.phases?.find((phase:any)=>phase.name==='emit')?.wallMs??null,pipelineWallMs:row.emit.elapsedMs,
  windowMs:row.window?.window.elapsedMs,hostBoundaries:row.window?.hostBoundaries.observed,
  clangMs:row.clang?.elapsedMs,runMs:row.run?.elapsedMs,CBytes:row.CBytes})),out}));
}catch(error){save('outcome.json',{...base,status:'REPRESENTATIVE_PERF_FAIL',rows,commands,error:String(error)});console.error(error);process.exitCode=1;}
