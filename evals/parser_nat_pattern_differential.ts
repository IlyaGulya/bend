import * as B from '../bend2/bend.ts';
import {canonicalSourceBook,canonicalCore,normalizeCoreBook,normalizeImports,type Value,type Node} from './parser_full_semantic_normalize.ts';
import {installCompiledLexerABI,feedbackParserResult} from './bootstrap_parser_eval_abi.ts';
import {sourceOracle,type SourceOracleResult} from './bootstrap_source_oracle.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {natPatternFixtures} from './parser_nat_pattern_fixtures.ts';
import {createHash} from 'node:crypto';
import {writeFileSync,mkdtempSync,mkdirSync,rmSync,realpathSync} from 'node:fs';
import {resolve,dirname,join} from 'node:path';
import {tmpdir} from 'node:os';
import {Readable} from 'node:stream';
import {createInterface} from 'node:readline';
import type {ReadableStream as NodeReadableStream} from 'node:stream/web';

import {inspect} from 'node:util';
// Public seam only: complete normalized module AST, and stage0's real pattern
// constructor/field/quantity shape (with the existing span/alpha normalization).
// All parser layers use the existing observation ABI; large source arithmetic
// is executed by checked Base primitives, not host arithmetic or AST rewriting.
// --trace records speculative commitment separately from semantic parity.
const option=(name:string)=>process.argv.find(arg=>arg.startsWith('--'+name+'='))?.slice(name.length+3);
process.argv.push('--memory-mib','8192','--rss-mib','8192','--poll-ms','10');
await guardHeavyGate(import.meta.path,{label:'Public Nat-pattern commitment differential'});
const layer=option('layer')??'canonical';
if(!['stage0','canonical','factored','generated','compiled'].includes(layer))throw Error('Unsupported layer '+layer);
const suite=option('suite')??'small';
if(!['small','large','all'].includes(suite))throw Error('Unsupported suite '+suite);
const parserPath=option('parser')??(layer==='canonical'?'bend2/selfhost/parser.bend':undefined);
if(!['compiled','stage0'].includes(layer)&&!parserPath)throw Error('Pass the exact --parser= path for '+layer);
const artifact=option('artifact');
if(layer==='compiled'&&!artifact)throw Error('Pass the exact frozen/repaired --artifact= path');
const report=option('report')??'checkpoints/nat-pattern-'+layer+'.json';
const traceEnabled=process.argv.includes('--trace');
if(traceEnabled&&layer!=='canonical')throw Error('--trace requires --layer=canonical');
const cases=option('case')?.split(',');
const selected=natPatternFixtures.filter(f=>(suite==='all'||f.suite===suite)&&(!cases||cases.includes(f.name)));
if(!selected.length)throw Error('No fixtures selected');
if(cases&&cases.some(name=>!selected.some(f=>f.name===name)))throw Error('Unknown case or case outside selected suite');
const hash=(value:unknown)=>createHash('sha256').update(JSON.stringify(value)).digest('hex');
const parserSource=parserPath?await Bun.file(parserPath).text():undefined;
const implementationSha256=createHash('sha256').update(layer==='compiled'?new Uint8Array(await Bun.file(artifact!).arrayBuffer()):layer==='stage0'?await Bun.file('bend2/bend.ts').text():parserSource!).digest('hex');
let book:B.Book|undefined,fuel:B.HTerm=B.Ctr('FeedbackFuelEnd',[]);
if(!['stage0','compiled'].includes(layer)){
  book=await canonicalSourceBook(parserSource!, resolve(parserPath!));
  await installCompiledLexerABI(book);
  if(layer==='generated')for(let i=0;i<2000000;i++)fuel=B.Ctr('FeedbackFuelCell',[fuel]);
}
function closed(source:string):B.HTerm{return B.Lit('String',source);}
function ctor(term:B.HTerm){const raw=B.term_wnf(book!,term),value=raw.$==='Lit'?B.lit_step(raw):raw;if(value.$!=='Ctr')throw Error('Expected constructor '+value.$);return {...value,k:B.name_key(value.k)};}
function nat(term:B.HTerm){let n=0;for(;;){const raw=B.term_wnf(book!,term);if(raw.$==='Lit'&&raw.k==='Nat')return n+raw.v;const value=ctor(raw);if(value.k==='Zero')return n;if(value.k!=='Succ')throw Error('Invalid Nat');n++;term=value.x[0]!;}}
function text(term:B.HTerm){
  let out='';for(;;){const value=ctor(term);if(value.k==='SNil')return out;if(value.k!=='SCon')throw Error('Invalid String');let word=ctor(ctor(value.x[0]!).x[0]!).x[0]!,code=0,bit=1;for(;;){const cell=ctor(word);if(cell.k==='WNil')break;if(cell.k!=='WCon')throw Error('Invalid character');if(ctor(cell.x[0]!).k==='True')code+=bit;bit*=2;word=cell.x[1]!;}out+=String.fromCodePoint(code);term=value.x[1]!;}
}
function decode(term:B.HTerm):Value{
  const value=ctor(term),tag=value.k.split('.').at(-1)!;
  if(tag==='Zero'||tag==='Succ')return nat(term);
  if(tag==='True'||tag==='False')return tag==='True';
  if(tag==='SNil'||tag==='SCon')return text(term);
  if(tag==='Nil'||tag==='Con'){const out:Value[]=[];for(;;){const cell=ctor(term);if(cell.k==='Nil')return out;if(cell.k!=='Con')throw Error('Invalid list');out.push(decode(cell.x[0]!));term=cell.x[1]!;}}
  return {tag,fields:value.x.map(decode)};
}
function node(value:Value):Node{if(!value||typeof value!=='object'||Array.isArray(value))throw Error('Expected syntax node');return value;}
function array(value:Value):Value[]{if(!Array.isArray(value))throw Error('Expected syntax list');return value;}
function native(value:any):Value{
  if(value?.$==='$NativeNat'){const n=Number(value.value);if(!Number.isSafeInteger(n))throw Error('Non-exact Nat observation');return n;}
  if(typeof value!=='object'||value===null)return value;
  if(value.$==='Nil'||value.$==='Con'){const out:Value[]=[];while(value.$==='Con'){out.push(native(value.head));value=value.tail;}if(value.$!=='Nil')throw Error('Invalid native list');return out;}
  if(typeof value.$!=='string')throw Error('Invalid native constructor');
  return {tag:value.$.split('.').at(-1)!,fields:Object.entries(value).filter(([key])=>key!=='$').map(([,child])=>native(child))};
}
function showError(error:unknown):string{
  if(error&&typeof error==='object'&&'$'in error&&error.$==='Err')return B.err_show(error as B.Err);
  return error instanceof Error?error.message:typeof error==='object'?inspect(error,{depth:6,breakLength:Infinity}):String(error);
}
function stage0Patterns(oracle:SourceOracleResult):unknown[][]{
  const groups:unknown[][]=[];
  function group(patterns:B.Patt[]){let next=0;function patt(p:B.Patt):unknown{return p.$==='PVar'?['PVar',p.k,p.q.$,next++]:['PCtr',p.k,p.x.map(patt)];}groups.push(patterns.map(patt));}
  function body(b:B.Body){if(b.$==='Local'){group(b.k);body(b.f);}else if(b.$==='Match')for(const row of b.r){group(row.p);body(row.f);}}
  for(const declaration of oracle.declarations)if(declaration.body)body(declaration.body);
  return groups;
}
function syntaxPatterns(module:Value):unknown[][]{
  const groups:unknown[][]=[],tasks:Value[]=[module];
  while(tasks.length){const value=tasks.pop()!;if(!value||typeof value!=='object')continue;
    if(!Array.isArray(value)&&(value.tag==='BodyLocal'||value.tag==='BodyCase')){
      let next=0;function patt(value:Value):unknown{const p=node(value),f=p.fields;if(p.tag==='PatternVar'){const quantity=({QZero:'None',QOne:'Lone',QMany:'Many'} as Record<string,string>)[node(f[2]!).tag];if(!quantity)throw Error('Invalid pattern quantity');return ['PVar',f[0],quantity,next++];}if(p.tag==='PatternCtr')return ['PCtr',f[0],array(f[1]!).map(patt)];throw Error('Invalid pattern constructor '+p.tag);}
      groups.push(array(value.fields[0]!).map(patt));
    }
    const children=Array.isArray(value)?value:value.fields;
    for(let i=children.length-1;i>=0;i--)tasks.push(children[i]!);
  }
  return groups;
}
const trace:Record<string,unknown>[]=[];
if(traceEnabled){
  const tokens=(term:B.HTerm)=>array(decode(term)).map(value=>{const fields=node(value).fields;return {kind:node(fields[0]!).tag,text:fields[1],beg:fields[2],end:fields[3]};});
  for(const name of ['parse_destructuring_local','destructuring_has_equal','parse_destructuring_recognized','parse_pattern_atom','pattern_scan','pattern_nat_after','nat_pattern','parse_destructuring_pattern_result','parse_reply']){
    const definition=book!.tlds[name];if(definition?.$!=='Def'){if(['destructuring_has_equal','parse_destructuring_recognized'].includes(name))continue;throw Error('Missing trace helper '+name);}
    const original=definition.v!,arity=definition.n;
    function wrap(term:B.HTerm,args:B.HTerm[]):B.HTerm{
      if(args.length<arity)return B.Lam('diagnostic',100000+args.length,arg=>wrap(B.App(term,arg),args.concat(arg)));
      const event:Record<string,unknown>={helper:name};trace.push(event);
      if(['parse_destructuring_local','parse_pattern_atom','parse_reply'].includes(name))event.tokens=tokens(args[1]!);
      if(name==='destructuring_has_equal'){event.tokens=tokens(args[0]!);event.nesting=nat(args[1]!);}
      if(name==='parse_destructuring_recognized')event.hasLocalMarker=ctor(args[0]!).k;
      if(name==='pattern_scan'){event.mode=ctor(args[2]!).k;event.goal=ctor(args[6]!).k;}
      if(name==='pattern_nat_after')event.value=nat(args[2]!);
      if(name==='nat_pattern')event.value=nat(args[1]!);
      if(name==='parse_destructuring_pattern_result'){event.okPattern=ctor(args[0]!).k;event.remainder=tokens(args[1]!);}
      const result=B.term_wnf(book!,term);
      if(name==='destructuring_has_equal')event.result=ctor(result).k;
      return result;
    }
    definition.v=wrap(original,[]);
  }
}
// Reuse the established artifact worker and its existing stack/fuel unchanged.
const worker=layer==='compiled'?Bun.spawn(['node','evals/bootstrap_parser_artifact_worker.mjs',resolve(artifact!)],{stdin:'pipe',stdout:'pipe',stderr:'inherit'}):undefined;
const lines=worker?createInterface({input:Readable.fromWeb(worker.stdout as unknown as NodeReadableStream<Uint8Array>)}):undefined;
const iterator=lines?.[Symbol.asyncIterator]();
const fixtures=realpathSync(mkdtempSync(join(tmpdir(),'bend-nat-pattern-'))),file=join(fixtures,'source.bend');
const rows:Record<string,unknown>[]=[],failures:string[]=[];
mkdirSync(dirname(resolve(report)),{recursive:true});
function publish(){writeFileSync(report,JSON.stringify({schemaVersion:1,layer,suite,parserPath:parserPath??null,artifact:artifact??null,implementationSha256,selectedCases:selected.map(f=>f.name),seam:layer==='stage0'?'Independent stage0 acceptance and raw pattern shapes; oracle only, no cross-layer parity claim':'Complete normalized public parser AST + stage0 pattern constructor/field/quantity parity (existing spans/alpha convention)',largeSourceEvaluations:!['stage0','compiled'].includes(layer)&&selected.some(f=>f.suite==='large'),traceEnabled,completed:rows.length===selected.length,passed:rows.length===selected.length&&!failures.length,rows,failures},null,2)+'\n');}
try{
  for(const [id,fixture] of selected.entries()){
    trace.length=0;const {accepted:expectedAccepted,...metadata}=fixture;
    const row:Record<string,unknown>={...metadata,expectedAccepted};rows.push(row);
    try{
      writeFileSync(file,fixture.source);const oracle=await sourceOracle(file,fixture.source,{preloadBase:true});row.stage0Accepted=oracle.accepted;row.stage0Observation=oracle.observation;
      if(!oracle.accepted){row.stage0Failure=oracle.failure;row.stage0Error=showError(oracle.error);}
      if(oracle.failure?.category==='observation-seam')throw Error('Stage0 observation seam failed: '+row.stage0Error);
      if(oracle.accepted!==fixture.accepted)throw Error('Stage0 disagrees with required fixture acceptance');
      const expectedPatterns=oracle.accepted?stage0Patterns(oracle):undefined;row.expectedPatterns=expectedPatterns;
      if(fixture.pinnedPatterns&&hash(expectedPatterns)!==hash(fixture.pinnedPatterns))throw Error('Stage0 disagrees with pinned literal pattern AST');
      if(layer==='stage0'){row.disposition='stage0-oracle-only';row.compared=false;continue;}
      let result:Value;
      if(worker){worker.stdin.write(JSON.stringify({id,file,source:fixture.source})+'\n');await worker.stdin.flush();const line=await iterator!.next();if(line.done)throw Error('Artifact worker ended before reply');const response=JSON.parse(line.value);if(response.id!==id)throw Error('Artifact reply id mismatch');if(response.error)throw Error(response.error);result=native(response.result);}
      else{const term=layer==='generated'?feedbackParserResult(book!,B.App(B.App(B.App(B.Ref('parse_with_fuel'),fuel),closed(file)),closed(fixture.source))):B.App(B.App(B.Ref('parse'),closed(file)),closed(fixture.source));result=decode(term);}
      const parsed=node(result);if(!['ParseSuccess','ParseFailure'].includes(parsed.tag))throw Error('Invalid public parser result');
      const accepted=parsed.tag==='ParseSuccess';row.accepted=accepted;row.acceptanceParity=accepted===oracle.accepted;
      if(!accepted)row.failure=parsed;
      if(accepted!==oracle.accepted)throw Error('Public parser acceptance mismatch');
      if(!accepted){row.patternParity=true;row.semanticParity=true;row.disposition='joint-rejection-no-AST';}
      else{
        const actualPatterns=syntaxPatterns(parsed.fields[0]!);row.actualPatterns=actualPatterns;row.patternParity=hash(expectedPatterns)===hash(actualPatterns);
        if(!row.patternParity)throw Error('Public pattern AST mismatch');
        const environment=oracle.normalizationBook(),imports=oracle.imports.map(i=>({path:i.path,alias:i.alias}));
        const expected=normalizeCoreBook(environment,oracle.declarations.map(d=>d.key),imports,file,dirname(file)+'/').semantic;
        const actual=canonicalCore(parsed.fields[0]!,environment,fixture.source).semantic;actual.imports=normalizeImports(imports);
        row.expected=expected;row.actual=actual;row.expectedASTHash=hash(expected);row.actualASTHash=hash(actual);row.semanticParity=row.expectedASTHash===row.actualASTHash;
        if(!row.semanticParity)throw Error('Complete normalized AST mismatch');
      }
    }catch(error){row.error=showError(error);failures.push(fixture.name+': '+row.error);}
    finally{if(traceEnabled)row.trace=trace.slice();publish();console.log(JSON.stringify({layer,name:fixture.name,accepted:row.accepted,stage0Accepted:row.stage0Accepted,patternParity:row.patternParity,semanticParity:row.semanticParity,error:row.error}));}
  }
}finally{
  if(worker){lines!.close();worker.stdin.end();await worker.exited;}
  rmSync(fixtures,{recursive:true,force:true});
  publish();
}
if(failures.length)process.exitCode=2;
