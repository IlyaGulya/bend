#!/usr/bin/env node
// Diagnostic only: fresh native parsing/expansion, then the public checker input.
// Run under the parent's heavy_gate; this script never launches another guardian.
import {readFileSync,realpathSync,openSync,closeSync,ftruncateSync,writeSync} from 'node:fs';
import {resolve,dirname} from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {Worker,isMainThread,parentPort,workerData} from 'node:worker_threads';
import {getHeapStatistics} from 'node:v8';
import {ABI,sha,hashPath,workloadRows,corpusFor} from './native_seed_runtime.mjs';
import {runTemplateSteps,declaredModuleNamespace} from './checker_core_step_runtime.mjs';

const workerPolicy={stackSizeMb:256,maxOldGenerationSizeMb:6144,maxYoungGenerationSizeMb:128};
const flags=['--experimental-strip-types','--max-old-space-size=6144','--max-semi-space-size=128'];
const tag=value=>typeof value?.$==='string'?value.$.split('.').at(-1):null;
const requireThat=(condition,message)=>{if(!condition)throw Error(message);};
// Neither runtime helper exports fuel/list: these are the throughput driver's
// exact passive carriers, with cycle validation added only for returned lists.
const fuelEnd=Object.freeze({$:'FeedbackFuelEnd'});
const fuelPrototype={get tail(){return fuel(this.remaining-1);}};
function fuel(remaining){if(remaining===0)return fuelEnd;const node=Object.create(fuelPrototype);node.$='FeedbackFuelCell';node.remaining=remaining;return node;}
function list(values){let result={$:'Nil'};for(let i=values.length-1;i>=0;i--)result={$:'Con',head:values[i],tail:result};return result;}
function* items(value){
  const seen=new WeakSet();
  while(tag(value)==='Con'){
    requireThat(!seen.has(value)&&Object.hasOwn(value,'head')&&Object.hasOwn(value,'tail'),'Malformed or cyclic native list');
    seen.add(value);yield value.head;value=value.tail;
  }
  requireThat(tag(value)==='Nil','Malformed native list terminator');
}
function count(value){let n=0;for(const unused of items(value))n++;return n;}
function verify(pinset,label){
  requireThat(pinset&&typeof pinset==='object'&&!Array.isArray(pinset)&&Object.keys(pinset).length>0,'Missing '+label);
  for(const [path,digest] of Object.entries(pinset)){
    requireThat(/^[a-f0-9]{64}$/.test(digest)&&resolve(path)===path&&realpathSync(path)===path,'Invalid '+label+' identity: '+path);
    requireThat(hashPath(path)===digest,label+' drift: '+path);
  }
}
function authenticate(requestPath,requestSha256){
  const bytes=readFileSync(requestPath);
  requireThat(sha(bytes)===requestSha256,'Request drift');
  const request=JSON.parse(bytes.toString('utf8'));
  requireThat(request.schemaVersion===1&&JSON.stringify(request.exports)===JSON.stringify(ABI),'Invalid throughput request ABI');
  requireThat(request.limits?.memoryMiB===8192&&request.limits?.rssMiB===8192&&request.limits?.timeoutMs===600000,'Original guardian limits required');
  requireThat(request.limits.pollMs===undefined||request.limits.pollMs===10,'Original guardian polling interval required');
  requireThat(JSON.stringify(process.execArgv)===JSON.stringify(flags),'Original benchmark Node flags required');
  requireThat(realpathSync(request.node)===realpathSync(process.execPath),'Node executable differs from request');
  requireThat(realpathSync(request.repository)===realpathSync('.'),'Run with cwd equal to the request source repository');
  for(const key of ['root','image'])requireThat(realpathSync(request[key])===request[key],key+' must be a canonical path');
  verify(request.pins,'Pinned input');verify(request.inputs,'Source input');
  requireThat(request.pins[request.image]===hashPath(request.image),'Image is not pinned');
  const work=workloadRows(request.root,'js'),corpus=corpusFor(work);
  const closure=Object.fromEntries([...work.sources,...work.externals].map(row=>[row.file,row.sha256]).sort(([a],[b])=>a.localeCompare(b)));
  const requested=Object.fromEntries(Object.entries(request.inputs).sort(([a],[b])=>a.localeCompare(b)));
  requireThat(JSON.stringify(closure)===JSON.stringify(requested),'Exact complete JS workload closure differs from request');
  const identities=corpus.files.map(row=>({...row,file:realpathSync(resolve(corpus.directory,row.path)),bytes:readFileSync(resolve(corpus.directory,row.path)).length}));
  return {request,work,corpus,identities,closureSha256:sha(JSON.stringify(corpus)),nodeSha256:hashPath(process.execPath)};
}

