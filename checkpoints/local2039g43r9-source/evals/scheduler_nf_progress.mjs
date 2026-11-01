import {createHash} from 'node:crypto';

// Read-only argument sampling for the exact genuine G43 stage-one image.
// These field names are verified against that image's $FIELDS declarations and
// checkpoints/emitter_steps_v1.bend. No source call, continuation or getter runs.
const IMAGE_SHA='85aff9e534c18b4a1d6acac5f3237571dabc58f2c1a75a7ea2040f1c477ab60e';
const PREFIX='emitter_steps_v1.EmitterRequest_';
const LIMITS=Object.freeze({intervalMs:100,clockEverySteps:4096,maxSamples:6000,
 maxNodes:4096,maxDepth:64,maxCharacters:32768,maxKeys:64,maxRepeatKeys:4096,listPrefix:256});

// The digest includes every data field, not only descriptor names. An incomplete
// walk NEVER yields a comparable key. DAG sharing is expanded; cycles fail closed.
function fingerprint(value){
 const hash=createHash('sha256'),active=new Set();
 let nodes=0,characters=0,reason=null;
 function put(text){
  characters+=text.length;
  if(characters>LIMITS.maxCharacters){reason='character-limit';return false;}
  hash.update(text);return true;
 }
 function walk(item,depth){
  if(++nodes>LIMITS.maxNodes){reason='node-limit';return false;}
  if(depth>LIMITS.maxDepth){reason='depth-limit';return false;}
  if(item===null)return put('null;');
  switch(typeof item){
   case 'string':
    if(item.length>LIMITS.maxCharacters){reason='string-limit';return false;}
    return put('s'+JSON.stringify(item)+';');
   case 'bigint':return put('i'+String(item)+';');
   case 'number':return put('n'+(Object.is(item,-0)?'-0':String(item))+';');
   case 'boolean':return put(item?'true;':'false;');
   case 'undefined':reason='missing-value';return false;
   case 'object':break;
   default:reason='non-data-value';return false;
  }
  if(active.has(item)){reason='cycle';return false;}
  const prototype=Object.getPrototypeOf(item);
  if(prototype!==Object.prototype&&prototype!==null&&!Array.isArray(item)){reason='non-record';return false;}
  const keys=Object.keys(item).sort();
  if(keys.length>LIMITS.maxKeys){reason='key-limit';return false;}
  active.add(item);
  if(!put(Array.isArray(item)?'array:'+item.length+'{':'object{'))return false;
  for(const key of keys){
   const property=Object.getOwnPropertyDescriptor(item,key);
   if(!property||!Object.hasOwn(property,'value')){reason='accessor';return false;}
   if(!put(JSON.stringify(key)+':')||!walk(property.value,depth+1))return false;
  }
  active.delete(item);
  return put('}');
 }
 const complete=walk(value,0);
 return {complete,sha256:complete?hash.digest('hex'):null,nodes,characters,reason};
}

function listSummary(value){
 let rest=value,length=0;
 for(;length<LIMITS.listPrefix;length++){
  if(typeof rest?.$!=='string')return {length,complete:false,reason:'not-list'};
  const tag=rest.$.slice(rest.$.lastIndexOf('.')+1);
  if(tag==='Nil')return {length,complete:true};
  if(tag!=='Con')return {length,complete:false,reason:'not-list'};
  rest=rest.tail;
 }
 return {length,complete:false,reason:'prefix-limit'};
}

