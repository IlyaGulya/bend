import {sourceOracle} from './bootstrap_source_oracle.ts';
import {canonicalCore,normalizeCoreBook,normalizeImports} from './parser_full_semantic_normalize.ts';
import type {Node,Value} from './parser_full_semantic_normalize.ts';
import type {Book} from '../bend2/bend.ts';
import type {HeavyGateResult} from './heavy_gate.ts';
import {nativeAstValue,semanticHash,decodeNativeAst} from './bootstrap_ast_transport.ts';
import type {NativeValue} from './bootstrap_ast_transport.ts';
import {runHeavyGate} from './heavy_gate.ts';
import {createHash} from 'node:crypto';
import {appendFileSync,readFileSync,writeFileSync,mkdtempSync,rmSync,existsSync,mkdirSync} from 'node:fs';
import {resolve,dirname,join,basename} from 'node:path';
import {tmpdir} from 'node:os';

const FUEL=2000000;
const MEMORY_MIB=8192,POLL_MS=10;
const DEFAULT_ARTIFACT='checkpoints/bootstrap-parser-rebuild-annotation-v1.js';
const FROZEN_SHA='e419a3387202dbd8e54ddfffbe79211b445aab03dee449687f7534f5a6372095';
const worker=resolve(import.meta.dir,'bootstrap_parser_isolated_worker.mjs');
const sha=(data:string|Uint8Array)=>createHash('sha256').update(data).digest('hex');
const errorText=(error:unknown)=>error instanceof Error?`${error.name}: ${error.message}`:String(error);
function save(path:string,value:unknown){writeFileSync(path,JSON.stringify(value,null,2)+'\n');}
type Item={id:number|string;file:string;snapshot:string;sourceSha256:string};
type Job={item:Item;artifact:string;request:string;transport:string;workerStatus:string;row:string;mismatch:string;declarations?:number};
type Row=Record<string,unknown>&{status:string;complete:boolean;acceptanceParity:boolean;semanticParity:boolean;compiledAccepted?:boolean;stage0Accepted?:boolean;error?:string};
function astNode(value:Value):Node{
 if(typeof value!=='object'||Array.isArray(value)||!value||typeof value.tag!=='string')throw Error('Expected AST constructor');
 return value;
}
function fullModuleMetadata(module:Node){
 const declarations=module.fields[2],imports=module.fields[1];
 if(!Array.isArray(declarations)||!Array.isArray(imports))throw Error('Expected module declaration and import lists');
 const constructorCensus={TemplateBinder:0,TermTemplate:0};
 const pending:Value[]=[module];
 while(pending.length){
  const value=pending.pop()!;
  if(Array.isArray(value)){
   for(let i=value.length-1;i>=0;i--)pending.push(value[i]);
  }else if(value&&typeof value==='object'){
   const node=astNode(value);
   if(node.tag==='TemplateBinder')constructorCensus.TemplateBinder++;
   if(node.tag==='TermTemplate')constructorCensus.TermTemplate++;
   for(let i=node.fields.length-1;i>=0;i--)pending.push(node.fields[i]);
  }
 }
 let templateDefinitionCount=0;
 for(const value of declarations){
  const top=astNode(value);
  if(top.tag!=='DefTop')continue;
  const definition=astNode(top.fields[0]),binders=definition.fields[1];
  if(definition.tag!=='Definition'||!Array.isArray(binders))throw Error('Expected DefTop definition binders');
  if(binders.some(value=>astNode(value).tag==='TemplateBinder'))templateDefinitionCount++;
 }
 return {
  imports:imports.map(value=>{
   const [path,alias]=astNode(value).fields;
   if(typeof path!=='string'||typeof alias!=='string')throw Error('Expected string import path and alias');
   return {path,alias};
  }),
  declarationCount:declarations.length,constructorCensus,templateDefinitionCount,
 };
}

