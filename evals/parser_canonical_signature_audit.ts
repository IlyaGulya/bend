#!/usr/bin/env bun
import { createHash } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import * as B from "../bend2/bend.ts";
import { readParserGraph } from "./parser_full_graph.ts";
const source=readFileSync(resolve(import.meta.dir,"../bend2/selfhost/parser.bend"),"utf8");
const graph=await readParserGraph(source);
const book:B.Book={...graph.parserBook,tlds:{...graph.parserBook.tlds}};
for(const[name,sig]of graph.signatures){const T=sig.parameters.reduceRight<B.LTerm>((body,[q,k,i,A,s])=>({$:"All",q,k,i,A,B:body,s}),sig.result);book.tlds[name]={$:"Def",n:sig.parameters.length,T:B.term_higher(T),v:null,b:true};}
const lhs={t:B.Ref("canonical_signature_audit"),n:0,def:"canonical_signature_audit",qs:[]};
const results=[...graph.signatures.keys()].map(name=>{try{B.term_check(book,lhs,(book.tlds[name] as B.Def).T,B.None(),B.Typ(B.Qua(B.Lone())),B.ctx_nil(),0);return{name,status:"PASS"};}catch(e){return{name,status:"FAIL",diagnostic:(e as B.Err).$==="Err"?B.err_show(e as B.Err):String(e)};}});
const report={sourceSha256:createHash("sha256").update(source).digest("hex"),method:"Native term_check independently validates every declared complete function telescope against Type under an opaque complete-global-signature book.",results};
const output=resolve(import.meta.dir,"../bend2/selfhost/parser.bend.canonical-signature-audit.json");writeFileSync(output,JSON.stringify(report,null,2)+"\n");console.log(JSON.stringify({output,signatures:results.length,passed:results.filter(r=>r.status==="PASS").length,failures:results.filter(r=>r.status==="FAIL")}));
