import assert from 'node:assert/strict';
import {resolve,basename} from 'node:path';
import {writeFileSync,realpathSync} from 'node:fs';
import {text,json,pin,hash,verify,ABI,LIMITS,guardian,runtimeProof} from './auth.mjs';
const save=(p,v)=>writeFileSync(p,JSON.stringify(v,null,2)+'\n',{flag:'wx'});
export async function scan({repo,out,node,bootstrap,requestPath,authority,pins,run,runtimeRun}){
 const b=json(bootstrap);assert.equal(b.stageOneProducer,'native stage0 executable');assert.equal(b.passed,true);assert.equal(b.status,'NATIVE_SEED_BOOTSTRAP_FIXEDPOINT');guardian(b.guardian);assert.equal(b.boundary.checksExcluded,0);assert.equal(b.boundary.outputPatches,0);assert.deepEqual(b.requiredExports,ABI);verify(b.inputs);
 for(const [k,v]of Object.entries({memoryMiB:8192,rssMiB:8192,pollMs:10,timeoutMs:600000,workerStackMiB:256,workerOldGenerationMiB:6144,workerYoungGenerationMiB:128,parserFuel:8000000,maxHeavyChildren:1}))assert.equal(b.limits[k],v,k);
 const seed=b.nativeSeed,n=json(seed.build);assert.equal(hash(seed.build),seed.buildSha256);assert.equal(hash(seed.binary),seed.binarySha256);assert.equal(n.artifactSha256,seed.binarySha256);assert.equal(n.status,'NATIVE_EXECUTABLE_BUILT_NOT_YET_RUN');guardian(n.guardian);assert.equal(n.checksExcluded,0);assert.equal(n.outputPatches,0);assert.equal(n.checkedDefinitions,n.expectedSourceDefinitions);assert.ok(n.checkedDefinitions>0);verify(n.protectedPins);verify(n.loadedInputs);
 const stage=b.artifacts.stageOne;assert.equal(stage.phase,'native-stage-zero-emit');assert.equal(hash(stage.path),stage.sha256);assert.notEqual(stage.path,authority.build.artifactPath,'canonical RootJS is not stage1');
 const generated=realpathSync(resolve(repo,authority.manifest.generationConfig.output));assert.equal(n.loadedInputs[generated],hash(generated),'native build must contain this new emitter source');
 const emittedInputs=Object.fromEntries(stage.sourceHashes.map(r=>{assert.equal(r.sha256,r.sourceBytesSha256);return [realpathSync(r.file),r.sha256];}));assert.equal(Object.keys(emittedInputs).length,53);verify(emittedInputs);assert.equal(emittedInputs[generated],hash(generated));assert.equal(hash(b.root),authority.build.sourceSha256);
 const event=b.events.filter(e=>e.event==='native-run'&&e.phase==='native-stage-zero');assert.equal(event.length,1);assert.equal(event[0].buildSha256,seed.buildSha256);assert.equal(event[0].binarySha256,seed.binarySha256);assert.equal(event[0].stageOne.sha256,stage.sha256);assert.equal(event[0].result.result,'EmitSuccess');
 const runtime=runtimeProof(text(stage.path),authority.runtime);
 const request=json(requestPath);assert.equal(request.schemaVersion,1);assert.deepEqual(request.exports,ABI);assert.deepEqual(request.limits,LIMITS);assert.equal(Object.keys(request.inputs).length,53);verify(request.inputs);verify(request.pins);assert.equal(realpathSync(request.image),realpathSync(stage.path),'genuine candidate request required, not R12 control request');assert.equal(realpathSync(request.node),node);
 for(const p of [bootstrap,seed.build,seed.binary,stage.path,requestPath,...Object.keys(emittedInputs),...Object.keys(request.inputs),...Object.keys(request.pins)])pins[realpathSync(p)]=hash(p);
 await runtimeRun('stage1-direct-protocol',stage.path,'protocol',undefined,true);
 // Original executor computes authorization on this exact workload. Never assume c332 or rewrite its request.
 const cleanRequest=resolve(out,'stage1-clean.request.json'),cleanReport=resolve(out,'stage1-clean.result.json');
 save(cleanRequest,{...request,expectedSelfhostOutput:null,pins:{...request.pins,...pins},e12Authority:{bootstrap:pin(bootstrap),originalRequest:pin(requestPath),purpose:'fresh unchanged-image execution to compute original output authorization; no acceptance claim'}});
 await run('stage1-clean-full53',[node,'--experimental-strip-types',resolve(repo,'evals/selfhost_throughput.mjs'),'--worker','js',cleanRequest,hash(cleanRequest),cleanReport]);
 const clean=json(cleanReport);assert.equal(clean.status,'PASS');assert.equal(clean.checksExcluded,0);assert.equal(clean.outputPatches,0);assert.equal(hash(clean.output.path),clean.output.sha256);assert.ok(clean.stepCounts.check>0&&clean.stepCounts.emit>0);
 // This is a newly authorized diagnostic request, not an alteration of old provenance.
 const authorized=resolve(out,'stage1-authorized.request.json');save(authorized,{...request,expectedSelfhostOutput:clean.output.sha256,pins:{...request.pins,...pins,[realpathSync(cleanRequest)]:hash(cleanRequest),[realpathSync(cleanReport)]:hash(cleanReport),[realpathSync(clean.output.path)]:hash(clean.output.path)},e12Authorization:{originalRequest:pin(requestPath),originalExecution:pin(cleanReport),actualOutput:clean.output}});
 const audit=new URL('./audit.mjs',import.meta.url).pathname,lifetime=new URL('./lifetime.mjs',import.meta.url).pathname;
 const config=resolve(out,'stage1-scan.config.json'),report=resolve(out,'stage1-scan.result.json');save(config,{request:authorized,plugins:[audit,lifetime],pins});
 await run('stage1-quiescent-full53',[node,'--experimental-strip-types','/private/tmp/bend-e01-e13-jbsb4I/census-runner.mjs','--worker',config,report]);
 const observed=json(report);assert.equal(observed.status,'PASS');assert.equal(observed.output.sha256,clean.output.sha256);assert.deepEqual(observed.stepCounts,{Template:clean.stepCounts.expand,Checker:clean.stepCounts.check,Emitter:clean.stepCounts.emit});
 const a=observed.snapshots[audit];for(const phase of ['check','emit']){const rows=a.boundaries.filter(x=>x.phase===phase);assert.equal(rows.length,1);assert.equal(rows[0].sp,0);assert.equal(rows[0].ksp,0);assert.equal(rows[0].nonnullSuffix,0,'retired argument root at '+phase);}
 assert.ok(a.counters.normal>0);verify(pins);
 return {status:'PASS',bootstrap:pin(bootstrap),nativeBuild:pin(seed.build),stageOne:pin(stage.path),runtime,request:pin(requestPath),originalExecution:pin(cleanReport),authorization:pin(authorized),scan:pin(report),audit:a,lifetime:observed.snapshots[lifetime],output:observed.output,scope:'Full frozen53 checker/emitter; removed argument suffix edge only. Not proof of global death, other-root removal, physical retained bytes, dispatch/JIT improvement or qualification.'};
}
