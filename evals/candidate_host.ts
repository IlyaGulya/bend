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
import {createHash} from 'node:crypto';
import {readFileSync,realpathSync,writeFileSync} from 'node:fs';
import {dirname,isAbsolute,posix,resolve} from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {
 sourceFileEntries,sourceFiles,OFFICIAL_SOURCE_FILE_TAG,
 runTemplateSteps,runCheckerSteps,runLibraryEmitterSteps,runEmitterSteps,
 runCEmitterSteps,runCLibraryEmitterSteps,
} from './checker_core_step_runtime.mjs';

const ROOT=resolve(dirname(fileURLToPath(import.meta.url)),'..');

function fail(message:string):never{
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
 const values=new Map<string,string>(),flags=new Set<string>(),positional:string[]=[];
 const rest=process.argv.slice(2);
 for(let i=0;i<rest.length;i+=1){
  const arg=rest[i]!;
  if(arg==='--library'){flags.add(arg);continue;}
  if(arg==='-o'){
   const value=rest[++i];
   if(value===undefined||values.has('-o'))fail('-o needs one output path');
   values.set('-o',value);
   continue;
  }
  if(arg.startsWith('--')){
   const at=arg.indexOf('='),name=at<0?arg:arg.slice(0,at),value=at<0?rest[++i]:arg.slice(at+1);
   if(!['--candidate','--parser','--base','--exports','--runtime-c'].includes(name)||value===undefined||values.has(name))fail('unknown or duplicate option '+arg);
   values.set(name,value);
   continue;
  }
  positional.push(arg);
 }
 if(positional.length!==1)fail('expected exactly one input .bend file');
 if(!values.has('--candidate'))fail('required --candidate=PATH');
 if(!values.has('-o'))fail('required -o <output>');
 const output=values.get('-o')!;
 return {candidate:resolve(values.get('--candidate')!),parser:values.has('--parser')?resolve(values.get('--parser')!):undefined,
  base:resolve(values.get('--base')??posix.join(ROOT,'bend2/base.bend')),exports:values.get('--exports')?.split(','),
  library:flags.has('--library')||output.endsWith('.mjs'),input:resolve(positional[0]!),output:resolve(output),
  runtimeC:values.has('--runtime-c')?resolve(values.get('--runtime-c')!):undefined};
}

const o=args_parse();
const target=o.output.endsWith('.c')?'c':'js';
// Both paths are runtime-selected by the caller, so a static import is impossible.
const candidate=objectOf((await import(pathToFileURL(o.candidate).href)).default);
const requiredStart=target==='c'?'emit_c_modules_start':'emit_modules_start';
const requiredLibraryStart=target==='c'?'emit_c_library_start':'emit_library_start';
if(candidate===undefined||typeof candidate.parsed_module!=='function'||typeof candidate.check_expanded_start!=='function'
 ||typeof candidate[requiredStart]!=='function'||(o.library&&typeof candidate[requiredLibraryStart]!=='function'))
 fail('candidate lacks the typed '+target+' step ABI ('+requiredStart+(o.library?'/'+requiredLibraryStart:'')+')');
const parserModule=o.parser===undefined?candidate:objectOf((await import(pathToFileURL(o.parser).href)).default);
if(typeof parserModule?.parse_with_fuel!=='function')fail('no compiled parser: pass --parser=PATH or export parse_with_fuel');

function parse(file:string,source:string):Record<string,unknown>{
 let fuel:unknown={$:'FeedbackFuelEnd'};
 for(let i=0;i<8000000;i+=1)fuel={$:'FeedbackFuelCell',tail:fuel};
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
 const module=parse(at,readFileSync(at,'utf8'));
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
visit(o.input,'');
const bag=sourceFiles(files,OFFICIAL_SOURCE_FILE_TAG);

function checkedProgram():unknown{
 const loaded=list(modules);
 const expanded=typeof candidate!.expand_modules_start==='function'?runTemplateSteps(candidate,loaded):{$:'ExpandSuccess',modules:loaded};
 if(tag(expanded)!=='ExpandSuccess')fail('template expansion failed: '+String(objectOf(expanded)?.message??''));
 const checked=runCheckerSteps(candidate,objectOf(expanded)?.modules);
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
const emitted=target==='c'
 ? o.library
  ? runCLibraryEmitterSteps(candidate,program,list(exports),runtime!,bag)
  : runCEmitterSteps(candidate,program,runtime!,bag)
 : o.library
  ? runLibraryEmitterSteps(candidate,program,list(exports),bag)
  : runEmitterSteps(candidate,program,bag);
if(tag(emitted)!=='EmitSuccess')fail('emission failed: '+String(objectOf(emitted)?.message??''));
const source=objectOf(emitted)?.source;
if(typeof source!=='string')fail('emission returned no source');
writeFileSync(o.output,source);
console.log(JSON.stringify({output:o.output,bytes:Buffer.byteLength(source),sha256:createHash('sha256').update(source).digest('hex'),target,library:o.library,exports:o.library?exports:undefined,modules:seen.size,foreignFiles:files.length,runtime:target==='c'?o.runtimeC:undefined}));
