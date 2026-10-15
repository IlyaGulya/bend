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
 * One LIFO loop passes values through unchanged, including the single native
 * argument record consumed by a source-supplied direct invoker.
 * There are no recursive host calls or host-imposed step/fuel limits.
 */
function runSteps(component,modules,kind,startExport,stepExport,validateResult){
 if(typeof component?.[startExport]!=='function')invalid(kind,'missing '+startExport+' export');
 if(typeof component?.[stepExport]!=='function')invalid(kind,'missing '+stepExport+' export');
 const pendingTag=kind+'Pending',directTag=kind+'Direct',finishedTag=kind+'Finished',pendingSuffix='.'+pendingTag,directSuffix='.'+directTag,finishedSuffix='.'+finishedTag,resumes=[];
 let depth=0,knownPendingTag,knownDirectTag,knownFinishedTag,progress=component[startExport](modules);
 modules=undefined;
 for(;;){
  const tag=progress?.$;
  // Matching a progress suffix also proves a nonempty, non-trailing-dot tag.
  const validProgress=progress!==null&&typeof progress==='object'&&!Array.isArray(progress)&&typeof tag==='string';
  // A cached kind cannot match another kind's disjoint constructor suffix.
  if(validProgress&&(tag===knownPendingTag||(tag!==knownDirectTag&&tag!==knownFinishedTag&&(tag===pendingTag||tag.endsWith(pendingSuffix))))){
   knownPendingTag=tag;
   if(!Object.hasOwn(progress,'request')||!hasConstructorTag(progress.request))invalid(kind,pendingTag+' requires a constructor-tagged request');
   if(typeof progress.resume!=='function')invalid(kind,pendingTag+' requires a callable resume');
   resumes[depth++]=progress.resume;
   const request=progress.request;
   progress=undefined;
   progress=component[stepExport](request);
  }else if(validProgress&&(tag===knownDirectTag||(tag!==knownFinishedTag&&(tag===directTag||tag.endsWith(directSuffix))))){
   knownDirectTag=tag;
   if(typeof progress.invoke!=='function')invalid(kind,directTag+' requires a callable invoke');
   if(typeof progress.resume!=='function')invalid(kind,directTag+' requires a callable resume');
   if(!Object.hasOwn(progress,'arguments'))invalid(kind,directTag+' requires arguments');
   resumes[depth++]=progress.resume;
   const invoke=progress.invoke,arguments_=progress.arguments;
   progress=undefined;
   progress=invoke(arguments_);
  }else if(validProgress&&(tag===knownFinishedTag||tag===finishedTag||tag.endsWith(finishedSuffix))){
   knownFinishedTag=tag;
   if(!Object.hasOwn(progress,'value'))invalid(kind,finishedTag+' requires value');
   const value=progress.value;
   progress=undefined;
   if(depth){
    const resume=resumes[--depth];
    resumes[depth]=undefined;
    progress=resume(value);
   }else{
    validateResult(value);
    return value;
   }
  }else invalid(kind,'expected '+pendingTag+', '+directTag+' or '+finishedTag+', observed '+String(tag));
 }
}

function validateCheckResult(value){
 const resultTag=constructorTag(value);
 if(resultTag==='CheckSuccess'){
  if(!Object.hasOwn(value,'modules')||!['Nil','Con'].includes(constructorTag(value.modules)))invalid('Checker','CheckSuccess requires native modules');
 }else if(resultTag==='CheckFailure'){
  if(!Object.hasOwn(value,'diagnostic')||constructorTag(value.diagnostic)!=='Diagnostic')invalid('Checker','CheckFailure requires a native Diagnostic');
 }else invalid('Checker','expected CheckResult, observed '+String(resultTag));
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

export function runEmitterSteps(component,modules){
 return runSteps(component,modules,'Emitter','emit_modules_start','emitter_step',validateEmitResult);
}

export function runLibraryEmitterSteps(component,modules){
 return runSteps(component,modules,'Emitter','emit_library_start','emitter_step',validateEmitResult);
}
