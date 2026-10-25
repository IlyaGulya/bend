#!/usr/bin/env bun
/** Minimal diagnostic differential: the root candidate's inline parser
 * (b0b92b67) against the accepted external parser artifact (qp57a-4, 0e7b3c42).
 * The already-authenticated external parser is not re-authenticated here; this
 * run only observes the public parse_with_fuel result for three small sources.
 * Reduced diagnostic only: the full acceptance corpus/exports/matrix are
 * unchanged and are not narrowed or replaced by these fixtures. */
import {createHash} from 'node:crypto';
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {dirname,resolve} from 'node:path';
import {Readable} from 'node:stream';
import {createInterface} from 'node:readline';
import type {ReadableStream as NodeReadableStream} from 'node:stream/web';
import {guardHeavyGate} from './heavy_gate.ts';
import {quantityBinderFixtures} from './parser_quantity_binder_fixtures.ts';

interface ArtifactPin {path:string;sha256:string;bytes:number}
interface Span {file:unknown;beg:unknown;end:unknown}
interface AstNode {tag:string;fields:Record<string,unknown>}
interface FailureEvidence {message:unknown;expected:unknown;observed:unknown;span:Span|null;sourceSlice:string|null}
interface PatternSite {tag:unknown;key:unknown;quantity:string|null;span:Span|null}
interface ValueSite {tag:unknown;span:Span|null}
interface QuantitySite {
  path:string;tag:'BodyLocal'|'TermLam';quantity:string|null;span?:Span;
  key?:unknown;patterns?:PatternSite[];values?:ValueSite[];body?:unknown;
}
interface SideResult {
  accepted:boolean;outcome:'ParseSuccess'|'ParseFailure'|'WorkerError'|'UnexpectedResult';
  error?:string;unexpectedTag?:string;
  elapsedMs:number;resultSha256:string;rawResult:unknown;
  module?:{file:unknown;imports:number;declarations:unknown[]};
  quantitySites?:QuantitySite[];failure?:FailureEvidence;
}
interface Row {
  name:string;source:string;sourceSha256:string;expected:{construct:string;quantity:string};
  inline:SideResult;external:SideResult;
  comparison:{acceptanceSame:boolean;astSame:boolean|null;firstDifference:string|null};
}

const option=(name:string)=>process.argv.find(a=>a.startsWith('--'+name+'='))?.slice(name.length+3);
const inline=option('inline'),external=option('external');
if(!inline||!external)throw Error('Explicit --inline=<root candidate artifact> and --external=<accepted parser artifact> are required');
const reportPath=option('report')??'checkpoints/parser-inline-root-differential.json';
const receiptPath=option('receipt')??'evals/receipts/parser_inline_root_differential.json';
const fuelCells=Number(option('fuel')??2000000);
if(!Number.isSafeInteger(fuelCells)||fuelCells<0)throw Error('Invalid --fuel');
await guardHeavyGate(import.meta.path,{label:'Inline root parser vs accepted external parser minimal quantity binder differential'});

const sha256=(bytes:Uint8Array|string)=>createHash('sha256').update(bytes).digest('hex');
const pin=(path:string):ArtifactPin=>{
  const resolved=resolve(path),bytes=readFileSync(resolved);
  return {path:resolved,sha256:sha256(bytes),bytes:bytes.length};
};
const inlinePin=pin(inline),externalPin=pin(external);
const runner=pin(import.meta.path);
const fixturesModule=pin(resolve('evals/parser_quantity_binder_fixtures.ts'));
const nodeVersion=new TextDecoder().decode(Bun.spawnSync(['node','--version']).stdout).trim();

function hasProperty<K extends string>(value:object,key:K):value is Record<K,unknown>{
  return key in value;
}
const isRawCtor=(value:unknown):value is Record<string,unknown>&{$:unknown}=>
  value!==null&&typeof value==='object'&&!Array.isArray(value)&&hasProperty(value,'$');
const isNode=(value:unknown):value is AstNode=>
  value!==null&&typeof value==='object'&&!Array.isArray(value)&&
  hasProperty(value,'tag')&&typeof value.tag==='string';

