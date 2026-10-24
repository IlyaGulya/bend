import {readFileSync} from 'node:fs';
import {posix} from 'node:path';

const constructorTag=value=>{
 if(value===null||typeof value!=='object'||Array.isArray(value)||typeof value.$!=='string')return undefined;
 const tag=value.$;
 return tag.slice(tag.lastIndexOf('.')+1);
};
const hasConstructorTag=value=>{
 if(value===null||typeof value!=='object'||Array.isArray(value)||typeof value.$!=='string')return false;
 const tag=value.$;
 return tag.length>0&&tag.charCodeAt(tag.length-1)!==46;
};
const invalid=(kind,message)=>{throw Error('Invalid '+kind.toLowerCase()+' step ABI: '+message);};

/**
 * The one host-side builder of the passive `List<&2, BIR.SourceFile>` carrier.
 *
 * Semantic link metadata stays in BIR: the renderer derives every declared
 * target path, namespace and span itself and joins them with this bag by exact
 * declared path. The host only supplies the bytes it actually read, keyed by
 * the same path BIR derives (`Path.resolve` of the module path and the
 * declared import). Nothing here invents a path, namespace or span.
 */
export function sourceFilePath(modulePath,declaredPath){
 if(typeof modulePath!=='string'||typeof declaredPath!=='string'||!declaredPath)throw Error('Invalid source file path input');
 return posix.normalize(posix.isAbsolute(declaredPath)?declaredPath:posix.dirname(modulePath)+'/'+declaredPath);
}

export function sourceFiles(entries, sourceFileTag = 'SourceFile') {
 const seen = new Map();
 let list={$:'Nil'};
 if(typeof sourceFileTag!=='string'||!/^[A-Za-z_][A-Za-z0-9_.\/-]*$/.test(sourceFileTag))throw Error('Invalid BIR.SourceFile constructor tag: '+sourceFileTag);
 for(const entry of entries){
  const path=entry?.path,source=entry?.source;
  if(typeof path!=='string'||!path||typeof source!=='string')throw Error('Invalid BIR source file entry: expected {path, source} strings');
  const known=seen.get(path);
  if(known!==undefined){
   if(known!==source)throw Error('Declared source path resolves to different bytes: '+path);
   continue;
  }
  seen.set(path,source);
  list={$:'Con',head:{$:sourceFileTag,path,source},tail:list};
 }
 return list;
}

/**
 * The `.js` alternatives a parsed module declares in its `DefImports` bodies,
 * in source order. These are the exact strings BIR lowering resolves against
 * the module path, so hosts never guess the target file name.
 */
export function declaredSourcePaths(module){
 const declarations=module?.declarations;
 const paths=[];
 const walk=list=>{
  for(;;){
   const tag=constructorTag(list);
   if(tag==='Nil')return;
   if(tag!=='Con')throw Error('Malformed native declaration list');
   const top=list.head;
   if(constructorTag(top)==='DefTop'){
    const body=top.definition?.body;
    if(constructorTag(body)==='DefImports'){
     for(let rest=body.paths;;){
      const pathTag=constructorTag(rest);
      if(pathTag==='Nil')break;
      if(pathTag!=='Con')throw Error('Malformed native foreign import list');
      const path=rest.head;
      if(typeof path!=='string')throw Error('Malformed native foreign import path');
      if(path.endsWith('.js'))paths.push(path);
      rest=rest.tail;
     }
    }
   }
   list=list.tail;
  }
 };
 walk(declarations);
 return paths;
}

/** Reads the actual bytes of every declared alternative of one module. */
export function sourceFileEntries(modulePath,declaredPaths){
 return [...new Set(declaredPaths)].map(path=>{
  const resolved=sourceFilePath(modulePath,path);
  return {path:resolved,source:readFileSync(resolved,'utf8')};
 });
}