export function createNfProgressProbe(profile,imageSha){
 if(imageSha!==IMAGE_SHA)throw Error('NF argument probe requires the pinned genuine G43 image');
 const REQUESTS=new Map([
  ['cps_provider_7_nf_all',{context:'v_1',term:'v_3',env:'v_6',level:'v_8',fuel:'v_10',list:true}],
  ['cps_provider_7_nf_descriptor_step',{context:'v_1',term:'v_2',env:'v_5',level:'v_7',fuel:'v_9'}],
  ['cps_provider_3_reach_arms',{context:'v_1',term:'v_3',env:'v_6',target:'v_8',seen:'v_11',fuel:'v_13',layout:true,list:true}],
 ]);
 const identities=new WeakMap(),repeats=new Map();
 let identitySequence=0,samples=0,nextAt=0;
 function identity(value){
  if(value===null||typeof value!=='object')return null;
  let id=identities.get(value);
  if(id===undefined){id=++identitySequence;identities.set(value,id);}
  return id;
 }
 profile.record({kind:'nf-argument-probe',name:'nf-probe-contract',scope:'read-only sampled host boundary arguments',
  values:LIMITS,source:'evals/scheduler_nf_progress.mjs',details:{imageSha,acceptanceEvidence:false,
   keySemantics:'Complete structural data fingerprints plus process-local context table identities. Fuel and seen path are included. Repeated samples are not call counts, CPU shares, or proof that caching is sound.',
   contextSemantics:'NF reads families/type_functions maps; layout reachability reads the same maps through ctx.context. Different context IDs are not evidence of different contents.',
   coverage:'Only three exact Pending requests, sampled after 4096-step clock checks at most every 100ms; Direct payloads are erased. Truncation yields no comparable key. No payload objects retained.',
   intervalSemantics:'Emitter step-interval attribution disabled for this diagnostic; coarse phase wall includes instrumentation.'}});
 return (steps,run)=>{
  if(samples>=LIMITS.maxSamples||steps%LIMITS.clockEverySteps!==0)return;
  const now=performance.now();
  if(now<nextAt)return;
  nextAt=now+LIMITS.intervalMs;samples++;
  let progress=run?.progress,depth=0;
  for(;depth<64;depth++){
   const tag=progress?.$;
   if(tag==='emitter_steps_v1.EmitterBound'){progress=progress.inner;continue;}
   if(tag==='emitter_steps_v1.EmitterRunState'){progress=progress.progress;continue;}
   break;
  }
  const request=progress?.$==='emitter_steps_v1.EmitterPending'?progress.request?.request:undefined;
  const name=typeof request?.$==='string'&&request.$.startsWith(PREFIX)?request.$.slice(PREFIX.length):null;
  const spec=REQUESTS.get(name);
  const details={sample:samples,hostStepOrdinal:steps,progress:progress?.$??null,request:name,
   coverage:spec?'selected-request':depth===64?'depth-limit':'unselected-or-erased'};
  if(spec){
   const fields=[spec.context,spec.term,spec.env,spec.fuel,...(spec.level?[spec.level]:[]),
    ...(spec.target?[spec.target,spec.seen]:[])];
   if(fields.some(field=>!Object.hasOwn(request,field)))throw Error('Pinned NF request schema mismatch: '+name);
   const ctx=spec.layout?request[spec.context]?.context:request[spec.context];
   const validContext=ctx?.$==='emitter_steps_v1.cps_provider_7_NfContext'
    &&ctx.families!==null&&typeof ctx.families==='object'
    &&ctx.type_functions!==null&&typeof ctx.type_functions==='object';
   if(!validContext)throw Error('Pinned NF context schema mismatch: '+name);
   const context={families:identity(ctx.families),typeFunctions:identity(ctx.type_functions)};
   const term=request[spec.term],env=request[spec.env];
   const parts={term:fingerprint(term),env:fingerprint(env),fuel:fingerprint(request[spec.fuel])};
   if(spec.level)parts.level=fingerprint(request[spec.level]);
   if(spec.seen)parts.seen=fingerprint(request[spec.seen]);
   if(spec.target)parts.target=fingerprint(request[spec.target]);
   const complete=Object.values(parts).every(part=>part.complete);
   let key=null,occurrences=null,tracking='incomplete-key';
   if(complete){
    key=createHash('sha256').update(JSON.stringify({name,context,
     parts:Object.fromEntries(Object.entries(parts).map(([key,value])=>[key,value.sha256]))})).digest('hex');
    const old=repeats.get(key);
    if(old!==undefined||repeats.size<LIMITS.maxRepeatKeys){
     occurrences=(old??0)+1;repeats.set(key,occurrences);tracking='tracked';
    }else tracking='repeat-table-full';
   }
   const head=spec.list?term?.head:term;
   Object.assign(details,{context,parts,complete,key,occurrences,tracking,trackedKeys:repeats.size,
    termTag:term?.$??null,headTag:head?.$??null,
    headKey:typeof head?.key==='string'?head.key.slice(0,160):null,
    headKeyTruncated:typeof head?.key==='string'&&head.key.length>160,
    termList:spec.list?listSummary(term):null,envList:listSummary(env),
    target:spec.target&&typeof request[spec.target]==='string'?request[spec.target].slice(0,160):null,
    targetTruncated:spec.target&&typeof request[spec.target]==='string'&&request[spec.target].length>160,
    seenList:spec.seen?listSummary(request[spec.seen]):null,
    level:spec.level&&['number','bigint'].includes(typeof request[spec.level])?String(request[spec.level]):null,
    fuel:['number','bigint'].includes(typeof request[spec.fuel])?String(request[spec.fuel]):null});
  }
  profile.record({kind:'nf-argument-sample',name:'emit-nf-arguments',scope:'sampled Pending request before one public quantum64 step',
   units:'boundary-samples',value:samples,source:'evals/scheduler_nf_progress.mjs',summary:false,details});
 };
}
