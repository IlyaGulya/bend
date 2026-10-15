import * as B from '../bend2/bend.ts';
import {canonicalSourceBook} from './parser_full_semantic_normalize.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
await guardHeavyGate(import.meta.path,{label:'Canonical bootstrap parser minimized token/remainder traces'});
const book=await canonicalSourceBook(await Bun.file('bend2/selfhost/parser.bend').text());
function closed(text:string){const p:B.Parse={book,dir:resolve('bend2/selfhost')+'/',str:text,pos:0,sc:{stk:[],frs:0},ns:'',al:{Ast:'ast',Lexer:'lexer'},os:[],inst:null,ts:[],lv:0};return B.term_higher(B.parse_term(p));}
const ctor=(t:B.HTerm)=>{const v=B.term_wnf(book,t);if(v.$!=='Ctr')throw Error('Expected constructor '+v.$);return v;};
const call=(name:string,args:B.HTerm[])=>args.reduce((f,x)=>B.App(f,x),B.Ref(name));
function list(t:B.HTerm){const xs=[];while(true){const v=ctor(t);if(v.k.split('.').at(-1)==='Nil')return xs;if(v.k.split('.').at(-1)!=='Con')throw Error('Bad list '+v.k);xs.push(v.x[0]);t=v.x[1];}}
function nat(t:B.HTerm){let n=0;while(true){const v=ctor(t);if(v.k==='Zero')return n;if(v.k!=='Succ')throw Error('Bad Nat '+v.k);n++;t=v.x[0];}}
function str(t:B.HTerm){let s='';while(true){const v=ctor(t);if(v.k==='SNil')return s;if(v.k!=='SCon')throw Error('Bad String '+v.k);let word=ctor(ctor(v.x[0]).x[0]).x[0],n=0,b=1;while(true){const c=ctor(word);if(c.k==='WNil')break;if(ctor(c.x[0]).k==='True')n+=b;b*=2;word=c.x[1];}s+=String.fromCodePoint(n);t=v.x[1];}}
function tokens(t:B.HTerm){return list(t).map(x=>{const v=ctor(x);return {kind:ctor(v.x[0]).k,text:str(v.x[1]),beg:nat(v.x[2]),end:nat(v.x[3]),line:nat(v.x[4]),col:nat(v.x[5])};});}
const fixtures=[
 {name:'cons',source:'def f(x: Nat) -> Nat:\n  match x:\n    case +_ <> _: 0n\n'},
 {name:'tuple',source:'def f(x: Nat) -> Nat:\n  match x:\n    case (a, b): a\n'},
 {name:'char',source:"def f(x: Char) -> Nat:\n  match x:\n    case 'x': 0n\n"},
 {name:'multi',source:'def f(x: Nat, y: Nat) -> Nat:\n  match x y:\n    case Zero{} Zero{}: 0n\n'},
 {name:'indexed-erased',source:'type A<-p: Nat> is Data:\n  C{}\n'},
];
const rows=[];
for(const item of fixtures){
 const raw=call('lexer.tokens',[closed(JSON.stringify(item.source))]);
 const combined=call('combine_symbols',[raw,B.Ctr('SymbolCombineScan',[])]);
 const inputTokens=tokens(combined),publicResult=ctor(call('parse',[closed(JSON.stringify(item.name)),closed(JSON.stringify(item.source))]));
 const row:any={...item,lexerTokens:tokens(raw),combinedTokens:inputTokens,result:publicResult.k};
 if(item.name==='indexed-erased'){
  const xs=list(combined);const tail=xs.slice(1).reduceRight((rest,x)=>B.Ctr('Con',[x,rest]),B.Ctr('Nil',[]));
  const result=ctor(call('parse_type_decl',[closed(JSON.stringify(item.name)),tail,closed('0n'),closed('0n')]));const pair=ctor(result.x[0]);row.helper='parse_type_decl';row.ok=ctor(result.x[1]).k;row.remainder=tokens(pair.x[1]);
 }else{
  const xs=list(combined),bodyIndex=inputTokens.findIndex(x=>x.text==='match'),body=xs.slice(bodyIndex).reduceRight((rest,x)=>B.Ctr('Con',[x,rest]),B.Ctr('Nil',[]));
  const scope=closed(item.name==='multi'?'[Scope{"x", 0n}, Scope{"y", 1n}]':'[Scope{"x", 0n}]');
  const result=ctor(call('parse_body',[closed(JSON.stringify(item.name)),body,scope,closed(item.name==='multi'?'2n':'1n'),closed('0n')]));const pair=ctor(result.x[0]);row.helper='parse_body';row.ok=ctor(result.x[1]).k;row.partialTerm=ctor(pair.x[0]).k;row.remainder=tokens(pair.x[1]);
 }
 rows.push(row);writeFileSync('checkpoints/bootstrap-parser-minimized-traces.json',JSON.stringify({rows},null,2)+'\n');console.log(JSON.stringify(row));Bun.gc(true);
}
