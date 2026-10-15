#!/usr/bin/env bun
import * as B from '../bend2/bend.ts';
import {createHash} from 'node:crypto';
import {guardHeavyGate} from './heavy_gate.ts';
import {runExplicitBindingSharing} from './stage0_explicit_binding_sharing.ts';
import {runExplicitBindingOwnership} from './stage0_explicit_binding_ownership.ts';
const fixed={
  'bend2/bend.ts':'47e1b06e2fa4466bad702f86d8cbce03f40e833a8ba8eaa1e04297fa46dc94a9',
  'bend2/selfhost/parser.bend':'f425995af41087dfa51f79e7b04259ea5d1acfa9906061c7ed57199bad4e18df',
  'bend2/selfhost/parser_full_generated_fuel.bend':'b66ca5fe16b41d65feb51afd95b3954550396b60e542c21a93fe042b7fa9d51e',
  'evals/parser_full_generate.ts':'0aedb4c1703cffe1055794b29829a357edcd956fdc0a8dec77bfa3c0cf7a6da6',
};
async function frozen(){
  for(const[path,expected]of Object.entries(fixed)){
    const actual=createHash('sha256').update(new Uint8Array(await Bun.file(path).arrayBuffer())).digest('hex');
    if(actual!==expected)throw Error('Frozen input changed: '+path);
  }
}
await guardHeavyGate(import.meta.path,{label:'explicit-binding-tiny-representation-gate'});
await frozen();
try {
  const representation=await runExplicitBindingSharing();
  const ownership=await runExplicitBindingOwnership();
  await frozen();
  const ownershipGate=ownership.every(o=>o.bookValid===(o.quantity==='Lone'&&o.callShape==='exclusive-branches')
    &&o.actual===(o.quantity==='Lone'&&o.callShape==='exclusive-branches'?'PASS':'FAIL')
    &&(o.actual==='PASS'||o.failureKind===(o.quantity==='Many'?'function-kind':'affine-usage')));
  const decision=representation.representationSurvives&&ownershipGate?'EXPLICIT BINDING REPRESENTATION PASSES':'EXPLICIT BINDING FAILS';
  const result={decision,scope:'TINY_EXPLICIT_LET_LAMBDA_REPRESENTATION_ONLY',frozenHashes:fixed,
    representation,ownership,ownershipGate,
    reclassification:{formerDecision:'EXPLICIT BINDING FAILS',cause:'Solely an incorrect exclusive affine-capture rejection expectation; original observations retained.',exclusiveAffineCapture:'LEGAL',checkerOrQuantityChanges:'NONE'},
    productionDiff:'NONE',converterChanges:'NONE',matchFlattenChanges:'NONE',affineAdapter:'NOT_IMPLEMENTED',
    prohibitedRuns:{eightRowDiagnostic:'NOT_RUN',wide:'NOT_RUN',twentyRowDiagnostic:'NOT_RUN',wholeParser:'NOT_RUN',regeneration:'NOT_RUN',whole29:'NOT_RERUN'},
    frozenStatus:{parserSemanticParity:'PASS29/29_FROZEN',generatorParity:'PASS29/29_FROZEN',caseW:'ACCEPTED',rawPointerSharing:'REJECTED',selfhostGreen:false}};
  await Bun.write('checkpoints/stage0-explicit-binding-result.json',JSON.stringify(result,null,2)+'\n');
  console.log(JSON.stringify(result));
} catch(error){
  const native=error as B.Err;
  if(native?.$==='Err')console.error(B.err_show(native));
  else console.error(error);
  throw Error('Explicit binding probe failed; see actual diagnostic above');
}
