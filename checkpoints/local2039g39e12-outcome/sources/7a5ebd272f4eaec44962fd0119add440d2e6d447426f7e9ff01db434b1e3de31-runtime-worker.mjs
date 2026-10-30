import assert from 'node:assert/strict';
import {Worker,isMainThread,workerData} from 'node:worker_threads';
import {writeFileSync} from 'node:fs';
import {pathToFileURL} from 'node:url';
import {text,json,hash,sha,verify,runtimeProof,priorAuthority} from './auth.mjs';
import * as audit from './audit.mjs';
const save=(p,v)=>writeFileSync(p,JSON.stringify(v,null,2)+'\n',{flag:'wx'});
if(isMainThread){
 const child=new Worker(new URL(import.meta.url),{workerData:{request:process.argv[2]},resourceLimits:{stackSizeMb:256,maxOldGenerationSizeMb:6144,maxYoungGenerationSizeMb:128}});
 await new Promise((done,reject)=>{child.once('error',reject);child.once('exit',code=>code===0?done():reject(Error('runtime worker exit '+code)));});
}else{
 const q=json(workerData.request),report={status:'RUNNING',mode:q.mode,request:{path:workerData.request,sha256:hash(workerData.request)},worker:{stackMiB:256,oldMiB:6144,youngMiB:128},runtime:{execPath:process.execPath,versions:process.versions},source:{path:q.image,sha256:hash(q.image)}};
 try{
  verify(q.pins);let source=text(q.image);report.runtimeProof=runtimeProof(source,q.runtime);
  if(q.mode==='clean'){
   process.argv=[process.execPath,q.image];await import(pathToFileURL(q.image).href);
  }else{
   const transformed=audit.instrument(source);source=transformed.source;report.observer=transformed.metadata;
   if(q.mode==='protocol'){
    const prior=priorAuthority(q.repo);assert.equal(prior.protocol.sha256,q.protocolSha256);
    const extracted=/const probe=`\n([\s\S]*?)\n`;/u.exec(prior.source);assert.ok(extracted);let probe=extracted[1];
    if(q.direct){
     const old=text(q.oldImage);assert.equal(sha(old),'85aff9e534c18b4a1d6acac5f3237571dabc58f2c1a75a7ea2040f1c477ab60e');
     const normalize=line=>line.replace(/\$[bk]\d+/g,'$FUNCTION');const lines=source.split('\n'),mapping={};
     for(const name of ['$b13348','$b877','$k20777']){const rows=old.split('\n').filter(l=>l.startsWith('function '+name+'('));assert.equal(rows.length,1);const matches=lines.filter(l=>l.startsWith('function ')&&normalize(l)===normalize(rows[0]));assert.equal(matches.length,1,'unique unchanged direct-path function '+name);mapping[name]=/^function (\$[bk]\d+)\(/.exec(matches[0])[1];}
     for(const name of Object.keys(mapping)){const oldLine=old.split('\n').find(l=>l.startsWith('function '+name+'('));let mapped=oldLine;for(const [from,to]of Object.entries(mapping))mapped=mapped.replaceAll(from+'(',to+'(');assert.ok(lines.includes(mapped),'complete direct-path call-edge correspondence '+name);}
     probe=probe.replace('function __e12OwnedProtocol()','function __e12OwnedProtocol(depth=0)').replace('$b13348(marker,value(37),0)','$b13348(marker,value(37),depth)').replace('$b13348(marker,x,0)','$b13348(marker,x,depth)').replaceAll('$b13348(',mapping.$b13348+'(');report.directMapping=mapping;
    }else{
     const start=probe.indexOf('const a={$:');assert.ok(start>0);probe='export function __e12OwnedProtocol(){const rootK=$ksp,rootS=$sp;'+probe.slice(start);probe=probe.replace('return {direct,resume,actualFailure,','return {');
    }
    source+='\n'+probe+'\n';
   }
   const image=q.observedImage;assert.ok(image.endsWith('.js'),'executable suffix contract');writeFileSync(image,source,{flag:'wx'});report.observedImage={path:image,sha256:hash(image)};
   process.argv=[process.execPath,q.mode==='execute'?image:'e12-protocol-worker.mjs'];const api=await import(pathToFileURL(image).href);
   if(q.mode==='protocol'){
    report.protocol=[];
    for(const depth of q.direct?[0,63,64,65]:[0]){
    const v=api.__e12OwnedProtocol(depth);report.protocol.push({depth,observed:v});
    for(const key of ['lexical','prefixNormal','prefixFailure','sameError'])assert.equal(v[key],true,key);
    for(const [key,value]of Object.entries({nested:175,reentry:101,outerResult:135,split1:10,splitm:16,skipped:17,left:28}))assert.equal(v[key],value,key);
    assert.equal(v.missing,'bend: a region leave reached no private frame');assert.equal(v.final.sp,0);assert.equal(v.final.ksp,0);assert.equal(v.final.nonnullSuffix,0);assert.ok(v.final.length>=3);
    if(q.direct){assert.equal(v.direct.sameCapturedObject,true);assert.equal(v.direct.value,37);assert.equal(v.direct.capturedSlotCleared,true);assert.equal(v.resume.value,71);assert.equal(v.resume.tag,'template_steps_v1.TemplateFinished');assert.equal(v.actualFailure.error,'bend: runtime fail-stop');assert.equal(v.actualFailure.restored,true);assert.equal(v.actualFailure.slotCleared,true);}
    }
    report.scope=q.direct?'Authentically mapped generated direct Pending path plus bounded synthetic runtime protocol':'Bounded synthetic runtime protocol on actual source-emitted runtime; no fabricated generated direct Pending path';
   }
  }
  process.once('beforeExit',()=>{try{if(q.mode!=='clean'){audit.onPhase('quiescent');report.audit=audit.snapshot();audit.requireQuiescent();}verify(q.pins);report.status='PASS';}catch(e){report.status='FAIL';report.error=String(e.stack??e);process.exitCode=1;}save(q.report,report);});
 }catch(e){report.status='FAIL';report.error=String(e.stack??e);save(q.report,report);process.exitCode=1;}
}
