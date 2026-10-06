#!/usr/bin/env bun
import * as B from '../bend2/bend.ts';
import {readParserGraph} from './parser_full_graph.ts';
import {swapMatchSource} from './column_source_swap.ts';
import {checkFrozen} from './load_replay_kernel.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {resolve} from 'node:path';
import {writeFileSync,rmSync} from 'node:fs';
import {randomUUID,createHash} from 'node:crypto';
await guardHeavyGate(import.meta.path,{label:'Exact source-only column swap existing semantic fixtures'});
await checkFrozen();
const previous=await Bun.file('checkpoints/stage0-column-order-controls.json').json();
if(previous.status!=='PASS')throw Error('Prior fixture prerequisite missing');
const output:{fixture:string;covers:string[];audit:object;variants:object[];identical:boolean}[]=[];
for(const fixture of previous.semantic){
 if(createHash('sha256').update(fixture.source).digest('hex')!==fixture.sourceSha256)throw Error('Fixture source mismatch');
 const graph=await readParserGraph(fixture.source),body=graph.bodies.get('matrix');if(body?.$!=='Match')throw Error('Fixture matrix missing');
 const swapped=swapMatchSource(fixture.source,body),variants:{variant:string;status:string;phase:string;error?:string;values?:number[]}[]=[];
 for(const[variant,source]of [['historical',fixture.source],['source-only-swap',swapped.source]]){
  const path=resolve('bend2/selfhost',`.column_control_${randomUUID()}.bend`),book=B.book_nil();let phase='load';
  const probes=fixture.inputs.map((input:{args:string[]},i:number)=>`def probe${i}() -> Nat: matrix(${input.args.join(', ')})\n`).join('');
  try{writeFileSync(path,source+'\n'+probes);await B.book_load(book,path,'',new Map());phase='validation';B.book_valid(book);phase='evaluation';const values=fixture.inputs.map((_:unknown,i:number)=>{const n=B.nat_from_term(B.term_lower(B.term_snf(book,B.Ref('probe'+i))));if(n===null)throw Error('Non-Nat result');return n;});if(JSON.stringify(values)!==JSON.stringify(fixture.inputs.map((x:{expected:number})=>x.expected)))throw Error('Literal priority oracle mismatch');variants.push({variant,status:'PASS',phase,values});}
  catch(error){const text=error&&typeof error==='object'&&'$'in error&&error.$==='Err'?B.err_show(error as B.Err):String(error);variants.push({variant,status:'FAIL',phase,error:text});}
  finally{rmSync(path,{force:true});}
 }
 const identical=variants.every(v=>v.status==='PASS')&&JSON.stringify(variants[0].values)===JSON.stringify(variants[1].values);
 output.push({fixture:fixture.fixture,covers:fixture.covers,audit:swapped.audit,variants,identical});
}
await checkFrozen();const result={status:output.every(r=>r.identical)?'PASS':'SEMANTIC_GATE_FAILED',contract:'Exact source-only exchange; same signatures/calls/bodies; no aligned telescope permutation',fixtures:output};writeFileSync('checkpoints/pattern-scan-source-controls.json',JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify(result));if(result.status!=='PASS')process.exitCode=2;
