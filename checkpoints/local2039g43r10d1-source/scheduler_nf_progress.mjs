// Diagnostic only: inspect one actual slow layout family, then stop without C.
const IMAGE_SHA='f5151acbd83e51ef32fa618b175b31cc18d91fd71677b2b5a60dfc5b0ac807eb';
const REQUEST='emitter_steps_v1.EmitterRequest_cps_provider_3_reach_arms';
const LIMITS={clockEverySteps:4096,intervalMs:100,emitDelayMs:5000,targetSamples:3,
 maxFamilies:32768,maxArms:256,maxFields:64,maxArgs:8,maxDepth:4,maxNodes:128,maxString:200};
const tag=value=>typeof value?.$==='string'?value.$:null;
const short=value=>typeof value==='string'?{value:value.slice(0,LIMITS.maxString),truncated:value.length>LIMITS.maxString}:null;
const scalar=value=>typeof value==='bigint'||typeof value==='number'?String(value):null;
function list(value,limit){
 const items=[];let rest=value;
 for(let i=0;i<limit;i++){
  const name=tag(rest)?.split('.').at(-1);
  if(name==='Nil')return {items,complete:true};
  if(name!=='Con')return {items,complete:false,reason:'not-list',tag:tag(rest)};
  items.push(rest.head);rest=rest.tail;
 }
 return {items,complete:false,reason:'list-limit'};
}
function descriptor(value,depth=0,budget={left:LIMITS.maxNodes}){
 if(--budget.left<0||depth>LIMITS.maxDepth)return {tag:tag(value),truncated:true};
 if(typeof value==='string')return {string:short(value)};
 if(value===null||typeof value!=='object')return {scalar:scalar(value),unsupported:typeof value};
 const result={tag:tag(value)};
 if(typeof value.key==='string')result.key=short(value.key);
 if(value.index!==undefined)result.index=scalar(value.index);
 for(const name of ['head','fn','arg','domain','body','value','left','right','source','ty']){
  if(Object.hasOwn(value,name))result[name]=descriptor(value[name],depth+1,budget);
 }
 if(Object.hasOwn(value,'args')){
  const args=list(value.args,LIMITS.maxArgs);
  result.args={...args,items:args.items.map(item=>descriptor(item,depth+1,budget))};
 }
 return result;
}
function fields(value){
 const values=list(value,LIMITS.maxFields);
 return {...values,items:values.items.map(field=>({tag:tag(field),key:descriptor(field.key),
  quantity:tag(field.quantity),type:descriptor(field.ty)}))};
}
function arms(value,limit=LIMITS.maxArms){
 const values=list(value,limit);
 return {...values,items:values.items.map(arm=>({key:short(arm.key),fields:fields(arm.fields)}))};
}
function familyIn(value,key){
 let rest=value;
 for(let i=0;i<LIMITS.maxFamilies;i++){
  const name=tag(rest)?.split('.').at(-1);
  if(name==='Nil')return {found:false,visited:i,complete:true};
  if(name!=='Con')return {found:false,visited:i,complete:false,reason:'not-family-list',tag:tag(rest)};
  const family=rest.head;
  if(family?.key===key)return {found:true,visited:i+1,complete:true,
   family:{tag:tag(family),key:short(family.key),name:short(family.name),native:descriptor(family.native),
    arity:scalar(family.arity),quantityPrefix:scalar(family.quantity_prefix),arms:arms(family.arms)}};
  rest=rest.tail;
 }
 return {found:false,complete:false,reason:'family-limit'};
}
export function createNfProgressProbe(profile,imageSha){
 if(imageSha!==IMAGE_SHA)throw Error('Family observation requires the exact genuine R10 image');
 let firstEmitAt,nextAt=0,observations=0;
 const targets=new Map();
 profile.record({kind:'nf-family-probe',name:'nf-family-contract',scope:'actual readonly C-layout context',
  values:LIMITS,details:{imageSha,acceptanceEvidence:false,stop:'Intentional command failure immediately after one actual family observation; no C output or workload completion is claimed.',
   semantics:'Observed arm order, quantities and bounded descriptor shapes only. No normalizer call, cache, program mutation or reduced import closure.'}});
 return (steps,run)=>{
  if(firstEmitAt===undefined)firstEmitAt=performance.now();
  if(steps%LIMITS.clockEverySteps!==0)return;
  const now=performance.now();
  if(now-firstEmitAt<LIMITS.emitDelayMs||now<nextAt)return;
  nextAt=now+LIMITS.intervalMs;
  let progress=run?.progress;
  for(let depth=0;depth<64;depth++){
   const name=tag(progress);
   if(name==='emitter_steps_v1.EmitterBound'){progress=progress.inner;continue;}
   if(name==='emitter_steps_v1.EmitterRunState'){progress=progress.progress;continue;}
   break;
  }
  const request=tag(progress)==='emitter_steps_v1.EmitterPending'?progress.request?.request:undefined;
  if(tag(request)!==REQUEST)return;
  for(const name of ['v_1','v_3','v_6','v_8','v_11','v_13'])
   if(!Object.hasOwn(request,name))throw Error('Pinned family request schema mismatch: '+name);
  const target=request.v_8,ctx=request.v_1;
  if(typeof target!=='string'||tag(ctx)!=='emitter_steps_v1.cps_provider_3_Context')throw Error('Pinned layout context schema mismatch');
  observations++;
  const count=(targets.get(target)??0)+1;
  if(targets.size<16||targets.has(target))targets.set(target,count);
  if(count<LIMITS.targetSamples)return;
  const seen=list(request.v_11,32),env=list(request.v_6,LIMITS.maxArgs);
  profile.record({kind:'nf-layout-family-observation',name:'actual-slow-layout-family',summary:false,
   scope:'sampled genuine emitter Pending request; not exclusive CPU or invocation counts',
   details:{imageSha,hostStepOrdinal:steps,emitObservedElapsedMs:now-firstEmitAt,observations,targetSamples:count,
    target:short(target),fuel:scalar(request.v_13),contextTag:tag(ctx),root:familyIn(ctx.families,target),
    currentArms:arms(request.v_3,8),seen:{...seen,items:seen.items.map(short)},
    env:{...env,items:env.items.map(value=>descriptor(value))},
    coverage:'Lists, strings and descriptor recursion are explicitly bounded. No raw AST/book/image is retained. The target is sampled after five emit seconds, not assumed to be CheckerProgress.'}});
  throw Error('NF_LAYOUT_FAMILY_OBSERVATION_COMPLETE: intentional diagnostic stop, not acceptance');
 };
}
