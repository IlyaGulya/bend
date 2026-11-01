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

export function sourceFilePath(modulePath,declaredPath){
 if(typeof modulePath!=='string'||typeof declaredPath!=='string'||!declaredPath)throw Error('Invalid source file path input');
 return posix.normalize(posix.isAbsolute(declaredPath)?declaredPath:posix.dirname(modulePath)+'/'+declaredPath);
}

/**
 * The passive `List<&2, BIR.SourceFile>` carrier uses nominal constructor names,
 * and the two current emitters use two different, both source-derived tag
 * spaces:
 *  - `bend2/comp.ts` v2.0.39 `js_tag(key)` emits the part after the first `:`,
 *    so an imported module's constructor is its bare local name.
 *  - the selfhost JS backend emits the canonical key verbatim: a bare name for
 *    a root declaration, otherwise `namespace.Name`.
 * Exactly one rule applies to the image being driven, selected by who emitted
 * it. A tag is always derived from the authenticated source namespace; a
 * registration in the artifact can only confirm it, and a wrong tag must fail
 * closed (a single-constructor match may have optimized the tag check away, so
 * successful emission is not proof of the carrier's declared name).
 */
export const OFFICIAL_BIR_IMPORT='../bend2/selfhost/backend_ir.bend';

/** The kernel's namespace rule: a module's namespace is its import path
 * without `.bend`, taken relative to the importing module's namespace. */
export function declaredModuleNamespace(parentNamespace,importPath){
 if(typeof parentNamespace!=='string'||typeof importPath!=='string'||!importPath)throw Error('Invalid declared module import');
 if(importPath==='Base')return '';
 return posix.normalize(posix.isAbsolute(importPath)?importPath.replace(/\.bend$/,''):posix.dirname(parentNamespace)+'/'+importPath.replace(/\.bend$/,''));
}

/** comp.ts `js_tag`: the part after the first `:` of a declared book key. */
export function declaredJsTag(key){
 if(typeof key!=='string'||!key)throw Error('Missing declared constructor key');
 return key.slice(key.indexOf(':')+1);
}

/** Carrier tag for a `comp.ts`-emitted image (`checker_core_component_build`). */
export function sourceFileTagForCompiledImage(namespace){
 if(typeof namespace!=='string')throw Error('BIR module namespace must be a declared source identity');
 return declaredJsTag((namespace?namespace+':':'')+'SourceFile');
}

/** Carrier tag for a selfhost-emitted image: the canonical key verbatim. */
export function sourceFileTagForSelfhostImage(namespace){
 if(typeof namespace!=='string')throw Error('BIR module namespace must be a declared source identity');
 return namespace?namespace+'.SourceFile':'SourceFile';
}

/** The two tag spaces a declared BIR module namespace produces. */
export function sourceFileTagsForNamespace(namespace){
 return [...new Set([sourceFileTagForSelfhostImage(namespace),sourceFileTagForCompiledImage(namespace)])];
}

/** The carrier tag a compiler root's own BIR import produces for one rule. */
export function sourceFileTagFromRoot(rootSource,emitter){
 if(typeof rootSource!=='string')throw Error('Missing compiler root source');
 if(emitter!=='compiled'&&emitter!=='selfhost')throw Error('Missing carrier emitter rule');
 const imports=[...rootSource.matchAll(/^import\s+(\S+)\s+as\s+([A-Za-z_]\w*)\s*$/gm)];
 if(!imports.some(([,path])=>path===OFFICIAL_BIR_IMPORT))throw Error('Compiler root does not declare '+OFFICIAL_BIR_IMPORT);
 const namespace=declaredModuleNamespace('',OFFICIAL_BIR_IMPORT);
 return emitter==='compiled'?sourceFileTagForCompiledImage(namespace):sourceFileTagForSelfhostImage(namespace);
}

