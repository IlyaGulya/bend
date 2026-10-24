#!/usr/bin/env bun
// Test-only JS runner for the typed-step library. NOT a production CLI and not
// a shell for a real compiler: the official CLI and the native backend are
// separate targets.
//
// The emitted compiler image is a library of the public step ABI, not a
// process, so this harness drives exactly that ABI (parsed_module/expand/check/
// emit*), supplies the passive List<&2, BIR.SourceFile> bag from the actual
// bytes of the declared `.js` alternatives, and never invents link metadata.
// `--library` asks for the explicit library entry and `--exports=NAME[,NAME]`
// overrides its export set; without them `-o out.js` is the whole-module entry,
// matching the official CLI where `-o out.mjs` selects a library.
//
// usage: bun evals/candidate_host.ts --candidate=PATH [--parser=PATH]
//   [--base=PATH] [--library] [--exports=a,b] <input.bend> -o <output>
//   Opt-in diagnostic stage report: [--stage-profile=DIR] [--stage-progress]
//   [--stage-manifest=PATH ...]. Ordinary output and diagnostics are unchanged.
import {createHash} from 'node:crypto';
import {readFileSync,realpathSync,writeFileSync} from 'node:fs';
import {dirname,isAbsolute,posix,resolve} from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {
 sourceFileEntries,sourceFiles,OFFICIAL_SOURCE_FILE_TAG,
 runTemplateSteps,runCheckerSteps,runLibraryEmitterSteps,runEmitterSteps,
 runCEmitterSteps,runCLibraryEmitterSteps,
} from './checker_core_step_runtime.mjs';
import {createStageProfile,createStepAttribution} from './compiler_stage_profile.mjs';

const ROOT=resolve(dirname(fileURLToPath(import.meta.url)),'..');

let stage:any;
function fail(message:string):never{
 try{stage?.fail(message);}catch(error){console.error('candidate: stage profile close failed: '+String(error));}
 console.error('candidate: '+message);
 process.exit(1);
}
// Runtime terms cross from generated JS, so every read is one validated guard.
const objectOf=(value:unknown):Record<string,unknown>|undefined=>
 value!==null&&typeof value==='object'&&!Array.isArray(value)?value as Record<string,unknown>:undefined;
const tag=(value:unknown):string|undefined=>{
 const object=objectOf(value),name=object?.$;
 return typeof name==='string'?name.slice(name.lastIndexOf('.')+1):undefined;
};
function items(value:unknown):unknown[]{
 const out:unknown[]=[];
 for(;;){
  const object=objectOf(value),kind=tag(value);
  if(kind==='Nil')return out;
  if(kind!=='Con'||object===undefined)fail('malformed native list from the candidate');
  out.push(object.head);
  value=object.tail;
 }
}
const list=(values:unknown[]):unknown=>values.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});

