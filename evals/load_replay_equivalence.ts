#!/usr/bin/env bun
import * as B from '../bend2/bend.ts';
import * as Comp from '../bend2/comp.ts';
import {fixtures as basic} from './load_replay_basic_fixtures.ts';
import {fixtures as binding} from './load_replay_binding_fixtures.ts';
import type {ReplayFixture} from './load_replay_fixture_types.ts';
import {replayKernel,checkFrozen,frozen} from './load_replay_kernel.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {mkdtemp,writeFile,rm} from 'node:fs/promises';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {spawnSync} from 'node:child_process';
await guardHeavyGate(import.meta.path,{label:'small historical/direct replay equivalence'});
const reportPath='checkpoints/load-replay-equivalence.json';
const reports:object[]=[];
function need(ok:unknown,message:string):asserts ok {if(!ok)throw Error(message);}
function errorText(error:unknown){return error&&typeof error==='object'&&'$'in error&&error.$==='Err'?B.err_show(error as B.Err):String(error);}
function serialized(term:unknown,spans=false){return JSON.stringify(term,(key,value)=>key==='s'&&!spans?undefined:typeof value==='bigint'?value+'n':value);}
function run(command:string,args:string[]){const child=spawnSync(command,args,{encoding:'utf8',timeout:60000,maxBuffer:16*1024*1024});need(child.status===0,'Execution failed '+command+': '+child.stderr);return{status:child.status,stdout:child.stdout,stderr:child.stderr};}
const fixtures:ReplayFixture[]=[...basic,...binding,{
 name:'binding-share-cell-and-span-reference',features:['share-cell','spans','earlier-definition-reference'],
 source:'import Base\ndef earlier() -> Nat:\n  17n\ndef main() -> Nat:\n  earlier()\n',expected:'17n',
 rawOverrides:{main:K=>{const s={src:'share-cell-span-fixture',beg:0,end:5};return K.Var<[B.LTerm]>('cell',-1,s,K.Ref<[B.LTerm]>('earlier',s));}}
}, {
 name:'negative-affine-repeated-consumption',features:['affine-ownership-rejection'],
 source:'import Base\ntype Resource is Type:\n  Resource{value: Nat}\ndef consume(resource: Resource) -> Nat:\n  match resource:\n    case Resource{value}: value\ndef bad(resource: Resource) -> Nat:\n  Nat.add(consume(resource), consume(resource))\ndef main() -> Nat:\n  bad(Resource{7n})\n',expected:'',expectedError:'consumed more than once'
}];
const historical=await replayKernel('historical'),direct=await replayKernel('direct');
let current='';
try{
 for(const fixture of fixtures){current=fixture.name;const directory=await mkdtemp(join(tmpdir(),'bend-replay-fixture-'));
  try{
   const input=join(directory,'main.bend');await writeFile(input,fixture.source);
   const variants=[];
   for(const [mode,handle]of [['historical',historical],['direct',direct]] as const){
    const K=handle.kernel,book=K.book_nil();await K.book_load(book,input,'',new Map());
    for(const[name,make]of Object.entries(fixture.rawOverrides??{})){const def=book.tlds[name];need(def?.$==='Def','Missing injected fixture definition '+name);const first=K.term_higher(make(K));def.v=mode==='direct'?first:K.term_higher(K.term_lower(first));}
    let typeError:string|null=null;try{K.book_valid(book);}catch(error){typeError=errorText(error);}
    variants.push({mode,K,book,typeError});
   }
   need((variants[0].typeError===null)===(variants[1].typeError===null),'SEMANTIC DIFFERENCE native book_valid '+fixture.name);
   if(fixture.expectedError){need(variants.every(v=>v.typeError?.includes(fixture.expectedError!)),'Expected ownership rejection missing '+fixture.name);reports.push({name:fixture.name,features:fixture.features,status:'PASS',expectedRejection:true,errors:variants.map(v=>v.typeError)});continue;}
   need(variants.every(v=>v.typeError===null),'INVALID_HISTORICAL_FIXTURE '+fixture.name+': '+variants.map(v=>v.typeError).join('\n'));
   const names=[...fixture.source.matchAll(/^def ([\w.]+)/gm)].map(m=>m[1]);
   const lowered=variants.map(({K,book})=>Object.fromEntries(names.map(name=>{const def=book.tlds[name];need(def?.$==='Def'&&def.v!==null,'Fixture body missing '+name);return[name,K.term_lower(def.v)];})));
   need(serialized(lowered[0])===serialized(lowered[1]),'SEMANTIC DIFFERENCE lowered LTerm '+fixture.name);
   const comparisons=names.map(name=>{const a=variants[0].book.tlds[name],b=variants[1].book.tlds[name];need(a.$==='Def'&&b.$==='Def'&&a.v!==null&&b.v!==null,'Definition comparison prerequisite');return{name,historicalBook:variants[0].K.term_compare('EQ',variants[0].book,a.v,b.v),directBook:variants[1].K.term_compare('EQ',variants[1].book,a.v,b.v)};});
   need(comparisons.every(c=>c.historicalBook&&c.directBook),'SEMANTIC DIFFERENCE native term_compare '+fixture.name);
   const outcomes=[];
   for(const {mode,K,book}of variants){
    const main=book.tlds.main;need(main?.$==='Def'&&main.v!==null,'Main missing');
    const native=K.term_show(K.term_lower(K.term_snf(book,K.Ref('main'))));
    const wnf=K.term_wnf(book,K.Ref('main'));
    const lhs={t:K.Ref('$fixture-probe'),n:0,def:'$fixture-probe',qs:[]};
    const inferred=K.term_infer(book,lhs,K.Ref('main'),K.Lone(),K.ctx_nil(),0);
    need(K.term_compare('EQ',book,inferred.ty,K.Ref('Nat')),'Native term_infer wrong scalar type '+fixture.name);
    const checked=K.term_check(book,lhs,K.Ref('main'),K.Lone(),K.Ref('Nat'),K.ctx_nil(),0);
    need(K.term_show(K.term_lower(K.term_snf(book,K.term_higher(checked.tm))))===fixture.expected,'Native term_check wrong behavior '+fixture.name);
    const js=join(directory,mode+'.js'),c=join(directory,mode+'.c'),executable=join(directory,mode);
    await writeFile(js,Comp.js_book(book));await writeFile(c,Comp.compile_book(book));
    const jsRuntime=run(process.execPath,[js]);run(process.env.CC??'cc',['-std=c11','-O1',c,'-lpthread','-lm','-o',executable]);const cRuntime=run(executable,['--threads','1','--gpu','off']);
    need(native===fixture.expected,'SEMANTIC DIFFERENCE native oracle '+fixture.name+' '+mode+': '+native);
    for(const [backend,result]of [['JS',jsRuntime],['C',cRuntime]] as const)need(result.stdout.trim()===fixture.expected,'SEMANTIC DIFFERENCE '+backend+' oracle '+fixture.name+' '+mode+': '+result.stdout);
    outcomes.push({mode,bookValid:'PASS',native,wnfKind:wnf.$,termInfer:'PASS',termCheck:'PASS',jsRuntime,cRuntime});
   }
   reports.push({name:fixture.name,features:fixture.features,status:'PASS',loweredSyntaxEqual:true,loweredSpansEqual:serialized(lowered[0],true)===serialized(lowered[1],true),comparisons,outcomes});
   await Bun.write(reportPath,JSON.stringify({status:'RUNNING',completed:reports.length,fixtures:reports,frozen},null,2)+'\n');console.log(JSON.stringify({fixture:fixture.name,status:'PASS'}));
  }finally{await rm(directory,{recursive:true,force:true});}
 }
 await checkFrozen();await Bun.write(reportPath,JSON.stringify({status:'PASS',count:reports.length,fixtures:reports,frozen},null,2)+'\n');
}catch(error){await Bun.write(reportPath,JSON.stringify({status:'FAIL',firstFailure:current,error:errorText(error),fixtures:reports,frozen},null,2)+'\n');throw error;}
finally{historical.close();direct.close();}
