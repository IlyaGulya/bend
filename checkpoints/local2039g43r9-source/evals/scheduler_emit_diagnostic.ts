#!/usr/bin/env bun
// Diagnostic only: the unchanged full fixture, genuine stage-one image and
// consumer worker run once under the original per-step resource envelope.
// Usage: bun evals/scheduler_emit_diagnostic.ts NODE IMAGE FROZEN_REPOSITORY NEW_OUTPUT_DIRECTORY [--nf-progress]
// Parent owns physical-host serialization and source/version checkpointing.
// This never runs clang/the fixture or produces qualification evidence.
import {createHash} from 'node:crypto';
import {mkdirSync,readFileSync,realpathSync,writeFileSync} from 'node:fs';
import {dirname,join,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {runHeavyGate} from './heavy_gate.ts';

const args=process.argv.slice(2);
if(args.length!==4&&!(args.length===5&&args[4]==='--nf-progress'))throw Error('usage: scheduler_emit_diagnostic.ts NODE IMAGE FROZEN_REPOSITORY NEW_OUTPUT_DIRECTORY [--nf-progress]');
const nfProgress=args[4]==='--nf-progress';
const [node,image,repository]=args.slice(0,3).map(path=>realpathSync(path));
const output=resolve(args[3]!);
const here=dirname(fileURLToPath(import.meta.url));
const fixture=join(repository!,'evals/scheduler_chunk_smoke.bend');
const generatedChecker=join(repository!,'checkpoints/checker_core_steps_v1.bend');
const base=join(repository!,'bend2/base.bend');
const runtime=join(repository!,'bend2/selfhost/c_runtime.c');
const worker=join(here,'candidate_consumer_worker.mjs');
const host=join(here,'candidate_host.ts');
const requiredPins=[
 {path:node!,sha256:'ead5889f15f4e17b37f941c7d9e92b624396786bd74d8155ef470f6381f032c5'},
 {path:image!,sha256:'85aff9e534c18b4a1d6acac5f3237571dabc58f2c1a75a7ea2040f1c477ab60e'},
 {path:fixture,sha256:'21986a939adccc86c6580c446242be9feb95703c6eeb820ef939d961f2247140'},
 {path:generatedChecker,sha256:'e4c1197d63129394551d5643ef2934be84af82eaeacfa3da1e4e660c6ff603a4'},
];
for(const pin of requiredPins){
 const actual=createHash('sha256').update(readFileSync(pin.path)).digest('hex');
 if(actual!==pin.sha256)throw Error('Diagnostic input pin mismatch: '+pin.path);
}
// The artifact and fixture pins forbid a seed substitution or an easier fixture.
// Do not derive a reduced import corpus, serialize an AST, or skip validation.
const observedPins=[base,runtime,join(repository!,'bend2/selfhost/checker_ir.bend'),
 fileURLToPath(import.meta.url),worker,host,join(here,'checker_core_step_runtime.mjs'),
 join(here,'compiler_stage_profile.mjs'),join(here,'compiler_profile.mjs'),join(here,'scheduler_nf_progress.mjs'),
 join(here,'heavy_gate.ts'),join(here,'heavy_gate_native.c')]
 .map(path=>({path:realpathSync(path),sha256:createHash('sha256').update(readFileSync(path)).digest('hex')}));
mkdirSync(output,{recursive:false});
const save=(name:string,value:unknown)=>writeFileSync(join(output,name),JSON.stringify(value,null,2)+'\n',{flag:'wx'});
const command=[node!,'--experimental-strip-types',worker,host,
 '--candidate='+image,'--parser='+image,'--stage-profile='+join(output,'stages'),'--stage-progress',
 ...(nfProgress?['--stage-nf-progress']:[]),
 fixture,'-o',join(output,'scheduler_chunk_smoke.c'),'--base',base,'--runtime-c',runtime];
const guard={memoryMiB:8192,rssMiB:8192,pollMs:10,timeoutMs:600000};
const stdout=join(output,'emit.stdout'),stderr=join(output,'emit.stderr');
// Positional shell arguments preserve paths verbatim, matching the matrix's
// redirection wrapper. The shell execs Node, retaining the owned-tree guardian.
const guardedCommand=['/bin/sh','-c','out=$1; err=$2; shift 2; exec "$@" >"$out" 2>"$err"',
 'sh',stdout,stderr,...command];
save('diagnostic.json',{
 schemaVersion:1,kind:nfProgress?'scheduler-emit-nf-argument-diagnostic':'scheduler-emit-phase-diagnostic',acceptanceEvidence:false,
 startedAt:new Date().toISOString(),repository,output,command,guard,requiredPins,observedPins,
 nodeVersion:'23.11.0 (accepted binary pinned above; observed runtime is in stages/*/run.json)',
 workerLimits:{stackSizeMb:256,maxOldGenerationSizeMb:3072},abiExports:13,parserFuelCellsPerParse:8000000,nativeQuantum:64,
 instrumentation:nfProgress
  ? 'Stage spans/progress plus bounded read-only NF/reach argument fingerprints. Emitter interval attribution disabled; coarse phase wall includes probe overhead. No generated-image edits.'
  : 'Existing stage spans and one typed-step checkpoint per second; additional fuel-construction/parser-call spans per file. No generated-image edits.',
 limitations:'Instrumentation contributes wall time. A deadline is diagnostic, not acceptance. Typed progress is a boundary sample, not exclusive CPU or a source-call count. No manifest-derived substage claim is made.',
});
try{
 const result=await runHeavyGate(guardedCommand,{...guard,label:'scheduler_chunk_smoke:diagnostic-emit'});
 save('guard.json',result);
 save('outcome.json',{acceptanceEvidence:false,endedAt:new Date().toISOString(),
  status:result.status,reason:result.reason,reportPhase:result.reportPhase,ownedTreeStopped:result.ownedTreeStopped,
  exitCode:result.exitCode,stdout,stderr,stageDirectory:join(output,'stages')});
 process.exitCode=result.exitCode;
}catch(error){
 save('outcome.json',{acceptanceEvidence:false,endedAt:new Date().toISOString(),status:'DRIVER_ERROR',error:String(error)});
 throw error;
}
