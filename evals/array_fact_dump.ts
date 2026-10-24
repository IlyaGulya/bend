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
import {pathToFileURL} from 'node:url';
import {
 sourceFileEntries,sourceFiles,OFFICIAL_SOURCE_FILE_TAG,
 runTemplateSteps,runCheckerSteps,runLibraryEmitterSteps,runEmitterSteps,
} from './checker_core_step_runtime.mjs';

const ROOT=resolve(import.meta.dir,'..');

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
 const output=values.get('-o');
 return {candidate:resolve(values.get('--candidate')!),parser:values.has('--parser')?resolve(values.get('--parser')!):undefined,
  base:resolve(values.get('--base')??posix.join(ROOT,'bend2/base.bend')),exports:values.get('--exports')?.split(','),
  library:flags.has('--library'),input:resolve(positional[0]!),output:output===undefined?undefined:resolve(output)};
}

const o=args_parse();
if(o.output!==undefined)fail('the dump entry writes to stdout, not to -o');
// Both paths are runtime-selected by the caller, so a static import is impossible.
const candidate=objectOf((await import(pathToFileURL(o.candidate).href)).default);
if(candidate===undefined||typeof candidate.parsed_module!=='function'||typeof candidate.check_expanded_start!=='function'||typeof candidate.emitter_request!=='function')
 fail('candidate lacks the typed step ABI plus emitter_request');
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

