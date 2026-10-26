#!/usr/bin/env bun
/** Complete behavior evidence for both unchanged images of an existing root
 * fixedpoint certificate. This is NOT the monolithic 600s bootstrap gate.
 * bun --smol evals/selfhost_emitted_suites.ts \
 *   --fixedpoint-report=checkpoints/selfhost-ir57t-bootstrap-a.json \
 *   --stage-sha256=c26cebdcf555b03605df7ae88e22c1a6a76ec9bc2ce712fbb487dfbe4ce6d832 \
 *   --stage-bytes=13739548 --report=checkpoints/selfhost-ir57t-emitted-suites-a.json
 * Source-only fixtures are freshly parsed by each image; no AST/cache inputs.
 */
import {runHeavyGate,guardHeavyGate} from './heavy_gate.ts';
import {authenticateNativeSeedBuild,requireCorpusCoversWorkload,workloadRows} from './native_seed_runtime.mjs';
import {parserParity,isolatedParserParity} from './selfhost_parser_parity.ts';
import {readAcceptedParserBuild} from './selfhost_driver_source.ts';
import {sourceFileTagForSelfhostImage,sourceFileTagFromRoot} from './checker_core_step_runtime.mjs';
import {createHash} from 'node:crypto';
import {readFileSync,writeFileSync,existsSync,mkdirSync,realpathSync} from 'node:fs';
import {resolve,dirname,join} from 'node:path';
import {pathToFileURL} from 'node:url';
import {spawn} from 'node:child_process';
import type {ChildProcess} from 'node:child_process';
import {createInterface} from 'node:readline';