/** Seed components are built by comp.ts; their carrier tag is that rule. */
export const COMPILED_SOURCE_FILE_TAG=sourceFileTagForCompiledImage(declaredModuleNamespace('',OFFICIAL_BIR_IMPORT));
/** Selfhost-emitted images carry the canonical qualified key. */
export const SELFHOST_SOURCE_FILE_TAG=sourceFileTagForSelfhostImage(declaredModuleNamespace('',OFFICIAL_BIR_IMPORT));

export function sourceFiles(entries,sourceFileTag){
 const seen=new Map();
 let list={$:'Nil'};
 if(typeof sourceFileTag!=='string'||!(sourceFileTag===COMPILED_SOURCE_FILE_TAG||/^[^:]+\.SourceFile$/.test(sourceFileTag)))
  throw Error('Carrier tag must be a source-derived BIR.SourceFile tag (compiled or selfhost rule), not an ad-hoc name');
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

/**
 * Nominal-only check. The exact tag is derived from the authenticated source
 * closure by the release's constructor-tag rule; if the emitted image registers
 * that exact key, its field schema must be the carrier's. An absent
 * registration is normal (a matching-only component never constructs the
 * carrier), and every other registration is an unrelated record that is
 * ignored rather than judged.
 */
export function verifySourceFileCarrier(componentSource,exactTag){
 if(typeof exactTag!=='string'||!exactTag)throw Error('Missing nominal BIR.SourceFile constructor tag');
 const registered=new RegExp('\\$FIELDS\\["'+exactTag.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')+'"\\]=\\[([^\\]]*)\\];').exec(String(componentSource));
 if(registered&&registered[1]!=='"path","source"')throw Error('Registered '+exactTag+' has fields ['+registered[1]+'], expected ["path","source"]');
 return exactTag;
}

export function sourceFilesFor(modulePath,declaredPaths,carrier){
 return sourceFiles(sourceFileEntries(modulePath,declaredPaths),carrier);
}


/**
 * The trace-only Run value carries exactly one event per boundary. This is a
 * structural limit, not a scheduling rule: the ABI never batches events onto one
 * Run value and this gate never interprets an event. Zero events stays legal
 * because the diagnostic layer, not the ABI gate, judges a boundary's events.
 */
const TRACE_EVENT_LIST_LIMIT=1;

/**
 * Trusted Node orchestration, outside the native Bend termination proof.
 * Template, checker and emitter logic live in native-validated Bend steps.
 * Each host call advances an opaque native-owned Run by one bounded chunk.
 * Stack transitions, requests and source continuations remain entirely native.
 * There are no recursive host calls or host-imposed step/fuel limits.
 *
 * An opt-in diagnostic trace build adds one more Run value, `<Protocol>RunSpan`:
 * one engine-emitted stage-boundary event list plus a deferred next Run. It is an
 * opaque native-owned Run exactly like `RunState` and is advanced by the same
 * single bounded public step call. Its events are never read here, so a trace
 * image advances identically with and without an observer; an ordinary image
 * cannot produce the tag and never enters this branch.
 */
function runSteps(component,startArguments,kind,startExport,stepExport,validateResult,observe){
 if(typeof component?.[startExport]!=='function')invalid(kind,'missing '+startExport+' export');
 if(typeof component?.[stepExport]!=='function')invalid(kind,'missing '+stepExport+' export');
 const stateTag=kind+'RunState',finishedTag=kind+'RunFinished',valueTag=kind+'Value',spanTag=kind+'RunSpan',
  stateSuffix='.'+stateTag,finishedSuffix='.'+finishedTag,valueSuffix='.'+valueTag,spanSuffix='.'+spanTag;
 let knownStateTag,knownFinishedTag,knownValueTag,knownSpanTag,steps=0,run=component[startExport](...startArguments);
 startArguments=undefined;
 try{
  for(;;){
   const tag=run?.$;
   const validRun=run!==null&&typeof run==='object'&&!Array.isArray(run)&&typeof tag==='string';
   if(validRun&&(tag===knownStateTag||tag===stateTag||tag.endsWith(stateSuffix))){
    knownStateTag=tag;
    const next=run;
    run=undefined;
    // Read-only diagnostic observation; absent on every ordinary run.
    if(observe!==undefined)observe.onStep?.(steps,next);
    steps+=1;
    run=component[stepExport](next);
   }else if(validRun&&(tag===knownSpanTag||tag===spanTag||tag.endsWith(spanSuffix))){
    // Diagnostics-only scheduler boundary: the events ride on the Run value and
    // the step export advances it unchanged, observer or not.
    knownSpanTag=tag;
    validateSpanRun(kind,run,spanTag);
    const next=run;
    run=undefined;
    if(observe!==undefined)observe.onStep?.(steps,next);
    steps+=1;
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
    if(observe!==undefined)observe.onFinish?.(value,steps);
    return value;
   }else invalid(kind,'expected '+stateTag+' or '+finishedTag+', observed '+String(tag));
  }
 }catch(error){
  if(observe!==undefined)observe.onError?.(error,steps);
  throw error;
 }
}

function validateSpanRun(kind,run,spanTag){
 if(!Object.hasOwn(run,'events')||!Object.hasOwn(run,'next'))invalid(kind,spanTag+' requires events and next');
 if(typeof run.next!=='function')invalid(kind,spanTag+' next requires a deferred Run function');
 let rest=run.events,count=0;
 for(;;){
  const tag=constructorTag(rest);
  if(tag==='Nil')return;
  if(tag!=='Con')invalid(kind,spanTag+' events requires a native List');
  count+=1;
  if(count>TRACE_EVENT_LIST_LIMIT)invalid(kind,spanTag+' carries more than '+TRACE_EVENT_LIST_LIMIT+' event per boundary');
  if(!hasConstructorTag(rest.head))invalid(kind,spanTag+' events requires nominal trace constructors');
  rest=rest.tail;
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

export function runTemplateSteps(component,modules,observe){
 return runSteps(component,[modules],'Template','expand_modules_start','template_step',validateExpandResult,observe);
}

export function runCheckerSteps(component,modules,observe){
 return runSteps(component,[modules],'Checker','check_expanded_start','checker_step',validateCheckResult,observe);
}

export function runCheckedInspectionSteps(component,program,observe){
 validateCheckedProgram(program);
 return runSteps(component,[program],'Checker','inspect_checked_start','checker_step',validateInspection,observe);
}

export function runEmitterSteps(component,program,files,observe){
 validateCheckedProgram(program);
 validateSourceFiles(files);
 return runSteps(component,[program,files],'Emitter','emit_modules_start','emitter_step',validateEmitResult,observe);
}

export function runLibraryEmitterSteps(component,program,exports,files,observe){
 validateCheckedProgram(program);
 if(!['Nil','Con'].includes(constructorTag(exports)))invalid('Emitter','library start requires explicit native exports list');
 validateSourceFiles(files);
 return runSteps(component,[program,exports,files],'Emitter','emit_library_start','emitter_step',validateEmitResult,observe);
}

export function runCEmitterSteps(component,program,runtime,files,observe){
 validateCheckedProgram(program);
 if(typeof runtime!=='string')invalid('Emitter','runtime source must be a string, not a path');
 validateSourceFiles(files);
 return runSteps(component,[program,runtime,files],'Emitter','emit_c_modules_start','c_emitter_step',validateEmitResult,observe);
}

export function runCLibraryEmitterSteps(component,program,exports,runtime,files,observe){
 validateCheckedProgram(program);
 if(!['Nil','Con'].includes(constructorTag(exports)))invalid('Emitter','library start requires explicit native exports list');
 if(typeof runtime!=='string')invalid('Emitter','runtime source must be a string, not a path');
 validateSourceFiles(files);
 return runSteps(component,[program,exports,runtime,files],'Emitter','emit_c_library_start','c_emitter_step',validateEmitResult,observe);
}