function args_parse(){
 const values=new Map<string,string>(),flags=new Set<string>(),positional:string[]=[],manifests:string[]=[];
 const rest=process.argv.slice(2);
 for(let i=0;i<rest.length;i+=1){
  const arg=rest[i]!;
  if(arg==='--library'||arg==='--stage-progress'){flags.add(arg);continue;}
  if(arg==='-o'){
   const value=rest[++i];
   if(value===undefined||values.has('-o'))fail('-o needs one output path');
   values.set('-o',value);
   continue;
  }
  if(arg.startsWith('--')){
   const at=arg.indexOf('='),name=at<0?arg:arg.slice(0,at),value=at<0?rest[++i]:arg.slice(at+1);
   if(name==='--stage-manifest'){
    if(value===undefined)fail('--stage-manifest needs one path');
    manifests.push(resolve(value));
    continue;
   }
   if(!['--candidate','--parser','--base','--exports','--runtime-c','--source-tag','--stage-profile'].includes(name)||value===undefined||values.has(name))fail('unknown or duplicate option '+arg);
   values.set(name,value);
   continue;
  }
  positional.push(arg);
 }
 if(positional.length!==1)fail('expected exactly one input .bend file');
 if(!values.has('--candidate'))fail('required --candidate=PATH');
 if(values.has('--source-tag')){const sourceTag=values.get('--source-tag')!;if(!sourceTag||/[\r\n\t]/.test(sourceTag))fail('--source-tag needs one nominal constructor tag');}
 if(!values.has('-o'))fail('required -o <output>');
 if(flags.has('--stage-progress')&&!values.has('--stage-profile'))fail('--stage-progress needs --stage-profile=DIR');
 const output=values.get('-o')!;
 return {candidate:resolve(values.get('--candidate')!),parser:values.has('--parser')?resolve(values.get('--parser')!):undefined,
  base:resolve(values.get('--base')??posix.join(ROOT,'bend2/base.bend')),exports:values.get('--exports')?.split(','),
  library:flags.has('--library')||output.endsWith('.mjs'),input:resolve(positional[0]!),output:resolve(output),
  runtimeC:values.has('--runtime-c')?resolve(values.get('--runtime-c')!):undefined,
  sourceTag:values.get('--source-tag')??OFFICIAL_SOURCE_FILE_TAG,
  stageProfile:values.has('--stage-profile')?resolve(values.get('--stage-profile')!):undefined,
  stageManifests:manifests,stageProgress:flags.has('--stage-progress')};
}

const o=args_parse();
const target=o.output.endsWith('.c')?'c':'js';
// Opt-in diagnostic identity. Ordinary runs never touch the collector.
const fileSha=(path:string)=>createHash('sha256').update(readFileSync(path)).digest('hex');
if(o.stageProfile!==undefined){
 const inputPath=realpathSync(o.input),parserPath=realpathSync(o.parser??o.candidate);
 stage=await createStageProfile({
  directory:o.stageProfile,rawDetail:o.stageProgress,manifestPaths:o.stageManifests,
  execution:{stage:'selfhost-candidate',mode:'typed-step',target,
   sourcePath:inputPath,sourceSha256:fileSha(inputPath),
   candidatePath:realpathSync(o.candidate),candidateSha256:fileSha(o.candidate),
   parserPath,parserSha256:fileSha(parserPath),
   basePath:realpathSync(o.base),baseSha256:fileSha(o.base),
   sourceFileTag:o.sourceTag,library:o.library,exports:o.exports??null,outputPath:o.output,
   command:[process.execPath,...process.argv.slice(2)],
   scope:'candidate_host.ts typed-step ABI; source emission only, no external link step'},
 });
 process.on('exit',code=>{
  try{if(stage!==undefined&&!stage.finished)stage.finish(code===0?'completed':'failed',code===0?undefined:'candidate host exited '+code);}
  catch(error){console.error('candidate: stage profile close failed: '+String(error));}
 });
 // Preserve the real exception in the report before Node/Bun prints it and exits.
 process.on('uncaughtExceptionMonitor',error=>{try{stage?.fail(error);}catch{};});
}
const importSpan=stage?.span('startup-import',{candidatePath:o.candidate,parserPath:o.parser??o.candidate});
// Both paths are runtime-selected by the caller, so a static import is impossible.
const candidate=objectOf((await import(pathToFileURL(o.candidate).href)).default);
const requiredStart=target==='c'?'emit_c_modules_start':'emit_modules_start';
const requiredLibraryStart=target==='c'?'emit_c_library_start':'emit_library_start';
if(candidate===undefined||typeof candidate.parsed_module!=='function'||typeof candidate.check_expanded_start!=='function'
 ||typeof candidate[requiredStart]!=='function'||(o.library&&typeof candidate[requiredLibraryStart]!=='function'))
 fail('candidate lacks the typed '+target+' step ABI ('+requiredStart+(o.library?'/'+requiredLibraryStart:'')+')');
const parserModule=o.parser===undefined?candidate:objectOf((await import(pathToFileURL(o.parser).href)).default);
if(typeof parserModule?.parse_with_fuel!=='function')fail('no compiled parser: pass --parser=PATH or export parse_with_fuel');
stage?.end(importSpan!,'completed',{target,library:o.library,parserModule:o.parser===undefined?'candidate':'separate'});

