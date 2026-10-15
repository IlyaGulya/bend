#!/usr/bin/env node
/** Aggregate ordinary V8 .cpuprofile files without estimating missing samples.
 * Usage: node evals/summarize_cpu_profile.mjs PATH.cpuprofile [MORE.cpuprofile ...]
 * JSON goes to stdout. Each samples[i] receives timeDeltas[i] microseconds;
 * durations are never rescaled to wall time. Inclusive time credits a function
 * once per sample, even when several recursive frames have that function key.
 * These are sampled elapsed milliseconds, not measured process CPU time.
 */
import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {createHash} from 'node:crypto';

const paths=process.argv.slice(2);
if(!paths.length)throw Error('Usage: node evals/summarize_cpu_profile.mjs PATH.cpuprofile [MORE.cpuprofile ...]');
const functions=new Map(),profiles=[];
let sampledMicroseconds=0,samples=0,gcMicroseconds=0,gcSamples=0;
for(const path of paths){
 const file=resolve(path),bytes=readFileSync(file),profile=JSON.parse(bytes.toString('utf8'));
 if(!Array.isArray(profile.nodes)||!Array.isArray(profile.samples)||!Array.isArray(profile.timeDeltas)||profile.samples.length!==profile.timeDeltas.length)
  throw Error(file+': requires nodes and equal-length samples/timeDeltas arrays');
 if(!Number.isFinite(profile.startTime)||!Number.isFinite(profile.endTime)||profile.endTime<profile.startTime)
  throw Error(file+': requires a nonnegative startTime/endTime interval');
 const nodes=new Map(),parents=new Map();
 for(const node of profile.nodes){
  const frame=node.callFrame;
  if(!Number.isSafeInteger(node.id)||nodes.has(node.id)||!frame||typeof frame.functionName!=='string'||typeof frame.url!=='string'||!Number.isInteger(frame.lineNumber)||!Number.isInteger(frame.columnNumber))
   throw Error(file+': invalid or duplicate node/callFrame');
  // Script IDs are process-local, so location/function identity is used across
  // profiles. Distinct declaration locations are not merged just by name.
  const key=JSON.stringify([frame.functionName,frame.url,frame.lineNumber,frame.columnNumber]);
  let row=functions.get(key);
  if(!row){row={functionName:frame.functionName,url:frame.url,lineNumber:frame.lineNumber,columnNumber:frame.columnNumber,selfMicroseconds:0,inclusiveMicroseconds:0,selfSamples:0,inclusiveSamples:0};functions.set(key,row);}
  nodes.set(node.id,{key,row,isGC:frame.functionName==='(garbage collector)'});
  if(node.children!==undefined&&!Array.isArray(node.children))throw Error(file+': invalid node children');
  for(const child of node.children??[]){
   if(!Number.isSafeInteger(child)||parents.has(child))throw Error(file+': invalid or multiply-parented child');
   parents.set(child,node.id);
  }
 }
 for(const [child,parent]of parents)if(!nodes.has(child)||!nodes.has(parent))throw Error(file+': missing parent/child node');
 // Reuse the sets rather than allocating them per sample; function identity,
 // not node identity, is the inclusive recursion-deduplication boundary.
 const seenNodes=new Set(),seenFunctions=new Set();
 let total=0,localGC=0,localGCSamples=0;
 for(let index=0;index<profile.samples.length;index++){
  let id=profile.samples[index];
  const duration=profile.timeDeltas[index],leaf=nodes.get(id);
  if(!leaf||!Number.isFinite(duration)||duration<0)throw Error(file+': invalid sample or time delta at '+index);
  total+=duration;leaf.row.selfMicroseconds+=duration;leaf.row.selfSamples++;
  seenNodes.clear();seenFunctions.clear();let isGC=false;
  while(id!==undefined){
   if(seenNodes.has(id))throw Error(file+': cyclic sample stack at node '+id);
   seenNodes.add(id);
   const node=nodes.get(id);
   if(!node)throw Error(file+': missing sampled ancestor '+id);
   if(!seenFunctions.has(node.key)){
    seenFunctions.add(node.key);node.row.inclusiveMicroseconds+=duration;node.row.inclusiveSamples++;
   }
   isGC ||= node.isGC;id=parents.get(id);
  }
  if(isGC){localGC+=duration;localGCSamples++;}
 }
 const duration=profile.endTime-profile.startTime;
 profiles.push({file,sha256:createHash('sha256').update(bytes).digest('hex'),samples:profile.samples.length,profileDurationMs:duration/1000,sampledMs:total/1000,unattributedDurationMs:(duration-total)/1000,gcSampledMs:localGC/1000,gcShare:total?localGC/total:0,gcSamples:localGCSamples});
 sampledMicroseconds+=total;samples+=profile.samples.length;gcMicroseconds+=localGC;gcSamples+=localGCSamples;
}
const rows=[...functions.values()].sort((a,b)=>b.selfMicroseconds-a.selfMicroseconds||b.inclusiveMicroseconds-a.inclusiveMicroseconds||a.functionName.localeCompare(b.functionName)).map(({selfMicroseconds,inclusiveMicroseconds,...row})=>({...row,selfSampledMs:selfMicroseconds/1000,inclusiveSampledMs:inclusiveMicroseconds/1000,selfShare:sampledMicroseconds?selfMicroseconds/sampledMicroseconds:0,inclusiveShare:sampledMicroseconds?inclusiveMicroseconds/sampledMicroseconds:0}));
console.log(JSON.stringify({schemaVersion:1,attribution:'samples[i] is weighted by timeDeltas[i] in microseconds; no wall-time rescaling or hitCount estimates; inclusive function identity credited once per sample',functionIdentity:'functionName + url + zero-based lineNumber + zero-based columnNumber; process-local scriptId excluded',gcIdentity:'stack contains the canonical V8 (garbage collector) frame; not a guess from heap size or function names',samples,sampledMs:sampledMicroseconds/1000,gcSampledMs:gcMicroseconds/1000,gcShare:sampledMicroseconds?gcMicroseconds/sampledMicroseconds:0,gcSamples,profiles,functions:rows},null,2));