function collectWorkerPhases(job:Job,row:Row){
 const path=job.workerStatus+'.phases.jsonl';
 if(!existsSync(path))return;
 row.workerStatusPath=job.workerStatus;row.workerPhasesPath=path;
 const text=readFileSync(path,'utf8'),end=text.lastIndexOf('\n');
 if(end<0)return; // A guardian kill can interrupt the final append; retain its raw sidecar.
 const lines=text.slice(0,end).split('\n').filter(Boolean),already=Number(row.workerPhaseRows??0);
 for(let i=already;i<lines.length;i++){
  const record=JSON.parse(lines[i]);
  appendFileSync(job.row+'.phases.jsonl',JSON.stringify({...record,origin:record.origin??'compiled-worker',collectedBy:'corpus-compare'})+'\n');
  row.lastWorkerPhase={phase:record.phase,boundary:record.boundary??record.event,timestampMs:record.timestampMs,elapsedMs:record.elapsedMs,rssBytes:record.rssBytes};
  // The guardian may kill serialization after a validated parse but before final worker status.
  if(record.origin==='compiled-worker'&&record.parseCompleted===true){
   row.parseCompleted=true;
   if(typeof record.compiledAccepted==='boolean')row.compiledAccepted=record.compiledAccepted;
   if(typeof record.fullFileParseSuccess==='boolean')row.fullFileParseSuccess=record.fullFileParseSuccess;
   if(typeof record.prefixParseSuccess==='boolean')row.prefixParseSuccess=record.prefixParseSuccess;
   if(typeof record.sourceScope==='string')row.sourceScope=record.sourceScope;
  }
 }
 row.workerPhaseRows=lines.length;
}