// Object-identity census, not a heap-byte estimate or a recursively unfolded AST.
// Never inspects a Run, Stack, checked program, closure environment or prototype.
function census(root){
  const seen=new WeakSet(),pending=[root],tags=new Map(),incomingTags=new Map();
  const result={status:'COMPLETE',uniqueObjects:0,arrayObjects:0,untaggedObjects:0,ownEnumerableFields:0,objectReferences:0,repeatedObjectReferences:0,
    primitiveFields:{string:0,number:0,bigint:0,boolean:0,null:0,undefined:0},stringUtf16CodeUnits:0,
    omissions:{accessorFields:0,callableFields:0,symbolFields:0,symbolKeys:0,nonEnumerableFields:0,otherFields:0}};
  const ownTag=object=>{
    const descriptor=Object.getOwnPropertyDescriptor(object,'$');
    return descriptor&&Object.hasOwn(descriptor,'value')&&typeof descriptor.value==='string'?descriptor.value:null;
  };
  result.rootTag=ownTag(root);
  while(pending.length){
    const object=pending.pop();
    requireThat(object!==null&&typeof object==='object','Non-object in public structural graph');
    if(seen.has(object)){result.repeatedObjectReferences++;continue;}
    seen.add(object);result.uniqueObjects++;
    const array=Array.isArray(object);
    if(array)result.arrayObjects++;
    const name=ownTag(object);
    if(name!==null)tags.set(name,(tags.get(name)??0)+1);
    else result.untaggedObjects++;
    for(const key of Reflect.ownKeys(object)){
      if(array&&key==='length')continue;
      const field=Object.getOwnPropertyDescriptor(object,key);
      if(typeof key==='symbol'){result.omissions.symbolKeys++;continue;}
      if(!field.enumerable){result.omissions.nonEnumerableFields++;continue;}
      result.ownEnumerableFields++;
      if(!Object.hasOwn(field,'value')){result.omissions.accessorFields++;continue;}
      const value=field.value;
      if(value!==null&&typeof value==='object'){
        result.objectReferences++;
        // Count the edge even if this child was already visited. Its own fields
        // are still visited only once: this is not exponential tree unfolding.
        const childTag=ownTag(value);
        if(childTag!==null)incomingTags.set(childTag,(incomingTags.get(childTag)??0)+1);
        pending.push(value);continue;
      }
      const type=value===null?'null':typeof value;
      if(type==='function'){result.omissions.callableFields++;continue;}
      if(type==='symbol'){result.omissions.symbolFields++;continue;}
      if(!Object.hasOwn(result.primitiveFields,type)){result.omissions.otherFields++;continue;}
      result.primitiveFields[type]++;
      if(type==='string')result.stringUtf16CodeUnits+=value.length;
    }
  }
  const sorted=[...tags].sort(([a],[b])=>a.localeCompare(b));
  const incoming=[...incomingTags].sort(([a],[b])=>a.localeCompare(b));
  const isCollection=([name])=>['Con','Nil'].includes(name.split('.').at(-1));
  const collection=sorted.filter(isCollection),nonCollection=sorted.filter(row=>!isCollection(row));
  result.tagCounts=Object.fromEntries(sorted);
  result.taggedIncomingEdgeCounts=Object.fromEntries(incoming);
  result.collection={constructorLocalNames:['Con','Nil'],exactTagCounts:Object.fromEntries(collection),
    taggedIncomingEdgeCounts:Object.fromEntries(incoming.filter(isCollection)),uniqueNodes:collection.reduce((n,[,v])=>n+v,0)};
  result.nonCollection={excludedExactTags:collection.map(([name])=>name),excludedSourceSpanOrStringTags:[],tagCounts:Object.fromEntries(nonCollection),
    taggedIncomingEdgeCounts:Object.fromEntries(incoming.filter(row=>!isCollection(row))),
    uniqueTaggedNodes:nonCollection.reduce((n,[,v])=>n+v,0),semantics:'Only generic List Con/Nil nodes subtracted; no subtrees pruned. SpanOf, StringLiteralNames, TermString and all other tags remain.'};
  result.scope='Physical public object graph vectors, not full tree counts. tagCounts counts each object identity once. taggedIncomingEdgeCounts counts every observed parent data field/array slot targeting a tagged child, including shared singleton objects; root has no synthetic incoming edge. Each parent is visited once. Primitive field occurrences include constructor-tag strings. Repeated references include sharing or cycles, not a cycle count. Array length metadata and prototypes are outside this data-field observation.';
  if(Object.values(result.omissions).some(n=>n!==0)){
    result.status='INCONCLUSIVE';
    result.reason='Unhandled payload fields remain omissions; observed vectors are partial, not complete syntax counts.';
  }
  result.semanticTails={status:'UNAVAILABLE',arity:null,depth:null,subtreeSize:null,reason:'No version-authenticated complete semantic child/arity schema is supplied by the public ABI. Object graph fields and linked-list depth are not semantic AST arity, depth or size.'};
  return result;
}