export function sourceFilesFor(modulePath,declaredPaths){
 return sourceFiles(sourceFileEntries(modulePath,declaredPaths));
}


/**
 * Trusted Node orchestration, outside the native Bend termination proof.
 * Template, checker and emitter logic live in native-validated Bend steps.
 * Each host call advances an opaque native-owned Run by one bounded chunk.
 * Stack transitions, requests and source continuations remain entirely native.
 * There are no recursive host calls or host-imposed step/fuel limits.
 */
function runSteps(component,startArguments,kind,startExport,stepExport,validateResult){
 if(typeof component?.[startExport]!=='function')invalid(kind,'missing '+startExport+' export');
 if(typeof component?.[stepExport]!=='function')invalid(kind,'missing '+stepExport+' export');
 const stateTag=kind+'RunState',finishedTag=kind+'RunFinished',valueTag=kind+'Value',stateSuffix='.'+stateTag,finishedSuffix='.'+finishedTag,valueSuffix='.'+valueTag;
 let knownStateTag,knownFinishedTag,knownValueTag,run=component[startExport](...startArguments);
 startArguments=undefined;
 for(;;){
  const tag=run?.$;
  const validRun=run!==null&&typeof run==='object'&&!Array.isArray(run)&&typeof tag==='string';
  if(validRun&&(tag===knownStateTag||tag===stateTag||tag.endsWith(stateSuffix))){
   knownStateTag=tag;
   const next=run;
   run=undefined;
   run=component[stepExport](next);
  }else if(validRun&&(tag===knownFinishedTag||tag===finishedTag||tag.endsWith(finishedSuffix))){
   knownFinishedTag=tag;
   if(!Object.hasOwn(run,'box'))invalid(kind,finishedTag+' requires box');
   const box=run.box,boxTag=box?.$;
   if(box===null||typeof box!=='object'||Array.isArray(box)||typeof boxTag!=='string'||!(boxTag===knownValueTag||boxTag===valueTag||boxTag.endsWith(valueSuffix))||!Object.hasOwn(box,'value'))invalid(kind,finishedTag+' requires '+valueTag+' box with value');
   knownValueTag=boxTag;
   run=undefined;
   const value=box.value;
   validateResult(value);
   return value;
  }else invalid(kind,'expected '+stateTag+' or '+finishedTag+', observed '+String(tag));
 }
}

function validateCheckResult(value){
 const resultTag=constructorTag(value);
 if(resultTag==='CheckSuccess'){
  validateCheckedProgram(value.program);
 }else if(resultTag==='CheckFailure'){
  if(!Object.hasOwn(value,'diagnostic')||constructorTag(value.diagnostic)!=='Diagnostic')invalid('Checker','CheckFailure requires a native Diagnostic');
 }else invalid('Checker','expected CheckResult, observed '+String(resultTag));
}

function validateCheckedProgram(program){
 if(constructorTag(program)!=='CheckedProgram'||!Object.hasOwn(program,'source')||!hasConstructorTag(program.source)||!['Nil','Con'].includes(constructorTag(program.modules))||!['Nil','Con'].includes(constructorTag(program.signatures)))invalid('Checker','expected owning CheckedProgram with source, IR modules and signatures');
}

function validateInspection(value){
 const resultTag=constructorTag(value);
 if(resultTag==='Inspection'){
  if(!['Nil','Con'].includes(constructorTag(value.modules)))invalid('Checker','Inspection requires native readback modules');
 }else if(resultTag==='InspectionFailure'){
  if(constructorTag(value.diagnostic)!=='Diagnostic')invalid('Checker','InspectionFailure requires a native Diagnostic');
 }else invalid('Checker','expected owner-preserving Inspection or InspectionFailure');
 validateCheckedProgram(value.program);
}

