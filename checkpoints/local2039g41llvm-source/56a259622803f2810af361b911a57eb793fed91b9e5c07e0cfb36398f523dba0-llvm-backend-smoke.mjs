import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {readFileSync,writeFileSync,mkdirSync,existsSync,chmodSync,realpathSync} from 'node:fs';
import {resolve,join} from 'node:path';
const [repo,bun,clang,llvm,out,fixture]=process.argv.slice(2);
assert.ok(repo&&bun&&clang&&llvm&&out&&fixture);
assert.ok(!existsSync(out),'Fresh smoke output required');mkdirSync(out,{recursive:true});
const hash=p=>createHash('sha256').update(readFileSync(p)).digest('hex');
const worker=join(repo,'evals/native_compiler_llvm.ts'),publicCli=join(repo,'evals/native_compiler_experiment.ts');
const node=process.execPath,rows=[];
const save=(p,v)=>writeFileSync(p,JSON.stringify(v,null,2)+'\n');
const failureCc=join(out,'deliberate-failure-cc.mjs');
writeFileSync(failureCc,'#!'+node+'\nimport {spawnSync} from "node:child_process";\nconst a=process.argv.slice(2);\nif(a.includes("-x")&&a.some(x=>x.endsWith("/part.bc3")))process.exit(7);\nconst r=spawnSync('+JSON.stringify(clang)+',a,{stdio:"inherit"});\nif(r.error)throw r.error;process.exit(r.status??1);\n');chmodSync(failureCc,0o755);
function execute(command,cwd=repo){const start=Date.now();const r=spawnSync(command[0],command.slice(1),{cwd,encoding:'utf8',maxBuffer:8*1024*1024,timeout:650000,env:{...process.env,BUN_JSC_forceRAMSize:'4294967296',HEAVY_GATE_MEMORY_MIB:'8192',HEAVY_GATE_RSS_MIB:'8192',HEAVY_GATE_POLL_MS:'10',HEAVY_GATE_TIMEOUT_MS:'600000'}});return {command,cwd,status:r.status,signal:r.signal,error:r.error?String(r.error):null,stdout:r.stdout??'',stderr:r.stderr??'',elapsedMs:Date.now()-start};}
for(const [name,parts,cc,expectedPass] of [['parts4',4,clang,true],['parts8',8,clang,true],['failure4',4,failureCc,false]]){
 const report=join(out,name+'.json'),artifact=join(out,name),pins=Object.fromEntries([worker,fixture,...(expectedPass?[]:[failureCc])].map(p=>[realpathSync(p),hash(p)]));
 // Backend-only authored C input. This never claims canonical Bend validation,
 // a native compiler seed, a selfhost stage or full compiler qualification.
 save(report,{status:'C_GENERATED_NOT_YET_BUILT',diagnosticOnly:true,compilerAccepted:false,sourceAuthority:'Authored C linkage fixture, not a canonical native compiler build',cPath:fixture,cSha256:hash(fixture),artifact,ccOptimization:{flag:'-O1'},ccPipelineRequest:{kind:'llvm-split',partitions:parts,maxBackendChildren:3},protectedPins:pins});
 save(report+'.inputs.json',pins);
 const command=execute([bun,'--smol',worker,report,cc,llvm,String(parts)]),result=JSON.parse(readFileSync(report,'utf8'));
 const matches=[...command.stderr.matchAll(/^HEAVY_GATE (\{[^\n]+\})$/gm)],guardian=matches.length?JSON.parse(matches.at(-1)[1]):null;
 assert.ok(guardian?.ownedTreeStopped===true,'Every backend child must be reaped');
 assert.equal(result.ccPipeline.temporaryFilesRemoved,true);
 assert.equal(result.ccPipeline.partitions,parts);assert.equal(result.ccPipeline.maxBackendChildren,3);
 assert.ok(result.ccPipeline.stages.every(x=>x.status!=='RUNNING'));
 if(expectedPass){
  assert.equal(command.status,0,command.stderr);assert.equal(result.ccPipeline.status,'PASS');assert.equal(guardian.status,'PASS');
  assert.deepEqual(result.ccPipeline.partitionInputs.map(x=>x.id),Array.from({length:parts},(_,i)=>i));
  const children=result.ccPipeline.stages.filter(x=>x.name.startsWith('opt-codegen-'));assert.equal(children.length,parts);
  for(const t of [...new Set(children.flatMap(x=>[x.startedMs,x.startedMs+x.wallMs]))])assert.ok(children.filter(x=>x.startedMs<=t&&t<x.startedMs+x.wallMs).length<=3,'Backend concurrency exceeded3');
  const linked=result.ccPipeline.stages.find(x=>x.name==='link');assert.equal(linked.status,'PASS');assert.deepEqual(linked.command.slice(1,1+parts),result.ccPipeline.partitionInputs.map(x=>x.object));
  const consumer=execute([artifact]);assert.equal(consumer.status,0);assert.equal(consumer.stdout,'529\n');rows.push({name,parts,command,guardian,pipeline:result.ccPipeline,consumer});
 }else{
  assert.notEqual(command.status,0);assert.equal(result.ccPipeline.status,'FAIL');assert.ok(!existsSync(artifact));
  assert.ok(result.ccPipeline.stages.some(x=>x.name==='opt-codegen-3'&&x.status==='FAIL'));
  assert.ok(!result.ccPipeline.stages.some(x=>x.name==='link'||x.name==='opt-codegen-0'),'No replacement or link after failure');
  rows.push({name,parts,expectedFailure:true,command,guardian,pipeline:result.ccPipeline});
 }
}
const corpus=join(repo,'checkpoints/local2039g24r12/root.native.corpus.json');
const base=['--mode=build','--corpus='+corpus];
const invalid=[['zero','--cc-pipeline=llvm-split','--cc-partitions=0'],['unsupported','--cc-pipeline=llvm-split','--cc-partitions=16'],['noncanonical','--cc-pipeline=llvm-split','--cc-partitions=08'],['duplicate','--cc-pipeline=llvm-split','--cc-partitions=4','--cc-partitions=8'],['direct','--cc-pipeline=direct','--cc-partitions=8'],['optimization','--cc-pipeline=llvm-split','--cc-partitions=8','--cc-opt=3']];
const invalidRows=[];
for(const [name,...args] of invalid){const report=join(out,'invalid-'+name+'.json'),artifact=join(out,'invalid-'+name),r=execute([bun,'--smol',publicCli,...base,'--report='+report,'--artifact='+artifact,...args]);assert.notEqual(r.status,0);assert.ok(!existsSync(report)&&!existsSync(artifact)&&!existsSync(report+'.inputs.json'),'Invalid request started work');invalidRows.push({name,...r});}
save(join(out,'report.json'),{schemaVersion:1,status:'REAL_LLVM_LINKAGE_AND_FAILURE_DRAIN_SMOKE_PASS',scope:'Backend fixture and CLI boundary behavior only; not native compiler or selfhost acceptance',fixture:{path:fixture,sha256:hash(fixture)},runtime:{node,bun,clang,llvm},sources:{[worker]:hash(worker),[publicCli]:hash(publicCli),[failureCc]:hash(failureCc)},rows,invalidRows});
console.log(JSON.stringify({status:'REAL_LLVM_LINKAGE_AND_FAILURE_DRAIN_SMOKE_PASS',report:join(out,'report.json'),successfulCExecutions:2,expectedBackendFailures:1,invalidRequestsRejected:invalidRows.length}));
