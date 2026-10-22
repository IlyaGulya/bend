import {createHash} from 'node:crypto';
import {writeFileSync} from 'node:fs';
import {mutualComponents} from './parser_full_graph.ts';
const options=new Map<string,string>();
for(const arg of process.argv.slice(2)){const at=arg.indexOf('='),key=arg.slice(0,at),value=arg.slice(at+1);if(at<0||!['--graph','--factored','--output'].includes(key)||!value||options.has(key))throw Error('Require unique --graph=PATH --factored=PATH --output=PATH');options.set(key,value);}
for(const key of ['--graph','--factored','--output'])if(!options.has(key))throw Error('Missing '+key);
const graphPath=options.get('--graph')!,factoredPath=options.get('--factored')!;
const historicalPath='bend2/selfhost/parser_full_cut.json';
const hash=(bytes:Uint8Array)=>createHash('sha256').update(bytes).digest('hex');
const bytes=async(path:string)=>new Uint8Array(await Bun.file(path).arrayBuffer());
const graph=await Bun.file(graphPath).json(),historical=await Bun.file(historicalPath).json();
const seeds=[...(historical.completeSelected??historical.selected)].sort() as string[];
const edges=graph.edges as Record<string,string[]>;
const canonicalText=await Bun.file('bend2/selfhost/parser.bend').text();
const sourceVertices=new Set([...canonicalText.matchAll(/^def ([A-Za-z_]\w*)\(/gm)].map(m=>m[1]!));
const lexicalCompare=(a:string,b:string)=>a<b?-1:a>b?1:0;
const scc=(removed:Set<string>)=>mutualComponents(edges,removed);
const fixed=new Set(seeds),residual=scc(fixed),candidates=[...new Set(residual.flat())].filter(v=>sourceVertices.has(v)).sort();
// Exact directed feedback vertex set for mutual recursion. Singleton self loops
// remain legal under the existing generator. Branch on every vertex of one
// proven nontrivial cycle; every feasible solution must hit that cycle.
function cycle(component:string[],removed:Set<string>):string[]{const allowed=new Set(component);for(const start of component){const path=[start],inPath=new Set(path);function search(v:string):string[]|null{for(const w of [...(edges[v]??[])].sort()){if(!allowed.has(w)||removed.has(w)||w===v)continue;if(w===start&&path.length>1)return [...path];if(inPath.has(w))continue;path.push(w);inPath.add(w);const found=search(w);if(found)return found;path.pop();inPath.delete(w);}return null;}const found=search(start);if(found)return found;}throw Error('Nontrivial SCC without cycle');}
let best=candidates.length+1;const solutions=new Map<string,string[]>(),seen=new Set<string>();
function solve(delta:string[]){const sorted=[...delta].sort(),key=sorted.join('\0');if(seen.has(key)||delta.length>best)return;seen.add(key);const removed=new Set([...seeds,...delta]),remaining=scc(removed);if(!remaining.length){if(delta.length<best){best=delta.length;solutions.clear();}solutions.set(key,sorted);return;}if(delta.length===best)return;for(const vertex of cycle(remaining[0],removed).filter(v=>sourceVertices.has(v)).sort())solve([...delta,vertex]);}
solve([]);
const minimumSolutions=[...solutions.values()].sort((a,b)=>lexicalCompare(a.join('\0'),b.join('\0'))),newlySelected=minimumSolutions[0];
if(!newlySelected)throw Error('No residual feedback solution');
const completeSelected=[...new Set([...seeds,...newlySelected])].sort();
const canonicalSha256=hash(await bytes('bend2/selfhost/parser.bend')),factoredSha256=hash(await bytes(factoredPath)),currentGraphSha256=hash(await bytes(graphPath));
const graphSourceSha256=hash(await bytes(graph.path??factoredPath));
if(graphSourceSha256!==graph.sourceSha256)throw Error('Graph source hash drift');
if(graphSourceSha256!==factoredSha256||graph.canonicalSha256!==canonicalSha256||
 !Array.isArray(graph.unresolvedReferences)||graph.unresolvedReferences.length||
 seeds.length!==14||new Set(seeds).size!==14||seeds.some(name=>!Object.hasOwn(edges,name)))
 throw Error('Current graph/source/history closure mismatch');
const payload={schemaVersion:1,sourceCheckpoint:factoredSha256.slice(0,8),sourceSha256:factoredSha256,canonicalSha256,factoredSha256,currentGraphSha256,graphPath,factoredPath,historicalPath,historicalCutSha256:hash(await bytes(historicalPath)),historicalSourceCheckpoint:historical.sourceCheckpoint,historicalSourceSha256:historical.sourceSha256,historicalSelected:seeds,selected:historical.selected,completeSelected,newlySelected,algorithm:'Exact cycle-hitting branch-and-bound directed feedback vertex set; fixed historical vertices removed; ignore singleton self recursion; exhaust all equal-cardinality minima',tieBreak:'Lexicographically smallest sorted function-name vector among all minimum-cardinality solutions',minimumCardinality:best,minimumSolutions,residualSCCs:residual,candidateAdditionalVertices:candidates,residualEdges:Object.fromEntries(candidates.map(v=>[v,(edges[v]??[]).filter(w=>candidates.includes(w)).sort()])),remainingMutualSCCs:scc(new Set(completeSelected)),statesExamined:seen.size,seedSemantics:'Remove fixed selected vertices from source dependency graph: calls to those source functions become feedback boundaries',unresolvedReferences:graph.unresolvedReferences};
const perComponent=residual.map(component=>{
 const projected=[...new Map(minimumSolutions.map(solution=>{const selected=solution.filter(v=>component.includes(v));return [selected.join('\0'),selected];})).values()];
 return {vertices:component,candidateSourceVertices:component.filter(v=>sourceVertices.has(v)),minimumCardinality:projected[0].length,minimumSolutions:projected,cycleWitness:cycle(component,fixed)};
});
Object.assign(payload,{selectionStatus:'PROPOSED_NOT_APPLIED',candidatePolicy:'Only original canonical source functions are selectable; factored helper vertices are graph facts, not cut candidates',perComponent,patternScanOnlyResidualSCCs:scc(new Set([...seeds,'pattern_scan']))});
Object.assign(payload,{graphKind:graph.kind??'factored',graphSourceSha256,residualEdges:Object.fromEntries(residual.flat().map(v=>[v,(edges[v]??[]).filter(w=>residual.flat().includes(w)).sort()]))});
const output=options.get('--output')!;
writeFileSync(output,JSON.stringify(payload,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({output,minimumCardinality:best,newlySelected,minimumSolutions,residualSCCs:residual,remainingMutualSCCs:payload.remainingMutualSCCs,statesExamined:seen.size},null,2));
