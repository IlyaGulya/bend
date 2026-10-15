import * as B from '../bend2/bend.ts';
import type {ParserGraph} from './parser_full_graph.ts';
import {freeBinderIds,termChildren} from './parser_full_type_env.ts';
export type CursorRelation='Same'|'StrictSuffix'|'Suffix'|'Unknown';
export type ConstructorFieldMatrix={constructor:string;paths:number[][];relations:CursorRelation[][]};
export type CursorInput={input:number;binderId:number;path:number[];root:string;constructorFields?:ConstructorFieldMatrix};
export type CursorGuard={path:number[];constructor:string};
export type CursorResult={path:number[];guards:CursorGuard[];relations:Record<string,CursorRelation>;reason:string};
export type CursorPush={captureBinderId:number;capturePath:number[];captureRoot:string;child:CursorInput;relation:CursorRelation;guards:CursorGuard[];unknownReason?:{category:'cross-stack ancestry loss'|'constructor-field relation loss'|'opaque callee result'|'genuinely unrelated cursors'|'other';reason:string}};
export type TokenTransition={caller:string;callee:string;offset:number;line:number;sourceCursor:string;destinationCursor:string;relation:CursorRelation;sourceProvenance:Record<string,string>;destinationProvenance:Record<string,string>;sourceConstruct:string;reason:string};
export type TokenProvenanceAnalysis={summaries:Map<string,unknown>;transitions:TokenTransition[];iterations:number;cursorInputs(name:string):CursorInput[];cursorResults(name:string,active?:CursorInput):CursorResult[];cursorPushes(caller:string,offset:number,captureIds:readonly number[],active?:CursorInput):CursorPush[];relationOf(name:string,input:number,path:number[],branch?:{path:number[];constructor:string}):CursorRelation;fieldRelationOf(name:string,fromPath:number[],toPath:number[],branch?:{path:number[];constructor:string}):CursorRelation};
// Masks are a finite powerset lattice: bottom 0, Same 1, StrictSuffix 2,
// their join Suffix 3, and Unknown 7. Output alternatives preserve guards.
type Token={kind:'token';relations:Record<string,number>};
type Constructor={kind:'ctor';tag:string;fields:Value[];matrix?:ConstructorFieldMatrix};
type Closure={kind:'lambda';id:number;owner:string;node:Extract<B.LTerm,{$:'Lam'|'Mat'}>;captures:[number,Value][]};
type FunctionValue={kind:'function';name:string;args:Value[]};
type Value=Token|Constructor|Closure|FunctionValue|{kind:'literal';node:Extract<B.LTerm,{$:'Lit'}>}|{kind:'unknown';cursorLoss?:boolean};
type Environment=Map<number,Value>;
type Event={caller:string;callee:string;offset:number;args:Value[];bindings:[number,Value][]};
type Context={name:string;args:Value[];outputs:Value[];events:Event[];dependents:Set<Context>};
const unknown:Value={kind:'unknown'};
const FIELD_DEPTH=8;
function relation(mask:number):CursorRelation{return mask===1?'Same':mask===2?'StrictSuffix':mask===3?'Suffix':'Unknown';}
function at(value:Value,path:readonly number[]):Value|undefined{let v:Value|undefined=value;for(const i of path){if(v?.kind==='unknown')return unknown;v=v?.kind==='ctor'?v.fields[i]:undefined;}return v;}
function shape(v:Value):unknown{if(v.kind==='literal')return{kind:v.kind,type:v.node.k,value:v.node.v};if(v.kind==='lambda')return{kind:v.kind,codeKind:v.node.$,id:v.id,owner:v.owner,captures:v.captures.map(([i,x])=>[i,shape(x)])};if(v.kind==='ctor')return{kind:v.kind,tag:v.tag,matrix:v.matrix,fields:v.fields.map(shape)};if(v.kind==='function')return{...v,args:v.args.map(shape)};return v;}
function key(v:Value):string{return JSON.stringify(shape(v));}
function distinct(values:Value[]):Value[]{return[...new Map(values.map(v=>[key(v),v])).values()];}
function bounded(v:Value,depth=0,closures=new Set<number>()):Value{
 if(depth>=FIELD_DEPTH)return tokens(v).length?{kind:'unknown',cursorLoss:true}:unknown;
 if(v.kind==='ctor')return constructor(v.tag,v.fields.map(x=>tokens(v).length||callableOwners(v).size?bounded(x,depth+1,closures):unknown),v.matrix);
 if(v.kind==='function')return{...v,args:v.args.map(x=>bounded(x,depth+1,closures))};
 if(v.kind==='lambda'){if(closures.has(v.id))return unknown;const seen=new Set([...closures,v.id]);return{...v,captures:v.captures.map(([i,x])=>[i,bounded(x,depth+1,seen)])};}
 return v;
}
function compose(a:number,b:number):number{if(!a||!b)return 0;if(a===7||b===7)return 7;if(a===1)return b;if(b===1)return a;return a===2||b===2?2:3;}
function suffix(t:Token):Token{return{kind:'token',relations:Object.fromEntries(Object.entries(t.relations).map(([r,q])=>[r,compose(2,q)]))};}
function tokens(v:Value,path:number[]=[]):[number[],Token][]{if(v.kind==='token')return[[path,v]];if(v.kind==='unknown'&&v.cursorLoss)return[[path,{kind:'token',relations:{}}]];return v.kind==='ctor'?v.fields.flatMap((x,i)=>tokens(x,[...path,i])):[];}
const masks:Record<CursorRelation,number>={Same:1,StrictSuffix:2,Suffix:3,Unknown:7};
function relative(from:Token,to:Token):number{
 if(from===to)return 1;
 let result=0;for(const[root,q]of Object.entries(to.relations))if(q===1&&from.relations[root])result|=from.relations[root]!;
 return result||7;
}
function fieldMask(value:Value,fromPath:readonly number[],toPath:readonly number[]):number{
 if(value.kind==='ctor'&&value.matrix){
  const i=value.matrix.paths.findIndex(p=>p.join('.')===fromPath.join('.')),j=value.matrix.paths.findIndex(p=>p.join('.')===toPath.join('.'));
  if(i>=0&&j>=0)return masks[value.matrix.relations[i]![j]!];
 }
 const from=at(value,fromPath),to=at(value,toPath);
 return from?.kind==='token'&&to?.kind==='token'?relative(from,to):7;
}
function constructor(tag:string,fields:Value[],prior?:ConstructorFieldMatrix):Constructor{
 const value:Constructor={kind:'ctor',tag,fields},entries=tokens(value);
 const paths=entries.map(([p])=>p);
 const relations=entries.map(([from,a])=>entries.map(([to,b])=>{
  const pi=prior?.paths.findIndex(p=>p.join('.')===from.join('.'))??-1,pj=prior?.paths.findIndex(p=>p.join('.')===to.join('.'))??-1;
  if(pi>=0&&pj>=0)return prior!.relations[pi]![pj]!;
  if(from[0]===to[0])return relation(fieldMask(fields[from[0]!]!,from.slice(1),to.slice(1)));
  return relation(relative(a,b));
 }));
 if(entries.length)value.matrix={constructor:tag,paths,relations};
 return value;
}
function matrixKey(value:Value):string{return value.kind==='ctor'?JSON.stringify(value.matrix??{constructor:value.tag,paths:[],relations:[]}):'';}
function callableOwners(v:Value,owners=new Set<string>()):Set<string>{
 if(v.kind==='lambda'){owners.add(v.owner);for(const[,x]of v.captures)callableOwners(x,owners);}
 else if(v.kind==='ctor')for(const x of v.fields)callableOwners(x,owners);
 else if(v.kind==='function')for(const x of v.args)callableOwners(x,owners);
 return owners;
}
function eventKey(e:Event):string{return e.caller+':'+e.callee+':'+e.offset+':'+e.args.map(key).join('|')+':'+e.bindings.map(([i,v])=>i+'='+key(v)).join('|');}
function eventValue(v:Value):Value{v=bounded(v);if(v.kind==='token')return v;if(v.kind==='ctor'&&tokens(v).length)return{...v,fields:v.fields.map(eventValue)};return unknown;}
export function analyzeTokenProvenance(graph:ParserGraph,options?:{tokenElement?:string}):TokenProvenanceAnalysis{
 const element=options?.tokenElement??'lexer.Token';
 // Closed generated-source Data invariants: infer each local constructor
 // separately, then validate against every production before exposing facts.
 // No field names, function names or parser offsets participate.
 const localTypes=new Set([...graph.source.matchAll(/^type\s+(\S+)/gm)].map(m=>m[1]!));
 const localConstructors=new Set([...localTypes].flatMap(k=>{const d=graph.parserBook.tlds[k];return d?.$==='ADT'?d.c.map(c=>c.k):[];}));
 const invariants=new Map<string,Map<string,number>>(),observed=new Map<string,Map<string,number>>();
 let validating=false;
 const pairKey=(a:readonly number[],b:readonly number[])=>a.join('.')+'|'+b.join('.');
 const productionSites=new Map<string,Set<B.LTerm>>(),seenProductions=new Set<B.LTerm>();
 function scan(t:B.LTerm):void{
  if(t.$==='Ctr'&&localConstructors.has(t.k)){const sites=productionSites.get(t.k)??new Set<B.LTerm>();sites.add(t);productionSites.set(t.k,sites);}
  for(const child of termChildren(t))scan(child);
 }
 function scanBody(b:B.Body):void{
  if(b.$==='Local'){for(const v of b.v)scan(v);scanBody(b.f);}
  else if(b.$==='Match'){for(const v of b.e)scan(v);for(const row of b.r)scanBody(row.f);}
  else scan(b);
 }
 for(const b of graph.bodies.values())scanBody(b);
 function schema(v:Constructor):void{
  if(!localConstructors.has(v.tag))return;
  const row=invariants.get(v.tag)??new Map<string,number>();invariants.set(v.tag,row);
  for(const[a]of tokens(v))for(const[b]of tokens(v))if(!row.has(pairKey(a,b)))row.set(pairKey(a,b),validating?7:0);
 }
 function enrich(v:Constructor,matrix:ConstructorFieldMatrix):Constructor{
  const entries=tokens(v),replacements=new Map<string,Token>();
  for(const[path,t]of entries){
   const i=matrix.paths.findIndex(p=>p.join('.')===path.join('.')),relations={...t.relations};
   if(i>=0)for(const[to,source]of entries){
    const j=matrix.paths.findIndex(p=>p.join('.')===to.join('.'));if(j<0)continue;
    const q=masks[matrix.relations[i]![j]!];if(q===7)continue;
    const root=Object.keys(source.relations).find(r=>source.relations[r]===1);
    if(root)relations[root]=(relations[root]??0)|q;
   }
   replacements.set(path.join('.'),{kind:'token',relations});
  }
  function replace(x:Value,path:number[]):Value{
   if(x.kind==='token')return replacements.get(path.join('.'))??x;
   return x.kind==='ctor'?constructor(x.tag,x.fields.map((f,i)=>replace(f,[...path,i])),x.matrix):x;
  }
  return constructor(v.tag,v.fields.map((f,i)=>replace(f,[i])),matrix);
 }
 function invariantSeed(v:Constructor):Constructor{
  schema(v);const row=invariants.get(v.tag);if(!row||!v.matrix)return v;
  const matrix={...v.matrix,relations:v.matrix.paths.map(a=>v.matrix!.paths.map(b=>{
   const q=row.get(pairKey(a,b))??7;
   return relation(q||1); // Provisional induction hypothesis, never exported.
  }))};
  return enrich(v,matrix);
 }
 function observe(v:Constructor):void{
  const expected=invariants.get(v.tag);if(!expected)return;
  const row=observed.get(v.tag)??new Map<string,number>();observed.set(v.tag,row);
  for(const key of expected.keys()){
   const[a,b]=key.split('|').map(p=>p!.split('.').filter(Boolean).map(Number));
   row.set(key,(row.get(key)??0)|fieldMask(v,a!,b!));
  }
 }
 const closureIds=new WeakMap<B.LTerm,number>();let nextClosureId=0;
 function closureId(node:B.LTerm):number{let id=closureIds.get(node);if(id===undefined){id=nextClosureId++;closureIds.set(node,id);}return id;}
 function tokenType(t:B.LTerm):boolean{const[h,args]=B.term_unapply(t);const xs=t.$==='ADT'&&t.k==='List'?t.x:h.$==='Ref'&&h.k==='List'?args:[];const e=xs[1];return!!e&&(e.$==='Ref'||e.$==='ADT')&&e.k===element;}
 function normalizedType(t:B.LTerm):B.LTerm{return B.term_lower(B.term_wnf(graph.parserBook,B.term_higher(t)));}
 function fieldsOf(T:Extract<B.LTerm,{$:'ADT'}>,tag:string):B.LTerm[]{
  const declaration=graph.parserBook.ctrs[tag];if(!declaration)return[];
  let tel=B.tele_fill(graph.parserBook,declaration.T,T.x.map(x=>B.term_higher(x)),B.ctx_nil());
  const fields:B.LTerm[]=[];for(let head=B.tele_open(graph.parserBook,tel);head;head=B.tele_open(graph.parserBook,tel)){fields.push(B.term_lower(head.A));tel=head.B(B.Var(head.k,-1));}return fields;
 }
 function containsTokens(T:B.LTerm,seen=new Set<string>(),depth=0):boolean{
  if(depth>=FIELD_DEPTH)return false;const t=normalizedType(T);if(tokenType(t))return true;
  if(t.$!=='ADT'||seen.has(t.k))return false;const d=graph.parserBook.tlds[t.k];if(d?.$!=='ADT')return false;
  const next=new Set([...seen,t.k]);return d.c.some(c=>fieldsOf(t,c.k).some(f=>containsTokens(f,next,depth+1)));
 }
 function seed(T:B.LTerm,root:string,depth=0,seen=new Set<string>()):Value[]{
  if(depth>=FIELD_DEPTH)return[{kind:'unknown',cursorLoss:containsTokens(T)}];const t=normalizedType(T);
  if(tokenType(t))return[{kind:'token',relations:{[root]:1}}];
  if(t.$!=='ADT')return[unknown];if(seen.has(t.k))return[{kind:'unknown',cursorLoss:containsTokens(t)}];const d=graph.parserBook.tlds[t.k];
  if(d?.$!=='ADT'||(t.k!=='Bool'&&!containsTokens(t)))return[unknown];
  return d.c.flatMap(c=>{let rows:Value[][]=[[]];for(const[f,T]of fieldsOf(t,c.k).entries())rows=rows.flatMap(row=>seed(T,root+'.'+c.k+'.'+f,depth+1,new Set([...seen,t.k])).map(v=>[...row,v]));return rows.map(fields=>invariantSeed(constructor(c.k,fields)));});
 }
 const formalRelevance=new Map([...graph.signatures].map(([name,sig])=>[name,sig.parameters.map(([, , ,T])=>{
  const t=normalizedType(T);return containsTokens(T)||(t.$==='ADT'&&t.k==='Bool');
 })]));
 const contexts=new Map<string,Context>(),seeds=new Map<string,Context[]>();
 const pending=new Set<Context>();let iterations=0,events:Event[]=[],currentContext:Context|undefined;
 function context(name:string,args:Value[]):Context{
  const values=args.map(v=>bounded(v)),id=name+':'+values.map(key).join('|');let c=contexts.get(id);
  if(!c){c={name,args:values,outputs:[],events:[],dependents:new Set()};contexts.set(id,c);pending.add(c);}return c;
 }
 function argumentsFor(name:string,args:Value[]):{args:Value[];substitutions:Map<string,Token>}{
  const substitutions=new Map<string,Token>(),sig=graph.signatures.get(name)!;
  function normalize(v:Value,root:string,keepConstructor=false):Value{
   if(v.kind==='token'){substitutions.set(root,v);return{kind:'token',relations:{[root]:1}};}
   if(v.kind==='ctor'){
    if(!keepConstructor&&v.fields.length&&!tokens(v).length&&!callableOwners(v).size)return unknown;
    const rebased=constructor(v.tag,v.fields.map((x,i)=>normalize(x,root+'.'+v.tag+'.'+i)),v.matrix);
    return rebased.matrix?enrich(rebased,rebased.matrix):rebased;
   }
   if(v.kind==='lambda')return{...v,captures:v.captures.map(([i,x])=>[i,normalize(x,root+'.lambda'+v.id+'.capture'+i)])};
   if(v.kind==='function')return{...v,args:v.args.map((x,i)=>normalize(x,root+'.argument'+i))};
   return v;
  }
  return{args:args.map((v,i)=>normalize(v,name+':'+sig.parameters[i]?.[2]+':'+i,formalRelevance.get(name)?.[i])),substitutions};
 }
 function instantiate(v:Value,substitutions:Map<string,Token>):Value{
  if(v.kind==='token'){const relations:Record<string,number>={};for(const[root,q]of Object.entries(v.relations)){const actual=substitutions.get(root);if(!actual){relations[root]=(relations[root]??0)|q;continue;}for(const[r,a]of Object.entries(actual.relations))relations[r]=(relations[r]??0)|compose(q,a);}return{kind:'token',relations};}
  if(v.kind==='ctor')return constructor(v.tag,v.fields.map(x=>instantiate(x,substitutions)),v.matrix);
  if(v.kind==='lambda')return{...v,captures:v.captures.map(([i,x])=>[i,instantiate(x,substitutions)])};
  if(v.kind==='function')return{...v,args:v.args.map(x=>instantiate(x,substitutions))};
  return v;
 }
 function apply(value:Value,args:Value[],owner:string):Value[]{
  if(!args.length)return[value];
  if(value.kind==='lambda'){
   const env=new Map(value.captures),node=value.node;
   if(node.$==='Lam'){env.set(node.i,args[0]!);return expression(node.f,env,value.owner).flatMap(v=>apply(v,args.slice(1),owner));}
   const raw=args[0]!,argument=raw.kind==='literal'?literalConstructor(B.lit_step(raw.node)):raw,variants:Value[]=argument.kind==='token'?[
    {kind:'ctor',tag:'Nil',fields:[]},
    {kind:'ctor',tag:'Con',fields:[unknown,suffix(argument)]},
   ]:[argument];
   return distinct(variants.flatMap(v=>{
    if(v.kind==='ctor')return v.tag===node.k?
     expression(node.h,env,value.owner).flatMap(h=>apply(h,[...v.fields,...args.slice(1)],owner)):
     expression(node.m,env,value.owner).flatMap(m=>apply(m,[v,...args.slice(1)],owner));
    const arity=graph.parserBook.ctrs[node.k]?.n??0;
    return[
     ...expression(node.h,env,value.owner).flatMap(h=>apply(h,[...Array<Value>(arity).fill(unknown),...args.slice(1)],owner)),
     ...expression(node.m,env,value.owner).flatMap(m=>apply(m,[unknown,...args.slice(1)],owner)),
    ];
   }));
  }
  if(value.kind==='function'){
   const all=[...value.args,...args],sig=graph.signatures.get(value.name);if(!sig)return[unknown];
   if(all.length<sig.parameters.length)return[{...value,args:all}];
   const normalized=argumentsFor(value.name,all.slice(0,sig.parameters.length));
   const c=context(value.name,normalized.args);
   if(currentContext)c.dependents.add(currentContext);
   const owners=new Set(all.flatMap(v=>[...callableOwners(v)]));
   events.push(...c.events.filter(e=>owners.has(e.caller)).map(e=>({...e,args:e.args.map(x=>bounded(instantiate(x,normalized.substitutions))),bindings:e.bindings.map(([i,v])=>[i,bounded(instantiate(v,normalized.substitutions))] as [number,Value])})));
   return c.outputs.flatMap(v=>apply(instantiate(v,normalized.substitutions),all.slice(sig.parameters.length),owner));
  }
  return[unknown];
 }
 function expression(t:B.LTerm,env:Environment,owner:string):Value[]{
  if(t.$==='Lit')return[{kind:'literal',node:t}];
  if(t.$==='Var')return[env.get(t.i)??unknown];
  if(t.$==='Ref')return graph.signatures.has(t.k)?[{kind:'function',name:t.k,args:[]}]:[unknown];
  if(t.$==='Ann')return expression(t.x,env,owner);
  if(t.$==='Lam'||t.$==='Mat')return[bounded({kind:'lambda',id:closureId(t),owner,node:t,captures:freeBinderIds(t).map(i=>[i,env.get(i)??unknown])})];
  if(t.$==='Efq')return[];
  if(t.$==='App'){
   const[head,args]=B.term_unapply(t);let rows:Value[][]=[[]];for(const a of args)rows=rows.flatMap(row=>expression(a,env,owner).map(v=>[...row,v]));
   if(head.$==='Ref'&&graph.signatures.has(head.k)&&head.s)for(const row of rows)events.push({caller:owner,callee:head.k,offset:head.s.beg,args:row.map(eventValue),bindings:[...env].filter(([,v])=>tokens(v).length).map(([i,v])=>[i,eventValue(v)])});
   return distinct(expression(head,env,owner).flatMap(fn=>rows.flatMap(row=>apply(fn,row,owner))));
  }
  if(t.$==='Ctr'){
   let rows:Value[][]=[[]];for(const x of t.x)rows=rows.flatMap(row=>expression(x,env,owner).map(v=>[...row,v]));
   return distinct(rows.map(fields=>{const v=constructor(t.k,fields);seenProductions.add(t);observe(v);return bounded(v);}));
  }
  if(t.$==='Let'){
   let states=[env];for(let i=0;i<t.v.length;i++)states=states.flatMap(s=>expression(t.v[i]!,env,owner).map(v=>{const inner=new Map(s);inner.set(t.i[i]!,v);return inner;}));
   return distinct(states.flatMap(s=>expression(t.f,s,owner)));
  }
  if(t.$==='Sub'){
   const v=B.patt_term(t.v);
   return distinct(expression(v,env,owner).flatMap(x=>{const inner=new Map(env);inner.set(t.i,x);return expression(t.f,inner,owner);}));
  }
  return[unknown];
 }
 function literalConstructor(term:B.LTerm):Value{
  if(term.$==='Lit')return{kind:'literal',node:term};
  if(term.$!=='Ctr')throw Error('Native lit_step returned non-literal constructor syntax');
  return constructor(term.k,term.x.map(literalConstructor));
 }
 function bind(p:B.Patt,v:Value,env:Environment):boolean{
  if(p.$==='PVar'){env.set(p.i,v);return true;}
  if(v.kind==='literal')v=literalConstructor(B.lit_step(v.node));
  if(v.kind==='token'){
   if(p.k==='Con')return bind(p.x[0]!,unknown,env)&&bind(p.x[1]!,suffix(v),env);
   return p.k==='Nil';
  }
  if(v.kind==='ctor'){if(v.tag!==p.k)return false;return p.x.every((child,i)=>bind(child,v.fields[i]??unknown,env));}
  return p.x.every(child=>bind(child,unknown,env));
 }
 function body(b:B.Body,env:Environment,owner:string):Value[]{
  if(b.$!=='Local'&&b.$!=='Match')return expression(b,env,owner);
  if(b.$==='Local'){
   let states=[env];for(let i=0;i<b.v.length;i++)states=states.flatMap(s=>expression(b.v[i]!,env,owner).flatMap(v=>{const inner=new Map(s);return bind(b.k[i]!,v,inner)?[inner]:[];}));
   return distinct(states.flatMap(s=>body(b.f,s,owner)));
  }
  let rows:Value[][]=[[]];for(const e of b.e)rows=rows.flatMap(row=>expression(e,env,owner).map(v=>[...row,v]));
  return distinct(rows.flatMap(values=>b.r.flatMap(row=>{const inner=new Map(env);return row.p.every((p,i)=>bind(p,values[i]!,inner))?body(row.f,inner,owner):[];})));
 }
 // Only finite matrix masks can change between validation rounds. A round
 // rebuilds summaries so no provisional hypothesis leaks into final evidence.
 for(const sig of graph.signatures.values()){for(const[, , ,T]of sig.parameters)seed(T,'schema');seed(sig.result,'schema');}
 for(;;){
 contexts.clear();seeds.clear();pending.clear();observed.clear();seenProductions.clear();
 for(const[name,sig]of graph.signatures){let rows:Value[][]=[[]];for(const[, ,id,T]of sig.parameters){const i=rows[0]?.length??0;rows=rows.flatMap(row=>seed(T,name+':'+id+':'+i).map(v=>[...row,v]));}seeds.set(name,rows.map(args=>context(name,args)));}
 // New contexts and output alternatives are added monotonically. Bounded field
 // paths, finite code/closure IDs and finite relation masks bound the universe.
 while(pending.size){
  const batch=[...pending];pending.clear();iterations++;
  for(const c of batch){
   currentContext=c;
   const sig=graph.signatures.get(c.name)!,env=new Map(sig.parameters.map(([, ,id],i)=>[id,c.args[i]??unknown]));
   events=[];
   const next=distinct([...c.outputs,...body(graph.bodies.get(c.name)!,env,c.name).map(v=>bounded(v))]);
   if(next.some(v=>v.kind==='unknown'))for(const v of seed(sig.result,'opaque')){
    function opaque(x:Value):void{
     if(x.kind!=='ctor')return;
     const row=invariants.get(x.tag);if(row){const out=observed.get(x.tag)??new Map<string,number>();observed.set(x.tag,out);for(const key of row.keys())out.set(key,7);}
     for(const child of x.fields)opaque(child);
    }
    opaque(v);
   }
   const nextEvents=[...new Map([...c.events,...events].map(e=>[eventKey(e),e])).values()];
   if(next.length!==c.outputs.length||nextEvents.length!==c.events.length){
    c.outputs=next;c.events=nextEvents;
    for(const dependent of c.dependents)pending.add(dependent);
   }
  }
 }
 let changed=false;
 for(const[tag,row]of invariants){
  const sites=productionSites.get(tag),missing=!sites?.size||[...sites].some(t=>!seenProductions.has(t));
  for(const[key,old]of row){
   const next=old|(missing?7:observed.get(tag)?.get(key)??7);
   if(next!==old){row.set(key,next);changed=true;}
  }
 }
 if(!changed)break;
 }
 validating=true;
 currentContext=undefined;
 const bySite=new Map<string,Event[]>();
 for(const c of contexts.values())for(const e of c.events)if(e.caller===c.name){const id=e.caller+':'+e.callee+':'+e.offset;const all=bySite.get(id)??[];all.push(e);bySite.set(id,all);}
 for(const[id,all]of bySite)bySite.set(id,[...new Map(all.map(e=>[eventKey(e),e])).values()]);
 const transitions:TokenTransition[]=[];
 for(const[caller,calls]of graph.calls)for(const call of calls){
  const alternatives=bySite.get(caller+':'+call.callee+':'+call.offset)??[],sig=graph.signatures.get(call.callee)!;
  const expected=sig.parameters.flatMap(([, ,id,T],i)=>seed(T,call.callee+':'+id+':'+i).flatMap(v=>tokens(v).map(([path])=>({input:i,path,id}))));
  const destinations=[...new Map(expected.map(x=>[x.input+':'+x.path.join('.'),x])).values()];
  let mask=0;const sourceProvenance:Record<string,string>={},destinationProvenance:Record<string,string>={};
  // Unknown alternatives remain sticky in the existing finite mask lattice.
  for(const d of destinations){
   let field=0;
   for(const e of alternatives){
    const v=e.args[d.input]&&at(e.args[d.input]!,d.path);
    if(v?.kind!=='token'){field|=7;continue;}
    const own=Object.entries(v.relations).filter(([r])=>r.startsWith(caller+':'));
    field|=own.length?own.reduce((q,[root,x])=>{
     sourceProvenance[root]='Same';
     const old=destinationProvenance[root] as CursorRelation|undefined;
     destinationProvenance[root]=relation((old?masks[old]:0)|x);
     return q|x;
    },0):7;
   }
   if(!alternatives.length)field=7;
   mask|=field;
   destinationProvenance[call.callee+':binder#'+d.id+':field['+d.path.join('.')+']']=relation(field);
  }
  if(!destinations.length)mask=7;
  transitions.push({
   caller,callee:call.callee,offset:call.offset,line:call.line,
   sourceCursor:Object.keys(sourceProvenance).join(' | ')||'Unknown',
   destinationCursor:destinations.map(d=>call.callee+':binder#'+d.id+':field['+d.path.join('.')+']').join(' | ')||'Unknown',
   relation:relation(mask),sourceProvenance,destinationProvenance,
   sourceConstruct:graph.source.slice(call.offset).split('\n',1)[0]!,
   reason:mask===7||!mask?'Unknown: missing or opaque cursor provenance; no administrative classification inferred':mask===2?'Every branch-reachable destination cursor is a strict matched-tail suffix after function/callback summary composition':mask===1?'Every branch-reachable destination cursor is the identical binder-identity input cursor':'Branch alternatives join identity and strict suffix; strict descent is not established',
  });
 }
 const summaries=new Map<string,unknown>([...seeds].map(([name,cs])=>[name,distinct(cs.flatMap(c=>c.outputs))]));
 // Stack evidence projects the existing domain; no additional value abstraction.
 const inputCache=new Map<string,CursorInput[]>(),resultCache=new Map<string,CursorResult[]>(),resultPaths=new Map<string,number[][]>();
 function cursorInputs(name:string):CursorInput[]{
  let found=inputCache.get(name);if(found)return found;
  found=graph.signatures.get(name)!.parameters.flatMap(([, ,binderId,T],input)=>seed(T,name+':'+binderId+':'+input).flatMap(v=>tokens(v).map(([path,t])=>({input,binderId,path,root:Object.keys(t.relations)[0]??name+':'+binderId+':'+input+':opaque['+path+']',constructorFields:v.kind==='ctor'?v.matrix:undefined}))));
  found=[...new Map(found.map(x=>[x.root,x])).values()];inputCache.set(name,found);return found;
 }
 function guardsOf(v:Value,path:number[]=[]):CursorGuard[]{
  return v.kind==='ctor'?[{path,constructor:v.tag},...v.fields.flatMap((x,i)=>guardsOf(x,[...path,i]))]:[];
 }
 function cursorResults(name:string,active?:CursorInput):CursorResult[]{
  const cacheKey=name+':'+JSON.stringify(active?.constructorFields??null);
  let found=resultCache.get(cacheKey);if(found)return found;
  let paths=resultPaths.get(name);if(!paths){paths=[...new Map(seed(graph.signatures.get(name)!.result,'result').flatMap(v=>tokens(v).map(([path])=>[path.join('.'),path]as const))).values()];resultPaths.set(name,paths);}
  const values=active?.constructorFields?distinct([...contexts.values()].filter(c=>c.name===name&&matrixKey(c.args[active.input]??unknown)===JSON.stringify(active.constructorFields)).flatMap(c=>c.outputs)):summaries.get(name) as Value[];
  found=values.flatMap(value=>paths.map(path=>{
   const v=at(value,path),relations=v?.kind==='token'?Object.fromEntries(Object.entries(v.relations).map(([r,q])=>[r,relation(q)])): {};
   return{path,guards:guardsOf(value),relations,reason:v?.kind==='token'?'Existing branch-specific cursor summary':'Existing domain has no token provenance at this result field ('+(v?.kind??'absent')+')'};
  }));
  if(!found.length)found=[{path:[],guards:[],relations:{},reason:'No cursor-bearing result alternative is represented by the existing summary'}];
  resultCache.set(cacheKey,found);return found;
 }
 function cursorPushes(caller:string,offset:number,captureIds:readonly number[],active?:CursorInput):CursorPush[]{
  const site=graph.calls.get(caller)!.find(c=>c.offset===offset);if(!site)return[];
  const alternatives=(bySite.get(caller+':'+site.callee+':'+offset)??[]).filter(e=>!active?.constructorFields||matrixKey(e.bindings.find(([i])=>i===active.binderId)?.[1]??unknown)===JSON.stringify(active.constructorFields));
  const pushes=alternatives.flatMap(e=>captureIds.flatMap(captureBinderId=>{
   const captured=e.bindings.find(([i])=>i===captureBinderId)?.[1];if(!captured)return[];
   return tokens(captured).flatMap(([capturePath,t])=>cursorInputs(site.callee).flatMap(formal=>{
    const actual=e.args[formal.input]??unknown;
    if(formal.constructorFields&&actual.kind==='ctor'&&formal.constructorFields.constructor!==actual.tag)return[];
    const child={...formal,constructorFields:actual.kind==='ctor'?actual.matrix:undefined};
    const destination=at(actual,child.path),argument=site.args[child.input];
    let mask=0;
    if(destination?.kind==='token'){
     if(argument?.$==='Var'&&argument.i===captureBinderId&&capturePath.join('.')===child.path.join('.'))mask=1;
     else for(const[root,q]of Object.entries(t.relations))if(q===1)mask|=destination.relations[root]??7;
    }
    let unknownReason:CursorPush['unknownReason'];
    if(relation(mask)==='Unknown'){
     unknownReason={category:destination?.kind==='token'?'cross-stack ancestry loss':'opaque callee result',reason:destination?.kind==='token'?'No proved relation to the suspended cursor root':'Child argument has no cursor provenance at this field'};
     if(captured.kind==='ctor'&&destination?.kind==='token')for(const[path,source]of tokens(captured)){
      if(path.join('.')===capturePath.join('.'))continue;
      if(relative(destination,source)!==7&&fieldMask(captured,path,capturePath)===7){
       unknownReason={category:'constructor-field relation loss',reason:'Retained '+captured.tag+' matrix has Unknown for field ['+path+'] relative to ['+capturePath+']; child provenance is '+relation(relative(destination,source))+' of field ['+path+']'};
       break;
      }
     }
    }
    return[{captureBinderId,capturePath,captureRoot:Object.keys(t.relations).find(r=>t.relations[r]===1)??'Unknown',child,relation:relation(mask),guards:e.args.flatMap((v,i)=>guardsOf(v,[i])),unknownReason}];
   }));
  }));
  return[...new Map(pushes.map(p=>[JSON.stringify(p),p])).values()];
 }
 for(const name of graph.signatures.keys()){cursorInputs(name);cursorResults(name);}
 return{summaries,transitions,iterations,cursorInputs,cursorResults,cursorPushes,fieldRelationOf(name,fromPath,toPath,branch){
  let mask=0;
  for(const value of seeds.get(name)?.flatMap(c=>c.outputs)??[]){
   const d=branch&&at(value,branch.path);if(branch&&d?.kind==='ctor'&&d.tag!==branch.constructor)continue;
   mask|=fieldMask(value,fromPath,toPath);
  }
  return relation(mask);
 },relationOf(name,input,path,branch){
  const sig=graph.signatures.get(name),id=sig?.parameters[input]?.[2];let mask=0;
  for(const value of seeds.get(name)?.flatMap(c=>c.outputs)??[]){
   const d=branch&&at(value,branch.path);
   if(branch&&d?.kind==='ctor'&&d.tag!==branch.constructor)continue;
   const v=at(value,path);
   if(v?.kind==='token'){
    const qs=Object.entries(v.relations).filter(([r])=>r===name+':'+id+':'+input||r.startsWith(name+':'+id+':'+input+'.'));
    mask|=qs.length?qs.reduce((m,[,q])=>m|q,0):7;
   }else if(v||value.kind==='unknown')mask|=7;
  }
  return relation(mask);
 }};
}
