#!/usr/bin/env bun
/** Plan-only ownership repairs:
 *   bun evals/parser_canonical_ownership_repair.ts --output /tmp/ownership.json
 *   --only name1,name2 limits diagnostics; --candidate includes proposed source.
 *   --function-timeout-ms name:60000 bounds only a known expensive body.
 *   --expect-sha256 HASH rejects stale input before any audit/proposal.
 * Every edit is tied to sourceSha256: reject stale plans before applying edits.
 * Kind(&2) proof is native; a later first error is NOT a whole-body PASS.
 * Workers bound native match expansion; timeout is never validity. */
import {createHash} from "node:crypto";
import {readFileSync, writeFileSync} from "node:fs";
import {resolve} from "node:path";
import {createInterface} from "node:readline";
import {Readable} from "node:stream";
import * as B from "../bend2/bend.ts";
import {readParserGraph, type ParserGraph} from "./parser_full_graph.ts";

type SpanEdit={beg:number;end:number;before:string;after:string};
type GeneratedOrigin={nativeBinder:string;nativeBinderSpan:{beg:number;end:number};sourcePatternText:string;constructorPath:string[];scrutinee:string;formalIndex:number;rule:string};
type Proof={function:string;binder:string;kind:string;sourceSpan:{beg:number;end:number;line:number};sourceText:string;edit:SpanEdit;diagnostic:string;diagnosticSpan:{beg:number;end:number}|null;type:string;kindProof:string;generatedOrigin?:GeneratedOrigin;after:Outcome};
type Outcome={status:"PASS"|"FAIL";category?:string;diagnostic?:string;span?:{beg:number;end:number}|null};
type Binder={name:string;kind:string;s:B.Span;diagnosticSpan:B.Span;quantity:()=>B.Quant;promote:()=>void};
type DomainWitness={T:B.HTerm;ctx:B.Ctx;d:number};
type WorkerResult={name:string;before:Outcome;after:Outcome;proofs:Proof[];limitations:string[];lastPhase?:string;pendingProposal?:{binder:string;span:{beg:number;end:number};type:string;kindProof:string}};
type WorkerProcess={stdin:{write(data:string):unknown};stdout:ReadableStream<Uint8Array>;kill():void};
const lhs:B.LHS={t:B.Ref("canonical_ownership_repair"),n:0,def:"canonical_ownership_repair",qs:[]};
const argument=(key:string,fallback:string)=>{const i=process.argv.indexOf(key);return i<0?fallback:process.argv[i+1]!;};
const errorText=(e:unknown)=>(e as B.Err)?.$==="Err"?B.err_show(e as B.Err):String(e);
function outcome(e?:unknown):Outcome {
  if(e===undefined)return{status:"PASS"};
  const err=e as B.Err, diagnostic=errorText(e);
  const category=/consumed more than once/.test(diagnostic)?"E":err?.$!=="Err"?"F":/defined name|bound variable/.test(diagnostic)?"C":/cases for |exhaust|impossible|empty|constructor.*case/.test(typeof err.exp==="string"?err.exp:"")?"D":/parameter or field scrutinee/.test(diagnostic)?"F":"B";
  return{status:"FAIL",category,diagnostic,span:err?.spn?{beg:err.spn.beg,end:err.spn.end}:null};
}
const key=(s:{beg:number;end:number})=>s.beg+":"+s.end;
function reserve(node:unknown):number {
  let next=0;
  function visit(n:unknown):void {
    if(!n||typeof n!=="object")return;
    if(Array.isArray(n)){n.forEach(visit);return;}
    for(const[k,v]of Object.entries(n)){
      if(k==="s"||k==="q")continue;
      if(k==="i")for(const i of Array.isArray(v)?v:[v]){if(typeof i==="number")next=Math.max(next,i+1);}
      else visit(v);
    }
  }
  visit(node);return next;
}

