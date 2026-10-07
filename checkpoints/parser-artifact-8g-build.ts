#!/usr/bin/env bun
/** Diagnostic source copy; generated output untouched; ordinary kernel retains e. */
import {createHash,randomUUID} from 'node:crypto';
import {resolve} from 'node:path';
import {writeFileSync,appendFileSync,rmSync} from 'node:fs';
import {partitionPatternScanSource} from './pattern_scan_partition_source.ts';
import {extractAtomShape} from './parse_atom_shape_source.ts';
import {extractBodyShape} from './parse_body_shape_source.ts';
import {extractCaseShape,extractMatchTailShape,extractMatchTailScanShape,extractBraceRightShape,extractBraceAnnotShape,extractInequalityShape,extractInequalityRightShape,extractAllNamedTypeShape,extractIndexResultShape,extractRewriteMotiveShape,extractMatchScrutineesShape,extractDefinitionHeaderShape,extractDefinitionBodyShape} from './parse_case_shape_source.ts';
import {extractDoTokenShape,extractArrayShape,extractBraceEqualsShape} from './parse_do_token_shape_source.ts';
import {extractOperatorKeyShape} from './operator_key_shape_source.ts';
import {extractExternalImportShape} from './external_import_shape_source.ts';
import {extractSymbolPairShape,extractSymbolTripleShape} from './symbol_pair_shape_source.ts';
import {checkFrozen,frozen,replayKernel} from './load_replay_kernel.ts';
import {runHeavyGate,guardHeavyGate} from './heavy_gate.ts';
import {dlopen,FFIType,ptr} from 'bun:ffi';
const memoryLib=dlopen('/tmp/bend-artifact-phase-memory.dylib',{artifact_memory:{args:[FFIType.ptr],returns:FFIType.i32},artifact_start:{args:[],returns:FFIType.i32},artifact_phase:{args:[FFIType.i32],returns:FFIType.void},artifact_stop:{args:[FFIType.ptr],returns:FFIType.void}});
function memory(){const m=new BigUint64Array(2);if(memoryLib.symbols.artifact_memory(ptr(m)))throw Error('Memory sample failed');return {footprintBytes:Number(m[0]),rssBytes:Number(m[1])};}
const isProposal=process.argv[2]==='--build-proposal';
const stem='/Users/ilyagulya/Projects/My/bend/checkpoints/parser-artifact-8g',sourcePath=resolve('bend2/selfhost/.parser_definition_body_shape_source.bend'),outputBase=resolve('bend2/selfhost/.parser_definition_body_shape_generated.bend'),candidatePath=outputBase.replace('.bend','_fuel.bend'),artifactPath='/Users/ilyagulya/Projects/My/bend/checkpoints/parser-explicit-fuel-822e8460.js';
const sha=(s:string)=>createHash('sha256').update(s).digest('hex');
const mode=process.argv[2];
if(!mode){
 const prepare=await runHeavyGate([process.execPath,import.meta.path,'--prepare'],{label:'Local typed scanner helpers normal regeneration',memoryMiB:3072,rssMiB:3072,pollMs:10});
 writeFileSync(stem+'.prepare.guardian.json',JSON.stringify(prepare,null,2)+'\n');
 if(prepare.status!=='PASS'){process.exit(prepare.exitCode||2);}
 const build=await runHeavyGate([process.execPath,import.meta.path,'--build'],{label:'Local scanner candidate ordinary complete load/check/JS codegen',memoryMiB:3072,rssMiB:3072,pollMs:10});
 writeFileSync(stem+'.build.guardian.json',JSON.stringify(build,null,2)+'\n');console.log(JSON.stringify(build));process.exit(build.exitCode);
}
await guardHeavyGate(import.meta.path,{label:'Local scanner build worker'});await checkFrozen();
const compilerHash=sha(await Bun.file('bend2/comp.ts').text());
if(sha(await Bun.file(candidatePath).text())!=='822e8460ff94ff3f00695e27f5b4fe4dbd3515ae4d6d5c3b3c5eb7c1867b840e'||compilerHash!=='0939b98d013ab58d82619e35c0d4900b72c9d8e5b478f0e1df7822fe713c9b48')throw Error('Snapshot hash mismatch');
if(memoryLib.symbols.artifact_start())throw Error('Sampler start failed');
let proposalKernel:Awaited<ReturnType<typeof replayKernel>>|undefined;
const start=performance.now();let phase=mode==='--prepare'?'source':'load';
function event(data:object){const row={phase,elapsedMs:performance.now()-start,bunVersion:Bun.version,runtimeArgs:process.execArgv,...data};appendFileSync(stem+'.jsonl',JSON.stringify(row)+'\n');writeFileSync(stem+'.progress.json',JSON.stringify(row)+'\n');}
try{
 if(mode==='--prepare'){
  writeFileSync(stem+'.jsonl','');
  const stages=[
   ['patternScanner',partitionPatternScanSource],['atomScanner',extractAtomShape],['bodyScanner',extractBodyShape],
   ['caseScanner',extractCaseShape],['doTokenScanner',extractDoTokenShape],['arrayScanner',extractArrayShape],
   ['operatorKey',extractOperatorKeyShape],['matchTail',extractMatchTailShape],['tailScan',extractMatchTailScanShape],
   ['braceRight',extractBraceRightShape],['braceAnnot',extractBraceAnnotShape],['braceEquals',extractBraceEqualsShape],
   ['inequality',extractInequalityShape],['inequalityRight',extractInequalityRightShape],['allNamedType',extractAllNamedTypeShape],
   ['indexResult',extractIndexResultShape],['rewriteMotive',extractRewriteMotiveShape],['matchScrutinees',extractMatchScrutineesShape],
   ['definitionHeader',extractDefinitionHeaderShape],['externalImport',extractExternalImportShape],['symbolPair',extractSymbolPairShape],
   ['symbolTriple',extractSymbolTripleShape],['definitionBody',extractDefinitionBodyShape]
  ] as const;
  let currentSource=await Bun.file('bend2/selfhost/parser.bend').text(),latest:{source:string,graph:Awaited<ReturnType<typeof extractAllNamedTypeShape>>['graph'],audit:{transformedSha256:string}}|undefined;
  const audits:Record<string,object>={};
  for(const [name,transform]of stages){latest=await transform(currentSource);currentSource=latest.source;audits[name]=latest.audit;}
  if(!latest)throw Error('No source transformation stages');
  const prepared={...latest,audit:{...latest.audit,...audits}};
  writeFileSync(sourcePath,prepared.source);writeFileSync(stem+'.audit.json',JSON.stringify(prepared.audit,null,2)+'\n');event({stage:'source-audit-pass',sourceHash:prepared.audit.transformedSha256});
  const graphPath=resolve('evals/.local_shape_graph_'+randomUUID()+'.json'),generatorPath=resolve('evals/.local_shape_generator_'+randomUUID()+'.ts');
  const baseGraph=await Bun.file('bend2/selfhost/parser_full_current_graph.json').json();writeFileSync(graphPath,JSON.stringify({...baseGraph,sourceCheckpoint:prepared.audit.transformedSha256.slice(0,8),sourceSha256:prepared.audit.transformedSha256,definitions:prepared.graph.definitions,edges:prepared.graph.edges,unresolvedReferences:prepared.graph.unresolvedReferences},null,2)+'\n');
  const original=await Bun.file('evals/parser_full_generate.ts').text(),changes=[['const input = resolve(import.meta.dir, "../bend2/selfhost/parser.bend");','const input = '+JSON.stringify(sourcePath)+';'],['const output = resolve(import.meta.dir, "../bend2/selfhost/parser_full_generated.bend");','const output = '+JSON.stringify(outputBase)+';'],['const expected = "'+frozen['bend2/selfhost/parser.bend']+'";','const expected = "'+prepared.audit.transformedSha256+'";'],['const currentGraphPath = resolve(import.meta.dir, "../bend2/selfhost/parser_full_current_graph.json");','const currentGraphPath = '+JSON.stringify(graphPath)+';']];
  let redirected=original;for(const[a,b]of changes){if(redirected.split(a).length!==2)throw Error('Generator redirect anchor drift');redirected=redirected.replace(a,b);}let back=redirected;for(const[a,b]of [...changes].reverse())back=back.replace(b,a);if(back!==original)throw Error('Non-invertible generator path configuration');writeFileSync(generatorPath,redirected);
  try{phase='generation';event({stage:'generation-start',constantRedirects:changes,logicUnchanged:true});const child=Bun.spawn([process.execPath,generatorPath,'--fuel-parametric'],{stdout:'inherit',stderr:'inherit'});const exit=await child.exited;if(exit)throw Error('Normal generator logic exited'+exit);event({stage:'generation-pass',candidateSha256:sha(await Bun.file(candidatePath).text())});}finally{rmSync(graphPath,{force:true});rmSync(generatorPath,{force:true});}
 }else if(mode==='--build'||isProposal){
  if(isProposal)proposalKernel=await replayKernel('direct',undefined,{retention:'retain'});
  const B=proposalKernel?.kernel??await import('../bend2/bend.ts'),Comp=await import('../bend2/comp.ts'),book=B.book_nil();event({stage:'load-start',candidatePath,kernel:frozen['bend2/bend.ts'],temporaryKernel:proposalKernel?.path,loadMode:isProposal?'PROPOSED_DIRECT_LOADER_DIAGNOSTIC':'ordinary production',checkedOutputRetention:'native e'});await B.book_load(book,candidatePath,'',new Map());event({stage:'load-pass',events:book.order.length});
  memoryLib.symbols.artifact_phase(1);
  phase='validation';const order=book.order;let passes=0;const declarationGC=process.env.BEND_PARSER_DECL_GC==='1';event({stage:'validation-policy',declarationGC,checksExcluded:0,checkedOutputRetention:'native e'});book.order=new Proxy(order,{get(array,key,receiver){if(typeof key==='string'&&/^\d+$/.test(key)&&phase==='validation'){const index=Number(key);if(index===0)passes++;if(passes===2){if(declarationGC)Bun.gc(true);event({stage:'declaration-begin',index,name:array[index]});}}return Reflect.get(array,key,receiver);}});
  B.book_valid(book);book.order=order;if(book.hols||book.open)throw Error('Unfilled candidate');event({stage:'full-validation-pass',events:order.length});
  const validationEndMs=performance.now()-start,preGC=memory();event({stage:'pre-phase-gc',...preGC});Bun.gc(true);const postGC=memory();event({stage:'post-phase-gc',...postGC});memoryLib.symbols.artifact_phase(2);
  phase='codegen';event({stage:'codegen-start'});const code=Comp.js_lib(book,['parse_with_fuel'],['parse_with_fuel']);writeFileSync(artifactPath,code);event({stage:'codegen-pass',artifactPath,artifactSha256:sha(code),bytes:Buffer.byteLength(code)});writeFileSync(stem+'.result.json',JSON.stringify({status:'JS_GENERATED_NOT_YET_EXECUTED',sourceCandidate:candidatePath,artifactPath,artifactSha256:sha(code),eventsFullyValidated:order.length,kernel:frozen['bend2/bend.ts'],compilerHash,toolchain:isProposal?'PROPOSED_DIRECT_LOADER_DIAGNOSTIC; unchanged full checker retaining e and normal codegen':'ordinary production load/check/codegen, generator only temporary input/path metadata redirection',selfhostGreen:false},null,2)+'\n');
  const peaks=new BigUint64Array(6);memoryLib.symbols.artifact_stop(ptr(peaks));writeFileSync(stem+'.metrics.json',JSON.stringify({checkpoint:'COMPILED EXPLICIT-FUEL SELFHOST PARSER — DIAGNOSTIC DIRECT-LOAD BUILD',artifactPath,artifactSha256:sha(code),bytes:Buffer.byteLength(code),validationEndMs,totalElapsedMs:performance.now()-start,preGC,postGC,phasePeaks:{load:{footprintBytes:Number(peaks[0]),rssBytes:Number(peaks[1])},validation:{footprintBytes:Number(peaks[2]),rssBytes:Number(peaks[3])},codegen:{footprintBytes:Number(peaks[4]),rssBytes:Number(peaks[5])}},selfhostGreen:false},null,2)+'\n');
 }else throw Error('Unknown build mode');
}catch(error){let detail=String(error);if(error&&typeof error==='object'&&'$'in error&&error.$==='Err'){const B=await import('../bend2/bend.ts');detail=B.err_show(error as Parameters<typeof B.err_show>[0]);}event({stage:'error',error:detail});console.error(detail);process.exitCode=2;}
finally{proposalKernel?.close();await checkFrozen();if(sha(await Bun.file('bend2/comp.ts').text())!==compilerHash)throw Error('Compiler drift');}
