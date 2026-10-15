/** Finite conservative progress evidence for the generated Request/Kont machine.
 * Source calls and driver ticks are deliberately different graphs. A suffix
 * fact relative to a function's entry is not a fact about a resumed machine's
 * current cursor; those edges stay Unknown until a stack invariant proves it.
 */
import type { ParserGraph } from "./parser_full_graph.ts";
import type { Body, LTerm } from "../bend2/bend.ts";
import { termChildren } from "./parser_full_type_env.ts";
import type { CursorRelation, CursorInput, CursorResult, CursorPush, TokenProvenanceAnalysis } from "./parser_full_token_provenance.ts";

type ProvenanceTransition = TokenProvenanceAnalysis["transitions"][number];
export type LoweredCall = { caller: string; callee: string; offset: number; kind: string; machineSource?: string };
export type ProgressFrame={name:string;owner:string;pushOffset:number;fields:readonly {name:string;binderId?:number}[]};
export type PushAncestry={outerFrame:string;innerFrame?:string;pushOffset:number;nestedPushOffset?:number;nestedPushRelation?:CursorRelation;nestedCompletionRelation?:CursorRelation;nestedResultGuards?:CursorResult["guards"];capturedBinderId:number;capturedPath:number[];childInput:CursorInput;pushRelation:CursorRelation;executionRelation:CursorRelation;completionRelation:CursorRelation;resultPath:number[];guards:CursorResult["guards"];witness:string[]};
function compose(a:CursorRelation,b:CursorRelation):CursorRelation{
 if(a==="Unknown"||b==="Unknown")return"Unknown";
 if(a==="Same")return b;if(b==="Same")return a;
 return a==="StrictSuffix"||b==="StrictSuffix"?"StrictSuffix":"Suffix";
}
type UnknownReason = {
  component: string;
  category: "cross-stack ancestry loss" | "constructor-field relation loss" | "opaque callee result" | "genuinely unrelated cursors" | "other";
  reason: string;
};
function unknownReason(component: string, reason: string, category: UnknownReason["category"] = "other"): UnknownReason {
  return { component, category, reason };
}
function completionUnknown(component: string, result: CursorResult, root: string): UnknownReason {
  if (!Object.keys(result.relations).length) return unknownReason(component,
    "No cursor-bearing provenance is represented for this result alternative: " + result.reason, "opaque callee result");
  return unknownReason(component,
    root === "Unknown" ? "The completion input root is Unknown: " + result.reason
      : !(root in result.relations) ? "The result alternative has no matching ancestry root " + root + ": " + result.reason
      : "The result relation to matching ancestry root " + root + " is Unknown: " + result.reason,
    "cross-stack ancestry loss");
}
export type ProgressEdge = ProvenanceTransition & {
  from: string; to: string; classification: "consuming" | "admin" | "unknown";
  driverTicks: number; semantics: string;
  sourceCallRelation?: ProvenanceTransition["relation"];
  sourceCallEvidence?: ProvenanceTransition;
  pushAncestry?:PushAncestry;
  unknownReasons?: UnknownReason[];
};
type Cycle = { nodes: string[]; edges: ProgressEdge[]; evidenceType: "A" | "B" };
type GraphInspection = { nodes: string[]; edgeCount: number; cyclicSCCs: string[][];
  cycle: Cycle | null; height: number | null; ranks: Record<string, number> | null };

