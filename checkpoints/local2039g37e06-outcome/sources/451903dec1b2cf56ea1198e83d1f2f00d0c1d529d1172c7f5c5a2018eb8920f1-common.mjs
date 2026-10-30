import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {readFileSync,writeFileSync,realpathSync} from 'node:fs';
import {resolve} from 'node:path';
export const LIMITS=Object.freeze({memoryMiB:8192,rssMiB:8192,pollMs:10,timeoutMs:600000});
export const ABI=Object.freeze(['parsed_module','parse_with_fuel','expand_modules_start','template_step','check_expanded_start','inspect_checked_start','checker_step','emit_modules_start','emit_library_start','emitter_step','emit_c_modules_start','emit_c_library_start','c_emitter_step']);
export const sha=x=>createHash('sha256').update(x).digest('hex');
export const hash=p=>sha(readFileSync(p));
export const json=p=>JSON.parse(readFileSync(p,'utf8'));
export const save=(p,x)=>writeFileSync(p,JSON.stringify(x,null,2)+'\n');
export function verify(pins){for(const [p,h] of Object.entries(pins)){assert.equal(realpathSync(p),p);assert.equal(hash(p),h,'input drift '+p);}}
export function guardian(g){assert.equal(g.status,'PASS');assert.equal(g.reportPhase,'complete');assert.equal(g.ownedTreeStopped,true);assert.equal(g.commandExitCode,0);assert.equal(g.memoryLimitBytes,8589934592);assert.equal(g.rssLimitBytes,8589934592);assert.equal(g.timeoutMs,600000);}
export function authenticate(repo,buildPath){
 const b=json(buildPath);assert.equal(b.status,'JS_GENERATED_NOT_YET_EXECUTED');assert.equal(b.checksExcluded,0);assert.equal(b.outputPatches,0);assert.equal(b.checkedOutputRetention,'native e');guardian(b.guardian);
 assert.equal(hash(b.artifactPath),b.artifactSha256);assert.equal(hash(b.sourcePath),b.sourceSha256);assert.deepEqual(b.exports,ABI);
 const {provenanceSha256,...p}=json(b.provenancePath);assert.equal(sha(JSON.stringify(p)),provenanceSha256);assert.equal(b.provenanceSha256,provenanceSha256);
 for(const name of ['protectedPins','loadedInputs']){assert.ok(Object.keys(p[name]).length);verify(p[name]);}
 assert.ok(b.checkedDefinitions>0);assert.equal(b.checkedDefinitions,b.expectedSourceDefinitions);assert.equal(b.checkedDefinitions,b.nativeCheckedBodies);
 assert.equal(b.runtime.name,'node');assert.equal(b.runtime.stackSizeMb,256);assert.equal(b.runtime.heapLimitMiB,3072);assert.equal(b.runtime.manualGC,false);
 const manifestPath=resolve(repo,'checkpoints/emitter-steps-v1.json'),m=json(manifestPath);
 assert.equal(m.nativeChunk.quantum,64);assert.equal(m.nativeChunk.semanticFuelChanged,false);
 assert.ok(!m.canonicalComposition.providers.includes('bend2/selfhost/backend_continuation.bend'),'E05 provider remains in isolated reuse root');
 assert.equal(hash(resolve(repo,m.source)),m.sourceSha256);
 for(const s of m.canonicalComposition.sources)assert.equal(hash(resolve(repo,s.canonical)),s.canonicalSha256,'provider drift '+s.canonical);
 // The compiled root's loaded-input proof, not just a current manifest, must pin the exact generated emitter.
 const generated=realpathSync(resolve(repo,m.generationConfig.output));assert.equal(p.loadedInputs[generated],hash(generated));
 const pins={...p.protectedPins,...p.loadedInputs,[realpathSync(buildPath)]:hash(buildPath),[realpathSync(b.provenancePath)]:hash(b.provenancePath),[realpathSync(b.artifactPath)]:hash(b.artifactPath),[realpathSync(manifestPath)]:hash(manifestPath)};
 for(const s of m.canonicalComposition.sources)pins[realpathSync(resolve(repo,s.canonical))]=s.canonicalSha256;
 return {build:b,manifest:m,pins};
}
export function expectations(text){const lines=text.split('\n').filter(s=>s.startsWith('#|'));assert.ok(lines.length,'source lacks #| expectation');return lines.map(s=>s.slice(2)).join('\n')+'\n';}
export const tag=x=>typeof x?.$==='string'?x.$.split('.').at(-1):undefined;
export const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
export function items(x){const out=[];while(tag(x)==='Con'){out.push(x.head);x=x.tail;}assert.equal(tag(x),'Nil');return out;}
