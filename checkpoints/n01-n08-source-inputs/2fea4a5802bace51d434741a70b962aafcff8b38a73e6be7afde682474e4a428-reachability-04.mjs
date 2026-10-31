import {createHash} from 'node:crypto';
import {readFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import * as producer from './occurrences.mjs';

// Diagnostic-only: no source FIR, arena, registry, environment or argument writes.
const IMAGE = '85aff9e534c18b4a1d6acac5f3237571dabc58f2c1a75a7ea2040f1c477ab60e';
const PRODUCER = '2505b8f82b3c46ff309ae82cff12f1bfbc0bbf5fbe0cdc287781035c5cf0038a';
const ROWS = '73d8a0c49975e93771b19fbbc8a7b4756cd4ff5316f19d685e1a76ded5639aeb';
const BASELINES = {
  c: {sha256:'44a2f5d8289aa58ac459ba36d596ebbb589088987bd97b55aa443c6133a00579', steps:1239542},
  js:{sha256:'4316079cc1099455a3d791c5b1d1b8d6d0488c66483225609f8927ee803eb61c', steps:15932},
};
const GLOBAL = '__bendN07Reachability04';
const digest = s => createHash('sha256').update(s).digest('hex');
const tag = o => o?.$?.split('.').at(-1);
const key = r => JSON.stringify([r.definition,r.path]);
const facts = r => JSON.stringify({...r, definition:undefined, path:undefined});
const identities = new WeakMap();
const counts = new Map();
const firstByTerm = new Map();
const annotations = [];
const hookCounts = {lower:0,root:0,annotation:0,knownLower:0,knownRoot:0,unknownInSelectedDefinition:0,ambiguous:0};
const errors = [];
const diagnosticCollapses = [];
let selectedDefinition = null;
let target = null;
let rows = [];
let emitterSteps = null;
let emitted = null;
let metadata = null;

function list(xs) {
  const out=[];
  while(tag(xs)==='Con') {
    if(out.length>=32768) throw Error('N07 reachability list bound');
    out.push(xs.head); xs=xs.tail;
  }
  if(tag(xs)!=='Nil') throw Error('N07 reachability malformed observed list');
  return out;
}
function identify(object) {
  const found=identities.get(object);
  if(!found) return null;
  if(found.length!==1) {hookCounts.ambiguous++; return null;}
  return found[0];
}
function observe(kind,object) {
  hookCounts[kind]++;
  const row=identify(object);
  if(kind==='root') selectedDefinition=row?.definition ?? null;
  if(!row) {
    if(selectedDefinition!==null) hookCounts.unknownInSelectedDefinition++;
    return;
  }
  hookCounts[kind==='root'?'knownRoot':'knownLower']++;
  const count=counts.get(key(row)); count[kind]++;
  // The negative representation is a scalar copy with first-wins term indexing.
  // Actual lowering still receives the untouched original occurrence.
  const collapsed=firstByTerm.get(row.term);
  if(facts(collapsed)!==facts(row)) diagnosticCollapses.push({current:key(row),first:key(collapsed),term:row.term,kind});
}
function annotation(children) {
  hookCounts.annotation++;
  const xs=list(children);
  if(xs.length!==2) {errors.push('Actual annotated_child received nonbinary children'); return;}
  const selected=identify(xs[0]), discarded=identify(xs[1]);
  if(!selected || !discarded) {
    if(selectedDefinition!==null) hookCounts.unknownInSelectedDefinition++;
    return;
  }
  counts.get(key(discarded)).annotationDiscard++;
  annotations.push({selected:key(selected),discarded:key(discarded),discardedTerm:discarded.term});
}
function mapOccurrence(object,definition,path,byPath,depth=0) {
  if(depth>256) throw Error('N07 reachability depth bound');
  const row=byPath.get(JSON.stringify([definition,path]));
  if(!row) throw Error(`N07 reachability missing published path ${definition}:${path}`);
  const existing=identities.get(object);
  if(existing) existing.push(row); else identities.set(object,[row]);
  if(tag(object)==='TypedOccurrence') list(object.children).forEach((child,i)=>mapOccurrence(child,definition,`${path}/children/${i}`,byPath,depth+1));
  else if(tag(object)==='LocalOccurrence') {
    list(object.values).forEach((child,i)=>mapOccurrence(child,definition,`${path}/values/${i}`,byPath,depth+1));
    mapOccurrence(object.body,definition,`${path}/body`,byPath,depth+1);
  } else if(tag(object)==='CaseOccurrence') {
    mapOccurrence(object.body,definition,`${path}/body`,byPath,depth+1);
  }
}
export function instrument(source,context) {
  if(digest(source)!==IMAGE) throw Error('N07 reachability genuine image digest mismatch');
  if(digest(readFileSync(fileURLToPath(new URL('./occurrences.mjs',import.meta.url))))!==PRODUCER) throw Error('N07 immutable producer plugin digest mismatch');
  if(!BASELINES[context.target]) throw Error('N07 reachability unsupported target');
  target=context.target;
  producer.instrument(source,context);
  if(globalThis[GLOBAL]!==undefined) throw Error('N07 reachability global already installed');
  globalThis[GLOBAL]=Object.freeze({lower:o=>observe('lower',o),root:o=>observe('root',o),annotation});
  const hooks=[];
  for(const [name,arity,method] of [['lower_occurrence',4,'lower'],['definition_root',5,'root'],['annotated_child',5,'annotation']]) {
    const declaration='emitter_steps_v1.emitter_body_cps_provider_1_'+name;
    const prefix='$D['+JSON.stringify(declaration)+']=';
    const lines=source.split('\n').filter(line=>line.startsWith(prefix));
    if(lines.length!==1) throw Error(`N07 declaration cardinality ${declaration}: ${lines.length}`);
    const direct=lines[0].match(/\?\s*(\$b\d+)\(/);
    if(!direct) throw Error(`N07 missing mapped direct callee ${declaration}`);
    const binding=direct[1];
    const opener=`function ${binding}(${Array.from({length:arity},(_,i)=>'$v'+i).join(',')},$td=0){`;
    const at=source.indexOf(opener);
    if(at<0 || source.indexOf(opener,at+1)>=0) throw Error(`N07 hook signature/cardinality ${binding}`);
    const end=source.indexOf('\n',at);
    hooks.push({declaration,binding,arity,declarationSha256:digest(lines[0]),bodySha256:digest(source.slice(at,end)),argument:'$v1'});
    source=source.slice(0,at+opener.length)+`globalThis.${GLOBAL}.${method}($v1);`+source.slice(at+opener.length);
  }
  metadata={kind:'passive-original-occurrence-identity-reachability',imageSha256:IMAGE,producerPluginSha256:PRODUCER,hooks,transformedSha256:digest(source),retention:'WeakMap keys only; values and durable events are scalar diagnostic copies',mutation:'first-wins scalar diagnostic fact table only; compiler objects unchanged'};
  return {source,metadata};
}
export function onPhase(name,value) {
  producer.onPhase(name,value);
  if(name==='check' && tag(value)==='CheckSuccess') {
    const snapshot=producer.snapshot();
    if(snapshot.rowsSha256!==ROWS) throw Error('N07 source producer rows drifted from authenticated scalar-record baseline');
    rows=snapshot.rows;
    const byPath=new Map(rows.map(r=>[key(r),r]));
    for(const row of rows) {
      counts.set(key(row),{root:0,lower:0,annotationDiscard:0});
      if(!firstByTerm.has(row.term)) firstByTerm.set(row.term,row);
    }
    for(const loaded of list(value.program.modules)) {
      for(const top of list(loaded.module.declarations)) {
        if(tag(top)!=='DefTop') continue;
        const definition=top.definition;
        const identity=loaded.namespace+'::'+definition.key;
        if(byPath.has(JSON.stringify([identity,'root']))) {
          if(tag(definition.checked)!=='Some') throw Error('N07 expected published checked root');
          mapOccurrence(definition.checked.value,identity,'root',byPath);
        }
      }
    }
  }
  if(name==='emit' && typeof value.source==='string') {
    emitted={sha256:digest(value.source),baselineSha256:BASELINES[target].sha256,byteIdentical:digest(value.source)===BASELINES[target].sha256,emitterSteps,baselineSteps:BASELINES[target].steps,stepsIdentical:emitterSteps===BASELINES[target].steps};
  }
}
export function onFinish(name,result,count) {
  if(name==='Emitter') emitterSteps=count;
}
export function snapshot() {
  const producerSnapshot=producer.snapshot();
  const sharedTerms=new Set(producerSnapshot.sharedTermDifferentFacts?.map(x=>x.term)??[]);
  const sharedRows=rows.filter(r=>sharedTerms.has(r.term)).map(r=>({...r,observed:counts.get(key(r))}));
  const allDiscarded=sharedRows.length>0 && sharedRows.every(r=>r.observed.annotationDiscard>0 && r.observed.root===0 && r.observed.lower===0);
  let status='UNEXECUTED_OR_INCOMPLETE';
  if(emitted) {
    if(!emitted.byteIdentical || !emitted.stepsIdentical || errors.length || hookCounts.ambiguous || hookCounts.unknownInSelectedDefinition || !hookCounts.knownLower || !hookCounts.knownRoot) status='STOP_OBSERVER_OR_BASELINE_MISMATCH';
    else if(allDiscarded && diagnosticCollapses.length===0) status='STOP_NO_CONSUMER_RELEVANT_SHARED_CONTEXT';
    else status='OBSERVED_REQUIRES_CONSUMER_SEMANTIC_INVARIANT';
  }
  return {status,metadata,producerStatus:producerSnapshot.status,producerRowsSha256:producerSnapshot.rowsSha256,hookCounts,emitted,sharedRows,annotations,diagnosticCollapses,errors,semanticClaim:'No N07 GO. Shared raw type handle inequality does not establish semantic context inequality.',remaining:'A consumed source-produced same-term/different-context pair and actual semantic distinction are required unless this bounded negative reachability result is the requested stopping evidence.'};
}
