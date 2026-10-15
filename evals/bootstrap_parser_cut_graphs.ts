import {readParserGraph} from './parser_full_graph.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {createHash} from 'node:crypto';
import {writeFileSync} from 'node:fs';
await guardHeavyGate(import.meta.path,{label:'Current feedback cut native source-AST graph provenance'});
const canonicalPath='bend2/selfhost/parser.bend',factoredPath='bend2/selfhost/.bootstrap_parser_rebuild_c90c06a262b3af6d-grammar-shapes_source.bend';
const canonical=await Bun.file(canonicalPath).text(),factored=await Bun.file(factoredPath).text();
const sha=(source:string)=>createHash('sha256').update(source).digest('hex');
const old=await Bun.file('checkpoints/bootstrap-parser-rebuild-c90c06a262b3af6d-grammar-shapes.graph.json').json();
const normalized=(edges:Record<string,string[]>)=>JSON.stringify(Object.keys(edges).sort().map(name=>[name,[...edges[name]].sort()]));
for(const [kind,path,source] of [['canonical',canonicalPath,canonical],['factored',factoredPath,factored]] as const){
 const graph=await readParserGraph(source),sourceSha256=sha(source),output='checkpoints/bootstrap-parser-cut-'+kind+'-graph-'+sourceSha256.slice(0,16)+'.json';
 const facts={kind,path,sourceCheckpoint:sourceSha256.slice(0,8),sourceSha256,definitions:graph.definitions,edges:graph.edges,astReferences:graph.astReferences,unresolvedReferences:graph.unresolvedReferences};
 if(kind==='factored'&&(sourceSha256!==old.sourceSha256||normalized(graph.edges)!==normalized(old.edges)))throw Error('Factored saved graph differs from fresh native source AST');
 writeFileSync(output,JSON.stringify(facts,null,2)+'\n',{flag:'wx'});
 console.log(JSON.stringify({kind,output,sourceSha256,definitions:graph.definitions.length,unresolvedReferences:graph.unresolvedReferences}));
 Bun.gc(true);
}
