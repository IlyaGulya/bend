#!/usr/bin/env bun
/** Reduce this experiment's closed, hash-guarded producer outputs; no compiler changes. */
import {guardHeavyGate} from './heavy_gate.ts';
import {createHash} from 'node:crypto';
import type {Report,NodeCounts,DescendantUnion,WildLink} from './stage0_match_node_attribution.ts';
type Counts=Pick<NodeCounts,'Sub'|'Lam'|'Mat'|'other'>;
type State={key:string;unique:number;repeats:number;callsCoveredByRepeatedGroups:number;duplicateCallsOwnedFinalObjects:number;duplicateCallsOwnedFinalObjectPercent:number};
type Shape={depth:number;rows:number;columns:number;constructor:string|null;action:string;calls:number;freshBinders:number;bodySubCalls:number;own:Counts};
type Split={id:number;depth:number;rows:number;columns:number;constructor:string|null;ps:number;ds:number;wildcardRows:number;removedConstructors:number;constructorPreparation:Counts;ownFinalObjects:Counts;constructorSideFinalAllocations:Counts;defaultSideFinalAllocations:Counts};
interface ProbeReport {
  kind:'diagnostic'|'wide-matrix';scope:string;baselineKernelSha256:string;
  allocation:Report;states:State[];absoluteIdMisses:{alphaGroupsWithMultipleAbsoluteKeys:number;distinctAbsoluteKeysCollapsedByAlpha:number;definition:string};
  matchFlattenCalls:number;freshBinders:number;maximumDepth:number;shapeDepth:Shape[];constructorDefaultSplits:Split[];lamSites:Record<string,number>;
  summary:{constructorSplits:number;wildcardDuplicationMemberships:number;bodySubCalls:number;wildcardOrderMemberships:Record<WildLink['order'],number>};
}
const BASELINE_SHA='47e1b06e2fa4466bad702f86d8cbce03f40e833a8ba8eaa1e04297fa46dc94a9';
const zero=():Counts=>({Sub:0,Lam:0,Mat:0,other:0});
function add(a:Counts,b:Counts){a.Sub+=b.Sub;a.Lam+=b.Lam;a.Mat+=b.Mat;a.other+=b.other;}
const sum=(c:Counts)=>c.Sub+c.Lam+c.Mat+c.other;
function union(r:DescendantUnion){return {graphObjects:r.graphObjects,percentage:r.percentageOfFinalGraphObjects,sourceOwned:r.sourceOwnedGraphObjects,constructor:r.bySide.constructor,default:r.bySide.default,before:r.byOrder.before,between:r.byOrder.between,after:r.byOrder.after,bySideOrder:r.bySideOrder};}
function reduceProbe(root:ProbeReport){
  if(root.scope!=='MEASUREMENT_ONLY_BASELINE_NO_COMPILER_CHANGE'||root.baselineKernelSha256!==BASELINE_SHA)throw Error('Foreign or stale producer output');
  const {allocation,summary}=root,{selectedBody:body,branchEnvelope:envelope}=allocation.wildcards;
  const graphObjects=allocation.graphObjects,kinds=allocation.nodeKinds;
  const nodeKinds={Sub:kinds.Sub,Lam:kinds.Lam,Mat:kinds.Mat,other:graphObjects-kinds.Sub-kinds.Lam-kinds.Mat};
  const states=root.states.map(s=>({key:s.key,unique:s.unique,repeats:s.repeats,callsCoveredByRepeatedGroups:s.callsCoveredByRepeatedGroups,repeatAllocatedObjects:s.duplicateCallsOwnedFinalObjects,repeatAllocationPercent:s.duplicateCallsOwnedFinalObjectPercent}));
  const owned=zero();for(const item of allocation.perOwner)add(owned,item);
  const {sourceOwned,unowned,lamEmissions}=allocation;
  if(sum(owned)+sum(sourceOwned)+sum(unowned)!==graphObjects)throw Error('Unique allocation conservation failed');
  if(Object.values(lamEmissions).reduce((n,c)=>n+c.finalLams,0)!==nodeKinds.Lam)throw Error('Lam reason conservation failed');
  const byAction=new Map<string,Counts>();let shapeCalls=0,shapeFresh=0,shapeSubs=0;
  const shapes=root.shapeDepth.map(row=>{let group=byAction.get(row.action);if(!group){group=zero();byAction.set(row.action,group);}add(group,row.own);shapeCalls+=row.calls;shapeFresh+=row.freshBinders;shapeSubs+=row.bodySubCalls;return {depth:row.depth,rows:row.rows,columns:row.columns,constructor:row.constructor,action:row.action,calls:row.calls,ownFinalObjects:row.own,ownTotal:sum(row.own)};});
  if(shapeCalls!==root.matchFlattenCalls||shapeFresh!==root.freshBinders||shapeSubs!==summary.bodySubCalls)throw Error('Shape/depth census conservation failed');
  const splits=root.constructorDefaultSplits.map(r=>({id:r.id,depth:r.depth,rows:r.rows,columns:r.columns,constructor:r.constructor,ps:r.ps,ds:r.ds,wildcardRows:r.wildcardRows,removedConstructors:r.removedConstructors,prepared:r.constructorPreparation,own:r.ownFinalObjects,constructorSide:r.constructorSideFinalAllocations,defaultSide:r.defaultSideFinalAllocations}));
  const prepared=zero(),splitOwn=zero();for(const s of splits){add(prepared,s.prepared);add(splitOwn,s.own);}
  const selectedContributions=body.bySplitSourceRowSideOrder.map(r=>{if(r.uniqueFinalGraphObjects===null||r.uniqueFinalNodeKinds===null)throw Error('Missing exact selected-body origin counts');return {splitId:r.splitId,sourceRow:r.sourceRow,side:r.side,order:r.order,nodes:r.uniqueFinalGraphObjects,nodeKinds:r.uniqueFinalNodeKinds,weightedSubtreeObjects:r.weightedSubtreeGraphObjects,roots:r.roots};});
  const wildcardOrderWeights={before:{memberships:summary.wildcardOrderMemberships.before,constructorNodes:0,defaultNodes:0},between:{memberships:summary.wildcardOrderMemberships.between,constructorNodes:0,defaultNodes:0},after:{memberships:summary.wildcardOrderMemberships.after,constructorNodes:0,defaultNodes:0}};
  for(const row of selectedContributions){if(row.side==='constructor')wildcardOrderWeights[row.order].constructorNodes+=row.nodes;else wildcardOrderWeights[row.order].defaultNodes+=row.nodes;}
  // Envelope origins enumerate EVERY duplicated candidate, including those never selected.
  const everyWildcard=new Map<string,{splitId:number;sourceRow:number;order:WildLink['order'];constructorNodes:number;defaultNodes:number}>();
  for(const r of envelope.bySplitSourceRowSideOrder){const key=r.splitId+':'+r.sourceRow;if(!everyWildcard.has(key))everyWildcard.set(key,{splitId:r.splitId,sourceRow:r.sourceRow,order:r.order,constructorNodes:0,defaultNodes:0});}
  for(const row of selectedContributions){const item=everyWildcard.get(row.splitId+':'+row.sourceRow);if(!item)throw Error('Selected wildcard origin missing candidate');if(row.side==='constructor')item.constructorNodes=row.nodes;else item.defaultNodes=row.nodes;}
  if(everyWildcard.size!==summary.wildcardDuplicationMemberships)throw Error('Wildcard candidate census incomplete');
  const strongestForks=splits.filter(s=>sum(s.defaultSide)>0.05*(sum(s.constructorSide)+sum(s.defaultSide))&&sum(s.constructorSide)+sum(s.defaultSide)>10000).sort((a,b)=>sum(b.constructorSide)+sum(b.defaultSide)-sum(a.constructorSide)-sum(a.defaultSide)).slice(0,8);
  return {kind:root.kind,graphObjects,nodeKinds,sourceOwned,unowned,states,absoluteIdMisses:root.absoluteIdMisses,calls:root.matchFlattenCalls,freshBinders:root.freshBinders,maximumDepth:root.maximumDepth,bodySubCalls:summary.bodySubCalls,constructorSplits:summary.constructorSplits,wildcardMemberships:summary.wildcardDuplicationMemberships,allocationByAction:Object.fromEntries(byAction),splitPreparation:prepared,splitOwn,rootSplit:splits[0],strongestForks,topShapeDepth:shapes.sort((a,b)=>b.ownTotal-a.ownTotal).slice(0,12),wildcardBodyUnion:union(body.union),wildcardBranchEnvelope:union(envelope.union),wildcardOrderWeights,wildcardTopBodies:[...everyWildcard.values()].sort((a,b)=>b.constructorNodes+b.defaultNodes-a.constructorNodes-a.defaultNodes).slice(0,12),wildcardsNeverSelectedEitherSide:[...everyWildcard.values()].filter(row=>row.constructorNodes===0&&row.defaultNodes===0).length,lamEmissions,lamSites:root.lamSites,weightedCountsCaveat:'Per-origin UNIQUE counts still overlap across ancestor splits. Weighted Lam subtrees count shared edges and ancestor wrappers repeatedly; only global identity unions yield final-node percentages.'};
}
await guardHeavyGate(import.meta.path,{label:'match-attribution-decision-reduction'});
const probes=[];
for(const kind of ['diagnostic','wide-matrix'] as const){
  // Fixed files produced by stage0_match_allocation_probe.ts in this run, not external/config inputs.
  const report=JSON.parse(await Bun.file(`checkpoints/stage0-match-attribution-${kind}.json`).text()) as ProbeReport;
  if(report.kind!==kind)throw Error('Producer fixture mismatch');
  probes.push(reduceProbe(report));Bun.gc(true);
}
const diagnostic=probes[0],wide=probes[1],k2=diagnostic.states.find(s=>s.key==='K2')!;
const classification=k2.repeatAllocationPercent>=50?'M':diagnostic.wildcardBodyUnion.percentage>=50&&wide.wildcardBodyUnion.percentage>=50?'W':'MIXED';
if(classification!=='W')throw Error('Decision no longer matches evidence; review before reporting');
const productionHash=createHash('sha256').update(await Bun.file('bend2/bend.ts').text()).digest('hex');if(productionHash!==BASELINE_SHA)throw Error('Production kernel drift');
const result={status:'MEASUREMENT_COMPLETE_NO_IMPLEMENTATION',classification,productionKernelSha256:productionHash,restoration:'checkpoints/stage0-a1-restoration.json',rawEvidence:['checkpoints/stage0-match-attribution-diagnostic.json','checkpoints/stage0-match-attribution-wide-matrix.json'],probes,decision:'W: 87.80%/88.25% of unique final graph objects descend from actually selected duplicated-wildcard Body outputs; full alpha-normalized matrix states remain almost/all unique. K3 control-only recurrence is high but cannot license output reuse.',rejectedCases:{M:'K2 optimistic directly-owned repeat allocation ceiling is only 0.919% diagnostic and 0% wide; ID renumbering collapses only one diagnostic structural state.',L:'Lam wrappers are 24.68%/12.75% of final graph objects. Constructor fields dominate Lam counts, not overall allocation; overlapping subtree weights are not a unique-node percentage.'},proposalOnly:'Evaluate sharing an ordered residual-row suffix/continuation with explicit binder/quantity environment adapters. Invoke it at the exact original row position: a before/between wildcard must be tried before later constructor rows, and failure resumes the remaining ordered rows. Validate before/between/after shadowing, nested-field binding and affine transfer. Not constructor-rows-first plus one global fallback.',implemented:false,a2:'NOT_STARTED',resultCaching:'NONE',compilerAlgorithm:'UNCHANGED_PRE_A1',twentyRows:'NOT_RUN',fullParser:'NOT_RUN',whole29:'FROZEN_NOT_RERUN',regeneration:'NOT_RUN',selfhostGreen:false};
await Bun.write('checkpoints/stage0-match-attribution-decision.json',JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify(result));
