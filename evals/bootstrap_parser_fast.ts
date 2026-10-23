import * as B from '../bend2/bend.ts';
import {canonicalSourceBook,observeCanonicalCore,observeCoreBook} from './parser_full_semantic_normalize.ts';
import type {Value,Span} from './parser_full_semantic_normalize.ts';
import {sourceOracle} from './bootstrap_source_oracle.ts';
import {guardHeavyGate,parseHeavyGateOptions} from './heavy_gate.ts';
import {compiledLexerABI,lexerConstructorKey} from './bootstrap_parser_eval_abi.ts';
import {readNativeAstArena} from './bootstrap_ast_transport.ts';
import {createHash} from 'node:crypto';
import {writeFileSync,mkdtempSync,rmSync,readFileSync,realpathSync} from 'node:fs';
import {resolve,dirname,join,posix} from 'node:path';
import {tmpdir,homedir} from 'node:os';
import {execFileSync} from 'node:child_process';
import {Readable} from 'node:stream';
import type {ReadableStream as NodeReadableStream} from 'node:stream/web';
import {createInterface} from 'node:readline';
// Source preparation is bounded evaluator evidence, never parser admission.
// Final admission requires --component and --component-build and all 75 cases.
const requestedGuard=parseHeavyGateOptions(process.argv.slice(2)).options;
for(const [key,variable,value]of [['memoryMiB','HEAVY_GATE_MEMORY_MIB',8192],['rssMiB','HEAVY_GATE_RSS_MIB',8192],['pollMs','HEAVY_GATE_POLL_MS',10]] as const){
 const selected=requestedGuard[key]??process.env[variable];
 if(selected!==undefined&&Number(selected)!==value)throw Error('Parser gate requires '+variable+'='+value);
 process.env[variable]=String(value);
}
await guardHeavyGate(import.meta.path,{label:'Current release parser preparation or complete native semantic and literal-span gate'});
const parserPath=process.argv.find(a=>a.startsWith('--parser='))?.slice(9);
const entryPoint=process.argv.find(a=>a.startsWith('--entry='))?.slice(8);
const report=process.argv.find(a=>a.startsWith('--report='))?.slice(9);
const publicReportPath=process.argv.find(a=>a.startsWith('--public-report='))?.slice(16);
if(!parserPath||!report||!publicReportPath||!entryPoint||!['parse_module_tokens','parse_with_fuel'].includes(entryPoint))throw Error('Require --parser, --entry, --public-report and fresh --report');
const componentPath=process.argv.find(a=>a.startsWith('--component='))?.slice(12);
const componentBuildPath=process.argv.find(a=>a.startsWith('--component-build='))?.slice(18);
const nativeMode=entryPoint==='parse_with_fuel';
if(nativeMode?(!componentPath||!componentBuildPath):(componentPath!==undefined||componentBuildPath!==undefined))throw Error('Final parse_with_fuel requires --component and --component-build; source preparation takes neither');
const evaluationMode=nativeMode?'native-artifact':'source-preparation';
const guard={memoryMiB:8192,rssMiB:8192,pollMs:10};
const historicalLimitedModules=['.parser_definition_body_shape_generated_fuel.bend','base.bend','checker_core_slice.bend','js_emit.bend'];
const knownEvaluatorLimitedModules=nativeMode?[]:historicalLimitedModules;
const parserSource=await Bun.file(parserPath).text(),parserSha256=createHash('sha256').update(parserSource).digest('hex');
const canonicalSha256=createHash('sha256').update(new Uint8Array(await Bun.file('bend2/selfhost/parser.bend').arrayBuffer())).digest('hex');
const kernelPath=resolve('bend2/bend.ts'),kernelSha256=createHash('sha256').update(readFileSync(kernelPath)).digest('hex');
const sourceInputs=new Map<string,{file:string,sha256:string}>();
for(const path of [kernelPath,'bend2/comp.ts','bend2/base.bend','bend2/selfhost/ast.bend','bend2/selfhost/lexer.bend',
 'evals/bootstrap_parser_fast.ts','evals/bootstrap_parser_public_gate.ts','evals/heavy_gate.ts','evals/heavy_gate_native.c',
 'evals/bootstrap_ast_transport.ts','evals/parser_full_semantic_normalize.ts','evals/parser_full_graph.ts','evals/bootstrap_source_oracle.ts','evals/bootstrap_parser_eval_abi.ts','evals/parser_full_fuel_smoke.ts',
 ...(nativeMode?['evals/bootstrap_parser_native_semantic_worker.mjs']:['evals/bootstrap_token_worker.mjs'])]){
 const file=realpathSync(path);sourceInputs.set(file,{file,sha256:createHash('sha256').update(readFileSync(file)).digest('hex')});
}
const component=nativeMode?authenticateNativeComponent(componentPath!,componentBuildPath!):null;
const book=nativeMode?B.book_nil():await canonicalSourceBook(parserSource, resolve(parserPath));
const lexerNamespace = parserSource.match(/^import (\S+) as Lexer$/m)?.[1]?.replace(/^\.\//,'').replace(/\.bend$/,'');
if (!lexerNamespace) throw Error('Missing authentic parser Lexer import');
const lexerABI=null;
const tokenABI=nativeMode?null:await compiledLexerABI();
// This authenticates provisional native generation only. It deliberately does
// not import the final root acceptance validator: this gate creates that proof.
function authenticateNativeComponent(artifact:string,receipt:string){
 const sha=(bytes:string|Uint8Array)=>createHash('sha256').update(bytes).digest('hex');
 const object=(value:unknown):Record<string,unknown>=>{if(!value||typeof value!=='object'||Array.isArray(value))throw Error('Invalid canonical native build object');return value as Record<string,unknown>;};
 const pin=(path:string)=>{
  const file=realpathSync(path),bytes=readFileSync(file),sha256=sha(bytes),previous=sourceInputs.get(file);
  if(previous&&previous.sha256!==sha256)throw Error('Native build closure changed: '+file);
  sourceInputs.set(file,{file,sha256});return bytes;
 };
 const nativeBuildPath=realpathSync(receipt),buildBytes=pin(nativeBuildPath),build=object(JSON.parse(buildBytes.toString('utf8')));
 if(build.status!=='JS_GENERATED_NOT_YET_EXECUTED'||build.checksExcluded!==0||build.outputPatches!==0
  ||!Array.isArray(build.exports)||!build.exports.includes('parse_with_fuel')||typeof build.provenancePath!=='string')throw Error('Complete provisional canonical native parser build required');
 const provenancePath=realpathSync(build.provenancePath),record=object(JSON.parse(pin(provenancePath).toString('utf8')));
 const {provenanceSha256,...proof}=record;
 if(proof.schemaVersion!==4||typeof provenanceSha256!=='string'||!/^[0-9a-f]{64}$/.test(provenanceSha256)||provenanceSha256!==build.provenanceSha256||sha(JSON.stringify(proof))!==provenanceSha256)throw Error('Canonical schema4 native provenance drift');
 const protectedPins=object(proof.protectedPins),loadedInputs=object(proof.loadedInputs);
 for(const pins of [protectedPins,loadedInputs]){
  if(!Object.keys(pins).length)throw Error('Missing complete native input manifest');
  for(const [path,digest]of Object.entries(pins))if(resolve(path)!==path||realpathSync(path)!==path
   ||typeof digest!=='string'||!/^[0-9a-f]{64}$/.test(digest)||sha(pin(path))!==digest)throw Error('Native input drift: '+path);
 }
 for(const [field,path]of [['runnerPath','evals/checker_core_component_build.ts'],['compilerPath','bend2/comp.ts'],['kernelPath','bend2/bend.ts'],['basePath','bend2/base.bend']] as const){
  const current=realpathSync(path),digest=sha(pin(current));
  if(typeof proof[field]!=='string'||realpathSync(proof[field])!==current||proof[field.replace('Path','Sha256')]!==digest||protectedPins[current]!==digest)throw Error('Native producer drift: '+field);
 }
 const officialKernelSha256=sha(execFileSync('git',['show','4ff8545f19b09b7d2b8ca2303668100eac8efd66:bend2/bend.ts']));
 if(kernelSha256!==officialKernelSha256)throw Error('Native parser gate kernel is not the exact official release');
 for(const path of ['evals/heavy_gate.ts','evals/heavy_gate_native.c']){
  const current=realpathSync(path);if(protectedPins[current]!==sha(pin(current)))throw Error('Missing authenticated native helper '+path);
 }
 if(typeof build.sourcePath!=='string'||typeof build.artifactPath!=='string'||realpathSync(build.sourcePath)!==realpathSync(parserPath!)
  ||realpathSync(build.artifactPath)!==realpathSync(artifact)||sha(pin(build.sourcePath))!==parserSha256||build.sourceSha256!==parserSha256
  ||proof.sourcePath!==build.sourcePath||proof.sourceSha256!==parserSha256||loadedInputs[realpathSync(parserPath!)]!==parserSha256
  ||typeof build.artifactSha256!=='string'||!/^[0-9a-f]{64}$/.test(build.artifactSha256)||sha(pin(artifact))!==build.artifactSha256||JSON.stringify(proof.exports)!==JSON.stringify(build.exports)||proof.checksExcluded!==0||proof.outputPatches!==0)throw Error('Native artifact does not authenticate the selected candidate bytes');
 const runtime=object(proof.runtime),nativeGuard=object(proof.guard),guardian=object(build.guardian),observation=object(proof.kernelObservation);
 if(runtime.name!=='node'||runtime.heapLimitMiB!==3072||runtime.manualGC!==false||JSON.stringify(runtime)!==JSON.stringify(build.runtime)
  ||nativeGuard.memoryMiB!==8192||nativeGuard.rssMiB!==8192||nativeGuard.pollMs!==10||guardian.status!=='PASS'
  ||guardian.memoryLimitBytes!==8192*1024*1024||guardian.rssLimitBytes!==8192*1024*1024
  ||observation.kernelUnmodified!==true||observation.sourceValueReplacement!==false||observation.parserSubstitutions!==0
  ||proof.loadMode!=='CANONICAL_NATIVE_UNMODIFIED'||proof.checkedOutputRetention!=='native e'||build.checkedOutputRetention!=='native e')throw Error('Native validation/resource contract drift');
 const bodies=proof.checkedDefinitions;
 if(!Number.isSafeInteger(bodies)||Number(bodies)<=0)throw Error('Missing native checked bodies');
 for(const field of ['checkedDefinitions','nativeCheckedBodies','expectedSourceDefinitions'])if(proof[field]!==bodies||build[field]!==bodies)throw Error('Incomplete native body coverage: '+field);
 if(proof.eventsFullyValidated!==build.eventsFullyValidated||typeof proof.eventsFullyValidated!=='number'||!Number.isSafeInteger(proof.eventsFullyValidated)||proof.eventsFullyValidated<=0)throw Error('Incomplete native validation event coverage');
 const closure=new Set<string>(),library=resolve(process.env.BEND_LIB??posix.join(homedir(),'.bend','lib'));
 function visit(path:string){
  const file=realpathSync(path);if(closure.has(file))return;closure.add(file);
  const bytes=pin(file);if(loadedInputs[file]!==sha(bytes))throw Error('Unobserved native source dependency '+file);
  for(const raw of bytes.toString('utf8').split('\n')){
   const line=raw.trim();if(!line||line.startsWith('#'))continue;if(!/^import(\s|$)/.test(line))break;
   const imported=/^import\s+(\S+)(?:\s+as\s+([A-Za-z_]\w*))?\s*(?:#.*)?$/.exec(line);
   if(!imported||(imported[2]===undefined&&imported[1]!=='Base')||imported[1]!.includes('@'))throw Error('Native parser import manifest drift: '+file);
   visit(imported[2]===undefined?resolve('bend2/base.bend'):/^0x[0-9a-f]+\//.test(imported[1]!)?resolve(library,imported[1]!):resolve(dirname(file),imported[1]!));
  }
 }
 visit(parserPath!);
 if(Object.keys(loadedInputs).filter(path=>path.endsWith('.bend')).sort().join('\n')!==[...closure].sort().join('\n'))throw Error('Native parser loaded source closure drift');
 return {artifactPath:realpathSync(artifact),artifactSha256:build.artifactSha256,nativeBuildPath,nativeBuildSha256:sha(buildBytes),provenancePath,provenanceSha256};
}
function closed(source:string):B.HTerm{return B.Lit('String',source);}
function inputNat(value:number):B.HTerm{
 if(!Number.isSafeInteger(value)||value<0)throw Error('Invalid current native token Nat');
 return B.Lit('Nat',value);
}
function inputTokens(tokens:{$:string,kind:{$:string},text:string,beg:number,end:number,line:number,col:number}[]):B.HTerm{
 let tail:B.HTerm=B.Ctr('Nil',[]);
 for(let i=tokens.length-1;i>=0;i--){const t=tokens[i],token=B.Ctr(lexerConstructorKey(t.$,lexerNamespace),[B.Ctr(lexerConstructorKey(t.kind.$,lexerNamespace),[]),closed(t.text),inputNat(t.beg),inputNat(t.end),inputNat(t.line),inputNat(t.col)]);tail=B.Ctr('Con',[token,tail]);}
 // Combining is part of the selected authentic parser, not a historical JS snapshot.
 return B.App(B.App(B.Ref('combine_symbols'),tail),B.Ctr('SymbolCombineScan',[]));
}
function head(t:B.HTerm):B.HTerm{
 for(;;){const v=B.term_wnf(book,t);if(v.$!=='Ann')return v;t=v.x;}
}
function ctor(t:B.HTerm){
 const v=head(t),demanded=v.$==='Lit'?B.lit_step(v):v;
 if(demanded.$!=='Ctr')throw Error('Expected constructor '+demanded.$);return demanded;
}
function tag(key:string){return B.name_key(key).split('.').at(-1)!;}
function nat(t:B.HTerm){
 let n=0;
 for(;;){
  const v=head(t);
  if(v.$==='Lit'&&v.k==='Nat'){const result=n+v.v;if(!Number.isSafeInteger(result)||result<0)throw Error('Invalid exact AST Nat');return result;}
  if(v.$!=='Ctr')throw Error('Expected Nat '+v.$);
  if(v.k==='Zero'&&v.x.length===0)return n;
  if(v.k!=='Succ'||v.x.length!==1||!Number.isSafeInteger(++n))throw Error('Bad Nat '+v.k);
  t=v.x[0];
 }
}
function word(t:B.HTerm){
 let n=0,bits=0;
 for(;;){
  const c=ctor(t);if(c.k==='WNil'&&c.x.length===0){if(bits!==32)throw Error('Invalid U32 width');return n;}
  if(c.k!=='WCon'||c.x.length!==2||bits>=32)throw Error('Bad U32 Word');
  const bit=ctor(c.x[0]);if(bit.k!=='True'&&bit.k!=='False'||bit.x.length!==0)throw Error('Bad U32 bit');
  if(bit.k==='True')n+=2**bits;bits++;t=c.x[1];
 }
}
function u32(t:B.HTerm){
 const v=head(t);
 if(v.$==='Lit'&&v.k==='U32'){if(!Number.isInteger(v.v)||v.v<0||v.v>0xffffffff)throw Error('Bad compact U32');return v.v;}
 const c=ctor(t);if(c.k!=='U32'||c.x.length!==1)throw Error('Expected U32');return word(c.x[0]);
}
function str(t:B.HTerm){
 const parts:string[]=[];
 for(;;){
  const v=head(t);
  if(v.$==='Lit'&&v.k==='String'){parts.push(v.v);return parts.join('');}
  const c=ctor(t);if(c.k==='SNil'&&c.x.length===0)return parts.join('');
  if(c.k!=='SCon'||c.x.length!==2)throw Error('Bad String '+c.k);
  const char=ctor(c.x[0]);if(char.k!=='Chr'||char.x.length!==1)throw Error('Bad String Char');
  parts.push(String.fromCodePoint(u32(char.x[0])));t=c.x[1];
 }
}
function decode(t:B.HTerm):Value{
 const raw=head(t);
 if(raw.$==='Lit'&&raw.k==='Nat')return nat(raw);
 if(raw.$==='Lit'&&raw.k==='String')return raw.v;
 if(raw.$==='Lit'&&raw.k==='U32')return u32(raw);
 const v=ctor(raw),k=tag(v.k);
 if(k==='SpanOf'){if(v.x.length!==3)throw Error('Bad source span');return {tag:k,fields:[str(v.x[0]),nat(v.x[1]),nat(v.x[2])]};}
 if(k==='Zero'||k==='Succ')return nat(v);
 if(k==='True'||k==='False'){if(v.x.length!==0)throw Error('Bad Bool');return k==='True';}
 if(k==='SNil'||k==='SCon')return str(v);
 if(k==='U32')return u32(v);
 if(k==='Nil'||k==='Con'){
  const out:Value[]=[];let cur:B.HTerm=v;
  for(;;){const c=ctor(cur),key=tag(c.k);if(key==='Nil'&&c.x.length===0)return out;if(key!=='Con'||c.x.length!==2)throw Error('Bad list');out.push(decode(c.x[0]));cur=c.x[1];}
 }
 // Scalar runtime containers are decoded above. Syntax constructor fields,
 // including all eight string constructor names, remain structurally intact.
 return {tag:k,fields:v.x.map(decode)};
}
function astNode(value:Value){
 if(typeof value!=='object'||value===null||Array.isArray(value))throw Error('Expected AST node');return value;
}
function astList(value:Value){
 if(!Array.isArray(value))throw Error('Expected AST list');return value;
}
function literalSpans(declaration:unknown,spans:Span[],index:number){
 const byPath=new Map(spans.map(s=>[s.path,{beg:s.beg,end:s.end}]));
 const literals:unknown[]=[];
 type Task={term:unknown,path:string,inherited:{beg:number,end:number}|null};
 const tasks:Task[]=[];
 const d=declaration as {T:unknown,body?:unknown,constructors?:{T:unknown}[]};
 const path='declarations/'+index;
 tasks.push({term:d.T,path:path+'/T',inherited:null});
 if(d.body)tasks.push({term:d.body,path:path+'/body',inherited:null});
 d.constructors?.forEach((c,j)=>tasks.push({term:c.T,path:path+'/constructors/'+j+'/T',inherited:null}));
 while(tasks.length){
  const {term,path,inherited}=tasks.pop()!,span=byPath.get(path)??inherited;
  if(!Array.isArray(term))throw Error('Expected normalized core term');
  const child=(term:unknown,key:string)=>tasks.push({term,path:path+'/'+key,inherited:span});
  switch(term[0]){
   case 'Lit': literals.push({path,kind:term[1],value:term[2],span});break;
   case 'All': child(term[3],'A');child(term[4],'B');break;
   case 'Lam': child(term[3],'f');break;
   case 'Let': term[3].forEach((v:unknown,i:number)=>child(v,'v/'+i));child(term[4],'f');break;
   case 'Typ': child(term[1],'g');break;
   case 'Min': child(term[1],'a');child(term[2],'b');break;
   case 'App': child(term[1],'f');child(term[2],'x');break;
   case 'ADT': case 'Ctr': term[2].forEach((v:unknown,i:number)=>child(v,'x/'+i));break;
   case 'Mat': child(term[2],'h');child(term[3],'m');break;
   case 'Eql': child(term[1],'a');child(term[2],'b');child(term[3],'T');break;
   case 'Rwt': child(term[1],'e');child(term[2],'p');child(term[3],'f');break;
   case 'Ann': child(term[1],'x');child(term[2],'T');break;
   case 'Var': case 'Ref': case 'Qnt': case 'Qua': case 'Efq': case 'Rfl': case 'Hol': break;
   default: throw Error('Unknown normalized literal-span term '+term[0]);
  }
 }
 return literals;
}
function literalLedger(groups:unknown[][]){
 const digest=createHash('sha256');digest.update('[');
 let first=true,count=0;
 for(let i=groups.length-1;i>=0;i--)for(const entry of groups[i]!){
  if(!first)digest.update(',');first=false;count++;
  digest.update(JSON.stringify(entry));
 }
 digest.update(']');return {sha256:digest.digest('hex'),count};
}
function sourceCases(value:unknown):{name:string,source:string}[]{
 if(typeof value!=='object'||value===null||!('rows'in value)||!Array.isArray(value.rows))throw Error('Expected source fixture rows');
 return value.rows.map((row:unknown)=>{
  if(typeof row!=='object'||row===null||!('name'in row)||typeof row.name!=='string'||!('source'in row)||typeof row.source!=='string')throw Error('Invalid named source fixture');
  return {name:row.name,source:row.source};
 });
}
const text=await Bun.file('evals/parser_full_fuel_smoke.ts').text(),begin=text.indexOf('const originalCorpus = ['),end=text.indexOf('const corpusSelection = ',begin);
if(begin<0||end<begin)throw Error('Corpus declaration anchors changed');
const {regression,literals}=new Function(text.slice(begin,end)+'return {regression:originalCorpus.concat(expandedCorpus),literals:literalCorpus};')() as {regression:{name:string,source:string}[],literals:{name:string,source:string}[]};
if(regression.length!==29||literals.length!==13)throw Error('Complete regression/literal corpus changed');
const fixturePaths=['checkpoints/bootstrap-real-source-corpus.json','checkpoints/bootstrap-minimized-stage0-oracle.json','checkpoints/bootstrap-new-minimized-stage0-oracle.json',
 'checkpoints/bootstrap-natural-expression-fixtures.json','checkpoints/bootstrap-binder-identity-fixtures.json','checkpoints/bootstrap-local-pattern-fixtures.json',
 'checkpoints/bootstrap-signature-fixtures.json','checkpoints/bootstrap-empty-match-fixtures.json','checkpoints/bootstrap-newline-expression-fixtures.json'];
for(const path of fixturePaths){const file=realpathSync(path);sourceInputs.set(file,{file,sha256:createHash('sha256').update(readFileSync(file)).digest('hex')});}
const real=await Bun.file('checkpoints/bootstrap-real-source-corpus.json').json();
const focused=await Bun.file('checkpoints/bootstrap-minimized-stage0-oracle.json').json();
const exposedFocused=await Bun.file('checkpoints/bootstrap-new-minimized-stage0-oracle.json').json();
const numericExpressions=await Bun.file('checkpoints/bootstrap-natural-expression-fixtures.json').json();
const binderIdentity=await Bun.file('checkpoints/bootstrap-binder-identity-fixtures.json').json();
const localPatterns=await Bun.file('checkpoints/bootstrap-local-pattern-fixtures.json').json();
const signatures=await Bun.file('checkpoints/bootstrap-signature-fixtures.json').json();
const emptyMatches=await Bun.file('checkpoints/bootstrap-empty-match-fixtures.json').json();
const newlineExpressions=await Bun.file('checkpoints/bootstrap-newline-expression-fixtures.json').json();
const fixtureDir=realpathSync(mkdtempSync(join(tmpdir(),'bend-bootstrap-parser-regression-'))),fixtureFile=join(fixtureDir,'source.bend');
writeFileSync(fixtureFile,'');writeFileSync(join(fixtureDir,'dependency.bend'),'def value() -> Nat:\n  7n\n');
// Historical names are stable consumer roles, not stale implementation paths.
// The generated parser role always parses this run's selected current source.
const currentRolePaths:Record<string,string>={
 '.parser_definition_body_shape_generated_fuel.bend':parserPath,
 'checker_core_slice.bend':'checkpoints/checker_core_owned_v1.bend',
 'checker_core_driver.bend':'checkpoints/checker_core_owned_driver_v1.bend',
};
const realCases=await Promise.all(real.modules.map(async(m:unknown)=>{
 if(typeof m!=='object'||m===null||!('file'in m)||typeof m.file!=='string')throw Error('Invalid real-source consumer path');
 const name=m.file.split('/').at(-1)!,file=realpathSync(currentRolePaths[name]??m.file);
 const source=await Bun.file(file).text(),sha256=createHash('sha256').update(source).digest('hex'),previous=sourceInputs.get(file);
 if(previous&&previous.sha256!==sha256)throw Error('Real consumer changed during preparation: '+file);
 sourceInputs.set(file,{file,sha256});
 return {name,role:name,historicalFile:resolve(m.file),file,source,suite:'real'};
}));
const realSourceRoleMigrations=realCases.map(i=>({role:i.role,historicalFile:i.historicalFile,file:i.file,sourceSha256:createHash('sha256').update(i.source).digest('hex')}));
const suite=[...[...sourceCases(focused),...sourceCases(exposedFocused),...sourceCases(numericExpressions),...sourceCases(binderIdentity),...sourceCases(localPatterns),...sourceCases(signatures),...sourceCases(emptyMatches),...sourceCases(newlineExpressions)].map(r=>({...r,role:r.name,historicalFile:undefined,file:fixtureFile,suite:'focused'})),...regression.map(r=>({...r,role:r.name,historicalFile:undefined,file:fixtureFile,suite:'whole29'})),...literals.map(r=>({...r,role:r.name,historicalFile:undefined,file:fixtureFile,suite:'literals'})),...realCases];
if(suite.filter(i=>i.suite==='focused').length!==23||suite.filter(i=>i.suite==='real').length!==10||new Set(suite.map(i=>i.suite+'/'+i.name)).size!==75)throw Error('Complete named consumer corpus changed');
const rows:Record<string,unknown>[]=[];
const publicReportBytes=readFileSync(publicReportPath),publicReport=JSON.parse(publicReportBytes.toString('utf8'));
if(resolve(publicReport.parserPath)!==resolve(parserPath)||publicReport.parserSha256!==parserSha256||publicReport.canonicalSha256!==canonicalSha256||publicReport.entryPoint!==entryPoint||publicReport.exitCode!==0||publicReport.passed!==15||publicReport.failed!==0||publicReport.assertions!==264)throw Error('Public gate does not authenticate this complete parser run');
if(typeof publicReport.rawOutputPath!=='string'||createHash('sha256').update(readFileSync(publicReport.rawOutputPath)).digest('hex')!==publicReport.rawOutputSha256)throw Error('Public gate raw output drift');
const publicRegressions={parserSha256:publicReport.parserSha256,passed:publicReport.passed,failed:publicReport.failed,assertions:publicReport.assertions,reportPath:resolve(publicReportPath),reportSha256:createHash('sha256').update(publicReportBytes).digest('hex')};
for(const path of [parserPath,'bend2/selfhost/parser.bend',kernelPath,...(tokenABI?[tokenABI.sourcePath,tokenABI.artifactPath]:[]),publicReportPath,publicReport.rawOutputPath]){
 const file=realpathSync(path),sha256=createHash('sha256').update(readFileSync(file)).digest('hex'),previous=sourceInputs.get(file);
 if(previous&&previous.sha256!==sha256)throw Error('Runtime closure changed while preparing semantic gate: '+file);
 sourceInputs.set(file,{file,sha256});
}
if(sourceInputs.get(realpathSync(parserPath))?.sha256!==parserSha256||sourceInputs.get(realpathSync('bend2/selfhost/parser.bend'))?.sha256!==canonicalSha256||sourceInputs.get(realpathSync(kernelPath))?.sha256!==kernelSha256
 ||tokenABI&&(sourceInputs.get(realpathSync(tokenABI.sourcePath))?.sha256!==tokenABI.sourceSha256||sourceInputs.get(realpathSync(tokenABI.artifactPath))?.sha256!==tokenABI.artifactSha256))throw Error('Parser/kernel/lexer changed while preparing semantic gate');
const selectedSuite=process.argv.find(a=>a.startsWith('--suite='))?.slice(8),selectedCase=process.argv.find(a=>a.startsWith('--case='))?.slice(7);
const partial=selectedSuite!==undefined||selectedCase!==undefined;
if(selectedSuite&&!suite.some(i=>i.suite===selectedSuite)||selectedCase&&selectedCase.split(',').some(name=>!suite.some(i=>i.name===name&&(!selectedSuite||i.suite===selectedSuite))))throw Error('Unknown selected semantic suite/case');
let completed=false;
const corpus=suite.map(i=>({name:i.name,role:i.role,historicalFile:i.historicalFile,file:i.file,suite:i.suite,sourceSha256:createHash('sha256').update(i.source).digest('hex')}));
const executionSuite=nativeMode?suite:suite.filter(i=>i.suite!=='real'||!historicalLimitedModules.includes(i.name));
if(executionSuite.length!==(nativeMode?75:71))throw Error('Parser phase execution policy changed');
const tokenProducer=tokenABI?Object.fromEntries(Object.entries(tokenABI).filter(([name])=>name!=='lexer')):null;
const nativeWorker=nativeMode?{path:realpathSync('evals/bootstrap_parser_native_semantic_worker.mjs'),sha256:sourceInputs.get(realpathSync('evals/bootstrap_parser_native_semantic_worker.mjs'))!.sha256,runtime:{name:'node',heapLimitMiB:3072,stackSizeMiB:256,manualGC:false},fuelCells:2000000,transport:'bend-native-ast-v1',isolation:'Fresh Bun/Node processes for every semantic case; no overlapping heavy children'}:null;
function save(){
 const passed=completed&&!partial&&rows.length===executionSuite.length&&rows.every(row=>row.acceptanceParity&&row.semanticParity&&row.literalSpanParity&&!row.error);
 const admitted=nativeMode&&passed,preparationAdmitted=!nativeMode&&passed;
 writeFileSync(report,JSON.stringify({schemaVersion:1,parserPath:resolve(parserPath),parserSha256,canonicalSha256,entryPoint,evaluationMode,completed,admitted,preparationAdmitted,partial,guard,component,nativeWorker,sourceSpecificExceptions:0,checksExcluded:0,outputPatches:0,knownEvaluatorLimitedModules,publicRegressions,kernelPath,kernelSha256,sourceInputs:[...sourceInputs.values()],corpus,realSourceRoleMigrations,realSourcePolicy:'Current release bytes for all ten historical roles; generated parser is the selected current source, checker and driver use current owned sources. Source preparation executes six bounded real roles only and cannot admit a parser. Native final admission executes all ten current roles.',lexerABI,tokenProducer,spanDiagnosticDebt:'Existing nonliteral span/alpha normalization only; decoded offsets retained and every normalized core literal span compared exactly.',counts:Object.fromEntries(['focused','whole29','literals','real'].map(s=>[s,{total:rows.filter(r=>r.suite===s).length,accepted:rows.filter(r=>r.suite===s&&r.canonicalAccepted).length,acceptanceParity:rows.filter(r=>r.suite===s&&r.acceptanceParity).length,semanticParity:rows.filter(r=>r.suite===s&&r.semanticParity).length,literalSpanParity:rows.filter(r=>r.suite===s&&r.literalSpanParity).length}])),rows},null,2)+'\n');
}
// Exclusive creation prevents accidental replacement of historical evidence.
writeFileSync(report,'',{flag:'wx'});save();
const startWorker=()=>Bun.spawn(nativeMode?['node','--max-old-space-size=3072','evals/bootstrap_parser_native_semantic_worker.mjs',component!.artifactPath,component!.artifactSha256]:['node','--max-old-space-size=3072','evals/bootstrap_token_worker.mjs',tokenABI!.artifactPath],
 {stdin:'pipe',stdout:'pipe',stderr:'inherit'});
let worker=startWorker();
// Bun and Node expose the same web-stream ABI with different declaration types.
let replies=createInterface({input:Readable.fromWeb(worker.stdout as unknown as NodeReadableStream)});
let nextReply=replies[Symbol.asyncIterator]();
let requestId=0,workerClosed=false;
async function closeWorker(){
 replies.close();worker.stdin.end();workerClosed=true;
 if(await worker.exited!==0)throw Error('Current parser/lexer worker failed');
}
async function parseCase(item:typeof suite[number],row:Record<string,unknown>):Promise<Value>{
 const id=requestId++,transport=join(fixtureDir,'native-'+id+'.ast.json');
 worker.stdin.write(JSON.stringify(nativeMode?{id,kind:'parse',file:item.file,source:item.source,transport}:{id,source:item.source})+'\n');await worker.stdin.flush();
 const response=await nextReply.next();
 if(response.done)throw Error('Current parser/lexer worker ended');
 const value=JSON.parse(response.value);
 if(value.id!==id||value.error)throw Error(value.error??'Invalid native worker reply');
 if(!nativeMode){
  if(!Array.isArray(value.tokens))throw Error('Invalid current lexer tokens');
  return decode(B.App(B.App(B.Ref(entryPoint!),inputTokens(value.tokens)),closed(item.file)));
 }
 if(value.compiledExecution!==true||value.transport!==transport||value.artifactSha256!==component!.artifactSha256
  ||value.sourceSha256!==row.sourceSha256||JSON.stringify(value.runtime)!==JSON.stringify(nativeWorker!.runtime))throw Error('Native parser execution provenance mismatch');
 const {arena,sha256}=await readNativeAstArena(transport);
 if(sha256!==value.transportSha256)throw Error('Native parser AST transport drift');
 row.compiledExecution=true;row.componentArtifactSha256=value.artifactSha256;row.nativeTransportSha256=sha256;row.nativeTransportBytes=value.transportBytes;
 const result=arena.semantic(arena.root);rmSync(transport);return result;
}
try{
for(const item of executionSuite.filter(i=>(!selectedSuite||i.suite===selectedSuite)&&(!selectedCase||selectedCase.split(',').includes(i.name)))){
 if(nativeMode&&!process.argv.includes('--isolated-semantic-case')){
  // Bound both heaps: a large native oracle/core graph must leave with its process.
  if(!workerClosed)await closeWorker();
  const childReport=resolve(report+'.case-'+item.suite+'-'+item.name+'.json');
  const command=[process.execPath,'--smol',import.meta.path,...process.argv.slice(2).filter(arg=>!['--report=','--suite=','--case='].some(prefix=>arg.startsWith(prefix))),
   '--suite='+item.suite,'--case='+item.name,'--report='+childReport,'--isolated-semantic-case'];
  const child=Bun.spawn(command,{stdin:'ignore',stdout:'pipe',stderr:'pipe'});
  const [stdout,stderr,exitCode]=await Promise.all([new Response(child.stdout).text(),new Response(child.stderr).text(),child.exited]);
  const output=stdout+'\n'+stderr,outputPath=childReport+'.output.txt';
  writeFileSync(outputPath,output,{flag:'wx'});console.log(output);
  const bytes=readFileSync(childReport),proof=JSON.parse(bytes.toString('utf8'));
  if(exitCode!==2||proof.completed!==true||proof.partial!==true||proof.admitted!==false||proof.preparationAdmitted!==false||
   proof.evaluationMode!==evaluationMode||proof.parserSha256!==parserSha256||proof.canonicalSha256!==canonicalSha256||proof.kernelSha256!==kernelSha256||
   proof.sourceSpecificExceptions!==0||proof.checksExcluded!==0||proof.outputPatches!==0||proof.component?.artifactSha256!==component!.artifactSha256||
   !Array.isArray(proof.rows)||proof.rows.length!==1||proof.rows[0].name!==item.name||proof.rows[0].suite!==item.suite||
   proof.rows[0].sourceSha256!==createHash('sha256').update(item.source).digest('hex'))throw Error('Incomplete isolated semantic proof: '+item.name);
  for(const input of [...proof.sourceInputs,{file:childReport,sha256:createHash('sha256').update(bytes).digest('hex')},
   {file:outputPath,sha256:createHash('sha256').update(output).digest('hex')}]){
   const file=realpathSync(input.file),previous=sourceInputs.get(file);
   if(previous&&previous.sha256!==input.sha256)throw Error('Isolated semantic input drift: '+file);
   sourceInputs.set(file,{file,sha256:input.sha256});
  }
  const row={...proof.rows[0],isolatedExecution:{command,exitCode,reportPath:childReport,reportSha256:createHash('sha256').update(bytes).digest('hex'),outputPath,outputSha256:createHash('sha256').update(output).digest('hex')}};
  rows.push(row);save();console.log(JSON.stringify(row));continue;
 }
 console.log(JSON.stringify({stage:'parse',suite:item.suite,name:item.name,bytes:Buffer.byteLength(item.source)}));
 const oracle=await sourceOracle(item.file,item.source,{preloadBase:item.suite!=='real',recordInputs:true});
 const row:Record<string,unknown>={name:item.name,role:item.role,historicalFile:item.historicalFile,file:item.file,suite:item.suite,evaluationMode,sourceSha256:createHash('sha256').update(item.source).digest('hex'),stage0Accepted:oracle.accepted,oracleObservation:oracle.observation,oracleFailure:oracle.failure,oracleInputs:oracle.inputFiles,oracleLoadContexts:oracle.loadContexts};
 if(oracle.observation.stage0Sha256!==kernelSha256)throw Error('Oracle kernel changed during semantic gate');
 if(item.suite==='real'&&!oracle.inputFiles.some(input=>input.file===realpathSync(item.file)&&input.sha256===row.sourceSha256))throw Error('Current real module bytes changed before observation: '+item.file);
 for(const input of oracle.inputFiles){
  // Per-case source bytes are authenticated above; temporary loader fixtures
  // are observation inputs, not a permanent source-closure artifact.
  if(input.file.startsWith(fixtureDir+'/'))continue;
  const previous=sourceInputs.get(input.file);
  if(previous&&previous.sha256!==input.sha256)throw Error('Source closure changed during semantic gate: '+input.file);
  sourceInputs.set(input.file,{file:input.file,sha256:input.sha256});
 }
 try{
  const result=astNode(await parseCase(item,row));
  if(!['ParseSuccess','ParseFailure'].includes(result.tag))throw Error('Unexpected parser result '+result.tag);
  if(oracle.failure?.category==='observation-seam')throw Error('Native oracle observation seam failed');
  row.canonicalAccepted=result.tag==='ParseSuccess';row.acceptanceParity=row.canonicalAccepted===oracle.accepted;
  console.log(JSON.stringify({stage:'canonical-result',name:item.name,accepted:row.canonicalAccepted}));
  if(!row.canonicalAccepted){row.failure=result;const pos=astNode(result.fields[3]).fields[1];if(typeof pos!=='number')throw Error('Expected failure offset');row.failureBoundary=oracle.boundaries.filter(b=>b.beg<=pos).at(-1);}
  if(!row.canonicalAccepted&&!oracle.accepted){row.semanticParity=true;row.literalSpanParity=true;}
  if(row.canonicalAccepted&&oracle.accepted){
   const module=astNode(result.fields[0]),imports=astList(module.fields[1]).map(astNode),adjusted={...module,fields:[module.fields[0],imports.map(v=>{const actual=oracle.imports.find(i=>i.alias===v.fields[1]);return {...v,fields:[actual?.namespace||v.fields[0],...v.fields.slice(1)]};}),module.fields[2]]};
   console.log(JSON.stringify({stage:'native-normalization',name:item.name}));
   const environment=oracle.normalizationBook(),expectedLiteralGroups:unknown[][]=[],actualLiteralGroups:unknown[][]=[];
   const semanticImports=imports.map(v=>{const [path,alias]=v.fields;if(typeof path!=='string'||typeof alias!=='string')throw Error('Expected string import path/alias');return {path,alias};});
   row.stage0ASTHash=observeCoreBook(environment,oracle.declarations.map(d=>d.key),oracle.imports.map(i=>({path:i.path,alias:i.alias})),
    (declaration,spans,index)=>{expectedLiteralGroups.push(literalSpans(declaration,spans,index));},item.file,dirname(oracle.file)+'/');
   row.canonicalASTHash=observeCanonicalCore(adjusted,environment,item.source,semanticImports,
    (declaration,spans,index)=>{actualLiteralGroups.push(literalSpans(declaration,spans,index));});
   row.semanticParity=row.stage0ASTHash===row.canonicalASTHash;
   const expectedLedger=literalLedger(expectedLiteralGroups),actualLedger=literalLedger(actualLiteralGroups);
   row.stage0LiteralSpanHash=expectedLedger.sha256;row.canonicalLiteralSpanHash=actualLedger.sha256;row.literalSpanCount=expectedLedger.count;row.literalSpanParity=expectedLedger.sha256===actualLedger.sha256;
   if(!row.semanticParity||!row.literalSpanParity){writeFileSync(report+'.'+item.name+'.mismatch.json',JSON.stringify({expectedHash:row.stage0ASTHash,actualHash:row.canonicalASTHash,expectedLiteralGroups,actualLiteralGroups},null,2)+'\n',{flag:'wx'});}
  }
 }catch(error){row.error=error&&typeof error==='object'&&'$'in error&&error.$==='Err'?B.err_show(error as Parameters<typeof B.err_show>[0]):String(error);row.canonicalAccepted??=false;row.acceptanceParity??=false;}
 rows.push(row);save();console.log(JSON.stringify(row));
}
if(!workerClosed)await closeWorker();
for(const input of sourceInputs.values())if(createHash('sha256').update(readFileSync(input.file)).digest('hex')!==input.sha256)throw Error('Authenticated source/input drift: '+input.file);
rmSync(fixtureDir,{recursive:true,force:true});
completed=true;save();
if(partial||rows.length!==executionSuite.length||rows.some(row=>!row.acceptanceParity||!row.semanticParity||!row.literalSpanParity||row.error))process.exitCode=2;
}finally{
 if(!workerClosed)await closeWorker();
}
