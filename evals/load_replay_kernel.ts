import type * as B from '../bend2/bend.ts';
import {createHash,randomUUID} from 'node:crypto';
import {resolve} from 'node:path';
import {readFileSync,writeFileSync,rmSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
const releaseKernel = execFileSync('git', ['show', '4ff8545f19b09b7d2b8ca2303668100eac8efd66:bend2/bend.ts'], {cwd: resolve(import.meta.dir, '..'), encoding: 'utf8'});
export const frozen={
 'bend2/bend.ts':createHash('sha256').update(releaseKernel).digest('hex'),
 'bend2/selfhost/parser.bend':'f425995af41087dfa51f79e7b04259ea5d1acfa9906061c7ed57199bad4e18df',
 'bend2/selfhost/parser_full_generated_fuel.bend':'b66ca5fe16b41d65feb51afd95b3954550396b60e542c21a93fe042b7fa9d51e'};
export async function checkFrozen(){for(const[path,hash]of Object.entries(frozen)){if(createHash('sha256').update(readFileSync(path)).digest('hex')!==hash)throw Error('Frozen input drift '+path);}}
declare global {var __loadReplayStage:((name:string,stage:string)=>void)|undefined;}
declare global {var __replayCheck:((name:string,stage:'before'|'after')=>void)|undefined;}
export async function replayKernel(mode:'historical'|'direct',observe?: (name:string,stage:string)=>void,options:{retention?:'retain'|'discard-e';observeCheck?:(name:string,stage:'before'|'after')=>void}={}):Promise<{kernel:typeof B;path:string;close:()=>void}>{
 await checkFrozen();
 const original=readFileSync('bend2/bend.ts','utf8');
 const anchor='    def.v = term_higher(term_lower(term_higher(body_flatten(parse_body(p), vars, () => p.frs++))));';
 if(original.split(anchor).length!==2)throw Error('Exact parse-body replay anchor missing');
 const replacement=observe?[
  '    globalThis.__loadReplayStage?.(k, "flatten-start");',
  '    const flat = body_flatten(parse_body(p), vars, () => p.frs++);',
  '    globalThis.__loadReplayStage?.(k, "flatten-complete");',
  '    const first = term_higher(flat);',
  '    globalThis.__loadReplayStage?.(k, "higher-complete");',
  mode==='direct'?'    def.v = first;':'    def.v = term_higher(term_lower(first));',
  '    globalThis.__loadReplayStage?.(k, "assigned");',
 ].join('\n'):mode==='direct'?'    def.v = term_higher(body_flatten(parse_body(p), vars, () => p.frs++));':anchor;
 const prelude=(observe?'declare global {var __loadReplayStage:((name:string,stage:string)=>void)|undefined;}\n':'')+(options.observeCheck?"declare global {var __replayCheck:((name:string,stage:'before'|'after')=>void)|undefined;}\n":'');
 let changed=original.replace(anchor,replacement);
 const changes:[string,string][]=[];
 for(const[checkAnchor,assignment,name,indent]of [
  ['        tld.e = def_check(book, k, tld);','tld.e = ','k','        '],
  ['    inst.e = def_check(book, o, inst, z);','inst.e = ','o','    '],
 ]){
  if(changed.split(checkAnchor).length!==2)throw Error('Exact checked-body retention anchor missing');
  const statement=options.retention==='discard-e'?checkAnchor.replace(assignment,''):checkAnchor;
  const instrumented=options.observeCheck?[indent+'globalThis.__replayCheck?.('+name+', "before");',statement,indent+'globalThis.__replayCheck?.('+name+', "after");'].join('\n'):statement;
  changed=changed.replace(checkAnchor,instrumented);changes.push([checkAnchor,instrumented]);
 }
 let recovered=changed;
 for(const[before,after]of changes.reverse())recovered=recovered.replace(after,before);
 if(recovered.replace(replacement,anchor)!==original)throw Error('Temporary kernel changed beyond approved substitutions and invertible observation');
 const path=resolve('bend2',`.load_replay_${mode}_${randomUUID()}.ts`);
 writeFileSync(path,prelude+changed);globalThis.__loadReplayStage=observe;globalThis.__replayCheck=options.observeCheck;
 try {const kernel=await import(path);return{kernel,path,close:()=>{globalThis.__loadReplayStage=undefined;globalThis.__replayCheck=undefined;rmSync(path,{force:true});}};}
 catch(error){rmSync(path,{force:true});globalThis.__loadReplayStage=undefined;globalThis.__replayCheck=undefined;throw error;}
}
