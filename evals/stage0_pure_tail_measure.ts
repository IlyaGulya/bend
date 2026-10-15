#!/usr/bin/env bun
/** Same graph counter and fixture loader for pre-A1 baseline and evals prototype. */
import * as B from '../bend2/bend.ts';
import {createHash} from 'node:crypto';
import {guardHeavyGate} from './heavy_gate.ts';
import {readParserGraph} from './parser_full_graph.ts';
import {semanticCases} from './parser_full_match_factor_fixtures.ts';
import {compilePureTail} from './stage0_pure_tail_compiler.ts';
import {Observation} from './stage0_trailing_suffix_sharing.ts';
const frozen={
  'bend2/bend.ts':'47e1b06e2fa4466bad702f86d8cbce03f40e833a8ba8eaa1e04297fa46dc94a9',
  'bend2/selfhost/parser.bend':'f425995af41087dfa51f79e7b04259ea5d1acfa9906061c7ed57199bad4e18df',
  'bend2/selfhost/parser_full_generated_fuel.bend':'b66ca5fe16b41d65feb51afd95b3954550396b60e542c21a93fe042b7fa9d51e',
  'evals/parser_full_generate.ts':'0aedb4c1703cffe1055794b29829a357edcd956fdc0a8dec77bfa3c0cf7a6da6',
};
async function checkFrozen(){for(const[path,expected]of Object.entries(frozen))if(createHash('sha256').update(await Bun.file(path).text()).digest('hex')!==expected)throw Error('Frozen input drift: '+path);}
const kind=process.argv[2],mode=process.argv[3];
if((kind!=='diagnostic'&&kind!=='wide-matrix')||(mode!=='baseline'&&mode!=='prototype'))throw Error('Only diagnostic/wide baseline/prototype allowed');
await guardHeavyGate(import.meta.path,{label:'pure-tail-comparable-'+kind+'-'+mode});
await checkFrozen();
const semantic=JSON.parse(await Bun.file('checkpoints/stage0-pure-tail-semantic.json').text()) as {status:string;compilerSha256:string;fixturesSha256:string};
const census=JSON.parse(await Bun.file(`checkpoints/stage0-pure-tail-census-${kind}.json`).text()) as {censusGate:string};
if(semantic.status!=='PASS'||census.censusGate!=='PASS')throw Error('Native/representation/census gate is not PASS');
for(const[path,expected]of [['evals/stage0_pure_tail_compiler.ts',semantic.compilerSha256],['evals/stage0_pure_tail_fixtures.ts',semantic.fixturesSha256]])
  if(createHash('sha256').update(await Bun.file(path).text()).digest('hex')!==expected)throw Error('Semantic gate is stale: '+path);
const source=kind==='diagnostic'?await Bun.file('evals/stage0_match_diagnostic.bend').text():semanticCases.find(f=>f.name==='wide-matrix')!.source;
const graph=await readParserGraph(source),name=kind==='diagnostic'?'pattern_scan':'matrix';
const body=graph.bodies.get(name),signature=graph.signatures.get(name);if(!body||!signature)throw Error('Missing frozen matrix');
let term:B.LTerm,freshBinders:number,stats:ReturnType<typeof compilePureTail>['stats']|null=null;
const start=performance.now();
if(mode==='prototype'){
  const compiled=compilePureTail(body,signature.parameters,signature.result,graph.parserBook);
  term=compiled.term;stats=compiled.stats;freshBinders=compiled.stats.freshBinders;
}else{
  const vars:B.PVar[]=signature.parameters.map(([q,k,i,,s])=>({$:'PVar',q,k,i,s}));let fresh=0;
  function reserve(value:unknown){if(!value||typeof value!=='object')return;for(const[key,child]of Object.entries(value)){if(key==='s')continue;if(key==='i'&&typeof child==='number')fresh=Math.max(fresh,child+1);else reserve(child);}}
  reserve(body);for(const v of vars)fresh=Math.max(fresh,v.i+1);const initial=fresh;
  term=B.body_flatten(body,vars,()=>fresh++);freshBinders=fresh-initial;
}
const loweringMs=performance.now()-start;
const observation=new Observation(true);observation.visit(term);
const counts=observation.counts(observation.descendants(term)),nodeKinds={Sub:0,Lam:0,Let:0,App:0,Mat:0};
for(const node of observation.termNodes){const syntax=node as B.LTerm;if(syntax.$==='Sub'||syntax.$==='Lam'||syntax.$==='Let'||syntax.$==='App'||syntax.$==='Mat')nodeKinds[syntax.$]++;}
if(observation.observedCallbacks.size!==0)throw Error('Lower result unexpectedly contains opaque HOAS callbacks');
if(mode==='baseline'){
  const expected=kind==='diagnostic'?{objects:578315,Sub:212753,Lam:142729,Mat:20786,fresh:10279}:{objects:504756,Sub:250947,Lam:64377,Mat:20706,fresh:10210};
  if(counts.graphObjects!==expected.objects||nodeKinds.Sub!==expected.Sub||nodeKinds.Lam!==expected.Lam||nodeKinds.Mat!==expected.Mat||freshBinders!==expected.fresh)throw Error('Frozen comparable baseline drift');
}
await checkFrozen();
const result={kind,mode,scope:'EVALS_ONLY_PURE_TAIL_MEASUREMENT',frozenHashes:frozen,fixtureSha256:createHash('sha256').update(source).digest('hex'),
  loweredUniqueObjects:counts.graphObjects,termNodes:counts.termNodes,...nodeKinds,freshBinders,loweringMs,stats,
  graphCounting:'Enumerable graph including arrays/patterns/Quant excluding spans; same Observation counter and fixture loader in baseline/prototype, no attribution state-key overhead.',productionDiff:'NONE',selfhostGreen:false};
await Bun.write(`checkpoints/stage0-pure-tail-${kind}-${mode}.json`,JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify(result));