function project(value:unknown):unknown{
  if(typeof value==='bigint'){
    const n=Number(value);
    if(!Number.isSafeInteger(n)||n<0)throw Error('Inexact compiled Nat');
    return n;
  }
  if(Array.isArray(value))return value.map(project);
  if(value===null||typeof value!=='object')return value;
  if(!isRawCtor(value))throw Error('Malformed compiled constructor');
  const raw=String(value.$??'');
  const tag=raw.split('.').at(-1)??raw;
  if(raw==='$NativeNat'){
    if(!hasProperty(value,'value'))throw Error('Malformed compiled Nat');
    const n=Number(value.value);
    if(!Number.isSafeInteger(n)||n<0)throw Error('Inexact compiled Nat');
    return n;
  }
  if(tag==='Nil'&&Object.keys(value).length===1)return [];
  if(tag==='Con'){
    const out:unknown[]=[];let cell:unknown=value;
    while(isRawCtor(cell)&&String(cell.$??'').split('.').at(-1)==='Con'){
      if(!hasProperty(cell,'head')||!hasProperty(cell,'tail'))throw Error('Malformed native list cell');
      out.push(project(cell.head));
      cell=cell.tail;
    }
    if(!isRawCtor(cell)||String(cell.$??'').split('.').at(-1)!=='Nil')throw Error('Malformed native list');
    return out;
  }
  const fields:Record<string,unknown>={};
  for(const [key,field] of Object.entries(value))if(key!=='$')fields[key]=project(field);
  return {tag,fields} satisfies AstNode;
}
const sortProjected=(value:unknown):unknown=>{
  if(Array.isArray(value))return value.map(sortProjected);
  if(value&&typeof value==='object'){
    const out:Record<string,unknown>={};
    for(const [key,field] of Object.entries(value).sort(([left],[right])=>left<right?-1:left>right?1:0))
      out[key]=sortProjected(field);
    return out;
  }
  return value;
};
const canonical=(value:unknown)=>JSON.stringify(sortProjected(value));
function firstDifference(left:unknown,right:unknown,path=''):string|null{
  if(Array.isArray(left)&&Array.isArray(right)){
    if(left.length!==right.length)return path+' length '+left.length+' != '+right.length;
    for(let index=0;index<left.length;index++){
      const found=firstDifference(left[index],right[index],path+'['+index+']');
      if(found)return found;
    }
    return null;
  }
  if(Array.isArray(left)||Array.isArray(right))return path+' array mismatch';
  if(left===null||right===null||typeof left!=='object'||typeof right!=='object')
    return Object.is(left,right)?null:path+' value '+JSON.stringify(left)+' != '+JSON.stringify(right);
  const leftKeys=Object.keys(left).sort(),rightKeys=Object.keys(right).sort();
  if(leftKeys.join('\u0000')!==rightKeys.join('\u0000'))return path+' keys '+leftKeys+' != '+rightKeys;
  for(const key of leftKeys){
    if(!hasProperty(left,key)||!hasProperty(right,key))return path+'.'+key+' missing';
    const found=firstDifference(left[key],right[key],path+'.'+key);
    if(found)return found;
  }
  return null;
}
const quantityLabel=(quantity:unknown):string|null=>{
  if(!isNode(quantity))return null;
  if(quantity.tag==='None')return 'None';
  if(quantity.tag==='Some')return 'Some('+(isNode(quantity.fields.value)?quantity.fields.value.tag:'?')+')';
  return quantity.tag;
};
const readSpan=(value:unknown):Span|null=>{
  if(!isNode(value)||value.tag!=='SpanOf')return null;
  const {file,beg,end}=value.fields;
  return {file,beg,end};
};
function collectQuantitySites(value:unknown,path:string,out:QuantitySite[]):void{
  if(out.length>=64)return;
  if(Array.isArray(value)){value.forEach((child,index)=>collectQuantitySites(child,path+'['+index+']',out));return;}
  if(!isNode(value))return;
  const {fields}=value;
  if(value.tag==='BodyLocal'){
    out.push({path,tag:'BodyLocal',quantity:quantityLabel(fields.quantity),span:readSpan(fields.span)??undefined,
      patterns:(Array.isArray(fields.patterns)?fields.patterns:[]).map((pattern:unknown)=>({
        tag:isNode(pattern)?pattern.tag:null,key:isNode(pattern)?pattern.fields.key:null,
        quantity:isNode(pattern)?quantityLabel(pattern.fields.quantity):null,
        span:isNode(pattern)?readSpan(pattern.fields.span):null})),
      values:(Array.isArray(fields.values)?fields.values:[]).map((entry:unknown)=>({
        tag:isNode(entry)?entry.tag:null,span:isNode(entry)?readSpan(entry.fields.span):null}))});
  }
  if(value.tag==='TermLam'){
    out.push({path,tag:'TermLam',key:fields.key,quantity:quantityLabel(fields.quantity),
      span:readSpan(fields.span)??undefined,body:isNode(fields.body)?fields.body.tag:null});
  }
  for(const [key,field] of Object.entries(fields))collectQuantitySites(field,path+'.'+key,out);
}
function failureEvidence(result:unknown,source:string):FailureEvidence{
  const fields=isNode(result)?result.fields:{};
  const span=readSpan(fields.span);
  return {message:fields.message,expected:fields.expected,observed:fields.observed,span,
    sourceSlice:span&&typeof span.beg==='number'&&typeof span.end==='number'?source.slice(span.beg,span.end):null};
}
function sideEvidence(raw:unknown,source:string,workerError?:string):SideResult{
  if(workerError!==undefined)
    return {accepted:false,outcome:'WorkerError',error:workerError,elapsedMs:0,resultSha256:'',rawResult:null};
  const resultTag=isNode(raw)?raw.tag:'<non-object>';
  if(resultTag!=='ParseSuccess'&&resultTag!=='ParseFailure')
    return {accepted:false,outcome:'UnexpectedResult',unexpectedTag:resultTag,elapsedMs:0,
      resultSha256:sha256(canonical(raw)),rawResult:raw};
  const accepted=resultTag==='ParseSuccess';
  const side:SideResult={accepted,outcome:accepted?'ParseSuccess':'ParseFailure',elapsedMs:0,resultSha256:sha256(canonical(raw)),rawResult:raw};
  if(accepted&&isNode(raw)){
    const module=raw.fields.module;
    const fields=isNode(module)?module.fields:{};
    const sites:QuantitySite[]=[];
    collectQuantitySites(fields.declarations,'module.declarations',sites);
    side.module={file:fields.path,imports:Array.isArray(fields.imports)?fields.imports.length:0,
      declarations:(Array.isArray(fields.declarations)?fields.declarations:[]).map((entry:unknown)=>isNode(entry)?entry.tag:null)};
    side.quantitySites=sites;
  }else if(isNode(raw))side.failure=failureEvidence(raw,source);
  return side;
}

