import {Worker,isMainThread,parentPort,workerData} from 'node:worker_threads';
import {readFileSync,writeFileSync} from 'node:fs';
import {join} from 'node:path';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
import {createInterface} from 'node:readline';
import {writeNativeAst,readNativeAst} from './bootstrap_ast_transport.ts';
import {runTemplateSteps,runCheckerSteps,runCheckedInspectionSteps,runLibraryEmitterSteps,sourceFilesFor,declaredSourcePaths,OFFICIAL_SOURCE_FILE_TAG} from './checker_core_step_runtime.mjs';

const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
const tag=value=>value?.$?.split('.').at(-1);
const ABI=['parsed_module','expand_modules_start','template_step','check_expanded_start','inspect_checked_start','checker_step','emit_modules_start','emit_library_start','emitter_step'];
const exports=['zero','one','pack','make_pack','apply','identity','identity_probe','erased_probe','specialized_probe','local_twice','local_unused','local_order','over_order','over_generic','constructor_match'];
const list=values=>values.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
if(isMainThread){
 const request=JSON.parse(readFileSync(process.argv[2],'utf8'));
 const worker=new Worker(new URL(import.meta.url),{workerData:request,resourceLimits:{stackSizeMb:256}});
 const output=value=>console.log(JSON.stringify(value,(_,v)=>typeof v==='bigint'?String(v):v));
 const lines=createInterface({input:process.stdin});
 lines.on('line',line=>worker.postMessage(JSON.parse(line)));
 worker.on('message',output);
 worker.on('error',error=>{output({event:'result',result:{passed:false,failure:{phase:'worker-runtime',error:String(error)}}});process.exitCode=2;});
 worker.on('exit',code=>{if(code)process.exitCode=code;lines.close();process.stdin.destroy();});
}else{
 let phase='imports',approve,reject;
 const send=value=>parentPort.postMessage(value);
 const mark=next=>{phase=next;send({event:'phase',phase,rssBytes:process.memoryUsage().rss});};
 parentPort.on('message',message=>message.approved?approve():reject(Error(message.error)));
 const fail=(stage,result)=>{const error=Error(stage+' failed: '+String(result?.message??result?.diagnostic?.message??tag(result)));error.diagnostic=result;throw error;};
 const transport=(name,value)=>{
  const path=join(workerData.sidecars,name+'.ast.json');
  return {path,...writeNativeAst(path,value)};
 };
 try{
  const component=(await import(pathToFileURL(workerData.component).href)).default;
  if(!component||!ABI.every(name=>typeof component[name]==='function'))throw Error('Diagnostic component lacks all nine real step exports');
  const parser=(await import(pathToFileURL(workerData.parser).href)).default;
  if(typeof parser?.parse_with_fuel!=='function')throw Error('Accepted compiled parser lacks parse_with_fuel');
  const source=readFileSync(workerData.file,'utf8');
  if(sha(source)!==workerData.sourceSha256)throw Error('Smoke source drift');
  let fuel={$:'FeedbackFuelEnd'};for(let i=0;i<2000000;i++)fuel={$:'FeedbackFuelCell',tail:fuel};
  mark('parse');
  let feedback=parser.parse_with_fuel(fuel,workerData.file,source);fuel=undefined;
  if(tag(feedback)!=='FeedbackComplete')throw Error('Accepted parser feedback did not complete: '+tag(feedback));
  let parsed=feedback.value?.result;feedback=undefined;
  if(tag(parsed)!=='ParseSuccess')fail('parse',parsed);
  const parsedTransport=transport('parsed',parsed);
  parsed=undefined;
  const approval=new Promise((resolve,rejection)=>{approve=resolve;reject=rejection;});
  send({event:'parse',phase,file:workerData.file,sourceSha256:sha(source),parserSha256:sha(readFileSync(workerData.parser)),transport:parsedTransport.path});
  await approval;
  // Only the actual native parser result is input. Native List/LoadedModule
  // packaging is orchestration, not host-created syntax or parser behavior.
  let restored=await readNativeAst(parsedTransport.path);
  if(restored.sha256!==parsedTransport.sha256||tag(restored.value)!=='ParseSuccess')throw Error('Approved parser transport changed before actual consumer input');
  parsed=restored.value;restored=undefined;
  let modules={$:'Con',head:component.parsed_module('',parsed.module),tail:{$:'Nil'}};
  // The passive bag carries only the bytes of this source's declared `.js`
  // alternatives; this consumer library declares none.
  const files=sourceFilesFor(workerData.file,declaredSourcePaths(parsed.module),OFFICIAL_SOURCE_FILE_TAG);
  parsed=undefined;
  mark('expand');let expanded=runTemplateSteps({...component,expand_modules_start:input=>{modules=undefined;return component.expand_modules_start(input);}},modules);
  if(tag(expanded)!=='ExpandSuccess')fail('expand',expanded);
  const expandedTransport=transport('expanded',expanded);
  send({event:'stage',phase,result:tag(expanded),transport:expandedTransport});
  mark('check');let checked=runCheckerSteps({...component,check_expanded_start:input=>{expanded=undefined;return component.check_expanded_start(input);}},expanded.modules);
  if(tag(checked)!=='CheckSuccess')fail('check',checked);
  let inspection=runCheckedInspectionSteps({...component,inspect_checked_start:program=>{checked=undefined;return component.inspect_checked_start(program);}},checked.program);
  if(tag(inspection)==='InspectionFailure')fail('inspection',{diagnostic:inspection.diagnostic});
  const checkedTransport=transport('checked',inspection.modules);
  send({event:'stage',phase,result:'CheckSuccess',transport:checkedTransport,emitterInput:'authentic Inspection.program (same owner after explicit readback)'});
  mark('emit-library');
  // Only consumer APIs are requested; no compiler API enters the library.
  const emitted=runLibraryEmitterSteps({...component,emit_library_start:(program,names,sources)=>{inspection=undefined;return component.emit_library_start(program,names,sources);}},inspection.program,list(exports),files);
  if(tag(emitted)!=='EmitSuccess')fail('emit',emitted);
  const artifact=join(workerData.sidecars,'consumer.mjs');
  writeFileSync(artifact,emitted.source,{flag:'wx'});
  send({event:'artifact',phase,path:artifact,sha256:sha(emitted.source),bytes:Buffer.byteLength(emitted.source),outputPatches:0,result:tag(emitted)});
  mark('consume-esm');
  const api=(await import(pathToFileURL(artifact).href)).default;
  if(!api||Object.keys(api).sort().join(',')!==[...exports].sort().join(',')||!exports.every(name=>typeof api[name]==='function'))throw Error('Consumer ESM must export exactly the actual program APIs');
  const rows=[];
  const bit=value=>{if(!['BitZero','BitOne'].includes(tag(value)))throw Error('Invalid consumer Bit value');return tag(value);};
  const duo=value=>{if(tag(value)!=='Duo')throw Error('Invalid consumer Duo value');return [bit(value.left),bit(value.right)];};
  const expect=(name,observed,expected)=>{if(JSON.stringify(observed)!==JSON.stringify(expected))throw Error(name+': '+JSON.stringify(observed)+' != '+JSON.stringify(expected));rows.push({name,observed,expected,passed:true});};
  const zero=api.zero(),one=api.one();
  expect('zero-nullary',bit(zero),'BitZero');expect('one-nullary',bit(one),'BitOne');
  expect('positional-noncommutative',duo(api.pack(one,zero)),['BitOne','BitZero']);
  expect('positional-reversed-input',duo(api.pack(zero,one)),['BitZero','BitOne']);
  const partial=api.pack(one);
  expect('pack-one-argument-is-curried-function',typeof partial,'function');
  expect('pack-curried-second-argument',duo(partial(zero)),['BitOne','BitZero']);
  const higher=api.make_pack(one);
  expect('returned-curried-function',typeof higher,'function');
  expect('higher-order-positional-call',duo(api.apply(higher,zero)),['BitOne','BitZero']);
  expect('over-applied-returned-function',duo(api.make_pack(one,zero)),['BitOne','BitZero']);
  let liveCalls=0;
  expect('live-host-callback',duo(api.apply(value=>{liveCalls++;return api.pack(value,one);},zero)),['BitZero','BitOne']);
  expect('live-host-callback-evaluated-once',liveCalls,1);
  expect('erased-kind-and-type-effective-one-argument',bit(api.identity(one)),'BitOne');
  expect('ordinary-type-reference-erasure-in-bend-application',bit(api.identity_probe(zero)),'BitZero');
  expect('actual-template-specialization',bit(api.specialized_probe(one)),'BitOne');
  let erasedCalls=0;
  const poison=()=>{erasedCalls++;throw Error('Erased Bend argument was evaluated');};
  expect('erased-expression-keeps-second-live-argument',bit(api.erased_probe(poison,one)),'BitOne');
  expect('erased-expression-not-evaluated',erasedCalls,0);
  let localCalls=0;
  expect('shared-local-value',duo(api.local_twice(()=>{localCalls++;return one;},zero)),['BitOne','BitOne']);
  expect('shared-local-evaluated-once',localCalls,1);
  let unusedCalls=0;
  expect('unused-local-result',bit(api.local_unused(()=>{unusedCalls++;return one;},zero)),'BitZero');
  expect('unused-live-local-still-evaluated',unusedCalls,1);
  const localOrder=[];
  expect('ordered-local-values',duo(api.local_order(
    ()=>{localOrder.push('first');return one;},
    ()=>{localOrder.push('second');return zero;},zero,one)),['BitOne','BitZero']);
  expect('local-evaluation-order',localOrder,['first','second']);
  const namedOrder=[];
  expect('named-over-application-value',duo(api.over_order(
    ()=>{namedOrder.push('callee');return one;},
    ()=>{namedOrder.push('argument');return zero;},zero,one)),['BitOne','BitZero']);
  expect('named-over-application-order',namedOrder,['callee','argument']);
  const genericOrder=[];
  expect('generic-over-application-value',duo(api.over_generic(
    left=>{genericOrder.push('callee');return right=>{genericOrder.push('apply');return api.pack(left,right);};},
    ()=>{genericOrder.push('argument');return zero;},one,one)),['BitOne','BitZero']);
  expect('generic-over-application-order',genericOrder,['callee','argument','apply']);
  expect('constructor-eliminator-first-arm',bit(api.constructor_match(zero)),'BitOne');
  expect('constructor-eliminator-default-chain',bit(api.constructor_match(one)),'BitZero');
  if(sha(readFileSync(artifact))!==sha(emitted.source))throw Error('Returned JS changed during consumer execution');
  send({event:'result',result:{passed:true,compilerBootstrapGreen:false,selfhostGreen:false,smokeOnly:true,runtime:{exports,rows,artifactExecutedUnchanged:true},parsedTransport}});
 }catch(error){send({event:'result',result:{passed:false,compilerBootstrapGreen:false,selfhostGreen:false,smokeOnly:true,failure:{phase,error:String(error),diagnostic:error.diagnostic}}});process.exitCode=2;}
 finally{parentPort.removeAllListeners('message');parentPort.close();}
}