function parseWorkload(api,authenticated){
  const {request,work}=authenticated,rows=new Map(work.sources.map(row=>[row.file,row]));
  const externals=new Map(work.externals.map(row=>[row.file,row])),observedForeign=new Set(),seen=new Set(),active=new Set();
  const modules=[],moduleRows=[];
  const foreign=(file,path)=>{
    const real=realpathSync(resolve(dirname(file),path)),row=externals.get(real);
    requireThat(row&&hashPath(real)===row.sha256,'Unexpected or changed JS alternative: '+real);
    observedForeign.add(real);
  };
  const visit=(file,namespace)=>{
    const real=realpathSync(file),row=rows.get(real);
    requireThat(row&&row.namespace===namespace,'Native parser namespace/closure mismatch: '+real);
    requireThat(!active.has(real),'Native parser import cycle: '+real);
    if(seen.has(real))return;
    seen.add(real);active.add(real);
    const bytes=readFileSync(real);
    requireThat(sha(bytes)===row.sha256,'Source drift before native parse: '+real);
    const source=bytes.toString('utf8');
    requireThat(Buffer.from(source,'utf8').equals(bytes),'Source is not lossless UTF-8: '+real);
    const feedback=api.parse_with_fuel(fuel(8000000),real,source);
    requireThat(tag(feedback)==='FeedbackComplete','Native parser did not complete: '+real+' ('+tag(feedback)+')');
    const parsed=feedback.value?.result;
    requireThat(tag(parsed)==='ParseSuccess','Native parser rejected: '+real+' ('+tag(parsed)+')');
    const module=parsed.module;
    requireThat(tag(module)==='Module'&&module.path===real,'Native parser module identity mismatch: '+real);
    let declarations=0;
    for(const top of items(module.declarations)){
      declarations++;
      if(tag(top)==='DefTop'&&tag(top.definition?.body)==='DefImports'){
        for(const path of items(top.definition.body.paths)){
          requireThat(typeof path==='string','Non-string foreign alternative');
          if(path.endsWith('.js'))foreign(real,path);
        }
      }
    }
    for(const imported of items(module.imports)){
      requireThat(tag(imported)==='ModuleImport'&&typeof imported.path==='string','Invalid parsed import');
      const path=imported.path;
      if(path.endsWith('.js'))foreign(real,path);
      else if(!path.endsWith('.c'))visit(path==='Base'?resolve(request.repository,'bend2/base.bend'):resolve(dirname(real),path),declaredModuleNamespace(namespace,path));
    }
    // workloadRows sorts rows by path, not dependency order. Native parser
    // imports define the same depth-first postorder used by throughput JS.
    modules.push(api.parsed_module(row.namespace,module));
    moduleRows.push({file:real,path:row.path,namespace:row.namespace,sha256:row.sha256,bytes:bytes.length,sourceDeclarations:declarations,parserFuelCells:8000000,parserResult:'ParseSuccess'});
    active.delete(real);
  };
  visit(work.root,'');
  requireThat(seen.size===rows.size&&observedForeign.size===externals.size,'Native parser omitted a frozen source or JS alternative');
  return {modules,moduleRows,sourceDeclarations:moduleRows.reduce((n,row)=>n+row.sourceDeclarations,0),externalCount:observedForeign.size};
}
function expandedModuleCounts(modules,sourceRows){
  const sources=new Map(sourceRows.map(row=>[row.file,row])),seen=new Set(),rows=[];
  for(const loaded of items(modules)){
    requireThat(tag(loaded)==='LoadedModule'&&tag(loaded.module)==='Module','Unknown expanded public module schema');
    const module=loaded.module,source=sources.get(module.path);
    requireThat(source&&source.namespace===loaded.namespace&&!seen.has(module.path),'Expanded module source identity mismatch');
    seen.add(module.path);
    rows.push({file:module.path,namespace:loaded.namespace,sourceDeclarations:source.sourceDeclarations,expandedDeclarations:count(module.declarations)});
  }
  requireThat(seen.size===sources.size,'Expansion omitted source modules');
  return {count:rows.length,sourceDeclarations:sourceRows.reduce((n,row)=>n+row.sourceDeclarations,0),expandedDeclarations:rows.reduce((n,row)=>n+row.expandedDeclarations,0),rows};
}
async function diagnose(data){
  const started=performance.now();
  const report={schemaVersion:1,kind:'native-public-checker-input-shape',status:'RUNNING',diagnosticOnly:true,acceptanceEvidence:false,
    request:data.requestPath,requestSha256:data.requestSha256,workerPolicy,phases:[],outputPatches:0,
    execution:{parser:true,template:true,checker:false,emitter:false,hostParser:false,astTransport:false},
    guardian:{ownership:'caller',required:{memoryMiB:8192,rssMiB:8192,pollMs:10,timeoutMs:600000},verifiedByThisTool:false}};
  const publish=()=>parentPort.postMessage(report);
  const phase=async(name,action)=>{
    report.activePhase=name;publish();const before=performance.now();
    try{const value=await action();report.phases.push({phase:name,status:'COMPLETE',elapsedMs:performance.now()-before});delete report.activePhase;publish();return value;}
    catch(error){report.phases.push({phase:name,status:'FAILED',elapsedMs:performance.now()-before,reason:String(error)});throw error;}
  };
  try{
    const authenticated=await phase('authenticate-before',()=>authenticate(data.requestPath,data.requestSha256));
    const {request,work}=authenticated;
    report.exports=ABI;report.limits=request.limits;
    report.runtime={execPath:realpathSync(process.execPath),nodeSha256:authenticated.nodeSha256,versions:process.versions,execArgv:process.execArgv,heapLimitBytes:getHeapStatistics().heap_size_limit};
    report.image={file:request.image,sha256:request.pins[request.image],bytes:readFileSync(request.image).length,provenance:'Caller-pinned image; this tool does not independently certify its native build receipt.'};
    report.sourceUniverse={directory:work.directory,root:work.root,rootSha256:request.inputs[work.root],closureSha256:authenticated.closureSha256,
      sourceCount:work.sources.length,jsAlternativeCount:work.externals.length,bytes:authenticated.identities.reduce((n,row)=>n+row.bytes,0),identities:authenticated.identities};
    report.pins=request.pins;
    report.observerSources=Object.fromEntries(['selfhost_corpus_shape.mjs','native_seed_runtime.mjs','checker_core_step_runtime.mjs'].map(name=>{const path=fileURLToPath(new URL(name,import.meta.url));return [path,hashPath(path)];}));
    const api=await phase('startup',async()=>(await import(pathToFileURL(request.image).href)).default);
    requireThat(api&&ABI.every(key=>typeof api[key]==='function'),'Emitted compiler ABI incomplete');
    let parsed=await phase('load-parse',()=>parseWorkload(api,authenticated));
    report.parse={moduleCount:parsed.moduleRows.length,sourceDeclarations:parsed.sourceDeclarations,jsAlternativeCount:parsed.externalCount,dependencyOrder:parsed.moduleRows};
    const sourceRows=parsed.moduleRows;
    let modules=list(parsed.modules);parsed=undefined;
    const expanded=await phase('expand',()=>{
      const result=runTemplateSteps(api,modules,{onFinish(_value,steps){report.templateSteps=steps;}});
      requireThat(tag(result)==='ExpandSuccess','Native expansion rejected input: '+tag(result));
      return result;
    });
    modules=undefined;
    report.expansionResult='ExpandSuccess';
    const observed=await phase('observe-public-checker-input',()=>{
      const structure=census(expanded.modules);
      const module=structure.status==='COMPLETE'?expandedModuleCounts(expanded.modules,sourceRows):
        {status:'UNAVAILABLE',sourceDeclarations:report.parse.sourceDeclarations,reason:'Expanded declaration/module traversal withheld because public payload omissions remain.'};
      return {module,structure};
    });
    await phase('authenticate-after',()=>{
      const after=authenticate(data.requestPath,data.requestSha256);
      requireThat(after.closureSha256===authenticated.closureSha256&&after.nodeSha256===authenticated.nodeSha256,'Source universe or runtime changed during diagnostic');
      verify(report.observerSources,'Observer source');
    });
    report.module=observed.module;report.structure=observed.structure;
    report.authentication={before:true,after:true,exactClosure:true,nativeParserClosure:true,nativeParserNamespaces:true};
    report.status=observed.structure.status==='COMPLETE'?'OBSERVED':'INCONCLUSIVE';
    if(report.status==='INCONCLUSIVE')report.reason=observed.structure.reason;
  }catch(error){report.status='FAIL';report.reason=String(error);delete report.structure;delete report.module;}
  report.totalElapsedMs=performance.now()-started;publish();
}

