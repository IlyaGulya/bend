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
 * One LIFO loop passes affine result boxes through unchanged, including the
 * single native argument record consumed by a source-supplied direct invoker.
 * There are no recursive host calls or host-imposed step/fuel limits.
 */
function runSteps(component,modules,kind,startExport,stepExport,validateResult,exports){
 if(typeof component?.[startExport]!=='function')invalid(kind,'missing '+startExport+' export');
 if(typeof component?.[stepExport]!=='function')invalid(kind,'missing '+stepExport+' export');
 const pendingTag=kind+'Pending',directTag=kind+'Direct',boundTag=kind+'Bound',finishedTag=kind+'Finished',valueTag=kind+'Value',pendingSuffix='.'+pendingTag,directSuffix='.'+directTag,boundSuffix='.'+boundTag,finishedSuffix='.'+finishedTag,valueSuffix='.'+valueTag,resumes=[];
 let depth=0,knownPendingTag,knownDirectTag,knownBoundTag,knownFinishedTag,knownValueTag,progress=exports===undefined?component[startExport](modules):component[startExport](modules,exports);
 modules=undefined;
 for(;;){
  const tag=progress?.$;
  // Matching a progress suffix also proves a nonempty, non-trailing-dot tag.
  const validProgress=progress!==null&&typeof progress==='object'&&!Array.isArray(progress)&&typeof tag==='string';
  // A cached kind cannot match another kind's disjoint constructor suffix.
  if(validProgress&&(tag===knownPendingTag||(tag!==knownDirectTag&&tag!==knownBoundTag&&tag!==knownFinishedTag&&(tag===pendingTag||tag.endsWith(pendingSuffix))))){
   knownPendingTag=tag;
   if(!Object.hasOwn(progress,'request')||!hasConstructorTag(progress.request))invalid(kind,pendingTag+' requires a constructor-tagged request');
   if(typeof progress.resume!=='function')invalid(kind,pendingTag+' requires a callable resume');
   resumes[depth++]=progress.resume;
   const request=progress.request;
   progress=undefined;
   progress=component[stepExport](request);
  }else if(validProgress&&(tag===knownDirectTag||(tag!==knownBoundTag&&tag!==knownFinishedTag&&(tag===directTag||tag.endsWith(directSuffix))))){
   knownDirectTag=tag;
   if(typeof progress.invoke!=='function')invalid(kind,directTag+' requires a callable invoke');
   if(typeof progress.resume!=='function')invalid(kind,directTag+' requires a callable resume');
   if(!Object.hasOwn(progress,'arguments'))invalid(kind,directTag+' requires arguments');
   resumes[depth++]=progress.resume;
   const invoke=progress.invoke,arguments_=progress.arguments;
   progress=undefined;
   progress=invoke(arguments_);
  }else if(validProgress&&(tag===knownBoundTag||(tag!==knownFinishedTag&&(tag===boundTag||tag.endsWith(boundSuffix))))){
   knownBoundTag=tag;
   if(!Object.hasOwn(progress,'inner'))invalid(kind,boundTag+' requires inner progress');
   if(typeof progress.resume!=='function')invalid(kind,boundTag+' requires a callable resume');
   resumes[depth++]=progress.resume;
   const inner=progress.inner;
   progress=undefined;
   progress=inner;
  }else if(validProgress&&(tag===knownFinishedTag||tag===finishedTag||tag.endsWith(finishedSuffix))){
   knownFinishedTag=tag;
   if(!Object.hasOwn(progress,'box'))invalid(kind,finishedTag+' requires box');
   const box=progress.box,boxTag=box?.$;
   if(box===null||typeof box!=='object'||Array.isArray(box)||typeof boxTag!=='string'||!(boxTag===knownValueTag||boxTag===valueTag||boxTag.endsWith(valueSuffix))||!Object.hasOwn(box,'value'))invalid(kind,finishedTag+' requires '+valueTag+' box with value');
   knownValueTag=boxTag;
   progress=undefined;
   if(depth){
    const resume=resumes[--depth];
    resumes[depth]=undefined;
    progress=resume(box);
   }else{
    const value=box.value;
    validateResult(value);
    return value;
   }
  }else invalid(kind,'expected '+pendingTag+', '+directTag+', '+boundTag+' or '+finishedTag+', observed '+String(tag));
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