async function compare(job:Job){
 const began=performance.now();
 const {item}=job,original=readFileSync(item.snapshot,'utf8');
 if(sha(original)!==item.sourceSha256)throw Error('Frozen source snapshot hash mismatch');
 const candidates=job.declarations===undefined?undefined:[...original.matchAll(/^(?:def |type |law |@unsafe\b).*$/gm)];
 if(job.declarations!==undefined&&(!Number.isSafeInteger(job.declarations)||job.declarations<0||job.declarations>candidates!.length))throw Error('Invalid declaration boundary');
 const source=job.declarations===undefined?original:original.slice(0,candidates![job.declarations]?.index??original.length);
 const sourceScope=job.declarations===undefined?'full-file':'declaration-prefix';
 const row:Row={id:item.id,name:basename(item.file),file:item.file,snapshot:item.snapshot,originalSourceSha256:item.sourceSha256,sourceSha256:sha(source),prefixSha256:job.declarations===undefined?undefined:sha(source),sourceScope,declarations:job.declarations,sourceChars:source.length,originalSourceChars:original.length,fuel:FUEL,status:'runtime-error',attempted:true,finished:false,complete:false,parseCompleted:false,fullFileParseSuccess:false,prefixParseSuccess:false,acceptanceParity:false,semanticParity:false,phasesPath:job.row+'.phases.jsonl'};
 let phase='runtime-error',failureStage='initialization';
 const persist=()=>{save(job.row,row);};
 const mark=(stage:string,boundary:string,details:Record<string,unknown>={})=>{
  failureStage=stage;
  const memory=process.memoryUsage(),elapsedMs=performance.now()-began;
  appendFileSync(job.row+'.phases.jsonl',JSON.stringify({
   phase:stage,boundary,origin:'corpus-compare',pid:process.pid,timestampMs:Date.now(),elapsedMs,
   rssBytes:memory.rss,heapUsed:memory.heapUsed,heapTotal:memory.heapTotal,external:memory.external,arrayBuffers:memory.arrayBuffers,...details,
  })+'\n');
  row.lastPhase={phase:stage,boundary,elapsedMs};persist();
 };
 try{
  mark('compare-start','before');
  mark('stage0-oracle','before');
  const oracle=await sourceOracle(item.file,source,{preloadBase:false});
  row.stage0Accepted=oracle.accepted;
  row.stage0Failure=oracle.failure;
  row.stage0Error=oracle.error===undefined?undefined:errorText(oracle.error);
  row.normalizationLedger={observation:oracle.observation,exclusions:oracle.exclusions};
  mark('stage0-oracle','after',{accepted:oracle.accepted,declarations:oracle.declarations.length,imports:oracle.imports.length});
  mark('compiled-parse-launch','before');
  save(job.request,{file:item.file,source,sourceScope,declarations:job.declarations,originalSourceSha256:item.sourceSha256,sourceSha256:row.sourceSha256,prefixSha256:row.prefixSha256});
  const child=Bun.spawn(['node',worker,job.artifact,job.request,job.transport,job.workerStatus],{stdin:'ignore',stdout:'inherit',stderr:'inherit'});
  mark('compiled-parse-launch','after',{childPid:child.pid});
  mark('compiled-parse-wait','before',{childPid:child.pid});
  const exitCode=await child.exited;
  mark('compiled-parse-wait','after',{exitCode});
  collectWorkerPhases(job,row);
  mark('compiled-parse-status','before');
  if(!existsSync(job.workerStatus))throw Error('Artifact worker exited '+exitCode+' without status');
  const result=JSON.parse(readFileSync(job.workerStatus,'utf8'));
  Object.assign(row,result);
  mark('compiled-parse-status','after',{status:result.status,parseCompleted:row.parseCompleted});
  if(!['accepted','rejection'].includes(result.status)){
   row.complete=false;row.finished=true;mark('compare-complete','after',{status:row.status});return;
  }
  row.acceptanceParity=row.compiledAccepted===oracle.accepted;
  phase='ast-transport-normalization-failure';
  let environment:Book|undefined;
  let expectedDeclarations:number|undefined;
  if(oracle.accepted&&row.compiledAccepted){
   mark('expected-normalization-environment','before');
   environment=oracle.normalizationBook();
   mark('expected-normalization-environment','after');
   {
    mark('expected-normalization','before');
    const expected=normalizeCoreBook(environment,oracle.declarations.map(d=>d.key),oracle.imports.map(i=>({path:i.path,alias:i.alias})),item.file,dirname(item.file)+'/').semantic;
    expectedDeclarations=expected.declarations.length;
    mark('expected-normalization','after',{declarations:expectedDeclarations});
    mark('expected-semantic-hash','before');
    row.stage0ASTHash=semanticHash(expected);
    mark('expected-semantic-hash','after');
   }
   // Only the complete JSON-ledger hash survives; never retain both normalized trees.
   mark('expected-semantic-reclaim','before');
   Bun.gc(true);
   mark('expected-semantic-reclaim','after');
  }
  let native:NativeValue;
  {
   mark('native-ast-transport-read','before');
   const encoded=readFileSync(job.transport,'utf8');
   mark('native-ast-transport-read','after',{transportCodeUnits:encoded.length});
   mark('native-ast-transport-decode','before');
   native=decodeNativeAst(encoded);
   mark('native-ast-transport-decode','after');
  }
  // The parsed envelope and transport string are dead outside the decode scope.
  // Reclaim diagnostic-host temporaries, not parser fuel/state or semantic data.
  mark('native-ast-transport-reclaim','before');
  Bun.gc(true);
  mark('native-ast-transport-reclaim','after');
  if(!row.compiledAccepted){
   // Keep the complete native failure, including spans and diagnostics, in the transport sidecar.
   row.failureTransport=job.transport;
   row.semanticParity=!oracle.accepted&&!oracle.failure?.category?.includes('observation-seam');
  }else{
   if(!native||typeof native!=='object'||!('module' in native))throw Error('Expected native module result');
   mark('native-ast-materialization','before');
   const module=astNode(nativeAstValue(native.module)),importValues=module.fields[1];
   native=undefined; // The semantic Value graph no longer needs the native graph.
   if(!Array.isArray(importValues))throw Error('Expected module imports');
   const imports=importValues.map(astNode);
   if(row.fullFileParseSuccess){
    mark('full-module-census','before');
    Object.assign(row,fullModuleMetadata(module));
    mark('full-module-census','after',{declarationCount:row.declarationCount,constructorCensus:row.constructorCensus,templateDefinitionCount:row.templateDefinitionCount});
   }
   if(oracle.accepted){
   const adjusted={...module,fields:[module.fields[0],imports.map(v=>{
    const actual=oracle.imports.find(i=>i.alias===v.fields[1]);
    return {...v,fields:[actual?.namespace||v.fields[0],...v.fields.slice(1)]};
   }),module.fields[2]]};
   mark('native-ast-materialization','after',{declarations:Array.isArray(module.fields[2])?module.fields[2].length:undefined});
   mark('native-ast-reclaim','before');
   Bun.gc(true);
   mark('native-ast-reclaim','after');
   mark('actual-normalization','before');
   const actual=canonicalCore(adjusted,environment!,source).semantic;
   actual.imports=normalizeImports(imports.map(v=>{
    const [path,alias]=v.fields;
    if(typeof path!=='string'||typeof alias!=='string')throw Error('Expected string import path and alias');
    return {path,alias};
   }));
   mark('actual-normalization','after',{declarations:actual.declarations.length});
   mark('actual-semantic-hash','before');
   row.compiledASTHash=semanticHash(actual);
   mark('actual-semantic-hash','after');
   mark('semantic-comparison','before');
   row.semanticParity=row.stage0ASTHash===row.compiledASTHash;
   row.normalizedSemanticParity=row.semanticParity;
   mark('semantic-comparison','after',{semanticParity:row.semanticParity});
   if(!row.semanticParity){
    mark('mismatch-write','before');
    // Bounded diagnostics retain both complete hashes. The existing native AST
    // sidecar preserves compiled syntax without reconstructing the expected tree.
    save(job.mismatch,{stage0ASTHash:row.stage0ASTHash,compiledASTHash:row.compiledASTHash,expectedDeclarations,actualDeclarations:actual.declarations.length,normalizationLedger:row.normalizationLedger,compiledTransport:job.transport,sourceScope,sourceSha256:row.sourceSha256,originalSourceSha256:item.sourceSha256,prefixSha256:row.prefixSha256,diagnosticScope:'complete semantic hashes; bounded counts and raw compiled AST sidecar'});
    row.mismatchReport=job.mismatch;
    mark('mismatch-write','after');
   }else mark('mismatch-serialization','skipped',{semanticParity:true});
   }
  }
  if(oracle.failure?.category==='observation-seam'){
   row.status='ast-transport-normalization-failure';row.acceptanceParity=false;row.semanticParity=false;
  }else if(row.compiledAccepted)row.status=row.acceptanceParity&&row.semanticParity?'parity':'parity-mismatch';
 }catch(error){
  row.status=phase;row.error=errorText(error);row.failureStage=failureStage;
  row.errorStack=error instanceof Error?error.stack:undefined;
  row.acceptanceParity=false;row.semanticParity=false;
 }
 row.complete=['parity','parity-mismatch','rejection'].includes(row.status);
 row.finished=true;mark('compare-complete','after',{status:row.status});
}

