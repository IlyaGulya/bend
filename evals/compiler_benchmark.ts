#!/usr/bin/env bun
/** Fresh complete-source compiler timing, not bootstrap acceptance.
 * Official mode preserves unmodified js_lib(book,true), including its export set.
 * Component mode requests that identical set through the typed emitter API.
 * Source admission/oracle remains in selfhost_bootstrap_gate, never hidden here.
 * Frozen v41 output uses its explicitly selected captured runtime input; it is
 * not a production ABI compatibility path or inferred from emitted values.
 */
import {createHash} from 'node:crypto';
import {existsSync,mkdirSync,readFileSync,realpathSync,writeFileSync} from 'node:fs';
import {dirname,isAbsolute,posix,relative,resolve} from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {Worker,isMainThread,workerData} from 'node:worker_threads';
import {guardHeavyGate,runHeavyGate} from './heavy_gate.ts';
import {sourceFiles,sourceFilePath,OFFICIAL_SOURCE_FILE_TAG} from './checker_core_step_runtime.mjs';

type Corpus={schemaVersion:number;directory:string;root:string;officialCommit:string;files:{path:string;sha256:string}[]};
type Options={mode:'official'|'component';corpus:string;report:string;component?:string;driver:string;outputSmokeDriver:'production'|'frozen-v41';exports?:string;stopAfter:'check'|'compile'};
const script=fileURLToPath(import.meta.url),repository=resolve(dirname(script),'..');
const sha=(bytes:string|Uint8Array)=>createHash('sha256').update(bytes).digest('hex');
const hash=(path:string)=>sha(readFileSync(path));
const json=(value:unknown)=>JSON.stringify(value,null,2)+'\n';
const save=(path:string,value:unknown,exclusive=false)=>writeFileSync(path,json(value),exclusive?{flag:'wx'}:undefined);
const guard={memoryMiB:8192,rssMiB:8192,pollMs:10};
const ABI=['parsed_module','parse_with_fuel','expand_modules_start','template_step','check_expanded_start','inspect_checked_start','checker_step','emit_modules_start','emit_library_start','emitter_step','emit_c_modules_start','emit_c_library_start','c_emitter_step'];
// Frozen output is an explicit historical test input, never a production decoder.
const frozenV41ABI=['parsed_module','parse_with_fuel','expand_modules_start','template_step','check_expanded_start','checker_step','emit_modules_start','emit_library_start','emitter_step'];
const productionRuntime=resolve(repository,'evals/checker_core_step_runtime.mjs');
const frozenV41Runtime=resolve(repository,'checkpoints/compiler-benchmark-v41-step-runtime.mjs');
const frozenV41Manifest=resolve(repository,'checkpoints/compiler-benchmark-release237-v41.corpus.json');
const frozenV41RuntimeSha256='2cad05bb4885854d7ede65336dbe287ac78063f8321110d2d63018e9890000fd';
const tag=(value:any):string|undefined=>typeof value?.$==='string'?value.$.split('.').at(-1):undefined;
function options():Options{
 const args=new Map<string,string>();
 for(const arg of process.argv.slice(2)){
  const at=arg.indexOf('='),key=arg.slice(0,at),value=arg.slice(at+1);
  if(at<0||!['--mode','--corpus','--report','--component','--driver','--output-smoke-driver','--exports','--stop-after'].includes(key)||!value||args.has(key))throw Error('Expected unique --mode=official|component --corpus=PATH --report=FRESH.json [--component=PATH --driver=PATH --output-smoke-driver=production|frozen-v41 --exports=PATH --stop-after=check|compile]');
  args.set(key,value);
 }
 const mode=args.get('--mode'),stopAfter=args.get('--stop-after')??'compile',outputSmokeDriver=args.get('--output-smoke-driver')??'production';
 if(!['official','component'].includes(mode??'')||!['check','compile'].includes(stopAfter)||!['production','frozen-v41'].includes(outputSmokeDriver))throw Error('Invalid benchmark mode/phase/output runtime');
 for(const key of ['--corpus','--report'])if(!args.has(key))throw Error('Missing '+key);
 if(mode==='component'&&!args.has('--component'))throw Error('Component mode requires --component');
 if(mode==='component'&&stopAfter==='compile'&&!args.has('--exports'))throw Error('Component compilation requires the official --exports receipt');
 if(mode==='official'&&(args.has('--component')||args.has('--exports')))throw Error('Official mode has no selected-export override');
 return {mode:mode as Options['mode'],corpus:resolve(args.get('--corpus')!),report:resolve(args.get('--report')!),driver:resolve(args.get('--driver')??productionRuntime),outputSmokeDriver:outputSmokeDriver as Options['outputSmokeDriver'],component:args.has('--component')?resolve(args.get('--component')!):undefined,exports:args.has('--exports')?resolve(args.get('--exports')!):undefined,stopAfter:stopAfter as Options['stopAfter']};
}
function corpusOf(path:string):Corpus{
 const c=JSON.parse(readFileSync(path,'utf8'));
 if(c.schemaVersion!==1||!isAbsolute(c.directory)||typeof c.root!=='string'||!Array.isArray(c.files)||!c.files.length)throw Error('Invalid frozen corpus manifest');
 const seen=new Set<string>();
 for(const row of c.files){
  if(typeof row.path!=='string'||isAbsolute(row.path)||row.path.split('/').some((part:string)=>part==='..'||part==='')||seen.has(row.path)||!/^([0-9a-f]{64})$/.test(row.sha256))throw Error('Invalid/duplicate frozen source path');
  seen.add(row.path);
 }
 if(!seen.has(c.root))throw Error('Root is outside frozen input set');
 return c;
}
function verifyRuntimeSelection(o:Options,c:Corpus){
 if(o.outputSmokeDriver!=='frozen-v41'&&realpathSync(o.driver)!==realpathSync(frozenV41Runtime))return;
 if(hash(frozenV41Runtime)!==frozenV41RuntimeSha256)throw Error('Frozen v41 runtime source drift');
 const reference=corpusOf(frozenV41Manifest);
 const identity=(corpus:Corpus)=>JSON.stringify({officialCommit:corpus.officialCommit,root:corpus.root,files:corpus.files.map(({path,sha256})=>({path,sha256})).sort((a,b)=>a.path.localeCompare(b.path))});
 if(identity(c)!==identity(reference))throw Error('Captured old runtime is only a frozen v41 benchmark input');
}
function verifyCorpus(c:Corpus):Map<string,string>{
 const directory=realpathSync(c.directory),expected=new Map<string,string>();
 for(const row of c.files){
  const path=realpathSync(resolve(directory,row.path));
  if(relative(directory,path).startsWith('..')||hash(path)!==row.sha256)throw Error('Frozen source drift: '+row.path);
  expected.set(path,row.sha256);
 }
 return expected;
}
function verifyPins(pins:Record<string,string>){for(const [path,digest]of Object.entries(pins))if(hash(path)!==digest)throw Error('Benchmark implementation drift: '+path);}
function list(rows:any[]):any{return rows.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});}
function items(value:any):any[]{const out=[];while(tag(value)==='Con'){out.push(value.head);value=value.tail;}if(tag(value)!=='Nil')throw Error('Malformed native list');return out;}
const fuelEnd=Object.freeze({$:'FeedbackFuelEnd'}),fuelPrototype={get tail(){return fuelNode((this as any).remaining-1);}};
function fuelNode(remaining:number):any{if(!remaining)return fuelEnd;const node=Object.create(fuelPrototype);node.$='FeedbackFuelCell';node.remaining=remaining;return node;}
function parsed(api:any,file:string,source:string):any{
 const feedback=api.parse_with_fuel(fuelNode(8000000),file,source);
 if(tag(feedback)!=='FeedbackComplete'||tag(feedback.value?.result)!=='ParseSuccess')throw Error('Fresh own parse failed: '+file+' '+String(feedback.value?.result?.message??tag(feedback)));
 return feedback.value.result.module;
}
function loadOwn(api:any,c:Corpus,expected:Map<string,string>){
 const seen=new Map<string,string>(),active=new Set<string>(),observed=new Set<string>(),modules:any[]=[],foreign=new Map<string,string>();
 let declarations=0;
 const observe=(path:string)=>{const at=realpathSync(path);if(!expected.has(at))throw Error('Unexpected compiler input: '+at);observed.add(at);return at;};
 // The declared `.js` alternative is BIR metadata; this host only reads the
 // bytes of the path BIR resolves from it and keys the bag by that same path.
 const observeForeign=(module:string,declared:string)=>{
  const key=sourceFilePath(module,declared),source=readFileSync(key,'utf8');
  observe(key);
  const known=foreign.get(key);
  if(known!==undefined&&known!==source)throw Error('Declared source path resolves to different bytes: '+key);
  foreign.set(key,source);
 };
 const namespace=(parent:string,path:string)=>path==='Base'?'':posix.normalize(isAbsolute(path)?path.replace(/\.bend$/,''):posix.dirname(parent)+'/'+path.replace(/\.bend$/,''));
 function visit(path:string,scope:string){
  const file=observe(path);
  if(active.has(file))throw Error('Source import cycle: '+file);
  if(seen.has(file)){if(seen.get(file)!==scope)throw Error('Conflicting source namespace: '+file);return;}
  seen.set(file,scope);active.add(file);
  const module=parsed(api,file,readFileSync(file,'utf8'));
  const tops=items(module.declarations);declarations+=tops.length;
  for(const top of tops)if(tag(top)==='DefTop'&&tag(top.definition.body)==='DefImports')for(const imported of items(top.definition.body.paths))if(imported.endsWith('.js'))observeForeign(file,imported);
  for(const imported of items(module.imports)){
   const path=imported.path;
   if(typeof path!=='string'||/^0x[0-9a-f]+\//.test(path))throw Error('Nonlocal/malformed import in frozen corpus');
   const child=path==='Base'?resolve(c.directory,'bend2/base.bend'):resolve(dirname(file),path);
   if(path.endsWith('.js'))observeForeign(file,path);else visit(child,namespace(scope,path));
  }
  modules.push(api.parsed_module(scope,module));active.delete(file);
 }
 visit(resolve(c.directory,c.root),'');
 if(observed.size!==expected.size||[...expected.keys()].some(path=>!observed.has(path)))throw Error('Own compiler did not load the exact complete frozen corpus');
 return {modules:list(modules),moduleCount:seen.size,declarations,inputFiles:observed.size,files:[...foreign].map(([path,source])=>({path,source}))};
}

async function worker(requestPath:string,requestSha256:string){
 await guardHeavyGate(script,{label:'Comparable full-corpus compiler benchmark'});
 const requestBytes=readFileSync(requestPath),request=JSON.parse(requestBytes.toString()),o:Options=request.options;
 if(hash(requestPath)!==requestSha256)throw Error('Benchmark request authentication failed');
 verifyPins(request.pins);
 const corpus=corpusOf(o.corpus),expected=verifyCorpus(corpus),phases:Record<string,unknown>[]=[];
 verifyRuntimeSelection(o,corpus);
 const report:any={schemaVersion:1,status:'IN_PROGRESS',diagnosticOnly:true,bootstrapAcceptance:false,mode:o.mode,stopAfter:o.stopAfter,oracleIncluded:false,checksExcluded:0,outputPatches:0,corpus:o.corpus,corpusSha256:hash(o.corpus),root:resolve(corpus.directory,corpus.root),inputFiles:expected.size,runtime:{versions:process.versions,platform:process.platform,arch:process.arch},limits:{...guard,oldGenerationMiB:6144,youngGenerationMiB:128,stackMiB:256},implementationPins:request.pins,phases};
 const started=performance.now();
 const phase=async<T>(name:string,action:()=>T|Promise<T>):Promise<T>=>{
  report.activePhase={name,startedAtUnixMs:Date.now(),memoryBefore:process.memoryUsage()};
  save(o.report,report);
  const wall=performance.now(),cpu=process.cpuUsage();
  const value=await action(),used=process.cpuUsage(cpu);
  const row={name,wallMs:performance.now()-wall,cpuMs:(used.user+used.system)/1000,memoryEnd:process.memoryUsage()};phases.push(row);
  report.lastCompletedPhase=name;delete report.activePhase;save(o.report,report);
  console.log(JSON.stringify({phase:name,...row}));return value;
 };
 let source:string|undefined,api:any,driver:any;
 try{
  let exportNames:string[]|undefined;
  if(o.mode==='official'){
   const loaded=await phase('compiler-startup',async()=>({K:await import(pathToFileURL(resolve(corpus.directory,'bend2/bend.ts')).href),C:await import(pathToFileURL(resolve(corpus.directory,'bend2/comp.ts')).href)}));
   const {K,C}=loaded,book=K.book_nil(),observed=new Set<string>();
   class Inputs extends Map<string,string|null>{override set(path:string,namespace:string|null){if(namespace===null)observed.add(realpathSync(path));return super.set(path,namespace);}}
   await phase('load-parse-expand',()=>K.book_load(book,report.root,'',new Inputs()));
   for(const def of Object.values(book.tlds) as any[])if(def.$==='Def')for(const path of def.i??[])if(path.endsWith('.js'))observed.add(realpathSync(path));
   if(observed.size!==expected.size||[...observed].some(path=>!expected.has(path)))throw Error('Official compiler did not load the same complete frozen corpus');
   await phase('check',()=>K.book_valid(book));
   if(book.hols)throw Error('Unfilled official book');
   const definitions=(Object.values(book.tlds) as any[]).filter(def=>def.$==='Def'&&def.v!==null);
   if(definitions.some(def=>def.e===undefined))throw Error('Official unchecked body');
   report.checkedBodies=definitions.length;report.validationEvents=book.order.length;
   if(o.stopAfter==='compile')source=await phase('emit',()=>C.js_lib(book,true));
  }else{
   ({api,driver}=await phase('compiler-startup',async()=>({api:(await import(pathToFileURL(o.component!).href)).default,driver:await import(pathToFileURL(o.driver).href)})));
   if(!api||!ABI.every(key=>typeof api[key]==='function'))throw Error('Compiler component ABI is incomplete');
   const loaded=await phase('load-parse',()=>loadOwn(api,corpus,expected));report.moduleCount=loaded.moduleCount;report.sourceDeclarations=loaded.declarations;
   let modules=loaded.modules;
   const files=sourceFiles(loaded.files,OFFICIAL_SOURCE_FILE_TAG);
   let expanded=await phase('expand',()=>driver.runTemplateSteps({...api,expand_modules_start:(input:any)=>{modules=undefined;return api.expand_modules_start(input);}},modules));
   if(tag(expanded)!=='ExpandSuccess')throw Error('Own expansion failed: '+JSON.stringify(expanded));
   let checked=await phase('check',()=>driver.runCheckerSteps({...api,check_expanded_start:(input:any)=>{expanded=undefined;return api.check_expanded_start(input);}},expanded.modules));
   if(tag(checked)!=='CheckSuccess')throw Error('Own checking failed: '+JSON.stringify(checked.diagnostic,(_,v)=>typeof v==='bigint'?String(v):v));
   report.checkedModules=items(checked.program.modules).length;
   if(report.checkedModules!==report.moduleCount)throw Error('Own checking lost source modules');
   if(o.stopAfter==='compile'){
    const receipt=JSON.parse(readFileSync(o.exports!,'utf8'));
    if(receipt.schemaVersion!==1||receipt.corpusSha256!==report.corpusSha256||!Array.isArray(receipt.exports)||!receipt.exports.length||receipt.exports.some((key:any)=>typeof key!=='string')||new Set(receipt.exports).size!==receipt.exports.length)throw Error('Missing exact official export-set receipt');
    exportNames=receipt.exports;
    // The public typed entry owns its FIR input and accepts explicit exports.
    const emission={...api,emit_library_start:(input:unknown,exports:unknown,sources:unknown)=>{checked=undefined;return api.emit_library_start(input,exports,sources);}};
    const emitted=await phase('emit',()=>driver.runLibraryEmitterSteps(emission,checked.program,list(exportNames!),files));
    if(tag(emitted)!=='EmitSuccess')throw Error('Own emission failed: '+emitted.message);source=emitted.source;
   }
  }
  if(source!==undefined){
   const output=o.report+'.output.mjs';
   report.artifact=await phase('write-and-hash',()=>{writeFileSync(output,source!,{flag:'wx'});const bytes=Buffer.byteLength(source!);return {path:output,bytes,sha256:sha(source!)};});source=undefined;
  }
  report.compileMs=performance.now()-started;
  if(report.artifact){
   const outputApi=(await phase('output-import',()=>import(pathToFileURL(report.artifact.path).href))).default;
   const actual=Object.keys(outputApi);
   if(o.mode==='official'){
    exportNames=actual;
    save(o.report+'.exports.json',{schemaVersion:1,corpusSha256:report.corpusSha256,officialCommit:corpus.officialCommit,artifactSha256:report.artifact.sha256,exports:actual},true);
   }else if(actual.length!==exportNames!.length||actual.some((key,index)=>key!==exportNames![index]))throw Error('Emitted public export set differs from official mode');
   if(!(o.outputSmokeDriver==='frozen-v41'?frozenV41ABI:ABI).every(name=>typeof outputApi[name]==='function'))throw Error('Emitted compiler ABI incomplete');
   const runtimePath=o.outputSmokeDriver==='frozen-v41'?frozenV41Runtime:productionRuntime;
   const runtime=await import(pathToFileURL(runtimePath).href);
   report.outputSmokeRuntime={selection:o.outputSmokeDriver,path:runtimePath,sha256:hash(runtimePath),...(o.outputSmokeDriver==='frozen-v41'?{provenance:'Exact pre-v53 runtime captured from committed52 f99b22db; frozen v41 benchmark input only',expectedSha256:frozenV41RuntimeSha256,corpusReference:frozenV41Manifest}:{progressABI:'typed-native-stack-v57t'})};
   await phase('output-semantic-smoke',()=>{
    const module=parsed(outputApi,resolve(corpus.directory,'benchmark-smoke.bend'),'type Bit is Data:\n  Zero{}\n  One{}\n\ndef main() -> Bit:\n  One{}\n');
    if(!items(module.declarations).some(top=>tag(top)==='DefTop'&&top.definition.key==='main'))throw Error('Emitted parser lost the actual main declaration');
    const checked=runtime.runCheckerSteps(outputApi,{$:'Nil'});
    const checkedModules=o.outputSmokeDriver==='frozen-v41'?checked.modules:checked.program?.modules;
    if(tag(checked)!=='CheckSuccess'||tag(checkedModules)!=='Nil')throw Error('Emitted checker failed empty-module semantics');
   });
   report.exportCount=actual.length;report.exportSetSha256=sha(JSON.stringify(actual));report.outputSmokePassed=true;
  }
  verifyCorpus(corpus);verifyPins(request.pins);
  report.status='PASS';report.passed=true;report.totalWithOutputSmokeMs=performance.now()-started;
 }catch(error){report.status='FAIL';report.passed=false;report.error=String(error);report.stack=(error as Error).stack;process.exitCode=1;}
 save(o.report,report);console.log(JSON.stringify({status:report.status,mode:o.mode,compileMs:report.compileMs,report:o.report,error:report.error}));
}

if(!isMainThread){
 await worker(workerData.requestPath,workerData.requestSha256);
}else if(process.argv[2]==='--worker'){
 if(process.argv.length!==5)throw Error('Invalid worker request');
 const execution=new Worker(new URL(import.meta.url),{workerData:{requestPath:resolve(process.argv[3]!),requestSha256:process.argv[4]},resourceLimits:{stackSizeMb:256,maxOldGenerationSizeMb:6144,maxYoungGenerationSizeMb:128}});
 await new Promise<void>((done,reject)=>{execution.once('error',reject);execution.once('exit',code=>code===0?done():reject(Error('Benchmark worker failed: '+code)));});
}else{
 const o=options();mkdirSync(dirname(o.report),{recursive:true});
 if(existsSync(o.report)||existsSync(o.report+'.request.json')||existsSync(o.report+'.output.mjs'))throw Error('Use fresh benchmark report/output paths');
 const corpus=corpusOf(o.corpus);verifyCorpus(corpus);verifyRuntimeSelection(o,corpus);
 const paths=[script,o.corpus,o.driver,o.outputSmokeDriver==='frozen-v41'?frozenV41Runtime:productionRuntime,...(o.outputSmokeDriver==='frozen-v41'||realpathSync(o.driver)===realpathSync(frozenV41Runtime)?[frozenV41Manifest,frozenV41Runtime]:[]),...(o.component?[o.component]:[]),...(o.exports?[o.exports]:[]),resolve(corpus.directory,'bend2/bend.ts'),resolve(corpus.directory,'bend2/comp.ts')];
 const pins=Object.fromEntries(paths.map(path=>[realpathSync(path),hash(path)]));
 const expectedOfficialKernel='6c1df3eb304fe085070aa4797928f70243b80d4635389e3d5d8a49fdfbb3051e',expectedOfficialCompiler='56d5727049bc3ef528ef84d3b4712a41a0a8ce0a06437b29d881e71107638c70';
 if(pins[realpathSync(resolve(corpus.directory,'bend2/bend.ts'))]!==expectedOfficialKernel||pins[realpathSync(resolve(corpus.directory,'bend2/comp.ts'))]!==expectedOfficialCompiler)throw Error('Unmodified official compiler identity mismatch');
 const request=o.report+'.request.json';save(request,{options:o,pins},true);save(o.report,{status:'IN_PROGRESS',diagnosticOnly:true,bootstrapAcceptance:false},true);
 const result=await runHeavyGate(['node','--experimental-strip-types','--max-old-space-size=6144','--max-semi-space-size=128','--stack-size=262144',script,'--worker',request,hash(request)],{label:'Comparable full-corpus '+o.mode+' compiler',...guard});
 const record=JSON.parse(readFileSync(o.report,'utf8'));record.guardian=result;record.passed=record.passed===true&&result.status==='PASS';
 if(result.status!=='PASS'){record.status=result.status;record.partial=true;}
 save(o.report,record);process.exitCode=record.passed?0:result.exitCode||1;
}
