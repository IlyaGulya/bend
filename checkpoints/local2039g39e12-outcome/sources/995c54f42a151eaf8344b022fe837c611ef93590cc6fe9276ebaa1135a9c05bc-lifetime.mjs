import assert from 'node:assert/strict';
import {sha} from './auth.mjs';
const identities=new WeakMap(),samples=[],counts={},WINDOWS=[[0,64],[4000000,4000064],[8000000,8000064]];
let next=1,staticCaptures;
const id=x=>{if(!x||typeof x!=='object'&&typeof x!=='function')return 0;let n=identities.get(x);if(n===undefined){n=next++;identities.set(x,n);}return n;};
export function instrument(source){
 const functions=source.split('\n').filter(l=>/^function \$[bk]\d+\(/.test(l));
 const stores=functions.reduce((n,l)=>n+[...l.matchAll(/\$stArgs\[\$sp\+\+\]=/g)].length,0),loads=functions.reduce((n,l)=>n+[...l.matchAll(/\$stArgs\[\$base\+\d+\]/g)].length,0);
 assert.ok(stores>0&&loads>0,'actual capture storage code required');
 staticCaptures={generatedFunctionLines:functions.length,denseStoreSites:stores,prefixLoadExpressions:loads,scope:'Static expression census, not dynamic slot count or completeness proof for arbitrary code'};
 return {source,metadata:{inputSha256:sha(source),outputSha256:sha(source),passive:true,sourceUnchanged:true,windows:WINDOWS,depthBound:4096,scalarIDsOnly:true,staticCaptures}};
}
export function onStep(kind,index,run){
 counts[kind]=(counts[kind]??0)+1;if(!['Checker','Emitter'].includes(kind)||!WINDOWS.some(([a,b])=>index>=a&&index<b))return;
 let stack=run?.stack,depth=0;const top=id(stack),resume=id(stack?.resume);
 while(stack?.$?.endsWith('StackMore')&&depth<4096){depth++;stack=stack.rest;}
 samples.push({kind,index,runID:id(run),topFrameID:top,topResumeID:resume,depthLowerBound:depth,exact:!!stack?.$?.endsWith('StackDone')});
}
export function snapshot(){return {staticCaptures,hostStepEntries:{...counts},samples:[...samples],windows:WINDOWS,scope:'Read-only bounded live stack depth/identity. Weak keys only; no frames, owners, closures or Run objects in receipts. Lexical captures remain live independently of retired argument slots; no inferred owner transfer/drop or heap bytes.'};}
