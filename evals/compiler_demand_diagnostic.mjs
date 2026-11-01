#!/usr/bin/env bun
// Diagnostic only. Fresh native-produced stage1, original scheduler and Worker.
// bun evals/compiler_demand_diagnostic.mjs --node=... --native-build=...
//   --native-corpus=... --producer-report=... --producer-corpus=...
//   --repository=... --manifest=... --request-manifest=... --out=FRESH_DIR [--window-ms=80000]
import {existsSync,mkdirSync,readFileSync,realpathSync,writeFileSync} from 'node:fs';
import {dirname,join,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {authenticateNativeSeedBuild,workloadRows,hashPath} from './native_seed_runtime.mjs';
import {runHeavyGate} from './heavy_gate.ts';

const here=dirname(fileURLToPath(import.meta.url));
const limits=Object.freeze({memoryMiB:8192,rssMiB:8192,pollMs:10,timeoutMs:600000});
const load=path=>JSON.parse(readFileSync(path,'utf8'));
const pin=path=>({path:realpathSync(path),sha256:hashPath(path)});
const save=(path,value)=>writeFileSync(path,JSON.stringify(value,null,2)+'\n',{flag:'wx'});
const requireThat=(condition,message)=>{if(!condition)throw Error(message);};

// This is a derived diagnostic attestation, not a fabricated component-build
// receipt. Both raw producer reports and every runtime source byte stay pinned.
export function authenticateCensusProducer(paths){
 const evidence=Object.fromEntries(Object.entries(paths).map(([key,path])=>[key,pin(path)]));
 const build=load(evidence.nativeBuild.path),run=load(evidence.producerReport.path);
 const seed=authenticateNativeSeedBuild(evidence.nativeBuild.path,{
  root:realpathSync(build.source),corpusPath:evidence.nativeCorpus.path,limits});
 requireThat(run.status==='NATIVE_FULL_COMPILE_PASS'&&run.boundary?.outputPatches===0&&run.boundary?.checksExcluded===0,'Incomplete or patched native stage1 producer');
 requireThat(run.buildSha256===evidence.nativeBuild.sha256&&realpathSync(run.build)===evidence.nativeBuild.path,'Stage1 producer uses another native build');
 requireThat(run.corpusSha256===evidence.producerCorpus.sha256&&realpathSync(run.corpus)===evidence.producerCorpus.path,'Stage1 producer corpus drift');
 requireThat(run.guardian?.status==='PASS'&&run.guardian.reportPhase==='complete'&&run.guardian.ownedTreeStopped===true,'Stage1 producer tree is not successfully reaped');
 requireThat(run.guardian.memoryLimitBytes===8192*1024*1024&&run.guardian.rssLimitBytes===8192*1024*1024&&run.guardian.timeoutMs<=600000,'Stage1 producer resource contract changed');
 requireThat(run.threads===1&&JSON.stringify(run.exports)===JSON.stringify(seed.corpus.exports),'Stage1 producer runtime or ABI changed');
 const phases=['parse','expand','check','emit'];
 requireThat(JSON.stringify(run.phases?.map(row=>row.phase))===JSON.stringify(phases)&&JSON.stringify(run.phaseStarts?.map(row=>row.phase))===JSON.stringify(phases),'Stage1 producer lacks ordered full phases');
 const corpus=load(evidence.producerCorpus.path);
 requireThat(corpus.schemaVersion===1&&Array.isArray(corpus.files)&&corpus.files.length>0,'Missing stage1 source corpus');
 const loadedInputs={};
 for(const row of corpus.files){
  const path=realpathSync(resolve(corpus.directory,row.path));
  requireThat(hashPath(path)===row.sha256,'Stage1 runtime source drift: '+path);
  loadedInputs[path]=row.sha256;
 }
 const sources=corpus.files.filter(row=>row.external!==true).length;
 requireThat(run.fuel?.length===sources&&run.fuel.every(row=>row.cells===8000000),'Stage1 parser fuel coverage changed');
 const artifact=pin(run.output);
 requireThat(artifact.sha256===run.outputSha256&&readFileSync(artifact.path).length===run.outputBytes&&run.result?.modules===sources&&run.result?.bytes===run.outputBytes,'Stage1 output or complete result drift');
 requireThat(run.command?.[0]===seed.binary&&run.command.includes('compile')&&run.command.includes(artifact.path),'Missing native stage1 producer command');
 return {schemaVersion:1,kind:'authenticated-native-stage1-census-binding',acceptanceEvidence:false,
  byteFixedpointClaim:false,artifactPath:artifact.path,artifactSha256:artifact.sha256,tagEncoding:null,
  loadedInputs,evidence,producer:{binarySha256:seed.binarySha256,sourceRoot:realpathSync(resolve(corpus.directory,corpus.root)),exports:run.exports},
  note:'Runtime source hashes authenticated against the successful native producer; not TS-generated root.js and not compiler acceptance.'};
}
export function authenticateCensusBinding(path){
 const binding=load(path);
 requireThat(binding.kind==='authenticated-native-stage1-census-binding','Wrong work census binding kind');
 const verified=authenticateCensusProducer(Object.fromEntries(Object.entries(binding.evidence??{}).map(([key,row])=>[key,row.path])));
 requireThat(JSON.stringify(binding)===JSON.stringify(verified),'Work census binding or raw producer evidence drift');
 return verified;
}

async function main(){
 const values=new Map();
 for(const argument of process.argv.slice(2)){
  const at=argument.indexOf('='),key=argument.slice(0,at),value=argument.slice(at+1);
  requireThat(at>0&&['--node','--native-build','--native-corpus','--producer-report','--producer-corpus','--repository','--manifest','--request-manifest','--out','--window-ms'].includes(key)&&value&&!values.has(key),'Expected unique documented --option=value');
  values.set(key,value);
 }
 for(const key of ['--node','--native-build','--native-corpus','--producer-report','--producer-corpus','--repository','--manifest','--request-manifest','--out'])requireThat(values.has(key),'Missing '+key);
 const windowMs=Number(values.get('--window-ms')??80000);
 requireThat(Number.isSafeInteger(windowMs)&&windowMs>=1&&windowMs<=120000,'Diagnostic emit window must be 1..120000 ms');
 const output=resolve(values.get('--out'));
 requireThat(!existsSync(output),'Use a fresh diagnostic output directory');
 const binding=authenticateCensusProducer({nativeBuild:values.get('--native-build'),nativeCorpus:values.get('--native-corpus'),producerReport:values.get('--producer-report'),producerCorpus:values.get('--producer-corpus')});
 const repository=realpathSync(values.get('--repository')),node=realpathSync(values.get('--node'));
 const fixture=join(repository,'evals/scheduler_chunk_smoke.bend');
 requireThat(hashPath(fixture)==='21986a939adccc86c6580c446242be9feb95703c6eeb820ef939d961f2247140','Original scheduler source drift');
 requireThat(hashPath(join(repository,'checkpoints/checker_core_steps_v1.bend'))==='e4c1197d63129394551d5643ef2934be84af82eaeacfa3da1e4e660c6ff603a4','Original scheduler checker source drift');
 const workloads=['js','c'].map(target=>workloadRows(fixture,target));
 const closure=new Map(workloads.flatMap(work=>[...work.sources,...work.externals]).map(row=>[row.file,row.sha256]));
 const inputPins=[...closure].map(([path,sha256])=>({path,sha256}));
 const runtime=join(repository,'bend2/selfhost/c_runtime.c');
 const queryMode=Array.isArray(load(values.get('--manifest')).trace?.queryCaptures);
 const observedPins=[node,runtime,values.get('--manifest'),values.get('--request-manifest'),fileURLToPath(import.meta.url),
  ...['candidate_consumer_worker.mjs','candidate_host.ts','checker_core_step_runtime.mjs','compiler_stage_profile.mjs','compiler_profile.mjs','selfhost_cpu_profile.mjs','compiler_work_census.mjs','compiler_demand_census.mjs',...(queryMode?['compiler_query_census.mjs']:[]),'heavy_gate.ts','heavy_gate_native.c'].map(name=>join(here,name))].map(pin);
 mkdirSync(output);
 const bindingPath=join(output,'image-binding.json'),workPath=join(output,'work-census.json');
 save(bindingPath,binding);
 const command=[node,'--experimental-strip-types',join(here,'candidate_consumer_worker.mjs'),join(here,'candidate_host.ts'),
  '--candidate='+binding.artifactPath,'--parser='+binding.artifactPath,
  '--stage-profile='+join(output,'stages'),'--stage-manifest='+realpathSync(values.get('--manifest')),'--stage-manifest='+realpathSync(values.get('--request-manifest')),'--stage-receipt='+bindingPath,
  '--work-census='+workPath,'--work-census-binding='+bindingPath,'--work-census-ms='+windowMs,
  fixture,'-o',join(output,'scheduler_chunk_smoke.c'),'--base',join(repository,'bend2/base.bend'),'--runtime-c',runtime];
 const stdout=join(output,'emit.stdout'),stderr=join(output,'emit.stderr');
 const guarded=['/bin/sh','-c','out=$1; err=$2; shift 2; exec "$@" >"$out" 2>"$err"','sh',stdout,stderr,...command];
 save(join(output,'diagnostic.json'),{schemaVersion:1,kind:queryMode?'compiler-semantic-query-census':'compiler-demand-work-census',acceptanceEvidence:false,byteFixedpointClaim:false,startedAt:new Date().toISOString(),command,limits,windowMs,abiExports:13,parserFuelCellsPerModule:8000000,quantum:64,inputPins,observedPins,bindingSha256:hashPath(bindingPath)});
 const guard=await runHeavyGate(guarded,{...limits,label:'original scheduler demand diagnostic'});
 save(join(output,'guard.json'),guard);
 for(const row of [...inputPins,...observedPins])requireThat(hashPath(row.path)===row.sha256,'Diagnostic input changed: '+row.path);
 const report=existsSync(workPath)?load(workPath):null;
 const intentional=report?.status==='INTENTIONAL_DIAGNOSTIC_STOP'&&guard.commandExitCode===0;
 const observed=guard.reportPhase==='complete'&&guard.ownedTreeStopped===true&&report!==null&&(!queryMode||report.queries!==undefined)&&(intentional||guard.status==='PASS');
 save(join(output,'outcome.json'),{schemaVersion:1,acceptanceEvidence:false,byteFixedpointClaim:false,status:observed?'DIAGNOSTIC_OBSERVED':'DIAGNOSTIC_FAILED',intentionalStop:intentional,guard,report:workPath,sourceClosureUnchanged:true,endedAt:new Date().toISOString()});
 console.log(JSON.stringify({status:observed?'DIAGNOSTIC_OBSERVED':'DIAGNOSTIC_FAILED',output,guard:guard.status,intentionalStop:intentional,report:workPath}));
 process.exitCode=observed?0:1;
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url))await main();