const childArg=process.argv.find(a=>a.startsWith('--child='));
if(childArg){
 await compare(JSON.parse(readFileSync(childArg.slice(8),'utf8')));
}else{
 const options=new Map<string,string>();
 for(let i=2;i<process.argv.length;i++){
  const argument=process.argv[i],equals=argument.indexOf('='),name=equals<0?argument:argument.slice(0,equals);
  if(!['--artifact','--report','--module','--modules','--file','--declarations','--timeout-ms'].includes(name))throw Error('Unknown option '+name);
  const value=equals<0?process.argv[++i]:argument.slice(equals+1);
  if(!value)throw Error('Missing value for '+name);options.set(name,value);
 }
 const artifact=resolve(options.get('--artifact')??DEFAULT_ARTIFACT),artifactSha256=sha(readFileSync(artifact));
 if(artifact===resolve(DEFAULT_ARTIFACT)&&artifactSha256!==FROZEN_SHA)throw Error('Frozen artifact SHA256 mismatch');
 const report=resolve(options.get('--report')??'checkpoints/bootstrap-parser-isolated-corpus.json');
 const timeoutMs=Number(options.get('--timeout-ms')??120000);
 if(!Number.isSafeInteger(timeoutMs)||timeoutMs<1)throw Error('--timeout-ms must be a positive safe integer');
 const manifestPath=resolve('checkpoints/bootstrap-real-source-corpus.json');
 const manifestBytes=readFileSync(manifestPath),manifest=JSON.parse(manifestBytes.toString());
 if(manifest.modules.length!==10)throw Error('Frozen ten-module manifest drift');
 let items:Item[]=manifest.modules;
 const subset=options.get('--modules')??options.get('--module');
 if(options.has('--file')&&subset)throw Error('Use either --file or --module(s)');
 if(options.has('--file')){
  const file=resolve(options.get('--file')!);items=[{id:'smoke',file,snapshot:file,sourceSha256:sha(readFileSync(file))}];
 }else if(subset){
  const selectors=subset.split(',');
  items=items.filter(item=>selectors.some(s=>s===String(item.id)||s===item.file||s===basename(item.file)||s===item.snapshot));
  for(const selector of selectors)if(!items.some(item=>selector===String(item.id)||selector===item.file||selector===basename(item.file)||selector===item.snapshot))throw Error('Unknown module '+selector);
 }
 const declarations=options.has('--declarations')?Number(options.get('--declarations')):undefined;
 let prefixMetadata:Record<string,unknown>={};
 if(declarations!==undefined){
  if(options.has('--file')||!subset||items.length!==1)throw Error('--declarations requires exactly one frozen --module');
  const original=readFileSync(items[0].snapshot,'utf8');
  if(sha(original)!==items[0].sourceSha256)throw Error('Frozen source snapshot hash mismatch');
  const candidates=[...original.matchAll(/^(?:def |type |law |@unsafe\b).*$/gm)];
  if(!Number.isSafeInteger(declarations)||declarations<0||declarations>candidates.length)throw Error('--declarations must be a safe integer from zero through '+candidates.length);
  const prefix=original.slice(0,candidates[declarations]?.index??original.length);
  prefixMetadata={originalSourceSha256:items[0].sourceSha256,sourceSha256:sha(prefix),prefixSha256:sha(prefix),sourceChars:prefix.length,originalSourceChars:original.length};
 }
 mkdirSync(dirname(report),{recursive:true});
 // Result and transport sidecars survive failures; temporary request/job files do not.
 const sidecars=report+'.modules';mkdirSync(sidecars,{recursive:true});
 const temporary=mkdtempSync(join(tmpdir(),'bend-isolated-corpus-'));
 const rows:Row[]=[];
 const saveReport=()=>save(report,{
  criterion:'failure-isolated complete normalized module semantics',artifact,artifactSha256,
  frozenArtifactSha256:FROZEN_SHA,manifest:manifestPath,manifestSha256:sha(manifestBytes),
  limits:{timeoutMs,memoryMiB:MEMORY_MIB,rssMiB:MEMORY_MIB,pollMs:POLL_MS,maxHeavyChildren:1,fuel:FUEL},
  normalization:'Complete existing semantic normalization ledger; no field exclusions added',
  requestedModules:items.map(i=>({id:i.id,file:i.file,sourceSha256:i.sourceSha256,...prefixMetadata})),sourceScope:declarations===undefined?'full-file':'declaration-prefix',declarations,...prefixMetadata,
  fullCorpus:declarations===undefined&&!options.has('--file')&&items.length===10,finished:rows.length===items.length&&rows.every(r=>r.finished),complete:rows.length===items.length&&rows.every(r=>r.complete),
  passed:rows.length===items.length&&rows.every(r=>r.complete&&r.acceptanceParity&&r.semanticParity&&['parity','rejection'].includes(r.status)),
  counts:{requested:items.length,attempted:rows.filter(r=>r.attempted).length,finished:rows.filter(r=>r.finished).length,completed:rows.filter(r=>r.complete).length,parseCompleted:rows.filter(r=>r.parseCompleted).length,fullFileParseSuccess:rows.filter(r=>r.fullFileParseSuccess).length,prefixParseSuccess:rows.filter(r=>r.prefixParseSuccess).length,stage0Accepted:rows.filter(r=>r.stage0Accepted).length,compiledAccepted:rows.filter(r=>r.compiledAccepted).length,acceptanceParity:rows.filter(r=>r.acceptanceParity).length,semanticParity:rows.filter(r=>r.semanticParity).length,normalizedSemanticParity:rows.filter(r=>r.complete&&r.compiledAccepted&&r.normalizedSemanticParity).length},rows,
 });
 saveReport();
 try{
  for(const item of items){
   const prefix=join(sidecars,String(item.id)),job:Job={item,artifact,declarations,request:join(temporary,String(item.id)+'.request.json'),transport:prefix+'.ast.json',workerStatus:prefix+'.worker.json',row:prefix+'.result.json',mismatch:prefix+'.mismatch.json'};
   for(const path of [job.row,job.row+'.phases.jsonl',job.workerStatus,job.workerStatus+'.phases.jsonl'])rmSync(path,{force:true});
   const jobPath=join(temporary,String(item.id)+'.job.json');save(jobPath,job);
   const began=Date.now();let guardian:HeavyGateResult|undefined,row:Row;
   try{
    guardian=await runHeavyGate(['node',worker,'--supervise',process.execPath,import.meta.path,jobPath,job.row,String(timeoutMs)],{label:'Isolated parser corpus '+item.id,memoryMiB:MEMORY_MIB,rssMiB:MEMORY_MIB,pollMs:POLL_MS});
    row=existsSync(job.row)?JSON.parse(readFileSync(job.row,'utf8')):{status:'runtime-error',complete:false,acceptanceParity:false,semanticParity:false};
    if(guardian.status==='RESOURCE_LIMIT')Object.assign(row,{status:'resource-limit',complete:false,acceptanceParity:false,semanticParity:false});
    else if(guardian.status!=='PASS'&&!['timeout','ast-transport-normalization-failure','fuel-exhaustion','runtime-error'].includes(row.status))Object.assign(row,{status:'runtime-error',complete:false,error:row.error??'Guardian '+guardian.status+': '+guardian.reason,acceptanceParity:false,semanticParity:false});
    if(guardian.status!=='PASS')row.complete=false;
   }catch(error){row={status:'runtime-error',complete:false,error:errorText(error),acceptanceParity:false,semanticParity:false};}
   row={id:item.id,name:basename(item.file),file:item.file,originalSourceSha256:item.sourceSha256,sourceScope:declarations===undefined?'full-file':'declaration-prefix',declarations,...prefixMetadata,parseCompleted:false,fullFileParseSuccess:false,prefixParseSuccess:false,...row,attempted:true,finished:true,elapsedMs:Date.now()-began,guardian};
   collectWorkerPhases(job,row);
   if(existsSync(job.row+'.phases.jsonl'))row.phasesPath=job.row+'.phases.jsonl';
   save(job.row,row);rows.push(row);saveReport();console.log(JSON.stringify(row));
  }
 }finally{rmSync(temporary,{recursive:true,force:true});}
 if(rows.length!==items.length||rows.some(r=>!r.acceptanceParity||!r.semanticParity||!['parity','rejection'].includes(r.status)))process.exitCode=2;
}
