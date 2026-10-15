#!/usr/bin/env bun
/** Read-only native match amplification probe; every run owns the heavy lease. */
import * as B from '../bend2/bend.ts';
import {readParserGraph} from './parser_full_graph.ts';
import {renderBody} from './parser_full_body_render.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {semanticCases} from './parser_full_match_factor_fixtures.ts';
import {mkdtemp,writeFile,rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
await guardHeavyGate(import.meta.path,{label:'generic-match-factor-probe'});
const kind=process.argv[2]??'wide-matrix',factored=process.argv.includes('--factored');
const diagnostic=kind==='diagnostic';
const fixture=semanticCases.find(item=>item.name===kind);
if(!diagnostic&&!fixture)throw Error('Unknown fixture '+kind);
const sourceOption=process.argv.find(arg=>arg.startsWith('--source='));
const source=diagnostic?await Bun.file(resolve(sourceOption?.slice(9)??'bend2/selfhost/parser.bend')).text():fixture!.source;
const graph=await readParserGraph(source),name=diagnostic?'pattern_scan':'matrix';
const original=graph.bodies.get(name)!,signature=graph.signatures.get(name)!;
const body:B.Body=diagnostic&&original.$==='Match'?{...original,r:original.r.slice(0,8)}:original;
function objects(value:unknown):number {const seen=new WeakSet<object>();function walk(v:unknown):number {if(!v||typeof v!=='object'||seen.has(v))return 0;seen.add(v);return 1+Object.entries(v).reduce((n,[k,x])=>n+(k==='s'?0:walk(x)),0);}return walk(value);}
let max=-1;function ids(v:unknown){if(!v||typeof v!=='object')return;for(const [key,value]of Object.entries(v)){if(key==='s')continue;if(key==='i'&&typeof value==='number')max=Math.max(max,value);else ids(value);}}
ids(body);for(const p of signature.parameters)max=Math.max(max,p[2]);
let transformed=body,audit:unknown=null;
if(factored){const {factorMatches}=await import('./parser_full_match_factor.ts');const result=factorMatches(body,{minimumRows:diagnostic?4:2,minimumFreshId:max+1});transformed=result.body;audit=result.audit;}
ids(transformed);let fresh=max+1;const started=performance.now();
const lowered=B.body_flatten(transformed,signature.parameters.map(([q,k,i,,s])=>({$: 'PVar' as const,q,k,i,s})),()=>fresh++);
const loweringMs=performance.now()-started;
const rendered=renderBody(transformed,signature.parameters,{book:graph.parserBook});
const before=renderBody(body,signature.parameters,{book:graph.parserBook});
const result:Record<string,unknown>={kind,factored,rawObjects:objects(body),factoredRawObjects:objects(transformed),loweredObjects:objects(lowered),freshBinders:fresh-max-1,loweringMs,sourceBytesBefore:Buffer.byteLength(before.body),sourceBytesAfter:Buffer.byteLength(rendered.body),audit};
if(process.argv.includes('--profile')){
  const freeMemo=new WeakMap<object,Set<number>>(),visited=new WeakSet<object>(),kinds:Record<string,number>={};let deadSubstitutions=0;
  function union(values:Iterable<Set<number>>){const ids=new Set<number>();for(const value of values)for(const id of value)ids.add(id);return ids;}
  function free(value:unknown):Set<number>{
    if(!value||typeof value!=='object')return new Set();
    const cached=freeMemo.get(value);if(cached)return cached;
    // These are in-process AST records/arrays, not external serialized input.
    const node=value as Record<string,unknown>;
    let ids:Set<number>;
    if(node.$==='Var'||node.$==='PVar'){if(typeof node.i!=='number')throw Error('Invalid variable ID');ids=new Set([node.i]);}
    else if(node.$==='Sub'){if(typeof node.i!=='number')throw Error('Invalid substitution ID');const tail=free(node.f);ids=new Set(tail);if(ids.delete(node.i))ids=union([ids,free(node.v)]);}
    else if(node.$==='Lam'||node.$==='All'){if(typeof node.i!=='number')throw Error('Invalid binder ID');ids=new Set(free(node.$==='Lam'?node.f:node.B));ids.delete(node.i);if(node.$==='All')ids=union([ids,free(node.A)]);}
    else if(node.$==='Let'){if(!Array.isArray(node.i)||!Array.isArray(node.v))throw Error('Invalid Let fields');ids=new Set(free(node.f));for(const id of node.i){if(typeof id!=='number')throw Error('Invalid Let ID');ids.delete(id);}ids=union([ids,...node.v.map(free)]);}
    else ids=union(Object.entries(value).filter(([key])=>key!=='s').map(([,child])=>free(child)));
    freeMemo.set(value,ids);return ids;
  }
  function profile(value:unknown){if(!value||typeof value!=='object'||visited.has(value))return;visited.add(value);if('$'in value&&typeof value.$==='string'){kinds[value.$]=(kinds[value.$]??0)+1;if(value.$==='Sub'&&'f'in value&&'i'in value&&typeof value.i==='number'&&!free(value.f).has(value.i))deadSubstitutions++;}for(const[key,child]of Object.entries(value))if(key!=='s')profile(child);}
  profile(lowered);result.profile={nodeKinds:kinds,deadSubstitutions,definition:'Sub binder absent from semantic free IDs of its continuation; substitutions are interpreted transitively, lambda/let bindings excluded'};
}
if(!diagnostic){const prefix=source.slice(0,source.indexOf('def matrix('));const emitted=prefix+`def matrix(${rendered.parameters}) -> Nat:\n${rendered.body}\n`;const directory=await mkdtemp(join(tmpdir(),'bend-match-probe-'));try{const path=join(directory,'fixture.bend');await writeFile(path,emitted);const book=B.book_nil();let at=performance.now();await B.book_load(book,path,'',new Map());result.bookLoadMs=performance.now()-at;at=performance.now();B.book_valid(book);result.bookValidMs=performance.now()-at;result.checkedDeclarations=book.order.length;result.values=[];for(const [a,b,expected]of fixture!.inputs){const p:B.Parse={book,dir:directory+'/',str:`matrix(${a}, ${b})`,pos:0,stk:[],frs:0,ns:'',al:{}};const value=B.term_wnf(book,B.term_higher(B.parse_term(p))),observed=B.nat_from_term(B.term_lower(value));if(observed===null)throw Error('Non-Nat result');(result.values as unknown[]).push({a,b,observed,expected});if(observed!==expected)throw Error('Semantic mismatch');}result.status='PASS';}catch(error){result.status='FAIL';result.error=error&&typeof error==='object'&&'$'in error&&error.$==='Err'?B.err_show(error as B.Err):String(error);process.exitCode=1;}finally{await rm(directory,{recursive:true,force:true});}}
const reportOption=process.argv.find(arg=>arg.startsWith('--report='));
const output=resolve(reportOption?.slice(9)??`checkpoints/match-factor-${kind}-${factored?'factored':'baseline'}${process.argv.includes('--profile')?'-profile':''}.json`);await Bun.write(output,JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify(result));
