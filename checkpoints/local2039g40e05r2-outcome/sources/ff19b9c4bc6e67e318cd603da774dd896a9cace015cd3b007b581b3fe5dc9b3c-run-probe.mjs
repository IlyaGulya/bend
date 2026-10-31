import assert from 'node:assert/strict';
import {readFileSync,writeFileSync,mkdirSync,existsSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {deserialize,serialize} from 'node:v8';
import {dirname,resolve,sep} from 'node:path';
import {pathToFileURL,fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
import {Worker,isMainThread,workerData} from 'node:worker_threads';
import {runHeavyGate} from '/Users/ilyagulya/Projects/My/bend/evals/heavy_gate.ts';
import {nominalBridge} from './nominal-bridge.mjs';
const home=dirname(fileURLToPath(import.meta.url)),self=fileURLToPath(import.meta.url);
const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
const hash=path=>sha(readFileSync(path));
const tag=value=>typeof value?.$==='string'?value.$.split('.').at(-1):null;
function items(value){const result=[];while(tag(value)==='Con'){result.push(value.head);value=value.tail;assert.ok(result.length<=1000000,'list cap');}assert.equal(tag(value),'Nil');return result;}
function save(path,value){writeFileSync(path,JSON.stringify(value,null,2)+'\n');}
function drive(api,run){let steps=0;while(tag(run)==='TemplateRunState'){assert.ok(++steps<=200000000,'typed step budget');run=api.template_step(run);}assert.equal(tag(run),'TemplateRunFinished');return{value:run.box.value,steps};}
function blocks(root){const result=[],stack=[root];while(stack.length){const b=stack.pop();assert.ok(result.length<4000000);result.push(b);switch(tag(b)){case'Let':stack.push(b.next);break;case'Branch':stack.push(b.no,b.yes);break;case'Region':stack.push(b.next,b.body);break;case'Return':case'TailDirect':case'TailApply':case'Failure':case'LeaveRegion':break;default:throw Error('unknown block '+tag(b));}}return result;}
function highId(program){let high=0,n=0;const stack=[program],seen=new WeakSet();while(stack.length){const value=stack.pop();if(!value||typeof value!=='object'||seen.has(value))continue;seen.add(value);assert.ok(++n<=16000000);for(const [key,child]of Object.entries(value)){if(['id','identity','slot','label','code','constructor','field'].includes(key)&&typeof child==='number')high=Math.max(high,child);else if(child&&typeof child==='object')stack.push(child);}}return high;}
function codeMap(program){return new Map(items(program.codes).map(code=>[code.id,code]));}
function renamedOperation(value,environment){
 const holder={},stack=[{value,parent:holder,key:'value'}];let count=0;
 while(stack.length){const job=stack.pop(),current=job.value;assert.ok(++count<=4000000);if(!current||typeof current!=='object'){job.parent[job.key]=current;continue;}
  if(tag(current)==='Local'){assert.ok(environment.has(current.id),'producer frame binding');job.parent[job.key]={$:current.$,id:environment.get(current.id)};continue;}
  const output={};job.parent[job.key]=output;for(const [key,child]of Object.entries(current))stack.push({value:child,parent:output,key});
 }return holder.value;
}
function inspectProofs(inspection){
 const original=codeMap(inspection.original),optimized=codeMap(inspection.optimized),proofs=items(inspection.proofs),high=highId(inspection.original),newIds=new Set();
 for(const code of optimized.values())if(!original.has(code.id)){
  for(const id of [code.id,...items(code.parameters).map(p=>p.id),...blocks(code.body).filter(b=>tag(b)==='Let').map(b=>b.id)]){assert.ok(id>high,'global freshness');assert.ok(!newIds.has(id),'new global ID collision');newIds.add(id);}
 }
 for(const proof of proofs){
  const p=original.get(proof.producer),k=original.get(proof.consumer),worker=optimized.get(proof.worker),continuation=optimized.get(proof.continuation);assert.ok(p&&k&&worker&&continuation);
  const old=blocks(p.body),fresh=blocks(worker.body),last=old.at(-2);assert.equal(tag(last?.op),'Construct');assert.equal(last.op.constructor,proof.constructor);
  const oldPrefix=old.filter(b=>tag(b)==='Let'&&b!==last),newPrefix=fresh.filter(b=>tag(b)==='Let');assert.equal(newPrefix.length,oldPrefix.length,'strict let count');
  assert.deepEqual(newPrefix.map(b=>[tag(b.op),tag(b.op.primitive)]),oldPrefix.map(b=>[tag(b.op),tag(b.op.primitive)]),'strict operation ordering');
  const environment=new Map(items(p.parameters).map((parameter,index)=>[parameter.id,items(worker.parameters)[index].id]));
  for(let i=0;i<oldPrefix.length;i++){assert.deepEqual(newPrefix[i].op,renamedOperation(oldPrefix[i].op,environment),'strict operation operands and descriptors');environment.set(oldPrefix[i].id,newPrefix[i].id);}
  assert.equal(tag(fresh.at(-1)),'TailDirect');assert.equal(fresh.at(-1).code,proof.continuation);
  assert.equal(items(worker.captures).length,0);assert.equal(items(continuation.captures).length,0);
  const retained=items(k.parameters).filter(p=>p.id!==proof.record),fields=items(last.op.fields);
  assert.equal(items(worker.parameters).length,items(p.parameters).length+retained.length);
  assert.equal(items(continuation.parameters).length,fields.length+retained.length);
  assert.deepEqual(items(continuation.parameters).map(p=>tag(p.use)),[...fields.map(f=>tag(f.use)),...retained.map(p=>tag(p.use))]);
  assert.equal(blocks(worker.body).filter(b=>tag(b.op)==='Construct').length,0,'no producer replacement aggregate');
  const shapes=body=>blocks(body).filter(b=>tag(b.op)==='Construct').map(b=>({constructor:b.op.constructor,tag:b.op.tag,fields:items(b.op.fields).map(f=>({identity:f.identity,key:f.key,use:tag(f.use)}))}));
  assert.deepEqual(shapes(continuation.body),shapes(k.body),'consumer constructs preserved without replacement aggregate');
  const owner=optimized.get(proof.owner);assert.ok(owner);assert.ok(blocks(owner.body).some(b=>tag(b)==='TailDirect'&&b.code===proof.worker),'replacement reaches worker');
 }
 if(!proofs.length)assert.deepEqual(inspection.optimized,inspection.original,'refusal must leave complete input unchanged');
 return{proofs:proofs.map(p=>({...p})),refusals:items(inspection.refusals).map(r=>({...r})),originalCodes:original.size,optimizedCodes:optimized.size,highOriginalId:high,newIds:newIds.size};
}
async function execute(options){
 const report={schemaVersion:1,status:'RUNNING',diagnosticOnly:true,compilerAccepted:false,newFixedpointClaim:false,mode:options.mode,artifact:{path:options.artifact,sha256:hash(options.artifact)},rows:[],driver:{path:self,sha256:hash(self)},started:performance.now()};
 const reportPath=resolve(options.output,'report.json');save(reportPath,report);
 try{
  const generationPath=resolve(dirname(options.artifact),'generation.json'),generation=JSON.parse(readFileSync(generationPath,'utf8'));assert.equal(generation.status,'E05_SOURCE_GENERATED');assert.equal(hash(resolve(home,'generate-probe.ts')),generation.generatorSha256);
  for(const pins of [generation.staged,generation.generatedArtifacts])for(const [path,digest]of Object.entries(pins))assert.equal(hash(path),digest,'canonical source ownership pin '+path);
  const buildPrefix=process.env.E05_BUILD_PREFIX??resolve(dirname(options.artifact),'probe-build'),buildPath=buildPrefix+'.result.json',build=JSON.parse(readFileSync(buildPath,'utf8'));
  assert.equal(build.status,'JS_GENERATED_NOT_YET_EXECUTED');assert.equal(build.guardian.status,'PASS');assert.equal(build.checksExcluded,0);assert.equal(build.outputPatches,0);assert.equal(build.artifactPath,options.artifact);assert.equal(build.artifactSha256,report.artifact.sha256);assert.equal(build.sourcePath,generation.bridge);assert.equal(build.sourceSha256,generation.bridgeSha256);
  const buildInputs=buildPrefix+'.inputs.json';for(const [path,digest]of Object.entries(JSON.parse(readFileSync(buildInputs,'utf8'))))assert.equal(hash(path),digest,'canonical component input pin '+path);
  report.canonicalBuild={path:buildPath,sha256:hash(buildPath),generation:{path:generationPath,sha256:hash(generationPath)},inputs:{path:buildInputs,sha256:hash(buildInputs)},source:generation.bridge,checksExcluded:0,outputPatches:0};
  const api=(await import(pathToFileURL(options.artifact).href)).default;for(const key of ['suite_start','schema_start','inspect_start','template_step'])assert.equal(typeof api[key],'function',key);
  const schemaRun=drive(api,api.schema_start()),bundle=schemaRun.value;assert.equal(tag(bundle),'SchemaBundle');report.schemaSteps=schemaRun.steps;
  if(options.mode==='suite'){
   const run=drive(api,api.suite_start(bundle.base.nil)),batch=run.value;assert.equal(tag(batch),'ProbeBatch');report.steps=run.steps;
   const expected={0:146,1:146,2:null,3:152,4:1,5:146,6:146,7:146,8:168,10:292,11:292,12:146,14:146};
   const accepted={0:true,1:true,2:true,6:true,10:true,11:true};
   for(const row of items(batch.cases)){
    assert.ok(Object.hasOwn(expected,row.mode));const facts=inspectProofs(row.inspection);assert.equal(facts.proofs.length,row.mode===11?2:Object.hasOwn(accepted,row.mode)?1:0,'proof count mode '+row.mode);
    if(row.mode===10){const codes=codeMap(row.inspection.optimized);assert.ok(codes.has(10)&&codes.has(20),'public originals preserved');}
    if(row.mode===0){const codes=codeMap(row.inspection.optimized);assert.ok(!codes.has(10)&&!codes.has(20),'unreferenced originals removed');}
    if(row.mode===11){assert.equal(new Set(facts.proofs.map(p=>p.worker)).size,1);assert.equal(new Set(facts.proofs.map(p=>p.continuation)).size,1);}
    if(row.mode===6)assert.equal(facts.highOriginalId,9000000);
    const executions=[];
    for(const rendered of items(row.sources)){
     const target=rendered.target?'js':'c',variant=rendered.optimized?'optimized':'original',path=resolve(options.output,`case-${row.mode}-${variant}.${target}`);assert.equal(typeof rendered.source,'string');assert.ok(!rendered.source.startsWith('ERROR:'),rendered.source);writeFileSync(path,rendered.source,{flag:'wx'});
     let command;
     if(target==='c'){
      const binary=path+'.exe',args=['-std=c11','-O1','-pthread',path,'-lm','-o',binary],build=spawnSync('/usr/bin/clang',args,{encoding:'utf8',timeout:600000,maxBuffer:4*1024*1024});assert.ifError(build.error);assert.equal(build.status,0,build.stderr);command=[binary];
     }else command=[process.execPath,'--max-old-space-size=6144','--max-semi-space-size=128',path];
     const result=spawnSync(command[0],command.slice(1),{encoding:'utf8',timeout:600000,maxBuffer:4*1024*1024});assert.ifError(result.error);assert.equal(result.signal,null,'target signal');
     if(expected[row.mode]===null){assert.notEqual(result.status,0,'strict unused failing primitive must execute');assert.equal(result.stdout,'','consumer must not run after producer failure');assert.ok(result.stderr.includes('bend: an array past the deepest block class 31'),'exact strict primitive failure');}
     else {assert.equal(result.status,0,result.stderr);assert.equal(result.stdout.trim(),String(expected[row.mode]));}
     executions.push({target,variant,source:{path,sha256:hash(path),bytes:Buffer.byteLength(rendered.source)},command,status:result.status,stdout:result.stdout,stderr:result.stderr});
    }
    assert.equal(executions.length,4);report.rows.push({mode:row.mode,expected:expected[row.mode],facts,executions});save(reportPath,report);
   }
   assert.equal(report.rows.length,13);
   // The compiled pass remains usable after the target failure case. These
   // are public typed starts on the same loaded library, never raw CPS calls.
   const again=drive(api,api.inspect_start(items(batch.cases)[0].inspection.original));assert.equal(items(again.value.proofs).length,1);report.reentrySteps=again.steps;
  }else{
   assert.equal(options.mode,'actual');const metadataPath=resolve(options.capture,'original-bir.json'),metadata=JSON.parse(readFileSync(metadataPath,'utf8')),bytes=readFileSync(metadata.snapshot);
   assert.equal(metadata.status,'captured');assert.equal(metadata.calls,1);assert.equal(metadata.image.sha256,'85aff9e534c18b4a1d6acac5f3237571dabc58f2c1a75a7ea2040f1c477ab60e');assert.equal(hash(metadata.image.path),metadata.image.sha256);assert.equal(sha(bytes),metadata.sha256);
   const census=JSON.parse(readFileSync(options.census,'utf8'));assert.equal(census.status,'PASS');assert.equal(census.image.sha256,metadata.image.sha256);assert.equal(census.output.sha256,'c33227e028d767df9a9fff75663e42eb7374919dcf8e7dff14936a98d20008fb');
   const captured=census.snapshots[resolve(home,'capture-bir.mjs')];assert.equal(captured?.sha256,metadata.sha256);assert.equal(captured.calls,1);
   for(const [path,digest]of Object.entries(census.inputPins))assert.equal(hash(path),digest,'frozen input pin '+path);
   report.captureCensus={path:options.census,sha256:hash(options.census),output:census.output,inputPinsSha256:sha(JSON.stringify(census.inputPins))};
   const schemaPath=resolve(dirname(options.artifact),'schema.json'),schema=JSON.parse(readFileSync(schemaPath,'utf8'));for(const row of [schema.bir,schema.ast,schema.witness])assert.equal(hash(row.path),row.sha256);
   const bridge=nominalBridge(schema,bundle.witnesses,bundle.base,metadata.schema),transport=bridge.importProgram(deserialize(bytes));
   report.transport={objects:transport.objects,scalars:transport.scalars,mappingSha256:bridge.mappingSha256,mappings:bridge.mappings,generic:bridge.generic,snapshot:{path:metadata.snapshot,sha256:metadata.sha256},metadata:{path:metadataPath,sha256:hash(metadataPath)},schema:{path:schemaPath,sha256:hash(schemaPath)},semantics:'typed schema reconstruction from exact R12 tags to observed compiled constructor witnesses; strings/IDs/fields preserved, no suffix retagging'};
   const run=drive(api,api.inspect_start(transport.program)),inspection=run.value;assert.equal(tag(inspection),'Inspection');const facts=inspectProofs(inspection);report.steps=run.steps;
   const declarations=items(inspection.original.declarations),resolveCode=key=>{const rows=declarations.filter(d=>tag(d)==='FunctionDeclaration'&&d.key===key);assert.equal(rows.length,1,'source-mapped declaration '+key);return rows[0].code;};
   const producer=resolveCode('../bend2/selfhost/checker_arena.metadata_write'),consumer=resolveCode('../bend2/selfhost/checker_arena.put_word.tables'),matches=facts.proofs.filter(p=>p.producer===producer&&p.consumer===consumer);assert.equal(matches.length,1,'actual Word transform proof required');
   const proof=matches[0],codes=codeMap(inspection.optimized),worker=codes.get(proof.worker),continuation=codes.get(proof.continuation),originalCodes=codeMap(inspection.original),originalK=originalCodes.get(consumer);
   assert.equal(items(worker.parameters).length,19);assert.equal(items(continuation.parameters).length,15);assert.deepEqual(items(continuation.parameters).slice(0,2).map(p=>tag(p.use)),['Affine','Affine']);
   assert.equal(blocks(worker.body).filter(b=>tag(b.op?.primitive)==='PrimArraySet').length,3);
   const before=blocks(originalK.body).filter(b=>tag(b.op)==='Construct').map(b=>({constructor:b.op.constructor,tag:b.op.tag,keys:items(b.op.fields).map(f=>f.key)})),after=blocks(continuation.body).filter(b=>tag(b.op)==='Construct').map(b=>({constructor:b.op.constructor,tag:b.op.tag,keys:items(b.op.fields).map(f=>f.key)}));assert.deepEqual(after,before,'remaining Arena/Tuple constructors preserved');assert.equal(after.length,2);
   report.actualWord={proof,producer,consumer,producerParameters:19,continuationParameters:15,retained:13,arraySets:3,constructors:after};report.facts=facts;
   const optimizedPath=resolve(options.output,'optimized-bir.v8');writeFileSync(optimizedPath,serialize(inspection.optimized),{flag:'wx'});report.optimized={path:optimizedPath,sha256:hash(optimizedPath),representation:'compiled probe BIR; nominal transport mapping recorded'};
   const repeat=drive(api,api.inspect_start(transport.program));assert.deepEqual(items(repeat.value.proofs),items(inspection.proofs),'deterministic repeated plan');report.reentrySteps=repeat.steps;
  }
  assert.equal(hash(options.artifact),report.artifact.sha256);report.status='PASS';
 }catch(error){report.status='FAIL';report.error=String(error);report.stack=error?.stack;process.exitCode=1;}
 report.elapsedMs=performance.now()-report.started;delete report.started;save(reportPath,report);console.log(JSON.stringify({status:report.status,mode:report.mode,report:reportPath,rows:report.rows.length,actualWord:report.actualWord,error:report.error}));
}
if(!isMainThread)await execute(workerData);
else if(process.argv[2]==='--worker'){
 const options=JSON.parse(process.argv[3]),worker=new Worker(new URL(import.meta.url),{workerData:options,resourceLimits:{stackSizeMb:256,maxOldGenerationSizeMb:6144,maxYoungGenerationSizeMb:128}});
 await new Promise((done,reject)=>{worker.once('error',reject);worker.once('exit',code=>code===0?done():reject(Error('probe worker exit '+code)));});
}else{
 const [mode,artifact,out,capture,census]=process.argv.slice(2);assert.ok(['suite','actual'].includes(mode)&&artifact&&out,'suite|actual ARTIFACT FRESH_OUTPUT [CAPTURE_DIRECTORY CENSUS_REPORT]');if(mode==='actual')assert.ok(capture&&census);
 const output=resolve(out);assert.ok(output.startsWith(home+sep));assert.ok(!existsSync(output),'fresh output directory required');mkdirSync(output,{recursive:true});save(resolve(output,'report.json'),{status:'STARTING',mode});
 const options={mode,artifact:resolve(artifact),output,capture:capture?resolve(capture):undefined,census:census?resolve(census):undefined},command=[process.execPath,'--experimental-strip-types','--max-old-space-size=6144','--max-semi-space-size=128',self,'--worker',JSON.stringify(options)];
 const guardian=await runHeavyGate(command,{memoryMiB:8192,rssMiB:8192,pollMs:10,timeoutMs:600000,label:'E05 canonical continuation '+mode});
 const report=JSON.parse(readFileSync(resolve(output,'report.json'),'utf8'));report.guardian=guardian;report.command=command;if(guardian.status!=='PASS'||report.status!=='PASS'){report.status='FAIL';process.exitCode=1;}save(resolve(output,'report.json'),report);
}
