import * as B from '../bend2/bend.ts';
import {canonicalSourceBook,canonicalCore,normalizeCoreBook,normalizeImports,type Value,type Node} from './parser_full_semantic_normalize.ts';
import {sourceOracle} from './bootstrap_source_oracle.ts';
import {compiledLexerABI,lexerConstructorKey,installCompiledLexerABI,feedbackParserResult} from './bootstrap_parser_eval_abi.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {createHash} from 'node:crypto';
import {readFileSync,writeFileSync} from 'node:fs';
import {resolve,dirname} from 'node:path';
import {Readable} from 'node:stream';
import {createInterface} from 'node:readline';
process.argv.push('--memory-mib','8192','--rss-mib','8192','--poll-ms','10');
await guardHeavyGate(import.meta.path,{label:'Exact frozen source evaluator AST parity'});
const option=(name:string)=>process.argv.find(arg=>arg.startsWith('--'+name+'='))?.slice(name.length+3);
(Error as ErrorConstructor & {stackTraceLimit: number}).stackTraceLimit=64;
const layer=option('layer')??'canonical';
if(!['canonical','factored','generated'].includes(layer))throw Error('Unsupported evaluator layer '+layer);
const parserPath=option('parser')??(layer==='canonical'?'bend2/selfhost/parser.bend':undefined);
if(!parserPath)throw Error('Exact --parser path required');
const report=option('report');if(!report)throw Error('--report required');
const moduleId=Number(option('module'));if(!Number.isSafeInteger(moduleId))throw Error('--module required');
const manifest=JSON.parse(readFileSync('checkpoints/bootstrap-real-source-corpus.json','utf8'));
const module=manifest.modules.find((item:any)=>item.id===moduleId);if(!module)throw Error('Unknown frozen module');
const hash=(value:string)=>createHash('sha256').update(value).digest('hex');
const original=readFileSync(module.snapshot,'utf8');if(hash(original)!==module.sourceSha256)throw Error('Frozen source drift');
const count=option('declarations')===undefined?undefined:Number(option('declarations'));
const candidates=[...original.matchAll(/^(?:def |type |law |@unsafe\b).*$/gm)];
if(count!==undefined&&(!Number.isSafeInteger(count)||count<0||count>candidates.length))throw Error('Invalid declaration boundary');
const source=count===undefined?original:original.slice(0,candidates[count]?.index??original.length);
const parserSource=readFileSync(parserPath,'utf8');
const evidence:any={layer,parserPath:resolve(parserPath),parserSha256:hash(parserSource),module:moduleId,file:module.file,snapshot:module.snapshot,originalSourceSha256:module.sourceSha256,sourceSha256:hash(source),sourceChars:source.length,sourceScope:count===undefined?'full-file':'declaration-prefix',declarations:count,complete:false,parseCompleted:false,fullFileParseSuccess:false,normalizedASTParity:false};
function publish(phase:string){evidence.phase=phase;writeFileSync(report,JSON.stringify(evidence,null,2)+'\n');console.log(JSON.stringify({phase,module:moduleId,layer,sourceScope:evidence.sourceScope,declarations:count}));}
function closed(text:string):B.HTerm{return B.Lit('String',text);}
let book:B.Book;
function ctor(term:B.HTerm){const value=B.term_wnf(book,term),head=value.$==='Lit'?B.lit_step(value):value;if(head.$!=='Ctr')throw Error('Expected source AST constructor');return {...head,k:B.name_key(head.k)};}
function nat(term:B.HTerm){let n=0;for(;;){const raw=B.term_wnf(book,term);if(raw.$==='Lit'&&raw.k==='Nat')return n+raw.v;const value=ctor(raw);if(value.k==='Zero')return n;if(value.k!=='Succ')throw Error('Invalid Nat');n++;term=value.x[0]!;}}
function text(term:B.HTerm){let result='';for(;;){const value=ctor(term);if(value.k==='SNil')return result;if(value.k!=='SCon')throw Error('Invalid String');let word=ctor(ctor(value.x[0]!).x[0]!).x[0]!,code=0,bit=1;for(;;){const cell=ctor(word);if(cell.k==='WNil')break;if(cell.k!=='WCon')throw Error('Invalid Word');if(ctor(cell.x[0]!).k==='True')code+=bit;bit*=2;word=cell.x[1]!;}result+=String.fromCodePoint(code);term=value.x[1]!;}}
function decode(term:B.HTerm,preserveSpans=false):Value{const value=ctor(term),tag=value.k.split('.').at(-1)!;if(tag==='SpanOf')return {tag,fields:[text(value.x[0]!),preserveSpans?nat(value.x[1]!):0,preserveSpans?nat(value.x[2]!):0]};if(tag==='Zero'||tag==='Succ')return nat(term);if(tag==='U32')return nat(B.App(B.Ref('U32.to_nat'),term));if(tag==='True'||tag==='False')return tag==='True';if(tag==='SNil'||tag==='SCon')return text(term);if(tag==='Nil'||tag==='Con'){const out:Value[]=[];for(;;){const cell=ctor(term);if(cell.k.split('.').at(-1)==='Nil')return out;if(cell.k.split('.').at(-1)!=='Con')throw Error('Invalid List');out.push(decode(cell.x[0]!,preserveSpans));term=cell.x[1]!;}}return {tag,fields:value.x.map(child=>decode(child,preserveSpans||tag==='ParseFailure'))};}
try{
 publish('stage0-oracle');const oracle=await sourceOracle(module.file,source);evidence.stage0Accepted=oracle.accepted;
 if(!oracle.accepted)throw oracle.error;
 publish('source-book');book=await canonicalSourceBook(parserSource, resolve(parserPath));
 // Reuse the established compiled scanner worker and its unchanged policy.
 // Grammar runs in the requested source evaluator, not in the token producer.
 publish('compiled-scanner-worker');
 const {lexer:_,...tokenProof}=await compiledLexerABI();
 const worker=Bun.spawn(['node','evals/bootstrap_token_worker.mjs',tokenProof.artifactPath],{stdin:'pipe',stdout:'pipe',stderr:'inherit'});
 const lines=createInterface({input:Readable.fromWeb(worker.stdout as any)});
 let tokens:any[];
 try{
   worker.stdin.write(JSON.stringify({id:0,source})+'\n');await worker.stdin.flush();
   const response=await lines[Symbol.asyncIterator]().next();if(response.done)throw Error('Lexer worker ended');
   const value=JSON.parse(response.value);
   if(value.id!==0||value.error||!Array.isArray(value.tokens))throw Error(value.error??'Invalid raw lexer reply');
   tokens=value.tokens;
 }finally{lines.close();worker.stdin.end();if(await worker.exited!==0)throw Error('Raw lexer worker failed');}
 if(layer==='generated')evidence.lexerABI=await installCompiledLexerABI(book,{source,tokens});
 else evidence.scannerABI={...tokenProof,implementation:'Current native Lexer.tokens; symbol combining runs in the selected source parser'};
 let run:B.HTerm;
 publish('source-parse');
 if(layer==='generated'){let fuel:B.HTerm=B.Ctr('FeedbackFuelEnd',[]);for(let i=0;i<2000000;i++)fuel=B.Ctr('FeedbackFuelCell',[fuel]);run=feedbackParserResult(book,B.App(B.App(B.App(B.Ref('parse_with_fuel'),fuel),closed(module.file)),closed(source)));}
 else{
   const inputNat=(value:number)=>{if(!Number.isSafeInteger(value)||value<0)throw Error('Invalid Token Nat');return B.Lit('Nat',value);};
   let input=B.Ctr('Nil',[]);
   for(let i=tokens.length-1;i>=0;i--){const t=tokens[i];input=B.Ctr('Con',[B.Ctr(lexerConstructorKey(t.$),[B.Ctr(lexerConstructorKey(t.kind.$),[]),closed(t.text),inputNat(t.beg),inputNat(t.end),inputNat(t.line),inputNat(t.col)]),input]);}
   const combined=B.App(B.App(B.Ref('combine_symbols'),input),B.Ctr('SymbolCombineScan',[]));
   run=B.App(B.App(B.Ref('parse_module_tokens'),combined),closed(module.file));
 }
 const parsed=decode(run) as Node;evidence.parseCompleted=true;evidence.parseSuccess=parsed.tag==='ParseSuccess';evidence.fullFileParseSuccess=count===undefined&&evidence.parseSuccess;
 if(!evidence.parseSuccess){evidence.failure=parsed;throw Error('Source parser returned '+parsed.tag);}
 publish('normalized-AST');const environment=oracle.normalizationBook();const syntax=parsed.fields[0] as Node;
 const imports=syntax.fields[1] as Node[];
 const adjusted:Node={...syntax,fields:[syntax.fields[0],imports.map(value=>{const expected=oracle.imports.find(item=>item.alias===value.fields[1]);return {...value,fields:[expected?.namespace||value.fields[0],...value.fields.slice(1)]};}),syntax.fields[2]]};
 const expected=normalizeCoreBook(environment,oracle.declarations.map(item=>item.key),oracle.imports.map(item=>({path:item.path,alias:item.alias})),module.file,dirname(module.file)+'/').semantic;
 const actual=canonicalCore(adjusted,environment,source).semantic;actual.imports=normalizeImports(imports.map(value=>({path:value.fields[0] as string,alias:value.fields[1] as string})));
 evidence.stage0ASTHash=hash(JSON.stringify(expected));evidence.actualASTHash=hash(JSON.stringify(actual));evidence.normalizedASTParity=evidence.stage0ASTHash===evidence.actualASTHash;
 if(!evidence.normalizedASTParity){writeFileSync(report+'.mismatch.json',JSON.stringify({expected,actual},null,2)+'\n');throw Error('Complete normalized AST mismatch');}
 evidence.complete=true;publish('PASS');
}catch(error){evidence.error=error&&typeof error==='object'&&'$'in error&&error.$==='Err'?B.err_show(error as B.Err):String(error);if(error instanceof Error)evidence.errorStack=error.stack?.split('\n').slice(0,40);publish('FAIL');process.exitCode=1;}
