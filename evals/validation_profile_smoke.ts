import {createHash,randomUUID} from 'node:crypto';
import {writeFileSync,appendFileSync,rmSync,mkdtempSync} from 'node:fs';
import {resolve,join} from 'node:path';
import {tmpdir} from 'node:os';
import {dlopen,FFIType,ptr} from 'bun:ffi';
import {guardHeavyGate} from './heavy_gate.ts';
import {validationProfile} from './validation_profile.ts';
await guardHeavyGate(import.meta.path,{label:'Full-prefix native validation profile'});
const [candidate,output,limitText='1250',artifact]=process.argv.slice(2),limit=Number(limitText);
if(!candidate||!output||!Number.isSafeInteger(limit)||limit<1)throw Error('Expected candidate report positive-prefix-limit');
const compilerPath='/tmp/bend-artifact-d746e7cc/bend2/.comp_js_stream_probe.ts';
const digest=(source:string)=>createHash('sha256').update(source).digest('hex');
if(artifact){
 if(await Bun.file(artifact).exists())throw Error('Artifact already exists');
 if(digest(await Bun.file(candidate).text())!=='0bc3d4054c08ffcea2a90cb9177d9c918258b4eef0de1227e89ceecc3266ac93')throw Error('Accepted operator candidate drift');
 if(digest(await Bun.file(compilerPath).text())!=='3d8c4e2a14f1f5e7f1833b8c7492c640481a31dd03544bff7378b360a56d19ae')throw Error('Accepted diagnostic compiler drift');
}
const temp=mkdtempSync(join(tmpdir(),'bend-validation-profile-'));
const loaderPath=resolve('evals','.validation_profile_loader_'+randomUUID()+'.ts');
const canonical=await Bun.file('bend2/selfhost/parser.bend').text();
const pin=createHash('sha256').update(canonical).digest('hex');
const loader=await Bun.file('evals/load_replay_kernel.ts').text();
const anchor="'bend2/selfhost/parser.bend':'f425995af41087dfa51f79e7b04259ea5d1acfa9906061c7ed57199bad4e18df'";
if(loader.split(anchor).length!==2)throw Error('Loader anchor drift');
writeFileSync(loaderPath,loader.replace(anchor,"'bend2/selfhost/parser.bend':'"+pin+"'"));
const dylib=join(temp,'memory.dylib');
const cc=Bun.spawn(['/usr/bin/cc','-O2','-dynamiclib','-pthread','/tmp/bend-artifact-d746e7cc/evals/artifact_phase_memory.c','-o',dylib],{stdout:'inherit',stderr:'inherit'});
if(await cc.exited!==0)throw Error('Memory sampler compilation failed');
const library=dlopen(dylib,{artifact_memory:{args:[FFIType.ptr],returns:FFIType.i32}}),values=new BigUint64Array(2);
const memory=()=>{if(library.symbols.artifact_memory(ptr(values)))throw Error('Memory observation failed');return{footprintBytes:Number(values[0]),rssBytes:Number(values[1]),heapUsed:process.memoryUsage().heapUsed};};
writeFileSync(output+'.jsonl','');
const profile=validationProfile(memory,e=>appendFileSync(output+'.jsonl',JSON.stringify({atMs:performance.now(),...e})+'\n'));
const {replayKernel,checkFrozen}=await import(loaderPath);
const handle=await replayKernel('direct',undefined,{retention:'retain',observeCheck:profile.observeCheck});
try{
 const K=handle.kernel,book=K.book_nil(),loadStart=performance.now();await K.book_load(book,resolve(candidate),'',new Map());
 const loadMs=performance.now()-loadStart;
 const result=profile.run(K,book,Math.min(limit,book.order.length));
 const retainedCheckedBodies=result.rows.filter(row=>Number(row.bodyChecks)>0).every(row=>{const def=book.tlds[String(row.name)];return def?.$==='Def'&&def.e!==undefined;});
 if(!retainedCheckedBodies)throw Error('Checked body retention lost');
 writeFileSync(output,JSON.stringify({...result,candidate,loadMs,retainedCheckedBodies,checksExcluded:0,...memory()},null,2)+'\n');
 console.log(JSON.stringify({...result,rows:undefined,loadMs,retainedCheckedBodies,...memory()}));
 if(artifact){
  if(result.eventsChecked!==result.totalEvents||book.hols||book.open)throw Error('Artifact requires complete, closed native validation');
  const Comp=await import(compilerPath);
  const codegenStart=performance.now(),cpuStart=process.cpuUsage();
  Comp.js_storage_release_e(true);
  Comp.js_storage_set_probe((stage:string,name?:string)=>{
   const observed=memory();
   appendFileSync(output+'.jsonl',JSON.stringify({phase:'codegen',atMs:performance.now(),stage,name,...observed})+'\n');
  });
  let source:string;
  try{source=Comp.js_lib(book,true,{roots:['parse_with_fuel'],exports:['parse_with_fuel']});}finally{Comp.js_storage_set_probe(undefined);}
  await checkFrozen();
  if(digest(await Bun.file(candidate).text())!=='0bc3d4054c08ffcea2a90cb9177d9c918258b4eef0de1227e89ceecc3266ac93')throw Error('Candidate changed during emission');
  writeFileSync(artifact,source,{flag:'wx'});
  const cpu=process.cpuUsage(cpuStart);
  const emitted={status:'JS_GENERATED_NOT_YET_EXECUTED',artifact,sha256:digest(source),bytes:Buffer.byteLength(source),validationEvents:result.eventsChecked,checksExcluded:0,elapsedMs:performance.now()-codegenStart,cpuMs:(cpu.user+cpu.system)/1000,...memory(),selfhostGreen:false};
  writeFileSync(output+'.artifact.json',JSON.stringify(emitted,null,2)+'\n');console.log(JSON.stringify(emitted));
 }
}finally{handle.close();library.close();await checkFrozen();rmSync(loaderPath,{force:true});rmSync(temp,{recursive:true,force:true});}
