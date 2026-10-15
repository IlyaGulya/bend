#!/usr/bin/env bun
import * as B from '../bend2/bend.ts';
import {createHash} from 'node:crypto';
import {guardHeavyGate} from './heavy_gate.ts';
import {runPureTailFixtures,pureTailFixtures} from './stage0_pure_tail_fixtures.ts';
import {compilePureTail} from './stage0_pure_tail_compiler.ts';
import {readParserGraph} from './parser_full_graph.ts';
import {measurePureTailRepresentation,proveAffinePrefixPaths} from './stage0_pure_tail_representation.ts';
const frozen={
  'bend2/bend.ts':'47e1b06e2fa4466bad702f86d8cbce03f40e833a8ba8eaa1e04297fa46dc94a9',
  'bend2/selfhost/parser.bend':'f425995af41087dfa51f79e7b04259ea5d1acfa9906061c7ed57199bad4e18df',
  'bend2/selfhost/parser_full_generated_fuel.bend':'b66ca5fe16b41d65feb51afd95b3954550396b60e542c21a93fe042b7fa9d51e',
  'evals/parser_full_generate.ts':'0aedb4c1703cffe1055794b29829a357edcd956fdc0a8dec77bfa3c0cf7a6da6',
};
async function checkFrozen(){for(const[path,expected]of Object.entries(frozen))if(createHash('sha256').update(await Bun.file(path).text()).digest('hex')!==expected)throw Error('Frozen input drift: '+path);}
await guardHeavyGate(import.meta.path,{label:'pure-tail-native-and-real-adapter-gates'});
await checkFrozen();
try {
  const native=await runPureTailFixtures();
  const fixture=pureTailFixtures.find(f=>f.name==='affine-reconstruction');if(!fixture)throw Error('Missing affine real adapter fixture');
  const graph=await readParserGraph(fixture.source),body=graph.bodies.get('matrix'),sig=graph.signatures.get('matrix');
  if(!body||!sig)throw Error('Missing fixture Body/signature');
  const compiled=compilePureTail(body,sig.parameters,sig.result,graph.parserBook);
  const representation=measurePureTailRepresentation(compiled.term,compiled.residualNames);
  const affinePaths=proveAffinePrefixPaths(compiled.term,compiled.residualNames);
  const status=representation.pass?'PASS':'STOP_REPRESENTATION_GATE_FAILED';
  await checkFrozen();
  const compilerSha256=createHash('sha256').update(await Bun.file('evals/stage0_pure_tail_compiler.ts').text()).digest('hex');
  const fixturesSha256=createHash('sha256').update(await Bun.file('evals/stage0_pure_tail_fixtures.ts').text()).digest('hex');
  const result={status,native,representation:{fixture:fixture.name,...representation},affinePaths,frozenHashes:frozen,compilerSha256,fixturesSha256,
    productionDiff:'NONE',converterChanges:'NONE',largeProbes:'NOT_RUN_BY_THIS_PROBE',selfhostGreen:false};
  await Bun.write('checkpoints/stage0-pure-tail-semantic.json',JSON.stringify(result,null,2)+'\n');
  console.log(JSON.stringify({status,native:native.map(f=>({fixture:f.fixture,cases:f.prototype.outputs.length,stats:f.stats})),representation}));
} catch(error){const native=error as B.Err;if(native?.$==='Err')console.error(B.err_show(native));else console.error(error);throw Error('Pure-tail native gate failed; see actual diagnostic above');}