// The declared `.js` alternative is BIR metadata: the host reads exactly the
// path BIR resolves from it. Real read failures stay failures.
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
   if(typeof declared==='string'&&declared.endsWith('.js'))files.push(...sourceFileEntries(at,[declared]));
  }
 }
 for(const imported of items(module.imports)){
  const path=objectOf(imported)?.path;
  if(typeof path!=='string'||/^0x[0-9a-f]+\//.test(path))fail('malformed import in '+at);
  if(path.endsWith('.js'))continue;
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


// BIR terms are plain tagged data across the step boundary, so the host walks
// them directly; suffix matching keeps the check independent of module prefixes.
const ARRAY_PRIMITIVES:Record<string,string>={
 PrimArrayNew:'Array.new',PrimArraySet:'Array.set',PrimArrayGet:'Array.get',PrimArraySwap:'Array.swap',
 PrimArraySize:'Array.size',PrimArrayClone:'Array.clone',PrimArrayLeaf:'Array.leaf',PrimArrayNode:'Array.node',
 PrimArrayLeafValue:'Array.leaf_value',PrimArrayLeft:'Array.left',PrimArrayRight:'Array.right',
 PrimIsArrayLeaf:'Array.is_leaf',PrimIsArrayNode:'Array.is_node'};
function descriptorText(value:unknown):string{
 const kind=tag(value),record=objectOf(value);
 const listOf=(items_:unknown):string=>items(items_).map(descriptorText).join(',');
 switch(kind){
  case 'DescriptorRef':return String(record?.key)+'('+listOf(record?.args)+')';
  case 'DescriptorConstructor':return 'ctor:'+String(record?.key)+'('+listOf(record?.args)+')';
  case 'DescriptorParameter':return '#'+String(record?.index);
  case 'DescriptorApplication':return 'app('+descriptorText(record?.fn)+';'+descriptorText(record?.arg)+')';
  case 'DescriptorArrow':return 'arrow('+descriptorText(record?.domain)+'->'+descriptorText(record?.body)+')';
  case 'DescriptorLambda':return 'lam('+descriptorText(record?.body)+')';
  case 'DescriptorNull':return 'null';
  case 'DescriptorQuantityKind':return 'quantity-kind';
  case 'DescriptorQuantity':return 'quantity';
  case 'DescriptorKind':return 'kind('+descriptorText(record?.quantity)+')';
  case 'DescriptorMinimum':return 'min('+descriptorText(record?.left)+','+descriptorText(record?.right)+')';
  default:return String(kind);
 }
}
function atomText(atom:unknown):string{
 const kind=tag(atom),record=objectOf(atom);
 switch(kind){
  case 'Local':return 'Local#'+String(record?.id);
  case 'Capture':return 'Capture#'+String(record?.slot);
  case 'Word':return 'Word#'+String(record?.value);
  case 'Natural':return 'Nat#'+String(record?.value);
  case 'FloatBits':return 'Float#'+String(record?.bits);
  case 'Text':return JSON.stringify(String(record?.value));
  case 'Boolean':return 'Bool#'+String(record?.value);
  case 'Symbol':return 'Symbol#'+String(record?.id);
  case 'Null':return 'Null';
  case 'Undefined':return 'Undefined';
  default:return String(kind);
 }
}
function argText(arg:unknown):string{
 const record=objectOf(arg);
 return atomText(record?.value);
}
function opText(op:unknown):string[]{
 const kind=tag(op),record=objectOf(op);
 if(kind==='PrimitiveCall'){
  const name=ARRAY_PRIMITIVES[tag(record?.primitive)??''];
  const types=items(record?.types).map(descriptorText).join(',');
  const args=items(record?.args).map(argText).join(',');
  if(name===undefined)return types===''?[]:['LEAK non-array primitive carries types=['+types+']'];
  return [name+' ['+args+'] types=['+types+']'];
 }
 if(kind==='LoadSymbol')return ['symbol '+String(record?.key)];
 if(kind==='Apply'||kind==='TailApply')return ['apply'];
 if(kind==='Closure')return ['closure '+String(record?.code)];
 if(kind==='PrimitiveConstant')return [];
 return [];
}
function blockText(block:unknown):string[]{
 const out:string[]=[];
 let cursor=block;
 for(let i=0;i<1000000;i+=1){
  const kind=tag(cursor),record=objectOf(cursor);
  if(record===undefined)break;
  if(kind==='Let'){out.push(...opText(record.op));cursor=record.next;continue;}
  if(kind==='Branch'){out.push('branch');out.push(...blockText(record.yes),...blockText(record.no));break;}
  if(kind==='Region'){out.push('region');out.push(...blockText(record.body),...blockText(record.next));break;}
  if(kind==='Return'){out.push('return '+String(tag(record.value)));break;}
  if(kind==='TailApply'){out.push('tail-apply');break;}
  if(kind==='TailDirect'){out.push('tail-direct '+String(record.code));break;}
  if(kind==='LeaveRegion'){out.push('leave-region');break;}
  break;
 }
 return out;
}
function renderProgram(program:unknown):string{
 const lines:string[]=['BEGIN'];
 for(const declaration of items(objectOf(program)?.declarations)){
  const kind=tag(declaration),record=objectOf(declaration),key=String(record?.key??'');
  if(kind==='FunctionDeclaration')lines.push('decl '+key+' -> code '+String(record?.code));
  else if(kind==='LazyDeclaration')lines.push('lazy '+key,...blockText(record?.body));
 }
 for(const code of items(objectOf(program)?.codes)){
  const kind=tag(code),record=objectOf(code);
  if(kind!=='Code')continue;
  lines.push('code '+String(record?.id));
  lines.push(...blockText(record?.body));
 }
 return lines.join('\n')+'\n';
}

// The lowering is a public request of the emitter state machine, so the host
// can ask for it directly and walk the BIR it returns: no Loader, no do-binding
// and no raw provider import anywhere.
const program=checkedProgram();
if(typeof candidate.emitter_request!=='function')fail('candidate lacks the emitter_request export');
const request={$:'emitter_steps_v1.EmitterRequestGroup_5',request:{$:'emitter_steps_v1.EmitterRequest_cps_provider_1_lower',v_0:program}};
const stack:unknown[]=[];
let progress:unknown=candidate.emitter_request(request),value:unknown;
for(let i=0;;i+=1){
 if(i>50000000)fail('lowering did not finish');
 const kind=tag(progress),record=objectOf(progress);
 if(kind==='EmitterFinished'){
  const box=objectOf(record?.box);
  if(typeof record?.box!=='object'||box===undefined)fail('EmitterFinished without a value box');
  if(stack.length===0){value=box.value;break;}
  const resume=stack.pop() as (box:unknown)=>unknown;
  progress=resume(record.box);
 }else if(kind==='EmitterDirect'){
  stack.push(record?.resume);
  progress=(record?.invoke as (argument:unknown)=>unknown)(record?.arguments);
 }else if(kind==='EmitterPending'){
  stack.push(record?.resume);
  progress=candidate.emitter_request(record?.request);
 }else if(kind==='EmitterBound'){
  stack.push(record?.resume);
  progress=record?.inner;
 }else fail('unexpected progress term '+String(kind));
}
const lowered=objectOf(value);
if(tag(value)==='cps_provider_1_LowerFailure')fail('lowering failed: '+String(lowered?.message??''));
const codeList=tag(value)==='cps_provider_1_Lowered'?lowered?.program:value;
if(tag(codeList)!=='Program')fail('lowering returned no program: '+String(tag(value)));
const dump=renderProgram(codeList);
const arrayLines=dump.split('\n').filter(line=>line.startsWith('Array.'));
const leakLines=dump.split('\n').filter(line=>line.startsWith('LEAK'));
const count=(prefix:string)=>arrayLines.filter(line=>line.startsWith(prefix+' ')).length;
console.log(dump);
console.error(JSON.stringify({modules:seen.size,arrayPrimitiveCalls:arrayLines.length,leaks:leakLines.length,
 counts:Object.fromEntries(['Array.new','Array.set','Array.get','Array.swap','Array.size','Array.clone','Array.leaf','Array.node','Array.leaf_value','Array.left','Array.right','Array.is_leaf','Array.is_node'].map(name=>[name,count(name)])),
 dumpLines:dump.split('\n').length}));
