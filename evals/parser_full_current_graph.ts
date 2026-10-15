#!/usr/bin/env bun
/** Current canonical dependency facts only. Never selects/reselects feedback gateways. */
import {readParserGraph} from './parser_full_graph.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {createHash} from 'node:crypto';
import {readFileSync,writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
await guardHeavyGate(import.meta.path,{label:'parser-current-dependency-facts'});
if(process.argv.length!==2)throw Error('Usage: bun evals/parser_full_current_graph.ts [heavy-gate options]');
const input=resolve(import.meta.dir,'../bend2/selfhost/parser.bend');
const output=resolve(import.meta.dir,'../bend2/selfhost/parser_full_current_graph.json');
const source=readFileSync(input,'utf8'),sourceSha256=createHash('sha256').update(source).digest('hex');
const graph=await readParserGraph(source, input);
if(graph.unresolvedReferences.length)throw Error('Current canonical source has unresolved references');
const result={sourceCheckpoint:sourceSha256.slice(0,8),sourceSha256,graphBasis:'unchanged stage-0 source Body AST/raw HOAS Ref nodes',selectionPolicy:'Facts only; historical parser_full_cut.json selection and provenance are unchanged',definitions:graph.definitions,edges:graph.edges,unresolvedReferences:graph.unresolvedReferences};
writeFileSync(output,JSON.stringify(result,null,2)+'\n');
console.log(JSON.stringify({output,sourceSha256,definitions:graph.definitions.length,unresolvedReferences:graph.unresolvedReferences.length,selectionRun:false}));
