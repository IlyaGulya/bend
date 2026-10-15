#!/usr/bin/env bun
import * as B from '../bend2/bend.ts';
import {createHash,randomUUID} from 'node:crypto';
import {resolve} from 'node:path';
import {unlink} from 'node:fs/promises';
import {writeFileSync} from 'node:fs';
import {guardHeavyGate} from './heavy_gate.ts';
import {readParserGraph} from './parser_full_graph.ts';
import {semanticCases} from './parser_full_match_factor_fixtures.ts';
import {Observation} from './stage0_trailing_suffix_sharing.ts';
const fixed={
  'bend2/selfhost/parser.bend':'f425995af41087dfa51f79e7b04259ea5d1acfa9906061c7ed57199bad4e18df',
  'bend2/selfhost/parser_full_generated_fuel.bend':'b66ca5fe16b41d65feb51afd95b3954550396b60e542c21a93fe042b7fa9d51e',
  'evals/parser_full_generate.ts':'0aedb4c1703cffe1055794b29829a357edcd956fdc0a8dec77bfa3c0cf7a6da6',
};
const sha=(text:string)=>createHash('sha256').update(text).digest('hex');
async function frozen(){for(const[path,expected]of Object.entries(fixed))if(sha(await Bun.file(path).text())!==expected)throw Error('Frozen semantic input drift: '+path);}
const kind=process.argv[2],mode=process.argv[3]??'production';
if(!['diagnostic','wide-matrix','twenty-row'].includes(kind)||!['historical','production'].includes(mode)||(kind==='twenty-row'&&mode!=='production'))throw Error('Only allowed scaling stages');
await guardHeavyGate(import.meta.path,{label:`production-pure-tail-${kind}-${mode}`});
await frozen();
if(mode==='production'&&sha(await Bun.file('bend2/bend.ts').text())!=='1f2c3fbbadfb489c401b735791716779a75dc2594a5b7c1e82571418ea51f403')throw Error('Rejected production port is not installed; preserved evidence is bound to checkpoints/stage0-rejected-production-pure-tail-kernel.ts.txt');
const progressPath=`checkpoints/stage0-production-${kind}-${mode}.progress.json`;
function progress(phase:string,extra:object={}){writeFileSync(progressPath,JSON.stringify({phase,kind,mode,...extra})+'\n');}
progress('raw-graph-load');
let temporary:string|undefined;
try {
  let kernel:typeof B=B;
  if(mode==='historical'){
    const source=await Bun.file('checkpoints/stage0-pre-pure-tail-kernel.ts.txt').text();
    if(sha(source)!=='47e1b06e2fa4466bad702f86d8cbce03f40e833a8ba8eaa1e04297fa46dc94a9')throw Error('Historical snapshot drift');
    temporary=resolve('bend2/.pre-pure-tail-'+randomUUID()+'.ts');await Bun.write(temporary,source);kernel=await import(temporary);
  }
  const source=kind==='diagnostic'?await Bun.file('evals/stage0_match_diagnostic.bend').text():kind==='wide-matrix'?semanticCases.find(f=>f.name==='wide-matrix')!.source:await Bun.file('bend2/selfhost/parser.bend').text();
  const name=kind==='wide-matrix'?'matrix':'pattern_scan';
  const graph=await readParserGraph(source),body=graph.bodies.get(name),sig=graph.signatures.get(name);
  progress('raw-graph-loaded');
  if(!body||!sig||body.$!=='Match')throw Error('Missing raw matrix');
  if(kind==='twenty-row'&&body.r.length!==20)throw Error('Full canonical diagnostic is not twenty rows');
  const vars:B.PVar[]=sig.parameters.map(([q,k,i,,s])=>({$:'PVar',q,k,i,s}));
  let next=0;
  function reserve(x:unknown){if(!x||typeof x!=='object')return;for(const[k,v]of Object.entries(x)){if(k==='s')continue;if(k==='i'&&typeof v==='number')next=Math.max(next,v+1);else reserve(v);}}
  reserve(body);for(const p of vars)next=Math.max(next,p.i+1);const initial=next;
  const fresh=()=>{const i=next++;if(kind==='twenty-row'&&(next-initial)%4096===0)progress('lowering',{freshBinders:next-initial,elapsedMs:performance.now()-started});return i;};
  progress('lowering',{freshBinders:0});
  const started=performance.now();
  const goal=B.term_higher(B.tele_bind(sig.parameters,sig.result));
  const flatten:(b:B.Body,vars:B.PVar[],fr:()=>number,context?:{book:B.Book;goal:B.HTerm})=>B.LTerm=kernel.body_flatten;
  const term=mode==='historical'?flatten(body,vars,fresh):flatten(body,vars,fresh,{book:graph.parserBook,goal});
  const loweringMs=performance.now()-started;
  progress('counting',{freshBinders:next-initial,loweringMs});
  const observation=new Observation(true);observation.visit(term);
  const counts=observation.counts(observation.descendants(term)),kinds={Sub:0,Lam:0,Let:0,App:0,Mat:0};
  for(const n of observation.termNodes){const t=n as B.LTerm;if(t.$==='Sub'||t.$==='Lam'||t.$==='Let'||t.$==='App'||t.$==='Mat')kinds[t.$]++;}
  if(observation.observedCallbacks.size)throw Error('Lower result includes unexpected HOAS');
  if(mode==='historical'){
    const expected=kind==='diagnostic'?{objects:578315,Sub:212753,Lam:142729,Mat:20786,fresh:10279}:{objects:504756,Sub:250947,Lam:64377,Mat:20706,fresh:10210};
    if(counts.graphObjects!==expected.objects||kinds.Sub!==expected.Sub||kinds.Lam!==expected.Lam||kinds.Mat!==expected.Mat||next-initial!==expected.fresh)throw Error('Historical baseline count drift');
  }
  await frozen();
  const result={kind,mode,matrixRows:body.r.length,productionKernelSha256:sha(await Bun.file('bend2/bend.ts').text()),historicalKernelSha256:'47e1b06e2fa4466bad702f86d8cbce03f40e833a8ba8eaa1e04297fa46dc94a9',frozenInputs:fixed,
    loweredUniqueObjects:counts.graphObjects,termNodes:counts.termNodes,...kinds,freshBinders:next-initial,loweringMs,
    typedContext:mode==='production'?'Definition telescope from frozen raw signature and parserBook':'NONE_HISTORICAL',
    scope:'PRODUCTION_FUNCTIONS_FULL_MATRIX_NO_BINDER_LIMIT',selfhostGreen:false};
  await Bun.write(`checkpoints/stage0-production-${kind}-${mode}.json`,JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify(result));
  progress('complete',{freshBinders:next-initial,loweringMs,loweredUniqueObjects:counts.graphObjects});
}catch(error){const err=error as B.Err;if(err?.$==='Err')console.error(B.err_show(err));else console.error(error);throw Error('Production measurement failed');}
finally{if(temporary)await unlink(temporary);}