function classify(relation: ProvenanceTransition["relation"]): ProgressEdge["classification"] {
  return relation === "StrictSuffix" ? "consuming" : relation === "Unknown" ? "unknown" : "admin";
}
function compareEdge(a: ProgressEdge, b: ProgressEdge): number {
  return a.from.localeCompare(b.from) || a.to.localeCompare(b.to) || a.offset - b.offset || a.semantics.localeCompare(b.semantics);
}
function inspect(nodes: string[], edges: ProgressEdge[]): GraphInspection {
  const adjacency = new Map(nodes.map(node => [node, [] as ProgressEdge[]]));
  for (const edge of [...edges].sort(compareEdge)) adjacency.get(edge.from)!.push(edge);
  let next = 0;
  const indices = new Map<string, number>(), low = new Map<string, number>();
  const stack: string[] = [], active = new Set<string>(), components: string[][] = [];
  function visit(node: string): void {
    indices.set(node, next); low.set(node, next++); stack.push(node); active.add(node);
    for (const edge of adjacency.get(node)!) {
      if (!indices.has(edge.to)) { visit(edge.to); low.set(node, Math.min(low.get(node)!, low.get(edge.to)!)); }
      else if (active.has(edge.to)) low.set(node, Math.min(low.get(node)!, indices.get(edge.to)!));
    }
    if (low.get(node) !== indices.get(node)) return;
    const component: string[] = [];
    let member: string;
    do { member = stack.pop()!; active.delete(member); component.push(member); } while (member !== node);
    component.sort();
    if (component.length > 1 || adjacency.get(node)!.some(edge => edge.to === node)) components.push(component);
  }
  for (const node of nodes) if (!indices.has(node)) visit(node);
  components.sort((a, b) => a.length - b.length || a.join("\0").localeCompare(b.join("\0")));
  // BFS from every vertex finds a globally shortest directed cycle, not the
  // first DFS backedge. Sorted starts/edges make equal-length evidence stable.
  let cycle: Cycle | null = null;
  const cyclicNodes = new Set(components.flat());
  for (const start of nodes.filter(node => cyclicNodes.has(node))) {
    const queue = [start], previous = new Map<string, ProgressEdge>(), seen = new Set([start]);
    let closing: ProgressEdge | undefined;
    for (let cursor = 0; cursor < queue.length && !closing; cursor++) {
      for (const edge of adjacency.get(queue[cursor]!)!) {
        if (edge.to === start) { closing = edge; break; }
        if (!seen.has(edge.to)) { seen.add(edge.to); previous.set(edge.to, edge); queue.push(edge.to); }
      }
    }
    if (!closing) continue;
    const path = [closing];
    for (let node = closing.from; node !== start;) { const edge = previous.get(node)!; path.push(edge); node = edge.from; }
    path.reverse();
    if (!cycle || path.length < cycle.edges.length) cycle = { nodes: [start, ...path.map(edge => edge.to)], edges: path,
      evidenceType: path.every(edge => edge.relation === "Same") ? "B" : "A" };
  }
  if (cycle) return { nodes, edgeCount: edges.length, cyclicSCCs: components, cycle, height: null, ranks: null };
  const ranks = new Map<string, number>();
  function rank(node: string): number {
    if (ranks.has(node)) return ranks.get(node)!;
    const value = Math.max(0, ...adjacency.get(node)!.map(edge => 1 + rank(edge.to)));
    ranks.set(node, value); return value;
  }
  for (const node of nodes) rank(node);
  return { nodes, edgeCount: edges.length, cyclicSCCs: [], cycle: null,
    height: Math.max(0, ...ranks.values()), ranks: Object.fromEntries(nodes.map(node => [node, ranks.get(node)!])) };
}

/** Unknown is retained in the uncertified graph; Suffix is not strict descent. */
export function inspectProgressGraph(inputNodes: Iterable<string>, edges: ProgressEdge[]) {
  const nodes = [...new Set([...inputNodes, ...edges.flatMap(edge => [edge.from, edge.to])])].sort();
  return { uncertified: inspect(nodes, edges.filter(edge => edge.classification !== "consuming")),
    knownNonconsuming: inspect(nodes, edges.filter(edge => edge.classification === "admin")) };
}
function counts(edges: ProgressEdge[]) {
  return { nodes: new Set(edges.flatMap(edge => [edge.from, edge.to])).size, transitions: edges.length,
    consuming: edges.filter(edge => edge.classification === "consuming").length,
    admin: edges.filter(edge => edge.classification === "admin").length,
    unknown: edges.filter(edge => edge.classification === "unknown").length,
    driverTickEdges: edges.filter(edge => edge.driverTicks > 0).length };
}

