#!/usr/bin/env node
import assert from 'node:assert/strict';
import {existsSync,mkdirSync,writeFileSync,realpathSync} from 'node:fs';
import {resolve,dirname} from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import os from 'node:os';
import {sourceAuthority,priorAuthority,text,json,hash,pin,verify,runtimeProof,ABI,LIMITS,guardian} from './auth.mjs';
import {scan} from './stage1.mjs';
const here=dirname(fileURLToPath(import.meta.url)),parent=dirname(here);
const usage='cli.mjs consumers|stage1 --repo=PATH --build=FULL_ROOTJS.result.json --source-commit=COMMIT --out=FRESH_DIR [--node=PATH --clang=PATH --bootstrap=GENUINE_BOOTSTRAP.json --request=GENUINE_CANDIDATE_FULL53.request.json --require-stage1=true|false]';
const [action,...args]=process.argv.slice(2);if(action==='--help'){console.log(usage);process.exit(0);}assert.ok(['consumers','stage1'].includes(action),usage);
const o={};for(const arg of args){const m=/^--([a-z-]+)=(.+)$/.exec(arg);assert.ok(m,usage);assert.ok(!Object.hasOwn(o,m[1]));assert.ok(['repo','build','source-commit','out','node','clang','bootstrap','request','require-stage1'].includes(m[1]));o[m[1]]=m[2];}
for(const k of ['repo','build','source-commit','out'])assert.ok(o[k],'required '+k);
const repo=realpathSync(o.repo),out=resolve(o.out),node=realpathSync(o.node??process.execPath),clang=realpathSync(o.clang??'/usr/bin/clang');assert.equal(realpathSync(process.execPath),node);assert.equal(hash(node),'ead5889f15f4e17b37f941c7d9e92b624396786bd74d8155ef470f6381f032c5');assert.equal(process.version,'v23.11.0');assert.equal(process.platform,'darwin');assert.equal(process.arch,'arm64');
assert.ok(out.startsWith(here+'/'),'outputs must remain in assigned directory');assert.ok(!existsSync(out),'fresh namespace required');mkdirSync(out,{recursive:true});process.chdir(repo);
assert.ok(o['require-stage1']===undefined||['true','false'].includes(o['require-stage1']));
const save=(p,v)=>writeFileSync(p,JSON.stringify(v,null,2)+'\n'),fresh=(p,v)=>writeFileSync(p,JSON.stringify(v,null,2)+'\n',{flag:'wx'});
const receipt={schemaVersion:1,status:'RUNNING',action,compilerAccepted:false,performanceAccepted:false,newFixedpointClaim:false,limits:LIMITS,worker:{stackMiB:256,oldMiB:6144,youngMiB:128},parserFuel:8000000,quantum:64,abi:ABI,host:{platform:os.platform(),release:os.release(),arch:os.arch(),cpus:os.cpus().map(c=>c.model),memoryBytes:os.totalmem()},commands:[],rows:[],stage1:{status:'MISSING_PROOF'},limitsOfClaim:['No pre-entry-throw cleanup guarantee','No other-root/global-owner-death claim','No retained-byte or engine-allocation saving','Canonical RootJS runtime is not the candidate runtime','Native/fixedpoint/performance/full consumer qualification remains parent-owned']};
const publish=()=>save(resolve(out,'receipt.json'),receipt);publish();
let pins={};
try{
 const authority=sourceAuthority(repo,realpathSync(o.build),o['source-commit']),prior=priorAuthority(repo);pins={...authority.pins};
 const tools=[...['cli.mjs','auth.mjs','audit.mjs','lifetime.mjs','runtime-worker.mjs','stage1.mjs'].map(p=>resolve(here,p)),...['common.mjs','compile-worker.mjs','probes.mjs','capture.mjs'].map(p=>resolve(parent,'reuse-preflight',p)),resolve(parent,'census-runner.mjs'),resolve(repo,'evals/selfhost_throughput.mjs'),resolve(repo,'evals/checker_core_step_runtime.mjs'),resolve(repo,'evals/native_seed_runtime.mjs'),resolve(repo,'evals/heavy_gate.ts'),resolve(repo,'evals/heavy_gate_native.c'),resolve(repo,'bend2/selfhost/c_runtime.c'),node,clang,prior.protocol.path,prior.receipt.path,...Object.values(prior.results).map(r=>r.path)];
 for(const p of tools)pins[realpathSync(p)]=hash(p);
 receipt.source=authority.identity;receipt.pins=pins;receipt.runtimeBinaries={node:pin(node),clang:pin(clang)};receipt.priorDirectRegression={receipt:prior.receipt,protocol:prior.protocol,results:prior.results};receipt.sourceInventory=tools.filter(p=>/\.(mjs|ts|c)$/.test(p)).map(p=>({...pin(p),kind:'tooling',sourceOnly:true,purpose:'Actual E12 source/runtime/consumer proof tooling and dependencies'}));publish();
 const {runHeavyGate}=await import(pathToFileURL(resolve(repo,'evals/heavy_gate.ts')).href);
 async function run(label,command){
  verify(pins);const prefix=resolve(out,String(receipt.commands.length).padStart(3,'0')+'-'+label),row={label,command,stdout:prefix+'.stdout',stderr:prefix+'.stderr',limits:LIMITS};receipt.commands.push(row);publish();
  try{row.guardian=await runHeavyGate([node,resolve(parent,'reuse-preflight/capture.mjs'),row.stdout,row.stderr,...command],{...LIMITS,label:'E12 source '+label});guardian(row.guardian);verify(pins);row.status='PASS';return row;}
  catch(error){row.status='FAIL';row.error=String(error.stack??error);throw error;}
  finally{if(existsSync(row.stdout))row.stdoutSha256=hash(row.stdout);if(existsSync(row.stderr))row.stderrSha256=hash(row.stderr);publish();}
 }
 async function runtimeRun(name,image,mode,expected,direct=false){
  const request=resolve(out,name+'.request.json'),report=resolve(out,name+'.result.json');const imagePins={...pins,[realpathSync(image)]:hash(image)};
  const oldImage=resolve(repo,'checkpoints/local2039g24r12/bootstrap.json.cases/stage-one.js');if(direct)imagePins[realpathSync(oldImage)]=hash(oldImage);
  fresh(request,{repo,image,mode,direct,oldImage,protocolSha256:prior.protocol.sha256,runtime:authority.runtime,pins:imagePins,observedImage:resolve(out,name+'.observed.js'),report});
  const row=await run(name,[node,'--experimental-strip-types',resolve(here,'runtime-worker.mjs'),request]);const r=json(report);assert.equal(r.status,'PASS');if(expected!==undefined)assert.equal(text(row.stdout),expected,'exact consumer stdout '+name);return {...pin(report),result:r,execution:row};
 }
 if(action==='consumers'){
  const fixture=resolve(out,'arena63-64-65.bend');
  writeFileSync(fixture,`import Base\nimport ${resolve(repo,'bend2/selfhost/checker_arena.bend')} as Arena\n\ndef grow(n: Nat, arena: Arena.Arena) -> Arena.Arena:\n  match n:\n    case 0n: arena\n    case 1n+p: again(p, Arena.put_node(arena, Arena.TermQuant{}))\n\ndef again(n: Nat, result: Arena.Arena & U32) -> Arena.Arena:\n  match result:\n    case Tuple{arena, _}: grow(n, arena)\n\ndef count(result: Arena.Arena & U32) -> U32:\n  match result:\n    case Tuple{_, n}: n\n\ndef main() -> IO(Unit):\n  do IO<Unit>:\n    IO.print(U32.show(count(Arena.node_count(grow(63n, Arena.empty())))))\n    IO.print(U32.show(count(Arena.node_count(grow(64n, Arena.empty())))))\n    IO.print(U32.show(count(Arena.node_count(grow(65n, Arena.empty())))))\n\n#|63\n#|64\n#|65\n`,{flag:'wx'});
  pins[realpathSync(fixture)]=hash(fixture);receipt.sourceInventory.push({...pin(fixture),kind:'source',sourceOnly:true,purpose:'actual Arena put_node growth, not a host-array stand-in'});
  const cases=[{name:'split-capture-chain',source:resolve(repo,'tests/compile/js_split_capture_chain.bend'),expected:'206\n45\n32\n24\n',targets:['c','js']},{name:'multi-reentrant',source:resolve(repo,'tests/compile/js_multi_reentrant.bend'),expected:'10109\n76\n',targets:['js']},{name:'arena63-64-65',source:fixture,expected:'63\n64\n65\n',targets:['c','js']}];
  receipt.targetCoverage={c:['split-capture-chain','arena63-64-65'],js:cases.map(x=>x.name),cReentry:{status:'MISSING_SOURCE_ALTERNATIVE',source:pin(cases[1].source),reason:'Existing Host.reenter declares only js_multi_reentrant.js. No invented C foreign fallback or C reentry PASS.'}};
  for(const c of cases){pins[realpathSync(c.source)]=hash(c.source);receipt.sourceInventory.push({...pin(c.source),kind:'source',sourceOnly:true,purpose:c.name});}
  const foreign=resolve(repo,'tests/compile/js_multi_reentrant.js');pins[realpathSync(foreign)]=hash(foreign);receipt.sourceInventory.push({...pin(foreign),kind:'source',sourceOnly:true,purpose:'unchanged reentry/throw foreign implementation'});
  for(const c of cases)for(const target of c.targets){
   const name=c.name+'-'+target,output=resolve(out,name+'.'+target),request=resolve(out,name+'.compile.request.json'),report=resolve(out,name+'.compile.result.json');const row={name,source:pin(c.source),target,expected:c.expected,status:'RUNNING'};receipt.rows.push(row);publish();
   fresh(request,{repo,build:realpathSync(o.build),source:c.source,target,instrument:false,pins,output,report});await run(name+'-emit',[node,'--experimental-strip-types',resolve(parent,'reuse-preflight/compile-worker.mjs'),request]);const compiled=json(report);assert.equal(compiled.status,'PASS');assert.equal(compiled.output.sha256,hash(output));verify(compiled.inputs);Object.assign(pins,compiled.inputs);row.emission={...pin(report),result:compiled};
   if(target==='c'){const binary=resolve(out,name);await run(name+'-clang',[clang,'-std=c11','-O1','-pthread',output,'-lm','-o',binary]);row.binary=pin(binary);const executed=await run(name+'-exec',[binary]);assert.equal(text(executed.stdout),c.expected);row.execution=executed;}
   else{row.runtimeProof=runtimeProof(text(output),authority.runtime);row.clean=await runtimeRun(name+'-clean',output,'clean',c.expected);row.observed=await runtimeRun(name+'-observed',output,'execute',c.expected);row.protocol=await runtimeRun(name+'-protocol',output,'protocol');}
   row.status='PASS';publish();
  }
 }
 if(o.bootstrap||o.request){assert.ok(o.bootstrap&&o.request,'both genuine stage1 pointers required');receipt.stage1=await scan({repo,out,node,bootstrap:realpathSync(o.bootstrap),requestPath:realpathSync(o.request),authority,pins,run,runtimeRun});}
 if(action==='stage1'||o['require-stage1']==='true')assert.equal(receipt.stage1.status,'PASS','MISSING_REQUIRED_STAGE1_PROOF; canonical RootJS cannot substitute');
 verify(pins);receipt.status=action==='stage1'?'STAGE1_SCAN_PASS':receipt.stage1.status==='PASS'?'SOURCE_PREFLIGHT_PASS':'CONSUMERS_PASS_STAGE1_MISSING';publish();
}catch(error){receipt.status='FAIL';receipt.error=String(error.stack??error);publish();process.exitCode=1;}
console.log(JSON.stringify({status:receipt.status,receipt:resolve(out,'receipt.json'),stage1:receipt.stage1.status,compilerAccepted:false}));
