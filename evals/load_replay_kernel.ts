import type * as B from '../bend2/bend.ts';
import {createHash,randomUUID} from 'node:crypto';
import {resolve} from 'node:path';
import {writeFileSync,rmSync} from 'node:fs';
export const frozen={
 'bend2/bend.ts':'47e1b06e2fa4466bad702f86d8cbce03f40e833a8ba8eaa1e04297fa46dc94a9',
 'bend2/selfhost/parser.bend':'f425995af41087dfa51f79e7b04259ea5d1acfa9906061c7ed57199bad4e18df',
 'bend2/selfhost/parser_full_generated_fuel.bend':'b66ca5fe16b41d65feb51afd95b3954550396b60e542c21a93fe042b7fa9d51e',
 'evals/parser_full_generate.ts':'0aedb4c1703cffe1055794b29829a357edcd956fdc0a8dec77bfa3c0cf7a6da6'};
export async function checkFrozen(){for(const[path,hash]of Object.entries(frozen)){if(createHash('sha256').update(await Bun.file(path).text()).digest('hex')!==hash)throw Error('Frozen input drift '+path);}}
declare global {var __loadReplayStage:((name:string,stage:string)=>void)|undefined;}
declare global {var __replayCheck:((name:string,stage:'before'|'after')=>void)|undefined;}
export async function replayKernel(mode:'historical'|'direct',observe?: (name:string,stage:string)=>void,options:{retention?:'retain'|'discard-e';observeCheck?:(name:string,stage:'before'|'after')=>void}={}):Promise<{kernel:typeof B;path:string;close:()=>void}>{
 await checkFrozen();
 const original=await Bun.file('bend2/bend.ts').text();
 const anchor='  def.v = term_higher(term_lower(term_higher(body_flatten(b, vars, () => p.sc.frs++))));';
 if(original.split(anchor).length!==2)throw Error('Exact parse-body replay anchor missing');
 const replacement=observe?[
  '  globalThis.__loadReplayStage?.(k, "flatten-start");',
  '  const flat = body_flatten(b, vars, () => p.sc.frs++);',
  '  globalThis.__loadReplayStage?.(k, "flatten-complete");',
  '  const first = term_higher(flat);',
  '  globalThis.__loadReplayStage?.(k, "higher-complete");',
  mode==='direct'?'  def.v = first;':'  def.v = term_higher(term_lower(first));',
  '  globalThis.__loadReplayStage?.(k, "assigned");',
 ].join('\n'):mode==='direct'?'  def.v = term_higher(body_flatten(b, vars, () => p.sc.frs++));':anchor;
 const prelude=(observe?'declare global {var __loadReplayStage:((name:string,stage:string)=>void)|undefined;}\n':'')+(options.observeCheck?"declare global {var __replayCheck:((name:string,stage:'before'|'after')=>void)|undefined;}\n":'');
 let changed=original.replace(anchor,replacement);
 const checkAnchor='      def.e = term_check(seen, { t: Ref(k), n: def.n, def: k, qs, u: def.u }, def.v, Lone(), def.T, ctx_nil(), 0).tm;';
 const discard=checkAnchor.replace('def.e = ','');
 if(options.retention==='discard-e'){
  if(changed.split(checkAnchor).length!==2)throw Error('Exact checked-body retention anchor missing');
  changed=changed.replace(checkAnchor,discard);
 }
 const statement=options.retention==='discard-e'?discard:checkAnchor;
 const instrumented=['      globalThis.__replayCheck?.(k, "before");',statement,'      globalThis.__replayCheck?.(k, "after");'].join('\n');
 if(options.observeCheck)changed=changed.replace(statement,instrumented);
 const uninstrumented=options.observeCheck?changed.replace(instrumented,statement):changed;
 const recovered=options.retention==='discard-e'?uninstrumented.replace(discard,checkAnchor):uninstrumented;
 if(recovered.replace(replacement,anchor)!==original)throw Error('Temporary kernel changed beyond approved substitutions and invertible observation');
 const path=resolve('bend2',`.load_replay_${mode}_${randomUUID()}.ts`);
 writeFileSync(path,prelude+changed);globalThis.__loadReplayStage=observe;globalThis.__replayCheck=options.observeCheck;
 try {const kernel=await import(path);return{kernel,path,close:()=>{globalThis.__loadReplayStage=undefined;globalThis.__replayCheck=undefined;rmSync(path,{force:true});}};}
 catch(error){rmSync(path,{force:true});globalThis.__loadReplayStage=undefined;throw error;}
}