async function runArtifact(role:'inline'|'external',artifact:ArtifactPin,sources:{name:string;source:string}[]){
  const started=performance.now();
  const child=Bun.spawn([
    'node','--max-old-space-size=3072','--stack-size=262144',
    resolve('evals/bootstrap_parser_artifact_worker.mjs'),artifact.path,String(fuelCells),
  ],{stdin:'pipe',stdout:'pipe',stderr:'inherit'});
  const lines=createInterface({input:Readable.fromWeb(child.stdout as unknown as NodeReadableStream<Uint8Array>)});
  const iterator=lines[Symbol.asyncIterator]();
  const results:{name:string;elapsedMs:number;result:unknown;error?:string}[]=[];
  try{
    for(const [id,item] of sources.entries()){
      const requestStarted=performance.now();
      child.stdin.write(JSON.stringify({id,file:'repro-inline-parser.bend',source:item.source})+'\n');
      await child.stdin.flush();
      const line=await iterator.next();
      if(line.done)throw Error(role+' parser worker ended before response '+id);
      const response=JSON.parse(line.value) as {id:number;result?:unknown;error?:string};
      if(response.id!==id)throw Error(role+' parser worker response id '+response.id+' != '+id);
      results.push({name:item.name,elapsedMs:performance.now()-requestStarted,
        result:response.error===undefined?project(response.result):undefined,error:response.error});
    }
  }finally{
    lines.close();
    if(!child.stdin.destroyed)child.stdin.end();
    await child.exited;
  }
  return {role,artifact,elapsedMs:performance.now()-started,results};
}

const sources=quantityBinderFixtures.map(fixture=>({name:fixture.name,source:fixture.source}));
const runs=[await runArtifact('inline',inlinePin,sources),await runArtifact('external',externalPin,sources)];

const rows:Row[]=[];
for(const [index,fixture] of quantityBinderFixtures.entries()){
  const inlineRun=runs[0].results[index]!,externalRun=runs[1].results[index]!;
  const inlineSide=sideEvidence(inlineRun.result,fixture.source,inlineRun.error),
    externalSide=sideEvidence(externalRun.result,fixture.source,externalRun.error);
  inlineSide.elapsedMs=inlineRun.elapsedMs;
  externalSide.elapsedMs=externalRun.elapsedMs;
  const row:Row={name:fixture.name,source:fixture.source,sourceSha256:sha256(fixture.source),expected:fixture.expected,
    inline:inlineSide,external:externalSide,
    comparison:{acceptanceSame:inlineSide.accepted===externalSide.accepted,astSame:null,firstDifference:null}};
  if(inlineSide.accepted&&externalSide.accepted){
    const left=sortProjected(inlineSide.rawResult),right=sortProjected(externalSide.rawResult);
    row.comparison.astSame=canonical(left)===canonical(right);
    if(!row.comparison.astSame)row.comparison.firstDifference=firstDifference(left,right);
  }
  rows.push(row);
}
const differences=rows.map(row=>({
  name:row.name,expected:row.expected,
  inlineOutcome:row.inline.outcome,externalOutcome:row.external.outcome,
  externalQuantitySites:(row.external.quantitySites??[]).map(site=>site.tag+':'+String(site.quantity)),
  inlineFailureSpan:row.inline.failure?.span??null,
  inlineFailureSlice:row.inline.failure?.sourceSlice??null,
  astSame:row.comparison.astSame,firstDifference:row.comparison.firstDifference,
}));
const abiFailures:{name:string;side:'inline'|'external';outcome:string;error:string|null;unexpectedTag:string|null}[]=[];
for(const row of rows)for(const side of ['inline','external'] as const){
  const result=row[side];
  if(result.outcome==='WorkerError'||result.outcome==='UnexpectedResult')
    abiFailures.push({name:row.name,side,outcome:result.outcome,error:result.error??null,
      unexpectedTag:result.unexpectedTag??null});
}
const oracleRejected=rows.filter(row=>row.external.outcome!=='ParseSuccess').map(row=>({name:row.name,
  externalOutcome:row.external.outcome,externalError:row.external.error??null,
  unexpectedTag:row.external.unexpectedTag??null}));
