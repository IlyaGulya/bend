// Diagnostic only: classify actual C-emitter boundaries, then stop without C.
const IMAGE_SHA='146b191bbcb7e85bc5115e086dcc08b24ce860ee110ae03d0312ec4f5ec585e4';
const LIMITS={clockEverySteps:4096,intervalMs:100,emitDelayMs:60000,windowMs:20000,
 maxKinds:128,maxRepresentatives:16,maxFields:16,maxDepth:3,maxNodes:64,maxString:200};
const tag=value=>typeof value?.$==='string'?value.$:null;
const short=value=>({value:value.slice(0,LIMITS.maxString),truncated:value.length>LIMITS.maxString});
function describe(value,depth=0,budget={left:LIMITS.maxNodes}){
 if(--budget.left<0)return {truncated:true};
 if(typeof value==='string')return {string:short(value)};
 if(typeof value==='bigint'||typeof value==='number'||typeof value==='boolean')return {scalar:String(value)};
 if(value===null||typeof value!=='object')return {type:typeof value};
 if(value instanceof Map)return {type:'native-js-map',size:value.size};
 const result={tag:tag(value)};
 if(depth>=LIMITS.maxDepth)return {...result,truncated:true};
 if(result.tag==='emitter_steps_v1.cps_provider_3_Context'){
  result.plan=describe(value.plan,depth+1,budget);
  return result;
 }
 const fields={};let count=0;
 // Inspect the new fact table before unrelated node/arm catalog data consumes
 // the metadata budget. This reads values only; it never runs Bend lookups.
 if(Object.hasOwn(value,'closed')){
  fields.closed=describe(value.closed,depth+1,budget);count++;
 }
 for(const name in value){
  if(!Object.hasOwn(value,name)||name==='$'||name==='closed')continue;
  if(count++>=LIMITS.maxFields){result.fieldsTruncated=true;break;}
  fields[name]=describe(value[name],depth+1,budget);
 }
 return {...result,fields};
}
export function createNfProgressProbe(profile,imageSha){
 if(imageSha!==IMAGE_SHA)throw Error('Phase observation requires exact native-emitted R11 image146; fixedpoint is not established');
 let firstEmitAt,nextAt=0,samples=0,unrepresentedSamples=0;
 const kinds=new Map(),representatives=[];
 profile.record({kind:'nf-phase-probe',name:'nf-phase-contract',scope:'actual readonly C-emitter Pending boundary samples',
  values:LIMITS,details:{imageSha,acceptanceEvidence:false,byteFixedpointClaim:false,
   stop:'Intentional failure after one20-second observation window starting after60 emit seconds; no C output or workload acceptance.',
   semantics:'No normalizer call, graph/fact evaluation, program mutation or reduced import closure. Counts are boundary samples, not invocations or exclusive CPU.'}});
 return (steps,run)=>{
  if(firstEmitAt===undefined)firstEmitAt=performance.now();
  if(steps%LIMITS.clockEverySteps!==0)return;
  const now=performance.now(),elapsed=now-firstEmitAt;
  if(elapsed<LIMITS.emitDelayMs||now<nextAt)return;
  nextAt=now+LIMITS.intervalMs;
  let progress=run?.progress,depth=0;
  for(;depth<64;depth++){
   const name=tag(progress);
   if(name==='emitter_steps_v1.EmitterBound'){progress=progress.inner;continue;}
   if(name==='emitter_steps_v1.EmitterRunState'){progress=progress.progress;continue;}
   break;
  }
  const request=tag(progress)==='emitter_steps_v1.EmitterPending'?progress.request?.request:undefined;
  const name=tag(request)??tag(progress)??'unrecognized-progress';
  samples++;
  if(kinds.has(name))kinds.set(name,kinds.get(name)+1);
  else if(kinds.size<LIMITS.maxKinds){
   kinds.set(name,1);
   if(representatives.length<LIMITS.maxRepresentatives)representatives.push({
    name,hostStepOrdinal:steps,emitObservedElapsedMs:elapsed,unwrapLimitReached:depth===64,
    request:describe(request??progress)});
  }else unrepresentedSamples++;
  if(elapsed<LIMITS.emitDelayMs+LIMITS.windowMs)return;
  profile.record({kind:'nf-layout-phase-observation',name:'actual-layout-boundary-window',summary:false,
   scope:'sampled genuine native-emitted R11 image; not fixedpoint, invocation counts or exclusive CPU',
   details:{imageSha,hostStepOrdinal:steps,emitObservedElapsedMs:elapsed,samples,unrepresentedSamples,
    kinds:[...kinds].map(([name,count])=>({name,count})),representatives,
    coverage:'One late finite boundary window. Request payloads, fields, depth, nodes and strings are explicitly bounded. No raw AST/book/image is retained.'}});
  throw Error('NF_LAYOUT_PHASE_OBSERVATION_COMPLETE: intentional diagnostic stop, not acceptance');
 };
}
