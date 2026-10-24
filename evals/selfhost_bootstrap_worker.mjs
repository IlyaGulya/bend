import {Worker,isMainThread,parentPort,workerData} from 'node:worker_threads';
import {readFileSync,writeFileSync,realpathSync,createReadStream,existsSync} from 'node:fs';
import {resolve,dirname,join,posix,isAbsolute} from 'node:path';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
import {createInterface} from 'node:readline';
import {spawnSync} from 'node:child_process';
import {getHeapStatistics} from 'node:v8';
import {writeNativeAst,decodeNativeAst} from './bootstrap_ast_transport.ts';
import {runNativeStage0,requireNativeRun,runtimeManifest,workloadRows,corpusFor,requireCorpusCoversWorkload} from './native_seed_runtime.mjs';
import {runTemplateSteps,runCheckerSteps,runEmitterSteps,runLibraryEmitterSteps,sourceFiles,sourceFilePath,verifySourceFileCarrier} from './checker_core_step_runtime.mjs';

const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
async function transportHash(path){
 const hash=createHash('sha256');
 for await(const bytes of createReadStream(path))hash.update(bytes);
 return hash.digest('hex');
}
const tag=value=>value?.$?.split('.').at(-1);
const ABI=['parsed_module','parse_with_fuel','expand_modules_start','template_step','check_expanded_start','inspect_checked_start','checker_step','emit_modules_start','emit_library_start','emitter_step','emit_c_modules_start','emit_c_library_start','c_emitter_step'];
const requiredExports=workerData?.fixture?ABI.filter(name=>name!=='parse_with_fuel'&&name!=='emit_library_start'):ABI;
const send=message=>parentPort.postMessage(message);
if(isMainThread){
 if(!process.argv[2])throw Error('Expected bootstrap request path');
 const request=JSON.parse(readFileSync(process.argv[2],'utf8'));
 const worker=new Worker(new URL(import.meta.url),{workerData:request,resourceLimits:{stackSizeMb:256,maxOldGenerationSizeMb:6144,maxYoungGenerationSizeMb:128}});
 const output=message=>console.log(JSON.stringify(message,(_,v)=>typeof v==='bigint'?String(v):v));
 worker.on('message',output);
 worker.on('error',error=>{output({event:'result',result:{passed:false,failure:{phase:'worker-runtime',error:String(error)}}});process.exitCode=2;});
 worker.on('exit',code=>{if(code)process.exitCode=code;lines.close();process.stdin.destroy();});
 const lines=createInterface({input:process.stdin});
 lines.on('line',line=>worker.postMessage(JSON.parse(line)));
}else{
 let phase='imports',parseId=0,phaseStarted=performance.now();
 let cpuProfiler,executionError;
 const approvals=new Map(),artifacts={},fixtures=[],sourcePins=new Map();
 const mark=(next,details={})=>{cpuProfiler?.mark(next,details);phase=next;phaseStarted=performance.now();const memory=process.memoryUsage();send({event:'phase',phase,elapsedMs:phaseStarted,rssBytes:memory.rss,heapUsedBytes:memory.heapUsed,heapLimitBytes:getHeapStatistics().heap_size_limit,...details});};
 parentPort.on('message',message=>{const pending=approvals.get(message.id);if(!pending)return;approvals.delete(message.id);message.approved?pending.resolve(message):pending.reject(Error(message.error));});
 const requestApproval=message=>new Promise((resolve,reject)=>{approvals.set(message.id,{resolve,reject});send(message);});
 const pinSource=(file,digest)=>{
  const previous=sourcePins.get(file);
  if(previous!==undefined&&previous!==digest)throw Error('Source bytes changed across bootstrap boundaries: '+file);
  sourcePins.set(file,digest);
 };
 const authenticateSources=()=>{
  for(const [file,digest]of sourcePins)if(realpathSync(file)!==file||sha(readFileSync(file))!==digest)throw Error('Protected bootstrap source changed: '+file);
 };
 const approve=(file,source,sourceBytesSha256,parsed,parserSha256,cacheContext)=>{
  const id=++parseId,transport=join(workerData.sidecars,'parse-'+id+'.ast.json');
  mark(phase,{file,parserBoundary:'transport-before'});
  const receipt=writeNativeAst(transport,parsed);parsed=undefined;
  mark(phase,{file,parserBoundary:'transport-complete'});
  return {transport,sha256:receipt.sha256,approval:requestApproval({event:'parse',id,phase,file,sourceSha256:sha(source),sourceBytesSha256,parserSha256,transport,cacheContext})};
 };
 const list=values=>{let tail={$:'Nil'};for(let i=values.length-1;i>=0;i--)tail={$:'Con',head:values[i],tail};return tail;};
 function items(value){const out=[];while(tag(value)==='Con'){out.push(value.head);value=value.tail;}if(tag(value)!=='Nil')throw Error('Malformed native list');return out;}
 const namespace=(parent,path)=>path==='Base'?'':posix.normalize(isAbsolute(path)?path.replace(/\.bend$/,''):posix.dirname(parent)+'/'+path.replace(/\.bend$/,''));
 const failure=(stage,result)=>{const error=Error(stage+' failed: '+String(result.message??result.diagnostic?.message));error.phase=phase;error.diagnostic=result.diagnostic??result;error.span=result.span??result.diagnostic?.span;throw error;};
 function exportsOf(module,path){const api=module.default;if(!api||!requiredExports.every(name=>typeof api[name]==='function'))throw Error('Actual compiler library ABI missing in '+path+'; required '+requiredExports.join(','));return api;}
 // The exact finite constructor input is materialized on demand. Keeping the
 // already-consumed 8M-cell prefix live would retain hundreds of MiB.
 const fuelEnd=Object.freeze({$:'FeedbackFuelEnd'});
 const fuelPrototype={
  get tail(){return fuelNode(this.remaining-1);},
 };
 function fuelNode(remaining){
  if(remaining===0)return fuelEnd;
  const node=Object.create(fuelPrototype);
  node.$='FeedbackFuelCell';node.remaining=remaining;
  return node;
 }
 const fuel=fuelNode(workerData.limits.parserFuel);
 function parseFresh(parser,file,source){
  const feedback=parser.parse_with_fuel(fuel,file,source);
  if(tag(feedback)!=='FeedbackComplete'){const error=Error('Accepted parser feedback did not complete: '+tag(feedback));error.file=file;throw error;}
  if(tag(feedback.value?.result)!=='ParseSuccess')failure('parse',feedback.value?.result??feedback);
  return feedback.value.result;
 }
 async function load(root,parser,component,parserSha256){
  const modules=[],parked=[],admissions=[],assignments=new Map(),active=new Set(),sourceHashes=[],foreignSources=new Map();
  const externalImport=(module,declared,span)=>{
   // The declared alternative is BIR metadata; the host only reads the bytes
   // of the path BIR resolves from it and keys the bag by that same path.
   const key=sourceFilePath(module,declared),external=realpathSync(key);
   const bytes=readFileSync(key),source=bytes.toString('utf8'),digest=sha(bytes);
   pinSource(external,digest);
   if(!sourceHashes.some(row=>row.file===external))sourceHashes.push({file:external,sha256:digest,sourceBytesSha256:digest,external:true});
   const known=foreignSources.get(key);
   if(known!==undefined&&known!==source)throw Error('Declared source path resolves to different bytes: '+key);
   foreignSources.set(key,source);
   send({event:'external-import',phase,file:external,declaredPath:declared,sourceSha256:digest,span});
  };
  // The host admits transports serially in its existing oracle loop. Retain at
  // most that admission and one parse-ahead result; imports come only from the
  // actual compiled parser, and no module is consumed until every admission.
  async function admitOne(){
   const {file,sha256,outcome}=admissions[0],result=await outcome;
   if('error'in result)throw result.error;
   if(result.accepted.transportSha256!==sha256)throw Error('Approved fresh transport hash differs');
   admissions.shift();
   mark(phase,{file,parserBoundary:'admission-complete',pendingAdmissions:admissions.length});
  }
  async function visit(file,scope,span){
   const at=realpathSync(file),existing=assignments.get(at);
   if(active.has(at)){const error=Error('Import cycle: '+at);error.span=span;throw error;}
   if(existing!==undefined){if(existing!==scope){const error=Error('One file imported into conflicting namespaces: '+at+' ('+existing+' versus '+scope+')');error.span=span;throw error;}return;}
   if(admissions.length===2)await admitOne();
   assignments.set(at,scope);active.add(at);
   let source,sourceBytesSha256;
   {const bytes=readFileSync(at);source=bytes.toString('utf8');sourceBytesSha256=sha(bytes);}
   pinSource(at,sourceBytesSha256);
   sourceHashes.push({file:at,sha256:sha(source),sourceBytesSha256,namespace:scope});
   mark(phase,{file:at,sourceSha256:sha(source),parserSha256});
   // Diagnostic reuse is never enabled for any full-bootstrap parser boundary,
   // including the full gate's seed/stage-one/stage-two fixture executions.
   const cacheContext=workerData.fixture?{root:realpathSync(root),namespace:scope,assignments:[...assignments],sourceHashes:[...sourceHashes],runtime:{versions:process.versions,platform:process.platform,arch:process.arch}}:undefined;
   let parsed,transportReceipt,approval;
   if(cacheContext){
    const id=++parseId,response=await requestApproval({event:'parse-cache',id,phase,file:at,sourceSha256:sha(source),sourceBytesSha256,parserSha256,cacheContext});
    if(response.transport){
     cpuProfiler?.mark(phase,{file:at,parserBoundary:'cache-restore-before'});
     try{
      const encoded=readFileSync(response.transport);
      if(sha(encoded)!==response.transportSha256)throw Error('Diagnostic transport drift');
      parsed=decodeNativeAst(encoded.toString('utf8'));
      if(tag(parsed)!=='ParseSuccess'||!parsed.module)throw Error('Diagnostic transport is not ParseSuccess');
      transportReceipt={transport:response.transport,sha256:response.transportSha256};
      send({event:'parse-cache-used',id,phase});
     }catch(error){parsed=undefined;send({event:'parse-cache-rejected',id,phase,error:String(error)});}
     cpuProfiler?.mark(phase,{file:at,parserBoundary:'cache-restore-complete',cacheRestored:!!parsed});
    }
   }
   if(!parsed){
    mark(phase,{file:at,parserBoundary:'native-before'});
    parsed=parseFresh(parser,at,source);
    mark(phase,{file:at,parserBoundary:'native-complete'});
    transportReceipt=approve(at,source,sourceBytesSha256,parsed,parserSha256,cacheContext);
    approval=transportReceipt.approval;
   }
   const imports=items(parsed.module.imports);
   // Foreign files live in DefImports, not Module.imports. Authenticate the
   // original parsed paths, matching the native JS builder's full input closure.
   for(const declaration of items(parsed.module.declarations)){
    if(tag(declaration)!=='DefTop'||tag(declaration.definition.body)!=='DefImports')continue;
    for(const path of items(declaration.definition.body.paths)){
     if(typeof path!=='string')throw Error('Malformed actual AST foreign path');
     if(path.endsWith('.js'))externalImport(at,path,declaration.definition.span);
    }
   }
   // The parser's immutable Data tree is the exact graph just serialized.
   // Approval still validates every transport field in both native-oracle
   // passes and compares the complete semantic AST, including source spans.
   // No intervening host operation mutates this graph; do not reconstruct it.
   const module=parsed.module;parsed=undefined;
   if(approval){
    // Observe rejections immediately, even while synchronous native parsing
    // runs ahead. Surface them in deterministic admission order at the barrier.
    admissions.push({file:at,sha256:transportReceipt.sha256,outcome:approval.then(accepted=>({accepted}),error=>({error}))});
    mark(phase,{file:at,parserBoundary:'admission-queued',pendingAdmissions:admissions.length});
    if(workerData.fixture)await admitOne();
   }
   for(const imported of imports){
    const path=imported.path;
    if(typeof path!=='string')throw Error('Malformed actual AST import path');
    if(/^0x[0-9a-f]+\//.test(path)){const error=Error('Cached package manifest/hash verification is not part of this local bootstrap root');error.span=imported.span;throw error;}
    const child=path==='Base'?resolve('bend2/base.bend'):resolve(dirname(at),path);
    if(path.endsWith('.js')){
     // Foreign import metadata belongs to the original parsed Module. Host IO
     // authenticates its bytes but never parses it as Bend or rewrites the AST.
     externalImport(at,path,imported.span);
     continue;
    }
    await visit(child,namespace(scope,path),imported.span);
   }
   parked.push({file:at,scope,sourceBytesSha256,transport:transportReceipt.transport,sha256:transportReceipt.sha256,module});active.delete(at);
  }
  await visit(root,'',{$:'SpanOf',file:root,beg:0,end:0});
  while(admissions.length)await admitOne();
  if(realpathSync(root)===realpathSync(workerData.root)){
   const observed=new Set(sourceHashes.map(row=>row.file)),expected=workerData.rootInputs;
   if(Object.keys(expected).length!==observed.size||sourceHashes.some(row=>expected[row.file]!==row.sourceBytesSha256))throw Error('Parsed compiler closure differs from the canonical native builder inputs');
  }
  for(const row of parked){
   if(sha(readFileSync(row.file))!==row.sourceBytesSha256)throw Error('Source changed before approved AST use');
   mark(phase,{file:row.file,parserBoundary:'retained-input-before'});
   if(await transportHash(row.transport)!==row.sha256)throw Error('Approved native AST transport changed before source use');
   modules.push(component.parsed_module(row.scope,row.module));row.module=undefined;
   mark(phase,{file:row.file,parserBoundary:'retained-input-complete'});
  }
  return {modules:list(modules),sourceHashes,files:[...foreignSources].map(([path,source])=>({path,source}))};
 }
 // A bounded profile timeout is failure, never bootstrap acceptance.
 function profileSteps(component,exports){
  if(!workerData.profileRoot)return component;
  let chunkAdvances=0,lastHeartbeat=performance.now();
  return Object.fromEntries([...Object.entries(component),...exports.filter(name=>name.endsWith('_step')).map(name=>[name,run=>{
   chunkAdvances++;
   if((chunkAdvances&1023)===0){
    const now=performance.now();
    if(now-lastHeartbeat>=1000){lastHeartbeat=now;send({event:'profile-progress',phase,phaseTraceVersion:3,chunkAdvances,chunkQuantum:64,countScope:'Opaque native Run step calls only; initial start chunk excluded',phaseElapsedMs:now-phaseStarted,...process.memoryUsage()});}
    if(now-phaseStarted>300000){const error=Error('Full-root profiling phase exceeded the 300000 ms target: '+phase);error.phase=phase;throw error;}
   }
   return component[name](run);
  }])]);
 }
 // The nominal carrier tag is supplied by the caller from provenance or the
 // closure's source rows; there is no default because a wrong tag is a fail-stop.
 // The BIR module's namespace in this closure is the authority for the carrier
 // tag of anything the closure emits; the artifact can only confirm it.
 function stageSourceFileTag(rows){
  const canonical=realpathSync(resolve('bend2/selfhost/backend_ir.bend'));
  const row=rows.find(row=>row.file===canonical);
  if(!row)throw Error('Compiler closure carries no canonical backend_ir source row');
  return row.namespace?row.namespace+'.SourceFile':'SourceFile';
 }
 function compile(component,loaded,library,sourceFileTag){
  let modules=loaded.modules,files=sourceFiles(loaded.files,sourceFileTag);loaded.modules=undefined;loaded.files=undefined;
  const expansionComponent=profileSteps({...component,expand_modules_start:input=>{modules=undefined;return component.expand_modules_start(input);}},['expand_modules_start','template_step']);
  mark(phase+'-expand');let expanded=runTemplateSteps(expansionComponent,modules);
  if(tag(expanded)!=='ExpandSuccess')failure('expand',expanded);
  const checkingComponent=profileSteps({...component,check_expanded_start:input=>{expanded=undefined;return component.check_expanded_start(input);}},['check_expanded_start','checker_step']);
  mark(phase.replace(/-expand$/,'')+'-check');let checked=runCheckerSteps(checkingComponent,expanded.modules);
  if(tag(checked)!=='CheckSuccess')failure('check',checked);
  const emissionComponent=profileSteps({...component,emit_modules_start:(input,sources)=>{checked=undefined;return component.emit_modules_start(input,sources);},emit_library_start:(program,names,sources)=>{checked=undefined;return component.emit_library_start(program,names,sources);}},['emit_modules_start','emit_library_start','emitter_step']);
  mark(phase.replace(/-check$/,'')+'-emit');const emitted=library?runLibraryEmitterSteps(emissionComponent,checked.program,list(ABI),files):runEmitterSteps(emissionComponent,checked.program,files);
  files=undefined;
  if(tag(emitted)!=='EmitSuccess')failure('emit',emitted);
  return emitted.source;
 }
 function fixtureConstructorValue(text){
  let at=0;
  const whitespace=()=>{while(/\s/.test(text[at]??'')&&at<text.length)at++;};
  const value=()=>{
   whitespace();const name=/^[A-Za-z_][A-Za-z0-9_.\/~:-]*/.exec(text.slice(at));
   if(!name)throw Error('Expected a printed constructor value at '+at);
   at+=name[0].length;whitespace();const fields=[];
   if(text[at]==='{'){
    at++;whitespace();
    if(text[at]!=='}')for(;;){fields.push(value());whitespace();if(text[at]!==',')break;at++;}
    if(text[at]!=='}')throw Error('Unclosed printed constructor fields at '+at);
    at++;whitespace();
   }
   return [name[0],fields];
  };
  const result=value();if(at!==text.length)throw Error('Trailing printed value content at '+at);
  return JSON.stringify(result);
 }
 async function runFixtures(parser,component,parserSha256,compilerSha256,stage,sourceFileTag){
  for(const fixture of workerData.fixtures){
   mark(stage+'-fixture-'+fixture.name+'-parse');
   const loaded=await load(fixture.file,parser,component,parserSha256);
   let output,diagnostic,observedFailure;
   try{
    mark(stage+'-fixture-'+fixture.name);
    const source=compile(component,loaded,false,sourceFileTag);
    if(!fixture.accepted)throw Error('Consumer-visible failure was incorrectly accepted: '+fixture.name);
    const artifact=join(workerData.sidecars,stage+'-'+fixture.name+'.js');writeFileSync(artifact,source,{flag:'wx'});
    mark(stage+'-fixture-'+fixture.name+'-execute');
    const profileExecution=cpuProfiler?.childExecution(phase,{artifact,artifactSha256:sha(source),stage,fixture:fixture.name});
    const run=spawnSync(process.execPath,[...(profileExecution?.args??[]),artifact],{encoding:'utf8',timeout:120000,killSignal:'SIGKILL'});
    profileExecution?.finish(run);
    if(run.error||run.status!==0)throw Error('Unchanged emitted fixture execution failed: '+String(run.error??run.stderr));
    output=run.stdout.trim();if(fixtureConstructorValue(output)!==fixtureConstructorValue(fixture.output))throw Error('Fixture value mismatch: expected '+fixture.output+', observed '+output);
   }catch(error){
    if(fixture.accepted||!error.diagnostic)throw error;
    observedFailure=error.phase?.split('-').at(-1);diagnostic=error.diagnostic;
    if(observedFailure!==fixture.failurePhase)throw error;
    const span=error.span;
    if(!span||span.file!==fixture.file||!Number.isSafeInteger(span.beg)||!Number.isSafeInteger(span.end)||span.beg<0||span.end<span.beg||span.end>fixture.source.length)throw Error('Consumer failure lost its actual source span');
   }
   const row={event:'fixture',phase,stage,name:fixture.name,passed:true,accepted:fixture.accepted,output,diagnostic,observedFailure,sourceSha256:fixture.sourceSha256,parserSha256,compilerSha256};fixtures.push(row);send(row);
  }
 }
 async function runNativeSeed(){
  const native=workerData.native,sidecar=workerData.sidecars,limits=workerData.limits;
  const binary=realpathSync(native.binary),base=resolve('bend2/base.bend');
  if(sha(readFileSync(binary))!==native.binarySha256)throw Error('Native stage0 binary changed before execution');
  if(sha(readFileSync(native.corpus))!==native.corpusSha256)throw Error('Native stage0 corpus changed before execution');
  if(sha(readFileSync(native.build))!==native.buildSha256)throw Error('Native stage0 build report changed before execution');
  const corpus=JSON.parse(readFileSync(native.corpus,'utf8'));
  const workload=workloadRows(workerData.root,'js');
  const effective=requireCorpusCoversWorkload(corpus,workload,'js');
  const sources=workload.sources.length;
  const exportsPath=join(sidecar,'native-exports.txt'),manifestPath=join(sidecar,'native-root.runtime.tsv');
  writeFileSync(exportsPath,ABI.join('\n')+'\n',{flag:'wx'});
  writeFileSync(manifestPath,runtimeManifest(corpus),{flag:'wx'});
  const sourceHashes=[...workload.sources.map(row=>({file:row.file,sha256:row.sha256,sourceBytesSha256:row.sha256,namespace:row.namespace})),
    ...workload.externals.map(row=>({file:row.file,sha256:row.sha256,sourceBytesSha256:row.sha256,external:true}))]
    .sort((left,right)=>left.file.localeCompare(right.file));
  const sorted=values=>JSON.stringify([...values].sort((left,right)=>left.file.localeCompare(right.file)));
  mark('native-stage-zero-parse');
  const stageOnePath=join(sidecar,'stage-one.js');
  const run=runNativeStage0(binary,{root:workerData.root,base,manifest:manifestPath,exports:exportsPath,phase:'compile',output:stageOnePath},{timeoutMs:limits.timeoutMs});
  const emitted=requireNativeRun(run,{phases:['parse','expand','check','emit'],sources,output:stageOnePath});
  const stageOneSha=sha(emitted.bytes);
  artifacts.stageOne={event:'artifact',phase:'native-stage-zero-emit',stage:'stageOne',path:stageOnePath,sha256:stageOneSha,bytes:emitted.bytes.length,sourceHashes};send(artifacts.stageOne);
  const nativeRun={binary:native.binary,binarySha256:native.binarySha256,build:native.build,buildSha256:native.buildSha256,
   corpus:native.corpus,corpusSha256:native.corpusSha256,phases:run.phases,phaseStarts:run.phaseStarts,fuel:run.fuel,
   begins:run.begins,result:emitted.emit,elapsedMs:run.elapsedMs,sources,foreign:effective.externals,workload:effective,
   stageOne:{path:stageOnePath,sha256:stageOneSha,bytes:emitted.bytes.length}};
  send({event:'native-run',phase:'native-stage-zero',...nativeRun});
  // The native stage0 executes the original seed fixtures through its own
  // checked parser/checker/emitter; no seed JS is imported anywhere here.
  for(const fixture of workerData.fixtures){
   mark('seed-fixture-'+fixture.name+'-parse');
   const rows=workloadRows(fixture.file),fixtureCorpus=corpusFor(rows);
   const fixtureManifest=join(sidecar,'native-fixture-'+fixture.name+'.runtime.tsv');
   writeFileSync(fixtureManifest,runtimeManifest(fixtureCorpus),{flag:'wx'});
   const output=join(sidecar,'native-fixture-'+fixture.name+'.js');
   mark('seed-fixture-'+fixture.name);
   const fixtureRun=runNativeStage0(binary,{root:fixture.file,base,manifest:fixtureManifest,exports:exportsPath,phase:'compile-module',output},{timeoutMs:limits.timeoutMs});
   let outputText,diagnostic,observedFailure;
   try{
    requireNativeRun(fixtureRun,{phases:['parse','expand','check','emit'],sources:rows.sources.length,output});
    if(!fixture.accepted)throw Error('Consumer-visible failure was incorrectly accepted: '+fixture.name);
    mark('seed-fixture-'+fixture.name+'-execute');
    const executed=spawnSync(process.execPath,[output],{encoding:'utf8',timeout:120000,killSignal:'SIGKILL'});
    if(executed.error||executed.status!==0)throw Error('Unchanged emitted fixture execution failed: '+String(executed.error??executed.stderr));
    outputText=executed.stdout.trim();
    if(fixtureConstructorValue(outputText)!==fixtureConstructorValue(fixture.output))throw Error('Fixture value mismatch: expected '+fixture.output+', observed '+outputText);
   }catch(error){
    if(fixture.accepted||!error.failurePhase)throw error;
    observedFailure=error.failurePhase;diagnostic=error.diagnostic;
    if(observedFailure!==fixture.failurePhase)throw error;
   }
   const row={event:'fixture',phase,stage:'seed',name:fixture.name,passed:true,accepted:fixture.accepted,output:outputText,diagnostic,observedFailure,
    sourceSha256:fixture.sourceSha256,parserSha256:native.binarySha256,compilerSha256:native.binarySha256,
    native:{binarySha256:native.binarySha256,manifestSha256:sha(readFileSync(fixtureManifest)),
     artifactSha256:existsSync(output)?sha(readFileSync(output)):null,phases:fixtureRun.phaseStarts.map(row=>row.phase)}};
   fixtures.push(row);send(row);
  }
  authenticateSources();
  // No seed parser or component is used from this boundary onwards.
  mark('stage-one-execute');const stage1=exportsOf(await import(pathToFileURL(stageOnePath).href),stageOnePath);
  mark('stage-two-parse');const second=await load(workerData.root,stage1,stage1,stageOneSha);
  if(sorted(second.sourceHashes)!==sorted(sourceHashes))throw Error('Stage source closure drift');
  mark('stage-two');let stageTwo=compile(stage1,second,true,native.sourceFileTag);
  const secondPath=join(sidecar,'stage-two.js');writeFileSync(secondPath,stageTwo,{flag:'wx'});
  artifacts.stageTwo={event:'artifact',phase,stage:'stageTwo',path:secondPath,sha256:sha(stageTwo),bytes:Buffer.byteLength(stageTwo),sourceHashes:second.sourceHashes};send(artifacts.stageTwo);
  mark('fixedpoint-byte-comparison');
  {
   const firstBytes=readFileSync(stageOnePath),secondBytes=readFileSync(secondPath);
   if(sha(firstBytes)!==artifacts.stageOne.sha256||sha(secondBytes)!==artifacts.stageTwo.sha256)throw Error('Unchanged emitted compiler artifact drift');
   if(!firstBytes.equals(secondBytes))throw Error('Real emitted compiler fixedpoint failed: stage-one and stage-two bytes differ');
  }
  mark('stage-two-execute');const stage2=exportsOf(await import(pathToFileURL(secondPath).href),secondPath);
  stageTwo=undefined;
  authenticateSources();
  mark('complete');
  send({event:'result',result:{passed:true,seedMode:'native',compilerBootstrapGreen:true,selfhostGreen:false,
   fixedpoint:{criterion:'Exact emitted UTF-8 JS bytes; no normalization or patching',equal:true,
    stageOneSha256:artifacts.stageOne.sha256,stageTwoSha256:artifacts.stageTwo.sha256},
   stageTwoParser:'stage-one emitted parse_with_fuel, not seed parser',stageOneProducer:'native stage0 executable',
   fullCompilerRoot:workerData.root,legacyFullIODriver:false,fixtureExecutions:fixtures.length,nativeRun}});
 }
 try{
  if(process.env.SELFHOST_CPU_PROFILE_DIR){
   const {createCpuProfiler}=await import('./selfhost_cpu_profile.mjs');
   cpuProfiler=createCpuProfiler(process.env.SELFHOST_CPU_PROFILE_DIR,{root:workerData.root,parser:workerData.parser,parserSha256:workerData.parserSha256,component:workerData.component,componentSha256:workerData.componentSha256,sidecars:workerData.sidecars,fixture:workerData.fixture,parseOnly:workerData.parseOnly,profileRoot:workerData.profileRoot,limits:workerData.limits});
   cpuProfiler.mark('imports');
  }
  if(workerData.native){await runNativeSeed();}else{
  if(sha(readFileSync(workerData.parser))!==workerData.parserSha256||sha(readFileSync(workerData.component))!==workerData.componentSha256)throw Error('Authenticated seed artifact changed before execution');
  const seedParser=(await import(pathToFileURL(workerData.parser).href)).default;
  // The passive carrier tag is the seed artifact's own registration, never a guess.
  // Provenance, not inspection: the seed artifact is produced by the official
  // compiler, whose BIR module sits in the root namespace and therefore
  // registers the bare carrier. The request carries that fact explicitly.
  if(typeof workerData.sourceFileTag!=='string'||!workerData.sourceFileTag)throw Error('Seed request must carry the nominal BIR.SourceFile tag');
  const seedTag=workerData.sourceFileTag;
  const seed=exportsOf(await import(pathToFileURL(workerData.component).href),workerData.component);
  const seedParserSha=workerData.parserSha256;
  if(!workerData.parseOnly&&!workerData.profileRoot)await runFixtures(seedParser,seed,seedParserSha,workerData.componentSha256,'seed',seedTag);
  if(workerData.fixture){
   authenticateSources();
   mark('complete');send({event:'result',result:{passed:true,compilerBootstrapGreen:false,selfhostGreen:false,diagnosticFixture:workerData.fixture,fixtureExecutions:fixtures.length}});
  }else{
  mark('stage-one-parse');const first=await load(workerData.root,seedParser,seed,seedParserSha);
  if(!first.sourceHashes.some(row=>row.file===realpathSync(workerData.root)&&row.sourceBytesSha256===workerData.rootComposition.rootSha256&&row.namespace===''))throw Error('Parsed compiler root does not match the verified exact-parser composition');
  if(workerData.parseOnly){
   authenticateSources();
   const sourceHashes=first.sourceHashes;first.modules=undefined;
   mark('root-parse-diagnostic-complete');send({event:'result',result:{passed:false,diagnosticOnly:true,bootstrapAcceptance:false,diagnosticPhaseComplete:true,compilerBootstrapGreen:false,selfhostGreen:false,sourceHashes,fixtureExecutions:0}});
  }else{
  mark('stage-one');let stageOne=compile(seed,first,true,seedTag);
  const firstPath=join(workerData.sidecars,'stage-one.js');writeFileSync(firstPath,stageOne,{flag:'wx'});
  artifacts.stageOne={event:'artifact',phase,stage:'stageOne',path:firstPath,sha256:sha(stageOne),bytes:Buffer.byteLength(stageOne),sourceHashes:first.sourceHashes};send(artifacts.stageOne);
  // Stage-one is a selfhost-emitted image: its BIR module is namespaced by the
  // closure import path, so the tag comes from that source row, not the bytes.
  const stageOneTag=stageSourceFileTag(first.sourceHashes);
  verifySourceFileCarrier(stageOne,stageOneTag);
  mark('stage-one-execute');const stage1=exportsOf(await import(pathToFileURL(firstPath).href),firstPath);
  stageOne=undefined;
  if(workerData.profileRoot){
   authenticateSources();
   mark('root-compiler-profile-complete');send({event:'result',result:{passed:false,diagnosticOnly:true,bootstrapAcceptance:false,diagnosticPhaseComplete:true,compilerBootstrapGreen:false,selfhostGreen:false,sourceHashes:first.sourceHashes,artifacts,fixtureExecutions:0}});
  }else{
  // No seed parser or component is used from this boundary onwards.
  mark('stage-two-parse');const second=await load(workerData.root,stage1,stage1,artifacts.stageOne.sha256);
  if(JSON.stringify(first.sourceHashes)!==JSON.stringify(second.sourceHashes))throw Error('Stage source closure drift');
  mark('stage-two');let stageTwo=compile(stage1,second,true,stageOneTag);
  const secondPath=join(workerData.sidecars,'stage-two.js');writeFileSync(secondPath,stageTwo,{flag:'wx'});
  artifacts.stageTwo={event:'artifact',phase,stage:'stageTwo',path:secondPath,sha256:sha(stageTwo),bytes:Buffer.byteLength(stageTwo),sourceHashes:second.sourceHashes};send(artifacts.stageTwo);
  mark('fixedpoint-byte-comparison');
  {
   const firstBytes=readFileSync(firstPath),secondBytes=readFileSync(secondPath);
   if(sha(firstBytes)!==artifacts.stageOne.sha256||sha(secondBytes)!==artifacts.stageTwo.sha256)throw Error('Unchanged emitted compiler artifact drift');
   if(!firstBytes.equals(secondBytes))throw Error('Real emitted compiler fixedpoint failed: stage-one and stage-two bytes differ');
  }
  // Prove full-root self-compilation before the long fixture suites. Both emitted
  // stages still execute every fixture before bootstrap acceptance is published.
  mark('stage-two-execute');const stage2=exportsOf(await import(pathToFileURL(secondPath).href),secondPath);
  stageTwo=undefined;
  await runFixtures(stage1,stage1,artifacts.stageOne.sha256,artifacts.stageOne.sha256,'stage-one',stageOneTag);
  await runFixtures(stage2,stage2,artifacts.stageTwo.sha256,artifacts.stageTwo.sha256,'stage-two',stageOneTag);
  authenticateSources();
  mark('complete');send({event:'result',result:{passed:true,compilerBootstrapGreen:true,selfhostGreen:false,fixedpoint:{criterion:'Exact emitted UTF-8 JS bytes; no normalization or patching',equal:true,stageOneSha256:artifacts.stageOne.sha256,stageTwoSha256:artifacts.stageTwo.sha256},stageTwoParser:'stage-one emitted parse_with_fuel, not seed parser',fullCompilerRoot:workerData.root,legacyFullIODriver:false,fixtureExecutions:fixtures.length}});
  }
  }
  }
  }
 }catch(error){executionError=error;send({event:'result',result:{passed:false,selfhostGreen:false,failure:{phase:error.phase??phase,error:String(error),stack:error.stack,diagnostic:error.diagnostic,span:error.span,file:error.file,artifacts}}});process.exitCode=2;}
 finally{try{cpuProfiler?.finish(executionError);}finally{parentPort.removeAllListeners('message');parentPort.close();}}
}