async function worker(source:string,name:string,marks:SpanEdit[],repair:boolean,graph:ParserGraph):Promise<WorkerResult> {
  const binders:Binder[]=[];
  for(const[fn,sig]of graph.signatures){
    for(const p of sig.parameters){
      const[,k,,,s]=p;
      if(fn===name)binders.push({name:k,kind:"formal",s,diagnosticSpan:s,quantity:()=>p[0],promote:()=>{p[0]=B.Many();}});
      if(marks.some(m=>m.beg===s.beg&&m.end===s.end))p[0]=B.Many();
    }
  }
  function add(p:B.PVar,kind:string,diagnosticSpan=p.s):void {
    if(!p.s||!diagnosticSpan)return;
    binders.push({name:p.k,kind,s:p.s,diagnosticSpan,quantity:()=>p.q,promote:()=>{p.q=B.Many();}});
  }
  function visit(n:unknown):void {
    if(!n||typeof n!=="object")return;
    if(Array.isArray(n)){n.forEach(visit);return;}
    const t=n as B.LTerm;
    if(t.$==="Lam"&&t.s){
      binders.push({name:t.k,kind:"lambda",s:t.s,diagnosticSpan:t.s,quantity:()=>t.q??B.Lone(),promote:()=>{t.q=B.Many();}});
    }
    const pattern=n as B.Patt,statement=n as B.Body;
    if(pattern.$==="PVar")add(pattern,"pattern");
    if(statement.$==="Local"){
      const b=statement;
      for(const p of b.k)if(p.$==="PVar")add(p,"local",b.k[0]?.s);
      b.v.forEach(visit);visit(b.f);return;
    }
    if(t.$==="Let"){
      // Expression-level lets share one native diagnostic span. Source Body
      // locals carry individual binder spans; unsupported expression lets are
      // deliberately not guessed from occurrences in the value/body.
      t.v.forEach(visit);visit(t.f);return;
    }
    for(const[k,v]of Object.entries(n))if(k!=="s"&&k!=="q")visit(v);
  }
  const body=graph.bodies.get(name)!;visit(body);
  for(const b of binders)if(marks.some(m=>m.beg===b.s.beg&&m.end===b.s.end))b.promote();
  const book:B.Book={...graph.parserBook,tlds:{...graph.parserBook.tlds}};
  function signatures():void {
    for(const[fn,sig]of graph.signatures)book.tlds[fn]={$:"Def",n:sig.parameters.length,T:B.term_higher(B.tele_bind(sig.parameters,sig.result)),v:null,b:true};
  }
  signatures();
  const sig=graph.signatures.get(name)!;
  let lastFlat:B.LTerm|undefined;
  function flatten():B.HTerm {
    let next=Math.max(reserve(body),reserve(sig.parameters),reserve(sig.result),...sig.parameters.map(p=>p[2]+1));
    const ps:B.PVar[]=sig.parameters.map(([q,k,i,,s])=>({$:"PVar",q,k,i,s}));
    lastFlat=B.body_flatten(body,ps,()=>next++);
    return B.term_higher(lastFlat);
  }
  function check():{result:Outcome;term?:B.HTerm;flat?:B.LTerm;error?:unknown} {
    let term:B.HTerm|undefined;lastFlat=undefined;
    try{term=flatten();B.term_check(book,lhs,term,B.Lone(),(book.tlds[name] as B.Def).T,B.ctx_nil(),0);return{result:outcome(),term,flat:lastFlat};}
    catch(error){return{result:outcome(error),term,flat:lastFlat,error};}
  }
  // Raw source path avoids expanding every unrelated match alternative merely
  // to obtain a named pattern binder's domain. Contexts are built from native
  // scrutinee inference and constructor telescopes; no generator type state.
  function sourceDomain(binder:Binder):DomainWitness|undefined {
    type Scope={ctx:B.Ctx;env:B.Env;next:number};
    function contains(n:unknown):boolean{
      if(!n||typeof n!=="object")return false;
      if(Array.isArray(n))return n.some(contains);
      const p=n as B.Patt;
      if(p.$==="PVar"&&p.k===binder.name&&p.s&&key(p.s)===key(binder.s))return true;
      return Object.entries(n).some(([k,v])=>k!=="s"&&k!=="q"&&contains(v));
    }
    let witness:DomainWitness|undefined;
    function bind(p:B.Patt,T:B.HTerm,demand:B.Quant,scope:Scope):Scope{
      if(p.$==="PVar"){
        if(p.k===binder.name&&p.s&&key(p.s)===key(binder.s))witness={T,ctx:scope.ctx,d:scope.next};
        const q=p.q.$==="Many"&&demand.$==="Lone"?B.Many():demand;
        if(q.$!==demand.$)B.term_check_kind(book,lhs,T,q,scope.ctx,scope.next,p.s);
        return{ctx:B.ctx_bind(scope.ctx,p.i,q,p.k,T),env:B.list_set(scope.env,p.i,B.Var(p.k,p.i)),next:Math.max(scope.next,p.i+1)};
      }
      const adt=B.term_wnf(book,T),ctor=book.ctrs[p.k];
      if(adt.$!=="ADT"||!ctor)throw Error("Source binder constructor goal unavailable");
      let tel=B.tele_fill(book,ctor.T,adt.x,scope.ctx),inner=scope;
      for(const child of p.x){
        const h=B.tele_head(book,tel,inner.ctx),q=h.q.$==="None"?B.None():h.q.$==="Lone"?demand:B.quant_add(demand,demand);
        inner=bind(child,h.A,q,inner);
        tel=h.B(B.term_higher(B.patt_term(child),inner.env));
      }
      return inner;
    }
    function walk(b:B.Body,scope:Scope):void{
      if(witness)return;
      if(b.$==="Reply")return;
      if(b.$==="Local"){
        let inner=scope;
        for(let j=0;j<b.k.length;j++){
          const p=b.k[j]!;
          const type=B.term_infer(book,lhs,B.term_higher(b.v[j]!,scope.env),B.Lone(),scope.ctx,scope.next).ty;
          inner=bind(p,type,B.quant_join(b.q,p.$==="PVar"?p.q:B.Lone()),inner);
        }
        walk(b.f,inner);return;
      }
      const types=b.e.map(e=>B.term_infer(book,lhs,B.term_higher(e,scope.env),B.Lone(),scope.ctx,scope.next).ty);
      const demands=b.e.map(e=>e.$==="Var"?(B.pmap_get(scope.ctx,e.i)?.q??B.Lone()):B.Lone());
      for(const row of b.r){
        if(!contains(row))continue;
        let inner=scope;
        row.p.forEach((p,j)=>{inner=bind(p,types[j]!,demands[j]!,inner);});
        if(!witness)walk(row.f,inner);
        if(witness)return;
      }
    }
    let scope:Scope={ctx:B.ctx_nil(),env:null,next:0};
    for(const[q,k,i,A,s]of sig.parameters)scope=bind({$:"PVar",q,k,i,s},B.term_higher(A,scope.env),q,scope);
    if(!witness)walk(body,scope);
    return witness;
  }
  // Follow native goals through the already-flattened term, using native
  // inference/telescopes. No occurrence counts, generator TypeEnv or branch sum.
  function domain(tm:B.HTerm,goal:B.HTerm,binder:Binder,ctx=B.ctx_nil(),d=0):DomainWitness|undefined {
    if(tm.$==="Lam"){
      const all=B.term_wnf(book,goal);if(all.$!=="All")return;
      if(tm.k===binder.name&&tm.s&&key(tm.s)===key(binder.diagnosticSpan))return{T:all.A,ctx,d};
      const x=B.Var(tm.k,d),q=tm.q?.$==="Many"&&all.q.$==="Lone"?B.Many():all.q;
      return domain(tm.f(x),all.B(x),binder,B.ctx_bind(ctx,d,q,tm.k,all.A),d+1);
    }
    if(tm.$==="Let"){
      const types=tm.v.map(v=>B.term_infer(book,lhs,v,B.Lone(),ctx,d).ty);
      if(tm.s&&key(tm.s)===key(binder.diagnosticSpan)){
        const j=tm.k.indexOf(binder.name);if(j>=0)return{T:types[j]!,ctx,d};
      }
      for(let j=0;j<tm.v.length;j++){
        const found=domain(tm.v[j]!,types[j]!,binder,ctx,d);if(found)return found;
      }
      let inner=ctx;types.forEach((T,j)=>{inner=B.ctx_bind(inner,d+j,tm.q[j]!,tm.k[j]!,T);});
      return domain(tm.f(tm.k.map((k,j)=>B.Var(k,d+j,undefined,tm.v[j]))),goal,binder,inner,d+tm.k.length);
    }
    if(tm.$==="Mat"){
      const all=B.term_wnf(book,goal);if(all.$!=="All")return;
      const adt=B.term_wnf(book,all.A);if(adt.$!=="ADT")return;
      const ctor=book.ctrs[tm.k];if(!ctor)return;
      function fields(t:B.HTerm,n:number,xs:B.HTerm[]):B.HTerm {
        if(n===0)return all.$==="All"?all.B(B.Ctr(tm.$==="Mat"?tm.k:"",xs)):goal;
        const h=B.tele_head(book,t,ctx),q=h.q.$==="None"?B.None():h.q.$==="Lone"?all.q:B.quant_add(all.q,all.q);
        return B.All(q,h.k,h.i,h.A,x=>fields(h.B(x),n-1,[...xs,x]));
      }
      const head=fields(B.tele_fill(book,ctor.T,adt.x,ctx),ctor.n,[]);
      const found=domain(tm.h,head,binder,ctx,d);if(found)return found;
      return domain(tm.m,B.All(all.q,all.k,all.i,B.ADT(adt.k,adt.x,tm.s,[...adt.r,tm.k]),all.B),binder,ctx,d);
    }
    if(tm.$==="Ann")return domain(tm.x,tm.T,binder,ctx,d);
    if(tm.$==="App"){
      const[head,args]=B.term_unapply<B.HBody>(tm);
      let tel=B.term_infer(book,lhs,head,B.Lone(),ctx,d).ty;
      const found=domain(head,tel,binder,ctx,d);if(found)return found;
      for(const x of args){const h=B.tele_head(book,tel,ctx),inner=domain(x,h.A,binder,ctx,d);if(inner)return inner;tel=h.B(x);}
    }
    if(tm.$==="Ctr"){
      const adt=B.term_wnf(book,goal),ctor=book.ctrs[tm.k];if(adt.$!=="ADT"||!ctor)return;
      let tel=B.tele_fill(book,ctor.T,adt.x,ctx);
      for(const x of tm.x){const h=B.tele_head(book,tel,ctx),found=domain(x,h.A,binder,ctx,d);if(found)return found;tel=h.B(x);}
    }
    return;
  }
  const proofs:Proof[]=[],limitations:string[]=[];
  let current=check();const before=current.result;
  console.log(JSON.stringify({progress:true,name,before,after:before}));
  if(repair)for(let iteration=0;iteration<512&&current.result.category==="E";iteration++){
    const err=current.error as B.Err;
    const nativeName=typeof err.obs==="string"?/^(.*) \(consumed more than once\)$/.exec(err.obs)?.[1]:undefined;
    const matches=binders.filter(b=>b.name===nativeName&&b.quantity().$==="Lone"&&err.spn&&key(b.diagnosticSpan)===key(err.spn));
    let binder=matches.length===1?matches[0]:undefined;
    let generatedOrigin:GeneratedOrigin|undefined;
    if(!binder&&matches.length===0&&nativeName&&/^_\d+$/.test(nativeName)&&err.spn&&current.flat&&body.$==="Match"&&body.e.length===1&&body.e[0]?.$==="Var"){
      const scrutinee=body.e[0],formal=sig.parameters.find(p=>p[2]===scrutinee.i);
      const originSpan=err.spn;
      let flattenedBinder=false,constructorPath:string[]|undefined;
      function findFlat(n:unknown):void{
        if(!n||typeof n!=="object")return;
        if(Array.isArray(n)){n.forEach(findFlat);return;}
        const t=n as B.LTerm;
        if(t.$==="Lam"&&t.k===nativeName&&t.s&&key(t.s)===key(originSpan))flattenedBinder=true;
        for(const[k,v]of Object.entries(n))if(k!=="s"&&k!=="q")findFlat(v);
      }
      function findPattern(p:B.Patt,path:string[]):void{
        if(p.$!=="PCtr")return;
        const here=[...path,p.k];
        if(p.s&&key(p.s)===key(originSpan))constructorPath=here;
        for(const child of p.x)findPattern(child,here);
      }
      findFlat(current.flat);body.r.forEach(row=>row.p.forEach(p=>findPattern(p,[])));
      if(formal&&flattenedBinder&&constructorPath){
        binder=binders.find(b=>b.kind==="formal"&&b.name===formal[1]&&key(b.s)===key(formal[4])&&b.quantity().$==="Lone");
        if(binder)generatedOrigin={nativeBinder:nativeName,nativeBinderSpan:{beg:originSpan.beg,end:originSpan.end},sourcePatternText:source.slice(originSpan.beg,originSpan.end),constructorPath,scrutinee:scrutinee.k,formalIndex:formal[2],rule:"Native match_flatten creates a synthetic binder for a nested constructor pattern (2748-2753); default rows reconstruct the original scrutinee with its fields (2769-2772). Promote only the traced root owning formal, after native KindMany proof."};
      }
    }
    if(!binder){limitations.push("Native ownership diagnostic has "+matches.length+" exact source binder matches and no proven root-formal origin; no guessed edit.");break;}
    const text=source.slice(binder.s.beg,binder.s.end);
    if(text.trim()!==binder.name){limitations.push("Binder span is not an unmarked identifier: "+JSON.stringify(text));break;}
    console.log(JSON.stringify({progress:true,name,before,after:current.result,phase:"Acquiring exact binder domain",pendingProposal:null}));
    let witness:DomainWitness|undefined;
    try{
      witness=binder.kind!=="lambda"?sourceDomain(binder):undefined;
      witness??=domain(current.term!,(book.tlds[name] as B.Def).T,binder);
      if(!witness)throw Error("No native goal telescope found for exact binder span");
      if(generatedOrigin){
        const ownerType=B.term_wnf(book,witness.T);
        if(ownerType.$!=="ADT"||ownerType.k!=="lexer.Token")throw Error("Generated owner is not the scoped Lexer.Token formal repair family");
      }
      B.term_check_kind(book,lhs,witness.T,B.Many(),witness.ctx,witness.d,binder.s);
    }catch(e){
      limitations.push("Kind(&2) proof unavailable: "+errorText(e));
      if(witness){
        try{
          const normalized=B.term_wnf(book,witness.T);
          B.term_check_kind(book,lhs,normalized,B.Many(),witness.ctx,witness.d,binder.s);
          limitations.push("Native normalized-domain KindMany PASS: "+B.term_show(B.term_lower(normalized))+"; raw domain "+B.term_show(B.term_lower(witness.T))+". Raw checker goal remains unproved; no source marker proposed.");
        }catch(normalizedError){
          limitations.push("Normalized-domain KindMany also unavailable: "+errorText(normalizedError));
        }
      }
      break;
    }
    console.log(JSON.stringify({progress:true,name,before,after:current.result,phase:"Native KindMany proved; whole-body after-check pending",pendingProposal:{binder:binder.name,span:{beg:binder.s.beg,end:binder.s.end},type:B.term_show(B.term_lower(witness.T)),kindProof:"Native term_check_kind returned successfully; not an emitted edit until native whole-body after-check returns"}}));
    const diagnostic=current.result.diagnostic!,diagnosticSpan=current.result.span??null;
    binder.promote();signatures();
    const after=check();
    // Exact native obligation must disappear. A different first diagnostic is
    // evidence of progress, NOT a whole-body PASS or complete ownership proof.
    const afterError=after.error as B.Err|undefined;
    if(after.result.category==="E"&&afterError?.obs===err.obs&&JSON.stringify(after.result.span)===JSON.stringify(diagnosticSpan)){
      limitations.push("Quantity promotion did not discharge the exact native diagnostic; proposal rejected.");break;
    }
    const edit={beg:binder.s.beg,end:binder.s.end,before:text,after:"+"+text};
    proofs.push({function:name,binder:binder.name,kind:generatedOrigin?"generated-field-owner-formal":binder.kind,sourceSpan:{beg:edit.beg,end:edit.end,line:source.slice(0,edit.beg).split("\n").length},sourceText:text,edit,diagnostic,diagnosticSpan,type:B.term_show(B.term_lower(witness.T)),kindProof:"Native term_check_kind(domain, Many, exact native lexical context) returned successfully",...(generatedOrigin?{generatedOrigin}:{}),after:after.result});
    console.log(JSON.stringify({progress:true,name,before,after:after.result,proof:proofs[proofs.length-1]}));
    current=after;
  }
  return{name,before,after:current.result,proofs,limitations};
}

