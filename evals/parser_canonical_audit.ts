#!/usr/bin/env bun
/** Independent native body audit. Signature-only globals are explicitly marked
 * base declarations in this private book; no source body is assumed valid. */
import { createHash } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import * as B from "../bend2/bend.ts";
import { readParserGraph } from "./parser_full_graph.ts";

const input = resolve(import.meta.dir, "../bend2/selfhost/parser.bend");
const source = readFileSync(input, "utf8");
const graph = await readParserGraph(source);
const book: B.Book = {...graph.parserBook, tlds:{...graph.parserBook.tlds}};
for (const [name, signature] of graph.signatures) {
  const T = signature.parameters.reduceRight<B.LTerm>((body,[q,k,i,A,s]) => ({$:"All",q,k,i,A,B:body,s}),signature.result);
  book.tlds[name] = {$:"Def",n:signature.parameters.length,T:B.term_higher(T),v:null,b:true};
}
function classify(error: unknown) {
  if (!error || typeof error !== "object" || !("$" in error) || error.$ !== "Err") return "F";
  const err = error as B.Err;
  const text = typeof err.exp === "string" ? err.exp : "";
  if (/consumed more than once/.test(B.err_show(err))) return "E";
  if (/cases for |exhaust|impossible|empty|constructor.*case/.test(text)) return "D";
  if (/decreasing self-call|filled definition/.test(text)) return "A";
  if (/defined name|bound variable/.test(text)) return "C";
  if (/consum|use|affine|quantity|unrestricted/.test(text)) return "E";
  if (/parameter or field scrutinee/.test(text)) return "F";
  return "B";
}
function check(name: string) {
  const signature = graph.signatures.get(name)!;
  const body = graph.bodies.get(name)!;
  let next = 0;
  function reserve(node: unknown): void {
    if (!node || typeof node !== "object") return;
    if (Array.isArray(node)) {node.forEach(reserve);return;}
    for (const [key,value] of Object.entries(node)) {
      if(key === "s" || key === "q")continue;
      if(key === "i")for(const id of Array.isArray(value)?value:[value]){if(typeof id === "number")next=Math.max(next,id+1);}
      else reserve(value);
    }
  }
  reserve(body);signature.parameters.forEach(p=>{next=Math.max(next,p[2]+1);reserve(p[3]);});
  const pairs: {line:number;beg:number;end:number;expression:string}[]=[];
  function collect(node: unknown):void {
    if(!node||typeof node!=="object")return;
    if(Array.isArray(node)){node.forEach(collect);return;}
    const term=node as B.LTerm;
    if(term.$ === "App"){
      const [head,args]=B.term_unapply(term);
      if(head.$ === "Ref"&&head.k === "Pair"&&args.length===2&&term.s){
        pairs.push({line:source.slice(0,term.s.beg).split("\n").length,beg:term.s.beg,end:term.s.end,expression:source.slice(term.s.beg,term.s.end)});
      }
    }
    for(const[key,value]of Object.entries(node))if(key!=="s"&&key!=="q")collect(value);
  }
  collect(body);
  try {
    const parameters: B.PVar[] = signature.parameters.map(([q,k,i,,s])=>({$:"PVar",q,k,i,s}));
    const value = B.body_flatten(body,parameters,()=>next++);
    const declaration=book.tlds[name] as B.Def;
    // A sentinel lhs deliberately excludes source recursion/decrease rules.
    B.term_check(book,{t:B.Ref("canonical_body_audit"),n:0,def:"canonical_body_audit",qs:[]},B.term_higher(value),B.Lone(),declaration.T,B.ctx_nil(),0);
    return {name,status:"PASS",pairs};
  } catch(error) {
    const err=error as B.Err;
    return {name,status:"FAIL",category:classify(error),diagnostic:err?.$==="Err"?B.err_show(err):String(error),span:err?.spn?{beg:err.spn.beg,end:err.spn.end,line:source.slice(0,err.spn.beg).split("\n").length}:null,pairs};
  }
}
if(process.argv.includes("--worker")) {
  const name=process.argv[process.argv.indexOf("--worker")+1]!;
  console.log(JSON.stringify(check(name)));
} else if(process.argv.includes("--batch")) {
  console.log(JSON.stringify({ready:true}));
  for(const name of process.argv.slice(process.argv.indexOf("--batch")+1))console.log(JSON.stringify(check(name)));
} else {
  const results: Record<string,unknown>[]=[];
  await Promise.all(Array.from({length:2},async(_,shard)=>{
    let pending=graph.definitions.filter((_,i)=>i%2===shard);
    while(pending.length){
      const child=Bun.spawn([process.execPath,import.meta.path,"--batch",...pending],{stdout:"pipe",stderr:"pipe"});
      let timedOut=false;
      let timer=setTimeout(()=>{timedOut=true;child.kill();},60000);
      const stderrPromise=new Response(child.stderr).text();
      const decoder=new TextDecoder();let buffered="",completed=0,ready=false;
      for await(const chunk of child.stdout){
        buffered+=decoder.decode(chunk,{stream:true});
        let end:number;
        while((end=buffered.indexOf("\n"))!==-1){
          const line=buffered.slice(0,end);buffered=buffered.slice(end+1);if(!line)continue;
          const result=JSON.parse(line);
          if(result.ready)ready=true;else{if(result.name!==pending[completed])throw Error("Audit worker ordering drift");results.push(result);completed++;}
          clearTimeout(timer);timer=setTimeout(()=>{timedOut=true;child.kill();},30000);
        }
      }
      await child.exited;clearTimeout(timer);const stderr=await stderrPromise;
      pending=pending.slice(completed);
      if(pending.length){const name=pending.shift()!;results.push({name,status:"FAIL",category:"F",diagnostic:timedOut?ready?"Native body check timed out (30s after shared source AST loading)":"Source AST loading timed out (60s)":stderr||"Worker returned no JSON"});}
    }
  }));
  results.sort((a,b)=>String(a.name).localeCompare(String(b.name)));
  const counts=Object.fromEntries(["A","B","C","D","E","F"].map(category=>[category,results.filter(r=>r.category===category).length]));
  const report={sourceSha256:createHash("sha256").update(source).digest("hex"),method:"Native body_flatten + term_check against all declared signature-only globals; private base flags permit opaque references; sentinel lhs excludes recursion restrictions. Original parameter/pattern quantities retained.",limits:["One first native diagnostic per body; additional defects may be masked.","Worker timeout is category F, never validity.","Signature declarations are assumptions checked separately by subsequent audit extensions; no termination or source parity claim."],definitions:graph.definitions.length,passed:results.filter(r=>r.status==="PASS").length,counts,unresolvedReferences:graph.unresolvedReferences,results};
  const output=resolve(import.meta.dir,"../bend2/selfhost/parser.bend.canonical-audit.json");
  writeFileSync(output,JSON.stringify(report,null,2)+"\n");
  console.log(JSON.stringify({output,definitions:report.definitions,passed:report.passed,counts}));
}
