#!/usr/bin/env bun
/** Measurement-only projection of the frozen attribution hooks; no compiler rewrite. */
import {createHash,randomUUID} from 'node:crypto';
import {resolve} from 'node:path';
import {unlink} from 'node:fs/promises';
import {guardHeavyGate} from './heavy_gate.ts';
import {readParserGraph} from './parser_full_graph.ts';
import {semanticCases} from './parser_full_match_factor_fixtures.ts';
import type {PVar,Body} from '../bend2/bend.ts';
import type {AllocationObserver} from './stage0_match_allocation_probe.ts';
import type {Report,RootContribution} from './stage0_match_node_attribution.ts';
const frozen={
  'bend2/bend.ts':'47e1b06e2fa4466bad702f86d8cbce03f40e833a8ba8eaa1e04297fa46dc94a9',
  'bend2/selfhost/parser.bend':'f425995af41087dfa51f79e7b04259ea5d1acfa9906061c7ed57199bad4e18df',
  'bend2/selfhost/parser_full_generated_fuel.bend':'b66ca5fe16b41d65feb51afd95b3954550396b60e542c21a93fe042b7fa9d51e',
  'evals/parser_full_generate.ts':'0aedb4c1703cffe1055794b29829a357edcd956fdc0a8dec77bfa3c0cf7a6da6',
};
async function checkFrozen(){for(const[path,sha]of Object.entries(frozen))if(createHash('sha256').update(await Bun.file(path).text()).digest('hex')!==sha)throw Error('Frozen input drift: '+path);}
function replaceOnce(source:string,anchor:string,replacement:string){
  if(source.split(anchor).length!==2)throw Error('Census instrumentation anchor changed: '+anchor);
  return source.replace(anchor,replacement);
}
type PureCall=AllocationObserver['calls'][number]&{wild:{sourceRow:number;order:'before'|'between'|'after';pureTail:boolean}[]};
type CensusObserver=AllocationObserver&{calls:PureCall[]};
type Baseline={kind:string;fixtureSha256:string;summary:{constructorSplits:number;wildcardDuplicationMemberships:number};allocation:Report};
function weighted(rows:RootContribution[]){let total=0;for(const row of rows){if(row.weightedSubtreeGraphObjects===null)throw Error('Cyclic subtree');total+=row.weightedSubtreeGraphObjects;}if(!Number.isSafeInteger(total))throw Error('Unsafe attribution weight');return total;}
await guardHeavyGate(import.meta.path,{label:'pure-trailing-pvar-census'});
const kind=process.argv[2];
if(kind!=='diagnostic'&&kind!=='wide-matrix')throw Error('Only frozen diagnostic/wide census allowed');
await checkFrozen();
const original=await Bun.file('evals/stage0_match_allocation_probe.ts').text();
const attribution=await Bun.file('evals/stage0_match_node_attribution.ts').text();
let observerSource=original.slice(0,original.indexOf('await guardHeavyGate(import.meta.path'));
if(!observerSource.includes('function instrument(source:string)'))throw Error('Frozen observer boundary changed');
// State-cache census is unrelated to eligibility. Omit only its observational
// string keys, never any lowering branch, binder, substitution or factory hook.
observerSource=replaceOnce(observerSource,'const keys=this.keyMaker.keys(m,vars),id=this.calls.length,parent=this.stack.at(-1);','const id=this.calls.length,parent=this.stack.at(-1);');
observerSource=replaceOnce(observerSource,'const groups=[keys.k1,keys.k2,keys.k3,keys.kAbsolute].map((key,index)=>{let group=this.states[index].get(key);if(!group){group={id:this.states[index].size,calls:0,outputWeight:0,ownObjects:0,duplicateOwnObjects:0,firstCall:id};this.states[index].set(key,group);}group.calls++;return group;});','const groups:Group[]=[];');
observerSource=replaceOnce(observerSource,"type WildRow={sourceRow:number;order:WildLink['order']};","type WildRow={sourceRow:number;order:WildLink['order'];pureTail:boolean};");
observerSource=replaceOnce(observerSource,'call.removedConstructors=matching.length;const first=matching[0],last=matching.at(-1)!;',
  `call.removedConstructors=matching.length;const first=matching[0],last=matching.at(-1)!;
    let lastAnyConstructor=-1;
    for(let j=0;j<m.r.length;j++)if(m.r[j].p[0]?.$==='PCtr')lastAnyConstructor=j;
    const boundary=lastAnyConstructor+1;
    const pure=lastAnyConstructor>=0&&boundary<m.r.length
      &&m.r.slice(0,boundary).every(row=>row.p[0]?.$!=='PVar')
      &&m.r.slice(boundary).every(row=>row.p[0]?.$==='PVar');`);
