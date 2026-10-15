#!/usr/bin/env bun
/** Native checks of bounded original Body subtrees, not whole-function validity. */
import {readFileSync,writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {createHash} from 'node:crypto';
import * as B from '../bend2/bend.ts';
import {readParserGraph} from './parser_full_graph.ts';
const source=readFileSync(resolve(import.meta.dir,'../bend2/selfhost/parser.bend'),'utf8');
const graph=await readParserGraph(source),book:B.Book={...graph.parserBook,tlds:{...graph.parserBook.tlds}};
for(const[name,sig]of graph.signatures)book.tlds[name]={$:'Def',n:sig.parameters.length,T:B.term_higher(B.tele_bind(sig.parameters,sig.result)),v:null,b:true};
const lhs:B.LHS={t:B.Ref('canonical_subtree_audit'),n:0,def:'canonical_subtree_audit',qs:[]};
type Scope={ctx:B.Ctx,env:B.Env,next:number};
function bind(p:B.Patt,T:B.HTerm,quantity:B.Quant,scope:Scope):Scope{
 if(p.$==='PVar'){let q=quantity;if(p.q.$==='Many'&&q.$==='Lone'){B.term_check_kind(book,lhs,T,p.q,scope.ctx,scope.next,p.s);q=p.q;}if(p.k==='_')return scope;const v=B.Var(p.k,p.i);return{ctx:B.ctx_bind(scope.ctx,p.i,q,p.k,T),env:B.list_set(scope.env,p.i,v),next:Math.max(scope.next,p.i+1)};}
 const ty=B.term_wnf(book,T),ctor=book.ctrs[p.k];if(ty.$!=='ADT'||!ctor||book.tlds[ty.k]?.$!=='ADT'||!(book.tlds[ty.k] as B.ADT).c.some(c=>c.k===p.k))throw Error('Pattern datatype mismatch');
 let tel=B.tele_fill(book,ctor.T,ty.x,scope.ctx),s=scope;
 for(const child of p.x){const h=B.tele_head(book,tel,s.ctx),q=h.q.$==='None'?B.None():h.q.$==='Lone'?quantity:B.quant_add(quantity,quantity);s=bind(child,h.A,q,s);tel=h.B(child.$==='PVar'&&child.k!=='_'?B.Var(child.k,child.i):B.Var('subtree_wild',s.next++));}return s;
}
function infer(t:B.LTerm,s:Scope){return B.term_infer(book,lhs,B.term_higher(t,s.env),B.Lone(),s.ctx,s.next).ty;}
const name=process.argv[2]!,binder=process.argv[3]!;if(!graph.bodies.has(name)||!binder)throw Error('Usage: parser_canonical_subtree_audit.ts function binder');
const results:Record<string,unknown>[]=[];
function contains(p:B.Patt):boolean{return p.$==='PVar'?p.k===binder:p.x.some(contains);}
function walk(b:B.Body,s:Scope,goal:B.HTerm):void{
 if(b.$==='Reply')return;
 if(b.$==='Local'){let inner=s;for(let i=0;i<b.v.length;i++){const p=b.k[i]!,q=p.$==='PVar'?B.quant_join(b.q,p.q):b.q;inner=bind(p,infer(b.v[i]!,s),q,inner);}walk(b.f,inner,goal);return;}
 if(b.r.some(r=>r.p.some(contains))){
  let next=s.next;const vars=B.pmap_to_array(s.ctx).sort((a,b)=>a[0]-b[0]);
  let T=B.term_lower(goal);for(const[i,a]of [...vars].reverse())T={$:'All',i,k:a.k,q:a.q,A:B.term_lower(a.T),B:T};
  try{const flat=B.body_flatten(b,vars.map(([i,a])=>({$:'PVar',i,k:a.k,q:a.q})),()=>next++);B.term_check(book,lhs,B.term_higher(flat),B.Lone(),B.term_higher(T),B.ctx_nil(),0);results.push({line:b.s?source.slice(0,b.s.beg).split('\n').length:null,status:'PASS'});}catch(e){results.push({line:b.s?source.slice(0,b.s.beg).split('\n').length:null,status:'FAIL',diagnostic:(e as B.Err).$==='Err'?B.err_show(e as B.Err):String(e)});}return;
 }
 const types=b.e.map(e=>infer(e,s));for(const r of b.r){let inner=s;for(let i=0;i<r.p.length;i++){const e=b.e[i]!;if(e.$!=='Var')throw Error('Native scoped subtree requires a parameter/field scrutinee');const a=B.pmap_get(s.ctx,e.i);if(!a)throw Error('Native scrutinee absent from context');inner=bind(r.p[i]!,types[i]!,a.q,inner);}walk(r.f,inner,goal);}
}
const sig=graph.signatures.get(name)!;let scope:Scope={ctx:B.ctx_nil(),env:null,next:0};for(const[q,k,i,T,s]of sig.parameters)scope=bind({$:'PVar',q,k,i,s},B.term_higher(T,scope.env),q,scope);walk(graph.bodies.get(name)!,scope,B.term_higher(sig.result,scope.env));
const report={sourceSha256:createHash('sha256').update(source).digest('hex'),function:name,binder,method:'Native original Body subtree flattened under its sound source-pattern lexical telescope and original result goal; full subtree resource accounting is checked, not other branches or whole-function validity.',results};
writeFileSync(resolve(import.meta.dir,'../bend2/selfhost/parser.bend.canonical-subtree-audit.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report));
