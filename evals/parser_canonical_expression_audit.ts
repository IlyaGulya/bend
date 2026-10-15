#!/usr/bin/env bun
/** Native per-expression checks supplement first-error whole-body diagnostics.
 * Pattern contexts come from native constructor telescopes, not the CPS typer. */
import * as B from "../bend2/bend.ts";
import { readParserGraph } from "./parser_full_graph.ts";
import { createHash } from "node:crypto";
import { readFileSync,writeFileSync } from "node:fs";
import { resolve } from "node:path";
const input=resolve(import.meta.dir,"../bend2/selfhost/parser.bend");
const source=readFileSync(input,"utf8"), graph=await readParserGraph(source);
const book:B.Book={...graph.parserBook,tlds:{...graph.parserBook.tlds}};
for(const[name,sig]of graph.signatures)book.tlds[name]={$:"Def",n:sig.parameters.length,T:B.term_higher(B.tele_bind(sig.parameters,sig.result)),v:null,b:true};
const lhs:B.LHS={t:B.Ref("canonical_expression_audit"),n:0,def:"canonical_expression_audit",qs:[]};
type Scope={ctx:B.Ctx;env:B.Env;next:number};
type Finding={function:string;category:string;line:number|null;beg:number|null;end:number|null;expression:string;expectedType?:string;diagnostic:string;family?:string};
const findings:Finding[]=[],pairs:Record<string,unknown>[]=[];
const tupleRepairs:Record<string,unknown>[]=[];
const provenPairs=new Set<string>();
const imports=[...source.matchAll(/^import .*\/(\w+)\.bend as (\w+)$/gm)].map(m=>[m[1]!,m[2]!] as const);
function replaceProvenPairs(t:B.LTerm):B.LTerm{
  const[h,args]=B.term_unapply(t);
  if(h.$==="Ref"&&h.k==="Pair"&&args.length===2&&t.s&&provenPairs.has(t.s.beg+":"+t.s.end))return{$:"Ctr",k:"Tuple",x:args.map(replaceProvenPairs),s:t.s};
  const out={...t} as unknown as Record<string,unknown>;
  for(const[key,value]of Object.entries(t)){
    if(key==="s"||key==="q")continue;
    if(Array.isArray(value))out[key]=value.map(x=>x?.$?replaceProvenPairs(x):x);
    else if(value&&typeof value==="object"&&"$"in value)out[key]=replaceProvenPairs(value as B.LTerm);
  }
  return out as B.LTerm;
}
function printSource(t:B.LTerm,scope:Scope):string{
  const out=B.term_lower(B.term_higher(t,scope.env),scope.next);
  function alias(node:unknown):void{
    if(!node||typeof node!=="object")return;if(Array.isArray(node)){node.forEach(alias);return;}
    const n=node as B.LTerm;if(n.$==="Ref"||n.$==="Ctr"||n.$==="ADT")for(const[from,to]of imports)if(n.k.startsWith(from+"."))n.k=to+n.k.slice(from.length);
    for(const[key,value]of Object.entries(node))if(key!=="s"&&key!=="q")alias(value);
  }
  alias(out);const names:string[]=[];for(const[i,a]of B.pmap_to_array(scope.ctx))names[i]=a.k;
  return B.term_show(out,-1,names);
}
function show(t:B.HTerm){return B.term_show(B.term_lower(t));}
function location(t:B.LTerm){const s=t.s;return{line:s?source.slice(0,s.beg).split("\n").length:null,beg:s?.beg??null,end:s?.end??null,expression:s?source.split("\n")[source.slice(0,s.beg).split("\n").length-1]!.trim():B.term_show(t)};}
function category(e:B.Err){const d=B.err_show(e);if(/consumed more than once|affine|unrestricted|quantity/.test(d))return"E";if(/defined name|bound variable/.test(d))return"C";if(/cases for /.test(d))return"D";return"B";}
function record(name:string,t:B.LTerm,e:unknown,family?:string,goal?:B.HTerm){const err=e as B.Err;findings.push({function:name,category:err?.$==="Err"?category(err):"F",...location(t),expectedType:goal?show(goal):undefined,diagnostic:err?.$==="Err"?B.err_show(err):String(e),family});}
function bindValue(p:B.Patt,T:B.HTerm,scope:Scope,quantity:B.Quant):{scope:Scope;value:B.HTerm}{
  if(p.$==="PVar"){
    let q=quantity;
    if(p.q.$==="Many"&&q.$==="Lone"){B.term_check_kind(book,lhs,T,p.q,scope.ctx,scope.next,p.s);q=p.q;}
    const v=B.Var(p.k,p.i,p.s);return{scope:{ctx:B.ctx_bind(scope.ctx,p.i,q,p.k,T),env:B.list_set(scope.env,p.i,v),next:Math.max(scope.next,p.i+1)},value:v};
  }
  const type=B.term_wnf(book,T);if(type.$!=="ADT")throw Error("Pattern does not have a native datatype goal");
  const adt=book.tlds[type.k],ctor=book.ctrs[p.k];
  if(adt?.$!=="ADT"||!ctor||!adt.c.some(c=>c.k===p.k))throw B.Err(book,scope.ctx,"a constructor of "+type.k,p.k,p.s);
  if(p.x.length!==ctor.n)throw B.Err(book,scope.ctx,p.k+" with "+ctor.n+" fields",String(p.x.length),p.s);
  let tel=B.tele_fill(book,ctor.T,type.x,scope.ctx);let current=scope;const values:B.HTerm[]=[];
  for(const child of p.x){
    const head=B.tele_head(book,tel,current.ctx);
    const q=head.q.$==="None"?B.None():head.q.$==="Lone"?quantity:B.quant_add(quantity,quantity);
    const bound=bindValue(child,head.A,current,q);current=bound.scope;values.push(bound.value);
    tel=head.B(bound.value);
  }
  return{scope:current,value:B.Ctr(p.k,values)};
}
function bind(p:B.Patt,T:B.HTerm,scope:Scope,quantity:B.Quant=p.$==="PVar"?p.q:B.Lone()):Scope{return bindValue(p,T,scope,quantity).scope;}
function constructorGoal(t:B.LTerm,scope:Scope):B.HTerm|undefined{
  if(t.$!=="Ctr")return;
  const entry=Object.entries(book.tlds).find(([,d])=>d.$==="ADT"&&d.c.some(c=>c.k===t.k));
  if(entry?.[1].$==="ADT"&&entry[1].n===0)return B.ADT(entry[0],[],t.s);
  const tuple=book.ctrs[t.k];
  if(t.k==="Tuple"&&tuple&&t.x.length===2){const a=infer(t.x[0]!,scope),b=infer(t.x[1]!,scope);return B.App(B.App(B.Ref("Pair"),a),b);}
}
function infer(t:B.LTerm,scope:Scope):B.HTerm{
  try{return B.term_infer(book,lhs,B.term_higher(t,scope.env),B.Lone(),scope.ctx,scope.next).ty;}
  catch(e){const goal=t.$==="Var"?B.pmap_get(scope.ctx,t.i)?.T:constructorGoal(t,scope);if(!goal)throw e;B.term_check(book,lhs,B.term_higher(t,scope.env),B.Lone(),goal,scope.ctx,scope.next);return goal;}
}
function coverage(name:string,b:Extract<B.Body,{$:"Match"}>,scope:Scope):void{
  const vars:B.PVar[]=B.pmap_to_array(scope.ctx).sort((a,b)=>a[0]-b[0]).map(([i,a])=>({$:"PVar",i,k:a.k,q:a.q}));
  const shape:B.Body={...b,r:b.r.map(row=>({...row,f:{$:"Reply",x:{$:"Ctr",k:"True",x:[]}}}))};
  let next=scope.next;
  try{
    const value=B.body_flatten(shape,vars,()=>next++);
    let T:B.LTerm={$:"Ref",k:"Bool"};
    for(const[i,a]of B.pmap_to_array(scope.ctx).sort((a,b)=>b[0]-a[0]))T={$:"All",i,k:a.k,q:a.q,A:B.term_lower(a.T),B:T};
    B.term_check(book,lhs,B.term_higher(value),B.Lone(),B.term_higher(T),B.ctx_nil(),0);
  }catch(error){record(name,b.e[0]!,error,"native-match-coverage");}
}
function pairAudit(name:string,t:B.LTerm,goal:B.HTerm,scope:Scope){
  const[head,args]=B.term_unapply(t);
  const isPair=head.$==="Ref"&&head.k==="Pair"&&args.length===2;
  if(!isPair){
    try{
      if(t.$==="Ann"){pairAudit(name,t.T,B.Typ(B.Qua(B.Lone())),scope);pairAudit(name,t.x,B.term_higher(t.T,scope.env),scope);}
      else if(t.$==="Ctr"){
        const type=B.term_wnf(book,goal),ctor=book.ctrs[t.k];
        if(type.$==="ADT"&&ctor){let tel=B.tele_fill(book,ctor.T,type.x,scope.ctx);for(const child of t.x){const field=B.tele_head(book,tel,scope.ctx);pairAudit(name,child,field.A,scope);tel=field.B(B.term_higher(child,scope.env));}}
      }else if(t.$==="Lam"){
        const type=B.term_wnf(book,goal);if(type.$==="All"){const inner=bind({$:"PVar",k:t.k,i:t.i,q:t.q??type.q,s:t.s},type.A,scope);pairAudit(name,t.f,type.B(B.Var(t.k,t.i)),inner);}
      }else if(t.$==="App"){
        let tel=infer(head,scope);for(const child of args){const field=B.tele_head(book,tel,scope.ctx);pairAudit(name,child,field.A,scope);tel=field.B(B.term_higher(child,scope.env));}
      }
    }catch(error){record(name,t,error,"pair-context-unavailable",goal);}
    return;
  }
  const type=B.term_wnf(book,goal);const pos=location(t);
  if(type.$==="Typ"){pairs.push({function:name,...pos,classification:"legitimate-type-product",expectedType:show(goal)});return;}
  const tuple=type.$==="ADT"?book.tlds[type.k]:undefined;
  if(type.$!=="ADT"||tuple?.$!=="ADT"||!tuple.c.some(c=>c.k==="Tuple")){pairs.push({function:name,...pos,classification:"unknown",expectedType:show(goal)});return;}
  let diagnostic="";try{B.term_check(book,lhs,B.term_higher(t,scope.env),B.Lone(),goal,scope.ctx,scope.next);}catch(e){diagnostic=(e as B.Err).$==="Err"?B.err_show(e as B.Err):String(e);}
  if(diagnostic&&t.s)provenPairs.add(t.s.beg+":"+t.s.end);
  pairs.push({function:name,...pos,classification:diagnostic?"confirmed-runtime-value-misuse":"unknown",expectedType:show(goal),diagnostic,intendedTupleNesting:B.term_show({$:"Ctr",k:"Tuple",x:args.map(a=>tupleValue(a)),s:t.s}),ast:B.term_show(t)});
  const ctor=book.ctrs.Tuple!;let tel=B.tele_fill(book,ctor.T,type.x,scope.ctx);
  for(const arg of args){const field=B.tele_head(book,tel,scope.ctx);pairAudit(name,arg,field.A,scope);tel=field.B(B.term_higher(tupleValue(arg),scope.env));}
}
function tupleValue(t:B.LTerm):B.LTerm{const[h,a]=B.term_unapply(t);return h.$==="Ref"&&h.k==="Pair"&&a.length===2?{$:"Ctr",k:"Tuple",x:a.map(tupleValue),s:t.s}:t;}
function checkResourceUses(name:string,t:B.LTerm,uses:B.Uses,scope:Scope):void{
  for(const[i,used]of B.pmap_to_array(uses)){
    if(used.$==="None")continue;
    const a=B.pmap_get(scope.ctx,i);
    if(!a){record(name,t,Error("Native expression usage escapes its lexical context"),"expression-resource-context");continue;}
    try{B.quant_used(book,scope.ctx,a.k,a.q,used,t.s,name);}catch(error){record(name,t,error,"native-expression-resource-usage");}
  }
}
function walk(name:string,b:B.Body,scope:Scope,goal:B.HTerm):void{
  if(b.$==="Reply"){
    pairAudit(name,b.x,goal,scope);
    const changed=replaceProvenPairs(b.x);
    if(b.s&&printSource(changed,scope)!==printSource(b.x,scope)){
      let afterDiagnostic:string|null=null;
      try{B.term_check(book,lhs,B.term_higher(changed,scope.env),B.Lone(),goal,scope.ctx,scope.next);}catch(error){afterDiagnostic=(error as B.Err).$==="Err"?B.err_show(error as B.Err):String(error);}
      const before=source.slice(b.s.beg,b.s.end),tail=/\s*$/.exec(before)![0];
      tupleRepairs.push({function:name,beg:b.s.beg,end:b.s.end,line:source.slice(0,b.s.beg).split("\n").length,before,after:printSource(changed,scope)+tail,expectedType:show(goal),afterDiagnostic});
    }
    try{const checked=B.term_check(book,lhs,B.term_higher(b.x,scope.env),B.Lone(),goal,scope.ctx,scope.next);checkResourceUses(name,b.x,checked.us,scope);}catch(e){record(name,b.x,e,undefined,goal);}return;
  }
  if(b.$==="Local"){
    let inner=scope;
    for(let i=0;i<b.v.length;i++){
      const value=b.v[i]!;try{
        const pattern=b.k[i]!,quantity=pattern.$==="PVar"?B.quant_join(b.q,pattern.q):b.q;
        const demand=B.quant_dem(quantity,B.Lone());
        try{const inferred=B.term_infer(book,lhs,B.term_higher(value,scope.env),demand,scope.ctx,scope.next);checkResourceUses(name,value,inferred.us,scope);}catch(e){record(name,value,e,"local-constructor-needs-annotation");}
        const type=infer(value,scope);B.term_check_kind(book,lhs,type,quantity,scope.ctx,scope.next,pattern.s);inner=bind(pattern,type,inner,quantity);
      }catch(e){record(name,value,e,"local-context-unavailable");return;}
    }walk(name,b.f,inner,goal);return;
  }
  coverage(name,b,scope);
  const types:B.HTerm[]=[];for(const e of b.e)try{types.push(infer(e,scope));}catch(error){record(name,e,error,"scrutinee-context-unavailable");return;}
  for(const row of b.r){let inner=scope;try{for(let i=0;i<row.p.length;i++){const e=b.e[i]!;if(e.$!=="Var")throw Error("Native scoped resource audit requires a parameter/field scrutinee");const a=B.pmap_get(scope.ctx,e.i);if(!a)throw Error("Native scrutinee is absent from its lexical context");const q=b.r.reduce((q,r)=>r.p[i]!.$==="PVar"?B.quant_join(q,(r.p[i] as B.PVar).q):q,a.q);const bound=bindValue(row.p[i]!,types[i]!,inner,q);inner={...bound.scope,env:B.list_set(bound.scope.env,e.i,bound.value)};}walk(name,row.f,inner,goal);}catch(error){record(name,b.e[0]!,error,"pattern-context-unavailable");}}
}
for(const[name,sig]of graph.signatures){let scope:Scope={ctx:B.ctx_nil(),env:null,next:0};for(const[q,k,i,T,s]of sig.parameters)scope=bind({$:"PVar",q,k,i,s},B.term_higher(T,scope.env),scope);walk(name,graph.bodies.get(name)!,scope,B.term_higher(sig.result,scope.env));}
const report={sourceSha256:createHash("sha256").update(source).digest("hex"),method:"Native term_check on each Reply under original result type; native constructor telescope pattern types and field demands; native quant_used validates each expression's returned usage map; native-checked constructor hypotheses remain explicit annotation defects.",limits:["Per-expression resource checks do not account for sequential or match-scrutinee usage across the complete Body; whole-body checks remain required.","Match coverage is independently native-checked with original patterns and constant branch bodies.","Native-checked local constructor hypotheses are explicit recorded source annotation defects, not silently accepted source."],findings,pairs,counts:Object.fromEntries(["A","B","C","D","E","F"].map(c=>[c,findings.filter(f=>f.category===c).length]))};
Object.assign(report,{tupleRepairs});
const output=resolve(import.meta.dir,"../bend2/selfhost/parser.bend.canonical-expression-audit.json");writeFileSync(output,JSON.stringify(report,null,2)+"\n");console.log(JSON.stringify({output,counts:report.counts,pairs:pairs.length,confirmedPairs:pairs.filter(p=>p.classification==="confirmed-runtime-value-misuse").length}));