observerSource=replaceOnce(observerSource,"sourceRow:this.sourceRow(row),order:index<first?'before':index>last?'after':'between'","sourceRow:this.sourceRow(row),order:index<first?'before':index>last?'after':'between',pureTail:pure&&index>=boundary");
// Numeric provenance projection only: retain eligible ancestors, skip all other
// wildcard origins. The unchanged attribution analyzer computes their EXACT
// final identity union; no overlapping per-origin percentages are summed.
observerSource=replaceOnce(observerSource,'for(const wild of call.wild){const link:WildLink=', 'for(const wild of call.wild){if(!wild.pureTail)continue;const link:WildLink=');
observerSource+='\nexport {instrument};\n';
const id=randomUUID(),observerPath=resolve(import.meta.dir,'.pure-tail-observer-'+id+'.ts'),kernelPath=resolve('bend2/.pure-tail-kernel-'+id+'.ts');
const registry=globalThis as typeof globalThis&{__stage0_allocation?:AllocationObserver};
try {
  await Bun.write(observerPath,observerSource);
  const helpers: {AllocationObserver:new(body:Body,vars:PVar[])=>CensusObserver;instrument:(source:string)=>string}=await import(observerPath);
  const fixture=kind==='diagnostic'?await Bun.file('evals/stage0_match_diagnostic.bend').text():semanticCases.find(f=>f.name==='wide-matrix')!.source;
  const graph=await readParserGraph(fixture),name=kind==='diagnostic'?'pattern_scan':'matrix';
  const body=graph.bodies.get(name),signature=graph.signatures.get(name);
  if(!body||!signature)throw Error('Frozen fixture missing matrix');
  const vars:PVar[]=signature.parameters.map(([q,k,i,,s])=>({$:'PVar',q,k,i,s}));
  let fresh=0;
  function reserve(value:unknown){if(!value||typeof value!=='object')return;for(const[key,child]of Object.entries(value)){if(key==='s')continue;if(key==='i'&&typeof child==='number')fresh=Math.max(fresh,child+1);else reserve(child);}}
  reserve(body);for(const v of vars)fresh=Math.max(fresh,v.i+1);const initialFresh=fresh;
  const observer=new helpers.AllocationObserver(body,vars);registry.__stage0_allocation=observer;
  const source=await Bun.file('bend2/bend.ts').text();
  await Bun.write(kernelPath,helpers.instrument(source));
  const kernel:typeof import('../bend2/bend.ts')=await import(kernelPath);
  const start=performance.now();
  const lower=kernel.body_flatten(body,vars,()=>{observer.fresh();return fresh++;});
  const loweringMs=performance.now()-start;
  const allocation=observer.nodes.analyze(lower);
  const baseline=JSON.parse(await Bun.file(`checkpoints/stage0-match-attribution-${kind}.json`).text()) as Baseline;
  const splits=observer.calls.filter(c=>c.action==='constructor-split');
  const eligible=splits.filter(c=>c.wild.some(w=>w.pureTail));
  const memberships=splits.reduce((n,c)=>n+c.wildcardRows,0),covered=splits.reduce((n,c)=>n+c.wild.filter(w=>w.pureTail).length,0);
  const expected=kind==='diagnostic'?{objects:578315,Sub:212753,Lam:142729,Mat:20786,fresh:10279}:{objects:504756,Sub:250947,Lam:64377,Mat:20706,fresh:10210};
  if(allocation.graphObjects!==expected.objects||allocation.nodeKinds.Sub!==expected.Sub||allocation.nodeKinds.Lam!==expected.Lam||allocation.nodeKinds.Mat!==expected.Mat||fresh-initialFresh!==expected.fresh)throw Error('Census changed frozen lowering graph');
  if(baseline.kind!==kind||baseline.fixtureSha256!==createHash('sha256').update(fixture).digest('hex')||splits.length!==baseline.summary.constructorSplits||memberships!==baseline.summary.wildcardDuplicationMemberships)throw Error('Census drift from frozen split/membership baseline');
  const selected=allocation.wildcards.selectedBody;
  const result={kind,scope:'PURE_TAIL_CENSUS_NO_ADAPTER',eligibility:'Non-empty suffix entirely PVar after the LAST PCtr of ANY constructor in current selected column; reject boundary if any PVar appears before/between constructor rows.',
    frozenHashes:frozen,instrumentationHashes:{producer:createHash('sha256').update(original).digest('hex'),attribution:createHash('sha256').update(attribution).digest('hex')},
    constructorSplits:splits.length,pureTailSplits:eligible.length,totalDuplicatedWildcardMemberships:memberships,pureTailCoveredMemberships:covered,uncoveredMemberships:memberships-covered,
    finalGraphObjects:allocation.graphObjects,nodeKinds:allocation.nodeKinds,freshBinders:fresh-initialFresh,instrumentedLoweringMs:loweringMs,
    provenance:{pureTailUniqueFinalObjects:selected.union.graphObjects,pureTailPercentOfFinalObjects:selected.union.percentageOfFinalGraphObjects,
      allWildcardUniqueFinalObjects:baseline.allocation.wildcards.selectedBody.union.graphObjects,
      pureTailPercentOfAllWildcardProvenance:100*selected.union.graphObjects/baseline.allocation.wildcards.selectedBody.union.graphObjects,
      weightedPureTailDescendantObjects:weighted(selected.bySplitSourceRowSideOrder),weightedAllWildcardDescendantObjects:weighted(baseline.allocation.wildcards.selectedBody.bySplitSourceRowSideOrder),
      definition:selected.definition,weightedCaveat:'Weighted sums overlap through roots and origins; census gate uses exact UNIQUE selected-body descendant union divided by final graph objects, not summed weights.'},
    censusGate:selected.union.percentageOfFinalGraphObjects>=50?'PASS':'STOP_BELOW_HALF',
    perEligibleSplit:eligible.map(c=>({id:c.id,constructor:c.constructor,depth:c.depth,rows:c.rows,columns:c.columns,pureTailRows:c.wild.filter(w=>w.pureTail).map(w=>w.sourceRow)})),
    adapter:'NOT_IMPLEMENTED',productionDiff:'NONE',selfhostGreen:false};
  await checkFrozen();
  await Bun.write(`checkpoints/stage0-pure-tail-census-${kind}.json`,JSON.stringify(result,null,2)+'\n');
  console.log(JSON.stringify({...result,perEligibleSplit:undefined}));
} finally {
  await unlink(observerPath);await unlink(kernelPath).catch(error=>{if(error.code!=='ENOENT')throw error;});delete registry.__stage0_allocation;
}
