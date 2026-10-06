/** Termination inspection for explicit generated effects, never cursor provenance. */
import type {Progress} from './parser_full_explicit_progress.ts';
import type {ExplicitProgressProgram} from './parser_full_explicit_progress.ts';
import {explicitMachineTransitions,type ExplicitLowering} from './parser_full_explicit_machine.ts';
export type ExplicitTransition={
 from:string;to:string;progress:Progress;owner:string;offset:number;line:number;
 operation:string;driverTicks:number;
 consumptionOperations:readonly {owner:string;offset:number;binderId:number}[];
 propagation:'literal-NoProgress'|'explicit-composition';
};
export type ExplicitCycle={nodes:string[];edges:ExplicitTransition[]};
export function inspectExplicitProgressGraph(inputNodes:Iterable<string>,inputEdges:readonly ExplicitTransition[]){
 const nodes=[...new Set([...inputNodes,...inputEdges.flatMap(e=>[e.from,e.to])])].sort();
 const edges=[...inputEdges].sort((a,b)=>a.from.localeCompare(b.from)||a.to.localeCompare(b.to)||a.offset-b.offset||a.operation.localeCompare(b.operation));
 for(const edge of edges){
  if(edge.progress!=='NoProgress'&&edge.progress!=='Consumed')throw Error('Invalid explicit Progress on '+edge.operation);
  if(edge.progress==='Consumed'&&!edge.consumptionOperations.length)throw Error('Consumed transition has no emitted consuming operation: '+edge.operation);
 }
 const administrative=edges.filter(e=>e.progress==='NoProgress');
 const adjacency=new Map(nodes.map(n=>[n,[] as ExplicitTransition[]]));
 for(const edge of administrative)adjacency.get(edge.from)!.push(edge);
 const reverse=new Map(nodes.map(node=>[node,[] as string[]]));
 for(const edge of administrative)reverse.get(edge.to)!.push(edge.from);
 const seenNodes=new Set<string>(),postorder:string[]=[];
 for(const root of nodes){
  if(seenNodes.has(root))continue;
  seenNodes.add(root);const work=[{node:root,index:0}];
  while(work.length){
   const top=work[work.length-1]!,outgoing=adjacency.get(top.node)!;
   if(top.index<outgoing.length){const next=outgoing[top.index++]!.to;if(!seenNodes.has(next)){seenNodes.add(next);work.push({node:next,index:0});}}
   else{postorder.push(top.node);work.pop();}
  }
 }
 const assigned=new Set<string>(),sccs:string[][]=[];
 for(let index=postorder.length-1;index>=0;index--){
  const root=postorder[index]!;if(assigned.has(root))continue;
  const component:string[]=[],work=[root];assigned.add(root);
  while(work.length){const node=work.pop()!;component.push(node);for(const previous of reverse.get(node)!)if(!assigned.has(previous)){assigned.add(previous);work.push(previous);}}
  if(component.length>1||adjacency.get(root)!.some(edge=>edge.to===root))sccs.push(component.sort());
 }
 sccs.sort((a,b)=>a.length-b.length||a.join('\0').localeCompare(b.join('\0')));
 const cyclic=new Set(sccs.flat());let cycle:ExplicitCycle|null=null;
 for(const start of nodes.filter(n=>cyclic.has(n))){
  const queue=[start],seen=new Set([start]),previous=new Map<string,ExplicitTransition>();let closing:ExplicitTransition|undefined;
  for(let cursor=0;cursor<queue.length&&!closing;cursor++)for(const edge of adjacency.get(queue[cursor]!)!){
   if(edge.to===start){closing=edge;break;}
   if(!seen.has(edge.to)){seen.add(edge.to);previous.set(edge.to,edge);queue.push(edge.to);}
  }
  if(!closing)continue;
  const path=[closing];for(let node=closing.from;node!==start;){const edge=previous.get(node)!;path.push(edge);node=edge.from;}path.reverse();
  if(!cycle||path.length<cycle.edges.length)cycle={nodes:[start,...path.map(e=>e.to)],edges:path};
  if(cycle.edges.length===1)break;
 }
 const ranks=new Map<string,number>();
 if(!cycle)for(const node of postorder){
  let result=0;for(const edge of adjacency.get(node)!)result=Math.max(result,1+ranks.get(edge.to)!);
  ranks.set(node,result);
 }
 let H=0;for(const value of ranks.values())H=Math.max(H,value);
 return{schemaVersion:1,authority:'explicit-generated-Progress' as const,status:cycle?'remaining-NoProgress-cycle':'certified-NoProgress-dag',certified:!cycle,
  nodes,edges,administrativeEdges:administrative,cyclicSCCs:sccs,smallestRemainingCycle:cycle,
  counts:{nodes:nodes.length,transitions:edges.length,Consumed:edges.length-administrative.length,NoProgress:administrative.length,Unknown:0},
  bound:{H:cycle?null:H,transitionFactor:cycle?null:H+1,expression:cycle?null:'(N + 1) * (H + 1)'},administrativeRanks:cycle?null:Object.fromEntries(ranks)};
}

export async function buildExplicitProgressCertificate(program:ExplicitProgressProgram,lowering:ExplicitLowering){
 const machine=await explicitMachineTransitions(program,lowering);
 const inspection=inspectExplicitProgressGraph(machine.nodes,machine.edges);
 return{...inspection,configurations:machine.configurations,analysisIterations:machine.analysisIterations,invocations:machine.invocations,
  model:{semantics:machine.semantics,retrospectiveProvenanceAuthority:false,UnknownTerminationClass:false,
   proofBoundary:machine.proofBoundary,
   progressComposition:'NoProgress is identity; Consumed composes by logical OR',
   effectIRIsEmittedCode:true}};
}