if(!isMainThread){
  await diagnose(workerData);
}else{
  const args=process.argv.slice(2);
  if(args.length!==2)throw Error('Usage: node --experimental-strip-types --max-old-space-size=6144 --max-semi-space-size=128 evals/selfhost_corpus_shape.mjs REQUEST.json FRESH-REPORT.json');
  const requestPath=resolve(args[0]),reportPath=resolve(args[1]);
  // Reserve once with wx. Only this process owns this descriptor; phase updates
  // cannot accidentally overwrite an existing report or follow a replaced path.
  const fd=openSync(reportPath,'wx');
  let report={schemaVersion:1,kind:'native-public-checker-input-shape',status:'RUNNING',diagnosticOnly:true,acceptanceEvidence:false,request:requestPath,phases:[]};
  const save=()=>{
    const bytes=Buffer.from(JSON.stringify(report,null,2)+'\n');
    ftruncateSync(fd,0);let offset=0;
    while(offset<bytes.length)offset+=writeSync(fd,bytes,offset,bytes.length-offset,offset);
  };
  try{
    save();
    const requestSha256=hashPath(requestPath);
    const worker=new Worker(new URL(import.meta.url),{workerData:{requestPath,requestSha256},resourceLimits:workerPolicy});
    await new Promise((done,reject)=>{
      worker.on('message',value=>{report=value;save();});
      worker.once('error',reject);
      worker.once('exit',code=>code===0?done():reject(Error('Shape worker exited: '+code)));
    });
    if(report.status!=='OBSERVED'){
      if(!['FAIL','INCONCLUSIVE'].includes(report.status))throw Error('Shape worker exited without a completed diagnostic');
      process.exitCode=1;
    }
  }catch(error){report.status='FAIL';report.reason=String(error);delete report.structure;delete report.module;process.exitCode=1;}
  finally{save();closeSync(fd);}
}