const ABI=['parsed_module','parse_with_fuel','expand_modules_start','template_step','check_expanded_start','inspect_checked_start','checker_step','emit_modules_start','emit_library_start','emitter_step','emit_c_modules_start','emit_c_library_start','c_emitter_step'];
const limits={memoryMiB:8192,rssMiB:8192,pollMs:10,timeoutMs:600000,workerStackMiB:256,workerOldGenerationMiB:6144,workerYoungGenerationMiB:128,parserFuel:8000000,maxHeavyChildren:1};
const sha=(bytes:string|Uint8Array)=>createHash('sha256').update(bytes).digest('hex');
const hash=(path:string)=>sha(readFileSync(path));
function object(value:unknown):Record<string,any>{if(!value||typeof value!=='object'||Array.isArray(value))throw Error('Expected evidence object');return value as Record<string,any>;}
const json=(path:string)=>object(JSON.parse(readFileSync(path,'utf8')));
const save=(path:string,value:unknown)=>writeFileSync(path,JSON.stringify(value,(_,v)=>typeof v==='bigint'?String(v):v,2)+'\n');
const requireProof=(condition:unknown,message:string)=>{if(!condition)throw Error(message);};
const same=(left:unknown,right:unknown)=>JSON.stringify(left)===JSON.stringify(right);
const sameMap=(left:unknown,right:unknown)=>{
 const a=Object.entries(object(left)).sort(([x],[y])=>x.localeCompare(y));
 const b=Object.entries(object(right)).sort(([x],[y])=>x.localeCompare(y));
 return a.length===b.length&&a.every(([key,value],index)=>key===b[index][0]&&value===b[index][1]);
};
const options=new Map<string,string>();let worker=false;
for(const argument of process.argv.slice(2)){
 if(argument==='--worker'&&!worker){worker=true;continue;}
 const at=argument.indexOf('='),key=argument.slice(0,at),value=argument.slice(at+1);
 requireProof(at>0&&['--fixedpoint-report','--stage-sha256','--stage-bytes','--report'].includes(key)&&value&&!options.has(key),'Expected unique --fixedpoint-report=PATH --stage-sha256=SHA256 --stage-bytes=COUNT --report=FRESH.json');options.set(key,value);
}
requireProof(options.size===4,'Both reports and independently observed stage fingerprint are required');
const fixedpointReport=resolve(options.get('--fixedpoint-report')!),report=resolve(options.get('--report')!),sidecars=report+'.cases';
const stageSha256=options.get('--stage-sha256')!,stageBytes=Number(options.get('--stage-bytes'));
requireProof(/^[0-9a-f]{64}$/.test(stageSha256)&&Number.isSafeInteger(stageBytes)&&stageBytes>0,'Expected exact SHA256 and positive stage byte count');
const criterion='Authenticated root byte fixedpoint and original 95 seed results plus 95 freshly executed fixtures on EACH unchanged emitted image. Separate behavior proof, not aggregate bootstrap/speed acceptance.';
if(!worker){
 requireProof(!existsSync(report)&&!existsSync(sidecars),'Use fresh report and sidecar paths');mkdirSync(dirname(report),{recursive:true});
 save(report,{status:'IN_PROGRESS',passed:false,criterion,limits,monolithicBootstrapAcceptance:false,selfhostGreen:false});
 const guardian=await runHeavyGate([process.execPath,'--smol',import.meta.path,...process.argv.slice(2),'--worker'],{label:'Both unchanged emitted compiler semantic suites',...limits});
 const result=json(report),passed=result.passed===true&&guardian.status==='PASS';
 save(report,{...result,guardian,passed,status:passed?'EMITTED_SUITES_BEHAVIOR_PASS':'FAIL',monolithicBootstrapAcceptance:false,selfhostGreen:false});
 if(!passed)process.exitCode=2;
}else{
 await guardHeavyGate(import.meta.path,{label:'Both unchanged emitted compiler semantic suites'});
 mkdirSync(sidecars,{recursive:true});
 const inputs:Record<string,string>={},stages:Record<string,any>[]=[],state:Record<string,any>={status:'IN_PROGRESS',passed:false,criterion,limits,requiredExports:ABI,fixedpointReport,expectedStage:{sha256:stageSha256,bytes:stageBytes},inputs,stages,monolithicBootstrapAcceptance:false,selfhostGreen:false};
 const flush=()=>save(report,state);
 let child:ChildProcess|undefined,phase='authentication';
 const pin=(path:string,digest:string)=>{requireProof(typeof digest==='string'&&/^[0-9a-f]{64}$/.test(digest)&&realpathSync(path)===path&&hash(path)===digest&&(!inputs[path]||inputs[path]===digest),'Input/proof drift: '+path);inputs[path]=digest;};
 const rehash=()=>{for(const [path,digest]of Object.entries(inputs))pin(path,digest);};
 try{
  pin(fixedpointReport,hash(fixedpointReport));pin(import.meta.path,hash(import.meta.path));
  const snapshot=join(sidecars,'selfhost_emitted_suites.ts');writeFileSync(snapshot,readFileSync(import.meta.path),{flag:'wx'});pin(snapshot,inputs[import.meta.path]);state.runnerSnapshot={path:snapshot,sha256:inputs[snapshot]};
  const original=json(fixedpointReport),requestPath=join(fixedpointReport+'.cases','request.json');pin(requestPath,hash(requestPath));
  const request=json(requestPath);
  const nativeMode=original.status==='NATIVE_SEED_BOOTSTRAP_FIXEDPOINT';
  let one:any,two:any,fixtures:any,sourceFileTag:string;
  if(nativeMode){
   requireProof(request.report===fixedpointReport&&request.sidecars===fixedpointReport+'.cases'&&request.worker===true&&!request.fixture&&!request.parseOnly&&!request.profileRoot,'Original request is not a full bootstrap request');
   requireProof(original.passed===true&&original.seedMode==='native'&&original.guardian?.status==='PASS'&&original.guardian.timeoutMs===600000&&original.guardian.memoryLimitBytes===8192*1024*1024&&original.guardian.rssLimitBytes===8192*1024*1024,'Expected complete native seed certificate');
   requireProof(same(original.requiredExports,ABI)&&same(original.limits,request.limits),'Full original ABI/limits missing');
   for(const [key,value]of Object.entries(request.limits))requireProof(limits[key as keyof typeof limits]===value,'Original limit changed: '+key);
   for(const [path,digest]of Object.entries(object(original.inputs)))pin(path,digest as string);
   const native=object(request.native),seedBuild=object(original.nativeSeed),nativeRun=object(original.nativeRun);
   const auth=authenticateNativeSeedBuild(String(native.build),{root:realpathSync(String(request.root)),corpusPath:String(native.corpus),limits});
   const expectedPhases=['parse','expand','check','emit'];
   requireProof(JSON.stringify((nativeRun.phaseStarts??[]).map((row:any)=>row.phase))===JSON.stringify(expectedPhases)&&JSON.stringify((nativeRun.phases??[]).map((row:any)=>row.phase))===JSON.stringify(expectedPhases),'Missing ordered native stage0 phases');
   const workload=workloadRows(realpathSync(String(request.root)),'js');
   const effective=requireCorpusCoversWorkload(auth.corpus,workload,'js');
   const effectiveInputs=Object.fromEntries([...workload.sources,...workload.externals].map((row:any)=>[row.file,row.sha256]));
   requireProof(nativeRun.sources===effective.sources&&Array.isArray(nativeRun.fuel)&&nativeRun.fuel.length===effective.sources&&nativeRun.fuel.every((row:any)=>row.cells===8000000),'Native stage0 js source/cell accounting drift');
   requireProof(nativeRun.workload?.target==='js'&&nativeRun.workload?.sources===effective.sources&&nativeRun.workload?.externals===effective.externals,'Native stage0 did not record the exact js workload');
   requireProof(auth.binarySha256===native.binarySha256&&auth.binarySha256===seedBuild.binarySha256&&auth.binarySha256===nativeRun.binarySha256,'Native binary identity drift');
   requireProof(auth.corpusSha256===native.corpusSha256&&auth.corpusSha256===nativeRun.corpusSha256,'Native corpus identity drift');
   requireProof(hash(String(native.build))===native.buildSha256&&native.buildSha256===nativeRun.buildSha256&&hash(String(native.build))===hash(String(seedBuild.build)),'Native build identity drift');
   requireProof(nativeRun.stageOne?.sha256===stageSha256&&nativeRun.stageOne?.bytes===stageBytes,'Native stage-one fingerprint drift');
   for(const [path,digest]of Object.entries(auth.protectedPins))pin(path,String(digest));
   for(const [path,digest]of Object.entries(auth.loadedInputs))pin(path,String(digest));
   pin(String(native.build),String(native.buildSha256));pin(String(native.corpus),String(native.corpusSha256));pin(auth.binary,auth.binarySha256);
   const accepted=readAcceptedParserBuild(request.parserBuild);
   for(const [path,digest]of Object.entries(accepted.authenticatedInputs))pin(path,digest);
   requireProof(accepted.parserSource===request.parserSource,'Original accepted parser chain mismatch');
   for(const key of ['parser','parserBuild','root','rootManifest'])requireProof(typeof request[key]==='string'&&inputs[request[key]]===hash(request[key]),'Request not authenticated by original inputs: '+key);
   const artifacts=object(original.artifacts);one=object(artifacts.stageOne);two=object(artifacts.stageTwo);
   for(const [artifact,name]of [[one,'stage-one'],[two,'stage-two']] as const){
    requireProof(artifact.path===join(String(request.sidecars),name+'.js')&&artifact.bytes===stageBytes&&artifact.sha256===stageSha256,'Wrong native emitted image chain');
    pin(artifact.path,String(artifact.sha256));requireProof(readFileSync(String(artifact.path)).length===stageBytes,'Emitted image size mismatch');
   }
   requireProof(readFileSync(String(one.path)).equals(readFileSync(String(two.path))),'Native stage bytes differ');
   const closure=one.sourceHashes as Record<string,any>[];
   requireProof(Array.isArray(closure)&&closure.length===Object.keys(request.rootInputs).length,'Incomplete native stage source closure');
   requireProof(sameMap(request.rootInputs,effectiveInputs),'Gate phase inputs are not the exact js workload');
   requireProof(sameMap(Object.fromEntries(closure.map((row:any)=>[row.file,row.sourceBytesSha256])),effectiveInputs),'Native stage source closure is not the exact js workload');
   for(const row of closure){requireProof(row.sha256===row.sourceBytesSha256&&request.rootInputs[row.file]===row.sourceBytesSha256,'Native stage source closure mismatch');pin(row.file,row.sourceBytesSha256);}
   const parseRows=original.parseRows as Record<string,any>[],expected=closure.filter(row=>!row.external);
   requireProof(parseRows.length===expected.length&&new Set(parseRows.map(row=>row.file)).size===parseRows.length&&expected.every(row=>parseRows.some(parsed=>parsed.file===row.file)),'Incomplete stage-two root parse approvals');
   for(const row of parseRows){
    requireProof(row.phase==='stage-two-parse'&&row.oracleAccepted===true&&row.fullSemanticAST===true&&row.semanticParity===true&&row.stage0ASTHash===row.compiledASTHash&&/^[0-9a-f]{64}$/.test(String(row.stage0ASTHash))&&row.parserFeedback==='FeedbackComplete'&&row.parserFuel===limits.parserFuel&&row.parserSha256===stageSha256&&row.sourceBytesSha256===inputs[row.file]&&row.sourceSha256===sha(readFileSync(row.file,'utf8')),'Missing complete stage-two semantic approval: '+row.file);
    pin(String(row.transport),String(row.transportSha256));
   }
   fixtures=request.fixtures as Record<string,any>;const seedRows=original.fixtureRows.filter((row:Record<string,any>)=>row.stage==='seed');
   requireProof(Array.isArray(fixtures)&&fixtures.length===95&&new Set(fixtures.map(row=>row.name)).size===95&&seedRows.length===95,'Missing complete 95 original fixtures/native seed rows');
   for(const fixture of fixtures){
    const row=seedRows.find((row:Record<string,any>)=>row.name===fixture.name);
    requireProof(typeof fixture.source==='string'&&fixture.sourceSha256===sha(fixture.source)&&readFileSync(fixture.file,'utf8')===fixture.source&&inputs[fixture.file]===fixture.sourceSha256,'Original fixture source drift: '+fixture.name);
    requireProof(row?.passed===true&&row.accepted===fixture.accepted&&row.sourceSha256===fixture.sourceSha256&&row.parserSha256===auth.binarySha256&&row.compilerSha256===auth.binarySha256,'Original native seed row mismatch: '+fixture.name);
    const manifest=join(String(request.sidecars),'native-fixture-'+fixture.name+'.runtime.tsv');
    const manifestRows=readFileSync(manifest,'utf8').trim().split('\n').map(line=>line.split('\t'));
    const fixtureManifestRow=manifestRows.find(row=>row.length===3&&row[0]==='B'&&row[2]===realpathSync(fixture.file));
    const baseManifestRow=manifestRows.find(row=>row.length===3&&row[0]==='B'&&row[2]===realpathSync('bend2/base.bend'));
    requireProof(row.native?.binarySha256===auth.binarySha256&&hash(manifest)===row.native.manifestSha256&&fixtureManifestRow&&baseManifestRow,'Missing exact native seed manifest receipt: '+fixture.name);
    const artifact=join(String(request.sidecars),'native-fixture-'+fixture.name+'.js');
    if(fixture.accepted)requireProof(existsSync(artifact)&&readFileSync(artifact).length>0&&row.native?.artifactSha256===hash(artifact),'Missing native seed artifact receipt: '+fixture.name);
    else requireProof(!existsSync(artifact)&&row.native?.artifactSha256===null,'Negative native seed row emitted an artifact: '+fixture.name);
    const recordedPhases=Array.isArray(row.native?.phases)?row.native.phases:[];
    const failureIndex=expectedPhases.indexOf(String(fixture.failurePhase));
    if(fixture.accepted)requireProof(JSON.stringify(recordedPhases)===JSON.stringify(expectedPhases),'Accepted native row lacks the complete ordered phases: '+fixture.name);
    else requireProof(failureIndex>=0&&JSON.stringify(recordedPhases)===JSON.stringify(expectedPhases.slice(0,failureIndex+1)),'Native negative phase prefix mismatch: '+fixture.name);
    if(fixture.accepted)requireProof(typeof row.output==='string'&&typeof fixture.output==='string'&&row.output.replace(/\s+/g,'').replace(/\{\}/g,'')===fixture.output.replace(/\s+/g,'').replace(/\{\}/g,''),'Original expected output mismatch: '+fixture.name);
    else requireProof(typeof fixture.failurePhase==='string'&&row.observedFailure===fixture.failurePhase&&row.diagnostic,'Original negative phase mismatch: '+fixture.name);
   }
   state.rootFixedpointCertificate={report:fixedpointReport,reportSha256:inputs[fixedpointReport],request:requestPath,requestSha256:inputs[requestPath],equal:true,comparison:'Buffer.equals on actual unchanged files',stageOne:{path:one.path,sha256:one.sha256,bytes:one.bytes},stageTwo:{path:two.path,sha256:two.sha256,bytes:two.bytes},sourceHashes:closure};
   state.originalMonolithicGate={status:original.status,passed:true,guardian:original.guardian,acceptance:true,seedMode:'native'};
   state.nativeSeedCoverage={checkedDefinitions:auth.report.checkedDefinitions,eventsFullyValidated:auth.report.eventsFullyValidated,binary:auth.binary,sha256:auth.binarySha256,corpus:auth.corpusPath,corpusSha256:auth.corpusSha256};
   state.existingSeedRows=seedRows;state.fixtureInputsSha256=sha(JSON.stringify(fixtures));flush();
   const backendIr=realpathSync(resolve('bend2/selfhost/backend_ir.bend'));
   const sourceFileRow=auth.corpus.files.find((row:any)=>row.external!==true&&typeof row.path==='string'&&realpathSync(resolve(auth.corpus.directory,row.path))===backendIr);
   requireProof(sourceFileRow&&typeof sourceFileRow.namespace==='string','Native workload does not load the canonical BIR module');
   sourceFileTag=sourceFileTagForSelfhostImage(sourceFileRow.namespace);
   requireProof(sourceFileTag===sourceFileTagFromRoot(readFileSync(String(request.root),'utf8'),'selfhost'),'Native corpus BIR namespace differs from the authenticated root import');
  }else{
  requireProof(request.report===fixedpointReport&&request.sidecars===fixedpointReport+'.cases'&&request.worker===true&&!request.fixture&&!request.parseOnly&&!request.profileRoot,'Original request is not a full bootstrap request');
  requireProof(original.status==='FAIL'&&original.passed===false&&original.guardian?.status==='FAIL'&&original.guardian.reason==='deadline_exceeded'&&original.guardian.timeoutMs===600000,'Expected honestly failed original monolithic deadline');
  requireProof(same(original.requiredExports,ABI)&&same(original.limits,request.limits),'Full original ABI/limits missing');
  for(const [key,value]of Object.entries(request.limits))requireProof(limits[key as keyof typeof limits]===value,'Original limit changed: '+key);
  for(const [path,digest]of Object.entries(object(original.inputs)))pin(path,digest as string);
  for(const key of ['component','componentBuild','parser','parserBuild','root','rootManifest'])requireProof(typeof request[key]==='string'&&inputs[request[key]]===hash(request[key]),'Request not authenticated by original inputs: '+key);
  const accepted=readAcceptedParserBuild(request.parserBuild);
  for(const [path,digest]of Object.entries(accepted.authenticatedInputs))pin(path,digest);
  requireProof(accepted.parserSource===request.parserSource&&original.parserSource.file===accepted.parserSource&&original.parserSource.sha256===hash(accepted.parserSource),'Original accepted parser chain mismatch');
  const component=json(request.componentBuild),provenancePath=realpathSync(component.provenancePath),record=json(provenancePath),{provenanceSha256,...proof}=record;
  pin(provenancePath,hash(provenancePath));
  requireProof(component.status==='JS_GENERATED_NOT_YET_EXECUTED'&&component.provenanceSha256===provenanceSha256&&proof.schemaVersion===4&&sha(JSON.stringify(proof))===provenanceSha256,'Native seed canonical schema4 proof mismatch');
  const runtime=object(proof.runtime),guard=object(proof.guard),observation=object(proof.kernelObservation),nativeGuardian=object(component.guardian);
  requireProof(component.checksExcluded===0&&component.outputPatches===0&&proof.checksExcluded===0&&proof.outputPatches===0&&nativeGuardian.status==='PASS','Native seed excluded checks or patched output');
  requireProof(component.sourcePath===request.root&&component.sourceSha256===hash(request.root)&&proof.sourcePath===request.root&&proof.sourceSha256===component.sourceSha256&&realpathSync(component.artifactPath)===request.component&&component.artifactSha256===hash(request.component)&&component.artifactSha256===request.componentSha256,'Native seed is not this exact full root');
  requireProof(same(component.exports,ABI)&&same(component.exports,proof.exports)&&same(runtime,component.runtime)&&runtime.name==='node'&&runtime.heapLimitMiB===3072&&runtime.stackSizeMb===256&&runtime.manualGC===false,'Native seed full ABI/runtime mismatch');
  requireProof(guard.memoryMiB===8192&&guard.rssMiB===8192&&guard.pollMs===10&&nativeGuardian.memoryLimitBytes===8192*1024*1024&&nativeGuardian.rssLimitBytes===8192*1024*1024,'Native seed guardian contract mismatch');
  requireProof(observation.kernelUnmodified===true&&observation.sourceValueReplacement===false&&observation.parserSubstitutions===0&&proof.loadMode==='CANONICAL_NATIVE_UNMODIFIED'&&proof.checkedOutputRetention==='native e'&&component.checkedOutputRetention==='native e','Native seed kernel/body retention mismatch');
  const bodies=proof.checkedDefinitions;requireProof(Number.isSafeInteger(bodies)&&bodies>0,'Missing full native seed body coverage');
  for(const key of ['checkedDefinitions','nativeCheckedBodies','expectedSourceDefinitions'])requireProof(proof[key]===bodies&&component[key]===bodies,'Incomplete native seed bodies: '+key);
  requireProof(Number.isSafeInteger(proof.eventsFullyValidated)&&proof.eventsFullyValidated>0&&proof.eventsFullyValidated===component.eventsFullyValidated,'Incomplete native seed events');
  for(const pins of [object(proof.protectedPins),object(proof.loadedInputs)]){
   requireProof(Object.keys(pins).length>0,'Missing native seed source closure');for(const [path,digest]of Object.entries(pins))pin(path,digest as string);
  }
  for(const [field,path]of [['compilerPath','bend2/comp.ts'],['kernelPath','bend2/bend.ts'],['runnerPath','evals/checker_core_component_build.ts']] as const){
   const real=realpathSync(path);requireProof(proof[field]===real&&proof[field.replace('Path','Sha256')]===hash(real)&&proof.protectedPins[real]===hash(real),'Canonical seed builder identity drift: '+field);
  }
  for(const path of ['evals/heavy_gate.ts','evals/heavy_gate_native.c'])requireProof(proof.protectedPins[realpathSync(path)]===hash(path),'Unauthenticated native guardian');
  requireProof(same(request.rootInputs,proof.loadedInputs)&&same(original.componentBuilder.loadedInputs,proof.loadedInputs)&&original.componentBuilder.provenanceSha256===provenanceSha256,'Original native full closure mismatch');
  requireProof(request.parserSha256===hash(request.parser)&&request.parserSha256===accepted.accepted.artifactSha256,'Original seed parser hash mismatch');
  const composition=object(original.rootComposition),manifest=json(request.rootManifest),parserText=readFileSync(accepted.parserSource,'utf8'),rootText=readFileSync(request.root,'utf8'),declarations=parserText.slice(parserText.search(/^(?:type|def) /m));
  requireProof(same(composition,request.rootComposition)&&composition.exactParserDeclarations===true&&composition.manifest===request.rootManifest&&composition.manifestSha256===hash(request.rootManifest)&&composition.rootSha256===hash(request.root)&&composition.parserSourceSha256===hash(accepted.parserSource)&&composition.parserDeclarationSha256===sha(declarations)&&rootText.slice(composition.embedding.start,composition.embedding.start+composition.embedding.chars)===declarations&&same(composition.embedding,manifest.embedding)&&manifest.outputSha256===hash(request.root)&&manifest.parserBodiesChanged===0&&manifest.parserDatatypesChanged===0&&manifest.parserRequestKontChanged===false,'Exact accepted parser/root composition mismatch');
  const artifacts=object(original.artifacts);one=object(artifacts.stageOne);two=object(artifacts.stageTwo);
  for(const [artifact,name]of [[one,'stage-one'],[two,'stage-two']] as const){
   requireProof(artifact.path===join(request.sidecars,name+'.js')&&artifact.bytes===stageBytes&&artifact.sha256===stageSha256,'Wrong independently pinned emitted image chain');
   pin(artifact.path,artifact.sha256);requireProof(readFileSync(artifact.path).length===artifact.bytes,'Emitted image size mismatch');
  }
  requireProof(readFileSync(one.path).equals(readFileSync(two.path))&&same(one.sourceHashes,two.sourceHashes),'Actual unchanged stage bytes/sourceHashes differ');
  const closure=one.sourceHashes as Record<string,any>[];
  requireProof(Array.isArray(closure)&&closure.length===Object.keys(request.rootInputs).length&&new Set(closure.map(row=>row.file)).size===closure.length,'Incomplete/duplicate stage source closure');
  for(const row of closure){requireProof(row.sha256===row.sourceBytesSha256&&request.rootInputs[row.file]===row.sourceBytesSha256,'Stage source closure mismatch');pin(row.file,row.sourceBytesSha256);}
  const backendIr=realpathSync(resolve('bend2/selfhost/backend_ir.bend'));
  const sourceRow=closure.find(row=>realpathSync(row.file)===backendIr);
  requireProof(sourceRow&&typeof sourceRow.namespace==='string','Legacy stage closure has no canonical BIR module');
  sourceFileTag=sourceFileTagForSelfhostImage(sourceRow.namespace);
  const events=original.events as Record<string,any>[];
  const index=(name:string)=>events.findIndex(row=>row.event==='phase'&&row.phase===name);
  requireProof(index('stage-one-execute')>=0&&index('stage-two-parse')>index('stage-one-execute')&&index('fixedpoint-byte-comparison')>index('stage-two-parse')&&index('stage-two-execute')>index('fixedpoint-byte-comparison'),'Missing actual Root comparison or stage-two execution chain');
  function authenticatedParse(row:Record<string,any>,parserSha:string){
   requireProof(row.oracleAccepted===true&&row.fullSemanticAST===true&&row.semanticParity===true&&row.stage0ASTHash===row.compiledASTHash&&/^[0-9a-f]{64}$/.test(row.stage0ASTHash)&&row.parserFeedback==='FeedbackComplete'&&row.parserFuel===limits.parserFuel&&row.parserSha256===parserSha&&row.sourceBytesSha256===inputs[row.file]&&row.sourceSha256===sha(readFileSync(row.file,'utf8')),'Missing complete original semantic/span approval: '+row.file);
  }
  for(const [parsePhase,parserSha]of [['stage-one-parse',request.parserSha256],['stage-two-parse',one.sha256]]){
   const rows=original.parseRows.filter((row:Record<string,any>)=>row.phase===parsePhase),expected=closure.filter(row=>!row.external);
   requireProof(rows.length===expected.length&&new Set(rows.map((row:Record<string,any>)=>row.file)).size===rows.length&&expected.every(row=>rows.some((parsed:Record<string,any>)=>parsed.file===row.file)),'Incomplete actual root parse approvals: '+parsePhase);
   for(const row of rows){authenticatedParse(row,parserSha);pin(row.transport,row.transportSha256);}
  }
  fixtures=request.fixtures as Record<string,any>;const seedRows=original.fixtureRows.filter((row:Record<string,any>)=>row.stage==='seed');
  requireProof(Array.isArray(fixtures)&&fixtures.length===95&&new Set(fixtures.map(row=>row.name)).size===95&&seedRows.length===95&&new Set(seedRows.map((row:Record<string,any>)=>row.name)).size===95,'Missing complete 95 original fixtures/seed rows');
  // Same printed-constructor equivalence as the unchanged worker (empty braces
  // and whitespace do not change the constructor tree).
  for(const fixture of fixtures){
   const row=seedRows.find((row:Record<string,any>)=>row.name===fixture.name);
   requireProof(typeof fixture.source==='string'&&fixture.sourceSha256===sha(fixture.source)&&readFileSync(fixture.file,'utf8')===fixture.source&&inputs[fixture.file]===fixture.sourceSha256&&typeof fixture.accepted==='boolean','Original fixture source drift: '+fixture.name);
   requireProof(row?.passed===true&&row.accepted===fixture.accepted&&row.sourceSha256===fixture.sourceSha256&&row.parserSha256===request.parserSha256&&row.compilerSha256===request.componentSha256,'Original seed row mismatch: '+fixture.name);
   if(fixture.accepted)requireProof(typeof fixture.output==='string'&&typeof row.output==='string'&&row.output.replace(/\s+/g,'').replace(/\{\}/g,'')===fixture.output.replace(/\s+/g,'').replace(/\{\}/g,''),'Original expected output mismatch: '+fixture.name);
   else requireProof(typeof fixture.failurePhase==='string'&&row.observedFailure===fixture.failurePhase&&row.diagnostic,'Original negative phase mismatch: '+fixture.name);
   const approvals=original.parseRows.filter((row:Record<string,any>)=>row.phase==='seed-fixture-'+fixture.name+'-parse');
   requireProof(approvals.some((row:Record<string,any>)=>row.file===fixture.file),'Missing original seed parse: '+fixture.name);for(const approval of approvals)authenticatedParse(approval,request.parserSha256);
  }
  state.rootFixedpointCertificate={report:fixedpointReport,reportSha256:inputs[fixedpointReport],request:requestPath,requestSha256:inputs[requestPath],equal:true,comparison:'Buffer.equals on actual unchanged files',stageOne:{path:one.path,sha256:one.sha256,bytes:one.bytes},stageTwo:{path:two.path,sha256:two.sha256,bytes:two.bytes},sourceHashes:closure,events:events.filter(row=>['fixedpoint-byte-comparison','stage-two-execute'].includes(row.phase))};
  state.originalMonolithicGate={status:original.status,passed:false,guardian:original.guardian,acceptance:false};
  state.nativeSeedCoverage={checkedDefinitions:bodies,eventsFullyValidated:proof.eventsFullyValidated,component:request.component,sha256:request.componentSha256,provenancePath,provenanceSha256};
  state.existingSeedRows=seedRows;state.fixtureInputsSha256=sha(JSON.stringify(fixtures));flush();
  }
  for(const [name,image]of [['stage-one',one],['stage-two',two]] as const){
   phase=name+'-imports';rehash();
   // The fixture marker selects the worker's existing fixtures-only branch,
   // whose precheck omits two functions; require the full ABI here. Paths are
   // certificate-selected at runtime, so static imports cannot identify them.
   const api=(await import(pathToFileURL(image.path).href)).default;
   requireProof(api&&ABI.every(key=>typeof api[key]==='function'),'Unchanged emitted image lacks full ABI: '+name);
   const directory=join(sidecars,name);mkdirSync(directory);
   const stage:Record<string,any>={stage:name,image:image.path,imageSha256:image.sha256,requiredExports:ABI,fixtureRows:[],parseRows:[],events:[],passed:false};stages.push(stage);flush();
   const freshRequest={...request,native:undefined,nativeBuild:undefined,nativeCorpus:undefined,parser:image.path,component:image.path,parserSha256:image.sha256,componentSha256:image.sha256,sidecars:directory,report,fixture:'authenticated-complete-emitted-suite',parseOnly:false,profileRoot:false,fixtures,sourceFileTag,selfhostImage:{stage:name,path:image.path,sha256:image.sha256,bytes:image.bytes},expectedRoot:{path:realpathSync(request.root),sha256:hash(request.root)}};
   const freshPath=join(directory,'request.json');save(freshPath,freshRequest);pin(freshPath,hash(freshPath));
   child=spawn('node',[resolve('evals/selfhost_bootstrap_worker.mjs'),freshPath],{stdio:['pipe','pipe','inherit']});
   stage.command=['node',resolve('evals/selfhost_bootstrap_worker.mjs'),freshPath];
   const completed=new Promise<number>((done,reject)=>{child!.once('error',reject);child!.once('close',code=>done(code??125));});
   for await(const line of createInterface({input:child.stdout!})){
    const message=object(JSON.parse(line));if(typeof message.phase==='string')phase=message.phase;
    if(message.event==='parse-cache'){
     // The diagnostic marker prompts a cache lookup even without a cache.
     // Always return a miss, with no transport: the worker must parse SOURCE.
     requireProof(Number.isSafeInteger(message.id)&&message.parserSha256===image.sha256,'Malformed fresh-only cache lookup');
     stage.cacheMisses=(stage.cacheMisses??0)+1;
     child.stdin!.write(JSON.stringify({id:message.id,approved:true})+'\n');
    }else if(message.event==='parse'){
     for(const key of ['file','sourceSha256','sourceBytesSha256','parserSha256','transport'])requireProof(typeof message[key]==='string','Malformed compiled parse: '+key);
     requireProof(Number.isSafeInteger(message.id)&&message.parserSha256===image.sha256,'Wrong emitted parser approval request');
     const file=realpathSync(message.file),source=readFileSync(file,'utf8'),transport=realpathSync(message.transport);
     requireProof(file===message.file&&sha(source)===message.sourceSha256&&hash(file)===message.sourceBytesSha256&&transport.startsWith(directory+'/'),'Source/transport changed during compiled parsing');
     pin(file,message.sourceBytesSha256);
     const observe=(event:Record<string,unknown>)=>{if(event.event==='oracle-profile')stage.events.push({...event,phase,file});};
     const parityRequest={file,source,transport,recordInputs:false};
     const parity=process.env.SELFHOST_CPU_PROFILE_DIR?await isolatedParserParity(parityRequest,observe):await parserParity(parityRequest);
     const {stage0ASTHash,compiledASTHash,transportSha256,normalizationLedger,declarations}=parity;
     requireProof(stage0ASTHash===compiledASTHash&&hash(transport)===transportSha256,'Complete semantic AST/transport mismatch: '+file);
     stage.parseRows.push({phase,file,sourceSha256:sha(source),sourceBytesSha256:message.sourceBytesSha256,parserSha256:image.sha256,parserFuel:limits.parserFuel,parserFeedback:'FeedbackComplete',oracleAccepted:true,fullSemanticAST:true,transport,transportSha256,stage0ASTHash,compiledASTHash,semanticParity:true,normalizationLedger,declarations});
     flush();child.stdin!.write(JSON.stringify({id:message.id,approved:true,transportSha256})+'\n');
    }else if(message.event==='fixture'){
     const fixture=fixtures[stage.fixtureRows.length];
     requireProof(fixture&&message.stage==='seed'&&message.name===fixture.name&&message.passed===true&&message.accepted===fixture.accepted&&message.sourceSha256===fixture.sourceSha256&&message.parserSha256===image.sha256&&message.compilerSha256===image.sha256,'Missing/reordered/wrong emitted fixture row');
     stage.fixtureRows.push({...message,workerStage:message.stage,stage:name});flush();
    }else if(message.event==='result'){requireProof(!stage.workerResult,'Duplicate worker result');stage.workerResult=object(message.result);flush();}
    else if(message.event==='parse-cache-used'||message.event==='parse-cache-rejected'||message.event==='artifact')throw Error('Forbidden cache/root emission in emitted fixture runner');
    else if(message.event==='phase'&&message.phase==='complete'){stage.events.push(message);flush();}
   }
   const exit=await completed;child=undefined;stage.exitCode=exit;
   requireProof(exit===0&&stage.workerResult?.passed===true&&stage.workerResult.fixtureExecutions===95&&stage.fixtureRows.length===95,'Emitted worker did not finish all 95 fixtures: '+name);
   for(const fixture of fixtures)requireProof(stage.parseRows.some((row:Record<string,any>)=>row.file===fixture.file&&row.phase==='seed-fixture-'+fixture.name+'-parse'),'Missing fresh emitted fixture parse: '+fixture.name);
   for(const row of stage.parseRows)requireProof(hash(row.transport)===row.transportSha256,'Fresh full AST transport changed');
   rehash();stage.passed=true;flush();
  }
  requireProof(stages.length===2&&stages.every(stage=>stage.passed&&stage.fixtureRows.length===95),'Both unchanged images must finish independently');
  rehash();state.evidenceCounts={existingSeed:95,freshStageOne:95,freshStageTwo:95,freshEmitted:190,total:285};state.passed=true;state.status='EMITTED_SUITES_BEHAVIOR_PASS';flush();
 }catch(error){child?.kill('SIGTERM');state.passed=false;state.status='FAIL';state.failure={phase,error:String(error),stack:error instanceof Error?error.stack:undefined};flush();process.exitCode=2;}
}