const status=abiFailures.length>0?'DIAGNOSTIC_ABI_FAILURE':oracleRejected.length>0?'DIAGNOSTIC_ORACLE_REJECTED':
  'DIAGNOSTIC_OBSERVED';

const observed={
  schemaVersion:1,
  kind:'INLINE_ROOT_PARSER_QUANTITY_BINDER_DIFFERENTIAL',
  status,
  reducedDiagnosticOnly:true,
  scope:'Five new minimal sources: + and plain typed body locals, + and plain typed do binds, and one unannotated control with both body shapes. Diagnostic only; the unchanged 13-export corpus, 24-case matrix and full public gates are neither represented nor replaced.',
  authenticationBoundary:'The external parser artifact 0e7b3c42 is already authenticated from canonical 7389188a by the completed qp57a-4 600s gate; this run does not re-run that gate. This run does not authenticate the root candidate inline parser, does not validate its generated compiler image, and does not establish any full fixedpoint.',
  contract:'Stage0 and canonical 7389188a accept an annotated local written "name : T = value", a "+"-annotated local "+name : T = value", a typed do bind "name : T <- action", and "+name : T <- action". The + binder is quantity Many (QMany); the plain binder is QOne/None. Real corpus evidence already in the accepted gate: tests/run/c_backend_link.bend body locals and tests/parse/plus_binder_lambda_do.bend do binders.',
  staticInference:'[INFERENCE, not runtime evidence] Both the 433 artifact and the fresh root57ab-go artifact contain zero compiled functions named step_decl_plus_local, step_parse_typed_local_body or step_parse_do_plus_bind, while the accepted external artifact does. The rows below are the authoritative runtime observation, not this static count.',
  fixtures:quantityBinderFixtures.map(fixture=>({name:fixture.name,source:fixture.source,
    sourceSha256:sha256(fixture.source),expected:fixture.expected})),
  artifacts:{inline:{...inlinePin,role:'root candidate artifact under test; its inline parser is compiled inside this image'},
    external:{...externalPin,role:'accepted external parser canonical 7389188a'}},
  runner,
  fixturesModule,
  runtime:{node:nodeVersion,nodeFlags:['--max-old-space-size=3072','--stack-size=262144'],workerStackSizeMb:256,fuelCells},
  runs:runs.map(run=>({role:run.role,artifactSha256:run.artifact.sha256,elapsedMs:run.elapsedMs})),
  rows,
  differences,
  abiFailures,
  oracleRejected,
};
mkdirSync(dirname(resolve(reportPath)),{recursive:true});
writeFileSync(reportPath,JSON.stringify(observed,null,2)+'\n');
const receiptRows=rows.map(row=>{
  const {rawResult:inlineRaw,...inlineRest}=row.inline;
  const {rawResult:externalRaw,...externalRest}=row.external;
  void inlineRaw;void externalRaw;
  return {...row,inline:inlineRest,external:externalRest};
});
const receipt={...observed,rows:receiptRows,rawReport:resolve(reportPath)};
mkdirSync(dirname(resolve(receiptPath)),{recursive:true});
writeFileSync(receiptPath,JSON.stringify(receipt,null,2)+'\n');
console.log(JSON.stringify({status,abiFailures,oracleRejected,report:resolve(reportPath),receipt:resolve(receiptPath),
  differences,rows:rows.map(row=>({name:row.name,inline:row.inline.outcome,external:row.external.outcome,
    inlineSites:row.inline.quantitySites,externalSites:row.external.quantitySites,
    inlineFailure:row.inline.failure,inlineWorkerError:row.inline.error,
    astSame:row.comparison.astSame,firstDifference:row.comparison.firstDifference}))},null,2));
if(status==='DIAGNOSTIC_ABI_FAILURE')process.exitCode=2;
else if(status==='DIAGNOSTIC_ORACLE_REJECTED')process.exitCode=5;
