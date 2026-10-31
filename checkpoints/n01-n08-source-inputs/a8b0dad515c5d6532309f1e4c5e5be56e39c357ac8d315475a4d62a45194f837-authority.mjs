import assert from 'node:assert/strict';
import {readFileSync,realpathSync} from 'node:fs';
import {resolve} from 'node:path';
import {ABI,authenticateNativeSeedBuild,hashPath,sha} from '/Users/ilyagulya/Projects/My/bend/evals/native_seed_runtime.mjs';
import {sourceFileTagFromRoot} from '/Users/ilyagulya/Projects/My/bend/evals/checker_core_step_runtime.mjs';
export {ABI,hashPath,sha};
export const ROOT='/Users/ilyagulya/Projects/My/bend',BASE=ROOT+'/checkpoints/local2039g24r12',LIMITS={memoryMiB:8192,rssMiB:8192,pollMs:10,timeoutMs:600000};
export const NODE='/Users/ilyagulya/bend-g12-borrow-7782b78a-1e88-4ffd-9889-14cb52c6a5b9/.tools/node';
export const json=p=>JSON.parse(readFileSync(p,'utf8'));
export const tag=x=>typeof x?.$==='string'?x.$.split('.').at(-1):null;
export const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
export function items(x){const a=[];while(tag(x)==='Con'){a.push(x.head);x=x.tail;}assert.equal(tag(x),'Nil');return a;}
export function verify(pins){for(const[p,h]of Object.entries(pins))assert.equal(hashPath(realpathSync(p)),h,'pin drift: '+p);}
export function authenticate(){
 assert.equal(realpathSync('.'),ROOT,'Run in original repository');
 const buildPath=BASE+'/root-native-build.json',build=json(buildPath),corpusPath=BASE+'/root.native.corpus.json';
 const native=authenticateNativeSeedBuild(buildPath,{root:realpathSync(build.source),corpusPath,limits:LIMITS});
 assert.equal(native.binarySha256,'b3459184f37d3159f44e9b7f67642ad6c3850dc806ae5f7837f348fc842b3f71');
 const bootstrapPath=BASE+'/bootstrap.json',boot=json(bootstrapPath),one=boot.artifacts.stageOne,two=boot.artifacts.stageTwo;
 assert.equal(boot.status,'NATIVE_SEED_BOOTSTRAP_FIXEDPOINT');assert.equal(boot.passed,true);assert.equal(boot.fixedpoint.equal,true);assert.deepEqual(boot.requiredExports,ABI);
 const expected='85aff9e534c18b4a1d6acac5f3237571dabc58f2c1a75a7ea2040f1c477ab60e';
 for(const a of[one,two])assert.equal(hashPath(a.path),expected);assert.equal(one.sha256,expected);assert.equal(two.sha256,expected);
 for(const a of[one,two])for(const row of a.sourceHashes){assert.equal(hashPath(row.file),row.sha256);assert.equal(row.sourceBytesSha256,row.sha256);}
 const carrier=sourceFileTagFromRoot(readFileSync(build.source,'utf8'),'selfhost');
 const proof={class:'GENUINE_R12_NATIVE_SEED_STAGE1',build:{path:buildPath,sha256:hashPath(buildPath),checkedDefinitions:build.checkedDefinitions,events:build.eventsFullyValidated},bootstrap:{path:bootstrapPath,sha256:hashPath(bootstrapPath),status:boot.status},image:{path:one.path,sha256:expected,bytes:one.bytes},stageTwo:{path:two.path,sha256:expected},native:{path:native.binary,sha256:native.binarySha256},source:{path:build.source,sha256:hashPath(build.source)},sourceFileTag:carrier,abi:ABI,limits:LIMITS,parserFuel:8000000,quantum:64,worker:{stackMiB:256,oldMiB:6144,youngMiB:128},protectedInputCount:Object.keys(native.protectedPins).length,loadedInputCount:Object.keys(native.loadedInputs).length,newFixedpointClaim:false};
 return {proof,image:one.path,carrier,pins:{...native.protectedPins,...native.loadedInputs,[buildPath]:hashPath(buildPath),[bootstrapPath]:hashPath(bootstrapPath),[one.path]:expected,[two.path]:expected,[native.binary]:native.binarySha256}};
}