if(process.argv.includes("--worker")){
  let source="",graph:ParserGraph|undefined;
  let restore:()=>void=()=>{};
  for await(const line of createInterface({input:process.stdin})){
    const request=JSON.parse(line);
    if(request.source!==undefined){
      source=request.source;graph=await readParserGraph(source);
      const originalParameters=[...graph.signatures.values()].flatMap(s=>s.parameters.map(p=>({p,q:p[0]})));
      const resets:Array<()=>void>=[];
      function remember(n:unknown):void{
        if(!n||typeof n!=="object")return;
        if(Array.isArray(n)){n.forEach(remember);return;}
        const t=n as B.LTerm;
        const pattern=n as B.Patt;
        if(t.$==="Lam"||pattern.$==="PVar"){
          const binder=t.$==="Lam"?t:pattern;
          const original=binder.q;
          resets.push(()=>{if(original===undefined)delete binder.q;else binder.q=original;});
        }
        for(const[k,v]of Object.entries(n))if(k!=="s"&&k!=="q")remember(v);
      }
      graph.bodies.forEach(remember);
      restore=()=>{
        for(const{p,q}of originalParameters)p[0]=q;
        resets.forEach(reset=>reset());
      };
      console.log(JSON.stringify({ready:true}));continue;
    }
    if(!graph)throw Error("Worker missing source snapshot");
    restore();
    console.log(JSON.stringify(await worker(source,request.name,request.marks,request.repair,graph)));
  }
}else{
  const path=resolve(argument("--source",resolve(import.meta.dir,"../bend2/selfhost/parser.bend")));
  const source=readFileSync(path,"utf8");
  const sha=createHash("sha256").update(source).digest("hex");
  const expected=argument("--expect-sha256",sha);
  if(expected!==sha)throw Error("Stale ownership input: expected "+expected+", received "+sha);
  const outputPath=argument("--output","");
  if(outputPath&&[path,resolve(import.meta.dir,"../bend2/selfhost/parser.bend")].includes(resolve(outputPath)))throw Error("Plan output cannot overwrite source");
  const graph=await readParserGraph(source);
  const selected=argument("--only","").split(",").filter(Boolean);
  const names=selected.length?selected:graph.definitions;
  for(const name of names)if(!graph.signatures.has(name))throw Error("Unknown definition: "+name);
  const functionDeadlines=new Map(argument("--function-timeout-ms","").split(",").filter(Boolean).map(entry=>{
    const[name,value]=entry.split(":");const milliseconds=Number(value);
    if(!graph.signatures.has(name!)||!Number.isFinite(milliseconds)||milliseconds<=0)throw Error("Invalid function timeout: "+entry);
    return[name!,milliseconds] as const;
  }));
  const deadline=Number(argument("--timeout-ms","15000"));
  const concurrency=Number(argument("--jobs","6"));
  const maxRounds=Number(argument("--rounds","4"));
  if(!Number.isInteger(concurrency)||concurrency<1||!Number.isFinite(deadline)||deadline<=0||!Number.isInteger(maxRounds)||maxRounds<1)throw Error("Positive jobs, timeout and rounds required");
  let marks:SpanEdit[]=[],proofs:Proof[]=[],initial:WorkerResult[]|undefined;
  async function wave(repair:boolean){
    const results:WorkerResult[]=[];let cursor=0;
    await Promise.all(Array.from({length:Math.min(concurrency,names.length)},async()=>{
      let child:WorkerProcess|undefined;
      let lines:AsyncIterator<string>|undefined;
      async function response(limit:number){
        let timer:NodeJS.Timeout|undefined;
        try{
          return await Promise.race([
            lines!.next().then(r=>{if(r.done)throw Error("Native worker closed output");return JSON.parse(r.value);}),
            new Promise<never>((_,reject)=>{timer=setTimeout(()=>{child!.kill();reject(Error("Native worker deadline exceeded ("+limit+"ms); no validity claim"));},limit);}),
          ]);
        }finally{clearTimeout(timer);}
      }
      try{while(cursor<names.length){
        const name=names[cursor++]!;
        const partial:WorkerResult={name,before:{status:"FAIL",category:"F"},after:{status:"FAIL",category:"F"},proofs:[],limitations:[]};
        try{
          if(!child){
            child=Bun.spawn([process.execPath,import.meta.path,"--worker"],{stdin:"pipe",stdout:"pipe",stderr:"ignore"});
            lines=createInterface({input:Readable.fromWeb(child.stdout as never)})[Symbol.asyncIterator]();
            child.stdin.write(JSON.stringify({source})+"\n");
            await response(Math.max(deadline,60000));
          }
          child.stdin.write(JSON.stringify({name,marks,repair})+"\n");
          while(true){
            const message=await response(functionDeadlines.get(name)??deadline);
            if(!message.progress){results.push(message);break;}
            partial.before=message.before;partial.after=message.after;
            if(message.proof)partial.proofs.push(message.proof);
            if(message.phase)partial.lastPhase=message.phase;
            if("pendingProposal"in message)partial.pendingProposal=message.pendingProposal??undefined;
            if(message.proof)partial.pendingProposal=undefined;
          }
        }catch(e){
          child?.kill();child=undefined;lines=undefined;
          const failure:Outcome={status:"FAIL",category:"F",diagnostic:errorText(e)};
          results.push({...partial,before:partial.before.diagnostic?partial.before:failure,after:failure,limitations:[partial.proofs.length?"Recovered only already native-verified proposals; later worker phase incomplete, never a whole-body PASS":"No proposal recovered from incomplete worker",...(partial.lastPhase?["Incomplete phase: "+partial.lastPhase]:[])]});
        }
      }}finally{child?.kill();}
    }));return results.sort((a,b)=>a.name.localeCompare(b.name));
  }
  const rounds:Record<string,unknown>[]=[];
  for(let r=0;r<maxRounds;r++){
    const results=await wave(true);initial??=results;
    const fresh=results.flatMap(r=>r.proofs).filter(p=>!marks.some(m=>key(m)===key(p.edit)));
    proofs.push(...fresh);marks.push(...fresh.map(p=>p.edit));
    rounds.push({round:r+1,newProposals:fresh.length,results});
    if(!fresh.length)break;
  }
  // Recheck every selected body under the combined promoted signatures/binders.
  // Independent per-function passes before combination are never final proof.
  const final=await wave(false);
  marks.sort((a,b)=>a.beg-b.beg);
  for(let i=1;i<marks.length;i++)if(marks[i-1]!.end>marks[i]!.beg)throw Error("Overlapping binder edits");
  let candidate=source;
  for(const m of [...marks].reverse())candidate=candidate.slice(0,m.beg)+m.after+candidate.slice(m.end);
  const report={
    sourcePath:path,sourceSha256:sha,
    candidateSha256:createHash("sha256").update(candidate).digest("hex"),
    method:"Exact native ownership diagnostic source binder span/name, or native-flattened literal-field origin traced to its Lexer.Token root formal; native source constructor telescopes or flattened goal telescope domain; native term_check_kind Many; only binder + insertion. Formal marks also change private declared All signature. Native whole-body checking retains exclusive match joins.",
    scope:selected.length?"Selected definitions only; not a source-wide validity claim":"All source definitions",
    definitions:names.length,edits:marks,proofs,rounds,final,
    counts:{
      before:Object.fromEntries(["PASS","B","C","D","E","F"].map(c=>[c,initial!.filter(r=>c==="PASS"?r.before.status==="PASS":r.before.category===c).length])),
      after:Object.fromEntries(["PASS","B","C","D","E","F"].map(c=>[c,final.filter(r=>c==="PASS"?r.after.status==="PASS":r.after.category===c).length])),
    },
    limits:[
      "Private signature-only base globals are assumptions; sentinel lhs excludes recursion/decrease checks.",
      "Only the first whole-body error is exposed; non-ownership diagnostics can mask later ownership errors.",
      "Bounded worker timeout/stack exhaustion is category F, never PASS. Only proposals already emitted after native KindMany and whole-body recheck survive a later timeout.",
      "Expression-level let binder positions without individual source spans are not guessed.",
      "Only exact diagnosed binders or explicitly traced Lexer.Token root owners: no blanket promotion, no syntactic counting across exclusive alternatives, no copying/drop/body-value/literal rewrite.",
      "Kind proof and diagnostic discharge do not imply whole-body success; see each final outcome.",
      "The final combined AST/book audit does not replace reparsing and reauditing emitted source edits.",
    ],
    ...(process.argv.includes("--candidate")?{candidateSource:candidate}:{}),
  };
  const output=argument("--output","");if(output)writeFileSync(resolve(output),JSON.stringify(report,null,2)+"\n");
  console.log(JSON.stringify(output?{output:resolve(output),sourceSha256:report.sourceSha256,edits:marks.length,counts:report.counts}:report,null,2));
}