function validateEmitResult(value){
 const resultTag=constructorTag(value);
 if(resultTag==='EmitSuccess'){
  if(typeof value.source!=='string')invalid('Emitter','EmitSuccess requires source string');
 }else if(resultTag==='EmitFailure'){
  if(typeof value.message!=='string')invalid('Emitter','EmitFailure requires message string');
  const span=value.span;
  if(constructorTag(span)!=='SpanOf'||typeof span.file!=='string'||!Number.isSafeInteger(span.beg)||!Number.isSafeInteger(span.end)||span.beg<0||span.end<span.beg)invalid('Emitter','EmitFailure requires native SourceSpan');
 }else invalid('Emitter','expected EmitResult, observed '+String(resultTag));
}

function validateExpandResult(value){
 const resultTag=constructorTag(value);
 if(resultTag==='ExpandSuccess'){
  if(!Object.hasOwn(value,'modules')||!['Nil','Con'].includes(constructorTag(value.modules)))invalid('Template','ExpandSuccess requires native modules');
 }else if(resultTag==='ExpandFailure'){
  if(typeof value.message!=='string')invalid('Template','ExpandFailure requires message string');
  const span=value.span;
  if(constructorTag(span)!=='SpanOf'||typeof span.file!=='string'||!Number.isSafeInteger(span.beg)||!Number.isSafeInteger(span.end)||span.beg<0||span.end<span.beg)invalid('Template','ExpandFailure requires native SourceSpan');
 }else invalid('Template','expected ExpandResult, observed '+String(resultTag));
}

function validateSourceFiles(files){
 if(files===undefined)invalid('Emitter','start requires the passive BIR source file list');
 for(let rest=files;;){
  const tag=constructorTag(rest);
  if(tag==='Nil')return;
  if(tag!=='Con')invalid('Emitter','source files must be a native List<&2, BIR.SourceFile>');
  const entry=rest.head;
  if(constructorTag(entry)!=='SourceFile'||typeof entry.path!=='string'||!entry.path||typeof entry.source!=='string')invalid('Emitter','SourceFile requires path and source strings');
  rest=rest.tail;
 }
}

export function runTemplateSteps(component,modules){
 return runSteps(component,[modules],'Template','expand_modules_start','template_step',validateExpandResult);
}

export function runCheckerSteps(component,modules){
 return runSteps(component,[modules],'Checker','check_expanded_start','checker_step',validateCheckResult);
}

export function runCheckedInspectionSteps(component,program){
 validateCheckedProgram(program);
 return runSteps(component,[program],'Checker','inspect_checked_start','checker_step',validateInspection);
}

export function runEmitterSteps(component,program,files){
 validateCheckedProgram(program);
 validateSourceFiles(files);
 return runSteps(component,[program,files],'Emitter','emit_modules_start','emitter_step',validateEmitResult);
}

export function runLibraryEmitterSteps(component,program,exports,files){
 validateCheckedProgram(program);
 if(!['Nil','Con'].includes(constructorTag(exports)))invalid('Emitter','library start requires explicit native exports list');
 validateSourceFiles(files);
 return runSteps(component,[program,exports,files],'Emitter','emit_library_start','emitter_step',validateEmitResult);
}

export function runCEmitterSteps(component,program,runtime,files){
 validateCheckedProgram(program);
 if(typeof runtime!=='string')invalid('CEmitter','runtime source must be a string, not a path');
 validateSourceFiles(files);
 return runSteps(component,[program,runtime,files],'CEmitter','emit_c_modules_start','c_emitter_step',validateEmitResult);
}

export function runCLibraryEmitterSteps(component,program,exports,runtime,files){
 validateCheckedProgram(program);
 if(!['Nil','Con'].includes(constructorTag(exports)))invalid('CEmitter','library start requires explicit native exports list');
 if(typeof runtime!=='string')invalid('CEmitter','runtime source must be a string, not a path');
 validateSourceFiles(files);
 return runSteps(component,[program,exports,runtime,files],'CEmitter','emit_c_library_start','c_emitter_step',validateEmitResult);
}
