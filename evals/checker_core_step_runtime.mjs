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
 * Trusted Node orchestration, outside the native Bend termination proof.
 * Template, checker and emitter logic live in native-validated Bend steps.
 * Each host call advances an opaque native-owned Run by one bounded chunk.
 * Stack transitions, requests and source continuations remain entirely native.
 * There are no recursive host calls or host-imposed step/fuel limits.
 */
function runSteps(component,modules,kind,startExport,stepExport,validateResult,exports){
 if(typeof component?.[startExport]!=='function')invalid(kind,'missing '+startExport+' export');
 if(typeof component?.[stepExport]!=='function')invalid(kind,'missing '+stepExport+' export');
 const stateTag=kind+'RunState',finishedTag=kind+'RunFinished',valueTag=kind+'Value',stateSuffix='.'+stateTag,finishedSuffix='.'+finishedTag,valueSuffix='.'+valueTag;
 let knownStateTag,knownFinishedTag,knownValueTag,run=exports===undefined?component[startExport](modules):component[startExport](modules,exports);
 modules=undefined;
 exports=undefined;
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

export function runTemplateSteps(component,modules){
 return runSteps(component,modules,'Template','expand_modules_start','template_step',validateExpandResult);
}

export function runCheckerSteps(component,modules){
 return runSteps(component,modules,'Checker','check_expanded_start','checker_step',validateCheckResult);
}

export function runCheckedInspectionSteps(component,program){
 validateCheckedProgram(program);
 return runSteps(component,program,'Checker','inspect_checked_start','checker_step',validateInspection);
}

export function runEmitterSteps(component,program){
 validateCheckedProgram(program);
 return runSteps(component,program,'Emitter','emit_modules_start','emitter_step',validateEmitResult);
}

export function runLibraryEmitterSteps(component,program,exports){
 validateCheckedProgram(program);
 if(!['Nil','Con'].includes(constructorTag(exports)))invalid('Emitter','library start requires explicit native exports list');
 return runSteps(component,program,'Emitter','emit_library_start','emitter_step',validateEmitResult,exports);
}
