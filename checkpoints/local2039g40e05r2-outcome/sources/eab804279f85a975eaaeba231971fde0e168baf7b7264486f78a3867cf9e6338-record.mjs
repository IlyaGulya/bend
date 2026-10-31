#!/usr/bin/env node
import {pathToFileURL,fileURLToPath} from 'node:url';
import {assert,readFileSync,existsSync,resolve,relative,dirname,basename,realpathSync,sha,hash,json,pin,save,put,fresh,rel,within,file,git,commit,blob,config,limits,guardian,sourceKind,rejectEmitted,compact,verifyPin,ABI} from './common.mjs';
const {path:configPath,value:c}=config('record');
assert.equal(c.schemaVersion,1);assert.ok(['G37E06','G38E10','G39E12','G40E05R2'].includes(c.sourceVersion));assert.ok(['rejected','accepted'].includes(c.decision));assert.ok(typeof c.reason==='string'&&c.reason.length>0);
assert.equal(c.sourceInventoryComplete,true,'Parent must declare every new regression/throwaway SOURCE input');assert.equal(c.evidenceInventoryComplete,true,'Parent must include every successful/failed preflight and legacy setup report');
const repo=realpathSync(c.repo),out=resolve(c.out),g24=resolve(c.g24Out),authored=commit(repo,c.authoredCommit),planPath=resolve(c.plan),plan=json(planPath);
const destination=rel(c.destination);assert.ok(destination.startsWith('checkpoints/'));assert.ok(!existsSync(resolve(repo,destination)),'Destination must be fresh; historical inputs are immutable');
limits(plan.limits);assert.equal(plan.parserFuel,8000000);assert.equal(plan.quantum,64);assert.deepEqual(plan.worker,{stackMiB:256,oldMiB:6144,youngMiB:128});
const command=plan.fullCommand;assert.ok(Array.isArray(command));assert.ok(command.includes('--phase=all')&&command.includes('--fail-fast-performance=true'));assert.ok(command.includes('--out='+g24),'Final out does not match predeclared command');
const runPath=resolve(g24,'receipt.json'),run=json(runPath);assert.ok(['FAIL','G24_QUALIFICATION_PASS'].includes(run.status),'Final settled g24 receipt required');assert.equal(resolve(run.repository),repo);assert.equal(resolve(run.out),g24);assert.equal(run.phase,'all');limits(run.limits);assert.deepEqual(run.abi,ABI);assert.equal(run.parserFuel,8000000);assert.equal(run.quantum,64);assert.ok(Number.isFinite(run.finished),'Unfinished g24 receipt');
for(const [p,h] of Object.entries(plan.sourcePins)){assert.equal(hash(resolve(repo,p)),h,'Source changed since declaration: '+p);assert.equal(sha(blob(repo,authored,rel(p))??Buffer.alloc(0)),h,'Authored commit does not own plan source: '+p);}
const evidence=[],sources=[],seen=new Set(),pending=new Map(),authoredCallers=new Map();
function report(p,required=false){p=resolve(p);if(!existsSync(p)){assert.ok(!required,'Missing report '+p);return null;}const data=json(p);evidence.push({pin:pin(p),data:compact(data)});return data;}
function add(p,h,kind='source',logical){p=resolve(repo,p);sourceKind(p,kind);const bytes=file(p),digest=sha(bytes);if(authoredCallers.has(p))assert.equal(digest,authoredCallers.get(p),'Executed caller source pin');else rejectEmitted(p);if(h)assert.equal(digest,h,'Source pin changed: '+p);logical=logical??(p.startsWith(repo+'/')?relative(repo,p):basename(p));rel(logical);const key=p+'\0'+digest;if(seen.has(key))return;seen.add(key);sources.push({path:p,logicalPath:logical,sha256:digest,bytes:bytes.length,kind});pending.set(key,bytes);}
function provenance(p){const v=report(p,true);assert.ok(v.loadedInputs&&v.protectedPins,'Canonical provenance requires loadedInputs and protectedPins');for(const [p,h] of Object.entries({...v.loadedInputs,...v.protectedPins}))add(p,h);return v;}
function build(p){const v=report(p);if(!v)return null;if(v.provenancePath){const {provenanceSha256,...payload}=json(v.provenancePath);assert.equal(sha(JSON.stringify(payload)),provenanceSha256,'Provenance payload self-digest');assert.equal(provenanceSha256,v.provenanceSha256,'Build/provenance binding');provenance(v.provenancePath);}if(v.sourcePath)add(v.sourcePath,v.sourceSha256);return v;}
for(const [p,h] of Object.entries(plan.sourcePins))add(p,h);
const root=build(resolve(g24,'root-build.result.json')),native=report(resolve(g24,'root-native-build.json')),boot=report(resolve(g24,'bootstrap.json'));
const corpusPath=resolve(g24,'root.native.corpus.json');if(existsSync(corpusPath)){const corpus=json(corpusPath);add(corpusPath,undefined,'manifest');assert.deepEqual(corpus.exports,ABI);for(const f of corpus.files)add(resolve(corpus.directory,f.path),f.sha256,'source',rel(f.path));}
const cp=resolve(repo,'checkpoints');
// These are g24's actual generated SOURCE names, not emitted compiler images.
for(const [p,kind] of [[resolve(cp,'.bootstrap_compiler_root_'+run.runId+'.bend'),'source'],[resolve(cp,'.bootstrap_parser_rebuild_'+run.runId+'_source.bend'),'source'],[resolve(cp,'.bootstrap_parser_rebuild_'+run.runId+'_generated_fuel.bend'),'source'],[resolve(cp,'selfhost-root-'+run.runId+'.json'),'manifest'],...['checker_core_steps_v1.bend','template_steps_v1.bend','emitter_steps_v1.bend'].map(x=>[resolve(cp,x),'source']),...['checker-core-owned-source-v1.json','checker-core-steps-v1.json','emitter-steps-v1.json'].map(x=>[resolve(cp,x),'manifest'])])if(existsSync(p))add(p,undefined,kind);
// Follow SOURCE edges in composition metadata, not report/image/AST edges.
function sourceEdges(v){
 if(!v||typeof v!=='object')return;
 if(Array.isArray(v)){for(const x of v)sourceEdges(x);return;}
 if(v.jsCaller&&typeof v.jsCaller.path==='string'&&/^[a-f0-9]{64}$/.test(v.jsCaller.sha256??''))authoredCallers.set(resolve(v.jsCaller.path),v.jsCaller.sha256);
 for(const [key,digestKey] of [['canonical','canonicalSha256'],['source','sourceSha256'],['driver','driverSha256'],['slice','sliceSha256'],['owned','sourceSha256']]){
  if(typeof v[key]==='string'&&/\.(bend|ts|c|h|md)$/.test(v[key])&&/^[a-f0-9]{64}$/.test(v[digestKey]??''))add(v[key],v[digestKey]);
 }
 for(const [k,x] of Object.entries(v)){
  if(/^[a-f0-9]{64}$/.test(typeof x==='string'?x:'')&&(/\/[^/]+\.(bend|ts|c|h|md)$/.test(k)||/\/bend2\/effs\/[^/]+\.js$/.test(k)))add(k,x);
  else if(x&&typeof x==='object')sourceEdges(x);
 }
}
for(const s of [...sources].filter(x=>x.kind==='manifest'))sourceEdges(json(s.path));
const bindingsArg=command.find(x=>x.startsWith('--bindings=')),frozenArg=command.find(x=>x.startsWith('--frozen-repository='));
assert.ok(bindingsArg&&frozenArg);const bindingPath=resolve(bindingsArg.slice('--bindings='.length)),binding=json(bindingPath),frozenRepo=resolve(frozenArg.slice('--frozen-repository='.length));add(bindingPath,undefined,'manifest');
for(const [p,h] of Object.entries(binding.frozenInputs)){add(p,h,'source',within(frozenRepo,p));}
assert.ok(Array.isArray(c.preflightReports)&&Array.isArray(c.legacyReports)&&Array.isArray(c.sources),'Explicit report/source arrays required (empty allowed)');
for(const item of [...c.preflightReports,...c.legacyReports]){
 assert.ok(item.classification);const p=resolve(item.path),v=report(p,true);if(v.sourceCommit)assert.equal(commit(repo,v.sourceCommit),authored);evidence.at(-1).classification=item.classification;sourceEdges(v);
 if(typeof v.build==='string'&&v.build.endsWith('.result.json'))build(v.build);
 if(typeof v.rootManifest==='string'){add(v.rootManifest,undefined,'manifest');sourceEdges(json(v.rootManifest));}
 for(const s of v.sourceInventory??[]){assert.equal(s.sourceOnly,true);assert.ok(s.purpose);assert.match(s.sha256,/^[a-f0-9]{64}$/);add(s.path,s.sha256,s.kind,s.logicalPath);}
}
for(const p of c.provenances??[])provenance(resolve(p));
for(const s of c.sources){assert.match(s.sha256,/^[a-f0-9]{64}$/);assert.ok(s.purpose);assert.equal(s.sourceOnly,true,'Declare SOURCE-only input, never emitted image');add(s.path,s.sha256,s.kind,s.logicalPath);}
for(const p of ['record.mjs','restore.mjs','common.mjs'])add(resolve(dirname(fileURLToPath(import.meta.url)),p),undefined,'tooling','version-outcomes/'+p);
const progressPath=resolve(g24,'logs/native-build.stderr');let progress=[];
if(existsSync(progressPath)){progress=[...readFileSync(progressPath,'utf8').matchAll(/^NATIVE_BUILD_PROGRESS (\{[^\n]+\})$/gm)].map(x=>JSON.parse(x[1])).filter(x=>['book_valid','compile_book','guardian'].includes(x.phase));}
const nativeBuilt=native?.status==='NATIVE_EXECUTABLE_BUILT_NOT_YET_RUN';
if(nativeBuilt){guardian(native.guardian);assert.equal(native.checkedDefinitions,native.expectedSourceDefinitions);assert.ok(native.checkedDefinitions>0);assert.equal(native.checksExcluded,0);assert.equal(native.outputPatches,0);verifyPin({path:native.artifact,sha256:native.artifactSha256});}
let byteFixedpoint=false;
if(boot?.status==='NATIVE_SEED_BOOTSTRAP_FIXEDPOINT'&&boot.passed===true&&boot.compilerBootstrapGreen===true){assert.ok(nativeBuilt);guardian(boot.guardian);assert.equal(boot.seedMode,'native');assert.equal(boot.boundary.checksExcluded,0);assert.equal(boot.boundary.outputPatches,0);assert.equal(boot.fixedpoint.equal,true);for(const stage of [boot.artifacts.stageOne,boot.artifacts.stageTwo])verifyPin(stage);assert.equal(boot.artifacts.stageOne.sha256,boot.artifacts.stageTwo.sha256);assert.equal(boot.nativeRun.binarySha256,native.artifactSha256);byteFixedpoint=true;}
const rows=run.throughput?.runs??[];const paired=[];
for(const row of rows){verifyPin(row.report);const detail=json(row.report.path);paired.push({report:row.report,data:compact(detail)});}
// runThroughput returns its rows only at the end; a failure can leave actual
// sample reports without receipt.throughput. Retain those, without synthesizing
// successful rows or treating the partial lane as measured/accepted.
for(const mode of ['native','js'])for(const [role,repetition] of [['control',1],['candidate',1],['candidate',2],['control',2],['control',3],['candidate',3]]){
 const p=resolve(g24,'throughput',`${mode}-${role}-${repetition}.json`);
 if(existsSync(p)&&!paired.some(x=>resolve(x.report.path)===p))paired.push({report:pin(p),data:compact(json(p)),mode,role,repetition,notPublishedInFinalRuns:true});
}
// Reuse the original gate's pure decision function: no second acceptance convention.
const {performanceDecision}=await import(pathToFileURL(resolve(repo,'evals/g24_qualification.mjs')).href);
const decision=performanceDecision(run.throughput);
if(run.performanceDecision)assert.deepEqual(decision,run.performanceDecision,'Original paired decision drift');
if(c.decision==='accepted'){
 assert.equal(run.status,'G24_QUALIFICATION_PASS');assert.equal(run.correctnessPassed,true);assert.equal(run.throughputMeasured,true);assert.equal(run.failure,null);assert.ok(byteFixedpoint&&nativeBuilt);assert.equal(rows.length,12);assert.equal(decision.passed,true);
 for(const row of rows){guardian(row.guardian);const detail=json(row.report.path);assert.equal(detail.status,'PASS');guardian(detail.guardian);}
 assert.ok(root);assert.equal(root.status,'JS_GENERATED_NOT_YET_EXECUTED');guardian(root.guardian);assert.equal(root.checksExcluded,0);assert.equal(root.outputPatches,0);assert.equal(root.checkedDefinitions,root.expectedSourceDefinitions);
 assert.ok(run.steps.length&&run.steps.every(x=>x.status==='PASS'),'All original consumer steps must pass');
}
// Resolve sources against immutable Git bytes first, then explicitly supplied frozen
// authorities, then new content-addressed SOURCE copies. Never copy an image.
const authorities=[authored,...(c.authorityCommits??['6e6debc2']).map(x=>commit(repo,x))];
const frozen=(c.existingFrozen??[]).map(x=>{rel(x.path);sourceKind(x.path,x.kind??'source');const b=blob(repo,commit(repo,x.commit),x.path);assert.ok(b,'Frozen source must already be committed');assert.equal(sha(b),x.sha256);return {...x,commit:commit(repo,x.commit)};});
const committedNames=git(repo,'ls-tree','-r','--name-only',authored,'--','checkpoints').toString().split('\n').filter(Boolean);
for(const p of committedNames){const m=/(?:^|\/)([a-f0-9]{64})-[^/]+\.(?:bend|ts|mjs|js|c|h|md|json)$/.exec(p);if(m&&sources.some(s=>s.sha256===m[1])&&!frozen.some(x=>x.sha256===m[1])){const b=blob(repo,authored,p);if(b&&sha(b)===m[1])frozen.push({commit:authored,path:p,sha256:m[1]});}}
const installs=[],commitFiles=[],newFiles=new Map();
for(const s of sources){let authority;for(const co of authorities){const b=blob(repo,co,s.logicalPath);if(b&&sha(b)===s.sha256){authority={gitCommit:co,path:s.logicalPath,sha256:s.sha256};break;}}
 if(!authority){const prior=frozen.find(x=>x.sha256===s.sha256);if(prior)authority={gitCommit:prior.commit,path:prior.path,sha256:s.sha256};}
 if(!authority){const name=s.sha256+'-'+basename(s.logicalPath),dest=destination+'/sources/'+name;authority={checkpointSource:dest,sha256:s.sha256};if(!newFiles.has(dest))newFiles.set(dest,pending.get(s.path+'\0'+s.sha256));}
 s.authority=authority;
}
const receiptDest=destination+'/outcome.json',listDest=destination+'/commit-files.json';commitFiles.push(...newFiles.keys(),receiptDest,listDest);commitFiles.sort();
const receipt={schemaVersion:1,status:c.sourceVersion+'_'+c.decision.toUpperCase()+'_ORIGINAL_G24_OUTCOME',sourceVersion:c.sourceVersion,authoredCommit:authored,decision:{owner:'parent',value:c.decision,reason:c.reason},compilerAccepted:c.decision==='accepted',performanceAccepted:c.decision==='accepted',byteFixedpoint,completeQualification:run.status==='G24_QUALIFICATION_PASS'&&run.correctnessPassed===true,config:pin(configPath),plan:{pin:pin(planPath),data:plan},qualification:{pin:pin(runPath),data:compact(run)},nativeProgress:existsSync(progressPath)?{log:pin(progressPath),observations:progress,checkedCountAuthority:'Only actual book_valid observations; absent top-level build counts remain absent'}:null,nativeExecutableBuilt:nativeBuilt,rootJSIsNativeStageOne:false,evidence,pairedReports:paired,originalPairedRows:rows,originalPerformanceDecision:run.performanceDecision??null,recomputedOriginalDecision:decision,sourceInputs:sources,commitFiles,checkpointRequiredBeforeRestoreOrNextVersion:true,legacyFailurePolicy:'Retained as failures, never semantic passes; no retries or replaced measurements'};
assert.ok(Buffer.byteLength(JSON.stringify(receipt))<=4*1024*1024,'Compact receipt exceeds 4MiB; no truncation or success claim');
fresh(out);for(const [dest,b] of newFiles){const staged=resolve(out,'files',dest);put(staged,b);installs.push({source:staged,destination:dest,sha256:sha(b)});}
for(const [dest,value] of [[receiptDest,receipt],[listDest,commitFiles]]){const staged=resolve(out,'files',dest);save(staged,value);installs.push({source:staged,destination:dest,sha256:hash(staged)});}
save(resolve(out,'install.json'),{schemaVersion:1,repo,sourceVersion:c.sourceVersion,authoredCommit:authored,status:'PREPARED_FOR_PARENT_INSTALL_AND_COMMIT',files:installs,commitFiles,receiptPath:receiptDest,mutation:'No Git add/commit or repository writes performed. Parent must install exact bytes and commit this allowlist before restore/next version.'});
console.log(JSON.stringify({status:receipt.status,staged:out,install:resolve(out,'install.json'),commitFiles,samples:rows.length,byteFixedpoint}));