let parsedSources=0,fuelCells=0,sourceBytes=0;
function parse(file:string,source:string):Record<string,unknown>{
 let fuel:unknown={$:'FeedbackFuelEnd'};
 for(let i=0;i<8000000;i+=1)fuel={$:'FeedbackFuelCell',tail:fuel};
 if(stage!==undefined){parsedSources+=1;fuelCells+=8000000;sourceBytes+=Buffer.byteLength(source);}
 const feedback=objectOf(parserModule!.parse_with_fuel(fuel,file,source));
 if(tag(feedback)!=='FeedbackComplete')fail('parser feedback did not complete for '+file);
 const result=objectOf(objectOf(feedback?.value)?.result);
 if(tag(result)!=='ParseSuccess')fail('parser rejected '+file+': '+String(result?.message??tag(result)));
 const module=objectOf(result?.module);
 if(module===undefined)fail('parser returned no module for '+file);
 return module;
}
const namespace_of=(parent:string,path:string):string=>
 path==='Base'?'':posix.normalize(isAbsolute(path)?path.replace(/\.bend$/,''):posix.dirname(parent)+'/'+path.replace(/\.bend$/,''));

// The declared target alternative is BIR metadata: the host reads exactly the
// path BIR resolves from it. Real read failures stay failures that name it.
const files:unknown[]=[];
const modules:unknown[]=[];
const seen=new Set<string>();
const inputFile=realpathSync(o.input);
let rootModule:Record<string,unknown>|undefined;
function visit(file:string,scope:string){
 const at=realpathSync(file);
 if(seen.has(at))return;
 seen.add(at);
 const fileSpan=o.stageProgress?stage?.span('parse-file',{file:at,summary:false}):undefined;
 const module=parse(at,readFileSync(at,'utf8'));
 if(fileSpan!==undefined)stage!.end(fileSpan,'completed',{file:at});
 if(at===inputFile)rootModule=module;
 for(const top of items(module.declarations)){
  const definition=objectOf(objectOf(top)?.definition);
  if(tag(definition?.body)!=='DefImports')continue;
  for(const declared of items(objectOf(definition?.body)?.paths)){
   if(typeof declared==='string'&&declared.endsWith('.'+target)){
    try{files.push(...sourceFileEntries(at,[declared]));}
    catch(error){fail('cannot read declared .'+target+' target '+declared+' of '+at+': '+String(error));}
   }
  }
 }
 for(const imported of items(module.imports)){
  const path=objectOf(imported)?.path;
  if(typeof path!=='string'||/^0x[0-9a-f]+\//.test(path))fail('malformed import in '+at);
  if(path.endsWith('.js')||path.endsWith('.c'))continue;
  visit(path==='Base'?o.base:resolve(dirname(at),path),namespace_of(scope,path));
 }
 modules.push(candidate!.parsed_module(scope,module));
}
const parseSpan=stage?.span('parse-import-fuel',{input:o.input,target});
visit(o.input,'');
stage?.end(parseSpan!,'completed',{modules:modules.length,foreignFiles:files.length});
stage?.record({kind:'phase-exact-counters',scope:'candidate host',name:'parse-import-fuel',
 values:{modules:modules.length,parses:parsedSources,fuelCells,sourceBytes,foreignFiles:files.length,parserFuelCellsPerParse:8000000},
 source:'candidate_host.ts',details:{phase:'parse-import-fuel',
  note:'one eager parser feedback chain per parsed module; fuelCells is the exact constructed cell count, not semantic fuel consumed'}});
const bag=sourceFiles(files,o.sourceTag);

// One attributed phase: a real span plus exact host-step counters and sampled
// typed progress. A thrown step error still closes the span failed and records
// the samples observed before it.
function attributedPhase(name:string,protocol:string,inputs:Record<string,unknown>,run:(observe:unknown)=>unknown,success:(value:unknown)=>boolean):unknown{
 if(stage===undefined)return run(undefined);
 const attributes=createStepAttribution(name,protocol,stage.manifestTable);
 const token=stage.span(name,inputs);
 let value:unknown;
 try{value=run(attributes);}
 catch(error){stage.end(token,'failed',{error:String(error)});attributes.record(stage.profile);throw error;}
 const ok=success(value),message=String(objectOf(objectOf(value)?.diagnostic)?.message??objectOf(value)?.message??tag(value));
 stage.end(token,ok?'completed':'failed',{result:tag(value),...(ok?{}:{error:message})});
 attributes.record(stage.profile);
 return value;
}

function checkedProgram():unknown{
 const loaded=list(modules);
 const expanded=attributedPhase('template-expand','Template',{inputModules:modules.length},
  observe=>typeof candidate!.expand_modules_start==='function'?runTemplateSteps(candidate,loaded,observe):{$:'ExpandSuccess',modules:loaded},
  value=>tag(value)==='ExpandSuccess');
 if(tag(expanded)!=='ExpandSuccess')fail('template expansion failed: '+String(objectOf(expanded)?.message??''));
 const checked=attributedPhase('check-signature-body','Checker',{inputModules:modules.length},
  observe=>runCheckerSteps(candidate,objectOf(expanded)?.modules,observe),
  value=>tag(value)==='CheckSuccess');
 if(tag(checked)!=='CheckSuccess')fail('checking failed: '+String(objectOf(objectOf(checked)?.diagnostic)?.message??''));
 return objectOf(checked)?.program;
}

// The host cannot re-derive the official CLI's type-based IO filter from a
// syntax tree, so the default library export set is every term-bodied
// definition this module declares, in source order; --exports overrides it.
function declaredExports():string[]{
 const keys:string[]=[];
 for(const top of items(rootModule?.declarations)){
  const definition=objectOf(objectOf(top)?.definition);
  if(tag(top)==='DefTop'&&typeof definition?.key==='string'&&tag(definition.body)==='DefTerm')keys.push(definition.key);
 }
 return keys;
}

const program=checkedProgram();
const exports=o.exports??declaredExports();
let runtime:string|undefined;
if(target==='c'){
 try{runtime=readFileSync(o.runtimeC,'utf8');}
 catch(error){fail('cannot read C runtime '+o.runtimeC+': '+String(error));}
}
const emitted=attributedPhase('emit','Emitter',{target,library:o.library,exports:o.library?exports.length:null},
 observe=>target==='c'
  ? o.library
   ? runCLibraryEmitterSteps(candidate,program,list(exports),runtime!,bag,observe)
   : runCEmitterSteps(candidate,program,runtime!,bag,observe)
  : o.library
   ? runLibraryEmitterSteps(candidate,program,list(exports),bag,observe)
   : runEmitterSteps(candidate,program,bag,observe),
 value=>tag(value)==='EmitSuccess');
if(tag(emitted)!=='EmitSuccess')fail('emission failed: '+String(objectOf(emitted)?.message??''));
const source=objectOf(emitted)?.source;
if(typeof source!=='string')fail('emission returned no source');
const outputSpan=stage?.span('output-write',{output:o.output,bytes:Buffer.byteLength(source)});
const digest=createHash('sha256').update(source).digest('hex');
writeFileSync(o.output,source);
stage?.end(outputSpan!,'completed',{output:o.output,bytes:Buffer.byteLength(source)});
stage?.record({kind:'phase-exact-counters',scope:'candidate host',name:'output-write',
 values:{bytes:Buffer.byteLength(source),modules:modules.length,foreignFiles:files.length},
 source:'candidate_host.ts',details:{phase:'output-write',note:'bytes are the emitted source size; the hash is content identity, not a performance metric'}});
if(stage!==undefined)stage.finish('completed');
const result:Record<string,unknown>={output:o.output,bytes:Buffer.byteLength(source),sha256:digest,target,library:o.library,exports:o.library?exports:undefined,modules:seen.size,foreignFiles:files.length,runtime:target==='c'?o.runtimeC:undefined};
if(stage!==undefined)result.stageProfile=stage.reportPath;
console.log(JSON.stringify(result));
