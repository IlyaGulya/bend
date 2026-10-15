#!/usr/bin/env bun
/** Observation-only instrumentation of a temporary module. No result caches. */
import {readParserGraph} from './parser_full_graph.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {resolve} from 'node:path';
import {randomUUID} from 'node:crypto';
import {unlink} from 'node:fs/promises';
import type {Match,PVar,Rows} from '../bend2/bend.ts';
await guardHeavyGate(import.meta.path,{label:'stage0-lowering-call-observation'});
// Historical A1 observation replays the archived experiment, not restored production.
const source=await Bun.file(resolve('checkpoints/stage0-a1-kernel.ts.txt')).text();
const graph=await readParserGraph(await Bun.file('evals/stage0_match_diagnostic.bend').text());
const body=graph.bodies.get('pattern_scan')!,signature=graph.signatures.get('pattern_scan')!;
const ids=new WeakMap<object,number>(),fingerprints=new WeakMap<object,string>(),states=new Map<string,number>();let next=0,calls=0,repeated=0,defaults=0,defaultRowMemberships=0,wildcardBranchDuplicationMemberships=0;
function id(x:object){let n=ids.get(x);if(n===undefined){n=next++;ids.set(x,n);}return n;}
function fingerprint(x:unknown):string{if(!x||typeof x!=='object')return JSON.stringify(x);const prior=fingerprints.get(x);if(prior!==undefined)return prior;const text=Array.isArray(x)?'['+x.map(fingerprint).join(',')+']':'{'+Object.entries(x).filter(([key])=>key!=='s').sort(([a],[b])=>a.localeCompare(b)).map(([key,v])=>JSON.stringify(key)+':'+fingerprint(v)).join(',')+'}';fingerprints.set(x,text);return text;}
const observer={enter(m:Match,vars:PVar[]){calls++;const key=m.e.map(fingerprint).join('|')+';'+m.r.map(row=>row.p.map(fingerprint).join('|')+'='+id(row.f)).join(';')+';'+vars.map(v=>v.i+':'+v.q.$).join(',');const prior=states.get(key)??0;if(prior)repeated++;states.set(key,prior+1);},fallback(rows:Rows){defaults++;defaultRowMemberships+=rows.length;wildcardBranchDuplicationMemberships+=rows.filter(row=>row.p[0].$==='PVar').length;}};
const hook='export function match_flatten(m: Match, vars: PVar[], fr: () => number): LTerm {';
const fallback='const dt = match_flatten({ $: "Match", e: m.e, r: ds, s: m.s }, vars, fr);';
if(!source.includes(hook)||!source.includes(fallback))throw Error('Observer anchors changed');
const access='(globalThis as typeof globalThis & {__stage0_observer: {enter(m: Match, vars: PVar[]): void; fallback(rows: Rows): void}}).__stage0_observer';
let instrumented=source.replace(hook,hook+'\n  '+access+'.enter(m, vars);').replace(fallback,access+'.fallback(ds);\n        '+fallback);
instrumented=instrumented.replace(/export const BEND_DIR =[\s\S]*?;\nexport const BASE_BEND/,`export const BEND_DIR = ${JSON.stringify(resolve('bend2')+'/')};\nexport const BASE_BEND`);
// This registry is assigned and removed within this observation process.
const registry=globalThis as typeof globalThis & {__stage0_observer?:typeof observer};
const temporary=resolve(import.meta.dir,'.stage0-observe-'+randomUUID()+'.ts');registry.__stage0_observer=observer;
try {
  await Bun.write(temporary,instrumented);
  const kernel:typeof import('../bend2/bend.ts')=await import(temporary);
  let fresh=0;
  function reserve(x:unknown){if(!x||typeof x!=='object')return;for(const[key,v]of Object.entries(x)){if(key==='s')continue;if(key==='i'&&typeof v==='number')fresh=Math.max(fresh,v+1);else reserve(v);}}
  reserve(body);for(const p of signature.parameters)fresh=Math.max(fresh,p[2]+1);
  const initialFresh=fresh;
  const lowered=kernel.body_flatten(body,signature.parameters.map(([q,k,i,,s])=>({$:'PVar',q,k,i,s})),()=>fresh++);
  const seen=new WeakSet<object>();
  function objects(x:unknown):number{if(!x||typeof x!=='object'||seen.has(x))return 0;seen.add(x);return 1+Object.entries(x).reduce((n,[key,v])=>n+(key==='s'?0:objects(v)),0);}
  const loweredObjects=objects(lowered);
  if(loweredObjects!==473631||fresh-initialFresh!==10279)throw Error('Observer changed A1 diagnostic result');
  const result={loweredObjects,freshBinders:fresh-initialFresh,matchFlattenCalls:calls,distinctMatrixStates:states.size,repeatedMatrixStateCalls:repeated,defaultBranchCalls:defaults,defaultRowMemberships,wildcardBranchDuplicationMemberships,stateDefinition:'Exact scrutinee/pattern structural spelling including IDs/quantities, row-body identity, and remaining variable IDs/quantities; no alpha-equivalence, no result caching',duplicationDefinition:'Wildcard row memberships retained in both constructor and default branches; counted per split, not unique source rows',scope:'A1 exact eight-row diagnostic; observation-only temporary module, production match_flatten unchanged'};
  await Bun.write('checkpoints/stage0-a1-call-observation.json',JSON.stringify(result,null,2)+'\n');
  console.log(JSON.stringify(result));
} finally {
  await unlink(temporary);
  delete registry.__stage0_observer;
}
