import assert from 'node:assert/strict';
import {readFileSync,realpathSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import {resolve} from 'node:path';
import {authenticate,hash,sha,json,verify,ABI,LIMITS,guardian} from '../reuse-preflight/common.mjs';
export {hash,sha,json,verify,ABI,LIMITS,guardian};
export const text=p=>readFileSync(p,'utf8');
export const pin=p=>({path:realpathSync(p),sha256:hash(p)});
export const hooks=['function $split(f,count,k,base) {','function $splitm(f,a,k,base) {','function $split1(f,x,k,base) {','function $frame(t,base) {','function $split_enter(k,b) {'];
export function once(s,a,b){assert.equal(s.split(a).length,2,'unique boundary '+a.slice(0,100));return s.replace(a,()=>b);}
export function literals(s){return Object.fromEntries(['js_runtime','js_runtime_direct'].map(name=>{const m=new RegExp('^def '+name+'\\(\\) -> String:\\n  ("[^\\n]*")$','m').exec(s);assert.ok(m,'literal '+name);return [name,{quoted:m[1],value:JSON.parse(m[1])}];}));}
// This constructs an expected string for comparison only. It never patches an image.
function expectedRuntime(s){s=once(s,'let $sp = 0, $ksp = 0, $leaveThunk;','let $sp = 0, $ksp = 0, $leaveThunk, $stHi = 0;');for(const h of hooks.slice(0,4))s=once(s,h,h+' if($sp>$stHi)$stHi=$sp;');s=once(s,'if ($ksp===k0) { $sp=s0; return x; }','if ($ksp===k0) { $sp=s0; if($stHi>s0){$stArgs.fill(undefined,s0,$stHi);$stHi=s0;} return x; }');return once(s,'$ksp=k0; $sp=s0; $tailFn=undefined; $tailCount=0; throw e;','$ksp=k0; $sp=s0; if($stHi>s0){$stArgs.fill(undefined,s0,$stHi);$stHi=s0;} $tailFn=undefined; $tailCount=0; throw e;');}
export function sourceAuthority(repo,buildPath,commit){
 const git=(...args)=>{const r=spawnSync('git',args,{cwd:repo,encoding:'utf8',maxBuffer:32*1024*1024});assert.equal(r.status,0,r.stderr);return r.stdout;};
 const sourceCommit=git('rev-parse',commit+'^{commit}').trim(),baseline=git('rev-parse','6e6debc2^{commit}').trim();
 const path='bend2/selfhost/js_backend.bend',current=text(resolve(repo,path)),old=git('show',baseline+':'+path),before=literals(old),after=literals(current);
 assert.equal(current,git('show',sourceCommit+':'+path),'authored source must be checkpointed');
 assert.equal(after.js_runtime.value,expectedRuntime(before.js_runtime.value));
 assert.equal(after.js_runtime_direct.value,once(before.js_runtime_direct.value,hooks[4],hooks[4]+' if($sp>$stHi)$stHi=$sp;'));
 let masked=current;for(const name of Object.keys(after))masked=once(masked,after[name].quoted,before[name].quoted);assert.equal(masked,old,'only the two runtime literals may change');
 const a=authenticate(repo,buildPath),p=json(a.build.provenancePath);assert.equal(Object.keys(p.loadedInputs).length,53,'full RootJS loaded input closure');assert.equal(p.sourcePath,a.build.sourcePath);assert.equal(p.sourceSha256,a.build.sourceSha256);assert.deepEqual(p.exports,ABI);
 // All canonical providers and compiler/generator authorities must remain on R12.
 const paths=new Set([...a.manifest.canonicalComposition.sources.map(x=>x.canonical),'bend2/comp.ts','bend2/bend.ts','bend2/base.bend','evals/emitter_step_lower.ts','evals/checker_core_step_lower.ts','evals/template_step_lower.ts']);
 for(const f of paths){const body=text(resolve(repo,f));assert.equal(body,git('show',sourceCommit+':'+f),'uncommitted provider '+f);if(f!==path)assert.equal(body,git('show',baseline+':'+f),'non-isolated source delta '+f);a.pins[realpathSync(resolve(repo,f))]=hash(resolve(repo,f));}
 return {...a,sourceCommit,baseline,runtime:after,identity:{sourceCommit,baseline,source:pin(resolve(repo,path)),build:pin(buildPath),artifact:pin(a.build.artifactPath),provenance:pin(a.build.provenancePath),checkedDefinitions:a.build.checkedDefinitions}};
}
export function runtimeProof(source,runtime){
 const blocks={};for(const [name,{value}]of Object.entries(runtime)){assert.equal(source.split(value).length,2,'exact production runtime emission '+name);blocks[name]={sha256:sha(value),bytes:Buffer.byteLength(value)};}
 for(const h of hooks)assert.equal(source.split('\n'+h+' if($sp>$stHi)$stHi=$sp;').length,2,'executable five-hook '+h);
 const line=source.match(/^function run_base\(x,k0,s0\) \{[^\n]*$/gm);assert.equal(line?.length,1);assert.equal(line[0].split('$stArgs.fill(undefined,s0,$stHi);$stHi=s0;').length,3);assert.ok(!line[0].includes('$stArgs.length='));
 return {blocks,hooks:5,ownedNormalAndCatch:true,retainsArgumentLength:true,cleanupAddedAtObservation:false,engineAllocationClaim:false};
}
export function priorAuthority(repo){
 const receipt=json(resolve(repo,'evals/receipts/experiments_e10_e12_admission.json'));
 const file='/private/tmp/bend-e01-e13-jbsb4I/e12-owned-protocol.mjs';const row=receipt.supportingSources.find(r=>r.path===file);assert.ok(row);assert.equal(hash(file),row.sha256);assert.equal(sha(row.source),row.sha256);
 assert.equal(row.sha256,'2450fe761da133b3f63fbb70f8bc43d6e2ac9b47a7fd58fc6511f51842a37ee2');
 const results={};for(const mode of ['original','four-hooks','owned']){const p='/private/tmp/bend-e01-e13-jbsb4I/e12-owned-protocol-'+mode+'.json',r=json(p);assert.equal(r.status,'PASS');assert.equal(r.variant,mode);assert.equal(r.observed.direct.capturedSlotCleared,mode==='owned');assert.equal(r.observed.actualFailure.slotCleared,mode==='owned');results[mode]={...pin(p),observed:r.observed};}
 assert.equal(receipt.E12.protocol.status,'PASS_DIAGNOSTIC_ONLY');
 for(const mode of Object.keys(results)){const rows=receipt.E12.protocol.rows.filter(r=>r.variant===mode);assert.equal(rows.length,1);assert.equal(rows[0].result.path,results[mode].path);assert.equal(rows[0].result.sha256,results[mode].sha256);guardian(rows[0].guardian);const observations=receipt.E12.protocol.observations.filter(r=>r.variant===mode);assert.equal(observations.length,1);assert.deepEqual(results[mode].observed,observations[0].observed);}
 return {protocol:pin(file),source:row.source,results,receipt:pin(resolve(repo,'evals/receipts/experiments_e10_e12_admission.json'))};
}
