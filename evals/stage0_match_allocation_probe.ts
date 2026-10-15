#!/usr/bin/env bun
/** Measurement only. Transient hooks preserve the frozen baseline algorithm. */
import {createHash,randomUUID} from 'node:crypto';
import {resolve} from 'node:path';
import {unlink} from 'node:fs/promises';
import type {Body,Case,Match,PVar,LTerm} from '../bend2/bend.ts';
import {readParserGraph} from './parser_full_graph.ts';
import {semanticCases} from './parser_full_match_factor_fixtures.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {MatrixStateKeys} from './stage0_match_state_keys.ts';
import {LoweringNodeAttribution,type WildLink,type LamReason} from './stage0_match_node_attribution.ts';
type Counts={Sub:number;Lam:number;Mat:number;other:number};
const empty=():Counts=>({Sub:0,Lam:0,Mat:0,other:0});
const total=(c:Counts)=>c.Sub+c.Lam+c.Mat+c.other;
function add(a:Counts,b:Counts){a.Sub+=b.Sub;a.Lam+=b.Lam;a.Mat+=b.Mat;a.other+=b.other;}
type Group={id:number;calls:number;outputWeight:number;ownObjects:number;duplicateOwnObjects:number;firstCall:number};
type WildRow={sourceRow:number;order:WildLink['order']};
type Call={id:number;parent:number;edge:'linear'|WildLink['side'];phase:0|1;depth:number;rows:number;columns:number;variables:number;constructor:string|null;action:string;ps:number;ds:number;wildcardRows:number;removedConstructors:number;fresh:number;bodySubCalls:number;bodySubRootCalls:number;output:Counts;own:Counts;preparedConstructor:Counts;inclusive:Counts;constructorAllocation:Counts;defaultAllocation:Counts;keys:Group[];duplicate:boolean[];wild:WildRow[]};
const BASELINE_SHA='47e1b06e2fa4466bad702f86d8cbce03f40e833a8ba8eaa1e04297fa46dc94a9';
export class AllocationObserver {
  readonly calls:Call[]=[];
  readonly states=[new Map<string,Group>(),new Map<string,Group>(),new Map<string,Group>(),new Map<string,Group>()];
  readonly keyMaker=new MatrixStateKeys();
  readonly nodes:LoweringNodeAttribution;
  readonly stack:Call[]=[];
  readonly sourceRows=new WeakMap<Case,number>();
  readonly fields=new Set<number>();
  readonly originalParameters:Set<number>;
  readonly weights=new WeakMap<object,Counts>();
  readonly lamSiteCounts:Record<string,number>={};
  histories=new Map<number,WildLink>();
  nextRow=0;
  subDepth=0;
  lamReason:LamReason='other';
  pendingEdge:'linear'|WildLink['side']='linear';
  constructor(body:Body,vars:PVar[]){this.nodes=new LoweringNodeAttribution(body);this.originalParameters=new Set(vars.map(v=>v.i));this.registerRows(body);}
  registerRows(body:Body){if(body.$==='Match'){for(const row of body.r){this.sourceRows.set(row,this.nextRow++);this.registerRows(row.f);}}else if(body.$==='Local')this.registerRows(body.f);}
  sourceRow(row:Case){const id=this.sourceRows.get(row);if(id===undefined)throw Error('Untracked row lineage');return id;}
  copyRow(original:Case,row:Case){this.sourceRows.set(row,this.sourceRow(original));return row;}
  enter(m:Match,vars:PVar[]):number {
    const keys=this.keyMaker.keys(m,vars),id=this.calls.length,parent=this.stack.at(-1);
    const groups=[keys.k1,keys.k2,keys.k3,keys.kAbsolute].map((key,index)=>{let group=this.states[index].get(key);if(!group){group={id:this.states[index].size,calls:0,outputWeight:0,ownObjects:0,duplicateOwnObjects:0,firstCall:id};this.states[index].set(key,group);}group.calls++;return group;});
    const call:Call={id,parent:parent?.id??-1,edge:this.pendingEdge,phase:0,depth:this.stack.length,rows:m.r.length,columns:m.r[0]?.p.length??m.e.length,variables:vars.length,constructor:m.r.map(row=>row.p[0]).find(p=>p?.$==='PCtr')?.k??null,action:m.e.length===0?(m.r.length?'selected-row':'uncovered'):(vars.length===0?'select-scrutinee':'pending'),ps:0,ds:0,wildcardRows:0,removedConstructors:0,fresh:0,bodySubCalls:0,bodySubRootCalls:0,output:empty(),own:empty(),preparedConstructor:empty(),inclusive:empty(),constructorAllocation:empty(),defaultAllocation:empty(),keys:groups,duplicate:groups.map(g=>g.calls>1),wild:[]};
    this.pendingEdge='linear';
    this.calls.push(call);this.stack.push(call);return id;
  }
  leave(id:number){if(this.stack.pop()?.id!==id)throw Error('Unbalanced observer call stack');}
  exit(id:number,result:LTerm){const call=this.calls[id];call.output=this.weight(result);for(const group of call.keys)group.outputWeight+=total(call.output);}
  weight(value:unknown):Counts {
    if(!value||typeof value!=='object')return empty();
    const prior=this.weights.get(value);if(prior)return prior;
    const counts=empty();if('$'in value&&value.$==='Sub')counts.Sub++;else if('$'in value&&value.$==='Lam')counts.Lam++;else if('$'in value&&value.$==='Mat')counts.Mat++;else counts.other++;
    for(const[key,child]of Object.entries(value))if(key!=='s')add(counts,this.weight(child));this.weights.set(value,counts);return counts;
  }
  emit<T extends object>(node:T):T{const call=this.stack.at(-1);if(call)this.nodes.mark(node,call.id*3+call.phase);return node;}
  emitLam<T extends object>(node:T):T{const call=this.stack.at(-1);if(call)this.nodes.mark(node,call.id*3+call.phase,this.lamReason);return node;}
  withLam<T>(site:'skipped'|'reply',i:number,action:()=>T):T {
    const prior=this.lamReason;
    const origin=this.fields.has(i)?'field':this.originalParameters.has(i)?'original':'other';
    this.lamReason=origin==='field'?'constructor-field':site==='skipped'?'skipped-parameter':origin==='original'?'reply-parameter':'other';
    const key=site+':'+origin;this.lamSiteCounts[key]=(this.lamSiteCounts[key]??0)+1;
    try{return action();}finally{this.lamReason=prior;}
  }
  enterSub(){const call=this.stack.at(-1);if(call){call.bodySubCalls++;if(this.subDepth===0)call.bodySubRootCalls++;}this.subDepth++;}
  leaveSub(){this.subDepth--;}
  fresh(){const call=this.stack.at(-1);if(call)call.fresh++;}
  variableColumn(){const call=this.stack.at(-1);if(call)call.action='variable-column';}
  skipped(){const call=this.stack.at(-1);if(call)call.action='skipped-parameter';}
  split(m:Match,k:string,xs:PVar[],kx:unknown){
    const call=this.stack.at(-1)!;call.action='constructor-split';call.phase=1;
    const matching=m.r.flatMap((row,index)=>row.p[0].$==='PCtr'&&row.p[0].k===k?[index]:[]);
    if(!matching.length)throw Error('Split without matching row');
    call.removedConstructors=matching.length;const first=matching[0],last=matching.at(-1)!;
    call.wild=m.r.flatMap((row,index)=>row.p[0].$==='PVar'?[{sourceRow:this.sourceRow(row),order:index<first?'before':index>last?'after':'between'} as WildRow]:[]);call.wildcardRows=call.wild.length;
    for(const x of xs)this.fields.add(x.i);this.nodes.mark(kx,call.id*3+1);
  }
  branch<T extends LTerm>(side:WildLink['side'],rows:Case[],action:()=>T):T {
    const call=this.stack.at(-1)!;call.phase=0;if(side==='constructor')call.ps=rows.length;else call.ds=rows.length;
    this.pendingEdge=side;
    const prior=this.histories,next=new Map(prior),links:WildLink[]=[];
    for(const wild of call.wild){const link:WildLink={splitId:call.id,side,order:wild.order,sourceRow:wild.sourceRow,previous:prior.get(wild.sourceRow)};next.set(wild.sourceRow,link);links.push(link);}
    this.histories=next;try{const result=action();this.nodes.branch(result,links);return result;}finally{this.histories=prior;this.pendingEdge='linear';}
  }
  selected<T extends LTerm>(row:Case,action:()=>T):T{const sourceRow=this.sourceRow(row);const result=action();this.nodes.leaf(result,this.histories.get(sourceRow),sourceRow);return result;}
}
function instrument(source:string):string {
  function replace(anchor:string,replacement:string){if(source.split(anchor).length!==2)throw Error('Instrumentation anchor not unique: '+anchor);source=source.replace(anchor,replacement);}
  for(const[name,fields]of [['Sub','i, v, f, s'],['Mat','k, h, m, s'],['Efq','s'],['Ctr','k, x, s'],['Let','k, i, q: q ?? k.map(() => Lone()), v, f, s']])replace(`return { $: "${name}", ${fields} };`,`return __measure.emit({ $: "${name}" as const, ${fields} });`);
  replace('return { $: "Lam", k, i, f, s, q };','return __measure.emitLam({ $: "Lam" as const, k, i, f, s, q });');
  replace('export function body_sub(b: Body, i: number, v: Patt): Body {',`export function body_sub(b: Body, i: number, v: Patt): Body {\n  __measure.enterSub();\n  try { return __measured_body_sub(b, i, v); } finally { __measure.leaveSub(); }\n}\nfunction __measured_body_sub(b: Body, i: number, v: Patt): Body {`);
  replace('export function match_flatten(m: Match, vars: PVar[], fr: () => number): LTerm {',`export function match_flatten(m: Match, vars: PVar[], fr: () => number): LTerm {\n  const id = __measure.enter(m, vars);\n  try { const result = __measured_match_flatten(m, vars, fr); __measure.exit(id, result); return result; } finally { __measure.leave(id); }\n}\nfunction __measured_match_flatten(m: Match, vars: PVar[], fr: () => number): LTerm {`);
  replace('return body_flatten(m.r[0].f, vars, fr);','return __measure.selected(m.r[0], () => body_flatten(m.r[0].f, vars, fr));');
  replace('const w  = { ...v, q: patt_mark(v, m.r) };','__measure.variableColumn();\n      const w  = { ...v, q: patt_mark(v, m.r) };');
  replace('return { p: row.p.slice(1), f: body_sub(row.f, p0.i, w) };','return __measure.copyRow(row, { p: row.p.slice(1), f: body_sub(row.f, p0.i, w) });');
  replace('const kx: Patt = { $: "PCtr", k: c.k, x: xs, s: x.s };','const kx: Patt = { $: "PCtr", k: c.k, x: xs, s: x.s };\n        __measure.split(m, c.k, xs, kx);');
  replace('return [{ p: [...p0.x, ...row.p.slice(1)], f }];','return [__measure.copyRow(row, { p: [...p0.x, ...row.p.slice(1)], f })];');
  replace('return [{ p: [...xs, ...row.p.slice(1)], f }];','return [__measure.copyRow(row, { p: [...xs, ...row.p.slice(1)], f })];');
  replace('const pt = match_flatten({ $: "Match", e: pe, r: ps, s: m.s }, pv, fr);','const pt = __measure.branch("constructor", ps, () => match_flatten({ $: "Match", e: pe, r: ps, s: m.s }, pv, fr));');
  replace('const dt = match_flatten({ $: "Match", e: m.e, r: ds, s: m.s }, vars, fr);','const dt = __measure.branch("default", ds, () => match_flatten({ $: "Match", e: m.e, r: ds, s: m.s }, vars, fr));');
  replace('return Lam(x.k, x.i, t, x.s, x.q);','__measure.skipped();\n      return __measure.withLam("skipped", x.i, () => Lam(x.k, x.i, t, x.s, x.q));');
  replace('return Lam(v.k, v.i, f, v.s, v.q);','return __measure.withLam("reply", v.i, () => Lam(v.k, v.i, f, v.s, v.q));');
  return source+'\nconst __measure = (globalThis as typeof globalThis & {__stage0_allocation: import("../evals/stage0_match_allocation_probe.ts").AllocationObserver}).__stage0_allocation;\n';
}
function aggregate(calls:Call[]){
  const shapes=new Map<string,{depth:number;rows:number;columns:number;variables:number;constructor:string|null;action:string;calls:number;splits:number;psRows:number;dsRows:number;wildcardMemberships:number;removedConstructorRows:number;freshBinders:number;bodySubCalls:number;bodySubRootCalls:number;own:Counts;inclusiveOutputEdgeWeights:Counts}>();
  for(const c of calls){const key=[c.depth,c.rows,c.columns,c.variables,c.constructor,c.action].join('|');let row=shapes.get(key);if(!row){row={depth:c.depth,rows:c.rows,columns:c.columns,variables:c.variables,constructor:c.constructor,action:c.action,calls:0,splits:0,psRows:0,dsRows:0,wildcardMemberships:0,removedConstructorRows:0,freshBinders:0,bodySubCalls:0,bodySubRootCalls:0,own:empty(),inclusiveOutputEdgeWeights:empty()};shapes.set(key,row);}row.calls++;row.splits+=Number(c.action==='constructor-split');row.psRows+=c.ps;row.dsRows+=c.ds;row.wildcardMemberships+=c.wildcardRows;row.removedConstructorRows+=c.removedConstructors;row.freshBinders+=c.fresh;row.bodySubCalls+=c.bodySubCalls;row.bodySubRootCalls+=c.bodySubRootCalls;add(row.own,c.own);add(row.inclusiveOutputEdgeWeights,c.output);}
  return [...shapes.values()].sort((a,b)=>total(b.own)-total(a.own));
}
await guardHeavyGate(import.meta.path,{label:'baseline-match-allocation-attribution'});
const kind=process.argv[2]??'diagnostic';
if(kind!=='diagnostic'&&kind!=='wide-matrix')throw Error('Only eight-row diagnostic and wide-matrix are allowed');
const source=await Bun.file(resolve('bend2/bend.ts')).text();if(createHash('sha256').update(source).digest('hex')!==BASELINE_SHA)throw Error('Production kernel is not exact pre-A1 baseline');
const fixture=kind==='diagnostic'?await Bun.file('evals/stage0_match_diagnostic.bend').text():semanticCases.find(item=>item.name==='wide-matrix')!.source;
const graph=await readParserGraph(fixture),name=kind==='diagnostic'?'pattern_scan':'matrix',body=graph.bodies.get(name)!,signature=graph.signatures.get(name)!;
const vars:PVar[]=signature.parameters.map(([q,k,i,,s])=>({$:'PVar',q,k,i,s}));
let fresh=0;function reserve(x:unknown){if(!x||typeof x!=='object')return;for(const[key,v]of Object.entries(x)){if(key==='s')continue;if(key==='i'&&typeof v==='number')fresh=Math.max(fresh,v+1);else reserve(v);}}reserve(body);for(const v of vars)fresh=Math.max(fresh,v.i+1);const initialFresh=fresh;
const observer=new AllocationObserver(body,vars);
const registry=globalThis as typeof globalThis & {__stage0_allocation?:AllocationObserver};registry.__stage0_allocation=observer;
const temporary=resolve(import.meta.dir,'../bend2/.stage0-allocation-'+randomUUID()+'.ts');
try {
  await Bun.write(temporary,instrument(source));const kernel:typeof import('../bend2/bend.ts')=await import(temporary);
  const start=performance.now();const lowered=kernel.body_flatten(body,vars,()=>{observer.fresh();return fresh++;});const instrumentedLoweringMs=performance.now()-start;
  const allocation=observer.nodes.analyze(lowered);
  const expected=kind==='diagnostic'?{objects:578315,Sub:212753,Lam:142729,Mat:20786,fresh:10279,calls:161440}:{objects:504756,Sub:250947,Lam:64377,Mat:20706,fresh:10210,calls:undefined};
  if(allocation.graphObjects!==expected.objects||allocation.nodeKinds.Sub!==expected.Sub||allocation.nodeKinds.Lam!==expected.Lam||allocation.nodeKinds.Mat!==expected.Mat||fresh-initialFresh!==expected.fresh||(expected.calls!==undefined&&observer.calls.length!==expected.calls))throw Error('Instrumentation changed the frozen baseline graph');
  for(const ownership of allocation.perOwner){const call=observer.calls[Math.floor(ownership.owner/3)];add(call.own,ownership);if(ownership.owner%3===1)add(call.preparedConstructor,ownership);}
  for(const call of observer.calls){add(call.inclusive,call.own);add(call.constructorAllocation,call.preparedConstructor);for(const[index,group]of call.keys.entries()){group.ownObjects+=total(call.own);if(call.duplicate[index])group.duplicateOwnObjects+=total(call.own);}}
  for(let index=observer.calls.length-1;index>=0;index--){const call=observer.calls[index];if(call.parent<0)continue;const parent=observer.calls[call.parent];add(parent.inclusive,call.inclusive);if(call.edge==='constructor')add(parent.constructorAllocation,call.inclusive);else if(call.edge==='default')add(parent.defaultAllocation,call.inclusive);}
  const shapes=aggregate(observer.calls);
  const splitCalls=observer.calls.filter(c=>c.action==='constructor-split');
  const splitRecords=splitCalls.map(c=>({id:c.id,parent:c.parent,depth:c.depth,rows:c.rows,columns:c.columns,constructor:c.constructor,ps:c.ps,ds:c.ds,wildcardRows:c.wildcardRows,removedConstructors:c.removedConstructors,fresh:c.fresh,bodySubCalls:c.bodySubCalls,ownFinalObjects:c.own,constructorPreparation:c.preparedConstructor,constructorSideFinalAllocations:c.constructorAllocation,defaultSideFinalAllocations:c.defaultAllocation,inclusiveOutputEdgeWeights:c.output}));
  const distinctAbsoluteByAlpha=new Map<number,Set<number>>();
  for(const call of observer.calls){let keys=distinctAbsoluteByAlpha.get(call.keys[1].id);if(!keys){keys=new Set();distinctAbsoluteByAlpha.set(call.keys[1].id,keys);}keys.add(call.keys[3].id);}
  const states=observer.states.map((map,index)=>({key:['K1','K2','K3','absoluteStructural'][index],unique:map.size,repeats:observer.calls.length-map.size,callsCoveredByRepeatedGroups:[...map.values()].filter(g=>g.calls>1).reduce((n,g)=>n+g.calls,0),ownedFinalObjectsInRepeatedGroups:[...map.values()].filter(g=>g.calls>1).reduce((n,g)=>n+g.ownObjects,0),duplicateCallsOwnedFinalObjects:[...map.values()].reduce((n,g)=>n+g.duplicateOwnObjects,0),duplicateCallsOwnedFinalObjectPercent:100*[...map.values()].reduce((n,g)=>n+g.duplicateOwnObjects,0)/allocation.graphObjects,topGroups:[...map.values()].filter(g=>g.calls>1).sort((a,b)=>b.duplicateOwnObjects-a.duplicateOwnObjects).slice(0,20)}));
  const absoluteIdMisses={alphaGroupsWithMultipleAbsoluteKeys:[...distinctAbsoluteByAlpha.values()].filter(keys=>keys.size>1).length,distinctAbsoluteKeysCollapsedByAlpha:observer.states[3].size-observer.states[1].size,definition:'kAbsolute and K2 have identical structural/body/name projection; only numeric binder ID renumbering differs. K1 versus kAbsolute additionally changes Body identity and vars projection.'};
  const result={kind,scope:'MEASUREMENT_ONLY_BASELINE_NO_COMPILER_CHANGE',baselineKernelSha256:BASELINE_SHA,fixtureSha256:createHash('sha256').update(fixture).digest('hex'),matchFlattenCalls:observer.calls.length,freshBinders:fresh-initialFresh,instrumentedLoweringMs,allocation,lamSites:observer.lamSiteCounts,states,absoluteIdMisses,maximumDepth:Math.max(...shapes.map(s=>s.depth)),shapeDepth:shapes,constructorDefaultSplits:splitRecords,summary:{constructorSplits:splitCalls.length,wildcardDuplicationMemberships:splitCalls.reduce((n,c)=>n+c.wildcardRows,0),bodySubCalls:observer.calls.reduce((n,c)=>n+c.bodySubCalls,0),bodySubRootCalls:observer.calls.reduce((n,c)=>n+c.bodySubRootCalls,0),wildcardOrderMemberships:splitCalls.flatMap(c=>c.wild).reduce((counts,row)=>{counts[row.order]++;return counts;},{before:0,between:0,after:0})},nodeReuseEstimateDefinition:'Duplicate-call owned final graph objects are a non-overlapping optimistic allocation-reuse ceiling, NOT proof of safely reusable outputs; source objects excluded. Per-split branch allocations overlap ancestor splits and are not additive.',note:'Inclusive output/subtree weights overlap across ancestors and shared edges; unique graph counts and selected-wildcard-body union must be used for final percentages.'};
  await Bun.write(`checkpoints/stage0-match-attribution-${kind}.json`,JSON.stringify(result,null,2)+'\n');
  console.log(JSON.stringify({kind,calls:result.matchFlattenCalls,objects:allocation.graphObjects,freshBinders:result.freshBinders,states,summary:result.summary,wildcardBodyUnion:allocation.wildcards.selectedBody.union,lamEmissions:allocation.lamEmissions}));
} finally {await unlink(temporary);delete registry.__stage0_allocation;}