export function buildProgressCertificate(graph: ParserGraph, analysis: TokenProvenanceAnalysis, options: {
  lifted: ReadonlySet<string>; selected: ReadonlySet<string>; classifications: LoweredCall[]; frames: readonly ProgressFrame[];
}) {
  const { lifted, selected, classifications, frames } = options;
  const indexed = new Map(analysis.transitions.map(site => [`${site.caller}\0${site.callee}\0${site.offset}`, site]));
  function provenance(site: LoweredCall): ProvenanceTransition {
    const found = indexed.get(`${site.caller}\0${site.callee}\0${site.offset}`);
    if (found) return found;
    return { caller: site.caller, callee: site.callee, offset: site.offset,
      line: graph.source.slice(0, site.offset).split("\n").length,
      sourceCursor: "Unknown", destinationCursor: "Unknown", relation: "Unknown",
      sourceProvenance: {}, destinationProvenance: {}, sourceConstruct: graph.source.slice(site.offset).split("\n", 1)[0]!,
      reason: "No stabilized real-AST provenance transition matches this lowered callsite" };
  }
  const sourceEdges: ProgressEdge[] = classifications.map(site => {
    const evidence = provenance(site);
    return { ...evidence, from: site.caller, to: site.callee, classification: classify(evidence.relation),
      driverTicks: 0, semantics: "Source call proxy only; not a driver transition",
      unknownReasons: evidence.relation === "Unknown" ? [unknownReason("relation", evidence.reason)] : [] };
  });
  const machineEdges: ProgressEdge[] = [];
  function add(evidence: ProvenanceTransition, from: string, to: string, semantics: string, ticks = 0,
      relation = evidence.relation, reason = evidence.reason): void {
    machineEdges.push({ ...evidence, from, to, semantics, driverTicks: ticks, relation, reason,
      sourceCallRelation: evidence.relation,
      sourceCallEvidence: indexed.get(`${evidence.caller}\0${evidence.callee}\0${evidence.offset}`) ?? evidence,
      classification: classify(relation),
      unknownReasons: [
        ...(relation === "Unknown" ? [unknownReason("relation", reason,
          reason.startsWith("Owner-entry provenance cannot establish") ? "cross-stack ancestry loss" : "other")] : []),
        ...(evidence.relation === "Unknown" ? [unknownReason("sourceCallRelation", evidence.reason)] : [])
      ] });
  }
  for (const site of classifications) {
    const evidence = provenance(site), resumed = site.machineSource !== undefined;
    add(evidence, resumed ? "Kont:" + site.machineSource! : "Control:" + site.caller, (selected.has(site.callee) ? "Request:" : "Control:") + site.callee,
      selected.has(site.callee) ? "Control constructs FeedbackCall; dispatch is a separate driver tick" : "Direct Control helper evaluation; no driver tick",
      0, resumed ? "Unknown" : evidence.relation,
      resumed ? "Owner-entry provenance cannot establish the cursor relation after Kont resume: " + evidence.reason : evidence.reason);
  }
  for (const name of selected) {
    const site = sourceEdges.find(edge => edge.callee === name);
    const evidence: ProvenanceTransition = site ?? { caller: name, callee: name, offset: -1, line: 0,
      sourceCursor: name + ":request-payload", destinationCursor: name + ":request-payload",
      sourceProvenance: {}, destinationProvenance: {}, relation: "Same", sourceConstruct: "FeedbackCall{Request_" + name + "{...}}",
      reason: "Request dispatch forwards the same payload to step_" + name };
    const payload = { ...evidence, sourceCursor: evidence.destinationCursor,
      sourceProvenance: evidence.destinationProvenance };
    add(payload, "Request:" + name, "Control:" + name, "feedback_drive FeedbackCall -> feedback_dispatch -> step_" + name,
      1, "Same", "Request dispatch forwards the identical flattened payload; no token consumption");
  }
  const returnEvidence: Array<{ frame: string; source: string }> = [];
  const pushes=frames.map(frame=>{
   const site=classifications.find(call=>call.kind==="non-tail"&&call.caller===frame.owner&&call.offset===frame.pushOffset);
   if(!site)throw Error("No source attachment for continuation "+frame.name);
   const captures=frame.fields.flatMap(f=>f.binderId===undefined?[]:[f.binderId]);
   let cursors=analysis.cursorPushes(site.caller,site.offset,captures);
   if(!cursors.length)cursors=analysis.cursorPushes(site.caller,site.offset,analysis.cursorInputs(site.caller).map(c=>c.binderId));
   if(!cursors.length)cursors=[{captureBinderId:-1,capturePath:[],captureRoot:"Unknown",child:analysis.cursorInputs(site.callee)[0]??{input:-1,binderId:-1,path:[],root:"Unknown"},relation:"Unknown",guards:[]}];
   return{frame,site,evidence:provenance(site),cursors};
  });
  function controlled(t:LTerm):boolean{return t.$==="Ref"&&lifted.has(t.k)||termChildren(t).some(controlled);}
  function terminal(b:Body):boolean{return b.$==="Local"?terminal(b.f):b.$==="Match"?b.r.some(r=>terminal(r.f)):!controlled(b);}
  const canComplete=new Map([...lifted].map(name=>[name,terminal(graph.bodies.get(name)!)]));
  const tailCalls=classifications.filter(c=>c.kind!=="non-tail"&&c.machineSource===undefined);
  const pairEvidence:Array<{outer:string;inner:string;relation:CursorRelation;witness:string[]}>=[];
  for(const outer of pushes)for(const cursor of outer.cursors){
   type State={name:string;input:CursorInput;relation:CursorRelation;witness:string[];unknownReason?:string};
   const pending:State[]=[{name:outer.site.callee,input:cursor.child,relation:"Same",witness:[outer.site.caller,outer.site.callee]}],seen=new Set<string>();
   function pop(state:State,inner?:typeof pushes[number],nested?:CursorPush):void{
    const nestedResults=inner&&nested?analysis.cursorResults(inner.site.callee,nested.child):[undefined];
    for(const result of analysis.cursorResults(state.name,state.input))for(const nestedResult of nestedResults){
     const nestedCompletion=nestedResult&&nested?(nestedResult.relations[nested.child.root]??"Unknown"):undefined;
     const completion=result.relations[state.input.root]??"Unknown";
     const unresolved=nested?.relation==="Unknown"||nestedCompletion==="Unknown";
     const composed=unresolved?"Unknown":compose(cursor.relation,compose(state.relation,completion));
     add({...outer.evidence,sourceCursor:outer.frame.name+":captured-binder#"+cursor.captureBinderId,
       destinationCursor:state.name+":result["+result.path+"]"},
       inner?"Kont:"+inner.frame.name:"Control:"+state.name,"Kont:"+outer.frame.name,
       inner?"Matching nested resume completion pops its immediate suspended ancestor":"Matching child completion pops its suspended ancestor",
       1,composed,nestedCompletion==="Unknown"?nestedResult!.reason:completion==="Unknown"?result.reason:unresolved?"Nested push cursor ancestry is Unknown":"Push, balanced execution and branch-specific completion compose in the existing cursor lattice");
     machineEdges.at(-1)!.pushAncestry={outerFrame:outer.frame.name,innerFrame:inner?.frame.name,
       pushOffset:outer.site.offset,nestedPushOffset:inner?.site.offset,nestedPushRelation:nested?.relation,
       nestedCompletionRelation:nestedCompletion,nestedResultGuards:nestedResult?.guards,
       capturedBinderId:cursor.captureBinderId,capturedPath:cursor.capturePath,childInput:cursor.child,
       pushRelation:cursor.relation,executionRelation:state.relation,completionRelation:completion,
       resultPath:result.path,guards:result.guards,witness:state.witness};
     const edge=machineEdges.at(-1)!;
     const components:UnknownReason[]=[];
     if(cursor.relation==="Unknown")components.push(unknownReason("push",
       cursor.unknownReason?.reason??"No known relation connects captured root "+cursor.captureRoot+" to child input root "+cursor.child.root,
       cursor.unknownReason?.category??"cross-stack ancestry loss"));
     if(state.relation==="Unknown")components.push(unknownReason("execution",
       state.unknownReason??"Balanced execution has an Unknown ancestry relation", "cross-stack ancestry loss"));
     if(nested?.relation==="Unknown")components.push(unknownReason("nested push",
       nested.unknownReason?.reason??"No known relation connects nested captured root "+nested.captureRoot+" to child input root "+nested.child.root,
       nested.unknownReason?.category??"cross-stack ancestry loss"));
     if(nestedCompletion==="Unknown")components.push(completionUnknown("nested completion",nestedResult!,nested!.child.root));
     if(completion==="Unknown")components.push(completionUnknown("completion",result,state.input.root));
     edge.unknownReasons=[...(edge.unknownReasons??[]).filter(r=>r.component!=="relation"),...components];
     returnEvidence.push({frame:outer.frame.name,source:inner?.frame.name??state.name});
    }
   }
   for(let i=0;i<pending.length;i++){
    const state=pending[i]!,id=state.name+"\0"+state.input.root+"\0"+JSON.stringify(state.input.constructorFields??null)+"\0"+state.relation;
    if(seen.has(id))continue;seen.add(id);
    if(canComplete.get(state.name))pop(state);
    const calls=tailCalls.filter(c=>c.caller===state.name);
    for(const inner of pushes.filter(p=>p.site.caller===state.name)){
     const candidates=state.input.constructorFields?analysis.cursorPushes(inner.site.caller,inner.site.offset,[...new Set(inner.cursors.map(p=>p.captureBinderId))],state.input):inner.cursors;
     const compatible=candidates.filter(p=>state.input.root==="Unknown"||p.captureRoot===state.input.root||p.captureRoot==="Unknown");
     for(const nested of compatible){
      const ancestry=compose(state.relation,nested.relation);
      pairEvidence.push({outer:outer.frame.name,inner:inner.frame.name,relation:ancestry,witness:state.witness});
      // Owner result summaries include capture restoration on resume. Never
      // assume a continuation preserves its child's result cursor.
      pop(state,inner,nested);
     }
     // After the matching inner pop its resume executes with this same outer
     // frame beneath it; do not descend into the inner child with outer on top.
     calls.push(...classifications.filter(c=>c.machineSource===inner.frame.name));
    }
    for(const call of calls){
     const continuations=analysis.cursorPushes(state.name,call.offset,[state.input.binderId],state.input).filter(p=>p.capturePath.join(".")===state.input.path.join("."));
     if(!continuations.length)for(const child of analysis.cursorInputs(call.callee))pending.push({name:call.callee,input:child,relation:"Unknown",witness:[...state.witness,call.callee],
       unknownReason:"No matching captured field-path ancestry connects execution to "+call.callee+" at offset "+call.offset});
     for(const next of continuations)pending.push({name:call.callee,input:next.child,relation:compose(state.relation,next.relation),witness:[...state.witness,call.callee],
       unknownReason:state.relation==="Unknown"?state.unknownReason:next.relation==="Unknown"?"Execution push has an Unknown relation between captured root "+next.captureRoot+" and child root "+next.child.root:undefined});
    }
   }
  }
  const machineNodes = [...[...lifted].map(name => "Control:" + name), ...[...selected].map(name => "Request:" + name), ...frames.map(frame => "Kont:" + frame.name)];
  const machine = inspectProgressGraph(machineNodes, machineEdges);
  const sourceProxy = inspectProgressGraph(lifted, sourceEdges);
  const complete = inspect([...machineNodes].sort(), machineEdges);
  const height = machine.uncertified.height;
  const certified = height !== null;
  return { schemaVersion: 3, analysisIterations: analysis.iterations,
    status: certified ? "certified-administrative-dag" : "remaining-cycle",
    certified, counts: counts(machineEdges), sourceCounts: counts(sourceEdges),
    machine: { nodes: machineNodes.sort(), edges: machineEdges, complete, ...machine },
    sourceProxy: { edges: sourceEdges, ...sourceProxy },
    smallestRemainingCycle: machine.uncertified.cycle,
    sourceSmallestRemainingCycle: sourceProxy.uncertified.cycle,
    returnReachability: returnEvidence,
    stackAncestry:pairEvidence,
    framePushes:pushes.map(p=>({frame:p.frame.name,caller:p.site.caller,callee:p.site.callee,offset:p.site.offset,cursors:p.cursors})),
    proposedRefinement:{name:"Constructor-field relational provenance",implemented:true},
    priorRefinement:{name:"Cross-stack active-cursor invariant",implemented:true},
    bound: { H: height, transitionFactor: certified ? height! + 1 : null,
      expression: certified ? "(N + 1) * (H + 1)" : null,
      N: "Sum of token-list input lengths (the generator may conservatively include String lengths)",
      justification: certified ? "The nonconsuming/Unknown machine graph is a DAG of height H; compatible push/pop cursor ancestry segments execution into at most N + 1 token phases, each using at most H + 1 driver cells."
        : "No driver fuel bound claimed: a remaining machine cycle prevents certification.",
      globalCursorContinuity: "Bounded immediate-frame ancestry; branch-specific completion and capture restoration are composed relative to the suspended cursor" },
    model: { sourceCallsAreDriverTransitions: false,
      directControlTicks: 0, requestDispatchTicks: 1, kontResumeTicks: 1, terminalCompletionTicks: 1,
      returnEdges: "Only balanced child execution and immediate matching-pop ancestry; no arbitrary Kont pairing",
      scope: "Finite constructor-variant token-field matrices, preserved across calls and matches, compose with binder-ID matching-stack cursor evidence" } };
}
