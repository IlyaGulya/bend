#!/usr/bin/env bun
/** Narrow experiment, gated before adapters or large diagnostics; production is read-only. */
import {createHash} from 'node:crypto';
import {guardHeavyGate} from './heavy_gate.ts';
import {runNativeSuffixFixtures,runNativeSuffixWitness} from './stage0_trailing_suffix_native.ts';
import {runSuffixSharingWitness} from './stage0_trailing_suffix_sharing.ts';
const fixed={
  'bend2/bend.ts':'47e1b06e2fa4466bad702f86d8cbce03f40e833a8ba8eaa1e04297fa46dc94a9',
  'bend2/selfhost/parser.bend':'f425995af41087dfa51f79e7b04259ea5d1acfa9906061c7ed57199bad4e18df',
  'bend2/selfhost/parser_full_generated_fuel.bend':'b66ca5fe16b41d65feb51afd95b3954550396b60e542c21a93fe042b7fa9d51e',
};
async function hash(path:string){return createHash('sha256').update(new Uint8Array(await Bun.file(path).arrayBuffer())).digest('hex');}
async function frozen(){for(const[path,expected]of Object.entries(fixed))if(await hash(path)!==expected)throw Error('Frozen input changed: '+path);}
await guardHeavyGate(import.meta.path,{label:'trailing-suffix-representation-gate'});
await frozen();
const generatorBefore=await hash('evals/parser_full_generate.ts');
const native=await runNativeSuffixFixtures();
await Bun.write('checkpoints/stage0-trailing-suffix-native.json',JSON.stringify({status:'PASS',native},null,2)+'\n');
// No residual adapter is designed before this actual unchanged conversion pipeline gate.
const sharing=await runSuffixSharingWitness(runNativeSuffixWitness);
await frozen();if(await hash('evals/parser_full_generate.ts')!==generatorBefore)throw Error('Generator changed during experiment');
const stopped=!sharing.representationSharingSurvives;
const result={
  status:stopped?'REPRESENTATION_SHARING_FAILED_STOPPED':'REPRESENTATION_SURVIVES_ADAPTER_REQUIRED',
  scope:'TRAILING_AFTER_SUFFIX_ONLY_EXPERIMENTAL_EVALS',
  productionHashes:fixed,generatorSha256:generatorBefore,
  eligibility:'Boundary after last selected-C row; reject any before/between PVar prefix; preserve prefix/suffix order; allow other constructor rows in suffix.',
  nativeEvidence:'checkpoints/stage0-trailing-suffix-native.json',sharing,
  conditional:{affineEnvironmentAdapter:stopped?'NOT_STARTED_REPRESENTATION_GATE_FAILED':'NOT_STARTED',diagnosticEightRows:'NOT_RUN',wideMatrix:'NOT_RUN',fourTimesThreshold:'NOT_REACHED',productionDiff:'NONE'},
  forbidden:{generalWildcardSharing:'NOT_IMPLEMENTED',newMatchCompiler:'NOT_IMPLEMENTED',k2k3Caching:'NONE',decisionDagMemoization:'NONE',transformChanges:'NONE',beforeBetweenOptimization:'NONE'},
  frozenStatus:{parserSemantics:'PASS29/29_FROZEN',generatorParity:'PASS29/29_FROZEN',whole29:'NOT_RERUN',twentyRows:'NOT_RUN',fullParser:'NOT_RUN',regeneration:'NOT_RUN',selfhostGreen:false},
};
await Bun.write('checkpoints/stage0-trailing-suffix-result.json',JSON.stringify(result,null,2)+'\n');
console.log(JSON.stringify(result));
